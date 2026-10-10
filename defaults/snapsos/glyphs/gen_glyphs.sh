#!/usr/bin/env zsh
# [legacy] Regenerate all glyph files from gen_defaults.py
#
# The 70 built-in glyphs are now stored statically in glyphs-data/
# and this script is preserved for reference only.  It will overwrite
# (delete + regenerate) the contents of glyphs-data/.
set -e
GLYPH_DIR="/home/wehttamsnaps/ownCloud/SNAPS-OS/snapsos/glyphs/glyphs-data"
[ -d "$GLYPH_DIR" ] && rm -rf "$GLYPH_DIR"
exec python3 /home/wehttamsnaps/ownCloudSNAPS-OS/snapsos/glyphs/gen_defaults.py
