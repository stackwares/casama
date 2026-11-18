/**
 * Site addresses against the real Cloudflare (docs/SITES-AND-DOMAINS-PLAN.md §10, end of Phase 1):
 * a tunnel whose only ingress rule is a catch-all to the local pages port serves a published site
 * at name.<sites zone> over HTTPS. Removes everything it made. Never touches production: it runs
 * against the local stack (DATABASE_URL, the pages port) and a zone you name.
 *
 *   DATABASE_URL=postgres://…local… CF_ACCOUNT_ID=… CF_API_TOKEN=… CF_ZONE_ID=… \
 *   CASAMA_SITES_ZONE=<zone> node apps/server/scripts/sites-live-check.ts
 *
 * The local API must be running with the same CASAMA_SITES_ZONE and PAGES_PORT (default 8790).
 * The token needs Cloudflare Tunnel: Edit on the account and DNS: Edit on the zone.
 *
 * Instead of the zone's wildcard record (which production owns), it makes one proxied CNAME for a
 * random name, sites-check-<random>.<zone>: the same path a wildcard takes, one label deep so
 * Universal SSL covers it. Pass WILDCARD=1 on a fresh zone to make and remove `*.<zone>` instead.
 *
 * Optional: PAGES_PORT (8790), CONNECTOR_IMAGE (cloudflare/cloudflared:latest),
 * ORIGIN_HOST (host.docker.internal: how the connector container reaches this machine).
 */
import { execFileSync } from "node:child_process";
import { randomBytes } from "node:crypto";
import { request } from "node:http";
import postgres from "postgres";

const need = (k: string) => {
  const v = process.env[k];
  if (!v) throw new Error(`${k} is required`);
  return v;
};
const databaseUrl = need("DATABASE_URL");
const accountId = need("CF_ACCOUNT_ID");
const apiToken = need("CF_API_TOKEN");
const zoneId = need("CF_ZONE_ID");
const zone = need("CASAMA_SITES_ZONE").toLowerCase();
if (/(^|\.)casama\.(ai|link)$/.test(zone))
  throw new Error("The sites zone is never casama.ai or casama.link");
const pagesPort = Number(process.env.PAGES_PORT ?? 8790);
const image = process.env.CONNECTOR_IMAGE ?? "cloudflare/cloudflared:latest";
const originHost = process.env.ORIGIN_HOST ?? "host.docker.internal";
const wildcard = process.env.WILDCARD === "1";
const api = (process.env.CF_API_URL ?? "https://api.cloudflare.com/client/v4").replace(/\/$/, "");
const label = `sites-check-${randomBytes(5).toString("hex")}`;
const host = `${label}.${zone}`;
const marker = `casama-sites-check-${randomBytes(6).toString("hex")}`;

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const step = async <T>(name: string, fn: () => Promise<T>) => {
  const started = Date.now();
  try {
    const out = await fn();
    console.log(`ok    ${name} ${Date.now() - started}ms`);
    return out;
  } catch (e) {
    console.log(`FAIL  ${name}: ${(e as Error).message}`);
    throw e;
  }
};
async function cf<T>(method: string, path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${api}${path}`, {
    method,
    headers: {
      authorization: `Bearer ${apiToken}`,
      ...(body === undefined ? {} : { "content-type": "application/json" }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(20_000),
  });
  const json = (await res.json().catch(() => ({}))) as {
    success?: boolean;
    result?: T;
    errors?: Array<{ message?: string }>;
  };
  if (!res.ok || json.success === false)
    throw new Error(
      `${method} ${path}: ${res.status} ${json.errors?.map((e) => e.message).join("; ") ?? ""}`,
    );
  return json.result as T;
}

const sql = postgres(databaseUrl, { max: 1 });
const made: { pageId?: string; tunnelId?: string; recordId?: string; container?: string } = {};

try {
  await step("a published site on the local stack", async () => {
    const [bot] = await sql<{ id: string; org_id: string }[]>`
      select id, org_id from public.bots where archived_at is null order by created_at limit 1`;
    if (!bot) throw new Error("The local stack has no bot: sign in and make one first");
    const [page] = await sql<{ id: string }[]>`
      insert into public.pages (org_id, bot_id, title, html, visibility)
      values (${bot.org_id}, ${bot.id}, 'Sites live check', ${`<h1>${marker}</h1>`}, 'public') returning id`;
    made.pageId = page!.id;
    await sql`insert into public.sites (page_id, org_id) values (${page!.id}, ${bot.org_id})`;
    await sql`
      insert into public.site_hosts (hostname, kind, org_id, page_id, is_primary, status, verified_at)
      values (${host}, 'address', ${bot.org_id}, ${page!.id}, true, 'active', now())`;
  });

  await step("the pages port serves it by Host", async () => {
    // The API's host cache keeps a miss for a minute; a fresh name was never asked for.
    // fetch() drops a Host header, so this goes through node:http.
    const res = await new Promise<{ status: number; text: string }>((resolve, reject) => {
      const req = request(
        { host: "127.0.0.1", port: pagesPort, path: "/", headers: { host } },
        (r) => {
          let text = "";
          r.setEncoding("utf8");
          r.on("data", (c) => (text += c));
          r.on("end", () => resolve({ status: r.statusCode ?? 0, text }));
        },
      );
      req.on("error", reject);
      req.end();
    });
    if (res.status !== 200 || !res.text.includes(marker))
      throw new Error(`got ${res.status}; is the API running with CASAMA_SITES_ZONE=${zone}?`);
  });

  const tunnel = await step("a tunnel with one catch-all rule", async () => {
    const t = await cf<{ id: string }>("POST", `/accounts/${accountId}/cfd_tunnel`, {
      name: `casama-${label}`,
      config_src: "cloudflare",
    });
    made.tunnelId = t.id;
    await cf("PUT", `/accounts/${accountId}/cfd_tunnel/${t.id}/configurations`, {
      config: { ingress: [{ service: `http://${originHost}:${pagesPort}` }] },
    });
    return t;
  });

  await step(wildcard ? `the wildcard *.${zone}` : `a proxied CNAME for ${host}`, async () => {
    const r = await cf<{ id: string }>("POST", `/zones/${zoneId}/dns_records`, {
      type: "CNAME",
      name: wildcard ? `*.${zone}` : host,
      content: `${tunnel.id}.cfargotunnel.com`,
      proxied: true,
      comment: "Casama sites live check (removed when it ends)",
    });
    made.recordId = r.id;
  });

  await step("the connector runs", async () => {
    const token = await cf<string>("GET", `/accounts/${accountId}/cfd_tunnel/${tunnel.id}/token`);
    made.container = execFileSync(
      "docker",
      [
        "run",
        "-d",
        "--rm",
        "--add-host",
        `${originHost}:host-gateway`,
        image,
        "tunnel",
        "--no-autoupdate",
        "run",
        "--token",
        token,
      ],
      { encoding: "utf8" },
    ).trim();
  });

  await step(`https://${host} serves the site through the tunnel`, async () => {
    const deadline = Date.now() + 180_000;
    let last = "";
    while (Date.now() < deadline) {
      try {
        const res = await fetch(`https://${host}/`, { signal: AbortSignal.timeout(10_000) });
        const text = await res.text();
        last = `${res.status}`;
        if (res.status === 200 && text.includes(marker)) {
          if (!res.headers.get("strict-transport-security")) throw new Error("no HSTS header");
          const missing = await fetch(`https://${host}/nowhere`);
          if (missing.status !== 404) throw new Error(`/nowhere answered ${missing.status}`);
          const pages = await fetch(`https://${host}/s/anything`);
          if (pages.status !== 404)
            throw new Error(`a pages route answered ${pages.status} on a site host`);
          return;
        }
      } catch (e) {
        last = (e as Error).message;
      }
      await sleep(5000);
    }
    throw new Error(`not served within 3 minutes (last: ${last})`);
  });
  console.log("\nSite addresses work end to end.");
} finally {
  console.log("\nCleaning up");
  if (made.container)
    try {
      execFileSync("docker", ["stop", made.container], { stdio: "ignore" });
    } catch {}
  if (made.recordId)
    await cf("DELETE", `/zones/${zoneId}/dns_records/${made.recordId}`).catch((e) =>
      console.log(`  record: ${e.message}`),
    );
  if (made.tunnelId) {
    await cf("DELETE", `/accounts/${accountId}/cfd_tunnel/${made.tunnelId}/connections`).catch(
      () => {},
    );
    await cf("DELETE", `/accounts/${accountId}/cfd_tunnel/${made.tunnelId}`).catch((e) =>
      console.log(`  tunnel: ${e.message}`),
    );
  }
  if (made.pageId) await sql`delete from public.pages where id = ${made.pageId}`.catch(() => {});
  await sql.end();
}
