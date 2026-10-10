#!/bin/bash
#===============================================================================
# Wayshell Daemon — Module Event Manager
#===============================================================================
# Description:
#   Reads module configuration, spawns zone/layout/focused event sources,
#   and dispatches ON/OFF actions with configurable trailing-edge debounce.
#
# Dependencies: jq, mmsg
# Config: wayshell.conf (zone_buffer, on_delay, off_delay)
# Modules: wayshell.modules (name,on_exec,off_exec,type,args...)
#===============================================================================

CONFIG_DIR="${HOME}/.config/snapsos/wayshell"
CONFIG_FILE="${CONFIG_DIR}/wayshell.conf"
MODULES_FILE="${CONFIG_DIR}/wayshell.modules"
MODULE_DIR="${CONFIG_DIR}/modules"

exec 1>>/tmp/wayshell_daemon.log 2>&1
echo "=== Starting Wayshell Daemon ==="

CLEANED_UP=false
cleanup() {
    $CLEANED_UP && return
    CLEANED_UP=true
    echo "Shutting down Wayshell Daemon..."
    kill -- -$$ 2>/dev/null
    exit 0
}
trap cleanup SIGTERM SIGINT EXIT

# --- Config ---
ON_DELAY=$(grep -oP 'on_delay=\K[0-9]+' "$CONFIG_FILE" 2>/dev/null || echo "100")
OFF_DELAY=$(grep -oP 'off_delay=\K[0-9]+' "$CONFIG_FILE" 2>/dev/null || echo "100")

ZONE_ON_DELAY=$(grep -oP 'zone_on_delay=\K[0-9]+' "$CONFIG_FILE" 2>/dev/null || echo "$ON_DELAY")
ZONE_OFF_DELAY=$(grep -oP 'zone_off_delay=\K[0-9]+' "$CONFIG_FILE" 2>/dev/null || echo "$OFF_DELAY")
LAYOUT_ON_DELAY=$(grep -oP 'layout_on_delay=\K[0-9]+' "$CONFIG_FILE" 2>/dev/null || echo "$ON_DELAY")
LAYOUT_OFF_DELAY=$(grep -oP 'layout_off_delay=\K[0-9]+' "$CONFIG_FILE" 2>/dev/null || echo "$OFF_DELAY")
FOCUSED_ON_DELAY=$(grep -oP 'focused_on_delay=\K[0-9]+' "$CONFIG_FILE" 2>/dev/null || echo "$ON_DELAY")
FOCUSED_OFF_DELAY=$(grep -oP 'focused_off_delay=\K[0-9]+' "$CONFIG_FILE" 2>/dev/null || echo "$OFF_DELAY")
echo "Config: on_delay=$ON_DELAY, off_delay=$OFF_DELAY zone_on=$ZONE_ON_DELAY zone_off=$ZONE_OFF_DELAY layout_on=$LAYOUT_ON_DELAY layout_off=$LAYOUT_OFF_DELAY focused_on=$FOCUSED_ON_DELAY focused_off=$FOCUSED_OFF_DELAY"

# --- Storage ---
declare -A MODULES
declare -A MODULE_STATES
declare -A MODULE_ENTER_TS
declare -A MODULE_EXIT_TS

# --- Module parsing ---
parse_modules() {
    echo "Parsing modules from $MODULES_FILE"
    [[ -f "$MODULES_FILE" ]] || { echo "ERROR: Modules file not found"; exit 1; }
    local count=0
    while IFS='|' read -r name onexec offexec type args; do
        name="${name// /}"
        [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue
        MODULES["$name"]="$onexec|$offexec|$type|$args"
        MODULE_STATES["$name"]="disabled"
        ((count++))
        echo "  [$count] $name ($type)"
    done < "$MODULES_FILE"
    echo "Total modules loaded: $count"
}
parse_modules

# --- Filter ---
modules_by_type() {
    local t="$1"
    for n in "${!MODULES[@]}"; do
        IFS='|' read -r _ _ mt _ <<< "${MODULES[$n]}"
        [[ "$mt" == "$t" ]] && echo "$n"
    done
}

# --- Monitor offset cache ---
declare -A MONITOR_OFFSETS
MONITOR_CACHE_TS=0
get_monitor_offset() {
    local mon="$1"; local now; now=$(date +%s)
    if (( now - MONITOR_CACHE_TS > 5 )); then
        local json entry name ox oy
        json=$(mmsg get all-monitors 2>/dev/null)
        if [[ -n "$json" ]]; then
            while IFS= read -r entry; do
                name=$(jq -r '.name' <<< "$entry" 2>/dev/null)
                ox=$(jq -r '.x' <<< "$entry" 2>/dev/null); oy=$(jq -r '.y' <<< "$entry" 2>/dev/null)
                [[ -n "$name" && "$ox" != "null" ]] && MONITOR_OFFSETS["$name"]="$ox,$oy"
            done < <(jq -c '.monitors[]' <<< "$json" 2>/dev/null)
        fi
        MONITOR_CACHE_TS=$now
    fi
    echo "${MONITOR_OFFSETS[$mon]:-0,0}"
}

# --- Check debounce timers and fire actions ---
# Called every ~50ms from the main event loop.
check_fires() {
    local now name onexec offexec mtype on_delay off_delay
    now=$(date +%s%3N)

    # Pending ON fires
    for name in "${!MODULE_ENTER_TS[@]}"; do
        local st=${MODULE_STATES[$name]}
        [[ "$st" != "pending_on" && "$st" != "pending_off" ]] && continue
        IFS='|' read -r _ _ mtype _ <<< "${MODULES[$name]}"
        case "$mtype" in
            zone)    on_delay=$ZONE_ON_DELAY ;;
            layout)  on_delay=$LAYOUT_ON_DELAY ;;
            focused) on_delay=$FOCUSED_ON_DELAY ;;
            *)       on_delay=$ON_DELAY ;;
        esac
        if (( now - MODULE_ENTER_TS[$name] >= on_delay )); then
            if [[ "$st" == "pending_on" ]]; then
                MODULE_STATES["$name"]="enabled"
                IFS='|' read -r onexec _ _ _ <<< "${MODULES[$name]}"
                echo "ON  $name"
                eval "$onexec" &
            fi
            unset "MODULE_ENTER_TS[$name]"
        fi
    done

    # Pending OFF fires
    for name in "${!MODULE_EXIT_TS[@]}"; do
        local st=${MODULE_STATES[$name]}
        [[ "$st" != "pending_off" && "$st" != "enabled" ]] && continue
        IFS='|' read -r _ _ mtype _ <<< "${MODULES[$name]}"
        case "$mtype" in
            zone)    off_delay=$ZONE_OFF_DELAY ;;
            layout)  off_delay=$LAYOUT_OFF_DELAY ;;
            focused) off_delay=$FOCUSED_OFF_DELAY ;;
            *)       off_delay=$OFF_DELAY ;;
        esac
        if (( now - MODULE_EXIT_TS[$name] >= off_delay )); then
            MODULE_STATES["$name"]="disabled"
            IFS='|' read -r _ offexec _ _ <<< "${MODULES[$name]}"
            echo "OFF $name"
            eval "$offexec" &
            unset "MODULE_EXIT_TS[$name]"
        fi
    done
}

# --- Process zone events ---
process_zone_event() {
    local data="$1"

    # Exit event — cursor left the edge zone entirely
    local state
    state=$(jq -r '.state // "enter"' <<< "$data" 2>/dev/null)
    if [[ "$state" == "exit" ]]; then
        local now; now=$(date +%s%3N)
        while IFS= read -r module_name; do
            [[ -z "$module_name" ]] && continue
            local st=${MODULE_STATES[$module_name]}
            if [[ "$st" == "enabled" || "$st" == "pending_on" ]]; then
                MODULE_EXIT_TS[$module_name]=$now
                MODULE_STATES["$module_name"]="pending_off"
                unset "MODULE_ENTER_TS[$module_name]"
            fi
        done < <(modules_by_type "zone")
        return
    fi

    # Enter event — check bounding boxes
    local x y monitor
    x=$(jq -r '.x' <<< "$data" 2>/dev/null)
    y=$(jq -r '.y' <<< "$data" 2>/dev/null)
    monitor=$(jq -r '.monitor' <<< "$data" 2>/dev/null)
    [[ -z "$x" || -z "$y" || -z "$monitor" ]] && return

    local x_int=${x%.*}
    local y_int=${y%.*}
    local offset mx my
    offset=$(get_monitor_offset "$monitor")
    mx="${offset%,*}"; my="${offset#*,}"

    local now; now=$(date +%s%3N)

    while IFS= read -r module_name; do
        [[ -z "$module_name" ]] && continue
        IFS='|' read -r onexec offexec _ args <<< "${MODULES[$module_name]}"
        IFS=',' read -r x1 y1 x2 y2 <<< "$args"
        local ax1=$(( x1 + mx )) ay1=$(( y1 + my ))
        local ax2=$(( x2 + mx )) ay2=$(( y2 + my ))
        local in=$(( x_int >= ax1 && x_int <= ax2 && y_int >= ay1 && y_int <= ay2 ? 1 : 0 ))
        local st=${MODULE_STATES[$module_name]}

        if (( in )); then
            if [[ "$st" == "disabled" ]]; then
                MODULE_ENTER_TS[$module_name]=$now
                MODULE_STATES["$module_name"]="pending_on"
            elif [[ "$st" == "pending_off" ]]; then
                # Re-entered before off delay — cancel OFF, stay enabled
                unset "MODULE_EXIT_TS[$module_name]"
                MODULE_STATES["$module_name"]="enabled"
            fi
        else
            if [[ "$st" == "enabled" || "$st" == "pending_on" ]]; then
                MODULE_EXIT_TS[$module_name]=$now
                MODULE_STATES["$module_name"]="pending_off"
                unset "MODULE_ENTER_TS[$module_name]"
            fi
        fi
    done < <(modules_by_type "zone")
}

# --- Layout event processing ---
process_layout_event() {
    local event="$1"; local layout state event_monitor
    layout=$(jq -r '.layout' <<< "$event" 2>/dev/null)
    state=$(jq -r '.state' <<< "$event" 2>/dev/null)
    event_monitor=$(jq -r '.monitor // empty' <<< "$event" 2>/dev/null)
    [[ -z "$layout" || -z "$state" ]] && return
    local now; now=$(date +%s%3N)
    while IFS= read -r module_name; do
        [[ -z "$module_name" ]] && continue
        IFS='|' read -r onexec offexec _ args <<< "${MODULES[$module_name]}"
        # args = "layout_name" or "layout_name,monitor_name"
        local expected_layout="${args%%,*}"
        local expected_monitor=""
        [[ "$args" == *","* ]] && expected_monitor="${args#*,}"
        [[ "$layout" != "$expected_layout" ]] && continue
        [[ -n "$expected_monitor" && "$event_monitor" != "$expected_monitor" ]] && continue
        local st=${MODULE_STATES[$module_name]}
        if [[ "$state" == "active" && "$st" == "disabled" ]]; then
            MODULE_ENTER_TS[$module_name]=$now
            MODULE_STATES["$module_name"]="pending_on"
        elif [[ "$state" == "inactive" && ( "$st" == "enabled" || "$st" == "pending_on" ) ]]; then
            MODULE_EXIT_TS[$module_name]=$now
            MODULE_STATES["$module_name"]="pending_off"
            unset "MODULE_ENTER_TS[$module_name]"
        fi
    done < <(modules_by_type "layout")
}

# --- Focused event processing ---
process_focused_event() {
    local event="$1"; local app_id state
    app_id=$(jq -r '.app_id' <<< "$event" 2>/dev/null)
    state=$(jq -r '.state' <<< "$event" 2>/dev/null)
    [[ -z "$app_id" || -z "$state" ]] && return
    local now; now=$(date +%s%3N)
    while IFS= read -r module_name; do
        [[ -z "$module_name" ]] && continue
        IFS='|' read -r onexec offexec _ expected <<< "${MODULES[$module_name]}"
        [[ "$app_id" != "$expected" ]] && continue
        local st=${MODULE_STATES[$module_name]}
        if [[ "$state" == "focused" && "$st" == "disabled" ]]; then
            MODULE_ENTER_TS[$module_name]=$now
            MODULE_STATES["$module_name"]="pending_on"
        elif [[ "$state" == "unfocused" && ( "$st" == "enabled" || "$st" == "pending_on" ) ]]; then
            MODULE_EXIT_TS[$module_name]=$now
            MODULE_STATES["$module_name"]="pending_off"
            unset "MODULE_ENTER_TS[$module_name]"
        fi
    done < <(modules_by_type "focused")
}

# --- Start module subprocesses (auto-restarting) ---
echo "Starting modules..."

(
    start_src() {
        local script="$1" label="$2"
        [[ -x "$script" ]] || { echo "WARNING: $script not found — $label disabled" >&2; return; }
        (
            while true; do "$script"; sleep 0.5; done
        ) | while IFS= read -r line; do echo "${label}:$line"; done &
    }
    start_src "$MODULE_DIR/zone.sh"    "zone"
    start_src "$MODULE_DIR/layout.sh"  "layout"
    start_src "$MODULE_DIR/focused.sh" "focused"
    wait
) | while true; do
    if IFS= read -t 0.05 -r line; then
        source="${line%%:*}"
        data="${line#*:}"
        case "$source" in
            zone)    process_zone_event    "$data" ;;
            layout)  process_layout_event  "$data" ;;
            focused) process_focused_event "$data" ;;
        esac
    fi
    check_fires
done
