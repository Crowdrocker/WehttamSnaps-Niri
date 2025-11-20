# Steam Launch Options - WehttamSnaps Gaming Setup

**Optimized for:** Dell XPS 8700 | i7-4790 | RX 580 | 16GB RAM  
**Arch Linux** with **Mesa/RADV** drivers

---

## 🎮 How to Apply Launch Options

1. Open Steam
2. Right-click game in library
3. Select **Properties**
4. Under **General** tab, find **Launch Options**
5. Copy and paste the options below
6. Close properties (auto-saves)

---

## 🚀 Universal Launch Options (All Games)

Use these as a base for any game not listed:

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl %command%
```

**What it does:**
- `gamemoderun` - Enables gamemode (CPU performance)
- `PROTON_ENABLE_NVAPI=1` - Better NVIDIA API translation
- `DXVK_ASYNC=1` - Async shader compilation (smoother)
- `RADV_PERFTEST=gpl` - AMD GPU pipeline optimizations

---

## 📋 Per-Game Launch Options

### 1. Call of Duty HQ / Modern Warfare / Warzone

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 PROTON_HIDE_NVIDIA_GPU=0 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11,dxr mesa_glthread=true __GL_THREADED_OPTIMIZATIONS=1 %command% -fullscreen
```

**Notes:**
- Uses Proton GE (install via ProtonUp-Qt)
- Force fullscreen mode
- DXR11 for better compatibility
- May need to disable HDR in-game

**Compatibility:** ✅ Gold (some anti-cheat issues)

---

### 2. Cyberpunk 2077

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl RADV_DEBUG=zerovram DXVK_STATE_CACHE=1 VKD3D_CONFIG=dxr11 mesa_glthread=true %command% -fullscreen -skipStartScreen
```

**Notes:**
- `-skipStartScreen` - Skip intro videos
- `RADV_DEBUG=zerovram` - Helps with crashes
- Use Proton GE (latest)
- Set graphics to Medium-High for stable 60 FPS
- **Known Issue Fix:** If crashing on startup, disable Ray Tracing in settings

**Compatibility:** ✅ Platinum

---

### 3. Fallout 4

```bash
gamemoderun PROTON_USE_WINED3D=1 PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 %command% -fullscreen -nolauncher
```

**Notes:**
- `-nolauncher` - Skip Bethesda launcher
- Uses WINE3D instead of DXVK (better compatibility)
- For modding: Install MO2 separately via Wine/Lutris
- **Window Fix:** Game may start windowed - Alt+Enter to fullscreen

**Additional Fix for crashes:**
Add to `Fallout4Prefs.ini` (Documents/My Games/Fallout4/):
```ini
[General]
bBorderless=1
bFull Screen=0
iSize H=1080
iSize W=1920
```

**Compatibility:** ✅ Gold

---

### 4. FarCry 5

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 mesa_glthread=true %command% -fullscreen
```

**Notes:**
- Use Proton GE or Proton Experimental
- Ubisoft Connect overlay may cause issues - disable if laggy
- Works great with RX 580

**Compatibility:** ✅ Platinum

---

### 5. Ghost Recon Breakpoint

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 PROTON_USE_WINED3D=0 %command%
```

**Notes:**
- Requires Ubisoft Connect
- May need to run Uplay in offline mode first time
- Online works but anti-cheat may flag (play offline recommended)

**Compatibility:** ⚠️ Silver (online issues)

---

### 6. Marvel's Avengers

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 DXVK_STATE_CACHE=1 mesa_glthread=true %command% -dx12
```

**Notes:**
- Force DirectX 12 mode
- Online functionality limited
- Single-player campaign works well

**Compatibility:** ✅ Gold

---

### 7. Need for Speed Payback

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl mesa_glthread=true %command% -fullscreen
```

**Notes:**
- Origin overlay may cause issues - disable in Origin settings
- Use Proton GE
- Works well with RX 580

**Compatibility:** ✅ Platinum

---

### 8. Rise of the Tomb Raider

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl RADV_DEBUG=zerovram mesa_glthread=true %command% -fullscreen
```

**Notes:**
- Excellent compatibility
- Use High settings for 60 FPS
- VXAO works but may drop FPS

**Compatibility:** ✅ Platinum

---

### 9. Shadow of the Tomb Raider

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 RADV_DEBUG=zerovram mesa_glthread=true %command% -fullscreen
```

**Notes:**
- DX12 mode works best
- Ray tracing available but impacts FPS heavily
- Use Medium-High for stable 60 FPS

**Compatibility:** ✅ Platinum

---

### 10. The First Descendant

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 DXVK_STATE_CACHE=1 mesa_glthread=true __GL_SHADER_DISK_CACHE=1 __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1 %command%
```

**Notes:**
- Free-to-play, online required
- Anti-cheat may have issues - check ProtonDB
- Shader caching helps with stuttering

**Compatibility:** ⚠️ Silver (anti-cheat)

---

### 11. Tom Clancy's The Division

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 mesa_glthread=true %command% -fullscreen
```

**Notes:**
- Ubisoft Connect required
- Works well in offline/solo mode
- Online Dark Zone may have connectivity issues

**Compatibility:** ✅ Gold

---

### 12. Tom Clancy's The Division 2

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 RADV_DEBUG=zerovram DXVK_STATE_CACHE=1 mesa_glthread=true __GL_SHADER_DISK_CACHE=1 %command% -dx12 -fullscreen
```

**Critical Crash Fix:**
If game crashes on startup or during gameplay:

1. **Disable EAC in compatibility mode:**
   - Right-click game → Properties → Compatibility
   - Check "Force the use of a specific Steam Play compatibility tool"
   - Select Proton Experimental or latest Proton GE

2. **Add to launch options:**
   ```bash
   PROTON_USE_WINED3D=0 PROTON_NO_ESYNC=0 PROTON_NO_FSYNC=0
   ```

3. **Set graphics to Medium in-game**

4. **Verify game files** if still crashing

**Window Mode Fix:**
- Game may start in windowed mode
- Alt+Enter to toggle fullscreen
- Or set in-game: Settings → Graphics → Display Mode → Fullscreen

**Compatibility:** ⚠️ Silver (crashes, but fixable)

---

### 13. Warframe

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl mesa_glthread=true %command%
```

**Notes:**
- Excellent compatibility
- Works perfectly with RX 580
- 60+ FPS on High settings
- Online works flawlessly

**Compatibility:** ✅ Platinum

---

### 14. Watch Dogs

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl mesa_glthread=true PROTON_NO_ESYNC=1 %command% -fullscreen
```

**Notes:**
- Older game, runs well
- Ubisoft Connect may need offline mode
- Disable Uplay overlay for best performance

**Compatibility:** ✅ Gold

---

### 15. Watch Dogs 2

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 mesa_glthread=true %command% -fullscreen
```

**Notes:**
- Use Proton GE
- High settings for 60 FPS
- Ubisoft Connect required

**Compatibility:** ✅ Platinum

---

### 16. Watch Dogs: Legion

```bash
gamemoderun PROTON_ENABLE_NVAPI=1 DXVK_ASYNC=1 RADV_PERFTEST=gpl VKD3D_CONFIG=dxr11 RADV_DEBUG=zerovram DXVK_STATE_CACHE=1 mesa_glthread=true %command% -dx12 -fullscreen
```

**Notes:**
- Most demanding Watch Dogs game
- Use Medium-High settings for stable 60 FPS
- Ray tracing off for RX 580
- Proton GE required

**Compatibility:** ✅ Gold

---

## 🛠️ Troubleshooting Common Issues

### Game won't start
```bash
# Check Proton version
Right-click game → Properties → Compatibility → Select Proton GE or Experimental

# Verify game files
Right-click game → Properties → Local Files → Verify integrity
```

### Stuttering / Low FPS
```bash
# Enable gaming mode
Mod + G (in Niri)

# Check gamemode status
gamemoded -s

# Monitor GPU usage
radeontop
```

### Crashes on startup
```bash
# Try WINE3D instead of DXVK
PROTON_USE_WINED3D=1 %command%

# Disable ESYNC/FSYNC
PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 %command%

# Clear shader cache
rm -rf ~/.steam/steam/steamapps/shadercache/[APPID]
```

### Window mode issues
```bash
# Force fullscreen
%command% -fullscreen

# Or use Alt+Enter in-game to toggle fullscreen
```

---

## 📊 Expected Performance (RX 580 @ 1080p)

| Game | Settings | FPS |
|------|----------|-----|
| Cyberpunk 2077 | Medium-High | 55-60 |
| Division 2 | Medium | 60 |
| Fallout 4 | Ultra | 60 |
| FarCry 5 | High | 60+ |
| Shadow of Tomb Raider | High | 55-60 |
| Warframe | High | 60+ |
| Watch Dogs Legion | Medium | 50-60 |

---

## 🎯 Recommended Proton Versions

**Install via ProtonUp-Qt** (`Mod + Alt + P`):

- **Proton GE (Latest)** - Best compatibility for most games
- **Proton Experimental** - Valve's cutting-edge fixes
- **Proton 9.0** - Stable fallback

**Per-game recommendations:**
- Cyberpunk 2077: Proton GE
- Division 2: Proton Experimental
- Fallout 4: Proton 8.0 or earlier (WINE3D works better)
- All Watch Dogs: Proton GE

---

## 🔧 System Optimizations Applied

When gaming mode is enabled (`Mod + G`):

✅ CPU governor → performance  
✅ GPU power mode → high  
✅ Animations disabled  
✅ J.A.R.V.I.S. notification  
✅ Window rules optimized  

---

## 📝 Notes

- **Anti-cheat games:** Some online games may not work due to anti-cheat (The First Descendant, COD)
- **Ubisoft Connect:** Requires separate login, may need offline mode for stability
- **ProtonDB:** Check https://protondb.com for latest community reports
- **Mesa drivers:** Keep updated via `paru -Syu mesa lib32-mesa`

---

## 🎮 Quick Commands

```bash
# Install Proton GE
protonup-qt

# Check game compatibility
xdg-open https://protondb.com

# Monitor GPU
radeontop

# Enable gaming mode
~/.config/wehttamsnaps/scripts/toggle-gamemode.sh on

# Steam logs
~/.steam/steam/logs/
```

---

**Made for WehttamSnaps** | Photography • Gaming • Content Creation  
**Hardware:** Dell XPS 8700 | i7-4790 | RX 580 | 16GB RAM
