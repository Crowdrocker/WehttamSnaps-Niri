#!/usr/bin/env bash
# Keyhints_direct_kdl.sh
# Show Niri keybind hints by parsing the KDL file directly (no intermediate markdown).
#
# Features:
# - Parses the first binds { ... } block from a KDL file and extracts "Key — Action (Notes)" lines.
# - Shows an interactive chooser (rofi / wofi / dmenu / zenity / less).
# - Copies the selected line to clipboard (wl-copy / xclip / xsel) and sends a notification.
# - Environment-configurable paths (KDL_PATH) so you can place it in your scripts dir and bind it in Niri.
#
# Usage:
#   KDL_PATH=/path/to/10-wiri_keybinds.kdl ./Keyhints_direct_kdl.sh
#
# Defaults (override with env vars):
#   KDL_PATH  - path to the KDL file (default: ./dots/.config/niri/snaps/10-wiri_keybinds.kdl)
#   CHOICE_CMD - prefered menu program (rofi|wofi|dmenu); script still falls back
#
# Make executable:
#   chmod +x Keyhints_direct_kdl.sh
#
# Bind in your KDL:
#   Mod+H { spawn "~/.config/wehttamsnaps/scripts/Keyhints_direct_kdl.sh"; }

set -euo pipefail

: "${KDL_PATH:=dots/.config/niri/snaps/10-wiri_keybinds.kdl}"
: "${CHOICE_CMD:=auto}"    # rofi, wofi, dmenu, zenity, auto
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

if [ ! -f "$KDL_PATH" ]; then
  echo "KDL file not found: $KDL_PATH" >&2
  exit 2
fi

# Use embedded Python to robustly parse the binds block and print "Key — Action (Notes)"
python3 - "$KDL_PATH" > "$TMP" <<'PY'
import sys, re, json, pathlib

def read_file(p):
    return pathlib.Path(p).read_text(encoding='utf-8')

def extract_binds_block(text):
    m = re.search(r'\bbinds\b', text)
    if not m:
        return ""
    start = m.start()
    brace_idx = text.find('{', start)
    if brace_idx == -1:
        return ""
    depth = 0
    for pos in range(brace_idx, len(text)):
        c = text[pos]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return text[brace_idx+1:pos]
    return ""

def remove_line_comments(text):
    # keep comments separately (not needed here), just remove // comments
    return re.sub(r'//.*', '', text)

def normalize_whitespace(s):
    return re.sub(r'\s+', ' ', s).strip()

def parse_binds(block):
    # permissive regex to capture key+attrs and inner block
    pattern = re.compile(r'([^\{\n]+?)\s*\{\s*(.*?)\s*\}\s*', re.DOTALL)
    for m in pattern.finditer(block):
        key_attrs = normalize_whitespace(m.group(1))
        inner = m.group(2).strip()
        if not key_attrs or not inner:
            continue
        parts = key_attrs.split(None, 1)
        key = parts[0]
        attrs = parts[1] if len(parts) > 1 else ""
        # split actions on semicolons not in quotes
        action_parts = []
        cur = []
        in_q = False
        qch = ''
        for ch in inner:
            if ch in ("'", '"'):
                if in_q and ch == qch:
                    in_q = False
                    qch = ''
                elif not in_q:
                    in_q = True
                    qch = ch
                cur.append(ch)
            elif ch == ';' and not in_q:
                part = ''.join(cur).strip()
                if part:
                    action_parts.append(normalize_whitespace(part))
                cur = []
            else:
                cur.append(ch)
        last = ''.join(cur).strip()
        if last:
            action_parts.append(normalize_whitespace(last))
        action = '; '.join(action_parts)
        # filter out empty
        if not action:
            continue
        yield {"key": key, "action": action, "attrs": attrs}

def main(path):
    txt = read_file(path)
    binds = extract_binds_block(txt)
    if not binds:
        # fallback: try entire file
        binds = txt
    # remove comments only for parsing safety (we don't need them as headings here)
    binds_plain = re.sub(r'//[^\n]*', '\n', binds)
    items = list(parse_binds(binds_plain))
    # Print lines: KEY — ACTION  (Notes: ...)
    for it in items:
        notes = f" ({it['attrs']})" if it['attrs'] else ""
        print(f"{it['key']} — {it['action']}{notes}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: parser.py path/to/file.kdl", file=sys.stderr)
        sys.exit(2)
    main(sys.argv[1])
PY

# If no lines produced, exit
if [ ! -s "$TMP" ]; then
  echo "No keybinds parsed from $KDL_PATH" >&2
  exit 3
fi

# Menu chooser function: try rofi/wofi/dmenu/zenity, fallback to less
show_menu() {
  local input_file="$1"
  local choice
  if [ "$CHOICE_CMD" = "rofi" ] || [ "$CHOICE_CMD" = "auto" ] && command -v rofi >/dev/null 2>&1; then
    choice=$(rofi -dmenu -i -p "Keyhints" < "$input_file")
    printf '%s' "$choice"
    return
  fi
  if [ "$CHOICE_CMD" = "wofi" ] || [ "$CHOICE_CMD" = "auto" ] && command -v wofi >/dev/null 2>&1; then
    choice=$(wofi --dmenu --placeholder "Keyhints" < "$input_file")
    printf '%s' "$choice"
    return
  fi
  if [ "$CHOICE_CMD" = "dmenu" ] || [ "$CHOICE_CMD" = "auto" ] && command -v dmenu >/dev/null 2>&1; then
    choice=$(dmenu -p "Keyhints" < "$input_file")
    printf '%s' "$choice"
    return
  fi
  if command -v zenity >/dev/null 2>&1; then
    # show entire list in a scrollable dialog; no selection returned
    zenity --text-info --width=700 --height=600 --title="Keyhints" --filename="$input_file"
    return
  fi
  # fallback: open less
  less "$input_file"
}

CHOICE=$(show_menu "$TMP" || true)

if [ -z "$CHOICE" ]; then
  # nothing chosen or user closed dialog
  exit 0
fi

# Copy to clipboard (wl-copy preferred on Wayland)
if command -v wl-copy >/dev/null 2>&1; then
  printf '%s' "$CHOICE" | wl-copy
elif command -v xclip >/dev/null 2>&1; then
  printf '%s' "$CHOICE" | xclip -selection clipboard
elif command -v xsel >/dev/null 2>&1; then
  printf '%s' "$CHOICE" | xsel --clipboard --input
fi

# Send notification
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Keyhint copied" "$CHOICE"
fi

# Print selected line to stdout so the caller gets it
printf '%s\n' "$CHOICE"