"""Encodes rendered PNG frames into a small transparent animated WebP for the app.

Called by kasama-mascot-render.mjs: python3 scripts/kasama-mascot-encode.py <frames_dir> <out.webp> <fps>

Fully transparent pixels get the colour of their nearest visible neighbours first ("alpha bleed"), so
lossy colour compression does not drag soft edges like the orb glow towards black.
"""
import os, sys
from PIL import Image, ImageChops, ImageFilter

frames_dir, out, fps = sys.argv[1], sys.argv[2], float(sys.argv[3])


def bleed(im):
    r, g, b, a = im.split()
    filled = Image.merge('RGB', (r, g, b))
    alpha = a
    for radius in (2, 6, 16):
        pre = ImageChops.multiply(filled, Image.merge('RGB', (alpha,) * 3)).filter(ImageFilter.GaussianBlur(radius))
        wa = alpha.filter(ImageFilter.GaussianBlur(radius))
        spread = pre.copy()  # premultiplied blur, divided by the blurred alpha below
        px, pa = spread.load(), wa.load()
        w, h = spread.size
        data = []
        for y in range(h):
            for x in range(w):
                k = pa[x, y]
                c = px[x, y]
                data.append((min(255, c[0] * 255 // k), min(255, c[1] * 255 // k), min(255, c[2] * 255 // k)) if k else (0, 0, 0))
        spread.putdata(data)
        mask = alpha.point(lambda v: 255 if v else 0)
        filled = Image.composite(filled, spread, mask)
        alpha = ImageChops.lighter(alpha, wa.point(lambda v: 255 if v else 0))
    out_im = filled.convert('RGBA')
    out_im.putalpha(a)
    return out_im


files = sorted(f for f in os.listdir(frames_dir) if f.endswith('.png'))
frames = [bleed(Image.open(os.path.join(frames_dir, f)).convert('RGBA')) for f in files]
frames[0].save(out, save_all=True, append_images=frames[1:], duration=round(1000 / fps), loop=0,
               quality=62, alpha_quality=40, method=4, exact=True, minimize_size=True, allow_mixed=False)
