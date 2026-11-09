# Needs from Oliver

Everything below is built and tested against mocks, fixtures or local stand-ins. Each item says what is needed to use the real thing and where it plugs in. Newest items are added at the end of each section.

## Keys and accounts

| Item                                                                        | Needed for                                                     | Where it plugs in                                                         | Status                                                         |
| --------------------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------- |
| A model key (OpenRouter is simplest; any of OpenAI, Anthropic, Google, xAI) | Real bot replies instead of recorded fixtures                  | `kasama credential add`, or `POST /v1/credentials`                        | Gateway wired for all providers; only replayed fixtures tested |
| An OpenAI key (optional)                                                    | Vector embeddings for memory (otherwise full-text search only) | Same as above, provider `openai`                                          | Hybrid search tested with an offline hash embedder             |
| Resend API key and a sending domain                                         | Invite emails (bot email channel is post-v1)                   | `RESEND_API_KEY`, `EMAIL_FROM`                                            | Invites fall back to returning the token                       |
| Composio API key (free tier)                                                | Composio integration tools (Phase 4)                           | Integration credentials in Vault; built against a mock until a key is set |
| Pipedream Connect project (client id and secret, free tier)                 | Pipedream Connect integration tools (Phase 4)                  | Same as above                                                             |
| fal.ai API key                                                              | `media.image.generate` / `media.video.generate` (Phase 4)      | `MediaProvider` fal.ai adapter; tested against a mock                     |

## Infrastructure

| Item                                                      | Needed for                                                                       | Status                                                                                              |
| --------------------------------------------------------- | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| A Linux host with gVisor (`runsc`)                        | Verifying the spec's sandbox runtime. Docker Desktop on macOS only has `runc`    | Supervisor takes `SANDBOX_RUNTIME=runsc`; all sandbox tests ran on `runc` here                      |
| Docker Desktop running on this Mac                        | Phase 2+ tests (computers)                                                       | Installed 2026-11-09                                                                                |
| Supabase (local via `supabase start`, which needs Docker) | Testing against real Supabase Auth, Realtime and Vault instead of the local shim | Migrations and all pgTAP tests verified on the real Supabase Postgres image; app tests use the shim |

| A Linux sandbox host with XFS project quotas | Enforcing the 10 GB per-computer disk limit (D-032) | Free disk is reported; no hard cap on Docker Desktop |
| Object storage bucket (Cloudflare R2 free tier or Supabase Storage) | Computer snapshots and checkpoints off the sandbox host | `OBJECT_STORE=s3` + `S3_*` variables; tested only with the filesystem store |

| GitHub Actions enabled on `stackwares/kasama` | CI (lint, tests, RLS on real Supabase, image builds) | Disabled at the repo/org level; workflows are committed but have not run. Private repos use the org's free Actions minutes |
| Review of Dependabot PRs | Dependency updates opened automatically on the first push | 5+ PRs left open, not merged |

## Phase 3 app distribution and testers

| Item                                                           | Needed for                                             | Status                                                                       |
| -------------------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------------- |
| Apple Developer account (TestFlight) and signing identity      | iOS tester builds                                      | `flutter build ios --no-codesign` succeeds; not signed                       |
| Google Play Console account (internal testing track)           | Android tester builds                                  | Debug APK builds; no release signing key                                     |
| A place to host the web preview                                | Web testers                                            | `flutter build web` succeeds; nothing deployed (no deploys per instructions) |
| 10 testers for a week                                          | The Phase 3 gate ("80% of runs finish without errors") | Replaced by automated end-to-end runs on 4 platforms                         |
| Google and Apple OAuth credentials configured in Supabase Auth | "Continue with Google/Apple" buttons                   | Buttons call Supabase OAuth; providers not configured locally                |
| Sentry DSN (optional)                                          | Crash reporting from the app                           | `--dart-define=SENTRY_DSN=...` turns it on                                   |

## Decisions only Oliver can make

| Decision                      | Default used                                                                |
| ----------------------------- | --------------------------------------------------------------------------- |
| Final product name and domain | "Kasama", placeholder addresses `security@kasama.dev`, `conduct@kasama.dev` |
