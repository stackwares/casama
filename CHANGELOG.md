# Changelog

All notable changes to Casama are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/). Until 1.0, minor versions may include breaking changes;
they're called out under **Changed**.

The server, apps, CLI, SDK and MCP server share one version number.

## [Unreleased]

The first public release. Highlights:

### Bots and chat

- Bots with instructions, a model policy with fallbacks, memory, skills, budgets and an autonomy
  level; personas and starter bots to start from; a welcome chat that sets up your first bot.
- Any model through your own keys (OpenAI, Anthropic, Google, xAI, OpenRouter, OpenAI-compatible
  endpoints including local models), or a ChatGPT plan. On Casama Cloud, a workspace with no key
  of its own runs on Casama's OpenRouter key and pays for those calls from credits.
- Chats with attachments, interactive cards, edit and resend, search, shortcuts and offline reading;
  group chats with several bots; pages.
- Memory with optional external backends; knowledge sources (files, websites, GitHub, connections);
  a catalog of 38 ready-made skills in seven categories (including PDF, Word, Excel and
  PowerPoint skills), GitHub import and self-improving skills. A Gallery in Settings for themes,
  color schemes, wallpapers and skills from `gallery.casama.ai`, with the bundled looks as the fallback.
- About you: one private profile every bot reads (what to call you, pronouns, how you like
  replies, about me, and facts bots learn in chat), shared into team workspaces only when you
  turn it on there.

### Voice

- Live voice calls run on Gemini Live when the workspace has a Google AI key (much cheaper per
  minute), with OpenAI Realtime as the fallback.
- Cheaper calls: a small voice tool set with bigger jobs handed to the chat, a capped context,
  silence left out of turns, idle calls hung up after 2 minutes, and the real per-call cost
  recorded in usage. Each bot can add chosen connected-app tools to its calls.
- A new call screen: the bot's mascot animated for the call (listening, and talking while it
  speaks), with live captions.
- Calls work without a key of your own on Casama Cloud (paid from credits) and on servers with a
  server-wide `GOOGLE_AI_API_KEY`; otherwise the call screen shows where to get a free key and where
  to add it.

### Computers

- A sandboxed Linux computer per bot (headless or desktop) that sleeps when idle, with checkpoints
  before destructive commands, live view, take control and team computers.
- Providers: Docker (with gVisor on Linux), E2B, Daytona and others; the desktop companion lends
  your own machine, with local MCP servers and desktop context.
- Coding agents, teach by showing, and step replay.

### Automation and connections

- Routines on schedules, webhooks, calendar events, messages and device events; watchers,
  check-ins, projects and a ticket board.
- Built-in app connections, Composio and Pipedream, MCP servers, plugins (Agent Plugins 1.0),
  password managers, paid data services, chat apps, voice calls, device connections and
  health summaries, payments with approval, linked agents and agent-to-agent (A2A).

### Control, teams and privacy

- Approvals, action rules, a loop guard, quiet hours and attention rules; usage and budgets.
- Workspaces with roles, invites and spaces; two-step sign-in; SAML single sign-on (enterprise).
- Sign in with Apple, Google, a passkey, an email link or code, or a password; new accounts confirm
  their email.
- Row-level security on every table, encryption at rest, data export, account deletion, retention
  settings, and telemetry off by default.
- Telemetry hygiene (D-206): official build isolation with `CASAMA_OFFICIAL_BUILD=1`, gitignored client telemetry configuration, super property tracking (`app`, `environment`, `platform`, `distribution`, `server_kind`), session-deduplicated screen tracking, and dynamic web telemetry loading.

### Self-hosting and developers

- `install.sh` for a full self-hosted stack, `casama selfhost` commands, encrypted backups, a Helm
  chart, deploy templates, monitoring and Cloud Connect.
- An HTTP API with an OpenAPI reference, the `casama` CLI, the Dart SDK, the Casama MCP server
  (local and hosted), bot templates, routines and skills as files with git sync, and a plugin
  checker.
