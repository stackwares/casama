# Self-hosting Kasama

One machine with Docker runs everything: Supabase (Postgres, Auth, REST, Realtime), the Kasama API
and worker, the sandbox supervisor and egress proxy for bot computers, the TURN relay for live view,
and Caddy for HTTPS. Self-hosted Kasama has no paywall and no limits.

## Requirements

- Linux with Docker Engine and Docker Compose v2 (macOS with Docker Desktop works for trials).
- 4+ vCPU and 8+ GB RAM for a few concurrent computers; about 2 GB RAM per running computer.
- 40+ GB disk (images about 6 GB, plus home folders and snapshots).
- For a public server: a domain pointing at the machine, and these ports open:
  80 and 443 (TCP), 3478 (UDP and TCP) and 49160–49260 (UDP) for live view.
- Recommended: gVisor (`runsc`) for stronger computer isolation. The installer uses it when Docker
  lists it as a runtime; otherwise computers run with runc plus the other controls (non-root user,
  read-only root filesystem, no capabilities, per-computer networks, egress proxy, resource limits).

## Install

```sh
git clone https://github.com/stackwares/kasama && cd kasama
./install.sh --domain kasama.example.com
```

The installer checks Docker, generates every secret with OpenSSL into `infra/compose/.env`, builds the
Kasama images, starts the stack and waits until the API is ready. Then open the Kasama app (or
`kasama login --api https://kasama.example.com`) and create the first account: it becomes the
instance owner, with the admin console under Settings.

- `--local` serves plain HTTP on this machine only (`--http-port 8080` to pick a port).
- `--with-desktop` also builds the desktop computer image (live view and desktop apps).
- `--monitoring` adds Prometheus and Grafana (Grafana on `127.0.0.1:3001`, password in `.env`).
- `--web` adds the web app at the same address.

The same steps are available as `kasama selfhost init` (with `--dir` pointing at the checkout).

Measured on the development Mac (Docker Desktop, Apple silicon, 2026-11-10): a fresh install that
built every Kasama image from scratch (no build cache) and started the stack took 2 minutes 47 seconds,
with the Supabase, Caddy and base images already downloaded; downloading those (about 3 GB) adds a few
minutes on a typical server connection. A re-run with images in place takes about a minute.

## Everyday operation

| Task         | Command                                                                                   |
| ------------ | ----------------------------------------------------------------------------------------- |
| Status       | `kasama selfhost status`                                                                  |
| Logs         | `kasama selfhost logs -f` (or `logs migrate`, `logs supervisor`)                          |
| Stop / start | `kasama selfhost down` / `kasama selfhost up`                                             |
| Upgrade      | `kasama selfhost upgrade` (git pull, rebuild, migrate, restart; `.env` and data are kept) |
| Backup       | `kasama selfhost backup --out /backups` (database dump, computer archives, `.env`)        |
| Restore      | `kasama selfhost restore /backups/<timestamp>`                                            |

Run the backup daily (cron) and copy it off the machine. Migrations are backward compatible for one
release, so the API and worker can be upgraded without downtime. `selfhost down` keeps bot computers
that are running; they are archived and stopped by the idle timer.

## Settings

All settings live in `infra/compose/.env`. Common ones:

| Setting                                                                              | Purpose                                                              |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `KASAMA_SITE`, `KASAMA_PUBLIC_URL`                                                   | The domain (automatic HTTPS) or `:80` behind another proxy           |
| `INSTANCE_ADMIN_EMAILS`                                                              | Comma-separated owners (default: the first account)                  |
| `DISABLE_SIGNUP=true`                                                                | Invite-only after the first accounts exist                           |
| `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`, `SMTP_ADMIN_EMAIL`, `EMAIL_AUTOCONFIRM=false` | Email confirmation and password reset through your SMTP server       |
| `FCM_SERVICE_ACCOUNT`                                                                | Push: Firebase service account JSON (one line) for the apps' project |
| `RESEND_API_KEY`                                                                     | Invite emails (otherwise invites return a code to share)             |
| `COMPUTER_MEMORY_MB`, `RUN_CONCURRENCY`                                              | Computer size and worker parallelism                                 |
| `SENTRY_DSN` or `POSTHOG_API_KEY`                                                    | Error reporting (off by default)                                     |
| `TELEMETRY=on`                                                                       | Opt-in anonymous counts (see below; off by default)                  |
| `KASAMA_CLOUD_URL`, `KASAMA_CLOUD_KEY`                                               | Cloud Connect: cloud computers and model credits                     |
| `CHATGPT_SIGN_IN=off`                                                                | Hide ChatGPT plan sign-in (on by default when self-hosted)           |

Object storage defaults to a Docker volume; `--profile s3` adds SeaweedFS, and any S3-compatible
store (Cloudflare R2, AWS S3) works with the `OBJECT_STORE=s3` settings described in
`.env.example`. Models: any OpenAI-compatible endpoint works, including a local Ollama
(`kasama credential add --provider openai_compatible --base-url http://host.docker.internal:11434/v1`).
People with a ChatGPT Go, Plus or Pro plan can use it instead of an API key: "Continue with
ChatGPT" in the desktop app's Settings → Model keys, or `kasama credential chatgpt`. Each plan
serves only the person who connected it.

## Two machines

For public deployments run computers on a second host: start the supervisor, egress proxy and TURN
relay there (same compose file, those services only), point `SUPERVISOR_URL` at it over a private
network or WireGuard, and keep the Docker socket off the app server.

## Monitoring

`/metrics` (bearer `METRICS_TOKEN`) exposes run success rate, time to first token, computer start
time, computers by state, cost per run, queue depth and API error rate. The monitoring profile
ships a Grafana dashboard and alert rules (run failures above 5% over 15 minutes, host memory above
85%, slow first tokens, queue backlog, API down); route alerts with Alertmanager or Grafana.

## Privacy

Users can export their data (Settings → Privacy, or `kasama account export`) and delete their
account; deleted accounts are purged with their solely owned workspaces and computer snapshots after
`ACCOUNT_DELETION_GRACE_DAYS` (default 7). Run events are kept for each workspace's retention setting
(default 180 days).

**Telemetry** is off. With `TELEMETRY=on` the worker sends, once a week, a random instance id, the
Kasama version and two numbers (bots and users active in the last 7 days) to
`TELEMETRY_URL`. Nothing else: no names, emails, content, keys or addresses.

## Troubleshooting

- `kasama selfhost logs migrate`: migrations wait for Supabase Auth and Realtime to create their
  schemas, then apply in order (tracked in `public.kasama_migrations`).
- Live view needs the TURN ports reachable from viewers; behind strict networks add TLS on 5349.
- `docker ps --filter name=kasama-c-` lists bot computers; the supervisor creates and removes them.
