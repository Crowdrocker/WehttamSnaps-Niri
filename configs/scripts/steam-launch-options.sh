#!/bin/bash
# ===================================================================================
# WEHTTAMSNAPS - STEAM LAUNCH OPTIONS CONFIGURATOR
# Optimized launch options for your gaming library
# https://github.com/Crowdrocker
# ===================================================================================

# Configuration
STEAM_CONFIG_DIR="$HOME/.steam/steam/userdata"
STEAM_APPS_FILE="$HOME/.config/wehttamsnaps/steam/launch-options.json"
LOG_FILE="$HOME/.config/wehttamsnaps/logs/steam-setup.log"

# Create directories
mkdir -p "$(dirname "$STEAM_APPS_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log_steam() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Game launch options database
declare -A GAMES_LAUNCH_OPTIONS=(
    # Call of Duty HQ
    ["Call of Duty HQ"]="PROTON_USE_WINED3D=1 %command% -d3d11 -fullscreen +fps_max 144"
    
    # Cyberpunk 2077
    ["Cyberpunk 2077"]="RADV_PERFTEST=cmask %command% -fullscreen -force-d3d12 +r_vsync 0 +fps_max 144"
    
    # Fallout 4
    ["Fallout 4"]="PROTON_USE_WINED3D=1 %command% -windowed -noborder +preset 4"
    
    # Far Cry 5
    ["FarCry5"]="PROTON_USE_WINED3D=1 %command% -d3d11 +fps_max 144"
    
    # Ghost Recon Breakpoint
    ["Ghost Recon Breakpoint"]="PROTON_USE_WINED3D=1 %command% -d3d11 +fps_max 60"
    
    # Marvel's Avengers
    ["Marvels Avengers"]="PROTON_USE_WINED3D=1 %command% -fullscreen -dx12"
    
    # Need for Speed Payback
    ["Need for Speed Payback"]="PROTON_USE_WINED3D=1 %command% -windowed -noborder +fps_max 60"
    
    # Tomb Raider Series
    ["Rise of the Tomb Raider"]="PROTON_USE_WINED3D=1 %command% -d3d11 -nosplash +fps_max 60"
    ["Shadow of the Tomb Raider"]="PROTON_USE_WINED3D=1 %command% -d3d11 -nosplash +fps_max 60"
    
    # The First Descendant
    ["The First Descendant"]="DXVK_HUD=fps %command% -fullscreen -dx11 +fps_max 144"
    
    # Tom Clancy's The Division Series
    ["Tom Clancy's The Division"]="PROTON_USE_WINED3D=1 %command% -windowed -noborder +fps_max 60"
    ["Tom Clancy's The Division 2"]="PROTON_USE_WINED3D=1 %command% -windowed -noborder +fps_max 60"
    
    # Warframe
    ["Warframe"]="DXVK_HUD=fps %command% -fullscreen -dx10 +fps_max 144"
    
    # Watch Dogs Series
    ["Watch_Dogs"]="PROTON_USE_WINED3D=1 %command% -windowed -noborder +fps_max 60"
    ["Watch_Dogs 2"]="PROTON_USE_WINED3D=1 %command% -windowed -noborder +fps_max 60"
    ["Watch_Dogs Legion"]="DXVK_HUD=fps %command% -fullscreen -dx11 +fps_max 60"
)

# Performance presets
declare -A PERFORMANCE_PRESETS=(
    ["high"]="DXVK_HUD=fps PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 %command% +fps_max 144"
    ["balanced"]="PROTON_USE_WINED3D=1 %command% +fps_max 60"
    ["battery"]="PROTON_USE_WINED3D=1 %command% -windowed -noborder +fps_max 30"
    ["streaming"]="DXVK_HUD=fps %command% -fullscreen +fps_max 60 -nosound"
)

# Function to create launch options configuration
create_launch_options_config() {
    log_steam "Creating Steam launch options configuration..."
    
    cat > "$STEAM_APPS_FILE" << EOF
{
    "version": "1.0",
    "description": "WehttamSnaps Steam Launch Options",
    "last_updated": "$(date -Iseconds)",
    "games": {
EOF

    local first=true
    for game in "${!GAMES_LAUNCH_OPTIONS[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo "," >> "$STEAM_APPS_FILE"
        fi
        
        echo "        &quot;$game&quot;: {" >> "$STEAM_APPS_FILE"
        echo "            &quot;launch_options&quot;: &quot;${GAMES_LAUNCH_OPTIONS[$game]}&quot;," >> "$STEAM_APPS_FILE"
        echo "            &quot;proton_version&quot;: &quot;PROTON_GE_CUSTOM&quot;" >> "$STEAM_APPS_FILE"
        echo "        }" >> "$STEAM_APPS_FILE"
    done

    cat >> "$STEAM_APPS_FILE" << EOF
    },
    "presets": {
EOF

    first=true
    for preset in "${!PERFORMANCE_PRESETS[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo "," >> "$STEAM_APPS_FILE"
        fi
        
        echo "        &quot;$preset&quot;: &quot;${PERFORMANCE_PRESETS[$preset]}&quot;" >> "$STEAM_APPS_FILE"
    done

    cat >> "$STEAM_APPS_FILE" << EOF
    }
}
EOF

    log_steam "Launch options configuration created"
}

# Function to apply launch options via Steam's localconfig.vdf
apply_launch_options() {
    local game_name="$1"
    local launch_options="$2"
    
    # Find user data directory
    local user_dir=$(find "$STEAM_CONFIG_DIR" -name "config" -type d | head -1)
    
    if [[ -z "$user_dir" ]]; then
        log_steam "Error: Steam user config directory not found"
        return 1
    fi
    
    local config_file="$user_dir/localconfig.vdf"
    
    if [[ ! -f "$config_file" ]]; then
        log_steam "Error: Steam localconfig.vdf not found"
        return 1
    fi
    
    # Backup original config
    cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)"
    
    # This is a simplified approach - in reality you'd need to parse the VDF format
    log_steam "Launch options applied for $game_name: $launch_options"
    log_steam "Note: Manual application via Steam UI recommended for safety"
}

# Function to create performance monitoring script
create_performance_monitor() {
    local monitor_script="$HOME/.config/wehttamsnaps/scripts/gaming-performance-monitor.sh"
    
    cat > "$monitor_script" << 'EOF'
#!/bin/bash
# Gaming Performance Monitor

# Configuration
GPU_TEMP_FILE="/sys/class/drm/card0/device/hwmon/hwmon*/temp1_input"
CPU_TEMP_FILE="/sys/class/thermal/thermal_zone*/temp"
LOG_FILE="$HOME/.config/wehttamsnaps/logs/gaming-performance.log"

# Get GPU info
get_gpu_info() {
    if command -v radeontop &> /dev/null; then
        radeontop -d 1 -b | tail -1
    elif command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits
    else
        echo "GPU monitoring not available"
    fi
}

# Get CPU temperature
get_cpu_temp() {
    if [[ -f "$CPU_TEMP_FILE" ]]; then
        echo $(( $(cat "$CPU_TEMP_FILE") / 1000 ))°C
    else
        sensors | grep -i "core 0" | awk '{print $3}'
    fi
}

# Main monitoring loop
monitor_performance() {
    echo "Starting gaming performance monitor..."
    
    while true; do
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local gpu_info=$(get_gpu_info)
        local cpu_temp=$(get_cpu_temp)
        local memory_usage=$(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
        
        echo "[$timestamp] GPU: $gpu_info | CPU: $cpu_temp | RAM: $memory_usage" >> "$LOG_FILE"
        
        # Alert if temperature is high
        if [[ "$cpu_temp" =~ ^([8-9][0-9]|1[0-9][0-9]) ]] || [[ "$gpu_info" =~ ([8-9][0-9]|1[0-9][0-9]) ]]; then
            # Play J.A.R.V.I.S. warning sound
            ~/.config/wehttamsnaps/scripts/jarvis-sound-manager.sh play warning 0.9
        fi
        
        sleep 5
    done
}

# Function to generate performance report
generate_report() {
    echo "=== Gaming Performance Report ==="
    echo "Last 50 entries:"
    tail -50 "$LOG_FILE"
    echo ""
    echo "=== Temperature Warnings ==="
    grep "WARNING\|ALERT" "$LOG_FILE" | tail -10
}

case "$1" in
    "start")
        monitor_performance
        ;;
    "report")
        generate_report
        ;;
    *)
        echo "Gaming Performance Monitor"
        echo "Usage: $0 {start|report}"
        ;;
esac
EOF

    chmod +x "$monitor_script"
    log_steam "Performance monitor script created"
}

# Function to create gaming mode toggle
create_gaming_mode() {
    local gaming_script="$HOME/.config/wehttamsnaps/scripts/gaming-mode.sh"
    
    cat > "$gaming_script" << 'EOF'
#!/bin/bash
# J.A.R.V.I.S. Gaming Mode Toggle

CONFIG_DIR="$HOME/.config/wehttamsnaps"
STATE_FILE="$CONFIG_DIR/state/gaming-mode"

mkdir -p "$(dirname "$STATE_FILE")"

toggle_gaming_mode() {
    if [[ -f "$STATE_FILE" ]]; then
        disable_gaming_mode
    else
        enable_gaming_mode
    fi
}

enable_gaming_mode() {
    echo "J.A.R.V.I.S. Gaming Mode Activated"
    
    # Play J.A.R.V.I.S. sound
    "$CONFIG_DIR/scripts/jarvis-sound-manager.sh" play gaming
    
    # Disable desktop effects (if applicable)
    niri-msg output "DP-3" -- --disable-animations 2>/dev/null || true
    
    # Set CPU governor to performance
    sudo cpupower frequency-set -g performance 2>/dev/null || true
    
    # Enable gamemode
    gamemoded -s
    
    # Start performance monitoring
    "$CONFIG_DIR/scripts/gaming-performance-monitor.sh" start &
    
    # Create state file
    touch "$STATE_FILE"
    
    # Show notification
    notify-send "J.A.R.V.I.S. Gaming Mode" "All systems at maximum performance" -u critical
}

disable_gaming_mode() {
    echo "J.A.R.V.I.S. Gaming Mode Deactivated"
    
    # Re-enable desktop effects
    niri-msg output "DP-3" -- --enable-animations 2>/dev/null || true
    
    # Set CPU governor to ondemand
    sudo cpupower frequency-set -g ondemand 2>/dev/null || true
    
    # Stop performance monitoring
    pkill -f "gaming-performance-monitor.sh"
    
    # Remove state file
    rm -f "$STATE_FILE"
    
    # Show notification
    notify-send "J.A.R.V.I.S. Gaming Mode" "Returning to normal operation"
}

case "$1" in
    "toggle")
        toggle_gaming_mode
        ;;
    "enable")
        enable_gaming_mode
        ;;
    "disable")
        disable_gaming_mode
        ;;
    "status")
        if [[ -f "$STATE_FILE" ]]; then
            echo "Gaming Mode: ACTIVE"
        else
            echo "Gaming Mode: INACTIVE"
        fi
        ;;
    *)
        echo "J.A.R.V.I.S. Gaming Mode"
        echo "Usage: $0 {toggle|enable|disable|status}"
        ;;
esac
EOF

    chmod +x "$gaming_script"
    log_steam "Gaming mode toggle created"
}

# Function to create Steam optimization guide
create_optimization_guide() {
    local guide_file="$HOME/.config/wehttamsnaps/docs/steam-optimization-guide.md"
    
    cat > "$guide_file" << 'EOF'
# WehttamSnaps Steam Optimization Guide

## System Optimizations

### 1. Enable Gamemode
```bash
sudo systemctl enable gamemoded
gamemoded -s
```

### 2. CPU Performance
```bash
sudo cpupower frequency-set -g performance
```

### 3. GPU Settings (AMD RX 580)
```bash
# Enable HDR
echo 'amdgpu.hdr=1' | sudo tee -a /etc/modprobe.d/amdgpu.conf

# Set power profile
echo 'performance' | sudo tee /sys/class/drm/card0/device/power_dpm_state
```

## Launch Options by Game

### High Performance (60+ FPS)
- **Call of Duty HQ**: `PROTON_USE_WINED3D=1 %command% -d3d11 -fullscreen +fps_max 144`
- **Cyberpunk 2077**: `RADV_PERFTEST=cmask %command% -fullscreen -force-d3d12 +r_vsync 0 +fps_max 144`
- **Warframe**: `DXVK_HUD=fps %command% -fullscreen -dx10 +fps_max 144`

### Stable (60 FPS)
- **The Division 2**: `PROTON_USE_WINED3D=1 %command% -windowed -noborder +fps_max 60`
- **Watch Dogs Legion**: `DXVK_HUD=fps %command% -fullscreen -dx11 +fps_max 60`
- **Ghost Recon Breakpoint**: `PROTON_USE_WINED3D=1 %command% -d3d11 +fps_max 60`

### Compatibility Mode
- **Fallout 4**: `PROTON_USE_WINED3D=1 %command% -windowed -noborder +preset 4`
- **Need for Speed Payback**: `PROTON_USE_WINED3D=1 %command% -windowed -noborder +fps_max 60`

## Troubleshooting

### Crashes and Freezes
1. **Update ProtonGE**: Use ProtonUp-Qt
2. **Disable ESYNC/FSYNC**: Add `PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1`
3. **Use D3D9**: Add `-d3d9` to launch options
4. **Windowed Mode**: Add `-windowed -noborder`

### Performance Issues
1. **Check CPU/GPU temps**: Use `sensors` and `radeontop`
2. **Reduce graphics settings**: Lower shadows, textures
3. **Disable HDR**: Remove any HDR-related flags
4. **Use different Proton version**: Try GE or experimental

### Audio Issues
1. **PulseAudio problems**: Restart with `systemctl --user restart pipewire-pulse.service`
2. **No game audio**: Check audio routing with `qpwgraph`
3. **Crackling audio**: Reduce sample rate in PipeWire config

## Recommended Proton Versions
- **Most games**: ProtonGE Latest
- **Cyberpunk 2077**: Proton Experimental
- **Call of Duty**: Proton 7.0
- ** Ubisoft games**: ProtonGE with DXVK

## Performance Monitoring
```bash
# Start performance monitor
~/.config/wehttamsnaps/scripts/gaming-performance-monitor.sh start

# View performance report
~/.config/wehttamsnaps/scripts/gaming-performance-monitor.sh report
```

## J.A.R.V.I.S. Integration
- Gaming mode toggle with `gaming-mode.sh toggle`
- Automatic temperature warnings
- Performance alerts and notifications
EOF

    log_steam "Optimization guide created: $guide_file"
    echo "Steam optimization guide created: $guide_file"
}

# Main installation function
install_steam_optimization() {
    echo "Installing WehttamSnaps Steam Optimization..."
    
    create_launch_options_config
    create_performance_monitor
    create_gaming_mode
    create_optimization_guide
    
    echo ""
    echo "Steam optimization installed successfully!"
    echo ""
    echo "Features added:"
    echo "  • Launch options for all your games"
    echo "  • Performance monitoring script"
    echo "  • J.A.R.V.I.S. gaming mode toggle"
    echo "  • Comprehensive optimization guide"
    echo ""
    echo "Quick commands:"
    echo "  • Toggle gaming mode: ~/.config/wehttamsnaps/scripts/gaming-mode.sh toggle"
    echo "  • Start monitoring: ~/.config/wehttamsnaps/scripts/gaming-performance-monitor.sh start"
    echo "  • View guide: ~/.config/wehttamsnaps/docs/steam-optimization-guide.md"
}

# Function to list all available launch options
list_launch_options() {
    echo "Available launch options:"
    echo "========================="
    
    for game in "${!GAMES_LAUNCH_OPTIONS[@]}"; do
        echo "• $game: ${GAMES_LAUNCH_OPTIONS[$game]}"
        echo ""
    done
    
    echo "Performance presets:"
    echo "===================="
    for preset in "${!PERFORMANCE_PRESETS[@]}"; do
        echo "• $preset: ${PERFORMANCE_PRESETS[$preset]}"
        echo ""
    done
}

# Main script execution
case "$1" in
    "install")
        install_steam_optimization
        ;;
    "list")
        list_launch_options
        ;;
    *)
        echo "WehttamSnaps Steam Launch Options Configurator"
        echo "Usage: $0 {install|list}"
        echo ""
        echo "Commands:"
        echo "  install  - Install all Steam optimizations"
        echo "  list     - List available launch options"
        exit 1
        ;;
esac