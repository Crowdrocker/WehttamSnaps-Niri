# glyphs — pen-based input for mangoWM

Draw rune-shaped glyphs with a pen/stylus to type commands or execute shell
actions. No keyboard needed — just draw and underline.

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

These keybindings are configured in your mangoWM binds.conf:

| Keybinding | Mode | Command |
|---|---|---|
| `SUPER+G` | **Normal** | `glyphs-cli.py` |
| `SUPER+SHIFT+G` | **Record** | `glyphs-cli.py --record` |
| `SUPER+CTRL+G` | **Dictionary** | `glyphs-cli.py --dictionary` |

Press `Escape` to close any mode at any time.

---

## Normal mode

A fullscreen transparent overlay appears when activated. Draw glyphs with your
pen — each completed stroke is matched against the dictionary. Recognised
glyphs show their name in a green label; unrecognised strokes show a red `?`.

### Mode system

The overlay has three output modes, indicated in the top-left corner:

| Mode | Indicator | Behaviour on session execution |
|---|---|---|
| **TYPE** | Green | `wtype` types text into the focused window |
| **EXEC** | Orange | `exec_prefix + text` runs as a shell command |
| **TERM** | Purple | Opens `term_exec` terminal with the command |

Default mode is **TYPE**. Switch modes by drawing the appropriate mode-switch
glyph as the first stroke:

| Glyph output string | Switches to |
|---|---|
| `__mode_exec__` | EXEC mode |
| `__mode_term_exec__` | TERM mode |

### Session execution

Draw a **horizontal line** across the full screen width near the bottom to
fire the session. A large **circle** gesture also triggers execution.

### Strike-out

Draw a short horizontal scratch **over** a recognised glyph's label to remove
it from the session.

### Undo

`Ctrl+Z`, `Backspace`, or click the undo button.

### Carousel bar

Animated preview bar at the bottom showing all known glyphs. Toggle in config.

---

## Bracket / OCR mode

1. Draw open-bracket glyph (`__lbracket__` / `[`)
2. Write text freehand (blue ink)
3. Draw close-bracket glyph (`__rbracket__` / `]`)
4. Tesseract OCR recognises the text

Requires `tesseract-ocr` and `tesseract-data-eng`.

---

## Record mode

The screen divides into a grid (default 4 sections). Draw the same glyph in
each cell. When all cells are filled, a dialog asks for:
- **Name** — shown in dictionary and carousel
- **Output string** — what gets typed/executed

### Grid-snapped recording

7 labelled anchor points (A–G) with axis-aligned and diagonal edges, plus 17
intermediate points. Strokes snap to nearest grid nodes via BFS routing.

### Freehand recording

Same grid, but strokes kept as-is without snapping.

---

## Dictionary mode

Scrollable window (default 8 columns) showing all known glyphs as cards with
name, output string, and animated stroke preview.

---

## Special glyph output strings

| String | Effect |
|---|---|
| `__mode_exec__` | Switch to EXEC mode |
| `__mode_term_exec__` | Switch to TERM mode |
| `__complete_enter__` | Send Enter key after session |
| `__enter__` | Type Enter key (`wtype -k Return`) |
| `__lbracket__` | Open OCR bracket mode |
| `__rbracket__` | Close OCR bracket mode |

---

## Recognition pipeline

```
Ink stroke → RDP simplification → 32-point uniform resample →
scale to unit square → centre at origin → flip Y →
12 rotations × 15° steps × 32 cyclic shifts →
DTW-style pointwise distance →
minimum across all templates → threshold check (≤ 0.12) → match or `?`.
```

Key details:
- **RDP simplification** — epsilon = 0.8% of larger screen dimension
- **Resampling** — 32 points, uniform arc-length
- **Rotations** — 12 equispaced rotations at 15° steps (0°, 15°, 30°, ..., 165°)
- **Cyclic shifts** — 32 starting positions per rotation
- **Threshold** — distance ≤ 0.12 is a match

---

## Configuration

File: `~/.config/snapsos/glyphs/config.json`

| Key | Default | Description |
|---|---|---|
| `recording.sections` | `4` | Recording grid cells |
| `appearance.ink_width` | `3.0` | Stroke width (px) |
| `appearance.background_rgba` | `[0,0,0,0.06]` | Overlay background |
| `appearance.dictionary_grid_cols` | `8` | Dictionary columns |
| `appearance.carousel.enabled` | `true` | Carousel visibility |
| `appearance.carousel.height` | `70` | Carousel height (px) |
| `appearance.exec_prefix` | `""` | EXEC mode prefix |
| `appearance.term_exec` | `["ghostty", "-e"]` | Terminal command |

---

## Input filtering

Only pen/stylus and touchscreen input accepted. Mice and trackpads rejected
(`is_pen_event` checks for PEN, ERASER, TOUCHSCREEN sources).

---

## Project structure

```
glyphs/
├── glyphs-cli.py          ← Entry point
├── glyphs-old.py          ← Legacy (kept for reference)
├── glyphs-data/           ← 71 glyph definition files (JSON)
├── config.json            ← Template config
├── gen_defaults.py        ← Built-in glyph generator
├── gen_glyphs.sh          ← Legacy regeneration script
└── glyphs/                ← Python package
    ├── __init__.py
    ├── app.py             ← GlyphApp orchestrator
    ├── config.py          ← Config paths and defaults
    ├── storage.py         ← JSON persistence
    ├── geometry.py        ← RDP, resampling, matching pipeline
    ├── models.py          ← StrokeGlyph data class
    ├── grid.py            ← Anchor points and BFS routing
    ├── input.py           ← Pen-event detection
    ├── widgets.py         ← Animated card widget
    ├── normal.py          ← Normal drawing overlay
    ├── record_freehand.py ← Freehand recording
    ├── record_grid.py     ← Grid-snapped recording
    └── dictionary.py      ← Dictionary browser
```

---

## Dependencies

- `python3-gobject` (PyGObject / GTK 3)
- `python3-cairo` (PyCairo)
- `wtype` — Wayland text input
- `tesseract-ocr` + `tesseract-data-eng` — handwriting OCR (optional, bracket mode)
- Runtime: `mmsg` (mangoWM IPC), `ghostty` (terminal emulator)

---

## Built-in glyphs (71)

Shell commands: `ls`, `cd`, `rm`, `cp`, `mv`, `cat`, `grep`, `git`, `sudo`,
`clear`, `exit`, `echo`, `source`, `man`, `mkdir`, `chmod`, `find`, `kill`,
`ps`, `top`, `df`, `du`, `which`, `history`, `alias`, `export`, `ssh`, `ping`,
`killall`, `wait`, `la` (`ls -la`), `rf` (`rm -rf`), `h`

Window management: killclient, togglefloating, togglefullscreen, reload-config,
quit, toggleoverview, togglegaps, zoom, toggle-scratchpad, focuslast, centerwin,
viewtoleft, viewtoright

Applications: btop, firefox, ghostty, vesktop, code, steam, obsidian, nautilus,
gimp, unipkg

Special: exec (mode switch), start-string (open bracket), capture-string (close
bracket), enter, pipe, and, colorize, figlet, pacman, fetch, fetch-conf,
upgrade all, ghostty exec
