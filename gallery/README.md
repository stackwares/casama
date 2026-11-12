# Casama gallery

The public catalog is [stackwares/casama-gallery](https://github.com/stackwares/casama-gallery).
A pull request there is how a theme, color scheme, wallpaper, skill, app, starter bot, routine idea or plugin reaches everyone's Casama.

Themes, color schemes, wallpapers, skills, apps, starter bots, routine ideas and plugins for Casama. A pull request is how someone contributes.
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
apps/<id>/item.json
apps/<id>/app.json
apps/<id>/logo.svg   (optional)
bots/<id>/item.json
bots/<id>/bot.json
routines/<id>/item.json
routines/<id>/routine.json
plugins/<id>/item.json
plugins/<id>/plugin.json
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

### Apps

An app is a vendor's own hosted MCP server, such as `https://mcp.canva.com/mcp`. Once merged it shows
in every Casama's Connections next to the built-in apps, within about 15 minutes, with no app or server
release. Removing it (or setting `"retired": true`) hides it from the list; people who already connected
it keep their connection.

`item.json` is like any item's, with the license `CC0-1.0`. `app.json` says how to connect:

```json
{
  "description": "Find, create and edit your Canva designs.",
  "category": "design",
  "color": "00C4CC",
  "homepage": "https://www.canva.com",
  "url": "https://mcp.canva.com/mcp",
  "auth": ["oauth"],
  "oauthClient": "dcr",
  "capabilities": ["Search your designs", "Create designs from a prompt"]
}
```

- `category`: `developer`, `productivity`, `payments`, `design`, `sales`, `data` or `automation`.
- `color`: the brand color, hex without `#`. The app draws the logo on it.
- `url` and `homepage`: https on a public host name (no IP addresses, ports or internal names).
- `auth`: any of `oauth`, `api_key`, or `none` on its own.
  - `oauth` needs `oauthClient`: `dcr` when the server registers clients itself (its authorization server
    metadata has a `registration_endpoint`), `cimd` when it accepts a client metadata document. Optional
    `scopes` replace what the server announces; leave them out unless it announces far more than it needs.
  - `api_key` needs `apiKey`: `label`, `url` (where to create a key), 1 to 6 `steps`, and optionally a
    `placeholder` and a `header` (default `Authorization: Bearer`).
- `note` (optional, up to 200 characters): a caveat for the connect sheet, such as "Read-only".
- `capabilities`: 1 to 6 short phrases of what a bot can do with it.
- `logo.svg` (optional): the vendor's single-color mark on a 24 × 24 `viewBox`, such as Simple Icons' copy.
  The app tints it, so its colors don't matter. No scripts, styles, links or images, at most 24 KB. The
  mark stays the vendor's trademark.

Built-in apps (Google's, GitHub, Slack and the rest) live in Casama's code and keep their ids. Things only
they can do stay there: Google's apps, sign-ins with a client the server owner registers, and Composio.
Community and self-hosted servers don't go here: Settings → Connections → Custom server adds any MCP URL.

Apps are written to `apps.json`, not `index.json`, so servers and apps from before apps never see them.

### Skills are the catalog

Casama's skill catalog (Settings → Skills → Skill catalog) shows the skills here. A merged change reaches
every server without a release; the copy bundled with Casama only stands in when the gallery can't be
read. A skill's `category` has to be one of the catalog's: `work`, `writing`, `research`, `data`, `money`,
`build` or `life`.

### Starter bots

A starter bot is offered when someone makes a new bot. `bot.json`:

```json
{
  "description": "Quizzes you, explains what you got wrong and plans revision before an exam.",
  "category": "life",
  "icon": "graduation-cap",
  "mascot": "thinker",
  "persona": "You are a patient study partner. ...",
  "starters": ["Quiz me on photosynthesis"],
  "autonomy": "ask_always",
  "skills": [{ "name": "flashcards", "description": "...", "body_md": "..." }],
  "routines": [{ "name": "Sunday week ahead", "instructions_md": "...", "schedule_cron": "0 18 * * 0" }]
}
```

- `category`: `work`, `research`, `build`, `create` or `life`. `icon`: a Lucide name.
- `mascot`: `cool`, `focused`, `giggly`, `lovey`, `shy`, `sleepy`, `starry`, `thinker`, `winky` or `wow`.
- `persona`: the bot's standing instructions, 20 to 20,000 characters. `starters`: 1 to 6 first messages.
- `autonomy`: `ask_always` or `ask_risky`. A gallery bot never starts fully on its own.
- `skills` (up to 10) and `routines` (up to 5, five-field cron) are optional.
- License: MIT, Apache-2.0, CC0-1.0 or CC-BY-4.0. Built-in starter bots keep their ids.

### Routine ideas

A routine idea fills in a new routine (a bot's Routines → New routine → Ideas). `routine.json`:

```json
{
  "description": "Every Friday afternoon: what got done, what slipped, and next week's priorities.",
  "category": "work",
  "icon": "calendar-check",
  "instructions_md": "Write my weekly review. ...",
  "schedule_cron": "0 16 * * 5"
}
```

### Plugins

A plugin entry points at an Agent Plugins 1.0 package on GitHub and the exact commit that was reviewed.
People add it from a bot's Plugins page, and that commit is what gets installed, never a later one.
`plugin.json`:

```json
{
  "description": "A small example plugin: a stand-up skill and a notes server.",
  "url": "https://github.com/stackwares/casama/tree/main/examples/hello-plugin",
  "commit": "6efc18250f69b9c2938b689076384237324136e3",
  "icon": "puzzle",
  "adds": ["A stand-up skill", "A notes server on the bot's computer"]
}
```

A newer version is a pull request that changes `commit`, reviewed like the first. The entry is CC0-1.0;
the plugin keeps its own license.

Bots, routine ideas and plugins are written to `bots.json`, `routines.json` and `plugins.json`.
