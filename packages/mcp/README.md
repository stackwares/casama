# Kasama MCP server

Control your Kasama bots from AI coding tools over the Model Context Protocol, using your
`kasama login` session. For apps that only take a URL, use the hosted endpoint at
`https://<your server>/mcp` instead. Both are described in
[Connect AI apps](../../docs-site/guide/mcp.md).

```sh
kasama login                     # once, with the Kasama CLI
claude mcp add kasama -- npx -y @kasama/mcp
```

Tools: `list_workspaces`, `list_bots`, `ask_bot` (sends a message and waits for the reply; pass
`conversation_id` to continue), `get_run`, `list_approvals`, `decide_approval`.

Settings: `KASAMA_API_URL` (defaults to the CLI's saved server, else `http://localhost:8787`) and
either the CLI login (refreshed automatically) or `KASAMA_TOKEN`.
