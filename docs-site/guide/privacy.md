# Privacy and security

Your chats, memories and files belong to you. This page covers how to export your data, delete
your account, control how long run history is kept, encrypt workspace content, and protect your
sign-in. It also explains what Kasama never sends to a model or anywhere else.

## Export your data

1. Open **Settings**, and under **Privacy and more**, tap **Privacy**.
2. Under **Your data**, tap **Export my data**.
3. Save or share the ZIP file. The app shows **Export ready** with its size.

From the CLI:

```sh
kasama account export              # writes kasama-export-<date>.zip
kasama account export -o my-data.zip
```

The export is built with your own permissions, so it holds exactly what you can see. It contains
`account.json`, `workspaces.json`, and a folder per workspace with JSON files for bots,
conversations, messages, attachments, runs and their events, approvals, memories, skills,
routines, tickets, computers, checkpoints, connections, usage, billing records, members and the
audit log.

It never contains secret values, model keys, token hashes, device push tokens, memory vectors or
voice audio. Secrets and keys appear by name only.

## Delete your account

1. Open **Settings → Privacy**.
2. Under **Danger zone**, tap **Delete my account**.
3. Type your email to confirm.

You're signed out everywhere at once, your devices stop receiving push notifications, and the app
shows the date your data will be erased. From the CLI:

```sh
kasama account delete --confirm ana@example.com
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
Make someone else an owner first if the workspace should stay.
:::

## Run history retention

Every run keeps a timeline of events: tool calls, outputs and errors. Workspace owners and admins
choose how long to keep it.

1. Open **Settings → Privacy**.
2. Under **Workspace**, set **Keep run history for**: 30, 90, 180, 365 or 730 days.

The default is 180 days. Older run events are deleted automatically every day. Through the API you
can set any value from 7 to 3650 days (`run_event_retention_days`).

## Encrypt workspace content

Workspace owners can encrypt content before it's stored in the database, using a key that belongs
to the workspace.

1. Open **Settings → Workspace settings**.
2. Under **Encrypt content**, tap **Turn on** and confirm.

The status shows **Turning on: encrypting what's already stored** while existing content is
encrypted in the background, then **On, with the server's key** or **On, with AWS KMS**. Turning it
off decrypts everything the same way, then deletes the key.

What's encrypted: messages, run event details, memories, conversation summaries, tickets and their
comments, pages (with their versions) and knowledge text.

What changes when it's on:

- Exact-word search no longer matches text inside encrypted content. Titles and names still match,
  and memory and knowledge search still work by meaning.
- If the workspace is deleted, its key is destroyed and the content can't be recovered.
- You don't keep or copy any key. Kasama creates the workspace's key and wraps it with the
  server's key.

To rotate, tap **Rotate key**. This rewraps the workspace key with the server's current key;
content stays readable and nothing is re-encrypted.

::: tip Self-hosting
Encryption needs `CONTENT_ENCRYPTION_KEY` (32 bytes, base64) or an AWS KMS key on the server.
Without one, the setting reads **Not available: this server has no encryption key set up**. See
[Configuration](/self-hosting/configuration).
:::

## Two-step sign-in

Two-step sign-in asks for a 6-digit code from an authenticator app every time you sign in.

1. Open **Settings → Two-step sign-in**.
2. Tap **Set up an authenticator app**.
3. Scan the QR code with an authenticator app (such as 1Password, Google Authenticator or Authy),
   or type in the **Setup key**.
4. Enter the **6-digit code** and tap **Verify**.

You can add more than one authenticator with **Add another authenticator**, and rename or remove
each one. Removing your only authenticator turns two-step sign-in off.

After you enter your password, the app asks **Enter your code** before anything else. The CLI asks
for the code too, or takes it from `kasama login --code` or the `KASAMA_2FA_CODE` environment
variable.

Workspaces can require two-step sign-in for owners and admins. See
[Workspaces and teams](/guide/workspaces#require-two-step-sign-in-for-admins).

## What models never see

- **Secrets.** Bots refer to secrets with placeholders such as `{{secret:NAME}}`. Kasama fills in
  the real value only when a request goes to a host the secret allows, after the model has
  written the call. Two-step seeds only ever produce codes. Known secret values are replaced with
  `[secret:NAME]` before anything reaches the model, the run timeline or logs.
- **Model keys and connection tokens.** These stay in the server's vault and are used by the
  server, not the bot.

See [Autonomy, approvals and action rules](/guide/autonomy#untrusted-content) for how Kasama
handles untrusted content.

## Run tracing

Each run gets a trace id, shown on the run timeline with **Copy**. If the server runs an
OpenTelemetry collector, each run, model step and tool call becomes a span with the model, token
counts, cost, tool name, risk and outcome. Spans never carry prompts, messages, arguments or
results.

A self-hosted server can also send model calls to Langfuse for debugging. Those include model
input and output, with secrets and model keys removed. Workspaces can opt out with the
`llm_tracing` workspace setting through the [API](/develop/api).

## Telemetry

- **Usage ping:** off by default. A self-hosted server sends nothing unless its owner sets
  `TELEMETRY=on`. Then, once a week, it sends a random instance id, the Kasama version, and the
  number of bots and users active in the last 7 days. Nothing else. The admin console shows
  whether it's on.
- **Error reports and product analytics:** off unless whoever builds the app or runs the server
  adds a Sentry or PostHog key. When on, reports never carry message text, prompts, secrets or
  email addresses.

## Limits

- The app has no screen to change member roles, so making someone else an owner before deleting
  your account isn't possible in the app yet.
- A deletion can't be undone from the app once requested.
- The `llm_tracing` opt-out has no switch in the app.

## Related

- [Workspaces and teams](/guide/workspaces)
- [Autonomy, approvals and action rules](/guide/autonomy)
- [Memory](/guide/memory)
- [Self-hosting configuration](/self-hosting/configuration)
- [Operations](/self-hosting/operations)
