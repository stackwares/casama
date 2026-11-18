#!/usr/bin/env python3
"""Installs generated wallpapers into gallery/wallpapers/ (D-379).

    python3 visuals/install-walls.py            # every wall-<id>.png found in visuals/round-*/raw/
    python3 visuals/install-walls.py aurora tide

- An existing wallpaper keeps its id, name, tags and featured flag, becomes an image wallpaper and gets
  version + 1, so sets and people already using it get the new art. Old image files are removed.
- A new id gets a fresh item.json (Casama, CC0-1.0) with the name and tags from NEW below.
- Writes <id>.jpg at 2400 px and thumb.jpg at 640 px with sips. Run `node gallery/check.mjs` afterwards.
"""
import glob, json, os, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WALLS = os.path.join(ROOT, 'gallery', 'wallpapers')
QUALITY = '62'
TODAY = '2026-11-18'

# Names and tags for wallpapers that don't exist yet.
NEW = {
    'cloud-sea': ('Cloud sea', ['calm', 'sky']),
    'lavender-hills': ('Lavender hills', ['calm', 'purple']),
    'moonlit-garden': ('Moonlit garden', ['night', 'flowers']),
    'paper-cranes': ('Paper cranes', ['calm', 'light']),
    'tea-morning': ('Tea morning', ['warm', 'light']),
    'tidepool': ('Tidepool', ['sea', 'pastel']),
    'starlit-lake': ('Starlit lake', ['night', 'calm']),
    'citrus-grove': ('Citrus grove', ['bright', 'warm']),
    'rain-window': ('Rain window', ['cozy', 'city']),
    'koi-pond': ('Koi pond', ['water', 'calm']),
    'desert-bloom': ('Desert bloom', ['warm', 'flowers']),
    'northern-pines': ('Northern pines', ['forest', 'green']),
    'candy-sky': ('Candy sky', ['pastel', 'playful']),
    'mountain-mist': ('Mountain mist', ['calm', 'cool']),
    'lantern-night': ('Lantern night', ['night', 'warm']),
}
# New one-line picks where the old one described the old art.
PICKS = {
    'dusk': 'A warm painted sunset that sits quietly behind your chats.',
    'petal': 'Soft pink petals drifting over a blush wash.',
}


def source(wid):
    found = sorted(glob.glob(os.path.join(ROOT, 'visuals', 'round-*', 'raw', f'wall-{wid}.png')))
    return found[-1] if found else None  # the newest round wins


def jpeg(src, out, size):
    with tempfile.TemporaryDirectory() as tmp:
        t = os.path.join(tmp, 'w.png')
        subprocess.run(['cp', src, t], check=True)
        w = int(subprocess.run(['sips', '-g', 'pixelWidth', t], capture_output=True, text=True).stdout.split()[-1])
        h = int(subprocess.run(['sips', '-g', 'pixelHeight', t], capture_output=True, text=True).stdout.split()[-1])
        n = min(w, h)
        subprocess.run(['sips', '--cropToHeightWidth', str(n), str(n), t], check=True, capture_output=True)
        subprocess.run(['sips', '-z', str(size), str(size), t], check=True, capture_output=True)
        subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', QUALITY, t, '--out', out], check=True, capture_output=True)


def install(wid):
    src = source(wid)
    if not src:
        return print(f'skip {wid}: no wall-{wid}.png')
    d = os.path.join(WALLS, wid)
    item_path = os.path.join(d, 'item.json')
    wall_path = os.path.join(d, 'wallpaper.json')
    os.makedirs(d, exist_ok=True)
    if os.path.exists(item_path):
        item = json.load(open(item_path))
        old = json.load(open(wall_path)) if os.path.exists(wall_path) else {}
        was_new_today = item.get('added') == TODAY and item.get('version') == 1
        if not was_new_today:  # an older wallpaper gets new art: bump its version
            item['version'] = int(item.get('version', 1)) + 1
            log = item.get('changelog') or [{'version': 1, 'date': item.get('added', TODAY), 'note': 'First version.'}]
            item['changelog'] = [{'version': item['version'], 'date': TODAY, 'note': 'New painted art in the same mood.'}] + log
        if wid in PICKS:
            item['pick'] = PICKS[wid]
        for key in ('file', 'thumb'):
            f = old.get(key)
            if f and f not in (f'{wid}.jpg', 'thumb.jpg') and os.path.exists(os.path.join(d, f)):
                os.remove(os.path.join(d, f))
    else:
        name, tags = NEW[wid]
        item = {'name': name, 'author': {'name': 'Casama', 'url': 'https://casama.ai', 'handle': 'casama'},
                'license': 'CC0-1.0', 'tags': tags, 'featured': False, 'version': 1, 'added': TODAY}
    jpeg(src, os.path.join(d, f'{wid}.jpg'), 2400)
    jpeg(src, os.path.join(d, 'thumb.jpg'), 640)
    json.dump({'kind': 'image', 'file': f'{wid}.jpg', 'thumb': 'thumb.jpg'}, open(wall_path, 'w'), indent=2)
    open(wall_path, 'a').write('\n')
    json.dump(item, open(item_path, 'w'), indent=2, ensure_ascii=False)
    open(item_path, 'a').write('\n')
    kb = os.path.getsize(os.path.join(d, f'{wid}.jpg')) // 1024
    print(f'{wid}: v{item["version"]}, {kb} KB')


ids = sys.argv[1:] or sorted({os.path.basename(p)[5:-4] for p in glob.glob(os.path.join(ROOT, 'visuals', 'round-*', 'raw', 'wall-*.png'))})
for wid in ids:
    install(wid)
