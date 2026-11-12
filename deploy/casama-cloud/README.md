# Casama Cloud server

How `api.casama.ai` and `auth.casama.ai` move from the development Mac's tunnel (D-171) to a
server of their own (D-197). The server runs the normal self-host stack from published images
(`ghcr.io/stackwares/casama/<name>`, tags `<sha>`, `edge` and `latest`). A new package is private
until its visibility is set to public in GitHub package settings. `./install.sh --pull` cannot
download a private package.

## 1. Install

On a fresh Linux server with Docker (4+ vCPU, 16 GB recommended; see `docs/COSTS.md`):

```sh
git clone https://github.com/stackwares/casama && cd casama
./install.sh --pull --behind-proxy --domain api.casama.ai --turn-host turn.casama.ai \
  --search --backups --settings deploy/casama-cloud/settings.env --no-start
```

`--no-start` stops after writing `infra/compose/.env`, so the secrets below can go in first.

## 2. Secrets in `infra/compose/.env`

All of these are in Vaultwarden. Never commit them, and never copy them to another machine.

| Setting                                                             | Vaultwarden item                                           |
| ------------------------------------------------------------------- | ---------------------------------------------------------- |
| `BACKUP_S3_ACCESS_KEY_ID`, `BACKUP_S3_SECRET_ACCESS_KEY`            | Cloudflare R2 · casama-backups · S3 key RW                  |
| `SMTP_USER=hello@casama.ai`, `SMTP_PASS`                            | Zoho SMTP hello@casama.ai                                   |
| `COMPOSIO_API_KEY` (the **prod** key)                               | Composio API key: Casama org, casama_prod project           |
| `CASAMA_LICENSE_KEY`                                                | Casama · enterprise license key (Casama Cloud)              |
| `SENTRY_DSN`, `POSTHOG_API_KEY`                                     | Sentry and PostHog items (casama-server)                    |
| `POSTHOG_PERSONAL_API_KEY`, `POSTHOG_PROJECT_ID`                    | A PostHog personal key with person write scope, and project 637030: deletes a purged account's analytics (D-208). Not created yet |
| `GOOGLE_AI_API_KEY` (live calls without a key, D-177)               | Google AI Studio (Gemini API key) - Casama                  |
| `CLOUD_MODEL_UPSTREAM_KEY` (OpenRouter on the Cloud account, D-186) | OpenRouter Casama workspace key                             |
| `DODO_*`, `APP_STORE_*`, `GOOGLE_PLAY_*`                            | Once billing is set up (NEEDS-FROM-OLIVER, Phase 7)          |
| `MCP_OAUTH_CLIENTS`, `GOOGLE_OAUTH_CLIENT_ID/SECRET`                | Once the OAuth apps exist (section 5)                       |

The installer already generated everything else: database and worker passwords
(`WORKER_DB_PASSWORD` gives the worker its own least-privilege login, D-095), JWT keys,
`AUTH_HOOK_SECRET` for the sign-up hook, TURN and internal tokens. Back that file up: the
backup service uploads it encrypted every night.

Then start: `./install.sh` (re-running keeps the .env and pulls the images).

## 3. Network

- **Cloudflare Tunnel** for HTTPS (done 2026-11-12, D-199): the server runs the `casama-prod`
  tunnel as the `cloudflared` service. Its ingress sends `api.casama.ai`, `auth.casama.ai` and
  `telemetry.casama.ai` to `http://localhost:80` and `pages.casama.ai` to `http://localhost:8790`
  (`cf tunnels config get|update`). `api-dev`, `auth-dev` and `app-dev` stay on the Mac's
  `casama-dev` tunnel (D-172). The rewrite rule `telemetry.casama.ai/v1/ping` →
  `/telemetry/v1/ping` is already at Cloudflare's edge.
- **Start without `install.sh` while names move:** its readiness check calls the public URL, which
  may still reach another machine. `docker compose ... --profile search --profile backup up -d`,
  then `curl http://127.0.0.1/readyz` on the server.
- **DNS on Contabo:** its resolvers returned SERVFAIL; set 1.1.1.1 / 9.9.9.9 in
  `/etc/systemd/resolved.conf.d/`.
- **TURN for live view**: a DNS-only (grey cloud) record `turn.casama.ai` → the server's public
  IP, and the firewall open for **3478 UDP and TCP**. That is the only port live view needs:
  media goes relay to relay inside coturn, so the 49160–49260 relay range stays closed.
- Nothing else is published: SSH, plus 3478. Ports 80/443 stay closed when the tunnel serves HTTPS.
  Docker-published ports skip ufw, so the server also has a `DOCKER-USER` rule in
  `/etc/ufw/after.rules` dropping outside traffic to containers except 3478.

## 4. Checks after start

```sh
curl -fsS https://api.casama.ai/readyz
docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env \
  --profile backup run --rm backup now      # one backup right away
docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env \
  --profile backup run --rm backup list
```

Restore test (on the Mac, with the private key from Vaultwarden "Casama Cloud backups age key"):
download a backup folder, `age -d -i key.txt -o postgres.dump postgres.dump.age`, then
`pg_restore --list postgres.dump`.

## 5. Still needs Oliver (vendor consoles)

- **OAuth apps** (D-166), each with redirect `https://api.casama.ai/oauth/callback`:
  Google (one client for Gmail, Calendar and Drive; restricted-scope review), Slack, HubSpot,
  Asana, Box, GitHub (optional) and Figma (approval needed). Their ids and secrets go in
  `MCP_OAUTH_CLIENTS` and `GOOGLE_OAUTH_CLIENT_ID/SECRET`.
- **App Check** in the Firebase console for project `kasama-ai`: App Attest (and DeviceCheck with
  the "DeviceCheck (App Check)" key) for the Apple app, Play Integrity for Android (link the
  Cloud project in Play Console), reCAPTCHA Enterprise for web. The server already verifies
  tokens for project number 278631205206; until the apps send them, sign-ups use the
  proof-of-work puzzle.
