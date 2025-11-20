#!/bin/bash
# ===================================================================================
# WEHTTAMSNAPS - AUDIO ROUTING SYSTEM
# PipeWire virtual sinks for streaming (Voicemeeter alternative)
# https://github.com/Crowdrocker
# ===================================================================================

# Configuration
PIPEWIRE_CONFIG_DIR="$HOME/.config/pipewire"
AUDIO_LOGS="$HOME/.config/wehttamsnaps/logs/audio-setup.log"

# Create directories
mkdir -p "$PIPEWIRE_CONFIG_DIR"
mkdir -p "$(dirname "$AUDIO_LOGS")"

# Logging function
log_audio() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$AUDIO_LOGS"
}

# Function to create virtual sinks for audio routing
create_virtual_sinks() {
    log_audio "Creating virtual audio sinks..."
    
    # Create virtual sink config for PipeWire
    cat > "$PIPEWIRE_CONFIG_DIR/sink.conf" << 'EOF'
# J.A.R.V.I.S. Audio Routing Configuration
context.properties = {
    # Default properties
}

context.modules = [
    # Module for creating virtual sinks
    {   name = libpipewire-module-loopback
        args = {
            node.description = "Game Audio"
            capture.props = {
                media.class = "Audio/Sink"
                node.name = "game_audio_sink"
                node.description = "Game Audio Sink"
            }
            playback.props = {
                node.name = "game_audio_source"
                node.description = "Game Audio Source"
            }
        }
    }
    {   name = libpipewire-module-loopback
        args = {
            node.description = "Browser Audio"
            capture.props = {
                media.class = "Audio/Sink"
                node.name = "browser_audio_sink"
                node.description = "Browser Audio Sink"
            }
            playback.props = {
                node.name = "browser_audio_source"
                node.description = "Browser Audio Source"
            }
        }
    }
    {   name = libpipewire-module-loopback
        args = {
            node.description = "Communication Audio"
            capture.props = {
                media.class = "Audio/Sink"
                node.name = "comm_audio_sink"
                node.description = "Communication Audio Sink"
            }
            playback.props = {
                node.name = "comm_audio_source"
                node.description = "Communication Audio Source"
            }
        }
    }
    {   name = libpipewire-module-loopback
        args = {
            node.description = "Music Audio"
            capture.props = {
                media.class = "Audio/Sink"
                node.name = "music_audio_sink"
                node.description = "Music Audio Sink"
            }
            playback.props = {
                node.name = "music_audio_source"
                node.description = "Music Audio Source"
            }
        }
    }
]
EOF

    log_audio "Virtual sinks configuration created"
}

# Function to create qpwgraph layout for audio routing
create_audio_routing_layout() {
    local layout_dir="$HOME/.config/qpwgraph"
    mkdir -p "$layout_dir"
    
    log_audio "Creating qpwgraph routing layout..."
    
    cat > "$layout_dir/wehttamsnaps-routing.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<graph>
    <nodes>
        <!-- System Output -->
        <node id="system_output" name="Built-in Audio" type="sink" x="800" y="200"/>
        
        <!-- Virtual Sinks -->
        <node id="game_sink" name="Game Audio Sink" type="sink" x="200" y="100"/>
        <node id="browser_sink" name="Browser Audio Sink" type="sink" x="200" y="200"/>
        <node id="comm_sink" name="Communication Audio Sink" type="sink" x="200" y="300"/>
        <node id="music_sink" name="Music Audio Sink" type="sink" x="200" y="400"/>
        
        <!-- Virtual Sources (for routing to recording/streams) -->
        <node id="game_source" name="Game Audio Source" type="source" x="500" y="100"/>
        <node id="browser_source" name="Browser Audio Source" type="source" x="500" y="200"/>
        <node id="comm_source" name="Communication Audio Source" type="source" x="500" y="300"/>
        <node id="music_source" name="Music Audio Source" type="source" x="500" y="400"/>
        
        <!-- Monitoring/Mixing -->
        <node id="stream_mix" name="Stream Mix" type="sink" x="800" y="400"/>
    </nodes>
    
    <edges>
        <!-- Route all virtual sources to system output -->
        <edge from="game_source" to="system_output"/>
        <edge from="browser_source" to="system_output"/>
        <edge from="comm_source" to="system_output"/>
        <edge from="music_source" to="system_output"/>
        
        <!-- Route to stream mix -->
        <edge from="game_source" to="stream_mix"/>
        <edge from="browser_source" to="stream_mix"/>
        <edge from="music_source" to="stream_mix"/>
    </edges>
</graph>
EOF

    log_audio "qpwgraph layout created"
}

# Function to set up application routing rules
setup_application_routing() {
    log_audio "Setting up application audio routing..."
    
    # Create pw-metadata script for automatic routing
    cat > "$HOME/.config/wehttamsnaps/scripts/set-app-routing.sh" << 'EOF'
#!/bin/bash
# Set up application-specific audio routing

app_name="$1"
case "$app_name" in
    "steam"|"gamescope")
        # Route games to Game Audio Sink
        pw-metadata -n settings 0 node.target "game_audio_sink"
        ;;
    "brave"|"firefox"|"chromium")
        # Route browsers to Browser Audio Sink
        pw-metadata -n settings 0 node.target "browser_audio_sink"
        ;;
    "discord"|"teams"|"zoom")
        # Route communication apps to Communication Audio Sink
        pw-metadata -n settings 0 node.target "comm_audio_sink"
        ;;
    "spotify"|"mpv"|"vlc")
        # Route music apps to Music Audio Sink
        pw-metadata -n settings 0 node.target "music_audio_sink"
        ;;
    *)
        echo "Unknown application: $app_name"
        echo "Available: steam, brave, discord, spotify"
        exit 1
        ;;
esac
EOF

    chmod +x "$HOME/.config/wehttamsnaps/scripts/set-app-routing.sh"
    log_audio "Application routing script created"
}

# Function to create audio control GUI
create_audio_gui() {
    local gui_dir="$HOME/.config/wehttamsnaps/scripts"
    
    log_audio "Creating audio control GUI..."
    
    cat > "$gui_dir/audio-control-gui.py" << 'EOF'
#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GdkPixbuf
import subprocess
import json
import os

class AudioControlGUI:
    def __init__(self):
        self.window = Gtk.Window(title="J.A.R.V.I.S. Audio Control")
        self.window.set_default_size(400, 500)
        self.window.set_position(Gtk.WindowPosition.CENTER)
        
        # Main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_box.set_margin_top(20)
        main_box.set_margin_bottom(20)
        main_box.set_margin_start(20)
        main_box.set_margin_end(20)
        
        # Title
        title = Gtk.Label()
        title.set_markup('<span size="x-large" weight="bold">J.A.R.V.I.S. Audio Router</span>')
        title.set_halign(Gtk.Align.CENTER)
        main_box.pack_start(title, False, False, 0)
        
        # Separator
        separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        main_box.pack_start(separator, False, False, 10)
        
        # Audio routing sections
        self.create_routing_controls(main_box)
        
        # qpwgraph launcher
        graph_button = Gtk.Button(label="Open Audio Graph")
        graph_button.connect("clicked", self.open_qpwgraph)
        main_box.pack_start(graph_button, False, False, 0)
        
        self.window.add(main_box)
        self.window.connect("destroy", Gtk.main_quit)
        self.window.show_all()

    def create_routing_controls(self, container):
        # Create routing controls for each application type
        apps = {
            "Games": ["steam", "gamescope"],
            "Browser": ["brave", "firefox"],
            "Communication": ["discord", "teams"],
            "Music": ["spotify", "mpv"]
        }
        
        for category, app_list in apps.items():
            frame = Gtk.Frame(label=category)
            frame_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
            frame_box.set_margin_top(10)
            frame_box.set_margin_bottom(10)
            frame_box.set_margin_start(10)
            frame_box.set_margin_end(10)
            
            for app in app_list:
                button = Gtk.Button(label=f"Route {app.title()}")
                button.connect("clicked", lambda btn, a=app: self.route_app(a))
                frame_box.pack_start(button, False, False, 0)
            
            frame.add(frame_box)
            container.pack_start(frame, False, False, 0)

    def route_app(self, app_name):
        script_path = os.path.expanduser("~/.config/wehttamsnaps/scripts/set-app-routing.sh")
        try:
            subprocess.run([script_path, app_name], check=True)
            self.show_message(f"Routing {app_name.title()} audio...")
        except subprocess.CalledProcessError:
            self.show_message(f"Failed to route {app_name.title()} audio")

    def open_qpwgraph(self, button):
        subprocess.Popen(["qpwgraph"])

    def show_message(self, message):
        dialog = Gtk.MessageDialog(
            parent=self.window,
            flags=Gtk.DialogFlags.MODAL,
            type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            message_format=message
        )
        dialog.run()
        dialog.destroy()

if __name__ == "__main__":
    AudioControlGUI()
    Gtk.main()
EOF

    chmod +x "$gui_dir/audio-control-gui.py"
    log_audio "Audio control GUI created"
}

# Function to create preset configurations
create_audio_presets() {
    local preset_dir="$HOME/.config/wehttamsnaps/audio-presets"
    mkdir -p "$preset_dir"
    
    log_audio "Creating audio routing presets..."
    
    # Gaming preset
    cat > "$preset_dir/gaming.json" << 'EOF'
{
    "name": "Gaming Mode",
    "description": "Optimized for gaming with separate game and voice audio",
    "routing": {
        "games": "game_audio_sink",
        "discord": "comm_audio_sink",
        "browser": "browser_audio_sink",
        "music": "music_audio_sink"
    },
    "mixing": {
        "stream": ["game_audio_source", "comm_audio_source"],
        "monitor": ["game_audio_source", "comm_audio_source", "music_audio_source"]
    }
}
EOF

    # Streaming preset
    cat > "$preset_dir/streaming.json" << 'EOF'
{
    "name": "Streaming Mode",
    "description": "Complete audio separation for streaming",
    "routing": {
        "games": "game_audio_sink",
        "discord": "comm_audio_sink",
        "browser": "browser_audio_sink",
        "music": "music_audio_sink",
        "obs": "stream_mix"
    },
    "mixing": {
        "stream": ["game_audio_source", "browser_audio_source", "music_audio_source"],
        "monitor": ["comm_audio_source"]
    }
}
EOF

    # Work preset
    cat > "$preset_dir/work.json" << 'EOF'
{
    "name": "Work Mode",
    "description": "Simplified routing for productivity",
    "routing": {
        "browser": "browser_audio_sink",
        "discord": "comm_audio_sink",
        "music": "music_audio_sink"
    },
    "mixing": {
        "focus": ["browser_audio_source", "music_audio_source"],
        "meetings": ["comm_audio_source"]
    }
}
EOF

    log_audio "Audio presets created"
}

# Function to restart PipeWire with new configuration
restart_pipewire() {
    log_audio "Restarting PipeWire services..."
    
    # Restart PipeWire services
    systemctl --user restart pipewire.service
    systemctl --user restart pipewire-pulse.service
    systemctl --user restart wireplumber.service
    
    sleep 3
    log_audio "PipeWire services restarted"
}

# Main installation function
install_audio_routing() {
    echo "Installing J.A.R.V.I.S. Audio Routing System..."
    
    # Check dependencies
    for cmd in pipewire qpwgraph pactl pw-metadata; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd not found. Please install required packages."
            return 1
        fi
    done
    
    create_virtual_sinks
    create_audio_routing_layout
    setup_application_routing
    create_audio_gui
    create_audio_presets
    
    echo "Restarting PipeWire to apply changes..."
    restart_pipewire
    
    echo ""
    echo "J.A.R.V.I.S. Audio Routing System installed successfully!"
    echo ""
    echo "Usage:"
    echo "  • Run 'qpwgraph' for visual audio routing"
    echo "  • Run audio-control-gui.py for easy app routing"
    echo "  • Check logs: $AUDIO_LOGS"
    echo ""
    echo "Virtual sinks created:"
    echo "  • Game Audio Sink"
    echo "  • Browser Audio Sink"
    echo "  • Communication Audio Sink"
    echo "  • Music Audio Sink"
}

# Function to create cheat sheet
create_audio_cheat_sheet() {
    cat > "$HOME/.config/wehttamsnaps/docs/audio-routing-cheat.txt" << 'EOF'
# J.A.R.V.I.S. Audio Routing Cheat Sheet

## Virtual Audio Sinks
- Game Audio Sink: Route game audio separately
- Browser Audio Sink: Route web browser audio
- Communication Audio Sink: Route Discord/Teams audio
- Music Audio Sink: Route Spotify/Music audio

## Quick Commands

### Launch Audio Graph
```bash
qpwgraph
```

### Route Application Audio
```bash
~/.config/wehttamsnaps/scripts/set-app-routing.sh <app>
# Examples: steam, discord, brave, spotify
```

### Launch Audio Control GUI
```bash
~/.config/wehttamsnaps/scripts/audio-control-gui.py
```

### Check Available Audio Devices
```bash
pactl list sinks
pactl list sources
```

### Set Default Sink
```bash
pactl set-default-sink <sink_name>
```

## Streaming Setup
1. Launch qpwgraph
2. Drag virtual sources to OBS inputs
3. Adjust volumes as needed
4. Save your layout for future sessions

## Troubleshooting
- If audio doesn't work: Restart PipeWire services
- Check logs: ~/.config/wehttamsnaps/logs/audio-setup.log
- Ensure all virtual sinks appear in pavucontrol

## Presets
- Gaming Mode: Separated game and voice audio
- Streaming Mode: Complete audio separation
- Work Mode: Simplified routing for productivity
EOF

    echo "Audio routing cheat sheet created: $HOME/.config/wehttamsnaps/docs/audio-routing-cheat.txt"
}

# Main script execution
case "$1" in
    "install")
        install_audio_routing
        create_audio_cheat_sheet
        ;;
    "cheat-sheet")
        create_audio_cheat_sheet
        ;;
    *)
        echo "J.A.R.V.I.S. Audio Routing Setup"
        echo "Usage: $0 {install|cheat-sheet}"
        echo ""
        echo "Commands:"
        echo "  install      - Install complete audio routing system"
        echo "  cheat-sheet  - Create audio routing cheat sheet"
        exit 1
        ;;
esac