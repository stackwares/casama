"""Builds the talking mascots for live calls: each Casama cloud bot as a Lottie with two loops.

Run from the repo root (needs what scripts/casama-mascot-lottie.py needs: Pillow, Node, Google Chrome):
    uv run --with pillow python3 scripts/casama-call-mascots.py [name ...]
Writes client/assets/mascots/<name>-call.json for the ten personalities plus `brand` (the app icon's
lavender cloud, for bots without a mascot).

The 8 second timeline holds two loops, marked in the Lottie:
- `listening` (0-4 s): the bot faces you with a soft smile, blinks, glances and nods, its orb breathing.
- `speaking` (4-8 s): its mouth moves in a syllable rhythm with a breath in the middle, it bounces a
  little, sways its tail and pulses its orb.
Both start and end in the same resting pose, so the app can loop either one and switch between them
(client/lib/features/voice/call_mascot.dart). The face, colours and orb come from each personality in
scripts/casama-cloud-svg.py; the conversion is scripts/casama-mascot-lottie.py.
"""
import importlib.util
import json
import os
import random
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))


def load(name, file):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, file))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


svg = load('casama_cloud_svg', 'casama-cloud-svg.py')
lottie = load('casama_mascot_lottie', 'casama-mascot-lottie.py')
F, T = svg.F, svg.T
HALF = T / 2
FR = lottie.FR
# The app plays each loop a few frames inside its edges, where both loops sit in the resting pose.
EDGE = 2


def talk_frames(seed, t0, t1, pause):
    """The talking mouth: syllables of varied size every 0.15-0.22 s, closed for a breath at [pause]."""
    rng = random.Random(seed)
    fr = [F(0, o=0, sx=.9, sy=.25), F(t0 - .02, o=0, sx=.9, sy=.25), F(t0 + .03, o=1, sx=.9, sy=.3)]
    t = t0 + .06
    while t < t1 - .2:
        if pause[0] <= t < pause[1]:
            fr.append(F(t, sx=1, sy=.22))
            t = pause[1]
            continue
        open_ = rng.uniform(.55, 1.0)
        step = rng.uniform(.15, .22)
        fr += [F(t + step * .45, sx=rng.uniform(.82, 1.0), sy=open_), F(t + step, sx=1.0, sy=rng.uniform(.18, .32))]
        t += step
    fr += [F(t1 - .06, sx=.9, sy=.25), F(t1 - .02, o=1), F(t1, o=0)]
    return fr


def call_bot(make):
    base = make()
    b = svg.Bot(base.key, base.title, 'Live call: listening (0-4 s) and speaking (4-8 s).', base.pal, base.orb)
    EL, ER, MX, MY = svg.EL, svg.ER, svg.MX, svg.MY

    svg.cheeks_both(b)
    b.add('face', svg.eye(EL, 'kcEyeL', 'eyeL', 'iris'))
    b.add('face', svg.eye(ER, 'kcEyeR', 'eyeR', 'iris'))
    b.add('face', svg.stroke(svg.shut_d(EL), 'shutL') + svg.stroke(svg.shut_d(ER), 'shutR'), 'anim')
    b.add('face', svg.stroke(svg.smile_d(), 'smile', svg.CORAL, 5))
    b.add('face', svg.o_mouth('talk', 12, 13, 7), 'anim')

    # Blinks, away from the loop edges.
    blinks = (1.35, 3.15, 5.25, 7.1)
    b.anim('eyeL', (EL[0], EL[1] + 3), svg.eye_frames(blinks))
    b.anim('eyeR', (ER[0], ER[1] + 3), svg.eye_frames(blinks))
    b.anim('shutL', None, svg.shut_frames(blinks))
    b.anim('shutR', None, svg.shut_frames(blinks))
    # Listening: looks at you, glances up as if taking it in, back. Speaking: livelier, explaining.
    b.anim('iris', None, [F(0, x=0, y=0), F(.9), F(1.15, x=-2, y=-3), F(1.9), F(2.15, x=0, y=0), F(2.9), F(3.1, x=1.5, y=0),
                          F(3.6), F(3.85, x=0, y=0),
                          F(4.6), F(4.8, x=-4, y=-2), F(5.5), F(5.7, x=2, y=-1), F(6.5), F(6.7, x=-1, y=0), F(7.4),
                          F(7.7, x=0, y=0)])
    # The smile while listening; the talking mouth while speaking (both swap in a frame or two).
    b.anim('smile', (MX, MY + 3), [F(0, o=1, s=1), F(1.6), F(1.85, sx=1.12, sy=1.1), F(2.6), F(2.85, s=1),
                                   F(HALF - .02, o=1, s=1), F(HALF + .03, o=0, s=.6), F(T - .03, o=0, s=.6), F(T, o=1, s=1)])
    b.anim('talk', (MX, MY + 4), talk_frames(base.key, HALF, T, (5.85, 6.15)))
    ck = [F(0, o=.75, s=1), F(1.6), F(1.85, o=.9, s=1.12), F(2.6), F(2.85, o=.75, s=1),
          F(4.8), F(5.0, o=.95, s=1.15), F(5.7), F(5.9, o=.75, s=1), F(6.8), F(7.0, o=.95, s=1.12), F(7.6), F(7.8, o=.75, s=1)]
    b.anim('cheekL', svg.CHEEK_L[:2], ck)
    b.anim('cheekR', svg.CHEEK_R[:2], ck)

    # Body: a slow nod while listening; little bounces on the beats while speaking.
    b.body = ([F(0, x=0, y=0, sx=1, sy=1), F(1.55), F(1.8, y=3, sx=1.02, sy=.98), F(2.1, y=0, s=1), F(2.25, y=2, sx=1.01, sy=.99),
               F(2.5, y=0, s=1)]
              + svg.bounce(4.55, 5, .6) + svg.bounce(6.3, 6, .7) + svg.bounce(7.15, 4, .5))
    b.tilt = [F(0, r=0), F(.6), F(1.0, r=-3), F(3.2), F(3.7, r=0),
              F(4.2), F(4.5, r=2.5), F(5.2), F(5.5, r=-2.5), F(6.6), F(6.9, r=2), F(7.5), F(7.8, r=0)]
    b.tail = svg.tail_mix([(.8, -1, -2), (1.9, 1, 2), (3.0, -1, -2), (3.8, 0, 0)],
                          [(4.3, 1.5, 3), (4.7, -2, -4)] + svg.bounce_tail(4.55, .7) + [(5.4, 2, 4), (5.9, -1.5, -3)]
                          + svg.bounce_tail(6.3, .8) + svg.bounce_tail(7.15, .6) + [(7.85, 0, 0)])
    b.float_amp = 2
    # The orb breathes while listening and pulses with the speech.
    b.glow = [F(0, o=.45, s=.9), F(2, o=.62, s=1.06), F(HALF, o=.45, s=.9)]
    t, pulse = HALF + .1, []
    while t < T - .3:
        pulse += [F(t, o=.5, s=.95), F(t + .18, o=.9, s=1.22)]
        t += .42
    b.glow += pulse + [F(T - .1, o=.45, s=.9)]
    b.ball = [F(0, s=1), F(HALF + .2), F(HALF + .3, s=1.08), F(HALF + .45, s=1), F(6.3), F(6.4, s=1.1), F(6.55, s=1)]
    return b


def build_all(names):
    makers = {m().key: m for m in svg.BOTS}
    makers['brand'] = svg.brand
    names = names or [*makers]
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, 'svg')
        os.makedirs(src)
        lottie.SRC = src
        for name in names:
            bot = call_bot(makers[name])
            bot.key = name
            with open(os.path.join(src, f'casama-{name}-call-animated.svg'), 'w') as fh:
                fh.write(svg.build(bot, True))
            data = lottie.convert(f'{name}-call', tmp)
            data['nm'] = f'Casama {bot.title} on a call'
            data['markers'] = [
                {'cm': 'listening', 'tm': EDGE, 'dr': int(HALF * FR) - 2 * EDGE},
                {'cm': 'speaking', 'tm': int(HALF * FR) + EDGE, 'dr': int(HALF * FR) - 2 * EDGE},
            ]
            out = os.path.join(lottie.OUT, f'{name}-call.json')
            with open(out, 'w') as fh:
                json.dump(data, fh, separators=(',', ':'))
            print(f'{name}-call: {len(data["layers"])} layers, {os.path.getsize(out) // 1024} KB')


if __name__ == '__main__':
    build_all(sys.argv[1:])
