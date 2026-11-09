# Kasama — Full Build Spec

Nov 9, 2026 · @Oliver Martinez

## How to use this spec

This doc is the single source of truth for building Kasama: build every phase in the build plan, in order, and do not mark a phase done until its acceptance criteria pass. Export it as `SPEC.md` at the repo root so the coding agent can read it.

**Rules for the coding agent**

1. **Clean-room build.** Never open, copy, translate or paraphrase source code, docs or UI copy from Rakazo or any other existing agent platform. Build only from this spec and the public docs of the libraries named here.
2. **No third-party brand names** in product UI, code identifiers or package names. "Kasama" is a working name: keep it in one config constant so it can change.
3. **Contracts first.** The OpenAPI spec, the run event schema and the SQL migrations are the source of truth. Generate TypeScript types and the Dart client from them; never hand-write duplicates.
4. **Database changes only through Supabase CLI migrations,** with row-level security enabled on every table in the same migration.
5. **No secrets** in code, logs, prompts or test fixtures. Use environment variables and Supabase Vault.
6. **Small pull requests,** each with tests. Keep `docs/ARCHITECTURE.md` and `docs/DECISIONS.md` (an architecture decision log) current.
7. **When the spec is silent,** pick the simplest option that keeps the interfaces in this doc intact, and record it in `docs/DECISIONS.md`.
8. **Licenses:** record every third-party dependency in `THIRD_PARTY_NOTICES.md`.

**Definition of done for every task**

- Lint, typecheck, unit and integration tests pass in CI.
- New endpoints are in the OpenAPI spec, and the regenerated Dart client compiles.
- Every new table has row-level security policy tests.
- User-facing strings live in Flutter ARB files, never hard-coded.
- Errors report to Sentry, and key actions emit OpenTelemetry spans.

## Product overview

Kasama is an open-source, self-hostable platform for persistent AI teammates. Each bot has its own chats, memory, routines and a sandboxed computer, and users reach it from web, iOS, Android, desktop and messaging apps.

**Goals**

- Match the feature set of leading open-source agent platforms (persistent bots, computers, delegation, routines, voice, integrations), plus the upgrades in this spec.
- One Flutter codebase for web, iOS, Android, macOS, Windows and Linux.
- Serve 100 active users with 2 bots each on one app server and one sandbox server.
- Self-host with one command. Run the hosted version in a Singapore region for users in the Philippines.
- License the whole repo under Apache-2.0.

**Target users:** solo founders, small teams and power users who want bots that do real work (research, browsing, operations, outreach) using their own model keys.

**Non-goals for v1**

- Training or hosting our own models.
- GPU sandboxes.
- A paid plugin marketplace.
- Enterprise SSO/SAML (the schema allows it; build it later).

## Features and acceptance criteria

The full product is 36 features across 9 phases, built backend-first: Phases 0 to 3 are the MVP. Each row's acceptance criterion is the test that proves it works. Latency figures are targets, measured from Manila against the Singapore region.

| Area                    | Feature                                                                                              | Acceptance criterion                                                                           | Phase  |
| ----------------------- | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ------ |
| Workspaces              | Organizations, members, roles (owner, admin, member), email invites                                  | A member sees only their organization's data (RLS test)                                        | 0      |
| Auth                    | Email and password, magic link, Google, Apple                                                        | Auth works from the CLI in Phase 0; sign-in works on all 6 platforms in Phase 3                | 0, 3   |
| CLI                     | Dart `kasama` CLI: login, bots, chat, runs, computers                                                | A developer chats with a bot and watches its run from the terminal                             | 0 to 2 |
| Bots                    | Name, avatar, persona, model, autonomy level, budget                                                 | Settings persist; per-bot model override works                                                 | 1      |
| Chat                    | Streaming chat, attachments, markdown, cancel, retry                                                 | First token shows within 1.5 s of the model starting; cancel stops within 2 s                  | 1      |
| Memory                  | Facts, episode summaries, editable memory, hybrid search                                             | A fact told in chat A is recalled in chat B; the user can edit or delete it                    | 1      |
| Skills                  | Markdown instruction packs per organization or bot, loaded on demand                                 | The timeline shows a skill loaded only when relevant                                           | 1      |
| Model keys              | Bring-your-own keys in Vault, fallback chain                                                         | Keys are never returned by the API; a 429 or 5xx fails over to the next model                  | 1      |
| Usage ledger            | Every token, computer-second and voice character recorded                                            | The cost meter matches provider bills within 5%                                                | 1      |
| Computers               | Private and team computers; headless by default, desktop on demand                                   | Bot runs shell commands, edits files, browses; sleeps after 10 min idle and restores its state | 2      |
| Browser                 | agent-browser tool with element refs                                                                 | Bot completes a form task on a test site                                                       | 2      |
| Terminal and files      | Terminal and file access (CLI in Phase 2, app in Phase 3)                                            | User types in the terminal, uploads and downloads files                                        | 2, 3   |
| Undo                    | Checkpoints before risky actions, one-tap restore                                                    | Restoring a checkpoint reverts the files                                                       | 2      |
| MVP app                 | Flutter app: auth, bots, chat, timeline, computer screenshot view, terminal, files                   | 10 testers use it on Android, iOS and web for a week                                           | 3      |
| Routines                | Cron schedules in the user's timezone, plus event triggers                                           | A daily 08:00 Asia/Manila routine runs and pushes its result                                   | 4      |
| Approvals               | Policy-driven approval for risky tools                                                               | Sending an email waits for approval; deny cancels that step only                               | 4      |
| Delegation              | Subagents and peer bots with budgets and timeouts; shared task board                                 | A subagent stops at its budget; the parent receives its summary                                | 4      |
| Integrations            | Remote MCP servers, OpenAPI tools, optional Composio or Pipedream                                    | Adding an MCP server URL makes its tools appear and run                                        | 4      |
| Secrets                 | Named secrets used through `{{secret:NAME}}` placeholders                                            | Secret values never appear in model input, events or logs (test)                               | 4      |
| Notifications           | Push (FCM and APNs) plus an in-app inbox                                                             | An approval request reaches the phone within 5 s                                               | 4      |
| Templates               | Starter bots for common jobs                                                                         | A new user has a working bot from a template within 2 min                                      | 4      |
| Live view               | WebRTC stream of the bot's desktop                                                                   | Under 500 ms glass-to-glass on 4G                                                              | 5      |
| Take control            | Control lease, bot-initiated takeover requests, hand back                                            | Bot pauses while the user controls and resumes after hand-back                                 | 5      |
| Desktop control         | agent-desktop (accessibility tree) with screenshot fallback                                          | Bot operates a Linux desktop app                                                               | 5      |
| Providers               | Docker with gVisor, E2B, Daytona                                                                     | The same computer test suite passes on all three                                               | 5      |
| Channels                | Bot email inbox, SMS, Telegram, Slack, WhatsApp, Messenger                                           | A Telegram message gets a reply in the same chat; unknown senders are ignored                  | 6      |
| Voice                   | Dictation, text-to-speech (BYO ElevenLabs, OpenAI, Cartesia, Fish Audio), live calls                 | Live-call reply starts within 1 s                                                              | 6      |
| Local computer          | Flutter desktop companion runs tools on the user's own machine                                       | Bot opens an app on the user's Mac behind a visible consent overlay                            | 6      |
| Flutter extras          | Home-screen widgets, iOS Live Activities, share to bot, desktop hotkey and tray, owner admin console | Each works on its platforms in the release build                                               | 6      |
| Dart SDK                | `kasama_sdk` on pub.dev with typed events                                                            | An external sample app streams a run using only the published SDK                              | 6      |
| Plans and subscriptions | Dodo Payments on web and desktop; App Store and Google Play subscriptions on mobile                  | A purchase on any platform unlocks every platform; cancels and refunds remove access           | 7      |
| Credits and quotas      | Prepaid and metered credits; plan limits drive quotas                                                | A run stops cleanly when credits or quota run out                                              | 7      |
| Cloud Connect           | Self-hosted instances use cloud computers and credits through an API key                             | A self-hosted bot runs on a cloud computer and the usage shows on the cloud bill               | 7      |
| Privacy                 | Data export and account deletion                                                                     | Export downloads a ZIP; deletion purges data within 30 days                                    | 8      |
| Languages               | English and Filipino at launch, more via ARB files                                                   | Language switch in settings changes every screen                                               | 8      |
| Self-host and launch    | One-command installer, one-click deploy templates, docs site, public launch                          | Fresh VPS to working app in under 15 min                                                       | 8      |

## System architecture

The Flutter app reads data straight from Supabase under row-level security and sends every command to one TypeScript server, which runs as an API process and a worker process; a separate supervisor owns all bot computers.

&#91;embedded content: system architecture · 11 components\]

Reads go straight to Supabase; every command, run and tool call flows from API to worker to supervisor, and live video reaches the app through coturn.

**Components**

- **Flutter app** (web, iOS, Android, macOS, Windows, Linux): reads and simple edits through `supabase_flutter`; commands through the generated API client; live events through Supabase Realtime.
- **Supabase:** Auth, Postgres (with pgvector), Realtime, Storage, Vault. Self-hostable.
- **API process** (Hono): validates the Supabase JWT, accepts commands, starts workflows, mints short-lived stream tokens, receives webhooks.
- **Worker process** (DBOS on the same Postgres): agent runs as durable workflows, routines, memory jobs, channel replies, usage accounting. Hosts the model gateway and tool registry.
- **Sandbox supervisor:** the only service with Docker access. Creates, sleeps, restores and checkpoints computers, and runs the egress proxy. Talks to `computerd`, a small daemon inside each computer.
- **Remote providers:** E2B and Daytona adapters behind the same sandbox interface.
- **Streaming:** each desktop computer runs a WebRTC streamer; media relays through coturn; signaling goes through the API.
- **Object storage** (S3-compatible: Supabase Storage or Cloudflare R2): computer snapshots, checkpoints, attachments.
- **External services:** model providers, FCM, Resend, Twilio, Telegram, Slack, Meta (WhatsApp, Messenger), Sentry, Langfuse, PostHog.
- **Local computer companion:** the Flutter desktop app connects to the API over WebSocket and runs tools on the user's machine.

**Request path for one chat message**

1. The app calls `POST /v1/conversations/{id}/messages`.
2. The API stores the message, creates a `runs` row and starts the `agentRun` workflow.
3. The worker builds context, calls the model and streams events.
4. Tool calls go to the supervisor (computers), MCP servers or channel adapters.
5. Every step is appended to `run_events` and broadcast on Realtime; the app renders it live.

## Tech stack

The backend is TypeScript on Node.js 24 LTS with Supabase as the platform; the client is Flutter. Every choice below is final for v1 unless a decision record replaces it.

| Layer                        | Choice                                                                       | Why                                                                         |
| ---------------------------- | ---------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Client                       | Flutter (stable channel), Dart 3                                             | One codebase for 6 platforms                                                |
| Client state and routing     | Riverpod with code generation, go\_router, freezed                           | Testable, typed, widely documented                                          |
| Backend language             | TypeScript, Node.js 24 LTS                                                   | Most mature LLM and MCP libraries                                           |
| API framework                | Hono with `@hono/zod-openapi`                                                | Routes defined once; OpenAPI generated for the Dart client                  |
| Platform                     | Supabase: Auth, Postgres, pgvector, Realtime, Storage, Vault                 | Replaces auth, realtime and storage plumbing; self-hostable                 |
| Database access              | Drizzle ORM, schema pulled from the SQL migrations                           | Typed SQL; easy to run queries under RLS                                    |
| Durable workflows and queues | DBOS Transact (TypeScript) on the same Postgres                              | Crash-safe agent runs, scheduled workflows, queues; no extra infrastructure |
| LLM layer                    | Vercel AI SDK (`ai`) behind our own `ModelGateway` interface                 | Multi-provider streaming and tool calling; swappable later                  |
| MCP                          | Official `@modelcontextprotocol/sdk` client                                  | Standard tool integration                                                   |
| Validation                   | Zod, shared through `packages/contracts`                                     | One schema for API, events and tools                                        |
| Computers                    | Docker with gVisor (`runsc`); E2B and Daytona adapters                       | Cheap self-run isolation; managed overflow                                  |
| Browser tool                 | agent-browser (Vercel Labs, Apache-2.0)                                      | Accessibility-tree refs, low token use                                      |
| Desktop tool                 | agent-desktop (Vercel Labs, Apache-2.0), screenshot and xdotool fallback     | Structured control where apps support it                                    |
| Live view                    | WebRTC streamer in the computer image, coturn, `flutter_webrtc`              | Low latency on mobile networks                                              |
| Push                         | Firebase Cloud Messaging (APNs through FCM)                                  | One API for iOS and Android                                                 |
| Email and SMS                | Resend (email in and out), Twilio (SMS)                                      | Behind a `ChannelAdapter` interface                                         |
| Observability                | OpenTelemetry, Sentry, Langfuse (self-hostable), PostHog                     | Errors, traces, LLM traces, product analytics and flags                     |
| Monorepo tooling             | pnpm workspaces, Turborepo, Biome, Vitest, Testcontainers                    | Fast builds and one lint and format tool                                    |
| CI/CD                        | GitHub Actions, GitHub Container Registry, Shorebird for Flutter OTA patches | Automated tests, images and app updates                                     |

**Key decisions**

- **Reads through Supabase, commands through the API.** The app reads tables directly under RLS. Anything that touches secrets, runs, computers, money or external services goes through the API.
- **DBOS over a plain job queue.** Agent runs survive crashes and deploys by resuming at the last completed step.
- **One server codebase, two modes.** `MODE=api` and `MODE=worker` start from the same image, which keeps shared code simple.
- **Interfaces at every vendor edge:** `ModelGateway`, `SandboxProvider`, `ChannelAdapter`, `ObjectStore`, `EventBus`. No vendor SDK is imported outside its adapter.

## Repository layout

One monorepo holds the server, supervisor, sandbox daemon, Flutter client, database migrations and infrastructure.

```
kasama/
  apps/
    server/              # one TypeScript codebase, MODE=api or MODE=worker
      src/api/           # Hono routes (OpenAPI), webhooks, WebSocket endpoints
      src/worker/        # DBOS workflows: agentRun, routines, memory, channels, usage, billing
      src/main.ts
    supervisor/          # sandbox supervisor; the only service with Docker access
    www/                 # static marketing site and public docs
  dart/
    cli/                 # kasama CLI, compiled per OS with dart compile exe
    computerd/           # daemon inside each computer: exec, files, input, screenshots, health
    kasama_sdk/          # generated API client + typed run events (published to pub.dev)
  packages/
    contracts/           # OpenAPI spec, Zod schemas, run event schema, tool schemas
    domain/              # pure logic: policies, budgets, autonomy, context builder, entitlements
    db/                  # Drizzle schema (pulled from migrations), query helpers, RLS session helper
    agent/               # agent loop, tool registry, ModelGateway, memory service
    sandbox/             # SandboxProvider interface + docker, e2b, daytona, local, kasama-cloud adapters
    channels/            # ChannelAdapter interface + email, sms, telegram, slack, whatsapp, messenger
    billing/             # BillingProvider interface + dodo, app_store, google_play adapters (Phase 7)
    observability/       # OpenTelemetry, Sentry, Langfuse setup
    evals/               # eval tasks, runner, scoring
  client/                # Flutter app for all platforms (uses dart/kasama_sdk)
    lib/core/            # sdk wiring, supabase, theme, l10n, routing, event stream
    lib/features/        # auth, workspaces, bots, chat, computer, approvals, routines, memory,
                         # skills, integrations, channels, voice, usage, billing, settings,
                         # companion, admin, widgets
  ee/                    # commercial-license features: SSO, advanced roles, audit export, Cloud Connect server
  supabase/
    migrations/          # SQL migrations with RLS policies (source of truth)
    tests/               # pgTAP tests for RLS
    functions/           # Edge Functions: push fan-out only
    seed.sql
  infra/
    images/computer/     # computer images: headless and desktop
    compose/             # Docker Compose for self-hosting + install script
    deploy/              # one-click templates: Railway, Render, Coolify
    coturn/  egress-proxy/
  docs/                  # ARCHITECTURE.md, DECISIONS.md, SELF_HOST.md, SECURITY.md, GOVERNANCE.md
  LICENSE                # Apache-2.0 (everything outside ee/)
  .github/workflows/
```

## Data model and row-level security

Every tenant table carries `org_id`, has RLS enabled, and is created by a SQL migration; organizations and teams exist from day one. All ids are UUIDs and every table has `created_at`.

| Table              | Key columns                                                                                                                                                           | Notes                                                                                       |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| organizations      | name, slug, plan, region                                                                                                                                              | One per workspace                                                                           |
| memberships        | org\_id, user\_id, role (owner, admin, member)                                                                                                                        | Drives every RLS policy                                                                     |
| profiles           | user\_id, display\_name, avatar\_url, locale, timezone                                                                                                                | Timezone used for routines                                                                  |
| invites            | org\_id, email, role, token\_hash, expires\_at                                                                                                                        | Token stored hashed                                                                         |
| bots               | name, avatar\_url, persona\_md, model\_policy jsonb, autonomy, visibility (private, team), default\_computer\_id, budget jsonb, status                                | model\_policy = primary, fallbacks, cheap model                                             |
| conversations      | bot\_id, channel\_id, external\_thread\_id, title, summary, last\_message\_at                                                                                         | One per chat or external thread                                                             |
| messages           | conversation\_id, role, author\_user\_id, content jsonb (parts), run\_id                                                                                              | Final messages only; token deltas live in run\_events                                       |
| attachments        | message\_id, storage\_path, mime, size                                                                                                                                | Files in object storage                                                                     |
| runs               | bot\_id, conversation\_id, parent\_run\_id, trigger, status, budget jsonb, tokens\_in, tokens\_out, cost\_usd, started\_at, ended\_at, error                          | Status: queued, running, waiting\_approval, waiting\_takeover, completed, failed, cancelled |
| run\_events        | run\_id, seq, type, payload jsonb                                                                                                                                     | Primary key (run\_id, seq); append-only                                                     |
| memories           | bot\_id, kind (fact, episode, summary, preference), content, embedding vector, tsv tsvector, importance, pinned, source\_run\_id                                      | Hybrid search                                                                               |
| skills             | bot\_id (null = whole org), name, description, body\_md, enabled                                                                                                      | Loaded on demand                                                                            |
| routines           | bot\_id, name, instructions\_md, schedule\_cron, timezone, trigger jsonb, enabled, next\_run\_at, last\_run\_id                                                       | Schedule or event trigger                                                                   |
| computers          | kind (private, team, local), owner\_bot\_id, provider, provider\_ref, profile (headless, desktop), state, size jsonb, image\_version, last\_active\_at, snapshot\_ref | One team computer per org by default                                                        |
| computer\_leases   | computer\_id, holder\_type (bot, user), holder\_id, mode (view, control), expires\_at                                                                                 | Take-control state                                                                          |
| checkpoints        | computer\_id, run\_id, label, storage\_ref                                                                                                                            | Undo points                                                                                 |
| model\_credentials | provider, label, base\_url, vault\_secret\_id                                                                                                                         | Key lives only in Vault                                                                     |
| secrets            | name, vault\_secret\_id, allowed\_bot\_ids, allowed\_hosts                                                                                                            | Placeholder secrets with a host allowlist                                                   |
| integrations       | kind (mcp, openapi, composio, pipedream), name, config jsonb, vault\_secret\_id, status                                                                               | Org-level                                                                                   |
| bot\_integrations  | bot\_id, integration\_id, tool\_allowlist                                                                                                                             | Which bot may use which tools                                                               |
| approvals          | run\_id, tool\_name, args\_redacted jsonb, risk, status, decided\_by, decided\_at, expires\_at                                                                        | Status: pending, approved, denied, expired                                                  |
| channels           | bot\_id, kind, address, config jsonb, vault\_secret\_id, allowed\_senders                                                                                             | Email, SMS, Telegram, Slack, WhatsApp, Messenger                                            |
| tasks              | created\_by\_bot\_id, assignee\_bot\_id, title, status, parent\_run\_id, result\_md                                                                                   | Shared task board for multi-bot work                                                        |
| devices            | user\_id, platform, fcm\_token, last\_seen\_at                                                                                                                        | Push targets                                                                                |
| notifications      | user\_id, kind, payload jsonb, read\_at                                                                                                                               | In-app inbox                                                                                |
| local\_devices     | user\_id, name, os, capabilities jsonb, token\_hash, last\_seen\_at                                                                                                   | Companion computers                                                                         |
| usage\_ledger      | bot\_id, run\_id, kind, quantity, cost\_usd                                                                                                                           | Kinds: tokens\_in, tokens\_out, computer\_seconds, stream\_seconds, tts\_chars              |
| quotas             | period, max\_cost\_usd, max\_computer\_hours, max\_concurrent\_computers                                                                                              | Checked before and during runs                                                              |
| audit\_log         | actor\_type (user, bot, system), actor\_id, action, target\_type, target\_id, metadata jsonb                                                                          | Append-only                                                                                 |

**RLS rules**

- Helper functions `is_member(org_id)` and `has_role(org_id, role)` back every policy. Private bots and computers are also limited to their creator.
- **Client path:** `supabase_flutter` sends the user's JWT, so RLS applies automatically.
- **Server path:** each request runs its queries in a transaction that sets `role authenticated` and `request.jwt.claims` from the verified JWT, so the server obeys the same policies. A Drizzle helper `withUserSession(claims, fn)` does this.
- **System jobs** (routines, channel webhooks) use a dedicated database role scoped by explicit `org_id`. Only the worker can read `vault.decrypted_secrets`.
- `run_events`, `audit_log` and `usage_ledger` allow insert and select only; no update or delete policies.
- `supabase/tests` holds pgTAP tests proving a member of org A can never read org B's rows.

**Indexes and storage:** `run_events (run_id, seq)`; `messages (conversation_id, created_at)`; `memories` with an HNSW index on `embedding` and a GIN index on `tsv`; `routines (enabled, next_run_at)`. The embedding dimension is set by the chosen embedding model (default 1536); changing models runs a re-embed job.

## Run event protocol

Every step of every run is an append-only event in `run_events`; that one log drives the live UI, the activity timeline, the audit trail, crash recovery and evals. Build this before any UI.

**Envelope**

```json
{
  "v": 1,
  "run_id": "uuid",
  "seq": 42,
  "type": "tool.completed",
  "ts": "2026-11-09T09:30:00.000Z",
  "bot_id": "uuid",
  "payload": {}
}
```

`seq` increases by 1 per run with no gaps. Each payload is a Zod schema in `packages/contracts`, also published as OpenAPI components so the Dart client gets typed `freezed` classes.

| Type               | Payload                                                            |
| ------------------ | ------------------------------------------------------------------ |
| run.started        | trigger, model, computer\_id                                       |
| message.delta      | message\_id, text (coalesced: at most 5 writes per second per run) |
| message.completed  | message\_id, content parts                                         |
| tool.started       | call\_id, tool, args\_redacted                                     |
| tool.output        | call\_id, chunk (streaming shell output)                           |
| tool.completed     | call\_id, result\_preview, artifact\_path, duration\_ms            |
| tool.failed        | call\_id, error\_code, message                                     |
| approval.requested | approval\_id, tool, args\_redacted, risk, expires\_at              |
| approval.resolved  | approval\_id, decision, decided\_by                                |
| takeover.requested | computer\_id, reason                                               |
| lease.changed      | computer\_id, holder\_type, mode                                   |
| computer.state     | computer\_id, state                                                |
| checkpoint.created | checkpoint\_id, label                                              |
| subrun.started     | child\_run\_id, bot\_id, task                                      |
| subrun.completed   | child\_run\_id, status, summary                                    |
| memory.written     | memory\_id, kind                                                   |
| skill.loaded       | skill\_id, name                                                    |
| usage              | tokens\_in, tokens\_out, cost\_usd (running totals)                |
| run.completed      | final\_message\_id                                                 |
| run.failed         | error\_code, message                                               |
| run.cancelled      | cancelled\_by                                                      |

**Delivery**

- The worker writes each event to Postgres first, then broadcasts it on Realtime channels `run:{run_id}` and `bot:{bot_id}`.
- The app subscribes to Realtime and drops duplicates by `seq`.
- On reconnect or app open, the app calls `GET /v1/runs/{id}/events?after_seq=N` to fill gaps, then resumes live.
- Secrets are redacted before an event is written; a unit test scans every event type for known secret values.
- Unknown event types are ignored by older clients, so new types never break shipped apps.

## API surface

The API is versioned under `/v1`, described entirely in OpenAPI, and authenticated with the Supabase JWT as a Bearer token. Simple reads and edits (listing bots, renaming a conversation, editing a memory) go straight to Supabase from the app; everything below goes through the API.

| Method   | Path                                         | Purpose                                                 |
| -------- | -------------------------------------------- | ------------------------------------------------------- |
| POST     | /v1/orgs                                     | Create an organization and its team computer record     |
| POST     | /v1/orgs/{id}/invites                        | Invite by email                                         |
| POST     | /v1/invites/{token}/accept                   | Join an organization                                    |
| POST     | /v1/bots                                     | Create a bot (optionally from a template)               |
| POST     | /v1/conversations/{id}/messages              | Send a message; returns run\_id                         |
| GET      | /v1/runs/{id}/events?after\_seq=             | Fetch missed events (JSON or SSE)                       |
| POST     | /v1/runs/{id}/cancel                         | Cancel a run and its subruns                            |
| POST     | /v1/approvals/{id}/decision                  | Approve or deny                                         |
| POST     | /v1/computers/{id}/start, /stop, /restart    | Lifecycle commands                                      |
| POST     | /v1/computers/{id}/stream-session            | Short-lived WebRTC signaling token and TURN credentials |
| POST     | /v1/computers/{id}/lease                     | Take control (mode: control)                            |
| DELETE   | /v1/computers/{id}/lease                     | Hand control back to the bot                            |
| GET      | /v1/computers/{id}/terminal                  | WebSocket terminal session                              |
| GET, PUT | /v1/computers/{id}/files?path=               | List, download, upload files                            |
| POST     | /v1/computers/{id}/checkpoints/{cid}/restore | Undo to a checkpoint                                    |
| POST     | /v1/credentials                              | Store a model key in Vault; returns metadata only       |
| POST     | /v1/credentials/{id}/test                    | Validate a key with a 1-token call                      |
| POST     | /v1/secrets                                  | Create a named secret with allowed hosts                |
| POST     | /v1/integrations                             | Add an MCP server or OpenAPI tool source                |
| POST     | /v1/integrations/{id}/test                   | List tools to prove the connection works                |
| POST     | /v1/channels                                 | Connect a channel; returns webhook URL or address       |
| POST     | /v1/routines/{id}/run                        | Run a routine now                                       |
| POST     | /v1/voice/session                            | Mint an ephemeral token for a live call                 |
| GET      | /v1/usage?period=                            | Usage and cost by bot                                   |
| POST     | /v1/account/export, DELETE /v1/account       | Privacy tools                                           |
| GET      | /v1/local-computer/connect                   | WebSocket for the desktop companion (device token)      |
| GET      | /healthz, /readyz                            | Health checks                                           |

**Webhooks** (signature-verified, no JWT): `/hooks/email`, `/hooks/twilio`, `/hooks/telegram/{channel_id}`, `/hooks/slack`, `/hooks/meta` (WhatsApp and Messenger), `/hooks/github/{routine_id}`, `/hooks/custom/{routine_id}` (HMAC).

**Conventions:** errors use RFC 9457 problem JSON with a stable `code`; every mutating request accepts an `Idempotency-Key` header; list endpoints use cursor pagination; rate limits per user and per IP return 429 with `Retry-After`.

## Agent runtime

Each run is one DBOS workflow, `agentRun(runId)`, whose every model call and tool call is a checkpointed step, so a crash or deploy resumes at the last finished step instead of starting over.

### Run loop

1. **Admit:** check quotas and the bot's budget; reject with a clear error if exceeded.
2. **Build context** (below) and emit `run.started`.
3. **Model step:** stream from the `ModelGateway`, emitting coalesced `message.delta` events. Record usage.
4. **For each tool call:** validate arguments with Zod, apply the approval policy, resolve secret placeholders, execute as its own step, redact and store the result, emit events.
5. **Repeat** until the model returns a final answer, or a limit is hit: max steps (default 40), wall time (default 30 min), or budget.
6. **Finish:** save the final message, run memory extraction with the cheap model, record cost, send notifications, emit `run.completed`.
7. **Waits** for approvals and takeovers use durable DBOS receive with a timeout (default 24 h), so a run can wait for days without holding a process.
8. **Cancel** marks the run and its subruns cancelled; in-flight shell commands are killed through the supervisor.

### Context builder

- **Order:** system prompt (platform rules, persona, autonomy level, current date and user timezone), skills index (names and one-line descriptions only), retrieved memories, conversation summary, recent messages, current message.
- **Token budget:** compact when context passes 70% of the model's window. Older turns are summarized into the conversation `summary` and an `episode` memory.
- **Large tool results:** anything over about 4,000 tokens is written to a file in the computer, and the model gets a short preview plus the file path.
- **Prompt caching:** keep the system prompt and skills index byte-stable so providers that support caching can reuse it.
- **Untrusted content** (web pages, emails, tool output) is wrapped in clearly labeled blocks; the system prompt tells the model never to follow instructions inside them.

### Memory

- **Kinds:** `fact`, `preference`, `episode` (summary of a past run or conversation), `summary` (rolling conversation summary).
- **Write:** after each run, the cheap model extracts new facts and preferences, merges near-duplicates, and updates rather than appends. The bot can also call `memory.write` directly.
- **Read:** hybrid search (pgvector similarity plus Postgres full-text), merged with reciprocal rank fusion, top 8 plus all pinned memories.
- **User control:** a memory screen to view, edit, pin and delete; deleted memories are gone, not hidden.

### Tools

| Tool                                                                       | What it does                                                  | Default risk                                          |
| -------------------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------- |
| shell.exec                                                                 | Run a command in the computer, streaming output               | Low inside workspace                                  |
| files.read, files.write, files.list, files.search                          | Workspace files                                               | Low; deletes outside workspace are high               |
| browser.open, snapshot, click, fill, type, press, scroll, read, screenshot | Wraps agent-browser with element refs                         | Low; form submits on non-allowlisted sites are medium |
| desktop.snapshot, act, screenshot, click\_xy, type                         | agent-desktop first, screenshot fallback (vision models only) | Low                                                   |
| http.request                                                               | Outbound HTTP with secret placeholders                        | Medium                                                |
| memory.search, memory.write                                                | Bot memory                                                    | Low                                                   |
| skills.load                                                                | Load one skill's full instructions                            | Low                                                   |
| tasks.create, tasks.update                                                 | Shared task board                                             | Low                                                   |
| bots.delegate                                                              | Hand a task to a peer bot                                     | Low                                                   |
| subagent.spawn                                                             | Short-lived child run with a tool subset, budget and timeout  | Low                                                   |
| routines.create, routines.update                                           | Let a bot schedule its own follow-ups                         | Medium                                                |
| channel.send                                                               | Email, SMS, Telegram and other outbound messages              | High                                                  |
| notify.user                                                                | Push notification to the bot's owner                          | Low                                                   |
| request\_takeover                                                          | Ask a human to take control of the computer                   | Low                                                   |
| checkpoint.create                                                          | Save an undo point                                            | Low                                                   |
| mcp.{server}.{tool}, openapi.{source}.{operation}                          | Integration tools                                             | Set per tool, default medium                          |
| web.search                                                                 | Search provider with a BYO key                                | Low                                                   |

Tools are registered in one registry with a Zod schema, a risk level, a capability requirement (needs a computer, needs desktop, needs vision) and an executor. The model only sees tools the bot is allowed to use.

### Approvals and autonomy

- **Autonomy levels per bot:** `ask_always`, `ask_risky` (default), `autonomous`.
- `ask_risky` requires approval for high-risk tools, and for medium-risk tools when the run has read untrusted content since the last approval.
- Approvals show the tool, redacted arguments and a plain-language summary, and expire after 24 h. Users can tick "always allow this tool for this bot".

### Secrets

- Bots refer to secrets as `{{secret:NAME}}`. The executor swaps in the real value only at execution time, only for tools that accept secrets, and only for hosts in the secret's `allowed_hosts`.
- Tool output is scanned and every secret value is replaced with `[secret:NAME]` before it reaches the model, events or logs.

### Delegation and multi-bot work

- `subagent.spawn` starts a child DBOS workflow with its own budget (default 20% of the parent's remaining budget), timeout and tool subset, and returns a summary.
- `bots.delegate` posts a task to a peer bot's conversation and links the runs; the result returns as a `subrun.completed` event.
- Maximum delegation depth is 3; cycles are rejected.

### Routines and triggers

- A DBOS scheduled workflow runs every minute, claims due routines with `SELECT ... FOR UPDATE SKIP LOCKED`, starts runs and sets `next_run_at` from the cron expression in the routine's timezone.
- Event triggers: email received at the bot's inbox, channel message, GitHub webhook, custom HMAC webhook.
- Routine results go to the routine's conversation and trigger a push notification if the routine asks for one.

### Model gateway

- Providers at launch: OpenAI, Anthropic, Google, xAI, OpenRouter, and any OpenAI-compatible endpoint (Ollama, vLLM).
- Each bot has a primary model, an ordered fallback list and a cheap model for internal steps (memory extraction, summaries, titles).
- Failover on 429, 5xx or timeout, with exponential backoff; every attempt is logged to Langfuse.
- Capabilities per model (tools, vision, context window, caching) live in a registry, which decides which tools and context strategy apply.

## Computers

Every bot computer is reached through one `SandboxProvider` interface, runs a `computerd` daemon, starts headless by default, and sleeps to object storage when idle; Docker with gVisor is the default provider, E2B and Daytona are drop-in alternatives.

### Provider interface

```ts
export interface SandboxProvider {
  readonly id: "docker" | "e2b" | "daytona" | "local";
  readonly capabilities: { desktop: boolean; snapshots: boolean; liveStream: boolean };
  create(spec: ComputerSpec): Promise<SandboxHandle>;
  resume(ref: string, snapshot?: SnapshotRef): Promise<SandboxHandle>;
  sleep(ref: string): Promise<SnapshotRef>; // save home dir, then stop
  destroy(ref: string): Promise<void>;
}

export interface SandboxHandle {
  readonly ref: string;
  exec(cmd: string, opts?: ExecOptions): AsyncIterable<ExecChunk>;
  kill(execId: string): Promise<void>;
  readFile(path: string): Promise<Uint8Array>;
  writeFile(path: string, data: Uint8Array): Promise<void>;
  listDir(path: string): Promise<FileEntry[]>;
  enableDesktop(): Promise<void>; // start X server, window manager, streamer
  screenshot(): Promise<Uint8Array>;
  input(event: InputEvent): Promise<void>; // mouse and keyboard
  streamEndpoint(): Promise<StreamEndpoint>; // WebRTC signaling target
  checkpoint(label: string): Promise<CheckpointRef>;
  restore(id: CheckpointRef): Promise<void>;
  health(): Promise<HealthStatus>;
}
```

Each adapter in `packages/sandbox` passes the same contract test suite.

### Supervisor

- The only service with access to the Docker socket. The API and worker call it over an internal authenticated HTTP API.
- Creates each computer as a container with `--runtime=runsc` (gVisor), a non-root user, a read-only root filesystem except home and `/tmp`, CPU, memory and PID limits, and a disk quota.
- Puts each computer on its own Docker network whose only route out is the egress proxy.
- Keeps a small warm pool of pre-started headless containers to cut first-command latency.
- Reports `computer.state` changes and usage seconds to the worker.

### Images

| Image             | Contents                                                                                                                | Default size                 |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| computer-headless | Ubuntu 24.04, computerd, bash, git, Node.js, Python, common CLIs, Chromium, agent-browser                               | 1 vCPU, 1 GB RAM, 10 GB disk |
| computer-desktop  | Headless image plus X server, lightweight window manager, AT-SPI accessibility, agent-desktop, xdotool, WebRTC streamer | 2 vCPU, 3 GB RAM, 10 GB disk |

Images are versioned and published to GHCR for amd64 and arm64. A running headless computer switches to desktop on demand by restarting into the desktop image with the same home volume.

### Lifecycle

States are `provisioning`, `starting`, `running`, `idle`, `sleeping`, `stopped` and `error`. A computer with no tool calls, open terminals or viewers for 10 minutes goes idle and is put to sleep: its home directory (workspace and browser profiles) is archived to object storage and the container is destroyed. The next tool call or viewer restores it.

&#91;embedded content: computer lifecycle · 5 main states\]

Stopped and error can be reached from any state and are left out of the drawing; a restore always passes back through starting.

### Isolation and networking

- The egress proxy blocks private and link-local ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16, 127.0.0.0/8, IPv6 equivalents) and the internal service network.
- Per-org egress rules: optional allowlist or denylist of domains.
- Team computers are shared by an org's bots; private computers belong to one bot. Bots never share computers across orgs.
- Bandwidth and outbound connection rate limits per computer stop abuse such as spam or scanning.

### Checkpoints and undo

- The executor creates a checkpoint before high-risk tool calls and before any command matching destructive patterns (`rm -rf`, `git reset --hard`, package uninstalls).
- Checkpoints snapshot the home directory incrementally to object storage. The app shows them on the timeline with a Restore button.
- Keep the last 20 checkpoints per computer or 7 days, whichever is fewer.

### Providers

- **Docker (default):** cheapest at steady use; needs the supervisor host.
- **E2B and Daytona:** per-second billing; use for overflow when the sandbox host is full, or as the only provider for small installs. Selected per org or globally by config.
- **Local:** the user's own machine through the desktop companion (see its section).

## Live streaming and take control

Users watch a bot's desktop live over WebRTC and can take control at any time; the bot pauses while a human holds control and resumes when control is handed back.

### Streaming

- The desktop image runs an open-source WebRTC desktop streamer (evaluate Selkies and Neko in Phase 5, record the choice as a decision). The stream starts only when a viewer joins and stops 60 s after the last viewer leaves.
- `POST /v1/computers/{id}/stream-session` returns a signaling URL, a 5-minute token bound to the user, computer and mode (`view` or `control`), and short-lived coturn credentials.
- Signaling is proxied by the API; the computer's streamer is never reachable directly from the internet.
- The Flutter app uses `flutter_webrtc` on every platform. Mouse, touch and keyboard input travel on a WebRTC data channel and are accepted only with a `control` token.
- Adaptive bitrate; the app requests a lower frame rate when backgrounded and drops video when the screen is off.
- Fallback for networks that block WebRTC: periodic screenshots over HTTPS (one per second) so the user can always see the screen.

### Control lease

- At most one control holder per computer screen. The default holder is the bot.
- **User takes control:** `POST /lease` sets the user as holder; the worker stops issuing desktop and browser actions for that computer and the run shows "paused, user in control". Shell and file tools keep working only if the user allows it.
- **Hand back:** `DELETE /lease` (or 15 minutes of no input) returns control; the bot takes a fresh snapshot of the screen before acting again.
- **Bot asks for help:** `request_takeover(reason)` sets the run to `waiting_takeover`, sends a push notification with a "Take control" action that deep-links to the live view, and waits durably until the user hands back or dismisses.
- Viewers with only `view` mode can watch but never send input. Every lease change is written to `audit_log` and the run timeline.

### Privacy during takeover

- While a user holds control, input events are not recorded and screenshots are not sent to the model, so passwords typed by the user never reach the bot.
- After hand-back, the bot is told only that the user finished, plus any note the user typed.

## Integrations, channels and voice

MCP is the one integration standard; channels let people talk to bots from outside the app; voice covers dictation, read-aloud and live calls, all with the user's own provider keys.

### Integrations

- **Remote MCP servers** (Streamable HTTP, with OAuth or header auth): tools are listed on connect, cached, and exposed as `mcp.{server}.{tool}`. Re-list on demand and every 24 h.
- **OpenAPI sources:** import an OpenAPI 3 JSON document; each operation becomes a tool with its schema. Auth through named secrets.
- **Optional catalogs:** Composio and Pipedream Connect adapters, off unless their keys are set.
- Per-bot allowlists decide which integration tools each bot may call; each tool has a risk level the org admin can raise.
- Integration credentials live only in Vault and are never returned by the API.

### Channels

| Channel   | Inbound                                         | Outbound       | Notes                                                |
| --------- | ----------------------------------------------- | -------------- | ---------------------------------------------------- |
| Email     | Resend inbound webhook to the bot's own address | Resend         | Each bot gets an address like `name@bots.yourdomain` |
| SMS       | Twilio webhook                                  | Twilio         | Optional phone number per bot                        |
| Telegram  | Bot API webhook                                 | Bot API        | Free; quickest channel to ship first                 |
| Slack     | Events API                                      | Web API        | Install per workspace                                |
| WhatsApp  | Meta Cloud API webhook                          | Meta Cloud API | Needs Meta business verification                     |
| Messenger | Meta webhook                                    | Send API       | Needs Meta app review                                |

- Every adapter implements `ChannelAdapter` with `verifyWebhook`, `normalizeInbound` (to a standard message), `send` and `threadKey`.
- Each external thread maps to one conversation, so replies stay in context.
- **Sender allowlist:** a bot only acts on messages from senders in `allowed_senders` (for example the owner's Telegram id or email). Others get no reply and are logged.
- Outbound sends from a bot are `channel.send`, a high-risk tool that needs approval under the default autonomy level; replies inside an existing thread started by an allowed sender are medium risk.

### Voice

- **Dictation:** record with the `record` package, transcribe through the user's speech-to-text key (OpenAI or Deepgram) via the API.
- **Read aloud:** text-to-speech through the user's key: ElevenLabs, OpenAI, Cartesia or Fish Audio. Cache audio per message.
- **Live calls:** speech-to-speech realtime models over WebRTC. The API mints an ephemeral provider token (`POST /v1/voice/session`); the app connects directly; the call's tool calls are forwarded to `POST /v1/voice/tool` and run as a normal agent run with the same approvals. Transcripts are saved to the conversation.
- Voice usage is recorded in `usage_ledger` like tokens.

## Local computer companion

The Flutter desktop app can act as a bot's computer on the user's own Mac, Windows or Linux machine, which costs nothing to host; it is off by default and every action is visible and stoppable.

- **Pairing:** in Settings, the user turns on "Use this computer for bots", picks which bots may use it, and approves capabilities one by one: shell, files (limited to chosen folders), browser, desktop apps.
- **Connection:** the app opens a WebSocket to `/v1/local-computer/connect` with a device token stored in `flutter_secure_storage`. The backend's `local` provider routes tool calls to it and receives streamed results. Reconnects with backoff; tool calls fail fast when the device is offline.
- **Execution:** the app runs tools with `Process.start`: agent-browser for web tasks, agent-desktop for native apps, shell and file tools inside the allowed folders only.
- **Visibility:** an always-on-top overlay shows which bot is acting and what it is doing, with a Stop button that cancels the run. A tray or menu-bar icon shows status.
- **Safety:** high-risk actions always need approval on this provider regardless of autonomy level; the app refuses paths outside allowed folders; all actions are written to the run timeline and audit log.
- **Bundling:** the app downloads pinned versions of agent-browser and agent-desktop on first use with checksum verification, rather than shipping them inside the app.
- **Platform permissions:** guide the user through macOS Accessibility and Screen Recording permission prompts; on Windows and Linux, check accessibility support and explain any missing pieces.

## Flutter client

One Flutter app ships to web, iOS, Android, macOS, Windows and Linux, organized by feature, with adaptive layouts: bottom navigation on phones, a navigation rail on tablets and a three-pane layout (bots, chat, computer) on desktop and web.

### Architecture

- **Feature-first folders** under `lib/features/<name>/` with `data/` (repositories), `application/` (Riverpod notifiers) and `presentation/` (widgets).
- **Riverpod** with code generation for state; **go\_router** with deep links (`/bots/:id/chat`, `/computers/:id/live`, `/approvals/:id`) used by push notifications.
- **Data:** `supabase_flutter` for reads and simple writes; the generated `kasama_sdk` client (openapi-generator, dart-dio) for commands; one `RunEventStream` service merges Realtime events with the catch-up endpoint and orders by `seq`.
- **Offline cache:** `drift` stores conversations, messages and bots so chats open instantly; server data always wins on sync.
- **Models:** `freezed` and `json_serializable`; event payloads come from the generated client.

### Packages

| Need                      | Package                                                     |
| ------------------------- | ----------------------------------------------------------- |
| Backend                   | supabase\_flutter, generated kasama\_sdk (dio)              |
| State, routing, models    | flutter\_riverpod, riverpod\_generator, go\_router, freezed |
| Local cache               | drift                                                       |
| Live view                 | flutter\_webrtc                                             |
| Terminal                  | xterm                                                       |
| Markdown and code in chat | a maintained markdown renderer with syntax highlighting     |
| Push                      | firebase\_messaging, flutter\_local\_notifications          |
| Voice                     | record, just\_audio                                         |
| Secure storage            | flutter\_secure\_storage                                    |
| Files                     | file\_picker, share\_plus                                   |
| Monitoring and analytics  | sentry\_flutter, posthog\_flutter                           |
| OTA updates               | Shorebird (mobile and desktop)                              |
| Languages                 | flutter\_localizations with ARB files                       |

### Screens

1. **Onboarding and auth:** sign up, sign in, magic link, Google, Apple; create or join a workspace; add a model key; pick a template.
2. **Bots list:** status (idle, working, waiting for you), last activity, today's cost.
3. **Bot chat:** streaming messages, tool steps folded into readable cards, approvals inline, attachments, voice input, cancel.
4. **Activity timeline:** every run event with filters; checkpoints with Restore.
5. **Computer:** live view, take control and hand back, terminal, file browser, sleep and wake, size.
6. **Approvals inbox:** pending approvals across bots, with approve, deny and "always allow".
7. **Bot settings:** persona, model and fallbacks, autonomy, budget, memory, skills, routines, integrations, channels.
8. **Workspace settings:** members and roles, model keys, secrets, integrations, quotas and usage, language, data export, delete account.
9. **Templates gallery:** starter bots with one-tap create.
10. **Companion settings** (desktop only): local computer pairing and permissions.

### Platform notes

- **Web:** WebRTC and Realtime work in the browser; keep bundle size in check with deferred loading of the computer and voice features.
- **iOS:** Sign in with Apple is required because other social logins exist; request microphone and notification permissions only when first needed.
- **Desktop:** tray or menu-bar icon, native notifications, and the companion feature.
- **Accessibility:** every interactive widget has semantics labels; support dynamic text size.

## Dart and Flutter extras

Dart covers every client, not just the app: the CLI is the first test client for the backend, `computerd` runs inside every computer, and one SDK is shared by the app, CLI and companion. The backend stays TypeScript for its AI libraries, and the marketing site stays static HTML for SEO.

| Piece                   | What it is                                                                                                                                                                                                                         | Phase     |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| `kasama` CLI            | Dart, compiled per OS with `dart compile exe`. Commands: `login`, `org`, `bot`, `chat` (streams tokens and tool steps), `runs watch`, `memory`, `computer shell`, `computer files`. Later: `selfhost install`, `upgrade`, `backup` | 0 to 2, 8 |
| `computerd`             | Dart daemon inside each computer: exec with streaming, files, mouse and keyboard input, screenshots, health. One small static binary, so the image needs no extra runtime for it                                                   | 2         |
| `kasama_sdk`            | Generated API client, typed run events and a `RunEventStream` helper that merges Realtime with catch-up by `seq`. Used by the app, CLI and companion; published to pub.dev                                                         | 0, 6      |
| Home-screen widgets     | Bot status and a quick-ask button on iOS and Android (`home_widget`)                                                                                                                                                               | 6         |
| iOS Live Activities     | A running bot's progress on the lock screen and Dynamic Island (`live_activities`)                                                                                                                                                 | 6         |
| Share to bot            | Send links, text and files from any app to a chosen bot (`receive_sharing_intent`)                                                                                                                                                 | 6         |
| Desktop hotkey and tray | Global shortcut opens a quick-ask window; tray or menu-bar status (`hotkey_manager`, `tray_manager`)                                                                                                                               | 6         |
| Owner admin console     | Owner-only screens in the same app: users, providers, quotas, system health, update notices                                                                                                                                        | 6         |
| Desktop companion       | Bot computer on the user's own machine (see Local computer companion)                                                                                                                                                              | 6         |

**CLI rules:** every CLI command calls only public API endpoints through `kasama_sdk`, so the CLI doubles as an end-to-end test of the backend. Output supports `--json` for scripting. Release binaries for macOS, Linux and Windows on GitHub Releases, plus a Homebrew tap.

## Security and privacy

The main threats are a bot being hijacked by content it reads, one tenant reaching another's data or computer, and leaked credentials; each has a specific control below.

| Threat                                               | Control                                                                                                             |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Prompt injection from web pages, emails, tool output | Untrusted-content labeling, approval required for risky tools after untrusted input, secrets never in model context |
| Cross-tenant data access                             | RLS on every table, server queries under the user's claims, pgTAP isolation tests in CI                             |
| Sandbox escape or lateral movement                   | gVisor runtime, non-root user, per-computer networks, egress proxy blocking private ranges, resource limits         |
| Leaked model keys or secrets                         | Supabase Vault only, host allowlists per secret, output redaction, never returned by the API                        |
| Abuse (spam, scanning, crypto mining)                | Outbound rate limits, CPU quotas, usage alerts, account suspension tooling                                          |
| Stolen stream or control session                     | 5-minute tokens bound to user, computer and mode; signaling only through the API                                    |
| Unauthorized channel commands                        | Webhook signature checks, sender allowlists per bot                                                                 |
| Compromised dependencies                             | Lockfiles, Dependabot, image scanning in CI, pinned agent-browser and agent-desktop versions                        |

**Other requirements**

- TLS everywhere; HSTS and a strict Content Security Policy on the web app.
- Admin actions, approvals, lease changes and credential changes go to `audit_log`.
- **Privacy (Philippines Data Privacy Act of 2012, plus GDPR-style rights):** data export as a ZIP, account deletion that purges data and computer snapshots within 30 days, a retention setting for run events (default 180 days), a privacy policy and a named data protection contact.
- Never log message content or tool arguments at info level; Langfuse traces redact secrets and can be turned off per org.
- A `SECURITY.md` with a vulnerability reporting address.

## Observability, testing and evals

A nightly eval suite is the quality gate: no prompt, model, tool or context change merges if it lowers the task success rate.

### Observability

- **Traces:** OpenTelemetry spans from API to worker to supervisor to computerd, with run\_id and org\_id as attributes; export to an OTel collector.
- **Errors:** Sentry on server, supervisor and Flutter.
- **LLM traces:** Langfuse (self-hosted) for every model call, with token counts and cost.
- **Product analytics and flags:** PostHog; risky features ship behind flags to 10% of users first.
- **Dashboards and alerts:** run success rate, time to first token (p50, p95), computer start time, sleeping vs running computers, cost per run, queue depth, error rate. Alert when run failures exceed 5% over 15 minutes or the sandbox host passes 85% memory.

### Testing

| Level            | Tooling                                                               | Covers                                                                 |
| ---------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Unit             | Vitest; Dart `test`                                                   | Domain logic, context builder, policies, redaction, Riverpod notifiers |
| Database         | pgTAP against `supabase start`                                        | Every RLS policy, cross-org isolation                                  |
| Integration      | Vitest + Testcontainers + local Supabase                              | API endpoints, DBOS workflows, crash-and-resume, approvals             |
| Model fixtures   | Recorded model responses replayed in tests                            | Agent loop without paid API calls                                      |
| Sandbox contract | One suite run against Docker, E2B, Daytona, local                     | Every `SandboxHandle` method                                           |
| Flutter widgets  | Widget tests and golden tests                                         | Chat cards, approvals, timeline, computer view                         |
| End to end       | Flutter `integration_test` on Android emulator, iOS simulator, Chrome | Sign up, create bot, chat, approve, take control                       |
| Load             | k6                                                                    | 200 bots waking at once; 100 concurrent chat streams                   |

### Evals

- `packages/evals` holds 30 to 50 real tasks with automatic checks: web research with a known answer, fill a form on a test site, edit a repo and pass its tests, write a file in a set format, use an MCP tool, respect an approval, refuse an injected instruction.
- Runs nightly in real computers against the default models. Records success rate, cost, steps and time per task.
- CI fails a pull request that changes `packages/agent` or prompts if a quick 10-task subset drops below the last baseline.

## Infrastructure and deployment

Production for 100 users runs on one app server and one sandbox server in Singapore, at roughly $200 to $450 a month before model costs; self-hosters get the same stack from one Docker Compose file.

### Hosted production (about 100 active users, 200 bots)

| Component      | Spec                                                                                         | Approx. USD per month |
| -------------- | -------------------------------------------------------------------------------------------- | --------------------- |
| App server     | Cloud VPS, 4 to 8 vCPU, 16 GB RAM: Caddy, API, worker, coturn, egress proxy                  | 30 to 60              |
| Supabase       | Supabase Cloud (Singapore) or self-hosted on the app server                                  | Plan dependent        |
| Sandbox server | Dedicated, 16+ cores, 64 to 128 GB RAM, NVMe: supervisor and computers (30 to 40 concurrent) | 150 to 350            |
| Object storage | S3-compatible (Cloudflare R2 has no egress fees) for snapshots and files                     | 10 to 20              |
| Overflow       | E2B or Daytona, per-second billing, only when the sandbox server is full                     | Usage based           |

Prices are estimates and providers raised prices several times in 2026; confirm current pricing before ordering. Pick Singapore locations for lower latency from the Philippines.

### Self-host

- `infra/compose/` contains the Supabase self-host services plus `server` (api), `server` (worker), `supervisor`, `coturn`, `egress-proxy` and `caddy`.
- `install.sh` checks Docker, generates all secrets with OpenSSL, writes `.env`, pulls images and starts the stack. Re-running keeps the existing `.env`.
- Single-machine mode runs computers on the same host with gVisor; a second host is recommended for public deployments.
- `docs/SELF_HOST.md` covers domains and TLS, providers, backups, upgrades and restore.

### Environments and CI/CD

- **Environments:** local (`supabase start` + `pnpm dev`), preview per pull request (Supabase branch plus a preview server), staging, production.
- **On every pull request:** lint, typecheck, unit, database, integration and widget tests, OpenAPI diff check, Dart client regeneration check, quick eval subset when agent code changes.
- **On merge to main:** build multi-arch images to GHCR, run migrations on staging, deploy staging, run end-to-end smoke tests.
- **Releases:** tagged releases promote to production; Flutter builds for app stores and desktop installers (signed and notarized); Shorebird patches for urgent fixes.
- **Backups:** daily Postgres backups with point-in-time recovery, object storage versioning, monthly restore drill.
- **Migrations** are backward compatible for one release so API and worker can deploy without downtime.

## Cost controls and quotas

Computer time and model tokens are the two costs that grow with users, so both are metered from Phase 1 and capped per bot and per organization.

- **Headless by default:** desktop computers start only for desktop tools or a live viewer, then drop back to headless after 10 idle minutes.
- **Sleep on idle:** 10 minutes without activity puts a computer to sleep in object storage.
- **Cheap model for internal steps:** memory extraction, summaries, titles and routing never use the primary model.
- **Prompt caching and compaction** keep long-running bots from growing more expensive each day.
- **Budgets:** each bot has a per-run and a daily cost cap; subagents inherit a share of the parent's budget.
- **Quotas per organization:** monthly cost, computer hours and concurrent computers. Checked at run start and after every model step; when exceeded, the run stops cleanly and the owner is notified.
- **Ledger:** every token, computer-second, stream-second and TTS character is written to `usage_ledger`, which feeds the per-bot cost meter in the app.
- **Bring-your-own keys** by default, so model costs are paid by users. Paid plans and credits come later through Dodo Payments on top of the same ledger (see Monetization).

## Monetization

Self-hosting stays free; revenue comes from Kasama Cloud plans, usage credits and Cloud Connect, billed through Dodo Payments on web and desktop and through Apple and Google subscriptions on mobile. No Stripe. The full build is Phase 7; Phase 0 only adds `plans` and `entitlements` stubs with one default self-host plan, so billing later needs no data migration.

### Revenue streams

| Stream             | Who pays                       | How                                                                                                                 |
| ------------------ | ------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| Kasama Cloud plans | Hosted users                   | Monthly or yearly subscription with included computer hours and model credits                                       |
| Usage credits      | Hosted and Cloud Connect users | Prepaid or metered credits for computer time, model tokens and phone numbers                                        |
| Cloud Connect      | Self-hosters                   | An API key lets a self-hosted instance use cloud computers, model credits and channels, billed to its cloud account |
| Enterprise license | Companies that self-host       | Commercial license for `ee/` features: SSO and SAML, advanced roles, audit export, priority support                 |

Plan names, prices and limits are open decisions; the system supports any number of plans.

### Payment sources

- **Dodo Payments** for web, desktop, Cloud Connect and enterprise. Dodo is the merchant of record, handling sales tax, VAT, fraud screening and chargebacks ([Appwrite integration page](https://appwrite.io/integrations/dodo-payments-subscriptions)). Use its hosted checkout and customer portal; verify every webhook with the Standard Webhooks signature; send usage events for metered credits ([Better Auth plugin docs](https://www.better-auth.com/docs/plugins/dodopayments)).
- **Apple App Store** for iOS: auto-renewable subscriptions through Flutter's `in_app_purchase`, verified with the App Store Server API, with renewals and refunds from App Store Server Notifications V2.
- **Google Play** for Android: Play Billing subscriptions through `in_app_purchase`, verified with the Play Developer API, with real-time developer notifications for renewals, cancellations and refunds.
- **Store rule:** digital subscriptions bought inside the iOS app must use Apple in-app purchase ([Mondaq](https://www.mondaq.com/unitedstates/it-and-internet/1825852/update-your-app-external-purchase-developments-for-apple-google)). Links to web checkout are allowed on the US storefront only and are still a violation in most other regions ([Stora guide](https://stora.sh/blog/2026-05-16-apple-app-store-external-purchase-links-implementation-guide)), so the Philippine iOS app shows in-app purchase only. Re-check store rules every quarter.

### Data model (Phase 7)

| Table                | Key columns                                                                                                                       |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| plans                | code, name, interval, limits jsonb (computer hours, credits, bots, seats), dodo\_product\_id, store\_product\_ids jsonb, active   |
| subscriptions        | org\_id, source (dodo, app\_store, google\_play), external\_id, plan\_code, status, current\_period\_end, cancel\_at\_period\_end |
| entitlements         | org\_id, plan\_code, limits jsonb, valid\_until, subscription\_id                                                                 |
| credit\_ledger       | org\_id, delta, reason (purchase, usage, grant, refund), reference, balance\_after                                                |
| billing\_events      | source, event\_id (unique), payload jsonb, processed\_at                                                                          |
| cloud\_connect\_keys | org\_id, key\_hash, instance\_name, scopes, last\_used\_at                                                                        |

### Rules

- One `BillingProvider` interface (`createCheckout`, `customerPortal`, `verifyWebhook`, `parseEvent`, `verifyPurchase`) with dodo, app\_store and google\_play adapters.
- Every webhook is stored in `billing_events` and processed once by event id. The server re-fetches the subscription from the provider instead of trusting the payload.
- Entitlements are computed on the server and are the only thing quotas and paywalls read. Purchases belong to the account, so a purchase on one platform works on all; mobile has Restore Purchases.
- `usage_ledger` entries are converted into credit deductions; metered plans also report usage to Dodo.
- Self-host builds ship with `BILLING_ENABLED=false`: no paywall and unlimited local use.

## Open source and growth

The aim is the shortest path from discovering Kasama to a working bot, plus public numbers that show growth to users and investors. Repo basics start in Phase 0; the public launch is Phase 8.

### License and governance

- **Apache-2.0** for everything outside `ee/`, which keeps adoption friction low for individuals and companies.
- **`ee/`** holds enterprise features under a commercial license: the code is readable, production use needs a license.
- **DCO sign-off** on every commit instead of a contributor license agreement, so contributing stays easy.
- Public roadmap on GitHub Projects, a changelog for every release, semantic versioning, and a `GOVERNANCE.md` naming maintainers and how decisions are made.

### Fast adoption

- **Under 5 minutes to a first bot:** one-command install, one-click deploy templates (Railway, Render, DigitalOcean, Coolify) and a free hosted tier.
- **README that sells:** one-line pitch, 60-second demo video, install command, screenshots, and what Kasama does that closed agent products don't (self-hosting, any model, your own computers).
- **Try without paying:** local models through Ollama, so a first bot needs no API key.
- **Ecosystem hooks:** a community repo of skills and bot templates, a Kasama MCP server so people control their bots from AI coding tools, and public SDKs (Dart on pub.dev, TypeScript on npm).
- **Docs site** with quick start, self-hosting, API reference generated from OpenAPI, and guides per use case.
- **Translations** starting with Filipino.

### Community and launch

- Discord, `good first issue` labels, a contributor guide with one-command local setup, and a monthly community call.
- **Launch order:** private beta with testers from Phase 3, then Show HN, Product Hunt, r/selfhosted and r/LocalLLaMA, with build-in-public posts on X and short demo videos throughout.

### Metrics for investors

- **Opt-in anonymous telemetry** for self-hosted instances (instance count, weekly active bots, version), documented in the README and easy to turn off.
- **Track weekly:** GitHub stars, active self-hosted instances, weekly active users and bots, cloud MRR and month-over-month growth, paid conversion, 4-week retention.
- Publish a monthly update post with these numbers. Accelerators like Y Combinator weigh traction and growth rate most, so this data is what makes an application strong; no plan guarantees acceptance.

## Build plan

The plan is backend-first: Phases 0 to 2 build a working backend you test from the Dart CLI, Phase 3 adds the Flutter app so real testers can use the MVP, and monetization waits until Phase 7. Each phase ends at a gate whose criteria must pass before the next one starts, and every phase leaves a deployable system.

&#91;embedded content: build plan · 9 phases, MVP after Phase 3\]

A phase starts only when the previous gate passes; the full task lists and gate criteria follow.

### Phase 0: Backend foundations

- [ ] Monorepo with pnpm, Turborepo and Biome, plus a Dart workspace for `dart/`; CI running lint, typecheck and tests
- [ ] Open-source basics: Apache-2.0 LICENSE, README, CONTRIBUTING with DCO sign-off, CODE\_OF\_CONDUCT, SECURITY.md, issue templates
- [ ] Supabase migrations for organizations, memberships, profiles, invites, with RLS and pgTAP tests
- [ ] Billing-ready stubs: `plans` and `entitlements` tables with one default self-host plan
- [ ] Server skeleton: Hono with zod-openapi, `MODE=api` and `MODE=worker`, JWT middleware, `withUserSession`, problem-JSON errors, health checks, interactive API reference at `/docs`
- [ ] `packages/contracts`: OpenAPI generation and run event schema; generator for `dart/kasama_sdk`
- [ ] DBOS wired into the worker with one test workflow
- [ ] Observability package: OpenTelemetry and Sentry
- [ ] Docker Compose stack for local development
- [ ] `kasama` CLI v0: `login`, `whoami`, `org create`, `org invite`

**Gate:** a developer signs up and logs in from the CLI, creates a workspace and invites a member; the cross-org RLS test passes; CI is green.

### Phase 1: Backend MVP (bots and chat)

- [ ] Migrations: bots, conversations, messages, attachments, runs, run\_events, memories, skills, model\_credentials, usage\_ledger, quotas, audit\_log
- [ ] Model keys in Vault with a test endpoint (OpenRouter plus one direct provider first)
- [ ] `ModelGateway` with fallback chain and capability registry
- [ ] `agentRun` workflow: loop, streaming, cancel, step and time limits, usage recording
- [ ] Event bus: write to Postgres, broadcast on Realtime, catch-up endpoint
- [ ] Context builder with compaction and large-output offload
- [ ] Memory service: extraction and hybrid search
- [ ] Skills: create, edit, `skills.load`
- [ ] CLI: `bot create`, `chat` (streams tokens and tool steps), `runs watch`, `memory list`
- [ ] Recorded model fixtures; crash-and-resume integration test

**Gate:** chat from the CLI streams replies; killing the worker mid-run resumes the run; a fact from one chat is recalled in another; no API response ever contains a key.

### Phase 2: Computers (backend)

- [ ] `SandboxProvider` interface and contract test suite
- [ ] `computerd` in Dart, compiled to a single binary
- [ ] Headless and desktop images for amd64 and arm64
- [ ] Supervisor: Docker with gVisor, per-computer networks, limits, warm pool
- [ ] Egress proxy with private-range blocking
- [ ] Sleep and restore through object storage; checkpoints and restore
- [ ] Tools: shell, files, browser (agent-browser), checkpoint
- [ ] CLI: `computer status`, `computer shell` (interactive terminal), `computer files`

**Gate:** from the CLI, a bot researches a topic on the web and writes a report file; sleep and restore keep files and browser logins; restoring a checkpoint reverts files; requests to 169.254.169.254 and the internal network are blocked.

### Phase 3: MVP app (Flutter)

- [ ] App shell: theme, go\_router, l10n, adaptive layout, wired to `kasama_sdk`
- [ ] Auth screens (email, magic link, Google, Apple), create and join workspace, add a model key
- [ ] Bots list, streaming chat with tool cards, activity timeline
- [ ] Computer tab: screenshot view, terminal, file browser, checkpoint Restore
- [ ] Memory and skills screens; cost meter
- [ ] Tester builds: TestFlight, Google Play internal testing, web preview

**Gate (MVP complete):** 10 testers use the app on Android, iOS and web for one week, and at least 80% of their runs finish without errors.

### Phase 4: Autonomy

- [ ] Approvals, autonomy levels and approvals inbox
- [ ] Secret placeholders, host allowlists and redaction tests
- [ ] Routine scheduler with timezones; webhook and GitHub triggers
- [ ] `subagent.spawn`, `bots.delegate` and the task board
- [ ] MCP and OpenAPI integrations; optional Composio and Pipedream adapters
- [ ] Push notifications (devices table, FCM fan-out), in-app inbox, deep links
- [ ] Templates gallery with 5 starter bots
- [ ] Tools: `web.search`, `http.request`, `notify.user`

**Gate:** a daily 08:00 Asia/Manila routine runs and pushes its result; sending email waits for approval; a subagent stops at its budget; MCP tools work; a test proves secrets never reach model input.

### Phase 5: Live computer

- [ ] Evaluate and integrate the WebRTC streamer in the desktop image; deploy coturn
- [ ] Stream-session endpoint and signaling proxy
- [ ] Flutter live view with `flutter_webrtc`, input data channel, touch gestures and zoom
- [ ] Control lease, `request_takeover`, push deep link, privacy during takeover
- [ ] Desktop tools: agent-desktop with screenshot fallback
- [ ] E2B and Daytona adapters passing the contract suite
- [ ] Team and private computer management in the app

**Gate:** live view under 500 ms on 4G; take control and hand back works mid-run; the same flow works on E2B; a bot completes a task in a Linux desktop app.

### Phase 6: Reach and Flutter extras

- [ ] Channel adapters in this order: Telegram, email (Resend), SMS (Twilio), Slack, WhatsApp, Messenger, each with sender allowlists
- [ ] Voice: dictation, read aloud, live calls with tool forwarding
- [ ] Local computer companion on macOS, Windows and Linux
- [ ] Home-screen widgets, iOS Live Activities, share to bot, desktop hotkey and tray, owner admin console
- [ ] Publish `kasama_sdk` to pub.dev; CLI release binaries and Homebrew tap

**Gate:** a Telegram message and an email each get replies in the same thread; unknown senders are ignored; a live call reply starts within 1 s; the companion completes a browser task on the user's Mac; an external sample app streams a run with the published SDK.

### Phase 7: Monetization (Dodo Payments)

- [ ] Billing tables: plans, subscriptions, entitlements, credit\_ledger, billing\_events, cloud\_connect\_keys
- [ ] `BillingProvider` interface and Dodo adapter: checkout, customer portal, Standard Webhooks verification, subscription lifecycle, usage events
- [ ] App Store adapter: `in_app_purchase`, App Store Server API verification, Server Notifications V2
- [ ] Google Play adapter: `in_app_purchase`, Play Developer API verification, real-time developer notifications
- [ ] Entitlement service feeding quotas; credit deductions from `usage_ledger`
- [ ] Plans, paywall and Restore Purchases screens; iOS shows in-app purchase only outside the US storefront
- [ ] Cloud Connect: API keys, `kasama-cloud` sandbox provider and model credit proxy for self-hosted instances
- [ ] `BILLING_ENABLED=false` by default in self-host builds

**Gate:** a Dodo purchase on web unlocks iOS and Android; an App Store purchase unlocks web; cancel and refund webhooks remove access; a self-hosted instance runs a bot on a cloud computer and the usage shows on its cloud bill.

### Phase 8: Production and open-source launch

- [ ] Dashboards and alerts; nightly evals with a stored baseline
- [ ] k6 load test: 200 bots waking at once, 100 concurrent chat streams
- [ ] Security review against the threat table; penetration test of sandbox isolation and RLS
- [ ] Data export, account deletion, retention settings
- [ ] Filipino translation
- [ ] Self-host installer, CLI `selfhost` commands, one-click deploy templates, docs site
- [ ] `ee/` features under the commercial license; opt-in telemetry; Kasama MCP server
- [ ] Marketing site, demo video, app store listings, signed desktop installers, Shorebird release flow
- [ ] Public launch: Show HN, Product Hunt, r/selfhosted, r/LocalLLaMA

**Gate:** load test p95 time to first token under 3 s; evals at or above baseline; security checklist closed; fresh VPS install under 15 minutes; apps approved in both stores; public launch done.

## Open decisions and risks

Five decisions have defaults the coding agent can build on now; they should be confirmed before Phase 4.

| Decision                      | Default in this spec                                                              | Confirm by |
| ----------------------------- | --------------------------------------------------------------------------------- | ---------- |
| Final product name and domain | "Kasama" as a working name in one config constant; check trademarks before launch | Phase 8    |
| Who pays for model usage      | Bring-your-own model keys at launch; included credits later via Dodo Payments     | Phase 7    |
| Supabase hosting              | Supabase Cloud in Singapore for hosted; self-hosted Supabase in the Compose stack | Phase 0    |
| First messaging channel       | Telegram first, then email and SMS, then Slack, WhatsApp, Messenger               | Phase 6    |
| WebRTC streamer               | Evaluate Selkies and Neko; pick by latency, license and mobile support            | Phase 5    |

| Risk                                                                                     | Impact                                     | Mitigation                                                                                                                 |
| ---------------------------------------------------------------------------------------- | ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| Chromium or desktop apps misbehave under gVisor                                          | Browser or desktop tools fail in computers | Test early in Phase 2; fall back to standard runc on a dedicated sandbox host with stricter network rules, or route to E2B |
| agent-desktop is new (v1.0 in Oct 2026) and depends on apps exposing accessibility trees | Desktop tasks fail on some apps            | Keep the screenshot fallback; pin versions; contract tests per release                                                     |
| WebRTC complexity and NAT traversal                                                      | Live view unreliable on mobile networks    | coturn with TCP and TLS fallback; screenshot fallback; measure in Phase 5 gate                                             |
| Model costs grow faster than expected                                                    | Hosted version loses money                 | BYO keys, budgets, quotas, cheap internal model, caching                                                                   |
| Prompt injection leads to harmful actions                                                | Trust and legal exposure                   | Untrusted-content labeling, approvals after untrusted input, secret placeholders, evals with injection tasks               |
| Meta app review delays for WhatsApp and Messenger                                        | Channels ship late                         | Start verification early; ship Telegram and email first                                                                    |
| Scope is large for one team                                                              | Slow launch                                | Strict phase gates; every phase ships a usable product                                                                     |
