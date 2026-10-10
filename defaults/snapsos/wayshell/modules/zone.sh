#!/bin/bash
#===============================================================================
# Zone Detection Daemon
#===============================================================================
# Description:
#   Polls cursor position via `mmsg get cursorpos` and outputs JSON when the
#   cursor is within ZONE_BUFFER pixels of any screen edge. Emits an exit
#   event when the cursor leaves the edge zone, so the daemon knows the
#   exact departure time for proper trailing-edge debounce.
#
#   Uses monitor-relative coordinates so edge detection works on any monitor.
#
# Dependencies: jq, mmsg
#
# Output format (JSON lines):
#   In zone: {"x":<float>,"y":<float>,"monitor":"<name>"}
#   On exit: {"state":"exit","x":<float>,"y":<float>,"monitor":"<name>"}
#===============================================================================

CONFIG_FILE="${HOME}/.config/snapsos/wayshell/wayshell.conf"

ZONE_BUFFER=$(grep -oP 'zone_buffer=\K[0-9]+' "$CONFIG_FILE" 2>/dev/null || echo "10")
ZONE_BUFFER=${ZONE_BUFFER:-10}
POLL_INTERVAL=0.1

was_in_zone=false
last_x=""
last_y=""
last_monitor=""

declare -A MONITOR_CACHE
MONITOR_CACHE_AGE=0

get_monitor_info() {
    local mon="$1"
    local now
    now=$(date +%s)

    if (( now - MONITOR_CACHE_AGE > 5 )) || [[ -z "${MONITOR_CACHE[$mon]}" ]]; then
        local json entry name w h ox oy
        json=$(mmsg get all-monitors 2>/dev/null)
        if [[ -n "$json" ]]; then
            while IFS= read -r entry; do
                name=$(jq -r '.name' <<< "$entry" 2>/dev/null)
                w=$(jq -r '.width' <<< "$entry" 2>/dev/null)
                h=$(jq -r '.height' <<< "$entry" 2>/dev/null)
                ox=$(jq -r '.x' <<< "$entry" 2>/dev/null)
                oy=$(jq -r '.y' <<< "$entry" 2>/dev/null)
                if [[ -n "$name" && "$w" != "null" && "$h" != "null" ]]; then
                    MONITOR_CACHE["$name"]="$w $h ${ox:-0} ${oy:-0}"
                fi
            done < <(jq -c '.monitors[]' <<< "$json" 2>/dev/null)
        fi
        MONITOR_CACHE_AGE=$now
    fi

    echo "${MONITOR_CACHE[$mon]:-1920 1080 0 0}"
}

while true; do
    cursor_info=$(mmsg get cursorpos 2>/dev/null)
    if [[ -z "$cursor_info" ]]; then
        sleep "$POLL_INTERVAL"
        continue
    fi

    x=$(jq -r '.x' <<< "$cursor_info" 2>/dev/null)
    y=$(jq -r '.y' <<< "$cursor_info" 2>/dev/null)
    monitor=$(jq -r '.monitor' <<< "$cursor_info" 2>/dev/null)

    if [[ -z "$x" || -z "$y" || -z "$monitor" ]]; then
        sleep "$POLL_INTERVAL"
        continue
    fi

    read -r width height m_x m_y <<< "$(get_monitor_info "$monitor")"
    if [[ -z "$width" || -z "$height" ]]; then
        sleep "$POLL_INTERVAL"
        continue
    fi

    local_x=$(( ${x%.*} - m_x ))
    local_y=$(( ${y%.*} - m_y ))

    in_zone=false
    (( local_x < ZONE_BUFFER )) && in_zone=true
    (( local_x > width - ZONE_BUFFER )) && in_zone=true
    (( local_y < ZONE_BUFFER )) && in_zone=true
    (( local_y > height - ZONE_BUFFER )) && in_zone=true

    if $in_zone && ! $was_in_zone; then
        echo "$cursor_info"
    elif ! $in_zone && $was_in_zone; then
        echo "{\"state\":\"exit\",\"x\":$last_x,\"y\":$last_y,\"monitor\":\"$last_monitor\"}"
    fi

    was_in_zone=$in_zone
    last_x=$x
    last_y=$y
    last_monitor=$monitor

    sleep "$POLL_INTERVAL"
done
