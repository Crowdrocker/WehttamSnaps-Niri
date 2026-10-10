"""
Input-device helpers.

Provides the shared pen-event check used by all drawing overlays.
"""

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk


# ---------------------------------------------------------------------------
# Pen / touch detection
# ---------------------------------------------------------------------------

def is_pen_event(device):
    """Return ``True`` if *device* is a pen, eraser, or touchscreen.

    Mouse / trackpad events are rejected so that only stylus input is
    accepted for drawing.
    """
    if device is None:
        return False
    src = device.get_source()
    return src in (Gdk.InputSource.PEN,
                   Gdk.InputSource.ERASER,
                   Gdk.InputSource.TOUCHSCREEN)
