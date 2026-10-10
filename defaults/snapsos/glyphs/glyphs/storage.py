"""
Glyph persistence — loads/saves individual glyph JSON files from *GLYPH_DIR*.
"""

import json
import os
from .config import GLYPH_DIR


def load_glyphs():
    """
    Walk *GLYPH_DIR* recursively and load every ``.json`` file as a glyph.

    Returns a list of glyph dicts, each validated to have the keys
    ``name``, ``string`` and ``templates``.  Files that are unreadable or
    malformed are silently skipped.
    """
    glyphs = []
    if not os.path.isdir(GLYPH_DIR):
        return glyphs
    for root, _dirs, files in os.walk(GLYPH_DIR):
        for fname in sorted(files):
            if not fname.endswith(".json"):
                continue
            path = os.path.join(root, fname)
            try:
                with open(path) as f:
                    glyph = json.load(f)
                if "name" in glyph and "string" in glyph and "templates" in glyph:
                    glyphs.append(glyph)
            except (json.JSONDecodeError, OSError):
                pass  # skip unreadable / malformed files
    return glyphs


def save_glyph(glyph):
    """
    Persist a glyph dict as ``{name}.json`` inside *GLYPH_DIR*.

    The glyph *must* contain a ``name`` key; the value is used as the
    filename (with ``.json`` appended).
    """
    os.makedirs(GLYPH_DIR, exist_ok=True)
    path = os.path.join(GLYPH_DIR, f"{glyph['name']}.json")
    with open(path, "w") as f:
        json.dump(glyph, f, indent=2)
