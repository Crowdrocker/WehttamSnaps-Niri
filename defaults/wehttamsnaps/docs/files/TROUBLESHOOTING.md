# Troubleshooting Guide - WehttamSnaps Setup

Common issues and solutions for your Niri + Noctalia configuration.

---

## 🚨 Critical Issues

### Niri Won't Start

**Symptoms:** Black screen, no compositor, stuck at login

**Diagnosis:**
```bash
# Check if Niri is running
ps aux | grep niri

# Check logs
journalctl --user -u niri.service -f

# Validate config
niri validate
```

**Solutions:**

**1. Config syntax error:**
```bash
# Find the error
niri validate

# Common issues:
# - Missing closing braces }
# - Typo in keybind
# - Invalid color code

# Fix in config
kate ~/.config/niri/config.kdl
```

**2. Missing dependencies:**
```bash
# Reinstall Niri
paru -S niri

# Check required packages
paru -Q niri quickshell pipewire wireplumber
```

**3. Start Niri manually:**
```bash
# From TTY (Ctrl+Alt+F2)
niri

# Or with logging
niri 2>&1 | tee ~/niri-debug.log
```

**4. Restore backup:**
```bash
# If you have backup
cp ~/.config/wehttamsnaps-backup-*/niri/* ~/.config/niri/

# Validate
niri validate

# Restart
systemctl --user restart niri.service
```

---

### Noctalia Shell Not Loading

**Symptoms:** No bar, no launcher, keybinds don't work

**Diagnosis:**
```bash
# Check if Noctalia is running
ps aux | grep quickshell

# Check Noctalia logs
journalctl --user -xe | grep quickshell
```

**Solutions:**

**1. Restart Noctalia:**
```bash
# Kill existing instance
killall qs

# Start manually
qs -c noctalia-shell &

# Or restart service (if using systemd)
systemctl --user restart noctalia.service
```

**2. Check installation:**
```bash
# Verify Noctalia is installed
paru -Q noctalia-shell quickshell

# Reinstall if needed
paru -S noctalia-shell quickshell
```

**3. Check Niri autostart:**
```bash
# Should be in: ~/.config/niri/conf.d/00-base.kdl
grep "qs.*noctalia-shell" ~/.config/niri/conf.d/00-base.kdl

# Should see:
# spawn-at-startup "qs" "-c" "noctalia-shell"
```

**4. Manual start for debugging:**
```bash
# Run in foreground to see errors
qs -c noctalia-shell
```

---

## 🎮 Gaming Issues

### Games Won't Launch via Steam

**Symptoms:** Game crashes immediately, black screen, won't start

**Solutions:**

**1. Check Proton version:**
```bash
# Right-click game → Properties → Compatibility
# Enable: "Force the use of a specific Steam Play compatibility tool"
# Select: Proton GE or Proton Experimental
```

**2. Verify game files:**
```bash
# Right-click game → Properties → Local Files
# Click: "Verify integrity of game files"
```

**3. Clear shader cache:**
```bash
# Find game's App ID (check Properties)
rm -rf ~/.steam/steam/steamapps/shadercache/[APPID]
```

**4. Try different compatibility tool:**
```bash
# Install Proton GE
protonup-qt

# Select Proton GE in game properties
```

**5. Check launch options:**
```bash
# See: ~/.config/wehttamsnaps/docs/STEAM-LAUNCH-OPTIONS.md
# Common fix: Remove all launch options, test, then re-add
```

---

### Division 2 / Cyberpunk 2077 Crashes

**Known Issue:** These games crash frequently on Linux.

**Solutions:**

**Division 2:**
```bash
# Launch options:
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 RADV_DEBUG=zerovram DXVK_STATE_CACHE=1 mesa_glthread=true __GL_SHADER_DISK_CACHE=1 %command% -dx12 -fullscreen

# In-game:
# - Set graphics to Medium
# - Disable DX12 (if crashing persists)
# - Play offline first to rule out network issues

# Use Proton Experimental or latest Proton GE
```

**Cyberpunk 2077:**
```bash
# Launch options:
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl RADV_DEBUG=zerovram DXVK_STATE_CACHE=1 VKD3D_CONFIG=dxr11 mesa_glthread=true %command% -fullscreen -skipStartScreen

# In-game:
# - Disable Ray Tracing
# - Set to Medium-High settings
# - Cap FPS to 60

# If still crashing:
PROTON_USE_WINED3D=1 %command%
```

---

### Gaming Mode Won't Enable

**Symptoms:** `Mod + G` doesn't disable animations

**Solutions:**

**1. Check script exists:**
```bash
ls ~/.config/wehttamsnaps/scripts/toggle-gamemode.sh
chmod +x ~/.config/wehttamsnaps/scripts/toggle-gamemode.sh
```

**2. Test manually:**
```bash
~/.config/wehttamsnaps/scripts/toggle-gamemode.sh on
~/.config/wehttamsnaps/scripts/toggle-gamemode.sh status
```

**3. Check keybind:**
```bash
# Should be in: ~/.config/niri/conf.d/10-keybinds.kdl
grep "toggle-gamemode" ~/.config/niri/conf.d/10-keybinds.kdl
```

**4. Check gamemode service:**
```bash
# Install gamemode
paru -S gamemode

# Check status
systemctl --user status gamemoded.service
```

---

### Low FPS / Stuttering

**Solutions:**

**1. Enable gaming mode:**
```bash
# Mod + G or:
gaming-on
gaming-status
```

**2. Check GPU driver:**
```bash
# Should see RADV for AMD RX 580
vulkaninfo | grep deviceName

# Update Mesa drivers
paru -Syu mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
```

**3. Monitor GPU:**
```bash
# Install radeontop
paru -S radeontop

# Monitor in real-time
radeontop
```

**4. Reduce graphics settings:**
- Most games should run Medium-High at 60 FPS on RX 580
- Disable Ray Tracing
- Cap FPS to 60 to reduce heat

**5. Check temperatures:**
```bash
# CPU temp
sensors | grep "Package id 0"

# GPU temp
cat /sys/class/drm/card0/device/hwmon/hwmon0/temp1_input | awk '{print $1/1000 "°C"}'

# If over 80°C (CPU) or 85°C (GPU), clean dust or improve cooling
```

---

## 🔊 Audio Issues

### No Audio Output

**Solutions:**

**1. Restart PipeWire:**
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
# or use alias:
audio-restart
```

**2. Check output device:**
```bash
# List sinks
pactl list sinks short

# Set default
pactl set-default-sink [sink-name]

# Or use pavucontrol:
pavu
# Configuration tab → Set default output
```

**3. Unmute:**
```bash
pactl set-sink-mute @DEFAULT_SINK@ 0
pactl set-sink-volume @DEFAULT_SINK@ 65536  # 100%
```

**4. Check connections in qpwgraph:**
```bash
qpw
# Make sure applications are connected to output
```

---

### Virtual Sinks Not Working

**Symptoms:** GameAudio, BrowserAudio, etc. not appearing

**Solutions:**

**1. Re-run setup:**
```bash
~/.config/wehttamsnaps/scripts/audio-setup.sh
```

**2. Check PipeWire config:**
```bash
ls ~/.config/pipewire/pipewire.conf.d/wehttamsnaps-sinks.conf

# If missing, re-run setup
audio
```

**3. Manually create sinks:**
```bash
pw-cli create-node adapter \
    "{ factory.name=support.null-audio-sink \
       node.name=\"GameAudio\" \
       media.class=Audio/Sink \
       object.linger=true \
       audio.position=[FL,FR] }"
```

**4. Restart audio services:**
```bash
audio-restart
sleep 3
pactl list sinks short
```

---

### J.A.R.V.I.S. Sounds Not Playing

**Solutions:**

**1. Check sound files exist:**
```bash
ls ~/.config/wehttamsnaps/sounds/

# Should see:
# jarvis-startup.mp3
# jarvis-shutdown.mp3
# jarvis-gaming.mp3
# etc.
```

**2. Test manually:**
```bash
jarvis-test
# or:
~/.config/wehttamsnaps/scripts/jarvis-manager.sh test
```

**3. Check audio player:**
```bash
# MPV should be installed
which mpv

# Test with MPV
mpv ~/.config/wehttamsnaps/sounds/jarvis-startup.mp3
```

**4. Create placeholders:**
```bash
jarvis placeholders
# Then replace empty files with your actual MP3s
```

---

## ⌨️ Input Issues

### Keyboard Shortcuts Not Working

**Solutions:**

**1. Check Noctalia is running:**
```bash
ps aux | grep quickshell
```

**2. Test Niri keybinds:**
```bash
# Try basic Niri commands
# Mod + Q (close window)
# Mod + 1-9 (switch workspace)

# If these work, issue is with Noctalia keybinds
# If these don't work, issue is with Niri config
```

**3. Validate Niri config:**
```bash
niri validate
# Fix any errors shown
```

**4. Reload Niri:**
```bash
# Mod + Shift + Ctrl + R
# or:
niri-reload
```

**5. Check for conflicting keybinds:**
```bash
# Search for duplicate keybinds
grep -r "Mod+Space" ~/.config/niri/conf.d/
```

---

### Mouse Not Working / Cursor Missing

**Solutions:**

**1. Check cursor theme:**
```bash
# Install cursor theme
paru -S bibata-cursor-theme

# Set in Niri config (should already be set)
# ~/.config/niri/conf.d/00-base.kdl:
# cursor { theme "Bibata-Modern-Ice" size 24 }
```

**2. Reload Niri:**
```bash
niri msg action reload-config
```

**3. Check input device:**
```bash
# List input devices
libinput list-devices

# If mouse not listed, check USB connection
```

---

## 🖼️ Display Issues

### Screen Tearing / Flickering

**Solutions:**

**1. Check VRR (Variable Refresh Rate):**
```bash
# Edit: ~/.config/niri/conf.d/00-base.kdl
# Change: vrr "auto" to vrr "off"
```

**2. Update GPU drivers:**
```bash
paru -Syu mesa lib32-mesa xf86-video-amdgpu vulkan-radeon
```

**3. Check monitor cable:**
- Use DisplayPort for best results
- Ensure cable is plugged in fully
- Try different cable if available

---

### Wrong Resolution / Refresh Rate

**Solutions:**

**1. Check Niri config:**
```bash
# Edit: ~/.config/niri/conf.d/00-base.kdl
# Should be:
# output "DP-3" {
#     mode "1920x1080@60.000"
# }
```

**2. List available modes:**
```bash
niri msg outputs
```

**3. Force resolution:**
```bash
# Edit output config
# mode "1920x1080@60"
niri msg action reload-config
```

---

## 📸 Photography App Issues

### GIMP / Darktable Won't Start

**Solutions:**

**1. Launch from terminal to see errors:**
```bash
gimp
# or
darktable
```

**2. Check installation:**
```bash
paru -Q gimp darktable krita

# Reinstall if needed
paru -S gimp darktable krita
```

**3. Clear cache:**
```bash
rm -rf ~/.cache/gimp ~/.cache/darktable
```

---

### RAW Files Won't Open in Darktable

**Solutions:**

**1. Check file format support:**
```bash
# Darktable supports most RAW formats
# Check: https://www.darktable.org/about/features/

# Update Darktable
paru -Syu darktable
```

**2. Try opening in RawTherapee:**
```bash
paru -S rawtherapee
rawtherapee your-file.raw
```

---

## 🌐 Webapp Issues

### Webapps Won't Launch

**Solutions:**

**1. Check script exists:**
```bash
ls ~/.config/wehttamsnaps/scripts/webapp-launcher.sh
chmod +x ~/.config/wehttamsnaps/scripts/webapp-launcher.sh
```

**2. Test manually:**
```bash
webapp youtube
# or
~/.config/wehttamsnaps/scripts/webapp-launcher.sh youtube
```

**3. Check browser:**
```bash
which brave
# If missing:
paru -S brave-bin
```

**4. Try alternate browser:**
```bash
# Edit webapp script or create custom config
# Use firefox instead of brave
```

---

## 💾 System Issues

### High Memory Usage

**Solutions:**

**1. Check what's using memory:**
```bash
btop
# or
ps aux --sort=-%mem | head
```

**2. Close unused applications:**
```bash
# Kill process
killall [process-name]
```

**3. Enable zram:**
```bash
paru -S zram-generator

# Create config
sudo nano /etc/systemd/zram-generator.conf

# Add:
[zram0]
zram-size = ram / 2
compression-algorithm = zstd

# Enable
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service
```

---

### System Freezes / Hangs

**Solutions:**

**1. Check logs after reboot:**
```bash
journalctl -b -1 -p err
# Shows errors from last boot
```

**2. Check temperatures:**
```bash
sensors
# CPU and GPU temps
```

**3. Memory test:**
```bash
# Run memtest86+ from GRUB menu
# Or use:
memtester 1000 5
```

**4. Disk check:**
```bash
# Check disk health
sudo smartctl -a /dev/sda

# Check for errors
sudo journalctl -b | grep -i error
```

---

## 🔧 Configuration Issues

### Can't Edit Config Files

**Solutions:**

**1. Use correct editor:**
```bash
# Niri config
kate ~/.config/niri/config.kdl

# Or use text editor
nano ~/.config/niri/config.kdl
```

**2. Check permissions:**
```bash
ls -la ~/.config/niri/
chmod 644 ~/.config/niri/config.kdl
```

---

### Changes Not Taking Effect

**Solutions:**

**1. Reload Niri:**
```bash
Mod + Shift + Ctrl + R
# or:
niri msg action reload-config
```

**2. Restart Noctalia:**
```bash
killall qs
qs -c noctalia-shell &
```

**3. Restart services:**
```bash
systemctl --user restart niri.service
systemctl --user restart noctalia.service  # if using systemd
```

---

## 📦 Package Management Issues

### Can't Install Packages

**Solutions:**

**1. Update system:**
```bash
paru -Syu
```

**2. Clear package cache:**
```bash
paru -Scc
```

**3. Update mirrorlist:**
```bash
sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

**4. Check keyring:**
```bash
sudo pacman -S archlinux-keyring
sudo pacman-key --refresh-keys
```

---

## 🆘 Emergency Recovery

### Boot to TTY

If GUI won't start:
1. Press `Ctrl + Alt + F2`
2. Login with username/password
3. Debug from terminal

### Restore Backup

```bash
# List backups
ls ~/.config/wehttamsnaps-backup-*

# Restore
cp -r ~/.config/wehttamsnaps-backup-XXXXXXX/* ~/.config/

# Validate
niri validate

# Reboot
reboot
```

### Start with Minimal Config

```bash
# Rename current config
mv ~/.config/niri ~/.config/niri-broken

# Create minimal config
mkdir -p ~/.config/niri
cat > ~/.config/niri/config.kdl << 'EOF'
input {
    keyboard {
        xkb { layout "us" }
    }
}

output "DP-3" {
    mode "1920x1080@60"
}

layout {
    gaps 8
    default-column-width { proportion 0.5; }
}

binds {
    Mod+Return { spawn "foot"; }
    Mod+Q { close-window; }
}
EOF

# Test
niri
```

---

## 📞 Getting Help

### Gather Debug Info

Before asking for help, collect:

```bash
# System info
fastfetch > ~/system-info.txt

# Niri config
niri validate > ~/niri-validate.txt

# Niri logs
journalctl --user -u niri.service -n 100 > ~/niri-logs.txt

# Package versions
paru -Q niri noctalia-shell quickshell pipewire > ~/versions.txt
```

### Resources

- **Niri Issues:** https://github.com/YaLTeR/niri/issues
- **Noctalia Issues:** https://github.com/noctalia-dev/noctalia-shell/issues
- **Arch Wiki:** https://wiki.archlinux.org/
- **WehttamSnaps GitHub:** https://github.com/Crowdrocker

---

## 🔍 Diagnostic Commands

Quick reference for debugging:

```bash
# System
fastfetch
journalctl -b -p err
systemctl --failed --user

# Niri
niri validate
niri msg outputs
journalctl --user -u niri.service -f

# Audio
pactl list sinks short
pw-dump
systemctl --user status pipewire

# Graphics
vulkaninfo | grep deviceName
glxinfo | grep "OpenGL renderer"
radeontop

# Processes
ps aux | grep niri
ps aux | grep quickshell
btop

# Disk
df -h
du -sh ~/.config/*

# Network
ip addr
ping -c 4 8.8.8.8
```

---

**Made for WehttamSnaps** | Photography • Gaming • Content Creation
