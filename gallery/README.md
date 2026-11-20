# Casama gallery

The public catalog is [stackwares/casama-gallery](https://github.com/stackwares/casama-gallery).
A pull request there is how a theme, color scheme, wallpaper, skill, app, starter bot, routine idea or plugin reaches everyone's Casama.

Themes, color schemes, wallpapers, skills, apps, starter bots, routine ideas and plugins for Casama. A pull request is how someone contributes.
Casama reviews it, and a merge is what every app sees, without an app release.

`coding-agents.json` (the coding agents bots can run, D-370) is the exception: Casama writes it,
and pull requests from outside that change it are refused.

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
sets/<id>/item.json
sets/<id>/set.json
```

Skills, bots, routines, plugins and sets can also have a painted cover, `<id>/cover.webp` (optional): a
square WebP, 256 to 1024 px, at most 80 KB. It isn't part of the item's files or hash, so adding one never
shows as an update. The index record names it as `cover`.

`item.json` names the author and the license. Looks use CC0-1.0 or CC-BY-4.0. Skills use MIT or Apache-2.0.
Color schemes give a seed, a background and a text color for light and dark. Text on the background has to
pass WCAG AA. Fonts have to be ones the app already ships. Photos from Unsplash's API stay in photo search
and are not copied here.

An image wallpaper can add a `thumb` (a small copy, at most 200 KB) that cards load instead of the full
image. It can also add `dark` (at most 2 MB) and `darkThumb` (at most 200 KB): the same picture for dark
mode, such as a painting's night version. Apps draw `dark` when dark mode is on and `file` otherwise; apps
from before dark versions draw `file` in both. A theme that names the wallpaper with `image` gets both.
A skill's `item.json` can name a Lucide `icon` (`notebook-pen`) for its tile.

A mesh wallpaper (`"kind": "mesh"`) is a pattern wallpaper plus a `mesh`: nine light and nine dark
`#RRGGBB` colors, row by row from the top left, and optionally nine `[x, y]` points as fractions of the
window. Corners stay on corners, edge points on their edge, and inner points between 0.2 and 0.8. Light
colors need a luminance of at least 0.55 and dark ones at most 0.05, so text on top stays readable. Its
`palette` is the fallback that apps from before mesh support draw, so it has to be one of the first ten
(`theme` to `graphite`). A theme's `wallpaper` can carry a `mesh` the same way. See `wallpapers/petal`.

A theme's `wallpaper` can also name one of the gallery's image wallpapers: `"image": "lavender-hills"`.
It keeps its `pattern` and `palette` as the fallback. The catalog resolves the name into the wallpaper's
file, in a form apps from before this field can load too. See `themes/casama`.

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

Check the tree and refresh the derived files (`index.json`, `apps.json`, `bots.json`, `routines.json`,
`plugins.json`, `sets.json`, `authors.json` and `manifest.json`):

```sh
node check.mjs          # in this folder, no toolchain
node scripts/casama-gallery-check.mts   # from the Casama repo; same rules and output
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

The 27 starter bots built into Casama have copies here under the same ids (D-372). The gallery copy
wins: change `bots/<id>/bot.json` and every server offers the new version without a release. The
built-in copy only stands in when the gallery can't be read.

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

### Starter sets

A starter set bundles items people often add together (Founder kit, Student kit). `set.json`:

```json
{
  "description": "Decide, plan and report without a chief of staff.",
  "icon": "rocket",
  "items": [{ "type": "skill", "id": "decision-memo" }, { "type": "routine", "id": "weekly-review" }]
}
```

2 to 12 items of any kind but another set, each one in this gallery and not retired. License CC0-1.0 or
CC-BY-4.0. Sets are written to `sets.json`.

A set's `tags` are also its match words in onboarding: a set whose tags share words with what someone
says they want to do is suggested to them. Give a set at least three tags.

### Lists (D-372)

`lists/<id>.json` holds content the app and server read instead of their built-in copies. Each file is
written into `lists.json`, a file older apps never read. A list that can't be read, or a field left
out, falls back to the built-in copy. Gallery text shows in the app only in English.

- `search-words.json`: `{ "words": { "email": ["mail", "inbox"] } }`. Extra words a gallery search
  also matches; used by the app, bots' `gallery.search` and the MCP server. Up to 12 lower-case
  words per key.
- `welcome.json`: the welcome chat's focus choices, a `focus` list. Each has an `id`
  (`email_calendar`, `work_projects`, `coding`, `research`, `sales`, `errands`, `health`, `other`),
  a `label`, an `intro`, a `first_task` (`label`, `placeholder`, `prefix`), up to 4 `starters`
  (starter bot ids) and up to 4 `apps` (app ids). Focus ids are fixed for analytics; an unknown id
  is left out.
- `starters.json`: empty-screen starters. `library` (up to 9: `id`, `label`, `prompt`, a Lucide
  `icon`, a `hue`), `tasks` (up to 6) and `support` (up to 6), each `{ "id", "text" }`.
- `app-curation.json`: display fields only for built-in apps: `apps` (`id` with an optional `name`,
  `description`, `color`, `featured`), `order` (ids first, in this order) and `starter_apps` (up to
  8 ids shown in an empty chat). Sign-in, scopes and server addresses stay in code.

`node gallery/check.mjs` checks every list strictly (known ids, icon names, lengths).

## More in item.json (gallery v2, D-315)

Every item needs `added`; the rest is optional. The checker copies them into the item's record.

| Field | Shape | Notes |
| --- | --- | --- |
| `added` | `"YYYY-MM-DD"` | Required. The day the item joined the gallery. Drives the **New** row. |
| `updated` | `"YYYY-MM-DD"` | Defaults to the top changelog date, else `added`. Every record carries it. |
| `changelog` | `[{ "version", "date", "note", "breaking"? }]` | Newest first, versions going down, the top one equal to `version`. Required once `version` is above 1. `note` up to 160 characters. `breaking: true` makes apps ask before updating. |
| `pick` | string up to 140 | Why it's a pick. Only with `"featured": true`, and every featured item should have one. |
| `examples` | 1 to 3 strings up to 160 | Prompts people can try. Skills, apps and bots. |
| `access` | `{ "reads"?, "writes"?, "runs_code"?, "computer"?, "credits"? }` | What it can touch, in plain words: `"reads": ["email", "calendar"]`, `"writes": ["sends email"]` (up to 8 each, 40 characters). `credits`: `none`, `low`, `medium` or `high`. Skills, apps, routines, bots and plugins. A skill with scripts always gets `runs_code` and `computer`. |
| `needs` | `{ "apps"?, "skills"? }` | Apps (gallery ids or built-in ids such as `google_calendar`) and gallery skills a routine or bot needs. Installing it adds the skills and walks the person through the apps. |
| `inputs` | up to 6 questions | Asked when a routine or bot is added. See below. |
| `remix_of` | `{ "type", "id" }` | The gallery item this one is based on. Must exist. |
| `replaced_by` | `{ "type", "id" }` | For a retired item: what to use instead. Must exist. |
| `min_app`, `min_server` | `"x.y.z"` | Lowest app or server version that can use it; older ones hide it. |
| `season` | `{ "from": "MM-DD", "to": "MM-DD" }` | Shown in the **Seasonal** row between these days; may wrap the year end. |
| `author.handle` | `[a-z0-9-]`, up to 39 | Stable author id for author pages, like a GitHub login. Without it, items group by the author's name. |

### Install questions

A routine or bot can ask a few things when it's added and use the answers as `{{key}}` in a routine's
`instructions_md` or a bot's `persona` and `starters`:

```json
"inputs": [
  { "key": "time", "label": "What time should it arrive?", "type": "time", "default": "07:30" },
  { "key": "city", "label": "Your city, for the weather", "type": "text", "default": "my city" }
]
```

- `type`: `text`, `choice` (with 2 to 8 `options`), `time` (`HH:MM`) or `timezone` (`Europe/Berlin`).
- `default` is required and has to fit the type: it's what the form starts with and what servers from
  before inputs use.
- A `time` input named `time` can set the schedule: `"schedule_cron": "{{time.minute}} {{time.hour}} * * 1-5"`.
- Every placeholder needs an input and every input has to be used.

In the record, `document` has the defaults filled in (so older servers get a working routine) and
`template` holds the fields with their placeholders, which newer servers fill from the answers.

### Skill tests

A skill can add `tests.json`, 1 to 5 prompts with a plain-words rubric:

```json
{ "cases": [{ "prompt": "Proofread this: 'Their going tomorow.'", "expect": "Fixes they're and tomorrow, keeps the voice, lists what changed." }] }
```

`node scripts/gallery-skill-tests.mts` (in the Casama repo, needs `OPENROUTER_API_KEY`, costs a little)
runs each prompt with the skill loaded, has a model grade the answer, and writes `tested.json`. A skill that
passed on its current version gets `tested: { version, date }` in its record, shown as **Reviewed**.

### Authors and the signed manifest

`authors.json` lists each author (by `handle`, else a slug of the name) with their items. `manifest.json`
holds the sha256 of every derived file. On a merge, CI runs `node sign.mjs` with `GALLERY_SIGNING_KEY` to
write `manifest.sig`, an Ed25519 signature over `manifest.json`; servers check it with the gallery's public
key before trusting the files. `node sign.mjs --gen-key` prints a new key pair, and
`node sign.mjs --verify <public key>` checks a signature. Pull requests don't need the key.
