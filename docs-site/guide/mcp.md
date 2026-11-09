# MCP server

Control your bots from AI coding tools (Claude Code, Cursor, Codex and others) with the Kasama MCP
server.

```sh
kasama login
claude mcp add kasama -- npx -y @kasama/mcp
```

Tools: `list_workspaces`, `list_bots`, `ask_bot` (waits for the reply), `get_run`,
`list_approvals`, `decide_approval`. Bots can also use other MCP servers as tools: add one under
Settings → Integrations.
