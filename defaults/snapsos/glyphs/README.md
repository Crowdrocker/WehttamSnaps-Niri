# glyphs — pen-based input for mangoWC

Draw rune-shaped glyphs with a pen/stylus to type commands or execute shell
actions.  No keyboard needed — just draw and underline.

Also supports handwriting OCR for ad-hoc text input via Tesseract.

---

## Quick start

```bash
# Normal mode — draw and match glyphs
./glyphs-cli.py

# Record new glyphs (grid-snapped to anchor points)
./glyphs-cli.py --record

# Record new glyphs (freehand)
./glyphs-cli.py --record-freehand

# Browse glyph dictionary
./glyphs-cli.py --dictionary
```

## Modes

These keybindings are configured in your Wayland compositor (mangoWC) config,
not inside the app itself:

| Keybinding          | Mode         | Command                          |
|---------------------|--------------|----------------------------------|
| `SUPER+G`           | **Normal**   | `glyphs-cli.py`                  |
| `SUPER+SHIFT+G`     | **Record**   | `glyphs-cli.py --record`         |
| `SUPER+CTRL+G`      | **Dictionary**| `glyphs-cli.py --dictionary`    |

Press `Escape` to close any mode at any time.

---

## Normal mode

A fullscreen transparent overlay appears when activated.  Draw glyphs with your
pen — each completed stroke is matched against the dictionary.  Recognised
glyphs show their name in a green label; unrecognised strokes show a red `?`.

### Mode system

The overlay has three output modes, indicated in the top-left corner:

| Mode        | Indicator | Behaviour on session execution           |
|-------------|-----------|------------------------------------------|
| **TYPE**    | Green     | `wtype` types text into the focused window |
| **EXEC**    | Orange    | `exec_prefix + text` runs as a shell command |
| **TERM**    | Purple    | Opens `term_exec` terminal with the command  |

The default mode is **TYPE**.  To switch modes, draw the appropriate mode-switch
glyph as the very first stroke of a session:

| Glyph output string      | Switches to |
|--------------------------|-------------|
| `__mode_exec__`          | EXEC mode   |
| `__mode_term_exec__`     | TERM mode   |

### Session execution

Everything you draw forms a *session*.  The session is a concatenation (space-separated)
of every recognised glyph's output string, in the order they were drawn.

To fire the session, draw a **horizontal line** across the full screen width near
the bottom of the writing area.  A large **circle** gesture also triggers execution.
The session is then:

- **typed** into the focused window via `wtype` (TYPE mode),
- **executed** as a shell command (EXEC mode), or
- **launched** in a terminal emulator (TERM mode).

### Strike-out (delete a glyph)

Draw a short horizontal scratch **over** a recognised glyph's label to remove
it from the session.  The scratch must be wider than it is tall and overlap the
glyph's bounding box.

### Undo

Three ways to undo:

- **Ctrl+Z** — removes the last stroke, text stroke, or recognised entry
- **Backspace** — removes the last recognised entry
- **Undo button** — click the grey button in the top-right corner

### Carousel bar

A scrollable, animated preview bar at the bottom of the screen shows all known
glyphs.  Each glyph's stroke path is repeatedly drawn in blue with a progress
animation.  Enabled by default; can be toggled in `config.json`.

---

## Bracket / OCR mode

For text that doesn't have a glyph (e.g. arbitrary words), use handwriting OCR:

1. Draw the **open-bracket glyph** (`__lbracket__` / `[`) — the mode indicator
   changes to blue `[ … ]` and subsequent strokes are drawn in **blue ink**.
2. Write your text freehand.
3. Draw the **close-bracket glyph** (`__rbracket__` / `]`) — all blue strokes
   are rendered to a PNG image and sent to **Tesseract OCR** (`tesseract`).
4. The recognised text is added as a session entry labelled `ocr`.

Requires `tesseract-ocr` and `tesseract-data-eng` to be installed.

---

## Record mode

The screen is divided into a grid (N sections, default 4).  Draw the same
glyph shape in each cell — multiple templates make recognition more robust.

When all cells are filled, a dialog asks for:

- **Name** — shown in the dictionary and carousel
- **Output string** — what gets typed or executed when the glyph is recognised

The dialog notes three special output strings:

| Output string            | Effect                                |
|--------------------------|---------------------------------------|
| `__mode_exec__`          | Switches to EXEC mode when drawn first |
| `__mode_term_exec__`     | Switches to TERM mode when drawn first |
| `__complete_enter__`     | Sends Enter key after session output   |

### Grid-snapped recording

The recording grid shows 7 labelled anchor points (A–G) connected by axis-aligned
and diagonal edges, plus 17 intermediate points.  When you draw, the stroke is
**snapped** to the nearest grid nodes and routed through the graph via
breadth-first search.  This produces clean, repeatable glyph definitions.

Use this mode for precise, structured glyphs.

### Freehand recording

Use `--record-freehand` instead.  Same grid layout, but strokes are kept as-is
without snapping.  No anchor-point graph is shown.

Use this mode for organic shapes (e.g. handwritten letters, symbols).

---

## Dictionary mode

A scrollable window (default 8 columns) showing all known glyphs as cards.
Each card displays:

- Glyph **name** (bold)
- **Output string** (small)
- Animated **stroke preview** — the path is repeatedly traced by a blue line
  with a red "drawing head" dot at 60 fps.

---

## Special glyph output strings

In addition to `__mode_exec__`, `__mode_term_exec__`, and `__complete_enter__`,
the following output strings have built-in behaviour:

| String                 | Effect                                              |
|------------------------|-----------------------------------------------------|
| `__enter__`            | Types the Enter key (via `wtype -k Return`)         |
| `__lbracket__`         | Opens handwriting OCR bracket mode                  |
| `__rbracket__`         | Closes OCR bracket mode and runs Tesseract          |

Any other output string is treated as literal text to type or execute.

---

## Glyph data format

Glyphs are stored as individual JSON files in `~/.config/snapsos/glyphs/glyphs-data/`.

```json
{
  "name": "ls",
  "string": "ls",
  "templates": [
    {"pts": [[x, y], ...]},
    {"pts": [[x, y], ...]}
  ]
}
```

| Field       | Description                                                |
|-------------|------------------------------------------------------------|
| `name`      | Display name (shown in dictionary, carousel, labels)       |
| `string`    | Output text (typed, executed, or a special `__*__` value)  |
| `templates` | Array of 1+ normalised stroke variations for robust matching |

Each template's `pts` is an array of 32 `[x, y]` coordinates normalised to a
unit-space centred at the origin (see Recognition pipeline below).

---

## Recognition pipeline

```
Ink stroke → RDP simplification → 32-point uniform resample →
scale to unit square → centre at origin → flip Y →
12 rotations × 32 cyclic shifts → DTW-style pointwise distance →
minimum across all templates → threshold check (≤ 0.12) → glyph match or `?`.
```

Key details:

- **RDP simplification** — Ramer-Douglas-Peucker with `epsilon = 0.8%` of the
  larger screen dimension.
- **Resampling** — uniform arc-length parameterisation to 32 points.
- **Normalisation** — scale so the larger axis fits in [0,1], then centre the
  centroid at the origin.
- **Y-flip** — screen coordinates have Y increasing downward; templates are
  stored with Y increasing upward (mathematical convention).
- **Rotation invariance** — 12 equispaced rotations (every 30°) are tried.
- **Cyclic shift invariance** — for each rotation, the starting point is shifted
  through all 32 positions.
- **Threshold** — distance ≤ 0.12 is considered a match (lower = better).

---

## Configuration

File: `~/.config/snapsos/glyphs/config.json`

```json
{
  "recording": {
    "sections": 4
  },
  "appearance": {
    "ink_width": 3.0,
    "background_rgba": [0.0, 0.0, 0.0, 0.06],
    "dictionary_grid_cols": 8,
    "carousel": {
      "enabled": true,
      "height": 70
    },
    "exec_prefix": "",
    "term_exec": ["ghostty", "-e"]
  }
}
```

| Key                            | Default                | Description                                      |
|--------------------------------|------------------------|--------------------------------------------------|
| `recording.sections`           | `4`                    | Number of cells in the recording grid            |
| `appearance.ink_width`         | `3.0`                  | Stroke width in pixels                           |
| `appearance.background_rgba`   | `[0,0,0,0.06]`         | Overlay background colour (RGBA 0–1)            |
| `appearance.dictionary_grid_cols` | `8`                 | Columns in the dictionary window grid            |
| `appearance.carousel.enabled`  | `true`                 | Show/hide the animated glyph carousel bar        |
| `appearance.carousel.height`   | `70`                   | Carousel bar height in pixels                    |
| `appearance.exec_prefix`       | `""`                   | Prefix for EXEC mode (e.g. `mmsg dispatch spawn_shell,`) |
| `appearance.term_exec`         | `["ghostty", "-e"]`    | Terminal emulator command (TERM mode)            |

If the file does not exist, built-in defaults are used.  The first run will
**not** create the file automatically — create it manually if you need
non-default settings.

---

## Input filtering

Only pen/stylus and touchscreen input is accepted for drawing.  Mice and
trackpads are silently rejected (`is_pen_event` checks for `PEN`, `ERASER`, and
`TOUCHSCREEN` source devices).

---

## Project structure

```
glyphs/
├── glyphs-cli.py          ← Entry point (argparse → GlyphApp)
├── glyphs-old.py          ← Original monolithic script (kept for reference)
├── glyphs-data/           ← Glyph definition files (JSON)
├── config.json            ← config storage
├── gen_defaults.py        ← Built-in glyph generator (legacy)
├── gen_glyphs.sh          ← Legacy regeneration shell script
├── README.md
└── glyphs/                ← Python package (modular)
    ├── __init__.py        ← Re-exports all public symbols
    ├── app.py             ← GlyphApp orchestrator (dispatches to modes)
    ├── config.py          ← Config paths, load/save, defaults
    ├── storage.py         ← Glyph JSON file persistence
    ├── geometry.py        ← RDP, resampling, normalisation, matching
    ├── models.py          ← StrokeGlyph data class
    ├── grid.py            ← Grid anchor points, adjacency, BFS routing
    ├── input.py           ← Pen-event detection (rejects mice)
    ├── widgets.py         ← GlyphCard (animated card widget)
    ├── normal.py          ← Normal overlay (drawing, matching, OCR, carousel)
    ├── record_freehand.py ← Freehand recording overlay
    ├── record_grid.py     ← Grid-snapped recording overlay
    └── dictionary.py      ← Dictionary browser window
```

### Architecture flow

```
glyphs-cli.py  (entry point)
     │
     v
GlyphApp  (app.py)
  ├── load_config()          →  config.json
  ├── load_glyphs()          →  glyphs-data/*.json
  │
  ├── run_normal()           →  NormalOverlay (normal.py)
  │     ├── geometry.py      —  recognition pipeline
  │     ├── models.py        —  StrokeGlyph
  │     ├── input.py         —  pen event check
  │     └── config.json      —  appearance settings
  │
  ├── run_record()           →  RecordOverlay (record_grid.py)
  │     ├── geometry.py
  │     ├── grid.py          —  anchor points + BFS
  │     ├── input.py
  │     ├── storage.py       —  save_glyph()
  │     └── config.json
  │
  ├── run_record_freehand()  →  FreehandRecordOverlay (record_freehand.py)
  │     ├── geometry.py
  │     ├── input.py
  │     ├── storage.py
  │     └── config.json
  │
  └── run_dictionary()       →  DictionaryWindow (dictionary.py)
        └── widgets.py       —  GlyphCard (animated preview)
```

---

## Dependencies

- `python3-gobject` (PyGObject / GTK 3)
- `python3-cairo` (PyCairo)
- `wtype` — types text into the focused window (Wayland)
- `tesseract-ocr` + `tesseract-data-eng` — handwriting OCR (bracket mode)
- Runtime shell commands: `mmsg` (mango messaging), `ghostty` (terminal emulator)

---

## Built-in glyphs

The project ships with 60+ predefined glyphs covering shell commands, window
management, app launchers, and mode switches.

### Shell commands

`ls`, `cd`, `rm`, `cp`, `mv`, `cat`, `grep`, `git`, `sudo`, `clear`, `exit`,
`echo`, `source`, `man`, `mkdir`, `chmod`, `find`, `kill`, `ps`, `top`, `df`,
`du`, `which`, `history`, `alias`, `export`, `ssh`, `ping`, `killall`, `wait`,
`la` (`ls -la`), `rf` (`rm -rf`), `h` (suffix/alias)

### Window management (mangoWC)

| Output string                          | Action                     |
|----------------------------------------|----------------------------|
| `mmsg dispatch killclient`             | Close focused window       |
| `mmsg dispatch togglefloating`         | Toggle floating mode       |
| `mmsg dispatch togglefullscreen`       | Toggle fullscreen          |
| `mmsg dispatch reload_config`          | Reload compositor config   |
| `mmsg dispatch quit`                   | Quit compositor            |
| `mmsg dispatch toggleoverview`         | Overview / expose mode     |
| `mmsg dispatch togglegaps`             | Toggle window gaps         |
| `mmsg dispatch zoom`                   | Zoom                       |
| `mmsg dispatch toggle_scratchpad`      | Toggle scratchpad window   |
| `mmsg dispatch focuslast`              | Focus last window          |
| `mmsg dispatch centerwin`              | Centre focused window      |
| `mmsg dispatch viewtoleft`             | Move view left             |
| `mmsg dispatch viewtoright`            | Move view right            |

### Applications

`btop`, `firefox`, `ghostty`, `vesktop`, `code` (VS Code), `steam`, `obsidian`,
`nautilus`, `gimp`, `unipkg`

### Special / mode glyphs

| Name              | Output string            | Purpose                         |
|-------------------|--------------------------|---------------------------------|
| exec              | `__mode_exec__`          | Switch to EXEC mode             |
| start-string      | `__lbracket__`           | Open OCR bracket                |
| capture-string    | `__rbracket__`           | Close OCR bracket               |
| enter             | `__enter__`              | Send Enter key                  |
| pipe              | `\|`                     | Shell pipe operator             |
| and               | `&&`                     | Shell AND operator              |
| colorize          | `colorize`               | Terminal colouriser             |
| figlet            | `figlet`                 | ASCII art generator             |
| pacman            | `pacman`                 | Package manager                 |
| fetch             | `fetch`                  | System info                     |
| fetch-conf        | `fetch-conf`             | System info config              |
| upgrade all       | `upgrade all`            | System upgrade                  |
| ghostty exec      | `ghostty -e`             | Terminal with command           |
