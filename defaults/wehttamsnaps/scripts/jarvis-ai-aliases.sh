#!/bin/bash
# WehttamSnaps J.A.R.V.I.S. AI Aliases
# Source via ~/.bashrc — jarvis-ai.sh must be sourced first
# Author: Matthew (WehttamSnaps)
# FIX: Removed niri-specific aliases, updated config paths to Hyprland

# ═══════════════════════════════════════════════════════════════════
# SOURCE AI FUNCTIONS (safe double-source — guarded by JARVIS_AI_LOADED)
# ═══════════════════════════════════════════════════════════════════

if [ -z "${JARVIS_FUNCTIONS_LOADED:-}" ] && [ -f "$HOME/.config/wehttamsnaps/scripts/jarvis-ai.sh" ]; then
    source "$HOME/.config/wehttamsnaps/scripts/jarvis-ai.sh"
fi

# ═══════════════════════════════════════════════════════════════════
# QUICK ACCESS ALIASES
# ═══════════════════════════════════════════════════════════════════

alias ask='~/.config/wehttamsnaps/scripts/jarvis-gemini.sh ask'
alias wtf='jarvis-explain-error'
alias why='jarvis-diagnose'
alias learn='learn-cmd'
alias docs='get-docs'
alias examples='get-examples'

# ═══════════════════════════════════════════════════════════════════
# HYPRLAND COMPOSITOR ALIASES
# ═══════════════════════════════════════════════════════════════════

alias hypr-help='jarvis-hypr-help'
alias hypr-fix='jarvis-debug-hypr'
alias hypr-analyze='jarvis-analyze-config ~/.config/hypr/UserConfigs/UserSettings.conf'
alias config-check='jarvis-analyze-config'

# ═══════════════════════════════════════════════════════════════════
# GAMING ALIASES
# ═══════════════════════════════════════════════════════════════════

alias game-fix='jarvis-proton-debug'
alias game-settings='jarvis-game-settings'
alias proton-help='jarvis-ask "explain Proton compatibility and how to troubleshoot games on Linux"'
alias cyberpunk-help='jarvis-game-settings "Cyberpunk 2077"'
alias division-help='jarvis-game-settings "The Division 2"'
alias fallout-help='jarvis-game-settings "Fallout 4"'
alias skyrim-help='jarvis-game-settings "Skyrim Special Edition"'

# ═══════════════════════════════════════════════════════════════════
# PHOTOGRAPHY WORKFLOW ALIASES
# ═══════════════════════════════════════════════════════════════════

alias photo-help='jarvis-photo-tips'
alias dt-help='jarvis-darktable-help'
alias darktable-tips='jarvis-photo-tips "Darktable workflow for landscape photography"'
alias tone-help='jarvis-darktable-help "tone equalizer"'
alias color-help='jarvis-darktable-help "color balance rgb"'
alias denoise-help='jarvis-darktable-help "denoise profiled"'

# ═══════════════════════════════════════════════════════════════════
# CODE & SCRIPT ALIASES
# ═══════════════════════════════════════════════════════════════════

alias explain='jarvis-explain-script'
alias review='jarvis-code-review'
alias generate='jarvis-generate-script'
alias check-script='jarvis-code-review'
alias what-does-this-do='jarvis-explain-script'

# Pipe-friendly helpers
alias jarvis-explain='gemini "Explain this output in simple terms:"'
alias jarvis-optimize='gemini "Suggest optimizations for this:"'
alias jarvis-debug='gemini "Debug this error and provide solutions:"'
alias jarvis-summarize='gemini "Summarize this concisely:"'

# ═══════════════════════════════════════════════════════════════════
# SYSTEM DIAGNOSTIC ALIASES
# ═══════════════════════════════════════════════════════════════════

alias diagnose='jarvis-diagnose'
alias check-system='jarvis-diagnose'
alias audio-check='jarvis-analyze-audio'
alias gpu-check='jarvis-ask "analyze my AMD RX 580 status and performance on Linux with Mesa/RADV"'

# ═══════════════════════════════════════════════════════════════════
# CONTEXT-AWARE HELPERS
# ═══════════════════════════════════════════════════════════════════

learn-cmd() {
    local cmd="${*:-}"
    if [ -z "$cmd" ]; then
        echo "Usage: learn-cmd <command>"
        echo "Example: learn-cmd pacman -Syu"
        return 1
    fi
    jarvis-ask "Explain this command and what it does: $cmd"
}

get-docs() {
    local topic="${*:-}"
    if [ -z "$topic" ]; then
        echo "Usage: get-docs <topic>"
        echo "Example: get-docs hyprland window rules"
        return 1
    fi
    jarvis-ask "Provide documentation and examples for: $topic"
}

get-examples() {
    local topic="${*:-}"
    if [ -z "$topic" ]; then
        echo "Usage: get-examples <topic>"
        return 1
    fi
    jarvis-ask "Show me 3-5 practical examples of: $topic"
}

# ═══════════════════════════════════════════════════════════════════
# WORKFLOW COMBINATIONS
# ═══════════════════════════════════════════════════════════════════

photo-export() {
    sound-system photo-export 2>/dev/null || true
    jarvis-ask "What are the best export settings for web vs print in Darktable?"
}

gaming-mode() {
    sound-system gaming-toggle 2>/dev/null || true
    jarvis-ask "I just enabled gaming mode. Give me quick performance tips for AMD RX 580 on Linux."
}

resource-hog() {
    echo "Top CPU processes:"
    ps aux --sort=-%cpu | head -6
    echo ""
    ps aux --sort=-%cpu | head -6 | gemini "Which of these processes should I be concerned about and why?"
}

# ═══════════════════════════════════════════════════════════════════
# SOUND SYSTEM HELPERS
# ═══════════════════════════════════════════════════════════════════

check-sounds() {
    sound-system list 2>/dev/null || ~/.config/wehttamsnaps/scripts/sound-system.sh list
    echo ""
    jarvis-ask "I have J.A.R.V.I.S. and iDroid sound packs integrated into Hyprland. Suggest creative ways to use them for productivity."
}

test-jarvis() {
    sound-system notification 2>/dev/null || true
    jarvis-ask "Say 'Systems online, sir. All diagnostic checks complete.' in your best J.A.R.V.I.S. impression."
    sound-system notification 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════
# EXPORTS
# ═══════════════════════════════════════════════════════════════════

export -f learn-cmd get-docs get-examples
export -f photo-export gaming-mode resource-hog
export -f check-sounds test-jarvis

# ═══════════════════════════════════════════════════════════════════
# WELCOME MESSAGE (one per session)
# ═══════════════════════════════════════════════════════════════════

if [ -n "${PS1:-}" ] && [ -z "${JARVIS_AI_LOADED:-}" ]; then
    export JARVIS_AI_LOADED=1
    echo -e "\033[0;36m╔═══════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[0;36m║   J.A.R.V.I.S. AI Integration Active                 ║\033[0m"
    echo -e "\033[0;36m╚═══════════════════════════════════════════════════════╝\033[0m"
    echo -e "\033[1;33mQuick commands: j, wtf, why, game-fix, photo-help\033[0m"
    echo -e "\033[0;90mType 'jarvis-ai.sh' for full command list\033[0m"
    echo ""
fi
