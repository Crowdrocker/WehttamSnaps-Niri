#!/usr/bin/env bash
# Keyhints.sh
# Show Niri keybind hints interactively using the generated cheatsheet.
#
# Behavior:
# - Regenerates the markdown cheatsheet if it doesn't exist or is older than the KDL source.
# - Extracts the "Full actions" list from the cheatsheet and shows it in an interactive menu.
# - Tries rofi, wofi, dmenu, zenity (in that order) and falls back to less.
# - If you pick an entry, it is copied to clipboard (wl-copy/xclip) and shown in a notification (notify-send).
#
# Configure paths below as needed.

set -euo pipefail

# CONFIG: adjust these paths if your repo layout differs
KDL_PATH="${KDL_PATH:-$HOME/path/to/WehttamSnaps-Niri/dots/.config/niri/snaps/10-wiri_keybinds.kdl}"
PARSER="${PARSER:-$(pwd)/generate_niri_cheatsheet.py}"   # path to the Python generator script
MD_OUT="${MD_OUT:-$HOME/.cache/niri_keybinds_cheatsheet.md}"

# If parser not found in current dir, assume it is next to this script
if [ ! -f "$PARSER" ]; then
  THISDIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -f "$THISDIR/generate_niri_cheatsheet.py" ]; then
    PARSER="$THISDIR/generate_niri_cheatsheet.py"
  fi
fi

# Regenerate cheatsheet if missing or older than KDL (best-effort)
regenerate() {
  if [ -x "$(command -v python3)" ] && [ -f "$PARSER" ] && [ -f "$KDL_PATH" ]; then
    if [ ! -f "$MD_OUT" ] || [ "$KDL_PATH" -nt "$MD_OUT" ]; then
      python3 "$PARSER" "$KDL_PATH" -o "$MD_OUT" --group --strict-header >/dev/null 2>&1 || true
    fi
  fi
}

# Extract the "Full actions" block from the markdown and transform into "Key — Action" lines.
extract_hints() {
  if [ ! -f "$MD_OUT" ]; then
    echo "Cheatsheet not found ($MD_OUT)." >&2
    return 1
  fi

  awk '
    BEGIN { in_section=0 }
    /^## Full actions/ { in_section=1; next }
    /^## / && in_section==1 { exit }
    in_section==1 { print }
  ' "$MD_OUT" \
  | sed -n 's/^- \*\*\(.*\)\*\* — *\(.*\)/\1 — \2/p' \
  | sed 's/  (hotkey-overlay-title=.*//; s/  (allow-when-locked=.*//'
}

# Display helpers (rofi/wofi/dmenu/zenity/less)
show_menu() {
  local menu_input="$1"
  local choice=""
  if command -v rofi >/dev/null 2>&1; then
    choice=$(printf '%s\n' "$menu_input" | rofi -dmenu -i -p "Keyhints")
  elif command -v wofi >/dev/null 2>&1; then
    choice=$(printf '%s\n' "$menu_input" | wofi --dmenu --placeholder "Keyhints")
  elif command -v dmenu >/dev/null 2>&1; then
    choice=$(printf '%s\n' "$menu_input" | dmenu -p "Keyhints")
  elif command -v zenity >/dev/null 2>&1; then
    # zenity --list requires columns; we'll show first 100 entries (should be plenty)
    choice=$(printf '%s\n' "$menu_input" | nl -w2 -s'. ' | zenity --text-info --width=700 --height=600 --title="Keyhints (choose an entry and close to copy)")
    # With zenity we just show the text, no selection. Return empty to skip copy.
    echo "$choice"
    return 0
  else
    # fallback: open in less and exit
    printf '%s\n' "$menu_input" | less
    return 0
  fi

  printf '%s\n' "$choice"
}

# Copy to clipboard (wl-copy preferred)
copy_clipboard() {
  local text="$1"
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$text" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$text" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$text" | xsel --clipboard --input
  fi
}

# Notification helper
notify() {
  local title="$1"
  local body="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$body"
  fi
}

main() {
  regenerate || true

  hints=$(extract_hints) || {
    echo "No hints found in $MD_OUT" >&2
    exit 1
  }

  if [ -z "$hints" ]; then
    echo "No key hints to show."
    exit 0
  fi

  # Show menu and capture selection
  selection=$(show_menu "$hints")

  # If selection is empty, exit
  if [ -z "$selection" ]; then
    exit 0
  fi

  # Copy selection to clipboard and notify
  copy_clipboard "$selection"
  notify "Keyhint copied" "$selection"

  # Also print selection to stdout for debug
  printf '%s\n' "$selection"
}

main "$@"