#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  keyhints.sh — WehttamSnaps Keybinds Cheat Sheet                ║
# ║  Super + H  |  Uses wehttamsnaps-keyhints.rasi (3 columns)      ║
# ╚══════════════════════════════════════════════════════════════════╝

# Kill existing rofi instance
if pidof rofi > /dev/null; then
    pkill rofi
    exit 0
fi

THEME="$HOME/.config/rofi/themes/wehttamsnaps-keyhints.rasi"

GDK_BACKEND=wayland rofi \
    -dmenu \
    -i \
    -p "J.A.R.V.I.S." \
    -mesg "WehttamSnaps · Arch Linux · SwayFX · Noctalia Shell" \
    -no-custom \
    -no-fixed-num-lines \
    -theme "$THEME" \
    -columns 3 \
    -lines 25 \
    -width 1200 << 'EOF'
ESC                                              Close this panel
                                                 Super = Windows Key

=== J.A.R.V.I.S. QUICKSHELL ===
Super + Space          App Launcher             Noctalia
Super + C              Control Center           Noctalia
Super + N              Notification Center      Noctalia
Super + ,              Settings                 Noctalia
Super + X              Power Menu               Session menu
Super + V              Clipboard                History
Super + H              Keybinds                 This screen!
Super + Shift + W      Welcome Screen           WehttamSnaps

=== APPLICATIONS ===
Super + Enter          Ghostty Terminal
Super + D              Rofi Launcher            drun
Super + B              Brave Browser
Super + F              Thunar                   File manager
Super + Shift + F      Dolphin                  Alt file manager
Super + E              Kate Editor
Super + O              OBS Studio               Streaming
Super + J              J.A.R.V.I.S. Menu        Rofi command center
Super + Shift + J      J.A.R.V.I.S. Terminal    CLI mode

=== WEBAPPS ===
Super + Ctrl + Y       YouTube                  Webapp
Super + Ctrl + T       Twitch                   Webapp
Super + Ctrl + D       Discord                  Webapp
Super + Ctrl + S       Spotify                  Webapp

=== PHOTOGRAPHY ===
Super + Shift + D      Darktable                RAW editing
Super + Shift + K      DigiKam                  Import / catalog
Super + Shift + G      GIMP                     Retouching
Super + Shift + I      Krita                    Digital painting
Super + Shift + E      Photo Export             JARVIS feedback

=== GAMING MODE ===
Super + G              Toggle Gaming Mode       iDroid voice
Super + Alt + S        Launch Steam             +sound
Super + Alt + G        Steam + Gamescope        Performance shell
Super + Alt + L        Lutris
Super + Alt + P        ProtonUp-Qt              GE-Proton manager

=== WINDOW MANAGEMENT ===
Super + Q              Close Window             +sound
Super + Shift + Q      Kill Window              Force kill
Super + Shift + F      Fullscreen Toggle
Super + Ctrl + V       Toggle Floating
Super + W              Tabbed Layout
Super + Alt + C        Center Window
Super + Ctrl + R       Resize Mode
Super + -              Shrink Width             -10%
Super + =              Grow Width               +10%

=== FOCUS ===
Super + Arrow Keys     Focus Direction
Super + Alt + H        Focus Left               Vim
Super + J              Focus Down               Vim
Super + K              Focus Up                 Vim
Super + ;              Focus Right              Vim

=== MOVE WINDOWS ===
Super + Shift + Arrows Move Window
Super + Ctrl + H       Move Left                Vim
Super + Ctrl + ;       Move Right               Vim
Super + Ctrl + K       Move Up                  Vim
Super + Ctrl + J       Move Down                Vim

=== WORKSPACES ===
Super + 1              Browser
Super + 2              Terminal / Dev
Super + 3              Gaming
Super + 4              Streaming / OBS
Super + 5              Photography
Super + 6              Media / Video
Super + 7              Communications
Super + 8              Music / Audio
Super + 9              Files
Super + 0              System / Misc
Super + Shift + 1-0    Move to Workspace

=== SCREENSHOTS ===
Print                  Full Screenshot          +JARVIS sound
Super + Print          Region Select
Alt + Print            Active Window
Super + Shift + E      Photo Export             JARVIS feedback

=== AUDIO ===
Vol Up/Down            Volume                   +JARVIS sound
Mute                   Toggle Mute              Adaptive voice
Mic Mute               Toggle Mic
Play / Next / Prev     Media Controls

=== SYSTEM ===
Super + Ctrl + L       Lock Screen
Super + Alt + L        Lock Screen              Alt binding
Super + Shift + C      Reload Config            +JARVIS sound
Super + Alt + E        Exit SwayFX
Super + Shift + P      Monitors Off

=== J.A.R.V.I.S. SOUNDS ===
Startup                Good morning / afternoon
Gaming Mode ON         iDroid: Combat systems online
Gaming Mode OFF        iDroid: Returning to normal
Window Close           Closing window sound
Screenshot             Capture sound
Photo Export           Export complete, sir
Volume Up/Down         Volume feedback
Mute/Unmute            Audio muted / restored
WS4 (Streaming)        Streaming systems online

=== RESOURCES ===
GitHub                 github.com/Crowdrocker
Twitch                 twitch.tv/WehttamSnaps
YouTube                @WehttamSnaps
Noctalia Docs          docs.noctalia.dev
EOF
