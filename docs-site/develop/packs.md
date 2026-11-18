# Packs

A pack is a [plugin](./plugins.md) that brings more than a bot's skills and tools: whole bots,
routines, apps to connect, workspace skills and looks, set up in one install. It is still one
Agent Plugins 1.0 folder on GitHub. The extra parts live in a `com.casama/` folder that other apps
reading the format ignore, so a pack keeps working as a plain plugin elsewhere.

People find packs on the **Packs** shelf in the gallery, or paste a GitHub link under
**Gallery > Add a pack from a link**. Before anything is installed they see every bot, skill,
routine, app and look, can untick what they don't want, answer the pack's questions and see what
it can reach. Casama installs exactly the commit they previewed.

Start from the example,
[`examples/hello-pack`](https://github.com/stackwares/casama/tree/main/examples/hello-pack), or
scaffold one:

```sh
casama init pack my-kit
npx @casama/plugin-check my-kit --strict
```

## The folder

```text
my-kit/
├── plugin.json                  the plugin's manifest (name, version, secrets, settings)
├── mcp.json                     optional: tool servers
├── skills/<name>/SKILL.md       skills: a bot's, or the whole workspace's
└── com.casama/
    ├── pack.json                required: what makes it a pack
    ├── cards/<tool>.json        optional: a tool's result as a card (see Plugins)
    ├── bots/<id>.json           up to 5 bots
    ├── routines/<id>.json       up to 20 routines
    ├── apps/<id>/app.json       up to 12 apps (and an optional logo.svg)
    └── looks/
        ├── themes/<id>.json     up to 12 looks in all
        ├── schemes/<id>.json
        └── wallpapers/<id>.json
```

### pack.json

```json
{
  "format": "casama.pack",
  "version": 1,
  "title": "Stand-up kit",
  "icon": "megaphone",
  "summary": "A stand-up bot that writes and saves your daily stand-up, and a Monday recap.",
  "inputs": [
    { "key": "team", "label": "Your team's name", "type": "text", "default": "the team" },
    { "key": "time", "label": "When should the recap arrive?", "type": "time", "default": "09:00" }
  ],
  "needs": { "apps": ["notion"] },
  "includes": [{ "type": "skill", "id": "weekly-report" }],
  "workspace_skills": ["house-style"],
  "examples": ["Write my stand-up for today"]
}
```

| Field | What it does |
|---|---|
| `format`, `version` | Always `"casama.pack"` and `1`. A newer version is refused by older servers, not misread |
| `title` | The name people see, up to 64 characters. Without it, the plugin's `name` made readable (`stand-up-kit` → "Stand up kit"). The plugin's `name` stays the pack's identity for updates |
| `icon` | A Lucide icon name for the shelf |
| `summary` | One line, up to 160 characters |
| `inputs` | Up to 6 questions asked at install, in the gallery's format (`text`, `number`, `time`, `choice`...). `{{key}}` in personas, starters, routine instructions and schedules is filled with the answer; a `time` answer also gives `{{key.hour}}` and `{{key.minute}}` |
| `needs.apps` | Built-in or gallery apps the pack works best with; people are asked to connect them after installing |
| `includes` | Up to 12 gallery items installed along with it (`skill`, `app`, `routine`, `bot`, `theme`, `scheme`, `wallpaper`, `plugin`), or another plugin by `url` and `commit` |
| `workspace_skills` | Skills from `skills/` that go to the whole workspace instead of a bot. A skill no bot names goes to the workspace too |
| `examples` | Up to 3 things to ask, shown on the shelf |

A placeholder with no matching question refuses the pack; a question nothing uses is a warning. Card files (`com.casama/cards/`) aren't filled at install: their `{{result…}}` bindings are
filled from a tool's result each time it runs ([Cards for your tools](./plugins.md#cards-for-your-tools)).

### Bots

`com.casama/bots/<id>.json` is the gallery's bot format plus what the bot gets from the pack:

```json
{
  "name": "Stand-up",
  "description": "Writes your daily stand-up and recaps the week on Monday.",
  "category": "work",
  "icon": "megaphone",
  "mascot": "focused",
  "persona": "You help {{team}} with their daily stand-up...",
  "starters": ["Write my stand-up for today"],
  "autonomy": "ask_risky",
  "skills": ["team-standup"],
  "routines": ["monday-recap"],
  "tools": ["notes"],
  "rules": [{ "match_kind": "category", "match_value": "send", "rule": "ask" }],
  "knowledge": [{ "kind": "website", "name": "Handbook", "url": "https://handbook.example.com", "max_pages": 30 }]
}
```

- `skills` name folders under `skills/`, `routines` name files under `com.casama/routines/`, and
  `tools` name servers in `mcp.json`. The bots that name tools get the plugin's servers; when no
  bot names any, every bot of the pack gets them.
- `autonomy` is `ask_always` or `ask_risky`. A pack's bot never starts fully autonomous: `autonomous`
  is lowered to `ask_risky` with a warning.
- `rules` only narrow what the bot may do: `ask` (ask first) or `hand_off` (a person does it),
  matched by `tool`, `group` or `category` (`send`, `pay`, `delete`, `publish`, `share`,
  `sign_in`). Rules that allow are skipped. Up to 20.
- `knowledge` is up to 5 sources the bot reads: `website` (an `https` address, `max_pages` up to
  200, 20 by default) or `github` (a `github.com` repository). They sync daily, which costs a
  little, so the preview counts the pages.

### Routines

```json
{
  "name": "Monday recap",
  "description": "Every Monday: last week's stand-ups in five lines.",
  "category": "work",
  "icon": "calendar-check",
  "instructions_md": "Read last week's stand-ups and write a recap for {{team}}...",
  "schedule_cron": "{{time.minute}} {{time.hour}} * * 1"
}
```

A routine runs on the bot that lists it, else the bot the person picks, else the pack's first
bot. Routines from a pack Casama hasn't reviewed start switched off.

### Apps and looks

`com.casama/apps/<id>/app.json` is the gallery's app format plus a `name`. A pack's app joins that
workspace's app list as `<pack>.<id>`. An app can't use the name of a built-in or gallery app
that talks to a different host.

Looks are the gallery's theme, scheme and wallpaper files plus a `name`. They are offered on the
device after installing; they never change anyone's look by themselves.

## What it can reach

The preview and `plugin-check` work out, from the files rather than the author's word:

- whether it runs code, and on how many bots' computers;
- every host its servers, apps and knowledge talk to;
- the secrets and settings it asks for;
- how many scheduled runs a week its routines make, with the default answers;
- how many knowledge sources and pages its bots read.

An update that reaches further (new hosts, secrets or servers) asks again before it installs.

## Installing, updating, removing

- **Installing** makes ordinary bots, skills, routines and connections. Bots go through the same
  limits and model policy as a bot you make yourself. Workspace skills need an admin; for anyone
  else they're skipped with a note. The workspace's gallery rules (**Settings > Gallery**) apply:
  a directory pack by its plugin entry (`plugin/<id>`), a link by its repository
  (`repo/<owner>:<repo>`), a file or share link by its name (`pack/<name>`). When an admin's approval is
  needed, the whole request waits for them.
- **Updating** shows a diff of every bot, skill, routine, app, look and server. What you edited
  stays yours unless you choose the pack's version; what the newer version dropped is left with
  you.
- **Removing** takes the pack's tools and the items you didn't change. Bots stay unless you ask
  for them to go, and so does anything you edited.

## Share as pack

Anyone can turn bots into a pack: **Share as pack** in the app, `casama packs export`, or
`POST /v1/orgs/{id}/packs/export`. It writes the bots' personas, skills (with their files),
scheduled routines, the apps they use (by name, never their sign-ins), their plugins (by link and
commit) and, optionally, this device's look. Memories, chats, files and secrets never go in.
Before sharing, every file is scanned for things that look like keys and for the workspace's own
secret values.

A share link (`POST /v1/orgs/{id}/packs/share`) works for 30 days for anyone signed in, and can be
ended early or reported.

## Check it

```sh
npx @casama/plugin-check my-kit --strict
```

It prints the pack's bots, skills, routines, apps, looks, rules, questions and reach, and fails on
anything Casama would refuse. The GitHub workflow from `casama init` runs the same check on every
push.

## API

| | |
|---|---|
| `POST /v1/packs/preview` | What a pack brings: give `url` (and `commit`), `gallery_id`, `share_token` or `files` |
| `POST /v1/packs` | Install: the same source plus `skip`, `inputs`, `secrets`, `settings`, `bot_id`, `routines_on`. 201 installed, 202 waiting for an admin |
| `GET /v1/packs?org_id=` | Installed packs, with each item and whether you edited it |
| `GET`/`POST /v1/packs/{id}/update` | The newer version as a diff; apply it with `commit`, `take_theirs`, `confirm_reach` |
| `DELETE /v1/packs/{id}?bots=keep\|delete` | Remove |
| `POST /v1/orgs/{id}/packs/export`, `.../share` | Share as pack |
| `GET`/`DELETE /v1/pack-shares/{token}` | A share link's preview; end it |
| `GET /v1/gallery/packs` | The Packs shelf |

Also: `casama packs preview|install|list|update|remove|export` in the [CLI](./cli.md),
`client.packs` in the [TypeScript client](./typescript.md), `client.packs` in the
[Dart SDK](./sdk.md), and `list_packs`, `preview_pack` and `install_pack` over MCP.

## Limits

5 bots, 30 skills, 20 routines, 12 apps, 12 looks, 12 includes, 6 questions, 20 rules and 5
knowledge sources per bot; the plugin limits (400 files, 10 MB) apply to the whole folder.
