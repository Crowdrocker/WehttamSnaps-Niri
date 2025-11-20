#!/usr/bin/env bash
# === WEHTTAMSNAPS NIRI SETUP INSTALLER ===
# Author: Matthew (WehttamSnaps)
# GitHub: https://github.com/Crowdrocker
#
# Professional installation script for Arch Linux Niri configuration
# Optimized for photography, content creation, and gaming

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config/wehttamsnaps-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/wehttamsnaps-install-$(date +%Y%m%d-%H%M%S).log"

# Directories
CONFIG_DIR="$HOME/.config"
WEHTTAM_CONFIG="$CONFIG_DIR/wehttamsnaps"
NIRI_CONFIG="$CONFIG_DIR/niri"
NOCTALIA_CONFIG="$CONFIG_DIR/quickshell/noctalia"
GHOSTTY_CONFIG="$CONFIG_DIR/ghostty"
LOCAL_SHARE="$HOME/.local/share/wehttamsnaps"

# State tracking
ERRORS=0
WARNINGS=0

# Function to print banner
print_banner() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╦ ╦┌─┐┬ ┬┌┬┐┌┬┐┌─┐┌┬┐╔═╗┌┐┌┌─┐┌─┐┌─┐
║║║├┤ ├─┤ │  │ ├─┤│││╚═╗│││├─┤├─┘└─┐
╚╩╝└─┘┴ ┴ ┴  ┴ ┴ ┴┴ ┴╚═╝┘└┘┴ ┴┴  └─┘
    Niri Setup for Arch Linux
    Photography • Gaming • Content Creation
EOF
    echo -e "${NC}"
    echo -e "${CYAN}Author:${NC} Matthew (WehttamSnaps)"
    echo -e "${CYAN}GitHub:${NC} https://github.com/Crowdrocker"
    echo -e ""
}

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
    ((ERRORS++))
}

log_step() {
    echo -e "\n${MAGENTA}▶${NC} ${CYAN}$1${NC}\n" | tee -a "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should NOT be run as root!"
        log_info "Run as your regular user. Sudo will be requested when needed."
        exit 1
    fi
}

# Function to check if on Arch Linux
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        log_error "This script is designed for Arch Linux"
        log_warning "You may encounter issues on other distributions"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check for required commands
check_dependencies() {
    log_step "Checking dependencies..."
    
    local required_commands=(
        "git:git"
        "paru:paru (AUR helper)"
        "systemctl:systemd"
    )
    
    local missing=()
    
    for cmd_desc in "${required_commands[@]}"; do
        IFS=':' read -r cmd desc <<< "$cmd_desc"
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$desc")
            log_warning "Missing: $desc"
        else
            log_success "Found: $desc"
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_info "Please install missing dependencies and run again"
        exit 1
    fi
}

# Function to create backup
create_backup() {
    log_step "Creating backup of existing configurations..."
    
    mkdir -p "$BACKUP_DIR"
    log_info "Backup directory: $BACKUP_DIR"
    
    local backup_targets=(
        "$NIRI_CONFIG"
        "$GHOSTTY_CONFIG"
        "$CONFIG_DIR/starship.toml"
        "$CONFIG_DIR/fastfetch"
    )
    
    for target in "${backup_targets[@]}"; do
        if [[ -e "$target" ]]; then
            local basename=$(basename "$target")
            cp -r "$target" "$BACKUP_DIR/$basename" 2>/dev/null || true
            log_success "Backed up: $basename"
        fi
    done
    
    log_success "Backup completed"
}

# Function to install core packages
install_core_packages() {
    log_step "Installing core packages..."
    
    log_info "This will install Niri, Noctalia, and essential components"
    read -p "Continue with package installation? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_warning "Skipping package installation"
        return
    fi
    
    log_info "Installing core packages (this may take a while)..."
    
    # Core packages list
    local core_packages=(
        # Compositor and shell
        "niri"
        "noctalia-shell"
        "quickshell"
        
        # Terminal
        "ghostty"
        "foot"
        
        # Audio
        "pipewire"
        "wireplumber"
        "pipewire-alsa"
        "pipewire-jack"
        "pipewire-pulse"
        "pavucontrol"
        "qpwgraph"
        
        # Essential tools
        "git"
        "starship"
        "fastfetch"
        "brightnessctl"
        "playerctl"
        "cliphist"
        
        # Gaming
        "gamemode"
        "gamescope"
        "proton-ge-custom-bin"
        "steam"
        "lutris"
        
        # Screenshots
        "grim"
        "slurp"
        "swappy"
        
        # File manager
        "thunar"
        
        # Browser
        "brave-bin"
        
        # Authentication
        "hyprpolkitagent"
        
        # Theming
        "matugen-git"
        "qt6ct"
        "kvantum"
        
        # Fonts
        "ttf-fira-code"
        "ttf-jetbrains-mono-nerd"
        "noto-fonts"
        "noto-fonts-emoji"
    )
    
    # Install packages
    if paru -S --needed --noconfirm "${core_packages[@]}" >> "$LOG_FILE" 2>&1; then
        log_success "Core packages installed"
    else
        log_error "Failed to install some packages. Check $LOG_FILE for details"
        ((ERRORS++))
    fi
}

# Function to install photography packages
install_photography_packages() {
    log_step "Installing photography packages..."
    
    read -p "Install photography tools (GIMP, Darktable, Krita, etc.)? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_warning "Skipping photography packages"
        return
    fi
    
    local photo_packages=(
        "gimp"
        "darktable"
        "krita"
        "inkscape"
        "blender"
        "digikam"
        "rawtherapee"
    )
    
    if paru -S --needed --noconfirm "${photo_packages[@]}" >> "$LOG_FILE" 2>&1; then
        log_success "Photography packages installed"
    else
        log_warning "Some photography packages failed to install"
    fi
}

# Function to install gaming packages
install_gaming_packages() {
    log_step "Installing gaming packages..."
    
    read -p "Install additional gaming tools? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_warning "Skipping additional gaming packages"
        return
    fi
    
    local gaming_packages=(
        "protonup-qt"
        "mangohud"
        "lib32-gamemode"
        "wine-staging"
        "winetricks"
        "steam-native-runtime"
    )
    
    if paru -S --needed --noconfirm "${gaming_packages[@]}" >> "$LOG_FILE" 2>&1; then
        log_success "Gaming packages installed"
    else
        log_warning "Some gaming packages failed to install"
    fi
}

# Function to create directory structure
create_directories() {
    log_step "Creating directory structure..."
    
    local directories=(
        "$WEHTTAM_CONFIG"
        "$WEHTTAM_CONFIG/scripts"
        "$WEHTTAM_CONFIG/sounds"
        "$WEHTTAM_CONFIG/webapps"
        "$WEHTTAM_CONFIG/wallpapers"
        "$WEHTTAM_CONFIG/themes"
        "$WEHTTAM_CONFIG/docs"
        "$WEHTTAM_CONFIG/assets"
        "$NIRI_CONFIG"
        "$NIRI_CONFIG/conf.d"
        "$LOCAL_SHARE"
        "$HOME/.cache/wehttamsnaps"
        "$HOME/Pictures/Screenshots"
    )
    
    for dir in "${directories[@]}"; do
        if mkdir -p "$dir"; then
            log_success "Created: $dir"
        else
            log_error "Failed to create: $dir"
        fi
    done
}

# Function to copy configuration files
copy_configs() {
    log_step "Installing configuration files..."
    
    # Niri configs
    if [[ -d "$SCRIPT_DIR/configs/niri" ]]; then
        cp -r "$SCRIPT_DIR/configs/niri/"* "$NIRI_CONFIG/" 2>/dev/null || true
        log_success "Installed Niri configuration"
    fi
    
    # Ghostty config
    if [[ -f "$SCRIPT_DIR/configs/ghostty/config" ]]; then
        mkdir -p "$GHOSTTY_CONFIG"
        cp "$SCRIPT_DIR/configs/ghostty/config" "$GHOSTTY_CONFIG/config"
        log_success "Installed Ghostty configuration"
    fi
    
    # Starship config
    if [[ -f "$SCRIPT_DIR/configs/starship/starship.toml" ]]; then
        cp "$SCRIPT_DIR/configs/starship/starship.toml" "$CONFIG_DIR/starship.toml"
        log_success "Installed Starship configuration"
    fi
    
    # Fastfetch config
    if [[ -d "$SCRIPT_DIR/configs/fastfetch" ]]; then
        cp -r "$SCRIPT_DIR/configs/fastfetch" "$CONFIG_DIR/"
        log_success "Installed Fastfetch configuration"
    fi
    
    # Scripts
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        cp -r "$SCRIPT_DIR/scripts/"* "$WEHTTAM_CONFIG/scripts/" 2>/dev/null || true
        chmod +x "$WEHTTAM_CONFIG/scripts/"*.sh 2>/dev/null || true
        log_success "Installed scripts"
    fi
    
    # Sounds
    if [[ -d "$SCRIPT_DIR/sounds" ]]; then
        cp -r "$SCRIPT_DIR/sounds/"* "$WEHTTAM_CONFIG/sounds/" 2>/dev/null || true
        log_success "Installed J.A.R.V.I.S. sounds"
    fi
    
    # Webapps
    if [[ -d "$SCRIPT_DIR/webapps" ]]; then
        cp -r "$SCRIPT_DIR/webapps/"* "$WEHTTAM_CONFIG/webapps/" 2>/dev/null || true
        log_success "Installed webapp templates"
    fi
    
    # Documentation
    if [[ -d "$SCRIPT_DIR/docs" ]]; then
        cp -r "$SCRIPT_DIR/docs/"* "$WEHTTAM_CONFIG/docs/" 2>/dev/null || true
        log_success "Installed documentation"
    fi
    
    # Assets
    if [[ -d "$SCRIPT_DIR/assets" ]]; then
        cp -r "$SCRIPT_DIR/assets/"* "$WEHTTAM_CONFIG/assets/" 2>/dev/null || true
        log_success "Installed assets"
    fi
    
    # Copy logo and version
    if [[ -f "$SCRIPT_DIR/logo.txt" ]]; then
        cp "$SCRIPT_DIR/logo.txt" "$WEHTTAM_CONFIG/logo.txt"
    fi
    
    if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
        cp "$SCRIPT_DIR/VERSION" "$LOCAL_SHARE/VERSION"
    else
        echo "1.0.0" > "$LOCAL_SHARE/VERSION"
    fi
}

# Function to setup audio routing
setup_audio() {
    log_step "Setting up audio routing..."
    
    # Enable PipeWire services
    systemctl --user enable --now pipewire.service >> "$LOG_FILE" 2>&1 || true
    systemctl --user enable --now pipewire-pulse.service >> "$LOG_FILE" 2>&1 || true
    systemctl --user enable --now wireplumber.service >> "$LOG_FILE" 2>&1 || true
    
    log_success "PipeWire services enabled"
    
    # Run audio setup script if available
    if [[ -x "$WEHTTAM_CONFIG/scripts/audio-setup.sh" ]]; then
        log_info "Running audio setup script..."
        "$WEHTTAM_CONFIG/scripts/audio-setup.sh" >> "$LOG_FILE" 2>&1 || true
        log_success "Audio routing configured"
    fi
}

# Function to setup Plymouth theme
setup_plymouth() {
    log_step "Setting up Plymouth boot theme..."
    
    read -p "Install WehttamSnaps Plymouth theme? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Skipping Plymouth theme"
        return
    fi
    
    if [[ -d "$SCRIPT_DIR/plymouth/wehttamsnaps-spinner" ]]; then
        sudo cp -r "$SCRIPT_DIR/plymouth/wehttamsnaps-spinner" /usr/share/plymouth/themes/ 2>/dev/null || true
        
        # Set Plymouth theme
        sudo plymouth-set-default-theme -R wehttamsnaps-spinner >> "$LOG_FILE" 2>&1 || true
        log_success "Plymouth theme installed"
    else
        log_warning "Plymouth theme not found in repository"
    fi
}

# Function to enable services
enable_services() {
    log_step "Enabling system services..."
    
    # Enable bluetooth
    if systemctl list-unit-files | grep -q bluetooth.service; then
        sudo systemctl enable bluetooth.service >> "$LOG_FILE" 2>&1 || true
        log_success "Bluetooth service enabled"
    fi
    
    # Enable NetworkManager
    if systemctl list-unit-files | grep -q NetworkManager.service; then
        sudo systemctl enable NetworkManager.service >> "$LOG_FILE" 2>&1 || true
        log_success "NetworkManager enabled"
    fi
}

# Function to configure shell
configure_shell() {
    log_step "Configuring shell..."
    
    # Add Starship to shell config
    local shell_configs=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
    )
    
    local starship_init='eval "$(starship init bash)"'
    if [[ "$SHELL" == *"zsh"* ]]; then
        starship_init='eval "$(starship init zsh)"'
    fi
    
    for config_file in "${shell_configs[@]}"; do
        if [[ -f "$config_file" ]]; then
            if ! grep -q "starship init" "$config_file"; then
                echo "" >> "$config_file"
                echo "# WehttamSnaps - Starship prompt" >> "$config_file"
                echo "$starship_init" >> "$config_file"
                log_success "Added Starship to $(basename "$config_file")"
            fi
        fi
    done
}

# Function to create desktop entries
create_desktop_entries() {
    log_step "Creating desktop entries..."
    
    local applications_dir="$HOME/.local/share/applications"
    mkdir -p "$applications_dir"
    
    # Welcome app desktop entry
    cat > "$applications_dir/wehttamsnaps-welcome.desktop" << EOF
[Desktop Entry]
Name=WehttamSnaps Welcome
Comment=Welcome screen for WehttamSnaps Niri setup
Exec=$WEHTTAM_CONFIG/scripts/welcome.py
Icon=user-info
Terminal=false
Type=Application
Categories=System;
EOF
    
    log_success "Created desktop entries"
}

# Function to run first-time setup
first_time_setup() {
    log_step "First-time setup..."
    
    # Create welcome flag
    cat > "$WEHTTAM_CONFIG/welcome.json" << EOF
{
  "dismissed": false,
  "first_run": true,
  "timestamp": $(date +%s)
}
EOF
    
    log_info "Welcome screen will appear on first login"
}

# Function to validate installation
validate_installation() {
    log_step "Validating installation..."
    
    local validation_checks=(
        "$NIRI_CONFIG/config.kdl:Niri config"
        "$WEHTTAM_CONFIG/scripts/toggle-gamemode.sh:Gaming scripts"
        "$WEHTTAM_CONFIG/scripts/jarvis-manager.sh:J.A.R.V.I.S. manager"
        "$LOCAL_SHARE/VERSION:Version file"
    )
    
    local validation_errors=0
    
    for check in "${validation_checks[@]}"; do
        IFS=':' read -r file desc <<< "$check"
        if [[ -e "$file" ]]; then
            log_success "$desc: OK"
        else
            log_error "$desc: Missing"
            ((validation_errors++))
        fi
    done
    
    if [[ $validation_errors -eq 0 ]]; then
        log_success "All validation checks passed"
    else
        log_warning "$validation_errors validation check(s) failed"
    fi
    
    # Validate Niri config
    if command -v niri &> /dev/null; then
        if niri validate >> "$LOG_FILE" 2>&1; then
            log_success "Niri configuration is valid"
        else
            log_error "Niri configuration has errors. Check $LOG_FILE"
        fi
    fi
}

# Function to print post-install instructions
print_post_install() {
    log_step "Installation Complete!"
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                        ║${NC}"
    echo -e "${GREEN}║         WehttamSnaps Niri Setup Installed!             ║${NC}"
    echo -e "${GREEN}║                                                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}📋 Next Steps:${NC}"
    echo ""
    echo -e "  ${YELLOW}1.${NC} ${BLUE}Log out and log back in${NC}"
    echo -e "     Or start Niri manually: ${CYAN}niri${NC}"
    echo ""
    echo -e "  ${YELLOW}2.${NC} ${BLUE}First-time shortcuts:${NC}"
    echo -e "     • ${CYAN}Mod + H${NC}         → Help & keybindings"
    echo -e "     • ${CYAN}Mod + Space${NC}     → Application launcher"
    echo -e "     • ${CYAN}Mod + Enter${NC}     → Terminal (Ghostty)"
    echo -e "     • ${CYAN}Mod + S${NC}         → Control center"
    echo ""
    echo -e "  ${YELLOW}3.${NC} ${BLUE}Configure audio routing:${NC}"
    echo -e "     ${CYAN}~/.config/wehttamsnaps/scripts/audio-setup.sh${NC}"
    echo ""
    echo -e "  ${YELLOW}4.${NC} ${BLUE}Add J.A.R.V.I.S. sounds:${NC}"
    echo -e "     Place MP3 files in ${CYAN}~/.config/wehttamsnaps/sounds/${NC}"
    echo -e "     Run: ${CYAN}~/.config/wehttamsnaps/scripts/jarvis-manager.sh placeholders${NC}"
    echo ""
    echo -e "  ${YELLOW}5.${NC} ${BLUE}Read documentation:${NC}"
    echo -e "     ${CYAN}~/.config/wehttamsnaps/README.md${NC}"
    echo -e "     ${CYAN}~/.config/wehttamsnaps/docs/${NC}"
    echo ""
    
    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}⚠️  $ERRORS error(s) occurred during installation${NC}"
        echo -e "   Check log file: ${CYAN}$LOG_FILE${NC}"
        echo ""
    fi
    
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  $WARNINGS warning(s) during installation${NC}"
        echo ""
    fi
    
    echo -e "${CYAN}🔗 Links:${NC}"
    echo -e "  • Twitch:  ${BLUE}https://twitch.tv/WehttamSnaps${NC}"
    echo -e "  • YouTube: ${BLUE}https://youtube.com/@WehttamSnaps${NC}"
    echo -e "  • GitHub:  ${BLUE}https://github.com/Crowdrocker${NC}"
    echo ""
    
    echo -e "${GREEN}Backup saved to: ${CYAN}$BACKUP_DIR${NC}"
    echo -e "${GREEN}Log file: ${CYAN}$LOG_FILE${NC}"
    echo ""
}

# Main installation flow
main() {
    print_banner
    
    log_info "WehttamSnaps Niri Setup Installer"
    log_info "Installation started at $(date)"
    echo ""
    
    # Pre-flight checks
    check_root
    check_arch
    check_dependencies
    
    # Confirm installation
    echo -e "${YELLOW}This will install the WehttamSnaps Niri configuration.${NC}"
    echo -e "${YELLOW}Existing configs will be backed up to: $BACKUP_DIR${NC}"
    echo ""
    read -p "Continue with installation? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    # Run installation steps
    create_backup
    install_core_packages
    install_photography_packages
    install_gaming_packages
    create_directories
    copy_configs
    setup_audio
    setup_plymouth
    enable_services
    configure_shell
    create_desktop_entries
    first_time_setup
    validate_installation
    
    # Show completion
    print_post_install
    
    log_info "Installation completed at $(date)"
}

# Run main function
main "$@"
