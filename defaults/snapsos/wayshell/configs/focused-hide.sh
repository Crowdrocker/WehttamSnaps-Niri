#!/bin/bash

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wayshell"
PIN_FILE="$CACHE_DIR/bottom_focused_pinned"
VISIBLE_FILE="$CACHE_DIR/bottom_focused_visible"

[[ -f "$PIN_FILE" && "$(cat "$PIN_FILE")" == "1" ]] && exit 0

echo 0 > "$VISIBLE_FILE"

if ! grep -l "1" "$CACHE_DIR"/bottom_*_visible 2>/dev/null | grep -q .; then
    pkill -f "waybar.*bottom-bar" 2>/dev/null || true
fi
