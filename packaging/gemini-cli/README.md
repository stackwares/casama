# Casama for Gemini CLI

Give [Casama](https://casama.ai) bots tasks from Gemini CLI. Each bot has its own computer, memory,
tools and connected apps; risky steps wait for your approval in the Casama app.

```sh
gemini extensions install https://github.com/stackwares/casama-gemini
```

Then start `gemini` and ask, for example, "Ask my Casama research bot to compare three CRMs for a
five-person bakery". The first call opens your browser to sign in to Casama and pick a workspace.
You can also run `/mcp auth casama`.

## What it adds

| Server | Address | Sign-in |
| --- | --- | --- |
| `casama` | `https://api.casama.ai/mcp` | OAuth, one workspace |
| `casama-docs` | `https://api.casama.ai/mcp/docs` | None |

Tools: `list_workspaces`, `list_bots`, `ask_bot`, `get_run`, `react_to_message`,
`list_approvals`, `decide_approval`, sites and domains tools, packs tools, and the docs tools
`search_docs`, `read_doc`, `list_doc_pages` and `get_api_operation`. Every tool says whether it
only reads or can change things.

Using a self-hosted Casama server? Point the servers at your own API in `~/.gemini/settings.json`
under `mcpServers` with the same names; settings there take precedence over the extension.

## Links

- Guide: https://docs.casama.ai/guide/mcp
- Privacy: https://casama.ai/privacy
- Terms: https://casama.ai/terms
- Support: support@casama.ai

This repository is generated from `packaging/gemini-cli/` and `agent-kit/skills/` in
[stackwares/casama](https://github.com/stackwares/casama). Send changes there.
