# Coolify

Coolify runs Docker Compose stacks and lets them use the Docker socket, so it can host the full
stack, bot computers included.

[`casama.yaml`](casama.yaml) is a Coolify service template: one compose file, published images
only, with Coolify generating the secrets. It has not been run end to end on a Coolify server yet.
It parses (`deploy/check-templates.sh`), and the rest of this page says what is still unchecked.

## Install

Casama is not in Coolify's service list, so paste the template yourself:

1. In Coolify, open your project and choose **New resource > Docker Compose Empty**.
2. Paste the contents of `casama.yaml` and save.
3. Open the `caddy` service and set its domain, for example `https://casama.example.com`. Open
   the `api` service and set a second domain for bots' web pages, for example
   `https://pages.casama.example.com`. Both need DNS records that point at the server.
4. Open port 3478 (UDP and TCP) in the server's firewall. Live view of desktop computers uses it.
5. Deploy. The first start downloads about 10 GB of images.
6. Point the Casama app or CLI at the `caddy` domain and create an account. The first account
   is the instance owner.

Then copy the generated values from **Environment Variables** somewhere safe. They hold every key
for this installation. `SERVICE_REALBASE64_CONTENTKEY` matters most: encrypted data cannot be read
without it.

## What Coolify generates

`install.sh` writes these to `infra/compose/.env`. Here Coolify makes them on the first deploy.

| `install.sh` name | Coolify variable | Notes |
| --- | --- | --- |
| `CASAMA_PUBLIC_URL` | `SERVICE_URL_CADDY` | The domain of the `caddy` service |
| `CASAMA_PAGES_URL` | `SERVICE_URL_API` | The domain of the `api` service, port 8790 |
| `TURN_PUBLIC_HOST` | `SERVICE_FQDN_CADDY` | Set `TURN_PUBLIC_HOST` to override |
| `POSTGRES_PASSWORD` | `SERVICE_PASSWORD_POSTGRES` | |
| `WORKER_DB_PASSWORD` | `SERVICE_PASSWORD_WORKERDB` | |
| `JWT_SECRET` | `SERVICE_PASSWORD_JWT` | |
| `ANON_KEY` | `SERVICE_SUPABASEANON_KEY` | A JWT that Coolify signs with `SERVICE_PASSWORD_JWT` |
| `SERVICE_ROLE_KEY` | `SERVICE_SUPABASESERVICE_KEY` | The same, with the `service_role` role |
| `SECRET_KEY_BASE` | `SERVICE_PASSWORD_64_REALTIME` | |
| `REALTIME_ENC_KEY` | `SERVICE_USER_REALTIMEENC` | Must be 16 characters. This is Coolify's only 16-character generator. |
| `SUPERVISOR_TOKEN` | `SERVICE_PASSWORD_SUPERVISOR` | |
| `COMPUTER_TOKEN_SECRET` | `SERVICE_PASSWORD_64_COMPUTERTOKEN` | |
| `EGRESS_CONTROL_TOKEN` | `SERVICE_PASSWORD_EGRESS` | |
| `INTERNAL_TOKEN` | `SERVICE_PASSWORD_64_INTERNAL` | |
| `TURN_SECRET` | `SERVICE_PASSWORD_TURN` | |
| `METRICS_TOKEN` | `SERVICE_PASSWORD_METRICS` | |
| `AUTH_HOOK_SECRET` | `v1,whsec_` + `SERVICE_REALBASE64_AUTHHOOK` | |
| `CONTENT_ENCRYPTION_KEY` | `SERVICE_REALBASE64_CONTENTKEY` | 32 random bytes, base64 |

`SEARXNG_SECRET` and `GRAFANA_ADMIN_PASSWORD` are not here: the template has no search or
monitoring services.

## What Coolify cannot generate

**The SAML signing key.** It is an RSA key, and Coolify has no generator for one. SAML SSO is
off in this template. To turn it on, make the key on any machine with OpenSSL 3:

```sh
openssl genrsa 2048 | openssl rsa -traditional -outform DER | openssl base64 -A
```

Set the output as `SAML_PRIVATE_KEY`, set `SAML_ENABLED=true`, and redeploy.

## Settings to check after the first deploy

- **HTTPS and the sign-up hook.** `SIGNUP_HOOK_URI` starts empty, because Supabase Auth does
  not start with an `http` hook address. With an `https` domain, set it to
  `https://<your domain>/hooks/auth/before-user-created`. Turn the hook on with
  `SIGNUP_HOOK_ENABLED=true` only if you need it.
- **Live view.** `TURN_PUBLIC_HOST` must be a name or IP that reaches the server directly on
  port 3478. If the domain goes through Cloudflare's proxy, set it to the server's IP.
- **Memory for computers.** `COMPUTER_HOST_MEMORY_GB` is 4. `install.sh` uses the machine's
  memory less 4 GB. Set it to match your server.
- **gVisor.** If `runsc` is installed on the server, set `SANDBOX_RUNTIME=runsc`.
- **Email.** New accounts sign in without a confirmation email until you set `SMTP_HOST`,
  `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` and `SMTP_ADMIN_EMAIL`, then `EMAIL_AUTOCONFIRM=false`.
- **Desktop computers.** The template pulls the headless computer image only. For desktop
  computers, run `docker pull ghcr.io/stackwares/casama/computer-desktop:latest` on the server.
- **Version.** Casama images use the `latest` tag. The git tag `selfhost` marks the commit they
  were built from. To pin a release, set `CASAMA_VERSION` to its short commit id.

Other settings from [Configuration](../../docs-site/self-hosting/configuration.md) are not in the
template. Add them to the `api` and `worker` services in the compose file when you need them.

## How it differs from `install.sh`

- Coolify's proxy ends TLS. `caddy` only routes paths to the API and to Supabase, on port 80.
- The config files (`kong.yml`, the Caddyfile, `migrate.sh`, the database setup files) are
  inline in the template. They mirror `infra/compose/selfhost/`. Change both together.
- The `migrations` service copies the database migrations out of the server image, so they
  always match the API.
- Coolify names containers `<service>-<resource id>`. The supervisor's start script reads that
  id from `COOLIFY_RESOURCE_UUID` to find the egress proxy and the TURN relay by name.
- Auth reads Casama's email templates from the repository at the `selfhost` tag.
- No profiles: no monitoring, search, backups, web app, PDF export or Casama Link connector.

## Not checked on a real server

- That Coolify's parser accepts the file and creates every variable above.
- That `SERVICE_REALBASE64_*` exists in your Coolify version. On a version without it, the two
  values stay empty: encryption at rest is then unavailable and the sign-up hook has no secret.
- That each container gets `COOLIFY_RESOURCE_UUID`. Without it the supervisor stops with a
  clear message.
- That one stack can hold two generated domains (`caddy` and `api`).

## The older way

You can still run the repository's own compose file in Coolify:

1. On the Coolify server, run `./install.sh --no-start --domain your.domain` once from a checkout to
   generate `infra/compose/.env` (or copy its keys by hand).
2. In Coolify: New resource → Docker Compose → this repository, compose file
   `infra/compose/docker-compose.yml`, and paste the variables from `infra/compose/.env`.
3. Let Coolify's proxy route your domain to the `caddy` service on port 80 and set `CASAMA_SITE=:80`
   (Coolify terminates TLS), or remove `caddy` and route `/v1`, `/hooks`, `/link` to `api:8787` and
   `/auth/v1`, `/rest/v1`, `/realtime/v1` to `kong:8000`.
4. Build the computer image once on the server:
   `docker compose -f infra/compose/docker-compose.yml --profile images build computer-headless`.

## Sending it to Coolify

The template would go to `templates/compose/casama.yaml` in
[coollabsio/coolify](https://github.com/coollabsio/coolify), with a logo at `svgs/casama.svg`.
Two things block that today. Coolify asks for 1,000 GitHub stars on the service's repository, and
its docs say outside contributions are paused. Coolify also asks for a fixed image tag, not
`latest`, so replace `${CASAMA_VERSION:-latest}` with a release's short commit id first.
