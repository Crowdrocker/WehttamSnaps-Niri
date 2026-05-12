# Configuration Guide for WehttamSnaps-SwayFx

> **Complete Configuration Reference** | **Modular Structure** | **Easy Customization**

---

## 📋 Table of Contents

- [File Structure](#-file-structure)
- [Configuration Files](#-configuration-files)
- [Common Edits](#-common-edits)
- [Reload & Testing](#-reload--testing)
- [Advanced Topics](#-advanced-topics)

---

## 📂 File Structure

```
~/.config/sway/
├── config                         # Main entry point (imports everything)
├── snaps/                         # Modular configuration files
│   ├── 00-base.conf              # 🔧 Input, focus, colors (EDIT HERE)
│   ├── 10-keybinds.conf          # ⌨️ Keyboard shortcuts (EDIT HERE)
│   ├── 20-rules.conf             # 🪟 Window rules/layout (EDIT HERE)
│   ├── 30-workspaces.conf        # 📊 Workspace/display setup (EDIT HERE)
│   ├── 40-gaming.conf            # 🎮 Gaming settings (EDIT HERE)
│   └── 99-overrides.conf         # 👤 YOUR CUSTOMIZATIONS (EDIT HERE)
├── scripts/                       # Helper scripts (keep as-is)
│   ├── audio-init.sh
│   ├── jarvis-manager.sh
│   ├── toggle-gamemode.sh
│   ├── gaming-init.sh
│   └── start-quickshell.sh
├── themes/                        # Color schemes
│   └── windows11-dark.conf        # Main theme (modify here for colors)
└── quickshell-adapter/            # ii shell integration (auto-generated)
```

---

## 🔧 Configuration Files

### 1. `00-base.conf` - Fundamentals

**What it does**: Input devices, focus behavior, basic colors, gaps, borders

**Common edits**:

```bash
# Change keyboard layout
input "type:keyboard" {
    xkb_layout us    # Change to: de, fr, es, etc.
}

# Adjust repeat rate (milliseconds)
input "type:keyboard" {
    repeat_delay 500  # Lower = faster repeat
    repeat_rate 30    # Higher = more repeats/sec
}

# Change touchpad speed
input "type:touchpad" {
    # accel_profile flat    # Remove adaptive acceleration
    pointer_accel 0.5      # -1 to 1 (negative = inverted)
}

# Disable focus-follows-mouse
focus_follows_mouse no

# Adjust gaps (12 = 12 pixels)
gaps inner 12
gaps outer 0

# Change corner radius (0 = sharp, 10 = rounded)
corner_radius 8

# Disable blur for performance
blur disable
```

### 2. `10-keybinds.conf` - Keyboard Shortcuts

**What it does**: All keyboard bindings organized by category

**Common edits**:

```bash
# Add new binding
bindsym $mod+x exec firefox

# Add application launcher
bindsym $mod+e exec nautilus  # File manager

# Remap navigation keys
bindsym $mod+n focus left     # Instead of $mod+h
bindsym $mod+e focus down     # Instead of $mod+j
bindsym $mod+i focus up       # Instead of $mod+k
bindsym $mod+o focus right    # Instead of $mod+l

# Custom music controls
bindsym $mod+Prior exec "pactl set-sink-volume @DEFAULT_SINK@ +5%"
bindsym $mod+Next exec "pactl set-sink-volume @DEFAULT_SINK@ -5%"

# Screenshot to clipboard instead of file
bindsym Print exec grimshot copy area
bindsym Shift+Print exec grimshot save area ~/Pictures/screenshot-$(date +%s).png
```

**Format**: `bindsym [MODIFIERS+]KEY exec COMMAND`

**Modifiers**: `$mod` (Super/Win), `$alt`, `Shift`, `Ctrl`

**Find key names**: `xev` (X11) or `wev` (Wayland)

### 3. `20-rules.conf` - Window Rules

**What it does**: Application-specific behavior, floating, workspace assignment

**Common edits**:

```bash
# Make Firefox open in workspace 3
for_window [app_id="firefox"] workspace 3

# Always float Pavucontrol
for_window [app_id="pavucontrol"] floating enable

# Open steam in workspace 5 as floating
for_window [class="Steam"] {
    workspace 5
    floating enable
}

# Remove borders for certain apps
for_window [app_id="mpv"] border none

# Make dialog boxes floating
for_window [window_type="dialog"] floating enable

# Assign class for games
for_window [class="heroic"] {
    workspace 5
    floating enable
}

# Auto-layout for specific windows
for_window [app_id="discord"] {
    workspace 4
    layout tabbed
}
```

**Finding app_id**:
```bash
# Use swaymsg to get window details
swaymsg -t get_tree | grep -i "app_id"

# Or while window is focused
swaymsg -t get_tree | grep -C5 focused
```

### 4. `30-workspaces.conf` - Workspaces & Displays

**What it does**: Workspace layout, monitor assignment, display settings

**Common edits**:

```bash
# Add more workspaces (default is 10)
workspace 11 output "DP-1"
workspace 12 output "DP-1"

# Assign workspaces to specific monitors
workspace 1 output "DP-1"
workspace 2 output "DP-1"
workspace 5 output "DP-2"  # Second monitor starts at 5

# Change display resolution
output "DP-1" {
    mode 2560x1440@144Hz    # Check with: swaymsg -t get_outputs
    position 0,0
    scale 1.0
    transform normal        # or: 90, 180, 270 (rotate)
}

# Multiple monitors side-by-side
output "DP-1" {
    mode 1920x1080@60Hz
    position 0,0
}

output "DP-2" {
    mode 1920x1080@60Hz
    position 1920,0          # Directly to the right
}

# HiDPI display
output "eDP-1" {
    mode 1920x1080@60Hz
    scale 2                  # 200% scaling
}

# Disable output
output "HDMI-A-1" disable
```

**Find display info**:
```bash
swaymsg -t get_outputs
```

### 5. `40-gaming.conf` - Gaming Configuration

**What it does**: Gaming-specific settings, Proton, gamescope, performance

**Common edits**:

```bash
# Add game launch with gaming mode
bindsym $mod+g exec "~/.config/sway/scripts/toggle-gamemode.sh on && steam"

# Auto-layout for gaming
workspace 5 layout stacking   # No wasted space

# Remove gaps during gaming
for_window [class="heroic"] {
    gaps inner 0
    gaps outer 0
}

# Steam-specific settings
for_window [class="Steam" title=".*"] floating enable

# Lutris launcher
for_window [app_id="lutris"] floating enable

# Disable effects for emulators (low-spec performance)
for_window [app_id="retroarch"] {
    fullscreen enable
    corner_radius 0
    blur disable
}
```

### 6. `99-overrides.conf` - Your Customizations

**What it does**: Your personal additions (preserved during updates)

**This is where you add**:
```bash
# Your custom keybindings
bindsym $mod+x exec firefox

# Your custom window rules
for_window [app_id="myapp"] floating enable

# Your custom gaps
workspace 2 gaps inner 0

# Your custom launch commands
exec --no-startup-id your-app

# Anything else you want to add
```

---

## 🎨 Themes - `windows11-dark.conf`

**What it does**: Define all colors used throughout SwayFx

**Colors you can customize**:

```bash
# Primary - background
set $bg       #0c0c0c          # Change main background

# UI surfaces
set $surface  #1e1e1e          # Primary surface
set $overlay  #2d2d30          # Overlay/modal background
set $elevated #3c3c42          # Elevated elements

# Text colors
set $text     #e0e0e0          # Main text
set $textdim  #858585          # Dimmed/secondary text
set $textmuted #616161         # Very dim text

# Semantic colors
set $accent   #0078d4          # Main accent (Windows blue)
set $error    #f48771          # Error states
set $success  #13a538          # Success states
set $warning  #ffb900          # Warning states

# Transparency
set $opacity_bg 0.95           # Background opacity (0-1)
```

**Create custom theme**:

1. Copy theme file:
```bash
cp ~/.config/sway/themes/windows11-dark.conf ~/.config/sway/themes/my-theme.conf
```

2. Edit colors:
```bash
# Change to Dracula theme, for example
set $bg       #282a36
set $surface  #44475a
set $accent   #bd93f9
set $text     #f8f8f2
```

3. Include in main config:
```bash
# Edit ~/.config/sway/config, change:
# include ~/.config/sway/themes/windows11-dark.conf
# to:
# include ~/.config/sway/themes/my-theme.conf
```

---

## ⌨️ Common Edits

### Add Custom Shortcut

Edit `~/.config/sway/snaps/99-overrides.conf`:

```bash
# Open web browser
bindsym $mod+w exec firefox

# Open file manager
bindsym $mod+e exec nautilus

# Open settings
bindsym $mod+Shift+s exec gnome-control-center

# Custom command
bindsym $mod+x exec your-command-here
```

### Change Display Settings

Edit `~/.config/sway/snaps/30-workspaces.conf`:

```bash
# Check available outputs
swaymsg -t get_outputs

# Modify output settings
output "eDP-1" {
    mode 1920x1080@60Hz
    position 0,0
    scale 1.5
    bg #1e1e1e solid_color    # Set solid background
}
```

### Assign Application to Workspace

Edit `~/.config/sway/snaps/20-rules.conf`:

```bash
# Auto-open in workspace 2
for_window [app_id="darktable"] workspace 2

# Multiple apps to same workspace
for_window [app_id="firefox"] workspace 3
for_window [app_id="chromium"] workspace 3

# Open as floating
for_window [app_id="pavucontrol"] floating enable
```

### Adjust Gaps & Borders

Edit `~/.config/sway/snaps/00-base.conf`:

```bash
# Normal gaps
gaps inner 12
gaps outer 0

# Tight gaps for productivity
gaps inner 4
gaps outer 0

# No gaps (fullscreen-like)
gaps inner 0
gaps outer 0

# Border width (pixels)
default_border pixel 2      # Change to 1, 3, etc.
default_floating_border pixel 2
```

### Disable Blur (Performance)

Edit `~/.config/sway/snaps/00-base.conf`:

```bash
# Disable blur
blur disable

# Or reduce blur passes
blur enable
blur_passes 1           # Default: 2
blur_radius 3           # Default: 5
```

### Change Mouse Acceleration

Edit `~/.config/sway/snaps/00-base.conf`:

```bash
input "type:pointer" {
    accel_profile adaptive      # or: flat (no acceleration)
    pointer_accel 0.5          # -1.0 (slow) to 1.0 (fast)
}
```

---

## 🔄 Reload & Testing

### Reload Configuration

```bash
# Reload without restarting
swaymsg reload

# Full restart (less reliable)
exec sway
```

### Test Configuration

```bash
# Validate syntax
swayfx -c ~/.config/sway/config -C

# Dry-run mode (if supported)
swayfx -c ~/.config/sway/config --check-for-config-errors
```

### Check Current Settings

```bash
# Show all outputs
swaymsg -t get_outputs

# Show all workspaces
swaymsg -t get_workspaces

# Show focused window info
swaymsg -t get_tree | grep -A10 focused

# Show all keybindings
swaymsg -t get_config
```

---

## 🔍 Advanced Topics

### Conditional Configuration (By Display)

```bash
# If output exists, apply settings
output "DP-1" {
    mode 2560x1440@144Hz
    position 0,0
}

# Fallback for laptop screen
output "eDP-1" {
    mode 1920x1080@60Hz
    position 0,0
}
```

### Workspace Switching Animation

```bash
# This is in Niri KDL format - SwayFx uses simpler system
# For animations, consider using:
# - Fade via opacity changes
# - Or upgrade to Niri if needed
```

### Custom Startup Scripts

In `99-overrides.conf`:

```bash
# Run on startup
exec --no-startup-id ~/.config/sway/scripts/my-startup.sh

# Run periodically
exec --no-startup-id watch -n 300 ~/.config/sway/scripts/check-updates.sh

# Background process (& at end)
exec ~/.config/sway/scripts/my-daemon.sh &
```

### Per-Workspace Gaps

```bash
# Workspace 2 with no gaps (photography)
workspace 2 gaps inner 0

# Workspace 5 with large gaps (gaming)
workspace 5 gaps inner 8
```

### Keyboard Layout Switching

```bash
# US + German layouts, toggle with Alt+Caps
input "type:keyboard" {
    xkb_layout "us,de"
    xkb_options "grp:alt_caps_toggle"
}
```

---

## 📚 File Format Reference

### Sway Configuration Syntax

```bash
# Comments (lines starting with #)

# Variable assignment
set $mod Mod4
set $accent #0078d4

# Command execution
bindsym $mod+Return exec $term

# Conditional (output exists)
output "DP-1" { ... }

# For_window rules
for_window [app_id="firefox"] floating enable

# Include other files
include ~/.config/sway/custom.conf
```

---

## 🆘 Troubleshooting Configuration

### Changes not taking effect

```bash
# 1. Save file (Ctrl+S in editor)
# 2. Reload Sway
swaymsg reload

# 3. Check for errors
swayfx -c ~/.config/sway/config -C

# 4. Check logs
journalctl -u sway --user -n 50
```

### Syntax error on reload

```bash
# Test configuration
swayfx -c ~/.config/sway/config -C

# View specific error
cat ~/.config/sway/snaps/10-keybinds.conf | grep -n "ERROR_LINE"
```

### Keybinding not working

```bash
# Check if key name is correct
# Use: wev  (Wayland event viewer)
wev

# Or test binding
swaymsg -t subscribe all  # See all events

# Verify binding exists
swaymsg -t get_config | grep "your_keybinding"
```

---

## 📖 More Resources

- **Sway Config Manual**: `man 5 sway`
- **Sway IPC**: `swaymsg -h`
- **Find Key Names**: `wev` (Wayland) 
- **Color Picker**: `gcolor3` or `kcolorchooser`

---

**Last Updated**: 2026-05-12 | **Status**: Complete Reference
