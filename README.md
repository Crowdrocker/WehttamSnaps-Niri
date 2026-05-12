# WehttamSnaps for SwayFx - Getting Started

> **Windows 11 Dark Theme** | **Gaming Optimized** | **Photography Ready** | **Audio Perfect**

**Status**: ✅ Ready to Use  
**Last Updated**: 2026-05-12  
**Tested**: CachyOS + Arch Linux with RX 580

---

## 🚀 Quick Start (5 Minutes)

### Fresh CachyOS Install

```bash
# Clone repository
git clone https://github.com/Crowdrocker/WehttamSnaps-Niri.git -b swayfx-migration
cd WehttamSnaps-Niri

# Run migration (fully automated!)
chmod +x migrate-to-swayfx.sh
./migrate-to-swayfx.sh --full --force

# Login to SwayFx and enjoy!
```

### Migrating from Niri

```bash
cd ~/WehttamSnaps-Niri
git checkout swayfx-migration
./migrate-to-swayfx.sh --full

# Your PipeWire audio is AUTOMATICALLY PRESERVED! ✅
```

---

## 📖 Documentation

- **[INSTALL-CACHYOS.md](INSTALL-CACHYOS.md)** - Complete installation guide (fresh install, migration, examples)
- **[CONFIGURATION.md](CONFIGURATION.md)** - Config reference (edit gaps, keybinds, themes, etc.)

---

## ✨ Features

✅ **Windows 11 Dark** - Authentic Fluent Design theme  
✅ **Gaming** - Proton GE, gamescope, performance optimized  
✅ **Photography** - Workspace 2 optimized for editing  
✅ **Audio** - PipeWire routing (games/browser/Discord separate)  
✅ **J.A.R.V.I.S.** - Audio feedback integration  
✅ **Taskbar** - Bottom panel with system tray (like Windows 11)  
✅ **Modular Config** - Easy to customize  
✅ **Quickshell** - ii shell adapted for SwayFx  

---

## 📊 What's Included

```
WehttamSnaps-SwayFx
├── migrate-to-swayfx.sh        (1700+ lines of automation)
├── INSTALL-CACHYOS.md          (Complete guide + 10 examples)
├── CONFIGURATION.md            (Config reference)
├── README.md                   (This file)
└── [Config files auto-generated]
    ├── ~/.config/sway/         (Main SwayFx config)
    ├── ~/.config/waybar/       (Bottom taskbar)
    ├── ~/.config/pipewire/     (Audio - PRESERVED!)
    ├── ~/.config/mako/         (Notifications)
    └── ~/.local/share/sounds/  (J.A.R.V.I.S. sounds)
```

---

## 🎯 Migration Options

```bash
# Interactive (recommended for first time)
./migrate-to-swayfx.sh

# Test without making changes
./migrate-to-swayfx.sh --dry-run

# Backup only
./migrate-to-swayfx.sh --backup-only

# Fully automated
./migrate-to-swayfx.sh --full --force
```

---

## 🔧 First Steps After Installation

### 1. Test Audio

```bash
speaker-test -c 2 -l 1      # Test speakers
qpwgraph &                  # Visual audio routing
```

### 2. Configure Your Workspace

Edit `~/.config/sway/snaps/99-overrides.conf`:

```bash
# Add your apps
bindsym $mod+w exec firefox
bindsym $mod+e exec code
bindsym $mod+d exec discord
```

### 3. Install Optional Apps

```bash
# Photography
sudo pacman -S darktable gimp rawtherapee

# Gaming
sudo pacman -S steam lutris
# Proton GE: yay -S proton-ge-custom-bin

# Development
sudo pacman -S code git python
```

### 4. Reload Configuration

```bash
swaymsg reload
```

---

## 🎮 Gaming Setup

```bash
# Toggle gaming mode (disables effects for performance)
~/.config/sway/scripts/toggle-gamemode.sh on

# Your steam launch options are ready!
# Steam → Game Properties → Launch Options
# Copy from: ~/.config/sway/scripts/steam-launch-options.sh

# Supported games: 16+ pre-configured with optimizations
```

---

## 🎨 Customization

### Change Colors

Edit `~/.config/sway/themes/windows11-dark.conf`:

```bash
set $accent #0078d4          # Windows blue
set $bg #0c0c0c              # Almost black
set $text #e0e0e0            # Light gray
```

### Adjust Gaps

Edit `~/.config/sway/snaps/00-base.conf`:

```bash
gaps inner 12                # Space between windows
gaps outer 0                 # Space at edges
corner_radius 8              # Round corners
```

### Add Keybindings

Edit `~/.config/sway/snaps/99-overrides.conf`:

```bash
bindsym $mod+Return exec foot
bindsym $mod+w exec firefox
bindsym Print exec grimshot copy area
```

---

## 🆘 Need Help?

### Check Status

```bash
# Audio
wpctl status

# GPU
glxinfo | grep Device

# Logs
journalctl -u sway --user -n 20
```

### Common Fixes

| Problem | Solution |
|---------|----------|
| Audio crackling | `systemctl --user restart pipewire` |
| GPU not detected | `sudo pacman -S linux-firmware` |
| Keybind not working | Check config: `swaymsg -t get_config` |
| High CPU | Disable blur: `blur disable` in config |

---

## 📚 Full Documentation

- See **[INSTALL-CACHYOS.md](INSTALL-CACHYOS.md)** for:
  - Fresh install steps
  - Migration from Niri
  - 10+ configuration examples
  - Troubleshooting guide

- See **[CONFIGURATION.md](CONFIGURATION.md)** for:
  - Detailed config reference
  - How to edit each file
  - Advanced configuration

---

## 🌟 What's New in SwayFx vs Niri

| Feature | Niri | SwayFx |
|---------|------|--------|
| **Compositor** | Tiling (columns) | Tiling (i3-style) |
| **IPC** | Niri custom | Sway standard |
| **Taskbar** | Top (Quickshell ii) | Bottom (Waybar) |
| **Theme** | Custom gradients | Standard borders |
| **Audio** | PipeWire ✅ | PipeWire ✅ |
| **Gaming** | Optimized | Optimized |
| **Quickshell** | Full ii shell | ii shell adapted |

---

## ✅ Migration Checklist

- [ ] Clone repository
- [ ] Run migration script
- [ ] Test audio (`speaker-test`)
- [ ] Test gaming
- [ ] Configure personal shortcuts
- [ ] Install preferred applications
- [ ] Enjoy! 🎉

---

## 🔗 Links

- **GitHub**: https://github.com/Crowdrocker/WehttamSnaps-Niri
- **SwayFx**: https://github.com/swaywm/sway
- **Quickshell**: https://quickshell.outfoxxed.me/
- **CachyOS**: https://cachyos.org/

---

## 💡 Tips

- **First time?** Start with `./migrate-to-swayfx.sh --dry-run` to see what will happen
- **Backup first?** Use `./migrate-to-swayfx.sh --backup-only` to create backup
- **Want defaults?** Just run `./migrate-to-swayfx.sh --full --force`
- **Audio preserved?** Yes! Your PipeWire routing is automatically restored

---

## 📞 Support

**Issues?** Check:
1. **INSTALL-CACHYOS.md** - Troubleshooting section
2. **CONFIGURATION.md** - Config reference
3. **GitHub Issues** - Search existing solutions
4. **Logs** - `journalctl -u sway --user -n 50`

---

**Ready to get started? → [INSTALL-CACHYOS.md](INSTALL-CACHYOS.md)** 🚀
