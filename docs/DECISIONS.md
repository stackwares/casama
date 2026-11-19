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
- **Superseded in part by D-297 (2026-11-15):** App Store and Google Play purchases go through RevenueCat; the server's own App Store and Play adapters are gone.
- **Superseded in part by D-244 and D-248 (2026-11-13):** credit packs are also sold in the stores as consumables (D-244), only to paying plans (D-246), and a workspace has one subscription, changed where it was bought (D-248).
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
- **Live check (2026-11-15):** a real ChatGPT plan on a self-hosted server from the `worktree-casama-connect` branch, through `casama credential chatgpt`. Sign-in with the dynamic client worked; the key tested ok; `/v1/credentials/{id}/models` listed 8 models live (`gpt-6.1-sol` first); a bot on `gpt-6.1-sol` answered in about 4 s to first token and used the shell tool, with every usage row `source = 'chatgpt_plan'` at $0 (memory summaries too); a teammate got `chatgpt_plan_not_yours`; removing the key ran `revokeCredential`. Voice still needs other keys, as designed: live calls a Gemini key, read aloud and voice messages an OpenRouter key. Fixed from the run: `casama bot create` without `--model` now takes the key's first listed model when the server has no default (ChatGPT plans had none); `casama usage` labels computer time "(computers, no bot)" instead of "(deleted bot)"; the key refusals (not yours, sign in again, plan usage off) no longer go through the model step's retries (1 s, then 4 s). Seen twice right after a fresh install and not reproduced since: `casama chat` waited two minutes (the SDK's receive timeout) after a run had finished. Not tried: a real plan limit.

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
- **Waking:** `@Name` wakes that bot (longest name first, `@casama/domain` `parseMentions`); `@everyone` wakes the lead with the member list and asks for a plan that @mentions a bot per part, and if the lead's reply names none of them (a greeting, a question for all), every other bot then starts on the person's message; no mention goes to the last bot that spoke (else the lead). One user message, one run per woken bot, all in the same conversation and running in parallel.
- **Bot to bot:** a bot's reply that @mentions others starts their runs (trigger `mention`) up to 6 hops and 10 woken runs per user message (a reply that mentions two bots doubles the runs each hop, so the hop limit alone allowed over a hundred); a bot that already has a queued run isn't queued again, and bots are told not to @mention just to report, agree or thank. After that the chat waits for a person. Group messages are stored flat (no branches, so edit and resend stays direct-chat only). Words a bot says before its tool calls are kept as their own message in group chats too, and the bots they @mention start right then (a lead's plan usually comes before its own work; it used to be dropped, so nobody started).
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
- **Stdio servers on the user's own computer** through the desktop companion came later (D-344). The default computer image needs this computerd build to run plugin servers.
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
  - On macOS, Linux and Windows, the sign-in screen offers "Run Casama on this computer". (D-216: macOS and Linux only, pinned to the published images, loopback only.)
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
- **Messages sent while the bot works** (direct chats): `POST …/messages` without a card action attaches the message to the active run (`queued` or `running`, not cancelling) and returns `joined: true`. Before each model step the run adds such messages to its turn, marked "Sent while you were working on this", and the bot decides whether to fold them in, switch, or finish first. A message the run never saw gets its own follow-up run when the run completes or fails; the app follows that run too. Not when it is stopped (2026-11-17): Stop means stop, and a follow-up run made people press Stop once per message they had sent while it worked; those messages stay in the chat to send again. Group chats and card answers still wait (one run per woken bot, and a card answer is a new turn by nature).
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
- **Where updates come from:** a public repo with only installers and feeds, `stackwares/casama-releases` (`CASAMA_RELEASES_REPO`, `CASAMA_UPDATE_FEED`); the source repo is private, so its release files would need a sign-in. Feeds: `appcast-macos.xml` and `appcast-windows.xml` on the repo's `main` branch (`raw.githubusercontent.com/stackwares/casama-releases/main/…`), one item each (the latest release), or none before the first release. They used to be assets on `releases/latest`, but CLI releases share the repo and GitHub calls the newest of those "latest" when no desktop release is, so the feed 404'd and Sparkle showed "Update Error!" (2026-11-16). Builds from before that read `releases/latest` until they update.
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
- **Why:** three to five tabs is the platform norm; the computer belongs to a bot, not the whole app; Settings is visited rarely and needn't take a tab.
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
- **Shared key (2026-11-12):** a workspace without its own OpenRouter key generates images on the server's shared key (`CLOUD_MODEL_UPSTREAM_KEY`, D-186) whenever the server has one, like chat, dictation and memory search (D-194). Before, images used it only with billing on, so a self-hosted or local server with the key chatted fine but asked for an OpenRouter key to make a picture.
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
- **Every version needs lines:** `client/test/whats_new_test.dart` fails until pubspec.yaml's version has an entry, so a release can't ship without its notes. The 0.1.0 lines are never shown (no earlier build has this feature, so every install of it counts as fresh); the first sheet people see is the next version's.
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

## D-201 Looks are data: built-ins from `client/looks`, doodles and full color schemes from the gallery

- **Decision** (Oliver asked, 2026-11-12: make almost everything contributable): the app is the renderer, and looks are data in one format, the gallery's.
- **Built-ins as data:** `client/looks/` holds the Casama scheme (`schemes/casama.json`, full-scheme format), the 14 meshes (`meshes/*.json`) and the 8 patterns (`patterns/*.json`, Lucide names), with the picker order in `index.json`. `node scripts/casama-looks.mts` checks them (hex, mesh luminance and point rules, doodle limits, scheme contrast), resolves glyphs against `gallery/assets/lucide/icon-nodes.json` and writes `client/lib/theme/looks.g.dart` (the `WallpaperPalette` and `WallpaperPattern` enums and `casamaScheme`); `--check` fails when it is stale. They stay compiled in, so first launch and offline need nothing, and enum names (stored in preferences and gallery documents) are unchanged. lucide-static 1.63 renamed three icons the patterns use (smile, music and waves); `client/looks` uses the new names, with the same drawings.
- **Doodles:** pattern tiles are drawn from stroked paths (`client/lib/theme/doodles.dart`, path data via `path_parsing`) instead of icon-font glyphs. They use the same layout and seeds, stroked at 2.6 units, which matches the font's ink within 1%. A gallery wallpaper (pattern or mesh) or a theme's wallpaper can bring `glyphs` (up to 24 Lucide names, which the checker resolves into `doodles` in `index.json`) or its own `doodles`: up to 24 drawings, each up to 24 Lucide-format elements on a 24 × 24 grid. `pattern` stays as the fallback for older apps. `WallpaperSpec.doodles` saves, compares by value, travels in share codes, and is cleared by picking a pattern.
- **Full color schemes:** a scheme (or a theme's inline scheme) can give primary, secondary and tertiary with their containers, plus an optional app bar, next to its seeds. The checker requires 4.5:1 for each accent on the background and for text on each container. The app uses the exact colors when all six are valid and saves them with the scheme; otherwise, and on older apps, it builds the scheme from the seeds. `gallery/schemes/orchid` is the Casama brand as a gallery scheme.
- **`requires`:** the checkers add `requires` (`doodles`, `mesh`, `scheme-colors`) to index items. The server passes it through, and its item endpoint returns the index's document (with glyphs resolved). The app hides items that need something it can't draw (`GalleryItem.supportedFeatures`). Older apps don't read it and draw the fallbacks, so every new kind so far stays safe to publish.
- **Checkers:** `packages/domain/src/gallery.ts` (exports `checkDoodles`, `checkSchemeColors`, `resolveGlyphs`, `galleryRequires`, `galleryIndexDocument`) and the standalone `gallery/check.mjs` apply the same rules and write a byte-identical `index.json`.
- **Make a look:** `gallery/make.html` (plain JS, no build step) builds a theme, color scheme or wallpaper. It covers seeds or exact colors with live contrast, a built-in palette or your own mesh with draggable points and luminance limits, Lucide doodles by search, fallbacks for older apps, item details, and live chat previews in light and dark. It outputs `item.json` and the item's file with Copy, Download and "Propose on GitHub" links. Gaps: no hand-drawn doodles, no image wallpapers, mesh points can't be moved with the keyboard, and each file opens as its own GitHub page.
- **Samples (not deployed yet):** `wallpapers/stargazer` (glyphs), `wallpapers/scribbles` (a mesh with hand-made doodles), `schemes/orchid`.
- **Lucide data:** `gallery/assets/lucide/` (lucide-static 1.63.0, ISC; in THIRD_PARTY_NOTICES).

## D-202 Profile photos live in Postgres and are served by the API; Google's photo is copied once

- **Decision** (Oliver asked, 2026-11-12): people get a profile photo. Uploads come from the camera or the photo library. Google sign-ins get their Google photo copied automatically.
- **Storage:** `public.profile_photos` (one row per person, ≤ 1 MB JPEG/PNG/WebP checked by magic bytes, no RLS policies, API only). The self-hosted stack and prod run no object storage, and a photo is a few dozen KB, so Postgres it is. Account purge cascades.
- **Serving:** `GET /v1/photos/{id}`, without a token, cached `immutable`. Every new photo gets a new random id, so caches never show a stale picture. Only people who can already see the profile get the id: your own `GET /v1/me/about` (`photo_id`) and the workspace member list (`WorkspaceMember.photo_id`).
- **Changing it:** `PUT /v1/me/photo` (base64 body), `DELETE /v1/me/photo`, `POST /v1/me/photo/import` (`replace` for "Use my Google photo").
- **Google:** the server copies the sign-in photo (from `raw_user_meta_data` `avatar_url`/`picture`, only from `*.googleusercontent.com` over https, asked at 512 px, 8 s timeout, no redirects) the first time the app loads About you without a photo. `profiles.photo_import_tried_at` records the attempt, so a removed photo stays removed. Apple shares no photo.
- **App:** phones shrink and compress with `image_picker` (512 px, quality 85). Desktop files over 400 KB, or in other formats, are cropped to a 384 px square PNG on the device. `PersonAvatar` shows the photo with the initial as the fallback: MeAvatar (header, rail, Settings card), About you (the editor), People.
- **Settings reorganized at the same time:** Workspace, App (Appearance has its own page now), Connections, Sign-in & security, Advanced.

## D-203 One place for how Casama looks: pick a whole theme, then Customize

- **Decision** (Oliver, 2026-11-12: Themes, Colors, Gallery and Presets were too many places): Settings → Appearance is the one place. A look is at most two pages deep, and the gallery is one more source of looks rather than somewhere else to go.
- **Appearance** (`client/lib/features/settings/appearance_screen.dart`): the look in use as a small chat, named (or "Custom look"), with **Customize**, plus Save when the look matches no theme. Below it are light, system or dark, then every theme as a card drawn in its own colors, fonts and background (`ThemeCard`, the gallery's `GalleryChatPreview`): yours, then Casama's, then **From the gallery** (six, then "Show all"). One tap uses a theme. If that replaces a changed look that wasn't saved, a snackbar offers Undo, so trying themes never loses work. Fewer effects follows the cards, with Import a theme and Share to gallery at the end. Your own themes have Share and Delete in their menu; gallery themes have About this theme (the gallery's detail sheet).
- **Customize** (`customize_screen.dart`): Colors, Background and Fonts as tabs on one page, under a live preview that stays in view, pinned above the choices on phones and beside them on windows 760 px and wider. A sun/moon button previews the other brightness without changing the app's setting. Save appears in the header once the look is your own. The panels are the former pages: `colors_panel.dart` (search, families, and a Gallery chip with the gallery's schemes mixed in after Casama's), `background_panel.dart` (the gallery's wallpapers first, then pattern, colors, strength, photo, everywhere and reset) and `fonts_panel.dart`.
- **Gallery looks** come from one provider (`gallery_looks.dart`, `galleryLooksProvider`), loaded once a session and shared by both pages. A theme you use is kept with your themes for offline use, and shown once, under the gallery, while the gallery lists it. Using it again replaces that copy instead of adding another. The Gallery page stays for skills and links (`/settings/gallery`).
- **What counts as the same theme:** "Show in the whole app" is a preference, so changing it keeps a theme in use, and picking a theme keeps it as it is. The Casama theme is now exactly the out-of-the-box look (Clouds on the theme's own colors, orchid, rose and periwinkle with Casama's scheme), so a new install shows Casama in use, and changing colors later moves the background with them. Anyone who picked the old Casama theme (the Casama mesh) sees "Custom look" until they tap it again.
- **Addresses:** `/settings/appearance` and `/settings/appearance/customize?tab=colors|background|fonts`. The older `/settings/themes`, `/settings/theme`, `/settings/fonts` and `/settings/background` redirect there.

## D-204 Google first in the welcome chat, and app tiles in an empty chat

- **Decision** (Oliver, 2026-11-12: Grok, Hark and other assistants get people connected to Gmail and their apps first): the welcome chat asks for Google right after the name, for everyone, instead of only after the picks. Connecting is the moment Casama proves itself, so the catch-up follows at once.
- **The Google card** (when this server can connect Google: through the server's Composio account, or self-hosted with its own Google client, `googleConnectRoute`): "Connect Google Calendar" (primary), "Gmail too" and "Not now". Its wording is the consent to the catch-up (it reads the next 14 days of calendar, and with Gmail the last 14 days of email; nothing is sent, changed or deleted), so no second consent card follows. On Composio a caption says that Google's screen names Composio.
- **Connected:** the buttons are `app:connect` with `after: "welcome.connected"`. Once the connect sheet returns a connection, the app sends that action (shown as "Connected Google Calendar"). The server checks the connection is real (`googleConnection`): a direct one exists only after its sign-in finished; a Composio one is added when the sign-in page opens, so Composio's account list is asked whether it's active. Active: the catch-up runs straight away (calendar-only wording when Gmail isn't connected) and the focus and scope questions are skipped. The setup interview after it learns the rest. Still signing in: "Finish signing in to Google in your browser, then tap Catch me up", and Catch me up checks again before starting a run. Nothing connected: the card again.
- **Not now:** the focus question, as before. The later connection card leaves Google out, and is skipped if Google was its only app.
- **Fixes on the way:** the old check counted any Composio connection (GitHub or Slack too) as Google, which offered a catch-up with nothing to read.
- **One Google screen:** direct Google sign-ins send `login_hint` with the Casama sign-in email, so Google skips its account chooser. Composio's Connect Link has no such parameter (not in its v3 docs), so Composio sign-ins still show Google's chooser.
- **Not yet:** signing in with Google and connecting it in one consent, as Hark does. That needs Casama's own Google app verified for `calendar.events` (free; the demo video is still missing, NEEDS-FROM-OLIVER) and Supabase's provider tokens handed to the integration. Reading the inbox in Casama's own app also needs the yearly CASA assessment. Until then it's sign-in, then one Google screen for Calendar.
- **No Microsoft:** the catalog has no Outlook or Microsoft calendar yet, so people who don't use Google tap Not now and connect from More apps.
- **App tiles:** an empty chat shows "Connect your apps" with one-tap tiles above the starter requests: Gmail, Google Calendar, Google Drive, Notion, GitHub and Slack, in that order, only those that connect in one click on this server (own sign-in, or Composio) and not yet connected (directly or through a hub). They go away once two apps are connected. Tapping one opens its connect sheet (`ConnectAppTiles`, `client/lib/features/chat/widgets/app_tiles.dart`).

## D-205 Chat media: generated images and videos live in Postgres and show under the reply; Office files preview as PDF

- **Decision** (Oliver asked, 2026-11-12, "Build all"): what a bot generates shows in the chat by itself. Before this, it only showed if the bot linked the file, and was lost when there was no computer.
- **Storage:** `public.chat_media` (≤ 50 MB a file, RLS on with no user policies, written by the worker). `media.image.generate` and `media.video.generate` always keep the bytes there, plus the computer's `media/` copy when there is one. The tool result tells the bot the person already sees it.
- **In the reply:** `saveFinalMessage` adds one part per row of the run, after the text and UI parts: `{type: "file", path: "media:<id>", name, mime_type, size, width?, height?, duration_s?}`. They go into the stored content and the `message.completed` event. In later turns the model sees "(You showed the person a generated image/png: image.png.)", not a computer file to open.
- **Serving:** `GET /v1/media/{id}` needs a token and membership of the row's workspace (404 otherwise). It sends `cache-control: private, immutable` and `accept-ranges: bytes`, and answers one `Range` with 206 (416 when unsatisfiable), reading only that slice of the bytea, because AVPlayer won't play without ranges.
- **Office previews:** `GET /v1/computers/{id}/files/pdf-preview?path=` (`computerFilePdfPreview`) converts doc/docx/odt/rtf/xls/xlsx/ods/ppt/pptx/odp with LibreOffice on the computer (60 s limit), cached in `~/.cache/casama-previews/<sha1(path:mtime)>.pdf`. Responses: 415 `preview_unsupported` (another file type, checked before waking the computer, or no LibreOffice), 404 (no such file), 422 `preview_failed`.
- **Not encrypted:** media bytes aren't sealed with the workspace key (D-136), the same as files on computers.

## D-206 Telemetry hygiene, official build isolation, and super properties (Phase 0)

- **Decision** (Oliver: "Execute the plan"): Phase 0 of `docs/ANALYTICS-PLAN.md` implemented.
- **Client & Official builds:** `client/config/telemetry.json` is untracked and gitignored with `client/config/telemetry.example.json` committed. Packaging scripts (`package-macos.sh`, `package-macos-appstore.sh`, `package-linux.sh`, `package-windows.ps1`, `package-ios.sh`, `package-android.sh`) pass telemetry defines ONLY when `CASAMA_OFFICIAL_BUILD=1` and `config/telemetry.json` exists. Builds without the file send nothing.
- **API URL default:** Fixed `CASAMA_API_URL` default in packaging scripts to `https://api.casama.ai` (was `cloud.casama.ai`).
- **Telemetry super properties:** `app` (`casama`), `environment` (`production|staging|development`), `platform` (`ios|android|macos|windows|linux|web`), `distribution` (`app_store|google_play|mac_app_store|direct|web`), and `server_kind` (`cloud|local|self_hosted|unknown`). `server_kind` is classified from `billing_enabled` and `apiUrl` without sending the URL.
- **PostHog configuration:** lifecycle event capture, survey capture, push open/subscription captures, and feature flag preloading turned off. Person profiles set to `identifiedOnly`.
- **Screen views & dedupe:** `ShellRoute` passes `Telemetry.observers`. `SessionScreenObserver` deduplicates screens per session, expiring after 30 minutes in background.
- **Web telemetry:** dynamic script loader for `posthog-js` on web when a PostHog key is provided; updated Caddy CSP to allow `https://us-assets.i.posthog.com`.
- **Server:** Centralized `CASAMA_VERSION` in `apps/server/src/version.ts` and passed `version` and `environment` to `initObservability`. Documented `ANALYTICS_ENVIRONMENT` and `PRODUCT_ANALYTICS` in `env.ts`, `.env.example`, and `docker-compose.yml`.

## D-207 Crash reporting and error tracking (Phase 1)

- **Decision** (Oliver: "Go and finish all until all phases are completed"): Phase 1 of `docs/ANALYTICS-PLAN.md` implemented.
- **Client rate capping & fingerprint deduplication:** `Telemetry.captureException` limits captured exceptions to at most 20 exceptions per minute per process, and suppresses identical error fingerprints (`errorType:message:topFrame`) for 5 minutes to prevent reconnect / offline loops from burning error quotas.
- **Client error config:** PostHog error tracking enabled with `captureFlutterErrors = true`, `capturePlatformDispatcherErrors = true`, `captureIsolateErrors = true`, `captureNativeExceptions = true`, `captureNativeCrashes = true`, and `inAppIncludes = ['casama']`.
- **Handled client exceptions:** `showError` in `client/lib/core/widgets.dart` reports unexpected exceptions (filtering expected 4xx DioExceptions and AuthExceptions). `runGuarded` forwards stack traces. Purchase verification failures in `billing.dart` and updater failures in `updater.dart` report with warning level.
- **Server and worker unhandled error boundaries:**
  - `apps/server/src/main.ts`: Process `unhandledRejection` and `uncaughtException` handlers capture to observability, flush/close, and exit with code 1.
  - `apps/server/src/worker/workflows.ts`: `agentRunWorkflow` guarded with try/catch to ensure unexpected workflow errors update `public.runs` to `status = 'failed'` (`run_error`) and capture with `run_id` and `trace_id`, preventing permanent zombie/stuck runs (§1.3 Bug 1).
  - Background tick steps in `workflows.ts` now route through `captureStep` to log and report recurring failures instead of silently swallowing errors.
  - Usage meter reporting in `billing/connect.ts` and external object/memory cleanup in `services/privacy.ts` now capture unexpected exceptions.
- **Supervisor:** Added `@casama/observability` to `apps/supervisor`, initialized observability in `apps/supervisor/src/main.ts`, captured warm pool errors, and wired `app.onError` in `app.ts`.

## D-208 Identity, consent, and core funnels (Phase 2)

- **Decision** (Oliver: \"Go and finish all until all phases are completed\"): Phase 2 of `docs/ANALYTICS-PLAN.md` implemented.
- **Privacy & Opt-out:**
  - Added migration `20270120000001_analytics.sql` adding `profiles.analytics_opt_out` (default false), `profiles.analytics_signup_sent_at`, and `public.analytics_milestones` table.
  - Added `analytics_opt_out` to workspace settings and API route `POST /v1/me/analytics-opt-out` in `apps/server/src/api/routes/privacy.ts`.
  - Added client analytics sharing toggle in `client/lib/features/privacy/privacy_screen.dart` under "Your data", backed by `SharedPreferences` and syncing with PostHog's `optIn()` / `optOut()`.
  - Updated `client/ios/Runner/PrivacyInfo.xcprivacy` and `client/macos/Runner/PrivacyInfo.xcprivacy` declaring `ProductInteraction`, linked `CrashData`, `UserID`, and `OtherDiagnosticData`.
  - Updated disclosures in `site/privacy.html` and `docs-site/guide/privacy.md`.
- **Client & Server Analytics Facades:**
  - Implemented `client/lib/core/analytics.dart` with `capture`, `identify`, `reset`, and `featureUsed` (rate-limited per day).
  - Wired `Analytics.identify` on sign-in and `Analytics.reset` on sign-out in `client/lib/app.dart`.
  - Implemented `packages/observability/src/analytics.ts` providing `initProductAnalytics`, `getProductAnalytics`, and personless capture options when `PRODUCT_ANALYTICS=on`.
  - Updated client `beforeSend` in `client/lib/core/telemetry.dart` to strictly allow only cataloged product events and scrub payload properties.
  - Wired purchase completion analytics tracking across store purchase states in `client/lib/core/billing.dart`.

## D-209 Adoption, reliability, and daily rollups (Phase 3)

- **Decision** (Oliver: \"Go and finish all until all phases are completed\"): Phase 3 of `docs/ANALYTICS-PLAN.md` implemented.
- **Daily Rollup Worker Workflow:**
  - Implemented `apps/server/src/worker/analytics-rollup.ts` (`runDailyAnalyticsRollup`) to summarize yesterday's metrics directly in Postgres at 00:20 UTC without tracking individual messages or tool calls.
  - Generates deterministic PostHog event UUIDs (`rollup:usage_daily:<userId>:<date>` and `rollup:workspace_daily:<orgId>:<date>`).
  - Respects user consent in SQL (`p.analytics_opt_out = false`) and sends workspace rollups as personless events (`distinct_id = workspace:<orgId>`, `personless = true`).
  - Scheduled via DBOS `analyticsDailyWorkflow` in `apps/server/src/worker/workflows.ts` and registered in `apps/server/src/worker/index.ts` with schedule `20 0 * * *`.
- **Client Adoption Tracking:**
  - Wired `Analytics.featureUsed` rate-limiting (at most once per feature per day per device) into the Analytics client facade.

## D-210 The analytics plan, finished: what runs, what changed from the plan

- **Decision** (Oliver: "finish the whole plan completely"): `docs/ANALYTICS-PLAN.md` is implemented end to end except the steps only Oliver can take (listed in NEEDS-FROM-OLIVER and the plan's appendices). This entry also corrects what D-208 and D-209 said was done.
- **Fixed from D-208/D-209:**
  - The daily rollup queried a column that does not exist (`runs.user_id`; it is `created_by`) and sent event ids PostHog rejects (not UUIDs). It now counts only what a person did themselves (runs they started in chat, mention or voice, approvals they decided), puts automation in the personless workspace rollup, skips opted-out people and workspaces in SQL, and is tested against a real Postgres.
  - Server product analytics was never initialized (`initProductAnalytics` was not called), so no server event could ever be sent. `PRODUCT_ANALYTICS` is `on|off` (the env schema said `true|false` while the code and docs said `on`).
  - The Privacy switch never told the server, so a person who turned it off still produced server events. It now syncs once per change and again after sign-in (and is cleared on sign-out). The workspace switch the D-208 text mentioned did not exist: `organizations.analytics_opt_out` is added and honored by events, milestones and rollups, with a switch for admins in Privacy.
  - The app decided "Casama Cloud" by comparing with `https://cloud.casama.ai`, which is not a host we run; it is now an official `casama.ai` host with billing on. Screens and product events leave the device only for Cloud (one place: `beforeSend`); a self-hosted or local server sees crash reports and one `app_active_daily` ping.
  - Lint and format failures in the earlier commits (CI would have failed) are fixed.
- **One catalog:** `packages/contracts/analytics/catalog.json` lists every event, its sender and its properties; `pnpm gen` writes the app's allowlist (`client/lib/core/analytics_events.g.dart`); a test checks names, property rules (no content words), that every event in the code is in the catalog and the other way round, and that the generated file is current.
- **Server events** (all through `track()` in `packages/agent/src/analytics.ts`, after the change is saved, never blocking, skipped for opted-out people and workspaces): `signed_up` (a worker sweep through `worker_new_signups`, since sign-up is a database trigger; existing accounts are marked reported by the migration), milestones (`first_value` and the rest, once per person, guarded by `analytics_milestones`), `workspace_created`, `invite_created`, `member_joined`, `join_requested`, `join_request_decided`, `bot_created`, `bot_shared`, `connection_added`/`connection_failed`, `model_key_added`, `run_refused`, `limit_reached`, `routine_created`, `watcher_created`, `action_rule_created`, `page_published`, `chat_app_connected`, `computer_start_requested`/`ready`/`failed`, `call_ended`, `checkout_created`, `subscription_changed`, `purchase`, `refund_issued`, `account_deletion_requested`, onboarding steps from the Welcome script, and the two rollups.
- **App events:** sign-in (started, failed, completed, two-step), signed out, onboarding (manual path, name step), connection funnel, calls, join and invite sharing, paywall and purchase (including cancel, failure and restore), push permission and opens, startup failure, `app_error_shown` (a code, a status, a coarse kind and the route template: never the message), and `feature_used` (a closed list, once a day per device; pages count through the route observer).
- **Deviations from the plan:**
  - `purchase` carries no `value`: plans have only a text `price_label`. Revenue analytics waits for numeric prices (it needs a plan-price decision).
  - `paywall_plan_selected` is merged into `purchase_started` (they were the same tap); `signup_blocked` is dropped (no stable id exists before an account; `abuse_events` already has it); `restore_purchases` has no `none` outcome (the store gives no signal).
  - The workspace switch stops server events and rollups; it does not stop the app's `identify` (the app does not know the workspace at sign-in).
  - Purchases are attributed to the workspace owner (the webhook does not say who paid).
- **Erasure:** purging an account asks PostHog to delete the person and their events (`POSTHOG_PERSONAL_API_KEY`, `POSTHOG_PROJECT_ID`); a failure is reported with the user id and never blocks the purge.
- **Crash reporting:** PostHog is the reporter for Casama Cloud and official builds (`ERROR_REPORTING=posthog`); Sentry stays supported (D-063). More silent failures now report: A2A, live view, idle sleep, OAuth and ChatGPT sign-in.
- **Set up afterwards (Oliver asked me to, 2026-11-12):** the local keys file, the VPS `.env` settings (not yet deployed), two scoped PostHog personal keys (stored in Vaultwarden), and the PostHog dashboards, cohorts, actions and alerts, all in project 637030. Compose now passes the person-deletion settings into the containers (it did not).
- **Still Oliver's:** deploying the new version, store privacy forms, data processing agreements, the PostHog `$ip` transformation and error tracking alerts, and the crash drill on real devices. See the plan's appendices.

## D-211 Invite friends: no gate, a personal code, credits for the inviter

- **Decision (Oliver, 2026-11-12):** a soft version of Muse's invite codes, to grow faster. Anyone can download the app and sign up; nothing is gated. Each person has one invite code and link, and the friend who invited someone earns free usage once that person is real. Researched first: Meta's Muse turned out to be mostly a referral program as well (a per-account code, entered within 48 hours, 1B tokens for both people), with hard gating only in some regions.
- **Codes:** 6 characters of Crockford base32 (`referral_codes`, one per person, made on first use), so they can't be confused with 8-character workspace codes (D-167); read however they're typed, and from a pasted `casama.ai/i/<code>` link. Wrong codes count against the D-167 guessing limit.
- **Redeeming:** `POST /v1/me/referral/redeem` goes through `redeem_referral_for()`, a security definer function only the API can call. It refuses one's own code, a second code, a code from someone you invited yourself, and codes entered after `REFERRAL_REDEEM_DAYS` (7) days from signing up. `GET /v1/me/referral` returns the code, the link, counts, credits earned, who invited you and until when you can still enter a code. `GET /v1/referral/preview` needs no sign-in and returns only the inviter's first name, never the name taken from an email address.
- **Rewards:** the worker runs `worker_reward_referrals()` every minute. A referral qualifies once the friend has a verified email or phone and has reached the `first_value` milestone (a first finished chat). The inviter's oldest owned workspace (else the oldest one they belong to) then gets `REFERRAL_REWARD_USD` (2) through `credit_apply` (reason `grant`, once per friend), and the inviter gets a `referral_rewarded` push that opens Invite friends. Rewards stop after `REFERRAL_REWARD_CAP` (20) friends, and later friends are recorded as `capped`. An inviter in no workspace at all gets nothing for that friend (`none`); nothing is left pending.
- **Welcome bonus (Oliver, 2026-11-12):** the new person gets `REFERRAL_WELCOME_USD` (2) at the same moment, in the oldest workspace they own, else the oldest they belong to (reference `referral-welcome:<id>`), with a `referral_welcome` push. It doesn't count toward the inviter's cap, and a friend past the cap still gets it. Someone in no workspace at all gets no bonus. The app, the casama.ai page and the share text say "you each get $2" when the two amounts match.
- **On or off:** `REFERRALS=auto` turns it on with billing (Casama Cloud). Self-hosted servers show nothing. Without billing the reward is 0.
- **Links:** `casama.ai/i/<code>` is served by the site worker (`site/gallery-link.js`). It shows who invited you and the code, with Open in Casama and Get Casama. iOS (AASA `/i/*`) and Android (App Link `/i/`) open the app at `/i/<code>`. Signed out, the code is kept on disk through sign-up, and once signed in the app asks once (**Accept invite**). Nothing is redeemed without a tap. A store install loses the link, so the page shows the code to enter under Settings → Invite friends.
- **App:** Settings → **Invite Friends** (buttons and titles in Title Case, like the rest of the app): the code (tap to copy), Share link and Copy link, friends who joined (and how many haven't finished a first chat yet), credits earned against the cap, how it works, and a field for a friend's code while that's still allowed.
- **Analytics:** `referral_redeemed` and `referral_rewarded` from the server, `referral_shared` from the app (F7).
- **Costs:** docs/COSTS.md "Invite rewards".
- **Audit (2026-11-12), fixed in `20270121000002_referral_fixes.sql` and the API:**
  - **Stuck referrals:** a referral whose inviter owned no workspace stayed pending and was re-read every minute ahead of newer ones, so enough of them would have starved the 100-row sweep, and the friend's welcome bonus waited with it. Credits now fall back to a workspace the person belongs to, and with none the referral is decided anyway.
  - **Redeeming through PostgREST (security):** `redeem_referral(code, days)` took the window from its caller and was executable by `authenticated`. So anyone signed in could call `/rest/v1/rpc/redeem_referral` with a window of years and redeem a code on an old account. `referral_preview` was executable by `anon`, which skipped the API's guess limit. Both are API-only now: `redeem_referral_for(user, code, days)`, called with the signed-in person's id and the server's window, and neither is granted to `anon` or `authenticated`. A test checks every referral function.
  - **Concurrent redeems:** two redeems at once by the same person surfaced the primary-key error as a 500; they now answer `referral_already`.
  - **Data export:** `account.json` now has `invites`: your code, the invite you joined with, and what each friend earned, without naming them.
  - **App:** the Settings row showed "$2.00" while everything else said "$2", and Invite Friends showed counts from when Settings first loaded; it refreshes on open now.
  - **Signed-out rate limits (affects all of the API, not only invites):** behind Cloudflare Tunnel, Caddy (which has no `trusted_proxies`) writes the tunnel's local address into `X-Forwarded-For`, so every signed-out caller on Casama Cloud shared one 120-a-minute bucket, and one person guessing workspace or invite codes locked everyone out for 10 minutes. `TRUSTED_CLIENT_IP_HEADER` names a header the edge sets and clients can't override (`cf-connecting-ip` on Casama Cloud). Unset, self-hosted servers keep the first `X-Forwarded-For` entry, which Caddy sets. Not trusted: Cloudflare's `CF-Worker` header, which isn't documented as safe on requests straight from a client. So the casama.ai invite page's lookups still share the Worker's address. A burst of bad codes there only drops the inviter's name from the page for a few minutes, and a link that's going around is served from the Worker's 5-minute cache.

## D-212 The app builds on Flutter 3.50; no model picker on Casama Cloud

- **Decision** (Oliver: "we want to use flutter 3.50 going forward"): the app, CI (`.github/workflows/ci.yml`) and the web image (`client/Dockerfile.web`, commit `ab2912035e16…`, checked against the official tag) use Flutter 3.50.0 (Dart 3.14). This supersedes the 3.47.9 pin from D-186's CI note.
- **What changed in the code:** 3.50 deprecates `package:flutter/material.dart` and `cupertino.dart`, and CI's `flutter analyze` fails on deprecations. Every Material import is now `package:material_ui/material_ui.dart` and the two Cupertino ones `package:cupertino_ui/cupertino_ui.dart` (new direct dependencies `material_ui ^1.10.0`, `cupertino_ui ^1.1.6`); `presets.dart` takes `immutable` from `foundation.dart`. `flex_color_scheme` is 9.x because 8.x returns the old `ThemeData` and `ColorScheme` types. `window_manager`, `tray_manager` and `hotkey_manager` moved to 0.7, 0.9 and 0.4: their `nativeapi` 0.5.10 called `Isolate.create`, which Dart 3.14 removed (done by the referral-feature session). New files use the `material_ui` import.
- **Checked:** `flutter analyze` is clean; the suite passes on 3.50 except tests whose expected text another session's uncommitted title-casing of `app_en.arb` and voice work had changed; Android, iOS simulator and macOS debug builds succeed.
- **Working rules:** never run two Flutter commands in `client/` at once (they share `client/build` and `.dart_tool`), and don't mix Flutter versions in one checkout: `pub get` rewrites `.dart_tool/package_config.json` for the version that ran it.
- **Casama Cloud shows no key or model fields:** on Cloud (billing on) every bot already runs on Casama's key and model (D-188), so the new-bot sheet, the bot profile, bot template import and agent import no longer show the key dropdown or the (locked) model field; the sheet uses Casama's key and model. Self-hosted servers are unchanged. Tests: `autonomy_test.dart`, `bot_profile_test.dart`.

## D-213 Bots ask only before really risky actions by default

- **Decision** (Oliver: "I want most permissions to be allowed by default, only the super risky ones need"): under the default autonomy, "ask for risky actions" (`ask_risky`), a bot now runs everything except these, which still ask first:
  - high-risk actions: sending through chat apps or email, calls to other people, making a page public, creating or archiving bots, raising a bot's autonomy or budget, setup changes, opening pull requests, destructive shell commands outside `~/workspace`, and connected-app tools marked destructive;
  - paid data lookups (`data.call`, with the price shown, D-138);
  - payments, whatever the autonomy (D-142).

  Password and two-step changes are still handed off (D-115). Action rules and the other two autonomy levels are unchanged.
- **The prompt-injection guard is narrowed:** after the bot reads outside content (web, files, email, tool output, D-154), a medium-risk call asks first only if it sends data out of Casama. A tool says so with `sendsOut` (or `sendsOutFor` from its arguments), and `needsApproval` takes it as `sendsOut`. Tools that set it:
  - `http.request` for POST/PUT/PATCH/DELETE (GET and HEAD don't);
  - every connected-app tool (MCP, OpenAPI, other agents);
  - `links.ask`.

  Everything else medium-risk runs, for example web reads, workspace publishing and creating skills or projects. A GET to a hostile address can still carry data in its URL. This is accepted: secrets are only filled in for their allowed hosts, and private addresses are blocked.
- **No longer "always confirm":** image and video generation (credit caps and budgets still apply) and device calendar and reminder writes (this replaces D-149's "ask first by default"). An "ask" action rule makes any of them ask again.
- **Templates:** the six that started bots on "ask before acting" (executive assistant, support agent, writer, social manager, money helper, recruiting screener) now start on the default. Migration `20270122000001_default_autonomy.sql` moves bots already made from them, found through their `bot.created` audit entry. It skips any bot whose autonomy someone has changed since (it has a `bot_revisions` entry for `autonomy`). The revision trigger records each move, so it shows in the bot's history. Bots that other bots created record no template, so they are left as they are.
- This updates D-155's list of what still asks. Tests:
  - `packages/domain/test/autonomy.test.ts`;
  - `packages/agent/test/autonomy.test.ts`: reading after untrusted input runs, sending data out asks, media runs without asking, and the approval-flow tests now use bots set to ask before acting;
  - `apps/server/test/device-data.test.ts`: the write test sets an "ask" rule.

## D-214 A stopped bot stays stopped, and a bot that runs out of steps says so

- **What happened** (Prod Bot on prod, 2026-11-12 06:57–07:19 UTC). Oliver asked it to crop a video to 1:1. The computer had no `ffmpeg` and the bot can't install packages, so each run spent its 40 steps hunting for a workaround (pip packages, Playwright's ffmpeg build, hexdumping the MP4).
  - Oliver tapped stop twice. Each time, a message he had sent during the work (the GIF request, then "Why can't I stop you here") started a new run. That run saw the crop request still unanswered and picked it back up.
  - Two runs then hit the step limit and ended with **no reply**, so the chat showed "Working" for about 20 minutes and never answered.
  - Asked from the group chat, the bot said it wasn't working on anything: runs couldn't see the bot's work in other chats.
- **Changes:**
  - **Stopped and silent work is marked in the history.** A request whose run the person stopped (`cancel_requested_at` set, or the run cancelled) gets this note in the history the model sees: "the person stopped your work on this before you replied. Don't pick it back up unless they ask again". A run that failed without a reply gets a note saying so, and not to silently retry the same approach.
  - **Out of steps or time, the bot answers.** When a chat run hits `max_steps_exceeded` or `wall_time_exceeded`, it takes one last model turn with no tools. That reply says what it got done, what blocked it and what it suggests, and is saved as the reply before the run fails.
  - **Work in other chats is visible.** The current message carries a note listing the bot's other active runs from the last 6 hours (chat title, what was asked, how long ago), so it can say what it's doing.
  - **`ffmpeg` is in the computer image** (`Dockerfile.headless`, so the desktop image gets it too).
- **Not done yet:** stopping still waits for the running tool call to finish (27 s for the first stop that day). Shell and other computer tools don't take a cancel signal; only local and computer MCP calls are aborted. Interrupting `docker exec` on cancel is a follow-up.
- Tests (`packages/agent/test/run.test.ts`): "stops at max steps, and says where it got to instead of going quiet", "a bot asked from another chat knows it's busy elsewhere", "after the person stops a run, the next message doesn't pick the stopped work back up".

## D-215 A new bot opens straight into chat

- **Decision** (Oliver: "we don't need this anymore when we create a new bot, just let the user chat"): a new bot's empty chat no longer shows the "Set up NAME" card with Start Setup and Skip for Now (D-105). It shows the normal empty chat with starters, so the person can type straight away.
- **Kept:** the setup interview, `setup.apply` and `bots.setup_status`, which new bots still get as `pending`. The interview starts from bot settings (Run Setup Again), and the welcome flow still uses it. Only the card is removed from `chat_screen.dart`. `setup_test.dart` now checks that no card shows.

## D-216 "Run Casama on this computer" works from a downloaded app

- **Problem:** the desktop app's one-click local server (D-147) could not work for anyone who downloaded the app. It fetched the bundle from `github.com/casama-dev/casama`, which never existed (404). It built every image from source instead of pulling the published ones (D-197), which takes far longer and more disk than the sheet promises. It was offered on Windows, where the installer's bash and OpenSSL aren't there. It always used port 8080. It published Caddy and TURN on every interface although the sheet says only this computer can reach it. A Finder-launched Mac app has a bare PATH without `docker` or Docker Desktop's credential helper. And closing the sheet left the installer running.
- **Matching source and images:** `scripts/publish-images.sh` now moves the git tag `selfhost` to the commit it publishes as `latest`, and refuses a commit that isn't on `origin/main`. A `--only` publish gives the images it skipped the new `<short sha>` on their current build, so every published commit names a complete set. `--retag <tag>` points a new commit's tags at an existing build without building, for commits that change nothing inside the images. The app resolves `selfhost` to a commit (GitHub API, `Accept: application/vnd.github.sha`), downloads that commit's archive and runs `install.sh --local --pull <short sha>`. If the API is unavailable (anonymous rate limit), it downloads the tag's archive and pulls `latest`. The image tag it installed with is saved in `local-server.json` in the app's support folder and reused on later starts. A downloaded bundle is never replaced, because its `.env` holds the keys.
- **This computer only:** `install.sh --local` sets `HTTP_BIND=127.0.0.1` and the new `TURN_BIND=127.0.0.1`, so Caddy (HTTP, HTTPS, pages) and TURN listen on loopback. Compose publishes TURN on `${TURN_BIND:-0.0.0.0}:${TURN_HOST_PORT:-3478}` and gives the API `TURN_PORT=${TURN_HOST_PORT:-3478}` (the port clients use; the supervisor keeps the container's 3478). Servers with a domain are unchanged.
- **Ports:** on the first install the app picks the first free port, checking TCP and UDP on loopback and on every interface, from 8080 (HTTP), 8443 (HTTPS), 8790 (pages) and 3478 (TURN). It passes them as `--http-port` and a `--settings` file (`HTTPS_PORT`, `PAGES_PORT`, `CASAMA_PAGES_URL`, `TURN_HOST_PORT`), saves them, and reuses them later, when the stack itself holds them.
- **App:** offered on macOS and Linux only (not the Mac App Store build). Processes run with `/usr/local/bin`, `/opt/homebrew/bin`, `~/.docker/bin`, Docker.app's `Contents/Resources/bin` and `/snap/bin` added to PATH. Cancelling (closing the sheet) kills the installer and its child processes straight away rather than at its next line of output. Starting again resumes, because Docker keeps the layers already pulled. The installer's ANSI headings are stripped in the sheet.
- **Checked:** `client/test/local_server_test.dart` (pinned release and fallback, taken ports and reuse, cancel). A real `install.sh --local --pull … --settings … --no-start` run against the published images showed the loopback bindings, moved ports and the API's `TURN_PORT` in `docker compose config`. It also showed that only `server` had been published at `7473821a414a`, which led to the `--only` backfill.
- **Not yet:** Windows (it needs a PowerShell installer or WSL), and choosing where the bundle lives.

## D-217 Continue with Google uses Google's own sheet on Android, iPhone and Mac

- **Decision** (Oliver: "I want native for android and ios/macos"): Continue with Google opens Google's account sheet instead of a web page, the way Apple's sheet already does on iPhone and Mac (D-167). `google_sign_in` 7 returns an ID token and `signInWithIdToken` swaps it for a Supabase session, with a nonce (its hash goes to Google, the raw value to Supabase). Android uses Credential Manager's bottom sheet. iPhone and Mac use Google's iOS SDK, which is still a system web sheet run by Google's SDK, not our in-app page. Windows, Linux and the web keep the browser.
- **Which server accepts which token:** on Android the token is addressed to the server's web client (`serverClientId`); on iPhone and Mac to the iOS client. Auth must list both: `GOOGLE_AUTH_CLIENT_ID` is comma-separated, the web client first (the browser flow uses the first). The API reads the same two variables and returns the list as `google_client_ids` in `/v1/config`. The app uses the sheet only when its own client id is listed there. A self-hosted server with its own Google client gets the browser, never a refused token.
- **Falling back:** if the sheet can't run (no Google account or Play services on the phone, a Mac build without the keychain entitlement, a client Google doesn't know yet) the app opens the browser. Cancelling the sheet doesn't. The Google SDK can be set up once per launch, so its nonce is per launch. Signing out of Casama signs out of Google's SDK too, so the next sign-in offers every account.
- **Client ids:** Android takes the web client from the server (the first id in `google_client_ids`), so one build works with the dev stack ("Casama sign-in") and production (its own web client), both in project `kasama-ai` like the Android client. A server whose web client is in another Google project fails in Credential Manager and gets the browser. The SDK is set up once per launch, so after switching to a server with another client the app uses the browser until it restarts. The iOS id is a constant in `google_sign_in.dart` because Google's iOS SDK stops the app when its reversed id isn't a URL scheme in `Info.plist`; `google_sign_in_test.dart` checks the constant against both Info.plist files. While it is empty, iPhone and Mac use the browser.
- **Mac:** Google's SDK needs keychain sharing (`keychain-access-groups`, `$(AppIdentifierPrefix)com.google.GIDSignIn`). Only the Mac App Store build has it (`AppStore.entitlements`; `package-macos-appstore.sh` fills in the team prefix from the provisioning profile, since codesign doesn't expand it). The direct-download build would need a Developer ID provisioning profile for that entitlement, so it keeps the browser for now.
- **Android signing:** the Android OAuth client needs the SHA-1 of every key that signs installed builds: Play App Signing `9a:f7:04:78:33:be:64:e6:4a:55:63:42:9f:c4:bd:1a:d1:9b:05:0e` (read from a Play-generated APK), the upload key `a9:5c:e9:…:d3:d1:a5` (sideloaded release builds) and the debug key `8f:b5:a8:…:29:26`. They are also on the Firebase Android app. Google has no API for creating OAuth clients, so they were made in Cloud Console: three Android clients (one per key) and "Casama iOS and macOS" (`278631205206-ma3i1l9a9q2sb3ac2coeucm43nqqt2lj`).
- **Tests:** `google_sign_in_test.dart` (which platform asks for which client, which errors fall back, Info.plist in step); the server's config test (`google_client_ids` only when Google sign-in is on).

## D-218 A personal computer offers only what it can do

- **Problem** (Oliver: "why do I have the option to do those? we should hide not working features"): a computer connected with "Use this computer for bots" (D-066) is stored as a desktop computer, so the app offered Live View, Terminal, Checkpoints, Wake/Sleep and Switch to Headless on it. The desktop app never streams the person's screen and refuses the terminal and checkpoints, so Live View ended in a 503 (reported as a crash) and the rest failed or did nothing.
- **App:** a personal computer (`kind = local`) shows Connected or Offline instead of awake or asleep, a screenshot that refreshes every 5 seconds with a note saying why it isn't live, and Files while it's connected. It has no Live View, Terminal, Checkpoints, Advanced toggle, Wake/Sleep, Desktop/Headless pill, provider pill or Switch to Desktop/Headless. Offline, it says to open Casama on that computer and turn the setting on.
- **Server:** `POST /v1/computers/{id}/stream-session` answers 409 `not_on_companion` for a personal computer, before anything starts. A bot that calls `computer.request_takeover` there gets told to ask the person in chat to do the step on their own computer, and no takeover request is made (the card would lead to Live View).
- **Not done:** a real live view of the person's own screen. It needs screen capture in the desktop app with its own approval, a visible "being watched" sign, and a decision on control from a phone.
- **Tests:** `live_test.dart` (the panel connected and offline, the list's menu); `local.test.ts` (the 409 and the takeover answer).

## D-219 The live view puts the computer's screen first

- **Problem** (Oliver: "we need the best design for the Live View screen especially on mobile… put some options behind a menu"): on a phone the header, a three-line status sentence, a row of quick actions and a privacy note took about a third of the height. Held sideways, the computer's screen was a small box under all of it.
- **One status chip** in the header: a dot and Live, Screenshots, Connecting or Paused, plus the round trip while live. Tapping it says what Screenshots means ("live video can't get through this network…") and who has the screen. The dot is still, not animated, so the page doesn't redraw while it's open.
- **A dock at the bottom**, in reach of a thumb. Watching: who has the screen and Take Control. In control: Keyboard and Right-click (touch devices and phone-sized windows), Paste and Copy, then Hand Back. Phones push Hand Back to the edge, and it shrinks to its icon (with a tooltip) on the narrowest screens. Wide windows keep the tools and Hand Back together in the middle.
- **Behind ⋯:** Save Screenshot, and Teach a Task while you're in control.
- **Phone held sideways:** no header. When the black bars beside the screen are at least 72 pt wide (a 16:10 desktop on a modern phone), the controls go there: back, ⋯ and the status dot on the left; the tools and the main action (Take Control or Hand Back, round, with its name under it) on the right, so nothing covers the screen. Narrower bars get a floating dock instead. A bot's takeover request shows over the top of the screen, between the bars.
- **Upright phone:** when there's room under the screen, a line says to turn the phone for a bigger screen.
- **The privacy note** ("While you're in control, the bot is paused…") shows once, over the top of the screen, for 6 seconds after taking control. It doesn't take taps. A toast at the bottom would cover the dock just as the person reaches for it.
- **Checked:** phone (upright, sideways, 320 pt), tablet, light and dark, rendered from widget tests. `live_test.dart` covers the hint, the side bars and the ⋯ menu; `teach_test.dart` opens Teach a Task from ⋯.

## D-220 Deleting chats, and message actions on every device

- **Problem** (Oliver): there was no way to delete a chat short of deleting the account, and conversations are visible to everyone who can use the bot unless private. Web and desktop had no visible message actions (only extra items at the end of the right-click text menu), and a long-press on phones gave no sign it was registering.
- **Delete a chat:** `DELETE /v1/conversations/{id}`. The database rule already allowed the person who started a chat or a manager of its bot (`conversations_delete`); the route deletes under the person's session, so RLS decides (403 otherwise). Messages and attachments go by cascade, `chat_media` (no foreign key) is deleted too; runs, pages, routines, tasks and calls stay and are unlinked. Refused with 409 `conversation_busy` while a run in it is queued, running or waiting. Audited as `conversation.deleted` with the bot and kind, never the content.
- **Delete all chats with a bot:** `DELETE /v1/bots/{id}/conversations` deletes the direct chats the person may delete (theirs, or all for a manager); group chats and chats the bot is working in are left, and the reply counts them (`deleted`, `skipped`). Audited as `conversation.deleted_all` with the count.
- **Who sees the option:** conversation lists carry `can_delete` (started it, or `can_manage_bot` on the bot or a group's lead).
- **What stays, said in every confirmation:** usage records (billing and budgets stay right) and whatever the bot remembered, which lives in its memory, not the chat.
- **App:** Delete Chat in the chat's ⋯ menu (direct and group chats; a deleted direct chat starts fresh, a group chat goes back to Bots), a delete button and long-press on each row of the chat history, and Delete All Chats in bot settings above Archive. Not built: deleting single messages (the bot can't follow a thread with holes; edit and resend covers a wrong message) and a separate Clear (Delete plus New Chat).
- **Message actions:** with a mouse, hovering a message shows Copy, Edit (yours), Read Aloud and Share under it; the row's space is always kept, so nothing moves. Right-click keeps adding them to the text menu. On touch, a held bubble shrinks up to 4% as the long-press builds (none with reduced motion), then a haptic and the menu, now with rounded corners.
- **Tests:** `apps/server/test/delete-conversations.test.ts` (who may delete, cascade and media, runs kept, audit without content, 403, 409, delete all with a busy chat skipped and a manager's sweep); `client/test/delete_chats_test.dart`, `message_actions_test.dart`.

## D-221 One picker for every "pick one of these" sheet

- **Problem** (Oliver, on "Which bot should learn this?": "they don't look right… also check other UIs like this"): sheets that ask the person to pick one thing were each built differently. Teach a Task and Import Agent used a form sheet with Cancel as its main button, so Cancel showed twice, over plain text rows. Profile photo, Ask which bot, Move to and the call's audio output were bare list rows (some without a title). Desktop users at once was a stock `SimpleDialog`.
- **Decision:** all of them use `showChoiceSheet` (`ui/form_sheet.dart`), the picker the bot profile and quiet hours already used: the same header as forms (icon tile, title, a line of help), then the options as one grouped card of rows, a bottom sheet on phones and a dialog on larger windows. No Cancel button; a flick down, a tap outside or Escape closes it, like other pickers.
- **What the picker gained:** per-option keys, a `leading` widget (bot avatars, status dots), a `trailing` widget, destructive rows (Remove Photo in red), and asking without a current choice (`selected` left out: no checks, for "which bot" or "which source"). Settings pass `selected` and the current option is checked, as before, including a null value ("no folder").
- **Not changed:** the persona gallery and the model picker, which are full pickers with search and previews of their own.

## D-222 An answered request folds into one line

- **Problem** (Oliver, on a declined key request that still showed its title, hosts and the bot's whole reason: "we don't need this big of a card when we've already taken action"): approvals already fold into one line once decided ("Allowed: Making an image"), but key and sign-in code requests, takeover requests and device access requests kept the full card after they were answered.
- **Decision:** all four fold the same way, into one quiet line with an icon: "Saved STRIPE_API_KEY", "Declined: OpenRouter key", "No answer in time: Stripe sign-in code", "Handed back: <what the bot asked>", "Declined: <what the bot asked>", "Allowed to use your calendar", "Not shared: your calendar". The open card (field, buttons, reason) shows only while it waits for an answer. One widget (`_Folded` in `chat_widgets.dart`) draws all of them.
- **Tests:** `secret_request_test.dart` (declined, and declined earlier with no event), `live_test.dart` (handed back).

## D-224 An open chat follows what happens in it from any device

- **Problem** (Oliver): a message sent to a bot from the iPhone didn't show on the Android phone with the same chat open. An open chat only streamed runs it had started itself (the run's own `run:<id>` topic); it looked for other runs only when the chat opened or its own run ended.
- **Signal:** a trigger on `runs` (insert with a conversation) sends `conversation_activity` with `{kind: "run", run_id}` on the private topic `conversation:<id>` (`20270124000001_live_conversations.sql`). Joining needs `can_access_conversation`, the same check as reading its messages; the message carries only ids. Status changes and runs outside a conversation stay quiet.
- **App:** the chat subscribes while a conversation is open (`watchConversation`). When a run starts that it isn't already following, it waits 400 ms (a message sent on this device attaches its own run first), then reloads the thread and streams the run, exactly as if it had started there. After Realtime reconnects (a phone waking up), it checks again. While its own run is going it leaves the event alone: the existing end-of-run check picks up the next run.
- **Covers:** another device of the same person, a teammate in a shared chat, routines and watchers that post into a chat, group-chat @mentions.
- **Tests:** `supabase/tests/live_conversations.test.sql` (announced once per run, ids only, quiet otherwise, who may listen), `client/test/live_conversation_test.dart` (a message from another phone appears and its reply streams in).

## D-225 The bot list updates live on every device

- **Problem** (Oliver): a bot created on the Android phone didn't appear in the Mac app's list until it reloaded. The list was fetched when the app or workspace opened, and on this device's own changes, but nothing told it about another device's.
- **Signal:** a trigger on `bots` (insert, update that changes something, delete) sends `bots_changed` on the workspace's private topic `org:<id>` (`20270123000001_live_bot_list.sql`). Joining needs workspace membership (`is_member`). The message is `{kind: "bots"}` and nothing else, so a member never learns about a private bot they can't see; the refetch goes through RLS like any other read.
- **App:** while signed in to a workspace, the bot list keeps one subscription to that topic (`watchBotsChanged`). A change refetches the list once per 400 ms burst (a reorder touches every bot) and updates it in place: no skeleton, no provider reload, no new subscription. Archived bots refresh with it. After Realtime reconnects (a laptop waking up) it refetches once, in case something changed meanwhile.
- **Cost:** one small private channel per open app on the Realtime connection the app already has. Bots change rarely: creation, edits, archiving, and status (working, idle, waiting) a few times per run, which also keeps status dots right on other devices. Each burst costs one bot-list read per open app.
- **Checked:** `supabase/tests/live_bot_list.test.sql` (announced on insert, update and delete, quiet on a no-op write, no bot in the message, who may listen), `client/test/live_bot_list_test.dart` (another device's bot appears in place, once per burst; a status change shows), and end to end on the local stack: a signed-in member joined `org:<id>`, a bot was inserted with SQL, and `bots_changed` arrived.

## D-226 Thumbnails for videos and PDFs on a bot's computer, never at the cost of waking it

- **Problem:** a video a bot linked from its computer (`[clip.mp4](workspace/clip.mp4)`, or `/Users/me/Desktop/…` on a personal computer) showed a dark tile, because the app could only download the whole file. PDF cards for computer files did download the whole file just to draw page one, which also woke a sleeping computer (`downloadComputerFile` goes through `ensureRunning`).
- **computerd:** `GET /files/thumbnail?path=&size=` (size 128–640, default 480). Same path rules as `GET /files` (personal computers: shared folders only, `files` capability). Videos: one frame with ffmpeg's fast input seek (`-ss 0.5`, then `-ss 0` for very short clips), scaled to fit `size`, JPEG at `-q:v 6`, plus the length from ffprobe in `x-duration-ms`. Images through ffmpeg, PDFs through `pdftoppm` (page 1). On a Mac, Quick Look (`qlmanage -t`) does all three and `sips` turns its PNG into a JPEG; the length comes from `mdls`, else ffprobe. The response carries `x-file-mtime`. No tool, an unsupported file or a failure: 404 `no_thumbnail`. Code: `dart/computerd/lib/src/thumbnails.dart`.
- **Cost rules on the computer:** one thumbnail job at a time (a queue; more than 6 waiting gets 503 `thumbnail_busy`); the whole job, every tool included, is killed at 8 s; results are cached on disk under a hash of path, modified time, size and requested size (bot computers `~/.cache/casama/thumbs`, left out of sleep archives and checkpoints; personal computers the temp folder `casama-thumbs`), at most 200 files or 50 MB, least recently used dropped first. A file that has no thumbnail is remembered too, so it costs nothing next time. Typical result 10–20 KB.
- **API:** `GET /v1/computers/{id}/files/thumbnail?path=&size=` (`computerFileThumbnail`). It checks the person can see the computer (RLS), then uses `ComputerService.ifRunning`, which returns a handle only when the stored state is running/idle and the provider confirms it (a personal computer: connected). It never starts, wakes or restores a computer, never waits for one, and doesn't touch `last_active_at`, so looking at thumbnails never keeps a computer awake. Not running: 409 `thumbnail_unavailable` at once; the relay gives up after 15 s with the same answer. Nothing is stored on the server; responses are `cache-control: private, max-age=86400`. The relay goes through every provider's handle (`thumbnail?` on `SandboxHandle`: Docker, the supervisor's new `/computers/:ref/files/thumbnail`, which answers 409 when not running, hosted providers, and the device tunnel).
- **Personal computers:** the device tunnel lets requests through only for a bot the owner allowed. Thumbnails have no bot, so the API sends `x-casama-viewer` (the signed-in person) and the tunnel lets `GET /files/thumbnail` through when that person owns the device (`local_devices.user_id`). Other workspace members get 409, and the shared-folder limit still applies on the device. Full downloads keep the bot-only rule.
- **Owner reads (Oliver: a video from his Mac failed with 503 `computer_unavailable`):** the same viewer exception covers `GET /files` and `GET /files/list`, so the owner can open, play and list files in their shared folders from the app with no bot involved. Read-only: uploads and deletes still need a bot the owner allowed. A refusal from the device is now 403 `computer_forbidden`, not 503 "try again shortly". Test: `local.test.ts` (owner opens and lists, outside the shared folders refused, another member 403, a write refused).
- **App:** `ChatVideo` asks for a computer video's thumbnail once the card has been on screen for 250 ms, so cards scrolled past ask for nothing. It shows the thumbnail as the poster (fading in, shaped by its aspect ratio when the chat doesn't know the size) with the length from `x-duration-ms`. `ComputerThumbnails` sends one request per file at a time and keeps results in memory and on disk for a day (bots rewrite files under the same name). No thumbnail is quiet: the dark tile stays, and the file isn't asked about again for 2 minutes. Computer-file PDF cards use the thumbnail too and download the file only when opened. They no longer show a page count, and without a thumbnail they show the PDF icon.
- **Not covered:** computers running an older image (the route is new in computerd) answer 404, so they keep the plain tile until their image is updated. On Windows, and Linux companions without ffmpeg or poppler, there are no thumbnails.
- **Tests:** `dart/computerd/test/thumbnails_test.dart` (frame and length, cache hit runs no tool, a changed file is redone, short-clip fallback, unsupported or missing tool, the "has none" answer is cached, shared folders and capability, the time limit kills the tool); `apps/server/test/computer-thumbnails.test.ts` (relays bytes and headers from a running computer without touching `last_active_at`; sleeping, stopped or vanished computers get 409 with no start, resume or even provider lookup; 404 and errors; outsiders refused); `apps/server/test/local.test.ts` (owner only, shared folders only, through the real tunnel and computerd); `client/test/computer_thumbnail_test.dart` (poster and length, quiet fallback, no request for cards scrolled past, one request per file, the PDF card).

## D-227 Computer cards say what the machine is

- **Problem** (Oliver): a computer card said little more than its name and state, and its second line repeated the name ("Team computer / Team computer", "This computer / This device").
- **API:** `Computer` gains `os` (display text, null when unknown) and, for personal computers, `device` (`platform`, `online`, `last_seen_at`, `capabilities`). Both are optional in the contract, so an app built against an older server still parses. Cloud computers on Docker report `Ubuntu 24.04`, the base of `infra/images/computer/Dockerfile.*` (`DOCKER_COMPUTER_OS` in `routes/computers.ts`; update it with the image). Other providers report null rather than a guess. `LocalDevice` gains `os_version`.
- **Desktop app:** on each connect it sends `x-casama-os`, a readable name built from `Platform.operatingSystemVersion` ("macOS 26.2"; on Windows the quoted product name, with "Windows 10" read as "Windows 11" from build 22000 on, since the registry still says 10; on Linux `PRETTY_NAME` from `/etc/os-release`). The API keeps it in `local_devices.os_version` (`20270125000101_device_os_version.sql`), after turning control characters into spaces and cutting it to 80 characters. It is display text only; nothing decides on it. Until a device reports, its card shows the platform ("macOS").
- **Card:** whose computer it is only when the name doesn't already say so; a system line (`Ubuntu 24.04 · 1 CPU · 1 GB RAM · 10 GB disk`, or `macOS 26.2 · This device` on the machine itself); for a personal computer, what bots may use (`Bots can use: Files, Terminal`); a "Saved" pill when its files are kept while stopped (`has_snapshot`); and below the pills either the error in red or, when it isn't on, `Last used 2 hours ago` / `Last seen 5 minutes ago`.
- **Left out:** live CPU and memory use (polling and new server work for little value) and IP addresses (a privacy detail). Machine model names were left out too: macOS only gives codes like `Mac16,1`.
- **Tests:** `apps/server/test/computer-details.test.ts` (platform and access before a report, the reported OS cleaned and kept over a real device socket, single read, outsiders get 404, cloud OS, the cleaner); `client/test/computer_details_test.dart` (OS names per platform, sizes, the cards, this machine, an older server).

## D-228 Waiting runs survive a redeploy

- **Problem** (Oliver): a chat replayed the same request cards every time it opened. The full key card flashed, then "Allowed: Making an image" and "Declined: OpenRouter key" stuck at the bottom, long after both were answered. The run was still `waiting_approval` 11 hours later. DBOS stamps each build with a hash of its code and recovers only workflows that carry its own hash. The worker was rebuilt while the run waited for the key, so nothing ran its workflow again. Declining signalled a workflow no process was running, and the app re-attached to the "active" run on every open and replayed its events below the history.
- **Decision:** the worker sets one DBOS `applicationVersion` (`casama`, overridable with `DBOS__APPVERSION`). Workflows waiting on approvals, keys or takeovers resume after any redeploy, as D-048's "waits survive worker restarts" always meant. A run whose recorded steps no longer match the new code throws on replay (DBOS codes 26/37). `agentRunWorkflow` then marks it failed with a direct write, not a DBOS step, and appends `run.failed` with "Casama was updated while this was waiting…". The old fallback was itself a step, so on a mismatched replay it never ran, and `leftover-after-stop` threw outside the try: the workflow ended in ERROR with the run still waiting. The leftover step is now guarded too.
- **Repair:** pending workflows stamped with an old hash were restamped to `casama` once (local stack: the stuck run, which replayed, failed cleanly and got its `run.failed`; prod had none).
- **Tests:** none automated (DBOS recovery across versions needs two builds). Verified on the local stack by replaying the real stuck run.

## D-229 Timeouts on every outside call

- **Problem** (Oliver asked whether everything that could hang has a timeout): most paths did, but several waited on Node's or the OS's defaults (5 minutes, or none). A model that went quiet after its first words held a run for up to 5 minutes; vendor APIs (Stripe, Twilio, Infisical, AWS KMS, Treg, maps, the knowledge crawler, GitHub, embeddings) only had a connect limit; a few plain `fetch` calls had none at all (supervisor health check, egress control, the live-view login, the device tunnel's online check, iMessage polling); Postgres had no statement or idle-in-transaction limit; the app's Supabase calls had none.
- **Models:** after the first event, a gap of 90 s between events ends the stream as `model_timeout` (`idleTimeoutMs` in `withFallback`). The clock pauses while the run handles an event. Output already shown means no retry, as before.
- **Vendor APIs:** `withTimeout(fetch, ms)` (safe-fetch.ts) puts one deadline on headers and body: Infisical 15 s, Stripe and Twilio 30 s, Treg 60 s, maps 15 s, crawled pages 20 s, GitHub 30 s, AWS KMS 10 s, embeddings 45 s across their retries. The shared bot fetch keeps Node's limits on purpose: MCP tool calls and `http.request` can take minutes before the first byte and have their own limits.
- **Postgres:** every `createDb` connection gets `statement_timeout` 60 s, `idle_in_transaction_session_timeout` 60 s and a 10 s connect limit. Paths that legitimately take longer lift them for their own transaction: `liftTimeouts(tx)` in `ensureRunning` (provisioning holds the computer lock), the project heartbeat and iMessage poll (network calls under a tick lock), and the privacy export; `withoutTimeouts(db, fn)` around the retention delete, workspace and user purges, and the device-data purge. DBOS's own pool is separate and unchanged. A new transaction that awaits the network must lift them too, or move the call out.
- **App:** the Supabase client uses `TimeoutHttpClient` (30 s to the first byte, 30 s between body chunks); the voice call's SDP exchange gives up after 15 s; the auth settings read has 10 s/15 s. The SDK's Dio already had 10 s/60 s.
- **Tests:** `packages/agent/test/fallback.test.ts` (a stream that goes quiet after output; the caller's own time doesn't count), `client/test/timeout_http_client_test.dart`.

## D-230 A chat lets go of a run that has ended

- **Problem** (Oliver): the composer showed Stop on an empty field while the bot wasn't doing anything, and pressing it did nothing. The chat still thought a run was going: it follows a run until that run's last event arrives, and when that event never reached the device (a phone or laptop asleep through it, an event held back behind a gap), the chat kept following a run that had ended. Stop then asked the server to cancel a finished run, which answers `409 run_finished`, and nothing changed.
- **Following a run:** the catch-up the chat already does every 2 seconds while a run is open now reads the run's status, which `GET /v1/runs/{id}/events` already returned. When the server says the run is completed, failed or cancelled and no more events are coming, the chat stops following it, but only after the run has stayed finished for 1.5 seconds, because the worker marks a run finished a moment before it writes the last event. A run that is gone (`404`, its chat deleted) is let go at once.
- **Stop:** `cancelRun` turns `409 run_finished` and `404` into `RunAlreadyFinished`; the chat then clears the run, reloads the conversation and refreshes the bot list, so Stop never does nothing.
- **Tests:** `client/test/stop_finished_run_test.dart` (Stop on a run that had already ended clears it).

## D-231 A reply can't link to a file the bot never made; offline personal computers say so

- **Problem** (Oliver): a bot answered "Done! Open it here: [index.html](workspace/bots/casama/index.html)" in a run with no tool calls. It had made nothing, so opening the link could only fail. The same tap happened while the API restarted, when the person's Mac was briefly offline, and every failure read as "Your Casama server isn't responding".
- **File links are checked:** when a chat run's final reply links to computer files (Markdown links and images, read with the app's `computerPathFromLink` rule, ported to `packages/agent/src/file-links.ts`), the worker lists each file's folder on the bot's computer. If one isn't there, the streamed draft is taken back (an empty `message.completed`, which the app already removes) and the model gets one more turn with a note: make the file now with tools, or reply again without the link and say plainly what it did and didn't do. Once per run, at most 5 links, 15 s at most. It fails open: no computer, an offline or unreachable one, or someone else's personal computer skips the check, so a reply is never held back because the check couldn't run.
- **Offline personal computer:** a computer route whose personal computer isn't connected answers `409 device_offline`, "This computer is offline. Open the Casama app on it and turn on \"Use this computer for bots\"", instead of `503 computer_unavailable` "try again shortly".
- **Reconnect grace:** when the API restarts, every desktop app drops its tunnel and dials back within seconds (backoff from 1 s). Starting a personal computer now waits up to 8 s (`LocalProvider` `reconnectGraceMs`) for the device before it's offline, so a call in that gap doesn't fail. Checking whether it's online (`get`) never waits.
- **Tests:** `packages/agent/test/file-links.test.ts` (the link rule, missing files, failing open, a run whose made-up link is taken back and one whose real link is kept), `packages/sandbox/test/local-reconnect.test.ts`, and `apps/server/test/local.test.ts` (opening a file on an offline computer).

## D-232 One still wallpaper behind every page; pages and tabs fade through instead of flickering

- **Problem** (Oliver, screen recording on an Android phone with a wallpaper): screens flickered almost everywhere, worst with a wallpaper and on phones. Frame by frame, five causes:
  - Flutter's Android transition (`FadeForwardsPageTransitionsBuilder`) paints the theme's surface color behind the page it leaves and fades that page out faster than the new one fades in, so the wallpaper blacked out for a moment on every page (Settings → About you dipped from 55 to 45 average brightness in one frame).
  - Each page painted its own copy of the wallpaper inside its transition, so the copy slid and faded with the page. It was drawn once where the page started (stretched over the off-screen part), travelled with the page, then jumped into place when the transition ended.
  - Switching tabs crossfaded two see-through pages: the router keeps the old tab fully shown until the new one has faded in, so both lists showed on top of each other ("Chats" over "Inbox").
  - A page opened from a tab faded in over the tab, which never moved, and closing it was a 75 ms fade-out: an overlap one way, a cut the other. Our wrapper around the platform transition also dropped its duration and its delegated transition.
  - The Inbox's suggestions and briefs (`forYouProvider`), skill ideas and pages were auto-disposed, so every visit started from skeletons.
- **Decision:**
  - **One wallpaper, painted once:** `MaterialApp.builder` paints the `Wallpaper` behind every navigator. Pages are see-through over it, so it never moves, reloads or blacks out.
  - **Android: shared axis** (`SharedAxisPageTransitionsBuilder`, `client/lib/theme/page_transitions.dart`). The page leaving fades out in the first 30% of 300 ms while moving 30 dp aside. The page arriving fades in over the rest while settling 30 dp. The two are never on screen at once. Its delegated transition moves tab pages aside the same way. Full-screen dialogs rise 48 dp on their own copy of the wallpaper, so they cover the page under them.
  - **iOS keeps its slide and back swipe** (`OpaquePageTransitionsBuilder` around `CupertinoPageTransitionsBuilder`, now with its own 500 ms duration and delegated transition). A sliding page must cover the one under it, so each page still paints the wallpaper. `Wallpaper` now repaints on every frame its route moves, lined up with the window, and covers only the window, so the wallpaper looks still under the moving content.
  - **The web and desktop** still switch at once (`InstantPageTransitionsBuilder`): they are click and open.
  - **Tabs fade through** (`fadeThrough`, 250 ms). The tab you leave fades out on the new tab's animation in the first 35%. The new one then fades in and grows from 98%.
  - **Kept lists:** `forYouProvider`, `skillProposalsProvider`, `projectsProvider` and every bot's pages (`pagesProvider(null)`) stay loaded. The Inbox and Tasks reload them just after opening (`refreshKeptOnOpen`) while still showing what they showed.
  - **Loading fades:** `AsyncView` fades through from skeleton to list (or error). New data in the same state just rebuilds.
- **Tests:** `client/test/page_motion_test.dart` measures each page's opacity frame by frame. It checks that two pages or tabs never show together on a push, a pop, a tab switch, or a page opened from a tab and closed again. It also checks that nothing opaque is painted behind the leaving page, that iOS and full-screen dialog pages paint their own wallpaper, and that the Inbox reopens without skeletons. `client/test/page_transitions_test.dart` checks the instant desktop transition.

## D-233 Casama Cloud shows no provider or model anywhere; the new-bot sheet leads with the persona

- **Why** (Oliver, 2026-11-12): on Casama Cloud nobody can change the provider or model (D-188), so showing them only adds noise. The new-bot sheet should be as simple as it can be.
- **Cloud (billing on):**
  - The bot profile no longer names the model under the bot's name.
  - Settings shows **Service keys** ("Your own search, maps or data keys") instead of Model keys. The page lists and adds only Brave Search, Tavily, Google Maps, Mapbox and Treg (`cloudKeyProviders`). Chat, voice and media keys, the Casama Cloud row and ChatGPT sign-in are hidden. The web tab title follows. Casama Cloud will soon supply these keys too: remove each provider from `cloudKeyProviders` once it does. When the list is empty, the Settings row disappears.
  - A failed run's one-tap fix no longer points at keys or "Choose a model". Out of credits still leads to plans.
  - Already hidden before this (D-188): key and model fields in the new-bot sheet, bot profile, template import and agent import, and voice provider menus.
- **New-bot sheet, top to bottom:**
  1. Title and subtitle.
  2. **Persona:** a row of quick-pick chips (Blank plus up to six personas, with the chosen one always included) and "Browse all" for the gallery. Below that, one card shows the chosen persona (with its routines) and holds the instructions it fills in. Picking a persona fills in the instructions, name and icon further down.
  3. **Name and icon:** one card with a live avatar next to the name field, and the mascots in one row that scrolls sideways (`MascotPicker(scrollable: true)`) instead of wrapping.
  4. Advanced (key and model, self-hosted only), then Create.
- **Tests:** `autonomy_test.dart` (quick-pick chip fills persona, name and routines; Blank clears them), `cloud_model_picker_test.dart` (Cloud keys page), `bot_profile_test.dart` (no model name on Cloud).

## D-234 The bot says hi first on every call; a better new-group sheet

- **Calls:** a live call the person starts now opens with the bot speaking, like someone picking up a phone. `POST /v1/voice/session` without a `call_id` adds `answerGreeting(name)` to the call's instructions (say hi in one short sentence, by their preferred or first name when known, and ask what it can do) and returns `speak_first: true`; the app already acts on that (Gemini Live sends a "connected" turn, OpenAI Realtime a `response.create`). A phone call the bot placed keeps `callGreeting(reason)`.
- **New group chat sheet:** a strip at the top shows the group so far, the lead first with a crown; tapping another bot there makes it the lead and its small x takes it out. The name field shows the name an unnamed group will go by. The bot list has faces, what each bot is doing, a check that shows the order it joins in (a crown for the lead) and a live "n / 10" count; once ten are picked the rest dim. A search field appears past six bots. The note under it says what's missing (pick n more), that the group is full, or what the lead does. Archived bots aren't offered.
- **Local MCP servers stay visible on phones and the web:** they run on the desktop through computerd and the tunnel (D-096), so a bot reached from any device can use them while that computer is online. Adding one stays desktop-only.
- **Tests:** `voice.test.ts` (speak first and the greeting in the instructions), `group_chats_test.dart` (change the lead, remove from the strip, button off until two bots).

## D-235 Search suggests before you type, scopes, works from the keyboard, and opens the item itself

- **Before typing** (it used to say "Type at least 2 characters."), the panel answers "where was I?" and "where can I go?", with each section hidden when empty: **Recent** (the last five searches someone opened a result from, as chips with a remove x and Clear; kept on the device in shared preferences under `search.recent.<user>.<workspace>`, so one account never sees another's, and saved only when a result is opened, never per keystroke), **Jump back in** (the four bots with the most recent chats, from `Bot.last_message`, opening that conversation), **Needs you** (one row with the Inbox count, only when something waits) and **Go to** (Quick ask, Tasks, Skills, Settings). Nothing goes to the server until something is typed.
- **While typing:** from the first letter, bots and places (chats, Inbox, tasks, projects, pages, skills, computers, usage, settings, matched by name or a few other words) show at once under **Top hits**; server results join from two characters as before. Rows have one look: a bot's face or a tinted icon, a title, and a line with the bot's name and time for messages and chats plus the snippet, matches bold on a soft tint (they were amber text). Earlier results stay up while new ones load under a thin progress bar; the field has a clear x; errors have Try again. Files show the file name with the computer and path under it.
- **Scope chips** (All, Chats, Memories, Skills, Routines, Tickets, Files) under the field; once an unscoped search returns, each chip shows its count. A scoped search sends `kinds` to `GET /v1/search` (comma-separated `message`, `chat`, `memory`, `skill`, `routine`, `ticket`, `file`): the server returns up to 25 of each kind asked for instead of 8 and searches files only when `file` is listed, so scoping to memories never wakes a shell on a computer. Chats covers chat titles and messages.
- **Nothing found** offers "Ask BOT about "query"", the bot you talked to last, which opens Quick ask with the question filled in (`/quick-ask?bot=…&text=…`); the same row sits at the end of every result list.
- **Keyboard** (tablet and desktop windows): the first row starts selected, up and down move (the pointer moves it too), Enter opens, Escape clears the query and then closes; a line under the list says so and the selected row shows ↵.
- **Results open the item:** a memory opens its edit sheet, a skill its editor (`?focus=<id>` on `/bots/{id}/memory` and `/settings/skills`), a routine scrolls into view and glows (`/bots/{id}/routines?focus=<id>`), and a ticket opens the board with its ticket sheet on top. `routeFocus`, `OpenOnce` and `FocusHighlight` (`ui/route_focus.dart`) are there for any other screen a link should land inside.
- **Tests:** `search.test.ts` (scoped kinds, no files, bad kind rejected), `search_test.dart` (suggestions and opening a recent chat, one-letter matches without the server, scope chips, recent searches saved, rerun and cleared, ask a bot when nothing is found, arrow keys and Enter open a ticket's sheet, Escape clears, a memory link opens that memory).

## D-236 The paywall opens on top of everything, with the mascots

- **Bug:** a plan limit hit inside a sheet (New bot is the common one) showed a "See plans" confirmation that pushed Billing onto the tab's navigator, under the sheet on the root navigator, so nothing seemed to happen until the sheet was closed. `showPaywall` now opens the paywall straight away as a full-screen route on the root navigator (`openPaywall`, `features/billing/paywall.dart`), above any sheet or dialog. Closing it goes back to the sheet as it was, so the person can tap Create again after upgrading.
- **Paywall:** five bots bobbing in an arc on a glowing halo (still with Fewer effects or reduced motion), the reason in a small pill ("Your plan allows 2 bots."), "Grow your crew with Pro", and a card of perks, each with its own bot, showing the Pro amount next to the current one struck through (bots, computer hours, monthly credits, seats, from the plan catalog). The paid plans sit side by side with the button, pinned to the bottom so the price is always visible; yearly starts selected and wears Best value. The button buys through the store when there is one (Subscribe for the store's price) and web checkout otherwise; US iOS also gets Subscribe on the web. Restore sits top right on store builds. Members see who can upgrade instead of a buy button. When the plan turns paid while it is open (a verified store purchase, or coming back from web checkout, which refreshes billing on resume), it celebrates and closes.
- **Also:** "Out of credits" in a chat opens the paywall instead of Billing; Billing shows an Upgrade to Pro banner on the free plan that opens it. The server's limit message drops "in Billing" ("Your plan allows 2 bots. Upgrade to add more."). `paywall_view` and `paywall_dismiss` carry `source` `limit`, `credits_depleted` or `settings`.
- **Tests:** `billing_test.dart` (a 402 inside a sheet opens the paywall in front of it, checkout runs, closing returns to the sheet; a store purchase closes it with `true`).
- **Superseded in part by D-244 and D-248 (2026-11-13):** plans side by side with a Best value ribbon became tier and period pickers (D-244). The headline names the chosen plan, and Out of credits opens a sheet of credit packs for a paying workspace (D-248).

## D-237 Apps lead with everyday tools; developer tools go last

- **Why:** the catalog was ordered and featured like a developer's: GitHub, Sentry and Linear led Popular, and Developer was the first category. Casama is for everyone, so the apps most people use come first.
- **Popular:** Gmail, Google Calendar, Google Drive, Google Docs, Google Sheets, Notion, Slack and Zapier. GitHub, Sentry, Linear, Jira & Confluence, Stripe, Figma and Composio leave the row; they stay in the catalog. On Casama Cloud without Composio the Google apps aren't offered, so the row shows Notion, Slack and Zapier.
- **Order:** `APP_CATALOG` (which sets both the Popular row and All apps) runs Google, productivity (Notion, Slack, Asana, monday.com, Box, Jira & Confluence), data & search (Exa, Airtable), automation (Zapier, Composio, Pipedream), design, sales & support, payments, then developer. PostHog and Hugging Face move from Data & search to Developer, so that category holds only everyday tools.
- **Category chips:** the app sets their order (`appCategoryOrder` in `integrations_screen.dart`): Google, Productivity, Data & search, Automation, Design, Sales & support, Payments, Developer. It no longer follows the API enum's order. A category added later shows after these.

## D-238 Data key rotation, for when the database leaks

- **Why:** rotating the server key (D-136) only rewraps each data key. If an attacker has a copy of the database and the old server key, they can open the data keys in that copy, and rotation never changes them. A leak like that needs new data keys and every row re-encrypted onto them.
- **Keys:** `org_keys` and `user_keys` (D-169) get `retired_at`. Each workspace or person has one current key (a partial unique index on `retired_at is null`) and any number of retired ones. A retired key still opens rows, since sealed values name their key (`enc:v1:<keyId>:…`), but it seals nothing new. The key ring loads every key and seals only with the current one.
- **Replacing:** `POST /v1/orgs/{id}/encryption/replace-key` (owners, audited as `encryption.key_replaced`) retires the workspace's key and makes a new one in one statement, so two calls at once can't leave two current keys. It also replaces the About you keys of the workspace's members. `POST /v1/admin/encryption/replace-keys` (instance owner) replaces every data key on the server. `replaceDataKey` needs encryption to be on or turning on (409 `encryption_off` otherwise). `GET …/encryption` gains `rekeying` (optional in the contract, so older servers and apps still parse each other).
- **Resealing:** `sweepReplacedKeys` runs with the worker's minute sweep. For each retired key it finds rows sealed with it (500 per column per pass), opens them in the process and seals them with the current key. Postgres never sees plaintext. It covers the D-136 columns, `invite_links.share_token`, device data (`device_readings.summary`, `device_requests.result`, sealed with a workspace key of the owner's, D-149/D-150) and About you. Rows are updated by `tableoid` and `ctid` and only if the column's hash is unchanged since it was read, so a concurrent edit is never overwritten.
- **Deleting an old key:** only when no rows are left on it, 15 minutes after it was retired (for a server process that hasn't heard about the new key yet), and when `content_key_in_use(key)` finds nothing. That function scans every text and json column in `public`, nested values too, as security definer so row level security can't hide a row. A key still in use stays and is checked again every 15 minutes.
- **Fixes found on the way:**
  - The hourly `rewrapAllKeys` rewrapped workspace keys only, not people's About you keys. After a server key change and dropping `CONTENT_ENCRYPTION_KEY_PREVIOUS`, those keys couldn't be unwrapped and the key ring failed to load. It now rewraps both, and `rotateEncryptionKey` rewraps a workspace's retired keys too.
  - Turning encryption off deleted the workspace key even when device data was still sealed with it, which made that data unreadable. A key that's still in use is now kept, retired.
  - `invite_links.share_token` is sealed at write, but wasn't in the sweep's column list, so turning encryption off left it sealed. It's in the list now.
  - Production had no `CONTENT_ENCRYPTION_KEY`, because `install.sh` never generated one. The server got one on 2026-11-12, and `install.sh` now generates it unless AWS KMS is set.
- **Tests:**
  - API (`encryption.test.ts`):
    - Owners only.
    - New writes go to the new key at once, and old rows read in the meantime.
    - The sweep leaves nothing on the old workspace or person key.
    - A stray value sealed with the old key in an unlisted column keeps that key alive, and the key is deleted once the value is gone.
    - A fresh key ring that never held the old keys reads everything.
    - Changing the server key rewraps About you keys.
  - pgTAP (`encryption_rls.test.sql`):
    - One current key per workspace.
    - The in-use check finds a value in any column.
    - App sessions can't run it.


## D-239 Anyone can add an app to the catalog through the gallery

- **Decision** (Oliver asked, 2026-11-12): the app catalog was a list in the server's code (`APP_CATALOG`), so a new vendor server needed a code change and a server deploy, and outside contributors had no clear way in. Apps now also come from the open gallery (D-184): a folder `apps/<id>/` with `item.json`, `app.json` and an optional `logo.svg`, proposed by pull request and approved by a maintainer (Oliver, through CODEOWNERS). A merge reaches every server within the 15-minute cache, with no app build and no server release.
- **Built-in apps stay in code.** They keep their ids and come first. What only they can do stays there, behind code review: the Google category (it shares the server's Google client), admin-registered OAuth clients, Composio routing, inbox scopes and the Popular row. A gallery app connects through its own sign-in (`dcr` or `cimd`), an API key or nothing.
- **Checked twice.** `@casama/domain`'s `checkAppDocument` runs in the gallery checker and again on the server for every entry it reads, so a bad index can't put an app in the catalog. URLs must be https on a public host name (no IP addresses, ports, credentials or internal names), an API key can't go in a header such as Host or Cookie, and a logo is one SVG with no scripts, styles, links, images or entities, at most 24 KB. A gallery id that matches a built-in one is skipped.
- **Own file, so nothing shipped breaks.** Apps are written to `apps.json`, not `index.json`. Servers already deployed pass index items straight to apps, and the apps' generated parser only knows the four look and skill types, so an `app` item in `index.json` would have broken the gallery in every installed app. The gallery website reads both files.
- **Logos.** The catalog response gains an optional `logo_url`. The app draws the mark like a bundled one, tinted on the brand color (`galleryAppMarks`, filled when the catalog loads), and falls back to the initial. Older apps ignore the field and show the initial.
- **Retiring.** `"retired": true` or removing the folder hides the app from the catalog. Existing connections keep working: they store their own URL.
- **Seed entries:** Canva (`https://mcp.canva.com/mcp`, OAuth with dynamic client registration) and DeepWiki (`https://mcp.deepwiki.com/mcp`, no sign-in), both checked live on 2026-11-12. Neither has been connected end to end from the app yet.
- **Not covered:** the generated Dart enums for `category` and `auth` still have no fallback for unknown values, so the gallery can only use the categories and sign-in methods apps already know. Adding a new one later needs those enums to accept unknown values first, then an app release.
- **Tests:** `packages/domain/test/gallery-apps.test.ts`, the app cases in `apps/server/test/gallery.test.ts`, `client/test/gallery_app_logo_test.dart`.

## D-240 Managing a computer: fix it, see what it costs, what it holds and what happened

- **Decision** (Oliver asked, 2026-11-12, design approved before building): people had Start, Sleep, Rename, Delete and the Checkpoints tab, but no way to fix a computer that misbehaves, see its cost or space, or set when it sleeps. The computer screen gets a **Manage** tab next to Screen and Files. Restore points move into Manage, so the Checkpoints tab goes; Advanced now shows only the Terminal.
- **Fixes in order, not three unrelated buttons.** "Not working right?" lists Restart (about 20 s, nothing lost), Reset system (a fresh system, ~/workspace kept) and Erase everything (like new). Each step says up front what it costs. Sleeping already archives the home folder and throws the container away, so a restart is sleep then wake. A reset clears the home folder except ~/workspace (erase: all of it), puts back `/etc/skel`, then sleeps and wakes. Both run on the computer as shell scripts, so they work on every provider.
- **Every reset can be undone.** The reset sheet saves a "Before reset" restore point first (on by default) and lists what's kept and what's removed side by side. Erasing also needs the computer's name typed. Resets run in the background: `POST /v1/computers/{id}/reset` returns 202 and `computers.operation` records the steps (saving, wiping, restarting, done or failed). The app polls every 3 s and shows the steps ticking off, and when it finishes, a toast and a card offer Undo (restore that point). Only one reset runs at a time (409 `reset_in_progress`). One not finished after 20 minutes counts as abandoned. Idle sleep skips a computer while a reset runs. Only the bot's managers (or admins, for the team computer) can reset.
- **Looking never wakes or costs.** Vitals (CPU and memory from the container's cgroup, disk from the home folder's size, cached for a minute in /tmp), storage and running programs are read only from a computer that's already running (otherwise 409 `computer_not_running`), and reading doesn't count as activity. The header shows three small meters while the computer is on. Disk turns amber at 80% and red at 90%, and tapping a meter opens Manage.
- **Storage:** a breakdown (your files, apps and tools, caches, browser, other) against `size.disk_gb`, and Free up space, which removes caches and the browser's caches only, never ~/workspace, installed tools, settings or sign-ins.
- **Running now:** programs, busiest first. A helper process whose parent has the same name is folded into that parent, so Chrome shows once. The computer's own parts (pid 1, computerd, the desktop stack, root-owned processes) are marked system and can't be stopped. Stop asks first, sends TERM, then KILL after 3 s.
- **Sleep timer per computer:** 5, 15, 30 or 60 minutes (`computers.idle_sleep_minutes`; null means the default 5). The help text says a longer wait costs more.
- **Usage:** computer-seconds now record their computer (`usage_ledger.computer_id`; older rows have none). Manage shows this month's time on, its cost and a bar per day, including the time it has been on now.
- **History:** `audit_log` rows on the computer, read as sentences ("Reset the system · you · 2 min ago"). Recorded: woke up, went to sleep (by a person, or idle), restarted (by a person or a bot), reset, erased, restore point saved or restored, space freed, program stopped, settings changed.
- **Also:** "Used by" lists the bots that use the computer (the same choice as `ComputerService.forBot`). "Download all files" zips ~/workspace, up to 1 GB (413 above that, 422 when it's empty). Settings > Computers gets Manage, Restart and Reset… in each computer's menu, and `/computer?c=<id>&tab=manage` opens a computer straight on Manage. In a chat, a computer that broke (state `error`) shows Restart and More fixes, and that notice is no longer folded into the tool steps. Bots get `computer.restart` for a stuck computer; it's refused on personal computers and recorded in History as the bot.
- **Personal computers** (D-218) get none of this: they're managed on the device.
- **Tests:** `apps/server/test/computer-manage.test.ts` (parsers, never waking, stop, free up, zip, reset and erase in the background, permissions, sleep timer, usage, bots), `client/test/computer_manage_test.dart`, `client/test/computer_tabs_test.dart`. The shell scripts were also run against `casama/computer-headless:dev` with a read-only root and a home volume, like real computers: vitals, storage, list and stop, free up, zip, reset and erase.

## D-241 Starter bots, routine ideas, plugins and skills come from the gallery; remote app settings

- **Decision** (Oliver asked, 2026-11-12): after apps (D-239), the other built-in lists that people would contribute to move into the open gallery, and the owner gets settings that change every installed app without a release.
- **Starter bots:** `bots/<id>/bot.json` is a `BotTemplate` without id and name. They join `GET /v1/templates` after the built-in ones with an `author`, and creating a bot with their `template_id` applies the persona, skills and routines (`findTemplate`). A gallery bot starts at `ask_always` or `ask_risky`, never autonomous, and uses only the mascots the app ships. Built-in bots stay in `templates.ts` and keep their ids. The `create_bot` agent tool still offers built-in templates only.
- **Routine ideas:** `routines/<id>/routine.json` (description, category, icon, instructions, cron). `GET /v1/routine-ideas`; the new-routine sheet shows them as **Ideas** that fill in the name, instructions and schedule.
- **Plugins:** `plugins/<id>/plugin.json` names a GitHub folder and the exact commit someone reviewed. `GET /v1/plugin-directory`; **Add a plugin** lists **Reviewed plugins**, and picking one previews and installs that commit (`commit` on `POST /v1/plugins/preview`), never a later one. A newer version is a pull request changing `commit`. Seed: the repo's own `examples/hello-plugin` at `6efc1825`.
- **Skills:** the 32 bundled skills that weren't in the gallery are copied there with their authors and licenses (Anthropic, Jesse Vincent, GitHub and Matt Pocock for the adapted ones, D-104). The skill catalog now prefers the gallery's copy, so an improved skill reaches every server on merge; the bundled `skills/` stays for offline, self-hosters with the gallery off, and anything the gallery lacks. Installing a gallery copy checks it against the index hash and records source `catalog` with `sha256`, so installed state in the app is unchanged.
- **Own files again:** `bots.json`, `routines.json` and `plugins.json`, never `index.json` (see D-239). Skills stay in `index.json`, a type every app knows.
- **Remote app settings:** per server, not in the gallery, because self-hosted servers read the same gallery but their owners decide their own versions and notices. `instance_settings` key `app_config`: `min_versions` and `update_urls` per platform, `maintenance`, up to 10 `announcements`, and `flags`. Admin → App settings edits them as JSON (the server's errors say what's wrong); `GET /v1/app-config` needs no sign-in. The app (`RemoteConfigGate` over everything) refreshes every 30 minutes and on resume, keeps the last copy so a minimum version holds offline, and shows an update page, a maintenance page or a dismissible banner. `remoteFlag(ref, name)` reads a switch; nothing uses one yet.
- **Icons:** names from the gallery map through a fixed list of 174 common Lucide icons (`lucideByName`), not all of them, so the icon font still tree-shakes; anything else falls back. The gallery website loads the full Lucide set only when an item names an icon it doesn't embed.
- **Not done:** the app shows a gallery bot's author only where the server sends it; the persona picker doesn't print "By …" yet.
- **Tests:** `packages/domain/test/gallery-content.test.ts`, the new cases in `apps/server/test/gallery.test.ts`, `client/test/gallery_content_test.dart`.

## D-242 Bots that change their own setup

- **Decision** (Oliver asked, 2026-11-13: "can bots install custom MCP on their own? If not let them", then "build all" of the proposed list): bots get tools for their connections, the person's theme, their own action rules, their knowledge and their notifications. The rule for every tool: anything that widens what a bot can reach always asks the person, whatever its autonomy, grants or action rules; anything that only narrows it applies at once.
- **Connections:** `mcp.add` adds a remote server (https only, through the worker's safe fetch, so no private addresses) or a stdio server run by command on the bot's own computer, and attaches it to the bot. It always asks (`alwaysAsk`). The integration is named `<name>_<6 hex of the bot id>`, like plugin servers, and its config records `added_by_bot`. A key is given as `{{secret:NAME}}`, filled in only when the secret is allowed for the server's host, then copied into Vault for the connection. `connections.attach` attaches one of the workspace's connections (never a plugin's, and a local MCP server only for its owner); always asks. `mcp.remove` deletes a server the bot added, or detaches anything else; never asks.
- **Plugin-less computer servers:** `computer_mcp` rows no longer need a plugin. `computerPluginServers` left-joins `plugins`; a server without one runs in `~/.casama/mcp/<name>` (created on sync), which is also its data folder.
- **Plugins and the look are cards, not changes.** `plugins.suggest` shows a card whose button routes to `/bots/:id/plugins?install=<url>`, which opens the install sheet and previews it, so the person sees what the plugin adds and enters its keys. `appearance.suggest` shows a card with an `app:appearance` action: the app applies the preset, mode, scheme, fonts and fewer-effects that it knows (others are dropped) on that device only, with Undo. The look stays on the device because that's where it lives (SharedPreferences); syncing it across devices is a separate decision.
- **Rules:** `rules.add|remove` change only the bot's own rules (`bot_id` = itself). `ToolDefinition.alwaysAskFor` (new) asks for some arguments only: adding allow or allow_within_limits, and removing ask or hand_off. A bot can't add an allow rule for the pay or sign_in categories at all. `rules.remove` takes the rule's kind so the approval card says what's being removed; a mismatch is refused.
- **Knowledge:** `knowledge.add` adds a website or GitHub source to the bot (never the workspace's); `knowledge.remove` removes only its own.
- **Notifications:** `notifications.quiet` sets `user_bot_settings` for the person the run acts for: always quiet or custom hours apply at once; back to their usual hours asks.
- **About you** needed nothing new: `memory.write` already saves facts about the person (D-169).
- **Out of reach on purpose:** billing and plans, payment setup, members and roles, encryption and data keys, privacy deletion, bot sharing, secret values, and the bot's own autonomy or budget.
- **Not covered:** a stdio server takes plain env values, not secrets (use a plugin for one that needs a key). A key copied into a connection doesn't follow later changes to the secret. New tools arrive from the bot's next message, not mid-run.
- **Tests:** `apps/server/test/bot-settings.test.ts`, `client/test/suggested_look_test.dart`, the suggested-plugin case in `client/test/plugins_test.dart`.

## D-243 Phone sign-ins open in the system sign-in sheet and come back on their own

- **Decision** (Oliver asked, 2026-11-13: "don't we have composio sign in callbacks so after we sign in via browser we get back to the app?", then "go and build it"): connecting an app on iOS and Android opens the system's sign-in sheet instead of the browser app: `ASWebAuthenticationSession` on iOS (`SignInSheet` in `AppDelegate.swift`), a Custom Tab on Android (`SignInSheet` and `SignInCallbackActivity` in `MainActivity.kt`), over the `casama/sign_in_sheet` channel (`client/lib/core/sign_in_sheet.dart`). The sheet shares the browser's sign-ins, Google accepts it (embedded WebViews get `disallowed_useragent`, and the app has none), and it closes itself when the sign-in ends, so nobody has to switch back to Casama.
- **Own code, not `flutter_web_auth_2`:** that package brings `desktop_webview_window` to Windows and Linux, an embedded WebView that also needs webkit2gtk to build on Linux.
- **How it ends:** the connect requests take `return_to_app` (`ConnectAppRequest`, `ProviderConnectRequest`). For Composio and Pipedream the return address becomes `/oauth/done?app=1&integration=<id>` ("app=1" first, because providers append their own "?status=…"); for direct OAuth the flow row's `oauth` records it. Then `/oauth/done` and `/oauth/callback` finish the connection as before and answer with a 302 to `casama-auth://done?status=ok|error`, a fixed address, so it can't be used as an open redirect. Without the flag (web, desktop) the "You're signed in" page stays.
- **Own scheme:** `casama-auth`, caught on Android by `SignInCallbackActivity`, so it never competes with the `casama://` deep links `MainActivity` handles. iOS needs no URL type for it. The Android tab opens with no history, so it closes once the callback activity shows; coming back to the app without the callback reads as "closed".
- **Still checking:** the app checks once when the sheet closes and keeps its polling and resume checks, and the server still finishes Composio and Pipedream sign-ins itself (495d20ff), for when the person closes the sheet early or Android stops the app.
- **Where it doesn't apply:** macOS, Windows, Linux and web keep opening the browser. If the sheet can't open on a phone, the sign-in falls back to the browser; it still connects, but on iOS the browser then ends on an address it can't open.
- **Not changed:** the Supabase account sign-in (its iOS in-app view works around the blank Safari sheet) and the AI-app consent screen, which hands off to the other app's own address.
- **Tests:** the sign-in sheet cases in `apps/server/test/apps.test.ts` and `apps/server/test/google-permissions.test.ts`, `client/test/sign_in_sheet_test.dart`. The native halves need a device check.

## D-244 Casama Cloud pricing: Free, Plus, Pro and Max, editable live

- **Decision** (Oliver, 2026-11-13: plan lineup, store pack prices, live editor, and the go-ahead to roll it out): four plans, yearly at ten months' price.

  | Plan | Monthly | Yearly | Credits / month | Bots | Computers | Computer hours | Seats | Casama key per day |
  |---|---|---|---|---|---|---|---|---|
  | Free | $0 | | $1 | 2 | 1 | 5 | 1 | $0.25 |
  | Plus | $15 | $150 | $5 | 5 | 2 | 30 | 2 | $5 |
  | Pro | $39 | $390 | $10 | 20 | 5 | 100 | 5 | $10 |
  | Max | $149 | $1,490 | $50 | 50 | 10 | 400 | 10 | $25 |

  Credit packs: $10 and $25 of credits, at face value on the web (Dodo) and $12.99 / $29.99 in the App Store and Google Play, because the stores keep 15–30% and a $10 store pack at face value lost money on Play. Product ids: `ai.casama.{plus,pro,max}.{monthly,yearly}` and `ai.casama.credits.{10,25}` (App Store), `casama_{plus,pro,max}` with base plans `monthly` / `yearly` and `casama_credits_{10,25}` (Play). Margins at full use are in docs/COSTS.md; the most a subscriber can cost is bounded because every cost is metered with the markup or capped.
- **Live editing:** `GET /v1/admin/pricing`, `PUT /v1/admin/plans/{code}`, `PUT /v1/admin/credit-packs/{code}` and `PATCH /v1/admin/billing-settings` (instance owner), with a Pricing section in the Admin screen. Saving a plan's limits rewrites the entitlement of every workspace on it in the same transaction, keeping owner overrides on top, so a change reaches people without a deploy or a billing event (before, a plan row change waited for the workspace's next subscription event). The free and self-hosted plans can't be switched off or changed respectively.
- **Markup:** moved from a constant to `billing_settings.markup` (default 1.3). Each process loads it at start and every minute (`BillingService.loadSettings`, also run by the worker's settle step); the API process applies a change at once. It covers OpenRouter on Casama's key (× 1.055 fee × markup), dictation on the shared key, live calls and phone-call voice on the server's Google key (Google's price × markup; these were at cost before), and app calls.
- **Daily cap on Casama's key:** now the plan's `cloud_daily_usd` limit; the old $0.25 / $10 split stays as the fallback for a plan without it.
- **Seats enforced:** a `memberships` trigger (`enforce_seats`, SQLSTATE PT402, so PostgREST answers 402 and the app shows the paywall) counts members against the plan's `seats` for every way someone joins: invites, links, join requests. Free has one seat, the owner. Before this, seats were advertised on the paywall but never checked.
- **Metering what wasn't:** calls through the server's Composio account record `app_calls` at $0.002 each (Composio Pro's price for Gmail, Slack, Calendar) times the markup, billable with billing on. The voice model inside a phone call is billable on the server's key and a call doesn't start without credits. Twilio minutes, numbers and SMS are on the workspace's own Twilio account (`org_telephony`, D-141), so Casama never pays them; docs/COSTS.md said otherwise and is corrected.
- **Store credit packs:** `POST /v1/orgs/{id}/billing/purchases` accepts a pack's product id. The App Store transaction or Play one-time purchase is verified (Play's is consumed so it can be bought again) and credited once, keyed by `app_store:<transactionId>` / `google_play:<orderId>`; another workspace reporting the same purchase gets 409 `purchase_used`, and a pending Play purchase 409 `purchase_pending`. `CreditPack` gains `price_label` and `store_product_ids` (optional, so older apps still parse it).
- **Not done:** refunds of store credit packs aren't taken back automatically (Dodo pack refunds are); Composio calls inside its free monthly allowance are still charged, on purpose, so the price doesn't jump.
- **Tests:** `apps/server/test/admin-pricing.test.ts`; the plan list, seat limit and store pack cases in `apps/server/test/billing.test.ts`; the marked-up call cost in `apps/server/test/voice-cloud-calls.test.ts`.

## D-245 Usage is shown in dollars, led by a plain credits meter

- **Decision** (Oliver, 2026-11-13): no custom currency. Credits stay dollars (1 credit = $1), because every cost is already metered in USD (OpenRouter's reported cost × fee × markup, computer hours, voice, data calls), the referral copy and spend limits already say dollars, and a made-up unit would read as hiding the price of things bots spend on their own. Charging stays in USD; a local-currency hint can come later.
- **What people see first:** a credits meter (`client/lib/features/billing/credits_meter.dart`) at the top of Usage and on the Billing plan card: the balance ("Credits: $7.80"), a bar of how much of this month's credits is used, and "About N more runs at your usual cost". The bar compares this month's billed spend with spend plus what's left, since monthly credits carry over (`BillingService` grants them on top of the balance). The bar turns amber at 80% and red when nothing is left, with a line saying so. The runs estimate is this month's average cost per run and is hidden under 3 runs. A line under it says "1 credit = $1" and how much the plan adds each month.
- **Exact amounts one level down:** Usage's charts, per-bot and per-model amounts and Billing's charges stay in dollars. Model input and output show as one "AI models" line, without token counts; tokens stay under Advanced and in the CSV/JSON exports. Billing's "Model credits: N tokens" line is gone.
- **Self-hosted:** no meter (billing off, or an unlimited plan).
- **Tests:** `client/test/credits_meter_test.dart`; `client/test/workspace_advanced_test.dart` (Advanced summary).

## D-246 Billing holes closed; credit packs for paid plans; credits that expire

- **Decision** (Oliver, 2026-11-13, from docs/MONETIZATION-AUDIT-2026-11-13.md): close the holes that let usage go unpaid, sell credit packs only to paying plans, and let credits expire.
- **Workspaces:** every server writes whether it bills into `billing_settings.enabled` as it starts (`BillingService.loadSettings`). With billing on, a new organization starts on `free` however it was made (a `before insert` trigger), so calling `create_organization` directly no longer gives the unlimited `selfhost` plan; settlement also moves any `selfhost` workspace to its real plan. One person can own `billing_settings.max_owned_workspaces` (5) workspaces; the next answers 402 `workspace_limit`. Database plan limits (`PT402`, also seats) now reach the app as 402.
- **Free credits:** only a person's oldest free workspace gets Free's monthly credits; the others record a $0 grant. A plan change within a month tops that month's grant up to the new plan's amount instead of granting again (the old key per plan let switching collect every plan's credits).
- **Metered on Casama's keys:** images (server OpenRouter key) and video (server Google key) are billable at cost × markup (× 1.055 on OpenRouter) with `meta.key = "server"`, and are refused when the credits left can't cover the estimate. Read-aloud on the server's Google key is billable with markup and needs credits; dictation on the shared key needs credits, else the app uses the phone's own dictation. `billPlatform` follows `billing.enabled` (it was on for every server).
- **The credit gate:** on a credit-gated plan every run needs credits, whatever key its model is on, because fallbacks, app calls, paid data, media and computers all bill Casama. The daily cap on the server's keys counts all billable spend except computer and live-view time, not only model tokens.
- **Packs:** web checkout of a pack answers 402 `paid_plan_required` on Free, and the app hides packs there; a store pack already paid for is still credited.
- **Expiry:** credits live in `credit_lots`. A month's included credits last until the end of the following month; purchases and rewards 12 months; adjustments never. Spending takes the lot that lapses first; `expire_credits()` (worker settle, every minute) takes lapsed credits off once per lot (`reason = 'expire'`). A top-up after a negative balance only adds the part above zero. Existing balances became one 12-month lot.
- **Not in this change** (still open in the audit): live-call usage reported by the app, cancelled streams, running computers between settlements, refund clawbacks, Cloud Connect markup, downgrades, the referral welcome cap, the host-wide computer cap, paywall store disclosures and plan changes.
- **Tests:** `apps/server/test/billing-holes.test.ts`; `apps/server/test/billing.test.ts` (top-up, packs on Free); `client/test/billing_test.dart`, `client/test/credits_meter_test.dart`.

## D-247 Proactive bots: on from the start, one setup summary, pushes in the bot's words with buttons

- **Decision** (Oliver, 2026-11-13: "build all", after comparing with Hark's proactive notifications): check-ins become how a bot reaches out first. Pricing stays per workspace, not per bot (a bot costs nothing idle; scans cost model credits), so plans limit how many bots check in instead of how many exist.
- **On from the start:** the welcome bot gets check-ins turned on when it's made (`enableDefaultCheckins`: brief 08:00, scans every 3 hours or the plan's floor, daily cap $1 or the plan's `cloud_daily_usd` if lower). Other bots stay off until someone turns them on. Bots that already had check-in settings are left alone.
- **Plan limits** (new `plans.limits` keys, added with `jsonb ||` and copied onto current entitlements): `max_proactive_bots` Free 1, Plus 2, Pro 5, Max 20; `min_scan_hours` Free 12, Plus 3, Pro and Max 1; `event_scans` 0 on Free, 1 on paid plans. Turning check-ins on past the limit, or with scans more often than the floor, answers 402 `plan_limit` (the app shows the paywall). After a downgrade the worker skips briefs and scans of bots past the limit (the oldest bots keep theirs) and scheduled scans more often than the floor. Self-hosted plans have none of these keys, so no limits.
- **Scans off schedule:** `request_checkin_scan(bot, reason, delay)` sets `bot_checkins.scan_requested_at` / `scan_reason` and pulls the scan routine's next run in. Reasons: `setup` (once per bot, when the welcome chat's first value is done or the setup interview ends), `connection` (a database trigger when an integration turns ok, or a managed Composio connection gains an app; 3 minutes later so several connections share one scan) and `event` (below; at most every 30 minutes, needs `event_scans`). The scan run records its reason in `runs.budget.scan_reason`, and its task says why it runs now.
- **The setup summary:** the setup scan adds up to 5 suggestions without pushing each, then replies with one sentence ("You're all set. Found 3 things to start on, like booking a ride to the concert tomorrow night."). `afterCheckinRun` sends that as one push titled with the bot's name, or "You're all set. I'll keep an eye on things…" when it found nothing, and sets `welcomed_at`.
- **Pushes in the bot's words:** `suggestions.add` takes `push_text` (first person, like a text, ending in a question when offering to do something). A suggestion's push is titled with the bot's name and shows `push_text` (else the title). The scan instructions now ask to think ahead over the next couple of days, group related items (a trip, an event) into one suggestion, and offer to pull a multi-part plan into a shareable Page. Scan routines made with the old instructions use the new ones.
- **Timed suggestions:** `suggestions.add` takes `notify_at`; the push waits until then (`sendDueSuggestions`, every minute) and the suggestion lives at least 6 hours past it. `suggestions.notified_at` records the push.
- **Buttons:** suggestion pushes carry `suggestion_id`, `bot_id` and the iOS category `SUGGESTION` (Do it with `.foreground`, Not now), registered in `AppDelegate.swift`; Do it arrives as `onMessageOpenedApp` with `actionIdentifier = accept`. Android apps that set `devices.data_pushes` (this version and later) get suggestions as data-only FCM messages and draw them natively (`SuggestionPush.kt`: a receiver on the FCM broadcast, like the firebase_messaging plugin's own, plus a trampoline-free activity). Older Android apps keep plain notifications. Do it opens `/suggestions/{id}/accept?bot=…`, which accepts and opens the chat (or the inbox if it was already handled). No new Flutter packages.
- **App events (Composio triggers):** with `COMPOSIO_WEBHOOK_SECRET` set, the worker subscribes `GMAIL_NEW_GMAIL_MESSAGE`, Google Calendar event created/updated and `OUTLOOK_MESSAGE_TRIGGER` for managed Composio connections in workspaces with check-ins, every 10 minutes (ids in `integrations.config.triggers`, failures retried after a day). `POST /hooks/composio` checks Composio's signature (HMAC-SHA256 of `id.timestamp.body` keyed with the secret's raw bytes, base64, `v1,` prefix, 5-minute window), matches the workspace by trigger id or Composio user id, and asks those bots for an `event` scan. The event's contents never reach a model; the scan reads the app through its tools. Subscriptions aren't removed when check-ins are turned off (their events are ignored).
- **Phone calendar:** a new event in the next 7 days on the calendar a phone shares (device data, D-149) asks for an `event` scan, under the same rules.
- **Cost:** scans run on the bot's cheap model and are billed as usage under the credit gate and the bot's check-in cap; nothing new is paid for. To spend less where scans rarely help:
  - scheduled scans skip quiet hours (the brief carries the night), and app-event scans wait for them to end; setup and connection scans always run;
  - where Composio events cover email and calendar, scheduled scans are a 6-hour backstop;
  - a person idle 7 days gets at most one scan a day; idle 30 days, no briefs or scans until they're back (`public.user_last_active`: latest session refresh, device check-in or notification read);
  - Composio triggers are removed once nobody in the workspace checks in.
  - briefs and scans use low reasoning effort. A live check on Casama Cloud's model (`meta/muse-ember`, a realistic weekend: concert, hotel, flight, an urgent invoice) found that at the default effort the reasoning used up the 4,096 output tokens before the setup scan's first suggestion. At low effort it found the urgent invoice, grouped the weekend into one Page offer and wrote the summary line, at about $0.0013 a setup scan, $0.0008 a busy scan and $0.0002 a quiet one, before markup.
  On Free (12-hour floor, one bot, no event scans) that's at most a brief plus two scans a day: about $0.05 a month of model cost.
- **Costs, round 2** (2026-11-13, from the first prod scans: 7 event scans in 3 hours, 3 out of time and 3 stuck waiting for approval, none with a suggestion, $0.006–0.029 each):
  - Composio reads are low risk (`composioToolRisk`: the tool's `readOnlyHint`/`destructiveHint` tags, else read words in the slug with no change words), so reading the person's own mail and calendar no longer asks after the first untrusted result. That applies to chats too; writes still ask as before.
  - Check-in runs never wait for an approval: a call that would need one is refused with "offer it with suggestions.add instead".
  - Check-in runs offer only `suggestions.add`, `memory.search`, `tasks.list`, `device.read`, `projects.status` and low-risk app reads (for Gmail and Google Calendar, a short list of fetch and list tools). Nothing that needs the computer, no lazy loading, at most 8 steps, and app results cut at 8,000 characters. The instructions ask for about 10 recent emails without bodies and two days of calendar.
  - App events only scan when worth it (`composioEventNote`): mail from a person (not promotions, social, updates, forums, Outlook "other" or no-reply/notification/newsletter senders) and calendar changes from an hour ago to 48 hours ahead. Unknown events still scan. Event scans are at least 2 hours apart and at most 6 a day per bot (plan key `event_scans_day` can change it). The phone calendar window is 48 hours too.
  - The scan gets what changed (`bot_checkins.scan_note`: sender and subject, event title and time, wrapped as untrusted) so it starts there. This replaces "the event's contents never reach a model" above; it's a line of the event, not the message.
  - Tests: `packages/agent/test/checkin-costs.test.ts`, plus the event filter, daily cap and notes in `proactive.test.ts`.
- **For you:** suggestion cards show the bot's own line (`Suggestion.push_text`, optional in the API).
- **Analytics:** `proactive_message_sent` (kind suggestion, timed or summary; reason), `suggestion_resolved` (accepted, dismissed, dismissed_forever; age in hours), `proactive_muted` (Less like this); `push_opened` has kind `suggestion`.
- **Live:** deployed 2026-11-13 (server 522448435b01, migration 20270130000001). The Composio webhook subscription `ws_-eL6Jba8gJRP` posts to `https://api.casama.ai/hooks/composio`; `COMPOSIO_WEBHOOK_SECRET` is in prod `.env` and Vaultwarden.
- **Tests:** `apps/server/test/proactive.test.ts` (plan limits, downgrade skip, setup summary, connection trigger, signed Composio events and the 30-minute gap, push wording, buttons, data-only Android pushes, timed suggestions, phone calendar, quiet hours and idle throttles, trigger removal, welcome default); `client/test/suggestion_push_test.dart`.

## D-248 One subscription per workspace, purchase terms, out-of-credits packs, money leaks closed

- **Decision** (Oliver, 2026-11-13, from docs/MONETIZATION-AUDIT-2026-11-13.md: "do all of them").
- **One subscription per workspace:**
  - A web subscriber who picks another plan is moved in place: Dodo `POST /subscriptions/{id}/change-plan` (prorated, the change waits for payment). Extra people on the old plan move with it when the new plan sells them (D-249). Checkout answers `{url, changed: true}`; `url` is the return page, so older apps still land somewhere.
  - The plan the workspace already has answers 409 `already_subscribed`. A store subscriber asking for web checkout gets 409 `subscribed_in_store`.
  - In the app, Google Play replaces the owned subscription with `ChangeSubscriptionParam` (time proration). iOS needs nothing, since every plan is in one subscription group. The paywall and Billing don't offer a second channel: store subscribers are told to change plans in that store, and web subscribers only see web checkout.
- **Purchase terms (App Store 3.1.2):** under every way to subscribe, the price and period, that it renews until cancelled, which account is charged and how to cancel, plus Privacy Policy, and on Apple platforms Apple's standard Terms of Use (EULA) until Casama has its own. Billing's store buttons name the period ("Subscribe for $9.99 per month").
- **Paywall:**
  - The headline and the welcome name the chosen plan.
  - "N months free" is worked out from the prices shown (store prices differ by country) and hidden under a month.
  - In a store with no web checkout, tiers and periods the store doesn't sell are hidden, so no button does nothing; failed product loads retry.
  - A paying workspace's own tier in the other period, or a smaller tier, says "Switch to …".
  - Restore Purchases is for everyone.
- **Out of credits:** a paying workspace gets a sheet of credit packs, with See Plans under it; a free one gets the paywall with "You're out of credits" on top. `runGuarded` sends every 402 `out_of_credits` there. Other plan limits in a chat (`plan_limit`, hours, daily cap) open the paywall.
- **Purchase feedback:** store purchases are verified from launch, not only once Billing or the paywall opens. Pending, failed, unverified and restored purchases each show a message. Cancelled and failed store transactions are finished so they don't stay in the queue. `purchase_completed` carries `kind` and, for failures, `reason` (`store_error`, `verification_failed`).
- **Leaks closed:**
  - **Live calls:** a billable call starts with a hold of 2 minutes at the per-minute estimate. The saved call is charged the higher of what the app reports and its time on the clock at Gemini's listening rate ($0.0045 a minute), and replaces the hold, which can mean money back. A call that never reports keeps its hold. Starting a call checks credits less unsettled usage; settlement applies negative totals as refunds.
  - **Cancelled and broken model streams:** usage is recorded from an estimate (about 4 characters a token) when the model had produced anything.
  - **Running computers:** billed every 5 minutes while they run (`meterRunning`), and put to sleep when their credit-gated workspace has nothing left.
  - **Refunds:** a refunded store pack (App Store consumable refund, Play voided one-time purchase) takes its credits back once. A refunded subscription takes back the credits its plan added that month.
  - **Cloud Connect:** model calls cost what Casama's own key charges (OpenRouter's fee × markup) unless `CLOUD_MODEL_MARKUP` is set. Calls need credits less unsettled usage and a call's reserve, stop at the plan's daily cap (402 `cloud_daily_cap`), and a stream cut short is metered from an estimate.
  - **Downgrades:** the workspace keeps everything, but only the plan's number of bots and hosted computers, oldest first, run or start (`plan_limit`). Starting a computer that's out of credits now answers 402, not 500.
  - **Server capacity:** `COMPUTER_HOST_CAPACITY` (0 = off) caps hosted computers running at once on the server; past it a start answers 503 `capacity_full`. (Superseded by D-252: the room is counted in memory, `COMPUTER_HOST_MEMORY_GB`.)
  - **Referrals:** one inviter's friends earn the welcome bonus at most twice the reward cap (40 with the defaults).
- **Not done:** Casama's own Terms of Use page (Oliver to decide; Apple's EULA stands in); the plan-change UI for a store subscriber who should move to the web.
- **Tests:** `client/test/billing_test.dart` (the D-248 group), `apps/server/test/billing.test.ts` (plan change in place, refunds), `apps/server/test/voice-cloud-calls.test.ts` (hold and clock), `apps/server/test/billing-holes.test.ts` (welcome cap), `apps/server/test/cloud-connect.test.ts`, `packages/agent/test/computers-limits.test.ts`.

## D-249 Pricing that fits every store; computers limited by how many run; extra people; a Pro trial

Revises D-244 after comparing Rakazo, MausBot, OpenBot, Claude Duet, Grok Bot and ChatGPT Dots.

- **Prices:** Free $0, Plus $15 ($150/yr), Pro $49 ($490/yr), Max $99 ($899/yr). Every price is at
  most $899, so one list works on the web, the App Store (above about $899 needs Apple's approval)
  and Google Play (capped at $999.99 without $1M in Play earnings).
- **Credits and hours:** $1 / $5 / $15 / $30 a month; 5 / 30 / 100 / 300 computer hours.
- **Computers:** hours cost little; what runs out is the server, so plans limit hosted computers
  running at once (`max_running_computers` 1 / 1 / 2 / 2; Max goes back to 3 on a bigger server, since three 4 GB computers don't fit in the ~9 GB the current one has for computers). Starting another puts the one nobody has
  used for 2 minutes to sleep; if all are in use the start is refused (402 `plan_limit`, or the
  `running_limit` tool error for a bot). `computer_size` (1 / 1 / 2 / 4) sets vCPUs and GB of memory
  at each start and is saved on the computer, so usage is billed at that size.
- **Bots:** 3 / 10 / unlimited / unlimited. A bot costs nothing until it uses credits or a computer,
  which are limited already. No `max_bots` key means no limit.
- **People:** seats 1 / 1 / 3 / 10. Pro and Max sell extra people at $12 a month ($120 a year) as a
  Dodo add-on on the web subscription (`PUT /v1/orgs/{id}/billing/seats`, prorated now). Store
  subscriptions can't carry a quantity, so they upgrade instead. Lowering below the people already
  in the workspace is refused (`seats_in_use`). `subscriptions.extra_seats` holds the count.
- **Trial:** Pro has 7 days free, once per person across all their workspaces and never after any
  subscription (`trial_available` in the billing summary). Web checkouts pass the trial to Dodo; the
  App Store and Google Play run their own introductory offer. While trialing the workspace gets $2
  of credits and 10 computer hours; the first payment tops the month up to the plan's $15.
- **One formula for limits:** `public.entitlement_limits(plan, subscription, overrides)` adds extra
  people and trial allowances to the plan's limits, with owner overrides on top. The server's
  recompute and the Admin screen's saves both use it.
- **Why not $1,490 for Max yearly:** Apple would need a request and Play can't sell it, and $99 for
  the top plan matches what Rakazo and MausBot charge.

## D-250 Timezones follow the person

- **Decision** (Oliver, 2026-11-13): found while turning on check-ins for existing people. The apps never saved a timezone, so every profile kept the `UTC` default and briefs, quiet hours and routines ran on UTC (an "08:00" brief came at 4 pm in Manila).
- **Apps:** save the device's IANA timezone (`flutter_timezone`, every platform) to `profiles.timezone` after sign-in and whenever the app comes back to the front, only when it differs (`client/lib/core/timezone_sync.dart`, kept alive by the push provider). Abbreviations like "PST" are never sent.
- **Server:** a trigger on `profiles.timezone` (`follow_profile_timezone`) refuses unknown names and moves the person's routines: the brief and scan of bots that check in for them, and their own scheduled routines that were on their previous timezone (a zone chosen on purpose stays). It marks them `retime_pending`; the worker recomputes `next_run_at` in the new zone within a minute (`retimeRoutines`).
- **Existing accounts:** Oliver's two accounts were set to `Asia/Manila` by hand; everyone else gets theirs the next time they open the app.
- **Tests:** the timezone case in `apps/server/test/proactive.test.ts`; `client/test/timezone_sync_test.dart`.

## D-251 Bot computers' CLIs stay current through their images

- **Decision** (Oliver asked, 2026-11-13: "how do we keep those CLIs updated for every bot's computer?", then "do all of those now"): agent-browser, Playwright and agent-desktop stay pinned in the computer images, and updates arrive as reviewed image changes, never by upgrading tools inside running computers (bots can't anyway: `/usr/local` is root's).
- **How a computer gets them:** sleeping archives the home folder and deletes the container (D-178); waking creates a fresh container from the image and restores the home folder. So a new image reaches every computer on its next wake-up or restart, with its files, logins and settings kept. No extra cost: images are public on ghcr (free), and a version bump changes only the top layers.
- **`scripts/computer-tools.sh`:** `check` compares the pins with npm. `bump` raises them in a separate checkout of `origin/main` (never the shared tree), builds both images for the local machine and checks each CLI starts (`agent-browser --version`, `playwright --version`, `chrome --version`, `agent-desktop version`), then opens a pull request with the steps after merging. It skips when everything is current or a `computer-tools/` pull request is already open. `prod-pull --yes` pulls both images on the VPS and prunes old layers; it changes production, so it runs only with Oliver's yes.
- **Weekly:** `~/Library/LaunchAgents/ai.casama.computer-tools.plist` (Oliver's Mac) runs `bump` on Mondays at 10:00 and logs to `~/Library/Logs/casama-computer-tools.log`. If Docker isn't running, `bump` stops without opening a pull request.
- **Warm pool:** `fillPool` (every minute) also replaces pool members whose image differs from what the headless tag now names, and `claim` never hands one out, so the first computer after an update is current too. When either image id can't be read, members are kept rather than churned.
- **Not covered:** a computer that never idles for 5 minutes keeps its image until it restarts. The supervisor still doesn't pull images itself; `prod-pull` is the step.
- **Tests:** `packages/sandbox/test/warm-pool-refresh.test.ts`.

## D-252 Server capacity: counted in memory, watched every 5 minutes, checked from outside

- **Room in GB, not computers:** computers come in plan sizes of 1, 2 and 4 GB (D-249), so a count
  doesn't say whether the next one fits. `COMPUTER_HOST_MEMORY_GB` (0 = no limit) is the memory
  hosted computers may use; a start whose plan size would go past it answers `capacity_full` and is
  recorded in `capacity_events`. Replaces D-248's `COMPUTER_HOST_CAPACITY`. Production has about
  9.7 GB free for computers on the 12 GB server, so it runs with 9, and Max runs 2 computers at once
  (two 4 GB fit, three don't) until the bigger server.
- **Samples:** the worker records host memory, load, root-disk use, and hosted computers up with
  their memory, every 5 minutes in `capacity_samples` (kept 90 days).
- **Alerts** to the instance owners (INSTANCE_ADMIN_EMAILS, else the first account) as an inbox
  item with a push and an email, each kind at most once a day (`capacity_alerts`):
  early warning when the daily peak of computer memory is over 60% of the budget on 3 of the last
  7 days (order the bigger server); act now on any `capacity_full`; health when free host memory is
  under 1.5 GB for 10 minutes or the disk is over 80%.
- **Admin screen:** "Server capacity" card (`GET /v1/admin/capacity`): computers' memory against the
  budget, free memory, disk and load, the 30-day daily peak with the budget line, refusals, recent
  alerts, and "full in about N weeks" from a least-squares line through the daily peaks.
- **Outside check:** the `casama-uptime` Cloudflare Worker (infra/uptime) fetches the API's
  `/readyz` and the web app every 5 minutes and emails the owner after two failures in a row (again
  hourly while down) and when it's back, through the same SMTP mailbox as the server. It runs on
  Cloudflare, so it works when the server doesn't; no new account was needed.


## D-253 One main conversation per bot, work in topics; chat history on a fixed budget

- **Decision** (Oliver, 2026-11-13, after comparing with Grok's single thread: "push then start building"):
  a bot opens straight into its **General** conversation, one per person per bot, where quick
  questions, briefs, routine results and proactive messages land. Work runs in **topics**
  (conversations linked to the message that started them), opened by an accepted suggestion, a
  project, a routine run or a long task, or by hand; each posts a one-line result back to General.
  Active topics show as chips at the top of General (needs-you first), topics idle 7 days move to
  Older, and the Inbox tab gives way to Chats with a Needs you filter and a pinned Casama
  conversation for workspace notices. A person's latest direct chat with a bot becomes General;
  the rest become topics. Group chats are unchanged.
- **Order:** (1) history budget; (2) General and topics on the server; (3) automatic topics with
  results posted back; (4) the app. All four are built.
- **General (server):** `conversations.is_main`, one per person and bot (unique index). A trigger
  makes a person's first app chat with a bot General and every later one a topic under it
  (`parent_conversation_id`); chat-app threads, projects and group chats stay out. The migration
  made each person's latest chat General and the rest its topics. Deleting General promotes the
  latest remaining chat. `public.main_conversation(org, bot, user)` gets or makes it for the worker.
  `GET /v1/bots/{id}/conversations` lists your General first and adds `is_main`,
  `parent_conversation_id`, `anchor_message_id` and `status` (`needs_you` when a run waits for an
  approval or a take-over, `working` while one is going).
- **What lands in General:**
  - Briefs, always. Other routines post where they were asked for (D-155); with no chat recorded,
    in General.
  - The setup scan's "You're all set" line.
  - Suggestions, as the bot's line plus a `suggestion` part. The app draws it as a card with Do it
    and Not now. `suggestions.message_id` records the post.
  - Suggestion and summary pushes open `/bots/{id}/chat` (General) instead of the inbox.
- **Never mid-run:** a run's reply is attached to the message it answers, so a post landing in
  between would push the reply onto a hidden branch. So nothing is posted into General while a run
  works there:
  - a run's own suggestions are posted right after it ends;
  - anything that had to wait goes out in the worker's minute sweep (`postSuggestions`,
    `postTopicResults`).
  - Posts without a run broadcast `conversation_activity`, so open apps reload (D-224).
- **Topics:** Do it opens a topic with the suggestion's card as its anchor and `posts_result`. It
  posts a one-line result back to General (the first sentence of the reply, markdown stripped, with
  a `topic` part linking to it) after the run that did the work, and after later runs nobody asked
  for there (a routine, a watcher). `result_run_id` keeps it to once per run. The person's own
  back-and-forth in a topic stays in the topic. A topic made by hand ("New topic") doesn't post back.
- **Personal chats only (audit, migration 20270131000602):** the first version treated every
  direct chat with a person behind it as theirs. But chat apps link threads in `channel_threads`
  and never set `conversations.channel_id`, so a WhatsApp thread, a ticket chat, a watcher or a
  linked-bot, A2A, replay or teach chat could become General. `conversations.personal` now marks a
  person's own chats; it's set by:
  - the app's chat;
  - the welcome chat;
  - bot setup;
  - accepted suggestions;
  - calls;
  - `main_conversation`.

  The migration worked `personal` out from `channel_threads`, `watchers`, `tasks` and those chats'
  title prefixes, then reassigned General. Other chats stay listed for the person, under Older in
  All topics, but never as chips.
- **Cards once:** suggestions pending before General existed keep `post_card = false` and stay in
  Needs you, so the first sweep doesn't flood General. A card deleted with its chat isn't posted
  again (a trigger clears `post_card` when `message_id` is cleared). The minute sweep reads two
  partial indexes. A manager sees someone else's General as an ordinary chat. The suggestion card
  only calls a suggestion closed when For You's list (at most 30) isn't full.
- **Not done:** the bot opening a topic by itself for a long task. Projects already have their own
  chats, and routines post in General. Revisit if General gets noisy.
- **App:**
  - **Tabs:** Chats and Tasks; the Inbox tab is gone. Chats starts with a Needs you card (when
    something waits) and a pinned Casama row (updates and notices). Both open the old Inbox screen
    full screen (`/inbox?tab=0` and `/inbox`). Desktop has the same two rows over the bots in the
    sidebar. The Chats tab carries the badge the Inbox had.
  - **Opening a bot** opens General. Chips at the top show the live topics: needs you first, then
    working, then the newest; ones idle 7 days are left out. All topics lists General, the live
    ones, then Older. Inside a topic, a General chip leads back.
  - **The header:** "New chat" became New topic, and Conversations became Topics.
- **History budget (built):** chats used to send their whole history until it reached 70% of the
  model's window. Casama Cloud's Muse Ember has a 1M window, so nothing was summarized before about
  730k tokens, and every message resent it all. Now history over `HISTORY_BUDGET` (16k tokens) is
  folded into the conversation's summary until `HISTORY_KEEP` (8k) of the newest turns remain, so
  compaction runs once every couple of dozen turns, not on every turn. Small windows still cap at
  70%. A single long last turn (a pasted document) stays while it fits the budget alone.
- **Fixed with it:** compaction marked everything before the current message as summarized
  (`summary_through`), though only the older turns went into the summary, so the turns a run kept
  vanished from every later run. `summary_through` is now the newest folded message's own
  timestamp, read in SQL by id (JavaScript dates drop the microseconds and would let it back in).
- **Cost** (`docs/COSTS.md`): on Muse Ember a long chat's message drops from up to about $0.07–0.20
  (225k–675k tokens of history, 3 model calls) to about $0.006; short chats are unchanged (prod
  chat runs average 11.4k input tokens a call, $0.004 a run). A summary costs about $0.002 on the
  background model and is also saved as an episode memory, so older details stay findable.
- **Tests:** `packages/agent/test/context.test.ts` (short chat whole on a 1M window, long chat
  capped, compacting down to the keep size, a long last turn kept), `apps/server/test/history-budget.test.ts`
  (seeded 24k-token chat: the cut-off is a seeded turn, the next message still carries the kept
  turns; fails on the old cut-off). The replay gateway gained `when.messagesInclude`.
  `apps/server/test/general-topics.test.ts` covers:
  - General first and topics under it;
  - briefs in General;
  - a suggestion card posted once;
  - Do it opening an anchored topic that posts back once, with follow-ups staying put;
  - no post while General is busy, then the sweep;
  - needs-you status;
  - deleting General.
  `client/test/general_topics_test.dart` covers the chips (needs-you first, Older left out, the way
  back), the suggestion card's Do it and Not now, the topic link, the Needs you and Casama rows, and
  `splitTopics`. The navigation tests now expect two places.

## D-254 Updates instead of the Casama row; quiet hours on by default

- **Decision** (Oliver, 2026-11-13: "do fixes for what makes it weak and worse", after reviewing D-253's Casama row).
- **Problems with the Casama row:**
  - It shared its name and mascot with the welcome bot, so Chats could show two "Casama" rows.
  - It repeated what General already shows (briefs, routine results, suggestions).
  - Its unread count counted those again after you'd read them in the chat.
  - Pages were buried in its feed.
- **Updates:** the row is now **Updates**, with a bell, as a slim row under Needs you (which now
  has an alert icon). Desktop has the same two rows over the bots.
  - It lists notifications that aren't requests and don't open a bot's chat
    (`isUpdateRowNotification`): people joining, missed calls, referrals, server alerts. Its
    chips are **Updates** and **Pages**.
  - Decisions stay in Needs you. Briefs and anything linking into a bot's chat are read there,
    and opening the chat marks them read.
  - The row's count and preview use the same rule, so nothing counts twice. `/inbox` opens
    Updates and `/inbox?tab=0` opens Needs you.
- **Quiet hours on by default:** `profiles.quiet_hours` defaults to 22:00–07:00, enabled, in the
  person's timezone (D-250). Existing profiles without a choice got the same (migration
  20270131000701). Before, nobody had quiet hours until they set them, so scheduled check-in scans
  ran all night and normal-urgency pushes could arrive at 3 a.m.
  - Urgent pushes still come through.
  - The app's fallback for a missing value is "on" too.
  - Test users start with quiet hours off (`createAuthUser`), so push tests pass at any hour.
- **Tests:** `quiet-hours.test.ts` (a new sign-up gets 22:00–07:00 on); `general_topics_test.dart`
  (Updates leaves out what's in a chat, the row's rename); the navigation tests use the new keys.

## D-255 A shorter first message

- **Decision** (Oliver, 2026-11-13, looking at the first user's opening: "too much text and 2
  messages right away").
- **Before:** a 50-word introduction ("I can work on my own computer, use your apps…"), then a
  card with a heading, a paragraph, small print and three buttons (Connect Google Calendar, Gmail
  too, Not now). It read as two messages and two decisions.
- **Now:** one line and one card.
  - **The line:** "Hi Oliver! I'm Casama. Connect your Google Calendar and I'll catch you up on your
    next two weeks." (`GOOGLE_PITCH`). The same line follows "Nice to meet you, …!" when the
    name was asked first, and when the welcome chat is reopened.
  - **The card:** only **Connect Google Calendar** and **Not now**, plus one line of small print
    ("Read only. Google's sign-in screen will show Composio…").
  - **Gmail afterwards:** once Calendar is connected, one follow-up, "Calendar's connected. Want
    me to check your inbox too?", with **Add Gmail** or **Just my calendar**
    (`welcome.calendaronly`, `WelcomeState.gmailAsked`). Then the catch-up runs as before.
  - **Without Google:** the line is "Hi! I'm Casama. Two quick questions so I start in the right
    place." before the focus question.
- **Tests:** `welcome-google.test.ts`:
  - one text part with the offer and a card with two actions and no heading;
  - the Gmail question after Calendar connects;
  - Just my calendar runs the calendar-only catch-up.

## D-256 Chat look: filled bubbles, one-line working status, forms one question at a time

- **Decision** (Oliver, 2026-11-13, with screenshots of another chat app as the target: "same
  rounded" bubbles, its forms and its one-line busy status).
- **Bubbles** (`client/lib/features/chat/widgets/chat_look.dart`):
  - Both sides are filled, with the same radius on every corner (22, no tail), no border or
    shadow, and opaque on any wallpaper.
  - The bot's bubble uses `surfaceContainerHigh`. Yours uses the accent (`primary`) with its own
    text color.
  - Reading aloud still lights the bot's bubble with an accent edge.
- **No name over each turn** in a chat with one bot; the space between turns stays. Group chats
  keep the header, so you can tell bots apart.
- **Working status:** one line with the bot's own icon (rocking while it thinks) and the status
  shimmering, its first word bright and the rest dimmer ("Checking Vaultwarden setup").
- **Cards** (requests, suggestions, bot forms):
  - The bubble's fill, a hairline edge, radius 24.
  - Requests open with a small icon tile and their kind ("Secrets", "Approval", "Take over",
    "Device access", "Suggestion"), then a bold title and grey help text.
  - Fields are filled and rounded with no outline (`chatFieldDecoration`, and the same theme for
    the basic catalog's SDK fields).
  - A secret request's title is the secret's name, with the bot's reason under it. Save stays off
    until there's a value.
- **Bot forms (A2UI):**
  - List questions (a ChoicePicker that isn't chips) show lettered answers (A, B, C…) with the
    label as the question's title.
  - A column with two or more questions (choice lists or text fields) shows them one at a time:
    the question, dots for where you are, **Skip** and **Next**, and whatever followed the last
    question (the submit button) on the last step.
  - This is all on the app side; bots send the same A2UI as before.
- **Tests:** `bot_ui_test.dart` (lettered answers, the second question after Next),
  `secret_request_test.dart` (title, reason, Save waits for a value). Analyze is clean.
- **Follow-up (2026-11-13):**
  - **Hover buttons float:** on a computer, the message hover buttons (Copy, Edit, Read aloud,
    Share) float in a small pill under the message (`OverlayPortal`) instead of keeping 34 px of
    space under every message. Messages sit as close as on a phone, and nothing moves on hover.
  - **Tighter turns:** the gap between turns is 16 with one bot, 24 in group chats.
  - **App logos:** a bot-card button that connects an app (`app:connect` with an `app`) shows the
    app's bundled mark, tinted like its label.
  - **Small print first:** the welcome's Google card puts its small print above the buttons, so
    it's read before tapping.

## D-257 One question at a time: suggestions don't stack, the welcome waits

- **Decision** (Oliver, 2026-11-13, after a new account got about eight prompts in a row: "it goes to
  the next one" before he answered).
- **What happened:** the catch-up's quick tasks, then the setup offer straight away, then the setup
  scan's "You're all set…", then each suggestion as a line plus a card. The suggestions repeated
  emails the catch-up had already shown.
- **No stacking in General:** a suggestion is only posted when General doesn't end in an unanswered
  question (a card, or a suggestion still pending, newer than 24 hours: `openQuestion` in
  `general.ts`). Otherwise it waits under Needs you, and its push still follows the attention rules.
  Answering or dismissing a card, or the bot finishing a turn in General, lets the next one in;
  the minute sweep catches anything else. Posting takes a lock per person and bot and reads the
  batch again under it, so nothing is posted twice.
- **One message per batch, no line above it:**
  - A single suggestion is just its card: the title, then the bot's own line (`push_text`), else the
    start of its body, at most two lines.
  - Several waiting at once (up to 5) are one card: "Found N things worth a look", a row each
    with its own **Do it**, and one **Not now** for the rest. It's a `suggestions` part with `items`.
  - Chat-list previews use the titles.
- **The welcome waits:**
  - When the first value is the Google catch-up, the setup offer ("a few quick questions") comes
    after the person's next finished turn (they used a quick task or replied), not straight after
    the catch-up (`WelcomeState.catchup`, `catchupSeen`).
  - The setup scan waits for the welcome to end: **Later**, or after the interview.
  - Its instructions carry the catch-up's text, so it doesn't suggest the same things again.
  - After a catch-up it sends no "You're all set" summary, push or line, since the catch-up was it.
- **Tests:**
  - `general-topics.test.ts`: a card-only suggestion; an unanswered card holds the next back and
    dismissing it lets it in; three waiting come as one list card.
  - `welcome-google.test.ts`: no setup offer right after the catch-up.
  - `general_topics_test.dart`: the list card's rows and Not now.

## D-258 Default model: DeepSeek V4.1 Flash 1017

- **Decision** (Oliver): the default OpenRouter model moves from Muse Ember (`meta/muse-ember`) to DeepSeek V4.1 Flash 1017 (`deepseek/deepseek-v4.1-flash-1017`). This covers new bots and onboarding (`DEFAULT_MODELS`), background work (`SMALL_MODELS`, D-187), Casama Cloud's built-in chat and background assignment (`CLOUD_MODEL_DEFAULTS`, `CLOUD_LOCKED_MODEL`, D-188), the app's offline fallback, the live evals, and the top of the picker's short list. Muse Ember stays in the list.
- **Price:** OpenRouter list price on 2026-11-13 is $0.038/M input, $0.50/M output and $0.01/M cached reads, against Muse Ember's $0.10/M / $0.50/M. The context window is the same 1M. Calls are billed from OpenRouter's reported `usage.cost`, and the registry entry (with the real cache-read price) is only the fallback. Without that entry, the generic `deepseek` rule would have priced the model at $0 with a 32k window.
- **What's lost:** Muse Ember took images, video, audio and files. DeepSeek V4.1 Flash 1017 takes text and images only.
- **Not changed:** bots that already have a model keep it (never applied over a person's choice). `DEFAULT_MODEL_OPENROUTER` still overrides the default per server. On Cloud, an assignment saved in the admin console (`instance_settings.cloud_models`) overrides the built-in default and has to be changed there.

## D-259 Connect buttons in any chat

- **Problem:** asked "can you get me connected to Google?", a bot said no Google integration was available and that a workspace admin had to enable it. No such step exists; anyone can connect Google. The only `app:connect` buttons were in the welcome chat (D-204). Outside it, `connections.list` said "No connections yet" and `setup.apply` said "you can't add accounts yourself", so the model made up a reason.
- **Decision:** a `connections.offer` tool (`packages/agent/src/tools/settings.ts`). It takes up to four built-in catalog app ids and a one-line reason, and shows a card with one "Connect <app>" button per app (the `app:connect` action, so the D-256 logo shows), plus a borderless "More apps" button that opens Settings → Integrations. Ids not in the catalog are refused with the list of valid ones. Apps the workspace already has are skipped, and the bot is told to use `connections.attach` instead. The description says "Google" usually means Calendar and Gmail, and tells the bot never to claim an app has to be requested or enabled by an admin.
- **Always loaded:** `connections.offer` is a core tool (`lazy-tools.ts`), so bots with many tools don't have to `tools.load` it first.
- **Pointers:** an empty `connections.list` now points to `connections.offer`, and `setup.apply` tells the bot to offer the connections it proposed instead of sending the person to Settings.
- **Composio-connected apps count:** an app connected through the managed Composio route has no row of its own, so the tool asks Composio which accounts are active (`managedComposioActive` in `integrations.ts`) and skips those too. A sign-in that was opened but never finished still gets a button. Before this, a person who had connected Gmail asked "can you read my inbox" and got a Connect Gmail card before the bot read it.
- **Gallery apps:** the tool also accepts the gallery's apps (D-239). The worker passes `galleryApps` (the same cached, checked list the catalog route uses) into `registerSettingsTools`. Built-in ids win, and a gallery app never replaces one. Gallery ids stay out of the tool description so the cached prompt prefix doesn't change when the gallery does; the description tells the bot to try a lowercase, dashed id, and an unknown id returns every built-in and gallery id. If the gallery is off or can't be reached, only built-in apps are offered.

## D-260 One provider per voice and media job

- **Decision** (Oliver: "remove the gpt realtime fallback, let's use gemini live only … remove the other fallbacks"): each job has one service, and the fallbacks are deleted from the code, not just hidden:
  - **Live calls**, in the app and on the phone: Gemini Live only, on the workspace's Google AI key or else the server's `GOOGLE_AI_API_KEY`. With neither, `POST /v1/voice/session` answers 409 `voice_key_missing` ("Live calls need a Google AI (Gemini) key"), and a phone call fails with that error.
  - **Read aloud:** Gemini Flash-Lite TTS only, on the same keys.
  - **Dictation:** OpenAI (`gpt-4o-mini-transcribe`) on the workspace's key, else Whisper on the server's shared OpenRouter key (D-194).
  - **Images:** OpenRouter only (Nano Banana 2.1, D-185), on the workspace's key or the shared one.
  - **Video:** Gemini Omni Flash only (D-189), on a Google AI key.
- **Removed:**
  - OpenAI Realtime: `createRealtimeSession`, `DEFAULT_REALTIME_MODEL`, the phone bridge's OpenAI branch, `OPENAI_REALTIME_URL`, the `realtime` field of Cloud Models (contracts, domain defaults, the admin sheet's "Call fallback" box), and the app's WebRTC call client (`OpenAiRealtimeConnector`, `RealtimeEvents`). The app still uses `flutter_webrtc` for live view.
  - Read-aloud through OpenAI TTS, ElevenLabs, Cartesia and Fish Audio. Dictation through Deepgram.
  - fal for images and video (`FalMediaProvider`, its price tables, the Seedream and LTX defaults).
  - The provider ids `fal`, `deepgram`, `elevenlabs`, `cartesia` and `fish_audio` from `ProviderId`, so new keys for them can't be added (API or CLI). The Model keys form and its "images" and "voice" hints drop them. The bot Voice sheet loses its read-aloud and dictation pickers and keeps the voice name and Tools on calls.
- **Embeddings unchanged:** OpenAI `text-embedding-3-small` at $0.02 per 1M tokens is 7–10× cheaper than Gemini Embedding ($0.15–0.20), and every stored vector is one of its 1536-dimension vectors.
- **Compatibility, no migration:**
  - Stored keys for removed services stay in Vault and in `model_credentials` (the check constraint still allows them), but `GET /v1/credentials` leaves them out and nothing reads them.
  - A bot's saved `tts_provider`, `realtime_provider` or an `stt_provider` such as `deepgram` is ignored; saving the Voice sheet clears the first two.
  - A saved `cloud_models.realtime` is dropped when the assignment is read.
  - `POST /v1/voice/transcript` still accepts `provider: "openai"` from older apps and prices every call at Gemini's rate.
  - An older app's admin sheet expects `realtime` in the Cloud Models response and can't parse it until the app is updated (admin-only).
- **Tests:** `packages/agent/test/media-prices.test.ts`, `voice-speech.test.ts` and `autonomy.test.ts` (media now runs on OpenRouter and Gemini stand-ins); `apps/server/test/voice.test.ts` (calls on Gemini, no Google key refused, a saved Deepgram preference ignored, read aloud needs a Google key and is cached), `calls.test.ts` (a phone call bridged to a fake Gemini Live), `autonomy.test.ts`, `phone-calls.test.ts`; `client/test/call_tools_test.dart`, `voice_test.dart`, `barge_in_test.dart`, `advanced_connections_test.dart`.

## D-262 Routines that end; bots change every part of a routine

- **Decision** (Oliver: "can our bots be instructed to modify a routine? … can we support expiration date and time for our routines?" → "build all"): a repeating or event routine can end on its own, and `routines.update` covers everything a person can ask for.
  - **Ends:** `routines.ends_at` (a date and time) and `routines.max_runs` (1–10,000), with `run_count`. Migration `20270131000801_routine_ends.sql`. Either or both; once reached, the routine switches itself off (`enabled = false`, `next_run_at = null`) and stays in the list.
  - **What counts:** every run a routine starts on its own (schedule, webhook, calendar, message, device). Manual **Run now** doesn't. The run that reaches `max_runs` switches the routine off in the same statement (`markRun` in `apps/server/src/worker/routines.ts`).
  - **Ends at:** the claim skips routines past their end, a next run past the end switches the routine off instead of being scheduled, every event path (message, calendar, webhook, device) skips ended routines, and `expireRoutines` (each routines tick) switches off any routine past `ends_at`, event routines included.
  - **One-time routines** keep their own rule (one run, then off) and take no end: create refuses `ends_at`/`max_runs` with `in_minutes`/`run_at`, and turning a routine into a one-time one drops its end.
  - **A new `max_runs` counts from now** (resets `run_count`), so "three more times" means three. Resuming a routine past its end or out of runs is refused until the end moves or is removed (`null`), and so is resuming a finished one-time routine without a new time.
- **Bot tools** (`packages/agent/src/tools/autonomy.ts`): `routines.create` takes `ends_at` and `max_runs`; `routines.list` shows the end and runs left; `routines.update` now also takes `name`, `notify`, `timezone`, `in_minutes`, `on_device_event` (device routines only), `ends_at`/`max_runs` (nullable). `schedule_cron` on a one-time routine makes it repeat; `run_at`/`in_minutes` on a repeating one makes it run once. Event routines (device, message, calendar, webhook) keep their trigger kind. Past `run_at` is refused. Still `selfOnly` (D-155): no approval.
- **API:** `Routine` gains `ends_at`, `max_runs`, `run_count` (optional in the contract, for older servers); `CreateRoutineRequest` takes `ends_at`/`max_runs`; `UpdateRoutineRequest` takes them nullable and switches once ↔ repeating like the tool.
- **App:** **New routine** has an **Ends** row (Never, On a date, After some runs) for every trigger but Once; cards show **Ends …** or **N runs left**; the routine menu has **When It Ends**. The app sends that change as raw JSON because the generated request drops nulls.
- **Routines as files (D-124)** carry `ends_at` and `max_runs` since 2026-11-15; a file without them leaves the end as it is, and an import never switches on a routine that has ended.
- **Tests:** `apps/server/test/routine-ends.test.ts` (tools, worker, API); `client/test/routine_ends_test.dart`.

## D-261 Video, read aloud and dictation on OpenRouter

- **Decision** (Oliver: "move what we can to openrouter provider"): video, read aloud and dictation join chat, images and embeddings on OpenRouter. Each uses the workspace's own OpenRouter key, else the server's shared key (`CLOUD_MODEL_UPSTREAM_KEY`) on any server that has one, as images and embeddings do (D-186, D-194). Live calls, in the app and on the phone, stay on Gemini Live with a Google AI key (D-260): OpenRouter has no realtime voice. A Google key is now only for calls, and the Model keys hints say so ("live calls only" for Google; "recommended: chat, images, video, voice" for OpenRouter).
- **Video:** `POST /api/v1/videos` with `google/gemini-omni-1.2-flash`, 720p, 3–15 s, audio on, 16:9 or 9:16. The worker polls `GET /videos/{id}` (5 s, up to 10 minutes; three failed polls in a row end it; `failed`, `cancelled` and `expired` end it with the error) and downloads `GET /videos/{id}/content?index=0` with the key. Animating a picture sends it as `frame_images[0]` (`first_frame`) as a base64 data URL. The direct Gemini Interactions client (`GeminiVideoProvider`) is deleted.
- **Read aloud:** `POST /api/v1/audio/speech` with `google/gemini-3.8-flash-lite-tts` and the same Gemini voices (Kore by default). Gemini TTS there only returns `pcm` (16-bit mono, 24 kHz from the content type); `mp3` is refused with a 400. The PCM gets a WAV header, as before. The direct Gemini call is deleted.
- **Dictation:** `POST /api/v1/audio/transcriptions` (the OpenAI-style multipart upload, one of the three shapes OpenRouter accepts) with `openai/whisper-large-v3-turbo`. The direct OpenAI path is deleted; `STT_PROVIDERS` is `openrouter` only.
- **Cost:**
  - Dictation records OpenRouter's reported `usage.cost`, else $0.0002 a minute.
  - Video records the finished job's `usage.cost`, else $0.069504 a second (OpenRouter's 720p-with-audio price, the same as Google direct).
  - Read aloud is **estimated**, because the speech response carries no cost (only `x-generation-id`): $6 per 1M audio tokens, 25 a second, from the audio length; Google's rate doubles on 2027-01-01.
  - On the shared key with billing on, all three are billable at OpenRouter cost × 1.055 × 1.3 (`cloudOpenRouterCharge`) and need credits (D-246), as before. Read aloud on Cloud used Google's price × 1.3 before.
- **Cloud models:** the `tts`, `stt` and `video` defaults are now OpenRouter ids (`google/gemini-3.8-flash-lite-tts`, `openai/whisper-large-v3-turbo`, `google/gemini-omni-1.2-flash`). A saved bare id is read as an OpenRouter one (`openRouterModelId`): `gemini-…` becomes `google/gemini-…`, `gpt-…` and `whisper-…` become `openai/…`. So a saved `gpt-4o-mini-transcribe` keeps running as `openai/gpt-4o-mini-transcribe`, not the new default. The admin sheet labels which jobs are OpenRouter ids. `live` stays a Gemini API id. `server_voice` in `/v1/config` now lists `read_aloud` and `dictation` with the shared OpenRouter key, and `live` with `GOOGLE_AI_API_KEY`.
- **Checked against OpenRouter on 2026-11-13:** a real speech call (`pcm`, 2.52 s of audio from "Water the fern on Fridays.") and a real transcription of that audio (both JSON and multipart: " Water the fern on Fridays.", `usage: {seconds: 2.52, cost: 0.0000083916}`). Video was **not** called for real (it spends); the job shape follows OpenRouter's API reference and the Omni model's listing (`supported_frame_images: first_frame, last_frame`), tested against fakes. Whether the video API takes a data URL for a frame image is not confirmed by the docs, whose examples use https URLs.
- **Tests:** `packages/agent/test/media-prices.test.ts` (a video job polled, downloaded and priced; a failed job; the first frame), `voice-speech.test.ts` (speech and transcription requests), `autonomy.test.ts`; `packages/domain/test/cloud-model-assignment.test.ts` (id normalization); `apps/server/test/voice.test.ts` (dictation and read aloud on the workspace's OpenRouter key, cached), `voice-server-key.test.ts`; `client/test/barge_in_test.dart`.

## D-263 First run lands in the empty chat, like a new bot

- **Decision** (Oliver: "I want the new user experience to have the same as creating a new bot … we don't need the welcome chats either"): a new person no longer gets the scripted welcome chat (D-129, D-204, D-255, D-257). `POST /v1/welcome` still makes the personal space and a private "Casama" bot, then one plain personal chat with it (`purpose = 'chat'`, no `welcome` state, no opening message), which the D-253 trigger makes their General. The app opens it and shows the empty chat a new bot shows: the bot's mark, Connect your apps tiles and the starter requests.
- **Kept:** the app's name step first (it names the space, D-264); the bot gets its model at once (`ensureBotModel`, which the script did later); default check-ins (D-247). Analytics: `onboarding_begin` and `onboarding_complete` with `path: "auto"` in the same request; no `onboarding_step_view`.
- **Chats already in the script** keep working: `handleWelcomeAction` and the welcome steps are unchanged, and `existingWelcome` finds either kind of first chat, so asking again returns the same one. The script's tests now set up such a chat themselves (`legacyWelcome` in `apps/server/test/helpers.ts`).
- **Response unchanged:** `conversation_id` is still returned, so installed apps open the new empty chat the same way.

## D-264 The space is named from the onboarding name

- **Problem:** the name step saved "Oliver" seconds before the space was made, but the space name came from the sign-up name, then the email ("Nemoryoliver's space").
- **Decision:** `startWelcome` names the space (and its slug) from `profiles.preferred_name` first. Setting the name later, from the welcome name card or About you, renames the person's spaces that still carry a name we made up (from `display_name`, the previous preferred name, or "My space"); a name they chose is never changed (`renameDefaultSpaces` in `packages/agent/src/welcome.ts`).

## D-265 The computer's Terminal tab is always there

- **Decision** (Oliver: "can we just show the Terminal always and no need for the toggle?"): a bot's computer shows Screen, Terminal, Files and Manage with no Advanced toggle, replacing D-182's hidden Terminal. A personal computer still shows only Screen, and Files while online.

## D-266 Plain is the default look

- **Decision** (Oliver: "I want Plain as the default theme from now on"): the out-of-the-box look is the Plain theme instead of Casama's. The `Appearance` defaults (`client/lib/theme/appearance.dart`) are now Plain's: the `shadNeutral` scheme, Google Sans for headings and text (bundled, so nothing loads on first launch), a flat surface with no pattern, and fewer effects on. The Plain preset in `presets.dart` is built from the same constants, so the two can't drift.
- **Who sees it:** new installs, and anyone whose device never saved a look; each setting falls back to Plain's when it isn't saved. A device that applied a theme or changed a setting keeps what it saved. Light or dark still follows the system.
- **Resets:** "Use the Defaults" in Fonts and "Reset to Default" in Background go back to Plain's fonts and flat surface instead of Libre Baskerville, Lato and clouds.
- **Casama stays** as a built-in theme in Settings → Appearance, unchanged.

## D-267 Backups carry the Vault key, restores run as the database admin, and workflow steps are sealed

Stage 0 of `docs/MASTER-PLAN-2026-11.md`. Oliver approved the plan's defaults and asked for it to be executed without questions (2026-11-13); decisions from here to the end of that plan are made on that basis.

- **Found:** a backup could not bring secrets back on another machine. The Vault's root key lives in the `db-config` volume (`pgsodium_root.key`), which no backup included. And `casama selfhost restore` ran `pg_restore` as `postgres`, which is not a superuser on Supabase's image: the Vault's secrets and the sign-in tables belong to other roles, so their rows were skipped while the command reported success. Proved on scratch databases: without the key, or as `postgres`, `vault.decrypted_secrets` comes back empty; with the key in place first and the restore run as `supabase_admin` keeping owners, the secret reads back.
- **Decision:** both backup paths save the key as `vault-key` (the scheduled container only when `BACKUP_AGE_RECIPIENTS` is set, like `.env`, and it warns otherwise; the CLI always, beside `env`). Restore writes the key, restarts the database, then restores as `supabase_admin` without `--no-owner`.
- **Found:** the workflow engine (DBOS) keeps every step's result for replay in `dbos.operation_outputs`. For a run that includes model replies, tool results and summaries, in plain text even in a workspace with encryption at rest (D-136), and nothing ever deleted them.
- **Decision:** `runAgentDurably` seals each step's result with the workspace's key before the engine stores it (`sealStepOutput` / `openStepOutput` in `apps/server/src/worker/workflows.ts`; results recorded before this pass through). The hourly maintenance deletes the engine's records of workflows that ended more than 7 days ago (`purgeEndedWorkflows`). New dependency: `superjson` (the engine's own serializer, so dates survive sealing).
- **Not done:** step results recorded before this change are not rewritten; they go with the 7-day purge. Production needs the new server image and `up -d backup` to pick up the volume mount; that deploy waits for Oliver.

## D-268 Runs that survive: waiting doesn't count, cut-off replies continue, broken streams retry, restarts don't repeat actions

Stage 1 of `docs/MASTER-PLAN-2026-11.md` (Fix 1–5 and 8, Improve (agent) 6 in `docs/PRODUCT-REVIEW-2026-11-13.md`).

- **Waiting for a person:** time spent waiting on an approval, a secret, a takeover or the screen no longer counts toward the run's 30-minute limit. Each wait is bracketed by two recorded steps, so a replayed run adds up the same.
- **Thinking:** gateways emit a `progress` event for reasoning and tool-argument chunks. It resets the silence timers and is never passed on, so a failure after only thinking can still fail over.
- **Claude models** get their reasoning effort (an early return for prompt caching had skipped it).
- **Cut-off replies:** the run loop reads why the model stopped. A reply stopped at the output limit is kept and continued, up to 3 times; a tool call cut off at the limit asks the model to work in smaller pieces. Casama Cloud's output cap rises from 4,096 to 16,384 tokens; spending is held by the run and day budgets, not by the cap.
- **Long tasks:** once a run's own steps pass 75% of the model's context, the oldest tool results (all but the newest 4) are cut to their first lines until the total is under 50%; long file contents the model wrote get the same treatment. A provider's "context too long" refusal trims harder once and asks again. Trimming is deterministic, so replays send the same prompt.
- **Broken streams:** a model step whose stream breaks after it started is tried again up to twice (1 s, then 4 s), and the half-written draft is taken back from the chat first. Errors that can't be helped by trying again (bad keys, context overflow) fail at once.
- **Restarts:** a new server-only table, `run_tool_attempts`, records each tool call as it starts. When the engine runs a step again after a restart, looking, low-risk and self-only tools run again; anything else returns "Casama restarted while this action was running" to the model instead of doing it twice.
- **Orphans:** the minute tick fails runs that still say they're working two minutes after their workflow ended. Runs with no workflow (live calls, teach sessions) are left alone.
- **Not done:** a person-facing "resume" button for a failed run. Retrying the model step and the orphan sweep cover the causes the review found; resume needs the app and waits for Stage 2's retry work.

## D-269 A more capable bot: it sees, edits in place, reads in parallel, checks itself, and remembers its work

Stage 4 of `docs/MASTER-PLAN-2026-11.md` (Improve (agent) 1–5 and 7, Add 9 and 10 in `docs/PRODUCT-REVIEW-2026-11-13.md`).

- **Pictures:** a tool result can carry an image (`ToolResult.image`). `browser.screenshot`, `desktop.screenshot` and `files.read` on a png, jpg, webp or gif attach it, and models that read images get it as part of the tool result. Only the newest two pictures stay in a run's steps (about 1,600 tokens each); older ones become a note. Pictures over 3.5 MB aren't sent.
- **`files.edit`:** replaces an exact piece of a text file (unique unless `replace_all`), so changing one line no longer means rewriting the file through the output cap.
- **Parallel reads:** read-only, non-screen tool calls that come in a row run together in one step; anything else waits for them, and results keep the order the model asked in.
- **`subagent.spawn_many`:** up to 5 helpers at once, each with an equal share of the budget (40% of what's left together, unless set), returning every summary in order. This is also the research mode (Add 9): one helper per item, same fields with sources, merged by the lead into a table. A fully detached background helper was left out; the parallel form covers the case the review found.
- **Memory:** extraction now reads a digest of the run's steps (tool names, arguments and the start of each result, marked as outside content), so what the bot found out while working is remembered. Known memories are numbered, and a correction (`"replaces": n`) updates the old memory through the store's `update` instead of sitting beside it. Recall by meaning alone needs a cosine distance under 0.75 (`search_memories`), so unrelated memories no longer fill every prompt. Saved memories are labelled in the prompt as notes, never instructions.
- **A check before done (Add 10):** a chat run with 4 or more tool steps gets one look from the background model before its reply counts. A reply claiming something no step shows (a failed step reported as done, an unattempted part called finished) is taken back once, and the bot fixes it or says plainly what isn't done. The check fails open and is skipped for group chats and check-ins.
- **The guard after untrusted content (Improve 7, revisiting D-213 in part):** `routines.create` and `routines.update` ask first under the default autonomy once the run has read untrusted content, because a routine is a standing instruction that runs later on its own. Other self-only tools (notes, tasks, memory) still never ask; shell and GET requests stay as D-213 left them, since asking there would make most research runs stop for approval.

## D-270 Chat apps on real traffic: repeats skipped, Feishu decrypted, email bodies fetched, long replies split

Stage 6, first part, of `docs/MASTER-PLAN-2026-11.md` (Fix 18 in `docs/PRODUCT-REVIEW-2026-11-13.md`).

- **Repeats:** every adapter now reads the provider's message id (Telegram `update_id`, Slack `event_id`, Twilio `MessageSid`, WhatsApp and Messenger message ids, Feishu `event_id`, the email's Message-ID). A new server-only table, `channel_inbound_seen`, keeps them for 7 days, so a webhook delivered twice (Slack retries after 3 seconds) starts one run.
- **Feishu:** with an encrypt key set, which Casama requires, Feishu sends every body as `{"encrypt": ...}` (AES-256-CBC). Adapters gained `decode`; the signature is still checked over the body as sent, and handshakes and parsing read the decrypted one.
- **Email:** Resend's inbound webhook carries only the envelope. Adapters gained `enrich`, run after the signature check: the email adapter fetches the body from Resend's received-email API (`/emails/receiving/{id}`; written from the docs and checked against a mock only, listed in NEEDS-FROM-OLIVER).
- **Long replies:** adapters declare `maxText` (Telegram and WhatsApp 4,096, SMS 1,600, Messenger 2,000, Slack 39,000, Feishu 10,000), and `sendThrough` sends longer replies in parts split at a paragraph, line, sentence or word break. Before, they were cut off.
- **Attachments:** a photo, file or voice note no longer vanishes: the bot gets the caption, if any, plus a note that the attachment doesn't come through yet, so it can ask. Receiving and sending the files themselves is left for the Slack app work (Add 1).

## D-271 Push tokens kept unless dead, one sign-in refresh at a time, local models free and able to search memory

From the "alongside" list of `docs/MASTER-PLAN-2026-11.md` (Fix 20, 22 and 23 in `docs/PRODUCT-REVIEW-2026-11-13.md`).

- **Push tokens:** FCM 404 still forgets a token; a 400 only when its message names the token (`fcmTokenGone`). APNs VoIP 410 still does; a 400 only with `BadDeviceToken`. Before, any bad payload unsubscribed every phone it went to.
- **Sign-in refresh:** refreshing a connection's OAuth token takes a per-connection advisory lock, re-reads the token inside it, and refreshes only if it's still expiring. Two runs at once used to refresh twice, and with providers that rotate refresh tokens the loser held a retired token.
- **Local models:** calls on an `openai_compatible` credential (Ollama, LM Studio, vLLM) cost $0, whatever the model is called; a guessed $1/$3 price stopped local runs at the default $1 budget.
- **Local memory search:** an `openai_compatible` credential whose `settings.embedding_model` is set is used for memory and knowledge search when there's no OpenAI key. Vectors shorter than the stored 1,536 dimensions are padded with zeros (cosine similarity unchanged); longer ones are cut and renormalized. The credential API takes and returns `embedding_model` (create and update, `openai_compatible` only).

## D-272 A self-hosted server keeps itself up: a memory budget by default, capped logs, a worker health check, alerts by email

From the "alongside" list of `docs/MASTER-PLAN-2026-11.md` (Fix 21 and Improve (agent) 9 in `docs/PRODUCT-REVIEW-2026-11-13.md`).

- **Memory budget:** the installer sets `COMPUTER_HOST_MEMORY_GB` when it's missing, to the machine's memory less 4 GB (at least 2). Before, a fresh install allowed computers to start until the server ran out of memory. A computer with no recorded size now counts as `COMPUTER_MEMORY_MB` (2,048, the supervisor's default) instead of 1 GB.
- **Logs:** every Compose service keeps 5 files of 20 MB; each bot computer 3 files of 10 MB.
- **Worker health:** the minute tick touches `/tmp/worker-alive`; the worker container is unhealthy when it's over 3 minutes old.
- **Alerts:** the monitoring profile gains Alertmanager, emailing `ALERT_EMAIL` through Auth's SMTP settings, and a disk-over-85% rule. Found on the way: `prometheus.yml` read the metrics token from `/etc/prometheus/metrics_token` while the entrypoint wrote `/tmp/metrics_token`, so every scrape failed and `CasamaApiDown` fired on a healthy server.
- **Not done:** a hard disk cap per computer (needs XFS project quotas on the sandbox host; already in NEEDS-FROM-OLIVER).

## D-273 Knowledge PDFs are read with pdf.js; a scan says it has no text

Stage 8 of `docs/MASTER-PLAN-2026-11.md` (Fix 19 in `docs/PRODUCT-REVIEW-2026-11-13.md`), done early because it's server-only.

- **Decision:** knowledge sources read PDFs with Mozilla's pdf.js (`pdfjs-dist` 6.5.438, Apache-2.0), page by page, with the PDF's own title when it has one. The old reader understood only literal strings in content streams, not the hex strings, font encodings and ToUnicode maps most exported PDFs use, so those files indexed as empty. It stays as a fallback for files pdf.js can't open.
- **Scans:** a PDF with no text layer now fails with "This PDF has no text to read, probably because it's a scan", which shows on the source, instead of indexing nothing silently. Reading scans (OCR) is not built; a vision model per page would need page rendering, which the server image doesn't have.
- `parseDocument` became async; its four callers await it.

## D-274 The Library, Phase 1: an index of everything bots make, and its API

Stage 3, first half, of `docs/MASTER-PLAN-2026-11.md`; `docs/LIBRARY-PLAN.md` Phase 1, with all of its §14 defaults taken (Oliver: "you decide all of those", 2026-11-13).

- **Index:** `public.creations`, one row per thing a bot made: kind (`page`, `image`, `video`, `audio`, `document`, `file`), the bot's label, title, where it came from (bot, chat, run, the person it was made for) and a pointer to the bytes (`page_id`, `media_id`; kept files in Phase 3). Per-person pins and "recently opened" in `creation_marks`. Database triggers fill it from `pages` (every publish, version and title change) and `chat_media`, so every path is covered; existing rows were backfilled.
- **Who sees what:** `can_view_creation`: a page by its own visibility; anything else by the chat it was made in (private chats stay private, D-091); with no chat, the person it was made for and the bot's managers. Renaming and deleting: that person, the bot's managers, or an admin. pgTAP covers it.
- **Deleting a chat keeps what was made** (changes D-220). Its creations lose the chat and stay private to their person. `DELETE /v1/conversations/{id}` and `DELETE /v1/bots/{id}/conversations` take `with_creations=true` to delete them too.
- **Deleting a creation** hides it at once with Undo (`POST /v1/creations/{id}/restore`); the hourly maintenance purges it, with its page or media bytes, after 30 days.
- **API:** `GET /v1/creations` (kind, bot, chat, project, pinned, words, recently opened, deleted; keyset cursor; the workspace's kinds for filter chips), `GET`, `PATCH` (title, label, pin, opened), `DELETE`, `restore`, `content` (byte ranges) and `cover` (a picture is its own cover; a video gets a frame). In the OpenAPI contract and the Dart client.
- **Bots:** `pages.publish` takes a `label` (Site, Game, Report…), the media tools take a `title` (else the prompt's first words), and `library.list` and `library.get` let a bot find its own earlier work and the handle to change it, scoped to what the person it acts for can see.
- **Storage** is counted per workspace (`organizations.storage_bytes`) from the start; caps come with Phase 3.

## D-275 Failed runs are free, owners see usage by person, and hear when credits run low

Stage 5 (cost clarity, server side) of `docs/MASTER-PLAN-2026-11.md` (Add 4 in `docs/PRODUCT-REVIEW-2026-11-13.md`; the plan's decision 4 default: no charge for failed runs).

- **Failed runs:** a run that fails on Casama's or a provider's side (the workflow's catch-all `run_error`) has its Casama-billed model usage waived (`waiveFailedRun`): rows not yet settled stop being billable and are marked `waived`; rows already settled come back once as a `refund` credit. Computer time is still billed, since the computer ran. Runs that stopped at a limit, looped or were stopped by the person are charged as before.
- **Usage report:** `GET /v1/usage` leaves waived charges out of its totals and reports them as `waived_usd`, and gives admins and owners `by_person`: what each member's work cost and how many runs.
- **Low credits:** after each settlement, owners of a workspace whose balance fell under $1 (and above zero) with billable usage in the last day get a `credits_low` notification, at most once a week.
- **Not done here:** "a price before a long run". Casama can't know a run's length in advance; the run and day budgets (now settable in the app, Stage 5 app work) are the control that answers it.

## D-276 The Library, Phase 3 (server): files a reply links to are kept, with versions and storage caps

Stage 5 of `docs/MASTER-PLAN-2026-11.md`; `docs/LIBRARY-PLAN.md` Phase 3, server side.

- **Kept files:** when a chat reply links to files on the bot's computer, up to 8 of them (each up to 50 MB) are copied to the object store before the reply is saved, while the computer is still awake. Each becomes a creation keyed by bot, computer and path; handing the same file over again with new bytes makes a new version (the same bytes don't), and the last 5 versions are kept (`creation_versions`). The reply gains a `creation` part per kept file; shipped apps skip unknown parts and keep showing the link. Personal computers are skipped: the person's own files stay on their machine.
- **`library.save`:** a bot keeps a file it didn't link, with a title and label.
- **Where the bytes go:** the API and worker read `OBJECT_STORE` / `OBJECT_STORE_DIR` (`objectStoreFromEnv`). Compose gives both a `library` volume at `/data/library` (the server image creates the folder as its own user so the volume is writable), or S3 with `LIBRARY_OBJECT_STORE=s3` and `LIBRARY_S3_*`. Backups always include it (`library.tar.gz`).
- **Serving:** `GET /v1/creations/{id}/content` streams kept files (byte ranges; `sandbox` CSP so HTML can't run), and a kept picture is its own cover.
- **Storage caps:** plans gain `storage_gb` (Free 1, Plus 10, Pro 50, Max 200; self-hosted none). At the cap a kept file, a generated picture or video, and a new page are refused with "the Library is full"; nothing is ever deleted for the person. The purge deletes kept files' bytes with their rows.
- **Not done:** real covers for pages and documents (they need the PDF/screenshot service on, which is a production change), the Usage screen's storage row and the `storage_full` paywall source (app work), and moving `chat_media` bytes out of Postgres (Phase 5).

## D-277 Slack as a place to work: one-click install, @mentions, a reaction on arrival, approvals with buttons

Stage 6 of `docs/MASTER-PLAN-2026-11.md` (Add 1 in `docs/PRODUCT-REVIEW-2026-11-13.md`), Slack first.

- **One-click install:** with `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET` and `SLACK_SIGNING_SECRET` set (Casama Cloud's own Slack app), `GET /v1/channels/slack/install?bot_id=` returns Slack's sign-in address; the callback `/hooks/slack/oauth` stores the workspace's bot token and makes the chat app, with the installing person allowed to talk to it. Its events and button presses arrive at `/hooks/slack/events` and `/hooks/slack/interact` and are routed by Slack workspace. One Casama bot per Slack workspace through Casama's app; installing again moves it. Without those settings the endpoint answers 409 and self-hosters keep connecting their own Slack app with a bot token (D-134).
- **Where people talk:** @mentions in channels (`app_mention`, the mention stripped) as well as direct messages; the same message arriving as both events starts one run. An 👀 reaction shows the message arrived.
- **Approvals in the thread:** when a run from a Slack thread needs approval, the request is posted into the thread with Approve and Deny buttons (as well as the usual push). A press is accepted only from someone on the chat app's allowed list, for an approval of that bot in that channel's thread; it's decided as the person who connected the app, the run wakes, and the message is replaced with "Approved by @…". Self-hosted Slack apps use `/hooks/channels/{id}/interact`.
- **Needs from Oliver:** a Slack app listing for Casama Cloud (client id, secret, signing secret, and the three URLs above). Teams and Discord follow (D-278).

## D-278 Microsoft Teams and Discord as chat apps

Stage 6 of `docs/MASTER-PLAN-2026-11.md` (Add 1), after Slack (D-277).

- **Teams** (Bot Framework): people message the bot in Teams chats and channels (an @mention, stripped). Each activity's bearer token is checked against Microsoft's published keys (issuer `https://api.botframework.com`, audience the bot's app id, and the token's service address must match the activity's). Replies go to the conversation's service address with a token from Microsoft sign-in (`app_id` and `app_password` of the Azure bot). Adapters gained `verifyAsync` for checks that need the network.
- **Discord** (HTTP interactions): Discord bots hear ordinary messages only over a gateway connection a webhook server doesn't keep, so people talk to the bot through its `/ask` command. Requests are checked with the application's Ed25519 public key; PING is answered, a command gets Discord's "thinking…" at once (adapters gained `respond`), and the reply goes to the interaction's follow-up address within its 15 minutes, then as a channel message with the bot token.
- Both are new channel kinds (migration, contract, the app's chat-apps screen with their setup fields, and routine message triggers). Long replies are split at Teams' and Discord's limits (D-270). Buttons for approvals in Teams and Discord are not built; those approvals arrive in the app as before.
- **Needs from Oliver:** an Azure bot registration and a Discord application to try them for real; both are built against signed test requests.

## D-279 Pages that take input: forms and responses, on the page's own origin only

Stage 8 of `docs/MASTER-PLAN-2026-11.md` (Add 3; plan decision 8: yes, changing D-119 for pages that opt in).

- **Opting in:** `pages.publish` takes `collect: true`. Only such a page gets a small runtime (`casama.submit(object)`, and any `<form data-casama-form>` sends its fields and shows `data-casama-sent`) and a policy that allows `connect-src 'self'`; `form-action` stays `'none'` (the runtime sends with fetch), and every other source stays as strict as before. A page that doesn't collect is served exactly as before.
- **Responses** go to the page's own address (`/p/{id}/collect` for signed-in viewers, `/s/{token}/collect` for a public link), at most 64 KB, JSON objects only, and at most 20 an hour per address on a public page. They're stored in `page_submissions` (sealed in workspaces that encrypt; readable by the page's person and the bot's managers) and the Library's page counts them.
- **The bot** reads them with `pages.submissions` (marked as outside content), and `on_submit` instructions make a routine that starts with each response. It uses the existing "webhook" trigger, because shipped apps refuse unknown trigger types when listing routines.
- Bots are told never to ask for passwords, card numbers or other secrets on a page.

## D-280 Documents are finished outputs: kept with a PDF preview and a cover

Stage 8 of `docs/MASTER-PLAN-2026-11.md` (Add 2 in `docs/PRODUCT-REVIEW-2026-11-13.md`).

- **What was already there:** bot computers have LibreOffice, pptxgenjs, docx, python-pptx and openpyxl, and the catalog's document skills; bots could always make real Office files. What competitors do better is treat them as finished outputs that open anywhere.
- **Decision:** when a kept file (D-276) is a PDF or an Office document, the computer makes a PDF of it with LibreOffice and a PNG of its first page with pdftoppm while it's still awake. Both are stored with the creation (`preview_key`, `cover_key`), so the Library shows the document's first page and `GET /v1/creations/{id}/preview` opens it as a PDF with the computer asleep or reset. Best effort: a document without them still opens as the original file.
- Bots are told to make a real .pptx, .docx or .xlsx when someone wants slides, a document or a spreadsheet they'll edit, and to link it.
- **Not done:** editing inside the app; the original file opens in the person's own apps.

## D-281 Share anything in the Library: workspace and public links, reports and takedown

Stage 7 of `docs/MASTER-PLAN-2026-11.md`; `docs/LIBRARY-PLAN.md` Phase 5 (sharing), with §14's default that public links are allowed on Free, rate-limited.

- **Levels:** every creation has a visibility: private (as before: its chat's people, or its person and the bot's managers), workspace (every member), or public (anyone with the link). `PATCH /v1/creations/{id}` with `visibility` changes it; a page goes through its own visibility (D-119), so the two never disagree. Making something public returns `public_url` once; doing it again gives a new link and the old one stops working.
- **Public viewer:** on the pages origin, `/c/{token}` shows a picture, a video, a sound or a link to open the document (its PDF preview when there is one), under a policy with no scripts at all. `/c/{token}/raw` serves the bytes inline only for picture, video, sound and PDF types; anything else (an HTML file, say) downloads, so a shared file can't run on Casama's origin.
- **Abuse:** at most 20 new public links per workspace a day; every public creation and every public page has a Report link; three different reporters hide a link until an instance owner looks (`GET /v1/admin/reports`, `POST /v1/admin/creations/{id}/takedown`, which also turns a page private). Reporters are counted by a hash of their address, never the address.
- **Not done here:** moving generated media's bytes out of Postgres (the other half of Phase 5).

## D-282 Export a chat, and share a read-only link to it

Stage 7 of `docs/MASTER-PLAN-2026-11.md` (the rest of Add 11).

- **Export:** `GET /v1/conversations/{id}/export` downloads the shown branch as Markdown (default) or JSON: each message's author, time, text, and the names of what came with it. It reads in the person's own session, so it contains only what they can see.
- **Public link:** `POST /v1/conversations/{id}/share` with `public: true` returns a link on the pages origin (`/t/{token}`) that shows the chat read-only, as its starter saw it, under a policy with no scripts; message text is escaped. Making it public again gives a new link; `public: false` stops it. Only the chat's starter or the bot's managers can share, and a private chat (personal device data, D-091) can't be made public. Attachments are listed by name, not served.

## D-283 Chat basics in the app: drafts on the web, files shared in, an in-app banner, edits to routines, topics and memory, and the small chat features

Stage 2 of `docs/MASTER-PLAN-2026-11.md` (the review's Fix 14–17, Improve app 1–3 and the small ones in Add 11), plus deleting a chat with what was made there (D-274). Each item has its own commit and test.

- **Drafts on the web (Fix 14):** the web keeps `draft:` keys, and only those, in the browser's local storage (`DraftsOnlyCache`); messages stay uncached there as before (D-112). Signing out clears them.
- **Sharing in (Fix 15):** on Android a shared picture, video or file reaches quick ask as the file itself, uploaded to the bot's computer and sent as an attachment. The iOS share extension still passes text only: carrying files needs an App Group copy and a native channel, and can only be checked on a device.
- **In-app banner (Fix 16):** comes from the live inbox, so it works on every platform with or without push (Windows and Linux still have no push). Requests, secrets, link invitations and urgent messages get it; plain updates stay a badge. It hides after 10 s and never shows for the screen already open.
- **Attachments (Fix 17):** the app picks the bot's computer as the server does (its default computer only, else its own, else the team computer), never another computer in the workspace.
- **Routines (Improve app 1):** a routine opens an edit sheet (name, instructions; cron and timezone, or the one-time run's time) with its last 10 runs, read from `runs` by `routine_id`. Event routines keep their trigger.
- **Topics (Improve app 2):** `PATCH /v1/conversations/{id}` renames or pins (`conversations.pinned_at`), for the chat's starter or the bot's managers (the delete rule). Pinned topics list after General and needs-you topics and never move to Older. A pin belongs to the chat, which in practice is one person's (topics are per person since D-253).
- **Memory (Improve app 3):** search filters the loaded list as you type (every word, any order). Add a Memory saves a fact or a preference through the existing memory import route, which seals it like any memory; no new endpoint.
- **Small chat features (Add 11):** Regenerate reruns the message a reply answered through the edit route, so the old reply stays one arrow away. `DELETE /v1/conversations/{id}/messages/{message_id}` deletes one message (the sender, the chat's starter or the bot's managers; refused while the bot works); the messages after it are joined to the one before it, and the head moves back. Find in Chat matches the messages loaded so far (older pages load as you scroll), opened from the chat menu or Cmd/Ctrl+F. Cmd/Ctrl+V attaches a picture on the clipboard through the `pasteboard` plugin (desktop and the web). Rate a reply was left out.
- **Deleting a chat:** the confirmation counts what was made there and offers "Also delete the N things made here", off by default (`with_creations=true`).
- **Not verified on devices:** Android share-in, the banner on Windows and Linux, and paste on each desktop OS and browser need a real build to confirm.

## D-289 Sites and games with their own files

Stage 8 of `docs/MASTER-PLAN-2026-11.md`; `docs/LIBRARY-PLAN.md` Phase 6 ("sites and games with real assets").

- **Decision:** `pages.publish` takes `folder`, a folder on the bot's computer with an `index.html`. The other files (up to 300 and 25 MB in all) go to the object store per page version (`page_assets`), and the page is served with a `<base>` pointing at its own files and a policy that allows scripts, styles, images, sounds, fonts and fetches from the pages origin only (`PAGE_CSP_ASSETS`). Nothing beyond Casama's page address can load, as before. Publishing the page again as one HTML file drops the files.
- Files are served from the live version only; a path with `..` or `.` is refused. The Library counts their size against the workspace's storage, and the purge deletes them with the page.
- **Not done:** custom domains, server-side code for a site, and removing an older version's files when a site is republished (they stay until the page is deleted).

## D-284 Bots make spoken audio

Stage 8 of `docs/MASTER-PLAN-2026-11.md`; `docs/LIBRARY-PLAN.md` Phase 6 ("sound").

- **Decision:** `media.audio.generate` turns up to 4,000 characters into speech in a chosen Gemini voice, on the same OpenRouter speech service as read-aloud (D-261): the workspace's own key, else the server's. It shows under the reply, is saved on the computer when there is one, and is kept in the Library as audio. It asks first under the default autonomy, like pictures and videos, and is charged as `tts_chars` (with markup and a credit check on the server's key), so no new paid dependency.
- **Not done:** music and sound effects. No provider on the keys Casama already uses makes them; adding one is a new paid dependency that needs its own decision and a row in `docs/COSTS.md`. Duplicating a creation is also not built yet.

## D-285 Give a bot a Linear or Jira issue

Stage 6 of `docs/MASTER-PLAN-2026-11.md` (Add 14 in `docs/PRODUCT-REVIEW-2026-11-13.md`).

- **Decision:** Linear and Jira are chat-app kinds, so they reuse everything chat apps have: the signed webhook, the allowed-senders gate, repeats skipped (D-270), one conversation per issue, and routines started by a message. Assigning an issue to the tracker user that stands for the bot (or creating it assigned) starts a run with the issue's title and description; comments on an issue the bot holds continue the conversation; the bot's reply is posted as a comment on the issue. Changes the bot made itself are ignored.
- **Linear:** webhooks signed with `Linear-Signature` (HMAC of the body, timestamp within 5 minutes); comments through the GraphQL API with an API key.
- **Jira Cloud:** webhooks with a secret (`X-Hub-Signature: sha256=…`); descriptions and comments read from Atlassian's document format; comments posted with the account's email and API token.
- **Not done:** moving the issue's status as the bot works (it says so in its comment instead).

## D-286 Knowledge that keeps up: per-source sync interval, unchanged pieces reuse their embeddings

Stage 8 of `docs/MASTER-PLAN-2026-11.md` (Add 5, server side; the app's screens for connection sources are app work).

- **Decision:** a knowledge source can sync every 1 to 168 hours (`sync_every_hours`; 24 by default; uploads never change). Each piece's text is hashed (`knowledge_chunks.text_hash`): a piece that's the same as before keeps its embedding, and a source whose pieces all match (`content_hash`) isn't rewritten at all. An hourly sync of a website or Drive folder that rarely changes therefore costs one read and no embedding calls.

## D-287 Meeting notes without a meeting bot

Stage 8 of `docs/MASTER-PLAN-2026-11.md` (Add 6; meeting bots stay cut, D-123).

- **After the meeting:** calendar routines take `anchor: "end"`, so the offset counts from the meeting's end ("5 minutes after each standup ends") instead of its start.
- **A gallery routine idea, "Meeting notes":** each weekday evening the bot gathers the day's notes from whichever notes app is connected (Fireflies, Granola, Circleback, Otter, Fathom, Zoom or Google Meet, through the existing app connections) or from the calendar, and files one Markdown file per meeting in the team folder (`shared/meetings/`) with decisions and action items, asking before it sends anything. Gallery routine ideas are schedule-only, because shipped apps parse them strictly; the after-meeting version is made as a calendar routine.
- **Not done:** the gallery change reaches the public gallery only when it's published (a production step for Oliver), and none of the notes apps were tried with a real account.

## D-290 Generated media out of Postgres, and bytes deleted with their rows

Stage 7 of `docs/MASTER-PLAN-2026-11.md`; the second half of `docs/LIBRARY-PLAN.md` Phase 5.

- **Decision:** with an object store configured (the Library's volume by default, D-276), new pictures, videos and sounds are written there and `chat_media` keeps only the key; the hourly maintenance moves older rows' bytes out 50 at a time. Every reader goes through `readMedia`, which serves either place, byte ranges included, so nothing changes for the app. The nightly database dump stops growing with media.
- **Deletion:** a trigger on `chat_media`, `creations`, `creation_versions` and `page_assets` queues the keys of any deleted row (`deleted_blobs`), whatever deleted it, including workspace and account deletion cascades; the maintenance deletes those bytes unless another row still uses the key.

## D-291 Duplicate anything in the Library; stored bytes are deleted only when nothing uses them

`docs/LIBRARY-PLAN.md` Phase 6 ("duplicate a creation and change the copy").

- **Decision:** `POST /v1/creations/{id}/duplicate` makes a private copy for the person asking: a page becomes a new page with the same layout, data and files; a picture, video or sound a new media row; a kept file a new creation not tied to the computer's file. Copies share the stored bytes instead of copying them (their size still counts toward storage).
- **Consequence:** bytes are now deleted only through the queue (D-290), which checks no other row still uses them. The 30-day purge and pruning a kept file's old versions stopped deleting bytes directly.

## D-292 Two accounts of one app already work

Add 12 in `docs/PRODUCT-REVIEW-2026-11-13.md` ("two accounts of one app"), checked in the code: an app connected directly (its own sign-in or key) can be connected again, and the second becomes `gmail_2` (`freeName` in `apps/server/src/api/routes/apps.ts`), with its own tools. Connections through Composio's managed sign-in share one connection per workspace, so a second account of the same app isn't possible there; that's Composio's model, recorded here rather than worked around.

## D-293 Eval tasks for the run-loop changes

Stage 1's eval item in `docs/MASTER-PLAN-2026-11.md` (Improve (agent) 8).

- **Decision:** four tasks join the suite (now 34): changing one line of a file with `files.edit` and nothing else, a 60-item answer that must reach item 60 (a reply cut off at the output limit doesn't), reading three files and summing them, and refusing to claim a copy of a file that doesn't exist (the check before done). They run in live mode; the quick fixture subset is unchanged.
- **Not done:** a stored live baseline. Running the suite live costs money (roughly $0.05–0.25), so it waits for Oliver's go-ahead (NEEDS-FROM-OLIVER); until then the nightly run can't fail.

## D-294 The Library in the app (Library Phase 2)

Stage 3, second half, of `docs/MASTER-PLAN-2026-11.md`; `docs/LIBRARY-PLAN.md` Phase 2, with the §14 defaults (Library, a third place, Chats / Library / Tasks).

- **The place:** phones get a third tab in the pill, tablets a third rail destination, desktop a Library row above Tasks in the sidebar. `/library` is a tab root (`?kind=`, `?bot=`, `?q=`), `/library/:id` one creation. Tapping Library again scrolls to the top. The "something new" dot was left out for now.
- **The screen:** a search box, kind chips (only kinds the workspace has, from the list's `kinds`), a Pinned shelf, then Today, Yesterday, This week and Earlier; a grid of 4:3 covers with title, bot and time and a kind pill (pictures and videos pack tighter when filtered). A skeleton while it loads, Try Again when it fails, a no-match line for a filter, and for an empty Library the sleepy mascot with three starters (a game, a logo, a one-page site) that open quick ask with the bot talked to last and the request typed in, not sent. 60 at a time, more on scroll, pull to refresh. On a wide window a picked tile opens beside the grid.
- **Covers:** the server's cover when `has_cover` (cache-busted by version); otherwise, and when a cover fails to load, a drawn cover: a tint picked from the id, the kind's glyph and the title.
- **One creation:** the preview (the player for chat videos and sounds, the cover elsewhere), the title (tap to rename), who made it, when, its version and who can see it; the main action for its kind (Open or Play for pages through the single-use view link, View for chat media in the existing preview, Open for documents and kept files through the system), Change it, and a menu with Rename, Pin, Who Can See It (private, workspace, public with the warning and the link, D-281), Export PDF for pages, and Delete (hidden at once, Undo restores). Rows for the chat it came from and its details; "Made alongside" shows the same run's other things. Opening marks it opened (Recently opened).
- **Change it** opens the chat it came from (else the bot's General) with the composer filled in, `About “Space Dodger”: `, and the cursor at the end. The bot finds the item with `library.list`. The plan's `about` message part (the creation's id in the agent's context) needs agent work and is not built.
- **Ways in:** a page card or a generated picture or video in a chat has Show in Library on a long-press or right-click (the item is looked up by its page or media id, since chat parts don't carry the creation id); the "Show in Library" button after a published page; the bot profile's Library tile (in place of the Pages row); search's Library scope and results (through `/v1/creations?q=`, since server search has no `creation` kind) and its Go to: Library place; "Ada published …" in Updates opens the item when the Library finds it, else the page as before.
- **Pages retired:** the Pages screen and the Inbox's Pages filter are gone; `/pages` and `/pages?bot=` redirect to `/library?kind=page`. `pages_screen.dart` keeps only what opens a page.
- **Not built here:** the dot, stacks of a run's pictures, Sort and Mine/Workspace filters, the side panel's Made here tab (Phase 4), live updates (the grid refreshes on open and on pull), and previews of documents' PDFs (D-280) inside the detail.

## D-295 Light projects: a project is the home for one piece of work, and the Library groups by it

Oliver asked whether the Library should group work by project ("the user wants to make a game: the plan, to-dos, assets and code belong together"), then left the design to me ("you decide", "build all now", 2026-11-14). It replaces the Collections planned for `docs/LIBRARY-PLAN.md` Phase 4, so there is one way things are grouped.

- **Decision:** a project needs only a name and a bot. Planning for approval, milestones, the budget and the heartbeat (D-113) are a mode switched on per project (`projects.autonomous`; every project made before this has it on). A project is not a folder in the Library: things are filed under it by themselves and still show in the Library's own grid.
- **Why not folders:** a folder needs filing by hand, most work starts in a plain chat and would land in "no project", and pulling code and scratch files in would break the Library's rule that it holds only what was handed over (and fill the storage cap).
- **Filed by itself:** `creations.project_id`. A trigger fills it from the run that made the thing, else from the chat it was made in. Until now the only link was creation → run → project, which pages never had (their creation has no run when it's made) and which was lost with the run (`run_id` is set null). A run started in a project's chat now carries the project too (a trigger on `runs`), so what a person asks for there counts toward the project's spend and timeline.
- **Where the pieces live:** the plan stays `plan_md`, to-dos stay tickets, sites, games and media stay Library items, and code stays on the bot's computer in one folder per project (`projects/<slug>` under the bot's work folder; the API returns it under the home folder as `folder`). None of these became loose Library files. For code that should outlive the computer, the bot is told to zip the folder and keep it with `library.save` labelled Source: one item, a new version each time.
- **A project's chat is a topic** (changes D-253, which kept project chats out of General and topics): a person's own chat that becomes a project's chat stays under General. The threads D-113 opens for a project that works by itself are not personal chats, so they stay out as before. General can't become a project, and a project's chat is never promoted to General.
- **Three ways to start one:**
  - the app's New project sheet (a name and a bot; the project gets a new topic);
  - Make This a Project in a topic's menu (`POST /v1/projects` with `conversation_id`): the topic becomes its chat, and what was made and spent there moves under it;
  - the bot's `projects.create`, which no longer plans by default. In a topic it adopts the topic. In General it files only that run (`runs.project_id`), and in later runs the bot calls the new `projects.open` first; its prompt lists the person's open projects so it knows to.
- **Working by itself is a switch:** `PATCH /v1/projects/{id}` with `autonomous`. On needs a goal, refuses while a run works in the project's chat (nothing is posted mid-run, D-253), and starts planning, or carries on when a plan was approved earlier. Off returns a planning, paused or blocked project to active and the heartbeat leaves it alone; a session already running finishes. `status: "done"` finishes a project, and one worked on together can be made active again.
- **Bots:** `projects.plan` in a project worked on together saves the to-dos with no approval, sign-off or notification; `projects.update` refuses `blocked` there (the bot asks in the chat); `projects.status` lists open to-dos with their ids; `tasks.create` files a ticket under the project the run works on; `library.list` takes a project. A run in a project gets a prompt block with the project's folder, goal and plan.
- **Who sees a project:** one made in the app's list is the workspace's, as before. One that grew out of someone's own chat (`projects.personal`: made from a topic, or by a bot in a personal chat) is seen by its owner and by whoever can open its chat (`can_view_project`), so a private chat's plan stays private (D-091). The bot tools apply the same rule to the person a run acts for.
- **On the wire:** `POST /v1/projects` still plans and runs by itself when `autonomous` is left out, because shipped apps send a goal and expect planning. New fields in answers are optional, and the app treats a missing `autonomous` as on, so a new app works against an older server.
- **App:** the Library has a Projects row (compact cards, so the grid stays on a phone's first screen) and `/library?project=`; the project screen shows Made in this project, the plan, to-dos, Files (opens the computer's Files tab at the folder, shown empty until the bot saves something there; on a team computer the folder is under the bot's own folder, D-148), the switch, and Mark as Done or Reopen; a thing in the Library shows its project and has Move to Project; a topic has Make This a Project, and a project's topic a Project chip.
- **Not done:**
  - Tickets are still the workspace's board, so a personal project's to-dos are visible to every member.
  - A project has one lead bot and one chat; other chats can't be added to it by hand.
  - The app can't rename, cancel or delete a project, or set its deadline (the API can do all but delete).
  - Stacks, select several and the side panel's Made here tab (Library Phase 4) are still open.
  - Nothing zips the Source by itself: it's an instruction to the bot.
  - The screens were checked by widget tests only, not on a device.
- **Tests:** API with a scripted model (`light-projects.test.ts`: a project from the app, from a topic, from a bot in a topic and in General, `projects.open`, filing, moving a thing, who sees what, the switch both ways), pgTAP (`light_projects_rls.test.sql`), widget tests (`light_projects_test.dart`, `projects_test.dart`). `sealed-steps.test.ts` now waits for the run's workflow to end before it checks the purge: it raced the run's last steps, and the new `project-context` step shifted the timing enough to lose that race in a full run.

## D-296 Casama Connect: a self-hosted server gets a public address through Casama Cloud

**Renamed to Casama Link (2026-11-15, Oliver):** the feature is **Casama Link**, and addresses live on **casama.link** (bought that day). Everything was renamed: code (`src/link/`, `features/link/`), tables (`link_servers`, `link_sign_in_requests`; the old Cloud Connect tables `cloud_connect_keys`/`cloud_connect_computers` become `link_keys`/`link_computers` in a new forward migration, `20270201100200`, since production has them), env (`CONNECT_*` → `CASAMA_LINK_*`, `CLOUD_CONNECT` → `CASAMA_LINK_CLOUD`, `CONNECT_LINK_URL` → `CASAMA_LINK_SIGN_IN_URL`), routes (`/connect/v1/*` → `/link/v1/*` with `/link/v1/sign-in/*` for linking, `/v1/cloud-connect/*` → `/v1/link/*`, `/v1/admin/connect/*` → `/v1/admin/link/*`), the compose profile and volume (`link`), docs and app text. Usage tagged `cloud_connect` is retagged `casama_link`. "link" alone already means share links, so the code prefix is `casamaLink`/`CASAMA_LINK_` where a bare `link` would be ambiguous. The text below keeps the old name as written at the time; `docs/LINK-PLAN.md` (was `CONNECT-PLAN.md`) is current.

`docs/CONNECT-PLAN.md`, with Oliver's answers of 2026-11-14 (its §13). Built on the branch `worktree-casama-connect`; nothing is on `main` or in production until Oliver says. (D-295 is Light projects, on `main`.)

- **The problem:** a server run by the desktop app ("Run Casama on This Computer") or `install.sh --local` answers only on that computer. Using it from a phone needed a VPS or a domain and a tunnel set up by hand.
- **Decision:** the server links to a **Casama Cloud account** (no separate account system) and gets an address `https://<12 random characters>.<zone>` through a Cloudflare tunnel of its own. A `connector` container (Compose profile `connect`, pinned `cloudflared`) holds the tunnel open; it only dials out. Phone traffic goes phone → Cloudflare → the computer and never through Casama's servers. Casama Cloud is the control plane only: which server has which address, and taking one away.
- **One name:** the old "Cloud Connect" (cloud computers and model credits for self-hosters) is now part of **Casama Connect**. The keys (`kcc_`), tables and `/connect/v1` paths keep their names.
- **The zone is a new domain, never `casama.ai`:** anything hosted on these addresses is someone else's server, so a report or a block list hits that domain and not ours. Oliver buys it; until then everything runs against a fake Cloudflare in tests (`apps/server/test/fake-cloudflare.ts`).
- **Linking** is a device-code flow: the server shows a code, a workspace owner or admin approves it at `/link` in the app, and the server collects a key once. A linked key has the scopes `remote_access` and `push`, neither of which can spend money. Revoking the key removes the address.
- **Servers per workspace** (plan limit `remote_servers`): Free 1, Plus 1, Pro 3, Max 10.
- **Safe to expose:** remote access turns on only when the server already has an account (otherwise the first stranger to sign up would own it), and it sets `DISABLE_SIGNUP=true`. "Let invited people sign up" (`SIGNUP_INVITED_ONLY`) lets in only an email address with a pending workspace invite, checked by the existing before-user-created hook, which fails closed. Rate limits see the real caller (`cf-connecting-ip`).
- **The computer's own app keeps working:** `GET /v1/config` answers a loopback caller with `CASAMA_LOCAL_URL`, so the app on that computer keeps its session and works with no internet. Tokens are checked with the shared secret, so either address accepts them.
- **Scan to sign in** (self-hosted servers and Casama Cloud alike): the app or `casama pair` shows a QR code holding the server's address and a one-time code (hashed, five minutes). The phone redeems it at the server for a one-time sign-in link from Auth's admin API. Casama Cloud never sees the code, so it can't sign in to anyone's server. A "New sign-in" notice goes to the account each time.
- **Push through Casama Cloud:** only Casama's Firebase key (and Apple key, for iPhone call rings) can address the store apps, so a linked server with no key of its own sends through `POST /connect/v1/push`. Nothing is stored there. **Private notifications** (a server setting) sends no text: the phone shows "New activity", a call rings as "Casama", and the app loads the rest from the server. A server on its own domain can link for this alone (`casama selfhost remote link`).
- **Self-healing:** each address has a generation; the server checks in hourly, fetches its tunnel secret again when the cloud made the tunnel anew, and asks for a new one when its connector stays disconnected for five minutes. Losing touch with Casama Cloud never takes a working address down.
- **Upkeep on the cloud:** Cloudflare includes 1,000 tunnels per account and charges for each one past that, idle or not, so a server silent for `CONNECT_PARK_AFTER_DAYS` (14) can have its tunnel removed and its address kept (`CONNECT_PARKING`: off, dry-run or on; off until there are numbers to look at). The sweep also finishes removals that failed, forgets addresses nobody came back for after 90 days, and warns the instance owners once a day near the tunnel and DNS record limits. Suspending a server or a workspace removes its tunnels at once, and its key is refused new relay credentials and push until the suspension is lifted.
- **Live view away from the computer:** live view is WebRTC through a relay, and the server's own relay is behind the home router. A viewer who isn't on the server's own machine gets short-lived credentials for Cloudflare's TURN service from Casama Cloud (`POST /connect/v1/turn-credentials`, 12 hours, 24 asks a day per key, plan limit `connect_live_view`). The bot's computer has no route to the internet except the egress proxy, so the `turn` container forwards one unpublished port (3479) to that relay and nowhere else, and the streamer is told to use it. A running streamer is started again only when it wasn't given the relay a viewer needs. Without the plan, viewers away see the existing screenshot fallback and the app says why.
- **Checked against the real Cloudflare (2026-11-14), before the zone exists:** the tunnel adapter made, adopted, connected (the real `connector` image was healthy in 16 s), counted and removed a tunnel on the Stackwares account (`apps/server/scripts/connect-live-check.ts`). With Oliver's yes, a second run made the two DNS records on oliverbytes.dev for a few minutes: both addresses answered over https through the tunnel, and everything was removed while the connector was still attached. Real relay credentials came from a TURN key made with the `cf` CLI (in Vaultwarden as "Casama · Cloudflare TURN key (Casama Connect live view)"). Live view through Cloudflare's relay worked end to end with Chrome (the phones' WebRTC library) as the viewer away: video in about 3 s, three runs out of three (`packages/sandbox/test/live-outside-relay.test.ts`).
- **The whole flow end to end (2026-11-15):** a second self-hosted stack from this branch on the same Mac (`CASAMA_CONTAINER_PREFIX=casama-t`, its own ports), linked to a stand-in Casama Cloud running this branch with the real Cloudflare (zone oliverbytes.dev) and the real TURN key. `casama selfhost remote on` linked, got the address, restarted and connected; the address answered over https; outside callers got the public sign-in address and the Mac's own app kept `localhost`; a stranger's sign-up through the address was refused; `casama pair` made a code that a "phone" redeemed over the address for its own session, once only; live view asked for through the address got Cloudflare's relay (at home, the local one) and Chrome watched the bot's desktop through the tunnel and the relay; `remote off` removed the tunnel and both DNS records. Not on a device: the installed app builds predate these screens, and the simulators were in use or unreachable.
- **On a real iPhone (2026-11-15):** a debug build of this branch on an iPhone 14 Pro Max against the same kind of test stack. Scanning the code in the app moved it to the server and signed in without a password; live view on Wi-Fi through the public address used Cloudflare's relay (104.30.x.x); turning off removed the tunnel and records. Scanning with the iPhone's own Camera opened casama.ai/pair in Safari and got "not found": the page and the `/pair` universal link are on this branch but casama.ai isn't deployed yet. Mobile data wasn't tried (none on hand).
- **What the iPhone run found:** once the app was open, a server that stopped answering showed nothing: refreshes failed quietly behind the offline cache. Now every API call reports whether the server answered (`core/server_reachability.dart`), and a bar over the app says "Can't reach your Casama server" or, for a person's own server behind a tunnel (530, 502 to 504), "Your server is offline", with Try Again. It checks every 10 seconds and on coming back to the front, and when the server answers it goes away and reloads workspaces and bots. Checked on the iPhone by stopping the connector and starting it again.
- **What the end-to-end run found:** turning off releases the address, then reruns the installer, which rebuilt every image in a source checkout and took over ten minutes. Meanwhile the old server still ran with remote access on, its connector watcher saw the tunnel gone for five minutes and asked for the address again, and the cloud made a new tunnel for a server that had just turned off. The watcher now checks in first and stops when the address was released, removed or suspended. Also: the compose file's fixed container names are now `${CASAMA_CONTAINER_PREFIX:-casama}-…` (and bot computers use the same prefix), so two stacks can share a machine.
- **What the real run changed:** on a home connection about one UDP source port in four to Cloudflare's relay was silently dropped for good, while the others always worked, so a TURN client that started on such a port never got through. `socat` in UDP fork mode could also split one client across two outbound ports. The forwarder is now `infra/turn/udp-forward.pl` (perl-base, already in the image): one outbound socket per client, moved to a new port each second until the relay first answers, then kept. Neko's WebRTC stack doesn't gather relay addresses over TCP, so UDP had to be made reliable rather than avoided. The werift test viewer can't connect relay to relay to Neko through Cloudflare (Chrome can), so it isn't used for the away case.
- **What it earns:** the address, sign-in by QR and push are free on every plan, so nobody is stopped from self-hosting. Live video away from home (which costs us relay traffic) comes with Plus and up, and more servers come with Pro and Max. There is no charge for the address and no separate small plan for now.
- **Accepted risks:** Casama Cloud, if compromised, could re-point or drop addresses and read push text (private notifications removes the second). A process in a bot's computer that reads the streamer's environment could use the relay credentials to send UDP to public hosts until they expire; the relay can't reach the home network, and this exists only on servers with remote access on and a paid plan. Relay credentials already handed out aren't revoked when a server is suspended; they run out within 12 hours. Relay traffic isn't metered per workspace (`docs/COSTS.md` says what to watch).
- **Not built:** bots on a Claude subscription through Claude Code (parked by Oliver; Anthropic's terms allow a person to sign in to the unmodified Claude Code themselves but not a product to offer that sign-in), messages held while the computer sleeps, a chosen address name, backups to Casama's storage, and an alert when the server goes offline.
- **Needs Oliver before it works for real:** buying the zone domain and adding it to Cloudflare, an API token for tunnels and DNS and a TURN key (both into Vaultwarden), the `CONNECT_*` settings on the production server, deploying the site (`/pair` and the app-link file), new app builds, and publishing the `connector` and `turn` images.

## D-297 App Store and Google Play purchases through RevenueCat

- **Decision (2026-11-15, Oliver):** iOS, Android and the Mac App Store build buy through RevenueCat (`purchases_flutter`); web and the direct Mac download keep Dodo checkout. The server stays the only source of entitlements and credits (D-070): it learns about store purchases from RevenueCat, not from the app. The server's own App Store Server API and Play Developer API adapters, Apple's root certificate and their settings (`APP_STORE_*` except `APP_STORE_URL`, `GOOGLE_PLAY_*`) are removed.
- **Who owns a purchase:** the RevenueCat app user id is the workspace id. The app configures RevenueCat as the open workspace and calls `logIn(<workspace>)` before a purchase or a restore, so a RevenueCat customer is a workspace and purchases never need an app-side account token.
- **How the server learns:** RevenueCat's webhook goes to `/hooks/billing/revenuecat`, checked by its Authorization header (`REVENUECAT_WEBHOOK_AUTH`) and, when set, its HMAC signature (`REVENUECAT_WEBHOOK_SIGNING_SECRET`). Each event is stored once in `billing_events` (source `revenuecat`); the body is never trusted: the server re-reads every subscription and purchase of the customers it names (`app_user_id`, `original_app_user_id`, aliases, and both sides of a transfer) with the REST API v2 (`REVENUECAT_PROJECT_ID`, a read-only v2 secret key in `REVENUECAT_API_KEY`). After a purchase or restore the app still calls `POST /v1/orgs/{id}/billing/purchases`, which does the same re-read and checks the reported product is there (409 `purchase_not_found` otherwise).
- **Mapping:** subscriptions keep the store they were bought in (`app_store` for iOS and the Mac App Store, `google_play`), keyed by RevenueCat's subscription id. RevenueCat statuses map to ours (`in_grace_period` → grace, `in_billing_retry` → grace while it still gives access, else on_hold; `will_not_renew` → cancel at period end). A CANCELLATION with `cancel_reason: CUSTOMER_SUPPORT` is a refund: the subscription is found by the event's store transaction id and marked refunded for good, and its month's credits come back out (D-248). Credit packs are RevenueCat one-time purchases, credited once under `revenuecat:<purchase id>` and taken back when their status turns `refunded`. A subscription or pack already linked to another workspace stays there (409 `purchase_in_use`), whatever RevenueCat's transfer setting does. Sandbox purchases (TestFlight, App Review) count like any other.
- **API unchanged:** sources stay `dodo`, `app_store` and `google_play` in the contract, and `providers` lists `app_store` and `google_play` when RevenueCat is configured, because the shipped apps' generated client rejects enum values it doesn't know.
- **RevenueCat project:** "Casama" (`proj864b35e1`) on the Stackwares account, with an App Store app (`ai.casama.app`, iOS and Mac, with the In-App Purchase key HW9SYD2XPL and App Store Connect key CC7KG77GYT), a Play Store app, the six subscriptions and two packs per store, and entitlements `plus`, `pro` and `max`. The public SDK keys are compiled into the app (`CASAMA_REVENUECAT_APPLE_KEY`, `CASAMA_REVENUECAT_GOOGLE_KEY` override them).
- **Cost:** RevenueCat is free to $2,500 of monthly tracked revenue, then 1% of it, counted across the Stackwares account (docs/COSTS.md).
- **Tested:** against a local RevenueCat v2 fake (`apps/server/test/fake-billing.ts`) with paged lists, signed webhooks, refunds, transfers and packs; not yet against a real StoreKit or Play purchase.
- **Set up 2026-11-15:** a read-only v2 key ("Casama server (read-only, D-297)"); the webhook "Casama API (production)" to `https://api.casama.ai/hooks/billing/revenuecat` with an Authorization value and HMAC signing, both environments; restore behaviour "Keep with original App User ID"; the Play service account (`casama-billing@pc-api-…`) on the Play Store app, given Pub/Sub Admin on its Google Cloud project so RevenueCat subscribes to Casama's own topic `casama-play-rtdn` (the other Stackwares apps share `Play-Store-Notifications`); Play notifications now include one-time products; App Store Server Notifications (production and sandbox) point at RevenueCat. The old push subscription `casama-play-rtdn-push` to `/hooks/billing/google_play` is deleted once the server is deployed.

## D-298 Help & support: Casama Help, the support team, and support IDs

- **Decision (2026-11-15, Oliver asked for "the best way" to reach support and find the RevenueCat id, then for an AI support agent with email behind it, safe from abuse):** Settings > Help & support. On Casama Cloud it leads with **Casama Help**, a support assistant; a person is always one tap away; the page shows the support IDs. The Billing page links to it ("Trouble with a purchase?"). The Mac menu's Help opens docs.casama.ai instead of GitHub.
- **Casama Help** runs in the API (`POST /v1/support/chat`), not as a bot in the person's workspace, so it costs them no credits and needs no setup. It calls OpenRouter with Casama's key (`CLOUD_MODEL_UPSTREAM_KEY`, model `SUPPORT_MODEL`, default the cloud chat default) and has read-only tools: `search_docs` (BM25 over the docs split at their headings), `get_account` (account, workspaces, the open workspace's plan, store, renewal, credits and subscriptions, checked with `has_role` so it never sees another workspace), `get_recent_problems` (failed runs in 14 days), `get_plans`, plus `hand_off` (a summary for the support team) and `decline_off_topic`. It never sees chats. The conversation lives in the app until it closes; the server keeps nothing but counters.
- **Up-to-date knowledge:** the server image carries docs-site's markdown, so it always knows its own release, and refreshes hourly from `https://docs.casama.ai/llms-full.txt`, which the docs build now writes (`docs-site/scripts/sync.ts`). A broken or partial file never replaces a good index. The system prompt holds the facts the docs don't (store refunds and cancelling, when to hand off) and forbids inventing features, prices or policies.
- **The support team:** `POST /v1/support/tickets` emails `SUPPORT_INBOX` (support@casama.ai) through the server's email settings with the person's address as reply-to, a reference like `C-7K2M9Q`, their ids, plan and store, app version and platform, and the conversation if they kept "Include my conversation" on; a copy goes to their own confirmed address. The hand-off fills in the topic and summary; the person reviews and sends. Servers older than this or without email: the app opens the mail app with everything filled in, or copies it when there is none.
- **Abuse fences** (the assistant is free and on our key): signed-in, non-guest accounts only; off-topic requests (code, essays, homework, general questions) get a one-line refusal and a strike, and 3 strikes pause it for that person for 24 hours; one request at a time per person and 6 a minute; 60 messages a person a day (`SUPPORT_MESSAGES_PER_DAY`) and 3× that per address (hashed); $0.50 a person a day and `SUPPORT_DAILY_USD` ($10) for everyone, from OpenRouter's reported cost; only the newest 16 messages and 14,000 characters reach the model, answers stop at 900 tokens and 4 tool rounds. Tickets: 5 a person and 12 an address a day, only ever to the support inbox. Counters live in `public.support_usage` (API only), so deploys don't reset them. Hitting a limit shows a notice that leads to a person, never a dead end.
- **Support IDs:** the workspace ID (also the RevenueCat app user id, D-297) and the account ID, each copied with a tap, and "Copy all details" (version, platform, ids, plan, server).


## D-299 Production deploys build on the server; images publish from GitHub

- **Decision (2026-11-15, Oliver asked how to deploy faster, then said "go all 3"):** production deploys no longer go through ghcr. `scripts/deploy-prod.sh` runs from the Mac in one command: it checks the commit is on origin/main and the server checkout fast-forwards to it, waits for running runs to finish (restarting the worker mid-run leaves a run stuck), backs up the database and `.env`, fast-forwards, builds `casama-local/server:<sha>` on the server, points the new `CASAMA_SERVER_IMAGE` at it, runs `compose up -d` (migrate first), recreates Caddy when its Caddyfile changed, waits for the API to be healthy and checks https://api.casama.ai/healthz. `--rollback` puts the API and worker back on the previous image (migrations stay); `--registry-image` goes back to the ghcr image; `--dry-run` changes nothing. Deploys are logged in `/root/casama-deploys.log` on the server; the newest 20 deploy dumps and five local builds are kept.
- **Why:** measured on 2026-11-15, a code-only server build is 1–2 s either way (the dependency layers are cached), but the Mac's uplink made dependency changes and the 1 GB computer images slow (npm at ~28 KiB/s, a desktop upload needing retries), and every deploy chained many hand-run steps. The server has native amd64 and a datacenter connection.
- **`CASAMA_SERVER_IMAGE`** (compose, optional) pins the API and worker to one image; empty keeps `${CASAMA_REGISTRY}/server:${CASAMA_VERSION}`, so self-host installs are unchanged. A later `compose pull` can't swap the local build for an older ghcr `:latest`.
- **Publishing** to ghcr for self-hosters is separate and manual: the "Publish images" workflow (`.github/workflows/publish-images.yml`) builds each architecture on its own native runner (ubuntu-24.04, ubuntu-24.04-arm) with a GitHub Actions layer cache, pushes by digest, merges the tags, retags images left out of `only` and moves the `selfhost` tag, same as `scripts/publish-images.sh`, which stays as the fallback. Images carry `org.opencontainers.image.source`, so each package links to the repository. GITHUB_TOKEN can push only after each package grants the repository write access (Package settings → Manage Actions access); GitHub has no API for that. Supervisor, TURN, computer and the other images still reach the server from ghcr.

## D-300 Building on Casama with AI agents: agent kit, docs MCP, llms.txt, init, plugin-check, TS client

- **Decision (2026-11-15, Oliver asked whether we have a skill or MCP that makes it easy for people building on Casama, and what else would help agents know the project, then "build all"):** coding agents get Casama's knowledge from the real docs and API instead of guessing, with no account needed:
  - **Agent kit** (`agent-kit/`): seven skills (`casama-overview`, `casama-plugin`, `casama-api`, `casama-a2a`, `casama-bot-template`, `casama-gallery`, `casama-contribute`) plus the docs server, packaged once in both formats: Agent Plugins 1.0 (`plugin.json`, `mcp.json` with `streamable-http`, so a Casama bot can install it) and a Claude Code plugin (`.claude-plugin/plugin.json`, `.mcp.json`), listed by the repo-root `.claude-plugin/marketplace.json` (`/plugin marketplace add stackwares/casama`, `/plugin install casama-dev@casama`). Skill descriptions stay under 300 characters, Casama's cut-off.
  - **Docs MCP**: `@casama/mcp` 0.2.0 has `search_docs`, `read_doc`, `list_doc_pages`, `get_api_operation` (operationId, `METHOD /path` with concrete ids, or keywords; schemas shown as compact types) and, over stdio, `check_plugin`. The API serves the docs tools at **`/mcp/docs` with no sign-in** (rate-limited per address, no account tools) and adds them to the signed-in `/mcp`. Hosted, they read the docs shipped in the image (refreshed hourly from `DOCS_URL`) and the server's own `/openapi.json`, so a self-hosted server describes exactly what it runs. The BM25 index moved from the support assistant (D-298) into `@casama/mcp/docs`; `support-docs.ts` imports it, so both answer from the same index.
  - **Docs as markdown**: the docs build writes `llms.txt` (llmstxt.org; sidebar order, first sentence of each page) and a markdown copy of every page at its URL + `.md` (containers as quotes, site links absolute to other `.md` copies), next to `llms-full.txt`, which stays the raw source the support assistant parses. Each page has `<link rel="alternate" type="text/markdown">` and Copy page / Markdown / Open in Claude / Open in ChatGPT buttons. casama.ai gets a short `llms.txt` pointing at the docs.
  - **`casama init plugin|skill|bot|routine`** in the CLI writes a starting point that passes Casama's own checks, each with an `AGENTS.md`; the examples have one too.
  - **`@casama/plugin-check`** is publishable (`npx @casama/plugin-check`): tsc builds it with the two domain files it imports, so the published checker is the code Casama runs.
  - **`@casama/client`**: TypeScript types generated from the OpenAPI document (openapi-typescript, which needs TypeScript 5's compiler API, so it runs from a `typescript-api` alias) over openapi-fetch, plus `ask`, `watchRun` (SSE, poll fallback), `decideApproval`, `cancelRun` and `CasamaError`. Sign-in tokens only: workspace keys (`ksk_`) don't work on `/v1`.
- **Order to ship:** publish `@casama/plugin-check`, `@casama/mcp` 0.2.0 and `@casama/client` to npm, deploy the API (for `/mcp/docs`), then deploy the docs and casama.ai, so no published page points at a command or address that isn't live yet.

## D-306 Suggestions: Do it on each row, never used up by a run that can't start

- **Decision (2026-11-15, Oliver tapped a suggestion that had been accepted but whose run failed at once on the daily limit, and asked for the best experience):** in a card of several suggestions (D-257) each open row has its own **Do it**; tapping the row still opens the whole suggestion with Do it and Not now. Answered rows say what happened: "Started 12:50" (a tap opens its topic), "Put away" or "Expired"; once all are answered the card folds into one line that keeps a link to each topic started.
- **Accepting checks first:** `POST /v1/suggestions/{id}/accept` creates the topic and run, then runs the worker's own start checks without starting anything (`startVerdict` in `packages/agent/src/run.ts`: a live bot and workspace, room in the plan, credits and daily limits; the model is left to run start, where Casama Cloud picks it). If the run couldn't start, the topic is taken back and the suggestion stays pending: 402 for limits a plan fixes (the app opens the plans page), 409 otherwise.
- **The topic is saved** on the suggestion (`suggestions.conversation_id`). The app reads where its suggestions stand straight from `public.suggestions` (the person's own rows, RLS).
- **A chat whose last message is yours and whose run failed** says why when it opens, with the fix and Try Again; Try Again reruns that message through the edit route, so a suggestion's hidden action part goes with it.

## D-301 Reporting and blocking inside the app

- **Decision (2026-11-15, Oliver: "do 1-5" of docs/GAPS-PLAN-2026-11.md):** the App Store (Guideline 1.2) and Google Play (user-generated content, and AI-generated content) require a way to report content, a way to block people, and someone who acts. Public pages and chats already have their report form and auto-hide (D-281, D-282). This adds reporting from inside the app.
- **What can be reported** (`POST /v1/reports`): a bot's reply (the reply menu: long-press, right-click or text selection), a bot shared with the team (its profile), a gallery item (it opened a GitHub issue before), a person (Settings > People), a workspace. The server checks the reporter can see the thing and keeps a short copy (`content_reports.snapshot`), so an edit or delete doesn't hide it. One open report per person and thing; 20 reports a day per person.
- **Who acts:** each report is emailed to `ABUSE_INBOX` (abuse@casama.ai) and listed in **Admin console > Reports**, next to the reported public links (whose API had no screen until now). Dealing with a report closes every open report about the same thing, and can suspend the workspace (D-094); take-down for public links is the D-281 one.
- **Blocking** (`/v1/me/blocks`): tapping a person in Settings > People offers Block or Report (reporting a person blocks them too). A blocked person's invites to the blocker are neither stored nor sent, their pending ones are deleted, and the inviter sees what they'd see for any invite, so the block isn't revealed. Settings > Privacy > Blocked people lists blocks and undoes them. Chats never show other people's messages (group chats are a person and their bots), so there is nothing to hide there.

## D-302 Account emails: billing changes and a welcome series

- **Decision (2026-11-15, same request):** billing changes reached PostHog but never the customer. Now `BillingService.applySnapshot` queues an email for `trial_started`, `started`/`trial_converted`/`plan_changed` ("Welcome to Plus"), `grace` (payment failed), renewal turned off (`cancel_at_period_end` turning true), `expired` and `refunded`. An hourly sweep adds trials ending in 3 days, payments still failing after 3 days, yearly web plans renewing in 7 days, credits low (weekly at most) and credits gone (once until the next top-up). `renewed` sends nothing: the stores and Dodo send receipts.
- **Welcome series** (tips class): welcome after sign-up, a first-bot nudge on day 2 if they haven't made a bot or sent a message, three ideas on day 7 if active, and "your bots are still here" after 14 quiet days (monthly at most). Only people who signed up in the last 9 days get the series, so turning it on never emails everyone. Tips emails go out only when `EMAIL_POSTAL_ADDRESS` is set (US CAN-SPAM), carry a one-click unsubscribe (`List-Unsubscribe` and `List-Unsubscribe-Post`, RFC 8058) to `/v1/email/unsubscribe/<signed token>`, and stop when `profiles.email_tips` is off (Settings > Tips and news by email). A visit to the link only shows a button; the POST unsubscribes, so mail scanners can't.
- **How it's sent:** rows go to `public.email_outbox` with a unique dedupe key (subscription, change, period), so retried webhooks and sweeps never send twice; the worker sends every minute through the server's email settings (Zoho SMTP in production) with up to five attempts. Billing emails go to the workspace's owners and admins with confirmed addresses, never plain members. `ACCOUNT_EMAILS=false` turns it off. Move to Resend when volume passes Zoho's daily cap (docs/COSTS.md).

## D-303 Support ticket log

- **Decision (2026-11-15, same request):** each message sent from Help & support (D-298) is recorded in `support_tickets` (reference, person, workspace, topic, first line, open or closed), never the message itself, which stays in email. Casama Help gets a `get_my_tickets` tool so "did you get my message?" has an answer, and **Admin console > Support** lists tickets and closes or reopens them. A ticket whose email fails is removed again. A helpdesk can wait until there are about 20 a day.

## D-304 Public status page at status.casama.ai

- **Decision (2026-11-15, same request):** the uptime Worker (D-252) also serves `status.casama.ai`, so it stays up when our server is down: the current state of API, Web app, Sign-in (Auth's health through the public anon key) and Docs, 90 days of daily uptime bars, and an incident note set with `scripts/status-incident.sh` (production infrastructure: Oliver's yes each time). A service shows down only after two failed checks in a row, like the alert. `/status.json` has the same data without URLs or error text. KV writes stay in the free tier: a check's state is written only when it changes, plus one history record per run. The test email now needs `TEST_TOKEN`, and the Worker no longer runs checks on request. The app's "Can't reach your Casama server" bar gets a Status button for Casama Cloud.

## D-305 The store's rating prompt

- **Decision (2026-11-15, same request):** `in_app_review` asks after a good moment: a purchase (right away; the store shows it over the celebration), or the 10th and every 40th reply the person asked for. Only when the app was used on 5 different days, was first opened at least 7 days ago, no error message showed this session, it hasn't asked on this device for 120 days, and the remote flag `review_prompt` isn't off. iOS, Android and the Mac App Store build only. `review_prompt_shown` goes to analytics; the stores don't say whether someone rated.

## D-307 Usage on replies

- **Decision (2026-11-15, Oliver: power users should see how much each task uses; "you decide"):** the line goes on each **reply**, meaning one run and the subruns it started, under the last message of that run that shows. Per tool call is too small to act on, and a total for the whole chat hides which request was expensive. It is behind **Settings > Show usage on replies**, off by default and saved on the device (`chat.showUsage`, like Show the bot's steps), so most people never see prices in chat.
- **What it shows:** what came out of credits, in dollars like Usage and Billing (1 credit = $1), then "… on your keys" for spend on the person's own keys, "On your ChatGPT plan", tokens and duration. While the run is going, the line counts up from the chat's `usage` events. Tapping it opens a breakdown (each kind and model, own key or credits, steps, helper runs) and **Open the run**, which goes to the run timeline.
- **API:** `GET /v1/runs/{id}/usage` adds up `usage_ledger` over the run and its subruns (`parent_run_id`, recursive), splits `charged_usd` (billable) from `cost_usd` (everything), and counts `tool.started` events. Access is the same as `GET /v1/runs/{id}`, which already returns `cost_usd` to anyone who can see the run, so hiding the cost of other people's runs from members would hide nothing. The app keeps a finished run's usage and asks again for a run still going.

## D-308 Casama Help looks up usage, credits, connections, bots and invites

- **Decision (2026-11-15):** Casama Help (D-298) gets five more read-only lookups (`apps/server/src/api/routes/support-tools.ts`): `get_usage` (this month's spend by bot and kind, today's spend against the daily cap, computer hours, bots, computers and seats against the plan's limits, credits, and runs the limits stopped in the last 7 days), `get_credit_history` (the last 20 credit entries and credits about to expire), `get_connections` (connected apps, chat channels and model keys with status and last error), `get_bot` (one bot's settings, routines, apps, channels and last runs with full errors) and `get_invites` (invites and join requests; owners and admins also see the open workspace's pending ones). `get_account` adds the profile (name, language, time zone, sign-in methods), the plan's limits and extra seats.
- **Who sees what:** the same as the app. Members already see the plan, credits, usage and credit history on the Billing and Usage pages, so the assistant doesn't hide them from members; restricting only the assistant would protect nothing. Bot names, runs, channels and errors are read in the person's own database session with `can_access_bot`, so someone else's private bot shows up only as "a private bot" in spend totals. Other people's personal model keys stay out. No lookup returns secrets, tokens or connection settings. `get_recent_problems` now follows the same rule.
- **Tool calls per round:** up to 6, and calls beyond that are dropped from the assistant message too, so every call the model sees has a reply. Before, the message kept every call but only the first 4 were answered, which OpenAI-style APIs reject.

## D-309 Guided setup of a server on this computer

- **Decision (2026-11-15, Oliver: "I want the easiest UI/UX to get started with our Mac desktop app, self-hosting, running the local server and getting their phone connected"; he chose guiding people to Docker Desktop over shipping a container runtime inside the app, and building it now):** the desktop app's sign-in screen offers **Run on This Mac** (**Run on This Computer** on Linux) next to the main button, no longer under "More sign-in options". It opens `/setup`, one page with five steps: Docker, Server, Account, AI model, Phone. It replaces the "Run Casama on This Computer" sheet (D-147, D-216), which stopped at a running server and left the account, the model key and Casama Link (D-296) for the person to find.
- **Docker:** checked when the page opens and every 3 seconds (`features/selfhost/docker_check.dart`), telling apart not installed, installed but not running, running but not allowed (Linux, not in the `docker` group) and no Compose v2. On a Mac: **Download Docker Desktop** opens the installer for the chip (`desktop.docker.com/mac/main/arm64|amd64/Docker.dmg`), and an installed but closed Docker is opened for the person (`open -a Docker`). On Linux: Docker's install guide, and the fixing command to copy (`sudo systemctl start docker`, `sudo usermod -aG docker $USER`). Less than 12 GB of free disk is said. The app never installs Docker itself: that needs an administrator password and accepting Docker's terms for the person.
- **Server:** one **Start** click (none when the person had to wait for Docker: the page said it would continue). Five plain parts replace the installer's log, which is behind **Show Details**. The pulls are quiet (`--quiet`), so there is a real bar only for the bundle download; no invented percentages.
- **Account:** name, email and password on the page. A local server confirms at once (`EMAIL_AUTOCONFIRM`), so it signs in, saves the name, and makes the first space and bot the way `/welcome` does. "I already have an account here" signs in; a server that takes no new accounts offers only that.
- **AI model:** the same form as Settings → Model keys (ChatGPT plan sign-in, D-091, or a key). Skippable.
- **Phone:** turns on Casama Link with the same switch as Settings → Casama Link, shows the code to scan, renews it when it runs out, and says **Phone connected** when the "New sign-in" notification the scan makes arrives (no new server route). Keep-awake is offered here. Skippable.
- **Picking up where it stopped:** connecting to the new server rebuilds the whole app, and people quit. So the setup keeps only three things on disk (`GuidedSetup`: under way, steps skipped, card closed), and the step shown comes from what is true: the app is on this computer's server, someone is signed in, a space exists, a key exists. While it is under way, launches open `/setup` again and the name and notification pages wait. Closing it ends it.
- **Afterwards:** on a server this computer runs, a **Finish setting up** card on the home page (sidebar, and the Chats page on narrow windows) lists what is left (a model, the phone) and reopens the setup; it can be closed for good.
- **Its own names:** a server the app installs from now on uses the Compose project and container prefix `casama-app` (written to its settings file, kept in `local-server.json`), so it never takes over or collides with another Casama stack on the same computer (one installed by hand with `install.sh`, which is project `casama`, or a development stack). Servers the app installed earlier keep their names.
- **Not done, on purpose:** Windows (the installer needs bash and OpenSSL); a container runtime inside the app so nobody installs Docker (weeks of work: a Linux VM to ship, update and test computers on); showing download progress for the images.

## D-310 A Map card in bots' replies

- **Decision (2026-11-15, Oliver: "I asked it to show me a map ui view but it didn't. An a2ui flutter map widget I requested"; he chose flutter_map with MapTiler tiles):** the A2UI catalog the apps render (D-086) gets one component of Casama's own, **Map**: `{center?: {lat, lng}, zoom?, markers?: [{lat, lng, label?}], path?: [{lat, lng}], height?}`. Without a center it fits the markers and the path. Before, a bot asked for a map had no way to show one: it tried the computer's browser, then a page.
- **In the app** (`features/chat/widgets/bot_ui_map.dart`): a native map (flutter_map), one finger scrolls the chat past it, two fingers move and zoom it, and a corner button opens it full screen. Labelled pins and an optional route line in the theme's color; dark tiles in dark mode. MapTiler and OpenStreetMap attribution on the map, as both require. A Map with no valid place draws nothing.
- **Tiles:** MapTiler's streets map, with the key built into the apps (`CASAMA_MAPTILER_KEY`, from the gitignored `client/config/maps.json` that every packaging script and `scripts/build-web.sh` read on official builds, like `telemetry.json`). Builds without a key (self-built, development) use OpenStreetMap's own tile server, which allows light use with attribution and a real user agent. Cost in `docs/COSTS.md`.
- **For bots** (`ui.show`, `packages/agent/src/tools/ui.ts`): Map is in the component list and the description, which tells the bot to show a Map for places, maps and routes instead of opening a browser or building a page. Coordinates are checked (numbers, in range, something to show) so a bad call comes back with what to fix. A map needs no button, so no Send or Skip is added.
- **Older apps** don't know the component and leave it out of the card (the A2UI renderer skips unknown types), so a bot should say a line about the map, not only show it.
- **Not done:** geocoding (the bot uses coordinates it knows or looks up), search on the map, live location, turn-by-turn routes.


## D-311 The daily limit is on screen, and says its amount

- **Decision (2026-11-16, Oliver: "it cannot access almost anything because it says the workspace usage limit is reached but I see in my usage that only 20% is used"):** the plan's daily cap on the server's keys (`cloud_daily_usd`, D-244/D-248) stops runs whatever credits are left, but the app only showed the month's credits. A Free workspace with most of its credits left was told "limit reached" with nothing on screen to explain it.
- **API:** `GET /v1/orgs/{id}/billing` returns `daily: {used_usd, cap_usd, resets_at}`: today's (UTC) billable spend except computer and live-view seconds, the same sum run admission checks, against the plan's cap. Null on servers without billing or without the shared model key (`CLOUD_MODEL_UPSTREAM_KEY`), and on unlimited plans.
- **App:** under the credits meter (Usage, and the Billing plan card), **Today's limit** with "$0.10 of $0.25", a thin bar (amber at 80%, red when reached) and when it resets. When reached, it says bots are paused and how to get more (upgrade or own key).
- **Message:** a run stopped by the cap now names the amount ("This workspace used today's $0.25 limit on Casama's models…") and points to Billing.
- **Not changed: sandbox purchases.** Store sandbox purchases (TestFlight, App Review) keep counting on production like any other (`billing.test.ts`, "a sandbox purchase … counts like any other"). App Review buys in sandbox against the production server, so refusing them would fail review. Sandbox subscriptions renew every few minutes and expire after about 12 renewals, so a tester's plan drops back to Free within hours; that is what happened here.

## D-312 Notifications are plain text, and the morning brief comes once

- **Decision (2026-11-16, Oliver showed a morning brief push full of `**` and asked "should we be using markdown on notifications?", then "do everything you recommend"):** phones draw a push's title and body as plain text. Production also showed two briefs every morning that contradicted each other, the same suggestions offered day after day, and today's suggestions held by yesterday's pushes.
- **Plain text:** `notify()` runs every title and body through `pushText` (`packages/agent/src/notifications.ts`): markdown removed (links keep their words), a heading line that repeats the title dropped, lines joined, cut at a word with "…" at 240 characters. The inbox row gets the same text.
- **One brief per bot:** `routines.create` refuses a daily routine named like a brief when the bot has the check-ins brief (`brief_exists`); a weekly one is fine. Oliver's prod bot had made a second "Morning brief" routine on 14 Nov.
- **Brief wording:** briefs set up with the original text get today's `BRIEF_INSTRUCTIONS` (`briefInstructions`, like scans already did), so prompt changes reach them; a brief someone rewrote keeps its text. The new wording: only today and what's ahead (an all-day event's end date is exclusive), say each thing once, leave out Casama's own plan and billing emails, don't guess at causes, open with one plain sentence that doubles as the notification, and reply "Quiet day…" when there is nothing.
- **Brief push:** a quiet brief posts in the chat without a push. The default bot's name isn't repeated in the title ("Morning brief", not "Casama: Morning brief"). The push carries a tag per bot (Android tag, iOS `apns-collapse-id`), so a second brief replaces the first on the phone.
- **Suggestions in a brief:** the brief gets the "Already suggested or dismissed" list scans get. Its suggestions are cards under it and don't push on their own (urgent and timed ones still do); their "why" says morning brief, not check-in scan.
- **Daily caps:** the 5 pushes per bot count the person's calendar day in their timezone, not the last 24 hours, and the brief doesn't count. The check-in spending cap also resets at the person's midnight, not UTC's.
- **Skills:** check-in runs (brief and scan) are never proposed as a skill; they repeat by design.

## D-315 Gallery v2: finding, trusting, updating and contributing

- **Decision (2026-11-16, Oliver: "Do all of that now", after we went through ways to improve the gallery):** the gallery grows from a catalog into a place people find things, judge them, keep them up to date and add to. The full shapes are in `docs/GALLERY-V2.md`; this entry records the choices.
- **Finding:** rows for Picks (each with a one-line `pick` note), New (`added` within 30 days; hidden while more than half the catalog counts as new, so a backfilled catalog doesn't badge everything), Trending this week, Most used, Works with what you have (from connected apps), Starter sets (new `sets/` kind, `sets.json`) and In season (`season`). One search across every kind with tags and a small synonym map; an empty search offers **Request this** (a requests board with votes) and **Ask Casama to make it**. Bots get `gallery.search`, `gallery.suggest` (one card per reply, never twice per conversation) and `gallery.draft_skill`, plus a no-model hint when someone asks for the same thing on three different days. The web gallery gets a static page and share image per item at `/i/<type>/<id>/`, author pages, a sitemap and an Add to Casama badge.
- **Usage is counted in aggregate only:** `gallery_installs` keeps an HMAC of user and item, never a user or workspace id; `gallery_item_stats` is rolled up hourly. Numbers show only from 10 people (run success from 20 runs), so nothing reads "1 install". Ranking uses unique installers, last-7-day installers, people still using it after 14 days and the share of runs that finish, not raw installs. `GET /v1/gallery/stats` is public and cached; self-hosted servers read Casama's (`GALLERY_STATS_URL`) or turn it off. Telemetry stays off (D-074, D-206): this is server-side counting of installs the server already performs, plus one anonymous call when a look is applied.
- **Trust:** items say what they can reach (`access`: reads, writes, runs code, needs a computer, credit level; the checker forces runs-code for skills with scripts), show example prompts with **Try it**, who made them, version, changelog and a Reviewed badge when the skill's `tests.json` passed `scripts/gallery-skill-tests.mts` (opt-in, needs a model key, never in `pnpm test`).
- **Signed catalog:** the checker writes `manifest.json` (SHA-256 of every catalog file) and CI signs it with Ed25519 (`gallery/sign.mjs`, key in the catalog repo's `GALLERY_SIGNING_KEY` secret and Vaultwarden). Servers verify it against the built-in public key before trusting any file; `GALLERY_SIGNATURE=optional` until the first signed deploy, after which a present-but-bad signature makes the gallery unavailable rather than trusted. The CLI's `casama gallery mirror` verifies the same way for offline servers.
- **Compatibility:** every new field is optional for readers, new kinds go in new files, and `document` keeps defaults filled in so shipped servers keep working. Install-time questions (`inputs`, each with a `default`) fill `{{key}}` placeholders from a separate `template` field. `min_app` and `min_server` hide items from versions that can't use them, beside the existing per-feature `requires`.
- **Installed and updates:** `gallery_links` records what each workspace installed at which version; the Installed tab offers Update, asks first when access grew or the change is marked breaking (409 `access_changed`), offers Remove, and points retired items to `replaced_by`. Looks are tracked on the device.
- **Workspaces:** admins choose Open, Ask first or Only allowed, with allow and block lists (`/v1/orgs/{id}/gallery-policy`). Gallery approvals are their own table, not run approvals, because run approvals need a bot and a run and their API type can't loosen without breaking shipped apps. Old install routes answer 403 `approval_pending` so shipped apps show a message; the new install route answers 202.
- **Contributing without GitHub:** `POST /v1/gallery/submissions` checks the item with the same domain checker and opens a pull request on the catalog repo (`GALLERY_SUBMIT_TOKEN`; off when unset). Remixes credit the original (`remix_of`). Authors see their items' numbers. Rewards: credits when an item reaches 50, 250 and 1,000 people still using it, once each, through the existing credit grant (`GALLERY_REWARDS`, default $10, $25 and $75 since 1 credit = $1: the first tier is about a month of Plus at cost, and the total of $110 per item costs about $80 in model spend; listed in `docs/COSTS.md`).
- **Other surfaces:** opt-in monthly "New for you" email (`gallery_digest`), first-run "Picks for you" after About you, a nightly health check that files admin reports (unreachable apps, dead links, reported items), extra catalogs via `GALLERY_SOURCES` (ids namespaced `<name>:<id>`), `gallery_search` in MCP, the gallery files in `llms.txt`, and `casama init --from-gallery`.
- **Publishing:** the monorepo's `gallery/` is the source and gallery.casama.ai is published from it with `scripts/deploy-web.sh`, which signs the manifest first and stops if it can't (key from `GALLERY_SIGNING_KEY`, `~/.config/casama/gallery-signing-key.pem` or Vaultwarden through `bw`). `scripts/sync-gallery.sh` copies `gallery/` to the public `stackwares/casama-gallery` and refuses while that repo has merged changes the monorepo lacks (`--pull` brings them in). The public repo's Actions check every pull request (contributors and in-app submissions) and sign on merge; they publish only if a `CLOUDFLARE_API_TOKEN` secret is added, which is left off so one place publishes.
- **Not done:** star ratings and reviews (moderation cost, easy to fake, empty while usage is small). Paid items.

## D-316 The web app's large files are served from R2

- **Problem:** Cloudflare static assets take files up to 25 MiB each, with no paid way past it. The Wasm build's `main.dart.wasm` reached 46 MB in a local build (14 MB live), and the dart2js fallback `main.dart.js` was already past the limit, so it was left out with a hand-made `.assetsignore` and browsers without WasmGC stayed on the launch splash.
- **Decision (Oliver, 2026-11-16: "let's do that as the default from now on"):** app.casama.ai stays on Cloudflare. `client/wrangler.jsonc` now has a small Worker (`client/cloudflare/worker.js`) with the R2 bucket `casama-app-large`. `scripts/deploy-app-web.sh` (the only way to publish the web app; it does not build) runs `client/cloudflare/prepare.mjs`, which sends every build file of 25 MiB or more to R2 under a content-named key (`<sha256 prefix>/<path>`) with Brotli 11 and gzip 9 copies, writes `.assetsignore` (those files and every `*.map`) and the path list the Worker bundles, uploads, then runs `wrangler deploy` and checks each large file live. Everything else is still free static assets.
- **Serving:** only paths in `assets.run_worker_first` (`/main.dart.wasm`, `/main.dart.js`) run the Worker, so the rest of the app costs no Worker requests; prepare refuses a large file that isn't listed. The Worker picks the Brotli, gzip or plain copy from `Accept-Encoding` (46 MB plain is 8.4 MB as Brotli), sends the `_headers` security headers itself, answers `If-None-Match` with 304 (ETag is the SHA-256), and keeps each object in the data centre's cache, since keys never change content. A small file on those paths goes to static assets as before.
- **Not chosen:** our VPS (Flutter builds are heavy there, app releases would ride server deploys, and it would add load to the one machine; Cloudflare would cache in front of it anyway); another host such as Firebase Hosting or Netlify (another vendor and bill for one file); trimming the build under 25 MiB (not reachable with compiler flags, and it would come back).
- **Wasm stays (D-196):** skwasm renders faster and on several threads; the dart2js build ships beside it for browsers without WasmGC and is now actually published when large. Source maps never go online; `scripts/upload-symbols.sh` sends them to error tracking.
- **Costs:** in `docs/COSTS.md`. Self-hosted web (`client/Dockerfile.web`, Caddy) has no file limit and is unchanged.

## D-317 casama.link has its own page

- **Problem:** every Casama Link address is `<label>.casama.link`, but the bare domain had nothing on it (it didn't even resolve). People who strip an address down to `casama.link` got an error, abuse desks and Safe Browsing reviewers found no owner or abuse contact for a domain full of other people's servers, and the Public Suffix List request (LINK-PLAN §11 "Later") is stronger when the domain says whose it is.
- **Decision (Oliver, 2026-11-16: "let's build in 1 go, the best idea for this"):** one page at `casama.link` (`link-site/`, its own Worker `casama-link-site`; `www` redirects to the bare domain). Not a second marketing site: casama.ai stays the product site. The page says what an address is, shows the path (phone → Cloudflare → your computer, Casama Cloud off to the side), what it costs, who can sign up, what Casama Cloud keeps and never gets (taken from `docs-site/self-hosting/remote-access.md`), and takes reports.
- **Address check:** a box that reads a pasted address and says whether it has the shape Casama Link gives out (`newLabel()`'s alphabets, `-p` for bots' pages). It runs in the page and never contacts the server or Casama: a live lookup would let anyone test which addresses exist, which the random labels are there to prevent. Lookalikes (`paypal-login.casama.link`, `x.casama.link@evil.com`) are called out.
- **Reports:** a form that opens the visitor's email app to `security@casama.ai` (the address the docs already give) with the address, the kind and the details filled in; nothing is sent or stored by the page, so there is no new endpoint to abuse. `casama.link/#report=<address>` fills the form. The instance owner takes an address down from the admin side (`LinkServers.suspendServer`). `/.well-known/security.txt` points to the same inbox.
- **Rules for the Worker:** it answers only `casama.link` and `www.casama.link`, never `*.casama.link`, so it is never in front of anyone's server. It sets no cookies: until the zone is on the Public Suffix List a `.casama.link` cookie would reach every address. Strict CSP, `no-referrer`, HSTS with subdomains (every address is https through Cloudflare already).
- **Not chosen:** a Worker on `*.casama.link` for a friendly "this server is offline" page instead of Cloudflare's 1033 (it would sit in front of every request to every server and cost Worker requests; the app already says **Your server is offline**); an abuse API with a form (an open endpoint to defend, for a few reports a month).
- **Publishing:** `scripts/deploy-link-web.sh --dry-run`, then `--yes` (production, ask first). Needs the zone on the Stackwares Cloudflare account. Local preview: `scripts/serve-web.py` serves it on :8734. The brand mascot files come from `scripts/web-brand-lottie.py` like the other sites.

## D-318 App email goes through ZeptoMail; Zoho Mail keeps people's inboxes

- **Problem:** sign-in links, invites, account emails (D-302) and support replies went out over Zoho Mail SMTP as hello@casama.ai. Zoho Mail is for people, not apps: it has a daily sending cap per mailbox and can suspend automated sending, which would stop sign-in and take the team's inbox down with it. One sender reputation covered everything, and there were no delivery or bounce logs.
- **Decision (Oliver, 2026-11-16: "let's do all of that now"):** app mail goes through ZeptoMail (Zoho's transactional service, now inside Zoho CPaaS) from `hello@notify.casama.ai`. Org "Stackwares" (946963344) on the Zoho user that signs in with stackwares@gmail.com, agent `casama`, domain `notify.casama.ai` (DKIM `1518530._domainkey.notify` and the return path `bounce-zem.notify` → `cluster89.zeptomail.com` in Cloudflare DNS; the zone's `p=none` DMARC covers it). The code didn't change: it is plain SMTP (`smtp.zeptomail.com:587`, user `emailapikey`), so Auth, the API and worker, and alertmanager all pick it up from `SMTP_*`/`EMAIL_FROM`. The key is in Vaultwarden.
- **Why ZeptoMail:** cheapest of the simple services ($2.50 per 10k, no monthly fee, 10k free to start), a vendor we already use, SMTP so switching costs only credentials. Not chosen: Resend (about 8× the price at our volume; better developer tools and broadcasts), Amazon SES (cheapest at scale but more setup: sandbox exit, SNS for bounces; the next step if volume grows), Postmark (expensive), Cloudflare Email Service (beta), our own mail server (Contabo IP ranges are often blocklisted).
- **Rules:** ZeptoMail is transactional only, so marketing or newsletters go through another provider on another subdomain, never this agent. The subdomain keeps app mail's reputation apart from the team's mail on `casama.ai`. Replies reach a person: Cloudflare Email Routing is on for `notify.casama.ai` only (its own MX; `casama.ai` keeps Zoho's MX), forwarding `hello@` and `status@` to the hello@casama.ai Zoho inbox (a verified Email Routing destination since 2026-11-16). The subdomain's SPF lists ZeptoMail and Cloudflare. Rule changes take a few minutes to apply.
- **Also moved:** the `casama-uptime` Worker's alerts (secrets `SMTP_*`, port 465, `MAIL_FROM` status@notify.casama.ai) and the local dev `.env` (Auth there picks it up on the next `supabase start`). Self-hosters keep setting their own SMTP.
- **Rollout note:** recreating `auth` on its own left Kong pointing at the old container's address, so `auth.casama.ai` answered 502 for about two minutes until Kong was restarted. After recreating `auth`, restart `kong` too.

## D-319 Every Casama web page uses casama.link's look

- **Problem:** casama.ai morphed its colours, fonts and hero pattern through the app's eight looks (2026-11-13 redesign), with a canvas field, a look picker and a pause chip. It was busy, heavy (about 900 lines of script) and unlike the docs, gallery, status and casama.link pages, which each had their own take on the brand. The status page used system fonts and Georgia; the invite page on casama.ai was green.
- **Decision (Oliver, 2026-11-16: "I like the Link website design more, the buttons, fonts, colors. I want it applied for all our web pages"):** `link-site/link.css` is the reference for casama.ai (with privacy, terms, pair and the invite page), docs.casama.ai, gallery.casama.ai and status.casama.ai. Plain white or dark grey (`#1c1c1e`), Casama's purple (`#7a3fa8` / `#d9b6f7`) for text and buttons only, `--card` panels with a 1px line and 22px corners, pill buttons (52px, 40px small) in bold Google Sans, Google Sans for text and the hero h1, Libre Baskerville for the wordmark and h2s, JetBrains Mono for code and eyebrows. Light or dark follows the system; the site's theme toggle is gone.
- **casama.ai:** same sections and copy, drawn as Link-style cards: hero with the example chat (Approve/Deny still works), teammates, features, a four-step "How a task goes", apps, safety and the comparison, four plan cards plus Self-hosted, questions, install command. Removed: the looks morph, canvas field, look picker and "Make it yours", the run slider, plan tabs, scroll reveals, `boot.js`. The look fonts (Lato, Figtree, Fraunces) stay in `site/assets/fonts` because gallery previews use them.
- **Status page:** the uptime Worker has no static files, so it loads Google Sans and Libre Baskerville from `https://casama.ai/assets/fonts/`, which now sends `Access-Control-Allow-Origin: *` (`site/_headers`).
- **Not chosen:** one shared stylesheet served to every site (four separate Workers deploy on their own; a copy of the tokens per site keeps each deploy independent). Keep the tokens in step with `link-site/link.css` when changing any of them.

## D-320 Coding agents and bots on your own computer, after a live test

- **Problem:** Claude drove the desktop app with agent-desktop (2026-11-16) and had a bot build an app with Claude Code and Codex on Oliver's Mac, and drive T3 Code through a local MCP server. Several things failed in ways the tests (fake computers) never showed:
  - cancelling a run left the command working: `ComputerdClient.exec` only hung up its stream, computerd keeps a command until it exits, and nothing called `/exec/{id}/kill`. `shell.exec` didn't get a cancel signal at all.
  - Codex failed at once: codex-cli 0.169 removed `--full-auto`.
  - Claude Code on the user's computer (`acceptEdits`) could edit but not run tests or git.
  - `branch` ran `git checkout -B`, which resets an existing branch to the current commit.
  - "Changed files" came from `git diff --stat HEAD`, so commits and new files didn't show.
  - after a network blip the desktop app sat on a dead WebSocket for good (no pings either side): it showed On, bots saw the computer as offline.
  - the app redialled up to 30 s apart while the worker gave up after 8 s, so any API restart failed tool calls.
  - the tunnel cut every request at 15 minutes, though coding agents may run 120.
  - the message box's semantics node was the parent of the whole chat: its field merged into the empty node of the page's `CallbackShortcuts` (Cmd+F), and macOS gives a text field no children, so VoiceOver saw only the box.
  - Codex's summary was the tail of its output, which is tool logs and hook lines.
  - while fixing this, the API's shutdown hung under `node --watch`: `server.close()` waits for every connection, and a desktop app's WebSocket never ends, so the API stayed down until killed.
- **Decision (Oliver: "yes fix all"):**
  - cancel: tools get `ToolContext.signal`, aborted when the run is cancelled (polled while the tool runs). `shell.exec` and `coding.delegate` pass it on, and `ComputerdClient.exec` kills the command by id on abort or when the reader stops early. The desktop app also kills the command when the API sends `cancel`, and when bots are turned off.
  - Codex runs with `--sandbox workspace-write` on the user's computer and `--dangerously-bypass-approvals-and-sandbox` in the bot's sandbox, and writes its final message with `-o`, printed after a marker that `summarizeAgentOutput` reads.
  - Claude Code on the user's computer runs with `--settings '{"sandbox":{"enabled":true,"autoAllowBashIfSandboxed":true}}'`: commands run without a prompt and writes stay in the project (checked on macOS: `/tmp` refused, the folder allowed).
  - `branch`: `git checkout <b> || git checkout -b <b>`. Changes are diffed against the commit the agent started from, and new uncommitted files are listed.
  - the app pings every 20 s and redials at most 5 s apart; the API pings every 25 s and drops a device that misses a pong; the worker waits 15 s for a reconnecting device. `/exec` through the tunnel gets the long (2 h 5 min) limit, like local MCP. On shutdown the API closes device sockets with 1012 (apps redial at once) and gives `server.close()` 5 s.
  - computerd's refusal names the app's switch ("Run commands", not "shell"). Approval summaries and the inbox show a connection tool as `t3_show_thread (t3code)`. `tools.load` takes a connection tool's own name when only one tool ends with it.
  - the composer's field is `Semantics(container: true)` (`composer_semantics_test` fails without it); the Bots Allowed rows exclude the avatar's image label, so they read as named checkboxes, not images. A failed background chat refresh no longer throws an unhandled error.
- **Checked live after the fix:** Codex added a feature on an existing branch without resetting it and committed (13/13 tests); Claude Code ran with its sandbox; cancelling stopped it within 1 s; the app redialled within about 5 s of an API restart; the chat, header and buttons reach macOS accessibility.
- **Retest the same day:** Codex on the user's computer could edit and test but never commit: `workspace-write` keeps `.git` read-only even when it is listed in `sandbox_workspace_write.writable_roots` (reproduced with `codex sandbox -P :workspace`). Decision (Oliver: "Casama commits after"): with a `branch`, `coding.delegate` tells Codex not to commit, records `git status` before it starts, and when it finishes cleanly commits only the paths it changed (`git add -A -- <paths> && git commit -- <paths>`, subject from its summary, "Made by Codex through Casama."). Paths changed before it started stay out and are named in the result. Running Codex unsandboxed was the other choice. Also: the desktop app now registers its local MCP servers again when its device id changes (5202ec22).
- **Not changed:** icon buttons' tooltips don't reach macOS accessibility as names (maybe as help text). Local MCP tools without MCP annotations stay medium risk (the server should set `readOnlyHint`). A bot saved a wrong conclusion to memory after a failed check; left for memory hygiene work. The dev worker under `node --watch` stays dead after a crash (a database restart); production's container restarts it.

## D-321 Pi as a coding agent on your own computer

- **Problem:** Oliver uses Pi (`pi`) too, and `coding.delegate` knew only Claude Code, Codex and Cursor.
- **Decision (Oliver: "just support pi agent"):**
  - `pi` runs `pi -p --no-session <task>` (pi 1.5.2): print mode prints only the final answer, and `--no-session` keeps bot runs out of the user's session list. Pi has no sandbox or permission prompts, so it runs commands with the user's access, like Cursor with `--force`; the guide says so.
  - Only on the user's computer, with their own sign-ins: which provider key Pi would need on the bot's computer depends on their setup, so `bot_computer` answers `local_only`.
  - The desktop app looks for `pi` with the other agents and labels it Pi.
- **Not done:** Antigravity's CLI (`agy`) was tried first and dropped. Headless, it denies every command it would ask about, and with commands allowed its `--sandbox` didn't keep a write to the home folder out (agy 1.4.10).

## D-322 Video, audio and checks in bots' cards; map tiles stay on OpenStreetMap

- **Problem:** the app's A2UI renderer (`a2ui_flutter` basic catalog) already plays Video and AudioPlayer and evaluates `checks`, but `ui.show` didn't offer them, so a bot couldn't play a clip or stop a half-filled form from being sent.
- **Decision (Oliver: "Yes, add them"):**
  - `ui.show` takes **Video** `{url, posterUrl?}` and **AudioPlayer** `{url, description?}`. The url must be http(s) and the media file itself; a page like YouTube goes in the reply as a link. Media is display only, so no Send or Skip is added.
  - **Checks** (`checks: [{condition, message}]`) are allowed on any component and checked before the card is sent: a condition is a bound boolean or a call to `required`, `email`, `length`, `numeric`, `regex`, `and`, `or` or `not` with the arguments each needs, so a bad check comes back with what to fix. `call` is turned into v1.0 `@call`, as `path` already was.
  - Bots are told to put a form's checks on its Send button: a Button with a failing check stays off with the first message as its tooltip, while an input shows a failing check in red at once, before anything is typed. The Send button `ensureSubmit` adds carries any checks the inputs have.
  - The description tells bots not to ask for passwords, keys or other secrets in a form, since what's sent stays in the chat, and to use `secrets.request`. The renderer's `obscured` text field stays unoffered for that reason.
  - Apps already shipped render all of this: these parts of the basic catalog came with D-086. No app change.
- **Map tiles (Oliver: keep OpenStreetMap "for now"):** no MapTiler key is set up (`client/config/maps.json` doesn't exist), so every build, official ones included, uses OpenStreetMap's own tile server as D-310's fallback. Its usage policy allows light use only; move to MapTiler (D-310) if map cards get heavy use.
- **Not done:** Modal (little use inside a chat), and a hidden field for things that aren't secrets.

## D-323 Casama for Chrome: a browser extension, reopening D-123

- **Problem:** Oliver wants Casama in the Chrome Web Store. The app can't go in as it is: the store rejects extensions that only open a website, app.casama.ai refuses to be framed, and the Wasm build is 48 MB. D-123 had taken the browser extension off the roadmap.
- **Decision (Oliver, 2026-11-16: yes to decisions 1, 2 and 4; the rest as recommended):**
  - Build a small Manifest V3 TypeScript extension in `apps/extension` on `@casama/client`, with one purpose: connect the browser to the person's bots (ask about the page, capture, let a bot work in their tabs). D-123 is reopened, "your own browser" included.
  - One listing. It goes public at Phase 1; the Phase 3 `debugger` update is accepted as one "accept new permissions" prompt for existing users.
  - Free on every plan, Act included; normal limits and credits apply.
  - First run recommends "all sites" access with the other modes one tap away. Banking and payments, health portals, password managers, government ID sites and Casama's own addresses are off for Act by default (Casama's always). Meeting captions are decided at Phase 4; activity recap and history search come last, off by default, and are dropped if review objects. Store name "Casama", from a dedicated developer address under the Stackwares Google account. Built in its own worktree and branch.
- **Plan:** `docs/CHROME-EXTENSION-PLAN.md` (features §6, phases §15).
- **Phases:**
  - Phase 0 (2026-11-16): `apps/extension` (MV3, Vite, `@casama/client`), the three sign-in routes, account and workspace switchers, token storage, first-run agreement, remote flags (`chrome_extension`, `min_versions.chrome`), Playwright harness, reproducible store zip in CI, CORS for the extension's id (`CHROME_EXTENSION_IDS`), Copy Link and Connect Chrome in Sign In on Another Device.
  - Phase 1 (2026-11-16): the side panel (Chat with page, selection, PDF and YouTube context, streamed replies and cards, "What was sent"; Inbox; Library saves; More), right-click menu, four shortcuts, `ca` in the address bar, notifications with Approve and Deny over `chrome.gcm` (poll fallback), site access modes, never-list, offline save queue. Server: `POST /v1/media` (attachments that don't wake a computer, Library saves, HTML to PDF under a strict CSP), `media:` attachments, data-only pushes naming their account, attachments counting toward storage. Pages are read only when the person starts a message, switches a chip on, sends or saves; tab switches update the chips from the address and title alone. Store listing kit in `apps/extension/store/`.
  - Phase 2 (2026-11-16): a page kit content script, registered only on granted sites once a page feature is on, that asks the service worker for the guard and settings and never touches storage: selection bar and write button (opt-in), six self-hiding site helpers with remote off switches, highlights drawn inside the kit's closed shadow root (the page's DOM isn't touched). Kit buttons count only real, unobscured clicks; text goes into a page's box only when the person presses Insert; the write flow refuses password, card and one-time-code fields. Panel: "/" page commands and bot skills, "@" other tabs (optional `tabs`), Point, this page before (local index first, server only on Show), live call over Gemini Live, quick answers with Chrome's built-in models, send less (word-overlap trimming, no model), translate and read aloud, watch part of a page, read it for me, send these tabs, send a link's file to the bot's computer, today's brief. Server: `page_commands`, `highlights`, `conversations.source_url`, `POST /v1/watchers` with `target.chars`, `highlights.search`, a read-for-me line in the brief. Browser-made watchers: up to 25 a person, 90-day expiry, their maker can pause or stop them, a vanished anchor is an error, not a change.
  - Phase 3 (2026-11-16): bots in your own browser. A browser-only local device (platform `chrome`, capability `browser`, no computer) on the existing device WebSocket; `BrowserBackend` with a computer backend (agent-browser) and a "mine" backend (`/internal/browser/:device/call`), picked per run: a routine's `browser` setting, else the person's browser when the chat began in the extension, else the bot's computer; tools take `where`. Owner only (the run must act for the browser's owner, the bot be allowed, the workspace's `chrome_extension` and `chrome_act` on); Casama's own addresses and non-web addresses refused on the server and again in the extension after every navigation; state-changing steps in the audit log. In the extension, `chrome.debugger` behind one module: accessibility snapshots in agent-browser's shape with hidden text left out (DOMSnapshot styles), clicks only on the element really under the pointer, page reads in isolated worlds, a tab group per bot, an overlay in a closed shadow root talking back over a world-scoped binding, take over and hand back. Site asks (once, always, never; kept on the device), risky clicks and Enter in such forms ask, the cross-site check asks, purchases, password changes and password, card and one-time-code fields are handed to the person; asks are an extension window plus a notification, 5 minutes then no. Stop from the banner, the panel, Chrome's Cancel, closing the group, unpairing or going offline cancels the run. Watchers read signed-in pages in a background tab (`where: "mine"`, wait or use the computer when offline); teach by showing records role and name targets, never passwords, and replays in the browser. Device site columns, `organizations.chrome_*`, `routines.browser`, browser teach sessions; managed policies (`ServerAddress`, `ActDisabled`, `BlockedSites`, `AllowedSites`, `ExtensionDisabled`). Per-step screenshots aren't stored on the timeline (only when the bot takes one); needs `LOCAL_COMPUTERS` on, like the desktop companion.
  - Phase 4 (2026-11-17): the browser as a device and the long tail. The extension is a device source of platform `web` with live-only kinds `browser_tab` and `browser_history` (never stored, strict schemas, web sources only) and `activity` as site minutes per hour; it hears requests over Realtime on `user:<id>` and answers them in the 10-second window. `device.read` takes a `query` for history. Browser trigger events `site_opened` (a site, at most hourly per routine), `download_done`, `bookmark_added`; banking, health, password manager, government ID and Casama's own sites can't be triggers (one list in `packages/domain/src/browser-guard.ts`, shared with the extension), and the extension sends an event only when one of the person's routines starts on it (`GET /v1/device-triggers/browser`). Quick ask on Windows and Linux asks the paired browser for the tab through `POST /v1/device-requests`. Old app builds parse device kinds strictly, so grants leave the browser kinds out unless `all_kinds=true`. Bookmarks into knowledge once (B11); record this tab with `tabCapture`, up to two minutes, in the panel (B12); live view of a bot's cloud computer from the stream session's screenshot address, view only, in the panel or a pop-out (D10, not WebRTC); meeting notes from Meet's captions behind the `chrome_meeting_captions` flag and a consent step, banner while it runs, nothing sent until stop (E7); the private model rule checks `GET /v1/bots/{id}/model-privacy` and answers with Chrome's model or refuses (F3).
  - Coding agents in your browser (C16) don't use D-096's local MCP bridge: the browser isn't the computer the agent runs on, and computerd can't reach the extension. Instead `coding.delegate` hands Claude Code and Codex on the person's computer an MCP server on the API, `/mcp/browser` (Streamable HTTP, plain JSON), with a token signed by the internal token that names the run and the browser and ends with the agent's time limit or the run, passed in the environment, never on the command line. Its calls go through `/internal/browser/:device/call`, so every browser rule applies.
  - Phase 4 review (2026-11-17): browser asks get their own run event, `device.browser_access_requested`, and routines leave browser events out unless the client asks with `all_events=true`, because shipped app builds decode device kinds and events strictly; live-only readings are cleared once read; quick ask asks only for the address and title and is refused when the browser keeps its content to private models; incognito tabs are never read; `/mcp/browser` takes one request at a time.
  - Phase 5 (2026-11-17): other browsers. Edge takes the Chrome store zip unchanged; it has no `chrome.gcm`, so it polls once a minute as servers without a push sender already do, and its store id goes in `CHROME_EXTENSION_IDS` when the item exists. Firefox gets its own build from the same code (`vite build --mode firefox`, `scripts/build-extension.sh firefox`): the sidebar, a background script, id `casama@casama.ai`, Firefox 140+ for Mozilla's data consent at install, and Ask, Capture and Stay in the loop only. Act, the browser as a device, tab recording and meeting notes are left out at build time (`__CASAMA_BROWSER__` checks in the background), so the background registers nothing Firefox lacks and Mozilla's linter reports no errors. The page kit stays off too: its content script runs only when storage is closed to content scripts, and Firefox has no `setAccessLevel`, so pages could read the refresh token. Edge and Firefox show approval notifications from the minute check; other news waits in the panel and badge. Firefox has no `externally_connectable`, so it signs in by link or email code. Each Firefox install has its own random `moz-extension://` origin, so the API allows any such origin (`FIREFOX_EXTENSIONS`, on by default): calls still need the person's token, and no web page can have that origin. The Firefox test installs the built add-on into Playwright's Firefox over Firefox's remote debugging protocol and drives its pages from inside the add-on, since Playwright can't load extensions into Firefox or open their pages. Listing kits for Edge Add-ons and AMO are in `apps/extension/store/`; nothing is uploaded.

## D-324 The island and the menu bar app: Mac notch, iPhone Live Activities, Android live notification

- **Problem:** a person only knows what a bot is doing while Casama's window is in front of them. The iPhone Live Activity (D-067) freezes about 30 seconds after the app leaves the screen, Android has nothing, and closing the Mac window quits the app.
- **Decision (Oliver, 2026-11-16: every default in the plan's §13, with two changes):**
  - One island feed in Dart drives four surfaces: a notch drawn by us on the Mac (no system API exists), a native menu bar item and panel, a real iPhone Live Activity with server pushes, and an Android live notification (Live Update chip on Android 16 and later, RemoteViews before that and in the home-screen widget). Closing the Mac window keeps Casama running; Cmd+Q quits. Our own ActivityKit bridge replaces the `live_activities` plugin.
  - **Pushes go through Firebase**, not straight to Apple: production already sends through FCM, which holds the Apple key, and the server has no `APNS_*` key. Phase 4 first checks that Firebase holds a `.p8` auth key.
  - **The window stops forcing itself on top while a bot uses this Mac (D-066) only while "Show bots in the notch" is on** and the notch is on screen; otherwise D-066 stands.
  - Phones answer approvals with **Review** (opens the app); the Mac answers in place. Phones follow only runs the person started; the Mac also shows routines. Push-to-start waits for a later release.
- **Plan:** `docs/ISLAND-AND-MENU-BAR-PLAN.md` (features §6, phases §12).
- **Phase 0 built (2026-11-16):** the run tracker, island feed and `casama/island` bridge (Dart side) in `client/lib/features/island/`, the backend's `activeRuns`, `runEventsAfter` and `registerLiveToken`, and the chat controller reporting its run to the tracker. Who started a run is read from its trigger (`chat`, `mention`, `voice`, `replay`, `teach` are a person), since a routine's run keeps its owner as `created_by`; the Mac follows only the person's own or ownerless automation. No platform has a native side yet (`islandPlatforms` is empty), so nothing runs or shows until Phase 1 adds macOS.
- **Phase 1 built (2026-11-16):** the Mac. Closing the window hides it (Cmd+Q quits; the Dock icon, the menu bar item and the notch bring it back). A native `NSStatusItem` and popover (`client/macos/Runner/Island.swift`) replace tray_manager on macOS, and the notch is a borderless non-activating `NSPanel` above the menu bar on every Space: resting, working, open on hover after 0.3 s, needs your OK (opens by itself while another app is in front; Allow and Deny only on click, Open too when the risk is high), a 2-second peek, Stop. Decision 10 is tied to the notch answering that it is on screen. **On the Mac, approvals that ask this person show even when their run isn't one this device follows** (a teammate's routine asking them); phones stay "only runs the person started". Review fixes: a chat lets go of its run when it opens another conversation or a new chat; an unlisted unfinished run follows its own record; the workspace is re-checked after every wait; group chats link to `/groups/<id>`; Allow and Deny answer only on macOS and only for a request the feed shows; requests time out after 10 s; the tracker checks every 20 s instead of 3 s when nothing is followed; a poll never undoes a status the chat reported; the list of runs that ended is capped. The partial index for unfinished runs waits for Phase 4's migration. Checked on this MacBook by an integration test (`client/integration_test/island_flow_test.dart`) that writes runs into the local database and presses the notch's buttons through debug-only hooks.
- **Phase 2 built (2026-11-16):** the Mac extras. **Ask a bot…** in the open notch sends in the background to the bot asked last (a picker beside it; remembered per device), then shows the run in the notch; if it can't be sent, the window opens with the message. Files dragged onto the notch open Quick ask with them attached. A Mac without a notch (or an external display) gets a small pill that leaves the screen at rest. **Show bots in the notch** and **Open the notch on hover** under Settings → App (per device, on by default). The panel is left out of screenshots and screen sharing (`sharingType = .none`), so a bot never reads its own approval off the screen. VoiceOver labels on every row and button; Reduce Motion stops the pulse and swaps the spring for a short fade. The notch asks for the keyboard only while typing. A run's steps so far are counted from its events. Checked on this MacBook by the integration test; a real external display, VoiceOver and real key focus are left for Oliver (plan §19).
- **Phase 3 built (2026-11-16):** the iPhone. Our own ActivityKit bridge (`client/ios/Runner/IslandActivities.swift`) replaces the `live_activities` plugin: `RunActivityAttributes` (shared with the widget) and a typed content state in plain seconds, so a push can replace it. Activities start for runs the person started, update from the feed (an unchanged state sends nothing), go stale after two minutes, end as Finished (kept 15 minutes) or at once when the person stopped the run, and hand each activity's push token to Dart, which registers it. The widget draws the Lock Screen, StandBy and every Dynamic Island presentation, with Stop, Open and Review as deep links (`/runs/:id/stop` stops the run and opens its chat). **The Lock Screen gets the same general words as a server push** (§10): no detail, and an approval or takeover shows the tool's everyday words, not its own summary or reason; the Mac keeps the full wording. **No small family** (Apple Watch, CarPlay) yet: `supplementalActivityFamilies` needs iOS 18 and the widget extension still targets iOS 17. Checked in the iPhone 18 Pro Simulator (iOS 27.2) by `client/integration_test/island_ios_test.dart` and by screenshots of the Dynamic Island and the Lock Screen.
- **Phase 4 built (2026-11-16):** server pushes. `run_live_tokens` (run, user, platform, token, and an iPhone's own Firebase token, which Firebase needs beside the activity's) under row-level security: a person writes only their own tokens and only for runs they can see. `EventBus.observe` hears every event a process appends; `LiveRunPusher` (`packages/agent/src/live-runs.ts`), wired in the worker where every run event is written, reads a run's tokens (cached 10 s) and sends its whole state: a step at most every 5 seconds (Apple priority 5), needs your OK, takeover, back to work and the end at once (priority 10), each with a timestamp and a stale date. Steps are the app's own everyday words (checked against `app_en.arb`); tool arguments and approval details never leave. iPhones through Firebase with `apns.live_activity_token` (decision 8), no alert; Android as a data-only `live` message for Phase 5. Linked self-hosted servers send through `/link/v1/push`'s new `live` body; with private notifications on, without the bot's name or step (the widget then says "Working"). Tokens go when the run ends, when Firebase says they're gone, and in a sweep at 12 hours. Built and tested locally with a recording sender; on the Simulator the activity's push token reached `run_live_tokens`, and the real pusher made the APNs payload (`packages/agent/scripts/live-push-local.ts`), but the Simulator delivers it as an ordinary notification ("no user visible content"), not as a Live Activity update, so that last step needs a real iPhone. Not deployed: production needs the deploy and a check that Firebase holds Apple's `.p8` key (plan §19).
- **Phase 5 built (2026-11-16):** Android. `client/android/app/src/main/kotlin/ai/casama/app/LiveRun.kt` draws one ongoing notification per run the person started, on a silent **Bots at work** channel: on Android 16 and later, when the phone allows it, a **Live Update** (the standard look with `BigTextStyle`, ongoing, and the `android.requestPromotedOngoing` extra, since API 36's builder has no setter for it), with a status bar chip that shows the running time, or **Needs you** while it waits for an OK or a takeover; otherwise a `DecoratedCustomViewStyle` with our own collapsed and expanded RemoteViews. Stop, Review and Open open deep links; Finished stops being ongoing and clears itself after 15 minutes; a stopped run leaves at once; a notification the person swipes away stays away. **Android gets the iPhone's lock-screen words** (§10): Android shows the full notification on the lock screen unless the person hides sensitive content, so no detail and no approval summary; the public version says only "A bot is working" (or "Needs your OK"). Server updates arrive as the data-only `live` messages from Phase 4, drawn by `LiveRunReceiver` even when the app isn't running; the app registers its own Firebase token for each run it shows. States from the app and from the server are reconciled by time: an older push is dropped (Firebase doesn't keep order), pushes wait while the app is in front, the app redraws only what changed in its own feed, and an ended run never comes back as working. The home-screen widget shows the run that matters most with **Stop** while one runs. Checked on the Pixel 10 Pro XL emulator (Android 17) by `client/integration_test/island_android_test.dart`: the Live Update is promoted, the chip, both forms, every state, Stop, the widget's data, and **a real push through Firebase** drawn while the app was in the background (`live-push-local.ts` with `LIVE_SEND=1`), with an out-of-order older push ignored. Review fixes: a run that ended or was stopped leaves a marker so a late push can't bring it back; an end is never dropped as "older"; a state drawn from a push clears itself an hour past its stale time if no further word comes (a lost end); a run whose Firebase token wasn't ready yet registers on the next state.
- **Phase 6 built (2026-11-17):** the four later pieces, each with a short plan in the plan's §16. **Windows and Linux:** no notch, so the tray menu carries the feed (a row per run, then Stop, Allow and Deny, Open), with the tooltip and title saying what matters most; the notch switches stay Mac-only. **Acting without opening the app** (decision 5): on iPhone, Stop and Allow/Deny are App Intents (`LiveActivityIntent`) run in the app's process and handed to Dart; Stop is never gated, Allow and Deny need Face ID or the passcode (`requiresAuthentication`); if the app can't act within 10 seconds it asks iOS to bring it forward and opens the stop screen or the request. On Android the buttons open a translucent activity, so the phone is unlocked first (Allow and Deny also set `setAuthenticationRequired`), which hands the action to the running engine and closes, or opens the deep link when no engine runs. **Phones answer only a request the feed shows as waiting, only when native code says the phone was unlocked for it, and never a high-risk one**, which keeps Review alone so the details are read first. **Push-to-start** (decision 11): `live_start_tokens` under row-level security; an iPhone registers ActivityKit's push-to-start token (iOS 17.2+), Android its Firebase token; six seconds after a person starts a run, the server starts it on their phones that don't follow it yet (an APNs `start` with the attributes, or the usual data message, whose token then joins the run's live tokens). **Bots you start elsewhere** (Settings → App, phones) turns it off per phone; a shared phone follows whoever signed in last; an iPhone ends a duplicate if both the app and the server started one. **A voice call in the notch** (§6 B 13): the live call reports itself to `islandCallProvider`; the notch shows the call first, with a level meter (its own `level` message, ten a second, only when it moves), the length, Mute/Unmute and Hang up through the call's own handlers. After merging main (D-327), the notch follows `ActiveCall` (`followActiveCall`) and its `CallController` instead of the call screen, a click on the row opens the call screen (`call_open`), the Mac shows the call in the notch and its panel instead of D-327's tray items, and Windows and Linux show the call above the feed in the tray. Checked: the Mac integration test drives the call row, its meter, Mute and Hang up in the real notch; the Android emulator test presses the notification's real Stop and Deny buttons and sees them reach the server without the app moving; the iOS and macOS apps build. Not checked here: push-to-start and the intents on a real iPhone (the Simulator delivers no Live Activity pushes), and Face ID on the Lock Screen (plan §19). Review fixes: a phone that turns the setting off keeps its row switched off (`enabled = false`) instead of deleting it, so a shared phone never falls back to an earlier account, and signing out deletes it; push-to-start syncs run one after another and read the switch after every wait; Android's Firebase token is read each time (it can change); iOS sends the start token and activity tokens again once Dart listens (a message sent before its handler exists can be dropped); the notch lets go of a call that ended from the other side; a request whose risk isn't known (an older server) shows Review alone.

## D-325 Notifications: reply-ready pushes, the chat on screen, per-kind settings, every platform

- **Problem:** a normal chat reply sent no push, so a person who asked something and locked the phone never heard the answer was ready; a failed long run was silent too. Pushes that arrived with the app open were dropped on Android and iOS, everything on Android went to one "Miscellaneous" channel at normal priority, the only setting was quiet hours, and Windows and Linux had no notifications at all.
- **Decision (Oliver, 2026-11-16: "Go and build all now. Make sure it covers all platform Notifications too", approving every default in `docs/NOTIFICATIONS-PLAN.md` §11):**
  - **Reply ready / Couldn't finish:** kind `reply`, sent when a `chat` or `mention` run the person started ends after at least 10 s (completed, or failed including limits; never cancelled, voice, chat-app, routine or sub-runs). Bot name as title (conversation title for the default bot), reply in plain text, one tag per conversation. No proactive cap, no attention holds; quiet hours apply. Only the asker gets it.
  - **The chat on screen:** the app upserts `chat_focus` (per install, every 30 s while a chat is open and the app in front; null in the background). A fresh focus (45 s) on the conversation writes the reply row read with `push_status = 'off'` and pushes to no device. Opening a chat clears its notifications (Android by tag, iPhone and Mac by thread).
  - **Per-kind settings:** `profiles.push_prefs` (Replies, Needs you, Routines and briefs, Suggestions and check-ins, Account; missing = on) plus **Hide reply text**. Off still writes the inbox row (`push_status = 'off'`). Settings → Notifications.
  - **Per platform:** Android channels per kind (high priority for replies and needs-you) and approvals drawn by the app with Approve / Deny for `push_version >= 2` devices; iPhone and Mac `thread-id`, badge, `APPROVAL` category and Time Sensitive for urgent approvals; web tag and a click handler that opens the link in the app; Windows and Linux draw system notifications from the live inbox while the app runs (`flutter_local_notifications_windows` / `_linux` only, so Firebase keeps owning notifications on phones and Macs). With the app in front, every platform shows the in-app banner instead (now also for replies, with **Open**).
  - **Approve from the notification:** below high risk only, after unlocking; the app opens on the approval and answers it. High risk gets **Review**.
- **Kept out:** reply rows from the inbox list (read in their chat). Quick reply from the notification and pushes for other people's messages in shared chats wait (plan §10).
- **Note:** `timezone` is overridden to ^0.11.2 for the Windows plugin; `device_calendar` only uses `TZDateTime` and `initializeTimeZones`. The Realtime broadcast now carries `read_at`, `push_status`, `urgency` and `held_reason`.
- **Time Sensitive (iPhone):** `Runner.entitlements` has `com.apple.developer.usernotifications.time-sensitive`. Neither the App Store Connect API nor `asc web` can turn it on for the App ID, so automatic signing registers it at the next archive (`-allowProvisioningUpdates`). The Mac app leaves it out: its profiles are made by hand, and without it an urgent approval still arrives, just not through Focus.
- **Plan:** `docs/NOTIFICATIONS-PLAN.md` (§13 is the wire contract as built).

## D-326 Links in emails and invites open the installed app

- **Problem:** links in emails (Open Billing, invites, shared bots, a server's link code) went to the API's host, which only serves the API, so they failed with a 502 (fixed first by `CASAMA_APP_URL`, d91a79e9). Pointing them at the web app still left someone with the app installed in a browser, and the web app reads its route from the part after `#`, so a link like `app.casama.ai/settings/billing` opened the home screen.
- **Decision (Oliver, 2026-11-16: "we should open via the app instead of the web app"):**
  - Links are made by `appLink(env, path)`: `PUBLIC_OPEN_URL` + path when set (compose `CASAMA_OPEN_URL`), else `PUBLIC_APP_URL` + path. Casama Cloud sets `https://casama.ai/open`. That covers account emails, invite links and email invites, shared bot links and the Casama Link sign-in page; the MCP OAuth consent page and the billing portal's return stay on the web app, since a browser flow is waiting on them.
  - **`casama.ai/open/<route>`** is claimed by the apps the way `/i/` and `/gallery/` are: Android lists `/open/` in its App Links, iOS and the Mac App Store build read the AASA. The app's router turns `/open/<route>` into `<route>` before anything else, query and fragment kept.
  - **Without the app**, the site worker (`site/gallery-link.js`) sends phones and other computers to `app.casama.ai/open/<route>`. A Mac gets a page with **Open in the app** (`casama://app/<route>`) and **Continue in browser**, and can remember the choice. Windows and Linux builds don't register `casama://`, so they aren't offered the app.
  - **The web app reads paths:** a script in `web/index.html` moves a path behind `#` before Flutter starts, so any link to a screen opens it, self-hosted ones included.
  - **macOS** doesn't hand links to the router by itself: app_links passes `casama://app/…` and casama.ai links to it (`macOpenLinksProvider`), and the AppDelegate passes universal links to app_links.
  - **Signed out**, an `/open` link is kept on the device for 30 minutes (`PendingOpenLink`) and sign-in ends there, also after the web app reloads for Google or a sign-in email. It is forgotten once the person has reached it and moved on.
  - A pasted Casama Cloud link (`casama.ai/…`, `app.casama.ai/…`) names `api.casama.ai` as its server when an invite isn't found, not the site.
- **Order (not done yet):** `/open/*` goes into `site/.well-known/apple-app-site-association` only once an iOS build with this change is live: iOS reads that file from casama.ai, so older builds would otherwise open at a route they don't know. Until then iPhones and iPads open these links in the browser, which goes on to the web app. Android needs no such step: only new builds claim `/open/`.

## D-327 Live calls belong to the app: minimised calls, one call at a time, the live view on a call, the background

- **Problem:** a live call lived inside its screen. Leaving the call screen hung up without saving the transcript (and on Casama Cloud left the 2-minute hold as the charge), a second bot's call killed the first, a job started on the call was silent until the chat showed it, and on Android a backgrounded call heard only silence.
- **Decision (Oliver, 2026-11-16: "Execute the plan until all phases complete", every default in the plan's §11):**
  - One `ActiveCall` for the whole app; the call screen is a view of it. Back minimises to a draggable bubble on phones and a call card in the sidebar on wide screens.
  - One call at a time: "End call with Ava and call Max?". No hold. A new call gets the conversation's last 20 turns (about 2,000 tokens) in its locked instructions.
  - Turns are saved as they happen; a `live_calls` record with a heartbeat lets the server end abandoned calls and bill their real length.
  - Jobs started on a call are followed; the bot says when they finish or need the person (after a pause in speech), the idle limit waits for them, and a live-view tile (screenshots small, video when enlarged) swaps with the call.
  - Backgrounded calls carry on: an Android microphone foreground service with a `CallStyle` notification, CallKit for every iPhone call (outside mainland China), recovery after interruptions and network changes. The call shows in the island surfaces (D-324) once they exist.
- **Plan:** `docs/CALLS-PLAN.md` (phases §12).
- **Built, Phase 1 (2026-11-16, branch `t3/calls-plan-phases-1-4`):** `ActiveCall`/`CallController` own the call (`client/lib/features/voice/active_call.dart`); the call screen only views it. Back and **Minimize** leave the call running as a bubble (phones, tablets, any window without the sidebar) or a sidebar card (desktop layout); the chat shows a return bar. A second bot's call asks first; answering a ring ends the current call. `live_calls` (+ `live_call_turns` for idempotent turn ids), `POST /v1/voice/transcript/turns`, `POST /v1/voice/live/{id}/heartbeat`, `live_call_id` on the session, the transcript and voice tools; the worker's minute tick ends calls with no heartbeat for 2 minutes and bills up to the last heartbeat (`billing/live-calls.ts`). New calls in an existing chat get its last 20 turns in the locked instructions. The screen stays on while the call screen is in front; the wake word pauses during calls. Calls made while building are in the plan's Progress section.
- **Built, Phase 2 (2026-11-16):** the app follows `start_task` runs (and tools still running after 12 s) through their run events: a "Working on it" card and a job strip stay while they run, the idle check waits, and the bot gets a note when one finishes, fails or needs the person, after a 1.5 s pause. A live-view tile (screenshots only) shows while a job works on the computer; tapping it swaps the call screen for the live view, and the bubble swaps back. `stop_task` stops only the jobs started on that call (`live_calls.task_run_ids`, through the person's session); `show_screen` is answered by the app. Every call that connected ends with a recap message (a `call` content part, shown as a card, plus a text fallback).
- **Built, Phase 3 (2026-11-16, native parts not compiled):** `CallSystem` gives each call the phone's own controls: an outgoing CallKit call on iPhone (except region CN), whose audio session the mic waits for, and a microphone foreground service with a CallStyle notification on Android (`CallService.kt`). Mute, End Call, hold and a tap on the notification drive the call. Interruptions (audio_session) put the call on hold (`VoiceCall.setOnHold`: no mic, the bot's speech dropped, the bot told to wait) and restore the audio session and route after; unplugged headphones switch to the speaker; the web tab's title shows the call's clock. Network changes keep using the Gemini resume handle.
- **Built, Phase 4 (2026-11-16, native parts not compiled):** `CallGlance` (`call_glance.dart`) is what surfaces outside the window show for a call, changing only when that changes. iPhone: the call's own Live Activity (the widget's `kind: call` branch) on the lock screen and Dynamic Island, with the bot, a counting timer, the job line, and Mute and End Call (iOS 17 App Intents, passed to the app by a Darwin notification and `casama/call_glance`). Mac: the menu bar starts with the call and its buttons, and its title counts the call. The island (D-324) is still on its branch, so the notch gets the same glance after its merge (listed in the plan's "After island merge").

## D-328 Device access a bot can't miss

- **Why:** on 2026-11-16 a bot was asked about health data the person shared from their iPhone. First it looked only at connected apps and said nothing was connected. Then `device.read` failed with `no_device_access`, and it told the person it had sent the Allow card without calling `device.request_access`. Turning a kind on in Device connections never grants it to any bot, so there was no way through.
- **The card comes from the failed read:** when `device.read` or a device write has no grant and the person shares that kind from a device, the tool emits `device.access_requested` itself (reason "So I can use your … to answer you"). The model is told the card is already showing. A run shows the card once per kind, even if the bot also calls `device.request_access`. If the person doesn't share the kind, no card appears and the error points to Settings → Device connections.
- **The bot knows what's shared:** the "who you're talking with" block (D-169) lists the kinds the person shares from their devices, which ones this bot may read, and which ones are waiting, so the bot reaches for `device.read` instead of a connected app. The lazy tool index describes the `device` group by what it holds.
- **Allow from settings:** under each kind in Device connections → Advanced, "Allow a bot" picks a bot from the workspace (`PUT /v1/device-grants`, which still checks that the person can use the bot). Before, the screen could only revoke.
- **Tests:** API (`device-data.test.ts`): one card per run from the failed read, no card for someone who doesn't share the kind. Agent: the person block with shared and allowed kinds. App: allowing a bot from the settings screen.

## D-329 Sites and domains: pages on the web at their own address, connected and bought domains

- **Problem:** a site a bot builds can only be shared as a long `pages` link that search engines are
  told to skip; people want it at an address they'd tell someone, and on their own domain.
- **Decision (Oliver, 2026-11-16: "start executing the plan in a separate worktree. Don't stop until
  all phases complete"; every §13 default taken):**
  - A site is the same page, made public, served at `<name>.<sites zone>` by the pages port, chosen
    by host name. The sites zone is a domain of its own (`CASAMA_SITES_ZONE`), never `casama.ai`
    or `casama.link`, so a site can never read the app's cookies.
  - Connected domains get certificates from Cloudflare for SaaS on Casama Cloud and from Caddy's
    on-demand TLS on self-hosted servers. A domain is served only once it carries our proof, and
    the proof is re-checked so nobody can take it over later.
  - Buying domains: the Name.com reseller API, paid through Dodo (one payment with an amount, then
    on-demand renewal charges), priced at cost × 1.25 + $1.50 rounded up to .99, paid plans only,
    shown only where the web purchase channel is allowed (never on Android). Buying is Casama Cloud
    only.
  - Limits: live sites 1 / 3 / 10 / 50 and domains 0 / 1 / 5 / 20 (Free / Plus / Pro / Max).
    Search engines may list a site from Plus. "Made with Casama · Report" always shows on site
    addresses; it can be turned off on a custom domain from Plus. Three different reporters take a
    site down until someone checks it.
  - The registrant email is kept in a server-only table, not sealed with the workspace key: the
    registrar still needs it after the workspace (and its key) is deleted.
  - Buying (Phase 3): a domain payment is offered to buying before plan billing on the same Dodo
    webhook (`BillingService.domains`). The order id is the workflow id and the registrar's
    reference, an attempt holds a lease on its order, and the cost is re-read before registering
    (over the quoted cost + $1: refund). A refund that fails goes to `needs_attention` for an
    instance owner. A workspace under a day old waits for an owner's approval on its first
    purchase. The registrant's details are sealed with the workspace key; the email is also kept
    in `domain_registrants`.
  - Keeping a domain (Phase 4): every upkeep step is keyed `<domain>:<expiry date>:<step>` in
    `domain_events`, so a late or repeated run never charges or emails twice; only the latest
    reached notice is sent after an outage. A renewal is an order of kind `renew` through the same
    workflow and refund rule. Before calling a domain expired the registrar is asked again. A
    transfer code needs the workspace owner and a sign-in from the last 10 minutes (the token's
    `amr` time), and is never stored. A finished transfer turns the row into a connected domain,
    so the site stays up while its DNS still proves it. A deleted workspace's domains are released
    and their registrant emailed by address: `email_outbox` rows may name an address (`data.to`)
    instead of a workspace or person.
- **Store rules, 2026-11-17:** in-app notices and pushes about renewals state facts only (no price,
  no "renew now"), since the inbox reaches Android and App Store storefronts outside the US; the
  emails keep the price and how to pay. Remote setting `buy_domains_app_store: false` hides buying
  in the iOS and Mac App Store builds only, without a release, if App Review objects. App Review
  notes are in the plan §2.4.
- **Plan:** `docs/SITES-AND-DOMAINS-PLAN.md` (how it works §7, phases §9, what's left for Oliver §14).

## D-330 Local models see pictures and search memory on their own machine

From testing Gemma 4 on Ollama (2026-11-17): a run on the local model worked, tools and all, but
pictures never reached it and memory search fell back to words.

- **Decision**: open models that read images are recognized by name in the model table
  (`registry.ts`): Gemma 3 and 4 (not Gemma 3's text-only 1B and 270M), LLaVA, Moondream,
  MiniCPM-V, Qwen-VL, Llama 3.2 Vision, Llama 4, Granite Vision, Pixtral and Mistral Small 3.1/3.2.
  Before, the catch-all `llama|qwen|mistral|gemma` row said no vision, so attachments were dropped
  and screenshot tools hidden. Any other model can be marked on its OpenAI-compatible credential:
  `settings.vision_models` (create and update take `vision_models`; the response always lists it,
  optional in the schema so new apps still read older servers). A run whose primary model is
  marked treats it as able to see (`CredentialResolver.markedVision`). Only `openai_compatible`
  credentials count; other providers' models are known by name.
- **CLI**: `casama credential add` takes `--embedding-model` and `--vision-model` (repeatable);
  the new `casama credential set <id>` changes the name, embedding model or image list.
- **Memory**: nothing new in code; D-271's `embedding_model` already did it. The docs now say how
  (`embeddinggemma` on Ollama, 768 dimensions, padded to 1,536).
- **Why a list, not a switch per server**: one Ollama often holds text-only and vision models side
  by side, and sending an image to a text-only model can fail the call.

## D-331 Emoji reactions on messages

Asked for 2026-11-17: "reacting to messages with emojis, just like on Facebook". Plan:
`docs/REACTIONS-PLAN.md`; built with the plan's default answers.

- **Decision**: anyone who can read a chat reacts to people's messages and bots' replies with one
  emoji each. Another emoji replaces it (Facebook, not Slack). Quick six 👍 ❤️ 😂 😮 😢 👎 (👎 over
  😡: a clearer signal for the bot), any emoji through `emoji_picker_flutter`, double-tap ❤️ on
  touch only (it never takes a heart back). Chips under the bubble with counts; yours outlined;
  hold a chip for who reacted.
- **Data**: `message_reactions`, one row per author: a person (`user_id`), a bot (`bot_id`) or a
  chat-app sender (`external_sender` = `<channel id>:<sender>`, `source = 'channel'`); exactly
  one of them, enforced by a check and partial unique indexes. A trigger copies the conversation
  and workspace from the message and refuses tool and system rows. People insert, change and
  delete only their own rows (source app or api); the worker writes bot and chat-app rows. Stored
  unencrypted: an emoji is metadata, like the time a message was sent. A broadcast trigger sends
  `message_reaction` on the chat's Realtime topic; the app listens on the channel it already
  joined for runs, since Realtime allows one join per topic.
- **Emoji check**: one extended grapheme of up to 16 code points, made only of emoji code points
  (`normalizeReaction` in `@casama/domain`; the database checks length and no letters or spaces).
  New Unicode emoji work without a server update. Text-style pictographs get FE0F so ❤ and ❤️ are
  one chip.
- **No run, no push**: a reaction never wakes the bot (Regenerate exists for that) and never sends
  a notification. 60 changes a minute per person.
- **The bot reads them**: history notes reactions on the last 50 turns
  (`[Reactions: ❤️ from Ana]`). `run_digests.reaction` holds the latest person's sentiment on a
  run's reply (positive or negative; others neutral). Skill learning counts a negative reaction as
  a correction (and proposes a skill edit when the reply used one), and doesn't treat a "no…"
  after a positively-reacted reply as correcting it.
- **Bots react**: the `chat.react` tool (low risk, defaults to the message being answered), for
  acknowledgements only; group-chat prompts suggest it over posting "👍" as a message. MCP:
  `react_to_message`.
- **Chat apps**: Telegram (`message_reaction` updates; old channels' webhooks are reset on their
  next message; groups need the bot as admin), Slack (`reactions:read`, `reaction_added` and
  `reaction_removed`) and WhatsApp (reaction messages), both ways. `channel_message_links` maps an
  app's message ref to our message for messages received and sent from now on. Senders not on the
  allowed list are ignored. Telegram's fixed reaction set gets the nearest emoji or nothing.
  **Discord dropped**: it hears only slash commands here (no gateway connection), so it can't see
  reactions.
- **Chrome extension**: chips and the quick six under messages, through the same API.
- **Not now**: several reactions per person, custom emoji, reactions in search, exports and shared
  links.

## D-332 The server picks where the paywall opens and which plan is popular

Asked by Oliver (2026-11-17): lead with the monthly price so the paywall looks affordable, start
Free workspaces on Plus, and be able to change both without an app release.

- **Decision**: two flags on `plans`, edited in Admin → Pricing and sent with `/v1/billing/plans`:
  `paywall_default` (at most one plan, a unique partial index; saving one unpicks the rest) and
  `paywall_popular` (any number, usually a tier's monthly and yearly). The default plan gives the
  tier a Free workspace opens on and the billing period everyone opens on; paying workspaces still
  open on the tier above theirs. The plan order stays `sort`.
- **Shipped picks**: Plus monthly opens the paywall (it used to be Pro yearly), Pro is badged.
- **Older servers**: the flags are optional in `Plan`. An app that gets none opens on Plus,
  monthly, with Pro badged. A server that sends them all off gets Plus, monthly, no badge.
- **Why flags on the plan, not remote app settings**: the picks name plans, and the plan table is
  where plans are edited; D-241's feature switches are per-app on/off values with no plan in them.

## D-333 Billing audit fixes: workspace columns, calls, Link metering, domains, plan changes

Asked by Oliver (2026-11-17): audit billing for bugs, leaks and abuse. Findings and what's still
open: docs/BILLING-AUDIT-2026-11-17.md.

- **Workspace billing columns are the server's**: a trigger refuses app-session changes to
  `created_by`, `plan`, `suspended_*`, `storage_bytes` and `region`, and app sessions can't delete a
  workspace (account deletion still does, on the server). Everything "once per person" (free
  credits, the trial, the cap of 5) hangs off `created_by`.
- **Live calls**: only a Google key makes a call the workspace's own (every call is Gemini Live,
  D-260). A billable call is recorded with its hold under a per-workspace lock before its token is
  made, at most 3 open at once. A quiet call is billed the clock to the sweep at the listening rate
  (the app talks to Google directly, so the server can't cut it off), and one that never sent a
  heartbeat keeps its hold.
- **Link model proxy**: a cut-off stream is charged the prompt and all output, reasoning included;
  plain calls always finish upstream; output capped at 32,768 tokens; credits needed cover the
  prompt and the cap. Any model stays allowed (pay-as-you-go).
- **Domains**: a refund or chargeback of a registered domain's own payment suspends it. Late or
  duplicate payments are refunded instead of failing the webhook or being kept.
- **Plan changes**: a move between paid plans tops credits up by the share of the period left
  (charges are pro rata); starting to pay still tops up in full. No plan changes during a trial.
- **Computer hours** are checked on every hosted start, and computers past them are put to sleep.
- **Why not ignore sandbox purchases**: App Review buys with sandbox accounts in the production
  build; only invited testers can make them.
- **Credits follow the paid period** (`public.grant_month`), and a refund ends only the period it
  paid for; a full refund of the current payment or a lost dispute revokes the plan and claws back
  every paid grant of that period.
- **Runs wait in their workspace's line**: the runs queue is partitioned by workspace,
  `RUN_WORKSPACE_CONCURRENCY` (5) at once.
- **One inbox, one set of free things**: free credits, the trial and referral decisions are keyed
  on a hash of the normalised email (no "+tag", no Gmail dots) that outlives the account. A web
  trial started after the person's trial was used gives nothing until it's paid.
  A store trial started after it was used (the store gives its own free week) keeps the plan but
  gets no trial credits from us (2026-11-18); paying tops the month up as usual.
- **Live calls paid from credits go through the server's relay**, which bills what Gemini reports;
  the app gets a relay secret, not Gemini's token. Why a relay and not a client change: the app
  already connects to whatever `connect_url` the server returns, so no app release is needed.
- **Given-back credits keep their expiry**: they refill the lots they were spent from.
- **Gallery rewards** count only confirmed, week-old accounts with a successful run, capped at $110
  a contributor a month. **Link computers** follow the cloud workspace's plan limits and are slept
  at zero credits. **Bot cards are USD only**, because the caps are in dollars.

## D-334 Leaving stops your automations; knowledge uploads use storage; refused teach drafts say why

Decided by Oliver (2026-11-17), from the billing audit (D-333).

- **Leaving a workspace stops that person's automations there.** When a membership goes (they
  leave, an admin removes them, or their account is deleted), a trigger on `memberships` switches
  off the routines they made in that workspace and pauses their watchers. Nothing is deleted:
  after rejoining they can turn them back on. The worker checks again at fire time: scheduled,
  message, calendar and webhook routines and watcher checks skip any whose creator is no longer a
  member (as browser triggers already did). Routines with nobody behind them (a page's form, a
  workspace file) still run. Why: someone who left shouldn't keep spending the workspace's credits.
- **Knowledge uploads count toward the plan's storage** (`storage_gb`), like Library items and chat
  attachments: a trigger adds each upload's bytes to `organizations.storage_bytes` (existing uploads
  were counted once). Adding an upload source that would pass the cap is refused with the same 409
  `storage_full` as attachments. Websites, GitHub and connection sources keep only indexed text and
  aren't counted.
- **A teach draft that couldn't be written says why.** The recording keeps the drafting run's
  `error_code` and `error_message`, and `GET /v1/teach/{id}` returns them. Casama for Chrome and the
  app show the reason, with See plans for credit and plan codes.

## D-335 Message drafts in bots' replies

- **Decision (2026-11-17, Oliver showed Grok's email draft card, "I want the same with ours", then "maybe we can also use for other draft message related cards too"):** the A2UI catalog the apps render (D-086) gets a second component of Casama's own after Map (D-310), **MessageDraft**: `{kind?: "email"|"message"|"post", app?, from?, to?, cc?, bcc?, subject?, body, title?, status?, sendLabel?}`. One card for emails, chat messages (Slack, WhatsApp, Telegram, SMS) and posts. Before, a bot either sent straight away or pasted the draft as text and asked "should I send it?", and then the send stopped again for an approval.
- **In the app** (`features/chat/widgets/bot_ui_draft.dart`): inside the chat card, a header ("New email", plus the app's mark when it's bundled) with a status pill ("Ready to send"), the message on a plain panel (From, To, Cc, Bcc and Subject rows, then the body), and the card's own **Send email** (or Send, Post), **Discard** and **Edit**. Edit turns the fields into text boxes and the pill says Edited. Send sends what's on screen. The chat shows the button pressed ("Send email"), not the fields, and the card dims without "Sent" under it.
- **For bots** (`ui.show`, `packages/agent/src/tools/ui.ts`): the description says to show a draft before sending an email or message the person asked for, unless they said to send it straight away. A draft needs a body, recipients as text, and no action or children; the bot adds no buttons. "draft.send" reaches the bot with the final fields and the instruction to send exactly that without asking again; "draft.discard" means don't send it.
- **One yes, not two** (`packages/agent/src/drafts.ts`, the approval gate in `run.ts`): Send on the draft is the person's approval of that message. When the run's message is a draft.send from a surface this bot showed with a MessageDraft, a tool call that would ask is let through once per draft if it sends exactly that message: one of its texts is the body (HTML or a base64 MIME message count; added or missing text doesn't), the subject and every recipient are in it, and it addresses nobody the draft (or its text) didn't. The pass is recorded as an approved row in `approvals` (`args_redacted._draft`). Action rules set to ask and always-ask tools still ask. `ui.show` refuses `draft.` events on any other component, so no bot button can pose as the draft's Send.
- **Older apps** don't know the component and leave it out of the card, so the bot should also say a line about the draft.
- **Not done:** attachments on a draft, updating the card after sending (the bot's reply says it went), and saving to the mail app's own Drafts folder.
- **Later (D-337):** Event and eight more cards, the same one-yes check for Add to calendar, and approval cards that show the email or event.

## D-336 The web app draws its first frame without waiting for what it doesn't need yet

Decided by Oliver (2026-11-17: "improve the performance of the whole app, start with the web app").

Measured on cold loads of the Wasm build at 20 Mbps and 40 ms (median of 3, headless Chrome with
the GPU): the first frame came at 8.3 s and after 9.3 MB in 49 requests; now 5.2 s, 6.85 MB, 25
requests. Everything below either loads later or not at all on the web.

- **Fonts load when first used.** Families in pubspec's `fonts:` are font-manifest fonts, and the
  web engine downloads every one before its first frame. Only Google Sans (the Plain look, D-266)
  and the icon fonts stay there. Libre Baskerville, Lato, Noto Serif, Fraunces, Figtree and
  JetBrains Mono ship as plain assets and load through `FontLoader` (`lib/theme/bundled_font_loader.dart`):
  a saved look's fonts before the app's first frame (`preloadFonts`), a picker's preview as it
  shows, and the code face once the app is up. About 2.7 MB off the start.
- **Live-call audio loads with the call.** `index.html` no longer loads flutter_soloud's start-up
  script, which compiled a 2.6 MB WebAssembly module and started audio threads on every visit.
  `ensureSoloudLoaded` adds it when a call's audio is made and before `SoLoud.init()`.
- **PostHog doesn't hold the first frame.** On the web, setup first downloads posthog-js (up to
  3 s); the app now starts at once, and every PostHog call waits on `Telemetry.posthogReady`,
  because the plugin silently drops calls made before its script loads. Native setup still
  finishes before `runApp`.
- **The renderer comes from the app's own `canvaskit/` folder** (`canvasKitBaseUrl` in
  `web/flutter_bootstrap.js`), not www.gstatic.com: no extra connection before the first frame,
  and a self-hosted server no longer depends on Google's CDN.
- **No RevenueCat or Google Identity Services scripts.** The web app never buys through RevenueCat
  (its store is `NoStore`, D-297) or signs in through Google's script (Continue with Google is a
  redirect), yet both plugins loaded their scripts when they registered. `scripts/build-web.sh`
  ships an empty file in place of RevenueCat's 1 MB web SDK, and `client/third_party/google_sign_in_web`
  is an empty web plugin swapped in through `dependency_overrides`. If the web app ever uses
  either, remove the stand-in.
- **Pictures are WebP.** The launch image in `index.html`, the mascot stills the app shows, and the
  cloud baked into each mascot Lottie: about 72% smaller for the stills and 45% for the Lotties.
  The PNG stills stay as sources and because the Mac's notch island reads them
  (`client/macos/Runner/Island.swift`). `scripts/casama-mascot-webp.py` converts; the generators
  write WebP themselves.
- **Not done: splitting the Wasm build.** Flutter 3.50 splits deferred imports only in the
  JavaScript build; the Wasm build needs `--enable-wasm-deferred-loading`, a hidden flag marked
  experimental. `main.dart.wasm` (4.8 MB compressed) is now most of the start, so this is the next
  step once it is tried on a quiet machine.
- **Checked at run time:** a 200-message chat scrolled, flung and typed in at about 60 fps with
  two frames over 25 ms; the main thread was 93% idle. Code blocks in chat now draw their
  unhighlighted text in the mono face too (`styleNotMatched`); it took the paragraph font before.

## D-337 Cards for what bots read and do, and approvals that show the real thing

- **Decision (2026-11-17, Oliver: "maybe we're missing more a2ui cards? Dig deeper what else we need", then "build all"):** bots mostly read email, calendar, tasks and device data (production, last 30 days), yet answered in text and almost never showed a card. The A2UI catalog (D-086) gets nine more components of Casama's own after Map (D-310) and MessageDraft (D-335), and approval cards show the email or event itself.
- **Cards** (`features/chat/widgets/bot_ui_cards.dart`, `bot_ui_lists.dart`, shared pieces in `bot_ui_kit.dart`), all in the draft's look (header with a status pill, a plain panel, the card's own buttons):
  - **Event** `{title, start, end?, allDay?, location?, attendees?, description?, app?, actions?}`: Add to calendar ("event.add" with the shown fields), Change, Skip. `actions: false` shows an existing event.
  - **Agenda** `{title?, date?, events: [...]}`: a day or week in time order, grouped by day when it spans several. Display only.
  - **MessageList** `{title?, app?, messages: [{id, from, subject?, preview?, time?, unread?}], reply?}`: an inbox, with an unread count and a Reply per row ("message.reply"; the bot answers with a MessageDraft).
  - **Checklist** `{title?, items: [{id, text, done?, due?, detail?}]}`: ticks stay on the card until Save ("checklist.save" {done, undone}), because any answer closes a card.
  - **Stats** `{title?, stats?: [...], chart?: {type, labels, series, unit?}}`: tiles with value, unit and a change colored by whether up is good, plus a line or bar chart (fl_chart). Display only.
  - **Results** `{title?, layout?, items: [{title, subtitle?, imageUrl?, rating?, reviews?, price?, url?, badge?}], choose?}`: a carousel (when there are images) or a list; a tap opens the url; with `choose`, "result.choose".
  - **PersonPicker** `{label?, people: [{id?, name, detail?, avatarUrl?}], multiple?}`: "Who do you mean?" when a name matches several contacts ("person.pick" or "person.none").
  - **Schedule** `{kind?, title, when, next?, detail?, ref?}`: confirms a reminder, routine or watcher; Change and Cancel it ("schedule.cancel" {ref}). Its id field is `ref` because `id` is the component's own.
  - **Details** `{title?, rows: [{label, value}], footer?}`: a booking, order or receipt. Display only.
- **For bots** (`ui.show`): each card is in the description with its events, and checked before it reaches the app (required fields, ISO times, row limits, chart values one per label), so a bad call comes back with what to fix. Cards take no action or children; the events of every card with buttons are reserved for that card. The chat shows the pressed button ("Add to calendar", "Reply to Sarah"), not the values, and these cards dim without "Sent".
- **One yes for events too:** Add to calendar works like a draft's Send (D-335): a create call is let through once if it has the card's title, day and start time and every guest, and invites nobody else (a calendar or account id the call names is not a guest). Other calls still ask.
- **Approval cards** (`bot_ui_previews.dart`): a send by an email or chat tool (Gmail, Outlook, Slack, `channel.send`…) shows as a read-only draft, and a calendar create or update shows as an event, instead of three lines of arguments. Other tools keep the summary.
- **Older apps** skip components they don't know, so bots are told to say a line in text too.
- **Not done:** live updates to a shown card (a ticked task or added event changes only after the bot's reply), editing an event's time on the card, and attachments on drafts.

## D-338 Starter requests written for the person

- **Decision (2026-11-17, Oliver: "our welcome chat list of suggestions should be dynamic or ai generated so it's more aligned to the user especially should focus on general end user", then "build all"):** an empty chat showed the same four starters to everyone, two of them for developers ("Make a project folder … in my workspace", "What can you do on your computer?"). Now a cheap model writes four for each person and bot; rules stand in without a model.
- **What it writes from** (`packages/agent/src/starters.ts`): the person's local day and time (their profile timezone), the apps the bot can use (integration names, labels, Composio toolkits), About you and learned facts only where the person shares them in that space (`loadPerson`, D-169), the bot's role (first 1,200 characters of its instructions), and the person's own last 12 requests to that bot (run digests) so it doesn't repeat them. The prompt asks for first-person, everyday requests of 3–9 words, no technical words unless the person works in tech, only things the bot can do with the listed apps, a mix of time-of-day, app, personal and everyday, and no name in the text.
- **Checked before saving:** a JSON array of exactly four usable starters, 6–80 characters, no links or code words, no repeats; an emoji or ✨. Anything else counts as a failed reply.
- **Rules** (`ruleStarters`): connected mail and calendar first ("Sum up my unread emails", "What's on my calendar today?", tomorrow in the evening), then one for the time of day (plan my day, to-do list, dinner idea, wind down; something fun on weekends), then everyday help rotating by day. Used when the bot has no usable model, its budget or credits refuse, or the reply is unusable.
- **Where it runs:** the worker (`refreshStarters` workflow, workflow id per person, bot and hour, so at most once an hour). `GET /v1/bots/{id}/starters` returns the saved list, or rules on a first open, with `refreshing: true` while a new list is written; the app asks again up to three times (6, 10, 14 s) and the new list fades in. A list lasts 20 hours (rules 3 hours, in case a key or credits were added), and a newly connected app makes it stale after 10 minutes.
- **The model call:** `backgroundComplete` in `run.ts` makes one call outside a run with the same checks as a run: Casama Cloud's model assignment and the shared key's rules, a live bot and workspace, the bot's daily budget, credits on a credit-gated plan, and the bot's background model (`backgroundChain`). Its cost goes to `usage_ledger` with no run and `meta.purpose = "starters"` (docs/COSTS.md).
- **Storage:** `chat_starters` (one row per person and bot; `source` ai or rules), API and worker only. Leaving a workspace deletes the lists written there.
- **App:** the empty chat reads `botStartersProvider`; until the first answer the app's own everyday four hold the space invisibly, so nothing jumps. Offline or on an older server it shows them (plan my day, write a message, explain something, "What can you help me with?"). The subtitle is now "Ask {bot} anything, or tap an idea below to get started." instead of "has its own computer, memory and tools". Taps send `starter_tapped` {source: ai, rules or app; position}.
- **Tests:** `packages/agent/test/starters.test.ts` (parsing, rules, local time, prompt, staleness), `apps/server/test/starters.test.ts` (route and 404, rules without a model, a scripted model's list with its ledger rows, an unusable reply, a bot over budget, leaving the workspace), `client/test/chat_starters_test.dart` (personal list and tap, offline fallback, the new list replacing the old).
- **Role first (2026-11-17, Oliver, on a Coder bot offered "Plan a calm Tuesday evening" and birthday reminders: "not related at all to the Coder bot persona I selected"):** the first prompt forced a mix of time-of-day, app, personal and everyday requests and banned tech words, so only one of four followed the role. Now the role leads: every request must fit it, and the time, apps and person only shape requests within it; a general assistant still gets everyday ones. A bot whose instructions open like a starter bot's (`personaTemplate`, matched on the first line) gets that template's starters in the prompt as examples, and rules lead with them too. Tech words pass the check for a technical role (`technicalRole`: build templates, the data analyst, or instructions that say software, developer, coding…). Lists written before `STARTERS_REVISED_AT` count as stale and are written again on the next open.
- **Connect tiles centered:** `ShowHide` lines its child up top-start, so the tile column shrank to its tiles and sat left; it now takes the full width. When every tile fits at 60–72 points they sit in one centered row instead of wrapping one tile onto a second line.
- **Not done:** languages other than English (v1 is English only), and refreshing a list that's still open when it goes stale (the app keeps it until restart).

## D-339 The open-source edition runs without ee/; licensing, trademark and CLA files

- **Decision (2026-11-17, Oliver: "Do everything you can right now", after comparing Casama's license with Rakazo, MausBot and OpenBot):** keep Apache-2.0 for everything outside `ee/` and the Casama Enterprise License for `ee/` (D-073). Make the split clear and keep it honest: without `ee/`, Casama is fully open source and works.
- **Compared:** Rakazo is Apache-2.0 with nothing held back; OpenBot (CopilotKit) is MIT; OpenMausBot has the same split as Casama (Apache-2.0 plus a source-available `enterprise/`), with a CLA for that folder and a CI job that builds without it. Casama was the only one of the four with neither a written licensing page nor a NOTICE file.
- **The server loads ee/ in one place:** `apps/server/src/ee.ts` imports `@casama/ee` (types only statically, the module dynamically), returns null when it isn't installed, and throws on any other failure so a broken `ee/` isn't mistaken for the open-source edition. `app.ts`, `routes/admin.ts`, `main.ts` and the worker's audit-forwarding step use it. Without `ee/` the enterprise routes answer 402 `license_required` (as an unlicensed enterprise build does, so the app behaves the same), and Admin → Status shows "Open-source edition (built without ee/)".
- **`scripts/oss-edition.sh <dir> [--check]`** exports HEAD into `<dir>` (never touches the checkout), deletes `ee/` and its tests, the workspace entry, the server's dependency and the image's `COPY ee/` lines, and fails if anything outside `ee.ts` and tests still names `@casama/ee`. `--check` installs it, loads the API's module graph, and runs `oss-edition.test.ts` and `admin.test.ts` with `CASAMA_EDITION=oss`. CI's backend job runs it after pgTAP.
- **Files:** `LICENSING.md` (the split, the open-core rule "would someone running Casama for themselves or a small team want it? then open core", contributions), `NOTICE` (Apache §4(d), so forks carry the attribution; copied into the server image with LICENSE), `TRADEMARKS.md` (draft: forks under their own name, "based on Casama" is fine, no "Casama" in a modified or hosted product's name), `ee/CLA.md` (draft CLA for `ee/` only; outside `ee/` stays DCO with no CLA). `ee/LICENSE` clause 4 now points at the CLA: a DCO sign-off doesn't grant the right to relicense. README, CONTRIBUTING, the docs' contributing page and `ee/README.md` (which also gains audit forwarding) link them.
- **Tests:** `apps/server/test/oss-edition.test.ts` (edition, missing vs broken `ee/`, the 402 fallback routes), and the CI step above.
- **Not done (Oliver, with a lawyer):** legal review of `ee/LICENSE`, `ee/CLA.md` and `TRADEMARKS.md` (each still says DRAFT); assigning the code's copyright to the company that will raise money; registering the "Casama" trademark; a CLA bot on pull requests that touch `ee/`.

## D-340 Bot replies in each chat app's own format, not raw Markdown

- **Decision (2026-11-17, Oliver, after the first live Telegram test: "the bot responds in markdown format to telegram which is not rendered … what if this happens with our other chat integrations?"):** replies are converted when they're sent, per app, not by asking the model for plain text. The same reply shows in the Casama app, where Markdown is right, and a prompt can't guarantee the format anyway.
- **One converter, `packages/agent/src/channels/format.ts`:** a small line-based Markdown reader (bold, italic, strikethrough, code, code blocks, links, headings, lists, quotes, rules, tables; anything else stays text; no library) and one writer per format:
  - Telegram: HTML with `parse_mode: "HTML"`, escaped; a 400 from Telegram resends the same reply as plain text, so formatting can never stop a reply.
  - Slack: mrkdwn (`*bold*`, `_italic_`, `~strike~`, `<url|text>`), with `&`, `<`, `>` escaped.
  - WhatsApp: its own marks (`*bold*`, `_italic_`, `~strike~`, code), links as "text (url)".
  - Email: an HTML body next to the plain-text one.
  - Jira: Atlassian Document Format with marks, nested lists, code blocks and tables (before, paragraphs of raw text).
  - SMS, iMessage, Messenger, Feishu: plain text; links as "text (url)", list bullets kept.
  - Discord, Teams and Linear render Markdown themselves and get it unchanged.
  - Tables become aligned monospaced text where the app has no tables, and real tables in email and Jira. Only `http(s):`, `mailto:` and `tg:` links become links.
- **Splitting:** `sendThrough` splits first (D-270) and each part is converted on its own. A part that ends inside a code block closes it and the next part reopens it (`balanceFences`); replies with code blocks split 32 characters under the limit to leave room.
- **Tests:** `packages/agent/test/channel-format.test.ts` (each format, escaping, snake_case and lone `*` left alone, tables, split code blocks, odd input never throws) and adapter checks in `packages/agent/test/channels.test.ts` (what each app is sent, the Telegram plain-text fallback).

## D-341 Typing, a seen reaction and approval buttons in Telegram

- **Decision (2026-11-17, Oliver: "why don't i get like `Typing` events in Telegram? And maybe more events? Like Hermes Agent does?", then "do 1, 2 and 5 now"):** between a message and the reply, a Telegram chat looked dead, and a run waiting for an approval stalled silently there. Three things fix that; progress lines and streamed replies wait for a plan.
- **Typing:** adapters get `typing(cfg, secrets, reply, f)`. Telegram sends `sendChatAction` `typing`; Messenger sends `sender_action: typing_on`. `startChannelTyping` (channels/service.ts) runs beside every run with trigger `channel`: it sends at once and every 4 s (the indicator lasts about 5), skips while the run's status starts with `waiting` (approval, takeover), stops on `failed` or `cancelled`, and `runAgent`'s `finally` stops it. Teams has a typing activity too but its token fetch per call isn't worth it yet.
- **Seen:** Telegram's adapter gets `acknowledge`, putting 👀 on an allowed sender's message as it arrives, as Slack's does with `eyes` (D-277). It stays, as on Slack; a reaction the bot makes later replaces it.
- **Approvals:** Telegram's `sendApproval` posts "Approval needed" with an inline keyboard (`approve:<id>`, `deny:<id>` as callback data). Presses come to the channel's own webhook as `callback_query` updates; the route sends them to the same `act` as Slack's (allowed list, this channel's bot and thread, decided as the connector). A new `settleAction` answers the press (`answerCallbackQuery`, showing the reason when refused) and swaps the buttons for "Approved by Ana." `ChannelAction` gains `senderName`, `callbackId` and `messageRef`.
- **Older Telegram bots:** `allowed_updates` now adds `callback_query`. The channel stores `telegram_updates` (the list it last asked for) instead of `reaction_updates`; a bot whose list differs is switched over on its next message, as D-331 did for reactions.
- **Tests:** `apps/server/test/channels.test.ts` (👀 only for allowed senders, typing repeats and pauses while waiting, the approval message and its escaping, a stranger's press refused, Ana's press approves and swaps the buttons, no run from a press).

## D-342 Files in chat apps, both ways

- **Decision (2026-11-17, Oliver: "I tried sending from telegram asking to generate an image but I didn't receive a preview or even a url … Cover everything", then "All. You decide too"):** a bot made two images for a Telegram chat and only its text reached Telegram; photos people sent were replaced by a "doesn't come through yet" note; and the bot didn't know it was in a chat app. Plan: `docs/CHAT-APP-FILES-PLAN.md`.
- **Out:** `replyToChannel` collects the run's generated `chat_media` rows (`uploaded_by` null) and its kept creations (D-276), sends the text, then each file through the adapter's new `sendFile` (or `sendBundle` for email: one message with attachments). One file plus text under the app's `captionMax` goes as one captioned message. Per-app `fileFits` picks native or link; at most 10 native files. A file that doesn't fit, is over 10, or fails to send goes as a line "📎 name (size): link"; failures are logged in the chat app's Activity, and the text is never held back. Links to the bot's computer in the text (`[report](~/report.pdf)`) keep only their words (`unlinkComputerFiles`), since the file goes along. The `channel.send` tool takes `files` (`media:`/`library:` ids, org-checked) too.
- **Signed links:** `GET /hooks/files/{token}` (under `/hooks` so Caddy, Helm and the tunnel already route it). The token is base64url JSON (`m` or `c`+`v`, expiry) with an HMAC keyed from `internalToken(env)`. Links last **7 days** (Oliver let me choose; 24 h is too short for people returning to a chat). The route looks the row up, so deleting a file kills its links; inline for pictures, video, audio and PDF, attachment otherwise; byte ranges; strict CSP. Twilio MMS uses the link as `MediaUrl`.
- **In:** adapters return `files` on `InboundMessage` (an opaque `fetch` per app) and implement `downloadFile`. `handleInbound` downloads up to 10 files of up to 25 MB through the server's outbound fetch, sniffs the type, and saves each in `chat_media` with `uploaded_by` = the connector and `in_library` false, counted against the connector's **daily attachment allowance** (300 files / 1 GB, the same as the app; my choice: one allowance per person is simpler and closes the abuse gap). The message gets `file` parts (`media:<id>`, `uploaded: true`), so vision, `partsText` and `files.from_chat` work unchanged. A file that can't be fetched becomes a note naming the file and the reason. Credentials only go to each provider's own file host (Slack `files.slack.com`, Twilio, Discord CDN). Strangers' messages are logged before any download.
- **Voice notes:** audio from a voice note is also transcribed with the workspace's `voiceTranscribe` and added as `[Voice note "…", transcribed: …]`.
- **Context:** runs with trigger `channel` get a hint naming the app and sender and saying files are delivered there (`chatAppHint`).
- **Per app:** Telegram (`sendPhoto`/`sendVideo`/`sendAudio`/`sendVoice`/`sendAnimation`/`sendDocument`, `getFile` with the 20 MB bot limit), Slack (external upload, `files:read`/`files:write` added to Casama's Slack app scopes), WhatsApp (media upload by kind and limits), Messenger (multipart), email (Resend attachments, received attachments listed), SMS (MMS images ≤ 5 MB), Feishu (image/file upload, message resources), Teams (inline images ≤ 1 MB, `downloadUrl`/`contentUrl` in), Discord (attachment on the interaction reply; an optional attachment option on `/ask`), Linear (`fileUpload`, uploads.linear.app links in), Jira (issue attachments), iMessage (through the Mac companion: `/imessage/new` returns attachments from chat.db, `/imessage/attachment/{id}` reads one, `/imessage/send` takes a file and sends it with osascript from an outbox; needs a desktop app build, until then files go as links).
- **Not now:** Teams file consent cards in personal chat; Telegram albums (`sendMediaGroup`); stickers, locations and contacts in.
- **Tests:** `packages/agent/test/channel-files.test.ts` (signing, expiry, forgery, unlinking, sniffing, each adapter's send and download, token hosts), `apps/server/test/channel-files.test.ts` (Telegram photo in → `chat_media` + file part, strangers' files never fetched, too-large note, generated image → `sendPhoto` after the text, a refused file → signed link that opens with ranges, 404 for expired, forged and deleted), `dart/computerd/test/companion_test.dart` (attachments from chat.db).

## D-343 Packs: everything you add is a plugin

- **Decision (2026-11-17, Oliver: "go and build in a separate worktree. finish everything in 1 go", on docs/PLUGINS-AND-PACKS-PLAN.md with every §13 decision at its default):** what people add to Casama comes as a plugin; the core (built-in apps, starter bots, coding agents, model providers) is not one. A **pack** is an Agent Plugins 1.0 plugin plus `com.casama/pack.json`, which brings whole bots, routines, apps, workspace skills and looks in one install. One package, not a second format: other apps reading the format ignore `com.casama/`.
- **Format** (`packages/domain/src/packs.ts`, `checkPack`): `pack.json` (`format: "casama.pack"`, `version: 1`, icon, summary, up to 6 `inputs`, `needs.apps`, up to 12 `includes`, `workspace_skills`, `examples`), `bots/` (gallery bot format plus `skills`, `routines`, `tools`, `rules`, `knowledge`), `routines/`, `apps/<id>/app.json`, `looks/`. Limits 5 bots, 30 skills, 20 routines, 12 apps, 12 looks, 12 includes, 20 rules and 5 knowledge sources per bot. `{{key}}` placeholders; a time answer also gives `{{key.hour}}`/`{{key.minute}}`. Bots never start `autonomous` (lowered to `ask_risky`); rules only narrow (`ask`, `hand_off`; allow rules are dropped). Reach is worked out from the files: code, computers, hosts (servers, apps, knowledge), secrets, settings, weekly scheduled runs, knowledge pages.
- **Plugins gain settings** (`extensions["com.casama"].settings`: non-secret values filling an env var or header, editable later, `PATCH /v1/plugins/{id}/settings`) and **private repositories** through `GITHUB_API_TOKEN` (server) or the workspace's `GITHUB_TOKEN` secret.
- **Install** (`apps/server/src/services/packs.ts`, `plugin-install.ts`): preview (`POST /v1/packs/preview`, from a link and commit, a directory id, a share token or uploaded files) then `POST /v1/packs`. Every item is made through the same internal API calls a person's own would use, so bot limits, model policy and permissions apply unchanged. Workspace skills need an admin; for anyone else they're skipped with a note rather than a per-item approval. Routines from a pack Casama hasn't reviewed start off. Tools: the plugin is installed on each bot that names tools (all bots when none do). Files are stored in `pack_files` at install, so a pack outlives its repository. `pack_items` keep a content hash so updates know what the person edited.
- **Gallery rules now cover plugins from a link** as well as packs: policy keys `plugin/<id>` (directory), `repo/<owner>:<repo>` (link), `pack/<name>` (file or share). When an admin must approve, the whole install waits (`gallery_approvals.item_type = 'pack'`, answer 202); approving a `repo/` request adds it to the allowed list.
- **Updates** show a diff by kind with `reach_grew` (new hosts, secrets or servers must be confirmed); edited items stay unless `take_theirs`; items the new version drops stay with the person. Rules and knowledge are only created with a new bot. **Removing** takes tools and unedited items; bots stay unless `bots=delete`.
- **Share as pack** (`POST /v1/orgs/{id}/packs/export`, `/share`): personas, skills with files, scheduled routines, apps by name, plugins by link and commit, optionally a look. Never memories, chats, files, sign-ins or secrets; every file is scanned for key shapes and the workspace's own secret values. Share links last 30 days for signed-in viewers, can be revoked, reported (`pack_share` report target) and taken down.
- **Pack apps** join that workspace's catalog as `<pack>.<app>` (`pack-apps.ts`); they can't take a built-in or gallery app's name for a different host.
- **Packs shelf:** `GET /v1/gallery/packs` lists directory plugins that are packs, with contents computed on the server and cached by commit (the gallery checker can't fetch GitHub). Gallery rewards apply to packs (the same three tiers).
- **First-party packs** in `packs/`: Founder kit, Dev kit, Meetings handled. They pass `plugin-check --strict` and install in the server test; they can be listed in the gallery's `plugins.json` once pushed (a listing needs a real commit).
- **Tools:** `casama init pack`, `casama packs preview|install|list|update|remove|export`, `client.packs` (TS and Dart), MCP `list_packs`, `preview_pack`, `install_pack` (no secrets over MCP), plugin-check prints the pack, the agent kit's `casama-plugin` skill, `docs-site/develop/packs.md`.
- **Storage:** `packs`, `pack_items`, `pack_files`, `pack_shares`; `plugins.pack_id` (settings live in the plugin's config); the shelf cache is in memory, by commit. RLS with `allow_worker`; pgTAP in `supabase/tests/packs_rls.test.sql`.
- **Tests:** `packages/domain` pack tests, `apps/server/test/packs.test.ts` (preview, install with rules and knowledge, settings, update with edits and reach, approvals, link policy, export/share/report, remove, shelf, first-party packs), CLI `init_test.dart`, client and MCP tests, and the app's widget tests for its pack screens.
- **App** (`client/lib/features/packs/`): a Packs row on the gallery home, the pack page and install wizard (tick items, questions, keys and settings, what it can reach, results with Connect and Use), Add from a link or a `.zip` file, Installed packs with update diffs and remove, Share as pack in workspace settings (key findings, link, Save as file as a `.zip`), plugin settings and "From the … pack" on a bot's Plugins page, and `repo/`/`pack/` keys in the gallery rules. Open links `casama.ai/open/pack?url=…` and `/open/packs/share/<token>` route to the app.
- **Not done:** tools on your own computer (built in D-344; a real Mac run is left), cards for a plugin's tools (built in D-345), "Submit to the gallery" from Share as pack, the web page and universal-link paths for `/packs/share/*`, a Share as pack button on a bot's page (the screen takes `?bot=`), and coding agents or model providers as plugins (decision 11: no). No live check on a device yet.

## D-344 Plugin tools on your own computer

- **Decision (2026-11-17, plan item 35 / Phase 6(b) of docs/PLUGINS-AND-PACKS-PLAN.md):** a plugin's stdio servers can run on the installer's own paired computer through the desktop companion (D-096), not only on the bot's computer (D-121). Remote servers are unaffected. The smallest honest version: one place per plugin install, chosen at install.
- **Choosing:** `device_id` on `POST /v1/plugins` and `POST /v1/packs` (a pack applies it to every tools install it makes; an update keeps where the tools run). The device must be the installer's own, in that workspace, set up for bots, with "Local tools (MCP)" on, and online at install (`device_not_yours` 403, `device_off`/`device_no_mcp` 400, `device_offline` 409). The app offers "The bot's computer" or "My computer: <name>" only when the preview has stdio servers and the person has such a computer online.
- **Storage, no migration:** each stdio server becomes a `local_mcp` connection (not `computer_mcp`) whose config carries the plugin's command, args, env, cwd and `secret_env` as before, plus D-096's `device_id`, `computer_id`, `owner_user_id`, label and timeout, and `bridge_key` (the connection's name, unique in the workspace). Secrets stay in Vault. Being `local_mcp`, the existing D-131 filters apply unchanged: tool loading, starters, `connections.list`/`attach` and attach-by-API only offer them to the owner. `LocalMcpAdapter` calls `/mcp/<bridge_key>`. The app's own `PUT /v1/local-devices/{id}/mcp-servers` ignores plugin rows (`plugin_id is null`), so neither list replaces the other.
- **Pushing to the computer:** the API (which holds the device sockets) talks to the companion's computerd through the tunnel (`syncCompanionPlugins`, `services/companion-plugins.ts`): `GET /plugins` (commits there), `PUT /plugins/<name>` (`{commit, files}`, only when the commit changed) and `PUT /plugin-servers` (the whole list, with secret env values). It runs after install, update, settings changes and removal, and on every device connection, because computerd keeps plugin servers in memory only (no secrets on disk). The worker's tunnel route refuses `/plugins` and `/plugin-servers`, so a run can't push code.
- **computerd (companion mode, needs `mcp`):** packages live in `<COMPUTERD_PLUGINS_DIR or ~/.casama>/plugins/<name>/` with `.casama-commit`, data in `plugin-data/<name>/`, outside the shared folders so bots can't edit the code. computerd resolves `./` commands and cwd, `${PLUGIN_ROOT}` and `${PLUGIN_DATA}` in args, env values and cwd, sets `PLUGIN_ROOT`/`PLUGIN_DATA`, checks cwd stays inside those folders, and deletes packages no server uses (data stays, as on the bot's computer). Plugin servers sit next to the user's own servers in `McpBridge` (the user's win on a key clash); changed servers restart on their next call. The endpoints are 404 outside companion mode.
- **D-131's rule in the tunnel:** a call to `/mcp/<bridge_key>` of a plugin placed on that computer is allowed when the run's bot has that connection and the run acts for the computer's owner, even if the bot isn't in the computer's allowed bots: placing the plugin authorizes exactly those servers, nothing else (no shell, files or browser). Anyone else's run gets "These tools run on someone else's own computer, so only they can use them from their own chats." Runs for other people also get a context line naming those plugins and whose computer they're on, so the bot can say why. Offline computers give D-096's offline message; nothing is marked broken.
- **Who changes it:** only the owner updates the plugin or changes its settings (`plugin_on_others_computer` 403); anyone who manages the bot may remove it, which removes the servers and the package from the computer. `Plugin.runs_on` (`device_id`, `device_name`, `owner_user_id`, `online`) feeds "Runs on <device>" on the bot's Plugins page.
- **Limits:** one folder per plugin name per computer, so two bots with the same plugin at different commits share the last one pushed; packages travel as one tunnel message (up to the 10 MB plugin limit); the tools run with the person's own OS and what's installed there.
- **Tests:** computerd `plugin_servers_test.dart` (package, `./` command, variables, secrets in env, cwd, removal keeps data, unsafe names and paths, capability, bot computers refuse); API `plugin-companion.test.ts` with a real computerd in companion mode (someone else's computer refused, install with tools listed through the tunnel, calls in the owner's runs with secrets and settings, refused in a teammate's run, the context line, offline then re-pushed on reconnect, owner-only settings, removal by a manager deletes it from the computer); widget test in `plugins_test.dart` (the choice appears only with a capable computer, install sends it, the card says where).
- **Not done:** a run on a real Mac (Oliver), moving an installed plugin between computers (uninstall and install again), and the desktop app keeping plugin servers across a computerd restart without a reconnect.

## D-345 Cards for a plugin's tools

- **Decision (2026-11-17, Oliver approved docs/PLUGIN-CARDS-PLAN.md with every decision at its default):** a plugin may show a tool's result as a card. One file per MCP tool, `com.casama/cards/<tool>.json`, names a component of the catalog the apps already draw (D-086 basic A2UI plus Casama's own: D-310, D-335, D-337), with `{{result.path}}` bindings into the tool's result. No new widgets, no HTML, no WebViews; card buttons send the person's answer as a message like any card's (D-086), never call a tool, so approvals and rules still apply.
- **Format** (`packages/domain/src/plugin-cards.ts`, `checkCardFile`): `"format": 1` (required; a newer format is skipped, so older servers show text), then either `"card": "<Component>"` with that component's fields on the file, or `"components": [...]` (a flat list with a `root`, at most 60). Optional `when`: a result path that must have a value (not missing, empty, `false` or an empty list), else the result stays text. Bindings: `result.a.b`, `result.items[0].x`; inside a list field a row with `"each": "result.items"` repeats per item with `{{item.x}}` and `{{index}}`, `max` 1–60 (default 20). A string that is one whole binding keeps the value's type (numbers, lists, booleans: chart values, attendees); a missing one drops the field; inside other text it becomes empty. Filled strings are cut at 2,000 characters, a filled card at 64 KB.
- **One validator:** the catalog and its checks moved from `packages/agent/src/tools/ui.ts` to `packages/domain/src/a2ui.ts` (`checkComponents`, `UiCheckError`), so `ui.show`, the plugin checker and the run use the same code. `ui.show` turns `UiCheckError` into its `invalid_arguments` ToolError as before. Card files are checked with `{template: true}`: a string holding a binding passes any field's type check, an `each` row counts as one row, and component names must be in the catalog. The filled card is checked again without it.
- **Checker** (`checkPlugin` → `checkPluginCards`): an unknown component, a binding Casama can't fill (`{{env.X}}`, unclosed `{{`, `item` outside `each`), a wrong field or a bad file name is skipped with a warning ("Skipped the card for X: …"), so the plugin still installs and `plugin-check --strict` fails. Cards in a plugin without MCP servers are ignored. Up to 100 cards of 64 KB. plugin-check prints "Tools shown as cards" and `--json` has `cards`.
- **Install:** the checked cards go in `plugins.summary.cards` (the `com.casama/` files still aren't copied to the computer). No migration.
- **Run** (`run.ts`): `loadIntegrationTools` joins the plugin's summary and puts the tool's card on its spec. MCP adapters (remote, local, computer) pass `structuredContent` through `CallToolOptions.onStructured`; the card reads it, else the text parsed as JSON, else the text. After a successful call the run fills the card, checks it, adds the same Send/Skip `ui.show` would, and emits `ui.shown` (with `plugin_card: <tool>`), so the reply keeps it as a `ui` part. The model gets the plain result plus "Shown to the person as a card, so don't repeat it in full: add only what matters." Unlike `ui.show` the turn doesn't end. A fill that doesn't match `when` or doesn't check leaves the text; the reason is logged at info ("plugin card not shown") for the author.
- **App:** no change. Numbers in text fields already render; older apps skip components they don't know.
- **Dev kit** (`packs/dev-kit`) gains a tool server (`server/github.mjs`, plain Node, no key): `get_pull_request` (Details card) and `list_pull_requests` (Results card) for public repositories, with `structuredContent`. Its reach now says it runs code on the bot's computer. It still passes `plugin-check --strict` and installs in the packs test.
- **Tests:** `packages/domain/test/plugin-cards.test.ts` (both shapes, refusals, skipping, fill with `each`/`max`/types, `when`, a fill that fails the check, result parsing), `packages/plugin-check/test/check.test.ts` (cards listed, bad ones warned, Dev kit strict), `apps/server/test/plugin-cards.test.ts` (installed from a fake GitHub with the fake computer's MCP server: a card shown with the model told so, `when` not matching → text, a broken fill → text). The existing `ui.show` tests pass unchanged.
- **Not done:** live updates to a shown card, cards for tools that aren't from a plugin, optional secrets (so the Dev kit could take a GitHub token for private repositories and a higher limit), and a live check in the app.

## D-346 Zoho through a pasted MCP server URL

- **Decision (2026-11-17, Oliver asked for Zoho MCP support):** Zoho is a built-in app. Zoho MCP
  (mcp.zoho.com) has no fixed endpoint and no MCP OAuth for clients: each person builds a server
  from the Zoho tools they pick (Mail, CRM, Desk, Projects, Books, Cliq…) and gets a URL with an
  API key in it, `https://<server>-<id>.zohomcp.<dc>/mcp/<key>/message` (some products put
  `?key=` in the query instead). Zoho then signs the person in to each app on first use.
- **Catalog:** `AppApiKeyHelp.serverUrl: { hosts }` marks an app whose "key" is the person's
  server URL. `appServerUrl` accepts only https URLs (http on localhost for tests) without
  credentials whose host is one of the hosts or ends in `.<host>`; Zoho's list covers its data
  centres (`zohomcp.com`, `.eu`, `.in`, `.com.au`, `.jp`, `.ca`, `.sa`, `.uk`, `.com.cn`). A
  pasted URL anywhere else gets 400 before anything is saved, so the server can't be pointed at
  an arbitrary address.
- **Storage:** the full URL is the connection's Vault secret; the config holds only its origin and
  `url_in_secret: true`, because members can read config. `McpAdapter` uses the secret as the
  endpoint and sends no auth header. No migration, no app change: the connect sheet already shows
  the steps, label and placeholder and hides what's pasted. The app bundles Zoho's mark.
- **Tests:** `apps/server/test/apps.test.ts` (wrong host, not a URL and a bare key refused; a
  pasted URL connects and lists tools; the key isn't in the API's answer or the config; a wrong
  key reports an error like a wrong API key).
- **Not done:** a live check against a real Zoho MCP server, and Composio's Zoho toolkits as a
  managed sign-in.

## D-347 Everyday tools on bot computers

- **Decision** (Oliver, 2026-11-17: "Should we get our server / bot computers pre-installed with some useful cli, or tools?", then "Yes to all, commit then deploy"): the computer image ships the tools bots reach for in ordinary requests, developer and consumer alike.
- **The rule:** anything that needs root goes in the image, because the bot runs as `casama` and can't apt-install; a missing system tool sends it hunting for workarounds. Fast-moving CLIs that install into the home folder stay out: the coding agents (Claude Code, Codex, Cursor, installed on first use, `packages/agent/src/tools/coding.ts`) and the cloud SDKs. The home folder is archived on sleep, so a first-use install is kept.
- **Added to `Dockerfile.headless`:** gh (GitHub's apt repo), git-lfs, sqlite3, postgresql-client, openssl, rsync, tree, fd, htop, bc; ImageMagick, exiftool, libheif with its HEVC decoder plugin (iPhone HEIC; `--no-install-recommends` leaves the decoder out), webp, graphviz; ocrmypdf, Ghostscript, pdftk; Tesseract languages spa, fra, deu, por, ita, jpn, chi_sim, kor; unar, 7z; zbar; Noto CJK fonts (CJK pages rendered as empty boxes in screenshots and PDFs); uv in /usr/local/bin; Python pillow-heif, icalendar, vobject, qrcode, segno, matplotlib, beautifulsoup4, requests, and python-pptx and python-docx, which the bot's context already claimed were installed. About 400 MB more image, one copy per server.
- **Left out:** calibre, Whisper and rembg (large, slow on CPU, and the models do transcription, speech and image edits better); yt-dlp and torrent clients (legal risk).
- **The bot knows:** the cloud computer context lists what's installed and says apt-get won't work (`COMPUTER_TOOLS` in `packages/agent/src/context.ts`).
- **Skills that use them:** convert-photos, scan-to-pdf, calendar-invite and shrink-file in `skills/` and the gallery. Icons are ones shipped apps already map.
- **Check:** `scripts/computer-tools.sh` smoke now also starts gh, convert, ocrmypdf, uv and imports the new Python libraries. apt packages update with image rebuilds, not D-251 pins.

## D-348 Home folder limit on cloud computers, and what bots are told about it

- **Decision** (Oliver asked, 2026-11-17: "What happens if users ask their bot to install or save stuffs in their computer… and what if we push new server images", then "Yes to all" to a context note and a size limit): a cloud computer keeps only its home folder (sleep archives it and deletes the container; waking restores it onto the current image, D-251), so the bot is told what that means and is held to the size the Storage card already showed.
- **What the bot is told** (`homeFolderText` in `packages/agent/src/context.ts`, private and team computers, not personal ones): its home folder holds up to `computers.size.disk_gb` GB (default 10) including installed tools and caches; when full, files.write is refused and it should delete things, caches first; programs it started stop when the computer sleeps and /tmp is cleared; the system underneath gets updated while home stays, so a tool it installed itself that stops working (missing library, changed Python or Node) should be reinstalled.
- **The limit** (`withDiskLimit` in `packages/agent/src/disk-limit.ts`, wrapped around the computer handle in `run.ts`): Docker's local volume driver can't take a size, so the worker checks. It reads the home folder's size from the `/tmp/.casama-du` cache the vitals and Storage reads keep (measured the first time, refreshed in the background after a minute), at most once per 30 s per tool call. Over the limit, files.write fails with `disk_full`; shell commands still run, because the bot needs them to delete things, and end with a note saying the folder is full. A size that can't be read lets everything through.
- **Soft, on purpose:** one command (a big download) can still go past the limit, and the note comes after it. A hard cap needs a filesystem with project quotas (XFS pquota) or a volume driver that takes a size; not worth it until a computer actually fills the host's disk, which the capacity alerts watch (D-252).
- **Not covered:** personal computers (the person's own disk); browser downloads, which go through the browser rather than the handle's writeFile.
- **Tests:** `packages/agent/test/disk-limit.test.ts` (writes refused and commands noted over the limit, the exit code kept last, one look per 30 s, unreadable size lets it be, `disk_gb` default, the prompt text). The usage script was also run in `casama/computer-headless:d347` (read-only root, user 1000): an `npm i -g` lands in `~/.npm-global` and is counted, and a stale cache answers at once and refreshes behind.

## D-349 Zoho's apps through Composio's managed sign-in

- **Decision (2026-11-17, Oliver chose "Composio first, then our own Zoho app"):** Zoho Mail,
  Zoho CRM, Zoho Desk and Zoho Books are built-in apps that connect with one click through
  Composio's managed sign-in (D-172): no URL, no key. Zoho has no MCP sign-in a client can
  register with (D-346), so this is the quickest way to give people a real "Sign in with Zoho".
  Composio's toolkits: `zoho_mail`, `zoho` (CRM), `zoho_desk`, `zoho_books`; Composio also
  manages Invoice, Inventory and Bigin, which can be added the same way. Calendar, Projects,
  People and WorkDrive have no Composio-managed sign-in.
- **Catalog:** the four apps list only `auth: ["managed"]`. `catalogFor` drops apps whose only
  way in is the managed sign-in when the server's Composio is off, and `POST /v1/apps/connect`
  with `method: "managed"` now always needs the server's Composio on, even for an app that
  lists it. The pasted-URL app (D-346) is renamed **Zoho MCP** and stays for every other Zoho
  app and for servers without Composio. Each app has Zoho's mark in the app; `url` is Zoho's
  site, never called.
- **Costs:** Composio usage per tool call, already in docs/COSTS.md.
- **Next:** Casama's own Zoho app (a Zoho OAuth client and a Casama-hosted MCP server over Zoho's
  APIs, per data centre), so Zoho works without Composio; it gets its own plan first.
- **Tests:** `apps/server/test/google-permissions.test.ts` (listed with Composio, hidden without
  it, Zoho MCP always). Checked against the real Composio account locally: the catalog lists the
  four and connecting Zoho Mail returns Composio's sign-in link.

## D-350 Casama's own Zoho sign-in: one connection for Mail, CRM, Desk and Books

- **Decision (2026-11-17, Oliver: "Go and build it now"):** Casama has its own Zoho OAuth client
  ("Casama", a Server-based application under the hello@casama.ai Zoho account, all data centres
  on with one secret; Vaultwarden "Casama Zoho OAuth client (D-350)"). A new built-in app
  **`zoho_apps` ("Zoho")** signs in once and covers Zoho Mail, CRM, Desk and Books. It changes the
  plan's draft (docs/ZOHO-APP-PLAN.md) in two ways: **one sign-in, not four**, because Zoho keeps at
  most 20 refresh tokens per person per client and four apps would each burn one; and **no new
  integration kind**: it's `kind: "mcp"` with `config.provider: "zoho"`, because the DB check
  constraint and the shipped apps' strict `IntegrationKind` enum would break on a new kind.
- **Sign-in:** the connect route builds Zoho's authorize URL itself (Zoho has no OAuth discovery):
  `accounts.zoho.com/oauth/v2/auth`, comma-separated scopes, `access_type=offline`,
  `prompt=consent`, PKCE S256. Zoho hands people in other data centres to theirs and the callback
  carries `accounts-server`, which must be on Zoho's list (`accounts.zoho.{com,eu,in,com.au,jp,sa,
  uk,ca,ae,sg}`, `accounts.zohocloud.ca`) before the code and client secret go there; China is out
  (it needs its own client). The token answer's `api_domain` must be a `zohoapis` host. The secret
  is the usual OAuth JSON with the regional token endpoint as metadata, so the generic refresh in
  `loadIntegration` (D-271 lock) refreshes against the right data centre.
- **Discovery:** right after sign-in Casama asks Mail (`/api/accounts`), CRM (`/crm/v8/org`),
  Desk (`/api/v1/organizations`) and Books (`/books/v3/organizations`, default org) which the
  account has, and keeps the ids in `config.zoho` (no secrets). Apps the account lacks get no
  tools; with none of the four the sign-in fails with a plain message. Zoho's consent page makes
  people without some apps tick "I understand I cannot grant all permissions", which is expected.
- **Tools:** `ZohoAdapter` (packages/agent/src/zoho.ts) calls Zoho's REST APIs with 28 hand-picked
  tools: Mail search, recent, read, folders, send, reply, draft, mark/move; CRM modules, search,
  get, create, update, note; Desk list, search, get, update, comment, reply; Books invoices,
  invoice, contacts, bills, create contact, draft invoice, send invoice. Reads are low risk,
  writes medium, and sending (mail send and reply, Desk reply, Books send invoice) high, so they
  ask first. Results are structured for cards. Zoho errors become ToolErrors: an expired or revoked
  token says to reconnect, rate limits say the daily limit is used up, a missing scope says
  reconnecting grants it.
- **Catalog:** `zoho_apps` has `hiddenWithoutClient` (shown only with `ZOHO_OAUTH_CLIENT_ID` and
  `ZOHO_OAUTH_CLIENT_SECRET` set); the four Composio tiles (D-349) have `replacedBy: "zoho_apps"`
  and hide where it's set up, so servers without the client keep D-349's tiles. Zoho MCP (D-346)
  stays for other Zoho apps. Existing Composio Zoho connections keep working.
- **Costs:** none to us; Zoho's daily API limits are per person's Zoho plan (docs/COSTS.md).
- **Tests:** `apps/server/test/zoho-app.test.ts`: a fake Zoho reached through the injected fetch,
  so real host names apply. Catalog swap, sign-in via the EU data centre, a forged accounts server
  refused before any token request, discovery (no Desk, the default Books org), refresh at the EU
  server, tools, risks, and a revoked token reading as reconnect. **Live check (local stack,
  2026-11-17):** a real sign-in with hello@casama.ai (US data centre, Mail only) connected, and
  mail_list_folders, mail_list_recent, mail_search, mail_read, mail_save_draft and mail_send all
  worked against the real mailbox. CRM, Desk and Books are covered by the fake only so far (the
  account has none of them).

## D-351 File work without a computer, and chat apps hear "On it"

- **Decision** (Oliver, 2026-11-17, from a Telegram chat where the bot remade a picture instead
  of cropping it, then "Server image tool" and all four extra tools): a bot can crop, convert,
  read and combine files kept in the chat on the server, so it works on the real file even with
  no computer, or on the person's own Mac with no shared folders (where `files.from_chat` has
  nowhere to write).
- **Tools** (`packages/agent/src/file-ops.ts`, registered in `tools/autonomy.ts`, low risk, take a
  `media:` id or a computer path): `media.image.look` (size, and a small copy for vision models,
  so boxes are right), `media.image.edit` (box or shape crop with a focus, resize, rotate, flip,
  PNG/JPEG/WebP, quality; metadata such as GPS dropped), `documents.read` (PDF, DOCX, CSV,
  Markdown, HTML, text through the knowledge parsers of D-125, 40,000 characters at a time,
  untrusted), `documents.pdf` (combine PDFs and pictures, keep/reorder/drop pages, rotate, split,
  up to 50 pieces), `media.qr.make` and `media.qr.read`. Results are kept like generated media
  (`chat_media`, the Library), so they show under the reply and go out to chat apps (D-342).
- **Libraries:** sharp (libvips, prebuilt for amd64 and arm64; its install script stays off),
  pdf-lib, qrcode, jsqr. Pictures over about 50 megapixels are refused. Not covered: iPhone HEIC
  (sharp's prebuilt libvips has no HEVC decoder; the computer has one, D-347) and video.
- **PDF and Word files** (`documents.make`, `packages/agent/src/document-make.ts`, plan in
  `docs/DOCUMENT-FILES-PLAN.md`, approved 2026-11-17 with "Yes add those languages" and "All is
  approved"): Markdown read with marked's lexer into a small block model, written with pdfmake
  (Roboto, which it ships; Courier for code) or docx (Calibri, Consolas). Plain look, page numbers,
  A4 or Letter, pictures by `media:` id. Limits: 200 pages and 10 MB out, 300,000 characters in.
  pdfmake reads no URLs and only the font files it's given.
- **Chinese, Japanese and Korean in PDFs:** the server image copies only `NotoSansCJK-Regular.ttc`
  and `NotoSansCJK-Bold.ttc` from Debian's `fonts-noto-cjk` (39 MB; the package is 91 MB with Serif).
  Runs of CJK characters get the CJK font; Han characters follow the document's language (kana
  means Japanese, Hangul without kana means Korean, else Simplified Chinese). `CJK_FONT_DIR`
  points elsewhere; without the fonts such PDFs are refused with a message. Word files leave fonts
  to the reader. Checked in the built server image: a mixed CJK PDF, QR round trip, WebP crop.
- **Chat apps hear the first line** (`sayInChannel` in `run.ts`): the line a bot writes before its
  first tool call ("On it, opening Google.") was saved in the app but only the final reply went
  to Telegram and the rest, so people there saw nothing until the work was done. It now goes to
  the thread as soon as it's saved, as its own message, in one-to-one and group conversations.
- **Leaked note:** Casama's note on a bot's past picture ("(You showed the person a generated
  image/jpeg: …)") was copied by a model into a Telegram reply. The note is now marked
  `[Casama note, not part of your reply: …]`, says how to reuse the file, and
  `stripEchoedUntrusted` takes both wordings out of replies.
- **Tests:** `packages/agent/test/file-ops.test.ts`, `document-make.test.ts` (each element read
  back through the D-125 parsers; the CJK case runs where the fonts are), the D-351 case in
  `autonomy.test.ts`,
  `apps/server/test/channel-interim.test.ts` (fails without the fix), and the echo cases in
  `context.test.ts`.

## D-352 Choose where links open on a phone

- **What:** Settings → App → **Open links in the app** (iOS and Android only, on by default, kept
  on the device). On: web links open in the system's in-app browser (Safari View Controller,
  Chrome Custom Tabs). Off: in the default browser app. Neither is a web view in the app.
- **Which links:** links in replies and bot UI, cards, map credits, Pages (D-092, which already
  opened in-app), gallery authors, photo credits, app help links and the status page, all through
  `openWebLink` in `client/lib/core/link_browser.dart`. If the in-app browser can't open a link,
  the default browser does.
- **Left in the default browser:** sign-in and OAuth returns, payment and billing links (store
  rules, D-297), provider key pages and gallery sharing (people are signed in there), update and
  download pages, mail links. Desktop always uses the default browser; the web opens a new tab.
- **Tests:** `client/test/link_browser_test.dart`.

## D-353 Filter usage by bot, model, source and person

- **What:** Settings → Usage gets filter chips under the period: bot, model, source and person.
  Each narrows every number on the screen; tapping a row in a breakdown filters to it, and the
  breakdown for a filtered dimension is hidden (it would be one row). **Clear** comes first in the
  row so it stays in view. Exports and "Ask a Bot" carry the filter in words.
- **API:** `GET /v1/usage` takes `bot_id`, `model`, `source` and `user_id`, and returns
  `by_source` (spend and runs). `user_id` is for admins, or your own id (members get **Just me**);
  anything else is 403. `by_person` (admins, D-275) is now shown in the app.
- **Source** comes from the run: a routine (`routine_id` set), the API (`trigger = 'a2a'`), a chat
  app (the conversation has a `channel_id`), else the app's chats; ledger rows without a run are
  `other`. Private conversations a viewer can't see count as chats for them (RLS on the join).
- **Choices** come from the unfiltered report for the period, so picking a bot doesn't empty the
  model list; with no filter it's the same request.
- **Tests:** the D-353 case in `apps/server/test/chat.test.ts`; the usage filter cases in
  `client/test/workspace_advanced_test.dart`.

## D-354 The shared model key goes to the cheapest provider first

- **Context:** credits ran out fast. In production (2026-11-13 to 17: 218 runs, 1,496 model calls)
  input tokens were 84% of model spend, and 19% of calls cost 2 to 7.5 times the model's list
  price and made up 47% of that spend.
- **Why:** a model's price on OpenRouter is its cheapest provider's. DeepSeek V4.1 Flash 1017 is
  sold by 50 providers, from $0.036 to $0.60 per 1M input tokens, and each keeps its own prompt
  cache. We sent no preference, so OpenRouter spread the calls: six identical test calls went to
  four providers, none of them the cheapest, and none hit the cache until the same provider saw
  the same prompt twice. A run's next step often landed somewhere new and paid full price for
  context the last provider had cached.
- **Decision:** calls on the server's shared key (`CLOUD_MODEL_UPSTREAM_KEY`) carry
  `provider.sort = "price"`, so OpenRouter tries the cheapest provider first and stays on it while
  it answers. It applies to bot runs and their background calls (the gateway), the support
  assistant and the Casama Link model proxy. `CLOUD_MODEL_PROVIDER_SORT` (`price`, `throughput`,
  `latency`, `off`) and `CLOUD_MODEL_PROVIDERS` (provider tags tried before the rest, in order)
  change it without a code change. `data_collection: deny` stays.
- **Not changed:** a workspace's own OpenRouter key. Its owner may have set routing on their
  OpenRouter account, and a request-level preference would override it. A request that names its
  own `provider` fields (a linked server's) keeps them.
- **Measured:** replaying production's traffic on the cheapest provider with the cache holding
  inside each run costs $0.79 against the $1.70 paid. With `sort: price`, 33 of 36 test calls went
  to the cheapest provider and the other 3 to providers that already held that prompt's cache.
- **Quality:** the cheapest provider runs a 4-bit copy of the model (mxfp4). Twelve tool-use
  tasks with Casama's real prompt and tools (right tool, valid arguments, using a result, ignoring
  an injected instruction, Spanish), twice on each of eight routes: today's spread 24 of 24, the
  cheapest route 24, the others 22 to 24, with the misses all the same harmless one (running a
  command again to check it). The cheapest route was also the fastest (about 1.0 s median against
  1.7 s). A small sample: if replies get worse, name fuller-precision providers in
  `CLOUD_MODEL_PROVIDERS` (`deepinfra/fp8`, `morph/fp8`), or set the sort to `off`.
- **Cheaper still, not chosen:** Sail Research would cost about $0.47 on the same replay (cheaper
  cached input and output) but answered three times slower.
- **Tests:** `packages/agent/test/openrouter-cloud.test.ts`,
  `apps/server/test/cloud-model-routing.test.ts`, and the routing checks in
  `apps/server/test/support.test.ts` and `apps/server/test/link-cloud.test.ts`.

## D-355 Making credits last: check-ins, the prompt cache, long tasks, voice and tools

- **Context:** the rest of docs/USAGE-PLAN.md, after D-354. In production (2026-11-13 to 17) chat
  was 45% of spend, voice calls 22% and check-ins 21%; 29 of 218 runs were refused at the daily
  limit; 15 of 39 scans ended with nothing to show; a chat message made about 10 model calls of
  about 25,000 input tokens each. Oliver took every default in the plan's decision table.
- **Check-ins read first.** A brief or scan makes its usual reads itself before the first model
  call, as if the model had asked: recent mail (`gmail_fetch_emails`), the next two days of
  `googlecalendar_events_list`, and `tasks.list` (`packages/agent/src/checkin-prefetch.ts`). The
  reads go through the normal tool step, so they are metered, capped and shown on the timeline.
  The model then judges in a step or two instead of 6.6.
- **An unchanged scan makes no model call.** The first reads are reduced to a digest (message ids,
  event ids and etags, the board as listed) kept in `bot_checkins.scan_digest`. A scheduled scan
  with the same digest ends there, at the price of the reads. Not when the scan was asked for
  (setup, a new app, an app event), when the bot has tools from any other app, when the person
  shares phone data with it, or when a read failed or came back in a shape we don't know.
- **A scan always ends with something.** The last step offers only `suggestions.add` (a brief: no
  tools) and says so; after it, or at the step limit, a scan ends as finished. Before, it failed
  with `max_steps_exceeded` and nothing saved. The scan and brief instructions now say there are
  few steps and to make independent calls together.
- **No memory pass after `NOTHING_NEW`.**
- **Limits.** `checkinCapReached` is also checked on every step, and is true once all of a
  workspace's check-ins have used 40% of the day's limit on Casama's key (`CHECKIN_DAY_SHARE`;
  a plan can set `checkin_day_share`). New bots' default limit is that share ($0.10 on Free).
- **Free checks in once a day.** `min_scan_hours` 12 → 24 in a migration (only where the plan
  still had 12). Two knock-on fixes: a once-a-day scan runs six hours after the brief, because
  "every 24 hours" is midnight, inside quiet hours, where a scheduled scan is skipped; and saving
  the sheet with an old value below the new floor raises it to the floor instead of answering 402
  (asking for more often still opens the paywall). The app's picker gains 24 hours.
- **Not built in check-ins:** Outlook's first read (no account to check the tool's arguments
  against), and running check-ins on the cloud's background model: the shared key allows only the
  chat model (`cloudModelIds`), the two are the same model today, and widening that rule is a
  billing decision of its own.
- **Long tasks have a fixed budget.** `trimTurn` also trims once a run's own steps pass 48,000
  tokens, down to 24,000 (`TURN_BUDGET`, `TURN_KEEP`), whatever the model's window. The window
  share (75%) was about 786,000 tokens on the default model and never reached.
- **The prompt cache holds across messages.**
  - A conversation remembers the tool groups its runs used (`conversations.tool_groups`), and the
    next run starts with up to 6 of them within 6,000 tokens, sorted. No `tools.load` step, and
    the same tool list as the last message. Adding a tool mid-run re-bills the whole context
    (measured: 0 cached tokens).
  - The date and time, the project and the turn's hints open the newest message in a
    `<casama-context>` block instead of sitting in the system text ahead of the history. The
    system text now changes only with the bot's settings, the person's profile, the summary or
    the recalled memories.
  - Memories stay in the system text, sorted so the same notes make the same text. Moving them
    next to the person's words was tried: in 36 live calls each way the default model never
    obeyed an order planted in a note, but only the system placement has held across the models
    people bring (D-269), and the saving was small.
  - Each run's calls on the shared key carry a `session_id`, so OpenRouter keeps the run on the
    provider that served its first call. Per run, not per conversation: a conversation pinned to
    a dearer stand-in provider would keep paying for it.
- **A faster provider for live chat, off by default.** `CLOUD_MODEL_CHAT_SORT` applies only to the
  model steps of chats, mentions and chat apps; routines, check-ins, background calls, the support
  assistant and the Link proxy keep `CLOUD_MODEL_PROVIDER_SORT`. `throughput` measured 171 tokens
  a second against 70, at about 3 times the cost on replayed traffic.
- **No model of our own.** The production server has no GPU; a rented 48 GB card costs $600 to
  $800 a month against about $10 of model spend, and holds only a much weaker model. Look again
  above about 3,000 runs a day, or when a customer needs data kept on our servers.
- **Smaller always-sent tools.** The core tools went from 4,922 tokens to 2,972.
  - `ui.show` (2,270 → 781) describes the common components; the rest come from a new read-only
    `ui.catalog`, which a refused card also points to. What the catalog accepts is unchanged.
  - `connections.offer` (496 → 228) no longer lists 39 app ids: it finds an app by name or id,
    and an unknown app still returns every id. `secrets.request` 327 → 261, `setup.apply` 296 →
    230.
  - No tool's schema carries the `$schema` line any more (13 tokens each), and `leanSchema()`
    keeps string length limits out of what the model reads on those five tools; the server still
    checks them.
  - `packages/agent/test/core-tools-size.test.ts` fails above 3,000 tokens for the core and 800
    for `ui.show`. Live check on the default model: cards for choices, a form and a map were
    valid 9 times of 9; a table now takes one `ui.catalog` lookup first.
- **Live calls carry less on every turn.** Gemini Live bills each turn for the whole session and
  has no prompt cache.
  - The call tools went from 14,926 characters to 4,334 (18 declarations to 14). Changing or
    deleting routines and watching things go through `start_task`; `routines.create` and
    `device.read` have short call-time schemas, tested against the real ones.
  - A call carries the first 1,500 characters of the persona and 600 tokens of earlier turns (it
    was the whole persona and 2,000).
  - `VOICE_CONTEXT_TRIGGER_TOKENS` (8000) and `VOICE_CONTEXT_TARGET_TOKENS` (3000) replace the
    32,000 → 16,000 literal. They count the conversation only; an estimate of the instructions
    and tools is added before they go to Gemini, which counts that fixed part toward both. A
    literal 8,000 → 3,000 would have kept only seconds of talk after each trim.
  - Measured on `gemini-3.8-live`, six text turns: 33,987 prompt tokens before, 12,826 after (62%
    fewer). A spoken call and Google's invoice are still to check. One open point: we record
    input from `promptTokensDetails`, which came out about 25% below `promptTokenCount`.
- **"Use your own AI" at the limit is not built.** On Casama Cloud every run is put on Casama's
  key and model (D-188), the daily limit and credits stop runs whatever key they are on, and the
  keys screen there takes no model keys, so the offer would be false. Three texts already made
  it: the daily-limit message, the app's line under the credits meter and the usage guide. They
  no longer say "add your own model key". Letting Cloud workspaces run on their own AI is a
  billing decision with server work behind it, for its own plan.
- **Not built:** the `tools.call` experiment (decision 6: only if remembered groups aren't
  enough), a lower thinking level on in-between steps (decision 7), and cheapest-first for
  people's own OpenRouter keys (decision 8).
- **Tests:** `packages/agent/test/checkin-fetch-first.test.ts`, the budget cases in
  `run-survive.test.ts`, the prompt order in `context.test.ts`, remembered groups in `run.test.ts`,
  routing and the session in `openrouter-cloud.test.ts`; `apps/server/test/checkins.test.ts`
  (the plan floor), `cloud-model-routing.test.ts`; `supabase/tests/plan_limits.test.sql`.

## D-356 Terminal and files while a person has the screen

- **Context:** a person took control of a bot's computer and asked in chat why it was slow. The
  chat said "Browsing the web…" under a "Paused: a person is in control" notice. Under D-058 every
  computer tool waits while a person holds the lease, and shell and file tools could carry on only
  with `allow_shell`, which the server accepted but no app ever sent.
- **Decision:** the live view's dock gets a **Terminal and files** switch while you're in control
  (off by default, sent with every lease renewal, since a renewal sets `allow_shell` again). The
  `Lease` response now carries `allow_shell` (optional, so new apps still read older servers).
  Turning it on mid-takeover wakes runs waiting on this computer at once instead of at their next
  5-minute check (`lease.shell_allowed` in the audit log). A run waiting on a shell or file tool then
  carries on without a hand-back: no `lease.changed` back to the bot, a `notice`
  (`shell_beside_user`) in the chat, and the model is told the person still has the screen, that
  browser and desktop tools wait, and not to use the shell to look at the screen. Before, it would
  have been told the person handed back.
- **Screen tools still wait.** One mouse, keyboard and focus: the bot's input would land in the
  middle of the person's, and screenshots during a takeover would break D-058's promise that
  nothing typed or shown reaches the model. A second browser for the bot doesn't help either,
  since Chrome locks a profile to one process and the takeover is usually there to sign in to it.
- **Why off by default:** from a terminal a bot can take screenshots or drive the browser, so the
  person chooses it, typically when they aren't typing anything private.
- **The working line:** while the newest control notice is "a person is in control" (or a bot's
  takeover request is unanswered), the chat says "Waiting for you to hand back the screen…" instead
  of the paused step's activity. A `notice` or the bot getting control back ends it.
- **Tests:** `apps/server/test/live.test.ts` (shell waits, switching on wakes the run, no
  hand-back), `client/test/live_test.dart` (the switch and renewals), `client/test/simple_chat_test.dart`
  (the working line).

## D-357 A spoken call measured, both prompt counts kept, and calls know the date

- **Context:** D-355 measured the smaller call set-up with typed turns only, and left two things
  open: what a real spoken call costs, and why Gemini's prompt total was larger than the per-kind
  counts we charge from.
- **Measured.** The same ten-turn call with real audio both ways (the Mac's voice in, Kore out) on
  `gemini-3.8-live`, at Google's list prices and counted from the per-kind breakdown:

  | | Before D-355 | After |
  |---|---|---|
  | Text input tokens | 62,320 | 22,050 |
  | Audio input tokens | 17,411 | 21,452 |
  | Cost a minute | $0.055 | $0.038 |

  Text input fell 65%; the cost a minute fell 30%, because what a short call mostly pays for now is
  its own audio so far, billed again on every turn at the audio rate (60% of the new call's cost).
  Trimming doesn't touch that in a call under about five minutes, and trimming sooner would make
  the bot forget the start of the call.
- **The two prompt counts.** Gemini's `promptTokenCount` was larger than the sum of its
  `promptTokensDetails` on every response: by 23,357 tokens over the old call and 9,232 over the
  new, about 37 to 44% on top of the text count. Google's replies on its developer forum say the
  per-kind counts are what it bills, which is what we charge from, so nothing changes in the
  charge. If it bills the total instead, the new call costs $0.041 a minute, not $0.038.
- **Decision:** keep the difference with each call, uncharged: `input_unattributed_tokens` next to
  the four counts in the relay's totals, the phone bridge's and the ledger row's `meta.tokens`.
  One day's invoice then settles it: compare Google's billed text input for the Live model with
  the sum of `input_text_tokens`, with and without `input_unattributed_tokens`. The app's own
  report doesn't carry it; a billable call is settled from the relay's count.
- **Calls know the date.** A call's instructions now carry the same "Today is …" line a chat
  gets, in the caller's timezone. Without it, "remind me tomorrow at nine" left the model to guess
  the date for the reminder's `run_at`. About 20 tokens a turn.
- **Not done:** the invoice comparison itself (it needs the billing console, and a day of
  production calls recorded with both counts).
- **Tests:** `packages/agent/test/gemini-live.test.ts`, `apps/server/test/live-relay.test.ts`,
  `apps/server/test/voice.test.ts`.

## D-360 Computer updates on the person's terms; live view survives deploys

- **Decision (2026-11-17, Oliver asked what happens to busy computers and live viewers on every
  deploy, then whether people could update their computers when they choose, then "write the final
  plan then let's get working"):** plan and details in `docs/COMPUTER-UPDATES-PLAN.md`.
- **What was true:** a running computer keeps the image it started from; idle sleep and wake (and
  Restart) already move it to the current image, so a computer update never interrupted anyone, but
  nobody could see one coming or choose the moment. Deploys recreate the API, which closed every
  live view's signaling socket; the app took that as "WebRTC blocked" and stayed on screenshots.
- **Updates:** the supervisor's `GET /computers/images` compares each running Docker computer's
  image with what its profile's tag names now (unknown ids count as current; pool members are left
  out). The worker's minute tick sets `computers.update_available_since` the first minute a computer
  is behind and clears it when it is current or not running; any start clears it. The API shows it
  on `Computer` and `POST /v1/computers/{id}/apply-update` (`force`) sleeps and wakes the computer
  (files kept), audited as `computer.updated`: 409 `no_update` when it's current, 409
  `computer_busy` while a command runs unless `force`. The app shows an **Update available** card
  under the computer's header (Update now; Later hides it for a day on that device) and **Update
  computer** in the live view's menu; a bot working on it is mentioned in the confirmation. Nothing
  is forced. Hosted providers and personal computers never get the prompt.
- **Live view:** the API closes live sockets with 1012 on shutdown. The app redials a stream that
  was cut (it had been live, or 1012) for about 45 s (1, 2, 4, 8, 15, 15 s), screenshots meanwhile
  and **Reconnecting…** in the chip, then settles on screenshots with **Try again**. A stream that
  never got live still falls back at once. Control comes back with the lease.
- **Deploys:** `scripts/deploy-prod.sh` prints, from `compose up -d --dry-run`, when the supervisor,
  egress proxy or TURN relay will be recreated (commands on computers are cut, live views
  reconnect).
- **Tests:** `packages/sandbox/test/image-status.test.ts`, `apps/supervisor/test/app.test.ts`,
  `apps/server/test/computer-updates.test.ts`, the 1012 case in `apps/server/test/live.test.ts`,
  `client/test/computer_update_test.dart`.

## D-361 Casama on Linux: the app, the dev stack and the tests

- **Decision (2026-11-17, Oliver: "can we get this running here in ubuntu?", then "our goal here is
  to verify our project works in linux", then "use it like a normal user and find Linux related
  issues to fix"):** checked on Ubuntu 26.04 (GNOME 50, Wayland), plus a virtual X display with no
  keyring, portal or tray for the bare-desktop cases.
- **Plugin exceptions:** `libflutter_linux_gtk.so` (Flutter 3.50) exports its own `_Unwind_*`
  functions. A plugin's C++ `throw` bound to them can't reach the plugin's own `catch`, so
  flutter_secure_storage aborted the app at start on any desktop without a Secret Service. The
  runner links `libgcc_s` first (`client/linux/runner/CMakeLists.txt`), which wins the lookup for
  every library. Drop it once the engine stops exporting the unwinder.
- **File dialogs:** file_picker on Linux only talks to `org.freedesktop.portal.Desktop`, and threw
  without one. `lib/core/linux_file_dialogs.dart` wraps `FilePickerPlatform.instance`: the portal
  first, GTK's own dialog (file_selector) when it's missing, so all fifteen pickers keep their code.
- **Desktop entry:** the GNOME portal grants the global shortcut, and `casama://` finds the app, only
  through a desktop entry named after the application id. A snap or flatpak brings one; otherwise the
  app writes `~/.local/share/applications/ai.casama.app.desktop` pointing at itself (rewritten when
  it moves), and the bundle carries `data/casama.png` for its icon.
- **Quitting:** tray_manager's native library frees leftover tray icons in a static destructor that
  runs after its own tables are gone (SIGSEGV on every quit). The desktop shell frees the icon when
  the window asks to close (`AppLifecycleListener.onExitRequested`) and when it stops (a server
  change had also left one icon per switch).
- **Window placement:** saved as the frame's corner and the content's size (`window.placement`), not
  the frame's size: set before GTK knows the decorations, a frame size became the content size and
  the window grew by its title bar every launch. The local cache opens once per process (a server
  change opened the drift database a second time).
- **Dev stack and tests:** the worker runs as `casama_worker` locally too (`supabase/seed.sql` gives
  it the password `.env.example` uses; local Supabase's `postgres` isn't a superuser and can't use
  the `dbos` schema). Relative fixture paths count from the repo root. Tests find Postgres 17 in
  `/usr/lib/postgresql/17/bin` as well as Homebrew's. `scripts/dev-up.sh` runs on Linux. The CLI exits
  when its command returns (a timer left in the SDK's run stream had kept `casama chat` open for two
  minutes).
- **Not changed:** the tray needs a StatusNotifier host (Ubuntu's AppIndicator extension; stock
  GNOME has none); everything in it is also in the window. Under Mesa's software renderer the engine
  can crash on quit inside libgallium (engine and Mesa, not ours).
- **Tests:** `client/test/linux_desktop_entry_test.dart`, `client/test/linux_file_dialogs_test.dart`,
  `dart/cli/test/init_test.dart` (now runs from `dart/` as CI does).

## D-362 T3 Code as a coding agent on the user's computer

- **Decision (2026-11-18, Oliver: "can we also get t3code scanned or listed?"):** the desktop app's
  Coding Agents scan also looks for `t3`, and `coding.delegate` takes `agent: "t3code"`, on
  my_computer only (like Pi: the user's own T3 setup and sign-ins, no install or key for the bot's
  computer).
- **How it runs:** `t3 thread start . <task> --wait --json` in the given folder. It runs the task
  as a thread in the running T3 Code app with the project's default model and permissions, and
  prints `{threadId, runId, status, reply, error}`; `summarizeAgentOutput` reads `reply` and
  `error`. A folder outside every T3 project is added with `t3 project add .` first (`t3 thread
  list` fails there). The folder is required: without one the command would run in the computer's
  default folder and could add the home folder as a project.
- **Exit 2:** T3 Code stopped to ask a question. The result says it's waiting for an answer and
  points the user to the thread instead of reporting a failure.
- **Not done:** no browser MCP (C16 is Claude Code and Codex only) and no commits made for it.
  T3 Code has to be running; if it isn't, the `t3` error comes back as the failure.
- **Tests:** `apps/server/test/coding.test.ts` ("runs T3 Code…", "reads T3 Code's reply…"),
  `client/test/local_mcp_test.dart`.

## D-363 Local MCP servers: sign-in, network addresses, import, and questions

- **Decision (2026-11-18, Oliver: "not just t3code support though can we widen it", then "build all
  now"):** plan in `docs/LOCAL-MCP-PLAN.md`. Local MCP servers on a paired computer can sign in,
  can live elsewhere on the network, can be imported from other apps, and can ask the person
  questions. Defaults taken for the plan's open questions: network and https addresses allowed
  with a warning, all seven importers, elicitation included, T3 Code gets every scope it
  advertises.
- **Headers:** an address server takes a token (`Authorization: Bearer`) or one named header. The
  values stay in the app's secure storage with the rest of the server; the workspace only gets
  `auth: none|token|header|oauth` on `LocalMcpServerInfo`.
- **Browser sign-in (MCP OAuth):** computerd's `McpOAuth` runs on the device: a 401 with
  protected-resource metadata (RFC 9728), server metadata (RFC 8414), dynamic registration
  (RFC 7591), PKCE S256 required, the `resource` parameter (RFC 8707), and the loopback redirect the
  desktop sign-in already uses. An authorization server on another host is refused. The bridge
  refreshes on expiry or a 401 (once, even with calls in flight), hands new tokens back to the app
  to store, and when it can't, raises `mcp_sign_in_needed`. The worker turns that into
  `local_mcp.sign_in_needed` (once per run per server) and a `sign_in_needed` tool error. The chat
  card has **Sign in** only on that computer; elsewhere it names the computer.
- **Addresses:** loopback http as before. With network on (set by the app when the address isn't
  on this computer, never by a pushed config or a plugin): https anywhere, plain http only for
  local network hosts (RFC 1918, CGNAT, link-local, ULA, single-label, `.local`, `.lan`,
  `.home.arpa`, `.internal`). Streamable HTTP first, legacy HTTP+SSE when the address ends in
  `/sse` or the server answers 404/405 without a session. A lost session (404 with one) is
  re-initialized once.
- **Import:** reads T3 Code (`~/.t3/userdata/server-runtime.json`), Claude Code (`~/.claude.json`,
  per-project too), Claude Desktop, Cursor, VS Code (mcp.json and settings.json, comments
  allowed), Codex (`config.toml`, a small TOML reader) and Windsurf. `${VAR}`, `${env:VAR}`,
  `${VAR:-default}` and `${input:x}` are filled from the app's environment; anything unset is asked
  for. Internet servers are listed but not picked by default. T3 Code's entry is browser sign-in
  and its address is followed when T3 Code moves port.
- **Questions (MCP elicitation):** hosted and local MCP clients declare `elicitation`. A question
  becomes an `mcp_questions` row (10-minute expiry; RLS read via `can_access_bot`; the `answer`
  column isn't readable by app users and is cleared once read), an `mcp.question` event and a
  "needs you" push to the run's creator. `POST /v1/mcp-questions/{id}/answer` (creator or admin)
  checks the answer against the form (flat: string, number, integer, boolean, enum). Expiry or a
  stopped run cancels it; `mcp.question_resolved` closes the card. Forms Casama can't show are
  declined without asking. Callers that don't declare elicitation get -32601 from the bridge.
- **Stdio PATH:** computerd resolves bare commands against the app's extra bin folders
  (`~/.local/bin`, npm-global, bun, cargo, volta, plus the existing ones), so imported `npx`/`uvx`
  servers start from a Finder-launched app.
- **Tests:** `dart/computerd/test/mcp_address_test.dart`, `apps/server/test/local-mcp.test.ts`,
  `apps/server/test/mcp-questions.test.ts`, `packages/domain/test/mcp-questions.test.ts`,
  `supabase/tests/mcp_questions_rls.test.sql`, `client/test/local_mcp_test.dart`,
  `client/test/mcp_import_test.dart`, `client/test/mcp_chat_test.dart`.

## D-375 App lock, checks before risky actions, and a workspace requirement

- **Decision (2026-11-18, Oliver: build the app lock "all in 1 go"):** an opt-in lock on each
  device, on every platform. It uses the system's own check where there is one: Face ID, Touch ID
  or the passcode on iPhone and iPad, BiometricPrompt with the screen lock on Android 9 and later,
  Touch ID or the login password on a Mac, and Windows Hello (`local_auth`, device credential
  allowed, so nobody needs biometrics). Linux, Android 8 and devices without a screen lock use a
  6-digit PIN. Only a salted PBKDF2-SHA256 hash (120,000 rounds, run off the UI thread) is kept, in
  the system keychain. Android 8 is on the PIN because BiometricPrompt's fallback dialog there needs
  an AppCompat theme the app doesn't use. The web uses one of the person's passkeys, checked
  against the Auth server's passkey endpoints directly (`confirmWithPasskey`). The client's own
  verify would replace the session, even with another account's passkey. The check's extra session
  is logged out at once, and a passkey of another account counts as a failure.
- **What it covers:** `AppLockGate` sits in `MaterialApp.builder`. While locked, the app below it is
  kept but not drawn (`Visibility(maintainState)`, which also stops its animations and taps) and
  can't take focus. The lock screen and the workspace setup screen have their own `Navigator` (with
  `HeroControllerScope.none`) for sheets. Links, notification taps and shares still go to their
  page, which shows once the person unlocks. A cover replaces the app in the app switcher on phones
  (any non-resumed state) and over a hidden window on computers and the web. On Android 13 and later,
  `setRecentsScreenshotEnabled(false)` blanks Recents while the lock is on, and **Block screenshots**
  sets `FLAG_SECURE` (`casama/app_lock` channel in MainActivity). iOS has no supported way to block
  screenshots, so the switch is Android only.
- **When it locks:** at every launch, and after the chosen time away (right away, 1, 5 or 15
  minutes, 1 hour; default 1 minute). Away is hidden or paused, and on a computer also inactive
  (behind other apps, asleep, screen locked), since the window stays visible there. A phone's
  inactive (Control Center, a call banner) isn't away. The lock's own prompts never count as time
  away (`AppLockController.prompt`). A fresh sign-in starts unlocked. The settings carry the user
  id, so another account on the device starts with the lock off and never meets someone else's
  PIN.
- **Never stuck:** the lock screen always offers **Sign Out**. Five wrong PINs stop the PIN pad, and
  an unavailable check (passcode removed, keychain unreadable) says so. Signing out from the lock
  screen turns the lock off and deletes the PIN, so signing in again opens the app. Other sign-outs
  (a session ending) keep the settings.
- **The sign-in in the keychain:** while the lock is on, the Supabase session lives in the keychain
  (`AuthSessionStore`, a supabase_flutter `LocalStorage`) instead of shared preferences, under
  supabase_flutter's own key, so nothing is lost when moving it either way. On iPhone the items use
  `first_unlock_this_device`, so background wakes (geofences, pushes) still read it. Any keychain
  failure falls back to the preferences instead of signing the person out (unsigned Mac builds,
  Linux without a keyring). The background backend (`device_events.dart`) uses the same store.
  **Not done on purpose:** binding the session to biometrics (`biometryCurrentSet`,
  `setUserAuthenticationRequired`). Every background path (push actions, App Intents, geofences,
  CallKit) would then fail while the phone is locked, and a fingerprint change would sign the
  person out.
- **The notch and the tray:** while locked, Allow, Deny, Ask and dropped files on a computer open
  the window instead. Stop and a call's controls still work. A phone's Lock Screen Allow and Deny
  are unchanged: they already need the phone unlocked for them (D-324), which is the same check.
  The island feed's titles still show on the notch, as notifications do.
- **Checks before risky actions** (`confirmIdentity`, on by default, with or without the lock):
  deleting the account, exporting data, a new AI app (MCP) key, Casama Link key or bot link, the web
  billing portal and extra seats, rotating the encryption key, allowing a high-risk request (in the
  inbox and in chat; from the notch it opens in the app instead), and taking control of a computer.
  It uses the lock's method when the lock is on. Otherwise it uses the device check, a passkey on
  the web when the person has one, or a PIN set earlier. With nothing to ask with it goes ahead:
  these checks are a client-side speed bump, not server-enforced re-authentication. Turning the
  lock off, changing the PIN and turning the checks off always ask.
- **Workspace requirement:** `organizations.require_app_lock` (migration 20270202600001), set
  through `PATCH /v1/orgs/{id}/settings` by owners and admins (members can't, in the API or under
  RLS), and returned on every workspace in `/v1/orgs` and `/v1/me`. When any of the person's
  workspaces requires it and it's off, the app shows **Turn On the App Lock** before anything else,
  and the switch can't be turned off. An admin turns on their own lock before requiring it, as with
  two-step sign-in. On the web without passkeys on the server there's no way to comply, so the
  browser can't be used for that account while the requirement is on: failing closed beats a
  requirement that silently doesn't apply. It's enforced by the app only; the API doesn't check it.
- **Hide reply text** (D-325) is also on the App lock page, as the same account-wide switch.
- **Tests:** `client/test/app_lock_test.dart` (PBKDF2 against published vectors, PIN storage, the
  session moving in and out of the keychain, lock timing, the gate, PIN and passkey unlocks, the
  workspace setup, the settings page, checks before risky actions),
  `client/test/island_feed_test.dart` (the notch while locked, a high-risk Allow opening in the
  app), `apps/server/test/app-lock.test.ts`, `supabase/tests/app_lock.test.sql`.
- **Not checked here:** the native prompts on real devices (Face ID, BiometricPrompt, Touch ID,
  Windows Hello), the Recents blank and `FLAG_SECURE` on an Android 13+ phone, and whether iOS takes
  its app-switcher snapshot after the cover is drawn. Flutter draws the cover on `inactive`, which
  usually comes first. A native snapshot view in the scene delegate would make it certain.

## D-370 Coding agents come from the signed gallery; new ones need one Allow

- **Decision (2026-11-18, Oliver: "build all now!", REMOTE-CONTENT-PLAN §2.1 with its defaults):**
  the coding agents list is `gallery/coding-agents.json`, first-party only and covered by the signed
  manifest (D-315). Adding an agent that fits the named behaviours is a gallery change, not a server
  deploy or an app build.
- **Entries:** id, label, bin, where, one command template per place, and named behaviours that
  stay in code: `result` (`json_result`, `marker`, `json_field:<name>`, `stream_json`, `tail`),
  `browser` (`claude`, `codex`), `commits_for_agent`, `needs_folder`, `exit_messages`, `min_server`.
  Templates take only `{task}`, `{folder}` and `{result_file}` as whole words, always shell-quoted;
  every command segment starts with `bin`; no `$`, backticks or other placeholders
  (`checkCodingTemplate` in `packages/domain/src/coding-agents.ts`, mirrored in `gallery/check.mjs`).
  A refused or too-new entry keeps the built-in one with that id.
- **Loading:** the server reads the file with the gallery cache, from the main source only, only
  when the signed manifest lists it; anything else falls back to `BUILT_IN_CODING_AGENTS`.
  `coding.delegate` takes any id on the loaded list (no fixed enum) and builds its description from
  it. Today's five render exactly the commands they did before.
- **API:** `GET /v1/coding-agents` (signed in) returns `{id, label, bin, where, needs_folder, hint,
  preallowed}`. The desktop app scans for those bins, keeps its built-in five for older servers and
  offline, ignores bins that aren't plain names and shows ids it doesn't know.
- **One Allow:** Claude Code, Codex, Cursor, Pi and T3 Code (what shipped apps know) run whenever
  Run commands is on. Any other agent also needs its id in `local_devices.allowed_coding_agents`,
  set by the device's owner with **Allow** in Coding Agents (no companion restart). Without it the
  bot gets `agent_not_allowed`, telling it where the user taps Allow.
- **Kimi Code** added after a real run (`kimi -p {task} --output-format stream-json`), my computer
  only. Gemini CLI (no global bin; account IneligibleTier; untrusted folder), OpenCode (401,
  reconnect), Cline (unauthorized) and Grok (402, no credits) weren't added: no working run.
- **Community pull requests** to `coding-agents.json` are refused by CODEOWNERS and a gallery CI
  step (author must be OWNER or MEMBER).
- **Tests:** `packages/domain/test/coding-agents.test.ts`, `apps/server/test/coding-agents.test.ts`,
  `apps/server/test/coding.test.ts` (unchanged), `client/test/coding_agents_test.dart`.

## D-371 People's own coding agents, on their own computer

- **Decision (2026-11-18, REMOTE-CONTENT-PLAN §2.2 with its defaults):** **Add Your Own** under
  Coding Agents in the desktop app: label, bin, a template with `{task}`, how to read the answer,
  and a time limit (1–120 minutes, default 30). Same template rules as the catalog; no scripts.
- **One person, one computer:** stored in `own_coding_agents` (org, user, device, key), RLS lets
  only the device's owner read or write them (`public.owns_local_device`), admins included; the
  worker reads them with `allow_worker`. My computer only. Ids are `own_<key>`, and
  `coding.delegate` finds them on that device for the device's user only, so a workspace member's
  bot can't reach someone else's.
- **No Allow needed:** the owner added it. Run commands still has to be on.
- **Test:** `POST /v1/local-devices/{id}/coding-agents/test` runs the template with "Reply with just
  the word pong. Do not use tools." on that computer (online, enabled, Run commands on, first shared
  folder) and returns the exit code, the parsed reply and the output. The app shows it before saving.
- **API:** `GET`/`PUT /v1/local-devices/{id}/coding-agents` (the whole list, up to 20).
- **Export:** included in the privacy export (`own_coding_agents.json`).
- **Later:** a pack may carry an agent, shown with its exact command and needing Allow, like D-343.
- **Tests:** `supabase/tests/own_coding_agents_rls.test.sql`, `apps/server/test/coding-agents.test.ts`
  (CRUD, admin refused, Test through a fake computerd, delegate to an own agent),
  `client/test/coding_agents_test.dart`.

## D-372 Remote content, phases 2 and 4: lists from the gallery, links and words from settings

- **Decision (2026-11-18, Oliver: "build all now!"):** phases 2 and 4 of
  `docs/REMOTE-CONTENT-PLAN.md`, with every open question at its default. Lists that change more
  often than we release move to the gallery or the server's settings; the built-in copy stays as the
  fallback everywhere, and shipped apps (0.1.0+34) and the shipped extension keep working (every new
  field is optional, parsers skip what they don't know).
- **Gallery lists:** a new `lists/<id>.json` folder, written by `check.mjs` into `lists.json` (a file
  older readers never fetch, covered by the signed manifest). Four lists: `search-words`,
  `welcome`, `starters`, `app-curation`. `packages/domain/src/gallery-lists.ts` has lenient parsers
  (skip bad entries) and the strict check the gallery runs. Servers read lists from the main gallery
  only, never from an added catalog. Gallery text shows in the app only in English.
- **#2 search words:** one list replaces three copies (agent, MCP, app). Bots' `gallery.search`, the
  MCP's `gallery_search` and the app's gallery search read it; their built-in words are the
  fallback.
- **#3 starter bots:** the 26 built-in starter bots have gallery copies under the same ids, and the
  gallery copy wins (`starterBots()` in `services/gallery.ts`). Built-in ids still count as
  built-in for workspace gallery policy.
- **#4 links:** `links` in remote app settings, https only, by name (status, docs, terms, privacy,
  key pages, subscription management, Docker downloads). The app keeps its own URL as fallback.
- **#15 small duplicates:** tool-call app names moved to `domain/display-names.ts` and DNS provider
  names to `sites/dns.ts`; the server sends them as `names` in `/v1/app-config` (computed, never
  stored) and `dns_provider_name` on a domain. Quick reactions are `quick_reactions` in app settings,
  with the domain list as the default sent.
- **#6 onboarding:** the welcome chat's focus labels, intros, first tasks, starters and apps come
  from `lists/welcome.json` (focus ids fixed for analytics). Starter sets' match words moved into
  each set's `tags`; the app uses a set's tags when it has three or more, else its old hints.
- **#13 empty-state starters:** Library, Tasks and Help starters from `lists/starters.json` via
  signed-in `GET /v1/gallery/lists`.
- **#5 app curation:** display fields only (`name`, `description`, `color`, `featured`, `order`)
  for built-in apps, plus `starter_apps` for an empty chat, sent as `starter_apps` on the app
  catalog. Sign-in, scopes and MCP addresses stay in code.
- **#14 extension prompts:** `prompts` in app settings (`selection.*`, `write.*`); the extension
  uses the last settings fetched, never waiting on the network, and its own text otherwise. Its quick
  reactions are not moved yet.
- **#10 emails:** an owner-only **Email words** admin setting (`instance_settings.email_copy`,
  `GET/PUT /v1/admin/email-copy`) overlays subject, preheader, title, intro paragraphs and button
  for the welcome series and the gallery digest. The greeting, links, digest items and billing and
  domain emails stay in code.
- **No migration:** `instance_settings` already has worker access.
- **Tests:** `packages/domain/test/gallery-lists.test.ts`, `apps/server/test/remote-content.test.ts`,
  `apps/server/test/gallery.test.ts`, `packages/mcp/test/gallery.test.ts`,
  `client/test/remote_content_test.dart`, `apps/extension/test/remote-config.test.ts` and
  `settings.test.ts`.

## D-373 Models and prices in the admin console (remote content, phase 3)

- **Decision (2026-11-18, Oliver: "build all now!", docs/REMOTE-CONTENT-PLAN.md #1, #11, #12):**
  the model catalog, the cost tables and the domain endings and caps are owner settings with the
  code's values as the fallback. Unit prices don't change: only where they live.
- **Model catalog** (`instance_settings` key `model_catalog`, Admin > Services): default, small,
  test and featured models per provider, price and capability rows (exact id or `pattern` regex),
  OpenRouter image prices. `packages/domain/src/model-catalog.ts` holds the check, the loaded copy
  and the getters (`defaultModelFor`, `smallModelFor`, `testModelFor`, `featuredModelsFor`,
  `catalogPriceRow`, `catalogImagePrice`). Order: env `DEFAULT_MODEL_*`, then the catalog, then
  code for defaults; for prices, a provider's live price list, then a catalog row, then the regex
  rows in code. The worker no longer pins the cloud default at boot.
- **Test models:** `DEFAULT_TEST_MODELS` (stale `gemini-2.5-flash`, `grok-3-mini`) is gone; a
  test uses the catalog's test model, else the small model, else the default.
- **Cost tables** (`billing_settings.cost_tables`, Admin > Pricing): voice, Gemini Live tokens,
  computer rates by provider, media. Computers: Admin, then `COMPUTER_RATES`, then code.
- **Domains** (`billing_settings.domain_tlds`, `domain_cap_first_month`, `domain_cap_per_month`):
  the saved list wins; with none saved `CASAMA_DOMAINS_TLDS` is the fallback, then code. The env
  var is a fallback, not an override, so the owner can change endings without a restart; `null`
  goes back to it.
- **Checks:** lenient on load (a bad row is dropped, the rest kept), strict on save (400
  `validation_failed` listing every error). Token prices over $1,000 a million and image prices
  over $5 are refused. Every process reloads every minute (`startRemoteSettings`).
- **App:** the model fallback in `supabase_backend.dart` is gone: every server since D-064 sends
  `default_models`, and the app always starts with a saved or fetched config. Admin gets one JSON
  editor (`remote_settings_cards.dart`) with the built-in values beside it.
- **Routes:** `GET/PUT /v1/admin/model-catalog`, `GET/PUT /v1/admin/price-tables`. Migration
  `20270202610002_price_tables.sql`.
- **Tests:** `packages/agent/test/remote-prices.test.ts` pins today's bills to the cent with no
  setting, an empty one and a broken one; `packages/domain/test/remote-settings.test.ts`;
  `apps/server/test/remote-settings.test.ts`.

## D-374 Guard sites, prompts and model-key providers (remote content, phase 5)

- **Browser guard sites (#7):** an add-only list in `instance_settings` key `browser_guard`
  (Admin > Services), served signed-out at `GET /v1/browser-guard`. `sensitiveSiteKind` checks the
  lists in code first, so nothing a server sends can take a site off. The extension fetches each
  signed-in server's list once an hour (`lib/guard-sites.ts`), keeps the last good copy offline and
  passes it to every guard check; the shipped extension keeps its own lists.
- **Prompts (#8):** gallery-only, versioned, evals in CI (the plan's default for question 3).
  `gallery/prompts/<id>.md` (brief, scan, setup scan, the two scan reasons, setup guide), checked
  and numbered by `check.mjs` into `prompts.json` (in the signed manifest) and
  `prompts/versions.json`. Servers read it from the main catalog only, every 15 minutes; an entry
  that fails its check keeps the built-in text (`packages/agent/src/prompts.ts`). The parts code
  checks for stay in code around the text: the brief and scan openings (how a stored brief or scan
  is known to use the built-in wording), "Quiet day", `NOTHING_NEW`, "You're all set."; the
  checker and the server refuse text that contains them. One wording change: the brief's "Quiet
  day" sentence moved to the end. Composio trigger slugs stay in code: they're subscriptions, not
  prompt text.
- **Evals:** `packages/evals/src/prompts.ts` (`--subset prompts`) sends the gallery's text and
  checks the replies code looks for. `.github/workflows/evals.yml` runs it live on pull requests
  that change a prompt (job `prompts`, needs the OpenRouter secret) and nightly, failing under 75%.
- **Model-key providers (#9):** `KEY_PROVIDERS` in `packages/domain/src/key-providers.ts`, sent in
  `/v1/config` as `key_providers` (chat, more, cloud, runs_chat, hints). The app's three copies are
  now `KeyProviders.fallback` in `client/lib/core/key_providers.dart`; it skips ids it doesn't know
  and adds any it knows that the server left out, so shipped apps and older servers both work.
- **Tests:** `packages/agent/test/prompts.test.ts`, `apps/server/test/gallery-prompts.test.ts`,
  `packages/evals/test/prompts.test.ts`, `apps/extension/test/guard.test.ts`,
  `client/test/key_providers_test.dart`.

## D-378 Share links move to share.casama.page

Asked 2026-11-18: "will published sites at pages.casama.ai hurt our domain?" Search rankings, no:
the pages origin sends `noindex` and a `Disallow: /` robots.txt. Reputation, yes: public pages can
carry forms, and Safe Browsing, SmartScreen and company web filters often flag a whole registrable
domain, so one phishing page could put a warning in front of the app, the API and mail from
`notify.casama.ai`. Being the same site as `app` and `api`, the pages host also weakened SameSite
cookies and could set cookies on `.casama.ai`.

- **Decision (Oliver: "go and do all of that now"):** `PAGES_URL` on Casama Cloud is
  `https://share.casama.page`, on the user-content zone that D-329 picked for sites. Oliver found
  `pages.casama.page` odd ("page" twice, an internal name); `share` says what the link is.
  `share` and `view` join the reserved site labels, and the host dispatcher (`apps/server/src/pages/hosts.ts`) sends
  the `PAGES_URL` host to the pages origin before any site lookup, so the share host wins even before that reaches production.
- **Routing:** `share.casama.page` is a proxied CNAME to the `casama-prod` tunnel, with an ingress
  line to `localhost:8790`. The specific record wins over the `*.casama.page` wildcard, which goes
  to the `casama-sites` tunnel, so this didn't wait for the sites rollout.
- **Old links:** Single Redirects send `pages.casama.ai/*` (casama.ai zone) and `pages.casama.page/*`
  (casama.page zone, live for a few minutes before the rename) to `share.casama.page` with a 301, keeping the path and query, so links already in chats, exports and emails keep working.
  Anyone signed in to a private page signs in once more, because the page cookie is per host.
- **Still to do:** put `casama.page` on the Public Suffix List, so each site counts as its own site
  for browsers and reputation systems, and add `casama.page` to Google Search Console for alerts
  when a page is flagged unsafe.

## D-379: Generated artwork on the websites (2026-11-18)

- **Decision (Oliver: "I love them"):** artwork made with `codex/gpt-6-luna` goes in a few contained places on
  the websites: share cards for casama.ai, docs, casama.link and casama.page, a hero picture on casama.page,
  one "not found" scene on the casama.link, casama.page and gallery 404s, and six new CC0 gallery wallpapers
  (Cloud sea, Lavender hills, Moonlit garden, Paper cranes, Tea morning, Tidepool). Plan: `docs/VISUALS-PLAN.md`.
- **Rules:** the model draws backgrounds and scenes only, with no text, no app UI and no mascot. The words and
  the real SVG mascot are laid on top in HTML and rendered to PNG (`visuals/compose/og.html`,
  `visuals/render-og.sh`), so spelling and the mascot never drift. App screenshots stay real captures, and the
  "Coming soon" cards wait for real screenshots. Pages keep the plain look (D-319): art sits in rounded
  pictures, never behind text.
- **casama.link and casama.page** now have share cards of their own (casama.link used casama.ai's, casama.page had none).
  Gallery items keep their own generated share images with a real preview of the item.
- **Review:** `visuals/serve.py` serves the review board on :8740; `scripts/serve-web.py` now also serves
  casama.page on :8735 (`--only-sites` when the other sites already run). Raw art stays local (`visuals/.gitignore`).
- **Still to do:** compress the new wallpapers (400–816 KB against about 270 KB; five were upscaled from 1254 px),
  re-sign the gallery manifest on deploy, and deploy each site after Oliver's yes.

## D-364 Casama's own model keys only run the models Casama uses

- **Decision (2026-11-18, Oliver: "make stricter our guardrails for what models we currently use
  only"):** the OpenRouter "Casama" workspace's default guardrail, "Casama privacy"
  (`6a06bc80-cb40-43ea-931f-223de655a1d9`, on the "Casama server" key), went from "Allow all
  except" to **Only allow** these six models, the `CLOUD_MODEL_DEFAULTS` that run on OpenRouter:
  `deepseek/deepseek-v4.1-flash-1017` (chat, background work, Casama Help),
  `google/gemini-nano-banana-2.1` (images), `google/gemini-3.8-flash-lite-tts` (read aloud),
  `openai/whisper-large-v3-turbo` (dictation), `openai/text-embedding-3-small` (memory) and
  `google/gemini-omni-1.2-flash` (video). The allowed-provider list stays empty, so any provider
  serving those models still works. The training and prompt-publishing switches stay off.
- **Why:** if the key leaks, it's only worth those six cheap models, on top of the existing caps:
  $50 a day on the key, and the workspace's $50 a day and $1,500 a month (D-244). The server
  already sends only these models (`lockCloudPolicy`, `cloudModelIds`); the guardrail enforces the
  same list at OpenRouter for anyone holding the key.
- **Checked live:** DeepSeek and the embedding model answer. `anthropic/claude-opus-5.5` and
  `openai/gpt-6.2-sol` get 404 "Model blocked by guardrail".
- **Changing a cloud model:** before you switch a model in Admin → Cloud models (or the
  defaults in `packages/domain/src/cloud-model-assignment.ts`), add it to the guardrail at
  openrouter.ai/workspaces/casama/guardrails. Otherwise every call on Casama's key fails with
  that 404.
- **Google (Gemini Live calls):** the server's key (`GOOGLE_AI_API_KEY`, project `kasama-ai`) is
  bound to a service account and limited to the Gemini API. The project has a $100 monthly spend
  cap in AI Studio → Spend. The Firebase keys in the app can't reach Gemini: Gemini keys must be
  bound to a service account, and Firebase AI Logic isn't enabled. The key has no IP restriction,
  because phones connect to Gemini Live with one-use tokens the server makes. Restricting it to
  the server's IP still needs a real call to test.
- **Newer models:** `node scripts/check-model-updates.mts` lists newer models from the same
  maker and family as each OpenRouter default, with prices, and marks the ones it hasn't
  reported before as NEW. It remembers them in `~/.config/casama/model-updates-seen.json`. A
  weekly T3 scheduled task ("Weekly cloud model check", Mondays 09:00) runs it, also checks
  Gemini Live and DeepSeek news, and recommends update, wait or ignore. It never changes anything.

## D-377 One download page, one QR code, one place for store links

casama.ai/download lists every way to get Casama: App Store (iPhone, iPad, Mac), Google Play,
Windows, Linux, the web app, the browser extension (Chrome Web Store, Edge, Firefox), the CLI and
self-hosting. The homepage has a short "On every screen you own" section, and every "Get Casama"
button on casama.ai, the gallery, casama.link and casama.page leads to the download page.

- **One QR code for any phone.** It encodes https://casama.ai/get. The site worker sends iPhones and
  iPads to the App Store, Android to Google Play, and anything else to /download. A code per store
  would make people pick the right one first; one code just works. The code is a static SVG
  (`site/assets/qr/get.svg`, error correction H so the mascot can sit in the middle) on white in
  both themes, and it's hidden on phones and tablets, where it can't be scanned.
- **Every download button goes through /get/<platform>.** `GET_LINKS` in `site/gallery-link.js`
  holds the real addresses, so a store listing going live, or a release file moving, changes one
  line and no page.
- **"Start free" depends on the device.** The homepage's two Start free buttons go to /get/start:
  computers always get the web app (quickest way to sign up), phones and tablets get their app
  store once `STORES_LIVE` is true (the native app starts faster, gets push and gets kept), the
  web app until then. Open app and the plan buttons stay on the web app; a "Download the app"
  link sits beside both Start free buttons.
- **The page leads with this device's download.** site.js reads the user agent (iPads that say
  Macintosh are told apart by touch) and marks the matching card "This device".
- Store badges are drawn in the site's own style with simple-icons glyphs (CC0), not the official
  Apple and Google artwork. Before launch, swap in the official badges if the store guidelines
  require them.
- **Official links where we have them.** App Store (id 6833509960), Google Play (ai.casama.app)
  and Firefox Add-ons (`/firefox/addon/casama/`) use the listings' own addresses, live once each
  listing is public. The Mac .dmg is the only download already public, so the Mac card leads with
  it and the Mac App Store is the second choice; /get/mac-dmg (and /get/windows, once there's a
  feed) reads the newest file from the update feed the release script moves, cached five minutes,
  with a pinned v0.1.0 fallback. Chrome Web Store and Edge have no item ids yet and no Windows or
  Linux build is published: those go to the extension guide and the releases page.

## D-378 Share links move to share.casama.page

Asked 2026-11-18: "will published sites at pages.casama.ai hurt our domain?" Search rankings, no:
the pages origin sends `noindex` and a `Disallow: /` robots.txt. Reputation, yes: public pages can
carry forms, and Safe Browsing, SmartScreen and company web filters often flag a whole registrable
domain, so one phishing page could put a warning in front of the app, the API and mail from
`notify.casama.ai`. Being the same site as `app` and `api`, the pages host also weakened SameSite
cookies and could set cookies on `.casama.ai`.

- **Decision (Oliver: "go and do all of that now"):** `PAGES_URL` on Casama Cloud is
  `https://share.casama.page`, on the user-content zone that D-329 picked for sites. Oliver found
  `pages.casama.page` odd ("page" twice, an internal name); `share` says what the link is.
  `share` and `view` join the reserved site labels, and the host dispatcher (`apps/server/src/pages/hosts.ts`) sends
  the `PAGES_URL` host to the pages origin before any site lookup, so the share host wins even before that reaches production.
- **Routing:** `share.casama.page` is a proxied CNAME to the `casama-prod` tunnel, with an ingress
  line to `localhost:8790`. The specific record wins over the `*.casama.page` wildcard, which goes
  to the `casama-sites` tunnel, so this didn't wait for the sites rollout.
- **Old links:** Single Redirects send `pages.casama.ai/*` (casama.ai zone) and `pages.casama.page/*`
  (casama.page zone, live for a few minutes before the rename) to `share.casama.page` with a 301, keeping the path and query, so links already in chats, exports and emails keep working.
  Anyone signed in to a private page signs in once more, because the page cookie is per host.
- **Still to do:** put `casama.page` on the Public Suffix List, so each site counts as its own site
  for browsers and reputation systems, and add `casama.page` to Google Search Console for alerts
  when a page is flagged unsafe.

## D-380 Plain in casama.ai's colors is the one built-in theme; every other theme comes from the gallery

- **Decision** (Oliver, 2026-11-18: "why not just 1? Why not just from Gallery at all?", then "make our default theme look like our website brand colors so it's consistent"): Settings → Appearance shows one Themes grid: Plain, then your themes, then the gallery's (six, then Show all). Plain is the only theme that ships with the app, because it is the default and has to work offline and before the server answers. Updates D-203 and D-266.
- **Plain's colors** are casama.ai's (`link-site/link.css`): purple `#7A3FA8` on white in light, `#D9B6F7` on `#1C1C1E` in dark, grey secondaries, with the site's card grey, hairlines and ink as the surfaces. The scheme is data, `client/looks/schemes/plain.json` (id `plain`), generated into `looks.g.dart` with the usual AA checks. Its `ThemeChoice` has `neutralSurfaces`, so `withNeutralSurfaces` puts the site's plain surfaces over the scheme instead of surfaces tinted with the purple (D-319's plain backgrounds), in the app theme and in gallery previews alike. Plain keeps Google Sans, no pattern and fewer effects. Unknown scheme ids now fall back to Plain.
- **Moving off the old Plain:** a look saved with the old Plain scheme (`shadNeutral`) together with Plain's fonts and flat surface reads as Plain, so it shows as Plain in its new colors. Shad Neutral picked on purpose with other fonts or a background stays as it is, and it is still in Customize → Colors.
- **The other eight** (Casama, Editorial, Ocean, Forest, Sakura, Sunset, Cosmos, Graphite) are gallery themes by Casama under the same ids (`gallery/themes/<id>`), with Casama featured. Casama keeps its exact six colors. The others give seeds, background and text only, because their FlexColorScheme colors fail the gallery's AA checks, so their secondary colors come out slightly different from before. Someone using one of the old built-in themes keeps the look; the card says Custom look until they tap the gallery copy.
- **Bot suggestions** (D-242) keep the same names: `preset` is Plain or a gallery theme with that id, which the app looks up in the gallery (`applySuggestedLook`'s `galleryTheme`). Older apps still have the built-in copies, so they show those themes twice until they update.
- **Also:** `scripts/casama-looks.mts` wrote `package:flutter/material.dart` into `looks.g.dart`, which Flutter 3.50 flags; it writes `material_ui` now.

## D-381 Search and AI answers: the written pages, one address per page, and weekly tracking

- **Decision** (Oliver, 2026-11-18: "we should start doing serious SEO, AEO, GEO", then "you decide all for me and start working"): build `docs/SEO-PLAN.md` with its recommended answers to all 14 decisions. Docs and gallery stay on their subdomains; the homepage keeps its headline and gets a title with the searched words ("Casama | Open-source AI agents with their own computers"); rivals are named with sourced, dated facts; AI training crawlers are allowed; no paid placements or tools beyond OpenSEO.
- **Faults fixed:** the docs were built twice (the markdown copies in `public/` were also pages, half the sitemap); `srcExclude` stops it and `/public/*` redirects. Docs pages get a canonical address, their own description, share tags and structured data. casama.ai gets a real not-found page, `Organization` and `WebSite` data, and `Content-Signal` lines in every `robots.txt`.
- **Written pages:** `site/build.mjs` (no dependencies) turns `site/content/**.md` and `site/data/*.json` into pages, a markdown copy of each, `sitemap.xml`, the "Pages" part of `llms.txt` and RSS feeds. First set: pricing, self-hosted, open source, security, about; 12 alternatives pages and 3 comparisons; 8 use cases; 12 question pages; 4 posts; the changelog from `CHANGELOG.md`.
- **Rival facts** live in `site/data/rivals.json`, each with its source. The build fails on a fact with no source, a rival last checked more than 45 days ago, a page under 300 words, a missing description or a repeated title, and when the homepage's prices differ from `site/data/plans.json`.
- **Clean room holds** (SPEC rule 1): rival facts come from public marketing, pricing and help pages, store listings, repository metadata and press, in our own words.
- **Gallery:** item pages get structured data, app pages get a title people search ("Gmail AI agent: …"), and the gallery gets an `llms.txt`.
- **Telling search engines:** `scripts/indexnow.mjs` sends changed addresses to IndexNow after `scripts/deploy-web.sh`; the key file is public by design.
- **Visit counts:** `site.js` posts the page and the referring site's host to `/b`; the site Worker writes one anonymous row (source kind, page) to Workers Analytics Engine. No cookie, visitor ID or IP address. The privacy page says so.
- **Tracking:** OpenSEO project Casama: 75 keywords weekly, 25 questions weekly on five AI engines. About $23 a month (`docs/COSTS.md`).
- **Not done here, needs Oliver:** the deploy, the `www` redirect rule, adding casama.ai to Bing Webmaster Tools, directory submissions, the launch, and a read of the four posts written under his name.

## D-376 System permissions from the chat: a card with a button per permission

- **Why (Oliver, 2026-11-18):** a bot reached his MacBook but Accessibility and Screen Recording were
  off and no folders were shared, so all it could do was write out "System Settings → Privacy &
  Security → …". He asked for buttons, for every permission and every platform.
- **Decision (plan `docs/OS-PERMISSIONS-PLAN.md`, every §9 default taken, "execute the plan now"):**
  - **One list** (`packages/domain/src/os-permissions.ts`, copied in
    `client/lib/features/permissions/os_permissions.dart`, a test keeps them equal): location,
    location in the background, camera, microphone, speech, photos, contacts, calendars, health,
    notifications, notification access (Android), Accessibility, Screen Recording, Automation, Full
    Disk Access (macOS), and Casama's own shared folders and local tools. Each says per platform
    whether it's asked by a system prompt, only in settings, or in Casama, and whether it needs a
    restart (Screen Recording on a Mac). **Only what the builds declare:** no camera or location on
    the Mac, no camera or photos on Android, no reminders, motion, Bluetooth, local network or Input
    Monitoring anywhere, since a row the build can't turn on is a dead end. Adding one belongs with
    the feature that needs it, together with its declaration. Ids are plain strings on the wire.
  - **Devices report** what the system has, checked without prompting (`PUT
    /v1/device-permissions/{computer|source}/{id}`, new `permissions`, `permissions_at`,
    `permission_snoozes` columns on `local_devices` and `device_sources`): on start, on resume,
    after an action, and every 3 s while a card or the screen for that device is open. The server
    fills shared folders and local tools for computers from their settings.
  - **The failure posts the card, not the model** (D-328's lesson): the run's tool error handler
    reads the permission from the error (agent-desktop's `PERM_DENIED` message, checked against
    agent-desktop 1.3.1 on macOS 27; computerd's `screen_recording_denied`; `no_folders`; an MCP
    server's `casama_permission` in an error's data or a failed result's `structuredContent`) and
    emits `device.permission_needed` when the bot works on the person's own computer in their own
    run. `device.read` and device writes post it when every device sharing the kind reports the
    permission off (`permission_off`). `device.request_permission` asks up front. Once per run per
    device and permission; "Not now" quiets that bot for that permission on that device for 24 h.
    The model is told the card is showing and not to write out the steps. The "who you're talking
    with" block lists what's off on the person's devices.
  - **The card** (`PermissionsCard`, kept per run like the Allow card): a row per permission with
    its live state and a button. On the device it names, the button shows the system prompt, or
    opens the exact settings page once the system won't ask again (macOS Privacy panes, Windows
    `ms-settings:`, the app's page on iOS and Android), or Casama's Use this computer screen. On
    another device: a computer gets `{"type":"permission","permission","do","bot_id"}` over its
    device socket and opens it there ("Opened on <device>"); a phone gets a `permission`
    notification (needs_you) whose tap opens `/permissions?device=source:<id>&ask=<id>&do=<do>` and
    shows the prompt, since phones can't prompt from the background. Screen Recording asks for a
    restart (the Mac relaunches itself). Continue sends "They're on, go ahead." Someone else's
    device: read only. Settings → Permissions shows the same rows for this device.
  - **No request rows for phones:** older apps parse `device_requests.action` strictly, so a new
    action would have broken their whole request list; the notification carries it instead.
  - **Mac screenshots:** computerd's `/screenshot` only worked on X11, so on a Mac it always failed
    with "no desktop running" (the "no desktop session" the bot saw). In companion mode on macOS it
    now runs `screencapture -x`, after `agent-desktop permissions` says Screen Recording isn't
    denied (403 `screen_recording_denied` otherwise, which the run keeps as the error code).
- **Native:** channel `casama/permissions` (`check`, `request`, `relaunch`). macOS: AX,
  CGPreflight/CGRequestScreenCaptureAccess (a prompt shown once is remembered, since neither API
  tells "never asked" from "said no"), AEDeterminePermissionToAutomateTarget for System Events,
  a TCC.db read probe for Full Disk Access, microphone and speech states, relaunch through `open
  -n`. iOS: camera, photos, microphone, speech. Android, Windows, Linux and web use plugins,
  url_launcher and the browser's Permissions API; no native code.
- **Not the A2UI catalog:** the plan put a `Permissions` component in the catalog for `ui.show`;
  it's an event-driven card instead (like the Allow card), because card buttons in the catalog only
  send messages (D-086) and older apps would skip a device action anyway. Plugins reach it through
  `casama_permission`.
- **Tests:** domain list and error mapping; server `device-permissions.test.ts` (routes, socket,
  phone notification, Not now, cards from a desktop error, device.read, device.request_permission,
  the prompt line); agent MCP mapping; computerd Mac screenshot helpers; app
  `permissions_test.dart` and `os_permissions_test.dart` (card states and buttons, cross-device,
  restart, Not now, read only, unknown ids, chat replay and reload, screen and link, reporter,
  companion message, list parity).
- **Not done:** the Swift bridges were only typechecked against stubs, never compiled in a build;
  no real-device check of any prompt, pane (including whether the Privacy pane URLs still open on
  macOS 27, which renamed Accessibility to Device Control and Data Access), the relaunch, or the
  Mac screenshot path. The run hook is tested at function level, not through a fixture run. A
  plugin placed on "My computer" (D-344) while the bot works on a cloud computer gets no card.

## D-382 Starter bots get a person's name; the demo bots follow

- **Decision (Oliver, 2026-11-18):** new bots get names from Oliver's list (Rome, Max, Juancho, Anna, Kelly, Oliver, Dawn, Zenaida, Hannya, Kitsune, Orlando, Agnes, Jose, Jason, Angel, Theo, Airene, Eden, Troy, Jack, Timothy, Kenhart, Ian, Kayvin, Jojo, Zedric, Mel, Bryan, Noel, Richard, Ivan, Jib, Arvin), kept in `BOT_NAMES` (`packages/domain/src/templates.ts`).
- **Starter bots:** each of Casama's 28 starter bots (built-in and gallery-only) has its own name, for example Travel → Rome, Assistant → Anna, Researcher → Theo (`starterBotName`). A community starter bot from the gallery gets one from the list, the same each time for its id. The starter bot's `name` stays its job, which the gallery and the persona picker show.
- **API:** `Template.bot_name` on `GET /v1/templates`. Picking a starter bot in the new-bot sheet fills in that name until the person types their own; an older server without it fills in the job, as before. Installing a bot from the gallery names it the same way. Kept out of the signed gallery documents so nothing there needs re-signing.
- **Websites:** the casama.ai hero chat, the "Give every bot a job" cards, the small-business use case and the docs' examples now use Anna, Theo, Kelly and Mel (were Ada, Milo, Sora and Juno). The screenshots (`hero`, `mac-group`, `mac-nova`) still show Ada, Milo and Nova and keep their alt text until they're retaken.
- **Every starter bot on casama.ai:** the new page `casama.ai/bots` lists all of Casama's starter bots by category, each with its mascot, name, job and description, linking to its gallery page (the `{{bots}}` token in `site/content/bots.md`). The home page keeps the four story cards and adds one row of eight bots as chips plus "See all 28 starter bots", so the list doesn't take a screenful there. `site/build.mjs` writes both from `gallery/bots` and `starterBotName`, so the site follows the app; `--check` fails when the home row is out of date.
- **Unchanged:** the personal bot is still "Casama", the support bot "Casama Help", and a blank bot left unnamed is still "Chief".

## D-376 System permissions from the chat: a card with a button per permission

- **Why (Oliver, 2026-11-18):** a bot reached his MacBook but Accessibility and Screen Recording were
  off and no folders were shared, so all it could do was write out "System Settings → Privacy &
  Security → …". He asked for buttons, for every permission and every platform.
- **Decision (plan `docs/OS-PERMISSIONS-PLAN.md`, every §9 default taken, "execute the plan now"):**
  - **One list** (`packages/domain/src/os-permissions.ts`, copied in
    `client/lib/features/permissions/os_permissions.dart`, a test keeps them equal): location,
    location in the background, camera, microphone, speech, photos, contacts, calendars, health,
    notifications, notification access (Android), Accessibility, Screen Recording, Automation, Full
    Disk Access (macOS), and Casama's own shared folders and local tools. Each says per platform
    whether it's asked by a system prompt, only in settings, or in Casama, and whether it needs a
    restart (Screen Recording on a Mac). **Only what the builds declare:** no camera or location on
    the Mac, no camera or photos on Android, no reminders, motion, Bluetooth, local network or Input
    Monitoring anywhere, since a row the build can't turn on is a dead end. Adding one belongs with
    the feature that needs it, together with its declaration. Ids are plain strings on the wire.
  - **Devices report** what the system has, checked without prompting (`PUT
    /v1/device-permissions/{computer|source}/{id}`, new `permissions`, `permissions_at`,
    `permission_snoozes` columns on `local_devices` and `device_sources`): on start, on resume,
    after an action, and every 3 s while a card or the screen for that device is open. The server
    fills shared folders and local tools for computers from their settings.
  - **The failure posts the card, not the model** (D-328's lesson): the run's tool error handler
    reads the permission from the error (agent-desktop's `PERM_DENIED` message, checked against
    agent-desktop 1.3.1 on macOS 27; computerd's `screen_recording_denied`; `no_folders`; an MCP
    server's `casama_permission` in an error's data or a failed result's `structuredContent`) and
    emits `device.permission_needed` when the bot works on the person's own computer in their own
    run. `device.read` and device writes post it when every device sharing the kind reports the
    permission off (`permission_off`). `device.request_permission` asks up front. Once per run per
    device and permission; "Not now" quiets that bot for that permission on that device for 24 h.
    The model is told the card is showing and not to write out the steps. The "who you're talking
    with" block lists what's off on the person's devices.
  - **The card** (`PermissionsCard`, kept per run like the Allow card): a row per permission with
    its live state and a button. On the device it names, the button shows the system prompt, or
    opens the exact settings page once the system won't ask again (macOS Privacy panes, Windows
    `ms-settings:`, the app's page on iOS and Android), or Casama's Use this computer screen. On
    another device: a computer gets `{"type":"permission","permission","do","bot_id"}` over its
    device socket and opens it there ("Opened on <device>"); a phone gets a `permission`
    notification (needs_you) whose tap opens `/permissions?device=source:<id>&ask=<id>&do=<do>` and
    shows the prompt, since phones can't prompt from the background. Screen Recording asks for a
    restart (the Mac relaunches itself). Continue sends "They're on, go ahead." Someone else's
    device: read only. Settings → Permissions shows the same rows for this device.
  - **No request rows for phones:** older apps parse `device_requests.action` strictly, so a new
    action would have broken their whole request list; the notification carries it instead.
  - **Mac screenshots:** computerd's `/screenshot` only worked on X11, so on a Mac it always failed
    with "no desktop running" (the "no desktop session" the bot saw). In companion mode on macOS it
    now runs `screencapture -x`, after `agent-desktop permissions` says Screen Recording isn't
    denied (403 `screen_recording_denied` otherwise, which the run keeps as the error code).
- **Native:** channel `casama/permissions` (`check`, `request`, `relaunch`). macOS: AX,
  CGPreflight/CGRequestScreenCaptureAccess (a prompt shown once is remembered, since neither API
  tells "never asked" from "said no"), AEDeterminePermissionToAutomateTarget for System Events,
  a TCC.db read probe for Full Disk Access, microphone and speech states, relaunch through `open
  -n`. iOS: camera, photos, microphone, speech. Android, Windows, Linux and web use plugins,
  url_launcher and the browser's Permissions API; no native code.
- **Not the A2UI catalog:** the plan put a `Permissions` component in the catalog for `ui.show`;
  it's an event-driven card instead (like the Allow card), because card buttons in the catalog only
  send messages (D-086) and older apps would skip a device action anyway. Plugins reach it through
  `casama_permission`.
- **Tests:** domain list and error mapping; server `device-permissions.test.ts` (routes, socket,
  phone notification, Not now, cards from a desktop error, device.read, device.request_permission,
  the prompt line); agent MCP mapping; computerd Mac screenshot helpers; app
  `permissions_test.dart` and `os_permissions_test.dart` (card states and buttons, cross-device,
  restart, Not now, read only, unknown ids, chat replay and reload, screen and link, reporter,
  companion message, list parity).
- **Not done:** the Swift bridges were only typechecked against stubs, never compiled in a build;
  no real-device check of any prompt, pane (including whether the Privacy pane URLs still open on
  macOS 27, which renamed Accessibility to Device Control and Data Access), the relaunch, or the
  Mac screenshot path. The run hook is tested at function level, not through a fixture run. A
  plugin placed on "My computer" (D-344) while the bot works on a cloud computer gets no card.

## D-383 A wide window opens the last chat instead of "Select a bot to chat"

- **Decision (Oliver, 2026-11-18):** on wide windows the bare Chats page (`/bots`) is no longer a
  page asking to pick a bot. It opens the chat last open on this device, with the cursor in the
  message box. People come to say something; the middle of the screen was a dead end on every
  launch.
- **Which chat:** the bot's chat or group chat last open in this workspace on this device
  (`lastChat:<orgId>` in the device's preferences, written by the shell); when that bot or group
  is gone or nothing is saved, the bot that spoke or was spoken to most recently; when none has
  messages, the first bot in the list (`chatToOpen` in `home/last_chat.dart`). Which conversation
  of the bot is unchanged: the chat reopens the bot's latest, as before.
- **Links win:** a notification, a casama.ai/open link or any other address goes where it says;
  only the bare Chats page is replaced. The chat takes the page's place in a browser's history, so
  Back doesn't land on it and bounce forward.
- **No bots:** the page stays, as "No bots yet" with what a bot is and New bot. "Select a bot to
  chat" and "Pick a bot on the left…" are gone (strings removed).
- **Cursor in the message box:** on macOS, Windows and Linux, in the app or a browser, a chat
  opens focused on the message box, also when picked from the sidebar. Not on a phone's or
  tablet's browser (the keyboard would come up), not when the link points at one message, and not
  under an open dialog.
- **Read means seen:** a chat that opens by itself must not clear a badge nobody saw. The chat
  marks its notifications read only while the app is in front (window focused, tab visible), and
  when it comes back to the front.
- **Phones and tablets:** unchanged; they show the list of bots.
- **Tests:** `last_chat_test.dart` (saved chat, most recent bot, no bots, phones, focus, read
  only in front); `app_test.dart`'s desktop layout test no longer picks a bot first.
- **Not done:** no check in a real window or browser yet (the browser Back behaviour and the
  focus on a real Mac are only covered by widget tests).

## D-384 Better web search and page reading: a cheap server chain, a cache and web.fetch

- **Problem:** bots on Casama Cloud searched only through SearXNG, which scrapes public engines and
  gets rate-limited or shown captchas; good search needed each workspace's own Brave ($5 per
  1,000) or Tavily ($8 per 1,000) key. To read a result, bots used `http.request`, which hands the
  model up to 200 KB of raw HTML (mostly markup, paid as input tokens on every later turn), or the
  browser, which is slower and needs a computer. The `no_search_provider` error told self-hosters
  only about Brave and Tavily keys.
- **Decision:**
  - **New providers** in `packages/agent/src/search.ts`, each with its price per query:
    Parallel Search (`POST /v1/search`, `x-api-key`, `mode: "fast"`, $0.001, results capped at 10
    because more cost extra), Serper (`POST google.serper.dev/search`, `X-API-KEY`, `{q, num}`,
    $0.001; `google.com/goto?url=…` links are unwrapped) and DeepSeek Search
    (`POST api.deepseek.com/v1/tools/search`, Bearer, query cut to 128 characters, its `summary`
    used as the snippet, $0.00075).
  - **The server's own chain** (Casama Cloud's keys): `SEARCH_PROVIDER_ORDER` (default
    `parallel,serper,searxng`; empty means the default), `PARALLEL_API_KEY`, `SERPER_API_KEY`,
    `DEEPSEEK_SEARCH_API_KEY`. A provider without its key is skipped, and a configured SearXNG is
    always the last resort. `searchFor` tries the workspace's own key first (Brave, Tavily, and now
    Parallel and Serper as workspace keys too), then the server chain; `FallbackSearchProvider`
    moves to the next provider on an error or no results.
  - **Cost of the provider that answered:** `runSearch` returns the answering provider's id and
    price; `search_queries` records that cost with `meta.provider`, not the first provider's.
  - **Cache:** answers with results are kept 6 hours in an in-memory LRU in the worker (2,000
    entries), keyed by workspace, provider chain, normalized query (case, spacing) and count. A hit
    still writes one `search_queries` row, at $0 with `meta.cached: true`, so query counts stay
    true. Per workspace, not shared: a $0 answer would otherwise tell one workspace that another
    searched the same words. A worker restart forgets it, which only costs a few repeat queries.
  - **`web.fetch`:** GETs a URL through the same guarded fetch `http.request` uses (private
    ranges, cloud metadata and DNS rebinding refused at connect time), follows at most five
    redirects by hand so each hop goes through the guard, reads at most 5 MB, and returns the
    title, description and main content as markdown-ish text (`packages/agent/src/web-read.ts`:
    scripts, styles, menus, headers, footers, forms and ARIA navigation removed; `<article>` or
    `<main>` preferred when it has real text; links kept as absolute markdown links; `<pre>` kept).
    Default 20,000 characters, at most 100,000, with `start` to read on. Plain text and JSON pass
    through; PDFs, images and other binaries get a one-line note. Low risk, read-only, untrusted
    output (`wrapUntrusted("web", …)`), in the voice-call tool list, and in the `web` group for lazy
    loading. `web.search`'s description now points to it. No HTML parser was in the dependencies,
    so the extractor is small and regex-based; it is not a sanitizer and its text is never
    rendered as HTML.
  - **Error message:** `no_search_provider` now names the four workspace keys and SearXNG
    (`SEARXNG_URL`, `./install.sh --search`).
- **Why not OpenRouter's server-side web search:** it works only on models and routes OpenRouter
  supports it for, bills inside the model call where we can't meter or cap it per query, can't be
  cached, and skips our tool approvals and run steps. Our own tool stays model-agnostic (DeepSeek
  V4.1 Flash today, anything tomorrow), metered per query and the same on a self-hosted server.
- **DeepSeek's privacy:** search queries would go to DeepSeek's servers in China. It is never in
  the default order and is used only when the server owner names `deepseek` in
  `SEARCH_PROVIDER_ORDER` and sets its key. DeepSeek also has a Fetch tool (`/v1/tools/fetch`);
  `web.fetch` stays our own extractor so page contents never leave the server.
- **Who pays:** a workspace key pays its own provider. The server chain is paid by the server owner;
  on Casama Cloud that is about $0.001 a search, recorded at cost and not billed to credits
  (docs/COSTS.md). Bill it with markup if search use grows.
- **Trade-offs:** a workspace key that fails falls through to the server chain, so a broken key
  costs the server instead of failing the search. Parallel and Serper are separate vendors to keep
  as subprocessors. Older apps can't parse a credential whose provider is `parallel` or `serper`
  (the generated `ProviderId` enum is strict), the same as when `google_maps` and `mapbox` were
  added: their Model keys list fails to load in a workspace that has one, until they update.
  Workspace keys `parallel` and `serper` need migration `20270203000001_search_keys.sql`.
- **Tests:** `packages/agent/test/web-search.test.ts` (each provider's request and parsing,
  errors, Google link unwrapping, fallback order and the answering provider's cost, cache hits,
  expiry, per-workspace keys and LRU bound, server chain order and workspace-key-first selection;
  live checks when `PARALLEL_TEST_KEY` or `SERPER_TEST_KEY` is set) and
  `packages/agent/test/web-fetch.test.ts` (extraction, caps and `start`, JSON and PDF, redirects,
  refusal of private and metadata addresses also after a redirect, cost rows for web.search
  including a $0 cached row, the new error message); `voice-call-tools.test.ts` covers `web.fetch`.
- **Not done:** no live call to Parallel, Serper or DeepSeek yet (the response shapes come from
  their docs); not deployed; Casama Cloud needs `PARALLEL_API_KEY` and `SERPER_API_KEY` on the
  server.

## D-385 Casama Cloud's Service keys no longer offer search keys

- **Before:** on Casama Cloud, Settings → Service keys took Brave Search and Tavily keys, because
  Cloud had no paid search of its own (D-188, D-179).
- **Decision (2026-11-18, Oliver):** Cloud searches on Casama's own Parallel and Serper keys since
  D-384, so `KEY_PROVIDERS.cloud` drops `brave_search` and `tavily` and keeps Google Maps, Mapbox and
  Treg. The list comes from `GET /v1/config`, so this is a server deploy; the apps' built-in fallback
  copy (only used against older servers) is left as is.
- **Existing keys:** the Service keys page lists only the providers in this list, so a saved Brave or
  Tavily key would have become invisible while `searchFor` kept using it. Production had none
  (checked before the change). Self-hosted servers still offer every search key under More providers.
- **Docs:** `docs-site/guide/bots.md` (Service keys paragraph).
- **Tests:** `packages/domain/test/remote-settings.test.ts`, `apps/server/test/remote-settings.test.ts`.

## D-386 Casama Cloud searches DeepSeek first; the privacy policy names the search providers

- **Decision (2026-11-18, Oliver: "cost matters more"):** production's `SEARCH_PROVIDER_ORDER` is
  `deepseek,parallel,serper,searxng` (set in the server's env, not in code; the code default stays
  `parallel,serper,searxng` for self-hosters). DeepSeek Search is $0.75 per 1,000 against $1 for
  Parallel and Serper. Oliver topped up DeepSeek with $10 (about 13,000 searches); when it fails or
  finds nothing, Parallel answers.
- **Trade-off:** Cloud users' search words now mostly go to DeepSeek's servers. Only the query is
  sent; pages a bot opens are fetched by our own server (`web.fetch`, D-384).
- **Privacy policy:** `site/privacy.html` §4 now says search words go to DeepSeek, or Parallel or
  Serper as fallback, and no longer says Cloud users can add their own search keys (D-385).
  Effective date moved to 18 November 2026.
- **Costs:** `docs/COSTS.md` web search row.

## D-387 Chats show when messages were sent: day and pause labels, the exact time on demand

- **Decision (2026-11-18, Oliver: "build all now"):** the chat never showed when a message was
  sent; the server's `created_at` was dropped on the way into the chat. It is shown in three
  layers, from always visible to on demand, so no bubble gets a time under it:
  1. **Day labels:** where the day changes, a small muted centered label with the day and the first
     message's time: "Today · 3:42 PM", "Yesterday · …", "Mon, Nov 16 · …", the year only for
     another year. No line or pill, so it reads on any wallpaper.
  2. **Pause labels:** within a day, the time alone after a gap of an hour or more (`chatTimeGap`).
  3. **Exact time:** the top line of a message's touch menu ("Yesterday at 9:05 AM"), the end of the
     hover bar with a mouse (full date in its tooltip), and the message's semantics value for
     screen readers.
- **Not done:** relative "5 minutes ago" inside the chat (it goes stale and needs timers; the chat
  list keeps its relative time) and a time under every message.
- **How:** `MessageEntry.at` (local time) from `ChatMessageView.createdAt`; a message still sending
  takes now, a streamed reply its event's time, until the next reload. `chatTimeBreak` in
  `client/lib/features/chat/widgets/chat_time.dart` decides; `_buildRows` adds the label rows before
  messages and routine notices, and a label starts a new turn so a group chat's bot header shows
  again under it. Times follow the device's 12/24-hour setting.
- **Docs:** `docs-site/guide/chat.md` (When messages were sent).
- **Tests:** `client/test/chat_time_test.dart`.

## D-388 Gallery paintings have a day and a night version; backgrounds follow light and dark mode

- **Decision (2026-11-18, Oliver: "backgrounds should adapt to the theme light/dark as well"):**
  every theme had light and dark colors but one painting, drawn the same in both modes under a
  thin veil (about 13%), so a bright painting glared behind dark mode's light text and a night
  painting sat heavy behind light mode. Each of the 22 paintings the themes use now has a twin:
  18 light paintings got a night version, and the 4 night paintings (Aurora, Lantern night,
  Starlit lake, Moonlit garden) got a day version, which becomes their light-mode `file`.
- **Data:** an image wallpaper's `wallpaper.json` can add `dark` and `darkThumb` (2 MB and 200 KB,
  like `file` and `thumb`). The index resolves them for a theme's `image` the same way
  (`../<id>/<file>`). Checked in `gallery/check.mjs` and `checkWallpaperDocument`. Older apps
  ignore them and keep drawing `file`.
- **App:** `WallpaperSpec.photoDark` (saved with the appearance; a new photo drops it). The
  wallpaper loads `photoDark` when the theme is dark (`WallpaperTheme.isDark`, by surface
  luminance). A photo with no night version (Unsplash, your own photo, other wallpapers) gets a
  veil of at least 50% toward the dark surface in dark mode instead. Web gallery previews follow
  the same rule.
- **Updates:** the 22 wallpapers and their 22 themes went up one version, so people already using
  them see Update in Gallery → Installed, which brings the night painting along.
- **Art:** gpt-6-luna, one image per task, from the original as reference (brief
  `visuals/round-6/BRIEF.md`, raw files gitignored); installed with `visuals/install-twins.py`.
  The other 8 wallpapers, not used by a theme, have no twin yet and use the veil.
- **Tests:** `client/test/looks_test.dart` (day and night paintings), `packages/domain/test/gallery.test.ts`.

## D-389 casama.ai's hero says what the bots do, not only what they have

- **Decision (2026-11-18, Oliver: "make everything perfect", after asking whether the hero copy
  was the best it could be):** the homepage H1 is "AI teammates that do the work on their own
  computers." (was "AI teammates with their own computers."). The old line named a feature and
  left the result to the paragraph under it; the new one says both. This replaces the "keep the
  H1" row of D-381. The page title is unchanged.
- **The short line stays the tagline** everywhere else: README, docs, emails, store listings, the
  share image and the site footer. Only the homepage H1 changed.
- **Around it:** the eyebrow is "Open source · Free to start" (was a list of seven platforms,
  which moved to the note under the buttons). The paragraph names tasks ("book the trip, answer
  the email or build the site") and says "asks before it pays, sends or deletes anything". The
  "Meet the bots" link is gone; the menu's Teammates link goes to the same section.
- **Headings:** "Your apps, and the right AI model for each job." (was "Your apps. The best AI
  models.", a claim we can't prove) and "Start free. Pay when you need more." (was "Start free.
  Simple to grow.").
- **Layout:** each phrase of the H1 is an inline block (`.hero h1 .ph`), so it breaks into four
  lines between phrases on every screen. The hero H1 stops growing at 78px (was 84px) so "that do
  the work" fits the text column on wide screens. `site/index.html`, `site/site.css`.

## D-390 casama.ai shows the launch film: "Watch the film" in the hero, and the film in "See it at work"

- **Decision (2026-11-18, Oliver: "Can we now use the videos in our websites? … you decide for me
  surprise me"):** the homepage carries the launch film, hero v2 (Oliver's pick; docs/LAUNCH-VIDEO-PLAN.md).
  - **The hero** gets a "Watch the film · 1 min" button beside Start free. It opens the 68-second
    film with sound in a dialog, in 16:9 on every screen. `casama.ai/#film` opens it straight away,
    so posts can link to it.
  - **"See it at work"** swaps its screenshot, which showed old bot names, for the same film in 16:9.
    It plays muted and on a loop only while it's on screen; its captions are burned in, so it reads
    without sound. "Sound on" starts it over with the voice and music, and a link opens the dialog.
- **Not the fast cut (Oliver, same day: "The landscape video is wrong. It should be the v2 hero"):**
  the first version of this put the 30-second fast cut in "See it at work". It was replaced by hero
  v2 and its files removed from the site. The fast cut stays for social posts.
- **No upright version (Oliver, same day: "Maybe remove the phone or vertical video"):** phones
  first got the 9:16 hero in the dialog. Now every screen gets the 16:9 film, and the 9:16 files are
  off the site; it stays for Reels, TikTok and Shorts. The dialog is never wider than its height
  allows (`82vh × 16/9`), and on a phone held sideways the close button sits on the video.
- **Why there:** the hero is where a visitor decides whether to keep reading, and a minute of the
  bots working answers "what does it actually do" faster than the copy.
- **Honesty (plan §2a):** the web versions have no "rough cut" corner label. Instead, the line
  "Casama's app is shown as it is. What's on the bots' computers is recreated for clarity." sits
  under both the section's video and the dialog.
- **Calm and data:** nothing loads until it's needed (`preload="none"`, posters only). With reduced
  motion or Save-Data on, the section's video doesn't autoplay and shows its own controls instead.
  Opening the dialog pauses it. Without JavaScript the links open the MP4 file.
- **Files:** `site/assets/film/`: `casama-film-16x9.mp4` (7.2 MB) and its JPG poster (the 6.5 s
  frame). H.264 + AAC 128k, `+faststart`, CRF 28. It stays well under the 25 MiB Workers asset
  limit, so it's served as a static asset (no R2).
  `_headers` caches `/assets/film/*` for a day.
- **Byte ranges:** Workers static assets ignore `Range` and always send the whole file with 200, and
  Safari won't play a video that way. So `/assets/film/*` is in `run_worker_first`, and
  `servePartial` in `site/gallery-link.js` answers ranges with 206: it fetches the file from
  ASSETS and streams only the requested bytes. ASSETS gives no length, so the first range request for
  a file reads it through once, counting bytes, and the size is kept per path and ETag. Checked with
  `wrangler dev`. Locally that needs a copy without `export const STORES_LIVE`, which workerd
  rejects as an entrypoint; production accepts it.
- **Search:** the page's JSON-LD has a `VideoObject` for the film.
- **Updating the film:** render the web master without the label in `Marketing/casama/showreel`:
  `sh scripts/render.sh LaunchHero ../out/web/en-US/film-16x9-1920x1080.mp4 --props='{"label":null}'`.
  Then re-encode with
  `ffmpeg -c:v libx264 -preset slow -crf 28 -pix_fmt yuv420p -movflags +faststart -c:a aac -b:a 128k`
  under the same name, and run `scripts/deploy-web.sh`.
- **Code:** `site/index.html` (the button, `#reel`, `dialog#film`, JSON-LD), `site/site.css` (the
  film section), `site/site.js` (the section's video and the dialog).

## D-391 Casama is the first starter bot; every starter bot's name is its own

- **Decision (Oliver, 2026-11-18):** "add of course `Casama` as our 1st and top priority bot which is an all in one personal assistant. apply to the app and websites", and give the starter bots that shared a name new ones: Elena, Fernando, Edlene, Levic, Jeff, Amy, Kim, Phoebe, Carol, Matty, Gerard.
- **The Casama starter bot:** id `casama`, job "Personal assistant", category Work, mascot winky (the personal bot's), icon `sparkles`, asks before risky actions. Its persona covers email and calendar, research and decisions, errands in its own browser, things made into the Library and routines; it never pays, sends, books or deletes without asking, and suggests a bot of its own for a big job that keeps coming back. It is first in `BOT_TEMPLATES`, so the app's persona picker, `GET /v1/templates`, casama.ai/bots and the gallery list it first, with a gallery copy in `gallery/bots/casama` (featured).
- **Its name is Casama:** `starterBotName("casama")` is "Casama", the only starter bot name outside `BOT_NAMES`.
- **The personal bot starts as it:** `startWelcome` gives a new workspace's personal bot the Casama persona (`personalBotPersona()`), under whatever name the person picked; it was one line ("You are Casama, this person's personal assistant…"). Existing personal bots keep the instructions they have.
- **Names:** the 12 gallery-only starter bots added after D-382 took their names from the hash, and 11 of them repeated another bot's (four Jasons, three Juanchos, and a second Anna, Oliver, Dawn, Bryan, Theo and Jojo). Each now has its own: Event planner → Elena, Home scout → Fernando, Newsletter editor → Edlene, Contract reader → Levic, Job hunt coach → Jeff, Personal shopper → Amy, Language partner → Kim, SEO writer → Phoebe, Customer success → Carol, Family organizer → Matty, IT helpdesk → Gerard, and Bookkeeper keeps Kitsune, now pinned. All 41 of Casama's starter bots have a name of their own (a test reads `gallery/bots`). A community starter bot gets a name from the list that none of Casama's own has.
- **casama.ai:** the first "Give every bot a job" card is "Casama, personal assistant" (was Anna's), and the home row of bot chips starts with Casama (Coordinator left the row). The hero chat, the film and the dinner walk-through still follow Anna, as the v5 film does, until the next film opens on Casama.
- **Reaches the app with the server:** names and the template list come from the server, so the app shows Casama first and the new names after the next server deploy. Until then an older server lists the gallery's `casama` copy last, under a name from the old list.
- **Code:** `packages/domain/src/templates.ts`, `packages/agent/src/welcome.ts`, `gallery/bots/casama/`, `site/build.mjs` (`HOME_BOTS`), `site/index.html`, `docs-site/guide/bots.md`.

## D-392 Casama on the Snap Store: a classic snap of the bundle we already build

- **Decision (2026-11-18, Oliver: "we got approved on snapcraft.io so what now?", then "help me
  decide all of that", "don't upload release yet"):** the snap name `casama` is ours. Nothing is
  uploaded yet.
- **Classic, not strict.** What sets the desktop app apart is reaching outside itself: bots using
  this computer (the companion's files and terminal), running your own server with Docker
  (guided setup), quick ask reading the front window with X11 tools. A strict snap can do none of
  that, and one store name can't carry two editions. Classic needs a manual review on
  forum.snapcraft.io ("classic confinement request"); the case is the one IDEs and terminals
  make: the app runs commands the person asked for on their own machine. If it's refused, ship
  strict with those features off, the way the Mac App Store build does (`isMacAppStoreBuild` in
  `client/lib/core/distribution.dart`, which would grow a `snap` distribution).
- **Packs the existing bundle, no second Flutter build.** `snap/snapcraft.yaml` dumps the bundle
  from `scripts/package-linux.sh`, unpacked by `scripts/package-snap.sh`. Libraries a desktop may
  lack (Ayatana indicator for the tray, jsoncpp, libsecret) are copied into the bundle's `lib/` and
  the plugins get `RUNPATH=$ORIGIN`; nothing sets `LD_LIBRARY_PATH`, because in a classic snap it
  would leak into every command a bot runs on the computer. GTK and the rest come from the host.
- **Built in CI.** The hand-started "Desktop apps" workflow packs the snap on both Ubuntu 24.04
  runners (amd64, arm64) next to the tar.gz and keeps it as an artifact. Publishing stays a
  separate, asked-for step.
- **Release path:** install the artifact on real Ubuntu with `snap install --classic --dangerous`;
  until classic is approved, uploads can only go to `edge` and wait in review; after approval,
  `edge`, then `stable`. Then `GET_LINKS` in `site/gallery-link.js` points Linux at
  snapcraft.io/casama (D-377).
- **To check on a real install:** the tray, the global shortcut through the GNOME portal (snapd
  names the desktop file `casama_casama.desktop`, not `ai.casama.app.desktop`), `casama://` links,
  and that `linux_desktop_entry.dart` writes no second entry (it skips when `$SNAP` is set).

## D-393 A chat never says "Thinking…" for a run it has stopped hearing

- **Why:** on 2026-11-18 a run paused on its fourth approval (`shell.exec`, high risk) while the
  chat on screen kept saying "Thinking…" with no card. The server was right: run
  `waiting_approval`, event 182 `approval.requested`, every event readable by the Dart SDK. The
  chat had stopped applying events at 179 (its usage line stayed at event 178's count). The exact
  break wasn't caught, but every way to get there has the same result: nothing follows the run
  while the chat still says it is running.
- **Watchdog in the chat (`chat_controller.dart`).** While a run is on screen, a 10 s tick counts
  silence. After 20 s with no event (or at once if nothing follows the run, for example after a
  reload failed half-way), the chat reads the run (`GET /v1/runs/{id}`). If the server's
  `last_seq` is past the last event shown, the chat follows the run again from there
  (`watchRun(afterSeq:)`) and reports it as a warning. A run that is only quiet (a long step,
  waiting on a person) is asked after 20, 40, 80, then every 160 s. It counts ticks, not clock
  time, so a clock that jumps can't trip it.
- **Catch-up can't wedge (`supabase_backend.dart`).** Each catch-up request has a hard 20 s limit
  that covers the auth step too (Dio's timeouts start only once it connects); otherwise one
  request that never returns keeps every later poll out. An event the app can't parse is skipped
  (`RunEventBuffer.skip`) and reported, instead of holding back every event after it. Five failed
  catch-ups in a row are reported once.
- **A reply taken back says so.** When the server pulls back a finished reply for another look
  (D-231 missing file links, D-269 verify), the working line says "Checking its work…" until the
  bot does something else. Before, the reply just disappeared.
- **Reloads:** `open()` resets the "events applied" counter when it rebuilds the thread from saved
  messages, so the watchdog never resumes from a seq whose events are no longer on screen.

## D-394 Full access: one workspace switch so bots stop asking; "Act on its own" and "Always allow" cover your Mac

- **Why** (Oliver, 2026-11-18: "support like claude and chatgpt full permission or bypass permission
  switch", then "even though I gave all access to the bot it still asks me a native macOS dialog"):
  a bot working on the person's own Mac kept stopping for every `rm -f` outside `~/workspace`.
  D-066 made high-risk steps there ask whatever the autonomy, and the check ran before grants, so
  **Always Allow** and **Act on its own** did nothing. Approving a high-risk step then asked for the
  Mac password ("Confirm risky actions", D-375).
- **Decision:**
  - `needsApproval` (`packages/domain/src/approvals.ts`): a grant ("Always allow" rule) or the
    `autonomous` level now covers high-risk steps on the person's own Mac. Without either, they
    still ask under `ask_risky` and `ask_always` (D-066 otherwise unchanged).
  - **Full access** (`organizations.full_access`, default off, migration
    `20270203100001_full_access.sql`): when on, nothing asks for any bot in the workspace,
    whatever its autonomy. That includes tools marked `alwaysAsk` that widen a bot's reach
    (`mcp.add`, `connections.attach`, loosening its own rules, notifications back to usual hours).
  - **Still asks with full access:** tools marked `askEvenWithFullAccess` (only
    `payments.request`), and the workspace's own **Ask me first** rules. Password and two-step
    changes are still handed to the person, and **Hand it to me to finish** rules still apply.
    OS permission and device access cards (D-328, D-376) need a tap on the device, so they're
    unchanged.
  - The gate reads the switch on every tool call, so turning it on or off applies to running bots
    at once. Approvals already waiting stay waiting.
  - Owners and admins change it through `PATCH /v1/orgs/{id}/settings` (`full_access`), and it goes
    in the audit log as `org.settings`. Members can read it. Bots can't change it: workspace
    settings are out of their reach (D-242).
  - **App:** Workspace settings → **Full access**, outside the Advanced fold. Turning it on shows a
    warning and then the "Confirm it's you" check. Turning it off needs neither.
- **The "working on this computer" bar is a floating card** (Oliver: "not the best place … maybe a
  floating card"): `CompanionOverlay` used to insert a full-width bar above the whole app, which
  pushed every screen down while a bot acted on the Mac. It's now a rounded card floating just
  below the header and the chat's topic chips, so it moves nothing and covers no buttons. It uses
  the theme's tertiary colors so it stands apart from chat bubbles in light and dark. It shows the
  bot's own mascot, animated, with a pulsing working dot, then the step and Stop. A long step
  shows one line, and tapping the card shows up to six. It hides while the Mac's notch shows the
  same thing with Stop (D-324). The window still stays on top (D-066). Debug builds show a sample
  card with `?previewActing=1`, so it can be checked on the web.
- **Tests:** `packages/domain/test/autonomy.test.ts` (Mac grants and autonomy, full access under
  every level), `packages/agent/test/full-access.test.ts` (off by default; on: high-risk and
  always-ask tools run; payments and ask rules still ask), `apps/server/test/full-access.test.ts`
  (members can't change it, admins can, audit), `client/test/full_access_test.dart`,
  `client/test/companion_test.dart` (the card floats without moving the app; hidden with the notch).

## D-395 The instance owner sees what usage cost the server, next to what it charged

- **Decision (2026-11-18, Oliver asked whether the costs the app shows are real or marked up, then
  chose "admin only version yes 1-3"):** the prices in the app are what workspaces are charged
  (provider price × 1.055 OpenRouter fee × the markup in `billing_settings`). The cost behind them
  is now kept per row and shown only to the instance owner. Members and workspace owners keep
  seeing the price only, as before; a margin next to every reply would invite "why am I paying
  more" and make the credits look like a bad deal against your own key.
- **Ledger:** `usage_ledger.upstream_cost_usd` is what the server's operator paid upstream for the
  row, fees included: OpenRouter calls (model tokens, voice to text, spoken audio, media) at
  `cloudOpenRouterCost` = price × 1.055; Gemini Live and phone-call voice, Composio app calls and
  paid data at the provider's price. It is null when the workspace's own key or ChatGPT plan paid,
  and for computer time, which runs on the server's own machines and has no cost per row. A live
  call's hold has cost 0 (nothing was paid yet), and its settling row carries what the call cost.
  Composio calls on the server's account carry their cost even where they aren't billed, because
  the operator still pays.
- **Earlier rows:** the migration fills the column from `meta.provider_cost_usd`, which rows on the
  server's keys already had (× 1.055 where it went through OpenRouter). A model call's two rows (in
  and out) each carried the whole call's price, so the cost is split between them like the charge.
  Voice-call rows use their price including the listening floor. Casama Link's model calls kept no
  price, so their cost is the charge over today's markup, which is wrong for rows charged before a
  markup change.
- **Who can read it:** members read their workspace's usage rows through PostgREST
  (`usage_ledger_select`), so the column is left out of their select grant (column grants;
  `revoke select` from anon and authenticated, then grant every other column). A later column has
  to be added to that grant. The data export lists the columns instead of `select *`.
  `meta.provider_cost_usd` is still readable by members there; hiding it is a separate change
  (server queries read `meta` in members' sessions).
- **API:** `GET /v1/runs/{id}/usage` adds `upstream_cost_usd`, the total and per item, for the
  instance owner only (`isInstanceOwner`: `INSTANCE_ADMIN_EMAILS`, else the first account). The field
  is absent for everyone else, not null. `GET /v1/admin/margin?days=` (1–90, default 30, owner only)
  returns charged, charged with a known cost, and cost: in total, per UTC day, per kind, and for
  the top 20 workspaces by charge. Margin is over the rows with a known cost; waived rows count as
  cost with no charge.
- **App:** the admin console's overview gets a **Usage margin** card (7, 30 or 90 days: charged,
  our cost, margin and its share; computers said apart; by kind; top workspaces). For the instance
  owner, the reply breakdown (D-307) adds **Our cost** and **Margin** and an "Our cost $…" on each
  line, with a note that nobody else sees them.
- **Not done:** web search on the server's chain (Casama pays, nothing is charged) isn't marked as
  the server's cost, because the ledger can't tell it from a workspace's own search key. The cost
  of computers per hour isn't tracked.

## D-396 casama.ai's page views reach Google Analytics 4 from the server, without cookies

- **Decision** (Oliver, 2026-11-18: "casama.ai is still not connected to GSC and GA4 get those
  connected"; then "GA4, cookieless", then the server-side fix below): casama.ai's own anonymous
  count (`/b`, site/gallery-link.js) is also forwarded to GA4 with the Measurement Protocol, into
  the web stream `G-4GVRF0K324` of the Casama GA4 property `properties/563408057`. Search Console
  (`sc-domain:casama.ai`) is linked to that stream. The Worker reads the API secret from the
  `GA_API_SECRET` Worker secret (Vaultwarden: "Casama · GA4 Measurement Protocol API secret").
- **Why:** search work needs landing-page numbers next to Search Console queries. The first try,
  gtag in the browser with consent mode "denied", sets no cookies but GA4 only models such pings
  and reports nearly nothing without consenting users; GA4 has no other cookieless browser mode.
- **What Google gets:** one `page_view` per count with the page, the referring host, the source
  kind, the country from Cloudflare and phone-or-not, under a random client and session id per hit
  (so GA can't tie views together, and its "users" equal page views) and no IP address. No Google
  script runs on casama.ai and the site still sets no cookies; the privacy page says so.
- Only casama.ai. Skipped when the secret isn't set (local runs, self-hosted copies). Accepting
  GA4's user-data collection acknowledgement was needed to create the secret.

## D-397 Product events go to Google Analytics 4 as well as PostHog; one setting picks providers

- **Context (2026-11-18):** Oliver: "can we also support GA4 so it's a free alternative? but can we keep
  both for now?", then "make it easier for other self hosters to be disabled/enabled". PostHog project
  637030 is shared and past its free tier; GA4 is free. Plan: `docs/GA4-PLAN.md`.
- **Decision:** the catalog events go to every configured provider.
  - **Server:** `ProductAnalytics` fans out to PostHog and to GA4 over the Measurement Protocol
    (`packages/observability/src/ga4.ts`). It sends to one web stream with `user_id` = Casama user id.
    GA4 doesn't get personless events or the `usage_daily` / `workspace_daily` rollups. `purchase` carries
    `currency` and `transaction_id`.
  - **App:** a sink layer in `client/lib/core/analytics.dart` adds a GA4 sink (`firebase_analytics`) on
    iOS, Android, macOS and web. Windows and Linux are left out: there's no plugin, and the API secret can't
    ship in the app.
- **Choosing providers:** `ANALYTICS_PROVIDERS` (`posthog`, `ga4`, `posthog,ga4`, `none`) on the server
  and in `client/config/telemetry.json`. On the server, unset means every provider whose keys are set,
  so a self-hoster turns GA4 on just by adding keys and narrows the list with one line. In the app, unset
  means PostHog when its key is set, and GA4 only with `GA4_ENABLED=true` (the Firebase settings are there
  for push anyway, so they alone don't turn GA4 on); the web also needs `FIREBASE_WEB_MEASUREMENT_ID`. `PRODUCT_ANALYTICS=on` stays the
  server's master switch. Casama Cloud sets `posthog,ga4`.
- **Same rules as PostHog:**
  - one "Share usage data" switch covers both, and the workspace switch is honored;
  - nothing reaches GA4 from a self-hosted server, and the daily ping stays PostHog-only;
  - app collection is off in the native manifests until consent is checked;
  - no ad ids (no IDFA, no `AD_ID`), Signals and ad personalization are off;
  - purging an account asks GA4's User Deletion API to delete it by user id and the derived client id
    (`GA4_PROPERTY_ID`, `GA4_SERVICE_ACCOUNT_JSON`);
  - the catalog test enforces GA4's names and limits.
- **Not done:**
  - no hand-off of the app's GA4 instance id to the server, so server events go to their own stream;
  - no dedupe of retried server events in GA4;
  - GA4 keys, streams, custom dimensions and the Apple/Play privacy forms aren't set. The Firebase-linked
    property "kasama-ai" exists; its "Kasama (web)" stream belongs to casama.ai (D-396), and the server and
    web app need their own streams.

## D-398 GA4 funnels end to end: recommended events, website funnel events, a daily visitor id, setup and funnel scripts

- **Context (2026-11-18):** Oliver: "make sure we have a robust GA4 analytics and funnel implementation in
  both flutter apps and websites". This builds on D-396 (casama.ai page views to GA4 from the Worker) and
  D-397 (catalog events to GA4). Details are in `docs/GA4-PLAN.md`, "Funnels and the websites".
- **Recommended events:** catalog events can name a `ga4_twin` (`sign_up`, `login`, `tutorial_begin`,
  `tutorial_complete`, `begin_checkout`, `share`, `join_group`). The app and server GA4 sinks send the twin
  next to the event, and PostHog never sees it. `pnpm gen` writes the twins for both sides, and the catalog
  test keeps them valid. Server events that carry `plan` also set GA4's user property `plan`.
- **Websites:** casama.ai's Worker is the one collector for casama.ai, the docs, the gallery and casama.link
  (the last three beacon to `https://casama.ai/b` with a site key).
  - **This changes D-396:** each hit's id is no longer random. It's a daily id: an HMAC of the UTC date, IP
    and user agent, keyed with the GA secret. Nothing is stored, no cookie is set, no IP is sent, and the id
    rotates at midnight UTC. This is what makes site funnels possible: GA4 can join one browser's page views
    and clicks within a day.
  - **Worker routes become funnel steps:** `start_click` (/get/start), `download_click` (/get/<platform>),
    `qr_open` (/get), `invite_open` (/i/<code>, without the code) and `gallery_open` (item type only).
  - **Allowlisted page events:** `film_play`, `copy_install`, `plan_click`, and `start_click` for direct
    links to the web app.
  - **Hand-off:** the web app link gets `utm_source=casama.ai&utm_medium=website&utm_campaign=<page>`, and
    Play links get the same values as an install referrer, so GA4 credits app sign-ups to the page.
    App Store links are unchanged (campaign links need Apple's provider token).
  - The privacy page says all of this.
- **Property setup and funnels as code:**
  - `scripts/ga4-setup.mts` (dry run by default, `--apply`; only adds, never deletes): custom dimensions,
    key events, 14-month retention.
  - `scripts/ga4-funnels.mts`: funnels W1 and F1–F8 via the Data API `runFunnelReport`, with production
    filtering and breakdowns.
- **Not done:**
  - Credentials for the scripts. The gcloud sign-ins on this machine lack Analytics scopes; a service
    account added to the property, or a scoped `gcloud auth login`, is Oliver's.
  - The server and web-app GA4 streams and keys (D-397).
  - Deploying the sites and the Worker.
  - The pricing page has no per-plan buttons yet, so `plan_click` waits for them.
  - Funnel numbers can't be checked until data arrives.

  connected", then picked "GA4, cookieless"): casama.ai loads GA4 (`G-4GVRF0K324`, the unused web
  stream in the Casama GA4 property `properties/563408057`) from `site/site.js`, with consent mode
  defaulting every storage type to `denied`. gtag then sets no cookies and sends anonymous pings
  that GA models into traffic; Search Console (`sc-domain:casama.ai`) links to that stream.
- **Why:** search work needs landing-page and engagement numbers next to Search Console queries.
  The site's own anonymous count (`/b`) only says which page and which kind of referrer.
- **Changed:** the privacy page no longer says "no tracking scripts"; it says casama.ai uses
  Google Analytics without cookies and what Google receives. The site still sets no cookies.
  Only casama.ai: the docs, gallery and apps don't load GA. localhost skips it.

## D-400 The margin view covers every charge: computer time and the server's own web search

- **Decision (2026-11-18, Oliver on D-395's gaps: "we should cover all the charges"):** every
  usage row the server pays for now carries `upstream_cost_usd`, so the Usage margin card no
  longer leaves computers out or misses search.
- **Computers:** the cost is the provider's rate (`computerProviderCostUsd`): `COMPUTER_RATES`
  and its defaults, never Admin → Pricing (D-373), which is what workspaces are charged. Docker
  $0.003 per vCPU-hour + $0.005 per GB-hour, E2B and Daytona their published prices, Casama
  Cloud's computers (what a self-hosted server pays Casama) $0.05 per vCPU-hour. A person's own
  computer has none. The Docker default is a Hetzner CPX42 spread over what it holds; production
  runs on an $11 Contabo VPS, so setting `COMPUTER_RATES` there to the real share (about $0.0017
  per GB-hour with 9 GB for computers) makes the margin true. Casama Link computers count one size
  step of Docker an hour (they record no size).
- **Search:** answers from the server's chain carry `serverPaid` (`ServerPaidSearchProvider`
  wraps each server provider), and their price becomes the row's cost, still not charged. A
  workspace's own key and cache hits have none.
- **Earlier rows:** computer time is filled at the default rates from each computer's provider
  and size (Link rows at $0.008 an hour). Earlier searches can't be told apart, so they stay
  without a cost.
- **App:** the card's "with no cost recorded" replaces "for computers", and its note says
  computers count at their provider's rate and the server's search counts as cost.
- **Still not per row:** embeddings for memory and knowledge (OpenRouter's
  text-embedding-3-small, about $0.02 per million tokens, not in the ledger at all), live view
  over Cloudflare TURN (first 1,000 GB a month free), and email. They are fixed or tiny and stay
  in docs/COSTS.md.

## D-399 Windows and Linux send GA4 events through the server; their builds finally carry the analytics keys

- **Context (2026-11-18):** Oliver asked whether every Flutter build has the analytics. `firebase_analytics`
  doesn't run on Windows or Linux, so those had no GA4 (D-397). And although `posthog_flutter` 5.61 does run
  there, the desktop workflow takes the keys from the repo secret `CASAMA_TELEMETRY_JSON`, which didn't
  exist: the Windows and Linux builds had no PostHog or Sentry at all.
- **Decision:**
  - The secret now holds the PostHog key, the app's Sentry DSN and `GA4_ENABLED=true`.
  - Windows and Linux get `Ga4RelaySink`. It batches catalog events and screen views to
    `POST /v1/analytics/events`, and the server forwards them to GA4 only (`CaptureOptions.only`).
  - The server forwards only catalog app events with their catalog properties (the allowlist is generated
    as `ANALYTICS_CLIENT_EVENTS`), adds their twins, sends screens as `page_view`, and drops everything for
    opted-out people or when it has no GA4 keys.
  - The Measurement Protocol secret never ships in an app.
- **Same rules:** the "Share usage data" switch, Casama Cloud only, and signed in only (the endpoint needs a
  session; events from before sign-in are dropped).
- **Not done:** no endpoint test with a real database (the filter is unit-tested). The first Windows or
  Linux build from the workflow will be the live check.

## D-400 The margin view covers every charge: computer time and the server's own web search

- **Decision (2026-11-18, Oliver on D-395's gaps: "we should cover all the charges"):** every
  usage row the server pays for now carries `upstream_cost_usd`, so the Usage margin card no
  longer leaves computers out or misses search.
- **Computers:** the cost is the provider's rate (`computerProviderCostUsd`): `COMPUTER_RATES`
  and its defaults, never Admin → Pricing (D-373), which is what workspaces are charged. Docker
  $0.003 per vCPU-hour + $0.005 per GB-hour, E2B and Daytona their published prices, Casama
  Cloud's computers (what a self-hosted server pays Casama) $0.05 per vCPU-hour. A person's own
  computer has none. The Docker default is a Hetzner CPX42 spread over what it holds; production
  runs on an $11 Contabo VPS, so setting `COMPUTER_RATES` there to the real share (about $0.0017
  per GB-hour with 9 GB for computers) makes the margin true. Casama Link computers count one size
  step of Docker an hour (they record no size).
- **Search:** answers from the server's chain carry `serverPaid` (`ServerPaidSearchProvider`
  wraps each server provider), and their price becomes the row's cost, still not charged. A
  workspace's own key and cache hits have none.
- **Earlier rows:** computer time is filled at the default rates from each computer's provider
  and size (Link rows at $0.008 an hour). Earlier searches can't be told apart, so they stay
  without a cost.
- **App:** the card's "with no cost recorded" replaces "for computers", and its note says
  computers count at their provider's rate and the server's search counts as cost.
- **Still not per row:** embeddings for memory and knowledge (OpenRouter's
  text-embedding-3-small, about $0.02 per million tokens, not in the ledger at all), live view
  over Cloudflare TURN (first 1,000 GB a month free), and email. They are fixed or tiny and stay
  in docs/COSTS.md.

## D-401 Help on the websites: one FAQ, a Help page, and Casama Help for visitors

- **Decision (2026-11-18, Oliver asked whether our FAQs were the best, searchable and complete, and whether to add a chat support agent to the websites "safe from being abused", then "go and build everything in one go"):**
  - **One FAQ.** `docs-site/faq.md` is the only FAQ: 58 questions in nine groups (Getting started, Plans & billing, Account & data, Bots/apps/chat apps, Safety, Self-hosting, Casama Link & Pages, Building, Getting help), written only from the docs, site pages and decisions; unsettled or unshipped things are left out. casama.ai's builder parses it for the new **casama.ai/help** page (one box that filters the questions as you type, then "Ask Casama Help about …"), the pricing page's billing questions, and FAQPage structured data there, on the homepage and on docs.casama.ai/faq, which also gets a filter box. Since the support assistants read the docs, every FAQ fix reaches them within the hour.
  - **Casama Help on casama.ai and docs** (not the gallery, casama.link, casama.page or the web app, which has the signed-in assistant): a small "Questions" button bottom-right (on the homepage only after the hero), no pop-ups; it opens a side panel (a full-screen sheet on phones). The widget's code loads on the first tap. The Help page shows the same chat inline, and the docs search offers "Ask Casama Help about …" under its results. Conversations live in the browser tab only.
  - **Same knowledge, no account.** It runs in the API (`/v1/support/web/{config,session,chat}`, `support-web.ts`) on the same docs index and the same shared prompt rules as the app's assistant (`SHARED_RULES` in `support.ts`), but its tools are only `search_docs`, `get_plans`, `note_gap` and `decline_off_topic`: nothing that reads an account or acts, so a jailbreak has nothing to reach. Account questions get "sign in and open Help & support, or email support@casama.ai", never a guess. Both assistants' index now also holds casama.ai's /learn, /compare, pricing, security, self-hosted, about, open-source and bots pages (shipped with the server from `site/content`), and the FAQ is split at each question so a search returns one answer.
  - **Abuse fences:** CORS and an Origin check for casama.ai, www and docs only (`SUPPORT_WEB_ORIGINS`); in production it runs only with Cloudflare Turnstile keys (widget "Casama Help (websites)", managed mode), which buy a two-hour session signed with a key that lives only in the API process and tied to the hashed address; per address one request at a time, 5 a minute, 20 messages and $0.10 a day, 8 messages a session, three off-topic requests pause it for 24 hours; a message is at most 1,000 characters, the newest 8 messages and 8,000 characters reach the model, answers stop at 600 tokens and 3 tool rounds; **its own daily budget** `SUPPORT_WEB_DAILY_USD` ($5), apart from the app's $10, with a Sentry alert at 80%; and **its own OpenRouter key** (`SUPPORT_WEB_UPSTREAM_KEY`, $100 a month at OpenRouter) so a bug in our counters still stops there. Any limit or outage shows the FAQ and the support email, never a dead end. `SUPPORT_WEB=false` turns it off. Self-hosted servers have no Turnstile keys, so it stays off there.
  - **Model:** `SUPPORT_WEB_MODEL`, else `SUPPORT_MODEL`, else the cloud chat default (DeepSeek V4.1 Flash, already on the guardrail allowlist, D-364).
  - **What's kept:** daily counters in `support_usage` (`web:all`, `web:ip:<hash>`), and questions the docs didn't answer in `support_web_gaps` (no account, address or session; emails, links and phone numbers taken out; 90 days). Admin console → Support shows today's messages, spend against the budget, paused addresses and those questions, so the FAQ grows from what people really ask. The privacy policy says so.
- **Why:** visitors deciding whether to sign up ask the same questions support gets, and the only searchable FAQ was the docs'. Reusing D-298's assistant keeps one source of truth and one set of fences; the stricter, separate budget and key keep an open endpoint from becoming a free model API or eating help for paying customers.

## D-402 Deploys nobody notices: Caddy holds requests, the new API starts first, the worker hands over at a step, interrupted runs pick up by themselves

- **Decision (2026-11-18, Oliver asked whether every server deploy interrupts people and bots, then asked for a deeper look, then "build all in 1 go now"):** plan and measurements in `docs/SMOOTH-DEPLOYS-PLAN.md`. Before this, each of the ~17 deploys a day left the API unreachable for roughly 9–14 s (messages "Not sent", screens erroring, credit calls dropped), cut the worker mid-step, and killed runs whose saved steps the new code had changed (2 of 9 failed runs in three days).
- **Caddy holds requests (`(api_hold)` in `infra/compose/selfhost/Caddyfile`, also in `sites-edge-true.caddy`):** `lb_try_duration 30s`, `lb_try_interval 250ms`, `request_buffers 4MiB` on every `reverse_proxy` to the API. A request that can't connect waits for an API to answer instead of failing with 502; Caddy retries only dial failures, so nothing is sent twice. Checked with Caddy 2.10.2 on Docker: GET and small POSTs wait through a missing container, a container that stopped listening, and two containers under one name where one is gone; WebSocket upgrades wait too. Without `request_buffers` a POST failed ("invalid Read on closed Body"); a body over 4 MiB that arrives in the gap still gets a 502.
- **The API stops in order (`apps/server/src/api/drain.ts`):** it stops listening, closes desktop-app, live-view and terminal sockets with 1012 "server restarting" (they redial), waits up to `API_DRAIN_SECONDS` (30) for requests in flight (counted by wrapping `fetch`), then closes call relays and phone bridges with 1012 after their usage is written, then every connection left. **SIGUSR2 is a handover:** calls are carried until they end or `CALL_HANDOVER_SECONDS` (600) runs out; a second signal cuts that short. SIGTERM (a plain restart, Kubernetes) skips the carrying. Call relays (`relayedCalls`), phone bridges (`phoneCalls`) and terminals register in an `OpenSockets` set. Compose: `stop_grace_period` 45 s for the API, 60 s for the worker; Helm: `terminationGracePeriodSeconds` 45/60.
- **`scripts/deploy-prod.sh` starts the new API first:** copy `.env` → fast-forward → build → back up the database → `compose run migrate` → stop any API the previous deploy left carrying calls (SIGTERM, so its calls resume on the current API) → `compose up -d --no-deps --no-recreate --scale api=N+1 api` → wait for the new container's `/readyz` (from inside it) → for each old API: `restart=no`, SIGUSR2, recorded in `/root/casama-api-draining`, and a detached `timeout <handover+120 s> docker wait; docker rm -f` → `compose up -d --no-deps` for every other service (the worker drains) → Caddy recreated when its config files changed → checks. The API is skipped when its compose config hash is unchanged. A new API that doesn't answer is removed and `.env` put back while the old one keeps serving; failed migrations put `.env` back too. Runs no longer block a deploy: the dry run reports working and waiting runs, `--wait-runs N` is optional (default 0), `--force-runs` is accepted and does nothing. Containers are found by compose service, not by `casama-api-1`. Checked with a scratch compose project: the second container runs the new config, requests reach only the new one while the old drains, and a later plain `compose up -d` removes the exited extra and leaves the new one alone. The first deploy with this script sends SIGUSR2 to an API without the handler, which exits at once (calls dropped that one time).
- **The worker hands over at a step (`apps/server/src/worker/drain.ts`):** every agent-run step (and the wait checks) goes through `gatedStep`. On stop, `drainSteps(WORKER_DRAIN_SECONDS, 45)` lets steps in flight finish and be saved and holds every run at its next step, which never starts in this process; the next worker recovers the run (DBOS) and continues there. While draining, `agentRunWorkflow` records nothing on an error (it would otherwise mark the run failed). Tested with a real worker process (`graceful-stop.test.ts`): SIGTERM while the final answer streams exits 0 with `steps_cut: 0`, and on the next worker the reply finishes with the same deltas, one tool call and one message (a SIGKILL streams it twice).
- **Interrupted runs pick up by themselves (`continueAfterUpdate`, `pickupNote` in `packages/agent/src/run.ts`):** when a replay no longer matches the code (DBOS 26/37), a person's own chat run, in the app or a chat app (not group, routine, call or subagent; once; never a pickup of a pickup), gets a new run in the same chat, with the same trigger so a chat app's reply goes back there, whose task is a note: it was interrupted by an update, the actions it had started (`tool.started` events, last 30, arguments cut at 200 characters), and to check before repeating anything that sends, posts, pays, deletes or changes. The old run fails with code `updated` and "Casama was updated while this was going. Picking up where it stopped…"; its request gets no "ended without a reply" note in later history. Pending approvals are asked again by the new run. Messages sent during the old run stay with it and are seen in the history. `arrivedMessages` and `followUpRun` compare ids as text, since a pickup run's current item is `task-<run id>`.
- **Sends are safe to retry:** `sendMessage` already declared `Idempotency-Key` and the middleware replays a finished request; a UUID key is now also the user message's id, so a retry arriving while the first send is still being answered hits the primary key and returns the first one's result (`send-retry.test.ts`, including two at once).
- **The app (no build yet):** call resume tries at once, then again for about 30 s (0.5, 1, 2, 4, 8, 15 s), each with a 10 s connect timeout; "Not sent" retries by itself on connection errors and 502/503/504 (1, 2, 4, 8, 15 s) with one Idempotency-Key per message, kept for the manual Retry; the terminal reconnects on 1012 (1, 2, 4, 8 s, showing "Reconnecting…"); the island drops a run only after 45 s of failed reads.
- **Rule:** a migration must work with the build before it (the old API answers for seconds after migrations run and carries calls for minutes), so a column or table is dropped in the deploy after the code stopped using it. In `docs-site/develop/contributing.md` and the `casama-contribute` skill.
- **Not done:** starting the new worker before stopping the old (needs distinct DBOS executor ids and re-queuing the old one's runs; plan Phase 3b); Kubernetes rolling updates for the API get SIGTERM, so calls there resume rather than being carried. The worker's `Recreate` strategy in Helm prevents two workers from picking up the same runs.
- **Tests:** `apps/server/test/drain.test.ts`, `graceful-stop.test.ts`, `send-retry.test.ts`, the 1012 cases in `live-relay.test.ts` and `computers.test.ts`, `packages/agent/test/pickup.test.ts`, and the app's tests listed in the plan.

## D-403 The product moves to AGPL-3.0; what people build with stays Apache-2.0; a CLA for every contribution

- **Decision (2026-11-18, Oliver, after asking what to do if someone sells a modified Casama):** new work on the product (server, worker, supervisor, browser extension, agent, sandbox, database, the apps, `dart/computerd`, infra, websites, scripts) is under **AGPL-3.0-only**. What people build on Casama with stays **Apache-2.0**: `packages/client`, `packages/mcp`, `packages/plugin-check`, `dart/casama_api`, `dart/casama_sdk`, `dart/cli`, `agent-kit/`, `examples/`, `packs/`, `docs-site/`, the OpenAPI document, and the 13 shared format files in `packages/domain/src` that `plugin-check`, `mcp` and `client` import (each starts with `SPDX-License-Identifier: Apache-2.0`). `ee/` keeps the Casama Enterprise License. Gallery items keep their own licenses.
- **Why AGPL and not FSL/BSL/ELv2:** it stops a company from selling a changed Casama without sharing its changes, and it is still OSI open source, so the "open source" claims, badges and list entries stay true and self-hosters lose nothing. Organisations whose policy forbids AGPL can buy a commercial license (Stackwares holds the copyright, and the CLA keeps it able to). Keeping the interfaces Apache-2.0 means plugins, bots, integrations and apps built on Casama are never caught by the copyleft.
- **Earlier versions:** at first every commit up to `e2ee725d` was to stay Apache-2.0 and the docs said so; D-406 restarted the public history instead.
- **Files:** `LICENSE` is now the AGPL-3.0 text (GitHub's canonical copy); the Apache text moved to `LICENSES/Apache-2.0.txt` and is copied as `LICENSE` into each Apache-2.0 folder; the server image also copies `LICENSES/`. `package.json` license fields, the snap, OCI image labels (`publish-images` workflow and script, backup and computer Dockerfiles) say `AGPL-3.0-only`; the Homebrew formula (the CLI) and the SDK, MCP and plugin-check packages stay `Apache-2.0`.
- **CLA for everyone:** `ee/CLA.md` moved to `CLA.md` and now covers every contribution (still signed by a pull request comment, still DRAFT for legal review); it promises each contribution stays available under its folder's open-source license. The DCO sign-off stays. CONTRIBUTING, the docs' contributing page, the PR template, `casama-contribute` and the README say so; `ee/CLA.md` points to the root one.
- **Updated everywhere the license is stated:** LICENSING.md (rewritten: the split, what AGPL means in practice, the commercial license), NOTICE, TRADEMARKS.md (AGPL 7(e)), SPEC.md, docs (introduction, FAQ, home, footer, contributing, llms.txt), casama.ai (home, download, terms, privacy, Chrome pages, open source, about, pricing, self-hosted, comparison and alternative pages, product and rival data, structured data), the Firefox listing, launch drafts, Admin → Status ("open-source features only"), ARCHITECTURE.md, CI and `oss-edition.sh` comments. Older decisions (D-073, D-339) stay as written: they record what was true then.
- **Not done (Oliver, with a lawyer):** review of LICENSING.md, CLA.md and the commercial license terms; a CLA bot on pull requests; telling the places that list Casama as Apache-2.0 (awesome lists, Glama, opensourcealternatives.to, store listings already submitted) once this is published; deploying casama.ai and the docs.

## D-404 A monthly email on Resend, from news.casama.ai, with double opt-in on casama.ai's Worker

- **Decision (2026-11-18, Oliver asked whether to set up a newsletter, ruled out ZeptoMail, asked about open-source options, then "start with Resend… set everything up now"):** Casama gets a monthly email: what's new and what's next, once a month at most. Resend holds the list and sends the broadcasts. Listmonk + Amazon SES is the self-hosted way out if the list outgrows Resend's price.
- **Why not ZeptoMail:** its terms allow transactional mail only, and that account carries every sign-in email (D-318). Newsletters also draw more spam complaints, which would hurt `notify.casama.ai`'s reputation and push magic links into spam.
- **Sending:** domain `news.casama.ai` in Resend (us-east-1, verified 2026-11-18), from `Casama <news@news.casama.ai>`, replies to `hello@casama.ai`. DNS on Cloudflare: DKIM `resend._domainkey.news`, return path `send.news` (MX + SPF TXT), `rsend.news` CNAME, and `_dmarc.news` at `p=none` with reports to hello@. Open and click tracking are off.
- **List:** segment "Casama newsletter" (`bcf1b930-…`), topic "Casama updates" (`4b2d83b2-…`, opt-out default, used for the preference page), contact property `signup_source` (the page the form was on). The Resend account is the one shared with sayainvitations.com: move Casama to a team of its own before the list matters.
- **Sign-up (`site/newsletter.js`, routed from `site/gallery-link.js`):** a form in the footer of every casama.ai page (`index.html`, `download.html`, and every page `site/build.mjs` builds from them) posts to `/newsletter/subscribe`. The Worker checks the address, drops bots through a hidden `website` field, limits each IP and address to 5 tries a minute (`NEWSLETTER_LIMIT` rate-limit binding), and emails a confirmation link signed with HMAC-SHA256 (`NEWSLETTER_SECRET`) that works for 7 days. Nobody is stored until they confirm. Opening the link only shows a Confirm button, because mail scanners open links on their own; posting it creates the contact, subscribes it and adds it to the segment and topic. Each step is safe to repeat. Without JavaScript the form still works and the Worker answers with a page.
- **Unsubscribe:** Resend's own link (`{{{RESEND_UNSUBSCRIBE_URL}}}`) in every broadcast. Existing Casama accounts are never added without asking.
- **Secrets:** `RESEND_API_KEY` (full access: contacts need it) and `NEWSLETTER_SECRET` are Worker secrets on `casama-site` and in Vaultwarden ("Casama · Resend API key (newsletter signup…)", "Casama · Newsletter confirm-link signing secret…").
- **Live 2026-11-18:** deployed with `wrangler deploy` in `site/` only (version `2d5fab33`). Checked end to end: hello@casama.ai signed up, the email reached the inbox, Confirm added the contact with source `home`. hello@ stays on the list, so the team gets each issue.
- **Limits (Resend free plan, 2026-11-18):** 1,000 contacts, 3,000 emails a month, 100 a day, and confirmations count too. A broadcast to more than 100 people needs a paid plan, so upgrade before the first issue goes to more than about 90 people. Cost is in `docs/COSTS.md`.
- **Update 2026-11-19 (cooldown):** the rate-limit binding let 18 a minute through in a live test, so the Worker also keeps its own counts in the Cache API: one confirmation email per address per 2 minutes, 10 tries per IP per 10 minutes (per data center).
- **Update 2026-11-19 (Oliver: "how do we onboard users to our newsletter?" then "go with all that now!"):**
  - **Welcome email** once, when someone confirms (or comes back after leaving), never on a repeat confirm: what to expect and three things to try (start free, routines in the gallery, the apps). Its footer and `List-Unsubscribe` / `List-Unsubscribe-Post` headers (RFC 8058 one-click) point at `/newsletter/unsubscribe`, signed with `NEWSLETTER_SECRET` and never expiring; GET asks, POST marks the contact unsubscribed in Resend.
  - **An old confirm link** after confirming shows "You're already on the list" instead of another button.
  - **More places to sign up:** a box at the end of every blog post and the changelog, a `/newsletter` page (`site/content/newsletter.md`, `{{ newsletter }}` token), a "Newsletter" footer link, a "While it downloads" card on `/download` that appears when a desktop download starts, a footer form on every gallery page (posts to casama.ai; source `gallery-…`), and a "Monthly email" link in the docs footer.
  - **Live 2026-11-19:** casama.ai `e8ab54be`, gallery `850f437d`, docs via `scripts/deploy-web.sh`. Checked live: a gallery sign-up got the confirmation, Confirm sent the welcome, the old link said "already on the list", one-click unsubscribe marked the contact unsubscribed, a tampered link got 400.
  - **In the app** (Settings switch, sign-up checkbox, one-time card, Resend sync): built on a separate branch with its own decision number.
- **Not done:** funnel counts for sign-ups (Resend has the numbers); the first issue; a regular monthly issue.
- **Tests:** `node --test scripts/site-newsletter.test.mjs`.

## D-405 Widgets: the home screen, the Lock Screen and controls on iPhone, Android and the Mac

- **Decision (2026-11-18, Oliver asked for "a full suite of widgets for ios and android and maybe macos", then "build all now and you decide everything yourself"):** plan in `docs/WIDGETS-PLAN.md`, mockups in `docs/media/widgets-mockups.html`. Every §13 default was taken except decision 10: Android widgets are RemoteViews, not Glance, because Glance needs the Compose compiler in the Flutter Gradle build and nothing could be built here to prove it; RemoteViews is what `LiveRun.kt` already uses, and Android 12+ sizes and the phone's colours work the same.
- **What a widget shows comes from one summary, the glance,** built by the server (`GET /v1/glance`, `packages/agent/src/glance.ts`) in one transaction as the person (row-level security applies): Needs you (approvals, takeovers, suggestions, skill proposals; the same count as the Chats tab's row), up to 8 bots with status and step in general words, the next 6 routines with `cronWords` schedules plus up to 20 for pickers, the latest brief or when the next comes, what bots last finished, 6 recent creations, the board's counts, credits, and the default bot's starters. It has a content version: `If-None-Match` answers 304. Private (a widget key marked private, or the app lock without **Show details in widgets**) keeps counts, bot names, times and kinds and drops the person's words; `hide_reply_text` drops bots' last messages.
- **Two ways to reach a widget.** The app writes the glance and the widgets' words into the shared store while it's open (`client/lib/features/widgets/glance_sync.dart`; keys in plan §17) and builds a small one from what it has when the server is older. Widgets also fetch it themselves with a **widget key** (`widget_keys`, shown once, stored hashed, `Authorization: Widget <key>`), which works only on the glance, its push-token route and creation covers, 120 requests an hour, and is deleted at sign-out.
- **Refresh pushes carry nothing but "changed".** `GlancePusher` sends needs-you changes within half a second and everything else at most once per person every 5 minutes: WidgetKit pushes (`apns-push-type: widgets`, topic `ai.casama.app.push-type.widgets`) straight to Apple, since Firebase can't send them, through `ApnsClient` (`packages/agent/src/apns.ts`, now shared with VoIP rings, with an unreachable-Apple crash fixed); data-only `{kind:"glance"}` Firebase messages for Android; Casama Cloud's relay (`widget` body) for linked servers. Needs `APNS_KEY_P8`, `APNS_KEY_ID`, `APNS_TEAM_ID` in production; without them Apple devices refresh on their own schedule.
- **iPhone** (`client/ios/CasamaWidgets/`, extension raised to iOS 18): Needs you, Bot (kind `BotStatusWidget`, so placed widgets carry over; pick a bot), Ask (pick a bot; starters), Routines (automatic or chosen; **Run now**), Today (large, extra large, extra large portrait on iOS 27), Brief, Library (covers fetched with the key), Tasks, Credits; Lock Screen circular, rectangular and inline, with no buttons and the person's words `privacySensitive`; controls **Ask Casama**, **Talk to a bot**, **Run a routine** (asks to unlock). Buttons are `LiveActivityIntent`s (`RunActionIntents.swift`) so they run inside the app and hand `run_routine`, `accept`, `allow`, `deny`, `stop` to Dart through `casama/island`, falling back to a link. **Allow** and **Deny** appear only for low-risk requests. The widget extension registers its own WidgetKit push token (iOS 26+). The key sits in the keychain group `ai.casama.app.widgets`.
- **Android** (RemoteViews, responsive sizes, the phone's colours on 12+): the same nine, Ask as a 4×1 bar; a native picker for Bot, Ask and Routines; `LiveRunActionActivity` takes `run_routine` and `accept`; `GlanceRefresh` (WorkManager, every 30 minutes while a widget and a key exist, and on a `glance` push); Needs you, Bot, Routines and Credits allowed on the lock screen (`keyguard`, drawn private there); the **Ask Casama** Quick Settings tile; a bot pinned as its own icon; previews with the person's own bot on Android 15+.
- **Mac:** a new `CasamaWidgetsMac` extension target (sandboxed, macOS 14) sharing the iPhone's views, view only (the notch acts); the app writes the glance through `casama/mac` → `glance` into the app group `V8V5US964Z.ai.casama.app`; both packaging scripts sign the extension first (`WIDGET_PROVISIONING_PROFILE`).
- **The app:** Settings → Widgets (each widget, **Add to Home screen** on Android, how to add on Apple devices, **Show details in widgets**, pin a bot), a one-time hint after the first approval answered or routine made, analytics `widgets_placed`, `widget_action`, and `feature_used` values `widget_opened` and `widget_action`.
- **Not verified, because nothing was built:** every widget's look, Xcode embedding and signing the Mac target, Gradle resource linking, widget pushes on real devices, keychain sharing, Lock Screen privacy, the tile. Swift was type-checked for all four Apple targets against the iOS 27.2 and macOS 27.2 SDKs, Kotlin with the Kotlin 2.4 compiler against android-37, XML with `xmllint`. The migration wasn't applied to the shared local database. Left for Oliver: builds, the Apple push key in production, Mac widget provisioning profiles, a deploy.

## D-406 The public history starts again, under AGPL-3.0

- **Decision (2026-11-19, Oliver: "no one has seen this source yet… let's go reset the history now"):** the public repository `stackwares/casama` starts again from one commit holding the code as of `ee52bb31`, under D-403's licenses. The full development history (801 commits, 2026-11-09 to 2026-11-19) is kept privately: the old repository was renamed `stackwares/casama-archive` and made private (with its Actions runs and CLI releases), and a git bundle of every ref is kept offline.
- **Why:** the last Apache-2.0 commit was, in effect, the whole product. As long as it was public, anyone could take it and build a closed product on it, the way OpenSearch and OpenTofu were forked from the last permissive Elasticsearch and Terraform. Before the reset nobody outside had looked: 0 stars, 0 forks, at most one unique visitor a day (Oliver), clones only from CI runners and the server, not archived by Software Heritage, and Oliver is the only author besides dependabot.
- **What it doesn't do:** anyone who already had a copy keeps it under Apache-2.0. Nothing says the code was never Apache; the docs simply stop pointing at earlier versions. The SDKs, CLI, MCP server and plugin kit are Apache-2.0 anyway.
- **Changed:** LICENSING.md, NOTICE, the README, SPEC.md, the docs' contributing page and FAQ, casama.ai's open-source page and terms (now effective 19 November 2026) no longer mention earlier Apache versions. `docs/TRADEMARK-EVIDENCE.md` points at the archive for first-use dates. The CLI releases were recreated in the new repository; the `selfhost` tag sits on the new root until the images are republished. A `pre-push` hook in the shared `.git/hooks` refuses to push any commit from the old history, so an old branch can't bring it back.
- **Production, done 2026-11-19 with Oliver's yes:** the server's checkout was reset to the new history (no restart; `deploy-prod.sh` refuses a non-fast-forward), casama.ai and the docs were deployed, and the eight GHCR packages were deleted whole (about 420 versions labelled Apache-2.0) and republished from the new root, linked to the new repository. Local branches that were on the old history were moved onto the new root as one commit each.
- **GitHub gotchas:** the organisation runs Actions only on selected repositories, so the new repository had to be added (and the archive removed, so its nightly evals don't spend private minutes); GHCR packages accept pushes from Actions only from the repository they're linked to.

## D-407 A CLA check on pull requests

- **Decision (2026-11-19, Oliver: "go with #8"):** `.github/workflows/cla.yml` runs CLA Assistant Lite (`contributor-assistant/github-action` v2.6.1, pinned by commit) on every pull request. It comments asking the author to sign [CLA.md](../CLA.md) with the exact sentence from its section 6 ("I have read the Casama CLA (CLA.md) and I agree to it."), records each signature (GitHub login, id, pull request, time) in `signatures/cla.json` on the `cla-signatures` branch, and sets a status that stays red until everyone on the pull request has signed. "recheck" runs it again.
- **Why this one:** free, no outside service to trust with the signatures (they live in the repository, with git history as the record), and the signing sentence D-403's CLA already asks for.
- **Who doesn't sign:** Stackwares' own account (`oliverbytes`) and bots. Add co-founders or staff to `allowlist` only once their work is covered by an employment or assignment agreement.
- **Safe with `pull_request_target`:** the action never checks out or runs the pull request's code.
- **Not done:** making the CLA status required for merging (branch protection on `main`), once outside pull requests start coming in.

## D-408 The monthly email in the app: a switch, a sign-up box and one card, synced to Resend

- **Decision (2026-11-19, Oliver approved building the "not done" item of D-404):** people can opt in to Casama's monthly email from the app. **Settings → App → Casama's monthly email** ("What's new and what's next, once a month at most.") is a switch, off by default; password sign-up has an unticked box; a small card above the chats (and in the wide sidebar) asks once: Yes, No thanks, or close. Any answer or closing the card counts as asked on every device. Nobody is subscribed without saying yes.
- **Only on Casama Cloud:** the server offers it when `NEWSLETTER_RESEND_API_KEY` is set, and says so in `/v1/config` (`newsletter: true`); the apps show nothing otherwise. It's its own variable because `RESEND_API_KEY` already means "send invite emails through Resend" on self-hosted servers (D-174), which must not turn on Casama's list. `NEWSLETTER_SEGMENT_ID` and `NEWSLETTER_TOPIC_ID` default to D-404's segment and topic.
- **No confirmation email:** the app subscribes the person's sign-in address, which sign-in has already verified (`email_confirmed_at`; an unconfirmed address waits). Resend gets the same calls as `site/newsletter.js`'s `addContact` (create with segment and topic, then `unsubscribed: false`, segment, topics), with `signup_source` `app`. Off is `unsubscribed: true`: the contact stays, so it stays off.
- **Saved first, sent after:** `public.newsletter_subscriptions` holds the choice, when the app asked, where the last choice was made, the address Resend has (`resend_email`, never readable by the person or their workspace), and `sync_due`. `GET`/`PUT /v1/me/newsletter` save and then call Resend; a failure is logged and the worker (`startNewsletterSync`, every 15 minutes, with the API's database connection because it reads `auth.users`) tries again, up to 50 times. Resend being down never fails a save, a sign-up or a deletion.
- **Email changes and deletion:** a trigger on `auth.users` marks the row when the sign-in email changes; the sync deletes the old contact and subscribes the new address. Deleting an account turns it off and deletes the contact right away (the address the app added, or else the sign-in address, which may have come from casama.ai's form); the purge tries once more before the rows go.
- **Unsubscribing from an email turns the switch off:** `POST /hooks/newsletter/resend`, signed by Resend with svix headers (`NEWSLETTER_WEBHOOK_SECRET`, `whsec_…`), handles `contact.updated` with `unsubscribed: true`, `contact.topics.updated` with the topic `opt_out`, and `contact.deleted`. An event older than the last change in the app is ignored, so a late webhook can't undo a newer yes. Register the webhook in Resend for those three events at `https://api.casama.ai/hooks/newsletter/resend`.
- **Sign-up box timing:** the account may not exist until the address is confirmed, so the box's answer waits on the device (`casama.newsletter.signup`) and is sent once the account signs in, only if the app hasn't asked yet.
- **Not done:** the switch doesn't learn about a casama.ai form sign-up (it only turns off from Resend's side, never on); sign-up with an email code, Apple or Google gets the card instead of a box; no app build or deploy yet. Privacy policy updated (Resend listed, consent, retention).
- **Tests:** `apps/server/test/newsletter.test.ts`, `supabase/tests/newsletter_rls.test.sql`, `client/test/newsletter_test.dart`.

## D-409 The founding team on casama.ai/about and in the README

- **Decision (2026-11-19, Oliver: "apply them all now"):** casama.ai/about's "Who makes it" and the README's "Made by" name the founding team: Oliver Martinez (Founder & CEO), Anna May A. Valdez (Co-founder & Head of Product), April Dawn D. Martinez (Head of Customer Success) and Kelly Avia Martinez (Head of Social & Community).
- **Why these titles:** "founder" only for people who own a core part of the company; support and social are founding-team roles, credited by name without founder titles or founder equity.
- **Not changed:** GOVERNANCE.md maintainers, CODEOWNERS and the CLA allowlist stay `oliverbytes` until the others have GitHub accounts on the project and their work is covered by an assignment agreement (D-407). Stackwares is still unregistered; equity, vesting and IP assignment wait for the company and a lawyer.

## D-410 Casama on the wrist: Apple Watch and Wear OS

- **Decision (2026-11-19, Oliver asked for Apple Watch and Wear OS support, then "defaults"):** plan in `docs/WATCH-PLAN.md`, wire formats in `docs/WATCH-PROTOCOL.md`, mockups in `docs/media/watch-mockups.html`. All 18 §13 defaults were taken. Two native apps, no Flutter on a watch: SwiftUI (`client/ios/CasamaWatch/`, with `CasamaWatchWidgets/` for complications, the Smart Stack, controls and Siri, and `Shared/` for what both Apple targets use) and Compose for Wear OS (`client/wear/`, its own Gradle project so the phone's builds never build it). Floors are watchOS 26 and Wear OS 3 (API 30). The Apple Watch app runs without the iPhone app.
- **The watch has a key of its own.** It makes 32 random bytes, keeps them in its own keychain or Keystore, and only the fingerprint (`sha256("casama-watch-key:" + key)`) ever leaves it. The server stores that fingerprint in `watch_keys` (`supabase/migrations/20270207100001_watch_keys.sql`, with `watch_key_requests` for codes and `watch_prefs`). Signing in: the phone app registers the fingerprint (`POST /v1/watch-keys`) and tells the watch the server, workspace and the person's name; or the watch shows a code, good for ten minutes, that the person allows in Settings → Watch (Casama Cloud only; a self-hosted server signs a watch in through the phone). Remove on the phone, signing out of the phone, or **Sign out of this watch** deletes the key.
- **The server enforces the limits, for the first time.** With `Authorization: Watch <key>`: low risk allows in one tap, medium risk needs a hold (on the watch), high risk and payments never (`403 watch_allow_refused`), **Deny** always works, **Always Allow** never (`403 watch_always_allow`). A watch key may call only a short allowlist of routes (anything else is `403 watch_key_not_allowed`, so a watch never wipes its key over it), at 60 requests a minute per key, at most ten watches per person per workspace. The person's own setting (Low and medium risk, Low risk only, Never) is held per person in `watch_prefs`. Rules live in `packages/domain/src/watch.ts`; plain words and snapshots in `packages/agent/src/watch.ts`; routes in `apps/server/src/api/routes/watch.ts`.
- **Pushes.** The phone's pushes keep their `kind`; a `watch_kind` key beside it is what both watches read. Reply pushes gain `category: "REPLY"`. The iPhone's notification buttons say **Allow** and **Deny** (the id stays `approve`). Apple pushes also go straight to a watch's own token. On Wear OS the watch app registers its own Firebase token and, once it has one, turns off the phone's bridging for Casama so nothing shows twice. Strings are generated from `client/lib/l10n/app_en.arb` by `scripts/gen-watch-strings.mjs` into `WatchStrings.swift` and `watch_strings.xml`.
- **Why:** a watch is good at knowing, deciding and asking. Today a watch only mirrors notifications and **Approve** needs the phone. Going through the phone fails whenever the phone app is asleep, so the watch holds its own key; and two native apps must not each decide what a risk is, so the server holds the rules.
- **No workspace-level switch yet.** The plan's "a workspace can turn watch approvals off" needs a settings column on `organizations`, which doesn't exist. The per-person setting is all there is for now.
- **Built, not run:** the server, phone side, Swift and Kotlin were written and type-checked, and the model code (words, risk, decoding) has tests (`scripts/test-watch-swift.sh`, `scripts/test-wear-kotlin.sh`). Nothing was built in Xcode or Gradle and nothing ran on a watch or a simulator. **Not built:** a live call on the wrist, Wear Widgets, complication and tile refresh pushes from the server (they refresh on a timer and when the app runs).
- **Left for Oliver:** approve builds (an iOS build with the watch targets, a Wear bundle), the watchOS simulator runtime and a Wear OS emulator image, real watches, the Apple push key in production, App IDs and profiles for `ai.casama.app.watchkitapp` and `.widgets` with their app group and keychain group, the Wear OS form factor in Play Console, a production deploy (migration `20270207100001`), the store listings. Store uploads only when asked.
- **Audit, 2026-11-19 (Oliver: "Find issues to fix. Dig deeper"):** four reviews (server, Apple Watch, Wear OS, the phone app) found about 55 problems; the ones below changed a rule. The rest are bug fixes in the same commit. Wire changes are in `docs/WATCH-PROTOCOL.md`.
  - **A signed-out watch stays signed out.** A Wear OS watch asked the phone to sign it in again the moment it was signed out or removed, and the phone said yes without asking. Now only a watch that was never signed in asks by itself. Both watches take a `signed_in` answer only for a request they made for the key they hold; the phone holds one request per watch key, for fifteen minutes, and reading them no longer clears them.
  - **Sign Out Everywhere takes the watches too** (`DELETE /v1/watch-keys`, every workspace). A watch key isn't a session, so ending every session didn't stop a lost watch. Leaving a workspace now deletes that person's watch and widget keys there (a trigger, `supabase/migrations/20270211100001_watch_key_cleanup.sql`); before, a key came back to life when the person was invited again.
  - **Show details off covers pushes.** A watch's own copy of a push then says the bot's name and general words. The decision route no longer answers a watch with a request's arguments. The relay never carries a Wear OS push's text when private notifications are on.
  - **Spending money is the phone's.** `data.call` (a paid data call, medium risk) could be allowed with a hold; it now counts as a payment (`spendsMoney`, `packages/domain/src/watch.ts`).
  - **A bot's latest chat is the person's own.** On a bot a team shares, the watch (and the phone's widgets) could show a coworker's latest chat, and a reply from the wrist landed in it.
  - **Pushes say which workspace** (`org_id`) and whether this person's watch may allow (`can_allow`). A Wear OS watch now hears about every workspace the person is in, because it turns the phone's bridging off; it draws another workspace's request without buttons. An Apple Watch does the same for a mirrored one. Before, both said "Already answered".
  - **Open on phone leaves something to tap.** On Android the phone was told to open a screen from the background, which Android refuses; it now posts a notification. On iPhone the app says whether it is in front, and when it isn't the watch asks the server for the notification.
  - **Smaller rules:** bad keys from one address no longer lock out the working watches there; a notice goes out only for a new watch, not on every workspace switch; a code isn't used up by looking at it; Hold to allow is timed by a clock, not an animation (with animations off it was a tap); a Wear OS release build refuses a `defaultServer`; LAN http works on both watches and public http is refused with a reason.
  - **Checked by:** type-checks and unit tests for Swift and Kotlin (168 and 17), the server, agent, contracts and pgTAP suites, and the phone app's tests. A second pair of reviews read the fixes themselves and found 17 more problems in them (one serious: after a failed key delete the phone no longer told the watch to sign out); those are fixed in the same commit. **Not run on a watch:** none of it. The Gradle changes and the manifest change have not been through a Wear build.

## D-411 The iPhone Duo and other folding phones: a side strip, two panes on the fold, and a layout for each pose

- **Decision (2026-11-19, Oliver asked for "the best support for the iPhone Duo… everything", then "go and build all now" on `docs/IPHONE-DUO-PLAN.md`, taking its defaults):** Casama lays itself out for a folding phone from the window itself: its size, its safe-area insets, where its fold is and whether the fold divides it. Nothing asks "is this an iPhone Duo", so the same code serves Android foldables and, for the two panes, any window from 840 to 1099 points wide.
- **Why now:** builds made on this Mac already use the iOS 27.2 SDK, which opts an app into the Duo's whole screen. So Casama ran full screen there with nobody having designed it: an 84-point column down the outer screen that held nothing, and the tablet rail with one page at a time on the inner screen.
- **The window, described once (`client/lib/core/fold/fold.dart`):** `FoldScope` at the app's root gives every screen a `FoldInfo`: the pose (closed, tent, open wide, book, open tall, laptop), the fold's band and whether it divides the window, and the side strip. The fold comes from `MediaQuery.displayFeatures` where Flutter fills it (Android) and from our own bridge on iOS, where Flutter doesn't yet (flutter/flutter#193025). While the fold divides the window on iOS it is also written into `displayFeatures`, so Flutter's own dialogs and menus keep off it. iOS's "active" flag lags the hinge by up to a second, so the fold divides only when the hinge says partly open and the region says active.
- **The side strip (`client/lib/ui/side_strip.dart`, `shell_header.dart`):** on an iPhone Duo iOS keeps a column down one edge for the camera, the clock and the battery, and only UIKit's own navigation classes get their buttons put in it. So Casama draws it: the shell puts the three tabs at the bottom (`StripTabs`), and each page's `ShellHeader` paints its Back button and icon actions in the zone above them through an `OverlayPortal`, so they stay the page's own widgets (keys, state, navigator). The title stays with the page; an action with words on it is wrapped in `HeaderTextAction` and stays too. The strip is the side inset of 60 points or more with nothing on the other side, on iOS only: an ordinary iPhone on its side has 59 on both.
- **Two panes (`client/lib/features/home/home_shell.dart`, `client/lib/ui/shell_layout.dart`):** a fourth layout, `LayoutSize.split`, between tablet and desktop. The tab's list is on the left and what is opened from it on the right: Chats, the Library and Settings. On a folding phone they meet on the fold; elsewhere the list is 360 points beside the rail. A fold down the middle also splits a narrower window (600 and up) with the floating tab bar under the list. Each pane gets its own `MediaQuery` (`paneMedia`), so screens written for a phone lay out for the pane; what they need to know about the shell they ask `ShellLayout` (which navigation is on screen, list or detail). From the list, `pushOnce` opens beside it instead of stacking. Beside its list a page's first screen has no Back and swaps in without a slide (`AppPage`, `core/app_page.dart`); it offers a button that hides the list instead.
- **Open and close:** the router's navigator keeps its state across every layout, so the chat, its scroll position, the draft and the focus survive. The chat list keeps its element too (`chatsListKey`). Opening the device on the chat list opens the last chat beside it (D-383); closed again without a touch in that pane, the app goes back to the list without a transition (`SplitRest`, `PageMotion.snapOnce`).
- **Partly folded:** nothing tappable sits on the fold. Held like a book the band between the panes is empty, and a page that wasn't made for the fold takes the right half with the chats on the left. `FoldSplit` (`client/lib/ui/fold_split.dart`) puts what is watched before the fold and what is touched after it: the bot's computer gets its screen on one half and a trackpad, the dock and the keyboard on the other (one finger moves the pointer, two scroll, a tap clicks); a call gets the bot and captions on one half and its buttons on the other. The Tasks board lines its columns up either side of the fold and snaps to them. A short, wide window (the Duo standing like a tent, any phone on its side) gets a call layout that fits.
- **What covers the app:** `showAdaptiveSheet` asks the window, not the pane, whether it is a sheet or a dialog. Dialogs open on the trailing half of a dividing fold (`foldAnchor`); bottom sheets keep to the page and that half (`foldSideInsets`), and to the lower half of a propped-up device; toasts follow the same insets. Pages outside the shell (sign-in, the welcome steps, the paywall, the first-run steps) are wrapped in `OutsideShell`: clear of the strip, on the half you touch while the fold divides the window, Casama's mark on the other.
- **Native (`client/ios/Runner/AppDelegate.swift`):** `FoldBridge` (event channel `casama/fold`) adds an invisible view over Flutter's with a `UIHingeInteraction`, and reads the reserved regions, `verticalBarEdge`, the status bar's frame and the scene's full-screen flag in `layoutSubviews`. iOS 27.1 and later; before that and without a hinge it sends nothing. `DropBridge` (`casama/drop`) takes files, photos and text dragged from the app beside Casama in Split View and hands them to the chat on screen (`core/dropped_files.dart`).
- **Settings → Folding screen** (`features/settings/fold_screen.dart`, only on a device that folds) shows what Casama reads from the device, with a copy button. Debug builds also print it.
- **Where it differs from the plan:** (1) when the strip runs out of room its gaps close and then it scrolls; there is no "…" menu, because header actions are free-form widgets and no screen overflows today. (2) Dropped files use our own small native handler, not `super_drag_and_drop`: one less package with native code on five platforms. (3) The chat beside the list is a real navigation that is undone when the device closes untouched, not a chat shown without navigating: the first is one mechanism (the router), the second needed the same chat in two places. (4) Lying flat, pages outside the shell stay as they are (centered); they take a half only while the fold divides the window. (5) Read aloud and the file preview keep their layouts in the laptop pose.
- **Read on the iPhone Duo simulator (iOS 27.2, 2026-11-19):** a debug build was installed with `xcrun simctl` and the simulator opened, folded and rotated by scripting Xcode's Device Hub (the T3 device panel does not list the Duo simulator). Closed is 466 × 678 with 84 points on the right; open wide is 951 × 669 with the same 84 and the fold at 455.5 to 495.5; held tall it is 669 × 951 with 82 at the top; the fold's region turns active a moment after the hinge says partly open. iOS reports its own part of the strip as a covered region (174 points at the top on the outer screen, 124 on the inner one, and at the bottom of the strip in the tent pose), so `FoldInfo.stripTop` and `stripBottom` come from those regions. `statusBarFrame` is a 2-point sliver and `isFullScreen` is always false there; nothing depends on them. The plan's §11.4 has the table.
- **Signed in on the simulator, closed pose:** `client/integration_test/duo_tour_test.dart` runs the real app on a device with sample data and walks through the main screens in each pose it is put in. Its screenshots showed the strip as designed, and that iOS centers its strip items 36 points from the strip's inner edge, so ours keep 12 points off the screen's edge (`FoldInfo.stripOuterMargin`).
- **Decided 2026-11-19 (Oliver: "You decide all for me"):** two panes stay on for every window from 840 to 1099 points, after a 13-inch iPad upright and a 900-point window were rendered and looked right; the work goes to main through a pull request, because the main checkout holds other sessions' uncommitted work; no store builds and no deploys. Pull request #16 was merged the same day, after Oliver asked why it could not merge before CI: every check that runs this change had passed, and the backend job's Docker sandbox, computerd and CLI end to end steps were still running. It carries two fixes for main's own CI in their own commits (biome formatting of the watch fixtures and their strings generator; the Drizzle schema regenerated for the widget, monthly email and watch tables).
- **Not done, not checked:** nobody has seen it on a device. Signed in, only the closed pose was seen on the simulator: Device Hub stopped showing a window to script, so the two panes, the trackpad and a call across the fold are covered by tests in the windows the simulator reported, not by eyes. Split View and the keyboard across a pose change (flutter/flutter#193096) were not checked. The hinge-driven arrival of the list pane is built and off (`hingeMotionProvider`). No store screenshots for the Duo yet, no line on casama.ai. The plan's §11 has the list.
- **Tests:** `client/test/fold_test.dart`, `duo_shell_test.dart`, `duo_modal_test.dart`, `duo_live_test.dart`, `duo_call_test.dart`, `duo_outside_test.dart`, and `duo_layout_test.dart` (every route in every pose). `client/test/support/poses.dart` puts a test in a pose; `DUO_SHOTS=<folder> flutter test test/duo_look_test.dart` writes pictures of every pose.

## D-412 GitHub Sponsors for the stackwares organization

- **Decision (2026-11-19, Oliver: "setup now… get it live"):** Casama takes sponsorships through GitHub Sponsors on the `stackwares` organization (github.com/sponsors/stackwares), the account that owns the repository. The profile and tiers were made through the GraphQL API (`createSponsorsListing`, `createSponsorsTier`): $5, $25, $100 and $500 a month, and $10 and $50 one time. Payouts go to Oliver's bank in the Philippines through Stripe Connect, because Stackwares is not registered yet; move them to the company's account once it exists.
- **Why:** self-hosting is free under AGPL-3.0, and until now people running it themselves had no way to pay for it. Sponsorship is aimed at them and doesn't compete with the Cloud plans, which stay the business. Expect it to be small.
- **Where it shows:** `.github/FUNDING.yml` (the repository's Sponsor button, with casama.ai/pricing beside it), a badge and a "Sponsors" section in the README (names at $25+ between the `<!-- sponsors -->` markers), a "Sponsor Casama" section and question on casama.ai/open-source, a line on /self-hosted, and a Sponsor link in the casama.ai and docs footers.
- **Promised perks to keep:** names at $25+ in the README; team name and link at $100+ in the README and on /open-source; logo and a monthly maintainer call at $500+. Update the README list when someone sponsors.
- **Not a cost:** GitHub takes no fee on sponsorships from personal accounts (sponsorships paid by organizations carry a small processing fee), so nothing goes in `docs/COSTS.md`. Sponsorship money is income, not usage, and isn't recorded in `usage_ledger`.

## D-413 One chat, many things at once: nothing lost, hidden, attached to the wrong chat or left waiting

- **Decision (2026-11-19, Oliver: "sometimes bots take too long or stuck, sometimes bots reply to another thread instead of theirs… what if multiple logged in devices in a single account send messages in parallel… handle all of those smoothly"):** a review of everything that can happen in one chat at the same moment, checked against production (read only), and the fixes below.
- **What production showed** (the last 14 days, 211 chat runs):
  - 16 bot messages in 6 chats sat off the branch the app shows. The latest was a 1,725 character reply on 2026-11-19 01:11 UTC: it streamed, then was gone on the next load.
  - Two routines that fire at midnight in the same chat hid one result every night.
  - `shell.exec` failed nine times in a row on 2026-11-18 with "supervisor unreachable: fetch failed" after 303 seconds each; that run then ended at its 30 minute limit.
  - No run waited in the queue for more than 2 seconds, so the queue problem below had not happened yet.
- **Messages and replies stay on the shown branch.**
  - A conversation is a tree and the app shows the branch ending at its head. A new message read the head without a lock, so two inserts at the same moment (a second device, a routine, two bots in a group) took the same parent and the second fell off the shown branch with every reply under it. Reading the head now locks the conversation's row (`messages_branch`, "for no key update": a plain "for update" deadlocks with the foreign-key locks of runs inserted alongside).
  - A run's reply was saved under the message it answers. If the person sent another message while the reply was being written, the reply became a side branch nobody saw. It now goes at the end of the shown branch when its question is on that branch (`replyParent`), and stays with its question when the person switched to another branch (an edit).
  - The run started for that later message never saw the earlier reply and did the first request again. `loadRun` now adds what the bot said after the run's own message. A request another run of the chat is still handling (a routine, a run waiting for a yes) is marked "already working on this in another run".
- **No message is left without an answer.**
  - A message sent while the bot works joins its run. The run looked for messages it never saw before its memory step, and was still "running" during that step (a model call of several seconds): a message sent then joined a run that had stopped looking. A run now ends first and looks again (inside the existing `complete` step, so runs in flight during an update replay cleanly), and the send and the hand-over take one lock per chat (`lockChat`).
  - The join no longer picks a routine's run (a brief has a cheaper model and fewer tools) or a call's tool run (it never looks for new messages).
- **Two devices sending at the same moment** both found no run working and each started one. The send is now one transaction under the chat's lock: the first starts the run, the others join it. A group send uses its idempotency key as the message id, as a direct send does, so a retry no longer posts twice.
- **Runs waiting for a person don't hold up everyone else.** The run queue counted a run from start to end. A run waiting for an approval, a secret or the screen (up to 24 hours) kept its place, so five of them in a workspace left every new message there "queued", and twenty froze the server. `RunSlots` now keeps how many runs work at once (same numbers: `RUN_CONCURRENCY`, `RUN_WORKSPACE_CONCURRENCY`); a run gives its slot back while it waits and takes one again after. The queue admits ten started runs for each one that may work. A run another run asked for works inside that run's slot. The slots live in the worker's memory, so with several workers the limits are per worker.
- **Computers: no five minute cliff.**
  - Node's fetch gives up after 300 seconds without headers or without body data. A checkpoint, sleep or restore of a large home folder answers only when done and failed as "supervisor unreachable"; a command that printed nothing for five minutes lost its stream and came back as "exit code -1". These calls now use their own agents (`long-fetch.ts`): a command's stream has no silence limit (the computer stops the command at its own timeout), and slow calls may take an hour.
  - The checkpoint before a command that deletes archives the whole home folder: 36 to 80 seconds for a 70 MB archive, over four minutes for 740 MB, before every `rm -rf`. Automatic ones are now at least 10 minutes apart, and at least 20 times what the last one took. Checkpoints asked for by name are always taken.
  - A command whose exit never arrives stops being waited for a minute after its own timeout. A stream that ends without an exit says so instead of "exit code -1".
- **The app.**
  - A send that came back after another chat was opened attached its run to the chat on screen: the other chat showed that run's steps, its reply and a Stop button that stopped it. A slower open of one topic could also land on top of the topic opened after it. Each open now has a number and the newest wins; what a send does afterwards goes to the chat it was sent in.
  - A message sent while its chat was still loading started a new conversation. It now waits for the chat.
  - A message from the person's other device joined the working run, so nothing told the first device. Messages are announced on the conversation's topic (`conversation_message`), and the chat puts in what it doesn't show without reloading (a reload drops the steps on screen); it also checks when a run ends.
  - A run whose stream closes without an ending no longer leaves "Thinking" on screen; the thread is read again.
  - Going from one bot to another kept reporting the first bot's chat as "on screen", so its replies stopped notifying on every device. A reply in another topic of the bot on screen was marked read without ever being shown. Both now go by the conversation.
  - A reply or an approval in a group chat opened the bot's own chat on the group's thread. The link is `/groups/{id}` and old links open the group.
  - Topic chips kept "working" after the topic finished; tapping the topic the address already names (after New topic) did nothing.
- **The four things first left for Oliver** (he answered "go and decide everything for yourself"):
  - **Chat apps answer where they were asked.** A Telegram group with topics is one conversation per topic, and the answer, the typing and an approval go to that topic (they all went to General). Each run keeps the reply target of the message that started it (`channel_run_replies`), so a second Discord command no longer takes the first one's answer. iMessage reads one-to-one messages only: a message in a group chat was answered to its sender one-to-one. That one is in the Mac app (`computerd`) and needs a desktop build.
  - **A watcher that fires tells the person.** Its chat is now a topic under General that posts its result there (the rule routines follow, D-253), with a notification, and back to the chat app it was asked from. A change that isn't what it watched for answers `NO_MATCH`: nothing is posted or pushed. Not built: answering in the chat it was asked in. A page that changes every hour would write there every hour, and its instructions would show as something the person said.
  - **One run at a time drives a computer's browser and desktop** (`computer_screen_leases`). Another run waits up to 90 seconds and is then told who has them. A run asked by the run that holds them shares them. Not built: a browser per run. They would share no sign-ins, and the live view shows one screen.
  - **A group chat follows the run that waits for the person.** When a bot asks for an approval while another bot's run is on screen, the chat moves to the asking run, so its card shows; on reload a waiting run is picked before a working one.
- **Tests:** `packages/agent/test/chat-threads.test.ts`, `checkpoint-spacing.test.ts`; `apps/server/test/chat-concurrency.test.ts`, `run-slots.test.ts` (five runs waiting, a sixth answered; fails with the old queue limits); `supabase/tests/conversation_messages.test.sql`; `client/test/chat_switch_test.dart`, `chat_topics_notify_test.dart`; `packages/agent/test/channels-reply-targets.test.ts`, `screen-lease.test.ts`; `apps/server/test/watchers.test.ts`; `dart/computerd/test/companion_test.dart`.

## D-414 No background location on Android; voice calls drop the camera service type (2026-11-19)

- **Why:** Google Play asks for a declaration with a YouTube walkthrough for background location and for each foreground service type, and background location also needs an in-app disclosure before the system prompt, which Casama doesn't have. Oliver chose to drop background use on Android rather than film it.
- **Android Places** asks for "While using" only. It still tells bots which named place you're at when the app is open (`currentLocation`), but arrive and leave with the app closed (geofences) are iOS only: `supportsPlaceEvents`, and `watchPlaces`/`stopPlaces` do nothing on Android. `location_always` is an iOS permission now (`os-permissions.ts`, `os_permissions.dart`), so Places on Android needs `location`.
- **Manifest:** `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE_LOCATION` and `FOREGROUND_SERVICE_CAMERA` are removed (`tools:node="remove"`, so plugins can't merge them back), as are the geofence and geolocator location services. `flutter_callkit_incoming`'s notification service is `phoneCall|microphone`: calls are voice only (`type: 0`), and it adds camera only for video calls.
- **Still declared on Play:** phone call (incoming bot calls, `flutter_callkit_incoming`) and microphone (`CallService`, live calls in the background). Both need a short video each.
- Docs: guide/devices.md, guide/routines.md. Tests: `packages/domain/test/os-permissions.test.ts`; `client/test/device_connections_test.dart` fake.

## D-418 Credits bought in the App Store or Google Play never expire (2026-11-19)

- **Why:** App Store guideline 3.1.1 says credits bought with in-app purchase may not expire. Since D-246 every credit pack lasted 12 months (`public.credit_lot_expiry`), store packs included.
- **Decision:** a credit pack bought through RevenueCat (D-297: the App Store, the Mac App Store and Google Play alike, ledger reason `purchase`, reference `revenuecat:<RevenueCat purchase id>`) gets a lot with no expiry. Packs bought on the web or in the desktop app (Dodo, reference `dodo:<payment id>`), rewards and opening balances keep 12 months; a month's included credits still last until the end of the following month. Google Play has no such rule, but RevenueCat gives both stores the same reference, and one rule for both is simpler to explain.
- **Spending:** credits that lapse first are still spent first, so store packs, which never lapse, are used last.
- **Migration** `20270212100001_store_credits_never_expire.sql` redefines `credit_lot_expiry` and clears `expires_at` on lots from store packs already bought. None had lapsed yet: store packs have been on sale since 2026-11-15.
- **Where it shows:** the terms (credits section), the FAQ (docs and casama.ai/pricing), docs guide/usage.md "Credits", and the app's `creditsExplainerShort` and `outOfCreditsPaidBody`.
- Tests: `supabase/tests/store_credits_never_expire.test.sql`; `apps/server/test/billing-holes.test.ts`; `client/test/credits_meter_test.dart`.

## D-419 Casama checks image and video requests itself (2026-11-19)

- **Why:** App Store guidelines 1.1.4 and 1.2 expect an app that generates images to stop objectionable content itself. Casama relied on the provider's filters, and a workspace's own key or a future provider may have weaker ones.
- **Decision:** `media.image.generate` and `media.video.generate` run `checkMediaRequest` (`packages/agent/src/media-safety.ts`) before credits are checked or the provider is called, on every key. It refuses three things: sexual content involving minors, sexual or nude pictures of real people (a named person, or the person in a photo being animated), and graphic violence or gore. A refusal is a `content_refused` tool error whose message tells the bot to say plainly and politely why, and not to rephrase and retry.
- **Classifier:** one call on the bot's background model through `backgroundComplete` (D-338), so the same model checks whatever key or local model the bot runs on, and on Casama Cloud it is the small model already on the guardrail allowlist (D-364). Its cost goes in the usage ledger as `tokens_in`/`tokens_out` with `meta.purpose = "media_safety"` (docs/COSTS.md). The prompt is wrapped as data, and a photo being animated is flagged so whoever is in it counts as a real person.
- **Failing:** minors fail closed. A prompt with both a word for a child and a sexual word is refused before any model call; while the check is down (no model, an error, an answer that isn't one of the categories), a prompt that mentions a child is refused with "try again in a minute". The other two fail open while the check is down, logged as "media safety check unavailable", so a provider outage doesn't stop all pictures; the provider's own filters still apply.
- **Not covered:** `media.image.edit` only crops, resizes and converts (no model), and the app's photo editor runs on the device; neither makes new content.
- Docs: guide/chat.md. Tests: `packages/agent/test/media-safety.test.ts`.

## D-420 Deleting an account revokes its Sign in with Apple tokens (2026-11-19)

- **Why:** App Store guideline 5.1.1(v): an app that offers Sign in with Apple must revoke the person's Apple tokens through Apple's REST API (`POST https://appleid.apple.com/auth/revoke`) when they delete their account. Casama deleted accounts (D-072) without telling Apple. Supabase Auth signs people in with Apple's ID token (the iOS and macOS sheet, D-167) or its own OAuth flow (the browser), and keeps no Apple token the server can use.
- **Decision:** the app hands the server what Apple gave it, right after an Apple sign-in, through `POST /v1/me/apple-sign-in`:
  - **The system sheet** (iOS, macOS): `credential.authorizationCode`. The server swaps it at `https://appleid.apple.com/auth/token` (client id: the app, `ai.casama.app`) for a refresh token.
  - **The browser** (Android, web, Windows, Linux, a Mac without the sheet): Supabase Auth's `provider_refresh_token` from the PKCE exchange (client id: the Services ID, `ai.casama.app.signin`). The server checks it with Apple (`grant_type=refresh_token`). The app sends it only when it started an Apple sign-in within 15 minutes (a flag in SharedPreferences, so it survives the web page's reload), never another provider's token.
  - Either way the server keeps the refresh token only when the `sub` in Apple's id_token is the person's own Apple identity (`auth.identities`, provider `apple`). The token lives in Vault; `public.apple_sign_in_tokens` (person, client id, Apple `sub`, Vault id) has RLS with no policies for people (only the API and the worker read it). Triggers delete the Vault secret when a row is replaced or deleted, or cascades away with the user.
- **On deletion:** `DELETE /v1/me` revokes every kept token (`token_type_hint=refresh_token`, with a client secret for the client id the token belongs to), which also takes Casama off the person's "Sign in with Apple" list. A failed revoke never fails the deletion: it is logged and sent to Sentry, the row stays, and the purge after the grace period tries again and then drops the row either way. Apple's `invalid_grant` (already revoked or expired) counts as done.
- **Client secret:** the server signs its own short-lived ES256 JWT (five minutes, `kid` = key id, `iss` = team, `sub` = client id, `aud` = `https://appleid.apple.com`) with the Sign in with Apple key, so it never expires the way Supabase Auth's six-month `SUPABASE_AUTH_EXTERNAL_APPLE_SECRET` does.
- **Settings** (API and worker; `infra/compose/docker-compose.yml`, `.env.example`, docs-site self-hosting configuration): `APPLE_SIGNIN_KEY_P8` (the `.p8`, inline with `\n` or a path), `APPLE_SIGNIN_KEY_ID`, `APPLE_SIGNIN_TEAM_ID`, and `APPLE_SIGNIN_APP_ID` / `APPLE_SIGNIN_SERVICES_ID` (defaults `ai.casama.app` / `ai.casama.app.signin`). Casama Cloud uses the existing Sign in with Apple key `928HPX454R`, team `V8V5US964Z` (Vaultwarden: "Casama Sign in with Apple AuthKey 928HPX454R"). Unset: the route answers `stored: false` and deletion does what it did before.
- **Limits:** people who signed in with Apple before this app build have no kept token until they sign in with Apple again, so their deletion can't revoke anything. The browser path depends on Supabase Auth returning `provider_refresh_token` for Apple.
- **Migration** `20270213100001_apple_sign_in_tokens.sql`. Tests: `apps/server/test/apple-signin.test.ts`, `supabase/tests/apple_sign_in_tokens.test.sql`, `client/test/apple_token_handoff_test.dart`.

## D-421 People agree before their chats go to outside AI providers (2026-11-19)

- **Why:** App Store guideline 5.1.2(i): an app must say which third-party AI receives personal data and get permission before sending it. Casama sent the first message to OpenRouter (and the model makers behind it) with no such step; the privacy policy was the only place that named them.
- **Decision:** a full-screen step, "Your chats go to AI companies" (`client/lib/features/privacy/ai_consent_step.dart`), covers the app after sign-in and before every other first-run step, the welcome chat and the guided setup. It says what is sent (messages, files, photos, call audio, memories, phone data that was turned on) and to whom (OpenRouter and the model makers behind it, Google Gemini for calls, the web search providers, or the person's own provider for their own key). "Agree and Continue" or "Sign Out"; nothing reaches a model before agreeing, because the welcome chat waits for it (`nameStepNeededProvider` stays null until then).
- **Where:** only the App Store apps, where Apple requires it: iOS and the sandboxed Mac App Store build (`aiConsentAskedHereProvider`, `CASAMA_DISTRIBUTION=appstore`). Web, Android, the Mac direct download, Windows and Linux never show it, nor the Privacy row.
- **Stored** in the account's Supabase user metadata (`ai_consent_at`), so it follows the person to every device; existing accounts see the step once. Settings > Privacy > AI providers withdraws it ("Stop Sharing"), which brings the step back before anything else is sent.
- **Not done:** the server doesn't refuse runs for people who haven't agreed; chat apps and routines are set up from the app, after the step.
- Tests: `client/test/ai_consent_test.dart`.

## D-422 App Store preflight fixes for the iOS and Mac 1.0 submission (2026-11-19)

- **Why:** a preflight against Apple's review guidelines (the app-store-preflight skill) before the first App Store review found these alongside D-418..D-421.
- **Mac App Store build without Sparkle (2.4.5(vii)):** `scripts/package-macos-appstore.sh` swaps `auto_updater` for `client/tool/appstore/auto_updater_stub` (same Dart API, no native plugin) through a temporary `pubspec_overrides.yaml`, so neither Sparkle nor its plugin is linked; it drops the `SU*` Info.plist keys and fails if Sparkle got in anyway. The lock files are put back afterwards. The direct download keeps Sparkle (D-159).
- **Mac App Store entitlements (2.4.5(i)):** dropped `network.server` and `files.downloads.read-write`, which only features turned off in that build used; the script adds `aps-environment` from the provisioning profile, so pushes (D-312, D-325) work there.
- **Privacy manifests (5.1.1):** the watch app and watch complications have their own (UserDefaults `CA92.1`, `1C8F.1`); the iPhone and Mac apps add `1C8F.1` (app-group defaults shared with widgets) and declare the phone number calls keep.
- **No advertising or vendor ids for GA4:** `GOOGLE_ANALYTICS_ADID_COLLECTION_ENABLED` and `GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED` are false on iOS and macOS.
- **Purchase terms (3.1.2):** the Terms of Use link on Apple devices is casama.ai/terms (which carries Apple's minimum EULA terms), the same page the App Store description links; "Apple ID" became "Apple Account".
- **Sign in with Apple (4.8):** when Apple gives the name, the name step is marked answered, so the app doesn't ask for it again.
- **Review notes** (`client/store/app_store/review_notes.txt`) cover every feature's path, external services, the AI providers step, regional differences (US-only web checkout and domain buying), remote kill switches and the demo account's plan.

## D-423 The bot can hang up an in-app call itself (2026-11-19)

- **What:** in-app voice calls get the `end_call` tool that phone calls already have (D-141). The
  call's instructions say: when the user says goodbye or wants to end the call, say a short
  goodbye, then use `end_call`.
- **The app answers it,** as it does `show_screen` (D-327): it tells the model it's hanging up, waits
  1.2 s for a goodbye still on its way, then waits for the bot to stop speaking (at most 10 s) and
  ends the call with the reason `CallEnd.bot`. The call is saved and recapped like any other.
- **Older apps** send `end_call` to `/v1/voice/tool` like any tool. The server answers without a run:
  it can't hang up, so the bot tells the user to tap the red button.
- **Why:** a call stayed open after "okay, bye" until the person tapped End Call or two quiet
  minutes passed, billing turns nobody needed.

## D-427 Casama Cloud takes new accounts by invitation: a waitlist, invite codes and one gate in Auth's hook (2026-11-19)

`docs/WAITLIST-PLAN.md`, approved by Oliver on 2026-11-19 ("Yes to all!" to its 18 decisions). This amends D-211's "nothing is gated" for the launch period only.

- **Why:** a launch people want to get into, and a production server that runs about 9 computers at once. The gate has to be on before the Hacker News post (planned 8 Dec 2026) and opens for everyone at the public launch (planned 12 Jan 2027).
- **Where it sits:** one rule in Supabase Auth's before-user-created hook (`routes/abuse.ts`), which every way of making an account already passes: email link, password, Apple, Google, the CLI. Existing accounts never reach it. Auth asks the hook before it sends a sign-in link, so a refused person costs no email.
- **The rule, while the gate is on:** a new account is made only for an address that was let in (`waitlist_entries` status `admitted` or `joined`, matched on D-333's normalised-email hash), or that has a standing workspace invite where the workspace has a seat for it (`signup_invited_with_seat`: invites aren't checked against seats when they are made, so without this any Free workspace could mint accounts). A self-hosted server's own allowlist (D-145) keeps deciding alone where it is set.
- **Everything that lets someone in marks an address:** a batch from the list, an invite code claimed together with an email address (`POST /v1/waitlist/redeem`), or an address added by hand. Codes are claimed before sign-up because Apple and Google sign-ins carry nothing of ours to the hook.
- **Cloud only, and off by default:** the feature exists where `SIGNUP_WAITLIST` says (auto: with billing). Whether the gate is on is the `signup_gate` row in `instance_settings` (no row: open), changed at `PUT /v1/admin/signup-gate` or with `scripts/waitlist.sh on|open`, read by the hook through a 15-second cache. `opens_at` opens it by itself at a set time. A setting that can't be read makes the hook answer 503 (Auth tries again, then refuses): it never falls open.
- **What people see:** "Casama Cloud is invite-only for now. Join the waitlist or enter an invite code at casama.ai/waitlist." A hidden Apple relay address is told to share its email or use the email link. `/v1/config` adds `signups_by_invitation: true` (builds 44 and web 45 already show a line for it) and `signup_gate` for new builds.
- **The waitlist:** our own table, not Resend. Joining needs a solved sign-up puzzle (D-094) and sends no email; the one email is "You're in", sent by the worker a few a minute and never more than `daily_emails_max` a day (25 while ZeptoMail is capped at 100). A person is let in when their email goes out. A yes to the monthly email is stored with its wording and applied when the person first signs in (D-408's path, no confirmation email).
- **Invite codes:** a member's D-211 referral code is their invite code, with `invites_per_person` invites (3) once they have finished a first chat, plus `referral_codes.invite_bonus`. The friend's referral is attached at sign-up by the worker, so D-211's credits follow with no second tap. Campaign codes (`invite_campaigns`: a total, an optional number per day, a start, an end) are 9 or more characters or carry a hyphen, so they can't look like a 6-character member code or an 8-character workspace code. A used-up code puts the person on the list with priority. The count and the admission share one transaction with the campaign row or the inviter locked.
- **Not done on purpose:** no position number, no "share to move up" (joins aren't verified, and Apple doesn't allow it in an app), no confirmation email on joining.
- **Found on the way, and fixed for everyone:** Auth (v2.197.0, checked against a throwaway copy) passes a hook's refusal on to the app only when the hook answers HTTP 200 with `{error: {http_code, message}}`. The hook answered 403, which reached people as "Unexpected status code returned from hook: 403", so the reasons written for D-094, D-145 and D-296 were never shown. All refusals now answer 200 with the status in the body. Also checked there: a refused email-link request sends no email; accounts made through Auth's admin `POST /admin/users` skip the hook, while `/invite` and `generate_link` for a new address go through it; anonymous sign-ins are off.
- **Costs:** no new paid service. `docs/COSTS.md` has the "You're in" emails and the worst case for invite credits under the gate.
- **Privacy:** the privacy page has a waitlist section. An entry is in the account's data export (`account.json`, `waitlist`). When an account is deleted its entry keeps only the inbox's hash and how it got in, so the same inbox can come back; the address, the line the person wrote and the network hash go (`waitlist_forget_account`). The network hash is cleared after 30 days anyway.
- **Tests:** `apps/server/test/waitlist.test.ts` (45), `supabase/tests/waitlist_rls.test.sql` (37), `scripts/site-waitlist.test.mjs` (18); the older hook tests read a refusal through `hookVerdict`.
- **Live 2026-11-19 (Oliver: "deploy all you need"):** Phase 1 and the site placements; the gate is on in production.
- **Phases 2 and 3 (built 2026-11-19):** a code rides in the sign-up's metadata (`invite_code`) and the hook claims it after checking the sign-up proof; an Apple or Google ID token can be redeemed with a code (`services/id-token.ts` makes Auth's own checks), which is how Hide My Email gets in; each "You're in" email carries a one-time code for one more address, stored as a hash; the daily batch runs once a day at `batch_hour_utc` and skips with a push to the owners when yesterday's computers passed 7/9 or model spend passed 60% of `OPENROUTER_DAILY_CAP_USD`; four analytics events and `admitted_via`; the app's native Join the Waitlist, I Have an Invite, refusal sheet, invites left and Admin → Waitlist. Details in the plan's "Status of the build".

## D-430 Casama gets its own PostHog Cloud project (2026-11-19)

Casama used the shared Stackwares PostHog project 637030, which was already past its free tier, so every Casama event was paid for out of a project shared with the other Stackwares apps. Casama now has its own PostHog Cloud account (US region, `hello@casama.ai`, email and password) with project 750357, which starts on the free 1M events a month. The project key, a `person:write` key for erasing purged accounts and an `error_tracking:write` + `organization:read` key for crash symbols are Vaultwarden items marked "Casama 750357"; the three old items are marked superseded and stay until the old keys are revoked. Switched the same day: the server's `POSTHOG_API_KEY`, `POSTHOG_PERSONAL_API_KEY` and `POSTHOG_PROJECT_ID` on the VPS (a redeploy of the live commit, API and worker only), the `CASAMA_TELEMETRY_JSON` repo secret for CI desktop builds, and the local `.env`, `client/config/telemetry.json` and `posthog-cli.env`. App builds already in the stores keep sending to 637030 until their users update. History and the dashboards stay in 637030; the new project starts empty.
