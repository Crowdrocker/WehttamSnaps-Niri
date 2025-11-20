#!/usr/bin/env bash
# === WEHTTAMSNAPS KEYBINDINGS CHEAT SHEET ===
# Author: Matthew (WehttamSnaps)
# GitHub: https://github.com/Crowdrocker
#
# Interactive keybindings reference for Niri + Noctalia setup
# Adapted from JaKooLit's KeyHints

set -euo pipefail

# GDK backend
BACKEND=wayland

# Check if yad or rofi is running and kill them
if pidof rofi > /dev/null 2>&1; then
  pkill rofi
fi

if pidof yad > /dev/null 2>&1; then
  pkill yad
fi

# Launch yad with keybindings
GDK_BACKEND=$BACKEND yad \
    --center \
    --title="WehttamSnaps Keybindings" \
    --no-buttons \
    --list \
    --column=Key: \
    --column=Description: \
    --column=Notes: \
    --timeout-indicator=bottom \
    --width=1000 \
    --height=700 \
"" "WehttamSnaps Niri Setup" "Photography • Gaming • Content Creation" \
"Mod" "= SUPER KEY" "(Windows key)" \
"" "" "" \
"━━━ NOCTALIA SHELL ━━━" "" "" \
"Mod + Space" "Application Launcher" "Noctalia launcher" \
"Mod + S" "Control Center" "Quick settings panel" \
"Mod + Comma" "Settings" "Noctalia settings" \
"Mod + V" "Clipboard History" "Access clipboard" \
"Mod + C" "Calculator" "Quick calculator" \
"Mod + N" "Notifications" "Show notification history" \
"Mod + Shift + N" "Do Not Disturb" "Toggle DND mode" \
"Mod + L" "Lock Screen" "Lock with swaylock" \
"Mod + Ctrl + B" "Toggle Bar" "Show/hide Noctalia bar" \
"Mod + Shift + I" "Idle Inhibitor" "Prevent screen sleep" \
"" "" "" \
"━━━ CORE APPLICATIONS ━━━" "" "" \
"Mod + Enter" "Terminal" "Ghostty with Fira Code" \
"Mod + Shift + Enter" "Backup Terminal" "Foot terminal" \
"Mod + E" "File Manager" "Thunar file browser" \
"Mod + B" "Browser" "Brave browser" \
"Mod + Shift + B" "Firefox" "Backup browser" \
"Mod + H" "Help" "This keybindings cheat sheet" \
"Mod + Shift + T" "Text Editor" "Kate editor" \
"" "" "" \
"━━━ PHOTOGRAPHY (Workspace 3) ━━━" "" "" \
"Mod + 3" "Photo Workspace" "Jump to photography workspace" \
"Mod + Shift + G" "GIMP" "Photo editing" \
"Mod + Shift + D" "Darktable" "RAW processing" \
"Mod + Shift + K" "Krita" "Digital art & painting" \
"Mod + Shift + I" "Inkscape" "Vector graphics" \
"Mod + Shift + M" "Blender" "3D modeling & composites" \
"Mod + Shift + P" "DigiKam" "Photo management" \
"" "" "" \
"━━━ WEBAPPS (Mod + W) ━━━" "" "" \
"Mod + W, Y" "YouTube" "YouTube webapp" \
"Mod + W, T" "Twitch" "Twitch webapp" \
"Mod + W, S" "Spotify" "Spotify webapp" \
"Mod + W, D" "Discord" "Discord webapp" \
"Mod + W, M" "Gmail" "Gmail webapp" \
"Mod + W, G" "GitHub" "GitHub webapp" \
"" "" "" \
"━━━ GAMING (Workspace 9) ━━━" "" "" \
"Mod + 9" "Gaming Workspace" "Jump to gaming workspace" \
"Mod + G" "Gaming Mode Toggle" "Disable animations, max performance" \
"Mod + Shift + S" "Steam" "Launch Steam client" \
"Mod + Alt + L" "Lutris" "Lutris game manager" \
"Mod + Alt + P" "ProtonUp-Qt" "Manage Proton versions" \
"Mod + Alt + V" "Vortex" "Mod manager (via Wine)" \
"Mod + Alt + G" "GameMode Status" "Check gamemode state" \
"" "" "" \
"━━━ WORKSPACES ━━━" "" "" \
"Mod + 1-0" "Switch Workspace" "1=Browser, 2=Terminal, 3=Photo..." \
"Mod + Shift + 1-0" "Move Window" "Move window to workspace" \
"Mod + Alt + 1-0" "Move & Follow" "Move window and switch" \
"Mod + Ctrl + Left/Right" "Cycle Workspaces" "Navigate sequentially" \
"" "" "" \
"Workspace 1" "Browser" "🌐 Brave, Firefox" \
"Workspace 2" "Terminal" "💻 Ghostty, Thunar, Kate" \
"Workspace 3" "Photo" "📷 GIMP, Darktable, Krita" \
"Workspace 4" "Design" "🎨 Inkscape, vector graphics" \
"Workspace 5" "3D" "🧊 Blender" \
"Workspace 6" "Chat" "💬 Discord, Telegram" \
"Workspace 7" "Media" "🎵 Spotify, VLC, webapps" \
"Workspace 8" "Stream" "📺 OBS Studio, qpwgraph" \
"Workspace 9" "Gaming" "🎮 Steam, games, launchers" \
"Workspace 10" "Modding" "🔧 Vortex, MO2, Wabbajack" \
"" "" "" \
"━━━ WINDOW MANAGEMENT ━━━" "" "" \
"Mod + Q" "Close Window" "Graceful close" \
"Mod + Shift + Q" "Kill Window" "Force close" \
"Mod + F" "Fullscreen" "Toggle fullscreen" \
"Mod + Shift + Space" "Float Window" "Toggle floating mode" \
"Mod + Shift + C" "Center Window" "Center floating window" \
"Mod + Shift + F" "Maximize Column" "Maximize column width" \
"Mod + M" "Monocle" "Single window focus" \
"" "" "" \
"━━━ FOCUS MOVEMENT ━━━" "" "" \
"Mod + Left/H" "Focus Left" "Move focus to left window" \
"Mod + Right/L" "Focus Right" "Move focus to right window" \
"Mod + Up/K" "Focus Up" "Move focus to window above" \
"Mod + Down/J" "Focus Down" "Move focus to window below" \
"Mod + Home" "Focus First" "Jump to first column" \
"Mod + End" "Focus Last" "Jump to last column" \
"" "" "" \
"━━━ WINDOW MOVEMENT ━━━" "" "" \
"Mod + Shift + Left/H" "Move Left" "Move window left" \
"Mod + Shift + Right/L" "Move Right" "Move window right" \
"Mod + Shift + Up/K" "Move Up" "Move window up in column" \
"Mod + Shift + Down/J" "Move Down" "Move window down in column" \
"Mod + Plus" "Increase Width" "Make column wider" \
"Mod + Minus" "Decrease Width" "Make column narrower" \
"Mod + R" "Preset Width" "Cycle preset widths" \
"" "" "" \
"━━━ SCREENSHOTS ━━━" "" "" \
"Print" "Full Screenshot" "Capture entire screen" \
"Shift + Print" "Area Selection" "Select area with slurp" \
"Mod + Print" "Screenshot Editor" "Capture and edit with swappy" \
"Alt + Print" "Window Screenshot" "Capture active window only" \
"" "" "" \
"━━━ SCREEN RECORDING ━━━" "" "" \
"Mod + Shift + R" "Toggle Recording" "Start/stop screen recording" \
"" "" "" \
"━━━ AUDIO CONTROLS ━━━" "" "" \
"XF86AudioRaiseVolume" "Volume Up" "Increase system volume" \
"XF86AudioLowerVolume" "Volume Down" "Decrease system volume" \
"XF86AudioMute" "Mute Output" "Toggle audio mute" \
"XF86AudioMicMute" "Mute Microphone" "Toggle mic mute" \
"Mod + A" "Audio Router" "Open qpwgraph (VoiceMeeter-like)" \
"Mod + Ctrl + A" "Volume Mixer" "Open pavucontrol" \
"" "" "" \
"━━━ MEDIA CONTROLS ━━━" "" "" \
"XF86AudioPlay" "Play/Pause" "Toggle media playback" \
"XF86AudioNext" "Next Track" "Skip to next track" \
"XF86AudioPrev" "Previous Track" "Previous track" \
"XF86AudioStop" "Stop" "Stop playback" \
"" "" "" \
"━━━ BRIGHTNESS ━━━" "" "" \
"XF86MonBrightnessUp" "Brightness Up" "Increase screen brightness" \
"XF86MonBrightnessDown" "Brightness Down" "Decrease brightness" \
"" "" "" \
"━━━ WALLPAPER & THEME ━━━" "" "" \
"Mod + Shift + W" "Wallpaper Selector" "Choose wallpaper" \
"Mod + Ctrl + Space" "Random Wallpaper" "Apply random wallpaper" \
"Mod + Alt + W" "Wallpaper Auto" "Toggle automation" \
"Mod + Shift + Ctrl + T" "Toggle Dark Mode" "Switch light/dark theme" \
"" "" "" \
"━━━ SYSTEM UTILITIES ━━━" "" "" \
"Mod + Escape" "Task Manager" "GNOME System Monitor" \
"Mod + Shift + Escape" "Resource Monitor" "Mission Center" \
"Mod + Ctrl + Escape" "btop" "Terminal system monitor" \
"Mod + O" "OBS Studio" "Recording/streaming" \
"Mod + D" "Discord" "WebCord Discord client" \
"Mod + P" "Spotify" "Music player" \
"Mod + I" "System Settings" "KDE System Settings" \
"" "" "" \
"━━━ DEVELOPMENT ━━━" "" "" \
"Mod + Alt + C" "VS Code" "Code editor" \
"Mod + Alt + H" "GitHub Desktop" "Git GUI client" \
"" "" "" \
"━━━ POWER & SESSION ━━━" "" "" \
"Mod + Shift + E" "Session Menu" "Logout, reboot, shutdown" \
"Mod + Shift + Ctrl + R" "Reload Config" "Reload Niri configuration" \
"Mod + Shift + Ctrl + E" "Exit Niri" "Close Niri session" \
"" "" "" \
"━━━ MISCELLANEOUS ━━━" "" "" \
"Mod + Shift + C" "Color Picker" "Pick color from screen" \
"Mod + Period" "Emoji Picker" "Select emoji via rofi" \
"Mod + Shift + /" "Web Search" "Google search via rofi" \
"" "" "" \
"━━━ J.A.R.V.I.S. EVENTS ━━━" "" "" \
"System Startup" "Greeting" "J.A.R.V.I.S. introduction" \
"Gaming Mode On" "Performance" "Gaming mode activated sound" \
"Workspace 8 Entry" "Streaming" "Streaming systems online" \
"High Temperature" "Warning" "Temperature alert" \
"" "" "" \
"━━━ AUDIO ROUTING TIPS ━━━" "" "" \
"qpwgraph Setup" "VoiceMeeter-like" "Separate audio per app" \
"Game Audio" "Virtual Sink 1" "Route to OBS + headphones" \
"Browser Audio" "Virtual Sink 2" "YouTube, web audio" \
"Discord Audio" "Virtual Sink 3" "Voice chat audio" \
"Spotify Audio" "Virtual Sink 4" "Music (optional OBS)" \
"See docs/" "AUDIO-ROUTING.md" "Full setup guide" \
"" "" "" \
"━━━ GAMING TIPS ━━━" "" "" \
"Gaming Mode" "Mod + G" "Disables animations, max performance" \
"Launch Options" "Pre-configured" "16 games optimized for RX 580" \
"Proton GE" "Latest" "Installed via ProtonUp-Qt" \
"Mesa Drivers" "RADV optimizations" "GPU performance tweaks" \
"GameMode" "Auto-enabled" "CPU governor to performance" \
"See docs/GAMING.md" "Per-game configs" "Fixes for Division 2, Cyberpunk" \
"" "" "" \
"━━━ PHOTOGRAPHY WORKFLOW ━━━" "" "" \
"1. Import" "DigiKam" "Photo management & organization" \
"2. RAW Process" "Darktable" "Non-destructive RAW editing" \
"3. Edit/Composite" "GIMP" "Advanced editing & composites" \
"4. Touch-ups" "Krita" "Digital painting & final touches" \
"5. Export" "WehttamSnaps" "Ready for Twitch/YouTube/IG" \
"" "" "" \
"━━━ LINKS & RESOURCES ━━━" "" "" \
"Documentation" "~/.config/wehttamsnaps/docs/" "Full guides" \
"GitHub" "github.com/Crowdrocker" "Source repository" \
"Twitch" "twitch.tv/WehttamSnaps" "Live streams" \
"YouTube" "youtube.com/@WehttamSnaps" "Video content" \
"" "" "" \
"━━━ HELP & SUPPORT ━━━" "" "" \
"README" "~/.config/wehttamsnaps/README.md" "Main documentation" \
"Troubleshooting" "docs/TROUBLESHOOTING.md" "Common issues" \
"Niri Validation" "niri validate" "Check config syntax" \
"View Logs" "journalctl --user -u niri" "Niri service logs" \
"" "" "" \
"Made with ❤️ by WehttamSnaps" "Photography • Gaming • Content" "github.com/Crowdrocker"
