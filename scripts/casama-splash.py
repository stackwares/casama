"""Makes the launch screens: the transparent lavender Casama cloud (client/assets/bots/casama-brand.svg from
scripts/casama-cloud-svg.py) centred on the app's own background, light or dark to match the system.

Run from the repo root (needs Pillow, Node and Google Chrome):
    python3 scripts/casama-splash.py

Writes:
- Android: drawable-*dpi/launch_logo.png (Android 8-11), drawable-*dpi/splash_icon.png (Android 12+ system
  splash), values[-night]/colors.xml and values[-night]-v31/styles.xml
- iOS: LaunchImage.imageset, LaunchBackground.colorset and LaunchScreen.storyboard
- Web: web/splash/casama.png (index.html shows it until Flutter's first frame)
"""
import json, os, re, subprocess, tempfile

from PIL import Image

CLIENT = 'client'
LIGHT, DARK = '#FCF3FB', '#25102F'  # sign-in background; the default dark wallpaper
WIDTH = 160                        # cloud width in dp / pt / CSS px
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
RES = f'{CLIENT}/android/app/src/main/res'


def render_cloud():
    """The brand cloud, cropped to its pixels, at high resolution."""
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, 'brand.png')
        subprocess.run(['node', 'scripts/casama-mascot-render.mjs', '--svg', '2048', f'{CLIENT}/assets/bots/casama-brand.svg', out],
                       check=True, stdout=subprocess.DEVNULL)
        img = Image.open(out).convert('RGBA')
    return img.crop(img.getchannel('A').getbbox())


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
        save(fit(cloud, round(WIDTH * k)), f'{RES}/drawable-{name}/launch_logo.png')
        # Android 12+ draws the splash icon on a 288dp canvas and masks it to a 192dp circle: the cloud (tail and orb
        # included) is about square, so it must stay within 192/sqrt(2) ~ 136dp.
        canvas = Image.new('RGBA', (round(288 * k),) * 2, (0, 0, 0, 0))
        icon = fit(cloud, round(134 * k))
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


def main():
    cloud = render_cloud()
    android(cloud)
    ios(cloud)
    web(cloud)
    print('launch screens written')


if __name__ == '__main__':
    main()
