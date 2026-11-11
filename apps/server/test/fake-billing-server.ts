/**
 * Local billing mock for trying Casama Cloud billing end to end without accounts (D-070).
 * Starts fake Dodo / App Store / Google Play servers, writes an env file for a billing-enabled
 * API, and sets the plans' Dodo product ids. Opening a checkout URL "pays" it and delivers the
 * signed webhook to the API.
 *
 *   node --env-file=.env apps/server/test/fake-billing-server.ts [api-url] [env-out]
 *   MODE=api PORT=8788 node --env-file=.env --env-file=<env-out> apps/server/src/main.ts
 */
import { writeFileSync } from "node:fs";
import postgres from "postgres";
import { billingEnv, startFakeBilling } from "./fake-billing.ts";

const apiUrl = process.argv[2] ?? "http://127.0.0.1:8788";
const out = process.argv[3] ?? "/tmp/casama-billing.env";
const f = await startFakeBilling({
  deliverTo: apiUrl,
  port: Number(process.env.FAKE_BILLING_PORT ?? 8799),
});
const env = { ...billingEnv(f), PORT: new URL(apiUrl).port || "8788" };
writeFileSync(
  out,
  Object.entries(env)
    .map(([k, v]) =>
      // JSON stays literal in single quotes; PEM keeps its real newlines in double quotes.
      v.startsWith("{") ? `${k}='${v}'` : v.includes("\n") ? `${k}="${v}"` : `${k}=${v}`,
    )
    .join("\n"),
  { mode: 0o600 },
);
const sql = postgres(process.env.DATABASE_URL as string, { max: 1 });
await sql`update public.plans set dodo_product_id = 'pdt_sub_' || code where code in ('pro', 'pro_yearly')`;
await sql`update public.credit_packs set dodo_product_id = 'pdt_pack_' || code`;
await sql.end();
console.log(`fake billing on ${f.url}; env written to ${out}; webhooks go to ${apiUrl}`);
