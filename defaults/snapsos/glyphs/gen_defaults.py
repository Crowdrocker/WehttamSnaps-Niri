#!/usr/bin/env python3
"""Generate 46 rune-glyphs from the 7 anchor points only.
No immediate backtracking; revisiting allowed; diagonals preferred."""
import importlib.util, json, math, os, random

random.seed(42)

spec = importlib.util.spec_from_file_location("glyphs",
    os.path.join(os.path.dirname(__file__), "glyphs.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

normalize = mod.normalize_stroke

P = {"A":(0,20),"B":(-5,15),"C":(5,15),"D":(0,10),"E":(-5,5),"F":(5,5),"G":(0,0)}
ALL = list(P.keys())
ANCHORS = set("ABCDEFG")

def valid(p1, p2):
    dx = p2[0] - p1[0]; dy = p2[1] - p1[1]
    return (dx != 0 or dy != 0) and (dx == 0 or dy == 0 or abs(dx) == abs(dy))

def has_intermediate(p, q):
    x1, y1 = P[p]; x2, y2 = P[q]
    for r in ANCHORS:
        if r == p or r == q: continue
        x, y = P[r]
        if (x - x1) * (y2 - y1) != (y - y1) * (x2 - x1):
            continue
        dx = x2 - x1; dy = y2 - y1
        dxr = x - x1; dyr = y - y1
        if dxr * dx + dyr * dy > 0 and dxr*dxr + dyr*dyr < dx*dx + dy*dy:
            return True
    return False

ADJ = {l: [o for o in ALL if o != l and valid(P[l], P[o]) and not has_intermediate(l, o)] for l in ALL}

def enum_paths(max_len=7, min_len=6):
    out = []
    def dfs(cur):
        if len(cur) >= min_len and len(cur) <= max_len:
            out.append(list(cur))
        if len(cur) >= max_len:
            return
        for n in ADJ[cur[-1]]:
            if len(cur) >= 2 and n == cur[-2]:
                continue
            if n in cur:
                continue
            cur.append(n); dfs(cur); cur.pop()
    for l in ALL:
        dfs([l])
    return out

def simplicity(path):
    n = len(path); changes = 0; axis = 0
    for i in range(1, len(path)):
        dx = P[path[i]][0] - P[path[i-1]][0]
        dy = P[path[i]][1] - P[path[i-1]][1]
        if dx == 0 or dy == 0: axis += 1
    for i in range(2, len(path)):
        dx1=P[path[i-1]][0]-P[path[i-2]][0]; dy1=P[path[i-1]][1]-P[path[i-2]][1]
        dx2=P[path[i]][0]-P[path[i-1]][0];   dy2=P[path[i]][1]-P[path[i-1]][1]
        if abs(math.atan2(dy1,dx1)-math.atan2(dy2,dx2))>0.01: changes+=1
    return n, axis, changes

def mse_dist(a, b):
    n = min(len(a), len(b))
    fa = a if len(a)==n else mod.resample_points([(float(x),float(y)) for x,y in a], n)
    fb = b if len(b)==n else mod.resample_points([(float(x),float(y)) for x,y in b], n)
    best = float("inf")
    for ai in range(12):
        ang = ai * math.pi / 12
        c, s = math.cos(ang), math.sin(ang)
        rx = [x*c - y*s for x,y in fa]
        ry = [x*s + y*c for x,y in fa]
        for shift in range(n):
            d = 0.0
            for i in range(n):
                dx = rx[(i+shift)%n] - fb[i][0]
                dy = ry[(i+shift)%n] - fb[i][1]
                d += math.hypot(dx, dy)
            d /= n
            if d < best: best = d
    return best

print("Enumerating paths …")
cands = enum_paths(7, 6)
print(f"  {len(cands)} candidates")

def has_dir_change(path):
    dirs = set()
    for i in range(1, len(path)):
        dx=P[path[i]][0]-P[path[i-1]][0]; dy=P[path[i]][1]-P[path[i-1]][1]
        dirs.add((round(dx), round(dy)))
    return len(dirs) >= 2

cands = [p for p in cands if has_dir_change(p)]
print(f"  {len(cands)} after filtering straight lines")

cands.sort(key=simplicity)
cands = cands[:200]
print(f"  Top {len(cands)} candidates")

normed = [normalize([P[l] for l in p]) for p in cands]
print(f"Computing {len(cands)}×{len(cands)} distance matrix …")

n_all = len(normed)
D = [[0.0]*n_all for _ in range(n_all)]
for i in range(n_all):
    for j in range(i+1, n_all):
        d = mse_dist(normed[i], normed[j])
        D[i][j] = d; D[j][i] = d
    if (i+1) % 20 == 0:
        print(f"  row {i+1}/{n_all}")

NAMES = [
    "exec","start-string","capture-string",
    "killclient","togglefloating","togglefullscreen",
    "reload-config","quit","toggleoverview",
    "togglegaps","zoom","toggle-scratchpad",
    "focuslast","centerwin","viewtoleft","viewtoright",
    "ls","cd","rm","cp","mv","cat","grep","git","sudo",
    "clear","exit","echo","source","man","mkdir","chmod","find",
    "kill","ps","top","df","du","which","history","alias","export",
    "ssh","ping","killall","la","rf","h","btop","firefox",
    "ghostty","vesktop","code","steam","obsidian","nautilus",
    "unipkg","fetch","fetch-conf",
]

STRMAP = {
    "exec":"__mode_exec__","start-string":"__lbracket__","capture-string":"__rbracket__",
    "killclient":"mmsg dispatch killclient","togglefloating":"mmsg dispatch togglefloating",
    "togglefullscreen":"mmsg dispatch togglefullscreen",
    "reload-config":"mmsg dispatch reload_config","quit":"mmsg dispatch quit",
    "toggleoverview":"mmsg dispatch toggleoverview",
    "togglegaps":"mmsg dispatch togglegaps","zoom":"mmsg dispatch zoom",
    "toggle-scratchpad":"mmsg dispatch toggle_scratchpad",
    "focuslast":"mmsg dispatch focuslast","centerwin":"mmsg dispatch centerwin",
    "viewtoleft":"mmsg dispatch viewtoleft","viewtoright":"mmsg dispatch viewtoright",
    "la":"-la","rf":"-rf","h":"-h",
    "ghostty":"ghostty","firefox":"firefox","vesktop":"vesktop",
    "code":"code-oss","steam":"steam",
    "btop":"ghostty -e btop","obsidian":"obsidian","nautilus":"nautilus",
    "unipkg":"unipkg launch-tui","fetch":"fetch","fetch-conf":"fetch-conf",
}

print("Greedy selection …")
sel_idx = [0]
rem_idx = list(range(1, n_all))
while len(sel_idx) < len(NAMES) and rem_idx:
    best_ri = 0; best_d = -1
    for rii, ri in enumerate(rem_idx):
        md = min(D[ri][si] for si in sel_idx)
        if md > best_d: best_d = md; best_ri = rii
    sel_idx.append(rem_idx.pop(best_ri))

print(f"  Selected {len(sel_idx)} paths (min pair dist={best_d:.4f})")

min_all = float("inf")
for i in range(len(sel_idx)):
    for j in range(i+1, len(sel_idx)):
        d = D[sel_idx[i]][sel_idx[j]]
        if d < min_all: min_all = d
        if d < 0.12:
            print(f"  LOW: {sel_idx[i]} vs {sel_idx[j]}: {d:.4f}")
print(f"Min pairwise dist: {min_all:.4f}")

os.makedirs(mod.GLYPH_DIR, exist_ok=True)
for idx, name in enumerate(NAMES):
    path_labels = cands[sel_idx[idx]]
    raw = [P[l] for l in path_labels]
    base = normalize(raw)
    t1 = {"pts":[(float(x),float(y)) for x,y in base]}
    t2 = {"pts":[(x+random.uniform(-0.012,0.012),y+random.uniform(-0.012,0.012)) for x,y in base]}
    t3 = {"pts":[(x*random.uniform(0.96,1.04),y) for x,y in base]}
    g = {"name":name,"string":STRMAP.get(name,name),"templates":[t1,t2,t3]}
    mod.save_glyph(g)
    print(f"  {name:10s} → {STRMAP.get(name,name):20s}  ({len(path_labels)}p) {'→'.join(path_labels)}")

print(f"\nSaved {len(NAMES)} glyphs")
print(f"Min pairwise dist: {min_all:.4f}")
