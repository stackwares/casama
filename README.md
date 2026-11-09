# Kasama

**Persistent AI teammates you can self-host.** Each bot has its own chats, memory, routines and a sandboxed computer. You reach it from Kasama's own apps (web, iOS, Android, desktop) and the terminal, and it runs on your own model keys.

> Status: early development. Phases 0 to 3 (backend, bots and chat, computers, the Flutter app) are built. See [SPEC.md](SPEC.md) for the plan and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for what exists.

## Why Kasama

- **Self-hosted**: one command brings up the whole stack on your own server.
- **Any model**: OpenAI, Anthropic, Google, xAI, OpenRouter or any OpenAI-compatible endpoint, including local models via Ollama.
- **Your own computers**: every bot gets an isolated Linux computer that sleeps when idle.

## Repository layout

| Path                     | What it is                                                    |
| ------------------------ | ------------------------------------------------------------- |
| `apps/server`            | TypeScript API and worker (`MODE=api` / `MODE=worker`)        |
| `packages/contracts`     | Zod schemas, OpenAPI spec, run event schema (source of truth) |
| `packages/db`            | Drizzle schema and the RLS session helper                     |
| `packages/domain`        | Pure domain logic                                             |
| `packages/observability` | OpenTelemetry and Sentry setup                                |
| `dart/cli`               | `kasama` command-line client                                  |
| `dart/kasama_sdk`        | Generated Dart API client                                     |
| `supabase/`              | SQL migrations with row-level security, pgTAP tests           |
| `infra/compose`          | Docker Compose for local development and self-hosting         |

## Local development

Requirements: Node.js 24+, pnpm, Dart 3, the Supabase CLI and Docker.

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

Apache-2.0 for everything outside `ee/`. See [LICENSE](LICENSE).
