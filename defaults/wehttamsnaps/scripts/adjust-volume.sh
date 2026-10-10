#!/bin/env bash
# adjust volume script 2024-10-20
# raise and lower volume and mute using pamixer 
# send a notification

# adjust volume based on input
if [[ "$1" == "--mute" ]]; then
	pamixer --toggle-mute
elif [[ "$1" == "--mic-mute" ]]; then
	pamixer --default-source --toggle-mute
elif [[ "$1" == "--inc" ]]; then
	pamixer --increase 5
elif [[ "$1" == "--dec" ]]; then
	pamixer --decrease 5
fi

currentMsg="Error: No valid inputs."
currentPct=$(pamixer --get-volume)
isMuted=$(pamixer --get-mute)
isMicMuted=$(pamixer --default-source --get-mute)

# notify the user
if  [[ "$1" == "--mic-mute" ]]; then
	if [[ "$isMicMuted" == "true" ]]; then
		currentMsg="Microphone:  Muted"
	else
		currentMsg="Microphone:  Unmuted" 
	fi
	notify-send -h string:x-canonical-private-synchronous:sys-notify \
	  -u low $currentMsg --transient
else
	if  [[ "$isMuted" == "true" ]]; then
		currentPct=0
		currentMsg="Volume:  Muted"
	else
		currentMsg="Volume:  $currentPct%"
	fi
	notify-send -h string:x-canonical-private-synchronous:sys-notify \
	  -u low $currentMsg -h int:value:$currentPct --transient
fi

