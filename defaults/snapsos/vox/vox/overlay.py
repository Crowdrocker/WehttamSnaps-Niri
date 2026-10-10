"""Transparent HUD overlay using wlr-layer-shell (Wayland overlay layer).

Places a GTK window in the compositor's ``OVERLAY`` layer — always above
everything, never tiled.  Uses system theme for styling.
"""

from __future__ import annotations

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GLib, GtkLayerShell


class Overlay:
    """A small overlay at the top of the screen.

    Uses the compositor's ``OVERLAY`` layer so it floats above all other
    windows (including panels/bars).  No exclusive zone is set, so it
    does not push other surfaces aside.

    Shown/hidden by ``show_text()`` with a configurable auto-hide timeout.
    """

    def __init__(self, hide_timeout: int = 3):
        import logging
        self._log = logging.getLogger("vox")
        self._hide_timeout = hide_timeout

        self.window = Gtk.Window.new(Gtk.WindowType.TOPLEVEL)
        try:
            GtkLayerShell.init_for_window(self.window)
            GtkLayerShell.set_layer(self.window, GtkLayerShell.Layer.OVERLAY)
            GtkLayerShell.set_namespace(self.window, "vox-overlay")
            GtkLayerShell.set_keyboard_interactivity(
                self.window, GtkLayerShell.KeyboardMode.NONE
            )
            GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.TOP, True)
            GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.TOP, 12)
            self._log.info("overlay: GtkLayerShell initialized")
        except Exception as e:
            self._log.error("overlay: GtkLayerShell init failed: %s", e)

        self.window.set_decorated(False)
        self.window.set_resizable(True)
        self.window.set_name("vox-overlay")

        self.label = Gtk.Label(label="")
        self.label.set_halign(Gtk.Align.CENTER)
        self.label.set_valign(Gtk.Align.CENTER)
        self.label.set_line_wrap(True)
        self.label.set_max_width_chars(60)
        self.window.add(self.label)

        display = Gdk.Display.get_default()
        if display:
            monitor = display.get_primary_monitor()
            if monitor:
                geo = monitor.get_geometry()
                if geo:
                    w = min(1000, geo.width - 40)
                    self.window.set_default_size(w, 56)

        self.window.show_all()
        self.window.hide()
        self._log.info("overlay: window created and initially hidden")

        self._timeout_id = None

    def show_text(self, text: str, timeout: int | None = None) -> None:
        """Display *text* on the overlay.

        If *timeout* is given, auto-hide after that many seconds.  A
        *timeout* of ``0`` keeps the overlay visible until the next call.
        """
        try:
            self.label.set_text(text)
            nw = min(len(text) * 14 + 60, 1200)
            self.window.set_size_request(nw, 56)
            self.window.show_all()
            self._log.info("overlay: shown with text=%r", text)
        except Exception as e:
            self._log.error("overlay: show_text failed: %s", e)
        if self._timeout_id:
            GLib.source_remove(self._timeout_id)
            self._timeout_id = None
        t = self._hide_timeout if timeout is None else timeout
        if t > 0:
            self._timeout_id = GLib.timeout_add_seconds(t, self._hide)

    def clear(self) -> None:
        self.show_text("", timeout=0)

    def _hide(self) -> bool:
        try:
            self.window.hide()
            self._log.info("overlay: hidden")
        except Exception as e:
            self._log.error("overlay: hide failed: %s", e)
        self._timeout_id = None
        return False

    def destroy(self) -> None:
        if self._timeout_id:
            GLib.source_remove(self._timeout_id)
        self.window.destroy()
