# Privacy and security

Your chats, memories and files belong to you. This page covers how to export your data, delete
your account, control how long run history is kept, encrypt workspace content, and protect your
sign-in. It also explains what Casama never sends to a model or anywhere else.

## Report or block

If a bot's reply is harmful, long-press it (or right-click on a computer) and choose **Report
reply**. You can also report a bot shared with your team from its profile, a gallery item from its
page, and a person from **Settings > People**. Reports go to the people who run the server, who
review each one and can take content down or suspend a workspace.

Tap a person in **Settings > People** to **block** them. Blocked people can't invite you to a
workspace, and reporting someone blocks them too. See and undo blocks in **Settings > Privacy >
Blocked people**.

## Export your data

1. Open **Settings**, and under **Sign-in & security**, tap **Privacy**.
2. Under **Your Data**, tap **Export My Data**.
3. Save or share the ZIP file. The app shows **Export ready** with its size.

From the CLI:

```sh
casama account export              # writes casama-export-<date>.zip
casama account export -o my-data.zip
```

The export is built with your own permissions, so it holds exactly what you can see. It contains
`account.json`, `workspaces.json`, and a folder per workspace with JSON files for bots,
conversations, messages, attachments, runs and their events, approvals, memories, skills,
routines, tickets, computers, checkpoints, connections, usage, billing records, members and the
audit log.

It never contains secret values, model keys, token hashes, device push tokens, memory vectors or
voice audio. Secrets and keys appear by name only.

The export doesn't include what bots made in the [Library](/guide/library), such as pages,
pictures and kept files. Open or download those from the Library. To keep one chat, export it on
its own as Markdown or JSON (`GET /v1/conversations/{id}/export`).

## Delete your account

1. Open **Settings → Privacy**.
2. Under **Danger Zone**, tap **Delete My Account**.
3. Type your email to confirm.

You're signed out everywhere at once, your devices stop receiving push notifications, and the app
shows the date your data will be erased. From the CLI:

```sh
casama account delete --confirm ana@example.com
```

### What gets deleted

| What | When |
| --- | --- |
| Your sessions, push devices and shared device data | Right away |
| Workspaces where you're the only owner, with their bots, chats and computers (including computer snapshots) | After the grace period |
| Your account | After the grace period |
| Your membership in workspaces that have another owner | After the grace period; the workspace and its data stay |

The grace period is set by the server with `ACCOUNT_DELETION_GRACE_DAYS` (0 to 30 days, default
7). The confirmation screen shows the exact date.

::: warning
A workspace where you're the only owner is deleted with your account, even if other people use it.
There's no screen for making someone else an owner yet, so ask for help first if the workspace
should stay.
:::

## Run history retention

Every run keeps a timeline of events: tool calls, outputs and errors. Workspace owners and admins
choose how long to keep it.

1. Open **Settings → Privacy**.
2. Under **Workspace**, set **Keep Run History For**: 30, 90, 180, 365 or 730 days.

The default is 180 days. Older run events are deleted automatically every day. Through the API you
can set any value from 7 to 3650 days (`run_event_retention_days`).

## Encrypt workspace content

Workspace owners can encrypt content before it's stored in the database, using a key that belongs
to the workspace.

1. Open **Settings → Workspace settings**.
2. Under **Encrypt Content**, tap **Turn On** and confirm.

The status shows **Turning on: encrypting what's already stored** while existing content is
encrypted in the background, then **On, with the server's key** or **On, with AWS KMS**. Turning it
off decrypts everything the same way, then deletes the key once nothing uses it any more.

What's encrypted: messages, run event details, memories, conversation summaries, tickets and their
comments, pages (with their versions) and knowledge text.

What changes when it's on:

- Exact-word search no longer matches text inside encrypted content. Titles and names still match,
  and memory and knowledge search still work by meaning.
- If the workspace is deleted, its key is destroyed and the content can't be recovered.
- You don't keep or copy any key. Casama creates the workspace's key and wraps it with the
  server's key.

To rotate, tap **Rotate Key**. This rewraps the workspace key with the server's current key;
content stays readable and nothing is re-encrypted.

If you think a copy of the database has leaked, rotating isn't enough: whoever has the copy and the
old server key could still open it. An owner can instead replace the workspace's key through the
API (`POST /v1/orgs/{id}/encryption/replace-key`). New content uses the new key at once, and
existing content moves onto it in the background; everything stays readable meanwhile. This also
replaces the About you keys of the workspace's members. On a self-hosted server, the instance owner
can replace every key on the server at once. There's no button for this in the app yet.

::: tip Self-hosting
Encryption needs `CONTENT_ENCRYPTION_KEY` (32 bytes, base64) or an AWS KMS key on the server.
`install.sh` generates the key for new installs and fills it in on older ones the next time it runs.
Without one, the setting reads **Not available: this server has no encryption key set up**. See
[Configuration](/self-hosting/configuration).
:::

## Two-step sign-in

Two-step sign-in asks for a 6-digit code from an authenticator app every time you sign in.

1. Open **Settings → Two-step sign-in**.
2. Tap **Set Up an Authenticator App**.
3. Scan the QR code with an authenticator app (such as 1Password, Google Authenticator or Authy),
   or type in the **Setup key**.
4. Enter the **6-digit code** and tap **Verify**.

You can add more than one authenticator with **Add Another Authenticator**, and rename or remove
each one. Removing your only authenticator turns two-step sign-in off.

After you enter your password, the app asks **Enter your code** before anything else. The CLI asks
for the code too, or takes it from `casama login --code` or the `CASAMA_2FA_CODE` environment
variable.

Workspaces can require two-step sign-in for owners and admins. See
[Workspaces and teams](/guide/workspaces#require-two-step-sign-in-for-admins).

## Passkeys

A passkey signs you in with Face ID, a fingerprint or your screen lock, with no password or email.

1. Open **Settings**, and under **Sign-in & security**, tap **Passkeys**.
2. Tap **Add a Passkey** and follow your device's prompt.

Each phone, computer or password manager keeps its own passkey. Add more with **Add Another
Passkey**, and rename or remove each one.

## App lock

The app lock asks you to unlock Casama when it opens and after time away, so someone holding your
unlocked phone or sitting at your computer can't read your chats.

1. Open **Settings**, and under **Sign-in & security**, tap **App lock**.
2. Turn on **Lock Casama** and pass the check once.

What unlocks it depends on the device:

| Device | Unlocks with |
| --- | --- |
| iPhone and iPad | Face ID, Touch ID or your passcode |
| Android (9 and later) | Your fingerprint, face or screen lock |
| Mac | Touch ID or your Mac's password |
| Windows | Windows Hello |
| Linux, Android 8, and devices without a screen lock | A 6-digit PIN you choose |
| Web | One of your [passkeys](#passkeys) (Casama offers to add one) |

**Lock after** sets how long Casama can be away before it asks again: **Right away**, 1, 5 or 15
minutes, or 1 hour. Away means in the background or minimised, and on a computer also behind other
apps or while the computer sleeps or its screen is locked.

While the lock is on:

- The app switcher shows a plain cover instead of your chats. On Android 13 and later, Recents does
  too. On Android you can also turn on **Block screenshots**, which keeps Casama out of
  screenshots, screen recordings and screen sharing.
- Your sign-in is kept in the device's keychain instead of the app's settings file.
- Links, shares and notification taps still open their page, which shows once you unlock. Calls
  still ring, and the lock screen says when one is waiting.
- The Mac's notch, the menu bar and the Windows and Linux tray don't send anything or answer
  requests. **Allow**, **Deny** and asking a bot open Casama instead. **Stop** still works.
- Allow and Deny on a phone's Lock Screen and in notifications still need Face ID, your passcode
  or the screen lock, as before.
- [Widgets](./widgets) show only counts, bot names and times, and their buttons open Casama,
  unless you turn on **Show details in widgets** in Settings → Widgets.
- Your [watch](./apple-watch) shows counts and bot names only, not what bots wrote, until you turn
  on **Show details on the watch** in Settings → Watch. A watch has a key of its own that can answer
  low and medium risk requests and nothing above them; remove it in Settings → Watch.

If unlocking can't work (you removed the device's passcode, or typed the wrong PIN five times),
tap **Sign Out** on the lock screen and sign in again. Signing out from the lock screen turns the
lock off on that device. The lock belongs to one account on one device: someone else signing in on
the same device starts with it off.

The lock covers Casama on that device. It doesn't encrypt the app's offline copy of your chats,
and it doesn't replace your device's own screen lock.

### Confirm risky actions

With **Confirm risky actions** on (the default, with or without the app lock), Casama asks you to
unlock again before you:

- delete your account or export your data,
- make an AI app key, a Casama Link key or a bot link,
- open the billing portal or change extra seats,
- rotate the workspace's encryption key,
- allow a high-risk request (denying never asks),
- take control of a computer.

Where the device has nothing to ask with (no screen lock, no PIN, no passkey on the web), these go
ahead without a check. A high-risk request allowed from the Mac's notch or the tray opens in
Casama, so the check happens there.

### Hide reply text

**Hide reply text** on the same page makes reply notifications say which bot replied, without its
words. It's the same switch as in **Settings → Notifications** and applies to all your devices.

Workspaces can require the app lock. See
[Workspaces and teams](/guide/workspaces#require-the-app-lock).

## Public links

Anything you share with a public link can be opened by anyone who has the link, without signing
in. That covers Library items, pages and read-only chat links. A public chat link shows the chat as
its starter saw it, and lists attachments by name without serving them. A chat that holds your
personal device data can't be made public.

For Library items and chats, making something public again gives a new link, and the old one
stops working. Public pages and Library items let anyone report them. After reports from three
different people, the item is hidden until the server's instance owner looks at it. See
[Sharing](/guide/sharing) and the [Library](/guide/library).

## What models never see

- **Secrets.** Bots refer to secrets with placeholders such as `{{secret:NAME}}`. Casama fills in
  the real value only when a request goes to a host the secret allows, after the model has
  written the call. Two-step seeds only ever produce codes. Known secret values are replaced with
  `[secret:NAME]` before anything reaches the model, the run timeline or logs.
- **Model keys and connection tokens.** These stay in the server's vault and are used by the
  server, not the bot.

See [Autonomy, approvals and action rules](/guide/autonomy#untrusted-content) for how Casama
handles untrusted content.

## Run tracing

Each run gets a trace id, shown on the run timeline with **Copy**. If the server runs an
OpenTelemetry collector, each run, model step and tool call becomes a span with the model, token
counts, cost, tool name, risk and outcome. Spans never carry prompts, messages, arguments or
results.

A self-hosted server can also send model calls to Langfuse for debugging. Those include model
input and output, with secrets and model keys removed. Workspaces can opt out with the
`llm_tracing` workspace setting through the [API](/develop/api).

## Telemetry and usage analytics

- **Usage ping:** off by default. A self-hosted server sends nothing unless its owner sets
  `TELEMETRY=on`. Then, once a week, it sends a random instance id, the Casama version, and the
  number of bots and users active in the last 7 days. Nothing else. The admin console shows
  whether it's on.
- **Product analytics:** On Casama Cloud, the official app and server capture usage metrics (screen
  views, milestone completions, daily activity rollups) to PostHog, and the same events (without
  the workspace rollups) to Google Analytics 4, to improve the app. Google Analytics runs without
  advertising ids, Google Signals or ad personalization. One switch covers both: you can opt out at
  any time in **Settings → Privacy → Share Usage Data**. On self-hosted servers, product analytics
  is completely disabled unless the server owner explicitly sets `PRODUCT_ANALYTICS=on` and supplies
  PostHog or Google Analytics keys (`ANALYTICS_PROVIDERS` picks which).
- **Who is counted:** a person is identified only by their account id, only on Casama Cloud, and only
  while their switch is on. Workspace admins can also turn usage data off for a whole workspace in
  **Settings → Privacy → Usage Data for This Workspace**. Automated work (routines, watchers, chat apps) is counted per
  workspace, never as a person being active. Deleting your account also deletes your analytics.
- **On someone else's server:** the official app connected to a self-hosted server sends crash
  reports and one anonymous "the app was used today" ping a day. No screens, no events, no account id.
- **Error reports:** An app sends crash reports to one service at a time: Sentry, PostHog or, in the
  official iOS, Android and macOS apps, Firebase Crashlytics. Which one can change without an app
  update; the reports themselves stay the same, without your account id. Reports never carry
  message text, prompts, secrets, personal device data, or email addresses. Turning off **Share
  Usage Data** stops crash reports too, and deletes Crashlytics reports not yet sent. Builds you make
  yourself send nothing to Crashlytics (it needs `CRASHLYTICS_ENABLED` and your own Firebase project).
- **Casama's websites:** casama.ai, these docs, the gallery and the web app's page send script errors
  to Sentry: the error, the page address without its query, and your browser. Nothing loads until a
  page breaks, nothing is stored on your device, and nothing is sent when your browser sends Do Not
  Track or Global Privacy Control.

## Limits

- The app has no screen to change member roles, so making someone else an owner before deleting
  your account isn't possible in the app yet.
- A deletion can't be undone from the app once requested.
- The `llm_tracing` opt-out has no switch in the app.

## Questions about your data

Email [privacy@casama.ai](mailto:privacy@casama.ai) for privacy questions or requests about data
held by Casama Cloud. On a self-hosted server, ask whoever runs it.

## Related

- [Workspaces and teams](/guide/workspaces)
- [Autonomy, approvals and action rules](/guide/autonomy)
- [Memory](/guide/memory)
- [Self-hosting configuration](/self-hosting/configuration)
- [Operations](/self-hosting/operations)
