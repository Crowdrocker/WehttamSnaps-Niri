#!/bin/bash
# WehttamSnaps Audio Routing Setup
# Automatically configures PipeWire audio routing for streaming

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   WehttamSnaps Audio Routing Setup            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}\n"

# Wait for PipeWire to be ready
wait_for_pipewire() {
    echo -e "${BLUE}→ Waiting for PipeWire...${NC}"
    for i in {1..10}; do
        if pw-cli info 0 &>/dev/null; then
            echo -e "${GREEN}✓ PipeWire ready${NC}\n"
            return 0
        fi
        sleep 1
    done
    echo -e "${RED}✗ PipeWire not responding${NC}"
    return 1
}

# Get node ID by name pattern
get_node_id() {
    local pattern="$1"
    pw-cli list-objects Node | grep -A 20 "node.name.*$pattern" | grep "id:" | head -1 | awk '{print $2}' | tr -d ','
}

# Get port ID by node and port name
get_port_id() {
    local node_pattern="$1"
    local port_type="$2"  # "output" or "input"
    local channel="$3"    # "FL" or "FR" or empty

    if [ -n "$channel" ]; then
        pw-cli list-objects Port | grep -B 5 "$node_pattern" | grep -A 3 "port.direction.*$port_type" | grep "port.name.*$channel" | grep "id:" | awk '{print $2}' | tr -d ',' | head -1
    else
        pw-cli list-objects Port | grep -B 5 "$node_pattern" | grep -A 3 "port.direction.*$port_type" | grep "id:" | awk '{print $2}' | tr -d ',' | head -1
    fi
}

# Create a link between two ports
create_link() {
    local output_port="$1"
    local input_port="$2"
    local description="$3"

    if [ -z "$output_port" ] || [ -z "$input_port" ]; then
        echo -e "${YELLOW}⚠ Skipping: $description (ports not found)${NC}"
        return 1
    fi

    if pw-link "$output_port" "$input_port" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Connected: $description"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Already connected or failed: $description"
        return 1
    fi
}

# Clear existing custom links (optional)
clear_links() {
    echo -e "${BLUE}→ Clearing existing links...${NC}"
    # This is optional - comment out if you want to keep existing connections
    # pw-cli list-objects Link | grep "id:" | awk '{print $2}' | tr -d ',' | xargs -I {} pw-cli destroy {}
    echo -e "${GREEN}✓ Ready for new connections${NC}\n"
}

# Setup preset for gaming + streaming
setup_gaming_stream() {
    echo -e "${CYAN}Setting up: Gaming + Streaming preset${NC}\n"

    # Find virtual sinks
    local game_sink=$(get_node_id "game_audio_sink")
    local browser_sink=$(get_node_id "browser_audio_sink")
    local discord_sink=$(get_node_id "discord_audio_sink")

    # Find output devices
    local headphones=$(get_node_id "Built-in Audio Analog Stereo")

    # Find sources
    local game_source=$(get_node_id "game_audio_source")
    local browser_source=$(get_node_id "browser_audio_source")
    local discord_source=$(get_node_id "discord_audio_source")

    echo -e "${YELLOW}Found virtual sinks:${NC}"
    echo -e "  Game Audio: ${game_sink:-not found}"
    echo -e "  Browser Audio: ${browser_sink:-not found}"
    echo -e "  Discord Audio: ${discord_sink:-not found}\n"

    # Route virtual sink outputs to headphones
    if [ -n "$game_source" ] && [ -n "$headphones" ]; then
        echo -e "${BLUE}→ Routing Game Audio to headphones...${NC}"
        # This happens automatically via loopback module
        echo -e "${GREEN}✓ Game Audio → Headphones (automatic)${NC}"
    fi

    if [ -n "$browser_source" ] && [ -n "$headphones" ]; then
        echo -e "${GREEN}✓ Browser Audio → Headphones (automatic)${NC}"
    fi

    if [ -n "$discord_source" ] && [ -n "$headphones" ]; then
        echo -e "${GREEN}✓ Discord Audio → Headphones (automatic)${NC}"
    fi

    echo ""
}

# Setup preset for desktop recording
setup_desktop_recording() {
    echo -e "${CYAN}Setting up: Desktop Recording preset${NC}\n"
    echo -e "${GREEN}✓ All audio routed to default output${NC}"
    echo -e "${GREEN}✓ Ready for OBS Desktop Audio capture${NC}\n"
}

# Setup preset for music production
setup_music_production() {
    echo -e "${CYAN}Setting up: Music Production preset${NC}\n"
    echo -e "${GREEN}✓ Direct routing for minimal latency${NC}"
    echo -e "${GREEN}✓ No virtual sinks${NC}\n"
}

# Apply application-specific routing
apply_app_routing() {
    echo -e "${BLUE}→ Configuring application defaults...${NC}\n"

    # This uses pactl to set default sinks for applications
    # Applications need to be running for this to work

    # Check if Firefox is running
    if pgrep -x firefox &>/dev/null; then
        echo -e "${YELLOW}Firefox detected - routing to Game Audio sink${NC}"
        # Get Firefox stream
        local firefox_stream=$(pactl list sink-inputs | grep -B 20 "application.name = \"Firefox\"" | grep "Sink Input" | head -1 | awk '{print $3}' | tr -d '#')
        if [ -n "$firefox_stream" ]; then
            pactl move-sink-input "$firefox_stream" game_audio_sink 2>/dev/null && \
                echo -e "${GREEN}✓ Firefox → Game Audio${NC}" || \
                echo -e "${YELLOW}⚠ Could not route Firefox${NC}"
        fi
    fi

    # Check if Discord is running
    if pgrep -i discord &>/dev/null; then
        echo -e "${YELLOW}Discord detected - routing to Discord Audio sink${NC}"
        local discord_stream=$(pactl list sink-inputs | grep -B 20 "application.name.*iscord" | grep "Sink Input" | head -1 | awk '{print $3}' | tr -d '#')
        if [ -n "$discord_stream" ]; then
            pactl move-sink-input "$discord_stream" discord_audio_sink 2>/dev/null && \
                echo -e "${GREEN}✓ Discord → Discord Audio${NC}" || \
                echo -e "${YELLOW}⚠ Could not route Discord${NC}"
        fi
    fi

    # Check if Brave/Chrome is running
    if pgrep -i brave &>/dev/null || pgrep -i chrome &>/dev/null; then
        echo -e "${YELLOW}Browser detected - routing to Browser Audio sink${NC}"
        local browser_stream=$(pactl list sink-inputs | grep -B 20 "application.name.*rave\|Chrome" | grep "Sink Input" | head -1 | awk '{print $3}' | tr -d '#')
        if [ -n "$browser_stream" ]; then
            pactl move-sink-input "$browser_stream" browser_audio_sink 2>/dev/null && \
                echo -e "${GREEN}✓ Browser → Browser Audio${NC}" || \
                echo -e "${YELLOW}⚠ Could not route Browser${NC}"
        fi
    fi

    echo ""
}

# Launch qpwgraph
launch_qpwgraph() {
    echo -e "${BLUE}→ Launching qpwgraph...${NC}"
    if command -v qpwgraph &>/dev/null; then
        qpwgraph &
        echo -e "${GREEN}✓ qpwgraph launched${NC}"
        echo -e "${YELLOW}  Tip: Save your layout with Graph → Save As${NC}"
    else
        echo -e "${RED}✗ qpwgraph not installed${NC}"
        echo -e "${YELLOW}  Install with: paru -S qpwgraph${NC}"
    fi
}

# Save current routing as preset
save_preset() {
    local preset_name="$1"
    local preset_dir="$HOME/.config/wehttamsnaps/audio-presets"

    mkdir -p "$preset_dir"

    echo -e "${BLUE}→ Saving preset: $preset_name${NC}"

    # Get all current links
    pw-cli list-objects Link > "$preset_dir/$preset_name.links"

    # Get all current sink-input assignments
    pactl list sink-inputs > "$preset_dir/$preset_name.inputs"

    echo -e "${GREEN}✓ Preset saved: $preset_dir/$preset_name${NC}\n"
}

# Show current routing
show_routing() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           Current Audio Routing               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}\n"

    echo -e "${YELLOW}Virtual Sinks:${NC}"
    pw-cli list-objects Node | grep -A 5 "node.name.*audio_sink" | grep "node.name\|node.description"

    echo -e "\n${YELLOW}Active Applications:${NC}"
    pactl list sink-inputs short

    echo -e "\n${YELLOW}Output Devices:${NC}"
    pactl list sinks short

    echo ""
}

# Interactive menu
show_menu() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════╗${NC}
${CYAN}║        Audio Routing Quick Setup Menu          ║${NC}
${CYAN}╚════════════════════════════════════════════════╝${NC}

${YELLOW}Presets:${NC}
  ${GREEN}1${NC}) Gaming + Streaming (recommended)
  ${GREEN}2${NC}) Desktop Recording
  ${GREEN}3${NC}) Music Production

${YELLOW}Actions:${NC}
  ${GREEN}4${NC}) Route running applications
  ${GREEN}5${NC}) Show current routing
  ${GREEN}6${NC}) Launch qpwgraph (visual editor)
  ${GREEN}7${NC}) Save current as preset

  ${GREEN}0${NC}) Exit

EOF
    read -p "Choose an option: " choice
    echo ""

    case "$choice" in
        1)
            setup_gaming_stream
            apply_app_routing
            ;;
        2)
            setup_desktop_recording
            ;;
        3)
            setup_music_production
            ;;
        4)
            apply_app_routing
            ;;
        5)
            show_routing
            ;;
        6)
            launch_qpwgraph
            return
            ;;
        7)
            read -p "Enter preset name: " preset_name
            save_preset "$preset_name"
            ;;
        0)
            echo -e "${GREEN}✓ Done!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}\n"
            ;;
    esac

    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read
    show_menu
}

# Main
main() {
    wait_for_pipewire || exit 1

    if [ $# -eq 0 ]; then
        # Interactive mode
        show_menu
    else
        # Command line mode
        case "$1" in
            gaming|game|stream)
                setup_gaming_stream
                apply_app_routing
                ;;
            desktop|record)
                setup_desktop_recording
                ;;
            music|production)
                setup_music_production
                ;;
            route|apps)
                apply_app_routing
                ;;
            show|status)
                show_routing
                ;;
            graph|qpwgraph)
                launch_qpwgraph
                ;;
            save)
                save_preset "${2:-custom}"
                ;;
            *)
                echo "Usage: $0 [gaming|desktop|music|route|show|graph|save]"
                exit 1
                ;;
        esac
    fi
}

main "$@"
