/**
 * Casama Link against the real Cloudflare (D-296): runs the tunnel adapter, the connector image
 * and the relay credentials for real, then removes everything it made.
 *
 *   CF_ACCOUNT_ID=… CF_API_TOKEN=… node apps/server/scripts/link-live-check.ts
 *
 * Optional:
 *   CF_ZONE_ID, CF_ZONE    the address zone. Without them the two DNS calls per address are
 *                          answered here and only the tunnel side is real; with them the records
 *                          are made for real and the address is fetched over https.
 *   TURN_KEY_ID, TURN_API_TOKEN   the relay service's key, to ask for real credentials.
 *   CONNECTOR_IMAGE        default casama/connector:local (build infra/connector first).
 *
 * Every tunnel it makes is named casama-<random label>, which can't be an existing tunnel's name.
 */
import { execFileSync, spawnSync } from "node:child_process";
import { randomBytes } from "node:crypto";
import { chmodSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { CloudflareTunnels, tunnelName } from "../src/link/tunnels.ts";

const need = (k: string) => {
  const v = process.env[k];
  if (!v) throw new Error(`${k} is required`);
  return v;
};
const accountId = need("CF_ACCOUNT_ID");
const apiToken = need("CF_API_TOKEN");
const zoneId = process.env.CF_ZONE_ID;
const zone = process.env.CF_ZONE ?? "connect-check.invalid";
const realDns = !!(zoneId && process.env.CF_ZONE);
const image = process.env.CONNECTOR_IMAGE ?? "casama/connector:local";

const results: Array<{ step: string; ok: boolean; detail?: string }> = [];
const step = async (name: string, fn: () => Promise<unknown>) => {
  const started = Date.now();
  try {
    const out = await fn();
    const detail = typeof out === "string" ? out : undefined;
    results.push({ step: name, ok: true, detail });
    console.log(`ok    ${name}${detail ? ` (${detail})` : ""} ${Date.now() - started}ms`);
  } catch (e) {
    results.push({ step: name, ok: false, detail: (e as Error).message });
    console.log(`FAIL  ${name}: ${(e as Error).message}`);
    throw e;
  }
};
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const until = async <T>(what: string, ms: number, fn: () => Promise<T | null | undefined>) => {
  const end = Date.now() + ms;
  for (;;) {
    const v = await fn().catch(() => null);
    if (v) return v;
    if (Date.now() > end) throw new Error(`timed out waiting for ${what}`);
    await sleep(3000);
  }
};

/** Without a zone: DNS calls are answered from memory, everything else goes to Cloudflare. */
const records = new Map<string, { id: string; name: string; type: string; content: string }>();
const dnsCalls: string[] = [];
const net: typeof fetch = async (input, init) => {
  const url = String(input);
  if (realDns || !url.includes("/dns_records")) return fetch(input, init);
  const method = init?.method ?? "GET";
  dnsCalls.push(`${method} ${new URL(url).pathname.split("/dns_records")[1] || "/"}`);
  const ok = (result: unknown) => Response.json({ success: true, result });
  if (method === "GET") {
    const name = new URL(url).searchParams.get("name.exact");
    return ok([...records.values()].filter((r) => r.name === name));
  }
  if (method === "POST") {
    const body = JSON.parse(String(init?.body));
    const r = { id: randomBytes(8).toString("hex"), ...body };
    records.set(r.id, r);
    return ok(r);
  }
  const id = url.split("/").pop() as string;
  if (method === "DELETE") records.delete(id);
  return ok({ id });
};

const cf = new CloudflareTunnels({
  accountId,
  zoneId: zoneId ?? "no-zone",
  zone,
  apiToken,
  fetch: net,
});
const label = `chk${randomBytes(6).toString("hex")}`.slice(0, 12);
const dir = mkdtempSync(join(tmpdir(), "connect-check-"));
const container = `casama-link-check-${label}`;
const network = `casama-link-check-${label}`;
let tunnelId = "";

const docker = (args: string[]) => execFileSync("docker", args, { encoding: "utf8" }).trim();

async function main() {
  console.log(
    `label ${label}, tunnel ${tunnelName(label)}, DNS ${realDns ? `real (${zone})` : "answered locally"}`,
  );
  let before = 0;
  await step("count the account's tunnels", async () => {
    before = await cf.count();
    return `${before}`;
  });
  await step("make the tunnel, its routes and its two addresses", async () => {
    tunnelId = (await cf.provision(label, { app: "http://origin:80", pages: "http://origin:80" }))
      .tunnelId;
    return tunnelId;
  });
  await step("asking again adopts the same tunnel (a retry after a failure)", async () => {
    const again = (
      await cf.provision(label, { app: "http://origin:80", pages: "http://origin:80" })
    ).tunnelId;
    if (again !== tunnelId) throw new Error(`made a second tunnel ${again}`);
    if (records.size && records.size !== 2) throw new Error(`${records.size} records, wanted 2`);
  });
  await step("a new tunnel isn't connected yet", async () => {
    const s = await cf.status(tunnelId);
    if (!s || s.state === "healthy") throw new Error(`status ${JSON.stringify(s)}`);
    return s.state;
  });
  let token = "";
  await step("fetch the connector's secret", async () => {
    token = await cf.token(tunnelId);
    if (token.length < 50) throw new Error("the secret is too short");
    return `${token.length} characters`;
  });

  await step("the connector image holds the tunnel open with that secret", async () => {
    const file = join(dir, "token");
    writeFileSync(file, token);
    chmodSync(dir, 0o755);
    chmodSync(file, 0o644);
    docker(["network", "create", network]);
    // What the address leads to: a tiny web server standing in for the stack's Caddy.
    docker([
      "run",
      "-d",
      "--rm",
      "--name",
      `${container}-origin`,
      "--network",
      network,
      "--network-alias",
      "origin",
      "busybox:1.37",
      "sh",
      "-c",
      "mkdir -p /w && echo casama-link-check > /w/index.html && httpd -f -p 80 -h /w",
    ]);
    docker([
      "run",
      "-d",
      "--rm",
      "--name",
      container,
      "--network",
      network,
      "-v",
      `${dir}:/connect:ro`,
      image,
    ]);
    const s = await until("the tunnel to be healthy", 120_000, async () => {
      const st = await cf.status(tunnelId);
      return st && (st.state === "healthy" || st.state === "degraded") ? st : null;
    });
    return s.state;
  });
  await step("the connector reports ready on its health check", async () => {
    await until("cloudflared's readiness", 60_000, async () => {
      const r = spawnSync(
        "docker",
        ["exec", container, "wget", "-q", "-O", "-", "http://127.0.0.1:2000/ready"],
        {
          encoding: "utf8",
        },
      );
      return r.status === 0 ? "ready" : null;
    });
  });
  await step("the account's count went up by one", async () => {
    const n = await cf.count();
    if (n !== before + 1) throw new Error(`${n}, wanted ${before + 1}`);
    return `${n}`;
  });
  if (realDns) {
    await step("the address answers over https through the tunnel", async () => {
      const body = await until("the address to answer", 180_000, async () => {
        const r = await fetch(`https://${label}.${zone}/`, { signal: AbortSignal.timeout(10_000) });
        const t = await r.text();
        return r.ok && t.includes("casama-link-check") ? t.trim() : null;
      });
      return body;
    });
    await step("the pages address answers too", async () => {
      await until("the pages address", 120_000, async () => {
        const r = await fetch(`https://${label}-p.${zone}/`, {
          signal: AbortSignal.timeout(10_000),
        });
        return r.ok ? "ok" : null;
      });
    });
  }

  await step("remove it while the connector is still attached", async () => {
    await cf.remove(label, tunnelId);
    const s = await cf.status(tunnelId);
    if (s) throw new Error(`still there: ${JSON.stringify(s)}`);
    if (records.size) throw new Error(`${records.size} records left`);
  });
  await step("removing again is not an error", async () => {
    await cf.remove(label, tunnelId);
  });
  await step("the count is back where it was", async () => {
    const n = await until("the count to settle", 30_000, async () =>
      (await cf.count()) === before ? before : null,
    );
    return `${n}`;
  });
  if (!realDns)
    results.push({ step: "DNS calls answered locally", ok: true, detail: dnsCalls.join(", ") });

  const key = process.env.TURN_KEY_ID;
  const turnToken = process.env.TURN_API_TOKEN;
  if (key && turnToken) {
    const { CloudflareTurn } = await import("../src/link/turn.ts");
    await step("the relay service hands out credentials", async () => {
      const c = await new CloudflareTurn({ keyId: key, apiToken: turnToken }).generate(600);
      if (!c.username || !c.credential) throw new Error("no credentials");
      if (c.urls.some((u) => /:53(\?|$)/.test(u))) throw new Error("port 53 was left in");
      return c.urls.join(" ");
    });
  }
}

let failed = false;
try {
  await main();
} catch {
  failed = true;
} finally {
  // Whatever happened, leave nothing behind.
  spawnSync("docker", ["rm", "-f", container, `${container}-origin`], { stdio: "ignore" });
  spawnSync("docker", ["network", "rm", network], { stdio: "ignore" });
  if (tunnelId) await cf.remove(label, tunnelId).catch((e) => console.log(`cleanup: ${e.message}`));
  rmSync(dir, { recursive: true, force: true });
}
console.log(JSON.stringify({ label, realDns, results }, null, 2));
process.exit(failed ? 1 : 0);
