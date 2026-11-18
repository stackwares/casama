# Build with AI agents

If you build on Casama with a coding agent such as Claude Code, Codex or Cursor, give it these and
it can answer from the real docs and API instead of guessing. Every option is free and needs no
Casama account.

| What | Gives your agent | Set up |
| --- | --- | --- |
| [Agent kit](#the-agent-kit) | Skills for plugins, the API, A2A, bot templates, the gallery and the Casama repo, plus the docs server | One command in Claude Code |
| [Docs server (MCP)](#the-docs-server) | Search the docs, read any page, look up any API operation | One URL |
| [Docs as markdown](#docs-as-markdown) | `llms.txt`, a markdown copy of every page, the OpenAPI document | Nothing |
| [The gallery](#check-the-gallery-first) | Ready-made skills, apps, routines, bots, plugins and looks to reuse before building | `gallery_search`, or plain JSON |
| [Starter projects](#starter-projects) | A plugin, skill, bot or routine to start from, with an `AGENTS.md` | `casama init` |
| [Plugin checker](#check-a-plugin) | The same checks Casama runs at install | `npx @casama/plugin-check` |
| [TypeScript client](/develop/typescript) | Typed calls for every API route | `npm i @casama/client` |

## The agent kit

The agent kit is a set of skills, one per job, plus the docs server. A skill holds the exact
formats, limits and steps for its job, and the agent loads it only when the task calls for it.

| Skill | For |
| --- | --- |
| `casama-overview` | What Casama is, its concepts, where the docs are, and which skill to load next |
| `casama-plugin` | Write, check and publish a [plugin](/develop/plugins) |
| `casama-api` | Call the [HTTP API](/develop/api): sign in, chat with a bot, follow runs, approvals, [webhooks](/develop/webhooks), SDKs and the CLI |
| `casama-a2a` | Publish a bot over [A2A](/develop/a2a), or call an outside agent |
| `casama-bot-template` | [Bot templates](/develop/bot-templates), and [routines and skills as files](/develop/workspace-files) |
| `casama-gallery` | Add apps, skills, starter bots, routine ideas, plugins and themes to the [gallery](https://gallery.casama.ai) |
| `casama-sites` | Publish pages as [sites](/guide/sites-and-domains) at their own address, connect domains, read DNS records and states |
| `casama-contribute` | Change Casama itself. See also [Contribute to Casama](/develop/contributing). |

**Claude Code:**

```text
/plugin marketplace add stackwares/casama
/plugin install casama-dev@casama
```

**Codex, Cursor and other tools:** copy the folders in
[`agent-kit/skills`](https://github.com/stackwares/casama/tree/main/agent-kit/skills) to where
your tool reads skills (for Codex, `~/.codex/skills`), and add the docs server below.

**A Casama bot:** the kit is also a Casama plugin. In a bot's settings, under **Plugins**, paste
`https://github.com/stackwares/casama/tree/main/agent-kit`.

## The docs server

`https://api.casama.ai/mcp/docs` is an MCP server (Streamable HTTP) with the docs tools. It needs
no sign-in and can't see any account.

```sh
claude mcp add --transport http casama-docs https://api.casama.ai/mcp/docs
```

Cursor (`~/.cursor/mcp.json`) and other tools that take JSON:

```json
{
  "mcpServers": {
    "casama-docs": { "url": "https://api.casama.ai/mcp/docs" }
  }
}
```

| Tool | What it does |
| --- | --- |
| `search_docs` | Searches the docs by keyword and returns the best-matching sections |
| `read_doc` | One page as markdown, or one section of it |
| `list_doc_pages` | Every page, with its title and address |
| `get_api_operation` | Finds API operations by operationId (`sendMessage`), `METHOD /path` (`POST /v1/routines`) or keywords, and shows their parameters, request body and responses as types |

The local server, `npx -y @casama/mcp`, has the same tools plus `check_plugin` and
`gallery_search`, and the tools that work with your bots once you sign in. With `--docs-only` it runs without a sign-in. See
[Connect AI apps](/guide/mcp#docs-tools-for-building-on-casama).

A self-hosted server answers at `/mcp/docs` too, from the docs that shipped with it.

## Docs as markdown

| Address | What's there |
| --- | --- |
| [`docs.casama.ai/llms.txt`](https://docs.casama.ai/llms.txt) | An index of every page, with a one-line summary and a link to its markdown ([llmstxt.org](https://llmstxt.org)) |
| `docs.casama.ai/<page>.md` | Any page as markdown: add `.md` to its address, for example [`/develop/plugins.md`](https://docs.casama.ai/develop/plugins.md) |
| [`docs.casama.ai/llms-full.txt`](https://docs.casama.ai/llms-full.txt) | Every page in one file, about 600 KB |
| [`docs.casama.ai/api/openapi.json`](https://docs.casama.ai/api/openapi.json) | The HTTP API as OpenAPI 3.1. Your own server serves its version at `/openapi.json`. |

The buttons at the top of every page do the same by hand: **Copy page** copies its markdown, and
**Open in Claude** and **Open in ChatGPT** start a chat that reads it.

## Check the gallery first

Before your agent writes a new skill, bot, routine, plugin or look, have it look in the
[gallery](https://gallery.casama.ai): someone may have made it already, and a gallery item comes
checked and ready to add.

- **MCP:** the `gallery_search` tool of `npx -y @casama/mcp` takes plain words and, optionally,
  the kinds to search (`skill`, `app`, `routine`, `bot`, `plugin`, `set`, `theme`, `scheme`,
  `wallpaper`). It returns the best matches with what each can access, what it needs and its page.
- **Terminal:** `casama gallery search "summarize unread email"`, or start from a bot or plugin with
  `casama init --from-gallery bot/<id>` (or `plugin/<id>`). See the [CLI](/develop/cli#the-gallery-gallery).
- **Plain JSON**, no sign-in:

| File | What's in it |
| --- | --- |
| [`index.json`](https://gallery.casama.ai/index.json) | Themes, color schemes, wallpapers and skills |
| [`apps.json`](https://gallery.casama.ai/apps.json) | Apps bots can connect to |
| [`bots.json`](https://gallery.casama.ai/bots.json) | Starter bots |
| [`routines.json`](https://gallery.casama.ai/routines.json) | Routine ideas |
| [`plugins.json`](https://gallery.casama.ai/plugins.json) | Reviewed plugins, each pinned to a commit |
| [`sets.json`](https://gallery.casama.ai/sets.json) | Starter sets of items that go together |
| [`authors.json`](https://gallery.casama.ai/authors.json) | Authors and their items |
| [`manifest.json`](https://gallery.casama.ai/manifest.json) | The SHA-256 of every file above, signed with Ed25519 in `manifest.sig` |
| [`api.casama.ai/v1/gallery/stats`](https://api.casama.ai/v1/gallery/stats) | How many people use each item, what's trending and how often its runs finish, keyed `<type>/<id>`. Small numbers are left out. |

Each item has a page at `https://gallery.casama.ai/i/<type>/<id>/` with an **Open in Casama**
button. The item formats are in [Gallery catalog format](/develop/gallery-format).

Bots inside Casama do the same: when someone asks for something a bot has no skill or app for,
the bot searches the gallery and offers a match as a card with an **Add** button.

## Starter projects

The [CLI](/develop/cli) writes a starting point that already passes Casama's checks:

```sh
casama init plugin acme-weather                    # plugin.json, mcp.json, a small server, a skill, a CI check
casama init skill weekly-report                    # a SKILL.md
casama init bot support --name "Support Desk"      # a .casama-bot.json template
casama init routine routines --name "Daily digest" # a routine file
```

Each one includes an `AGENTS.md` that tells your coding agent the format's rules, how to check the
work and where the docs are. `init` needs no sign-in and never overwrites a file unless you pass
`--force`.

The examples in the repository have one too:
[`examples/hello-plugin`](https://github.com/stackwares/casama/tree/main/examples/hello-plugin)
and
[`examples/sdk_sample`](https://github.com/stackwares/casama/tree/main/examples/sdk_sample).

## Check a plugin

```sh
npx @casama/plugin-check . --strict
```

It runs the code Casama runs when someone installs a plugin, and exits 1 when Casama would refuse
it (with `--strict`, also when it would skip anything). Agents can run it after every change and
fix what it reports. In CI, use the GitHub Action, as described in
[Plugins](/develop/plugins#check-your-plugin).

## Tips for working with an agent

- Ask it to load `casama-overview` first, or to read `llms.txt`, before it plans anything.
- Have it search the gallery before it builds a skill, bot, routine or plugin.
- For API work, have it look up each operation with `get_api_operation` rather than writing request
  bodies from memory. The API changes between versions; the OpenAPI document doesn't lie.
- Point it at your own server: the local MCP server reads `CASAMA_API_URL`, and `/openapi.json`
  on your server describes exactly what it runs.
- For plugins, put the plugin check in the loop: write, check, fix, then commit.

## Related

- [HTTP API](/develop/api)
- [Plugins](/develop/plugins)
- [Connect AI apps (MCP)](/guide/mcp)
- [CLI](/develop/cli)
- [TypeScript client](/develop/typescript)
