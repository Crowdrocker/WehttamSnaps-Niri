#!/bin/bash
# J.A.R.V.I.S. Shutdown Script
# Plays farewell message before system shutdown

SOUNDS_DIR="$HOME/.config/jarvis/sounds"
SOUND="$SOUNDS_DIR/shutdown.mp3"

# Play shutdown sound (blocking to ensure it plays before shutdown)
if [ -f "$SOUND" ]; then
    mpv --no-video --volume=70 "$SOUND"
fi

# Optional: Display notification
notify-send -i system-shutdown "J.A.R.V.I.S." "Shutting down. Have a good day, Matthew." -t 2000

# Wait a moment for sound to finish
sleep 2