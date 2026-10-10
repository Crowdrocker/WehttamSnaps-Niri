# Miscellaneous Scripts

Utility scripts for layout-aware actions, cross-workspace window swapping,
workspace marking, and color palette display.

---

## `layoutbutton.sh` — Layout-specific action dispatcher

Reads the current layout on the active monitor/tag and executes a
layout-appropriate action, while also outputting the layout name for
display on a bar widget.

**Output:** echoes two lines — the active monitor name and the layout name.

**Layout actions:**

| Layout | Code | Action |
|--------|------|--------|
| Dwindle | `DW` | Toggle maximize screen |
| Left Master | `T` | Zoom (swap focused ↔ master) |
| Right Master | `RT` | Zoom |
| Center Master | `CT` | Zoom |
| Top Master | `VT` | Zoom |
| Horizontal Scroller | `S` | Switch proportion preset |
| Vertical Scroller | `VS` | Switch proportion preset |
| Horizontal Deck | `K` | Zoom |
| Vertical Deck | `VK` | Zoom |
| Horizontal Grid | `G` | Toggle render border + toggle gaps |
| Vertical Grid | `VG` | Toggle render border + toggle gaps |
| Fair | `F` | Toggle render border + toggle gaps |
| Vertical Fair | `VF` | Toggle render border + toggle gaps |
| Monocle | `M` | No action (name only) |
| *(unknown)* | * | Notification: "Unhandled Layout Detected" |

**Dependencies:** `mmsg`, `jq`, `notify-send`

---

## `marker.sh` — Workspace marker

Marks the current workspace (monitor + tag) and all windows on it for
later use by `swapmarked.sh`.

- Saves the workspace as `monitor:tag` → `~/.config/marker.workspace`
- Saves all window IDs on that workspace → `~/.config/marker.state`
- Sends a desktop notification confirming the mark

Accepts an optional monitor name as argument; if omitted, uses the
currently active monitor.

**Dependencies:** `mmsg`, `jq`, `notify-send`

---

## `swapmarked.sh` — Cross-workspace window swap

Swaps all windows on the current workspace with all windows on a
previously marked workspace (set by `marker.sh`).

Reads the target workspace from `~/.config/marker.workspace` and the
target window list from `~/.config/marker.state`, then moves each
window across monitors and tags using `tagcrossmon`.

Handles mismatched window counts gracefully — extra windows are left
in place, and the view switches to the other workspace if one side
is empty.

**Dependencies:** `mmsg`, `jq`, `paste`, `awk`, `sed`, `cut`, `sleep`

---

## `colors.sh` — DMS color palette display

Reads the current DMS Material You color palette from
`~/.local/state/quickshell/user/generated/colors.json` and renders
each color name with its actual color swatch in the terminal.

Uses ANSI 24-bit true color escape sequences for accurate color
rendering. Press any key to exit.

**Dependencies:** `jq`
=======
| Script | Purpose |
|--------|---------|
| `layoutbutton.sh` | script for a hotkey that changes function depending on the current layout (SUPER+A) |
| `swapmarked.sh` | Swap marked windows across tags/monitors |
| `marker.sh` | Mark a window for cross-tag/monitor operations |
| `colors.sh` | Display current DMS color palette in terminal |
