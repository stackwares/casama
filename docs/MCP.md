# Connect AI apps to Kasama (MCP)

Kasama serves its tools over MCP in two ways:

- **Hosted, by URL:** `https://<your Kasama API>/mcp` (Streamable HTTP). For apps that only take
  a URL (web and mobile AI apps, custom connectors). Sign in with OAuth, or use a workspace API key.
- **Local, over stdio:** `kasama-mcp` (from `@kasama/mcp`), using your `kasama login` session. For
  desktop coding tools.

Both give the same tools: `list_workspaces`, `list_bots`, `ask_bot`, `get_run`, `list_approvals`
and `decide_approval`. Your bots' approvals, action rules and budgets apply either way. Deciding
approvals from a connected app is off unless the workspace turns it on (Workspace settings →
Connect AI apps).

## Hosted with OAuth (recommended)

Add a custom connector or remote MCP server and give it the URL. The app discovers sign-in on its
own (`/.well-known/oauth-protected-resource`), registers itself, and sends you to Kasama to allow it
for one workspace.

```
https://api.example.com/mcp
```

## Hosted with an API key

Create a key in Workspace settings → Connect AI apps (owners and admins). It acts as you, in that
workspace only. Revoke it there at any time.

Cursor (`~/.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "kasama": {
      "url": "https://api.example.com/mcp",
      "headers": { "Authorization": "Bearer ksk_..." }
    }
  }
}
```

Claude Code:

```sh
claude mcp add --transport http kasama https://api.example.com/mcp --header "Authorization: Bearer ksk_..."
```

Any client that supports Streamable HTTP with headers works the same way.

## Local (stdio)

```json
{
  "mcpServers": {
    "kasama": { "command": "npx", "args": ["-y", "@kasama/mcp"] }
  }
}
```

It uses the session from `kasama login`, or `KASAMA_TOKEN` and `KASAMA_API_URL`.
