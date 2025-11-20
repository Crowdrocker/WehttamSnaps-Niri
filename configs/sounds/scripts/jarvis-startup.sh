#!/bin/bash
# J.A.R.V.I.S. Startup Script
# Plays time-appropriate greeting on system startup

SOUNDS_DIR="$HOME/.config/jarvis/sounds"

# Get current hour
HOUR=$(date +%H)

# Determine greeting based on time
if [ "$HOUR" -ge 5 ] && [ "$HOUR" -lt 12 ]; then
    # Morning (5 AM - 11:59 AM)
    SOUND="$SOUNDS_DIR/morning.mp3"
elif [ "$HOUR" -ge 12 ] && [ "$HOUR" -lt 18 ]; then
    # Afternoon (12 PM - 5:59 PM)
    SOUND="$SOUNDS_DIR/afternoon.mp3"
else
    # Evening (6 PM - 4:59 AM)
    SOUND="$SOUNDS_DIR/evening.mp3"
fi

# Play sound in background (non-blocking)
if [ -f "$SOUND" ]; then
    mpv --no-video --volume=70 "$SOUND" &
else
    # Fallback to generic startup sound
    if [ -f "$SOUNDS_DIR/startup.mp3" ]; then
        mpv --no-video --volume=70 "$SOUNDS_DIR/startup.mp3" &
    fi
fi

# Optional: Display notification
notify-send -i dialog-information "J.A.R.V.I.S." "All systems operational" -t 3000