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
