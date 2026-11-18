# AGENTS.md

`hello-casama` is the example plugin for Casama (https://casama.ai) in the open Agent Plugins 1.0
format: a stand-up skill plus a small notes server with one secret. People copy it to start their
own plugin. Full guide: https://docs.casama.ai/develop/plugins.md

## Layout

- `plugin.json`: the manifest, with the `NOTES_SIGNATURE` secret under `extensions["com.casama"]`.
- `mcp.json`: one `stdio` server, `notes`, run on the bot's computer with `${PLUGIN_ROOT}` and
  `${PLUGIN_DATA}`.
- `server/notes.mjs`: the server in plain Node.js, no dependencies (newline-delimited JSON-RPC 2.0
  on stdio). Three tools with risk annotations; notes are kept in `NOTES_DIR` under `PLUGIN_DATA`.
- `skills/team-standup/SKILL.md`: a skill that uses the server's tools.

## Rules

- Keep it small and dependency-free: it's a teaching example, and the docs link to it.
- `plugin.json`: `$schema` stays `https://agent-plugins.org/schemas/1.0.0/plugin.schema.json`.
  Only `$schema`, `name`, `version`, `description`, `author`, `homepage`, `repository`,
  `license`, `keywords` and `extensions`. Don't change `name`: an update with a new name is refused.
- `mcp.json`: only `$schema` and `mcpServers`; a `stdio` server has only `type`, `command`,
  `args`, `env`, `cwd`. `command` is one program or a `./path` inside the plugin. Secrets never go
  in `env`: they're declared under `extensions["com.casama"].secrets` and filled in by Casama.
- Skills: folder name = `name` in the front matter (lowercase letters, digits, `-`, `_`, up to
  63); `description` is required and says when to use the skill (first 300 characters kept).
- The server runs on Ubuntu 24.04 with Node.js 24 and nothing installed, answers `initialize`
  within 30 seconds, writes only JSON-RPC to stdout (logs to stderr) and keeps state in
  `PLUGIN_DATA`. Annotate tools honestly: `readOnlyHint: true` is low risk, `destructiveHint: true`
  is high, neither is medium.
- If you change what the example shows, update `README.md` here and
  `docs-site/develop/plugins.md`, which describe it.

## Check

From the repository root (Node 24+):

```sh
node packages/plugin-check/src/main.ts examples/hello-plugin --strict
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
  | NOTES_DIR=/tmp/notes node examples/hello-plugin/server/notes.mjs
```

The check must exit 0. `casama init plugin <folder>` scaffolds a new plugin with the same layout.

## Docs and tools

- Every Casama doc, for agents: https://docs.casama.ai/llms.txt (each page also has a `.md`
  version, such as the one linked above).
- Casama's agent kit for Claude Code: `/plugin marketplace add stackwares/casama`, then
  `/plugin install casama-dev@casama`.
- Casama's docs as an MCP server: `https://api.casama.ai/mcp/docs`.
