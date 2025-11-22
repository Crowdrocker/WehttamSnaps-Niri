# WehttamSnaps – Arch Linux Niri Configuration

```
██╗    ██╗███████╗██╗  ██╗████████╗████████╗ █████╗ ███╗   ███╗███████╗███╗   ██╗ █████╗ ██████╗ ███████╗
██║    ██║██╔════╝██║  ██║╚══██╔══╝╚══██╔══╝██╔══██╗████╗ ████║██╔════╝████╗  ██║██╔══██╗██╔══██╗██╔════╝
██║ █╗ ██║█████╗  ███████║   ██║      ██║   ███████║██╔████╔██║███████╗██╔██╗ ██║███████║██████╔╝███████╗
██║███╗██║██╔══╝  ██╔══██║   ██║      ██║   ██╔══██║██║╚██╔╝██║╚════██║██║╚██╗██║██╔══██║██╔═══╝ ╚════██║
╚███╔███╔╝███████╗██║  ██║   ██║      ██║   ██║  ██║██║ ╚═╝ ██║███████║██║ ╚████║██║  ██║██║     ███████║
 ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚══════╝
```

**Author:** Matthew (wehttamsnaps)  
**GitHub:** [github.com/Crowdrocker](https://github.com/Crowdrocker)  
**Twitch/YouTube:** WehttamSnaps

> *A professional Arch Linux Niri configuration optimized for photography, content creation, and gaming.*

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1?logo=arch-linux&logoColor=white)
![Niri](https://img.shields.io/badge/WM-Niri-89b4fa)
![License](https://img.shields.io/badge/license-MIT-green)
![Stars](https://img.shields.io/github/stars/Crowdrocker/WehttamSnaps-Niri?style=social)
```
```
## 📸 Screenshots

<p align="center">
  <img src="screenshots/desktop-overview.png" width="48%" alt="Desktop Overview">
  <img src="screenshots/gradient-borders.png" width="48%" alt="Gradient Borders">
</p>

<p align="center">
  <img src="screenshots/gaming-workspace.png" width="48%" alt="Gaming">
  <img src="screenshots/photo-editing.png" width="48%" alt="Photography">
</p>

```

---

## 🎯 Overview

This repository contains a complete, modular Niri configuration featuring:

- **Noctalia Shell** (Quickshell-based) – Beautiful, responsive UI
- **J.A.R.V.I.S. Integration** – Immersive AI assistant theme with custom sounds
- **Photography Workflow** – Optimized for photo editing and content creation
- **Gaming Performance** – Tuned for RX 580 with Proton GE configurations
- **Audio Routing** – PipeWire + qpwgraph for advanced audio control
- **Custom Branding** – WehttamSnaps theme throughout

---

## 💻 System Specifications

- **Hardware:** Dell XPS 8700
- **CPU:** Intel Core i7-4790 @ 4.00 GHz (8 cores)
- **GPU:** AMD RX 580 Series
- **RAM:** 16GB
- **Display:** 1920x1080 @ 60Hz (DP-3)
- **Storage:** 1TB SSD + 2x 120GB SSD

---

## ✨ Features

### Compositor & Shell
- **Niri** – Modern scrollable-tiling Wayland compositor
- **Noctalia Shell** – Quickshell-based panel with custom widgets
- **Ghostty Terminal** – GPU-accelerated with Fira Code font

### Productivity
- **10 Workspaces** – Organized for media, gaming, work, and photography
- **Custom Keybindings** – Efficient workflow shortcuts
- **Webapp Integration** – Quick access to web-based tools
- **Window Rules** – Optimized layouts for specific applications

### Gaming
- **Gamemode + Gamescope** – Performance optimization
- **Proton GE** – Enhanced game compatibility
- **Steam Launch Options** – Pre-configured for 16 games
- **Mod Manager Support** – Window rules for Vortex, MO2, Wabbajack

### Audio
- **PipeWire Routing** – Separate audio channels (game, browser, Discord, Spotify)
- **qpwgraph** – Visual audio routing like VoiceMeter
- **J.A.R.V.I.S. Sounds** – System event audio notifications

### Theming
- **Material You Colors** – Generated from wallpapers via Matugen
- **Consistent Styling** – GTK, Qt, terminal themes
- **Custom Plymouth** – Animated boot screen with WehttamSnaps logo

## 📝 Update Your Documentation



```markdown
### 🛡️ Config Validation

Real-time config validation with desktop notifications:

```bash
# Enable config watcher (automatic on boot)
systemctl --user enable --now config-watcher.service

# Validate all configs manually
Mod + Alt + V
# or
validate-config
```

**Features:**
- ✅ Instant error notifications when you save
- ✅ J.A.R.V.I.S. warning sounds
- ✅ Detailed error messages
- ✅ Prevents broken configs
```

---

## 🎨 Integration with Your Setup

### Already Integrated:
- ✅ J.A.R.V.I.S. warning sound on errors
- ✅ Uses your notification system (Noctalia/mako)
- ✅ Logs to `~/.cache/wehttamsnaps/`
- ✅ Follows WehttamSnaps branding
- ✅ Works with all your configs

### Add to Aliases:
Already included in `.aliases`:
```bash
alias validate-config='~/.config/wehttamsnaps/scripts/config-watcher.sh validate'
alias watch-config='~/.config/wehttamsnaps/scripts/config-watcher.sh start'
```
---

## 📦 Installation

### Prerequisites

```bash
# Install base dependencies
paru -S niri ghostty noctalia-shell quickshell pipewire wireplumber \
        gamemode gamescope proton-ge-custom-bin qpwgraph pavucontrol \
        matugen-git cliphist starship fastfetch git git-lfs
```

### Quick Install

```bash
# Clone the repository
git clone https://github.com/Crowdrocker/WehttamSnaps-Niri.git ~/.config/wehttamsnaps

# Run installer
cd ~/.config/wehttamsnaps
./install.sh
```

The installer will:
1. Back up existing configurations
2. Install required packages
3. Create symlinks to configs
4. Set up J.A.R.V.I.S. sounds
5. Configure Plymouth theme
6. Initialize audio routing

---

## 🎹 Keybindings

### Core Navigation
| Shortcut | Action |
|----------|--------|
| `Mod + Space` | Application Launcher |
| `Mod + S` | Control Center |
| `Mod + Comma` | Settings |
| `Mod + Enter` | Terminal (Ghostty) |
| `Mod + B` | Browser |
| `Mod + Q` | Close Window |
| `Mod + H` | Help/Keybindings |

### Workspaces
| Shortcut | Action |
|----------|--------|
| `Mod + 1-0` | Switch to workspace 1-10 |
| `Mod + Shift + 1-0` | Move window to workspace |
| `Mod + Ctrl + Left/Right` | Navigate workspaces |

### Audio
| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | Volume Up |
| `XF86AudioLowerVolume` | Volume Down |
| `XF86AudioMute` | Toggle Mute |

### Utilities
| Shortcut | Action |
|----------|--------|
| `Mod + V` | Clipboard History |
| `Mod + L` | Lock Screen |
| `Mod + C` | Calculator |
| `Mod + Ctrl + Space` | Random Wallpaper |

### Gaming Mode
| Shortcut | Action |
|----------|--------|
| `Mod + G` | Toggle Gaming Mode (disable animations) |
| `Mod + Shift + G` | Launch Steam |

---

## 📁 Repository Structure

```
~/.config/wehttamsnaps/
├── README.md                    # This file
├── install.sh                   # Main installation script
├── logo.txt                     # ASCII art branding
├── docs/
│   ├── INSTALL.md              # Detailed installation guide
│   ├── QUICKSTART.md           # First-time setup
│   ├── AUDIO-ROUTING.md        # PipeWire configuration guide
│   ├── GAMING.md               # Gaming optimization guide
│   └── TROUBLESHOOTING.md      # Common issues and fixes
├── configs/
│   ├── niri/
│   │   ├── config.kdl          # Main Niri config (loader)
│   │   └── conf.d/
│   │       ├── 00-base.kdl     # Core settings
│   │       ├── 10-keybinds.kdl # Keybindings
│   │       ├── 20-rules.kdl    # Window rules
│   │       ├── 30-workspaces.kdl
│   │       ├── 40-gaming.kdl   # Gaming-specific rules
│   │       └── 99-overrides.kdl
│   ├── noctalia/
│   │   ├── config.qml          # Noctalia main config
│   │   └── widgets/
│   │       ├── README.md
│   │       ├── work/           # Work-mode widgets
│   │       └── gaming/         # Gaming-mode widgets
│   ├── ghostty/
│   │   └── config              # Ghostty terminal config
│   ├── starship/
│   │   └── starship.toml       # Shell prompt config
│   └── fastfetch/
│       └── config.jsonc        # System info display
├── scripts/
│   ├── create_widget.sh        # Widget scaffold generator
│   ├── toggle-gamemode.sh      # Gaming mode toggle
│   ├── audio-setup.sh          # PipeWire routing setup
│   ├── jarvis-manager.sh       # J.A.R.V.I.S. sound manager
│   ├── webapp-launcher.sh      # Webapp launcher helper
│   └── save-configs.sh         # Backup current configs
├── sounds/
│   ├── jarvis-startup.mp3
│   ├── jarvis-shutdown.mp3
│   ├── jarvis-notification.mp3
│   ├── jarvis-warning.mp3
│   ├── jarvis-gaming.mp3
│   └── jarvis-streaming.mp3
├── webapps/
│   ├── youtube.webapp
│   ├── twitch.webapp
│   ├── spotify.webapp
│   ├── discord.webapp
│   └── template.webapp
├── wallpapers/
│   └── (your wallpaper collection)
├── themes/
│   ├── gtk/
│   ├── qt/
│   └── colors/
├── plymouth/
│   └── wehttamsnaps-spinner/  # Custom boot theme
└── packages/
    ├── core.list               # Essential packages
    ├── gaming.list             # Gaming packages
    ├── photography.list        # Photo editing tools
    └── optional.list           # Nice-to-have packages
```
```markdown
### 🎨 Wallpaper Management

Download wallpapers from Wallhaven:

```bash
# Configure API key
wallpaper-manager.sh set-key YOUR_KEY

# Search and download
wallpaper-manager.sh search "nature"
wallpaper-manager.sh download-search

# Random wallpapers
wallpaper-manager.sh random 10

# Set via Noctalia
Mod + Shift + W
```

See `scripts/wallpaper-manager.sh` for full features.
```

---

## 🎯 Why This is Better Than Manual Downloads

### Before:
1. Go to Wallhaven website
2. Search wallpapers
3. Click each one
4. Download manually
5. Move to wallpapers folder
6. Set via Noctalia

### After:
```bash
wp search "cyberpunk neon"
wp download-search
# Enter: all

# Done! All wallpapers downloaded and ready in Noctalia
```

**Time saved:** ~30 seconds per wallpaper = 5 minutes for 10 wallpapers!

---

## 📦 Integration Points

### With Noctalia:
✅ Wallpapers auto-detected in `~/.config/wehttamsnaps/wallpapers/`  
✅ Can set via IPC: `qs -c noctalia-shell ipc call wallpaper set`  
✅ Works with Noctalia's wallpaper selector (`Mod + Shift + W`)  
✅ Compatible with Material You color generation
---

## 🎨 Popular Search Examples for Photography

```bash
# Landscape photography
wp search "landscape photography"
wp search "mountain sunset golden hour"
wp search "forest fog morning"

# Urban photography
wp search "street photography night"
wp search "architecture modern building"
wp search "urban cityscape"

# Nature macro
wp search "macro photography flowers"
wp search "water droplets close up"
wp search "insect macro detail"

# Minimalist
wp search "minimalist photography"
wp search "simple composition"
wp search "negative space"

# Your brand style
wp search "photography professional"
wp search "editorial photography"
wp search "commercial photography"
```

---

## 📂 File Structure

```
~/.config/wehttamsnaps/
├── scripts/
│   └── wallpaper-manager.sh ✅ NEW!
├── wallpaper-config.json ✅ NEW! (API key stored here)
└── wallpapers/ ✅ NEW! (Downloaded wallpapers)
    ├── 983651_1920x1080.jpg
    ├── 953847_2560x1440.jpg
    └── ...

~/.cache/wehttamsnaps/wallpapers/
├── last-search.json (Search results cache)
└── wallpaper-manager.log (Activity log)

docs/
└── WALLPAPER-MANAGER.md ✅ NEW!
```
---

## 🎮 Gaming Optimizations

### Supported Games (Pre-configured)
- Call of Duty HQ
- Cyberpunk 2077
- Fallout 4
- FarCry 5
- Ghost Recon Breakpoint
- Marvel's Avengers
- Need for Speed Payback
- Rise of the Tomb Raider
- Shadow of the Tomb Raider
- The First Descendant
- Tom Clancy's The Division 1 & 2
- Warframe
- Watch Dogs 1, 2, & Legion

### Performance Tips
1. **Enable Gamemode:** Automatic via launch options
2. **Use Gamescope:** Configured per-game
3. **Proton GE:** Latest version installed
4. **Mesa Optimizations:** Pre-configured for RX 580
5. **Disable Compositor Effects:** Gaming mode toggle

See `docs/GAMING.md` for detailed per-game configurations and troubleshooting.

---

## 🎨 Customization

### Change Theme
```bash
# Open Noctalia settings
Mod + Comma

# Navigate to Color Scheme
# Select predefined scheme or use wallpaper colors
```

### Add Custom Widget
```bash
# Run widget scaffold generator
./scripts/create_widget.sh my-widget-name

# Edit generated files in configs/noctalia/widgets/my-widget-name/
```

### Configure Audio Routing
```bash
# Launch qpwgraph
qpwgraph

# Or use automated setup
./scripts/audio-setup.sh
```

---

## 🔊 J.A.R.V.I.S. Integration

J.A.R.V.I.S. provides audio feedback for system events:

- **Startup:** "Allow me to introduce myself, I am JARVIS..."
- **Shutdown:** "Shutting down. Have a good day, Matthew."
- **Notifications:** "Matthew, you have a notification."
- **Gaming Mode:** "Gaming mode activated. Systems at maximum performance."
- **Streaming:** "Streaming systems online. All feeds operational."
- **Warnings:** Temperature alerts and system warnings

### Customize J.A.R.V.I.S.
Edit `scripts/jarvis-manager.sh` to add or modify sound triggers.

---

## 📸 Photography Workflow

Optimized window rules and keybindings for:
- **GIMP** – Full screen, workspace 3
- **Darktable** – Full screen, workspace 3
- **Inkscape** – Workspace 4
- **Blender** – Full screen, workspace 5

Quick access:
- `Mod + Shift + P` – Launch photo editor
- `Mod + Shift + D` – Darktable
- `Mod + Shift + G` – GIMP

---

## 🛠️ Troubleshooting

### Niri won't start
```bash
# Check logs
journalctl --user -u niri.service -f

# Validate config
niri validate
```

### Audio routing not working
```bash
# Restart PipeWire
systemctl --user restart pipewire pipewire-pulse wireplumber

# Re-run audio setup
./scripts/audio-setup.sh
```

### Gaming performance issues
```bash
# Check Proton version
protonup-qt

# Verify Mesa drivers
vulkaninfo | grep "deviceName"

# Enable performance mode
./scripts/toggle-gamemode.sh on
```

See `docs/TROUBLESHOOTING.md` for more solutions.

---

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

---

## 📜 License

MIT License – See LICENSE file for details.

---

## 🙏 Credits

- **Noctalia Shell** – [noctalia-dev](https://github.com/noctalia-dev/noctalia-shell)
- **Omarchy** – Workflow inspiration
- **JaKooLit** – Theming concepts
- **Chris Titus** – Linutil tool
- **Community** – Arch Linux, Niri, and PipeWire communities

---

## 📞 Contact

- **Twitch:** [twitch.tv/WehttamSnaps](https://twitch.tv/WehttamSnaps)
- **YouTube:** [youtube.com/@WehttamSnaps](https://youtube.com/@WehttamSnaps)
- **GitHub:** [github.com/Crowdrocker](https://github.com/Crowdrocker)

---

**Made with ❤️ by WehttamSnaps**
