#!/bin/bash
target=$1
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
timestamp=$(date +%s)

# Hide the screenshot bar so it doesn't appear in captures
pkill -f "screenshot.json" 2>/dev/null || true
sleep 0.5

# Resolve capture geometry/device
case $target in
    output)
        monitor=$(mmsg get cursorpos | python3 -c "import json,sys; print(json.load(sys.stdin)['monitor'])")
        grim_args=(-o "$monitor")
        label="$(echo "$monitor" | sed 's/[-_.]/ /g')"
        ;;
    area)
        grim_args=(-g "$(slurp)")
        label="selected area"
        ;;
    screen)
        grim_args=()
        label="all monitors"
        ;;
    active)
        slurp -p -f "%x,%y" >/dev/null 2>&1
        sleep 0.5
        geom=$(mmsg get focusing-client | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'{d[\"x\"]},{d[\"y\"]} {d[\"width\"]}x{d[\"height\"]}')
")
        grim_args=(-g "$geom")
        label="window"
        ;;
esac

case $mode in
    disk)
        mkdir -p "$save_dir"
        file="$save_dir/screenshot-$timestamp.png"
        grim "${grim_args[@]}" "$file"
        editor_name=$(echo "$editor" | awk '{print $1}' | sed 's|.*/||')
        action=$(notify-send \
            -a "Screenshot" \
            -i "$file" \
            -h "string:image-path:$file" \
            -t 10000 \
            -A "open=Open in $editor_name" \
            "Screenshot saved" \
            "$(basename "$file")")
        if [ "$action" = "open" ]; then
            mmsg dispatch spawn_shell,"$editor $file"
        fi
        ;;
    clipboard)
        file=$(mktemp /tmp/screenshot-XXXXXX.png)
        grim "${grim_args[@]}" "$file"
        wl-copy < "$file"
        notify-send \
            -a "Screenshot" \
            -i "$file" \
            -h "string:image-path:$file" \
            -t 3000 \
            "Screenshot copied" \
            "$label captured to clipboard"
        rm "$file"
        ;;
    editor)
        mkdir -p "$save_dir"
        file="$save_dir/screenshot-$timestamp.png"
        grim "${grim_args[@]}" "$file"
        mmsg dispatch spawn_shell,"$editor $file"
        notify-send \
            -a "Screenshot" \
            -i "$file" \
            -h "string:image-path:$file" \
            -t 3000 \
            "Opening in editor" \
            "$(basename "$file")"
        ;;
esac
