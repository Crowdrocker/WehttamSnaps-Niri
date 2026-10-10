#!/bin/bash
# WehttamSnaps J.A.R.V.I.S. AI Integration with Gemini
# Fully integrated with sound-system and existing J.A.R.V.I.S. commands
# Author: Matthew (WehttamSnaps)
#
# FIX: Removed set -u — causes "unbound variable" crash when sourced into
# interactive shells that call functions without arguments. All $1 usage
# is now guarded with ${1:-} defaults instead.

SCRIPT_DIR="$HOME/.config/wehttamsnaps/scripts"
SOUND_SYSTEM="$HOME/.config/wehttamsnaps/scripts/sound-system.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════════════
# CORE JARVIS AI FUNCTIONS WITH SOUND INTEGRATION
# ═══════════════════════════════════════════════════════════════════

jarvis-ask() {
    local query="${*:-}"

    if [ -z "$query" ]; then
        echo "❌ Usage: jarvis-ask <your question>"
        return 1
    fi

    # Play thinking sound
    if command -v sound-system &>/dev/null; then
        sound-system notification &
    elif [ -x "$SOUND_SYSTEM" ]; then
        "$SOUND_SYSTEM" notification &
    fi

    echo -e "${CYAN}🤖 J.A.R.V.I.S. is processing your request, sir...${NC}"

    local system_prompt="You are J.A.R.V.I.S., Tony Stark's AI assistant from Iron Man. You are helpful, witty, and sophisticated. Address the user as 'sir' or 'Matthew' when appropriate. Keep responses concise and practical for terminal use, but maintain your characteristic dry wit and British eloquence."
    local response
    response=$(gemini "$system_prompt\n\nUser query: $query" 2>/dev/null)
    local exit_code=$?

    if command -v sound-system &>/dev/null; then
        sound-system notification &
    fi

    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "${CYAN}┌─[ J.A.R.V.I.S. Response ]─────────────────────────────────${NC}"
        echo "$response" | fold -s -w 70 | sed "s/^/${CYAN}│${NC} /"
        echo -e "${CYAN}└───────────────────────────────────────────────────────────${NC}"
        echo ""
    else
        echo -e "${RED}❌ Error communicating with Gemini API${NC}"
        return 1
    fi
}

# Quick alias function
j() {
    jarvis-ask "$@"
}

# ═══════════════════════════════════════════════════════════════════
# HYPRLAND / COMPOSITOR HELPERS  (updated from Niri)
# ═══════════════════════════════════════════════════════════════════

jarvis-hypr-help() {
    local topic="${1:-general usage and best practices}"
    jarvis-ask "As an expert in Hyprland Wayland compositor on Arch Linux, explain $topic. Be specific to Hyprland's config format and provide practical examples for my system: i5-4430, AMD RX 580, 16GB RAM."
}

# Kept for backwards compat — redirects to hypr version
jarvis-niri-help() {
    jarvis-hypr-help "${1:-}"
}

jarvis-analyze-config() {
    local config_file="${1:-$HOME/.config/hypr/hyprland.conf}"

    if [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ Config file not found: $config_file${NC}"
        return 1
    fi

    echo -e "${BLUE}🔍 Analyzing $(basename "$config_file")...${NC}"

    if command -v sound-system &>/dev/null; then
        sound-system notification &
    fi

    gemini "Analyze this Hyprland configuration for a system with i5-4430, AMD RX 580, 16GB RAM. Suggest optimizations for gaming performance, photography workflow, and overall smoothness. Focus on practical improvements:" < "$config_file"
}

jarvis-debug-hypr() {
    echo -e "${BLUE}📋 Gathering Hyprland diagnostics...${NC}"

    if command -v sound-system &>/dev/null; then
        sound-system notification &
    fi

    local log_file="/tmp/hypr-debug-$(date +%s).log"
    journalctl --user --since "30 minutes ago" | grep -i hyprland > "$log_file" 2>/dev/null || true

    echo -e "${CYAN}🤖 J.A.R.V.I.S. analyzing compositor logs...${NC}"
    gemini "Analyze this Hyprland compositor log from an Arch Linux system. Identify errors, performance issues, or warnings. Provide specific solutions:" < "$log_file"

    rm -f "$log_file"
}

# Kept for backwards compat
jarvis-debug-niri() { jarvis-debug-hypr; }

# ═══════════════════════════════════════════════════════════════════
# GAMING & PROTON HELPERS
# ═══════════════════════════════════════════════════════════════════

jarvis-proton-debug() {
    local game_log="${1:-}"

    if [ -z "$game_log" ]; then
        game_log=$(find ~/.steam/steam/steamapps/compatdata -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2- || echo "")

        if [ -z "$game_log" ]; then
            echo -e "${YELLOW}⚠️  No recent Proton logs found${NC}"
            echo "Try running a game first, then try again."
            return 1
        fi
    fi

    if [ ! -f "$game_log" ]; then
        echo -e "${RED}❌ Log file not found: $game_log${NC}"
        return 1
    fi

    echo -e "${GREEN}🎮 Analyzing game compatibility for AMD RX 580...${NC}"

    if command -v sound-system &>/dev/null; then
        sound-system notification &
    fi

    tail -1000 "$game_log" | gemini "Analyze this Proton/Wine log from Steam on Arch Linux. Hardware: AMD RX 580 GPU with Mesa drivers, i5-4430 CPU. Identify crashes, errors, or compatibility issues. Suggest fixes specific to this hardware and Linux gaming:"
}

jarvis-game-settings() {
    local game="${1:-}"

    if [ -z "$game" ]; then
        echo -e "${YELLOW}Usage: jarvis-game-settings <game name>${NC}"
        return 1
    fi

    jarvis-ask "What are the optimal graphics settings for $game on Linux with an AMD RX 580 GPU (8GB VRAM) and i5-4430 CPU? Consider Proton compatibility, RADV driver performance, and aim for 60+ FPS at 1080p. Be specific about which settings to prioritize."
}

# ═══════════════════════════════════════════════════════════════════
# PHOTOGRAPHY WORKFLOW
# ═══════════════════════════════════════════════════════════════════

jarvis-photo-tips() {
    local topic="${1:-general landscape photography workflow in Darktable}"
    jarvis-ask "As a photography expert familiar with Darktable on Linux, explain $topic. Provide practical, step-by-step advice for landscape photography. Be specific about module order and settings."
}

jarvis-darktable-help() {
    local module="${1:-}"

    if [ -z "$module" ]; then
        echo -e "${YELLOW}Usage: jarvis-darktable-help <module name>${NC}"
        echo "Example: jarvis-darktable-help 'tone equalizer'"
        return 1
    fi

    jarvis-ask "Explain the Darktable '$module' module in detail. Include: what it does, when to use it, recommended settings for landscape photography, and how it interacts with other modules in the pipeline."
}

# ═══════════════════════════════════════════════════════════════════
# SYSTEM DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════════

jarvis-diagnose() {
    echo -e "${BLUE}🔧 Running system diagnostics...${NC}"

    if command -v sound-system &>/dev/null; then
        sound-system notification &
    fi

    local diag_file="/tmp/jarvis-diag-$(date +%s).txt"

    {
        echo "=== SYSTEM INFO ==="
        uname -a
        echo ""
        echo "=== HARDWARE ==="
        echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
        echo "GPU: $(lspci | grep -i vga | cut -d':' -f3 | xargs)"
        echo ""
        echo "=== MEMORY ==="
        free -h
        echo ""
        echo "=== DISK USAGE ==="
        df -h / /home 2>/dev/null
        echo ""
        echo "=== TOP PROCESSES (CPU) ==="
        ps aux --sort=-%cpu | head -6
        echo ""
        echo "=== RECENT ERRORS (Last 20) ==="
        journalctl -p err -n 20 --no-pager 2>/dev/null || echo "No recent errors"
    } > "$diag_file"

    gemini "Analyze this Arch Linux system diagnostic from a system with i5-4430, RX 580, 16GB RAM running Hyprland compositor. Identify issues, bottlenecks, or unusual resource usage. Suggest optimizations:" < "$diag_file"

    rm -f "$diag_file"
}

jarvis-explain-error() {
    echo -e "${BLUE}🔍 Fetching most recent error...${NC}"

    local error_log
    error_log=$(journalctl -p err -n 1 --no-pager 2>/dev/null)

    if [ -z "$error_log" ]; then
        echo -e "${GREEN}✅ No recent errors found. System is running smoothly, sir.${NC}"
        return 0
    fi

    if command -v sound-system &>/dev/null; then
        sound-system notification &
    fi

    echo "$error_log" | gemini "Explain this Linux system error in simple terms. What caused it and how can it be fixed? Provide specific commands if applicable:"
}

# ═══════════════════════════════════════════════════════════════════
# CODE & SCRIPT HELPERS
# ═══════════════════════════════════════════════════════════════════

jarvis-explain-script() {
    local script="${1:-}"

    if [ -z "$script" ]; then
        echo -e "${YELLOW}Usage: jarvis-explain-script <file path>${NC}"
        return 1
    fi

    if [ ! -f "$script" ]; then
        echo -e "${RED}❌ Script not found: $script${NC}"
        return 1
    fi

    gemini "Explain what this $(file -b "$script") does, step by step. Break down the logic, identify key functions, and describe the overall purpose:" < "$script"
}

jarvis-code-review() {
    local file="${1:-}"

    if [ -z "$file" ]; then
        echo -e "${YELLOW}Usage: jarvis-code-review <file path>${NC}"
        return 1
    fi

    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ File not found: $file${NC}"
        return 1
    fi

    gemini "Review this code/configuration file. Focus on: bugs, security issues, performance problems, best practices violations, and readability. Suggest specific improvements:" < "$file"
}

jarvis-generate-script() {
    local description="${*:-}"

    if [ -z "$description" ]; then
        echo -e "${YELLOW}Usage: jarvis-generate-script <description>${NC}"
        echo "Example: jarvis-generate-script backup my dotfiles to github daily"
        return 1
    fi

    gemini "Generate a complete, production-ready bash script that: $description. Include: error handling, comments, proper shebang, and make it compatible with Arch Linux and Hyprland Wayland compositor. Use modern bash best practices."
}

# ═══════════════════════════════════════════════════════════════════
# AUDIO ANALYSIS
# ═══════════════════════════════════════════════════════════════════

jarvis-analyze-audio() {
    echo -e "${BLUE}🔊 Analyzing audio system configuration...${NC}"

    local audio_info="/tmp/audio-info-$(date +%s).txt"

    {
        echo "=== PIPEWIRE STATUS ==="
        wpctl status 2>/dev/null || echo "wpctl not available"
        echo ""
        echo "=== AUDIO DEVICES ==="
        pactl list sinks short 2>/dev/null || echo "pactl not available"
        echo ""
        echo "=== AUDIO SOURCES ==="
        pactl list sources short 2>/dev/null
    } > "$audio_info"

    gemini "Analyze this PipeWire/PulseAudio configuration. Identify the optimal setup for gaming and music production. Suggest improvements for low latency and quality:" < "$audio_info"

    rm -f "$audio_info"
}

# ═══════════════════════════════════════════════════════════════════
# QUICK SHORTCUTS
# ═══════════════════════════════════════════════════════════════════

wtf() { jarvis-explain-error; }
why() { jarvis-diagnose; }

# ═══════════════════════════════════════════════════════════════════
# AI INTEGRATION DISPATCHER (called by keybinds etc.)
# ═══════════════════════════════════════════════════════════════════

jarvis-ai-integration() {
    local mode="${1:-}"
    shift || true   # ← was the crash: shift with no args + set -u = boom

    case "$mode" in
        ask)    jarvis-ask "$@" ;;
        hypr)   jarvis-hypr-help "$@" ;;
        niri)   jarvis-hypr-help "$@" ;;  # backwards compat
        game)   jarvis-game-settings "$@" ;;
        photo)  jarvis-photo-tips "$@" ;;
        debug)  jarvis-proton-debug "$@" ;;
        "")
            echo "Usage: jarvis-ai-integration <ask|hypr|game|photo|debug> [args]"
            return 1
            ;;
        *)
            echo "Unknown AI mode: $mode"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# EXPORTS
# ═══════════════════════════════════════════════════════════════════

export -f jarvis-ask j
export -f jarvis-hypr-help jarvis-niri-help jarvis-analyze-config jarvis-debug-hypr jarvis-debug-niri
export -f jarvis-proton-debug jarvis-game-settings
export -f jarvis-photo-tips jarvis-darktable-help
export -f jarvis-diagnose jarvis-explain-error
export -f jarvis-explain-script jarvis-code-review jarvis-generate-script
export -f jarvis-analyze-audio
export -f wtf why
export -f jarvis-ai-integration

# ═══════════════════════════════════════════════════════════════════
# MAIN (if run directly, not sourced)
# ═══════════════════════════════════════════════════════════════════

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-help}" in
        ask)   shift; jarvis-ask "$@" ;;
        hypr)  shift; jarvis-hypr-help "$@" ;;
        game)  shift; jarvis-game-settings "$@" ;;
        photo) shift; jarvis-photo-tips "$@" ;;
        debug) shift; jarvis-proton-debug "$@" ;;
        diag)  jarvis-diagnose ;;
        error) jarvis-explain-error ;;
        help|*)
            echo -e "${CYAN}WehttamSnaps J.A.R.V.I.S. AI (Gemini)${NC}"
            echo ""
            echo "  jarvis-ai.sh ask <question>"
            echo "  jarvis-ai.sh game <game name>"
            echo "  jarvis-ai.sh photo [topic]"
            echo "  jarvis-ai.sh debug [log file]"
            echo "  jarvis-ai.sh diag"
            echo "  jarvis-ai.sh error"
            echo "  jarvis-ai.sh hypr [topic]"
            ;;
    esac
fi
