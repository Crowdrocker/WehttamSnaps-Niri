# Troubleshooting Guide

## Niri Issues

### Config not loading
```bash
niri msg action reload-config
# Check errors: niri -l info
```

### Keybindings not working
```bash
# List current binds
niri msg binds
```

## Audio Issues

### No sound
```bash
# Check WirePlumber
systemctl --user status wireplumber
# Restart if needed
systemctl --user restart wireplumber
```

### Sound system not playing
```bash
# Test sound
sound-system test
# Check mode
sound-system status
```

## Gaming Issues

### Games not launching
```bash
# Check Proton version
protontricks --list
# Set specific version in Steam
```

### Performance issues
```bash
# Enable gaming mode
sound-system gaming-toggle
# Check MangoHUD is working
mangohud --version
```

## MO2 Helper Issues

### NXM links not working
```bash
# Register handler
xdg-open nxm://test
# Check ~/.local/share/applications/mimeapps.list
```

## Welcome App Issues

### Not starting
```bash
# Run manually
~/.config/wehttamsnaps/scripts/wehttamsnaps-welcome.py
# Check if dismissed
cat ~/.config/wehttamsnaps/welcome.json
```
