#!/bin/bash
state_file=$HOME/.config/screenshot.state

icon=""
if [ -f "$state_file" ]; then
    mode=$(awk -F= '/^mode=/ {print $2}' "$state_file")
    case $mode in
        disk)   icon="" ;;
        editor) icon="" ;;
    esac
fi
echo "$icon"
