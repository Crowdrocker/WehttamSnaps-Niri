#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#   WehttamSnaps KeyHints — i3 Keybindings Cheat Sheet
#   Super + H to open  |  Escape or click X to close
#   github.com/Crowdrocker  |  twitch.tv/WehttamSnaps
# ═══════════════════════════════════════════════════════════════════════

# Kill any existing instance
pkill -9 yad 2>/dev/null || true
sleep 0.1

# ── Colours (WehttamSnaps cyberpunk palette) ─────────────────────────────
BG="#06060f"
BG2="#0a0a1c"
CYAN="#00ffd1"
ORANGE="#ff6b1a"
FG="#c8d0e8"
FG_DIM="#3a4060"
BORDER="#1a1a3a"

yad \
    --center \
    --title="WehttamSnaps // i3 Keybindings" \
    --no-buttons \
    --list \
    --column="Key" \
    --column="Action" \
    --column="Notes" \
    --width=1000 \
    --height=780 \
    --search-column=2 \
    --tooltip-column=3 \
    --grid-lines=hor \
    --text-align=center \
    --text="  WehttamSnaps  //  i3 Keybindings Reference  //  Super = Windows Key" \
    --text-info \
    --separator="|" \
    --print-column=0 \
    --no-selection \
    \
    "" "── APPLICATIONS ─────────────────────────────────────" "" \
    "Super + Enter"        "Terminal"               "Ghostty" \
    "Super + B"            "Browser"                "Brave" \
    "Super + F"            "File Manager"           "Thunar" \
    "Super + E"            "Text Editor"            "Kate" \
    "Super + D"            "App Launcher"           "Rofi — WehttamSnaps theme" \
    "Super + H"            "KeyHints"               "This cheat sheet" \
    "Super + Shift + W"    "Welcome Screen"         "WehttamSnaps welcome app" \
    \
    "" "── JARVIS ────────────────────────────────────────────" "" \
    "Super + Space"        "JARVIS Menu"            "Main JARVIS launcher" \
    "Super + /"            "JARVIS Command"         "Free command input" \
    \
    "" "── WINDOW MANAGEMENT ─────────────────────────────────" "" \
    "Super + Q"            "Close Window"           "With JARVIS sound" \
    "Super + Shift + Q"    "Close Window"           "Silent — no sound" \
    "Super + Shift + F"    "Float Toggle"           "Toggle floating/tiled" \
    "Super + F11"          "Fullscreen"             "Toggle fullscreen" \
    \
    "" "── FOCUS ─────────────────────────────────────────────" "" \
    "Super + Arrow Keys"   "Move Focus"             "Left / Right / Up / Down" \
    "Super + Alt + H/J/K/L" "Move Focus (vim)"     "Super+Alt+hjkl" \
    \
    "" "── MOVE WINDOWS ──────────────────────────────────────" "" \
    "Super + Shift + Arrows" "Move Window"          "Shift window in direction" \
    \
    "" "── RESIZE ────────────────────────────────────────────" "" \
    "Super + Ctrl + Left"  "Shrink Width"           "-10px" \
    "Super + Ctrl + Right" "Grow Width"             "+10px" \
    "Super + Ctrl + Up"    "Shrink Height"          "-10px" \
    "Super + Ctrl + Down"  "Grow Height"            "+10px" \
    \
    "" "── LAYOUT ────────────────────────────────────────────" "" \
    "Super + Ctrl + S"     "Layout Stacking"        "" \
    "Super + Ctrl + W"     "Layout Tabbed"          "" \
    "Super + Ctrl + T"     "Layout Toggle Split"    "" \
    \
    "" "── WORKSPACES ────────────────────────────────────────" "" \
    "Super + 1"            "Workspace 1: Browser"   "Brave" \
    "Super + 2"            "Workspace 2: Media"     "Video / music" \
    "Super + 3"            "Workspace 3: Gaming"    "Steam / Lutris" \
    "Super + 4"            "Workspace 4: Stream"    "OBS Studio" \
    "Super + 5"            "Workspace 5: Photo"     "Darktable / GIMP / DigiKam" \
    "Super + 6"            "Workspace 6: Code"      "Kate / terminals" \
    "Super + 7"            "Workspace 7: Work"      "Documents" \
    "Super + 8"            "Workspace 8: Comm"      "Discord / email" \
    "Super + 9"            "Workspace 9: Files"     "Thunar" \
    "Super + 0"            "Workspace 10: System"   "Settings / htop" \
    "Super + Shift + 1–0"  "Move Window"            "Send window to workspace" \
    \
    "" "── SCREENSHOTS ───────────────────────────────────────" "" \
    "Print"                "Full Screenshot"        "Saves to ~/Pictures/Screenshots/" \
    "Super + Print"        "Region Screenshot"      "Draw selection with slurp" \
    "Super + Alt + Print"  "Window Screenshot"      "Active window via slurp" \
    \
    "" "── GAMING ────────────────────────────────────────────" "" \
    "Super + Shift + G"    "Gaming Mode Toggle"     "Kills compositor, max CPU, iDroid sounds" \
    "Super + Alt + S"      "Steam"                  "Launch Steam" \
    "Super + Alt + G"      "Gamescope Steam"        "Steam via gamescope" \
    \
    "" "── WEBAPPS ───────────────────────────────────────────" "" \
    "Super + Shift + T"    "Twitch"                 "twitch.tv/WehttamSnaps" \
    "Super + Shift + Y"    "YouTube"                "youtube.com" \
    "Super + Shift + D"    "Discord"                "discord.com/app" \
    "Super + Shift + S"    "Spotify"                "open.spotify.com" \
    \
    "" "── AUDIO ─────────────────────────────────────────────" "" \
    "Mute Key"             "Mute / Unmute"          "XF86AudioMute" \
    "Vol Up Key"           "Volume Up"              "XF86AudioRaiseVolume" \
    "Vol Down Key"         "Volume Down"            "XF86AudioLowerVolume" \
    "Mic Key"              "Mic Mute Toggle"        "XF86AudioMicMute" \
    "Play Key"             "Play / Pause"           "playerctl" \
    "Next Key"             "Next Track"             "playerctl next" \
    "Prev Key"             "Previous Track"         "playerctl previous" \
    \
    "" "── SYSTEM ────────────────────────────────────────────" "" \
    "Super + Ctrl + L"     "Lock Screen"            "i3lock dark" \
    "Super + Shift + R"    "Reload i3"              "Reload config" \
    "Super + Ctrl + R"     "Restart i3"             "Full restart" \
    "Ctrl + Alt + Delete"  "Exit i3"                "Prompts confirmation" \
    \
    "" "── J.A.R.V.I.S. SOUNDS ───────────────────────────────" "" \
    "Startup"              "JARVIS Online"          "System boot greeting" \
    "Workspace Switch"     "Confirmation Tone"      "Context-aware sound" \
    "Gaming Mode On"       "iDroid Activated"       "Switches to iDroid voice" \
    "Gaming Mode Off"      "JARVIS Restored"        "Returns to Paul Bettany TTS" \
    "Window Close"         "Closure Sound"          "On Super+Q" \
    "Screenshot"           "Capture Sound"          "On Print key" \
    \
    "" "── PHOTOGRAPHY WORKFLOW ──────────────────────────────" "" \
    "Step 1"               "DigiKam"                "Import + organise RAW files" \
    "Step 2"               "Darktable"              "RAW development + colour grade" \
    "Step 3"               "GIMP"                   "Compositing + retouching" \
    "Step 4"               "Krita"                  "Digital painting" \
    "Step 5"               "Export"                 "Thumbnails / overlays / Instagram" \
    \
    "" "── RESOURCES ─────────────────────────────────────────" "" \
    "Docs"                 "~/.config/wehttamsnaps/docs/"  "Local guides" \
    "GitHub"               "github.com/Crowdrocker"        "Source code" \
    "Twitch"               "twitch.tv/WehttamSnaps"        "Live streams" \
    "YouTube"              "@WehttamSnaps"                 "Video content" \
    \
    "" "── WehttamSnaps // Photography • Gaming • Content ────" ""
