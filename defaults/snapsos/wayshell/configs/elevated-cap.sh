#!/bin/bash

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wayshell"
VISIBLE_FILE="$CACHE_DIR/bottom_elevated_visible"
PIN_FILE="$CACHE_DIR/bottom_elevated_pinned"
STATE_FILE="$CACHE_DIR/bottom_elevated.state"

VISIBLE=$(cat $VISIBLE_FILE)

if [ "$VISIBLE" == "1" ]; then
    echo "sudo"
fi