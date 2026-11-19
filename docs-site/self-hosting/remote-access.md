# Use your server on your phone (Casama Link)

A Casama server on your own Mac or PC normally answers only on that computer. Casama Link gives it
an `https://` address your phone can reach from anywhere, with no domain, no router settings and no
open ports. You sign in on the phone by scanning a code, and notifications reach the Casama apps
from the App Store and Google Play.

This page takes you from a server on your computer to your phone signed in to it, then explains
what goes where, what it costs, and how to turn it off. Casama Link can also give a self-hosted
server Casama Cloud's computers and model credits; that part is billed and has its own page:
[Cloud computers and credits](/self-hosting/casama-link-cloud).

## Before you start

You need:

- **A server on this computer**, started by the desktop app's **Run on This Mac** setup or
  installed with `./install.sh --local`. See [Run a server on your own computer](/self-hosting/#run-a-server-on-your-own-computer).
- **Your account on that server.** Remote access refuses to turn on while nobody has signed up,
  because it closes sign-ups and the first account would otherwise belong to whoever finds the
  address first.
- **A free Casama Cloud account** where you are an owner or admin of a workspace. You can make one
  while you approve the link. Casama Cloud is invite-only for now, and people who run their own
  server are let in first: tick **I run Casama on my own server** at casama.ai/waitlist. See
  [Getting an invite](/guide/getting-an-invite).
- **Outbound port 7844, TCP and UDP.** The `connector` container dials out to Cloudflare on it. Most
  home networks allow it. Some company networks and VPNs don't.
- **A Casama Cloud that gives out addresses.** The CLI and the app use `https://api.casama.ai`. If
  that cloud doesn't hand out addresses, linking stops with "This Casama Cloud does not give out
  addresses."

A server that already has its own `https://` domain doesn't need an address. It can still
[link for notifications only](#link-without-an-address).

## Set it up

### 1. Turn on remote access

**In the desktop app**, on the computer that runs the server:

1. Open **Settings**, then **Casama Link** (under Connections). The row only shows for the
   server's instance owner.
2. Choose **Use on Your Phone**.
3. Your browser opens Casama Cloud's **Link a Server** page. Sign in if asked, check that it shows
   the same code as the app, pick the workspace and choose **Link**.
4. The app goes through **Link this server**, **Get an address**, **Restart the server** and
   **Connect**. The restart takes about a minute.
5. When it's done, the app shows a QR code for your phone.

The **Use on Your Phone** button appears only when the app is connected to the server it
installed itself. For a server you installed another way, the screen shows the command below.

**In a terminal**, from the server's checkout:

```sh
casama selfhost remote on
```

It prints a code and a link, and opens the link in a browser. Approve the code there (it works for
15 minutes). The command then gets the address, restarts the stack with it, waits up to three
minutes for the connector, and prints the address.

| Option            | What it does                                                                        |
| ----------------- | ----------------------------------------------------------------------------------- |
| `--name <name>`   | What to call this server in Casama Cloud. Default: the machine's name.              |
| `--invites`       | Let people you invite by email make an account. See [Who can sign up](#who-can-sign-up). |
| `--no-invites`    | Close sign-ups again.                                                               |
| `--relink`        | Link again even when the server has a key, for example after it was revoked.         |
| `--no-browser`    | Only print the link. Useful over SSH.                                               |
| `--cloud <url>`   | Use another Casama Cloud (default `CASAMA_CLOUD_URL`, then `https://api.casama.ai`). |
| `-v`, `--verbose` | Show the installer's output while the server restarts.                              |

Check it at any time:

```sh
casama selfhost remote status
```

It says whether the address answers from outside and, when it doesn't, where it stops: Casama
Cloud's record, the connector, or the address itself.

### 2. Turn on two-step sign-in

The address can be reached from the whole internet. Turn on two-step sign-in for your account in
**Settings → Two-step sign-in**, so a guessed password isn't enough. The Casama Link screen reminds
you until you do.

### 3. Sign in on your phone

1. Install Casama from the App Store or Google Play.
2. Scan the code:
   - with the phone's camera, then open the link, or
   - in the app's sign-in screen, choose **Scan a Code from Your Computer**.
3. The app asks **Sign in to** your server's address. Choose **Sign in**.

The code holds the server's address and a one-time sign-in code. It works once, for five minutes,
and showing a new code ends the old one. Anyone who scans it is signed in as you, so don't share a
picture of it. Each time a code is used, your account gets a "New sign-in" notice. If your account
has two-step sign-in, the phone still asks for the second step.

To show a code again:

- in the app: **Settings → Sign In on Another Device**, or **Show Sign-In Code** on the Casama Link
  screen, or
- in a terminal where the CLI is signed in: `casama pair`.

Both work on any Casama server, Casama Cloud included. You can also type the address by hand: on
the phone's sign-in screen, choose **More options**, then **Server**.

### 4. Keep the computer awake

Phones reach the server only while the computer is on, awake and online. On a Mac, turn on
**Keep This Mac Awake While Plugged In** on the Casama Link screen. It holds the Mac awake while
Casama is open and the charger is connected. On other systems, change the computer's own power
settings.

## How it works

```text
Phone ── https ──> Cloudflare edge ── tunnel ──> connector ──> Caddy ──> API, Auth, Pages
                   (*.casama.link)              (your computer, dials out on 7844)

Your server ── check-in every hour, notifications ──> Casama Cloud (control desk only)
```

1. **Linking.** Your server asks Casama Cloud for a code. A workspace owner or admin approves it,
   and the server collects a key (`kcc_…`) once. That key can hold an address and send
   notifications. It can't spend the workspace's credits.
2. **The address.** Casama Cloud makes a Cloudflare tunnel for your server and two names on
   `casama.link`: `https://<12 random characters>.casama.link` for the app, and the same name with
   `-p` added for bots' [Pages](/guide/pages), which stay on their own origin.
3. **The connector.** The `connector` container (Cloudflare's `cloudflared`, pinned) holds the
   tunnel open. It only dials out, and nothing on your computer is published to the network. The
   API fetches the tunnel's secret from Casama Cloud and hands it to the connector through a
   private Docker volume.
4. **Your phone's traffic** goes to Cloudflare's edge and down the tunnel to your computer. It
   never passes through Casama's servers.
5. **Check-ins.** Every hour the server tells Casama Cloud it's there. If Cloudflare's tunnel was
   made again, the server fetches the new secret. If the connector stays disconnected for five
   minutes, the server asks for the tunnel again. Losing touch with Casama Cloud never takes a
   working address down: the stored secret keeps the connector running.
6. **The app on the server's own computer** keeps using the local address (`CASAMA_LOCAL_URL`, for
   example `http://localhost:8080`). It stays signed in and works with no internet. Only other
   devices use the public address.

### Who can see what

| Part                     | Who can see it                                                                                     |
| ------------------------ | -------------------------------------------------------------------------------------------------- |
| Your chats, files and API calls | Your server, and Cloudflare in transit: TLS ends at Cloudflare's edge, as on any Cloudflare-proxied site, and the tunnel to your computer is encrypted again. Casama's servers never carry or store it. |
| Sign-in codes            | Only your server. The code is in the part of the link after `#`, which browsers don't send to `casama.ai`, and the phone redeems it at your server. Casama Cloud can't sign in to your server. |
| Notifications            | Casama Cloud passes them to Firebase and Apple, with their text, unless **Private Notifications** is on. It doesn't store the text or the device tokens. |
| Live video from away     | The relay passes video it can't read: WebRTC encrypts it between the bot's computer and your phone. |
| Your server's record     | Casama Cloud keeps the workspace it's linked to, its name and id, its address, the platform and version it reports, and when it last checked in. |

What Casama Cloud can do: it runs the tunnels and the `casama.link` names in its own Cloudflare
account, so it can take an address down or point it elsewhere. It can't read what passes through
the tunnel. If you want no third party in the path at all, give the server your own domain or use a
private network such as a VPN instead.

## Who can sign up

Turning remote access on sets `DISABLE_SIGNUP=true`, because anyone who learns the address can
reach the sign-in screen. People who already have an account sign in as before; the app tells
everyone else "This server isn't taking new accounts."

To let more people in, turn on **Let Invited People Sign Up** on the Casama Link screen (or run
`casama selfhost remote on --invites`). Only an email address with a pending invite to a workspace
on your server can then make an account. The server's sign-up hook checks it before the account is
made, and refuses the sign-up if the check can't run. The server restarts to change this setting.

## Notifications

The apps from the App Store and Google Play only accept notifications sent with Casama's own
Firebase key, and call rings on iPhone with Casama's own Apple key. So a linked server with no
Firebase key of its own (`FCM_SERVICE_ACCOUNT`) hands its notifications and call rings to Casama
Cloud, which sends them on.

**Private Notifications** (on the Casama Link screen, instance owner only) keeps the text on your
server. The phone then shows "New activity", call rings show "Casama" instead of the bot's name,
and the app loads the rest from your server when you open it. The switch takes effect within
seconds, with no restart.

A bot's progress on the Lock Screen (an iPhone Live Activity, or Android's live notification)
goes the same way, so it keeps up while the app is closed. With Private Notifications on, Casama
Cloud gets only whether the bot is working, needs you or has finished: the phone shows those in its
own words, without the bot's name or step. A server that can't push at all still updates the Lock
Screen while the app is open.

Without a link, a self-hosted server still fills the in-app inbox; it just can't push to the store
apps.

## Live view away from the computer

Live view of a bot's desktop is video through a relay. Your server's own relay listens only on
your computer, so:

| Where you watch                           | What you get                                                       |
| ----------------------------------------- | ------------------------------------------------------------------ |
| On the computer that runs the server       | Live video, as always. No internet needed.                         |
| Anywhere else, Casama Cloud plan Plus and up | Live video through Casama Cloud's relay, and you can take control. |
| Anywhere else, Free plan                   | The screen as a screenshot about once a second.                    |

"Anywhere else" includes a phone on the same Wi-Fi: it reaches the server through the public
address too. The plan is the one of the Casama Cloud workspace the server is linked to. The
Casama Link screen (**Live View Away From Here**) and `casama selfhost remote status` say which
applies.

How the relay is reached: your phone connects to it directly. A bot's computer has no route to the
internet except the egress proxy, so with remote access on, the `turn` container forwards one more
port (3479, never published) to that relay and nowhere else. The relay accepts only short-lived
credentials that your server gets from Casama Cloud. They last up to 12 hours, and a server can ask
for them at most 24 times a day.

## When the phone can't reach the server

If the server stops answering while the app is open, a bar over the app says **Can't reach your
Casama server**, or **Your server is offline** when Cloudflare answered but your computer didn't
(the computer is asleep, off or without internet). The app checks again every 10 seconds and when
you bring it back to the front, and reloads by itself once the server answers. **Try Again** checks
at once.

## Servers per plan

A Casama Cloud workspace can link this many servers at once:

| Plan | Servers | Live video away from the computer |
| ---- | ------- | --------------------------------- |
| Free | 1       | No (screenshots)                  |
| Plus | 1       | Yes                               |
| Pro  | 3       | Yes                               |
| Max  | 10      | Yes                               |

The address, sign-in by QR code and notifications are free on every plan. See
[Usage, budgets and plans](/guide/usage).

## Limits

- Uploads through the address are limited to 100 MB each, and a reply must start within 100
  seconds. These are Cloudflare's limits.
- The address is random, but it isn't a secret. Treat the server as public: a good password and
  two-step sign-in.
- Notifications through Casama Cloud are capped at 2,000 devices an hour per server.
- A server that hasn't checked in for 14 days may have its tunnel put away. The address stays, and
  the tunnel comes back within a minute of the server starting again.
- An address you turned off, or a server that was removed, keeps its name reserved for 90 days.
- Addresses used for phishing or malware are taken down. Report one at
  [casama.link](https://casama.link/#report) or to `security@casama.ai`.

## Turn it off

In the app: **Settings → Casama Link → Turn Off**. In a terminal:

```sh
casama selfhost remote off
```

The address stops answering, the connector stops, and the server goes back to answering only on
this computer. Every setting remote access changed goes back to what it was, sign-ups included.
The server stays linked: turning it on again gives it the same address.

To unlink completely, remove the server in your Casama Cloud workspace: **Settings → Billing**,
open **Charges by server, Casama Link servers and keys**, find it under **Linked Servers** and
choose **Remove**. That frees its place on the plan, also when the server is offline or gone.

## Link without an address

A server on its own domain already has an address, but without a Firebase key of its own it can't
notify the store apps. Link it to Casama Cloud for notifications and call rings alone:

```sh
casama selfhost remote link
```

It shows a code to approve, saves the key and restarts the server. Nothing about who can reach the
server changes: no address, no tunnel, and sign-ups stay as they are. **Private Notifications**
works the same way. `remote link` takes `--name`, `--cloud`, `--relink`, `--no-browser` and
`--verbose`.

## What gets set

`casama selfhost remote on` and the desktop app write these to `infra/compose/.env`, then re-run
the installer, which starts the `connector` container (Compose profile `link`). You shouldn't need
to edit them by hand.

| Name                     | What it holds                                                                 |
| ------------------------ | ----------------------------------------------------------------------------- |
| `CASAMA_REMOTE_ACCESS`   | `on` or `off`. `on` starts the connector and the relay forwarder.             |
| `CASAMA_CLOUD_URL`, `CASAMA_CLOUD_KEY` | The link to Casama Cloud. A linked key holds an address and sends notifications. It can't spend money. |
| `CASAMA_INSTANCE_ID`     | This server's id at Casama Cloud. The same id gets the same address back.      |
| `CASAMA_PUBLIC_URL`, `CASAMA_PAGES_URL` | The public address, and the one for bots' pages.               |
| `CASAMA_LOCAL_URL`       | The address on this computer, which its own app keeps using.                   |
| `DISABLE_SIGNUP`, `SIGNUP_INVITED_ONLY`, `SIGNUP_HOOK_ENABLED`, `SIGNUP_HOOK_URI` | Who can make an account. See [Who can sign up](#who-can-sign-up). |
| `TRUSTED_CLIENT_IP_HEADER`, `AUTH_RATE_LIMIT_HEADER` | `cf-connecting-ip`, so rate limits count the real caller. |
| `CASAMA_REMOTE_ACCESS_BEFORE` | The values from before, so turning off restores them exactly.            |

`casama selfhost up`, `down` and `logs` add the `link` profile by themselves while remote access is
on.

## Troubleshooting

Start with `casama selfhost remote status`, then see
[Remote access](/self-hosting/troubleshooting#remote-access-casama-link) in Troubleshooting. It
follows the request's path: the phone, Cloudflare, the connector, and Casama Cloud.

## Related

- [Casama Link overview](/guide/casama-link)
- [Cloud computers and credits](/self-hosting/casama-link-cloud)
- [Self-hosting](/self-hosting/)
- [Configuration](/self-hosting/configuration#casama-link)
- [Troubleshooting](/self-hosting/troubleshooting#remote-access-casama-link)
- [CLI](/develop/cli)
