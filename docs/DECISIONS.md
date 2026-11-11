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
- **Decision**: openapi-generator dart-dio with json_serializable generates `dart/casama_api` (one class per event variant included). `gen-dart.ts` generates a sealed `RunEventItem` hierarchy in `casama_sdk` that dispatches on `type` to those classes, with `UnknownRunEventItem` for forward compatibility. The union is removed from the generator's input only.
- **Consequences**: `casama_api` is a separate generated package that `casama_sdk` re-exports. App models that are not API types can still use freezed.

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

- **Decision**: `append_run_event` allocates the next seq (`runs.last_seq`) and inserts in one transaction. An `AFTER INSERT` trigger calls `realtime.send` for topics `run:{id}` and `bot:{id}` (private channels, authorized by a policy on `realtime.messages` that calls `realtime_topic_allowed`) and `pg_notify('casama_run_events', 'run_id:seq')`.
- **Consequences**: an event is broadcast if and only if it was stored. The API's SSE stream listens to NOTIFY and reads rows, so it never sees an event that was rolled back.

## D-014 Deltas from a crashed model step stay in the log

- **Context**: Events are append-only; a model step that crashes mid-stream is re-executed by DBOS.
- **Decision**: each model step attempt uses a new `message_id`. Clients group `message.delta` by `message_id` and treat `message.completed` as the final text; partial deltas whose `message_id` never completes are hidden once the run ends.

## D-015 Model keys: written by the API, read only by the worker

- **Decision**: `POST /v1/credentials` writes the key to Vault with the server role after checking `has_role(org, 'admin')` under the user's session. `POST /v1/credentials/{id}/test` enqueues a `testCredential` workflow, because only the worker reads `vault.decrypted_secrets`. Keys are resolved inside each step and never appear in step outputs, which DBOS persists.

## D-016 Worker database role (deferred; built in D-095)

- **Context**: The spec calls for a dedicated role for system jobs, scoped by explicit org ids.
- **Decision**: In Phase 1 the worker uses the server connection and scopes every query by run, bot and org ids. A least-privilege `casama_worker` role (execute on the event functions, Vault read, table grants without bypass) is scheduled for the Phase 8 security review.

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

- **Decision**: `ReplayGateway` chooses a turn by matching the request (last user text, last role, last tool name, system text, model), so replays are deterministic, including re-executed steps after a crash. Workers take `CASAMA_MODEL_FIXTURES` (JSON or JSONL) and `CASAMA_MODEL_RECORD` (append real exchanges as fixture turns).

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

## D-033 Warm pool deferred (built in D-148)

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

## D-038 v1 product scope (English-only clients, deferred channels; channels built in D-134)

- **Context**: the product should stay region-neutral. v1 should not ship external messaging adapters; integrations should include Composio, Pipedream and media generation like comparable open-source agent platforms.
- **Decision**: Phases 0–8 cover Casama's own Flutter and CLI clients only. External `ChannelAdapter` implementations (Telegram, email inbox, SMS, Slack, WhatsApp, Messenger) and extra sandbox vendors are specified under **Post-v1** in `SPEC.md`. Phase 4 ships Composio, Pipedream Connect and a `MediaProvider` (fal.ai first). Launch locale is English only; ARB files stay the source for UI strings.
- **Consequences**: Phase 4 and Phase 6 gates do not require Telegram or email channel tests. `channel.send` and channel tables remain in the spec for post-v1 work.

## D-039 Riverpod without code generation; no freezed

- **Context**: the spec names Riverpod with code generation and freezed. At build time `riverpod_generator` and `json_serializable` required conflicting analyzer versions, so the code generation toolchain would not resolve.
- **Decision**: plain Riverpod 3 providers and notifiers (no `@riverpod` codegen) and small immutable classes with `copyWith` instead of freezed. API models come from the generated `casama_api` client. Revisit when the generators agree on an analyzer version.

## D-040 One Backend interface in the app

- **Decision**: every read and write goes through `Backend` (`client/lib/core/backend.dart`). `SupabaseBackend` reads and edits through Supabase under RLS (messages, runs, memories, skills, bot edits) and sends commands through the generated API client; widget tests use a fake. The API client gets its token from the Supabase session (`CallbackSessionStore`).

## D-041 Live run events: Realtime plus catch-up

- **Decision**: the app subscribes to the private Realtime topic `run:{id}`, merges broadcasts with `GET /v1/runs/{id}/events?after_seq=` through `RunEventBuffer` (ordered by seq, duplicates dropped, gaps filled from the API) and polls catch-up every 2 seconds as a safety net. The integration test asserts events arrive over Realtime.

## D-042 Offline cache (drift) deferred (superseded by D-112)

- **Context**: the spec's client architecture lists a drift cache for conversations, messages and bots.
- **Decision**: deferred past the MVP app. Data loads from Supabase and the API on demand. Add drift (including its web/wasm setup) when offline or instant-open becomes a priority.

## D-043 Chat attachments deferred (built in D-082)

- **Decision**: the `attachments` table exists, but the chat composer has no attachment picker yet; files reach bots through the computer's file browser (upload) in the meantime.

## D-044 CORS for the web app

- **Decision**: the API allows `PUBLIC_APP_URL` and `CORS_ORIGINS`, plus any `localhost`/`127.0.0.1` origin outside production.

## D-045 Headless "screen" shows the browser page

- **Decision**: `GET /v1/computers/{id}/screenshot` returns the desktop when one exists; on headless computers it captures the bot's open browser page through agent-browser, and returns 409 when there is nothing to show. The app refreshes it every 5 seconds until live view arrives in Phase 5.

## D-046 Android minSdk 26

- **Decision**: `sentry_flutter` needs Android 8.0 (API 26), so the app's minimum SDK is 26. Debug builds allow cleartext HTTP for local development servers.

## D-047 Webhooks are verified in the worker

- **Decision**: `/hooks/github/{routine_id}` and `/hooks/custom/{routine_id}` accept the raw body (capped, rate limited) and enqueue a `routineWebhook` workflow. The worker, which is the only service that reads Vault, checks the HMAC (`X-Hub-Signature-256` or `X-Casama-Signature`) with a constant-time compare before starting a run. The API answers 202 either way so callers cannot probe which routines exist.

## D-048 Approval waits use DBOS messages

- **Decision**: a run that needs approval sets `waiting_approval`, then loops `DBOS.recv("signal", ≤300 s)` and re-reads the approval row. Deciding (API) or cancelling sends the signal. Waits survive worker restarts, and a run waiting days costs nothing. Approvals expire after 24 hours; expired or denied calls fail only that tool step (`approval_denied`) and the model continues.

## D-049 Subagents and delegation run on their own queue

- **Decision**: DBOS cannot start a workflow from inside a step, so `subagent.spawn` and `bots.delegate` enqueue a child `agentRun` on the `subruns` queue through `DBOSClient` and wait for its result. Children get 20% of the parent's remaining budget (or less if asked), a tool subset and a wall-clock limit; delegation depth is capped at 3 and cycles are refused.

## D-050 Push fan-out lives in the worker

- **Decision**: notifications are rows in `public.notifications` (broadcast to the private Realtime topic `user:{id}` by a trigger) plus FCM HTTP v1 pushes sent by the worker's `NotificationService`, instead of a Supabase Edge Function. One less runtime to deploy and test; the service account JSON is a worker secret (`FCM_SERVICE_ACCOUNT_JSON`). Without it the in-app inbox still works.

## D-051 App push uses FCM registration tokens

- **Decision**: the app registers with `getToken()` because the worker sends to `message.token`. firebase_messaging 17 deprecates that in favour of installation-ID direct send; move both sides together once that API is stable on all platforms. Firebase options come from `--dart-define` (`FIREBASE_*`), so no Firebase config files are committed and builds without them simply have push off.
- **Web:** Chrome shows the permission prompt only from the click itself. The Turn on control is a real browser button (`bindNotificationButton`), so the prompt opens in that click; the page waits for the answer and stays up if the prompt is dismissed. The messaging service worker is `web/firebase-messaging-sw.js`, registered at the site root with those same `FIREBASE_*` values on its address (a worker cannot read `--dart-define`). The self-host page's `script-src` allows `https://www.gstatic.com` so Firebase's scripts and that worker can load.

## D-052 Composio and Pipedream adapters follow their public REST docs

- **Decision**: the Composio (v3 tools list and execute) and Pipedream Connect (OAuth client credentials, actions list and run) adapters are written from the public REST documentation and tested against local mocks only. Field names may need small fixes once real keys are available (tracked in NEEDS-FROM-OLIVER).

## D-053 Integration tool names

- **Decision**: integration tools are named `{kind}.{integration}.{tool}` (for example `mcp.calc.add`) and sent to models with dots replaced by double underscores. Integrations are attached per bot, optionally with a tool allowlist, and tool lists are cached on the integration row and refreshed by "Test".

## D-054 Neko is the live-view streamer

- **Decision**: the desktop image runs Neko (m1k1o/neko, Apache-2.0), compiled from a pinned tag on Ubuntu 24.04 so glibc and GStreamer match the runtime. Selkies (MPL-2.0, Python and GStreamer) was the alternative; Neko won on a single Go binary, a small JSON signaling protocol, per-user `can_host` profiles that enforce view-only inside the streamer, a data-channel ping for latency, and touch support. computerd starts Neko only when the first viewer arrives (`POST /stream/start`) with fresh viewer and controller passwords (multiuser provider, so every connection is its own session) and stops it 60 s after the last viewer leaves. Neko's chat, file transfer and plugins are off.

## D-055 Media goes only through a TURN relay

- **Decision**: viewers use `iceTransportPolicy: relay` with short-lived coturn REST credentials from the stream session. The relay joins each desktop computer's private network under the alias `turn` (the supervisor connects it), and Neko uses it as its own ICE server, so media flows client ↔ coturn ↔ computer without the computer being reachable from anywhere. coturn refuses every peer address except its own relay address, so it cannot be used to reach other hosts, private ranges or metadata services. Signaling goes client ↔ API ↔ supervisor ↔ Neko; the API proxy drops input events from view tokens and lets a control token take control only while its user holds the lease, and takes control back when the lease ends.

## D-056 Hosted providers are routed by the supervisor

- **Decision**: E2B and Daytona adapters run inside the supervisor next to Docker, because they need the object store and the computer-token secret, which only the supervisor holds. The API and worker keep one client; `ComputerService` picks the provider from `computers.provider` and the client sends `x-casama-provider`.

## D-057 E2B and Daytona run Casama's own image

- **Decision**: both providers start Casama's computer image (an E2B template or a Daytona snapshot) with computerd as the start command, and every call goes to computerd through the provider's authenticated port URL (E2B `https://{port}-{id}.e2b.app`; Daytona signed preview URLs with `x-daytona-preview-token`). Files, exec, checkpoints, sleep to object storage and live view are the same code as on Docker. The adapters were written from the public REST docs and verified against local control-plane mocks that run the real image (`testing-hosted.ts`). Hosted sandboxes have their own internet access, so the egress proxy's private-range blocking does not apply there; the TURN relay must be public for live view.

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

- **Decision**: snapshots, checkpoints and (later) attachments stay behind the `ObjectStore` interface with two implementations, filesystem and S3-compatible. Self-hosted default: the filesystem store on a Docker volume (nothing extra to run on one host). Self-hosted S3: SeaweedFS (Apache-2.0, actively maintained), an optional `s3` compose profile, with `S3_CREATE_BUCKET=true` to create the bucket on start. MinIO was the obvious choice, but its community images are no longer published, so it is not a dependable default. Hosted Casama: Cloudflare R2, because every wake downloads a whole home directory and R2 has no egress fees (S3 would bill each restore). AWS S3 and Supabase Storage's S3 endpoint work through the same settings. The S3 store is tested against SeaweedFS (`packages/sandbox/test/object-store.test.ts`).
- **Other Cloudflare products**: Turnstile is worth offering, but only as configuration: Supabase Auth supports it as its captcha provider (documented, off by default; it needs a site key). Cloudflare Tunnel helps self-hosters without a public IP expose the API and webhook endpoints (documented as an option, no code); it cannot carry the TURN relay's UDP. Workers, Queues and Access add nothing over DBOS queues, the Hono API and Supabase Auth, and would tie core features to one vendor, so they are not used.

## D-063 Error reporting: Sentry protocol by default, PostHog optional

- **Decision**: errors go to one reporter behind the observability interface (`ErrorReporter`): `ERROR_REPORTING=auto|sentry|posthog|none`, where auto picks Sentry when `SENTRY_DSN` is set, else PostHog when `POSTHOG_API_KEY` is set, else nothing. The Sentry SDKs stay the default path because their DSN works with sentry.io, self-hosted Sentry and GlitchTip (one container plus Postgres), which keeps self-hosting light; PostHog's self-hosted stack is much heavier. PostHog is fully supported for teams that want one dashboard (errors, analytics and flags) with a configurable host (cloud region or self-hosted). The app does the same with build-time keys and adds PostHog screen analytics when a PostHog key is set, without person profiles or session replay.
- **Privacy**: every payload is scrubbed before it leaves: request bodies, headers, cookies and users are dropped, secret-looking values and emails are redacted, context keeps only ids, codes and numbers (no prompts, messages, tool arguments or keys), and PostHog stack frames lose their source lines. Tested in `packages/observability/test/errors.test.ts` and `client/test/telemetry_test.dart`.
- **Android**: minSdk stays 26 because `sentry_flutter` requires it.

## D-064 Default model: Muse Ember on OpenRouter, GPT-6 Luna on OpenAI, at medium reasoning effort

- **Decision**: wherever Casama suggests a model it uses Muse Ember on OpenRouter (`meta/muse-ember`) and GPT-6 Luna on direct OpenAI (`gpt-6-luna`) (ids checked on OpenRouter's catalog, 2026-11-11; OpenAI id unchanged from 2026-11-09). There is no separate "Medium" model: GPT-6 Luna takes a reasoning effort of none to max, and medium is OpenAI's default, so the default model runs at medium unless a bot sets `reasoning_effort` (new optional field on `ModelChoice`; sent as `reasoning.effort` to OpenRouter and `reasoningEffort` to OpenAI, whose function calling with reasoning needs the Responses API the AI SDK uses). The defaults live in `@casama/domain`, can be overridden per server (`DEFAULT_MODEL_OPENROUTER`, `DEFAULT_MODEL_OPENAI`, `DEFAULT_REASONING_EFFORT`) and are served in `/v1/config`; onboarding, the New bot sheet and `casama bot create` preselect them for the chosen key's provider and never overwrite a model the user typed. Key tests use the default model with effort `none`. Recorded fixtures keep their fixture ids.
- **Live checks**: `scripts/live-check.sh` reads a real OpenRouter key from `~/.config/casama/openrouter.env` (or the environment) and runs a handful of capped calls: the key test, one live tool call that drives a real Docker computer, and (with `LIVE_APP=1`) a live chat in the macOS app. CI and the default tests use fixtures and need no key.

## D-065 Voice runs on the user's own keys, through the worker

- **Decision**: dictation (OpenAI `gpt-4o-mini-transcribe` or Deepgram `nova-3`), read aloud (ElevenLabs, OpenAI, Cartesia or Fish Audio, cached per message and voice in `tts_cache`) and live-call sessions all use the workspace's own provider keys, so they run as short worker workflows on their own `voice` queue (only the worker reads Vault). Live calls use OpenAI Realtime over WebRTC (GA interface, default `gpt-realtime-2.1`): `POST /v1/voice/session` mints a 10-minute ephemeral key carrying the bot's persona and tools, the app connects to OpenAI directly, and each function call goes to `POST /v1/voice/tool`, which runs it as an agent run (trigger `voice`, no model step) with the bot's normal approvals and returns the output for the model. Transcripts are saved to the conversation, and every minute, second or character is in `usage_ledger`. Queue polling dropped from 1 s to 50 ms (voice) and 100 ms (runs): a forwarded tool call answers in about 200 ms locally, and the session mints in about 30 ms. Provider request shapes come from their public docs and were tested against local mocks only.

## D-066 The desktop companion embeds computerd and tunnels through the API

- **Decision**: "Use this computer for bots" runs computerd inside the desktop app on 127.0.0.1 in companion mode: files and working directories must stay inside the folders the user shares (symlinks resolved), each capability (shell, files, browser, desktop) is off until approved, and archives, terminals and the streamer are refused. The app opens one WebSocket to `/v1/local-computer/connect` (device token, kept in secure storage or a 0600 file), and the API forwards HTTP requests from the worker's `local` provider over it (internal `/internal/local/*`, shared secret derived from `DATABASE_URL`), streaming responses back. Only bots the user allowed may act (checked against the run's bot on every call), high-risk actions always ask on this provider, and an overlay plus the tray show which bot is acting, with Stop. agent-browser runs in its own `casama` namespace and session, never touching the user's other browser sessions. Without a sandbox supervisor, personal computers still work. One API instance holds the device sockets (a multi-instance API needs sticky routing; noted for later). The macOS app runs without the App Sandbox so it can start agent-browser and shell commands; it ships with Developer ID signing and notarization rather than through the Mac App Store.

## D-067 Mobile and desktop extras

- **Decision**: one iOS WidgetKit extension holds the home-screen widget (bot status, today's cost, Ask button) and the Live Activity (a running bot on the lock screen and Dynamic Island, `LiveActivitiesAppAttributes`), sharing data through the App Group `group.dev.casama.app`; Android has an AppWidgetProvider. Share to bot uses receive_sharing_intent on Android and a small native share extension on iOS that saves the shared text to the App Group and opens `casama://app/quick-ask`. The desktop app adds a tray or menu-bar icon with status and a global shortcut (Cmd/Ctrl+Shift+K) for quick ask. The app now draws immediately and connects behind a startup screen with a timeout and Retry; before, an unreachable server left the release build on the splash screen forever.

## D-068 Owner admin console

- **Decision**: instance owners are `INSTANCE_ADMIN_EMAILS`, or the first user to sign up when unset (the usual self-host case). The console shows totals, users, workspaces with quotas (stored in `entitlements.limits`), configured services and their health, and update notices from `UPDATE_CHECK_URL` (a GitHub "latest release" API URL; off by default, so no phoning home).

## D-069 Publishing the SDK and CLI

- **Decision**: `casama_api` and `casama_sdk` are pub.dev-ready at 0.6.0 (publishable metadata, example, LICENSE, CHANGELOG; `dart pub publish --dry-run` clean apart from uncommitted files), with versions set by the generator. The CLI builds to native binaries per platform (`scripts/release-cli.sh`, `.github/workflows/release.yml` on `cli-v*` tags as a draft release) and `scripts/homebrew-formula.sh` writes the formula for a `stackwares/homebrew-tap` repository. Publishing and creating the public tap are outward actions left to a maintainer. `examples/sdk_sample` is an external app that depends on `casama_sdk: ^0.6.0` exactly as a pub.dev user would (a `dependency_overrides` block points at this repository until it is published).

## D-070 Billing: one provider interface, server-side entitlements, off when self-hosted

- **Decision**: billing lives in `apps/server/src/billing` behind one `BillingProvider` interface (`verifyWebhook`, `parseEvent`, `fetchSubscription`, `verifyPurchase`, `createCheckout`, `customerPortal`, `fetchPayment`, `reportUsage`) with three adapters written with plain `fetch` and `jose` (no vendor SDKs): **Dodo Payments** (hosted checkout with `metadata.org_id`, customer portal, Standard Webhooks signatures with a 5-minute tolerance, usage events for metered plans), the **App Store** (App Store Server API with an ES256 key; every signed payload's x5c chain must lead to Apple Root CA - G3, shipped in the repo, with Apple's marker extensions on the intermediate and leaf; Server Notifications V2) and **Google Play** (subscriptionsv2 with a service-account token, acknowledgement, real-time developer notifications authenticated by a secret push-URL token or the Pub/Sub OIDC token). Every provider is optional and configured by environment variables.
- **Rules**: every webhook is stored in `billing_events` and processed once by `(source, event_id)`; the payload is never trusted, the server re-fetches the subscription. Purchases belong to the workspace: Dodo checkouts carry the org id, and the apps pass the org id as `applicationUserName` (App Store `appAccountToken`, Play `obfuscatedAccountId`), so a store purchase cannot be linked to another workspace and Restore Purchases is idempotent. Refunds (Dodo refunds and lost disputes, App Store REFUND/REVOKE, Play voided purchases and revocations) mark the subscription `refunded`, which later events cannot undo; cancellation keeps access to the period end on the stores, while a Dodo `cancelled` status ends it. The entitlement (best entitled subscription by plan order, else the default plan) is computed on the server and is the only input to quotas and paywalls; owner overrides from the admin console (`entitlements.overrides`) survive plan changes.
- **Credits**: `credit_ledger` is append-only with a running balance; `credit_apply()` applies each `(org, reason, reference)` once. Plans grant included credits once a month per plan. Usage that the platform pays for (computer and stream seconds, Cloud Connect model calls; `usage_ledger.billable`) becomes credit deductions in a worker job every minute; usage on the workspace's own model keys is never charged. Casama Cloud plans set `credit_gate`, so a run is refused (`out_of_credits`) when the balance is at or below zero, and `computer_hours` caps the month; `max_bots` and `max_computers` return 402 `plan_limit`, which opens the paywall in the app.
- **Store rule in the app**: iOS sells subscriptions with in-app purchase and shows the web checkout link only on the US storefront; Android uses Google Play billing; web and desktop use Dodo checkout. Credit packs are sold on the web only (the stores are not required to sell them). Re-check store rules every quarter.
- **Self-hosting**: `BILLING_ENABLED=false` is the default: no paywall, the `selfhost` plan has no limits, `/hooks/billing/*` and `/connect/*` are not served, and the Billing entry is hidden in the app. Plan names, prices and limits are placeholders (`free`, `pro`, `pro_yearly`, `credits_10`); product ids are set per deployment in the `plans` and `credit_packs` tables.
- **Testing**: Dodo, the App Store Server API (with a throwaway openssl PKI that mimics Apple's chain) and the Play Developer API are local fakes using the documented shapes (`apps/server/test/fake-billing.ts`); `apps/server/test/fake-billing-server.ts` runs them for manual and device tests, where opening a checkout URL "pays" and delivers the signed webhook. Dodo request and webhook shapes were checked against docs.dodopayments.com on 2026-11-10; the refund webhook schema is not documented there, so the adapter reads `payment_id` and re-fetches the payment.

## D-071 Cloud Connect: a self-hosted instance uses cloud computers and model credits

- **Decision**: a Casama Cloud workspace admin creates a Cloud Connect key (`kcc_…`, stored as a SHA-256 hash, scopes `computers` and/or `models`) for a named instance. The cloud API serves `/connect/v1/*` to those keys: `whoami`; `sandbox/*`, the supervisor API scoped to the workspace (the first create or resume of a ref claims it; other workspaces see it as not running and cannot use it; object deletion is limited to the workspace's own refs; live view and terminals are not proxied in v1); and `models/chat/completions`, an OpenAI-compatible proxy to the cloud's own upstream (OpenRouter by default) that forces usage reporting, passes streams through and bills the upstream's reported cost (or the price table) times `CLOUD_MODEL_MARKUP`. Computer time is metered on the proxy from create or resume to sleep or delete (and flushed every minute while running) at `CLOUD_COMPUTER_USD_PER_HOUR`. Everything lands in the cloud workspace's `usage_ledger` with the instance name, so it shows on the cloud bill and is deducted from credits; credit-gated workspaces get 402 at zero.
- **Self-hosted side**: setting `CASAMA_CLOUD_URL` and `CASAMA_CLOUD_KEY` adds the `casama-cloud` computer provider (the supervisor client pointed at the proxy); computers created with `provider: "casama-cloud"` run in the cloud. Model credits need no new code: a workspace adds an OpenRouter credential whose base URL is `<cloud>/connect/v1/models` and whose key is the Cloud Connect key, so the default model and reasoning settings pass through unchanged.
- **Verified**: a self-hosted API and worker ran a bot's shell command on a cloud Docker computer through the proxy, and the computer time showed on the cloud bill and reduced its credits (`apps/server/test/cloud-connect.test.ts`); one live call through the proxy to OpenRouter (GPT-6 Luna, 16 output tokens max) was billed from OpenRouter's reported cost.

## D-072 Privacy: export, deletion with a grace period, retention

- **Decision**: `GET /v1/me/export` streams a ZIP of JSON files built under the user's own session, so it holds exactly what RLS lets them see (account, notifications, and per workspace: bots, conversations, messages, runs and events, memories, routines, computers, usage, audit log...), without Vault references, token hashes, vectors or audio. `DELETE /v1/me` (confirmed by typing the email) bans the auth user, ends sessions and removes push devices at once, then a daily worker job purges after `ACCOUNT_DELETION_GRACE_DAYS` (default 7, max 30): workspaces the user solely owns (their computers' archives first, then the rows by cascade) and the auth user. Shared workspaces lose only the membership. Run events are deleted per workspace after `run_event_retention_days` (default 180, 7 to 3650, admins set it). Settings → Privacy in the app and `casama account export|delete` in the CLI.

## D-073 Enterprise features in ee/ under a commercial license

- **Decision**: `ee/` is a workspace package (`@casama/ee`) under a draft source-available license (read and try freely; production use needs a key; no resale or hosting for others); everything else stays Apache-2.0. Keys are Ed25519-signed JWTs (issuer `casama-licensing`, features, seats, expiry) verified against `ee/server/license-public.pem`; the private signing key lives outside the repo (`~/.config/casama/license-signing-key.pem` on the build Mac, to move into a password manager). First features: audit-log export (CSV/JSON, admins) and SAML SSO through Supabase Auth's admin API (the self-host stack enables SAML with a generated key; the app gains "Continue with SSO"). Without a key the routes answer 402 `license_required`. Advanced roles are planned.

## D-074 Opt-in telemetry

- **Decision**: off unless `TELEMETRY=on`. A weekly worker job posts a random instance id (stored in `instance_settings`), the version, and the counts of bots and users active in the last 7 days to `TELEMETRY_URL`; Casama Cloud stores pings in `telemetry_pings` with strict validation. Nothing else is sent. Documented in SELF_HOST.md and the admin console shows the state.

## D-075 Metrics, dashboards and alerts

- **Decision**: the API serves Prometheus text at `/metrics` (bearer `METRICS_TOKEN`; off in production without one), computed on scrape from Postgres over short windows: runs by status and failure ratio (15 min), time to first token p50/p95 (new `runs.first_token_at`, set at the first model token or tool call), computer start time p50/p95 (from `computer.state` events), computers by state, cost per run, DBOS queue depth, and API response counters. `infra/monitoring/` holds the Prometheus config, alert rules (run failures above 5% over 15 minutes, host memory above 85%, p95 first token above 3 s, queue backlog, API down) and a provisioned Grafana dashboard, started with the compose profile `monitoring`. Langfuse LLM traces are not built; spans and the cost ledger cover it for now.

## D-076 Self-host installer and server choice in the apps

- **Decision**: `infra/compose/docker-compose.yml` runs the whole stack on one machine: Supabase's Postgres, GoTrue, PostgREST, Realtime and Kong (images pinned to the versions the Supabase CLI uses), a one-shot `migrate` service that waits for Auth and Realtime to create their schemas and applies `supabase/migrations` once each (tracked in `casama_migrations`), the API and worker (one image, Node 26, pnpm installed directly since corepack left Node), supervisor, egress proxy, TURN relay and Caddy (one public address: `/v1`, `/hooks`, `/connect` to the API; `/auth/v1`, `/rest/v1`, `/realtime/v1` to Kong). Optional profiles: `web`, `s3`, `monitoring`, `images`. `install.sh` checks Docker, generates every secret with OpenSSL (including the Supabase anon and service JWTs and a SAML key), writes `infra/compose/.env` once (re-runs keep it and only add new keys), builds and starts, and waits for readiness; `casama selfhost init|up|down|status|logs|upgrade|backup|restore` wraps it. Empty environment values now count as unset. The apps let users enter a server address at sign-in or on the can't-connect screen (remembered; switching reconnects), and the web build uses its own origin when built with an empty `CASAMA_API_URL`. PaaS templates (Render, Railway, DigitalOcean) run the API and worker against a Supabase project; Coolify runs the full compose file.

## D-077 Casama MCP server

- **Decision**: `packages/mcp` (`casama-mcp`, stdio) exposes `list_workspaces`, `list_bots`, `ask_bot` (sends a message and polls the run until it completes, fails or waits for approval, returning the reply, tools used, cost and ids), `get_run`, `list_approvals` and `decide_approval`. It authenticates with the CLI's saved session (refreshing it through Supabase Auth) or `CASAMA_TOKEN`, and the server address from `CASAMA_API_URL` or the CLI config. Tested with a real MCP client over an in-memory transport against the test API and worker.

## D-078 Evals and load test

- **Decision**: `packages/evals` holds 30 tasks with automatic checks (reasoning, research on local pages, files, code fixes that must pass their test, output formats, approvals, prompt-injection refusal, secrets, browser forms, MCP, memory, delegation, routines); tasks needing internet, a search key or an MCP server are skipped unless enabled. Ten form the quick subset that guards pull requests touching `packages/agent`. The runner records success rate, cost, steps and time, and compares with `baseline.json` per mode and subset (fixture mode replays scripted model turns to check the harness and tools; live mode uses the default model). The load test (`apps/server/load`) creates 200 webhook bots and 100 chat bots, fires the webhooks together with k6, then opens 100 chat streams, and reads time to first token from Postgres.

## D-079 Model picker

- **Decision**: New bots pick their model from a searchable list instead of a free-text id. `GET /v1/credentials/{id}/models` asks the worker (the only process that reads Vault) for the key's live model list: OpenRouter's public catalog, the OpenAI, xAI and Anthropic model endpoints, Google's `generateContent` models, or `<base_url>/models` for OpenAI-compatible servers such as Ollama. Embedding, image, audio and batch models are dropped. Casama's short recommended list (`FEATURED_MODELS` in `@casama/domain`) comes first; if the provider can't be reached, or the worker runs on fixtures, the picker shows that list and says so. Any model id can still be typed in. Live lists are cached in the API for 10 minutes. A blank bot is named "Chief"; when a workspace has no chat-model key yet, the new-bot sheet shows the add-key form in place.

## D-080 Firebase project for official builds

- **Decision**: Official Casama apps use the `kasama-ai` Firebase project for push. Its public client identifiers live in `client/config/firebase.json` (passed with `--dart-define-from-file`), per platform: one Apple app for iOS and macOS (bundle `dev.casama.casamaApp`), one Android app, one web app. The worker reads `FCM_SERVICE_ACCOUNT` (JSON text or a file path); without it push is off and the in-app inbox still works. Firebase stays optional: self-hosters who build their own apps point both settings at their own project. A self-hosted server can't push to the official store apps, since only the `kasama-ai` key can address them; a push relay through Casama Cloud would cover that later. Opening a notification (in the inbox or from a push, which carries `notification_id`) marks it read.

## D-081 Client design system

- **Decision**: The apps share one design system, after the look of our openrc app. FlexColorScheme 8 (8.4: version 9 is built on the separate `material_ui` package and does not work with this Flutter) supplies the base Material 3 theme. On top of it: neutral surfaces in light and dark whatever the accent (the accent colors controls and selection only), hairline-bordered cards (18px), 14px input fields, pill buttons, 28px sheets, and pill tabs. Nunito (OFL, bundled) sets headlines; body text uses each platform's own font (San Francisco on Apple platforms; Apple's font license doesn't allow shipping it in this repository), with tracking tightened for it. Tokens live in `client/lib/theme` (spacing, radii, motion, semantic colors). Shared components live in `client/lib/ui`: card, grouped list, header and round header buttons, floating tab bar, adaptive sheet (a sheet on phones, a dialog on larger windows), segmented control, bot avatar, Casama mark, and a small motion kit. The motion kit runs on animation controllers rather than timers, so nothing is left running when a widget goes away. Layout: a floating pill tab bar on phones (hidden inside a chat), a rail on tablets, and on desktop a sidebar with the bot list, the chat, and a collapsible computer panel. In chat, tool steps read in plain words and consecutive steps share one card. Settings → Appearance picks light, dark or system and one of seven accents, kept on the device.

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

## D-084 Type: Fraunces, Figtree, JetBrains Mono (defaults superseded by D-087)

- **Decision**: Three bundled typefaces, all SIL OFL 1.1 (`client/assets/fonts/*-OFL.txt`), and none fetched at runtime:
  - **Fraunces** (72pt optical size, the soft cut, SemiBold and Bold) for display, headline and large title styles: page and sheet titles, greetings, Markdown headings and avatar initials. A warm serif suits the cloud mascot and sets the app apart from the sans-only AI chat apps.
  - **Figtree** (Regular to ExtraBold) for the rest of the interface and body text, bold labels included.
  - **JetBrains Mono** for code, terminal output and tool arguments.
- **Replaces** Nunito plus the platform font (D-081). `AppFonts` names the families. The text theme maps display, headline and titleLarge to Fraunces and everything else to Figtree.

## D-085 Color schemes, wallpapers, Lucide icons and the message menu

- **Decision**:
  - **Color schemes.** Settings → Color scheme replaces the accent swatches. It offers Casama's own scheme first, then every FlexColorScheme built-in. Each has a live preview. You can search by name or description, or filter by color family (worked out from each scheme's primary hue). The pick applies immediately and is kept on the device.
  - **Brand default.** The default scheme comes from the app icon: orchid plum primary, the cheeks' rose pink as secondary and the orb's periwinkle as tertiary (retuned 2026-11-12 from plum, sky blue and cyan, which read too blue for the brand). Light and dark both keep the scheme's own primary, secondary and tertiary colors. Surfaces blend lightly with the scheme instead of being fixed neutrals.
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
- **Theme presets**: a preset is scheme + fonts + wallpaper (Casama, Editorial, Ocean, Forest, Sakura, Sunset, Cosmos, Graphite). People save their current look as a theme and share it as a `casama-theme:` code (base64url JSON, versioned). Local photos stay on the device; shared codes only carry https photos. The code format is what a future theme gallery would exchange.
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
- **One-click sign-in** follows the MCP authorization spec: protected-resource discovery, then a client from dynamic registration, Casama's client metadata document (`/oauth/client.json`, needs a public https API), or an admin-registered client (`MCP_OAUTH_CLIENTS`; Google uses `GOOGLE_OAUTH_CLIENT_ID`), always with PKCE and the `resource` parameter. The vendor redirects to `/oauth/callback`. Tokens go to Vault with what is needed to refresh them, and refresh happens when a connection is loaded within two minutes of expiry. Sign-ins in progress live in `integration_oauth_flows` (service role only, 15-minute expiry, single use).
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
- **Sign-in:** OpenAI redirects only to `http://127.0.0.1:<port>/auth/callback`, so the desktop app and the CLI run a loopback listener (`casama_sdk/chatgpt_sign_in.dart`, shared by both; `casama credential chatgpt`). `POST /v1/credentials/chatgpt/start` stores a single-use flow in `integration_oauth_flows` (state, nonce, PKCE verifier) and returns the authorize URL; `POST /v1/credentials/chatgpt/complete` exchanges the code on the server, verifies the ID token against OpenAI's JWKS (issuer, audience = issued client, nonce) and writes the tokens to Vault. Tokens never reach the device. The first sign-in uses `dynamic_agent_client` with the product name; later ones reuse the issued client and send `login_hint`. One host id per server (`instance_settings.chatgpt_host_id`, `urn:uuid:`). Phones and the web point to the desktop app or the CLI.
- **Credential:** `model_credentials.provider = 'chatgpt'` with `owner_user_id`, `status` (ok, plan_usage_off, needs_reconnect), `settings.fallback_on_limit`, `oauth` (issued client id, subject, email) and `refreshed_at`. Personal: runs use it only when the run acts for its owner (the sender, the routine's creator, or a parent run's, found by walking up the run tree); otherwise it is skipped (`model.fallback` event) or the run fails with `chatgpt_plan_not_yours`. Admins and the owner can delete it; only the owner tests it or changes its settings. `DELETE /v1/credentials/{id}` (new, for every key) revokes a ChatGPT sign-in through the worker first and deletes the Vault secret. `PATCH /v1/credentials/{id}` renames or sets `fallback_on_limit`.
- **Refresh:** the worker refreshes within 5 minutes of expiry under `pg_advisory_xact_lock` per credential (refresh tokens rotate, so parallel runs reuse the new pair), honors `earliest_refresh_at`, and the hourly maintenance job refreshes plans idle for 20 days. Dead refresh tokens set `needs_reconnect` and notify the owner; network errors never touch the credential.
- **Model calls:** a hand-written Responses adapter (`gateway/chatgpt.ts`), not the AI SDK, so the request carries only what the plan route accepts: `store: false`, `stream: true`, history in `input`, system text in `instructions`, no temperature, max output tokens or previous response id. OpenAI's documented error codes map to Casama codes: a plan limit (also mid-stream) never retries and moves to the next model only when the owner turned that on; an invalid user marks the credential; 503 retries twice (1 s, 2 s). The model picker lists `/v1/models` entries with visibility "list". Plan tokens go to `usage_ledger` with `source = 'chatgpt_plan'` and cost 0.
- **Tests:** `apps/server/test/fake-openai.ts` fakes the auth server (PKCE, dynamic client, ID tokens, rotating refresh with reuse detection, revocation) and the Responses stream; `chatgpt.test.ts` covers sign-in, reconnect, consent declined, plan usage off, a run at cost 0 with the right request shape, owner-only use, plan limits, single refresh under concurrency, needs_reconnect and revocation. A live check with a real plan is left for Oliver (NEEDS).
- **Open:** the button uses a neutral icon until OpenAI's approved button artwork is added; the "Manage usage" link opens chatgpt.com settings.

## D-092 Pages are web only

- **What:** a page is the bot's self-contained HTML (with its JSON data block), never A2UI. One format serves the app, signed-out public links and headless-Chromium PDF export, so every page can be shared without a second renderer. A2UI stays for cards inside chat.
- **Viewing in the app:** no embedded WebView (the app stays fully native). Pages open in the system's in-app browser: Safari View Controller on iOS and Chrome Custom Tabs on Android (`url_launcher` `LaunchMode.inAppBrowserView`), the default browser on macOS, Windows and Linux, and a new tab on the web.
- **Private and workspace pages:** the system browser has no Casama session, so the app requests a single-use view link (60 s, bound to page and viewer); the pages origin exchanges it for a short page-scoped cookie. Public links keep their revocable token, optional expiry and `noindex`.
- **Trade-offs accepted:** pages don't inherit the user's Casama theme beyond CSS variables the bot is asked to use, and buttons on a page can't call Casama actions (no JS bridge). Actions stay in chat.

## D-093 Two-step sign-in

- **What:** authenticator-app codes (TOTP) through Supabase Auth's MFA on every platform. Settings → Two-step sign-in sets up one or more authenticator apps (QR code or setup key, then a code), lists them and removes them. After the password step, an account with an authenticator goes to a code screen (`/two-step`) before anything else. `casama login` asks for the code (or `--code`, `CASAMA_2FA_CODE`). Passkeys wait until Supabase Auth supports them.
- **Workspace requirement:** `organizations.require_mfa`, set in the same screen by owners and admins (`PATCH /v1/orgs/{id}/settings`), and reported on each workspace in `/v1/orgs`. Turning it on needs an aal2 session, so nobody locks themselves out. When it is on, `public.has_role` grants owner and admin powers only to aal2 sessions; members are unaffected and owners keep member access. Because every RLS policy and API admin check goes through `has_role`, one change covers them all. The API turns the resulting "Only owners and admins…" refusals into `mfa_required` with a clear message, and Settings tells an affected admin what to do.
- **Config:** TOTP enroll and verify are on in `supabase/config.toml` and the self-host compose file.
- **Tests:** pgTAP (`two_step_rls.test.sql`), API (`two-step.test.ts`: turning it on needs aal2; aal1 admins get `mfa_required`; aal2 works; members unaffected), widget tests for setup, removal, the workspace switch and the sign-in code screen. Real GoTrue MFA was not exercised end to end (mock-only build).

## D-094 Casama Cloud abuse controls

- **Switch:** `ABUSE_CONTROLS=auto|on|off`, on when billing is on (Casama Cloud); self-hosted servers keep it all off. The egress proxy has its own `EGRESS_ABUSE=on`.
- **Sign-up check instead of a visible CAPTCHA:** a Turnstile widget would mean web content inside the apps (no embedded web panels), so new email accounts are checked by Supabase Auth's before-user-created hook (`POST /hooks/auth/before-user-created`, Standard Webhooks signature with `AUTH_HOOK_SECRET`). The account's user metadata must carry `signup_proof`: a Firebase App Check token (verified against Google's JWKS for `APP_CHECK_PROJECT_NUMBER`; App Attest, Play Integrity, reCAPTCHA Enterprise; nothing visible) or a solved proof-of-work puzzle from `GET /v1/signup/challenge` (stateless HMAC-signed challenge, `SIGNUP_POW_DIFFICULTY` zero bits, single use). Google, Apple and SSO sign-ups pass. `/v1/config` lists the accepted proofs. The apps (puzzle in an isolate) and `casama signup` send the puzzle today; App Check tokens come once App Check is set up in Firebase. Refusals are recorded as `signup_blocked`.
- **Verified email:** on Casama Cloud a free-plan workspace starts computers only when an owner has confirmed their email (`email_unverified`).
- **Egress:** the proxy refuses outbound mail ports (25, 465, 587, 2525), common Stratum ports and a list of mining pools, and reports each hit and each rate-limit flood (once a minute per computer) to the API's `/internal/abuse`. Mining suspends the workspace at once; three floods in an hour do too. Instance owners get a notification.
- **Suspension:** `organizations.suspended_at/suspended_reason`. Suspending cancels running runs, stops (sleeps) computers and keeps data; runs fail at admission with `workspace_suspended`, sending a message answers 403, and computers refuse to start. Owner console: Suspend (with a reason) and Lift on each workspace, and an Abuse tab listing `abuse_events` (service role only). The app shows a banner in a suspended workspace.
- **Tests:** egress proxy (ports, pools, flood report), API (`abuse.test.ts`: unsigned hook, missing proof, OAuth pass, puzzle once, App Check for this project only, reports, suspension and admin actions, computer start checks), SDK puzzle solver, widget tests (suspend and lift, Abuse tab, banner).

## D-095 Least-privilege worker database role

- **What (closes D-016):** migration `20261121000001_worker_role.sql` creates `casama_worker` (no superuser, no RLS bypass). It gets data access on public tables through one explicit policy per table (`casama_worker_all`, added by `public.allow_worker(table)`), read on `vault.decrypted_secrets` plus `vault.create_secret`/`update_secret` (no delete), the `extensions` schema, four columns of `auth.users` (id, email, email_confirmed_at, created_at), CONNECT and CREATE on the database (DBOS runs `create schema if not exists dbos` at start) and ownership of the `dbos` schema. It cannot alter public tables or read passwords or other Supabase schemas.
- **Wiring:** `WORKER_DATABASE_URL` (falls back to `DATABASE_URL`). The installer generates `WORKER_DB_PASSWORD`, the compose migrate step gives the role that password, and the worker connects with it. The API keeps the server role.
- **Rule for new tables:** migrations that create a table with RLS also call `select public.allow_worker('public.<table>')`; `worker_role_rls.test.sql` fails otherwise.
- **Tests:** the test harness now runs the worker as `casama_worker`, and the full API suite passes that way; the pgTAP test checks the policies, that the role is not privileged, column-level auth access and no DDL. Not yet checked on Supabase Cloud, where granting `vault.decrypted_secrets` to a custom role should be confirmed at deploy time (NEEDS).

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
- **History:** `bot_revisions` keeps the settings before every change (name, instructions, model, autonomy, budget, computer, archived) and who made it: a person (JWT `sub`) or a bot (`casama.actor_bot`, set in the bot tool's transaction). The app's bot settings → Settings history lists changes and restores one (the current settings become a new revision).
- **Folders and archive:** `bot_folders` and `bots.folder_id`/`sort_key` group the sidebar (loose bots first). Archived bots (`archived_at`) leave the sidebar, are excluded from `GET /v1/bots` (`archived=true` lists them) and from `max_bots`, and runs refuse them (`bot_archived`). Bot settings has Folder and Archive; the bot list has Archived bots with Bring back.
- **Worker and auth:** newer Supabase doesn't let the migration role grant on `auth.users`, so the worker uses `public.worker_owner_email_verified` and `public.worker_purge_user` (security definer, worker only) instead of a column grant. The vault grants go by function name (argument lists differ between versions), and non-superuser migration roles get SET on `casama_worker` (Postgres 16+).
- **Tests:** pgTAP (`bot_management_rls.test.sql`, worker role), API and tools (`bot_management.test.ts`), widget tests (history restore, folder, archive and bring back).

## D-101 Ask for a secret in chat

- **Tool:** `secrets.request(name, service, allowed_hosts, reason)` (low risk: it only asks). Hosts must be valid names under one registrable domain (`api.stripe.com` and `files.stripe.com`, not two services); a bad call returns an error at once, without waiting. Like `computer.request_takeover`, it runs in the run loop: `secret_requests` row, run status `waiting_approval` (waiting on a person; no new run status), event `secret.requested`, push to admins and the run's sender linking to the chat, then a durable wait (24 h, woken by the API signal).
- **Answering:** `POST /v1/secrets/requests/{id}/fulfill` (`{value}`) or `…/decline`, by the run's sender or an admin; `GET /v1/secrets/requests` lists pending ones. The value goes straight into Vault and a `secrets` row limited to the requesting bot and the requested hosts. An existing secret of that name is replaced only by an admin (a member gets 409). The response, events, messages and audit log never hold the value; idempotency stores responses only.
- **Resuming:** the run gets only "Saved NAME for SERVICE. Use it as {{secret:NAME}}", or the decline or expiry answer (`secret.resolved`); its in-memory secret list and redactor are reloaded so the new value is usable and scrubbed from then on.
- **App:** a protected card in the chat (service, hosts, reason, a masked field with no suggestions, autocorrect or IME learning, Save and Decline). The value never touches the composer or drafts and is cleared after sending.
- **Tests:** pgTAP (`secret_requests_rls.test.sql`), API with a scripted model (`secret-requests.test.ts`: wait, fulfill, nothing leaks, decline, mixed hosts refused), widget tests (`secret_request_test.dart`).

## D-102 Sign-in codes for bots

- **Kind:** `secrets.kind` is `value` (default) or `totp`; `secret_requests.kind` likewise, so `secrets.request` can ask for a seed (`kind: "totp"`). A totp secret holds an `otpauth://totp/...` link or a bare base32 key, checked when saved (`invalid_totp`): time-based only, SHA-1/256/512, 6–8 digits, 10–300 s periods.
- **Codes:** bots write `{{totp:NAME}}`. `resolvePlaceholders` turns it into the current RFC 6238 code (`@casama/domain` `totpCode`, node crypto) only at execution time, only for tools that accept secrets, only on the secret's allowed hosts. `{{secret:NAME}}` on a totp secret is refused (`totp_seed_protected`), so the seed never leaves Vault; `{{totp:...}}` on a plain secret is refused too. Each code is added to the run's redactor so it is scrubbed from output.
- **App:** Secrets → Add has Key or password / Sign-in code; a sign-in code takes a pasted link or key, and phones scan the site's QR code (`mobile_scanner`, iOS and Android only; the name is suggested from the issuer). The chat's secret card does the same for `kind: totp` requests.
- **Generator:** `--enum-name-mappings=value=plain` stops an enum member named `value` from clashing with the generated enum's own `value` field (Dart `SecretKind.plain` is `"value"` on the wire).
- **Tests:** RFC 6238 vectors (`totp.test.ts`), placeholder rules (`totp-placeholders.test.ts`), API (seed validation, totp request in `secret-requests.test.ts`), widget test (sign-in code form).

## D-103 Search

- **Database:** `pg_trgm`; `messages.tsv` (a stored `to_tsvector('simple', …)` of the text parts only, via immutable `public.message_plain_text`) with a GIN index; trigram indexes on chat titles, skill, routine and ticket names. `public.search_workspace(org, q, limit)` is **security invoker**, so RLS decides what each caller sees; results never cross workspaces or bots they can't access. It returns up to 8 per kind (message, chat, memory, skill, routine, ticket) with `ts_headline` snippets (matches between « »). `websearch_to_tsquery('simple')` keeps it language-neutral; `ilike` patterns escape `%`, `_` and `\`.
- **Files:** `GET /v1/search` also searches up to 3 awake computers (`running`/`idle`, not local devices) the caller can see: one shell command for names (`find -iname`, literal pattern) and contents (`grep -rIlis -F`) under `~/workspace`, skipping `node_modules` and `.git`, 4 s each. Sleeping computers are never woken; the app says so. Pages join when they exist (Wave 2); with encryption at rest (Wave 3) search will cover names and titles only.
- **App:** Cmd/Ctrl+K and a search button in the sidebar open the search panel on desktop and web; phones get a Search tab. Results are grouped by type; a message opens its chat scrolled to it and highlighted (`ChatScreen.focusMessageId`, `?m=`), chats open the chat, memories, routines, skills and tickets open their screens, files open the file preview.
- **Tests:** pgTAP (`search_rls.test.sql`), API (`search.test.ts`: grouping, isolation, wildcards, the file command on a real folder including a quoting attack), widget tests (`search_test.dart`).

## D-104 Skills library

- **Format:** the open Agent Skills layout: a folder with `SKILL.md` (front matter with `name` and `description`, then Markdown instructions) plus optional files. `@casama/domain` parses the small YAML subset skills use (`parseSkillMd`). Skills gain `source` (manual, catalog, github, bot), `source_ref`, `category`, `updated_at` and `updated_by_bot`.
- **Files in Postgres, not object storage:** a skill's extra files go in `skill_files` (bytea; 1 MB a file, 5 MB and 60 files a skill), under the same RLS as skills. They're small, need RLS and backups, and are copied to the computer on load, so a separate object-store path added nothing; snapshots keep using the `ObjectStore`. This departs from the SPEC's "object storage" wording on purpose. `skills.load` writes them to `~/skills/<name>/` (keeping the executable bit) and tells the bot where they are; scripts only ever run on the computer.
- **Catalog:** curated, original skills ship in the repo's `skills/` folder (`catalog.json` maps each to a category): meeting-notes, weekly-report, research-brief, csv-cleanup (with `scripts/clean.py`), code-review, trip-planner. `GET /v1/skills/catalog`; `POST /v1/skills/install` installs to the workspace (admins) or one bot (its managers), enforced by RLS. Later grown to 38 skills in seven categories (work, writing, research, data, money, build, life). Twelve of those are adapted from other Apache-2.0 and MIT skills, with their license file kept in the folder: pdf, docx, xlsx, pptx and webapp-testing from anthropics/skills@2c5958ec; build-dashboard, digest, write-spec and competitive-brief from anthropics/knowledge-work-plugins@877a617b; systematic-debugging from obra/superpowers@22f0b463; doublecheck from github/awesome-copilot@eaaffd5d; teach from mattpocock/skills@4ae2317d. The computer image installs the tools those skills call (LibreOffice, pandoc, Poppler, qpdf, Tesseract, and the Python and Node libraries), because a bot is not root and cannot install them later. A `catalog.json` entry is either a category or `{ "category", "icon" }`, where `icon` is a Lucide name the app maps from a fixed list (unknown names fall back to the category's icon), and catalog items also carry `skill_md` for the detail view. Both fields are optional in the contract so a newer app works against an older server.
- **GitHub import:** `POST /v1/skills/github/preview` resolves the link's branch to a commit and returns SKILL.md and every file (text up to 100 KB) for review; `…/install` fetches exactly that commit. `GET /v1/skills/{id}/update` compares with the latest commit (SKILL.md line diff plus files added, changed and removed); `POST …/update` applies a chosen commit. Private repositories use a workspace secret `GITHUB_TOKEN` allowed for `api.github.com` and not limited to bots (the "GitHub connection" until a GitHub app connection exists). `GITHUB_API_URL` points tests at a fake.
- **Bots:** `skills.create` (saves a bot-scoped skill, source `bot`) and `skills.update` (only the bot's own skills; workspace skills are an admin's call), both medium risk. A new `approvalDetails` hook on tools adds fields to the approval card only: the full SKILL.md for create and a line diff for update.
- **`/` picker:** typing `/` in the composer lists the bot's enabled skills; picked ones show as chips and go with the message (`SendMessageRequest.skills`, stored as `{type: skill}` parts). The run appends their instructions to the message up front.
- **App:** Skills has Skill catalog (its own page at `/settings/skills/catalog`: search, category chips, sections per category, a grid of tiles with each skill's icon tinted by category, a detail sheet with the instructions, and Install that asks for the workspace or a bot; installed state comes from the installed skills), Import from GitHub (link, preview of every file, install), a source label on each skill, and Check for updates with the diff on GitHub skills.
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
- **Attributes** follow the OpenTelemetry GenAI conventions: `gen_ai.operation.name`, `gen_ai.request.model`/`response.model`, `gen_ai.provider.name`, `gen_ai.usage.input_tokens`/`output_tokens`/`cache_read.input_tokens` (when the provider reports cached tokens), `gen_ai.tool.name`/`tool.call.id`, `gen_ai.agent.id`/`name`, plus `casama.cost_usd`, `casama.failover_attempts`, `casama.tool.risk`, `casama.tool.outcome` and `error.type`. No prompt, message, argument or result text is ever put on a span (the test checks a run's spans for the user's words).
- **Langfuse** (on when `LANGFUSE_BASE_URL`, `LANGFUSE_PUBLIC_KEY` and `LANGFUSE_SECRET_KEY` are set): every model attempt, including failed ones that fell over, becomes a `generation-create` in the run's trace (same trace id) via the public ingestion API, with input and output passed through the run's redactor (secrets and model keys removed), tokens and cost. Workspaces can turn it off (`llm_tracing` in workspace settings). Sending never blocks or fails a run.
- **Timeline:** run timelines show the trace id with Copy, and Open trace when the server sets `TRACE_URL_TEMPLATE` (any viewer URL with `{trace_id}`), opened in the default browser.
- **Tests:** in-memory exporter (`run.test.ts`): run span id and status, chat spans parented to it with tokens and cost, tool span outcome and risk, no prompt text, `trace_id` stored; Langfuse generations share the trace id, contain no secret, and stop when the workspace opts out; widget tests (`trace_test.dart`).

## D-108 Edit and resend

- **Tree:** `messages.parent_message_id` (the message before it in its branch) and `conversations.head_message_id` (the newest message of the branch on screen). Existing conversations were backfilled as one straight branch. A trigger fills in the parent from the head when an insert doesn't give one (so every existing insert path keeps working), and moves the head only when the new message continues the shown branch (a reply that lands after the person switched branches doesn't pull them back). `casama.branch_root` starts a new first message.
- **Edit:** `POST /v1/conversations/{id}/messages/{message_id}/edit` (your own messages, not while a run is going) adds a sibling with the same parent, keeping the original's attachments and picked skills, makes it the head and starts a run. The run's history is its own branch: `runAgent` walks from the run's message up through parents, so the old branch never reaches the model. The reply is attached to the run's message explicitly.
- **Switching:** `public.conversation_thread` returns the shown branch with each message's place among its versions (`sibling_index`/`sibling_count`); `POST /v1/conversations/{id}/branch` shows another version by moving the head to the newest message under it (`public.branch_leaf`). Both run as the caller, under RLS.
- **App:** Edit in the message menu (long-press, or the text's context menu with a mouse) opens a sheet with the text; sending reruns from there. Edited messages show `< 2/3 >` arrows.
- **Known limit:** a conversation summary made before an edit (long chats are compacted) may still mention the other branch.
- **Drizzle:** the pull script drops the `conversations_head_message_id_fkey` metadata from the generated schema, which would otherwise make a type cycle; the database keeps the key.
- **Tests:** API with a scripted model (`branches.test.ts`: straight thread, edit forks and reruns, versions and switching back, only user messages), widget tests (`branches_test.dart`).

## D-109 Quiet hours

- **Settings:** `profiles.quiet_hours` (`{enabled, start, end}`, local "HH:MM", may cross midnight) in the person's profile timezone; `user_bot_settings` per person and bot: `default` (my quiet hours), `always` (this bot may always push) or `custom` (its own window). People manage only their own rows (RLS).
- **Delivery:** `NotificationService.notify` always writes the inbox row; during quiet hours it records `push_status = deferred` and `push_after` (the window's end) instead of pushing. The worker's minute tick (`sendDeferred`) sends due pushes and skips ones already read in the app. `@casama/domain` `quietUntil` does the timezone math (DST shifts inside a window move the end by at most an hour).
- **Urgent:** approvals from a chat or voice run are urgent (someone is waiting in the conversation) and push anyway; approvals from routines, tickets and other background runs wait. Bot phone calls (Wave 3) will use the same check.
- **App:** Settings → Quiet hours (switch, start and end); bot settings → Notifications from this bot (follow my quiet hours, always notify me, its own quiet hours).
- **Tests:** domain (`quiet-hours.test.ts`), service against Postgres (`quiet-hours.test.ts`: deferral, urgent, per-bot always, delayed send skipping read ones), pgTAP (`quiet_hours_rls.test.sql`), widget tests (`quiet_hours_test.dart`).

## D-110 Share a bot as a template

- **Format:** `casama.bot` version 1 (`docs/BOT-TEMPLATE-FORMAT.md`, `BotTemplateFile` in contracts): name, description, instructions, autonomy, a built-in mascot, the bot's own skills with files (base64), repeating routines, connections by name, and memories only when chosen. Never keys, secrets, OAuth tokens or the model choice. It's the file the community template repository accepts.
- **Export:** `GET /v1/bots/{id}/export` (anyone who can see the bot; `memories=true` only counts for people who manage it).
- **Links:** `POST /v1/bots/{id}/share` (managers) stores a snapshot in `bot_shares` with a hashed token (default 30-day expiry) and returns `<PUBLIC_APP_URL>/import/<token>`; `GET /v1/bot-shares/{token}` returns it to anyone signed in, in any workspace, for the preview. Sharing is audited.
- **Import:** `POST /v1/bots/import` with the template, a model key from the importing workspace and a model; it checks skill file limits and cron schedules, respects `max_bots`, and creates the bot (owned by the importer), its skills and files, routines (optional, in the importer's timezone) and memories (optional). Connections come back as `connections_to_add` for the person to connect themselves.
- **App:** bot settings → Share as template (include memories, Save as file, Copy link); Bots → Import a bot (a file) and `/import/<token>` links open an import screen that previews instructions, skills, routines, connections and memory count, with switches for routines and memories and the key and model (prefilled with the key's default) before importing.
- **Generator notes:** enum and array defaults and numeric literals break the Dart generator, so the template's optional lists are optional (empty when missing) and `version` is a bounded integer.
- **Tests:** API (`bot-template.test.ts`: export without secrets, memories on request, cross-workspace link preview and import with files, bad schedules and foreign keys refused), widget tests (`bot_template_test.dart`).

## D-111 Shortcuts

- **iOS and macOS:** App Intents in each Runner's `AppDelegate.swift` (no extra target or Xcode project edits): `AskBotIntent` (bot, question) and `RunRoutineIntent` (routine), with `BotEntity`/`RoutineEntity` queries and a `CasamaShortcuts` provider, so they show up in Siri, Spotlight and the Shortcuts app ("Ask Casama", "Run a routine in Casama"). They need iOS 16 / macOS 13 (`@available`); older systems simply don't offer them.
- **Data:** the app writes its bots and routines (ids and names only) to shared preferences (`flutter.casama.shortcuts`), which the intents read in-process. Intents open the app (`openAppWhenRun`) and hand a path to Flutter over the `casama/shortcuts` method channel, queued until Flutter asks for it on start: `/quick-ask?bot=…&text=…` or `/run-routine/<routine>:<bot>`.
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
- **Matching** (`@casama/domain` `action-rules.ts`): categories come from a tool's declared `category`, else from words in its name; targets are read from argument fields (`to`, `cc`, `recipients`, `amount`…). A rule with limits only applies when the call is within them (every recipient in an allowed domain, under the amount). The most specific rule wins (the bot's own over the workspace's, tool over group over category, limited over unlimited); ask or hand off wins ties. No matching rule: autonomy decides as before.
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

- **One implementation:** the API serves the `@casama/mcp` tools (D-077) at `/mcp` over Streamable HTTP (the SDK's web-standard transport, stateless, one server per request). The tools' `CasamaApi` gets a fetch that calls the API in-process, carrying the caller's identity in Hono's environment (`casamaClaims`), which outside requests can't set; the auth middleware uses it for those calls only. So every tool call goes through the same routes, RLS, approvals, action rules and budgets as the app.
- **Who:** an OAuth access token (`kmcp_…`), a workspace API key (`ksk_…`), or a normal Casama sign-in. Tokens and keys act as one person in one workspace (other workspaces are invisible to the tools) and stop working if that person leaves it. Tokens are stored hashed in `mcp_tokens`.
- **OAuth** (the MCP authorization flow): `/.well-known/oauth-protected-resource` (also announced in the 401's `WWW-Authenticate`), `/.well-known/oauth-authorization-server`, dynamic client registration at `/oauth/register` (public clients, https or localhost redirects), `/oauth/authorize` (PKCE S256 required) sends the person to the app's consent screen (`/oauth/consent/<id>`) where they pick a workspace and allow or refuse; `/oauth/token` exchanges a single-use code (5 minutes) for a one-hour access token and a rotating 60-day refresh token. Connections are audited.
- **Approvals:** `decide_approval` over MCP is refused unless the workspace turns on `mcp_decide_approvals` (Workspace settings → Connect AI apps); with a full sign-in it behaves like the app. A high-risk step still waits for approval either way.
- **App and docs:** Workspace settings → Connect AI apps shows the `/mcp` address, API keys (create, shown once, revoke; admins) and the approvals switch; `docs/MCP.md` has copy-paste configs (OAuth by URL, Cursor and Claude Code with a key, local stdio). `PUBLIC_API_URL` sets the advertised address (else the request's origin).
- **Tests:** a real MCP client over HTTP (`hosted-mcp.test.ts`: 401 challenge and metadata, registration, PKCE (a wrong verifier fails and spends the code), consent, refresh, one-workspace scope, asking a bot, a high-risk step waiting, approvals refused until allowed, API key revoked), widget tests (`mcp_test.dart`).

## D-118 Group chats

- **Data:** `conversations.kind` (direct, group) and `conversation_bots` (bot, role lead or member, position); `conversations.bot_id` stays the lead, so existing access checks and lists keep working. `messages.bot_id` records which bot wrote each reply; `runs.trigger_message_id` and `runs.hop` tie a run to the message that woke it. A person sees a group chat only if they can see every bot in it (`group_bots_visible` in the conversations policy; messages use `can_access_conversation`).
- **Waking:** `@Name` wakes that bot (longest name first, `@casama/domain` `parseMentions`); `@everyone` wakes the lead with the member list and asks for a plan that @mentions a bot per part; no mention goes to the last bot that spoke (else the lead). One user message, one run per woken bot, all in the same conversation and running in parallel.
- **Bot to bot:** a bot's reply that @mentions others starts their runs (trigger `mention`) up to 6 hops per user message; after that the chat waits for a person. Group messages are stored flat (no branches, so edit and resend stays direct-chat only).
- **Other bots are chat, not instructions:** each run sees other bots' messages as user-role text prefixed with who said it and that it's not from the owner; a group note in the persona lists the members. Each bot keeps its own memory, approvals and budget.
- **API and app:** `POST /v1/conversations` with `bot_ids` (lead first, up to 10) creates a group; `GET /v1/group-chats?org_id=`; `send` returns every started `run_ids`. The sidebar lists group chats with New group chat (pick 2 to 10 bots, the first leads), `/groups/:id` opens the chat with each reply headed by its bot, and typing `@` suggests the members and everyone.
- **Tests:** domain (`mentions.test.ts`), API with a scripted model (`group-chats.test.ts`: @everyone plan then work, @Name, last speaker, the 6-hop cap, visibility), widget tests (`group_chats_test.dart`).

## D-119 Pages

- **Data:** `pages` (bot, the person it was made for, its conversation, title, HTML up to 2 MB, a JSON data block up to 1 MB, visibility private, workspace or public, public token hash, expiry, refresh routine, version) and `page_versions` (the last 20, trimmed by a trigger). Private pages are visible to the person they were made for and the bot's managers; workspace and public pages to everyone who can see the bot (RLS). Only those people can change, share or delete a page.
- **Tools:** `pages.publish` (HTML or an HTML file on the computer; a `page_id` replaces the layout; `refresh_cron` links a routine that refreshes the data with `pages.update_data`), `pages.update_data` (data only, layout untouched), `pages.share` (high risk for public, medium otherwise; category `share`, so action rules apply), `pages.list`. Bots only touch their own pages. New pages are private.
- **Serving (D-092):** a separate origin (`createPagesApp`, `PAGES_URL`, served by the API process on `PAGES_PORT`; self-host Caddy gives it its own site or port). The served document is the bot's HTML plus a head (charset, viewport, `noindex`, theme variables `--k-bg|fg|muted|accent|surface|font` for light and dark, and the data as `<script type="application/json" id="casama-data">` with `<`, `>` and `&` escaped) and an "Updated …" line. Headers: CSP `default-src 'none'` with inline scripts and styles, `data:` images and fonts, `connect-src 'none'`, `form-action 'none'`, `frame-ancestors 'none'`, `base-uri 'none'`; `X-Robots-Tag: noindex`, `no-store`, `no-referrer`. A fragment gets a full document around it.
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

- **Format:** Agent Plugins 1.0, checked by `@casama/domain` `checkPlugin`. The checker is written from the published specification, including the rules its JSON Schemas can't express:
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
- **Secrets:** the specification has no way to declare them and forbids secrets in `env` and `headers`. A plugin declares the secrets it needs under Casama's own extension namespace (`extensions["com.casama"].secrets`): a name, a description, the server, and the environment variable or header it fills, with an optional `"Bearer {{value}}"` format. Values are stored in Vault, never in the connection's config. Updates keep them unless replaced.
- **From GitHub, pinned:** preview resolves the link's ref to a commit and fetches that folder (up to 400 files and 10 MB). Install must name the previewed commit, so what was reviewed is what gets installed. Plugins are installed per bot.
- **What install creates** (each row points at `plugins.id`, so uninstall cascades):
  - the skills (`source = plugin`, with their files);
  - the package's other files (`plugin_files`);
  - one connection per server: kind `mcp` for remote servers, the new kind `computer_mcp` for stdio servers. Both are attached to the bot.
  - Install, update and uninstall are audited.
- **Stdio servers run in the bot's computer**, so plugin code never runs on Casama's servers:
  - computerd takes the computer's plugin servers over the new `PUT /mcp-servers`, outside companion mode, and bridges them on the existing `/mcp/<key>` (D-096).
  - The supervisor passes `/computers/:ref/mcp-servers` and `/computers/:ref/mcp/:key` through, and `SandboxHandle` gains `setMcpServers` and `mcpFetch`.
  - Before the first call on a computer, the worker writes the package to `~/.casama/plugins/<name>/` (`PLUGIN_ROOT`). A `.casama-commit` marker skips unchanged packages. Data lives in `~/.casama/plugin-data/<name>/` (`PLUGIN_DATA`), which survives updates.
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

- **Importers built from public docs only** (`@casama/domain` `planAgentImport`), not from either project's code:
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
  - `POST /v1/agent-imports` takes a ZIP (unzipped with fflate; paths with `..` or absolute paths dropped; 50 MB and 3,000 files at most) or the files of a folder the desktop app picked. It returns a `casama.bot` template (D-110) plus where each item came from, the leftovers, the skipped files and the notes.
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

- **Layout** (`@casama/domain` `workspace-files.ts`): `casama.json` maps folders to bots. Each bot's routines are `<bot>/routines/<name>.md`; front matter holds `id`, `name`, `schedule` (cron), `timezone`, `trigger`, `enabled` and `notify`, and the instructions follow. Skills are normal `SKILL.md` folders plus `id` and `enabled`: `<bot>/skills/<name>/` for one bot, `workspace/skills/<name>/` for the whole workspace. Plugin skills and check-in routines are managed elsewhere and left out.
- **Import rules** (`applyWorkspaceFiles`, shared by the API and the worker):
  - Matching:
    - Folders match bots through `casama.json` (by id), else by name.
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
  - CLI: `casama files export <folder>` and `casama files import <folder> [--dry-run]`.
  - Admins only, since the files cover every bot.
- **Git sync** (`syncWorkspaceRepo`):
  - **Setup:** `org_git_sync` holds repo, branch and folder. It uses the workspace's `GITHUB_TOKEN` secret, allowed for api.github.com. This is the GitHub connection for now; secrets already have host allowlists.
  - **Algorithm:** each sync compares three versions of every file: the last synced baseline (git blob sha plus content hash), Casama's export now, and the branch now.
    - Changed only in Casama: one commit on the branch through the git data API.
    - Changed only in the repo: checked and applied. Bad files are reported in `last_error` and kept out of the baseline, so they're retried once fixed.
    - Changed on both sides: Casama keeps its version and opens a pull request carrying it on a `casama/sync-…` branch. The baseline records the standoff, so no second pull request opens; merging it makes both sides agree.
  - **When it runs:**
    - Triggers on routines, skills and skill files mark the workspace dirty, and the worker's minute tick syncs dirty workspaces and checks the rest every 10 minutes.
    - The repo's push webhook (`/hooks/git-sync/<org>`) marks it due. Its HMAC (`X-Hub-Signature-256`) is checked with a secret stored in Vault, shown once at setup.
    - Changing the repo, branch or folder resets the baseline.
- **Tests:**
  - domain (`workspace-files.test.ts`)
  - API (`workspace-files.test.ts`), with an in-memory GitHub: export, a dry run then an import with bad files reported, the first push, the webhook signature, a repo edit applied, an app edit pushed, a conflict keeping Casama's version with one pull request, a repo deletion, and a bad repo file left alone
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
  - Websites are crawled within the start address's origin, up to 50 pages by default (at most 200). The crawler follows `robots.txt` (the group for "casama", else `*`; the longest matching rule wins), sends a `CasamaBot` user agent and uses the worker's guarded fetch.
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
  - It also creates a private personal bot named Casama with the winky mascot, and a `welcome` conversation with the scripted opening.
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
  - Casama Cloud has no built-in starter model yet, so the model card shows whenever there's no key.
- **Tests:**
  - API (`welcome.test.ts`): space, bot and opening; the same chat on repeat; scripted answers with no model runs; the model, connection and invite cards; memories from the picks; key pickup and a first task run; the setup offer; the interview and "What I learned" with an unticked memory deleted; invited people refused.
  - widget (`welcome_test.dart`): landing in the chat, "Set up manually", app-side card actions.
  - The onboarding test now goes through "Set up manually".

## D-130 Google permissions

- **Casama's own Google app asks for no restricted scopes:**
  - Sign-in uses `openid`, `email` and `profile` (the Supabase defaults).
  - Gmail asks only for `gmail.send`, Calendar for `calendar.events`, and Drive for `drive.file` instead of `drive.readonly`.
  - Google sign-ins add `include_granted_scopes=true`, so adding a scope later keeps the ones already granted.
- **Inbox reading is a separate "Gmail inbox" connection** (`gmail.modify`, catalog flag `inbox`), turned on only for inbox features.
  - **On Casama Cloud** (billing on), it is offered only as Composio's managed Google sign-in (`auth: managed`), and hidden when `COMPOSIO_API_KEY` isn't set.
  - **Managed connections:** they use one Casama-owned Composio integration per workspace (`config.managed`, Composio user = the workspace) and open Composio's sign-in page.
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
  - Telegram: the secret token header. Casama generates the token and calls `setWebhook` on connect.
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
  - Each API and worker process keeps a key ring of unwrapped workspace keys in memory. It's loaded at start and reloaded on `LISTEN casama_org_keys`; triggers notify when a key or a workspace's mode changes.
- **Turning it on and off:**
  - `PUT /v1/orgs/{id}/encryption` (owners only, audited) creates and wraps the key and sets the mode to `encrypting`. New writes are sealed from then on.
  - The worker's minute sweep seals existing rows, 500 per column per pass, then sets the mode to `on`. After that it re-checks only the last hour's rows, as a backstop for any write path that was missed.
  - Turning it off sets `decrypting`; the sweep opens every row, then sets `off` and deletes the key.
  - A trigger stops app sessions from changing the mode directly, so it only changes through the API, after the key exists.
- **Rotation:** `POST /v1/orgs/{id}/encryption/rotate` rewraps the data key with the server's current key. Rows aren't rewritten.
  - To change the server key, set the new key in `CONTENT_ENCRYPTION_KEY` and the old one in `CONTENT_ENCRYPTION_KEY_PREVIOUS`, and restart. The worker's hourly maintenance rewraps every data key still on the old key (`rewrapAllKeys`, wired up in the 2026-11 audit). After an hour, drop the old key.
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
  - **Supermemory (v3):** each memory is a document tagged `casama_bot_<bot>`, with kind, pinned and importance in its metadata. Recall uses `/v3/search` with the tag; listing uses `/v3/documents/list`; edits are `PATCH`; deletes are `DELETE`, and bulk delete goes by tag.
  - **Honcho (v2):**
    - **Layout:** each bot has a session `casama-<bot>` in the workspace's Honcho workspace (default `casama-<org>`), and each memory is a message from the bot's peer `bot-<bot>`, with kind, pinned and importance in its metadata.
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
  - **The workspace's own key:** saved in Settings → Model keys (provider `treg`). Treg charges the workspace's own account directly, with no Casama markup. Each call is still recorded in `usage_ledger` (`kind = data_calls`, `billable = false`) with the provider's cost, endpoint and call id, so it shows in usage.
  - **Casama Cloud resale:** uses Casama's key (`TREG_API_KEY`) only when `TREG_RESALE=on`, which stays off until there's a written agreement with Treg (SPEC). Calls are then `billable`, at the provider's cost plus 20% (`DATA_MARKUP`), and settle into credits like other usage. A workspace's own key always wins.
- **Tests:**
  - API (`paid-data.test.ts`), with a fake Treg and a scripted model:
    - A default-autonomy bot asks first, with the price on the card, and nothing is called before approval.
    - After approval, the call uses the workspace's key with the right ceiling and query, and is recorded unbilled.
  - Tools:
    - Resale prices and charges include the 20% and are billable.
    - Insufficient balance is explained.
    - With no key, the tool says to add one.

## D-139 More sandbox providers

- **The pattern:** every hosted provider is a `HostedControlPlane` (`packages/sandbox/src/hosted-more.ts`). It starts Casama's own computer image with computerd inside, finds it again by the computer's ref, deletes it, and says how to reach computerd's port. `HostedProvider` then supplies the rest, as on E2B and Daytona (D-057): exec, files, checkpoints, sleep to Casama's object store and resume, and live view.
- **Testing:** each provider passes the shared `SandboxProvider` contract suite (`hosted.test.ts`, 50 tests). It runs against a local stand-in (`testing-hosted.ts`) that speaks the provider's API and runs the real computer image in Docker.
- **API shapes:** come from each provider's public docs; nothing was run against a real account.
- **Built:**
  - **Novita Agent Sandbox:** E2B-compatible. It reuses the E2B control plane on `api.sandbox.novita.ai`, with port URLs on `sandbox.novita.ai`, from templates built from the image.
  - **Kubernetes:** one Pod per computer (labels `app=casama-computer`, `casama_ref`), created through the core API.
    - **Reaching it:** through the API server's pod proxy (`/pods/<name>:7070/proxy`) with the service account token, or by pod IP when the supervisor runs in the cluster.
    - **The token clash:** the proxy needs `Authorization` for itself, so the computerd client sends computerd's token in `X-Computerd-Token` whenever the route already uses `Authorization`, and computerd accepts either header.
    - **Options:** an optional image pull secret and runtime class (gVisor or Kata, say). Private CAs work through `K8S_CA_FILE`.
  - **Incus:** a container from the computer image pulled from an OCI registry (`source.protocol = oci`), with environment variables as `environment.*`, the ref in `user.casama_ref`, and asynchronous operations waited on.
    - **Reaching it:** on the instance's global IPv4 address.
    - **Auth:** a bearer token, or a client certificate through `tlsFetch` (undici, added to the sandbox package).
  - **Boat:** a VM per computer. Boat doesn't run OCI images, so the setup script runs the computer image with Docker inside the VM.
    - **Ports:** hosted publicly through `/sandboxes/{id}/host`. computerd still checks its own per-computer token on every call. Boat's private-port token only goes in a query string, which the computerd client can't carry.
  - **Railway:** a service per computer in one project and environment (GraphQL), deployed from the image, with a Railway domain per port Casama uses. Found again by service name, since Railway has no labels.
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
- **Across Casama servers:** this is the same protocol linked agents will use.
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
  - The `call_deny_list` of prefixes (Casama Cloud keeps one; self-hosters can add their own).
  - A daily cap per workspace (default 10).
  - Business numbers by default: Twilio Lookup's caller-name type. A number Lookup calls `CONSUMER` is refused unless admins allow personal numbers. Unknown types are allowed, since Lookup's caller name mostly covers US numbers.
  - Recording stays off.
- **Usage:** each completed call adds `phone_minutes` (rounded up) to the usage ledger with Twilio's approximate rate. It's not billable, since the workspace's own Twilio account pays. Casama-provided telephony and its credit pricing wait for the legal review the spec requires before a hosted launch.
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
  - Casama-issued cards on Cloud wait for the legal review the spec requires before a hosted launch.
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
  - A bot's manager creates an invite (`POST /v1/bots/{id}/links`). It's a `casama-link:` string carrying the server's address, the link id, a one-time code (only its hash is kept) and the bot's name. It works once, for 7 days.
  - The trusted contact accepts it with one of their bots (`POST /v1/links/accept`). Inviting and accepting are the two approvals.
  - Either side revokes (`DELETE /v1/links/{id}`), and the link ends for both.
- **On the same server:** a link is two `bot_links` rows pointing at each other.
- **Across Casama servers:**
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
  - Settings → Wake word: a phrase (default "hey casama") and the bot to call. Hearing the phrase opens a live call with that bot. It listens while the app is open.
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
  - Casama's Supabase sign-up hook enforces it for every sign-in method, Google included, and refuses others with "limited to approved email addresses".
  - Compose now wires the hook (`SIGNUP_HOOK_ENABLED`, `AUTH_HOOK_SECRET`, sent to the auth service and the API). An allowlist without the hook secret refuses sign-ups rather than allowing everyone.
- **Cloudflare AI Gateway:**
  - With `AI_GATEWAY_URL` (`https://gateway.ai.cloudflare.com/v1/<account>/<gateway>`), model calls whose credential has no base URL of its own go through the gateway's provider endpoint, for caching, logs and rate limits. The endpoints are: `openai`, `anthropic/v1`, `google-ai-studio/v1beta`, `grok/v1`, `openrouter/v1`.
  - `AI_GATEWAY_TOKEN` is sent as `cf-aig-authorization` for authenticated gateways.
  - `AI_GATEWAY_PROVIDERS` limits which providers use it.
  - It's applied in `CredentialResolver`, so every model path picks it up. Paths follow Cloudflare's public docs.
- **Secret store:**
  - **The interface:** `SecretStore` (`packages/agent/src/secret-store.ts`) for bots' named secrets (`{{secret:NAME}}`). Supabase Vault is the default; the Infisical adapter uses the workspace's own project with a universal-auth machine identity.
  - **Infisical calls:** `/api/v1/auth/universal-auth/login`, then `/api/v3/secrets/raw` to list, create, update and delete in the project, environment and path. Built from Infisical's public API docs; tested against a fake.
  - **What Casama keeps:** each secret's name, kind, allowed hosts and bots (`secrets.store` says where the value is). Values are read from Infisical when a bot uses them.
  - **Settings:** admins set it up in workspace settings → Where secrets are kept (`PUT /v1/orgs/{id}/secret-store`, checked before saving, audited).
  - **Moving secrets:** `move_existing` moves current Vault secrets into Infisical; switching back to Vault copies them back first.
  - **What it doesn't cover:** the rest of Casama's own credentials (model keys, integration tokens, channel secrets and so on) stay in Vault. Moving those is a separate, larger change.
- **Tests:**
  - API (`ops-extras.test.ts`):
    - The allowlist admits listed emails and domains (including Google sign-ins) and refuses others.
    - Gateway URLs and the auth header, an own base URL winning, and the provider filter.
    - Infisical: a bad identity refused, existing secrets moved (Vault row cleared), new secrets written to Infisical, bots reading values from it, and switching back to Vault restoring the values.
  - widget (`secret_store_test.dart`).

## D-146 Audit-log forwarding

- **What it is:** an enterprise feature (`ee/`, license feature `audit_forwarding`). Admins add forwarders per workspace (`/v1/orgs/{id}/audit-forwarders`, audited). Each forwarder streams that workspace's `audit_log` rows to one destination.
- **Destinations:**
  - **Signed webhook:** JSON `{forwarder_id, events}`, with `X-Casama-Signature: t=<unix>,v1=<hex HMAC-SHA256 of "t.body">` and a batch id header.
  - **OTLP/HTTP logs endpoint:** JSON to `<url>/v1/logs`. Each row becomes a log record (body = action; attributes = id, actor, target, metadata) under `service.name=casama`, scope `casama.audit`. Optional headers (an auth token, say) are stored as a JSON secret.
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

## D-147 Encrypted backups, the Helm chart, and a one-click local server

- **Encrypted backups (`casama selfhost backup`):**
  - `--encrypt` encrypts each file in the finished backup folder with [age](https://age-encryption.org) to one or more public keys (`--recipient`, repeatable, or `CASAMA_BACKUP_RECIPIENTS`, comma-separated; age1… or ssh keys). Each file becomes `<name>.age` and the plaintext is removed.
  - age is used as an external binary, not reimplemented, so the format is standard and the files open with any age tool. The CLI says how to install it when it's missing.
  - `restore --identity <key file>` decrypts into a temporary folder and restores from there.
  - Retention: `--keep N` keeps the newest N backups, `--keep-days D` drops ones older than D days. With both, a backup goes only when it's outside both limits. Only the timestamp folders the CLI itself writes are touched.
- **Compose fix:** the content-encryption keys (D-136), the sign-up allowlist and the auth hook secret (D-145) moved into the shared environment block, because the API needs them as well as the worker.
- **Helm chart (`infra/helm/casama`):**
  - For self-hosters on Kubernetes. It runs the API, worker, supervisor and (optionally) the web app. It does not run Postgres or Supabase: you point it at a database and a Supabase project (hosted, or the Supabase chart).
  - Migrations run as a pre-install and pre-upgrade Job. The migration files are copied out of the server image, so the chart and the image can't drift apart.
  - Generated secrets (the computer and service tokens) are kept across upgrades: a value you set wins, then the existing Secret (looked up), then a new random one. The Secret is kept on uninstall.
  - The supervisor uses the Kubernetes sandbox provider (D-139) in its own namespace, with a Role limited to pods and pod proxying there.
  - `scripts/check-helm.sh` lints and renders the chart with the Helm Docker image, so nothing is installed on the machine.
- **Supervisor default provider:** `DEFAULT_PROVIDER` (for example `kubernetes`) picks the provider for new computers. Docker is only set up when it's the default, so a cluster install needs no Docker socket. The hosted image default now points at the published image name.
- **One-click local server (desktop app):**
  - On macOS, Linux and Windows, the sign-in screen offers "Run Casama on this computer".
  - It checks that Docker and Compose v2 are running (and says what to do when they're not), downloads the self-host bundle (`CASAMA_SELFHOST_BUNDLE` at build time) into the app's support folder once, runs `install.sh --local --http-port 8080`, shows the installer's latest lines, waits for `/readyz`, saves `http://localhost:8080` as the server and reconnects.
  - If a server already answers there, it just reconnects. Re-running the installer keeps the existing `.env`.
- **Tests:**
  - CLI (`backups_test.dart`, with a fake age): encrypting every file to the recipients and decrypting back; a missing recipient refused and a missing age explained; retention by count and by age that leaves other folders alone.
  - Supervisor: the provider tests pass with the new main-provider shape.
  - Helm: lint plus a full render.
  - App (`local_server_test.dart`): the whole flow with a fake process runner and HTTP (Docker check, bundle unpacked, installer flags, ready); Docker missing; a server already running; a failed installer; the sheet saving the address and reconnecting.

## D-148 Team computer folders and the warm pool

- **Team computer folders:**
  - On a team computer each bot works in `~/workspace/bots/<folder>`, and `~/workspace/shared` holds what the bots share. Both are created on the bot's first file or command.
  - The folder name comes from the bot's name the first time it's needed ("Research Bot" → `research-bot`, then `-2`, `-3` on clashes). It's kept on the bot (`bots.team_folder`, unique per workspace), so a rename doesn't move its files.
  - The worker wraps the computer handle for team computers. Commands start in the bot's folder, and relative paths for files and searches resolve inside it. Paths starting with `shared/` or `bots/` stay relative to the workspace, so every bot reaches the shared folder the same way. Absolute and `~` paths are left alone.
  - The handle reports where a path really points (`resolvePath`), so saved files and screenshots link to the right place in the app.
  - The system prompt tells the bot its folder, the shared folder, and to leave other bots' folders alone. It's a convention, not a wall: the bots share one Linux user, and isolation between workspaces is unchanged (one team computer per workspace).
- **Desktop cap:**
  - A team computer has one screen, so `computers.max_desktops` (1 to 10, default 1, team computers only) limits how many bots use desktop tools at the same time.
  - The first desktop tool call in a run takes a lease, and later calls renew it (2 minutes). The lease is released when the run ends.
  - When the cap is reached, the tool fails with `desktop_busy`, naming the bots using it, and the bot carries on with the shell, files and browser. Claims lock the computer row, so two bots can't take the last place together.
  - Admins set the cap from the team computer's menu ("Desktop users at once") or with `PATCH /v1/computers/{id}`.
- **Warm pool (supersedes D-033's deferral):**
  - `WARM_POOL_SIZE` on the supervisor keeps that many headless computers started and unassigned (Docker provider; off by default).
  - A new computer with the default size and no extra environment claims one: its container is renamed to the computer's name and the provider remembers the alias. Desktop and custom-size computers always start cold.
  - The member keeps the network, volume, computerd token and egress identity it was created with. They're derived from its pool ref, which is stored in a container label, so the alias survives a supervisor restart (the first lookup reads it back).
  - Saved files are restored after the claim, as with a cold start. A stopped member is replaced, and the pool refills after each claim and every minute.
  - Pool members carry no workspace label; nothing reads it.
- **Tests:**
  - Agent (`team-computer.test.ts`): folder names; path and working-directory scoping, including `shared/`, other bots' folders and absolute paths.
  - API (`team-computer.test.ts`, through a real supervisor app over a fake computer):
    - The prompt names the folder, a saved file lands in and links to the bot's folder, and `shared/` resolves from the workspace.
    - The folder name is kept across a rename, and a clashing name gets `-2`.
    - A second bot is refused the desktop while another holds it. Raising the cap to 2 lets it in, and its lease goes when its run ends.
    - The cap is refused on a private computer.
  - pgTAP: the default and limits, folder name format, and members versus outsiders on leases.
  - Docker (`warm-pool.test.ts`, real containers): a new computer claims the started member in well under 5 seconds and runs normally (shell, egress, files). It sleeps and restores through the member's own credentials, `list` shows the computer and not the pool ref, and the pool refills. A custom-size computer leaves the pool alone.
  - App: setting the cap from the team computer's menu.

## D-149 Device connections

- **Owner-only data, not workspace data:**
  - New tables:
    - `device_sources`: a person's devices, with the kinds each shares and per-kind settings.
    - `device_readings`: summaries, keyed by an `external_id` so a re-upload replaces the old one.
    - `device_grants`: which bot may read which kind for that person.
    - `device_requests`: fresh reads and writes waiting for a device.
  - Every table keys on the person (`user_id`), not on a workspace. Row-level security shows rows only to their owner, not even to workspace admins.
  - Readings and grants are written only through the API. The API checks that the kind is on, and that the person can use the bot (D-131), before granting.
- **Bots read through `device.read(kind, from, to)`:**
  - It works only in runs acting for that person (the D-091 rule, via `actingUserOf`), and only with a grant for this bot and kind.
  - Without a grant it fails with `no_device_access` and points the bot at `device.request_access`. That tool emits `device.access_requested`, and the app shows a one-tap Allow / Not now card. The bot carries on meanwhile.
  - If the device was seen in the last 15 minutes, the tool first inserts a read request and waits up to 10 seconds. A trigger broadcasts the request on the person's private realtime topic, and the app collects and uploads with the request id. A "live only" kind (retention 0) is answered without being stored.
  - The result carries summaries with their age, wrapped as untrusted (calendar titles come from other people). A `device.data_used` event records the kind, count, range and devices, so the timeline shows exactly what reached the model.
  - Health results carry the "not medical advice" rule.
- **Private models:** a kind can be marked "private models only". The tool then refuses unless every model in the bot's policy (primary, fallbacks, cheap) uses a key whose base URL is on this machine or a private network (localhost, RFC 1918, CGNAT, `.local`, `.internal`).
- **Writes:**
  - `device.calendar.create` and `device.reminders.create` are medium-risk with `confirm`, so they ask first by default and action rules can allow them.
  - They queue a request on the most recently seen device and wait 20 seconds. If the device doesn't answer in time, the bot is told it will happen when the device is next online.
- **Retention:**
  - Defaults are a year for daily summaries and 90 days for places, photos and notifications. A person can shorten it per kind (7, 30, 90 days, or live only).
  - The worker's minute tick deletes expired readings and stale requests.
  - Turning a kind off deletes its readings. Forgetting a device deletes everything it shared.
  - Privacy export includes devices, readings and grants. An account deletion request removes device data right away.
- **App:**
  - Settings → Device connections offers the kinds this platform supports, each with a switch. The system prompt appears only when a kind is turned on. Each kind has its keep-for setting, the private-model switch and the bots allowed to read it (tap × to revoke). Other devices can be forgotten from the same screen.
  - The sync service answers requests as they arrive on the realtime topic, and refreshes on launch and resume. The notifications stream and device requests now share one subscription to the topic, because joining a topic twice replaces the first join.
  - Collectors: calendar (iOS, Android, `device_calendar`) and contacts (iOS, Android, macOS, `flutter_contacts`).
  - Calendar summaries are one per local day, from a day back to 30 days ahead (up to 100 events a day). Contacts are names, phones and emails, in chunks of 200.
  - Calendar writes go to the default writable calendar.
- **Not in this step:**
  - The remaining collectors and background refresh come with health data (D-150) and device triggers (D-151): places, photos, health, Android notifications, and WorkManager or background tasks.
  - Reminders have no Flutter plugin. The server and tools support them, but the app doesn't collect them yet; this is listed for Oliver.
  - Desktop calendar and activity come with desktop context (D-152).
- **Tests:**
  - API (`device-data.test.ts`, fixture model):
    - Registering and uploading, with re-uploads replacing. Kinds that are off are refused, and other people see nothing.
    - No access leads to the card event. With a grant, a fresh read is answered by the "phone" while the run waits, and the reply cites it.
    - A teammate using the same bot gets nothing.
    - A calendar write goes through approval and the device, and only the owner can answer it.
    - Turning calendar off deletes its data, and then `device_kind_off`.
    - Grants only for usable bots; revoking; retention.
  - pgTAP: owner-only rows; grants and readings can't be written directly.
  - App: day grouping and contact chunks; the permission-first switch; answering reads and writes and refusing unshared kinds; the settings screen (on, keep for, revoke); the chat card.

## D-150 Health data

- **Summaries only, by schema:**
  - Health uploads are a day summary or a workout summary:
    - Day: sleep start, end, minutes and stage minutes, steps, active energy, workout count, resting heart rate, heart-rate variability and weight.
    - Workout: activity, start, end, minutes, energy, distance and average heart rate.
  - Both are strict zod schemas in contracts, and the API refuses anything else (`bad_health_summary`). Raw samples, such as heart-rate series or sleep segments, can't reach the server, so they can't reach a model either.
  - The app reduces Apple Health and Health Connect data to these summaries on the device (`healthSummaries`). Sleep counts for the morning it ends, and it uses stage minutes when the source has them, else asleep time, else the session minus awake time. HRV is SDNN on iOS and RMSSD on Android.
- **Sensitive extras:**
  - Cycle tracking, blood glucose and blood pressure are separate switches on the Health kind (`extras`), off by default.
  - Their system permissions are asked only when switched on. The server drops any extra the person didn't turn on, whatever the device sends.
- **Trends without a model:** `device.read health` adds `vs_usual` to each day: sleep, steps, active energy, resting heart rate and HRV against the person's own previous 30 days (at least 5 earlier days). It uses neutral words only: "lower than your usual", "about your usual", "higher than your usual". Health results carry the "not medical advice" rule (D-149).
- **Encryption at rest:**
  - Every device reading is sealed with the content key (D-136) of the oldest workspace the person owns that has encryption on, when there is one. Live-only results waiting on a run are sealed too.
  - Reads decrypt transparently.
  - `HEALTH_REQUIRES_ENCRYPTION` defaults to `auto`, which means required when billing is on (Casama Cloud). There, health uploads without such a workspace are refused with `health_needs_encryption` instead of stored in the clear. Self-hosted servers keep the data on their own machine either way.
- **App:**
  - Health appears in Device connections on iOS and Android, with the extras switches and the "not medical advice" note.
  - Uploads cover the last 7 days on launch and resume, so a missed morning catches up and the baseline fills in. Background delivery comes with device triggers (D-151).
  - Platform setup:
    - iOS: HealthKit entitlement and purpose strings, read-only.
    - Android: Health Connect read permissions, the permissions-rationale intent, the Android 14 permission-usage alias, the Health Connect package query, and `MainActivity` as a `FlutterFragmentActivity` (the permission screen needs it).
- **Welcome chat:** the "Health and habits" pick: an intro that says it isn't a doctor, a first task ("What habit would you like to build?") and the personal-assistant starter. For health and errands picks, a phone-connections card ("Choose what to share") opens Device connections.
- **Tests:**
  - API (`health-data.test.ts`, with encryption required):
    - Refused until encryption is on, then stored sealed and read back.
    - Raw samples and unknown summary types refused.
    - An extra dropped until it's turned on.
    - A bot reading last night's sleep gets "lower than your usual" from summaries alone.
  - Agent: trend rules (thresholds, the 30-day window, enough history, later days never counting) and private model URLs.
  - App: day and workout summaries (sleep attribution, stages, sums and averages, extras only when on).
  - The wake-up brief that cites last night's sleep is tested with the wake-up trigger (D-151).

## D-151 Device triggers

- **The trigger:**
  - Routines take `trigger: "device"` with `{event, place?, app?, minutes_before?}`. Events are wake, arrive, leave, leave_now, workout_ended, notification, focus_on and focus_off.
  - A device routine fires only for events from its creator's own devices. The data is personal (D-149), so a teammate's routine never sees another person's events.
  - Bots create them with `routines.create(on_device_event)`. The routine's creator is the person the run acts for.
  - Arrive and leave need a place; notification needs an app.
- **Reporting events:**
  - `POST /v1/device-sources/{key}/events`. Each event carries a device-side id. `device_event_log` remembers ids for 30 days, so a retried upload never starts a routine twice.
  - The API creates the runs and starts them at once (no polling), which is well inside the 2-minute target. The event reaches the run as untrusted "device event" context.
- **No GPS trail:**
  - Named places are the only coordinates kept: `device_places`, up to 20 per person (the iOS region limit), saved through the API.
  - Devices report only the place name and a time. A visit is stored as `{place, arrived_at, left_at}` (leave closes the latest open visit), and only when Places is on and not "live only".
- **Notifications:** only from apps the person picked (`kinds.notifications.apps`). The server drops anything else, even if a device sends it. One-time codes are masked on the device and again on the server before storing or passing to a run.
- **Wake-up and workouts come from health:**
  - A day summary covering today with a sleep end means a wake-up, once per day per device. A workout summary that ended in the last 6 hours means workout_ended, so a backfill doesn't fire old ones.
  - A wake-up also runs the person's check-in briefs (D-114) that haven't run in the last 14 hours. The scheduled brief time becomes the fallback: `claimDueRoutines` skips a brief that already ran on wake-up.
- **Leave now:**
  - Each minute, for each leave-now routine, the worker finds the creator's next calendar event with a location in the next 3 hours.
  - It asks an online device with Places on where the person is: a `locate` request, answered once.
  - It gets the travel time on the workspace's own maps key: Google Maps Distance Matrix with traffic, or Mapbox geocoding plus driving-traffic directions (new providers `google_maps` and `mapbox` in Model keys).
  - It fires once travel time plus the buffer (default 5 minutes) reaches the start. The location is cleared as soon as it's used, and `locate` requests are deleted after 10 minutes.
- **App:**
  - Places (iOS, Android) turns on location ("While using", then "Always" for arrive and leave with the app closed). It registers geofences named `place:<name>` with `native_geofence`.
  - The geofence callback runs even with the app terminated. It queues the event and tries to send it within the OS's time limit by bringing up a background backend (stored server address and Supabase session). Anything unsent goes on the next launch or resume.
  - Settings shows the named places, with "Add where I am now". The "where am I" answer uses `geolocator`.
  - Notifications (Android) uses the notification listener, with a watched-apps list in Settings. Codes are masked before anything is queued.
  - iOS registers plugins for background geofence launches in `AppDelegate`. Purpose strings, Android permissions, geofence receivers and the notification listener service are declared.
- **Not in this step (server-ready, collectors pending):**
  - Focus and Do Not Disturb changes, and Android's first unlock as a wake-up signal. Both need native code (iOS Focus status needs its capability; Android needs a broadcast receiver and the interruption-filter callback). Listed for Oliver.
  - The notification listener only hears notifications while the app's process is alive.
  - Every collector still needs a check on real phones.
- **Tests:**
  - API (`device-triggers.test.ts`):
    - Named places are owner-only and capped at 20.
    - Arriving at Home starts the owner's routine at once, with the event text. It doesn't start the Work routine or a teammate's Home routine, and a retry doesn't fire twice.
    - The visit is stored as times only, with no coordinates.
    - A watched app's notification fires with the code masked, in the run and in storage. Unpicked apps are dropped.
    - A health upload with last night's sleep runs the wake routine and the brief, which reads health and cites the sleep. A second upload doesn't run them again, and the scheduled brief skips.
    - Leave-now asks for the location, then fires at travel (with traffic) plus buffer and not before, with the right maps request. The location is cleared afterwards, and it fires only once.
  - pgTAP: places and the event log are owner-only and written only through the API.
  - App: geofence-to-event mapping, code masking, places watching, notification filtering and masking, the locate answer, and Places off.

## D-152 Desktop context

- **Quick ask carries context, read only when the hotkey is pressed:**
  - Before Casama's window comes forward, the desktop app reads the front app and window title, the selected text and the browser tab:
    - macOS: System Events, the Accessibility attribute `AXSelectedText` through JXA, and Apple Events to Chrome, Arc, Brave, Edge, Vivaldi, Opera or Safari for the tab.
    - Windows: the foreground window through user32, plus UI Automation `TextPattern` for the selection.
    - Linux: `xdotool` and the primary selection.
  - Each part is a chip the person can switch off before sending. The kept parts go after their text as "From: app — window / Browser tab / Selected text".
  - A screenshot is taken only when they tap "Add a screenshot". Casama's own window steps aside for it, and the image is uploaded to the bot's computer like a chat attachment.
  - Missing tools or permissions mean less context, never an error. The context is used once.
  - macOS has an Apple Events purpose string and the automation entitlement. Selection and window titles need Accessibility permission.
- **File search on the person's own computer:**
  - `desktop.files.search(query)` works only when the bot's computer is that person's local device (D-066, owner-only as before). It searches only inside the folders they allowed (`local_devices.allowed_roots`):
    - macOS: Spotlight (`mdfind -onlyin`).
    - Windows: the Windows Search index (`SystemIndex` scoped to each folder).
    - Linux: `locate`, falling back to `find`.
  - Results are filtered to the allowed folders again on the server before the model sees them.
- **Folder watchers are triggers:**
  - Device routines take `event: "file_added"` with `folder` (the watched folder's name) and an optional `pattern` (`*.pdf`).
  - The desktop app watches folders the person picks (Settings → Device connections → Watched folders). It waits until a new file stops growing, skips partial downloads and hidden files, and reports only the folder name and file name.
  - The run is told the file is on the person's computer, so a bot working there can read it.
- **Activity recap (off by default):**
  - The Activity kind on a desktop samples the front app and window title every 30 seconds (never the selection, screenshots or keystrokes). It keeps them in hourly buckets on the computer and uploads one summary per finished hour: minutes per app, top three window titles.
  - A strict server schema (`ActivitySummary`) refuses anything else.
  - Bots read it with `device.read activity` for end-of-day recaps and time tracking, with the same grants, retention and private-model option as other kinds.
- **Not in this step:**
  - macOS Calendar and Reminders need a native EventKit channel; macOS Contacts works (D-149).
  - The web app's share target and on-request "show my screen" snapshot.
  - The Windows browser tab.
  - All listed for Oliver.
- **Tests:**
  - API (`desktop-context.test.ts`):
    - A PDF dropped in Downloads starts the "file it" routine with the file name. A JPEG, another folder and a missing name don't.
    - Pattern matching.
    - File search is refused off a personal computer. On it, it runs Spotlight inside the allowed folder only and drops paths outside it.
  - Agent: each platform's search command, with quoting that can't be broken out of.
  - App:
    - Mac and Linux context reading, including missing tools.
    - The context block keeping only the switched-on parts.
    - Partial-download filtering.
    - Hourly activity summaries uploaded once the hour ends.
    - Quick ask with hotkey context: chips, leaving the window out, and the sent text.

## D-153 Attention rules

- **Every proactive message has an urgency (low, normal or urgent):**
  - Proactive messages are check-in briefs, suggestions and routine results, including triggered routines.
  - `NotificationService.notify` takes `proactive: {urgency, why, hold}` and stores the urgency and any hold reason on the notification.
- **Urgent:** pushes now. It skips quiet hours, as before.
- **Normal:**
  - Pushes, unless the person is busy:
    - **Focus:** the latest focus event from their devices in the last 12 hours is "on".
    - **Driving:** the latest driving event in the last 3 hours is "on". Devices can report `driving_on` and `driving_off`; the collectors are listed for Oliver.
    - **Meeting:** a timed event on the calendar they share from their devices is happening now.
    - **Daily cap:** the bot has already sent 5 non-urgent pushes in the last 24 hours.
  - A held message is stored in the inbox with `push_status = held` and no push. Quiet hours still defer the pushes that do go.
  - Suggestions with normal urgency used to wait for the For you feed. They now push under these rules.
- **Low:** never pushes. It's held for the brief.
- **The next brief carries them:**
  - When a brief run is created (on schedule or on wake-up, D-151), the held messages from the last 36 hours are added to its instructions as "These waited for this brief", each with the reason it waited. They're then marked as bundled.
  - Briefs aren't held themselves, since they're the bundle.
- **"Why am I seeing this?":**
  - Each proactive message records `why: {rule, data}`. The rule is the routine with its trigger in words ("when you arrive at Home"), "Your morning brief (check-ins)" or "A suggestion from <bot> during a check-in scan". The data is the device kinds the run's model saw (from `device.data_used`, D-149).
  - The inbox shows an info button on these. Its sheet shows the rule, the data, the urgency and why it waited, plus "Less like this".
  - "Less like this" (`POST /v1/notifications/{id}/less-like-this`, the owner only) saves a pinned preference memory for that bot ("send these only when they really matter, or fold them into the brief").
- **Tests:**
  - API (`attention.test.ts`):
    - During a calendar meeting a normal message waits (reason meeting, with its why), an urgent one pushes, and a low one waits.
    - Focus holds messages until focus is turned off.
    - The sixth normal push from one bot waits, while another bot keeps its own count.
    - A normal suggestion during a meeting doesn't push and shows up in the next brief's instructions with "you were in a meeting". Nothing stays held afterwards.
    - "Less like this" saves a pinned preference, and only the owner can send it.
  - App: the why sheet (rule, data, why it waited) and "Less like this".

## D-154 Audit fixes (November 2026)

The full audit is in `docs/AUDIT-2026-11.md`. These are the decisions it made:

- **Personal data:**
  - **Linked bots' requests act for nobody** (`trigger = 'link'`, D-143). The run is recorded under the owner, but `actingUserOf` and the run loader return no acting person for it or its sub-runs, so device data, personal logins and personal computers stay out of reach. The peer's text arrives wrapped as untrusted, and `links.ask` answers come back wrapped too.
  - **Conversations become private when personal device data enters them.** `device.read` marks the conversation `private`. From then on its messages, run events and live stream are only for the person who started it (`conversations_select`, `can_access_conversation`, `run_visible`, `can_access_run`, and the API's run check). Team chats without personal data stay shared, as before.
  - **Deleting a conversation** is for its starter or the bot's managers.
  - **Memory extraction skips runs whose model saw device data**, because a bot's memory is shared by everyone who uses it (D-091).
  - **Replays stay shared** with the bot's users. A teach recording is private, but saving it as a replay is the owner's explicit choice to share it, and its secrets are placeholders. A reviewer's suggestion to restrict them was declined.
  - **"Less like this"** (D-153) saves a generic, unpinned preference (the kind and title only, not the why, which names places and apps).
  - **A brief bundles only its own workspace's held messages** (D-153).
  - **Device answers** (`locate`, live reads) are sealed and size-limited like readings.
- **Inbound and outbound:**
  - **Message routines without their own sender filter** only hear the channel's allowed senders (D-134). `sender: "*"` explicitly accepts anyone.
  - **Outbound calls from the API** (password managers, Infisical, invites, memory backends) go through the SSRF-guarded fetch, as the worker's already did. `OUTBOUND_ALLOW_CIDRS` lets both reach services on a LAN.
  - **SSO domains must be proven** with a DNS TXT record `casama-verification=<code>` tied to the workspace (code from `GET /v1/orgs/{id}/sso/verification`). A domain another workspace already uses is refused.
  - **Hosted MCP** (D-117) validates conversation, run and approval ids as UUIDs. A workspace-scoped token can only reach conversations and runs of that workspace's bots.
  - **Tools returning outside content** are marked untrusted, so later risky calls ask first: `knowledge.search`, `files.read`, `replay.run`, `data.search`, `memory.search`, `links.ask`.
  - **Redaction:** values added during a run (logins, cards, codes) stay redacted after a secret request rebuilds the redactor. The run-failure log is redacted.
- **Worker:**
  - Every minute-tick step catches its own errors.
  - Each due routine runs in its own savepoint. A broken one moves its schedule on (or switches off) instead of rolling back the whole batch.
  - **A sweeper starts runs left queued for 2 minutes** (made by a step that failed partway, or by the API when starting failed). The workflow id is the run id, so starting twice is harmless.
  - **The project heartbeat and iMessage polling hold advisory locks**, so overlapping ticks never double-start or double-reply.
  - **Calendar fires older than 10 minutes don't run.** Fires for cancelled or changed events are dropped at the next check.
  - **Device-data retention runs hourly** (keyed on the scheduled time, so recovery replays the same steps). "Where am I now" answers are still cleared within 10 minutes. Read notifications go after 180 days.
  - **The encryption sweep** re-checks fully sealed workspaces every 15 minutes instead of every minute. **Data keys on a previous server key are rewrapped automatically** (hourly maintenance).
  - **Leave-now** caches travel times for 10 minutes per event and only looks 2 hours ahead.
  - Indexes added for these queries and the unread badge.
  - A brief skips its scheduled time only when the last run was a wake-up brief, so twice-daily briefs keep both runs.
  - Sub-run messages and schedules belong to the person who started the work (`personForRun`), not the bot's creator.
- **Self-host install:**
  - The SAML key is written as PKCS#1, and existing PKCS#8 keys are converted.
  - The sign-up hook URL is https-only through the public address (an http URL stopped Auth from starting).
  - The server image includes `@casama/mcp` and the MCP SDK.
  - Kong's config version is single-quoted.
  - Caddy's 502 note covers only `/`, so health checks see real errors.
  - Image pulls retry with limited parallelism.
  - The web image clones Flutter at the pinned, commit-checked tag (works on arm64 and x64), with its own `.dockerignore`.
- **Self-improving skills:** the detailed SPEC rule ("matches two or more earlier runs", which is the third time) governs, as D-126 built it. The SPEC table's "twice" was reworded to match.

## D-155 Actions that never ask, and routines in your chat

- **Self-only actions never ask** (`selfOnly` on a tool), whatever the bot's autonomy, including "ask before everything". They change only the bot's own state inside Casama, visibly and reversibly:
  - its notes (`memory.write`) and its own schedule (`routines.create`, `routines.update`, `routines.delete`; what a routine then does still goes through approvals);
  - messages and cards for the person (`notify.user`, `ui.show`);
  - board tasks and comments (`tasks.create`, `tasks.update`, `tasks.comment`, `suggestions.add`);
  - housekeeping (`skills.load`, `checkpoint.create`, `sidebar.organize`).
- **Still asking as before:** anything that reaches outside Casama or costs money: sending through chat apps or email, web requests, shell, browsing, payments, publishing or sharing pages, calls, creating or archiving bots, rewriting a bot's setup. Watchers stay under the normal rules (they fetch outside pages on a schedule). An explicit "ask" action rule still wins over `selfOnly`.
- **One card at a time:** after `ui.show` the run ends its turn and waits for the answer; a second card in the same batch is refused.
- **Routines post in your chat, one thread per person:**
  - `routines.create` saves the conversation it was asked in (a direct chat with the routine's bot), and its runs post there.
  - A routine with no chat recorded (made in Settings, or before this change) uses the person's latest direct chat with that bot; only someone with no chat yet gets a new one.
  - The run's starting message carries `routine: {id, name}`; the app shows it as "Routine "…" ran" instead of a bubble from the person, and the open chat reloads when the routine's result arrives.
  - Routine runs are told their reply reaches the person in that chat with a notification, so they don't reach for `channel.send` to "send" a reminder or greeting. `channel.send` is for an outside chat app the routine names.
- **Notifications are read once answered:** a database trigger marks an approval's, takeover's or secret request's notifications read when it stops being pending, however it was answered; opening a bot's chat marks its results read. Per-bot counts in the sidebar come from the same data.

## D-156 Talking like a person: acknowledge first, messages mid-task, shared files

- **Acknowledge, then act:** the platform rules ask for one short line saying what the bot is about to do, in the same turn as its first tool call, and no running commentary after. Text a step says alongside tool calls is now kept as its own message (`message.completed`, stored in the thread) instead of disappearing when the run ends. The final reply's parent is the last thing the run said, so the thread stays one line (no false "edited versions"); a step that shows a card is the final reply itself.
- **Messages sent while the bot works** (direct chats): `POST …/messages` without a card action attaches the message to the active run (`queued` or `running`, not cancelling) and returns `joined: true`. Before each model step the run adds such messages to its turn, marked "Sent while you were working on this", and the bot decides whether to fold them in, switch, or finish first. A message the run never saw gets its own follow-up run when the run completes, is stopped or fails; the app follows that run too. Group chats and card answers still wait (one run per woken bot, and a card answer is a new turn by nature).
- **The composer while working:** Stop shows while the field is empty; typing turns it into Send. The per-run cost line under the composer is gone (it's in the run timeline and Usage).
- **Files a reply links to show in the chat:** links to files on the bot's computer become attachments under the reply. Images (png, jpg, gif, webp) show a thumbnail; documents, data, code, archives, audio and video show a file card. Nothing renders or plays inline beyond that; a tap opens the existing file preview. Up to 8 per reply.

## D-157 Loop guard, and live view quick actions

- **Loop guard** (on top of the 40-step, 30-minute and budget limits):
  - The same action (tool and arguments) a third time in a run isn't run; the model is told it already did that twice without getting further and to change approach or say what's blocking it. Looking-only tools (read-only ones, and names ending in snapshot, screenshot, read, list, search or load) are exempt, since they repeat legitimately as a page changes.
  - Five failed steps in a row (errors, refusals, skipped repeats) end the run as `stuck_looping`, with a message saying it stopped to save the budget.
- **Live view on phones:** the hidden typing field is multi-line, so the keyboard's Enter types Return on the computer instead of closing the keyboard, and it always holds one invisible character so Backspace registers on an "empty" field.
- **Quick actions** under the live status, in the side panel and full screen: Copy (Ctrl+C on the computer, then Neko's `clipboard/updated` text onto this device), Paste (this device's clipboard via `clipboard/set`, then Ctrl+V), Screenshot (saved or shared from this device; works while only watching), and on phones a keyboard button. Copy and Paste need control, as Neko only shares the clipboard with the host.

## D-158 Offline launch

- **Server settings are saved** per server (`ServerConfigCache`, shared preferences; public data, kept across sign-outs). A launch starts from the saved settings at once, so it doesn't wait on the network and opens offline, then fetches the server's in the background and saves them for next time. If the server has moved to another Supabase project since, the app reconnects. Only a server never reached before (or a first launch) waits for `/config`, with the "can't reach the server" screen and Retry as before. Background wakes (geofences) use the saved settings too.
- **Workspaces come from the offline cache at launch** (`orgs:<user>`, beside D-112's bots and messages, cleared on sign-out like them) and the server's replace them. After a change (a workspace created, joined or left) the server's are awaited, never the saved list. Offline, the saved ones stay.
- **A failed workspace load never starts the welcome flow:** with none known, the app stays where it is rather than treating "couldn't load" as "has none" (the welcome flow makes a workspace). Riverpod retries the load.
- **Sessions:** Supabase restores the saved session at launch and keeps it when a token refresh fails on the network (only an invalid refresh token signs out), so an offline launch stays signed in and the offline cache isn't wiped.

## D-159 Client performance

- **Measured, in profile mode:** `client/integration_test/perf_test.dart` streams a long Markdown reply into a 40-message chat and flings the thread, over the doodle and the photo wallpaper, against the fake backend (`flutter drive --profile -d macos …`). On an M-series Mac the UI thread's work per streamed frame went from about 3.5 to 1–1.3 ms (90th percentile 5 to 1.2–1.8 ms), with less raster time too; scrolling is unchanged.
- **Chat:** Markdown blocks are parsed once per run of text and theme and kept (`ChatMarkdown`, `markdownChunks`; split only at blank lines that start a new top-level block, so the result matches a whole parse), keyed by the style's values rather than the theme object (`Theme.of` can return an equal theme as a new object every frame). Rows whose entry and inputs are unchanged are reused (`_Row.inputs`, opt-in per row). The header and composer watch only the fields they show; the thread rebuilds alone. File links in a reply are found once per message.
- **App-wide:** themes are cached per appearance, and `WallpaperTheme` compares by value (a rebuilt but equal theme no longer animates and rebuilds the whole app). The app root listens to its background services instead of watching them. A finished entrance animation leaves no opacity layer behind. The doodle pattern is one tiled image instead of hundreds of glyphs per frame; a photo wallpaper is blurred once at low resolution instead of on every frame, and decoded no larger than the display. Thumbnails (chat attachments, app logos) decode at the size they show. Startup fetches `/config` once, not twice.

## D-160 Plugin developer kit

- **Guide:** `docs-site/develop/plugins.md` (Build on Casama → Plugins): the package layout, `plugin.json`, skills, `mcp.json` rules, Casama's secrets extension, the bot's computer as plugin servers see it (image contents, no install step, the 30-second `initialize` limit, idle stops, egress), risk from tool annotations, checking, publishing, updates and limits. Written from `checkPlugin`, the install route and computerd, so it states what Casama does rather than what the specification allows.
- **Example:** `examples/hello-plugin`: a skill, a dependency-free Node.js MCP server (three annotated tools, notes in `PLUGIN_DATA`) and one secret. Plain Node so it runs on the computer with nothing installed; the guide recommends the SDK plus bundling for real servers.
- **Checker:** `packages/plugin-check` (`casama-plugin-check [folder] [--json] [--strict]`) runs `checkPlugin` and the skill rules, plus run-time tips: a `./` command missing or not executable, a program the default image lacks, a `${PLUGIN_ROOT}` path that isn't in the package, `npx` start-up time, files not committed. In a git checkout it reads what git tracks (with the executable bit), as GitHub serves it. It imports the domain files by relative path, so it runs with plain Node 24 and nothing installed; the composite action `.github/actions/plugin-check` relies on that.
- **One source for limits:** the plugin limits (400 files, 10 MB) and the skill limits (60 files, 1 MB, 5 MB, safe file names) moved to `@casama/domain` (`PLUGIN_MAX_*`, `SKILL_MAX_*`, `SKILL_SAFE_PATH`); the server uses them, so the checker can't drift from install.
- **Not published to npm yet:** the package is private; publishing needs bundling the domain files in. Developers use the GitHub Action or run it from a clone.
- **Tests:** `packages/plugin-check/test/check.test.ts`: the example passes cleanly and its server answers MCP (initialize, tools/list with annotations, save and read a signed note, errors); refusals, size limits, skipped parts and each tip.

## D-158 Two Mac builds, App Store compliance, and Mac integration

- **Two Mac builds:**
  - **Mac App Store** (`scripts/package-macos-appstore.sh`, `--dart-define=CASAMA_DISTRIBUTION=appstore`, `macos/Runner/AppStore.entitlements`): sandboxed. Off in it (`isMacAppStoreBuild`): using this Mac for bots (companion), the local server (Docker), reading other apps' windows and selection, the folder watcher and the activity tracker. Purchases go through StoreKit with the iOS storefront rule. Entitlements: network client, a loopback listener (ChatGPT sign-in), microphone, contacts, user-selected files and Downloads. Verified: the sandboxed build launches with no sandbox denials.
  - **Direct download** (`scripts/package-macos.sh`): every feature, signed with Developer ID and the hardened runtime at packaging time, notarized. The hardened runtime is applied by the scripts, not set in the Xcode project: with it on, unsigned local release builds can't load bundled frameworks (different team IDs).
- **Compliance:** `PrivacyInfo.xcprivacy` in the iOS and macOS apps (no tracking; email, user content, audio, contacts and purchases linked and for app functionality, crash data unlinked; UserDefaults CA92.1 and file timestamps C617.1). `LSApplicationCategoryType` Productivity, `ITSAppUsesNonExemptEncryption` false, and the Mac app named Casama (`CFBundleName`). No new permission descriptions: the Mac asks only for contacts, the microphone and (direct build) Apple Events, which already have them.
- **Mac integration** (`casama/mac` channel, `MacBridge` in `MainFlutterWindow.swift`, `lib/core/mac_bridge.dart`): File menu (New Chat ⌘N, New Bot ⇧⌘N, Search ⌘K, Close Window), Go menu (Bots, Inbox, Board, Computer, Pages: ⌘1–5), a working Settings… (⌘,), Help → `CASAMA_HELP_URL`; the dock badge shows the Inbox count; Open at login in Settings (`SMAppService`, macOS 13+). The window is sized natively on first launch from the screen's usable area (up to 1440 × 960, centered) and then restored by macOS; Windows and Linux use `desktop_window.dart`, which saves its bounds by polling (window event types break release AOT builds).

## D-161 Documentation structure

- **One public source:** user, self-hosting and developer documentation lives only in `docs-site/` (VitePress), in four sections: Get started (`introduction`, `quick-start`, `faq`), Guides (`guide/`, one page per feature area), Self-hosting (`self-hosting/`: install, configuration, computer providers, operations, troubleshooting) and Build on Casama (`develop/`: HTTP API, CLI, SDK, plugins, webhooks, bot templates, workspace files, A2A). The pages render on GitHub as plain Markdown too, so the README and repository files link to them directly.
- **Moved, not copied:** `docs/SELF_HOST.md`, `docs/MCP.md` and `docs/BOT-TEMPLATE-FORMAT.md` were folded into `self-hosting/`, `guide/mcp.md` and `develop/bot-templates.md` and deleted; the build no longer copies `SELF_HOST.md` in. Older decisions that mention those files refer to their new homes. `docs/` keeps project records for contributors: architecture, decisions, the audit, the security review, the launch checklist and launch drafts.
- **Written from the code:** every page was checked against the decision log, the app's strings (`app_en.arb`, so UI paths match what people see), the contracts, the CLI and the server's settings. Where the code and older docs disagreed, the docs follow the code and say so under "Limits". Gaps found while writing are listed for follow-up rather than documented as working.
- **Style:** written for people using Casama, not for its developers: no decision numbers, phases or server-internal paths; the app's labels in bold; numbered steps; a Limits and a Related section per page. CONTRIBUTING.md has the short version for contributors.
- **Site details:** the brand teal from the marketing page, the mascot logo, local search, edit links, and inline code marked `v-pre` so placeholders like `{{secret:NAME}}` show as written. The API reference stays generated from OpenAPI at `/api/`; route descriptions no longer carry decision numbers.
- **Repository files:** README (features, quick start, documentation map), CONTRIBUTING (full development setup, checks, docs style), SECURITY (scope, safe harbor), issue and pull request templates, `client/README.md`, and a root `CHANGELOG.md` (the CLI release notes point at it).

## D-159 Desktop auto-updates

- **Who updates what:** the stores update the iOS, Android and Mac App Store apps. The direct-download Mac app uses Sparkle and the Windows app WinSparkle, both through `auto_updater` (`lib/core/updater.dart`). Linux installs come from packages, so the app only shows "Casama X is available" in Settings, from the releases repo's latest release.
- **Where updates come from:** a public repo with only installers and feeds, `stackwares/casama-releases` (`CASAMA_RELEASES_REPO`, `CASAMA_UPDATE_FEED`); the source repo is private, so its release files would need a sign-in. Feeds: `releases/latest/download/appcast-macos.xml` and `appcast-windows.xml`, one item each (the latest release).
- **Signing:** every update is signed and the apps refuse anything else. macOS: EdDSA (`SUPublicEDKey` in Info.plist; private key in the login Keychain, account `casama`, backup `~/.config/casama/sparkle-ed25519-private.key`). Windows: DSA, as WinSparkle 0.8.1 verifies (`client/windows/dsa_pub.pem` in `Runner.rc`; private key `~/.config/casama/winsparkle-dsa-private.pem`). Losing a private key means installed apps can't update until reinstalled by hand.
- **Behaviour:** checks every 6 hours, downloads in the background and installs on quit; "Update automatically" in Settings turns it off (macOS through Sparkle's `SUEnableAutomaticChecks` user default; Windows by not scheduling checks). "Check for Updates…" in the Casama menu (Mac) and "Check for updates" in Settings (Mac and Windows, with the version).
- **Release flow:** `package-macos.sh` signs the notarized DMG for Sparkle and writes `dist/appcast-macos.xml`; `package-windows.ps1` signs the MSIX (WinSparkle opens it in App Installer) and writes `dist/appcast-windows.xml`; `publish-desktop-release.sh` checks the repo is public, asks for confirmation and creates the GitHub release with the installers and feeds (`DRAFT=1` for a draft).
- **Mac App Store build:** never starts Sparkle; its packaging marks `CasamaDistribution = appstore` (the menu leaves out Check for Updates…) and removes Sparkle's helper programs (not sandboxed, they'd fail App Store validation). The framework stays linked, unused. Verified: the store build launches sandboxed without the helpers.

## D-162 Simple chats by default

- **Chats show what the bot is doing, not how:** by default the step cards (each tool, its command or query, its timing) stay out of the chat. While the bot works, one line says what it's doing in everyday words ("Searching the web…", "Making an image…", "Working on its computer…"; never tool names). Skill, checkpoint and model-switch notices are left out too. A failure the server can't explain plainly reads "Something went wrong. Try again, or open Details to see why."; its technical part stays in Details. Failures that explain themselves (a missing key, a budget reached) read as they are.
- **Still shown:** everything that needs the person (approvals, questions, secrets, device access, take-over requests, cards) and everything the bot produced (replies, files it shares, published pages, "Remembered something").
- **Settings → More → Show the bot's steps** brings back the detailed view (each step, as before). Kept per device; off by default, for everyday users. The bot's reply style itself is unchanged.

## D-163 Default fonts: Libre Baskerville and Lato

- **Headings in Libre Baskerville, text in Lato** by default (Oliver), replacing Noto Serif and Google Sans from D-087. Both ship with the app (Libre Baskerville 400 and 700; Lato 400, 700 and 900), so they work offline and never swap in late; SIL Open Font License 1.1, licenses in `client/assets/fonts/`. Google Sans, Noto Serif, Figtree and Fraunces stay bundled as choices.
- People who never picked fonts get the new defaults; anyone who chose fonts, or a theme that sets its own (Editorial, Sunset, Graphite), keeps them. Reset in Settings → Fonts goes to the new defaults.

## D-164 Phone UX pass: keyboard, back, keys, layouts, bot tool calls

- **Keyboard:** on phones, a tap outside the field being typed in puts the keyboard away (Flutter keeps it open on touch), and dragging a page, form sheet or the chat does too. Buttons and other fields get their taps first; mouse clicks are left alone, so desktop shortcuts keep working.
- **Back goes where you came from:** screens opened from somewhere other than their parent are pushed, not replaced: from the inbox (a notification, a run, "For you"), the board, projects, usage, watchers, replays, the routines "View run" link and the chat menu's Computer. Finishing a flow (setup, welcome, import) still replaces the screen.
- **Keys shown once** use one card: Copy key first, the key in a box you can tap to copy, then Done. Revoking an API key or unlinking bots asks first, since it takes effect at once and can't be undone.
- **Layouts:** every screen is checked at 430 and 375 points wide (`client/test/phone_layout_test.dart`); dropdowns expand to their field, the phone tab bar fits six tabs on small phones, and fixed-ratio tiles became natural height.
- **Bot tool calls:** an invalid call is told the tool's arguments ("shell.exec takes {"command": string (required), …}") so a model that sent none can fix it; a tools.load that loads nothing says what is loaded and which groups exist, and counts toward the loop guard (it was exempt, so a model could repeat it for the whole run). browser.screenshot creates its folder first.

## D-165 Live calls on Gemini Live

- **Decision (Oliver):** live voice calls use Gemini Live instead of OpenAI Realtime. It's the cheapest speech-to-speech API with function calling (about $0.005 a minute in and $0.018 out, against $0.06 or more for `gpt-realtime-2.1`), and it has a free tier. A workspace's Google AI key (`provider = google`) picks Gemini; without one, calls fall back to OpenAI Realtime so existing workspaces keep working. `bots.voice.realtime_provider` can prefer one when both keys exist.
- **Server:** `createGeminiLiveSession` mints a single-use ephemeral token (`POST /v1beta/auth_tokens`, `uses: 1`, 30-minute expiry, 2 minutes to start) whose `bidiGenerateContentSetup` carries the model (`gemini-3.8-live`, `GEMINI_LIVE_MODEL`), voice, the bot's instructions, its tools as `functionDeclarations` (JSON Schema cleaned to Gemini's OpenAPI subset by `geminiSchema`), turn detection with barge-in, both transcriptions and sliding-window context compression. `fieldMask` locks those fields, so a client can't change the instructions or tools; `sessionResumption` is left to the client so it can reconnect. `VoiceSession` gained `provider: gemini | openai` and `setup`; transcripts send `provider` for the usage estimate (`geminiLivePerMinute: 0.02`).
- **App:** `GeminiLiveCall` (`client/lib/core/gemini_live.dart`) opens the constrained WebSocket with the token, sends `setup`, streams the mic as 16 kHz PCM (`record`, with echo cancellation and noise suppression; Android uses the voice-communication source), and plays the 24 kHz reply through `flutter_soloud`'s buffer stream on every platform (web loads `init_soloud.js`). `GeminiLiveEvents` turns server messages into the transcript, tool calls (answered with `toolResponse` by id and name), the speaking state and reply latency; `interrupted` flushes queued audio. Google ends connections after about 10 minutes, so on `goAway` the call resumes the same session on a new connection with the latest resumable handle. `RealtimeVoiceConnector` picks Gemini or the existing OpenAI WebRTC client from `session.provider`.
- **Phone calls (Twilio):** the bridge speaks Gemini too when the session is Gemini: 8 kHz μ-law from Twilio becomes 16 kHz PCM, Gemini's 24 kHz PCM is averaged down to 8 kHz and encoded as μ-law; `interrupted` sends Twilio `clear`; transcripts are saved a turn at a time; `end_call` hangs up after the goodbye.
- **Not verified live:** no real Gemini key was used. The request and message shapes follow Google's Live API reference (v1beta, constrained endpoint); tests use a fake token endpoint and a fake socket. Echo on speakerphone depends on each platform's echo cancellation and needs real-device checks, especially on desktop. Phone calls on Gemini aren't covered by an end-to-end test.
- **Tests:** agent (`gemini-live.test.ts`: schema cleanup, the locked single-use token, μ-law and resampling), API (`voice.test.ts`: with a Google key the session is Gemini, single use, with locked instructions and tools), widget (`gemini_live_test.dart`: transcript, barge-in, tool round trip, setup, mic streaming, mute, resuming on goAway, the bot speaking first). macOS, Android, iOS and web builds pass with `flutter_soloud`.

## D-166 Google's MCP servers, hubs over MCP, and redirects vendors accept

- **Google:** Casama uses Google's own MCP servers, one per product: Gmail, Calendar, Drive, Docs, Sheets, Slides and Contacts (People). Google has none for Forms, Keep, Tasks or Meet; Chat (needs a Chat app) and Classroom are left out. Gmail is one connection: search, read, draft, label (`gmail.modify` + `gmail.compose`). Google's Gmail server can't send, so drafts are sent from Gmail. The old `gmail` (send) and `gmail_inbox` entries are merged; `gmail_inbox` still resolves to Gmail for existing connections. Docs, Sheets and Slides use `documents`, `spreadsheets` and `presentations`; Drive keeps `drive.file`; Contacts uses `contacts.readonly`, `directory.readonly` and `userinfo.profile`.
- **Scopes are Casama's, not the server's:** Google's servers announce every scope they accept (Gmail's include `https://mail.google.com/`), so Google apps ask only for the catalog's scopes; other vendors still follow what they announce. Each Google app gets its own consent (no `include_granted_scopes`), so a token never covers more Google apps than the one connected.
- **Google's gate:** tool calls only work once the server's Google Cloud project is enrolled in Google's Workspace Developer Preview Program. Enrolling needs a Workspace (not @gmail.com) address and accepting the program terms, which say preview features may not ship in public apps before general availability. Self-hosters enroll their own project; Casama Cloud offers Google apps through Composio (or not at all) until Google's servers are generally available. Verified live (project `kasama-ai`, client "Casama MCP" with "AI-powered agent" on): sign-in, token exchange and the tool list (23 Gmail tools) work; calls return Google's enrollment error.
- **Default route (2026-11-11):** whenever the server has a Composio key in use, Google's apps go through Composio, even with `GOOGLE_OAUTH_CLIENT_ID` set: enrollment needs a Workspace address we don't have, and after GA our own client would still need Google's verification plus a yearly CASA assessment for the restricted Gmail scopes, which Composio's verified app already covers. The admin console's App connections has **Google apps: Through Composio / Google's own servers** (`instance_settings.connections.google`, `composio` by default, `direct` for self-hosters who enrolled). Casama Cloud always uses Composio and refuses `direct`. Connections made directly before this keep calling Google's servers until they're reconnected.
- **Hubs over MCP:** Composio (`connect.composio.dev/mcp`), Pipedream (`remote.mcp.pipedream.net`) and Zapier connect with one click over MCP OAuth (dynamic registration checked live on 2026-11-11), so no API key is needed. The API-key paths stay under More ways to connect. When an app's own sign-in needs a client the server doesn't have (Slack, HubSpot, Asana, Box, Figma, GitHub without a token, Google), the connect sheet offers these hubs instead of a dead end (`HUB_APPS`).
- **Catalog checks (2026-11-11):** Vercel now allows dynamic registration on localhost (was a client metadata document, https only). Figma advertises registration but answers 403 to unapproved apps, so it stays admin-registered. Still admin-registered: GitHub, Slack, Asana, Box, HubSpot, Figma, Google.
- **Redirects:** vendors only accept https or localhost redirects. A server on a private address over http (local development) now uses `http://localhost:<port>/oauth/callback`; `OAUTH_REDIRECT_URL` overrides it. Casama Cloud's https address is used as is.
- **Not done: a Composio CLI on bots' computers.** It would need a Composio key inside the computer, where a bot or a page it reads could take it, and it adds nothing the MCP connection lacks. It could come later as an opt-in plugin.

## D-167 Apple and Google account sign-in

- **What people see:** Continue with Apple, then Continue with Google, on every platform. Apple used to be hidden on Android, Windows and Linux, so an account made with Apple on an iPhone had no Apple button there. The flow on those platforms is already the browser, so the button is there too.
- **iPhone and Mac use Apple's system sheet** (`sign_in_with_apple`, then `signInWithIdToken` with a nonce). Android, Windows, Linux and the web keep `signInWithOAuth`. If the sheet cannot open (an unsigned local Mac build has no Sign in with Apple entitlement, on purpose, so those builds still launch), the app opens the browser instead. Cancelling the sheet does not. The entitlement is on the iOS app and the Mac App Store signature. The direct-download Mac build adds it when `package-macos.sh` signs with a Developer ID. `Release.entitlements` stays without it.
- **Names:** Google and the Apple browser flow put the name in user metadata (`full_name`, `name`, or given and family), not `display_name`, so profiles showed the bit before the `@`. `profile_display_name` reads those, and a new profile uses it. Apple's sheet sends the name only on the first authorization and not inside the token; the app writes it onto the user, and a trigger copies it onto the profile while the profile is still the email fallback. A name someone already set is left as it is. Existing accounts whose profile is still that fallback are filled in by the migration.
- **Turning the providers on** is still credentials, not code. Self-host: `APPLE_AUTH_*` and `GOOGLE_AUTH_*` on the auth service, callback `https://<domain>/auth/v1/callback` (Kong's route; GoTrue's own default is the site root, which Kong does not serve). Apple's client id list is the Services ID first, then `ai.casama.app`. The Apple secret expires within six months. Local `supabase/config.toml` has both providers, off. The Google client for Gmail, Calendar and Drive is a different client.
- **Tests:** nonce hash, name joining and which Apple errors fall back to the browser (`apple_sign_in_test.dart`); the sign-in sheet shows both buttons. A live Apple or Google account was not used.

## D-167 Joining a workspace: one link, short codes, a preview, approvals and email domains

- **The link carries the invite; codes are the fallback.** Every workspace has one standing invite link (`invite_links.is_default`, member role, no expiry), made on first use and copyable again: its token is kept in `share_token`, sealed with the workspace content key (D-136), and the table stays admins-only under RLS. **Reset link** revokes it and makes a new one. A link carries the server's address, which a bare code can't, so codes are only for reading out or typing: 8 characters of Crockford base32 (no I, L, O or U) shown as `XXXX-XXXX`, valid 48 hours (`kind = 'code'`, the check requires an expiry), and normalized however they're typed (case, spaces, O for 0, I or L for 1). Custom links (role, expiry, uses; D-099) stay under **Custom links**.
- **Guessing:** codes have 40 bits, so wrong invites (preview, join and the join page) are capped at 10 per 10 minutes per person, or per address when signed out (in memory, like the request limit; 429 `too_many_attempts`).
- **One way in for every invite:** `POST /v1/join {invite}` takes a link, a link token, a code or an email invite token (`kinv_`). It returns `joined`, `member` (already in) or `requested`. Emailed links now point at `/join/<kinv_…>` (the app had no `/invites/` route; that path now redirects there, in the app and in Caddy). `POST /v1/invite-links/{token}/accept` stays for older clients and answers 403 `join_requested` for links that ask first.
- **See before joining:** `GET /v1/join/preview?invite=…` needs no sign-in and returns only the workspace's name, icon, color and member count, the role, the inviter's name, whether approval is needed, and for email invites the address partly hidden (`invite_preview()`, security definer, granted to anon). The app's `/join/<invite>` shows it with **Join**, **Ask to join** or **Sign in to join**; the invite is kept through sign-in, on disk, so a restart during sign-up doesn't lose it. Nothing joins without a tap. When an invite isn't found and the link named another server, the app offers to switch.
- **Ask first:** a link with `requires_approval` files a `join_requests` row (one pending per person and workspace) and notifies the admins; `decide_join_request()` approves (membership with the link's role, a use counted) or declines. The person sees their own request; admins see the workspace's.
- **Email domains:** an admin can open the workspace to their own verified email domain only (`org_join_domains`; the insert policy checks `my_email_domain()`, which needs `auth.users.email_confirmed_at`, and refuses shared domains such as gmail.com via `is_shared_email_domain()`). People with a verified address there see it in `GET /v1/me/joinable-workspaces` and join with `POST /v1/orgs/{id}/join`, as members only. New people with no workspace are shown **Your team is already here** before the welcome chat makes them one (D-129), with **Start my own workspace instead**.
- **Email invites:** batch (`POST /v1/orgs/{id}/invites/batch`, up to 50, deduplicated), list unaccepted, resend (new token, 7 more days) and cancel. Without email, the app lists each person's link to send by hand.
- **Telling people:** the person who made the invite gets `member_joined` ("Ana joined Acme"); domain joins notify the admins; an approved person gets `join_approved`, which opens `/joined/<org>`: a welcome page with the workspace's bots. Notifications go out as deferred pushes, like D-143's.
- **App:** **Settings → People** (everyone sees members; admins get the link with Copy, Share and QR code, **Ask me before people join**, codes, email invites, waiting requests, unaccepted invites, the domain switch and custom links). Workspace settings lost its invite section; the workspace switcher gained **Invite people to …**, **Join with a link or code** (paste, type or scan; a copied invite fills in by itself on Android, Windows and Linux, where reading the clipboard shows no prompt) and **Workspaces you can join**. Bot sharing links to People for someone not in the workspace yet. The welcome chat's invite card copies the standing link instead of making a new one each time.
- **Opening links in the app:** the API serves `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json` for `/join/*` when `APPLE_APP_IDS` / `ANDROID_CERT_SHA256` are set, and a small join page at `/join/<invite>` (strict CSP, no scripts, `casama://app/join/<invite>?server=…` to open the app). Caddy sends `/join/*` to it only when the web app isn't running. The apps' associated-domain entitlement and Android App Links intent filter need the final Casama Cloud domain, so they wait (NEEDS-FROM-OLIVER); a self-hosted domain can never be built into the store apps, so self-hosted links always go through the page or a paste.
- **Not done:** changing roles, removing members and leaving a workspace (unchanged limits); domain verification by DNS (an admin's own verified address stands in for it).

## D-168 Connector sign-in: real errors, and https for self-registered sign-in

- **The guarded fetch hands back Node's own `Response`** (and takes a `Request` object apart before passing it on). It used npm undici, whose classes fail `instanceof Response`; the MCP SDK's OAuth code then read every error reply as the text "[object Response]" and hid the provider's reason. This fetch serves every connector (MCP sign-in and token refresh, Composio, Pipedream, http.request), so all of them now report what the provider said.
- **Sign-in through self-registration (dcr) needs a secure return address:** OAuth 2.1 providers (PostHog among them) refuse a plain-http redirect unless it is loopback. With a LAN or other http address, the catalog marks those apps' sign-in unavailable, so the app offers the API key instead; apps that only sign in explain that Casama must be served over https. Production on https is unaffected.
- **Cost controls (Oliver: minimize Gemini Live cost):**
  - **Tools:** calls carry a small conversational set (`VOICE_CALL_TOOLS`: memory, knowledge, web search, notify, routines, watchers, tickets, usage, device data) plus `start_task`, instead of every tool the bot has: every definition goes with the session and Live models have no context caching. `start_task` (handled in `POST /v1/voice/tool`) posts the task to the call's conversation as an ordinary chat run with the bot's full tools and returns at once. This applies to OpenAI calls too.
  - **Context cap:** `contextWindowCompression` starts at 32k tokens and slides down to 16k (Gemini's default trigger is about 105k), which bounds what each turn carries and still lets calls run past 15 minutes.
  - **Silence:** `turnCoverage: TURN_INCLUDES_ONLY_ACTIVITY`, so turns hold speech, not the silence between it (3.8's default includes all audio activity).
  - **Forgotten calls:** the call screen hangs up after 2 minutes with no speech from either side and no tool running (`CallScreen.idleLimit`).
  - **Model:** `gemini-3.8-live` stays: every Live model has the same per-token price, Extended Thinking only adds billed thinking tokens, and `gemini-3.1-flash-live-preview` and the 2.5 native-audio preview shut down on 2026-11-17. There's no Flash-Lite Live model, and Live models can't use Batch or context caching.
  - **Real cost:** the app and the phone bridge add up `usageMetadata` (`addGeminiUsage`, by modality; tool-use prompts and thinking count as text) and the usage ledger records `geminiLiveCost` from list prices ($3 / $0.75 per 1M audio / text in, $12 / $4.50 out) with the token counts in `meta.tokens`; calls without counts keep the per-minute estimate (`meta.estimated`). Each `usageMetadata` is treated as covering the latest response, as the reference describes it; the ledger's token counts are there to confirm that against Google's bill.
  - **Tools on calls, per bot (Oliver):** the small set stays the default; bot settings → Voice → **Tools on calls** picks connected-app tools to add (`bots.voice.call_tools`, full names `kind.name.tool`). The worker adds them from each connection's cached tool list (no refresh at call start), only for connections the bot may use and within its tool allowlist; running them still goes through the voice run, which checks the bot's tools. Local MCP servers aren't offered. The voice settings sheet now starts from the bot's saved settings, and `updateBotVoice` merges (a null clears one setting) instead of replacing the whole `voice` object, which would have dropped `call_tools` and `realtime_voice`.

## D-169 About you: one profile per person that every bot reads

- **Why:** bots didn't know who they were talking to. The prompt carried only the timezone; the personal bot had the first name written into its instructions once; Settings showed only the email; and everything learned went into one bot's memory, which other members of a shared bot can read. A new bot started knowing nothing, and one person's "keep it short" applied to everyone using a shared bot.
- **Ask for one thing, learn the rest (Oliver):** the name comes from sign-in (D-167). The welcome chat now opens with "What should I call you?", the given first name filled in (only a real name, never the part of the email before the @); the answer sets `profiles.preferred_name`. Nothing else is asked up front. The personal bot's instructions no longer contain the name.
- **Where it lives:** `profiles.preferred_name` and `pronouns`, which teammates already read. `user_about` (about, reply_style, learn) and `user_facts` (at most 200, oldest unpinned dropped by a trigger) are private to the person under RLS, so a teammate's bot can't read them through Supabase; the worker reads them for runs. They are per person, not per workspace, so the built-in store and the Honcho/Supermemory backends (D-137) stay bot memory only.
- **Where it applies (Oliver: personal facts off in team spaces by default):** preferred name, pronouns and "How I like replies" go into every run that acts for the person (`actingUserId`, D-095), in every workspace. "About me" and learned facts apply only where `profile_shared_in(user, org)` is true: a `profile_spaces` row when the person set one for that workspace, otherwise only when they are its only member. A second member joining switches it off without anyone doing anything. Runs for nobody (linked agents) get no profile.
- **Learning:** the extraction prompt tags each memory `about: person | work` and refuses health, religion, politics, sexuality and money troubles unless the person asks for them to be remembered. Person facts go to `user_facts` (with the source workspace, bot and run), work facts to the bot's memory as before. With "Learn about me from chats" off, person facts are dropped rather than falling back to bot memory. The bot's `memory.write` takes `about: "person"` for the same split (`ToolContext.actingUserId`). Learning still never happens in runs that used personal device data (audit 2026-11).
- **Prompt:** a "You're talking with …" block after the skills index and the date, so the cached prefix is unchanged; up to 40 facts, pinned and newest first.
- **App:** the Settings card shows the name (falling back to the email) and opens **Settings → About you**: name, pronouns, how I like replies, about me, **Learn about me from chats**, **Use what I've shared in <workspace>**, and the learned facts (add, edit, pin, delete, and import from ChatGPT or Claude, which reuses the D-122 sheet without a bot). A profile save shows **Saved to your profile** with **Undo** in the chat: `memory.written` gained an optional `scope` ("profile"), and the event carries only the fact's id, never its text, because members of a shared chat can see run events.
- **Privacy:** About you is in the data export (`account.json` → `about_you`) and goes when the account is purged (`worker_purge_user` deletes the user; the tables cascade).
- **Encryption at rest:** About you has no workspace, so each person gets their own data key (`user_keys`, wrapped like workspace keys and loaded into the same key ring, so reads still open transparently). A person's `user_about.about`, `reply_style` and `user_facts.content` are sealed while they belong to any workspace that encrypts (`user_seals_profile`), which keeps D-136 opt-in. The worker's sweep makes the key and seals existing rows; when they no longer belong to an encrypting workspace it opens the rows and drops the key. Bots' writes seal at once (`contentKeys.sealForUser`). Because sealed rows can't be read straight from Supabase, the app reads and writes About you through `/v1/me/about`, `/v1/me/facts` and `/v1/me/profile-spaces/{org_id}`.
- **People who signed up earlier:** the welcome chat only asks new people, so everyone else gets one "What should bots call you?" card above their bots, filled in from their sign-in name. Saving or "Not now" sets `user_about.name_asked_at`, so it shows once across devices; skipping the welcome question sets it too, and people who already have a preferred name were marked by the migration. The migration also removes the person's name from existing personal bots' instructions (`You are X, Ana's personal assistant.` becomes `this person's`).
- **People screen:** members show the name they go by and their pronouns, with the email underneath (`WorkspaceMember.name`, `pronouns`).
- **Not done:** no embedding search over facts yet; 200 short facts fit the prompt budget.
- **Tests:** `about_you_rls.test.sql` (privacy, the sharing rule, the cap), `about-you.test.ts` (the API, sealing with the person's key and opening again), agent run tests (prompt in personal and team spaces, the split, learning off, `memory.write`), the context ordering test, server welcome and privacy tests, and `about_you_test.dart` in the app.

## D-170 Kasama is now Casama, on casama.ai

- **Everything is renamed**, while nothing is published yet: the product name and copy, the domain (`kasama.dev` → `casama.ai`), packages (`@casama/*`, Dart `casama_app`, `casama_api`, `casama_sdk`, the `casama` CLI), env vars (`CASAMA_*`), the Helm chart, images (`casama/*`), asset and file names, the deep-link scheme (`casama://`), the Android and iOS widget and share targets, and the app id `ai.casama.app` (was `com.kasama.app`; reverse of the domain we own).
- **Kept on purpose:** the Firebase / Google Cloud project id `kasama-ai` (permanent); new Firebase apps were registered for `ai.casama.app` (iOS/macOS `1:278631205206:ios:55b0d13fb7dc9d07a9aef7`, Android `1:278631205206:android:c5d3ecc40b4ceaa7a9aef7`) and `client/config/firebase.json` points at them. The old `com.kasama.app` apps can be deleted once nothing uses them. The local Supabase `project_id` stays `kasama`: it names the local Docker containers and volumes, so changing it would start an empty local database.
- **Existing databases** are renamed in place by `20270113500001_casama_rename.sql`: the `casama_worker` role (password and grants kept), its policies, the functions that send `casama_*` notifications or read `casama.*` settings, the `casama-cloud` computer provider and the store product ids. Fresh databases get the new names from the earlier migrations. The Realtime broadcast policy keeps its old name on existing databases (only Realtime's admin can alter it; nothing refers to it by name).
- **Local machine:** keys moved to `~/.config/casama` (old folder kept as a backup) and the Sparkle signing key is also stored under the Keychain account `casama`. Client builds now take `--dart-define=CASAMA_API_URL=...` (was `KASAMA_API_URL`).
- **casama.ai on Cloudflare:** the marketing page (`casama.ai`, `www`) and docs (`docs.casama.ai`) are Workers with static assets (`site/wrangler.jsonc`, `docs-site/wrangler.jsonc`, `scripts/deploy-web.sh`), with security headers, always-HTTPS, TLS 1.2+ and strict SSL. Email Routing forwards hello@, support@, privacy@, security@, dev@, abuse@ and postmaster@. The API (`api.casama.ai`) waits for a server.

## D-171 Our own Supabase and API on casama.ai through a Cloudflare Tunnel

- **No Supabase Cloud.** Our self-hosted Supabase (the local stack on Oliver's Mac for now) and the API are published through a Cloudflare Tunnel, `casama-dev`: `https://auth.casama.ai` → Supabase's gateway (`localhost:54321`), `https://api.casama.ai` → the API (`localhost:8787`), anything else 404. It gives the https address that Apple's web sign-in, Google sign-in from phones, and links opened on other devices need, at no cost. It only works while the Mac is on; a server later takes over the same names, so the apps and the Google and Apple settings don't change.
- **Secrets first.** The local stack's signing secret was Supabase's published demo value, so it is replaced (`SUPABASE_AUTH_JWT_SECRET` in the root `.env`, which the Supabase CLI reads as a config override) and the server uses the new anon and service-role keys. The CLI's opaque `sb_secret_…` key is the same for every local stack and the gateway turns it into a service-role token, so a Cloudflare custom rule blocks any request to `auth.casama.ai` that carries `sb_secret_` (header or query) and the pg-meta route `/pg/`. Checked: the new anon key works; `sb_secret_` and `/pg/` get 403; the old published service-role token gets 401.
- **Auth addresses** (root `.env`, not committed): `SUPABASE_AUTH_EXTERNAL_URL=https://auth.casama.ai/auth/v1` (the `/auth/v1` path matters: GoTrue builds sign-in links and the OAuth callback from it, and the gateway only serves it there), `SUPABASE_AUTH_SITE_URL=https://casama.ai`. The server's `SUPABASE_URL` and `PUBLIC_API_URL` are the public addresses, so app-connection sign-ins return to `https://api.casama.ai/oauth/callback` (added to the "Casama MCP" Google client next to the localhost one).
- **Return addresses:** the allow-list takes the apps (`casama://app/login-callback`), the web app on this machine on any port, and `https://casama.ai/**` and its subdomains. The web app now passes its own address; before, Supabase fell back to the site address, which is the marketing page.
- **Magic links verified through the public address:** the email carries the link and the code, the link lands back in the app with a session, and the API accepts that session.
- **Email through Zoho:** `supabase/config.toml` has an `[auth.email.smtp]` section that is off by default (Mailpit for everyone else); this Mac turns it on with `SUPABASE_AUTH_EMAIL_SMTP_*` in the root `.env` (smtp.zoho.com:587, user and sender hello@casama.ai, name Casama) and raises `SUPABASE_AUTH_RATE_LIMIT_EMAIL_SENT` to 30 an hour (2 by default). The CLI only overrides settings that appear in the config, which is why the section exists. The app password is in Vaultwarden.
- **Running it:** the connector runs as a login item (`~/Library/LaunchAgents/ai.casama.tunnel.plist`, token in `~/.config/casama/tunnel-token`, log in `~/Library/Logs/casama/tunnel.log`). Phones and other machines use `--dart-define=CASAMA_API_URL=https://api.casama.ai`.

## D-172 Dev and production addresses: `api-dev`/`auth-dev` for this Mac, `api`/`auth` for the server

- **Names.** Production is `https://api.casama.ai` (the API) and `https://auth.casama.ai` (our Supabase). Dev is `https://api-dev.casama.ai` and `https://auth-dev.casama.ai`, which reach this Mac through the `casama-dev` tunnel (`localhost:8787` and `localhost:54321`). A staging copy, if we add one, would be `api-staging` and `auth-staging`. More people later each get their own tunnel and names (`api-<name>`).
- **Flat, not nested.** `api-dev.casama.ai` rather than `api.dev.casama.ai`: Cloudflare's free certificate covers one level of subdomain (`*.casama.ai`); a second level needs Advanced Certificate Manager.
- **`api`, not `server`.** It names what a client talks to, matches `CASAMA_API_URL` and `PUBLIC_API_URL`, and is where people look for an API. `app.casama.ai` is kept for a hosted web app and `status.casama.ai` for a status page.
- **For now both pairs reach this Mac.** The tunnel serves all four names until the server exists; then `api` and `auth` move to it and nothing on the dev side changes. This Mac's root `.env` already uses the dev names (`SUPABASE_URL`, `PUBLIC_API_URL`, `SUPABASE_AUTH_EXTERNAL_URL=https://auth-dev.casama.ai/auth/v1`), so sign-in links, the OAuth callback and app-connection sign-ins (`https://api-dev.casama.ai/oauth/callback`) use them. Dev builds use `--dart-define=CASAMA_API_URL=https://api-dev.casama.ai`; store builds will default to `https://api.casama.ai`.
- **Kept apart per environment:** database, JWT secret and keys, model keys, the Supabase return-address list, Google and Apple redirect addresses (one Google client per environment), and email (dev may keep Mailpit). The Cloudflare custom rule now matches every `auth*.casama.ai` host, so the `sb_secret_` and `/pg/` block covers `auth-dev` too (checked: both get 403).

## D-173 Apps without our own sign-in connect through Composio, as other agent apps do

- **What competitors do:** Rakazo connects apps through Composio or Pipedream Connect; OpenMausBot and OpenBot also list Composio. None register their own apps with Slack, Box or Figma.
- **Why we don't register those three:** Slack's MCP server only accepts apps listed in the Slack Marketplace (or internal to one workspace); Box hands out credentials per customer company (made by each customer's admin, and charged); Figma only lets approved clients connect (waitlist, reportedly paused). GitHub, Asana and HubSpot would be free and self-serve, and can still be added later: a configured client puts the app's own sign-in first again.
- **How it works:** catalog apps carry Composio's name for them (`composio`, the toolkit slug). With `COMPOSIO_API_KEY` on the server, an app whose own sign-in needs a client the server doesn't have (GitHub, Slack, Asana, Box, HubSpot, Figma; Google's apps without a Google client) offers **Sign in through Composio** (`managed`) first, plus any API-key option (GitHub tokens). One Composio user per workspace on the server's account, one connection named `apps` that gains each app's tools as it's connected. On Casama Cloud, Google's apps (Developer Preview, D-166) always go through Composio, and aren't offered without a key. Without a key (self-hosted default) nothing changes: the connect sheet offers Composio, Pipedream and Zapier over MCP with the person's own account.
- **Admin switch (Oliver: "a way to remotely set the default"):** the admin console's Services tab has **App connections**: *Casama's Composio account* (default when the server has a key) or *People's own accounts* (the hubs over MCP, even with a key). Stored in `instance_settings` (`connections`), read per request with a 10-second cache, so it takes effect without a restart; `GET`/`PUT /v1/admin/connections`, instance owner only.
- **Composio's API changed:** creating managed-auth connections on `POST /api/v3/connected_accounts` is retired; sign-ins now start with `POST /api/v3/connected_accounts/link` (`auth_config_id`, `user_id`, `callback_url`), and the project's managed auth config for an app is reused instead of made per connect. Verified live through to Slack's own sign-in.
- **Accounts:** Composio org **Casama** (under the Stackwares Composio account); project `casama_dev` for this Mac (key in the root `.env` and Vaultwarden) and project `casama_prod` for Casama Cloud (key in Vaultwarden only, set on the server when it exists). Separate projects keep test connections away from real users' accounts.
- **Tests:** catalog routing with and without a key and with a vendor client; connecting Slack asks Composio for its `slack` sign-in; the Gmail inbox path unchanged.

## D-174 Invite emails over SMTP (Zoho on casama.ai), Resend optional

- **Why:** invites and Casama's own notices could only go through Resend, so with no Resend key an invite just returned a code. Sign-in emails already go through Zoho (D-171), and self-hosters already set `SMTP_*` for Supabase Auth.
- **How:** the server takes `SMTP_HOST`, `SMTP_PORT` (default 587), `SMTP_USER`, `SMTP_PASS` and sends with nodemailer (pinned 10.2.1); port 465 uses TLS from the start, other ports require STARTTLS. Resend still wins when `RESEND_API_KEY` is set. The admin status page shows "SMTP". Self-host Compose passes the same `SMTP_*` it gives Auth to the API, so one SMTP setting covers sign-in emails and invites.
- **This Mac:** `EMAIL_FROM=Casama <hello@casama.ai>` and the Zoho login from D-171. Checked: a real message sent through Zoho. Zoho caps daily sending; move invites to Resend (or a Zoho plan with more) if volume grows.
- **Tests:** `apps/server/test/email.test.ts` (message shape, errors reach the caller, a real transport builds).

## D-175 No Shorebird: no over-the-air code patches

- **Before:** SPEC planned Shorebird for Flutter over-the-air patches (urgent Dart-only fixes pushed to installed apps without a store review); only `client/shorebird.yaml` (placeholder app id) and `scripts/shorebird-release.sh` existed, never set up.
- **Now:** dropped by Oliver. Mobile updates go through the App Store and Play (an urgent fix ships as an expedited review); desktop direct downloads keep updating through Sparkle and WinSparkle (D-159). Removed the config, the script, the SPEC rows and the NEEDS item. One less paid service and one less thing that can change shipped code outside store review.

## D-176 Three places: Chats, Inbox and Tasks; Settings behind the avatar, the computer in the chat

- **Before:** phones had six tabs (Bots, Inbox, Board, Computer, Settings, Search), squeezed to fit small phones; Inbox and the computer each had tabs of their own; Pages was a sidebar row on desktop but hidden on phones; Settings mixed personal settings, the workspace and bot plumbing in one long list; bot settings was one page of about 30 rows.
- **Now (Oliver: "simpler/fewer tabs"):** three places on every size: **Chats** (bots and group chats, the home screen), **Inbox** (what bots hand you) and **Tasks** (the ticket board, renamed). The routes stay (`/bots`, `/inbox`, `/tasks`).
  - **Phones:** the floating pill holds the three tabs; **search** is a round button beside it that opens the same search sheet as Cmd/Ctrl+K. The Chats header has the person's avatar (Settings) on the left, the workspace under the title (tap to switch, create or join), and "+" on the right; the separate workspace button is gone. Settings, the computer, search, Pages and Projects open full screen with a back button, which goes to the chats when there is nothing to pop (a link straight to them).
  - **Tablets:** the rail holds the same three places, then search, and the avatar at the bottom.
  - **Desktop:** the sidebar lists the chats, then Inbox and Tasks, then the person (avatar, name, "Settings"). The Pages and Computer rows are gone: Pages lives in the Inbox and on each bot; the computer is the panel beside a chat.
- **Settings** is four groups: **You** (quiet hours, wake word, bot steps, two-step sign-in, privacy, updates, open at login, language), **Appearance**, **Workspace** (switch, people, workspace settings, usage, billing, admin console) and **Connections** (model keys, integrations, skills, secrets, computers, device connections, use this computer), then Sign out.
- **Inbox** is one feed with filters (All, Needs you, Briefs, Pages) instead of three tabs; decisions (approvals, takeovers, suggestions, skill ideas) come first, then updates (briefs, notifications, published pages) newest first. `/inbox?tab=0` opens Needs you.
- **Tasks**: a project picker replaces the projects button; on phones tickets are a list grouped by status (long-press to move), columns stay on tablets and desktop.
- **Bots:** tapping a bot's name opens its **profile** (still `/bots/:id/settings`): four tiles (Computer, Memory, Routines, Apps), then Profile, Brain, Abilities, Schedule, and an Advanced group that starts collapsed. The chat header keeps Call, New chat and "…" (Conversations, Computer, Activity, Bot profile); a computer button with a live dot shows while the bot is working on its computer.
- **Why:** three to five tabs is the platform norm; the computer belongs to a bot, not the whole app; Settings is visited rarely and needn't take a tab. It also settles the tab bar before the Liquid Glass work replaces its look.
- **Tests:** `client/test/navigation_test.dart` (tabs and search button, avatar to Settings and back, links straight to Settings/computer/search keep a way back, tablet rail, desktop sidebar rows), plus the Inbox, Tasks and bot profile tests.

## D-177 Calls without a key of your own; the call orb

- **Problem:** every new workspace started with no live-call key, so the first call failed with "Live calls need a Google AI (Gemini) or OpenAI key" and no way forward. Self-hosters setting up a family or team server had to add the same key to every workspace.
- **Server-wide key:** `GOOGLE_AI_API_KEY` on the server. A workspace's own Gemini or OpenAI key still comes first (and `realtime_provider` still picks between them); with neither, calls use the server's key. Self-hosted, the server owner pays Google and the usage row isn't billable.
- **Casama Cloud (`BILLING_ENABLED`):** calls on the server's key are included and paid from the workspace's credits at Google's price (no markup for now). A workspace with no credits left gets 402 `out_of_credits` before the call starts (the app's paywall opens). The usage row is `billable` with `meta.key = "server"`, and the minute settlement turns it into a credit deduction. A subscription gate comes later and goes in the same check in `POST /v1/voice/session`.
- **Known gap:** the cost comes from what the app reports at hang-up (Gemini's token counts, or the seconds). A modified app could under-report or skip it; tighten with a server-side session record and a sweep before Cloud pricing is final.
- **Missing key:** `voiceSession` returns code `voice_key_missing` (409). The call screen shows **Get a free key from Google** (AI Studio) and **Add a Google AI key** (Model keys with Google picked).
- **Call screen:** the bot's own Casama cloud mascot as a talking Lottie (Oliver's choice, after a hand-painted orb and the `siri_orb` package's orbs). `scripts/casama-call-mascots.py` builds `client/assets/mascots/<name>-call.json` for the ten personalities plus `brand` (the app icon's lavender cloud, for bots without a mascot icon), reusing each personality's colours, eyes and orb from `scripts/casama-cloud-svg.py` and the SVG-to-Lottie converter `scripts/casama-mascot-lottie.py`. Each 8 s file has two markers: `listening` (0-4 s: soft smile, blinks, glances, a nod, the orb breathing) and `speaking` (4-8 s: a talking mouth in a syllable rhythm with a breath in the middle, small bounces, tail sway, the orb pulsing). Both loops start and end in the resting pose and the markers sit two frames inside the edges, so `CallMascot` (`client/lib/features/voice/call_mascot.dart`) can loop either and switch on `speaking` without a visible jump. It scales up to 5% with the bot's output loudness, fades to 55% when muted and turns greyscale when the call fails. About 200 KB per file (2.2 MB for all, mostly the baked cloud body). Reduced motion (and widget tests) show the still pose. **Captions** (the last three turns) replace the full transcript list and can be turned off. The D-144 talking avatar and its **Avatar** button are gone. `CallLevels` on `VoiceCall` carries loudness; OpenAI Realtime calls have none.
- **Tests:** `apps/server/test/voice-server-key.test.ts`, `voice-cloud-calls.test.ts`, the `voice_key_missing` case in `voice.test.ts`; `client/test/barge_in_test.dart` (orb phases, captions remembered, the missing-key card).
- **Audio (after the first device test: transcripts but no sound):** reply audio arrives in many small pieces and each one started its own SoLoud init and buffer stream at once, so only the first piece reached the playing voice. `DevicePcmAudio` now makes one stream (a memoised future), queues pieces in order on a future chain, and restarts the voice only when its handle is no longer valid. Calls start on the speaker (`record` already asks iOS for `defaultToSpeaker`; the app also selects the speaker after the mic starts). The call screen's audio button (`client/lib/core/call_audio.dart`, through `audio_session`) toggles speaker and earpiece, or lists connected Bluetooth and wired headsets: iOS uses `overrideOutputAudioPort` and `setPreferredInput`, Android 12+ `setCommunicationDevice`, older Android the speakerphone switch. Phones only; desktop and web play through the system output.
- **Tool activity on calls:** the raw tool-name pill ("memory__search") is replaced by `CallActivity` (`client/lib/features/voice/call_activity.dart`): a card per tool, newest at the bottom, at most three, above the captions (scrolling, at most half the space on small phones). Each card has an icon and colour per kind of tool, a plain-language title that changes tense when done ("Searching your memories" to "Searched your memories", an ICU select per tool in the ARB file; connected-app tools read "Using github" with the tool name under it), the quoted query or name from the arguments, a spinning gradient arc and a shimmer while it runs, a seconds counter after 3 s (both driven by the call's frame ticker, so no timers), a check, cross or shield popping in, a light haptic tick when done and a firmer one when it needs the person, and a live-region label for screen readers. Done cards fold away after 2.6 s, failed and still-working ones after 5 s. **Approvals in the call:** a tool that returns `waiting_approval` turns its card amber with **Allow** and **Not now**, which call `decideApproval` and then `VoiceCall.tellModel` (a user-role note to Gemini via `clientContent`, or an OpenAI `conversation.item.create` plus `response.create`), so the bot acknowledges it and carries on.

## D-178 Computers sleep after 5 idle minutes; takeover desktops go back to headless

- **Problem:** computer time is Casama Cloud's biggest cost (docs/COSTS.md). Every finished task kept its computer running for 10 idle minutes, and a computer switched to the desktop for one takeover stayed a desktop (about four times the memory) for good.
- **Decision:** `IDLE_SLEEP_MS` is 5 minutes. Open terminals, running commands and live viewers (the stream touches the computer every minute) still keep it awake, and waking restores its files. `request_takeover` sets `computers.desktop_for_takeover` when it switches a headless computer to the desktop; when that computer next sleeps with no pending or taken takeover, it goes back to headless. Picking a profile in the app clears the flag, so a desktop someone chose stays.
- **Tests:** `apps/server/test/computers.test.ts` (takeover desktop back to headless; a chosen desktop stays), `live.test.ts` (takeovers).

## D-179 Free web search from the server's own SearXNG

- **Problem:** `web.search` needed each workspace's own Brave Search or Tavily key, so most bots couldn't search, and offering search on Casama Cloud's key would cost $5–8 per 1,000 searches (docs/COSTS.md).
- **Decision:** the worker's `searchFor` uses the workspace's own Brave or Tavily key first, else the server's SearXNG (`SEARXNG_URL`), a free, self-hosted metasearch engine. Compose has it as the `search` profile (`searxng/searxng`, pinned, internal network plus outbound internet, no published port, rate limiter off, JSON results on); `./install.sh --search` enables the profile and writes `SEARXNG_URL=http://searxng:8080`. The configured address is trusted, so it isn't sent through the egress filter. Each provider states its price per query (Brave $0.005, Tavily $0.008, SearXNG $0) and `search_queries` usage records it, instead of a flat $0.005.
- **Trade-off:** SearXNG scrapes public engines, which sometimes rate-limit or show captchas (DuckDuckGo did on the first try); it asks several at once, so results still came back. Brave or Tavily stay the reliable choice for heavy use.
- **Tests:** `packages/agent/test/searxng.test.ts` (JSON request, duplicate links dropped, errors; plus a live check against a real instance when `SEARXNG_TEST_URL` is set, run against the pinned image).

## D-180 Computer time is priced at what the provider charges

- **Problem:** `computer_seconds` usage was priced at a placeholder $0.01 per vCPU-hour, 8× below what E2B and Daytona charge for a 2 vCPU / 4 GiB computer ($0.166 an hour). On Casama Cloud that usage is billable, so every hosted computer-hour lost money (docs/COSTS.md).
- **Decision:** usage is priced per provider as vCPU-hours plus GiB-hours of the computer's size (`computerCostUsd` in `packages/agent/src/computers.ts`). Defaults: E2B and Daytona at their published per-second prices ($0.0504 per vCPU-hour, $0.0162 per GiB-hour); Docker on our own servers at $0.003 per vCPU-hour and $0.005 per GB-hour (a Hetzner CPX42 spread over what it holds, so 1 vCPU / 1 GB ≈ $0.008 an hour); local computers free; Cloud Connect computers $0.05 per vCPU-hour. `COMPUTER_RATES` (JSON by provider) overrides them, for example after moving to a dense server.
- **Known gap:** E2B sizes come from its template, so the price follows the size recorded on the computer; keep the templates at the recorded sizes.
- **Tests:** `packages/agent/test/computer-rates.test.ts`.

## D-181 Live model prices from OpenRouter; no model on OpenRouter is free by accident

- **Problem:** model prices were a hand-written table. Models it didn't know got a guess, and open-weight families (Llama, Qwen, Mistral, Gemma, DeepSeek) were priced at $0 everywhere, including on OpenRouter, where Casama or the person pays for them. The `tokens_in` ledger rows also ignored cached tokens, so they disagreed with the run's cost.
- **Decision:** the worker loads OpenRouter's public model list (`https://openrouter.ai/api/v1/models`; no key, nothing about the server sent) at start and once a day, keeping the last good list on failure. `capabilitiesOf(model, provider)` prefers a live price for the exact model id (OpenRouter ids such as `qwen/qwen3-235b`), including its own cache read and write prices. Models called on the provider's own API are looked up under their OpenRouter name (`claude-sonnet-5-5` on Anthropic is `anthropic/claude-sonnet-5.5`), so the stale direct prices in the table only apply when the list doesn't have the model. On OpenRouter a model with no known price gets the default price ($1 / $3 per million) unless its id ends in `:free`; local and custom endpoints still record $0. Ledger rows now split the cache-aware cost: output at its price, input the rest. `MODEL_PRICES_URL` points at another list, `off` turns the refresh off.
- **Tests:** `packages/agent/test/live-prices.test.ts`.

## D-182 Expert options fold under one "Advanced" section per screen; no power-user mode

- **Before:** everyday and expert options sat in one list on many screens: Settings (about 25 rows), workspace settings (about 22: phone, payments, encryption, memory backend, MCP, Git sync…), the routine editor (cron, timezone, webhooks), the add-key form (17 providers, base URLs), device connections, "use this computer", people (raw invite tokens), the computer (terminal, checkpoints).
- **Asked (Oliver):** a switch for power users, or keep advanced options somewhere.
- **Decision: no global switch.** Each screen keeps its expert options in one folded **Advanced** section at its end (`client/lib/ui/advanced_section.dart`, `AdvancedSection`). It opens in place and stays open on that device once opened (`advancedOpenProvider`, SharedPreferences `advanced.open`), so people who use the expert options open each section once.
- **Why not a mode:** with a mode, a hidden option doesn't exist on screen, so a bot or a help page saying "Settings → Secrets" stops making sense, and every screen exists twice for testing. A remembered fold gives power users the same result without hiding anything.
- **What goes in:** technical setup (MCP, OpenAPI, A2A, webhooks, cron, env vars, base URLs, raw ids and tokens), self-host and infrastructure settings (encryption, memory backend, secret store, payments plumbing), rarely used extras. **What stays out:** the everyday path and anything needed to fix a problem or leave (sign out, sharing with people, archive, billing plan, members). Nothing is removed, only moved; routes and keys are unchanged, and a fold beside one of its open pages shows open (`forceOpen`).
- **Settings:** You (quiet hours, wake word, two-step, privacy), Appearance (light/dark and Themes; scheme, fonts and background are on the Themes page), Workspace, Connections (model keys, integrations, skills), then Advanced (secrets, computers, device connections, use this computer, bot steps, updates, open at login, language) and Sign out.
- **Elsewhere:** workspace settings, people, billing, usage, the add-key form, integrations and their tool permissions, device connections, use this computer, the bot profile (sharing and archive stay visible; activity, action rules, watchers, plugins, chat apps, links, A2A, replays, history, template, re-run setup fold), Create bot (key and model fold when a key exists), the routine editor (GitHub/webhook triggers, cron and timezone fold; schedules read in words), and the computer (terminal and checkpoints behind its Advanced toggle). The chat header no longer shows the model when idle.
- **Tests:** `client/test/advanced_section_test.dart` plus each screen's tests.

## D-183 Passkeys on casama.ai; SSO only when set up; sign-ups confirm their email

- **Passkeys:** Supabase Auth's passkeys (beta) are on, relying party `casama.ai` (`[auth.passkey]`, `[auth.webauthn]` in `supabase/config.toml`). The apps are tied to that domain by `site/.well-known/apple-app-site-association` (`webcredentials`, `V8V5US964Z.ai.casama.app`, with `webcredentials:casama.ai` in `Runner.entitlements`) and `site/.well-known/assetlinks.json` (`get_login_creds`). The system sheet is the `passkeys` plugin (`client/lib/core/passkeys.dart`); Supabase's JSON options go to it as they are. The sign-in sheet shows "Sign in with a passkey" when the server's `/auth/v1/settings` has `passkeys_enabled` and the device can use them (iOS, Android, web; not when creating an account), and Settings → Passkeys adds, renames and removes them.
- **Limits:** the apps only accept passkeys for `casama.ai`; a self-hosted server on its own domain gets passkeys on the web only, and the apps say so. macOS isn't offered yet (the entitlement needs a signed build). Android origins are `android:apk-key-hash:` of each signing certificate: today the debug key, which release builds also use. Add the release and Play app signing keys to both `rp_origins` and `assetlinks.json` when they exist.
- **SSO:** "Continue with SSO" shows only when the server reports `saml_enabled`; before, it was always there and failed because no identity provider was set up.
- **Email:** `enable_confirmations = true`. The server is public now, so an address must be proven before it gets an account. A password sign-up goes to the same check-inbox step as a sign-in email (link or code). Evals create an already-confirmed user through the admin API.
- **Tests:** `client/test/passkeys_test.dart`, `client/test/privacy_test.dart`.
- **Silence during tool calls:** tested live on `gemini-3.8-live` with a 3-second tool: by default the model calls the tool about 0.35 s after the question and says nothing until the result. `behavior: NON_BLOCKING` (with `scheduling: WHEN_IDLE`) or `BLOCKING` made no difference. An explicit instruction did, in every run: "Before you use a tool, always say a few words first so the caller isn't left in silence... then wait for the result" gave "Let me check your watering schedule for you." (about 2 s of audio) before the tool call. That sentence is now in the call instructions. A voice tool also answers "still working" after 12 s instead of 25 s (the result then lands in the chat), so a slow tool doesn't leave a long silence.

## D-184 Gallery: open-source looks and skills, hosted as a static site on Cloudflare

- **Decision** (Oliver asked, 2026-11-11): themes, color schemes, wallpapers and skills come from one open-source gallery repo (`stackwares/casama-gallery`) that Casama curates and anyone can contribute to by pull request. A merge builds `index.json` plus the item files and deploys them as a static site at `gallery.casama.ai`. The server reads the index (`GALLERY_URL`, ETag, every 15 minutes) and serves `/v1/gallery`; the app browses, previews and saves items on the device. Spec: SPEC "### Gallery".
- **Hosting: Cloudflare static assets, not R2, our server or Supabase Storage.** The content is small and public (JSON, Markdown, preview images and wallpapers of up to 2 MB), changes only on a merge, and casama.ai's website and docs already deploy the same way (`site/`, `docs-site/`). Static assets cost nothing, have no bandwidth charge, are served from Cloudflare's edge and deploy from CI, and the same deploy gives a browsable web gallery. R2 also has no egress fee but needs a separate upload step and a bucket token in CI; it becomes the image store only if images outgrow the static limits (20,000 files, 25 MiB each). Our own server would put every app's image downloads on one machine's bandwidth and on its uptime. Supabase Storage charges for egress ($0.09/GB beyond the quota) and ours runs on the API server.
- **Why a separate repo:** contributors edit JSON and Markdown and get CI feedback without the Flutter and Node toolchain; licenses differ from the app's (CC0 / CC-BY-4.0 for looks, MIT / Apache-2.0 for skills); and removing an item doesn't need an app or server release.
- **Data only:** nothing in the gallery runs in the app (D-092, no WebViews). Fonts are limited to the app's font list, and color schemes must pass WCAG AA contrast. Skill scripts run only on the bot's computer, as with GitHub imports, and need a second maintainer's approval.
- **Unsplash and the gallery:** Unsplash's API terms require hotlinking `photo.urls` and forbid apps that replicate Unsplash (wallpaper apps). Photo search inside Casama's Background screen is fine, since Unsplash gives Trello's board backgrounds as the allowed example. Gallery wallpapers are contributors' own images, not re-hosted Unsplash API photos. A self-hosted server needs its own Unsplash key (their terms bar sharing credentials), so photo search stays off there until one is set.
- **Offline and fallback:** the bundled `skills/` catalog and the built-in presets stay in the release. Installed gallery items are copies on the device or in the workspace, so retiring or removing one from the gallery doesn't break anyone.
- **Built:** the checker is `scripts/casama-gallery-check.mts`, the seed catalog is `gallery/`, the API is `GET /v1/gallery` and gallery skill install on `POST /v1/skills/install`, and Settings → Themes, Color scheme, Background and Skills open the Gallery. `GALLERY_URL=off` turns it off. `gallery.casama.ai` is a Cloudflare Worker (`gallery/wrangler.jsonc`), deployed 2026-11-11, serving the seed catalog.

## D-185 Images default to Gemini Nano Banana 2.1 on OpenRouter

- **Why** (Oliver asked, 2026-11-11): pick the cheapest image model that still looks great. Qwen Image 3 Pro was $0.04 and 14th of 84 on LM Arena (8 Nov) and 20th on Artificial Analysis. Gemini Nano Banana 2.1 is about $0.034 at 1K, 7th on LM Arena and 6th on Artificial Analysis. GPT Image 2.6 at medium is about $0.043 and ranks 2nd–4th on LM Arena; its max tier leads both boards at about $0.21. Seedream 5.0 Pro is $0.045 at 1K and $0.09 at the 2K rate, and ranks behind both.
- **Decision:** a workspace with an OpenRouter key gets images from `google/gemini-nano-banana-2.1` with `resolution: "1K"` (2K is $0.050, 4K is $0.113). The usage row records OpenRouter's `usage.cost`, or $0.0336 when the response has none (1,120 output tokens at $30 per million). Without an OpenRouter key, images stay on fal with Seedream 4.5. Video stays on fal.
- **Tests:** `packages/agent/test/media-prices.test.ts`, the OpenRouter image case in `apps/server/test/autonomy.test.ts`.

## D-186 Casama Cloud runs models on one shared OpenRouter key

- **Decision** (Oliver asked to build it and left the five choices open, 2026-11-11): one OpenRouter key for Casama Cloud, `CLOUD_MODEL_UPSTREAM_KEY`, the same key Cloud Connect already uses. A workspace's own chat key comes first. With none, the welcome chat and new bots use this key (`00000000-0000-4000-8000-0000000000c1`, labeled "Casama Cloud"). It is not a row people can rename, test or delete.
- **Why one key:** the server already resolved this id, and OpenRouter's Casama workspace caps ($20 a day, $150 a month) plus the key's own $10 daily cap are the hard stop. One key per workspace can come later if one workspace can burn the shared cap. The key's $10 cap is a safety net while there are no users; raise it before launch.
- **Price:** a call on this key records OpenRouter's `usage.cost` (the price list only when a response has none). With billing on, the workspace is charged that cost × 1.055 (OpenRouter's fee on credits) × 1.3 (docs/COSTS.md). The usage rows are billable, with `meta.key = "server"`. A self-hosted server that sets the key pays OpenRouter and the rows are not billable.
- **Who can use it:** on Casama Cloud the key runs only the model Casama assigns (Muse Ember, or `DEFAULT_MODEL_OPENROUTER`). A saved choice of any other model is rewritten to that one before the call, including a cheap model or a fallback on the same key. A workspace's own key keeps whatever model they picked. A self-hosted server that set the key is locked the same way (Oliver, 2026-11-11: the shared key must never surprise whoever pays for it): one model (`DEFAULT_MODEL_OPENROUTER`), and the server's thinking level (`DEFAULT_REASONING_EFFORT`) whatever a bot or a saved choice asks for. Output on this key is capped at 4,096 tokens as a ceiling a caller cannot raise. A server that leaves the key unset has no shared key: people add their own. Each call sends the workspace id as OpenRouter's `user` and `provider.data_collection: "deny"`.
- **Before the call:** credits minus usage not yet settled must cover a worst-case estimate (8k input, and output tripled because reasoning models write past the cap). A free workspace can be charged $0.25 of this key per UTC day, a paid one $10. A used-up OpenRouter cap comes back as 403 `openrouter_key_limit`. A workspace's own key still runs when credits are gone; a hosted computer does not.
- **App:** Model keys lists "Casama Cloud" first, with no remove. On Casama Cloud the model field shows Casama's model and does not open, including on a workspace's own key (D-188). A self-hosted server's picker on the shared key shows its one model and does not accept a typed id. Onboarding skips "add a key" because the list is not empty. A bot cannot change the model on Casama's key (`bots.update` / `bots.create`).
- **Tests:** `packages/domain/test/cloud-models.test.ts`, `packages/domain/test/budget.test.ts`, `packages/agent/test/openrouter-cloud.test.ts`, the credit case in `apps/server/test/billing.test.ts`, `client/test/cloud_model_picker_test.dart`.
- **Superseded in part by D-188 (2026-11-12):** with billing on, every bot runs on Casama's key, including one created with the workspace's own key, so "a workspace's own key still runs when credits are gone" holds only on a self-hosted server. The billing test now checks that a new bot gets Casama's key and that no credits stops its runs.
- **CI (2026-11-12):** turbo's strict environment mode had kept `PG_BIN` and `SKIP_DOCKER_TESTS` from the tests; `turbo.json` now declares the variables tests read. CI's Flutter is pinned to 3.47.9, the version the app ships with, because Flutter 3.50 deprecates `package:flutter/material.dart` for the `material_ui` package (288 analyzer infos). Moving to `material_ui` is a follow-up. CI's backend job also moved from Postgres 16 to 17, the version production and local development use: drizzle-kit's schema pull orders tables and attaches policy conditions differently on 16, so the generated-code check could never match.

## D-187 Muse Ember for background work; Gemini Live for every call; Gemini for read-aloud

- **Why** (Oliver, 2026-11-11): the model Casama picks itself should be Muse Ember, and calls should be Gemini Live. Dictation and read-aloud should move to Google only when Google is cheaper.
- **Background work:** summaries, memory and briefs on an OpenRouter bot use `meta/muse-ember` when the bot has no cheap model of its own, then fall back to its main model. A direct OpenAI, Anthropic or Google key still uses that provider's small model (GPT-6 Luna, Haiku 5.5, Gemini 3.5 Flash-Lite), because Muse Ember is an OpenRouter model.
- **Calls:** in-app calls and phone calls use Gemini Live (`gemini-3.8-live`) when the workspace has a Google AI key, otherwise the server's `GOOGLE_AI_API_KEY`. OpenAI Realtime is used only when neither exists. A bot setting no longer switches a call onto OpenAI while a Google key is available.
- **Dictation stays on OpenAI.** Gemini 3.5 Transcribe lists about $0.003 a minute of audio and about $0.002 more for the transcript text, so about $0.005 a minute. `gpt-4o-mini-transcribe` is $0.003. Deepgram stays the optional second key.
- **Read aloud** uses Gemini 3.8 Flash-Lite TTS (`gemini-3.8-flash-lite-tts`) when a Google AI key exists. It is about $0.009 a minute of speech through 2026-12-31 ($6 per million audio tokens, 25 tokens a second) and about $0.018 after that, against about $0.018 for `gpt-4o-mini-tts` and about $0.032 for ElevenLabs Flash. The usage row prices the WAV's duration. Other providers stay at $0.015 per thousand characters. A saved voice id that isn't a Gemini voice uses Kore.
- **Tests:** `packages/agent/test/model-costs.test.ts`, `packages/agent/test/voice-speech.test.ts`, `apps/server/test/voice.test.ts`.

## D-188 Casama Cloud's models are fixed, and the owner can change them live

- **Why** (Oliver, 2026-11-11): on Casama Cloud a person should not pick models. When one stops working, Casama switches it without shipping a new app or restarting.
- **Who it applies to:** only when billing is on (`BILLING_ENABLED`), which is Casama Cloud. A self-hosted server is unchanged: each workspace keeps the models it chose, and this setting is ignored.
- **What is fixed:** chat and background work run on Casama's OpenRouter key. Images, calls (Gemini Live, and OpenAI Realtime only when there is no Google key), read-aloud, dictation, embeddings and video use the assigned ids. A bot's saved model, and a request that names another one, is replaced on each run. The model field in the app does not open. Voice provider menus are hidden.
- **How to change them:** the instance owner, in the admin console under Services, or `PUT /v1/admin/models`. The row is `instance_settings` key `cloud_models`. Each process caches it for 10 seconds, so a change reaches chat, images and calls without a restart. With no row, the built-in defaults stand (Muse Ember, Nano Banana 2.1 at 1K, Gemini Live, Gemini 3.8 Flash-Lite TTS, `gpt-4o-mini-transcribe`, `text-embedding-3-small`, LTX on fal).
- **Tests:** `packages/domain/test/cloud-model-assignment.test.ts`, `apps/server/test/cloud-models.test.ts`, `client/test/cloud_model_picker_test.dart`.

## D-189 Video is Gemini Omni Flash 1.2

- **Why** (Oliver, 2026-11-11): among models that still rank with the leaders, Gemini Omni Flash 1.2 at 720p is the cheapest, about $0.07 a second. Wan 3.0 leads Artificial Analysis at $0.10. MiniMax H3 is close at $0.08. Grok Imagine 1.5 Lite is $0.03 and around 30th. Seedance 2.5 is in the top group and costs several times more. The previous default, LTX on fal, sits near the bottom of that board.
- **Decision:** a Google AI key (the workspace's, otherwise the server's `GOOGLE_AI_API_KEY`) generates video with `gemini-omni-1.2-flash` through the Interactions API, at 720p, 3 to 15 seconds, with sound. Landscape and square are 16:9; portrait is 9:16. The clip comes back in the response and is saved on the bot's computer. The usage row is Google's reported cost, or $0.0695 a second. Without a Google key, video stays on fal. Casama Cloud's video setting defaults to this model id.
- **Tests:** the Gemini case in `packages/agent/test/media-prices.test.ts`.

## D-189 The gallery is chosen by looking: previews everywhere, from the list alone

- **Decision** (Oliver asked for the best gallery design with previews, 2026-11-11): every look in the gallery is drawn the way the app draws it, so people pick by seeing, in the app and on the web.
- **Previews need no extra requests.** `index.json` now carries each look's `document` (theme, scheme or wallpaper JSON, a few hundred bytes) and each skill's `description` and `icon` (a Lucide name in `item.json`). Both checkers write them; `GalleryItem` in the contract gains the three optional fields; the API passes them through. Image wallpapers carry a `thumb` (at most 200 KB) for cards, checked like the full image.
- **App (Settings → Gallery):** search, kind chips with counts that follow the search, and a light/dark preview switch in the header. "All" shows a Featured row (one theme, wallpaper and scheme in turn, so it doesn't repeat the rows below), then one row of each kind with See all; phones scroll each row sideways. Themes are a small Casama chat in the theme's colors, fonts and wallpaper, drawn at a fixed size and scaled like a screenshot (`GalleryChatPreview`); color schemes are fields of their own colors (`GallerySchemeSwatch`); wallpapers are phone-shaped; skills are rows with their icon and description. The detail shows the look as it would apply on this device, with its own light/dark switch, what it brings, tags that search, Use drawn in the colors it applies (pinned below the scrolling content), Copy link and Report. Loading keeps the final layout in flat grey; offline and empty states say what happened and offer Try again or Clear search. A theme's colors get their own scheme id (`gallery:theme-<id>`), so a theme and a scheme with the same name never overwrite each other.
- **Web (gallery.casama.ai):** the same previews in plain JavaScript (`gallery/gallery.js` and `gallery.css`), with the app's palettes, pattern layout and scheme derivation approximated from the app's own output. casama.ai's colors and type keep the site one brand; the frame is neutral so the previews carry the color, and the teal is only on Get Casama and Open in Casama. Tabs, search, the light/dark switch and a detail dialog with deep links (`#theme/lagoon`); a contribute section with the steps and a real `item.json`. Pattern glyphs are Lucide icons embedded as data (ISC, credited).
- **Share page (casama.ai/gallery/<type>/<id>):** what someone without the app sees from a shared link: the item drawn by the same script, its author and license, Open in Casama, Get Casama, and See it in the gallery. `casama.ai/gallery` goes to the gallery.
- **Starter content:** 6 color schemes, 7 themes, 6 pattern wallpapers and 3 image wallpapers (Aurora, Dune, Fog, and Dusk redrawn), painted in code by Casama under CC0, plus 5 of Casama's own skills (Apache-2.0). 33 items in all.
- **Tests:** `client/test/gallery_test.dart`, `apps/server/test/gallery.test.ts`, `packages/domain/test/gallery.test.ts`.

## D-190 Missing values show an em dash

- **Decision**: a text value from the server that is null, empty, blank or the word "null" is never shown as it is. `client/lib/core/display_text.dart` has `isUsable` and `orPlaceholder()`; screens hide a line that only adds detail and show `—` (`kMissingValue`) where a value must appear, or a better word when there is one ("Untitled chat").
- **Why the em dash**: it is the usual mark for "no value" in every language, so it needs no translation, and bot history already used it.
- **Tests**: `client/test/display_text_test.dart`.

## D-191 Text size follows the system setting up to 1.3x

- **Decision**: the app follows the system text size but caps it at 1.3x (`kMaxTextScale` in `client/lib/ui/text_scale.dart`, applied in the builder of both `MaterialApp`s). Smaller sizes are untouched.
- **Why 1.3x and not 1.1x**: 1.3x is the largest standard size on both platforms (Android's "Largest" before Android 14; iOS xLarge 1.12x and xxLarge 1.24x pass through, xxxLarge 1.35x is barely reduced). A 1.1x cap would undo the setting for most people who raised it. Only the accessibility sizes (iOS AX1–AX5, 1.65x–3.1x; Android 14 up to 2x) are held at 1.3x, because fixed-height rows, chips and the tab bar overflow there.
- **Tests**: `client/test/text_scale_test.dart`; `client/test/phone_layout_test.dart` runs every screen at the cap on a 375x667 phone.

## D-192 What's new after an update

- **Decision:** the first time the signed-in app opens on a new version, a sheet lists what changed since the version the person last saw, in plain words (a bottom sheet on phones, a dialog on larger windows, one "Got it" button). It never shows on a fresh install (the version is only remembered), never over sign-in, the welcome chat or onboarding (it wraps only the signed-in shell), and not over the name or notifications pages or another sheet (then it waits for the next open). It shows once: the version is saved as seen the moment it appears (SharedPreferences `whatsNew.lastSeenVersion`). Someone who skipped versions sees every version's lines in between, newest first (compared with `pub_semver`).
- **Where the words come from:** `whatsNewByVersion` in `client/lib/features/whats_new/whats_new.dart`, with each line a string in `app_en.arb`. CHANGELOG.md stays the developers' record. The lines are bundled, so fixing a typo needs a release; the server could serve them later.
- **Every version needs lines:** `client/test/whats_new_test.dart` fails until pubspec.yaml's version has an entry, so a release can't ship without its notes. The 0.8.0 lines are never shown (no earlier build has this feature, so every install of it counts as fresh); the first sheet people see is the next version's.
- **Tests:** `client/test/whats_new_test.dart`.

## D-193 The web app lives at app.casama.ai

- **Decision (Oliver: "we have a domain already, decide the url"):** the hosted web app is served at **https://app.casama.ai**. casama.ai stays the public site; api/auth (and api-dev/auth-dev) stay as in D-172.
- **Where it shows:** the web preview card tags in `client/web/index.html` (`og:url`, `og:image` = `https://app.casama.ai/og-image.png`, `twitter:image`). Self-hosters replace that address with their own.

## D-194 Dictation and memory search on the shared OpenRouter key

- **Decision** (Oliver, 2026-11-11: "no setup required"; he picked the cheapest OpenAI dictation model and left memory search to us): a workspace without its own dictation key (OpenAI or Deepgram) dictates on the server's shared OpenRouter key (`CLOUD_MODEL_UPSTREAM_KEY`) with **Whisper Large V3 Turbo** (`openai/whisper-large-v3-turbo`, $0.0002 a minute, the cheapest OpenAI transcription model on OpenRouter and tied for the cheapest of all 31). It goes through OpenRouter's OpenAI-compatible `/audio/transcriptions`, which returns `usage.seconds` and `usage.cost`. A workspace's own key still comes first and keeps its model.
- **Memory search:** a workspace without its own OpenAI key embeds memories on the shared key with OpenAI's `text-embedding-3-small` through OpenRouter. It gives the same 1536-dimension vectors every table already stores, so memories embedded on a workspace's own OpenAI key and on the shared key stay searchable together, and it costs $0.02 per million tokens (about $0.0000006 a memory). Free embedding models were passed over: different dimensions would split the index, and the Casama privacy guardrail blocks providers that train on prompts.
- **Billing:** on Casama Cloud a dictation on the shared key is a billable `stt_seconds` row at OpenRouter's reported cost × 1.055 × 1.3 (`meta.key = "server"`); self-hosted it is recorded at cost and not billable. Embeddings are not metered (negligible; see docs/COSTS.md).
- **Unset key:** a server without `CLOUD_MODEL_UPSTREAM_KEY` keeps the old behaviour: dictation asks for an OpenAI or Deepgram key, and memory search is full-text only.
- **Verified live** (2026-11-11, the Casama server key): a 2.8-second clip transcribed correctly for $0.0000093; one embedding returned 1536 dimensions for $0.00000006.
- **Tests:** the dictation case in `packages/agent/test/openrouter-cloud.test.ts`; `apps/server/test/voice.test.ts`.


## D-195 Only a person keeps a computer awake, not an open screen

- **Problem:** D-178 sleeps computers after 5 idle minutes, but an open live view touched the computer every 5 s and an open terminal every 60 s, and `sleepIdle` also kept any computer with an open terminal awake. A desktop window behind others, a hidden browser tab or a phone left on the table kept a computer (Casama Cloud's biggest cost) running forever.
- **Decision:** what keeps a computer awake now:
  1. A bot run using it (run.ts touches it) and running commands (`runningExecs > 0` in `sleepIdle`), as before.
  2. Live view: a control message from the person (`control/*`, `clipboard/set`, `keyboard/*`, `screen/set`), or the app's presence beat `{"event":"presence"}`. Pointer and key input travels on the WebRTC data channel, which the server can't see, so presence is what carries it. Signaling (`signal/*`) does not count.
  3. Terminal: keystrokes (binary frames, and any text frame except computerd's `{"type":"resize"}`), or the presence beat.
  4. Waking it (opening the stream, Resume, any API call that runs `ensureRunning`).
  The proxies touch at most once per 30 s per connection (`TOUCH_THROTTLE_MS`, `apps/server/src/api/keep-awake.ts`) and never forward presence to the computer. An open terminal alone no longer counts in `sleepIdle`: computerd's `open_terminals` is just the number of open terminal sockets, so a foreground command someone typed is only visible as one. That case stays awake through `last_active_at` instead (keystrokes, and presence while the person is in the app), and sleeps 5 minutes after they leave. Commands that must outlive the person belong to the bot (`runningExecs`).
- **App:** `client/lib/core/user_activity.dart` holds the timings (`KeepAwake`): presence every 60 s, only while the window is visible and focused (`AppLifecycleState.resumed`) and the person touched the app (pointer down, move, hover, scroll or a hardware key, seen through a global pointer route and `HardwareKeyboard`) in the last 3 minutes. Watching a bot work counts while the person is around. The live view (full screen and the side panel) asks "Still watching?" over a dimmed view after 5 minutes without input (before an idle computer would sleep and drop the stream), unless a bot that uses this computer is working (fresh bot statuses); unanswered for 60 s it closes the stream and shows "Paused to save power" with Resume, which reconnects and wakes the computer. The live view closes its stream on `paused` and `hidden` (background app, hidden browser tab, minimised window) and reconnects on `resumed`, except after a pause to save power. The terminal only stops its presence beat.
- **Trade-off:** with no input the computer sleeps 7–9 minutes after the last input (up to 3 minutes of presence, the 5-minute idle sleep and the 1-minute idle check), so without a working bot the stream usually ends before the 10-minute question; the question matters when a bot finishes during a long watch. A long build typed into the terminal sleeps 5 minutes after the person leaves the app.
- **Tests:** `apps/server/test/live.test.ts` and `computers.test.ts` ("keep-awake": no touch on an open idle socket, input and presence touch with the throttle, presence and resize handling, presence not forwarded); `packages/agent/test/computers-idle.test.ts` (an idle open terminal sleeps, a running command doesn't); `client/test/keep_awake_test.dart`.

## D-196 The web app ships as WebAssembly

- **Decision (Oliver: "go all in on web wasm", then "a release, deploy or publish must always be wasm"):** every release build, image, deploy and publish of the web app runs `scripts/build-web.sh`. That script compiles with `--wasm` last (a flag that turns Wasm off is dropped) and refuses to finish unless `build/web/main.dart.wasm` exists and `flutter_bootstrap.js` offers the `dart2wasm` build. In a git checkout it also fails if any other file outside the docs compiles the web app. CI (`.github/workflows/ci.yml`) and the self-host image (`client/Dockerfile.web`) both call it, so a JavaScript-only `flutter build web` is not a release. Browsers with WebAssembly garbage collection run the dart2wasm build on Flutter's skwasm renderer; others (older Safari) get the dart2js/CanvasKit build that ships beside it, picked by `flutter_bootstrap.js`.
- **Headers:** `client/web/_headers` (copied into `build/web`, read by Cloudflare and Netlify) and the Caddy config in `client/Dockerfile.web` send `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: credentialless` (plus `worker-src 'self' blob:` in CSP for the skwasm render worker), so the page is cross-origin isolated and skwasm renders on its own thread. `credentialless`, not `require-corp`, so images from other sites still load (without cookies). `same-origin` is safe because every web sign-in (Google, Apple, app connections) is a redirect or a new tab the app polls, never a popup that talks back to its opener. Hosts that ignore `_headers` must set these by hand; without them the app still works, single-threaded.
- **Checked (2026-11-11):** the build compiles with no Wasm warnings (`main.dart.wasm` 10.9 MB, plus the 23 MB JS build beside it). Served with those headers it loads `main.dart.wasm` and `skwasm.wasm` with `crossOriginIsolated` true, shows the sign-in screen, and calls the API and auth servers normally.
- **Development:** `flutter run -d chrome` stays on the debug JavaScript compiler for hot reload; use `flutter run -d chrome --wasm` to try the Wasm build locally. A local release build is `scripts/build-web.sh`, the same command CI and the image use.

## D-197 Published images, and how Casama Cloud is configured

- **Images:** they live at `ghcr.io/stackwares/casama/<name>` (`server`, `supervisor`, `egress-proxy`, `turn`, `backup`, `computer-headless`, `computer-desktop`). The old `ghcr.io/casama-dev` names were never published. `scripts/publish-images.sh` builds one commit (never the working tree) for `linux/amd64` and `linux/arm64` and pushes `:<sha>`, `:edge` and `:latest`. `./install.sh --pull [tag]` sets `CASAMA_REGISTRY` and `CASAMA_VERSION` and pulls those images instead of building. The supervisor's default computer images use the same prefix.
- **Behind a tunnel:** `--behind-proxy --domain <name>` serves plain HTTP and sets `HTTP_BIND=127.0.0.1`. Docker-published ports skip `ufw`, so binding to every interface would serve plain HTTP on the server's public IP. `--turn-host` is the name that reaches the machine directly. Live view only needs **3478 UDP and TCP**: coturn relays media inside the process, so the 49160–49260 range stays unpublished and closed.
- **Worker role:** the installer generates `WORKER_DB_PASSWORD`. Compose sets `WORKER_DATABASE_URL` to `postgres://casama_worker:…@db:5432/postgres`.
- **Abuse controls:** the installer generates `AUTH_HOOK_SECRET` (the same value on Auth and the API). Casama Cloud's non-secret settings are `deploy/casama-cloud/settings.env`, applied with `--settings`: `INSTANCE_ADMIN_EMAILS=admin@casama.ai`, the sign-up hook, App Check project number 278631205206 with proof of work as the fallback, `EGRESS_ABUSE=on`, billing and Cloud Connect on, the OAuth redirect `https://api.casama.ai/oauth/callback`, and Zoho SMTP host settings. Secrets stay in Vaultwarden and are written into `infra/compose/.env` on the server. The runbook is `deploy/casama-cloud/README.md`.
- **Backups:** `./install.sh --backups` starts the `backup` profile. Once a day (03:30 UTC) it dumps Postgres, optionally the computer archives, encrypts every file with age when `BACKUP_AGE_RECIPIENTS` is set, and uploads to any S3-compatible bucket. The `.env` is uploaded only when encrypted. A failed encryption deletes the folder and uploads nothing. Casama Cloud uses the R2 bucket `casama-backups`, prefix `casama-cloud`, and keeps 14 days. The private age key stays on this Mac and in Vaultwarden, never on the server.
- **Still Oliver, at the vendor consoles:** the OAuth apps (redirect `https://api.casama.ai/oauth/callback`) and Firebase App Check for project `kasama-ai`. Until the apps send App Check tokens, sign-ups use the proof-of-work puzzle.

## D-198 The launch screen hands off to the brand cloud's loop

- **Decision:** Operating-system launch screens stay stills. They show the first frame of the brand cloud — Winky in the app-icon lavender, both eyes open, from `client/assets/bots/casama-brand-animated.svg` — centred on `#FCF3FB` (light) and `#25102F` (dark). The old still winked, which is not a frame the loop rests on, so the stills were regenerated from that first frame. Flutter's first frame (`StartupGate`) draws the same crop of `assets/mascots/brand.json` at the same size and place, then plays the loop. iOS, web and desktop use 160 pt/px. Android uses 134 dp so the cloud fits the Android 12 splash icon's circle, and the pre-12 launch drawable uses 134 too, so both handoffs match. `assets/mascots/brand-splash.png` stands in until the loop has decoded, and when Reduce Motion is on. "Connecting…" appears under the cloud after 1.5 s. When the app is ready the splash fades and scales out over 300 ms (`AppMotion`, so Reduce Motion skips it) without waiting for the loop to finish. The web page keeps the still and adds a CSS float that rests on that same centred box, and turns off for `prefers-reduced-motion`.
- **Made by:** `scripts/casama-cloud-svg.py` (the animated brand SVG), `scripts/casama-mascot-lottie.py brand`, `scripts/casama-splash.py` (stills and `client/lib/ui/splash_art.g.dart`).
- **Tests:** `client/test/splash_test.dart`, `client/test/startup_test.dart`.

## D-199 Production runs on a Contabo VPS behind its own Cloudflare Tunnel

- **Server:** Contabo Cloud VPS 6 (instance 203746952, US Central, Ubuntu 24.04, 6 vCPU / 12 GB / 200 GB, $11 a month), set up 2026-11-12 with the normal self-host stack from the published images (`/opt/casama`, `./install.sh --pull --behind-proxy --domain api.casama.ai --turn-host turn.casama.ai --search --backups --settings deploy/casama-cloud/settings.env`). Fresh database (Oliver: start fresh).
- **Network:** a separate `casama-prod` tunnel (id 2f8335df-…) on the server via the `cloudflared` service: `api`, `auth` and `telemetry.casama.ai` go to Caddy on `localhost:80`, `pages.casama.ai` to `localhost:8790`. They were taken off the Mac's `casama-dev` tunnel, which keeps `api-dev`, `auth-dev` and `app-dev`. `turn.casama.ai` is a DNS-only A record for live view. Supabase is served on `api.casama.ai` under `/auth/v1` and `/rest/v1` (one public URL); `auth.casama.ai` reaches the same Caddy.
- **Hardening:** SSH by key only, ufw allowing 22 and 3478 (TCP and UDP), and a `DOCKER-USER` rule that drops outside traffic to containers except 3478, because Docker-published ports skip ufw. All web ports bind to loopback. Automatic security updates, fail2ban, 4 GB swap, gVisor (`runsc`) for computers. Contabo's resolvers returned SERVFAIL, so the server uses 1.1.1.1 and 9.9.9.9.
- **Fixes found on the way:** the Biome pass had turned `_format_version: '2.1'` into double quotes in `kong.yml`, which the container's shell `echo` strips, so Kong crash-looped on every fresh install (now excluded from Biome); the pages port ignored `HTTP_BIND`; the worker inherited the image's `/healthz` check although it serves no HTTP (now off); Supabase Auth now gets the branded templates from Caddy's internal-only `:8081`.
- **Checked:** `/readyz` through the tunnel; a real email sign-up with a solved puzzle through the public URL (hook passed, confirmation mail handed to Zoho); a throwaway account's computer started under gVisor in 3.8 s and wrote and read a file; search from the worker; an encrypted backup to R2; a Contabo snapshot; from outside only 22 and 3478 answer.
- **Computer price on this server:** `COMPUTER_RATES={"docker":{"cpu_hour":0.001,"gb_hour":0.0015}}` ($11 a month over about 9 GB and 6 vCPU for computers: 1 vCPU / 1 GB ≈ $0.0025 an hour, a full box ≈ $0.02 an hour, above the server's $0.015). Re-set it when the server changes.
- **After the first real use:** confirmation links pointed at `<url>/verify` (Auth keeps only the host of `API_EXTERNAL_URL`), so compose now sets `GOTRUE_MAILER_URLPATHS_*` to `/auth/v1/verify` as Supabase's own compose does; and the web app at `app.casama.ai` couldn't reach the API until `CORS_ORIGINS=https://app.casama.ai` (now in `deploy/casama-cloud/settings.env`).
- **Known gap:** deleting a user through the Auth admin API returns 500 (cleanup was done in SQL); account deletion needs a look.

## D-200 Wallpapers are real mesh gradients, and the Casama colors turn orchid and rose

- **Decision:** Every wallpaper palette is now a mesh gradient: nine colors on a gently warped 3×3 grid, blended with Catmull-Rom splines in OKLab and drawn as one cached triangle mesh with vertex colors (`client/lib/theme/mesh_gradient.dart`). This replaces the base color with three radial blobs. The mesh depends only on the window's size, so pages sliding during a transition reuse it, and a ring of edge colors reaching a window's width outside keeps half-offscreen pages covered. Every palette has hand-tuned night colors instead of the light ones pushed toward black. Warm palettes shift their hue at night (peach and sunset toward rose, citrus toward green) so they don't turn brown.
- **Palettes:** the nine existing ones, re-made as meshes under the same names so saved settings, presets and gallery items still resolve, and five new bolder ones: Northern, Twilight, Berry, Citrus and Reef (named so they don't clash with the gallery's Aurora and Dusk wallpapers or its Lagoon scheme and theme). Light meshes stay above 0.55 luminance and night meshes below 0.05, so text on transparent headers stays readable (`client/test/mesh_gradient_test.dart` checks this). `Theme` builds its nine colors from the scheme's primary, secondary and tertiary.
- **Meshes from the gallery, without a release:** a wallpaper of `"kind": "mesh"` (and a theme's `wallpaper`) carries a `mesh`: nine light and nine dark colors and optionally nine points. Its `palette` must be one of the ten palettes every app version knows: older apps don't read the mesh and draw that palette, instead of skipping the item. The app reads it into `WallpaperSpec.mesh` (`WallpaperMesh` in `mesh_gradient.dart`): corners are pinned, edge points kept on their edge, inner points kept between 0.2 and 0.8 so the mesh can't fold, and a malformed or low-contrast mesh falls back to the palette. The mesh is saved with the wallpaper and travels in theme share codes; picking a palette in Settings replaces it. Both checkers (`packages/domain/src/gallery.ts` and `gallery/check.mjs`) apply the same rules, and items naming one of the five new palettes are allowed but skipped by older apps, so they wait until most people have updated. `gallery.js` draws the same mesh (Catmull-Rom in OKLab, into a small canvas the browser stretches) and the app's new Casama colors. `wallpapers/petal` is the first mesh item (not deployed yet).
- **Brand colors:** Oliver found the Casama scheme too blue. The scheme is now orchid plum (`#9C3A9E` / `#F2B0EC`), rose (`#B8407F` / `#FFB1D4`) and periwinkle (`#5562CF` / `#BDC2FF`), with app bars matching the launch screens (`#FCF3FB` / `#25102F`). The Casama mesh, behind the welcome screen, is lilac, pink, orchid and periwinkle, with no sky blue or mint.
- **Needs a release:** the scheme, the built-in meshes and the mesh painter are compiled in; gallery meshes reach only builds that have the painter.
- **Not yet changed:** casama.ai (`site/`) and the auth email templates still use the old plum, sky blue and teal.
