#!/usr/bin/env python3
import argparse
import json
import math
import os
import shlex
import subprocess
import sys

import tempfile

import cairo
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk, Gdk, GLib

CONFIG_DIR = os.path.expanduser("~/.config/snapsos/glyphs")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")
GLYPH_DIR = os.path.join(CONFIG_DIR, "glyphs")
N_RESAMPLE = 32
MATCH_THRESHOLD = 0.12
MIN_STROKE_POINTS = 5
INK_WIDTH = 3.0


def load_config():
    if not os.path.exists(CONFIG_FILE):
        return default_config()
    with open(CONFIG_FILE) as f:
        return json.load(f)


def default_config():
    return {
        "recording": {"sections": 4},
        "appearance": {
            "ink_width": 3.0,
            "background_rgba": [0.0, 0.0, 0.0, 0.06],
            "dictionary_grid_cols": 8,
            "carousel": {"enabled": True, "height": 70},
            "exec_prefix": "",
            "term_exec": ["ghostty", "-e"],
        },
    }


def save_config(config):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)


def load_glyphs():
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
                pass
    return glyphs


def save_glyph(glyph):
    os.makedirs(GLYPH_DIR, exist_ok=True)
    path = os.path.join(GLYPH_DIR, f"{glyph['name']}.json")
    with open(path, "w") as f:
        json.dump(glyph, f, indent=2)


def rdp_simplify(points, epsilon):
    if len(points) <= 2:
        return points
    start, end = points[0], points[-1]
    max_dist = 0.0
    max_idx = 0
    for i in range(1, len(points) - 1):
        d = _perp_dist(points[i], start, end)
        if d > max_dist:
            max_dist = d
            max_idx = i
    if max_dist > epsilon:
        left = rdp_simplify(points[: max_idx + 1], epsilon)
        right = rdp_simplify(points[max_idx:], epsilon)
        return left[:-1] + right
    return [points[0], points[-1]]


def _perp_dist(p, a, b):
    if a[0] == b[0] and a[1] == b[1]:
        return math.hypot(p[0] - a[0], p[1] - a[1])
    dx = b[0] - a[0]
    dy = b[1] - a[1]
    t = ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    return math.hypot(p[0] - (a[0] + t * dx), p[1] - (a[1] + t * dy))


def resample_points(points, n):
    if len(points) <= 1:
        return list(points) * n
    dists = [0.0]
    for i in range(1, len(points)):
        dists.append(
            dists[-1]
            + math.hypot(points[i][0] - points[i - 1][0], points[i][1] - points[i - 1][1])
        )
    total = dists[-1]
    if total == 0:
        return [points[0]] * n
    result = []
    for i in range(n):
        target = i * total / (n - 1)
        j = 0
        while j < len(dists) - 1 and dists[j + 1] < target:
            j += 1
        if j >= len(dists) - 1:
            result.append(points[-1])
        else:
            t = (target - dists[j]) / (dists[j + 1] - dists[j]) if dists[j + 1] > dists[j] else 0
            result.append((
                points[j][0] + t * (points[j + 1][0] - points[j][0]),
                points[j][1] + t * (points[j + 1][1] - points[j][1]),
            ))
    return result


def normalize_stroke(points, n=N_RESAMPLE):
    if len(points) < 2:
        return list(points)
    resampled = resample_points(points, n)
    xs = [p[0] for p in resampled]
    ys = [p[1] for p in resampled]
    minx, maxx = min(xs), max(xs)
    miny, maxy = min(ys), max(ys)
    w, h = maxx - minx, maxy - miny
    if w == 0 and h == 0:
        return [(0.0, 0.0)] * n
    scale = max(w, h)
    scaled = [((x - minx) / scale, (y - miny) / scale) for x, y in resampled]
    cx = sum(p[0] for p in scaled) / n
    cy = sum(p[1] for p in scaled) / n
    return [(x - cx, y - cy) for x, y in scaled]


def rotate_points(points, angle):
    c, s = math.cos(angle), math.sin(angle)
    return [(x * c - y * s, x * s + y * c) for x, y in points]


def stroke_distance(a, b):
    n = min(len(a), len(b))
    if n < 2:
        return float("inf")
    fa = resample_points(a, n)
    fb = resample_points(b, n)
    best = float("inf")
    for angle in [i * math.pi / 12 for i in range(12)]:
        ra = rotate_points(fa, angle)
        for shift in range(n):
            d = sum(
                math.hypot(ra[(i + shift) % n][0] - fb[i][0],
                           ra[(i + shift) % n][1] - fb[i][1])
                for i in range(n)
            ) / n
            if d < best:
                best = d
    return best


def match_stroke(normalized, glyphs):
    if not glyphs or len(normalized) < 2:
        return None, float("inf")
    # Flip Y: user draws with screen-Y-down (top=-Y), templates stored with Y-up (top=+Y)
    normalized = [(x, -y) for x, y in normalized]
    best_dist = float("inf")
    best_glyph = None
    for glyph in glyphs:
        for template in glyph.get("templates", []):
            tpts = [(p[0], p[1]) for p in template["pts"]]
            d = stroke_distance(normalized, tpts)
            if d < best_dist:
                best_dist = d
                best_glyph = glyph
    return best_glyph, best_dist


def compute_write_area(recognized, strokes):
    all_ys = []
    all_xs = []
    for r in recognized:
        for p in r.stroke:
            all_xs.append(p[0])
            all_ys.append(p[1])
    for s in strokes:
        for p in s:
            all_xs.append(p[0])
            all_ys.append(p[1])
    if not all_xs:
        return None
    return min(all_xs), max(all_xs), min(all_ys), max(all_ys)


def is_pen_event(device):
    if device is None:
        return False
    src = device.get_source()
    return src in (Gdk.InputSource.PEN, Gdk.InputSource.ERASER, Gdk.InputSource.TOUCHSCREEN)


class StrokeGlyph:
    def __init__(self, stroke, string=None, name=None):
        self.stroke = stroke
        self.string = string
        self.name = name

    @property
    def display_text(self):
        return self.string if self.string else "?"


class GlyphApp:
    def __init__(self):
        self.config = load_config()
        self.glyphs = load_glyphs()

    def run_normal(self):
        win = NormalOverlay(self.config, self.glyphs)
        win.run()

    def run_record(self):
        win = RecordOverlay(self.config, self.glyphs)
        win.run()

    def run_record_freehand(self):
        win = FreehandRecordOverlay(self.config, self.glyphs)
        win.run()

    def run_dictionary(self):
        win = DictionaryWindow(self.config, self.glyphs)
        win.run()


class NormalOverlay:
    def __init__(self, config, glyphs):
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

        self.da = Gtk.DrawingArea()
        self.da.set_events(
            Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.BUTTON_RELEASE_MASK
            | Gdk.EventMask.POINTER_MOTION_MASK
        )
        self.da.connect("draw", self.on_draw)
        self.da.connect("button-press-event", self.on_button_press)
        self.da.connect("button-release-event", self.on_button_release)
        self.da.connect("motion-notify-event", self.on_motion)
        self.win.add(self.da)

        self.win.connect("key-press-event", self.on_key_press)
        self.win.connect("destroy", lambda _: Gtk.main_quit())
        self.win.show_all()

        GLib.timeout_add(30, self._carousel_tick)

    def run(self):
        Gtk.main()

    def on_key_press(self, widget, event):
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

    def on_button_press(self, widget, event):
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

    def on_motion(self, widget, event):
        if not self.current_stroke:
            return False
        self.current_stroke.append((event.x, event.y))
        widget.queue_draw()
        return True

    def on_button_release(self, widget, event):
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

        # 1. Enter glyph (circle+line) — check before _is_circle to avoid interception
        if not self.in_text and "__complete_enter__" in self.glyphs:
            g, d = match_stroke(normalized, {"__complete_enter__": self.glyphs["__complete_enter__"]})
            if g and d < MATCH_THRESHOLD:
                self._enter_after = True
                self._process_session()
                return True

        # 2. Plain circle check — shape-based, rejects angular strokes
        if not self.in_text and self._is_circle(stroke):
            self._process_session()
            return True

        # 3. Strike-out — horizontal line overlapping a recognised glyph
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

        # 5. Full glyph matching — modes, brackets, and regular glyphs
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

            self.recognized.append(StrokeGlyph(list(stroke), glyph["string"], glyph["name"]))
            widget.queue_draw()
            return True

        # 6. Unknown — add as unrecognised
        self.recognized.append(StrokeGlyph(list(stroke)))
        widget.queue_draw()
        return True

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
            ax = simplified[i][0] - simplified[i-1][0]
            ay = simplified[i][1] - simplified[i-1][1]
            bx = simplified[i+1][0] - simplified[i][0]
            by = simplified[i+1][1] - simplified[i][1]
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
        total_length = sum(math.hypot(stroke[i][0] - stroke[i-1][0], stroke[i][1] - stroke[i-1][1])
                          for i in range(1, len(stroke)))
        early = stroke[:max(3, len(stroke)//4)]
        min_early_dist = min(math.hypot(p[0] - stroke[-1][0], p[1] - stroke[-1][1]) for p in early)
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
        for i, glyph in enumerate(self.recognized):
            gxs = [p[0] for p in glyph.stroke]
            gys = [p[1] for p in glyph.stroke]
            gbox = (min(gxs), min(gys), max(gxs), max(gys))
            if sbox[0] < gbox[2] and sbox[2] > gbox[0] and sbox[1] < gbox[3] and sbox[3] > gbox[1]:
                return i
        return -1

    def _undo_btn_rect(self, widget):
        w = widget.get_allocated_width()
        return (w - 90, 8, 80, 28)

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
                term_cmd = self.config.get("appearance", {}).get("term_exec", ["ghostty", "-e"])
                prefix = self.config.get("appearance", {}).get("exec_prefix", "")
                if prefix:
                    cmd = prefix + " ".join(term_cmd) + " " + shlex.quote(text)
                    subprocess.Popen(cmd, shell=True)
                else:
                    subprocess.Popen(term_cmd + [text])
            else:
                subprocess.Popen(["wtype", "--", text])
            if self._enter_after:
                subprocess.Popen(["bash", "-c", "sleep 1 && wtype -k Return"])
            Gtk.main_quit()
        return False

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
                ["tesseract", tmp_path, "stdout", "-l", "eng", "--psm", "6", "--oem", "1"],
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

    def on_draw(self, widget, cr):
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

        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
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
                r.display_text for r in self.recognized if r.display_text
            )
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
        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
        cr.set_font_size(12)
        ext = cr.text_extents("Undo")
        cr.move_to(bx + (bw - ext.width) / 2, by + (bh + ext.height) / 2 - 2)
        cr.show_text("Undo")

    def _draw_strokes(self, cr, widget):
        ink = self.config.get("appearance", {}).get("ink_width", INK_WIDTH)
        for s in self.recognized:
            self._draw_polyline(cr, s.stroke, ink, 0.7, 0.9, 0.7, 0.9)
        if self.current_stroke:
            self._draw_polyline(cr, self.current_stroke, ink, 0.9, 0.9, 0.9, 0.9)

    def _draw_text_strokes(self, cr, widget):
        if not self.text_strokes:
            return
        ink = self.config.get("appearance", {}).get("ink_width", INK_WIDTH)
        for s in self.text_strokes:
            self._draw_polyline(cr, s, ink, 0.3, 0.6, 1.0, 0.9)

    def _draw_polyline(self, cr, pts, width, r, g, b, a):
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

        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)
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

                        n_show = max(2, int(self.carousel_progress * len(pts)))
                        if n_show > len(pts):
                            n_show = len(pts)

                        cr.set_source_rgba(0.5, 0.7, 1.0, 0.65)
                        cr.set_line_width(1.3)
                        cr.set_line_cap(cairo.LineCap.ROUND)
                        cr.set_line_join(cairo.LineJoin.ROUND)

                        for j in range(n_show):
                            p = pts[j]
                            px = x + mx + (p[0] - minx) / scale * area
                            py = y0 + my + (maxy - p[1]) / scale * area
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
        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)
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


class FreehandRecordOverlay:
    def __init__(self, config, glyphs):
        self.config = config
        self.glyphs = glyphs
        self.sections = config.get("recording", {}).get("sections", 4)
        self.grid = [[] for _ in range(self.sections)]
        self.current_stroke = []
        self.current_cell = -1
        self.filled = [False] * self.sections
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
        self.da.connect("draw", self.on_draw)
        self.da.connect("button-press-event", self.on_button_press)
        self.da.connect("button-release-event", self.on_button_release)
        self.da.connect("motion-notify-event", self.on_motion)
        self.win.add(self.da)

        self.win.connect("key-press-event", self.on_key_press)
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

    def on_key_press(self, widget, event):
        if event.get_keyval() == Gdk.KEY_Escape:
            Gtk.main_quit()
        return True

    def on_button_press(self, widget, event):
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

    def on_motion(self, widget, event):
        if not self.current_stroke:
            return False
        self.current_stroke.append((event.x, event.y))
        widget.queue_draw()
        return True

    def on_button_release(self, widget, event):
        if not self.current_stroke or event.button != 1:
            return False
        stroke = self.current_stroke
        self.current_stroke = []

        if len(stroke) < MIN_STROKE_POINTS:
            widget.queue_draw()
            return True

        self.grid[self.current_cell].append(list(stroke))
        self.filled[self.current_cell] = True

        if all(self.filled):
            self._prompt_mapping()
        widget.queue_draw()
        return True

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

        hl = Gtk.Label(label="<small>Use <b>__mode_exec__</b> to switch to exec mode,\n<b>__mode_term_exec__</b> to run in a terminal,\n<b>__complete_enter__</b> to send Enter after output.</small>")
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
            for cell_strokes in self.grid:
                if cell_strokes:
                    s = cell_strokes[0]
                    alloc = self.da.get_allocated_width(), self.da.get_allocated_height()
                    eps = max(alloc) * 0.008
                    simplified = rdp_simplify(s, eps)
                    normalized = normalize_stroke(simplified)
                    templates.append({"pts": [(x, y) for x, y in normalized]})
            glyph = {"name": name, "string": string, "templates": templates}
            save_glyph(glyph)
            self.glyphs.append(glyph)

        self.grid = [[] for _ in range(self.sections)]
        self.filled = [False] * self.sections
        self.current_cell = -1
        self.da.queue_draw()

    def on_draw(self, widget, cr):
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
        cw = alloc[0] / self.grid_cols
        ch = alloc[1] / self.grid_rows

        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
        cr.set_font_size(18)

        for i in range(self.sections):
            row = i // self.grid_cols
            col = i % self.grid_cols
            x, y = col * cw, row * ch

            cr.set_source_rgba(0.3, 0.3, 0.3, 0.5)
            cr.set_line_width(1)
            cr.rectangle(x, y, cw, ch)
            cr.stroke()

            if self.filled[i]:
                cr.set_source_rgba(0.3, 0.8, 0.3, 0.3)
                cr.rectangle(x + 2, y + 2, cw - 4, ch - 4)
                cr.fill()

            cr.set_source_rgba(0.6, 0.6, 0.6, 0.6)
            cr.move_to(x + 12, y + 28)
            cr.show_text(str(i + 1))

            for stroke in self.grid[i]:
                self._draw_polyline(cr, stroke, ink_w, 0.7, 0.9, 0.7, 0.9)

        if self.current_stroke and self.current_cell >= 0:
            self._draw_polyline(cr, self.current_stroke, ink_w, 0.9, 0.9, 0.9, 0.9)

    def _draw_polyline(self, cr, pts, width, r, g, b, a):
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


class DictionaryWindow:
    def __init__(self, config, glyphs):
        self.config = config
        self.glyphs = glyphs
        self._anim_data = []

        self.win = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        self.win.set_title("glyphs — dictionary")
        self.win.set_default_size(900, 600)

        grid_cols = config.get("appearance", {}).get("dictionary_grid_cols", 4)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        self.flow = Gtk.FlowBox()
        self.flow.set_max_children_per_line(grid_cols)
        self.flow.set_min_children_per_line(grid_cols)
        self.flow.set_selection_mode(Gtk.SelectionMode.NONE)
        self.flow.set_homogeneous(True)

        if not glyphs:
            lbl = Gtk.Label(label="No glyphs configured.\nRun 'glyphs --record' to add some.")
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


class GlyphCard(Gtk.EventBox):
    def __init__(self, glyph):
        super().__init__()
        self.glyph = glyph
        self.templates = glyph.get("templates", [])
        self.progress = 0.0

        frame = Gtk.Frame()
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        box.set_margin_start(4)
        box.set_margin_end(4)
        box.set_margin_top(4)
        box.set_margin_bottom(4)

        nm = Gtk.Label(label=glyph.get("name", "?"))
        nm.set_markup(f"<b>{GLib.markup_escape_text(glyph.get('name', '?'))}</b>")
        box.add(nm)

        st = Gtk.Label(label=glyph.get("string", ""))
        st.set_markup(f"<small>{GLib.markup_escape_text(glyph.get('string', ''))}</small>")
        box.add(st)

        self.da = Gtk.DrawingArea()
        self.da.set_size_request(100, 80)
        self.da.connect("draw", self.on_draw)
        box.add(self.da)

        frame.add(box)
        self.add(frame)

    def tick(self):
        self.progress += 0.008
        if self.progress > 1.2:
            self.progress = 0.0
        self.da.queue_draw()

    def on_draw(self, widget, cr):
        alloc = widget.get_allocated_width(), widget.get_allocated_height()
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

        n = max(2, int(self.progress * len(pts)))
        if n > len(pts):
            n = len(pts)

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

        if n > 0 and n <= len(pts):
            px = margin + (pts[n - 1][0] - minx) / scale * draw_scale
            py = margin + (maxy - pts[n - 1][1]) / scale * draw_scale
            cr.set_source_rgba(1.0, 0.3, 0.3, 0.9)
            cr.arc(px, py, 3.5, 0, 2 * math.pi)
            cr.fill()


GRID_PTS = {
    "A":(0,20),"B":(-5,15),"C":(5,15),"D":(0,10),"E":(-5,5),"F":(5,5),"G":(0,0),
    "U":(0,25),"V":(-5,25),"W":(5,25),
    "X":(-10,15),"Y":(10,15),"Z":(0,15),
    "AA":(-10,5),"AB":(10,5),"AC":(0,-5),
    "AD":(-10,20),"AE":(10,20),
    "AF":(-10,0),"AG":(10,0),
}
GRID_ANCHORS = set("ABCDEFG")

def _grid_edge_ok(p, q):
    dx = q[0]-p[0]; dy = q[1]-p[1]
    return (dx!=0 or dy!=0) and (dx==0 or dy==0 or abs(dx)==abs(dy))

GRID_ADJ = {}
for k,p in GRID_PTS.items():
    GRID_ADJ[k] = [o for o in GRID_PTS if o!=k and _grid_edge_ok(p,GRID_PTS[o])]

GRID_BOUNDS = (min(p[0] for p in GRID_PTS.values()), max(p[0] for p in GRID_PTS.values()),
               min(p[1] for p in GRID_PTS.values()), max(p[1] for p in GRID_PTS.values()))
# grid_minx=-10, grid_maxx=10, grid_miny=-5, grid_maxy=25

def _bfs_path(start, end):
    from collections import deque
    q = deque([start]); parent = {start: None}
    while q:
        cur = q.popleft()
        if cur == end:
            path = []
            while cur is not None: path.append(cur); cur = parent[cur]
            return path[::-1]
        for n in GRID_ADJ[cur]:
            if n not in parent: parent[n] = cur; q.append(n)
    return None


class RecordOverlay:
    def __init__(self, config, glyphs):
        self.config = config
        self.glyphs = glyphs
        self.sections = config.get("recording", {}).get("sections", 4)
        self.grid = [[] for _ in range(self.sections)]
        self.current_stroke = []
        self.current_cell = -1
        self.filled = [False] * self.sections
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
        self.da.connect("draw", self.on_draw)
        self.da.connect("button-press-event", self.on_button_press)
        self.da.connect("button-release-event", self.on_button_release)
        self.da.connect("motion-notify-event", self.on_motion)
        self.win.add(self.da)

        self.win.connect("key-press-event", self.on_key_press)
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

    def on_key_press(self, widget, event):
        if event.get_keyval() == Gdk.KEY_Escape:
            Gtk.main_quit()
        return True

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

    def _snap_and_route(self, stroke, cw, ch):
        ox, oy, sc = self._cell_transform(self.current_cell, cw, ch)
        snapped = []
        for sx, sy in stroke:
            gx, gy = self._screen_to_grid(sx, sy, ox, oy, sc)
            best = min(GRID_PTS.keys(), key=lambda k: math.hypot(gx - GRID_PTS[k][0], gy - GRID_PTS[k][1]))
            snapped.append(best)
        cleaned = [snapped[0]]
        for s in snapped[1:]:
            if s != cleaned[-1]: cleaned.append(s)
        routed = [cleaned[0]]
        for i in range(1, len(cleaned)):
            p, q = cleaned[i-1], cleaned[i]
            if q in GRID_ADJ[p]:
                routed.append(q)
            else:
                path = _bfs_path(p, q)
                if path: routed.extend(path[1:])
                else: return None
        return routed

    def on_button_press(self, widget, event):
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

    def on_motion(self, widget, event):
        if not self.current_stroke:
            return False
        self.current_stroke.append((event.x, event.y))
        widget.queue_draw()
        return True

    def on_button_release(self, widget, event):
        if not self.current_stroke or event.button != 1:
            return False
        stroke = self.current_stroke
        self.current_stroke = []
        if len(stroke) < MIN_STROKE_POINTS:
            widget.queue_draw(); return True
        alloc = widget.get_allocated_width(), widget.get_allocated_height()
        cw, ch = alloc[0] / self.grid_cols, alloc[1] / self.grid_rows
        eps = max(alloc) * 0.008
        simplified = rdp_simplify(stroke, eps)
        routed = self._snap_and_route(simplified, cw, ch)
        if routed is not None:
            self.grid[self.current_cell] = list(routed)
            self.filled[self.current_cell] = True
        if all(self.filled):
            self._prompt_mapping()
        widget.queue_draw()
        return True

    def _prompt_mapping(self):
        dialog = Gtk.Dialog(
            title="Record glyph",
            transient_for=self.win, flags=0,
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
        hl = Gtk.Label(label="<small>Use <b>__mode_exec__</b> to switch to exec mode,\n<b>__mode_term_exec__</b> to run in a terminal,\n<b>__complete_enter__</b> to send Enter after output.</small>")
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
            for labels in self.grid:
                if labels:
                    coords = [GRID_PTS[k] for k in labels]
                    normalized = normalize_stroke(coords)
                    templates.append({"pts": [(x, y) for x, y in normalized]})
            glyph = {"name": name, "string": string, "templates": templates}
            save_glyph(glyph)
            self.glyphs.append(glyph)
        self.grid = [[] for _ in range(self.sections)]
        self.filled = [False] * self.sections
        self.current_cell = -1
        self.da.queue_draw()

    def _draw_polyline(self, cr, pts, width, r, g, b, a):
        if len(pts) < 2: return
        cr.set_source_rgba(r, g, b, a)
        cr.set_line_width(width)
        cr.set_line_cap(cairo.LineCap.ROUND)
        cr.set_line_join(cairo.LineJoin.ROUND)
        cr.move_to(pts[0][0], pts[0][1])
        for p in pts[1:]:
            cr.line_to(p[0], p[1])
        cr.stroke()

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
                cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
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
                if k >= o: continue
                x1 = ox + (GRID_PTS[k][0] - GRID_BOUNDS[0]) * sc
                y1 = oy + (GRID_BOUNDS[3] - GRID_PTS[k][1]) * sc
                x2 = ox + (GRID_PTS[o][0] - GRID_BOUNDS[0]) * sc
                y2 = oy + (GRID_BOUNDS[3] - GRID_PTS[o][1]) * sc
                cr.move_to(x1, y1); cr.line_to(x2, y2); cr.stroke()

    def on_draw(self, widget, cr):
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
        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
        cr.set_font_size(18)
        for i in range(self.sections):
            row, col = i // self.grid_cols, i % self.grid_cols
            x, y = col * cw, row * ch
            cr.set_source_rgba(0.3, 0.3, 0.3, 0.5)
            cr.set_line_width(1)
            cr.rectangle(x, y, cw, ch)
            cr.stroke()
            if self.filled[i]:
                cr.set_source_rgba(0.3, 0.8, 0.3, 0.2)
                cr.rectangle(x + 2, y + 2, cw - 4, ch - 4)
                cr.fill()
            cr.set_source_rgba(0.6, 0.6, 0.6, 0.6)
            cr.move_to(x + 12, y + 28)
            cr.show_text(str(i + 1))
            self._draw_grid(cr, i, cw, ch)
            ox, oy, sc = self._cell_transform(i, cw, ch)
            for labels in self.grid[i]:
                screen_pts = [(ox + (GRID_PTS[k][0] - GRID_BOUNDS[0]) * sc,
                               oy + (GRID_BOUNDS[3] - GRID_PTS[k][1]) * sc) for k in labels]
                self._draw_polyline(cr, screen_pts, ink_w, 0.3, 0.8, 0.3, 0.9)
        if self.current_stroke and self.current_cell >= 0:
            self._draw_polyline(cr, self.current_stroke, ink_w, 0.9, 0.9, 0.9, 0.9)


def main():
    parser = argparse.ArgumentParser(description="Pen-based glyph input system")
    parser.add_argument("--record", action="store_true", help="Record new glyphs (grid-snapped)")
    parser.add_argument("--record-freehand", action="store_true", help="Record new glyphs (freehand)")
    parser.add_argument("--dictionary", action="store_true", help="Browse glyph dictionary")
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
