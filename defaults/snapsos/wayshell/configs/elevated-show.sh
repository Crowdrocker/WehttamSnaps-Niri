#!/bin/bash
#===============================================================================
# Elevated module — zone ON handler
# Sets the elevated module visible flag, then launches the bottom bar
# waybar if it isn't already running.
#===============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wayshell"
VISIBLE_FILE="$CACHE_DIR/bottom_elevated_visible"
mkdir -p "$CACHE_DIR"

echo 1 > "$VISIBLE_FILE"

if ! pgrep -f "waybar.*bottom-bar" > /dev/null 2>&1; then
    mmsg dispatch spawn_shell,waybar \
        -c ~/.config/snapsos/wayshell/configs/bottom-bar.json \
        -s ~/.config/snapsos/wayshell/configs/bottom-bar.css
fi
