"""
Geometry and recognition utilities.

Contains the full recognition pipeline::

    raw ink  →  RDP simplification  →  normalisation
    →  rotation-invariant distance matching against glyph templates
"""

import math


# ---------------------------------------------------------------------------
# Process-wide constants
# ---------------------------------------------------------------------------

N_RESAMPLE = 32          # number of points for uniform resampling
MATCH_THRESHOLD = 0.12   # maximum normalised distance for a match
MIN_STROKE_POINTS = 5    # strokes shorter than this are discarded
INK_WIDTH = 3.0          # default stroke width in pixels


# ---------------------------------------------------------------------------
# RDP simplification
# ---------------------------------------------------------------------------

def rdp_simplify(points, epsilon):
    """
    Ramer-Douglas-Peucker polyline simplification.

    Parameters
    ----------
    points : list of (x, y) tuples
        The input polyline.
    epsilon : float
        Maximum allowed perpendicular distance from the original polyline.

    Returns a simplified list of ``(x, y)`` tuples.
    """
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
        left = rdp_simplify(points[:max_idx + 1], epsilon)
        right = rdp_simplify(points[max_idx:], epsilon)
        return left[:-1] + right
    return [points[0], points[-1]]


def _perp_dist(p, a, b):
    """Perpendicular distance from point *p* to the line through *a* and *b*."""
    if a[0] == b[0] and a[1] == b[1]:
        return math.hypot(p[0] - a[0], p[1] - a[1])
    dx = b[0] - a[0]
    dy = b[1] - a[1]
    t = ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    return math.hypot(p[0] - (a[0] + t * dx), p[1] - (a[1] + t * dy))


# ---------------------------------------------------------------------------
# Resampling & normalisation
# ---------------------------------------------------------------------------

def resample_points(points, n):
    """
    Uniformly resample a polyline to *n* evenly-spaced points.

    Uses cumulative chord-length parameterisation so that output points
    are spaced by equal arc-length.
    """
    if len(points) <= 1:
        return list(points) * n
    dists = [0.0]
    for i in range(1, len(points)):
        dists.append(
            dists[-1]
            + math.hypot(points[i][0] - points[i - 1][0],
                         points[i][1] - points[i - 1][1])
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
            t = ((target - dists[j]) / (dists[j + 1] - dists[j])
                 if dists[j + 1] > dists[j] else 0)
            result.append((
                points[j][0] + t * (points[j + 1][0] - points[j][0]),
                points[j][1] + t * (points[j + 1][1] - points[j][1]),
            ))
    return result


def normalize_stroke(points, n=N_RESAMPLE):
    """
    Normalise a stroke to a canonical representation.

    Steps:
      1. Uniformly resample to *n* points.
      2. Scale so the larger dimension fits in [0, 1].
      3. Centre the centroid at the origin.

    Returns a list of ``(x, y)`` tuples.
    """
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


# ---------------------------------------------------------------------------
# Rotation
# ---------------------------------------------------------------------------

def rotate_points(points, angle):
    """Rotate every point in *points* by *angle* (radians) around the origin."""
    c, s = math.cos(angle), math.sin(angle)
    return [(x * c - y * s, x * s + y * c) for x, y in points]


# ---------------------------------------------------------------------------
# Distance / matching
# ---------------------------------------------------------------------------

def stroke_distance(a, b):
    """
    Rotation- and cyclic-shift-invariant distance between two strokes.

    Tries 12 equispaced rotations and *n* cyclic shifts, returning the
    minimum average pointwise Euclidean distance.
    """
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
    """
    Find the closest matching glyph for a normalised stroke.

    Parameters
    ----------
    normalized : list of (x, y)
        A stroke that has been run through :func:`normalize_stroke`.
    glyphs : list of dict
        Glyph entries with a ``"templates"`` key.

    Returns
    -------
    (best_glyph, best_dist)
        ``best_glyph`` is the dict of the closest match (or ``None``), and
        ``best_dist`` is the raw distance (lower is better).
    """
    if not glyphs or len(normalized) < 2:
        return None, float("inf")
    # Flip Y: user draws with screen-Y-down (top=-Y), templates stored with
    # Y-up (top=+Y).
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


# ---------------------------------------------------------------------------
# Misc geometry utilities
# ---------------------------------------------------------------------------

def compute_write_area(recognized, strokes):
    """
    Return the bounding box of all recognised glyph strokes and
    in-progress strokes, or ``None`` if no points exist yet.

    The returned tuple is ``(min_x, max_x, min_y, max_y)``.
    """
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
