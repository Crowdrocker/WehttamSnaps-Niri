# Gaming Guide - WehttamSnaps Setup

**Optimized for Dell XPS 8700 | i7-4790 | RX 580 | 16GB RAM**

Complete guide to gaming on your Arch Linux Niri setup.

---

## 🎮 Quick Start

### Enable Gaming Mode

Press `Mod + G` or run:
```bash
gaming-on
```

**What it does:**
- ✅ Disables all window animations
- ✅ Sets CPU to performance governor
- ✅ Sets AMD GPU to high performance mode
- ✅ Plays J.A.R.V.I.S. "Gaming mode activated" sound
- ✅ Optimizes system for maximum FPS

### Jump to Gaming Workspace

```bash
Mod + 9  # Switch to gaming workspace
```

All games automatically open fullscreen on workspace 9.

---

## 📊 Your System Performance

### Expected FPS @ 1080p

| Game | Settings | Average FPS | Notes |
|------|----------|-------------|-------|
| Cyberpunk 2077 | Medium-High | 55-60 | Disable RT |
| Division 2 | Medium | 60 | Some drops in busy areas |
| Fallout 4 | Ultra | 60+ | CPU bottleneck possible |
| FarCry 5 | High | 60+ | Runs great |
| Watch Dogs Legion | Medium | 50-60 | Most demanding |
| Shadow of Tomb Raider | High | 55-60 | Good optimization |
| Warframe | High | 60+ | Excellent performance |
| Watch Dogs 2 | High | 60 | Well optimized |
| Rise of Tomb Raider | High | 60+ | Great performance |

### Hardware Notes

**CPU (i7-4790):**
- 4 cores, 8 threads @ 4.0 GHz
- May bottleneck in CPU-heavy games
- Excellent for most games from 2015-2020

**GPU (RX 580):**
- 8GB VRAM
- 1080p sweet spot
- Medium-High settings for modern games
- High-Ultra for older games (pre-2018)

**RAM (16GB):**
- Sufficient for all games
- No memory issues expected

---

## 🚀 Gaming Setup

### 1. Install Gaming Packages

```bash
# Install from package list
paru -S --needed $(cat ~/.config/wehttamsnaps/packages/gaming.list | grep -v '^#')
```

**Includes:**
- Steam with native runtime
- Proton GE (latest)
- Lutris game manager
- Gamemode + Gamescope
- MangoHud (FPS overlay)
- AMD GPU drivers (Mesa/RADV)
- All necessary libraries

### 2. Configure Steam

**Enable Proton for all games:**
1. Open Steam
2. Settings → Compatibility
3. ✅ Enable Steam Play for all other titles
4. Select: Proton Experimental

**Install Proton GE:**
```bash
protonup-qt
# or: Mod + Alt + P
```

Select latest Proton GE version and install.

### 3. Apply Launch Options

See `STEAM-LAUNCH-OPTIONS.md` for per-game configurations.

**Universal launch options (fallback):**
```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl %command%
```

---

## 🎯 Per-Game Optimization

### Division 2 (Crash Fix)

**Problem:** Game crashes on startup or randomly during gameplay.

**Solution:**
```bash
# Launch options:
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 RADV_DEBUG=zerovram DXVK_STATE_CACHE=1 mesa_glthread=true __GL_SHADER_DISK_CACHE=1 %command% -dx12 -fullscreen

# Proton version:
Use Proton Experimental or latest Proton GE

# In-game settings:
- Graphics: Medium
- DX12 mode
- Fullscreen (not borderless)
- VSync: Off
- Frame rate cap: 60

# If still crashing:
1. Verify game files
2. Delete shader cache: rm -rf ~/.steam/steam/steamapps/shadercache/2543850
3. Try: PROTON_USE_WINED3D=1 %command%
```

**Window mode fix:**
- Game starts windowed? Alt+Enter to fullscreen
- Or set in-game: Settings → Graphics → Display Mode → Fullscreen

---

### Cyberpunk 2077 (Performance)

**Problem:** Low FPS, stuttering, or crashes.

**Solution:**
```bash
# Launch options:
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl RADV_DEBUG=zerovram DXVK_STATE_CACHE=1 VKD3D_CONFIG=dxr11 mesa_glthread=true %command% -fullscreen -skipStartScreen

# Proton version:
Latest Proton GE

# Optimal settings for RX 580:
Graphics Quality: Medium
Texture Quality: High
Ray Tracing: OFF (critical for FPS)
AMD FidelityFX CAS: ON
DLSS/FSR: FSR 2.0 Quality
Frame Rate: Capped at 60
VSync: Off

# Advanced:
Contact Shadows: Off
Improved Facial Geometry: Off
Anisotropy: 8x
```

**Expected:** 55-60 FPS stable with these settings.

---

### Fallout 4 (Mod Support)

**Problem:** Game won't start, or crashes with mods.

**Solution:**
```bash
# Launch options:
gamemoderun PROTON_USE_WINED3D=1 PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 %command% -fullscreen -nolauncher

# Proton version:
Proton 8.0 or earlier (WINE3D works better)

# For modding:
1. Install Mod Organizer 2 via Lutris/Wine
2. Run MO2 separately, not through Steam
3. Set MO2 to launch Fallout4.exe
4. Keep mods lightweight for RX 580

# Window fix:
Edit: ~/Documents/My Games/Fallout4/Fallout4Prefs.ini

[Display]
bBorderless=1
bFull Screen=0
iSize H=1080
iSize W=1920
```

**Recommended mods:**
- Unofficial Fallout 4 Patch
- FAR (performance boost)
- BethINI (settings optimizer)
- Keep texture mods to 2K max

---

### Watch Dogs Legion (High Graphics)

**Problem:** Stuttering, low FPS.

**Solution:**
```bash
# Launch options:
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 RADV_DEBUG=zerovram DXVK_STATE_CACHE=1 mesa_glthread=true %command% -dx12 -fullscreen

# Settings:
Graphics Quality: Medium-High preset
Ray Tracing: OFF
Resolution: 1920x1080
VSync: OFF
Frame Rate Limit: 60
Anti-Aliasing: TAA
Texture Quality: High
Shadow Quality: Medium
```

**Expected:** 50-60 FPS stable.

---

### Warframe (Perfect Performance)

**Problem:** None! Game runs excellently.

**Solution:**
```bash
# Launch options:
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl mesa_glthread=true %command%

# Proton: Any recent version works

# Settings:
Max everything! RX 580 handles Warframe easily.
Graphics: High
Effects: High
Textures: High
Anti-Aliasing: TAA
Frame Rate: Uncapped (or cap at 60 for stability)
```

**Expected:** 60+ FPS constant, even in busy missions.

---

## 🛠️ Tools & Utilities

### Gamemode

**What it does:**
- Adjusts CPU governor to performance
- Adjusts I/O priority
- Adjusts GPU performance mode
- Reduces background processes

**Usage:**
```bash
# Automatic (via launch options)
gamemoderun %command%

# Manual start
gamemoded -s  # Check status
```

**Verify it's working:**
```bash
# While game is running
gamemode-status
# or
gamemoded -s
```

---

### Gamescope (Optional)

Micro-compositor for games. Useful for:
- Better frame pacing
- HDR support (if monitor supports)
- Resolution scaling
- Alt+Tabbing without issues

**Usage:**
```bash
# In launch options
gamescope -w 1920 -h 1080 -f -- %command%

# With FPS limit
gamescope -w 1920 -h 1080 -r 60 -f -- %command%

# Upscaling from 720p
gamescope -W 1920 -H 1080 -w 1280 -h 720 -f -U -- %command%
```

---

### MangoHud (FPS Overlay)

**Enable in launch options:**
```bash
mangohud %command%

# Combined with gamemode
gamemoderun mangohud %command%
```

**Configure overlay:**
```bash
# Edit: ~/.config/MangoHud/MangoHud.conf
fps
gpu_temp
cpu_temp
ram
vram
frame_timing=0
position=top-left
```

**Toggle in-game:** Right Shift + F12

---

### ProtonUp-Qt (Proton Manager)

**Install/Update Proton GE:**
```bash
protonup-qt
# or: Mod + Alt + P
```

**When to use Proton GE:**
- Game doesn't work with standard Proton
- Newer game that needs latest fixes
- Better performance in some titles
- Ubisoft games (Division, Watch Dogs)

---

## 🎨 Graphics Settings Recommendations

### Texture Quality
- **High** - You have 8GB VRAM, use it!
- Only lower to Medium if hitting VRAM limit (rare)

### Shadow Quality
- **Medium** - Shadows are GPU-intensive
- High if FPS is stable, Low if struggling

### Anti-Aliasing
- **TAA** - Best balance for quality/performance
- FXAA if you need more FPS
- MSAA is too expensive, avoid

### Ray Tracing
- **OFF** - RX 580 doesn't support hardware RT
- Huge FPS hit with software RT

### Resolution Scaling / FSR
- **FSR 2.0 Quality** - Great upscaling
- Use if game has FSR support (Cyberpunk, some recent games)
- Render at 75-85%, output 100%

### VSync
- **OFF** - Less input lag
- Use in-game FPS cap at 60 instead

---

## 🔧 System Optimization

### CPU Governor

**Gaming mode sets this automatically.**

Manual control:
```bash
# Performance mode (gaming)
sudo cpupower frequency-set -g performance

# Balanced (default)
sudo cpupower frequency-set -g schedutil

# Check current
cpupower frequency-info
```

---

### GPU Performance Mode

**Gaming mode sets this automatically.**

Manual control:
```bash
# High performance
echo "high" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level

# Auto (default)
echo "auto" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level

# Check current
cat /sys/class/drm/card0/device/power_dpm_force_performance_level
```

---

### Mesa Environment Variables

Already configured in launch options, but for reference:

```bash
RADV_PERFTEST=gpl          # Graphics Pipeline Library (faster loading)
RADV_DEBUG=zerovram        # Helps with crashes (Cyberpunk, Division 2)
mesa_glthread=true         # Threaded optimization
DXVK_ASYNC=1               # Async shader compilation
__GL_SHADER_DISK_CACHE=1   # Cache shaders to disk
```

---

## 📊 Monitoring Performance

### In-Game FPS (MangoHud)

```bash
# Add to launch options
mangohud %command%

# Toggle overlay: Right Shift + F12
```

---

### GPU Monitoring

```bash
# Real-time GPU usage
radeontop

# GPU temperature
gpu-temp

# Detailed info
watch -n 1 cat /sys/class/drm/card0/device/hwmon/hwmon0/temp1_input
```

---

### CPU Monitoring

```bash
# Real-time CPU usage
btop

# CPU temperature
sensors | grep "Package id 0"

# Per-core frequency
watch -n 1 grep MHz /proc/cpuinfo
```

---

## 🎮 Game Launchers

### Steam (Primary)

**Location:** Workspace 9
**Launch:** `Mod + Shift + S` or `steam-launch`

**Tips:**
- Enable Proton for all games
- Use Proton GE for best compatibility
- Verify game files if issues occur
- Check ProtonDB for community reports

---

### Lutris (Secondary)

**Location:** Workspace 9
**Launch:** `Mod + Alt + L` or `lutris-launch`

**Use for:**
- GOG games
- Epic Games Store
- EA/Origin games
- Standalone Wine games
- Emulators

**Tips:**
- Use Wine-GE runner
- Enable DXVK for DirectX games
- Enable Esync/Fsync

---

### Heroic Games Launcher (Epic/GOG)

**Install:**
```bash
paru -S heroic-games-launcher-bin
```

**Use for:**
- Epic Games Store exclusives
- GOG DRM-free games
- Amazon Prime Gaming

---

## 🛡️ Mod Managers (Workspace 10)

### Vortex Mod Manager

**For:** Skyrim, Fallout, Cyberpunk, others

**Setup via Lutris:**
```bash
# Install via Lutris
lutris

# Search: Vortex
# Or manual Wine install
```

**Launch:** `Mod + Alt + V`

---

### Mod Organizer 2 (MO2)

**For:** Bethesda games (Skyrim, Fallout)

**Install:**
```bash
# Via Lutris or Wine
# Download from: https://www.nexusmods.com/skyrimspecialedition/mods/6194
```

**Better than Vortex for:**
- Bethesda games
- Virtual file system
- Profile management
- LOOT integration

---

### Wabbajack

**For:** Modlist installation (Skyrim, Fallout)

**Install:**
```bash
# Via Lutris
# Download from: https://www.wabbajack.org/
```

**Use for:**
- Complete modlist installations
- 1-click mod packs
- Curated experiences

---

## 🚨 Common Issues & Fixes

### Game Won't Launch

```bash
# 1. Check Proton version
Right-click game → Properties → Compatibility → Select Proton GE

# 2. Verify files
Right-click game → Properties → Local Files → Verify integrity

# 3. Clear shader cache
rm -rf ~/.steam/steam/steamapps/shadercache/[APPID]

# 4. Check logs
~/.steam/steam/logs/content_log.txt
```

---

### Low FPS / Stuttering

```bash
# 1. Enable gaming mode
gaming-on

# 2. Check temperatures
gpu-temp  # Should be under 85°C
sensors   # CPU should be under 80°C

# 3. Lower graphics settings
# Try Medium preset first

# 4. Check GPU usage
radeontop
# Should be 90-100% in-game

# 5. Cap FPS
# Set in-game FPS limit to 60
```

---

### Crashes to Desktop

```bash
# 1. Update Mesa drivers
paru -Syu mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon

# 2. Try different Proton
# Test: Proton 8.0, Proton GE, Proton Experimental

# 3. Add debug launch options
PROTON_LOG=1 %command%
# Check log: ~/steam-[appid].log

# 4. Try WINE3D (older games)
PROTON_USE_WINED3D=1 %command%
```

---

### Black Screen / Won't Fullscreen

```bash
# 1. Add fullscreen flag
%command% -fullscreen

# 2. Try borderless
In-game settings: Borderless Fullscreen

# 3. Alt+Enter
Press Alt+Enter in-game to toggle fullscreen

# 4. Check Niri window rules
kate ~/.config/niri/conf.d/20-rules.kdl
# Ensure game has fullscreen rule
```

---

### Controller Not Working

```bash
# 1. Install Steam Input support
paru -S steam-devices

# 2. Enable Steam Input
Steam → Settings → Controller → Enable Steam Input

# 3. For non-Steam games
paru -S antimicrox
# Map controller buttons to keyboard

# 4. Check device
ls /dev/input/
# Controller should appear as js0, js1, etc.
```

---

## 📚 Resources & References

### ProtonDB
Check game compatibility:
https://www.protondb.com

Search your game to see:
- Compatibility rating
- Community reports
- Working launch options
- Known issues

---

### Arch Wiki Gaming
https://wiki.archlinux.org/title/Gaming

Covers:
- Steam setup
- Wine configuration
- Performance tuning
- Troubleshooting

---

### Mesa Documentation
https://docs.mesa3d.org/

Learn about:
- RADV driver (AMD)
- Environment variables
- Performance tuning

---

### r/linux_gaming
https://reddit.com/r/linux_gaming

Community for:
- Game compatibility
- Performance tips
- Troubleshooting help

---

## 🎯 Quick Reference

### Aliases
```bash
gaming              # Toggle gaming mode
gaming-on           # Enable gaming mode
gaming-off          # Disable gaming mode
gaming-status       # Check status
game                # Go to workspace 9
steam-launch        # Launch Steam
lutris-launch       # Launch Lutris
protonup            # Manage Proton versions
gamemode-status     # Check gamemode
gpu                 # Monitor GPU
gpu-temp            # GPU temperature
```

### Keybinds
```
Mod + 9             Gaming workspace
Mod + G             Toggle gaming mode
Mod + Shift + S     Launch Steam
Mod + Alt + L       Launch Lutris
Mod + Alt + P       ProtonUp-Qt
Mod + Alt + V       Vortex (if installed)
```

### Workspaces
- **Workspace 9** - Games, Steam, Lutris
- **Workspace 10** - Mod managers (Vortex, MO2, Wabbajack)

---

## 💡 Pro Tips

1. **Always use gaming mode** - Significant FPS improvement
2. **Cap FPS at 60** - More stable than uncapped
3. **Use Proton GE** - Better compatibility than stock Proton
4. **Check ProtonDB first** - Save time troubleshooting
5. **Verify game files** - First step for crashes
6. **Medium settings are fine** - RX 580 sweet spot
7. **Disable RT always** - No hardware support
8. **Update Mesa regularly** - Driver improvements frequent
9. **Use MangoHud** - Monitor performance in real-time
10. **Save qpwgraph layout** - For streaming with game audio

---

## 🎮 Game Library Summary

Your 16 pre-configured games:

✅ Call of Duty HQ  
✅ Cyberpunk 2077 ⚠️ (needs tweaks)  
✅ Fallout 4 ⚠️ (use WINE3D)  
✅ FarCry 5  
✅ Ghost Recon Breakpoint  
✅ Marvel's Avengers  
✅ Need for Speed Payback  
✅ Rise of the Tomb Raider  
✅ Shadow of the Tomb Raider  
✅ The First Descendant ⚠️ (anti-cheat)  
✅ Tom Clancy's The Division  
✅ Tom Clancy's The Division 2 ⚠️ (needs tweaks)  
✅ Warframe ⭐ (perfect)  
✅ Watch Dogs  
✅ Watch Dogs 2  
✅ Watch Dogs Legion  

**Legend:**
- ⭐ Runs perfectly
- ⚠️ Requires specific configuration
- All have optimized launch options in `STEAM-LAUNCH-OPTIONS.md`

---

**Made for WehttamSnaps** | Photography • Gaming • Content Creation

**Happy Gaming! 🎮**
