#!/bin/bash
# Wehttamsnaps-Niri Quick Settings Menu
# Adapted from JaKooLit's Hyprland Quick Settings

# Config paths
niri_config="$HOME/.config/niri"
wehttam_config="$HOME/.config/wehttamsnaps"
scripts_dir="$HOME/.config/wehttamsnaps/scripts"
niri_scripts="$HOME/.config/niri/scripts"

# Rofi theme (adjust path if needed)
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
msg='⚠️ Choose what to do ⚠️'

# Default terminal and editor (modify as needed)
term="${TERMINAL:-kitty}"
edit="${EDITOR:-nano}"

# Function to display the menu options
menu() {
    cat <<EOF
view/edit Main Config (config.kdl)
view/edit Keybinds (binds.kdl)
view/edit Window Rules (rules.kdl)
view/edit Startup Apps (startup.kdl)
view/edit Environment Variables (env.kdl)
view/edit Layout Settings (layout.kdl)
view/edit Animations (animations.kdl)
view/edit Decorations (decorations.kdl)
view/edit Hotkey Config (hotkeys.kdl)
view/edit Wehttamsnaps Settings
view/edit Webapp Launcher Script
view/edit JARVIS Settings
Configure Monitors (nwg-displays)
GTK Settings (nwg-look)
QT Apps Settings (qt6ct)
QT Apps Settings (qt5ct)
Choose Rofi Themes
Search for Keybinds
Toggle Game Mode
Restart Niri
Reload Niri Config
Open Niri Wiki
EOF
}

# Main function to handle menu selection
main() {
    choice=$(menu | rofi -i -dmenu -config "$rofi_theme" -mesg "$msg")
    
    # Map choices to corresponding files/actions
    case "$choice" in
        "view/edit Main Config (config.kdl)") file="$niri_config/config.kdl" ;;
        "view/edit Keybinds (binds.kdl)") file="$niri_config/binds.kdl" ;;
        "view/edit Window Rules (rules.kdl)") file="$niri_config/rules.kdl" ;;
        "view/edit Startup Apps (startup.kdl)") file="$niri_config/startup.kdl" ;;
        "view/edit Environment Variables (env.kdl)") file="$niri_config/env.kdl" ;;
        "view/edit Layout Settings (layout.kdl)") file="$niri_config/layout.kdl" ;;
        "view/edit Animations (animations.kdl)") file="$niri_config/animations.kdl" ;;
        "view/edit Decorations (decorations.kdl)") file="$niri_config/decorations.kdl" ;;
        "view/edit Hotkey Config (hotkeys.kdl)") file="$niri_config/hotkeys.kdl" ;;
        "view/edit Wehttamsnaps Settings") file="$wehttam_config/settings.conf" ;;
        "view/edit Webapp Launcher Script") file="$scripts_dir/webapp-launcher.sh" ;;
        "view/edit JARVIS Settings") file="$wehttam_config/jarvis/config" ;;
        
        "Configure Monitors (nwg-displays)") 
            if ! command -v nwg-displays &>/dev/null; then
                notify-send "E-R-R-O-R" "Install nwg-displays first"
                exit 1
            fi
            nwg-displays ;;
            
        "GTK Settings (nwg-look)") 
            if ! command -v nwg-look &>/dev/null; then
                notify-send "E-R-R-O-R" "Install nwg-look first"
                exit 1
            fi
            nwg-look ;;
            
        "QT Apps Settings (qt6ct)") 
            if ! command -v qt6ct &>/dev/null; then
                notify-send "E-R-R-O-R" "Install qt6ct first"
                exit 1
            fi
            qt6ct ;;
            
        "QT Apps Settings (qt5ct)") 
            if ! command -v qt5ct &>/dev/null; then
                notify-send "E-R-R-O-R" "Install qt5ct first"
                exit 1
            fi
            qt5ct ;;
            
        "Choose Rofi Themes") 
            if [ -f "$scripts_dir/RofiThemeSelector.sh" ]; then
                "$scripts_dir/RofiThemeSelector.sh"
            else
                notify-send "Script Not Found" "RofiThemeSelector.sh not found"
            fi ;;
            
        "Search for Keybinds") 
            if [ -f "$scripts_dir/keyhints.sh" ]; then
                "$scripts_dir/keyhints.sh"
            else
                notify-send "Script Not Found" "keyhints.sh not found"
            fi ;;
            
        "Toggle Game Mode") 
            if [ -f "$scripts_dir/GameMode.sh" ]; then
                "$scripts_dir/GameMode.sh"
            else
                notify-send "Script Not Found" "GameMode.sh not found"
            fi ;;
            
        "Restart Niri")
            niri msg action quit
            sleep 1
            niri & ;;
            
        "Reload Niri Config")
            niri msg action reload-config
            notify-send "Niri" "Configuration reloaded" ;;
            
        "Open Niri Wiki")
            xdg-open "https://github.com/YaLTeR/niri/wiki" ;;
            
        *) return ;;  # Do nothing for invalid choices
    esac

    # Open the selected file in the terminal with the text editor
    if [ -n "$file" ]; then
        if [ -f "$file" ]; then
            $term -e $edit "$file"
        else
            notify-send "File Not Found" "Creating new file: $file"
            mkdir -p "$(dirname "$file")"
            touch "$file"
            $term -e $edit "$file"
        fi
    fi
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
    pkill rofi
fi

main