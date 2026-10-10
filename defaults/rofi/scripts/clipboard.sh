#!/usr/bin/env bash
# clipboard.sh — Clipboard history via cliphist + rofi
# Super + V

THEME="$HOME/.config/rofi/themes/wehttamsnaps.rasi"

cliphist list | \
    GDK_BACKEND=wayland rofi \
        -dmenu \
        -p "J.A.R.V.I.S." \
        -mesg "Clipboard History" \
        -theme "$THEME" \
        -theme-str 'window {width: 700px;}' | \
    cliphist decode | \
    wl-copy
