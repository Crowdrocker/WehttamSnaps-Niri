#!/bin/bash

BAR_WIDTH=20

get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | sed 's/.*: //' | awk '{printf "%.0f\n", $1 * 100}'
}

is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -qi "MUTED" && echo "yes" || echo "no"
}

render_bar() {
    local pct=$1
    local filled=$(( pct * BAR_WIDTH / 100 ))
    local empty=$(( BAR_WIDTH - filled ))
    local text="▲"
    for ((i=0; i<filled; i++)); do text+=$'\n'"█"; done
    for ((i=0; i<empty; i++)); do text+=$'\n'"░"; done
    text+=$'\n'"▼"
    echo "$text"
}

pct=$(get_volume)
[[ -z "$pct" ]] && pct=0
muted=$(is_muted)
bar=$(render_bar "$pct")
cls="volume"
[[ "$muted" == "yes" ]] && cls+=" muted"

# Escape newlines for JSON
escaped=$(printf '%s' "$bar" | awk '{if(NR>1)printf "\\n"; printf "%s", $0}')
printf '{"text":"%s","class":"%s","percentage":%d,"alt":"%d%%"}\n' "$escaped" "$cls" "$pct" "$pct"
