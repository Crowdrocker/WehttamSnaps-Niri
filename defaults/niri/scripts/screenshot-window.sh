#!/usr/bin/env bash
# Captures just the focused window, using mango's `mmsg` IPC tool.
# Requires: grim, jq
set -euo pipefail
mkdir -p "$HOME/Pictures/Screenshots"
geometry=$(mmsg get focusing-client | jq -r '"\(.x),\(.y) \(.width)x\(.height)"')
[ -z "$geometry" ] && exit 1
grim -g "$geometry" "$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"
sound-system screenshot
