<div align = center>
  
<a href="https://discord.gg/9bAVTCNZ">
    <img alt="Dynamic JSON Badge" src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FnTaknDvdUA%3Fwith_counts%3Dtrue&query=%24.approximate_member_count&suffix=%20members&style=for-the-badge&logo=discord&logoSize=auto&label=WehttamSnaps%20Community&labelColor=ebbcba&color=8A2BE2">
</a>

<p align="center">
  <img src="https://github.com/Crowdrocker/WehttamSnaps-Niri/blob/main/assets/latte.png" width="400" />
</p>

<h3 align="center">
<img align="center" width="80%" src=https://github.com/Crowdrocker/WehttamSnaps-Niri/blob/main/assets/github-header.png />
</h3>

<p align="center">
  <img src="https://github.com/Crowdrocker/WehttamSnaps-Niri/blob/main/assets/latte.png" width="400" />
</p>

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1?logo=arch-linux&logoColor=white)
![Niri](https://img.shields.io/badge/WM-Niri-89b4fa)
![License](https://img.shields.io/badge/license-MIT-green)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen)
![Stars](https://img.shields.io/github/stars/Crowdrocker/WehttamSnaps-Niri?style=social)

 
[![Twitch](https://img.shields.io/badge/Twitch-WehttamSnaps-9146FF?style=for-the-badge&logo=twitch)](https://www.twitch.tv/wehttamsnaps)
[![YouTube](https://img.shields.io/badge/YouTube-WehttamSnaps-FF0000?style=for-the-badge&logo=youtube)](https://www.youtube.com/@WehttamSnaps)
[![GitHub](https://img.shields.io/badge/GitHub-Crowdrocker-181717?style=for-the-badge&logo=github)](https://github.com/Crowdrocker)

</div>

</div><br>

<div align="center">
  
<a href="#Overview"><kbd> <br> Overview <br> </kbd></a>&ensp;&ensp;
<a href="#Screenshots"><kbd> <br> Screenshots <br> </kbd></a>&ensp;&ensp;
<a href="#Whatisthis"><kbd> <br> Whatisthis <br> </kbd></a>&ensp;&ensp;
<a href="#Documentation"><kbd> <br> Documentation <br> </kbd></a>&ensp;&ensp;
<a href="#QuickInstall"><kbd> <br> QuickInstall <br> </kbd></a>&ensp;&ensp;
<a href="#Updating"><kbd> <br> Updating <br> </kbd></a>&ensp;&ensp;
<a href="#Keybinds"><kbd> <br> Keybinds <br> </kbd></a>&ensp;&ensp;
<a href="#Troubleshooting"><kbd> <br> Troubleshooting <br> </kbd></a>&ensp;&ensp; 
<a href="#Credits"><kbd> <br> Credits <br> </kbd></a>&ensp;&ensp; 

<br/>
</div>

<div align="center">

![GitHub Repo stars](https://img.shields.io/github/stars/Crowdrocker/WehttamSnaps-Niri?style=for-the-badge&color=cba6f7) ![GitHub last commit](https://img.shields.io/github/last-commit/Crowdrocker/WehttamSnaps-Niri?style=for-the-badge&color=b4befe) 

<br/>
</div>

<h3 align="center">
  <img src="https://github.com/Crowdrocker/Telegram-Animated-Emojis/blob/main/Activity/Video%20Game.webp" alt="Game" width="38" height="38" />
  Arch Linux configuration optimized for photography, gaming, and content creation.
  <img src="https://github.com/Crowdrocker/Telegram-Animated-Emojis/blob/main/People/Thumbs%20Up.webp" alt="Up" width="38" height="38" />
</h3>

<a id="Overview"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=Overview" width="450"/>

This repository contains a complete, modular Niri configuration featuring:

A Quickshell shell for Niri. Fork of end-4's illogical-impulse, butchered to work on a different compositor.

> [!CAUTION]
> **Hey.** This is my personal rice. I put effort into it, but it's not a product - don't expect hand-holding or stability guarantees. If you're just here because "it looks cool" and have no clue what Niri even is, maybe check out something more beginner-friendly first. Your system, your responsibility.

> **Heads up:** almost everything here is configurable. Modules, colors, fonts, animations - if something bugs you, there's probably a toggle for it. Hit `Super+,` for settings before you rage-quit.

- **J.A.R.V.I.S. Integration** – Immersive AI assistant theme with custom sounds
- **Photography Workflow** – Optimized for photo editing and content creation
- **Gaming Performance** – Tuned for RX 580 with Proton GE configurations
- **Audio Routing** – PipeWire + qpwgraph for advanced audio control
- **Custom Branding** – WehttamSnaps theme throughout
---

## 🖥️ System Architecture Specs

| Component | Target Hardware Specification |
| :--- | :--- |
| **CPU** | AMD Ryzen 5 9600X (6 Cores / 12 Threads) |
| **GPU** | XFX Speedster SWFT210 Radeon RX 7600 (8GB VRAM) |
| **RAM** | 16GB DDR5 (Upgrading to 32GB Dual-Channel) |
| **PSU** | EVGA 850W Modular Power Supply |
| **Chassis** | HYTE Y60 (White with Black Trim, Panoramic Glass) |
| **Displays** | **Main:** Samsung 4K (Configured to 1920x1080 @ 60Hz)<br>**Left:** Native 1080p @ 60Hz |

---

## 🗃️ Modular Configuration Matrix (`snaps/`)

To prevent monolith configuration decay, my main Niri `config.kdl` parses modular file segments sequentially:

*   📁 **`00-base.kdl`**: Root environment limits, 1:1 flat mouse tracking configuration, and XWayland scale handling.
*   📁 **`05-wiri_startup.kdl`**: Autostart system bridges (`xwayland-satellite`), secure storage auto-mounters, GNOME Polkit agents, and background scripts.
*   📁 **`10-wiri_keybinds.kdl`**: Keyboard layout mappings (Vim-style navigation) and J.A.R.V.I.S automation execution hooks.
*   📁 **`20-wiri_rules.kdl`**: Precise window geometry bounds and floating rules for modding infrastructure (Vortex, MO2, xEdit, SteamTinkerLaunch).
*   📁 **`30-workspaces.kdl`**: Monitored desktop layouts splitting peripheral applications to the left screen and full-screen environments to the center display.
*   📁 **`40-gaming.kdl`**: Exclusive full-screen application sandboxing rules utilizing `gamescope`.
*   📁 **`99-overrides.kdl`**: Absolute layout overrides pinning coordinate geometry planes for my dual 1080p display matrix.

---

## 🎵 J.A.R.V.I.S Audio Routing Matrix

System audio streams are parsed cleanly into isolated virtual lines using PipeW
📸<a id="Screenshots"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=Screenshots" width="450"/>
### Material ii

| Overview | Sidebars |
|:---|:---|
| ![Overview](https://github.com/user-attachments/assets/9faaad0e-a665-4747-9428-ea94756e1f0f) | ![Sidebars](https://github.com/user-attachments/assets/21e43f3e-d6d9-4625-8210-642f9c05509b) |

| Overlay/Search | Settings |
|:---|:---|
| ![Settings](https://github.com/user-attachments/assets/25700a1c-70e6-4456-b053-35cf83fcac7a) | ![Overlay](https://github.com/user-attachments/assets/1d5ca0f0-6ffb-46da-be1a-2d5e494089e7) |

### Waffle (Windows 11 style)

| Quick Settings | Start Menu + Widgets |
|:---|:---|
| ![Waffle Start](https://github.com/user-attachments/assets/5c5996e7-90eb-4789-9921-0d5fe5283fa3) | ![Waffle Settings](https://github.com/user-attachments/assets/fadf9562-751e-4138-a3a1-b87b31114d44) |

---

✨ <a id="Whatisthis"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=Whatisthis" width="450"/>

A shell. Bar at the top, sidebars on the sides, overlays that pop up when you press keys. The usual.

- **Bar** - clock, workspaces, tray, the stuff you expect
- **Sidebars** - left one has AI chat and wallpaper browser, right one has quick toggles and a notepad
- **Overview** - workspace grid, adapted for Niri's scrolling model
- **Alt+Tab** - window switcher that actually works across workspaces
- **Clipboard** - history panel with search (needs cliphist)
- **Region tools** - screenshots, screen recording, OCR, reverse image search
- **Wallpaper** - picker, video support, and matugen pulls colors from whatever you set
- **Theming** - presets like Gruvbox and Catppuccin, or build your own with the custom theme editor. Fonts are customizable too
- **Settings** - GUI config with search, so you don't have to edit JSON like a caveman
- **GameMode** - fullscreen app? Effects go bye-bye. Your games won't stutter
- **Idle** - screen off, lock, suspend timeouts. swayidle handles it, you configure it
- **Gamemode + Gamescope** – Performance optimization
- **Proton GE** – Enhanced game compatibility
- **Steam Launch Options** – Pre-configured for 16 games
- **Mod Manager Support** – Window rules for Vortex, MO2, Wabbajack

### Audio
- **PipeWire Routing** – Separate audio channels (game, browser, Discord, Spotify)
- **qpwgraph** – Visual audio routing like VoiceMeter
- **J.A.R.V.I.S. Sounds** – System event audio notifications

### Two flavors, one shell

Can't decide on a look? Good news, you don't have to.

- **Material ii** - The OG. Floating bar, sidebars, that Material Design aesthetic.
- **Waffle** - Taskbar at the bottom, action center, tray overflow. For the "I kinda miss Windows" crowd.

Press `Mod+Shift+W` to cycle between styles, or go to Settings → Modules to mix and match.

---

  
🎮<a id="Gaming Optimizations"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=GamingOptimizations" width="450"/>
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

See [docs/GAMING.md](docs/GAMING.md) for detailed per-game configurations and troubleshooting.

```

### Configure Audio Routing
```bash
# Launch qpwgraph
qpwgraph

# Or use automated setup
./scripts/audio-setup.sh
```

---


🔊<a id="J.A.R.V.I.S. Integration"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=J.A.R.V.I.S.Integration" width="450"/>
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

📦<a id="Documentation"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=Documentation" width="450"/>
Read these or suffer.

| Doc | What's in it |
|-----|--------------|
| [docs/INSTALL.md](docs/INSTALL.md) | How to install this thing |
| [docs/PACKAGES.md](docs/PACKAGES.md) | Every package the installer uses, by category |
| [docs/KEYBINDS.md](docs/KEYBINDS.md) | Default keyboard shortcuts |
| [docs/IPC.md](docs/IPC.md) | All IPC targets for custom keybindings |
| [docs/SETUP.md](docs/SETUP.md) | How the setup script works, updates, uninstall |
| [docs/LIMITATIONS.md](docs/LIMITATIONS.md) | Known limitations and what doesn't work |

---

<a id="QuickInstall"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=QuickInstall" width="450"/>
Arch-based? Run this:

```bash
git clone https://github.com/Crowdrocker/WehttamSnaps-Niri.git
cd WehttamSnaps-Niri
./setup install -y
```

Not on Arch? Check [docs/INSTALL.md](docs/INSTALL.md) for manual steps.

---


<a id="Updating"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=Updating" width="450"/>
Already installed? Pull and sync:

```bash
cd WehttamSnaps-Niri
git pull
./setup update
```

Syncs QML and configs. Your customizations stay. Missing keybinds get added. Hot reload does the rest.

---

## (the important ones)
🎹<a id="Keybinds"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=Keybinds" width="450"/>
These come configured by default:

| Key | What it does |
|-----|--------------|
| `Mod+Tab` | Niri overview (native) |
| `Mod+Space` (`Super+Space`) | ii overview (search/workspaces nav) |
| `Alt+Tab` | ii window switcher |
| `Super+G` | ii overlay ( widgets/utils) |
| `Super+V` | Clipboard history |
| `Super+Shift+S` | Region screenshot |
| `Super+Shift+X` | Region OCR |
| `Ctrl+Alt+T` | Wallpaper picker |
| `Super+/` | Keyboard shortcuts cheatsheet |
| `Super+,` | Settings |
| `Mod+Shift+W` | Cycle panel style (Material ↔ Waffle) |

Full list in [docs/KEYBINDS.md](docs/KEYBINDS.md).

---

## IPC (for nerds who want custom bindings)

ii exposes IPC targets you can bind to whatever keys you want. Syntax:

```kdl
bind "Key" { spawn "qs" "-c" "ii" "ipc" "call" "<target>" "<function>"; }
```

Main targets:

| Target | Functions |
|--------|-----------|
| `overview` | `toggle` |
| `overlay` | `toggle` |
| `clipboard` | `toggle`, `open`, `close` |
| `altSwitcher` | `next`, `previous`, `toggle` |
| `region` | `screenshot`, `ocr`, `search`, `record` |
| `session` | `toggle` |
| `lock` | `activate` |
| `cheatsheet` | `toggle` |
| `settings` | `open` |
| `sidebarLeft` | `toggle` |
| `sidebarRight` | `toggle` |
| `wallpaperSelector` | `toggle` |
| `panelFamily` | `cycle`, `set` |
| `mpris` | `playPause`, `next`, `previous` |
| `brightness` | `increment`, `decrement` |
| `gamemode` | `toggle`, `activate`, `deactivate`, `status` |
| `notifications` | `test`, `clearAll`, `toggleSilent` |
| `audio` | `volumeUp`, `volumeDown`, `mute`, `micMute` |

Full reference with examples: [docs/IPC.md](docs/IPC.md)

---


🛠️<a id="Troubleshooting"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=Troubleshooting" width="450"/>
Something broke? Shocking.

```bash
# Check the logs
qs log -c ii

# Restart ii without restarting Niri
qs kill -c ii && qs -c ii

# Nuclear option: reload everything
niri msg action load-config-file
```
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

If you're still stuck, the logs usually tell you what's missing. Usually.

---

## Fair warning

This is my daily driver. It works. Most of the time. I break things when I'm bored.

This fork diverged a lot from the original - different compositor, different features, different bugs. If you want the Hyprland version, check out end-4's original.

---


🙏<a id="Credits"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=Credits" width="450"/>
- [**end-4**](https://github.com/end-4/dots-hyprland) –  illogical-impulse for Hyprland
- [**Quickshell**](https://quickshell.outfoxxed.me/) – the framework that makes this possible
- [**snowarch**](https://github.com/snowarch) – Theming concepts
- [**Chris Titus**](https://github.com/YaLTeR/niri) – Linutil tool
- [**Community**](https://github.com/YaLTeR/niri) – Arch Linux, Niri, and PipeWire communities

---

## 📞 Contact

- **Twitch:** [twitch.tv/WehttamSnaps](https://twitch.tv/WehttamSnaps)
- **YouTube:** [youtube.com/@WehttamSnaps](https://youtube.com/@WehttamSnaps)
- **GitHub:** [github.com/Crowdrocker](https://github.com/Crowdrocker)

---

Made with ❤️ by WehttamSnaps If you found this helpful, please consider giving it a star! It helps others discover this project.

[![Star History Chart](https://api.star-history.com/svg?repos=Crowdrocker/WehttamSnaps-Niri&type=date&legend=top-left)](https://www.star-history.com/#Crowdrocker/WehttamSnaps-Niri&type=date&legend=top-left)
