# Architecture

This is the as-built view. [SPEC.md](../SPEC.md) is the target; this file tracks what exists today.

## Status

**Phases 0 to 4 (backend, bots and chat, computers, the Flutter app, autonomy and integrations): built.** See "Build status" at the end.

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

## Model keys

Keys go into Supabase Vault through the API's server role and are never returned. Only the worker reads `vault.decrypted_secrets`. The credential test is a worker workflow. Every event, message and tool result passes through a redactor seeded with the bot's model keys.

## Code generation

`pnpm gen` writes `packages/contracts/openapi.json`, regenerates `dart/kasama_api` and `dart/kasama_sdk/lib/src/generated/`. `pnpm --filter @kasama/db pull` regenerates the Drizzle schema. CI fails if any generated file is stale.

## Testing

- `@kasama/db/testing` starts throwaway Postgres clusters from local binaries with a Supabase shim (roles, auth, Vault and Realtime stand-ins). CI also runs pgTAP on the real Supabase stack.
- Model calls in tests replay recorded fixtures (`apps/server/test/fixtures/chat.json`, `packages/agent/test/run.test.ts`). Turns are matched by request content, so re-executed steps get the same answer. Set `KASAMA_MODEL_RECORD=file.jsonl` on a worker with real keys to record new fixtures.
- `apps/server/test/crash-resume.test.ts` kills a real worker process mid-run with SIGKILL and proves a new worker finishes it without repeating finished steps.
- `scripts/e2e-cli.sh` runs the Phase 0 and Phase 1 gates through the real CLI.
- `apps/server/test/autonomy.test.ts` is the Phase 4 gate (fixtures in `test/fixtures/autonomy.json`, a local MCP server and a fal.ai mock).

## Build status

| Phase                 | State       | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| --------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0 Backend foundations | Built       | CLI signup, login, workspace, invite and join; RLS isolation; CI config                                                                                                                                                                                                                                                                                                                                                                                                                           |
| 1 Backend MVP         | Built       | Gate verified locally with recorded model fixtures: CLI chat streams; killing the worker mid-run resumes; a fact from one chat is recalled in another; no API response contains a key                                                                                                                                                                                                                                                                                                             |
| 2 Computers           | Built       | Gate verified locally on Docker Desktop (runc): from the CLI a bot researches a web page and writes a report; sleep and restore keep files and browser logins; restoring a checkpoint reverts files; metadata and internal addresses are blocked. gVisor not verified (needs a Linux host)                                                                                                                                                                                                        |
| 3 MVP app             | Built       | Same end-to-end flow passes on macOS, iOS Simulator, Android emulator and web against real local Supabase. The tester gate (10 testers for a week) needs store accounts and people                                                                                                                                                                                                                                                                                                                |
| 4 Autonomy            | Built       | Gate verified locally: high-risk calls wait for approval and resume or fail the step on deny/expiry; scheduled routines fire in America/Chicago and notify; signed webhooks start runs and unsigned ones do not; MCP tools work end to end; media generation needs confirmation; subagents stop at their budget. App end-to-end adds a routine run and its notification on macOS, iOS Simulator and Android emulator. Composio, Pipedream, fal.ai, Brave/Tavily and FCM tested against mocks only |
| 5 to 8                | Not started |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |

Known gaps carried forward: attachments have a table but no upload flow yet (Phase 3 app); the worker uses the server's database connection instead of a dedicated least-privilege role (D-016); live provider calls are wired but only exercised with recorded fixtures here.
