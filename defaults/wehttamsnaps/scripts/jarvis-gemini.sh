#!/bin/bash
# J.A.R.V.I.S. + Gemini CLI Integration
# Author: Matthew (WehttamSnaps)
#
# FIX: Removed set -euo pipefail — caused crashes when paplay couldn't
# find sound files (non-zero exit aborted the whole script).
# Sound path now uses wehttamsnaps sounds dir, not /usr/share hardcoded path.

SOUND_SYSTEM="$HOME/.config/wehttamsnaps/scripts/sound-system.sh"
VOICE_BASE="$HOME/.config/wehttamsnaps/sounds/jarvis"

# Sound helpers — silent failures (sound missing shouldn't kill the AI response)
jarvis_think() {
    if [ -x "$SOUND_SYSTEM" ]; then
        "$SOUND_SYSTEM" notification &>/dev/null &
    elif [ -f "$VOICE_BASE/listening.mp3" ]; then
        paplay "$VOICE_BASE/listening.mp3" &>/dev/null &
    fi
}

jarvis_response() {
    if [ -x "$SOUND_SYSTEM" ]; then
        "$SOUND_SYSTEM" notification &>/dev/null &
    elif [ -f "$VOICE_BASE/jarvis-confirm.mp3" ]; then
        paplay "$VOICE_BASE/jarvis-confirm.mp3" &>/dev/null &
    fi
}

jarvis_error_sound() {
    if [ -f "$VOICE_BASE/error.mp3" ]; then
        paplay "$VOICE_BASE/error.mp3" &>/dev/null &
    fi
}

jarvis_search_sound() {
    if [ -f "$VOICE_BASE/searching-google.mp3" ]; then
        paplay "$VOICE_BASE/searching-google.mp3" &>/dev/null &
    fi
}

# Main AI function
jarvis_ask() {
    local prompt="${1:-Hello J.A.R.V.I.S., what can you help me with?}"
    local output_format="${2:-text}"

    jarvis_think

    local response
    if [ "$output_format" = "json" ]; then
        response=$(gemini -p "$prompt" --output-format json 2>/dev/null) || true
    else
        response=$(gemini -p "$prompt" 2>/dev/null) || true
    fi

    if [ -n "$response" ]; then
        jarvis_response
        echo "$response"
    else
        jarvis_error_sound
        echo "Error: No response from Gemini. Is 'gemini' CLI installed and authenticated?" >&2
        return 1
    fi
}

# Streaming responses for long operations
jarvis_stream() {
    local prompt="${1:-Analyze this system}"

    jarvis_think
    gemini -p "$prompt" --output-format stream-json 2>/dev/null | while IFS= read -r line; do
        echo "$line"
    done || true
    jarvis_response
}

# System diagnostic shortcut
jarvis_diag() {
    jarvis_search_sound
    local diag
    diag=$(bash -c '
        echo "=== SYSTEM ==="
        uname -a
        echo "CPU: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
        echo "GPU: $(lspci | grep -i vga | cut -d: -f3 | xargs)"
        echo ""
        echo "=== MEMORY ==="
        free -h
        echo ""
        echo "=== DISK ==="
        df -h / /home 2>/dev/null
        echo ""
        echo "=== TOP CPU ==="
        ps aux --sort=-%cpu | head -5
        echo ""
        echo "=== RECENT ERRORS ==="
        journalctl -p err -n 10 --no-pager 2>/dev/null || echo "none"
    ')
    echo "$diag" | gemini -p "Analyze this Arch Linux system diagnostic (i5-4430, AMD RX 580, 16GB RAM, Hyprland). Identify issues and suggest improvements:" 2>/dev/null || true
}

# If script is run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-help}" in
        ask)
            shift
            jarvis_ask "${*:-Hello J.A.R.V.I.S., how can you help me?}"
            ;;
        stream)
            shift
            jarvis_stream "${*:-Analyze this system}"
            ;;
        diag)
            jarvis_diag
            ;;
        help|--help|-h)
            echo "Usage: jarvis-gemini.sh {ask|stream|diag} [prompt]"
            echo ""
            echo "  ask 'your question'     - Ask JARVIS anything"
            echo "  stream 'your question'  - Streaming response"
            echo "  diag                    - System diagnostic"
            ;;
        *)
            # Treat any unknown first arg as the start of a question
            jarvis_ask "$*"
            ;;
    esac
fi
