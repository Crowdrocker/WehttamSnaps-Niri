#!/bin/bash
# J.A.R.V.I.S. Gaming Mode Activation Script
# Activates gaming optimizations and plays J.A.R.V.I.S. sound

SOUNDS_DIR="$HOME/.config/jarvis/sounds"
SOUND="$SOUNDS_DIR/gaming.mp3"
STATE_FILE="/tmp/jarvis-gaming-mode"

# Check if gaming mode is already active
if [ -f "$STATE_FILE" ]; then
    # Deactivate gaming mode
    rm "$STATE_FILE"
    
    # Stop gamemode
    pkill -f gamemode
    
    # Reset GPU to normal profile
    if command -v corectrl &> /dev/null; then
        corectrl --profile normal &
    fi
    
    notify-send -i applications-games "J.A.R.V.I.S." "Gaming mode deactivated" -t 3000
else
    # Activate gaming mode
    touch "$STATE_FILE"
    
    # Play J.A.R.V.I.S. sound
    if [ -f "$SOUND" ]; then
        mpv --no-video --volume=70 "$SOUND" &
    fi
    
    # Start gamemode
    if command -v gamemoded &> /dev/null; then
        gamemoded &
    fi
    
    # Set GPU to performance profile
    if command -v corectrl &> /dev/null; then
        corectrl --profile performance &
    fi
    
    # Disable compositor effects (if using one)
    # This is handled by Niri automatically
    
    # Set CPU governor to performance
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    fi
    
    notify-send -i applications-games "J.A.R.V.I.S." "Gaming mode activated. Systems at maximum performance." -t 3000
fi