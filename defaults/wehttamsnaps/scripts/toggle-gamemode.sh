#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#   WehttamSnaps — Gaming Mode Toggle
#   Super + Shift + G to toggle
#   github.com/Crowdrocker  |  twitch.tv/WehttamSnaps
# ═══════════════════════════════════════════════════════════════════════

STATE_FILE="$HOME/.cache/wehttamsnaps/gaming-mode.active"
SOUND_MODE="$HOME/.cache/wehttamsnaps/sound-mode.state"
LOG="$HOME/.cache/wehttamsnaps/gamemode.log"

mkdir -p "$HOME/.cache/wehttamsnaps"

# ── Logging ──────────────────────────────────────────────────────────────
log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

# ── Sound helper ─────────────────────────────────────────────────────────
play_sound() {
    local event="$1"
    # Try sound-system script first
    for bin in /usr/local/bin/sound-system \
               "$HOME/.config/wehttamsnaps/scripts/sound-system"; do
        if [[ -x "$bin" ]]; then
            "$bin" "$event" &>/dev/null &
            return
        fi
    done
    # Fallback: play any matching wav/ogg directly
    local sound_dir="/usr/share/wehttamsnaps/sounds/idroid"
    local file
    file=$(find "$sound_dir" -iname "*${event}*" \( -name "*.wav" -o -name "*.ogg" -o -name "*.mp3" \) 2>/dev/null | head -1)
    if [[ -n "$file" ]]; then
        paplay "$file" &>/dev/null & 2>/dev/null || \
        ffplay -nodisp -autoexit "$file" &>/dev/null &
    fi
}

# ── Notification helper ───────────────────────────────────────────────────
notify() {
    local title="$1" body="$2" urgency="${3:-normal}"
    if command -v dunstify &>/dev/null; then
        dunstify -u "$urgency" -i "applications-games" \
            -h string:x-dunst-stack-tag:gamemode \
            "$title" "$body"
    elif command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" "$title" "$body"
    fi
}

# ── CPU governor ──────────────────────────────────────────────────────────
set_governor() {
    local gov="$1"
    if command -v cpupower &>/dev/null; then
        sudo cpupower frequency-set -g "$gov" &>/dev/null && \
            log "CPU governor → $gov" || \
            log "WARN: cpupower failed for governor $gov"
    else
        # Direct write fallback (needs write permission or polkit rule)
        for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo "$gov" | sudo tee "$f" &>/dev/null || true
        done
        log "CPU governor → $gov (direct write)"
    fi
}

# ── Non-essential apps to kill on gaming mode ON ──────────────────────────
# Add or remove to taste
KILL_ON_GAME=(
    "dunst"          # notifications (we re-launch after announcing)
    "xfce4-panel"    # already disabled but belt-and-braces
    "nm-applet"      # network tray — not needed mid-game
    "blueman-applet" # bluetooth tray
    "xfce4-power-manager" # power manager UI
)

# Apps to restore when gaming mode turns OFF
RESTORE_ON_EXIT=(
    "dunst"
    "nm-applet"
)

# ═══════════════════════════════════════════════════════════════════════
#   GAMING MODE ON
# ═══════════════════════════════════════════════════════════════════════
gaming_mode_on() {
    log "=== GAMING MODE ON ==="
    touch "$STATE_FILE"

    # 1. Announce FIRST (before killing dunst)
    notify "🎮  iDroid Activated" \
        "Gaming mode ON\nCompositor killed • CPU performance • Background apps cleared" \
        "normal"
    play_sound "gaming-on"
    sleep 0.4  # Let sound start before we kill things

    # 2. Kill compositor
    if pkill -x picom 2>/dev/null; then
        log "picom killed"
    else
        log "picom was not running"
    fi

    # 3. Kill non-essential apps
    for app in "${KILL_ON_GAME[@]}"; do
        if pkill -x "$app" 2>/dev/null; then
            log "killed: $app"
        fi
    done

    # 4. Set CPU to performance
    set_governor "performance"

    # 5. Switch sound profile to iDroid
    echo "idroid" > "$SOUND_MODE"
    log "sound profile → iDroid"

    # 6. Tell gamemode daemon we're active (if gamemoded running)
    if command -v gamemoded &>/dev/null || systemctl --user is-active gamemoded &>/dev/null; then
        # gamecli is the signal tool — if it exists use it, otherwise no-op
        if command -v gamemoded &>/dev/null; then
            log "gamemoded active"
        fi
    fi

    # 7. Re-launch dunst so game notifications still work (muted style)
    sleep 0.3
    dunst &>/dev/null &
    disown

    # 8. Update i3bar to show gaming mode (optional — writes a temp indicator)
    echo "GAMING" > "$HOME/.cache/wehttamsnaps/bar-mode.state"

    log "Gaming mode ON complete"

    # Final rofi confirmation (non-blocking overlay)
    # Uncomment if you want a visual HUD confirmation:
    # rofi -e "🎮  iDroid Activated — Gaming Mode ON" \
    #      -theme ~/.config/rofi/themes/wehttamsnaps.rasi &
}

# ═══════════════════════════════════════════════════════════════════════
#   GAMING MODE OFF
# ═══════════════════════════════════════════════════════════════════════
gaming_mode_off() {
    log "=== GAMING MODE OFF ==="
    rm -f "$STATE_FILE"

    # 1. Restore CPU governor to schedutil (better for desktop use than ondemand)
    set_governor "schedutil"

    # 2. Restart compositor
    picom --config "$HOME/.config/picom.conf" -b &>/dev/null &
    disown
    log "picom restarted"

    # 3. Restore background apps
    for app in "${RESTORE_ON_EXIT[@]}"; do
        if ! pgrep -x "$app" &>/dev/null; then
            "$app" &>/dev/null &
            disown
            log "restored: $app"
        fi
    done

    # 4. Switch sound profile back to JARVIS
    echo "jarvis" > "$SOUND_MODE"
    log "sound profile → JARVIS"

    # 5. Clear bar mode indicator
    rm -f "$HOME/.cache/wehttamsnaps/bar-mode.state"

    # 6. Announce
    sleep 0.3
    notify "🤖  J.A.R.V.I.S. Online" \
        "Gaming mode OFF\nCompositor restored • CPU schedutil • Desktop apps back" \
        "normal"
    play_sound "gaming-off"

    log "Gaming mode OFF complete"
}

# ═══════════════════════════════════════════════════════════════════════
#   TOGGLE
# ═══════════════════════════════════════════════════════════════════════
if [[ -f "$STATE_FILE" ]]; then
    gaming_mode_off
else
    gaming_mode_on
fi
