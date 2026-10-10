#!/bin/bash
# WehttamSnaps Voice Engine - J.A.R.V.I.S. & iDroid Integration

JARVIS_DIR="/usr/share/wehttamsnaps/sounds/jarvis"
IDROID_DIR="/usr/share/wehttamsnaps/sounds/idroid"
PLAYER="mpv --no-video"

case $1 in
    # --- System Events ---
    "startup")
        HOUR=$(date +%H)
        if [ "$HOUR" -lt 12 ]; then
            $PLAYER "$JARVIS_DIR/morning.mp3"
        elif [ "$HOUR" -lt 18 ]; then
            $PLAYER "$JARVIS_DIR/afternoon.mp3"
        else
            $PLAYER "$JARVIS_DIR/jarvis-evening.mp3"
        fi
        $PLAYER "$JARVIS_DIR/jarvis-startup.mp3"
        ;;
    "shutdown")     $PLAYER "$JARVIS_DIR/jarvis-shutdown.mp3" ;;
    "reload")       $PLAYER "$JARVIS_DIR/reloading-config.mp3" ;;
    "lock")         $PLAYER "$JARVIS_DIR/locking-screen.mp3" ;;
    "status-report") $PLAYER "$JARVIS_DIR/status-report.mp3" ;;
    "stream-start") $PLAYER "$JARVIS_DIR/stream-start.mp3" ;;

    # --- Productivity Tools ---
    "terminal")     $PLAYER "$JARVIS_DIR/opening-terminal.mp3" ;;
    "files")        $PLAYER "$JARVIS_DIR/opening-files.mp3" ;;
    "screenshot")   $PLAYER "$JARVIS_DIR/jarvis-screen-capture.mp3" ;;
    "export")       $PLAYER "$JARVIS_DIR/photo-export.mp3" ;;

    # --- App Specific ---
    "browser")      $PLAYER "$JARVIS_DIR/accessing-web.mp3" ;;
    "spotify")      $PLAYER "$JARVIS_DIR/initializing-audio.mp3" ;;
    "obs")          $PLAYER "$JARVIS_DIR/broadcast-ready.mp3" ;;
    "discord")      $PLAYER "$JARVIS_DIR/comms-online.mp3" ;;
    "edit-config")  $PLAYER "$JARVIS_DIR/accessing-core-files.mp3" ;;

    # --- System Warnings ---
    "temp-warning") $PLAYER "$JARVIS_DIR/jarvis-thermal.mp3" ;;
    "battery-low")  $PLAYER "$JARVIS_DIR/jarvis-battery.mp3" ;;

    # --- Gaming Mode (iDroid) ---
    "gamemode-on")  $PLAYER "$IDROID_DIR/gamemode-on.mp3" ;;
    "gamemode-off") $PLAYER "$IDROID_DIR/gamemode-off.mp3" ;;
    "steam")        $PLAYER "$IDROID_DIR/steam-launch.mp3" ;;

    # --- Layouts ---
    "float")        $PLAYER "$JARVIS_DIR/window-float.mp3" ;;
    "fullscreen")   $PLAYER "$JARVIS_DIR/window-fullscreen.mp3" ;;

    # Catch-all
    *)              exit 1 ;;
esac
