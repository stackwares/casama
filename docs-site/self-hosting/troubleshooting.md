# Troubleshooting

Problems you might hit running your own Casama server, each as symptom, cause and fix. Most start
with the same two commands:

```sh
casama selfhost status
casama selfhost logs migrate api worker auth
```

Instance owners can also check the health of each service under Settings → admin console.

## Install

### "Docker is not running (or this user cannot use it)"

**Cause:** The Docker daemon isn't running, or your user isn't allowed to use it.

**Fix:** Start Docker (`sudo systemctl start docker`, or open Docker Desktop). On Linux, add your
user to the `docker` group (`sudo usermod -aG docker $USER`), sign out and back in, and run
`docker info` to check.

### "Docker Compose v2 is needed"

**Cause:** Only the old `docker-compose` (v1) is installed, or no Compose at all.

**Fix:** Install the Docker Compose plugin so `docker compose version` works, then run the installer
again.

### "Couldn't pull the images"

**Cause:** No internet access, or the registry rate-limited anonymous pulls. Supabase's images come
from `public.ecr.aws`, which allows only a few anonymous pulls at a time. The installer already
pulls two at a time and retries five times.

**Fix:** Wait a few minutes and run `./install.sh` again. Images that finished downloading are
kept.

### "Warning: less than 8 GB of memory"

**Cause:** The machine has less memory than Casama needs for a few computers.

**Fix:** The install continues, but computers may fail to start. Use a bigger machine, lower
`COMPUTER_MEMORY_MB`, or run computers elsewhere (see [Computer providers](/self-hosting/computers)).

### "The API did not become ready"

**Cause:** Something in the stack failed to start within three minutes. Usual suspects: the
`migrate` service, Supabase Auth, or the API crashing on a bad setting.

**Fix:**

1. Check which services are down: `casama selfhost status`.
2. Read their logs: `casama selfhost logs migrate api auth`.
3. If `api` logs `Invalid environment: <NAME>: ...`, fix that setting in `infra/compose/.env` and run
   `casama selfhost up`.
4. If `migrate` logs `Auth/Realtime schemas did not appear`, see the next entry.

### Migrations wait, then fail with "Auth/Realtime schemas did not appear"

**Cause:** `migrate` waits up to four minutes for Supabase Auth and Realtime to create their
database schemas before it applies Casama's migrations. If Auth or Realtime keeps crashing, they
never appear.

**Fix:** Read `casama selfhost logs auth realtime` and fix what they report (the next entry covers
the most common one). Then run `casama selfhost up`; `migrate` runs again and applies only
migrations it hasn't applied yet (tracked in `public.casama_migrations`).

### Supabase Auth won't start

**Symptom:** `auth` restarts over and over; sign-in fails with a gateway error.

**Cause:** Usually one of:

- `SIGNUP_HOOK_URI` is a plain `http://` address. Supabase Auth only accepts `https://` hook URLs
  (plain http only on localhost), and refuses to start otherwise, even with the hook off.
- `SAML_PRIVATE_KEY` is in PKCS#8 format. Auth needs PKCS#1. Installers before November 2026 wrote
  PKCS#8.

**Fix:** Run `./install.sh` again: it converts the SAML key and leaves the rest of `.env` alone. Set
`SIGNUP_HOOK_URI` to empty or to `https://<your domain>/hooks/auth/before-user-created`. Then run
`casama selfhost up`.

### I re-ran the installer with `--domain`, but the address didn't change

**Cause:** When `infra/compose/.env` exists, the installer keeps it. `--domain`, `--local` and
`--http-port` only apply to the first run.

**Fix:** Edit the address settings in `.env` yourself. See
[Core and URLs](/self-hosting/configuration#core-and-urls).

### Caddy can't get a certificate

**Symptom:** The browser shows a TLS error; `casama selfhost logs caddy` shows ACME errors.

**Cause:** The domain doesn't point at the server yet, or ports 80 and 443 aren't reachable from the
internet.

**Fix:** Check the DNS record (`dig +short casama.example.com`) and your firewall, then run
`docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env restart caddy`.
Behind another proxy that terminates TLS, set `CASAMA_SITE=:80` (see
[Behind another proxy](/self-hosting/configuration#behind-another-proxy)).

## Health checks

### The root page says "Casama is running", but the app can't sign in

**Cause:** That note means Caddy is up but the web app isn't installed; it only answers the root
page. Other paths show the real status.

**Fix:** Check the API directly:

```sh
curl -i https://casama.example.com/readyz
```

`200` with `"status":"ok"` means the API and database are fine. A `503` with `"degraded"` means
the API can't reach the database: check `casama selfhost logs db api`. A `502` with "Casama isn't
ready yet" means Caddy can't reach that service.

## Sign-in and email

### Confirmation and sign-in emails never arrive

**Cause:** Supabase Auth sends email only through SMTP, and a new server has none. New accounts are
confirmed automatically (`EMAIL_AUTOCONFIRM=true`), so passwords work, but emailed sign-in links,
codes and password resets don't.

**Fix:** Set `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` and `SMTP_ADMIN_EMAIL` (see
[Email](/self-hosting/configuration#email)), then `casama selfhost up`. Check delivery problems in
`casama selfhost logs auth`.

### Email links open a page that doesn't exist

**Cause:** Older compose files built Auth's links as `<address>/verify`, but Auth is served under
`/auth/v1`. Or the links land on the API's address when you expected your web app.

**Fix:** Upgrade: the bundled compose file now sends links to `<address>/auth/v1/verify`. To land
people on your web app after they open a link, set `AUTH_SITE_URL` to its address (see
[Email](/self-hosting/configuration#email)), then `casama selfhost up`.

### Invites show a code instead of sending an email

**Cause:** Neither SMTP (`SMTP_HOST`) nor Resend (`RESEND_API_KEY`) is set, so Casama can't send email.

**Fix:** Share the code with the person, or set the SMTP settings (or `RESEND_API_KEY`) and
`EMAIL_FROM`, then restart.

### Every sign-up is refused with "limited to approved email addresses"

**Cause:** `SIGNUP_ALLOWED_EMAILS` doesn't include that email or its domain. If no one can sign up
at all, `AUTH_HOOK_SECRET` is missing or differs between Auth and the API; without a valid secret,
an allowlist refuses everyone.

**Fix:** Check the list and that `SIGNUP_HOOK_ENABLED=true` and `AUTH_HOOK_SECRET=v1,whsec_...` are
set, then `casama selfhost up`.

### Nobody has the admin console

**Cause:** The instance owner is the first account, unless `INSTANCE_ADMIN_EMAILS` is set. If it's
set, only those emails are owners.

**Fix:** Set `INSTANCE_ADMIN_EMAILS=you@example.com` and run `casama selfhost up`.

## The app can't reach the server

### "Can't connect" in the app or CLI

**Cause:** The app or CLI points at the wrong address, or the server isn't reachable from that
device. `--local` servers answer only on the machine they run on.

**Fix:**

1. In the app, tap **More options** → the **Server** chip (or **Use a different server**) and check
   the address, including `https://`.
2. In the CLI, check `casama config`, and set it with `casama config --api-url <address>`.
3. From the device, open `<address>/healthz` in a browser. It should return `{"status":"ok"}`.

### The web app on another domain gets CORS errors

**Cause:** In production, the API allows browser calls only from its public address and the origins
in `CORS_ORIGINS`.

**Fix:** Add the web app's origin, for example `CORS_ORIGINS=https://app.example.com`, then
`casama selfhost up`. The native apps and the CLI don't need this.

### Links to bots' pages point at `localhost:8790`

**Cause:** Pages are served from their own origin, and `CASAMA_PAGES_URL` defaults to
`http://localhost:8790`.

**Fix:** Give Pages their own domain with `CASAMA_PAGES_SITE` and `CASAMA_PAGES_URL` (see
[Core and URLs](/self-hosting/configuration#core-and-urls)).

### OAuth connections, hosted MCP or agent-to-agent calls return 502 or the web app

**Cause:** Caddy forwards only the paths in the `@api` matcher of
`infra/compose/selfhost/Caddyfile` to the API; everything else goes to the web app. Caddyfiles from
before November 13, 2026 left out `/oauth/*` (the redirect target for app connections), `/mcp`,
`/a2a/*` and `/links/*`. The current one still leaves out `/telephony/*`, which phone calls need
when you turn them on.

**Fix:** Upgrade (`casama selfhost upgrade`), or add the missing paths to the `@api` matcher
yourself, for example `/oauth/* /mcp /mcp/* /a2a/* /links/*`, plus `/telephony/*` if you use phone
calls. Then restart Caddy:
`docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env restart caddy`.

### Signed-out requests get "rate_limited" behind a tunnel

**Cause:** Behind a tunnel on the same machine (Cloudflare Tunnel, for example), every request
reaches Caddy from the tunnel's address, so all signed-out callers share one rate limit.

**Fix:** Set `TRUSTED_CLIENT_IP_HEADER` to the header that carries the caller's real address
(`cf-connecting-ip` for Cloudflare), then `casama selfhost up`.

## Computers

### Bots say they have no computer

**Cause:** The API or worker can't reach the supervisor, or it isn't configured. The admin console
shows "Sandbox supervisor: Not configured" or unhealthy.

**Fix:** Check `casama selfhost logs supervisor`. The supervisor refuses to start without
`SUPERVISOR_TOKEN` (16+ characters), `COMPUTER_TOKEN_SECRET` and `EGRESS_CONTROL_TOKEN`; re-run
`./install.sh` to add missing generated settings. If it logs
`DEFAULT_PROVIDER=<name> isn't configured on this supervisor`, add that provider's settings or
remove `DEFAULT_PROVIDER`.

### A computer fails to start

**Cause:** Common ones:

- The computer image is missing. The installer builds (or with `--pull`, downloads) the headless
  image; the desktop image only with `--with-desktop`.
- `SANDBOX_RUNTIME=runsc` is set but gVisor isn't installed or registered with Docker.
- The host is out of memory or disk.

**Fix:**

1. Check the images: `docker images | grep computer-`. Get the desktop one with
   `./install.sh --with-desktop`.
2. Check `docker info | grep -i runsc`. If it's missing, set `SANDBOX_RUNTIME=` (empty) and run
   `casama selfhost up`, or install gVisor.
3. Check `free -h` and `df -h`, and the supervisor's logs.

### "The computer could not be reached"

**Cause:** The API answers `503` with `computer_unavailable` when it can't reach a computer, for
example while it's stopping, restarting or waking, or when the supervisor is down. A personal
computer whose desktop app isn't connected answers `409` with `device_offline` instead.

**Fix:** Wait a moment and try again. If it keeps happening, check `casama selfhost logs supervisor`
and `docker ps --filter name=casama-c-`.

### A computer can't reach a website

**Cause:** The egress proxy blocks private, loopback, link-local, CGNAT and reserved addresses,
plus anything in `EGRESS_BLOCKED_CIDRS`. Non-HTTP traffic (SSH, for example) has no route out.

**Fix:** Check `casama selfhost logs egress`, which logs each refused connection. Services on your
LAN aren't reachable from computers by design; `OUTBOUND_ALLOW_CIDRS` only applies to the API and
worker.

### Bots can't reach Ollama or another service on my network

**Cause:** The server's outbound calls block private addresses unless you allow them. On Linux,
`host.docker.internal` doesn't resolve inside the containers by default.

**Fix:** Set `OUTBOUND_ALLOW_CIDRS` to the network (for example `192.168.1.0/24`), run
`casama selfhost up`, and use the host's LAN address in the credential's base URL.

### Plugins' servers don't start on the computer

**Symptom:** Installing a plugin with local (stdio) servers fails, or its tools never appear.

**Cause:** Plugin servers run inside the bot's computer, started by `computerd`. A computer still on
an image built before your upgrade, or a desktop image that wasn't rebuilt, has an older `computerd`
that can't run them. Hosted templates and snapshots built from older images have the same problem.

**Fix:** Rebuild the images with `./install.sh --with-desktop` (or without `--with-desktop` if you
don't use desktops), then let the computer sleep and wake, or restart it from the app. For hosted
providers, rebuild your templates or snapshots from the new images.

### Many old computer containers are still running

**Cause:** The supervisor creates computers outside Compose, so `casama selfhost down` leaves them.
The worker stops idle computers after 5 minutes, but only while it's running.

**Fix:** Start the stack again with `casama selfhost up`. To see them: `docker ps --filter name=casama-c-`.

## Live view

### Live view stays on "connecting"

**Cause:** Viewers reach the computer's screen only through the TURN relay on port 3478. It's
usually blocked by a firewall, or `TURN_PUBLIC_HOST` names a host viewers can't reach (for example
`localhost` on a server).

**Fix:**

1. Open 3478, UDP and TCP, on the server's firewall and any cloud security group.
2. Check that `TURN_PUBLIC_HOST` in `.env` resolves to the server from the viewer's device.
3. Check the admin console's "Live view relay" line, and `casama selfhost logs turn`.
4. Make sure the computer uses the desktop image.

Networks that block both UDP and port 3478 can't use live view: the bundled relay doesn't serve
TLS on 5349. For hosted providers, the relay must be reachable from the internet.

## Backups and restores

### "age is not installed"

**Fix:** Install age (`apt install age` or `brew install age`) on the machine running the backup or
restore.

### "This backup is encrypted; pass --identity with your age key file"

**Fix:** Run `casama selfhost restore <folder> --identity backup.key` with the private key that
matches a recipient the backup was encrypted to. "age could not decrypt ... (wrong identity?)" means
the key doesn't match.

### `pg_restore` prints many warnings during a restore

**Cause:** Supabase owns some database objects that `pg_restore --clean` can't drop or recreate.

**Fix:** None needed: the data is restored. Check by signing in once the stack is back up.

### After restoring on a new machine, sign-in or encrypted content fails

**Cause:** `restore` doesn't restore `infra/compose/.env`. A new install generated new keys, so
tokens, the JWT secret or `CONTENT_ENCRYPTION_KEY` no longer match the data.

**Fix:** Put the backup's `env` file at `infra/compose/.env`, run `./install.sh` (it keeps that
file), then restore again. See [Restore](/self-hosting/operations#restore).

### "No install.sh in ..."

**Cause:** `casama selfhost` commands need the checkout. They look at `--dir`, then
`CASAMA_SELFHOST_DIR`, then the current directory.

**Fix:** Pass `--dir /path/to/casama` or set `CASAMA_SELFHOST_DIR`.

## Related

- [Self-hosting](/self-hosting/)
- [Configuration](/self-hosting/configuration)
- [Operations](/self-hosting/operations)
- [Computer providers](/self-hosting/computers)
- [FAQ](/faq)
