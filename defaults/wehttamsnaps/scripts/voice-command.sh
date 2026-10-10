#!/bin/bash
# WehttamSnaps Voice Command System
# Parses spoken commands, executes actions, and plays voice replies
# Reuses your existing sound-system for voice feedback

set -euo pipefail

SOUND_BASE="/usr/share/wehttamsnaps/sounds"
LIB_PATH="/usr/local/bin/sound-system"  # Reuse your existing script

# Get current voice mode (jarvis or idroid)
get_voice_mode() {
    if [[ -f "$HOME/.cache/wehttamsnaps/gaming-mode.active" ]]; then
        echo "idroid"
    else
        echo "jarvis"
    fi
}

# Play a voice reply using your sound system
say() {
    local phrase="$1"
    local mode="${2:-$(get_voice_mode)}"
    # Try to play specific reply; fallback to generic notification
    if [[ -f "$SOUND_BASE/$mode/$phrase.mp3" ]]; then
        paplay "$SOUND_BASE/$mode/$phrase.mp3" &
    else
        # Fallback to generic notification if phrase not recorded
        "$LIB_PATH" notification
    fi
}

# Main command dispatcher
execute_command() {
    local input="$1"
    local mode
    mode=$(get_voice_mode)

    # Normalize input: lowercase, trim, remove extra spaces
    input=$(echo "$input" | tr '[:upper:]' '[:lower:]' | xargs)

    # === WINDOW MANAGEMENT ===
    if [[ "$input" == "close window" ]]; then
        niri msg action close-window
        say "window-close"

    elif [[ "$input" == "maximize"* ]]; then
        niri msg action maximize-window
        say "notification"  # or add maximize.mp3 later
        echo "Window maximized."

    elif [[ "$input" == "tile"* ]]; then
        niri msg action toggle-tiled
        say "notification"
        echo "Window tiled."

    elif [[ "$input" == "float"* ]]; then
        niri msg action toggle-tiled
        say "notification"
        echo "Window floated."

    # === WEB / SEARCH ===
    elif [[ "$input" == "search google for "* ]]; then
        query="${input#search google for }"
        encoded=$(printf '%s' "$query" | jq -sRr @uri)
        xdg-open "https://www.google.com/search?q=$encoded" >/dev/null 2>&1 &
        say "notification"
        echo "Searching Google for: $query"

    elif [[ "$input" == "search for "* ]]; then
        query="${input#search for }"
        encoded=$(printf '%s' "$query" | jq -sRr @uri)
        xdg-open "https://www.google.com/search?q=$encoded" >/dev/null 2>&1 &
        say "notification"

    # === MEDIA CONTROL ===
    elif [[ "$input" == "play music" ]]; then
        playerctl play 2>/dev/null || { say "alert-high" "$mode"; echo "No music player found."; return 1; }
        say "notification"

    elif [[ "$input" == "pause music" ]]; then
        playerctl pause 2>/dev/null || { say "alert-high" "$mode"; echo "No music player found."; return 1; }
        say "notification"

    # === APPLICATIONS ===
    elif [[ "$input" == "open chatgpt" ]]; then
        xdg-open "https://chatgpt.com" >/dev/null 2>&1 &
        say "notification"
        echo "Opening ChatGPT."

    elif [[ "$input" == "open discord" ]]; then
        discord &>/dev/null &
        say "discord-notify" "$mode"

    elif [[ "$input" == "open steam" ]]; then
        "$LIB_PATH" steam-launch
        steam &>/dev/null &

    # === WORKSPACES ===
    elif [[ "$input" == "go to workspace "* ]]; then
        ws="${input#go to workspace }"
        if [[ "$ws" =~ ^[0-9]+$ ]] && (( ws >= 1 && ws <= 10 )); then
            niri msg action focus-workspace "$ws"
            "$LIB_PATH" workspace "$ws"
        else
            say "alert-high" "$mode"
        fi

    # === SYSTEM ===
    elif [[ "$input" == "take screenshot" ]]; then
        grim "$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"
        "$LIB_PATH" screenshot

    elif [[ "$input" == "what mode are you in" ]]; then
        if [[ "$mode" == "jarvis" ]]; then
            say "notification"
            echo "I am in professional mode, sir."
        else
            say "alert-medium" "$mode"
            echo "Tactical mode active."
        fi

    else
        say "alert-high" "$mode"
        echo "Command not recognized: '$input'"
        return 1
    fi
}

# === REAL VOICE INPUT (via Whisper.cpp / vosk / etc.) ===
# For now, accept command via CLI for testing
if [[ $# -eq 0 ]]; then
    echo "Usage: voice-command \"<spoken phrase>\""
    echo "Example: voice-command \"close window\""
    exit 1
fi

execute_command "$*"
