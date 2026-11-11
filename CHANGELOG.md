# Changelog

All notable changes to Kasama are listed here. The format follows
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
  endpoints including local models), or a ChatGPT plan.
- Chats with attachments, interactive cards, edit and resend, search, shortcuts and offline reading;
  group chats with several bots; pages.
- Memory with optional external backends; knowledge sources (files, websites, GitHub, connections);
  a skill catalog, GitHub import and self-improving skills.

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
  password managers, paid data services, chat apps, voice and phone calls, device connections and
  health summaries, payments with approval, linked agents and agent-to-agent (A2A).

### Control, teams and privacy

- Approvals, action rules, a loop guard, quiet hours and attention rules; usage and budgets.
- Workspaces with roles, invites and spaces; two-step sign-in; SAML single sign-on (enterprise).
- Row-level security on every table, encryption at rest, data export, account deletion, retention
  settings, and telemetry off by default.

### Self-hosting and developers

- `install.sh` for a full self-hosted stack, `kasama selfhost` commands, encrypted backups, a Helm
  chart, deploy templates, monitoring and Cloud Connect.
- An HTTP API with an OpenAPI reference, the `kasama` CLI, the Dart SDK, the Kasama MCP server
  (local and hosted), bot templates, routines and skills as files with git sync, and a plugin
  checker.
