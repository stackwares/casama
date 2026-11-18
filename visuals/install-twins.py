#!/usr/bin/env python3
"""Installs the light/dark twins of the gallery's painted wallpapers (D-388).

    python3 visuals/install-twins.py            # every twin found in visuals/round-6/raw/
    python3 visuals/install-twins.py aurora tide

- wall-<id>-dark.png, a light painting's night version, becomes <id>-dark.jpg + thumb-dark.jpg.
- wall-<id>-day.png, a night painting's day version, becomes <id>.jpg + thumb.jpg, and the night
  painting moves to <id>-dark.jpg + thumb-dark.jpg.
- wallpaper.json gets `dark` and `darkThumb`. The wallpaper and every theme that uses it get version + 1,
  so people already using them see an update. Running it again only refreshes the images.
Run `node gallery/check.mjs` afterwards.
"""
import glob, json, os, shutil, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GALLERY = os.path.join(ROOT, 'gallery')
RAW = os.path.join(ROOT, 'visuals', 'round-6', 'raw')
TODAY = '2026-11-18'

# install-walls.py's jpeg() (square crop, resize, JPEG at the gallery's quality), without running
# its install loop at the bottom.
_walls = os.path.join(ROOT, 'visuals', 'install-walls.py')
_scope = {'__file__': _walls}
exec(compile(open(_walls).read().split('\nids = ')[0], _walls, 'exec'), _scope)
jpeg = _scope['jpeg']


def load(path):
    return json.load(open(path))


def save(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')


def bump(item_path, note):
    item = load(item_path)
    item['version'] = int(item.get('version', 1)) + 1
    log = item.get('changelog') or [{'version': 1, 'date': item.get('added', TODAY), 'note': 'First version.'}]
    item['changelog'] = [{'version': item['version'], 'date': TODAY, 'note': note}] + log
    save(item_path, item)
    return item['version']


def install(wid):
    d = os.path.join(GALLERY, 'wallpapers', wid)
    night = os.path.join(RAW, f'wall-{wid}-dark.png')
    day = os.path.join(RAW, f'wall-{wid}-day.png')
    wall_path = os.path.join(d, 'wallpaper.json')
    if not os.path.exists(wall_path):
        return print(f'skip {wid}: no gallery wallpaper')
    wall = load(wall_path)
    had_twin = 'dark' in wall
    if os.path.exists(night):
        jpeg(night, os.path.join(d, f'{wid}-dark.jpg'), 2400)
        jpeg(night, os.path.join(d, 'thumb-dark.jpg'), 640)
    elif os.path.exists(day):
        if not had_twin:  # the night painting becomes the dark version, once
            shutil.move(os.path.join(d, wall['file']), os.path.join(d, f'{wid}-dark.jpg'))
            shutil.move(os.path.join(d, wall.get('thumb', 'thumb.jpg')), os.path.join(d, 'thumb-dark.jpg'))
        jpeg(day, os.path.join(d, f'{wid}.jpg'), 2400)
        jpeg(day, os.path.join(d, 'thumb.jpg'), 640)
    else:
        return print(f'skip {wid}: no twin in {RAW}')
    save(wall_path, {'kind': 'image', 'file': f'{wid}.jpg', 'thumb': 'thumb.jpg',
                     'dark': f'{wid}-dark.jpg', 'darkThumb': 'thumb-dark.jpg'})
    if had_twin:
        return print(f'{wid}: images refreshed')
    v = bump(os.path.join(d, 'item.json'), 'A day and a night version: it follows light and dark mode.')
    themes = []
    for t in sorted(glob.glob(os.path.join(GALLERY, 'themes', '*', 'theme.json'))):
        if (load(t).get('wallpaper') or {}).get('image') == wid:
            tid = os.path.basename(os.path.dirname(t))
            bump(os.path.join(os.path.dirname(t), 'item.json'),
                 'The painting has a night version now, for dark mode.')
            themes.append(tid)
    kb = os.path.getsize(os.path.join(d, f'{wid}-dark.jpg')) // 1024
    print(f'{wid}: v{v}, dark {kb} KB' + (f', themes {", ".join(themes)}' if themes else ''))


ids = sys.argv[1:] or sorted({os.path.basename(p)[5:].rsplit('-', 1)[0] for p in glob.glob(os.path.join(RAW, 'wall-*-*.png'))
                      if p.endswith(('-dark.png', '-day.png'))})
for wid in ids:
    install(wid)
