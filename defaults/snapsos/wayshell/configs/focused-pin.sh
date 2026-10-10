#!/bin/bash

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wayshell"
PIN_FILE="$CACHE_DIR/bottom_focused_pinned"
mkdir -p "$CACHE_DIR"

if [[ -f "$PIN_FILE" && "$(cat "$PIN_FILE")" == "1" ]]; then
    echo "0" > "$PIN_FILE"
else
    echo "1" > "$PIN_FILE"
fi

pkill -RTMIN+2 -f "waybar.*bottom-bar" 2>/dev/null || true
