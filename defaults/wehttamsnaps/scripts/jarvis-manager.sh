#!/usr/bin/env bash
# === J.A.R.V.I.S. SOUND MANAGER ===
# WehttamSnaps Hyprland Setup
# GitHub: https://github.com/Crowdrocker
#
# Plays J.A.R.V.I.S. audio notifications for system events
# Sounds generated from 101soundboards.com using:
# - jarvis-v1-paul-bettany-tts-computer-ai-voice
# - idroid-tts-computer-ai-voice
#
# FIX: Removed set -euo pipefail (caused crash when sound files missing)
#      Updated Niri references to Hyprland

# Configuration
SOUNDS_DIR="$HOME/.config/wehttamsnaps/sounds"
STATE_FILE="$HOME/.cache/wehttamsnaps/jarvis-state"
VOLUME=70

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$SOUNDS_DIR"

play_sound() {
    local sound_file="$1"
    local volume="${2:-$VOLUME}"

    if [[ ! -f "$sound_file" ]]; then
        echo -e "${RED}Error: Sound file not found: $sound_file${NC}" >&2
        return 1
    fi

    if command -v mpv &>/dev/null; then
        mpv --no-terminal --volume="$volume" "$sound_file" &>/dev/null &
    elif command -v ffplay &>/dev/null; then
        ffplay -nodisp -autoexit -volume "$volume" "$sound_file" &>/dev/null &
    elif command -v paplay &>/dev/null; then
        paplay --volume="$((volume * 655))" "$sound_file" &>/dev/null &
    elif command -v aplay &>/dev/null; then
        aplay -q "$sound_file" &>/dev/null &
    else
        echo -e "${RED}Error: No audio player found (mpv, ffplay, paplay, or aplay)${NC}" >&2
        return 1
    fi
}

get_greeting() {
    local hour
    hour=$(date +%H)
    if (( hour >= 5 && hour < 12 )); then echo "Good morning"
    elif (( hour >= 12 && hour < 17 )); then echo "Good afternoon"
    else echo "Good evening"
    fi
}

play_startup() {
    local sound="$SOUNDS_DIR/jarvis-startup.mp3"
    if [[ -f "$sound" ]]; then
        echo -e "${BLUE}🤖 J.A.R.V.I.S.: Initializing...${NC}"
        play_sound "$sound" "$VOLUME"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - STARTUP" >> "$STATE_FILE"
    else
        echo -e "${YELLOW}⚠️  J.A.R.V.I.S. startup sound not found: $sound${NC}"
    fi
}

play_shutdown() {
    local sound="$SOUNDS_DIR/jarvis-shutdown.mp3"
    if [[ -f "$sound" ]]; then
        echo -e "${BLUE}🤖 J.A.R.V.I.S.: Shutting down...${NC}"
        play_sound "$sound" "$VOLUME"
        sleep 3
        echo "$(date '+%Y-%m-%d %H:%M:%S') - SHUTDOWN" >> "$STATE_FILE"
    else
        echo -e "${YELLOW}⚠️  J.A.R.V.I.S. shutdown sound not found${NC}"
    fi
}

play_notification() {
    local sound="$SOUNDS_DIR/jarvis-notification.mp3"
    [[ -f "$sound" ]] && play_sound "$sound" "$VOLUME" || true
}

play_warning() {
    local sound="$SOUNDS_DIR/jarvis-warning.mp3"
    if [[ -f "$sound" ]]; then
        echo -e "${RED}⚠️  J.A.R.V.I.S.: Warning!${NC}"
        play_sound "$sound" "$VOLUME"
    fi
}

play_gaming() {
    local sound="$SOUNDS_DIR/jarvis-gaming.mp3"
    if [[ -f "$sound" ]]; then
        echo -e "${GREEN}🎮 J.A.R.V.I.S.: Gaming mode activated${NC}"
        play_sound "$sound" "$VOLUME"
    else
        echo -e "${YELLOW}⚠️  J.A.R.V.I.S. gaming sound not found${NC}"
    fi
}

play_streaming() {
    local sound="$SOUNDS_DIR/jarvis-streaming.mp3"
    if [[ -f "$sound" ]]; then
        echo -e "${BLUE}📺 J.A.R.V.I.S.: Streaming systems online${NC}"
        play_sound "$sound" "$VOLUME"
    else
        echo -e "${YELLOW}⚠️  J.A.R.V.I.S. streaming sound not found${NC}"
    fi
}

check_temperature() {
    local temp_threshold=80
    if command -v sensors &>/dev/null; then
        local cpu_temp
        cpu_temp=$(sensors | grep -i "Package id 0:" | awk '{print $4}' | tr -d '+°C' || echo "")
        if [[ -n "$cpu_temp" ]] && (( ${cpu_temp%.*} > temp_threshold )); then
            echo -e "${RED}🌡️  CPU Temperature: ${cpu_temp}°C (Threshold: ${temp_threshold}°C)${NC}"
            play_warning
            command -v notify-send &>/dev/null && notify-send -u critical "J.A.R.V.I.S. Warning" "CPU temperature critical: ${cpu_temp}°C" || true
        fi
    fi
}

check_gpu_temperature() {
    local temp_threshold=85
    # Try card0 first, then card1 (RX 580 sometimes appears on card1)
    local temp_file=""
    for card in card0 card1; do
        for hwmon in hwmon0 hwmon1 hwmon2; do
            local path="/sys/class/drm/$card/device/hwmon/$hwmon/temp1_input"
            if [[ -f "$path" ]]; then
                temp_file="$path"
                break 2
            fi
        done
    done

    if [[ -n "$temp_file" ]]; then
        local gpu_temp=$(( $(cat "$temp_file") / 1000 ))
        if (( gpu_temp > temp_threshold )); then
            echo -e "${RED}🎮 GPU Temperature: ${gpu_temp}°C (Threshold: ${temp_threshold}°C)${NC}"
            play_warning
            command -v notify-send &>/dev/null && notify-send -u critical "J.A.R.V.I.S. Warning" "GPU temperature critical: ${gpu_temp}°C" || true
        fi
    fi
}

list_sounds() {
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}   J.A.R.V.I.S. Available Sounds${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

    local sounds=(
        "startup:jarvis-startup.mp3:System initialization"
        "shutdown:jarvis-shutdown.mp3:System shutdown"
        "notification:jarvis-notification.mp3:New notification"
        "warning:jarvis-warning.mp3:System warning"
        "gaming:jarvis-gaming.mp3:Gaming mode activated"
        "streaming:jarvis-streaming.mp3:Streaming systems online"
    )

    for sound_info in "${sounds[@]}"; do
        IFS=':' read -r name file description <<< "$sound_info"
        local path="$SOUNDS_DIR/$file"
        if [[ -f "$path" ]]; then
            echo -e "  ${GREEN}✓${NC} ${YELLOW}$name${NC} - $description"
        else
            echo -e "  ${RED}✗${NC} ${YELLOW}$name${NC} - $description ${RED}(missing)${NC}"
        fi
    done

    echo -e "\n${BLUE}═══════════════════════════════════════${NC}\n"
}

test_sounds() {
    echo -e "${BLUE}🔊 Testing J.A.R.V.I.S. sounds...${NC}\n"
    local sounds=("startup:Startup" "notification:Notification" "gaming:Gaming Mode" "streaming:Streaming" "warning:Warning" "shutdown:Shutdown")
    for sound_info in "${sounds[@]}"; do
        IFS=':' read -r name description <<< "$sound_info"
        echo -e "${YELLOW}▶ Playing: $description${NC}"
        case "$name" in
            startup)      play_startup ;;
            shutdown)     play_shutdown ;;
            notification) play_notification ;;
            warning)      play_warning ;;
            gaming)       play_gaming ;;
            streaming)    play_streaming ;;
        esac
        sleep 3
    done
    echo -e "\n${GREEN}✓ Sound test complete${NC}"
}

create_placeholders() {
    echo -e "${BLUE}📝 Creating placeholder sound files...${NC}\n"
    mkdir -p "$SOUNDS_DIR"
    local sounds=("jarvis-startup.mp3" "jarvis-shutdown.mp3" "jarvis-notification.mp3" "jarvis-warning.mp3" "jarvis-gaming.mp3" "jarvis-streaming.mp3")
    for sound in "${sounds[@]}"; do
        local path="$SOUNDS_DIR/$sound"
        if [[ ! -f "$path" ]]; then
            touch "$path"
            echo -e "  ${YELLOW}Created placeholder: $sound${NC}"
        else
            echo -e "  ${GREEN}Already exists: $sound${NC}"
        fi
    done
    echo -e "\n${BLUE}Placeholder files created at: $SOUNDS_DIR${NC}"
    echo -e "${YELLOW}Replace these with your actual J.A.R.V.I.S. sound files${NC}\n"
}

show_help() {
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════════${NC}
${BLUE}          WehttamSnaps J.A.R.V.I.S. Sound Manager${NC}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

${YELLOW}Usage:${NC} $0 [event] [options]

${YELLOW}Events:${NC}
  startup           Play startup sound (system boot)
  shutdown          Play shutdown sound
  notification      Play notification sound
  warning           Play warning sound
  gaming            Play gaming mode activated sound
  streaming         Play streaming systems online sound

${YELLOW}Commands:${NC}
  list              List all available sounds
  test              Test all sounds in sequence
  placeholders      Create placeholder sound files
  temp-check        Check temperatures and warn if high
  help              Show this help message

${YELLOW}Options:${NC}
  --volume, -v NUM  Set volume (0-100, default: 70)

${YELLOW}Examples:${NC}
  $0 startup
  $0 gaming --volume 80
  $0 test
  $0 temp-check

${YELLOW}Sound Files Location:${NC}
  $SOUNDS_DIR

${YELLOW}Expected Files:${NC}
  • jarvis-startup.mp3       - "Allow me to introduce myself..."
  • jarvis-shutdown.mp3      - "Shutting down. Have a good day..."
  • jarvis-notification.mp3  - "Matthew, you have a notification."
  • jarvis-warning.mp3       - "Warning: System temperature critical."
  • jarvis-gaming.mp3        - "Gaming mode activated..."
  • jarvis-streaming.mp3     - "Streaming systems online..."

${YELLOW}Integration:${NC}
  Called automatically by Hyprland UserKeybinds.conf:
  • On boot via Startup_Apps.conf (startup)
  • SUPER+SHIFT+G   gaming mode toggle (gaming)
  • SUPER+1-0       workspace switches (workspace N via sound-system.sh)
  • Volume keys     volume up/down/mute
  • SUPER+F10       screenshot

${BLUE}═══════════════════════════════════════════════════════════════${NC}
EOF
}

main() {
    local event="${1:-help}"
    local volume="$VOLUME"

    shift || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --volume|-v)
                volume="${2:-$VOLUME}"
                shift 2 || shift
                ;;
            *) shift ;;
        esac
    done

    VOLUME="$volume"

    case "$event" in
        startup)              play_startup ;;
        shutdown)             play_shutdown ;;
        notification|notify)  play_notification ;;
        warning|warn)         play_warning ;;
        gaming|game)          play_gaming ;;
        streaming|stream)     play_streaming ;;
        list|ls)              list_sounds ;;
        test)                 test_sounds ;;
        placeholders|create)  create_placeholders ;;
        temp-check|temperature) check_temperature; check_gpu_temperature ;;
        help|--help|-h)       show_help ;;
        *)
            echo -e "${RED}Error: Unknown event '$event'${NC}"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"
