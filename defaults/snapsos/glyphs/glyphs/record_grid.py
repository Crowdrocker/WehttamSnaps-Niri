"""
Grid-snapped recording overlay.

Divides the screen into a grid of cells, each showing the anchor-point
graph.  The user draws through the grid nodes; the stroke is snapped
to the nearest nodes and routed via BFS through the graph.  When all
cells are filled a dialog prompts for the glyph metadata.
"""

import math

import cairo
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk

from .geometry import (
    MIN_STROKE_POINTS,
    INK_WIDTH,
    rdp_simplify,
    normalize_stroke,
)
from .storage import save_glyph
from .grid import GRID_PTS, GRID_ANCHORS, GRID_ADJ, GRID_BOUNDS, _bfs_path
from .input import is_pen_event


class RecordOverlay:
    """Fullscreen grid overlay for recording new glyphs with grid-snapped
    strokes.

    The user draws on a grid of labelled anchor points.  The stroke is
    snapped to the nearest grid nodes and routed through the grid graph
    via BFS.  When all cells are filled a dialog prompts for the glyph
    metadata.
    """

    def __init__(self, config, glyphs):
        self.config = config
        self.glyphs = glyphs
        self.sections = config.get("recording", {}).get("sections", 4)
        self._grid = [[] for _ in range(self.sections)]
        self.current_stroke = []
        self.current_cell = -1
        self._filled = [False] * self.sections
        self._calc_grid()

        self.win = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.win.set_title("glyphs — record")
        self.win.set_decorated(False)
        self.win.set_app_paintable(True)
        self.win.set_keep_above(True)
        self.win.fullscreen()

        screen = self.win.get_screen()
        rgba = screen.get_rgba_visual()
        if rgba:
            self.win.set_visual(rgba)

        self.da = Gtk.DrawingArea()
        self.da.set_events(
            Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.BUTTON_RELEASE_MASK
            | Gdk.EventMask.POINTER_MOTION_MASK
        )
        self.da.connect("draw", self._on_draw)
        self.da.connect("button-press-event", self._on_button_press)
        self.da.connect("button-release-event", self._on_button_release)
        self.da.connect("motion-notify-event", self._on_motion)
        self.win.add(self.da)

        self.win.connect("key-press-event", self._on_key_press)
        self.win.connect("destroy", lambda _: Gtk.main_quit())
        self.win.show_all()

    def _calc_grid(self):
        n = self.sections
        best_r, best_c = 1, n
        for r in range(1, int(math.sqrt(n)) + 2):
            if n % r == 0:
                c = n // r
                if abs(c - r) < abs(best_c - best_r):
                    best_r, best_c = r, c
        self.grid_rows = best_r
        self.grid_cols = best_c

    def run(self):
        Gtk.main()

    def _on_key_press(self, widget, event):
        if event.get_keyval() == Gdk.KEY_Escape:
            Gtk.main_quit()
        return True

    # ---- Coordinate transforms --------------------------------------------

    def _cell_transform(self, idx, cw, ch):
        row, col = idx // self.grid_cols, idx % self.grid_cols
        cx, cy = col * cw, row * ch
        m = 0.12
        gminx, gmaxx, gminy, gmaxy = GRID_BOUNDS
        gw, gh = gmaxx - gminx, gmaxy - gminy
        aw = cw * (1 - 2 * m)
        ah = ch * (1 - 2 * m)
        sc = min(aw / gw, ah / gh)
        ox = cx + cw * m + (aw - gw * sc) / 2
        oy = cy + ch * m + (ah - gh * sc) / 2
        return ox, oy, sc

    def _screen_to_grid(self, sx, sy, ox, oy, sc):
        gx = (sx - ox) / sc + GRID_BOUNDS[0]
        gy = GRID_BOUNDS[3] - (sy - oy) / sc
        return gx, gy

    def _grid_to_screen(self, gx, gy, ox, oy, sc):
        sx = ox + (gx - GRID_BOUNDS[0]) * sc
        sy = oy + (GRID_BOUNDS[3] - gy) * sc
        return sx, sy

    # ---- Snap & route -----------------------------------------------------

    def _snap_and_route(self, stroke, cw, ch):
        ox, oy, sc = self._cell_transform(self.current_cell, cw, ch)
        snapped = []
        for sx, sy in stroke:
            gx, gy = self._screen_to_grid(sx, sy, ox, oy, sc)
            best = min(
                GRID_PTS.keys(),
                key=lambda k: math.hypot(gx - GRID_PTS[k][0],
                                         gy - GRID_PTS[k][1]))
            snapped.append(best)

        cleaned = [snapped[0]]
        for s in snapped[1:]:
            if s != cleaned[-1]:
                cleaned.append(s)

        routed = [cleaned[0]]
        for i in range(1, len(cleaned)):
            p, q = cleaned[i - 1], cleaned[i]
            if q in GRID_ADJ[p]:
                routed.append(q)
            else:
                path = _bfs_path(p, q)
                if path:
                    routed.extend(path[1:])
                else:
                    return None
        return routed

    # ---- Pen input --------------------------------------------------------

    def _on_button_press(self, widget, event):
        if event.button != 1:
            return False
        dev = event.get_source_device()
        if not is_pen_event(dev) and dev is not None:
            return False

        alloc = widget.get_allocated_width(), widget.get_allocated_height()
        cw = alloc[0] / self.grid_cols
        ch = alloc[1] / self.grid_rows
        col = int(event.x / cw)
        row = int(event.y / ch)
        idx = row * self.grid_cols + col
        if idx >= self.sections:
            return False
        self.current_cell = idx
        self.current_stroke = [(event.x, event.y)]
        widget.queue_draw()
        return True

    def _on_motion(self, widget, event):
        if not self.current_stroke:
            return False
        self.current_stroke.append((event.x, event.y))
        widget.queue_draw()
        return True

    def _on_button_release(self, widget, event):
        if not self.current_stroke or event.button != 1:
            return False
        stroke = self.current_stroke
        self.current_stroke = []

        if len(stroke) < MIN_STROKE_POINTS:
            widget.queue_draw()
            return True

        alloc = (widget.get_allocated_width(),
                 widget.get_allocated_height())
        cw, ch = alloc[0] / self.grid_cols, alloc[1] / self.grid_rows
        eps = max(alloc) * 0.008
        simplified = rdp_simplify(stroke, eps)
        routed = self._snap_and_route(simplified, cw, ch)

        if routed is not None:
            self._grid[self.current_cell] = list(routed)
            self._filled[self.current_cell] = True

        if all(self._filled):
            self._prompt_mapping()

        widget.queue_draw()
        return True

    # ---- Mapping dialog ---------------------------------------------------

    def _prompt_mapping(self):
        dialog = Gtk.Dialog(
            title="Record glyph",
            transient_for=self.win,
            flags=0,
        )
        dialog.add_button("Save", Gtk.ResponseType.OK)
        dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
        dialog.set_default_size(350, 180)

        content = dialog.get_content_area()
        content.set_spacing(8)

        hdr = Gtk.Label(label="<b>New glyph</b>")
        hdr.set_use_markup(True)
        content.add(hdr)

        nl = Gtk.Label(label="Name (for dictionary):")
        nl.set_xalign(0)
        ne = Gtk.Entry()
        content.add(nl)
        content.add(ne)

        sl = Gtk.Label(label="Output string:")
        sl.set_xalign(0)
        se = Gtk.Entry()
        content.add(sl)
        content.add(se)

        hl = Gtk.Label(
            label="<small>Use <b>__mode_exec__</b> to switch to exec mode,\n"
                  "<b>__mode_term_exec__</b> to run in a terminal,\n"
                  "<b>__complete_enter__</b> to send Enter after output.</small>")
        hl.set_use_markup(True)
        hl.set_xalign(0)
        content.add(hl)

        dialog.show_all()
        resp = dialog.run()
        name = ne.get_text().strip()
        string = se.get_text().strip()
        dialog.destroy()

        if resp == Gtk.ResponseType.OK and name and string:
            templates = []
            for labels in self._grid:
                if labels:
                    coords = [GRID_PTS[k] for k in labels]
                    normalized = normalize_stroke(coords)
                    templates.append(
                        {"pts": [(x, y) for x, y in normalized]})
            glyph = {"name": name, "string": string, "templates": templates}
            save_glyph(glyph)
            self.glyphs.append(glyph)

        self._grid = [[] for _ in range(self.sections)]
        self._filled = [False] * self.sections
        self.current_cell = -1
        self.da.queue_draw()

    # ---- Drawing ----------------------------------------------------------

    def _on_draw(self, widget, cr):
        app = self.config.get("appearance", {})
        bg = app.get("background_rgba", [0.0, 0.0, 0.0, 0.06])
        ink_w = app.get("ink_width", INK_WIDTH)

        cr.set_source_rgba(0, 0, 0, 0)
        cr.set_operator(cairo.Operator.SOURCE)
        cr.paint()
        cr.set_operator(cairo.Operator.OVER)

        cr.set_source_rgba(*bg)
        cr.paint()

        alloc = widget.get_allocated_width(), widget.get_allocated_height()
        cw, ch = alloc[0] / self.grid_cols, alloc[1] / self.grid_rows

        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL,
                            cairo.FONT_WEIGHT_BOLD)
        cr.set_font_size(18)

        for i in range(self.sections):
            row, col = i // self.grid_cols, i % self.grid_cols
            x, y = col * cw, row * ch

            cr.set_source_rgba(0.3, 0.3, 0.3, 0.5)
            cr.set_line_width(1)
            cr.rectangle(x, y, cw, ch)
            cr.stroke()

            if self._filled[i]:
                cr.set_source_rgba(0.3, 0.8, 0.3, 0.2)
                cr.rectangle(x + 2, y + 2, cw - 4, ch - 4)
                cr.fill()

            cr.set_source_rgba(0.6, 0.6, 0.6, 0.6)
            cr.move_to(x + 12, y + 28)
            cr.show_text(str(i + 1))

            self._draw_grid(cr, i, cw, ch)

            ox, oy, sc = self._cell_transform(i, cw, ch)
            for labels in self._grid[i]:
                screen_pts = [
                    (ox + (GRID_PTS[k][0] - GRID_BOUNDS[0]) * sc,
                     oy + (GRID_BOUNDS[3] - GRID_PTS[k][1]) * sc)
                    for k in labels]
                self._draw_polyline(cr, screen_pts, ink_w,
                                    0.3, 0.8, 0.3, 0.9)

        if self.current_stroke and self.current_cell >= 0:
            self._draw_polyline(cr, self.current_stroke, ink_w,
                                0.9, 0.9, 0.9, 0.9)

    def _draw_grid(self, cr, idx, cw, ch):
        ox, oy, sc = self._cell_transform(idx, cw, ch)

        for k, p in GRID_PTS.items():
            sx = ox + (p[0] - GRID_BOUNDS[0]) * sc
            sy = oy + (GRID_BOUNDS[3] - p[1]) * sc

            if k in GRID_ANCHORS:
                cr.set_source_rgba(0.5, 0.7, 1.0, 0.7)
                cr.arc(sx, sy, 4, 0, 2 * math.pi)
                cr.fill()
                cr.set_source_rgba(0.7, 0.9, 1.0, 0.9)
                cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL,
                                    cairo.FONT_WEIGHT_BOLD)
                cr.set_font_size(10)
                cr.move_to(sx + 5, sy - 3)
                cr.show_text(k)
            else:
                cr.set_source_rgba(0.3, 0.4, 0.6, 0.35)
                cr.arc(sx, sy, 2, 0, 2 * math.pi)
                cr.fill()

        cr.set_source_rgba(0.2, 0.25, 0.35, 0.25)
        cr.set_line_width(0.5)
        for k, adjs in GRID_ADJ.items():
            for o in adjs:
                if k >= o:
                    continue
                x1 = ox + (GRID_PTS[k][0] - GRID_BOUNDS[0]) * sc
                y1 = oy + (GRID_BOUNDS[3] - GRID_PTS[k][1]) * sc
                x2 = ox + (GRID_PTS[o][0] - GRID_BOUNDS[0]) * sc
                y2 = oy + (GRID_BOUNDS[3] - GRID_PTS[o][1]) * sc
                cr.move_to(x1, y1)
                cr.line_to(x2, y2)
                cr.stroke()

    @staticmethod
    def _draw_polyline(cr, pts, width, r, g, b, a):
        if len(pts) < 2:
            return
        cr.set_source_rgba(r, g, b, a)
        cr.set_line_width(width)
        cr.set_line_cap(cairo.LineCap.ROUND)
        cr.set_line_join(cairo.LineJoin.ROUND)
        cr.move_to(pts[0][0], pts[0][1])
        for p in pts[1:]:
            cr.line_to(p[0], p[1])
        cr.stroke()
