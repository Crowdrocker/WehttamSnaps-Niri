#! /bin/bash

export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/$(id -u den)
# Dynamically find HYPRLAND_INSTANCE_SIGNATURE
HYPRLAND_SOCKET=$(find "$XDG_RUNTIME_DIR/hypr" -name ".socket.sock" 2>/dev/null | head -n 1)
if [[ -z "$HYPRLAND_SOCKET" ]]; then
    echo "Error: Hyprland socket not found. Is Hyprland running?"
    exit 1
fi

# Extract HYPRLAND_INSTANCE_SIGNATURE from the socket path
HYPRLAND_INSTANCE_SIGNATURE=$(basename "$(dirname "$HYPRLAND_SOCKET")")
export HYPRLAND_INSTANCE_SIGNATURE
# Call the original script
~/ownCloud/ArchConfig/hyprscripts/daemons/sudoborders.sh
