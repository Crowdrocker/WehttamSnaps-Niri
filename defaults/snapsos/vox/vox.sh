#!/usr/bin/env bash
# vox.sh — wrapper that adds the vox directory to sys.path and
# runs the CLI.  Symlinked to /usr/local/bin/vox by install.sh.
exec /usr/bin/python3 -c "
import sys
from pathlib import Path
sys.path.insert(0, str(Path.home() / '.config' / 'sdgos' / 'vox'))
from vox.cli import main
main()
" "$@"
