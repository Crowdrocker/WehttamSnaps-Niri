#!/bin/bash
# Voice Activation System for J.A.R.V.I.S.
# Uses vosk-api for offline speech recognition

set -euo pipefail

CACHE_DIR="$HOME/.cache/wehttamsnaps"
VOSK_MODEL_DIR="$CACHE_DIR/vosk-model"
JARVIS_SCRIPT="$HOME/.config/wehttamsnaps/scripts/jarvis-voice-assistant.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Install dependencies if needed
check_dependencies() {
    echo -e "${CYAN}Checking dependencies...${NC}"

    local missing=()

    command -v python3 &>/dev/null || missing+=("python3")
    command -v pip &>/dev/null || missing+=("python-pip")
    command -v parecord &>/dev/null || missing+=("pulseaudio-utils")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}Missing packages: ${missing[*]}${NC}"
        echo "Install with: paru -S ${missing[*]}"
        exit 1
    fi

    # Check for Python vosk module
    if ! python3 -c "import vosk" 2>/dev/null; then
        echo -e "${YELLOW}Installing vosk-api...${NC}"
        pip install --user vosk sounddevice
    fi
}

# Download Vosk model if needed
setup_vosk_model() {
    if [ ! -d "$VOSK_MODEL_DIR" ]; then
        echo -e "${CYAN}Downloading Vosk speech model...${NC}"
        mkdir -p "$CACHE_DIR"

        # Small English model (~40MB)
        MODEL_URL="https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"
        MODEL_ZIP="$CACHE_DIR/vosk-model.zip"

        curl -L "$MODEL_URL" -o "$MODEL_ZIP"
        unzip -q "$MODEL_ZIP" -d "$CACHE_DIR"
        mv "$CACHE_DIR/vosk-model-small-en-us-0.15" "$VOSK_MODEL_DIR"
        rm "$MODEL_ZIP"

        echo -e "${GREEN}✓ Model installed${NC}"
    fi
}

# Voice activation listener
start_listener() {
    echo -e "${CYAN}Starting voice activation listener...${NC}"
    echo -e "${YELLOW}Listening for 'Hey Jarvis' or 'Jarvis'...${NC}"

    python3 - <<'PYTHON'
import vosk
import sounddevice as sd
import json
import subprocess
import os
import sys

# Configuration
SAMPLE_RATE = 16000
BLOCK_SIZE = 8000
MODEL_PATH = os.path.expanduser("~/.cache/wehttamsnaps/vosk-model")
JARVIS_SCRIPT = os.path.expanduser("~/.config/wehttamsnaps/scripts/jarvis-voice-assistant.sh")

# Wake words
WAKE_WORDS = ["hey jarvis", "jarvis", "ok jarvis"]

print(f"\033[32m✓ Voice activation ready\033[0m")
print(f"\033[33mSay: 'Hey Jarvis' followed by your command\033[0m")

# Initialize Vosk
model = vosk.Model(MODEL_PATH)
recognizer = vosk.KaldiRecognizer(model, SAMPLE_RATE)
recognizer.SetWords(True)

is_listening_for_command = False
command_buffer = []

def process_audio(indata, frames, time, status):
    global is_listening_for_command, command_buffer

    if status:
        print(f"Status: {status}", file=sys.stderr)

    # Feed audio to recognizer
    if recognizer.AcceptWaveform(bytes(indata)):
        result = json.loads(recognizer.Result())
        text = result.get("text", "").lower().strip()

        if not text:
            return

        print(f"\033[36m🎤 Heard: {text}\033[0m")

        # Check for wake word
        if any(wake in text for wake in WAKE_WORDS):
            print(f"\033[32m✓ Wake word detected!\033[0m")
            is_listening_for_command = True
            command_buffer = []

            # Remove wake word from text
            for wake in WAKE_WORDS:
                text = text.replace(wake, "").strip()

            if text:  # If command follows immediately
                command_buffer.append(text)
                execute_command()
                is_listening_for_command = False

        elif is_listening_for_command:
            # Collecting command after wake word
            command_buffer.append(text)

            # Execute after 2 seconds of speech or on certain keywords
            if any(word in text for word in ["please", "now", "go"]) or len(command_buffer) >= 3:
                execute_command()
                is_listening_for_command = False

def execute_command():
    global command_buffer

    if not command_buffer:
        return

    command = " ".join(command_buffer).strip()
    print(f"\033[34m→ Executing: {command}\033[0m")

    try:
        subprocess.Popen(
            [JARVIS_SCRIPT, command],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception as e:
        print(f"\033[31m✗ Error executing command: {e}\033[0m")

    command_buffer = []

# Start audio stream
try:
    with sd.RawInputStream(
        samplerate=SAMPLE_RATE,
        blocksize=BLOCK_SIZE,
        dtype='int16',
        channels=1,
        callback=process_audio
    ):
        print("\033[32m🎤 Listening...\033[0m")
        while True:
            sd.sleep(100)
except KeyboardInterrupt:
    print("\n\033[33mVoice activation stopped\033[0m")
except Exception as e:
    print(f"\033[31m✗ Error: {e}\033[0m")
    sys.exit(1)
PYTHON
}

# Create systemd service
create_service() {
    local service_file="$HOME/.config/systemd/user/jarvis-voice.service"

    mkdir -p "$(dirname "$service_file")"

    cat > "$service_file" <<EOF
[Unit]
Description=J.A.R.V.I.S. Voice Activation
After=pipewire.service

[Service]
Type=simple
ExecStart=$HOME/.config/wehttamsnaps/scripts/voice-activation.sh start-listener
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

    echo -e "${GREEN}✓ Systemd service created${NC}"
    echo "Enable with: systemctl --user enable --now jarvis-voice.service"
}

# Test microphone
test_microphone() {
    echo -e "${CYAN}Testing microphone...${NC}"
    echo "Recording 3 seconds... Speak now!"

    arecord -d 3 -f cd -t wav /tmp/test.wav 2>/dev/null

    echo -e "${GREEN}✓ Microphone works${NC}"
    echo "Playing back..."
    aplay /tmp/test.wav 2>/dev/null
    rm /tmp/test.wav
}

# Show help
show_help() {
    cat <<EOF
${CYAN}J.A.R.V.I.S. Voice Activation Setup${NC}

${YELLOW}Commands:${NC}
  setup             Install and configure voice activation
  start-listener    Start voice recognition (foreground)
  create-service    Create systemd service
  test-mic          Test your microphone
  help              Show this help

${YELLOW}Usage Examples:${NC}
  # One-time setup
  ./voice-activation.sh setup

  # Test manually
  ./voice-activation.sh start-listener

  # Run as service
  ./voice-activation.sh create-service
  systemctl --user enable --now jarvis-voice.service

${YELLOW}Voice Commands:${NC}
  Say: "Hey Jarvis, open firefox"
  Say: "Jarvis, close window"
  Say: "Ok Jarvis, screenshot"

${YELLOW}Troubleshooting:${NC}
  - Test mic: ./voice-activation.sh test-mic
  - Check logs: journalctl --user -u jarvis-voice.service -f
  - Adjust mic volume: pavucontrol

EOF
}

# Main
case "${1:-help}" in
    setup)
        check_dependencies
        setup_vosk_model
        create_service
        echo -e "\n${GREEN}✓ Setup complete!${NC}"
        echo "Start with: systemctl --user start jarvis-voice.service"
        ;;
    start-listener)
        check_dependencies
        setup_vosk_model
        start_listener
        ;;
    create-service)
        create_service
        ;;
    test-mic)
        test_microphone
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
