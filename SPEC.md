# Casama — Full Build Spec

Nov 9, 2026 · @Oliver Martinez

## How to use this spec

This doc is the single source of truth for building Casama: build every phase in the build plan, in order, and do not mark a phase done until its acceptance criteria pass. Export it as `SPEC.md` at the repo root so the coding agent can read it.

**Rules for the coding agent**

1. **Clean-room build.** Never open, copy, translate or paraphrase source code, docs or UI copy from Rakazo or any other existing agent platform. Build only from this spec and the public docs of the libraries named here.
2. **No third-party brand names** in product UI, code identifiers or package names, except to name a service the user connects (a model provider, an app, or a sign-in button such as "Continue with ChatGPT"). "Casama" is a working name: keep it in one config constant so it can change.
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
- Errors report to one configurable reporter (Sentry protocol, so Sentry or self-hosted GlitchTip; or PostHog), off unless configured, and key actions emit OpenTelemetry spans (D-063).

## Product overview

Casama is an open-source, self-hostable platform for persistent AI teammates. Each bot has its own chats, memory, routines and a sandboxed computer. Users talk to bots through Casama's own clients (web, iOS, Android, macOS, Windows and Linux). External messaging channel adapters are specified for a later release but are not part of the v1 build (Phases 0–8).

**Goals**

- Match the feature set of leading open-source agent platforms (persistent bots, computers, delegation, routines, voice, integrations, media generation), plus the upgrades in this spec, then pull ahead of them with the Post-v1 roadmap.
- One Flutter codebase for web, iOS, Android, macOS, Windows and Linux.
- Serve 100 active users with 2 bots each on one app server and one sandbox server.
- Self-host with one command. For hosted deployments, pick a cloud region close to your users.
- License the whole repo under Apache-2.0.

**Target users:** solo founders, small teams and power users who want bots that do real work (research, browsing, operations, outreach) using their own model keys.

**v1 scope (Phases 0–8)**

- **Clients:** Flutter apps and the CLI only. No Telegram, SMS, email-inbox, Slack, WhatsApp or Messenger adapters in v1.
- **Models:** bring-your-own API keys for every provider, plus **ChatGPT plan sign-in**, so people with an eligible ChatGPT plan run bots on it instead of an API key. It is on for self-hosted servers, and on Casama Cloud only after OpenAI approves hosted use (see ChatGPT plan sign-in).
- **Integrations:** Remote MCP, OpenAPI tools, **Composio**, **Pipedream Connect**, and **image/video generation** (BYO provider keys).
- **Sandbox providers:** Docker (default), E2B, Daytona, and the local desktop companion. Extra hosted providers are specified post-v1 (see Providers).
- **Locale:** English only at launch. All UI strings in ARB files so more languages can ship later without code changes.

**Non-goals for v1**

- Training or hosting our own models.
- GPU sandboxes.
- A paid plugin marketplace.
- Enterprise SSO/SAML (the schema allows it; build it later).
- External messaging channels were post-v1 here; they shipped in Wave 3 (D-134).

## Features and acceptance criteria

The full product is 40 features across 9 phases, built backend-first: Phases 0 to 3 are the MVP. Each row's acceptance criterion is the test that proves it works. Latency figures are targets, measured from a representative user network against the chosen hosted region.

| Area                    | Feature                                                                                              | Acceptance criterion                                                                              | Phase   |
| ----------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------- |
| Workspaces              | Organizations, members, roles (owner, admin, member), email invites                                  | A member sees only their organization's data (RLS test)                                           | 0       |
| Auth                    | Email and password, magic link, Google, Apple                                                        | Auth works from the CLI in Phase 0; sign-in works on all 6 platforms in Phase 3                   | 0, 3    |
| CLI                     | Dart `casama` CLI: login, bots, chat, runs, computers                                                | A developer chats with a bot and watches its run from the terminal                                | 0 to 2  |
| Bots                    | Name, avatar, persona, model, autonomy level, budget                                                 | Settings persist; per-bot model override works                                                    | 1       |
| Chat                    | Streaming chat, attachments, markdown, cancel, retry                                                 | First token shows within 1.5 s of the model starting; cancel stops within 2 s                     | 1       |
| Memory                  | Facts, episode summaries, editable memory, hybrid search                                             | A fact told in chat A is recalled in chat B; the user can edit or delete it                       | 1       |
| Skills                  | Markdown instruction packs per organization or bot, loaded on demand                                 | The timeline shows a skill loaded only when relevant                                              | 1       |
| Model keys              | Bring-your-own keys in Vault, fallback chain                                                         | Keys are never returned by the API; a 429 or 5xx fails over to the next model                     | 1       |
| ChatGPT plan            | Sign in with ChatGPT so bots run on the person's ChatGPT plan instead of an API key                  | A bot replies on the user's plan at $0 model cost; the plan limit stops the run with a usage link | 8       |
| Usage ledger            | Every token, computer-second and voice character recorded                                            | The cost meter matches provider bills within 5%                                                   | 1       |
| Computers               | Private and team computers; headless by default, desktop on demand                                   | Bot runs shell commands, edits files, browses; sleeps after 10 min idle and restores its state    | 2       |
| Browser                 | agent-browser tool with element refs                                                                 | Bot completes a form task on a test site                                                          | 2       |
| Terminal and files      | Terminal and file access (CLI in Phase 2, app in Phase 3)                                            | User types in the terminal, uploads and downloads files                                           | 2, 3    |
| Undo                    | Checkpoints before risky actions, one-tap restore                                                    | Restoring a checkpoint reverts the files                                                          | 2       |
| MVP app                 | Flutter app: auth, bots, chat, timeline, computer screenshot view, terminal, files                   | 10 testers use it on Android, iOS and web for a week                                              | 3       |
| Routines                | Cron schedules in the user's timezone, plus event triggers                                           | A daily 08:00 routine in the owner's profile timezone runs and pushes its result                  | 4       |
| Approvals               | Policy-driven approval for risky tools                                                               | Sending an email waits for approval; deny cancels that step only                                  | 4       |
| Delegation              | Subagents and peer bots with budgets and timeouts; shared task board                                 | A subagent stops at its budget; the parent receives its summary                                   | 4       |
| Integrations            | Remote MCP servers, OpenAPI tools, Composio, Pipedream Connect                                       | MCP and OpenAPI tools run; Composio and Pipedream tools run when org credentials are configured   | 4       |
| Media generation        | Image and video generation via BYO provider (fal.ai adapter first; pluggable `MediaProvider`)        | A bot generates an image and a short video clip; usage is recorded; keys never leave Vault        | 4       |
| Secrets                 | Named secrets used through `{{secret:NAME}}` placeholders                                            | Secret values never appear in model input, events or logs (test)                                  | 4       |
| Notifications           | Push (FCM and APNs) plus an in-app inbox                                                             | An approval request reaches the phone within 5 s                                                  | 4       |
| Templates               | Starter bots for common jobs                                                                         | A new user has a working bot from a template within 2 min                                         | 4       |
| Live view               | WebRTC stream of the bot's desktop                                                                   | Under 500 ms glass-to-glass on 4G                                                                 | 5       |
| Take control            | Control lease, bot-initiated takeover requests, hand back                                            | Bot pauses while the user controls and resumes after hand-back                                    | 5       |
| Desktop control         | agent-desktop (accessibility tree) with screenshot fallback                                          | Bot operates a Linux desktop app                                                                  | 5       |
| Providers               | Docker with gVisor, E2B, Daytona (more providers specified post-v1)                                  | The same computer test suite passes on Docker, E2B and Daytona                                    | 5       |
| Channels                | Bot email inbox, SMS, Telegram, Slack, WhatsApp, Messenger (post-v1 build)                           | Specified in Channels; built in Wave 3 (D-134)                                                    | post-v1 |
| Voice                   | Dictation, text-to-speech (BYO ElevenLabs, OpenAI, Cartesia, Fish Audio), live calls                 | Live-call reply starts within 1 s                                                                 | 6       |
| Local computer          | Flutter desktop companion runs tools on the user's own machine                                       | Bot opens an app on the user's Mac behind a visible consent overlay                               | 6       |
| Flutter extras          | Home-screen widgets, iOS Live Activities, share to bot, desktop hotkey and tray, owner admin console | Each works on its platforms in the release build                                                  | 6       |
| Dart SDK                | `casama_sdk` on pub.dev with typed events                                                            | An external sample app streams a run using only the published SDK                                 | 6       |
| Plans and subscriptions | Dodo Payments on web and desktop; App Store and Google Play subscriptions on mobile                  | A purchase on any platform unlocks every platform; cancels and refunds remove access              | 7       |
| Credits and quotas      | Prepaid and metered credits; plan limits drive quotas                                                | A run stops cleanly when credits or quota run out                                                 | 7       |
| Cloud Connect           | Self-hosted instances use cloud computers and credits through an API key                             | A self-hosted bot runs on a cloud computer and the usage shows on the cloud bill                  | 7       |
| Privacy                 | Data export and account deletion                                                                     | Export downloads a ZIP; deletion purges data within 30 days                                       | 8       |
| Account security        | Two-step sign-in (TOTP), required for owners and admins by workspace setting; passkeys later         | A new device asks for a code; admins without two-step sign-in can't open secrets or billing       | 8       |
| Cloud abuse controls    | Sign-up check, verified email before free computers, mining and flood detection, suspension          | A scripted sign-up without a proof fails; a mining computer is stopped within 5 minutes           | 8       |
| Languages               | English at launch; ARB-ready for more locales later                                                  | Every screen uses English ARB strings; no hard-coded UI copy                                      | 8       |
| Self-host and launch    | One-command installer, one-click deploy templates, docs site, public launch                          | Fresh VPS to working app in under 15 min                                                          | 8       |

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
- **Object storage** behind the `ObjectStore` interface: the filesystem by default for a single self-hosted host, SeaweedFS (S3-compatible, optional compose profile) for self-hosted S3, and Cloudflare R2 recommended for hosted installs (no egress fees); AWS S3 and Supabase Storage's S3 endpoint also work. Holds computer snapshots, checkpoints and attachments (D-062).
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
casama/
  apps/
    server/              # one TypeScript codebase, MODE=api or MODE=worker
      src/api/           # Hono routes (OpenAPI), webhooks, WebSocket endpoints
      src/worker/        # DBOS workflows: agentRun, routines, memory, channels, usage, billing
      src/main.ts
    supervisor/          # sandbox supervisor; the only service with Docker access
    www/                 # static marketing site and public docs
  dart/
    cli/                 # casama CLI, compiled per OS with dart compile exe
    computerd/           # daemon inside each computer: exec, files, input, screenshots, health
    casama_sdk/          # generated API client + typed run events (published to pub.dev)
  packages/
    contracts/           # OpenAPI spec, Zod schemas, run event schema, tool schemas
    domain/              # pure logic: policies, budgets, autonomy, context builder, entitlements
    db/                  # Drizzle schema (pulled from migrations), query helpers, RLS session helper
    agent/               # agent loop, tool registry, ModelGateway, memory service
    sandbox/             # SandboxProvider interface + docker, e2b, daytona, local, casama-cloud adapters
    channels/            # ChannelAdapter interface + email, sms, telegram, slack, whatsapp, messenger
    billing/             # BillingProvider interface + dodo, app_store, google_play adapters (Phase 7)
    observability/       # OpenTelemetry, Sentry, Langfuse setup
    evals/               # eval tasks, runner, scoring
  client/                # Flutter app for all platforms (uses dart/casama_sdk)
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

| Table              | Key columns                                                                                                                                                           | Notes                                                                                                                     |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| organizations      | name, slug, plan, region                                                                                                                                              | One per workspace                                                                                                         |
| memberships        | org\_id, user\_id, role (owner, admin, member)                                                                                                                        | Drives every RLS policy                                                                                                   |
| profiles           | user\_id, display\_name, preferred\_name, pronouns, avatar\_url, locale, timezone                                                                                     | Timezone used for routines; the rest is About you (D-169)                                                                 |
| invites            | org\_id, email, role, token\_hash, expires\_at                                                                                                                        | Token stored hashed                                                                                                       |
| bots               | name, avatar\_url, persona\_md, model\_policy jsonb, autonomy, visibility (private, team), default\_computer\_id, budget jsonb, status                                | model\_policy = primary, fallbacks, cheap model                                                                           |
| conversations      | bot\_id, channel\_id, external\_thread\_id, title, summary, last\_message\_at                                                                                         | One per chat or external thread                                                                                           |
| messages           | conversation\_id, role, author\_user\_id, content jsonb (parts), run\_id                                                                                              | Final messages only; token deltas live in run\_events                                                                     |
| attachments        | message\_id, storage\_path, mime, size                                                                                                                                | Files in object storage                                                                                                   |
| runs               | bot\_id, conversation\_id, parent\_run\_id, trigger, status, budget jsonb, tokens\_in, tokens\_out, cost\_usd, started\_at, ended\_at, error                          | Status: queued, running, waiting\_approval, waiting\_takeover, completed, failed, cancelled                               |
| run\_events        | run\_id, seq, type, payload jsonb                                                                                                                                     | Primary key (run\_id, seq); append-only                                                                                   |
| memories           | bot\_id, kind (fact, episode, summary, preference), content, embedding vector, tsv tsvector, importance, pinned, source\_run\_id                                      | Hybrid search                                                                                                             |
| skills             | bot\_id (null = whole org), name, description, body\_md, enabled                                                                                                      | Loaded on demand                                                                                                          |
| routines           | bot\_id, name, instructions\_md, schedule\_cron, timezone, trigger jsonb, enabled, next\_run\_at, last\_run\_id                                                       | Schedule or event trigger                                                                                                 |
| computers          | kind (private, team, local), owner\_bot\_id, provider, provider\_ref, profile (headless, desktop), state, size jsonb, image\_version, last\_active\_at, snapshot\_ref | One team computer per org by default                                                                                      |
| computer\_leases   | computer\_id, holder\_type (bot, user), holder\_id, mode (view, control), expires\_at                                                                                 | Take-control state                                                                                                        |
| checkpoints        | computer\_id, run\_id, label, storage\_ref                                                                                                                            | Undo points                                                                                                               |
| model\_credentials | provider (adds chatgpt), label, base\_url, vault\_secret\_id, owner\_user\_id, status                                                                                 | Keys and tokens live only in Vault; chatgpt credentials are personal (owner\_user\_id)                                    |
| secrets            | name, vault\_secret\_id, allowed\_bot\_ids, allowed\_hosts                                                                                                            | Placeholder secrets with a host allowlist                                                                                 |
| integrations       | kind (mcp, openapi, composio, pipedream), name, config jsonb, vault\_secret\_id, status                                                                               | Org-level                                                                                                                 |
| bot\_integrations  | bot\_id, integration\_id, tool\_allowlist                                                                                                                             | Which bot may use which tools                                                                                             |
| approvals          | run\_id, tool\_name, args\_redacted jsonb, risk, status, decided\_by, decided\_at, expires\_at                                                                        | Status: pending, approved, denied, expired                                                                                |
| channels           | bot\_id, kind, address, config jsonb, vault\_secret\_id, allowed\_senders                                                                                             | Email, SMS, Telegram, Slack, WhatsApp, Messenger                                                                          |
| tasks              | created\_by\_bot\_id, assignee\_bot\_id, title, status, parent\_run\_id, result\_md                                                                                   | Shared task board for multi-bot work                                                                                      |
| devices            | user\_id, platform, fcm\_token, last\_seen\_at                                                                                                                        | Push targets                                                                                                              |
| notifications      | user\_id, kind, payload jsonb, read\_at                                                                                                                               | In-app inbox                                                                                                              |
| local\_devices     | user\_id, name, os, capabilities jsonb, token\_hash, last\_seen\_at                                                                                                   | Companion computers                                                                                                       |
| usage\_ledger      | bot\_id, run\_id, kind, quantity, cost\_usd, source                                                                                                                   | Kinds: tokens\_in, tokens\_out, computer\_seconds, stream\_seconds, tts\_chars, media\_jobs; source chatgpt\_plan costs 0 |
| quotas             | period, max\_cost\_usd, max\_computer\_hours, max\_concurrent\_computers                                                                                              | Checked before and during runs                                                                                            |
| audit\_log         | actor\_type (user, bot, system), actor\_id, action, target\_type, target\_id, metadata jsonb                                                                          | Append-only                                                                                                               |

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
| secret.requested   | request\_id, name, service, allowed\_hosts, reason, expires\_at    |
| secret.resolved    | request\_id, outcome (never a value)                               |
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
| model.fallback     | from\_model, reason, message (a model it could not use, D-091)     |
| run.failed         | error\_code, message                                               |
| run.cancelled      | cancelled\_by                                                      |
| ui.shown           | surface\_id, messages (A2UI v1.0, D-086)                           |

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
| POST     | /v1/credentials/chatgpt/start                | Begin ChatGPT sign-in; returns the authorize URL        |
| POST     | /v1/credentials/chatgpt/complete             | Finish ChatGPT sign-in; tokens go to Vault              |
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
| media.image.generate, media.video.generate                                 | Image and video generation via configured `MediaProvider`     | Medium; requires approval under default autonomy      |

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

- Providers at launch: OpenAI, Anthropic, Google, xAI, OpenRouter, and any OpenAI-compatible endpoint (Ollama, vLLM), plus the user's ChatGPT plan (below).
- Default model: GPT-6 Luna at medium reasoning effort (`openai/gpt-6-luna` on OpenRouter, `gpt-6-luna` on OpenAI), preselected in onboarding, new bots and the CLI, configurable per server and never applied over a model the user picked (D-064).
- Each bot has a primary model, an ordered fallback list and a cheap model for internal steps (memory extraction, summaries, titles).
- Failover on 429, 5xx or timeout, with exponential backoff; every attempt is logged to Langfuse.
- Capabilities per model (tools, vision, context window, caching) live in a registry, which decides which tools and context strategy apply.

### ChatGPT plan sign-in

People with an eligible ChatGPT plan can sign in with ChatGPT instead of adding an OpenAI API key, and their bots' model calls then count against the plan's limits. This uses OpenAI's "Sign in with ChatGPT" plan usage for open-source apps ([developers.openai.com/siwc](https://developers.openai.com/siwc)). Other subscription sign-ins (GitHub Copilot, SuperGrok, Claude plans) stay out until their terms clearly allow third-party apps.

- **Where it is on:** `CHATGPT_SIGN_IN=auto` (the default) turns it on for self-hosted servers and off when billing is on; `on` and `off` override it. OpenAI's open-source route covers them, including an open-source app running on the user's own VM. Casama Cloud ships with it `off` until OpenAI approves hosted use through its interest form. Eligible plans are whatever OpenAI allows (Go, Plus and Pro at the time of writing); other accounts get OpenAI's "not eligible" error, shown in plain words.
- **Personal, never shared:** a `chatgpt` credential belongs to the person who signed in (`model_credentials.owner_user_id`), one per person in each workspace. Only runs on that person's behalf use it: messages they send, routines and webhooks they created, and subruns of those runs. Other members' runs skip it and move to the next model in the bot's chain, or fail with a clear "connect your own plan or key" error. Admins can see that it exists and remove it, but never use or read it.
- **Sign-in (loopback only):** OpenAI accepts only `http://127.0.0.1:<port>/auth/callback` redirects (never `localhost`), so sign-in runs from the desktop app or the CLI (`casama credential chatgpt`). Phones and the web app list connected plans and say "Connect from the desktop app or the CLI". Add phone sign-in if OpenAI adds device code to this flow.
  1. The client picks a free port and calls `POST /v1/credentials/chatgpt/start`. The API stores a single-use flow (15 minutes, service role only, in `integration_oauth_flows`) with the state, nonce and PKCE verifier, and returns the authorize URL: `https://auth.openai.com/api/accounts/authorize` with `response_type=code`; the person's issued `client_id` if they registered before, otherwise `dynamic_agent_client` plus `agent_name_hint` set to the product-name constant; `ext_agent_host_id`; scopes `openid profile email offline_access resource.invoke chatgpt.tokens.use.direct`; `resource=https://api.openai.com/v1`; S256 PKCE; and `login_hint` for returning users.
  2. The client listens on `127.0.0.1`, opens the system browser, receives the code and state (plus the issued `client_id` on a first registration), answers the browser with a "You can close this tab" page, and posts them to `POST /v1/credentials/chatgpt/complete`.
  3. The API exchanges the code at `https://auth.openai.com/api/accounts/oauth/token` (form-encoded, with the verifier, redirect URI and resource; no client secret). It verifies the ID token against OpenAI's published keys (`iss`, `aud` equal to the issued client id, `exp`, `nonce`) and writes the access, refresh and ID tokens and the issued client id to Vault. Tokens never reach the client device, browser storage, logs or run events.
  4. If the person declined plan usage, the credential is saved with `status = plan_usage_off`, and the app offers "Try again" (asks for consent again) or "Add an API key" instead.
- **Host id:** each server has one stable `ext_agent_host_id` (`urn:uuid:…`, generated once into `instance_settings`). It is never an email or a user id, and each self-hosted server is its own host.
- **Refresh:** access tokens last 1 hour; refresh tokens last 30 days and rotate on every use. The worker refreshes within 5 minutes of expiry (not before `earliest_refresh_at`) under a Postgres advisory lock per credential, so parallel runs never race the rotating token, and writes the new pair to Vault in one transaction. The hourly maintenance job refreshes credentials unused for 20 days so routines keep working. Refresh errors (`invalid_grant`, `refresh_token_expired`, `refresh_token_reused` and the like) set `status = needs_reconnect` and notify the owner. Network errors never delete credentials.
- **Model calls:** a `chatgpt` gateway adapter calls `POST https://api.openai.com/v1/responses` with the bearer token, `store: false` and `stream: true`. It sends the history in `input` (no `previous_response_id`), puts system text in `instructions` or developer messages, and drops the fields OpenAI rejects on this route (`temperature`, `top_p`, `max_output_tokens`, `metadata`, `user`, `truncation`, `background` and the rest of OpenAI's preview-limitations list). The model picker lists the `GET https://api.openai.com/v1/models` entries with `visibility == "list"`. Casama's own function tools, images and files work. OpenAI's hosted tools, audio input and transcription do not, so voice, dictation and embeddings still need an API key (without one, memory recall uses full-text search, D-017).
- **Limits and errors** (the HTTP status, `error.code` and request id are kept on the run event and in logs):
  - `subscription_sharing_usage_limit_exceeded` (429, or `response.failed` mid-stream): never retried. The run stops with "Your ChatGPT plan limit is reached" and a "Manage usage" link to ChatGPT Settings → Usage, without guessing a reset time. The gateway moves to the bot's next model only if the owner turned on "Use my next model when my ChatGPT limit is reached". That setting is off by default because the next model may cost money, and the timeline says when it happens.
  - `subscription_sharing_user_not_eligible` (403): explain that the plan is not eligible, without looping back through sign-in.
  - `subscription_sharing_invalid_user` (401): set `needs_reconnect` and notify the owner.
  - `subscription_sharing_usage_unavailable` and `subscription_sharing_user_unavailable` (503): bounded backoff, then the normal failover rules.
  - `subscription_sharing_unsupported_capability` (400): a Casama bug. Report it with `error.param` and never resend the same body.
- **Usage and billing:** plan-backed tokens go to `usage_ledger` with `cost_usd = 0` and `source = chatgpt_plan`, and Casama Cloud never charges credits for them (computer time is still billed). The model picker, bot settings and run timeline show "Using ChatGPT plan". Plus plans share a five-hour limit across every app, so the routine editor warns that routines on a ChatGPT model draw from the same allowance.
- **Disconnect:** revoke the refresh token at the `revocation_endpoint` listed in `https://auth.openai.com/.well-known/openid-configuration`, then delete the Vault secrets. OpenAI does not tell apps when someone disconnects inside ChatGPT, so Casama detects it on the next failed call or refresh.
- **Branding:** the button reads "Continue with ChatGPT" and follows OpenAI's approved branding. It appears in onboarding's model step and in Settings → Model keys.
- **Tests:** a fake OpenAI auth and Responses server (like the fake billing server) covers sign-in, ID-token checks, refresh rotation under concurrency, a limit hit mid-stream, asking for consent again, and revocation. A live check with a real Plus account is a manual launch step.

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

States are `provisioning`, `starting`, `running`, `idle`, `sleeping`, `stopped` and `error`. A computer with no tool calls, open terminals or viewers for 5 minutes goes idle and is put to sleep: its home directory (workspace and browser profiles) is archived to object storage and the container is destroyed. The next tool call or viewer restores it.

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
- **Post-v1 providers:** additional hosted sandboxes (for example Boat, CreateOS, Novita, Railway-backed runners) ship as optional `SandboxProvider` adapters behind the same contract test suite. They are documented and may be partially stubbed in the repo, but v1 gates require only Docker, E2B and Daytona.

## Live streaming and take control

Users watch a bot's desktop live over WebRTC and can take control at any time; the bot pauses while a human holds control and resumes when control is handed back.

### Streaming

- The desktop image runs an open-source WebRTC desktop streamer (Neko, chosen in D-054). The stream starts only when a viewer joins and stops 60 s after the last viewer leaves.
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

MCP is the one integration standard for v1. External messaging channels are specified below for a later release; voice covers dictation, read-aloud and live calls, all with the user's own provider keys.

### Integrations

- **Remote MCP servers** (Streamable HTTP, with OAuth or header auth): tools are listed on connect, cached, and exposed as `mcp.{server}.{tool}`. Re-list on demand and every 24 h.
- **OpenAPI sources:** import an OpenAPI 3 JSON document; each operation becomes a tool with its schema. Auth through named secrets.
- **Composio** and **Pipedream Connect** (v1): org-level adapters behind `integrations.kind = composio | pipedream`. Tools appear when credentials are set; same allowlist and risk model as MCP. Off on self-host until keys are configured.
- **Media generation** (v1): `MediaProvider` interface with a default **fal.ai** adapter (`MEDIA_GENERATION_PROVIDER`, model ids in config, API key in Vault). Tools `media.image.generate` and `media.video.generate` record usage in `usage_ledger`. Additional providers plug in without changing the tool schema.
- Per-bot allowlists decide which integration tools each bot may call; each tool has a risk level the org admin can raise.
- Integration credentials live only in Vault and are never returned by the API.
- MCP servers on the user's own computer (a local command or a `127.0.0.1` address) cannot be reached from the server; they connect through the desktop companion (Post-v1 roadmap: Local MCP servers).

### Channels (post-v1; built in Wave 3, D-134)

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
- **Next:** the companion also hosts local MCP servers and coding agents such as Claude Code, Codex and Cursor's command-line agent (Post-v1 roadmap: Local MCP servers, Coding agents).

## Flutter client

One Flutter app ships to web, iOS, Android, macOS, Windows and Linux, organized by feature, with adaptive layouts: bottom navigation on phones, a navigation rail on tablets and a three-pane layout (bots, chat, computer) on desktop and web.

### Architecture

- **Feature-first folders** under `lib/features/<name>/` with `data/` (repositories), `application/` (Riverpod notifiers) and `presentation/` (widgets).
- **Riverpod** with code generation for state; **go\_router** with deep links (`/bots/:id/chat`, `/computers/:id/live`, `/approvals/:id`) used by push notifications.
- **Data:** `supabase_flutter` for reads and simple writes; the generated `casama_sdk` client (openapi-generator, dart-dio) for commands; one `RunEventStream` service merges Realtime events with the catch-up endpoint and orders by `seq`.
- **Offline cache:** `drift` stores conversations, messages and bots so chats open instantly; server data always wins on sync.
- **Models:** `freezed` and `json_serializable`; event payloads come from the generated client.

### Packages

| Need                      | Package                                                     |
| ------------------------- | ----------------------------------------------------------- |
| Backend                   | supabase\_flutter, generated casama\_sdk (dio)              |
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
7. **Bot settings:** persona, model and fallbacks, autonomy, budget, memory, skills, routines, integrations, chat apps (D-134).
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
| `casama` CLI            | Dart, compiled per OS with `dart compile exe`. Commands: `login`, `org`, `bot`, `chat` (streams tokens and tool steps), `runs watch`, `memory`, `computer shell`, `computer files`. Later: `selfhost install`, `upgrade`, `backup` | 0 to 2, 8 |
| `computerd`             | Dart daemon inside each computer: exec with streaming, files, mouse and keyboard input, screenshots, health. One small static binary, so the image needs no extra runtime for it                                                   | 2         |
| `casama_sdk`            | Generated API client, typed run events and a `RunEventStream` helper that merges Realtime with catch-up by `seq`. Used by the app, CLI and companion; published to pub.dev                                                         | 0, 6      |
| Home-screen widgets     | Bot status and a quick-ask button on iOS and Android (`home_widget`)                                                                                                                                                               | 6         |
| iOS Live Activities     | A running bot's progress on the lock screen and Dynamic Island (`live_activities`)                                                                                                                                                 | 6         |
| Share to bot            | Send links, text and files from any app to a chosen bot (`receive_sharing_intent`)                                                                                                                                                 | 6         |
| Desktop hotkey and tray | Global shortcut opens a quick-ask window; tray or menu-bar status (`hotkey_manager`, `tray_manager`)                                                                                                                               | 6         |
| Owner admin console     | Owner-only screens in the same app: users, providers, quotas, system health, update notices                                                                                                                                        | 6         |
| Desktop companion       | Bot computer on the user's own machine (see Local computer companion)                                                                                                                                                              | 6         |

**CLI rules:** every CLI command calls only public API endpoints through `casama_sdk`, so the CLI doubles as an end-to-end test of the backend. Output supports `--json` for scripting. Release binaries for macOS, Linux and Windows on GitHub Releases, plus a Homebrew tap.

## Security and privacy

The main threats are a bot being hijacked by content it reads, one tenant reaching another's data or computer, and leaked credentials; each has a specific control below.

| Threat                                               | Control                                                                                                                                                     |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Prompt injection from web pages, emails, tool output | Untrusted-content labeling, approval required for risky tools after untrusted input, secrets never in model context                                         |
| Cross-tenant data access                             | RLS on every table, server queries under the user's claims, pgTAP isolation tests in CI                                                                     |
| Sandbox escape or lateral movement                   | gVisor runtime, non-root user, per-computer networks, egress proxy blocking private ranges, resource limits                                                 |
| Leaked model keys or secrets                         | Supabase Vault only, host allowlists per secret, output redaction, never returned by the API                                                                |
| Account takeover                                     | Two-step sign-in (TOTP), required for owners and admins by workspace setting; `aal2` on sensitive routes                                                    |
| Abuse (spam, scanning, crypto mining)                | Outbound rate limits, CPU quotas, usage alerts, sign-up checks, verified email before free computers, mining and spam detection, account suspension tooling |
| Stolen stream or control session                     | 5-minute tokens bound to user, computer and mode; signaling only through the API                                                                            |
| Unauthorized channel commands                        | Webhook signature checks, sender allowlists per bot                                                                                                         |
| Compromised dependencies                             | Lockfiles, Dependabot, image scanning in CI, pinned agent-browser and agent-desktop versions                                                                |

**Other requirements**

- TLS everywhere; HSTS and a strict Content Security Policy on the web app.
- Admin actions, approvals, lease changes and credential changes go to `audit_log`.
- **Privacy (GDPR-style rights):** data export as a ZIP, account deletion that purges data and computer snapshots within 30 days, a retention setting for run events (default 180 days), a privacy policy and a named data protection contact.
- Never log message content or tool arguments at info level; Langfuse traces redact secrets and can be turned off per org.
- A `SECURITY.md` with a vulnerability reporting address.

## Observability, testing and evals

A nightly eval suite is the quality gate: no prompt, model, tool or context change merges if it lowers the task success rate.

### Observability

- **Traces:** OpenTelemetry spans from API to worker to supervisor to computerd, with run\_id and org\_id as attributes; export to an OTel collector.
- **Errors:** one reporter on server, supervisor and Flutter: the Sentry SDKs (to Sentry or GlitchTip by DSN) or PostHog error tracking (cloud or self-hosted by host). Off by default; payloads never carry secrets, prompts or message contents (D-063).
- **LLM traces:** Langfuse (self-hosted) for every model call, with token counts and cost.
- **Product analytics and flags:** PostHog, optional (off without a key, any host); risky features ship behind flags to 10% of users first.
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

Production for 100 users runs on one app server and one sandbox server in a region you choose, at roughly $200 to $450 a month before model costs; self-hosters get the same stack from one Docker Compose file.

### Hosted production (about 100 active users, 200 bots)

| Component      | Spec                                                                                                                                 | Approx. USD per month |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------ | --------------------- |
| App server     | Cloud VPS, 4 to 8 vCPU, 16 GB RAM: Caddy, API, worker, coturn, egress proxy                                                          | 30 to 60              |
| Supabase       | Supabase Cloud (your region) or self-hosted on the app server                                                                        | Plan dependent        |
| Sandbox server | Dedicated, 16+ cores, 64 to 128 GB RAM, NVMe: supervisor and computers (30 to 40 concurrent)                                         | 150 to 350            |
| Object storage | Cloudflare R2 for hosted (no egress fees; every wake downloads a whole home directory); self-hosted uses the filesystem or SeaweedFS | 10 to 20              |
| Overflow       | E2B or Daytona, per-second billing, only when the sandbox server is full                                                             | Usage based           |

Prices are estimates and providers raised prices several times in 2026; confirm current pricing before ordering. Pick cloud regions close to your users.

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
- **Sleep on idle:** 5 minutes without activity puts a computer to sleep in object storage. A computer switched to the desktop only for a takeover wakes up headless afterwards (D-178).
- **Cheap model for internal steps:** memory extraction, summaries, titles and routing never use the primary model.
- **Prompt caching and compaction** keep long-running bots from growing more expensive each day.
- **Budgets:** each bot has a per-run and a daily cost cap; subagents inherit a share of the parent's budget.
- **Quotas per organization:** monthly cost, computer hours and concurrent computers. Checked at run start and after every model step; when exceeded, the run stops cleanly and the owner is notified.
- **Ledger:** every token, computer-second, stream-second, TTS character, and media generation job is written to `usage_ledger`, which feeds the per-bot cost meter in the app.
- **Bring-your-own keys or the user's ChatGPT plan** by default, so model costs are paid by users. Paid plans and credits come later through Dodo Payments on top of the same ledger (see Monetization).

## Monetization

Self-hosting stays free; revenue comes from Casama Cloud plans, usage credits and Cloud Connect, billed through Dodo Payments on web and desktop and through Apple and Google subscriptions on mobile. No Stripe. The full build is Phase 7; Phase 0 only adds `plans` and `entitlements` stubs with one default self-host plan, so billing later needs no data migration.

### Revenue streams

| Stream             | Who pays                       | How                                                                                                                 |
| ------------------ | ------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| Casama Cloud plans | Hosted users                   | Monthly or yearly subscription with included computer hours and model credits                                       |
| Usage credits      | Hosted and Cloud Connect users | Prepaid or metered credits for computer time, model tokens and phone numbers                                        |
| Cloud Connect      | Self-hosters                   | An API key lets a self-hosted instance use cloud computers, model credits and channels, billed to its cloud account |
| Enterprise license | Companies that self-host       | Commercial license for `ee/` features: SSO and SAML, advanced roles, audit export, priority support                 |

Plan names, prices and limits are open decisions; the system supports any number of plans.

### Payment sources

- **Dodo Payments** for web, desktop, Cloud Connect and enterprise. Dodo is the merchant of record, handling sales tax, VAT, fraud screening and chargebacks ([Appwrite integration page](https://appwrite.io/integrations/dodo-payments-subscriptions)). Use its hosted checkout and customer portal; verify every webhook with the Standard Webhooks signature; send usage events for metered credits ([Better Auth plugin docs](https://www.better-auth.com/docs/plugins/dodopayments)).
- **Apple App Store** for iOS: auto-renewable subscriptions through Flutter's `in_app_purchase`, verified with the App Store Server API, with renewals and refunds from App Store Server Notifications V2.
- **Google Play** for Android: Play Billing subscriptions through `in_app_purchase`, verified with the Play Developer API, with real-time developer notifications for renewals, cancellations and refunds.
- **Store rule:** digital subscriptions bought inside the iOS app must use Apple in-app purchase ([Mondaq](https://www.mondaq.com/unitedstates/it-and-internet/1825852/update-your-app-external-purchase-developments-for-apple-google)). Links to web checkout are allowed on the US storefront only and are still a violation in most other regions ([Stora guide](https://stora.sh/blog/2026-05-16-apple-app-store-external-purchase-links-implementation-guide)); outside the US, show in-app purchase for digital subscriptions. Re-check store rules every quarter.

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

The aim is the shortest path from discovering Casama to a working bot, plus public numbers that show growth to users and investors. Repo basics start in Phase 0; the public launch is Phase 8.

### License and governance

- **Apache-2.0** for everything outside `ee/`, which keeps adoption friction low for individuals and companies.
- **`ee/`** holds enterprise features under a commercial license: the code is readable, production use needs a license.
- **DCO sign-off** on every commit instead of a contributor license agreement, so contributing stays easy.
- Public roadmap on GitHub Projects, a changelog for every release, semantic versioning, and a `GOVERNANCE.md` naming maintainers and how decisions are made.

### Fast adoption

- **Under 5 minutes to a first bot:** one-command install, one-click deploy templates (Railway, Render, DigitalOcean, Coolify) and a free hosted tier.
- **README that sells:** one-line pitch, 60-second demo video, install command, screenshots, and what Casama does that closed agent products don't (self-hosting, any model, your own computers).
- **Try without paying:** local models through Ollama, or a ChatGPT plan the user already pays for, so a first bot needs no API key.
- **Ecosystem hooks:** a community repo of skills and bot templates, a Casama MCP server so people control their bots from AI coding tools, and public SDKs (Dart on pub.dev, TypeScript on npm).
- **Docs site** with quick start, self-hosting, API reference generated from OpenAPI, and guides per use case.
- **English-first docs and UI**; additional locales via ARB files when there is demand.

### Community and launch

- Discord, `good first issue` labels, a contributor guide with one-command local setup, and a monthly community call.
- **Launch order:** private beta with testers from Phase 3, then Show HN, Product Hunt, r/selfhosted and r/LocalLLaMA, with build-in-public posts on X and short demo videos throughout.

### Metrics for investors

- **Opt-in anonymous telemetry** for self-hosted instances (instance count, weekly active bots, version), documented in the README and easy to turn off.
- **Track weekly:** GitHub stars, active self-hosted instances, weekly active users and bots, cloud MRR and month-over-month growth, paid conversion, 4-week retention.
- Publish a monthly update post with these numbers. Accelerators like Y Combinator weigh traction and growth rate most, so this data is what makes an application strong; no plan guarantees acceptance.

## Post-v1 roadmap

After launch, Casama builds these features to lead the open-source agent platforms instead of matching them. They come in four waves; build each wave in the order listed unless the product owner reorders it. Each row's acceptance criterion is the test that proves it works, and every item follows the v1 rules (contracts first, RLS and policy tests on every new table, ARB strings, tests in CI).

| Area                   | Feature                                                                                                                                                                                         | Acceptance criterion                                                                                                                                                                 | Wave |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---- |
| Local MCP servers      | Bots use MCP servers running on the user's own computer, through the desktop companion                                                                                                          | A bot calls a stdio MCP server on the user's Mac and a loopback one, with the overlay showing each call                                                                              | 1    |
| Coding agents          | Bots hand coding tasks to Claude Code, Codex or Cursor on the user's computer or the bot's, or to cloud coding agents                                                                           | A bot hands a fix to Codex on the user's Mac and to a cloud agent, and reports each diff or pull request link                                                                        | 1    |
| Ticket board           | Columns (to do, in progress, in review, blocked, done), owners, priorities and comments; assigning a bot starts its work                                                                        | Assigning a ticket to a bot moves it to in progress within 5 s, and the bot's comments and result appear on the ticket                                                               | 1    |
| Spaces                 | Create and switch workspaces from the app; invite links                                                                                                                                         | A bot in one workspace cannot reach another's memory, files, connections or secrets; a revoked or expired invite link stops working                                                  | 1    |
| Bots that manage bots  | Bots create and edit bots, models and schedules, organize the sidebar and change their own settings                                                                                             | A bot creates a new bot with a routine from chat, and cannot raise any autonomy, budget or tool access above its own                                                                 | 1    |
| Ask for a secret       | `secrets.request` shows a protected card where the user saves a key tied to one service                                                                                                         | The value never appears in messages, events, logs or model input, and works only for its service's hosts                                                                             | 1    |
| Sign-in codes for bots | One-time codes from a stored two-step seed, typed only into the seed's sites                                                                                                                    | A bot signs in to a test site that asks for a code; the seed never appears in events, logs or model input                                                                            | 1    |
| Search                 | Search across chats, memories, skills, routines, tickets, pages and file names                                                                                                                  | A word from a month-old message finds it in under 1 s and opens the chat at that message; RLS hides other workspaces                                                                 | 1    |
| Skills library         | Catalog, GitHub import, "save that as a skill", and a `/` picker in the composer                                                                                                                | A skill imported from a GitHub repo loads on demand; "save that as a skill" creates one the user can edit                                                                            | 1    |
| Setup and starter bots | A setup interview for new bots; starter bots for common jobs, including a coordinator                                                                                                           | A new bot asks its setup questions, then proposes its instructions, routines and connections for approval                                                                            | 1    |
| Lazy tool loading      | The model starts with core tools and loads the rest when it needs them                                                                                                                          | For bots with 30+ tools, input tokens drop at least 30% and eval success does not drop                                                                                               | 1    |
| Run tracing            | OpenTelemetry spans for every run, model step and tool call; Langfuse attempt logging                                                                                                           | One trace shows a run's model and tool steps with timing, tokens and cost, and no prompt text                                                                                        | 1    |
| App polish             | Edit and resend, quiet hours, bot settings history, share a bot as a template, Siri and Android shortcuts, offline cache                                                                        | Each works on its platforms; an edited message reruns from that point and keeps the old branch                                                                                       | 1    |
| Projects               | A goal with a plan, milestones, tickets, budget and deadline; the lead bot works in sessions until the goal is met                                                                              | A multi-session project reaches done with no person between milestones, stops cleanly at its budget and resumes after a restart                                                      | 1    |
| Check-ins              | Opt-in morning brief, scans of connected accounts every few hours, and a "For you" feed of suggested actions                                                                                    | The 08:00 brief lists today's meetings and emails needing replies; accepting a suggestion runs it through approvals; a quiet scan sends no push                                      | 1    |
| Action rules           | Per-action autonomy: allow, allow within limits, ask, or hand off, by tool, category or target                                                                                                  | Email to the user's domain sends without approval and external email waits; a bot cannot change its own rules                                                                        | 1    |
| Watchers               | "Tell me when": wake a bot when a page changes, a reply arrives, a query result changes or a time passes                                                                                        | A page watcher fires within one check interval of a change, and unchanged checks use no model tokens                                                                                 | 1    |
| Hosted MCP endpoint    | The existing `@casama/mcp` tools (D-077) served over HTTP at `/mcp`, so AI apps connect by URL with no install                                                                                  | A remote MCP client connects by URL with OAuth, sends a task to a bot and gets the result; a high-risk step waits for approval                                                       | 1    |
| Group chats            | 2 to 10 bots in one chat, woken by `@Name` or `@everyone`                                                                                                                                       | `@everyone` gets a plan from the lead bot and work from each assigned bot; `@Name` wakes only that bot                                                                               | 2    |
| Pages                  | Full-screen dashboards and reports with public links, PDF export and refresh by routine                                                                                                         | A public link shows the page signed out and returns 404 once revoked; a routine refreshes it                                                                                         | 2    |
| Teach by showing       | Record a task on the bot's computer and turn it into a skill                                                                                                                                    | After one recorded demo, the bot completes the same form with new values; no typed password is stored                                                                                | 2    |
| Plugins                | Install Agent Plugins 1.0 packages from GitHub                                                                                                                                                  | A plugin with a stdio MCP server and a skill installs, runs in the bot's computer and uninstalls cleanly                                                                             | 2    |
| Import an agent        | Import OpenClaw or Hermes Agent folders, and ChatGPT or Claude memory                                                                                                                           | An imported folder becomes a bot with its persona, skills, routines and memories after a review step                                                                                 | 2    |
| Routines as files      | Routines and skills as Markdown files, synced with a git repo                                                                                                                                   | Editing a routine file in the repo changes the routine; editing it in the app updates the file                                                                                       | 2    |
| Knowledge sources      | Uploaded documents, Drive folders, Notion pages and websites, indexed for bots to search with citations                                                                                         | A bot answers a question from an uploaded PDF and cites the page; a Drive change shows up after the next sync                                                                        | 2    |
| Self-improving skills  | Bots propose a skill after repeating a task and propose fixes when a skill fails                                                                                                                | When a task matches two earlier runs the bot offers a skill; a failure produces a proposed fix shown as a diff                                                                       | 2    |
| Step replay            | Replay recorded browser and desktop steps without model calls; the bot takes over when a step breaks                                                                                            | A recorded form fill replays with new values at zero model tokens, and recovers after the page layout changes                                                                        | 2    |
| Password managers      | 1Password and Bitwarden logins filled into the bot's browser without the model seeing them                                                                                                      | A bot signs in with a vault item; the password never appears in events, logs or model input; other sites are refused                                                                 | 2    |
| Welcome chat           | New users land in a chat with a ready personal bot that asks what to focus on, then shows a matching intro, one relevant connection and a first task; the form wizard becomes "Set up manually" | A new user goes from sign-in to a first suggested task without a form; picking Coding offers GitHub, not Google; with no model, the scripted questions and the model card still show | 2    |
| Bot sharing            | Per-bot access (chat, edit, admin) and private bots; a bot acting for a person sees only what that person can                                                                                   | A chat-only member cannot edit a bot; a bot asked by member A cannot read a folder only member B can see                                                                             | 2    |
| Calendar triggers      | Routines start a set time before or after calendar events (connected Google or Outlook), with the event in context                                                                              | A routine set for 15 min before meetings with outside guests runs within 1 min of that time and skips other events                                                                   | 2    |
| Bot-to-bot switch      | An admin setting stops bots from messaging, @mentioning and delegating to each other in a workspace                                                                                             | With the switch off, a bot's @mention of another bot is not delivered and the timeline says why; subagents still work                                                                | 2    |
| Chat apps              | Telegram, email, Slack, WhatsApp, SMS, iMessage, Feishu and Messenger; routines started by an email or chat message                                                                             | The channel gate passes, and an email that matches a routine's filter starts that routine                                                                                            | 3    |
| Phone-call voice       | The bot calls the user with a native incoming-call screen                                                                                                                                       | The phone rings on the lock screen on iOS and Android; answering starts the live call within 2 s                                                                                     | 3    |
| Encryption at rest     | Content encrypted before it reaches Postgres, with a local key or AWS KMS                                                                                                                       | A database dump shows no message, event, memory or summary text, and the app works unchanged                                                                                         | 3    |
| Memory backends        | Honcho and Supermemory beside the built-in store                                                                                                                                                | The memory test suite passes on all three backends                                                                                                                                   | 3    |
| Paid data services     | Bots buy data (places, emails, SEO) through Treg, charged to credits                                                                                                                            | The approval card shows the price, and the credit ledger charges cost plus 20%                                                                                                       | 3    |
| Sandbox providers      | Boat, boxd, CreateOS, Novita, Railway, Kubernetes, Incus and Alibaba Wuying                                                                                                                     | Each passes the provider contract suite                                                                                                                                              | 3    |
| Agent-to-agent         | Bots published as A2A agents, and external A2A agents callable by bots                                                                                                                          | An external A2A client gets a task done by a bot; a bot hands a task to an external A2A agent and gets the result                                                                    | 3    |
| Calls for you          | The bot phones businesses for the user, with a live transcript, listen-in and take-over                                                                                                         | The bot books a slot on a test line, the transcript streams live, and the user takes over mid-call                                                                                   | 3    |
| Payments               | Single-use virtual cards for an approved amount and merchant; hard bans no rule can relax                                                                                                       | A test purchase succeeds once; a second or larger charge declines; a gift-card purchase is refused                                                                                   | 3    |
| Linked agents          | A person's bot coordinates with a trusted contact's bot, across workspaces or servers                                                                                                           | Two users' bots agree a meeting time without either seeing the other's calendar details; revoking the link stops requests                                                            | 3    |
| Voice upgrades         | Wake word, interrupting the bot mid-sentence, and an optional animated avatar in live calls                                                                                                     | The wake word opens a live call within 1 s; speaking over the bot stops its speech within 300 ms                                                                                     | 3    |
| Ops extras             | Infisical, audit-log forwarding, Cloudflare AI Gateway, one-click local server, sign-up allowlist, encrypted backups, team computer folders, Helm chart, warm pool                              | Each works on a fresh self-hosted install                                                                                                                                            | 3    |
| Device connections     | Bots use data the user shares from their phone and computer: calendar, reminders, contacts, named places, photos, and Android notifications from apps they pick                                 | A bot with calendar access answers "what's on tomorrow" from the phone and a bot without it cannot; turning a type off deletes its stored data                                       | 4    |
| Health data            | Daily summaries from Apple Health and Health Connect (sleep, activity, workouts, heart) for the bots the user allows, optionally on a private model only                                        | The wake-up brief cites last night's sleep from a test device; model input holds the summary only, never raw samples                                                                 | 4    |
| Device triggers        | Routines start when the user wakes up, arrives at or leaves a named place, needs to leave for an event, finishes a workout, or gets a notification from a watched app                           | Arriving at Home on a test device starts the routine within 2 min; no GPS trail is stored                                                                                            | 4    |
| Desktop context        | Quick ask attaches the selection, front window, browser tab or a screenshot; bots search the user's files, watch folders and write an end-of-day recap                                          | The hotkey on selected text in any app sends it with the window title; a PDF dropped in Downloads starts a "file it" routine                                                         | 4    |
| Attention rules        | Proactive messages wait while the user is asleep, focused, driving or in a meeting unless urgent, and each says why it was sent                                                                 | A non-urgent suggestion during a calendar meeting arrives in the next brief instead of as a push                                                                                     | 4    |
| About you              | Each person keeps one profile every bot reads: what to call them, pronouns, about me, how they like replies, and facts bots learn in chat                                                       | A name set in About you is used by a bot in another workspace; a fact learned in a personal space never reaches a team space unless the person turns it on there                     | 4    |

### Local MCP servers on the user's computer

Bots think on the server, so today they reach only remote MCP servers by URL. MCP servers on the user's own machine (a local command, or a `127.0.0.1` address) need the desktop companion, which already holds a WebSocket to the API.

- In the desktop app, under "Use this computer for bots", the user adds local MCP servers: a command with arguments and a working folder inside a shared folder (stdio), or a loopback address (only `127.0.0.1` or `::1`). Environment values for a server, such as tokens, stay in the app's secure storage on the device and never go to the server. A new companion capability, "Local tools (MCP)", is off until the user approves it, and each server is approved separately.
- The companion starts stdio servers when a bot first needs them and stops them after 10 idle minutes, or forwards to the loopback address. MCP messages travel over the existing device WebSocket, and the worker uses an MCP transport over that tunnel. This works the same on Casama Cloud and on self-hosted servers.
- Each server is an integration of kind `local_mcp` (config: device, computer, owner, server key, label, summary, timeout; nothing secret), registered by the app through `PUT /v1/local-devices/{id}/mcp-servers` and attached at first to the bots that computer allows. Only the computer's owner attaches it to other bots. Tools are listed like other integration tools (D-053) and marked with the device they run on. Each tool's approval level is set as in D-089 (read-only, makes changes, always asks), and the companion's rule that high-risk actions always ask still applies (D-096).
- Calls show on the companion overlay with the bot and tool name, and Stop cancels the run and sends MCP cancellation. When the device is offline, its tools fail fast with a clear error. Tool output is untrusted content.
- Long calls: a server can allow calls up to the run's wall time (default 30 minutes). MCP progress notifications appear on the run timeline while the run waits durably.
- Desktop apps that offer neither MCP nor a command-line tool are driven through the companion's desktop control (accessibility tree, screenshot fallback).

### Coding agents

- One tool, `coding.delegate(agent, task, where, repo or folder, branch)`, behind a `CodingAgentProvider` interface: start, progress, cancel, and a result with a summary, diff stats and a branch or pull request link. It is medium risk, and high risk when the agent may push or open a pull request. The run waits durably and posts progress to the timeline; the result lands in the chat, and on the ticket when the work came from the board.
- **On the user's computer** (through the companion's shell permission and shared folders): the agents' headless modes, `claude -p`, `codex exec --full-auto` and `cursor-agent -p`, using the user's own installs, sign-ins and plans. The desktop app lists the agents it finds and turns on commands in one tap. (`claude mcp serve` exposes Claude Code's individual tools, not a whole-task agent, so it is not the delegation route; Codex's own MCP server can be added as a local MCP server when wanted.)
- **On the bot's computer:** `coding.delegate` installs the agent's command-line tool on first use and starts it with credentials from Vault in that process's environment only; they are redacted from output. Codex can use the owner's ChatGPT plan (ChatGPT plan sign-in) or an OpenAI key; Claude Code and Cursor use API keys. Claude subscription sign-ins are not used on hosted computers until Anthropic's terms clearly allow it.
- **In the cloud:** Cursor's background agents API first; other cloud coding agents plug in when they offer a public API for starting tasks.

### Ticket board

- `tasks` gains the statuses `todo`, `in_progress`, `in_review`, `blocked` and `done` (`doing` becomes `in_progress`), plus `priority` (urgent, high, medium, low, none), `assignee_user_id` so people own tickets too, `due_at`, `labels`, `position` for order within a column, and `conversation_id` for the ticket's work thread. New `task_comments` (task\_id, author\_type user or bot, author\_id, body\_md).
- The board screen has one column per status, drag to move, filters by owner, bot and priority, and a ticket sheet with details, comments, linked runs and history. It replaces the read-only list in the Inbox and gets its own navigation entry.
- Assigning a bot starts a run (trigger `task`) in the ticket's thread. The bot moves the ticket to in progress and comments as it works. It finishes in review when the ticket asks for review, otherwise done with a result, or blocked with a reason that notifies the owner. A person's comment on a bot's ticket wakes that bot.
- Tools: `tasks.create` and `tasks.update` take the new fields; new `tasks.list` and `tasks.comment`.

### Spaces

- A space is an organization, which already keeps its own bots, memory, team computer, connections, secrets, billing and members. No new isolation layer is needed; the work is in the app.
- App: "New workspace" from anywhere (not only onboarding), a one-tap switcher at the top of the navigation, an icon and color per workspace, unread and approval badges per workspace, and notifications that name their workspace and switch to it when opened.
- Invite links: `invite_links` (org\_id, role, token\_hash, expires\_at, max\_uses, uses, revoked\_at). Admins create, copy and revoke them. Joining needs sign-in and adds the member with the link's role. Email invites stay.
- The UI word is an open decision (see Open decisions).

### Bots that manage bots

- Tools: `bots.list`; `bots.create` (from a template or a spec: name, instructions, model, autonomy, computer); `bots.update` (instructions, model policy, autonomy, budget, computer), which a bot can also call on itself; `bots.archive`; and `sidebar.organize` (folders and pin order, through a new `bot_folders` table and `bots.folder_id` and `bots.sort_key`). Schedules use the existing `routines.*` tools, which gain a `bot` argument.
- Limits: a bot can never give any bot, itself included, more autonomy, budget or tool access than it has, or more than its owner's role allows. Creating, archiving and any increase are high risk; other edits are medium. Every change goes to `audit_log` and shows as a card in chat with Undo (backed by bot settings history).
- The coordinator starter bot uses these tools to build and run a small team.

### Ask for a secret in chat

- Tool `secrets.request(name, service, allowed_hosts, reason)`. `allowed_hosts` is required and must belong to one service (one registrable domain and its subdomains).
- The run waits durably, like an approval, and the chat shows a protected card with the service, hosts, reason, a masked field and Save. The value goes from the card straight to `POST /v1/secrets/requests/{id}/fulfill` and into Vault; it never enters the composer, drafts, messages, events, logs or model input. Phones get a push that opens the card.
- The run resumes with only "Saved NAME for SERVICE" and uses `{{secret:NAME}}` as it does today. Declining, or a 24-hour timeout, resumes it with that answer.

### Sign-in codes for bots

- Secrets gain `kind` (value or `totp`). A `totp` secret holds a two-step seed, added by pasting an `otpauth://` link, scanning its QR code on a phone, or through `secrets.request`.
- Bots write `{{totp:NAME}}` where a code goes. The executor turns it into the current code only at execution time, only for tools that accept secrets (such as `browser.fill`), and only on the secret's allowed hosts. Codes are redacted from output like other secrets, and the seed never leaves Vault.

### Search

- One search box (Cmd/Ctrl+K on desktop and web, a search tab on phones) over messages, memories, skills, routines, tickets, pages and file names, grouped by type. Results jump to the exact message or item.
- Postgres full-text search (a `tsv` column on message text) plus trigram matching for names, through an RLS-respecting function, so results never cross workspaces. File contents are searched only on computers that are awake, through `computerd` search.
- With encryption at rest on, search covers names and titles only.

### Skills library

- Skills use the open Agent Skills format (a folder with a `SKILL.md` file and front matter, plus optional files), so community skills work unchanged. Extra files live in object storage and sync to `~/skills/<name>/` on the computer when the skill loads.
- Catalog: curated skills ship in the repo's `skills/` folder with each release. The app browses them with search and categories and installs a skill to the workspace or to one bot.
- GitHub import: a repo or folder URL, public or private through the GitHub connection. Casama pins the commit, shows the files before install and shows a diff before any update. Scripts in a skill run only on the computer.
- Save as a skill: new tools `skills.create` and `skills.update` (medium risk; the approval card shows the text or the diff). "Save that as a skill" turns the method used in the conversation into one.
- `/` picker: typing `/` in the composer lists skills; picking one attaches it to the message so the run loads it up front.

### Setup and starter bots

- Setup interview: a new bot opens with three to six questions as A2UI cards (the work, how the user likes things written, which tools and accounts, any schedule). It then proposes its instructions, a few memories, connections to add and routines, all for approval. It can be skipped and rerun from bot settings.
- Starter bots for jobs the persona gallery lacks: inbox triage, outbound sales research, recruiting screens, bug triage, expense matching, and a coordinator that plans work and hands it to other bots.

### Lazy tool loading

- When a bot has more than 30 tools (configurable), the model starts with core tools (memory, skills, tasks, notify and `tools.load`) and a byte-stable index of tool groups, one line each. `tools.load(groups or names)` adds the full definitions for the rest of the run.
- When the model registry says a provider supports deferred tools natively, use that instead of `tools.load`.
- Loaded tools are added after the cached prefix so prompt caching keeps working. Evals compare token use and success with lazy loading on and off.

### Run tracing

- One trace per run, with spans for the run, each model step (model, tokens, cost, cache hits, failover attempt) and each tool call (name, risk, duration, outcome). Spans follow OpenTelemetry's GenAI conventions and never carry prompt or tool content. `runs.trace_id` links the timeline to the trace.
- Langfuse logging of every model attempt (already in Model gateway, not yet built) behind a config switch, with the same redaction.

### App polish

- **Edit and resend:** editing a sent message forks the conversation at that point and reruns it. The old branch stays, and arrows switch between branches.
- **Quiet hours** per user, with an override per bot. Pushes wait until quiet hours end, except approvals marked urgent; bot phone calls respect them too.
- **Bot settings history:** `bot_revisions` records every change to instructions, model policy, autonomy, budget and computer, with who made it. Any revision can be restored.
- **Share a bot as a template:** export a bot's instructions, skills, routines and suggested connections (never secrets; memories only if chosen) as a file or link. Importing shows a preview first. This feeds the community template repo.
- **Shortcuts:** App Intents for Siri and Shortcuts on iOS and macOS, and app shortcuts on Android, for "Ask a bot" and "Run a routine".
- **Offline cache** (D-112): a drift cache of bots, conversations and recent messages, so chats open instantly and can be read offline.

### Projects

- `projects` (org\_id, title, goal\_md, done\_criteria\_md, status planning, active, paused, blocked, done or cancelled, lead\_bot\_id, owner\_user\_id, budget\_usd, deadline\_at, plan\_md, version). Tickets gain `project_id`, `parent_task_id` and `milestone`; conversations, routines, watchers and pages can link to a project.
- **Plan first:** the lead bot drafts milestones and tickets from the goal, and the owner approves or edits the plan before work starts. Milestones can require the owner's sign-off before the next one begins.
- **Sessions:** each session is a normal run (so the 40-step and 30-minute limits still apply) that picks the next ready tickets, works them or assigns them to other bots or subagents, and ends by updating `plan_md` with what was done, what is next and any blocker. A DBOS project heartbeat starts the next session when tickets are ready, and stops when the project is paused, blocked, done, over budget or past its deadline. All runs carry `project_id`, so spend is summed per project.
- Each session posts a short status to the project thread; a blocked project notifies the owner with the question. The project folder is `projects/<slug>/` on the lead bot's computer (the team computer when several bots work on it).
- Project screen: goal, progress by milestone, the board filtered to the project, spend against budget and a timeline across every run. Tools: `projects.create`, `projects.plan`, `projects.update` and `projects.status`.

### Check-ins

- Off by default, per bot. A morning brief at a set time in the owner's timezone, plus a scan of the bot's connected accounts, tickets, projects and watchers every few hours (default 3, minimum 1). Both are routines (`routines.kind` brief or scan) and run on the bot's cheaper model with a daily spend cap.
- Scans write `suggestions` (org\_id, bot\_id, user\_id, title, body\_md, proposed\_action jsonb, sources, urgency, status pending, accepted, dismissed or expired, expires\_at). Accepting runs the proposed action through normal approvals; dismissing can save a "don't suggest this" memory. A scan that finds nothing new writes nothing and sends nothing.
- Home gets a "For you" feed per workspace: the latest brief, pending suggestions, approvals and pinned pages. Only urgent suggestions push, and quiet hours apply.

### Action rules

- `action_rules` (org\_id, bot\_id or null for the workspace, match by tool, tool group or category such as send, pay, delete, publish, share or sign\_in, an optional target such as a domain, recipient list or amount limit, and a rule: allow, allow within limits, ask or hand off). Hand off means the bot prepares the step and asks the person to finish it through take control.
- The most specific rule wins and ask or hand off wins ties. The autonomy level stays as the default when no rule matches, and "always allow this tool" ticks become rules. Changing passwords and two-step settings is always hand off. Bots, including bots that manage bots, cannot edit rules.
- A rules screen per bot, grouped by category, with plain-language previews ("Sends email to anyone at acme.com without asking").

### Watchers

- `watchers` (bot\_id, kind page\_change, reply, query or time, target, condition\_md, check\_every, expires\_at, what to run on a match, last\_value\_hash). Page watchers fetch through the egress proxy, or in the bot's browser for signed-in pages, and compare a chosen part of the page. Reply watchers listen to connected email, chat and ticket events; query watchers rerun an MCP or API call and compare the result.
- Checks run in the worker without a model; only a match wakes the bot, with the change. "Tell me when…" in chat creates one through `watchers.create`, and the bot's screen lists active watchers with pause and delete.

### Hosted MCP endpoint

- `@casama/mcp` (D-077) already gives local MCP clients the tools `list_workspaces`, `list_bots`, `ask_bot`, `get_run`, `list_approvals` and `decide_approval` over stdio. The API now also serves the same tools over Streamable HTTP at `/mcp`, sharing one tool implementation, so web and mobile AI apps that only take a URL can connect.
- Auth is OAuth (the MCP authorization flow, with dynamic client registration) or a workspace API key. Runs keep the bot's approvals, rules and budgets, and `decide_approval` over MCP is off unless the workspace allows it. The docs give copy-paste client configs.

### Group chats

- `conversations.kind` (direct, group). Group chats list their bots in `conversation_bots` (conversation\_id, bot\_id, role lead or member), and `conversations.bot_id` stays the lead. A member sees a group chat only if they can see every bot in it.
- `@Name` wakes that bot. `@everyone` wakes the lead with the member list, and the lead replies with a plan that @mentions a bot for each part. Mentioned bots run in parallel, each as its own run in the same conversation, and each message shows its bot. A message without a mention goes to the last bot that spoke.
- Bots can @mention each other, up to 6 bot-to-bot hops per user message; then the chat waits for a person. Each bot keeps its own memory, approvals and budget, and treats other bots' messages as chat, never as instructions from the owner.

### Pages

- `pages` (org\_id, bot\_id, title, html, data jsonb, visibility private, workspace or public, public\_token\_hash, expires\_at, refresh\_routine\_id, version), plus `page_versions` holding the last 20.
- A page is one self-contained HTML document the bot writes, with its data in a separate JSON block it can update without rewriting the layout. Tools: `pages.publish` (from HTML or a file on the computer), `pages.update_data`, and `pages.share` (high risk, because it can make data public).
- Pages are web only (D-092): the same HTML serves the app, public links and PDF export, so anything a page shows can be shared. They are served from a separate origin with a strict content security policy (inline scripts and styles only, no network requests, no forms that post out).
- The app never embeds a page in a WebView. It opens pages in the system's in-app browser (Safari View Controller on iOS, Chrome Custom Tabs on Android, via `url_launcher` `inAppBrowserView`), the default browser on macOS, Windows and Linux, and a new tab on the web. Because that browser has no Casama session, opening a private or workspace page first asks the API for a single-use view link (60 s, bound to the page and the viewer) that the pages origin swaps for a short page-scoped cookie. A2UI stays the format for cards inside chat and is never used for pages.
- Public links use unguessable, revocable tokens, an optional expiry and `noindex`. PDF export renders the page with headless Chromium in the worker. A routine linked to a page refreshes it on schedule, and the page shows when it was last updated.

### Teach a task by showing it

- "Teach a task" in the live view starts a recording while the user holds control. This is the one exception to the take-control privacy rule, so a red "Recording" banner stays on screen and the user can stop at any time.
- The recording keeps input events, the accessibility snapshot and a screenshot for each step, plus browser URLs. Keystrokes into password fields are never stored, and the user can mark any field as a secret, which becomes a `{{secret:NAME}}` input.
- When recording stops, the model turns it into a draft skill (steps, inputs as parameters, success checks) that the user edits, saves and can try right away.

### Plugins

- Install packages in the Agent Plugins 1.0 format (`plugin.json` and `mcp.json`, validated against the published schemas at agent-plugins.org) from a GitHub repo, pinned to a commit.
- A plugin can bring skills, remote MCP servers and stdio MCP servers. Stdio servers run inside the bot's computer, started by `computerd` and bridged to the worker, so plugin code never runs on Casama's servers. With the desktop companion, a plugin can also be installed on the user's computer as local MCP servers.
- Before install, the app shows what the plugin adds: tools and their risk, network hosts, and the secrets it needs. Updates show a diff, and uninstall removes everything the plugin added. A paid marketplace stays a non-goal.

### Import an agent

- Agent folders: upload a ZIP, or pick a folder in the desktop app, from OpenClaw or Hermes Agent. Importers built from each project's public docs map persona files, memory files, skills and schedules to a bot, memories, skills and routines, show the mapping for review, and put anything else in `~/imported/` on the bot's computer.
- ChatGPT or Claude memory: the app shows a prompt to paste into that assistant, which answers with the user's saved memories in a fixed format. The user pastes the answer back, and Casama turns it into facts and preferences, each with a checkbox.

### Routines and skills as files

- Each routine and skill has a Markdown form with front matter (bot, schedule, timezone, trigger, enabled), with export and import in the app and the CLI.
- Optional git sync per workspace through the GitHub connection: app changes commit to the repo, and a push to the repo updates Casama after validation. When both sides changed, the app keeps its version and opens a pull request with the other.

### Knowledge sources

- `knowledge_sources` (org\_id, bot\_id or null for the whole workspace, kind upload, drive, notion, website or github, config jsonb, status, last\_synced\_at) and `knowledge_chunks` (source\_id, document reference, title, text, embedding, tsv).
- The worker parses uploads (PDF, DOCX, Markdown, HTML, CSV) and syncs connected sources through the existing app connections, daily or on change notices where offered. Website sources crawl within one domain and respect robots.txt.
- Tool `knowledge.search` uses the same hybrid search as memory and returns snippets with citations (document, page or heading, link), which the chat shows as sources. Without an embedding key, search is full-text only (D-017).

### Self-improving skills

- When a run succeeds at a task that matches two or more earlier runs (by embedding of run summaries), the bot proposes a skill as a card with its name, steps and tools; accepting saves it. When a run that used a skill fails, or the user corrects it, the bot proposes an edit shown as a diff.
- Skill changes need the owner's approval unless an action rule allows them. `skill_revisions` keeps history, and each skill shows uses, success rate and last failure.

### Step replay

- Teach-by-showing recordings and successful browser or desktop runs can be saved as replays: agent-browser and agent-desktop actions with element refs, parameters and checks. `replay.run(name, params)` runs them in the worker without model calls.
- When an element is missing or a check fails, the bot takes over from that step with the model and offers to update the replay. Typed passwords are never stored; replays use `{{secret}}` and password-manager items.

### Password managers

- Connect 1Password (service account) or Bitwarden (Secrets Manager or an organization vault) per workspace or person, choosing which vaults or collections bots may use.
- The executor fills logins into the bot's browser only for the item's own URLs, like `{{secret}}`; the model sees `[login:Name]`, never the password. One-time codes stored in an item use the sign-in codes flow.

### Welcome chat

- First run (signed in, no invite): the app creates a personal workspace ("<first name>'s space") and a personal bot (named from the product-name constant, with a mascot avatar; renamable in chat) and opens its chat. Joining by invite link skips this. The three-step wizard stays behind "Set up manually".
- The opening is scripted: normal bot messages with A2UI cards, stored like any message, with no model call. First "What should I call you?" (About you, D-169), then "What should I help with first?" (up to three of Email and calendar, Work projects, Coding, Research, Sales and customers, Personal errands, Something else with free text), then "Just me, my team or my business?". Both can be skipped, which gives a general intro.
- Then a scripted intro written for the picks (ARB strings in Casama's own words) and one main connection card, with "More apps" below it:

  | Pick                | Main connection                                                  | First value without a connection               |
  | ------------------- | ---------------------------------------------------------------- | ---------------------------------------------- |
  | Email and calendar  | Google or Microsoft (see Google sign-in and permissions)         | —                                              |
  | Work projects       | Notion, Linear or Jira                                           | "Tell me a project" creates a project          |
  | Coding              | GitHub, and coding agents on the user's computer                 | "Point me at a repo"                           |
  | Research            | None                                                             | "Give me a topic" leads to a report or page    |
  | Sales and customers | HubSpot, plus Google or Microsoft                                | "Who should I research first?"                 |
  | Personal errands    | Calendar                                                         | "What's one errand I can take off your plate?" |
  | Something else      | Chosen by the bot from the description once a model is available | Model-written                                  |

- No model yet (self-hosted): before anything that needs the model, an inline card offers Continue with ChatGPT, a model key or a local model. Casama Cloud's starter credits skip this card.
- First value: with email or calendar connected, a catch-up run (after an explicit consent line) reads the next 14 days of calendar and, only if inbox access was granted, the last 14 days of email. It posts "Here's what I noticed" (3–5 items), up to three one-tap task cards and a morning brief offer (check-ins). Without connections, the bot posts the first task card for the pick.
- The setup interview (D-105) then runs in the same chat with two or three questions, followed by a "What I learned" card listing the memories saved (up to 10) to edit or delete. Then the chat is open.
- The picks are saved as memories, shape the personal bot's instructions, choose which starter bots it suggests and set what check-ins cover. "My team" or "My business" adds an invite-link card and suggests shared bots.
- Wave 4 adds the picks "Health and habits" and phone connections.

### About you

Bots should know who they are talking to without the person filling in a form. Each person keeps one profile that every bot they use can read, built mostly from what they already said (D-169).

- **Prefilled, then one question:** the name comes from Apple or Google sign-in (D-167), timezone and language from the device. The welcome chat opens with "What should I call you?", the sign-in first name filled in, so confirming is one tap. Nothing else is asked up front.
- **Profile fields:** preferred name and pronouns (optional) on `profiles`, which teammates already see; "About me" (free text, up to 1,500 characters), "How I like replies" (up to 600) and "Learn about me from chats" (on by default) on `user_about`, private to the person. Settings → About you edits all of it; the Settings card shows the name instead of only the email.
- **Learned facts:** memory extraction marks each fact as about the person (their job, family, places, tastes, how they like things written) or about the work. Facts about the person go to their own `user_facts` (private to them under RLS, at most 200, the oldest unpinned dropped first) instead of the bot's memory, which other members can read. Facts about the work stay in the bot's memory as before. The bot's `memory.write` takes `about: "person"` for the same split. A chip under the reply says "Saved to your profile" with Undo. With learning off, facts about the person are dropped.
- **Sensitive topics** (health, religion, politics, sexuality, money troubles) are saved only when the person asks the bot to remember them, never inferred.
- **Imports:** the ChatGPT or Claude memory import (Import an agent) can save to About you instead of one bot.
- **Where it applies:** the preferred name, pronouns and "How I like replies" go into every run that acts for the person, in every workspace. "About me" and learned facts apply only in personal spaces (where the person is the only member) unless they turn on "Use what I've shared about me" for a team space (`profile_spaces`); the default in team spaces is off. A space with a second member stops using them automatically.
- **Whose profile:** the person the run acts for (the sender, the routine's creator or a parent run's person, D-095). Runs for nobody (linked agents) get no profile.
- **Prompt:** a short "Who you're talking with" block after the skills index and date, so the cached prefix doesn't change. The personal bot's instructions no longer hold the person's name.
- **Privacy:** About you is in the data export and is deleted with the account. Its text is sealed with the person's own key while they belong to a workspace that encrypts (Encryption at rest), so the app reads and writes it through the API.
- **People who signed up earlier** get one "What should bots call you?" card above their bots. Personal bots made before this lose the name from their instructions. The People screen shows the name each member goes by and their pronouns.

### Google sign-in and permissions

- Casama Cloud uses its own Google OAuth app with only non-sensitive and sensitive scopes: sign-in (`openid`, `email`, `profile`), `calendar.events`, `gmail.send` and `drive.file` (files the user picks with Google's file picker). These need Google's free verification (a verified domain, a privacy policy on it and a demo video) and no yearly security assessment.
- Reading the inbox needs a restricted scope (`gmail.modify`), requested only when the user turns on an inbox feature (incremental authorization). Until Casama passes Google's restricted-scope verification and its yearly security assessment, Casama Cloud provides inbox access through Composio's managed Google sign-in, shown as a separate, clearly explained step; Zapier's MCP server (one-click, D-089) also works. When verification passes, inbox access moves into Casama's own app and users reconnect once.
- Self-hosted servers use their own Google client, published to production rather than Testing (Testing ends sign-ins after 7 days); unverified apps work for up to 100 users, and Google's Gmail MCP server works with that client.
- Forwarding mail to the bot's own address (Chat apps: email) needs no Google permission at all.

### Bot sharing

- `bot_access` (bot\_id, user\_id or role, access chat, edit or admin). The workspace default stays "everyone can chat"; private bots are visible only to people listed.
- A bot acting for a person (the run's acting user, as with ChatGPT plans in D-091) sees only the files, connections and knowledge that person can access.

### Calendar triggers

- Routine triggers gain `calendar_event`: an offset before or after events from a connected Google or Outlook calendar, with filters (calendar, has outside guests, title match, has a video link). The worker checks connected calendars every 5 minutes, or uses the provider's change notifications where offered, and schedules the run with the event (title, time, attendees, link, description) in context. Wave 4 adds the phone's calendar.

### Bot-to-bot switch

- Workspace setting `allow_bot_to_bot` (default on), changed by owners and admins. When off, bots cannot @mention or message each other in group chats and `bots.delegate` to peer bots is refused; subagents still work. The sending bot's timeline and the chat say why.

### Chat apps

- The Channels section stands, with iMessage and Feishu added after Messenger. iMessage works only through the desktop companion on the user's own Mac (Apple has no bot API) and needs that Mac online. Feishu uses its open platform's events and send API.
- Routine triggers gain filters for inbound email and chat messages (sender, channel, subject or text match), so "when an invoice email arrives" can start a routine.

### Phone-call voice

- Tool `voice.call_user(reason)` (medium risk; respects quiet hours). iOS rings through a PushKit VoIP push and CallKit, Android through a high-priority FCM message and a self-managed calling screen, and desktop and web through an in-app ringing banner.
- Answering opens the existing live call with the run's context, and the bot speaks first. A declined or missed call becomes a normal push with the reason. Every VoIP push must show a call, as Apple requires.

### Encryption at rest

- Envelope encryption (AES-256-GCM) of `messages.content`, `run_events.payload`, `memories.content`, `conversations.summary`, ticket details, page content and knowledge chunks, done by the server before writing. Each workspace has a data key, wrapped by a key from `CONTENT_ENCRYPTION_KEY` or AWS KMS. It is off by default; turning it on encrypts existing rows in a background job.
- Postgres no longer sees plaintext, so the app reads these through the API instead of Supabase, and Realtime carries only event ids that the app fetches from the API. Memory and knowledge search use embeddings only, because full-text search needs plaintext; embeddings stay unencrypted, and the docs say so.
- Deleting a workspace destroys its data key. Key rotation rewraps data keys without rewriting rows.

### Memory backends

- A `MemoryStore` interface (search, write, update, delete, list, export) with the built-in Postgres store as the default, and Honcho and Supermemory adapters on the workspace's own keys. The memory screen, privacy export and account deletion all go through the interface.

### Paid data services

- A `DataProvider` interface with a Treg adapter (treg.to). Tools `data.{service}.{operation}` show the price in the approval card before the call.
- Casama Cloud charges the provider's cost plus 20% to credits (`usage_ledger.kind = data_calls`). Self-hosters use their own Treg key with no markup. Hosted resale waits for a written agreement with Treg.

### More sandbox providers

- Boat, boxd, CreateOS, Novita, Railway-backed runners, Kubernetes (pods with a gVisor RuntimeClass and a volume per home directory), Incus (system containers or VMs) and Alibaba Wuying, each a `SandboxProvider` adapter that passes `sandboxContract`.

### Agent-to-agent (A2A)

- Off by default. When on, each chosen bot is published as an A2A agent with an agent card, and A2A tasks become runs with the same approvals, budgets and audit log. Callers authenticate with workspace API keys.
- External A2A agents are added as integrations (`integrations.kind = a2a`), and bots call them with `a2a.send(agent, task)` (medium risk). Follow the A2A spec version that is current at build time.

### Calls for you

- Tool `voice.call(number, purpose, notes)` (high risk): the bot places an outbound call through a telephony provider (Twilio first) on the live-voice stack. It says at the start that it is an AI assistant calling for the user, works toward the stated purpose and hangs up when done.
- The app shows a live transcript, and the user can listen in, take over or end the call. Recording is off by default and only allowed where consent rules permit.
- Limits: business numbers by default, a daily call cap, never emergency numbers, and a number deny list on Casama Cloud. Call minutes go to credits. Legal review comes before hosted launch.

### Payments

- A `PaymentProvider` interface; the first adapter issues single-use virtual cards (Stripe Issuing on Casama Cloud; self-hosters bring their own issuing account). `payments.request(merchant, amount, currency, reason)` always needs approval with the amount shown. The card works once, for that merchant and amount plus a small tolerance, and expires after 1 h. The executor fills card details into checkout; the model never sees them.
- Hard bans no rule can relax: trading securities, buying crypto or gift cards, transfers between accounts and payments to individuals. Monthly spend caps per bot and workspace. Legal review (card issuing terms, money transmission) comes before hosted launch.

### Linked agents

- A person links their bot with a trusted contact's bot; both approve and either can revoke. Links work across workspaces and, through A2A, across Casama servers.
- Linked bots exchange structured requests ("find a dinner slot for 4 next week"), each under its own owner's rules, sharing only what the request needs. Every exchange shows in both owners' timelines.

### Voice upgrades

- Wake word on desktop and Android with an on-device open-source model, opening a live call with the chosen bot. Barge-in: speaking over the bot stops its speech and it listens. An optional animated avatar for live calls, rendered on device from the bot's avatar.

### Ops extras

- A `SecretStore` interface with Supabase Vault as the default and an Infisical adapter.
- Audit-log forwarding (`ee/`): stream `audit_log` rows to a signed webhook, an OTLP logs endpoint or S3, at least once, with a cursor.
- Cloudflare AI Gateway as an optional base URL per provider, for caching, logs and rate limits.
- One-click local server: the desktop app checks for Docker, runs the self-host stack on the same machine and connects to it.
- A self-host sign-up allowlist (`SIGNUP_ALLOWED_EMAILS`, emails or domains) beside `DISABLE_SIGNUP`.
- Encrypted backups (`casama selfhost backup --encrypt`, using age) with retention limits.
- Team computer layout: a `bots/<name>/` folder per bot and a `shared/` folder, plus a cap on simultaneous desktops per team computer.
- A Helm chart for self-hosters on Kubernetes (separate from the Kubernetes sandbox provider).
- Warm pool of computers (D-033), once first-command latency matters in practice.

### Device connections

- Collected by the Casama app on phones and by the desktop companion on computers. Every type is off until the user turns it on per device in Settings → Device connections; the system permission prompt appears only then.
- Access per bot: a bot that needs a type asks with a one-tap card, and a personal starter bot's setup interview asks for calendar, places and health. The owner revokes access from the card, the bot or Settings.
- Owner only: the data belongs to a person, not the workspace, and is used only by runs acting for that person (the D-091 rule). Teammates' bots never see it.
- Devices upload summaries in the background (health background delivery, geofences, Android WorkManager, companion timers) into `device_readings` (user\_id, device\_id, kind, period\_start, period\_end, summary jsonb, collected\_at). `device.read(kind, range)` returns summaries with their age and asks an online device for a fresh read (10 s timeout).
- Writing: `device.calendar.create` and `device.reminders.create` go through action rules (default: ask). Health stays read-only.
- Places: named places only (Home, Work, Gym; up to 20 on iOS), stored as arrive and leave visits, never a GPS trail. "Where am I now" is a one-off read that is not stored.
- Android notifications: only from apps the user picks; one-time codes are masked on the device.
- Retention: daily summaries 12 months; place visits and notifications 90 days; adjustable down to 7 days or "live only". Turning a type off deletes its data, and the privacy export and account deletion include it.
- Each run's timeline shows exactly what device data reached the model. Per type, the owner can require a private model (for example a local one) whenever that data is in context.

| Kind                           | iOS                               | Android        | macOS              | Windows                      | Linux                        | Web                       |
| ------------------------------ | --------------------------------- | -------------- | ------------------ | ---------------------------- | ---------------------------- | ------------------------- |
| Calendar                       | Yes                               | Yes            | Yes                | Through a connected calendar | Through a connected calendar | —                         |
| Reminders                      | Yes                               | —              | Yes                | —                            | —                            | —                         |
| Contacts                       | Yes                               | Yes            | Yes                | —                            | —                            | —                         |
| Named places                   | Yes (up to 20)                    | Yes            | —                  | —                            | —                            | Location once, on request |
| Photos                         | Picked photos, recent screenshots | Same           | Screenshots folder | Screenshots folder           | Screenshots folder           | File picker               |
| Health                         | Apple Health                      | Health Connect | —                  | —                            | —                            | —                         |
| Selection, window, browser tab | —                                 | —              | Yes                | Yes                          | Partial                      | —                         |
| File search, folder watch      | —                                 | —              | Spotlight          | Windows Search               | Yes                          | —                         |

### Health data

- Read-only through the `health` package (Apple Health and Health Connect): sleep (stages, start and end), steps, active energy, workouts, resting heart rate, heart-rate variability and weight. Cycle tracking, blood glucose and blood pressure are separate switches, off by default. Data from watches and rings arrives through Health or Health Connect.
- A daily summary each morning and a summary after each workout; trends against the user's own 30-day baseline are computed on the server without a model.
- No medical claims: neutral wording ("lower than your usual"), and health tools carry a "not medical advice" rule.
- Casama Cloud stores health data only with encryption at rest on; self-hosted servers keep it on their own machine. Store requirements: purpose strings, a privacy policy, Google's Health Connect declaration, and never using the data for ads or training.

### Device triggers

- New trigger kinds for routines and watchers: wake up (sleep end, or the first unlock on Android), arrive at or leave a named place, leave now (travel time to the next event's location crosses a threshold, using a maps provider on the workspace's own key: Google Maps or Mapbox), workout ended, a notification from a watched app, and Focus or Do Not Disturb turning on or off.
- Events reach the server within 2 minutes and the run gets the event in context. Check-ins use the wake-up trigger, so the morning brief follows the user's real wake time.

### Desktop context

- The quick-ask hotkey attaches, only when pressed, the selected text, the front app and window title, the current browser tab or a screenshot (Accessibility on macOS, UI Automation on Windows, X11 on Linux).
- `desktop.files.search` uses Spotlight, Windows Search or locate inside allowed folders; folder watchers are triggers.
- Activity recap, off by default: the companion logs front-app and window-title time locally and uploads an hourly summary, never screenshots or keystrokes. It powers end-of-day recaps and time tracking.
- macOS also shares Calendar, Reminders and Contacts like the phone. The web app offers a share target and a "show my screen" snapshot, both only on request.

### Attention rules

- Every proactive message (check-ins, suggestions, triggers) carries an urgency. Non-urgent ones wait while the user is asleep, in a Focus mode, driving, in a calendar meeting or in quiet hours, and are bundled into the next brief. Non-urgent proactive pushes are capped at 5 per bot per day.
- "Why am I seeing this?" on each proactive message lists the data and rule behind it, with "Less like this" (saved as a memory).

## Build plan

The plan is backend-first: Phases 0 to 2 build a working backend you test from the Dart CLI, Phase 3 adds the Flutter app so real testers can use the MVP, and monetization waits until Phase 7. Each phase ends at a gate whose criteria must pass before the next one starts, and every phase leaves a deployable system.

&#91;embedded content: build plan · 9 phases, MVP after Phase 3\]

A phase starts only when the previous gate passes; the full task lists and gate criteria follow.

### Phase 0: Backend foundations

> Checkboxes updated in the November 2026 audit from docs/DECISIONS.md. The unticked items need Oliver: accounts, store review, publishing or the launch itself (docs/NEEDS-FROM-OLIVER.md).

- [x] Monorepo with pnpm, Turborepo and Biome, plus a Dart workspace for `dart/`; CI running lint, typecheck and tests
- [x] Open-source basics: Apache-2.0 LICENSE, README, CONTRIBUTING with DCO sign-off, CODE\_OF\_CONDUCT, SECURITY.md, issue templates
- [x] Supabase migrations for organizations, memberships, profiles, invites, with RLS and pgTAP tests
- [x] Billing-ready stubs: `plans` and `entitlements` tables with one default self-host plan
- [x] Server skeleton: Hono with zod-openapi, `MODE=api` and `MODE=worker`, JWT middleware, `withUserSession`, problem-JSON errors, health checks, interactive API reference at `/docs`
- [x] `packages/contracts`: OpenAPI generation and run event schema; generator for `dart/casama_sdk`
- [x] DBOS wired into the worker with one test workflow
- [x] Observability package: OpenTelemetry and Sentry
- [x] Docker Compose stack for local development
- [x] `casama` CLI v0: `login`, `whoami`, `org create`, `org invite`

**Gate:** a developer signs up and logs in from the CLI, creates a workspace and invites a member; the cross-org RLS test passes; CI is green.

### Phase 1: Backend MVP (bots and chat)

- [x] Migrations: bots, conversations, messages, attachments, runs, run\_events, memories, skills, model\_credentials, usage\_ledger, quotas, audit\_log
- [x] Model keys in Vault with a test endpoint (OpenRouter plus one direct provider first)
- [x] `ModelGateway` with fallback chain and capability registry
- [x] `agentRun` workflow: loop, streaming, cancel, step and time limits, usage recording
- [x] Event bus: write to Postgres, broadcast on Realtime, catch-up endpoint
- [x] Context builder with compaction and large-output offload
- [x] Memory service: extraction and hybrid search
- [x] Skills: create, edit, `skills.load`
- [x] CLI: `bot create`, `chat` (streams tokens and tool steps), `runs watch`, `memory list`
- [x] Recorded model fixtures; crash-and-resume integration test

**Gate:** chat from the CLI streams replies; killing the worker mid-run resumes the run; a fact from one chat is recalled in another; no API response ever contains a key.

### Phase 2: Computers (backend)

- [x] `SandboxProvider` interface and contract test suite
- [x] `computerd` in Dart, compiled to a single binary
- [x] Headless and desktop images for amd64 and arm64
- [x] Supervisor: Docker with gVisor, per-computer networks, limits, warm pool (warm pool deferred in D-033, built in D-148)
- [x] Egress proxy with private-range blocking
- [x] Sleep and restore through object storage; checkpoints and restore
- [x] Tools: shell, files, browser (agent-browser), checkpoint
- [x] CLI: `computer status`, `computer shell` (interactive terminal), `computer files`

**Gate:** from the CLI, a bot researches a topic on the web and writes a report file; sleep and restore keep files and browser logins; restoring a checkpoint reverts files; requests to 169.254.169.254 and the internal network are blocked.

### Phase 3: MVP app (Flutter)

- [x] App shell: theme, go\_router, l10n, adaptive layout, wired to `casama_sdk`
- [x] Auth screens (email, magic link, Google, Apple), create and join workspace, add a model key
- [x] Bots list, streaming chat with tool cards, activity timeline
- [x] Computer tab: screenshot view, terminal, file browser, checkpoint Restore
- [x] Memory and skills screens; cost meter
- [ ] Tester builds: TestFlight, Google Play internal testing, web preview

**Gate (MVP complete):** 10 testers use the app on Android, iOS and web for one week, and at least 80% of their runs finish without errors.

### Phase 4: Autonomy

- [x] Approvals, autonomy levels and approvals inbox
- [x] Secret placeholders, host allowlists and redaction tests
- [x] Routine scheduler with timezones; webhook and GitHub triggers
- [x] `subagent.spawn`, `bots.delegate` and the task board
- [x] MCP and OpenAPI integrations; Composio and Pipedream Connect adapters
- [x] `MediaProvider` and fal.ai adapter; tools `media.image.generate` and `media.video.generate`
- [x] Push notifications (devices table, FCM fan-out), in-app inbox, deep links
- [x] Templates gallery with 5 starter bots
- [x] Tools: `web.search`, `http.request`, `notify.user`

**Gate:** a daily 08:00 routine in the owner's timezone runs and pushes its result; a high-risk tool waits for approval; a subagent stops at its budget; MCP, Composio and Pipedream tools work when configured; image generation succeeds with a test provider key; a test proves secrets never reach model input.

### Phase 5: Live computer

- [x] Evaluate and integrate the WebRTC streamer in the desktop image; deploy coturn
- [x] Stream-session endpoint and signaling proxy
- [x] Flutter live view with `flutter_webrtc`, input data channel, touch gestures and zoom
- [x] Control lease, `request_takeover`, push deep link, privacy during takeover
- [x] Desktop tools: agent-desktop with screenshot fallback
- [x] E2B and Daytona adapters passing the contract suite
- [x] Team and private computer management in the app

**Gate:** live view under 500 ms on 4G; take control and hand back works mid-run; the same flow works on E2B; a bot completes a task in a Linux desktop app.

### Phase 6: Reach and Flutter extras

- [x] Voice: dictation, read aloud, live calls with tool forwarding
- [x] Local computer companion on macOS, Windows and Linux
- [x] Home-screen widgets, iOS Live Activities, share to bot, desktop hotkey and tray, owner admin console
- [ ] Publish `casama_sdk` to pub.dev; CLI release binaries and Homebrew tap

**Gate:** a live call reply starts within 1 s; the companion completes a browser task on the user's Mac; an external sample app streams a run with the published SDK.

### Phase 7: Monetization (Dodo Payments)

- [x] Billing tables: plans, subscriptions, entitlements, credit\_ledger, billing\_events, cloud\_connect\_keys
- [x] `BillingProvider` interface and Dodo adapter: checkout, customer portal, Standard Webhooks verification, subscription lifecycle, usage events
- [x] App Store adapter: `in_app_purchase`, App Store Server API verification, Server Notifications V2
- [x] Google Play adapter: `in_app_purchase`, Play Developer API verification, real-time developer notifications
- [x] Entitlement service feeding quotas; credit deductions from `usage_ledger`
- [x] Plans, paywall and Restore Purchases screens; iOS shows in-app purchase only outside the US storefront
- [x] Cloud Connect: API keys, `casama-cloud` sandbox provider and model credit proxy for self-hosted instances
- [x] `BILLING_ENABLED=false` by default in self-host builds

**Gate:** a Dodo purchase on web unlocks iOS and Android; an App Store purchase unlocks web; cancel and refund webhooks remove access; a self-hosted instance runs a bot on a cloud computer and the usage shows on its cloud bill.

### Phase 8: Production and open-source launch

- [x] Dashboards and alerts; nightly evals with a stored baseline
- [x] k6 load test: 200 bots waking at once, 100 concurrent chat streams
- [x] Security review against the threat table; penetration test of sandbox isolation and RLS
- [x] Data export, account deletion, retention settings
- [x] Self-host installer, CLI `selfhost` commands, one-click deploy templates, docs site
- [x] `ee/` features under the commercial license; opt-in telemetry; Casama MCP server
- [ ] Marketing site, demo video, app store listings, signed desktop installers, Shorebird release flow
- [x] ChatGPT plan sign-in (see Model gateway): desktop and CLI sign-in, the `chatgpt` gateway adapter, limit and reconnect handling, and the fake OpenAI test server; cloud stays off until OpenAI approves hosted use
- [x] Two-step sign-in: TOTP through Supabase Auth on every platform, more than one factor allowed as backup, and a workspace setting that requires it for owners and admins (sensitive routes then need `aal2`); passkeys once Supabase Auth supports them
- [x] Casama Cloud abuse controls: a sign-up check on new email accounts (Supabase Auth's before-user-created hook accepts a Firebase App Check token, which needs no visible widget, or a solved proof-of-work puzzle on platforms without App Check), a verified email before a free-tier computer starts, outbound mail ports blocked, per-computer egress and CPU limits, crypto-mining and flood detection in the egress proxy that stops the computer and suspends the workspace, and Suspend in the owner console (stops computers and runs, keeps data, writes `audit_log`); self-hosted servers keep all of this off (D-094)
- [x] Least-privilege `casama_worker` database role for the worker and system jobs (D-016)
- [ ] Public launch: Show HN, Product Hunt, r/selfhosted, r/LocalLLaMA

**Gate:** load test p95 time to first token under 3 s; evals at or above baseline; security checklist closed; fresh VPS install under 15 minutes; a self-hosted bot replies on a ChatGPT plan; two-step sign-in works on all six platforms; a scripted sign-up without a sign-up proof fails on Casama Cloud; apps approved in both stores; public launch done.

### Post-v1 (specified, not part of Phases 0–8)

Build these only after v1 launch unless the product owner reprioritizes. (Reprioritized: Waves 1–4 were built before launch, D-096 to D-153.) Designs and acceptance criteria are in the Post-v1 roadmap; each wave's gate is that every acceptance criterion in its rows passes.

- [x] Wave 1: local MCP servers, coding agents, ticket board, spaces, bots that manage bots, ask for a secret, sign-in codes for bots, search, skills library, setup interview and starter bots, lazy tool loading, run tracing, app polish, projects, check-ins, action rules, watchers, hosted MCP endpoint
- [x] Wave 2: group chats, pages, teach by showing, plugins, import an agent, routines and skills as files, knowledge sources, self-improving skills, step replay, password managers, welcome chat, bot sharing, calendar triggers, bot-to-bot switch
- [x] Wave 3: channel adapters in this order: Telegram, email (Resend), SMS (Twilio), Slack, WhatsApp, Messenger, iMessage, Feishu, each with sender allowlists, plus email and chat triggers for routines
- [x] Channel gate: a Telegram message and an email each get replies in the same thread; unknown senders are ignored
- [x] Wave 3: phone-call voice, encryption at rest, memory backends, paid data services, additional `SandboxProvider` adapters (Boat, boxd, CreateOS, Novita, Railway-backed runners, Kubernetes, Incus, Alibaba Wuying) passing the contract suite, agent-to-agent (A2A), calls for you, payments, linked agents, voice upgrades, and the ops extras (boxd, CreateOS and Alibaba Wuying deferred for lack of public APIs, D-139)
- [x] Wave 4: device connections, health data, device triggers, desktop context, attention rules
- [x] About you: one profile per person that every bot reads (D-169)

## Open decisions and risks

Eleven decisions have defaults the coding agent can build on now; confirm each by the time shown.

| Decision                      | Default in this spec                                                                          | Confirm by     |
| ----------------------------- | --------------------------------------------------------------------------------------------- | -------------- |
| Final product name and domain | "Casama" as a working name in one config constant; check trademarks before launch             | Phase 8        |
| Who pays for model usage      | Bring-your-own model keys at launch; included credits later via Dodo Payments                 | Phase 7        |
| Supabase hosting              | Supabase Cloud in your chosen region for hosted; self-hosted Supabase in Compose              | Phase 0        |
| Media generation provider     | fal.ai first; additional `MediaProvider` adapters as needed                                   | Phase 4        |
| WebRTC streamer               | Decided: Neko (D-054)                                                                         | Phase 5        |
| Hosted ChatGPT plan usage     | Off on Casama Cloud until OpenAI approves it through its interest form                        | Cloud launch   |
| Name for workspaces in the UI | Keep "workspace"; switch to "space" if the product owner prefers                              | Post-v1 Wave 1 |
| Page format                   | Self-contained HTML on a separate origin; A2UI stays for chat cards                           | Post-v1 Wave 2 |
| Paid data resale              | Treg adapter; hosted resale only after a written agreement with Treg                          | Post-v1 Wave 3 |
| Google inbox access           | Composio managed sign-in on Casama Cloud until Casama passes Google's restricted-scope review | Cloud launch   |
| Maps provider for leave-now   | Google Maps or Mapbox on the workspace's own key                                              | Post-v1 Wave 4 |

| Risk                                                                                     | Impact                                           | Mitigation                                                                                                                                 |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Chromium or desktop apps misbehave under gVisor                                          | Browser or desktop tools fail in computers       | Test early in Phase 2; fall back to standard runc on a dedicated sandbox host with stricter network rules, or route to E2B                 |
| agent-desktop is new (v1.0 in Oct 2026) and depends on apps exposing accessibility trees | Desktop tasks fail on some apps                  | Keep the screenshot fallback; pin versions; contract tests per release                                                                     |
| WebRTC complexity and NAT traversal                                                      | Live view unreliable on mobile networks          | coturn with TCP and TLS fallback; screenshot fallback; measure in Phase 5 gate                                                             |
| Model costs grow faster than expected                                                    | Hosted version loses money                       | BYO keys, budgets, quotas, cheap internal model, caching                                                                                   |
| OpenAI changes or withdraws ChatGPT plan usage for third-party apps                      | People on plans lose model access                | Keep API keys and fallbacks first-class; feature flag; plan errors never switch billing silently                                           |
| Local MCP servers and coding agents act on the user's own machine                        | Unwanted changes to the user's files or accounts | Off until approved per server; shared folders only; overlay with Stop; high-risk actions always ask; pushes need approval                  |
| Prompt injection leads to harmful actions                                                | Trust and legal exposure                         | Untrusted-content labeling, approvals after untrusted input, secret placeholders, evals with injection tasks                               |
| Google limits or delays Gmail inbox access                                               | Weaker catch-up and inbox features               | Calendar, send and Drive use scopes with free review only; inbox through Composio until verified; Microsoft and forwarding as alternatives |
| Health and location data raise store-review and privacy problems                         | App rejection or lost trust                      | Off by default, per-bot access, summaries only, no GPS trail, encryption required on Cloud, precise purpose strings                        |
| Meta app review delays for WhatsApp and Messenger                                        | Post-v1 channels ship late                       | Channels are built (D-134); Meta business verification is still needed before WhatsApp and Messenger go live                               |
| Scope is large for one team                                                              | Slow launch                                      | Strict phase gates; every phase ships a usable product                                                                                     |
