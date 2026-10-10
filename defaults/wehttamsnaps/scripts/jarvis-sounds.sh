#!/bin/bash

# Path to your FakeYou wav files
SOUND_DIR="$HOME/.config/wehttamsnaps/sounds/jarvis"
PLAYER="paplay" # Using pulse/pipewire native player

case $1 in
    "startup")      $PLAYER "$SOUND_DIR/startup.mp3" ;;
    "shutdown")     $PLAYER "$SOUND_DIR/power_down.wav" ;;
    "screenshot")   $PLAYER "$SOUND_DIR/capture_complete.wav" ;;
    "export")       $PLAYER "$SOUND_DIR/photo-export.mp3" ;;
    "gamemode")     $PLAYER "$SOUND_DIR/performance_engaged.wav" ;;
    "backup")       $PLAYER "$SOUND_DIR/sync_complete.wav" ;;
    *)              echo "Usage: jarvis-sounds.sh [event]" ;;
esac
