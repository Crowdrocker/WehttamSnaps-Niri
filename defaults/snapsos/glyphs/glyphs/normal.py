"""
Normal fullscreen drawing overlay.

The primary user-facing mode.  The user draws glyph strokes on a transparent
fullscreen window; strokes are matched against the dictionary, and a
collection of recognised glyphs can be submitted (typed / executed) via a
circle or underline gesture.
"""

import math
import os
import shlex
import subprocess
import tempfile

import cairo
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GLib

from .geometry import (
    MATCH_THRESHOLD,
    MIN_STROKE_POINTS,
    INK_WIDTH,
    rdp_simplify,
    normalize_stroke,
    match_stroke,
)
from .models import StrokeGlyph
from .input import is_pen_event


class NormalOverlay:
    """Fullscreen transparent overlay for drawing and recognising glyphs.

    The user draws strokes with a pen.  Each completed stroke is matched
    against the glyph dictionary.  Special gestures (circle, underline,
    strike-out, bracket glyphs) trigger actions like executing a session,
    deleting entries, or entering OCR text mode.
    """

    def __init__(self, config, glyphs):
        # --- Configuration state -------------------------------------------
        self.config = config
        self.glyphs = glyphs
        self.strokes = []
        self.current_stroke = []
        self.recognized = []
        self.mode = "type"
        self.mode_set = False
        self.in_text = False
        self.text_strokes = []
        self.carousel_scroll = 0.0
        self.carousel_progress = 0.0
        self._exec_pending = False
        self._enter_after = False

        # --- Window setup --------------------------------------------------
        self.win = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.win.set_title("glyphs")
        self.win.set_decorated(False)
        self.win.set_app_paintable(True)
        self.win.set_keep_above(True)
        self.win.fullscreen()

        screen = self.win.get_screen()
        rgba = screen.get_rgba_visual()
        if rgba:
            self.win.set_visual(rgba)

        # --- Drawing area --------------------------------------------------
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

        # Carousel animation timer (every 30 ms)
        GLib.timeout_add(30, self._carousel_tick)

    # ---- Lifecycle --------------------------------------------------------

    def run(self):
        """Enter the GTK main loop (blocks until the window closes)."""
        Gtk.main()

    # ---- Keyboard input ---------------------------------------------------

    def _on_key_press(self, widget, event):
        k = event.get_keyval()
        ctrl = event.state & Gdk.ModifierType.CONTROL_MASK

        if k == Gdk.KEY_Escape:
            Gtk.main_quit()
        elif ctrl and k == Gdk.KEY_z:
            self._undo()
            widget.queue_draw()
        elif k == Gdk.KEY_BackSpace and self.recognized:
            self.recognized.pop()
            widget.queue_draw()
        return True

    def _undo(self):
        if self.current_stroke:
            self.current_stroke = []
        elif self.text_strokes:
            self.text_strokes.pop()
        elif self.recognized:
            self.recognized.pop()

    # ---- Pen input --------------------------------------------------------

    def _on_button_press(self, widget, event):
        if event.button != 1:
            return False
        dev = event.get_source_device()
        if not is_pen_event(dev) and dev is not None:
            return False

        bx, by, bw, bh = self._undo_btn_rect(widget)
        if bx <= event.x <= bx + bw and by <= event.y <= by + bh:
            self._undo()
            widget.queue_draw()
            return True

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

        alloc = widget.get_allocated_width()
        epsilon = max(alloc, widget.get_allocated_height()) * 0.008
        simplified = rdp_simplify(stroke, epsilon)
        normalized = normalize_stroke(simplified)

        # 1. Enter glyph (circle+line)
        if not self.in_text and "__complete_enter__" in self.glyphs:
            g, d = match_stroke(
                normalized,
                {"__complete_enter__": self.glyphs["__complete_enter__"]})
            if g and d < MATCH_THRESHOLD:
                self._enter_after = True
                self._process_session()
                return True

        # 2. Plain circle gesture
        if not self.in_text and self._is_circle(stroke):
            self._process_session()
            return True

        # 3. Strike-out
        if self.recognized:
            si = self._strikeout_target(stroke, widget)
            if si >= 0:
                self.recognized.pop(si)
                widget.queue_draw()
                return True

        # 4. In-text bracket mode
        if self.in_text:
            glyph, dist = match_stroke(normalized, self.glyphs)
            if glyph and dist < MATCH_THRESHOLD and glyph["string"] == "__rbracket__":
                text = self._ocr_text_strokes()
                if text:
                    self.recognized.append(StrokeGlyph(list(stroke), text, "ocr"))
                self.in_text = False
                self.text_strokes = []
                widget.queue_draw()
                return True
            self.text_strokes.append(list(stroke))
            widget.queue_draw()
            return True

        # 5. Full glyph matching
        glyph, dist = match_stroke(normalized, self.glyphs)

        if glyph and dist < MATCH_THRESHOLD:
            if glyph["string"] == "__lbracket__":
                self.in_text = True
                self.text_strokes = []
                widget.queue_draw()
                return True
            elif glyph["string"] == "__rbracket__" and self.in_text:
                text = self._ocr_text_strokes()
                if text:
                    self.recognized.append(StrokeGlyph(list(stroke), text, "ocr"))
                self.in_text = False
                self.text_strokes = []
                widget.queue_draw()
                return True

            if not self.mode_set and len(self.recognized) == 0:
                if glyph["string"] == "__mode_exec__":
                    self.mode = "exec"
                    self.mode_set = True
                    widget.queue_draw()
                    return True
                if glyph["string"] == "__mode_term_exec__":
                    self.mode = "term-exec"
                    self.mode_set = True
                    widget.queue_draw()
                    return True

            self.recognized.append(
                StrokeGlyph(list(stroke), glyph["string"], glyph["name"]))
            widget.queue_draw()
            return True

        # 6. No match
        self.recognized.append(StrokeGlyph(list(stroke)))
        widget.queue_draw()
        return True

    # ---- Gesture helpers --------------------------------------------------

    def _is_circle(self, stroke):
        if len(stroke) < 20:
            return False
        xs = [p[0] for p in stroke]
        ys = [p[1] for p in stroke]
        w = max(xs) - min(xs)
        h = max(ys) - min(ys)
        if w < 30 or h < 30:
            return False
        if w / h > 2.0 or h / w > 2.0:
            return False

        epsilon = max(w, h) * 0.008
        simplified = rdp_simplify(stroke, epsilon)
        if len(simplified) < 5:
            return False

        angles = []
        for i in range(1, len(simplified) - 1):
            ax = simplified[i][0] - simplified[i - 1][0]
            ay = simplified[i][1] - simplified[i - 1][1]
            bx = simplified[i + 1][0] - simplified[i][0]
            by = simplified[i + 1][1] - simplified[i][1]
            dot = ax * bx + ay * by
            ma = math.hypot(ax, ay)
            mb = math.hypot(bx, by)
            if ma > 0 and mb > 0:
                cos_a = max(-1.0, min(1.0, dot / (ma * mb)))
                angles.append(math.degrees(math.acos(cos_a)))
        if not angles:
            return False
        sorted_a = sorted(angles)
        if sorted_a[len(sorted_a) // 2] > 30:
            return False

        total_length = sum(
            math.hypot(stroke[i][0] - stroke[i - 1][0],
                       stroke[i][1] - stroke[i - 1][1])
            for i in range(1, len(stroke)))
        early = stroke[:max(3, len(stroke) // 4)]
        min_early_dist = min(
            math.hypot(p[0] - stroke[-1][0], p[1] - stroke[-1][1])
            for p in early)
        if min_early_dist > total_length * 0.10:
            return False
        return True

    def _strikeout_target(self, stroke, widget):
        if len(stroke) < 5:
            return -1
        xs = [p[0] for p in stroke]
        ys = [p[1] for p in stroke]
        dx = max(xs) - min(xs)
        dy = max(ys) - min(ys)
        if dx < dy or dx < 40:
            return -1
        if dx > widget.get_allocated_width() * 0.35:
            return -1

        sbox = (min(xs), min(ys), max(xs), max(ys))
        for i, g in enumerate(self.recognized):
            gxs = [p[0] for p in g.stroke]
            gys = [p[1] for p in g.stroke]
            gbox = (min(gxs), min(gys), max(gxs), max(gys))
            if (sbox[0] < gbox[2] and sbox[2] > gbox[0]
                    and sbox[1] < gbox[3] and sbox[3] > gbox[1]):
                return i
        return -1

    # ---- Session execution ------------------------------------------------

    def _process_session(self):
        parts = [r.string for r in self.recognized if r.string is not None]
        text = " ".join(parts)
        if not text:
            Gtk.main_quit()
            return
        self._exec_text = text
        self.win.hide()
        self._exec_pending = True
        GLib.timeout_add(400, self._do_exec)

    def _do_exec(self):
        if self._exec_pending:
            self._exec_pending = False
            text = self._exec_text

            if self.mode == "exec":
                prefix = self.config.get("appearance", {}).get("exec_prefix", "")
                cmd = prefix + text if prefix else text
                subprocess.Popen(cmd, shell=True)
            elif self.mode == "term-exec":
                term_cmd = self.config.get("appearance", {}).get(
                    "term_exec", ["ghostty", "-e"])
                prefix = self.config.get("appearance", {}).get("exec_prefix", "")
                if prefix:
                    cmd = (prefix + " ".join(term_cmd) + " "
                           + shlex.quote(text))
                    subprocess.Popen(cmd, shell=True)
                else:
                    subprocess.Popen(term_cmd + [text])
            else:
                subprocess.Popen(["wtype", "--", text])

            if self._enter_after:
                subprocess.Popen(
                    ["bash", "-c", "sleep 1 && wtype -k Return"])

            Gtk.main_quit()
        return False

    # ---- OCR (text-bracket mode) ------------------------------------------

    def _ocr_text_strokes(self):
        if not self.text_strokes:
            return ""
        all_xs = [p[0] for s in self.text_strokes for p in s]
        all_ys = [p[1] for s in self.text_strokes for p in s]
        if not all_xs:
            return ""
        minx, maxx = min(all_xs), max(all_xs)
        miny, maxy = min(all_ys), max(all_ys)
        w, h = maxx - minx, maxy - miny
        if w < 2 or h < 2:
            return ""

        scale = 4
        margin = 24
        img_w = int(w * scale + margin * 2)
        img_h = int(h * scale + margin * 2)
        surface = cairo.ImageSurface(cairo.Format.ARGB32, img_w, img_h)
        cr = cairo.Context(surface)

        cr.set_source_rgba(1, 1, 1, 1)
        cr.paint()

        cr.set_source_rgba(0, 0, 0, 1)
        cr.set_line_width(8)
        cr.set_line_cap(cairo.LineCap.ROUND)
        cr.set_line_join(cairo.LineJoin.ROUND)
        for stroke in self.text_strokes:
            for i, p in enumerate(stroke):
                px = (p[0] - minx) * scale + margin
                py = (p[1] - miny) * scale + margin
                if i == 0:
                    cr.move_to(px, py)
                else:
                    cr.line_to(px, py)
            cr.stroke()

        tmp = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
        tmp_path = tmp.name
        tmp.close()
        surface.write_to_png(tmp_path)

        try:
            result = subprocess.run(
                ["tesseract", tmp_path, "stdout", "-l", "eng",
                 "--psm", "6", "--oem", "1"],
                capture_output=True, text=True, timeout=10,
            )
            text = result.stdout.strip()
        except (subprocess.SubprocessError, FileNotFoundError):
            text = ""
        finally:
            try:
                os.unlink(tmp_path)
            except OSError:
                pass

        return text

    # ---- UI drawing -------------------------------------------------------

    def _undo_btn_rect(self, widget):
        w = widget.get_allocated_width()
        return (w - 90, 8, 80, 28)

    def _on_draw(self, widget, cr):
        app = self.config.get("appearance", {})
        bg = app.get("background_rgba", [0.0, 0.0, 0.0, 0.06])

        cr.set_source_rgba(0, 0, 0, 0)
        cr.set_operator(cairo.Operator.SOURCE)
        cr.paint()
        cr.set_operator(cairo.Operator.OVER)

        cr.set_source_rgba(*bg)
        cr.paint()

        self._draw_mode_indicator(cr, widget)
        self._draw_undo_button(cr, widget)
        self._draw_strokes(cr, widget)
        self._draw_text_strokes(cr, widget)
        self._draw_glyph_labels(cr, widget)
        self._draw_carousel(cr, widget)

    def _draw_mode_indicator(self, cr, widget):
        if self.mode == "exec":
            cr.set_source_rgba(0.9, 0.5, 0.1, 0.9)
            text = "EXEC"
        elif self.mode == "term-exec":
            cr.set_source_rgba(0.6, 0.3, 0.9, 0.9)
            text = "TERM"
        else:
            cr.set_source_rgba(0.3, 0.8, 0.3, 0.9)
            text = "TYPE"

        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL,
                            cairo.FONT_WEIGHT_BOLD)
        cr.set_font_size(16)
        cr.move_to(16, 26)
        cr.show_text(text)

        if self.in_text:
            cr.set_source_rgba(0.3, 0.6, 1.0, 0.9)
            cr.set_font_size(20)
            cr.move_to(80, 26)
            cr.show_text(" [ … ]")

        if self.recognized:
            preview = " | ".join(
                r.display_text for r in self.recognized if r.display_text)
            cr.set_source_rgba(0.7, 0.7, 0.7, 0.7)
            cr.set_font_size(12)
            cr.move_to(16, 48)
            cr.show_text(preview)

    def _draw_undo_button(self, cr, widget):
        bx, by, bw, bh = self._undo_btn_rect(widget)
        cr.set_source_rgba(0.7, 0.7, 0.7, 0.3)
        cr.set_line_width(1)
        r = 4
        cr.move_to(bx + r, by)
        cr.line_to(bx + bw - r, by)
        cr.curve_to(bx + bw, by, bx + bw, by, bx + bw, by + r)
        cr.line_to(bx + bw, by + bh - r)
        cr.curve_to(bx + bw, by + bh, bx + bw, by + bh, bx + bw - r, by + bh)
        cr.line_to(bx + r, by + bh)
        cr.curve_to(bx, by + bh, bx, by + bh, bx, by + bh - r)
        cr.line_to(bx, by + r)
        cr.curve_to(bx, by, bx, by, bx + r, by)
        cr.close_path()
        cr.fill_preserve()
        cr.set_source_rgba(0.4, 0.4, 0.4, 0.6)
        cr.stroke()

        cr.set_source_rgba(0.85, 0.85, 0.85, 0.85)
        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL,
                            cairo.FONT_WEIGHT_BOLD)
        cr.set_font_size(12)
        ext = cr.text_extents("Undo")
        cr.move_to(bx + (bw - ext.width) / 2,
                   by + (bh + ext.height) / 2 - 2)
        cr.show_text("Undo")

    def _draw_strokes(self, cr, widget):
        ink = self.config.get("appearance", {}).get("ink_width", INK_WIDTH)
        for s in self.recognized:
            self._draw_polyline(cr, s.stroke, ink, 0.7, 0.9, 0.7, 0.9)
        if self.current_stroke:
            self._draw_polyline(cr, self.current_stroke, ink,
                                0.9, 0.9, 0.9, 0.9)

    def _draw_text_strokes(self, cr, widget):
        if not self.text_strokes:
            return
        ink = self.config.get("appearance", {}).get("ink_width", INK_WIDTH)
        for s in self.text_strokes:
            self._draw_polyline(cr, s, ink, 0.3, 0.6, 1.0, 0.9)

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

    # ---- Carousel ---------------------------------------------------------

    def _carousel_tick(self):
        carousel_cfg = self.config.get("appearance", {}).get("carousel", {})
        if carousel_cfg.get("enabled", True):
            self.carousel_scroll += 0.4
            self.carousel_progress += 0.012
            if self.carousel_progress > 1.2:
                self.carousel_progress = 0.0
            self.da.queue_draw()
        return True

    def _draw_carousel(self, cr, widget):
        carousel_cfg = self.config.get("appearance", {}).get("carousel", {})
        if not carousel_cfg.get("enabled", True):
            return
        if not self.glyphs:
            return
        h = carousel_cfg.get("height", 70)
        alloc_w = widget.get_allocated_width()
        alloc_h = widget.get_allocated_height()
        y0 = alloc_h - h

        cr.set_source_rgba(0.06, 0.06, 0.08, 0.75)
        cr.rectangle(0, y0, alloc_w, h)
        cr.fill()

        cell_w = 56
        total_w = len(self.glyphs) * cell_w
        scroll = self.carousel_scroll % total_w

        cr.save()
        cr.rectangle(0, y0, alloc_w, h)
        cr.clip()

        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL,
                            cairo.FONT_WEIGHT_NORMAL)
        cr.set_font_size(8)

        for i, glyph in enumerate(self.glyphs):
            x = i * cell_w - scroll
            if x + cell_w < 0 or x > alloc_w:
                continue

            templates = glyph.get("templates", [])
            if templates:
                pts = templates[0].get("pts", [])
                if len(pts) >= 2:
                    xs = [p[0] for p in pts]
                    ys = [p[1] for p in pts]
                    minx, maxx = min(xs), max(xs)
                    miny, maxy = min(ys), max(ys)
                    sw = maxx - minx
                    sh = maxy - miny
                    if sw > 0 or sh > 0:
                        scale = max(sw, sh)
                        area = h * 0.45
                        mx = (cell_w - area) / 2
                        my = 6

                        n_show = max(
                            2, int(self.carousel_progress * len(pts)))
                        if n_show > len(pts):
                            n_show = len(pts)

                        cr.set_source_rgba(0.5, 0.7, 1.0, 0.65)
                        cr.set_line_width(1.3)
                        cr.set_line_cap(cairo.LineCap.ROUND)
                        cr.set_line_join(cairo.LineJoin.ROUND)

                        for j in range(n_show):
                            p = pts[j]
                            px = (x + mx
                                  + (p[0] - minx) / scale * area)
                            py = (y0 + my
                                  + (maxy - p[1]) / scale * area)
                            if j == 0:
                                cr.move_to(px, py)
                            else:
                                cr.line_to(px, py)
                        cr.stroke()

            name = glyph.get("name", "?")
            cr.set_source_rgba(0.6, 0.6, 0.6, 0.65)
            ext = cr.text_extents(name)
            cr.move_to(x + (cell_w - ext.width) / 2, y0 + h - 4)
            cr.show_text(name)

        cr.restore()

    def _draw_glyph_labels(self, cr, widget):
        alloc = widget.get_allocated_width()
        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL,
                            cairo.FONT_WEIGHT_NORMAL)
        cr.set_font_size(14)

        for glyph in self.recognized:
            xs = [p[0] for p in glyph.stroke]
            ys = [p[1] for p in glyph.stroke]
            cx = (min(xs) + max(xs)) / 2
            bottom = max(ys)
            text = glyph.display_text

            if glyph.string is None:
                cr.set_source_rgba(0.9, 0.3, 0.3, 0.9)
            else:
                cr.set_source_rgba(0.85, 0.85, 0.85, 0.9)

            ext = cr.text_extents(text)
            label_x = cx - ext.width / 2
            label_y = bottom + 22

            cr.move_to(label_x, label_y)
            cr.show_text(text)
