"""
Grid-pin definitions and path-finding for the grid-snapped ``RecordOverlay``.

The recording grid is built from 7 anchor points (A–G) and additional
intermediate points, forming a graph that the user's stroke is snapped to.
"""

import math
from collections import deque


# ---------------------------------------------------------------------------
# Grid points
# ---------------------------------------------------------------------------

# The 7 base anchor positions (A–G) plus intermediates for 17 additional
# edge / interior points.  Coordinates are in a synthetic space roughly
# 20×30 units.
GRID_PTS = {
    "A":  (0, 20),   "B": (-5, 15),  "C": (5, 15),   "D": (0, 10),
    "E": (-5,  5),   "F": (5,  5),   "G": (0,  0),
    "U": (0, 25),    "V": (-5, 25),  "W": (5, 25),
    "X": (-10, 15),  "Y": (10, 15),  "Z": (0, 15),
    "AA": (-10, 5),  "AB": (10, 5),  "AC": (0, -5),
    "AD": (-10, 20), "AE": (10, 20),
    "AF": (-10, 0),  "AG": (10, 0),
}

# The 7 labelled anchor points that are drawn prominently in the UI
GRID_ANCHORS = set("ABCDEFG")


# ---------------------------------------------------------------------------
# Adjacency
# ---------------------------------------------------------------------------

def _grid_edge_ok(p, q):
    """Return ``True`` if the directed edge from *p* to *q* is axis-aligned
    or diagonal (45°).  Zero-length edges are rejected."""
    dx = q[0] - p[0]
    dy = q[1] - p[1]
    return (dx != 0 or dy != 0) and (dx == 0 or dy == 0 or abs(dx) == abs(dy))


# Build adjacency list: each key maps to every other key that shares a
# valid edge.
GRID_ADJ = {}
for k, p in GRID_PTS.items():
    GRID_ADJ[k] = [o for o in GRID_PTS if o != k and _grid_edge_ok(p, GRID_PTS[o])]


# Bounding box of the entire grid, used for coordinate transforms
GRID_BOUNDS = (
    min(p[0] for p in GRID_PTS.values()),   # min_x = -10
    max(p[0] for p in GRID_PTS.values()),   # max_x =  10
    min(p[1] for p in GRID_PTS.values()),   # min_y =  -5
    max(p[1] for p in GRID_PTS.values()),   # max_y =  25
)


# ---------------------------------------------------------------------------
# Path finding (BFS)
# ---------------------------------------------------------------------------

def _bfs_path(start, end):
    """Shortest path (by number of edges) from *start* to *end* through the
    grid graph, returning a list of node labels, or ``None`` if no path exists.

    Uses breadth-first search since the graph is small and unweighted.
    """
    q = deque([start])
    parent = {start: None}
    while q:
        cur = q.popleft()
        if cur == end:
            path = []
            while cur is not None:
                path.append(cur)
                cur = parent[cur]
            return path[::-1]
        for n in GRID_ADJ[cur]:
            if n not in parent:
                parent[n] = cur
                q.append(n)
    return None
