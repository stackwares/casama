# CasaOS

CasaOS (and ZimaOS) run Docker Compose apps and let them use the Docker socket, so the full
stack can run there, bot computers included. The machine needs 8 GB of memory or more.

CasaOS cannot generate secrets. Apps in its store ship fixed passwords in the compose file. That
is not safe for Casama: its keys sign every sign-in. So this is a custom install with one
first-run step, not a store app.

| File | What it is |
| --- | --- |
| [`docker-compose.yml`](docker-compose.yml) | The stack with `x-casaos` details. Every `${...}` is a placeholder. |
| [`setup.sh`](setup.sh) | The first-run step: fills in the placeholders |

It has not been run end to end on CasaOS yet. The compose file parses
(`deploy/check-templates.sh`) and `setup.sh` was run into a test folder. The rest of this page
says what is still unchecked.

## Install

1. Open a terminal on the CasaOS machine (SSH, or the terminal in CasaOS) and get the repository:

   ```sh
   curl -L https://github.com/stackwares/casama/archive/refs/heads/main.tar.gz | tar xz
   cd casama-main
   ```

2. Run the first-run step. It starts nothing.

   ```sh
   sudo deploy/casaos/setup.sh
   ```

   It generates every secret with OpenSSL, the same way `install.sh` does. It copies the config
   files to `/DATA/AppData/casama/config`. It writes two files:

   - `/DATA/AppData/casama/casama.env`: the secrets and settings. Back it up.
   - `/DATA/AppData/casama/docker-compose.yml`: the file to import, with the values filled in.

3. In CasaOS, open **App Store > Custom Install**, choose **Import**, and paste the contents of
   `/DATA/AppData/casama/docker-compose.yml`. Then install. The first start downloads about 10 GB
   of images.
4. Point the Casama app or CLI at the address `setup.sh` printed, for example
   `http://192.168.1.50:8480`, and create an account. The first account is the instance owner.

Both files hold every key for this installation. Keep them private.

## Addresses

CasaOS itself uses port 80, so Casama listens on other ports, over plain HTTP:

| Port | Used for |
| --- | --- |
| 8480 (TCP) | The API and Supabase. This is the address the apps use. |
| 8790 (TCP) | Bots' web pages |
| 3478 (UDP and TCP) | Live view of desktop computers |

`setup.sh` uses the machine's first IP address. To use another address or port, pass options:

```sh
sudo deploy/casaos/setup.sh --url https://casama.example.com \
  --pages-url https://pages.casama.example.com --turn-host 203.0.113.7
```

Then import the new file in CasaOS again. Use an `https` address only when something in front of the machine
ends TLS and forwards to port 8480 (a reverse proxy or a tunnel). Running `setup.sh` again keeps
every secret and only changes the settings you pass. `--help` lists all options.

## Change a setting

Email, extra admins and other settings are plain values in the compose file. Edit them in CasaOS
(the app's **Settings**) or in `/DATA/AppData/casama/docker-compose.yml` before you import it. If
you run `setup.sh` again, it writes that file again, so make your edits again too.
[Configuration](../../docs-site/self-hosting/configuration.md) lists every setting.

## How it differs from `install.sh`

- No HTTPS of its own: Caddy serves plain HTTP on port 8480.
- The `migrations` service copies the database migrations out of the server image, so they
  always match the API.
- The config files come from the repository copy you ran `setup.sh` from. Run it again after you
  update that copy.
- No profiles: no monitoring, search, backups, web app, PDF export or Casama Link connector.

## Not checked on a real machine

- That CasaOS imports the file and starts the services in order. The stack uses
  `depends_on` with `service_completed_successfully` and `service_healthy`.
- That CasaOS keeps named volumes and file mounts as written.
- That the Casama apps on a phone accept a plain `http` address on your network. If they do
  not, put HTTPS in front and pass `--url`.

## Why not the CasaOS app store

The store file goes to `Apps/Casama/docker-compose.yml` in
[IceWhaleTech/CasaOS-AppStore](https://github.com/IceWhaleTech/CasaOS-AppStore). Their rules: the
file must pass `docker compose config -q`, and it needs a top-level `x-casaos` block with an id,
title, icon, category and version. This compose file meets both once filled in. But a store app
is the same file for everyone, with no step that makes secrets, so it would ship the same keys to
every install. Do not submit it until CasaOS can generate values at install time.
