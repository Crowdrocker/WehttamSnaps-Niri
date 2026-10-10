#!/usr/bin/env bash
# watch_cheatsheet.sh
# Simple watcher that regenerates the cheatsheet when the KDL file is modified.
# Requires inotifywait (inotify-tools). Make executable: chmod +x watch_cheatsheet.sh

KDL="dots/.config/niri/snaps/10-wiri_keybinds.kdl"
SCRIPT="./generate_niri_cheatsheet.py"
OUT="docs/10-wiri_keybinds-cheatsheet.md"

if ! command -v inotifywait >/dev/null 2>&1; then
  echo "inotifywait not found. Install inotify-tools or use the Makefile watch target."
  exit 2
fi

mkdir -p "$(dirname "$OUT")"

echo "Watching $KDL for changes..."
while inotifywait -e close_write "$KDL"; do
  echo "Change detected, regenerating cheatsheet..."
  python3 "$SCRIPT" "$KDL" -o "$OUT" --group --strict-header || echo "Generation failed"
  echo "Done."
done