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

A mesh wallpaper (`"kind": "mesh"`) is a pattern wallpaper plus a `mesh`: nine light and nine dark
`#RRGGBB` colors, row by row from the top left, and optionally nine `[x, y]` points as fractions of the
window. Corners stay on corners, edge points on their edge, and inner points between 0.2 and 0.8. Light
colors need a luminance of at least 0.55 and dark ones at most 0.05, so text on top stays readable. Its
`palette` is the fallback that apps from before mesh support draw, so it has to be one of the first ten
(`theme` to `graphite`). A theme's `wallpaper` can carry a `mesh` the same way. See `wallpapers/petal`.

### Doodles

A pattern or mesh wallpaper (and a theme's `wallpaper`) can bring its own doodles instead of a built-in
pattern, in one of two ways:

- `glyphs`: 1 to 24 Lucide icon names (`["cloud", "star", "moon"]`) from `assets/lucide/icon-nodes.json`.
  The checker turns them into `doodles` in `index.json`.
- `doodles`: 1 to 24 drawings of your own. Each is a list of 1 to 24 elements in Lucide's node format,
  `[tag, attributes]`, on a 24 × 24 grid, drawn as strokes with round ends and no fill (Lucide's style; the app draws them a touch heavier, like its built-in patterns). Tags:
  `path` (`d`), `circle` (`cx`, `cy`, `r`), `ellipse` (`cx`, `cy`, `rx`, `ry`), `rect` (`x`, `y`,
  `width`, `height`, optional `rx`, `ry`), `line` (`x1`, `y1`, `x2`, `y2`), `polyline` and `polygon`
  (`points`). Numbers may be numbers or numeric strings; positions stay between -2 and 26, sizes between
  0 and 26. A `d` is at most 1,500 characters of path commands and numbers.

Not both. `pattern` stays required: it is what apps from before doodle support draw.

### Full color schemes

A color scheme (and a theme's inline `scheme`) can give its exact colors next to the seeds. Each of
`light` and `dark` may add `primary`, `primaryContainer`, `secondary`, `secondaryContainer`, `tertiary`
and `tertiaryContainer` (all six, or none) and optionally `appBar`. `primary`, `secondary` and `tertiary`
need 4.5:1 against `background`, and `onBackground` needs 4.5:1 on each container. Keep the seeds: apps
from before full schemes build the scheme from them.

### What an item needs

The checker adds `requires` to an item in `index.json` when it uses something newer apps added:
`mesh` (a mesh), `doodles` (glyphs or doodles) and `scheme-colors` (a full color scheme). Apps hide items
that need something they can't draw; older apps, which don't read `requires`, draw the fallbacks above.

`index.json` carries each look's document and each skill's description and icon, so the app and this site
draw previews from the list alone. `gallery.js` and `gallery.css` draw them on the web: the app's small
chat in a theme's colors, fonts and background, a scheme's colors as fields, and wallpapers. casama.ai's
item pages load the same two files. The pattern glyphs inside `gallery.js` are Lucide icons (ISC).

Check the tree and refresh `index.json`:

```sh
node scripts/casama-gallery-check.mts
```

## Make a look

`make.html` (gallery.casama.ai/make.html) builds a theme, color scheme or wallpaper without writing JSON:
seed or exact colors with live contrast checks, a built-in palette or your own mesh (drag the points on the
preview), built-in doodles or Lucide icons you pick. It previews the look with `gallery.js` in light and dark,
applies the rules above, and gives you `item.json` and the item's file to copy, download, or propose on
GitHub. Nothing is sent anywhere until you open the GitHub link yourself.
