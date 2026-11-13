# Contributing to Casama

Thanks for helping. Bug reports, docs fixes, tests and features are all welcome. This guide covers
how to get set up, how the code is organized, the rules every change follows, and how to send it.

- Found a bug? [Open an issue](https://github.com/stackwares/casama/issues/new/choose) with steps to
  reproduce it.
- Have an idea? Start a [discussion](https://github.com/stackwares/casama/discussions) before writing
  a large change, so we can agree on the approach.
- Found a security issue? Don't open an issue; follow [SECURITY.md](SECURITY.md).

## Development setup

### Requirements

| Tool                                  | Version                                 | Used for                                   |
| ------------------------------------- | --------------------------------------- | ------------------------------------------ |
| Node.js                               | 24 or newer (`.nvmrc`)                  | API, worker, supervisor, packages          |
| pnpm                                  | 12 (`packageManager` in `package.json`) | JavaScript dependencies                    |
| Docker                                | recent                                  | Supabase, computers, the self-host stack   |
| Supabase CLI                          | recent                                  | Local Postgres, Auth, Realtime and Storage |
| Dart                                  | 3 (stable)                              | CLI, SDK, computerd                        |
| Flutter                               | 3.50 (Dart 3.14)                        | The app                                    |
| PostgreSQL 17 with pgvector and pgTAP | 17                                      | Server tests start a throwaway database    |

On macOS: `brew install node pnpm supabase/tap/supabase postgresql@17 pgvector pgtap`, plus
Docker Desktop and Flutter.

### Run the backend

`scripts/dev-up.sh` does all of this in one command: Docker, `supabase start`, the computer
services, then the API and worker until Ctrl-C (`--down` stops Supabase and the services too). The
steps it runs:

```sh
pnpm install
supabase start                      # Postgres :54322, API :54321, Studio :54323
cp .env.example .env                # fill in SUPABASE_ANON_KEY and friends from `supabase status`
pnpm --filter @casama/server dev    # the API on http://localhost:8787 (reference at /docs)
pnpm --filter @casama/server dev:worker   # the worker, in a second terminal
```

The server runs TypeScript directly on Node.js (type stripping), so there's no build step. Both
commands restart on changes.

**No model key?** Set `CASAMA_MODEL_FIXTURES=apps/server/test/fixtures/chat.json` in `.env` and the
worker replays recorded model responses.

**Computers** need the supervisor, egress proxy, TURN relay and computer images. Run them next to
`supabase start` with:

```sh
docker compose -f infra/compose/docker-compose.dev.yml up --build
```

### Run the app

```sh
cd client
flutter run -d macos --dart-define=CASAMA_API_URL=http://localhost:8787
```

Use `-d chrome`, an iOS simulator or an Android emulator instead of `macos` as you like. The app
reads the Supabase address and key from the API, so the API address is the only setting.

On a physical phone, `localhost` is the phone itself. Give it an address that reaches your machine:
an https tunnel (the maintainers' Mac is `https://api-dev.casama.ai` through a Cloudflare Tunnel,
D-172), `adb reverse tcp:8787 tcp:8787` for an Android phone on USB, or your LAN address (iOS blocks
plain http unless allowed). The API's `SUPABASE_URL` must be reachable from the phone too, since the
app signs in there.

### Run the CLI

```sh
cd dart/cli
dart run bin/casama.dart config --api-url http://localhost:8787
dart run bin/casama.dart signup --email you@example.com
dart run bin/casama.dart org create "My team" && dart run bin/casama.dart org use my-team
dart run bin/casama.dart credential add --provider openrouter
dart run bin/casama.dart bot create Ada --credential <id>
dart run bin/casama.dart chat Ada "What can you do?"
```

### Run the docs

```sh
pnpm --filter @casama/docs dev      # http://localhost:5173
```

## How the code is organized

[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) explains the system and where each feature lives.
In short:

- **`packages/contracts`** defines every route and schema. The OpenAPI document and the Dart client
  are generated from it.
- **`apps/server`** is the API (`MODE=api`) and the worker (`MODE=worker`), which runs bots as
  durable workflows.
- **`packages/agent`** is the agent runtime: the run loop, tools, the model gateway, memory and
  integrations.
- **`supabase/migrations`** is the database schema. Every table has row-level security.
- **`client`** is the Flutter app; **`dart/`** holds the CLI, the SDK and `computerd`, the agent
  inside each computer.

[`docs/DECISIONS.md`](docs/DECISIONS.md) records why things are the way they are. Search it before
changing a behavior that looks deliberate.

## Rules for every change

1. **Contracts first.** Change the schemas or routes in `packages/contracts`, run `pnpm gen`, then
   implement. Never hand-write duplicate types or Dart client code.
2. **Database changes only through migrations** in `supabase/migrations`, with row-level security
   enabled on every new table in the same migration, and pgTAP tests in `supabase/tests`.
3. **No secrets** in code, logs, prompts, fixtures or test output.
4. **Tests with every change.** Fix the cause of a failing test; don't skip it.
5. **User-facing text in the app** lives in `client/lib/l10n/app_en.arb`.
6. **New dependencies** at their latest compatible version, listed in `THIRD_PARTY_NOTICES.md`.
   Upgrades go in their own commit.
7. **Decisions** the spec doesn't cover get a short entry in `docs/DECISIONS.md`.
8. **Docs** change with the behavior they describe (see below).
9. **Format only what you touch.** `pnpm lint` checks TypeScript with Biome; run
   `npx biome check --write <files>` on your files, and `dart format <files>` for Dart. Don't
   reformat whole folders.

## Checks

Run what applies to your change before you push:

```sh
pnpm lint && pnpm typecheck && pnpm test          # TypeScript: lint, types, unit and API tests
pnpm --filter @casama/db test:pgtap                # row-level security tests
pnpm gen && git diff --exit-code                   # generated code is up to date
(cd dart && dart analyze && dart test cli casama_sdk computerd)
(cd client && flutter analyze && flutter test)     # the app
```

Server tests start a throwaway Postgres from your PostgreSQL 17 install (set `PG_BIN` if it isn't
Homebrew's), or use `TEST_DATABASE_URL`. On macOS, set `LC_ALL=en_US.UTF-8` or Postgres refuses to
start. Tests use recorded model fixtures; nothing calls a real model unless you run
`scripts/live-check.sh` with your own key.

CI runs all of these, plus Docker-based computer tests, a CLI end-to-end run and a Wasm web build
(`scripts/build-web.sh`). That script is the only release build of the web app.

## Documentation

The public docs are in [`docs-site/`](docs-site/) (VitePress):

- `guide/`: using Casama, one page per feature area.
- `self-hosting/`: installing and running a server.
- `develop/`: the API, CLI, SDK, plugins and file formats.

Write for someone using Casama, not for someone who built it: plain words, short sentences, the
app's exact labels in **bold**, real commands, and no internal references (decision numbers, file
paths of server internals). Check `pnpm --filter @casama/docs build` passes; it fails on broken
links. `docs/` holds project records for contributors: architecture, decisions, the audit and the
launch checklist.

## Sending a change

1. Fork the repository and create a branch from `main`.
2. Make your change in small, focused commits with tests.
3. Sign off every commit (see below).
4. Open a pull request and fill in the template: what changed and why, and how you tested it.

A maintainer reviews it, usually within a few days. Small pull requests get reviewed fastest.

### Developer Certificate of Origin

We use the [Developer Certificate of Origin](https://developercertificate.org/) instead of a CLA.
Sign off every commit:

```sh
git commit -s -m "Add bot budget checks"
```

This adds a `Signed-off-by: Your Name <you@example.com>` line, which certifies that you wrote the
change or have the right to submit it under the project license.

## License

By contributing, you agree that your contributions are licensed under Apache-2.0, or under the
Casama Enterprise License for changes inside `ee/`.
