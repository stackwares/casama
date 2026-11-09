# Needs from Oliver

Everything below is built and tested against mocks, fixtures or local stand-ins. Each item says what is needed to use the real thing and where it plugs in. Newest items are added at the end of each section.

## Keys and accounts

| Item                                                                        | Needed for                                                     | Where it plugs in                                                         | Status                                                                                                                                                                                                                              |
| --------------------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A model key (OpenRouter is simplest; any of OpenAI, Anthropic, Google, xAI) | Real bot replies instead of recorded fixtures                  | `kasama credential add`, or `POST /v1/credentials`                        | **Provided (OpenRouter, 2026-11-09)** in `~/.config/kasama/openrouter.env`. Live checks pass: key test, a live tool call on a Docker computer, a live chat in the app (`scripts/live-check.sh`). Other providers still fixture-only |
| An OpenAI key (optional)                                                    | Vector embeddings for memory (otherwise full-text search only) | Same as above, provider `openai`                                          | Hybrid search tested with an offline hash embedder                                                                                                                                                                                  |
| Resend API key and a sending domain                                         | Invite emails (bot email channel is post-v1)                   | `RESEND_API_KEY`, `EMAIL_FROM`                                            | Invites fall back to returning the token                                                                                                                                                                                            |
| Composio API key (free tier)                                                | Composio integration tools (Phase 4)                           | Integration credentials in Vault; built against a mock until a key is set |
| Pipedream Connect project (client id and secret, free tier)                 | Pipedream Connect integration tools (Phase 4)                  | Same as above                                                             |
| fal.ai API key                                                              | `media.image.generate` / `media.video.generate` (Phase 4)      | `MediaProvider` fal.ai adapter; tested against a mock                     |

| Firebase project: service account JSON and app options | Push notifications (approvals, routine results) | Worker `FCM_SERVICE_ACCOUNT_JSON`; app `--dart-define=FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, FIREBASE_PROJECT_ID` (web also `FIREBASE_VAPID_KEY`) | Sender tested with a recording stub; app registration builds on 4 platforms, not run with a real project. iOS also needs an APNs key uploaded to Firebase |
| Brave Search or Tavily API key (free tiers) | `web.search` tool | Credential with provider `brave_search` or `tavily` | Tested against mocks |
| Verification of the Composio and Pipedream REST shapes with real keys | Confidence that the adapters match the live APIs (D-052) | `packages/agent/src/integrations.ts` | Written from public docs; mock-tested only |

| E2B API key, and a template built from `infra/images/computer` (computerd start command) | Hosted computers on E2B (Phase 5) | Supervisor `E2B_API_KEY`, `E2B_TEMPLATE_HEADLESS`, `E2B_TEMPLATE_DESKTOP` | Adapter tested against a local mock of the E2B API (D-057) |
| Daytona API key, and snapshots built from the computer images | Hosted computers on Daytona (Phase 5) | Supervisor `DAYTONA_API_KEY`, `DAYTONA_SNAPSHOT_*` | Adapter tested against a local mock of the Daytona API |

| OpenAI key with Realtime access | Live voice calls; measuring the gate's "reply within 1 s" (Phase 6) | Workspace credential, provider `openai` | Session, tool forwarding and transcripts tested against a mock |
| Deepgram, ElevenLabs, Cartesia or Fish Audio keys (optional) | Dictation and read-aloud with those providers | Workspace credentials | Tested against mocks |

## Infrastructure

| Item                                                      | Needed for                                                                       | Status                                                                                              |
| --------------------------------------------------------- | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| A Linux host with gVisor (`runsc`)                        | Verifying the spec's sandbox runtime. Docker Desktop on macOS only has `runc`    | Supervisor takes `SANDBOX_RUNTIME=runsc`; all sandbox tests ran on `runc` here                      |
| Docker Desktop running on this Mac                        | Phase 2+ tests (computers)                                                       | Installed 2026-11-09                                                                                |
| Supabase (local via `supabase start`, which needs Docker) | Testing against real Supabase Auth, Realtime and Vault instead of the local shim | Migrations and all pgTAP tests verified on the real Supabase Postgres image; app tests use the shim |

| A Linux sandbox host with XFS project quotas | Enforcing the 10 GB per-computer disk limit (D-032) | Free disk is reported; no hard cap on Docker Desktop |
| Cloudflare R2 bucket and API token (hosted installs, D-062) | Snapshots and checkpoints off the sandbox host with no egress fees | `OBJECT_STORE=s3` + `S3_*` variables; S3 store tested against SeaweedFS locally |

| A public TURN relay: a host with UDP 3478 and the relay port range open, plus a TLS certificate for `turns:` on 5349 | Live view from outside this Mac (phones on 4G, networks that block UDP) | `infra/turn` image and `TURN_*` settings; tested only on Docker Desktop (D-055) |
| A phone on a mobile network | The Phase 5 gate "live view under 500 ms on 4G" | Measured 1–3 ms data-channel RTT locally (D-060) |
| GitHub Actions enabled on `stackwares/kasama` | CI (lint, tests, RLS on real Supabase, image builds) | Disabled at the repo/org level; workflows are committed but have not run. Private repos use the org's free Actions minutes |
| Review of Dependabot PRs | Dependency updates opened automatically on the first push | 5+ PRs left open, not merged |

## Phase 6 publishing and platform checks

| Item                                                                                                | Needed for                                                                     | Status                                                                                      |
| --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| A pub.dev publisher (for example `kasama.dev`) and `dart pub publish` of kasama_api then kasama_sdk | The published SDK (gate: an external app uses it)                              | Dry runs clean; `examples/sdk_sample` streams a run using the 0.6.0 packages from this repo |
| A public `stackwares/homebrew-tap` repository and a `cli-v0.6.0` release                            | `brew install stackwares/tap/kasama`                                           | Formula generator and release workflow ready; macOS arm64 binary built locally              |
| Apple team: App Group `group.dev.kasama.app` and signing for the widget and share extensions        | Widgets, Live Activities and share to bot on real iPhones                      | Extensions build for the simulator; not run on a device                                     |
| Developer ID certificate and notarization                                                           | Distributing the macOS app (it runs without the App Sandbox for the companion) | Debug and release builds run locally                                                        |
| A Windows and a Linux machine                                                                       | Checking the companion, tray and global shortcut there                         | Built and tested on macOS only                                                              |
| A real Android share from another app                                                               | Confirming the share sheet entry (the quick-ask route it opens is verified)    | Deep link checked on the emulator                                                           |

## Phase 3 app distribution and testers

| Item                                                                                     | Needed for                                             | Status                                                                               |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| Apple Developer account (TestFlight) and signing identity                                | iOS tester builds                                      | `flutter build ios --no-codesign` succeeds; not signed                               |
| Google Play Console account (internal testing track)                                     | Android tester builds                                  | Debug APK builds; no release signing key                                             |
| A place to host the web preview                                                          | Web testers                                            | `flutter build web` succeeds; nothing deployed (no deploys per instructions)         |
| 10 testers for a week                                                                    | The Phase 3 gate ("80% of runs finish without errors") | Replaced by automated end-to-end runs on 4 platforms                                 |
| Google and Apple OAuth credentials configured in Supabase Auth                           | "Continue with Google/Apple" buttons                   | Buttons call Supabase OAuth; providers not configured locally                        |
| Error reporting (optional): a Sentry or GlitchTip DSN, or a PostHog project key and host | Errors from server, supervisor and app (D-063)         | `SENTRY_DSN` or `POSTHOG_API_KEY`/`POSTHOG_HOST`; app `--dart-define` the same names |

## Decisions only Oliver can make

| Decision                      | Default used                                                                |
| ----------------------------- | --------------------------------------------------------------------------- |
| Final product name and domain | "Kasama", placeholder addresses `security@kasama.dev`, `conduct@kasama.dev` |
