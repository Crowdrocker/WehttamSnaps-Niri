#!/bin/bash


if [ -e ~/.config/screenshot-state ]; then
    state=$(cat ~/.config/screenshot-state)
    case $state in
        file)
            mkdir -p ~/Screenshots
            hyprshot -m region --output-folder ~/Screenshots
            ;;
        clipboard)
            hyprshot -m region --clipboard-only
            ;;
        editor)
            hyprshot -m region --raw | satty --filename -
            ;;
    esac
else
    echo "clipboard" > ~/.config/screenshot-state
    notify-send -t 3000 -a "Screenshots" "screenshot mode" 'No mode detected, set mode to "Save to Clipboard". re-run your screenshot'
fi