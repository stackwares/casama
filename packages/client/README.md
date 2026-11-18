# @casama/client

A typed TypeScript client for the [Casama](https://casama.ai) HTTP API. Every path, parameter and
response is typed from the API's OpenAPI document, so your editor completes them and the compiler
checks them. It adds a few helpers on top: `ask` a bot and wait for its reply, `watchRun` to
follow a run live, `decideApproval`, and `CasamaError` for the API's problem details.

Works in Node 20+, Deno, Bun, browsers and edge runtimes: anything with `fetch`.

```sh
npm i @casama/client
```

## Quickstart

```ts
import { createCasamaClient } from "@casama/client";

const casama = createCasamaClient({
  apiUrl: "https://api.casama.ai", // or your own server
  token: process.env.CASAMA_TOKEN, // a Casama sign-in token
});

const { data: orgs } = await casama.GET("/v1/orgs");
const { data: bots } = await casama.GET("/v1/bots", {
  params: { query: { org_id: orgs!.items[0]!.id } },
});

const reply = await casama.ask(bots!.items[0]!.id, "What can you do for me? Three bullets.");
console.log(reply.text);
console.log(reply.run.status, `$${reply.run.cost_usd.toFixed(4)}`);
```

Pass `getToken` instead of `token` to hand out a fresh token on every request, for example from
`@supabase/supabase-js`.

## Watch a run

```ts
for await (const e of casama.watchRun(runId)) {
  if (e.type === "message.delta") process.stdout.write(e.payload.text);
  if (e.type === "tool.started") console.log(`\n[tool] ${e.payload.tool}`);
}
```

It streams over server-sent events, reconnects after drops without repeating events, and ends with
the run.

## Errors

Failed helper calls throw `CasamaError`, with the API's stable `code`. For raw calls, check
`error`, or wrap them in `casama.unwrap(...)` to get `data` or a thrown `CasamaError`.

Full guide: [docs.casama.ai/develop/typescript](https://docs.casama.ai/develop/typescript).

## Development

The types in `src/generated/schema.ts` come from `packages/contracts/openapi.json`. After the API
changes, run `pnpm --filter @casama/client gen`; a test fails while they're out of date.

License: Apache-2.0
