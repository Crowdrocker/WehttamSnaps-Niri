#!/bin/bash
state_file=$HOME/.config/screenshot.state

tooltip="Settings"

if [ -f "$state_file" ]; then
    mode=$(awk -F= '/^mode=/ {print $2}' "$state_file")
    save_dir=$(awk -F= '/^save_dir=/ {print $2}' "$state_file")
    editor=$(awk -F= '/^editor=/ {print $2}' "$state_file")
    case $mode in
        disk)      tooltip="Save to: $save_dir" ;;
        clipboard) tooltip="Clipboard mode" ;;
        editor)    tooltip="Editor: $editor" ;;
    esac
fi

echo "{\"text\":\"\",\"tooltip\":\"$tooltip\"}"
