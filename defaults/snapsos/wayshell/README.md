# Wayshell — Event Manager Daemon

Wayshell is a trailing-edge debounced event manager that bridges mangoWM IPC
events to external actions — launching Waybar popups, triggering scripts,
toggling widgets, and more.

---

## Architecture

```
wayshell.sh                 Main daemon (event loop)
├── wayshell.conf           Debounce timings and zone buffer
├── wayshell.modules        Module definitions (name|on|off|type|args)
├── modules/                Event source scripts
│   ├── zone.sh             Polls cursor position, emits enter/exit events
│   ├── layout.sh           Watches mmsg watch all-tags for layout changes
│   └── focused.sh          Watches mmsg watch focusing-client for focus changes
└── configs/                ON/OFF action scripts and Waybar configs
    ├── volume.sh           Audio volume bar
    ├── brightness.sh       Brightness bar
    ├── ss-capture.sh       Screenshot capture (monitor/area/screen/window)
    ├── elevated-daemon.sh  Elevated (sudo) process detection + monitoring
    ├── focused-daemon.sh   Focused process CPU/RAM/GPU monitoring
    └── ...
```

---

## Daemon Lifecycle

### 1. Config Loading (`wayshell.conf`)

The daemon sources per-type debounce overrides:

```
zone_buffer=30             # pixels from edge = "in zone"
on_delay=300               # default ON debounce (ms)
off_delay=500              # default OFF debounce (ms)
zone_on_delay=300          # zone ON override
zone_off_delay=1500        # zone OFF override (slow to avoid flicker)
layout_on_delay=200
layout_off_delay=0         # instant OFF for layout changes
focused_on_delay=50        # fast ON for focus
focused_off_delay=500
```

### 2. Module Parsing (`wayshell.modules`)

Each line is a module definition in pipe-delimited format:

```
name|on_exec|off_exec|type|args
```

- **name** — unique identifier
- **on_exec** — shell command when condition becomes true
- **off_exec** — shell command when condition becomes false
- **type** — `zone`, `layout`, or `focused`
- **args** — type-specific arguments

Types and their args:

| Type | Args | Example |
|------|------|---------|
| `zone` | `x1,y1,x2,y2` (monitor-local bounding box) | `0,300,40,780` |
| `layout` | `layout_code[,monitor]` | `M,HDMI-A-1` |
| `focused` | `app_id` | `firefox` |

### 3. Event Source Spawning

The daemon spawns each module in `modules/` as an auto-restarting subprocess.
Output lines are prefixed with the source name (`zone:`, `layout:`, `focused:`)
and routed to the appropriate `process_*_event` handler.

### 4. Event Processing

Each handler maps event data back to matching module definitions, then
transitions module state:

```
disabled  ──[enter]──→  pending_on  ──[delay]──→  enabled
enabled   ──[exit]───→  pending_off ──[delay]──→  disabled
```

Modules in `pending_off` can be returned to `enabled` if the condition
re-activates before the OFF delay expires (trailing-edge debounce).

### 5. Action Firing (`check_fires`)

Every ~50ms, the main loop calls `check_fires()` which:

1. Checks all `pending_on` modules — fires `on_exec` once their ON delay is met
2. Checks all `pending_off` modules — fires `off_exec` once their OFF delay is met
3. Cleans up expired timestamps

---

## Event Sources

### `modules/zone.sh` — Cursor zone detection

Polls `mmsg get cursorpos` every 100ms. Computes cursor position relative to
the active monitor's origin. Emits enter/exit events based on `zone_buffer`:

```
{"x":960,"y":5,"monitor":"DP-1"}              ← enter
{"state":"exit","x":960,"y":400,"monitor":"DP-1"}  ← exit
```

Uses a 5-second TTL monitor geometry cache to avoid excessive IPC calls.
Coordinates are monitor-local (0,0 = monitor top-left), making zone
definitions portable across display layouts.

### `modules/layout.sh` — Layout change detection

Subscribes to `mmsg watch all-tags`. Detects when the active layout on any
tag changes by tracking the previous layout per monitor:

```
{"layout":"M","state":"active","monitor":"DP-1","tag":2}
{"layout":"DW","state":"inactive","monitor":"DP-1","tag":2}
```

Emits an `inactive` event for the old layout before the `active` event for
the new one, ensuring clean ON→OFF→ON transitions.

### `modules/focused.sh` — Focus change detection

Subscribes to `mmsg watch focusing-client`. Tracks the previously focused
app_id to emit unfocused events:

```
{"app_id":"firefox","state":"focused"}
{"app_id":"firefox","state":"unfocused"}
{"app_id":"com.mitchellh.ghostty","state":"focused"}
```

---

## Waybar Integration

Wayshell's configs directory contains Waybar JSON/CSS configurations for
popup bars. These are launched via `mmsg dispatch spawn_shell` and managed
by zone/layout module ON/OFF actions.

Key bars:

| Bar | Config | Trigger | Purpose |
|-----|--------|---------|---------|
| Volume | `volume.json` | Zone right (cursor at right edge) | Audio volume slider |
| Brightness | `brightness.json` | Zone left (cursor at left edge) | Backlight slider |
| Screenshot | `screenshot.json` | Zone top-center | Capture toolbar |
| Bottom bar | `bottom-bar.json` | Zone bottom-left/right | Elevated process + focused process info |

---

## Matugen Integration

Wayshell bars support dynamic theming via matugen. The `MATUGEN.toml` file
templates `colors.css` (a Jinja2 template with matugen color variables) to
`configs/colors.css`, which is sourced by all Waybar CSS files.

---

## Dependencies

`mmsg`, `jq`, `wpctl`, `brightnessctl`, `grim`, `slurp`, `wl-copy`,
`satty`, `notify-send`, `zenity`, `waybar`, `procps-ng`, `nvidia-smi` (optional)
