#!/bin/bash
# ===================================================================================
# WEHTTAMSNAPS - J.A.R.V.I.S. KEYBINDS CHEAT SHEET
# Comprehensive keybinds for Niri + DankMaterialShell + Gaming
# https://github.com/Crowdrocker
# ===================================================================================

# Check if rofi is running and kill it
if pidof rofi > /dev/null; then
    pkill rofi
fi

# Launch rofi with keybinds
GDK_BACKEND=wayland rofi \
    -center \
    -title="J.A.R.V.I.S. Keybinds - WehttamSnaps" \
    -no-buttons \
    -width 80 \
    -lines 25 \
    -dmenu \
    -i \
    -mesg "WehttamSnaps Arch Linux Niri Workstation" \
    -config ~/.config/rofi/themes/wehttamsnaps.rasi \
    -columns 3 << 'EOF'
ESC                       Close keybinds
                         SUPER KEY (Windows Key)

=== J.A.R.V.I.S. QUICKSHELL ===
Super + Space              Application Launcher
Super + V                  Clipboard Manager
Super + M                  Task Manager
Super + N                  Notification Center
Super + ,                  Settings
Super + P                  Notepad
Super + C                  Control Center
Super + Y                  Wallpaper Browser
Super + X                  Power Menu
Super + Alt + L            Lock Screen

=== APPLICATION LAUNCHERS ===
Super + Enter              Ghostty Terminal
Super + D                  Rofi App Launcher
Super + B                  Brave Browser
Super + F                  File Manager (Thunar)
Super + E                  Kate Editor
Super + H                  This Keybinds Help
Super + Shift + W          Welcome Screen

=== WINDOW MANAGEMENT ===
Super + Q                  Close Window
Super + Shift + Q          Kill Window
Super + Shift + F          Toggle Floating
Super + F11                Toggle Fullscreen
Super + ←/→                Focus Window Left/Right
Super + ↑/↓                Focus Window Up/Down
Super + Shift + ←/→        Move Window Left/Right
Super + Shift + ↑/↓        Move Window Up/Down
Super + Ctrl + ←/→         Resize Window Width
Super + Ctrl + ↑/↓         Resize Window Height

=== WORKSPACES ===
Super + 1-10               Switch to Workspace 1-10
Super + Shift + 1-10       Move Window to Workspace 1-10
Workspaces: Work|Media|Gaming|Streaming|Photo|Code|Browser|Comm|Files|System

=== SCREENSHOTS & RECORDING ===
Print                      Full Screenshot
Super + Print              Region Screenshot
Alt + Print                Active Window Screenshot
Super + Shift + R          Start Screen Recording

=== GAMING MODE ===
Super + Shift + G          Toggle Gaming Mode
Super + Alt + S            Launch Steam
Super + Alt + L            Launch Lutris
Super + Alt + G            Steam in Gamescope

=== AUDIO CONTROLS ===
XF86AudioRaiseVolume       Volume Up
XF86AudioLowerVolume       Volume Down
XF86AudioMute              Mute Audio
XF86AudioMicMute           Mute Microphone
XF86MonBrightnessUp        Brightness Up
XF86MonBrightnessDown      Brightness Down

=== MEDIA CONTROLS ===
XF86AudioPlay              Play/Pause
XF86AudioNext              Next Track
XF86AudioPrev              Previous Track

=== SYSTEM CONTROLS ===
Super + Ctrl + L           Lock Screen
Super + Ctrl + P           Power Menu
Super + Alt + E            Exit Niri
Super + Shift + R          Reload Niri Config

=== J.A.R.V.I.S. INTEGRATION ===
~/.config/wehttamsnaps/scripts/gaming-mode.sh toggle
~/.config/wehttamsnaps/scripts/audio-control-gui.py
~/.config/wehttamsnaps/scripts/jarvis-sound-manager.sh test

=== WEBAPP LAUNCHERS ===
Super + Shift + T          Twitch (Webapp)
Super + Shift + Y          YouTube (Webapp)
Super + Shift + D          Discord (Webapp)
Super + Shift + S          Spotify (Webapp)

=== TERMINAL ALIASES ===
update                     System update + clean
gaming                     Launch gaming mode
stream                     Launch streaming setup
audio                      Open audio routing GUI
EOF