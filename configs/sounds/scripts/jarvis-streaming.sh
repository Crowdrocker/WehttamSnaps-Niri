#!/bin/bash
# J.A.R.V.I.S. Streaming Mode Activation Script
# Activates streaming optimizations and plays J.A.R.V.I.S. sound

SOUNDS_DIR="$HOME/.config/jarvis/sounds"
SOUND="$SOUNDS_DIR/streaming.mp3"
STATE_FILE="/tmp/jarvis-streaming-mode"

# Check if streaming mode is already active
if [ -f "$STATE_FILE" ]; then
    # Deactivate streaming mode
    rm "$STATE_FILE"
    
    # Stop OBS if running
    # pkill obs
    
    # Reset audio routing to normal
    ~/.config/audio/scripts/reset-audio-routing.sh
    
    notify-send -i camera-video "J.A.R.V.I.S." "Streaming mode deactivated" -t 3000
else
    # Activate streaming mode
    touch "$STATE_FILE"
    
    # Play J.A.R.V.I.S. sound
    if [ -f "$SOUND" ]; then
        mpv --no-video --volume=70 "$SOUND" &
    fi
    
    # Set up audio routing for streaming
    ~/.config/audio/scripts/setup-streaming-audio.sh
    
    # Start OBS if not running
    if ! pgrep -x "obs" > /dev/null; then
        obs &
    fi
    
    # Set CPU governor to performance
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    fi
    
    notify-send -i camera-video "J.A.R.V.I.S." "Streaming systems online. All feeds operational." -t 3000
fi