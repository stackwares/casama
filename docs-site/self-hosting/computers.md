# Computer providers

Every bot can have its own Linux computer: a shell, files, a browser and, with the desktop image, a
screen you can watch live. The sandbox supervisor creates these computers through a **provider**.
The default provider runs them as Docker containers on your server. You can also run them on E2B,
Daytona, Novita, Kubernetes, Incus, Boat or Railway, on Casama Cloud through Cloud Connect, or on
people's own machines through the desktop companion.

This page covers each provider's setup and settings, the computer images, the egress proxy, the
TURN relay for live view, and resource limits. For what computers do for bots, see
[Computers](/guide/computers).

## How providers fit together

The API and worker talk to one supervisor (`SUPERVISOR_URL`, `SUPERVISOR_TOKEN`). The supervisor
holds the object store and the secret that derives each computer's tokens, so every provider runs
inside it:

- **Docker** runs on the supervisor's own Docker host. It's set up when it's the default provider.
- **Hosted providers** (E2B, Daytona, Novita, Kubernetes, Incus, Boat, Railway) are turned on by
  their settings on the supervisor. Each starts Casama's own computer image with `computerd` inside,
  so files, commands, checkpoints, sleep and wake, and live view work the same everywhere.
- **Casama Cloud** (`casama-cloud`) is set up on the API and worker, not the supervisor. See
  [Cloud Connect computers](#cloud-connect-computers).
- **People's own machines** (`local`) connect through the desktop companion. It's on by default
  (`LOCAL_COMPUTERS`). See [Companion](/guide/companion).

Each computer records its provider when it's created. `DEFAULT_PROVIDER` on the supervisor decides
where computers go that ask for the default (`docker`), which is what the apps do. A computer
created through the API can name another provider in its `provider` field, as long as that provider
is configured on the supervisor.

::: warning Settings go on the supervisor
The bundled compose file passes only the Docker settings to the `supervisor` service. To use a
hosted provider, add its settings to `services.supervisor.environment` in
`infra/compose/docker-compose.yml` (see
[Advanced settings](/self-hosting/configuration#advanced-settings)), then run
`casama selfhost up`.
:::

To send every new computer to a hosted provider, set its settings and `DEFAULT_PROVIDER`, for
example:

```yaml
# infra/compose/docker-compose.yml, under services.supervisor.environment
DEFAULT_PROVIDER: e2b
E2B_API_KEY: ${E2B_API_KEY:-}
```

With a hosted default, the supervisor doesn't set up Docker at all, so it needs no Docker socket.
The supervisor refuses to start if `DEFAULT_PROVIDER` names a provider that isn't configured.

## Docker

The default. Each computer is a container named `casama-c-<id>` with its own volume for
`/home/casama` and its own internal Docker network. The supervisor joins that network to reach
`computerd`, the egress proxy joins it to give the computer internet access, and the TURN relay
joins desktop computers' networks for live view.

Every container runs with:

- user `1000:1000`, a read-only root filesystem, and `/tmp` as a 1 GB in-memory filesystem;
- all Linux capabilities dropped and `no-new-privileges`;
- CPU, memory (swap capped at the same amount) and a 512-process limit;
- `HTTP_PROXY` and `HTTPS_PROXY` pointing at the egress proxy with per-computer credentials.

### gVisor on Linux

With gVisor (`runsc`), each computer gets a user-space kernel between it and the host. The installer
sets `SANDBOX_RUNTIME=runsc` on the first run when `docker info` lists `runsc`. To add it later,
install gVisor, register it with Docker, set `SANDBOX_RUNTIME=runsc` in `infra/compose/.env` and run
`casama selfhost up`. Computers pick it up the next time they start.

### Docker settings

| Name                      | Compose default                         | What it does                                                                 |
| ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------- |
| `SANDBOX_RUNTIME`         | Set by the installer                    | Docker runtime for computers (`runsc` for gVisor). Empty: Docker's default.  |
| `COMPUTER_IMAGE_HEADLESS` | `<CASAMA_REGISTRY>/computer-headless:<CASAMA_VERSION>` | Image for headless computers. `casama/computer-headless:local` unless you installed with `--pull`. |
| `COMPUTER_IMAGE_DESKTOP`  | `<CASAMA_REGISTRY>/computer-desktop:<CASAMA_VERSION>`  | Image for desktop computers.                                                 |
| `COMPUTER_MEMORY_MB`      | `2048`                                  | Memory for each new computer.                                                |
| `COMPUTER_CPUS`           | `1` (not passed by Compose)             | CPUs for each new computer.                                                  |
| `WARM_POOL_SIZE`          | `0`                                     | Started headless computers kept waiting. See [Scaling](/self-hosting/operations#scaling). |
| `DOCKER_SOCKET`           | `/var/run/docker.sock`                  | The Docker socket the supervisor uses.                                       |
| `EGRESS_CONTAINER`        | `casama-egress`                         | Container name of the egress proxy.                                          |
| `EGRESS_CONTROL_URL`      | `http://casama-egress:3129`             | The egress proxy's control API.                                              |
| `EGRESS_CONTROL_TOKEN`    | Generated                               | Token for the control API.                                                   |
| `TURN_CONTAINER`          | `casama-turn`                           | Container name of the TURN relay.                                            |
| `SUPERVISOR_CONTAINER`    | `casama-supervisor`                     | The supervisor's own container name, so it can join computer networks.       |
| `COMPUTER_TOKEN_SECRET`   | Generated                               | Derives each computer's tokens. Don't change it on a running server.         |

Compose names the egress proxy, TURN relay and supervisor containers explicitly, so you can't run
two Casama stacks on one Docker host.

## E2B

Runs computers as E2B sandboxes from templates built from Casama's images.

1. Build E2B templates from the headless image (and the desktop image for live view), with
   `computerd` as the start command. Name them `casama-computer-headless` and
   `casama-computer-desktop`, or set the names below.
2. Add the settings to the supervisor and run `casama selfhost up`.

| Name                    | Default                     | What it does                    |
| ----------------------- | --------------------------- | ------------------------------- |
| `E2B_API_KEY`           | (empty)                     | Turns the provider on.          |
| `E2B_API_URL`           | `https://api.e2b.app`       | E2B API address.                |
| `E2B_TEMPLATE_HEADLESS` | `casama-computer-headless`  | Template for headless computers. |
| `E2B_TEMPLATE_DESKTOP`  | `casama-computer-desktop`   | Template for desktop computers.  |

## Daytona

Runs computers from Daytona snapshots built from Casama's images.

| Name                         | Default                         | What it does                     |
| ---------------------------- | ------------------------------- | -------------------------------- |
| `DAYTONA_API_KEY`            | (empty)                         | Turns the provider on.           |
| `DAYTONA_API_URL`            | `https://app.daytona.io/api`    | Daytona API address.             |
| `DAYTONA_ORGANIZATION_ID`    | (empty)                         | Your Daytona organization.       |
| `DAYTONA_SNAPSHOT_HEADLESS`  | `casama-computer-headless`      | Snapshot for headless computers. |
| `DAYTONA_SNAPSHOT_DESKTOP`   | `casama-computer-desktop`       | Snapshot for desktop computers.  |

## Novita

Novita Agent Sandbox is E2B-compatible: build templates from the images as for E2B.

| Name                       | Default                            | What it does                     |
| -------------------------- | ---------------------------------- | -------------------------------- |
| `NOVITA_API_KEY`           | (empty)                            | Turns the provider on.           |
| `NOVITA_API_URL`           | `https://api.sandbox.novita.ai`    | Novita API address.              |
| `NOVITA_TEMPLATE_HEADLESS` | `casama-computer-headless`         | Template for headless computers. |
| `NOVITA_TEMPLATE_DESKTOP`  | `casama-computer-desktop`          | Template for desktop computers.  |

## Image-based providers

Kubernetes, Incus, Boat and Railway run the computer images directly from a registry. They share
two settings:

| Name                    | Default                                          | What it does                    |
| ----------------------- | ------------------------------------------------ | ------------------------------- |
| `HOSTED_IMAGE_HEADLESS` | `ghcr.io/stackwares/casama/computer-headless:latest`    | Image for headless computers.   |
| `HOSTED_IMAGE_DESKTOP`  | `ghcr.io/stackwares/casama/computer-desktop:latest`     | Image for desktop computers.    |

If you build your own images, push them to a registry these providers can pull from and set both.

### Kubernetes

One pod per computer, created in a namespace through the Kubernetes API. Inside the cluster, the
supervisor uses its service account and reaches pods by IP; outside, it uses the API server's pod
proxy. The [Helm chart](/self-hosting/operations#kubernetes-with-helm) sets this up for you.

| Name                     | Default                         | What it does                                                         |
| ------------------------ | ------------------------------- | -------------------------------------------------------------------- |
| `K8S_NAMESPACE`          | (empty)                         | Turns the provider on: the namespace for computer pods.             |
| `K8S_API_URL`            | The in-cluster API server       | API server address, when the supervisor runs outside the cluster.   |
| `K8S_TOKEN`              | The pod's service account token | Bearer token for the API server.                                    |
| `K8S_CA_FILE`            | The pod's service account CA    | CA certificate file for the API server.                             |
| `K8S_IMAGE_PULL_SECRET`  | (empty)                         | Image pull secret for computer pods.                                |
| `K8S_RUNTIME_CLASS`      | (empty)                         | Runtime class for computer pods, for example gVisor or Kata.        |

The supervisor needs `create`, `get`, `list` and `delete` on pods, and access to `pods/proxy`, in
that namespace.

### Incus

A container per computer, pulled from an OCI registry and reached on the instance's IPv4 address.

| Name                      | Default             | What it does                                                         |
| ------------------------- | ------------------- | -------------------------------------------------------------------- |
| `INCUS_URL`               | (empty)             | Turns the provider on: the Incus API address, for example `https://incus.example.com:8443`. |
| `INCUS_TOKEN`             | (empty)             | Bearer token. Or use a client certificate:                          |
| `INCUS_CLIENT_CERT_FILE`  | (empty)             | Client certificate file.                                            |
| `INCUS_CLIENT_KEY_FILE`   | (empty)             | Client key file.                                                    |
| `INCUS_CA_FILE`           | (empty)             | CA certificate for the Incus server.                                |
| `INCUS_REGISTRY`          | `https://ghcr.io`   | Registry the images come from. The `ghcr.io/` part of the image names is dropped. |
| `INCUS_PROJECT`           | (empty)             | Incus project.                                                       |

### Boat

A VM per computer. Boat doesn't run OCI images, so the VM runs the computer image with Docker.

| Name                 | Default                     | What it does              |
| -------------------- | --------------------------- | ------------------------- |
| `BOAT_API_KEY`       | (empty)                     | Turns the provider on.    |
| `BOAT_API_URL`       | `https://boat.dev/api/v1`   | Boat API address.         |
| `BOAT_SANDBOX_TYPE`  | (empty)                     | Boat sandbox type.        |

### Railway

A Railway service per computer, in one project and environment, with a Railway domain per port.

| Name                      | Default   | What it does                                                    |
| ------------------------- | --------- | --------------------------------------------------------------- |
| `RAILWAY_TOKEN`           | (empty)   | Railway API token. With the next two, turns the provider on.    |
| `RAILWAY_PROJECT_ID`      | (empty)   | Project for computer services.                                  |
| `RAILWAY_ENVIRONMENT_ID`  | (empty)   | Environment for computer services.                              |
| `RAILWAY_TOKEN_KIND`      | (account) | `project` when `RAILWAY_TOKEN` is a project token.              |

### What changes on hosted providers

- **Internet access.** Hosted computers use the provider's own network, so the egress proxy's
  private-range blocking doesn't apply.
- **Live view** needs the TURN relay to be reachable from the internet. The supervisor gives hosted
  computers `TURN_PUBLIC_HOST` and `TURN_PORT`.
- **Resource limits.** `COMPUTER_MEMORY_MB` and `COMPUTER_CPUS` apply to Docker only. Hosted
  providers set CPU and memory only for a computer with its own size; otherwise the provider's
  defaults apply.
- **The warm pool** is Docker only.
- Archives on sleep still go to the supervisor's object store.

## Cloud Connect computers

With `CASAMA_CLOUD_URL` and `CASAMA_CLOUD_KEY` set on the API and worker, computers created with the
`casama-cloud` provider run on Casama Cloud, and their time is billed to the Casama Cloud workspace
that made the key. Live view and terminals aren't available for them. See
[Cloud Connect](/guide/cloud-connect) and
[Configuration](/self-hosting/configuration#cloud-connect).

## Images

Casama has two computer images, both built from `infra/images/computer/`:

| Image                       | Contents                                                                                   |
| --------------------------- | ------------------------------------------------------------------------------------------ |
| `computer-headless`         | Ubuntu 24.04, `computerd`, shell tools, git, Node.js 24, Python 3, Chromium, agent-browser, LibreOffice, pandoc, Poppler, qpdf and Tesseract |
| `computer-desktop`          | The headless image plus an X server, a window manager, accessibility tools, a text editor and the Neko WebRTC streamer for live view |

The installer always builds the headless image, or pulls it with `--pull`. Get the desktop image
with `./install.sh --with-desktop`, or build it on its own:

```sh
COMPOSE_PROFILES=images docker compose -f infra/compose/docker-compose.yml --env-file infra/compose/.env build computer-desktop
```

Compose tags them `${CASAMA_REGISTRY}/computer-headless:${CASAMA_VERSION}` and
`${CASAMA_REGISTRY}/computer-desktop:${CASAMA_VERSION}` (by default `casama/...:local`; with
`--pull`, `ghcr.io/stackwares/casama/...` at the pulled tag). To build them outside Compose:

```sh
docker build -f infra/images/computer/Dockerfile.headless -t casama/computer-headless:dev .
docker build -f infra/images/computer/Dockerfile.desktop \
  --build-arg BASE=casama/computer-headless:dev -t casama/computer-desktop:dev .
```

Both build on x86-64 and ARM64. `computerd` listens on port 7070; the headless image starts it
with `CMD ["computerd"]`, and the desktop image with `desktop-start`.

Rebuild or pull the images after each upgrade (the installer does this for the headless image, and
for the desktop image with `--with-desktop`). A computer picks up a new image the next time it sleeps and
wakes. For hosted providers, rebuild your templates, snapshots or registry images too.

## The egress proxy

The `egress` service is the only route from Docker computers to the internet. It's an HTTP forward
proxy (plain requests and `CONNECT`):

- Each computer authenticates with its own credentials, so the proxy knows which computer made each
  connection.
- It resolves host names itself and refuses if any address is private, loopback, link-local (cloud
  metadata), CGNAT, multicast or reserved, including IPv4-mapped IPv6. It then connects to the
  address it checked, which defeats DNS rebinding.
- Non-HTTP traffic, such as SSH, has no route out.
- `EGRESS_BLOCKED_CIDRS` on the `egress` service adds more ranges to block.
- `EGRESS_ABUSE=on` also refuses outbound mail ports and crypto-mining traffic and reports it. It's
  off on self-hosted servers by default.

Computers can't reach your LAN through the proxy. `OUTBOUND_ALLOW_CIDRS` lets the API and worker
reach LAN services, not computers.

## TURN for live view

Live view streams a desktop computer's screen over WebRTC through the `turn` service (coturn).
Viewers always use the relay; media flows viewer ↔ relay ↔ computer, so the computer is never
reachable from outside. The relay refuses every peer address except its own, so it can't be used
to reach other hosts.

1. Build the desktop image (`./install.sh --with-desktop`).
2. Open port 3478, UDP and TCP, on the server. Compose publishes both.
3. Make sure `TURN_PUBLIC_HOST` is a name viewers can resolve to the server. The installer sets it to
   your domain, or `localhost` for `--local`.

The streamer starts with the first viewer and stops 60 seconds after the last one leaves
(`STREAM_IDLE_STOP_MS` on the supervisor). Credentials are short-lived and derived from
`TURN_SECRET`. The bundled relay doesn't serve TLS (`turns:` on 5349), so viewers on networks that
block UDP and port 3478 can't connect.

## Resource limits

| Limit              | Docker default                    | Set with                                     |
| ------------------ | --------------------------------- | -------------------------------------------- |
| Memory             | 2048 MB (swap capped the same)     | `COMPUTER_MEMORY_MB`                         |
| CPUs               | 1                                 | `COMPUTER_CPUS` (add it to Compose)          |
| Processes          | 512                               | Fixed                                        |
| `/tmp`             | 1 GB in memory                    | Fixed                                        |
| Shared memory      | 512 MB                            | Fixed                                        |
| Idle before sleep  | 5 minutes                         | Fixed                                        |

Home folders live on a Docker volume per computer, with no size limit of their own; watch disk use
on the host. Team computers have one screen, so a workspace admin sets how many bots can use
desktop tools at once from the team computer's menu (**Desktop users at once**).

## Related

- [Computers](/guide/computers)
- [Cloud Connect](/guide/cloud-connect)
- [Companion](/guide/companion)
- [Configuration](/self-hosting/configuration)
- [Operations](/self-hosting/operations)
- [Troubleshooting](/self-hosting/troubleshooting)
