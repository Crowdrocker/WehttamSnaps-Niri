#!/bin/bash

BAR_WIDTH=20

get_brightness() {
    brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'
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

pct=$(get_brightness)
[[ -z "$pct" ]] && pct=0
bar=$(render_bar "$pct")

# Escape newlines for JSON
escaped=$(printf '%s' "$bar" | awk '{if(NR>1)printf "\\n"; printf "%s", $0}')
printf '{"text":"%s","class":"brightness","percentage":%d,"alt":"%d%%"}\n' "$escaped" "$pct" "$pct"
