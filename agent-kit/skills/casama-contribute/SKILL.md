---
name: casama-contribute
description: "Work on the Casama repository itself (stackwares/casama): run it locally, change contracts, migrations, server, Flutter app, Dart CLI/SDK or docs, and run the right tests before a PR. Use when editing apps/server, packages/*, supabase/, client/, dart/ or docs-site/ in a Casama clone."
---

# Contribute to the Casama repo

Monorepo, pnpm workspaces plus turbo. TypeScript runs directly on Node.js 24 (type stripping), so
the server has **no build step**. License AGPL-3.0 for the product, Apache-2.0 for the SDKs, CLI, MCP server, plugin kit, examples
and docs, and the Casama Enterprise License for `ee/` (`LICENSING.md`).

Full pages: https://docs.casama.ai/develop/contributing.md and
https://docs.casama.ai/develop/architecture.md (repo map, one message end to end, security
boundaries).

## Where things live

| Folder | What |
| --- | --- |
| `packages/contracts` | Every route and schema (Zod). Source of `openapi.json` and the Dart client |
| `apps/server` | API (`src/api`, `MODE=api`) and worker (`src/worker`, `MODE=worker`), billing, Casama Link (`src/link`), pages server (`src/pages`) |
| `apps/supervisor` | Starts/stops computers; the only service with the Docker socket |
| `packages/agent` | Agent runtime: run loop, context, memory, tools, model gateway, integrations |
| `packages/db` | Drizzle schema pulled from migrations, DB client, `withUserSession`, test helpers |
| `packages/domain` | Pure logic, no I/O: roles, approvals, budgets, limits, plugin and skill formats |
| `packages/sandbox` | Computer provider interface, Docker provider, `computerd` client, object stores |
| `packages/mcp` | `@casama/mcp`, the stdio MCP server for coding tools |
| `packages/plugin-check` | `casama-plugin-check` (also a GitHub Action) |
| `packages/evals`, `packages/observability` | Agent evals; logging, OpenTelemetry, error reporting |
| `supabase/migrations`, `supabase/tests` | Schema source of truth; pgTAP RLS tests |
| `client` | Flutter app (iOS, Android, macOS, Windows, Linux, web) |
| `dart/casama_api` | Generated Dart REST client: **never edit by hand** |
| `dart/casama_sdk`, `dart/cli`, `dart/computerd` | Dart SDK, `casama` CLI, agent inside each computer |
| `docs-site` | Public docs (VitePress): `guide/`, `self-hosting/`, `develop/` |
| `gallery`, `site`, `skills` | Gallery site and catalog, casama.ai site, skills bundled with every server |
| `infra`, `deploy`, `examples`, `scripts`, `ee` | Compose, images, egress, TURN; deploy templates; sample plugin and SDK app; scripts; enterprise |

## Run it locally

Needs Node.js 24+, pnpm 12, Docker, Supabase CLI, Dart 3, Flutter 3.50, PostgreSQL 17 with
pgvector and pgTAP (`brew install node pnpm supabase/tap/supabase postgresql@17 pgvector pgtap`;
on Ubuntu, `postgresql-17 postgresql-17-pgvector postgresql-17-pgtap` from the PostgreSQL apt repo).

```sh
pnpm install
supabase start                              # Postgres :54322, API :54321, Studio :54323
cp .env.example .env                        # DATABASE_URL, SUPABASE_URL, SUPABASE_ANON_KEY from `supabase status`
pnpm --filter @casama/server dev            # API on http://localhost:8787 (reference at /docs)
pnpm --filter @casama/server dev:worker     # worker, second terminal
docker compose -f infra/compose/docker-compose.dev.yml up --build   # computers (supervisor, egress, TURN)
```

`scripts/dev-up.sh` does all of it on a Mac (`--down` stops it). No model key: set
`CASAMA_MODEL_FIXTURES=apps/server/test/fixtures/chat.json` to replay recorded answers; the bot
still needs a key and a model, so add a made-up OpenRouter key in the app and choose any model.
Health: `curl http://localhost:8787/readyz`.

App: `cd client && flutter run -d macos --dart-define=CASAMA_API_URL=http://localhost:8787`.
CLI: `cd dart/cli && dart run bin/casama.dart config --api-url http://localhost:8787`.
Docs: `pnpm --filter @casama/docs dev` (http://localhost:5173).

## Rules for every change

1. **Contracts first.** Change routes and schemas in `packages/contracts`, run `pnpm gen`, then
   implement. No hand-written duplicate types; never edit generated Dart.
2. **Database only through migrations** in `supabase/migrations`. Enable RLS on every new table in
   the same migration, add pgTAP tests in `supabase/tests`, and grant the worker access with
   `public.allow_worker` if it needs the table. The worker is not a superuser and can't bypass RLS.
   A migration must work with the build before it (the old API keeps serving for a while during a
   deploy): add before you use, and drop a column or table only in a later deploy.
3. **Requests run in `withUserSession`** (the `authenticated` role with the caller's claims); RLS
   helpers such as `is_member`, `has_role`, `can_access_bot` decide visibility.
4. **No secrets** in code, logs, prompts, fixtures or test output. Secrets live in Vault; tools use
   `{{secret:NAME}}`.
5. **Tests with every change.** Fix the cause; never skip a failing test. No test calls a real
   model (fixtures replay); `scripts/live-check.sh` is the opt-in live check.
6. **App text** goes in `client/lib/l10n/app_en.arb`.
7. **New dependencies** at their latest compatible version, listed in `THIRD_PARTY_NOTICES.md`;
   upgrades in their own commit.
8. **Docs change with behavior** in `docs-site/`. Write for users: plain words, the app's exact
   labels in **bold**, real commands, no internal references.
9. **Format only what you touch:** `npx biome check --write <files>` on TypeScript you changed,
   `dart format <files>` only on Dart files you created (existing app code isn't at its width, so
   edit those by hand). Never reformat whole folders.
10. **Decisions:** search `docs/DECISIONS.md` (entries `D-001`...) before changing behavior that
    looks deliberate; add a short entry for a new choice the code doesn't explain.
    `docs/ARCHITECTURE.md` maps features to files.

## Checks (run what applies; CI runs all)

```sh
pnpm lint                              # Biome
pnpm typecheck                         # every package
pnpm test                              # unit and API tests, every package
pnpm --filter @casama/db test:pgtap    # RLS tests
pnpm gen && git diff --exit-code       # generated code up to date
(cd dart && dart pub get && dart analyze && dart test cli casama_sdk)
(cd client && flutter pub get && flutter gen-l10n && flutter analyze && flutter test)
pnpm --filter @casama/docs build       # fails on broken links
```

- Server/DB tests start a throwaway Postgres 17 from Homebrew's `postgresql@17` or
  `/usr/lib/postgresql/17/bin` (set `PG_BIN` otherwise, or `TEST_DATABASE_URL`). macOS:
  `LC_ALL=en_US.UTF-8` if Postgres won't start.
- Computer tests, `dart test computerd` and `scripts/e2e-cli.sh` need Docker and the computer
  images. The web release build is `scripts/build-web.sh`.
- `pnpm --filter @casama/db pull` regenerates the Drizzle schema from the database.

## Sending a change

1. Fork, branch from `main`, small focused commits with tests.
2. Sign off every commit (DCO): `git commit -s -m "Add bot budget checks"`, and sign the one-time
   CLA (`CLA.md`) by commenting on the first PR.
3. Open a PR with the template: what changed, why, how you tested it.
4. Big change: start a GitHub Discussion first. Security issue: follow `SECURITY.md`, not an issue.

## Checklist

- [ ] Contract changed first and `pnpm gen` output committed
- [ ] New table: migration with RLS, pgTAP test, `allow_worker` if the worker needs it
- [ ] Tests added; `pnpm lint`, `pnpm typecheck`, `pnpm test`, pgTAP pass
- [ ] Only touched files formatted; no secrets anywhere
- [ ] Docs page updated in `docs-site/` and docs build passes
- [ ] Commits signed off
