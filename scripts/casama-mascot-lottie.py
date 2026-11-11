"""Converts the animated Casama cloud bot SVGs into Lottie files the app plays natively at full frame rate.

Run from the repo root after scripts/casama-cloud-svg.py:
    python3 scripts/casama-mascot-lottie.py [name ...]
Reads client/assets/bots/casama-<name>-animated.svg and writes client/assets/mascots/<name>.json.
Needs Pillow, Node and Google Chrome (the cloud body is baked by scripts/casama-mascot-render.mjs).

How the SVG maps onto Lottie:
- Paths, ellipses, circles, rects, colours, gradients and strokes become shape groups. CSS keyframes (with their
  transform-origin and cubic-bezier easing) and the SMIL tail morph become Lottie keyframes with the same easing,
  so the motion is identical but drawn at the screen's frame rate.
- A clip-path becomes a layer mask (eyes, lids, mouth). That layer lives in the clipped group's space, hangs off
  null layers carrying the ancestor transforms, and clips higher up are mapped into its space.
- A static group with a filter (the cloud body: lift shadow, puff shading, soft highlight) is baked into one
  image. An animated path with a drop shadow (the tail) gets a slightly offset dark copy instead.
"""
import base64, io, json, math, os, re, subprocess, sys, tempfile
from xml.etree import ElementTree as ET

from PIL import Image

NS = '{http://www.w3.org/2000/svg}'
ET.register_namespace('', NS[1:-1])
SRC, OUT = 'client/assets/bots', 'client/assets/mascots'
FR = 60              # Lottie frames per second (keyframe times are in frames)
LOOP = 8.0           # seconds, T in casama-cloud-svg.py
OP = int(LOOP * FR)
BAKE_PX = 2          # pixels per SVG unit in baked images
LINEAR = (0.0, 0.0, 1.0, 1.0)


def tag(e):
    return e.tag.replace(NS, '')


def rnd(v, n=2):
    v = round(v, n)
    return int(v) if v == int(v) else v


# ---------------------------------------------------------------- timing
def bezier_y(e, u):
    """CSS cubic-bezier(x1,y1,x2,y2) at progress u."""
    x1, y1, x2, y2 = e
    if e == LINEAR:
        return u
    bx = lambda s: 3 * (1 - s) ** 2 * s * x1 + 3 * (1 - s) * s * s * x2 + s ** 3
    by = lambda s: 3 * (1 - s) ** 2 * s * y1 + 3 * (1 - s) * s * s * y2 + s ** 3
    lo, hi = 0.0, 1.0
    for _ in range(40):
        mid = (lo + hi) / 2
        if bx(mid) < u:
            lo = mid
        else:
            hi = mid
    return by((lo + hi) / 2)


class KF:
    """An animated value: keys are (t in frames, [values], easing of the segment that starts there)."""

    def __init__(self, keys):
        out = []
        for k in sorted(keys, key=lambda k: k[0]):
            if out and abs(out[-1][0] - k[0]) < 1e-6:
                out[-1] = k
            else:
                out.append(k)
        self.keys = out

    def at(self, t):
        ks = self.keys
        if t <= ks[0][0]:
            return list(ks[0][1])
        for (t0, v0, e), (t1, v1, _) in zip(ks, ks[1:]):
            if t <= t1:
                u = bezier_y(e, (t - t0) / (t1 - t0))
                return [a + (b - a) * u for a, b in zip(v0, v1)]
        return list(ks[-1][1])

    def times(self):
        return [k[0] for k in self.keys]

    def constant(self):
        return all(k[1] == self.keys[0][1] for k in self.keys)

    def map(self, fn):
        return KF([(t, fn(v), e) for t, v, e in self.keys])


def val_at(v, t):
    return v.at(t) if isinstance(v, KF) else list(v)


def prop(v, n=2):
    """Lottie property from a static list or a KF."""
    if isinstance(v, KF):
        if v.constant():
            return prop(v.keys[0][1], n)
        ks = []
        for i, (t, val, e) in enumerate(v.keys):
            k = {'t': rnd(t, 3), 's': [rnd(x, n) for x in val]}
            if i < len(v.keys) - 1:
                k['o'] = {'x': rnd(e[0], 3), 'y': rnd(e[1], 3)}
                k['i'] = {'x': rnd(e[2], 3), 'y': rnd(e[3], 3)}
            ks.append(k)
        return {'a': 1, 'k': ks}
    v = [rnd(x, n) for x in v]
    return {'a': 0, 'k': v[0] if len(v) == 1 else v}


def shape_prop(v):
    """Lottie path property from a static shape dict or a KF over flattened shapes."""
    if isinstance(v, KF):
        ks = []
        for i, (t, flat, e) in enumerate(v.keys):
            k = {'t': rnd(t, 3), 's': [unflatten(flat, v.proto)]}
            if i < len(v.keys) - 1:
                k['o'] = {'x': rnd(e[0], 3), 'y': rnd(e[1], 3)}
                k['i'] = {'x': rnd(e[2], 3), 'y': rnd(e[3], 3)}
            ks.append(k)
        return {'a': 1, 'k': ks}
    return {'a': 0, 'k': v}


def parse_ease(s):
    s = s.strip()
    if s == 'linear':
        return LINEAR
    if s == 'ease':
        return (.25, .1, .25, 1)
    if s == 'ease-in-out':
        return (.42, 0, .58, 1)
    m = re.match(r'cubic-bezier\(([^)]*)\)', s)
    return tuple(float(x) for x in m.group(1).split(','))


# ---------------------------------------------------------------- geometry
def mat_mul(a, b):
    """2D affine [a b c d e f] (SVG order): a*b."""
    return [a[0] * b[0] + a[2] * b[1], a[1] * b[0] + a[3] * b[1],
            a[0] * b[2] + a[2] * b[3], a[1] * b[2] + a[3] * b[3],
            a[0] * b[4] + a[2] * b[5] + a[4], a[1] * b[4] + a[3] * b[5] + a[5]]


def mat_inv(m):
    a, b, c, d, e, f = m
    det = a * d - b * c
    return [d / det, -b / det, -c / det, a / det, (c * f - d * e) / det, (b * e - a * f) / det]


def mat_apply(m, p):
    return (m[0] * p[0] + m[2] * p[1] + m[4], m[1] * p[0] + m[3] * p[1] + m[5])


IDENT = [1, 0, 0, 1, 0, 0]


def trs_matrix(a, p, s, r):
    """Lottie transform: translate(p) rotate(r) scale(s) translate(-a)."""
    rad = math.radians(r)
    cs, sn = math.cos(rad), math.sin(rad)
    m = [1, 0, 0, 1, p[0], p[1]]
    m = mat_mul(m, [cs, sn, -sn, cs, 0, 0])
    m = mat_mul(m, [s[0] / 100, 0, 0, s[1] / 100, 0, 0])
    return mat_mul(m, [1, 0, 0, 1, -a[0], -a[1]])


def num_list(s):
    return [float(x) for x in re.findall(r'-?\d*\.?\d+(?:e-?\d+)?', s)]


def parse_transform_attr(s):
    """SVG transform attribute -> list of (a, p, s, r) static Lottie transforms, outermost first."""
    out = []
    for fn, args in re.findall(r'(\w+)\(([^)]*)\)', s or ''):
        v = num_list(args)
        if fn == 'translate':
            out.append(([0, 0], [v[0], v[1] if len(v) > 1 else 0], [100, 100], 0))
        elif fn == 'rotate':
            c = v[1:3] if len(v) == 3 else [0, 0]
            out.append((c, c, [100, 100], v[0]))
        elif fn == 'scale':
            out.append(([0, 0], [0, 0], [v[0] * 100, (v[1] if len(v) > 1 else v[0]) * 100], 0))
        else:
            raise ValueError(f'transform {fn}')
    return out


def path_to_subpaths(d):
    """SVG path data (absolute commands) -> list of (points, closed) where points are cubic segments:
    [p0, (c1, c2, p1), (c1, c2, p2), ...]."""
    toks = re.findall(r'[MLHVCSQTAZmlhvcsqtaz]|-?\d*\.?\d+(?:e-?\d+)?', d)
    i, subs, cur, start, pts = 0, [], (0, 0), (0, 0), None
    last_q, last_c, cmd = None, None, None

    def nums(n):
        nonlocal i
        v = [float(x) for x in toks[i:i + n]]
        i += n
        return v

    def line(p):
        nonlocal cur
        pts.append((cur, p, p))
        cur = p

    while i < len(toks):
        if re.match(r'[A-Za-z]', toks[i]):
            cmd = toks[i]
            i += 1
        assert cmd == cmd.upper() or cmd in 'zZ', f'relative path command {cmd}'
        if cmd == 'M':
            x, y = nums(2)
            if pts:
                subs.append((pts, False))
            cur = start = (x, y)
            pts = [cur]
            cmd = 'L'
            last_q = last_c = None
            continue
        if cmd in 'Zz':
            if cur != start:
                line(start)
            subs.append((pts, True))
            pts, cur = None, start
            last_q = last_c = None
            continue
        if cmd == 'L':
            line(tuple(nums(2)))
            last_q = last_c = None
        elif cmd == 'H':
            line((nums(1)[0], cur[1]))
            last_q = last_c = None
        elif cmd == 'V':
            line((cur[0], nums(1)[0]))
            last_q = last_c = None
        elif cmd == 'C':
            x1, y1, x2, y2, x, y = nums(6)
            pts.append(((x1, y1), (x2, y2), (x, y)))
            last_c, last_q, cur = (x2, y2), None, (x, y)
        elif cmd == 'S':
            x2, y2, x, y = nums(4)
            c1 = (2 * cur[0] - last_c[0], 2 * cur[1] - last_c[1]) if last_c else cur
            pts.append((c1, (x2, y2), (x, y)))
            last_c, last_q, cur = (x2, y2), None, (x, y)
        elif cmd in 'QT':
            if cmd == 'Q':
                qx, qy, x, y = nums(4)
            else:
                x, y = nums(2)
                qx, qy = (2 * cur[0] - last_q[0], 2 * cur[1] - last_q[1]) if last_q else cur
            c1 = (cur[0] + 2 / 3 * (qx - cur[0]), cur[1] + 2 / 3 * (qy - cur[1]))
            c2 = (x + 2 / 3 * (qx - x), y + 2 / 3 * (qy - y))
            pts.append((c1, c2, (x, y)))
            last_q, last_c, cur = (qx, qy), None, (x, y)
        elif cmd == 'A':
            rx, ry, rot, large, sweep, x, y = nums(7)
            for seg in arc_to_cubics(cur, (x, y), rx, ry, rot, int(large), int(sweep)):
                pts.append(seg)
            cur = (x, y)
            last_q = last_c = None
        else:
            raise ValueError(cmd)
    if pts and len(pts) > 1:
        subs.append((pts, False))
    return subs


def arc_to_cubics(p0, p1, rx, ry, phi, fa, fs):
    """SVG elliptical arc -> cubic segments (c1, c2, p)."""
    if rx == 0 or ry == 0:
        return [(p0, p1, p1)]
    phi = math.radians(phi)
    cp, sp = math.cos(phi), math.sin(phi)
    dx, dy = (p0[0] - p1[0]) / 2, (p0[1] - p1[1]) / 2
    x1p, y1p = cp * dx + sp * dy, -sp * dx + cp * dy
    rx, ry = abs(rx), abs(ry)
    lam = x1p ** 2 / rx ** 2 + y1p ** 2 / ry ** 2
    if lam > 1:
        rx, ry = rx * math.sqrt(lam), ry * math.sqrt(lam)
    num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
    den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
    co = math.sqrt(max(0, num / den)) * (-1 if fa == fs else 1)
    cxp, cyp = co * rx * y1p / ry, -co * ry * x1p / rx
    cx = cp * cxp - sp * cyp + (p0[0] + p1[0]) / 2
    cy = sp * cxp + cp * cyp + (p0[1] + p1[1]) / 2
    ang = lambda ux, uy, vx, vy: math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)
    t1 = ang(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
    dt = ang((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
    if not fs and dt > 0:
        dt -= 2 * math.pi
    elif fs and dt < 0:
        dt += 2 * math.pi
    n = max(1, math.ceil(abs(dt) / (math.pi / 2)))
    d = dt / n
    k = 4 / 3 * math.tan(d / 4)
    pt = lambda t: (cx + rx * math.cos(t) * cp - ry * math.sin(t) * sp, cy + rx * math.cos(t) * sp + ry * math.sin(t) * cp)
    dv = lambda t: (-rx * math.sin(t) * cp - ry * math.cos(t) * sp, -rx * math.sin(t) * sp + ry * math.cos(t) * cp)
    segs = []
    for j in range(n):
        a, b = t1 + j * d, t1 + (j + 1) * d
        pa, pb, da, db = pt(a), pt(b), dv(a), dv(b)
        segs.append(((pa[0] + k * da[0], pa[1] + k * da[1]), (pb[0] - k * db[0], pb[1] - k * db[1]), pb))
    segs[-1] = (segs[-1][0], segs[-1][1], p1)
    return segs


def lottie_shape(sub):
    """(points, closed) -> Lottie shape {v, i, o, c} with tangents relative to their vertex."""
    pts, closed = sub
    v = [pts[0]]
    ins = [(0, 0)]
    outs = []
    for c1, c2, p in pts[1:]:
        prev = v[-1]
        outs.append((c1[0] - prev[0], c1[1] - prev[1]))
        v.append(p)
        ins.append((c2[0] - p[0], c2[1] - p[1]))
    outs.append((0, 0))
    if closed and len(v) > 1 and abs(v[-1][0] - v[0][0]) < 1e-3 and abs(v[-1][1] - v[0][1]) < 1e-3:
        ins[0] = ins[-1]
        v, ins, outs = v[:-1], ins[:-1], outs[:-1]
    r = lambda ps: [[rnd(x), rnd(y)] for x, y in ps]
    return {'c': closed, 'v': r(v), 'i': r(ins), 'o': r(outs)}


def ellipse_shape(cx, cy, rx, ry):
    k = 0.5522847498
    return {'c': True, 'v': [[cx, cy - ry], [cx + rx, cy], [cx, cy + ry], [cx - rx, cy]],
            'i': [[-rx * k, 0], [0, -ry * k], [rx * k, 0], [0, ry * k]],
            'o': [[rx * k, 0], [0, ry * k], [-rx * k, 0], [0, -ry * k]]}


def flatten(shape):
    return [c for key in ('v', 'i', 'o') for p in shape[key] for c in p]


def unflatten(flat, proto):
    n = len(proto['v'])
    pts = [[rnd(flat[j]), rnd(flat[j + 1])] for j in range(0, len(flat), 2)]
    return {'c': proto['c'], 'v': pts[:n], 'i': pts[n:2 * n], 'o': pts[2 * n:]}


def map_shape(shape, m):
    """Apply an affine matrix to a Lottie shape (tangents use the linear part only)."""
    lin = [m[0], m[1], m[2], m[3], 0, 0]
    return {'c': shape['c'], 'v': [list(mat_apply(m, p)) for p in shape['v']],
            'i': [list(mat_apply(lin, p)) for p in shape['i']], 'o': [list(mat_apply(lin, p)) for p in shape['o']]}


# ---------------------------------------------------------------- colours and gradients
def color(c):
    c = c.strip().lstrip('#')
    if len(c) == 3:
        c = ''.join(x * 2 for x in c)
    return [rnd(int(c[i:i + 2], 16) / 255, 4) for i in (0, 2, 4)]


class Doc:
    def __init__(self, path):
        self.text = open(path).read()
        self.root = ET.fromstring(self.text)
        self.parent = {c: p for p in self.root.iter() for c in p}
        self.grads, self.clips, self.filters = {}, {}, {}
        for e in self.root.iter():
            t, i = tag(e), e.get('id')
            if t in ('linearGradient', 'radialGradient'):
                self.grads[i] = e
            elif t == 'clipPath':
                self.clips[i] = e
            elif t == 'filter':
                self.filters[i] = e
        style = ''.join(s.text or '' for s in self.root.iter(NS + 'style'))
        self.keyframes = {}
        for m in re.finditer(r'@keyframes\s+([\w-]+)\s*\{((?:[^{}]*\{[^}]*\})*)\s*\}', style):
            frames = []
            for pm in re.finditer(r'([\d.]+)%\s*\{([^}]*)\}', m.group(2)):
                props = dict(kv.split(':', 1) for kv in pm.group(2).split(';') if ':' in kv)
                frames.append((float(pm.group(1)), props))
            self.keyframes[m.group(1)] = frames
        body = re.sub(r'@keyframes\s+[\w-]+\s*\{(?:[^{}]*\{[^}]*\})*\s*\}', '', style)
        body = re.sub(r'@media[^{]*\{(?:[^{}]*\{[^}]*\})*\s*\}', '', body)
        self.rules = {}
        for m in re.finditer(r'\.([\w-]+)\s*\{([^}]*)\}', body):
            props = dict((k.strip(), v.strip()) for k, v in (kv.split(':', 1) for kv in m.group(2).split(';') if ':' in kv))
            self.rules.setdefault(m.group(1), {}).update(props)

    def ref(self, url):
        m = re.match(r'url\(#([^)]+)\)', url or '')
        return m.group(1) if m else None


def gradient_item(doc, gid, bbox, kind):
    """Lottie gradient fill (kind 'gf') for gradient id, in the element's local space. bbox=(x, y, w, h)."""
    g = doc.grads[gid]
    stops = [(float(s.get('offset')), color(s.get('stop-color')), float(s.get('stop-opacity', 1)))
             for s in g if tag(s) == 'stop']
    units = g.get('gradientUnits', 'objectBoundingBox')
    bx, by, bw, bh = bbox

    def pt(fx, fy):
        return (fx, fy) if units == 'userSpaceOnUse' else (bx + fx * bw, by + fy * bh)

    if tag(g) == 'linearGradient':
        s = pt(float(g.get('x1', 0)), float(g.get('y1', 0)))
        e = pt(float(g.get('x2', 1)), float(g.get('y2', 0)))
        t = 1
    else:
        cx, cy, r = float(g.get('cx', .5)), float(g.get('cy', .5)), float(g.get('r', .5))
        s = pt(cx, cy)
        rad = r if units == 'userSpaceOnUse' else r * bw  # callers make the bbox square for radial gradients
        e = (s[0] + rad, s[1])
        t = 2
    k = [x for off, c, _ in stops for x in (rnd(off, 4), *c)] + [x for off, _, a in stops for x in (rnd(off, 4), rnd(a, 3))]
    item = {'ty': kind, 'o': prop([100]), 'r': 1, 's': prop(list(s)), 'e': prop(list(e)), 't': t,
            'g': {'p': len(stops), 'k': {'a': 0, 'k': k}}}
    if t == 2:
        item['h'] = prop([0])
        item['a'] = prop([0])
    return item


# ---------------------------------------------------------------- animation of one element
def css_anim(doc, el):
    """(transform spec, opacity) for an element from CSS keyframes / SMIL, or None for each."""
    tf = op = None
    classes = (el.get('class') or '').split()
    for cls in classes:
        rule = doc.rules.get(cls, {})
        if 'animation' not in rule:
            continue
        parts = rule['animation'].split()
        name, dur = parts[0], float(parts[1].rstrip('s'))
        ease = parse_ease(' '.join(parts[2:-1])) if len(parts) > 3 else (.25, .1, .25, 1)
        origin = [0.0, 0.0]
        if 'transform-origin' in rule:
            origin = [float(x.rstrip('px')) for x in rule['transform-origin'].split()]
        frames = doc.keyframes[name]
        reps = round(LOOP / dur)
        keys_t, keys_o = [], []
        has_t = any('transform' in p for _, p in frames)
        has_o = any('opacity' in p for _, p in frames)
        wraps = frames[0][1] != frames[-1][1]  # e.g. a spin from 0 to 360deg restarts at 0 every cycle
        for rep in range(reps):
            for pct, props in frames:
                t = (rep * dur + pct / 100 * dur) * FR
                if rep and pct == 0:
                    if not wraps:
                        continue
                    t += 0.01
                e = parse_ease(props['animation-timing-function']) if 'animation-timing-function' in props else ease
                if has_t:
                    x = y = r = 0.0
                    sx = sy = 1.0
                    for fn, args in re.findall(r'(\w+)\(([^)]*)\)', props.get('transform', '')):
                        v = num_list(args)
                        if fn == 'translate':
                            x, y = v[0], v[1] if len(v) > 1 else 0
                        elif fn == 'rotate':
                            r = v[0]
                        elif fn == 'scale':
                            sx, sy = v[0], v[1] if len(v) > 1 else v[0]
                    keys_t.append((t, [origin[0] + x, origin[1] + y, r, sx * 100, sy * 100], e))
                if has_o:
                    keys_o.append((t, [float(props.get('opacity', 1)) * 100], e))
        if has_t:
            kf = KF(keys_t)
            still = lambda k: list(k.keys[0][1]) if k.constant() else k
            tf = {'a': origin, 'p': still(kf.map(lambda v: v[:2])), 'r': still(kf.map(lambda v: v[2:3])), 's': still(kf.map(lambda v: v[3:5]))}
        if has_o:
            op = KF(keys_o)
    for a in el:
        if tag(a) == 'animateTransform':
            assert a.get('type') == 'translate'
            tf = {'a': [0, 0], 'p': smil_kf(a, lambda s: num_list(s)), 'r': [0], 's': [100, 100]}
    return tf, op


def smil_kf(a, parse):
    assert float(a.get('dur').rstrip('s')) == LOOP and a.get('calcMode') == 'spline'
    times = [float(x) for x in a.get('keyTimes').split(';')]
    vals = [parse(v) for v in a.get('values').split(';')]
    splines = [tuple(float(x) for x in s.split()) for s in a.get('keySplines').split(';')]
    return KF([(t * LOOP * FR, v, splines[i] if i < len(splines) else LINEAR) for i, (t, v) in enumerate(zip(times, vals))])


# ---------------------------------------------------------------- tree model
class Node:
    """One SVG element with its own transforms (outermost first), opacity and clip."""

    def __init__(self, doc, el, parent):
        self.el, self.parent, self.doc = el, parent, doc
        self.kind = tag(el)
        tf, op = css_anim(doc, el)
        self.transforms = [tf] if tf else [{'a': a, 'p': p, 's': s, 'r': [r]} for a, p, s, r in parse_transform_attr(el.get('transform'))]
        if op is not None:
            self.opacity = op
        else:
            self.opacity = [float(el.get('opacity', 1)) * 100]
        self.clip = doc.ref(el.get('clip-path'))
        self.filter = doc.ref(el.get('filter'))
        self.children = []
        self.uid = None

    def animated(self):
        return any(isinstance(v, KF) for t in self.transforms for v in t.values()) or isinstance(self.opacity, KF)

    def matrix_at(self, t):
        m = IDENT
        for tr in self.transforms:
            m = mat_mul(m, trs_matrix(val_at(tr['a'], t), val_at(tr['p'], t), val_at(tr['s'], t), val_at(tr['r'], t)[0]))
        return m

    def kf_times(self):
        ts = set()
        for tr in self.transforms:
            for v in tr.values():
                if isinstance(v, KF):
                    ts.update(v.times())
        return ts

    def subtree_static(self):
        return not self.animated() and not any(tag(a) in ('animate', 'animateTransform') for a in self.el) and \
            all(c.subtree_static() for c in self.children)


SKIP = {'defs', 'style', 'title', 'clipPath', 'animate', 'animateTransform', 'desc'}
STYLE_KEYS = ('fill', 'stroke', 'stroke-width', 'stroke-linecap', 'stroke-linejoin', 'fill-opacity', 'stroke-opacity')


def build(doc, el, parent=None, style=None):
    style = dict(style or {'fill': '#000000'})
    for k in STYLE_KEYS:
        if el.get(k) is not None:
            style[k] = el.get(k)
    n = Node(doc, el, parent)
    n.style = style
    for c in el:
        if tag(c) in SKIP or 'still' in (c.get('class') or '').split():
            continue
        n.children.append(build(doc, c, n, style))
    return n


# ---------------------------------------------------------------- converter
class Converter:
    def __init__(self, doc, name, tmp):
        self.doc, self.name, self.tmp = doc, name, tmp
        self.layers, self.nulls, self.images = [], {}, []
        self.ind = 0
        self.bakes = []  # (node, image id)

    def next_ind(self):
        self.ind += 1
        return self.ind

    # -- leaf geometry
    def geometry(self, n):
        """Lottie shape items for a leaf (no style) and its local bbox."""
        e, k = n.el, n.kind
        if k in ('ellipse', 'circle'):
            cx, cy = float(e.get('cx', 0)), float(e.get('cy', 0))
            rx = float(e.get('r') if k == 'circle' else e.get('rx'))
            ry = float(e.get('r') if k == 'circle' else e.get('ry'))
            return [{'ty': 'el', 'p': prop([cx, cy]), 's': prop([2 * rx, 2 * ry]), 'd': 1}], (cx - rx, cy - ry, 2 * rx, 2 * ry)
        if k == 'rect':
            x, y, w, h = (float(e.get(a, 0)) for a in ('x', 'y', 'width', 'height'))
            return [{'ty': 'rc', 'p': prop([x + w / 2, y + h / 2]), 's': prop([w, h]), 'r': prop([float(e.get('rx', 0))]), 'd': 1}], (x, y, w, h)
        if k == 'path':
            subs = [lottie_shape(s) for s in path_to_subpaths(e.get('d'))]
            morph = [a for a in e if tag(a) == 'animate' and a.get('attributeName') == 'd']
            items = []
            if morph:
                a = morph[0]
                per_key = [[lottie_shape(s) for s in path_to_subpaths(v)] for v in a.get('values').split(';')]
                kf_all = smil_kf(a, lambda s: s)  # times + splines; values replaced below
                for si, proto in enumerate(per_key[0]):
                    kf = KF([(t, flatten(per_key[j][si]), ease) for j, (t, _, ease) in enumerate(kf_all.keys)])
                    kf.proto = proto
                    items.append({'ty': 'sh', 'ks': shape_prop(kf), 'd': 1})
                pts = [p for shapes in per_key for s in shapes for p in s['v']]
            else:
                items = [{'ty': 'sh', 'ks': shape_prop(s), 'd': 1} for s in subs]
                pts = [p for s in subs for p in s['v']]
            xs, ys = [p[0] for p in pts], [p[1] for p in pts]
            return items, (min(xs), min(ys), max(xs) - min(xs), max(ys) - min(ys))
        raise ValueError(f'unsupported element {k}')

    def style_items(self, n, bbox):
        st, items = n.style, []
        stroke = st.get('stroke')
        if stroke and stroke != 'none':
            line = {'w': prop([float(st.get('stroke-width', 1))]),
                    'lc': {'butt': 1, 'round': 2, 'square': 3}[st.get('stroke-linecap', 'butt')],
                    'lj': {'miter': 1, 'round': 2, 'bevel': 3}[st.get('stroke-linejoin', 'miter')], 'ml': 4}
            gid = self.doc.ref(stroke)
            if gid:
                items.append({**gradient_item(self.doc, gid, bbox, 'gs'), **line})
            else:
                items.append({'ty': 'st', 'c': prop(color(stroke) + [1], 4), 'o': prop([float(st.get('stroke-opacity', 1)) * 100]), **line})
        fill = st.get('fill')
        if fill and fill != 'none':
            gid = self.doc.ref(fill)
            if gid:
                items.append(gradient_item(self.doc, gid, bbox, 'gf'))
            else:
                items.append({'ty': 'fl', 'c': prop(color(fill) + [1], 4), 'o': prop([float(st.get('fill-opacity', 1)) * 100]), 'r': 1})
        return items

    def leaf_group(self, n):
        """A shape group for one leaf element (its own transform and opacity included)."""
        geo, bbox = self.geometry(n)
        fill_ref = self.doc.ref(n.style.get('fill'))
        inner_tr = None
        if fill_ref and tag(self.doc.grads[fill_ref]) == 'radialGradient' and \
                self.doc.grads[fill_ref].get('gradientUnits', 'objectBoundingBox') != 'userSpaceOnUse' and abs(bbox[2] - bbox[3]) > 1e-3:
            # A bounding-box radial gradient is elliptical in SVG but circular in Lottie: draw the shape squashed
            # to a square box and stretch the group back.
            bx, by, bw, bh = bbox
            cy = by + bh / 2
            k = bw / bh
            sq = [1, 0, 0, k, 0, cy - k * cy]
            geo = [self.squash_item(g, sq) for g in geo]
            bbox = (bx, cy - bw / 2, bw, bw)
            inner_tr = tr_item({'a': [0, cy], 'p': [0, cy], 's': [100, 100 / k], 'r': [0]}, [100])
        items = geo + self.style_items(n, bbox)
        if inner_tr:
            items = [{'ty': 'gr', 'it': items + [inner_tr], 'nm': 'squash'}]
        out = items
        if n.filter and self.drop_shadow(n.filter):
            dx, dy, col, alpha = self.drop_shadow(n.filter)
            geo_copy = [json.loads(json.dumps(g)) for g in geo]
            shadow = {'ty': 'gr', 'nm': 'edge', 'it': geo_copy + [{'ty': 'fl', 'c': prop(color(col) + [1], 4), 'o': prop([alpha * 70]), 'r': 1},
                                                                      tr_item({'a': [0, 0], 'p': [dx, dy], 's': [100, 100], 'r': [0]}, [100])]}
            out = [{'ty': 'gr', 'nm': 'main', 'it': items + [tr_item(None, [100])]}, shadow]
        return self.wrap(n, out)

    def squash_item(self, g, m):
        g = json.loads(json.dumps(g))
        if g['ty'] == 'el':
            (cx, cy), (w, h) = g['p']['k'], g['s']['k']
            nc = mat_apply(m, (cx, cy))
            g['p'], g['s'] = prop(list(nc)), prop([w, h * m[3]])
        elif g['ty'] == 'sh':
            assert g['ks']['a'] == 0
            g['ks'] = shape_prop(map_shape(g['ks']['k'], m))
        else:
            raise ValueError('radial bbox gradient on rect')
        return g

    def drop_shadow(self, fid):
        f = self.doc.filters[fid]
        prims = [c for c in f if tag(c) != 'feMerge']
        if len(prims) == 1 and tag(prims[0]) == 'feDropShadow':
            p = prims[0]
            return float(p.get('dx', 0)), float(p.get('dy', 0)), p.get('flood-color'), float(p.get('flood-opacity', 1))
        return None

    def wrap(self, n, items):
        """Wrap shape items in the node's own transforms and opacity (as nested shape groups)."""
        trs = n.transforms or [None]
        for i, tr in enumerate(reversed(trs)):
            opacity = n.opacity if i == len(trs) - 1 else [100]
            items = [{'ty': 'gr', 'nm': n.el.get('class') or n.kind, 'it': items + [tr_item(tr, opacity)]}]
        return items

    # -- tree walk
    def convert(self):
        root = build(self.doc, self.doc.root)
        self.runs = []  # (anchor node, [leaf nodes])
        self.collect(root, root)
        for anchor, items in self.runs:
            self.emit_run(anchor, items)
        return root

    def collect(self, n, anchor):
        """Walk in paint order, grouping leaves into runs that share a layer anchor."""
        if n.filter and (n.children or not self.drop_shadow(n.filter)):
            assert n.subtree_static(), f'filter {n.filter} on an animated element'
            self.add_run(None, ('bake', n))
            return
        if n.clip and n is not anchor:
            anchor = n
        if not n.children and n.kind != 'g':
            self.add_run(anchor, ('leaf', n))
            return
        for c in n.children:
            self.collect(c, anchor)

    def add_run(self, anchor, item):
        if item[0] == 'leaf' and self.runs and self.runs[-1][0] is anchor and self.runs[-1][1][-1][0] == 'leaf':
            self.runs[-1][1].append(item)
        else:
            self.runs.append((anchor, [item]))

    def chain(self, n):
        """Ancestors from the root down to n (inclusive)."""
        out = []
        while n is not None:
            out.append(n)
            n = n.parent
        return out[::-1]

    def emit_run(self, anchor, items):
        if items[0][0] == 'bake':
            return self.emit_bake(items[0][1])
        # Shapes: nested groups for everything between the anchor (exclusive) and each leaf.
        top = []
        open_groups = []  # (node, items list)
        for _, leaf in items:
            path = self.chain(leaf)
            path = path[path.index(anchor) + 1:-1] if anchor is not leaf else []
            # close groups not shared
            depth = 0
            while depth < len(open_groups) and depth < len(path) and open_groups[depth][0] is path[depth]:
                depth += 1
            del open_groups[depth:]
            for g in path[depth:]:
                container = open_groups[-1][1] if open_groups else top
                lst = []
                container.append((g, lst))
                open_groups.append((g, lst))
            container = open_groups[-1][1] if open_groups else top
            if anchor is leaf:
                geo, bbox = self.geometry(leaf)
                container.append((None, geo + self.style_items(leaf, bbox)))
            else:
                container.append((None, self.leaf_group(leaf)))
        shapes = self.materialize(top)
        layer = self.shape_layer(shapes, anchor)
        self.layers.append(layer)

    def materialize(self, entries):
        """[(group node, children entries) | (None, items)] in paint order -> Lottie items (top first)."""
        out = []
        for node, sub in entries:
            if node is None:
                out.append(sub)
            else:
                out.append(self.wrap(node, self.materialize(sub)))
        flat = []
        for chunk in reversed(out):
            flat.extend(chunk)
        return flat

    def layer_space(self, anchor):
        """Null-layer parent for an anchor's space and the opacity of everything from the root to it."""
        path = self.chain(anchor)
        parent = None
        for n in path:
            if n.transforms:
                parent = self.null_for(n, parent)
        opacity = self.opacity_product(path)
        return parent, opacity

    def null_for(self, n, parent):
        key = id(n)
        if key in self.nulls:
            return self.nulls[key]
        ind = parent
        for tr in n.transforms:
            i = self.next_ind()
            layer = {'ddd': 0, 'ind': i, 'ty': 3, 'nm': f'null {n.el.get("class") or n.kind}', 'sr': 1, 'ao': 0,
                     'ks': ks_item(tr, [100]), 'ip': 0, 'op': OP, 'st': 0, 'bm': 0}
            if ind is not None:
                layer['parent'] = ind
            self.null_layers.append(layer)
            ind = i
        self.nulls[key] = ind
        return ind

    def opacity_product(self, path):
        static, anims = 1.0, []
        for n in path:
            if isinstance(n.opacity, KF):
                anims.append(n.opacity)
            else:
                static *= n.opacity[0] / 100
        if not anims:
            return [static * 100]
        if len(anims) == 1:
            return anims[0].map(lambda v: [v[0] * static])
        ts = [t / 2 for t in range(0, OP * 2 + 1)]
        return KF([(t, [static * 100 * math.prod(a.at(t)[0] / 100 for a in anims)], LINEAR) for t in ts])

    def masks_for(self, anchor):
        """Masks for a layer in anchor's space: anchor's own clip plus every clip above, mapped down."""
        path = self.chain(anchor)
        clips = [n for n in path if n.clip]
        masks = []
        for ci, cnode in enumerate(clips):
            between = path[path.index(cnode) + 1:]  # transforms from the clip's space down to the anchor's space
            shapes = self.clip_shapes(cnode.clip)
            if ci > 0:
                assert len(shapes) == 1, 'nested clips must be single shapes'
            for si, shape in enumerate(shapes):
                mode = 'a' if ci == 0 else 'i'
                pt = self.mapped_shape(shape, between)
                masks.append({'inv': False, 'mode': mode, 'pt': pt, 'o': prop([100]), 'x': prop([0]), 'nm': cnode.clip})
        return masks

    def clip_shapes(self, cid):
        shapes = []
        for c in self.doc.clips[cid]:
            k = tag(c)
            if k in ('circle', 'ellipse'):
                cx, cy = float(c.get('cx')), float(c.get('cy'))
                rx = float(c.get('r') or c.get('rx'))
                ry = float(c.get('r') or c.get('ry'))
                shapes.append(ellipse_shape(cx, cy, rx, ry))
            elif k == 'path':
                shapes += [lottie_shape(s) for s in path_to_subpaths(c.get('d'))]
            elif k == 'rect':
                x, y, w, h = (float(c.get(a, 0)) for a in ('x', 'y', 'width', 'height'))
                shapes.append({'c': True, 'v': [[x, y], [x + w, y], [x + w, y + h], [x, y + h]], 'i': [[0, 0]] * 4, 'o': [[0, 0]] * 4})
        return shapes

    def mapped_shape(self, shape, between):
        """Clip shape expressed in the space below the given nodes' transforms (static or keyframed)."""
        if not any(n.transforms for n in between):
            return shape_prop(shape)
        anim = [n for n in between if n.animated() and n.transforms]

        def m_at(t):
            m = IDENT
            for n in between:
                m = mat_mul(m, n.matrix_at(t))
            return mat_inv(m)

        if not anim:
            return shape_prop(map_shape(shape, m_at(0)))
        times = sorted(set().union(*[n.kf_times() for n in anim]))
        mats = [m_at(t) for t in times]
        if all(max(abs(a - b) for a, b in zip(m, mats[0])) < 1e-6 for m in mats):
            return shape_prop(map_shape(shape, mats[0]))
        one = anim[0].transforms[0] if len(anim) == 1 and len(anim[0].transforms) == 1 else None
        if one and isinstance(one['p'], KF) and not isinstance(one['r'], KF) and not isinstance(one['s'], KF):
            # one keyframed transform: reuse its keys and easing (exact for translations)
            src = anim[0].transforms[0]['p']
            keys = [(t, flatten(map_shape(shape, m_at(t))), e) for t, _, e in src.keys]
        else:
            keys = [(t, flatten(map_shape(shape, m_at(t))), LINEAR) for t in range(0, OP + 1)]
        kf = KF(keys)
        kf.proto = shape
        return shape_prop(kf)

    def shape_layer(self, shapes, anchor):
        parent, opacity = self.layer_space(anchor)
        layer = {'ddd': 0, 'ind': self.next_ind(), 'ty': 4, 'nm': anchor.el.get('class') or anchor.kind, 'sr': 1, 'ao': 0,
                 'ks': ks_item(None, opacity), 'shapes': shapes, 'ip': 0, 'op': OP, 'st': 0, 'bm': 0}
        if parent is not None:
            layer['parent'] = parent
        masks = self.masks_for(anchor)
        if masks:
            layer['hasMask'] = True
            layer['masksProperties'] = masks
        return layer

    # -- baked images
    def emit_bake(self, n):
        """Render a static filtered subtree (in its parent's space) to an image layer."""
        idx = len(self.images)
        svg_path = os.path.join(self.tmp, f'{self.name}-bake{idx}.svg')
        png_path = os.path.join(self.tmp, f'{self.name}-bake{idx}.png')
        el = n.el
        defs = ''.join(ET.tostring(d, encoding='unicode') for d in self.doc.root if tag(d) == 'defs')
        markup = ET.tostring(el, encoding='unicode')
        vb = self.doc.root.get('viewBox')
        strip = lambda m: re.sub(r'\sxmlns="[^"]*"', '', m)
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}">{strip(defs)}{strip(markup)}</svg>'
        open(svg_path, 'w').write(svg)
        img_id = f'img_{idx}'
        self.images.append({'id': img_id, 'svg': svg_path, 'png': png_path})
        parent, opacity = self.layer_space(n.parent)
        layer = {'ddd': 0, 'ind': self.next_ind(), 'ty': 2, 'nm': 'body', 'refId': img_id, 'sr': 1, 'ao': 0,
                 'ks': None, 'ip': 0, 'op': OP, 'st': 0, 'bm': 0, '_opacity': opacity, '_img': idx}
        if parent is not None:
            layer['parent'] = parent
        self.layers.append(layer)

    def finish_images(self, vb_size):
        """Bake all images in one Chrome run, crop to content, embed."""
        if not self.images:
            return []
        px = int(vb_size * BAKE_PX)
        args = ['node', 'scripts/casama-mascot-render.mjs', '--svg', str(px)]
        for im in self.images:
            args += [im['svg'], im['png']]
        subprocess.run(args, check=True, stdout=subprocess.DEVNULL)
        assets = []
        for idx, im in enumerate(self.images):
            img = Image.open(im['png']).convert('RGBA')
            box = img.getchannel('A').getbbox()
            x0, y0, x1, y1 = box
            x0, y0 = max(0, x0 - 2), max(0, y0 - 2)
            x1, y1 = min(img.width, x1 + 2), min(img.height, y1 + 2)
            img = img.crop((x0, y0, x1, y1))
            buf = io.BytesIO()
            img.save(buf, 'PNG', optimize=True)
            assets.append({'id': im['id'], 'w': img.width, 'h': img.height, 'u': '', 'e': 1,
                           'p': 'data:image/png;base64,' + base64.b64encode(buf.getvalue()).decode()})
            for layer in self.layers:
                if layer.get('_img') == idx:
                    layer['ks'] = ks_item({'a': [0, 0], 'p': [x0 / BAKE_PX, y0 / BAKE_PX], 's': [100 / BAKE_PX] * 2, 'r': [0]},
                                          layer.pop('_opacity'))
                    del layer['_img']
        return assets


def tr_item(tr, opacity):
    tr = tr or {'a': [0, 0], 'p': [0, 0], 's': [100, 100], 'r': [0]}
    return {'ty': 'tr', 'a': prop(tr['a']), 'p': prop(tr['p']), 's': prop(tr['s']), 'r': prop(tr['r']),
            'o': prop(opacity), 'sk': prop([0]), 'sa': prop([0])}


def ks_item(tr, opacity):
    tr = tr or {'a': [0, 0], 'p': [0, 0], 's': [100, 100], 'r': [0]}
    return {'a': prop(tr['a']), 'p': prop(tr['p']), 's': prop(tr['s']), 'r': prop(tr['r']), 'o': prop(opacity)}


def convert(name, tmp):
    doc = Doc(os.path.join(SRC, f'casama-{name}-animated.svg'))
    vb = [float(x) for x in doc.root.get('viewBox').split()]
    c = Converter(doc, name, tmp)
    c.null_layers = []
    c.convert()
    assets = c.finish_images(vb[2])
    layers = list(reversed(c.layers)) + c.null_layers  # Lottie draws the first layer on top
    return {'v': '5.7.0', 'fr': FR, 'ip': 0, 'op': OP, 'w': int(vb[2]), 'h': int(vb[3]), 'nm': f'Casama {name}', 'ddd': 0,
            'assets': assets, 'layers': layers}


def main():
    names = sys.argv[1:] or sorted(f[len('casama-'):-len('-animated.svg')] for f in os.listdir(SRC) if f.endswith('-animated.svg'))
    with tempfile.TemporaryDirectory() as tmp:
        for name in names:
            data = convert(name, tmp)
            out = os.path.join(OUT, f'{name}.json')
            with open(out, 'w') as fh:
                json.dump(data, fh, separators=(',', ':'))
            print(f'{name}: {len(data["layers"])} layers, {os.path.getsize(out) // 1024} KB')


if __name__ == '__main__':
    main()
