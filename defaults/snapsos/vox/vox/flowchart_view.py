"""Cairo-rendered interactive graph editor — like draw.io for the command graph.

Nodes are positioned freely (``pos_x`` / ``pos_y`` in the config).
Key interactions:

- **Left-drag on a node body** — move the node.
- **Left-drag from the right-edge port** — draw a connection to another node.
- **Left-click (no drag)** — select the node.
- **Right-click on a node** — context menu.
- **Left-drag on empty canvas** — pan.
- **Scroll** — zoom.
"""

from __future__ import annotations
import math
from collections import deque
from enum import Enum, auto
from typing import Callable

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("PangoCairo", "1.0")
from gi.repository import Gtk, Gdk, Pango, PangoCairo

import cairo

from .models import GraphNode
from .config_manager import Config

# ── Constants ─────────────────────────────────────────────────────────────────
NODE_W = 144
NODE_H = 52
CORNER_R = 8
PORT_R = 7
PORT_HIT_R = 14
MIN_SCALE = 0.2
MAX_SCALE = 3.0
DRAG_THRESHOLD = 5
AUTO_ORIGIN_X = 60
AUTO_ORIGIN_Y = 60
AUTO_STEP_X = 350
AUTO_STEP_Y = 80

ACTION_TYPES = {"exec", "shell_exec", "type"}

def _is_action(type_: str) -> bool:
    return type_ in ACTION_TYPES

COLORS: dict[str, tuple[str, str]] = {
    "root":       ("#263238", "#78909c"),
    "branch":     ("#37474f", "#b0bec5"),
    "exec":       ("#1b5e20", "#a5d6a7"),
    "shell_exec": ("#bf360c", "#ffab91"),
    "type":       ("#0d47a1", "#90caf9"),
}

ICONS: dict[str, str] = {
    "root":       "\u25c9",
    "branch":     "\u25a4",
    "exec":       "\u26a1",
    "shell_exec": "\u25b6",
    "type":       "\u2328",
}

PORT_COLOR = (0.4, 0.7, 1.0, 0.7)
PORT_HOVER_COLOR = (0.6, 1.0, 1.0, 1.0)
CONN_DRAG_COLOR = (0.3, 0.6, 1.0, 0.6)


class _Mode(Enum):
    IDLE = auto()
    PANNING = auto()
    DRAGGING_NODE = auto()
    DRAGGING_CONNECTION = auto()


class NodeRect:
    """Visual representation of a graph node for hit-testing and drawing."""

    __slots__ = ("x", "y", "w", "h", "name", "type", "icon", "trigger",
                 "detail", "in_edges", "out_edges", "node_ref")

    def __init__(self, x: float, y: float, w: float, h: float,
                 name: str, type_: str, icon: str, trigger: str, detail: str,
                 in_edges: list[str], out_edges: list[str],
                 node_ref: GraphNode | None = None):
        self.x = x
        self.y = y
        self.w = w
        self.h = h
        self.name = name
        self.type = type_
        self.icon = icon
        self.trigger = trigger
        self.detail = detail
        self.in_edges = in_edges
        self.out_edges = out_edges
        self.node_ref = node_ref

    def contains(self, px: float, py: float) -> bool:
        return self.x <= px <= self.x + self.w and self.y <= py <= self.y + self.h

    def cx(self) -> float:
        return self.x + self.w / 2

    def cy(self) -> float:
        return self.y + self.h / 2

    def right(self) -> float:
        return self.x + self.w

    def left(self) -> float:
        return self.x

    def top(self) -> float:
        return self.y

    def bottom(self) -> float:
        return self.y + self.h

    def right_port_center(self) -> tuple[float, float]:
        return (self.right(), self.cy())

    def left_port_center(self) -> tuple[float, float]:
        return (self.left(), self.cy())


class FlowchartView(Gtk.DrawingArea):
    """Interactive graph editor — draw.io-style for the vox command graph."""

    def __init__(self):
        super().__init__()
        self.set_tooltip_text(
            "Drag node to move \u00b7 Drag from right port to connect \u00b7 "
            "Click to select \u00b7 Right-click for menu \u00b7 "
            "Drag empty space to pan \u00b7 Scroll to zoom"
        )
        self._rects: list[NodeRect] = []
        self._config: Config | None = None
        self._highlighted_names: set[str] = set()
        self._hovered_port: tuple[str, str] | None = None
        self._on_select: Callable | None = None
        self._on_context: Callable | None = None
        self._on_graph_changed: Callable | None = None

        self._scale = 1.0
        self._ox = 0.0
        self._oy = 0.0

        self._mode = _Mode.IDLE
        self._drag_button = 0
        self._press_sx = 0.0
        self._press_sy = 0.0
        self._drag_start_name: str | None = None
        self._drag_offset_x = 0.0
        self._drag_offset_y = 0.0
        self._conn_source_name: str | None = None
        self._conn_mouse_cx = 0.0
        self._conn_mouse_cy = 0.0
        self._conn_target_name: str | None = None

        self.add_events(
            Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.BUTTON_RELEASE_MASK
            | Gdk.EventMask.POINTER_MOTION_MASK
            | Gdk.EventMask.SCROLL_MASK
        )
        self.connect("draw", self._on_draw)
        self.connect("realize", self._on_realize)
        self.connect("button-press-event", self._on_button_press)
        self.connect("button-release-event", self._on_button_release)
        self.connect("motion-notify-event", self._on_motion)
        self.connect("scroll-event", self._on_scroll)

    # ── Public API ───────────────────────────────────────────────────────────

    def set_config(self, config: Config | None) -> None:
        self._rects.clear()
        self._selected_name = None
        self._highlighted_names.clear()
        self._hovered_port = None
        self._mode = _Mode.IDLE
        self._config = config
        if config is None:
            self.queue_draw()
            return
        self._auto_layout_if_needed(config)
        self._build_rects(config)
        self._center_view()
        self.queue_draw()

    def set_callbacks(self, on_select: Callable | None = None,
                      on_context: Callable | None = None,
                      on_graph_changed: Callable | None = None) -> None:
        self._on_select = on_select
        self._on_context = on_context
        self._on_graph_changed = on_graph_changed

    def rebuild(self) -> None:
        """Rebuild rects without resetting the view position."""
        if self._config is None:
            return
        self._build_rects(self._config)
        self.queue_draw()

    def run_auto_layout(self) -> None:
        """Reset all node positions to a smart auto-layout."""
        if self._config:
            self._auto_layout_all(self._config)
            self._build_rects(self._config)
            self.queue_draw()

    def select_node(self, name: str | None) -> None:
        self._selected_name = name
        self.queue_draw()

    def set_highlighted(self, names: set[str]) -> None:
        self._highlighted_names = names
        self.queue_draw()

    # ── Layout helpers ──────────────────────────────────────────────────────

    @staticmethod
    def _auto_layout_all(config: Config) -> None:
        """Smart layered layout — positions ALL nodes using barycenter ordering."""
        nodes = config.tree

        # BFS layering starting from all root nodes.
        layers: dict[str, int] = {}
        q: deque[tuple[str, int]] = deque()
        for name, nd in nodes.items():
            if nd.type == "root":
                layers[name] = 0
                for child in nd.connections:
                    if child in nodes and child not in layers:
                        layers[child] = 1
                        q.append((child, 1))
        while q:
            name, lvl = q.popleft()
            nd = nodes.get(name)
            if nd is None:
                continue
            for child in nd.connections:
                if child not in layers and child in nodes:
                    layers[child] = lvl + 1
                    q.append((child, lvl + 1))

        max_lvl = max(layers.values()) if layers else 0
        for name in nodes:
            if name not in layers:
                max_lvl += 1
                layers[name] = max_lvl

        # Parent map for barycenter calculation.
        parents: dict[str, list[str]] = {n: [] for n in nodes}
        for name, nd in nodes.items():
            for child in nd.connections:
                if child in parents:
                    parents[child].append(name)

        by_layer: dict[int, list[str]] = {}
        for name, lvl in layers.items():
            by_layer.setdefault(lvl, []).append(name)

        for lvl in sorted(by_layer):
            items = by_layer[lvl]

            if lvl == 0:
                ordered = [n for n in nodes if nodes[n].type == "root" and n in items]
                ordered += [n for n in items if n not in ordered]
            else:
                def _bary(n: str) -> float:
                    ys = [nodes[p].pos_y or 0 for p in parents[n]
                          if nodes.get(p) and nodes[p].pos_y is not None]
                    return sum(ys) / len(ys) if ys else 0
                ordered = sorted(items, key=_bary)

            for i, name in enumerate(ordered):
                nd = nodes[name]
                nd.pos_x = AUTO_ORIGIN_X + lvl * AUTO_STEP_X
                nd.pos_y = AUTO_ORIGIN_Y + i * AUTO_STEP_Y

    @staticmethod
    def _auto_layout_if_needed(config: Config) -> None:
        """Assign positions only to nodes missing ``pos_x`` or ``pos_y``."""
        unpositioned = [n for n in config.tree if config.tree[n].pos_x is None]
        if not unpositioned:
            return
        # Assign a default position below the lowest existing node so
        # existing layouts are not disturbed.
        max_y = max((n.pos_y or 0) for n in config.tree.values()) + AUTO_STEP_Y
        for i, name in enumerate(unpositioned):
            config.tree[name].pos_x = AUTO_ORIGIN_X
            config.tree[name].pos_y = max_y + i * AUTO_STEP_Y

    def _build_rects(self, config: Config) -> None:
        nodes = config.tree

        reverse: dict[str, list[str]] = {}
        for name, nd in nodes.items():
            for child in nd.connections:
                reverse.setdefault(child, []).append(name)

        def detail(name: str) -> str:
            nd = nodes.get(name)
            if nd is None:
                return ""
            if nd.type == "root":
                ww = nd.wake_word or "(no wake word)"
                return ww
            if nd.type in ACTION_TYPES:
                return nd.command[:50]
            parts = []
            if nd.connections:
                parts.append(f"{len(nd.connections)} out")
            if nd.text_capture:
                parts.append("$text")
            return ", ".join(parts) if parts else ""

        def out_edges(name: str) -> list[str]:
            nd = nodes.get(name)
            return list(nd.connections) if nd else []

        def in_edges(name: str) -> list[str]:
            return reverse.get(name, [])

        self._rects.clear()
        for name, nd in sorted(nodes.items(), key=lambda kv: (kv[1].pos_y or 0, kv[1].pos_x or 0)):
            x = nd.pos_x or AUTO_ORIGIN_X
            y = nd.pos_y or AUTO_ORIGIN_Y
            self._rects.append(NodeRect(
                x, y, NODE_W, NODE_H, name, nd.type, ICONS.get(nd.type, "?"),
                nd.trigger, detail(name), in_edges(name), out_edges(name), node_ref=nd,
            ))

    # ── View ─────────────────────────────────────────────────────────────────

    def _center_view(self) -> None:
        alloc = self.get_allocation()
        vw, vh = alloc.width, alloc.height
        if vw < 10 or vh < 10 or not self._rects:
            return
        min_x = min(r.x for r in self._rects) - 40
        min_y = min(r.y for r in self._rects) - 40
        max_x = max(r.right() for r in self._rects) + 40
        max_y = max(r.bottom() for r in self._rects) + 40
        cw, ch = max_x - min_x, max_y - min_y
        if cw < 1 or ch < 1:
            return
        s = min((vw - 40) / cw, (vh - 40) / ch, 1.5)
        self._scale = max(MIN_SCALE, min(MAX_SCALE, s))
        cx, cy = (min_x + max_x) / 2, (min_y + max_y) / 2
        self._ox = vw / 2 - cx * self._scale
        self._oy = vh / 2 - cy * self._scale

    def _on_realize(self, *_) -> None:
        self._center_view()
        self.queue_draw()

    def _screen_to_canvas(self, sx: float, sy: float) -> tuple[float, float]:
        return ((sx - self._ox) / self._scale, (sy - self._oy) / self._scale)

    # ── Hit testing ──────────────────────────────────────────────────────────

    def _hit_port(self, cx: float, cy: float) -> tuple[str, str] | None:
        for r in reversed(self._rects):
            # Left port (input) — always visible except for root and action nodes.
            if r.type not in ACTION_TYPES and r.type != "root":
                lx, ly = r.left_port_center()
                dx, dy = cx - lx, cy - ly
                if dx * dx + dy * dy <= PORT_HIT_R * PORT_HIT_R:
                    return (r.name, "left")
            # Right port (output) — only for branch and root nodes.
            if r.type == "root" or not _is_action(r.type):
                rx_, ry_ = r.right_port_center()
                dx, dy = cx - rx_, cy - ry_
                if dx * dx + dy * dy <= PORT_HIT_R * PORT_HIT_R:
                    return (r.name, "right")
        return None

    def _hit_node(self, cx: float, cy: float) -> NodeRect | None:
        for r in reversed(self._rects):
            if r.contains(cx, cy):
                lx, ly = r.left_port_center()
                dx, dy = cx - lx, cy - ly
                if dx * dx + dy * dy <= PORT_HIT_R * PORT_HIT_R:
                    continue
                if not _is_action(r.type):
                    rx_, ry_ = r.right_port_center()
                    dx, dy = cx - rx_, cy - ry_
                    if dx * dx + dy * dy <= PORT_HIT_R * PORT_HIT_R:
                        continue
                return r
        return None

    # ── Events ───────────────────────────────────────────────────────────────

    def _on_button_press(self, _w, event: Gdk.EventButton) -> bool:
        if event.button == 1:
            cx, cy = self._screen_to_canvas(event.x, event.y)
            self._press_sx = event.x
            self._press_sy = event.y

            port_hit = self._hit_port(cx, cy)
            if port_hit and port_hit[1] == "right":
                self._mode = _Mode.DRAGGING_CONNECTION
                self._conn_source_name = port_hit[0]
                self._conn_mouse_cx = cx
                self._conn_mouse_cy = cy
                self._conn_target_name = None
                return True

            hit = self._hit_node(cx, cy)
            if hit is not None:
                self._mode = _Mode.DRAGGING_NODE
                self._drag_start_name = hit.name
                if hit.node_ref is not None:
                    self._drag_offset_x = cx - hit.node_ref.pos_x
                    self._drag_offset_y = cy - hit.node_ref.pos_y
                else:
                    self._drag_offset_x = cx - hit.x
                    self._drag_offset_y = cy - hit.y
                return True

            self._mode = _Mode.PANNING
            return True

        elif event.button == 3:
            cx, cy = self._screen_to_canvas(event.x, event.y)
            hit = self._hit_node(cx, cy)
            if hit is not None:
                self._selected_name = hit.name
                self.queue_draw()
                if self._on_context:
                    self._on_context(hit.name, event)
                return True
        return False

    def _on_button_release(self, _w, event: Gdk.EventButton) -> bool:
        if event.button == 1:
            prev_mode = self._mode
            self._mode = _Mode.IDLE

            dx = abs(event.x - self._press_sx)
            dy = abs(event.y - self._press_sy)
            was_drag = dx > DRAG_THRESHOLD or dy > DRAG_THRESHOLD

            if prev_mode == _Mode.DRAGGING_CONNECTION:
                cx, cy = self._screen_to_canvas(event.x, event.y)
                port_hit = self._hit_port(cx, cy)
                if port_hit and port_hit[1] == "left" and port_hit[0] != self._conn_source_name:
                    target = port_hit[0]
                    src = self._conn_source_name
                    if src and target and self._config:
                        nd = self._config.tree.get(src)
                        if nd:
                            if target in nd.connections:
                                nd.connections.remove(target)
                            else:
                                nd.connections.append(target)
                        self._rebuild_rects()
                        self._emit_graph_changed()
                self._conn_source_name = None
                self._conn_target_name = None
                self.queue_draw()
                return True

            if prev_mode == _Mode.DRAGGING_NODE:
                if not was_drag:
                    cx, cy = self._screen_to_canvas(event.x, event.y)
                    hit = self._hit_node(cx, cy)
                    if hit is not None:
                        self._selected_name = hit.name
                        self.queue_draw()
                        if self._on_select:
                            self._on_select(hit.name)
                else:
                    self._emit_graph_changed()
                return True

            if prev_mode == _Mode.PANNING:
                return True

        return False

    def _on_motion(self, _w, event: Gdk.EventMotion) -> bool:
        cx, cy = self._screen_to_canvas(event.x, event.y)

        if self._mode == _Mode.DRAGGING_NODE:
            if self._drag_start_name and self._config:
                nd = self._config.tree.get(self._drag_start_name)
                if nd is not None:
                    new_x = cx - self._drag_offset_x
                    new_y = cy - self._drag_offset_y
                    nd.pos_x = round(new_x)
                    nd.pos_y = round(new_y)
                    for r in self._rects:
                        if r.name == self._drag_start_name:
                            r.x = nd.pos_x
                            r.y = nd.pos_y
                            break
                    self.queue_draw()
            return True

        if self._mode == _Mode.DRAGGING_CONNECTION:
            self._conn_mouse_cx = cx
            self._conn_mouse_cy = cy
            port_hit = self._hit_port(cx, cy)
            if port_hit and port_hit[1] == "left" and port_hit[0] != self._conn_source_name:
                self._conn_target_name = port_hit[0]
            else:
                self._conn_target_name = None
            self.queue_draw()
            return True

        if self._mode == _Mode.PANNING:
            self._ox += (event.x - self._press_sx)
            self._oy += (event.y - self._press_sy)
            self._press_sx = event.x
            self._press_sy = event.y
            self.queue_draw()
            return True

        port_hit = self._hit_port(cx, cy)
        if port_hit != self._hovered_port:
            self._hovered_port = port_hit
            self._set_cursor_for_port(port_hit)
            self.queue_draw()
        elif port_hit is None:
            if self._hovered_port is not None:
                self._hovered_port = None
                self._set_cursor_for_port(None)
                self.queue_draw()

        return False

    def _on_scroll(self, _w, event: Gdk.EventScroll) -> bool:
        factor = 1.15 if event.direction == Gdk.ScrollDirection.UP else 1 / 1.15
        if event.direction == Gdk.ScrollDirection.SMOOTH:
            dy = event.delta_y
            if abs(dy) > 0.01:
                factor = 1.05 if dy < 0 else 1 / 1.05
            else:
                return False
        new_s = max(MIN_SCALE, min(MAX_SCALE, self._scale * factor))
        mx, my = event.x, event.y
        self._ox = mx - (mx - self._ox) / self._scale * new_s
        self._oy = my - (my - self._oy) / self._scale * new_s
        self._scale = new_s
        self.queue_draw()
        return True

    def _set_cursor_for_port(self, port_hit: tuple[str, str] | None) -> None:
        if port_hit and port_hit[1] == "right":
            self.get_window().set_cursor(Gdk.Cursor.new_for_display(
                Gdk.Display.get_default(), Gdk.CursorType.CROSSHAIR))
        elif port_hit and port_hit[1] == "left":
            self.get_window().set_cursor(Gdk.Cursor.new_for_display(
                Gdk.Display.get_default(), Gdk.CursorType.HAND2))
        else:
            self.get_window().set_cursor(Gdk.Cursor.new_for_display(
                Gdk.Display.get_default(), Gdk.CursorType.ARROW))

    # ── Internal helpers ─────────────────────────────────────────────────────

    def _rebuild_rects(self) -> None:
        if self._config:
            self._build_rects(self._config)

    def _emit_graph_changed(self) -> None:
        if self._on_graph_changed:
            self._on_graph_changed()

    # ── Drawing ──────────────────────────────────────────────────────────────

    def _on_draw(self, _w, cr) -> None:
        w = self.get_allocated_width()
        h = self.get_allocated_height()
        cr.set_source_rgb(0.12, 0.12, 0.14)
        cr.paint()

        if not self._rects:
            cr.set_source_rgb(0.4, 0.4, 0.4)
            layout = self.create_pango_layout("No nodes \u2014 add them in the editor")
            fd = Pango.FontDescription("monospace 14")
            layout.set_font_description(fd)
            tw, _ = layout.get_pixel_size()
            cr.move_to((w - tw) / 2, h / 2 - 10)
            PangoCairo.show_layout(cr, layout)
            return

        cr.set_source_rgb(0.25, 0.25, 0.27)
        cr.rectangle(0, 0, 120, 22)
        cr.fill()
        cr.set_source_rgb(0.5, 0.5, 0.5)
        zl = self.create_pango_layout(f"\xd7{self._scale:.1f}")
        zfd = Pango.FontDescription("monospace 10")
        zl.set_font_description(zfd)
        cr.move_to(8, 3)
        PangoCairo.show_layout(cr, zl)

        cr.save()
        cr.translate(self._ox, self._oy)
        cr.scale(self._scale, self._scale)
        cr.set_antialias(cairo.ANTIALIAS_GOOD)
        cr.set_line_cap(cairo.LINE_CAP_ROUND)

        self._draw_edges(cr)

        for r in self._rects:
            sel = r.name == self._selected_name
            hov = r.name == self._hovered_port[0] if self._hovered_port else False
            self._draw_node(cr, r, sel, hov)

        self._draw_ports(cr)
        self._draw_connection_drag(cr)

        cr.restore()

    @staticmethod
    def _conn_offset(x1: float, y1: float, x2: float, y2: float) -> float:
        """Bezier control-point offset that keeps the curve below ~45\u00b0."""
        dy = abs(y2 - y1)
        dx = x2 - x1
        return min(max(dy * 0.55, 30.0), dx * 0.45)

    def _draw_edge(self, cr, x1: float, y1: float, x2: float, y2: float) -> None:
        d = self._conn_offset(x1, y1, x2, y2)
        cr.move_to(x1, y1)
        cr.curve_to(x1 + d, y1, x2 - d, y2, x2, y2)
        cr.stroke()

        angle = math.atan2(y2 - y1, x2 - x1)
        a_len = 8
        cr.move_to(x2, y2)
        cr.line_to(x2 - a_len * math.cos(angle - 0.4),
                   y2 - a_len * math.sin(angle - 0.4))
        cr.move_to(x2, y2)
        cr.line_to(x2 - a_len * math.cos(angle + 0.4),
                   y2 - a_len * math.sin(angle + 0.4))
        cr.stroke()

    def _draw_edges(self, cr) -> None:
        nmap = {r.name: r for r in self._rects}
        cr.set_line_width(2)

        for r in self._rects:
            if r.type == "root":
                cr.set_source_rgba(0.4, 0.6, 0.9, 0.5)
            elif _is_action(r.type):
                continue
            else:
                cr.set_source_rgba(0.5, 0.5, 0.5, 0.25)
            for child_name in r.out_edges:
                child = nmap.get(child_name)
                if child is None:
                    continue
                x1, y1 = r.right(), r.cy()
                x2, y2 = child.x, child.cy()
                if child.type in ACTION_TYPES:
                    cr.set_source_rgba(0.4, 0.8, 0.4, 0.35)
                self._draw_edge(cr, x1, y1, x2, y2)

    def _draw_node(self, cr, r: NodeRect,
                   selected: bool, hovered: bool) -> None:
        x, y, w_, h_ = r.x, r.y, r.w, r.h

        # Shadow
        cr.set_source_rgba(0, 0, 0, 0.3)
        self._rr(cr, x + 2, y + 2, w_, h_, CORNER_R)
        cr.fill()

        bg_h, fg_h = COLORS.get(r.type, ("#333", "#fff"))

        bg = Gdk.RGBA()
        bg.parse(bg_h)
        fg = Gdk.RGBA()
        fg.parse(fg_h)

        # Highlight glow for traced paths
        if r.name in self._highlighted_names:
            cr.set_source_rgba(1, 0.84, 0, 0.25)
            cr.set_line_width(6)
            self._rr(cr, x, y, w_, h_, CORNER_R)
            cr.stroke()

        self._rr(cr, x, y, w_, h_, CORNER_R)
        cr.set_source_rgba(bg.red, bg.green, bg.blue, bg.alpha)
        cr.fill()

        if selected:
            cr.set_source_rgba(1, 1, 1, 0.6)
            cr.set_line_width(3)
            self._rr(cr, x, y, w_, h_, CORNER_R)
            cr.stroke()
        elif hovered:
            cr.set_source_rgba(1, 1, 1, 0.2)
            cr.set_line_width(2)
            self._rr(cr, x, y, w_, h_, CORNER_R)
            cr.stroke()

        # Type badge
        badge_text = r.type[:4]
        bw, bh = 16, 14
        self._rr(cr, x + w_ - bw - 4, y + 3, bw, bh, 3)
        cr.set_source_rgba(fg.red, fg.green, fg.blue, 0.15)
        cr.fill()
        bl = self.create_pango_layout(badge_text)
        bfd = Pango.FontDescription("monospace 8")
        bl.set_font_description(bfd)
        cr.set_source_rgba(fg.red, fg.green, fg.blue, 0.7)
        cr.move_to(x + w_ - bw - 4 + (bw - bl.get_pixel_size()[0]) / 2, y + 4)
        PangoCairo.show_layout(cr, bl)

        # Name with icon
        icon = ICONS.get(r.type, "?")
        cr.set_source_rgba(fg.red, fg.green, fg.blue, fg.alpha)

        # Root nodes show the internal name; branch nodes show trigger; action nodes show name.
        if r.type == "root":
            name_text = f"{icon}  {r.name}"
        elif _is_action(r.type):
            name_text = f"{icon}  {r.name}"
        else:
            name_text = f"{icon}  {r.trigger}"

        nl = self.create_pango_layout(name_text)
        nfd = Pango.FontDescription("monospace bold 11")
        nl.set_font_description(nfd)
        nw, nh = nl.get_pixel_size()
        cr.move_to(x + (w_ - nw) / 2, y + (h_ - nh) / 2 - 2)
        PangoCairo.show_layout(cr, nl)

        # Detail below everything
        if r.detail:
            dl = self.create_pango_layout(r.detail)
            dfd = Pango.FontDescription("monospace 8")
            dl.set_font_description(dfd)
            dw, dh = dl.get_pixel_size()
            cr.set_source_rgba(fg.red, fg.green, fg.blue, 0.5)
            cr.move_to(x + (w_ - dw) / 2, y + h_ - dh - 3)
            PangoCairo.show_layout(cr, dl)

    def _draw_ports(self, cr) -> None:
        for r in self._rects:
            # Right port (output) — for root and branch nodes.
            if r.type == "root" or not _is_action(r.type):
                px, py = r.right_port_center()
                is_hov = (self._hovered_port == (r.name, "right") or
                          self._conn_target_name == r.name)
                if is_hov:
                    cr.set_source_rgba(*PORT_HOVER_COLOR)
                else:
                    cr.set_source_rgba(*PORT_COLOR)
                cr.arc(px, py, PORT_R, 0, 2 * math.pi)
                cr.fill()
                cr.set_source_rgba(1, 1, 1, 0.3)
                cr.set_line_width(1)
                cr.arc(px, py, PORT_R, 0, 2 * math.pi)
                cr.stroke()

            # Left port (input) — for branch and action nodes only.
            if r.type != "root":
                px, py = r.left_port_center()
                is_hov_left = self._hovered_port == (r.name, "left")
                if is_hov_left:
                    cr.set_source_rgba(*PORT_HOVER_COLOR)
                else:
                    cr.set_source_rgba(*PORT_COLOR)
                cr.arc(px, py, PORT_R, 0, 2 * math.pi)
                cr.fill()
                cr.set_source_rgba(1, 1, 1, 0.3)
                cr.set_line_width(1)
                cr.arc(px, py, PORT_R, 0, 2 * math.pi)
                cr.stroke()

    def _draw_connection_drag(self, cr) -> None:
        if self._mode != _Mode.DRAGGING_CONNECTION or self._conn_source_name is None:
            return
        src = next((r for r in self._rects if r.name == self._conn_source_name), None)
        if src is None:
            return
        x1, y1 = src.right_port_center()
        x2 = self._conn_mouse_cx
        y2 = self._conn_mouse_cy
        if self._conn_target_name:
            tgt = next((r for r in self._rects if r.name == self._conn_target_name), None)
            if tgt:
                x2, y2 = tgt.left_port_center()
        d = self._conn_offset(x1, y1, x2, y2) if x2 > x1 else (x2 - x1) * 0.5
        cr.set_source_rgba(*CONN_DRAG_COLOR)
        cr.set_line_width(2.5)
        cr.move_to(x1, y1)
        cr.curve_to(x1 + d, y1, x2 - d, y2, x2, y2)
        cr.stroke()

    def _rr(self, cr, x: float, y: float, w: float, h: float, r: float) -> None:
        r = min(r, w / 2, h / 2)
        cr.move_to(x + r, y)
        cr.line_to(x + w - r, y)
        cr.arc(x + w - r, y + r, r, -math.pi / 2, 0)
        cr.line_to(x + w, y + h - r)
        cr.arc(x + w - r, y + h - r, r, 0, math.pi / 2)
        cr.line_to(x + r, y + h)
        cr.arc(x + r, y + h - r, r, math.pi / 2, math.pi)
        cr.line_to(x, y + r)
        cr.arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
        cr.close_path()
