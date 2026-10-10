#!/bin/bash
#===============================================================================
# Elevated module — focus client at position N by reading state file
#===============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wayshell"
STATE_FILE="$CACHE_DIR/bottom_elevated.state"
INDEX="$1"

line=$(grep "^$INDEX|" "$STATE_FILE" 2>/dev/null)
[[ -z "$line" ]] && exit 0

cid=$(echo "$line" | cut -d'|' -f5)
[[ -z "$cid" ]] && exit 0

mmsg dispatch focusid client,"$cid"
