"""
Reusable GTK widgets for the glyphs UI.
"""

import math

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, GLib, cairo


# ---------------------------------------------------------------------------
# Glyph card (used in the dictionary window)
# ---------------------------------------------------------------------------

class GlyphCard(Gtk.EventBox):
    """A card widget that displays a single glyph's name, output string,
    and an animated stroke preview.

    The stroke is repeatedly drawn from start to finish in a loop,
    with a red dot following the "drawing head".
    """

    def __init__(self, glyph):
        super().__init__()
        self.glyph = glyph
        self.templates = glyph.get("templates", [])
        self._progress = 0.0  # 0..1.2, drives the animation

        # --- Outer frame & vertical layout ---------------------------------
        frame = Gtk.Frame()
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        box.set_margin_start(4)
        box.set_margin_end(4)
        box.set_margin_top(4)
        box.set_margin_bottom(4)

        # Glyph name (bold)
        nm = Gtk.Label(label=glyph.get("name", "?"))
        nm.set_markup(f"<b>{GLib.markup_escape_text(glyph.get('name', '?'))}</b>")
        box.add(nm)

        # Output string (small)
        st = Gtk.Label(label=glyph.get("string", ""))
        st.set_markup(f"<small>{GLib.markup_escape_text(glyph.get('string', ''))}</small>")
        box.add(st)

        # Drawing area for the animated stroke preview
        self._da = Gtk.DrawingArea()
        self._da.set_size_request(100, 80)
        self._da.connect("draw", self._on_draw)
        box.add(self._da)

        frame.add(box)
        self.add(frame)

    # ---- Animation tick ---------------------------------------------------

    def tick(self):
        """Advance the animation progress by one frame."""
        self._progress += 0.008
        if self._progress > 1.2:
            self._progress = 0.0
        self._da.queue_draw()

    # ---- Drawing ----------------------------------------------------------

    def _on_draw(self, widget, cr):
        alloc = widget.get_allocated_width(), widget.get_allocated_height()
        # Dark background
        cr.set_source_rgba(0.08, 0.08, 0.08, 1)
        cr.paint()

        if not self.templates:
            return

        pts = self.templates[0].get("pts", [])
        if len(pts) < 2:
            return

        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        minx, maxx = min(xs), max(xs)
        miny, maxy = min(ys), max(ys)
        sw = maxx - minx
        sh = maxy - miny
        if sw == 0 and sh == 0:
            return
        scale = max(sw, sh)

        margin = 12
        draw_w = alloc[0] - margin * 2
        draw_h = alloc[1] - margin * 2
        draw_scale = min(draw_w, draw_h)

        n = max(2, int(self._progress * len(pts)))
        if n > len(pts):
            n = len(pts)

        # Draw the stroke up to the current progress point
        cr.set_source_rgba(0.5, 0.7, 1.0, 0.85)
        cr.set_line_width(2)
        cr.set_line_cap(cairo.LineCap.ROUND)
        cr.set_line_join(cairo.LineJoin.ROUND)

        for i in range(n):
            px = margin + (pts[i][0] - minx) / scale * draw_scale
            py = margin + (maxy - pts[i][1]) / scale * draw_scale
            if i == 0:
                cr.move_to(px, py)
            else:
                cr.line_to(px, py)
        cr.stroke()

        # Red dot at the current drawing head
        if n > 0 and n <= len(pts):
            px = margin + (pts[n - 1][0] - minx) / scale * draw_scale
            py = margin + (maxy - pts[n - 1][1]) / scale * draw_scale
            cr.set_source_rgba(1.0, 0.3, 0.3, 0.9)
            cr.arc(px, py, 3.5, 0, 2 * math.pi)
            cr.fill()
