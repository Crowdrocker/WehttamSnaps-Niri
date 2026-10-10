#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                  WEHTTAMSNAPS ADAPTIVE SOUND SYSTEM                          ║
# ║                    J.A.R.V.I.S. & iDroid Voice Manager                       ║
# ║                                                                              ║
# ║  Author: Matthew (WehttamSnaps)                                              ║
# ║  GitHub: https://github.com/Crowdrocker                                      ║
# ║  Purpose: Context-aware audio feedback with dual voice modes                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

SOUND_DIR="/usr/share/wehttamsnaps/sounds"
STATE_FILE="$HOME/.cache/wehttamsnaps/sound-mode"
GAMING_WORKSPACES=(3 6 7)  # Workspaces that trigger iDroid mode
PHOTOGRAPHY_WORKSPACE=5     # Photography workspace triggers J.A.R.V.I.S.

# Ensure cache directory exists
mkdir -p "$(dirname "$STATE_FILE")"

# ═══════════════════════════════════════════════════════════════════════════════
# COLOR OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get current gaming mode state
get_gaming_mode() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "false"
    fi
}

# Set gaming mode state
set_gaming_mode() {
    local mode="$1"
    echo "$mode" > "$STATE_FILE"
    log_success "Gaming mode set to: $mode"
}

# Get current workspace
get_current_workspace() {
    # Try to get workspace from Niri
    if command -v niri &> /dev/null; then
        local workspace=$(niri msg -j workspaces | jq -r '.[] | select(.is_focused == true) | .idx' 2>/dev/null || echo "1")
        echo "$workspace"
    else
        echo "1"
    fi
}

# Determine which voice mode to use
get_voice_mode() {
    local gaming_mode=$(get_gaming_mode)

    # If gaming mode is explicitly enabled, always use iDroid
    if [[ "$gaming_mode" == "true" ]]; then
        echo "idroid"
        return
    fi

    # Check current workspace
    local workspace=$(get_current_workspace)

    # Gaming workspaces trigger iDroid
    for gaming_ws in "${GAMING_WORKSPACES[@]}"; do
        if [[ "$workspace" == "$gaming_ws" ]]; then
            echo "idroid"
            return
        fi
    done

    # Photography workspace uses J.A.R.V.I.S.
    if [[ "$workspace" == "$PHOTOGRAPHY_WORKSPACE" ]]; then
        echo "jarvis"
        return
    fi

    # Default to J.A.R.V.I.S.
    echo "jarvis"
}

# Play sound file
play_sound() {
    local voice_mode="$1"
    local sound_name="$2"
    local sound_file="$SOUND_DIR/$voice_mode/$sound_name.mp3"

    if [[ ! -f "$sound_file" ]]; then
        log_warning "Sound file not found: $sound_file"
        return 1
    fi

    # Play using mpv in background (fast and lightweight)
    if command -v mpv &> /dev/null; then
        mpv --no-terminal --volume=60 "$sound_file" &> /dev/null &
        return 0
    elif command -v paplay &> /dev/null; then
        paplay "$sound_file" &> /dev/null &
        return 0
    elif command -v aplay &> /dev/null; then
        aplay -q "$sound_file" &> /dev/null &
        return 0
    else
        log_error "No audio player found (mpv, paplay, or aplay)"
        return 1
    fi
}

# Play adaptive sound based on context
play_adaptive_sound() {
    local sound_name="$1"
    local voice_mode=$(get_voice_mode)

    log_info "Playing sound: $sound_name (voice: $voice_mode)"
    play_sound "$voice_mode" "$sound_name"
}

# ═══════════════════════════════════════════════════════════════════════════════
# AUDIO CONTROL FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

handle_mute() {
    # Get current mute state using wpctl
    local is_muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c "MUTED" || echo "0")

    # Toggle mute
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

    # Play appropriate sound based on new state
    if [[ "$is_muted" == "0" ]]; then
        # Was unmuted, now muted
        play_adaptive_sound "audio-mute"
    else
        # Was muted, now unmuted
        play_adaptive_sound "audio-unmute"
    fi
}

handle_volume_up() {
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    play_adaptive_sound "volume-up"
}

handle_volume_down() {
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    play_adaptive_sound "volume-down"
}

handle_mic_mute() {
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    local is_muted=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -c "MUTED" || echo "0")

    if [[ "$is_muted" == "0" ]]; then
        play_adaptive_sound "audio-mute"
    else
        play_adaptive_sound "audio-unmute"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# SYSTEM EVENT FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

handle_startup() {
    local hour=$(date +%H)

    # Time-based startup greeting
    if [[ "$hour" -ge 5 && "$hour" -lt 12 ]]; then
        if [[ -f "$SOUND_DIR/jarvis/morning.mp3" ]]; then
            play_sound "jarvis" "morning"
        else
            play_sound "jarvis" "startup"
        fi
    elif [[ "$hour" -ge 12 && "$hour" -lt 18 ]]; then
        if [[ -f "$SOUND_DIR/jarvis/afternoon.mp3" ]]; then
            play_sound "jarvis" "afternoon"
        else
            play_sound "jarvis" "startup"
        fi
    else
        if [[ -f "$SOUND_DIR/jarvis/evening.mp3" ]]; then
            play_sound "jarvis" "evening"
        else
            play_sound "jarvis" "startup"
        fi
    fi

    log_success "Welcome, Matthew. All systems online."
}

handle_shutdown() {
    play_sound "jarvis" "shutdown"
    log_info "Shutting down sound system..."
}

handle_screenshot() {
    play_adaptive_sound "screenshot"
}

handle_workspace_switch() {
    local workspace="${1:-1}"
    play_adaptive_sound "workspace-switch"
}

handle_window_close() {
    # Silent - could add sound if desired
    :
}

handle_notification() {
    play_adaptive_sound "notification"
}

handle_photo_export() {
    play_sound "jarvis" "photo-export"
}

handle_system_update() {
    if [[ -f "$SOUND_DIR/jarvis/jarvis-update.mp3" ]]; then
        play_sound "jarvis" "jarvis-update"
    else
        play_sound "jarvis" "notification"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# GAMING MODE FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

handle_gaming_toggle() {
    local current_mode=$(get_gaming_mode)

    if [[ "$current_mode" == "true" ]]; then
        # Disable gaming mode
        set_gaming_mode "false"
        play_sound "idroid" "gamemode-off"
        notify-send -u normal -t 3000 "Gaming Mode" "Deactivated - J.A.R.V.I.S. mode enabled"
        log_success "Gaming mode deactivated"
    else
        # Enable gaming mode
        set_gaming_mode "true"
        play_sound "idroid" "gamemode-on"
        notify-send -u normal -t 3000 "Gaming Mode" "Activated - iDroid voice enabled"
        log_success "Gaming mode activated"
    fi
}

handle_gamemode_on() {
    set_gaming_mode "true"
    play_sound "idroid" "gamemode-on"
}

handle_gamemode_off() {
    set_gaming_mode "false"
    play_sound "idroid" "gamemode-off"
}

handle_steam_launch() {
    play_sound "idroid" "steam-launch"
}

handle_mission_start() {
    play_sound "idroid" "mission-start"
}

handle_alert_high() {
    play_sound "idroid" "alert-high"
}

handle_alert_medium() {
    play_sound "idroid" "alert-medium"
}

handle_discord_notify() {
    play_sound "idroid" "discord-notify"
}

handle_performance_warn() {
    play_sound "idroid" "performance-warn"
}

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

show_status() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}         ${CYAN}WehttamSnaps Sound System Status${NC}               ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local gaming_mode=$(get_gaming_mode)
    local voice_mode=$(get_voice_mode)
    local workspace=$(get_current_workspace)

    echo -e "${CYAN}Gaming Mode:${NC}      $(if [[ "$gaming_mode" == "true" ]]; then echo -e "${GREEN}Enabled${NC}"; else echo -e "${RED}Disabled${NC}"; fi)"
    echo -e "${CYAN}Active Voice:${NC}     $(if [[ "$voice_mode" == "jarvis" ]]; then echo -e "${BLUE}J.A.R.V.I.S.${NC}"; else echo -e "${YELLOW}iDroid${NC}"; fi)"
    echo -e "${CYAN}Current Workspace:${NC} $workspace"
    echo -e "${CYAN}Sound Directory:${NC}  $SOUND_DIR"
    echo ""

    # Check sound files
    local jarvis_count=$(find "$SOUND_DIR/jarvis" -name "*.mp3" 2>/dev/null | wc -l)
    local idroid_count=$(find "$SOUND_DIR/idroid" -name "*.mp3" 2>/dev/null | wc -l)

    echo -e "${CYAN}J.A.R.V.I.S. Sounds:${NC} $jarvis_count files"
    echo -e "${CYAN}iDroid Sounds:${NC}      $idroid_count files"
}

list_sounds() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}           ${CYAN}Available Sound Files${NC}                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${BLUE}J.A.R.V.I.S. (Professional Mode):${NC}"
    if [[ -d "$SOUND_DIR/jarvis" ]]; then
        find "$SOUND_DIR/jarvis" -name "*.mp3" -exec basename {} .mp3 \; | sort | sed 's/^/  • /'
    else
        echo "  No sounds found"
    fi

    echo ""
    echo -e "${YELLOW}iDroid (Gaming Mode):${NC}"
    if [[ -d "$SOUND_DIR/idroid" ]]; then
        find "$SOUND_DIR/idroid" -name "*.mp3" -exec basename {} .mp3 \; | sort | sed 's/^/  • /'
    else
        echo "  No sounds found"
    fi
}

test_sounds() {
    echo -e "${CYAN}Testing J.A.R.V.I.S. sounds...${NC}"
    for sound in "$SOUND_DIR/jarvis"/*.mp3; do
        if [[ -f "$sound" ]]; then
            local name=$(basename "$sound" .mp3)
            echo -e "  Playing: ${GREEN}$name${NC}"
            play_sound "jarvis" "$name"
            sleep 2
        fi
    done

    echo ""
    echo -e "${CYAN}Testing iDroid sounds...${NC}"
    for sound in "$SOUND_DIR/idroid"/*.mp3; do
        if [[ -f "$sound" ]]; then
            local name=$(basename "$sound" .mp3)
            echo -e "  Playing: ${YELLOW}$name${NC}"
            play_sound "idroid" "$name"
            sleep 2
        fi
    done
}

preview_sound() {
    local sound_name="$1"
    local voice_mode="${2:-auto}"

    if [[ "$voice_mode" == "auto" ]]; then
        voice_mode=$(get_voice_mode)
    fi

    log_info "Previewing: $sound_name (voice: $voice_mode)"
    play_sound "$voice_mode" "$sound_name"
}

show_help() {
    cat << EOF
${PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}
${PURPLE}║${NC}              ${CYAN}WehttamSnaps Sound System - Help${NC}                      ${PURPLE}║${NC}
${PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}

${CYAN}USAGE:${NC}
    sound-system <command> [arguments]

${CYAN}AUDIO CONTROL COMMANDS:${NC}
    mute                Toggle audio mute with feedback
    volume-up           Increase volume with feedback
    volume-down         Decrease volume with feedback
    mic-mute            Toggle microphone mute

${CYAN}SYSTEM EVENT COMMANDS:${NC}
    startup             Play startup greeting
    shutdown            Play shutdown message
    screenshot          Screenshot confirmation
    workspace <num>     Workspace switch sound
    window-close        Window close sound
    notification        Generic notification
    photo-export        Photography export complete

${CYAN}GAMING MODE COMMANDS:${NC}
    gaming-toggle       Toggle gaming mode (J.A.R.V.I.S. ↔ iDroid)
    gamemode-on         Enable gaming mode explicitly
    gamemode-off        Disable gaming mode explicitly
    steam-launch        Steam game launch sound
    mission-start       Game/mission start sound
    alert-high          High priority alert
    alert-medium        Medium priority alert
    discord-notify      Discord notification sound
    performance-warn    Performance warning

${CYAN}UTILITY COMMANDS:${NC}
    status              Show current system status
    list                List all available sounds
    test                Test all sounds sequentially
    preview <sound> [voice]  Preview specific sound
    help                Show this help message

${CYAN}VOICE MODES:${NC}
    • ${BLUE}J.A.R.V.I.S.${NC} - Professional mode (default, photography, work)
    • ${YELLOW}iDroid${NC}      - Gaming/tactical mode (workspaces 3, 6, 7)

${CYAN}EXAMPLES:${NC}
    sound-system status
    sound-system gaming-toggle
    sound-system preview startup jarvis
    sound-system screenshot

${CYAN}INTEGRATION:${NC}
    Add to Niri keybinds for seamless audio feedback
    Automatically switches voice based on workspace context

${GREEN}GitHub:${NC} https://github.com/Crowdrocker
${GREEN}Brand:${NC}  WehttamSnaps

EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN COMMAND HANDLER
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        # Audio controls
        mute)               handle_mute ;;
        volume-up)          handle_volume_up ;;
        volume-down)        handle_volume_down ;;
        mic-mute)           handle_mic_mute ;;

        # System events
        startup)            handle_startup ;;
        shutdown)           handle_shutdown ;;
        screenshot)         handle_screenshot ;;
        workspace)          handle_workspace_switch "$@" ;;
        window-close)       handle_window_close ;;
        notification)       handle_notification ;;
        photo-export)       handle_photo_export ;;
        system-update)      handle_system_update ;;

        # Gaming mode
        gaming-toggle)      handle_gaming_toggle ;;
        gamemode-on)        handle_gamemode_on ;;
        gamemode-off)       handle_gamemode_off ;;
        steam-launch)       handle_steam_launch ;;
        mission-start)      handle_mission_start ;;
        alert-high)         handle_alert_high ;;
        alert-medium)       handle_alert_medium ;;
        discord-notify)     handle_discord_notify ;;
        performance-warn)   handle_performance_warn ;;

        # Utilities
        status)             show_status ;;
        list)               list_sounds ;;
        test)               test_sounds ;;
        preview)            preview_sound "$@" ;;
        help|--help|-h)     show_help ;;

        *)
            log_error "Unknown command: $command"
            echo "Run 'sound-system help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
