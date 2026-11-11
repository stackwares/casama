# Connect AI apps to Casama (MCP)

Casama is an MCP server, so AI apps such as Claude Code, Cursor and other MCP clients can list your
bots, give them tasks and read the results. Use it when you work in another AI app and want a
Casama bot, with its own computer, memory and tools, to do part of the job.

There are two ways to connect:

| | Hosted, by URL | Local, over stdio |
| --- | --- | --- |
| Address | `https://<your Casama API>/mcp` (Streamable HTTP) | The `casama-mcp` command from `@casama/mcp` |
| Best for | Apps that only take a URL: web and mobile AI apps, custom connectors | Desktop coding tools |
| Sign-in | OAuth, or a workspace API key | Your `casama login` session, or `CASAMA_TOKEN` |
| Scope | One workspace | Every workspace you belong to |

Both give the same tools, and your bots' approvals, action rules and budgets apply either way.

This page is about AI apps using Casama. To let your bots use other MCP servers as tools, see
[Connections](/guide/connections).

## Find your address

1. Open **Settings → Workspace settings**.
2. Under **Connect AI apps**, copy the address.

It's your API's address followed by `/mcp`, for example `https://api.example.com/mcp`. Self-hosters
can set the advertised address with `PUBLIC_API_URL`; otherwise Casama uses the address the request
came in on.

## Hosted with OAuth (recommended)

1. In your AI app, add a custom connector or remote MCP server and give it the address:

   ```text
   https://api.example.com/mcp
   ```

2. The app finds Casama's sign-in on its own, registers itself, and opens Casama in your browser.
3. On the screen that says the app wants to use Casama, pick the **Workspace** and tap
   **Allow** (or **Refuse**).
4. When you see **Done. You can go back to the AI app.**, return to the app.

The app acts as you, in that one workspace only. Its access token lasts an hour. The app renews
it with a refresh token that lasts 60 days and is replaced each time it's used. Connections are
recorded in the workspace's audit log.

## Hosted with an API key

Use a key for apps that don't support OAuth, or for scripts. Owners and admins create keys.

1. Open **Settings → Workspace settings → Connect AI apps**.
2. Tap **New API key**, enter a **Name** and tap **Create**.
3. Copy the key (it starts with `ksk_`). It isn't shown again.

The key acts as the person who created it, in that workspace only. Revoke it there at any time. A
key or OAuth connection also stops working if that person leaves the workspace.

Cursor (`~/.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "casama": {
      "url": "https://api.example.com/mcp",
      "headers": { "Authorization": "Bearer ksk_..." }
    }
  }
}
```

Claude Code:

```sh
claude mcp add --transport http casama https://api.example.com/mcp \
  --header "Authorization: Bearer ksk_..."
```

Any client that supports Streamable HTTP with custom headers works the same way.

## Local over stdio

The local server runs on your machine and uses the same sign-in as the Casama CLI.

1. Sign in with the CLI:

   ```sh
   casama login
   ```

2. Add the server to your tool. Claude Code:

   ```sh
   claude mcp add casama -- npx -y @casama/mcp
   ```

   Any tool that takes a JSON config:

   ```json
   {
     "mcpServers": {
       "casama": { "command": "npx", "args": ["-y", "@casama/mcp"] }
     }
   }
   ```

| Environment variable | What it does |
| --- | --- |
| `CASAMA_API_URL` | Your Casama API. Default: the address from `casama config`, else `http://localhost:8787`. |
| `CASAMA_TOKEN` | An access token to use instead of the CLI's saved session |
| `CASAMA_CONFIG_DIR` | Where to find the CLI's saved session and config |

With the CLI session, the server refreshes your sign-in as needed. See [CLI](/develop/cli).

## Tools

| Tool | What it does |
| --- | --- |
| `list_workspaces` | Workspaces you belong to, with your role |
| `list_bots` | Bots in a workspace, with their status. Takes an optional workspace slug, name or id. |
| `ask_bot` | Sends a message to a bot (by name or id) and waits for the run to finish, fail or need approval. Returns the reply, the tools used, the cost, and the conversation and run ids. Pass `conversation_id` to continue a thread. |
| `get_run` | A run's status and cost, and its recent events: tool calls, outputs and errors |
| `list_approvals` | Actions waiting for approval in a workspace |
| `decide_approval` | Approves or denies a pending action. The bot continues, or skips the step, right away. |

`ask_bot` waits up to 10 minutes. If the bot needs approval, the result says `waiting_approval`;
approve it in the Casama app, or with `decide_approval` if your workspace allows it.

## Allow approvals from AI apps

By default, connected apps can't approve or deny your bots' actions, so a bot can't get its own
risky step approved by the app that asked for it.

To change that, an owner or admin opens **Settings → Workspace settings → Connect AI apps** and
turns on **Allow approvals from AI apps**.

| Connection | Can use `decide_approval` |
| --- | --- |
| OAuth or API key | Only when **Allow approvals from AI apps** is on |
| Local stdio with your own sign-in | Yes, like the app |

Either way, a high-risk step still stops and waits for a decision. See
[Autonomy, approvals and action rules](/guide/autonomy).

## Limits

- The local server needs Node.js 24 or later.
- OAuth connections and API keys don't count as a two-step sign-in. In a workspace that requires
  two-step sign-in for admins, they get member access only.
- The **Connect AI apps** section is shown to owners and admins only.
- OAuth sign-in only accepts apps whose redirect address is `https` or `localhost`.

## Related

- [Connections](/guide/connections)
- [Autonomy, approvals and action rules](/guide/autonomy)
- [CLI](/develop/cli)
- [API](/develop/api)
- [Talk to outside agents (A2A)](/develop/a2a)
