# hello-casama: an example plugin

A small, working [Agent Plugins 1.0](https://agent-plugins.org) package for Casama. Copy it to
start your own; the [plugins guide](../../docs-site/develop/plugins.md) explains every part.

| File                           | What it shows                                                                                                       |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| `plugin.json`                  | The manifest, and a secret declared under Casama's extension (`com.casama`)                                         |
| `mcp.json`                     | A `stdio` server that runs on the bot's computer, using `${PLUGIN_ROOT}` and `${PLUGIN_DATA}`                       |
| `server/notes.mjs`             | An MCP server in plain Node.js with no dependencies: three tools with risk annotations, notes kept in `PLUGIN_DATA` |
| `skills/team-standup/SKILL.md` | A skill that uses the server's tools                                                                                |

## Try it

Check it the way Casama will, from the repository root:

```sh
node packages/plugin-check/src/main.ts examples/hello-plugin
```

Talk to the server by hand (one JSON-RPC message per line):

```sh
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"me","version":"1"}}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  | NOTES_DIR=/tmp/notes node examples/hello-plugin/server/notes.mjs
```

Install it on a bot: bot settings → **Plugins** → **Add a plugin**, and paste
`https://github.com/stackwares/casama/tree/main/examples/hello-plugin`. Casama asks for
`NOTES_SIGNATURE`, then the bot can write a stand-up and save it as a note.

## Make it yours

1. Copy this folder into a new repository and change `name` in `plugin.json` (it can't change
   later).
2. Replace the server and skill with your own. For a bigger server, use the official SDK
   (`@modelcontextprotocol/sdk` or the Python `mcp` package) and bundle it into the plugin, since
   Casama doesn't run `npm install`.
3. Add the check to your repository's workflow:
   `uses: stackwares/casama/.github/actions/plugin-check@main`.
