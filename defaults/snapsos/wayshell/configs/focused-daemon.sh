#!/bin/bash
#===============================================================================
# Focused Module — Waybar exec script (multi-role)
#===============================================================================
# Usage:
#   focused-daemon.sh --daemon — gets focused client, reads CPU/RAM for its PID
#   focused-daemon.sh pin     — reads pin + visibility state, shows pin icon
#   focused-daemon.sh cpu     — reads state file, shows CPU percentage
#   focused-daemon.sh mem     — reads state file, shows RAM usage
#   focused-daemon.sh cap     — reads state file, shows window title (first 20 chars)
#   focused-daemon.sh --fps-daemon — reads GPU utilization every 1s, signals RTMIN+3
#   focused-daemon.sh fps     — reads fps state file, shows GPU usage
#
# State file format:
#   cpu|<float>
#   mem|<kb>
#   title|<window title>
#===============================================================================

export LC_NUMERIC=C

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wayshell"
VISIBLE_FILE="$CACHE_DIR/bottom_focused_visible"
PIN_FILE="$CACHE_DIR/bottom_focused_pinned"
STATE_FILE="$CACHE_DIR/bottom_focused.state"
mkdir -p "$CACHE_DIR"

# ======================================================================
#  ROLE: daemon
# ======================================================================
if [[ "$1" == "--daemon" ]]; then
    focused=$(mmsg get all-clients 2>/dev/null | jq -c '.clients[] | select(.is_focused == true)' 2>/dev/null)
    if [[ -z "$focused" ]]; then
        : > "$STATE_FILE"
        pkill -RTMIN+2 -f "waybar.*bottom-bar" 2>/dev/null || true
        printf '{"text":"","class":"focused-daemon hidden","alt":"0"}\n'
        exit 0
    fi

    pid=$(jq -r '.pid // 0' <<< "$focused" 2>/dev/null)
    title=$(jq -r '.title // ""' <<< "$focused" 2>/dev/null)
    appid=$(jq -r '.appid // ""' <<< "$focused" 2>/dev/null)
    cid=$(jq -r '.id // ""' <<< "$focused" 2>/dev/null)

    if [[ "$pid" -eq 0 ]]; then
        : > "$STATE_FILE"
        pkill -RTMIN+2 -f "waybar.*bottom-bar" 2>/dev/null || true
        printf '{"text":"","class":"focused-daemon hidden","alt":"0"}\n'
        exit 0
    fi

    # Collect all descendants of a PID (recursive, depth-limited)
    find_descendants() {
        local p=$1 d=$2
        (( d > 15 )) && return
        for kid in $(ps --ppid "$p" -o pid= 2>/dev/null | tr -d ' '); do
            echo "$kid"
            find_descendants "$kid" $((d + 1))
        done
    }

    # Walk the tree to find the first PID whose CWD or comm appears in $title
    find_pid_matching_title() {
        local search_pid=$1 depth=$2
        (( depth > 10 )) && return 1
        for child in $(ps --ppid "$search_pid" -o pid= 2>/dev/null | tr -d ' '); do
            cwd=$(readlink "/proc/$child/cwd" 2>/dev/null)
            if [[ -n "$cwd" ]]; then
                if [[ "$title" == *"$cwd"* ]]; then
                    echo "$child"; return 0
                fi
                base=$(basename "$cwd" 2>/dev/null)
                if [[ -n "$base" && "$title" == *"$base"* ]]; then
                    echo "$child"; return 0
                fi
            fi
            cmd=$(cat "/proc/$child/comm" 2>/dev/null)
            if [[ -n "$cmd" && "$title" == *"$cmd"* ]]; then
                echo "$child"; return 0
            fi
            found=$(find_pid_matching_title "$child" $((depth + 1))) && { echo "$found"; return 0; }
        done
        return 1
    }

    # Build PID list for CPU/RAM measurement
    client_count=$(mmsg get all-clients 2>/dev/null | jq -c "[.clients[] | select(.pid == $pid)] | length" 2>/dev/null)
    if [[ "${client_count:-1}" -gt 1 ]]; then
        matching=$(find_pid_matching_title "$pid" 1) || true
        if [[ -n "$matching" ]]; then
            # Include: main PID + ancestor chain (IO handlers) + processes on the
            # same TTY (shell + commands — uniquely identifies a terminal window)
            pid_set="$pid"
            current="$matching"
            while true; do
                ppid=$(ps -o ppid= -p "$current" | tr -d ' ' 2>/dev/null)
                [[ -z "$ppid" || "$ppid" -eq "$pid" || "$ppid" -eq 0 ]] && break
                pid_set="${pid_set},${ppid}"
                current="$ppid"
            done
            tty=$(ps -o tty= -p "$matching" | tr -d ' ' 2>/dev/null)
            if [[ -n "$tty" && "$tty" != "?" ]]; then
                while IFS= read -r tty_pid; do
                    pid_set="${pid_set},${tty_pid}"
                done < <(ps -o pid= -t "$tty" 2>/dev/null)
            else
                pid_set="${pid_set},${matching}"
            fi
            pid_list=$(echo "$pid_set" | tr ',' '\n' | sort -nu | paste -sd ',')
        else
            pid_list="$pid"
        fi
    else
        pid_list="$pid"
        while IFS= read -r child; do
            [[ -n "$child" ]] && pid_list="${pid_list},${child}"
        done < <(find_descendants "$pid" 1)
    fi

    # CPU: tick-delta when PID set is stable; ps -o %cpu= fallback on switch
    CPU_CACHE="$CACHE_DIR/bottom_focused_cpu_delta"
    CPU_HIST="$CACHE_DIR/bottom_focused_cpu_hist"
    HZ=$(getconf CLK_TCK 2>/dev/null || echo 100)
    total_ticks=0
    IFS=',' read -ra pid_arr <<< "$pid_list"
    for p in "${pid_arr[@]}"; do
        t=$(awk '{print $14+$15}' "/proc/$p/stat" 2>/dev/null)
        total_ticks=$((total_ticks + ${t:-0}))
    done
    now=$(date +%s)
    raw_cpu=0.0
    if [[ -f "$CPU_CACHE" ]]; then
        read prev_pids prev_ticks prev_time < "$CPU_CACHE" 2>/dev/null || true
        if [[ -n "$prev_pids" && "$prev_pids" == "$pid_list" ]]; then
            dt=$((now - prev_time))
            dticks=$((total_ticks - prev_ticks))
            if (( dt > 0 && dticks >= 0 )); then
                raw_cpu=$(echo "scale=2; $dticks * 100 / ($HZ * $dt)" | bc -l 2>/dev/null)
                : "${raw_cpu:=0.0}"
            fi
        else
            # PID set changed (window switch or process churn).
            # Use ps -o %cpu= as a reasonable one-cycle bridge value.
            raw_cpu=$(ps -o %cpu= -p "$pid_list" 2>/dev/null | awk '{s+=$1} END{printf "%.2f", s}')
            : "${raw_cpu:=0.0}"
            # Reset history so the bridge value takes effect immediately
            : > "$CPU_HIST"
        fi
    fi
    echo "$pid_list $total_ticks $now" > "$CPU_CACHE"
    # Rolling max-of-last-5 history
    echo "$raw_cpu" >> "$CPU_HIST"
    cpu_total=$(tail -n 5 "$CPU_HIST" | sort -nr | head -1)
    tail -n 5 "$CPU_HIST" > "${CPU_HIST}.tmp" && mv "${CPU_HIST}.tmp" "$CPU_HIST"

    rss_total=$(ps -o rss= -p "$pid_list" 2>/dev/null | awk '{s+=$1} END{print s}')
    : "${rss_total:=0}"

    tmp="${STATE_FILE}.tmp"
    printf 'cpu|%s\nmem|%s\ntitle|%s\nappid|%s\ncid|%s\n' \
        "$cpu_total" "$rss_total" "$title" "$appid" "$cid" > "$tmp"
    mv "$tmp" "$STATE_FILE"

    pkill -RTMIN+2 -f "waybar.*bottom-bar" 2>/dev/null || true
    printf '{"text":"","class":"focused-daemon hidden","alt":"0"}\n'
    exit 0
fi

# ======================================================================
#  ROLE: pin
# ======================================================================
if [[ "$1" == "pin" ]]; then
    if [[ ! -f "$VISIBLE_FILE" || "$(cat "$VISIBLE_FILE")" != "1" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi
    if [[ -f "$PIN_FILE" && "$(cat "$PIN_FILE")" == "1" ]]; then
        printf '{"text":"","tooltip":"Pinned · click to unpin","class":"focused-pin pinned","alt":"1"}\n'
    else
        printf '{"text":"","tooltip":"Unpinned · click to pin","class":"focused-pin","alt":"0"}\n'
    fi
    exit 0
fi

# ======================================================================
#  ROLE: cpu
# ======================================================================
if [[ "$1" == "cpu" ]]; then
    if [[ ! -f "$VISIBLE_FILE" || "$(cat "$VISIBLE_FILE")" != "1" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi
    val=$(grep "^cpu|" "$STATE_FILE" 2>/dev/null | cut -d'|' -f2)
    if [[ -z "$val" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi
    cores=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
    pct=$(echo "scale=2; $val / $cores" | bc -l 2>/dev/null)
    printf '{"text":"  %.1f%%","tooltip":"CPU usage of focused process","class":"focused-cpu","alt":"%s"}\n' "$pct" "$val"
    exit 0
fi

# ======================================================================
#  ROLE: mem
# ======================================================================
if [[ "$1" == "mem" ]]; then
    if [[ ! -f "$VISIBLE_FILE" || "$(cat "$VISIBLE_FILE")" != "1" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi
    val=$(grep "^mem|" "$STATE_FILE" 2>/dev/null | cut -d'|' -f2)
    if [[ -z "$val" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi
    if (( val > 1048576 )); then
        human=$(echo "scale=1; $val / 1048576" | bc -l 2>/dev/null)
        unit="G"
    elif (( val > 1024 )); then
        human=$((val / 1024))
        unit="M"
    else
        human=$val
        unit="K"
    fi
    printf '{"text":" %s%s","tooltip":"RAM usage of focused process","class":"focused-mem","alt":"%s"}\n' \
        "$human" "$unit" "$val"
    exit 0
fi

# ======================================================================
#  ROLE: cap
# ======================================================================
if [[ "$1" == "cap" ]]; then
    if [[ ! -f "$VISIBLE_FILE" || "$(cat "$VISIBLE_FILE")" != "1" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi
    title=$(grep "^title|" "$STATE_FILE" 2>/dev/null | cut -d'|' -f2-)
    appid=$(grep "^appid|" "$STATE_FILE" 2>/dev/null | cut -d'|' -f2-)
    display="${title:-${appid}}"
    if [[ -z "$display" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi
    printf '{"text":"%.20s","tooltip":"%s","class":"focused-cap","alt":"0"}\n' "$display" "$display"
    exit 0
fi

# ======================================================================
#  ROLE: --fps-daemon — GPU utilization via nvidia-smi
# ======================================================================
if [[ "$1" == "--fps-daemon" ]]; then
    gpu=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader 2>/dev/null | tr -d ' %')
    : "${gpu:=0}"
    pstate=$(nvidia-smi --query-gpu=pstate --format=csv,noheader 2>/dev/null | tr -d ' ')
    : "${pstate:=P?}"
    printf '%s|%s\n' "$gpu" "$pstate" > "$CACHE_DIR/bottom_focused_fps.state"
    pkill -RTMIN+3 -f "waybar.*bottom-bar" 2>/dev/null || true
    printf '{"text":"","class":"focused-fps-daemon hidden","alt":"0"}\n'
    exit 0
fi

# ======================================================================
#  ROLE: fps — display GPU utilization
# ======================================================================
if [[ "$1" == "fps" ]]; then
    if [[ ! -f "$VISIBLE_FILE" || "$(cat "$VISIBLE_FILE")" != "1" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi
    line=$(cat "$CACHE_DIR/bottom_focused_fps.state" 2>/dev/null)
    if [[ -z "$line" ]]; then
        printf '{"text":"","class":"hidden","alt":"0"}\n'
        exit 0
    fi
    IFS='|' read -r gpu pstate <<< "$line"
    printf '{"text":"  %s%% %s","tooltip":"GPU utilization","class":"focused-fps","alt":"%s"}\n' "$gpu" "$pstate" "$gpu"
    exit 0
fi
