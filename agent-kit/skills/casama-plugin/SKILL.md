---
name: casama-plugin
description: "Write, check and publish a Casama plugin (Agent Plugins 1.0: plugin.json, mcp.json, skills/). Use when asked to make a plugin, add MCP tools or skills to a Casama bot, declare plugin secrets (com.casama), fix casama-plugin-check errors, or list a plugin in the gallery."
---

# Build a Casama plugin

A plugin is a folder on a **public** GitHub repo (the whole repo or one folder) in the open
[Agent Plugins 1.0](https://agent-plugins.org) format. It gives a bot skills and MCP tools in one
install. People paste its link in a bot's settings under **Plugins**, review what it adds, and
Casama installs that exact commit.

Full page: https://docs.casama.ai/develop/plugins.md. Working example to copy:
https://github.com/stackwares/casama/tree/main/examples/hello-plugin

## Check the gallery first

Before writing a new plugin (or a skill or app it would wrap), look for one that already exists at https://gallery.casama.ai: the
`gallery_search` tool of `npx -y @casama/mcp`, `casama gallery search "<words>"`, or the public
JSON files (`index.json`, `apps.json`, `bots.json`, `routines.json`, `plugins.json`, `sets.json`).
If one fits, point the person to its page (`https://gallery.casama.ai/i/<type>/<id>/`) or start
from it with `casama init --from-gallery plugin/<id>`. Build a new one only when nothing fits, and
consider submitting it to the gallery afterwards.

## Layout

```text
my-plugin/
├── plugin.json        required
├── mcp.json           optional: MCP servers
├── skills/<name>/SKILL.md   optional: one folder per skill, plus its files
└── server/notes.mjs   code for a stdio server (runs on the bot's computer)
```

## plugin.json

```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "hello-casama",
  "version": "1.0.0",
  "description": "A stand-up skill and a notes server.",
  "author": { "name": "Ana Cruz", "url": "https://example.com" },
  "repository": "https://github.com/you/hello-casama",
  "license": "MIT",
  "keywords": ["notes"],
  "extensions": { "com.casama": { "secrets": [] } }
}
```

- `$schema` must be exactly the 1.0.0 URL above; anything else is **refused**.
- `name`: `^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$`, max 64, no `--` or `..`. It **can't change** later:
  an update with a new name is refused.
- `version`, `description`, `homepage`, `repository`, `license`: strings. `keywords`: strings.
  `author`: only `name`, `email`, `url` (anything else is refused).
- Other top-level fields are ignored with a warning. App-specific settings go under `extensions`.

## Secrets (`extensions["com.casama"].secrets`)

The format forbids secrets in `env`/`headers`, so Casama adds them here:

```json
{ "name": "SEARCH_API_KEY", "description": "Your key from example.com/settings/keys.",
  "server": "search", "header": "Authorization", "format": "Bearer {{value}}" }
```

- `name`: `^[A-Z][A-Z0-9_]{0,63}$`. `server`: a key in `mcp.json`.
- stdio server: `env` names the variable. Remote server: `header` names the header; optional
  `format` must contain `{{value}}`.
- `description` (first 300 chars) is shown at install: say where to get the value.
- Missing name, unknown server, or missing `env`/`header` = ignored with a warning.
- Values are asked for before install, kept in the vault, never shown to the model, and carry
  over to updates.

## mcp.json

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
    "search": { "type": "streamable-http", "url": "https://mcp.example.com/mcp" }
  }
}
```

| `type` | Runs | Allowed fields |
| --- | --- | --- |
| `stdio` | On the bot's computer, started by Casama | `command`, `args`, `env`, `cwd` |
| `streamable-http` or `sse` | Your server, called by Casama | `url`, `headers` |

stdio rules:
- `command` is one program (`node`, `python3`) or a path inside the plugin starting with `./`.
  No spaces, no shell lines.
- `${PLUGIN_ROOT}` (plugin files) and `${PLUGIN_DATA}` (survives updates) expand in `args`, `env`
  values and `cwd` only. The server also gets `PLUGIN_ROOT`/`PLUGIN_DATA` env vars; `env` can't
  set them. Default cwd is `PLUGIN_ROOT`; `cwd` must stay inside the plugin or its data folder.

Remote rules: `https` only (plain `http` only for `localhost`, `127.x`, `::1`); no user, password
or `#fragment`; valid, non-repeated header names.

Any other field or broken rule skips that server with a warning. A broken `mcp.json` (bad JSON,
other `$schema`, no `mcpServers`, extra top-level key) disables only the servers; skills still
install.

## Skills

Each immediate folder of `skills/` with a `SKILL.md` is a skill:

```markdown
---
name: weekly-report
description: Turn the week's notes into a one-page report. Use when asked for a weekly report.
---
1. Read the notes with `list_notes` and `read_note`...
```

- `name`: `^[a-z0-9][a-z0-9_-]{0,62}$`; use the folder's name (Casama uses the SKILL.md name).
- `description` is required, first 300 chars kept; say **when** to use it.
- Other files go to `~/skills/<name>/` on the bot's computer with their executable bit: up to 60
  files, 1 MB each, 5 MB total, names of letters, digits, `. _ - /`.
- A broken skill is skipped with a warning; the rest installs.

## The bot's computer (where stdio servers run)

- Ubuntu 24.04, Node.js 24, Python 3 (`pip`, `venv`), bash, git, curl, wget, jq, ripgrep,
  Chromium, Playwright. Anything else: ship it in the plugin.
- Unprivileged user `casama`. Writable: home and `/tmp`. Files at `~/.casama/plugins/<name>/`,
  data at `~/.casama/plugin-data/<name>/`.
- **Nothing is installed for you**: no `npm install`/`pip install`. Bundle the server into one file
  (`esbuild --bundle --platform=node`) or commit its dependencies. `npx` works but downloads on
  first start, and the server has **30 seconds** to answer `initialize`.
- Network goes through an egress proxy that blocks private and metadata addresses.
- Idle servers stop after 10 minutes and restart on the next call; the computer sleeps after 5 idle
  minutes by default. Keep state in `PLUGIN_DATA`, not memory.
- stdout is the MCP channel (one JSON-RPC message per line). Log to **stderr**.
- Mark scripts executable in git (`git update-index --chmod=+x bin/server`) or start them with
  `node`/`python3`.

## Tool risk from MCP annotations

| Annotation | Risk |
| --- | --- |
| `readOnlyHint: true` | low |
| `destructiveHint: true` | high |
| neither | medium |

The bot's autonomy decides which risks need approval. Annotate honestly: true read-only tools run
without asking.

```js
annotations: { title: "List notes", readOnlyHint: true }
annotations: { title: "Save a note", readOnlyHint: false, destructiveHint: false } // medium
```

## Cards for tool results (`com.casama/cards/<tool>.json`)

Show a tool's result as a native card instead of text. One file per MCP tool, a component from
Casama's existing catalog (no new widgets, no HTML, no web views):

```json
{
  "format": 1,
  "card": "Details",
  "title": "#{{result.number}} {{result.title}}",
  "rows": [
    { "label": "State", "value": "{{result.state}}" },
    { "each": "result.labels", "max": 5, "label": "Label", "value": "{{item.name}}" }
  ],
  "when": "result.number"
}
```

- `format: 1` required. `card` = `Details`, `Checklist`, `Event`, `Agenda`, `Schedule`, `Results`,
  `MessageList`, `Stats`, `Map`, `PersonPicker`, `MessageDraft`, a live card (`Weather`, `Quote`,
  `Watchlist`, `Currency`, `Score`, `Flight`, `Parcel`…; your plugin is named as its source), a
  composed card (`Recipe`, `Summary`, `Media`, `Comparison`, `Status`, `Timeline`…; D-453) or a
  basic A2UI component; the rest of the file is its fields (same as `ui.show`, see `ui.catalog`).
  Or `"components": [...]` (flat list, one `root`).
- `{{result.a.b}}` / `{{result.items[0].x}}` read `structuredContent` (else the text as JSON). A
  string that is one whole binding keeps its type; a missing value drops an optional field.
- `"each": "result.items"` (+ `{{item.x}}`, `{{index}}`, `"max"` default 20, ≤ 60) repeats a row
  in a list field. `when` = a result path that must have a value, else the result stays text.
- The run fills it, checks it like `ui.show`, shows it; the model gets the result plus "Shown to the
  person as a card." A fill that fails stays text. Card buttons only send messages.
- plugin-check lists tools with cards; an unknown component or bad binding is skipped with a
  warning (fails `--strict`). Return `structuredContent` from tools. Example: `packs/dev-kit`.

## Check it

Same checks Casama runs at install, plus run-time tips (missing files, programs not in the image,
non-executable scripts, uncommitted files; in a git checkout it reads only tracked files):

```sh
npx @casama/plugin-check . --strict   # Node 20+
node packages/plugin-check/src/main.ts ../my-plugin --strict   # or from a Casama clone, Node 24
```

`--strict` also fails when anything would be skipped or ignored; `--json` prints JSON. Exit 1 =
refused (or warnings under `--strict`). In CI:

```yaml
- uses: actions/checkout@v4
- uses: stackwares/casama/.github/actions/plugin-check@main
  with:
    path: .   # strict: true by default
```

Test a stdio server by hand:

```sh
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"me","version":"1"}}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | node server/notes.mjs
```

## Publish, install, update

1. Push to a public GitHub repo. Link: `https://github.com/you/my-plugin` or
   `https://github.com/you/repo/tree/main/plugins/my-plugin`.
2. Bot settings → **Plugins** → **Add a plugin** → paste. Casama shows skills, each server's
   command or URL, hosts, secrets and warnings, then installs that commit.
3. Updates: push a commit, keep `version` current; people press **Check for update** and see the
   diff (skills, servers, hosts, secrets).
4. Gallery directory (**Reviewed plugins**): PR to `stackwares/casama-gallery` with
   `plugins/<id>/plugin.json` naming the folder URL and the 40-char `commit` (see `casama-gallery`).

API (Bearer user token): `POST /v1/plugins/preview` `{org_id, url, commit?}` → `name, version,
description, repo, path, commit, skills, servers, secrets, hosts, warnings`; `POST /v1/plugins`
`{org_id, bot_id, url, commit, secrets}`; `GET /v1/plugins?bot_id=`; `GET|POST
/v1/plugins/{id}/update`; `DELETE /v1/plugins/{id}`; `GET /v1/plugin-directory`.

## Packs: whole bots, routines, apps and looks

Add `com.casama/pack.json` (`{"format":"casama.pack","version":1,...}`) and the plugin becomes a
pack: `com.casama/bots/<id>.json` (gallery bot format plus `skills`, `routines`, `tools` naming
`mcp.json` servers, `rules` (only `ask`/`hand_off`) and `knowledge` (website or github)),
`com.casama/routines/<id>.json`, `com.casama/apps/<id>/app.json` and `com.casama/looks/...`.
`pack.json` holds `title` (the name people see), `inputs` (install questions; `{{key}}` placeholders, `{{time.hour}}`), `needs.apps`,
`includes` (gallery items), `workspace_skills` and `examples`. Bots never start `autonomous`.
Scaffold with `casama init pack <name>`; `plugin-check --strict` prints its reach (hosts, code,
secrets, weekly scheduled runs, knowledge pages). Install: `POST /v1/packs/preview` then
`POST /v1/packs` `{org_id, url, commit, skip?, inputs?, secrets?, settings?}` (201, or 202 when an
admin must approve), or `casama packs install <link>`. Full format:
https://docs.casama.ai/develop/packs.md. Examples: `examples/hello-pack`, `packs/` in the repo.

## Limits

400 files and 10 MB per plugin; symlinks left out; public GitHub (or private with the workspace's GitHub token); installed per bot, not per
workspace. Stdio servers run on the bot's computer, or with `device_id` on the installer's own computer
through the desktop app (Local tools on, online; only their own runs can use the tools, D-344).

## Checklist

- [ ] `$schema` 1.0.0 in both files; `name` final and valid
- [ ] Every secret has `name`, `server`, and `env` (stdio) or `header` (remote); none in `env`/`headers` literals
- [ ] stdio `command` is `node`/`python3`/etc. or `./path`; paths use `${PLUGIN_ROOT}`; state in `${PLUGIN_DATA}`
- [ ] Server bundled (no `npm install`), answers `initialize` within 30 s, logs to stderr
- [ ] Every tool has honest `readOnlyHint`/`destructiveHint`
- [ ] Optional: tools return `structuredContent`; cards in `com.casama/cards/<tool>.json` with `"format": 1`
- [ ] Each skill folder name = SKILL.md `name`; description says when to use it
- [ ] All files committed and pushed; plugin-check `--strict` passes
