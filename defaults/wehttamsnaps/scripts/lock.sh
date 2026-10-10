#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#   WehttamSnaps Lock Screen
#   Super + Ctrl + L to lock
#   github.com/Crowdrocker  |  twitch.tv/WehttamSnaps
# ═══════════════════════════════════════════════════════════════════════

WALL="$HOME/.config/wehttamsnaps/wallpaper/Wall.jpg"
CACHE="$HOME/.cache/wehttamsnaps"
LOCK_IMG="$CACHE/lockscreen.png"

mkdir -p "$CACHE"

# ── Colours ──────────────────────────────────────────────────────────────
BG="06060fff"          # near black — fallback bg
FG="c8d0e8ff"          # light grey — text
CYAN="00ffd1ff"        # cyan — ring, highlights
CYAN_DIM="00ffd133"    # cyan 20% — ring verify
BLUE="3b82ffff"        # blue — key highlight
PINK="ff5af1ff"        # pink — caps lock
RED="ff1744ff"         # red — wrong password
ORANGE="ff6b1aff"      # orange — verifying
DARK="0a0a1cff"        # dark bg for elements
BORDER="1a1a3aff"      # border colour
CLEAR="00000000"       # transparent

# ── Prepare background image ─────────────────────────────────────────────
# Slightly darken the wallpaper so text is readable
if [[ -f "$WALL" ]]; then
    convert "$WALL" \
        -resize 1920x1080^ \
        -gravity Center \
        -extent 1920x1080 \
        -fill black \
        -colorize 40 \
        "$LOCK_IMG" 2>/dev/null || cp "$WALL" "$LOCK_IMG"
else
    # Fallback — solid dark background
    convert -size 1920x1080 "xc:#06060f" "$LOCK_IMG" 2>/dev/null || \
        LOCK_IMG=""
fi

# ── Play lock sound ───────────────────────────────────────────────────────
sound-system notification &>/dev/null & 2>/dev/null || true

# ── Lock ─────────────────────────────────────────────────────────────────
ARGS=(
    # Background
    --image="$LOCK_IMG"

    # Clock
    --clock
    --time-str="%H:%M"
    --date-str="%A  %d %B"
    --time-font="Fira Code"
    --date-font="Fira Code"
    --time-size=64
    --date-size=18
    --time-color="$CYAN"
    --date-color="$FG"
    --time-pos="ix:iy-60"
    --date-pos="ix:iy-20"

    # Ring
    --ring-color="$BORDER"
    --ring-ver-color="$ORANGE"
    --ring-wrong-color="$RED"
    --ring-clear-color="$CYAN_DIM"
    --line-color="$CLEAR"
    --line-ver-color="$CLEAR"
    --line-wrong-color="$CLEAR"
    --line-clear-color="$CLEAR"

    # Key press highlight
    --keyhl-color="$CYAN"
    --bshl-color="$RED"
    --separator-color="$CLEAR"

    # Inside circle
    --inside-color="$CLEAR"
    --inside-ver-color="${ORANGE%ff}33"
    --inside-wrong-color="${RED%ff}33"
    --inside-clear-color="$CYAN_DIM"

    # Text on ring
    --verif-text="VERIFYING..."
    --wrong-text="ACCESS DENIED"
    --noinput-text="NO INPUT"
    --lock-text="LOCKED"
    --lockfailed-text="LOCK FAILED"
    --verif-color="$ORANGE"
    --wrong-color="$RED"
    --modif-color="$CYAN"
    --verif-font="Fira Code"
    --wrong-font="Fira Code"
    --verif-size=14
    --wrong-size=14

    # Indicator position — centre screen
    --indicator
    --radius=80
    --ring-width=4

    # Greeter text above clock
    --greeter-text="WehttamSnaps"
    --greeter-color="$PINK"
    --greeter-font="Fira Code"
    --greeter-size=22
    --greeter-pos="ix:iy-110"

    # Caps lock warning
    --caps-lock-text="CAPS LOCK"
    --caps-lock-key-hl-color="$PINK"

    # Blur — subtle
    --blur-size=0

    # Misc
    --pass-media-keys
    --pass-screen-keys
    --no-unlock-indicator
)

# Use image if it exists, otherwise fallback to colour
if [[ -f "$LOCK_IMG" ]]; then
    i3lock-color "${ARGS[@]}"
else
    i3lock-color \
        --color="$BG" \
        --clock \
        --time-str="%H:%M" \
        --date-str="%A  %d %B" \
        --time-color="$CYAN" \
        --date-color="$FG" \
        --ring-color="$BORDER" \
        --keyhl-color="$CYAN" \
        --bshl-color="$RED" \
        --inside-color="$CLEAR" \
        --line-color="$CLEAR" \
        --separator-color="$CLEAR" \
        --ring-ver-color="$ORANGE" \
        --ring-wrong-color="$RED" \
        --verif-text="VERIFYING..." \
        --wrong-text="ACCESS DENIED" \
        --greeter-text="WehttamSnaps" \
        --greeter-color="$PINK" \
        --indicator \
        --radius=80 \
        --ring-width=4 \
        --pass-media-keys
fi
