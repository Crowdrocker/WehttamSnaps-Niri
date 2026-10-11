#!/bin/bash
# Per-monitor screenshot menu for MangoWM (wlroots).
# Uses wlr-randr for output names; see https://github.com/mangowm/mango/wiki

set -euo pipefail

if ! command -v wlr-randr >/dev/null 2>&1; then
	notify-send -u critical "Screenshot menu" "Install wlr-randr (wlroots)."
	exit 1
fi

MONITORS=$(wlr-randr | awk '/^Output /{print $2}')

SELECTED=$(echo "$MONITORS" | fuzzel --dmenu --prompt "Capture monitor: " --lines 8) || exit 1
[ -z "$SELECTED" ] && exit 1

OUTPUT_NAME=$(echo "$SELECTED" | awk '{print $1}')

if [ "$1" = "--file" ]; then
	mkdir -p "${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
	FILENAME="Screenshot_${OUTPUT_NAME}_$(date '+%Y-%m-%d_%H-%M-%S').png"
	grim -o "$OUTPUT_NAME" "${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots/$FILENAME"
	notify-send -i screenshot "Screenshot saved" "$FILENAME"
else
	grim -o "$OUTPUT_NAME" - | wl-copy --type image/png
	notify-send -i screenshot "Screenshot taken" "$OUTPUT_NAME copied to clipboard"
fi
