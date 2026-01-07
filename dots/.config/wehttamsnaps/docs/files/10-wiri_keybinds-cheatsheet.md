# WehttamSnaps — Niri Keybinds Cheatsheet
Source: [10-wiri_keybinds.kdl](https://github.com/Crowdrocker/WehttamSnaps-Niri/blob/main/dots/.config/niri/snaps/10-wiri_keybinds.kdl)  
Generated: 2025-12-15

> This cheatsheet was produced from the binds block in the listed file. It includes active mappings and their commands/intent. Commented-out binds are omitted.

## Workspace switching
| Key | Action |
|-----|--------|
| `Mod+1` | focus-workspace 1 + sound-system workspace 1 |
| `Mod+2` | focus-workspace 2 + sound-system workspace 2 |
| `Mod+3` | focus-workspace 3 + sound-system workspace 3 |
| `Mod+4` | focus-workspace 4 + sound-system workspace 4 |
| `Mod+5` | focus-workspace 5 + sound-system workspace 5 |
| `Mod+6` | focus-workspace 6 + sound-system workspace 6 |
| `Mod+7` | focus-workspace 7 + sound-system workspace 7 |
| `Mod+8` | focus-workspace 8 + sound-system workspace 8 |
| `Mod+9` | focus-workspace 9 + sound-system workspace 9 |
| `Mod+0` | focus-workspace 10 + sound-system workspace 10 |
| `Mod+Shift+1` ... `Mod+Shift+0` | move-column-to-workspace 1..10 (shifted numbers move current column) |

## System / Overview / Locks
| Key | Action / Notes |
|-----|----------------|
| `Mod+Tab` (repeat=false) | toggle-overview |
| `Mod+Shift+E` | quit |
| `Mod+Escape` (allow-inhibiting=false) | toggle-keyboard-shortcuts-inhibit |
| `Alt+Tab` | ii altSwitcher next (window switcher) |
| `Alt+Shift+Tab` | ii altSwitcher previous |
| `Super+G` | ii overlay toggle |
| `Mod+Space` (repeat=false) | ii overview toggle |
| `Mod+V` | ii clipboard toggle |
| `Mod+Alt+L` (allow-when-locked=true) | ii lock activate |
| `Ctrl+Alt+T` | ii wallpaperSelector toggle |
| `Mod+Comma` | ii settings open |
| `Mod+Slash` | ii cheatsheet toggle |
| `Mod+Shift+W` | ii panelFamily cycle |

## Window management
| Key | Action |
|-----|--------|
| `Mod+Q` (repeat=false) | run close-window script (~/.config/quickshell/ii/scripts/close-window.sh) |
| `Mod+D` | maximize-column |
| `Mod+F` | fullscreen-window |
| `Mod+A` | toggle-window-floating |

### Focus navigation
| Key | Action |
|-----|--------|
| `Mod+Left` / `Mod+H` | focus-column-left |
| `Mod+Right` / `Mod+L` | focus-column-right |
| `Mod+Up` / `Mod+K` | focus-window-up |
| `Mod+Down` / `Mod+J` | focus-window-down |

### Move windows/columns
| Key | Action |
|-----|--------|
| `Mod+Shift+Left` / `Mod+Shift+H` | move-column-left |
| `Mod+Shift+Right` / `Mod+Shift+L` | move-column-right |
| `Mod+Shift+Up` / `Mod+Shift+K` | move-window-up |
| `Mod+Shift+Down` / `Mod+Shift+J` | move-window-down |

## Gaming & toggles
| Key | Action |
|-----|--------|
| `Mod+G` | sound-system gaming-toggle (hotkey-overlay-title="sound-system gaming-toggle") |
| `Mod+Shift+g` | run jarvis-manager.sh (toggle gaming mode) |
| `Mod+Alt+r` | run ~/bin/niri-validate.sh |

## Applications
| Key | Action |
|-----|--------|
| `Mod+T` or `Mod+Return` | spawn terminal (`ghostty`) |
| `Mod+B` | open Vivaldi (`vivaldi-stable`) |
| `Super+E` | open Thunar |
| `Mod+Alt+D` | open Rofi (`-show drun`) |
| `Mod+Shift+B` | open Brave (`brave`) |
| `Mod+Shift+T` | open Kate |
| `Mod+O` | open OBS (flatpak run com.obsproject.Studio) |
| `Mod+P` | open spotify-launcher |

## Webapps (custom launcher)
| Key | Action |
|-----|--------|
| `Mod+Ctrl+t` | launch Twitch webapp script |
| `Mod+Ctrl+y` | launch YouTube webapp script |
| `Mod+Ctrl+s` | launch Spotify webapp script |
| `Mod+Ctrl+d` | launch Discord webapp script |

## Gaming & launchers (cont.)
| Key | Action |
|-----|--------|
| `Mod+Shift+S` | sound-system steam-launch && steam |
| `Mod+Alt+P` | open protonup-qt |

## Screenshots
| Key | Action |
|-----|--------|
| `Mod+Print` | grim to ~/Pictures/Screenshots/<timestamp>.png && sound-system screenshot (hotkey-overlay-title="Take screenshot") |
| `Ctrl+Print` | screenshot-screen |
| `Alt+Print` | screenshot-window |

## Media controls
| Key | Action (allow-when-locked=true) |
|-----|---------------------------------|
| `XF86AudioPlay` | playerctl play-pause |
| `XF86AudioNext` | playerctl next |
| `XF86AudioPrev` | playerctl previous |
| `XF86AudioStop` | playerctl stop |

## Audio controls (adaptive / sound-system)
| Key | Action (allow-when-locked=true) |
|-----|---------------------------------|
| `XF86AudioMute` | sound-system mute |
| `XF86AudioRaiseVolume` | sound-system volume-up |
| `XF86AudioLowerVolume` | sound-system volume-down |
| `XF86AudioMicMute` | sound-system mic-mute |

---

Notes and next steps:
- If you'd like this to auto-update when you add/remove binds, I can:
  - provide a small parser that reads your KDL file and regenerates this Markdown, or
  - provide the runtime Lua script (for Neovim) I suggested earlier to dump active mappings if you want runtime introspection.
- Tell me which you prefer and I will add the generator script (shell/Python/Lua) and a small README command to regenerate the cheatsheet automatically.