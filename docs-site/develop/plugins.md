# Plugins

A plugin gives a bot new skills and new tools in one install. Casama reads the open
[Agent Plugins 1.0](https://agent-plugins.org) format, so a plugin is a folder on GitHub with a
`plugin.json`, and optionally an `mcp.json` (tool servers) and a `skills/` folder. A plugin written
for another app that reads the format works in Casama too.

People install a plugin by pasting its GitHub link in a bot's settings, under **Plugins**. They
see what it adds before anything runs, and Casama installs exactly the commit they reviewed.

A plugin can also bring whole bots, routines, apps and looks to a workspace: that's a
[pack](./packs.md), the same folder with a `com.casama/` folder added.

The quickest start is the example,
[`examples/hello-plugin`](https://github.com/stackwares/casama/tree/main/examples/hello-plugin): a
stand-up skill plus a small notes server with one secret.

## What's in a plugin

```text
my-plugin/
├── plugin.json            required: name, version, description, secrets
├── mcp.json               optional: MCP tool servers
├── skills/
│   └── weekly-report/
│       ├── SKILL.md       one folder per skill
│       └── template.md    files the skill uses
├── server/
│   └── notes.mjs          code for a server that runs on the bot's computer
└── com.casama/
    └── cards/
        └── list_notes.json  optional: show a tool's result as a card
```

### plugin.json

```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "hello-casama",
  "version": "1.0.0",
  "description": "A stand-up skill and a notes server.",
  "author": { "name": "Ana Cruz", "url": "https://example.com" },
  "repository": "https://github.com/you/hello-casama",
  "license": "MIT",
  "keywords": ["notes"]
}
```

- `$schema` must be the 1.0.0 address above. Other versions are refused.
- `name`: lowercase letters, digits, dots and dashes, up to 64 characters, starting and ending with a
  letter or digit, with no `--` or `..`. It can't change between versions: an update with a new name is refused.
- `version`, `description`, `homepage`, `repository` and `license` are strings; `keywords` is a list
  of strings; `author` has only `name`, `email` and `url`.
- Other top-level fields are ignored, with a warning. Put app-specific settings under `extensions`.

### Skills

Each immediate folder of `skills/` that holds a `SKILL.md` is a skill, in the open
[Agent Skills](https://agentskills.io) layout:

```markdown
---
name: weekly-report
description: Turn the week's notes into a one-page report.
---

1. Read the notes with `list_notes` and `read_note`...
```

- `name`: lowercase letters, digits, `-` and `_`, up to 63 characters. Use the folder's name.
- `description` is required; Casama keeps the first 300 characters. The bot sees it when choosing a
  skill, so say when to use it.
- The skill's other files go with it to the bot's computer (`~/skills/<name>/`), keeping the
  executable bit. Up to 60 files, 1 MB each and 5 MB in all, with names made of letters, digits,
  `.`, `_`, `-` and `/`.
- A broken skill is skipped with a warning; the rest of the plugin still installs.

### MCP servers (mcp.json)

```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json",
  "mcpServers": {
    "notes": {
      "type": "stdio",
      "command": "node",
      "args": ["${PLUGIN_ROOT}/server/notes.mjs"],
      "env": { "NOTES_DIR": "${PLUGIN_DATA}/notes" }
    },
    "search": {
      "type": "streamable-http",
      "url": "https://mcp.example.com/mcp"
    }
  }
}
```

Two kinds of server:

| Kind | Where it runs | Fields |
| --- | --- | --- |
| `stdio` | Inside the bot's computer, started by Casama | `command`, `args`, `env`, `cwd` |
| `streamable-http` or `sse` | Your own server, called by Casama | `url`, `headers` |

Rules for `stdio` servers:

- `command` is one program (`node`, `python3`) or a path inside the plugin starting with `./`
  (`./bin/server`). No shell lines, no spaces.
- `${PLUGIN_ROOT}` (where the plugin's files are) and `${PLUGIN_DATA}` (a folder that survives
  updates) are filled in, in `args`, `env` values and `cwd` only. The server also gets them as the
  `PLUGIN_ROOT` and `PLUGIN_DATA` environment variables; `env` can't set those two itself.
- `cwd` stays inside the plugin or its data folder. Without one, the server starts in
  `PLUGIN_ROOT`.

Rules for remote servers:

- `url` uses https (plain http only for `localhost`, `127.x` and `::1`), with no user name, password or
  `#fragment`.
- Header names must be valid and not repeated.

A server with any other field, or one that breaks a rule, is skipped with a warning. A broken
`mcp.json` (not JSON, another `$schema`, no `mcpServers`, or another top-level field) turns off only
the plugin's servers; its skills still install.

## Secrets

The format has no way to declare secrets, and it forbids putting them in `env` or `headers`. Casama
adds one, under its own extension:

```json
{
  "extensions": {
    "com.casama": {
      "secrets": [
        {
          "name": "NOTES_SIGNATURE",
          "description": "A line added to every saved note.",
          "server": "notes",
          "env": "NOTES_SIGNATURE"
        },
        {
          "name": "SEARCH_API_KEY",
          "description": "Your key from example.com/settings/keys.",
          "server": "search",
          "header": "Authorization",
          "format": "Bearer {{value}}"
        }
      ]
    }
  }
}
```

- `name`: uppercase letters, digits and `_`, starting with a letter, up to 64 characters.
- `server`: the key of a server in `mcp.json`.
- For a `stdio` server, `env` names the environment variable the value goes in. For a remote server,
  `header` names the header, and `format` (optional, must contain `{{value}}`) shapes it.
- `description` is shown to the person installing (first 300 characters). Say where to get the
  value.
- A secret without a valid `name`, a known `server`, or the `env` or `header` its server needs is
  ignored with a warning.

The person installing is asked for every secret before install. Values are stored in Casama's vault,
never in the plugin's settings and never shown to the model, and they carry over to updates.

## Settings

Values that aren't secret, like a folder name or a region, are settings. They're declared next to
secrets, filled with a default, editable later on the plugin's page (or
`PATCH /v1/plugins/{id}/settings`), and stored in the connection's settings, not the vault:

```json
{
  "extensions": {
    "com.casama": {
      "settings": [
        {
          "name": "NOTES_FOLDER",
          "label": "Notes folder name",
          "description": "The folder notes are saved in.",
          "server": "notes",
          "env": "NOTES_FOLDER",
          "default": "notes"
        }
      ]
    }
  }
}
```

The rules match secrets': `env` for a `stdio` server, `header` (and an optional `format`) for a
remote one. Up to 20 settings; a setting can't share a secret's name, and values are one line of up
to 500 characters. Settings carry over to updates.

## The bot's computer

`stdio` servers run inside the bot's sandboxed Linux computer, never on Casama's servers. Write them
for this environment:

- **Ubuntu 24.04** with **Node.js 24**, **Python 3** (with `pip` and `venv`), bash, git, curl, jq and
  ripgrep, plus Chromium and Playwright. Anything else, ship inside the plugin.
- Runs as an unprivileged user (`casama`). The home folder is the only lasting, writable place,
  plus `/tmp`. Your files are at `~/.casama/plugins/<name>/` and your data at
  `~/.casama/plugin-data/<name>/`.
- **Nothing is installed for you.** Casama copies the plugin's files; it doesn't run `npm install`
  or `pip install`. Bundle your server into one file (for Node, `esbuild --bundle --platform=node`)
  or commit what it needs. `npx` works, but downloads the package on first start, and the server
  has **30 seconds** to answer `initialize`.
- **Network** goes through an egress proxy that blocks private and cloud-metadata addresses.
  A plugin's local servers can't reach private networks, by design.
- The computer sleeps after 5 idle minutes by default (people can choose 15, 30 or 60), and an idle
  server is stopped after 10 minutes; Casama starts it again on the next call. Keep state in `PLUGIN_DATA`, not in memory.
- Write logs to stderr. stdout is the MCP channel (one JSON-RPC message per line).
- Mark executable files executable in git (`git update-index --chmod=+x bin/server`), or start them
  with `node` or `python3`.

## On a person's own computer

When the person installing a plugin has the Casama desktop app paired with **Local tools (MCP)**
turned on, and that computer is online, they can choose to run the plugin's `stdio` servers there
instead of on the bot's computer (`device_id` on `POST /v1/plugins` or `POST /v1/packs`). Remote
servers aren't affected. Then:

- Casama copies the package to `~/.casama/plugins/<name>/` on that computer, with data in
  `~/.casama/plugin-data/<name>/`; `${PLUGIN_ROOT}`, `${PLUGIN_DATA}` and `./` paths resolve there.
  These folders are outside the folders the person shared with bots, so bots can't edit the code.
- Secrets and settings fill the environment as they do on the bot's computer. The commands run on
  the person's macOS, Windows or Linux with what's installed there, so say what your server needs.
- Only runs acting for that person can use the tools; in anyone else's chats they aren't offered,
  and the bot says why. When the computer is offline, calls say so.
- Only that person can update the plugin or change its settings; anyone who manages the bot can
  remove it, which also removes it from the computer.
- The plugin's page shows "Runs on" with the computer's name.

## Tools and approvals

Casama lists each server's tools at install (it starts the bot's computer to list `stdio` tools) and
again on every update. Each tool's risk comes from its MCP annotations:

| Annotation | Risk |
| --- | --- |
| `readOnlyHint: true` | low |
| `destructiveHint: true` | high |
| neither | medium |

The bot's autonomy setting decides which risks need someone's approval first (see
[Autonomy and approvals](/guide/autonomy)), and people can change any tool's risk, as with any
connection. Annotate honestly: a read-only tool that runs without asking makes a plugin pleasant
to use.

## Cards for your tools

A tool's result normally reaches the person through the bot, as text. A plugin can show it as a
card instead: one file per tool, `com.casama/cards/<tool>.json`, naming a card from the catalog
the apps already draw. There are no new widgets, no HTML and no web views: the card is drawn
natively, in the app's own look.

```json
{
  "format": 1,
  "card": "Details",
  "title": "#{{result.number}} {{result.title}}",
  "rows": [
    { "label": "State", "value": "{{result.state}}" },
    { "label": "Author", "value": "{{result.author}}" },
    { "each": "result.labels", "max": 5, "label": "Label", "value": "{{item.name}}" }
  ],
  "footer": "{{result.url}}",
  "when": "result.number"
}
```

- **`format`** is required and is `1`. A newer format is skipped, so an older Casama shows text.
- **`card`** is one component of the catalog, and the rest of the file is its fields:
  `Details`, `Checklist`, `Event`, `Agenda`, `Schedule`, `Results`, `MessageList`, `Stats`,
  `Map`, `PersonPicker`, `MessageDraft`, or the basic ones (`Text`, `Image`, `Video`, …). The
  fields are the ones a bot's `ui.show` tool takes (listed in
  [`packages/agent/src/tools/ui-catalog.ts`](https://github.com/stackwares/casama/blob/main/packages/agent/src/tools/ui-catalog.ts),
  the reference a bot reads with its `ui.catalog` tool). For a layout of several basic
  components, give `"components": [ … ]` instead (a flat list, one with `"id": "root"`).
- **Bindings.** `{{result.path}}` reads the tool's result: its MCP `structuredContent`, or else
  its text parsed as JSON. Paths are `result.a.b` or `result.items[0].name`. A string that is
  only one binding keeps the value's type (a number, a list, `true`), so `"labels":
  "{{result.days}}"` gives a chart its labels. A binding with no value leaves an optional field
  out; inside other text it becomes empty.
- **Lists.** In a card's list (`rows`, `items`, `events`, `messages`, `markers`, …), a row with
  `"each": "result.items"` repeats once per item, with `{{item.x}}` and `{{index}}` (from 0).
  `"max"` caps it (default 20, at most 60).
- **`when`** (optional) is a path. The card shows only when it has a value (not missing, empty,
  `false` or an empty list); otherwise the result stays text.
- **Buttons** are the ones the card already has, and like every button in a bot's card they send
  the person's answer as a message. A card never calls a tool, so approvals and rules still apply.

After the tool runs, Casama fills the card, checks the filled card the way it checks a bot's
`ui.show`, and shows it under the reply. The bot gets the plain result as before, plus a line
saying it was shown as a card, so it doesn't repeat it. If the card doesn't fill or doesn't pass
(a required field missing, a time that isn't ISO 8601, too many rows), the result stays text and
the reason goes to the server's log. Apps from before a card's component skip it, so have the
bot say a line in text too.

The checker refuses a card whose component isn't in the catalog, a binding it can't fill
(`{{env.HOME}}`, an unclosed `{{`, `{{item.x}}` outside an `each` row) or a field of the wrong
kind. A refused card is skipped with a warning (the plugin still installs), so
`plugin-check --strict` fails on it; plugin-check also lists which tools have cards. Return
`structuredContent` from your tools so cards don't depend on the text's wording.
[`packs/dev-kit`](https://github.com/stackwares/casama/tree/main/packs/dev-kit) shows a pull
request as a Details card and a list of them as Results.

## Check your plugin

`casama-plugin-check` runs the same checks Casama runs at install, and adds tips for things that
install fine but would fail on the bot's computer (a missing file, a program the image doesn't have,
a script that isn't executable, files you haven't committed).

On GitHub, add it to your plugin's workflow:

```yaml
# .github/workflows/check.yml
name: Check plugin
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: stackwares/casama/.github/actions/plugin-check@main
        with:
          path: . # the plugin folder
```

It fails when Casama would refuse the plugin, and (with the default `strict: true`) when it would
skip or ignore anything. Locally (Node 20+):

```sh
npx @casama/plugin-check ../my-plugin
```

Coding agents can run the same check through the `check_plugin` tool of the
[Casama MCP server](/guide/mcp#docs-tools-for-building-on-casama).

Add `--json` for the result as JSON, and `--strict` to also fail when Casama would skip or ignore
something, as the GitHub Action does by default.

## Publish and install

1. Push the plugin to a **public** GitHub repository. It can be the whole repository or one folder in
   it.
2. Share the link: `https://github.com/you/my-plugin`, or a folder or branch with
   `https://github.com/you/repo/tree/main/plugins/my-plugin`.
3. In Casama, open the bot's settings → **Plugins** → **Add a plugin**, and paste the link. Casama
   shows the skills, each server's command or address, the hosts it talks to, the secrets it needs
   and any warnings, then installs that exact commit.

**The plugin directory:** a bot's **Add a plugin** sheet also lists **Reviewed plugins** from the
[open gallery](https://gallery.casama.ai/#plugin). To list yours, open a pull request to
[stackwares/casama-gallery](https://github.com/stackwares/casama-gallery) with `plugins/<id>/plugin.json`
naming the repository folder and the exact commit to review. People who add it from the directory
get that commit; a newer version is another pull request that changes `commit`.

A bot can also suggest a plugin in chat. The card opens the same install sheet, so the person
still sees what it adds and enters its secrets.

**Updates:** push a new commit. People press **Check for update** on the plugin's page and see
what changed (skills and servers added, changed or removed, new hosts, new secrets) before updating.
Tag releases and keep `version` current so the change is easy to read.

**Uninstall** removes the plugin's skills, files, servers and secrets.

### Install with the API

The app's steps map to the [HTTP API](/develop/api), which is handy for testing a plugin from a
script. Preview first; the preview names the commit to install:

```sh
curl -s -X POST "https://casama.example.com/v1/plugins/preview" \
  -H "authorization: Bearer $TOKEN" -H "content-type: application/json" \
  -d '{"org_id": "'"$ORG"'", "url": "https://github.com/you/my-plugin"}'
```

The response lists `name`, `version`, `description`, `repo`, `path`, `commit`, `skills`,
`servers`, `secrets`, `hosts` and `warnings`. Install that commit for a bot, with a value for each secret:

```sh
curl -s -X POST "https://casama.example.com/v1/plugins" \
  -H "authorization: Bearer $TOKEN" -H "content-type: application/json" \
  -d '{"org_id": "'"$ORG"'", "bot_id": "'"$BOT"'", "url": "https://github.com/you/my-plugin",
       "commit": "<40-character commit from the preview>",
       "secrets": {"NOTES_SIGNATURE": "Ana"}}'
```

| Endpoint | What it does |
| --- | --- |
| `GET /v1/plugin-directory` | The reviewed plugins from the gallery, each with its pinned commit |
| `POST /v1/plugins/preview` | What a plugin at a GitHub URL would add, at the latest commit or the `commit` you pass |
| `POST /v1/plugins` | Install it for a bot, pinned to a commit |
| `GET /v1/plugins?bot_id=...` | A bot's plugins, with each server's status and tools |
| `GET /v1/plugins/{id}/update` | The latest commit and what would change |
| `POST /v1/plugins/{id}/update` | Update to a commit (`commit`, plus `secrets` for new ones) |
| `DELETE /v1/plugins/{id}` | Uninstall |

## Limits

- Up to 400 files and 10 MB per plugin. Symlinks are left out.
- Up to 100 cards, 64 KB each, 60 components in one card.
- Public GitHub repositories, or private ones when the workspace has a `GITHUB_TOKEN` secret
  allowed for `api.github.com`.
- Plugins are installed per bot, not for a whole workspace (a [pack](./packs.md) can set up several
  bots at once).
- `stdio` servers run on the bot's computer, or on the installer's own computer through the
  desktop app (see [On a person's own computer](#on-a-person-s-own-computer)). Two bots with the
  same plugin on one computer share its folder, so the last installed or updated version is the one there.

## Related

- [Packs](./packs.md): plugins that bring bots, routines, apps and looks
- [Skills](/guide/skills)
- [Hosted MCP](/guide/mcp)
- [Computers](/guide/computers): the environment `stdio` servers run in
- [Autonomy and approvals](/guide/autonomy)
- [Connections](/guide/connections)
