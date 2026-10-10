#!/bin/bash

if [ -e ~/.config/screenshot-state ]; then
    state=$(cat ~/.config/screenshot-state)
    case $state in
        file)
            mkdir -p ~/Screenshots
            grim $HOME/Screenshots/$(date +%Y%m%d%H%M%S).png
            notify-send -t 3000 -a "Screenshots" -i $HOME/Screenshots/$(date +%Y%m%d%H%M%S).png "screenshot taken" "screenshot taken and saved to file in $HOME/screenshots"
            ;;
        clipboard)
            f=$(mktemp -t screenshot-XXXXXX.png) && grim "$f" && wl-copy < "$f" && rm -f "$f"
            notify-send -t 3000 -a "Screenshots" -i $f "screenshot taken" "screenshot taken and saved to clipboard"
            ;;
        editor)
            f=$HOME/Screenshots/$(date +%Y%m%d%H%M%S).png && grim "$f" && satty --filename "$f" --output-filename "$f" --actions-on-enter save-to-file --early-exit &
            notify-send -t 3000 -a "Screenshots" -i "$f" "screenshot taken" "screenshot taken and opened in editor"
            ;;
    esac
else
    echo "clipboard" > ~/.config/screenshot-state
    notify-send -t 3000 -a "Screenshots" "screenshot mode" 'No mode detected, set mode to "Save to Clipboard". re-run your screenshot'
fi