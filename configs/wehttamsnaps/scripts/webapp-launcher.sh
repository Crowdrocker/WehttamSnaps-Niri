#!/usr/bin/env bash
# === WEHTTAMSNAPS WEBAPP LAUNCHER ===
# Author: Matthew (WehttamSnaps)
# GitHub: https://github.com/Crowdrocker
#
# Launch web applications in standalone windows
# Similar to Omarchy webapp system

set -euo pipefail

# Configuration
WEBAPPS_DIR="$HOME/.config/wehttamsnaps/webapps"
CACHE_DIR="$HOME/.cache/wehttamsnaps/webapps"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create directories
mkdir -p "$WEBAPPS_DIR"
mkdir -p "$CACHE_DIR"

# Function to launch webapp with Brave
launch_brave() {
    local name="$1"
    local url="$2"
    local icon="${3:-web-browser}"

    brave \
        --app="$url" \
        --class="$name-webapp" \
        --user-data-dir="$CACHE_DIR/$name" \
        --no-first-run \
        --no-default-browser-check \
        > /dev/null 2>&1 &
}

# Function to launch webapp with Firefox
launch_firefox() {
    local name="$1"
    local url="$2"

    firefox \
        --class "$name-webapp" \
        --new-window "$url" \
        > /dev/null 2>&1 &
}

# Function to launch webapp with Chromium
launch_chromium() {
    local name="$1"
    local url="$2"

    chromium \
        --app="$url" \
        --class="$name-webapp" \
        --user-data-dir="$CACHE_DIR/$name" \
        > /dev/null 2>&1 &
}

# Function to load webapp config
load_webapp_config() {
    local webapp_name="$1"
    local config_file="$WEBAPPS_DIR/$webapp_name.webapp"

    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}Error: Webapp config not found: $config_file${NC}" >&2
        return 1
    fi

    # Source the config file
    source "$config_file"
}

# Function to launch webapp by name
launch_webapp() {
    local webapp_name="$1"

    # Predefined webapps (fallback if config file doesn't exist)
    case "$webapp_name" in
        youtube)
            WEBAPP_NAME="YouTube"
            WEBAPP_URL="https://www.youtube.com"
            WEBAPP_ICON="youtube"
            WEBAPP_BROWSER="brave"
            ;;
        twitch)
            WEBAPP_NAME="Twitch"
            WEBAPP_URL="https://www.twitch.tv"
            WEBAPP_ICON="twitch"
            WEBAPP_BROWSER="brave"
            ;;
        spotify)
            WEBAPP_NAME="Spotify"
            WEBAPP_URL="https://open.spotify.com"
            WEBAPP_ICON="spotify"
            WEBAPP_BROWSER="brave"
            ;;
        discord)
            WEBAPP_NAME="Discord"
            WEBAPP_URL="https://discord.com/app"
            WEBAPP_ICON="discord"
            WEBAPP_BROWSER="brave"
            ;;
        gmail)
            WEBAPP_NAME="Gmail"
            WEBAPP_URL="https://mail.google.com"
            WEBAPP_ICON="mail"
            WEBAPP_BROWSER="brave"
            ;;
        github)
            WEBAPP_NAME="GitHub"
            WEBAPP_URL="https://github.com/Crowdrocker"
            WEBAPP_ICON="github"
            WEBAPP_BROWSER="brave"
            ;;
        calendar)
            WEBAPP_NAME="Calendar"
            WEBAPP_URL="https://calendar.google.com"
            WEBAPP_ICON="calendar"
            WEBAPP_BROWSER="brave"
            ;;
        drive)
            WEBAPP_NAME="Drive"
            WEBAPP_URL="https://drive.google.com"
            WEBAPP_ICON="folder-cloud"
            WEBAPP_BROWSER="brave"
            ;;
        instagram)
            WEBAPP_NAME="Instagram"
            WEBAPP_URL="https://www.instagram.com"
            WEBAPP_ICON="instagram"
            WEBAPP_BROWSER="brave"
            ;;
        twitter|x)
            WEBAPP_NAME="X"
            WEBAPP_URL="https://x.com"
            WEBAPP_ICON="twitter"
            WEBAPP_BROWSER="brave"
            ;;
        reddit)
            WEBAPP_NAME="Reddit"
            WEBAPP_URL="https://www.reddit.com"
            WEBAPP_ICON="reddit"
            WEBAPP_BROWSER="brave"
            ;;
        netflix)
            WEBAPP_NAME="Netflix"
            WEBAPP_URL="https://www.netflix.com"
            WEBAPP_ICON="netflix"
            WEBAPP_BROWSER="brave"
            ;;
        notion)
            WEBAPP_NAME="Notion"
            WEBAPP_URL="https://www.notion.so"
            WEBAPP_ICON="notion"
            WEBAPP_BROWSER="brave"
            ;;
        chatgpt)
            WEBAPP_NAME="ChatGPT"
            WEBAPP_URL="https://chat.openai.com"
            WEBAPP_ICON="ai"
            WEBAPP_BROWSER="brave"
            ;;
        *)
            # Try to load from config file
            if load_webapp_config "$webapp_name"; then
                :  # Config loaded successfully
            else
                echo -e "${RED}Error: Unknown webapp: $webapp_name${NC}" >&2
                echo -e "${YELLOW}Available webapps: youtube, twitch, spotify, discord, gmail, github${NC}" >&2
                return 1
            fi
            ;;
    esac

    # Set defaults if not defined
    WEBAPP_NAME="${WEBAPP_NAME:-$webapp_name}"
    WEBAPP_ICON="${WEBAPP_ICON:-web-browser}"
    WEBAPP_BROWSER="${WEBAPP_BROWSER:-brave}"

    # Launch webapp
    echo -e "${BLUE}Launching $WEBAPP_NAME...${NC}"

    case "$WEBAPP_BROWSER" in
        brave)
            if command -v brave &> /dev/null; then
                launch_brave "$webapp_name" "$WEBAPP_URL" "$WEBAPP_ICON"
            else
                echo -e "${YELLOW}Brave not found, using Firefox${NC}"
                launch_firefox "$webapp_name" "$WEBAPP_URL"
            fi
            ;;
        firefox)
            launch_firefox "$webapp_name" "$WEBAPP_URL"
            ;;
        chromium)
            launch_chromium "$webapp_name" "$WEBAPP_URL"
            ;;
        *)
            echo -e "${RED}Unknown browser: $WEBAPP_BROWSER${NC}" >&2
            return 1
            ;;
    esac

    echo -e "${GREEN}✓ $WEBAPP_NAME launched${NC}"
}

# Function to create webapp config
create_webapp_config() {
    local webapp_name="$1"
    local webapp_url="$2"
    local webapp_icon="${3:-web-browser}"
    local webapp_browser="${4:-brave}"

    local config_file="$WEBAPPS_DIR/$webapp_name.webapp"

    cat > "$config_file" << EOF
# Webapp configuration for $webapp_name
# Created: $(date)

WEBAPP_NAME="$webapp_name"
WEBAPP_URL="$webapp_url"
WEBAPP_ICON="$webapp_icon"
WEBAPP_BROWSER="$webapp_browser"
EOF

    echo -e "${GREEN}✓ Created webapp config: $config_file${NC}"
}

# Function to list available webapps
list_webapps() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}   Available Webapps${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

    echo -e "${YELLOW}Built-in:${NC}"
    echo -e "  • youtube     - YouTube"
    echo -e "  • twitch      - Twitch streaming"
    echo -e "  • spotify     - Spotify music"
    echo -e "  • discord     - Discord chat"
    echo -e "  • gmail       - Gmail"
    echo -e "  • github      - GitHub"
    echo -e "  • calendar    - Google Calendar"
    echo -e "  • drive       - Google Drive"
    echo -e "  • instagram   - Instagram"
    echo -e "  • twitter/x   - X (Twitter)"
    echo -e "  • reddit      - Reddit"
    echo -e "  • netflix     - Netflix"
    echo -e "  • notion      - Notion"
    echo -e "  • chatgpt     - ChatGPT"

    if [[ -d "$WEBAPPS_DIR" ]] && [[ -n "$(ls -A "$WEBAPPS_DIR"/*.webapp 2>/dev/null)" ]]; then
        echo -e "\n${YELLOW}Custom:${NC}"
        for config in "$WEBAPPS_DIR"/*.webapp; do
            local name=$(basename "$config" .webapp)
            echo -e "  • $name"
        done
    fi

    echo -e "\n${BLUE}═══════════════════════════════════════${NC}\n"
}

# Function to show help
show_help() {
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════════${NC}
${BLUE}          WehttamSnaps Webapp Launcher${NC}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

${YELLOW}Usage:${NC} $0 [webapp-name] [options]

${YELLOW}Examples:${NC}
  $0 youtube              Launch YouTube webapp
  $0 twitch               Launch Twitch webapp
  $0 spotify              Launch Spotify webapp
  $0 discord              Launch Discord webapp

${YELLOW}Commands:${NC}
  list                    List all available webapps
  create NAME URL         Create custom webapp config
  help                    Show this help message

${YELLOW}Create Custom Webapp:${NC}
  $0 create myweb https://example.com icon-name brave

${YELLOW}Configuration:${NC}
  Webapp configs: $WEBAPPS_DIR
  Browser cache:  $CACHE_DIR

${YELLOW}Keybindings (Niri):${NC}
  Mod + W, Y              Launch YouTube
  Mod + W, T              Launch Twitch
  Mod + W, S              Launch Spotify
  Mod + W, D              Launch Discord
  Mod + W, M              Launch Gmail
  Mod + W, G              Launch GitHub

${YELLOW}Window Rules:${NC}
  Webapps open in dedicated windows with proper workspace assignment.
  Configure in ~/.config/niri/conf.d/20-rules.kdl

${BLUE}═══════════════════════════════════════════════════════════════${NC}
EOF
}

# Main logic
main() {
    local command="${1:-help}"

    case "$command" in
        list|ls)
            list_webapps
            ;;
        create)
            if [[ $# -lt 3 ]]; then
                echo -e "${RED}Error: Missing arguments${NC}" >&2
                echo "Usage: $0 create NAME URL [ICON] [BROWSER]"
                exit 1
            fi
            create_webapp_config "$2" "$3" "${4:-web-browser}" "${5:-brave}"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            launch_webapp "$command"
            ;;
    esac
}

# Run main function
main "$@"
