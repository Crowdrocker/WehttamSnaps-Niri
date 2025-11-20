#!/bin/bash
# J.A.R.V.I.S. System Monitoring Script
# Monitors system health and triggers warnings

SOUNDS_DIR="$HOME/.config/jarvis/sounds"
WARNING_SCRIPT="$HOME/.config/jarvis/scripts/jarvis-warning.sh"

# Temperature thresholds (Celsius)
CPU_TEMP_THRESHOLD=80
GPU_TEMP_THRESHOLD=85

# Disk space threshold (percentage)
DISK_THRESHOLD=90

# Check interval (seconds)
CHECK_INTERVAL=60

while true; do
    # Check CPU temperature
    if command -v sensors &> /dev/null; then
        CPU_TEMP=$(sensors | grep -i 'Package id 0' | awk '{print $4}' | sed 's/+//;s/°C//')
        if [ ! -z "$CPU_TEMP" ]; then
            if (( $(echo "$CPU_TEMP > $CPU_TEMP_THRESHOLD" | bc -l) )); then
                "$WARNING_SCRIPT" "CPU temperature critical: ${CPU_TEMP}°C"
            fi
        fi
    fi
    
    # Check GPU temperature (AMD)
    if [ -f /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input ]; then
        GPU_TEMP=$(cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
        if [ ! -z "$GPU_TEMP" ]; then
            GPU_TEMP=$((GPU_TEMP / 1000))
            if [ "$GPU_TEMP" -gt "$GPU_TEMP_THRESHOLD" ]; then
                "$WARNING_SCRIPT" "GPU temperature critical: ${GPU_TEMP}°C"
            fi
        fi
    fi
    
    # Check disk space
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
        "$WARNING_SCRIPT" "Disk space critical: ${DISK_USAGE}% used"
    fi
    
    # Check memory usage
    MEM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    if [ "$MEM_USAGE" -gt 90 ]; then
        "$WARNING_SCRIPT" "Memory usage high: ${MEM_USAGE}%"
    fi
    
    sleep "$CHECK_INTERVAL"
done