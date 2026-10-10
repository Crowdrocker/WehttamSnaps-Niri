#!/usr/bin/env bash
# === CONFIG WATCHER & VALIDATOR ===
# WehttamSnaps Niri Setup
# GitHub: https://github.com/Crowdrocker
#
# Watches config files for changes and validates them in real-time
# Shows desktop notifications on errors

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
NIRI_CONFIG_DIR="$HOME/.config/niri"
NOCTALIA_CONFIG_DIR="$HOME/.config/quickshell/noctalia"
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
STATE_FILE="$HOME/.cache/wehttamsnaps/config-watcher-state"
LOG_FILE="$HOME/.cache/wehttamsnaps/config-watcher.log"

# Create cache directory
mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

# Function to send notification
notify() {
    local urgency="$1"
    local title="$2"
    local message="$3"
    local icon="${4:-dialog-information}"
    
    if command -v notify-send &> /dev/null; then
        notify-send -u "$urgency" -i "$icon" -a "Config Watcher" "$title" "$message"
    fi
    
    # Also play J.A.R.V.I.S. sound for errors
    if [[ "$urgency" == "critical" ]] && [[ -x "$HOME/.config/wehttamsnaps/scripts/jarvis-manager.sh" ]]; then
        "$HOME/.config/wehttamsnaps/scripts/jarvis-manager.sh" warning &> /dev/null &
    fi
}

# Function to log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG_FILE"
}

# Function to validate Niri config
validate_niri() {
    local config_file="$1"
    
    if ! command -v niri &> /dev/null; then
        return 0
    fi
    
    # Run validation
    local output
    if output=$(niri validate 2>&1); then
        notify "normal" "✓ Niri Config Valid" "Configuration validated successfully" "dialog-ok"
        log "✓ Niri config valid: $config_file"
        return 0
    else
        # Extract error message
        local error_msg=$(echo "$output" | head -n 5)
        notify "critical" "✗ Niri Config Error" "$error_msg" "dialog-error"
        log "✗ Niri config error in $config_file: $error_msg"
        
        # Show detailed error in terminal if available
        if [[ -t 1 ]]; then
            echo -e "${RED}✗ Niri Configuration Error:${NC}"
            echo "$output"
        fi
        
        return 1
    fi
}

# Function to validate Ghostty config
validate_ghostty() {
    local config_file="$1"
    
    # Basic syntax check for Ghostty config
    if [[ ! -f "$config_file" ]]; then
        return 0
    fi
    
    # Check for common syntax errors
    local errors=""
    
    # Check for invalid characters or malformed lines
    if grep -n "^[^#]*=[^=]*=[^=]*$" "$config_file" &> /dev/null; then
        errors+="Multiple '=' on same line detected\n"
    fi
    
    # Check for unclosed quotes
    if grep -n "^[^#]*[\"'][^\"']*$" "$config_file" | grep -v "^[^#]*[\"'][^\"']*[\"']" &> /dev/null; then
        errors+="Unclosed quotes detected\n"
    fi
    
    if [[ -n "$errors" ]]; then
        notify "critical" "✗ Ghostty Config Error" "$errors" "dialog-error"
        log "✗ Ghostty config error in $config_file: $errors"
        return 1
    else
        notify "normal" "✓ Ghostty Config Valid" "Configuration syntax looks good" "dialog-ok"
        log "✓ Ghostty config valid: $config_file"
        return 0
    fi
}

# Function to check file type and validate accordingly
validate_config() {
    local file="$1"
    
    # Determine file type
    if [[ "$file" == *.kdl ]] || [[ "$file" == *niri* ]]; then
        validate_niri "$file"
    elif [[ "$file" == *ghostty* ]]; then
        validate_ghostty "$file"
    else
        # Generic validation - just check if file is readable
        if [[ -r "$file" ]]; then
            notify "normal" "✓ Config Updated" "$(basename "$file") saved" "dialog-information"
            log "✓ Config updated: $file"
            return 0
        else
            notify "critical" "✗ Config Error" "Cannot read $(basename "$file")" "dialog-error"
            log "✗ Cannot read: $file"
            return 1
        fi
    fi
}

# Function to watch directory
watch_directory() {
    local watch_dir="$1"
    local name="$2"
    
    if [[ ! -d "$watch_dir" ]]; then
        echo -e "${YELLOW}Warning: Directory not found: $watch_dir${NC}"
        return
    fi
    
    echo -e "${BLUE}Watching: $name${NC}"
    log "Started watching: $watch_dir"
    
    # Use inotifywait to watch for file changes
    inotifywait -m -r -e modify,create,delete,move \
        --format '%w%f %e' \
        "$watch_dir" 2>/dev/null | while read -r file event; do
        
        # Skip temporary files and backups
        if [[ "$file" == *~ ]] || [[ "$file" == *.swp ]] || [[ "$file" == *.tmp ]]; then
            continue
        fi
        
        # Skip if it's a directory
        if [[ -d "$file" ]]; then
            continue
        fi
        
        # Log event
        log "Event: $event on $file"
        
        # Validate on modify or create
        if [[ "$event" == *"MODIFY"* ]] || [[ "$event" == *"CREATE"* ]]; then
            # Small delay to ensure file is written
            sleep 0.5
            validate_config "$file"
        fi
    done
}

# Function to show help
show_help() {
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════════${NC}
${BLUE}          WehttamSnaps Config Watcher${NC}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

${YELLOW}Usage:${NC} $0 [action]

${YELLOW}Actions:${NC}
  start             Start watching configs (default)
  stop              Stop watching
  status            Show watcher status
  test              Test notifications
  validate          Validate all configs now
  logs              Show recent logs
  help              Show this help message

${YELLOW}What It Watches:${NC}
  • Niri configs     (~/.config/niri/)
  • Ghostty config   (~/.config/ghostty/config)
  • Noctalia configs (~/.config/quickshell/noctalia/)

${YELLOW}What It Does:${NC}
  ✓ Monitors config files for changes
  ✓ Validates syntax when you save
  ✓ Shows desktop notifications on errors
  ✓ Plays J.A.R.V.I.S. warning sound
  ✓ Logs all events for debugging

${YELLOW}Autostart:${NC}
  Add to ~/.config/niri/conf.d/00-base.kdl:
  spawn-at-startup "bash" "-c" "~/.config/wehttamsnaps/scripts/config-watcher.sh start &"

${YELLOW}Keybind:${NC}
  Mod + Alt + V     Validate all configs now

${BLUE}═══════════════════════════════════════════════════════════════${NC}
EOF
}

# Function to start watcher as daemon
start_watcher() {
    # Check if already running
    if pgrep -f "config-watcher.sh start" > /dev/null 2>&1; then
        echo -e "${YELLOW}Config watcher is already running${NC}"
        notify "normal" "Config Watcher" "Already running" "dialog-information"
        return
    fi
    
    # Check for inotifywait
    if ! command -v inotifywait &> /dev/null; then
        echo -e "${RED}Error: inotifywait not found${NC}"
        echo -e "${YELLOW}Install with: paru -S inotify-tools${NC}"
        notify "critical" "Config Watcher Error" "inotifywait not installed\nRun: paru -S inotify-tools" "dialog-error"
        exit 1
    fi
    
    echo -e "${GREEN}Starting config watcher...${NC}"
    notify "normal" "Config Watcher Started" "Monitoring configs for changes" "dialog-information"
    log "Config watcher started"
    
    # Watch Niri configs
    if [[ -d "$NIRI_CONFIG_DIR" ]]; then
        watch_directory "$NIRI_CONFIG_DIR" "Niri Configs" &
    fi
    
    # Watch Ghostty config directory
    if [[ -d "$(dirname "$GHOSTTY_CONFIG")" ]]; then
        watch_directory "$(dirname "$GHOSTTY_CONFIG")" "Ghostty Config" &
    fi
    
    # Watch Noctalia configs
    if [[ -d "$NOCTALIA_CONFIG_DIR" ]]; then
        watch_directory "$NOCTALIA_CONFIG_DIR" "Noctalia Configs" &
    fi
    
    # Save PIDs
    echo $$ > "$STATE_FILE"
    
    # Keep script running
    wait
}

# Function to stop watcher
stop_watcher() {
    if [[ -f "$STATE_FILE" ]]; then
        local pid=$(cat "$STATE_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${BLUE}Stopping config watcher (PID: $pid)...${NC}"
            kill "$pid" 2>/dev/null || true
            # Also kill all child processes
            pkill -P "$pid" 2>/dev/null || true
            rm -f "$STATE_FILE"
            notify "normal" "Config Watcher Stopped" "No longer monitoring configs" "dialog-information"
            log "Config watcher stopped"
            echo -e "${GREEN}✓ Stopped${NC}"
        else
            echo -e "${YELLOW}Config watcher not running${NC}"
            rm -f "$STATE_FILE"
        fi
    else
        echo -e "${YELLOW}Config watcher not running${NC}"
    fi
}

# Function to check status
check_status() {
    if [[ -f "$STATE_FILE" ]]; then
        local pid=$(cat "$STATE_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Config watcher is running (PID: $pid)${NC}"
            return 0
        else
            echo -e "${RED}✗ Config watcher not running (stale PID file)${NC}"
            rm -f "$STATE_FILE"
            return 1
        fi
    else
        echo -e "${RED}✗ Config watcher not running${NC}"
        return 1
    fi
}

# Function to test notifications
test_notifications() {
    echo -e "${BLUE}Testing notifications...${NC}"
    
    notify "normal" "Test: Normal" "This is a normal notification" "dialog-information"
    sleep 1
    notify "critical" "Test: Error" "This is an error notification" "dialog-error"
    sleep 1
    notify "normal" "Test: Success" "This is a success notification" "dialog-ok"
    
    echo -e "${GREEN}✓ Test complete${NC}"
}

# Function to validate all configs
validate_all() {
    echo -e "${BLUE}Validating all configurations...${NC}\n"
    
    local errors=0
    
    # Validate Niri
    if [[ -d "$NIRI_CONFIG_DIR" ]]; then
        echo -e "${YELLOW}Checking Niri config...${NC}"
        if validate_niri "$NIRI_CONFIG_DIR/config.kdl"; then
            echo -e "${GREEN}✓ Niri config valid${NC}\n"
        else
            echo -e "${RED}✗ Niri config has errors${NC}\n"
            ((errors++))
        fi
    fi
    
    # Validate Ghostty
    if [[ -f "$GHOSTTY_CONFIG" ]]; then
        echo -e "${YELLOW}Checking Ghostty config...${NC}"
        if validate_ghostty "$GHOSTTY_CONFIG"; then
            echo -e "${GREEN}✓ Ghostty config valid${NC}\n"
        else
            echo -e "${RED}✗ Ghostty config has errors${NC}\n"
            ((errors++))
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}✓ All configurations valid!${NC}"
        notify "normal" "✓ All Configs Valid" "No errors found" "dialog-ok"
    else
        echo -e "${RED}✗ Found $errors error(s)${NC}"
        notify "critical" "✗ Config Errors" "Found $errors configuration error(s)" "dialog-error"
    fi
}

# Function to show logs
show_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${BLUE}Recent config watcher logs:${NC}\n"
        tail -n 50 "$LOG_FILE"
    else
        echo -e "${YELLOW}No logs found${NC}"
    fi
}

# Main logic
main() {
    local action="${1:-start}"
    
    case "$action" in
        start)
            start_watcher
            ;;
        stop)
            stop_watcher
            ;;
        status)
            check_status
            ;;
        test)
            test_notifications
            ;;
        validate)
            validate_all
            ;;
        logs)
            show_logs
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown action: $action${NC}"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
