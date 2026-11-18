# casama-dev: a skill pack for building on Casama

Skills and a docs MCP server that make coding agents (Claude Code, Codex, Cursor and others) and
Casama bots themselves good at building on [Casama](https://casama.ai): plugins, the HTTP API,
webhooks, A2A, bot templates, gallery items and changes to the Casama repo.

This folder is one package in two formats:

- an [Agent Plugins 1.0](https://agent-plugins.org) plugin (`plugin.json`, `mcp.json`,
  `skills/`), the format Casama installs;
- a Claude Code plugin (`.claude-plugin/plugin.json`, `.mcp.json`, `skills/`).

## Skills

| Skill | Use it to |
| --- | --- |
| `casama-overview` | Learn the concepts (workspaces, bots, runs, approvals, computers, routines, skills, plugins, gallery), find docs, and pick the next skill |
| `casama-plugin` | Write, check and publish an Agent Plugins 1.0 plugin for Casama bots |
| `casama-api` | Call the HTTP API: sign-in, chat, run events (SSE), approvals, errors, webhooks, SDK and CLI |
| `casama-a2a` | Publish a bot over A2A, or give a bot an outside A2A agent as a tool |
| `casama-bot-template` | Write `.casama-bot.json` templates and routine and skill files, and set up git sync |
| `casama-gallery` | Add apps, skills, starter bots, routine ideas, plugins and looks to the gallery |
| `casama-sites` | Publish pages as sites at their own address, connect domains, read DNS records and states |
| `casama-contribute` | Work on the Casama repository itself |

## Docs MCP server

`casama-docs` is a Streamable HTTP server at `https://api.casama.ai/mcp/docs`. It needs no
sign-in. Its tools are `search_docs(query, limit?)`, `read_doc(page)`, `list_doc_pages()` and
`get_api_operation(query)`. Both `.mcp.json` (Claude Code) and `mcp.json` (Agent Plugins, type
`streamable-http`) point at it.

The local stdio server `npx -y @casama/mcp` has the same docs tools, plus `check_plugin(path)` and
account tools that act as you (`list_workspaces`, `list_bots`, `ask_bot`, `react_to_message`,
`get_run`, `list_approvals`, `decide_approval`, plus the sites and domains tools). It signs in
with your `casama login` session or `CASAMA_TOKEN`.

## Docs for agents without MCP

- https://docs.casama.ai/llms.txt: an index of every page
- https://docs.casama.ai/llms-full.txt: every page in one file
- Each docs page has a Markdown copy at its URL plus `.md`, for example
  https://docs.casama.ai/develop/plugins.md
- OpenAPI 3.1: https://docs.casama.ai/api/openapi.json

## Install

### Claude Code

```text
/plugin marketplace add stackwares/casama
/plugin install casama-dev@casama
```

This adds the skills and the `casama-docs` MCP server.

### Codex

Copy the skills into Codex's skills folder:

```sh
git clone --depth 1 https://github.com/stackwares/casama
mkdir -p ~/.codex/skills && cp -R casama/agent-kit/skills/* ~/.codex/skills/
```

Or keep them in your project and point to them from `AGENTS.md`, for example: "For Casama work,
read `agent-kit/skills/casama-overview/SKILL.md` first." To add the docs server, add
`https://api.casama.ai/mcp/docs` as a Streamable HTTP MCP server in Codex's config.

### Cursor and other agents

```sh
npx skills add stackwares/casama
```

The repository also holds other skills (the catalog bundled with Casama), so choose the
`casama-*` ones. You can also copy the folders under `agent-kit/skills/` into your agent's skills
folder. Then add the docs server, for example in `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "casama-docs": { "url": "https://api.casama.ai/mcp/docs" }
  }
}
```

### Casama bots

In a bot's settings, open **Plugins** → **Add a plugin** and paste:

```text
https://github.com/stackwares/casama/tree/main/agent-kit
```

The bot gets the seven skills and the `casama-docs` server. The docs server is on Casama Cloud
(`api.casama.ai`), so a self-hosted server's bot needs to be able to reach it.

## Check this package

From the repository root:

```sh
npx @casama/plugin-check agent-kit --strict
```

## License

Apache-2.0.
