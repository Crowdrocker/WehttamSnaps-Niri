#!/bin/bash
# ===================================================================================
# WEHTTAMSNAPS - J.A.R.V.I.S. SOUND MANAGER
# Controls J.A.R.V.I.S. sound events and audio feedback
# https://github.com/Crowdrocker
# ===================================================================================

# Configuration
SOUND_DIR="/usr/share/sounds/wehttamsnaps"
CONFIG_DIR="$HOME/.config/wehttamsnaps"
SOUND_CONFIG="$CONFIG_DIR/sounds/jarvis-config.json"
LOG_FILE="$CONFIG_DIR/logs/jarvis-sounds.log"

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR"/{logs,sounds}
mkdir -p "$SOUND_DIR"

# Ensure we have paplay for audio playback
if ! command -v paplay &> /dev/null; then
    echo "Error: paplay not found. Please install libpulse (pacman -S libpulse)" | tee -a "$LOG_FILE"
    exit 1
fi

# Logging function
log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to play sound with fade in/out
play_jarvis_sound() {
    local sound_name="$1"
    local volume="${2:-0.7}"
    local sound_file=""
    
    # Get sound file path from config
    if [[ -f "$SOUND_CONFIG" ]]; then
        sound_file=$(jq -r ".sounds.${sound_name}.file" "$SOUND_CONFIG" 2>/dev/null)
        volume=$(jq -r ".sounds.${sound_name}.volume // $volume" "$SOUND_CONFIG" 2>/dev/null)
    else
        # Fallback sound files
        case "$sound_name" in
            "startup") sound_file="jarvis-startup.mp3" ;;
            "shutdown") sound_file="jarvis-shutdown.mp3" ;;
            "notification") sound_file="jarvis-notification.mp3" ;;
            "warning") sound_file="jarvis-warning.mp3" ;;
            "gaming") sound_file="jarvis-gaming.mp3" ;;
            "streaming") sound_file="jarvis-streaming.mp3" ;;
            *) 
                log_event "Unknown sound: $sound_name"
                return 1
                ;;
        esac
    fi
    
    local full_path="$SOUND_DIR/$sound_file"
    
    if [[ -f "$full_path" ]]; then
        log_event "Playing J.A.R.V.I.S. sound: $sound_name ($sound_file)"
        # Play with paplay, adjusted volume
        paplay --volume=$(echo "$volume * 65536" | bc -l | cut -d. -f1) "$full_path" &
    else
        log_event "Sound file not found: $full_path"
        return 1
    fi
}

# Function to create notification sound
create_notification_sound() {
    local title="$1"
    local body="$2"
    local urgency="${3:-normal}"
    
    # Play sound based on urgency
    case "$urgency" in
        "critical") play_jarvis_sound "warning" ;;
        "high") play_jarvis_sound "notification" 0.8 ;;
        *) play_jarvis_sound "notification" ;;
    esac
}

# Function to set up system sound event listeners
setup_sound_hooks() {
    # Create systemd user service for sound events
    cat > "$CONFIG_DIR/systemd/user/jarvis-sound-events.service" << EOF
[Unit]
Description=J.A.R.V.I.S. Sound Event Listener
After=pipewire.service

[Service]
Type=simple
ExecStart=/bin/bash -c 'inotifywait -m -e modify $HOME/.config/wehttamsnaps/sounds/events.txt | while read line; do $CONFIG_DIR/scripts/jarvis-sound-manager.sh handle-event; done'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
    
    # Enable the service
    systemctl --user daemon-reload
    systemctl --user enable jarvis-sound-events.service
    systemctl --user start jarvis-sound-events.service
}

# Function to handle sound events
handle_event() {
    local events_file="$CONFIG_DIR/sounds/events.txt"
    
    if [[ -f "$events_file" ]]; then
        while IFS= read -r event; do
            case "$event" in
                "startup") play_jarvis_sound "startup" ;;
                "shutdown") play_jarvis_sound "shutdown" ;;
                "notification") play_jarvis_sound "notification" ;;
                "gaming_mode") play_jarvis_sound "gaming" ;;
                "streaming_mode") play_jarvis_sound "streaming" ;;
                "temperature_warning") play_jarvis_sound "warning" ;;
                *) log_event "Unhandled event: $event" ;;
            esac
        done < "$events_file"
        
        # Clear events after processing
        > "$events_file"
    fi
}

# Function to test all sounds
test_sounds() {
    echo "Testing J.A.R.V.I.S. sound pack..."
    
    for sound in startup shutdown notification gaming streaming warning; do
        echo "Playing: $sound"
        play_jarvis_sound "$sound"
        sleep 2
    done
    
    echo "Sound test completed."
}

# Function to install sound files
install_sounds() {
    local source_dir="$1"
    
    if [[ -z "$source_dir" ]]; then
        echo "Usage: $0 install-sounds <source_directory>"
        return 1
    fi
    
    if [[ ! -d "$source_dir" ]]; then
        echo "Source directory not found: $source_dir"
        return 1
    fi
    
    echo "Installing J.A.R.V.I.S. sounds to $SOUND_DIR..."
    cp -v "$source_dir"/*.mp3 "$SOUND_DIR"/ 2>/dev/null || echo "No .mp3 files found in source directory"
    
    # Set proper permissions
    chmod 644 "$SOUND_DIR"/*.mp3 2>/dev/null
    
    log_event "J.A.R.V.I.S. sounds installed from $source_dir"
    echo "Installation completed."
}

# Function to create welcome message
create_welcome_message() {
    local username="$USER"
    local hour=$(date +%H)
    local greeting=""
    
    if (( hour >= 5 && hour < 12 )); then
        greeting="Good morning"
    elif (( hour >= 12 && hour < 17 )); then
        greeting="Good afternoon"
    elif (( hour >= 17 && hour < 22 )); then
        greeting="Good evening"
    else
        greeting="Good night"
    fi
    
    # Create dynamic startup message
    echo "Creating dynamic startup message..."
    
    # This could be used to generate TTS messages
    echo "$greeting, $username. I am J.A.R.V.I.S. All systems operational. Ready for work and gaming." > "$CONFIG_DIR/sounds/welcome-message.txt"
}

# Main script logic
case "$1" in
    "play")
        play_jarvis_sound "$2" "${3:-0.7}"
        ;;
    "notify")
        create_notification_sound "$2" "$3" "$4"
        ;;
    "setup")
        setup_sound_hooks
        ;;
    "handle-event")
        handle_event
        ;;
    "test")
        test_sounds
        ;;
    "install-sounds")
        install_sounds "$2"
        ;;
    "welcome")
        create_welcome_message
        ;;
    *)
        echo "J.A.R.V.I.S. Sound Manager v1.0"
        echo "Usage: $0 {play|notify|setup|handle-event|test|install-sounds|welcome}"
        echo ""
        echo "Commands:"
        echo "  play <sound> [volume]     - Play specific J.A.R.V.I.S. sound"
        echo "  notify <title> <body>     - Create notification with sound"
        echo "  setup                      - Set up sound event listeners"
        echo "  handle-event              - Process queued sound events"
        echo "  test                       - Test all sounds"
        echo "  install-sounds <dir>      - Install sound files from directory"
        echo "  welcome                    - Create welcome message"
        exit 1
        ;;
esac