# Needs from Oliver

Everything below is built and tested against mocks, fixtures or local stand-ins. Each item says what is needed to use the real thing and where it plugs in. Newest items are added at the end of each section.

## Keys and accounts

| Item                                                                        | Needed for                                                     | Where it plugs in                                  | Status                                                         |
| --------------------------------------------------------------------------- | -------------------------------------------------------------- | -------------------------------------------------- | -------------------------------------------------------------- |
| A model key (OpenRouter is simplest; any of OpenAI, Anthropic, Google, xAI) | Real bot replies instead of recorded fixtures                  | `kasama credential add`, or `POST /v1/credentials` | Gateway wired for all providers; only replayed fixtures tested |
| An OpenAI key (optional)                                                    | Vector embeddings for memory (otherwise full-text search only) | Same as above, provider `openai`                   | Hybrid search tested with an offline hash embedder             |
| Resend API key and a sending domain                                         | Invite emails (and the bot email channel in Phase 6)           | `RESEND_API_KEY`, `EMAIL_FROM`                     | Invites fall back to returning the token                       |

## Infrastructure

| Item                                                      | Needed for                                                                       | Status                                                                                              |
| --------------------------------------------------------- | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| A Linux host with gVisor (`runsc`)                        | Verifying the spec's sandbox runtime. Docker Desktop on macOS only has `runc`    | Supervisor takes `SANDBOX_RUNTIME=runsc`; all sandbox tests ran on `runc` here                      |
| Docker Desktop running on this Mac                        | Phase 2+ tests (computers)                                                       | Installed 2026-11-09                                                                                |
| Supabase (local via `supabase start`, which needs Docker) | Testing against real Supabase Auth, Realtime and Vault instead of the local shim | Migrations and all pgTAP tests verified on the real Supabase Postgres image; app tests use the shim |

| A Linux sandbox host with XFS project quotas | Enforcing the 10 GB per-computer disk limit (D-032) | Free disk is reported; no hard cap on Docker Desktop |
| Object storage bucket (Cloudflare R2 free tier or Supabase Storage) | Computer snapshots and checkpoints off the sandbox host | `OBJECT_STORE=s3` + `S3_*` variables; tested only with the filesystem store |

## Decisions only Oliver can make

| Decision                      | Default used                                                                |
| ----------------------------- | --------------------------------------------------------------------------- |
| Final product name and domain | "Kasama", placeholder addresses `security@kasama.dev`, `conduct@kasama.dev` |
