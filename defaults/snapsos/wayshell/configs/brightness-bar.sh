#!/bin/bash

BAR_WIDTH=24

get_brightness() {
    brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'
}

pct=$(get_brightness)
[[ -z "$pct" ]] && pct=0

filled=$(( pct * BAR_WIDTH / 100 ))
empty=$(( BAR_WIDTH - filled ))

for ((i=0; i<filled; i++)); do printf "█"; done
for ((i=0; i<empty; i++)); do printf "░"; done
printf "\n"
