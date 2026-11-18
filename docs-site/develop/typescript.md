# TypeScript client

`@casama/client` is the TypeScript and JavaScript library for Casama. It gives you a typed client
for the whole [HTTP API](/develop/api), plus helpers to ask a bot and wait for its reply, follow a
run live and decide approvals. Your editor completes every path, parameter and field, and the
compiler checks them.

The types are generated from the API's OpenAPI document, and requests go through
[openapi-fetch](https://openapi-ts.dev/openapi-fetch/), a thin typed layer over `fetch`. It runs
anywhere `fetch` does: Node 20 or later, Bun, Deno, browsers and edge runtimes.

## Install

```sh
npm i @casama/client
```

Keep the client's version in step with your server's `api_version` (from `GET /v1/config`): it's
generated from that server version's routes.

## Connect

```ts
import { createCasamaClient } from "@casama/client";

const casama = createCasamaClient({
  apiUrl: "https://casama.example.com",
  token: process.env.CASAMA_TOKEN,
});

const { data: me } = await casama.GET("/v1/me");
console.log(`Signed in as ${me?.email}`);
```

`apiUrl` defaults to Casama Cloud, `https://api.casama.ai`.

| Option | What it does |
| --- | --- |
| `apiUrl` | The server's API address |
| `token` | A fixed access token, sent as `Authorization: Bearer` |
| `getToken` | A function called before every request for the current token. Use it when tokens refresh. |
| `fetch` | Your own `fetch`, for tests, proxies or retries |
| `headers` | Extra headers on every request |

## Sign in

The API takes a Casama sign-in token: the access token from the Supabase Auth server named in
`GET /v1/config` (see [Authentication](/develop/api#authentication)). The easiest way to get one
and keep it fresh is `@supabase/supabase-js`:

```ts
import { createClient } from "@supabase/supabase-js";
import { createCasamaClient } from "@casama/client";

const apiUrl = "https://casama.example.com";
const { data: config } = await createCasamaClient({ apiUrl }).GET("/v1/config");
const supabase = createClient(config!.supabase_url, config!.supabase_anon_key);
await supabase.auth.signInWithPassword({ email: "ana@example.com", password: "correct-horse-battery" });

const casama = createCasamaClient({
  apiUrl,
  getToken: async () => (await supabase.auth.getSession()).data.session?.access_token,
});
```

Supabase refreshes the session for you, and `getToken` hands the client the current token on every
request. For a quick script, `token` with a token you copied is enough; it lasts about an hour.

Workspace API keys (`ksk_...`) don't work on the HTTP API. They're for the
[hosted MCP endpoint](/guide/mcp) and [agent-to-agent](/develop/a2a) calls.

## List workspaces and bots

Raw calls name the path as it appears in the [API reference](/api/). They return
`{ data, error, response }`:

```ts
const { data: orgs } = await casama.GET("/v1/orgs");
const org = orgs!.items.find((o) => o.slug === "acme")!;

const { data: bots, error } = await casama.GET("/v1/bots", {
  params: { query: { org_id: org.id } },
});
if (error) throw new Error(error.detail ?? error.code);
for (const b of bots.items) console.log(`${b.name}: ${b.status}`);
```

## Ask a bot

`ask` starts a conversation (or continues one), sends your message, waits for the run to end and
returns the reply:

```ts
const reply = await casama.ask(botId, "Which invoices are overdue?");
console.log(reply.text);
console.log(reply.run.status, `$${reply.run.cost_usd.toFixed(4)}`);

// Carry on in the same conversation.
const more = await casama.ask(botId, "Draft a reminder for the oldest one.", {
  conversationId: reply.conversationId,
});
```

| Option | What it does |
| --- | --- |
| `conversationId` | Continue this conversation. Without it, `ask` starts a new one. |
| `title` | The new conversation's title |
| `timeoutMs` | Stop waiting after this long (default 10 minutes) and return what arrived, with `timedOut: true` |
| `onEvent` | Called for every event as it arrives, for example to print the reply live |
| `onApproval` | Called when the bot asks for approval (see [below](#approvals)) |
| `message` | Extra message fields, such as `attachments` or `skills` |
| `transport` | `sse` (default) streams the run; `poll` asks for new events every `pollIntervalMs` |
| `signal` | An `AbortSignal` to give up early |

The result has `text` (the text of the bot's finished messages), `run` (status, tokens, cost and
any error), `runId`, `conversationId`, `messageId`, every `events` it saw and `timedOut`. Each
message carries an `Idempotency-Key`, so a retry never sends it twice.

Print the reply as it's written:

```ts
await casama.ask(botId, "Write a haiku about invoices.", {
  onEvent: (e) => {
    if (e.type === "message.delta") process.stdout.write(e.payload.text);
  },
});
```

## Watch a run

`watchRun` follows a run you started some other way, for example from `POST
/v1/conversations/{id}/messages`, a routine or another app:

```ts
for await (const e of casama.watchRun(runId)) {
  switch (e.type) {
    case "message.delta":
      process.stdout.write(e.payload.text);
      break;
    case "tool.started":
      console.log(`\n[tool] ${e.payload.tool}`);
      break;
    case "run.failed":
      console.log(`\nFailed: ${e.payload.message} (${e.payload.error_code})`);
      break;
  }
}
```

- **Catch-up first.** You get everything that already happened, then live events as they come.
- **In order, once.** Events arrive by `seq`, with no repeats.
- **Reconnects.** If the stream drops, it reconnects with backoff (250 ms, doubling up to 8
  seconds) and picks up after the last event. After 8 failures in a row (`maxRetries`) it throws.
  Client errors, such as 404 `run_not_found`, throw at once.
- **Ends with the run.** The loop ends after `run.completed`, `run.failed` or `run.cancelled`.

`switch (e.type)` narrows `e.payload` to that event's fields. A newer server can send event types
this version doesn't list; ignore what you don't know. To resume later, pass the last `seq` you
handled as `afterSeq`. The [HTTP API page](/develop/api#event-types) describes each type.

## Approvals

When the bot needs a person to approve a step, the run waits on an `approval.requested` event.
Give `ask` an `onApproval` function and it answers for you:

```ts
const reply = await casama.ask(botId, "Clean up the old build folders.", {
  onApproval: async (req) => {
    const ok = await confirm(`Allow ${req.tool} (${req.risk} risk)?`);
    return ok ? "approved" : "denied";
  },
});
```

Return `{ decision: "approved", alwaysAllow: true }` to stop asking about that tool for that bot.
Denying fails only that step. Without `onApproval`, `ask` returns as soon as the run waits, with the
request in `pendingApproval`; decide it later with `decideApproval`:

```ts
if (reply.pendingApproval) {
  await casama.decideApproval(reply.pendingApproval.approval_id, "approved");
}
```

List everything waiting with
`casama.GET("/v1/approvals", { params: { query: { org_id: org.id, status: "pending" } } })`. See
[Autonomy and approvals](/guide/autonomy).

## Cancel a run

```ts
await casama.cancelRun(runId);
```

The run stops within about two seconds and `watchRun` ends with `run.cancelled`.

## Sites and domains

```ts
const site = await casama.sites.publish(pageId, { label: "crumb" });
console.log(site.address_url); // https://crumb.<sites zone>

const { domain, claim } = await casama.domains.connect(orgId, "bakery.com", { pageId });
for (const r of domain?.records ?? []) console.log(r.type, r.name, "→", r.value);
await casama.domains.check(domain!.id); // at most once every 10 seconds
```

Also `sites.list`, `sites.checkAddress`, `sites.unpublish`, `domains.list`, `domains.get`,
`domains.setSite`, `domains.disconnect` and `domains.search` (names and prices; buying happens in
the app). See [Sites and domains](/guide/sites-and-domains).

## Packs

```ts
const from = { url: "https://github.com/stackwares/casama/tree/main/packs/dev-kit" };
const preview = await casama.packs.preview(orgId, from);
console.log(preview.bots.map((b) => b.name), preview.reach);
// A link installs the commit the preview showed unless you pass one.
const result = await casama.packs.install(orgId, { ...from, commit: preview.commit ?? undefined }, {
  inputs: { repo: "acme/api" },
});
```

Also `packs.list`, `packs.checkUpdate`, `packs.update`, `packs.remove` (bots stay unless
`{ deleteBots: true }`), `packs.export` and `packs.share`. See [Packs](/develop/packs).

## Errors

Helpers (`ask`, `watchRun`, `decideApproval`, `cancelRun`, `sites`, `domains`) throw `CasamaError`, built from the
API's [problem details](/develop/api#errors). Match on `code`, which is stable:

```ts
import { CasamaError } from "@casama/client";

try {
  await casama.cancelRun(runId);
} catch (e) {
  if (e instanceof CasamaError && e.code === "run_finished") {
    console.log("Already done.");
  } else if (e instanceof CasamaError) {
    console.log(`${e.code}: ${e.detail ?? e.title}`);
    for (const f of e.errors) console.log(`  ${f.path}: ${f.message}`);
  } else {
    throw e; // a network error, not an API answer
  }
}
```

| Field | Meaning |
| --- | --- |
| `status` | The HTTP status |
| `code` | Stable code, such as `bot_not_found` or `rate_limited`. `http_502` and the like when the answer wasn't problem details (a proxy's error page). |
| `detail`, `title` | Sentences for people |
| `errors` | For `validation_failed`: one entry per bad field |
| `retryAfter` | For 429: seconds to wait |
| `requestId` | The `x-request-id`; include it when you report a problem |

Raw calls don't throw for API errors; they return `error`. Wrap one in `casama.unwrap` to get
`data` or a thrown `CasamaError`:

```ts
const run = await casama.unwrap(casama.GET("/v1/runs/{id}", { params: { path: { id: runId } } }));
console.log(run.status, run.tokens_in, run.tokens_out);
```

## Raw typed calls

Everything else in the [API reference](/api/) is a raw call: `GET`, `POST`, `PUT`, `PATCH` and
`DELETE`, with the path's parameters and body checked against the schema.

```ts
const { data: conversation } = await casama.POST("/v1/conversations", {
  body: { bot_id: botId, title: "From TypeScript" },
});

const { data: sent } = await casama.POST("/v1/conversations/{id}/messages", {
  params: { path: { id: conversation!.id } },
  headers: { "idempotency-key": crypto.randomUUID() },
  body: { text: "Summarise this week's tickets." },
});

const { data: page } = await casama.GET("/v1/runs/{id}/events", {
  params: { path: { id: sent!.run_id }, query: { after_seq: 0, limit: 500 } },
});
```

The schema types are exported too, for your own functions:

```ts
import type { Schemas, RunEvent } from "@casama/client";

type Bot = Schemas["Bot"];
function show(e: RunEvent) { /* ... */ }
```

`casama.api` is the underlying openapi-fetch client, for middleware such as logging or retries:
`casama.api.use({ onResponse: ({ response }) => console.log(response.status) })`.

## Related

- [HTTP API](/develop/api): authentication, errors and the event protocol
- [API reference](/api/): every endpoint, each one a raw call here
- [Dart SDK](/develop/sdk): the same for Dart and Flutter
- [Hosted MCP](/guide/mcp): use bots from AI apps without code
