#!/bin/bash
# OBS Screen Capture Setup for Niri Wayland
# Enables PipeWire screen capture and audio routing

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CACHE_DIR="$HOME/.cache/wehttamsnaps"
CONFIG_DIR="$HOME/.config/obs-studio"

echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   OBS Screen Capture Setup for Niri Wayland   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}\n"

# Check dependencies
check_dependencies() {
    echo -e "${BLUE}→ Checking dependencies...${NC}"
    
    local missing=()
    local optional=()
    
    # Required
    command -v obs &>/dev/null || missing+=("obs-studio")
    command -v pipewire &>/dev/null || missing+=("pipewire")
    command -v pw-cli &>/dev/null || missing+=("pipewire")
    
    # Optional but recommended
    command -v qpwgraph &>/dev/null || optional+=("qpwgraph")
    command -v helvum &>/dev/null || optional+=("helvum")
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}✗ Missing required packages: ${missing[*]}${NC}"
        echo -e "${YELLOW}Install with: paru -S ${missing[*]}${NC}"
        return 1
    fi
    
    if [ ${#optional[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠ Optional packages not found: ${optional[*]}${NC}"
        echo -e "${YELLOW}Install for audio routing GUI: paru -S ${optional[*]}${NC}"
    fi
    
    echo -e "${GREEN}✓ All required dependencies installed${NC}\n"
}

# Check for xdg-desktop-portal
check_portal() {
    echo -e "${BLUE}→ Checking XDG Desktop Portal...${NC}"
    
    if ! command -v /usr/lib/xdg-desktop-portal &>/dev/null; then
        echo -e "${RED}✗ xdg-desktop-portal not found${NC}"
        echo -e "${YELLOW}Install with: paru -S xdg-desktop-portal${NC}"
        return 1
    fi
    
    # Check for Wayland portal backend
    if [ ! -f /usr/share/xdg-desktop-portal/portals/wlr.portal ] && 
       [ ! -f /usr/share/xdg-desktop-portal/portals/gtk.portal ]; then
        echo -e "${YELLOW}⚠ No Wayland portal backend found${NC}"
        echo -e "${YELLOW}Install one: paru -S xdg-desktop-portal-wlr${NC}"
        echo -e "${YELLOW}       or: paru -S xdg-desktop-portal-gtk${NC}"
    fi
    
    echo -e "${GREEN}✓ XDG Desktop Portal configured${NC}\n"
}

# Create OBS scene collection with proper sources
create_obs_scene() {
    echo -e "${BLUE}→ Creating OBS scene collection...${NC}"
    
    mkdir -p "$CONFIG_DIR/basic/scenes"
    
    local scene_file="$CONFIG_DIR/basic/scenes/WehttamSnaps.json"
    
    cat > "$scene_file" <<'EOF'
{
    "current_scene": "Gaming",
    "current_program_scene": "Gaming",
    "scene_order": [
        {
            "name": "Gaming"
        },
        {
            "name": "Desktop"
        },
        {
            "name": "Camera + Game"
        }
    ],
    "sources": [
        {
            "id": "pipewire-desktop-capture-source",
            "name": "Screen Capture",
            "settings": {
                "restore_token": ""
            },
            "versioned_id": "pipewire-desktop-capture-source",
            "enabled": true
        },
        {
            "id": "pipewire-audio-capture",
            "name": "Desktop Audio",
            "settings": {
                "target": ""
            },
            "versioned_id": "pipewire-audio-capture",
            "enabled": true
        },
        {
            "id": "pipewire-audio-capture",
            "name": "Game Audio",
            "settings": {
                "target": ""
            },
            "versioned_id": "pipewire-audio-capture",
            "enabled": true
        },
        {
            "id": "pipewire-audio-capture",
            "name": "Microphone",
            "settings": {
                "target": ""
            },
            "versioned_id": "pipewire-audio-capture",
            "enabled": true
        }
    ],
    "scenes": [
        {
            "name": "Gaming",
            "sources": [
                {
                    "name": "Screen Capture",
                    "enabled": true
                },
                {
                    "name": "Game Audio",
                    "enabled": true
                },
                {
                    "name": "Microphone",
                    "enabled": true
                }
            ]
        },
        {
            "name": "Desktop",
            "sources": [
                {
                    "name": "Screen Capture",
                    "enabled": true
                },
                {
                    "name": "Desktop Audio",
                    "enabled": true
                },
                {
                    "name": "Microphone",
                    "enabled": true
                }
            ]
        }
    ]
}
EOF
    
    echo -e "${GREEN}✓ OBS scene collection created${NC}\n"
}

# Create PipeWire virtual sinks for audio routing
setup_audio_routing() {
    echo -e "${BLUE}→ Setting up PipeWire audio routing...${NC}"
    
    local pipewire_conf="$HOME/.config/pipewire/pipewire.conf.d"
    mkdir -p "$pipewire_conf"
    
    cat > "$pipewire_conf/99-wehttamsnaps-sinks.conf" <<'EOF'
# WehttamSnaps Virtual Audio Sinks
# Creates separate audio channels for OBS routing

context.modules = [
    {   name = libpipewire-module-loopback
        args = {
            node.description = "Game Audio (OBS)"
            capture.props = {
                node.name = "game_audio_sink"
                media.class = "Audio/Sink"
                audio.position = [ FL FR ]
            }
            playback.props = {
                node.name = "game_audio_source"
                media.class = "Audio/Source"
                audio.position = [ FL FR ]
                stream.dont-remix = true
                node.passive = true
            }
        }
    }
    {   name = libpipewire-module-loopback
        args = {
            node.description = "Browser Audio (OBS)"
            capture.props = {
                node.name = "browser_audio_sink"
                media.class = "Audio/Sink"
                audio.position = [ FL FR ]
            }
            playback.props = {
                node.name = "browser_audio_source"
                media.class = "Audio/Source"
                audio.position = [ FL FR ]
                stream.dont-remix = true
                node.passive = true
            }
        }
    }
    {   name = libpipewire-module-loopback
        args = {
            node.description = "Discord Audio (OBS)"
            capture.props = {
                node.name = "discord_audio_sink"
                media.class = "Audio/Sink"
                audio.position = [ FL FR ]
            }
            playback.props = {
                node.name = "discord_audio_source"
                media.class = "Audio/Source"
                audio.position = [ FL FR ]
                stream.dont-remix = true
                node.passive = true
            }
        }
    }
]
EOF
    
    echo -e "${GREEN}✓ Audio routing configured${NC}"
    echo -e "${YELLOW}  Restart PipeWire: systemctl --user restart pipewire${NC}\n"
}

# Create OBS startup script
create_obs_launcher() {
    echo -e "${BLUE}→ Creating OBS launcher script...${NC}"
    
    local script_dir="$HOME/.config/wehttamsnaps/scripts"
    mkdir -p "$script_dir"
    
    cat > "$script_dir/obs-launcher.sh" <<'EOF'
#!/bin/bash
# OBS Launcher with proper environment for Niri

# Set environment for Wayland
export QT_QPA_PLATFORM=wayland
export MOZ_ENABLE_WAYLAND=1

# Launch OBS
if command -v flatpak &>/dev/null && flatpak list | grep -q "com.obsproject.Studio"; then
    flatpak run com.obsproject.Studio "$@"
else
    obs "$@"
fi
EOF
    
    chmod +x "$script_dir/obs-launcher.sh"
    
    echo -e "${GREEN}✓ OBS launcher created${NC}\n"
}

# Create audio routing guide
create_audio_guide() {
    echo -e "${BLUE}→ Creating audio routing guide...${NC}"
    
    local docs_dir="$HOME/.config/wehttamsnaps/docs"
    mkdir -p "$docs_dir"
    
    cat > "$docs_dir/OBS-AUDIO-ROUTING.md" <<'EOF'
# OBS Audio Routing Guide for WehttamSnaps

## Virtual Sinks Setup

After running the setup script, you'll have these virtual sinks:

1. **Game Audio (OBS)** - Route game audio here
2. **Browser Audio (OBS)** - Route Firefox/Brave audio here  
3. **Discord Audio (OBS)** - Route Discord audio here

## How to Route Audio

### Method 1: Using qpwgraph (Visual)

1. Launch qpwgraph: `qpwgraph`
2. Find your application in the left column
3. Drag connections to the virtual sinks
4. Save the graph: File → Save As → wehttamsnaps-obs.qpwgraph

**Example Connections:**
```
Steam/Game → Game Audio Sink → Your Headphones
             → Game Audio Source → OBS

Firefox → Browser Audio Sink → Your Headphones  
         → Browser Audio Source → OBS

Discord → Discord Audio Sink → Your Headphones
         → Discord Audio Source → OBS
```

### Method 2: Using pavucontrol

1. Launch pavucontrol: `pavucontrol`
2. Go to "Playback" tab
3. For each application, change output to desired virtual sink
4. Go to "Recording" tab
5. Set OBS audio sources to capture from virtual sinks

### Method 3: Using pw-cli (Command Line)

```bash
# List all nodes
pw-cli ls Node

# Link application to virtual sink
pw-cli create-link <app-node-id> <sink-node-id>
```

## OBS Setup

### Adding Screen Capture

1. Open OBS
2. Sources → Add → Screen Capture (PipeWire)
3. Click "OK" - a portal dialog will appear
4. Select your screen/window
5. Click "Share"

### Adding Audio Sources

1. Sources → Add → Audio Output Capture (PipeWire)
2. Name it (e.g., "Game Audio")
3. In properties, select "Game Audio (OBS)" from dropdown
4. Repeat for Browser, Discord, Microphone

### Recommended OBS Settings

**Output:**
- Encoder: FFMPEG VAAPI (AMD GPU)
- Rate Control: VBR
- Bitrate: 6000 Kbps (for 1080p60)

**Video:**
- Base Resolution: 1920x1080
- Output Resolution: 1920x1080
- FPS: 60

**Audio:**
- Sample Rate: 48000 Hz
- Channels: Stereo

## Troubleshooting

### No Screen Capture Option

```bash
# Install portal
paru -S xdg-desktop-portal-wlr

# Restart portal
systemctl --user restart xdg-desktop-portal
```

### Audio Not Showing in OBS

```bash
# Restart PipeWire
systemctl --user restart pipewire pipewire-pulse

# Check audio devices
pw-cli ls Node | grep -i audio
```

### Can't Select Virtual Sinks

```bash
# Reload PipeWire config
systemctl --user restart pipewire
```

## Keybinds

Add to your Niri config:

```kdl
// OBS Controls
Mod+Shift+R { spawn "obs-cmd" "recording" "toggle"; }
```

## Tips

1. Save qpwgraph layouts for different scenarios
2. Create OBS profiles for Gaming vs Desktop streaming
3. Use Game Audio sink only when gaming for cleaner audio
4. Mute unused audio sources in OBS mixer
5. Test audio levels before going live!

---

**WehttamSnaps Pro Tip:** Set up separate scenes for:
- Gaming (Game Audio + Mic)
- Desktop (All Audio + Mic) 
- Camera + Game (Overlay camera on gameplay)
EOF
    
    echo -e "${GREEN}✓ Audio routing guide created${NC}"
    echo -e "${YELLOW}  Read at: $docs_dir/OBS-AUDIO-ROUTING.md${NC}\n"
}

# Test screen capture
test_screen_capture() {
    echo -e "${BLUE}→ Testing screen capture capability...${NC}"
    
    # Check if portal is running
    if ! pgrep -x xdg-desktop-portal &>/dev/null; then
        echo -e "${YELLOW}⚠ Starting xdg-desktop-portal...${NC}"
        systemctl --user start xdg-desktop-portal
        sleep 2
    fi
    
    # Try to get screen cast info
    if command -v busctl &>/dev/null; then
        if busctl --user call org.freedesktop.portal.Desktop \
           /org/freedesktop/portal/desktop \
           org.freedesktop.portal.ScreenCast version 2>/dev/null; then
            echo -e "${GREEN}✓ Screen capture portal is working${NC}\n"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}⚠ Could not verify screen capture - launch OBS to test${NC}\n"
}

# Display help
show_usage() {
    cat <<EOF
${CYAN}╔════════════════════════════════════════════════╗${NC}
${CYAN}║        OBS Screen Capture Setup - Niri        ║${NC}
${CYAN}╚════════════════════════════════════════════════╝${NC}

${YELLOW}Usage:${NC} $0 [command]

${YELLOW}Commands:${NC}
  setup              Full setup (dependencies + audio + scenes)
  check              Check dependencies only
  audio              Setup audio routing only
  scene              Create OBS scene collection
  test               Test screen capture
  guide              Show audio routing guide
  qpwgraph           Launch audio routing GUI
  restart-audio      Restart PipeWire audio system
  
${YELLOW}Quick Start:${NC}
  1. Run: $0 setup
  2. Restart PipeWire: systemctl --user restart pipewire
  3. Launch OBS: Mod + O
  4. Add Source → Screen Capture (PipeWire)
  5. Select screen when portal appears
  6. Add audio sources from virtual sinks

${YELLOW}Audio Routing:${NC}
  Use qpwgraph to visually route audio:
  - Game → Game Audio Sink → Headphones + OBS
  - Browser → Browser Audio Sink → Headphones + OBS
  - Discord → Discord Audio Sink → Headphones + OBS

${YELLOW}Troubleshooting:${NC}
  - No screen capture: paru -S xdg-desktop-portal-wlr
  - No audio: $0 restart-audio
  - Check logs: journalctl --user -u pipewire -f

EOF
}

# Main logic
case "${1:-setup}" in
    setup)
        check_dependencies || exit 1
        check_portal || exit 1
        setup_audio_routing
        create_obs_launcher
        create_obs_scene
        create_audio_guide
        test_screen_capture
        
        echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║            Setup Complete! ✓                   ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}\n"
        
        echo -e "${YELLOW}Next Steps:${NC}"
        echo -e "  1. Restart PipeWire: ${CYAN}systemctl --user restart pipewire${NC}"
        echo -e "  2. Launch OBS: ${CYAN}Mod + O${NC}"
        echo -e "  3. Add 'Screen Capture (PipeWire)' source"
        echo -e "  4. Setup audio routing: ${CYAN}$0 qpwgraph${NC}"
        echo -e "  5. Read guide: ${CYAN}cat ~/.config/wehttamsnaps/docs/OBS-AUDIO-ROUTING.md${NC}\n"
        ;;
    
    check)
        check_dependencies
        check_portal
        ;;
    
    audio)
        setup_audio_routing
        echo -e "${YELLOW}Restart PipeWire: systemctl --user restart pipewire${NC}"
        ;;
    
    scene)
        create_obs_scene
        ;;
    
    test)
        test_screen_capture
        ;;
    
    guide)
        if [ -f "$HOME/.config/wehttamsnaps/docs/OBS-AUDIO-ROUTING.md" ]; then
            cat "$HOME/.config/wehttamsnaps/docs/OBS-AUDIO-ROUTING.md" | less
        else
            create_audio_guide
            cat "$HOME/.config/wehttamsnaps/docs/OBS-AUDIO-ROUTING.md" | less
        fi
        ;;
    
    qpwgraph)
        if command -v qpwgraph &>/dev/null; then
            qpwgraph &
        else
            echo -e "${RED}qpwgraph not installed${NC}"
            echo -e "${YELLOW}Install with: paru -S qpwgraph${NC}"
        fi
        ;;
    
    restart-audio)
        echo -e "${BLUE}→ Restarting PipeWire...${NC}"
        systemctl --user restart pipewire pipewire-pulse wireplumber
        sleep 2
        echo -e "${GREEN}✓ PipeWire restarted${NC}"
        ;;
    
    help|--help|-h)
        show_usage
        ;;
    
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac
