# Audio Routing Guide - WehttamSnaps Setup

**VoiceMeeter-like audio control for Linux with PipeWire**

---

## 🎯 Overview

This guide helps you set up advanced audio routing similar to VoiceMeeter on Windows. You'll be able to:

- **Separate audio streams** (game, browser, Discord, Spotify)
- **Route each to different outputs** (OBS, headphones, speakers)
- **Control individual volumes** per application
- **Record/stream with full control** over what audio gets captured

---

## 📊 Audio Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        APPLICATIONS                          │
├──────────┬──────────┬──────────┬──────────┬─────────────────┤
│  Steam   │ Browser  │ Discord  │ Spotify  │  Other Apps     │
│  Games   │ YouTube  │ Voice    │  Music   │                 │
└────┬─────┴────┬─────┴────┬─────┴────┬─────┴─────────────────┘
     │          │          │          │
     ▼          ▼          ▼          ▼
┌─────────┬──────────┬──────────┬──────────┐
│  Game   │ Browser  │ Discord  │ Spotify  │  ◄─ Virtual Sinks
│  Audio  │  Audio   │  Audio   │  Audio   │
└────┬────┴────┬─────┴────┬─────┴────┬─────┘
     │         │          │          │
     │    ┌────┴──────────┴──────────┴────┐
     │    │                                │
     ▼    ▼                                ▼
┌────────────┐                      ┌──────────┐
│ OBS Studio │                      │ Hardware │
│   Mixer    │                      │  Output  │  ◄─ Your Headphones
└────────────┘                      └──────────┘
```

---

## 🚀 Quick Setup

### 1. Run the Setup Script

```bash
~/.config/wehttamsnaps/scripts/audio-setup.sh
```

This creates 4 virtual audio sinks:
- **GameAudio** - For Steam games and game launchers
- **BrowserAudio** - For Brave, Firefox, Chrome
- **DiscordAudio** - For Discord/WebCord
- **SpotifyAudio** - For Spotify music

**What it does:**
✅ Creates persistent virtual sinks  
✅ Configures automatic application routing  
✅ Sets up PipeWire + WirePlumber  
✅ Opens qpwgraph and pavucontrol for you

### 2. Open Audio Tools

```bash
# Visual routing graph
qpwgraph
# or: Mod + A

# Volume mixer
pavucontrol
# or: Mod + Ctrl + A
```

---

## 🎛️ Using qpwgraph (Visual Router)

qpwgraph shows all audio connections visually. Think of it as a digital patch bay.

### Interface Layout

```
┌─────────────────────────────────────────────────────┐
│  Audio  MIDI  Patchbay                               │
├─────────────────────────────────────────────────────┤
│                                                       │
│  [Inputs/Sources]              [Outputs/Sinks]      │
│                                                       │
│  ┌──────────┐                  ┌──────────┐         │
│  │  Steam   │─────────────────▶│ GameAudio│         │
│  └──────────┘                  └──────────┘         │
│                                       │              │
│  ┌──────────┐                        ├─────────────▶│
│  │ Browser  │─────────────────▶      │              │
│  └──────────┘                  └──────────┘         │
│                                       │              │
│                                       ▼              │
│                                 ┌──────────┐        │
│                                 │ Hardware │        │
│                                 │  Output  │        │
│                                 └──────────┘        │
│                                                       │
└─────────────────────────────────────────────────────┘
```

### Basic Operations

**Connect Audio:**
1. Click and drag from output port (right side of box)
2. Drop on input port (left side of destination)
3. Connection line appears

**Disconnect:**
- Right-click connection → Disconnect
- Or select and press Delete

**Save Layout:**
- File → Save As → `~/.config/qpwgraph/wehttamsnaps-streaming.qgp`
- File → Open to restore saved layout

---

## 🎚️ Using pavucontrol (Volume Mixer)

pavucontrol is your volume control panel.

### Tabs

#### 1. **Playback Tab**
Shows all playing audio streams.

**To route an application:**
1. Play audio from that app (game, browser, etc.)
2. Find it in the Playback list
3. Click the dropdown at the bottom
4. Select destination sink:
   - GameAudio
   - BrowserAudio  
   - DiscordAudio
   - SpotifyAudio
   - Or hardware output directly

#### 2. **Recording Tab**
Shows applications recording audio (OBS, Discord, etc.)

**To set OBS input:**
1. Start recording in OBS
2. Find OBS in Recording tab
3. Select which sink to capture:
   - Monitor of GameAudio
   - Monitor of BrowserAudio
   - Monitor of DiscordAudio
   - Monitor of SpotifyAudio

#### 3. **Output Devices Tab**
Your physical audio outputs (headphones, speakers).

#### 4. **Input Devices Tab**
Your microphone settings.

**For streaming/recording:**
- Set microphone as input
- Adjust input volume
- Enable/disable noise cancellation (if using EasyEffects)

---

## 🎮 Routing Examples

### Example 1: Basic Gaming Setup

**Goal:** Game audio to headphones, separate from other apps.

```bash
# In pavucontrol Playback tab:
Steam/Game → GameAudio
Browser → BrowserAudio
Discord → DiscordAudio

# In qpwgraph:
GameAudio → Hardware Output (Headphones)
BrowserAudio → Hardware Output (Headphones)
DiscordAudio → Hardware Output (Headphones)
```

**Result:** All audio goes to headphones but is separated for volume control.

---

### Example 2: Streaming Setup (OBS)

**Goal:** Stream game + Discord, but NOT Spotify.

#### Step 1: Route Applications
```bash
# pavucontrol Playback:
Steam/Game → GameAudio
Browser → BrowserAudio
Discord → DiscordAudio
Spotify → SpotifyAudio
```

#### Step 2: Add OBS Audio Sources

In OBS Studio:
1. **Add Sources:**
   - Audio Input Capture → "Game Audio"
   - Audio Input Capture → "Discord Audio"
   - Audio Input Capture → "Microphone"

2. **Configure Each Source:**
   - Right-click source → Properties
   - Device: Select "Monitor of GameAudio" (for game)
   - Device: Select "Monitor of DiscordAudio" (for voice)
   - Device: Select your microphone

3. **Don't add Spotify:**
   - SpotifyAudio goes only to headphones
   - Stream gets game + Discord + mic
   - You hear game + Discord + Spotify

#### Step 3: Route to Hardware

In qpwgraph:
```
GameAudio → OBS + Hardware Output
DiscordAudio → OBS + Hardware Output  
SpotifyAudio → Hardware Output only
Microphone → OBS
```

**Result:** 
- ✅ Stream hears: Game + Discord + Your mic
- ✅ You hear: Game + Discord + Spotify
- ❌ Stream does NOT hear: Spotify

---

### Example 3: Recording Without Discord

**Goal:** Record gameplay with only game audio, no chat.

```bash
# pavucontrol:
Game → GameAudio
Discord → DiscordAudio
Music → SpotifyAudio

# qpwgraph:
GameAudio → OBS + Headphones
DiscordAudio → Headphones only (not OBS)
SpotifyAudio → Headphones only
Mic → OBS
```

**Result:** Recording has game audio + your mic, but not Discord or music.

---

## 🔧 Advanced Configuration

### Automatic Application Routing

The setup script creates rules in `~/.config/wireplumber/main.lua.d/51-wehttamsnaps-routing.lua`.

**Pre-configured routing:**
- Steam games → GameAudio
- Brave/Firefox/Chrome → BrowserAudio
- Discord/WebCord → DiscordAudio
- Spotify → SpotifyAudio

**Add custom rules:**
```lua
-- Edit: ~/.config/wireplumber/main.lua.d/51-wehttamsnaps-routing.lua

rule = {
  matches = {
    {
      { "application.name", "matches", "*your-app*" },
    },
  },
  apply_properties = {
    ["node.target"] = "GameAudio",  -- or BrowserAudio, etc.
  },
}

table.insert(alsa_monitor.rules, rule)
```

Restart audio:
```bash
audio-restart
# or: systemctl --user restart wireplumber
```

---

### Creating Additional Virtual Sinks

Need more than 4 sinks? Add them manually:

```bash
# Create a new sink
pw-cli create-node adapter \
    "{ factory.name=support.null-audio-sink \
       node.name=\"MusicAudio\" \
       media.class=Audio/Sink \
       object.linger=true \
       audio.position=[FL,FR] }"
```

**Make it persistent:**

Add to `~/.config/pipewire/pipewire.conf.d/wehttamsnaps-sinks.conf`:
```
{   name = libpipewire-module-loopback
    args = {
        node.name = "MusicAudio"
        node.description = "Music Audio"
        audio.position = [ FL FR ]
        capture.props = {
            media.class = "Audio/Sink"
            node.name = "MusicAudio"
        }
        playback.props = {
            node.name = "MusicAudio.output"
            node.passive = true
        }
    }
}
```

---

## 🎤 Microphone Processing

### Basic Noise Suppression

Install EasyEffects:
```bash
paru -S easyeffects
```

**Setup:**
1. Open EasyEffects
2. Add effects chain:
   - Noise Reduction
   - Compressor (evens out volume)
   - Limiter (prevents clipping)
   - Gate (cuts background noise)

3. Save preset as "WehttamSnaps Mic"
4. Enable on startup

**Route processed mic to OBS:**
- EasyEffects output → OBS input
- Check in pavucontrol Recording tab

---

## 📊 Monitoring & Debugging

### Check Active Sinks

```bash
pactl list sinks short
```

Expected output:
```
0    GameAudio         module-null-sink.c      s16le 2ch 48000Hz
1    BrowserAudio      module-null-sink.c      s16le 2ch 48000Hz
2    DiscordAudio      module-null-sink.c      s16le 2ch 48000Hz
3    SpotifyAudio      module-null-sink.c      s16le 2ch 48000Hz
```

### Check Audio Routing

```bash
pw-dump | grep -A 10 "node.name"
```

### Test Audio Flow

```bash
# Play test sound to specific sink
paplay --device=GameAudio /usr/share/sounds/freedesktop/stereo/complete.oga
```

### View Real-Time Graph

```bash
pw-dot | dot -Tpng > pipewire-graph.png && xdg-open pipewire-graph.png
```

---

## 🚨 Troubleshooting

### No Sound / Sinks Not Appearing

```bash
# Restart PipeWire services
systemctl --user restart pipewire pipewire-pulse wireplumber

# Or use alias
audio-restart

# Wait 5 seconds, then check
pactl list sinks short
```

### Application Not Auto-Routing

```bash
# Check wireplumber rules
cat ~/.config/wireplumber/main.lua.d/51-wehttamsnaps-routing.lua

# Manual routing:
# 1. Open pavucontrol
# 2. Playback tab
# 3. Find app
# 4. Select sink from dropdown
```

### Audio Crackling / Stuttering

```bash
# Check buffer size in pipewire config
pw-metadata -n settings 0 clock.force-quantum 1024

# Or edit: ~/.config/pipewire/pipewire.conf
# default.clock.quantum = 1024
# default.clock.min-quantum = 256
```

### OBS Not Capturing Audio

**Check:**
1. Recording tab in pavucontrol shows OBS
2. OBS is set to capture "Monitor of [Sink]"
3. The sink exists: `pactl list sinks short`
4. Something is playing to that sink

**Fix:**
```bash
# Restart OBS
killall obs
obs &

# Re-add audio source in OBS
Sources → Add → Audio Input Capture → Monitor of GameAudio
```

### Virtual Sinks Disappear After Reboot

```bash
# Check persistent config exists
ls ~/.config/pipewire/pipewire.conf.d/wehttamsnaps-sinks.conf

# If missing, re-run setup
audio-setup
```

---

## 💡 Tips & Best Practices

### Save qpwgraph Layouts

Create different layouts for different scenarios:

```bash
~/.config/qpwgraph/
├── streaming.qgp      # For Twitch/YouTube
├── recording.qgp      # For video editing
├── music.qgp          # For music production
└── gaming.qgp         # For regular gaming
```

Load with: File → Open in qpwgraph

### Volume Control Tips

- **Game too loud?** Adjust GameAudio volume in pavucontrol Output Devices
- **Can't hear Discord?** Check DiscordAudio volume
- **OBS audio clipping?** Lower volume of individual sinks, not master output

### Latency Optimization

For minimal latency (important for rhythm games):

```bash
# Edit: ~/.config/pipewire/pipewire.conf
default.clock.quantum = 256      # Lower = less latency, more CPU
default.clock.min-quantum = 128
```

Restart audio after changes.

---

## 🎬 Streaming Workflows

### Twitch/YouTube Streaming

**Pre-Stream Checklist:**
- [ ] Open qpwgraph, load streaming layout
- [ ] Open pavucontrol, check volumes
- [ ] Test microphone in OBS
- [ ] Play test audio to each sink
- [ ] Start music (Spotify → goes to headphones only)
- [ ] Start game (auto-routes to GameAudio → OBS + headphones)
- [ ] Join Discord (auto-routes to DiscordAudio → OBS + headphones)

**During Stream:**
- Adjust sink volumes in pavucontrol Output Devices tab
- Game too loud? Lower GameAudio volume
- Chat too quiet? Raise DiscordAudio volume
- Mute yourself in Discord, not in OBS (so you can still hear yourself)

---

## 📝 Quick Reference

### Aliases

```bash
audio              # Run setup script
audio-test         # Test current setup
audio-restart      # Restart PipeWire
qpw                # Open qpwgraph
pavu               # Open pavucontrol
```

### Keybinds

```
Mod + A            Open qpwgraph
Mod + Ctrl + A     Open pavucontrol
```

### Important Locations

```bash
# Virtual sink config
~/.config/pipewire/pipewire.conf.d/wehttamsnaps-sinks.conf

# Routing rules
~/.config/wireplumber/main.lua.d/51-wehttamsnaps-routing.lua

# qpwgraph layouts
~/.config/qpwgraph/

# PipeWire settings
~/.config/pipewire/pipewire.conf
```

---

## 🔗 Resources

- **PipeWire Docs:** https://docs.pipewire.org/
- **WirePlumber Docs:** https://pipewire.pages.freedesktop.org/wireplumber/
- **qpwgraph:** https://gitlab.freedesktop.org/rncbc/qpwgraph
- **EasyEffects:** https://github.com/wwmm/easyeffects

---

**Made for WehttamSnaps** | Photography • Gaming • Content Creation
