Yes — you can automatically generate a keybind cheatsheet for Niri by extracting the actual mappings at runtime (recommended) or by statically parsing your config files. The runtime approach is the simplest and most reliable because it lists the mappings that Neovim actually has (so it catches mappings added/removed by Niri or any other plugin).

Below are two practical approaches and a ready-to-run Lua script you can drop into your Neovim config to produce a Markdown cheatsheet.

1) Runtime (recommended) — query Neovim's mapping registry
- This queries Neovim for all mappings (all modes) and writes a Markdown table with lhs, rhs, and description.
- It will reflect changes immediately when you add/remove mappings (run it to regenerate).
- Works regardless of whether mappings were created by Niri, vim.keymap.set, or vim.api.nvim_set_keymap.

Save this file and run it (or call it from your config).

```lua name=generate-keybinds.lua
-- generate-keybinds.lua
-- Generates a Markdown cheatsheet of current Neovim keymaps and writes it to:
--   ~/.config/nvim/niri-keybinds-cheatsheet.md  (adjust path if needed)

local output_path = vim.fn.stdpath('config') .. '/niri-keybinds-cheatsheet.md'
local modes = {
  n = 'Normal',
  i = 'Insert',
  v = 'Visual',
  x = 'Visual (x)',
  s = 'Select',
  o = 'Operator-pending',
  c = 'Command',
  t = 'Terminal',
}

local function escape_pipe(str)
  if not str then return '' end
  return str:gsub('|', '\\|'):gsub('\n', '\\n')
end

local lines = {}
table.insert(lines, '# Keybind cheatsheet')
table.insert(lines, '')
table.insert(lines, '*Generated: ' .. os.date('%Y-%m-%d %H:%M:%S') .. '*')
table.insert(lines, '')

for mode, pretty in pairs(modes) do
  local maps = vim.api.nvim_get_keymap(mode)
  if #maps > 0 then
    table.insert(lines, '## ' .. pretty .. ' (' .. mode .. ')')
    table.insert(lines, '')
    table.insert(lines, '| LHS | RHS | Desc | Buffer | Expr | Silent | Script |')
    table.insert(lines, '|-----|-----|------|--------|------|--------|--------|')
    for _, m in ipairs(maps) do
      local lhs = '`' .. escape_pipe(m.lhs) .. '`'
      local rhs = '`' .. escape_pipe(m.rhs) .. '`'
      local desc = m.desc or ''
      local buffer = tostring(m.buffer ~= nil and m.buffer or false)
      local expr = tostring(m.expr and true or false)
      local silent = tostring(m.silent and true or false)
      local script = tostring(m.script and true or false)
      table.insert(lines, string.format('| %s | %s | %s | %s | %s | %s | %s |',
        lhs, rhs, desc, buffer, expr, silent, script))
    end
    table.insert(lines, '')
  end
end

-- Write file
vim.fn.writefile(lines, output_path)
print('Keybind cheatsheet written to: ' .. output_path)
```

How to run:
- From within Neovim: :luafile /path/to/generate-keybinds.lua
- Or create a command in your init.lua:
  - vim.api.nvim_create_user_command('DumpKeybinds', function() dofile(vim.fn.stdpath('config')..'/generate-keybinds.lua') end, {})

2) Static (grep/parse) — search your repo for Niri registration calls
- If your keybinds are declared in a consistent pattern (e.g., require('niri').register(...), or calls to vim.keymap.set), you can grep and parse those lines to make a cheatsheet.
- Example shell pipeline to find likely binding calls:
  - grep -R --line-number -E "niri\.register|vim\.keymap\.set|vim.api\.nvim_set_keymap" .
- You can then craft a small parser in Python/Lua/Node that extracts the lhs/rhs/desc from those calls and outputs Markdown.

3) Inspect Niri's internal registry (if available)
- Some plugins keep an internal table of registered bindings. If Niri exposes a table, you can inspect it:
  - In Neovim: :lua =vim.inspect(require('niri')) or :lua print(vim.inspect(require('niri')._registry)) — only if such field exists.
- If you find a registry, iterate it and output the entries (similar idea to the runtime script above). If you want, paste the small output here and I can help convert it to a cheatsheet generator.

Other options / niceties
- Add mapping descriptions: make sure to add the 'desc' field when you create mappings (`vim.keymap.set({...}, { desc = '...' })`) — the runtime script will include that and makes the cheat sheet readable.
- Integrate with which-key: which-key and similar plugins show a popup; but the runtime script can write a persistent Markdown file for printing/sharing.
- Auto-regenerate: add a command or autocommand to regenerate after you edit your keybind file(s).

Would you like:
- I can adapt the Lua script to your repo patterns (e.g., if Niri.register is how you define binds) — tell me how your bindings look (post a sample binding), or
- I can provide a small grep+parser script for the repo to run from the command line.

Tell me how your keybinds are defined (examples) or whether you prefer the runtime approach and I’ll generate a tailored script/command for your setup.
############################################################################################################

```python name=generate_niri_cheatsheet.py
#!/usr/bin/env python3
"""
generate_niri_cheatsheet.py

Small parser that reads a Niri KDL-style "binds" snippet and regenerates a Markdown
cheatsheet listing Key | Action | Notes.

Usage:
  python generate_niri_cheatsheet.py path/to/10-wiri_keybinds.kdl
  python generate_niri_cheatsheet.py -i path/to/10-wiri_keybinds.kdl -o cheatsheet.md

The script:
- Finds the top-level 'binds { ... }' block.
- Removes // comments.
- Extracts each binding of the form:
    Key [attributes] { ... }
  and captures:
    - Key (e.g. Mod+1, Mod+Shift+T, XF86AudioPlay)
    - Action (contents inside braces, semicolons collapsed to '; ')
    - Attributes (e.g. repeat=false, hotkey-overlay-title="...", allow-when-locked=true)
- Writes a Markdown table grouped as a single list (you can adapt grouping later).
"""
from __future__ import annotations
import re
import argparse
import os
import sys
from textwrap import shorten

def read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def extract_binds_block(text: str) -> str:
    """
    Find the first 'binds {' occurrence and return the inner text up to the matching closing brace.
    Returns empty string if not found.
    """
    m = re.search(r'\bbinds\b', text)
    if not m:
        return ""
    start = m.start()
    # find the first '{' after 'binds'
    brace_idx = text.find('{', start)
    if brace_idx == -1:
        return ""
    i = brace_idx
    depth = 0
    for pos in range(brace_idx, len(text)):
        c = text[pos]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                # return content between the outer braces
                return text[brace_idx+1:pos]
    return ""

def remove_line_comments(s: str) -> str:
    # remove // comments (KDL-style single-line comments)
    return re.sub(r'//.*', '', s)

def normalize_whitespace(s: str) -> str:
    # collapse whitespace and trim
    return re.sub(r'\s+', ' ', s).strip()

def parse_binds(block: str):
    """
    Parse binds inside the block. Yields dicts with keys: key, action, attrs.
    This uses a permissive regex since inner commands rarely include braces.
    """
    # Ensure we operate on a comment-free block
    block = remove_line_comments(block)

    # Regex: capture "key + optional attrs" followed by { inner }.
    # Use DOTALL to allow multiline inner content.
    pattern = re.compile(r'([^\{\n]+?)\s*\{\s*(.*?)\s*\}\s*', re.DOTALL)

    for m in pattern.finditer(block):
        key_attrs = normalize_whitespace(m.group(1))
        inner = m.group(2).strip()

        if not key_attrs:
            continue

        # First token is the key (e.g. Mod+1). The rest are attributes like repeat=false
        parts = key_attrs.split(None, 1)
        key = parts[0]
        attrs = parts[1] if len(parts) > 1 else ""

        # Clean up action: remove trailing semicolons, collapse multiple semicolons into '; '.
        # Also remove leading/trailing whitespace/newlines.
        # Keep quoted strings intact.
        # Split on semicolons that are not inside quotes.
        action_parts = []
        cur = []
        in_quote = False
        quote_char = ""
        for ch in inner:
            if ch in ('"', "'"):
                if in_quote and ch == quote_char:
                    in_quote = False
                    quote_char = ""
                elif not in_quote:
                    in_quote = True
                    quote_char = ch
                cur.append(ch)
            elif ch == ';' and not in_quote:
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

        # Skip empty/meaningless entries
        if not key or not action:
            # allow entries that are just actions like 'screenshot-screen;' with no explicit spawn.
            if not key or not action:
                continue

        yield {
            "key": key,
            "action": action,
            "attrs": attrs
        }

def generate_markdown(bind_entries, source_path=None):
    lines = []
    source_line = f"Source: {source_path}" if source_path else ""
    lines.append("# Niri Keybinds Cheatsheet")
    if source_line:
        lines.append("")
        lines.append(source_line)
    lines.append("")
    lines.append(f"*Generated: {__import__('datetime').datetime.utcnow().strftime('%Y-%m-%d %H:%M:%SZ')}*")
    lines.append("")
    lines.append("| Key | Action | Notes |")
    lines.append("|-----|--------|-------|")
    for b in bind_entries:
        key = f"`{b['key']}`"
        # shorten long actions for table readability but keep full action available below
        action = b['action']
        # Escape pipe characters in action/attrs
        action = action.replace("|", "\\|")
        attrs = (b['attrs'] or "").replace("|", "\\|")
        lines.append(f"| {key} | `{action}` | {attrs} |")
    lines.append("")
    # Append a full listing with un-shortened actions for easier reading
    lines.append("## Full actions")
    lines.append("")
    for b in bind_entries:
        lines.append(f"- **{b['key']}** — {b['action']}" + (f"  \n  Notes: {b['attrs']}" if b['attrs'] else ""))
    lines.append("")
    return "\n".join(lines)

def main():
    ap = argparse.ArgumentParser(description="Generate a Markdown cheatsheet from a Niri KDL binds block.")
    ap.add_argument("input", nargs="?", help="Path to KDL file (e.g. dots/.config/niri/snaps/10-wiri_keybinds.kdl). If omitted reads stdin.", default=None)
    ap.add_argument("-o", "--output", help="Output Markdown file path. If omitted prints to stdout.", default=None)
    args = ap.parse_args()

    if args.input:
        if not os.path.exists(args.input):
            print(f"Input file not found: {args.input}", file=sys.stderr)
            sys.exit(2)
        text = read_file(args.input)
    else:
        text = sys.stdin.read()

    binds_block = extract_binds_block(text)
    if not binds_block:
        print("No 'binds { ... }' block found in input.", file=sys.stderr)
        sys.exit(3)

    entries = list(parse_binds(binds_block))
    if not entries:
        print("No keybinds parsed from binds block.", file=sys.stderr)
        sys.exit(4)

    md = generate_markdown(entries, source_path=args.input)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(md)
        print("Cheatsheet written to:", args.output)
    else:
        print(md)

if __name__ == "__main__":
    main()
```

Usage example:
- Save the script (above) as generate_niri_cheatsheet.py and make it executable (chmod +x).
- Run:
  - python generate_niri_cheatsheet.py dots/.config/niri/snaps/10-wiri_keybinds.kdl -o 10-wiri_keybinds-cheatsheet.md
  - or pipe: cat dots/.config/niri/snaps/10-wiri_keybinds.kdl | python generate_niri_cheatsheet.py

Notes and improvements you may want:
- The script is intentionally simple and permissive; it assumes inner commands do not contain unmatched braces.
- It strips // comments so commented-out binds are omitted automatically.
- Attributes are preserved and placed in the Notes column (e.g. hotkey-overlay-title, repeat=false).
- If you want grouping (Workspace, System, Window management) the parser can be extended to detect comment section headers (lines like "// === WORKSPACE SWITCHING ===") and attach those group labels to the following binds — I can add that if you want.
- If you prefer a version in Lua or a different output layout (per-category files, JSON), tell me which format and I'll adapt it.

Per your earlier instruction, here is the requested snippet exactly as markdown:

```markdown
  - provide a small parser that reads your KDL file and regenerates this Markdown, or
```

Would you like me to:
- add support for grouping by commented headings (e.g., "/// === WORKSPACE SWITCHING ===")?
- output per-category files or a JSON manifest instead of a single Markdown table?

############################################################################################################

```python name=generate_niri_cheatsheet.py
#!/usr/bin/env python3
"""
generate_niri_cheatsheet.py

Enhanced parser for Niri KDL-style "binds" snippets that:
- Groups binds by nearby comment headings (e.g. lines with "// === WORKSPACE SWITCHING ===")
- Outputs a single grouped Markdown file (default)
- Optionally outputs JSON (--json)
- Optionally writes per-group Markdown files (--split-dir DIR)

Usage examples:
  python generate_niri_cheatsheet.py dots/.config/niri/snaps/10-wiri_keybinds.kdl -o cheatsheet.md --group
  python generate_niri_cheatsheet.py dots/.config/niri/snaps/10-wiri_keybinds.kdl -o cheatsheet.json --json --group
  python generate_niri_cheatsheet.py dots/.config/niri/snaps/10-wiri_keybinds.kdl --group --split-dir out_dir
"""
from __future__ import annotations
import re
import argparse
import os
import sys
import json
from datetime import datetime
from typing import List, Dict, Optional

def read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def extract_binds_block(text: str) -> str:
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

def remove_line_comments_only(s: str) -> str:
    # Remove only comments that are not headings (we'll keep comments separately)
    return re.sub(r'//.*', '', s)

def find_bind_matches(block: str):
    """
    Finds all binds with their spans so we can look at context (nearby comments).
    Yields tuples: (match_obj, start, end)
    """
    pattern = re.compile(r'([^\{\n]+?)\s*\{\s*(.*?)\s*\}\s*', re.DOTALL)
    for m in pattern.finditer(block):
        yield m, m.start(), m.end()

def extract_last_heading_between(text: str) -> Optional[str]:
    """
    Given a text slice (the context before a bind), find the last comment line
    that looks like a heading. Heuristics:
      - contains === or --- or '──' OR
      - more uppercase letters than lowercase (e.g., "WORKSPACE SWITCHING")
    Returns cleaned heading or None.
    """
    comments = re.findall(r'//[^\n]*', text)
    if not comments:
        return None
    for c in reversed(comments):
        content = c[2:].strip()
        # if content is empty skip
        if not content:
            continue
        # heuristics
        if '===' in content or '---' in content or '──' in content:
            # remove surrounding decoration
            cleaned = re.sub(r'^[\s\-=~›«»▌▐\|]+', '', content)
            cleaned = re.sub(r'[\s\-=~›«»▌▐\|]+$', '', cleaned)
            return cleaned.strip()
        # count uppercase vs lowercase letters
        upp = sum(1 for ch in content if ch.isupper())
        low = sum(1 for ch in content if ch.islower())
        if upp >= low and upp > 0:
            return content.strip()
    return None

def normalize_whitespace(s: str) -> str:
    return re.sub(r'\s+', ' ', s).strip()

def parse_bind_from_match(m) -> Optional[Dict]:
    key_attrs = normalize_whitespace(m.group(1))
    inner = m.group(2).strip()
    if not key_attrs or not inner:
        return None
    parts = key_attrs.split(None, 1)
    key = parts[0]
    attrs = parts[1] if len(parts) > 1 else ""
    # Split inner by semicolons not inside quotes
    action_parts = []
    cur = []
    in_quote = False
    quote_char = ""
    for ch in inner:
        if ch in ('"', "'"):
            if in_quote and ch == quote_char:
                in_quote = False
                quote_char = ""
            elif not in_quote:
                in_quote = True
                quote_char = ch
            cur.append(ch)
        elif ch == ';' and not in_quote:
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
    # Skip empties
    if not action:
        return None
    return {"key": key, "action": action, "attrs": attrs}

def group_binds(bind_block: str) -> List[Dict]:
    """
    Returns list of groups: [{name: str, entries: [ {key, action, attrs} ] }]
    """
    groups: List[Dict] = []
    default_group_name = "Ungrouped"
    last_end = 0
    for m, start, end in find_bind_matches(bind_block):
        context_before = bind_block[last_end:start]
        header = extract_last_heading_between(context_before) or default_group_name
        entry = parse_bind_from_match(m)
        if not entry:
            last_end = end
            continue
        # find or create group
        grp = next((g for g in groups if g["name"] == header), None)
        if grp is None:
            grp = {"name": header, "entries": []}
            groups.append(grp)
        grp["entries"].append(entry)
        last_end = end
    return groups

def escape_pipe(s: str) -> str:
    return s.replace("|", "\\|")

def generate_markdown(groups: List[Dict], source_path: Optional[str]=None) -> str:
    lines = []
    lines.append("# Niri Keybinds Cheatsheet")
    if source_path:
        lines.append("")
        lines.append(f"Source: {source_path}")
    lines.append("")
    lines.append(f"*Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%SZ')}*")
    lines.append("")
    for g in groups:
        lines.append(f"## {g['name']}")
        lines.append("")
        lines.append("| Key | Action | Notes |")
        lines.append("|-----|--------|-------|")
        for e in g["entries"]:
            lines.append(f"| `{escape_pipe(e['key'])}` | `{escape_pipe(e['action'])}` | {escape_pipe(e['attrs']) or ''} |")
        lines.append("")
    # Also append full-action list per group
    lines.append("## Full actions")
    lines.append("")
    for g in groups:
        lines.append(f"### {g['name']}")
        for e in g["entries"]:
            notes = f"  \n  Notes: {e['attrs']}" if e['attrs'] else ""
            lines.append(f"- **{e['key']}** — {e['action']}{notes}")
        lines.append("")
    return "\n".join(lines)

def generate_json(groups: List[Dict], source_path: Optional[str]=None) -> str:
    payload = {
        "source": source_path,
        "generated": datetime.utcnow().isoformat() + "Z",
        "groups": groups
    }
    return json.dumps(payload, indent=2, ensure_ascii=False)

def write_split(groups: List[Dict], out_dir: str, basename_prefix: str="cheatsheet"):
    os.makedirs(out_dir, exist_ok=True)
    for g in groups:
        safe_name = re.sub(r'[^a-zA-Z0-9_-]+', '_', g['name']).strip('_') or 'group'
        path = os.path.join(out_dir, f"{basename_prefix}_{safe_name}.md")
        with open(path, "w", encoding="utf-8") as f:
            f.write("# " + g['name'] + "\n\n")
            f.write(f"*Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%SZ')}*\n\n")
            f.write("| Key | Action | Notes |\n|-----|--------|-------|\n")
            for e in g['entries']:
                f.write(f"| `{escape_pipe(e['key'])}` | `{escape_pipe(e['action'])}` | {escape_pipe(e['attrs']) or ''} |\n")
            f.write("\n")
    return out_dir

def main():
    ap = argparse.ArgumentParser(description="Generate a grouped Markdown/JSON cheatsheet from a Niri KDL binds block.")
    ap.add_argument("input", nargs="?", help="Path to KDL file. If omitted reads stdin.", default=None)
    ap.add_argument("-o", "--output", help="Output path (file). If omitted, prints to stdout.", default=None)
    ap.add_argument("--group", action="store_true", help="Group binds by nearby comment headings (heuristic).")
    ap.add_argument("--json", action="store_true", help="Output JSON instead of Markdown.")
    ap.add_argument("--split-dir", help="Write per-group Markdown files into DIR (creates DIR).")
    args = ap.parse_args()

    if args.input:
        if not os.path.exists(args.input):
            print(f"Input file not found: {args.input}", file=sys.stderr)
            sys.exit(2)
        text = read_file(args.input)
    else:
        text = sys.stdin.read()

    binds_block = extract_binds_block(text)
    if not binds_block:
        print("No 'binds { ... }' block found in input.", file=sys.stderr)
        sys.exit(3)

    groups = group_binds(binds_block) if args.group else [{"name": "All", "entries": list(parse_bind_from_match(m) for m,_,_ in find_bind_matches(binds_block) if parse_bind_from_match(m))}]
    # filter out any None entries if not grouped
    for g in groups:
        g["entries"] = [e for e in g["entries"] if e]

    if not any(g["entries"] for g in groups):
        print("No keybinds parsed from binds block.", file=sys.stderr)
        sys.exit(4)

    if args.split_dir:
        write_split(groups, args.split_dir, basename_prefix=os.path.splitext(os.path.basename(args.output or 'cheatsheet.md'))[0])

    if args.json:
        out = generate_json(groups, source_path=args.input)
    else:
        out = generate_markdown(groups, source_path=args.input)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(out)
        print("Cheatsheet written to:", args.output)
        if args.split_dir:
            print("Per-group files written to:", args.split_dir)
    else:
        print(out)

if __name__ == "__main__":
    main()
```

Usage notes:
- Run with --group to enable grouping by comment headings. The script uses simple heuristics (===, ---, typographic lines, or mostly uppercase comments) to detect section headers in the comments above binds.
- Use --json to get a machine-readable JSON output.
- Use --split-dir DIR to write one Markdown file per detected group (useful for separate files per category).
- If you want stronger or different grouping behavior (for example, only comments that start with "// ===" or capturing the next non-comment line as the header), tell me how you annotate headings and I’ll tweak the heuristics.

Per your earlier requirement, here is the requested snippet exactly as markdown:

```markdown
  - provide a small parser that reads your KDL file and regenerates this Markdown, or
```

Would you like me to:
- add stricter header detection tuned to your file style (I can scan your file and pick patterns), or
- produce a small Makefile/command that regenerates the cheatsheet automatically when the file changes?








############################################################################################################
```python name=generate_niri_cheatsheet.py
#!/usr/bin/env python3
"""
generate_niri_cheatsheet.py

Enhanced parser for Niri KDL-style "binds" snippets.

New features in this version:
- --strict-header : Uses stricter header detection tuned to files that use decorative comment headings
                    like "// === WORKSPACE SWITCHING ===" or "// ── WINDOW MANAGEMENT ──".
- --group         : Group binds by nearby comment headings (heuristic).
- --json          : Output JSON instead of Markdown.
- --split-dir DIR : Write per-group Markdown files into DIR.

Usage examples:
  python generate_niri_cheatsheet.py dots/.config/niri/snaps/10-wiri_keybinds.kdl -o cheatsheet.md --group
  python generate_niri_cheatsheet.py path/to/10-wiri_keybinds.kdl -o cheatsheet.md --group --strict-header
  python generate_niri_cheatsheet.py path/to/10-wiri_keybinds.kdl --group --split-dir out_dir
"""
from __future__ import annotations
import re
import argparse
import os
import sys
import json
from datetime import datetime
from typing import List, Dict, Optional, Tuple

def read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def extract_binds_block(text: str) -> str:
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

def find_bind_matches(block: str):
    """
    Finds all binds with their spans so we can look at context (nearby comments).
    Yields tuples: (match_obj, start, end)
    """
    pattern = re.compile(r'([^\{\n]+?)\s*\{\s*(.*?)\s*\}\s*', re.DOTALL)
    for m in pattern.finditer(block):
        yield m, m.start(), m.end()

def normalize_whitespace(s: str) -> str:
    return re.sub(r'\s+', ' ', s).strip()

def parse_bind_from_match(m) -> Optional[Dict]:
    key_attrs = normalize_whitespace(m.group(1))
    inner = m.group(2).strip()
    if not key_attrs or not inner:
        return None
    parts = key_attrs.split(None, 1)
    key = parts[0]
    attrs = parts[1] if len(parts) > 1 else ""
    # Split inner by semicolons not inside quotes
    action_parts = []
    cur = []
    in_quote = False
    quote_char = ""
    for ch in inner:
        if ch in ('"', "'"):
            if in_quote and ch == quote_char:
                in_quote = False
                quote_char = ""
            elif not in_quote:
                in_quote = True
                quote_char = ch
            cur.append(ch)
        elif ch == ';' and not in_quote:
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
    if not action:
        return None
    return {"key": key, "action": action, "attrs": attrs}

# ---------- Header detection heuristics ----------
def extract_last_heading_between(text: str, strict: bool=False) -> Optional[str]:
    """
    Given a text slice (the context before a bind), find the last comment line
    that looks like a heading.

    If strict=True, only accept comments that:
      - start with // and contain decorative sequences (===, ---, ──, etc) OR
      - start with // and the content is mostly uppercase and reasonably short.

    If strict=False, accept more relaxed matches (previous heuristics).
    """
    comments = re.findall(r'//[^\n]*', text)
    if not comments:
        return None

    for c in reversed(comments):
        content = c[2:].strip()
        if not content:
            continue
        # Strict mode: require decorations or obvious heading pattern
        if strict:
            # decoration patterns
            if re.search(r'[=~\-\─\—]{2,}', content):
                cleaned = re.sub(r'^[\s\-=~›«»▌▐\|]+', '', content)
                cleaned = re.sub(r'[\s\-=~›«»▌▐\|]+$', '', cleaned)
                return cleaned.strip()
            # or uppercase short headings (limit length to avoid long sentences)
            upp = sum(1 for ch in content if ch.isupper())
            low = sum(1 for ch in content if ch.islower())
            if upp >= low and upp > 0 and len(content) <= 60:
                return content.strip()
            continue
        # Non-strict: previous heuristics
        if '===' in content or '---' in content or '──' in content:
            cleaned = re.sub(r'^[\s\-=~›«»▌▐\|]+', '', content)
            cleaned = re.sub(r'[\s\-=~›«»▌▐\|]+$', '', cleaned)
            return cleaned.strip()
        upp = sum(1 for ch in content if ch.isupper())
        low = sum(1 for ch in content if ch.islower())
        if upp >= low and upp > 0:
            return content.strip()
    return None

def group_binds(bind_block: str, strict_headers: bool=False) -> List[Dict]:
    """
    Returns list of groups: [{name: str, entries: [ {key, action, attrs} ] }]
    """
    groups: List[Dict] = []
    default_group_name = "Ungrouped"
    last_end = 0
    for m, start, end in find_bind_matches(bind_block):
        # We examine the text between last_end and start to find headers just above this bind.
        context_before = bind_block[last_end:start]
        header = extract_last_heading_between(context_before, strict=strict_headers) or default_group_name
        entry = parse_bind_from_match(m)
        if not entry:
            last_end = end
            continue
        grp = next((g for g in groups if g["name"] == header), None)
        if grp is None:
            grp = {"name": header, "entries": []}
            groups.append(grp)
        grp["entries"].append(entry)
        last_end = end
    return groups

# ---------- Output generators ----------
def escape_pipe(s: str) -> str:
    return s.replace("|", "\\|")

def generate_markdown(groups: List[Dict], source_path: Optional[str]=None) -> str:
    lines = []
    lines.append("# Niri Keybinds Cheatsheet")
    if source_path:
        lines.append("")
        lines.append(f"Source: {source_path}")
    lines.append("")
    lines.append(f"*Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%SZ')}*")
    lines.append("")
    for g in groups:
        lines.append(f"## {g['name']}")
        lines.append("")
        lines.append("| Key | Action | Notes |")
        lines.append("|-----|--------|-------|")
        for e in g["entries"]:
            lines.append(f"| `{escape_pipe(e['key'])}` | `{escape_pipe(e['action'])}` | {escape_pipe(e['attrs']) or ''} |")
        lines.append("")
    lines.append("## Full actions")
    lines.append("")
    for g in groups:
        lines.append(f"### {g['name']}")
        for e in g["entries"]:
            notes = f"  \n  Notes: {e['attrs']}" if e['attrs'] else ""
            lines.append(f"- **{e['key']}** — {e['action']}{notes}")
        lines.append("")
    return "\n".join(lines)

def generate_json(groups: List[Dict], source_path: Optional[str]=None) -> str:
    payload = {
        "source": source_path,
        "generated": datetime.utcnow().isoformat() + "Z",
        "groups": groups
    }
    return json.dumps(payload, indent=2, ensure_ascii=False)

def write_split(groups: List[Dict], out_dir: str, basename_prefix: str="cheatsheet"):
    os.makedirs(out_dir, exist_ok=True)
    for g in groups:
        safe_name = re.sub(r'[^a-zA-Z0-9_-]+', '_', g['name']).strip('_') or 'group'
        path = os.path.join(out_dir, f"{basename_prefix}_{safe_name}.md")
        with open(path, "w", encoding="utf-8") as f:
            f.write("# " + g['name'] + "\n\n")
            f.write(f"*Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%SZ')}*\n\n")
            f.write("| Key | Action | Notes |\n|-----|--------|-------|\n")
            for e in g['entries']:
                f.write(f"| `{escape_pipe(e['key'])}` | `{escape_pipe(e['action'])}` | {escape_pipe(e['attrs']) or ''} |\n")
            f.write("\n")
    return out_dir

# ---------- CLI ----------
def main():
    ap = argparse.ArgumentParser(description="Generate a grouped Markdown/JSON cheatsheet from a Niri KDL binds block.")
    ap.add_argument("input", nargs="?", help="Path to KDL file. If omitted reads stdin.", default=None)
    ap.add_argument("-o", "--output", help="Output path (file). If omitted, prints to stdout.", default=None)
    ap.add_argument("--group", action="store_true", help="Group binds by nearby comment headings (heuristic).")
    ap.add_argument("--strict-header", action="store_true", help="Use stricter header detection (decorative comment headings).")
    ap.add_argument("--json", action="store_true", help="Output JSON instead of Markdown.")
    ap.add_argument("--split-dir", help="Write per-group Markdown files into DIR (creates DIR).")
    args = ap.parse_args()

    if args.input:
        if not os.path.exists(args.input):
            print(f"Input file not found: {args.input}", file=sys.stderr)
            sys.exit(2)
        text = read_file(args.input)
    else:
        text = sys.stdin.read()

    binds_block = extract_binds_block(text)
    if not binds_block:
        print("No 'binds { ... }' block found in input.", file=sys.stderr)
        sys.exit(3)

    if args.group:
        groups = group_binds(binds_block, strict_headers=args.strict_header)
    else:
        # no grouping: put all in one group
        entries = []
        for m,_,_ in find_bind_matches(binds_block):
            entry = parse_bind_from_match(m)
            if entry:
                entries.append(entry)
        groups = [{"name": "All", "entries": entries}]

    for g in groups:
        g["entries"] = [e for e in g["entries"] if e]

    if not any(g["entries"] for g in groups):
        print("No keybinds parsed from binds block.", file=sys.stderr)
        sys.exit(4)

    if args.split_dir:
        write_split(groups, args.split_dir, basename_prefix=os.path.splitext(os.path.basename(args.output or 'cheatsheet.md'))[0])

    if args.json:
        out = generate_json(groups, source_path=args.input)
    else:
        out = generate_markdown(groups, source_path=args.input)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(out)
        print("Cheatsheet written to:", args.output)
        if args.split_dir:
            print("Per-group files written to:", args.split_dir)
    else:
        print(out)

if __name__ == "__main__":
    main()
```

```makefile name=Makefile
# Makefile: regenerate Niri cheatsheet
KDL = dots/.config/niri/snaps/10-wiri_keybinds.kdl
SCRIPT = generate_niri_cheatsheet.py
OUT = docs/10-wiri_keybinds-cheatsheet.md

.PHONY: cheatsheet watch

cheatsheet:
	@mkdir -p $(dir $(OUT))
	python3 $(SCRIPT) $(KDL) -o $(OUT) --group --strict-header
	@echo "Wrote $(OUT)"

# watch requires inotifywait (from inotify-tools) on Linux.
watch:
	@echo "Watching $(KDL) for changes. Requires inotifywait."
	@while inotifywait -e close_write $(KDL); do make cheatsheet; done
```

```bash name=watch_cheatsheet.sh
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
```

Instructions (quick):
- Place the updated generate_niri_cheatsheet.py next to the KDL file or in your repo root.
- Run with grouping + strict headers (recommended for your file style):
  - python3 generate_niri_cheatsheet.py dots/.config/niri/snaps/10-wiri_keybinds.kdl -o docs/10-wiri_keybinds-cheatsheet.md --group --strict-header
- Or use the Makefile:
  - make cheatsheet
- To auto-regenerate on edits (Linux):
  - ./watch_cheatsheet.sh
  - or make watch  (requires inotifywait)

If you want, I can:
- run the parser on your posted file content and produce the generated Markdown here, or
- tweak the strict-header regex further to match other decorative patterns you use (paste a few of your section comment lines if you have different styles). Which would you like?








############################################################################################################

````markdown name=10-wiri_keybinds-cheatsheet.md url=https://github.com/Crowdrocker/WehttamSnaps-Niri/blob/main/dots/.config/niri/snaps/10-wiri_keybinds.kdl
# WehttamSnaps — Niri Keybinds Cheatsheet
Source: [10-wiri_keybinds.kdl](https://github.com/Crowdrocker/WehttamSnaps-Niri/blob/main/dots/.config/niri/snaps/10-wiri_keybinds.kdl)  
Generated: 2025-12-15 00:00:00Z

> This cheatsheet was produced from the `binds { ... }` block in the listed file. Commented-out binds were omitted.

## WORKSPACE SWITCHING WITH SOUNDS

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+1` | `spawn "sh" "-c" "niri msg action focus-workspace 1 && sound-system workspace 1"` | |
| `Mod+2` | `spawn "sh" "-c" "niri msg action focus-workspace 2 && sound-system workspace 2"` | |
| `Mod+3` | `spawn "sh" "-c" "niri msg action focus-workspace 3 && sound-system workspace 3"` | |
| `Mod+4` | `spawn "sh" "-c" "niri msg action focus-workspace 4 && sound-system workspace 4"` | |
| `Mod+5` | `spawn "sh" "-c" "niri msg action focus-workspace 5 && sound-system workspace 5"` | |
| `Mod+6` | `spawn "sh" "-c" "niri msg action focus-workspace 6 && sound-system workspace 6"` | |
| `Mod+7` | `spawn "sh" "-c" "niri msg action focus-workspace 7 && sound-system workspace 7"` | |
| `Mod+8` | `spawn "sh" "-c" "niri msg action focus-workspace 8 && sound-system workspace 8"` | |
| `Mod+9` | `spawn "sh" "-c" "niri msg action focus-workspace 9 && sound-system workspace 9"` | |
| `Mod+0` | `spawn "sh" "-c" "niri msg action focus-workspace 10 && sound-system workspace 10"` | |
| `Mod+Shift+1` | `move-column-to-workspace 1` | |
| `Mod+Shift+2` | `move-column-to-workspace 2` | |
| `Mod+Shift+3` | `move-column-to-workspace 3` | |
| `Mod+Shift+4` | `move-column-to-workspace 4` | |
| `Mod+Shift+5` | `move-column-to-workspace 5` | |
| `Mod+Shift+6` | `move-column-to-workspace 6` | |
| `Mod+Shift+7` | `move-column-to-workspace 7` | |
| `Mod+Shift+8` | `move-column-to-workspace 8` | |
| `Mod+Shift+9` | `move-column-to-workspace 9` | |
| `Mod+Shift+0` | `move-column-to-workspace 10` | |

## System

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Tab` | `toggle-overview` | repeat=false |
| `Mod+Shift+E` | `quit` | |
| `Mod+Escape` | `toggle-keyboard-shortcuts-inhibit` | allow-inhibiting=false |

## ii Window Switcher (Alt+Tab)

| Key | Action | Notes |
|-----|--------|-------|
| `Alt+Tab` | `spawn "qs" "-c" "ii" "ipc" "call" "altSwitcher" "next"` | |
| `Alt+Shift+Tab` | `spawn "qs" "-c" "ii" "ipc" "call" "altSwitcher" "previous"` | |

## ii Overlay

| Key | Action | Notes |
|-----|--------|-------|
| `Super+G` | `spawn "qs" "-c" "ii" "ipc" "call" "overlay" "toggle"` | |

## ii Overview (daemon)

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Space` | `spawn "qs" "-c" "ii" "ipc" "call" "overview" "toggle"` | repeat=false |

## ii Clipboard

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+V` | `spawn "qs" "-c" "ii" "ipc" "call" "clipboard" "toggle"` | |

## ii Lock screen

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Alt+L` | `spawn "qs" "-c" "ii" "ipc" "call" "lock" "activate"` | allow-when-locked=true |

## ii Region tools

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Shift+X` | `spawn "qs" "-c" "ii" "ipc" "call" "region" "ocr"` | |
| `Mod+Shift+A` | `spawn "qs" "-c" "ii" "ipc" "call" "region" "search"` | |

## ii Wallpaper selector

| Key | Action | Notes |
|-----|--------|-------|
| `Ctrl+Alt+T` | `spawn "qs" "-c" "ii" "ipc" "call" "wallpaperSelector" "toggle"` | |

## ii Settings

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Comma` | `spawn "qs" "-c" "ii" "ipc" "call" "settings" "open"` | |

## ii Cheatsheet

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Slash` | `spawn "qs" "-c" "ii" "ipc" "call" "cheatsheet" "toggle"` | |

## ii Panel family (cycle between Material ii and Waffle styles)

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Shift+W` | `spawn "qs" "-c" "ii" "ipc" "call" "panelFamily" "cycle"` | |

## Window management

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Q` | `spawn "bash" "-c" "$HOME/.config/quickshell/ii/scripts/close-window.sh"` | repeat=false |
| `Mod+D` | `maximize-column` | |
| `Mod+F` | `fullscreen-window` | |
| `Mod+A` | `toggle-window-floating` | |

## Focus

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Left` | `focus-column-left` | |
| `Mod+Right` | `focus-column-right` | |
| `Mod+Up` | `focus-window-up` | |
| `Mod+Down` | `focus-window-down` | |
| `Mod+H` | `focus-column-left` | |
| `Mod+J` | `focus-window-down` | |
| `Mod+K` | `focus-window-up` | |
| `Mod+L` | `focus-column-right` | |

## Move windows

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Shift+Left` | `move-column-left` | |
| `Mod+Shift+Right` | `move-column-right` | |
| `Mod+Shift+Up` | `move-window-up` | |
| `Mod+Shift+Down` | `move-window-down` | |
| `Mod+Shift+H` | `move-column-left` | |
| `Mod+Shift+J` | `move-window-down` | |
| `Mod+Shift+K` | `move-window-up` | |
| `Mod+Shift+L` | `move-column-right` | |

## GAMING MODE TOGGLE

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+G` | `spawn "sound-system" "gaming-toggle"` | hotkey-overlay-title="sound-system gaming-toggle" |

## Gaming and media

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Shift+g` | `spawn "~/.config/wehttamsnaps/scripts/jarvis-manager.sh"` | hotkey-overlay-title="toggle-gaming-mode" |
| `Mod+Alt+r` | `spawn "~/bin/niri-validate.sh"` | hotkey-overlay-title="niri-validate" |

## APPLICATIONS

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+T` | `spawn "ghostty"` | terminal |
| `Mod+Return` | `spawn "ghostty"` | terminal |
| `Mod+B` | `spawn "vivaldi-stable"` | hotkey-overlay-title="Open Vivaldi" |
| `Super+E` | `spawn "thunar"` | hotkey-overlay-title="Open Thunar" |
| `Mod+Alt+D` | `spawn "rofi" "-show" "drun"` | hotkey-overlay-title="Open Rofi" |
| `Mod+Shift+B` | `spawn "brave"` | hotkey-overlay-title="Open Brave" |
| `Mod+Shift+T` | `spawn "kate"` | hotkey-overlay-title="Open Kate" |
| `Mod+O` | `spawn "flatpak" "run" "com.obsproject.Studio"` | hotkey-overlay-title="Open OBS" |
| `Mod+P` | `spawn "spotify-launcher"` | hotkey-overlay-title="Open spotify-launcher" |

## WEBAPPS

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Ctrl+t` | `spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/webapp-launcher.sh twitch"` | hotkey-overlay-title="twitch" |
| `Mod+Ctrl+y` | `spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/webapp-launcher.sh youtube"` | hotkey-overlay-title="youtube" |
| `Mod+Ctrl+s` | `spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/webapp-launcher.sh spotify"` | hotkey-overlay-title="spotify" |
| `Mod+Ctrl+d` | `spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/webapp-launcher.sh discord"` | hotkey-overlay-title="discord" |

## GAMING & GAME LAUNCHERS

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Shift+S` | `spawn "sh" "-c" "sound-system steam-launch && steam"` | hotkey-overlay-title="Open steam" |
| `Mod+Alt+P` | `spawn "protonup-qt"` | hotkey-overlay-title="Open protonup-qt" |

## SCREENSHOT WITH SOUND

| Key | Action | Notes |
|-----|--------|-------|
| `Mod+Print` | `spawn "sh" "-c" "grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png && sound-system screenshot"` | hotkey-overlay-title="Take screenshot" |
| `Ctrl+Print` | `screenshot-screen` | hotkey-overlay-title="screenshot screen" |
| `Alt+Print` | `screenshot-window` | hotkey-overlay-title="screenshot window" |

## MEDIA CONTROLS

| Key | Action | Notes |
|-----|--------|-------|
| `XF86AudioPlay` | `spawn "playerctl" "play-pause"` | allow-when-locked=true |
| `XF86AudioNext` | `spawn "playerctl" "next"` | allow-when-locked=true |
| `XF86AudioPrev` | `spawn "playerctl" "previous"` | allow-when-locked=true |
| `XF86AudioStop` | `spawn "playerctl" "stop"` | allow-when-locked=true |

## AUDIO CONTROLS WITH ADAPTIVE SOUNDS

| Key | Action | Notes |
|-----|--------|-------|
| `XF86AudioMute` | `spawn "sound-system" "mute"` | allow-when-locked=true |
| `XF86AudioRaiseVolume` | `spawn "sound-system" "volume-up"` | allow-when-locked=true |
| `XF86AudioLowerVolume` | `spawn "sound-system" "volume-down"` | allow-when-locked=true |
| `XF86AudioMicMute` | `spawn "sound-system" "mic-mute"` | allow-when-locked=true |

---

## Full actions

### WORKSPACE SWITCHING WITH SOUNDS
- **Mod+1** — spawn "sh" "-c" "niri msg action focus-workspace 1 && sound-system workspace 1"
- **Mod+2** — spawn "sh" "-c" "niri msg action focus-workspace 2 && sound-system workspace 2"
- **Mod+3** — spawn "sh" "-c" "niri msg action focus-workspace 3 && sound-system workspace 3"
- **Mod+4** — spawn "sh" "-c" "niri msg action focus-workspace 4 && sound-system workspace 4"
- **Mod+5** — spawn "sh" "-c" "niri msg action focus-workspace 5 && sound-system workspace 5"
- **Mod+6** — spawn "sh" "-c" "niri msg action focus-workspace 6 && sound-system workspace 6"
- **Mod+7** — spawn "sh" "-c" "niri msg action focus-workspace 7 && sound-system workspace 7"
- **Mod+8** — spawn "sh" "-c" "niri msg action focus-workspace 8 && sound-system workspace 8"
- **Mod+9** — spawn "sh" "-c" "niri msg action focus-workspace 9 && sound-system workspace 9"
- **Mod+0** — spawn "sh" "-c" "niri msg action focus-workspace 10 && sound-system workspace 10"
- **Mod+Shift+1** — move-column-to-workspace 1
- **Mod+Shift+2** — move-column-to-workspace 2
- **Mod+Shift+3** — move-column-to-workspace 3
- **Mod+Shift+4** — move-column-to-workspace 4
- **Mod+Shift+5** — move-column-to-workspace 5
- **Mod+Shift+6** — move-column-to-workspace 6
- **Mod+Shift+7** — move-column-to-workspace 7
- **Mod+Shift+8** — move-column-to-workspace 8
- **Mod+Shift+9** — move-column-to-workspace 9
- **Mod+Shift+0** — move-column-to-workspace 10

### System
- **Mod+Tab** — toggle-overview  (repeat=false)
- **Mod+Shift+E** — quit
- **Mod+Escape** — toggle-keyboard-shortcuts-inhibit  (allow-inhibiting=false)

### ii Window Switcher (Alt+Tab)
- **Alt+Tab** — spawn "qs" "-c" "ii" "ipc" "call" "altSwitcher" "next"
- **Alt+Shift+Tab** — spawn "qs" "-c" "ii" "ipc" "call" "altSwitcher" "previous"

### ii Overlay
- **Super+G** — spawn "qs" "-c" "ii" "ipc" "call" "overlay" "toggle"

### ii Overview (daemon)
- **Mod+Space** — spawn "qs" "-c" "ii" "ipc" "call" "overview" "toggle"  (repeat=false)

### ii Clipboard
- **Mod+V** — spawn "qs" "-c" "ii" "ipc" "call" "clipboard" "toggle"

### ii Lock screen
- **Mod+Alt+L** — spawn "qs" "-c" "ii" "ipc" "call" "lock" "activate"  (allow-when-locked=true)

### ii Region tools
- **Mod+Shift+X** — spawn "qs" "-c" "ii" "ipc" "call" "region" "ocr"
- **Mod+Shift+A** — spawn "qs" "-c" "ii" "ipc" "call" "region" "search"

### ii Wallpaper selector
- **Ctrl+Alt+T** — spawn "qs" "-c" "ii" "ipc" "call" "wallpaperSelector" "toggle"

### ii Settings
- **Mod+Comma** — spawn "qs" "-c" "ii" "ipc" "call" "settings" "open"

### ii Cheatsheet
- **Mod+Slash** — spawn "qs" "-c" "ii" "ipc" "call" "cheatsheet" "toggle"

### ii Panel family (cycle between Material ii and Waffle styles)
- **Mod+Shift+W** — spawn "qs" "-c" "ii" "ipc" "call" "panelFamily" "cycle"

### Window management
- **Mod+Q** — spawn "bash" "-c" "$HOME/.config/quickshell/ii/scripts/close-window.sh"  (repeat=false)
- **Mod+D** — maximize-column
- **Mod+F** — fullscreen-window
- **Mod+A** — toggle-window-floating

### Focus
- **Mod+Left** — focus-column-left
- **Mod+Right** — focus-column-right
- **Mod+Up** — focus-window-up
- **Mod+Down** — focus-window-down
- **Mod+H** — focus-column-left
- **Mod+J** — focus-window-down
- **Mod+K** — focus-window-up
- **Mod+L** — focus-column-right

### Move windows
- **Mod+Shift+Left** — move-column-left
- **Mod+Shift+Right** — move-column-right
- **Mod+Shift+Up** — move-window-up
- **Mod+Shift+Down** — move-window-down
- **Mod+Shift+H** — move-column-left
- **Mod+Shift+J** — move-window-down
- **Mod+Shift+K** — move-window-up
- **Mod+Shift+L** — move-column-right

### GAMING MODE TOGGLE
- **Mod+G** — spawn "sound-system" "gaming-toggle"  (hotkey-overlay-title="sound-system gaming-toggle")

### Gaming and media
- **Mod+Shift+g** — spawn "~/.config/wehttamsnaps/scripts/jarvis-manager.sh"  (hotkey-overlay-title="toggle-gaming-mode")
- **Mod+Alt+r** — spawn "~/bin/niri-validate.sh"  (hotkey-overlay-title="niri-validate")

### APPLICATIONS
- **Mod+T** — spawn "ghostty"
- **Mod+Return** — spawn "ghostty"
- **Mod+B** — spawn "vivaldi-stable"  (hotkey-overlay-title="Open Vivaldi")
- **Super+E** — spawn "thunar"  (hotkey-overlay-title="Open Thunar")
- **Mod+Alt+D** — spawn "rofi" "-show" "drun"  (hotkey-overlay-title="Open Rofi")
- **Mod+Shift+B** — spawn "brave"  (hotkey-overlay-title="Open Brave")
- **Mod+Shift+T** — spawn "kate"  (hotkey-overlay-title="Open Kate")
- **Mod+O** — spawn "flatpak" "run" "com.obsproject.Studio"  (hotkey-overlay-title="Open OBS")
- **Mod+P** — spawn "spotify-launcher"  (hotkey-overlay-title="Open spotify-launcher")

### WEBAPPS
- **Mod+Ctrl+t** — spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/webapp-launcher.sh twitch"  (hotkey-overlay-title="twitch")
- **Mod+Ctrl+y** — spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/webapp-launcher.sh youtube"  (hotkey-overlay-title="youtube")
- **Mod+Ctrl+s** — spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/webapp-launcher.sh spotify"  (hotkey-overlay-title="spotify")
- **Mod+Ctrl+d** — spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/webapp-launcher.sh discord"  (hotkey-overlay-title="discord")

### GAMING & GAME LAUNCHERS
- **Mod+Shift+S** — spawn "sh" "-c" "sound-system steam-launch && steam"  (hotkey-overlay-title="Open steam")
- **Mod+Alt+P** — spawn "protonup-qt"  (hotkey-overlay-title="Open protonup-qt")

### SCREENSHOT WITH SOUND
- **Mod+Print** — spawn "sh" "-c" "grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png && sound-system screenshot"  (hotkey-overlay-title="Take screenshot")
- **Ctrl+Print** — screenshot-screen  (hotkey-overlay-title="screenshot screen")
- **Alt+Print** — screenshot-window  (hotkey-overlay-title="screenshot window")

### MEDIA CONTROLS
- **XF86AudioPlay** — spawn "playerctl" "play-pause"  (allow-when-locked=true)
- **XF86AudioNext** — spawn "playerctl" "next"  (allow-when-locked=true)
- **XF86AudioPrev** — spawn "playerctl" "previous"  (allow-when-locked=true)
- **XF86AudioStop** — spawn "playerctl" "stop"  (allow-when-locked=true)

### AUDIO CONTROLS WITH ADAPTIVE SOUNDS
- **XF86AudioMute** — spawn "sound-system" "mute"  (allow-when-locked=true)
- **XF86AudioRaiseVolume** — spawn "sound-system" "volume-up"  (allow-when-locked=true)
- **XF86AudioLowerVolume** — spawn "sound-system" "volume-down"  (allow-when-locked=true)
- **XF86AudioMicMute** — spawn "sound-system" "mic-mute"  (allow-when-locked=true)

````

```markdown
  - provide a small parser that reads your KDL file and regenerates this Markdown, or
```












############################################################################################################
```bash name=Keyhints_direct_kdl.sh
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
```

Short instructions and options
- Default KDL path is dots/.config/niri/snaps/10-wiri_keybinds.kdl relative to where you run the script. Override with:
  - KDL_PATH=/full/path/to/10-wiri_keybinds.kdl ./Keyhints_direct_kdl.sh
- Prefer a specific menu app:
  - CHOICE_CMD=rofi ./Keyhints_direct_kdl.sh
  - CHOICE_CMD=wofi ./Keyhints_direct_kdl.sh
- To bind it from Niri, copy the script to your scripts folder (e.g. ~/.config/wehttamsnaps/scripts/) and make it executable:
  - chmod +x ~/.config/wehttamsnaps/scripts/Keyhints_direct_kdl.sh
  - Then in KDL: Mod+H { spawn "~/.config/wehttamsnaps/scripts/Keyhints_direct_kdl.sh"; }

Would you like any of the following extras?
- Filter-by-group: show section headings first (Workspace / System / Window management) and then list binds only from chosen group (requires slightly more parsing to capture nearby comment headings). I can add that.
- Search-as-you-type: keep rofi/wofi flags tuned (size, theme) or pre-highlight matching segments.
- Copy only the key (lhs) or only the action: add sub-commands to control what gets copied.
Which extra (if any) would you like me to add?





############################################################################################################








############################################################################################################







############################################################################################################






