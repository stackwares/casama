"""Makes the app's mascot pictures WebP, which loads in about a third of the bytes.

Run from the repo root after the mascots change (needs Pillow with WebP support):
    uv run --with pillow python3 scripts/casama-mascot-webp.py
Safe to run again: only what is still PNG changes.

- Each Lottie in client/assets/mascots/*.json carries its baked cloud as an embedded image. A PNG
  one is re-encoded as WebP (Flutter's lottie decodes either). scripts/casama-mascot-lottie.py
  writes WebP itself now, so this only matters for files made before that.
- Each still pose client/assets/mascots/<name>.png gets a <name>.webp beside it, which the app
  shows (lib/ui/mascot.dart, lib/ui/brand_splash.dart). The PNGs stay: the Mac's notch island reads
  them from the app's assets (client/macos/Runner/Island.swift), and the widget art comes from them.
"""
import base64, glob, io, json, os

from PIL import Image

DIR = 'client/assets/mascots'
QUALITY = dict(quality=92, alpha_quality=95, method=6)


def webp_bytes(img):
    out = io.BytesIO()
    img.save(out, 'WEBP', **QUALITY)
    return out.getvalue()


def lotties():
    for path in sorted(glob.glob(f'{DIR}/*.json')):
        data = json.load(open(path))
        changed = False
        for asset in data.get('assets', []):
            uri = asset.get('p', '')
            if uri.startswith('data:image/png'):
                img = Image.open(io.BytesIO(base64.b64decode(uri.split(',', 1)[1])))
                asset['p'] = 'data:image/webp;base64,' + base64.b64encode(webp_bytes(img)).decode()
                changed = True
        if changed:
            before = os.path.getsize(path)
            with open(path, 'w') as fh:
                json.dump(data, fh, separators=(',', ':'))
            print(f'{os.path.basename(path)}: {before // 1024} KB -> {os.path.getsize(path) // 1024} KB')


def stills():
    for path in sorted(glob.glob(f'{DIR}/*.png')):
        out = path[:-4] + '.webp'
        if os.path.exists(out) and os.path.getmtime(out) >= os.path.getmtime(path):
            continue
        with open(out, 'wb') as fh:
            fh.write(webp_bytes(Image.open(path)))
        print(f'{os.path.basename(out)}: {os.path.getsize(path) // 1024} KB PNG -> {os.path.getsize(out) // 1024} KB')


if __name__ == '__main__':
    lotties()
    stills()
