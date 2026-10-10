#!/bin/bash
# WehttamSnaps J.A.R.V.I.S. WILD Integration Examples
# Crazy useful combinations for your Niri + Gaming + Photography setup
# Author: Matthew (WehttamSnaps)

# ═══════════════════════════════════════════════════════════════════
# REAL-TIME CONFIG OPTIMIZATION
# ═══════════════════════════════════════════════════════════════════

# Optimize config file on the fly
optimize-config() {
    local config_file="${1:-$HOME/.config/niri/config.kdl}"
    local output="${config_file}.optimized"
    
    echo "🔧 Optimizing $config_file..."
    sound-system notification
    
    cat "$config_file" | gemini "Optimize this Niri config for AMD RX 580 + i7-4790. Focus on gaming performance and smooth animations. Return ONLY the optimized KDL config, no explanations:" > "$output"
    
    echo "✅ Optimized config saved to: $output"
    echo "Review it, then: mv $output $config_file && niri msg action reload-config"
}

# ═══════════════════════════════════════════════════════════════════
# GAME LAUNCH WITH AI TIPS
# ═══════════════════════════════════════════════════════════════════

# Launch game with performance analysis
smart-game() {
    local game="$1"
    
    if [ -z "$game" ]; then
        echo "Usage: smart-game <game-name>"
        return 1
    fi
    
    sound-system notification
    
    # Get pre-launch tips
    echo "🎮 Fetching optimal settings for $game..."
    jarvis-game-settings "$game"
    
    echo ""
    read -p "Launch game? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sound-system steam-launch
        
        # Try to launch via Steam
        steam steam://rungameid/$(echo "$game" | tr '[:upper:]' '[:lower:]') &
        
        echo ""
        echo "💡 Tip: Run 'game-fix' after playing to analyze any issues"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# PHOTOGRAPHY WORKFLOW AUTOMATION
# ═══════════════════════════════════════════════════════════════════

# Export photos with AI-generated naming
smart-export() {
    local photo_dir="${1:-.}"
    
    echo "📸 Analyzing photos in $photo_dir..."
    
    # Get AI suggestions for organization
    find "$photo_dir" -type f \( -name "*.jpg" -o -name "*.raw" -o -name "*.dng" \) -printf "%f\n" | head -20 | \
    gemini "Based on these photo filenames, suggest an organized folder structure and naming convention for landscape photography. Be specific:"
    
    sound-system photo-export
}

# Darktable module suggester based on image analysis
dt-suggest() {
    local raw_file="$1"
    
    if [ -z "$raw_file" ]; then
        echo "Usage: dt-suggest <raw-file.dng>"
        return 1
    fi
    
    # Extract EXIF data
    exiftool "$raw_file" 2>/dev/null | grep -E "(ISO|Exposure|Aperture|Focal)" | \
    gemini "Based on these camera settings, suggest which Darktable modules to use and in what order for optimal landscape processing:"
}

# ═══════════════════════════════════════════════════════════════════
# SYSTEM MONITORING WITH AI ALERTS
# ═══════════════════════════════════════════════════════════════════

# Watch system and alert on issues
jarvis-monitor() {
    echo "👁️  J.A.R.V.I.S. monitoring system (Ctrl+C to stop)..."
    
    while true; do
        # Check CPU temp (if sensors available)
        if command -v sensors &> /dev/null; then
            temp=$(sensors | grep -oP 'CPU.*?\+\K[0-9.]+' | head -1)
            if (( $(echo "$temp > 80" | bc -l 2>/dev/null || echo 0) )); then
                sound-system notification
                notify-send "J.A.R.V.I.S. Alert" "CPU temperature critical: ${temp}°C" -u critical
            fi
        fi
        
        # Check memory
        mem_percent=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
        if [ "$mem_percent" -gt 90 ]; then
            sound-system notification
            
            # Get AI analysis of memory hogs
            ps aux --sort=-%mem | head -6 | \
            gemini "Memory at ${mem_percent}%. Which processes should I close? Be specific:" | \
            notify-send "J.A.R.V.I.S. Memory Alert" "$(cat -)" -u critical
        fi
        
        sleep 30
    done
}

# ═══════════════════════════════════════════════════════════════════
# PROTON LOG AUTO-ANALYSIS
# ═══════════════════════════════════════════════════════════════════

# Watch Proton logs in real-time
watch-proton() {
    echo "👀 Watching for Proton crashes..."
    
    # Find most recent compatdata directory
    local compat_dir="$HOME/.steam/steam/steamapps/compatdata"
    
    if [ ! -d "$compat_dir" ]; then
        echo "❌ Steam compatdata not found"
        return 1
    fi
    
    # Monitor for new log entries
    inotifywait -m -e modify -e create "$compat_dir" --include '.*\.log$' 2>/dev/null | \
    while read path action file; do
        if [[ "$file" =~ .*error.*|.*crash.* ]]; then
            sound-system notification
            echo "⚠️  Potential issue detected in: $file"
            
            # Auto-analyze the log
            tail -100 "$path/$file" | jarvis-debug
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════
# NIRI WORKSPACE AUTOMATION
# ═══════════════════════════════════════════════════════════════════

# Auto-setup workspace based on task
setup-workspace() {
    local task="$1"
    
    case "$task" in
        gaming)
            echo "🎮 Setting up gaming workspace..."
            sound-system workspace 2
            
            # Get app recommendations
            jarvis-ask "I'm setting up a gaming workspace. Which apps should I launch alongside Steam for the best experience?"
            ;;
            
        photography)
            echo "📸 Setting up photography workspace..."
            sound-system workspace 3
            
            # Launch apps
            darktable &
            gimp &
            
            jarvis-photo-tips "Quick workflow setup"
            ;;
            
        streaming)
            echo "🎥 Setting up streaming workspace..."
            sound-system workspace 4
            
            obs &
            
            jarvis-ask "Best OBS settings for streaming games on AMD RX 580?"
            ;;
            
        *)
            echo "Usage: setup-workspace <gaming|photography|streaming>"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# SMART KEYBIND DOCUMENTATION
# ═══════════════════════════════════════════════════════════════════

# Generate cheatsheet from your keybinds
keybind-cheatsheet() {
    local keybind_file="$HOME/.config/niri/snaps/10-wiri_keybinds.kdl"
    
    if [ ! -f "$keybind_file" ]; then
        echo "❌ Keybind file not found"
        return 1
    fi
    
    echo "📋 Generating interactive keybind cheatsheet..."
    
    cat "$keybind_file" | \
    gemini "Create a beautiful, categorized markdown cheatsheet from these Niri keybindings. Group by function (Window, Workspace, Apps, etc). Format with emoji:" > /tmp/keybinds.md
    
    # Display in your favorite viewer
    if command -v glow &> /dev/null; then
        glow /tmp/keybinds.md
    elif command -v bat &> /dev/null; then
        bat /tmp/keybinds.md
    else
        cat /tmp/keybinds.md
    fi
}

# ═══════════════════════════════════════════════════════════════════
# DOTFILE BACKUP WITH AI DESCRIPTIONS
# ═══════════════════════════════════════════════════════════════════

# Backup configs with AI-generated commit messages
smart-backup() {
    local config_dir="$HOME/.config"
    local backup_dir="$HOME/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
    
    mkdir -p "$backup_dir"
    
    echo "💾 Backing up configs..."
    
    # Copy important configs
    cp -r "$config_dir/niri" "$backup_dir/"
    cp -r "$config_dir/wehttamsnaps" "$backup_dir/"
    
    # Generate AI description
    echo "📝 Generating backup description..."
    
    local changes=$(find "$config_dir/niri" "$config_dir/wehttamsnaps" -type f -mtime -1 -exec basename {} \; 2>/dev/null)
    
    if [ -n "$changes" ]; then
        echo "$changes" | gemini "Generate a git commit message describing these config changes. Be concise and technical:" > "$backup_dir/CHANGES.txt"
    fi
    
    echo "✅ Backup saved to: $backup_dir"
    cat "$backup_dir/CHANGES.txt" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# GPU PERFORMANCE MONITORING
# ═══════════════════════════════════════════════════════════════════

# Real-time GPU analysis
gpu-watch() {
    echo "🎮 Monitoring AMD RX 580 performance..."
    
    while true; do
        clear
        echo "╔══════════════════════════════════════════╗"
        echo "║   AMD RX 580 Performance Monitor        ║"
        echo "╚══════════════════════════════════════════╝"
        echo ""
        
        # GPU info
        if command -v radeontop &> /dev/null; then
            timeout 2 radeontop -d - -l 1 2>/dev/null
        else
            lspci | grep -i vga
        fi
        
        echo ""
        echo "Press Ctrl+C to stop, or wait 5s for AI analysis..."
        
        sleep 5
        
        # Every 5th iteration, get AI tips
        if [ $((RANDOM % 5)) -eq 0 ]; then
            echo ""
            jarvis-ask "Quick AMD RX 580 optimization tip for gaming on Linux?"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════
# ERROR LOG DIGESTOR
# ═══════════════════════════════════════════════════════════════════

# Daily error summary
daily-errors() {
    echo "📊 Analyzing today's errors..."
    
    journalctl -p err --since today --no-pager > /tmp/daily-errors.log
    
    if [ -s /tmp/daily-errors.log ]; then
        cat /tmp/daily-errors.log | \
        gemini "Summarize these errors from an Arch Linux system. Group by severity and provide one-line fixes:" | \
        tee /tmp/error-summary.txt
        
        notify-send "J.A.R.V.I.S. Daily Report" "Error analysis complete. Check terminal for details."
    else
        echo "✅ No errors today, sir. System running perfectly."
        sound-system notification
    fi
    
    rm -f /tmp/daily-errors.log
}

# ═══════════════════════════════════════════════════════════════════
# SOUND PACK SUGGESTER
# ═══════════════════════════════════════════════════════════════════

# Get suggestions for missing sounds
suggest-sounds() {
    sound-system list
    
    echo ""
    echo "🔊 Getting AI suggestions for sound improvements..."
    
    sound-system list 2>&1 | \
    gemini "Based on these available J.A.R.V.I.S. and iDroid sounds, suggest: 1) Which sounds are missing? 2) Creative new sound triggers to add 3) Alternative sound packs to try"
}

# ═══════════════════════════════════════════════════════════════════
# QUICK NIRI RULE GENERATOR
# ═══════════════════════════════════════════════════════════════════

# Generate window rules for new apps
make-rule() {
    local app_name="$1"
    
    if [ -z "$app_name" ]; then
        echo "Usage: make-rule <app-name>"
        return 1
    fi
    
    jarvis-ask "Generate a Niri window rule in KDL format for $app_name. Include: floating behavior, size, workspace assignment, and styling. Make it compatible with my Catppuccin theme."
}

# ═══════════════════════════════════════════════════════════════════
# EXPORTS
# ═══════════════════════════════════════════════════════════════════

export -f optimize-config smart-game smart-export dt-suggest
export -f jarvis-monitor watch-proton setup-workspace
export -f keybind-cheatsheet smart-backup gpu-watch daily-errors
export -f suggest-sounds make-rule

# ═══════════════════════════════════════════════════════════════════
# DEMO FUNCTION
# ═══════════════════════════════════════════════════════════════════

demo-jarvis() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║        WehttamSnaps J.A.R.V.I.S. WILD Examples Demo          ║
╚═══════════════════════════════════════════════════════════════╝

🔥 CRAZY USEFUL COMMANDS:

1. optimize-config                  - AI optimize your Niri config
2. smart-game "Cyberpunk 2077"      - Launch game with AI tips
3. smart-export ~/Photos            - AI-powered photo organization
4. jarvis-monitor                   - AI watches system health
5. watch-proton                     - Auto-analyze game crashes
6. setup-workspace gaming           - Auto-setup workspace
7. keybind-cheatsheet              - Generate beautiful docs
8. smart-backup                     - Backup with AI descriptions
9. gpu-watch                        - Monitor GPU with AI tips
10. daily-errors                    - Digest day's errors
11. suggest-sounds                  - Get sound pack ideas
12. make-rule firefox               - Generate window rules

💡 PIPE EXAMPLES:

cat error.log | jarvis-debug
journalctl -xe | jarvis-summarize
ps aux | head | jarvis-explain

🎮 GAMING COMBOS:

smart-game "The Division 2"
watch-proton  # in another terminal
game-fix      # after playing

📸 PHOTOGRAPHY WORKFLOW:

setup-workspace photography
dt-suggest photo.dng
smart-export ~/Photos/2024

⚙️  CONFIG OPTIMIZATION:

optimize-config ~/.config/niri/config.kdl
keybind-cheatsheet
smart-backup

Try them all! 🚀
EOF
}

# Show demo on load
if [ "$1" = "--demo" ]; then
    demo-jarvis
fi
