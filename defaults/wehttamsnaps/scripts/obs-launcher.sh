#!/bin/bash
# OBS Launcher with proper environment for Niri

# Set environment for Wayland
export QT_QPA_PLATFORM=wayland
export MOZ_ENABLE_WAYLAND=1

# Launch OBS
if command -v flatpak &>/dev/null && flatpak list | grep -q "com.obsproject.Studio"; then
    flatpak run com.obsproject.Studio "$@"
else
    obs "$@"
fi
