# Casama gallery

The public catalog is [stackwares/casama-gallery](https://github.com/stackwares/casama-gallery).
A pull request there is how a theme, color scheme, wallpaper or skill reaches every app.

Themes, color schemes, wallpapers and skills for Casama. A pull request is how someone contributes.
Casama reviews it, and a merge is what every app sees, without an app release.

Each item is a folder:

```text
themes/<id>/item.json
themes/<id>/theme.json
schemes/<id>/item.json
schemes/<id>/scheme.json
wallpapers/<id>/item.json
wallpapers/<id>/wallpaper.json
skills/<id>/item.json
skills/<id>/SKILL.md
```

`item.json` names the author and the license. Looks use CC0-1.0 or CC-BY-4.0. Skills use MIT or Apache-2.0.
Color schemes give a seed, a background and a text color for light and dark. Text on the background has to
pass WCAG AA. Fonts have to be ones the app already ships. Photos from Unsplash's API stay in photo search
and are not copied here.

An image wallpaper can add a `thumb` (a small copy, at most 200 KB) that cards load instead of the full
image. A skill's `item.json` can name a Lucide `icon` (`notebook-pen`) for its tile.

`index.json` carries each look's document and each skill's description and icon, so the app and this site
draw previews from the list alone. `gallery.js` and `gallery.css` draw them on the web: the app's small
chat in a theme's colors, fonts and background, a scheme's colors as fields, and wallpapers. casama.ai's
item pages load the same two files. The pattern glyphs inside `gallery.js` are Lucide icons (ISC).

Check the tree and refresh `index.json`:

```sh
node scripts/casama-gallery-check.mts
```
