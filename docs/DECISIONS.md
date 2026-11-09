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
