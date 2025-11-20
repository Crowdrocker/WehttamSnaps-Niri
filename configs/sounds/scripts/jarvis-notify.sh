#!/bin/bash
# J.A.R.V.I.S. Notification Sound Script
# Plays notification sound for important alerts

SOUNDS_DIR="$HOME/.config/jarvis/sounds"
SOUND="$SOUNDS_DIR/notification.mp3"

# Play notification sound (non-blocking)
if [ -f "$SOUND" ]; then
    mpv --no-video --volume=60 "$SOUND" &
fi