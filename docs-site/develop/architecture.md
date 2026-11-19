# How Casama is built

This page is for people who want to read or change Casama's code. It maps the repository, follows
one chat message from the app to a computer and back, and shows where the security boundaries
are. To set up a development machine, see [Contribute to Casama](/develop/contributing).

## The pieces

A Casama server is a small set of services around one Postgres database:

| Service                   | What it does                                                                                    |
| ------------------------- | ----------------------------------------------------------------------------------------------- |
| **API**                   | The HTTP API under `/v1`, the live run stream, incoming webhooks, A2A and the hosted MCP server |
| **Worker**                | Runs bots: each run is a durable workflow that survives a crash or restart                      |
| **Supabase**              | Postgres, Auth, Realtime and Vault. Every table has row-level security                          |
| **Supervisor**            | Starts, stops and talks to computers. It is the only service with the Docker socket             |
| **Computers**             | One container per computer, with `computerd` inside                                             |
| **Egress proxy**          | Every computer's way to the internet. It blocks private addresses                               |
| **TURN relay**            | Carries the live view of a desktop computer                                                     |
| **Pages server**          | Serves pages bots make, from their own origin                                                   |

The API and the worker are one TypeScript codebase. `MODE=api` serves HTTP and `MODE=worker` runs
workflows. Node.js runs the TypeScript sources directly, so there's no build step.

The self-host compose file (`infra/compose/docker-compose.yml`) adds a few optional services:
`connector` for [remote access](/self-hosting/remote-access), `backup`, SearXNG for web search, a
PDF renderer, Caddy for HTTPS, the web app, and Prometheus and Grafana for monitoring.

## Repository map

| Folder                  | What's in it                                                                                                       |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `apps/server`           | The API (`src/api`, with the watch routes in `src/api/routes/watch.ts`) and the worker (`src/worker`), billing, Casama Link (`src/link`) and the pages server (`src/pages`) |
| `apps/supervisor`       | The supervisor's HTTP API and terminal proxy                                                                       |
| `packages/contracts`    | Every route and schema (Zod), including the watch's (`src/watch.ts`, `src/routes/watch.ts`). The OpenAPI document and the Dart client are generated from it |
| `packages/agent`        | The agent runtime: the run loop, context building, memory, tools, the model gateway and integrations; the watch's plain words and snapshots (`src/watch.ts`) |
| `packages/db`           | The Drizzle schema pulled from the migrations, the database client, `withUserSession`, and test helpers           |
| `packages/domain`       | Pure logic with no I/O: roles, approvals, budgets, limits, and which risks a watch may allow (`src/watch.ts`)     |
| `packages/sandbox`      | The computer provider interface, the Docker provider, the `computerd` client and object stores                    |
| `packages/mcp`          | `@casama/mcp`, the MCP server that lets coding tools drive your bots                                               |
| `packages/plugin-check` | `casama-plugin-check`, the plugin checker, also run as a GitHub Action                                              |
| `packages/evals`        | Agent evaluations and their tasks                                                                                  |
| `packages/observability`| Logging, OpenTelemetry and error reporting                                                                         |
| `client`                | The Flutter app for iOS, Android, macOS, Windows, Linux and the web                                                |
| `client/ios/CasamaWatch` | The Apple Watch app (SwiftUI, watchOS 26). `CasamaWatchWidgets` beside it holds its complications, Smart Stack widgets and controls; `Shared` holds what both use (API client, models, key store, words) |
| `client/wear`           | The Wear OS app: its own Gradle project, so phone builds never build it. Compose screens, tiles, complications, notifications |
| `client/lib/features/watch` | The phone's side of watches: the bridge that signs a watch in, and Settings → Watch                           |
| `dart/casama_api`       | The generated Dart REST client. Don't edit it by hand                                                              |
| `dart/casama_sdk`       | The [Dart SDK](/develop/sdk): sign-in, typed run events, live run watching                                         |
| `dart/cli`              | The [`casama` CLI](/develop/cli)                                                                                   |
| `dart/computerd`        | The agent inside each computer, and on your own machine in desktop companion mode                                 |
| `supabase`              | Migrations (the source of truth for the schema) and pgTAP tests in `supabase/tests`. Watch keys are in `20270207100001_watch_keys.sql` |
| `infra`                 | Compose files, computer images, the egress proxy, TURN, the remote access connector, backups, Helm, monitoring    |
| `ee`                    | Enterprise features under a separate license: audit log export and SAML single sign-on                            |
| `skills`                | The skills bundled with every server                                                                               |
| `gallery`               | The gallery site: themes, wallpapers, skills, apps, starter bots, routine ideas and plugins                       |
| `site`                  | The casama.ai website                                                                                              |
| `link-site`             | casama.link's own page: what a Casama Link address is, and how to report one (D-317)                              |
| `docs-site`             | These docs (VitePress)                                                                                             |
| `deploy`                | One-click deploy templates for hosting platforms                                                                   |
| `examples`              | A sample plugin and a sample SDK app                                                                               |
| `scripts`               | Development, test and packaging scripts. For the watch apps: `gen-watch-strings.mjs` (their words, from `app_en.arb`), `package-wear.sh`, `test-watch-swift.sh`, `test-wear-kotlin.sh` |
| `docs`                  | Project records: architecture notes and the decision log                                                          |

## One chat message, end to end

1. **The app sends it.** The app calls `POST /v1/conversations/{id}/messages`. Simple reads and
   edits go straight to Supabase under row-level security; anything that does work goes through
   the API.
2. **The API records it.** Inside the person's database session, the API saves the message,
   creates a queued run and enqueues an `agentRun` workflow, using the run id as the workflow id.
   It answers right away with the run id.
3. **The worker runs it.** A worker picks up the workflow. It checks the run is allowed (budget,
   quota, a model is set up), recalls memories and builds the context.
4. **The model answers.** Model calls go through the model gateway, which falls back to the next
   model on rate limits, server errors and timeouts. Every model call and tool call is its own
   durable step, so a crashed worker resumes at the last finished step instead of starting over.
5. **Tools touch a computer.** When a tool needs a computer (`shell.exec`, files, the browser), the
   worker asks the supervisor to start or wake the bot's computer, then sends the command to
   `computerd` inside it. Anything the computer fetches from the internet goes through the egress
   proxy.
6. **Approvals pause it.** If a tool call needs a person's approval, the run emits
   `approval.requested` and waits, durably, for as long as it takes.
7. **Events stream back.** Every step appends a numbered run event in one transaction. A database
   trigger broadcasts it on Supabase Realtime, which the app listens to, and on Postgres
   `NOTIFY`, which the API forwards to the server-sent events stream at `/v1/runs/{id}/events`
   that the CLI and SDK use. Clients that miss events catch up by sequence number.
8. **The run ends.** The worker saves the answer, extracts new memories, records usage and emits
   `run.completed`. A cancel request is noticed within half a second while streaming, or at the
   next step.

Routines, webhooks, chat apps, A2A calls and device triggers all start runs the same way: they
create a run and enqueue the same workflow.

## Data model essentials

The schema is in `supabase/migrations`. The tables you'll meet first:

- **`organizations`** (workspaces), **`memberships`** with a role (owner, admin, member), and
  **`profiles`**. Almost every other row carries an `org_id`.
- **`bots`**, with their instructions, model, autonomy level and default computer.
- **`conversations`** and **`messages`**: chats. A conversation can include more than one bot.
- **`runs`** and **`run_events`**: one run per piece of bot work, and its gap-free event log.
- **`computers`** and **`checkpoints`**: a bot's computer and its saved states.
- **`memories`**, **`skills`**, **`routines`**, **`tasks`**, **`approvals`**, **`integrations`**,
  **`secrets`** and **`model_credentials`**.
- **`creations`**: the Library, one row per thing a bot made (pages, images, files).
- **`usage_ledger`**: every model call and every second of computer time, with its cost.
- **`watch_keys`**: one row per signed-in watch (only the key's fingerprint), with **`watch_key_requests`**
  for sign-in codes and **`watch_prefs`** for what a person's watches may do.

Model keys and named secrets live in Supabase Vault. Tables hold only a reference to them.

## Security boundaries

- **Workspace isolation is enforced by Postgres.** The API runs each request inside
  `withUserSession`, which switches the transaction to the `authenticated` role with the caller's
  JWT claims. Row-level security policies, built on helpers like `is_member`, `has_role` and
  `can_access_bot`, decide what that person can see. A bug in a route can't read another
  workspace's rows.
- **The worker is not a superuser.** It connects as its own database role with explicit
  per-table policies and no way to bypass row-level security. New tables grant it access with
  `public.allow_worker`.
- **Secrets never reach the model.** Keys are written to Vault through the API and never returned.
  Tools write `{{secret:NAME}}`, and the worker swaps in the value only when the destination host
  is on that secret's allowlist. Every event, message and tool result passes through a redactor
  that knows the run's secrets.
- **Untrusted content is marked.** Web pages, files and tool output are wrapped as untrusted in the
  model's context, and outbound HTTP from tools refuses private, loopback and cloud metadata
  addresses after DNS resolution.
- **Computers are locked down.** Each computer runs as user 1000 with a read-only root filesystem,
  all Linux capabilities dropped, `no-new-privileges` and a process limit, on its own internal
  network. Its only way out is the egress proxy, with per-computer credentials. Only the
  supervisor holds the Docker socket.
- **Risky actions need a person.** The approval rules in `packages/domain` combine the bot's
  autonomy level, each tool's risk and standing "always allow" grants.
- **Bot pages get their own origin.** Pages bots publish are served from a separate address with a
  strict content security policy, so a page can't reach the app's session.
- **Content can be encrypted at rest** per workspace, with keys wrapped locally or by AWS KMS.

## Generated code

`packages/contracts` is the single source for the API. `pnpm gen` writes
`packages/contracts/openapi.json` (served as the [API reference](/api/)) and regenerates
`dart/casama_api` and the SDK's generated files. `pnpm --filter @casama/db pull` regenerates the
Drizzle schema from the database. CI fails if any generated file is out of date.

## Why things are the way they are

`docs/DECISIONS.md` in the repository records every design decision with its reasoning, numbered
`D-001` onward. `docs/ARCHITECTURE.md` is the detailed as-built map, with the files behind each
feature. Search both before changing something that looks deliberate.
