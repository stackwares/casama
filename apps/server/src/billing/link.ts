/**
 * Casama Link, the paid part (D-071; called Casama Link before D-296): a self-hosted instance
 * uses Casama Cloud computers and model credits with a key, billed to the cloud workspace. Served
 * by the cloud API only (BILLING_ENABLED):
 *
 *   /link/v1/whoami                    key, workspace and credit balance
 *   /link/v1/sandbox/*                 the supervisor API, scoped to the workspace's computers
 *   /link/v1/models/chat/completions   an OpenAI-compatible proxy to the cloud's model upstream
 *
 * The free part, a server's public address, is in ../link (linking and /link/v1/remote).
 *
 * Computers are metered on the proxy (running time); model calls by the upstream's reported usage.
 */
import {
  cloudCallReserveUsd,
  costOf,
  dailyResetAt,
  type OpenRouterRouting,
  withOpenRouterRouting,
} from "@casama/agent";
import type { Database } from "@casama/db";
import { cloudModelDailyCap, cloudOpenRouterCharge, cloudOpenRouterCost } from "@casama/domain";
import { captureError } from "@casama/observability";
import { sql } from "drizzle-orm";
import type { Context, Hono } from "hono";
import { type LinkCaller, linkCaller, linkKeyAuth } from "../link/keys.ts";
import { registerPushRelay } from "../link/push-relay.ts";
import { registerRemoteRoutes } from "../link/routes.ts";
import { liveViewIncluded, registerTurnRoutes } from "../link/turn.ts";
import type { BillingService } from "./service.ts";

export { hashLinkKey, newLinkKey } from "../link/keys.ts";

export interface LinkOptions {
  db: Database;
  billing: BillingService;
  supervisor?: { url: string; token: string };
  /** `routing`: which OpenRouter providers serve these calls (D-354), as on the cloud's own runs. */
  models?: { url: string; key: string; markup?: number; routing?: OpenRouterRouting };
  /** Casama Link addresses (D-296); unset: this cloud gives none. */
  servers?: import("../link/servers.ts").LinkServers;
  /** The push relay's sender (D-296): this cloud's own Firebase key. Unset: no relay. */
  push?: import("@casama/agent").PushSender;
  /** The relay's sender of iPhone call rings: this cloud's own Apple key. Unset: none. */
  voip?: import("@casama/agent").VoipSender;
  /** The relay's sender of widget refresh pushes (D-405). Unset: none. */
  widgets?: import("@casama/agent").WidgetPushSender;
  /** The relay's sender of alerts to Apple Watches' own tokens (D-410). Unset: none. */
  watch?: import("@casama/agent").WatchAlertSender;
  /** The relay for live view away from the computer (D-296). Unset: none. */
  turn?: import("../link/turn.ts").TurnProvider;
  /** Signed-out linking is limited per caller address. */
  trustedIpHeader?: string;
}

/** The most output one call through the model proxy may ask for. */
const LINK_MAX_OUTPUT_TOKENS = 32_768;

const err = (c: Context, status: number, code: string, message: string) =>
  c.json({ code, message }, status as 400);

/** Why a cloud computer may not start: status, the main API's code for it, and the message. */
const REFUSALS = {
  ref_taken: [409, "ref_taken", "That computer id belongs to another workspace"],
  computer_hours_exceeded: [
    402,
    "computer_hours_exceeded",
    "The cloud workspace used its computer hours for this month. Upgrade for more.",
  ],
  plan_limit: [
    402,
    "plan_limit",
    "The cloud workspace's plan allows no more computers. Delete one or upgrade.",
  ],
  running_limit: [
    402,
    "plan_limit",
    "The cloud workspace's plan runs no more computers at once, and they're all in use. Stop one or upgrade.",
  ],
} as const satisfies Record<string, readonly [number, string, string]>;

class Refused extends Error {
  readonly code: keyof typeof REFUSALS;
  constructor(code: keyof typeof REFUSALS) {
    super(code);
    this.code = code;
  }
}

/**
 * Cuts the size a create (a ComputerSpec) or a resume ({ snapshot, spec }) asks for to the plan's
 * computer_size: that many vCPUs and GB of memory. No size asked gets the plan's, so the
 * supervisor's default can't be bigger than the plan either.
 */
export function clampSize(body: string | undefined, creating: boolean, factor: number) {
  let b: Record<string, unknown>;
  try {
    b = JSON.parse(body || "{}") as Record<string, unknown>;
  } catch {
    return body;
  }
  const spec = (creating ? b : ((b.spec as Record<string, unknown> | undefined) ?? {})) as {
    size?: { cpus?: number; memoryMb?: number; diskGb?: number };
  };
  const want = spec.size ?? {};
  const cap = { cpus: factor, memoryMb: Math.round(1024 * factor) };
  const num = (v: unknown) => (typeof v === "number" && v > 0 ? v : undefined);
  spec.size = {
    ...want,
    cpus: Math.min(num(want.cpus) ?? cap.cpus, cap.cpus),
    memoryMb: Math.min(num(want.memoryMb) ?? cap.memoryMb, cap.memoryMb),
  };
  return JSON.stringify(creating ? spec : { ...b, spec });
}

export function registerCasamaLinkRoutes(app: Hono, opts: LinkOptions) {
  const { db, billing } = opts;

  app.use("/link/v1/*", linkKeyAuth(db));
  const caller = linkCaller;
  const turn = opts.turn;
  if (opts.servers)
    registerRemoteRoutes(app, {
      servers: opts.servers,
      trustedIpHeader: opts.trustedIpHeader,
      liveView: turn ? (orgId) => liveViewIncluded(db, orgId) : undefined,
    });
  if (opts.push)
    registerPushRelay(app, {
      push: opts.push,
      voip: opts.voip,
      widgets: opts.widgets,
      watch: opts.watch,
      db,
    });
  if (turn) registerTurnRoutes(app, { db, turn });

  /**
   * Credit-gated plans need credits to start paid work: the balance less usage not yet settled,
   * and at least [reserve] of it (a model call's worth for the model proxy; D-248).
   */
  const hasCredits = async (orgId: string, reserve = 0) => {
    const [e] = await db.execute<{ gate: boolean | null; unbilled: string }>(sql`
      select
        (select (limits->>'credit_gate')::boolean from public.entitlements
          where org_id = ${orgId}::uuid order by created_at desc limit 1) as gate,
        (select coalesce(sum(cost_usd), 0) from public.usage_ledger
          where org_id = ${orgId}::uuid and billable and billed_at is null)::text as unbilled`);
    if (!e?.gate) return true;
    const left = (await billing.balance(orgId)) - Number(e.unbilled);
    return left > 0 && left >= reserve;
  };

  /** Model spend through the proxy today, against the plan's daily cap on Casama's key (D-248). */
  const overDailyCap = async (orgId: string) => {
    const [r] = await db.execute<{
      plan_code: string | null;
      limits: Record<string, unknown> | null;
      today: string;
    }>(sql`
      select
        (select plan_code from public.entitlements where org_id = ${orgId}::uuid order by created_at desc limit 1) as plan_code,
        (select limits from public.entitlements where org_id = ${orgId}::uuid order by created_at desc limit 1) as limits,
        (select coalesce(sum(cost_usd), 0) from public.usage_ledger
          where org_id = ${orgId}::uuid and billable and meta->>'source' = 'casama_link'
            and kind in ('tokens_in', 'tokens_out')
            -- A saved reset that cleared today's limit (D-443) starts the count again.
            and created_at >= greatest(date_trunc('day', now() at time zone 'utc') at time zone 'utc',
              coalesce(${dailyResetAt(sql`${orgId}::uuid`)}, '-infinity'::timestamptz)))::text as today`);
    const cap = cloudModelDailyCap(r?.plan_code ?? undefined, r?.limits?.cloud_daily_usd);
    return cap != null && Number(r?.today ?? 0) >= cap;
  };

  app.get("/link/v1/whoami", async (c) => {
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
      remote_access: !!opts.servers && k.scopes.includes("remote_access"),
      push: !!opts.push && k.scopes.includes("push"),
    });
  });

  // ---------------------------------------------------------------------------
  // Cloud computers: the supervisor API, scoped per workspace
  // ---------------------------------------------------------------------------
  app.all("/link/v1/sandbox/*", async (c) => {
    const k = caller(c);
    if (!opts.supervisor || !k.scopes.includes("computers"))
      return err(c, 403, "computers_unavailable", "Cloud computers are not available for this key");
    const path = c.req.path.slice("/link/v1/sandbox".length);
    const method = c.req.method;
    const m = path.match(/^\/computers\/([^/]+)(\/.*)?$/);
    const ref = m?.[1];
    const sub = m?.[2] ?? "";
    let body: string | undefined =
      method === "GET" || method === "HEAD" ? undefined : await c.req.text();

    const owned = async () =>
      (
        await db.execute<{ ref: string }>(
          sql`select ref from public.link_computers where org_id = ${k.orgId}::uuid`,
        )
      ).map((r) => r.ref);

    // Creating or resuming a computer claims its ref for this workspace (first come) and a running
    // slot under the plan's limits; a failed start gives the slot back.
    let started: { ref: string; wasRunning: boolean } | undefined;
    const claim = async (r: string, creating: boolean) => {
      if (!/^[A-Za-z0-9-]{8,64}$/.test(r)) return err(c, 400, "bad_ref", "A computer needs a ref");
      if (!(await hasCredits(k.orgId)))
        return err(c, 402, "out_of_credits", "The cloud workspace is out of credits");
      const got = await claimStart(k, r, creating);
      if ("refused" in got) {
        const [status, code, message] = REFUSALS[got.refused];
        return err(c, status, code, message);
      }
      started = { ref: r, wasRunning: got.wasRunning };
      // The plan's computer size holds here too: a bigger one asked for is cut to it.
      if (got.sizeFactor != null) body = clampSize(body, creating, got.sizeFactor);
      // The cloud put this computer to sleep itself; its snapshot is newer than the server's.
      if (!creating && got.swept) {
        const b = JSON.parse(body || "{}") as Record<string, unknown>;
        body = JSON.stringify({ ...b, snapshot: got.swept });
      }
      return null;
    };
    if (path === "/computers" && method === "POST") {
      const refused = await claim((JSON.parse(body || "{}") as { ref?: string }).ref ?? "", true);
      if (refused) return refused;
    } else if (ref && method === "POST" && sub === "/resume") {
      const refused = await claim(ref, false);
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
      return err(c, 404, "not_found", "Not available through Casama Link");
    }
    // Live view and terminals stay on the cloud app; they are not proxied here (D-071).
    if (sub.startsWith("/stream") || sub.startsWith("/terminal"))
      return err(c, 404, "not_found", "Live view is not available through Casama Link");

    const headers: Record<string, string> = {
      authorization: `Bearer ${opts.supervisor.token}`,
    };
    const ct = c.req.header("content-type");
    if (ct) headers["content-type"] = ct;
    const url = `${opts.supervisor.url.replace(/\/$/, "")}${path}${new URL(c.req.url).search}`;
    let res: Response;
    // A start that didn't happen gives back the running slot it claimed.
    const unclaim = async () => {
      if (started && !started.wasRunning)
        await db.execute(
          sql`update public.link_computers set running_since = null where ref = ${started.ref}`,
        );
    };
    try {
      res = await fetch(url, { method, headers, body, signal: c.req.raw.signal });
    } catch (e) {
      await unclaim();
      return err(c, 502, "supervisor_unreachable", (e as Error).message);
    }
    if (!res.ok) await unclaim();
    else if (started)
      await db.execute(
        sql`update public.link_computers set swept_snapshot = null where ref = ${started.ref}`,
      );

    if (res.ok && ref) {
      if (method === "POST" && sub === "/resume") await markRunning(ref);
      if ((method === "POST" && sub === "/sleep") || (method === "DELETE" && sub === ""))
        await billing.flushCloudComputers(ref, true);
      if (method === "DELETE" && sub === "")
        await db.execute(sql`delete from public.link_computers where ref = ${ref}`);
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
      sql`update public.link_computers set running_since = coalesce(running_since, now()) where ref = ${ref}`,
    );

  /**
   * Claims a ref for this workspace and a running slot for it under the plan: max_computers on
   * create, max_running_computers (hosted computers and Link ones together) and the month's
   * computer_hours on every start (billing audit 2026-11-17). Before, only credits were checked.
   * One start per workspace at a time, so two at once can't both take the last slot.
   */
  async function claimStart(
    k: LinkCaller,
    r: string,
    creating: boolean,
  ): Promise<
    | { refused: keyof typeof REFUSALS }
    | { wasRunning: boolean; sizeFactor: number | null; swept: unknown }
  > {
    try {
      return await db.transaction(async (tx) => {
        await tx.execute(
          sql`select pg_advisory_xact_lock(hashtext(${`link_computer_start:${k.orgId}`}))`,
        );
        await tx.execute(sql`
          insert into public.link_computers (ref, org_id, key_id, instance_name)
          values (${r}, ${k.orgId}::uuid, ${k.keyId}::uuid, ${k.instance}) on conflict (ref) do nothing`);
        const [row] = await tx.execute<{
          org_id: string;
          running: boolean;
          swept: unknown;
        }>(sql`
          select org_id::text, running_since is not null as running, swept_snapshot as swept
          from public.link_computers where ref = ${r} for update`);
        if (!row || row.org_id !== k.orgId) throw new Refused("ref_taken");
        const [l] = await tx.execute<{
          limits: Record<string, unknown> | null;
          running: number;
          total: number;
          seconds: string;
        }>(sql`
          select
            (select limits from public.entitlements where org_id = ${k.orgId}::uuid
              order by created_at desc limit 1) as limits,
            ((select count(*) from public.computers where org_id = ${k.orgId}::uuid and kind <> 'local'
                and state in ('provisioning', 'starting', 'running', 'idle'))
             + (select count(*) from public.link_computers where org_id = ${k.orgId}::uuid
                and running_since is not null and ref <> ${r}))::int as running,
            ((select count(*) from public.computers where org_id = ${k.orgId}::uuid and provider <> 'local')
             + (select count(*) from public.link_computers where org_id = ${k.orgId}::uuid
                and ref <> ${r}))::int as total,
            (select coalesce(sum(quantity), 0) from public.usage_ledger
              where org_id = ${k.orgId}::uuid and kind = 'computer_seconds'
                and created_at >= date_trunc('month', now() at time zone 'utc') at time zone 'utc')::text as seconds`);
        const limit = (name: string) => {
          const v = l?.limits?.[name];
          const n = typeof v === "number" ? v : typeof v === "string" ? Number(v) : Number.NaN;
          return Number.isFinite(n) ? n : null;
        };
        const hours = limit("computer_hours");
        if (hours != null && Number(l?.seconds ?? 0) / 3600 >= hours)
          throw new Refused("computer_hours_exceeded");
        const maxComputers = limit("max_computers");
        if (creating && maxComputers != null && Number(l?.total ?? 0) >= maxComputers)
          throw new Refused("plan_limit");
        const maxRunning = limit("max_running_computers");
        if (maxRunning != null && Number(l?.running ?? 0) >= maxRunning)
          throw new Refused("running_limit");
        await tx.execute(sql`
          update public.link_computers set running_since = coalesce(running_since, now()) where ref = ${r}`);
        const size = limit("computer_size");
        return {
          wasRunning: row.running,
          sizeFactor: size != null && size > 0 ? size : null,
          swept: row.swept ?? null,
        };
      });
    } catch (e) {
      if (e instanceof Refused) return { refused: e.code };
      throw e;
    }
  }

  // ---------------------------------------------------------------------------
  // Model credits: OpenAI-compatible proxy to the cloud's upstream (OpenRouter by default)
  // ---------------------------------------------------------------------------
  app.post("/link/v1/models/chat/completions", async (c) => {
    const k = caller(c);
    if (!opts.models || !k.scopes.includes("models"))
      return err(c, 403, "models_unavailable", "Model credits are not available for this key");
    const req = (await c.req.json()) as Record<string, unknown> & {
      model?: string;
      stream?: boolean;
      messages?: unknown;
      tools?: unknown;
      max_tokens?: unknown;
      max_completion_tokens?: unknown;
    };
    if (typeof req.model !== "string") return err(c, 400, "bad_request", "model is required");
    // Output is capped so one call can't run far past the credits it was let in with, and the
    // credits needed cover this call's own prompt and that cap, not a fixed small call (billing
    // audit 2026-11-17).
    const asked = [req.max_tokens, req.max_completion_tokens].find(
      (v): v is number => typeof v === "number" && v > 0,
    );
    const maxOut = Math.min(asked ?? LINK_MAX_OUTPUT_TOKENS, LINK_MAX_OUTPUT_TOKENS);
    const promptTokens = Math.ceil(
      JSON.stringify([req.messages ?? "", req.tools ?? ""]).length / 4,
    );
    const reserve = Math.max(
      cloudCallReserveUsd(req.model),
      cloudOpenRouterCharge(
        costOf(req.model, { inputTokens: promptTokens, outputTokens: maxOut }, "openrouter"),
      ),
    );
    if (!(await hasCredits(k.orgId, reserve)))
      return err(c, 402, "out_of_credits", "The cloud workspace is out of credits");
    if (await overDailyCap(k.orgId))
      return err(
        c,
        402,
        "cloud_daily_cap",
        "The cloud workspace reached today's limit for model credits",
      );
    const upstreamBody = {
      // The linked server's own `provider` choices win over the cloud's routing.
      ...withOpenRouterRouting(req, opts.models.routing),
      ...(typeof req.max_completion_tokens === "number"
        ? { max_completion_tokens: maxOut }
        : { max_tokens: maxOut }),
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
        // A streamed call stops upstream when the caller goes away and is metered from an
        // estimate; a plain call always runs to the end so its real usage is recorded.
        ...(req.stream ? { signal: c.req.raw.signal } : {}),
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
          captureError(e, {
            service: "casama-api",
            step: "link-meter-json",
            key_id: k.keyId,
            org_id: k.orgId,
          });
        }
      }
      return new Response(text, {
        status: res.status,
        headers: { "content-type": res.headers.get("content-type") ?? "application/json" },
      });
    }
    // Streaming: pass every chunk through and read the final usage chunk on the way. A stream that
    // ends without one (the client went away first) is metered from an estimate (D-248).
    let usage: Usage | undefined;
    let buf = "";
    let outChars = 0;
    let metered = false;
    // A stream cut off before its usage chunk is charged the prompt (the upstream read all of it)
    // plus what came out, reasoning included; before, nothing was charged until visible text came.
    const meterOnce = async () => {
      if (metered) return;
      metered = true;
      await meter(
        usage ?? { prompt_tokens: promptTokens, completion_tokens: Math.ceil(outChars / 4) },
      ).catch((e) => {
        captureError(e, {
          service: "casama-api",
          step: "link-meter-stream-flush",
          key_id: k.keyId,
          org_id: k.orgId,
        });
      });
    };
    c.req.raw.signal.addEventListener("abort", () => void meterOnce(), { once: true });
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
              const j = JSON.parse(line.slice(5)) as {
                usage?: Usage;
                choices?: Array<{
                  delta?: {
                    content?: string | null;
                    reasoning?: string | null;
                    reasoning_content?: string | null;
                    tool_calls?: unknown;
                  };
                }>;
              };
              if (j.usage) usage = j.usage;
              for (const ch of j.choices ?? []) {
                outChars += ch.delta?.content?.length ?? 0;
                outChars += ch.delta?.reasoning?.length ?? 0;
                outChars += ch.delta?.reasoning_content?.length ?? 0;
                if (ch.delta?.tool_calls) outChars += JSON.stringify(ch.delta.tool_calls).length;
              }
            } catch (e) {
              captureError(e, {
                service: "casama-api",
                step: "link-meter-stream-parse",
                key_id: k.keyId,
                org_id: k.orgId,
              });
            }
          }
          i = buf.indexOf("\n");
        }
      },
      async flush() {
        await meterOnce();
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
  async function recordModelUsage(k: LinkCaller, model: string, usage: Usage | undefined) {
    if (!usage) return;
    const tin = usage.prompt_tokens ?? 0;
    const tout = usage.completion_tokens ?? 0;
    const cost =
      typeof usage.cost === "number"
        ? usage.cost
        : costOf(model, { inputTokens: tin, outputTokens: tout }, "openrouter");
    // The same price as Casama's own key: OpenRouter's fee and the markup from Admin (D-248),
    // unless CLOUD_MODEL_MARKUP sets one for this server.
    const total =
      opts.models?.markup != null ? cost * opts.models.markup : cloudOpenRouterCharge(cost);
    const share = tin + tout > 0 ? tin / (tin + tout) : 1;
    // Casama pays OpenRouter the price and its fee, whatever markup this server charges (D-395).
    const upstream = cloudOpenRouterCost(cost);
    const meta = JSON.stringify({ source: "casama_link", instance: k.instance });
    await db.execute(sql`
      insert into public.usage_ledger (org_id, kind, quantity, cost_usd, upstream_cost_usd, model, billable, meta) values
        (${k.orgId}::uuid, 'tokens_in', ${tin}, ${total * share}, ${upstream * share}, ${model}, true, ${meta}::jsonb),
        (${k.orgId}::uuid, 'tokens_out', ${tout}, ${total * (1 - share)}, ${upstream * (1 - share)}, ${model}, true, ${meta}::jsonb)`);
  }
}
