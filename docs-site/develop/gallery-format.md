# Gallery catalog format

The [gallery](https://gallery.casama.ai) is a folder of items that anyone can add to by pull request
to [stackwares/casama-gallery](https://github.com/stackwares/casama-gallery). A checker turns the
folders into a few JSON files that Casama servers, the app and the web gallery read. This page
describes the folders, every `item.json` field, skill tests, starter sets and the files the checker
writes. Any folder laid out the same way is a valid catalog, so you can run your own.

## Folders

Each item is a folder named by its id (lowercase letters, digits and dashes):

| Kind | Folder | Files next to `item.json` | Licenses |
| --- | --- | --- | --- |
| Theme | `themes/<id>/` | `theme.json` | CC0-1.0, CC-BY-4.0 |
| Color scheme | `schemes/<id>/` | `scheme.json` | CC0-1.0, CC-BY-4.0 |
| Wallpaper | `wallpapers/<id>/` | `wallpaper.json`, its image | CC0-1.0, CC-BY-4.0 |
| Skill | `skills/<id>/` | `SKILL.md`, any files it uses, optional `tests.json` | MIT, Apache-2.0 |
| App | `apps/<id>/` | `app.json`, optional `logo.svg` | CC0-1.0 |
| Starter bot | `bots/<id>/` | `bot.json` | MIT, Apache-2.0, CC0-1.0, CC-BY-4.0 |
| Routine idea | `routines/<id>/` | `routine.json` | MIT, Apache-2.0, CC0-1.0, CC-BY-4.0 |
| Plugin | `plugins/<id>/` | `plugin.json` | CC0-1.0 |
| Starter set | `sets/<id>/` | `set.json` | CC0-1.0, CC-BY-4.0 |

The documents for each kind (`theme.json`, `app.json`, `bot.json` and the rest) are described in the
catalog's [README](https://github.com/stackwares/casama-gallery#readme).

## item.json

```json
{
  "name": "Morning plan",
  "author": { "name": "Casama", "url": "https://casama.ai", "handle": "casama" },
  "license": "Apache-2.0",
  "tags": ["planning", "calendar"],
  "featured": true,
  "pick": "Five lines each morning: meetings, deadlines, weather, and where to start.",
  "version": 1,
  "added": "2026-11-13",
  "access": { "reads": ["calendar", "tickets", "memory", "the web"], "credits": "low" },
  "inputs": [
    { "key": "time", "label": "What time should it arrive?", "type": "time", "default": "07:30" },
    { "key": "city", "label": "Your city, for the weather", "type": "text", "default": "my city" }
  ]
}
```

| Field | Shape | Rule |
| --- | --- | --- |
| `name` | string | 1 to 60 characters. |
| `author` | `{ name, url?, handle? }` | `name` up to 80 characters, `url` https. `handle` (`[a-z0-9-]`, up to 39) groups the author's items on one author page; without it, items group by a slug of the name. |
| `license` | string | One of the kind's licenses above. |
| `tags` | string[] | Up to 8, each `[a-z0-9-]` up to 24 characters. |
| `category`, `icon` | string | A skill's catalog category (required for skills) and a Lucide icon name. |
| `featured` | boolean | Shown as a pick. |
| `pick` | string | Up to 140 characters: why it's a pick. Only with `featured: true`. |
| `retired` | boolean | Hidden from lists; people who added it keep it. |
| `replaced_by` | `{ type, id }` | For a retired item, what to use instead. Must exist. |
| `version` | integer | Starts at 1. Raise it when the item changes in a way people should update to. |
| `added` | `YYYY-MM-DD` | **Required.** The day it joined the gallery. |
| `updated` | `YYYY-MM-DD` | Optional. Defaults to the newest changelog date, else `added`. |
| `changelog` | `[{ version, date, note, breaking? }]` | Newest first, versions going down, the top one equal to `version`. Required once `version` is above 1. `note` up to 160 characters. `breaking: true` makes the app ask before updating. |
| `examples` | string[] | 1 to 3 prompts up to 160 characters people can try. Skills, apps and bots. |
| `access` | object | What the item can touch. Skills, apps, routines, bots and plugins. See below. |
| `needs` | `{ apps?, skills? }` | What a routine or bot needs first. See below. |
| `inputs` | question[] | Up to 6 questions asked when a routine or bot is added. See below. |
| `remix_of` | `{ type, id }` | The gallery item it's based on. Must exist. |
| `min_app`, `min_server` | `x.y.z` | Lowest app or server version that can use it. Older apps hide it; older servers leave it out. |
| `season` | `{ from: "MM-DD", to: "MM-DD" }` | Shown in the seasonal row between these days. May wrap the year end (`12-01` to `01-06`). |

### access

```json
"access": { "reads": ["email", "calendar"], "writes": ["sends email"], "runs_code": false, "computer": false, "credits": "low" }
```

- `reads` and `writes`: up to 8 plain phrases of at most 40 characters each, written for the person
  adding it ("files you share", "creates and edits Word files").
- `runs_code` and `computer`: whether it runs code and needs the bot's computer. A skill that brings
  scripts (`.py`, `.sh`, `.js` and similar files) always gets both, and saying `false` is an error.
- `credits`: `none`, `low`, `medium` or `high`, a rough guide to what a run costs.

When an update grows `access` (a new read or write, or code where there was none), the app shows the
difference and asks before updating.

### needs

```json
"needs": { "apps": ["google_calendar"], "skills": ["meeting-notes"] }
```

`apps` are gallery app ids or built-in app ids (`gmail`, `google_calendar`, `slack`, `github` and
the rest). `skills` are gallery skill ids. Installing the item installs the skills too, and walks the
person through connecting each app.

### inputs

Questions asked when a routine or bot is added. Each answer fills `{{key}}` in a routine's
`instructions_md` or a bot's `persona` and `starters`.

| Field | Rule |
| --- | --- |
| `key` | `^[a-z][a-z0-9_]{0,31}$`, unique. |
| `label` | 1 to 60 characters. |
| `type` | `text`, `choice`, `time` (`HH:MM`, 24-hour) or `timezone` (`Europe/Berlin`, `UTC`). |
| `options` | `choice` only: 2 to 8 options of at most 60 characters. |
| `default` | Required, 1 to 120 characters, fitting the type. The form starts with it, and servers from before inputs use it. |
| `help` | Optional, up to 120 characters. |

A `time` input named `time` can also set a routine's schedule:

```json
"schedule_cron": "{{time.minute}} {{time.hour}} * * 1-5"
```

Every placeholder needs an input, and every input has to be used. Answers can't contain `{` or `}`.

## Skill tests

A skill folder may hold `tests.json` with 1 to 5 cases:

```json
{
  "cases": [
    {
      "prompt": "Proofread this: 'Their going to the meeting tomorow.'",
      "expect": "Fixes they're and tomorrow, keeps the meaning and voice, and lists what changed."
    }
  ]
}
```

`prompt` is up to 500 characters and `expect`, a plain-words rubric, up to 300. The file is part of
the skill like any other. In the Casama repo, `node scripts/gallery-skill-tests.mts` runs each prompt
with the skill loaded and has a model check the answer against `expect` (it needs
`OPENROUTER_API_KEY`; `GALLERY_TEST_MODEL` and `GALLERY_JUDGE_MODEL` pick the models). It writes
`tested.json`:

```json
{ "proofread": { "version": 1, "passed": true, "date": "2026-11-16" } }
```

A skill that passed on its current version gets `tested: { version, date }` in its record, which the
app shows as **Reviewed**.

## Starter sets

`sets/<id>/set.json` bundles items people often add together:

```json
{
  "description": "Decide, plan and report without a chief of staff.",
  "icon": "rocket",
  "items": [
    { "type": "skill", "id": "decision-memo" },
    { "type": "routine", "id": "weekly-review" },
    { "type": "app", "id": "todoist" }
  ]
}
```

`description` up to 200 characters, `icon` a Lucide name, and 2 to 12 items of type `app`, `skill`,
`routine`, `bot`, `theme`, `scheme`, `wallpaper` or `plugin`. Each must be in the gallery and not
retired. A set's `tags` (in `item.json`) are also its match words in onboarding: a set whose tags
share words with what someone says they want to do is suggested. Give a set at least three tags.

## Lists

`lists/<id>.json` holds content Casama reads instead of its built-in copy (D-372). It isn't an item:
no folder or `item.json`, just a `name`, a `version`, an `updated` date and the list's fields. A
list that can't be read, or a field left out, falls back to the built-in copy, and gallery text
shows in the app only in English.

| File | Holds |
| --- | --- |
| `search-words.json` | `words`: extra words a gallery search also matches, `{ "email": ["mail", "inbox"] }`, up to 12 per key. Read by the app, bots' `gallery.search` and the MCP server. |
| `welcome.json` | `focus`: the welcome chat's choices by fixed id (`email_calendar`, `work_projects`, `coding`, `research`, `sales`, `errands`, `health`, `other`), each with `label`, `intro`, `first_task` (`label`, `placeholder`, `prefix`), up to 4 `starters` (bot ids) and 4 `apps`. |
| `starters.json` | Empty-screen starters: `library` (up to 9 of `id`, `label`, `prompt`, Lucide `icon`, `hue`), `tasks` and `support` (up to 6 of `id`, `text`). |
| `app-curation.json` | Display fields for built-in apps only: `apps` (`id`, optional `name`, `description`, `color`, `featured`), `order`, and `starter_apps` (up to 8 ids for an empty chat). Sign-in, scopes and server addresses stay in code. |

The checker writes them to `lists.json` as `{ type: "list", id, name, version, updated, document }`
records. Servers read `lists.json` from the main gallery only, never from an added catalog.

The 26 starter bots built into Casama also live in `bots/` under their own ids, and the gallery copy
wins over the built-in one.

## Packs

A pack is listed like any plugin: a `plugins/<id>/plugin.json` entry pinned to a reviewed commit.
When the folder at that commit has a `com.casama/pack.json`, the server shows it on the **Packs**
shelf with what's inside (worked out from the folder, cached by commit), and starter sets appear on
the same shelf. Installing a directory pack counts toward the plugin entry's usage and rewards. See
[Packs](/develop/packs) for the format.

## Files the checker writes

```sh
node check.mjs          # write the files
node check.mjs --check  # fail when an item is wrong or a file is out of date
```

| File | Holds |
| --- | --- |
| `index.json` | Themes, color schemes, wallpapers and skills. |
| `apps.json`, `bots.json`, `routines.json`, `plugins.json`, `sets.json` | The other kinds, one file each. |
| `lists.json` | The [lists](#lists). |
| `authors.json` | `{ schema: 1, authors: [{ handle, name, url?, items: [{ type, id }] }] }`. |
| `prompts.json` | The check-in and setup prompts: `{ schema: 1, items: [{ id, version, text }] }` (see [Prompts](#prompts)). |
| `prompts/versions.json` | Each prompt's version and the sha256 of its text; a changed text gets the next version. |
| `manifest.json` | `{ schema: 1, created, files: { "<file>": "<sha256 hex>" } }` over every file above. `created` is the newest `updated` date in the catalog. |
| `manifest.sig` | Written in CI by `node sign.mjs`, never committed. |

`index.json` only ever holds the four original types, because apps and servers from before the other
kinds can't read them; every new kind gets its own file. Every list file is
`{ "schema": 1, "items": [...] }`, and each record looks like this:

```json
{
  "id": "morning-plan",
  "type": "routine",
  "name": "Morning plan",
  "author": { "name": "Casama", "url": "https://casama.ai", "handle": "casama" },
  "license": "Apache-2.0",
  "tags": ["planning", "calendar"],
  "featured": true,
  "retired": false,
  "version": 1,
  "added": "2026-11-13",
  "updated": "2026-11-13",
  "sha256": "…",
  "size": 1343,
  "description": "Each weekday morning: today's meetings, deadlines and the one thing to get done first.",
  "pick": "Five lines each morning: meetings, deadlines, weather, and where to start.",
  "access": { "reads": ["calendar", "tickets", "memory", "the web"], "credits": "low" },
  "inputs": [{ "key": "time", "label": "What time should it arrive?", "type": "time", "default": "07:30" }],
  "document": { "instructions_md": "… today's weather in my city …", "schedule_cron": "30 7 * * 1-5" },
  "template": { "instructions_md": "… today's weather in {{city}} …", "schedule_cron": "{{time.minute}} {{time.hour}} * * 1-5" },
  "files": ["routines/morning-plan/item.json", "routines/morning-plan/routine.json"]
}
```

Fields appear only when the item has them: `category`, `icon`, `description`, `requires` (what a
look needs from the app), `changelog`, `pick`, `examples`, `access`, `needs`, `inputs`, `remix_of`,
`replaced_by`, `min_app`, `min_server`, `season` and `tested`. `document` is what a card or install
needs without another request; for a routine or bot with inputs it has the defaults filled in, and
`template` keeps the fields with their placeholders. `sha256` covers every file in the folder
(sorted path, length and bytes), and installs check it.

## Coding agents

`coding-agents.json` is the list of [coding agents](/guide/coding-agents) bots can use. Casama
writes it; pull requests from outside are refused, and the checker validates it but never rewrites
it. A server reads it only from the main gallery, only when the signed manifest covers it, and
otherwise uses its built-in list. An entry the server can't read, or one with `min_server` newer
than it, is skipped and the built-in entry with that id is kept.

```json
{
  "id": "kimi",
  "label": "Kimi Code",
  "bin": "kimi",
  "where": ["my_computer"],
  "command": { "my_computer": "kimi -p {task} --output-format stream-json" },
  "result": "stream_json"
}
```

- `command` has one template per place in `where` (`my_computer`, `bot_computer`). The only
  placeholders are `{task}`, `{folder}` and `{result_file}`, as whole words; the server quotes
  their values. Every command in a template starts with `bin`; quotes, `;`, `&&`, `||`, `|` and
  redirections like `2>&1` are allowed, while `$`, backticks and other placeholders are not.
- `result`: `json_result`, `marker` (with `{result_file}`), `json_field:<name>`, `stream_json` or
  `tail`.
- Optional: `browser` (`claude` or `codex`, the browser tools' flags), `commits_for_agent`,
  `needs_folder`, `install`, `key_name`, `hint`, `exit_messages`, `min_server`.
- Agents other than Claude Code, Codex, Cursor, Pi and T3 Code need one Allow on each computer.

## Prompts

`prompts/<id>.md` holds the text bots follow for check-ins and the setup interview (D-374). A
server reads `prompts.json` from its main catalog every 15 minutes, never from an extra source, and
uses the built-in copy for any prompt that's missing or fails its check, so a reviewed pull request
changes what every bot does without a deploy.

| Id | Used for |
| --- | --- |
| `checkin.brief` | The morning brief. |
| `checkin.scan` | Check-in scans. |
| `checkin.setup_scan` | Added to the first scan after setup. |
| `checkin.reason.connection`, `checkin.reason.event` | Added to a scan an app connection or an app change started. |
| `setup.guide` | The setup interview. |

The parts code checks for aren't in these files and can't be: the brief's opening line ("Write my
morning brief for today."), the scan's ("Check-in scan."), the "Quiet day" and `NOTHING_NEW`
replies and the setup summary's "You're all set.". The server adds them around the text, and the
checker refuses a file that contains them. Texts are 20 to 8000 characters.

`node check.mjs` gives a changed prompt its next version; `--check` fails when `prompts.json` or
`versions.json` is out of date. A pull request that changes a prompt runs the prompt evals against
a live model (`packages/evals/src/prompts.ts`, the `prompts` job in `.github/workflows/evals.yml`):
a quiet brief still starts "Quiet day", an empty scan still replies `NOTHING_NEW`, and the setup
interview still opens with a card. They run nightly too. By hand:

```sh
OPENROUTER_API_KEY=... node packages/evals/src/run.ts --mode live --subset prompts --min-rate 0.75
```

## Signing

A Casama server checks `manifest.sig`, a base64 Ed25519 signature over the exact bytes of
`manifest.json`, with the catalog's public key, then checks each JSON file it reads against the
hashes in the manifest. To sign your own catalog:

```sh
node sign.mjs --gen-key                          # prints a private key (PEM) and a public key
GALLERY_SIGNING_KEY="$(cat key.pem)" node sign.mjs  # writes manifest.sig
node sign.mjs --verify <base64 public key>        # checks it
```

`GALLERY_SIGNING_KEY` is a PKCS8 PEM or a base64 raw 32-byte seed; the public key is the base64 raw
32 bytes. Keep the private key in your CI's secrets, never in the repository.

## Related

- [Bot template format](/develop/bot-templates)
- [Plugins](/develop/plugins)
- [Build with AI agents](/develop/agents): the `casama-gallery` skill adds items for you
