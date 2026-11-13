<p align="center">
  <img src="client/assets/branding/casama_mascot_icon.png" width="96" alt="Casama">
</p>

<h1 align="center">Casama</h1>

<p align="center">
  <strong>AI teammates with their own computers, on your own server.</strong><br>
  Bots that remember, work on real computers, ask before risky steps, and run on any model.
</p>

<p align="center">
  <a href="docs-site/quick-start.md">Quick start</a> ·
  <a href="docs-site/introduction.md">What is Casama</a> ·
  <a href="docs-site/self-hosting/index.md">Self-hosting</a> ·
  <a href="docs-site/develop/api.md">Build on Casama</a> ·
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

---

Casama gives you bots that keep working after you close the chat. Each one has its own instructions,
memory, skills and a sandboxed Linux computer with a shell, files and a browser. Bots research,
write, code and run tasks on schedules and triggers, and they ask before doing anything risky. You
run the whole thing with one script, bring your own model keys, and reach your bots from apps on
every platform, the terminal, chat apps or your AI coding tools.

> **Status:** feature-complete and preparing for the first public release. Expect rough edges, and
> please [report them](https://github.com/stackwares/casama/issues).

## Features

- **Persistent bots**: instructions, memory, [skills](docs-site/guide/skills.md),
  [knowledge sources](docs-site/guide/memory.md) and budgets, with personas and templates to start
  from.
- **A real computer each**: an isolated Linux computer that sleeps when idle. Watch it live, take
  control, restore checkpoints, or lend your own machine through the desktop app.
  [Computers](docs-site/guide/computers.md)
- **Works while you're away**: schedules, webhooks, calendar, message and device triggers, watchers
  and check-ins. [Routines](docs-site/guide/routines.md)
- **You stay in charge**: autonomy levels, approvals, action rules, budgets, a loop guard and a full
  timeline of every run. [Autonomy](docs-site/guide/autonomy.md)
- **Any model**: OpenAI, Anthropic, Google, xAI, OpenRouter or any OpenAI-compatible endpoint
  (including local models), or sign in with a ChatGPT plan. [Bots and models](docs-site/guide/bots.md)
- **Connected to your tools**: built-in apps (GitHub, Notion, Linear, Slack, Google and more), MCP
  servers, plugins, password managers and device data, with secrets kept out of the model's sight.
  [Connections](docs-site/guide/connections.md)
- **Everywhere you are**: apps for iOS, Android, macOS, Windows, Linux and the web; chat apps such as
  Telegram, Slack, WhatsApp, email and SMS; voice calls; group chats with several bots.
- **Built to build on**: an HTTP API, a CLI, a Dart SDK, an MCP server for AI apps, plugins,
  bot templates and agent-to-agent (A2A). [Build on Casama](docs-site/develop/api.md)
- **Private by design**: row-level security on every table, encryption at rest, data export and
  deletion, and telemetry off unless you turn it on. [Privacy](docs-site/guide/privacy.md)

## Self-host in about 15 minutes

You need a machine with Docker.

```sh
git clone https://github.com/stackwares/casama && cd casama
./install.sh --local                          # a trial on this machine
./install.sh --domain casama.example.com      # or a server with a domain pointed at it
```

Then open the app, choose your server under **More options** on the sign-in screen, and create the
first account, which becomes the server's owner. The full guide covers requirements, configuration,
upgrades and backups: [Self-hosting](docs-site/self-hosting/index.md).

Self-hosting has no paywall and no limits. Casama Cloud, the hosted service, is optional, and
[Cloud Connect](docs-site/guide/cloud-connect.md) lets your own server borrow its computers or model
credits.

## Documentation

The documentation lives in [`docs-site/`](docs-site/) (a VitePress site; `pnpm --filter @casama/docs dev`
serves it locally).

|                       |                                                                                                                                                                                                                                                                                                 |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Get started**       | [What is Casama](docs-site/introduction.md) · [Quick start](docs-site/quick-start.md) · [FAQ](docs-site/faq.md)                                                                                                                                                                                 |
| **Guides**            | [Bots](docs-site/guide/bots.md) · [Chat](docs-site/guide/chat.md) · [Computers](docs-site/guide/computers.md) · [Routines](docs-site/guide/routines.md) · [Connections](docs-site/guide/connections.md) · [Autonomy](docs-site/guide/autonomy.md) · [Workspaces](docs-site/guide/workspaces.md) |
| **Self-hosting**      | [Install](docs-site/self-hosting/index.md) · [Configuration](docs-site/self-hosting/configuration.md) · [Operations](docs-site/self-hosting/operations.md) · [Troubleshooting](docs-site/self-hosting/troubleshooting.md)                                                                       |
| **Build on Casama**   | [HTTP API](docs-site/develop/api.md) · [CLI](docs-site/develop/cli.md) · [Dart SDK](docs-site/develop/sdk.md) · [Plugins](docs-site/develop/plugins.md) · [Webhooks](docs-site/develop/webhooks.md)                                                                                             |
| **Project internals** | [Architecture](docs/ARCHITECTURE.md) · [Decision log](docs/DECISIONS.md) · [Product spec](SPEC.md)                                                                                                                                                                                              |

## Repository layout

| Path                                             | What it is                                                                        |
| ------------------------------------------------ | --------------------------------------------------------------------------------- |
| `apps/server`                                    | TypeScript API and worker, one codebase (`MODE=api` or `MODE=worker`)             |
| `apps/supervisor`                                | Sandbox supervisor: the only service with access to Docker or a computer provider |
| `packages/contracts`                             | Zod schemas, routes and the OpenAPI document: the source of truth for the API     |
| `packages/agent`                                 | Agent runtime: the run loop, tools, model gateway, memory and integrations        |
| `packages/db`                                    | Drizzle schema and the row-level-security session helper                          |
| `packages/domain`                                | Pure domain logic with no I/O                                                     |
| `packages/sandbox`                               | Computer providers (Docker, E2B, Daytona and others)                              |
| `packages/mcp`                                   | The Casama MCP server for AI apps and coding tools                                |
| `packages/plugin-check`                          | Checks a plugin the way Casama does at install                                    |
| `packages/evals`, `packages/observability`       | Eval suite; OpenTelemetry and error reporting                                     |
| `client`                                         | The Flutter app (iOS, Android, macOS, Windows, Linux, web)                        |
| `dart/cli`, `dart/casama_sdk`, `dart/casama_api` | The `casama` CLI, the Dart SDK and the generated API client                       |
| `dart/computerd`                                 | The agent that runs inside every computer                                         |
| `supabase`                                       | SQL migrations with row-level security, and pgTAP tests                           |
| `infra`                                          | Docker Compose, computer images, egress proxy, TURN, Helm chart, monitoring       |
| `deploy`                                         | One-click deploy templates                                                        |
| `skills`, `examples`                             | The built-in skill catalog; an SDK sample app and an example plugin               |
| `docs-site`, `docs`                              | Public documentation; architecture, decisions and project records                 |
| `ee`                                             | Enterprise features under the Casama Enterprise License                           |

## Contributing

Contributions are welcome, from typo fixes to features. [CONTRIBUTING.md](CONTRIBUTING.md) explains
the development setup, the checks and how to send a change. Every commit needs a
[DCO](https://developercertificate.org/) sign-off (`git commit -s`). Please follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

- **Questions and ideas**: [GitHub Discussions](https://github.com/stackwares/casama/discussions)
- **Bugs and feature requests**: [GitHub Issues](https://github.com/stackwares/casama/issues)
- **Security issues**: please report privately, as described in [SECURITY.md](SECURITY.md)

## License

Apache-2.0 for everything outside `ee/`, which is source-available under the
[Casama Enterprise License](ee/LICENSE) and needs a license key in production. See
[LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
