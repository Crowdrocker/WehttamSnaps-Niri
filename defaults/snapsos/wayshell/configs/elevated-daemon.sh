#!/bin/bash
#===============================================================================
# Elevated Module — Waybar exec script (multi-role)
#===============================================================================
# Usage:
#   elevated-daemon.sh --daemon   — runs detection, writes state, outputs blank
#   elevated-daemon.sh pin        — reads pin + visibility state, shows pin icon
#   elevated-daemon.sh cap        — reads state file, shows elevated process count
#   elevated-daemon.sh <1-9>      — reads state file, shows client at position N
#
# State file format (line-based, one entry per elevated client):
#   <pos>|<title>|<monitor>|<tag>|<cid>
#===============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wayshell"
VISIBLE_FILE="$CACHE_DIR/bottom_elevated_visible"
PIN_FILE="$CACHE_DIR/bottom_elevated_pinned"
STATE_FILE="$CACHE_DIR/bottom_elevated.state"
mkdir -p "$CACHE_DIR"

# ======================================================================
#  ROLE: daemon — elevated detection
# ======================================================================
if [[ "$1" == "--daemon" ]]; then

    is_elevated() {
        local pid=$1
        [[ -f "/proc/$pid/status" ]] || return 1
        local uid
        uid=$(awk '/Uid:/ {print $2}' "/proc/$pid/status" 2>/dev/null)
        [[ "$uid" -eq 0 ]]
    }

    # Walk the process tree from a PID, collecting names of UID 0 descendants.
    # Outputs one name per line (command name from /proc/PID/comm).
    find_elevated_descendants() {
        local pid=$1 depth=$2
        (( depth > 15 )) && return
        local children
        children=$(ps --ppid "$pid" -o pid= | tr -d ' ')
        for child in $children; do
            if is_elevated "$child"; then
                cat "/proc/$child/comm" 2>/dev/null
            fi
            find_elevated_descendants "$child" $((depth + 1))
        done
    }

    # Fetch clients
    clients_json=$(mmsg get all-clients 2>/dev/null)
    if [[ -z "$clients_json" ]]; then
        printf '{"text":"","class":"elevated-daemon hidden","alt":"0"}\n'
        exit 0
    fi

    if echo "$clients_json" | jq -e '.clients' > /dev/null 2>&1; then
        clients_array=$(echo "$clients_json" | jq -c '.clients')
    else
        clients_array="$clients_json"
    fi

    # --- Pass 1: group clients by PID ---
    declare -A pid_clients   # pid → pipe-sep JSON strings
    declare -A pid_count     # pid → count
    while IFS= read -r client; do
        [[ -z "$client" ]] && continue
        pid=$(jq -r '.pid // 0' <<< "$client" 2>/dev/null)
        [[ "$pid" -le 0 ]] && continue
        pid_clients["$pid"]="${pid_clients[$pid]}|$client"
        pid_count["$pid"]=$((pid_count["$pid"] + 1))
    done < <(jq -c '.[] | select(.pid != null and .pid > 0)' <<< "$clients_array" 2>/dev/null)

    # --- Pass 2: for each PID, scan once and decide which clients are elevated ---
    tmp="${STATE_FILE}.tmp"
    : > "$tmp"
    idx=1

    for pid in "${!pid_clients[@]}"; do
        elevated_names=$(find_elevated_descendants "$pid" 1)
        [[ -z "$elevated_names" ]] && continue  # no elevated processes under this PID

        IFS='|' read -ra clients <<< "${pid_clients[$pid]}"

        if (( pid_count[$pid] == 1 )); then
            # Single client — unambiguous, always show it
            client="${clients[0]}"
            title=$(jq -r '.title // ""' <<< "$client" 2>/dev/null)
            monitor=$(jq -r '.monitor // ""' <<< "$client" 2>/dev/null)
            tag=$(jq -r '.tag // ""' <<< "$client" 2>/dev/null)
            cid=$(jq -r '.id // ""' <<< "$client" 2>/dev/null)
            printf '%s|%s|%s|%s|%s\n' "$idx" "$title" "$monitor" "$tag" "$cid" >> "$tmp"
            idx=$((idx + 1))
        else
            # Multiple clients share one PID — match title against elevated names
            title_lower=$(jq -r '.title // ""' <<< "$client" 2>/dev/null | tr '[:upper:]' '[:lower:]')

            for client in "${clients[@]}"; do
                [[ -z "$client" ]] && continue
                title=$(jq -r '.title // ""' <<< "$client" 2>/dev/null)
                title_lower=$(echo "$title" | tr '[:upper:]' '[:lower:]')

                match=false
                while IFS= read -r name; do
                    [[ -z "$name" ]] && continue
                    name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
                    if [[ "$title_lower" == *"$name_lower"* ]]; then
                        match=true
                        break
                    fi
                done <<< "$elevated_names"

                if $match; then
                    monitor=$(jq -r '.monitor // ""' <<< "$client" 2>/dev/null)
                    tag=$(jq -r '.tag // ""' <<< "$client" 2>/dev/null)
                    cid=$(jq -r '.id // ""' <<< "$client" 2>/dev/null)
                    printf '%s|%s|%s|%s|%s\n' "$idx" "$title" "$monitor" "$tag" "$cid" >> "$tmp"
                    idx=$((idx + 1))
                fi
            done
        fi
    done

    # Only signal on actual state change to avoid blink
    if [[ -f "$STATE_FILE" ]]; then
        if ! diff -q "$tmp" "$STATE_FILE" > /dev/null 2>&1; then
            mv "$tmp" "$STATE_FILE"
            pkill -RTMIN+1 -f "waybar.*bottom-bar" 2>/dev/null || true
        else
            rm -f "$tmp"
        fi
    else
        mv "$tmp" "$STATE_FILE"
        pkill -RTMIN+1 -f "waybar.*bottom-bar" 2>/dev/null || true
    fi
    printf '{"text":"","class":"elevated-daemon hidden","alt":"0"}\n'
    exit 0
fi

# ======================================================================
#  ROLE: pin — show pin/unpin button
# ======================================================================
if [[ "$1" == "pin" ]]; then
    if [[ ! -f "$VISIBLE_FILE" || "$(cat "$VISIBLE_FILE")" != "1" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi

    if [[ -f "$PIN_FILE" && "$(cat "$PIN_FILE")" == "1" ]]; then
        printf '{"text":"","tooltip":"Pinned · click to unpin","class":"elevated-pin pinned","alt":"1"}\n'
    else
        printf '{"text":"","tooltip":"Unpinned · click to pin","class":"elevated-pin","alt":"0"}\n'
    fi
    exit 0
fi

# ======================================================================
#  ROLE: <N> — show client at position N from state file
# ======================================================================
if [[ "$1" == "cap" ]]; then
    if [[ ! -f "$VISIBLE_FILE" || "$(cat "$VISIBLE_FILE")" != "1" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi
    count=$(wc -l < "$STATE_FILE" 2>/dev/null)
    : "${count:=0}"
    printf '{"text":"","tooltip":"Elevated processes running","class":"elevated-cap","alt":"%s"}\n' "$count"
    exit 0
fi

if [[ "$1" =~ ^[1-9]$ ]]; then
    if [[ ! -f "$VISIBLE_FILE" || "$(cat "$VISIBLE_FILE")" != "1" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi

    if [[ ! -f "$STATE_FILE" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi

    line=$(grep "^$1|" "$STATE_FILE" 2>/dev/null)
    if [[ -z "$line" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi

    IFS='|' read -r pos title monitor tag cid <<< "$line"
    tooltip="$title"
    local_info=""
    [[ -n "$tag" ]] && local_info="tag:$tag"
    [[ -n "$monitor" ]] && local_info="${local_info:+$local_info, }$monitor"
    [[ -n "$local_info" ]] && tooltip="$tooltip ($local_info)"

    short="${title:0:20}"
    printf '{"text":"%s","tooltip":"%s","class":"elevated-app","alt":"%s"}\n' "$short" "$tooltip" "$pos"
    exit 0
fi
