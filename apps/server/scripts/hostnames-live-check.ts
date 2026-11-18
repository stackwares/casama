/**
 * Custom hostnames against the real Cloudflare (docs/SITES-AND-DOMAINS-PLAN.md §10, end of
 * Phase 2). Proves, on a test domain whose DNS is on a Cloudflare account you control:
 *
 *   1. `www.<test domain>` with one CNAME to its own target goes pending → active on Cloudflare
 *      for SaaS, and our DNS-over-HTTPS proof (A) sees it;
 *   2. the bare domain, flattened at Cloudflare and set to DNS only, goes active with proof B
 *      (the ownership TXT);
 *   3. deleting and re-adding a hostname gives a NEW ownership value (§7.4: otherwise proof B
 *      becomes our own _casama record) — the result is printed, write it in §14;
 *   4. with ALIAS_DOMAIN set (a domain on a DNS company with ALIAS/ANAME records, its records
 *      added by hand as the script prints), whether a bare domain through ALIAS goes active —
 *      decides CASAMA_SITES_APEX=aname (§7.5);
 *   5. with the local stack's sites tunnel running (sites-live-check.ts), the host serves this
 *      server's /_casama/probe over HTTPS;
 *   6. removal: the hostname is gone at Cloudflare and stops serving.
 *
 * Removes everything it made. Never touches production: the sites zone's custom hostnames are
 * inside the included 100, and the test domain is yours.
 *
 *   CASAMA_SITES_ZONE=<zone> SITES_CF_ZONE_ID=… SITES_CF_API_TOKEN=… \
 *   TEST_DOMAIN=<domain> TEST_CF_ZONE_ID=… TEST_CF_API_TOKEN=… \
 *   [ALIAS_DOMAIN=<domain>] [INSTANCE_ID=<local CASAMA_INSTANCE_ID>] \
 *   node apps/server/scripts/hostnames-live-check.ts
 *
 * The sites zone needs Cloudflare for SaaS on with a fallback origin, and the wildcard record
 * (`*.<zone>`) so every target resolves. SITES_CF_API_TOKEN: SSL and Certificates: Edit on the
 * sites zone. TEST_CF_API_TOKEN: DNS: Edit on the test domain's zone.
 */
import { randomBytes } from "node:crypto";
import { domainTarget } from "@casama/domain";
import { DohLookup } from "../src/sites/dns.ts";
import { CloudflareHostnames } from "../src/sites/hostnames.ts";

const need = (k: string) => {
  const v = process.env[k];
  if (!v) throw new Error(`${k} is required`);
  return v;
};
const zone = need("CASAMA_SITES_ZONE").toLowerCase();
if (/(^|\.)casama\.(ai|link)$/.test(zone))
  throw new Error("The sites zone is never casama.ai or casama.link");
const testDomain = need("TEST_DOMAIN").toLowerCase();
const testZoneId = need("TEST_CF_ZONE_ID");
const testToken = need("TEST_CF_API_TOKEN");
const aliasDomain = process.env.ALIAS_DOMAIN?.toLowerCase();
const instanceId = process.env.INSTANCE_ID;
const api = (process.env.CF_API_URL ?? "https://api.cloudflare.com/client/v4").replace(/\/$/, "");

const edge = new CloudflareHostnames({
  zoneId: need("SITES_CF_ZONE_ID"),
  apiToken: need("SITES_CF_API_TOKEN"),
  apiUrl: process.env.CF_API_URL,
});
const dns = new DohLookup({
  urls: ["https://cloudflare-dns.com/dns-query", "https://dns.google/resolve"],
});
const alphabet = "abcdefghijklmnopqrstuvwxyz0123456789";
const target = domainTarget(zone, [...randomBytes(16)].map((b) => alphabet[b % 36]).join(""));
const www = `www.${testDomain}`;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const results: string[] = [];

const step = async <T>(name: string, fn: () => Promise<T>) => {
  const started = Date.now();
  try {
    const out = await fn();
    console.log(`ok    ${name} ${Math.round((Date.now() - started) / 1000)}s`);
    return out;
  } catch (e) {
    console.log(`FAIL  ${name}: ${(e as Error).message}`);
    throw e;
  }
};

async function testDns<T>(method: string, path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${api}/zones/${testZoneId}/dns_records${path}`, {
    method,
    headers: {
      authorization: `Bearer ${testToken}`,
      ...(body ? { "content-type": "application/json" } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(20_000),
  });
  const json = (await res.json()) as {
    success: boolean;
    result: T;
    errors?: { message: string }[];
  };
  if (!json.success)
    throw new Error(json.errors?.map((e) => e.message).join("; ") ?? `${res.status}`);
  return json.result;
}

async function until(what: string, ms: number, check: () => Promise<boolean>) {
  const deadline = Date.now() + ms;
  while (Date.now() < deadline) {
    if (await check().catch(() => false)) return;
    await sleep(10_000);
  }
  throw new Error(`${what}: not within ${Math.round(ms / 60_000)} minutes`);
}

const made = { refs: [] as string[], records: [] as string[] };

try {
  const w = await step(`register ${www}`, async () => {
    const r = await edge.add(www);
    made.refs.push(r.ref);
    return r;
  });
  await step(`CNAME ${www} → ${target} (DNS only)`, async () => {
    const r = await testDns<{ id: string }>("POST", "", {
      type: "CNAME",
      name: www,
      content: target,
      proxied: false,
      comment: "Casama hostnames live check",
    });
    made.records.push(r.id);
  });
  await step("proof A seen by both resolvers", () =>
    until("proof A", 5 * 60_000, async () => !!(await dns.cnames(www))?.includes(target)),
  );
  const t0 = Date.now();
  await step(`${www} active at the edge`, () =>
    until("active", 10 * 60_000, async () => (await edge.get(w.ref))?.state === "active"),
  );
  results.push(
    `www went active ${Math.round((Date.now() - t0) / 1000)}s after the record was seen`,
  );

  const bare = await step(`register ${testDomain} (bare)`, async () => {
    const r = await edge.add(testDomain);
    made.refs.push(r.ref);
    return r;
  });
  await step("flattened CNAME at the root and the ownership TXT", async () => {
    for (const rec of [
      { type: "CNAME", name: testDomain, content: target, proxied: false },
      { type: "TXT", name: bare.ownership.name, content: bare.ownership.value },
    ]) {
      const r = await testDns<{ id: string }>("POST", "", { ...rec, comment: "Casama live check" });
      made.records.push(r.id);
    }
  });
  await step("proof B seen by both resolvers", () =>
    until(
      "proof B",
      5 * 60_000,
      async () => !!(await dns.txt(bare.ownership.name))?.includes(bare.ownership.value),
    ),
  );
  await step(`${testDomain} active at the edge`, () =>
    until("bare active", 10 * 60_000, async () => (await edge.get(bare.ref))?.state === "active"),
  );
  results.push("bare domain on Cloudflare DNS: active");

  await step("re-adding a hostname gives a new ownership value", async () => {
    await edge.remove(w.ref);
    made.refs.splice(made.refs.indexOf(w.ref), 1);
    const again = await edge.add(www);
    made.refs.push(again.ref);
    const fresh = again.ownership.value !== w.ownership.value;
    results.push(
      fresh
        ? "re-added hostname: NEW ownership value (proof B as built)"
        : "re-added hostname: SAME ownership value — switch proof B to our own _casama record (§7.4)",
    );
  });

  if (instanceId)
    await step(`https://${www}/_casama/probe answers this server`, () =>
      until("probe", 5 * 60_000, async () => {
        const res = await fetch(`https://${www}/_casama/probe`, {
          signal: AbortSignal.timeout(10_000),
        });
        return (await res.text()).includes(instanceId);
      }),
    );

  if (aliasDomain) {
    const a = await step(`register ${aliasDomain} (ALIAS)`, async () => {
      const r = await edge.add(aliasDomain);
      made.refs.push(r.ref);
      return r;
    });
    console.log(
      `\nAt ${aliasDomain}'s DNS company add:\n  ALIAS ${aliasDomain} → ${target}\n  TXT   ${a.ownership.name} = ${a.ownership.value}\nWaiting up to 20 minutes…`,
    );
    try {
      await until(
        "ALIAS active",
        20 * 60_000,
        async () => (await edge.get(a.ref))?.state === "active",
      );
      results.push(
        `bare domain through ALIAS (${aliasDomain}): ACTIVE — CASAMA_SITES_APEX=aname can ship`,
      );
    } catch {
      const st = await edge.get(a.ref).catch(() => null);
      results.push(
        `bare domain through ALIAS (${aliasDomain}): NOT active (${st?.state}, ${st?.reason}) — keep CASAMA_SITES_APEX=forward`,
      );
    }
  }

  await step("removal stops it", async () => {
    for (const ref of made.refs.splice(0)) await edge.remove(ref);
    if ((await edge.get(w.ref)) !== null) throw new Error("still at the edge");
  });
  console.log("\nCustom hostnames work end to end.");
} finally {
  console.log("\nCleaning up");
  for (const ref of made.refs)
    await edge.remove(ref).catch((e) => console.log(`  hostname: ${e.message}`));
  for (const id of made.records)
    await testDns("DELETE", `/${id}`).catch((e) =>
      console.log(`  record: ${(e as Error).message}`),
    );
  if (results.length) console.log(`\nResults (write these in §14):\n- ${results.join("\n- ")}`);
}
