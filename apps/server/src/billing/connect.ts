/**
 * Cloud Connect (D-071): a self-hosted instance uses Casama Cloud computers and model credits with
 * an API key, billed to the cloud workspace. Served by the cloud API only (BILLING_ENABLED):
 *
 *   /connect/v1/whoami                    key, workspace and credit balance
 *   /connect/v1/sandbox/*                 the supervisor API, scoped to the workspace's computers
 *   /connect/v1/models/chat/completions   an OpenAI-compatible proxy to the cloud's model upstream
 *
 * Computers are metered on the proxy (running time); model calls by the upstream's reported usage.
 */
import { createHash, randomBytes } from "node:crypto";
import { costOf } from "@casama/agent";
import type { Database } from "@casama/db";
import { captureError } from "@casama/observability";
import { sql } from "drizzle-orm";
import type { Context, Hono } from "hono";
import type { BillingService } from "./service.ts";

export interface ConnectOptions {
  db: Database;
  billing: BillingService;
  supervisor?: { url: string; token: string };
  models?: { url: string; key: string; markup?: number };
}

type Caller = { keyId: string; orgId: string; instance: string; scopes: string[] };

export const hashConnectKey = (key: string) => createHash("sha256").update(key).digest("hex");

export function newConnectKey() {
  const key = `kcc_${randomBytes(24).toString("base64url")}`;
  return { key, hash: hashConnectKey(key), hint: `${key.slice(0, 8)}…${key.slice(-4)}` };
}

const err = (c: Context, status: number, code: string, message: string) =>
  c.json({ code, message }, status as 400);

export function registerConnectRoutes(app: Hono, opts: ConnectOptions) {
  const { db, billing } = opts;
  const callers = new WeakMap<Request, Caller>();
  const lastUsed = new Map<string, number>();

  app.use("/connect/v1/*", async (c, next) => {
    const auth = c.req.header("authorization") ?? "";
    const key = auth.startsWith("Bearer ") ? auth.slice(7) : "";
    if (!key.startsWith("kcc_")) return err(c, 401, "unauthorized", "Missing Cloud Connect key");
    const [k] = await db.execute<{
      id: string;
      org_id: string;
      instance_name: string;
      scopes: string[];
    }>(sql`
      select id, org_id, instance_name, scopes from public.cloud_connect_keys
      where key_hash = ${hashConnectKey(key)} and revoked_at is null`);
    if (!k) return err(c, 401, "unauthorized", "This Cloud Connect key is not valid");
    if ((lastUsed.get(k.id) ?? 0) < Date.now() - 60_000) {
      lastUsed.set(k.id, Date.now());
      await db.execute(
        sql`update public.cloud_connect_keys set last_used_at = now() where id = ${k.id}::uuid`,
      );
    }
    callers.set(c.req.raw, {
      keyId: k.id,
      orgId: k.org_id,
      instance: k.instance_name,
      scopes: k.scopes,
    });
    await next();
  });
  const caller = (c: Context) => callers.get(c.req.raw) as Caller;

  /** Credit-gated plans need a positive balance to start paid work. */
  const hasCredits = async (orgId: string) => {
    const [e] = await db.execute<{ gate: boolean | null }>(sql`
      select (limits->>'credit_gate')::boolean as gate from public.entitlements
      where org_id = ${orgId}::uuid order by created_at desc limit 1`);
    return !e?.gate || (await billing.balance(orgId)) > 0;
  };

  app.get("/connect/v1/whoami", async (c) => {
    const k = caller(c);
    const summary = await billing.summary(k.orgId);
    return c.json({
      org_id: k.orgId,
      instance_name: k.instance,
      scopes: k.scopes,
      plan_code: summary.plan_code,
      credits_usd: summary.credits_usd,
      computers: !!opts.supervisor && k.scopes.includes("computers"),
      models: !!opts.models && k.scopes.includes("models"),
    });
  });

  // ---------------------------------------------------------------------------
  // Cloud computers: the supervisor API, scoped per workspace
  // ---------------------------------------------------------------------------
  app.all("/connect/v1/sandbox/*", async (c) => {
    const k = caller(c);
    if (!opts.supervisor || !k.scopes.includes("computers"))
      return err(c, 403, "computers_unavailable", "Cloud computers are not available for this key");
    const path = c.req.path.slice("/connect/v1/sandbox".length);
    const method = c.req.method;
    const m = path.match(/^\/computers\/([^/]+)(\/.*)?$/);
    const ref = m?.[1];
    const sub = m?.[2] ?? "";
    let body: string | undefined =
      method === "GET" || method === "HEAD" ? undefined : await c.req.text();

    const owned = async () =>
      (
        await db.execute<{ ref: string }>(
          sql`select ref from public.cloud_connect_computers where org_id = ${k.orgId}::uuid`,
        )
      ).map((r) => r.ref);

    // Creating or resuming a computer claims its ref for this workspace (first come).
    const claim = async (r: string) => {
      if (!/^[A-Za-z0-9-]{8,64}$/.test(r)) return err(c, 400, "bad_ref", "A computer needs a ref");
      if (!(await hasCredits(k.orgId)))
        return err(c, 402, "out_of_credits", "The cloud workspace is out of credits");
      await db.execute(sql`
        insert into public.cloud_connect_computers (ref, org_id, key_id, instance_name)
        values (${r}, ${k.orgId}::uuid, ${k.keyId}::uuid, ${k.instance}) on conflict (ref) do nothing`);
      if (!(await owned()).includes(r))
        return err(c, 409, "ref_taken", "That computer id belongs to another workspace");
      return null;
    };
    if (path === "/computers" && method === "POST") {
      const refused = await claim((JSON.parse(body || "{}") as { ref?: string }).ref ?? "");
      if (refused) return refused;
    } else if (ref && method === "POST" && sub === "/resume") {
      const refused = await claim(ref);
      if (refused) return refused;
    } else if (ref) {
      if (!(await owned()).includes(ref)) {
        // Not created yet (or another workspace's): report it as not running, reveal nothing.
        if (method === "GET" && sub === "") return c.json({ running: false });
        return err(c, 404, "not_found", "No such computer");
      }
      const starts =
        (method === "POST" && (sub === "/resume" || sub === "/exec")) || sub === "/input";
      if (starts && !(await hasCredits(k.orgId)))
        return err(c, 402, "out_of_credits", "The cloud workspace is out of credits");
    } else if (path === "/objects/delete" && method === "POST") {
      const mine = await owned();
      const { keys = [] } = JSON.parse(body || "{}") as { keys?: string[] };
      const allowed = keys.filter((key) => mine.some((r) => key.split("/")[1] === r));
      body = JSON.stringify({ keys: allowed });
    } else if (!(path === "/computers" && method === "GET")) {
      return err(c, 404, "not_found", "Not available through Cloud Connect");
    }
    // Live view and terminals stay on the cloud app; they are not proxied here (D-071).
    if (sub.startsWith("/stream") || sub.startsWith("/terminal"))
      return err(c, 404, "not_found", "Live view is not available through Cloud Connect");

    const headers: Record<string, string> = {
      authorization: `Bearer ${opts.supervisor.token}`,
    };
    const ct = c.req.header("content-type");
    if (ct) headers["content-type"] = ct;
    const url = `${opts.supervisor.url.replace(/\/$/, "")}${path}${new URL(c.req.url).search}`;
    let res: Response;
    try {
      res = await fetch(url, { method, headers, body, signal: c.req.raw.signal });
    } catch (e) {
      return err(c, 502, "supervisor_unreachable", (e as Error).message);
    }

    if (res.ok && ref) {
      if (method === "POST" && sub === "/resume") await markRunning(ref);
      if ((method === "POST" && sub === "/sleep") || (method === "DELETE" && sub === ""))
        await billing.flushCloudComputers(ref, true);
      if (method === "DELETE" && sub === "")
        await db.execute(sql`delete from public.cloud_connect_computers where ref = ${ref}`);
    } else if (res.ok && path === "/computers" && method === "POST") {
      await markRunning((JSON.parse(body || "{}") as { ref: string }).ref);
    }
    if (res.ok && path === "/computers" && method === "GET") {
      const mine = new Set(await owned());
      const j = (await res.json()) as { running: string[] };
      return c.json({ running: j.running.filter((r) => mine.has(r)) });
    }
    const out = new Headers();
    const rct = res.headers.get("content-type");
    if (rct) out.set("content-type", rct);
    return new Response(res.body, { status: res.status, headers: out });
  });

  const markRunning = (ref: string) =>
    db.execute(
      sql`update public.cloud_connect_computers set running_since = coalesce(running_since, now()) where ref = ${ref}`,
    );

  // ---------------------------------------------------------------------------
  // Model credits: OpenAI-compatible proxy to the cloud's upstream (OpenRouter by default)
  // ---------------------------------------------------------------------------
  app.post("/connect/v1/models/chat/completions", async (c) => {
    const k = caller(c);
    if (!opts.models || !k.scopes.includes("models"))
      return err(c, 403, "models_unavailable", "Model credits are not available for this key");
    if (!(await hasCredits(k.orgId)))
      return err(c, 402, "out_of_credits", "The cloud workspace is out of credits");
    const req = (await c.req.json()) as Record<string, unknown> & {
      model?: string;
      stream?: boolean;
    };
    if (typeof req.model !== "string") return err(c, 400, "bad_request", "model is required");
    const upstreamBody = {
      ...req,
      ...(req.stream
        ? {
            stream_options: {
              ...((req.stream_options as object) ?? {}),
              include_usage: true,
            },
          }
        : {}),
      usage: { include: true },
    };
    let res: Response;
    try {
      res = await fetch(`${opts.models.url.replace(/\/$/, "")}/chat/completions`, {
        method: "POST",
        headers: {
          authorization: `Bearer ${opts.models.key}`,
          "content-type": "application/json",
        },
        body: JSON.stringify(upstreamBody),
        signal: c.req.raw.signal,
      });
    } catch (e) {
      return err(c, 502, "upstream_unreachable", (e as Error).message);
    }
    const model = req.model;
    const meter = (usage: Usage | undefined) => recordModelUsage(k, model, usage);
    if (!res.ok || !req.stream || !res.body) {
      const text = await res.text();
      if (res.ok) {
        try {
          await meter((JSON.parse(text) as { usage?: Usage }).usage);
        } catch (e) {
          captureError(e, { service: "casama-api", step: "connect-meter-json", key_id: k.keyId, org_id: k.orgId });
        }
      }
      return new Response(text, {
        status: res.status,
        headers: { "content-type": res.headers.get("content-type") ?? "application/json" },
      });
    }
    // Streaming: pass every chunk through and read the final usage chunk on the way.
    let usage: Usage | undefined;
    let buf = "";
    const decoder = new TextDecoder();
    const tap = new TransformStream<Uint8Array, Uint8Array>({
      transform(chunk, ctrl) {
        ctrl.enqueue(chunk);
        buf += decoder.decode(chunk, { stream: true });
        let i = buf.indexOf("\n");
        while (i >= 0) {
          const line = buf.slice(0, i).trim();
          buf = buf.slice(i + 1);
          if (line.startsWith("data:") && line !== "data: [DONE]") {
            try {
              const j = JSON.parse(line.slice(5)) as { usage?: Usage };
              if (j.usage) usage = j.usage;
            } catch (e) {
              captureError(e, { service: "casama-api", step: "connect-meter-stream-parse", key_id: k.keyId, org_id: k.orgId });
            }
          }
          i = buf.indexOf("\n");
        }
      },
      async flush() {
        await meter(usage).catch((e) => {
          captureError(e, { service: "casama-api", step: "connect-meter-stream-flush", key_id: k.keyId, org_id: k.orgId });
        });
      },
    });
    return new Response(res.body.pipeThrough(tap), {
      status: res.status,
      headers: {
        "content-type": res.headers.get("content-type") ?? "text/event-stream",
        "cache-control": "no-cache",
      },
    });
  });

  type Usage = { prompt_tokens?: number; completion_tokens?: number; cost?: number };
  async function recordModelUsage(k: Caller, model: string, usage: Usage | undefined) {
    if (!usage) return;
    const tin = usage.prompt_tokens ?? 0;
    const tout = usage.completion_tokens ?? 0;
    const markup = opts.models?.markup ?? 1;
    const total =
      (typeof usage.cost === "number"
        ? usage.cost
        : costOf(model, { inputTokens: tin, outputTokens: tout }, "openrouter")) * markup;
    const share = tin + tout > 0 ? tin / (tin + tout) : 1;
    const meta = JSON.stringify({ source: "cloud_connect", instance: k.instance });
    await db.execute(sql`
      insert into public.usage_ledger (org_id, kind, quantity, cost_usd, model, billable, meta) values
        (${k.orgId}::uuid, 'tokens_in', ${tin}, ${total * share}, ${model}, true, ${meta}::jsonb),
        (${k.orgId}::uuid, 'tokens_out', ${tout}, ${total * (1 - share)}, ${model}, true, ${meta}::jsonb)`);
  }
}
