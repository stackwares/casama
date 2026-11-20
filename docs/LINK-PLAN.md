# Casama Link: a phone reaches a Casama server on your own Mac, with no VPS and no domain

Renamed from Casama Connect on 2026-11-15; addresses live on **casama.link** (bought that day).

Status: **done** (live in production; checked against `docs/PLANS.md` on 2026-11-20, D-296).

Original status: **built 2026-11-14, all three phases, on the branch `worktree-casama-connect`**
(worktree `.claude/worktrees/casama-connect`); nothing is on `main` or in production until Oliver
says. Oliver's answers are in §13 and the decisions are **D-296** in `docs/DECISIONS.md`. The
migrations are `20270201100200` (renames the old Cloud Connect tables) to `20270201100203`. Everything is tested against a fake
Cloudflare; **it has not run against the real one**, because the address zone isn't bought and
there is no API token or TURN key yet. What is still open is in §15.

## 0. Summary

Today "Run Casama on This Computer" (D-147, D-216) gives a server only that Mac can reach:
`http://localhost:8080`, loopback only. A phone can't use it without a VPS, a domain, or the
person's own Cloudflare Tunnel set up by hand.

This plan gives every self-hosted server a public https address in one click, the way T3 Connect
does for T3 Code, and signs the phone in by scanning a QR code.

The answer to "our Casama Cloud accounts, or a separate system?":

- **Accounts: Casama Cloud's. No second system.** Sign-in, two-step, sign-up proofs, suspend,
  plans, the audit log, the owner console and the `kcc_` Casama Link keys already exist. T3 had
  to add Clerk because it had no accounts; we have them. **Casama Link is renamed Casama
  Connect**: one link from a server to Casama Cloud that carries the remote address and push
  (free) and cloud computers and credits (paid). One link, one key.
- **Traffic: never through Casama Cloud.** The phone talks to Cloudflare's edge, and Cloudflare
  carries it down a tunnel to the Mac. Our VPS only creates and removes tunnels. It is the same
  layout production already runs on (D-199: Cloudflare Tunnel → Caddy on port 80 → API and Auth).
- **The phone needs no Casama Cloud account.** It signs in to the person's own server.

```
Phone ──https──> Cloudflare edge ══tunnel══> connector ──> Caddy ──> API, Auth   data path
Mac app ──http://localhost:8080────────────────────────────> Caddy               unchanged, works offline
Server ──kcc_ key──> Casama Cloud /link/v1 ──> Cloudflare API                 control: create, check, remove
```

What gets built:

1. **Link**: the server is linked to a Casama Cloud workspace by approving a short code in the
   browser. No key to copy.
2. **Address**: Casama Cloud creates a Cloudflare Tunnel and `https://<random>.<zone>` for that
   server. A small `connector` container in the self-host stack holds the tunnel open.
3. **Scan to sign in**: the desktop app shows a QR code; the phone scans it and is signed in to
   that server. This also works for Casama Cloud accounts.
4. **Push** (Phase 2): notifications to the store apps through Casama Cloud, which a self-hosted
   server can't send today (D-080: "a push relay through Casama Cloud would cover that later").
5. **Live view away from home** (Phase 3): through Cloudflare's TURN service.

Not in this plan: LAN or Tailscale routes picked by the app, a Windows host (the local server isn't
offered there yet), end-to-end encryption on top of TLS, and one app signed in to two servers at once.

## 1. What exists today

Checked in code on 2026-11-14. Re-find each hook before editing.

- **Local server**: `client/lib/features/selfhost/local_server.dart` downloads the bundle and runs
  `install.sh --local --http-port <p> --pull <images> --settings <file>`. `--local` sets
  `HTTP_BIND=127.0.0.1` and `TURN_BIND=127.0.0.1`. Off in the Mac App Store build.
- **One public address**: `infra/compose/selfhost/Caddyfile` serves the API and Supabase's gateway
  on one site; bot pages have their own origin on port 8790.
- **The address is fixed at container start**: `CASAMA_PUBLIC_URL` feeds `SUPABASE_URL`,
  `PUBLIC_API_URL`, `PUBLIC_APP_URL` and Auth's `API_EXTERNAL_URL`, site URL and callback
  (`infra/compose/docker-compose.yml:26-30, 211-253`). So changing it means recreating containers.
- **The app asks the server where Auth is**: `GET /v1/config` returns `supabase_url` from
  `env.SUPABASE_URL` (`apps/server/src/api/routes/system.ts:42`). On a local install that is
  `http://localhost:8080`, which a phone can't reach.
- **Tokens are checked with the shared secret**, not by issuer (`apps/server/src/api/auth.ts`), so a
  token works whichever address it came in on.
- **Behind a tunnel already works**: `install.sh --behind-proxy` and `TRUSTED_CLIENT_IP_HEADER`
  (`cf-connecting-ip`) are what production uses.
- **Casama Link**: `apps/server/src/billing/link.ts` serves `/link/v1/*` on the cloud API,
  authenticated by `kcc_` keys from `link_keys` (workspace, instance name, `scopes`:
  `computers`, `models`). The self-hosted side reads `CASAMA_CLOUD_URL` and `CASAMA_CLOUD_KEY`.
- **Server address in the app**: `client/lib/core/server_address.dart` (one saved server; typed by
  hand at Sign in → More options → Server).
- **QR**: `mobile_scanner` and `qr_flutter` are already dependencies. iOS has `applinks:casama.ai`;
  Android takes `casama.ai/i/` and `/gallery/`.
- **iOS allows no plain HTTP** (no ATS exception in `Info.plist`), so an iPhone can't use a LAN
  `http://` address at all. An https address is the only route that works on every phone.
- **Push**: only the `kasama-ai` Firebase key can address the store apps, so self-hosted servers
  have no push. **Live view**: WebRTC through the stack's own coturn at `TURN_PUBLIC_HOST`, which is
  `localhost` on a local install.
- **Sign-up on a local install is open and auto-confirmed**, and the first account is the instance
  owner. Safe on loopback; not safe on a public address.

## 2. Goals

1. From "local server running" to "chatting on my phone over mobile data" in under 2 minutes, with
   no terminal, no router settings, no domain and nothing to copy by hand.
2. The same for a headless install: `casama selfhost remote on` on a home server or a VPS.
3. Turning it on never makes the server less safe than a person would expect.
4. Free for one server per workspace, with our cost at or near $0 until about 1,000 linked servers.
5. The desktop app on the same Mac keeps working exactly as before, also with no internet.

## 3. Principles

- **Control plane only.** Casama Cloud never proxies a self-hoster's traffic (cost, privacy, and one
  small VPS can't carry it).
- **One stable address.** It survives restarts, sleep, upgrades and a rebuilt tunnel, because
  webhooks, sign-in callbacks and saved phones all point at it.
- **The server owns its users.** The cloud link decides whether a server has an address. It never
  signs anyone in to that server.
- **Closed by default.** Sign-ups close when the address opens.
- **Plain about trust.** Say who can see what (§9).
- **Open source.** The control plane ships in this repo under the main licence, with a fake
  Cloudflare for tests, so someone else can run their own.

## 4. Words

| Word | Meaning |
|---|---|
| **Casama Link** | The feature, and the new name for Casama Link: everything a server gets from its link to Casama Cloud. |
| **Link** | This server is tied to a Casama Cloud workspace (a `kcc_` key). |
| **Remote access** | The switch inside Casama Link. On: the server has an address others can reach. |
| **Address** | `https://<12 random letters and digits>.<zone>` |
| **Connector** | The container that holds the tunnel open (cloudflared). Not "tunnel": the code already uses that word for the desktop companion (D-066). |
| **Scan to sign in** | A QR code that carries the address and a one-time sign-in code. |

## 5. The experience

### 5.1 Turning it on (desktop app, on the Mac that runs the server)

Settings → **Casama Link** → **Use on your phone** (also offered once, after the local server
first starts).

1. "Connect this server to Casama Cloud." The browser opens `app.casama.ai/link?code=K7QM-2XFD`.
   The person signs in or creates a free account, sees the server's name and the same code, and
   taps Link. The desktop app continues on its own.
2. The sheet shows three steps with live state: Linked, Address ready, Server restarted. About 30 s.
3. A QR code: "Scan with your phone's camera." Below it: the address with Copy, "Only people with
   an account on this server can sign in. New sign-ups are off.", and a suggestion to turn on
   two-step sign-in if it's off.

Afterwards the same screen shows: state (Online, Offline, Needs attention), the address, Show QR
code, **Keep this Mac awake while plugged in**, and Turn off.

### 5.2 On the phone

- Camera → the code opens Casama (or a casama.ai page with store buttons, then "scan again").
- In the app, signed out: **Scan a code from your computer** on the sign-in screen.
- The app saves the address, trades the one-time code for a session, and lands in the chat. An
  account with two-step sign-in is asked for its second step as usual.
- By hand, as today: Sign in → More options → Server, type the address, sign in with email and
  password.

### 5.3 Headless

```
casama selfhost remote on      # prints a link and a code; approve on any device
casama selfhost remote status  # state, address, and what's wrong if anything
casama selfhost remote off
casama pair                    # QR code in the terminal (with a sign-in code if the CLI is signed in)
```

### 5.4 States that need a design

| State | Phone | Desktop |
|---|---|---|
| Mac asleep, Docker stopped, or no internet at home | "Your server is offline. Is the computer on and awake?" with Try again. Told apart from "no internet on this phone" by Cloudflare's 530 answer. | Offline, with the reason |
| Connector can't reach Cloudflare (port 7844 blocked by a VPN or firewall) | Same as offline | "This network blocks the connection. Allow outbound port 7844, or turn off the VPN." |
| Live view before Phase 3 | "Live view works on the computer itself for now." | Unchanged |
| Workspace suspended, key revoked, or over the plan's limit | Offline | "Remote access was turned off for this server", with the reason and what to do |
| Server not seen for 14 days (address parked) | Offline | Comes back by itself at the same address about a minute after the server starts |

## 6. How it works

### 6.1 Casama Cloud: the control plane

A module in the cloud API (`apps/server/src/link/`), on only when its Cloudflare settings are
set, beside `billing/link.ts` and using the same `kcc_` middleware.

**Linking** (the device-code pattern, so it works with no browser on the host):

- `POST /link/v1/sign-in/start {instance_id, instance_name, platform, version}` →
  `{device_code, user_code, verification_url, interval, expires_in}`. No auth; limited per address.
- `app.casama.ai/link` → `POST /v1/orgs/{id}/link/sign-ins/approve {user_code}` (workspace
  admin). The page shows the instance name and code. It issues a key with scopes `remote_access`
  and `push`, which can't spend money. Cloud computers and credits (`computers`, `models`) stay a
  separate, explicit choice.
- `POST /link/v1/sign-in/poll {device_code}` → pending, or the key, once.

**Remote access** (key with `remote_access`):

- `PUT /link/v1/remote {instance_id}` → `{address, pages_address, token, generation}`. Safe to
  repeat. Checks the plan's server limit and suspension.
- `POST /link/v1/remote/heartbeat {generation}` → `ok`, `replaced` (with a new token),
  `suspended` or `limit`.
- `DELETE /link/v1/remote` → removes the tunnel and DNS, keeps the address reserved 90 days.

**Data**: `link_servers` (workspace, key, `instance_id`, name, the two host labels, Cloudflare
tunnel id, `generation`, status, `last_seen_at`, timestamps). RLS: workspace admins read. Every
change writes `audit_log`. New plan limit `remote_servers`.

**Cloudflare** behind a `TunnelProvider` interface with plain `fetch`, like the other adapters:

- One remotely managed tunnel per server, named from the server's id so a retry adopts it rather
  than making a second one. Ingress is fixed by us: `<label>.<zone>` → `http://caddy:80`,
  `<label>-p.<zone>` → `http://caddy:8790` (pages keep their own origin, D-119), anything else 404.
- Two proxied CNAMEs per server. One label deep, so Cloudflare's wildcard certificate covers them
  and the names never appear one by one in certificate logs.
- Every change bumps `generation`; a delete claims the generation first, so a late clean-up can't
  remove a tunnel that a restart just reused (the race T3 documents in its relay).
- **Parking**: a daily job removes tunnels whose server hasn't connected for 14 days, because
  Cloudflare counts idle tunnels toward the 1,000 it includes. The address stays reserved. Modes
  `off`, `dry-run`, `on`; ship `off`, watch `dry-run`, then turn it on.
- A scoped API token: Tunnel edit on the account, DNS edit on the address zone only.

**Zone rules**, once, for every linked server: block `/pg/` and `sb_secret_` (as on casama.ai), one
rate limit on `/auth/v1/token` and `/auth/v1/signup`, and `X-Robots-Tag: noindex` on every response.

**Owner console**: linked servers (workspace, name, address, last seen, state), Suspend and Remove.
Suspending a workspace (D-094) also takes down its servers' addresses.

### 6.2 The self-hosted server

- **Compose**: a `connector` service under profile `link`: Alpine with a pinned, checksum-verified
  cloudflared, run as `tunnel --no-autoupdate run --token-file /link/token` with a metrics port
  for health. A 20-line watcher restarts cloudflared when the token file changes. The API mounts the
  same small volume and owns the file. Published with the other images.
- **Settings written when it turns on** (through the existing `--settings` file and a re-run of
  `install.sh`, which recreates only the containers whose settings changed):

  | Setting | Value |
  |---|---|
  | `CASAMA_CLOUD_URL`, `CASAMA_CLOUD_KEY` | the link |
  | `CASAMA_REMOTE_ACCESS` | `on` (remembered on re-runs, like `CASAMA_BACKUPS`; adds `--profile link`) |
  | `CASAMA_PUBLIC_URL`, `CASAMA_PAGES_URL` | the two addresses |
  | `CASAMA_LOCAL_URL` | the old `http://localhost:<port>` |
  | `SIGNUP_HOOK_URI` | `<address>/hooks/auth/before-user-created` |
  | `TRUSTED_CLIENT_IP_HEADER` | `cf-connecting-ip` (and Auth's own rate-limit header) |
  | `DISABLE_SIGNUP` | `true` |

  Turning it off restores the saved values. Ports stay on loopback throughout.
- **The Mac's own app is untouched**: when a request arrives on a loopback host and
  `CASAMA_LOCAL_URL` is set, `GET /v1/config` answers with that as `supabase_url`. The desktop app
  keeps `http://localhost:8080` for everything, stays signed in, and works with no internet.
- **A small service in the API** (`services/remote-access.ts`): writes the token file, sends the
  heartbeat at start and hourly, applies a replaced token, asks the connector's health port and its
  own address from outside, and serves `GET /v1/admin/remote-access` (state, address, problem) and
  `POST /v1/admin/remote-access/check` for the app and the CLI.
- **Who runs the steps**: one Dart implementation in `dart/casama_sdk` (link, provision, write the
  settings file), used by `casama selfhost remote` and by the desktop app, which already runs the
  installer.

### 6.3 Scan to sign in

- `POST /v1/auth/pairing-codes` (signed in; 5 a minute) → a 256-bit code, stored hashed, single use,
  5 minutes.
- QR payload: `https://casama.ai/pair#v=1&s=<address>&c=<code>&n=<server name>`. The part after `#`
  never reaches casama.ai's server. The page is static.
- `POST /v1/auth/pairing-codes/redeem {code, device_name}` (no auth; limited per address) → a
  one-time Auth token hash made with the service key. The app finishes with `verifyOtp` and holds
  its own session. The server writes `audit_log` and notifies the account: "Signed in on Pixel 9 by
  scanning a code."
- The session is single-factor. Two-step accounts still do their second step.
- App: a `/pair` route, the Android `pathPrefix`, `/pair` in casama.ai's app-link files, and a
  scanner on the sign-in screen.

### 6.4 Push relay (Phase 2)

- Cloud: `POST /link/v1/push` (scope `push`) takes device tokens and a message and sends with
  Casama's Firebase key. It answers which tokens are dead, so the server drops them (D-271).
  Limited per key.
- Server: a `CloudRelayPushSender` when the server has a link and no `FCM_SERVICE_ACCOUNT` of its
  own.
- A server setting, **Private notifications**: the relay then gets only "New activity in Casama",
  and the app loads the text itself when opened.
- Needs only the link, not remote access, so servers on their own domain get push too.

### 6.5 Live view away from the computer (Phase 3)

As built:

- Cloud: `POST /link/v1/turn-credentials` → Cloudflare TURN credentials with a 12-hour life (a
  streamer is given them once, when it starts, so two hours was too short), 24 requests a day per
  key, only when the workspace's plan has `link_live_view` (Plus and up). The heartbeat tells
  the server what its plan gives, so the app and the CLI can say so.
- Server: when the viewer isn't on loopback, the live route answers with the outside relay instead
  of the local one, and says `live_view_needs_plan` when the plan doesn't have it (the app then
  shows screenshots and the reason). The server keeps credentials and reuses them while they are
  good for six more hours.
- The computer: bot computers **can't** reach `turn.cloudflare.com`; their only way out is the
  egress proxy, which carries HTTP. So the `turn` container, which each desktop computer already
  reaches as `turn`, forwards port 3479 (UDP and TCP, never published) to the relay when remote
  access is on, and the streamer is given `turn:turn:3479` with the same credentials. Checked
  against the real relay: a request through the forwarder is answered by Cloudflare.
- The streamer reads its relays only at start. `ice_key` names the outside relay; a running
  streamer that wasn't given it is started again (viewers fall back to screenshots and reconnect),
  and one that has it is left alone.
- Call rings: Android through the push relay's `call`, iPhones through `voip` with Casama's Apple
  key. With private notifications on, neither says which bot or why.

## 7. Security

| Risk | Answer |
|---|---|
| A stranger signs up on someone's Mac and runs bots and computers there | Remote access turns on only when an account already exists, and sets `DISABLE_SIGNUP=true`. Without the first rule a stranger could become the instance owner. Phase 2 adds "invited people only" through the existing sign-up hook. |
| Password guessing on a public address | Real caller addresses reach the rate limits (`cf-connecting-ip`), plus one zone rule at Cloudflare. The turn-on sheet suggests two-step sign-in. |
| Addresses found by scanning | 60 random bits per label, a wildcard certificate, `noindex`. |
| Phishing or malware hosted on our zone | The zone is a separate domain, never `casama.ai`. A verified account stands behind every address; Suspend removes it in seconds; an abuse contact is published. |
| A leaked `kcc_` key | It can hold an address and send push, nothing that costs money. Revoking it in the workspace removes the tunnel. |
| Casama Cloud compromised | It could re-point or drop addresses and read push text. It can't sign in to a server: sign-in codes go from the Mac's screen to the phone and are redeemed at the server. |
| A stolen QR code | Single use, 5 minutes, a notice to the account, and two-step still applies. |
| The sign-up hook now travels out and back through the tunnel | If the tunnel is down, sign-ups fail closed. |

## 8. Limits and cost

Add these rows to `docs/COSTS.md` in the phase that turns each on.

| Item | Price | Notes |
|---|---|---|
| Address zone (a new domain) | about $10–30 a year | Oliver buys it (§13) |
| Cloudflare Tunnels | $0 for the first 1,000 on the account, then $4.50 per tunnel a month | Idle tunnels count, hence parking. Alert at 700. Production's own tunnels share the count. |
| DNS records | 200 on a new Free zone, 3,500 on Pro (about $25 a month) | 2 per server, so Free holds about 100 servers. Alert at 150 records. |
| Traffic through the tunnel | $0 | Cloudflare's usual limits apply, as on Casama Cloud: 100 MB per upload, replies must start within 100 s |
| Push | $0 | Firebase and APNs are free |
| TURN (Phase 3) | $0.05 per GB after 1,000 GB a month, shared across the account | Roughly 0.7–1.4 GB per viewing hour (an estimate; measure it). Built: Plus and up only, 24 credential requests a day per key, 12-hour credentials. Not built: metering per workspace and the 500 GB alert; `docs/COSTS.md` says what to watch. |

Recommended limits (`remote_servers`): Free 1, Plus 1, Pro 3, Max 10. Past 1,000 live tunnels each
extra server costs us $4.50 a month, so free servers beyond that point need a decision then, not now.

### 8.1 How it earns

The address will not be a big earner by itself. Its job is to turn anonymous self-hosters into
Casama Cloud accounts, and to sit where the paid things are one tap away.

| Tier | Price | What it has |
|---|---|---|
| **Free** | $0 | One server: the address, scan to sign in, push (fair use). Never metered, never gated. |
| **Extras** | In every paid plan (Plus and up); later perhaps alone at about $5 a month | Live view away from home, messages held while the computer sleeps, your own name in the address, more servers, off-site encrypted backups, an alert when the server goes offline |
| **Credits** | Usage at the 1.4 markup (built: Casama Link `models` and `computers`) | "No model key? Use Casama credits." Also pictures, video, read-aloud and dictation, which a ChatGPT plan doesn't cover |
| **Move to Casama Cloud** | The normal plans | For when a laptop that sleeps isn't enough. The heartbeat tells us honestly how often the server was off and what was missed |
| **Companies** | Enterprise licence | Unchanged. Seats on a self-hosted server are never charged |

Why the address stays free:

- It costs us nothing for the first 1,000 servers online at once.
- T3 Connect and Tailscale are free, and r/selfhosted punishes a paywall on remote access.
- A linked server is the only way we learn a self-hoster exists.

Why the extras are the paid part: each one either costs us money (TURN bandwidth, backup storage) or
fixes the laptop-server problem (missed messages, offline alerts). Home Assistant sells the same kind
of bundle for about $6.50 a month (price from memory, not re-checked). Of these extras only live view
is in §11's phases today; held messages, a chosen name, backups to our storage and offline alerts
need their own small phase before anything is sold.

Rollout: Phase 1 ships free only, since no extra exists yet. The extras arrive with Phases 2 and 3,
on the existing plans, so there are no new store products. Add the $5 tier only if self-hosters ask
for the extras and won't pay $15. Sell it on the web and desktop (Dodo), not in the stores.

The honest limit: past about 1,000 servers online at once, a free server costs $4.50 a month at
Cloudflare's list price, which no plausible paid share covers. Parking keeps the count to servers
that are actually on. At 700, choose between platform pricing from Cloudflare, a cheaper shared
relay for free servers, or a waiting list.

## 9. What we tell people

"Remote access sends your phone's traffic through Cloudflare to your computer. Cloudflare ends the
encrypted connection at its edge, on a domain Casama runs. Casama's own servers don't carry or store
your traffic; they keep your server's name, its address and when it was last online. With push on,
notification text passes through Casama Cloud unless you turn on Private notifications. If you want
no third party in the path, use your own domain or a private network such as Tailscale." This goes
in `docs-site/self-hosting/remote-access.md`, with the alternatives and a troubleshooting page that
follows the four hops: phone, Cloudflare, connector, Casama.

## 10. Where the work lands

- **Cloud API**: `apps/server/src/link/` (link, remote, provider, Cloudflare adapter, parking),
  `env.ts`, `api/routes/admin.ts`, `packages/contracts/src/link.ts`, one migration
  (`link_servers`, the two scopes, the plan limit), `packages/domain` plan defaults.
- **Self-hosted server**: `services/remote-access.ts`, `api/routes/system.ts` (loopback rule),
  `api/routes/admin.ts`, pairing-code routes and their migration, `packages/agent/src/notifications.ts`
  (relay sender), `api/routes/live.ts` (Phase 3).
- **Stack**: `infra/compose/docker-compose.yml`, `infra/images/connector/`, `install.sh`,
  `scripts/publish-images.sh`, the Helm chart's notes.
- **Dart**: `dart/casama_sdk` (link and provision), `dart/cli/lib/src/commands_selfhost.dart`
  (`remote`, `pair`), regenerated `dart/casama_api`.
- **App**: `client/lib/features/selfhost/` (sheet, state, keep awake), `features/auth/sign_in_screen.dart`
  (scan), `core/server_address.dart`, `core/router.dart` (`/pair`, `/link`), the offline screen,
  `l10n/app_en.arb`, `android/app/src/main/AndroidManifest.xml`. No WebViews.
- **Site and docs**: `site/` (`/pair` page and app-link files), `docs-site/self-hosting/`,
  `SPEC.md`, `docs/DECISIONS.md`, `docs/COSTS.md`, `CHANGELOG.md`, `THIRD_PARTY_NOTICES.md`.

## 11. Phases

Each phase ends at a gate. Production deploys, site deploys and app builds each need Oliver's yes.

**Phase 0: setup (Oliver, small).** Buy the zone and add it to Cloudflare. Create the scoped API
token and save it to Vaultwarden. Add the zone rules. Confirm §13.

**Phase 1: remote access and scan to sign in (large).**

- Cloud: link flow, `PUT/DELETE /link/v1/remote`, heartbeat, Cloudflare adapter and its fake,
  `link_servers`, limits, console list with Suspend.
- Server: connector image and compose profile, settings switch, loopback rule, status service,
  sign-ups closed, real caller addresses, pairing codes.
- CLI: `selfhost remote on|off|status`, `pair`.
- App: Use on your phone sheet, scanner, `/pair`, `/link` approval page, offline screen, the
  live-view note.
- Docs and the three records (SPEC, DECISIONS, COSTS).
- Tests: cloud (link once only, provision repeated, limit, suspend, revoke, generation race), server
  (token file, heartbeat, config on loopback and through the address, codes: single use, expiry,
  rate limit, two-step kept), app (sheet states, scan, offline), CLI, and one scripted run with a
  real cloudflared against a dev zone.

**Gate:** on a fresh Mac: local server → Use on your phone → scan → chatting on mobile data in under
2 minutes. The Mac's app stays signed in and works with Wi-Fi off. Sleep the Mac: the phone says
offline in plain words; wake it: back in under 60 s with no new pairing. A stranger with the address
can't sign up. Turn off: the address is dead within 30 s and the server is back on loopback only. A
streamed reply, a 50 MB upload and the terminal all work through the address.

**Phase 2: push, invites, staying up (medium).** Push relay with Private notifications. "Invited
people only" sign-ups. Keep this Mac awake. Parking in `dry-run`, then on. Alerts at 700 tunnels and
150 records.

**Gate:** a self-hosted server's reply reaches a store-installed phone as a push with the app
closed. An invited email can sign up and another can't. A parked server returns at the same address
by itself.

**Phase 3: live view and calls (medium).** TURN credentials, caps, the cost row. Call pushes
through the relay.

**Gate:** live view from mobile data to a bot computer on a Mac at home, under 1 s.

**Later:** "Your servers" on the phone's sign-in screen for people signed in to Casama Cloud; LAN
and Tailscale routes; the zone on the Public Suffix List; a Windows host; a second Cloudflare
account when one fills up.

## 12. Risks

| Risk | What happens | Answer |
|---|---|---|
| Abuse gets the whole zone flagged | Every self-hoster's address shows a warning | Separate domain, verified accounts, fast suspend, noindex, one server on Free |
| Cloudflare changes tunnel terms again (it began charging past 1,000 in October 2026) | Cost per server | `TunnelProvider` interface, parking, limits by plan, alerts well before the line |
| Cloudflare is down | Remote access is down; the Mac's own app still works | Say so on the status screen |
| Networks that block port 7844 | The connector never connects | Diagnose and name it; document Tailscale |
| A sleeping Mac reads as "Casama is broken" | Bad first week | Keep awake switch, plain offline screen, last-seen time |
| Auth's issuer changes when the address does | A desktop session might not refresh | Test in Phase 1 with a session made before the switch; the loopback rule is the guard |
| The address ends up in OAuth clients and webhooks | Turning off breaks them | The address is reserved 90 days and returns unchanged |
| Push text passes through us | Privacy objection | Private notifications, stated plainly |

## 13. Decisions (Oliver, 2026-11-14)

| # | Question | Decided |
|---|---|---|
| 1 | Casama Cloud accounts, or a separate Connect system? | Casama Cloud accounts. Traffic stays off our servers. |
| 2 | Which domain carries the addresses? | A new one Oliver buys, never a `casama.ai` subdomain. Not bought yet: build and test against the fake Cloudflare; the zone is a setting. |
| 3 | What it's called | **Casama Link.** One name: Casama Link is renamed into it. The button reads "Use on your phone". |
| 4 | Scan to sign in | Self-hosted servers and Casama Cloud accounts |
| 5 | Servers per workspace | Free 1, Plus 1, Pro 3, Max 10 |
| 6 | How it earns | The address, scan to sign in and push are free. Extras come with Plus and up (§8.1). No $5 tier now, no charge for the address. |
| 7 | Sign-ups when the address opens | Closed. Invited people only arrives in Phase 2. |
| 8 | Push text through Casama Cloud | Yes, with a Private notifications switch |
| 9 | Scope of this build | All three phases, so Cloudflare TURN for live view is in. Live view away from home is a Plus-and-up extra. |
| 10 | Where it's built | A separate worktree and branch, committed as it goes |
| 11 | Bots on a Claude subscription through Claude Code | Parked. Oliver may ask Anthropic meanwhile. |

Still asked at the time, as `AGENTS.md` requires: each Flutter build or run, each production,
Cloudflare or site change, and store uploads.

## 14. How we'll know it worked

- Median time from Use on your phone to the phone's first message: under 2 minutes.
- Share of local servers with remote access on, and with a phone paired within a day.
- Linked workspaces that later buy credits or a plan.
- Connector uptime while the server is up: above 99%.
- Support questions per 100 linked servers, by the four hops.

## 15. What is still open (2026-11-14)

Checked against the real Cloudflare before the zone exists (D-296): the tunnel adapter and the
`connector` image, DNS records on a stand-in zone (oliverbytes.dev, removed after) with both
addresses answering over https, real relay credentials, and live view through Cloudflare's relay
with Chrome as the viewer away, which led to the new UDP forwarder.
Run them again with `apps/server/scripts/link-live-check.ts` (add `CF_ZONE_ID` and `CF_ZONE`
once the zone exists, and it checks the address over https too) and
`packages/sandbox/test/live-outside-relay.test.ts`. Before anyone can use it:

1. **The address zone.** casama.link is bought (2026-11-15); add it to Cloudflare and decide
   Free or Pro (200 or 3,500 DNS records; two per server). Then publish the bare domain's page
   (`link-site/`, D-317) with `scripts/deploy-link-web.sh`: it explains the addresses and takes
   abuse reports, which the Public Suffix List request and abuse desks look for.
2. **Cloudflare credentials**, saved to Vaultwarden: an API token for tunnels and DNS on that zone
   (`CASAMA_LINK_CF_ACCOUNT_ID`, `CASAMA_LINK_CF_ZONE_ID`, `CASAMA_LINK_CF_API_TOKEN`, `CASAMA_LINK_ZONE`); the
   CLI's sign-in can't make API tokens, so this one is made in the dashboard. The TURN key
   (`CASAMA_LINK_TURN_KEY_ID`, `CASAMA_LINK_TURN_API_TOKEN`) exists, made 2026-11-14, in Vaultwarden.
   One zone rule for sign-in rate limiting, as §7 says.
3. **A real phone**: the whole server flow ran end to end on 2026-11-15 (D-296) with the CLI, a
   stand-in cloud and Chrome as the phone. Still to do on a device with a new app build: scan the
   QR code, open a `/pair` link from the camera, sign in, and watch a bot's screen on mobile data.
4. **Production:** the three migrations, the `CASAMA_LINK_*` settings and the Apple key on the API,
   the `connector` and rebuilt `turn` and computer images published, the site deployed for `/pair`
   and the app-link files, and new app builds.
5. **In the app:** the screens were checked by widget tests, not on a device. The QR scanner, the
   `/pair` universal link and the keep-awake switch need a phone and a Mac.

Left out on purpose (§8.1's extras): messages held while the computer sleeps, a chosen name in the
address, backups to Casama's storage, an alert when the server goes offline, per-workspace metering
of relay traffic, and revoking relay credentials already handed out when a server is suspended
(they last 12 hours; a suspended server is refused new ones).

Sources: T3 Code's `docs/internals/t3-connect.md`, `docs/user/remote-access.md` and
`infra/relay/README.md` (github.com/pingdotgg/t3code) · Cloudflare:
developers.cloudflare.com/changelog/post/2026-10-16-tunnels-for-platforms-and-50k-routes,
developers.cloudflare.com/cloudflare-one/account-limits, developers.cloudflare.com/dns/manage-dns-records,
developers.cloudflare.com/realtime/turn/generate-credentials, and the cloudflared run parameters page
(`--token-file`, 2025.4.0 and later). Prices read on 2026-11-14.
