# Configuration

Every setting for a Compose install lives in one file: `infra/compose/.env`. The installer writes it
on the first run with generated secrets and a few defaults. This page lists every setting you can
put there, grouped by topic, with its default and what it does.

If you run Kasama with Helm or on a platform like Render or Railway, the same names apply as
environment variables on the API, worker and supervisor. See
[Database and auth](#database-and-auth) for the ones Compose sets for you.

## Change a setting

1. Edit `infra/compose/.env`. Use one `NAME=value` per line. An empty value counts as unset.
2. Apply it:

   ```sh
   kasama selfhost up
   ```

   Or, without the CLI:

   ```sh
   docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env up -d
   ```

Compose recreates every service whose settings changed. All Kasama services read their settings
only at start, so every change needs this step. `docker compose restart` is not enough: it restarts
containers with their old settings.

::: tip Optional profiles
`kasama selfhost up` doesn't name any Compose profiles. If you changed a setting for the web app or
monitoring, add the profile: `docker compose ... --profile monitoring up -d`. Docker Compose also
reads `COMPOSE_PROFILES` from the env file, so `COMPOSE_PROFILES=monitoring,web` in `.env` keeps
them on for every command.
:::

Some settings are read by the server but not passed through by the bundled compose file. They're
listed under [Advanced settings](#advanced-settings), with how to add them.

## Core and URLs

| Name                     | Default                         | What it does                                                                                                                          |
| ------------------------ | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `KASAMA_SITE`            | Set by the installer            | What Caddy serves: a domain (`kasama.example.com`, automatic HTTPS) or `:80` (plain HTTP, for `--local` or behind another proxy).      |
| `KASAMA_PUBLIC_URL`      | Set by the installer            | The public address, for example `https://kasama.example.com`. Used as the API, app and Supabase address and for Auth redirects.       |
| `HTTP_PORT`              | `80`                            | Host port Caddy listens on for HTTP.                                                                                                  |
| `HTTPS_PORT`             | `443`                           | Host port Caddy listens on for HTTPS.                                                                                                 |
| `KASAMA_PAGES_SITE`      | `:8790`                         | What Caddy serves Pages on: a domain of its own (`pages.example.com`, automatic HTTPS) or a port.                                     |
| `KASAMA_PAGES_URL`       | `http://localhost:8790`         | The public address of Pages, used in links to bots' pages. Set it to match `KASAMA_PAGES_SITE`.                                        |
| `PAGES_PORT`             | `8790`                          | Host port Caddy publishes for Pages.                                                                                                  |
| `CORS_ORIGINS`           | (empty)                         | Extra comma-separated web origins allowed to call the API from a browser. The public address is always allowed.                       |
| `RATE_LIMIT_PER_MINUTE`  | `120`                           | Requests per minute on the API and webhooks, per signed-in user or else per IP address. Cloud Connect endpoints get ten times as much. |
| `UPDATE_CHECK_URL`       | (empty: no update checks)       | Where the admin console checks for new releases, in the shape of GitHub's latest-release API.                                         |
| `KASAMA_VERSION`         | `local`                         | The tag of the Kasama images Compose builds and runs.                                                                                 |

**Pages on their own domain.** Bots' web pages are served from a separate origin so a page's
scripts never share an origin with Kasama. On a public server, give them their own name:

```sh
KASAMA_PAGES_SITE=pages.kasama.example.com
KASAMA_PAGES_URL=https://pages.kasama.example.com
```

Point the name's DNS at the server; Caddy gets its certificate automatically.

**Change the address after installing.** Re-running the installer doesn't change the address. Edit
these together, then run `kasama selfhost up`:

```sh
KASAMA_SITE=kasama.example.com
KASAMA_PUBLIC_URL=https://kasama.example.com
TURN_PUBLIC_HOST=kasama.example.com
SIGNUP_HOOK_URI=https://kasama.example.com/hooks/auth/before-user-created
```

### Behind another proxy

If a load balancer or another reverse proxy terminates TLS:

1. Set `KASAMA_SITE=:80` so Caddy serves plain HTTP.
2. Keep `KASAMA_PUBLIC_URL` on the public `https://` address.
3. Route your proxy to Caddy's HTTP port (`HTTP_PORT`), including WebSocket upgrades.
4. Keep port 3478 (UDP and TCP) reachable directly for live view: an HTTP proxy can't carry TURN.

## Generated secrets

The installer generates these on the first run. Don't edit them on a running server unless the
table says it's safe: several are baked into the database or into each other.

| Name                     | What it is                                                                     | Safe to change?                                                        |
| ------------------------ | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| `POSTGRES_PASSWORD`      | Password for Postgres and the Supabase service roles                           | No. Postgres keeps the password it was first started with.              |
| `WORKER_DB_PASSWORD`     | Password for `kasama_worker`, the worker's least-privilege database role       | Yes. The `migrate` service sets it again at every start.                |
| `JWT_SECRET`             | Signs Supabase tokens                                                          | No. `ANON_KEY` and `SERVICE_ROLE_KEY` are signed with it.               |
| `ANON_KEY`               | Supabase anon key (a JWT)                                                      | No                                                                     |
| `SERVICE_ROLE_KEY`       | Supabase service role key (a JWT)                                              | No                                                                     |
| `SECRET_KEY_BASE`        | Supabase Realtime's secret                                                     | No                                                                     |
| `REALTIME_ENC_KEY`       | Supabase Realtime's encryption key                                             | No                                                                     |
| `SAML_PRIVATE_KEY`       | Supabase Auth's SAML signing key (RSA, PKCS#1, base64 DER)                     | No                                                                     |
| `SUPERVISOR_TOKEN`       | The API and worker's token for the supervisor (16+ characters)                 | Yes, with a full `kasama selfhost up`                                   |
| `COMPUTER_TOKEN_SECRET`  | Derives each computer's own tokens                                             | No. Existing computers would stop answering.                            |
| `EGRESS_CONTROL_TOKEN`   | The supervisor's token for the egress proxy's control API                      | Yes, with a full `kasama selfhost up`                                   |
| `INTERNAL_TOKEN`         | Shared secret for the API's internal endpoints (32+ characters)                | Yes, with a full `kasama selfhost up`                                   |
| `TURN_SECRET`            | coturn's shared secret for short-lived live view credentials (16+ characters)   | Yes, with a full `kasama selfhost up`                                   |
| `METRICS_TOKEN`          | Bearer token for `/metrics` (16+ characters)                                   | Yes. Prometheus picks it up when it restarts.                           |
| `GRAFANA_ADMIN_PASSWORD` | Grafana's `admin` password (monitoring profile)                                | Only before Grafana's first start; afterwards change it in Grafana.     |

## Database and auth

Compose wires these for the API and worker from the generated secrets. Set them yourself only on
Helm, a platform like Render, or a custom setup.

| Name                        | Default                       | What it does                                                                                                   |
| --------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `MODE`                      | `api`                         | `api` or `worker`. The API and worker are the same image.                                                     |
| `PORT`                      | `8787`                        | The API's HTTP port.                                                                                          |
| `NODE_ENV`                  | `development`                 | Set `production` in production (Compose does).                                                                |
| `DATABASE_URL`              | Required                      | Postgres URL with full access, for the API.                                                                    |
| `WORKER_DATABASE_URL`       | Falls back to `DATABASE_URL`  | The worker's least-privilege URL (`kasama_worker`). Compose builds it from `WORKER_DB_PASSWORD`.               |
| `SUPABASE_URL`              | Required                      | Supabase's public address. Compose uses `KASAMA_PUBLIC_URL`, since Caddy routes `/auth/v1` and friends.        |
| `SUPABASE_ANON_KEY`         | Required                      | Supabase anon key. The apps get it from the server.                                                            |
| `SUPABASE_JWT_SECRET`       | (empty: verify with JWKS)     | Supabase's HS256 secret. When unset, tokens are checked against the project's JWKS.                           |
| `SUPABASE_SERVICE_ROLE_KEY` | (empty)                       | Needed for SAML SSO administration.                                                                            |
| `PUBLIC_APP_URL`            | `http://localhost:3000`       | The app's public address. Always allowed by CORS.                                                              |
| `PUBLIC_API_URL`            | The request's origin          | The API's public address, used in OAuth redirects, phone call webhooks and live view.                          |
| `PAGES_URL`                 | `http://localhost:8790`       | Public address of Pages. Compose sets it from `KASAMA_PAGES_URL`.                                              |
| `PAGES_PORT`                | (unset: Pages not served)     | Port the API process serves Pages on. Compose uses `8790` inside the stack.                                    |
| `API_INTERNAL_URL`          | `http://127.0.0.1:$PORT`      | How the worker reaches the API's internal endpoints.                                                           |
| `INTERNAL_TOKEN`            | Derived from `DATABASE_URL`   | Shared secret for internal endpoints. Always set a random value; the server warns in production without one.  |
| `SUPERVISOR_URL`            | (unset: no computers)         | The sandbox supervisor's address. Compose uses `http://kasama-supervisor:8788`.                               |
| `SUPERVISOR_TOKEN`          | (unset)                       | Token for the supervisor.                                                                                      |

## Email

Supabase Auth sends sign-in links, confirmations and password resets through SMTP. Kasama itself
sends invites through Resend.

| Name                | Default                        | What it does                                                                                          |
| ------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `SMTP_HOST`         | (empty: Auth sends no email)   | Your SMTP server.                                                                                     |
| `SMTP_PORT`         | `587`                          | SMTP port.                                                                                            |
| `SMTP_USER`         | (empty)                        | SMTP user name.                                                                                       |
| `SMTP_PASS`         | (empty)                        | SMTP password.                                                                                        |
| `SMTP_ADMIN_EMAIL`  | (empty)                        | The address Auth emails come from.                                                                    |
| `EMAIL_AUTOCONFIRM` | `true`                         | Confirm new accounts without an email. Set `false` once SMTP works.                                   |
| `RESEND_API_KEY`    | (empty)                        | Resend key for invite emails. Without it, an invite returns a code for the inviter to share.          |
| `EMAIL_FROM`        | `Kasama <no-reply@localhost>`  | Sender for Kasama's own emails.                                                                       |

To turn on email confirmation and sign-in links:

```sh
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=kasama@example.com
SMTP_PASS=your-smtp-password
SMTP_ADMIN_EMAIL=kasama@example.com
EMAIL_AUTOCONFIRM=false
```

## Sign-ups and allowlists

| Name                     | Default                          | What it does                                                                                                                             |
| ------------------------ | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `INSTANCE_ADMIN_EMAILS`  | (empty: the first account)       | Comma-separated emails of instance owners, who get the admin console.                                                                    |
| `DISABLE_SIGNUP`         | `false`                          | `true` turns off new sign-ups in Supabase Auth.                                                                                          |
| `SIGNUP_ALLOWED_EMAILS`  | (empty: anyone)                  | Only these emails or domains can sign up, comma-separated: `ana@example.com,@example.org` (`example.org` also works for a domain).       |
| `SIGNUP_HOOK_ENABLED`    | `false`                          | `true` makes Supabase Auth call Kasama's sign-up hook. Needed for the allowlist.                                                         |
| `AUTH_HOOK_SECRET`       | (empty)                          | The hook's signing secret, `v1,whsec_<base64>`. Shared by Auth and the API.                                                              |
| `SIGNUP_HOOK_URI`        | Set by the installer             | Where Auth calls the hook: `https://<domain>/hooks/auth/before-user-created`. Empty for `--local`.                                       |
| `ADDITIONAL_REDIRECT_URLS` | `kasama://app/login-callback`  | Redirect URLs Supabase Auth accepts after sign-in, comma-separated. Keep the default for the apps.                                       |
| `SAML_ENABLED`           | `true`                           | SAML SSO in Supabase Auth. Workspaces register their identity provider through the API (needs an enterprise license).                    |
| `ABUSE_CONTROLS`         | `auto` (off when self-hosted)    | `auto`, `on` or `off`. Sign-up proofs, verified email before computers start, and suspension on egress abuse. Meant for Kasama Cloud.    |
| `EGRESS_ABUSE`           | `off`                            | `on` makes the egress proxy refuse mail and crypto-mining traffic from computers and report it.                                          |

To limit sign-ups to your team (needs a `--domain` install, because Supabase Auth only calls https
hooks):

1. Generate a secret:

   ```sh
   echo "v1,whsec_$(openssl rand -base64 32)"
   ```

2. Add to `infra/compose/.env`:

   ```sh
   SIGNUP_ALLOWED_EMAILS=@example.com,ana@example.org
   SIGNUP_HOOK_ENABLED=true
   AUTH_HOOK_SECRET=v1,whsec_...
   ```

3. Run `kasama selfhost up`.

The allowlist applies to every sign-in method, Google included. Others see "limited to approved
email addresses". An allowlist without a hook secret refuses every sign-up rather than allowing
everyone.

::: warning
`SIGNUP_HOOK_URI` must be empty or an `https://` address. A plain `http://` address stops Supabase
Auth from starting, even with the hook turned off.
:::

## Models and AI Gateway

People add their own model keys in the app (Settings → Model keys) or with
`kasama credential add`. Any OpenAI-compatible endpoint works, including a local Ollama. These
settings change server-wide defaults.

| Name                        | Default            | What it does                                                                                                                     |
| --------------------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| `DEFAULT_MODEL_OPENROUTER`  | `meta/muse-ember`  | Default model for new bots on OpenRouter.                                                                                        |
| `DEFAULT_MODEL_OPENAI`      | `gpt-6-luna`       | Default model for new bots on OpenAI.                                                                                            |
| `DEFAULT_REASONING_EFFORT`  | `medium`           | `none`, `low`, `medium`, `high`, `xhigh` or `max`.                                                                               |
| `LAZY_TOOLS_THRESHOLD`      | `30`               | Bots with more tools than this load the rest on demand. `0` turns it off.                                                       |
| `CHATGPT_SIGN_IN`           | `auto` (on)        | `auto`, `on` or `off`. Lets people use a ChatGPT Go, Plus or Pro plan instead of an API key. Each plan serves only its owner.    |
| `RUN_CONCURRENCY`           | `20`               | How many runs one worker processes at once. See [Scaling](/self-hosting/operations#scaling).                                    |
| `AI_GATEWAY_URL`            | (empty)            | Send model calls through Cloudflare AI Gateway: `https://gateway.ai.cloudflare.com/v1/<account>/<gateway>`.                     |
| `AI_GATEWAY_TOKEN`          | (empty)            | Token for an authenticated gateway, sent as `cf-aig-authorization`.                                                              |

With `AI_GATEWAY_URL` set, calls for OpenAI, Anthropic, Google, xAI and OpenRouter keys go through
the gateway, for caching, logs and rate limits. A credential with its own base URL keeps it.

**Local models.** To use Ollama running on the server, allow the server to reach it with
[`OUTBOUND_ALLOW_CIDRS`](#network-and-egress), then add it as an OpenAI-compatible credential with
the address the worker container can reach. On Docker Desktop that's `host.docker.internal`:

```sh
kasama credential add --provider openai_compatible --base-url http://host.docker.internal:11434/v1
```

On Linux, use the host's LAN address instead (for example `http://192.168.1.20:11434/v1`).

## Object storage

Computers' home folders are archived to object storage when they sleep, and checkpoints are kept
there too. By default the supervisor stores them on the `objects` Docker volume, which needs nothing
extra on one host.

For S3-compatible storage (SeaweedFS from the `s3` profile, Cloudflare R2, AWS S3 and others), the
supervisor reads these settings:

| Name                    | Default                | What it does                                                         |
| ----------------------- | ---------------------- | -------------------------------------------------------------------- |
| `OBJECT_STORE`          | (filesystem)           | `s3` to use S3-compatible storage.                                   |
| `OBJECT_STORE_DIR`      | `/data/objects`        | Folder for the filesystem store.                                     |
| `S3_BUCKET`             | Required with `s3`     | Bucket name.                                                         |
| `S3_ENDPOINT`           | (AWS)                  | Endpoint, for example `http://kasama-s3:8333` or `https://<account>.r2.cloudflarestorage.com`. |
| `S3_REGION`             | (empty)                | Region, for example `auto` for R2.                                   |
| `S3_ACCESS_KEY_ID`      | (empty)                | Access key. The `s3` profile also creates SeaweedFS's user with it.  |
| `S3_SECRET_ACCESS_KEY`  | (empty)                | Secret key.                                                          |
| `S3_PREFIX`             | (empty)                | Key prefix inside the bucket.                                        |
| `S3_CREATE_BUCKET`      | (off)                  | `true` creates the bucket at start.                                  |

::: warning The bundled compose file doesn't pass these to the supervisor
Only `S3_ACCESS_KEY_ID` and `S3_SECRET_ACCESS_KEY` reach the `s3` service. To switch the supervisor
to S3, add the settings to the `supervisor` service's `environment:` in
`infra/compose/docker-compose.yml`, as shown in [Advanced settings](#advanced-settings). Switching
stores doesn't move existing archives, so do it before computers have slept, or copy the
`objects` volume's contents to the bucket yourself.
:::

With SeaweedFS on the same host:

```sh
# infra/compose/.env
S3_ACCESS_KEY_ID=kasama
S3_SECRET_ACCESS_KEY=a-long-random-secret
```

```yaml
# infra/compose/docker-compose.yml, under services.supervisor.environment
OBJECT_STORE: s3
S3_ENDPOINT: http://kasama-s3:8333
S3_BUCKET: kasama
S3_CREATE_BUCKET: "true"
S3_ACCESS_KEY_ID: ${S3_ACCESS_KEY_ID:-}
S3_SECRET_ACCESS_KEY: ${S3_SECRET_ACCESS_KEY:-}
```

Then start it with the profile:

```sh
docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env --profile s3 up -d
```

`kasama selfhost backup` archives the `objects` volume only. With S3, back up the bucket with your
storage provider's tools.

## Computers and sandbox

These go to the supervisor. Hosted providers and their settings are on
[Computer providers](/self-hosting/computers).

| Name                 | Default                 | What it does                                                                                                         |
| -------------------- | ----------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `COMPUTER_MEMORY_MB` | `2048`                  | Memory for each new computer, in MB. Swap is capped at the same amount.                                              |
| `WARM_POOL_SIZE`     | `0` (off)               | How many started headless computers to keep waiting, so a new computer starts at once. Docker provider only.         |
| `SANDBOX_RUNTIME`    | Set by the installer    | The Docker runtime for computers: `runsc` for gVisor, or empty for Docker's default.                                 |

## Network and egress

| Name                    | Default           | What it does                                                                                                                                   |
| ----------------------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `OUTBOUND_ALLOW_CIDRS`  | (empty)           | Private networks the API and worker may call, comma-separated CIDRs, for example `192.168.1.0/24`. Everything private is blocked otherwise.     |
| `TURN_PUBLIC_HOST`      | Set by the installer | The host name viewers use to reach the TURN relay. The domain, or `localhost` for `--local`.                                                 |

`OUTBOUND_ALLOW_CIDRS` covers calls the server makes for bots and people: model endpoints such as
Ollama, password managers such as Vaultwarden, connections, MCP servers and memory backends. It
doesn't change what computers can reach. The egress proxy always blocks private, loopback,
link-local (cloud metadata), CGNAT, multicast and reserved addresses for computers.

## Voice and phone calls

Phone calls through a workspace's own Twilio account need a public `https://` address, because
Twilio calls back to `PUBLIC_API_URL` (Compose sets it to `KASAMA_PUBLIC_URL`). See
[Voice](/guide/voice).

To ring iPhones for calls through PushKit, the worker needs an APNs token key for the app's bundle:

| Name            | Default   | What it does                                       |
| --------------- | --------- | -------------------------------------------------- |
| `APNS_KEY_P8`   | (empty)   | The APNs token key: the `.p8` file's contents.     |
| `APNS_KEY_ID`   | (empty)   | The key's id.                                      |
| `APNS_TEAM_ID`  | (empty)   | Your Apple team id.                                |

## Push notifications

| Name                   | Default   | What it does                                                                                                      |
| ---------------------- | --------- | ----------------------------------------------------------------------------------------------------------------- |
| `FCM_SERVICE_ACCOUNT`  | (empty)   | A Firebase service account JSON, on one line, for the Firebase project the apps are built with. Unset: no push. |

Push only reaches apps built with the same Firebase project as the service account. Without push,
the in-app inbox still shows every notification.

## Integrations

| Name                          | Default   | What it does                                                                                                                                                   |
| ----------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GOOGLE_OAUTH_CLIENT_ID`      | (empty)   | Your Google OAuth client, for Gmail, Calendar and Drive connections.                                                                                            |
| `GOOGLE_OAUTH_CLIENT_SECRET`  | (empty)   | Its secret.                                                                                                                                                     |
| `MCP_OAUTH_CLIENTS`           | (empty)   | OAuth clients for apps that don't support automatic registration, as JSON by app id: `{"slack":{"client_id":"...","client_secret":"..."}}`.                     |
| `COMPOSIO_API_KEY`            | (empty)   | A server-wide Composio key that enables Composio's managed sign-in for inbox apps such as Gmail.                                                                |
| `UNSPLASH_ACCESS_KEY`         | (empty)   | Wallpaper photo search in Appearance. Without it, the app offers its own patterns and photos.                                                                   |

Register `https://kasama.example.com/oauth/callback` as the redirect URI in each OAuth app. See
[Connections](/guide/connections).

## Billing

Billing is for Kasama Cloud. The bundled compose file sets `BILLING_ENABLED=false` for the API and
worker, so there's no paywall and no usage limit, and none of the payment settings apply. Settings
that switch on with billing (`ABUSE_CONTROLS=auto`, `HEALTH_REQUIRES_ENCRYPTION=auto`) stay off.

## Cloud Connect

Cloud Connect lets your server run computers on Kasama Cloud and use its model credits, billed to a
Kasama Cloud workspace. See [Cloud Connect](/guide/cloud-connect).

| Name                | Default   | What it does                                                                 |
| ------------------- | --------- | ---------------------------------------------------------------------------- |
| `KASAMA_CLOUD_URL`  | (empty)   | Kasama Cloud's address.                                                      |
| `KASAMA_CLOUD_KEY`  | (empty)   | A Cloud Connect key (`kcc_...`) created by a Kasama Cloud workspace admin.   |

With both set, the `kasama-cloud` computer provider is available. For model credits, a workspace
adds an OpenRouter credential whose base URL is `<cloud>/connect/v1/models` and whose key is the
Cloud Connect key.

## Telemetry and observability

| Name                           | Default                                   | What it does                                                                                                         |
| ------------------------------ | ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `TELEMETRY`                    | `off`                                     | `on` sends anonymous counts once a week (see below).                                                                 |
| `TELEMETRY_URL`                | `https://telemetry.kasama.dev/v1/ping`    | Where telemetry goes.                                                                                                |
| `ERROR_REPORTING`              | `auto`                                    | `auto` (Sentry if `SENTRY_DSN` is set, else PostHog if `POSTHOG_API_KEY` is set, else nothing), `sentry`, `posthog` or `none`. |
| `SENTRY_DSN`                   | (empty)                                   | A Sentry-protocol DSN: sentry.io, self-hosted Sentry or GlitchTip.                                                   |
| `POSTHOG_API_KEY`              | (empty)                                   | PostHog project key for error reports.                                                                               |
| `OTEL_EXPORTER_OTLP_ENDPOINT`  | (empty)                                   | Send traces to an OpenTelemetry collector.                                                                           |
| `LANGFUSE_BASE_URL`            | (empty)                                   | Langfuse address. With all three Langfuse settings, runs send LLM traces (workspaces can opt out).                   |
| `LANGFUSE_PUBLIC_KEY`          | (empty)                                   | Langfuse public key.                                                                                                 |
| `LANGFUSE_SECRET_KEY`          | (empty)                                   | Langfuse secret key.                                                                                                 |
| `METRICS_TOKEN`                | Generated                                 | Bearer token for Prometheus metrics at `/metrics`. Without it, `/metrics` is off in production.                     |

**Telemetry** is off unless you turn it on. With `TELEMETRY=on`, the worker sends once a week a
random instance id, the Kasama version and two numbers: bots and users active in the last 7 days.
Nothing else: no names, emails, content, keys or addresses.

**Error reports** are scrubbed before they leave: request bodies, headers, cookies and users are
dropped, and secret-looking values and emails are redacted.

## Secret store

Bots' named secrets live in Supabase Vault in your database by default. A workspace admin can keep
them in Infisical instead, under workspace settings → **Where secrets are kept**, with a machine
identity's client id and secret. There's no server setting for it. Kasama's other credentials
(model keys, connection tokens) stay in Vault either way.

## Encryption keys

Encryption at rest seals message content, run events, memories, summaries, ticket text, pages and
knowledge in Postgres. It's off by default and turned on per workspace by its owners, once the
server has a key.

| Name                               | Default         | What it does                                                                                                    |
| ---------------------------------- | --------------- | --------------------------------------------------------------------------------------------------------------- |
| `CONTENT_ENCRYPTION_KEY`           | (empty)         | The server key that wraps workspace keys: 32 bytes, base64. Generate with `openssl rand -base64 32`.            |
| `CONTENT_ENCRYPTION_KEY_PREVIOUS`  | (empty)         | Older keys during a rotation, comma-separated.                                                                  |
| `CONTENT_KMS_KEY_ID`               | (empty)         | Use AWS KMS instead: the key's id or ARN.                                                                       |
| `CONTENT_KMS_REGION`               | (empty)         | The KMS key's region.                                                                                           |
| `AWS_ACCESS_KEY_ID`                | (empty)         | AWS credentials for KMS.                                                                                        |
| `AWS_SECRET_ACCESS_KEY`            | (empty)         | AWS credentials for KMS.                                                                                        |
| `AWS_SESSION_TOKEN`                | (empty)         | Optional session token for temporary credentials.                                                               |
| `HEALTH_REQUIRES_ENCRYPTION`       | `auto` (off)    | `on` stores health data only for workspaces with encryption at rest on.                                         |

::: danger Back up the key
Without the key, encrypted content can't be read. Keep a copy somewhere other than the server.
:::

**Rotate the server key:**

1. Generate a new key with `openssl rand -base64 32`.
2. Move the current value to `CONTENT_ENCRYPTION_KEY_PREVIOUS` and put the new key in
   `CONTENT_ENCRYPTION_KEY`.
3. Run `kasama selfhost up`.
4. Wait at least an hour. The worker's hourly maintenance rewraps every workspace key that still
   uses the old server key. Owners can also rotate their workspace right away under workspace
   settings.
5. Remove `CONTENT_ENCRYPTION_KEY_PREVIOUS` and run `kasama selfhost up` again.

Rotation rewraps workspace keys; it doesn't rewrite rows. Search can't look inside sealed text:
memory and knowledge search use embeddings only, which stay unencrypted.

## Audit forwarding and enterprise features

| Name                 | Default   | What it does                                                                                     |
| -------------------- | --------- | ------------------------------------------------------------------------------------------------ |
| `KASAMA_LICENSE_KEY` | (empty)   | A Kasama Enterprise license key. Unlocks SAML SSO, audit log export and audit-log forwarding.    |

Everything outside the `ee/` folder works without a license. See
[Audit-log forwarding](/self-hosting/operations#audit-log-forwarding).

## Privacy and retention

| Name                           | Default   | What it does                                                                                                 |
| ------------------------------ | --------- | ------------------------------------------------------------------------------------------------------------ |
| `ACCOUNT_DELETION_GRACE_DAYS`  | `7`       | Days between an account deletion request and the purge (0 to 30).                                            |

Deleted accounts are purged with the workspaces they solely own and their computer snapshots. Run
events are kept for each workspace's retention setting (default 180 days). See
[Privacy](/guide/privacy).

## Advanced settings

The server and supervisor read these, but the bundled compose file doesn't pass them through. On
Helm, set them with `extraEnv`; on a platform, as environment variables. With Compose, add them to
the service's `environment:` in `infra/compose/docker-compose.yml`. The API and worker share the
`x-kasama` block at the top:

```yaml
x-kasama: &kasama
  # ...
  environment: &kasama-env
    # ...
    LOG_LEVEL: ${LOG_LEVEL:-info}
```

Then set the value in `.env` and run `kasama selfhost up`. Keep your edit when you upgrade: `git
pull` refuses to overwrite a changed file, so commit it on a local branch or re-apply it.

**API and worker:**

| Name                       | Default             | What it does                                                                                  |
| -------------------------- | ------------------- | --------------------------------------------------------------------------------------------- |
| `LOG_LEVEL`                | `info`              | `debug`, `info`, `warn` or `error`.                                                           |
| `LOCAL_COMPUTERS`          | `true`              | People's own machines as bot computers through the desktop companion.                         |
| `EMBEDDINGS`               | `auto`              | `auto` embeds memories with the workspace's OpenAI key when it has one; `none` uses full-text search only. |
| `AI_GATEWAY_PROVIDERS`     | (all)               | Limit AI Gateway to some providers, comma-separated: `openai`, `anthropic`, `google`, `xai`, `openrouter`. |
| `POSTHOG_HOST`             | (PostHog's default) | PostHog address, for another region or a self-hosted PostHog.                                 |
| `TRACE_URL_TEMPLATE`       | (empty)             | A trace viewer link containing `{trace_id}`, shown on run timelines.                          |
| `TURN_PORT`                | `3478`              | The TURN port given to viewers.                                                               |
| `TURN_TLS_PORT`            | (empty)             | Also offer a `turns:` address on this port. The bundled relay doesn't serve TLS.              |
| `CONTENT_KMS_ENDPOINT`     | (AWS's)             | A custom KMS endpoint, for example a VPC endpoint.                                            |
| `APNS_VOIP_TOPIC`          | `com.kasama.app.voip` | The app's VoIP push topic.                                                                  |

**Supervisor:**

| Name                   | Default         | What it does                                                                              |
| ---------------------- | --------------- | ----------------------------------------------------------------------------------------- |
| `COMPUTER_CPUS`        | `1`             | CPUs for each new computer.                                                               |
| `DEFAULT_PROVIDER`     | `docker`        | The provider for computers that ask for the default. See [Computer providers](/self-hosting/computers). |
| `STREAM_IDLE_STOP_MS`  | `60000`         | How long the live view streamer keeps running after the last viewer leaves.               |
| `OBJECT_STORE`, `S3_*` | Filesystem      | See [Object storage](#object-storage).                                                    |
| Provider settings      | (none)          | See [Computer providers](/self-hosting/computers).                                        |

**Egress proxy:**

| Name                    | Default   | What it does                                                                     |
| ----------------------- | --------- | -------------------------------------------------------------------------------- |
| `EGRESS_BLOCKED_CIDRS`  | (empty)   | More address ranges to block for computers, on top of the built-in private ranges. |

## Related

- [Self-hosting](/self-hosting/)
- [Operations](/self-hosting/operations)
- [Computer providers](/self-hosting/computers)
- [Troubleshooting](/self-hosting/troubleshooting)
- [Privacy](/guide/privacy)
- [Cloud Connect](/guide/cloud-connect)
