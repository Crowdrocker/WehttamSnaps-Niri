#!/bin/bash
state_file=$HOME/.config/screenshot.state

if [ ! -f "$state_file" ]; then
    mkdir -p "$(dirname "$state_file")"
    cat > "$state_file" <<- EOF
mode=clipboard
save_dir=$HOME/Pictures/Screenshots
editor=gimp
EOF
    new_mode="disk"
else
    mode=$(awk -F= '/^mode=/ {print $2}' "$state_file")
    case $mode in
        disk)      new_mode="clipboard" ;;
        clipboard) new_mode="editor" ;;
        editor)    new_mode="disk" ;;
        *)         new_mode="clipboard" ;;
    esac
    sed -i "s/^mode=.*/mode=$new_mode/" "$state_file"
fi

killall -SIGRTMIN+1 waybar 2>/dev/null
killall -SIGRTMIN+2 waybar 2>/dev/null

case $new_mode in
    disk)      icon_char="" ;;
    clipboard) icon_char="" ;;
    editor)    icon_char="" ;;
esac
notify-send \
    -a "$icon_char" \
    -t 2000 \
    "Screenshot mode" \
    "Changed to: $new_mode"
