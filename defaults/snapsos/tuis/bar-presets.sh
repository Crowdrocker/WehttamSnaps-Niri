#!/bin/bash

options="Toggle Default Top Bar
Toggle Taskbar Style Bar
Toggle Top Status Bar
Toggle Left Side Bar
Toggle Right Side Bar
Toggle Dock
preset 1 (classic)
preset 2 (windows-like)
preset 3 (mac-like)
preset 4 (combo)
preset 5 (sidebar)
preset 6 (side+status)
"

SELECTED=$(echo "$options" | fzf --layout=reverse)

case $SELECTED in
    "Toggle Default Top Bar")
        dms ipc call bar toggle index 0
        notify-send "Top Bar toggled"
        ;;
    "Toggle Taskbar Style Bar")
        dms ipc call bar toggle index 1
        notify-send "Taskbar toggled"
        ;;
    "Toggle Top Status Bar")
        dms ipc call bar toggle index 2
        notify-send "Status Bar toggled"
        ;;
    "Toggle Left Side Bar")
        dms ipc call bar toggle index 3
        dms ipc call bar setPosition index 3 left
        notify-send "Left Side Bar toggled"
        ;;
    "Toggle Right Side Bar")
        dms ipc call bar toggle index 3
        dms ipc call bar setPosition index 3 right
        notify-send "Right Side Bar toggled"
        ;;
    "Toggle Dock")
        dms ipc call dock toggle
        notify-send "toggled dock"
        ;;
    "preset 1 (classic)")
        dms ipc call dock hide
        dms ipc call bar hide index 3
        dms ipc call bar hide index 2
        dms ipc call bar hide index 1
        dms ipc call bar reveal index 0
        ;;
    "preset 2 (windows-like)")
        dms ipc call dock hide
        dms ipc call bar hide index 3
        dms ipc call bar hide index 2
        dms ipc call bar reveal index 1
        dms ipc call bar hide index 0
        ;;
    "preset 3 (mac-like)")
        dms ipc call dock reveal
        dms ipc call bar hide index 3
        dms ipc call bar reveal index 2
        dms ipc call bar hide index 1
        dms ipc call bar hide index 0
        ;;
    "preset 4 (combo)")
        dms ipc call dock hide
        dms ipc call bar hide index 3
        dms ipc call bar reveal index 2
        dms ipc call bar reveal index 1
        dms ipc call bar hide index 0
        ;;
    "preset 5 (sidebar)")
        dms ipc call dock hide
        dms ipc call bar setPosition index 3 left
        dms ipc call bar reveal index 3
        dms ipc call bar hide index 2
        dms ipc call bar hide index 1
        dms ipc call bar hide index 0
        ;;
    "preset 6 (side+status)")
        dms ipc call dock hide
        dms ipc call bar setPosition index 3 left
        dms ipc call bar hide index 3
        dms ipc call bar reveal index 2
        dms ipc call bar hide index 1
        dms ipc call bar hide index 0
        dms ipc call bar reveal index 3
        ;;
    
esac