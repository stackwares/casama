# Casama MCP server

Two things for AI coding tools, over the Model Context Protocol:

- **Docs tools**, no sign-in: search [docs.casama.ai](https://docs.casama.ai), read any page, look
  up any HTTP API operation, and check a plugin folder. For anyone building on Casama.
- **Your bots**, with your `casama login` session: list workspaces and bots, ask a bot and wait for
  its reply, read runs, and list and decide approvals.

```sh
claude mcp add casama -- npx -y @casama/mcp                    # everything (sign in with `casama login`)
claude mcp add casama-docs -- npx -y @casama/mcp --docs-only   # the docs tools only, no sign-in
```

Apps that only take a URL can use the hosted endpoints instead: `https://api.casama.ai/mcp/docs`
(the docs tools, no sign-in) and `https://<your server>/mcp` (everything, with OAuth or a workspace
API key). Both are described in [Connect AI apps](https://docs.casama.ai/guide/mcp).

| Tools | |
| --- | --- |
| Docs | `search_docs`, `read_doc`, `list_doc_pages`, `get_api_operation`, `check_plugin` (local only) |
| Gallery | `gallery_search` (local only): ready-made skills, apps, routines, bots, plugins, starter sets and looks on gallery.casama.ai |
| Your bots | `list_workspaces`, `list_bots`, `ask_bot` (sends a message and waits for the reply; pass `conversation_id` to continue), `get_run`, `list_approvals`, `decide_approval` |
| Sites and domains | `list_sites`, `list_domains`, `get_domain`, `check_domain`, `connect_domain`, `search_domains` (nothing buys, renews or moves a domain) |

Settings: `CASAMA_API_URL` (defaults to the CLI's saved server, else `https://api.casama.ai`),
either the CLI login (refreshed automatically) or `CASAMA_TOKEN`, `CASAMA_DOCS_URL` (default
`https://docs.casama.ai`) and `CASAMA_GALLERY_URL` (default `https://gallery.casama.ai`).

More ways to give a coding agent Casama's knowledge (skills, `llms.txt`, starter projects):
[Build with AI agents](https://docs.casama.ai/develop/agents).
