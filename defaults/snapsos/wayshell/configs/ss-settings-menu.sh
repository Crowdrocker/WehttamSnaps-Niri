#!/bin/bash
state_file=$HOME/.config/screenshot.state

if [ ! -f "$state_file" ]; then
    mkdir -p "$(dirname "$state_file")"
    cat > "$state_file" <<- EOF
mode=clipboard
save_dir=$HOME/Pictures/Screenshots
editor=gimp
EOF
fi

mode=$(awk -F= '/^mode=/ {print $2}' "$state_file")
save_dir=$(awk -F= '/^save_dir=/ {print $2}' "$state_file")
editor=$(awk -F= '/^editor=/ {print $2}' "$state_file")

case $mode in
    disk)
        new_dir=$(zenity --file-selection --directory \
            --title="Screenshot save directory" \
            --filename="$save_dir/")
        if [ -n "$new_dir" ]; then
            sed -i "s|^save_dir=.*|save_dir=$new_dir|" "$state_file"
            notify-send \
                -a "" \
                -t 3000 \
                "Save directory" \
                "$(basename "$new_dir")"
        fi
        ;;
    clipboard)
        notify-send \
            -a "" \
            -t 2000 \
            "Clipboard mode" \
            "No settings available"
        ;;
    editor)
        new_editor=$(zenity --entry \
            --title="Screenshot editor" \
            --text="Editor command:" \
            --entry-text="$editor")
        if [ -n "$new_editor" ]; then
            sed -i "s|^editor=.*|editor=$new_editor|" "$state_file"
            notify-send \
                -a "" \
                -t 3000 \
                "Editor" \
                "$new_editor"
        fi
        ;;
esac
