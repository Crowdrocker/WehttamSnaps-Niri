# Wayshell dependencies

- `mmsg` — mangoWM IPC (get monitors, tags, clients; dispatch commands)
- `jq` — JSON parsing of mmsg output
- `waybar` — bar instances (elevated processes, focused process, monocle)
- `wpctl` — audio volume control (from wireplumber)
- `brightnessctl` — backlight control
- `grim` — screenshot capture
- `slurp` — interactive area selection
- `wl-copy` — clipboard integration
- `satty` — screenshot editor
- `notify-send` — desktop notifications (libnotify)
- `zenity` — settings dialogs (ss-settings-menu)
- `pkill` / `pgrep` / `killall` — process management (procps-ng)
- `nvidia-smi` — GPU utilization (optional, focused-daemon)
- `CaskaydiaCove Nerd Font` (can be replaced in waybar configs)
- Standard POSIX tools: `awk`, `sed`, `grep`, `cut`, `tr`, `cat`, `sort`,
  `wc`, `paste`, `head`, `tail`, `diff`, `bc`, `nproc`, `getconf`, `readlink`,
  `ps`, `date`, `python3` (for geometry parsing in ss-capture)
