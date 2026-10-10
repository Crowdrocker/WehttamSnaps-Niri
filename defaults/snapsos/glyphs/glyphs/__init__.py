"""
glyphs — modular pen-based glyph input system.

Exposes all public symbols from the sub-modules so callers can do
``from glyphs import X`` for everything that was originally top-level
in the monolithic *glyphs.py*.
"""

# Config (paths + load/save)
from .config import (
    CONFIG_DIR,
    CONFIG_FILE,
    GLYPH_DIR,
    default_config,
    load_config,
    save_config,
)

# Glyph persistence
from .storage import load_glyphs, save_glyph

# Geometry / recognition pipeline
from .geometry import (
    N_RESAMPLE,
    MATCH_THRESHOLD,
    MIN_STROKE_POINTS,
    INK_WIDTH,
    rdp_simplify,
    resample_points,
    normalize_stroke,
    rotate_points,
    stroke_distance,
    match_stroke,
    compute_write_area,
)

# Data models
from .models import StrokeGlyph

# Grid constants (used by RecordOverlay)
from .grid import (
    GRID_PTS,
    GRID_ANCHORS,
    GRID_ADJ,
    GRID_BOUNDS,
)

# Widgets
from .widgets import GlyphCard

# Window classes
from .normal import NormalOverlay
from .record_freehand import FreehandRecordOverlay
from .record_grid import RecordOverlay
from .dictionary import DictionaryWindow

# Application orchestrator
from .app import GlyphApp
