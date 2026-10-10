"""
Glyph dictionary browser window.

Shows all known glyphs in a scrollable grid of animated cards.
"""

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, GLib

from .widgets import GlyphCard


class DictionaryWindow:
    """Scrollable window displaying all known glyphs as animated cards."""

    def __init__(self, config, glyphs):
        self.config = config
        self.glyphs = glyphs
        self._anim_data = []

        self.win = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.win.set_title("glyphs — dictionary")
        self.win.set_default_size(900, 600)

        grid_cols = config.get("appearance", {}).get(
            "dictionary_grid_cols", 4)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        self.flow = Gtk.FlowBox()
        self.flow.set_max_children_per_line(grid_cols)
        self.flow.set_min_children_per_line(grid_cols)
        self.flow.set_selection_mode(Gtk.SelectionMode.NONE)
        self.flow.set_homogeneous(True)

        if not glyphs:
            lbl = Gtk.Label(
                label="No glyphs configured.\n"
                      "Run 'glyphs --record' to add some.")
            lbl.set_margin_top(40)
            self.flow.add(lbl)
        else:
            for glyph in sorted(glyphs, key=lambda g: g.get("name", "")):
                card = GlyphCard(glyph)
                self._anim_data.append(card)
                self.flow.add(card)

        scrolled.add(self.flow)
        self.win.add(scrolled)

        GLib.timeout_add(16, self._anim_tick)

        self.win.connect("destroy", lambda _: Gtk.main_quit())

    def _anim_tick(self):
        for card in self._anim_data:
            card.tick()
        return True

    def run(self):
        self.win.show_all()
        Gtk.main()
