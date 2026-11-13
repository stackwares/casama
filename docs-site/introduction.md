# What is Casama

Casama gives you AI teammates, called bots, that keep working after you close the chat. Each bot has
its own instructions, memory, skills and a sandboxed Linux computer. It can research, write, code,
browse and run tasks on a schedule, and it asks before doing anything risky. You run Casama on your
own server with your own model keys, and reach your bots from apps on every platform, the terminal,
chat apps or your AI coding tools.

This page explains the main ideas. To try it, go to the [Quick start](/quick-start).

## The main ideas

### Workspaces

A **workspace** holds your bots, chats, connections and model keys. You can belong to several, such
as a personal one and one for your team. Everyone in a workspace has a role (owner, admin or member)
that decides what they can change. See [Workspaces and teams](/guide/workspaces).

### Bots

A **bot** is a teammate with:

- **Instructions**: who it is and how it works, written by you or started from a persona.
- **A model**: any model you have a key for, with fallbacks if one is unavailable.
- **Memory**: facts and preferences it saves as it works and recalls in later chats.
- **Skills**: reusable instructions for tasks it does often, loaded when they're relevant.
- **A computer**: its own sandboxed machine for files, code and the web.
- **Limits**: an autonomy level, budgets and the tools it may use.

See [Bots and models](/guide/bots).

### Chats and runs

You talk to a bot in a **chat**. Each time a bot works on something, from a message, a schedule or a
webhook, it starts a **run**. A run is a sequence of steps: the model thinks, calls tools, reads the
results and replies. Every step is recorded in the run's timeline, so you can see what the bot did,
what it cost and why. Runs survive restarts: if the server stops mid-run, the run continues from its
last finished step.

### Tools and risk

Bots act through **tools**: shell commands, files, the browser, memory, app connections, MCP servers
and more. Every tool has a risk level (low, medium or high). The bot's **autonomy** setting decides
which actions it does on its own and which wait for your **approval**. Approvals reach you in the app,
with a push notification. See [Autonomy and approvals](/guide/autonomy).

### Computers

Each bot works on a **computer**: an isolated Linux machine with a shell, files and a browser, and
optionally a full desktop. Computers sleep when idle and wake with everything intact. You can watch
one live, take control, and restore a checkpoint taken before a destructive command. You can also
lend your own machine through the desktop app. See [Computers](/guide/computers).

### Routines and triggers

A **routine** starts a run without you: on a schedule, when a webhook arrives, before a meeting, when
a message comes in, or when your phone says you've arrived somewhere. See
[Routines and triggers](/guide/routines).

### Connections

**Connections** let a bot use your other tools: built-in apps such as GitHub, Notion, Slack and
Google, any MCP server, plugins, chat apps, password managers and your devices. Secrets are stored
in a vault and are never shown to the model. See [Apps and connections](/guide/connections).

## Ways to run Casama

| Option | What it is |
| --- | --- |
| **Self-hosted** | The whole stack on your own server with one install script. No paywall and no limits. See [Self-hosting](/self-hosting/). |
| **Casama Cloud** | The hosted service, with plans and credits. Optional. |
| **Cloud Connect** | A self-hosted server that borrows Casama Cloud computers or model credits. See [Cloud Connect](/guide/cloud-connect). |

## Where you use it

- **Apps** for iOS, Android, macOS, Windows, Linux and the web.
- The **`casama` CLI** for the terminal and scripts. See [CLI](/develop/cli).
- **Chat apps** such as Telegram, Slack, WhatsApp, email and SMS. See [Chat apps](/guide/chat-apps).
- **AI apps and coding tools** over MCP. See [Connect AI apps](/guide/mcp).
- The **HTTP API** and the **Dart SDK** for your own software. See [HTTP API](/develop/api).

## How it fits together

```text
 Apps, CLI, chat apps, MCP clients
              │
              ▼
          API server ──── enqueues runs ────▶ Worker (runs the agent loop)
              │                                  │
              ▼                                  ▼
   Postgres (row-level security on        Sandbox supervisor ──▶ Bot computers
   every table) + Auth + Realtime                                 (via egress proxy)
```

- The **API** handles requests, checks who you are, and queues work.
- The **worker** runs bots: it calls models, runs tools and records every step. Runs are durable, so
  a crash resumes at the last finished step.
- **Postgres** stores everything, with row-level security on every table, so one workspace can never
  read another's data. Live updates reach the apps through Realtime.
- The **sandbox supervisor** starts and stops computers. It's the only part with access to Docker
  (or another computer provider). Computers reach the internet only through an egress proxy that
  blocks private and cloud-metadata addresses.

## Open source

Casama is licensed under Apache-2.0, except the `ee/` folder (enterprise features such as SAML
single sign-on and audit-log export), which is source-available under the Casama Enterprise License
and needs a license key in production. A self-hosted server sends no telemetry unless you turn it
on.
The code is on [GitHub](https://github.com/stackwares/casama), and contributions are welcome.

## Related

- [Quick start](/quick-start)
- [Self-hosting](/self-hosting/)
- [FAQ](/faq)
