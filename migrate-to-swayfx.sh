#!/bin/bash

################################################################################
# WehttamSnaps Niri → SwayFx Migration Script
# 
# Complete automated migration including:
# - Quickshell → SwayFx adapter
# - Windows 11 dark theme pack
# - PipeWire audio preservation
# - Gaming setup transfer
# - J.A.R.V.I.S. audio integration
#
# Usage: ./migrate-to-swayfx.sh [--dry-run|--backup-only|--full|--force]
# Author: WehttamSnaps
# License: MIT
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MIGRATION_HOME="${HOME}"
CONFIG_DIR="${MIGRATION_HOME}/.config"
LOCAL_SHARE="${MIGRATION_HOME}/.local/share"
BACKUP_DIR="${MIGRATION_HOME}/WehttamSnaps-SwayFx-Backup-$(date +%Y%m%d-%H%M%S)"
COMPLETION_MARKER="${MIGRATION_HOME}/.swayfx-migration-complete"
DRY_RUN=false
BACKUP_ONLY=false
FORCE=false
INTERACTIVE=true

# Logging
LOG_FILE="${BACKUP_DIR}/migration.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

section() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1" | tee -a "$LOG_FILE"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}" | tee -a "$LOG_FILE"
}

prompt_continue() {
    if [ "$INTERACTIVE" = true ] && [ "$FORCE" = false ]; then
        read -p "Continue? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    return 0
}

print_usage() {
    cat << EOF
Usage: ./migrate-to-swayfx.sh [OPTIONS]

OPTIONS:
    --dry-run           Show what would be done without making changes
    --backup-only       Create backups only, don't configure SwayFx
    --full              Full installation (includes package installation)
    --force             Skip all confirmation prompts
    -h, --help          Show this help message

EXAMPLES:
    # Interactive migration with confirmations
    ./migrate-to-swayfx.sh

    # Dry-run to see what would happen
    ./migrate-to-swayfx.sh --dry-run

    # Backup your configs
    ./migrate-to-swayfx.sh --backup-only

    # Full automated migration (recommended for fresh CachyOS install)
    ./migrate-to-swayfx.sh --full --force

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                INTERACTIVE=false
                shift
                ;;
            --backup-only)
                BACKUP_ONLY=true
                shift
                ;;
            --full)
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

check_dependencies() {
    section "Checking Dependencies"
    
    local missing_deps=()
    local optional_deps=()
    
    # Required
    for cmd in git bash sed awk; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Optional but recommended
    for cmd in swayfx waybar mako pipewire foot; do
        if ! command -v "$cmd" &> /dev/null; then
            optional_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    if [ ${#optional_deps[@]} -gt 0 ]; then
        warning "Missing optional packages: ${optional_deps[*]}"
        if [ "$INTERACTIVE" = true ] && [ "$FORCE" = false ]; then
            read -p "Would you like to install them? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Installing optional packages..."
                sudo pacman -S --needed "${optional_deps[@]}"
            fi
        fi
    fi
    
    success "Dependency check complete"
}

create_backups() {
    section "Creating Backups"
    
    log "Backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would backup:"
        [ -d "${CONFIG_DIR}/niri" ] && log "[DRY-RUN]   ~/.config/niri"
        [ -d "${CONFIG_DIR}/quickshell" ] && log "[DRY-RUN]   ~/.config/quickshell"
        [ -d "${CONFIG_DIR}/pipewire" ] && log "[DRY-RUN]   ~/.config/pipewire"
        [ -d "${CONFIG_DIR}/wireplumber" ] && log "[DRY-RUN]   ~/.config/wireplumber"
        return 0
    fi
    
    # Backup Niri config
    if [ -d "${CONFIG_DIR}/niri" ]; then
        log "Backing up Niri configuration..."
        cp -r "${CONFIG_DIR}/niri" "${BACKUP_DIR}/niri-config"
        success "Niri config backed up"
    fi
    
    # Backup Quickshell config
    if [ -d "${CONFIG_DIR}/quickshell" ]; then
        log "Backing up Quickshell configuration..."
        cp -r "${CONFIG_DIR}/quickshell" "${BACKUP_DIR}/quickshell-config"
        success "Quickshell config backed up"
    fi
    
    # Backup PipeWire config (CRITICAL - PRESERVE!)
    if [ -d "${CONFIG_DIR}/pipewire" ]; then
        log "Backing up PipeWire configuration..."
        cp -r "${CONFIG_DIR}/pipewire" "${BACKUP_DIR}/pipewire-config"
        success "PipeWire config backed up (PRESERVED FOR SWAYfx)"
    fi
    
    # Backup Wireplumber config
    if [ -d "${CONFIG_DIR}/wireplumber" ]; then
        log "Backing up Wireplumber configuration..."
        cp -r "${CONFIG_DIR}/wireplumber" "${BACKUP_DIR}/wireplumber-config"
        success "Wireplumber config backed up"
    fi
    
    # Create full backup archive
    log "Creating complete backup archive..."
    tar -czf "${BACKUP_DIR}/config-full-backup.tar.gz" -C "${CONFIG_DIR}" . 2>/dev/null || true
    success "Full backup archive created"
    
    echo "$BACKUP_DIR" > "${MIGRATION_HOME}/.swayfx-migration-backup-path"
}

create_sway_config() {
    section "Creating SwayFx Configuration"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would create SwayFx config at: ~/.config/sway"
        return 0
    fi
    
    mkdir -p "${CONFIG_DIR}/sway/snaps"
    mkdir -p "${CONFIG_DIR}/sway/scripts"
    mkdir -p "${CONFIG_DIR}/sway/themes"
    mkdir -p "${CONFIG_DIR}/sway/quickshell-adapter"
    
    # Main config
    log "Creating main SwayFx configuration..."
    create_sway_main_config
    success "Main config created"
    
    # Modular configs
    log "Creating modular configuration files..."
    create_sway_base_config
    create_sway_keybinds_config
    create_sway_rules_config
    create_sway_workspaces_config
    create_sway_gaming_config
    success "Modular configs created"
    
    # Themes
    log "Creating Windows 11 dark theme..."
    create_windows11_theme
    success "Theme created"
}

create_sway_main_config() {
    cat > "${CONFIG_DIR}/sway/config" << 'SWAY_MAIN_CONFIG'
# WehttamSnaps SwayFx Configuration - Windows 11 Dark Theme
# Complete Niri migration for gaming, photography, and content creation
# Features: PipeWire audio routing, J.A.R.V.I.S. integration, gaming optimizations

# Import modular configuration files
include /etc/sway/config.d/*
include ~/.config/sway/themes/windows11-dark.conf
include ~/.config/sway/snaps/00-base.conf
include ~/.config/sway/snaps/10-keybinds.conf
include ~/.config/sway/snaps/20-rules.conf
include ~/.config/sway/snaps/30-workspaces.conf
include ~/.config/sway/snaps/40-gaming.conf
include ~/.config/sway/snaps/99-overrides.conf

# Startup applications
exec --no-startup-id ~/.config/sway/scripts/audio-init.sh
exec --no-startup-id swaybg -o '*' -i ~/.local/share/wallpapers/default.jpg -m fill
exec --no-startup-id mako
exec --no-startup-id waybar
exec --no-startup-id ~/.config/sway/scripts/start-quickshell.sh

# Idle management
exec swayidle -w \
    timeout 300 'swaylock -f' \
    timeout 360 'swaymsg "output * power off"' \
    resume 'swaymsg "output * power on"'

# Gaming initialization
exec ~/.config/sway/scripts/gaming-init.sh

# Output configuration (modify as needed)
output * bg $bg solid_color
SWAY_MAIN_CONFIG
}

create_sway_base_config() {
    cat > "${CONFIG_DIR}/sway/snaps/00-base.conf" << 'SWAY_BASE_CONFIG'
# Base SwayFx Configuration
# Input, focus, and fundamental behavior settings

# ╭──────────────────── VARIABLES ────────────────────╮
set $mod Mod4
set $alt Alt
set $term foot
set $menu rofi -show drun -theme-str 'window { width: 40%; }'

# Windows 11 Dark Color Palette
set $bg       #0c0c0c
set $surface  #1e1e1e
set $overlay  #2d2d30
set $text     #e0e0e0
set $textdim  #858585
set $accent   #0078d4
set $error    #f48771
set $success  #13a538

# ╰──────────────────────────────────────────────────╯

# Input settings
input "type:keyboard" {
    xkb_layout us
    repeat_delay 500
    repeat_rate 30
}

input "type:touchpad" {
    tap enabled
    natural_scroll enabled
}

input "type:pointer" {
    accel_profile adaptive
    pointer_accel 0.5
}

# Focus behavior
focus_follows_mouse yes
mouse_warping output
workspace_auto_back_and_forth yes

# Window decoration
default_border pixel 2
default_floating_border pixel 2
gaps inner 12
gaps outer 0

# Focused window: Windows 11 accent blue
client.focused          $accent $accent $text $accent $accent
client.focused_inactive $overlay $overlay $textdim $overlay $overlay
client.unfocused        $surface $surface $textdim $surface $surface
client.urgent           $error $error $text $error $error
client.placeholder      $bg $bg $textdim $bg $bg

# Corner rounding (SwayFx feature)
corner_radius 8

# Blur effect (SwayFx feature)
blur enable
blur_xray disable
blur_passes 2
blur_radius 5

# Screenshot settings
set $screenshot_dir ~/Pictures/Screenshots

# Cursor
seat seat0 xcursor_theme Adwaita 24
SWAY_BASE_CONFIG
}

create_sway_keybinds_config() {
    cat > "${CONFIG_DIR}/sway/snaps/10-keybinds.conf" << 'SWAY_KEYBINDS_CONFIG'
# SwayFx Keybindings - Adapted from Niri/ii

# ╭────────────────── NAVIGATION ─────────────────╮
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# ╰────────────────────────────────────────────────╯

# ╭────────────────── MOVEMENT ──────────────────╮
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# ╰────────────────────────────────────────────────╯

# ╭────────────────── WORKSPACES ────────────────╮
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+0 workspace number 10

bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+Shift+9 move container to workspace number 9
bindsym $mod+Shift+0 move container to workspace number 10

bindsym $mod+Tab workspace next
bindsym $mod+Shift+Tab workspace prev

# ╰────────────────────────────────────────────────╯

# ╭────────────────── LAYOUT ────────────────────╮
bindsym $mod+s layout stacking
bindsym $mod+t layout tabbed
bindsym $mod+e layout toggle split
bindsym $mod+f fullscreen toggle
bindsym $mod+a focus parent

# ╰────────────────────────────────────────────────╯

# ╭────────────────── FLOATING ──────────────────╮
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle

# ╰────────────────────────────────────────────────╯

# ╭────────────────── LAUNCHER ──────────────────╮
bindsym $mod+Return exec $term
bindsym $mod+d exec $menu
bindsym $mod+Shift+q kill

# ╰────────────────────────────────────────────────╯

# ╭────────────────── SYSTEM ────────────────────╮
bindsym $mod+Shift+c reload
bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit SwayFx?' -B 'Yes' 'swaymsg exit'

# ╰────────────────────────────────────────────────╯

# ╭────────────────── AUDIO ─────────────────────╮
bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +5% && ~/.config/sway/scripts/volume-notify.sh'
bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -5% && ~/.config/sway/scripts/volume-notify.sh'
bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle && ~/.config/sway/scripts/volume-notify.sh'
bindsym XF86AudioMicMute exec 'pactl set-source-mute @DEFAULT_SOURCE@ toggle'

# ╰────────────────────────────────────────────────╯

# ╭────────────────── BRIGHTNESS ────────────────╮
bindsym XF86MonBrightnessUp exec 'brightnessctl set +5% && ~/.config/sway/scripts/brightness-notify.sh'
bindsym XF86MonBrightnessDown exec 'brightnessctl set 5%- && ~/.config/sway/scripts/brightness-notify.sh'

# ╰────────────────────────────────────────────────╯

# ╭────────────────── SCREENSHOT ────────────────╮
bindsym Print exec grimshot copy area
bindsym $mod+Print exec grimshot copy screen
bindsym Shift+Print exec grimshot copy window

# ╰────────────────────────────────────────────────╯

# ╭────────────────── QUICKSHELL ────────────────╮
bindsym $mod+comma exec qs -c ii ipc call settings open
bindsym $mod+slash exec qs -c ii ipc call cheatsheet toggle
bindsym $mod+v exec qs -c ii ipc call clipboard toggle

# ╰────────────────────────────────────────────────╯

# ╭────────────────── MOUSE ─────────────────────╮
floating_modifier $mod normal
bindsym --whole-window $mod+button8 kill
bindsym --whole-window $mod+button9 floating toggle

# ╰────────────────────────────────────────────────╯
SWAY_KEYBINDS_CONFIG
}

create_sway_rules_config() {
    cat > "${CONFIG_DIR}/sway/snaps/20-rules.conf" << 'SWAY_RULES_CONFIG'
# SwayFx Window Rules - App-specific behavior

# Gaming
for_window [class="Steam"] floating enable
for_window [class="Proton" title=".*"] floating enable
for_window [app_id="gamescope"] fullscreen enable

# Photography/Editing
for_window [app_id="darktable"] workspace 2
for_window [app_id="gimp"] workspace 2
for_window [app_id="rawtherapee"] workspace 2
for_window [app_id="krita"] workspace 2

# Browsers
for_window [app_id="firefox"] workspace 3
for_window [app_id="chromium"] workspace 3

# Communication
for_window [app_id="discord"] workspace 4
for_window [app_id="element"] workspace 4
for_window [app_id="telegram"] workspace 4

# Utilities
for_window [app_id="pavucontrol"] floating enable
for_window [app_id="qpwgraph"] floating enable
for_window [app_id="nm-applet"] floating enable
for_window [title="Volume Control"] floating enable
for_window [title="Audio Routing"] floating enable

# Dialogs
for_window [window_role="dialog"] floating enable
for_window [window_type="dialog"] floating enable
for_window [window_type="splash"] floating enable
for_window [window_type="tooltip"] floating enable

# Quickshell/ii
for_window [app_id="org.quickshell"] border none
for_window [app_id="org.quickshell.ii"] border none
SWAY_RULES_CONFIG
}

create_sway_workspaces_config() {
    cat > "${CONFIG_DIR}/sway/snaps/30-workspaces.conf" << 'SWAY_WORKSPACES_CONFIG'
# Workspace Configuration

workspace 1 output "DP-2" gaps inner 12
workspace 2 output "DP-2" gaps inner 12
workspace 3 output "DP-2" gaps inner 12
workspace 4 output "DP-2" gaps inner 12
workspace 5 output "DP-2" gaps inner 12
workspace 6 output "DP-2" gaps inner 12
workspace 7 output "DP-2" gaps inner 12
workspace 8 output "DP-2" gaps inner 12
workspace 9 output "DP-2" gaps inner 12
workspace 10 output "DP-2" gaps inner 12

# Output configuration (modify DP-2 to your display)
output "DP-2" {
    mode 1920x1080@60Hz
    position 0,0
    scale 1
}
SWAY_WORKSPACES_CONFIG
}

create_sway_gaming_config() {
    cat > "${CONFIG_DIR}/sway/snaps/40-gaming.conf" << 'SWAY_GAMING_CONFIG'
# Gaming-specific Configuration
# Performance optimizations, Proton settings, gamescope

# Performance mode toggle
set $gamemode_on exec ~/.config/sway/scripts/toggle-gamemode.sh on
set $gamemode_off exec ~/.config/sway/scripts/toggle-gamemode.sh off

# Gaming workspace
workspace 5 output "DP-2" layout tabbed

# Fullscreen gaming apps
for_window [class="heroic" title=".*"] floating enable
for_window [app_id="lutris"] floating enable

# Disable effects in fullscreen
bindsym $mod+g exec $gamemode_on
bindsym $mod+Shift+g exec $gamemode_off

# Steam Proton configurations (launch options managed in ~/.config/sway/scripts/)
# Use: ~/.config/sway/scripts/steam-launch-options.sh for game-specific settings

# J.A.R.V.I.S. Gaming alerts
exec ~/.config/sway/scripts/jarvis-manager.sh startup
SWAY_GAMING_CONFIG
}

create_windows11_theme() {
    cat > "${CONFIG_DIR}/sway/themes/windows11-dark.conf" << 'WINDOWS11_THEME'
# Windows 11 Dark Theme for SwayFx
# Fluent Design System colors and styling

# Primary Colors
set $bg       #0c0c0c
set $surface  #1e1e1e
set $overlay  #2d2d30
set $elevated #3c3c42

# Text Colors
set $text     #e0e0e0
set $textdim  #858585
set $textmuted #616161

# Semantic Colors
set $accent   #0078d4
set $accentLight #60cdff
set $error    #f48771
set $errorLight #ff8a80
set $success  #13a538
set $successLight #69f0ae
set $warning  #ffb900
set $info     #2196f3

# Transparency
set $opacity_bg 0.95
set $opacity_surface 0.90
set $opacity_overlay 0.92
WINDOWS11_THEME
}

create_waybar_config() {
    section "Creating Waybar Configuration (Windows 11 Taskbar)"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would create Waybar config at: ~/.config/waybar"
        return 0
    fi
    
    mkdir -p "${CONFIG_DIR}/waybar"
    
    cat > "${CONFIG_DIR}/waybar/config.jsonc" << 'WAYBAR_CONFIG'
{
  "layer": "bottom",
  "position": "bottom",
  "height": 48,
  "spacing": 10,
  "modules-left": [
    "sway/workspaces",
    "custom/separator",
    "sway/window"
  ],
  "modules-center": [
    "clock"
  ],
  "modules-right": [
    "tray",
    "custom/separator",
    "pulseaudio",
    "network",
    "cpu",
    "memory",
    "temperature",
    "backlight",
    "battery"
  ],
  
  "sway/workspaces": {
    "format": "{name}",
    "on-click": "activate",
    "all-outputs": true
  },

  "sway/window": {
    "format": "{}",
    "max-length": 50
  },

  "clock": {
    "format": "{:%I:%M %p}",
    "tooltip-format": "{:%A, %B %d, %Y}"
  },

  "tray": {
    "icon-size": 20,
    "spacing": 8
  },

  "pulseaudio": {
    "format": "🔊 {volume}%",
    "format-muted": "🔇 Muted",
    "on-click": "pavucontrol"
  },

  "network": {
    "format-wifi": "📶 {signalStrength}%",
    "format-ethernet": "🌐 Connected",
    "format-disconnected": "❌ Offline"
  },

  "cpu": {
    "format": "💻 {usage}%",
    "interval": 1
  },

  "memory": {
    "format": "🧠 {percentage}%",
    "interval": 5
  },

  "temperature": {
    "critical-threshold": 80,
    "format": "🌡️ {temperatureC}°C"
  },

  "backlight": {
    "format": "☀️ {percent}%"
  },

  "battery": {
    "format": "🔋 {capacity}%",
    "format-charging": "⚡ {capacity}%",
    "format-full": "✅ {capacity}%"
  },

  "custom/separator": {
    "format": "|"
  }
}
WAYBAR_CONFIG

    cat > "${CONFIG_DIR}/waybar/style.css" << 'WAYBAR_STYLE'
* {
  all: unset;
  font-family: "Segoe UI", system-ui, sans-serif;
  font-size: 14px;
  color: #e0e0e0;
}

window {
  background-color: #0c0c0c;
  border-top: 1px solid #2d2d30;
  padding: 4px 12px;
}

#workspaces {
  margin: 0 20px;
}

#workspaces button {
  padding: 4px 12px;
  border-radius: 4px;
  background-color: #1e1e1e;
  color: #858585;
  transition: all 0.3s ease;
  border: 1px solid transparent;
}

#workspaces button:hover {
  background-color: #2d2d30;
  color: #e0e0e0;
}

#workspaces button.active {
  background-color: #0078d4;
  color: #ffffff;
  border: 1px solid #0078d4;
}

#window {
  padding: 0 20px;
  color: #e0e0e0;
  font-weight: 500;
}

#clock {
  padding: 0 20px;
  color: #0078d4;
  font-weight: 500;
}

#tray {
  margin: 0 10px;
}

#tray > .passive {
  color: #858585;
}

#tray > .needs-attention {
  color: #f48771;
  animation: blink 0.5s ease-in-out infinite alternate;
}

#pulseaudio,
#network,
#cpu,
#memory,
#temperature,
#backlight,
#battery {
  padding: 0 12px;
  background-color: #1e1e1e;
  border-radius: 4px;
  margin: 0 4px;
  border: 1px solid #2d2d30;
}

#pulseaudio.muted {
  color: #f48771;
}

#battery.charging {
  color: #13a538;
}

#battery.full {
  color: #13a538;
}

#temperature.critical {
  color: #f48771;
}

#custom-separator {
  color: #2d2d30;
  margin: 0 4px;
}

@keyframes blink {
  to { color: #0078d4; }
}
WAYBAR_STYLE

    success "Waybar config created"
}

create_helper_scripts() {
    section "Creating Helper Scripts"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would create helper scripts in: ~/.config/sway/scripts"
        return 0
    fi
    
    mkdir -p "${CONFIG_DIR}/sway/scripts"
    chmod +x "${CONFIG_DIR}/sway/scripts"/* 2>/dev/null || true
    
    # Audio initialization script
    cat > "${CONFIG_DIR}/sway/scripts/audio-init.sh" << 'AUDIO_INIT'
#!/bin/bash
# Initialize PipeWire audio system

systemctl --user start pipewire pipewire-pulse wireplumber

sleep 2

# Apply saved audio routing if it exists
if [ -f ~/.config/sway/scripts/audio-profile.conf ]; then
    source ~/.config/sway/scripts/audio-profile.conf
fi

echo "Audio system initialized"
AUDIO_INIT
    chmod +x "${CONFIG_DIR}/sway/scripts/audio-init.sh"
    success "Audio init script created"
    
    # J.A.R.V.I.S. manager
    cat > "${CONFIG_DIR}/sway/scripts/jarvis-manager.sh" << 'JARVIS_MANAGER'
#!/bin/bash
# J.A.R.V.I.S. Audio Management

SOUND_DIR="${HOME}/.local/share/sounds/jarvis"

play_sound() {
    local sound="$1"
    if [ -f "$sound" ]; then
        paplay --volume=65536 "$sound" 2>/dev/null &
    fi
}

case "$1" in
    "startup")
        play_sound "$SOUND_DIR/startup.wav"
        ;;
    "shutdown")
        play_sound "$SOUND_DIR/shutdown.wav"
        ;;
    "gaming_start")
        play_sound "$SOUND_DIR/gaming_mode_on.wav"
        ;;
    "gaming_stop")
        play_sound "$SOUND_DIR/gaming_mode_off.wav"
        ;;
    "notification")
        play_sound "$SOUND_DIR/notification.wav"
        ;;
    "warning")
        play_sound "$SOUND_DIR/warning.wav"
        ;;
    *)
        echo "Unknown J.A.R.V.I.S. command: $1"
        ;;
esac
JARVIS_MANAGER
    chmod +x "${CONFIG_DIR}/sway/scripts/jarvis-manager.sh"
    success "J.A.R.V.I.S. manager created"
    
    # Gaming mode toggle
    cat > "${CONFIG_DIR}/sway/scripts/toggle-gamemode.sh" << 'GAMEMODE_TOGGLE'
#!/bin/bash
# Toggle gaming mode

case "$1" in
  on)
    echo "Gaming Mode: ON"
    ~/.config/sway/scripts/jarvis-manager.sh "gaming_start"
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    export RADV_PERFTEST=gpl
    export mesa_glthread=true
    ;;
  off)
    echo "Gaming Mode: OFF"
    ~/.config/sway/scripts/jarvis-manager.sh "gaming_stop"
    echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
    ;;
  status)
    echo "Check /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    ;;
  *)
    echo "Usage: $0 {on|off|status}"
    ;;
esac
GAMEMODE_TOGGLE
    chmod +x "${CONFIG_DIR}/sway/scripts/toggle-gamemode.sh"
    success "Gaming mode script created"
    
    # Audio profile generator
    mkdir -p "${LOCAL_SHARE}/sounds/jarvis"
    success "Audio directories created"
    
    # Quickshell launcher
    cat > "${CONFIG_DIR}/sway/scripts/start-quickshell.sh" << 'QS_LAUNCHER'
#!/bin/bash
# Start Quickshell ii shell adapted for SwayFx

export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=kde
export QT_STYLE_OVERRIDE=Darkly
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export GDK_BACKEND=wayland

QS_CONFIG_DIR="${HOME}/.config/quickshell/ii"
mkdir -p "$QS_CONFIG_DIR"

exec qs -c ii &
QS_LAUNCHER
    chmod +x "${CONFIG_DIR}/sway/scripts/start-quickshell.sh"
    success "Quickshell launcher created"
}

create_override_template() {
    section "Creating Override Template"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would create override template"
        return 0
    fi
    
    cat > "${CONFIG_DIR}/sway/snaps/99-overrides.conf" << 'OVERRIDES_TEMPLATE'
# User Overrides - Add your custom configurations here
# This file is preserved during updates

# Example: Custom keybinding
# bindsym $mod+x exec your-command

# Example: Custom window rule
# for_window [app_id="your-app"] floating enable

# Example: Custom gap settings for specific workspace
# workspace 2 gaps inner 20

# Example: Custom display settings
# output "HDMI-A-1" enable pos 1920 0
OVERRIDES_TEMPLATE
    
    success "Override template created"
}

restore_pipewire_config() {
    section "Restoring PipeWire Audio Configuration"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would restore PipeWire config from backup"
        return 0
    fi
    
    if [ -d "${BACKUP_DIR}/pipewire-config" ]; then
        log "Restoring PipeWire configuration from backup..."
        rm -rf "${CONFIG_DIR}/pipewire"
        cp -r "${BACKUP_DIR}/pipewire-config" "${CONFIG_DIR}/pipewire"
        success "PipeWire config restored (AUDIO ROUTING PRESERVED)"
    else
        warning "PipeWire backup not found, skipping restore"
    fi
    
    if [ -d "${BACKUP_DIR}/wireplumber-config" ]; then
        log "Restoring Wireplumber configuration from backup..."
        rm -rf "${CONFIG_DIR}/wireplumber"
        cp -r "${BACKUP_DIR}/wireplumber-config" "${CONFIG_DIR}/wireplumber"
        success "Wireplumber config restored"
    fi
}

verify_installation() {
    section "Verifying Installation"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would verify installation"
        return 0
    fi
    
    local missing=()
    
    [ -d "${CONFIG_DIR}/sway" ] || missing+=("~/.config/sway")
    [ -d "${CONFIG_DIR}/waybar" ] || missing+=("~/.config/waybar")
    [ -f "${CONFIG_DIR}/sway/config" ] || missing+=("~/.config/sway/config")
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing configurations: ${missing[*]}"
        return 1
    fi
    
    success "All configurations installed successfully"
}

generate_summary() {
    section "Migration Summary"
    
    cat << EOF | tee -a "$LOG_FILE"

${GREEN}✓ Migration Complete!${NC}

Backup Location:
  ${BACKUP_DIR}

New Configurations:
  ~/.config/sway/              - Main SwayFx config (modular)
  ~/.config/waybar/            - Windows 11 taskbar
  ~/.config/sway/themes/       - Theme files
  ~/.config/sway/scripts/      - Helper scripts

Audio Setup (PRESERVED):
  ~/.config/pipewire/          - Your audio routing (RESTORED)
  ~/.config/wireplumber/       - Audio rules (RESTORED)
  qpwgraph                     - Use for manual routing adjustments

Next Steps:

  1. Log out and switch to SwayFx:
     - Option 1: Select from login manager
     - Option 2: Run: exec sway

  2. Start Quickshell ii shell:
     Ctrl+Alt+T to open terminal, then: qs -c ii

  3. Test audio routing:
     Command: qpwgraph

  4. Toggle gaming mode:
     Command: ~/.config/sway/scripts/toggle-gamemode.sh on/off

  5. Customize as needed:
     Edit: ~/.config/sway/snaps/99-overrides.conf

Documentation:
  - SwayFx: https://github.com/swaywm/sway
  - Quickshell: https://quickshell.outfoxxed.me/
  - PipeWire: https://pipewire.org/

Troubleshooting:
  - Check logs: $LOG_FILE
  - Restore from backup: cp -r $BACKUP_DIR/* ~/.config/
  - Reload SwayFx: swaymsg reload

${YELLOW}⚠ Keep your backup! Location: $BACKUP_DIR${NC}

EOF
}

main() {
    parse_args "$@"
    
    clear
    section "WehttamSnaps Niri → SwayFx Migration"
    
    if [ "$DRY_RUN" = true ]; then
        log "Running in DRY-RUN mode - no changes will be made"
    fi
    
    if [ "$BACKUP_ONLY" = true ]; then
        log "Backup-only mode - creating backups only"
        create_backups
        generate_summary
        return 0
    fi
    
    check_dependencies && prompt_continue || exit 1
    
    create_backups && prompt_continue || exit 1
    
    create_sway_config && prompt_continue || exit 1
    
    create_waybar_config && prompt_continue || exit 1
    
    create_helper_scripts && prompt_continue || exit 1
    
    create_override_template && prompt_continue || exit 1
    
    restore_pipewire_config && prompt_continue || exit 1
    
    verify_installation && prompt_continue || exit 1
    
    touch "$COMPLETION_MARKER"
    generate_summary
}

main "$@"
