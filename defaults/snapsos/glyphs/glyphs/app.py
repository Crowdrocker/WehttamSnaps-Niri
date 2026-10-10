"""
Application orchestrator — ties configuration, glyph data and window classes
together.
"""

from .config import load_config
from .storage import load_glyphs
from .normal import NormalOverlay
from .record_freehand import FreehandRecordOverlay
from .record_grid import RecordOverlay
from .dictionary import DictionaryWindow


class GlyphApp:
    """Top-level application orchestrator.

    Loads configuration and glyph data once, then delegates to the
    appropriate window class based on the mode selected on the CLI.
    """

    def __init__(self):
        self.config = load_config()
        self.glyphs = load_glyphs()

    def run_normal(self):
        """Launch the main fullscreen transparent overlay for glyph drawing."""
        win = NormalOverlay(self.config, self.glyphs)
        win.run()

    def run_record(self):
        """Launch the grid-snapped recording overlay."""
        win = RecordOverlay(self.config, self.glyphs)
        win.run()

    def run_record_freehand(self):
        """Launch the freehand recording overlay."""
        win = FreehandRecordOverlay(self.config, self.glyphs)
        win.run()

    def run_dictionary(self):
        """Launch the dictionary browser window."""
        win = DictionaryWindow(self.config, self.glyphs)
        win.run()
