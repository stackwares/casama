"""Makes the launch screens: the transparent lavender Casama cloud centred on the app's own background, light or dark
to match the system. The cloud is the first frame of its loop (client/assets/bots/casama-brand-animated.svg from
scripts/casama-cloud-svg.py, played in the app as assets/mascots/brand.json), so the app's own splash takes over
from the launch screen without a visible change and then plays the loop (D-198).

Run from the repo root after scripts/casama-mascot-lottie.py brand (needs Pillow, Node and Google Chrome):
    python3 scripts/casama-splash.py

Writes:
- Android: drawable-*dpi/launch_logo.png (Android 8-11), drawable-*dpi/splash_icon.png (Android 12+ system
  splash), values[-night]/colors.xml and values[-night]-v31/styles.xml
- iOS: LaunchImage.imageset, LaunchBackground.colorset and LaunchScreen.storyboard
- Web: web/splash/casama.png (index.html shows it until Flutter's first frame)
- App: assets/mascots/brand-splash.png (the same still, shown until the loop has loaded) and
  lib/ui/splash_art.g.dart (where the cloud sits in the loop's 256 x 256 box, and the widths per platform)
"""
import json, os, re, subprocess, tempfile

from PIL import Image

CLIENT = 'client'
LIGHT, DARK = '#FCF3FB', '#25102F'  # sign-in background; the default dark wallpaper
WIDTH = 160                        # cloud width in pt / CSS px (iOS, web, desktop)
# Android 12+ draws the splash icon on a 288dp canvas and masks it to a 192dp circle: the cloud (tail and orb
# included) is about square, so it must stay within 192/sqrt(2) ~ 136dp. Older Android shows the same size so the app
# hands over from either at one width.
ANDROID_WIDTH = 134
RENDER = 2048                      # px for the 256 unit art box
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
RES = f'{CLIENT}/android/app/src/main/res'


# Holds every CSS animation and the SMIL tail morph at their first frame.
FREEZE = ('<style>*{animation-play-state:paused!important;animation-delay:0s!important}</style>'
          '<script>document.currentScript.closest("svg").pauseAnimations();'
          'document.currentScript.closest("svg").setCurrentTime(0)</script>')


def render_cloud():
    """The brand cloud at the first frame of its loop, cropped to its pixels, and its box in art units."""
    svg = open(f'{CLIENT}/assets/bots/casama-brand-animated.svg').read()
    svg = re.sub(r'(<svg[^>]*>)', lambda m: m.group(1) + FREEZE, svg, count=1)
    with tempfile.TemporaryDirectory() as tmp:
        src, out = os.path.join(tmp, 'brand.svg'), os.path.join(tmp, 'brand.png')
        open(src, 'w').write(svg)
        subprocess.run(['node', 'scripts/casama-mascot-render.mjs', '--svg', str(RENDER), src, out],
                       check=True, stdout=subprocess.DEVNULL)
        img = Image.open(out).convert('RGBA')
    box = img.getchannel('A').getbbox()
    return img.crop(box), [v * 256 / RENDER for v in box]


def fit(cloud, width):
    h = round(cloud.height * width / cloud.width)
    return cloud.resize((width, h), Image.LANCZOS)


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write(text)


def android(cloud):
    for name, k in DENSITIES.items():
        save(fit(cloud, round(ANDROID_WIDTH * k)), f'{RES}/drawable-{name}/launch_logo.png')
        canvas = Image.new('RGBA', (round(288 * k),) * 2, (0, 0, 0, 0))
        icon = fit(cloud, round(ANDROID_WIDTH * k))
        canvas.alpha_composite(icon, ((canvas.width - icon.width) // 2, (canvas.height - icon.height) // 2))
        save(canvas, f'{RES}/drawable-{name}/splash_icon.png')
    old = f'{RES}/drawable-nodpi/launch_logo.png'
    if os.path.exists(old):
        os.remove(old)
        if not os.listdir(os.path.dirname(old)):
            os.rmdir(os.path.dirname(old))
    layers = '''<?xml version="1.0" encoding="utf-8"?>
<!-- Launch screen before Android 12; made by scripts/casama-splash.py. -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <color android:color="@color/splash_background" />
    </item>
    <item>
        <bitmap android:gravity="center" android:src="@drawable/launch_logo" />
    </item>
</layer-list>
'''
    write(f'{RES}/drawable/launch_background.xml', layers)
    write(f'{RES}/drawable-v21/launch_background.xml', layers)
    for qual, col, parent in (('', LIGHT, 'Theme.Light.NoTitleBar'), ('-night', DARK, 'Theme.Black.NoTitleBar')):
        write(f'{RES}/values{qual}/colors.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Made by scripts/casama-splash.py. -->
<resources>
    <color name="splash_background">{col}</color>
</resources>
''')
        write(f'{RES}/values{qual}-v31/styles.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Android 12+ system splash: the Casama cloud on the app background. Made by scripts/casama-splash.py. -->
<resources>
    <style name="LaunchTheme" parent="@android:style/{parent}">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/splash_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_icon</item>
    </style>
</resources>
''')


def ios(cloud):
    assets = f'{CLIENT}/ios/Runner/Assets.xcassets'
    for k, suffix in ((1, ''), (2, '@2x'), (3, '@3x')):
        save(fit(cloud, WIDTH * k), f'{assets}/LaunchImage.imageset/LaunchImage{suffix}.png')

    def rgb(hexc):
        return {k: f'0x{hexc[i:i + 2]}' for k, i in (('red', 1), ('green', 3), ('blue', 5))}

    write(f'{assets}/LaunchBackground.colorset/Contents.json', json.dumps({
        'colors': [
            {'idiom': 'universal', 'color': {'color-space': 'srgb', 'components': {**rgb(LIGHT), 'alpha': '1.000'}}},
            {'idiom': 'universal', 'appearances': [{'appearance': 'luminosity', 'value': 'dark'}],
             'color': {'color-space': 'srgb', 'components': {**rgb(DARK), 'alpha': '1.000'}}},
        ],
        'info': {'author': 'xcode', 'version': 1},
    }, indent=2) + '\n')
    sb_path = f'{CLIENT}/ios/Runner/Base.lproj/LaunchScreen.storyboard'
    sb = open(sb_path).read()
    h = round(cloud.height * WIDTH / cloud.width)
    sb = re.sub(r'<color key="backgroundColor"[^>]*/>', '<color key="backgroundColor" name="LaunchBackground"/>', sb)
    sb = re.sub(r'<image name="LaunchImage"[^>]*/>', f'<image name="LaunchImage" width="{WIDTH}" height="{h}"/>', sb)
    if 'Named colors' not in sb:
        sb = sb.replace('</dependencies>', '    <capability name="Named colors" minToolsVersion="9.0"/>\n    </dependencies>')
    l = [int(LIGHT[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    named = (f'<namedColor name="LaunchBackground">\n            <color red="{l[0]:.3f}" green="{l[1]:.3f}" blue="{l[2]:.3f}" '
             f'alpha="1" colorSpace="custom" customColorSpace="sRGB"/>\n        </namedColor>')
    sb = re.sub(r'\s*<namedColor name="LaunchBackground">.*?</namedColor>', '', sb, flags=re.S)
    sb = sb.replace('</resources>', f'    {named}\n    </resources>')
    write(sb_path, sb)


def web(cloud):
    save(fit(cloud, WIDTH * 3), f'{CLIENT}/web/splash/casama.png')


def app(cloud, box):
    save(fit(cloud, WIDTH * 4), f'{CLIENT}/assets/mascots/brand-splash.png')
    l, t, r, b = (round(v, 3) for v in box)
    write(f'{CLIENT}/lib/ui/splash_art.g.dart', f'''// Made by scripts/casama-splash.py; do not edit.

/// Where the cloud sits in the first frame of assets/mascots/brand.json, in the loop's 256 x 256 units: the part of it
/// the launch screens show (assets/mascots/brand-splash.png).
const splashCloudBox = (left: {l}, top: {t}, right: {r}, bottom: {b});

/// The cloud's width on the launch screen in logical pixels: iOS, web and desktop.
const splashCloudWidth = {WIDTH}.0;

/// The cloud's width on Android's launch screens (the Android 12+ splash icon must fit its circle mask).
const splashCloudWidthAndroid = {ANDROID_WIDTH}.0;
''')


def main():
    cloud, box = render_cloud()
    android(cloud)
    ios(cloud)
    web(cloud)
    app(cloud, box)
    print('launch screens written')


if __name__ == '__main__':
    main()
