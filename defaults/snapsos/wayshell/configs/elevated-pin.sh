#!/bin/bash
#===============================================================================
# Elevated module — pin toggle
# Toggles the pin state file, then signals waybar to refresh the pin module
# (and any other module listening on SIGRTMIN+1).
#===============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wayshell"
PIN_FILE="$CACHE_DIR/bottom_elevated_pinned"
mkdir -p "$CACHE_DIR"

if [[ -f "$PIN_FILE" && "$(cat "$PIN_FILE")" == "1" ]]; then
    echo "0" > "$PIN_FILE"
else
    echo "1" > "$PIN_FILE"
fi

pkill -RTMIN+1 -f "waybar.*bottom-bar" 2>/dev/null || true
