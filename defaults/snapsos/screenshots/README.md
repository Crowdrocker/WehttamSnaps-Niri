# Screenshot Utilities

Screenshot scripts with multiple capture modes and editor integration.

## Scripts

| Script | Keybind | Purpose |
|--------|---------|---------|
| `fullscreen.sh` | SUPER+CTRL+PRINT | Fullscreen capture via grim |
| `region.sh` | SUPER+PRINT | Region capture via hyprshot |
| `mode-toggle.sh` | PRINT | Cycle save mode: clipboard / file / editor |

## Modes

- **Clipboard**: Screenshot copied to clipboard (wl-copy)
- **File**: Saved to `~/Pictures/Screenshots/`
- **Editor**: Opens in satty for annotation

## Dependencies

`grim`, `hyprshot`, `satty`, `wl-copy`, `notify-send`, `slurp`, `zenity`
