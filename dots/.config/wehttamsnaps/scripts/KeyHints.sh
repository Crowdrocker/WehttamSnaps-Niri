#!/usr/bin/env bash
# === WEHTTAMSNAPS KEYBINDINGS CHEAT SHEET ===
# Author: Matthew (WehttamSnaps)
# Updated for Niri + Noctalia Shell + JARVIS Integration

set -euo pipefail

# Kill existing instances
pkill -9 yad 2>/dev/null || true

# Launch yad with updated keybindings
GDK_BACKEND=wayland yad \
    --center \
    --title="WehttamSnaps Niri Keybindings" \
    --no-buttons \
    --list \
    --column=Key: \
    --column=Description: \
    --column=Notes: \
    --timeout-indicator=bottom \
    --width=1100 \
    --height=750 \
    --search-column=2 \
"" "WEHTTAMSNAPS NIRI CONFIGURATION - KEYBINDINGS REFERENCE" "" \
"Mod" "= SUPER KEY (Windows Key)" "" \
"" "" "" \
"=== NOCTALIA SHELL ===" "" "" \
"Mod + Space" "Application Launcher" "Noctalia launcher" \
"Mod + S" "Control Center" "Quick settings panel" \
"Mod + Comma" "Settings" "Noctalia settings" \
"Mod + V" "Clipboard History" "Access clipboard" \
"Mod + C" "Calculator" "Quick calculator" \
"Mod + L" "Lock Screen" "Lock with Noctalia" \
"" "" "" \
"=== CORE APPLICATIONS ===" "" "" \
"Mod + Enter" "Terminal" "Ghostty terminal" \
"Mod + B" "Browser" "Firefox" \
"Mod + Shift + B" "Alt Browser" "Brave browser" \
"Mod + E" "File Manager" "Thunar" \
"Mod + D" "Rofi Launcher" "Rofi drun menu" \
"Mod + H" "KeyHints" "This cheat sheet!" \
"Mod + Shift + T" "Text Editor" "Kate editor" \
"Mod + O" "OBS Studio" "Screen recording" \
"Mod + P" "Spotify" "Music player" \
"" "" "" \
"=== WEBAPPS (Mod + Ctrl) ===" "" "" \
"Mod + Ctrl + Y" "YouTube" "YouTube webapp" \
"Mod + Ctrl + T" "Twitch" "Twitch webapp" \
"Mod + Ctrl + S" "Spotify" "Spotify webapp" \
"Mod + Ctrl + D" "Discord" "Discord webapp" \
"" "" "" \
"=== GAMING & PERFORMANCE ===" "" "" \
"Mod + G" "Gaming Mode Toggle" "iDroid sounds, max performance" \
"Mod + Shift + S" "Steam" "Launch Steam with sound" \
"Mod + Alt + P" "ProtonUp-Qt" "Manage Proton versions" \
"" "" "" \
"=== WORKSPACES ===" "" "" \
"Mod + 1" "Workspace 1" "Browser" \
"Mod + 2" "Workspace 2" "Terminal/Dev" \
"Mod + 3" "Workspace 3" "Gaming" \
"Mod + 4" "Workspace 4" "Streaming/OBS" \
"Mod + 5" "Workspace 5" "Photography" \
"Mod + 6" "Workspace 6" "Media/Video" \
"Mod + 7" "Workspace 7" "Communication" \
"Mod + 8" "Workspace 8" "Music/Audio" \
"Mod + 9" "Workspace 9" "Files" \
"Mod + 0" "Workspace 10" "Misc" \
"Mod + Shift + 1-0" "Move Window" "Move to workspace" \
"" "" "" \
"=== WINDOW MANAGEMENT ===" "" "" \
"Mod + Q" "Close Window" "With sound effect" \
"Mod + F" "Maximize Column" "Fill workspace" \
"Mod + Shift + F" "Fullscreen" "True fullscreen" \
"Mod + Ctrl + V" "Toggle Floating" "Float/tile window" \
"Mod + Shift + V" "Switch Focus" "Float to Tile" \
"Mod + W" "Toggle Tabbed" "Tab window display" \
"Mod + R" "Preset Width" "Cycle window width" \
"Mod + Shift + R" "Preset Height" "Cycle window height" \
"Mod + Alt + C" "Center Column" "Center in workspace" \
"Mod + Minus" "Decrease Width" "-10%" \
"Mod + Equal" "Increase Width" "+10%" \
"Mod + Shift + Minus" "Decrease Height" "-10%" \
"Mod + Shift + Equal" "Increase Height" "+10%" \
"" "" "" \
"=== FOCUS MOVEMENT ===" "" "" \
"Mod + Left" "Focus Left" "Move focus left" \
"Mod + Right" "Focus Right" "Move focus right" \
"Mod + Up" "Focus Up" "Move focus up" \
"Mod + Down" "Focus Down" "Move focus down" \
"Mod + Alt + H" "Focus Left (Vim)" "Alternative" \
"Mod + J" "Focus Down (Vim)" "Alternative" \
"Mod + K" "Focus Up (Vim)" "Alternative" \
"Mod + Semicolon" "Focus Right (Vim)" "Alternative" \
"" "" "" \
"=== WINDOW MOVEMENT ===" "" "" \
"Mod + Ctrl + H" "Move Left" "Move window left" \
"Mod + Ctrl + Semicolon" "Move Right" "Move window right" \
"Mod + Ctrl + K" "Move Up" "Move window up" \
"Mod + Ctrl + J" "Move Down" "Move window down" \
"Mod + BracketLeft" "Consume Left" "Merge window left" \
"Mod + BracketRight" "Expel Right" "Split window right" \
"" "" "" \
"=== SCREENSHOTS ===" "" "" \
"Mod + Print" "Screenshot" "Full screen + sound" \
"Ctrl + Print" "Screen Capture" "Niri screenshot screen" \
"Alt + Print" "Window Capture" "Niri screenshot window" \
"Mod + Shift + E" "Photo Export" "Export with sound" \
"" "" "" \
"=== AUDIO CONTROLS ===" "" "" \
"XF86AudioMute" "Mute/Unmute" "With adaptive sound" \
"XF86AudioRaiseVolume" "Volume Up" "Sound feedback" \
"XF86AudioLowerVolume" "Volume Down" "Sound feedback" \
"XF86AudioMicMute" "Mic Mute" "Toggle microphone" \
"" "" "" \
"=== MEDIA CONTROLS ===" "" "" \
"XF86AudioPlay" "Play/Pause" "Media playback" \
"XF86AudioNext" "Next Track" "Skip forward" \
"XF86AudioPrev" "Previous Track" "Skip backward" \
"XF86AudioStop" "Stop" "Stop playback" \
"" "" "" \
"=== BRIGHTNESS ===" "" "" \
"XF86MonBrightnessUp" "Brightness +" "Increase brightness" \
"XF86MonBrightnessDown" "Brightness -" "Decrease brightness" \
"" "" "" \
"=== WALLPAPER & THEME ===" "" "" \
"Mod + Shift + W" "Wallpaper Toggle" "Noctalia wallpaper" \
"" "" "" \
"=== SYSTEM ===" "" "" \
"Mod + Shift + P" "Power Off Monitors" "Turn off displays" \
"Mod + Shift + /" "Hotkey Overlay" "Niri hotkey help" \
"Mod + Alt + L" "Lock Screen" "Swaylock" \
"Ctrl + Alt + Delete" "Quit Niri" "Exit compositor" \
"" "" "" \
"=== J.A.R.V.I.S. INTEGRATION ===" "" "" \
"System Startup" "Greeting" "J.A.R.V.I.S. online" \
"Workspace Switch" "Confirmation" "With sound effect" \
"Gaming Mode On" "iDroid Mode" "Performance sounds" \
"Gaming Mode Off" "J.A.R.V.I.S. Mode" "Normal operation" \
"Window Close" "Closure Sound" "Feedback on close" \
"Screenshot" "Capture Sound" "Photo taken effect" \
"Steam Launch" "Launch Sound" "iDroid activation" \
"" "" "" \
"=== PHOTOGRAPHY WORKFLOW ===" "" "" \
"Step 1" "Import - DigiKam" "Photo management" \
"Step 2" "Process - Darktable" "RAW editing" \
"Step 3" "Edit - GIMP" "Advanced editing" \
"Step 4" "Touch-up - Krita" "Digital painting" \
"Step 5" "Export - Ready!" "For social media" \
"" "" "" \
"=== GAMING OPTIMIZATIONS ===" "" "" \
"Gaming Mode" "Mod + G" "Disables animations" \
"Pre-configured" "16 Games" "Division 2, Cyberpunk, etc" \
"RX 580" "Mesa Optimized" "RADV tweaks applied" \
"GameMode" "Active" "CPU performance mode" \
"" "" "" \
"=== QUICK TIPS ===" "" "" \
"Tip 1" "Mod + H anytime" "Show this cheat sheet" \
"Tip 2" "Gaming mode" "Max FPS, no animations" \
"Tip 3" "Webapps" "Separate profiles/cookies" \
"Tip 4" "J.A.R.V.I.S." "Contextual sound system" \
"Tip 5" "iDroid" "Gaming/combat sounds" \
"" "" "" \
"=== RESOURCES ===" "" "" \
"Documentation" "~/.config/wehttamsnaps/docs/" "Full guides" \
"GitHub" "github.com/Crowdrocker" "Source code" \
"Twitch" "twitch.tv/WehttamSnaps" "Live streams" \
"YouTube" "@WehttamSnaps" "Video content" \
"" "" "" \
"" "Made with Love by WehttamSnaps" "Photography - Gaming - Content"
