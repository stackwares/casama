# Contribute to Casama

Casama is open source, and bug reports, docs fixes, tests and features are all welcome. This page
gets a development machine running, shows how to run every test suite, and explains how to send a
change. For a map of the code, read [How Casama is built](/develop/architecture) first.

- Found a bug? [Open an issue](https://github.com/stackwares/casama/issues/new/choose) with steps to
  reproduce it.
- Planning a large change? Start a [discussion](https://github.com/stackwares/casama/discussions)
  first, so you agree on the approach before you write it.
- Found a security issue? Don't open an issue. Follow
  [SECURITY.md](https://github.com/stackwares/casama/blob/main/SECURITY.md).

## What you need

| Tool                                  | Version                          | Used for                                    |
| ------------------------------------- | -------------------------------- | ------------------------------------------- |
| Node.js                               | 24 or newer (see `.nvmrc`)       | The API, worker, supervisor and packages    |
| pnpm                                  | 12 (`packageManager` in `package.json`) | JavaScript dependencies              |
| Docker                                | recent                           | Supabase, computers, the self-host stack    |
| Supabase CLI                          | recent                           | Local Postgres, Auth, Realtime and Storage  |
| Dart                                  | 3 (stable)                       | The CLI, SDK and `computerd`                |
| Flutter                               | 3.50                             | The app                                     |
| PostgreSQL 17 with pgvector and pgTAP | 17                               | Tests start a throwaway database from it    |

On macOS:

```sh
brew install node pnpm supabase/tap/supabase postgresql@17 pgvector pgtap
```

Then install Docker Desktop and Flutter.

On Ubuntu (24.04 or newer) and Debian, Postgres 17 comes from the PostgreSQL project's apt
repository, since newer Ubuntu releases ship only 18:

```sh
sudo apt install postgresql-common docker.io docker-compose-v2 docker-buildx
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
sudo apt install postgresql-17 postgresql-17-pgvector postgresql-17-pgtap
sudo usermod -aG docker $USER     # then log out and back in
npm install -g pnpm@12            # or: corepack enable
```

Install the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started)
from its release page, and Flutter. For the Linux desktop app, also install its build packages
(the same list CI uses):

```sh
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev \
  libsecret-1-dev libjsoncpp-dev libcurl4-openssl-dev libx11-dev libxi-dev \
  libayatana-appindicator3-dev libpulse-dev
```

`libpulse-dev` is optional: without it, screen sharing from the Linux app has no system audio.

## Run the backend

Clone the repository, install dependencies and start Supabase:

```sh
git clone https://github.com/stackwares/casama.git
cd casama
pnpm install
supabase start          # Postgres on :54322, the Supabase API on :54321, Studio on :54323
cp .env.example .env
```

Fill in `.env` from the output of `supabase status`: the API needs at least `DATABASE_URL`,
`SUPABASE_URL` and `SUPABASE_ANON_KEY`. The comments in `.env.example` explain every setting.
The worker connects as its own least-privilege role, `casama_worker`, through
`WORKER_DATABASE_URL`; `.env.example` already points it at the password `supabase/seed.sql` gives
that role locally.

**Continue with Google** on your local stack needs a Google OAuth web client of your own:
put `GOOGLE_AUTH_CLIENT_ID` and `GOOGLE_AUTH_SECRET` in `.env` before `supabase start`, and add
`http://127.0.0.1:54321/auth/v1/callback` to the client's redirect URIs. Without them Google answers
"The OAuth client was not found". Email sign-in works without any of this; local emails land in
Mailpit at `http://localhost:54324`.

Start the API and the worker, each in its own terminal:

```sh
pnpm --filter @casama/server dev          # the API on http://localhost:8787
pnpm --filter @casama/server dev:worker   # the worker
```

Node.js runs the TypeScript directly, so there's no build step, and both restart when you save a
file. The API serves its reference at `http://localhost:8787/docs`, and
`curl http://localhost:8787/readyz` tells you it's up.

**No model key?** Set `CASAMA_MODEL_FIXTURES=apps/server/test/fixtures/chat.json` in `.env`, and
the worker replays recorded model answers instead of calling a provider. The bot still needs a key
and a model before it answers, so add a made-up OpenRouter key in the app (such as
`sk-or-v1-localfixturesonly`; it never reaches a provider) and choose any model. Without them every
message fails with "no model".

**Computers** need the supervisor, the egress proxy, the TURN relay and the computer images. Run
them next to Supabase:

```sh
docker compose -f infra/compose/docker-compose.dev.yml up --build
```

On macOS and Linux, `scripts/dev-up.sh` does all of this in one command: it starts Supabase
(and Docker Desktop on a Mac; on Linux, Docker must already be running), builds the computer images
on first run, starts the computer services, then runs the API and worker until you press Ctrl-C.
`scripts/dev-up.sh --down` stops Supabase and the computer services too.

## Run the app

```sh
cd client
flutter run -d macos --dart-define=CASAMA_API_URL=http://localhost:8787
```

Use `-d linux`, `-d chrome`, an iOS simulator or an Android emulator instead of `macos` if you
prefer. The app
gets the Supabase address and key from the API, so the API address is the only setting.

On a physical phone, `localhost` is the phone itself. Give the app an address that reaches your
computer instead: an https tunnel, `adb reverse tcp:8787 tcp:8787` for an Android phone on USB, or
your computer's LAN address (iOS blocks plain http unless you allow it). The `SUPABASE_URL` in your
`.env` must be reachable from the phone too, because the app signs in there.

### Map cards

Maps that bots draw in a chat load their tiles from one of four sources, tried in this order:
Google Map Tiles, MapTiler, HERE, then OpenStreetMap. A source without a key is skipped. When one
fails (refused, rate-limited, offline), every later map in that app session moves to the next.

Pass the keys when you build the app, with `--dart-define` or a file given to
`--dart-define-from-file`:

| Setting | Source |
| --- | --- |
| `CASAMA_GOOGLE_MAPS_KEY` | Google Map Tiles API |
| `CASAMA_MAPTILER_KEY` | MapTiler |
| `CASAMA_HERE_MAPS_KEY` | HERE |

With no keys, maps use OpenStreetMap's public tiles. Put a daily quota on a Google key so that
extra traffic gets a refusal, which falls through to the next source, and not a charge. HERE has
alerts but no hard spending cap, so leave its key empty unless you watch usage.

## Run the CLI

```sh
cd dart/cli
dart run bin/casama.dart config --api-url http://localhost:8787
dart run bin/casama.dart signup --email you@example.com
dart run bin/casama.dart org create "My team"
dart run bin/casama.dart org use my-team
dart run bin/casama.dart credential add --provider openrouter
dart run bin/casama.dart bot create Anna --credential <id>
dart run bin/casama.dart chat Anna "What can you do?"
```

See [CLI](/develop/cli) for every command.

## Run the docs

```sh
pnpm --filter @casama/docs dev      # http://localhost:5173
pnpm --filter @casama/docs build    # fails on broken links
```

## Run the tests

Run everything that applies to your change before you push. CI runs all of it on pull requests;
pushes to `main` don't run CI, so on `main` these local runs are the only check.

```sh
pnpm lint                              # Biome
pnpm typecheck                         # TypeScript, every package
pnpm test                              # unit and API tests, every package
pnpm --filter @casama/db test:pgtap    # row-level security tests in supabase/tests
pnpm gen && git diff --exit-code       # generated code is up to date
(cd dart && dart pub get && dart analyze && dart test cli casama_sdk)
(cd client && flutter pub get && flutter gen-l10n && flutter analyze && flutter test)
```

Some things to know:

- **Tests start their own Postgres.** Server and database tests start a throwaway cluster from
  your PostgreSQL 17 binaries and apply every migration. They look in Homebrew's
  `postgresql@17` folder and in `/usr/lib/postgresql/17/bin` (Debian and Ubuntu); set `PG_BIN` if
  yours is elsewhere, or set `TEST_DATABASE_URL` to use a database you already run. On macOS, set
  `LC_ALL=en_US.UTF-8` if Postgres refuses to start.
- **No test calls a real model.** Model calls replay recorded fixtures. `scripts/live-check.sh`
  runs the few live checks against a real model with your own key.
- **Computer tests need Docker.** The sandbox and computer tests, `dart test computerd`, and the
  CLI end-to-end run (`scripts/e2e-cli.sh`) need the computer images built.
- **The web build** in CI is `scripts/build-web.sh`.
- **Several runs on one machine?** Prefix full runs with `scripts/heavy.sh` (for example
  `scripts/heavy.sh pnpm test`). It runs one heavy command at a time, queues the others, and caps
  test workers, so parallel checkouts or agent sessions don't slow each other down.

## Rules for every change

1. **Contracts first.** Change routes and schemas in `packages/contracts`, run `pnpm gen`, then
   implement. Never hand-write duplicate types or edit the generated Dart client.
2. **Database changes only through migrations** in `supabase/migrations`. Turn on row-level
   security for every new table in the same migration, add pgTAP tests in `supabase/tests`, and
   grant the worker access with `public.allow_worker` if it needs the table. **A migration must
   work with the build before it:** during a deploy the old API keeps answering for a few seconds
   after migrations run, and keeps carrying calls for minutes. Add before you use, and drop a
   column or table in the deploy after the code stopped using it, never in the same one.
3. **No secrets** in code, logs, prompts, fixtures or test output.
4. **Tests with every change.** If a test fails, fix the cause; don't skip the test.
5. **Text in the app** goes in `client/lib/l10n/app_en.arb`.
6. **New dependencies** at their latest compatible version, listed in `THIRD_PARTY_NOTICES.md`.
   Put upgrades in their own commit.
7. **Docs change with the behavior** they describe. User docs live in `docs-site/`.
8. **Format only what you touch.** Run `npx biome check --write <files>` on TypeScript you changed
   and `dart format <files>` on Dart files you created. Existing app code isn't at `dart format`'s
   width, so edit existing Dart files by hand. Don't reformat whole folders.

## How decisions are recorded

`docs/DECISIONS.md` is the decision log. Each entry has a number (`D-001` onward), what was
decided and why. When your change makes a choice the code doesn't explain by itself, add a short
entry. Before you change a behavior that looks deliberate, search the log for it; there's usually
a reason, and the entry tells you what to weigh.

`docs/ARCHITECTURE.md` maps each feature to the files behind it. Update it when you add a feature
or move one.

## Send a change

1. Fork the repository and create a branch from `main`.
2. Make your change in small, focused commits, with tests.
3. Sign off every commit:

   ```sh
   git commit -s -m "Add bot budget checks"
   ```

   This adds a `Signed-off-by` line certifying the
   [Developer Certificate of Origin](https://developercertificate.org/): that you wrote the change
   or have the right to submit it.
4. Sign the one-time
   [Contributor License Agreement](https://github.com/stackwares/casama/blob/main/CLA.md) by
   commenting on your first pull request: "I have read the Casama CLA (CLA.md) and I agree to it."
5. Open a pull request and fill in the template: what changed, why, and how you tested it.

A maintainer reviews it, usually within a few days. Small pull requests get reviewed fastest.

## Licenses

The product (server, worker, agent, apps) is under AGPL-3.0. The SDKs, CLI, MCP server, plugin
kit, examples and these docs are under Apache-2.0, so what you build on Casama can use any license.
The `ee/` folder is under the Casama Enterprise License: you can read it and try it, and production
use needs a license key. Your contribution is published under the license of the folder you change,
and every contribution needs the one-time
[Contributor License Agreement](https://github.com/stackwares/casama/blob/main/CLA.md).
[LICENSING.md](https://github.com/stackwares/casama/blob/main/LICENSING.md) has the details.

Without `ee/`, Casama is fully open source and works on its own; CI tests that edition on every
change. Features someone running Casama for themselves or a small team would want go in the open
core; only features larger organisations need (SSO, audit export, advanced roles) go in `ee/`.
The [LICENSING.md](https://github.com/stackwares/casama/blob/main/LICENSING.md) file has the
details, and [TRADEMARKS.md](https://github.com/stackwares/casama/blob/main/TRADEMARKS.md) covers
the Casama name for forks.
