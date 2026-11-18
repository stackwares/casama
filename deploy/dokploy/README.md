# Dokploy

Dokploy runs Docker Compose stacks and lets them use the Docker socket, so it can host the full
stack, bot computers included.

This folder is a Dokploy template in the shape of
[Dokploy/templates](https://github.com/Dokploy/templates):

| File | What it is |
| --- | --- |
| [`docker-compose.yml`](docker-compose.yml) | The stack: published images only |
| [`template.toml`](template.toml) | Generated secrets, the two domains, and the config files |
| [`meta.json`](meta.json), `casama.png` | The template's card |

It has not been run end to end on a Dokploy server yet. The compose file parses
(`deploy/check-templates.sh`), and Dokploy's own template code was run over `template.toml` to
check the generated values. The rest of this page says what is still unchecked.

## Install

Casama is not in Dokploy's template list, so import it yourself:

1. Make the import text. Dokploy takes one base64 string that holds both files:

   ```sh
   cd deploy/dokploy
   node -e 'const fs=require("fs");console.log(Buffer.from(JSON.stringify({compose:fs.readFileSync("docker-compose.yml","utf8"),config:fs.readFileSync("template.toml","utf8")})).toString("base64"))'
   ```

2. In Dokploy, create a **Compose** service. Open **Advanced > Import**, paste the text, and
   import. Dokploy shows the compose file, the variables, the mounts and the domains.
3. Open port 3478 (UDP and TCP) in the server's firewall. Live view of desktop computers uses it.
4. Deploy. The first start downloads about 10 GB of images.
5. Point the Casama app or CLI at the first domain and create an account. The first account is
   the instance owner.

Then copy the **Environment** tab somewhere safe. It holds every key for this installation.
`CONTENT_ENCRYPTION_KEY` matters most: encrypted data cannot be read without it.

## What Dokploy generates

Every secret `install.sh` generates, under the same names, so
[Configuration](../../docs-site/self-hosting/configuration.md) applies as written.

| Name | Dokploy helper |
| --- | --- |
| `POSTGRES_PASSWORD`, `WORKER_DB_PASSWORD` | `${password:32}` |
| `JWT_SECRET`, `SECRET_KEY_BASE`, `COMPUTER_TOKEN_SECRET` | `${password:64}` |
| `ANON_KEY`, `SERVICE_ROLE_KEY` | `${jwt:jwt_secret:<payload>}`: a JWT signed with `JWT_SECRET`, with the role, `iss: supabase`, `iat` and `exp` |
| `REALTIME_ENC_KEY` | `${hash:16}`. It must be 16 characters. |
| `SUPERVISOR_TOKEN`, `EGRESS_CONTROL_TOKEN`, `INTERNAL_TOKEN`, `TURN_SECRET`, `METRICS_TOKEN` | `${password:48}` |
| `AUTH_HOOK_SECRET` | `v1,whsec_${base64:32}` |
| `CONTENT_ENCRYPTION_KEY` | `${base64:32}`: 32 random bytes, base64 |
| `CASAMA_PUBLIC_URL`, `CASAMA_PAGES_URL`, `TURN_PUBLIC_HOST` | From two `${domain}` values |

The two Supabase keys end on 1 November 2036. `install.sh` gives them ten years too.

## What Dokploy cannot generate

**The SAML signing key.** It is an RSA key, and Dokploy has no helper for one. SAML SSO is off in
this template. To turn it on, make the key on any machine with OpenSSL 3:

```sh
openssl genrsa 2048 | openssl rsa -traditional -outform DER | openssl base64 -A
```

Set the output as `SAML_PRIVATE_KEY`, set `SAML_ENABLED=true`, and redeploy.

## Settings to check after the first deploy

- **Your own domain and HTTPS.** Dokploy starts with two `sslip.io` addresses on plain HTTP.
  When you change a domain or turn on HTTPS in the **Domains** tab, change `CASAMA_PUBLIC_URL`
  and `CASAMA_PAGES_URL` in **Environment** to match, then redeploy. The first domain goes to
  `caddy` on port 80, the second to `api` on port 8790.
- **The sign-up hook.** `SIGNUP_HOOK_URI` starts empty, because Supabase Auth does not start
  with an `http` hook address. With an `https` address, set it to
  `https://<your domain>/hooks/auth/before-user-created`.
- **Live view.** `TURN_PUBLIC_HOST` must be a name or IP that reaches the server directly on
  port 3478. If your domain goes through Cloudflare's proxy, set it to the server's IP.
- **Memory for computers.** `COMPUTER_HOST_MEMORY_GB` is 4. `install.sh` uses the machine's
  memory less 4 GB. Set it to match your server.
- **gVisor.** If `runsc` is installed on the server, set `SANDBOX_RUNTIME=runsc`.
- **Email.** New accounts sign in without a confirmation email until you set the `SMTP_*`
  values, then `EMAIL_AUTOCONFIRM=false`.
- **Desktop computers.** The template pulls the headless computer image only. For desktop
  computers, run `docker pull ghcr.io/stackwares/casama/computer-desktop:latest` on the server.
- **Version.** Casama images use the `latest` tag. The git tag `selfhost` marks the commit they
  were built from. To pin a release, set `CASAMA_VERSION` to its short commit id.

## How it differs from `install.sh`

- Dokploy's proxy serves the domains. `caddy` only routes paths to the API and to Supabase.
- The config files (`kong.yml`, the Caddyfile, `migrate.sh`, the database setup files) are
  mounts in `template.toml`. They mirror `infra/compose/selfhost/`. Change both together.
- The `migrations` service copies the database migrations out of the server image, so they
  always match the API.
- No fixed container names, as Dokploy asks. The supervisor finds the egress proxy and the
  TURN relay as `<project>-egress-1` and `<project>-turn-1`, the names Compose gives them.
- Auth reads Casama's email templates from the repository at the `selfhost` tag.
- No profiles: no monitoring, search, backups, web app, PDF export or Casama Link connector.

## Two rules of Dokploy's this template bends

- **It publishes a port.** Dokploy asks templates to use `expose`, not `ports`. TURN is not HTTP,
  so the proxy cannot carry it: the `turn` service publishes 3478 on the server.
- **It mounts the Docker socket.** The supervisor needs it to create computers. Other templates
  in Dokploy's list do the same.

## Not checked on a real server

- That Dokploy imports the template and the stack comes up.
- That Compose names the containers `<project>-<service>-1` under Dokploy. If the supervisor
  logs that it cannot find a container, set `SUPERVISOR_CONTAINER`, `EGRESS_CONTAINER` and
  `TURN_CONTAINER` in the compose file to the names `docker ps` shows.
- That Dokploy's proxy passes WebSocket traffic to `caddy` for Realtime.

## Sending it to Dokploy

Copy this folder's four files to `blueprints/casama/` in
[Dokploy/templates](https://github.com/Dokploy/templates) and open a pull request. Their rules:
test the template on your own Dokploy first (each pull request gets a preview link to import
from), and keep `meta.json` inside the template's folder.
