#!/usr/bin/env bash
# === J.A.R.V.I.S. SOUND MANAGER ===
# WehttamSnaps Niri Setup
# GitHub: https://github.com/Crowdrocker
#
# Plays J.A.R.V.I.S. audio notifications for system events
# Sounds generated from 101soundboards.com using:
# - jarvis-v1-paul-bettany-tts-computer-ai-voice
# - idroid-tts-computer-ai-voice

set -euo pipefail

# Configuration
SOUNDS_DIR="$HOME/.config/wehttamsnaps/sounds"
STATE_FILE="$HOME/.cache/wehttamsnaps/jarvis-state"
VOLUME=70  # Default volume (0-100)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create cache directory
mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$SOUNDS_DIR"

# Function to play sound with mpv (preferred) or fallback to other players
play_sound() {
    local sound_file="$1"
    local volume="${2:-$VOLUME}"
    
    # Check if sound file exists
    if [[ ! -f "$sound_file" ]]; then
        echo -e "${RED}Error: Sound file not found: $sound_file${NC}" >&2
        return 1
    fi
    
    # Try different audio players in order of preference
    if command -v mpv &> /dev/null; then
        mpv --no-terminal --volume="$volume" "$sound_file" &> /dev/null &
    elif command -v ffplay &> /dev/null; then
        ffplay -nodisp -autoexit -volume "$volume" "$sound_file" &> /dev/null &
    elif command -v paplay &> /dev/null; then
        paplay --volume="$((volume * 655))" "$sound_file" &> /dev/null &
    elif command -v aplay &> /dev/null; then
        aplay -q "$sound_file" &> /dev/null &
    else
        echo -e "${RED}Error: No audio player found (mpv, ffplay, paplay, or aplay)${NC}" >&2
        return 1
    fi
}

# Function to get time-appropriate greeting
get_greeting() {
    local hour=$(date +%H)
    
    if (( hour >= 5 && hour < 12 )); then
        echo "Good morning"
    elif (( hour >= 12 && hour < 17 )); then
        echo "Good afternoon"
    elif (( hour >= 17 && hour < 21 )); then
        echo "Good evening"
    else
        echo "Good evening"
    fi
}

# Function to play startup sound
play_startup() {
    local sound="$SOUNDS_DIR/jarvis-startup.mp3"
    
    if [[ -f "$sound" ]]; then
        echo -e "${BLUE}🤖 J.A.R.V.I.S.: Initializing...${NC}"
        play_sound "$sound" "$VOLUME"
        
        # Log startup
        echo "$(date '+%Y-%m-%d %H:%M:%S') - STARTUP" >> "$STATE_FILE"
    else
        echo -e "${YELLOW}⚠️  J.A.R.V.I.S. startup sound not found${NC}"
        echo -e "${YELLOW}Expected: $sound${NC}"
    fi
}

# Function to play shutdown sound
play_shutdown() {
    local sound="$SOUNDS_DIR/jarvis-shutdown.mp3"
    
    if [[ -f "$sound" ]]; then
        echo -e "${BLUE}🤖 J.A.R.V.I.S.: Shutting down...${NC}"
        play_sound "$sound" "$VOLUME"
        
        # Wait for sound to finish
        sleep 3
        
        # Log shutdown
        echo "$(date '+%Y-%m-%d %H:%M:%S') - SHUTDOWN" >> "$STATE_FILE"
    else
        echo -e "${YELLOW}⚠️  J.A.R.V.I.S. shutdown sound not found${NC}"
    fi
}

# Function to play notification sound
play_notification() {
    local sound="$SOUNDS_DIR/jarvis-notification.mp3"
    
    if [[ -f "$sound" ]]; then
        play_sound "$sound" "$VOLUME"
    fi
}

# Function to play warning sound
play_warning() {
    local sound="$SOUNDS_DIR/jarvis-warning.mp3"
    
    if [[ -f "$sound" ]]; then
        echo -e "${RED}⚠️  J.A.R.V.I.S.: Warning!${NC}"
        play_sound "$sound" "$VOLUME"
    fi
}

# Function to play gaming mode sound
play_gaming() {
    local sound="$SOUNDS_DIR/jarvis-gaming.mp3"
    
    if [[ -f "$sound" ]]; then
        echo -e "${GREEN}🎮 J.A.R.V.I.S.: Gaming mode activated${NC}"
        play_sound "$sound" "$VOLUME"
    else
        echo -e "${YELLOW}⚠️  J.A.R.V.I.S. gaming sound not found${NC}"
    fi
}

# Function to play streaming sound
play_streaming() {
    local sound="$SOUNDS_DIR/jarvis-streaming.mp3"
    
    if [[ -f "$sound" ]]; then
        echo -e "${BLUE}📺 J.A.R.V.I.S.: Streaming systems online${NC}"
        play_sound "$sound" "$VOLUME"
    else
        echo -e "${YELLOW}⚠️  J.A.R.V.I.S. streaming sound not found${NC}"
    fi
}

# Function to check CPU temperature and play warning if needed
check_temperature() {
    local temp_threshold=80  # Celsius
    
    # Try to get CPU temperature
    if command -v sensors &> /dev/null; then
        local cpu_temp=$(sensors | grep -i "Package id 0:" | awk '{print $4}' | tr -d '+°C')
        
        if [[ -n "$cpu_temp" ]] && (( ${cpu_temp%.*} > temp_threshold )); then
            echo -e "${RED}🌡️  CPU Temperature: ${cpu_temp}°C (Threshold: ${temp_threshold}°C)${NC}"
            play_warning
            
            if command -v notify-send &> /dev/null; then
                notify-send -u critical "J.A.R.V.I.S. Warning" "CPU temperature critical: ${cpu_temp}°C"
            fi
        fi
    fi
}

# Function to check GPU temperature
check_gpu_temperature() {
    local temp_threshold=85  # Celsius for AMD GPU
    
    # Check AMD GPU temperature
    if [[ -f /sys/class/drm/card0/device/hwmon/hwmon0/temp1_input ]]; then
        local gpu_temp=$(($(cat /sys/class/drm/card0/device/hwmon/hwmon0/temp1_input) / 1000))
        
        if (( gpu_temp > temp_threshold )); then
            echo -e "${RED}🎮 GPU Temperature: ${gpu_temp}°C (Threshold: ${temp_threshold}°C)${NC}"
            play_warning
            
            if command -v notify-send &> /dev/null; then
                notify-send -u critical "J.A.R.V.I.S. Warning" "GPU temperature critical: ${gpu_temp}°C"
            fi
        fi
    fi
}

# Function to show available sounds
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

# Function to test all sounds
test_sounds() {
    echo -e "${BLUE}🔊 Testing J.A.R.V.I.S. sounds...${NC}\n"
    
    local sounds=(
        "startup:Startup"
        "notification:Notification"
        "gaming:Gaming Mode"
        "streaming:Streaming"
        "warning:Warning"
        "shutdown:Shutdown"
    )
    
    for sound_info in "${sounds[@]}"; do
        IFS=':' read -r name description <<< "$sound_info"
        
        echo -e "${YELLOW}▶ Playing: $description${NC}"
        
        case "$name" in
            startup) play_startup ;;
            shutdown) play_shutdown ;;
            notification) play_notification ;;
            warning) play_warning ;;
            gaming) play_gaming ;;
            streaming) play_streaming ;;
        esac
        
        sleep 3
    done
    
    echo -e "\n${GREEN}✓ Sound test complete${NC}"
}

# Function to create placeholder sounds file
create_placeholders() {
    echo -e "${BLUE}📝 Creating placeholder sound files...${NC}\n"
    
    mkdir -p "$SOUNDS_DIR"
    
    local sounds=(
        "jarvis-startup.mp3"
        "jarvis-shutdown.mp3"
        "jarvis-notification.mp3"
        "jarvis-warning.mp3"
        "jarvis-gaming.mp3"
        "jarvis-streaming.mp3"
    )
    
    for sound in "${sounds[@]}"; do
        local path="$SOUNDS_DIR/$sound"
        
        if [[ ! -f "$path" ]]; then
            # Create empty file as placeholder
            touch "$path"
            echo -e "  ${YELLOW}Created placeholder: $sound${NC}"
        else
            echo -e "  ${GREEN}Already exists: $sound${NC}"
        fi
    done
    
    echo -e "\n${BLUE}Placeholder files created at: $SOUNDS_DIR${NC}"
    echo -e "${YELLOW}Replace these with your actual J.A.R.V.I.S. sound files${NC}\n"
}

# Function to show help
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
  warning           Play warning sound (temperature, etc.)
  gaming            Play gaming mode activated sound
  streaming         Play streaming systems online sound

${YELLOW}Commands:${NC}
  list              List all available sounds
  test              Test all sounds in sequence
  placeholders      Create placeholder sound files
  temp-check        Check and warn if temperature is high
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
  This script is called automatically by:
  • Niri startup (jarvis-startup.mp3)
  • Gaming mode toggle (jarvis-gaming.mp3)
  • Workspace 8 entry (jarvis-streaming.mp3)
  • System warnings (jarvis-warning.mp3)

${BLUE}═══════════════════════════════════════════════════════════════${NC}
EOF
}

# Main logic
main() {
    local event="${1:-help}"
    local volume="$VOLUME"
    
    # Parse options
    shift || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --volume|-v)
                volume="${2:-$VOLUME}"
                shift 2 || shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Set volume
    VOLUME="$volume"
    
    # Handle events
    case "$event" in
        startup)
            play_startup
            ;;
        shutdown)
            play_shutdown
            ;;
        notification|notify)
            play_notification
            ;;
        warning|warn)
            play_warning
            ;;
        gaming|game)
            play_gaming
            ;;
        streaming|stream)
            play_streaming
            ;;
        list|ls)
            list_sounds
            ;;
        test)
            test_sounds
            ;;
        placeholders|create)
            create_placeholders
            ;;
        temp-check|temperature)
            check_temperature
            check_gpu_temperature
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Unknown event '$event'${NC}"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
