# Architecture

This is the as-built view. [SPEC.md](../SPEC.md) is the target; this file tracks what exists today.

## Status

**Phases 0 to 6 (backend, bots and chat, computers, the Flutter app, autonomy and integrations, live computer, reach and Flutter extras): built.** See "Build status" at the end.

## Components today

```
Dart CLI ──(kasama_sdk)──▶ API (Hono, MODE=api) ── enqueue (DBOSClient) ──▶ Worker (DBOS, MODE=worker)
   ▲  SSE                    │ withUserSession(claims)                       │ agentRun: model + tool steps
   │                         ▼                                               ▼
   └──── LISTEN/NOTIFY ── Supabase Postgres (RLS on every table) ◀── append_run_event ──┘
                          │ run_events trigger → realtime.send (topics run:{id}, bot:{id})
                          ▼
                     Supabase Realtime ──▶ Flutter app (Phase 3)
```

- **apps/server**: one TypeScript codebase. `MODE=api` serves HTTP; `MODE=worker` launches DBOS. Node.js runs the TypeScript sources directly (type stripping), so there is no build step.
  - `src/api`: routes, JWT auth, rate limit, Idempotency-Key, problem JSON, the SSE run stream (`run-event-hub.ts` fans out Postgres NOTIFY), and `workflows.ts` (enqueues worker workflows with DBOSClient).
  - `src/worker`: DBOS workflows `agentRun`, `testCredential`, the hourly `maintenance` schedule, and the gateway choice (real providers, fixture replay, or recording).
- **packages/agent**: the agent runtime, independent of DBOS.
  - `gateway/`: the neutral `ModelGateway` interface, the Vercel AI SDK adapter (OpenAI, Anthropic, Google, xAI, OpenRouter, any OpenAI-compatible endpoint), `withFallback` (429, 5xx and timeout failover with backoff), the capability and price registry, and `ReplayGateway`/`recordingGateway` for recorded fixtures.
  - `run.ts`: `runAgent(runId, deps)`. Every side effect runs inside `deps.step` (DBOS `runStep` in the worker), so a crash resumes at the last finished step.
  - `context.ts`: the context builder (spec order, byte-stable cacheable prefix, compaction at 70% of the window, large-output offload, untrusted-content wrapping).
  - `memory.ts`: hybrid recall (pgvector + full text, reciprocal rank fusion, plus pinned), near-duplicate merge, extraction with the cheap model.
  - `tools/`: the tool registry (Zod schema, risk, capability needs, executor) and Phase 1 tools `memory.search`, `memory.write`, `skills.load`.
  - `events.ts`, `redact.ts`: gap-free event appends, delta coalescing (at most 5 writes per second per run) and secret redaction.
- **packages/contracts**: Zod schemas, route definitions, the run event protocol and the OpenAPI generator.
- **packages/db**: the Drizzle schema pulled from the SQL migrations, `createDb`, and `withUserSession`.
- **packages/domain**: pure logic (roles, slugs, budgets and run limits).
- **packages/observability**: OpenTelemetry, Sentry and a JSON logger.
- **dart/kasama_api**: the generated REST client. **dart/kasama_sdk**: auth, typed run events, `watchRun` (SSE with catch-up and reconnect) and `RunEventBuffer`. **dart/cli**: the `kasama` CLI.
- **supabase/**: migrations (source of truth) and pgTAP tests.

## Request path for one chat message

1. `POST /v1/conversations/{id}/messages`: under the user's session the API inserts a `runs` row (queued) and the user message, then enqueues `agentRun` with the run id as the workflow id.
2. The worker's `agentRun` loads the run, admits it (quota, daily budget, model configured), recalls memories, and builds context.
3. Model steps stream through the fallback chain; text deltas are coalesced into `message.delta` events. Tool calls run as their own steps with `tool.started`, `tool.completed` or `tool.failed` events.
4. Each event goes through `append_run_event` (gap-free seq, one transaction). A trigger broadcasts it on Realtime and sends NOTIFY, which the API's SSE stream forwards.
5. On the final answer: the assistant message is saved, memories are extracted with the cheap model, usage is recorded, and `run.completed` is emitted.
6. Cancel: `POST /v1/runs/{id}/cancel` sets `cancel_requested_at`; the worker notices within 500 ms (mid-stream) or at the next step boundary and emits `run.cancelled`.

## Computers (Phase 2)

```
Worker / API ── SupervisorProvider (HTTP + bearer) ──▶ Supervisor container (Docker socket, stateless)
                                                          │ joins each computer network
                                                          ▼
              per-computer internal network:  computer container (computerd :7070, user 1000, read-only root)
                                                          │ HTTPS_PROXY (per-computer credentials)
                                                          ▼
                                              Egress proxy container ──▶ internet (private ranges blocked)
```

- **dart/computerd**: HTTP daemon inside each computer: streamed exec with kill and timeouts (process groups), files, search, home-directory archive and restore, a WebSocket terminal, screenshots and input when a display exists. Compiled to one native binary.
- **infra/images/computer**: `Dockerfile.headless` (Ubuntu 24.04, Node.js 24, Python, Playwright's Chromium, agent-browser, computerd) and `Dockerfile.desktop` (adds Xvfb, Openbox, AT-SPI, agent-desktop, xdotool). Both build for arm64 and amd64.
- **packages/sandbox**: the `SandboxProvider` interface, the `computerd` client, object stores (filesystem and S3), the Docker provider, the supervisor client, the provider contract suite (`sandboxContract`) and a throwaway test stack.
- **apps/supervisor**: the supervisor HTTP API and terminal WebSocket proxy.
- **infra/egress-proxy**: the egress proxy with its control API.
- **packages/agent/src/computers.ts**: `ComputerService` (which computer a bot uses, start or restore under an advisory lock, idle sleep, checkpoints with retention, usage seconds). **tools/computer.ts**: `shell.exec`, `files.*`, `browser.*`, `checkpoint.create`.
- **API**: `/v1/computers` list, get, start, stop, restart, files (list, download, upload, delete), checkpoints (list, create, restore) and the terminal WebSocket. **CLI**: `kasama computer status|start|stop|shell|files|checkpoints|restore`.

## Flutter app (Phase 3)

`client/` is one Flutter app for web, iOS, Android, macOS, Windows and Linux.

- **core/**: `Backend` (interface) and `SupabaseBackend` (Supabase for reads and simple edits under RLS, the generated API client for commands, Realtime plus catch-up for live run events), Riverpod providers, go_router routes with auth and onboarding redirects, theme.
- **features/**: auth (email and password, magic link, Google, Apple), onboarding (workspace, model key, first bot), bots list with status and today's cost, chat (streaming text, tool cards with live output, notices, stop, conversations), activity timeline with filters and checkpoint restore, computer (state, screen, terminal, files, checkpoints), memory (edit, pin, delete), skills, settings (workspace, invites, model keys, usage), bot settings.
- **Layout**: bottom navigation under 700 px, a navigation rail under 1200 px, and three panes (bots, chat, computer) on wider screens.
- **Strings**: every user-facing string is in `lib/l10n/app_en.arb` (English only in v1).
- **Tests**: widget tests with a fake backend (`flutter test`); `integration_test/app_flow_test.dart` runs sign-up, onboarding, streaming chat and memory recall against the real local stack (`scripts/e2e-app.sh`), verified on macOS, the iOS Simulator, the Android emulator and web (headless Chrome for Testing).

## Autonomy and integrations (Phase 4)

- **Approvals**: `needsApproval` (packages/domain) combines the bot's autonomy level, the tool's risk (static or per call, for example destructive `shell.exec`), `confirm` tools (media generation) and standing grants ("always allow"). The run emits `approval.requested`, waits durably (D-048) and resumes with `approval.resolved`. Owners get an in-app notification and a push that deep links to `/approvals/{id}`.
- **Secrets**: named secrets in Vault with host allowlists. Tools write `{{secret:NAME}}`; the worker substitutes the value only when the destination host is allowed and seeds the redactor with it. Outbound HTTP from tools uses `createSafeFetch` (blocks private, loopback and metadata addresses after DNS resolution).
- **Tools**: `http.request`, `web.search` (Brave or Tavily), `notify.user`, `tasks.create/update`, `routines.create/update`, `subagent.spawn`, `bots.delegate`, `media.image.generate`, `media.video.generate` (fal.ai through `MediaProvider`).
- **Integrations** (`packages/agent/src/integrations.ts`): MCP (official SDK, Streamable HTTP), OpenAPI (operations become tools; auth from a named secret), Composio and Pipedream Connect (D-052). Tools are loaded per run for the bot's attached integrations (D-053).
- **Routines**: cron in an IANA timezone (cron-parser), claimed by a `routines-tick` schedule with `FOR UPDATE SKIP LOCKED`, or triggered by signed GitHub/custom webhooks (D-047). Results notify the creator.
- **Templates**: five starter bots (research assistant, daily briefing, coder, ops assistant, writer) that create skills and routines.
- **App**: Inbox tab (approvals with approve, deny and always allow; live notifications; the shared task board), approval cards inline in chat, routines per bot, integrations (add, test, attach to a bot), secrets, template picker in onboarding and "New bot", FCM push registration (D-051).

## Live computer (Phase 5)

- **Streaming** (D-054, D-055): the desktop image (Xorg dummy, Openbox, AT-SPI, agent-desktop, Mousepad, Neko) streams only while someone watches. `POST /v1/computers/{id}/stream-session` returns a 5-minute signaling URL bound to the user, computer and mode plus TURN credentials; the API proxies signaling to the supervisor, which logs in to Neko and pipes the WebSocket. Media is relayed by coturn (`infra/turn`), which joins each desktop computer's network.
- **Control** (D-058): `GET/POST/DELETE /v1/computers/{id}/lease`; screen tools wait while a person holds control; `computer.request_takeover` and `/v1/takeovers` (list, dismiss). Lease changes and takeovers are in `audit_log` and on the run timeline.
- **Desktop tools** (D-059): `desktop.snapshot`, `desktop.launch`, `desktop.click`, `desktop.type`, `desktop.press`, `desktop.screenshot`, offered when the bot's computer has the desktop profile.
- **Providers** (D-056, D-057): Docker, E2B and Daytona behind the same contract suite; hosted providers run in the supervisor and are chosen per computer.
- **Computers**: `POST/PATCH/DELETE /v1/computers` (private computers per bot, profile switch with restart, delete with archives); a bot's computer is `bots.default_computer_id`.
- **App**: live view (`/computer/live?c=&takeover=`) with flutter_webrtc over TURN, pinch zoom, mouse, touch and keyboard input on the data channel, take control and hand back with a note, lease renewal on input, latency display, screenshot fallback, pause in the background; takeover cards in the inbox and chat; Computers screen; a computer picker in bot settings.

## Reach and Flutter extras (Phase 6)

- **Voice** (D-065): `/v1/voice/transcribe`, `/v1/messages/{id}/speech`, `/v1/voice/session`, `/v1/voice/tool`, `/v1/voice/transcript`; worker workflows on the `voice` queue; app dictation (record), read aloud (just_audio) and live calls (flutter_webrtc to OpenAI Realtime) with tool forwarding.
- **Desktop companion** (D-066): `/v1/local-devices`, the device WebSocket and the internal tunnel; computerd companion mode; the `local` provider; app pairing screen, overlay with Stop, tray.
- **Extras** (D-067): home-screen widgets (iOS, Android), iOS Live Activities, share to bot, quick ask with a global shortcut, startup gate.
- **Owner console** (D-068): `/v1/admin/*` and the Admin screens.
- **SDK and CLI** (D-069): publishable packages, release workflow, Homebrew formula, `examples/sdk_sample`.

## Billing and Cloud Connect (Phase 7)

- **Billing** (D-070): `apps/server/src/billing` (`BillingProvider`, Dodo, App Store and Google Play adapters, `BillingService`), `/v1/billing/plans`, `/v1/orgs/{id}/billing` (summary, checkout, portal, purchases, usage), `/hooks/billing/{dodo,app_store,google_play}`, and the worker's `billingSettle` job (every minute). Tables: `subscriptions`, `credit_ledger`, `credit_packs`, `billing_events`, plus `entitlements.overrides` and `usage_ledger.billable`. App: Billing screen (plans, store purchases through `in_app_purchase`, Restore Purchases, web checkout and portal, usage, Cloud Connect keys) and a paywall on 402.
- **Cloud Connect** (D-071): `/v1/orgs/{id}/cloud-connect/keys`, `/connect/v1/{whoami,sandbox/*,models/chat/completions}` on the cloud; the `kasama-cloud` provider on self-hosted servers. Tables: `cloud_connect_keys`, `cloud_connect_computers`.
- Off by default (`BILLING_ENABLED=false`).

## ChatGPT plan sign-in (D-091)

- **API** (`routes/chatgpt.ts`): `/v1/credentials/chatgpt/start|complete` (loopback sign-in; the server exchanges the code, verifies the ID token and writes the tokens to Vault), plus `PATCH/DELETE /v1/credentials/{id}` for every key. `CHATGPT_SIGN_IN` (auto: off when billing is on), reported as `chatgpt_sign_in` in `/v1/config`.
- **Agent** (`chatgpt-auth.ts`, `gateway/chatgpt.ts`, `credentials.ts`): OAuth helpers, the Responses adapter with OpenAI's plan-usage constraints and error codes, owner-only resolution, refresh under an advisory lock. Runs know the person they act for (`actingUserId`); plan usage is recorded at cost 0 (`usage_ledger.source = 'chatgpt_plan'`); skipped plans emit `model.fallback`.
- **Worker:** ChatGPT key test (model list), `revokeCredential`, idle refresh in the hourly maintenance job.
- **Clients:** `kasama_sdk/chatgpt_sign_in.dart` (loopback listener) used by `kasama credential chatgpt` and the desktop app's "Continue with ChatGPT"; Model keys shows plans with status, reconnect, the next-model setting, Manage usage and Remove.

## Two-step sign-in (D-093)

- Supabase Auth TOTP; `organizations.require_mfa`; `has_role` requires aal2 for owner and admin powers when it is on; `mfa_required` errors from the API. App: Settings → Two-step sign-in and the `/two-step` code screen. CLI: `kasama login --code`.

## Kasama Cloud abuse controls (D-094)

- `services/abuse.ts` and `routes/abuse.ts`: sign-up hook (App Check or proof of work), `/v1/signup/challenge`, `/internal/abuse` for egress reports, suspension; admin suspend/lift and `/v1/admin/abuse`. Egress proxy: mail and mining ports and pools refused and reported. `ComputerService.checkCanStart` (suspended, unverified free workspaces). App: sign-up proof, banner, owner console Abuse tab.

## Worker database role (D-095)

- The worker connects as `kasama_worker` (`WORKER_DATABASE_URL`): explicit per-table policies, Vault read and update, two narrow `public.worker_*` functions instead of `auth.users`, its own `dbos` schema; no superuser or RLS bypass. New tables call `public.allow_worker`.

## Local MCP servers (D-096)

- computerd `POST /mcp/<key>` bridges MCP Streamable HTTP to a stdio or loopback server on the user's computer; servers are `local_mcp` integrations registered by the app (`PUT /v1/local-devices/{id}/mcp-servers`); the worker's `LocalMcpAdapter` reaches them through the device tunnel. App: companion screen → Local tools (MCP), env kept in secure storage.

## Coding agents (D-097)

- `tools/coding.ts`: `coding.delegate` runs Claude Code, Codex or Cursor's agent headless on the user's companion computer or the bot's computer, or starts a Cursor cloud agent; the companion screen lists agents found on the computer.

## Ticket board (D-098)

- `tasks` with five statuses, priorities, owners, order and a bot thread; `task_comments`; `packages/agent/src/tickets.ts` starts and settles bot work; app Board tab (`features/board`).

## Spaces (D-099)

- Workspaces get an icon and color, invite links (`invite_links`, `accept_invite_link`) and per-workspace badges; the app has a workspace switcher, workspace settings and `/join/<token>`.

## Bots that manage bots (D-100)

- `packages/agent/src/tools/bots.ts`: `bots.list|create|update|archive` and `sidebar.organize`, capped at the acting bot's autonomy and budget; routine tools take `bot`. `bot_folders`, `bots.folder_id|sort_key|archived_at`, and `bot_revisions` (trigger `bots_record_revision`; the acting bot comes from `kasama.actor_bot`). App: sidebar folders, bot settings → Folder, Settings history (restore), Archive; Archived bots on the bot list.

## Ask for a secret (D-101)

- `packages/agent/src/secret-requests.ts` (`secrets.request`, handled in the run loop like takeovers), `secret_requests`, `/v1/secrets/requests` (list, fulfill, decline), events `secret.requested`/`secret.resolved`, and the chat's protected `SecretPrompt` card.
- Sign-in codes (D-102): `secrets.kind = totp`, `{{totp:NAME}}` resolved by `resolvePlaceholders` with `@kasama/domain` `totp.ts`; QR scanning in `client/lib/features/settings/totp_scan.dart`.

## Search (D-103)

- `public.search_workspace` (security invoker; `messages.tsv`, trigram indexes), `GET /v1/search` (`apps/server/src/api/routes/search.ts`, plus file search on awake computers), and `client/lib/features/search/search_view.dart` (Cmd/Ctrl+K, phone tab, jump to message).

## Skills library (D-104)

- `skills/` (bundled catalog), `apps/server/src/services/skills.ts` (catalog, `GitHubReader`), `apps/server/src/api/routes/skills.ts`, `skill_files`, agent `tools/skills.ts` (`skills.create`, `skills.update`, `approvalDetails`), `skills.load` file sync, and the app's `skill_library.dart` plus the composer's `/` picker.

## Setup interview and starter bots (D-105)

- `bots.setup_status`, `conversations.purpose`, `POST /v1/bots/{id}/setup`, agent `tools/setup.ts` (`SETUP_GUIDE`, `setup.apply`), the chat's setup card, and six more templates in `packages/domain/src/templates.ts`.

## Lazy tool loading (D-106)

- `packages/agent/src/lazy-tools.ts` (`planLazyTools`, `tools.load`), handled in the run loop; `LAZY_TOOLS_THRESHOLD`; `ToolSpec.deferred` and `ModelCapabilities.deferredTools` for native support; `packages/evals/src/compare.ts`.

## Run tracing (D-107)

- `packages/observability/src/run-trace.ts` (deterministic ids, `ForcedIdGenerator`, run and child spans), spans in `run.ts`, `packages/agent/src/langfuse.ts` (`LANGFUSE_*`, `organizations.llm_tracing`), `runs.trace_id`, `TRACE_URL_TEMPLATE` and the timeline's trace link.

## Edit and resend (D-108)

- `messages.parent_message_id`, `conversations.head_message_id`, triggers `messages_branch`/`messages_set_head`, `conversation_thread`/`branch_leaf`, `POST …/messages/{id}/edit` and `POST …/branch`, branch-aware history in `runAgent`, and the chat's Edit action and version arrows.

## Quiet hours (D-109)

- `profiles.quiet_hours`, `user_bot_settings`, `notifications.push_status`/`push_after`, `NotificationService.quietUntil`/`sendDeferred` (worker minute tick), `@kasama/domain` `quiet-hours.ts`, and the app's `features/notifications/quiet_hours.dart`.

## Bot templates (D-110)

- `BotTemplateFile` (contracts), `apps/server/src/api/routes/bot-template.ts` (export, share links in `bot_shares`, import), `docs/BOT-TEMPLATE-FORMAT.md`, and the app's `features/bots/bot_template.dart` (share sheet, import preview, `/import/<token>`).

## Shortcuts (D-111)

- App Intents and `ShortcutBridge` in `client/ios/Runner/AppDelegate.swift` and `client/macos/Runner/AppDelegate.swift`, `client/lib/core/shortcuts.dart` (list sync, `kasama/shortcuts` channel, Android `quick_actions`), `/run-routine/<ref>`.

## Offline cache (D-112)

- `client/lib/core/local_cache.dart` (drift key/value cache, `openLocalCache` installed in `main.dart`), cache-first `BotsNotifier` and `ChatController.open`, cleared on sign-out.

## Projects (D-113)

- `packages/agent/src/projects.ts` (`projectHeartbeat` in the worker's minute tick, `startProjectRun`, `projects.create|plan|update|status`), `projects`/`project_milestones`, `project_id` on tickets, runs, conversations and routines, `apps/server/src/api/routes/projects.ts`, and the app's `features/projects/`.

## Check-ins (D-114)

- `packages/agent/src/checkins.ts` (`applyCheckins`, cap, scan context, `suggestions.add`), `routines.kind`, `bot_checkins`, `suggestions`, scan runs without a conversation in `worker/routines.ts`, `apps/server/src/api/routes/checkins.ts` (`/v1/bots/{id}/checkins`, `/v1/for-you`, accept and dismiss), and the Inbox's For you tab.

## Action rules (D-115)

- `packages/domain/src/action-rules.ts` (categories, targets, resolution, previews), `action_rules`, the approval gate in `run.ts` (allow, ask, hand off; credential changes always handed off), `apps/server/src/api/routes/action-rules.ts`, and the bot's Action rules screen.

## Watchers (D-116)

- `packages/agent/src/watchers.ts` (`checkWatchers` in the worker's minute tick, `watchers.create|list|delete`), `watchers`, `apps/server/src/api/routes/watchers.ts`, and the bot's Watchers screen.

## Hosted MCP endpoint (D-117)

- `apps/server/src/api/routes/mcp.ts` (`/mcp` with `@kasama/mcp` tools over in-process API calls, the OAuth server, consent, API keys), `mcp_clients`/`mcp_auth_requests`/`mcp_tokens`, `organizations.mcp_decide_approvals`, `docs/MCP.md`, and the app's consent screen and Connect AI apps section.

## Group chats (D-118)

- `conversation_bots`, `conversations.kind`, `messages.bot_id`, `runs.trigger_message_id|hop`; `packages/domain/src/mentions.ts`; group handling in `run.ts` (other bots' messages as labelled chat, `wakeMentioned` with a 6-hop cap, `RunDeps.startRun`); `sendGroup` and `/v1/group-chats` in `apps/server/src/api/routes/bots.ts`; `client/lib/features/groups/`.

## Pages (D-119)

- `packages/domain/src/pages.ts` (CSP, document assembly), `packages/agent/src/pages.ts` (`pages.publish|update_data|share|list`, versions, refresh routines), `pages`/`page_versions`/`page_view_tokens`, `apps/server/src/api/routes/pages.ts` (list, view links, share, revert, delete), `apps/server/src/pages/app.ts` (the pages origin on `PAGES_PORT`), `apps/server/src/services/pdf.ts`, and `client/lib/features/pages/`.

## Teach a task (D-120)

- `packages/domain/src/teach.ts` (password detection, transcript), `packages/agent/src/teach.ts` (`captureTeachContext`, `teach.save_draft`), `teach_sessions`/`teach_steps`, `apps/server/src/api/routes/teach.ts`, and in the app `features/teach/` (`TeachRecorder`, the draft screen) plus the recording banner in the live view.

## Plugins (D-121)

- `packages/domain/src/agent-plugins.ts` (Agent Plugins 1.0 checks), `packages/agent/src/plugins.ts` (`syncPluginComputer`, `computerMcpFor`) and `ComputerMcpAdapter` in `integrations.ts`, `plugins`/`plugin_files` plus `skills.plugin_id`/`integrations.plugin_id`, `apps/server/src/api/routes/plugins.ts`, computerd `PUT /mcp-servers`, the supervisor's `/computers/:ref/mcp*` passthrough, `SandboxHandle.setMcpServers|mcpFetch`, and the bot's Plugins screen.

## Import an agent (D-122)

- `packages/domain/src/agent-import.ts` (OpenClaw and Hermes Agent folders → a `kasama.bot` template; ChatGPT/Claude memory prompt and parser), `agent_imports`/`agent_import_files`, `apps/server/src/api/routes/agent-import.ts`, and `client/lib/features/bots/agent_import.dart` (review screen, memory sheet).

## Routines and skills as files (D-124)

- `packages/domain/src/workspace-files.ts` (file formats), `packages/agent/src/workspace-files.ts` (export, apply) and `git-sync.ts` (`syncWorkspaceRepo`, `gitSyncTick` in the worker's minute tick), `org_git_sync` with change triggers, `apps/server/src/api/routes/workspace-files.ts` (export, import, git sync setup, `/hooks/git-sync/<org>`), `kasama files export|import`, and the workspace settings section.

## Production and launch (Phase 8)

- **Privacy** (D-072): `/v1/me/export`, `DELETE /v1/me`, `/v1/orgs/{id}/settings`; worker job `privacy` (daily purge and retention).
- **Enterprise** (D-073): `ee/` (`@kasama/ee`): license keys, `/v1/orgs/{id}/audit-log/export`, `/v1/orgs/{id}/sso`.
- **Telemetry** (D-074): opt-in weekly ping; `/telemetry/v1/ping` on Kasama Cloud.
- **Metrics** (D-075): `/metrics`; `infra/monitoring/` (Prometheus, alerts, Grafana).
- **Self-host** (D-076): `install.sh`, `infra/compose/docker-compose.yml`, `kasama selfhost`, `deploy/`, `docs/SELF_HOST.md`, `docs-site/`.
- **MCP server** (D-077): `packages/mcp`.
- **Evals and load** (D-078): `packages/evals`, `apps/server/load`.
- **Launch prep**: `site/`, `client/store/`, `docs/launch/`, `scripts/package-*`, `client/shorebird.yaml`; gate status in `docs/LAUNCH_CHECKLIST.md`, security in `docs/SECURITY_REVIEW.md`.

## Self-hosting defaults and optional services

Everything hosted is optional, behind an interface, with a default that runs in `docker compose`:

| Concern                   | Self-hosted default                                  | Optional                                                                         | Decision            |
| ------------------------- | ---------------------------------------------------- | -------------------------------------------------------------------------------- | ------------------- |
| Snapshots and checkpoints | Filesystem volume                                    | SeaweedFS (`--profile s3`), Cloudflare R2 (hosted), AWS S3, Supabase Storage     | D-062               |
| Error reporting           | Off                                                  | Sentry protocol (sentry.io, self-hosted Sentry, GlitchTip) or PostHog (any host) | D-063               |
| Product analytics         | Off                                                  | PostHog (any host)                                                               | D-063               |
| Computers                 | Docker, plus users' own machines (desktop companion) | E2B, Daytona                                                                     | D-056, D-057, D-066 |
| Voice                     | Off                                                  | The workspace's own OpenAI, Deepgram, ElevenLabs, Cartesia or Fish Audio keys    | D-065               |
| Live view relay           | coturn container                                     | any TURN service                                                                 | D-055               |
| Default model             | GPT-6 Luna via the org's own key                     | any provider and model                                                           | D-064               |
| Billing                   | Off: no paywall, no limits                           | Dodo Payments, App Store, Google Play (Kasama Cloud)                             | D-070               |
| Cloud computers, credits  | Off                                                  | Cloud Connect key to a Kasama Cloud workspace                                    | D-071               |
| Telemetry                 | Off                                                  | Weekly anonymous counts (`TELEMETRY=on`)                                         | D-074               |
| Monitoring                | `/metrics` only                                      | Prometheus and Grafana (`--profile monitoring`)                                  | D-075               |
| Enterprise features       | Off (Apache-2.0 features only)                       | License key for `ee/` (audit export, SAML SSO)                                   | D-073               |

## Model keys

Keys go into Supabase Vault through the API's server role and are never returned. Only the worker reads `vault.decrypted_secrets`. The credential test is a worker workflow. Every event, message and tool result passes through a redactor seeded with the bot's model keys.

## Code generation

`pnpm gen` writes `packages/contracts/openapi.json`, regenerates `dart/kasama_api` and `dart/kasama_sdk/lib/src/generated/`. `pnpm --filter @kasama/db pull` regenerates the Drizzle schema. CI fails if any generated file is stale.

## Testing

- `@kasama/db/testing` starts throwaway Postgres clusters from local binaries with a Supabase shim (roles, auth, Vault and Realtime stand-ins). CI also runs pgTAP on the real Supabase stack.
- Model calls in tests replay recorded fixtures (`apps/server/test/fixtures/chat.json`, `packages/agent/test/run.test.ts`). Turns are matched by request content, so re-executed steps get the same answer. Set `KASAMA_MODEL_RECORD=file.jsonl` on a worker with real keys to record new fixtures.
- `apps/server/test/crash-resume.test.ts` kills a real worker process mid-run with SIGKILL and proves a new worker finishes it without repeating finished steps.
- `scripts/e2e-cli.sh` runs the Phase 0 and Phase 1 gates through the real CLI.
- `scripts/live-check.sh` runs the few live checks against a real model (key from `~/.config/kasama/openrouter.env`); everything else uses fixtures.
- `apps/server/test/live.test.ts` is the Phase 5 gate (desktop computer, TURN relay and a werift WebRTC client); `packages/sandbox/test/live.test.ts` and `hosted.test.ts` cover the streamer and the E2B/Daytona adapters; `client/integration_test/live_flow_test.dart` runs the live view in the real app.
- `apps/server/test/autonomy.test.ts` is the Phase 4 gate (fixtures in `test/fixtures/autonomy.json`, a local MCP server and a fal.ai mock).

## Build status

| Phase                   | State                  | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ----------------------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0 Backend foundations   | Built                  | CLI signup, login, workspace, invite and join; RLS isolation; CI config                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| 1 Backend MVP           | Built                  | Gate verified locally with recorded model fixtures: CLI chat streams; killing the worker mid-run resumes; a fact from one chat is recalled in another; no API response contains a key                                                                                                                                                                                                                                                                                                                                                                                                        |
| 2 Computers             | Built                  | Gate verified locally on Docker Desktop (runc): from the CLI a bot researches a web page and writes a report; sleep and restore keep files and browser logins; restoring a checkpoint reverts files; metadata and internal addresses are blocked. gVisor not verified (needs a Linux host)                                                                                                                                                                                                                                                                                                   |
| 3 MVP app               | Built                  | Same end-to-end flow passes on macOS, iOS Simulator, Android emulator and web against real local Supabase. The tester gate (10 testers for a week) needs store accounts and people                                                                                                                                                                                                                                                                                                                                                                                                           |
| 4 Autonomy              | Built                  | Gate verified locally: high-risk calls wait for approval and resume or fail the step on deny/expiry; scheduled routines fire in America/Chicago and notify; signed webhooks start runs and unsigned ones do not; MCP tools work end to end; media generation needs confirmation; subagents stop at their budget. App end-to-end adds a routine run and its notification on macOS, iOS Simulator and Android emulator. Composio, Pipedream, fal.ai, Brave/Tavily and FCM tested against mocks only                                                                                            |
| 5 Live computer         | Built                  | Gate verified locally: live view through the API and TURN relay (data-channel RTT 1–3 ms, first frame about 2.4 s including streamer start) in a WebRTC test client and in the app on macOS and the iOS Simulator; take control and hand back mid-run resumes the bot with the user's note; request_takeover waits for a person; the same live flow works on E2B and the contract suite passes on E2B and Daytona (local control-plane mocks); a bot completes a task in Mousepad. 4G latency, real E2B/Daytona accounts and gVisor not verified                                             |
| 6 Reach and extras      | Built                  | Gate verified locally: the desktop companion completed a browser task on this Mac (agent-browser read a page served on the machine, through the tunnel, in the real app); an external app streamed a run with kasama_sdk; live-call plumbing measured against a mock provider (session mint about 30 ms, forwarded tool call about 200 ms). The "reply within 1 s" part is the realtime provider's latency and needs an OpenAI key. Widgets, Live Activities and the iOS share extension build; deep links verified on the Android emulator; release APK starts normally; publishing pending |
| 7 Monetization          | Built                  | Gate verified locally against provider fakes: a Dodo web purchase unlocked the plan in the app on the iOS Simulator, the Android emulator and macOS (same workspace entitlement); an App Store purchase unlocked the web API; Dodo cancel and refund, App Store refund and expiry, and Play voided-purchase notifications removed access; a self-hosted instance ran a bot's command on a cloud computer through Cloud Connect and the time showed on the cloud bill. One live model call through the Cloud Connect proxy to OpenRouter. Real Dodo, Apple and Google accounts not used       |
| 8 Production and launch | Built (launch pending) | Locally verified: k6 load test (200 bots woken at once, 100 concurrent chat streams) p95 time to first token 0.14 s and 0.82 s with recorded models; evals quick subset 100% (fixtures) and a 3-task live run 100%; security review with a cross-tenant sweep of all API routes and sandbox penetration checks (one memory-limit bug fixed); fresh self-host install in 2 min 47 s with a cold build, then a bot ran a command on a computer. Store approval and the public launch need Oliver                                                                                               |

Known gaps carried forward: attachments have a table but no upload flow yet (Phase 3 app); the worker uses the server's database connection instead of a dedicated least-privilege role (D-016); live provider calls are wired but only exercised with recorded fixtures here.
