#!/bin/bash
# WehttamSnaps J.A.R.V.I.S. Graceful Shutdown

# Play the shutdown sound and wait for it to finish
mpv --no-video "/usr/share/wehttamsnaps/sounds/jarvis/jarvis-shutdown.mp3"

# Now actually shutdown or exit
# Use 'swaymsg exit' for just logging out, or 'systemctl poweroff' for total shutdown
systemctl poweroff
