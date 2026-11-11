# Webhooks

Webhooks let other services start work in Kasama. The main kind is a **routine webhook**: a
routine whose trigger is an HTTP request instead of a schedule. GitHub can call it on a push or a
new issue, or your own system can call it when something happens, and the bot gets the request's
body as context.

This page is about webhooks coming **into** Kasama. Every one is checked with an HMAC signature, so
only senders who know the secret can trigger anything.

## Routine webhooks

There are two kinds:

| Trigger | URL | Signature header |
| --- | --- | --- |
| `github` | `https://kasama.example.com/hooks/github/<routine id>` | `X-Hub-Signature-256` (sent by GitHub) |
| `webhook` | `https://kasama.example.com/hooks/custom/<routine id>` | `X-Kasama-Signature` (you compute it) |

Both use the same signature: `sha256=` followed by the hex HMAC-SHA256 of the raw request body,
keyed with the routine's secret.

### Create one

In the app, create a routine and pick a webhook or GitHub trigger (see [Routines](/guide/routines)).
Or use the API:

```sh
curl -s -X POST "https://kasama.example.com/v1/bots/$BOT/routines" \
  -H "authorization: Bearer $TOKEN" \
  -H "content-type: application/json" \
  -d '{
    "name": "Triage new orders",
    "instructions": "A new order came in. Check stock and draft a confirmation email.",
    "trigger": "webhook"
  }'
```

The response is the routine, plus two fields shown **only this once**:

```json
{
  "id": "8c3e5f0a-2b1d-4c6e-9f7a-1d2c3b4a5e6f",
  "name": "Triage new orders",
  "webhook_url": "https://kasama.example.com/hooks/custom/8c3e5f0a-2b1d-4c6e-9f7a-1d2c3b4a5e6f",
  "webhook_secret": "4b1f0c9e8d7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a",
  "...": "..."
}
```

Store the secret somewhere safe. Kasama keeps it in its vault and never shows it again. If you
lose it, create a new routine.

For a GitHub routine, set `"trigger": "github"` and optionally `"events"`: the GitHub event names
to accept, such as `["push", "issues"]` (up to 20). Without `events`, every event starts a run.

::: tip Behind a proxy
`webhook_url` is built from the address your request reached. If the API sits behind a proxy,
check that the URL uses your public address before you hand it out.
:::

### GitHub

In the repository (or organization), open **Settings → Webhooks → Add webhook** and fill in:

| Field | Value |
| --- | --- |
| Payload URL | The routine's `webhook_url` |
| Content type | `application/json` |
| Secret | The routine's `webhook_secret` |
| Events | The ones you listed in `events`, or the ones you want |

GitHub signs each delivery with `X-Hub-Signature-256` and names the event in `X-GitHub-Event`.
Kasama checks both.

### Your own service

Send a `POST` with any body (JSON is typical) and the signature in `X-Kasama-Signature`. You can
also name the event in `X-Kasama-Event`: the bot sees it, and if the routine has `events`, only
those event names start a run.

**Shell (OpenSSL):**

```sh
URL=https://kasama.example.com/hooks/custom/8c3e5f0a-2b1d-4c6e-9f7a-1d2c3b4a5e6f
SECRET=4b1f0c9e8d7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a
BODY='{"order_id": 1042, "customer": "Ana Cruz", "total": "129.00"}'

SIG="sha256=$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$SECRET" -hex | sed 's/^.* //')"

curl -s -X POST "$URL" \
  -H "content-type: application/json" \
  -H "x-kasama-signature: $SIG" \
  -H "x-kasama-event: order.created" \
  --data-binary "$BODY"
```

**Node.js:**

```js
import { createHmac } from "node:crypto";

const url = "https://kasama.example.com/hooks/custom/8c3e5f0a-2b1d-4c6e-9f7a-1d2c3b4a5e6f";
const secret = process.env.KASAMA_WEBHOOK_SECRET;
const body = JSON.stringify({ order_id: 1042, customer: "Ana Cruz", total: "129.00" });

const signature = `sha256=${createHmac("sha256", secret).update(body).digest("hex")}`;

const res = await fetch(url, {
  method: "POST",
  headers: {
    "content-type": "application/json",
    "x-kasama-signature": signature,
    "x-kasama-event": "order.created",
  },
  body,
});
console.log(res.status); // 202
```

**Python:**

```python
import hashlib
import hmac
import json
import os
import urllib.request

url = "https://kasama.example.com/hooks/custom/8c3e5f0a-2b1d-4c6e-9f7a-1d2c3b4a5e6f"
secret = os.environ["KASAMA_WEBHOOK_SECRET"].encode()
body = json.dumps({"order_id": 1042, "customer": "Ana Cruz", "total": "129.00"}).encode()

signature = "sha256=" + hmac.new(secret, body, hashlib.sha256).hexdigest()

req = urllib.request.Request(
    url,
    data=body,
    method="POST",
    headers={
        "content-type": "application/json",
        "x-kasama-signature": signature,
        "x-kasama-event": "order.created",
    },
)
print(urllib.request.urlopen(req).status)  # 202
```

Sign the exact bytes you send. If you serialize the JSON twice, or a library reformats it, the
signature won't match.

### What happens

1. Kasama answers **202** `{"accepted": true}` right away, before it checks anything. It answers the
   same way for a bad signature or a routine that doesn't exist, so nobody can probe which
   routines exist.
2. The worker checks the signature with a constant-time comparison. The request is dropped
   silently if the signature is wrong, the routine is turned off or has another trigger, or the
   event isn't one the routine accepts.
3. Otherwise the bot starts a run. It sees the routine's instructions, then the event: an
   `Event: <name>` line (from `X-GitHub-Event` or `X-Kasama-Event`) and the body, up to its first
   50,000 characters. The body is marked as untrusted outside content, so the bot treats it as
   data, not as instructions from you.
4. Like any routine run, it happens in the routine's conversation: by default the latest chat
   between the routine's creator and the bot, or a new one named after the routine.

Because a bad request also gets a 202, test a new webhook by checking that a run appears in the
bot's chat. If nothing shows up, check the secret and that you signed the raw body.

### Retries and duplicates

Kasama doesn't deduplicate deliveries: each request with a valid signature starts its own run. A
202 tells GitHub and most senders that the delivery succeeded, so they won't retry it. If your own
sender retries on network errors, expect an occasional second run, or make the instructions safe to
repeat (for example "skip orders you've already confirmed").

Kasama answers something other than 202 only when:

| Status | When | What to do |
| --- | --- | --- |
| 413 | The body is over 1 MB | Send less: an id and a link instead of the whole object |
| 429 | Too many requests from one address in a minute | Wait for `Retry-After` seconds, then retry |

## Git sync webhook

[Git sync](/develop/workspace-files#git-sync) keeps a workspace's routines and skills in a GitHub
repository. Kasama checks the repository every 10 minutes anyway; a push webhook makes it pick up
changes within a minute.

When an admin first sets up git sync, Kasama shows a webhook URL and secret, once:

| Field | Value |
| --- | --- |
| Payload URL | `https://kasama.example.com/hooks/git-sync/<workspace id>` |
| Content type | `application/json` |
| Secret | The secret shown at setup |
| Events | Just the push event |

Unlike routine webhooks, this one answers right away: **202** `{"ok": true}` when the
`X-Hub-Signature-256` signature matches, and **401** `bad_signature` when it doesn't (or git sync
isn't set up or is off). GitHub's delivery log shows which.

## Other inbound webhooks

Some features receive webhooks from a provider you connect. Kasama shows the URL when you set the
feature up, and checks each provider's own signature:

| Feature | URL | Checked with |
| --- | --- | --- |
| [Chat apps](/guide/chat-apps) | `/hooks/channels/<channel id>` | The provider's own signature (each adapter verifies its platform's scheme) |
| [Payments](/guide/payments) | `/hooks/payments/<workspace id>` | `Stripe-Signature`, with the signing secret of the Stripe webhook you created |

Paste these URLs into the provider's settings as the feature's guide describes. You don't call
them yourself.

## Limits

| What | Limit |
| --- | --- |
| Body size | 1 MB (413 above it) |
| Body the bot sees | The first 50,000 characters |
| Requests | 120 a minute per sender IP address by default, shared by all `/hooks/` URLs |
| GitHub `events` per routine | 20 |

## Related

- [Routines](/guide/routines): schedules, triggers and where results go
- [Routines and skills as files](/develop/workspace-files): git sync setup
- [HTTP API](/develop/api): creating routines from code
- [Autonomy and approvals](/guide/autonomy): what a webhook-started run may do on its own
