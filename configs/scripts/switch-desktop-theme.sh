#!/bin/env bash
# switch system theme back and forth
# Tokynonight-Dark and Tokyonight-Light must be updated to your themes
# You must set a theme manually before trying to switch it
# colors and config files are soft-linked, so destinations must exist

darkTheme='Tokyonight-Dark'
darkIcons='Papirus-Dark'
lightTheme='Tokyonight-Light'
lightIcons='Papirus-Light'
font='Adwaita Sans 10'
monoFont='Adwaita Mono 10'
cursor='Adwaita'

setSchema='gsettings set org.gnome.desktop.interface'
getSchema='gsettings get org.gnome.desktop.interface'

barOpts="--bar bar-0"

switchDir=$HOME/.config/themes
footColors=colors-foot.ini
fuzzelColors=colors-fuzzel.ini
waybarColors=colors-waybar.css
wlogoutIcons=wlogout-icons
gtk3Config=$HOME/.config/gtk-3.0/settings.ini
dunstConfig=$HOME/.config/dunst/dunstrc

switch_themes() {
	if [[ $currentTheme = $lightTheme ]] 
	then
		newMode='dark'
		${setSchema} icon-theme "$darkIcons"
		${setSchema} gtk-theme "$darkTheme"
	else
		newMode='light'
		${setSchema} icon-theme "$lightIcons"
		${setSchema} gtk-theme "$lightTheme"
	fi

	${setSchema} cursor-theme "$cursor"
	${setSchema} font-name "$font"
	${setSchema} document-font-name "$font"
	${setSchema} monospace-font-name "$monoFont"
	${setSchema} color-scheme prefer-$newMode

	unlink $dunstConfig
	unlink $gtk3Config
	unlink $switchDir/$footColors
	unlink $switchDir/$fuzzelColors
	unlink $switchDir/$waybarColors
	unlink $switchDir/$wlogoutIcons
	
	ln -sf $switchDir/${newMode}/dunstrc $dunstConfig
	ln -sf $switchDir/${newMode}/settings.ini $gtk3Config
	ln -sf $switchDir/${newMode}/$footColors $switchDir/$footColors
	ln -sf $switchDir/${newMode}/$fuzzelColors $switchDir/$fuzzelColors
	ln -sf $switchDir/${newMode}/$waybarColors $switchDir/$waybarColors
	ln -sf $switchDir/${newMode}/$wlogoutIcons $switchDir/$wlogoutIcons

	systemctl --user restart dunst.service
	killall -9 waybar 2>/dev/null
	waybar $barOpts &
	notify-send "Updated to $newMode mode succesfully." 
}

# main
currentTheme=`${getSchema} gtk-theme | sed -e "s/'//g"`

if [[ $currentTheme = $lightTheme || $currentTheme = $darkTheme ]]
then 
	switch_themes
else 
	notify-send "GTK theme not recognized."
fi

exit 0
