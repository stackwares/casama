# Kasama

**Persistent AI teammates you can self-host.** Each bot has its own chats, memory, routines and a sandboxed computer. You reach it from Kasama's own apps (web, iOS, Android, desktop) and the terminal, and it runs on your own model keys.

> Status: v1 feature-complete (Phases 0 to 8 built), public launch pending. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for what exists and [docs/LAUNCH_CHECKLIST.md](docs/LAUNCH_CHECKLIST.md) for the launch gate.

## Self-host in about 15 minutes

```sh
git clone https://github.com/stackwares/kasama && cd kasama
./install.sh --domain kasama.example.com    # or --local for a trial on this machine
```

Then open the app, choose **Use a different server**, and create the first account (the instance owner). Details: [docs/SELF_HOST.md](docs/SELF_HOST.md).

## Why Kasama

- **Self-hosted**: one command brings up the whole stack on your own server.
- **Any model**: OpenAI, Anthropic, Google, xAI, OpenRouter or any OpenAI-compatible endpoint, including local models via Ollama.
- **Real computers**: every bot gets an isolated Linux computer that sleeps when idle; watch it live and take control, or lend your own machine through the desktop app.
- **You stay in charge**: autonomy levels, approvals for risky steps, checkpoints, budgets and a full run timeline.
- **Everywhere**: apps for iOS, Android, macOS, Windows, Linux and web, a CLI, a Dart SDK and an MCP server for coding tools.
- **No paywall when self-hosted**; Kasama Cloud and Cloud Connect are optional.

## Repository layout

| Path                     | What it is                                                    |
| ------------------------ | ------------------------------------------------------------- |
| `apps/server`            | TypeScript API and worker (`MODE=api` / `MODE=worker`)        |
| `packages/contracts`     | Zod schemas, OpenAPI spec, run event schema (source of truth) |
| `packages/db`            | Drizzle schema and the RLS session helper                     |
| `packages/domain`        | Pure domain logic                                             |
| `packages/observability` | OpenTelemetry and error reporting                             |
| `packages/agent`         | Agent runtime, tools, model gateway                           |
| `packages/sandbox`       | Computer providers (Docker, E2B, Daytona, local, cloud)       |
| `packages/evals`         | Eval suite and baseline                                       |
| `packages/mcp`           | Kasama MCP server                                             |
| `apps/supervisor`        | Sandbox supervisor (the only service with Docker access)      |
| `client`                 | Flutter app                                                   |
| `ee`                     | Enterprise features (commercial license)                      |
| `docs-site`              | Documentation site (VitePress)                                |
| `deploy`                 | One-click deploy templates                                    |
| `dart/cli`               | `kasama` command-line client                                  |
| `dart/kasama_sdk`        | Generated Dart API client                                     |
| `supabase/`              | SQL migrations with row-level security, pgTAP tests           |
| `infra/compose`          | Docker Compose for local development and self-hosting         |
| `infra/monitoring`       | Prometheus, alert rules and Grafana dashboard                 |

## Local development

Requirements: Node.js 26+, pnpm, Dart 3, the Supabase CLI and Docker.

```sh
pnpm install
supabase start            # local Postgres, Auth, Realtime, Storage
cp .env.example .env      # fill in values printed by `supabase status`
pnpm dev                  # API on :8787, worker alongside
```

API reference: http://localhost:8787/docs

CLI:

```sh
cd dart/cli
dart run bin/kasama.dart signup --email you@example.com
dart run bin/kasama.dart login --email you@example.com
dart run bin/kasama.dart org create "My team"
dart run bin/kasama.dart org use my-team
dart run bin/kasama.dart credential add --provider openrouter --label Main      # prompts for the key
dart run bin/kasama.dart bot create Ada --credential <id>   # model defaults to openai/gpt-6-luna for OpenRouter keys
dart run bin/kasama.dart chat Ada "What can you do?"
```

Run the worker next to the API (`MODE=worker`). Without model keys, `KASAMA_MODEL_FIXTURES=apps/server/test/fixtures/chat.json` replays recorded responses.

## The app

```sh
cd client
flutter run -d macos --dart-define=KASAMA_API_URL=http://localhost:8787   # or chrome, an iOS simulator, an emulator
```

The app reads the Supabase URL and key from the API, so the API URL is the only setting.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Every commit needs a DCO sign-off (`git commit -s`).

## License

Apache-2.0 for everything outside `ee/`, which is under the [Kasama Enterprise License](ee/LICENSE) (source-available; production use needs a license key). See [LICENSE](LICENSE).

Telemetry is off by default; see [docs/SELF_HOST.md](docs/SELF_HOST.md#privacy) for the opt-in ping.
