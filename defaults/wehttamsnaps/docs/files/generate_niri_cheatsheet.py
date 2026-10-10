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