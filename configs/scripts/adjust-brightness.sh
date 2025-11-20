#!/bin/env bash
# adjust brightness script 2024-10-20
# raise and lower brightness 
# send a notification

# adjust brightness based on input
if [[ "$1" == "--inc" ]]; then
  brightnessctl set +5%
elif [[ "$1" == "--dec" ]]; then
  brightnessctl set 5%-
fi

# get current brightness
currentBrightness=$(brightnessctl -m | awk -F ',' '{print $4}')

# notify user
notify-send -h string:x-canonical-private-synchronous:sys-notify \
    -u low "Brightness: $currentBrightness" -h int:value:$currentBrightness \
    --transient
