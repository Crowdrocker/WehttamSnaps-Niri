# Complete Installation Guide: WehttamSnaps-SwayFx on CachyOS

> **Fresh Install Guide** | **Migration from Niri** | **10+ Configuration Examples** | **Troubleshooting**

**Last Updated**: 2026-05-12  
**Tested**: CachyOS 240515 + Arch Linux  
**Hardware**: Dell XPS 8700 (i7-4790, RX 580)

---

## 📋 Table of Contents

1. [Fresh CachyOS Install](#-fresh-cachyos-install)
2. [Migration from Niri](#-migration-from-niri)
3. [Post-Installation Setup](#-post-installation-setup)
4. [Configuration Examples](#-configuration-examples-10)
5. [Gaming Setup](#-gaming-setup)
6. [Photography Workflow](#-photography-workflow)
7. [Audio Routing](#-audio-routing)
8. [Troubleshooting](#-troubleshooting)
9. [Commands Reference](#-commands-reference)

---

## 🖥️ Fresh CachyOS Install

### Step 1: Install CachyOS

```bash
# Download CachyOS ISO from: https://cachyos.org/download/
# Create bootable USB and install

# During installation:
# 1. Choose minimal base
# 2. Select Btrfs or EXT4
# 3. Install GRUB bootloader
# 4. Reboot into new system
```

### Step 2: Update System

```bash
sudo pacman -Syu
sudo pacman -S base-devel git
```

### Step 3: Clone Repository

```bash
git clone https://github.com/Crowdrocker/WehttamSnaps-Niri.git -b swayfx-migration
cd WehttamSnaps-Niri
```

### Step 4: Run Migration Script

```bash
# Make executable
chmod +x migrate-to-swayfx.sh

# Option A: Fully automated (recommended for fresh install)
./migrate-to-swayfx.sh --full --force

# Option B: Interactive (prompts for confirmation)
./migrate-to-swayfx.sh

# Option C: Test first (no changes)
./migrate-to-swayfx.sh --dry-run
```

### Step 5: Configure SwayFx

The script creates configurations at:
- `~/.config/sway/` - Main config
- `~/.config/waybar/` - Taskbar
- `~/.config/pipewire/` - Audio

Edit as needed (see [Configuration Examples](#-configuration-examples-10))

### Step 6: Start SwayFx

```bash
# At login screen:
# 1. Select user
# 2. Choose "sway" from session menu
# 3. Enter password
# 4. Enjoy!

# Or from command line:
exec sway
```

---

## 🔄 Migration from Niri

### Prerequisites

```bash
# Ensure you have Niri config
ls ~/.config/niri/              # Should exist

# Ensure git is installed
git --version

# Ensure you have space for backup
df -h ~                         # Need ~500MB free
```

### Migration Steps

```bash
# Navigate to Niri config
cd ~/WehttamSnaps-Niri

# Update repository
git fetch origin
git checkout swayfx-migration

# Run migration
chmod +x migrate-to-swayfx.sh

# Option A: Full migration (automatic)
./migrate-to-swayfx.sh --full --force

# Option B: Interactive
./migrate-to-swayfx.sh

# Option C: Test first
./migrate-to-swayfx.sh --dry-run

# Option D: Backup only
./migrate-to-swayfx.sh --backup-only
```

### What Happens

✅ **Backed Up**:
- Your Niri config → `~/WehttamSnaps-SwayFx-Backup-[timestamp]/niri-config/`
- Quickshell config → `~/WehttamSnaps-SwayFx-Backup-[timestamp]/quickshell-config/`
- PipeWire config → `~/WehttamSnaps-SwayFx-Backup-[timestamp]/pipewire-config/`

✅ **Created**:
- SwayFx config → `~/.config/sway/`
- Waybar taskbar → `~/.config/waybar/`
- Helper scripts → `~/.config/sway/scripts/`
- Windows 11 theme → `~/.config/sway/themes/`

✅ **Preserved**:
- PipeWire audio routing → AUTOMATICALLY RESTORED!
- Wireplumber config → AUTOMATICALLY RESTORED!
- Gaming scripts → Available in `~/.config/sway/scripts/`

### Switch to SwayFx

After migration, reboot or:
```bash
pkill niri                      # Stop Niri
exec sway                       # Start SwayFx
```

---

## ⚙️ Post-Installation Setup

### 1. Install Essential Packages

```bash
# Core packages
sudo pacman -S swayfx swaybg swayidle swaylock wl-clipboard foot

# Audio
sudo pacman -S pipewire pipewire-pulse wireplumber qpwgraph

# Gaming
sudo pacman -S steam proton-ge-custom-bin gamescope

# Quickshell (if not already installed)
sudo pacman -S qt6-wayland qt6-declarative
yay -S quickshell

# Utilities
sudo pacman -S rofi cliphist mako swaync brightnessctl

# Optional: Photography
sudo pacman -S darktable gimp rawtherapee

# Optional: Development
sudo pacman -S code git python3 neovim
```

### 2. Test Audio

```bash
# List audio devices
wpctl status

# Test speakers
speaker-test -c 2 -l 1

# Launch visual audio router
qpwgraph &
```

### 3. Test Gaming

```bash
# Check GPU
glxinfo | grep Device
vulkaninfo | grep deviceName

# Test Proton
steam --version

# Check if ProtonGE is installed
ls ~/.steam/root/compatibilitytools.d/
```

### 4. Verify Everything

```bash
# Check SwayFx
swaymsg --version

# Check Waybar
waybar --version

# Check PipeWire
pipewire --version

# Check Quickshell
qs --version
```

---

## 🎯 Configuration Examples (10+)

### Example 1: Two-Monitor Setup

**File**: `~/.config/sway/snaps/30-workspaces.conf`

```bash
# Monitor 1 (DisplayPort)
output "DP-1" {
    mode 2560x1440@144Hz
    position 0,0
    scale 1.0
}

# Monitor 2 (HDMI)
output "HDMI-A-1" {
    mode 1920x1080@60Hz
    position 2560,0              # Right of DP-1
    scale 1.0
}

# Assign workspaces
workspace 1 output "DP-1"
workspace 2 output "DP-1"
workspace 3 output "DP-1"
workspace 4 output "DP-1"
workspace 5 output "HDMI-A-1"
workspace 6 output "HDMI-A-1"
```

### Example 2: Photography Workflow

**File**: `~/.config/sway/snaps/20-rules.conf`

```bash
# Open Darktable in workspace 2, no gaps, no decorations
for_window [app_id="darktable"] {
    workspace 2
    fullscreen enable
}

# GIMP in floating window, keep window decorations
for_window [app_id="gimp"] {
    workspace 2
    floating enable
    resize set 80 ppt 80 ppt
}

# Krita tablets support
for_window [app_id="krita"] {
    workspace 3
    fullscreen disable
}
```

Reload: `swaymsg reload`

### Example 3: Gaming Configuration

**File**: `~/.config/sway/snaps/40-gaming.conf`

```bash
# Launch Steam games with gaming mode on
for_window [class="steam"] {
    workspace 5
    floating enable
}

# Lutris games
for_window [app_id="lutris"] {
    workspace 5
}

# No gaps in gaming workspace
workspace 5 gaps inner 0

# Custom launch binding
bindsym $mod+g exec "~/.config/sway/scripts/toggle-gamemode.sh on && steam"
```

### Example 4: Custom Keybindings

**File**: `~/.config/sway/snaps/99-overrides.conf`

```bash
# Terminal shortcuts
bindsym $mod+Return exec $term
bindsym $mod+Shift+Return exec $term --fullscreen

# Application launchers
bindsym $mod+w exec firefox
bindsym $mod+e exec code
bindsym $mod+d exec discord

# Workspace jumping
bindsym $mod+1 workspace 1
bindsym $mod+2 workspace 2
bindsym $mod+3 workspace 3
bindsym $mod+4 workspace 4
bindsym $mod+5 workspace 5

# Screenshot
bindsym Print exec grimshot copy area
bindsym Shift+Print exec grimshot save area ~/Pictures/screenshot-$(date +%s).png

# Volume control (if not working)
bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +5%'
bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -5%'
bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'

# Brightness control
bindsym XF86MonBrightnessUp exec 'brightnessctl set +5%'
bindsym XF86MonBrightnessDown exec 'brightnessctl set 5%-'
```

### Example 5: Disable Blur (Performance)

**File**: `~/.config/sway/snaps/00-base.conf`

```bash
# Disable blur for better performance
blur disable

# Or reduce blur intensity
blur enable
blur_passes 1           # Default: 2
blur_radius 3           # Default: 5
```

Reload: `swaymsg reload`

### Example 6: Adjust Gaps & Borders

**File**: `~/.config/sway/snaps/00-base.conf`

```bash
# Productivity - minimal gaps
gaps inner 4
gaps outer 0
default_border pixel 1

# Gaming - no gaps
workspace 5 {
    gaps inner 0
    gaps outer 0
    default_border pixel 0
}

# Corner radius (rounded corners)
corner_radius 8             # Pixels
corner_radius 0             # Disable rounding
```

### Example 7: Dark Mode + Custom Colors

**File**: `~/.config/sway/themes/windows11-dark.conf`

```bash
# Windows 11 Dark theme (default)
set $bg       #0c0c0c          # Almost black
set $surface  #1e1e1e          # Dark gray
set $overlay  #2d2d30          # Slightly lighter gray
set $text     #e0e0e0          # Light gray
set $accent   #0078d4          # Windows blue

# Or switch to Dracula
# set $bg       #282a36
# set $surface  #44475a
# set $overlay  #6272a4
# set $text     #f8f8f2
# set $accent   #bd93f9
```

Then restart SwayFx for changes to take effect.

### Example 8: Touchpad Configuration

**File**: `~/.config/sway/snaps/00-base.conf`

```bash
input "type:touchpad" {
    tap enabled                 # Tap to click
    natural_scroll enabled       # Inverted scrolling (Mac-style)
    pointer_accel 0.5           # Sensitivity (-1 to 1)
    accel_profile adaptive       # Or: flat
}

# For trackpoint (laptop pointing stick)
input "type:pointer" {
    pointer_accel 0.3           # Slower than touchpad
}
```

### Example 9: Keyboard Layout Switching

**File**: `~/.config/sway/snaps/00-base.conf`

```bash
input "type:keyboard" {
    xkb_layout "us,de"          # US + German
    xkb_options "grp:alt_caps_toggle"  # Alt+Caps to switch
}

# Or just single layout
input "type:keyboard" {
    xkb_layout de               # German only
}

# And enable numlock on startup
input "type:keyboard" {
    numlock enabled
}
```

### Example 10: Auto-launch Applications

**File**: `~/.config/sway/snaps/99-overrides.conf`

```bash
# Launch on startup
exec --no-startup-id firefox
exec --no-startup-id discord --start-minimized
exec --no-startup-id keepass

# Background daemon
exec ~/.config/sway/scripts/my-daemon.sh &

# With delay (wait for system to settle)
exec sleep 2 && code
```

---

## 🎮 Gaming Setup

### Install Proton GE

```bash
# Method 1: AUR
yay -S proton-ge-custom-bin

# Method 2: Manual
mkdir -p ~/.steam/root/compatibilitytools.d
cd ~/.steam/root/compatibilitytools.d
# Download latest from: https://github.com/GloriousEggroll/proton-ge-custom/releases
# Extract here
```

### Launch Options (Pre-configured)

Your launch options are in `~/.config/sway/scripts/steam-launch-options.sh`

**Supported games** (16+ pre-configured):
- Cyberpunk 2077
- Call of Duty HQ
- Fallout 4
- Fortnite
- Valorant
- Warframe
- Elden Ring
- And 10+ more

### Enable Gaming Mode

```bash
# Toggle gaming mode (disables effects, maximizes performance)
~/.config/sway/scripts/toggle-gamemode.sh on

# Play your game
# Steam -> Properties -> Launch Options -> Copy from script

# Disable gaming mode after
~/.config/sway/scripts/toggle-gamemode.sh off
```

---

## 📸 Photography Workflow

### Recommended Workspace Setup

**Workspace 2** - Dedicated to photography

```bash
# Automatically open in workspace 2
for_window [app_id="darktable"] workspace 2
for_window [app_id="gimp"] workspace 2
for_window [app_id="krita"] workspace 2

# No gaps for more space
workspace 2 gaps inner 0
```

### Install Tools

```bash
# Photography suite
sudo pacman -S darktable gimp rawtherapee

# Optional
sudo pacman -S geeqie                # Image viewer
sudo pacman -S krita                 # Digital painting
```

### Configure Darktable

```bash
# Launch Darktable in workspace 2
bindsym $mod+Shift+d exec 'swaymsg workspace 2 && darktable'

# Full workspace for editing
for_window [app_id="darktable"] fullscreen enable
```

---

## 🔊 Audio Routing

### Verify Audio Setup

```bash
# Check audio devices
wpctl status

# Your audio should show:
# ├─ Sinks (speakers)
# │  └─ alsa_output.* (your device)
# └─ Sources (microphones)
```

### Visual Audio Routing

```bash
# Launch qpwgraph for drag-and-drop routing
qpwgraph &

# Route different apps:
# - Firefox → one sink
# - Discord → another sink
# - Games → third sink
# etc.
```

### Command-line Routing

```bash
# Set default audio device
wpctl set-default-sink alsa_output.pci-0000_07_00.1.analog-stereo

# List all sinks
pactl list sinks

# Route specific app
# Use PipeWire's pw-link or PulseAudio's pacmd
```

---

## 🆘 Troubleshooting

### Issue: Audio not working

```bash
# 1. Restart PipeWire
systemctl --user restart pipewire pipewire-pulse wireplumber

# 2. Check default device
wpctl get-default-sink

# 3. Test audio
speaker-test -c 2 -l 1

# 4. Check logs
journalctl -u pipewire -n 50
```

### Issue: Keybindings not working

```bash
# 1. Check if keybinding is defined
swaymsg -t get_config | grep "your_key"

# 2. Find correct key name
wev                             # Press the key

# 3. Verify syntax in config
swayfx -c ~/.config/sway/config -C

# 4. Reload
swaymsg reload
```

### Issue: GPU not detected

```bash
# 1. Check drivers
glxinfo | grep Device

# 2. Install firmware
sudo pacman -S linux-firmware

# 3. Check kernel logs
journalctl -b | grep -i gpu
```

### Issue: High CPU usage

```bash
# 1. Disable blur
blur disable

# 2. Reduce blur passes
blur_passes 1

# 3. Disable animations (in Quickshell)

# 4. Check running processes
top
```

### Issue: Games running slow

```bash
# 1. Enable gaming mode
~/.config/sway/scripts/toggle-gamemode.sh on

# 2. Check performance governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 3. Set to performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 4. Monitor temperatures
radeontop                       # For AMD GPU
```

---

## 📚 Commands Reference

### Configuration

```bash
# Edit main config
nvim ~/.config/sway/config

# Edit specific file
nvim ~/.config/sway/snaps/10-keybinds.conf

# Edit theme
nvim ~/.config/sway/themes/windows11-dark.conf

# Reload config
swaymsg reload

# Check for errors
swayfx -c ~/.config/sway/config -C
```

### Workspace Management

```bash
# Switch workspace
swaymsg workspace 1
swaymsg workspace 2

# Move window to workspace
swaymsg move container to workspace 3

# Focus window
swaymsg focus left
swaymsg focus down
```

### Window Management

```bash
# Toggle floating
swaymsg floating toggle

# Fullscreen
swaymsg fullscreen toggle

# Toggle layout
swaymsg layout stacking
swaymsg layout tabbed
swaymsg layout toggle split
```

### Audio

```bash
# Check status
wpctl status

# Set default sink
wpctl set-default-sink 0

# Volume control
pactl set-sink-volume @DEFAULT_SINK@ 50%
pactl set-sink-volume @DEFAULT_SINK@ +5%
pactl set-sink-volume @DEFAULT_SINK@ -5%

# Launch audio router
qpwgraph &
```

### Gaming

```bash
# Enable gaming mode
~/.config/sway/scripts/toggle-gamemode.sh on

# Disable gaming mode
~/.config/sway/scripts/toggle-gamemode.sh off

# Check Proton version
proton --version

# Start Steam
steam
```

---

## ✅ Verification Checklist

After installation, verify:

- [ ] SwayFx boots and displays desktop
- [ ] Audio plays (speaker-test works)
- [ ] Keyb​inds work (Super+Return opens terminal)
- [ ] Waybar visible at bottom with system tray
- [ ] Quickshell ii shell accessible (Super+G)
- [ ] Gaming mode toggles without error
- [ ] Workspaces switch smoothly
- [ ] GPU detected (glxinfo shows device)

---

## 📞 Getting Help

1. **Check logs**: `journalctl -u sway --user -n 50`
2. **Verify config**: `swayfx -c ~/.config/sway/config -C`
3. **See what's running**: `ps aux | grep sway`
4. **Test audio**: `speaker-test -c 2 -l 1`
5. **Check GPU**: `glxinfo | grep Device`

---

## 🎉 You're Done!

Your WehttamSnaps-SwayFx setup is complete with:
- ✅ Windows 11 Dark Theme
- ✅ Gaming Optimization
- ✅ Photography Workspace
- ✅ PipeWire Audio (PRESERVED!)
- ✅ J.A.R.V.I.S. Integration
- ✅ Quickshell ii Shell
- ✅ Modular Configuration
- ✅ Full Documentation

**Enjoy your new desktop environment!** 🚀
