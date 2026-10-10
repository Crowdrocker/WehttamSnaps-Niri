#!/usr/bin/env bash
# Keyhints_direct_kdl_with_groups.sh
# Interactive Niri keyhints with:
#  - Filter-by-group (section headings detected from comments)
#  - Search-as-you-type using rofi/wofi/dmenu with configurable flags/themes
#  - Copies chosen entry to clipboard (wl-copy/xclip/xsel) and notifies (notify-send)
#
# Usage:
#   KDL_PATH=/full/path/to/10-wiri_keybinds.kdl ./Keyhints_direct_kdl_with_groups.sh
#
# Environment/config variables you can set:
#   KDL_PATH    - path to the KDL file (default: dots/.config/niri/snaps/10-wiri_keybinds.kdl)
#   CHOICE_CMD  - preferred chooser: auto | rofi | wofi | dmenu | zenity  (default: auto)
#   ROFI_OPTS   - additional args to pass to rofi (e.g. "-theme ~/.config/rofi/themes/my.rasi")
#   WOFi_OPTS   - additional args for wofi (e.g. "--style ~/.config/wofi/style.css")
#   COPY_MODE   - what to copy on selection: both | key | action  (default: both)
#   SHOW_ALL_LABEL - label used to show all binds in group menu (default: "All")
#
# Example:
#   KDL_PATH=./dots/.config/niri/snaps/10-wiri_keybinds.kdl CHOICE_CMD=rofi ROFI_OPTS="-theme Arc-Dark" ./Keyhints_direct_kdl_with_groups.sh
#
# Place in your scripts dir and bind in Niri:
#   Mod+H { spawn "~/.config/wehttamsnaps/scripts/Keyhints_direct_kdl_with_groups.sh"; }

set -euo pipefail

: "${KDL_PATH:=dots/.config/niri/snaps/10-wiri_keybinds.kdl}"
: "${CHOICE_CMD:=auto}"
: "${ROFI_OPTS:='-dmenu -i -p Keyhints'}"
: "${WOFI_OPTS:='--dmenu'}"
: "${COPY_MODE:=both}"   # both|key|action
: "${SHOW_ALL_LABEL:=All}"

TMP_JSON="$(mktemp --suffix=.json)"
TMP_MENU="$(mktemp)"
trap 'rm -f "$TMP_JSON" "$TMP_MENU"' EXIT

if [ ! -f "$KDL_PATH" ]; then
  echo "KDL file not found: $KDL_PATH" >&2
  exit 2
fi

# Embedded Python: parse binds block and group by headings.
# Outputs JSON: { "groups": [ {"name": "NAME", "entries": [ {"key": "...", "action":"...", "attrs":"..."} ] } ] }
python3 - "$KDL_PATH" > "$TMP_JSON" <<'PY' || { echo "Parsing failed"; exit 3; }
import sys, re, json, pathlib

p = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8')

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

def normalize_ws(s):
    return re.sub(r'\s+', ' ', s).strip()

def parse_binds(block):
    # find comment lines to attach headings
    comment_lines = []
    for i, line in enumerate(block.splitlines()):
        if line.strip().startswith('//'):
            comment_lines.append((i, line.strip()[2:].strip()))
    # find binds with position
    pattern = re.compile(r'([^\{\n]+?)\s*\{\s*(.*?)\s*\}\s*', re.DOTALL)
    items = []
    for m in pattern.finditer(block):
        start_idx = block[:m.start()].count('\n')
        key_attrs = normalize_ws(m.group(1))
        inner = m.group(2).strip()
        if not key_attrs or not inner:
            continue
        parts = key_attrs.split(None, 1)
        key = parts[0]
        attrs = parts[1] if len(parts) > 1 else ""
        # split actions on semicolons not inside quotes
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
                    action_parts.append(normalize_ws(part))
                cur = []
            else:
                cur.append(ch)
        last = ''.join(cur).strip()
        if last:
            action_parts.append(normalize_ws(last))
        action = '; '.join(action_parts)
        if not action:
            continue
        items.append({'start_line': start_idx, 'key': key, 'action': action, 'attrs': attrs})
    # attach headings: find nearest preceding comment heading for each item
    groups = []
    # produce headings from detected decoration/comment lines: prefer lines with ===, ---, ──, or ALL CAPS
    def detect_heading_before(line_idx):
        # find last comment line index <= line_idx
        candidates = [c for c in comment_lines if c[0] <= line_idx]
        if not candidates:
            return "Ungrouped"
        for idx, txt in reversed(candidates):
            if not txt:
                continue
            if any(x in txt for x in ['===','---','──','──','──']):
                return txt.strip()
            # uppercase heuristic
            upp = sum(1 for ch in txt if ch.isupper())
            low = sum(1 for ch in txt if ch.islower())
            if upp >= low and upp > 0 and len(txt) <= 80:
                return txt.strip()
        # fallback to the last comment text
        return candidates[-1][1].strip()
    # group entries
    group_map = {}
    order = []
    for it in items:
        heading = detect_heading_before(it['start_line'])
        if heading not in group_map:
            group_map[heading] = []
            order.append(heading)
        group_map[heading].append({'key': it['key'], 'action': it['action'], 'attrs': it['attrs']})
    # build JSON
    out = {'groups': []}
    # Put the "All" pseudo-group first if many groups; also keep order
    for name in order:
        out['groups'].append({'name': name, 'entries': group_map[name]})
    # If no groups found, create default All group
    if not out['groups'] and items:
        out['groups'].append({'name': 'All', 'entries': [{'key': it['key'], 'action': it['action'], 'attrs': it['attrs']} for it in items]})
    print(json.dumps(out, ensure_ascii=False))
PY

# Read groups from JSON (use python to avoid requiring jq)
GROUPS=()
mapfile -t GROUPS < <(python3 - "$TMP_JSON" <<'PY'
import sys, json
d = json.load(open(sys.argv[1], encoding='utf-8'))
for g in d.get('groups', []):
    print(g['name'])
PY "$TMP_JSON")

if [ ${#GROUPS[@]} -eq 0 ]; then
  echo "No groups detected or no binds parsed." >&2
  exit 3
fi

# Build group menu: include a SHOW_ALL option at top
printf "%s\n" "$SHOW_ALL_LABEL" > "$TMP_MENU"
for g in "${GROUPS[@]}"; do
  printf '%s\n' "$g" >> "$TMP_MENU"
done

# chooser helper
chooser() {
  local input_file="$1"
  local prompt="$2"
  local choice=""
  if [ "$CHOICE_CMD" = "rofi" ] || { [ "$CHOICE_CMD" = "auto" ] && command -v rofi >/dev/null 2>&1; }; then
    # ROFI_OPTS example: "-dmenu -i -p Keyhints -mesg 'Select' -lines 20"
    choice=$(rofi $ROFI_OPTS < "$input_file")
    printf '%s' "$choice"
    return
  fi
  if [ "$CHOICE_CMD" = "wofi" ] || { [ "$CHOICE_CMD" = "auto" ] && command -v wofi >/dev/null 2>&1; }; then
    choice=$(wofi $WOFI_OPTS < "$input_file")
    printf '%s' "$choice"
    return
  fi
  if [ "$CHOICE_CMD" = "dmenu" ] || { [ "$CHOICE_CMD" = "auto" ] && command -v dmenu >/dev/null 2>&1; }; then
    choice=$(dmenu -i -p "$prompt" < "$input_file")
    printf '%s' "$choice"
    return
  fi
  if command -v zenity >/dev/null 2>&1; then
    # Zenity can't return selection easily; show list and exit
    zenity --text-info --filename="$input_file" --title="$prompt"
    return
  fi
  # fallback to less
  less "$input_file"
}

# Present group menu and get choice (search-as-you-type provided by rofi/wofi/dmenu)
GROUP_CHOICE="$(chooser "$TMP_MENU" "Choose group")" || true
if [ -z "$GROUP_CHOICE" ]; then
  exit 0
fi

# Determine which group's entries to show; if SHOW_ALL_LABEL selected show concatenated all groups.
if [ "$GROUP_CHOICE" = "$SHOW_ALL_LABEL" ]; then
  # print all entries
  python3 - "$TMP_JSON" > "$TMP_MENU" <<'PY'
import sys, json
d=json.load(open(sys.argv[1],encoding='utf-8'))
out=[]
for g in d.get('groups',[]):
    for e in g.get('entries',[]):
        notes = f" ({e['attrs']})" if e.get('attrs') else ""
        out.append(f"{e['key']} — {e['action']}{notes}")
print("\n".join(out))
PY "$TMP_JSON"
else
  # print only chosen group (match exact name)
  python3 - "$TMP_JSON" "$GROUP_CHOICE" > "$TMP_MENU" <<'PY'
import sys, json
d=json.load(open(sys.argv[1],encoding='utf-8'))
grp_name=sys.argv[2]
for g in d.get('groups',[]):
    if g.get('name')==grp_name:
        for e in g.get('entries',[]):
            notes = f" ({e['attrs']})" if e.get('attrs') else ""
            print(f"{e['key']} — {e['action']}{notes}")
        break
PY "$TMP_JSON" "$GROUP_CHOICE"
fi

# If no entries for group
if [ ! -s "$TMP_MENU" ]; then
  echo "No entries found for group '$GROUP_CHOICE'." >&2
  exit 0
fi

# Show binds in the chosen group (search-as-you-type via chooser)
SELECTION="$(chooser "$TMP_MENU" "Choose binding")" || true
if [ -z "$SELECTION" ]; then
  exit 0
fi

# Determine what to copy based on COPY_MODE (both|key|action)
case "$COPY_MODE" in
  key)
    # extract lhs before ' — '
    COPY_VAL="$(printf '%s' "$SELECTION" | awk -F ' — ' '{print $1}')"
    ;;
  action)
    COPY_VAL="$(printf '%s' "$SELECTION" | awk -F ' — ' '{print $2}')"
    ;;
  *)
    COPY_VAL="$SELECTION"
    ;;
esac

# Copy to clipboard
if command -v wl-copy >/dev/null 2>&1; then
  printf '%s' "$COPY_VAL" | wl-copy
elif command -v xclip >/dev/null 2>&1; then
  printf '%s' "$COPY_VAL" | xclip -selection clipboard
elif command -v xsel >/dev/null 2>&1; then
  printf '%s' "$COPY_VAL" | xsel --clipboard --input
fi

# Notify
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Keyhint copied" "$COPY_VAL"
fi

# Print selection (useful if spawned from Niri)
printf '%s\n' "$SELECTION"