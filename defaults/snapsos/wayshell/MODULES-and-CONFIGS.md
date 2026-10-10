# Wayshell Modules and Configs

Reference for all included modules (defined in `wayshell.modules`) and config
scripts (in `configs/`).

---

## Zone Modules

Trigger when the cursor enters/exits a monitor-local bounding box.

### `zone_left` — Brightness bar

| Field | Value |
|-------|-------|
| Bounding box | `0,300,40,780` (left edge, middle third of screen) |
| ON action | Launch Waybar brightness bar |
| OFF action | Kill Waybar brightness bar |
| Purpose | Hover to the left edge of any monitor to reveal brightness controls |

### `zone_right` — Volume bar

| Field | Value |
|-------|-------|
| Bounding box | `1880,300,1920,780` (right edge, middle third of screen) |
| ON action | Launch Waybar volume bar |
| OFF action | Kill Waybar volume bar |
| Purpose | Hover to the right edge of any monitor to reveal volume controls |

### `zone_topcenter` — Screenshot toolbar

| Field | Value |
|-------|-------|
| Bounding box | `760,0,1160,40` (top-center strip) |
| ON action | Launch Waybar screenshot toolbar |
| OFF action | Kill Waybar screenshot toolbar |
| Purpose | Hover to the top-center of any monitor to reveal screenshot buttons |

### `elevated_bar` — Elevated process indicator

| Field | Value |
|-------|-------|
| Bounding box | `0,1030,350,1080` (bottom-left corner) |
| ON action | Set elevated visible flag, launch bottom Waybar bar |
| OFF action | Clear elevated flag, kill bottom bar if no modules active |
| Purpose | Hover to bottom-left to see elevated (sudo) processes |

### `focused_bar` — Focused process monitor

| Field | Value |
|-------|-------|
| Bounding box | `1570,1030,1920,1080` (bottom-right corner) |
| ON action | Set focused visible flag, launch bottom Waybar bar |
| OFF action | Clear focused flag, kill bottom bar if no modules active |
| Purpose | Hover to bottom-right to see focused process CPU/RAM/GPU |

---

## Layout Modules

Trigger when a layout becomes active or inactive on any tag. Each entry is
scoped to a specific monitor via the `layout_code,monitor` argument format.

### Monocle bar (3 monitors)

| Module | Layout | Monitor | Purpose |
|--------|--------|---------|---------|
| `monocle` | M (monocle) | HDMI-A-1 | Show window switcher bar |
| `monocle-dp1` | M (monocle) | DP-1 | Show window switcher bar |
| `monocle-dp3` | M (monocle) | DP-3 | Show window switcher bar |

### Deck bar (3 monitors)

| Module | Layout | Monitor | Purpose |
|--------|--------|---------|---------|
| `deck-hdmi` | K (horizontal deck) | HDMI-A-1 | Show window switcher bar |
| `deck-dp1` | K (horizontal deck) | DP-1 | Show window switcher bar |
| `deck-dp3` | K (horizontal deck) | DP-3 | Show window switcher bar |

### Vertical deck bar (3 monitors)

| Module | Layout | Monitor | Purpose |
|--------|--------|---------|---------|
| `vdeck-hdmi` | VK (vertical deck) | HDMI-A-1 | Show window switcher bar |
| `vdeck-dp1` | VK (vertical deck) | DP-1 | Show window switcher bar |
| `vdeck-dp3` | VK (vertical deck) | DP-3 | Show window switcher bar |

All layout modules execute the Monocle window switcher (`monocle.sh`) on ON
and kill it on OFF.

---

## Focused Modules

Trigger when a specific application gains or loses focus.

Currently configured as examples and **commented out**:

```
#term_focused     → triggers on ghostty focus
#browser_focused  → triggers on firefox focus
```

Uncomment and customize in `wayshell.modules` to add focused app actions.

---

## Config Scripts

### Volume bar (`volume.sh`, `volume-bar.sh`, `volume-icon.sh`)

| Script | Purpose |
|--------|---------|
| `volume.sh` | JSON output with volume percentage, bar rendering, mute detection |
| `volume-bar.sh` | Renders vertical bar with filled/empty characters |
| `volume-icon.sh` | Outputs speaker icon (muted/unmuted) |

Waybar config: `volume.json` + `volume.css` with scroll-up/scroll-down bindings.

### Brightness bar (`brightness.sh`, `brightness-bar.sh`)

| Script | Purpose |
|--------|---------|
| `brightness.sh` | JSON output with brightness percentage from `brightnessctl` |
| `brightness-bar.sh` | Renders vertical brightness bar |

Waybar config: `brightness.json` + `brightness.css` with scroll bindings.

### Screenshot toolbar (`ss-*.sh`)

| Script | Purpose |
|--------|---------|
| `ss-capture.sh` | Screenshot capture (4 modes: output/area/screen/active) |
| `ss-mode.sh` | Displays current mode icon in toolbar |
| `ss-mode-cycle.sh` | Cycles save mode (clipboard → file → editor) |
| `ss-settings.sh` | Displays settings tooltip |
| `ss-settings-menu.sh` | Opens settings dialog (zenity) |

Capture modes:
- **output** — current monitor via `grim -o`
- **area** — interactive region via `slurp`
- **screen** — all monitors
- **active** — focused window geometry via `mmsg get focusing-client`

Save modes:
- **clipboard** — copied via `wl-copy`
- **disk** — saved to `~/Pictures/Screenshots/`
- **editor** — opened in configured editor (default: gimp)

Settings stored in `~/.config/screenshot.state`:
```
mode=clipboard
save_dir=$HOME/Pictures/Screenshots
editor=gimp
```

Waybar config: `screenshot.json` with modules: monitor, zone, all, window,
OBS, mode toggle, settings gear.

### Elevated process monitor (`elevated-*.sh`)

A multi-role script that detects processes with UID 0 (root) descendants
and displays them in the bottom bar.

| Role / Script | Purpose |
|---------------|---------|
| `elevated-daemon.sh --daemon` | Scans all clients, walks process trees, finds elevated descendants |
| `elevated-daemon.sh pin` | Shows pin/unpin icon |
| `elevated-daemon.sh cap` | Shows elevated process count badge |
| `elevated-daemon.sh <N>` | Shows client title at position N (1–5) |
| `elevated-show.sh` | Zone ON handler — sets visible flag, launches bottom bar |
| `elevated-hide.sh` | Zone OFF handler — checks pin state, clears flag, kills bar |
| `elevated-pin.sh` | Toggles pin state (keeps bar visible even after zone exit) |
| `elevated-focus.sh <N>` | Focuses client at position N |

State files in `$XDG_CACHE_HOME/wayshell/`:
- `bottom_elevated.state` — pipe-separated client list
- `bottom_elevated_visible` — 1/0 visibility flag
- `bottom_elevated_pinned` — 1/0 pin state

Signals: SIGRTMIN+1 refreshes elevated modules in the bottom bar.

### Focused process monitor (`focused-*.sh`)

A multi-role script that tracks the currently focused window and displays
its CPU, RAM usage, and an optional GPU utilization.

| Role / Script | Purpose |
|---------------|---------|
| `focused-daemon.sh --daemon` | Gets focused client, reads CPU/RAM for its PID tree |
| `focused-daemon.sh --fps-daemon` | Reads GPU utilization every 1s (via nvidia-smi) |
| `focused-daemon.sh pin` | Shows pin/unpin icon |
| `focused-daemon.sh cap` | Shows focused window title (first 20 chars) |
| `focused-daemon.sh cpu` | Shows CPU percentage |
| `focused-daemon.sh mem` | Shows RAM usage |
| `focused-daemon.sh fps` | Shows GPU utilization |
| `focused-show.sh` | Zone ON handler — sets visible flag, launches bottom bar |
| `focused-hide.sh` | Zone OFF handler — checks pin state, clears flag, kills bar |
| `focused-pin.sh` | Toggles pin state |

State files in `$XDG_CACHE_HOME/wayshell/`:
- `bottom_focused.state` — `cpu|<pct>\nmem|<kb>\ntitle|<text>`
- `bottom_focused_visible` — 1/0 visibility flag
- `bottom_focused_pinned` — 1/0 pin state

Signals: SIGRTMIN+2 refreshes focused modules, SIGRTMIN+3 refreshes FPS.

---

## Waybar CSS

The `colors.css` template uses matugen Jinja2 syntax to inject Material You
colors into all Waybar configs:

```
@define-color {{name}} {{value.default.hex}};
```

Output goes to `configs/colors.css`, which is `@import`ed by each bar's CSS.

## Bottom Bar Waybar Modules

The bottom bar (`bottom-bar.json`) shares a single Waybar instance between
elevated and focused modules. Each module type sets a visibility flag in
`$XDG_CACHE_HOME/wayshell/`. The hide scripts only kill the bar when no
flag is set, allowing both modules to coexist.

Modules defined in `bottom-bar-modules`:
- `custom/elevated-daemon` — runs every 5s, rescans for elevated processes
- `custom/elevated-pin` — pin/unpin button, signal 1
- `custom/elevated-1` through `custom/elevated-5` — up to 5 elevated clients
- `custom/cap` — elevated count badge, signal 1
- `custom/focused-daemon` — runs every 3s, rescans focused process
- `custom/focused-pin` — pin/unpin button, signal 2
- `custom/focused-cap` — window title display, signal 2
- `custom/focused-cpu` — CPU percentage, signal 2
- `custom/focused-mem` — RAM usage, signal 2
- `custom/focused-fps-daemon` — GPU poller, runs every 1s
- `custom/focused-fps` — GPU utilization, signal 3
