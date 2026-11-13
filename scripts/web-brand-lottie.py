"""Puts the animated Casama brand mascot on the three websites (casama.ai, docs, gallery).

Run from the repo root after the app's brand Lottie changes (scripts/casama-mascot-lottie.py brand):
    python3 scripts/web-brand-lottie.py
Needs Pillow with WebP support.

- Writes site/assets/brand/casama-brand.json from client/assets/mascots/brand.json, with its baked
  cloud image re-encoded as WebP (about 15 KB instead of 78 KB). The motion is unchanged.
- Copies that file, site/assets/brand/casama-mark.js (the shared player script) and
  site/assets/brand/lottie_light.min.js (lottie-web's SVG-only build, MIT) to gallery/assets/brand/
  and docs-site/public/brand/, with the Libre Baskerville Bold the wordmark uses for the docs.
"""
import base64, io, json, os, shutil

from PIL import Image

SRC = 'client/assets/mascots/brand.json'
SITE = 'site/assets/brand'
COPIES = ['gallery/assets/brand', 'docs-site/public/brand']
SHARED = ['casama-brand.json', 'casama-mark.js', 'lottie_light.min.js']


def webp_data_uri(uri):
    raw = base64.b64decode(uri.split(',', 1)[1])
    out = io.BytesIO()
    Image.open(io.BytesIO(raw)).save(out, 'WEBP', quality=92, alpha_quality=95, method=6)
    return 'data:image/webp;base64,' + base64.b64encode(out.getvalue()).decode()


def main():
    data = json.load(open(SRC))
    for asset in data.get('assets', []):
        if asset.get('p', '').startswith('data:image/png'):
            asset['p'] = webp_data_uri(asset['p'])
    os.makedirs(SITE, exist_ok=True)
    with open(os.path.join(SITE, 'casama-brand.json'), 'w') as f:
        json.dump(data, f, separators=(',', ':'))
    for dest in COPIES:
        os.makedirs(dest, exist_ok=True)
        for name in SHARED:
            shutil.copyfile(os.path.join(SITE, name), os.path.join(dest, name))
    shutil.copyfile('site/assets/fonts/LibreBaskerville-Bold.woff2', 'docs-site/public/brand/LibreBaskerville-Bold.woff2')
    size = os.path.getsize(os.path.join(SITE, 'casama-brand.json'))
    print(f'casama-brand.json {size // 1024} KB -> {SITE}, ' + ', '.join(COPIES))


if __name__ == '__main__':
    main()
