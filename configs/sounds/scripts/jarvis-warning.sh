#!/bin/bash
# J.A.R.V.I.S. Warning Script
# Plays warning sound for critical system alerts

SOUNDS_DIR="$HOME/.config/jarvis/sounds"
SOUND="$SOUNDS_DIR/warning.mp3"

# Get the warning message from argument
WARNING_MSG="${1:-System warning detected}"

# Play warning sound
if [ -f "$SOUND" ]; then
    mpv --no-video --volume=80 "$SOUND" &
fi

# Display urgent notification
notify-send -u critical -i dialog-warning "J.A.R.V.I.S. WARNING" "$WARNING_MSG" -t 5000