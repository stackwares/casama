# Architecture

This is the as-built view. [SPEC.md](../SPEC.md) is the target; this file tracks what exists today.

## Status

**Phases 0 (backend foundations), 1 (bots and chat) and 2 (computers): built.** See "Build status" at the end.

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

## Model keys

Keys go into Supabase Vault through the API's server role and are never returned. Only the worker reads `vault.decrypted_secrets`. The credential test is a worker workflow. Every event, message and tool result passes through a redactor seeded with the bot's model keys.

## Code generation

`pnpm gen` writes `packages/contracts/openapi.json`, regenerates `dart/kasama_api` and `dart/kasama_sdk/lib/src/generated/`. `pnpm --filter @kasama/db pull` regenerates the Drizzle schema. CI fails if any generated file is stale.

## Testing

- `@kasama/db/testing` starts throwaway Postgres clusters from local binaries with a Supabase shim (roles, auth, Vault and Realtime stand-ins). CI also runs pgTAP on the real Supabase stack.
- Model calls in tests replay recorded fixtures (`apps/server/test/fixtures/chat.json`, `packages/agent/test/run.test.ts`). Turns are matched by request content, so re-executed steps get the same answer. Set `KASAMA_MODEL_RECORD=file.jsonl` on a worker with real keys to record new fixtures.
- `apps/server/test/crash-resume.test.ts` kills a real worker process mid-run with SIGKILL and proves a new worker finishes it without repeating finished steps.
- `scripts/e2e-cli.sh` runs the Phase 0 and Phase 1 gates through the real CLI.

## Build status

| Phase                 | State       | Notes                                                                                                                                                                                 |
| --------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0 Backend foundations | Built       | CLI signup, login, workspace, invite and join; RLS isolation; CI config                                                                                                               |
| 1 Backend MVP         | Built       | Gate verified locally with recorded model fixtures: CLI chat streams; killing the worker mid-run resumes; a fact from one chat is recalled in another; no API response contains a key |
| 2 Computers | Built | Gate verified locally on Docker Desktop (runc): from the CLI a bot researches a web page and writes a report; sleep and restore keep files and browser logins; restoring a checkpoint reverts files; metadata and internal addresses are blocked. gVisor not verified (needs a Linux host) |
| 3 to 8 | Not started | |

Known gaps carried forward: attachments have a table but no upload flow yet (Phase 3 app); the worker uses the server's database connection instead of a dedicated least-privilege role (D-016); live provider calls are wired but only exercised with recorded fixtures here.
