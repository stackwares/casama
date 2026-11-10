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

## D-047 Webhooks are verified in the worker

- **Decision**: `/hooks/github/{routine_id}` and `/hooks/custom/{routine_id}` accept the raw body (capped, rate limited) and enqueue a `routineWebhook` workflow. The worker, which is the only service that reads Vault, checks the HMAC (`X-Hub-Signature-256` or `X-Kasama-Signature`) with a constant-time compare before starting a run. The API answers 202 either way so callers cannot probe which routines exist.

## D-048 Approval waits use DBOS messages

- **Decision**: a run that needs approval sets `waiting_approval`, then loops `DBOS.recv("signal", ≤300 s)` and re-reads the approval row. Deciding (API) or cancelling sends the signal. Waits survive worker restarts, and a run waiting days costs nothing. Approvals expire after 24 hours; expired or denied calls fail only that tool step (`approval_denied`) and the model continues.

## D-049 Subagents and delegation run on their own queue

- **Decision**: DBOS cannot start a workflow from inside a step, so `subagent.spawn` and `bots.delegate` enqueue a child `agentRun` on the `subruns` queue through `DBOSClient` and wait for its result. Children get 20% of the parent's remaining budget (or less if asked), a tool subset and a wall-clock limit; delegation depth is capped at 3 and cycles are refused.

## D-050 Push fan-out lives in the worker

- **Decision**: notifications are rows in `public.notifications` (broadcast to the private Realtime topic `user:{id}` by a trigger) plus FCM HTTP v1 pushes sent by the worker's `NotificationService`, instead of a Supabase Edge Function. One less runtime to deploy and test; the service account JSON is a worker secret (`FCM_SERVICE_ACCOUNT_JSON`). Without it the in-app inbox still works.

## D-051 App push uses FCM registration tokens

- **Decision**: the app registers with `getToken()` because the worker sends to `message.token`. firebase_messaging 17 deprecates that in favour of installation-ID direct send; move both sides together once that API is stable on all platforms. Firebase options come from `--dart-define` (`FIREBASE_*`), so no Firebase config files are committed and builds without them simply have push off.

## D-052 Composio and Pipedream adapters follow their public REST docs

- **Decision**: the Composio (v3 tools list and execute) and Pipedream Connect (OAuth client credentials, actions list and run) adapters are written from the public REST documentation and tested against local mocks only. Field names may need small fixes once real keys are available (tracked in NEEDS-FROM-OLIVER).

## D-053 Integration tool names

- **Decision**: integration tools are named `{kind}.{integration}.{tool}` (for example `mcp.calc.add`) and sent to models with dots replaced by double underscores. Integrations are attached per bot, optionally with a tool allowlist, and tool lists are cached on the integration row and refreshed by "Test".

## D-054 Neko is the live-view streamer

- **Decision**: the desktop image runs Neko (m1k1o/neko, Apache-2.0), compiled from a pinned tag on Ubuntu 24.04 so glibc and GStreamer match the runtime. Selkies (MPL-2.0, Python and GStreamer) was the alternative; Neko won on a single Go binary, a small JSON signaling protocol, per-user `can_host` profiles that enforce view-only inside the streamer, a data-channel ping for latency, and touch support. computerd starts Neko only when the first viewer arrives (`POST /stream/start`) with fresh viewer and controller passwords (multiuser provider, so every connection is its own session) and stops it 60 s after the last viewer leaves. Neko's chat, file transfer and plugins are off.

## D-055 Media goes only through a TURN relay

- **Decision**: viewers use `iceTransportPolicy: relay` with short-lived coturn REST credentials from the stream session. The relay joins each desktop computer's private network under the alias `turn` (the supervisor connects it), and Neko uses it as its own ICE server, so media flows client ↔ coturn ↔ computer without the computer being reachable from anywhere. coturn refuses every peer address except its own relay address, so it cannot be used to reach other hosts, private ranges or metadata services. Signaling goes client ↔ API ↔ supervisor ↔ Neko; the API proxy drops input events from view tokens and lets a control token take control only while its user holds the lease, and takes control back when the lease ends.

## D-056 Hosted providers are routed by the supervisor

- **Decision**: E2B and Daytona adapters run inside the supervisor next to Docker, because they need the object store and the computer-token secret, which only the supervisor holds. The API and worker keep one client; `ComputerService` picks the provider from `computers.provider` and the client sends `x-kasama-provider`.

## D-057 E2B and Daytona run Kasama's own image

- **Decision**: both providers start Kasama's computer image (an E2B template or a Daytona snapshot) with computerd as the start command, and every call goes to computerd through the provider's authenticated port URL (E2B `https://{port}-{id}.e2b.app`; Daytona signed preview URLs with `x-daytona-preview-token`). Files, exec, checkpoints, sleep to object storage and live view are the same code as on Docker. The adapters were written from the public REST docs and verified against local control-plane mocks that run the real image (`testing-hosted.ts`). Hosted sandboxes have their own internet access, so the egress proxy's private-range blocking does not apply there; the TURN relay must be public for live view.

## D-058 Control lease and takeover semantics

- **Decision**: a user lease lasts 15 minutes and the app renews it while the user gives input, so 15 minutes without input hands control back. While a person holds it, screen tools (`browser.*`, `desktop.*`) wait in the run loop (durably in the worker, `waitUntil` on DBOS `recv`), and shell and file tools wait too unless the person allowed them. The run status is `waiting_takeover` and the timeline shows `lease.changed`. After hand-back the next tool result starts with the person's note and a reminder to take a fresh snapshot. `computer.request_takeover` creates a takeover request, notifies the bot's owners with a deep link to the live view and waits until a person takes control and hands back, declines, or 24 hours pass; the outcome is a new run event, `takeover.resolved` {computer_id, outcome, note}, added to the spec's event list. Nothing typed or shown during a takeover reaches the model: screen tools are not called while a person is in control, and input travels only between the viewer and the streamer.

## D-059 Desktop computers use the Xorg dummy driver and agent-desktop

- **Decision**: the desktop image runs Xorg with the dummy video driver instead of Xvfb, because Neko changes the screen size through RandR. Desktop tools drive apps through agent-desktop's accessibility refs (`desktop.snapshot`, `click`, `type`, `press`, `launch`), with coordinates and xdotool as the fallback. `desktop.screenshot` saves a PNG for the user; screenshots are not sent to the model as images yet (the tool result type is text only).

## D-060 Measuring live-view latency

- **Decision**: latency is measured as the round trip of Neko's ping over the WebRTC data channel through the relay, in the server tests (werift client) and in the app (shown in the live view). Locally it is 1–3 ms; the spec's "under 500 ms on 4G" needs a real phone on a mobile network and a public relay (tracked in NEEDS-FROM-OLIVER).

## D-061 Dependencies at their latest compatible versions

- **Decision**: new dependencies are added at their latest compatible version, and constraints are kept tight to what is resolved (`pub upgrade --major-versions`, then `--tighten`; `pnpm add <pkg>@latest`). Upgrades are a separate commit and must pass analyze, every test suite and the web, Android, iOS and macOS builds. When a package cannot reach its latest version, pin the newest that works and record why here.
- **Current pins (2026-11-09 upgrade)**: Dart SDK floor `^3.13.0` everywhere. `build_runner ^2.16.2` (not 2.17): 2.17 needs `build` 5, while `copy_with_extension_gen` 18 (used by the generated API client) still needs `build` 4; the generator script sets these constraints so `pnpm gen` keeps them. Transitive packages held back by others: `material_color_utilities` and `test_api` (pinned by the Flutter SDK), `cross_file` 0.3 (file_picker, share_plus) and `equatable` 2 (an upstream plugin). Android minSdk stays 26 because `sentry_flutter` requires it (D-063 keeps Sentry on the client).
- **Codegen (D-039 revisited)**: riverpod_generator, freezed, json_serializable and build_runner now resolve together. The app stays without codegen for now (no benefit worth the churn); the conflict is no longer a reason.

## D-062 Object storage: filesystem or SeaweedFS self-hosted, Cloudflare R2 hosted

- **Decision**: snapshots, checkpoints and (later) attachments stay behind the `ObjectStore` interface with two implementations, filesystem and S3-compatible. Self-hosted default: the filesystem store on a Docker volume (nothing extra to run on one host). Self-hosted S3: SeaweedFS (Apache-2.0, actively maintained), an optional `s3` compose profile, with `S3_CREATE_BUCKET=true` to create the bucket on start. MinIO was the obvious choice, but its community images are no longer published, so it is not a dependable default. Hosted Kasama: Cloudflare R2, because every wake downloads a whole home directory and R2 has no egress fees (S3 would bill each restore). AWS S3 and Supabase Storage's S3 endpoint work through the same settings. The S3 store is tested against SeaweedFS (`packages/sandbox/test/object-store.test.ts`).
- **Other Cloudflare products**: Turnstile is worth offering, but only as configuration: Supabase Auth supports it as its captcha provider (documented, off by default; it needs a site key). Cloudflare Tunnel helps self-hosters without a public IP expose the API and webhook endpoints (documented as an option, no code); it cannot carry the TURN relay's UDP. Workers, Queues and Access add nothing over DBOS queues, the Hono API and Supabase Auth, and would tie core features to one vendor, so they are not used.

## D-063 Error reporting: Sentry protocol by default, PostHog optional

- **Decision**: errors go to one reporter behind the observability interface (`ErrorReporter`): `ERROR_REPORTING=auto|sentry|posthog|none`, where auto picks Sentry when `SENTRY_DSN` is set, else PostHog when `POSTHOG_API_KEY` is set, else nothing. The Sentry SDKs stay the default path because their DSN works with sentry.io, self-hosted Sentry and GlitchTip (one container plus Postgres), which keeps self-hosting light; PostHog's self-hosted stack is much heavier. PostHog is fully supported for teams that want one dashboard (errors, analytics and flags) with a configurable host (cloud region or self-hosted). The app does the same with build-time keys and adds PostHog screen analytics when a PostHog key is set, without person profiles or session replay.
- **Privacy**: every payload is scrubbed before it leaves: request bodies, headers, cookies and users are dropped, secret-looking values and emails are redacted, context keeps only ids, codes and numbers (no prompts, messages, tool arguments or keys), and PostHog stack frames lose their source lines. Tested in `packages/observability/test/errors.test.ts` and `client/test/telemetry_test.dart`.
- **Android**: minSdk stays 26 because `sentry_flutter` requires it.

## D-064 Default model: GPT-6 Luna at medium reasoning effort

- **Decision**: wherever Kasama suggests a model it uses GPT-6 Luna: `openai/gpt-6-luna` on OpenRouter and `gpt-6-luna` on OpenAI (ids checked against OpenRouter's model list and OpenAI's model page on 2026-11-09). There is no separate "Medium" model: GPT-6 Luna takes a reasoning effort of none to max, and medium is OpenAI's default, so the default model runs at medium unless a bot sets `reasoning_effort` (new optional field on `ModelChoice`; sent as `reasoning.effort` to OpenRouter and `reasoningEffort` to OpenAI, whose function calling with reasoning needs the Responses API the AI SDK uses). The defaults live in `@kasama/domain`, can be overridden per server (`DEFAULT_MODEL_OPENROUTER`, `DEFAULT_MODEL_OPENAI`, `DEFAULT_REASONING_EFFORT`) and are served in `/v1/config`; onboarding, the New bot sheet and `kasama bot create` preselect them for the chosen key's provider and never overwrite a model the user typed. Key tests use the default model with effort `none`. Recorded fixtures keep their fixture ids.
- **Live checks**: `scripts/live-check.sh` reads a real OpenRouter key from `~/.config/kasama/openrouter.env` (or the environment) and runs a handful of capped calls: the key test, one live tool call that drives a real Docker computer, and (with `LIVE_APP=1`) a live chat in the macOS app. CI and the default tests use fixtures and need no key.

## D-065 Voice runs on the user's own keys, through the worker

- **Decision**: dictation (OpenAI `gpt-4o-mini-transcribe` or Deepgram `nova-3`), read aloud (ElevenLabs, OpenAI, Cartesia or Fish Audio, cached per message and voice in `tts_cache`) and live-call sessions all use the workspace's own provider keys, so they run as short worker workflows on their own `voice` queue (only the worker reads Vault). Live calls use OpenAI Realtime over WebRTC (GA interface, default `gpt-realtime-2.1`): `POST /v1/voice/session` mints a 10-minute ephemeral key carrying the bot's persona and tools, the app connects to OpenAI directly, and each function call goes to `POST /v1/voice/tool`, which runs it as an agent run (trigger `voice`, no model step) with the bot's normal approvals and returns the output for the model. Transcripts are saved to the conversation, and every minute, second or character is in `usage_ledger`. Queue polling dropped from 1 s to 50 ms (voice) and 100 ms (runs): a forwarded tool call answers in about 200 ms locally, and the session mints in about 30 ms. Provider request shapes come from their public docs and were tested against local mocks only.

## D-066 The desktop companion embeds computerd and tunnels through the API

- **Decision**: "Use this computer for bots" runs computerd inside the desktop app on 127.0.0.1 in companion mode: files and working directories must stay inside the folders the user shares (symlinks resolved), each capability (shell, files, browser, desktop) is off until approved, and archives, terminals and the streamer are refused. The app opens one WebSocket to `/v1/local-computer/connect` (device token, kept in secure storage or a 0600 file), and the API forwards HTTP requests from the worker's `local` provider over it (internal `/internal/local/*`, shared secret derived from `DATABASE_URL`), streaming responses back. Only bots the user allowed may act (checked against the run's bot on every call), high-risk actions always ask on this provider, and an overlay plus the tray show which bot is acting, with Stop. agent-browser runs in its own `kasama` namespace and session, never touching the user's other browser sessions. Without a sandbox supervisor, personal computers still work. One API instance holds the device sockets (a multi-instance API needs sticky routing; noted for later). The macOS app runs without the App Sandbox so it can start agent-browser and shell commands; it ships with Developer ID signing and notarization rather than through the Mac App Store.

## D-067 Mobile and desktop extras

- **Decision**: one iOS WidgetKit extension holds the home-screen widget (bot status, today's cost, Ask button) and the Live Activity (a running bot on the lock screen and Dynamic Island, `LiveActivitiesAppAttributes`), sharing data through the App Group `group.dev.kasama.app`; Android has an AppWidgetProvider. Share to bot uses receive_sharing_intent on Android and a small native share extension on iOS that saves the shared text to the App Group and opens `kasama://app/quick-ask`. The desktop app adds a tray or menu-bar icon with status and a global shortcut (Cmd/Ctrl+Shift+K) for quick ask. The app now draws immediately and connects behind a startup screen with a timeout and Retry; before, an unreachable server left the release build on the splash screen forever.

## D-068 Owner admin console

- **Decision**: instance owners are `INSTANCE_ADMIN_EMAILS`, or the first user to sign up when unset (the usual self-host case). The console shows totals, users, workspaces with quotas (stored in `entitlements.limits`), configured services and their health, and update notices from `UPDATE_CHECK_URL` (a GitHub "latest release" API URL; off by default, so no phoning home).

## D-069 Publishing the SDK and CLI

- **Decision**: `kasama_api` and `kasama_sdk` are pub.dev-ready at 0.6.0 (publishable metadata, example, LICENSE, CHANGELOG; `dart pub publish --dry-run` clean apart from uncommitted files), with versions set by the generator. The CLI builds to native binaries per platform (`scripts/release-cli.sh`, `.github/workflows/release.yml` on `cli-v*` tags as a draft release) and `scripts/homebrew-formula.sh` writes the formula for a `stackwares/homebrew-tap` repository. Publishing and creating the public tap are outward actions left to a maintainer. `examples/sdk_sample` is an external app that depends on `kasama_sdk: ^0.6.0` exactly as a pub.dev user would (a `dependency_overrides` block points at this repository until it is published).

## D-070 Billing: one provider interface, server-side entitlements, off when self-hosted

- **Decision**: billing lives in `apps/server/src/billing` behind one `BillingProvider` interface (`verifyWebhook`, `parseEvent`, `fetchSubscription`, `verifyPurchase`, `createCheckout`, `customerPortal`, `fetchPayment`, `reportUsage`) with three adapters written with plain `fetch` and `jose` (no vendor SDKs): **Dodo Payments** (hosted checkout with `metadata.org_id`, customer portal, Standard Webhooks signatures with a 5-minute tolerance, usage events for metered plans), the **App Store** (App Store Server API with an ES256 key; every signed payload's x5c chain must lead to Apple Root CA - G3, shipped in the repo, with Apple's marker extensions on the intermediate and leaf; Server Notifications V2) and **Google Play** (subscriptionsv2 with a service-account token, acknowledgement, real-time developer notifications authenticated by a secret push-URL token or the Pub/Sub OIDC token). Every provider is optional and configured by environment variables.
- **Rules**: every webhook is stored in `billing_events` and processed once by `(source, event_id)`; the payload is never trusted, the server re-fetches the subscription. Purchases belong to the workspace: Dodo checkouts carry the org id, and the apps pass the org id as `applicationUserName` (App Store `appAccountToken`, Play `obfuscatedAccountId`), so a store purchase cannot be linked to another workspace and Restore Purchases is idempotent. Refunds (Dodo refunds and lost disputes, App Store REFUND/REVOKE, Play voided purchases and revocations) mark the subscription `refunded`, which later events cannot undo; cancellation keeps access to the period end on the stores, while a Dodo `cancelled` status ends it. The entitlement (best entitled subscription by plan order, else the default plan) is computed on the server and is the only input to quotas and paywalls; owner overrides from the admin console (`entitlements.overrides`) survive plan changes.
- **Credits**: `credit_ledger` is append-only with a running balance; `credit_apply()` applies each `(org, reason, reference)` once. Plans grant included credits once a month per plan. Usage that the platform pays for (computer and stream seconds, Cloud Connect model calls; `usage_ledger.billable`) becomes credit deductions in a worker job every minute; usage on the workspace's own model keys is never charged. Kasama Cloud plans set `credit_gate`, so a run is refused (`out_of_credits`) when the balance is at or below zero, and `computer_hours` caps the month; `max_bots` and `max_computers` return 402 `plan_limit`, which opens the paywall in the app.
- **Store rule in the app**: iOS sells subscriptions with in-app purchase and shows the web checkout link only on the US storefront; Android uses Google Play billing; web and desktop use Dodo checkout. Credit packs are sold on the web only (the stores are not required to sell them). Re-check store rules every quarter.
- **Self-hosting**: `BILLING_ENABLED=false` is the default: no paywall, the `selfhost` plan has no limits, `/hooks/billing/*` and `/connect/*` are not served, and the Billing entry is hidden in the app. Plan names, prices and limits are placeholders (`free`, `pro`, `pro_yearly`, `credits_10`); product ids are set per deployment in the `plans` and `credit_packs` tables.
- **Testing**: Dodo, the App Store Server API (with a throwaway openssl PKI that mimics Apple's chain) and the Play Developer API are local fakes using the documented shapes (`apps/server/test/fake-billing.ts`); `apps/server/test/fake-billing-server.ts` runs them for manual and device tests, where opening a checkout URL "pays" and delivers the signed webhook. Dodo request and webhook shapes were checked against docs.dodopayments.com on 2026-11-10; the refund webhook schema is not documented there, so the adapter reads `payment_id` and re-fetches the payment.

## D-071 Cloud Connect: a self-hosted instance uses cloud computers and model credits

- **Decision**: a Kasama Cloud workspace admin creates a Cloud Connect key (`kcc_…`, stored as a SHA-256 hash, scopes `computers` and/or `models`) for a named instance. The cloud API serves `/connect/v1/*` to those keys: `whoami`; `sandbox/*`, the supervisor API scoped to the workspace (the first create or resume of a ref claims it; other workspaces see it as not running and cannot use it; object deletion is limited to the workspace's own refs; live view and terminals are not proxied in v1); and `models/chat/completions`, an OpenAI-compatible proxy to the cloud's own upstream (OpenRouter by default) that forces usage reporting, passes streams through and bills the upstream's reported cost (or the price table) times `CLOUD_MODEL_MARKUP`. Computer time is metered on the proxy from create or resume to sleep or delete (and flushed every minute while running) at `CLOUD_COMPUTER_USD_PER_HOUR`. Everything lands in the cloud workspace's `usage_ledger` with the instance name, so it shows on the cloud bill and is deducted from credits; credit-gated workspaces get 402 at zero.
- **Self-hosted side**: setting `KASAMA_CLOUD_URL` and `KASAMA_CLOUD_KEY` adds the `kasama-cloud` computer provider (the supervisor client pointed at the proxy); computers created with `provider: "kasama-cloud"` run in the cloud. Model credits need no new code: a workspace adds an OpenRouter credential whose base URL is `<cloud>/connect/v1/models` and whose key is the Cloud Connect key, so the default model and reasoning settings pass through unchanged.
- **Verified**: a self-hosted API and worker ran a bot's shell command on a cloud Docker computer through the proxy, and the computer time showed on the cloud bill and reduced its credits (`apps/server/test/cloud-connect.test.ts`); one live call through the proxy to OpenRouter (GPT-6 Luna, 16 output tokens max) was billed from OpenRouter's reported cost.

## D-072 Privacy: export, deletion with a grace period, retention

- **Decision**: `GET /v1/me/export` streams a ZIP of JSON files built under the user's own session, so it holds exactly what RLS lets them see (account, notifications, and per workspace: bots, conversations, messages, runs and events, memories, routines, computers, usage, audit log...), without Vault references, token hashes, vectors or audio. `DELETE /v1/me` (confirmed by typing the email) bans the auth user, ends sessions and removes push devices at once, then a daily worker job purges after `ACCOUNT_DELETION_GRACE_DAYS` (default 7, max 30): workspaces the user solely owns (their computers' archives first, then the rows by cascade) and the auth user. Shared workspaces lose only the membership. Run events are deleted per workspace after `run_event_retention_days` (default 180, 7 to 3650, admins set it). Settings → Privacy in the app and `kasama account export|delete` in the CLI.

## D-073 Enterprise features in ee/ under a commercial license

- **Decision**: `ee/` is a workspace package (`@kasama/ee`) under a draft source-available license (read and try freely; production use needs a key; no resale or hosting for others); everything else stays Apache-2.0. Keys are Ed25519-signed JWTs (issuer `kasama-licensing`, features, seats, expiry) verified against `ee/server/license-public.pem`; the private signing key lives outside the repo (`~/.config/kasama/license-signing-key.pem` on the build Mac, to move into a password manager). First features: audit-log export (CSV/JSON, admins) and SAML SSO through Supabase Auth's admin API (the self-host stack enables SAML with a generated key; the app gains "Continue with SSO"). Without a key the routes answer 402 `license_required`. Advanced roles are planned.

## D-074 Opt-in telemetry

- **Decision**: off unless `TELEMETRY=on`. A weekly worker job posts a random instance id (stored in `instance_settings`), the version, and the counts of bots and users active in the last 7 days to `TELEMETRY_URL`; Kasama Cloud stores pings in `telemetry_pings` with strict validation. Nothing else is sent. Documented in SELF_HOST.md and the admin console shows the state.

## D-075 Metrics, dashboards and alerts

- **Decision**: the API serves Prometheus text at `/metrics` (bearer `METRICS_TOKEN`; off in production without one), computed on scrape from Postgres over short windows: runs by status and failure ratio (15 min), time to first token p50/p95 (new `runs.first_token_at`, set at the first model token or tool call), computer start time p50/p95 (from `computer.state` events), computers by state, cost per run, DBOS queue depth, and API response counters. `infra/monitoring/` holds the Prometheus config, alert rules (run failures above 5% over 15 minutes, host memory above 85%, p95 first token above 3 s, queue backlog, API down) and a provisioned Grafana dashboard, started with the compose profile `monitoring`. Langfuse LLM traces are not built; spans and the cost ledger cover it for now.

## D-076 Self-host installer and server choice in the apps

- **Decision**: `infra/compose/docker-compose.yml` runs the whole stack on one machine: Supabase's Postgres, GoTrue, PostgREST, Realtime and Kong (images pinned to the versions the Supabase CLI uses), a one-shot `migrate` service that waits for Auth and Realtime to create their schemas and applies `supabase/migrations` once each (tracked in `kasama_migrations`), the API and worker (one image, Node 26, pnpm installed directly since corepack left Node), supervisor, egress proxy, TURN relay and Caddy (one public address: `/v1`, `/hooks`, `/connect` to the API; `/auth/v1`, `/rest/v1`, `/realtime/v1` to Kong). Optional profiles: `web`, `s3`, `monitoring`, `images`. `install.sh` checks Docker, generates every secret with OpenSSL (including the Supabase anon and service JWTs and a SAML key), writes `infra/compose/.env` once (re-runs keep it and only add new keys), builds and starts, and waits for readiness; `kasama selfhost init|up|down|status|logs|upgrade|backup|restore` wraps it. Empty environment values now count as unset. The apps let users enter a server address at sign-in or on the can't-connect screen (remembered; switching reconnects), and the web build uses its own origin when built with an empty `KASAMA_API_URL`. PaaS templates (Render, Railway, DigitalOcean) run the API and worker against a Supabase project; Coolify runs the full compose file.

## D-077 Kasama MCP server

- **Decision**: `packages/mcp` (`kasama-mcp`, stdio) exposes `list_workspaces`, `list_bots`, `ask_bot` (sends a message and polls the run until it completes, fails or waits for approval, returning the reply, tools used, cost and ids), `get_run`, `list_approvals` and `decide_approval`. It authenticates with the CLI's saved session (refreshing it through Supabase Auth) or `KASAMA_TOKEN`, and the server address from `KASAMA_API_URL` or the CLI config. Tested with a real MCP client over an in-memory transport against the test API and worker.

## D-078 Evals and load test

- **Decision**: `packages/evals` holds 30 tasks with automatic checks (reasoning, research on local pages, files, code fixes that must pass their test, output formats, approvals, prompt-injection refusal, secrets, browser forms, MCP, memory, delegation, routines); tasks needing internet, a search key or an MCP server are skipped unless enabled. Ten form the quick subset that guards pull requests touching `packages/agent`. The runner records success rate, cost, steps and time, and compares with `baseline.json` per mode and subset (fixture mode replays scripted model turns to check the harness and tools; live mode uses the default model). The load test (`apps/server/load`) creates 200 webhook bots and 100 chat bots, fires the webhooks together with k6, then opens 100 chat streams, and reads time to first token from Postgres.

## D-079 Model picker

- **Decision**: New bots pick their model from a searchable list instead of a free-text id. `GET /v1/credentials/{id}/models` asks the worker (the only process that reads Vault) for the key's live model list: OpenRouter's public catalog, the OpenAI, xAI and Anthropic model endpoints, Google's `generateContent` models, or `<base_url>/models` for OpenAI-compatible servers such as Ollama. Embedding, image, audio and batch models are dropped. Kasama's short recommended list (`FEATURED_MODELS` in `@kasama/domain`) comes first; if the provider can't be reached, or the worker runs on fixtures, the picker shows that list and says so. Any model id can still be typed in. Live lists are cached in the API for 10 minutes. A blank bot is named "Chief"; when a workspace has no chat-model key yet, the new-bot sheet shows the add-key form in place.

## D-080 Firebase project for official builds

- **Decision**: Official Kasama apps use the `kasama-ai` Firebase project for push. Its public client identifiers live in `client/config/firebase.json` (passed with `--dart-define-from-file`), per platform: one Apple app for iOS and macOS (bundle `dev.kasama.kasamaApp`), one Android app, one web app. The worker reads `FCM_SERVICE_ACCOUNT` (JSON text or a file path); without it push is off and the in-app inbox still works. Firebase stays optional: self-hosters who build their own apps point both settings at their own project. A self-hosted server can't push to the official store apps, since only the `kasama-ai` key can address them; a push relay through Kasama Cloud would cover that later. Opening a notification (in the inbox or from a push, which carries `notification_id`) marks it read.

## D-081 Client design system

- **Decision**: The apps share one design system, after the look of our openrc app. FlexColorScheme 8 (8.4: version 9 is built on the separate `material_ui` package and does not work with this Flutter) supplies the base Material 3 theme. On top of it: neutral surfaces in light and dark whatever the accent (the accent colors controls and selection only), hairline-bordered cards (18px), 14px input fields, pill buttons, 28px sheets, and pill tabs. Nunito (OFL, bundled) sets headlines; body text uses each platform's own font (San Francisco on Apple platforms; Apple's font license doesn't allow shipping it in this repository), with tracking tightened for it. Tokens live in `client/lib/theme` (spacing, radii, motion, semantic colors). Shared components live in `client/lib/ui`: card, grouped list, header and round header buttons, floating tab bar, adaptive sheet (a sheet on phones, a dialog on larger windows), segmented control, bot avatar, Kasama mark, and a small motion kit. The motion kit runs on animation controllers rather than timers, so nothing is left running when a widget goes away. Layout: a floating pill tab bar on phones (hidden inside a chat), a rail on tablets, and on desktop a sidebar with the bot list, the chat, and a collapsible computer panel. In chat, tool steps read in plain words and consecutive steps share one card. Settings → Appearance picks light, dark or system and one of seven accents, kept on the device.

## D-082 One-time routines, attachments, file links and visible takeovers

- **Decision**:
  - **One-time routines.** Routines have a `once` trigger with `run_at`. The scheduler runs it a single time, then switches it off. The bot's `routines.create` takes `in_minutes` or `run_at` for one-time work and `schedule_cron` only for work that repeats. This fixes "remind me in a minute" becoming an every-minute cron.
  - **Managing routines.** Bots also get `routines.list` and `routines.delete`, and a routine's run is told which routine started it. The API and app can delete routines.
  - **Attachments.** The app uploads files to the bot's computer (`~/workspace/uploads`), straight away when you pick or drop them. The message carries them as `file` parts: path, name, type, size. Every model sees the file list. Up to four images (5 MB each) also go to vision models as images.
  - **Ways to attach.** Files work everywhere. The photo library works on mobile and macOS, the camera on mobile, and drag and drop on desktop and web.
  - **File links.** Bots are told to link files they make with their home-relative path, like `[report.md](workspace/report.md)`. The app maps such links, and stray `sandbox:` or `file:` ones, to the files API. It opens them in a preview with Open, Save and Share.
  - **Visible takeovers.** Desktop computers run the bot's browser headed (`AGENT_BROWSER_HEADED`, maximised), and the taskbar has a Browser launcher. Bots on headless computers can ask for a takeover too. The run switches that computer to the desktop profile (files are kept) and reopens the bot's current page in a visible window, so the person lands on the sign-in page.

## D-083 One page width, one form layout

- **Decision**:
  - **One page width.** Settings and every screen under it, the bot list, inbox, computer panel, activity and run timeline share one centered column (`kPageMaxWidth`, 680) with 16px gutters on phones, through `SubPage`, `PageColumn`, `PageListView` and `pageSide` in `client/lib/ui/page.dart`. No screen picks its own width.
  - **One form layout.** Every form, prompt and notice uses `FormSheet` (`client/lib/ui/form_sheet.dart`). It has a tinted icon tile, a title and a line of help, then fields 16px apart with leading icons and helper text. Phones get full-width buttons, main action first. Larger windows get a right-aligned row, main action last. `showConfirm`, `showTextPrompt` and `showChoiceSheet` (pick one of a few options) are built on it, so no stock `AlertDialog`s are left.
  - **Above the shell.** Adaptive sheets and dialogs open on the root navigator, so a phone sheet covers the floating tab bar rather than sliding under it.
  - **Labels, not raw values.** Computer states and run statuses show words ("Asleep", "Done"), never API values. Settings rows each carry a one-line description. Accents grew to 17, laid out in balanced rows.

## D-084 Type: Fraunces, Figtree, JetBrains Mono

- **Decision**: Three bundled typefaces, all SIL OFL 1.1 (`client/assets/fonts/*-OFL.txt`), and none fetched at runtime:
  - **Fraunces** (72pt optical size, the soft cut, SemiBold and Bold) for display, headline and large title styles: page and sheet titles, greetings, Markdown headings and avatar initials. A warm serif suits the cloud mascot and sets the app apart from the sans-only AI chat apps.
  - **Figtree** (Regular to ExtraBold) for the rest of the interface and body text, bold labels included.
  - **JetBrains Mono** for code, terminal output and tool arguments.
- **Replaces** Nunito plus the platform font (D-081). `AppFonts` names the families. The text theme maps display, headline and titleLarge to Fraunces and everything else to Figtree.

## D-085 Color schemes, wallpapers, Lucide icons and the message menu

- **Decision**:
  - **Color schemes.** Settings → Color scheme replaces the accent swatches. It offers Kasama's own scheme first, then every FlexColorScheme built-in. Each has a live preview. You can search by name or description, or filter by color family (worked out from each scheme's primary hue). The pick applies immediately and is kept on the device.
  - **Brand default.** The default scheme comes from the app icon: plum primary, the orb's sky blue as secondary and cyan as tertiary. Light and dark both keep the scheme's own primary, secondary and tertiary colors. Surfaces blend lightly with the scheme instead of being fixed neutrals.
  - **Wallpapers.** Settings → Background sets a Telegram-style wallpaper: a doodle pattern drawn from Lucide glyphs (clouds, doodles, treats, garden, space, pets, seaside or tech), a soft four-color gradient (theme colors or a preset), the pattern's strength, and whether it shows on every screen or only behind chats.
  - **How wallpapers are painted.** A `WallpaperTheme` extension carries the settings, and the theme's page transitions paint the wallpaper under every page. Scaffolds and headers are transparent. Patterns are painted in window coordinates, so the sidebar, chat and computer panel join up. Bubbles and cards are opaque so text stays readable.
  - **Pages.** Every route now builds a `MaterialPage`. go_router's fallback had been a page with no transition, because it doesn't recognize this Flutter's MaterialApp. Pages now animate the way each platform expects.
  - **Icons.** Lucide (`lucide_icons_flutter`) replaces Material icons app-wide. Brand marks (Apple, Google) stay as they were. `cupertino_icons` is available for Apple-specific spots.
  - **Message menu.** Bot replies get bubbles, and the copy and read-aloud buttons under each one are gone. On touch screens, a long-press opens Copy, Read aloud, Select text and Share. With a mouse, text selects by dragging, and the right-click menu adds the same actions.
  - **Share sheets** are anchored to the control that opened them, which iPad and macOS popovers need.
  - **Keyboard.** The tablet and desktop shells no longer resize for the keyboard, since the screens inside them already do. Resizing twice hid the composer.

## D-086 Interactive bot UI with A2UI (a2ui_flutter)

- **Decision**: Bots can show small interactive UIs in the chat, such as choice buttons, short forms and option cards, with the A2UI protocol v1.0 and its basic catalog. The app renders them with `a2ui_flutter` and `a2ui_core`, the Flutter team's replacement for `genui`.
  - **Tool.** Bots get a `ui.show` tool. It takes a flat component list (the one with id `root` is the top) and optional starting data. The server checks the tree and rewrites v0.9-style `{path}` bindings to v1.0's `{"@path"}`. It then wraps everything in `createSurface` / `updateDataModel` / `updateComponents` messages and emits a `ui.shown` run event, so the UI appears while the run is live. The final reply stores each surface as a `ui` part, so it is still there after a reload. The tool tells the model to end its turn.
  - **Rendering.** The app renders each surface with the basic catalog in its own theme, inside a bot bubble. Links open externally, and only for http(s). A surface that fails validation shows a short note instead.
  - **Answers.** A button or submit action sends a normal message whose text summarizes the chosen values, plus a `ui_action` part (surface id, action name, resolved context). The model reads it as text. An answered UI stays in the thread, dimmed and marked sent.
- **Why**: A few taps beat typing for picking options or filling 2 to 5 fields. A2UI is an open protocol, the renderer is a client library, and any model can produce the tool's JSON, so nothing depends on a hosted service.

## D-087 Fonts, theme presets, photo wallpapers, glass, glow buttons, error details and usage

- **Fonts**: Google Sans for text and Noto Serif for headlines are the new defaults (supersedes the defaults in D-084). They ship with the app with real weights, as do Fraunces and Figtree, so a self-hosted app works offline. Settings → Fonts picks a heading and a text font from a short suggested list or any Google Font; those download through `google_fonts` the first time and are cached. Bundled families are declared in pubspec rather than loaded through `google_fonts`, because `google_fonts` fixes each style to one weight and later bolding becomes faux bold. Text styles use even leading so text sits centered in fields and buttons whatever the font's metrics (this also fixes the composer hint).
- **Theme presets**: a preset is scheme + fonts + wallpaper (Kasama, Editorial, Ocean, Forest, Sakura, Sunset, Cosmos, Graphite). People save their current look as a theme and share it as a `kasama-theme:` code (base64url JSON, versioned). Local photos stay on the device; shared codes only carry https photos. The code format is what a future theme gallery would exchange.
- **Photo wallpapers**: your own photo (stored in the app support folder; a data: URI on the web) or a photo from the server's optional photo source, drawn blurred and dimmed under the pattern, in window coordinates so panes line up. The photo source is behind a `WallpaperSource` interface with an Unsplash implementation, on only when `UNSPLASH_ACCESS_KEY` is set (`config.wallpapers_enabled`). Searches go through the server so the key never ships in the app; choosing a photo calls Unsplash's download endpoint, and the photographer is credited, as Unsplash's API terms require. Pexels would fit the same interface. AI-generated wallpapers were left out: they cost money per image and need a hosted model.
- **Glass and buttons**: panes over the wallpaper (sidebar, computer panel, composer) are frosted glass, a backdrop blur plus a translucent tint. Main actions are `GlowButton`, a filled button with a soft gradient, a gloss edge and a glow in its own color. Secondary buttons stay flat so the main action is always the one that stands out.
- **Sidebar**: on large screens, bots come first; Inbox, Computer and Settings sit at the bottom, and Settings shows the account email. The separate account row is gone.
- **Error details**: a failed run's notice says why in plain words (missing key, auth failure, rate limit, or the first line of the error with tokens redacted). Tapping it opens the details: tool and run errors from the run's events, with Copy (plain text), Export (JSON) and a link to the run timeline.
- **Usage**: `GET /v1/usage` adds `by_day`, `by_model`, `by_kind` and `runs`, plus `week` and `year` periods (new fields are optional, so older clients are unaffected). Settings → Usage shows totals, spend by day (by month for a year), by bot, by model and everything metered; it exports CSV or JSON, and "Ask a bot about this" opens Quick ask with a plain-text summary ready to send.

## D-088 Persona templates

- Starter bots grew from five to twenty personas in five groups (work, research, build, create, life). Each has full standing instructions (a system prompt: role, how it works, style, limits), a Lucide icon, a suggested cloud mascot, and starter prompts. Some also bring skills or routines.
- The new-bot sheet's "Persona" field opens a searchable gallery with a preview of each persona's instructions. Picking one fills in the name, the mascot and the instructions, all editable. Bot settings has "Load a persona" to replace the instructions later.
- An empty persona on create now falls back to the template's instructions (it used to save an empty one).

## D-089 Built-in app connections

- Settings → Apps lists 27 apps that run their own hosted MCP servers (GitHub, Sentry, Linear, Notion, Stripe, Jira & Confluence, Gmail, Google Calendar and Drive, Figma, Slack, Zapier, Airtable, HubSpot and more). Endpoints were checked against vendor docs on 2026-11-10. No Composio or Pipedream is needed for these.
- **One-click sign-in** follows the MCP authorization spec: protected-resource discovery, then a client from dynamic registration, Kasama's client metadata document (`/oauth/client.json`, needs a public https API), or an admin-registered client (`MCP_OAUTH_CLIENTS`; Google uses `GOOGLE_OAUTH_CLIENT_ID`), always with PKCE and the `resource` parameter. The vendor redirects to `/oauth/callback`. Tokens go to Vault with what is needed to refresh them, and refresh happens when a connection is loaded within two minutes of expiry. Sign-ins in progress live in `integration_oauth_flows` (service role only, 15-minute expiry, single use).
- Checked live: discovery, registration and a valid sign-in link from Linear, Sentry, Notion, Stripe, Atlassian, Supabase, Zapier, Neon, PostHog, monday.com, Webflow, Intercom and Airtable. Cloudflare Docs, Hugging Face, Context7 and Exa connected without sign-in and listed tools. Asana, Slack, HubSpot, Box, Figma and Google need a client the admin registers, and Vercel needs a public https server. The catalog marks those as "Needs setup" and the connect sheet says why and which redirect address to register.
- **API keys** are the alternative where vendors offer them. The connect sheet gives steps and a link to the vendor's key page, and the key is tested on save.
- **Management:** each connection has a page with health, reconnect, test and disconnect (which deletes the Vault secret). It also controls which bots get the connection and each tool's approval level (read-only, makes changes, always asks), stored as `risk_overrides`. Legacy SSE endpoints are supported.
- **Composio and Pipedream** are guided: a key step with a link to get one free, then a searchable app directory where picking an app opens the provider's hosted sign-in. Connected accounts show with their status. Written from their public API docs and tested against fakes only.
- **Logos** come from Simple Icons (CC0), shown on brand-colored tiles. Apps without one get their initial.


## D-090 Usage answers, truthful computer state, resizable computer panel

- Bots have a read-only `usage.report` tool: the workspace's spend and usage for a day, week, month or year, by bot, model, day and metered kind. "Ask a bot about this" on the Usage screen now picks a bot, starts a new chat and sends the summary directly, instead of passing it through Quick ask. Quick ask is also keyed by its address, so it never shows stale text.
- **Computer state matches the sandbox.** Listing computers reconciles each one with its provider (at most 1.5 s): a row that says running without a live container becomes asleep, and an asleep row with a live container becomes running. The Computer panel refreshes itself while visible (every 3 s while waking, otherwise every 10 s, and on returning to the app). The Start button now reads "Wake up", shows progress while the computer starts, and offers a retry with the error when starting failed. The live view still wakes a sleeping computer, and the screen now says so ("Wake up and watch live").
- **Resizable computer panel:** on wide screens, drag its left edge to resize it. It stays between 360 px and 60% of the window, and the chat keeps at least 420 px. Double-click the edge to reset it. The width is kept on the device.

## D-091 ChatGPT plan sign-in

- **What:** people with an eligible ChatGPT plan connect it instead of an OpenAI key, following OpenAI's "Sign in with ChatGPT" plan usage for open-source apps (developers.openai.com/siwc). GitHub Copilot, SuperGrok and Claude plans stay out until their terms clearly allow third-party apps.
- **Where:** `CHATGPT_SIGN_IN=auto|on|off`; auto is on for self-hosted servers and off when `BILLING_ENABLED` is on, because hosted use needs OpenAI's approval through its interest form (NEEDS). `/v1/config` reports `chatgpt_sign_in` so the apps hide the button where it is off.
- **Sign-in:** OpenAI redirects only to `http://127.0.0.1:<port>/auth/callback`, so the desktop app and the CLI run a loopback listener (`kasama_sdk/chatgpt_sign_in.dart`, shared by both; `kasama credential chatgpt`). `POST /v1/credentials/chatgpt/start` stores a single-use flow in `integration_oauth_flows` (state, nonce, PKCE verifier) and returns the authorize URL; `POST /v1/credentials/chatgpt/complete` exchanges the code on the server, verifies the ID token against OpenAI's JWKS (issuer, audience = issued client, nonce) and writes the tokens to Vault. Tokens never reach the device. The first sign-in uses `dynamic_agent_client` with the product name; later ones reuse the issued client and send `login_hint`. One host id per server (`instance_settings.chatgpt_host_id`, `urn:uuid:`). Phones and the web point to the desktop app or the CLI.
- **Credential:** `model_credentials.provider = 'chatgpt'` with `owner_user_id`, `status` (ok, plan_usage_off, needs_reconnect), `settings.fallback_on_limit`, `oauth` (issued client id, subject, email) and `refreshed_at`. Personal: runs use it only when the run acts for its owner (the sender, the routine's creator, or a parent run's, found by walking up the run tree); otherwise it is skipped (`model.fallback` event) or the run fails with `chatgpt_plan_not_yours`. Admins and the owner can delete it; only the owner tests it or changes its settings. `DELETE /v1/credentials/{id}` (new, for every key) revokes a ChatGPT sign-in through the worker first and deletes the Vault secret. `PATCH /v1/credentials/{id}` renames or sets `fallback_on_limit`.
- **Refresh:** the worker refreshes within 5 minutes of expiry under `pg_advisory_xact_lock` per credential (refresh tokens rotate, so parallel runs reuse the new pair), honors `earliest_refresh_at`, and the hourly maintenance job refreshes plans idle for 20 days. Dead refresh tokens set `needs_reconnect` and notify the owner; network errors never touch the credential.
- **Model calls:** a hand-written Responses adapter (`gateway/chatgpt.ts`), not the AI SDK, so the request carries only what the plan route accepts: `store: false`, `stream: true`, history in `input`, system text in `instructions`, no temperature, max output tokens or previous response id. OpenAI's documented error codes map to Kasama codes: a plan limit (also mid-stream) never retries and moves to the next model only when the owner turned that on; an invalid user marks the credential; 503 retries twice (1 s, 2 s). The model picker lists `/v1/models` entries with visibility "list". Plan tokens go to `usage_ledger` with `source = 'chatgpt_plan'` and cost 0.
- **Tests:** `apps/server/test/fake-openai.ts` fakes the auth server (PKCE, dynamic client, ID tokens, rotating refresh with reuse detection, revocation) and the Responses stream; `chatgpt.test.ts` covers sign-in, reconnect, consent declined, plan usage off, a run at cost 0 with the right request shape, owner-only use, plan limits, single refresh under concurrency, needs_reconnect and revocation. A live check with a real plan is left for Oliver (NEEDS).
- **Open:** the button uses a neutral icon until OpenAI's approved button artwork is added; the "Manage usage" link opens chatgpt.com settings.

## D-092 Pages are web only

- **What:** a page is the bot's self-contained HTML (with its JSON data block), never A2UI. One format serves the app, signed-out public links and headless-Chromium PDF export, so every page can be shared without a second renderer. A2UI stays for cards inside chat.
- **Viewing in the app:** no embedded WebView (the app stays fully native). Pages open in the system's in-app browser: Safari View Controller on iOS and Chrome Custom Tabs on Android (`url_launcher` `LaunchMode.inAppBrowserView`), the default browser on macOS, Windows and Linux, and a new tab on the web.
- **Private and workspace pages:** the system browser has no Kasama session, so the app requests a single-use view link (60 s, bound to page and viewer); the pages origin exchanges it for a short page-scoped cookie. Public links keep their revocable token, optional expiry and `noindex`.
- **Trade-offs accepted:** pages don't inherit the user's Kasama theme beyond CSS variables the bot is asked to use, and buttons on a page can't call Kasama actions (no JS bridge). Actions stay in chat.

## D-093 Two-step sign-in

- **What:** authenticator-app codes (TOTP) through Supabase Auth's MFA on every platform. Settings → Two-step sign-in sets up one or more authenticator apps (QR code or setup key, then a code), lists them and removes them. After the password step, an account with an authenticator goes to a code screen (`/two-step`) before anything else. `kasama login` asks for the code (or `--code`, `KASAMA_2FA_CODE`). Passkeys wait until Supabase Auth supports them.
- **Workspace requirement:** `organizations.require_mfa`, set in the same screen by owners and admins (`PATCH /v1/orgs/{id}/settings`), and reported on each workspace in `/v1/orgs`. Turning it on needs an aal2 session, so nobody locks themselves out. When it is on, `public.has_role` grants owner and admin powers only to aal2 sessions; members are unaffected and owners keep member access. Because every RLS policy and API admin check goes through `has_role`, one change covers them all. The API turns the resulting "Only owners and admins…" refusals into `mfa_required` with a clear message, and Settings tells an affected admin what to do.
- **Config:** TOTP enroll and verify are on in `supabase/config.toml` and the self-host compose file.
- **Tests:** pgTAP (`two_step_rls.test.sql`), API (`two-step.test.ts`: turning it on needs aal2; aal1 admins get `mfa_required`; aal2 works; members unaffected), widget tests for setup, removal, the workspace switch and the sign-in code screen. Real GoTrue MFA was not exercised end to end (mock-only build).

## D-094 Kasama Cloud abuse controls

- **Switch:** `ABUSE_CONTROLS=auto|on|off`, on when billing is on (Kasama Cloud); self-hosted servers keep it all off. The egress proxy has its own `EGRESS_ABUSE=on`.
- **Sign-up check instead of a visible CAPTCHA:** a Turnstile widget would mean web content inside the apps (no embedded web panels), so new email accounts are checked by Supabase Auth's before-user-created hook (`POST /hooks/auth/before-user-created`, Standard Webhooks signature with `AUTH_HOOK_SECRET`). The account's user metadata must carry `signup_proof`: a Firebase App Check token (verified against Google's JWKS for `APP_CHECK_PROJECT_NUMBER`; App Attest, Play Integrity, reCAPTCHA Enterprise; nothing visible) or a solved proof-of-work puzzle from `GET /v1/signup/challenge` (stateless HMAC-signed challenge, `SIGNUP_POW_DIFFICULTY` zero bits, single use). Google, Apple and SSO sign-ups pass. `/v1/config` lists the accepted proofs. The apps (puzzle in an isolate) and `kasama signup` send the puzzle today; App Check tokens come once App Check is set up in Firebase. Refusals are recorded as `signup_blocked`.
- **Verified email:** on Kasama Cloud a free-plan workspace starts computers only when an owner has confirmed their email (`email_unverified`).
- **Egress:** the proxy refuses outbound mail ports (25, 465, 587, 2525), common Stratum ports and a list of mining pools, and reports each hit and each rate-limit flood (once a minute per computer) to the API's `/internal/abuse`. Mining suspends the workspace at once; three floods in an hour do too. Instance owners get a notification.
- **Suspension:** `organizations.suspended_at/suspended_reason`. Suspending cancels running runs, stops (sleeps) computers and keeps data; runs fail at admission with `workspace_suspended`, sending a message answers 403, and computers refuse to start. Owner console: Suspend (with a reason) and Lift on each workspace, and an Abuse tab listing `abuse_events` (service role only). The app shows a banner in a suspended workspace.
- **Tests:** egress proxy (ports, pools, flood report), API (`abuse.test.ts`: unsigned hook, missing proof, OAuth pass, puzzle once, App Check for this project only, reports, suspension and admin actions, computer start checks), SDK puzzle solver, widget tests (suspend and lift, Abuse tab, banner).

## D-095 Least-privilege worker database role

- **What (closes D-016):** migration `20261121000001_worker_role.sql` creates `kasama_worker` (no superuser, no RLS bypass). It gets data access on public tables through one explicit policy per table (`kasama_worker_all`, added by `public.allow_worker(table)`), read on `vault.decrypted_secrets` plus `vault.create_secret`/`update_secret` (no delete), the `extensions` schema, four columns of `auth.users` (id, email, email_confirmed_at, created_at), CONNECT and CREATE on the database (DBOS runs `create schema if not exists dbos` at start) and ownership of the `dbos` schema. It cannot alter public tables or read passwords or other Supabase schemas.
- **Wiring:** `WORKER_DATABASE_URL` (falls back to `DATABASE_URL`). The installer generates `WORKER_DB_PASSWORD`, the compose migrate step gives the role that password, and the worker connects with it. The API keeps the server role.
- **Rule for new tables:** migrations that create a table with RLS also call `select public.allow_worker('public.<table>')`; `worker_role_rls.test.sql` fails otherwise.
- **Tests:** the test harness now runs the worker as `kasama_worker`, and the full API suite passes that way; the pgTAP test checks the policies, that the role is not privileged, column-level auth access and no DDL. Not yet checked on Supabase Cloud, where granting `vault.decrypted_secrets` to a custom role should be confirmed at deploy time (NEEDS).

## D-096 Local MCP servers through the desktop companion

- **Bridge in computerd:** `POST /mcp/<key>` (companion capability `mcp`) speaks MCP Streamable HTTP and bridges to the server: a stdio command (started on first use, stopped after 10 idle minutes, working folder inside the shared folders) or a loopback address (`127.0.0.1`/`::1` only). The bridge owns one session per server: it initializes it once and answers later `initialize` calls from its cache, rewrites request ids and progress tokens so concurrent callers never collide, forwards progress, answers server-initiated requests with "not supported", and cancels in-flight requests when the caller hangs up. This works through the existing tunnel, which forwards only content type and length, so no MCP session header has to cross it.
- **Integrations, not a new table:** each server is an integration of kind `local_mcp` (config: device, computer, owner, key, label, summary, timeout), named `<key>_<device id prefix>`. The app registers them with `PUT /v1/local-devices/{id}/mcp-servers` (owner only); new ones attach to the bots the computer allows; only the owner attaches them elsewhere. Commands are shown to the workspace; environment values stay in the app's secure storage (or a 0600 file) and go only to the embedded computerd.
- **Worker:** `LocalMcpAdapter` calls `<API>/internal/local/<computer>/http/mcp/<key>` with the internal token and the run's activity (the tunnel checks the bot is allowed and the overlay shows the call). Calls may run up to the server's timeout (default 30 minutes, kept alive by progress, tunnel limit two hours for `/mcp/`); progress becomes `tool.output`; cancelling the run aborts the call. Listing tools needs no run: the tunnel allows `initialize`, `notifications/initialized` and `tools/list` without one. Offline computers give a clear error and do not mark the integration broken.
- **Tests:** computerd bridge tests with a fake stdio server (one initialize for many callers, colliding ids, progress, capability, unknown server); an API test through the real tunnel, computerd and stdio server (registration, listing through the worker, owner-only attach, calls with progress, other bots refused); app widget tests (add with env kept on the device, sync without it, remove).

## D-097 Coding agents

- **One tool:** `coding.delegate(agent: claude_code | codex | cursor, task, where: my_computer | bot_computer | cloud, folder?, repo?, branch?, open_pr?, timeout_min?)`. Medium risk; high when it may open a pull request. Output streams to the timeline; the result has the agent's summary (its JSON `result` when it prints one, else the tail of its output), `git diff --stat` and the branch or pull request link. Cancelling the run stops the agent.
- **Headless CLIs, not MCP:** `claude mcp serve` exposes Claude Code's individual tools rather than a whole-task agent, so every agent runs through its headless mode: `claude -p --output-format json` (`--permission-mode acceptEdits` on the user's computer, `--dangerously-skip-permissions` in the bot's sandbox), `codex exec --full-auto`, `cursor-agent -p --force --output-format json`.
- **my_computer:** the run owner's companion computer that allows this bot (companion shell permission and shared folders apply), with their own sign-ins; the overlay shows the agent working. The desktop app lists the agents it finds (claude, codex, cursor-agent in PATH and the usual install folders) and turns on commands in one tap.
- **bot_computer:** installs the CLI on first use (npm for Claude Code and Codex, Cursor's install script) and passes `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` or `CURSOR_API_KEY` from the bot's named secrets in that command's environment only (redacted like every secret). Codex with a ChatGPT plan on the bot's computer is left for later (it needs Codex's own sign-in file).
- **cloud:** Cursor's cloud agents API (`POST /v0/agents`, polled with `GET /v0/agents/{id}`, `DELETE` on cancel) with `CURSOR_API_KEY`; other cloud agents plug in when they publish a start-a-task API. Written from Cursor's public docs and tested against a fake.
- **Tests:** `coding.test.ts` (install and key handling on the bot's computer, missing key, the user's computer through the companion with no keys passed, a Cursor cloud agent to its pull request, risk), widget test for the detected agents.

## D-098 Ticket board

- **Data:** `tasks` statuses are `todo`, `in_progress`, `in_review`, `blocked`, `done` (`doing` became `in_progress`), plus `priority`, `assignee_user_id`, `due_at`, `labels`, `position` (order within a column), `conversation_id` (the ticket's thread with its bot) and `review_required`. New `task_comments` (members comment as themselves; bot comments come from the worker).
- **API:** `POST /v1/tasks`, `PATCH /v1/tasks/{id}`, `DELETE /v1/tasks/{id}`, `GET/POST /v1/tasks/{id}/comments`; tickets list with their comment counts.
- **Bots at work:** assigning a bot (on create, on reassignment, or by another bot with `tasks.create`/`tasks.update`) starts a run with trigger `task` in the ticket's thread (`startTicketWork`, shared by the API and the worker), with a brief that tells the bot how to report. The run moves the ticket to in progress; when it ends, a ticket still open becomes in review (when review is required) or done, with the reply as result and comment; a failed run blocks the ticket, comments why and notifies its owner. A person's comment on a bot's ticket wakes the bot. Moving tickets by hand never wakes a bot.
- **Tools:** `tasks.create` and `tasks.update` take the new statuses, priority and assignee; new `tasks.comment` and `tasks.list`.
- **App:** a Board tab in the main navigation (`/tasks`) with one column per status, long-press drag between columns, filters (all, mine, bots, priority), a new-ticket form and a ticket sheet (status, priority, bot, assign to me, needs review, comments, open the bot's thread, delete). The read-only list left the Inbox.
- **Tests:** pgTAP (`ticket_board_rls.test.sql`), API (`tickets.test.ts`: manual moves don't wake bots; a bot's run finishes a ticket with a comment; review flow; a comment wakes the bot; a failed run blocks and notifies), widget tests (create, drag, sheet, filters).

## D-099 Spaces

- **A space is an organization:** bots, memory, team computer, connections, secrets, billing and members were already per workspace, so no new isolation layer. The UI keeps the word "workspace" (the Open decisions entry stands).
- **Look:** `organizations.icon` (a Lucide key from a short list) and `color` (`#rrggbb`), changed by admins with `PATCH /v1/orgs/{id}`.
- **Invite links:** `invite_links` (role member or admin, token stored hashed with a short hint, optional expiry and use limit, revocation; admins only under RLS). `POST/GET /v1/orgs/{id}/invite-links`, `DELETE …/{link_id}`; the token and the share URL (`<PUBLIC_APP_URL>/join/<token>`) are returned once. `POST /v1/invite-links/{token}/accept` joins through `public.accept_invite_link` (signed in, valid link; joining again is a no-op). Email invites stay.
- **Badges:** `GET /v1/me/badges` gives pending approvals and unread notifications per workspace.
- **App:** a workspace switcher at the top of the sidebar, rail and phone header (other workspaces' badges show as a dot) opens a list to switch, create a workspace (name, icon, color) or join with a pasted link. Settings → Workspace settings edits the name and look and manages invite links (role, expiry, uses, copy, revoke). `/join/<token>` joins and opens the workspace; opened before signing in, the token is kept and joined right after. The selected workspace is remembered on the device.
- **Tests:** pgTAP (`spaces_rls.test.sql`), API (`spaces.test.ts`), widget tests (switcher, create, join, links).

