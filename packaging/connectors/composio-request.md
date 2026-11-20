# Composio toolkit request: Casama

Posted 2026-11-20 on Composio's request board:
https://request.composio.dev/boards/tool-requests/posts/casama-ai-bots-with-their-own-computers-hosted-mcp-rest-api-oauth-2-1

**Title:** Casama (AI bots with their own computers: hosted MCP + REST API, OAuth 2.1)

**Body:**

Casama (https://casama.ai) runs AI bots ("teammates") that each have their own cloud computer,
memory and tools, and ask a person before risky steps. A Casama toolkit would let Composio agents
hand a long task to a Casama bot and get the finished result back.

Everything a toolkit needs is already public:

- **Auth:** OAuth 2.1 with discovery (`https://api.casama.ai/.well-known/oauth-authorization-server`),
  dynamic client registration, PKCE S256, refresh tokens, token revocation (RFC 7009). Also
  workspace API keys (`Authorization: Bearer ksk_…`) for API-key auth.
- **Hosted MCP server:** `https://api.casama.ai/mcp` (Streamable HTTP). Every tool has MCP
  annotations (read-only / destructive / open-world).
- **REST API + OpenAPI:** https://docs.casama.ai/develop/api, spec at
  https://github.com/stackwares/casama/blob/main/packages/contracts/openapi.json
- **Docs:** https://docs.casama.ai/guide/mcp

Suggested tools:

| Tool | What it does |
| --- | --- |
| List workspaces / List bots | Find the bot to use |
| Ask bot | Send a task to a bot; returns the reply, tools used, cost, conversation and run ids |
| Get run | Status, cost and steps of a run (for long tasks) |
| List approvals / Decide approval | Steps waiting for a person's OK (deciding is off unless the workspace allows it) |
| List sites, domains; check / connect domain | Pages a bot published and their domains |
| List / preview / install packs | Ready-made bots and skills |

Triggers we could add: run completed, approval requested (we have webhooks:
https://docs.casama.ai/develop/webhooks).

Contact: support@casama.ai. Happy to give the Composio team a test workspace.
