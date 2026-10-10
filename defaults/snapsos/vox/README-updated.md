# vox — voice-to-commands

Wake-word activated, fully offline voice commands with a flat directed-graph
binding engine. No cloud APIs, no data leaving your machine.

- **Daemon mode** — always-listening background service with a transparent HUD overlay
- **Config mode** — GTK graph editor with a Cairo-rendered flowchart (DAG layout, pan/zoom)
- **Offline STT** — whisper-server (whisper.cpp), runs locally
- **Three action types** — `exec`, `shell_exec`, `type`

## Quick start

```sh
# Install system dependencies (detects package manager: pacman/apt/dnf)
./install.sh

# Open the configuration GUI to build your command graph
vox config

# Start the daemon (speak "system command" + your command)
vox daemon
```

## How it works

You speak a **wake word** (default: `"system command"`) followed by a command,
e.g. `"system command, open firefox"`. The daemon transcribes continuously via
whisper-server, detects the wake word, strips it, then walks the command graph
to find a matching action.

### Matching algorithm — skip-based

The graph matcher is *skip-based*: non-matching words are silently ignored
rather than causing the match to fail:

```
"system command, open the firefox now"       → matches "open" → "firefox"
"system command, hey please launch chromium" → matches "launch" → "chromium"
"system command, search for cute cats online" → captures "cute cats online"
```

### Command graph

Each node is an independent entity with a *name* (the spoken keyword), a *type*,
and *connections* to other nodes. Multiple nodes can share the same downstream
node. Nodes with exactly one connection to another branch node are
*auto-followed* — the intermediate label is silently traversed without consuming
a token.

```
system command
  ├─ open     ──→ browsers    (auto-follow)
  ├─ launch   ──→ browsers
  ├─ browsers
  │   ├─ firefox   → exec firefox
  │   ├─ chromium  → exec chromium
  │   └─ brave     → exec brave-browser
  ├─ clipboard
  │   ├─ copy      → exec wl-copy
  │   └─ paste     → exec wl-paste
  ├─ search for        → exec (text_capture) xdg-open '...?q={text}'
  ├─ type              → type (text_capture) {text}
  ├─ run in terminal   → shell_exec (text_capture) {text}
  └─ volume
       ├─ up    → pactl set-sink-volume @DEFAULT_SINK@ +5%
       ├─ down  → pactl set-sink-volume @DEFAULT_SINK@ -5%
       └─ mute  → pactl set-sink-mute @DEFAULT_SINK@ toggle
```

### Node types

| Type | Behaviour |
|---|---|
| `branch` | Routes speech to connected child nodes (no action on its own) |
| `exec` | Runs `command` via `subprocess.Popen(cmd, shell=True)` |
| `shell_exec` | Opens the configured terminal and runs `command` inside |
| `type` | Types `command` text via `ydotool type` (Wayland + X11) |

### Text capture

When `text_capture` is `true` on an action node, all remaining utterance tokens
after the matching keyword are captured and substituted into `{text}`.

### Shared sub-graphs (auto-follow)

A branch node with exactly **one** connection leading to another branch is
auto-followed — the intermediate label acts as an internal router and consumes
no tokens.

### Prefixes & suffixes

Prefix/suffix words are detected **anywhere** in the utterance — their
`prepend`/`append` string is applied to the matched command.

### Immediate triggers

Whole-utterance matches that fire before any graph walk.

## Configuration GUI

```
vox config
```

Opens a GTK window with:
- **Flowchart view** (left panel) — Cairo-rendered, left-to-right DAG with
  colour-coded node types, pan, zoom, curved edges
- **Node editor** (right panel) — edit name, type, command, text-capture,
  connections
- **Root connections editor** — list of entrypoint node names
- **Toolbar** — Save, Settings, New node, Validate, Help, Daemon toggle
- **Right-click context menu** — Add node, Delete node

### Settings dialog

Four-tab modal: Wake Word, Terminal, Filters (prefix/suffix rules),
Triggers (immediate triggers).

## Daemon overlay

```
vox daemon           # with transparent HUD overlay
vox daemon --headless  # no overlay
```

Borderless, always-on-top GTK overlay at the top of the screen showing
real-time transcriptions and matched actions.

## Configuration file

Location: `<install_dir>/config.json` (symlinked to `~/.config/snapsos/vox`)

| Key | Type | Default | Description |
|---|---|---|---|
| `wake_word` | string | `"system command"` | Wake phrase |
| `wake_word_aliases` | array | `[]` | Alternative wake phrases |
| `terminal` | string | `"ghostty"` | Terminal for `shell_exec` |
| `prefixes` | array | `[]` | Prefix rules |
| `suffixes` | array | `[]` | Suffix rules |
| `immediate_triggers` | array | `[]` | Whole-utterance commands |
| `tree.root` | array | `[]` | Root entrypoint node names |
| `tree.nodes` | object | `{}` | Flat map of GraphNode objects |

## Dependencies

| Component | Dependency | Arch (pacman) |
|---|---|---|
| Python bindings | PyGObject | `python-gobject` |
| Audio capture | GStreamer | `gst-plugins-base`, `gst-plugins-good` |
| Speech-to-text | whisper-server (whisper.cpp) | `whisper-cpp-vulkan` or `gst-plugin-whisper` |
| Keyboard typing | ydotool | `ydotool` |
| Audio server | pipewire | `pipewire` + `pipewire-pulse` |
| Wayland overlay | gtk-layer-shell | `gtk-layer-shell` |

A whisper model (`ggml-medium.en.bin`, ~1.5 GB) is auto-downloaded on first
`vox daemon` from Hugging Face (ggerganov/whisper.cpp).

## File structure

```
~/.config/snapsos/vox/
├── install.sh              # Setup script
├── config.json             # User command graph
├── pyproject.toml          # Python package config
├── models/                 # Whisper model files (auto-downloaded)
└── vox/
    ├── __init__.py         # Package version
    ├── __main__.py         # Entry point for `python -m vox`
    ├── cli.py              # Argument parser
    ├── daemon.py           # Main loop — wires capture → recognizer → matcher
    ├── audio_capture.py    # GStreamer mic capture
    ├── whisper_recognizer.py # Whisper-server STT + wake word detection
    ├── recognizer.py       # Legacy Vosk recognizer (dead code, kept for reference)
    ├── command_tree.py     # Skip-based graph matching engine
    ├── executor.py         # Action dispatcher
    ├── overlay.py          # GTK HUD overlay
    ├── flowchart_view.py   # Cairo DAG renderer
    ├── config_ui.py        # GTK config editor
    └── config_manager.py   # JSON load/save
```
