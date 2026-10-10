#!/bin/bash

SELECTED="$1"


WP_DIR=~/.config/sdgos/wallpapers

WP_GROUPS=$(ls "$WP_DIR" -l --group-directories-first | grep -e '^d.*' | awk '{print $9}' )


if [[ $SELECTED == "" ]]; then

    SELECTED=$(echo "$WP_GROUPS" | fzf --layout=reverse)
fi
echo "user selected $SELECTED"

dms ipc call wallpaper set "$WP_DIR/$SELECTED/$(ls -1 "$WP_DIR/$SELECTED" | grep -v ".conf" | head -n 1)"
sleep 0.5
dms ipc call wallpaper next
dms ipc call wallpaper prev

## todo: add other settings

# fetch info from file
GenericColor=$(cat "$WP_DIR/$SELECTED/wallpaper.conf" | grep -e "Generic_Color:" | cut -d: -f2)
ThemeCategory=$(cat "$WP_DIR/$SELECTED/wallpaper.conf" | grep -e "Theme_Category:" | cut -d: -f2)
Matugen=$(cat "$WP_DIR/$SELECTED/wallpaper.conf" | grep -e "Matugen:" | cut -d: -f2)
Mode=$(cat "$WP_DIR/$SELECTED/wallpaper.conf" | grep -e "Mode:" | cut -d: -f2)
Preset=$(cat "$WP_DIR/$SELECTED/wallpaper.conf" | grep -e "Preset:" | cut -d: -f2)

echo "color: $GenericColor, category: $ThemeCategory, matugen: $Matugen, mode: $Mode, preset: $Preset"

# theme type (generic, auto, browse)
#generic is registry
dms ipc call settings set currentThemeCategory $ThemeCategory


# auto > matugen template
dms ipc call settings set matugenScheme scheme-$Matugen

# dark/light mode
dms ipc call theme $Mode
sleep 1
# generic > color 
dms ipc call settings set currentThemeName $GenericColor
# browse > preset
dms ipc call settings set customThemeFile "/home/$(whoami)/.config/DankMaterialShell/themes/$Preset/theme.json"
sleep 1
sleep 0.5
dms kill
mmsg dispatch spawn_shell,dms run
sleep 4
dms ipc call theme toggle
dms ipc call theme toggle
dms ipc call theme $Mode
sleep 2
mmsg dispatch reload_config
notify-send "theme $SELECTED applied" "you may have to manually reload ghostty (ctrl+r)"
#read -n 1