#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  powermenu.sh — WehttamSnaps Power / Session Menu               ║
# ║  Super + X  |  Uses wehttamsnaps-powermenu.rasi                 ║
# ╚══════════════════════════════════════════════════════════════════╝

SOUND_SYSTEM="/usr/local/bin/sound-system"
THEME="$HOME/.config/rofi/themes/wehttamsnaps-powermenu.rasi"

CHOICE=$(printf "⏻  Power Off\n  Reboot\n  Suspend\n🔒  Lock Screen\n  Log Out\n  Cancel" | \
    GDK_BACKEND=wayland rofi \
        -dmenu \
        -i \
        -p "J.A.R.V.I.S." \
        -theme "$THEME" \
        -selected-row 5)

case "$CHOICE" in
    "⏻  Power Off")
        $SOUND_SYSTEM shutdown
        sleep 3
        systemctl poweroff
        ;;
    "  Reboot")
        $SOUND_SYSTEM shutdown
        sleep 3
        systemctl reboot
        ;;
    "  Suspend")
        $SOUND_SYSTEM locking-screen
        sleep 1
        systemctl suspend
        ;;
    "🔒  Lock Screen")
        $SOUND_SYSTEM locking-screen
        qs ipc call noctalia-shell lock 2>/dev/null || swaylock
        ;;
    "  Log Out")
        $SOUND_SYSTEM shutdown
        sleep 2
        swaymsg exit
        ;;
    *)
        exit 0
        ;;
esac
