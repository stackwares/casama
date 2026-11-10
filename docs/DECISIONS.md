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

## D-042 Offline cache (drift) deferred (superseded by D-112)

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

## D-100 Bots that manage bots

- **Tools:** `bots.list` (read only), `bots.create` (high risk), `bots.update` (medium; high when autonomy or budget is set; leave `bot` out to change itself), `bots.archive` (high; never itself) and `sidebar.organize` (folders, low). The routine tools take an optional `bot` to manage another bot's routines.
- **The limit:** a bot can never give any bot, itself included, more autonomy (ask_always < ask_risky < autonomous) or a larger per-run or daily budget than its own. A new bot gets no tools unless `copy_tools` copies the creator's own integrations, so tool access can't grow either. New bots copy the creator's model policy (a model override stays on the same key), belong to the person the run acts for (`actingUserOf`, shared with coding agents) and count against `max_bots`. Each action is in the audit log.
- **History:** `bot_revisions` keeps the settings before every change (name, instructions, model, autonomy, budget, computer, archived) and who made it: a person (JWT `sub`) or a bot (`kasama.actor_bot`, set in the bot tool's transaction). The app's bot settings → Settings history lists changes and restores one (the current settings become a new revision).
- **Folders and archive:** `bot_folders` and `bots.folder_id`/`sort_key` group the sidebar (loose bots first). Archived bots (`archived_at`) leave the sidebar, are excluded from `GET /v1/bots` (`archived=true` lists them) and from `max_bots`, and runs refuse them (`bot_archived`). Bot settings has Folder and Archive; the bot list has Archived bots with Bring back.
- **Worker and auth:** newer Supabase doesn't let the migration role grant on `auth.users`, so the worker uses `public.worker_owner_email_verified` and `public.worker_purge_user` (security definer, worker only) instead of a column grant. The vault grants go by function name (argument lists differ between versions), and non-superuser migration roles get SET on `kasama_worker` (Postgres 16+).
- **Tests:** pgTAP (`bot_management_rls.test.sql`, worker role), API and tools (`bot_management.test.ts`), widget tests (history restore, folder, archive and bring back).

## D-101 Ask for a secret in chat

- **Tool:** `secrets.request(name, service, allowed_hosts, reason)` (low risk: it only asks). Hosts must be valid names under one registrable domain (`api.stripe.com` and `files.stripe.com`, not two services); a bad call returns an error at once, without waiting. Like `computer.request_takeover`, it runs in the run loop: `secret_requests` row, run status `waiting_approval` (waiting on a person; no new run status), event `secret.requested`, push to admins and the run's sender linking to the chat, then a durable wait (24 h, woken by the API signal).
- **Answering:** `POST /v1/secrets/requests/{id}/fulfill` (`{value}`) or `…/decline`, by the run's sender or an admin; `GET /v1/secrets/requests` lists pending ones. The value goes straight into Vault and a `secrets` row limited to the requesting bot and the requested hosts. An existing secret of that name is replaced only by an admin (a member gets 409). The response, events, messages and audit log never hold the value; idempotency stores responses only.
- **Resuming:** the run gets only "Saved NAME for SERVICE. Use it as {{secret:NAME}}", or the decline or expiry answer (`secret.resolved`); its in-memory secret list and redactor are reloaded so the new value is usable and scrubbed from then on.
- **App:** a protected card in the chat (service, hosts, reason, a masked field with no suggestions, autocorrect or IME learning, Save and Decline). The value never touches the composer or drafts and is cleared after sending.
- **Tests:** pgTAP (`secret_requests_rls.test.sql`), API with a scripted model (`secret-requests.test.ts`: wait, fulfill, nothing leaks, decline, mixed hosts refused), widget tests (`secret_request_test.dart`).

## D-102 Sign-in codes for bots

- **Kind:** `secrets.kind` is `value` (default) or `totp`; `secret_requests.kind` likewise, so `secrets.request` can ask for a seed (`kind: "totp"`). A totp secret holds an `otpauth://totp/...` link or a bare base32 key, checked when saved (`invalid_totp`): time-based only, SHA-1/256/512, 6–8 digits, 10–300 s periods.
- **Codes:** bots write `{{totp:NAME}}`. `resolvePlaceholders` turns it into the current RFC 6238 code (`@kasama/domain` `totpCode`, node crypto) only at execution time, only for tools that accept secrets, only on the secret's allowed hosts. `{{secret:NAME}}` on a totp secret is refused (`totp_seed_protected`), so the seed never leaves Vault; `{{totp:...}}` on a plain secret is refused too. Each code is added to the run's redactor so it is scrubbed from output.
- **App:** Secrets → Add has Key or password / Sign-in code; a sign-in code takes a pasted link or key, and phones scan the site's QR code (`mobile_scanner`, iOS and Android only; the name is suggested from the issuer). The chat's secret card does the same for `kind: totp` requests.
- **Generator:** `--enum-name-mappings=value=plain` stops an enum member named `value` from clashing with the generated enum's own `value` field (Dart `SecretKind.plain` is `"value"` on the wire).
- **Tests:** RFC 6238 vectors (`totp.test.ts`), placeholder rules (`totp-placeholders.test.ts`), API (seed validation, totp request in `secret-requests.test.ts`), widget test (sign-in code form).

## D-103 Search

- **Database:** `pg_trgm`; `messages.tsv` (a stored `to_tsvector('simple', …)` of the text parts only, via immutable `public.message_plain_text`) with a GIN index; trigram indexes on chat titles, skill, routine and ticket names. `public.search_workspace(org, q, limit)` is **security invoker**, so RLS decides what each caller sees; results never cross workspaces or bots they can't access. It returns up to 8 per kind (message, chat, memory, skill, routine, ticket) with `ts_headline` snippets (matches between « »). `websearch_to_tsquery('simple')` keeps it language-neutral; `ilike` patterns escape `%`, `_` and `\`.
- **Files:** `GET /v1/search` also searches up to 3 awake computers (`running`/`idle`, not local devices) the caller can see: one shell command for names (`find -iname`, literal pattern) and contents (`grep -rIlis -F`) under `~/workspace`, skipping `node_modules` and `.git`, 4 s each. Sleeping computers are never woken; the app says so. Pages join when they exist (Wave 2); with encryption at rest (Wave 3) search will cover names and titles only.
- **App:** Cmd/Ctrl+K and a search button in the sidebar open the search panel on desktop and web; phones get a Search tab. Results are grouped by type; a message opens its chat scrolled to it and highlighted (`ChatScreen.focusMessageId`, `?m=`), chats open the chat, memories, routines, skills and tickets open their screens, files open the file preview.
- **Tests:** pgTAP (`search_rls.test.sql`), API (`search.test.ts`: grouping, isolation, wildcards, the file command on a real folder including a quoting attack), widget tests (`search_test.dart`).

## D-104 Skills library

- **Format:** the open Agent Skills layout: a folder with `SKILL.md` (front matter with `name` and `description`, then Markdown instructions) plus optional files. `@kasama/domain` parses the small YAML subset skills use (`parseSkillMd`). Skills gain `source` (manual, catalog, github, bot), `source_ref`, `category`, `updated_at` and `updated_by_bot`.
- **Files in Postgres, not object storage:** a skill's extra files go in `skill_files` (bytea; 1 MB a file, 5 MB and 60 files a skill), under the same RLS as skills. They're small, need RLS and backups, and are copied to the computer on load, so a separate object-store path added nothing; snapshots keep using the `ObjectStore`. This departs from the SPEC's "object storage" wording on purpose. `skills.load` writes them to `~/skills/<name>/` (keeping the executable bit) and tells the bot where they are; scripts only ever run on the computer.
- **Catalog:** curated, original skills ship in the repo's `skills/` folder (`catalog.json` maps each to a category): meeting-notes, weekly-report, research-brief, csv-cleanup (with `scripts/clean.py`), code-review, trip-planner. `GET /v1/skills/catalog`; `POST /v1/skills/install` installs to the workspace (admins) or one bot (its managers), enforced by RLS.
- **GitHub import:** `POST /v1/skills/github/preview` resolves the link's branch to a commit and returns SKILL.md and every file (text up to 100 KB) for review; `…/install` fetches exactly that commit. `GET /v1/skills/{id}/update` compares with the latest commit (SKILL.md line diff plus files added, changed and removed); `POST …/update` applies a chosen commit. Private repositories use a workspace secret `GITHUB_TOKEN` allowed for `api.github.com` and not limited to bots (the "GitHub connection" until a GitHub app connection exists). `GITHUB_API_URL` points tests at a fake.
- **Bots:** `skills.create` (saves a bot-scoped skill, source `bot`) and `skills.update` (only the bot's own skills; workspace skills are an admin's call), both medium risk. A new `approvalDetails` hook on tools adds fields to the approval card only: the full SKILL.md for create and a line diff for update.
- **`/` picker:** typing `/` in the composer lists the bot's enabled skills; picked ones show as chips and go with the message (`SendMessageRequest.skills`, stored as `{type: skill}` parts). The run appends their instructions to the message up front.
- **App:** Skills has Skill catalog (search, categories, install to the workspace or a bot), Import from GitHub (link, preview of every file, install), a source label on each skill, and Check for updates with the diff on GitHub skills.
- **Tests:** domain (`skills.test.ts`), API with a fake GitHub (`skills.test.ts`: catalog and RLS, preview, pinned install, update diff, token use, bot tools and approval details, `/` skills reaching the model), widget tests (`skill_library_test.dart`).

## D-105 Setup interview and starter bots

- **Setup state:** `bots.setup_status` (pending for new bots, including ones made by other bots; existing bots were marked done) and `conversations.purpose` (`chat` or `setup`).
- **Interview:** `POST /v1/bots/{id}/setup` (people who manage the bot) opens a "Setup" conversation with a short opening message and starts a run. In a setup conversation the bot's persona gets `SETUP_GUIDE`: ask three to six questions as `ui.show` cards (the work, writing style, tools and accounts, schedule), then call `setup.apply` once. The guide comes from the conversation, so every turn of the interview keeps it.
- **`setup.apply`** (high risk, so the approval card shows the whole proposal): new instructions (saved as the bot, so bot history records it), up to five memories (`preference`), up to five routines (cron in the owner's timezone), and connections to add. Connections are named, not created: accounts need the person's own sign-in, so the bot asks them to connect those in Settings → Integrations (the preview and result say which). It marks setup done.
- **App:** a new bot's empty chat shows Set up NAME (Start setup or Skip for now; skipping sets `skipped`). Bot settings has Run setup again.
- **Starter bots** (persona templates, D-088): inbox triage (with a weekday morning routine), outbound prospector, recruiting screener (scorecard-based, ignores protected traits, people decide), bug triage, expense matcher, and a coordinator that plans work, checks the team with `bots.list`, and hands work out with `tasks.create` or `bots.delegate`.
- **Tests:** API with a scripted model (`setup.test.ts`: permissions, approval contents, applied instructions, memories, routines and timezone, revision by the bot, no guide outside setup), widget test (`setup_test.dart`).

## D-106 Lazy tool loading

- **When:** a run whose available tools exceed `LAZY_TOOLS_THRESHOLD` (worker env, default 30; 0 turns it off) and whose registry has `tools.load`.
- **Core tools** are always sent: `memory.*`, `skills.*`, `tasks.*`, `notify`, `ui.*`, `setup.*`, `secrets.request` and `tools.load`. Every other tool belongs to a group: its first name segment (`browser`, `shell`, `desktop`), or kind plus name for integrations (`mcp.github`). An index, one line per group with its tool count and first eight names, sorted so it's byte-identical for the same tools, is added as the last system block.
- **`tools.load(groups, names)`** runs in the run loop: it adds those definitions for the rest of the run, appended after the core tools in load order, so the system blocks and the core tool list stay a stable cached prefix. The loaded set is rebuilt from step results on replay. A call to an available tool that wasn't loaded still runs (the registry decides), so a model that guesses right isn't punished.
- **Native deferred tools:** models whose registry entry sets `deferredTools` skip `tools.load` and get every tool, with non-core tools marked `deferred` on the `ToolSpec` for the provider adapter. No model sets it yet; the hook is there for providers that load tools on demand themselves.
- **Evals:** reports now carry `tokens_in`/`tokens_out` per task and in total, plus `--label`; `packages/evals/src/compare.ts before.json after.json` prints the input-token saving and success change and fails on a success drop or a saving under `--min-saving` (0.3). Run the same subset with the worker at `LAZY_TOOLS_THRESHOLD=0` and at the default to check the acceptance criterion with real models.
- **Tests:** stable grouping and index, core plus index on the first request, the loaded group appended after an unchanged prefix, under 70% of the full tool payload, all tools when off (`run.test.ts`); `compare.test.ts`.

## D-107 Run tracing

- **One trace per run:** the trace id is the run's uuid as 32 hex digits, stored in `runs.trace_id` when the run is admitted and returned on `Run`. Model step spans (`chat {model}`) and tool spans (`execute_tool {name}`) are children of the run span `invoke_agent {bot}`.
- **Durable runs:** DBOS replays finished steps, so spans are emitted only by steps that actually run (inside `modelStep`, `toolStep` and the terminal update), never on replay. The run span is recorded once when the run ends, with its start time from the run row; its span id is derived from the run id, and children point at that id from the start (a remote parent context). `ForcedIdGenerator` (installed as the SDK's `idGenerator`) gives the run span exactly those ids; every other span gets random ids.
- **Attributes** follow the OpenTelemetry GenAI conventions: `gen_ai.operation.name`, `gen_ai.request.model`/`response.model`, `gen_ai.provider.name`, `gen_ai.usage.input_tokens`/`output_tokens`/`cache_read.input_tokens` (when the provider reports cached tokens), `gen_ai.tool.name`/`tool.call.id`, `gen_ai.agent.id`/`name`, plus `kasama.cost_usd`, `kasama.failover_attempts`, `kasama.tool.risk`, `kasama.tool.outcome` and `error.type`. No prompt, message, argument or result text is ever put on a span (the test checks a run's spans for the user's words).
- **Langfuse** (on when `LANGFUSE_BASE_URL`, `LANGFUSE_PUBLIC_KEY` and `LANGFUSE_SECRET_KEY` are set): every model attempt, including failed ones that fell over, becomes a `generation-create` in the run's trace (same trace id) via the public ingestion API, with input and output passed through the run's redactor (secrets and model keys removed), tokens and cost. Workspaces can turn it off (`llm_tracing` in workspace settings). Sending never blocks or fails a run.
- **Timeline:** run timelines show the trace id with Copy, and Open trace when the server sets `TRACE_URL_TEMPLATE` (any viewer URL with `{trace_id}`), opened in the default browser.
- **Tests:** in-memory exporter (`run.test.ts`): run span id and status, chat spans parented to it with tokens and cost, tool span outcome and risk, no prompt text, `trace_id` stored; Langfuse generations share the trace id, contain no secret, and stop when the workspace opts out; widget tests (`trace_test.dart`).

## D-108 Edit and resend

- **Tree:** `messages.parent_message_id` (the message before it in its branch) and `conversations.head_message_id` (the newest message of the branch on screen). Existing conversations were backfilled as one straight branch. A trigger fills in the parent from the head when an insert doesn't give one (so every existing insert path keeps working), and moves the head only when the new message continues the shown branch (a reply that lands after the person switched branches doesn't pull them back). `kasama.branch_root` starts a new first message.
- **Edit:** `POST /v1/conversations/{id}/messages/{message_id}/edit` (your own messages, not while a run is going) adds a sibling with the same parent, keeping the original's attachments and picked skills, makes it the head and starts a run. The run's history is its own branch: `runAgent` walks from the run's message up through parents, so the old branch never reaches the model. The reply is attached to the run's message explicitly.
- **Switching:** `public.conversation_thread` returns the shown branch with each message's place among its versions (`sibling_index`/`sibling_count`); `POST /v1/conversations/{id}/branch` shows another version by moving the head to the newest message under it (`public.branch_leaf`). Both run as the caller, under RLS.
- **App:** Edit in the message menu (long-press, or the text's context menu with a mouse) opens a sheet with the text; sending reruns from there. Edited messages show `< 2/3 >` arrows.
- **Known limit:** a conversation summary made before an edit (long chats are compacted) may still mention the other branch.
- **Drizzle:** the pull script drops the `conversations_head_message_id_fkey` metadata from the generated schema, which would otherwise make a type cycle; the database keeps the key.
- **Tests:** API with a scripted model (`branches.test.ts`: straight thread, edit forks and reruns, versions and switching back, only user messages), widget tests (`branches_test.dart`).

## D-109 Quiet hours

- **Settings:** `profiles.quiet_hours` (`{enabled, start, end}`, local "HH:MM", may cross midnight) in the person's profile timezone; `user_bot_settings` per person and bot: `default` (my quiet hours), `always` (this bot may always push) or `custom` (its own window). People manage only their own rows (RLS).
- **Delivery:** `NotificationService.notify` always writes the inbox row; during quiet hours it records `push_status = deferred` and `push_after` (the window's end) instead of pushing. The worker's minute tick (`sendDeferred`) sends due pushes and skips ones already read in the app. `@kasama/domain` `quietUntil` does the timezone math (DST shifts inside a window move the end by at most an hour).
- **Urgent:** approvals from a chat or voice run are urgent (someone is waiting in the conversation) and push anyway; approvals from routines, tickets and other background runs wait. Bot phone calls (Wave 3) will use the same check.
- **App:** Settings → Quiet hours (switch, start and end); bot settings → Notifications from this bot (follow my quiet hours, always notify me, its own quiet hours).
- **Tests:** domain (`quiet-hours.test.ts`), service against Postgres (`quiet-hours.test.ts`: deferral, urgent, per-bot always, delayed send skipping read ones), pgTAP (`quiet_hours_rls.test.sql`), widget tests (`quiet_hours_test.dart`).

## D-110 Share a bot as a template

- **Format:** `kasama.bot` version 1 (`docs/BOT-TEMPLATE-FORMAT.md`, `BotTemplateFile` in contracts): name, description, instructions, autonomy, a built-in mascot, the bot's own skills with files (base64), repeating routines, connections by name, and memories only when chosen. Never keys, secrets, OAuth tokens or the model choice. It's the file the community template repository accepts.
- **Export:** `GET /v1/bots/{id}/export` (anyone who can see the bot; `memories=true` only counts for people who manage it).
- **Links:** `POST /v1/bots/{id}/share` (managers) stores a snapshot in `bot_shares` with a hashed token (default 30-day expiry) and returns `<PUBLIC_APP_URL>/import/<token>`; `GET /v1/bot-shares/{token}` returns it to anyone signed in, in any workspace, for the preview. Sharing is audited.
- **Import:** `POST /v1/bots/import` with the template, a model key from the importing workspace and a model; it checks skill file limits and cron schedules, respects `max_bots`, and creates the bot (owned by the importer), its skills and files, routines (optional, in the importer's timezone) and memories (optional). Connections come back as `connections_to_add` for the person to connect themselves.
- **App:** bot settings → Share as template (include memories, Save as file, Copy link); Bots → Import a bot (a file) and `/import/<token>` links open an import screen that previews instructions, skills, routines, connections and memory count, with switches for routines and memories and the key and model (prefilled with the key's default) before importing.
- **Generator notes:** enum and array defaults and numeric literals break the Dart generator, so the template's optional lists are optional (empty when missing) and `version` is a bounded integer.
- **Tests:** API (`bot-template.test.ts`: export without secrets, memories on request, cross-workspace link preview and import with files, bad schedules and foreign keys refused), widget tests (`bot_template_test.dart`).

## D-111 Shortcuts

- **iOS and macOS:** App Intents in each Runner's `AppDelegate.swift` (no extra target or Xcode project edits): `AskBotIntent` (bot, question) and `RunRoutineIntent` (routine), with `BotEntity`/`RoutineEntity` queries and a `KasamaShortcuts` provider, so they show up in Siri, Spotlight and the Shortcuts app ("Ask Kasama", "Run a routine in Kasama"). They need iOS 16 / macOS 13 (`@available`); older systems simply don't offer them.
- **Data:** the app writes its bots and routines (ids and names only) to shared preferences (`flutter.kasama.shortcuts`), which the intents read in-process. Intents open the app (`openAppWhenRun`) and hand a path to Flutter over the `kasama/shortcuts` method channel, queued until Flutter asks for it on start: `/quick-ask?bot=…&text=…` or `/run-routine/<routine>:<bot>`.
- **Android:** app shortcuts through `quick_actions`: Quick ask, Ask <bot> for the first two bots, and Run <routine> for the first routine, refreshed when the bot list changes.
- **Flutter:** `core/shortcuts.dart` keeps the list in sync and routes the paths; Quick ask takes a preselected bot; `/run-routine/<ref>` starts the routine and opens the bot's chat where results arrive.
- **Verified:** `flutter build macos --debug` and `flutter build ios --simulator --debug` compile the intents; tests cover the paths, the list the intents read, and Quick ask with a preselected bot. Siri phrases themselves need a device to try.

## D-112 Offline cache

- **Store:** drift (SQLite) through `drift_flutter`, one hand-made `cache(key, value, updated_at)` table of JSON snapshots, so there's no code generation step: `bots:<org>`, `lastconv:<bot>` and `msgs:<conversation>` (the last 100 messages, text and attachments; bot UIs aren't kept). `main.dart` installs it on mobile and desktop; the web app and tests use no cache (drift on the web needs its wasm worker set up, which can come later).
- **Instant open:** bots come from the cache first and refresh in the background (`BotsNotifier`); a chat shows its saved messages at once and the server's replace them. Offline, the saved bots and messages stay, and the chat says "Offline. Showing saved messages." with Retry. Every cache read and write is best effort: a broken or missing cache just means nothing saved.
- **Privacy:** the cache is cleared when the session ends (sign-out or expiry). It holds what the app already showed; no keys or secrets.
- **Tests:** the drift store with an in-memory database, and a chat opened once then reopened offline (`offline_cache_test.dart`); `flutter build macos` links drift's SQLite.

## D-113 Projects

- **Data:** `projects` (the SPEC's columns plus `slug`, `plan_status` draft/proposed/approved, `status_reason`, `conversation_id` for the project thread, `sessions`), `project_milestones` (ordered, optional owner sign-off, open/awaiting_signoff/done), and `project_id` on tickets, runs, conversations and routines. Tickets also gain `parent_task_id` and `milestone_id` (the SPEC's "milestone", as a row so sign-off can live on it). Members read; changes go through the API and tools.
- **Plan first:** creating a project (API or `projects.create`) starts a planning run in the project thread; the lead bot calls `projects.plan` (milestones with tickets, assignees, sign-off flags, `plan_md`), which proposes the plan and notifies the owner. Until approval, planning again replaces the proposed tickets; after approval `projects.plan` adds work. `POST /v1/projects/{id}/plan/approve` makes it active.
- **Heartbeat:** the worker's minute tick runs `projectHeartbeat` (state lives in the database, so it resumes as is after a restart). For each active, approved project with nothing in flight (no queued or running run carrying its `project_id`): pause at the budget (sum of its runs' cost) or past the deadline, with a note in the thread and a notification; close finished milestones, or mark them awaiting sign-off and wait; otherwise start a session for up to 10 ready tickets of the current milestone (todo, unassigned or the lead's), highest priority first. With every ticket done, one wrap-up session checks the done criteria and marks the project done; if it doesn't, the project goes blocked for the owner.
- **Sessions** are normal runs (`trigger = project`, so step and time limits apply) in the project thread. The message carries the goal, done criteria, plan and ready tickets, and asks the bot to work or hand out tickets, keep statuses current, and end with `projects.update(plan_md)`; `projects.update(status: blocked, question)` pauses and notifies the owner. Ticket runs and subagent or delegation runs inherit the project id, so spend sums per project. `projects.status` reports progress.
- **API and app:** `/v1/projects` (list, create), `/v1/projects/{id}` (detail with milestones and runs; PATCH to pause, resume, cancel, change budget, deadline or plan), plan approval and milestone sign-off; `GET /v1/tasks?project_id=` filters the board. Board → Projects lists them; a project screen shows goal, Approve the plan, Pause/Resume, spend against budget, milestones with Sign off, the plan, tickets and a timeline of every run, and opens the project chat.
- **Drizzle:** the pull script now strips a list of cycle-making foreign keys from the generated schema (`projects_conversation_id_fkey` joins the earlier one).
- **Tests:** API with a scripted model (`projects.test.ts`: planning, nothing before approval, three sessions across two milestones to done with no person, budget stop with a notification, resume), widget tests (`projects_test.dart`).

## D-114 Check-ins

- **Settings:** `bot_checkins` per bot (off by default; brief time, scan every 1–24 hours, default 3; daily cap, default $1), set by people who manage the bot (`PUT /v1/bots/{id}/checkins`). Briefs and suggestions go to the person who turned them on, in their timezone. Turning them on creates two routines (`routines.kind` brief and scan); turning them off disables them.
- **Running:** check-in runs use the bot's cheap model when it has one, and skip once the day's check-in spend reaches the cap (the schedule still moves on). The brief is a normal routine with its own conversation and a routine notification. A scan keeps no conversation: its instructions (plus what's already pending or was dismissed in the last 14 days) travel as the run's task, and its routine never notifies, so a scan that finds nothing writes nothing and sends nothing.
- **Suggestions:** `suggestions.add` stores title, body, proposed action (`{tool, args}`), sources, urgency and expiry (default 3 days) for the person, skipping repeats. Only urgent ones push, and through quiet hours (D-109), not around them. Accepting (`POST /v1/suggestions/{id}/accept`) starts a normal chat asking the bot to do it, so its tools go through the usual approvals; dismissing can pin a "don't suggest this again" memory.
- **For you:** `GET /v1/for-you` returns the latest brief per bot (last 36 hours), pending suggestions (urgent first) and pending approvals. It's the first tab of the Inbox (`/inbox`; `?tab=0` approvals, `?tab=1` notifications as before). Pinned pages join when Pages exist (Wave 2).
- **App:** bot settings → Check-ins (switch, brief time, scan interval, daily limit); Inbox → For you with brief cards and suggestion cards (Do it, Dismiss: just this once or don't suggest it again).
- **Also fixed:** the Android launch background used a bare color as a drawable, which current Android tooling rejects; it's a `<color>` item now, so `flutter build apk` works again.
- **Tests:** API with a scripted model (`checkins.test.ts`: routines created, brief on the cheap model in For you, an urgent suggestion with a notification, a quiet scan changing nothing, accept and dismiss, daily cap), widget tests (`checkins_test.dart`).

## D-115 Action rules

- **Rules:** `action_rules` for a bot or the whole workspace, matching a tool, a tool group (the lazy-tools grouping) or a category (send, pay, delete, publish, share, sign_in), with an optional target (recipient domains, exact recipients, a maximum amount) and a rule: allow, allow within limits, ask, or hand off. Workspace rules need an admin, a bot's rules someone who manages it (RLS). No tool writes rules, so bots, including bots that manage bots, can't change them.
- **Matching** (`@kasama/domain` `action-rules.ts`): categories come from a tool's declared `category`, else from words in its name; targets are read from argument fields (`to`, `cc`, `recipients`, `amount`…). A rule with limits only applies when the call is within them (every recipient in an allowed domain, under the amount). The most specific rule wins (the bot's own over the workspace's, tool over group over category, limited over unlimited); ask or hand off wins ties. No matching rule: autonomy decides as before.
- **In the approval gate:** allow and allow-within-limits skip approval; ask always asks, whatever the autonomy; hand off blocks the call and tells the bot to prepare everything and have the person finish it (`computer.request_takeover` when it's working on its computer). Password and two-step changes are always handed off.
- **"Always allow this tool"** now creates a tool allow rule (`decide_approval`); existing `tool_grants` were copied into rules, and the gate no longer reads `tool_grants`.
- **API and app:** `GET/POST /v1/action-rules`, `DELETE /v1/action-rules/{id}` (audited), each with a plain-language `preview` ("Sends messages to anyone at acme.com without asking"). Bot settings → Action rules lists the bot's and the workspace's rules grouped by category, and adds rules (category, behavior, domains, amount, this bot or the whole workspace).
- **Tests:** domain (`action-rules.test.ts`), runs (`agent action-rules.test.ts`: internal email sends without approval, external waits, password change handed off, no rule-editing tool), API (`action-rules.test.ts`), pgTAP (always-allow rule), widget test (`action_rules_test.dart`).

## D-116 Watchers

- **Data:** `watchers` (bot, kind page_change, reply, query or time; target; condition and what to do on a match in words; check interval, default 15 minutes, minimum 1; expiry; status active, paused, done or expired; last value and its hash; its own conversation).
- **Checks run in the worker's minute tick without a model** (`checkWatchers`, FOR UPDATE SKIP LOCKED): page watchers fetch through the worker's guarded fetch (or read the page in the bot's browser when asked and its computer is awake) and compare the visible text, from an anchor text on when one is given (scripts, styles and tags are dropped, so changing script contents don't count); reply watchers look for the newest comment from a person on a ticket; query watchers rerun a read-only integration tool; time watchers wait for their moment and then finish. The first check only records a baseline. A changed hash (or the time arriving) starts a `trigger = watcher` run in the watcher's conversation with what changed, the condition and what to do; the bot can decide it doesn't count. Unchanged checks spend no model tokens.
- **Reply sources:** tickets now; email and chat replies come with their channels (Wave 3), through the same watcher kind.
- **Tools and app:** `watchers.create` ("tell me when…"; query watchers only for read-only tools of integrations the bot is attached to), `watchers.list`, `watchers.delete`; `GET /v1/watchers?bot_id=`, `PATCH /v1/watchers/{id}` (pause, resume), `DELETE`. Bot settings → Watchers lists them with pause and delete and opens each one's conversation.
- **Tests:** API with a local page and a scripted model (`watchers.test.ts`: baseline, unchanged check with no tokens, a change firing within one interval, time and reply watchers, pause and delete), widget test (`watchers_test.dart`).

## D-117 Hosted MCP endpoint

- **One implementation:** the API serves the `@kasama/mcp` tools (D-077) at `/mcp` over Streamable HTTP (the SDK's web-standard transport, stateless, one server per request). The tools' `KasamaApi` gets a fetch that calls the API in-process, carrying the caller's identity in Hono's environment (`kasamaClaims`), which outside requests can't set; the auth middleware uses it for those calls only. So every tool call goes through the same routes, RLS, approvals, action rules and budgets as the app.
- **Who:** an OAuth access token (`kmcp_…`), a workspace API key (`ksk_…`), or a normal Kasama sign-in. Tokens and keys act as one person in one workspace (other workspaces are invisible to the tools) and stop working if that person leaves it. Tokens are stored hashed in `mcp_tokens`.
- **OAuth** (the MCP authorization flow): `/.well-known/oauth-protected-resource` (also announced in the 401's `WWW-Authenticate`), `/.well-known/oauth-authorization-server`, dynamic client registration at `/oauth/register` (public clients, https or localhost redirects), `/oauth/authorize` (PKCE S256 required) sends the person to the app's consent screen (`/oauth/consent/<id>`) where they pick a workspace and allow or refuse; `/oauth/token` exchanges a single-use code (5 minutes) for a one-hour access token and a rotating 60-day refresh token. Connections are audited.
- **Approvals:** `decide_approval` over MCP is refused unless the workspace turns on `mcp_decide_approvals` (Workspace settings → Connect AI apps); with a full sign-in it behaves like the app. A high-risk step still waits for approval either way.
- **App and docs:** Workspace settings → Connect AI apps shows the `/mcp` address, API keys (create, shown once, revoke; admins) and the approvals switch; `docs/MCP.md` has copy-paste configs (OAuth by URL, Cursor and Claude Code with a key, local stdio). `PUBLIC_API_URL` sets the advertised address (else the request's origin).
- **Tests:** a real MCP client over HTTP (`hosted-mcp.test.ts`: 401 challenge and metadata, registration, PKCE (a wrong verifier fails and spends the code), consent, refresh, one-workspace scope, asking a bot, a high-risk step waiting, approvals refused until allowed, API key revoked), widget tests (`mcp_test.dart`).


## D-118 Group chats

- **Data:** `conversations.kind` (direct, group) and `conversation_bots` (bot, role lead or member, position); `conversations.bot_id` stays the lead, so existing access checks and lists keep working. `messages.bot_id` records which bot wrote each reply; `runs.trigger_message_id` and `runs.hop` tie a run to the message that woke it. A person sees a group chat only if they can see every bot in it (`group_bots_visible` in the conversations policy; messages use `can_access_conversation`).
- **Waking:** `@Name` wakes that bot (longest name first, `@kasama/domain` `parseMentions`); `@everyone` wakes the lead with the member list and asks for a plan that @mentions a bot per part; no mention goes to the last bot that spoke (else the lead). One user message, one run per woken bot, all in the same conversation and running in parallel.
- **Bot to bot:** a bot's reply that @mentions others starts their runs (trigger `mention`) up to 6 hops per user message; after that the chat waits for a person. Group messages are stored flat (no branches, so edit and resend stays direct-chat only).
- **Other bots are chat, not instructions:** each run sees other bots' messages as user-role text prefixed with who said it and that it's not from the owner; a group note in the persona lists the members. Each bot keeps its own memory, approvals and budget.
- **API and app:** `POST /v1/conversations` with `bot_ids` (lead first, up to 10) creates a group; `GET /v1/group-chats?org_id=`; `send` returns every started `run_ids`. The sidebar lists group chats with New group chat (pick 2 to 10 bots, the first leads), `/groups/:id` opens the chat with each reply headed by its bot, and typing `@` suggests the members and everyone.
- **Tests:** domain (`mentions.test.ts`), API with a scripted model (`group-chats.test.ts`: @everyone plan then work, @Name, last speaker, the 6-hop cap, visibility), widget tests (`group_chats_test.dart`).

## D-119 Pages

- **Data:** `pages` (bot, the person it was made for, its conversation, title, HTML up to 2 MB, a JSON data block up to 1 MB, visibility private, workspace or public, public token hash, expiry, refresh routine, version) and `page_versions` (the last 20, trimmed by a trigger). Private pages are visible to the person they were made for and the bot's managers; workspace and public pages to everyone who can see the bot (RLS). Only those people can change, share or delete a page.
- **Tools:** `pages.publish` (HTML or an HTML file on the computer; a `page_id` replaces the layout; `refresh_cron` links a routine that refreshes the data with `pages.update_data`), `pages.update_data` (data only, layout untouched), `pages.share` (high risk for public, medium otherwise; category `share`, so action rules apply), `pages.list`. Bots only touch their own pages. New pages are private.
- **Serving (D-092):** a separate origin (`createPagesApp`, `PAGES_URL`, served by the API process on `PAGES_PORT`; self-host Caddy gives it its own site or port). The served document is the bot's HTML plus a head (charset, viewport, `noindex`, theme variables `--k-bg|fg|muted|accent|surface|font` for light and dark, and the data as `<script type="application/json" id="kasama-data">` with `<`, `>` and `&` escaped) and an "Updated …" line. Headers: CSP `default-src 'none'` with inline scripts and styles, `data:` images and fonts, `connect-src 'none'`, `form-action 'none'`, `frame-ancestors 'none'`, `base-uri 'none'`; `X-Robots-Tag: noindex`, `no-store`, `no-referrer`. A fragment gets a full document around it.
- **Opening without a session:** `POST /v1/pages/{id}/view-link` returns a single-use link (60 s, bound to page and viewer, stored hashed). The pages origin swaps it for a 30-minute cookie scoped to `Path=/p/<id>` (HttpOnly, Secure on https), then rechecks access as the viewer on every load, so removing someone works at once. Public links (`/s/<token>`) are hashed, revocable (making a page public again gives a new link; making it private or workspace kills it) and can expire; making a page public or taking it back is audited.
- **PDF:** `/p/<id>/pdf` and `/s/<token>/pdf` print the same document with headless Chromium's own `--print-to-pdf` (`PDF_CHROMIUM_PATH`; no browser library). Without it PDF export answers 503. It runs where the pages origin runs (the API process), not in the worker as SPEC says: the API already holds the rendered page, and a worker round trip only added latency. The default server image doesn't ship Chromium yet.
- **API and app:** `GET /v1/pages?org_id=&bot_id=`, `GET /v1/pages/{id}` (with versions), `PATCH` (visibility, expiry; returns a new public link), `POST /v1/pages/{id}/revert` (an old version as a new one), `DELETE` (turns its refresh routine off). The app's Pages screen (sidebar, bot settings → Pages, and "Open in Pages" under a chat's `pages.publish` step) lists pages and opens them in Safari View Controller or Chrome Custom Tabs (`LaunchMode.inAppBrowserView`), the default browser on desktop, or a new tab on the web; its menu exports PDF, changes visibility (public asks first, then shows and copies the link) and deletes. No WebView anywhere.
- **Tests:** domain (`pages.test.ts`: script escaping, document assembly, CSP), API (`pages.test.ts`: private visibility, CSP and data escaping, single-use link, page-scoped cookie, versions and revert with the 20-version cap, workspace and public links with expiry and revocation, audit, PDF and PDF off, refresh routine, other bots refused), widget test (`pages_test.dart`).

## D-120 Teach a task by showing it

- **Who sees the input:** live-view input goes peer to peer to the computer over WebRTC, so the server never sees it (D-054). While recording, the app also reports each step to the API (`POST /v1/teach/{id}/steps`), and the server captures what the screen looks like right after it: the accessibility snapshot (`agent-desktop`, else the bot's browser), the browser address and a screenshot (`captureTeachContext`). Missing pieces are skipped, never fatal.
- **Steps:** a click is one step; typing is gathered into one step until a click, a special key or a 1.5 s pause (`TeachRecorder`); scrolling likewise; special keys and shortcuts are their own steps (`Ctrl+c`, `Tab`).
- **The privacy exception:** recording starts only while the recorder holds the control lease, and each step checks it again; losing control stops recording (`control_ended`). One recording per computer. A red "Recording" banner with Stop replaces the usual privacy note for the whole time. Starting is audited. Recordings are visible only to the person who made them, and discarding one deletes every step, snapshot and screenshot.
- **Secrets:** when the focused field in the snapshot is a password field, the typed text is never stored; the step becomes `{{secret:PASSWORD}}` (then `PASSWORD_2`…). "Mark as secret" on the last typed step deletes its text and names it (`{{secret:EMPLOYEE_ID}}`). Marking is only allowed before Stop, because Stop sends the recording to the model.
- **Drafting:** Stop starts a run (trigger `teach`) in a new chat, "Teach: draft a skill", with the recording as text: steps grouped by page address, each with the first 1,500 characters of the snapshot after it, up to 60,000 characters. Screenshots are kept for the person but not sent to the model yet. The bot answers with `teach.save_draft` (name, description, instructions, inputs, success checks), which works only in that run. Instructions, an Inputs section and a Success checks section become the draft skill. A run that ends without a draft marks the recording failed, and the person can still write the skill by hand from the step list.
- **Placeholders in skill text:** tools now declare `keepsPlaceholders` when they store `{{secret:NAME}}` as written instead of filling it in. Before this, `teach.save_draft`, `skills.create` and `skills.update` refused any placeholder.
- **Saving:** the app shows the draft (name, description, instructions, the recorded steps with secrets as names). Save adds it as one of the bot's skills (`source = manual`, `source_ref.teach_session_id`). Save and try also opens a chat asking the bot to use it now.
- **API:** `POST /v1/teach`, `GET|DELETE /v1/teach/{id}`, `POST /v1/teach/{id}/steps`, `POST /v1/teach/{id}/steps/{seq}/secret`, `POST /v1/teach/{id}/stop`, `POST /v1/teach/{id}/save`.
- **Tests:**
  - domain: `teach.test.ts`, covering password detection, secret names and the transcript.
  - API, with a fake computer and a scripted model (`teach.test.ts`): recording only under control, capture after each step, password text never stored, mark as secret, control ending, a transcript without secret values, the draft, save and try, discard.
  - widget (`teach_test.dart`): the recorder, the live-view banner with mark-secret and stop, and the draft screen.

## D-121 Plugins

- **Format:** Agent Plugins 1.0, checked by `@kasama/domain` `checkPlugin`. The checker is written from the published specification, including the rules its JSON Schemas can't express:
  - `$schema` must be 1.0.0.
  - Name pattern; unknown manifest fields are warnings.
  - Skills are the immediate `skills/<name>/SKILL.md` folders.
  - `mcp.json` is checked per server:
    - stdio `command` is one program or a `./` path inside the plugin.
    - `cwd` stays inside the plugin or its data folder.
    - `env` can't set `PLUGIN_ROOT` or `PLUGIN_DATA`.
    - URLs are https except on loopback, with no credentials or fragments.
    - Headers are valid and not duplicated.
  - A bad server or skill is skipped with a warning; a bad `mcp.json` disables only MCP. `${PLUGIN_ROOT}` and `${PLUGIN_DATA}` are expanded once, in args, env values and cwd only.
- **Secrets:** the specification has no way to declare them and forbids secrets in `env` and `headers`. A plugin declares the secrets it needs under Kasama's own extension namespace (`extensions["com.kasama"].secrets`): a name, a description, the server, and the environment variable or header it fills, with an optional `"Bearer {{value}}"` format. Values are stored in Vault, never in the connection's config. Updates keep them unless replaced.
- **From GitHub, pinned:** preview resolves the link's ref to a commit and fetches that folder (up to 400 files and 10 MB). Install must name the previewed commit, so what was reviewed is what gets installed. Plugins are installed per bot.
- **What install creates** (each row points at `plugins.id`, so uninstall cascades):
  - the skills (`source = plugin`, with their files);
  - the package's other files (`plugin_files`);
  - one connection per server: kind `mcp` for remote servers, the new kind `computer_mcp` for stdio servers. Both are attached to the bot.
  - Install, update and uninstall are audited.
- **Stdio servers run in the bot's computer**, so plugin code never runs on Kasama's servers:
  - computerd takes the computer's plugin servers over the new `PUT /mcp-servers`, outside companion mode, and bridges them on the existing `/mcp/<key>` (D-096).
  - The supervisor passes `/computers/:ref/mcp-servers` and `/computers/:ref/mcp/:key` through, and `SandboxHandle` gains `setMcpServers` and `mcpFetch`.
  - Before the first call on a computer, the worker writes the package to `~/.kasama/plugins/<name>/` (`PLUGIN_ROOT`). A `.kasama-commit` marker skips unchanged packages. Data lives in `~/.kasama/plugin-data/<name>/` (`PLUGIN_DATA`), which survives updates.
  - The worker then sends the server list for every bot that uses that computer, with secret env values (`syncPluginComputer`, skipped when nothing changed). It speaks MCP through `mcpFetch` (`ComputerMcpAdapter`).
- **Tools and risk:** risk comes from the server's tool annotations (read-only is low, destructive is high, otherwise medium) and can be overridden like any connection's.
  - Remote servers' tools are listed through the worker at install.
  - Stdio servers' tools are listed at install by starting the bot's computer. They are refreshed on update, not at every run start, so a run doesn't wake the computer just to list tools.
  - **Deviation from SPEC:** the preview before install shows skills, each server's command or URL, network hosts, secrets and warnings, but not tool names. Listing tools means running the plugin's code, which happens only once it's installed. The plugin page then shows every tool with its risk.
- **Updates and uninstall:**
  - "Check for update" fetches the source's latest commit. It shows a diff: skills and servers added, changed and removed; new hosts; new secrets. Update reinstalls at that commit.
  - Uninstall deletes the plugin row (cascading to its skills, files and connections) and its Vault secrets. When the computer is awake, it also stops the servers and removes the files.
- **Not yet:** installing a plugin's stdio servers on the user's own computer through the desktop companion; for now only remote servers and the bot's computer are supported. The default computer image needs this computerd build to run plugin servers.
- **Tests:**
  - domain (`agent-plugins.test.ts`): the manifest rules, per-server checks and secret declarations.
  - computerd: `PUT /mcp-servers` starts and stops a real stdio server.
  - API (`plugins.test.ts`), with a fake GitHub, a fake computer and real MCP servers: preview, pinned install needing its secrets, tools listed for both kinds, the package and env on the computer with no secret in the config, a call through `computerMcpFor`, an update diff carrying secrets over, and an uninstall that removes everything.
  - widget (`plugins_test.dart`).

## D-122 Import an agent

- **Importers built from public docs only** (`@kasama/domain` `planAgentImport`), not from either project's code:
  - **OpenClaw:**
    - The workspace's `SOUL.md` and `AGENTS.md` become the persona; `IDENTITY.md` gives the name and joins the persona.
    - `USER.md` items become preferences, `MEMORY.md` items become facts, and the newest 60 `memory/YYYY-MM-DD.md` daily notes become episodes.
    - Skills come from `skills/<name>/SKILL.md`.
    - Scheduled jobs come from `cron/jobs.json` (`schedule` of kind `cron`, or `every` when it divides an hour or a day; `payload.message` or `text`). Newer OpenClaw versions keep jobs in a database, which isn't read.
  - **Hermes Agent:**
    - `SOUL.md` (plus `AGENTS.md` or `.hermes.md`) becomes the persona.
    - `memories/MEMORY.md` entries become facts and `memories/USER.md` entries become preferences; entries are split on `§`.
    - Skills come from `skills/<category>/<name>/SKILL.md`.
    - Jobs come from `cron/jobs.json` (`prompt`, with `schedule.expr` or the readable `display`: "every 2h", "daily at 7am").
  - The folder is found anywhere in the upload; a ZIP of `.openclaw/` or of `workspace/` both work.
- **What's left out, and said so:**
  - **Never read:** keys and settings (`.env`, `auth.json`, `credentials/`, `openclaw.json`, `config.yaml`), databases, sessions, logs and run history. These are listed as skipped.
  - **Not imported as routines, each with a note:** paused jobs, one-off jobs, finished jobs and unreadable schedules. A job's own time zone becomes the person's.
  - **Fixed up:** skill names that aren't valid are fixed (`Weekly Report` becomes `weekly-report`).
  - **Limits:** the template caps (30 skills, 20 routines, 200 memories, 20,000-character persona) apply, with a note when something was trimmed.
  - **Everything else** (for example `HEARTBEAT.md`, `canvas/`, notes) is kept for a day.
- **Review, then the existing template import:**
  - `POST /v1/agent-imports` takes a ZIP (unzipped with fflate; paths with `..` or absolute paths dropped; 50 MB and 3,000 files at most) or the files of a folder the desktop app picked. It returns a `kasama.bot` template (D-110) plus where each item came from, the leftovers, the skipped files and the notes.
  - The app lists every skill, routine and memory with a checkbox, plus the name and persona. Importing sends the ticked items to the existing `POST /v1/bots/import`, so there's one way to create a bot from outside.
  - `POST /v1/agent-imports/{id}/files` then copies the leftovers to `~/imported/<openclaw|hermes>/` on the new bot's computer, or answers 409 when it has none yet.
- **ChatGPT or Claude memory:**
  - `GET /v1/memory-import/prompt` gives a prompt asking for `FACT:` and `PREFERENCE:` lines.
  - `POST /v1/memory-import/parse` reads the pasted answer (labels optional, bullets and bold tolerated, duplicates dropped).
  - `POST /v1/bots/{id}/memories/import` saves the ticked ones (bot managers only). The bot's Memory screen has the import button.
- **Tests:**
  - domain (`agent-import.test.ts`): an OpenClaw home folder and a Hermes home folder end to end, schedules, splitting notes, and memory answers.
  - API (`agent-import.test.ts`): ZIP to template to bot through the template import, leftovers copied to `~/imported/`, unknown folders, unsafe paths, and memory paste-in.
  - widget (`agent_import_test.dart`): review with unticking, files copied, and the memory sheet.

## D-123 Wave 2 scope cut: no public bots, browser extension or meeting bots

- **What (Oliver, 41a7646):** public bots, "your own browser" (the browser extension) and meeting bots are removed from the roadmap. That covers SPEC's table, design sections, build plan and risks. Wave 2 is now 11 items.
- **Effect:** none of the three were started, so no code changes. Wave 2 continues in SPEC order with routines and skills as files (D-124), knowledge sources, self-improving skills, step replay, password managers and bot sharing.

## D-124 Routines and skills as files

- **Layout** (`@kasama/domain` `workspace-files.ts`): `kasama.json` maps folders to bots. Each bot's routines are `<bot>/routines/<name>.md`; front matter holds `id`, `name`, `schedule` (cron), `timezone`, `trigger`, `enabled` and `notify`, and the instructions follow. Skills are normal `SKILL.md` folders plus `id` and `enabled`: `<bot>/skills/<name>/` for one bot, `workspace/skills/<name>/` for the whole workspace. Plugin skills and check-in routines are managed elsewhere and left out.
- **Import rules** (`applyWorkspaceFiles`, shared by the API and the worker):
  - Matching:
    - Folders match bots through `kasama.json` (by id), else by name.
    - Routines match by `id`, else bot and name; skills match by bot and name.
  - Changes:
    - Changed files update; new files create.
    - Import never deletes; git sync deletes only what was removed in the repo.
    - Changing a schedule recomputes the next run.
  - Checks:
    - Every file is checked (cron, time zone, names, folder matching the skill name). Bad files are reported and skipped; the rest still apply.
    - Webhook and GitHub triggers can't be created from a file, because they need secrets; set them up in the app.
  - Dry run shows created, updated and unchanged items, and errors, without writing.
- **App, API and CLI:**
  - Workspace settings → Routines and skills as files (admins): export as a ZIP, import a ZIP after a dry-run preview, and git sync.
  - API: `POST /v1/orgs/{id}/files/export|import`.
  - CLI: `kasama files export <folder>` and `kasama files import <folder> [--dry-run]`.
  - Admins only, since the files cover every bot.
- **Git sync** (`syncWorkspaceRepo`):
  - **Setup:** `org_git_sync` holds repo, branch and folder. It uses the workspace's `GITHUB_TOKEN` secret, allowed for api.github.com. This is the GitHub connection for now; secrets already have host allowlists.
  - **Algorithm:** each sync compares three versions of every file: the last synced baseline (git blob sha plus content hash), Kasama's export now, and the branch now.
    - Changed only in Kasama: one commit on the branch through the git data API.
    - Changed only in the repo: checked and applied. Bad files are reported in `last_error` and kept out of the baseline, so they're retried once fixed.
    - Changed on both sides: Kasama keeps its version and opens a pull request carrying it on a `kasama/sync-…` branch. The baseline records the standoff, so no second pull request opens; merging it makes both sides agree.
  - **When it runs:**
    - Triggers on routines, skills and skill files mark the workspace dirty, and the worker's minute tick syncs dirty workspaces and checks the rest every 10 minutes.
    - The repo's push webhook (`/hooks/git-sync/<org>`) marks it due. Its HMAC (`X-Hub-Signature-256`) is checked with a secret stored in Vault, shown once at setup.
    - Changing the repo, branch or folder resets the baseline.
- **Tests:**
  - domain (`workspace-files.test.ts`)
  - API (`workspace-files.test.ts`), with an in-memory GitHub: export, a dry run then an import with bad files reported, the first push, the webhook signature, a repo edit applied, an app edit pushed, a conflict keeping Kasama's version with one pull request, a repo deletion, and a bad repo file left alone
  - widget (`workspace_files_test.dart`)
  - the CLI suite

## D-125 Knowledge sources

- **Data:** `knowledge_sources` belong to a bot, or to the whole workspace when `bot_id` is null. Their kinds are upload, website, github and connection; each has a status, a document count, a passage count and a next sync time. `knowledge_uploads` keeps uploaded files so they can be read again. `knowledge_chunks` holds the document reference and title, a location (a heading, "page 3" or "rows 2–21"), a link, the text, an embedding and a full-text vector. Visibility follows the bot, or workspace membership for shared sources. Changes need the bot's managers, or an admin for shared sources.
- **Parsing without extra libraries** (`knowledge-parse.ts`):
  - Markdown and text are split by heading. HTML is split by heading, with the head, scripts, styles, navigation and footer dropped.
  - CSV is read in groups of 20 rows, each value labelled with its header.
  - DOCX is read from `word/document.xml`, with heading styles kept.
  - **PDF limits:** PDFs are read from their Flate-compressed or plain content streams (`Tj` and `TJ` text, page by page). Scanned PDFs and PDFs with custom font encodings yield little or no text, and that file shows the error.
  - Passages are about 1,500 characters, split on paragraph and sentence ends.
- **Reading sources** (the worker's minute tick, `knowledgeTick`, five sources at a time; new and resynced sources are read within a minute):
  - Uploads are read once.
  - Websites are crawled within the start address's origin, up to 50 pages by default (at most 200). The crawler follows `robots.txt` (the group for "kasama", else `*`; the longest matching rule wins), sends a `KasamaBot` user agent and uses the worker's guarded fetch.
  - GitHub sources read a repository's Markdown, text, HTML and CSV files (up to 300), using the workspace's `GITHUB_TOKEN` when there is one.
  - Connection sources call the given tools of an app connection (for example a Notion or Drive fetch) and index what they return.
  - Websites, repositories and connections refresh daily. A failure retries in 6 hours, and an unreadable file is reported without stopping the rest.
- **Search:** `knowledge.search` runs `search_knowledge`, the same rank-fused hybrid as memory (vector, phrase, any word), over the bot's sources and the workspace's shared ones. It returns `[n] Title (location) link` with the snippet and asks the bot to cite them. The tool step's preview names the sources (`Sources: Returns, Shipping`), which is how the chat shows them for now. Without an embedding key, search is full-text only (D-017).
- **App:** bot settings → Knowledge. It lists sources with their status and counts, and has resync and delete. Adding takes files, a website or a GitHub link, and admins can share a source with the whole workspace.
- **Not yet:**
  - Connection sources are API-only (`POST /v1/knowledge-sources` with `kind: connection`).
  - Change notices from connected apps aren't used; the daily refresh covers changes.
- **Tests:**
  - parsers, chunking and `robots.txt` (`knowledge-parse.test.ts`)
  - API (`knowledge.test.ts`): uploads with an unsupported file reported, cited search, a website crawl that skips a disallowed page, a GitHub source shared with the workspace, full-text-only search, and permissions with resync and delete
  - widget (`knowledge_test.dart`)

## D-126 Self-improving skills

- **Run digests:** each chat run leaves a digest when it finishes (group chats excepted). It holds the request, the tools used (memory, knowledge, skills and suggestions bookkeeping left out), the skills loaded, how it ended, whether the person later corrected it, and an embedding of the request (`run_digests`).
- **New skills:** a successful run that used at least two tools and no skill, and matches at least two earlier successful runs, makes the bot propose a skill. A match means cosine distance under 0.3, or 60% shared words without an embedding key. The cheap model writes the name, description, steps and tools from up to four examples (requests, tools, answers). A proposal is made only once per group of runs, and names never clash.
- **Edits:**
  - A run that loaded a skill and failed leads to an edit proposal, with the error.
  - So does a correction in the next message of the same chat ("no…", "actually…", "that's wrong", "it should…"); the earlier run is marked corrected.
  - The model rewrites the skill and says what changed. The app shows the change as a line diff.
  - Plugin skills are never edited this way.
- **Approval:** proposals wait for the owner, who gets a notification and sees cards in Inbox → For you (save or apply, or dismiss). The API accepts an edited version. An action rule allowing `skills.create` or `skills.update` for the bot applies proposals at once.
- **History and stats:** a trigger copies a skill's old text into `skill_revisions` on every change, whether by a person or a bot. `GET /v1/skills/{id}/stats` reports uses, successes, failures, corrections, success rate and last failure from the digests, plus the earlier versions; the bot's Skills screen shows them.
- **Not yet:**
  - Proposals appear in the For you inbox and as a notification, not as a card inside the chat. A chat card needs a new run event type and app support.
  - Digests start now, so existing history doesn't count.
- **Tests:**
  - API (`skill-learning.test.ts`): three similar runs leading to one proposal; one-tool and unrelated runs ignored; no repeat proposal; members can't accept; accept with a change; a correction leading to an edit with a diff; stats and history; a failure leading to an edit auto-applied under an action rule.
  - widget (`skill_proposals_test.dart`): the diff, the For you cards and the stats sheet.

## D-127 Step replay

- **What a replay is:** `replays` belong to a bot. Each holds parameters (name, description, default, secret) and steps. A step is a browser or desktop action (`browser.open|click|fill|type|press|scroll`, `desktop.launch|click|type|press`) with:
  - arguments, where values that change are `{{param:name}}` and passwords are `{{secret:NAME}}`;
  - an element target (role and label) instead of a ref;
  - checks: the address contains…, or the screen shows…;
  - the host its secrets may go to.
- **Running without the model:** `executeReplay` fills the parameters and, for a step with a target, takes a fresh snapshot (`agent-browser` or `agent-desktop`) and finds the element by label and role. Matching by label keeps replays working when refs change between page loads. It then resolves secrets only for allowed hosts (the tool's own destination, else the step's host), calls the registered tool directly, and runs the checks.
- **When a step fails:** a missing element, a failed check or a tool error stops the replay there and returns where and why, plus what was done.
  - `replay.run` (a medium-risk tool) gives that to the bot in a normal run, and it carries on from that step.
  - A replay run (`trigger = replay`, `runs.replay`) starts with the replay before any model call, and passes the approval gate as usual. It finishes without the model if all steps pass; otherwise the stop report joins the person's message and the model takes over, offering to update the replay with `replay.save`.
  - Run, failure and last-failure counts are kept.
- **Saving:**
  - **From a run:** `replay.save` is the bot writing the steps it just did, with targets, checks and parameters. It refuses undeclared parameters and clear text typed into password-like fields.
  - **From a teach recording:** `POST /v1/teach/{id}/replay` turns clicks into `desktop.click` at the recorded position, typing into `desktop.type` (secrets stay placeholders; other text becomes a parameter with the typed value as its default), and keys into `desktop.press`. Each recorded address becomes a check and a secret host.
  - **Limit:** desktop clicks from recordings are positions, not elements, so they're the first thing to need the bot's help when a screen changes.
- **API and app:**
  - `GET /v1/replays?bot_id=`, `POST /v1/replays/{id}/run` (parameters; missing ones are refused) and `DELETE`.
  - Bot settings → Replays: list with step counts and history, run with a parameter form that opens the run's chat, delete.
  - The teach draft screen has "Also save as a replay".
  - **Pending:** password-manager items in replays come with D-128.
- **Tests:**
  - unit (`replays.test.ts`): parameters, finding refs, refusing clear-text passwords, teach to steps, running steps with refs and checks, stopping at a failed check or a missing element.
  - API (`replays.test.ts`): saving from a teach recording (private to its recorder), a replay run handing over to the model, delete permissions.
  - widget (`replays_test.dart`).

## D-128 Password managers

- **Providers (both mocked in tests; no real accounts):**
  - **1Password:** through a 1Password Connect server's REST API (vaults, items, and item fields: username, password, OTP), using a service account's Connect token.
  - **Bitwarden:** through its Vault Management API (`bw serve`: organization collections and their login items).
- **Not yet: Bitwarden Secrets Manager.** It holds key-value secrets rather than logins, which the existing named secrets already cover.
- **Scope:** `password_managers` belong to the whole workspace (admins connect them) or to one person (only runs acting for that person, D-091, can use them). The token is checked by listing vaults before saving, kept in Vault and never returned. Nothing is usable until someone chooses vaults or collections. An optional bot list narrows it further. Connecting and changing vaults are audited.
- **The model never sees a password:**
  - `logins.list` shows `[login:Name]` with the item's sites and whether it has one-time codes.
  - The bot writes `{{login:Name:username}}`, `{{login:Name:password}}` or `{{login:Name:otp}}` into `browser.fill` (or any tool that accepts secrets).
  - The executor fills these only when the destination host is one of the item's own URLs or a subdomain of one. Otherwise it refuses and names the item's sites.
  - Filled values are added to the run's redactor, so they never appear in output.
  - `otp` is the item's current code, computed from its seed through the sign-in codes flow (D-102), or taken as is when the provider already returns a code.
  - Replays fill login placeholders the same way.
- **App:** workspace settings → Password managers. It shows the workspace's managers and your own, and lets you connect one (1Password or Bitwarden, an address and a token; admins can share it with the workspace), choose vaults (with login counts) and remove one.
- **Tests:**
  - API (`password-managers.test.ts`), against fake Connect and `bw serve` servers: token check, admin-only workspace managers, no access before vaults are chosen, `[login:Name]` without values, filling only on the item's host with redaction and a one-time code, a personal Bitwarden usable only in runs acting for its owner and invisible to others.
  - widget (`password_managers_test.dart`).

## D-129 Welcome chat

- **First run:** a signed-in person with no workspace now lands on `/welcome`, not the wizard. Joining by invite still skips this.
  - `POST /v1/welcome` creates "<First name>'s space" through `create_organization`.
  - It also creates a private personal bot named Kasama with the winky mascot, and a `welcome` conversation with the scripted opening.
  - Calling it again returns the same chat; people who already belong to a workspace get 409.
  - The wizard stays at `/onboarding`, reached by "Set up manually".
- **Scripted, no model:** the opening, the two questions and the intro are ordinary bot messages with A2UI cards.
  - **Questions:** "What should I help with first?" (up to three picks, plus free text for something else), then "Just me, my team or my business?". Both can be skipped.
  - **How answers come back:** card actions named `welcome.*` are answered by the server (`handleWelcomeAction`). Each answer is stored as a completed run (`trigger = welcome`) with `message.completed` and `run.completed` events, so the app shows it the way it shows any reply.
  - **What the picks change:** they become pinned memories and a "What they want help with" section in the bot's instructions, and they choose the starter bots the intro suggests.
  - The state lives in `conversations.welcome`.
- **Intro and connection:**
  - The intro is written for the picks. It has one main connection card: GitHub for coding, Notion, Linear or Jira for projects, HubSpot and Calendar for sales, Google Calendar and Gmail for email and calendar.
  - The card also has "More apps" and "Done, next".
  - **No model yet:** with no usable key, a model card comes first, offering Continue with ChatGPT, Add a model key or Use a local model. The bot takes the workspace's first key with a default model as soon as there is one (`ensureBotModel`).
  - "My team" and "My business" add an invite card.
  - **App-side actions:** card actions named `app:connect`, `app:route` and `app:invite` are handled by the app. They open the connect sheet, a screen, or copy a new invite link, and never reach the server.
- **First value:**
  - **With Calendar or Gmail connected:** a consent card offers a catch-up of the next 14 days of calendar (plus the last 14 days of email only with inbox access). Accepting starts a model run under `WELCOME_GUIDE`: "Here's what I noticed" with 3–5 items, up to three one-tap task cards and a morning brief offer, with nothing sent or changed.
  - **Otherwise:** the first task card for the first pick (for example "Point me at a repo") starts a normal run.
- **Then the interview:** after that run, the run loop's `welcome` step offers the setup interview (D-105).
  - "Let's do it" switches the chat to `setup` and runs the interview.
  - Once `setup.apply` has finished, a "What I learned" card lists the memories saved during the welcome chat (up to 10), all ticked. Unticked ones are deleted, and an "Edit in Memory" button opens the memory screen.
  - The chat is then an ordinary chat.
- **Differences from SPEC:**
  - The scripted wording lives on the server in English, not in ARB strings, because v1 is English-only and the messages are stored.
  - Microsoft isn't in the app catalog yet, so email and calendar offer Google.
  - "Something else" gets the first task card rather than a model-chosen connection.
  - Kasama Cloud has no built-in starter model yet, so the model card shows whenever there's no key.
- **Tests:**
  - API (`welcome.test.ts`): space, bot and opening; the same chat on repeat; scripted answers with no model runs; the model, connection and invite cards; memories from the picks; key pickup and a first task run; the setup offer; the interview and "What I learned" with an unticked memory deleted; invited people refused.
  - widget (`welcome_test.dart`): landing in the chat, "Set up manually", app-side card actions.
  - The onboarding test now goes through "Set up manually".

## D-130 Google permissions

- **Kasama's own Google app asks for no restricted scopes:**
  - Sign-in uses `openid`, `email` and `profile` (the Supabase defaults).
  - Gmail asks only for `gmail.send`, Calendar for `calendar.events`, and Drive for `drive.file` instead of `drive.readonly`.
  - Google sign-ins add `include_granted_scopes=true`, so adding a scope later keeps the ones already granted.
- **Inbox reading is a separate "Gmail inbox" connection** (`gmail.modify`, catalog flag `inbox`), turned on only for inbox features.
  - **On Kasama Cloud** (billing on), it is offered only as Composio's managed Google sign-in (`auth: managed`), and hidden when `COMPOSIO_API_KEY` isn't set.
  - **Managed connections:** they use one Kasama-owned Composio integration per workspace (`config.managed`, Composio user = the workspace) and open Composio's sign-in page.
  - **Self-hosted servers** keep their own Google client for it.
  - The connect sheet shows "Sign in through Composio" with a short explanation. The catch-up only reads email when the inbox is connected.
- **Tests:** `google-permissions.test.ts` checks the scope list, the Cloud catalog with and without a Composio key, and a managed connect against a fake Composio. The existing apps tests still pass.

## D-131 Bot sharing

- **Access list:** `bot_access` grants a bot to one person or one role, with `chat`, `edit` or `admin` access. A role grant covers people with that role or higher.
  - The workspace default stays: a `team` bot is chat-for-everyone.
  - A `private` bot is visible only to its creator and the people or roles listed. The bots select policy and `can_access_bot` both count grants (`bot_grant`, which reads only `bot_access` and memberships, so policies never loop).
  - `can_manage_bot` now also allows `edit` and `admin` grants.
  - The new `can_admin_bot` decides who may change sharing: the creator, workspace admins, or an `admin` grant.
- **API and app:**
  - `GET` and `PUT /v1/bots/{id}/access` show and replace the visibility and list. Only workspace members can be listed, and every change is audited. Responses include the caller's own access.
  - `GET /v1/orgs/{id}/members` feeds the picker.
  - Bot settings → Sharing: a private switch, people with their access, add members, save.
- **A bot acting for someone uses only what that person can use:**
  - Local MCP servers on a person's own computer are offered only in runs acting for that person (D-091's acting user).
  - A bot whose computer is someone's personal computer refuses computer tools in other people's runs ("only they can use it from their own chats").
  - Personal password managers already worked this way (D-128). Knowledge sources belong to the bot or the workspace, so everyone with the bot shares them.
- **Tests:**
  - API (`bot-sharing.test.ts`): a private bot is invisible until a person is listed; chat, edit and admin access, checked with `can_manage_bot` as the user; only admins change sharing; outsiders refused; role grants; back to team.
  - widget (`sharing_test.dart`).

## D-132 Calendar triggers

- **The trigger:** a routine with `trigger = calendar_event` holds its connected calendar (an integration), an offset in minutes from the event's start (−15 means 15 minutes before) and optional filters: a calendar, outside guests only, a title match, a video link only.
  - It's created through the routines API (`calendar`), and in the app under "Meetings", with offset chips (30, 15 or 5 before, at the start, 15 after) and the filters.
- **Reading calendars without new provider code:**
  - Every 5 minutes per routine (in the minute tick), the worker calls the calendar connection's own list-events tool. It finds the tool by name and names the time-range arguments the way its input schema does: `timeMin`/`timeMax`, `startDateTime`/`endDateTime`, and so on.
  - It reads the next 36 hours from the reply, parsing Google (`items`, `hangoutLink`, `conferenceData`, `attendees[].self`), Microsoft Graph (`value`, `subject`, `emailAddress`, `onlineMeeting`, `body`) and plain shapes. Cancelled events are skipped.
  - **Not yet:** provider change notifications; the 5-minute check covers it for now.
- **Filters:** "outside guests" means an attendee whose email domain differs from the person's own. The person's domain comes from the event's `self` attendee, else the routine creator's email domain, read by the worker through `public.worker_user_email_domain` (the worker never reads `auth.*` itself, D-095). A "video link" is a Meet, Zoom, Teams, Webex or Whereby link anywhere in the event.
- **One run per event:** each match becomes a row in `calendar_fires` (routine plus event; a moved event moves its unfired time). The minute tick claims due fires (`FOR UPDATE SKIP LOCKED`) and starts the routine's run with the event as untrusted calendar context: title, times, attendees, link, location and description. Runs start within a minute of their time.
- **Tests:**
  - unit (`calendar-triggers.test.ts`): Google and Microsoft shapes, the filters, argument naming.
  - API (`calendar-triggers.test.ts`), with a real MCP calendar server: create the routine; one read per 5 minutes; only the meeting with an outside guest; not due 16 minutes before; one run at 15 minutes before, with the event in context; not twice.
  - widget (`calendar_trigger_test.dart`).

## D-133 Bot-to-bot switch

- **The setting:** `organizations.allow_bot_to_bot`, on by default. Owners and admins change it in workspace settings ("Bots can talk to each other", `PATCH /v1/orgs/{id}/settings`), and changes are audited.
- **When it's off:**
  - **Group chat @mentions:** a bot's @mention of other bots in a group chat starts no runs. The sending run records a new `notice` run event (`code: bot_to_bot_off`, "@Writer, @Designer weren't told: bots can't message each other in this workspace."). The app shows it in the chat as an info line.
  - **Delegation:** `bots.delegate` to a peer bot fails with `bot_to_bot_off`, which appears on the timeline as a failed step.
  - **Still allowed:** `subagent.spawn` keeps working, as do people mentioning bots.
- **`notice`** is a general run event `{code, message}` for things the person should know. Older apps ignore it, since unknown events are skipped.
- **Tests:**
  - API (`group-chats.test.ts`): with the switch off, @everyone gets only the lead's plan, and the notice names the bots that weren't told.
  - widget (`bot_to_bot_test.dart`).

## D-134 Chat apps

- **Which apps:**
  - Telegram (Bot API)
  - Email (Resend inbound and sending)
  - SMS (Twilio)
  - Slack (Events API and Web API)
  - WhatsApp (Cloud API)
  - Messenger (Graph API)
  - Feishu (open platform events v2)
  - iMessage (through the desktop app on the person's own Mac)
- **Where things live:**
  - Connections are `channels` rows on a bot. Settings that aren't secret (addresses, numbers, ids, an optional `api_base`) go in `config`.
  - Secrets go to Vault as one JSON value and are never returned.
  - Each adapter (`packages/agent/src/channels/adapters.ts`) does four jobs: answers the provider's setup handshake, checks its signature, turns its payload into standard messages, and sends replies.
- **How each app proves a request is real:**
  - Telegram: the secret token header. Kasama generates the token and calls `setWebhook` on connect.
  - Email: a Svix-style `whsec_` signature with a 5-minute window.
  - SMS: Twilio's signature over the public URL and sorted parameters.
  - Slack: the v0 signature with a 5-minute window, plus `url_verification`.
  - WhatsApp and Messenger: `X-Hub-Signature-256`, plus the `hub.challenge` GET with a generated verify token, shown once.
  - Feishu: the lark SHA-256 signature, plus `url_verification` checked against its token.
- **The webhook:**
  - Providers post to `/hooks/channels/{id}`. Behind a proxy, signatures are checked against `PUBLIC_API_URL`.
  - A failed signature gets a 401 and nothing else happens.
  - SMS gets an empty TwiML answer; the reply goes out later through the API.
- **The sender gate:**
  - A bot only answers people on the channel's allowed list: email addresses (or `*@domain`), phone numbers or user ids.
  - Messages from anyone else are logged as `ignored` in `channel_events` and get no reply. The app shows them in the chat app's activity list.
- **One conversation per thread:**
  - What counts as a thread: a Telegram chat, an email sender plus base subject (Re:/Fwd: stripped), an SMS or WhatsApp number, a Slack thread, a Messenger sender, a Feishu chat, an iMessage handle.
  - `channel_threads` maps each thread to its conversation and stores how to reply.
  - Each message lands as a user message, prefixed "(App, from Name)" and carrying a `channel` part, and starts a run with trigger `channel`.
  - When the run completes, a new `channel-reply` step in the run loop sends its final text back to the thread.
  - Send failures are logged and saved on the channel as `last_error`.
- **Routines on messages:**
  - A routine with trigger `message` has optional filters: chat app, app kind, sender (`*@domain` works), subject contains, message contains. At least one is required.
  - A matching message starts the routine (`startRoutineForMessage`), with the message as untrusted context, whoever sent it. So a routine can file a vendor's invoice even though the vendor can't chat with the bot.
  - A routed message isn't also answered.
  - In the app it's the routine sheet's "Messages" option.
- **Sending first:**
  - `channel.send` (high risk, send category) starts a new message through one of the bot's chat apps.
  - It works only to people on that app's allowed list, so approvals and the list both apply.
- **iMessage:**
  - There's no bot API, so the person's own Mac does the work.
  - **Setup:** the desktop app's "Use this computer for bots" gains a Mac-only **Messages** permission.
  - **Reading:** computerd answers `GET /imessage/new?since=` by reading `~/Library/Messages/chat.db` read-only through `sqlite3`. This needs Full Disk Access.
  - **Sending:** `POST /imessage/send` uses AppleScript. Both endpoints exist only in companion mode with the permission on.
  - **Polling:** the worker checks every minute through the device tunnel.
    - The first poll only takes a baseline, so old messages are never answered.
    - The tunnel lets these two paths through without a run, but only when an enabled iMessage chat app is tied to that Mac and its bot is one the owner allowed there.
  - **Connecting:** only the Mac's owner can connect it.
- **Not yet:** attachments and images (text only), Slack and Feishu OAuth app installs (paste a bot token), group chats on WhatsApp and iMessage.
- **Tests:**
  - unit (`channels.test.ts` in the agent package): every adapter's signature check (good and bad), payload parsing and send request; allowlists; routine filters.
  - API (`channels.test.ts`), with a fake provider: Telegram `setWebhook` with the stored secret; bad signature refused; two messages in one conversation; a stranger ignored and logged; the reply sent back to the chat; turning a chat app off; disconnecting removes its Vault secret. Email: a vendor invoice starts a message routine, a vendor's other email is ignored, and a colleague gets an answer. Meta handshake, missing credentials, members refused.
  - pgTAP (`channels_rls.test.sql`), computerd (iMessage baseline, own messages skipped, sending, the permission), widget (`channels_test.dart`: connect WhatsApp, webhook address and verify token, senders, activity, disconnect; a message routine).

## D-135 Phone-call voice

- **The tool:** `voice.call_user(reason)` (medium risk, send category) rings the person a run acts for.
  - **Quiet hours:** if the person's quiet hours are on (D-109), nothing rings; they get a notification with the reason when the window ends, and the tool says so.
  - **One at a time:** only one call rings per person.
  - **What's saved:** each call is a `voice_calls` row holding the run's conversation and the reason. It rings for 45 seconds.
- **How each device rings:**
  - **iOS:** a PushKit VoIP push through APNs. It goes over HTTP/2 with an ES256 token key (`APNS_KEY_P8`, `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_VOIP_TOPIC`), with push type `voip`, priority 10, and an expiry at the end of the ring.
    - The app registers its PushKit token in `voip_tokens`.
    - `AppDelegate.swift` reports every VoIP push to CallKit straight away, as Apple requires, through flutter_callkit_incoming.
    - Tokens APNs reports gone (410 or 400) are removed.
  - **Android:** a data-only FCM message with `android.priority = HIGH` and a 45-second TTL (`PushSender.sendCall`). A background handler shows the plugin's full-screen calling screen, even when the app is closed.
  - **Desktop and web:** a `call` notification row reaches the app over the usual Realtime topic. The app shows a ringing banner (Answer, Decline) over every screen until the call is answered or expires. `call` rows don't appear in the inbox.
- **Answering:**
  - `POST /v1/calls/{id}/answer` marks the call answered. It returns 409 if the call already ended.
  - The app then opens the live call (D-065) with the call's id.
  - `POST /v1/voice/session` with `call_id` uses the call's conversation and adds "you called because …; speak first" to the session's instructions. It returns `speak_first: true`, and the app sends `response.create` as soon as the data channel opens, so the bot talks first.
- **Declined and missed calls:**
  - **Declined:** `POST /v1/calls/{id}/decline` turns into an ordinary push with the reason ("Max wanted to talk"). The API has no push sender, so it writes the notification as due now and the worker's minute tick sends it.
  - **Missed:** a call still ringing at its expiry is marked missed by the minute tick, and pushes "Missed call from Max" right away, quiet hours or not, because the call itself already passed the quiet-hours check.
  - Both link to the conversation.
- **The plugin:** flutter_callkit_incoming (MIT) wraps CallKit and Android's calling UI. It's a native plugin, not a WebView.
- **Not yet:**
  - Stopping the ringing on the person's other devices once one answers (the extra rings end at the timeout).
  - Calls from routines to people other than the acting user.
- **Tests:**
  - API (`phone-calls.test.ts`), with a local HTTP/2 APNs server: the token signature verified with the public key; VoIP headers and payload; a gone token removed; the Android data message; the banner row; one ring at a time; the ringing list; answer, then 409; the voice session with the call's conversation, the greeting and `speak_first`; other people get 404; missed and declined calls push the reason; quiet hours leave a notification instead.
  - pgTAP (`phone_calls_rls.test.sql`).
  - widget (`phone_calls_test.dart`): the banner; answer opens the live call with the call id and speak-first; decline; push payload parsing.
  - Also fixed: the call screen stops listening to the call before hanging up when it closes.

## D-136 Encryption at rest

- **What's covered:**
  - `messages.content`
  - `run_events.payload`
  - `memories.content`
  - `conversations.summary`
  - ticket details, results and comments: `tasks.details_md`, `tasks.result_md`, `task_comments.body_md`
  - page content and data, with their versions: `pages.html`/`data`, `page_versions.html`/`data`
  - `knowledge_chunks.text`
  - It's off by default, per workspace.
- **Keys:** envelope encryption with AES-256-GCM.
  - Each workspace has one data key in `org_keys`. It's wrapped either by the server's key (`CONTENT_ENCRYPTION_KEY`, 32 bytes, base64) or by AWS KMS (`CONTENT_KMS_KEY_ID` plus region and credentials).
  - The KMS calls (Encrypt and Decrypt over the JSON 1.1 API with Signature Version 4) were written from AWS's public docs.
  - Nobody reads `org_keys` through the app: no policies.
  - Deleting a workspace deletes its key (cascade), which leaves its sealed rows unreadable.
- **Format:**
  - Text columns hold `enc:v1:<keyId>:<base64(iv | ciphertext | tag)>`.
  - JSON columns hold `{"$enc": "enc:v1:…"}`.
  - Length checks on the covered columns apply to plaintext, with a higher limit for sealed text.
- **Writes:**
  - Every write path for these columns seals the value before it reaches Postgres: `contentKeys.seal`/`sealJson` with the row's workspace. Plaintext is passed through for workspaces that don't encrypt.
  - Run events are sealed by the event bus, with each run's workspace cached.
- **Reads:**
  - Decryption is transparent: the database client (`createDb`) has a postgres.js value transform that opens any sealed value it reads, so server code is unchanged.
  - Each API and worker process keeps a key ring of unwrapped workspace keys in memory. It's loaded at start and reloaded on `LISTEN kasama_org_keys`; triggers notify when a key or a workspace's mode changes.
- **Turning it on and off:**
  - `PUT /v1/orgs/{id}/encryption` (owners only, audited) creates and wraps the key and sets the mode to `encrypting`. New writes are sealed from then on.
  - The worker's minute sweep seals existing rows, 500 per column per pass, then sets the mode to `on`. After that it re-checks only the last hour's rows, as a backstop for any write path that was missed.
  - Turning it off sets `decrypting`; the sweep opens every row, then sets `off` and deletes the key.
  - A trigger stops app sessions from changing the mode directly, so it only changes through the API, after the key exists.
- **Rotation:** `POST /v1/orgs/{id}/encryption/rotate` rewraps the data key with the server's current key. Rows aren't rewritten.
  - To change the server key, set the new key in `CONTENT_ENCRYPTION_KEY` and the old one in `CONTENT_ENCRYPTION_KEY_PREVIOUS`, rotate (or call `rewrapAllKeys`), then drop the old key.
- **The app:**
  - Postgres no longer has plaintext, so the app reads through the API:
    - **Threads:** when a thread from Supabase has sealed content, the app loads `GET /v1/conversations/{id}/thread` instead.
    - **Memory edits:** they use `PATCH /v1/memories/{id}`, which seals.
    - **Realtime:** carries only ids for sealed run events (`sealed: true`, no payload); the app fetches them from the API's events endpoint.
  - Owners turn encryption on (after a confirmation) or off, and rotate the key, under workspace settings.
- **Search:** Postgres can't search ciphertext.
  - Memory and knowledge search use embeddings only; embeddings stay unencrypted, as the confirmation says.
  - Workspace search still matches titles and names, but not words inside sealed text.
  - SQL that read text out of message content now reads it in TypeScript: the For you brief, skill learning, and a sub-run's final answer.
  - Ops metrics that read computer events' payloads don't see sealed workspaces.
- **Tests:**
  - API (`encryption.test.ts`):
    - Owners only.
    - New messages, memories and run events are ciphertext in Postgres and plaintext through the API.
    - The sweep seals older rows and moves the workspace to `on`; the thread endpoint returns plaintext.
    - Rotation changes the wrapped key and wrapper but no rows, and a server holding only the new key still reads everything.
    - Turning it off opens every row and deletes the key.
    - AWS KMS wrap and unwrap against a fake KMS, with signed requests.
  - pgTAP (`encryption_rls.test.sql`): keys aren't readable, and the mode can't be changed from the app.
  - widget (`encryption_test.dart`).

## D-137 Memory backends

- **The interface:** `MemoryStore` (`packages/agent/src/memory-store.ts`) with these methods:
  - `recall` (the most relevant memories plus every pinned one)
  - `write` (an exact duplicate is updated instead of added)
  - `update`, `delete`, `list`
  - `deleteAll` for a set of bots
- **Who uses it:** the run loop (recall, compaction episodes, extraction), the `memory.search` and `memory.write` tools, the memory screen (`GET`/`PATCH`/`DELETE /v1/bots/{id}/memories…`), the privacy export, and account deletion.
- **The stores:**
  - **Built in (default):** `PostgresMemoryStore` wraps the existing hybrid-search store.
  - **Supermemory (v3):** each memory is a document tagged `kasama_bot_<bot>`, with kind, pinned and importance in its metadata. Recall uses `/v3/search` with the tag; listing uses `/v3/documents/list`; edits are `PATCH`; deletes are `DELETE`, and bulk delete goes by tag.
  - **Honcho (v2):**
    - **Layout:** each bot has a session `kasama-<bot>` in the workspace's Honcho workspace (default `kasama-<org>`), and each memory is a message from the bot's peer `bot-<bot>`, with kind, pinned and importance in its metadata.
    - **Recall:** Honcho's search, filtered to the session.
    - **Edits and deletes:** Honcho messages can only change their metadata, so an edit stores the new text in metadata and a delete marks it deleted, which hides it.
    - **Deleting everything:** deletes the bots' sessions.
- **Request shapes:** both adapters were built from the providers' public API docs and tested only against local fakes.
- **Settings:**
  - `PUT /v1/orgs/{id}/memory-backend` (admins, audited) takes the provider, the workspace's own API key (into Vault), and optionally a Honcho workspace and a server address for self-hosted providers.
  - The connection is checked before saving.
  - `copy_existing` copies every bot's current memories into the new store first.
  - `DELETE` switches back to built-in memory. Memories in the provider stay there; built-in memories were never removed.
  - In the app: Workspace settings → "Where memory is kept".
- **Ids:** `Memory.id` and `memory.written.memory_id` are strings: a uuid for built-in memory, the provider's id otherwise. The memory routes take the bot in the path, so the right store is used.
- **Privacy:**
  - The export's `memories.json` comes from the provider when one is configured.
  - Purging an account's solely owned workspace calls `deleteAll` for its bots before the rows cascade away.
- **Not yet:** semantic near-duplicate merging in external stores (only exact text duplicates are caught), and moving memories back from a provider to built-in memory.
- **Tests:**
  - API (`memory-backends.test.ts`), with fake Supermemory and Honcho servers:
    - A bad address is refused.
    - Copying keeps pinned memories.
    - The tools write and search the provider, and nothing lands in Postgres.
    - The memory screen lists, edits and deletes in the provider.
    - The export includes provider memories.
    - Account deletion bulk-deletes them.
    - Honcho's session layout, recall, edits through metadata, hidden deletes and session deletion.
    - Members can't change the backend; switching back to built-in works.
  - widget (`memory_backend_test.dart`).

## D-138 Paid data services

- **The interface:** `DataProvider` (`packages/agent/src/data.ts`) with `search`, `describe` and `call`.
- **The Treg adapter:** follows Treg's public guides (treg.to `llms.txt`, `skill.md`, `integrate.md`) and is tested against a local fake only.
  - Every request carries an `X-Treg-Token`.
  - The catalog: `GET /catalog/search?q=` and `GET /catalog/endpoints/<id>`. Prices are read from each entry's `cost` block (`usd_per_call`, `type`, `unit`).
  - Calls go through `/call/<id>`: GET with query parameters, or POST with JSON, passed through unchanged.
  - The amount charged comes from `X-Treg-Cost-Micro`; the call id from `X-Treg-Call-Id`.
  - Each call sends an `Idempotency-Key`, plus `X-Treg-Route-Max-Cost` set to 1.5× the quote (50× for per-result prices, since those vary with the number of results), so a call never costs much more than the price that was approved.
  - Treg's own refusals (`X-Treg-Error: 1`) turn into plain explanations: insufficient balance, over the approved cost, own key required, funds required, trial used up.
- **Tools:**
  - `data.search` (low risk): matching services as `data.{service}.{operation}`, each with its price.
  - `data.call` (medium risk, `confirm`): buys one call.
    - Under the default autonomy it always asks first. `approvalDetails` puts the service and the quoted price on the card, and the approval summary ends "for $0.0040 per call".
    - Autonomous bots and "always allow" grants follow the usual rules (action rules can cap spend, D-115), as with every other tool.
    - The provider's answer is untrusted output, cut to 20,000 characters.
    - Provider errors (4xx/5xx) aren't billed by Treg and fail the step.
- **Why two tools:** the spec names tools `data.{service}.{operation}`, but Treg's catalog has thousands of endpoints. So bots get one search tool and one call tool, and the name `data.{service}.{operation}` appears in search results, on the approval card and on the timeline.
- **Billing:**
  - **The workspace's own key:** saved in Settings → Model keys (provider `treg`). Treg charges the workspace's own account directly, with no Kasama markup. Each call is still recorded in `usage_ledger` (`kind = data_calls`, `billable = false`) with the provider's cost, endpoint and call id, so it shows in usage.
  - **Kasama Cloud resale:** uses Kasama's key (`TREG_API_KEY`) only when `TREG_RESALE=on`, which stays off until there's a written agreement with Treg (SPEC). Calls are then `billable`, at the provider's cost plus 20% (`DATA_MARKUP`), and settle into credits like other usage. A workspace's own key always wins.
- **Tests:**
  - API (`paid-data.test.ts`), with a fake Treg and a scripted model:
    - A default-autonomy bot asks first, with the price on the card, and nothing is called before approval.
    - After approval, the call uses the workspace's key with the right ceiling and query, and is recorded unbilled.
  - Tools:
    - Resale prices and charges include the 20% and are billable.
    - Insufficient balance is explained.
    - With no key, the tool says to add one.

## D-139 More sandbox providers

- **The pattern:** every hosted provider is a `HostedControlPlane` (`packages/sandbox/src/hosted-more.ts`). It starts Kasama's own computer image with computerd inside, finds it again by the computer's ref, deletes it, and says how to reach computerd's port. `HostedProvider` then supplies the rest, as on E2B and Daytona (D-057): exec, files, checkpoints, sleep to Kasama's object store and resume, and live view.
- **Testing:** each provider passes the shared `SandboxProvider` contract suite (`hosted.test.ts`, 50 tests). It runs against a local stand-in (`testing-hosted.ts`) that speaks the provider's API and runs the real computer image in Docker.
- **API shapes:** come from each provider's public docs; nothing was run against a real account.
- **Built:**
  - **Novita Agent Sandbox:** E2B-compatible. It reuses the E2B control plane on `api.sandbox.novita.ai`, with port URLs on `sandbox.novita.ai`, from templates built from the image.
  - **Kubernetes:** one Pod per computer (labels `app=kasama-computer`, `kasama_ref`), created through the core API.
    - **Reaching it:** through the API server's pod proxy (`/pods/<name>:7070/proxy`) with the service account token, or by pod IP when the supervisor runs in the cluster.
    - **The token clash:** the proxy needs `Authorization` for itself, so the computerd client sends computerd's token in `X-Computerd-Token` whenever the route already uses `Authorization`, and computerd accepts either header.
    - **Options:** an optional image pull secret and runtime class (gVisor or Kata, say). Private CAs work through `K8S_CA_FILE`.
  - **Incus:** a container from the computer image pulled from an OCI registry (`source.protocol = oci`), with environment variables as `environment.*`, the ref in `user.kasama_ref`, and asynchronous operations waited on.
    - **Reaching it:** on the instance's global IPv4 address.
    - **Auth:** a bearer token, or a client certificate through `tlsFetch` (undici, added to the sandbox package).
  - **Boat:** a VM per computer. Boat doesn't run OCI images, so the setup script runs the computer image with Docker inside the VM.
    - **Ports:** hosted publicly through `/sandboxes/{id}/host`. computerd still checks its own per-computer token on every call. Boat's private-port token only goes in a query string, which the computerd client can't carry.
  - **Railway:** a service per computer in one project and environment (GraphQL), deployed from the image, with a Railway domain per port Kasama uses. Found again by service name, since Railway has no labels.
- **Configuration:** all of these are set up on the supervisor (`NOVITA_*`, `K8S_*`, `INCUS_*`, `BOAT_*`, `RAILWAY_*`; image-based providers run `HOSTED_IMAGE_HEADLESS`/`HOSTED_IMAGE_DESKTOP`). The new ids are allowed for `computers.provider` and the create-computer API.
- **Not built, and why:**
  - **boxd:** only a gRPC API (no public REST or HTTP API to write an adapter against).
  - **CreateOS:** publishes operation names but not its REST paths.
  - **Alibaba Wuying AgentBay:** the raw HTTP API isn't documented (only SDKs). Images must be built and enabled in AgentBay first, and links only open ports 30100–30199, while computerd listens on 7070.
  - These wait for public HTTP docs, or a decision to wrap the providers' SDKs. They're in NEEDS-FROM-OLIVER.
- **Tests:**
  - The contract suite for Novita, Kubernetes (asserting computerd was reached through the pod proxy), Incus, Boat and Railway.
  - A computerd test for `X-Computerd-Token`.

## D-140 Agent-to-agent (A2A)

- **Version:** A2A v1.0, the current release at build time, over its JSON-RPC binding, written from the public spec:
  - agent cards at `/.well-known/agent-card.json`
  - PascalCase methods: `SendMessage`, `GetTask`, `CancelTask`, `ListTasks`
  - `A2A-Version: 1.0`
  - roles `ROLE_USER`/`ROLE_AGENT`, text parts `{ "text": … }`, states `TASK_STATE_*`
  - a send result is `{ task }` or `{ message }`
  - errors: TaskNotFound `-32001`, plus the standard JSON-RPC codes
  - Streaming and push notifications aren't offered yet (the card says so).
- **Publishing bots (server):**
  - Off by default. An admin turns on `organizations.a2a_enabled` (workspace settings), then people who manage a bot publish it (`PUT /v1/bots/{id}/a2a`, audited). Turning the workspace switch off unpublishes every bot.
  - A published bot's card lives at `/a2a/{bot}/.well-known/agent-card.json`. It's public, with the name, a description from the persona, one JSON-RPC interface, and a bearer security scheme.
  - Calls go to `POST /a2a/{bot}`.
- **Callers:**
  - They authenticate with a workspace API key (the hosted MCP endpoint's `ksk_` keys, D-117) from the bot's workspace, and act as that key's person, who must be able to use the bot.
- **Tasks:**
  - `SendMessage` becomes a run (trigger `a2a`, created by the key's person) in a conversation; the same `contextId` continues the same conversation.
  - The bot's usual approvals, budgets, action rules and audit log apply (`a2a.task` audit entries).
  - It blocks for up to 55 seconds unless `returnImmediately` is set; after that the caller polls `GetTask`.
  - A run waiting for its owner's approval reports `TASK_STATE_WORKING` with a status message saying so. The answer comes back as an artifact and the final status message.
  - `CancelTask` cancels the run; `ListTasks` lists the caller's tasks, optionally by context.
  - Tasks are recorded in `a2a_tasks`.
- **Calling outside agents (client):**
  - An outside agent is an integration with `kind = a2a`: config `{url}` (its address or agent card), with its token as the integration secret.
  - Its adapter reads the card, uses the A2A 1.0 JSON-RPC interface, and offers one tool, `a2a.<name>.send(task, context_id?, task_id?)`, medium risk, described from the card's description and skills.
  - The tool sends a blocking `SendMessage`, then polls `GetTask` until the task finishes, needs input, or 10 minutes pass. It returns the agent's answer with its `context_id` for follow-ups, and says when the agent needs more input.
  - Like other integrations, it must be attached to the bot.
  - The spec writes the tool as `a2a.send(agent, task)`; per-integration names (`a2a.<agent>.send`) fit how bots already get integration tools.
- **Across Kasama servers:** this is the same protocol linked agents will use.
- **The app:** a workspace switch, a "Publish as an A2A agent" sheet in bot settings with the agent card URL, and "AI agent (A2A)" as an integration type.
- **Tests:**
  - API (`a2a.test.ts`), over real HTTP with a scripted model:
    - Off by default (no card; publishing refused).
    - The card's interface; a key is required.
    - An outside A2A client's blocking task completes with the bot's answer.
    - `GetTask`, `ListTasks`, task-not-found and method-not-found errors.
    - The run is attributed to the key's person and audited.
  - Calling out: a bot in another workspace adds the published bot as an `a2a` integration (the connection test lists `send`), hands it a task through `a2a.planner.send`, and gets the answer. Turning A2A off removes the card.
  - widget (`a2a_test.dart`).

## D-141 Calls for you

- **The tool:** `voice.call(number, purpose, notes)` (high risk, send category) phones a business for the person the run acts for, through the workspace's own Twilio account.
  - **Setup:** admins connect it in workspace settings → Phone calls with an account SID, an auth token (into Vault) and a caller number; the account is checked before saving.
  - **Approval:** under the default autonomy it always asks first.
  - **Waiting:** the tool waits for the call to end (up to 20 minutes), streaming transcript lines as tool output, and returns how the call ended plus the full transcript.
- **Placing the call:**
  - Twilio's Calls API, with recording off, a 30-second ring, signed status callbacks to `/hooks/telephony/{call}`, and TwiML `<Connect><Stream>` pointing at the API's `/telephony/stream/{call}`.
  - The stream proves itself with a one-time token sent as a TwiML `<Parameter>`; only its hash is stored, and it's spent on use.
  - Shapes follow Twilio's public REST and Media Streams docs and were tested against fakes.
- **The live-voice stack:** the API bridges Twilio's μ-law audio frames to a realtime voice session.
  - **The session:** minted by the worker (only the worker reads model keys, D-065) in a new phone mode: `audio/pcmu` in and out; the call's instructions (name, purpose, notes, and "say you're an AI assistant calling on behalf of …; never pretend to be a person"); and a single `end_call` function.
  - **The bridge:** the API connects to the realtime WebSocket with the session's ephemeral key and sends `response.create`, so the bot speaks first.
  - **Audio:** bot audio goes back as Twilio `media` frames.
  - **Barge-in:** speech from the other side clears Twilio's buffer and cancels the response.
  - **Transcripts:** both sides are saved as they arrive.
  - **Hanging up:** `end_call` leaves the stream after the goodbye plays, which ends the call.
- **The person's controls:**
  - **Notification:** when a call starts, the person gets one linking to `/calls/{id}`, which shows the live transcript.
  - **End:** hangs up through Twilio.
  - **Take over:** redirects the call to the person's own phone (`<Dial>`, saved to `profiles.phone_number`).
  - **Listening in to the audio is not yet built;** the live transcript stands in for it.
- **Limits:**
  - International (E.164) numbers only.
  - Never emergency or short numbers (a set of emergency codes, including ones dialed with a country code).
  - The `call_deny_list` of prefixes (Kasama Cloud keeps one; self-hosters can add their own).
  - A daily cap per workspace (default 10).
  - Business numbers by default: Twilio Lookup's caller-name type. A number Lookup calls `CONSUMER` is refused unless admins allow personal numbers. Unknown types are allowed, since Lookup's caller name mostly covers US numbers.
  - Recording stays off.
- **Usage:** each completed call adds `phone_minutes` (rounded up) to the usage ledger with Twilio's approximate rate. It's not billable, since the workspace's own Twilio account pays. Kasama-provided telephony and its credit pricing wait for the legal review the spec requires before a hosted launch.
- **Tests:**
  - API (`calls.test.ts`), with fake Twilio, Lookup and OpenAI, and the test playing Twilio's media stream:
    - The call is placed with recording off.
    - A stream with the wrong token is dropped.
    - The bot speaks first, and its audio reaches Twilio.
    - The session uses μ-law with only `end_call` and says it's an AI calling for the person.
    - Barge-in clears audio, and `end_call` hangs up.
    - The status webhook rejects bad signatures.
    - The run gets the transcript, and minutes are recorded.
    - Emergency, short, denied, personal and over-cap numbers are refused.
    - Take-over dials the person's phone; ending hangs up.
  - widget (`outbound_call_test.dart`).

## D-142 Payments

- **The interface:** `PaymentProvider` (`packages/agent/src/payments.ts`) with three methods: issue a card, read its details, cancel it.
- **The first adapter:** Stripe Issuing, on the workspace's own issuing account, built from Stripe's public API docs and tested against a fake.
  - Owners connect it in workspace settings → Payments: the secret key and webhook signing secret go into Vault, and a cardholder is created with the billing address.
  - Owners also set a monthly cap for the workspace (default $500) and a per-bot default (default $200). `bots.payments_monthly_cap_usd` overrides the per-bot default.
  - Kasama-issued cards on Cloud wait for the legal review the spec requires before a hosted launch.
- **The tool:** `payments.request(merchant, amount, currency, reason)`, high risk, with a new `alwaysAsk` flag.
  - It always creates an approval, whatever the autonomy, grants or action rules. "Always allow" is ignored for it when deciding.
  - The approval card and summary show the amount ("for $89.50") and the merchant.
- **The card:**
  - Virtual and single-use: limited to the amount plus 5% (`spending_limits`, `all_time`).
  - Banned merchant categories are blocked: securities brokers, quasi-cash/money orders, stored-value and gift cards, wires, financial institutions, cash disbursement, gambling.
  - It expires after an hour; the worker cancels unused cards every minute.
- **At authorization:** Stripe's real-time webhook (`issuing_authorization.request`, signature-checked, 5-minute window) approves only when all of these hold:
  - the card's request is still issued and unexpired
  - the currency matches
  - the amount is within the 5%
  - a distinctive word of the approved merchant appears in the merchant descriptor
  - Once the authorization is created, the request is marked used with the amount spent, and the card is cancelled.
- **Hard bans no rule can relax:** checked on merchant and reason before any card exists: securities, crypto, gift and prepaid cards, transfers, and payment apps used to pay individuals. The blocked categories back this up at the card level.
- **The model never sees card details:**
  - The tool returns placeholders `{{card:<request>:number|exp|exp_month|exp_year|cvc|name}}`.
  - The executor fills them, like logins (D-128), only into tools that accept secrets (`browser.fill`, `http.request`), only for the card issued to that same run while it's live.
  - The values are added to the redactor, so they never reach events or the model.
- **Caps:** approved amounts this calendar month (issued or used cards), per workspace and per bot, are checked before issuing.
- **Tests:**
  - API (`payments.test.ts`), with a fake Stripe Issuing:
    - Bad keys are refused at setup.
    - An autonomous bot still asks, with the amount on the card.
    - "Always allow" doesn't create a grant.
    - Card limits and blocked categories are sent.
    - Card numbers never appear in run events.
    - Placeholders fill only for the same run's live card.
    - Real-time authorization declines a wrong merchant and an over-amount charge, approves the right one, then marks the card used and cancels it; later charges are declined.
  - Bans, merchant matching, monthly caps and the one-hour expiry.
  - widget (`payments_test.dart`).

## D-143 Linked agents

- **Linking:**
  - A bot's manager creates an invite (`POST /v1/bots/{id}/links`). It's a `kasama-link:` string carrying the server's address, the link id, a one-time code (only its hash is kept) and the bot's name. It works once, for 7 days.
  - The trusted contact accepts it with one of their bots (`POST /v1/links/accept`). Inviting and accepting are the two approvals.
  - Either side revokes (`DELETE /v1/links/{id}`), and the link ends for both.
- **On the same server:** a link is two `bot_links` rows pointing at each other.
- **Across Kasama servers:**
  - The accepting server calls the inviting server's `POST /links/{id}/accept` with the code, its own address, its bot, and a fresh `klink_` token.
  - The inviting server answers with its own token and bot. Each side stores the other's token in Vault and only a hash of its own.
  - Requests then go over A2A (D-140) to `/a2a/{bot}` with the link token. A link token also unlocks that bot's agent card, whether or not the bot is published.
  - Revoking calls the other server's `POST /links/{id}/revoke` with the link token.
- **Asking:** `links.ask(contact, request)` (medium risk, send category) sends a structured request to the linked bot named by the contact.
  - **What the other bot receives:** "a request from <bot>, the linked assistant of <person>", with an instruction to answer under its own person's rules and share only what the request needs.
  - **Same server:** it runs as the other bot, created by its owner, so their approvals, action rules and budgets apply (trigger `link`, on the sub-run queue, awaited up to 5 minutes). It can say it's still waiting for its person's approval.
  - **Another server:** an A2A task on that server's bot, run as that link's owner.
- **Both timelines:**
  - Every exchange is recorded on each side's link (`link_exchanges`: direction, request, answer, run).
  - The receiving owner gets a notification.
  - The app's Linked bots screen (bot settings) lists links and their exchanges. Each person sees only their own side.
- **Tests:**
  - API (`links.test.ts`), on one server:
    - Invite, then accept (a second accept is refused).
    - The asker's tool gets the answer; the answering run belongs to the other owner.
    - Both sides' exchanges and the notification; the other side's records stay private.
    - Revoking ends it for both.
  - Across two servers over real HTTP:
    - The token handshake activates both sides.
    - The request goes over A2A and is answered as the other owner, with exchanges recorded on both servers.
    - Revoking on one server revokes on the other, and asking then fails.
  - widget (`links_test.dart`).

## D-144 Voice upgrades

- **Barge-in:**
  - The realtime session asks for server-side turn detection with `interrupt_response`.
  - The app's call client (now `RealtimeEvents`, testable on its own) watches whether the bot is responding or its audio is playing. When the person starts speaking (`input_audio_buffer.speech_started`), it sends `response.cancel` and `output_audio_buffer.clear`, so the bot stops at once and listens.
  - Phone calls (D-141) already cleared Twilio's buffer the same way.
- **The animated avatar (optional):**
  - On live calls, a button turns on `TalkingAvatar`, drawn on device from the bot's avatar. It breathes while listening; while the bot speaks (the speaking state comes from the call's audio buffer events) it bounces gently with a pulsing ring and a small voice meter.
  - It follows reduced-motion settings, and the choice is remembered on the device.
  - A face-tracking or lip-synced 3D avatar isn't built.
- **Wake word (desktop and Android):**
  - Settings → Wake word: a phrase (default "hey kasama") and the bot to call. Hearing the phrase opens a live call with that bot. It listens while the app is open.
  - Detection runs on device with sherpa-onnx keyword spotting (Apache-2.0) and its GigaSpeech zipformer keyword model (Apache-2.0, int8 files). The model is downloaded once (about 18 MB) from the sherpa-onnx releases, checked against a pinned SHA-256, and unpacked into the app's support folder.
  - openWakeWord was ruled out: its pretrained models are licensed for non-commercial use only.
  - **Tokenizing the phrase:** the model's tokenizer isn't in the download (no `bpe.vocab`), so the app spells the phrase from `tokens.txt` itself. It lists every segmentation with the fewest pieces (up to four) as keyword lines with one tag. On the model's own examples this always includes the official tokenization.
  - **Privacy:** audio stays on the device until the call starts.
  - **Not offered:** on iOS (as the spec scopes it), or in the background on Android (that would need a foreground service).
- **Tests:**
  - unit: barge-in cancels and clears only while the bot is talking; the keyword tokenizer on a small vocabulary. The tokenizer was also checked offline against the real vocabulary and examples.
  - widget: the avatar follows the speaking state and the choice is remembered; turning the wake word on prepares the model and listens for the phrase, and a detection opens the chosen bot's live call (fake engine).
  - Both native builds work with the plugin.

## D-145 Ops extras: sign-up allowlist, AI Gateway, secret store

- **Sign-up allowlist:**
  - `SIGNUP_ALLOWED_EMAILS` (emails or domains, comma-separated; `@acme.com` or `acme.com` for a domain) sits beside `DISABLE_SIGNUP`.
  - Kasama's Supabase sign-up hook enforces it for every sign-in method, Google included, and refuses others with "limited to approved email addresses".
  - Compose now wires the hook (`SIGNUP_HOOK_ENABLED`, `AUTH_HOOK_SECRET`, sent to the auth service and the API). An allowlist without the hook secret refuses sign-ups rather than allowing everyone.
- **Cloudflare AI Gateway:**
  - With `AI_GATEWAY_URL` (`https://gateway.ai.cloudflare.com/v1/<account>/<gateway>`), model calls whose credential has no base URL of its own go through the gateway's provider endpoint, for caching, logs and rate limits. The endpoints are: `openai`, `anthropic/v1`, `google-ai-studio/v1beta`, `grok/v1`, `openrouter/v1`.
  - `AI_GATEWAY_TOKEN` is sent as `cf-aig-authorization` for authenticated gateways.
  - `AI_GATEWAY_PROVIDERS` limits which providers use it.
  - It's applied in `CredentialResolver`, so every model path picks it up. Paths follow Cloudflare's public docs.
- **Secret store:**
  - **The interface:** `SecretStore` (`packages/agent/src/secret-store.ts`) for bots' named secrets (`{{secret:NAME}}`). Supabase Vault is the default; the Infisical adapter uses the workspace's own project with a universal-auth machine identity.
  - **Infisical calls:** `/api/v1/auth/universal-auth/login`, then `/api/v3/secrets/raw` to list, create, update and delete in the project, environment and path. Built from Infisical's public API docs; tested against a fake.
  - **What Kasama keeps:** each secret's name, kind, allowed hosts and bots (`secrets.store` says where the value is). Values are read from Infisical when a bot uses them.
  - **Settings:** admins set it up in workspace settings → Where secrets are kept (`PUT /v1/orgs/{id}/secret-store`, checked before saving, audited).
  - **Moving secrets:** `move_existing` moves current Vault secrets into Infisical; switching back to Vault copies them back first.
  - **What it doesn't cover:** the rest of Kasama's own credentials (model keys, integration tokens, channel secrets and so on) stay in Vault. Moving those is a separate, larger change.
- **Tests:**
  - API (`ops-extras.test.ts`):
    - The allowlist admits listed emails and domains (including Google sign-ins) and refuses others.
    - Gateway URLs and the auth header, an own base URL winning, and the provider filter.
    - Infisical: a bad identity refused, existing secrets moved (Vault row cleared), new secrets written to Infisical, bots reading values from it, and switching back to Vault restoring the values.
  - widget (`secret_store_test.dart`).

## D-146 Audit-log forwarding

- **What it is:** an enterprise feature (`ee/`, license feature `audit_forwarding`). Admins add forwarders per workspace (`/v1/orgs/{id}/audit-forwarders`, audited). Each forwarder streams that workspace's `audit_log` rows to one destination.
- **Destinations:**
  - **Signed webhook:** JSON `{forwarder_id, events}`, with `X-Kasama-Signature: t=<unix>,v1=<hex HMAC-SHA256 of "t.body">` and a batch id header.
  - **OTLP/HTTP logs endpoint:** JSON to `<url>/v1/logs`. Each row becomes a log record (body = action; attributes = id, actor, target, metadata) under `service.name=kasama`, scope `kasama.audit`. Optional headers (an auth token, say) are stored as a JSON secret.
  - **S3-compatible storage:** a JSON Lines object per batch at `<prefix>/<org>/YYYY/MM/DD/<ms>-<first id>.jsonl`, signed with Signature Version 4 and addressed path-style, so AWS S3, R2 and MinIO all work.
  - Secrets go to Vault.
- **At least once, from a cursor:**
  - Rows go in `(created_at, id)` order from each forwarder's cursor, in batches of 500, up to 10 batches per pass.
  - The cursor moves only after the destination accepts a batch. A failure keeps it in place (recorded as `last_error`), so the same rows go again on the next pass.
  - The comparison and the update happen in SQL so timestamps keep their microseconds. Rounding them in JavaScript resent the last row, which a test caught.
  - New forwarders start from now; `from: "start"` sends the whole history.
- **Running it:** the worker runs a pass every minute when the server's license includes the feature.
- **Tests:**
  - API (`audit-forwarding.test.ts`), with fake destinations:
    - Members refused; a webhook without a secret refused.
    - All three destinations get the new rows.
    - A busy webhook (503) keeps its cursor and gets the same batch next pass, while the others aren't sent anything twice.
    - The webhook signature, the OTLP header and records, and the S3 signature header and JSON Lines body.
    - A pass with nothing new sends nothing.
  - Without the license: 402.
