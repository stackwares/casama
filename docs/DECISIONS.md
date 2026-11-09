# Decision log

Choices the spec left open, recorded as they are made. Newest last. Each entry: context, decision, consequences.

## D-001 Run TypeScript directly on Node.js (no build step)

- **Context**: The spec fixes Node.js 24 LTS and TypeScript but not a build tool.
- **Decision**: Node.js runs `.ts` sources with built-in type stripping. Code uses only erasable syntax (`erasableSyntaxOnly`), relative imports carry `.ts` extensions, and `tsc --noEmit` typechecks.
- **Consequences**: No bundler or `dist/`. Workspace packages export `src/index.ts`. The Docker image keeps pnpm workspace symlinks so packages resolve outside `node_modules` (Node does not strip types inside `node_modules`).

## D-002 Route definitions live in packages/contracts

- **Context**: "Contracts first": OpenAPI is the source of truth and is generated from code.
- **Decision**: `createRoute` definitions and schemas live in `packages/contracts`; the server only attaches handlers. `buildOpenApiDocument()` registers the routes without handlers. The committed `openapi.json` is checked against the code in tests.

## D-003 Dart client: generated REST package plus generated sealed events

- **Context**: The spec names openapi-generator (dart-dio) and typed freezed event classes. dart-dio cannot model the discriminated `RunEvent` union with json_serializable, and it does not generate freezed classes.
- **Decision**: openapi-generator dart-dio with json_serializable generates `dart/kasama_api` (one class per event variant included). `gen-dart.ts` generates a sealed `RunEventItem` hierarchy in `kasama_sdk` that dispatches on `type` to those classes, with `UnknownRunEventItem` for forward compatibility. The union is removed from the generator's input only.
- **Consequences**: `kasama_api` is a separate generated package that `kasama_sdk` re-exports. App models that are not API types can still use freezed.

## D-004 Organization creation and invite acceptance are SQL functions

- **Context**: Creating an org must insert the org and the owner membership atomically; RLS would otherwise block the first membership.
- **Decision**: `create_organization(name, slug)` and `accept_invite(token_hash)` are `security definer` functions that use `auth.uid()` and `auth.jwt()`. Direct inserts into `organizations` and `memberships` have no RLS policy and are denied. A trigger keeps at least one owner per org.

## D-005 Invite delivery without an email provider

- **Context**: Phase 0 needs invites before email (Resend) is configured, especially for self-hosters.
- **Decision**: With `RESEND_API_KEY` set, the invite is emailed and the token never leaves the server. Without it, the API returns `accept_token` to the inviter (an admin) so it can be shared directly. Tokens are stored as SHA-256 hashes, expire in 7 days and are single use. The invitee's email must match the invite.

## D-006 Idempotency keys stored in Postgres

- **Decision**: `idempotency_keys (user_id, key)` stores the first non-5xx JSON response per user and key, replayed with `idempotent-replayed: true`. Reusing a key for a different method or path returns 422 `idempotency_key_reused`. A cleanup job (Phase 1 worker) will delete rows older than 24 h.

## D-007 In-memory rate limiting

- **Context**: The target is one API process for 100 users.
- **Decision**: Fixed one-minute window per user id (or client IP when anonymous), `RATE_LIMIT_PER_MINUTE` (default 120), 429 with `Retry-After`. Replace with a shared store if the API scales out.

## D-008 DBOS system tables in a `dbos` schema of the app database

- **Decision**: `systemDatabaseSchemaName: "dbos"` on the same Postgres as the app, which works on Supabase Cloud where creating extra databases is awkward.

## D-009 JWT verification supports both Supabase key types

- **Decision**: HS256 with `SUPABASE_JWT_SECRET` when the token says HS256 and the secret is set; otherwise the project's JWKS (`/auth/v1/.well-known/jwks.json`). Tokens must have `aud=authenticated` and `role=authenticated`.

## D-010 Local tests use real Postgres without Docker

- **Context**: The development machine has no Docker, so `supabase start` is unavailable.
- **Decision**: A test harness creates throwaway Postgres clusters from local binaries with a minimal Supabase shim (roles, `auth.users`, `auth.uid()`/`auth.jwt()`, default grants). CI also runs the same pgTAP files on the real Supabase stack, which is authoritative.

## D-011 Public client config endpoint

- **Decision**: `GET /v1/config` (no auth) returns the Supabase URL, anon key, product name and whether billing is on, so clients only need the API URL.

## D-012 `v` in the run event envelope is an integer, not a literal

- **Context**: openapi-generator emits invalid Dart for an integer enum.
- **Decision**: `v` is an integer with minimum 1 (currently 1). Clients still ignore unknown event types.

## D-013 Run events are broadcast by a database trigger

- **Decision**: `append_run_event` allocates the next seq (`runs.last_seq`) and inserts in one transaction. An `AFTER INSERT` trigger calls `realtime.send` for topics `run:{id}` and `bot:{id}` (private channels, authorized by a policy on `realtime.messages` that calls `realtime_topic_allowed`) and `pg_notify('kasama_run_events', 'run_id:seq')`.
- **Consequences**: an event is broadcast if and only if it was stored. The API's SSE stream listens to NOTIFY and reads rows, so it never sees an event that was rolled back.

## D-014 Deltas from a crashed model step stay in the log

- **Context**: Events are append-only; a model step that crashes mid-stream is re-executed by DBOS.
- **Decision**: each model step attempt uses a new `message_id`. Clients group `message.delta` by `message_id` and treat `message.completed` as the final text; partial deltas whose `message_id` never completes are hidden once the run ends.

## D-015 Model keys: written by the API, read only by the worker

- **Decision**: `POST /v1/credentials` writes the key to Vault with the server role after checking `has_role(org, 'admin')` under the user's session. `POST /v1/credentials/{id}/test` enqueues a `testCredential` workflow, because only the worker reads `vault.decrypted_secrets`. Keys are resolved inside each step and never appear in step outputs, which DBOS persists.

## D-016 Worker database role (deferred)

- **Context**: The spec calls for a dedicated role for system jobs, scoped by explicit org ids.
- **Decision**: In Phase 1 the worker uses the server connection and scopes every query by run, bot and org ids. A least-privilege `kasama_worker` role (execute on the event functions, Vault read, table grants without bypass) is scheduled for the Phase 8 security review.

## D-017 Embeddings

- **Decision**: memories are embedded with the org's OpenAI key (`text-embedding-3-small`, 1536 dimensions) when one exists (`EMBEDDINGS=auto`). Without one, recall uses full-text search only (still hybrid with a word-OR query). `EMBEDDINGS=hash` is a deterministic offline embedder for tests. Changing models will need a re-embed job.

## D-018 Tool names on the wire

- **Decision**: provider APIs reject dots in tool names, so `memory.search` is sent as `memory__search` and mapped back.

## D-019 SSE for the CLI, Realtime for the app

- **Decision**: `GET /v1/runs/{id}/events` returns JSON, or a server-sent event stream when the client sends `Accept: text/event-stream` (honours `Last-Event-ID`, closes after the terminal event). The Flutter app will use Supabase Realtime plus the same catch-up endpoint.

## D-020 Large tool output without a computer

- **Decision**: until computers exist (Phase 2), outputs over about 4,000 tokens keep their head and tail with an omission marker. The `OffloadSink` interface lets Phase 2 write the full output to the computer and pass the path.

## D-021 Cancellation is requested, then performed by the worker

- **Decision**: `request_run_cancel` (security definer, checks access) sets `cancel_requested_at` on the run and its active subruns. The worker polls every 500 ms while streaming and checks at every step boundary, then emits `run.cancelled`. This meets "cancel stops within 2 s" without DBOS-level cancellation.

## D-022 Budget and limit outcomes

- **Decision**: runs that hit a limit end as `failed` with a stable code: `quota_exceeded`, `daily_budget_exceeded`, `budget_exceeded`, `max_steps_exceeded`, `wall_time_exceeded`, `no_model_configured`. Checks run at admission and before every model step.

## D-023 Invite tokens carry a prefix

- **Decision**: tokens are `kinv_` plus 32 random bytes in base64url, so they never start with `-` (which CLIs parse as an option).

## D-024 Recorded model fixtures

- **Decision**: `ReplayGateway` chooses a turn by matching the request (last user text, last role, last tool name, system text, model), so replays are deterministic, including re-executed steps after a crash. Workers take `KASAMA_MODEL_FIXTURES` (JSON or JSONL) and `KASAMA_MODEL_RECORD` (append real exchanges as fixture turns).

## D-025 Bot select policy is written inline

- **Context**: `INSERT ... RETURNING` checks the select policy in the same statement, where a security definer function that re-reads `bots` cannot yet see the new row.
- **Decision**: `bots_select` checks `is_member(org_id) and (visibility = 'team' or created_by = auth.uid())` directly. Other tables keep using `can_access_bot(bot_id)`.

## D-026 Free-form JSON maps in the Dart client allow nulls

- **Decision**: `gen-dart.ts` rewrites generated `Map<String, Object>` to `Map<String, Object?>`, because event payloads legitimately contain nulls (for example `computer_id`).

## D-027 Supervisor reaches computers by joining their networks

- **Context**: each computer sits on its own Docker network with `Internal: true` (no route out). The macOS host cannot reach container networks, and published ports do not work on internal networks.
- **Decision**: the supervisor runs as a container and joins each computer network to reach `computerd` at `http://<prefix>-c-<ref>:7070`. The egress proxy joins each computer network too (and is the only container also on an outbound network). The same layout works on a Linux host.
- **Consequences**: computers can open TCP connections to the supervisor and proxy on their shared network; both require tokens computers never receive (the proxy's computer credentials only allow proxying). Tests prove a computer cannot use the supervisor API, the proxy control port, or reach another computer.

## D-028 Per-computer tokens are derived, not stored

- **Decision**: `computerd` and egress credentials are `HMAC(COMPUTER_TOKEN_SECRET, kind:ref)`, so the supervisor stays stateless across restarts.

## D-029 Egress proxy design

- **Decision**: an HTTP forward proxy (absolute-URI requests and CONNECT) written in Node with no dependencies. It authenticates each computer (Basic auth from `HTTPS_PROXY`), resolves hostnames itself, refuses if any resolved address is private, loopback, link-local (metadata), CGNAT, multicast or reserved (including IPv4-mapped IPv6), then connects to the vetted address, which defeats DNS rebinding. Per-computer domain allow/deny lists and connection and byte rate limits are set through a token-protected control API. Non-HTTP traffic (for example SSH) has no route out.

## D-030 Chromium from Playwright, not Chrome for Testing

- **Context**: `agent-browser install` uses Chrome for Testing, which has no Linux arm64 build; Ubuntu 24.04's `chromium` package is a snap stub that does not work in containers.
- **Decision**: install Playwright's Chromium build (both architectures) under `/opt/browser` and point `AGENT_BROWSER_EXECUTABLE_PATH` at it. The browser profile lives at `~/.browser-profile` (`AGENT_BROWSER_PROFILE`), so logins survive sleep and restore; Chrome gets the proxy through `AGENT_BROWSER_PROXY` plus username and password variables.

## D-031 Archives and checkpoints are full tarballs

- **Decision**: sleep snapshots and checkpoints are gzip tarballs of the home directory (excluding browser and package caches), streamed by `computerd` to object storage through the supervisor. The spec asks for incremental checkpoints; full archives are simpler and small at current sizes. Revisit (for example with restic-style chunking) when home directories grow.

## D-032 Home directory on a named volume; disk quota is soft for now

- **Decision**: each computer's home is a Docker named volume (seeded from the image), the root filesystem is read-only, and `/tmp` is a 1 GB tmpfs. Docker cannot cap named volume size on overlay2 without XFS project quotas, so the 10 GB disk limit is not enforced yet; `computerd` reports free disk in `/health`. Enforce with XFS quotas on the production sandbox host (Phase 8).

## D-033 Warm pool deferred

- **Context**: the spec lists a warm pool of pre-started containers.
- **Decision**: deferred. Cold start (create network, volume and container, start, `computerd` ready) measured about 1 to 2 seconds on this machine. Per-computer credentials are baked into the container at creation, so a pool needs a claim-time configuration step; build it if first-command latency matters in practice.

## D-034 Computer state lives in Postgres; the worker drives transitions

- **Decision**: the supervisor is stateless (Docker labels are its only record). The `computers` table holds state, the latest snapshot and `running_since`; the worker and API move it through provisioning, starting, running, sleeping and error, emit `computer.state` events, and record `computer_seconds` usage when a running interval ends. A DBOS schedule every minute sleeps computers idle for 10 minutes (no tool calls, open terminals or running commands).

## D-035 Destructive-command checkpoints

- **Decision**: `shell.exec` creates a checkpoint before commands matching destructive patterns (`rm -r`/`-f`, `git reset --hard`, `git clean -f`, force pushes, package uninstalls, `dd`, `mkfs`, `truncate -s 0`). Retention: the last 20 per computer or 7 days, whichever is fewer; pruned objects are deleted from storage.

## D-036 Desktop image now, desktop use in Phase 5

- **Decision**: the desktop image (Xvfb, Openbox, AT-SPI, agent-desktop, xdotool, ImageMagick) builds and serves screenshots, but `enableDesktop`, live streaming and desktop tools are Phase 5 work.

## D-037 Real Supabase check

- **Decision**: with Docker available, migrations and pgTAP tests also run on the real Supabase Postgres image (`supabase db start` + `supabase test db`). This caught that Supabase owns `realtime.messages` and already enables its RLS, so the migration no longer alters it.

## D-038 v1 product scope (English-only clients, deferred channels)

- **Context**: the product should stay region-neutral. v1 should not ship external messaging adapters; integrations should include Composio, Pipedream and media generation like comparable open-source agent platforms.
- **Decision**: Phases 0–8 cover Kasama's own Flutter and CLI clients only. External `ChannelAdapter` implementations (Telegram, email inbox, SMS, Slack, WhatsApp, Messenger) and extra sandbox vendors are specified under **Post-v1** in `SPEC.md`. Phase 4 ships Composio, Pipedream Connect and a `MediaProvider` (fal.ai first). Launch locale is English only; ARB files stay the source for UI strings.
- **Consequences**: Phase 4 and Phase 6 gates do not require Telegram or email channel tests. `channel.send` and channel tables remain in the spec for post-v1 work.

## D-039 Riverpod without code generation; no freezed

- **Context**: the spec names Riverpod with code generation and freezed. At build time `riverpod_generator` and `json_serializable` required conflicting analyzer versions, so the code generation toolchain would not resolve.
- **Decision**: plain Riverpod 3 providers and notifiers (no `@riverpod` codegen) and small immutable classes with `copyWith` instead of freezed. API models come from the generated `kasama_api` client. Revisit when the generators agree on an analyzer version.

## D-040 One Backend interface in the app

- **Decision**: every read and write goes through `Backend` (`client/lib/core/backend.dart`). `SupabaseBackend` reads and edits through Supabase under RLS (messages, runs, memories, skills, bot edits) and sends commands through the generated API client; widget tests use a fake. The API client gets its token from the Supabase session (`CallbackSessionStore`).

## D-041 Live run events: Realtime plus catch-up

- **Decision**: the app subscribes to the private Realtime topic `run:{id}`, merges broadcasts with `GET /v1/runs/{id}/events?after_seq=` through `RunEventBuffer` (ordered by seq, duplicates dropped, gaps filled from the API) and polls catch-up every 2 seconds as a safety net. The integration test asserts events arrive over Realtime.

## D-042 Offline cache (drift) deferred

- **Context**: the spec's client architecture lists a drift cache for conversations, messages and bots.
- **Decision**: deferred past the MVP app. Data loads from Supabase and the API on demand. Add drift (including its web/wasm setup) when offline or instant-open becomes a priority.

## D-043 Chat attachments deferred

- **Decision**: the `attachments` table exists, but the chat composer has no attachment picker yet; files reach bots through the computer's file browser (upload) in the meantime.

## D-044 CORS for the web app

- **Decision**: the API allows `PUBLIC_APP_URL` and `CORS_ORIGINS`, plus any `localhost`/`127.0.0.1` origin outside production.

## D-045 Headless "screen" shows the browser page

- **Decision**: `GET /v1/computers/{id}/screenshot` returns the desktop when one exists; on headless computers it captures the bot's open browser page through agent-browser, and returns 409 when there is nothing to show. The app refreshes it every 5 seconds until live view arrives in Phase 5.

## D-046 Android minSdk 26

- **Decision**: `sentry_flutter` needs Android 8.0 (API 26), so the app's minimum SDK is 26. Debug builds allow cleartext HTTP for local development servers.
