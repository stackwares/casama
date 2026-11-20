# Self-hosting

Casama runs on your own hardware. One machine with Docker runs the whole stack: Supabase (Postgres,
Auth, REST and Realtime), the Casama API and worker, the sandbox supervisor and egress proxy for bot
computers, the TURN relay for live view, and Caddy for HTTPS. Self-hosted Casama has no paywall and
no usage limits: billing is switched off in the bundled stack.

This page covers what you get, what you need, and how to install. When the server is running, see
[Configuration](/self-hosting/configuration) for every setting and
[Operations](/self-hosting/operations) for upgrades, backups and monitoring.

## What you get

`./install.sh` starts these services from `infra/compose/docker-compose.yml` (Compose project
`casama`):

| Service         | What it does                                                                                                 |
| --------------- | ------------------------------------------------------------------------------------------------------------ |
| `caddy`         | The one public address. Gets TLS certificates automatically and routes requests to the API, Supabase or the web app. |
| `api`           | The Casama API (port 8787 inside the stack), plus Pages on port 8790.                                         |
| `worker`        | Runs bots: chats, routines, memory, connections and scheduled jobs.                                          |
| `db`            | Supabase Postgres 17. Holds all data, including encrypted secrets in Supabase Vault.                         |
| `auth`          | Supabase Auth (accounts, sign-in, two-step sign-in, SAML SSO).                                               |
| `rest`          | PostgREST, used by the apps for reads.                                                                       |
| `realtime`      | Supabase Realtime, which streams chat and run updates to the apps.                                           |
| `kong`          | The Supabase gateway in front of Auth, REST and Realtime.                                                    |
| `migrate`       | Runs once at each start. Waits for Auth and Realtime, then applies Casama's database migrations.             |
| `supervisor`    | Creates, sleeps and wakes bot computers. The only service with access to the Docker socket.                   |
| `egress`        | The only route from computers to the internet. Blocks private, loopback and cloud metadata addresses.        |
| `turn`          | A coturn relay for live view of desktop computers.                                                           |

Optional Compose profiles add more:

| Profile      | Services                                   | Turn it on with                                    |
| ------------ | ------------------------------------------ | -------------------------------------------------- |
| `web`        | The web app at the same address            | `./install.sh --web`                               |
| `monitoring` | Prometheus, node-exporter and Grafana      | `./install.sh --monitoring`                        |
| `search`     | SearXNG, free web search for bots          | `./install.sh --search`                            |
| `backup`     | Daily off-site backups                     | `./install.sh --backups`                           |
| `link`       | `connector`: Casama Link's tunnel, a public address with no domain | `casama selfhost remote on`, see [Use your server on your phone](/self-hosting/remote-access) |
| `pdf`        | Gotenberg, for **Export PDF** on pages     | See [Page PDFs](/self-hosting/configuration#page-pdfs) |
| `s3`         | SeaweedFS, S3-compatible object storage    | See [Object storage](/self-hosting/configuration#object-storage) |
| `images`     | Build-only services for the computer images | Used by the installer                             |

How a request flows:

```text
Apps, CLI, browser
        |
        v
  Caddy :80/:443 --- /v1, /hooks, /link, /oauth, /mcp, /a2a, ----> api :8787
        |      |     /links, /telephony, /healthz, /readyz, /.well-known/...
        |      \---- /auth/v1, /rest/v1, /realtime/v1 --------> kong ---> auth, rest, realtime
        |       \--- everything else ------------------------> web (profile "web")
  Caddy :8790 ------ Pages (bots' web pages, own origin) ------> api :8790

  worker ---> supervisor ---> computer containers (one private network each)
                                   |-- internet only through egress
                                   \-- live view media only through turn :3478
```

Bot computers are Docker containers named `casama-c-<id>`. They run as a non-root user with a
read-only root filesystem, no Linux capabilities, CPU, memory and process limits, and a private
network whose only way out is the egress proxy. See [Computer providers](/self-hosting/computers)
for details and for running computers on E2B, Daytona, Kubernetes and others.

## Requirements

| What        | Minimum                                                                                                    |
| ----------- | ---------------------------------------------------------------------------------------------------------- |
| OS          | Linux with Docker Engine. macOS with Docker Desktop works for trials.                                      |
| Docker      | Docker Engine with Docker Compose v2 (`docker compose`). Your user must be able to run `docker`.           |
| Tools       | `git`, `bash`, `openssl` and `curl`                                                                        |
| CPU and RAM | 4 vCPU and 8 GB RAM for a few computers at once. Plan on about 2 GB RAM per running computer.             |
| Disk        | 40 GB or more. The images take about 10 GB; home folders and snapshots take the rest.                      |
| Domain      | For a public server, a DNS name (for example `casama.example.com`) pointing at the machine.               |

The installer warns when the machine has less than about 8 GB of memory, because computers may not
start reliably.

### Ports

| Port            | Protocol  | Used for                                                              |
| --------------- | --------- | --------------------------------------------------------------------- |
| 80              | TCP       | HTTP, and Let's Encrypt certificate checks                            |
| 443             | TCP       | HTTPS: the API, Supabase and the web app                              |
| 3478            | UDP, TCP  | TURN relay for live view                                              |
| 8790            | TCP       | Pages, when you serve them on a port instead of their own domain      |
| 127.0.0.1:3001  | TCP       | Grafana (monitoring profile), on the loopback interface only          |

For a public server, open 80, 443 and 3478 (UDP and TCP) in your firewall. With `--local`, nothing
needs to be reachable from other machines. To use a `--local` server from your phone without a
domain or open ports, see [Use your server on your phone](/self-hosting/remote-access).

### Domain and TLS

With `--domain`, Caddy requests a certificate for that name the first time it starts. Before you
install, make sure:

- the domain's A (or AAAA) record points at the server, and
- ports 80 and 443 are reachable from the internet.

If another proxy already terminates TLS in front of the machine, see
[Behind another proxy](/self-hosting/configuration#behind-another-proxy).

## Install

1. Clone the repository on the server:

   ```sh
   git clone https://github.com/stackwares/casama && cd casama
   ```

2. Run the installer with your domain:

   ```sh
   ./install.sh --domain casama.example.com
   ```

   For a trial on your own computer, use `./install.sh --local` instead.

3. Wait for the installer to finish. It prints the address when the API is ready:

   ```text
   Casama is running at https://casama.example.com
   ```

4. Back up `infra/compose/.env` somewhere safe. It holds every key for this installation.

The installer:

1. Checks that Docker, Docker Compose v2 and OpenSSL are available and that Docker is running.
2. On Linux, uses gVisor (`runsc`) for computers if Docker lists it as a runtime.
3. Generates every secret with OpenSSL and writes `infra/compose/.env` (mode 600). This includes the
   database passwords, the Supabase JWT secret and keys, a SAML signing key, the tokens the
   services use to talk to each other, and the server key for encryption at rest
   (`CONTENT_ENCRYPTION_KEY`, unless AWS KMS is set). Back that key up: encrypted data can't be read
   without it.
4. Pulls the Supabase, Caddy and other images (two at a time, with up to five retries, because
   public registries rate-limit anonymous pulls).
5. Builds the Casama images: `api` (shared by the worker), `supervisor`, `egress`, `turn` and the
   headless computer image. With `--pull`, it downloads the published images from
   `ghcr.io/stackwares/casama` instead.
6. Starts the stack and waits up to three minutes for `/readyz` to answer.

A fresh install that builds every image from scratch takes a few minutes, plus the time to download
about 3 GB of third-party images. Re-running it with images in place takes about a minute.

### Installer options

| Option              | What it does                                                                                                             |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `--domain <name>`   | Public server at `https://<name>` with automatic HTTPS. Sets `CASAMA_SITE` to the domain and the TURN host to the domain. |
| `--local`           | This machine only, over plain HTTP. The address is `http://localhost` (or `http://localhost:<port>`).                     |
| `--http-port <n>`   | The host port for HTTP (default `80`). Mostly useful with `--local`, for example `--local --http-port 8080`.             |
| `--with-desktop`    | Also builds the desktop computer image, needed for live view and desktop apps. Slower.                                    |
| `--monitoring`      | Adds the `monitoring` profile: Prometheus, node-exporter and Grafana.                                                    |
| `--web`             | Adds the `web` profile: the Flutter web app at the same address. The build runs Flutter in Docker and takes a while.     |
| `--search`          | Adds SearXNG and points the worker at it, so bots can search the web without a search key.                      |
| `--pull [tag]`      | Pulls published images from `ghcr.io/stackwares/casama` instead of building them. The tag defaults to `latest`.          |
| `--behind-proxy`    | TLS ends at a tunnel or another proxy. Needs `--domain`. Caddy listens on loopback only (`HTTP_BIND=127.0.0.1`).          |
| `--turn-host <name>` | The name or IP clients use for live view, when it differs from `--domain`. Needs UDP and TCP 3478 open to that host.   |
| `--admin-email <list>` | Comma-separated instance admin emails (`INSTANCE_ADMIN_EMAILS`).                                                      |
| `--settings <file>` | Merges `KEY=VALUE` lines from a file into `.env`. Comments and blank lines are skipped.                                 |
| `--backups`         | Adds the `backup` profile: a daily encrypted upload. See [Operations](/self-hosting/operations#off-site-backups).         |
| `--no-start`        | Writes `.env` and builds or pulls the images, but doesn't start the stack.                                               |
| `-h`, `--help`      | Prints the usage.                                                                                                        |

With neither `--domain` nor `--local`, the installer asks for a domain. An empty answer (or no
terminal) means a local install.

To force clean image builds, set `CASAMA_BUILD_FLAGS`, which is passed to `docker compose build`:

```sh
CASAMA_BUILD_FLAGS=--no-cache ./install.sh
```

::: warning Re-running keeps your settings
When `infra/compose/.env` exists, the installer keeps it as is and only adds settings that newer
releases introduced. `--domain`, `--local` and `--http-port` have no effect on a re-run. To change
the address later, edit the settings in [Core and URLs](/self-hosting/configuration#core-and-urls).
`--pull`, `--behind-proxy`, `--turn-host`, `--admin-email`, `--settings` and `--backups` do apply
on a re-run.
:::

### `--local` versus `--domain`

|                     | `--local`                               | `--domain casama.example.com`                 |
| ------------------- | --------------------------------------- | --------------------------------------------- |
| Address             | `http://localhost[:port]`               | `https://casama.example.com`                  |
| TLS                 | None                                    | Automatic (Let's Encrypt through Caddy)       |
| Who can reach it    | This machine                            | Anyone who can reach the domain               |
| Sign-up allowlist   | Not available (needs an https hook URL) | Available                                     |
| Live view TURN host | `localhost`                             | The domain                                    |

### The same steps from the CLI

The [Casama CLI](/develop/cli) wraps the installer:

```sh
casama selfhost init --dir ~/casama --domain casama.example.com
```

`init` takes `--domain`, `--local`, `--http-port`, `--with-desktop` and `--monitoring`. For `--web`
or `--no-start`, run `./install.sh` directly. Every `casama selfhost` command finds the checkout
through `--dir`, then the `CASAMA_SELFHOST_DIR` environment variable, then the current directory.

## First sign-in and the instance owner

The first account created on a new server becomes the **instance owner**. Owners get the admin
console under Settings, where they can see the health of each service, manage workspaces and check
for updates.

The admin console locks after five minutes without activity, when the app goes into the
background, and when you leave it. **Lock now** locks it immediately. Unlock with your account
password or an emailed one-time code (emailed codes require SMTP); an account with two-step
sign-in also enters its authenticator code. The rest of the app stays signed in. Admin changes
ask you to confirm with a fresh sign-in, at most once every 45 seconds.

Where the app can use your passkeys (the web, and the iPhone and Android apps on servers whose
passkeys are for `casama.ai`), **Verify with a passkey** comes first: one Face ID, fingerprint or
device passcode prompt instead of typing your password. It is a real sign-in, so the server
accepts it; an account with two-step sign-in still enters its authenticator code after it,
because a passkey sign-in counts as one step. On a phone or computer with Face ID, a fingerprint
reader or Windows Hello, coming back to a locked console also offers **Unlock with Face ID or
fingerprint** while your last sign-in is less than about four and a half minutes old. That only
lifts the app's own lock: the server can't check it, so changes still ask for a fresh sign-in.

The API independently requires a sign-in from the last five minutes for admin reads and the
last minute for changes, and the two-step code when the account has an authenticator. Token
refresh does not extend these windows, so even an active console occasionally asks you to verify
again. The same one-minute check applies to approving the admin bot's actions, to making a
scan-to-sign-in code as an instance owner, and to changing a gallery request. API and CLI callers
must authenticate again when receiving `admin_reauthentication_required` or
`admin_confirmation_required` (HTTP 403). Custom authentication hooks must preserve the signed
`amr` authentication methods and timestamps and the `aal` claim; missing proof is refused, even
when the token itself has just been issued. The owner-only overview used to discover the console
in Settings remains available with the ordinary session; its aggregate instance counts remain
visible without unlocking.

1. Open the Casama app and point it at your server (see the next section).
2. Create an account with email and password.
3. Add a model key (or a local model endpoint) and create your first bot.

A new server doesn't send email, so start with a password: emailed sign-in links need
[SMTP](/self-hosting/configuration#email). New accounts are confirmed automatically until you turn
email confirmation on.

To name the owners explicitly instead, set `INSTANCE_ADMIN_EMAILS` to a comma-separated list of
emails in `infra/compose/.env`, then run `casama selfhost up`.

## Connect the apps and the CLI

**In the app** (iOS, iPadOS, Android, macOS, Windows, Linux):

1. On the sign-in screen, tap **More options**.
2. Tap the **Server** chip, which shows the current server.
3. Enter your server's address, for example `https://casama.example.com`, and tap **Connect**.

The app remembers the address. If it can't reach a server, the error screen also offers **Use a
different server**. The web app (`--web`) always uses the address it's served from.

**With the CLI:**

```sh
casama config --api-url https://casama.example.com
casama signup --email you@example.com     # or: casama login --email you@example.com
```

You can also pass the address for a single command with the global `--api` option
(`casama --api https://casama.example.com login --email you@example.com`) or set `CASAMA_API_URL`.

## Run a server on your own computer

The desktop app on macOS and Linux (not the Mac App Store version) sets up a local server for you,
one step at a time. On the sign-in screen, tap **Run on This Mac** (**Run on This Computer** on
Linux):

1. **Docker.** The app looks for Docker by itself. If it's missing, **Download Docker Desktop**
   gets the installer for your Mac's chip; on Linux it opens Docker's install guide. If Docker is
   installed but closed, the app opens it. The page moves on by itself once Docker runs.
2. **Server.** Tap **Start**. The first start downloads about 10 GB and takes 5 to 10 minutes.
   **Show Details** shows the installer's own lines.
3. **Account.** Your name, an email and a password. No email is sent; the first account is the
   instance owner.
4. **AI model.** Sign in with a ChatGPT plan, or paste a model key (or a local Ollama address).
   You can skip this and add one later under **Settings → Model keys**.
5. **Phone.** Turn on [Casama Link](/self-hosting/remote-access), approve it in your browser
   with a free Casama Cloud account, and scan the code with your phone's camera. The page says
   **Phone connected** when the phone has signed in.

You can close the setup or quit the app at any step; it opens again at the step it reached. If you
skip the model or the phone, a **Finish setting up** card on the home page takes you back.

On Linux, when Docker runs but your user may not use it, the page shows the command that fixes it
(`sudo usermod -aG docker $USER`, then log out and back in).

For the server step, the app downloads the source of the release whose
images are published (the `selfhost` tag) into its support folder, and runs
`install.sh --local --pull <that release>`, which pulls the published images instead of building
them. The first start downloads about 10 GB of images, so it needs that much free disk. Then it waits for the server and connects to
`http://localhost:8080`. If a port is taken (8080, 8443, 8790 or TURN's 3478), it picks the next
free one and keeps it. Every port listens on `127.0.0.1` only, so only this computer can reach it.
If a server already answers there, it connects right away. Closing the setup while it installs
stops the installer; starting again picks up where it left off.

Windows isn't supported yet (the installer needs bash and OpenSSL). Use WSL and `./install.sh --local`.

The setup's last step connects your phone. To do it later, turn on Casama Link under
**Settings → Casama Link → Use on Your Phone**. See [Use your server on your phone](/self-hosting/remote-access).

## Other ways to deploy

| Method                      | What runs                                                   | Computers                                                      | Where to start                         |
| --------------------------- | ----------------------------------------------------------- | -------------------------------------------------------------- | -------------------------------------- |
| `install.sh` (recommended)  | Everything on one Docker host                               | Docker on the same host, or another provider                   | This page                              |
| Coolify                     | The same compose file, through Coolify                      | Docker on the Coolify server                                   | `deploy/coolify/README.md`             |
| Kubernetes (Helm)           | API, worker, supervisor and optionally the web app          | Pods in their own namespace                                    | [Helm chart](/self-hosting/operations#kubernetes-with-helm) |
| Render, Railway, DigitalOcean App Platform | API and worker only                          | [Casama Link](/self-hosting/casama-link-cloud), the desktop companion, or a supervisor elsewhere | `deploy/README.md`                     |

### Coolify

Coolify runs Docker Compose stacks with the Docker socket, so it can host the full stack.

1. On the Coolify server, run `./install.sh --no-start --domain casama.example.com` once from a
   checkout to generate `infra/compose/.env`.
2. In Coolify, create a Docker Compose resource from the repository with the compose file
   `infra/compose/docker-compose.yml`, and paste the variables from `infra/compose/.env`.
3. Let Coolify's proxy route your domain to the `caddy` service on port 80 and set
   `CASAMA_SITE=:80`, because Coolify terminates TLS.
4. Build the computer image once on the server:

   ```sh
   docker compose -f infra/compose/docker-compose.yml --profile images build computer-headless
   ```

### Templates for Coolify, Dokploy and CasaOS (not yet tested)

`deploy/` also has templates that use published images only, so nothing is built on the server:
`deploy/coolify/casama.yaml`, `deploy/dokploy/` and `deploy/casaos/`. Coolify and Dokploy generate
the secrets; CasaOS can't, so `deploy/casaos/setup.sh` does it once. These have been checked to
parse but have not been run end to end on those platforms. Each folder's README lists what is still
unchecked. Until they are, the steps above are the supported way.

### Render, Railway and DigitalOcean App Platform

These platforms have no Docker socket, so they run only the API and worker, against a Supabase
project (Supabase Cloud or your own Supabase) for Postgres and Auth. Bots get computers from
[Casama Link](/self-hosting/casama-link-cloud), from people's own machines through the
[desktop companion](/guide/companion), or from a supervisor you run elsewhere (`SUPERVISOR_URL` and
`SUPERVISOR_TOKEN`).

| Platform                  | File                          | Notes                                                    |
| ------------------------- | ----------------------------- | -------------------------------------------------------- |
| Render                    | `deploy/render/render.yaml`   | Blueprint: an API web service and a worker               |
| Railway                   | `deploy/railway/railway.json` | Two services from the same repository; set `MODE` on each |
| DigitalOcean App Platform | `deploy/digitalocean/app.yaml`| `doctl apps create --spec deploy/digitalocean/app.yaml`   |

Before the first start, apply the migrations to the Supabase database from a checkout:

```sh
supabase db push --db-url "$DATABASE_URL"
```

Every platform needs `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_JWT_SECRET`
(from the Supabase project settings), `INTERNAL_TOKEN` (32 or more random characters) and
`PUBLIC_APP_URL`. On Railway, the API service sets `MODE=api` and `PORT=8787`; the worker sets
`MODE=worker` and `API_INTERNAL_URL` to the API's private address on port 8787.

## Production hardening

### Use gVisor for computers

gVisor (`runsc`) gives each computer its own kernel boundary. Install it on the Linux host and
register it with Docker (see the gVisor documentation), then check that Docker lists it:

```sh
docker info | grep -i runsc
```

A first install picks it up automatically. On an existing install, set it yourself:

1. In `infra/compose/.env`, set `SANDBOX_RUNTIME=runsc`.
2. Run `casama selfhost up`.

New computers start under gVisor. Running computers keep their runtime until they sleep and wake.

Without gVisor, computers use Docker's default runtime (runc) together with the other controls: a
non-root user, a read-only root filesystem, no capabilities, `no-new-privileges`, per-computer
networks, the egress proxy and resource limits.

### Run computers on a second host

For public servers, keep untrusted code and the Docker socket off the machine that holds your data.
Run the supervisor, egress proxy and TURN relay on a second host, and point the API and worker at it
over a private network or WireGuard. See
[Run computers on a separate host](/self-hosting/operations#run-computers-on-a-separate-host).

### Firewall

- Allow inbound 80/tcp, 443/tcp and 3478 (UDP and TCP) only. Allow 8790/tcp only if you serve Pages
  on a port.
- Keep Grafana on the loopback interface and reach it through an SSH tunnel.
- Never expose the supervisor (8788), the API's internal port (8787) or Postgres to the internet.
- Docker's published ports bypass some host firewalls (ufw, for example). Check from another
  machine that only the ports above answer.

### Other checks

- Serve Pages from their own domain, so bots' pages never share an origin with Casama. See
  [Pages](/self-hosting/configuration#core-and-urls).
- Turn on email confirmation and set up [SMTP](/self-hosting/configuration#email).
- Restrict who can sign up with `DISABLE_SIGNUP` or the
  [sign-up allowlist](/self-hosting/configuration#sign-ups-and-allowlists).
- Set up [encrypted backups](/self-hosting/operations#back-up-your-server) and copy them off the
  machine.
- Consider [encryption at rest](/self-hosting/configuration#encryption-keys) for workspace content.
- Keep `COMPUTER_HOST_MEMORY_GB` at a number the machine can hold. See
  [Server capacity](/self-hosting/operations#server-capacity).

## Related

- [Configuration](/self-hosting/configuration)
- [Operations](/self-hosting/operations)
- [Computer providers](/self-hosting/computers)
- [Use your server on your phone](/self-hosting/remote-access)
- [Troubleshooting](/self-hosting/troubleshooting)
- [Quick start](/quick-start)
- [CLI](/develop/cli)
