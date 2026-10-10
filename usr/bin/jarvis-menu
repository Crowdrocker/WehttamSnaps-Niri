#!/bin/bash
# WehttamSnaps J.A.R.V.I.S. Rofi/Wofi Visual Menu
# Graphical command interface with icons and categories
# Author: Matthew (WehttamSnaps)

set -euo pipefail

# ================================
# CONFIGURATION
# ================================

JARVIS_CMD="/usr/local/bin/jarvis"
LAUNCHER="${ROFI_LAUNCHER:-rofi}"  # Can be 'rofi' or 'wofi'

# Detect which launcher is available
if ! command -v "$LAUNCHER" &> /dev/null; then
    if command -v rofi &> /dev/null; then
        LAUNCHER="rofi"
    elif command -v wofi &> /dev/null; then
        LAUNCHER="wofi"
    else
        notify-send "J.A.R.V.I.S. Error" "Neither Rofi nor Wofi is installed" -i dialog-error
        exit 1
    fi
fi

# ================================
# MENU CATEGORIES
# ================================

# Main menu options with icons
MAIN_MENU=(
    "🚀 Launch Applications|apps"
    "🪟 Window Control|windows"
    "🎯 Workspaces|workspaces"
    "🔊 Audio Control|audio"
    "🔍 Web Search|search"
    "⚙️  System Commands|system"
    "🎮 Gaming Mode|gaming"
    "📸 Photography Mode|photo"
    "💬 Talk to J.A.R.V.I.S.|talk"
    "❌ Cancel|cancel"
)

# Application launcher submenu
APP_MENU=(
    "🦊 Firefox|firefox"
    "🌐 Chrome|chrome"
    "🎮 Steam|steam"
    "💬 Discord|discord"
    "🎵 Spotify|spotify"
    "📝 VS Code|vscode"
    "🖥️  Terminal|terminal"
    "📁 File Manager|files"
    "🎨 GIMP|gimp"
    "🎥 OBS Studio|obs"
    "⬅️  Back|back"
)

# Window control submenu
WINDOW_MENU=(
    "❌ Close Window|close"
    "⬜ Maximize|maximize"
    "🖥️  Fullscreen|fullscreen"
    "🔲 Tile Window|tile"
    "🎈 Float Window|float"
    "🎯 Center Window|center"
    "⬅️  Back|back"
)

# Workspace submenu
WORKSPACE_MENU=(
    "1️⃣  Workspace 1|1"
    "2️⃣  Workspace 2 (Gaming)|2"
    "3️⃣  Workspace 3 (Photo)|3"
    "4️⃣  Workspace 4|4"
    "5️⃣  Workspace 5|5"
    "6️⃣  Workspace 6|6"
    "7️⃣  Workspace 7|7"
    "8️⃣  Workspace 8|8"
    "9️⃣  Workspace 9|9"
    "🔟 Workspace 10|10"
    "➡️  Next Workspace|next"
    "⬅️  Previous Workspace|previous"
    "⬅️  Back|back"
)

# Audio control submenu
AUDIO_MENU=(
    "🔇 Mute/Unmute|mute"
    "🔊 Volume Up|volume up"
    "🔉 Volume Down|volume down"
    "▶️  Play Music|play music"
    "⏸️  Pause Music|pause music"
    "⏭️  Next Track|next track"
    "⏮️  Previous Track|previous track"
    "⬅️  Back|back"
)

# Web search submenu
SEARCH_MENU=(
    "🔍 Google Search|google"
    "📺 YouTube Search|youtube"
    "💻 GitHub Search|github"
    "⬅️  Back|back"
)

# System commands submenu
SYSTEM_MENU=(
    "📸 Take Screenshot|screenshot"
    "🔒 Lock Screen|lock"
    "🔄 Reload Config|reload"
    "📊 System Status|status"
    "⬅️  Back|back"
)

# ================================
# LAUNCHER FUNCTIONS
# ================================

show_rofi_menu() {
    local prompt="$1"
    shift
    local options=("$@")

    # Format options for display
    local formatted_options=()
    for option in "${options[@]}"; do
        # Extract display text (before pipe)
        formatted_options+=("${option%%|*}")
    done

    if [[ "$LAUNCHER" == "rofi" ]]; then
        printf '%s\n' "${formatted_options[@]}" | rofi -dmenu \
            -i \
            -p "$prompt" \
            -theme-str 'window {width: 600px;} listview {lines: 10;}' \
            -theme-str 'element-text {color: #d3c6aa;} element selected {background-color: #7fbbb3; text-color: #2d353b;}' \
            -no-custom
    else  # wofi
        printf '%s\n' "${formatted_options[@]}" | wofi \
            --dmenu \
            --prompt "$prompt" \
            --width 600 \
            --height 400 \
            --insensitive \
            --cache-file /dev/null
    fi
}

show_text_input() {
    local prompt="$1"

    if [[ "$LAUNCHER" == "rofi" ]]; then
        rofi -dmenu \
            -p "$prompt" \
            -theme-str 'window {width: 600px;}' \
            -lines 0
    else  # wofi
        wofi --dmenu \
            --prompt "$prompt" \
            --width 600 \
            --lines 0 \
            --cache-file /dev/null
    fi
}

# ================================
# MENU HANDLERS
# ================================

handle_app_menu() {
    local choice
    choice=$(show_rofi_menu "Launch Application" "${APP_MENU[@]}")

    if [[ -z "$choice" ]]; then
        return
    fi

    # Extract command from selection
    local cmd
    for item in "${APP_MENU[@]}"; do
        if [[ "${item%%|*}" == "$choice" ]]; then
            cmd="${item##*|}"
            break
        fi
    done

    case "$cmd" in
        back)
            show_main_menu
            ;;
        *)
            $JARVIS_CMD open "$cmd"
            ;;
    esac
}

handle_window_menu() {
    local choice
    choice=$(show_rofi_menu "Window Control" "${WINDOW_MENU[@]}")

    if [[ -z "$choice" ]]; then
        return
    fi

    local cmd
    for item in "${WINDOW_MENU[@]}"; do
        if [[ "${item%%|*}" == "$choice" ]]; then
            cmd="${item##*|}"
            break
        fi
    done

    case "$cmd" in
        back)
            show_main_menu
            ;;
        *)
            $JARVIS_CMD "$cmd" window
            ;;
    esac
}

handle_workspace_menu() {
    local choice
    choice=$(show_rofi_menu "Switch Workspace" "${WORKSPACE_MENU[@]}")

    if [[ -z "$choice" ]]; then
        return
    fi

    local cmd
    for item in "${WORKSPACE_MENU[@]}"; do
        if [[ "${item%%|*}" == "$choice" ]]; then
            cmd="${item##*|}"
            break
        fi
    done

    case "$cmd" in
        back)
            show_main_menu
            ;;
        next|previous)
            $JARVIS_CMD workspace "$cmd"
            ;;
        *)
            $JARVIS_CMD go to workspace "$cmd"
            ;;
    esac
}

handle_audio_menu() {
    local choice
    choice=$(show_rofi_menu "Audio Control" "${AUDIO_MENU[@]}")

    if [[ -z "$choice" ]]; then
        return
    fi

    local cmd
    for item in "${AUDIO_MENU[@]}"; do
        if [[ "${item%%|*}" == "$choice" ]]; then
            cmd="${item##*|}"
            break
        fi
    done

    case "$cmd" in
        back)
            show_main_menu
            ;;
        *)
            $JARVIS_CMD "$cmd"
            ;;
    esac
}

handle_search_menu() {
    local choice
    choice=$(show_rofi_menu "Web Search" "${SEARCH_MENU[@]}")

    if [[ -z "$choice" ]]; then
        return
    fi

    local cmd
    for item in "${SEARCH_MENU[@]}"; do
        if [[ "${item%%|*}" == "$choice" ]]; then
            cmd="${item##*|}"
            break
        fi
    done

    case "$cmd" in
        back)
            show_main_menu
            ;;
        google|youtube|github)
            local query
            query=$(show_text_input "Search $cmd for:")
            if [[ -n "$query" ]]; then
                $JARVIS_CMD search "$cmd" for "$query"
            fi
            ;;
    esac
}

handle_system_menu() {
    local choice
    choice=$(show_rofi_menu "System Commands" "${SYSTEM_MENU[@]}")

    if [[ -z "$choice" ]]; then
        return
    fi

    local cmd
    for item in "${SYSTEM_MENU[@]}"; do
        if [[ "${item%%|*}" == "$choice" ]]; then
            cmd="${item##*|}"
            break
        fi
    done

    case "$cmd" in
        back)
            show_main_menu
            ;;
        *)
            $JARVIS_CMD "$cmd"
            ;;
    esac
}

handle_talk_mode() {
    local command
    command=$(show_text_input "J.A.R.V.I.S., ")

    if [[ -n "$command" ]]; then
        $JARVIS_CMD "$command"
    fi
}

# ================================
# MAIN MENU
# ================================

show_main_menu() {
    local choice
    choice=$(show_rofi_menu "J.A.R.V.I.S. Command Center" "${MAIN_MENU[@]}")

    if [[ -z "$choice" ]]; then
        exit 0
    fi

    # Extract command from selection
    local cmd
    for item in "${MAIN_MENU[@]}"; do
        if [[ "${item%%|*}" == "$choice" ]]; then
            cmd="${item##*|}"
            break
        fi
    done

    case "$cmd" in
        apps)
            handle_app_menu
            ;;
        windows)
            handle_window_menu
            ;;
        workspaces)
            handle_workspace_menu
            ;;
        audio)
            handle_audio_menu
            ;;
        search)
            handle_search_menu
            ;;
        system)
            handle_system_menu
            ;;
        gaming)
            $JARVIS_CMD gaming mode
            ;;
        photo)
            $JARVIS_CMD photography
            ;;
        talk)
            handle_talk_mode
            ;;
        cancel)
            exit 0
            ;;
    esac
}

# ================================
# QUICK LAUNCH MODES
# ================================

# Direct app launcher (no categories)
quick_app_launcher() {
    local choice
    choice=$(show_rofi_menu "Launch Application" "${APP_MENU[@]}")

    if [[ -n "$choice" ]]; then
        local cmd
        for item in "${APP_MENU[@]}"; do
            if [[ "${item%%|*}" == "$choice" ]]; then
                cmd="${item##*|}"
                [[ "$cmd" != "back" ]] && $JARVIS_CMD open "$cmd"
                break
            fi
        done
    fi
}

# Direct workspace switcher
quick_workspace_switcher() {
    local choice
    choice=$(show_rofi_menu "Switch Workspace" "${WORKSPACE_MENU[@]}")

    if [[ -n "$choice" ]]; then
        local cmd
        for item in "${WORKSPACE_MENU[@]}"; do
            if [[ "${item%%|*}" == "$choice" ]]; then
                cmd="${item##*|}"
                if [[ "$cmd" != "back" ]]; then
                    if [[ "$cmd" =~ ^[0-9]+$ ]]; then
                        $JARVIS_CMD go to workspace "$cmd"
                    else
                        $JARVIS_CMD workspace "$cmd"
                    fi
                fi
                break
            fi
        done
    fi
}

# Free-form command input
free_command() {
    local command
    command=$(show_text_input "J.A.R.V.I.S. Command:")

    if [[ -n "$command" ]]; then
        $JARVIS_CMD "$command"
    fi
}

# ================================
# MAIN ENTRY POINT
# ================================

case "${1:-main}" in
    main|menu)
        show_main_menu
        ;;
    apps|quick-apps)
        quick_app_launcher
        ;;
    workspaces|quick-workspace)
        quick_workspace_switcher
        ;;
    command|free)
        free_command
        ;;
    help|--help|-h)
        cat << EOF
J.A.R.V.I.S. Rofi/Wofi Visual Menu

Usage:
  jarvis-menu [mode]

Modes:
  main              Show full menu with categories (default)
  apps              Quick app launcher only
  workspaces        Quick workspace switcher only
  command           Free-form command input
  help              Show this help

Keybind Examples:
  Mod+Space       → Full J.A.R.V.I.S. menu
  Mod+A           → Quick app launcher
  Mod+W           → Quick workspace switcher
  Mod+Slash       → Free command input

EOF
        ;;
    *)
        echo "Unknown mode: $1"
        echo "Run 'jarvis-menu help' for usage"
        exit 1
        ;;
esac
