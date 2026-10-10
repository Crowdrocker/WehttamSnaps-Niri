#!/bin/bash
#===============================================================================
# Elevated module — zone OFF handler
# Checks pin state first: if pinned, do nothing.
# Otherwise clears the visible flag and kills the bottom bar waybar
# if no other module is currently visible.
#===============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wayshell"
PIN_FILE="$CACHE_DIR/bottom_elevated_pinned"
VISIBLE_FILE="$CACHE_DIR/bottom_elevated_visible"

# If pinned, ignore the hide trigger
[[ -f "$PIN_FILE" && "$(cat "$PIN_FILE")" == "1" ]] && exit 0

# Clear our visibility
echo 0 > "$VISIBLE_FILE"

# Kill the bottom bar only if no module flag is set
if ! grep -l "1" "$CACHE_DIR"/bottom_*_visible 2>/dev/null | grep -q .; then
    pkill -f "waybar.*bottom-bar" 2>/dev/null || true
fi
