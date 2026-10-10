#!/bin/bash


if [ -e ~/.config/screenshot-state ]; then
    state=$(cat ~/.config/screenshot-state)
    case $state in
        file)
            echo "clipboard" > ~/.config/screenshot-state
            notify-send -t 3000 -a "Screenshots" "toggled screenshot mode" "screenshot mode changed to: \nSave to Clipboard"
            echo "detected file, set to clipboard"
            ;;
        clipboard)
            echo "editor" > ~/.config/screenshot-state
            notify-send -t 3000 -a "Screenshots" "toggled screenshot mode" "screenshot mode changed to: \nOpen in Editor"
            echo "detected clipboard, set to editor"
            ;;
        editor)
            echo "file" > ~/.config/screenshot-state
            notify-send -t 3000 -a "Screenshots" "toggled screenshot mode" "screenshot mode changed to: \nSave to File"
            echo "detected editor, set to file"
            ;;
    esac
else
    echo "clipboard" > ~/.config/screenshot-state
    notify-send -t 3000 -a "Screenshots" "toggled screenshot mode" "screenshot mode changed to: \nSave to Clipboard"
    echo "detected no file ,set to clipboard"
fi



