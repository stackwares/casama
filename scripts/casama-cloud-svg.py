"""Generates the Casama cloud bot avatars: 10 personalities, each as a static and an animated SVG.

Every bot shares the same cloud, tail and orb geometry; each personality adds its own face, colours,
orb shape and an 8 second story loop. Edit here and re-run instead of hand-editing the SVGs.

Writes client/assets/bots/casama-<name>.svg and casama-<name>-animated.svg.
Run from the repo root: python3 scripts/casama-cloud-svg.py [out_dir]

Static SVGs use no CSS so they also work in flutter_svg. Animated SVGs use CSS keyframes plus SMIL
for the tail (it bends, and the orb rides its tip). With prefers-reduced-motion they hold the static pose.
"""
import colorsys, math, re, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else 'client/assets/bots'
T = 8.0  # master loop length (seconds); every loop is T, T/2 or T/8 so nothing drifts

EASE = 'cubic-bezier(.45,0,.55,1)'
OUT_E = 'cubic-bezier(.2,.75,.35,1)'
IN_E = 'cubic-bezier(.6,0,.85,.45)'
INK = '#3B1452'
CORAL = '#F0676B'


def hls(h, s, l):
    r, g, b = colorsys.hls_to_rgb(h / 360, l, s)
    return '#%02X%02X%02X' % (round(r * 255), round(g * 255), round(b * 255))


# ---------------------------------------------------------------- small helpers
def f(v):
    s = f"{v:.1f}"
    s = s.rstrip('0').rstrip('.') if '.' in s else s
    return '0' if s in ('-0', '') else s


def pt(p):
    return f"{f(p[0])} {f(p[1])}"


def catmull(pts, closed=False):
    n = len(pts)

    def P(i):
        return pts[i % n] if closed else pts[max(0, min(n - 1, i))]

    d = f"M{pt(pts[0])}"
    for i in (range(n) if closed else range(n - 1)):
        p0, p1, p2, p3 = P(i - 1), P(i), P(i + 1), P(i + 2)
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f"C{pt(c1)} {pt(c2)} {pt(p2)}"
    return d + ('Z' if closed else '')


def rot(p, c, deg):
    a = math.radians(deg)
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * math.cos(a) - y * math.sin(a), c[1] + x * math.sin(a) + y * math.cos(a))


def norm(v):
    l = math.hypot(*v) or 1
    return (v[0] / l, v[1] / l)


def F(t, **k):
    """One keyframe: o=opacity, x/y=translate, r=rotate, s/sx/sy=scale, e=easing of the next segment.
    Properties left out hold their previous value."""
    return (t, k)


# ---------------------------------------------------------------- shared geometry
PUFFS = [
    (110, 112, 50),   # crown
    (176, 130, 36),   # right shoulder
    (205, 163, 27),   # right cheek lobe
    (178, 190, 29),   # bottom right
    (128, 197, 28),   # bottom middle
    (80, 189, 29),    # bottom left
    (50, 158, 28),    # left lobe
    (68, 130, 23),    # upper-left shoulder
]
FILL = (128, 158, 84, 44)

EL = (97, 142, 21, 23)       # left eye (cx, cy, rx, ry)
ER = (163, 138, 17.5, 19.5)  # right eye, a little smaller: the face is turned slightly right
KR = ER[2] / EL[2]
IRIS_SHIFT = 4
MX, MY = 130, 160            # mouth
CHEEK_L = (73, 165, 13, 8)
CHEEK_R = (186, 159, 11, 7)
ORB_R = 18

TAIL_B, TAIL_C1, TAIL_C2, TAIL_M = (82, 110), (44, 104), (25, 76), (49, 56)
TAIL_C3, TAIL_C4, TAIL_T = (73, 36), (136, 30), (184, 52)
TAIL_W0, TAIL_W1 = 10.5, 4.2
OX, OY = TAIL_T


def tail_pose(a1, a2):
    B, C1, C2, M, C3, C4, Tp = TAIL_B, TAIL_C1, TAIL_C2, TAIL_M, TAIL_C3, TAIL_C4, TAIL_T
    C1 = rot(C1, B, a1 * 0.5)
    C2, M, C3, C4, Tp = (rot(p, B, a1) for p in (C2, M, C3, C4, Tp))
    C2, C3 = rot(C2, M, a2 * 0.5), rot(C3, M, a2 * 0.5)
    C4, Tp = rot(C4, M, a2), rot(Tp, M, a2)
    return [(B, C1, C2, M), (M, C3, C4, Tp)]


def bez(seg, t):
    p0, p1, p2, p3 = seg
    u = 1 - t
    return tuple(u ** 3 * p0[i] + 3 * u * u * t * p1[i] + 3 * u * t * t * p2[i] + t ** 3 * p3[i] for i in (0, 1))


def seg_len(seg):
    pts = [bez(seg, i / 40) for i in range(41)]
    return sum(math.dist(pts[i], pts[i + 1]) for i in range(40))


def tail_outline(a1, a2):
    """Tapered tail outline; a1 swings the whole tail about its root, a2 curls the outer half."""
    segs = tail_pose(a1, a2)
    lens = [seg_len(s) for s in segs]
    total = sum(lens)
    s0 = 0
    left, right = [], []
    w = lambda s: (TAIL_W0 + (TAIL_W1 - TAIL_W0) * s) / 2
    for seg, L in zip(segs, lens):
        s1 = s0 + L / total
        p0, p1, p2, p3 = seg
        n0 = norm((-(p1[1] - p0[1]), p1[0] - p0[0]))
        n3 = norm((-(p3[1] - p2[1]), p3[0] - p2[0]))
        ss = [s0, s0 + (s1 - s0) / 3, s0 + 2 * (s1 - s0) / 3, s1]
        ns = [n0, n0, n3, n3]
        left.append([(p[0] + n[0] * w(s), p[1] + n[1] * w(s)) for p, n, s in zip(seg, ns, ss)])
        right.append([(p[0] - n[0] * w(s), p[1] - n[1] * w(s)) for p, n, s in zip(seg, ns, ss)])
        s0 = s1
    d = f"M{pt(left[0][0])}"
    for c in left:
        d += f"C{pt(c[1])} {pt(c[2])} {pt(c[3])}"
    d += f"L{pt(right[-1][3])}"
    for c in reversed(right):
        d += f"C{pt(c[2])} {pt(c[1])} {pt(c[0])}"
    return d + 'Z', segs[1][3]


# ---------------------------------------------------------------- shape library
def crescent_lid(e, a0=184, a1=318, tmax=4.6, tmin=0.9, peak=0.42, n=14):
    cx, cy, rx, ry = e
    k = math.log(0.5) / math.log(peak)
    outer, inner = [], []
    for i in range(n + 1):
        u = i / n
        a = math.radians(a0 + (a1 - a0) * u)
        p = (cx + rx * math.cos(a), cy + ry * math.sin(a))
        nv = norm((math.cos(a) / rx, math.sin(a) / ry))
        t = tmin + (tmax - tmin) * math.sin(math.pi * u ** k)
        outer.append((p[0] + nv[0] * t, p[1] + nv[1] * t))
        inner.append((p[0] - nv[0] * 1.0, p[1] - nv[1] * 1.0))
    return catmull(outer + inner[::-1], closed=True)


def sparkle_d(cx, cy, R):
    k = R * 0.1
    return (f"M{pt((cx, cy - R))}Q{pt((cx + k, cy - k))} {pt((cx + R, cy))}"
            f"Q{pt((cx + k, cy + k))} {pt((cx, cy + R))}Q{pt((cx - k, cy + k))} {pt((cx - R, cy))}"
            f"Q{pt((cx - k, cy - k))} {pt((cx, cy - R))}Z")


def heart_d(cx, cy, s):
    P = lambda x, y: pt((cx + x * s, cy + y * s))
    return (f"M{P(0, 1)}C{P(-.95, .4)} {P(-1.25, -.15)} {P(-1.02, -.58)}C{P(-.8, -1.02)} {P(-.18, -1.05)} {P(0, -.55)}"
            f"C{P(.18, -1.05)} {P(.8, -1.02)} {P(1.02, -.58)}C{P(1.25, -.15)} {P(.95, .4)} {P(0, 1)}Z")


def star_d(cx, cy, R, r=None):
    r = r or R * .5
    pts = []
    for i in range(10):
        a = math.radians(-90 + i * 36)
        rr = R if i % 2 == 0 else r
        pts.append(pt((cx + rr * math.cos(a), cy + rr * math.sin(a))))
    return 'M' + 'L'.join(pts) + 'Z'


def drop_d(x, y, s=1):
    P = lambda dx, dy: pt((x + dx * s, y + dy * s))
    return f"M{P(0, 0)}C{P(4.5, 6)} {P(5, 10)} {P(0, 11)}C{P(-5, 10)} {P(-4.5, 6)} {P(0, 0)}Z"


def z_d(x, y, s):
    h = s / 2
    return f"M{pt((x - h, y - h))}H{f(x + h)}L{pt((x - h, y + h))}H{f(x + h)}"


def smile_d(w=10, depth=11, dx=0, dy=0):
    return f"M{pt((MX - w + dx, MY - 1 + dy))}Q{pt((MX + dx, MY - 1 + depth + dy))} {pt((MX + w + dx, MY - 1 + dy))}"


def grin_d():
    return (f"M{pt((MX - 14, MY))}Q{pt((MX, MY + 4))} {pt((MX + 14, MY))}"
            f"Q{pt((MX + 13.5, MY + 20))} {pt((MX, MY + 20))}Q{pt((MX - 13.5, MY + 20))} {pt((MX - 14, MY))}Z")


def grin(cls=None, extra=''):
    c = f' class="{cls}"' if cls else ''
    return (f'<g{c}{extra}><path d="{grin_d()}" fill="#D9475E"/>'
            f'<ellipse cx="{MX}" cy="{MY + 19}" rx="9" ry="6" fill="#FF8F98" clip-path="url(#kcMouth)"/></g>')


def o_mouth(cls, rx=6, ry=7, dy=4, extra=''):
    return (f'<g class="{cls}"{extra}><ellipse cx="{MX}" cy="{MY + dy}" rx="{rx}" ry="{ry}" fill="#D9475E"/>'
            f'<ellipse cx="{MX}" cy="{f(MY + dy + ry * .55)}" rx="{f(rx * .6)}" ry="{f(ry * .34)}" fill="#FF8F98"/></g>')


def stroke(d, cls=None, color=INK, w=6.5, extra=''):
    c = f' class="{cls}"' if cls else ''
    return f'<path{c} d="{d}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"{extra}/>'


def happy_arc_d(e, lift=None):
    cx, cy, rx, _ = e
    w = rx * .72
    lift = lift or rx * .66
    return f"M{pt((cx - w, cy + 4))}Q{pt((cx, cy + 2 - lift))} {pt((cx + w, cy + 4))}"


def shut_d(e):
    cx, cy, rx, _ = e
    w = rx * .76
    return f"M{pt((cx - w, cy + 3))}Q{pt((cx, cy + 12))} {pt((cx + w, cy + 3))}"


def eye(e, clip, cls, iris_cls, crescent=True, lid=None, iris_tf=None, extra_iris='', open_tf=None):
    """Open eye: white, clipped iris (moves via iris_cls), optional cloud-coloured eyelid, top lash crescent."""
    cx, cy, rx, ry = e
    k = rx / EL[2]
    ix, iy = cx + IRIS_SHIFT * k, cy + k
    irx, iry = 14.5 * k, 16 * k
    tf = f' transform="translate({f(iris_tf[0])} {f(iris_tf[1])})"' if iris_tf else ''
    otf = f' transform="{open_tf}"' if open_tf else ''
    iris = (f'<g class="{iris_cls}"{tf}>'
            f'<ellipse cx="{f(ix)}" cy="{f(iy)}" rx="{f(irx)}" ry="{f(iry)}" fill="url(#kcIris)"/>'
            f'<ellipse cx="{f(ix)}" cy="{f(iy - k)}" rx="{f(7 * k)}" ry="{f(8 * k)}" fill="#1E0630" opacity=".55"/>'
            f'<circle cx="{f(ix + 5 * k)}" cy="{f(iy - 7 * k)}" r="{f(4.8 * k)}" fill="#FFFFFF"/>'
            f'<circle cx="{f(ix - 5 * k)}" cy="{f(iy + 7.5 * k)}" r="{f(2.1 * k)}" fill="#FFFFFF" opacity=".85"/>'
            f'{extra_iris}</g>')
    lidm = ''
    if lid:
        lcls, frac = lid
        top, y0 = cy - 3 * ry - 6, cy - ry
        lid_d = f"M{pt((cx - rx - 3, top))}H{f(cx + rx + 3)}V{f(y0)}Q{pt((cx, y0 + 7))} {pt((cx - rx - 3, y0))}Z"
        # the lid is painted with the cloud's own body, shade and sheen so it matches the skin behind each eye
        # The paint sits in a counter-moving group (<lid>P, see Bot.anim) so the gradient stays put while the lid slides.
        dy = frac * 2 * ry
        x0, x1 = cx - rx - 4, cx + rx + 4
        lidm = (f'<g class="{lcls}" transform="translate(0 {f(dy)})">'
                f'<clipPath id="{lcls}Clip{f(cx)}"><path d="{lid_d}"/></clipPath>'
                f'<g clip-path="url(#{lcls}Clip{f(cx)})"><g class="{lcls}P" transform="translate(0 {f(-dy)})">'
                f'<rect x="{f(x0)}" y="{f(top - 10)}" width="{f(x1 - x0)}" height="{f(4 * ry + 30)}" fill="url(#kcBody)"/>'
                f'<rect x="{f(x0)}" y="{f(top - 10)}" width="{f(x1 - x0)}" height="{f(4 * ry + 30)}" fill="url(#kcShade)"/>'
                f'<ellipse cx="94" cy="94" rx="58" ry="40" fill="url(#kcSheen)"/></g></g>'
                f'{stroke(f"M{pt((cx - rx - 3, y0))}Q{pt((cx, y0 + 7))} {pt((cx + rx + 3, y0))}", w=4.5)}</g>')
    cres = f'<path d="{crescent_lid(e)}" fill="{INK}"/>' if crescent else ''
    return (f'<g class="{cls}"{otf}><ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#kcSclera)"/>'
            f'<g clip-path="url(#{clip})">{iris}</g>' + (f'<g clip-path="url(#{clip}Lid)">{lidm}</g>' if lidm else '') + f'{cres}</g>')


def brow_center(e):
    return (e[0], e[1] - e[3] - 10)


def brow(e, cls, r=0, dy=0, w=4.5):
    cx, cy = brow_center(e)
    hw = 11 * e[2] / EL[2]
    d = f"M{pt((cx - hw, cy + 2))}Q{pt((cx, cy - 4))} {pt((cx + hw, cy + 2))}"
    tf = f' transform="translate(0 {f(dy)}) rotate({f(r)} {f(cx)} {f(cy)})"' if (r or dy) else ''
    return f'<g class="{cls}"{tf}>{stroke(d, w=w)}</g>'


def cheek(c, cls=None, scale=1.0):
    cl = f' class="{cls}"' if cls else ''
    return f'<ellipse{cl} cx="{c[0]}" cy="{c[1]}" rx="{f(c[2] * scale)}" ry="{f(c[3] * scale)}" fill="url(#kcCheek)"/>'


def sparkle(cls, cx, cy, R, color):
    return (f'<g class="{cls}"><path d="{sparkle_d(cx, cy, R)}" fill="{color}"/>'
            f'<path d="{sparkle_d(cx, cy, R * .45)}" fill="#FFFFFF"/></g>')


def punct(kind, cls, cx, cy, k=1.4, color=INK):
    if kind == '?':
        d = (f"M{pt((cx - 5 * k, cy - 7 * k))}Q{pt((cx - 5 * k, cy - 13 * k))} {pt((cx, cy - 13 * k))}"
             f"Q{pt((cx + 6 * k, cy - 13 * k))} {pt((cx + 6 * k, cy - 7 * k))}Q{pt((cx + 6 * k, cy - 3 * k))} {pt((cx, cy - k))}V{f(cy + 3 * k)}")
    else:
        d = f"M{pt((cx, cy - 13 * k))}V{f(cy + 2 * k)}"
    dot = (cx, cy + 9 * k)
    return (f'<g class="{cls}">{stroke(d, color="#FFFFFF", w=4.2 * k + 3.5)}<circle cx="{f(dot[0])}" cy="{f(dot[1])}" r="{f(2.6 * k + 1.8)}" fill="#FFFFFF"/>'
            f'{stroke(d, color=color, w=4.2 * k)}<circle cx="{f(dot[0])}" cy="{f(dot[1])}" r="{f(2.6 * k)}" fill="{color}"/></g>')


# ---------------------------------------------------------------- keyframe helpers
def pops(times, dur=.55, peak=1.15):
    fr = [F(0, o=0, s=0, r=0)]
    for t in times:
        fr += [F(t, o=0, s=0, r=0), F(t + dur * .35, o=1, s=peak, r=45), F(t + dur * .7, o=1, s=.85, r=70), F(t + dur, o=0, s=0, r=90)]
    return fr


def eye_frames(blinks=(), hides=(), extra=()):
    fr = [F(0, o=1, sx=1, sy=1)]
    ev = sorted([(b, 'b') for b in blinks] + [(h, 'h') for h in hides], key=lambda e: e[0] if e[1] == 'b' else e[0][0])
    for v, kind in ev:
        if kind == 'b':
            b = v
            fr += [F(b - .04, o=1, sy=1), F(b + .01, sy=.22), F(b + .015, o=0), F(b + .065, o=0), F(b + .07, o=1, sy=.22), F(b + .13, sy=1)]
        else:
            t0, t1 = v
            fr += [F(t0 - .07, o=1, sy=1), F(t0, sy=.22), F(t0 + .015, o=0), F(t1, o=0), F(t1 + .015, o=1, sy=.22), F(t1 + .12, sy=1)]
    return fr + list(extra)


def shut_frames(blinks):
    fr = [F(0, o=0)]
    for b in blinks:
        fr += [F(b + .008, o=0), F(b + .015, o=1), F(b + .065, o=1), F(b + .072, o=0)]
    return fr


def arc_frames(hides):
    fr = [F(0, o=0, sx=1, sy=.5)]
    for t0, t1 in hides:
        fr += [F(t0 + .005, o=0, sx=1, sy=.5), F(t0 + .015, o=1), F(t0 + .13, sx=1.12, sy=1.18), F(t0 + .23, sx=1, sy=1),
               F(t1, o=1), F(t1 + .015, o=0, sy=.5)]
    return fr


def show(spans, t_in=.08, t_out=.08, pop=None):
    """Opacity (and optional scale pop) for something visible only during spans [(t0, t1)]."""
    fr = [F(0, o=0, s=pop or 1)]
    for t0, t1 in spans:
        fr += [F(t0, o=0, s=pop or 1), F(t0 + t_in, o=1, s=1.1 if pop else 1)]
        if pop:
            fr.append(F(t0 + t_in + .1, s=1))
        fr += [F(t1, o=1, s=1), F(t1 + t_out, o=0, s=pop or 1)]
    return fr


def hide(spans, t=.08, pop=None):
    """Opacity for something visible except during spans."""
    fr = [F(0, o=1, s=1)]
    for t0, t1 in spans:
        fr += [F(t0, o=1, s=1), F(t0 + t, o=0, s=pop or 1), F(t1, o=0, s=pop or 1), F(t1 + t, o=1, s=1.08 if pop else 1)]
        if pop:
            fr.append(F(t1 + t + .1, s=1))
    return fr


def rise(times, dur, dx, dy, s0=.6, s1=1.15):
    fr = [F(0, o=0, x=0, y=0, s=s0)]
    for t in times:
        fr += [F(t, o=0, x=0, y=0, s=s0), F(t + dur * .2, o=1, x=dx * .2, y=dy * .2, s=s0 + (s1 - s0) * .2),
               F(t + dur * .7, o=1, x=dx * .7, y=dy * .7, s=s0 + (s1 - s0) * .7), F(t + dur, o=0, x=dx, y=dy, s=s1)]
    return fr


def hop(t0, h=18, k=1.0):
    """Crouch, jump, land and wobble (1.55 s)."""
    return [F(t0, y=0, sx=1, sy=1, e=OUT_E), F(t0 + .2, sx=1 + .09 * k, sy=1 - .11 * k, e=OUT_E),
            F(t0 + .52, y=-h * .9, sx=1 - .06 * k, sy=1 + .08 * k, e=OUT_E), F(t0 + .69, y=-h, sx=1.01, sy=.99, e=IN_E),
            F(t0 + .91, y=-1, sx=.96, sy=1.05, e=OUT_E), F(t0 + 1.0, y=0, sx=1 + .08 * k, sy=1 - .1 * k, e=OUT_E),
            F(t0 + 1.17, y=-4 * k, sx=.98, sy=1.02), F(t0 + 1.35, y=0, sx=1.015, sy=.985), F(t0 + 1.55, sx=1, sy=1)]


def bounce(t0, h=10, k=1.0):
    """Quick little bounce (0.5 s)."""
    return [F(t0, y=0, sx=1, sy=1, e=OUT_E), F(t0 + .08, sx=1 + .06 * k, sy=1 - .08 * k, e=OUT_E),
            F(t0 + .25, y=-h, sx=.97, sy=1.04, e=IN_E), F(t0 + .42, y=0, sx=1 + .06 * k, sy=1 - .07 * k, e=OUT_E),
            F(t0 + .5, sx=1, sy=1)]


def jiggle(t0, t1, half, amp, key='y'):
    fr, t, i = [], t0, 0
    while t <= t1 + 1e-6:
        fr.append(F(t, **{key: (-amp if i % 2 else 0)}))
        t, i = t + half, i + 1
    if i % 2 == 0:
        fr.append(F(t, **{key: 0}))
    return fr


def hop_tail(t0, m=1.0):
    return [(t0 + .2, -3 * m, -5 * m), (t0 + .52, 4.5 * m, 8 * m), (t0 + .71, -4 * m, -7 * m), (t0 + .91, -1 * m, -2 * m),
            (t0 + 1.02, 4.5 * m, 8.5 * m), (t0 + 1.19, -2.5 * m, -4.5 * m), (t0 + 1.39, 1.2 * m, 2.2 * m), (t0 + 1.61, 0, 0)]


def bounce_tail(t0, m=1.0):
    return [(t0 + .1, 2.5 * m, 4.5 * m), (t0 + .27, -2.5 * m, -4.5 * m), (t0 + .45, 2.5 * m, 4.5 * m), (t0 + .6, -1 * m, -2 * m)]


def sway(t0, t1, half, a1=1.5, a2=3, sign=-1):
    keys, t = [], t0
    while t < t1 - 1e-6:
        keys.append((t, sign * a1, sign * a2))
        sign, t = -sign, t + half
    return keys


def tail_mix(base, *blocks):
    out = list(base)
    for b in blocks:
        lo, hi = min(k[0] for k in b) - .12, max(k[0] for k in b) + .12
        out = [k for k in out if not lo <= k[0] <= hi] + list(b)
    d = {round(k[0], 3): k for k in out}
    d[0], d[T] = (0, 0, 0), (T, 0, 0)
    return [d[k] for k in sorted(d)]


# ---------------------------------------------------------------- variant model
class Bot:
    def __init__(self, key, title, story, pal, orb='sphere'):
        self.key, self.title, self.story, self.pal, self.orb = key, title, story, pal, orb
        self.parts = {'orb': [], 'face': [], 'head': [], 'front': []}
        self.anims = {}
        self.body = [F(0, x=0, y=0, sx=1, sy=1)]
        self.tilt = [F(0, r=0)]
        self.tail = [(0, 0, 0), (T, 0, 0)]
        self.float_amp = 3
        self.glow = [F(0, o=.45, s=.9), F(2, o=.62, s=1.06), F(4, o=.45, s=.9), F(6, o=.62, s=1.06)]
        self.ball = [F(0, s=1)]
        self.defs = ''

    def add(self, layer, markup, mode='both'):
        """mode: both (static + animated), anim (animated only, starts hidden), static (static only)."""
        if mode == 'anim':
            markup = re.sub(r'^(\s*<\w+)', r'\1 opacity="0"', markup, count=1)
        self.parts[layer].append((markup, mode))

    def anim(self, cls, origin, frames, dur=T, timing=EASE):
        self.anims[cls] = (origin, frames, dur, timing)
        if cls.startswith('lid'):  # the lid's paint moves back by the same amount (see eye())
            self.anims[cls + 'P'] = (origin, [(t, {k: -v if k == 'y' else v for k, v in d.items()}) for t, d in frames], dur, timing)

    def spark(self, layer, cls, cx, cy, R, color, times, dur=.55, mode='anim'):
        self.add(layer, sparkle(cls, cx, cy, R, color), mode)
        self.anims[cls] = ((cx, cy), pops(times, dur), T, EASE)


def snapshots(frames):
    fr = {}
    for t, d in frames:
        fr.setdefault(round(t, 4), {}).update(d)
    times = sorted(fr)
    assert times[0] == 0, frames
    cur = {'o': 1, 'x': 0, 'y': 0, 'r': 0, 'sx': 1, 'sy': 1}
    used, out = set(), []
    for t in times:
        d = dict(fr[t])
        e = d.pop('e', None)
        if 's' in d:
            v = d.pop('s')
            d['sx'] = d['sy'] = v
        used |= set(d)
        cur.update(d)
        out.append((t, dict(cur), e))
    return out, used


def keyframes(name, frames, dur=T):
    snaps, used = snapshots(frames)
    if snaps[-1][0] < dur:
        snaps.append((dur, snaps[0][1], None))
    body = ''
    for t, c, e in snaps:
        css = []
        if 'o' in used:
            css.append(f"opacity:{c['o']:g}")
        tf = []
        if used & {'x', 'y'}:
            tf.append(f"translate({f(c['x'])}px,{f(c['y'])}px)")
        if 'r' in used:
            tf.append(f"rotate({c['r']:g}deg)")
        if used & {'sx', 'sy'}:
            tf.append(f"scale({c['sx']:g},{c['sy']:g})")
        if tf:
            css.append('transform:' + ' '.join(tf))
        if e:
            css.append('animation-timing-function:' + e)
        p = f"{t / dur * 100:.3f}".rstrip('0').rstrip('.') + '%'
        body += f"{p}{{{';'.join(css)}}}"
    return f"@keyframes {name}{{{body}}}"


# ---------------------------------------------------------------- rendering
def defs(bot):
    clip = ''.join(f'<circle cx="{x}" cy="{y}" r="{r}"/>' for x, y, r in PUFFS)
    clip += f'<ellipse cx="{FILL[0]}" cy="{FILL[1]}" rx="{FILL[2]}" ry="{FILL[3]}"/>'
    t0, t1, t2 = bot.pal['tail']
    o0, o1, o2, o3 = bot.pal['orb']
    h = bot.pal['hue']
    b0, b1, b2, b3 = hls(h, .9, .94), hls(h, .8, .82), hls(h, .75, .7), hls(h, .7, .59)
    shade, rim = hls(h, .55, .45), hls(h, .5, .48)
    sclera = hls(h, .6, .93)
    i0, i1, i2 = hls(h, .85, .66), hls(h, .7, .34), hls(h, .6, .12)
    ck = bot.pal.get('cheek', '#FF6F8C')
    return f'''<defs>
    <linearGradient id="kcBody" gradientUnits="userSpaceOnUse" x1="96" y1="62" x2="150" y2="226">
      <stop offset="0" stop-color="{b0}"/><stop offset=".46" stop-color="{b1}"/><stop offset=".8" stop-color="{b2}"/><stop offset="1" stop-color="{b3}"/>
    </linearGradient>
    <radialGradient id="kcShade" gradientUnits="userSpaceOnUse" cx="226" cy="214" r="120">
      <stop offset="0" stop-color="{shade}" stop-opacity=".5"/><stop offset="1" stop-color="{shade}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="kcSheen" gradientUnits="userSpaceOnUse" cx="92" cy="92" r="62">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity=".95"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="kcGround"><stop offset="0" stop-color="#2B0E42" stop-opacity=".2"/><stop offset="1" stop-color="#2B0E42" stop-opacity="0"/></radialGradient>
    <radialGradient id="kcCheek"><stop offset="0" stop-color="{ck}" stop-opacity=".85"/><stop offset=".6" stop-color="{ck}" stop-opacity=".4"/><stop offset="1" stop-color="{ck}" stop-opacity="0"/></radialGradient>
    <linearGradient id="kcSclera" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{sclera}"/><stop offset=".38" stop-color="#FFFFFF"/><stop offset="1" stop-color="#FFFDFB"/></linearGradient>
    <radialGradient id="kcIris" cx=".5" cy=".78" r=".78"><stop offset="0" stop-color="{i0}"/><stop offset=".45" stop-color="{i1}"/><stop offset="1" stop-color="{i2}"/></radialGradient>
    <linearGradient id="kcTail" gradientUnits="userSpaceOnUse" x1="40" y1="112" x2="190" y2="44">
      <stop offset="0" stop-color="{t0}"/><stop offset=".5" stop-color="{t1}"/><stop offset="1" stop-color="{t2}"/>
    </linearGradient>
    <radialGradient id="kcOrb" cx=".34" cy=".28" r=".85"><stop offset="0" stop-color="{o0}"/><stop offset=".22" stop-color="{o1}"/><stop offset=".62" stop-color="{o2}"/><stop offset="1" stop-color="{o3}"/></radialGradient>
    <radialGradient id="kcGlow"><stop offset="0" stop-color="{bot.pal['glow']}" stop-opacity=".9"/><stop offset=".45" stop-color="{bot.pal['glow']}" stop-opacity=".35"/><stop offset="1" stop-color="{bot.pal['glow']}" stop-opacity="0"/></radialGradient>
    <filter id="kcLift" x="-15%" y="-15%" width="130%" height="140%"><feDropShadow dx="0" dy="3" stdDeviation="3.5" flood-color="#2B0E42" flood-opacity=".2"/></filter>
    <filter id="kcPuff" x="-5%" y="-5%" width="110%" height="110%">
      <feOffset in="SourceAlpha" dy="-7" result="up"/><feGaussianBlur in="up" stdDeviation="5" result="upBlur"/>
      <feComposite in="SourceAlpha" in2="upBlur" operator="out" result="rim"/>
      <feFlood flood-color="{rim}" flood-opacity=".5"/><feComposite in2="rim" operator="in" result="shade"/>
      <feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="shade"/></feMerge>
    </filter>
    <filter id="kcEdge" x="-10%" y="-10%" width="120%" height="125%"><feDropShadow dx="0" dy="1.2" stdDeviation="1.2" flood-color="#2B0E42" flood-opacity=".3"/></filter>
    <filter id="kcSoft" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.6"/></filter>
    <clipPath id="kcCloud">{clip}</clipPath>
    <clipPath id="kcEyeL"><ellipse cx="{EL[0]}" cy="{EL[1]}" rx="{EL[2]}" ry="{EL[3]}"/></clipPath>
    <clipPath id="kcEyeR"><ellipse cx="{ER[0]}" cy="{ER[1]}" rx="{ER[2]}" ry="{ER[3]}"/></clipPath>
    <clipPath id="kcEyeLLid"><ellipse cx="{EL[0]}" cy="{EL[1]}" rx="{EL[2] + 1.5}" ry="{EL[3] + 1.5}"/></clipPath>
    <clipPath id="kcEyeRLid"><ellipse cx="{ER[0]}" cy="{ER[1]}" rx="{ER[2] + 1.5}" ry="{ER[3] + 1.5}"/></clipPath>
    <clipPath id="kcMouth"><path d="{grin_d()}"/></clipPath>{bot.defs}
  </defs>'''


def cloud_body():
    return '''<g filter="url(#kcLift)"><g filter="url(#kcPuff)">
      <g clip-path="url(#kcCloud)">
        <rect x="10" y="50" width="236" height="190" fill="url(#kcBody)"/>
        <rect x="10" y="50" width="236" height="190" fill="url(#kcShade)"/>
        <ellipse cx="94" cy="94" rx="58" ry="40" fill="url(#kcSheen)"/>
        <path d="M66 112A46 46 0 0 1 96 70" fill="none" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round" opacity=".7" filter="url(#kcSoft)"/>
      </g>
    </g></g>'''


def moon_d(cx, cy, R):
    c2, r2 = (cx + R * .45, cy - R * .35), R * .86
    d = math.dist((cx, cy), c2)
    a = (R * R - r2 * r2 + d * d) / (2 * d)
    h = math.sqrt(R * R - a * a)
    ux, uy = (c2[0] - cx) / d, (c2[1] - cy) / d
    px, py = cx + a * ux, cy + a * uy
    p1, p2 = (px - h * uy, py + h * ux), (px + h * uy, py - h * ux)
    return f"M{pt(p1)}A{f(R)} {f(R)} 0 1 1 {pt(p2)}A{f(r2)} {f(r2)} 0 0 0 {pt(p1)}Z"


def orb_markup(bot, animated):
    g = ' class="orbGlow"' if animated else ''
    b = ' class="orbBall"' if animated else ''
    shine = (f'<ellipse cx="{f(OX - 5.5)}" cy="{f(OY - 6)}" rx="5.5" ry="3.6" fill="#FFFFFF" opacity=".92" '
             f'transform="rotate(-25 {f(OX - 5.5)} {f(OY - 6)})"/>')
    if bot.orb == 'heart':
        shape = f'<path d="{heart_d(OX, OY + 1, ORB_R * .78)}" fill="url(#kcOrb)"/>' + shine
    elif bot.orb == 'star':
        shape = (f'<path d="{star_d(OX, OY + 1, ORB_R * 1.2)}" fill="url(#kcOrb)" stroke="url(#kcOrb)" stroke-width="5" stroke-linejoin="round"/>'
                 f'<ellipse cx="{f(OX - 3)}" cy="{f(OY - 5)}" rx="3.5" ry="2.4" fill="#FFFFFF" opacity=".92"/>')
    elif bot.orb == 'moon':
        shape = (f'<path d="{moon_d(OX, OY, ORB_R + 1)}" fill="url(#kcOrb)"/>'
                 f'<circle cx="{f(OX - 8)}" cy="{f(OY + 5)}" r="2.6" fill="{bot.pal["orb"][3]}" opacity=".45"/>'
                 f'<circle cx="{f(OX - 3)}" cy="{f(OY + 12)}" r="1.8" fill="{bot.pal["orb"][3]}" opacity=".4"/>')
    else:
        shape = f'<circle cx="{OX}" cy="{OY}" r="{ORB_R}" fill="url(#kcOrb)"/>' + shine
    return f'<circle{g} cx="{OX}" cy="{OY}" r="{ORB_R * 2}" fill="url(#kcGlow)"/><g{b}>{shape}</g>'


def parts(bot, layer, animated):
    return ''.join(m for m, mode in bot.parts[layer] if mode == 'both' or mode == ('anim' if animated else 'static'))


def css(bot):
    rules = []

    def add(cls, origin, frames, dur=T, timing=EASE):
        o = f"transform-origin:{f(origin[0])}px {f(origin[1])}px;" if origin else ''
        rules.append(f".{cls}{{{o}animation:k{cls} {dur:g}s {timing} infinite}}")
        rules.append(keyframes('k' + cls, frames, dur))

    snaps, _ = snapshots(bot.body)
    hop_f = [F(t, x=c['x'], y=c['y'], **({'e': e} if e else {})) for t, c, e in snaps]
    sq_f = [F(t, sx=c['sx'], sy=c['sy'], **({'e': e} if e else {})) for t, c, e in snaps]
    shadow = []
    for t, c, e in snaps:
        lift = min(1.0, max(0.0, -c['y'] / 30))
        sc = (1 - .32 * lift) * (c['sx'] if lift < .05 else 1)
        shadow.append(F(t, o=round(1 - .55 * lift, 3), s=round(sc, 3), **({'e': e} if e else {})))
    add('float', (128, 200), [F(0, y=0), F(T / 4, y=-bot.float_amp)], T / 2)
    add('groundB', (128, 238), [F(0, o=1, s=1), F(T / 4, o=.82, s=.94)], T / 2)
    add('hop', None, hop_f)
    add('squash', (128, 226), sq_f)
    add('groundA', (128, 238), shadow)
    add('tilt', (128, 160), bot.tilt)
    add('orbGlow', (OX, OY), bot.glow)
    add('orbBall', (OX, OY), bot.ball)
    for cls, (origin, frames, dur, timing) in bot.anims.items():
        add(cls, origin, frames, dur, timing)
    rules.append('@media (prefers-reduced-motion: reduce){*{animation:none!important}.moving{display:none}.still{display:inline}}')
    rules.append('.still{display:none}')
    return '\n    '.join(rules)


def tail_anim(bot):
    keys = bot.tail
    assert keys[0][0] == 0 and keys[-1][0] == T and all(keys[i][0] < keys[i + 1][0] for i in range(len(keys) - 1)), keys
    ds, moves, kts = [], [], []
    for s, a1, a2 in keys:
        d, tip = tail_outline(a1, a2)
        ds.append(d)
        moves.append(f"{f(tip[0] - OX)} {f(tip[1] - OY)}")
        kts.append(f"{s / T:.4f}".rstrip('0').rstrip('.') if s else '0')
    kts[-1] = '1'
    splines = ';'.join(['.45 0 .55 1'] * (len(keys) - 1))
    common = f'dur="{T:g}s" repeatCount="indefinite" calcMode="spline" keyTimes="{";".join(kts)}" keySplines="{splines}"'
    rest_d, _ = tail_outline(0, 0)
    return (f'<path d="{rest_d}" fill="url(#kcTail)" filter="url(#kcEdge)"><animate attributeName="d" {common} values="{";".join(ds)}"/></path>\n'
            f'      <g><animateTransform attributeName="transform" type="translate" {common} values="{";".join(moves)}"/>'
            f'{orb_markup(bot, True)}{parts(bot, "orb", True)}</g>')


def build(bot, animated):
    rest_tail, _ = tail_outline(0, 0)
    ground = '<ellipse cx="128" cy="238" rx="66" ry="8" fill="url(#kcGround)"/>'
    head = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" role="img" aria-labelledby="kcTitle">\n  <title id="kcTitle">Casama {bot.title}{" (animated)" if animated else ""}</title>'
    still_tail = f'<path d="{rest_tail}" fill="url(#kcTail)" filter="url(#kcEdge)"/>{orb_markup(bot, False)}{parts(bot, "orb", False)}'
    if not animated:
        return f'''{head}
  {defs(bot)}
  {ground}
  {still_tail}
  {cloud_body()}
  {parts(bot, "face", False)}
  {parts(bot, "head", False)}
  {parts(bot, "front", False)}
</svg>
'''
    return f'''{head}
  <!-- {bot.story} -->
  <style>
    {css(bot)}
  </style>
  {defs(bot)}
  <g class="groundA"><g class="groundB">{ground}</g></g>
  <g class="float"><g class="hop"><g class="tilt">
    <g class="moving">
      {tail_anim(bot)}
    </g>
    <g class="still">{still_tail}</g>
    <g class="squash">
    {cloud_body()}
    {parts(bot, "face", True)}
    </g>
    {parts(bot, "head", True)}
  </g></g></g>
  {parts(bot, "front", True)}
</svg>
'''


# ---------------------------------------------------------------- the ten personalities
PAL = {
    'winky':    dict(hue=195, tail=('#7A90FF', '#B09EFF', '#7DE9F4'), orb=('#F2FFFE', '#7AF2E6', '#5EC2FF', '#A585FF'), glow='#7EF0F4'),
    'sleepy':   dict(hue=245, tail=('#7C83F2', '#A59CF6', '#D9D2FF'), orb=('#FFFBE6', '#FFF0B3', '#FFD66E', '#E2A93A'), glow='#FFE9A0'),
    'starry':   dict(hue=50, tail=('#FF9F43', '#FFC94D', '#FFF1A6'), orb=('#FFFDE8', '#FFE680', '#FFC93C', '#FF9F1C'), glow='#FFE07A'),
    'lovey':    dict(hue=325, cheek='#E8365F', tail=('#FF6FAE', '#FF9CC9', '#FFC9E1'), orb=('#FFF0F6', '#FF9CC9', '#FF5C9E', '#E0367A'), glow='#FF9CC9'),
    'cool':     dict(hue=168, tail=('#14B8A6', '#4FD1C5', '#A7F3E4'), orb=('#F0FFFC', '#7CF5E0', '#2CC9B5', '#1A8F9E'), glow='#6FF0DC'),
    'thinker':  dict(hue=30, cheek='#E8455F', tail=('#F59E0B', '#FBBF24', '#FDE68A'), orb=('#FFFDF0', '#FFF3B0', '#FFD24D', '#F5A30B'), glow='#FFE27A'),
    'giggly':   dict(hue=95, tail=('#22C55E', '#4ADE80', '#BBF7D0'), orb=('#F3FFF6', '#A7F3C0', '#4ADE80', '#16A34A'), glow='#8EF5B0'),
    'shy':      dict(hue=8, cheek='#D9284F', tail=('#FB7185', '#FDA4AF', '#FFD5DC'), orb=('#FFF5F6', '#FFC2CB', '#FB8A9B', '#E35D74'), glow='#FFB3C0'),
    'focused':  dict(hue=220, tail=('#3B82F6', '#60A5FA', '#BFDBFE'), orb=('#F0F7FF', '#9CCBFF', '#4C9BFF', '#2563EB'), glow='#8CC4FF'),
    'wow':      dict(hue=272, tail=('#8B5CF6', '#A78BFA', '#E2D9FF'), orb=('#FAF7FF', '#D7C8FF', '#A78BFA', '#7C3AED'), glow='#C4B0FF'),
}


def cheeks_both(bot, cls=True, scale=1.0):
    bot.add('face', cheek(CHEEK_L, 'cheekL' if cls else None, scale) + cheek(CHEEK_R, 'cheekR' if cls else None, scale))


def winky():
    b = Bot('winky', 'Winky', 'Curious and playful: notices its orb ("ooh"), happy hop, signature wink.', PAL['winky'])
    hides = (2.67, 3.95)
    b.body = [F(0, x=0, y=0, sx=1, sy=1)] + hop(2.45)
    b.tilt = [F(0, r=0), F(1.25), F(1.6, r=-5), F(2.2), F(2.45, r=0), F(4.5), F(4.78, r=5), F(5.45), F(5.85, r=0),
              F(6.1), F(6.3, r=-2), F(6.65), F(6.95, r=0)]
    b.tail = tail_mix([(.8, -2, -3), (1.3, 1.5, 3), (1.58, 2.5, 5), (1.88, -1.5, -3), (2.2, .5, 1)], hop_tail(2.45),
                      [(4.5, 0, 0), (4.8, -2, -3.5), (5.1, 1, 2), (5.45, 0, 0), (5.85, 1.5, 3), (6.2, -1, -2), (6.7, 1, 2), (7.3, -1.5, -3)])
    cheeks_both(b)
    b.add('face', eye(EL, 'kcEyeL', 'eyeL', 'iris'))
    b.add('face', eye(ER, 'kcEyeR', 'eyeR', 'iris'), 'anim')
    b.add('face', stroke(shut_d(EL), 'shutL') + stroke(shut_d(ER), 'shutR'), 'anim')
    b.add('face', stroke(happy_arc_d(EL), 'arcL'), 'anim')
    b.add('face', stroke(happy_arc_d(ER), 'arcR'))
    b.add('face', stroke(smile_d(), 'smile', CORAL, 5))
    b.add('face', o_mouth('mouthO'), 'anim')
    b.add('face', grin('grin'), 'anim')
    b.spark('face', 'sparkWink', 214, 104, 12, '#FFC94D', [4.76], .62)
    blinks = (1.0, 6.72)
    b.anim('eyeL', (EL[0], EL[1] + 3), eye_frames(blinks, [hides]))
    b.anim('eyeR', (ER[0], ER[1] + 3), eye_frames(blinks, [hides, (4.72, 5.5)]))
    b.anim('shutL', None, shut_frames(blinks))
    b.anim('shutR', None, shut_frames(blinks))
    b.anim('arcL', EL[:2], arc_frames([hides]))
    b.anim('arcR', ER[:2], arc_frames([hides, (4.72, 5.5)]))
    b.anim('iris', None, [F(0, x=0, y=0), F(1.2), F(1.42, x=2, y=-5), F(2.2), F(2.42, x=0, y=0), F(4.05, x=-3, y=.5),
                          F(6.05), F(6.2, x=-7, y=1), F(6.62), F(6.8, x=0, y=0)])
    b.anim('smile', (MX, MY + 3), [F(0, o=1, s=1), F(1.42), F(1.5, o=0, s=.6), F(2.16), F(2.27, o=1, s=1), F(2.6),
                                   F(2.67, o=0, sx=1.3, sy=.8), F(3.93, s=.8), F(4.03, o=1, s=1), F(4.66),
                                   F(4.8, sx=1.2, sy=1.12), F(5.48), F(5.65, s=1)])
    b.anim('mouthO', (MX, MY + 3), [F(0, o=0, s=.3), F(1.44), F(1.54, o=1, s=1.12), F(1.62, s=1), F(1.9, sx=.88, sy=1.06),
                                    F(2.18, s=1), F(2.28, o=0, s=.3)])
    b.anim('grin', (MX, MY + 1), [F(0, o=0, sx=.6, sy=.2), F(2.62), F(2.7, o=1, sx=1.06, sy=1.1), F(2.8, s=1),
                                  F(3.12, sx=1.06, sy=1.14), F(3.45, sx=1.12, sy=.88), F(3.62, s=1), F(3.9), F(4.0, o=0, sx=.6, sy=.3)])
    ck = lambda dy: [F(0, o=.75, x=0, y=0, s=1), F(2.6), F(2.8, o=1, sx=1.35, sy=1.25), F(3.9), F(4.15, o=.75, s=1), F(4.7),
                     F(4.85, o=.9 if not dy else 1, y=dy, sx=1.1 if not dy else 1.3, sy=1.1 if not dy else 1.2), F(5.5), F(5.7, o=.75, y=0, s=1)]
    b.anim('cheekL', CHEEK_L[:2], ck(0))
    b.anim('cheekR', CHEEK_R[:2], ck(-3))
    b.glow = [F(0, o=.45, s=.9), F(1.5, o=.5, s=.95), F(1.82, o=.95, s=1.28), F(2.3, o=.55, s=1), F(2.9, o=.6, s=1),
              F(3.12, o=1, s=1.4), F(3.6, o=.55, s=1), F(5.0, o=.7, s=1.12), F(6.0, o=.45, s=.92), F(7.0, o=.62, s=1.06)]
    b.ball = [F(0, s=1), F(1.72), F(1.82, s=1.14), F(1.96, s=1), F(3.0), F(3.12, s=1.16), F(3.26, s=1)]
    b.spark('orb', 'spark1', OX + 25, OY - 21, 10, '#6FE3F2', [1.72])
    b.spark('orb', 'spark2', OX - 27, OY - 22, 8, '#B79BFF', [3.0], .5)
    b.spark('orb', 'spark3', OX + 28, OY + 16, 7.5, '#FFD36E', [3.1], .45)
    return b


def sleepy():
    b = Bot('sleepy', 'Sleepy', 'Drowsy: lids droop, dozes off with floating Zs, nods, startles awake, yawns.', PAL['sleepy'], 'moon')
    b.float_amp = 4
    b.add('face', cheek(CHEEK_L, 'cheekL', .9) + cheek(CHEEK_R, 'cheekR', .9))
    b.add('face', eye(EL, 'kcEyeL', 'eyeL', 'iris', crescent=False, lid=('lidL', .5), iris_tf=(0, 3)))
    b.add('face', eye(ER, 'kcEyeR', 'eyeR', 'iris', crescent=False, lid=('lidR', .5), iris_tf=(0, 3)))
    b.add('face', stroke(shut_d(EL), 'shutL') + stroke(shut_d(ER), 'shutR'), 'anim')
    b.add('face', stroke(smile_d(6, 7), 'smile', CORAL, 4.5))
    b.add('face', f'<ellipse class="snore" cx="{MX}" cy="{MY + 3}" rx="3.5" ry="4" fill="#D9475E"/>', 'anim')
    b.add('face', o_mouth('gasp', 5, 6), 'anim')
    b.add('face', o_mouth('yawn', 7.5, 10, 6), 'anim')
    b.add('head', f'<path class="sweat" d="{drop_d(203, 96, 1.1)}" fill="#8FD3FF"/>', 'anim')
    zc = '#8C8FF5'
    for i, (zx, zy, zs) in enumerate([(212, 114, 14), (217, 110, 17), (222, 106, 20)]):
        b.add('head', f'<g class="z{i}">{stroke(z_d(zx, zy, zs), color="#FFFFFF", w=zs * .3 + 3)}{stroke(z_d(zx, zy, zs), color=zc, w=zs * .3)}</g>', 'anim')
        b.anim(f'z{i}', (zx, zy), rise([2.3 + i * .55], 1.5, 16, -58, .5, 1.15), timing='linear')
    b.add('head', f'<g>{stroke(z_d(222, 92, 14), color="#FFFFFF", w=7.2)}{stroke(z_d(222, 92, 14), color=zc, w=4.2)}</g>', 'static')
    lid = [(0, .5), (.9, .55), (1.6, .72), (2.05, .85), (2.12, 1), (4.55, 1), (4.6, 0), (5.2, 0), (5.36, .22), (5.43, 1), (5.52, .25),
           (6.1, .3), (6.55, .5)]
    for cls, e in (('lidL', EL), ('lidR', ER)):
        b.anim(cls, None, [F(t, y=v * 2 * e[3]) for t, v in lid])
    ef = [F(0, o=1, s=1), F(2.05), F(2.12, o=0), F(4.58), F(4.6, o=1, s=1.15), F(4.78, s=1), F(6.6), F(6.66, o=0), F(7.35), F(7.4, o=1)]
    b.anim('eyeL', (EL[0], EL[1]), ef)
    b.anim('eyeR', (ER[0], ER[1]), ef)
    sh = [F(0, o=0), F(2.06), F(2.12, o=1), F(4.56), F(4.6, o=0), F(6.6), F(6.66, o=1), F(7.36), F(7.4, o=0)]
    b.anim('shutL', None, sh)
    b.anim('shutR', None, sh)
    b.anim('iris', None, [F(0, x=0, y=3), F(4.58), F(4.6, x=0, y=-1), F(4.8), F(4.95, x=-6, y=0), F(5.15), F(5.3, x=5, y=0),
                          F(5.6), F(5.85, x=0, y=2), F(6.5, y=3)])
    b.anim('smile', (MX, MY + 3), hide([(2.15, 5.2), (6.55, 7.4)]))
    b.anim('snore', (MX, MY + 3), [F(0, o=0, s=1), F(2.2), F(2.3, o=1), F(2.9, s=1.3), F(3.6, s=.9), F(4.3, s=1.25), F(4.55),
                                   F(4.6, o=0, s=1)])
    b.anim('gasp', (MX, MY + 4), show([(4.58, 5.1)], .06, .1, pop=.4))
    b.anim('yawn', (MX, MY + 2), [F(0, o=0, sx=.6, sy=.3), F(6.6), F(6.75, o=1, sx=.9, sy=.7), F(7.05, sx=1.05, sy=1.15),
                                  F(7.3, s=1), F(7.42, o=0, sx=.6, sy=.3)])
    b.anim('sweat', (203, 100), [F(0, o=0, y=0), F(4.62), F(4.7, o=1), F(5.2, o=1, y=10), F(5.4, o=0, y=14)])
    b.body = [F(0, x=0, y=0, sx=1, sy=1), F(2.1), F(2.8, sx=1.03, sy=.97), F(3.5, s=1), F(4.2, sx=1.03, sy=.97),
              F(4.5, y=2, sx=1.04, sy=.96), F(4.56, y=3, e=OUT_E), F(4.7, y=-10, sx=.95, sy=1.07, e=IN_E),
              F(4.88, y=0, sx=1.05, sy=.95, e=OUT_E), F(5.05, sx=1, sy=1), F(6.6), F(7.0, sx=.97, sy=1.05), F(7.38, sx=1, sy=1)]
    b.tilt = [F(0, r=0), F(1.0), F(2.1, r=7), F(4.2), F(4.45, r=9.5), F(4.56, r=9), F(4.72, r=-3), F(5.0, r=0), F(6.6),
              F(7.0, r=-4), F(7.5, r=0)]
    b.tail = tail_mix([(1.2, 1, 2), (2.1, 3, 5), (3.0, 4, 6), (3.8, 3, 5), (4.5, 4, 7), (4.62, -6, -10), (4.85, 3, 6),
                       (5.1, -1.5, -3), (5.4, 0, 0), (6.2, -1, -2), (7.0, 1, 2)])
    b.glow = [F(0, o=.5, s=1), F(2.1, o=.35, s=.9), F(4.5, o=.3, s=.88), F(4.62, o=1, s=1.4), F(5.2, o=.55, s=1), F(6.5, o=.5, s=1)]
    b.ball = [F(0, s=1, r=0), F(2.1), F(3.2, r=-12), F(4.5, r=-8), F(4.62, s=1.15, r=6), F(4.8, s=1, r=0)]
    return b


def starry():
    b = Bot('starry', 'Starry', 'Starstruck and bouncy: star eyes, happy bounces, a little dance and a big jump.', PAL['starry'], 'star')
    b.defs = ('\n    <linearGradient id="kcStarEye" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE66B"/>'
              '<stop offset="1" stop-color="#FFA41C"/></linearGradient>')
    cheeks_both(b, True, 1.1)
    for cls, e in (('starL', EL), ('starR', ER)):
        R = e[2] * 1.02
        b.add('face', f'<g class="{cls}"><path d="{star_d(e[0], e[1], R, R * .52)}" fill="url(#kcStarEye)" stroke="{INK}" stroke-width="3.2" stroke-linejoin="round"/></g>'
                      f'<circle cx="{f(e[0] - R * .25)}" cy="{f(e[1] - R * .2)}" r="{f(R * .16)}" fill="#FFFFFF"/>')
    b.add('face', grin('grin'))
    small = [.3, .85, 1.4]
    stars = [F(0, s=1, r=0)]
    for t in small:
        stars += [F(t + .25, s=1.22, r=10 if t != .85 else -10), F(t + .5, s=1, r=0)]
    stars += [F(2.0), F(2.25, r=-12), F(2.75, r=12), F(3.25, r=-12), F(3.75, r=12), F(4.2, r=0), F(4.7, s=.85),
              F(5.2, s=1.35, r=72), F(5.6, s=1), F(7.1), F(7.35, s=1.2, r=0), F(7.6, s=1)]
    b.anim('starL', EL[:2], stars)
    b.anim('starR', ER[:2], stars)
    gr = [F(0, s=1)]
    for t in small:
        gr += [F(t + .25, sx=1.04, sy=1.15), F(t + .5, s=1)]
    gr += [F(4.7, sx=1.1, sy=.85), F(5.2, sx=1.08, sy=1.2), F(5.6, s=1)]
    b.anim('grin', (MX, MY + 1), gr)
    body = [F(0, x=0, y=0, sx=1, sy=1)]
    for t in small:
        body += bounce(t, 10)
    body += [F(2.0, y=0, s=1)]
    for i, t in enumerate([2.25, 2.75, 3.25, 3.75]):
        body += [F(t, y=0, sx=1.04, sy=.95), F(t + .25, y=-4, sx=.98, sy=1.03)]
    body += [F(4.2, y=0, sx=1, sy=1)] + hop(4.5, 16, 1.1) + bounce(7.1, 6)
    b.body = body
    b.tilt = [F(0, r=0), F(2.0), F(2.25, r=8), F(2.75, r=-8), F(3.25, r=8), F(3.75, r=-8), F(4.2, r=0)]
    tails = []
    for t in small:
        tails += [(t + .1, 2, 4), (t + .27, -2, -4)]
    tails += [(1.95, 1, 2), (2.25, -3, -5), (2.75, 3, 5), (3.25, -3, -5), (3.75, 3, 5), (4.2, 0, 0)]
    b.tail = tail_mix(tails, hop_tail(4.5, 1.2), bounce_tail(7.1, .8))
    b.ball = [F(0, s=1, r=0)] + [x for t in small for x in (F(t + .25, s=1.15), F(t + .5, s=1))] + \
             [F(4.7, s=.9), F(5.2, s=1.25, r=72), F(5.6, s=1), F(7.1), F(7.35, s=1.15, r=0), F(7.6, s=1)]
    b.glow = [F(0, o=.5, s=1), F(.55, o=.8, s=1.15), F(1.1, o=.55, s=1), F(1.65, o=.8, s=1.15), F(2.2, o=.5, s=1),
              F(5.2, o=1, s=1.45), F(5.8, o=.55, s=1), F(7.35, o=.8, s=1.12)]
    for cls, x, y, R, col, times in (('sp1', 38, 96, 9, '#FFD36E', [.5, 5.1]), ('sp2', 228, 122, 8, '#FFB547', [1.05, 5.18]),
                                     ('sp3', 226, 34, 7.5, '#FFE680', [1.6, 5.26]), ('sp4', 104, 22, 7, '#FFC94D', [3.0, 5.3]),
                                     ('sp5', 20, 176, 6.5, '#FFE680', [3.5, 7.3])):
        b.spark('head', cls, x, y, R, col, times)
    return b


def lovey():
    b = Bot('lovey', 'Lovey', 'Smitten: heart eyes thump, hearts float up, blows a kiss.', PAL['lovey'], 'heart')
    b.defs = ('\n    <linearGradient id="kcHeartEye" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF4F8B"/>'
              '<stop offset="1" stop-color="#B5154F"/></linearGradient>')
    b.add('face', cheek(CHEEK_L, 'cheekL', 1.25) + cheek(CHEEK_R, 'cheekR', 1.25))
    for cls, e in (('heartL', EL), ('heartR', ER)):
        s = e[2] * .74
        b.add('face', f'<g class="{cls}"><path d="{heart_d(e[0], e[1] + 1, s)}" fill="url(#kcHeartEye)" stroke="#FFFFFF" stroke-width="2.5"/>'
                      f'<ellipse cx="{f(e[0] - s * .5)}" cy="{f(e[1] - s * .4)}" rx="{f(s * .22)}" ry="{f(s * .15)}" fill="#FFFFFF" opacity=".9" transform="rotate(-30 {f(e[0] - s * .5)} {f(e[1] - s * .4)})"/></g>')
    b.add('face', stroke(happy_arc_d(EL), 'arcL') + stroke(happy_arc_d(ER), 'arcR'), 'anim')
    b.add('face', stroke(smile_d(9, 10), 'smile', CORAL, 5))
    kiss = f"M{pt((MX - 2, MY - 3))}Q{pt((MX + 7, MY - 2))} {pt((MX + 1, MY + 3))}Q{pt((MX + 8, MY + 5))} {pt((MX - 1, MY + 9))}"
    b.add('face', stroke(kiss, 'kiss', '#D9475E', 4.5), 'anim')
    kiss_span = (4.05, 5.25)

    def beats(t):
        return [F(t, s=1), F(t + .1, s=1.2), F(t + .2, s=1.04), F(t + .3, s=1.16), F(t + .5, s=1)]
    hf = [F(0, o=1, s=1)] + beats(.1) + beats(2.1) + [F(3.9), F(4.0, o=1, s=1), F(4.08, o=0, s=.5), F(5.25),
                                                    F(5.33, o=1, s=1.3), F(5.5, s=1)] + beats(6.3)
    b.anim('heartL', EL[:2], hf)
    b.anim('heartR', ER[:2], hf)
    b.anim('arcL', EL[:2], arc_frames([kiss_span]))
    b.anim('arcR', ER[:2], arc_frames([kiss_span]))
    b.anim('smile', (MX, MY + 3), hide([(4.05, 5.2)]))
    b.anim('kiss', (MX + 2, MY + 3), [F(0, o=0, s=.5), F(4.08), F(4.18, o=1, s=1), F(4.45, s=1.25), F(4.62, s=.9), F(4.8, s=1),
                                      F(5.15), F(5.25, o=0, s=.5)])
    ck = [F(0, o=.85, s=1), F(4.1), F(4.35, o=1, s=1.3), F(5.2), F(5.5, o=.85, s=1)]
    b.anim('cheekL', CHEEK_L[:2], ck)
    b.anim('cheekR', CHEEK_R[:2], ck)
    for cls, x, y, s, times, dx, dy in (('fh1', 24, 126, 10, [.4, 5.6], -6, -62), ('fh2', 230, 124, 9, [1.6, 6.4], 6, -60),
                                        ('fh3', 224, 96, 8, [2.8], 8, -50)):
        b.add('front', f'<g class="{cls}"><path d="{heart_d(x, y, s)}" fill="#FF6FA5" stroke="#FFFFFF" stroke-width="2"/></g>', 'anim')
        b.anim(cls, (x, y), rise(times, 1.6, dx, dy, .5, 1.1), timing='linear')
    b.add('head', f'<g class="kissHeart"><path d="{heart_d(MX + 10, MY + 2, 9)}" fill="#D91E5B" stroke="#FFFFFF" stroke-width="2"/></g>', 'anim')
    b.anim('kissHeart', (MX + 10, MY + 2), rise([4.6], 1.0, 88, -46, .4, 1.4), timing='linear')
    still_hearts = ''.join('<path d="%s" fill="#FF6FA5" stroke="#FFFFFF" stroke-width="2"/>' % heart_d(x, y, sz)
                           for x, y, sz in ((22, 96, 6.5), (234, 92, 5.5)))
    b.add('front', f'<g>{still_hearts}</g>', 'static')
    b.tilt = [F(0, r=0), F(1.0, r=4), F(2.0, r=0), F(3.0, r=-4), F(4.0, r=0), F(5.4), F(6.4, r=4), F(7.3, r=-1)]
    b.body = [F(0, x=0, y=0, sx=1, sy=1), F(4.0), F(4.3, sx=.97, sy=1.04), F(5.1), F(5.3, sx=1, sy=1)] + bounce(5.35, 9)
    b.tail = tail_mix(sway(0, 4.0, 1.0, 1.5, 3, -1) + [(4.0, 0, 0), (4.6, -1.5, -3)], bounce_tail(5.35),
                      [(6.4, -1.5, -3), (7.3, 1, 2)])
    bb = [F(0, s=1)] + beats(.1) + beats(2.1) + beats(4.55) + beats(6.3)
    b.ball = bb
    b.glow = [F(0, o=.5, s=1), F(.2, o=.85, s=1.2), F(.6, o=.5, s=1), F(2.2, o=.85, s=1.2), F(2.6, o=.5, s=1), F(4.65, o=.9, s=1.3),
              F(5.1, o=.5, s=1), F(6.4, o=.85, s=1.2), F(6.8, o=.5, s=1)]
    return b


def cool():
    b = Bot('cool', 'Cool', 'Laid-back: vibes to a beat in shades, slides them down to peek and raise a brow.', PAL['cool'])
    lens = [(97, 141, 54, 47, 16), (163, 138, 45, 40, 14)]
    rects = ''.join(f'<rect x="{f(x - w / 2)}" y="{f(y - h / 2)}" width="{w}" height="{h}" rx="{r}"/>' for x, y, w, h, r in lens)
    b.defs = (f'\n    <linearGradient id="kcLens" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3A1A55"/><stop offset="1" stop-color="#12061C"/></linearGradient>'
              f'\n    <clipPath id="kcLensClip">{rects}</clipPath>')
    cheeks_both(b, False, .9)
    b.add('face', eye(EL, 'kcEyeL', 'eyeL', 'iris', crescent=False, lid=('lidL', .2), iris_tf=(-3, -2)))
    b.add('face', eye(ER, 'kcEyeR', 'eyeR', 'iris', crescent=False, lid=('lidR', .2), iris_tf=(-3, -2)))
    b.add('face', brow(EL, 'browL', 0, -3) + brow(ER, 'browR', 0, -3))
    smirk = f"M{pt((MX - 1, MY + 8))}Q{pt((MX + 9, MY + 13))} {pt((MX + 18, MY + 3))}"
    b.add('face', stroke(smirk, 'smirk', CORAL, 5))
    lens_shapes = ''.join(f'<rect x="{f(x - w / 2)}" y="{f(y - h / 2)}" width="{w}" height="{h}" rx="{r}" fill="url(#kcLens)" stroke="#12061C" stroke-width="3"/>'
                          for x, y, w, h, r in lens)
    glint = '<path d="M60 170 L84 104 L96 104 L72 170Z M76 170 L100 104 L106 104 L82 170Z" fill="#FFFFFF" opacity=".55"/>'
    b.add('face', f'<g class="shades">{stroke("M124 134Q130 128 141 132", color="#12061C", w=5)}{lens_shapes}'
                  f'<g clip-path="url(#kcLensClip)"><g class="glint" transform="translate(-40 0)">{glint}</g></g>'
                  f'<path d="M78 126Q86 122 94 123" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity=".35"/></g>')
    b.anim('shades', None, [F(0, y=0), F(3.3, e=OUT_E), F(3.65, y=16), F(5.3, e=IN_E), F(5.6, y=0), F(5.7, y=-2), F(5.8, y=0)])
    b.anim('glint', None, [F(0, x=-40), F(1.0), F(1.5, x=110), F(5.8), F(5.81, x=-40), F(5.9), F(6.4, x=110), F(7.95), F(7.96, x=-40)])
    b.anim('iris', None, [F(0, x=-3, y=-3), F(3.6), F(4.7), F(4.85, x=4, y=-3), F(5.1), F(5.25, x=-3, y=-3)])
    b.anim('browR', brow_center(ER), [F(0, y=-3, r=0), F(3.7), F(3.85, y=-10, r=-8), F(4.05, y=-3, r=0), F(4.25, y=-10, r=-8),
                                      F(4.45, y=-3, r=0)])
    b.anim('smirk', (MX + 9, MY + 8), [F(0, s=1), F(3.6), F(3.8, sx=1.15, sy=1.1), F(5.3), F(5.5, s=1)])
    body = [F(0, x=0, y=0, sx=1, sy=1)]
    for t in [0, .5, 1.0, 1.5, 2.0, 2.5] + [6.0, 6.5, 7.0]:
        body += [F(t, y=0, sx=1, sy=1), F(t + .22, y=2.5, sx=1.015, sy=.985)]
    body += [F(3.0, y=0, sx=1, sy=1), F(7.5, y=0, sx=1, sy=1)]
    b.body = body
    b.tilt = [F(0, r=0), F(3.0), F(3.5, r=3), F(5.3), F(5.7, r=0)]
    keys = [(t, (-1) ** i * 1.5, (-1) ** i * 3) for i, t in enumerate([.25, .5, .75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75])]
    keys += [(3.1, 0, 0), (3.6, -1.5, -3), (4.6, 1, 2), (5.4, -1, -2), (5.75, 0, 0)]
    keys += [(t, (-1) ** i * 1.5, (-1) ** i * 3) for i, t in enumerate([6.25, 6.5, 6.75, 7.0, 7.25, 7.5])]
    b.tail = tail_mix(keys)
    b.glow = [F(0, o=.5, s=1)] + [x for t in (0, 1, 2, 6, 7) for x in (F(t + .22, o=.8, s=1.15), F(t + .6, o=.5, s=1))]
    return b


def thinker():
    b = Bot('thinker', 'Thinker', 'Pondering: looks around with a hmm and a question mark, then lights up with an idea.', PAL['thinker'])
    cheeks_both(b, True, .9)
    b.add('face', eye(EL, 'kcEyeL', 'eyeL', 'iris', iris_tf=(-8, -6)))
    b.add('face', eye(ER, 'kcEyeR', 'eyeR', 'iris', iris_tf=(-8, -6)))
    b.add('face', stroke(shut_d(EL), 'shutL') + stroke(shut_d(ER), 'shutR'), 'anim')
    b.add('face', brow(EL, 'browL', -6, -4) + brow(ER, 'browR', 4, 1))
    hmm = f"M{pt((MX - 12, MY + 3))}Q{pt((MX - 8, MY))} {pt((MX - 4, MY + 3))}T{pt((MX + 4, MY + 3))}"
    b.add('face', stroke(hmm, 'hmm', CORAL, 4.5))
    b.add('face', o_mouth('aha', 5.5, 6.5), 'anim')
    b.add('face', grin('grin'), 'anim')
    b.add('head', punct('?', 'qmark', 222, 112, 1.5, '#B7791F'))
    b.add('head', punct('!', 'bang', 222, 110, 1.6, '#E8590C'), 'anim')
    blinks = (2.9, 6.95)
    pop = [F(3.5, s=1.16), F(3.7, s=1)]
    b.anim('eyeL', (EL[0], EL[1] + 3), sorted(eye_frames(blinks, extra=pop), key=lambda x: x[0]))
    b.anim('eyeR', (ER[0], ER[1] + 3), sorted(eye_frames(blinks, extra=pop), key=lambda x: x[0]))
    b.anim('shutL', None, shut_frames(blinks))
    b.anim('shutR', None, shut_frames(blinks))
    b.anim('iris', None, [F(0, x=-8, y=-6), F(1.0), F(1.3, x=3, y=-7), F(2.0), F(2.3, x=-8, y=-6), F(3.4), F(3.5, x=-2, y=0),
                          F(5.6), F(6.4, x=-8, y=-6)])
    b.anim('browL', brow_center(EL), [F(0, y=-4, r=-6), F(1.0), F(1.3, y=1, r=4), F(2.0), F(2.3, y=-4, r=-6), F(3.4),
                                      F(3.5, y=-8, r=-4), F(3.8, y=-5, r=0), F(5.6), F(6.4, y=-4, r=-6)])
    b.anim('browR', brow_center(ER), [F(0, y=1, r=4), F(1.0), F(1.3, y=-4, r=6), F(2.0), F(2.3, y=1, r=4), F(3.4),
                                      F(3.5, y=-8, r=4), F(3.8, y=-5, r=0), F(5.6), F(6.4, y=1, r=4)])
    b.anim('hmm', (MX - 4, MY + 3), [F(0, o=1, x=0, s=1), F(1.0), F(1.3, x=8), F(2.0), F(2.3, x=0), F(3.4), F(3.48, o=0, s=.6),
                                     F(6.1), F(6.25, o=1, s=1)])
    b.anim('aha', (MX, MY + 4), show([(3.46, 3.8)], .06, .08, pop=.4))
    b.anim('grin', (MX, MY + 1), [F(0, o=0, sx=.6, sy=.3), F(3.8), F(3.9, o=1, s=1), F(4.4, sx=1.06, sy=1.1), F(4.6, s=1),
                                  F(4.75, sx=1.06, sy=1.1), F(4.95, s=1), F(6.0), F(6.12, o=0, sx=.6, sy=.3)])
    b.anim('qmark', (222, 112), [F(0, o=1, s=1, r=0), F(.6, r=10), F(1.2, r=-8), F(1.8, r=10), F(2.4, r=-8), F(3.0, r=6),
                                 F(3.35, r=0), F(3.45, o=0, s=.4), F(6.9), F(7.1, o=1, s=1.12), F(7.25, s=1), F(7.6, r=-6)])
    b.anim('bang', (222, 110), show([(3.48, 5.1)], .1, .15, pop=.2))
    ck = [F(0, o=.7, s=1), F(3.8), F(4.0, o=1, s=1.3), F(5.6), F(6.0, o=.7, s=1)]
    b.anim('cheekL', CHEEK_L[:2], ck)
    b.anim('cheekR', CHEEK_R[:2], ck)
    b.body = [F(0, x=0, y=0, sx=1, sy=1)] + bounce(3.4, 13) + [F(4.3, y=0), F(4.45, y=3, sx=1.02, sy=.98), F(4.6, y=0, s=1),
                                                             F(4.75, y=3, sx=1.02, sy=.98), F(4.9, y=0, s=1)]
    b.tilt = [F(0, r=-5), F(1.1), F(1.4, r=4), F(2.0), F(2.35, r=-5), F(3.35), F(3.5, r=0), F(5.6), F(6.4, r=-5)]
    b.tail = tail_mix([(.6, -1, -2), (1.45, 2, 3.5), (2.0, 0, 0), (2.45, -2, -3.5), (3.0, 0, 0)], bounce_tail(3.4, 1.2),
                      [(4.45, 1.5, 3), (4.75, 1.5, 3), (5.2, 0, 0), (6.4, -1.5, -3), (7.2, 1, 2)])
    b.glow = [F(0, o=.4, s=.9), F(1.5, o=.5, s=1), F(3.0, o=.4, s=.9), F(3.48, o=1, s=1.55), F(4.2, o=.7, s=1.15),
              F(5.5, o=.5, s=1), F(6.5, o=.4, s=.9)]
    b.ball = [F(0, s=1), F(3.45), F(3.55, s=1.2), F(3.75, s=1)]
    b.spark('orb', 'spark1', OX + 25, OY - 21, 10, '#FFE27A', [3.5])
    b.spark('orb', 'spark2', OX - 27, OY - 22, 8, '#FFC94D', [3.6], .5)
    b.spark('orb', 'spark3', OX + 28, OY + 16, 7.5, '#FFFFFF', [3.7], .45)
    return b


def giggly():
    b = Bot('giggly', 'Giggly', 'Can not stop laughing: giggle fits, catches its breath, then a big belly laugh with happy tears.', PAL['giggly'])
    b.add('face', cheek(CHEEK_L, 'cheekL', 1.2) + cheek(CHEEK_R, 'cheekR', 1.2))
    b.add('face', stroke(happy_arc_d(EL), 'arcL', w=7) + stroke(happy_arc_d(ER), 'arcR', w=7))
    b.add('face', eye(EL, 'kcEyeL', 'eyeL', 'iris', iris_tf=(-3, 0)) + eye(ER, 'kcEyeR', 'eyeR', 'iris', iris_tf=(-3, 0)), 'anim')
    b.add('face', stroke(smile_d(10, 12), 'smile', CORAL, 5), 'anim')
    b.add('face', grin('laugh'))
    for cls, x, y in (('tearL', 74, 148), ('tearR', 183, 144)):
        b.add('face', f'<path class="{cls}" d="{drop_d(x, y, 1.3)}" fill="#8FD8FF" stroke="#FFFFFF" stroke-width="1.5"/>', 'anim')
        b.anim(cls, (x, y), [F(0, o=0, y=0), F(5.3), F(5.45, o=1), F(6.2, o=1, y=12), F(6.45, o=0, y=16)])
    breath = (2.05, 3.3)
    eo = [F(0, o=0, sx=1, sy=.3), F(breath[0]), F(breath[0] + .08, o=1, sy=1), F(2.75), F(2.79, sy=.22), F(2.8, o=0),
          F(2.85, o=1), F(2.92, sy=1), F(breath[1] - .08), F(breath[1], o=0, sy=.3)]
    b.anim('eyeL', (EL[0], EL[1] + 3), eo)
    b.anim('eyeR', (ER[0], ER[1] + 3), eo)
    af = [F(0, o=1, sx=1, sy=1), F(breath[0]), F(breath[0] + .06, o=0, sy=.5), F(breath[1] - .06), F(breath[1] + .02, o=1, sx=1.12, sy=1.2),
          F(breath[1] + .14, s=1)]
    b.anim('arcL', EL[:2], af)
    b.anim('arcR', ER[:2], af)
    b.anim('smile', (MX, MY + 3), show([(breath[0], breath[1] - .1)], .1, .08))
    lf = [F(0, o=1, sx=1, sy=1)]
    for t0, t1, half, big in ((.2, 1.8, .18, 0), (3.35, 4.95, .18, 0), (5.1, 6.3, .3, 1), (6.4, 7.5, .22, 0)):
        t, i = t0, 0
        while t <= t1:
            lf.append(F(t, sx=(1.25 if big else 1.04) if i % 2 else (1.15 if big else 1), sy=(1.25 if big else 1.15) if i % 2 else (1.05 if big else .92)))
            t, i = t + half, i + 1
    lf += [F(1.95, sx=1, sy=1), F(breath[0], o=1), F(breath[0] + .08, o=0), F(breath[1] - .05, o=0, sx=.8, sy=.6),
           F(breath[1] + .05, o=1, s=1), F(7.7, sx=1, sy=1)]
    b.anim('laugh', (MX, MY + 1), lf)
    ck = [F(0, o=.85, s=1), F(5.1), F(5.3, o=1, s=1.3), F(6.3), F(6.6, o=.85, s=1)]
    b.anim('cheekL', CHEEK_L[:2], ck)
    b.anim('cheekR', CHEEK_R[:2], ck)
    body = [F(0, x=0, y=0, sx=1, sy=1)] + jiggle(.2, 1.8, .18, 3.5) + [F(1.95, y=0), F(2.4, sx=1.03, sy=.97), F(2.9, s=1)]
    body += jiggle(3.35, 4.95, .18, 3.5) + [F(5.1, y=0, sx=.98, sy=1.04)] + jiggle(5.2, 6.4, .3, 5) + [F(6.45, sx=1, sy=1)]
    body += jiggle(6.6, 7.4, .2, 1.5)
    b.body = body
    b.tilt = [F(0, r=0), F(.2), F(1.0, r=-3), F(1.8, r=2), F(2.1, r=0), F(3.3), F(4.1, r=3), F(4.9, r=-2), F(5.1, r=0),
              F(5.4, r=-9), F(6.3, r=-8), F(6.7, r=0)]
    keys = [(t, (-1) ** i * 1.2, (-1) ** i * 2.5) for i, t in enumerate([x / 100 for x in range(29, 181, 18)])]
    keys += [(2.1, 0, 0), (2.6, -1, -2), (3.2, 0, 0)]
    keys += [(t, (-1) ** i * 1.2, (-1) ** i * 2.5) for i, t in enumerate([x / 100 for x in range(344, 496, 18)])]
    keys += [(5.4, 3, 6), (5.75, -3, -6), (6.05, 3, 6), (6.4, -2, -4), (6.8, 1, 2), (7.3, -.8, -1.6)]
    b.tail = tail_mix(keys)
    b.glow = [F(0, o=.5, s=1), F(1.0, o=.75, s=1.12), F(2.0, o=.5, s=1), F(4.2, o=.75, s=1.12), F(5.8, o=.9, s=1.25), F(7.0, o=.5, s=1)]
    return b


def shy():
    b = Bot('shy', 'Shy', 'Bashful: peeks at you, gets caught and hides blushing, then a small happy smile.', PAL['shy'])
    b.add('face', cheek(CHEEK_L, 'cheekL', 1.3) + cheek(CHEEK_R, 'cheekR', 1.3))
    lines = ''
    for cx, cy in (CHEEK_L[:2], CHEEK_R[:2]):
        for i in range(3):
            x = cx - 6 + i * 5
            lines += f'<path d="M{pt((x, cy + 3))}L{pt((x + 3, cy - 3))}"/>'
    b.add('face', f'<g class="blushLines" fill="none" stroke="#B81E4A" stroke-width="2.4" stroke-linecap="round" opacity=".85">{lines}</g>')
    b.add('face', eye(EL, 'kcEyeL', 'eyeL', 'iris', crescent=False, lid=('lidL', .28), iris_tf=(1, 6)))
    b.add('face', eye(ER, 'kcEyeR', 'eyeR', 'iris', crescent=False, lid=('lidR', .28), iris_tf=(1, 6)))
    b.add('face', stroke(shut_d(EL), 'shutL') + stroke(shut_d(ER), 'shutR'), 'anim')
    b.add('face', stroke(happy_arc_d(EL), 'arcL') + stroke(happy_arc_d(ER), 'arcR'), 'anim')
    wob = f"M{pt((MX - 7, MY + 3))}Q{pt((MX - 3.5, MY))} {pt((MX, MY + 3))}T{pt((MX + 7, MY + 3))}"
    b.add('face', stroke(wob, 'wobble', CORAL, 4))
    b.add('face', stroke(smile_d(7, 8), 'smile', CORAL, 4.5), 'anim')
    b.add('head', f'<g class="tinyHeart"><path d="{heart_d(212, 122, 8.5)}" fill="#FF6F91" stroke="#FFFFFF" stroke-width="2"/></g>', 'anim')
    happy = (5.5, 6.5)
    blinks = (.9, 7.4)
    b.anim('eyeL', (EL[0], EL[1] + 3), eye_frames(blinks, [happy]))
    b.anim('eyeR', (ER[0], ER[1] + 3), eye_frames(blinks, [happy]))
    b.anim('shutL', None, shut_frames(blinks))
    b.anim('shutR', None, shut_frames(blinks))
    b.anim('arcL', EL[:2], arc_frames([happy]))
    b.anim('arcR', ER[:2], arc_frames([happy]))
    lid = [(0, .28), (1.6), (1.75, .1), (2.2), (2.3, .4), (4.5), (5.0, .15), (6.7), (7.0, .28)]
    for cls, e in (('lidL', EL), ('lidR', ER)):
        fr = []
        for item in lid:
            fr.append(F(item[0], y=item[1] * 2 * e[3]) if isinstance(item, tuple) else F(item))
        b.anim(cls, None, fr)
    b.anim('iris', None, [F(0, x=1, y=6), F(1.6), F(1.75, x=-2, y=0), F(2.2), F(2.3, x=-9, y=6), F(3.2), F(3.4, x=-4, y=7),
                          F(3.8), F(4.0, x=-8, y=6), F(4.5), F(5.0, x=-2, y=1), F(6.7), F(7.0, x=1, y=6)])
    b.anim('wobble', (MX, MY + 3), [F(0, o=1, x=0, s=1), F(2.3), F(2.4, x=-1), F(2.5, x=1), F(2.6, x=-1), F(2.7, x=1), F(2.8, x=0),
                                    F(5.05), F(5.15, o=0, s=.6), F(6.6), F(6.75, o=1, s=1)])
    b.anim('smile', (MX, MY + 3), show([(5.1, 6.65)], .12, .12))
    ck = [F(0, o=.85, s=1), F(2.25), F(2.4, o=1, s=1.35), F(3.8), F(4.4, o=.9, s=1.1), F(5.5, o=1, s=1.25), F(6.6), F(7.0, o=.85, s=1)]
    b.anim('cheekL', CHEEK_L[:2], ck)
    b.anim('cheekR', CHEEK_R[:2], ck)
    b.anim('blushLines', (130, 162), [F(0, o=.5), F(2.25), F(2.4, o=1), F(3.8), F(4.4, o=.6), F(5.5, o=1), F(6.6), F(7.0, o=.5)])
    b.anim('tinyHeart', (210, 124), rise([5.6], 1.1, 6, -30, .4, 1.1), timing='linear')
    body = [F(0, x=0, y=0, sx=1, sy=1), F(2.25, e=OUT_E), F(2.4, y=6, sx=1.05, sy=.9)]
    body += jiggle(2.45, 2.95, .1, 1.5, 'x') + [F(3.1, x=0), F(4.4), F(5.0, y=0, sx=1, sy=1)]
    body += [F(5.6, y=-3, sx=.98, sy=1.02), F(5.8, y=0, s=1), F(6.0, y=-3, sx=.98, sy=1.02), F(6.2, y=0, s=1)]
    b.body = body
    b.tilt = [F(0, r=0), F(.6, r=2), F(1.4, r=-1), F(1.7, r=0), F(2.25), F(2.4, r=8), F(3.4, r=6), F(3.9, r=8), F(4.5), F(5.0, r=0),
              F(5.6, r=-4), F(5.9, r=4), F(6.2, r=-3), F(6.5, r=0), F(7.2, r=1.5)]
    b.tail = tail_mix([(.6, -1, -2), (1.4, 1, 2), (2.0, 0, 0), (2.4, -4, -7), (2.6, 2.5, 5), (2.8, -2, -4), (3.0, 1.5, 3), (3.3, -1.5, -3),
                       (3.7, 1.5, 3), (4.1, -1.5, -3), (4.6, 1, 2), (5.1, 0, 0), (5.6, 2, 4), (5.9, -2, -4), (6.2, 1.5, 3),
                       (6.6, -.8, -1.6), (7.3, .8, 1.6)])
    b.glow = [F(0, o=.45, s=.95), F(2.4, o=.8, s=1.2), F(3.4, o=.5, s=1), F(5.7, o=.8, s=1.18), F(6.6, o=.45, s=.95)]
    return b


def focused():
    b = Bot('focused', 'Focused', 'Hard at work: reads with a determined look and tongue out, types, then finishes with a proud grin.', PAL['focused'])
    cheeks_both(b, False, .85)
    b.add('face', eye(EL, 'kcEyeL', 'eyeL', 'iris', crescent=False, lid=('lidL', .33), iris_tf=(-8, 1)))
    b.add('face', eye(ER, 'kcEyeR', 'eyeR', 'iris', crescent=False, lid=('lidR', .33), iris_tf=(-8, 1)))
    b.add('face', brow(EL, 'browL', 14, 3) + brow(ER, 'browR', -14, 3))
    b.add('face', f'<g class="focusMouth">{stroke(f"M{pt((MX - 8, MY + 4))}Q{pt((MX, MY + 2))} {pt((MX + 7, MY + 4))}", color=CORAL, w=4.5)}'
                  f'<ellipse class="tongue" cx="{MX + 8}" cy="{MY + 8}" rx="4.2" ry="5" fill="#FF8F98" stroke="#D9475E" stroke-width="1.5"/></g>')
    b.add('face', grin('grin'), 'anim')
    b.add('face', stroke(smile_d(10, 11), 'smile', CORAL, 5), 'anim')
    dots = ''.join(f'<circle cx="{f(OX + 28 * math.cos(math.radians(a)))}" cy="{f(OY + 28 * math.sin(math.radians(a)))}" r="{3.6 - i * .7}" fill="#FFFFFF" stroke="#4C9BFF" stroke-width="1.5"/>'
                   for i, a in enumerate((0, -40, -80)))
    b.add('orb', f'<g class="orbit"><g class="spin">{dots}</g></g>')
    b.add('orb', f'<g class="check">{stroke(f"M{pt((OX - 8, OY + 1))}L{pt((OX - 2, OY + 7))}L{pt((OX + 9, OY - 6))}", color="#FFFFFF", w=5)}</g>', 'anim')
    b.anim('spin', (OX, OY), [F(0, r=0), F(1, r=360)], dur=1, timing='linear')
    b.anim('orbit', (OX, OY), [F(0, o=1, s=1), F(4.35), F(4.5, o=0, s=1.4), F(6.9, o=0, s=.6), F(7.2, o=1, s=1)])
    b.anim('check', (OX, OY), show([(4.45, 5.9)], .12, .2, pop=.3))
    lid = [(0, .33), (4.35, .33), (4.45, 0), (6.7, 0), (7.1, .33)]
    for cls, e in (('lidL', EL), ('lidR', ER)):
        b.anim(cls, None, [F(t, y=v * 2 * e[3]) for t, v in lid])
    b.anim('iris', None, [F(0, x=-8, y=1), F(1.0, x=4, y=1), F(1.12, x=-8, y=3), F(2.1, x=4, y=3), F(2.22, x=-8, y=1),
                          F(3.2, x=4, y=1), F(3.4, x=-2, y=4), F(4.35), F(4.45, x=-2, y=0), F(6.7), F(7.6, x=-8, y=1)])
    for cls, e, r in (('browL', EL, 14), ('browR', ER, -14)):
        b.anim(cls, brow_center(e), [F(0, y=3, r=r), F(3.3), F(3.45, y=5, r=r * 1.3), F(4.35), F(4.5, y=-6, r=0), F(6.7),
                                     F(7.1, y=3, r=r)])
    b.anim('focusMouth', (MX, MY + 4), [F(0, o=1, s=1), F(4.35), F(4.42, o=0, s=.6), F(7.0), F(7.15, o=1, s=1)])
    b.anim('tongue', (MX + 6, MY + 6), [F(0, x=0, s=1), F(.5, x=1.2, sy=1.12), F(1.0, x=0, s=1), F(1.5, x=1.2, sy=1.12),
                                        F(2.0, x=0, s=1), F(2.5, x=1.2, sy=1.12), F(3.0, x=0, s=1)] +
                                       jiggle(3.4, 4.2, .2, -1.5, 'x'))
    b.anim('grin', (MX, MY + 1), [F(0, o=0, sx=.6, sy=.3), F(4.4), F(4.5, o=1, sx=1.06, sy=1.12), F(4.65, s=1), F(5.7),
                                  F(5.8, o=0, sx=.6, sy=.3)])
    b.anim('smile', (MX, MY + 3), show([(5.75, 7.0)], .1, .12))
    body = [F(0, x=0, y=0, sx=1, sy=1), F(3.3)]
    for t in (3.4, 3.6, 3.8, 4.0, 4.2):
        body += [F(t, y=0, sx=1, sy=1), F(t + .1, y=1.5, sx=1.02, sy=.97)]
    body += [F(4.35, y=0, sx=1, sy=1)] + bounce(4.4, 13, 1.1) + [F(5.8, y=0), F(5.95, y=3, sx=1.02, sy=.98), F(6.1, y=0, s=1),
                                                               F(6.25, y=3, sx=1.02, sy=.98), F(6.4, y=0, s=1)]
    b.body = body
    b.tilt = [F(0, r=-1.5), F(1.0, r=1.5), F(1.12, r=-1.5), F(2.1, r=1.5), F(2.22, r=-1.5), F(3.2, r=1.5), F(3.4, r=0),
              F(4.45), F(4.7, r=-4), F(5.0, r=3), F(5.3, r=0), F(6.7), F(7.6, r=-1.5)]
    b.tail = tail_mix([(.5, -1, -2), (1.0, 1, 2), (1.6, -1, -2), (2.1, 1, 2), (2.7, -1, -2), (3.2, 0, 0)] +
                      [(t + .1, .8 * (-1) ** i, 1.6 * (-1) ** i) for i, t in enumerate((3.4, 3.6, 3.8, 4.0))],
                      bounce_tail(4.4, 1.2), [(5.95, 1.5, 3), (6.25, 1.5, 3), (6.7, 0, 0), (7.3, -1, -2)])
    b.glow = [F(0, o=.5, s=1)] + [x for t in (0, .5, 1, 1.5, 2, 2.5, 3, 3.5) for x in (F(t + .25, o=.75, s=1.1), F(t + .5, o=.5, s=1))]
    b.glow += [F(4.5, o=1, s=1.5), F(5.3, o=.6, s=1.05), F(6.9, o=.5, s=1)]
    b.ball = [F(0, s=1), F(4.4), F(4.52, s=1.18), F(4.7, s=1)]
    b.spark('orb', 'spark1', OX + 25, OY - 21, 10, '#8CC4FF', [4.5])
    b.spark('orb', 'spark2', OX - 27, OY - 22, 8, '#FFD36E', [4.6], .5)
    return b


def wow():
    b = Bot('wow', 'Wow', 'Easily amazed: looks around, gets startled into a big wow, then sparkly-eyed delight.', PAL['wow'])
    spk = lambda e, k: f'<path d="{sparkle_d(e[0] + IRIS_SHIFT * k - 4 * k, e[1] + 5 * k, 4 * k)}" fill="#FFFFFF"/>'
    cheeks_both(b)
    for side, e, clip in (('L', EL, 'kcEyeL'), ('R', ER, 'kcEyeR')):
        k = e[2] / EL[2]
        b.add('face', eye(e, clip, f'eye{side}', f'iris{side}', extra_iris=f'<g class="twinkle{side}">{spk(e, k)}</g>',
                          open_tf=f"translate({f(e[0])} {f(e[1])}) scale(1.14) translate({f(-e[0])} {f(-e[1])})"))
    b.add('face', stroke(shut_d(EL), 'shutL') + stroke(shut_d(ER), 'shutR'), 'anim')
    b.add('face', brow(EL, 'browL', 0, -7) + brow(ER, 'browR', 0, -7))
    b.add('face', stroke(smile_d(), 'smile', CORAL, 5), 'anim')
    b.add('face', o_mouth('wowO', 7, 9, 6))
    b.add('face', grin('grin'), 'anim')
    b.add('head', punct('!', 'bang', 222, 108, 1.7, '#7C3AED'), 'anim')
    blinks = (.7, 7.2)
    big = [F(1.9, s=1), F(2.0, s=1.24), F(3.3), F(3.5, s=1.14), F(5.0), F(5.6, s=1)]
    for side, e in (('L', EL), ('R', ER)):
        b.anim(f'eye{side}', (e[0], e[1]), sorted(eye_frames(blinks, extra=big), key=lambda x: x[0]))
        k = e[2] / EL[2]
        ic = (e[0] + IRIS_SHIFT * k, e[1] + k)
        gaze = [F(0, x=0, y=0, s=1), F(.3), F(.5, x=-7, y=1), F(.9), F(1.1, x=2, y=0), F(1.5), F(1.65, x=0, y=0), F(1.95),
                F(2.0, x=-2, y=0, s=.62), F(3.3), F(3.5, s=1.12), F(5.0), F(5.2, x=2, y=-5), F(6.0), F(6.3, x=0, y=0, s=1)]
        b.anim(f'iris{side}', ic, gaze)
        b.anim(f'twinkle{side}', (ic[0] - 4 * k, ic[1] + 5 * k), [F(0, o=0, s=.5), F(3.4), F(3.55, o=1, s=1.3), F(3.8, s=.9), F(4.1, s=1.25),
                                                                  F(4.4, s=.9), F(4.7, s=1.2), F(5.4, o=1, s=1), F(5.8, o=0, s=.5)])
    b.anim('shutL', None, shut_frames(blinks))
    b.anim('shutR', None, shut_frames(blinks))
    for cls, e in (('browL', EL), ('browR', ER)):
        b.anim(cls, brow_center(e), [F(0, y=0, r=0), F(1.95), F(2.02, y=-9), F(3.3), F(3.6, y=-5), F(5.5), F(6.0, y=0)])
    b.anim('smile', (MX, MY + 3), [F(0, o=1, s=1), F(1.95), F(2.0, o=0, s=.6), F(5.5), F(5.65, o=1, s=1)])
    b.anim('wowO', (MX, MY + 4), [F(0, o=0, s=.4), F(1.95), F(2.03, o=1, s=1.15), F(2.15, s=1), F(2.8, sx=.9, sy=1.3), F(3.2, s=1),
                                  F(3.45), F(3.55, o=0, s=.5)])
    b.anim('grin', (MX, MY + 1), [F(0, o=0, sx=.6, sy=.3), F(3.5), F(3.6, o=1, s=1), F(5.5), F(5.6, o=0, sx=.6, sy=.3)])
    b.anim('bang', (222, 108), show([(2.0, 3.35)], .08, .15, pop=.2))
    ck = [F(0, o=.75, s=1), F(3.5), F(3.7, o=1, s=1.3), F(5.4), F(5.8, o=.75, s=1)]
    b.anim('cheekL', CHEEK_L[:2], ck)
    b.anim('cheekR', CHEEK_R[:2], ck)
    body = [F(0, x=0, y=0, sx=1, sy=1), F(1.9, e=OUT_E), F(2.05, y=-10, sx=.92, sy=1.1), F(2.25, y=-8, sx=1, sy=1)]
    body += jiggle(2.3, 3.1, .1, 1.2, 'x') + [F(3.2, x=0, y=-8, e=IN_E), F(3.4, y=0, sx=1.07, sy=.92, e=OUT_E), F(3.55, y=0, s=1)]
    body += bounce(3.75, 8) + bounce(4.3, 8)
    b.body = body
    b.tilt = [F(0, r=0), F(.3), F(.5, r=-3), F(.9), F(1.1, r=2), F(1.5), F(1.65, r=0), F(5.0), F(5.25, r=-4), F(6.0), F(6.3, r=0)]
    b.tail = tail_mix([(.5, -1, -2), (1.1, 1, 2), (1.6, 0, 0), (1.95, 3, 5), (2.08, -6, -11), (2.3, -4, -8), (3.2, -3, -6),
                       (3.4, 4, 8), (3.6, -1.5, -3)] + bounce_tail(3.75) + bounce_tail(4.3) + [(5.2, -1.5, -3), (6.0, 0, 0), (7.0, 1, 2)])
    b.glow = [F(0, o=.45, s=.9), F(1.6, o=.5, s=.95), F(1.85, o=1, s=1.5), F(2.6, o=.6, s=1.05), F(4.0, o=.8, s=1.2),
              F(5.5, o=.6, s=1.05), F(6.5, o=.45, s=.9)]
    b.ball = [F(0, s=1), F(1.75), F(1.88, s=1.2), F(2.05, s=1)]
    b.spark('orb', 'spark1', OX + 25, OY - 21, 10, '#C4B0FF', [1.8])
    b.spark('head', 'spark2', 40, 92, 8, '#FFD36E', [3.7])
    b.spark('head', 'spark3', 226, 150, 7.5, '#C4B0FF', [4.25])
    return b


BOTS = [winky, sleepy, starry, lovey, cool, thinker, giggly, shy, focused, wow]

if __name__ == '__main__':
    for make in BOTS:
        bot = make()
        open(f"{OUT}/casama-{bot.key}.svg", 'w').write(build(bot, False))
        open(f"{OUT}/casama-{bot.key}-animated.svg", 'w').write(build(bot, True))
    print('ok', len(BOTS))
