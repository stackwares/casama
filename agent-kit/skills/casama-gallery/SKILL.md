---
name: casama-gallery
description: "Contribute to the Casama gallery (stackwares/casama-gallery): apps (hosted MCP servers), catalog skills, starter bots, routine ideas, reviewed plugins and looks. Use when asked to add or update a gallery item, write item.json/app.json/bot.json/routine.json, or fix gallery check errors."
---

# Contribute to the Casama gallery

The gallery is the open catalog every Casama reads without an app release. A merged pull request
to **https://github.com/stackwares/casama-gallery** is how an item reaches everyone (apps show up
in Connections within about 15 minutes). Browse: https://gallery.casama.ai. Build a look without
JSON: https://gallery.casama.ai/make.html.

Source of truth for the rules: the gallery repo's `README.md` and `check.mjs` (mirrored in the
Casama repo at `gallery/`).

Before adding an item, search for one that already does the job (`gallery_search` in
`npx -y @casama/mcp`, or `casama gallery search "<words>"`): improve or remix it instead of adding
a near copy.

## Layout: one folder per item

```text
apps/<id>/item.json + app.json (+ logo.svg)
skills/<id>/item.json + SKILL.md (+ files)
bots/<id>/item.json + bot.json
routines/<id>/item.json + routine.json
plugins/<id>/item.json + plugin.json
themes/<id>/item.json + theme.json
schemes/<id>/item.json + scheme.json
wallpapers/<id>/item.json + wallpaper.json
```

- `<id>`: `^[a-z0-9][a-z0-9-]{0,62}$`.
- Bots, routines and plugins may hold **only** `item.json` and their document; apps only
  `item.json`, `app.json`, `logo.svg`.

## item.json (every type)

```json
{
  "name": "Canva",
  "author": { "name": "Your Name", "url": "https://example.com" },
  "license": "CC0-1.0",
  "tags": ["design", "presentations"],
  "featured": false,
  "version": 1
}
```

- `name` 1-60 chars; `author.name` required (max 80); `author.url` optional, must be `https://`.
- `tags`: max 8, each `^[a-z0-9][a-z0-9-]{0,23}$`. `icon` (optional): a Lucide name.
- Licenses: apps and plugins `CC0-1.0`; skills `MIT` or `Apache-2.0`; bots and routines `MIT`,
  `Apache-2.0`, `CC0-1.0` or `CC-BY-4.0`; themes, schemes, wallpapers `CC0-1.0` or `CC-BY-4.0`.
- Skills also need `category`.
- `"retired": true` hides an item (people who connected an app keep it).

## Apps: a vendor's own hosted MCP server

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

- Allowed keys only: `description` (1-140), `category`, `color`, `homepage`, `url`, `auth`,
  `oauthClient`, `scopes`, `apiKey`, `note`, `capabilities`.
- **`category` is a strict enum**: `developer`, `productivity`, `payments`, `design`, `sales`,
  `data`, `automation`. Never invent one: apps already shipped parse the catalog strictly and
  break on an unknown value. Pick the closest (travel apps go under `productivity`).
- `color`: 6 hex digits, no `#`. `url`, `homepage`: `https`, public host name, no IP, port,
  credentials or internal TLD (`.local`, `.internal`, `.test`, `.example`, ...).
- `auth`: one or more of `oauth`, `api_key`, or `none` alone.
  - `oauth` needs `oauthClient`: `dcr` (metadata has `registration_endpoint`) or `cimd`.
    Optional `scopes` (max 30) only to trim what the server announces.
  - `api_key` needs `apiKey`: `label` (1-40), `url` (where to create a key), `steps` (1-6 lines,
    max 160 each), optional `placeholder` (max 60) and `header` (default `Authorization: Bearer`;
    not a reserved header such as `host` or `content-type`).
- `note` optional (max 200); `capabilities` 1-6 phrases, max 60 chars each.
- `logo.svg` optional: one `<svg>` with a `viewBox` (24 x 24), single color (the app tints it),
  max 24 KB, no scripts, styles, `<use>`, images, links, `href`, `url()` or entities.
- Not for community or self-hosted servers (users add those via Settings → Connections → Custom
  server) and not for Google's apps, Composio or built-ins, which live in Casama's code.

## Skills (the catalog in Settings → Skills → Skill catalog)

- `SKILL.md` front matter `name` must equal the folder id; `description` says when to use it.
- `item.json` `category`: `work`, `writing`, `research`, `data`, `money`, `build` or `life`.
- Optional `icon` (Lucide, e.g. `notebook-pen`) for the tile. License MIT or Apache-2.0.
- Same SKILL.md rules as any Casama skill (load `casama-plugin` for the format details).

## Starter bots (`bot.json`)

Allowed keys: `description` (1-300), `category` (`work`, `research`, `build`, `create`, `life`),
`icon` (Lucide), `mascot` (`cool`, `focused`, `giggly`, `lovey`, `shy`, `sleepy`, `starry`,
`thinker`, `winky`, `wow`), `persona` (20-20,000), `starters` (1-6, max 160 each), `autonomy`
(`ask_always` or `ask_risky` only; gallery bots never start autonomous), optional `skills` (max 10;
`name`, `description` 1-300, `body_md` 1-50,000; names unique) and `routines` (max 5; `name` 1-120,
`instructions_md` 1-20,000, `schedule_cron` 5 fields).

## Routine ideas (`routine.json`)

```json
{ "description": "Every Friday afternoon: what got done, what slipped, and next week's priorities.",
  "category": "work", "icon": "calendar-check",
  "instructions_md": "Write my weekly review. ...", "schedule_cron": "0 16 * * 5" }
```

`description` 1-200, `category` as for bots, `icon` required, `instructions_md` 10-20,000, 5-field
cron.

## Reviewed plugins (`plugin.json`)

```json
{ "description": "A small example plugin: a stand-up skill and a notes server.",
  "url": "https://github.com/stackwares/casama/tree/main/examples/hello-plugin",
  "commit": "6efc18250f69b9c2938b689076384237324136e3",
  "icon": "puzzle",
  "adds": ["A stand-up skill", "A notes server on the bot's computer"] }
```

`url`: a `github.com` repo or `/tree/<ref>/<folder>` link. `commit`: the full 40-hex commit that
was reviewed; that commit is what installs. A new version is a PR changing `commit`. `adds`: 1-6
phrases, max 80. Run plugin-check `--strict` on that commit first (see `casama-plugin`).

## Looks (themes, schemes, wallpapers)

Use make.html; it applies the rules and emits `item.json` plus the document. Key rules: scheme
text on background passes WCAG AA (4.5:1); `theme.json` has `v: 2`; fonts must be ones the app
ships; image wallpapers are webp/jpeg in the folder (max 2 MB, optional `thumb` max 200 KB,
optional `dark` + `darkThumb` for dark mode);
Unsplash photos are never copied in. Details (mesh, doodles, full color schemes) are in the
gallery README.

## Check before the PR

In the gallery repo root:

```sh
node check.mjs           # validate every item and rewrite index.json / apps.json / bots.json / routines.json / plugins.json
node check.mjs --check   # CI mode: fail if an item is wrong or an index file is stale
```

Commit the regenerated index files with your item. (In the Casama repo the same check runs as
`node scripts/casama-gallery-check.mts`.)

## Checklist

- [ ] Folder id valid; only allowed files in the folder
- [ ] `item.json`: name, author.name, the right license for the type, at most 8 valid tags
- [ ] App `category` is one of the seven; URLs are public https; auth fields consistent
- [ ] Skill name = folder id; category one of the seven catalog categories
- [ ] Bot autonomy is `ask_always` or `ask_risky`; cron strings 5 fields
- [ ] Plugin `commit` is the full reviewed SHA and passes plugin-check
- [ ] `node check.mjs` run and index files committed
