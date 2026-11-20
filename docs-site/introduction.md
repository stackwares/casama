---
description: "What Casama is: open-source AI teammates (bots) with their own sandboxed Linux computers, memory and schedules, that ask before anything risky."
---

# What is Casama

Casama gives you AI teammates, called bots, that keep working after you close the chat. Each bot has
its own instructions, memory, skills and a sandboxed Linux computer. It can research, write, code,
browse and run tasks on a schedule, and it asks before doing anything risky. You run Casama on your
own server with your own model keys, and reach your bots from apps on every platform, the terminal,
chat apps or your AI coding tools.

This page explains the main ideas. To try it, go to the [Quick start](/quick-start).

<figure class="casama-shot"><img class="shot-light" src="/screens/hero-light.webp" alt="Casama on Mac and iPhone: Milo publishes Stardust Drift, a game he made, while his computer's live desktop plays it in the side panel"><img class="shot-dark" src="/screens/hero-dark.webp" alt=""></figure>

## The main ideas

### Workspaces

A **workspace** holds your bots, chats, connections and model keys. You can belong to several, such
as a personal one and one for your team. Everyone in a workspace has a role (owner, admin or member)
that decides what they can change. See [Workspaces and teams](/guide/workspaces).

### Bots

A **bot** is a teammate with:

- **Instructions**: who it is and how it works, written by you, started from a persona, or
  proposed by the bot itself in a short setup interview.
- **A model**: any model you have a key for (including a local model or a ChatGPT plan), with
  fallbacks if one is unavailable. On Casama Cloud, Casama picks the model.
- **Memory**: facts and preferences it saves as it works and recalls in later chats.
- **Skills**: reusable instructions for tasks it does often, loaded when they're relevant.
- **A computer**: its own sandboxed machine for files, code and the web.
- **Limits**: an autonomy level, budgets and the tools it may use.

See [Bots and models](/guide/bots).

### Chats and runs

You talk to a bot in a **chat**. Each bot has one main conversation with you, called **General**,
where quick questions, morning briefs, routine results and its suggestions land. Bigger pieces of
work get their own **topics**, which post a one-line result back to General when they finish. See
[Chatting with a bot](/guide/chat).

Each time a bot works on something, from a message, a schedule or a webhook, it starts a **run**. A run is a sequence of steps: the model thinks, calls tools, reads the
results and replies. Every step is recorded in the run's timeline, so you can see what the bot did,
what it cost and why. Runs survive restarts: if the server stops mid-run, the run continues from its
last finished step.

### Tools and risk

Bots act through **tools**: shell commands, files, the browser, memory, app connections, MCP servers
and more. Every tool has a risk level (low, medium or high). The bot's **autonomy** setting decides
which actions it does on its own and which wait for your **approval**. Approvals reach you in the app,
with a push notification, and in Slack as buttons in the thread. See
[Autonomy and approvals](/guide/autonomy).

### Computers

Each bot works on a **computer**: an isolated Linux machine with a shell, files and a browser, and
optionally a full desktop. Computers sleep when idle and wake with everything intact. You can watch
one live, take control, and restore a checkpoint taken before a destructive command. You can also
lend your own machine through the desktop app. See [Computers](/guide/computers).

### Routines and check-ins

A **routine** starts a run without you: on a schedule, when a webhook arrives, before or after a
meeting, when a message comes in, or when your phone says you've arrived somewhere. A routine can
stop on a date or after a number of runs.

**Check-ins** let a bot reach out first. It sends a morning brief, looks through your connected
mail and calendar during the day, and offers what it could do as suggestions with **Do It** and
**Not Now** buttons. Your first bot has them on, and non-urgent notifications wait out quiet hours (22:00 to
07:00 by default). See [Routines and triggers](/guide/routines) and
[Notifications and attention](/guide/attention).

### The Library and projects

Everything a bot hands you, such as sites and games, reports, documents, pictures, videos and
sounds, is kept in the **Library**, with versions, search and share links. A **project** keeps one
piece of work together: its chat, plan, to-dos and what was made for it. See
A site in the Library can go on the web at its own address, on Casama's sites domain or
your own. See [The Library](/guide/library), [Projects and tickets](/guide/projects) and
[Sites and domains](/guide/sites-and-domains).

### Away from the app

You don't need Casama's window in front of you to know what a bot is doing. A push tells you when a
reply is ready. A working bot shows in your Mac's notch and menu bar, and on your phone's Lock Screen
as a Live Activity or Android live notification, where you can stop it or answer a request. Casama
for Chrome brings your bots to the page you're on. See [Notifications and attention](/guide/attention),
[Bots in the notch and menu bar](/guide/notch), [Bots on the Lock Screen](/guide/lock-screen) and
[Casama for Chrome](/guide/chrome).

### Connections

**Connections** let a bot use your other tools: built-in apps such as GitHub, Notion, Slack and
Google, meeting notes apps, any MCP server, plugins, chat apps, password managers and your devices. Secrets are stored
in a vault and are never shown to the model. See [Apps and connections](/guide/connections).

## Ways to run Casama

| Option | What it is |
| --- | --- |
| **Self-hosted** | The whole stack on your own server with one install script. No paywall and no limits. See [Self-hosting](/self-hosting/). |
| **Casama Cloud** | The hosted service at [casama.ai](https://casama.ai). A free plan, then Plus ($15 a month), Pro ($49) and Max ($99), paid from credits. Optional. See [Usage, budgets and plans](/guide/usage). |
| **Casama Link** | Links a self-hosted server to a Casama Cloud account. Free: an address like `https://k7qm2xfd9abc.casama.link` that your phone can reach with no domain or open ports, sign-in by scanning a QR code, and notifications in the store apps. Billed: Casama Cloud's computers and model credits for your server. See [Use your server on your phone](/self-hosting/remote-access) and [Casama Link](/guide/casama-link). |

## Where you use it

- **Apps** for iOS, iPadOS, Android, macOS, Windows, Linux and the web.
- The **`casama` CLI** for the terminal and scripts. See [CLI](/develop/cli).
- **Chat apps**: Slack, Microsoft Teams, Discord, Telegram, WhatsApp, Messenger, Feishu, iMessage,
  email and SMS. Assign a bot a Linear or Jira issue and it works on it. See
  [Chat apps](/guide/chat-apps).
- **Voice**: live calls in the app, and phone calls. See [Voice and calls](/guide/voice).
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

For the full picture, see [How Casama is built](/develop/architecture).

## Open source

Casama is open source. The product (server, worker, agent and apps) is licensed under AGPL-3.0,
and the SDKs, CLI, MCP server, plugin kit, examples and these docs under Apache-2.0, so what you
build on Casama can use any license. The `ee/` folder (enterprise features such as SAML
single sign-on and audit-log export) is source-available under the Casama Enterprise License
and needs a license key in production. A self-hosted server sends no telemetry unless you turn it
on.
The code is on [GitHub](https://github.com/stackwares/casama), and contributions are welcome.

## Related

- [Quick start](/quick-start)
- [Self-hosting](/self-hosting/)
- [Contribute to Casama](/develop/contributing)
- [FAQ](/faq)
