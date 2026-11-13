# Operating your server

This page covers day-to-day work on a running Casama server: upgrades, backups, monitoring, logs,
audit-log forwarding and scaling, plus the Kubernetes Helm chart. The commands use the
[Casama CLI](/develop/cli), which wraps `install.sh` and `docker compose` for your checkout.

## Everyday commands

Run these from the checkout, or pass `--dir ~/casama` (or set `CASAMA_SELFHOST_DIR`).

| Task          | Command                                                                       |
| ------------- | ----------------------------------------------------------------------------- |
| Status        | `casama selfhost status`                                                      |
| Logs          | `casama selfhost logs -f` (api and worker), or name services: `logs migrate supervisor` |
| Start         | `casama selfhost up`                                                          |
| Stop          | `casama selfhost down` (data is kept)                                         |
| Upgrade       | `casama selfhost upgrade`                                                     |
| Back up       | `casama selfhost backup --out /backups`                                       |
| Restore       | `casama selfhost restore /backups/<timestamp>`                                |

Each one maps to plain Compose, if you prefer:

```sh
docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env ps
```

`casama selfhost down` stops the stack but leaves running bot computers alone, because the
supervisor creates them outside Compose. After the next `up`, the worker archives and stops any that
sat idle for 5 minutes.

::: danger Don't delete the volumes
`docker compose down -v` deletes the database, computer archives and certificates. The CLI never
passes `-v`.
:::

## Upgrade

1. Back up first:

   ```sh
   casama selfhost backup --out /backups
   ```

2. Upgrade:

   ```sh
   casama selfhost upgrade
   ```

   This runs `git pull --ff-only` in the checkout, then `./install.sh`. The installer keeps
   `infra/compose/.env`, adds any settings the new release introduced, rebuilds the images (or, if
   you installed with `--pull`, pulls the published ones for `CASAMA_VERSION`), applies new database
   migrations and restarts the services that changed. A server pinned to one image tag stays on it:
   run `./install.sh --pull` (or `--pull <tag>`) to move it.

3. Check the result with `casama selfhost status` and the admin console.

`casama selfhost upgrade` runs the installer with no options. If you installed with
`--with-desktop`, `--monitoring`, `--web` or `--search`, upgrade by hand instead so those parts are
updated too:

```sh
git pull --ff-only
./install.sh --with-desktop --monitoring --web --search
```

The installer doesn't rebuild an existing web image. After an upgrade with `--web`, rebuild it:

```sh
docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env --profile web build web
docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env --profile web up -d
```

Notes:

- Migrations run automatically in the one-shot `migrate` service at every start, once each, in
  order. They're tracked in `public.casama_migrations`.
- Running computers keep the image they started with. They pick up the new image the next time
  they sleep and wake.
- Runs waiting for an approval, a key or a takeover pick up again after the upgrade. A run whose
  recorded steps no longer match the new code ends as failed, with a note that Casama was updated
  while it waited.
- If `git pull --ff-only` fails, you have local changes to tracked files (for example an edited
  `docker-compose.yml`). Commit them on a local branch or stash them, then try again.

## Back up your server

```sh
casama selfhost backup --out /backups
```

Each run writes a timestamped folder, for example `/backups/2026-11-11T09-30-00`, with:

| File              | Contents                                                       |
| ----------------- | -------------------------------------------------------------- |
| `postgres.dump`   | The whole database (`pg_dump` custom format)                    |
| `objects.tar.gz`  | Computer archives and checkpoints from the `objects` volume     |
| `env`             | A copy of `infra/compose/.env`, with every key                  |
| `vault-key`       | The database's Vault root key. The saved secrets in the dump (model keys, app sign-ins) can't be read on another machine without it |

`--out` defaults to `casama-backups` in the current directory. With S3 object storage, the archive
only covers the local volume, so back up the bucket with your provider's tools.

### Encrypt backups and keep a set number

Backups hold every key for your server, so encrypt them before they leave the machine. Casama uses
[age](https://age-encryption.org).

1. Install age (`apt install age` or `brew install age`).
2. On another machine, create a key pair:

   ```sh
   age-keygen -o backup.key
   ```

   It prints the public key (`age1...`). Keep `backup.key` off the server.

3. Back up with encryption and retention:

   ```sh
   casama selfhost backup --out /backups --encrypt --recipient age1... --keep 14 --keep-days 30
   ```

| Option                 | What it does                                                                                       |
| ---------------------- | -------------------------------------------------------------------------------------------------- |
| `--out <folder>`       | Where backup folders go (default `casama-backups`).                                               |
| `--encrypt`            | Encrypts each file with age (`postgres.dump.age` and so on) and removes the plaintext.             |
| `--recipient <key>`    | An age public key (`age1...`) or SSH public key to encrypt to. Repeat for more.                    |
| `--keep <n>`           | Keep only the newest n backups in `--out`.                                                         |
| `--keep-days <n>`      | Remove backups older than n days. With `--keep` too, a backup goes only when it's outside both.    |

`CASAMA_BACKUP_RECIPIENTS` (comma-separated) can stand in for `--recipient`. Retention only removes
the timestamped folders the CLI itself wrote.

### Schedule backups

Run the backup daily with cron and copy the folder off the machine. For example, in the crontab of
a user who can run Docker:

```text
30 3 * * * casama selfhost backup --dir /opt/casama --out /backups --encrypt --recipient age1... --keep 14 >> /var/log/casama-backup.log 2>&1
```

Then sync `/backups` to other storage with your usual tool.

### Off-site backups

`./install.sh --backups` starts a `backup` container that does this every day, without cron. It
dumps the database, optionally the computer archives, encrypts each file with age, and uploads the
folder to any S3-compatible bucket (Cloudflare R2, AWS S3, Backblaze B2, MinIO). The `.env` and
the Vault key (`vault-key`) are included only when `BACKUP_AGE_RECIPIENTS` is set, so set it:
without the Vault key a restore on another machine loses every saved secret. If encryption fails, the folder is deleted and
nothing is uploaded.

| Setting | What it does |
| --- | --- |
| `BACKUP_S3_BUCKET` | Bucket name. Empty keeps backups only in the local `backups` volume. |
| `BACKUP_S3_ENDPOINT` | `https://<account>.r2.cloudflarestorage.com` for R2. Empty for AWS. |
| `BACKUP_S3_REGION` | `auto` for R2. The bucket's region for AWS. |
| `BACKUP_S3_ACCESS_KEY_ID`, `BACKUP_S3_SECRET_ACCESS_KEY` | The bucket's key. |
| `BACKUP_S3_PREFIX` | Folder in the bucket (default `casama`). |
| `BACKUP_TIME` | `HH:MM` in UTC (default `03:30`). |
| `BACKUP_KEEP_DAYS` | Delete backups older than this many days (default `30`). |
| `BACKUP_AGE_RECIPIENTS` | Comma-separated age public keys (`age1…`) or SSH public keys. |
| `BACKUP_OBJECTS` | `true` to include computer archives. |
| `BACKUP_PING_URL` | Called after each success. `/fail` is appended after a failure. |

```sh
docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env \
  --profile backup run --rm backup now
docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env \
  --profile backup run --rm backup list
```

To read one back: download the folder, `age -d -i backup.key -o postgres.dump postgres.dump.age`,
then `pg_restore --list postgres.dump`. Restore the database with
[Restore](#restore) after decrypting. Casama Cloud's settings are in
`deploy/casama-cloud/settings.env`.

### Restore

`restore` replaces the current data with the backup.

```sh
casama selfhost restore /backups/2026-11-11T09-30-00
# encrypted backup:
casama selfhost restore /backups/2026-11-11T09-30-00 --identity backup.key
```

It stops the API and worker, puts the backup's Vault key in place and restarts the database to
load it, restores the database with `pg_restore --clean` as the database's admin user (so sign-in
accounts and saved secrets come back with their owners), unpacks the computer archives into the
`objects` volume, and starts the stack again.

A backup made before `vault-key` was added has no key. It restores fine on the machine it came
from; on a new machine, saved secrets (model keys, app sign-ins) have to be entered again.

`restore` doesn't touch `infra/compose/.env`. To restore onto a new machine:

1. Clone the same release of the repository.
2. Copy the backup's `env` file to `infra/compose/.env` (decrypt it first with
   `age -d -i backup.key -o infra/compose/.env env.age` if it's encrypted).
3. Run `./install.sh`. It keeps that `.env`, so the new stack uses the same keys.
4. Run `casama selfhost restore <backup-folder>`.

::: warning Test your restores
The backup holds the database, computer archives and `.env`. It doesn't include the other Docker
volumes (for example `db-config`, which holds the database's own configuration, or Caddy's
certificates). Restore onto a spare machine now and then, and check that you can sign in, that bots
answer with their saved model keys, and that a computer wakes with its files.
:::

## Monitoring

The `monitoring` profile adds Prometheus, node-exporter and a Grafana dashboard.

1. Turn it on:

   ```sh
   ./install.sh --monitoring
   ```

   Or add the profile to a running stack:

   ```sh
   docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env --profile monitoring up -d
   ```

2. Grafana listens on `127.0.0.1:3001` on the server. From your computer, open an SSH tunnel:

   ```sh
   ssh -L 3001:127.0.0.1:3001 you@casama.example.com
   ```

3. Open `http://localhost:3001` and sign in as `admin` with `GRAFANA_ADMIN_PASSWORD` from
   `infra/compose/.env`. The **Casama overview** dashboard is already provisioned.

Prometheus keeps 30 days of data and isn't published on the host. It scrapes the API's `/metrics`
inside the stack with `METRICS_TOKEN`, and node-exporter for host metrics. The config is in
`infra/monitoring/prometheus.yml`.

### Metrics

The API serves Prometheus metrics at `/metrics` with a bearer token (`METRICS_TOKEN`). Caddy doesn't
route `/metrics`, so it's only reachable inside the stack. The values are computed from Postgres on
each scrape.

| Metric                                  | What it measures                                        |
| --------------------------------------- | ------------------------------------------------------- |
| `casama_runs_15m`                       | Runs created in the last 15 minutes, by status          |
| `casama_run_failure_ratio_15m`          | Failed runs out of finished runs, last 15 minutes       |
| `casama_time_to_first_token_seconds`    | Run start to first model token, p50 and p95, last hour  |
| `casama_computer_start_seconds`         | Computer start or wake time, p50 and p95, last hour     |
| `casama_computers`                      | Computers by state                                      |
| `casama_cost_per_run_usd`               | Average cost of completed runs, last hour               |
| `casama_queue_depth`                    | Queued and running workflows, by queue                  |
| `casama_http_requests_total`            | API responses by status                                 |
| `casama_http_request_seconds_sum`, `_count` | Total API response time and responses timed         |

### Alerts

`infra/monitoring/alerts.yml` defines these rules:

| Alert                          | Fires when                                                         | Severity |
| ------------------------------ | ------------------------------------------------------------------ | -------- |
| `CasamaRunFailuresHigh`        | More than 5% of runs failed in 15 minutes (at least 20 finished), for 5 minutes | page     |
| `CasamaSandboxMemoryHigh`      | A host is above 85% memory for 10 minutes                          | page     |
| `CasamaTimeToFirstTokenSlow`   | p95 time to first token is above 3 seconds for 15 minutes          | warn     |
| `CasamaQueueBacklog`           | More than 200 runs are waiting, for 10 minutes                     | warn     |
| `CasamaApiDown`                | Prometheus can't scrape the API for 2 minutes                      | page     |

The stack doesn't include Alertmanager. Route alerts to email or chat with your own Alertmanager or
with Grafana alerting.

### The admin console

Instance owners see a health summary under Settings → admin console: the database, the worker, the
sandbox supervisor, the live view relay, personal computers, email, error reporting, the enterprise
license and telemetry, each with whether it's configured and healthy.

### Remote app settings

Under Settings → admin console → **App settings**, the instance owner can change every installed
app without a release. The settings are JSON:

```json
{
  "min_versions": { "ios": "0.9.0", "android": "0.9.0" },
  "update_urls": { "ios": "https://apps.apple.com/app/…", "android": "https://play.google.com/store/apps/details?id=…" },
  "maintenance": null,
  "announcements": [
    { "id": "spring-update", "title": "New: routine ideas", "body": "Start a routine from an idea.", "level": "info",
      "url": "https://casama.ai/changelog", "ends_at": "2026-12-01T00:00:00Z", "platforms": ["ios", "android"] }
  ],
  "flags": { "new_home": true }
}
```

- `min_versions`: apps older than this on a platform show **Time to update Casama** instead of the
  app, with an **Update** button to `update_urls` for that platform. Platforms: `ios`, `android`,
  `macos`, `windows`, `linux`, `web`.
- `maintenance`: `{ "message": "Back at 3 pm UTC." }` covers every app with that message until it's
  `null` again.
- `announcements`: up to 10 banners. Each has an `id`, a `title`, an optional `body`, `url`, `level`
  (`info` or `warning`), a time window, `platforms` and `min_version` / `max_version`. A dismissed
  banner stays dismissed on that device.
- `flags`: on/off switches the app reads by name.

Apps read the settings without signing in (`GET /v1/app-config`), every half hour and whenever they
come back to the front, and keep the last copy for when they're offline.

### Health endpoints

| Endpoint    | What it checks                                                     |
| ----------- | ------------------------------------------------------------------ |
| `/healthz`  | The API process answers. Always `200` while it's up.               |
| `/readyz`   | The API can reach the database. `503` with `"degraded"` otherwise. |

The supervisor has its own `/healthz` on port 8788, inside the stack.

## Logs

```sh
casama selfhost logs -f                       # api and worker
casama selfhost logs migrate                  # database migrations
casama selfhost logs -f supervisor egress     # computers and their internet access
casama selfhost logs auth                     # Supabase Auth: sign-in and email
```

`logs` shows the last 200 lines of each service; `-f` follows. The API, worker, supervisor and
egress proxy write JSON lines, one event each. The egress proxy logs each outbound connection a
computer makes.

To see bot computers, which run outside Compose:

```sh
docker ps --filter name=casama-c-
```

Set the API and worker's detail with `LOG_LEVEL` (see
[Telemetry and observability](/self-hosting/configuration#telemetry-and-observability)). For run-level traces, use
Langfuse or an OpenTelemetry collector (see
[Telemetry and observability](/self-hosting/configuration#telemetry-and-observability)).

## Audit-log forwarding

Audit-log forwarding streams each workspace's audit log to your own systems. It's an enterprise
feature: it needs a `CASAMA_LICENSE_KEY` that includes `audit_forwarding`. Without one, the
endpoints answer `402`.

Workspace owners and admins manage forwarders through the API at
`/v1/orgs/{id}/audit-forwarders` (`GET` to list, `POST` to add, `DELETE /{forwarder_id}` to remove).
Each forwarder sends to one destination:

| `kind`    | `config`                                                         | `secret`                                                         |
| --------- | ---------------------------------------------------------------- | ---------------------------------------------------------------- |
| `webhook` | `url`                                                            | Required: the signing secret                                     |
| `otlp`    | `url` (Casama posts to `<url>/v1/logs`)                          | Optional: JSON of extra headers, for example an auth token       |
| `s3`      | `bucket`; optional `endpoint`, `region` (default `us-east-1`), `prefix` (default `casama-audit`) | Required: `{"access_key_id":"...","secret_access_key":"..."}` |

For example, a signed webhook:

```sh
curl -X POST https://casama.example.com/v1/orgs/$ORG_ID/audit-forwarders \
  -H "authorization: Bearer $TOKEN" -H "content-type: application/json" \
  -d '{"kind":"webhook","config":{"url":"https://siem.example.com/casama"},"secret":"a-long-random-secret"}'
```

`$TOKEN` is a signed-in admin's access token (see [API](/develop/api)). Add `"from":"start"` to send
the whole history instead of starting from now.

How delivery works:

- The worker runs a pass every minute and sends new rows in order, in batches of up to 500.
- **Webhook:** JSON `{forwarder_id, events}` with an `X-Casama-Signature: t=<unix>,v1=<hex>` header,
  the HMAC-SHA256 of `<t>.<body>` with your secret.
- **OTLP:** each row becomes a log record under `service.name=casama`, scope `casama.audit`.
- **S3:** one JSON Lines object per batch at `<prefix>/<workspace>/YYYY/MM/DD/<ms>-<first id>.jsonl`,
  path-style, so AWS S3, R2 and MinIO work.
- Delivery is at least once. A failed batch stays put (the forwarder's `last_error` says why) and
  goes again on the next pass.

Secrets are stored in Supabase Vault.

## Scaling

**Worker concurrency.** `RUN_CONCURRENCY` (default `20`) is how many runs one worker processes at
once. Raise it on a bigger machine, then run `casama selfhost up`. The worker opens up to
`RUN_CONCURRENCY + 5` database connections. Watch `casama_queue_depth` and the
`CasamaQueueBacklog` alert to see when you need more.

**Computer size.** `COMPUTER_MEMORY_MB` (default `2048`) sets each new computer's memory. Each
computer also gets 1 CPU, 512 processes, a 1 GB `/tmp` and 512 MB of shared memory. Plan host
memory as about 2 GB per running computer, plus the stack itself.

**Warm pool.** `WARM_POOL_SIZE` keeps that many headless computers started and unassigned, so a new
computer starts in seconds instead of booting. A new computer with the default size claims one, and
the pool refills after each claim and every minute. Desktop and custom-size computers always start
cold. Each pool member uses memory while it waits. It works with the Docker provider only.

**Idle computers.** The worker archives computers to object storage and stops them after 5 minutes
without activity, so only computers in use take memory. Open terminals, running commands and live
viewers keep a computer awake.

### Run computers on a separate host

On a public server, keep untrusted code and the Docker socket off the machine with your data. The
supervisor, egress proxy and TURN relay must run together on the computer host: the supervisor
attaches the proxy and the relay to each computer's network by container name.

1. On the computer host, clone the same release and copy `infra/compose/.env` from the app host.
2. In `infra/compose/docker-compose.yml` on the computer host, publish the supervisor's port on the
   private interface only, for example under `services.supervisor`:

   ```yaml
   ports:
     - "10.0.0.2:8788:8788"
   ```

3. Build and start only those services:

   ```sh
   docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env build supervisor egress turn
   COMPOSE_PROFILES=images docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env build computer-headless
   docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env up -d supervisor egress turn
   ```

4. On both hosts, set `TURN_PUBLIC_HOST` to a name that points at the computer host, and open 3478
   (UDP and TCP) there.
5. On the app host, the compose file sets `SUPERVISOR_URL: http://casama-supervisor:8788` in the
   shared `x-casama` block. Change it to the computer host's private address
   (`http://10.0.0.2:8788`), then stop and remove the local `supervisor`, `egress` and `turn`
   services.
6. Connect the two hosts over a private network or WireGuard. The supervisor checks
   `SUPERVISOR_TOKEN` on every call, but it should never be reachable from the internet.

With computers on another host, their archives live in that host's `objects` volume. Back it up
there, or switch to [S3 object storage](/self-hosting/configuration#object-storage) so both hosts
see the same store. Add the computer host's node-exporter to `infra/monitoring/prometheus.yml` to
get its memory alerts.

## Kubernetes with Helm

`infra/helm/casama` runs the API, worker, supervisor and, optionally, the web app on Kubernetes.
Computers run as pods in their own namespace through the supervisor's Kubernetes provider. The
chart doesn't run Postgres or Supabase: point it at Supabase Cloud or your own Supabase (for
example the Supabase Helm chart).

1. Install:

   ```sh
   helm install casama infra/helm/casama -n casama --create-namespace \
     --set publicUrl=https://casama.example.com \
     --set pagesUrl=https://pages.casama.example.com \
     --set supabase.url=https://xyz.supabase.co \
     --set supabase.anonKey=... --set supabase.serviceRoleKey=... --set supabase.jwtSecret=... \
     --set database.url=postgres://postgres:...@db.xyz.supabase.co:5432/postgres \
     --set ingress.apiHost=casama.example.com --set ingress.pagesHost=pages.casama.example.com
   ```

2. Point Supabase Auth's "before user created" hook at
   `https://casama.example.com/hooks/auth/before-user-created` if you want the sign-up allowlist.
3. Upgrade later with `helm upgrade` and the same values. Migrations run first.

What the chart does:

- **Migrations** run as a pre-install and pre-upgrade Job. The migration files are copied out of the
  server image, so the chart and image never drift apart. The Job uses `database.adminUrl`
  (defaults to `database.url`).
- **Secrets**: `INTERNAL_TOKEN`, `SUPERVISOR_TOKEN`, `COMPUTER_TOKEN_SECRET` and `METRICS_TOKEN` are
  generated once and kept across upgrades. A value you set wins, then the existing Secret, then a
  new random one. The Secret is kept on uninstall. Bring your own with `existingSecret`.
- **Computers** run as pods in `computers.namespace`. The supervisor's Role there allows only
  pods and pod proxying. Set `computers.runtimeClass` to a gVisor or Kata runtime class if your
  cluster has one.
- **Ingress** routes the API host's API paths to the API (and `/` to the web app when it's on), and
  the Pages host to the API's Pages port.
- The supervisor keeps computer archives on a 20 Gi `ReadWriteOnce` volume, with one replica.

### Values

| Value                      | Default                               | What it does                                                         |
| -------------------------- | ------------------------------------- | -------------------------------------------------------------------- |
| `image.registry`           | `ghcr.io/stackwares/casama`                  | Where the `server`, `supervisor`, `computer-headless`, `computer-desktop` and `web` images come from. |
| `image.tag`                | `latest`                              | Image tag for all of them.                                           |
| `image.pullSecrets`        | `[]`                                  | Pull secrets for a private registry.                                 |
| `publicUrl`                | `https://casama.example.com`          | The API's public address.                                            |
| `pagesUrl`                 | `https://pages.casama.example.com`    | Pages' public address.                                               |
| `supabase.url`             | `https://your-project.supabase.co`    | Supabase address.                                                    |
| `supabase.anonKey`         | Required                              | Supabase anon key.                                                   |
| `supabase.serviceRoleKey`  | Required                              | Supabase service role key.                                           |
| `supabase.jwtSecret`       | Required                              | Supabase JWT secret.                                                 |
| `database.url`             | Required                              | Full-access Postgres URL for the API.                                |
| `database.workerUrl`       | `database.url`                        | Least-privilege URL for the worker.                                  |
| `database.adminUrl`        | `database.url`                        | URL migrations run with (`supabase_admin` on self-hosted Supabase).  |
| `existingSecret`           | (empty)                               | Use your own Secret with the generated keys and `CONTENT_ENCRYPTION_KEY`. |
| `secrets.*`                | (empty: generated)                    | `internalToken`, `supervisorToken`, `computerTokenSecret`, `metricsToken`, `contentEncryptionKey`. |
| `extraEnv`                 | `{}`                                  | More environment for the API and worker, for example `RESEND_API_KEY`. |
| `api.replicas`             | `2`                                   | API replicas.                                                        |
| `worker.replicas`          | `1`                                   | Worker replicas.                                                     |
| `worker.runConcurrency`    | `20`                                  | `RUN_CONCURRENCY` for the worker.                                    |
| `supervisor.enabled`       | `true`                                | Run the supervisor and computers.                                    |
| `computers.namespace`      | `casama-computers`                    | Namespace for computer pods.                                         |
| `computers.create`         | `true`                                | Create that namespace.                                               |
| `computers.runtimeClass`   | (empty)                               | Runtime class for computer pods (gVisor, Kata).                      |
| `computers.memoryMb`       | `2048`                                | Passed to the supervisor as `COMPUTER_MEMORY_MB`, which only the Docker provider reads. Computer pods get no limits from it. |
| `web.enabled`              | `false`                               | Run the web app.                                                     |
| `migrations.enabled`       | `true`                                | Run the migration Job.                                               |
| `ingress.enabled`          | `true`                                | Create an Ingress.                                                   |
| `ingress.className`        | (empty)                               | Ingress class.                                                       |
| `ingress.apiHost`          | `casama.example.com`                  | Host for the API (and the web app).                                  |
| `ingress.pagesHost`        | `pages.casama.example.com`            | Host for Pages.                                                      |
| `ingress.tls`              | `[]`                                  | Ingress TLS blocks.                                                  |

Each component also has a `resources` value.

### What the chart leaves out

- **Live view.** The chart doesn't run a TURN relay, so desktop computers have no live view.
- **The egress proxy.** Computer pods use the cluster's network. Add a NetworkPolicy to the
  computers namespace that blocks private ranges and cloud metadata addresses.
- **The warm pool**, which needs the Docker provider.
- **Computer resource limits.** The Kubernetes provider sets pod limits only for a computer with its
  own size, so add a LimitRange to the computers namespace for default limits.
- **Supervisor settings beyond the defaults.** `extraEnv` reaches the API and worker only. Hosted
  providers or S3 object storage on the supervisor need a change to its Deployment.

Check the chart without installing anything locally: `scripts/check-helm.sh` runs `helm lint` and
`helm template` in the official Helm Docker image.

## Related

- [Self-hosting](/self-hosting/)
- [Configuration](/self-hosting/configuration)
- [Computer providers](/self-hosting/computers)
- [Troubleshooting](/self-hosting/troubleshooting)
- [CLI](/develop/cli)
- [API](/develop/api)
