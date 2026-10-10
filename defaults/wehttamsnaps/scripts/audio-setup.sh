#!/usr/bin/env bash
# === AUDIO ROUTING SETUP ===
# WehttamSnaps Niri Setup
# GitHub: https://github.com/Crowdrocker
#
# Creates VoiceMeeter-like audio routing with PipeWire
# Separate channels for: Game, Browser, Discord, Spotify

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
WIREPLUMBER_CONFIG_DIR="$HOME/.config/wireplumber/main.lua.d"
QPWGRAPH_CONFIG_DIR="$HOME/.config/rncbc.org"
PIPEWIRE_CONFIG_DIR="$HOME/.config/pipewire"

# Virtual sink names
SINK_GAME="GameAudio"
SINK_BROWSER="BrowserAudio"
SINK_DISCORD="DiscordAudio"
SINK_SPOTIFY="SpotifyAudio"
SINK_MIC="MicrophoneProcessed"

# Function to print section header
print_section() {
    echo -e "\n${BLUE}━━━ $1 ━━━${NC}\n"
}

# Function to check if PipeWire is running
check_pipewire() {
    print_section "Checking PipeWire"

    if ! systemctl --user is-active --quiet pipewire.service; then
        echo -e "${RED}✗ PipeWire is not running${NC}"
        echo -e "${YELLOW}Starting PipeWire services...${NC}"
        systemctl --user start pipewire.service pipewire-pulse.service wireplumber.service
        sleep 2
    fi

    if systemctl --user is-active --quiet pipewire.service; then
        echo -e "${GREEN}✓ PipeWire is running${NC}"
    else
        echo -e "${RED}✗ Failed to start PipeWire${NC}"
        exit 1
    fi
}

# Function to create virtual sinks
create_virtual_sinks() {
    print_section "Creating Virtual Audio Sinks"

    echo -e "${CYAN}Creating 4 virtual sinks for audio routing...${NC}\n"

    # Game Audio sink
    pw-cli create-node adapter \
        "{ factory.name=support.null-audio-sink \
           node.name=\"$SINK_GAME\" \
           media.class=Audio/Sink \
           object.linger=true \
           audio.position=[FL,FR] }" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} $SINK_GAME"

    # Browser Audio sink
    pw-cli create-node adapter \
        "{ factory.name=support.null-audio-sink \
           node.name=\"$SINK_BROWSER\" \
           media.class=Audio/Sink \
           object.linger=true \
           audio.position=[FL,FR] }" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} $SINK_BROWSER"

    # Discord Audio sink
    pw-cli create-node adapter \
        "{ factory.name=support.null-audio-sink \
           node.name=\"$SINK_DISCORD\" \
           media.class=Audio/Sink \
           object.linger=true \
           audio.position=[FL,FR] }" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} $SINK_DISCORD"

    # Spotify Audio sink
    pw-cli create-node adapter \
        "{ factory.name=support.null-audio-sink \
           node.name=\"$SINK_SPOTIFY\" \
           media.class=Audio/Sink \
           object.linger=true \
           audio.position=[FL,FR] }" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} $SINK_SPOTIFY"

    echo -e "\n${GREEN}✓ Virtual sinks created${NC}"
}

# Function to create persistent sink configuration
create_persistent_sinks() {
    print_section "Creating Persistent Sink Configuration"

    mkdir -p "$PIPEWIRE_CONFIG_DIR/pipewire.conf.d"

    cat > "$PIPEWIRE_CONFIG_DIR/pipewire.conf.d/wehttamsnaps-sinks.conf" << 'EOF'
# WehttamSnaps Virtual Audio Sinks
# GitHub: https://github.com/Crowdrocker

context.modules = [
    {   name = libpipewire-module-loopback
        args = {
            node.name = "GameAudio"
            node.description = "Game Audio"
            audio.position = [ FL FR ]
            capture.props = {
                media.class = "Audio/Sink"
                node.name = "GameAudio"
            }
            playback.props = {
                node.name = "GameAudio.output"
                node.passive = true
            }
        }
    }
    {   name = libpipewire-module-loopback
        args = {
            node.name = "BrowserAudio"
            node.description = "Browser Audio"
            audio.position = [ FL FR ]
            capture.props = {
                media.class = "Audio/Sink"
                node.name = "BrowserAudio"
            }
            playback.props = {
                node.name = "BrowserAudio.output"
                node.passive = true
            }
        }
    }
    {   name = libpipewire-module-loopback
        args = {
            node.name = "DiscordAudio"
            node.description = "Discord Audio"
            audio.position = [ FL FR ]
            capture.props = {
                media.class = "Audio/Sink"
                node.name = "DiscordAudio"
            }
            playback.props = {
                node.name = "DiscordAudio.output"
                node.passive = true
            }
        }
    }
    {   name = libpipewire-module-loopback
        args = {
            node.name = "SpotifyAudio"
            node.description = "Spotify Audio"
            audio.position = [ FL FR ]
            capture.props = {
                media.class = "Audio/Sink"
                node.name = "SpotifyAudio"
            }
            playback.props = {
                node.name = "SpotifyAudio.output"
                node.passive = true
            }
        }
    }
]
EOF

    echo -e "${GREEN}✓ Persistent configuration created${NC}"
    echo -e "   ${CYAN}$PIPEWIRE_CONFIG_DIR/pipewire.conf.d/wehttamsnaps-sinks.conf${NC}"
}

# Function to create application routing rules
create_routing_rules() {
    print_section "Creating Application Routing Rules"

    mkdir -p "$WIREPLUMBER_CONFIG_DIR"

    cat > "$WIREPLUMBER_CONFIG_DIR/51-wehttamsnaps-routing.lua" << 'EOF'
-- WehttamSnaps Audio Routing Rules
-- GitHub: https://github.com/Crowdrocker
-- Routes specific applications to virtual sinks

rule = {
  matches = {
    -- Steam games to GameAudio
    {
      { "application.name", "matches", "steam_app_*" },
    },
    -- All games to GameAudio
    {
      { "application.name", "matches", "*game*" },
    },
  },
  apply_properties = {
    ["node.target"] = "GameAudio",
  },
}

table.insert(alsa_monitor.rules, rule)

rule = {
  matches = {
    -- Browsers to BrowserAudio
    {
      { "application.name", "matches", "*brave*" },
    },
    {
      { "application.name", "matches", "*firefox*" },
    },
    {
      { "application.name", "matches", "*chrome*" },
    },
    {
      { "application.name", "matches", "*chromium*" },
    },
  },
  apply_properties = {
    ["node.target"] = "BrowserAudio",
  },
}

table.insert(alsa_monitor.rules, rule)

rule = {
  matches = {
    -- Discord to DiscordAudio
    {
      { "application.name", "matches", "*discord*" },
    },
    {
      { "application.name", "matches", "*webcord*" },
    },
    {
      { "application.name", "matches", "*vesktop*" },
    },
  },
  apply_properties = {
    ["node.target"] = "DiscordAudio",
  },
}

table.insert(alsa_monitor.rules, rule)

rule = {
  matches = {
    -- Spotify to SpotifyAudio
    {
      { "application.name", "matches", "*spotify*" },
    },
  },
  apply_properties = {
    ["node.target"] = "SpotifyAudio",
  },
}

table.insert(alsa_monitor.rules, rule)
EOF

    echo -e "${GREEN}✓ Routing rules created${NC}"
    echo -e "   ${CYAN}$WIREPLUMBER_CONFIG_DIR/51-wehttamsnaps-routing.lua${NC}"
}

# Function to restart audio services
restart_audio_services() {
    print_section "Restarting Audio Services"

    echo -e "${YELLOW}Restarting PipeWire services...${NC}"
    systemctl --user restart pipewire.service
    systemctl --user restart pipewire-pulse.service
    systemctl --user restart wireplumber.service

    sleep 3

    if systemctl --user is-active --quiet pipewire.service; then
        echo -e "${GREEN}✓ Audio services restarted successfully${NC}"
    else
        echo -e "${RED}✗ Failed to restart audio services${NC}"
        exit 1
    fi
}

# Function to test audio setup
test_audio_setup() {
    print_section "Testing Audio Setup"

    echo -e "${CYAN}Checking for virtual sinks...${NC}\n"

    local sinks_found=0

    for sink in "$SINK_GAME" "$SINK_BROWSER" "$SINK_DISCORD" "$SINK_SPOTIFY"; do
        if pactl list sinks | grep -q "$sink"; then
            echo -e "${GREEN}✓${NC} $sink"
            ((sinks_found++))
        else
            echo -e "${RED}✗${NC} $sink ${YELLOW}(not found)${NC}"
        fi
    done

    echo ""

    if [[ $sinks_found -eq 4 ]]; then
        echo -e "${GREEN}✓ All virtual sinks are active${NC}"
    else
        echo -e "${YELLOW}⚠ Only $sinks_found/4 virtual sinks found${NC}"
        echo -e "${YELLOW}You may need to manually create sinks or restart audio services${NC}"
    fi
}

# Function to show usage instructions
show_usage_instructions() {
    print_section "Usage Instructions"

    cat << EOF
${CYAN}VoiceMeeter-like Audio Routing is now configured!${NC}

${YELLOW}Virtual Sinks Created:${NC}
  • ${GREEN}GameAudio${NC}      - Route Steam/game audio here
  • ${GREEN}BrowserAudio${NC}   - Brave, Firefox, Chrome audio
  • ${GREEN}DiscordAudio${NC}   - Discord/WebCord audio
  • ${GREEN}SpotifyAudio${NC}   - Spotify audio

${YELLOW}Quick Start:${NC}

1. ${CYAN}Open qpwgraph${NC} (visual audio router):
   ${GREEN}Mod + A${NC} or ${GREEN}qpwgraph${NC} in terminal

2. ${CYAN}Open pavucontrol${NC} (volume mixer):
   ${GREEN}Mod + Ctrl + A${NC} or ${GREEN}pavucontrol${NC} in terminal

3. ${CYAN}Route Applications:${NC}
   In pavucontrol "Playback" tab, select output sink for each app:
   - Steam games    → GameAudio
   - Brave/Firefox  → BrowserAudio
   - Discord        → DiscordAudio
   - Spotify        → SpotifyAudio

4. ${CYAN}Route to OBS (for streaming):${NC}
   In qpwgraph:
   - Connect GameAudio.output → OBS Audio Input
   - Connect BrowserAudio.output → OBS Audio Input
   - Connect DiscordAudio.output → OBS Audio Input
   - Connect all outputs → Your headphones/speakers

${YELLOW}For Streaming Setup:${NC}
1. Open OBS Studio
2. Add Audio Input Capture sources for each virtual sink
3. Control individual volumes in OBS mixer
4. Route all to headphones for monitoring

${YELLOW}Tips:${NC}
  • Automatic routing for Steam games, browsers, Discord
  • Use pavucontrol to manually assign apps to sinks
  • Save qpwgraph layout: File → Save As
  • Sinks persist across reboots

${YELLOW}Keybinds:${NC}
  • ${GREEN}Mod + A${NC}         - Open qpwgraph
  • ${GREEN}Mod + Ctrl + A${NC}  - Open pavucontrol

${CYAN}See ~/.config/wehttamsnaps/docs/AUDIO-ROUTING.md for detailed guide${NC}
EOF
}

# Function to open GUI tools
open_gui_tools() {
    print_section "Opening Audio Tools"

    read -p "Open qpwgraph and pavucontrol now? [Y/n] " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${CYAN}Launching qpwgraph...${NC}"
        qpwgraph > /dev/null 2>&1 &

        sleep 2

        echo -e "${CYAN}Launching pavucontrol...${NC}"
        pavucontrol > /dev/null 2>&1 &

        echo -e "${GREEN}✓ GUI tools launched${NC}"
    fi
}

# Function to show help
show_help() {
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════════${NC}
${BLUE}          WehttamSnaps Audio Routing Setup${NC}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

${YELLOW}Usage:${NC} $0 [action]

${YELLOW}Actions:${NC}
  setup             Full audio routing setup (default)
  create-sinks      Create virtual sinks only
  test              Test current audio setup
  restart           Restart audio services
  clean             Remove WehttamSnaps audio configuration
  help              Show this help message

${YELLOW}What This Script Does:${NC}
  ✓ Creates 4 virtual audio sinks (Game, Browser, Discord, Spotify)
  ✓ Configures automatic routing rules
  ✓ Makes configuration persistent across reboots
  ✓ Enables VoiceMeeter-like audio control

${YELLOW}Requirements:${NC}
  • PipeWire (audio server)
  • WirePlumber (session manager)
  • qpwgraph (visual routing tool)
  • pavucontrol (volume control)

${YELLOW}Examples:${NC}
  $0                Run full setup
  $0 test           Test if sinks are working
  $0 restart        Restart audio services

${BLUE}═══════════════════════════════════════════════════════════════${NC}
EOF
}

# Function to clean audio configuration
clean_audio_config() {
    print_section "Cleaning Audio Configuration"

    read -p "Remove WehttamSnaps audio configuration? [y/N] " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$PIPEWIRE_CONFIG_DIR/pipewire.conf.d/wehttamsnaps-sinks.conf"
        rm -f "$WIREPLUMBER_CONFIG_DIR/51-wehttamsnaps-routing.lua"

        echo -e "${GREEN}✓ Configuration removed${NC}"
        echo -e "${YELLOW}Restart audio services to apply changes${NC}"
    else
        echo -e "${YELLOW}Cancelled${NC}"
    fi
}

# Main function
main() {
    local action="${1:-setup}"

    echo -e "${BLUE}"
    cat << "EOF"
╦ ╦┌─┐┬ ┬┌┬┐┌┬┐┌─┐┌┬┐╔═╗┌┐┌┌─┐┌─┐┌─┐
║║║├┤ ├─┤ │  │ ├─┤│││╚═╗│││├─┤├─┘└─┐
╚╩╝└─┘┴ ┴ ┴  ┴ ┴ ┴┴ ┴╚═╝┘└┘┴ ┴┴  └─┘
   Audio Routing Setup
EOF
    echo -e "${NC}"

    case "$action" in
        setup)
            check_pipewire
            create_persistent_sinks
            create_routing_rules
            restart_audio_services
            test_audio_setup
            show_usage_instructions
            open_gui_tools
            ;;
        create-sinks)
            check_pipewire
            create_virtual_sinks
            ;;
        test)
            test_audio_setup
            ;;
        restart)
            restart_audio_services
            test_audio_setup
            ;;
        clean)
            clean_audio_config
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown action: $action${NC}"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
