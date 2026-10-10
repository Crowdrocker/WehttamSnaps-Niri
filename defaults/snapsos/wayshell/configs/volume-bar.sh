#!/bin/bash

BAR_WIDTH=24

get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | sed 's/.*: //' | awk '{printf "%.0f\n", $1 * 100}'
}

pct=$(get_volume)
[[ -z "$pct" ]] && pct=0

filled=$(( pct * BAR_WIDTH / 100 ))
empty=$(( BAR_WIDTH - filled ))

for ((i=0; i<filled; i++)); do printf "█"; done
for ((i=0; i<empty; i++)); do printf "░"; done
printf "\n"
