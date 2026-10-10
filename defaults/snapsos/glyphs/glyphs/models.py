"""
Simple data models used by the glyphs system.
"""


class StrokeGlyph:
    """Represents a single recognised stroke together with its metadata.

    Attributes
    ----------
    stroke : list of (x, y) tuples
        The raw screen-space points of the recognised stroke.
    string : str or None
        The output string (what gets typed/executed) when the glyph fires.
    name : str or None
        Human-readable name shown in the dictionary and carousel.
    """

    def __init__(self, stroke, string=None, name=None):
        self.stroke = stroke
        self.string = string
        self.name = name

    @property
    def display_text(self):
        """Return the string to display on the overlay — the output string,
        or ``?`` if unrecognised."""
        return self.string if self.string else "?"
