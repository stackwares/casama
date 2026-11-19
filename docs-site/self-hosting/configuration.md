# Configuration

Every setting for a Compose install lives in one file: `infra/compose/.env`. The installer writes it
on the first run with generated secrets and a few defaults. This page lists every setting you can
put there, grouped by topic, with its default and what it does.

If you run Casama with Helm or on a platform like Render or Railway, the same names apply as
environment variables on the API, worker and supervisor. See
[Database and auth](#database-and-auth) for the ones Compose sets for you.

## Change a setting

1. Edit `infra/compose/.env`. Use one `NAME=value` per line. An empty value counts as unset.
2. Apply it:

   ```sh
   casama selfhost up
   ```

   Or, without the CLI:

   ```sh
   docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env up -d
   ```

Compose recreates every service whose settings changed. All Casama services read their settings
only at start, so every change needs this step. `docker compose restart` is not enough: it restarts
containers with their old settings.

::: tip Optional profiles
`casama selfhost up` names no Compose profile except `link`, which it adds while remote access is
on. If you changed a setting for the web app, monitoring, search, page PDFs or backups, add the
profile: `docker compose ... --profile monitoring up -d`.
Docker Compose also reads `COMPOSE_PROFILES` from the env file, so `COMPOSE_PROFILES=monitoring,web`
in `.env` keeps them on for every command. Re-running `./install.sh` adds the `backup` profile by
itself once you installed with `--backups`.
:::

Some settings are read by the server but not passed through by the bundled compose file. They're
listed under [Advanced settings](#advanced-settings), with how to add them.

## Core and URLs

| Name                     | Default                         | What it does                                                                                                                          |
| ------------------------ | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `CASAMA_SITE`            | Set by the installer            | What Caddy serves: a domain (`casama.example.com`, automatic HTTPS) or `:80` (plain HTTP, for `--local` or behind another proxy).      |
| `CASAMA_PUBLIC_URL`      | Set by the installer            | The public address, for example `https://casama.example.com`. Used as the API, app and Supabase address and for Auth redirects.       |
| `CASAMA_APP_URL`         | `CASAMA_PUBLIC_URL`             | The web app's address, when it is served on its own host (for example `https://app.example.com`). Links in emails and invites go there unless `CASAMA_OPEN_URL` is set. |
| `CASAMA_OPEN_URL`        | (empty)                         | A page that opens links in the installed app, else in the web app (Casama Cloud uses `https://casama.ai/open`). Empty: links go to the web app. |
| `HTTP_PORT`              | `80`                            | Host port Caddy listens on for HTTP.                                                                                                  |
| `HTTPS_PORT`             | `443`                           | Host port Caddy listens on for HTTPS.                                                                                                 |
| `CASAMA_PAGES_SITE`      | `:8790`                         | What Caddy serves Pages on: a domain of its own (`pages.example.com`, automatic HTTPS) or a port.                                     |
| `CASAMA_PAGES_URL`       | `http://localhost:8790`         | The public address of Pages, used in links to bots' pages. Set it to match `CASAMA_PAGES_SITE`.                                        |
| `PAGES_PORT`             | `8790`                          | Host port Caddy publishes for Pages.                                                                                                  |
| `CORS_ORIGINS`           | (empty)                         | Extra comma-separated web origins allowed to call the API from a browser. The public address is always allowed.                       |
| `CHROME_EXTENSION_IDS`   | Casama for Chrome's id         | Extension ids allowed to call the API from Chrome or Edge, comma-separated. The default lets Casama for Chrome in. Add an id to allow your own build. |
| `FIREFOX_EXTENSIONS`     | `true`                          | Lets Casama for Firefox call the API. Firefox gives every install its own address, so it can't be listed by id; `false` keeps it out. |
| `RATE_LIMIT_PER_MINUTE`  | `120`                           | Requests per minute on the API and webhooks, per signed-in user or else per IP address. Casama Link endpoints get ten times as much. |
| `UPDATE_CHECK_URL`       | (empty: no update checks)       | Where the admin console checks for new releases, in the shape of GitHub's latest-release API.                                         |
| `CASAMA_REGISTRY`        | `casama` (build locally)        | Where the Casama images come from. `./install.sh --pull` sets `ghcr.io/stackwares/casama`, and re-runs then pull instead of build.     |
| `CASAMA_VERSION`         | `local`                         | The tag of the Casama images Compose builds or pulls. `--pull [tag]` sets it (default `latest`).                                      |
| `CASAMA_SERVER_IMAGE`    | (empty: registry and tag above) | Runs the API and worker on one exact image, such as your own build of `apps/server/Dockerfile`. Upgrades leave it alone; empty it to go back. |
| `API_DRAIN_SECONDS`      | `30`                            | How long a stopping API lets the requests it's answering finish before it exits.                                                       |
| `CALL_HANDOVER_SECONDS`  | `600`                           | When a deploy starts the new API first and hands over (SIGUSR2), how long the old one keeps carrying voice and phone calls.              |
| `WORKER_DRAIN_SECONDS`   | `45`                            | How long a stopping worker lets the step each bot is on finish; runs continue on the next worker.                                      |
| `HTTP_BIND`              | `0.0.0.0`                       | The address Caddy's HTTP, HTTPS and Pages ports listen on. `--behind-proxy` and `--local` set `127.0.0.1`.                              |
| `TRUSTED_CLIENT_IP_HEADER` | (empty: `X-Forwarded-For`)    | A header your edge sets with the caller's address, for rate limits on signed-out requests. Behind Cloudflare, `cf-connecting-ip`.      |
| `AUTH_RATE_LIMIT_HEADER` | (empty: Auth's default)         | The same for Supabase Auth's per-caller sign-in limits. Behind Cloudflare, `cf-connecting-ip`.                                         |
| `CASAMA_CONTAINER_PREFIX` | `casama`                       | Prefix of the fixed container names and of bot computers' containers, networks and volumes. Change it to run two stacks on one machine. |
| `PAIR_LINK_URL`          | `https://casama.ai/pair`        | The page a sign-in QR code opens, which hands the code to the app. The code rides after `#`, so the page never receives it.           |

**Pages on their own domain.** Bots' web pages are served from a separate origin so a page's
scripts never share an origin with Casama. On a public server, give them their own name:

```sh
CASAMA_PAGES_SITE=pages.casama.example.com
CASAMA_PAGES_URL=https://pages.casama.example.com
```

Point the name's DNS at the server; Caddy gets its certificate automatically.

**Change the address after installing.** Re-running the installer doesn't change the address. Edit
these together, then run `casama selfhost up`:

```sh
CASAMA_SITE=casama.example.com
CASAMA_PUBLIC_URL=https://casama.example.com
TURN_PUBLIC_HOST=casama.example.com
SIGNUP_HOOK_URI=https://casama.example.com/hooks/auth/before-user-created
```

### Behind another proxy

If a load balancer or another reverse proxy terminates TLS:

1. Set `CASAMA_SITE=:80` so Caddy serves plain HTTP. `./install.sh --behind-proxy --domain <name>` does this.
2. Keep `CASAMA_PUBLIC_URL` on the public `https://` address.
3. Route your proxy to Caddy's HTTP port (`HTTP_PORT`), including WebSocket upgrades.
4. Set `HTTP_BIND=127.0.0.1` (the installer does this with `--behind-proxy`). Docker-published ports skip the host firewall, so `0.0.0.0` would serve plain HTTP to anyone who can reach the server's IP.
5. Keep port 3478 (UDP and TCP) reachable directly for live view, and set `TURN_PUBLIC_HOST` (`--turn-host`) to a name that points at the server with DNS only, not through the HTTP proxy. Media stays inside coturn, so the relay range 49160–49260 does not need to be open.
6. If the proxy is a tunnel on the same machine (Cloudflare Tunnel, for example), every request reaches Caddy from the tunnel's own address. Set `TRUSTED_CLIENT_IP_HEADER` to the header that carries the real address (`cf-connecting-ip` for Cloudflare), or all signed-out callers share one rate limit.

## Generated secrets

The installer generates these on the first run. Don't edit them on a running server unless the
table says it's safe: several are baked into the database or into each other.

| Name                     | What it is                                                                     | Safe to change?                                                        |
| ------------------------ | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| `POSTGRES_PASSWORD`      | Password for Postgres and the Supabase service roles                           | No. Postgres keeps the password it was first started with.              |
| `WORKER_DB_PASSWORD`     | Password for `casama_worker`, the worker's least-privilege database role       | Yes. The `migrate` service sets it again at every start.                |
| `AUTH_HOOK_SECRET`       | Shared secret for the sign-up hook (`v1,whsec_…`), on Auth and the API         | Yes, if you change it in both places and restart Auth and the API.      |
| `JWT_SECRET`             | Signs Supabase tokens                                                          | No. `ANON_KEY` and `SERVICE_ROLE_KEY` are signed with it.               |
| `ANON_KEY`               | Supabase anon key (a JWT)                                                      | No                                                                     |
| `SERVICE_ROLE_KEY`       | Supabase service role key (a JWT)                                              | No                                                                     |
| `SECRET_KEY_BASE`        | Supabase Realtime's secret                                                     | No                                                                     |
| `REALTIME_ENC_KEY`       | Supabase Realtime's encryption key                                             | No                                                                     |
| `SAML_PRIVATE_KEY`       | Supabase Auth's SAML signing key (RSA, PKCS#1, base64 DER)                     | No                                                                     |
| `SUPERVISOR_TOKEN`       | The API and worker's token for the supervisor (16+ characters)                 | Yes, with a full `casama selfhost up`                                   |
| `COMPUTER_TOKEN_SECRET`  | Derives each computer's own tokens                                             | No. Existing computers would stop answering.                            |
| `EGRESS_CONTROL_TOKEN`   | The supervisor's token for the egress proxy's control API                      | Yes, with a full `casama selfhost up`                                   |
| `INTERNAL_TOKEN`         | Shared secret for the API's internal endpoints (32+ characters)                | Yes, with a full `casama selfhost up`                                   |
| `TURN_SECRET`            | coturn's shared secret for short-lived live view credentials (16+ characters)   | Yes, with a full `casama selfhost up`                                   |
| `SEARXNG_SECRET`         | SearXNG's own secret (search profile)                                          | Yes, with a full `casama selfhost up`                                   |
| `METRICS_TOKEN`          | Bearer token for `/metrics` (16+ characters)                                   | Yes. Prometheus picks it up when it restarts.                           |
| `GRAFANA_ADMIN_PASSWORD` | Grafana's `admin` password (monitoring profile)                                | Only before Grafana's first start; afterwards change it in Grafana.     |

The installer also generates `CONTENT_ENCRYPTION_KEY` unless you use AWS KMS. See
[Encryption keys](#encryption-keys): it can't be changed like the others.

## Database and auth

Compose wires these for the API and worker from the generated secrets. Set them yourself only on
Helm, a platform like Render, or a custom setup.

| Name                        | Default                       | What it does                                                                                                   |
| --------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `MODE`                      | `api`                         | `api` or `worker`. The API and worker are the same image.                                                     |
| `PORT`                      | `8787`                        | The API's HTTP port.                                                                                          |
| `NODE_ENV`                  | `development`                 | Set `production` in production (Compose does).                                                                |
| `DATABASE_URL`              | Required                      | Postgres URL with full access, for the API.                                                                    |
| `WORKER_DATABASE_URL`       | Falls back to `DATABASE_URL`  | The worker's least-privilege URL (`casama_worker`). Compose builds it from `WORKER_DB_PASSWORD`.               |
| `SUPABASE_URL`              | Required                      | Supabase's public address. Compose uses `CASAMA_PUBLIC_URL`, since Caddy routes `/auth/v1` and friends.        |
| `SUPABASE_ANON_KEY`         | Required                      | Supabase anon key. The apps get it from the server.                                                            |
| `SUPABASE_JWT_SECRET`       | (empty: verify with JWKS)     | Supabase's HS256 secret. When unset, tokens are checked against the project's JWKS.                           |
| `SUPABASE_SERVICE_ROLE_KEY` | (empty)                       | Needed for SAML SSO administration and for sign-in codes (scan to sign in).                                    |
| `SUPABASE_INTERNAL_URL`     | `SUPABASE_URL`                | How the server reaches Supabase itself. Compose uses `http://kong:8000`, since the public address may not answer from inside the stack. |
| `PUBLIC_APP_URL`            | `http://localhost:3000`       | The app's public address. Always allowed by CORS.                                                              |
| `PUBLIC_OPEN_URL`           | `PUBLIC_APP_URL`              | Where links in emails, invites and shares start, when a page should hand them to the installed app (D-326). Compose uses `CASAMA_OPEN_URL`. |
| `PUBLIC_API_URL`            | The request's origin          | The API's public address, used in OAuth redirects, phone call webhooks and live view.                          |
| `PAGES_URL`                 | `http://localhost:8790`       | Public address of Pages. Compose sets it from `CASAMA_PAGES_URL`.                                              |
| `PAGES_PORT`                | (unset: Pages not served)     | Port the API process serves Pages on. Compose uses `8790` inside the stack.                                    |
| `API_INTERNAL_URL`          | `http://127.0.0.1:$PORT`      | How the worker reaches the API's internal endpoints.                                                           |
| `INTERNAL_TOKEN`            | Derived from `DATABASE_URL`   | Shared secret for internal endpoints. Always set a random value; the server warns in production without one.  |
| `SUPERVISOR_URL`            | (unset: no computers)         | The sandbox supervisor's address. Compose uses `http://casama-supervisor:8788`.                               |
| `SUPERVISOR_TOKEN`          | (unset)                       | Token for the supervisor.                                                                                      |

## Page PDFs

**Export PDF** on a page prints it with headless Chromium. Chromium can't keep its own sandbox inside
a normal container, so it runs in a container of its own (Gotenberg, about 500 MB) that holds no
secrets and sits on a private network with only the API on it: no internet, no database. Pages are
printed from what the API sends; outside URLs and other files are blocked.

1. Add `pdf` to `COMPOSE_PROFILES` in `infra/compose/.env` (or pass `--profile pdf`).
2. Set `PDF_RENDERER_URL=http://pdf:3000` in the same file.
3. Run `docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env up -d`.

| Name               | Default                 | What it does                                          |
| ------------------ | ----------------------- | ----------------------------------------------------- |
| `PDF_RENDERER_URL` | (empty: PDF export off) | The PDF sidecar's address. Compose: `http://pdf:3000`. |

On Helm, run `gotenberg/gotenberg:8.39.0-chromium` as its own Deployment with a NetworkPolicy that only
lets the API in and nothing out, and set `PDF_RENDERER_URL` with `extraEnv`.

### PDFs and Word files bots make

Bots make PDF and Word files from text in the worker itself, with no sidecar and no computer. The
server image includes Noto Sans CJK for Chinese, Japanese and Korean, so there's nothing to set up.
If you run the worker outside the image, install Noto Sans CJK (`NotoSansCJK-Regular.ttc` and
`NotoSansCJK-Bold.ttc`) and point `CJK_FONT_DIR` at their folder. Without them, PDFs with those
languages are refused with a clear message; everything else still works.

| Name           | Default                          | What it does                                    |
| -------------- | -------------------------------- | ----------------------------------------------- |
| `CJK_FONT_DIR` | `/usr/share/fonts/opentype/noto` | Folder with the Noto Sans CJK collections.      |

## Invite links

Invite links are `<PUBLIC_APP_URL>/join/<token>`. With the web app running, it shows the invite;
without it, Caddy sends `/join/*` to a small page from the API with **Open in Casama**. To have
links open the installed apps directly, publish the app-link files:

| Name                  | Default            | What it does                                                                                     |
| --------------------- | ------------------ | ------------------------------------------------------------------------------------------------ |
| `APPLE_APP_IDS`       | (empty: no file)   | iOS app ids (`TEAMID.ai.casama.app`, comma-separated) for `/.well-known/apple-app-site-association`. |
| `ANDROID_APP_PACKAGE` | `ai.casama.app`   | Android package for `/.well-known/assetlinks.json`.                                              |
| `ANDROID_CERT_SHA256` | (empty: no file)   | SHA-256 fingerprints of the Android signing certificates, comma-separated.                       |
| `APP_STORE_URL`       | (empty)            | App Store page linked from the invite page.                                                      |
| `PLAY_STORE_URL`      | (empty)            | Google Play page linked from the invite page.                                                    |

The apps only claim links for a domain built into them, so on your own domain links open the
invite page, whose **Open in Casama** button opens the app and points it at your server.

## Email

Supabase Auth sends sign-in links, confirmations and password resets through SMTP. Casama sends
invites through the same SMTP server, or through Resend when `RESEND_API_KEY` is set. Email is
optional: without it, people sign in with a password and invites return a code to share.

| Name                | Default                        | What it does                                                                                          |
| ------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `SMTP_HOST`         | (empty: Auth sends no email)   | Your SMTP server.                                                                                     |
| `SMTP_PORT`         | `587`                          | SMTP port. `465` uses TLS from the start; other ports need STARTTLS.                                  |
| `SMTP_USER`         | (empty)                        | SMTP user name.                                                                                       |
| `SMTP_PASS`         | (empty)                        | SMTP password.                                                                                        |
| `SMTP_ADMIN_EMAIL`  | (empty)                        | The address Auth emails come from.                                                                    |
| `EMAIL_AUTOCONFIRM` | `true`                         | Confirm new accounts without an email. Set `false` once SMTP works.                                   |
| `RESEND_API_KEY`    | (empty)                        | Resend key for invite emails, used instead of SMTP. With neither, an invite returns a code to share.  |
| `EMAIL_FROM`        | `Casama <no-reply@localhost>`  | Sender for Casama's own emails.                                                                       |
| `AUTH_SITE_URL`     | `CASAMA_PUBLIC_URL`            | Where Auth's email links land when the app didn't ask for a place. Set it to your web app's address.  |
| `EMAIL_TEMPLATE_*`  | Casama's branded templates     | URLs of Auth's email templates (`_MAGIC_LINK`, `_CONFIRMATION`, `_INVITE`, `_RECOVERY`, `_EMAIL_CHANGE`, `_REAUTHENTICATION`). Override one to use your own. |

Links in Auth's emails go to `<CASAMA_PUBLIC_URL>/auth/v1/verify`, which Caddy sends to Auth.

To turn on email confirmation and sign-in links:

```sh
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=casama@example.com
SMTP_PASS=your-smtp-password
SMTP_ADMIN_EMAIL=casama@example.com
EMAIL_AUTOCONFIRM=false
```

## Sign-ups and allowlists

| Name                     | Default                          | What it does                                                                                                                             |
| ------------------------ | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `INSTANCE_ADMIN_EMAILS`  | (empty: the first account)       | Comma-separated emails of instance owners, who get the admin console.                                                                    |
| `DISABLE_SIGNUP`         | `false`                          | `true` turns off new sign-ups in Supabase Auth.                                                                                          |
| `SIGNUP_ALLOWED_EMAILS`  | (empty: anyone)                  | Only these emails or domains can sign up, comma-separated: `ana@example.com,@example.org` (`example.org` also works for a domain).       |
| `SIGNUP_HOOK_ENABLED`    | `false`                          | `true` makes Supabase Auth call Casama's sign-up hook. Needed for the allowlist.                                                         |
| `SIGNUP_WAITLIST`        | `auto`                           | Casama Cloud's waitlist and invite gate. `auto` means only where billing is on, which is Casama Cloud. A self-hosted server leaves it alone and nothing changes. Your own switches are `SIGNUP_ALLOWED_EMAILS`, `SIGNUP_INVITED_ONLY` and `DISABLE_SIGNUP`. |
| `WAITLIST_URL`           | `https://casama.ai/waitlist`     | Where the apps and sign-up refusals send people to join the waitlist or enter a code. Used only where the waitlist exists.               |
| `OPENROUTER_DAILY_CAP_USD` | `50`                           | The daily spending cap set on Casama Cloud's OpenRouter key, mirrored here. The waitlist's daily batch skips a day after one that passed 60% of it. Used only where the waitlist exists. |
| `AUTH_HOOK_SECRET`       | (empty)                          | The hook's signing secret, `v1,whsec_<base64>`. Shared by Auth and the API.                                                              |
| `SIGNUP_HOOK_URI`        | Set by the installer             | Where Auth calls the hook: `https://<domain>/hooks/auth/before-user-created`. Empty for `--local`.                                       |
| `ADDITIONAL_REDIRECT_URLS` | `casama://app/login-callback,http://127.0.0.1:*/auth/callback` | Redirect URLs Supabase Auth accepts after sign-in, comma-separated. Keep the default for the apps: iPhone, Mac and Android come back on `casama://`, Windows and Linux on a listener on `127.0.0.1`. |
| `SAML_ENABLED`           | `true`                           | SAML SSO in Supabase Auth. Workspaces register their identity provider through the API (needs an enterprise license).                    |
| `ABUSE_CONTROLS`         | `auto` (off when self-hosted)    | `auto`, `on` or `off`. Sign-up proofs, verified email before computers start, and suspension on egress abuse. Meant for Casama Cloud.    |
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

3. Run `casama selfhost up`.

The allowlist applies to every sign-in method, Google and Apple included. Others see "limited to
approved email addresses". An allowlist without a hook secret refuses every sign-up rather than
allowing everyone.

::: warning
`SIGNUP_HOOK_URI` must be empty or an `https://` address. A plain `http://` address stops Supabase
Auth from starting, even with the hook turned off.
:::

## Apple and Google sign-in

The sign-in screen offers **Continue with Apple** and **Continue with Google**. A new server has
both turned off, so people sign in with email until you set these. They are the accounts people
use to enter Casama. A Google client for Gmail, Calendar and Drive is a different setup, under
[Integrations](#integrations) below.

| Name                     | Default | What it does                                                                                                                                                          |
| ------------------------ | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `APPLE_AUTH_ENABLED`     | `false` | `true` turns on Continue with Apple.                                                                                                                                  |
| `APPLE_AUTH_CLIENT_IDS`  | (empty) | Comma-separated. The Services ID first, then the app id `ai.casama.app`. The first is the browser flow. The app id is the system sheet on iPhone and Mac.           |
| `APPLE_AUTH_SECRET`      | (empty) | Apple's client secret, a signed token. It expires within six months. Make a new one from the same key before it does, or browser sign-in starts failing.             |
| `GOOGLE_AUTH_ENABLED`    | `false` | `true` turns on Continue with Google.                                                                                                                                 |
| `GOOGLE_AUTH_CLIENT_ID`  | (empty) | The web client id from Google Cloud. To let your own build of the app use Google's sign-in sheet on iPhone and Mac, add its iOS client id after a comma.           |
| `GOOGLE_AUTH_SECRET`     | (empty) | That client's secret.                                                                                                                                                 |

Apple and Google both send people back to `https://<your domain>/auth/v1/callback`. Register that
exact address. On Apple it is the return URL of the Services ID. On Google it is an authorized
redirect URI of the web client. If Apple and Google reach Auth under another name than
`CASAMA_PUBLIC_URL`, set that full address in `AUTH_CALLBACK_URL`.

1. In the Apple Developer account, turn on Sign in with Apple for the app id `ai.casama.app`.
   Create a Services ID and a key. Put the Services ID first in `APPLE_AUTH_CLIENT_IDS`, then
   `ai.casama.app`.
2. In Google Cloud, create a web OAuth client (not an iOS or Android client) and copy its id and
   secret.
3. Add the values to `infra/compose/.env` and run `casama selfhost up`.

Apple asks apps with Sign in with Apple to revoke a person's Apple tokens when they delete their
account. Give the server the same Sign in with Apple key and it does so: the app hands over what
Apple returned at sign-in, and deleting the account revokes it with Apple.

| Name                       | Default                | What it does                                                    |
| -------------------------- | ---------------------- | --------------------------------------------------------------- |
| `APPLE_SIGNIN_KEY_P8`      | (empty)                | The Sign in with Apple key: the `.p8` file's contents, or a path. |
| `APPLE_SIGNIN_KEY_ID`      | (empty)                | The key's id.                                                   |
| `APPLE_SIGNIN_TEAM_ID`     | (empty)                | Your Apple team id.                                             |
| `APPLE_SIGNIN_APP_ID`      | `ai.casama.app`        | The app id the system sheet signs in with.                      |
| `APPLE_SIGNIN_SERVICES_ID` | `ai.casama.app.signin` | The Services ID the browser sign-in uses.                       |

## Passkeys

People can sign in with a passkey (Face ID, a fingerprint or a screen lock) once they add one in
Settings → Passkeys. On your own server this works in the browser, under your domain. The App
Store and Google Play apps are tied to `casama.ai`, so they hide passkeys when connected to
another server.

| Name                 | Default               | What it does                                                                            |
| -------------------- | --------------------- | --------------------------------------------------------------------------------------- |
| `PASSKEYS_ENABLED`   | `false`               | `true` turns on passkeys.                                                               |
| `PASSKEY_RP_ID`      | (empty)               | Your domain without `https://`, for example `casama.example.com`. Required when on.     |
| `PASSKEY_RP_ORIGINS` | `CASAMA_PUBLIC_URL`   | Comma-separated addresses the web app is served from, if more than the public address. |

A passkey belongs to its domain. Changing `PASSKEY_RP_ID` later means everyone adds theirs again.

iPhone and Mac use Apple's system sheet, so they need `ai.casama.app` in the client id list.
Android, Windows, Linux and the web open the browser, which is what the secret is for. Keep
`casama://app/login-callback` (Android) and `http://127.0.0.1:*/auth/callback` (Windows and Linux)
in `ADDITIONAL_REDIRECT_URLS`. If the web app is served from another
address, add that address too.

## Models and AI Gateway

People add their own model keys in the app (Settings → Model keys) or with
`casama credential add`. Any OpenAI-compatible endpoint works, including a local Ollama. These
settings change server-wide defaults.

| Name                        | Default            | What it does                                                                                                                     |
| --------------------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| `DEFAULT_MODEL_OPENROUTER`  | `deepseek/deepseek-v4.1-flash-1017` | Default model for new bots on OpenRouter.                                                                                        |
| `DEFAULT_MODEL_OPENAI`      | `gpt-6-luna`       | Default model for new bots on OpenAI.                                                                                            |
| `DEFAULT_REASONING_EFFORT`  | `medium`           | `none`, `low`, `medium`, `high`, `xhigh` or `max`.                                                                               |
| `LAZY_TOOLS_THRESHOLD`      | `30`               | Bots with more tools than this load the rest on demand. `0` turns it off.                                                       |
| `CHATGPT_SIGN_IN`           | `auto` (on)        | `auto`, `on` or `off`. Lets people use their ChatGPT plan instead of an API key. Each plan serves only its owner. `auto` is on unless billing is on. See [Connect a ChatGPT plan](/guide/bots#connect-a-chatgpt-plan). |
| `RUN_CONCURRENCY`           | `20`               | How many runs one worker processes at once. See [Scaling](/self-hosting/operations#scaling).                                    |
| `RUN_WORKSPACE_CONCURRENCY` | `5`               | How many of those runs one workspace may have going at once; its other runs wait their turn. `0` turns the limit off. |
| `AI_GATEWAY_URL`            | (empty)            | Send model calls through Cloudflare AI Gateway: `https://gateway.ai.cloudflare.com/v1/<account>/<gateway>`.                     |
| `AI_GATEWAY_TOKEN`          | (empty)            | Token for an authenticated gateway, sent as `cf-aig-authorization`.                                                              |
| `GOOGLE_AI_API_KEY`         | (empty)            | A server-wide Google AI key: live calls in workspaces without a Gemini or OpenAI key of their own use it. You pay Google for those calls. |
| `LIVE_CALL_RELAY`           | `on`               | `on` or `off`. With billing on, live calls paid from credits go through the API (`PUBLIC_API_URL`), which bills what Gemini reports instead of what the app reports. Without billing, or `off`, the app talks to Gemini directly. |

With `AI_GATEWAY_URL` set, calls for OpenAI, Anthropic, Google, xAI and OpenRouter keys go through
the gateway, for caching, logs and rate limits. A credential with its own base URL keeps it.

**Local models.** To use Ollama running on the server, allow the server to reach it with
[`OUTBOUND_ALLOW_CIDRS`](#network-and-egress), then add it as an OpenAI-compatible credential with
the address the worker container can reach. On Docker Desktop that's `host.docker.internal`:

```sh
casama credential add --provider openai_compatible --base-url http://host.docker.internal:11434/v1
```

On Linux, use the host's LAN address instead (for example `http://192.168.1.20:11434/v1`).

Add `--embedding-model embeddinggemma` (after `ollama pull embeddinggemma`) so memory search runs
locally too, and `--vision-model <name>` for a model that reads images but isn't recognized by
name. [Local models](/guide/bots#local-models) has the details.

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
| `S3_ENDPOINT`           | (AWS)                  | Endpoint, for example `http://casama-s3:8333` or `https://<account>.r2.cloudflarestorage.com`. |
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
S3_ACCESS_KEY_ID=casama
S3_SECRET_ACCESS_KEY=a-long-random-secret
```

```yaml
# infra/compose/docker-compose.yml, under services.supervisor.environment
OBJECT_STORE: s3
S3_ENDPOINT: http://casama-s3:8333
S3_BUCKET: casama
S3_CREATE_BUCKET: "true"
S3_ACCESS_KEY_ID: ${S3_ACCESS_KEY_ID:-}
S3_SECRET_ACCESS_KEY: ${S3_SECRET_ACCESS_KEY:-}
```

Then start it with the profile:

```sh
docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env --profile s3 up -d
```

`casama selfhost backup` archives the `objects` volume only. With S3, back up the bucket with your
storage provider's tools.

### The Library's files

The API and worker keep a second store: files bots hand over in replies, which the Library keeps
with their versions, and the pictures, videos and sounds in chats. By default it's the `library`
Docker volume, mounted at `/data/library`. To keep it in S3-compatible storage instead, set these
in `infra/compose/.env`; Compose passes them to the API and worker:

| Name                            | Default         | What it does                                       |
| ------------------------------- | --------------- | -------------------------------------------------- |
| `LIBRARY_OBJECT_STORE`          | (filesystem)    | `s3` to use S3-compatible storage.                 |
| `LIBRARY_OBJECT_DIR`            | `/data/library` | Folder for the filesystem store.                   |
| `LIBRARY_S3_BUCKET`             | Required with `s3` | Bucket name.                                    |
| `LIBRARY_S3_ENDPOINT`           | (AWS)           | Endpoint, for example an R2 address.               |
| `LIBRARY_S3_REGION`             | `auto`          | Region.                                            |
| `LIBRARY_S3_ACCESS_KEY_ID`      | (empty)         | Access key.                                        |
| `LIBRARY_S3_SECRET_ACCESS_KEY`  | (empty)         | Secret key.                                        |
| `LIBRARY_S3_PREFIX`             | `library/`      | Key prefix inside the bucket.                      |

The scheduled `backup` container includes the `library` volume (`library.tar.gz`).
`casama selfhost backup` doesn't; see [Back up your server](/self-hosting/operations#back-up-your-server).

## Computers and sandbox

These go to the supervisor. Hosted providers and their settings are on
[Computer providers](/self-hosting/computers).

| Name                 | Default                 | What it does                                                                                                         |
| -------------------- | ----------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `COMPUTER_MEMORY_MB` | `2048`                  | Memory for each new computer, in MB. Swap is capped at the same amount. The API also counts a computer with no recorded size as this much. |
| `COMPUTER_HOST_MEMORY_GB` | Set by the installer | Memory all hosted computers together may use, in GB. A start past it waits with `capacity_full`. The installer sets the machine's memory less 4 GB (at least 2). `0` means no limit. See [Server capacity](/self-hosting/operations#server-capacity). |
| `WARM_POOL_SIZE`     | `0` (off)               | How many started headless computers to keep waiting, so a new computer starts at once. Docker provider only.         |
| `SANDBOX_RUNTIME`    | Set by the installer    | The Docker runtime for computers: `runsc` for gVisor, or empty for Docker's default.                                 |

## Network and egress

| Name                    | Default           | What it does                                                                                                                                   |
| ----------------------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `OUTBOUND_ALLOW_CIDRS`  | (empty)           | Private networks the API and worker may call, comma-separated CIDRs, for example `192.168.1.0/24`. Everything private is blocked otherwise.     |
| `TURN_PUBLIC_HOST`      | Set by the installer | The host name viewers use to reach the TURN relay. The domain, or `localhost` for `--local`.                                                 |
| `TURN_HOST_PORT`        | `3478`            | Host port the TURN relay is published on, and the port viewers are given. "Run Casama on this computer" moves it when 3478 is taken.              |
| `TURN_BIND`             | `0.0.0.0`         | The address the TURN port listens on. `--local` sets `127.0.0.1`.                                                                              |

`OUTBOUND_ALLOW_CIDRS` covers calls the server makes for bots and people: model endpoints such as
Ollama, password managers such as Vaultwarden, connections, MCP servers and memory backends. It
doesn't change what computers can reach. The egress proxy always blocks private, loopback,
link-local (cloud metadata), CGNAT, multicast and reserved addresses for computers.

## Voice and phone calls

Bots phoning other numbers through a workspace's own Twilio account is built but turned off for
now. To try it, set `PHONE_CALLS=true` on the server (bots get the `voice.call` tool) and build the
app with `--dart-define=PHONE_CALLS=true` (admins see **Workspace settings** → **Phone calls**).
It needs a public `https://` address, because Twilio calls back to `PUBLIC_API_URL` (Compose sets
it to `CASAMA_PUBLIC_URL`).

To ring iPhones for calls through PushKit, and to refresh iPhone and Mac widgets the moment
something changes, the server needs an APNs token key for the app's bundle:

| Name            | Default   | What it does                                       |
| --------------- | --------- | -------------------------------------------------- |
| `APNS_KEY_P8`   | (empty)   | The APNs token key: the `.p8` file's contents.     |
| `APNS_KEY_ID`   | (empty)   | The key's id.                                      |
| `APNS_TEAM_ID`  | (empty)   | Your Apple team id.                                |
| `APNS_VOIP_TOPIC` | `ai.casama.app.voip` | The app's VoIP push topic.              |
| `APNS_TOPIC_APP` | `ai.casama.app` | The app's bundle id. Widget pushes go to `<bundle id>.push-type.widgets`. |

Without a key, a server linked to Casama Cloud sends widget refresh pushes through Casama Cloud's
relay, like its other notifications. The push says only that something changed: the widget then
fetches what it shows from your server. Unlinked and without a key, iPhone and Mac widgets still
refresh on their own schedule; Android widgets refresh through `FCM_SERVICE_ACCOUNT`.

Watch apps (Apple Watch and Wear OS) reach your server with a key of their own and are signed in
through the phone app, since a watch can't learn your server's address. Their pushes go through the
same relay. See [Casama on Apple Watch](/guide/apple-watch).

## Push notifications

| Name                   | Default   | What it does                                                                                                      |
| ---------------------- | --------- | ----------------------------------------------------------------------------------------------------------------- |
| `FCM_SERVICE_ACCOUNT`  | (empty)   | A Firebase service account JSON, on one line, for the Firebase project the apps are built with. Unset: no push. |
| `FCM_SENDER_ID`        | (empty)   | That Firebase project's number (its sender id). Casama for Chrome registers for pushes with it; unset, the extension checks every minute while Chrome is open. |

Push only reaches apps built with the same Firebase project as the service account. Without push,
the in-app inbox still shows every notification.

The apps from the App Store and Google Play are built with Casama's Firebase project, so your own
key can't reach them. Link the server to Casama Cloud instead and, as long as
`FCM_SERVICE_ACCOUNT` is empty, its notifications and call rings go through there, for free:
`casama selfhost remote on` for a server on your own computer, or `casama selfhost remote link` for
one with its own domain. With **Private Notifications** on, they carry no text. See
[Use your server on your phone](/self-hosting/remote-access#notifications).

## Integrations

| Name                          | Default   | What it does                                                                                                                                                   |
| ----------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GOOGLE_OAUTH_CLIENT_ID`      | (empty)   | Your Google OAuth client, for Gmail, Calendar and Drive connections.                                                                                            |
| `GOOGLE_OAUTH_CLIENT_SECRET`  | (empty)   | Its secret.                                                                                                                                                     |
| `ZOHO_OAUTH_CLIENT_ID`        | (empty)   | Your Zoho OAuth client, for the one-sign-in Zoho app (Mail, CRM, Desk, Books). See [Connections](/guide/connections#zoho).                          |
| `ZOHO_OAUTH_CLIENT_SECRET`    | (empty)   | Its secret.                                                                                                                                                     |
| `MCP_OAUTH_CLIENTS`           | (empty)   | OAuth clients for apps that don't support automatic registration, as JSON by app id: `{"slack":{"client_id":"...","client_secret":"..."}}`.                     |
| `COMPOSIO_API_KEY`            | (empty)   | A server-wide Composio key. Apps whose own sign-in needs a client the server doesn't have (GitHub, Slack, Asana, Google's apps without a Google client, and others) then offer **Sign in through Composio**. The admin console's Services tab can switch back to people's own accounts. |
| `OAUTH_REDIRECT_URL`          | `<PUBLIC_API_URL>/oauth/callback` | Where vendors send people back after an app sign-in. Change it only if vendors must use another address.                                 |
| `SEARXNG_URL`                 | (empty)   | A SearXNG instance for web search in workspaces without their own search key (Brave Search, Tavily, Parallel or Serper). Free: `./install.sh --search` runs one (`http://searxng:8080`). Its settings must allow JSON results. It is always tried last. |
| `SEARCH_PROVIDER_ORDER`       | `parallel,serper,searxng` | The server's own web search for workspaces without a key, in the order tried; the next one answers when one fails or finds nothing. Names: `parallel`, `serper`, `deepseek`, `searxng`. A provider without its key is skipped. Answers are kept for 6 hours per workspace. |
| `PARALLEL_API_KEY`            | (empty)   | The server's [Parallel](https://parallel.ai) Search key ($1 per 1,000 searches). The server pays; usage shows each search's cost. |
| `SERPER_API_KEY`              | (empty)   | The server's [Serper](https://serper.dev) key, Google results ($1 per 1,000 searches). |
| `DEEPSEEK_SEARCH_API_KEY`     | (empty)   | A DeepSeek API key for DeepSeek's Search API ($0.75 per 1,000). Used only when `deepseek` is in `SEARCH_PROVIDER_ORDER`: searches then go to DeepSeek's servers in China. |
| `UNSPLASH_ACCESS_KEY`         | (empty)   | Wallpaper photo search in Appearance. Without it, the app offers its own patterns and photos.                                                                   |
| `GALLERY_URL`                 | `https://gallery.casama.ai` | The open gallery of themes, color schemes, wallpapers, skills, apps, starter bots, routine ideas and reviewed plugins. Set to `off` to turn it off; a fork can point here instead. When it can't be reached, the built-in looks, skills, apps and bots stay. |
| `GITHUB_API_TOKEN`            | (empty)                     | A GitHub token for fetching plugins, packs and skills from GitHub. Without one, GitHub allows the server 60 API calls an hour (Casama reads public files from raw.githubusercontent.com, so a fetch is a few calls); with one, 5,000. A fine-grained token with public repositories (read-only) is enough. A workspace's own `GITHUB_TOKEN` secret still opens its private repositories. |

Register `https://casama.example.com/oauth/callback` as the redirect URI in each OAuth app. See
[Connections](/guide/connections).

### Gallery

The gallery's settings beyond `GALLERY_URL`. The defaults suit almost every server.

| Name                   | Default                                    | What it does |
| ---------------------- | ------------------------------------------ | ------------ |
| `GALLERY_SIGNATURE`    | `optional`                                 | Whether the gallery must be signed. `required`: the server only trusts a catalog whose `manifest.sig` checks out against the public key, and shows the gallery as unavailable otherwise. `optional`: it checks the signature when the catalog has one (a signature that doesn't check out still makes it unavailable). `off`: never checked. With no public key, it's off. |
| `GALLERY_PUBLIC_KEY`   | (empty)                                    | The catalog's Ed25519 public key, base64 of the raw 32 bytes. Empty: Casama's own key for the default `GALLERY_URL`, none for any other address. Set it when you sign your own catalog (`GALLERY_SIGNING_KEY` in its CI). |
| `GALLERY_SOURCES`      | (empty)                                    | More catalogs next to the main one, comma-separated: `url`, `name=url`, or `name=url#<base64 public key>`. Their items show up with ids like `team:weekly-review`. Each folder is laid out like the gallery's and checked with the same `node gallery/check.mjs`. If one can't be reached, only its items are missing. |
| `GALLERY_STATS_URL`    | `https://api.casama.ai/v1/gallery/stats`   | Where the "Used by 120 people" numbers on gallery items come from. They're Casama's public, aggregate counts (nothing under 10 people is shown). `off` hides them. Your server's own installs aren't sent anywhere. |
| `GALLERY_SUBMIT_REPO`  | `stackwares/casama-gallery`                | Where **Submit to the gallery** opens pull requests (`owner/repo`). |
| `GALLERY_SUBMIT_TOKEN` | (empty)                                    | A GitHub token that can push branches and open pull requests on that repository. Empty: **Submit to the gallery** is off on this server. |
| `GALLERY_REWARDS`      | `{"50":10,"250":25,"1000":75}`             | Casama Cloud only (billing on): credits for people whose submitted item reaches that many active users, as JSON (active users → credits). Each item earns each one once. `off` turns rewards off. Only people with a confirmed email, an account at least 7 days old and a run that succeeded with the item count (the item's author never does), and one contributor is paid at most $110 a calendar month (UTC); the rest is recorded and paid the next month. |

An offline server can read a local copy: point `GALLERY_URL` at a folder you serve, made with
`casama gallery mirror <dir>`, which checks the signature as it downloads.

## Billing

Billing is for Casama Cloud. The bundled compose file sets `BILLING_ENABLED=false` for the API and
worker, so there's no paywall and no usage limit, and none of the payment settings apply. Settings
whose `auto` follows billing keep their self-hosted behaviour: `ABUSE_CONTROLS`,
`HEALTH_REQUIRES_ENCRYPTION` and `REFERRALS` stay off, and `CHATGPT_SIGN_IN` stays on.

Computer time is recorded at what it costs whoever runs it: E2B and Daytona at their published
prices, Docker at a share of the server. Change the prices with `COMPUTER_RATES`, as JSON by
provider (`docker`, `e2b`, `daytona`, `local`, `casama-cloud`), in USD per vCPU-hour and per
GB-hour: `{"docker":{"cpu_hour":0.003,"gb_hour":0.005}}`. Rates saved in the admin console's cost
tables win over `COMPUTER_RATES` (see below).

### Models, prices and lists in the admin console

The instance owner can change these in the admin console without a release or a restart (D-373,
D-374). Each opens as JSON with the built-in values beside it to copy from; saving checks every row
and refuses the whole value with a list of what's wrong, and every process picks up a saved value
within a minute. An empty value means the built-in one. A row that a newer or older server can't
read is skipped and the built-in value stands in.

| Where | What | Wins over |
| --- | --- | --- |
| Services > Model catalog | Default, small, test and featured models per provider; price and capability rows (an exact id, or a `pattern` regex); image prices for OpenRouter models. Prices are USD per million tokens (per image for image prices) and refuse values over $1,000 ($5 an image). | The rows in code. Prices a provider's live price list reports still win over a row; `DEFAULT_MODEL_OPENROUTER` and `DEFAULT_MODEL_OPENAI` still win over the catalog's default. |
| Pricing > Cost tables | Voice (speech-to-text a minute, Gemini speech a thousand characters, Gemini Live a minute), Gemini Live token prices, computer rates by provider, media (an image, video a second); and the domain endings on sale and the purchase caps (3 in a workspace's first month, 10 a month after). | The values in code; `COMPUTER_RATES` for computers and `CASAMA_DOMAINS_TLDS` for the endings (both are used when nothing is saved). Save `"domain_tlds": null` to go back to them. |
| Services > Browser guard sites | Hosts added to the guard's off-by-default kinds: `banking`, `health`, `passwords`, `government`. | Nothing: they only add. The lists in code are always checked, and people can still switch a kind back on. The Chrome extension reads them from `GET /v1/browser-guard` once an hour. |
| Services > Call limits | Live calls and bot rings (D-426): `silence_seconds` (60; 20–900) before a quiet call hangs up, `heartbeat_seconds` (15; 5–60), `abandoned_seconds` (60; 60–900) before the server ends a call whose app stopped sending heartbeats, `max_call_minutes` (60; 5–240), `warning_seconds` (60; 15–300) before a limit when the bot warns the person, `ring_daily_cap` (3; 0–20, 0 means bots never ring) rings a person gets a day, `ring_cooldown_minutes` (30; 0–1440) before a bot rings the same person again. Also `GET`/`PUT /v1/admin/call-limits` with `{"limits": {...}}`. | The defaults in code. Values out of range are refused on save; the heartbeat is kept to at most a third of `abandoned_seconds`, and the warning to at most half the longest call. Apps take the silence limit and heartbeat from the next call they start. |

Changing a price changes what usage costs from then on, not what was already billed. The
model-key screen's providers (which are offered for chat and which as other keys, in what order,
with what hint) come from the server's `/v1/config` as `key_providers`; older apps keep their own
list.

The check-in and setup prompts aren't in the admin console: they're gallery content, changed by
reviewed pull request, with the built-in text as the fallback. See
[Gallery catalog format](/develop/gallery-format#prompts).

### Settings only Casama Cloud uses

The server reads these, and the compose file passes most of them, but they only do something with
`BILLING_ENABLED=true`. Leave them empty on your own server.

| Names | What they're for |
| --- | --- |
| `DODO_*`, `REVENUECAT_*` | Payments on the web, and in the App Store and Google Play |
| `REFERRALS`, `REFERRAL_REWARD_USD`, `REFERRAL_WELCOME_USD`, `REFERRAL_REWARD_CAP`, `REFERRAL_REDEEM_DAYS`, `REFERRAL_LINK_BASE` | Invite-a-friend credits |
| `SIGNUP_PROOFS`, `SIGNUP_POW_DIFFICULTY`, `APP_CHECK_PROJECT_NUMBER` | Sign-up abuse controls |
| `CASAMA_LINK_CLOUD` | Serving Casama Link to other servers (on by default when billing is on) |
| `CLOUD_MODEL_UPSTREAM_URL`, `CLOUD_MODEL_UPSTREAM_KEY`, `CLOUD_MODEL_MARKUP`, `CLOUD_COMPUTER_USD_PER_HOUR` | What linked servers' model calls and computers go to and cost |
| `CLOUD_MODEL_PROVIDER_SORT`, `CLOUD_MODEL_PROVIDERS` | Which OpenRouter providers serve calls on `CLOUD_MODEL_UPSTREAM_KEY`. One model is sold by many providers at prices several times apart, and each keeps its own prompt cache. `price` (the default) tries the cheapest first, `throughput` and `latency` rank by speed, and `off` leaves OpenRouter's own spread across providers. `CLOUD_MODEL_PROVIDERS` is a comma-separated list of provider tags to try before the rest, in order (for example `wafer,deepinfra/fp8`). A workspace's own OpenRouter key isn't affected |
| `CLOUD_MODEL_CHAT_SORT` | A different sort (`price`, `throughput` or `latency`) for the model steps of chats a person is waiting on. `throughput` answered about 2.4 times faster at about 3 times the price in our test. Routines, check-ins and background work keep `CLOUD_MODEL_PROVIDER_SORT`. Unset by default: chats use that sort too |
| `CASAMA_LINK_ZONE`, `CASAMA_LINK_CF_ACCOUNT_ID`, `CASAMA_LINK_CF_ZONE_ID`, `CASAMA_LINK_CF_API_TOKEN` | The zone and Cloudflare account that hold linked servers' addresses and tunnels |
| `CASAMA_LINK_SIGN_IN_URL` | Where a workspace admin approves a link code (default `<PUBLIC_APP_URL>/link`) |
| `CASAMA_LINK_PARKING`, `CASAMA_LINK_PARK_AFTER_DAYS` | Removing tunnels of servers that stopped checking in (`off`, `dry-run` or `on`; after 14 days) |
| `CASAMA_LINK_TUNNEL_ALERT`, `CASAMA_LINK_RECORD_LIMIT` | When the instance owners are warned about tunnel and DNS record counts (700 tunnels, 200 records) |
| `CASAMA_LINK_TURN_KEY_ID`, `CASAMA_LINK_TURN_API_TOKEN` | The relay for live view away from the computer (Cloudflare's TURN service) |
| `TREG_API_KEY`, `TREG_RESALE` | Paid data resale through Treg |
| `SUPPORT_INBOX`, `SUPPORT_ASSISTANT`, `SUPPORT_MODEL`, `SUPPORT_DAILY_USD`, `SUPPORT_MESSAGES_PER_DAY`, `DOCS_URL` | Help & support: where messages from the app go (default support@casama.ai, sent with your email settings) and the free support assistant, which runs on `CLOUD_MODEL_UPSTREAM_KEY` (model, daily spending cap $10, 60 messages a person a day, docs it refreshes from) |
| `SUPPORT_WEB`, `SUPPORT_WEB_UPSTREAM_KEY`, `SUPPORT_WEB_MODEL`, `SUPPORT_WEB_DAILY_USD`, `SUPPORT_WEB_MESSAGES_PER_DAY`, `SUPPORT_WEB_ORIGINS`, `TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET_KEY` | Casama Help on public web pages, for visitors who aren't signed in: answers from the docs, sees no account. In production it runs only with Cloudflare Turnstile keys, so it's off unless you set them. Its own model key (else `CLOUD_MODEL_UPSTREAM_KEY`), model, daily spending cap ($5), messages a visitor's address may send a day (20) and the pages allowed to call it |
| `ABUSE_INBOX` | Where reports from inside the app are emailed (default abuse@casama.ai); they also show in Admin console > Reports |
| `ACCOUNT_EMAILS`, `EMAIL_POSTAL_ADDRESS` | Emails about plans and purchases (trial ending, payment failed, plan ended, credits low) and a short welcome series. Welcome and tips emails go out only when `EMAIL_POSTAL_ADDRESS` is set, and each has a one-click unsubscribe |

## Casama Link

Casama Link connects your server to a Casama Cloud workspace. See the
[Casama Link overview](/guide/casama-link).

| Name                | Default   | What it does                                                                 |
| ------------------- | --------- | ---------------------------------------------------------------------------- |
| `CASAMA_CLOUD_URL`  | (empty)   | Casama Cloud's address: `https://api.casama.ai`.                             |
| `CASAMA_CLOUD_KEY`  | (empty)   | The server's Casama Link key (`kcc_...`). Empty: Casama Link is off.         |

With both set:

- notifications go through Casama Cloud when the key can send them and `FCM_SERVICE_ACCOUNT` is
  empty;
- the `casama-cloud` computer provider is available, if the key has the `computers` scope;
- a workspace can add an OpenRouter model key whose base URL is `<cloud>/link/v1/models` and whose
  key is the Casama Link key, if the key has the `models` scope.

See [Cloud computers and credits](/self-hosting/casama-link-cloud).

**Remote access.** `casama selfhost remote on` (or **Use on Your Phone** in the desktop app) writes
the settings below along with the two above, and changes the address and sign-up settings. Don't
set these by hand; see [What gets set](/self-hosting/remote-access#what-gets-set).

| Name                     | Default   | What it does                                                            |
| ------------------------ | --------- | ----------------------------------------------------------------------- |
| `CASAMA_REMOTE_ACCESS`   | `off`     | `on`: the server keeps a public address through Casama Link, the `connector` container runs (Compose profile `link`) and the `turn` container forwards to Casama Cloud's relay. |
| `CASAMA_INSTANCE_ID`     | (empty)   | This server's id at Casama Cloud. The same id gets the same address.    |
| `CASAMA_LOCAL_URL`       | (empty)   | The address on the server's own computer, which its own app keeps using. |
| `SIGNUP_INVITED_ONLY`    | (empty)   | `true`: only an email address with a pending workspace invite can make an account. Needs the sign-up hook. |
| `CASAMA_LINK_RELAY_UPSTREAM` | `turn.cloudflare.com:3478` | Where the `turn` container forwards bots' computers for live view away from the computer. It must match Casama Cloud's relay. |

Compose also sets `CASAMA_LINK_TOKEN_FILE` (`/link/token`, where the API keeps the connector's
secret on the `link` volume) and `CONNECTOR_URL` (`http://connector:2000`, the connector's
readiness check) for the API.

## Sites and domains

A site is a page put on the web at an address of its own (see
[Sites and domains](/guide/sites-and-domains)). Sites are served by the pages port (`PAGES_PORT`,
8790 in Compose), the same process that serves `PAGES_URL`, chosen by the request's host name.

Site addresses are off until you set a sites domain:

1. Pick a domain used only for sites, never your app's or API's domain: a site there could read the
   app's cookies. For example `sites.example.com`, or a domain of its own.
2. Point a wildcard record at the pages port: `*.sites.example.com` and `sites.example.com` to the
   server (or to your tunnel or proxy that forwards them to port 8790), with a wildcard certificate.
   Behind Cloudflare Tunnel, one catch-all ingress rule to `http://api:8790` covers every address.
3. Set `CASAMA_SITES_ZONE=sites.example.com` and restart the API.

| Name                | Default            | What it does                                                         |
| ------------------- | ------------------ | -------------------------------------------------------------------- |
| `CASAMA_SITES_ZONE` | (empty: sites off) | The sites domain. Each site gets `https://<name>.<zone>`.            |
| `CASAMA_SITES_SERVER_IPV4` | (empty)     | The address people point a bare domain (`example.com`) at when they connect their own domain. |
| `CASAMA_SITES_SERVER_IPV6` | (empty)     | The same for IPv6.                                                    |
| `CASAMA_SITES_APEX` | `forward`          | `forward`: a bare domain's record points at the server and the domain is sent on to `www`. `aname`: people's DNS host flattens a CNAME at the bare domain (ALIAS/ANAME), and the bare domain is served directly. |
| `CASAMA_SITES_DOH_URLS` | Cloudflare and Google | DNS-over-HTTPS resolvers used to check a connected domain's records, comma-separated. |

The name `www`, `mail`, `api` and other names kept for the server can't be taken by a site; neither
can names that start `d-` followed by 16 characters, which are kept for connected domains.

### Connected domains

People can put a site on their own domain once your server can make certificates for any host name.
Choose one:

- **Your own edge** (`CASAMA_SITES_OWN_EDGE=true`): the stack's Caddy makes a certificate the
  first time a name is opened, after asking the API (`http://api:8787/internal/tls-ask`), which
  says yes only for a live site address or a domain host it has proof for. The same switch turns
  on Caddy's catch-all site (`infra/compose/selfhost/sites-edge-true.caddy`), so this also serves
  your sites domain's addresses. Ports 80 and 443 must reach Caddy directly, not through a tunnel.
  People add an `A`/`AAAA` record to `CASAMA_SITES_SERVER_IPV4`/`IPV6` (or a CNAME to your pages
  host) and a `TXT` record that proves the domain is theirs.
- **Cloudflare for SaaS** (the three `CASAMA_SITES_CF_*` settings): Cloudflare makes the
  certificates for custom host names on your sites domain's zone, and you keep using a tunnel.

| Name                      | Default   | What it does                                                         |
| ------------------------- | --------- | -------------------------------------------------------------------- |
| `CASAMA_SITES_OWN_EDGE`   | `false`   | `true`: your own Caddy makes the certificates (on-demand TLS).        |
| `CASAMA_SITES_CF_ZONE_ID` | (empty)   | The sites domain's Cloudflare zone, with Cloudflare for SaaS on.      |
| `CASAMA_SITES_CF_API_TOKEN` | (empty) | A token with SSL and Certificates: Edit on that zone only.            |
| `CASAMA_SITES_CF_API_URL` | Cloudflare's API | Only for tests.                                                 |

With neither, **Use Your Own Domain** isn't offered. Buying domains through Casama is for Casama
Cloud only and stays off on self-hosted servers unless you set up a registrar account
(see `docs/DOMAINS-RUNBOOK.md` in the repository).

On Helm, set these with `extraEnv`, add the wildcard host to your Ingress, and for connected domains
use cert-manager with Cloudflare for SaaS, or an ingress controller that supports on-demand TLS with
an ask URL.

## Telemetry and observability

| Name                           | Default                                   | What it does                                                                                                         |
| ------------------------------ | ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `TELEMETRY`                    | `off`                                     | `on` sends anonymous counts once a week (see below).                                                                 |
| `TELEMETRY_URL`                | `https://telemetry.casama.ai/v1/ping`    | Where telemetry goes.                                                                                                |
| `ERROR_REPORTING`              | `auto`                                    | `auto` (Sentry if `SENTRY_DSN` is set, else PostHog if `POSTHOG_API_KEY` is set, else nothing), `sentry`, `posthog` or `none`. |
| `SENTRY_DSN`                   | (empty)                                   | A Sentry-protocol DSN: sentry.io, self-hosted Sentry or GlitchTip.                                                   |
| `POSTHOG_API_KEY`              | (empty)                                   | PostHog project key for error reports (and for product analytics when `PRODUCT_ANALYTICS=on`).                       |
| `PRODUCT_ANALYTICS`            | `off`                                     | `on` sends product events and daily summaries to your analytics: PostHog, Google Analytics 4, or both (Casama Cloud turns it on). Needs the keys of at least one. People and workspaces that opted out are skipped. |
| `ANALYTICS_PROVIDERS`          | (every provider with keys)                | Which providers get product events: `posthog`, `ga4`, `posthog,ga4` or `none`. Leave it empty to use each provider whose keys are set. |
| `GA4_MEASUREMENT_ID`           | (empty)                                   | Google Analytics 4 (free): the measurement id (`G-…`) of a web data stream for server events.                       |
| `GA4_API_SECRET`               | (empty)                                   | A Measurement Protocol API secret for that stream (Admin → Data streams → the stream → Measurement Protocol API secrets). |
| `GA4_PROPERTY_ID`              | (empty)                                   | Optional. The numeric GA4 property id: with the setting below, a purged account is deleted from GA4 too.            |
| `GA4_SERVICE_ACCOUNT_JSON`     | (empty)                                   | A Google service account's JSON key with Editor on that property, for those deletions.                              |
| `ANALYTICS_ENVIRONMENT`        | (`NODE_ENV`)                              | The `environment` tag on analytics and error events: `production`, `staging` or `development`.                       |
| `POSTHOG_PERSONAL_API_KEY`     | (empty)                                   | Optional. A PostHog personal API key with person write scope: when an account is purged, its PostHog person and events are deleted too. |
| `POSTHOG_PROJECT_ID`           | (empty)                                   | The PostHog project the key above belongs to.                                                                        |
| `POSTHOG_APP_HOST`             | `https://us.posthog.com`                  | PostHog's app address for person deletion (your region or self-hosted address).                                      |
| `POSTHOG_HOST`                 | `https://us.i.posthog.com`                | PostHog's ingest address, for another region or a self-hosted PostHog.                                               |
| `LOG_LEVEL`                    | `info`                                    | The API and worker's log detail: `debug`, `info`, `warn` or `error`.                                                 |
| `OTEL_EXPORTER_OTLP_ENDPOINT`  | (empty)                                   | Send traces to an OpenTelemetry collector.                                                                           |
| `LANGFUSE_BASE_URL`            | (empty)                                   | Langfuse address. With all three Langfuse settings, runs send LLM traces (workspaces can opt out).                   |
| `LANGFUSE_PUBLIC_KEY`          | (empty)                                   | Langfuse public key.                                                                                                 |
| `LANGFUSE_SECRET_KEY`          | (empty)                                   | Langfuse secret key.                                                                                                 |
| `METRICS_TOKEN`                | Generated                                 | Bearer token for Prometheus metrics at `/metrics`. Without it, `/metrics` is off in production.                     |

**Telemetry** is off unless you turn it on. With `TELEMETRY=on`, the worker sends once a week a
random instance id, the Casama version and two numbers: bots and users active in the last 7 days.
Nothing else: no names, emails, content, keys or addresses.

**Product analytics** go only where you point them. Each provider turns on when its keys are set;
`ANALYTICS_PROVIDERS` picks among them in one line (for example `ga4` to use only Google Analytics, or
`none` to stop all of them while keeping the keys). GA4 gets events tied to a person only: workspace-level
events and the daily summaries stay with PostHog. Apps you build yourself send analytics only when their
`client/config/telemetry.json` names a provider (see the client README).

**Error reports** are scrubbed before they leave: request bodies, headers, cookies and users are
dropped, and secret-looking values and emails are redacted. Apps you build yourself can also report to your own Firebase
Crashlytics with `CRASHLYTICS_ENABLED=true` in `client/config/telemetry.json` (iOS, Android and macOS);
it follows the app's "Share usage data and crash reports" switch.

### Which crash reporter runs

An app runs one crash reporter at a time (D-417): Sentry, Firebase Crashlytics or PostHog error
tracking, or none. Two at once would fight over native crash signals and split the same crash
across two dashboards. Your apps' build decides what they can run: Sentry needs `SENTRY_DSN`, PostHog
needs `POSTHOG_API_KEY`, Crashlytics needs `CRASHLYTICS_ENABLED=true` and a Firebase project and runs
only on iOS, Android and macOS, and `ERROR_REPORTING=none` rules them all out.

You can switch which one runs without a new build, from the remote app settings in Admin → App
settings ([Remote app settings](/self-hosting/operations#remote-app-settings)):

```json
{ "crash_reporter": { "default": "sentry", "android": "crashlytics", "ios": "crashlytics" } }
```

Keys are `default` and the platforms `ios`, `android`, `macos`, `windows`, `linux` and `web`; values
are `sentry`, `crashlytics`, `posthog` or `none`. At each launch, before any reporter starts, the app
picks:

1. this platform's value, else `default`, from the settings it saved at its last check;
2. if that's not set, or the build can't run it on this platform, the build's own
   `ERROR_REPORTING` (`auto` means Sentry when there's a DSN, else PostHog when there's a key);
3. if the build can't run that either, none.

`none` always turns crash reports off. A change reaches an app within half an hour and takes effect
the next time it starts; apps that don't know the setting ignore it. The "Share usage data and crash
reports" switch still turns the chosen reporter off. PostHog's product analytics don't depend on this
setting. Official builds upload crash symbols to every reporter they're set up for (scripts/upload-symbols.sh),
so a switch never leaves crashes unreadable. Support details (Settings → Help) show the reporter in use.

## Backups and alerts

These are read by the optional `backup` and `monitoring` profiles, not by the server. They're
explained on Operations.

| Name | What it does |
| --- | --- |
| `CASAMA_BACKUPS` | `on` once you installed with `--backups`, so re-running the installer keeps the `backup` profile. |
| `BACKUP_*` | Where and when the `backup` container uploads. See [Off-site backups](/self-hosting/operations#off-site-backups). |
| `ALERT_EMAIL` | Where Alertmanager emails alerts, through the SMTP settings above. See [Alerts](/self-hosting/operations#alerts). |
| `CASAMA_BACKUP_RECIPIENTS` | Read by `casama selfhost backup` from your shell, not from `.env`: age recipients for `--encrypt`. |

## Secret store

Bots' named secrets live in Supabase Vault in your database by default. A workspace admin can keep
them in Infisical instead, under workspace settings → **Where secrets are kept**, with a machine
identity's client id and secret. There's no server setting for it. Casama's other credentials
(model keys, connection tokens) stay in Vault either way.

## Encryption keys

Encryption at rest seals message content, run events, memories, summaries, ticket text, pages and
knowledge in Postgres. It's off by default and turned on per workspace by its owners, once the
server has a key.

| Name                               | Default         | What it does                                                                                                    |
| ---------------------------------- | --------------- | --------------------------------------------------------------------------------------------------------------- |
| `CONTENT_ENCRYPTION_KEY`           | (generated)     | The server key that wraps workspace keys: 32 bytes, base64. `install.sh` makes one unless KMS is set; back it up. |
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
3. Run `casama selfhost up`.
4. Wait at least an hour. The worker's hourly maintenance rewraps every workspace key that still
   uses the old server key. Owners can also rotate their workspace right away under workspace
   settings.
5. Remove `CONTENT_ENCRYPTION_KEY_PREVIOUS` and run `casama selfhost up` again.

Rotation rewraps workspace keys and people's About you keys; it doesn't rewrite rows. Search can't
look inside sealed text: memory and knowledge search use embeddings only, which stay unencrypted.

**If the database leaked:** rotating the server key isn't enough, because a copy of the database
plus the old server key still opens the old data keys. Replace the data keys as well:

1. Rotate the server key as above.
2. As the instance owner, call `POST /v1/admin/encryption/replace-keys`. It replaces every
   workspace's data key and every person's About you key. A workspace owner can do the same for one
   workspace with `POST /v1/orgs/{id}/encryption/replace-key`.
3. The worker re-encrypts every row onto the new keys in the background, 500 rows per column a
   minute. Rows are decrypted and encrypted again in the server, never in Postgres, and keep reading
   normally the whole time. The workspace's encryption status shows `rekeying: true` until it's done.
4. An old key is deleted 15 minutes after its last row moves, once nothing anywhere in the database
   still holds a value encrypted with it.

Content in the leaked copy stays readable to whoever has it; replacing keys protects everything
from then on.

## Audit forwarding and enterprise features

| Name                 | Default   | What it does                                                                                     |
| -------------------- | --------- | ------------------------------------------------------------------------------------------------ |
| `CASAMA_LICENSE_KEY` | (empty)   | A Casama Enterprise license key. Unlocks SAML SSO, audit log export and audit-log forwarding.    |

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
`x-casama` block at the top:

```yaml
x-casama: &casama
  # ...
  environment: &casama-env
    # ...
    EMBEDDINGS: ${EMBEDDINGS:-auto}
```

Then set the value in `.env` and run `casama selfhost up`. Keep your edit when you upgrade: `git
pull` refuses to overwrite a changed file, so commit it on a local branch or re-apply it.

**API and worker:**

| Name                       | Default             | What it does                                                                                  |
| -------------------------- | ------------------- | --------------------------------------------------------------------------------------------- |
| `LOCAL_COMPUTERS`          | `true`              | People's own machines as bot computers through the desktop companion.                         |
| `EMBEDDINGS`               | `auto`              | `auto` embeds memories with the workspace's OpenAI key when it has one; `none` uses full-text search only. |
| `AI_GATEWAY_PROVIDERS`     | (all)               | Limit AI Gateway to some providers, comma-separated: `openai`, `anthropic`, `google`, `xai`, `openrouter`. |
| `TRACE_URL_TEMPLATE`       | (empty)             | A trace viewer link containing `{trace_id}`, shown on run timelines.                          |
| `TURN_TLS_PORT`            | (empty)             | Also offer a `turns:` address on this port. The bundled relay doesn't serve TLS.              |
| `CONTENT_KMS_ENDPOINT`     | (AWS's)             | A custom KMS endpoint, for example a VPC endpoint.                                            |
| `MODEL_PRICES_URL`         | OpenRouter's model list | Where the worker reads model prices once a day, for the cost shown on runs and budgets. `off` uses only the built-in table. |
| `GEMINI_LIVE_MODEL`        | `gemini-3.8-live`   | The Gemini Live model for live calls (used when a workspace has a Google AI key).   |
| `VOICE_CONTEXT_TRIGGER_TOKENS`, `VOICE_CONTEXT_TARGET_TOKENS` | `8000`, `3000` | When a live call is trimmed: once the conversation passes the trigger, its oldest turns are dropped until the target is left. Two-way talk is about 1,500 tokens a minute, so the defaults trim after about five minutes of talk and keep the last two. Gemini Live bills every turn for the whole call so far, so lower numbers make long calls cheaper and higher ones let the bot remember more of the call. The bot's instructions and tools aren't counted; they go with every turn either way. Both must be at least `1000`, and the target below the trigger. |
| `PDF_CHROMIUM_PATH`        | (empty: PDF export off) | A Chromium binary in the API's own image, used when `PDF_RENDERER_URL` is empty. Chromium can't keep its sandbox in a normal container, so prefer [the sidecar](#page-pdfs). |
| `COMPOSIO_WEBHOOK_SECRET`  | (empty)             | The signing secret of a Composio webhook subscription to `<PUBLIC_API_URL>/hooks/composio`. With it, new mail and calendar changes in Composio-connected apps start a bot's check-in scan early; without it, scans keep their schedule. |
| `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET`, `SLACK_SIGNING_SECRET` | (empty: paste a bot token) | A Slack app of your own for one-click install of bots into Slack workspaces. Without them, people connect Slack with a bot token. See [Chat apps](/guide/chat-apps). |

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

**For tests and development only.** The server also reads names that point it at fakes or record
model calls. Never set them on a real server: `APP_CHECK_JWKS_URL`, `APP_CHECK_ISSUER_BASE`,
`APNS_URL`, `CASAMA_LICENSE_PUBLIC_KEY`, `CASAMA_LINK_CF_API_URL`, `CASAMA_LINK_TURN_API_URL`,
`CASAMA_MAX_OUTPUT_TOKENS`, `CASAMA_MODEL_FIXTURES`, `CASAMA_MODEL_RECORD`, `CHATGPT_API_URL`,
`CHATGPT_AUTH_URL`, `COMPOSIO_API_URL`, `DODO_API_URL`, `GITHUB_API_URL`, `REVENUECAT_API_URL`,
`SLACK_API_BASE`, `STRIPE_API_URL`, `TREG_API_URL`, `TWILIO_API_URL` and `UNSPLASH_API_URL`.
`FFMPEG_PATH`, `SKILLS_CATALOG_DIR` and the supervisor's `EGRESS_PROXY_PORT` and `NAME_PREFIX` are
set inside the images or by Compose; leave them alone.

## Related

- [Self-hosting](/self-hosting/)
- [Operations](/self-hosting/operations)
- [Computer providers](/self-hosting/computers)
- [Troubleshooting](/self-hosting/troubleshooting)
- [Privacy](/guide/privacy)
- [Casama Link](/guide/casama-link)
- [Use your server on your phone](/self-hosting/remote-access)
