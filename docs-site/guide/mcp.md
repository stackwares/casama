# Connect AI apps to Casama (MCP)

Casama is an MCP server, so AI apps such as Claude, ChatGPT, Gemini CLI, Cursor and other MCP
clients can list your bots, give them tasks and read the results. Use it when you work in another AI app and want a
Casama bot, with its own computer, memory and tools, to do part of the job.

There are two ways to connect:

| | Hosted, by URL | Local, over stdio |
| --- | --- | --- |
| Address | `https://<your Casama API>/mcp` (Streamable HTTP) | The `casama-mcp` command from `@casama/mcp` |
| Best for | Apps that only take a URL: web and mobile AI apps, custom connectors | Desktop coding tools |
| Sign-in | OAuth, or a workspace API key | Your `casama login` session, or `CASAMA_TOKEN` |
| Scope | One workspace | Every workspace you belong to |

Both give the same tools, and your bots' approvals, action rules and budgets apply either way.

Building something on Casama? The [docs tools](#docs-tools-for-building-on-casama) let a coding
agent search these docs and the API reference, with no sign-in.

This page is about AI apps using Casama. To let your bots use other MCP servers as tools, see
[Connections](/guide/connections).

## Find your address

1. Open **Settings → Workspace settings** and open **Advanced**.
2. Under **Connect AI Apps**, copy the address.

It's your API's address followed by `/mcp`, for example `https://api.example.com/mcp`. Self-hosters
can set the advertised address with `PUBLIC_API_URL`; otherwise Casama uses the address the request
came in on.

## Add Casama to your AI app

On Casama Cloud the address is `https://api.casama.ai/mcp`. On your own server, use
[your address](#find-your-address). Every app below signs in with OAuth: you pick the workspace and
tap **Allow** in Casama, as in [Hosted with OAuth](#hosted-with-oauth-recommended).

| App | Where to add it |
| --- | --- |
| Claude (claude.ai and the desktop app) | **Settings → Connectors → Add custom connector**. Give it a name (Casama) and the address, then **Connect**. |
| ChatGPT | Turn on developer mode under **Settings → Apps → Advanced settings**, then create an app with the address and OAuth sign-in. |
| Gemini CLI | `gemini extensions install https://github.com/stackwares/casama-gemini`, or `gemini mcp add --transport http casama https://api.casama.ai/mcp`. Then `/mcp auth casama`. |
| Claude Code | `claude mcp add --transport http casama https://api.casama.ai/mcp`, then `/mcp` to sign in. |
| VS Code (Copilot) | `code --add-mcp '{"name":"casama","type":"http","url":"https://api.casama.ai/mcp"}'` |
| Cursor | Add the address under `mcpServers` in `~/.cursor/mcp.json` as `"url"`. |

Menu names change as these apps update; look for "connectors", "apps" or "MCP servers". Apps
that can't sign in with OAuth can use an [API key](#hosted-with-an-api-key).

Try it with a request such as:

- "List my Casama bots."
- "Ask my research bot to compare three CRMs for a five-person bakery and give me a table."
- "Do any of my Casama bots have steps waiting for my approval?"

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

1. Open **Settings → Workspace settings → Advanced → Connect AI Apps**.
2. Tap **New API Key**, enter a **Name** and tap **Create**.
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

The local server runs on your machine and uses the same sign-in as the Casama CLI. `@casama/mcp` is
also listed in the official MCP Registry as `io.github.stackwares/casama`, so tools that browse the
registry can add it from there.

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
| `CASAMA_API_URL` | Your Casama API. Default: the address from `casama config`, else `https://api.casama.ai`. |
| `CASAMA_TOKEN` | An access token to use instead of the CLI's saved session |
| `CASAMA_CONFIG_DIR` | Where to find the CLI's saved session and config |
| `CASAMA_DOCS_URL` | Where the docs tools read the docs. Default: `https://docs.casama.ai` |

With the CLI session, the server refreshes your sign-in as needed. See [CLI](/develop/cli).

## Tools

**Reads** means the tool only reads. **Changes** means it can change something in Casama, and
**Acts** means it can lead to actions outside Casama. Each tool tells the AI app which it is, so
apps can ask you before calling one that changes or acts.

| Tool | Kind | What it does |
| --- | --- | --- |
| `list_workspaces` | Reads | Workspaces you belong to, with your role |
| `list_bots` | Reads | Bots in a workspace, with their status. Takes an optional workspace slug, name or id. |
| `ask_bot` | Acts | Sends a message to a bot (by name or id) and waits for the run to finish, fail or need approval. Returns the reply, the tools used, the cost, and the conversation and run ids. Pass `conversation_id` to continue a thread. The bot may use its computer and connected apps; risky steps wait for approval. |
| `get_run` | Reads | A run's status and cost, and its recent events: tool calls, outputs and errors |
| `react_to_message` | Changes | Reacts to a message with one emoji, or takes your reaction back (`remove`). Without `message_id` it reacts to the bot's latest reply in the conversation. A 👍 or 👎 tells the bot whether the reply worked. |
| `list_approvals` | Reads | Actions waiting for approval in a workspace |
| `decide_approval` | Acts | Approves or denies a pending action. The bot continues, or skips the step, right away. |
| `list_sites` | Reads | Pages published on the web at their own address, with their hosts and states |
| `list_domains`, `get_domain` | Reads | Connected and bought domains: the site each shows, its state, the DNS records to add with what DNS shows now |
| `check_domain` | Changes | Checks a domain's DNS and certificate now (admins) |
| `connect_domain` | Changes | Connects a domain the workspace owns, optionally to a published site; answers the records to add (admins) |
| `search_domains` | Reads | Names with availability and prices. Only a person can buy one, in the app. |
| `list_packs` | Reads | Packs installed in the workspace |
| `preview_pack` | Reads | What a pack from GitHub or the plugin directory would add, and the commit to install |
| `install_pack` | Changes | Installs a pack at the previewed commit. Secrets are added in the app, never over MCP. |

Both servers also have the [docs tools](#docs-tools-for-building-on-casama), and the local one
has `check_plugin` and `gallery_search`.

`ask_bot` waits up to 10 minutes. If the bot needs approval, the result says `waiting_approval`;
approve it in the Casama app, or with `decide_approval` if your workspace allows it.

## Docs tools for building on Casama

For people building on Casama, and their coding agents, there's a docs-only server at
`https://api.casama.ai/mcp/docs`. It needs no sign-in and can't see any account. A self-hosted
server has one too, at `/mcp/docs`, reading the docs shipped with that server.

```sh
claude mcp add --transport http casama-docs https://api.casama.ai/mcp/docs
```

| Tool | What it does |
| --- | --- |
| `search_docs` | Searches these docs by keyword and returns the best-matching sections, with their address |
| `read_doc` | One page as markdown, by path (`/develop/plugins`) or address. Pass `section` for one section. |
| `list_doc_pages` | Every page, with its title and address |
| `get_api_operation` | Looks up the [HTTP API](/develop/api) by operationId (`sendMessage`), `METHOD /path` or keywords, and shows the parameters, request body and responses as types |
| `check_plugin` | Local server only: checks a [plugin](/develop/plugins) folder the way Casama does at install |
| `gallery_search` | Local server only: searches the [gallery](https://gallery.casama.ai) for ready-made skills, apps, routines, bots, plugins, starter sets and looks, so an agent reuses one before building it |

The local server has these tools too. To run only them, with no sign-in:

```sh
claude mcp add casama-docs -- npx -y @casama/mcp --docs-only
```

See [Build with AI agents](/develop/agents) for the other ways agents can learn Casama.

## Allow approvals from AI apps

By default, connected apps can't approve or deny your bots' actions, so a bot can't get its own
risky step approved by the app that asked for it.

To change that, an owner or admin opens **Settings → Workspace settings → Advanced → Connect AI
Apps** and turns on **Allow Approvals from AI Apps**.

| Connection | Can use `decide_approval` |
| --- | --- |
| OAuth or API key | Only when **Allow Approvals from AI Apps** is on |
| Local stdio with your own sign-in | Yes, like the app |

Either way, a high-risk step still stops and waits for a decision. See
[Autonomy, approvals and action rules](/guide/autonomy).

## What a connected app can see

A connected app acts as you, in one workspace, and only through the [tools](#tools) above. It
goes through the same rules as the Casama app, so it reaches only what you can reach there. No
tool reads your connections' secrets, buys anything or changes billing, and `decide_approval` is
refused unless an owner or admin [allows it](#allow-approvals-from-ai-apps). What the app does
with what it reads is covered by that app's own privacy policy. See
[Privacy and security](/guide/privacy) and [casama.ai/privacy](https://casama.ai/privacy).

## See and disconnect connected apps

Open **Settings → Workspace settings**, open **Advanced**, and find **Connected AI Apps**. It lists
each app you connected by signing in, with when it was last used. Owners and admins see every
person's connected apps in the workspace, with who connected each one.

Tap **Disconnect** next to an app. It loses access to the workspace at once: its next request is
refused and it can't renew its sign-in. To use it again, connect it again from the app. Removing
Casama inside the app also ends its access.

An API key stops working as soon as it's revoked in **Connect AI Apps**, and leaving the workspace
cuts off every connection you made to it. Questions:
[support@casama.ai](mailto:support@casama.ai).

## Limits

- The local server needs Node.js 20 or later.
- OAuth connections and API keys don't count as a two-step sign-in. In a workspace that requires
  two-step sign-in for admins, they get member access only.
- The **Connect AI Apps** section is shown to owners and admins only.
- OAuth sign-in only accepts apps whose redirect address is `https` or `localhost`.

## Related

- [Connections](/guide/connections)
- [Autonomy, approvals and action rules](/guide/autonomy)
- [CLI](/develop/cli)
- [API](/develop/api)
- [Build with AI agents](/develop/agents)
- [Talk to outside agents (A2A)](/develop/a2a)
