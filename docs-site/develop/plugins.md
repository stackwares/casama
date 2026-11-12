# Plugins

A plugin gives a bot new skills and new tools in one install. Casama reads the open
[Agent Plugins 1.0](https://agent-plugins.org) format, so a plugin is a folder on GitHub with a
`plugin.json`, and optionally an `mcp.json` (tool servers) and a `skills/` folder. A plugin written
for another app that reads the format works in Casama too.

People install a plugin by pasting its GitHub link in a bot's settings, under **Plugins**. They
see what it adds before anything runs, and Casama installs exactly the commit they reviewed.

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
└── server/
    └── notes.mjs          code for a server that runs on the bot's computer
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
  letter or digit. It can't change between versions: an update with a new name is refused.
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

- `url` uses https (plain http only for `localhost` and `127.x`), with no user name, password or
  `#fragment`.
- Header names must be valid and not repeated.

A server that breaks a rule is skipped with a warning. A broken `mcp.json` turns off only the
plugin's servers; its skills still install.

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

- `name`: uppercase letters, digits and `_`, starting with a letter.
- `server`: the key of a server in `mcp.json`.
- For a `stdio` server, `env` names the environment variable the value goes in. For a remote server,
  `header` names the header, and `format` (optional, must contain `{{value}}`) shapes it.
- `description` is shown to the person installing (first 300 characters). Say where to get the
  value.

The person installing is asked for every secret before install. Values are stored in Casama's vault,
never in the plugin's settings and never shown to the model, and they carry over to updates.

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
- The computer sleeps after 10 idle minutes, and an idle server is stopped after 10 minutes; Casama
  starts it again on the next call. Keep state in `PLUGIN_DATA`, not in memory.
- Write logs to stderr. stdout is the MCP channel (one JSON-RPC message per line).
- Mark executable files executable in git (`git update-index --chmod=+x bin/server`), or start them
  with `node` or `python3`.

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
skip or ignore anything. Locally, from a clone of the Casama repository:

```sh
node packages/plugin-check/src/main.ts ../my-plugin
```

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

The response lists `name`, `version`, `commit`, `skills`, `servers`, `secrets`, `hosts` and
`warnings`. Install that commit for a bot, with a value for each secret:

```sh
curl -s -X POST "https://casama.example.com/v1/plugins" \
  -H "authorization: Bearer $TOKEN" -H "content-type: application/json" \
  -d '{"org_id": "'"$ORG"'", "bot_id": "'"$BOT"'", "url": "https://github.com/you/my-plugin",
       "commit": "<40-character commit from the preview>",
       "secrets": {"NOTES_SIGNATURE": "Ana"}}'
```

| Endpoint | What it does |
| --- | --- |
| `POST /v1/plugins/preview` | What a plugin at a GitHub URL would add |
| `POST /v1/plugins` | Install it for a bot, pinned to a commit |
| `GET /v1/plugins?bot_id=...` | A bot's plugins, with each server's status and tools |
| `GET /v1/plugins/{id}/update` | The latest commit and what would change |
| `POST /v1/plugins/{id}/update` | Update to a commit (`commit`, plus `secrets` for new ones) |
| `DELETE /v1/plugins/{id}` | Uninstall |

## Limits

- Up to 400 files and 10 MB per plugin. Symlinks are left out.
- Public GitHub repositories only.
- Plugins are installed per bot, not for a whole workspace.
- `stdio` servers run on the bot's computer; running them on a person's own computer through the
  desktop companion isn't supported yet.
- There's no plugin directory in the app yet: share your link.

## Related

- [Skills](/guide/skills)
- [Hosted MCP](/guide/mcp)
- [Computers](/guide/computers): the environment `stdio` servers run in
- [Autonomy and approvals](/guide/autonomy)
- [Connections](/guide/connections)
