# Monocle — Window Switcher

A per-monitor window switcher bar built on Waybar. Shows all windows on the
current monitor as selectable buttons in a dedicated Waybar instance.

## How it works

- `monocle.sh` — Launches the Waybar monocle bar instance
- `indexer.sh` — Continuously indexes windows from mangoWM IPC, writes state
- `focuswindow.sh` — Focuses a window by ID when clicked in the bar
- `fetchwindow.sh` — Returns window details for bar rendering

## Dependencies

`waybar`, `mmsg`, `jq`
