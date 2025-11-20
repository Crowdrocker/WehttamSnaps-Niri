# WehttamSnaps Niri Setup - Quick Start Guide

```
██╗    ██╗███████╗██╗  ██╗████████╗████████╗ █████╗ ███╗   ███╗███████╗███╗   ██╗ █████╗ ██████╗ ███████╗
██║    ██║██╔════╝██║  ██║╚══██╔══╝╚══██╔══╝██╔══██╗████╗ ████║██╔════╝████╗  ██║██╔══██╗██╔══██╗██╔════╝
██║ █╗ ██║█████╗  ███████║   ██║      ██║   ███████║██╔████╔██║███████╗██╔██╗ ██║███████║██████╔╝███████╗
██║███╗██║██╔══╝  ██╔══██║   ██║      ██║   ██╔══██║██║╚██╔╝██║╚════██║██║╚██╗██║██╔══██║██╔═══╝ ╚════██║
╚███╔███╔╝███████╗██║  ██║   ██║      ██║   ██║  ██║██║ ╚═╝ ██║███████║██║ ╚████║██║  ██║██║     ███████║
 ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚══════╝
```

**GitHub:** https://github.com/Crowdrocker  
**Twitch:** twitch.tv/WehttamSnaps  
**YouTube:** youtube.com/@WehttamSnaps

---

## 🚀 Essential Shortcuts (First 5 Minutes)

| Shortcut | Action |
|----------|--------|
| **Mod + H** | **Help (Keybindings)** |
| **Mod + Space** | **Application Launcher** |
| **Mod + Enter** | **Terminal (Ghostty)** |
| **Mod + B** | **Browser (Brave)** |
| **Mod + Q** | **Close Window** |

> **Mod = Super (Windows key)**

---

## 📸 Photography Workflow (Your Main Work)

**Jump to Photo Workspace:** `Mod + 3`

| Shortcut | Application |
|----------|-------------|
| `Mod + Shift + D` | Darktable (RAW) |
| `Mod + Shift + G` | GIMP (Editing) |
| `Mod + Shift + K` | Krita (Digital Art) |
| `Mod + Shift + P` | DigiKam (Management) |

**Workflow:**
1. Import → DigiKam
2. RAW Process → Darktable
3. Edit/Composite → GIMP
4. Final Touches → Krita
5. Export for WehttamSnaps

---

## 🎮 Gaming (Workspace 9)

**Jump to Gaming:** `Mod + 9`

| Shortcut | Action |
|----------|--------|
| `Mod + G` | **Gaming Mode Toggle** (Disable animations) |
| `Mod + Shift + S` | Launch Steam |
| `Mod + Alt + L` | Lutris |
| `Mod + Alt + P` | ProtonUp-Qt |

**Gaming Mode:**
- Disables all animations
- CPU to performance governor
- GPU to high performance
- J.A.R.V.I.S. says "Gaming mode activated"

**Your Pre-Configured Games:**
- Division 2 (fullscreen, borderless)
- Cyberpunk 2077 (fullscreen, borderless)
- Fallout 4, Watch Dogs series, and 11 more

---

## 🎨 10 Workspaces

| Number | Name | Purpose | Apps |
|--------|------|---------|------|
| **1** | Browser | Web | Brave, Firefox |
| **2** | Terminal | Dev/Files | Ghostty, Thunar, Kate |
| **3** | Photo | WehttamSnaps | GIMP, Darktable, Krita |
| **4** | Design | Graphics | Inkscape |
| **5** | 3D | Modeling | Blender |
| **6** | Chat | Social | Discord, Telegram |
| **7** | Media | Entertainment | Spotify, YouTube, Twitch |
| **8** | Stream | OBS | OBS Studio, qpwgraph |
| **9** | Gaming | Games | Steam, Lutris |
| **10** | Modding | Tools | Vortex, MO2, Wabbajack |

**Navigation:**
- `Mod + 1-0` → Switch to workspace
- `Mod + Shift + 1-0` → Move window to workspace
- `Mod + Alt + 1-0` → Move window and follow

---

## 🌐 Webapps (Mod + W)

Press `Mod + W` followed by letter:

| Key | Webapp |
|-----|--------|
| `Y` | YouTube |
| `T` | Twitch |
| `S` | Spotify |
| `D` | Discord |
| `M` | Gmail |
| `G` | GitHub |

---

## 🔊 Audio Routing (VoiceMeeter-like)

**Setup:** `~/.config/wehttamsnaps/scripts/audio-setup.sh`

**Open Tools:**
- `Mod + A` → qpwgraph (visual routing)
- `Mod + Ctrl + A` → pavucontrol (mixer)

**4 Virtual Sinks:**
1. **GameAudio** - Steam games
2. **BrowserAudio** - Web audio
3. **DiscordAudio** - Voice chat
4. **SpotifyAudio** - Music

**For Streaming:**
Route all sinks → OBS + Headphones via qpwgraph

---

## 🤖 J.A.R.V.I.S. Integration

**Audio Cues:**
- Startup: "Allow me to introduce myself..."
- Gaming Mode: "Gaming mode activated"
- Workspace 8: "Streaming systems online"
- High Temp: "Warning: System temperature critical"

**Manage:** `~/.config/wehttamsnaps/scripts/jarvis-manager.sh`

**Add Sounds:**
1. Place MP3 files in `~/.config/wehttamsnaps/sounds/`
2. Run: `jarvis-manager.sh placeholders` to see expected files
3. Replace placeholders with your sounds

---

## 📷 Screenshots

| Shortcut | Action |
|----------|--------|
| `Print` | Full screenshot |
| `Shift + Print` | Area selection |
| `Mod + Print` | Edit with swappy |
| `Alt + Print` | Active window |

**Saved to:** `~/Pictures/Screenshots/`

---

## 🎥 Screen Recording

| Shortcut | Action |
|----------|--------|
| `Mod + Shift + R` | Toggle recording |

---

## 🎵 Media Controls

| Key | Action |
|-----|--------|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute |
| `XF86AudioPlay` | Play/Pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |

---

## 🪟 Window Management

**Focus:**
- `Mod + Left/H` → Focus left
- `Mod + Right/L` → Focus right
- `Mod + Up/K` → Focus up
- `Mod + Down/J` → Focus down

**Move:**
- `Mod + Shift + Left/H` → Move left
- `Mod + Shift + Right/L` → Move right

**Resize:**
- `Mod + Plus` → Wider
- `Mod + Minus` → Narrower
- `Mod + R` → Preset widths

**Actions:**
- `Mod + F` → Fullscreen
- `Mod + Shift + Space` → Float
- `Mod + M` → Monocle mode

---

## 🎨 Appearance

**Wallpaper:**
- `Mod + Shift + W` → Selector
- `Mod + Ctrl + Space` → Random
- `Mod + Alt + W` → Toggle automation

**Theme:**
- `Mod + Shift + Ctrl + T` → Toggle dark/light

**Bar:**
- `Mod + Ctrl + B` → Show/hide

---

## 🔧 System Tools

| Shortcut | Tool |
|----------|------|
| `Mod + Escape` | Task Manager |
| `Mod + Shift + Escape` | Mission Center |
| `Mod + Ctrl + Escape` | btop |
| `Mod + O` | OBS Studio |
| `Mod + D` | Discord |
| `Mod + P` | Spotify |
| `Mod + I` | System Settings |

---

## 🔒 Session Management

| Shortcut | Action |
|----------|--------|
| `Mod + L` | Lock screen |
| `Mod + Shift + E` | Session menu |
| `Mod + Shift + Ctrl + R` | Reload config |
| `Mod + Shift + Ctrl + E` | Exit Niri |

---

## 📚 Documentation

**Location:** `~/.config/wehttamsnaps/docs/`

| File | Content |
|------|---------|
| `README.md` | Main documentation |
| `INSTALL.md` | Detailed installation |
| `QUICKSTART.md` | This guide |
| `AUDIO-ROUTING.md` | Audio setup guide |
| `GAMING.md` | Per-game configs |
| `TROUBLESHOOTING.md` | Common issues |

---

## 🛠️ Useful Commands

```bash
# Validate Niri config
niri validate

# Reload Niri
niri msg action reload-config

# Check Niri logs
journalctl --user -u niri.service -f

# Test J.A.R.V.I.S. sounds
~/.config/wehttamsnaps/scripts/jarvis-manager.sh test

# Setup audio routing
~/.config/wehttamsnaps/scripts/audio-setup.sh

# Check gaming mode status
~/.config/wehttamsnaps/scripts/toggle-gamemode.sh status

# Launch webapp
~/.config/wehttamsnaps/scripts/webapp-launcher.sh youtube

# List webapps
~/.config/wehttamsnaps/scripts/webapp-launcher.sh list
```

---

## 🎯 First-Time Checklist

- [ ] **1. Read welcome screen** (appears on first boot)
- [ ] **2. Press `Mod + H`** for keybindings reference
- [ ] **3. Setup audio routing** (`audio-setup.sh`)
- [ ] **4. Add J.A.R.V.I.S. sounds** to `~/.config/wehttamsnaps/sounds/`
- [ ] **5. Configure qpwgraph** for streaming
- [ ] **6. Test gaming mode** (`Mod + G`)
- [ ] **7. Launch Steam** and verify game configs
- [ ] **8. Setup wallpapers** in `~/.config/wehttamsnaps/wallpapers/`
- [ ] **9. Customize Noctalia** (`Mod + Comma`)
- [ ] **10. Read full README** for advanced features

---

## 🐛 Troubleshooting Quick Fixes

**Niri won't start:**
```bash
niri validate
journalctl --user -u niri.service -f
```

**No audio:**
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
~/.config/wehttamsnaps/scripts/audio-setup.sh restart
```

**Gaming performance issues:**
```bash
# Enable gaming mode
~/.config/wehttamsnaps/scripts/toggle-gamemode.sh on

# Check gamemode
gamemoded -s
```

**Keybindings not working:**
```bash
# Check Noctalia is running
ps aux | grep quickshell

# Restart Noctalia
systemctl --user restart noctalia.service
# or
killall qs && qs -c noctalia-shell &
```

---

## 🔗 Quick Links

- **Repository:** https://github.com/Crowdrocker
- **Twitch:** https://twitch.tv/WehttamSnaps
- **YouTube:** https://youtube.com/@WehttamSnaps
- **Niri Docs:** https://github.com/YaLTeR/niri
- **Noctalia Docs:** https://github.com/noctalia-dev/noctalia-shell

---

## 💡 Pro Tips

1. **Always keep terminal handy** - `Mod + Enter` is your friend
2. **Use gaming mode** - Big FPS boost for Division 2 and Cyberpunk
3. **Save qpwgraph layouts** - File → Save As in qpwgraph
4. **Workspace 3 is your main** - All photography tools there
5. **Test J.A.R.V.I.S. sounds** - `jarvis-manager.sh test`
6. **Keep wallpapers organized** - Material You colors auto-generate
7. **Check logs when things break** - `journalctl --user -f`
8. **Backup configs** - `~/.config/wehttamsnaps-backup-*`

---

## 🎮 Your Gaming Library (Pre-Configured)

All games have optimized launch options for RX 580:

✅ Call of Duty HQ  
✅ Cyberpunk 2077 (fullscreen fix)  
✅ Fallout 4 (fullscreen fix)  
✅ FarCry 5  
✅ Ghost Recon Breakpoint  
✅ Marvel's Avengers  
✅ Need for Speed Payback  
✅ Rise of the Tomb Raider  
✅ Shadow of the Tomb Raider  
✅ The First Descendant  
✅ Tom Clancy's The Division  
✅ Tom Clancy's The Division 2 (fullscreen fix)  
✅ Warframe  
✅ Watch Dogs  
✅ Watch Dogs 2  
✅ Watch Dogs Legion  

---

**Made with ❤️ for Photography, Gaming, and Content Creation**

*WehttamSnaps - Where pixels meet passion* 📸🎮🎨
