#!/usr/bin/env python3
"""
Command-line entry point for the glyphs pen-input system.

Usage
-----
    glyphs-cli.py                  Normal mode — draw and match glyphs.
    glyphs-cli.py --record         Record new glyphs (grid-snapped).
    glyphs-cli.py --record-freehand Record new glyphs (freehand).
    glyphs-cli.py --dictionary      Browse the glyph dictionary.
"""

import argparse
from glyphs.app import GlyphApp


def main():
    parser = argparse.ArgumentParser(
        description="Pen-based glyph input system")
    parser.add_argument(
        "--record", action="store_true",
        help="Record new glyphs (grid-snapped)")
    parser.add_argument(
        "--record-freehand", action="store_true",
        help="Record new glyphs (freehand)")
    parser.add_argument(
        "--dictionary", action="store_true",
        help="Browse glyph dictionary")
    args = parser.parse_args()

    app = GlyphApp()
    if args.dictionary:
        app.run_dictionary()
    elif args.record_freehand:
        app.run_record_freehand()
    elif args.record:
        app.run_record()
    else:
        app.run_normal()


if __name__ == "__main__":
    main()
