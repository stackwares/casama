/**
 * Paid data services (SPEC: Paid data services; D-138). A `DataProvider` sells data calls (places,
 * emails, SEO and the like). The Treg adapter (treg.to) follows Treg's public docs: one token
 * (`X-Treg-Token`), a catalog (`/catalog/search`, `/catalog/endpoints/<id>`), calls through
 * `/call/<id>`, the cost charged in `X-Treg-Cost-Micro`, and a per-call ceiling in
 * `X-Treg-Route-Max-Cost`. Tested against a local fake only.
 *
 * Bots find services with `data.search` and buy with `data.call`, which always asks first; the
 * approval card shows the quoted price. A workspace's own Treg key is charged by Treg directly
 * (no markup). On Casama Cloud, when resale is turned on, calls use Casama's key and credits are
 * charged the cost plus 20% (`usage_ledger.kind = data_calls`).
 */
import { createHash } from "node:crypto";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { wrapUntrusted } from "./context.ts";
import { withTimeout } from "./safe-fetch.ts";
import { ToolError, type ToolRegistry } from "./tools/registry.ts";

export interface DataService {
  id: string;
  name: string;
  description: string;
  /** Provider (service) and operation, for display: data.{service}.{operation}. */
  service: string;
  operation: string;
  method: string;
  /** Quoted price in USD per unit, when the catalog gives one. */
  price_usd: number | null;
  /** per_call, per_result, ... and the unit (row, keyword, domain). */
  price_type: string | null;
  price_unit: string | null;
  params?: unknown;
}

export interface DataCallResult {
  status: number;
  body: string;
  /** What the provider charged, in USD. */
  cost_usd: number;
  call_id: string | null;
}

export interface DataProvider {
  readonly name: string;
  search(query: string, limit: number): Promise<DataService[]>;
  describe(id: string): Promise<DataService | null>;
  call(
    id: string,
    method: string,
    params: Record<string, unknown>,
    opts: { maxCostUsd?: number; idempotencyKey?: string },
  ): Promise<DataCallResult>;
}

const num = (v: unknown) =>
  v === null || v === undefined || v === "" || Number.isNaN(Number(v)) ? null : Number(v);

/** Turns a catalog entry (fields vary by tool) into a DataService. */
function toService(e: Record<string, unknown>): DataService {
  const id = String(e.id ?? e.slug ?? "");
  const cost = (e.cost ?? {}) as Record<string, unknown>;
  const dot = id.indexOf(".");
  return {
    id,
    name: String(e.name ?? e.title ?? id),
    description: String(e.description ?? e.summary ?? "").slice(0, 500),
    service: String(e.provider ?? e.vendor ?? (dot > 0 ? id.slice(0, dot) : id)),
    operation: String(e.operation ?? (dot > 0 ? id.slice(dot + 1) : id)),
    method: String(e.method ?? "GET").toUpperCase(),
    price_usd: num(
      cost.usd_per_call ??
        cost.usd ??
        cost.price_usd ??
        e.usd_per_call ??
        e.price_usd ??
        e.overflow_price_usd,
    ),
    price_type: (cost.type as string) ?? null,
    price_unit: (cost.unit as string) ?? null,
    params: e.params ?? e.parameters ?? undefined,
  };
}

export class TregProvider implements DataProvider {
  readonly name = "treg";
  private readonly o: { key: string; base: string; fetch: typeof fetch };
  constructor(o: { key: string; base?: string; fetch?: typeof fetch }) {
    this.o = {
      key: o.key,
      base: (o.base ?? "https://treg.to").replace(/\/$/, ""),
      fetch: withTimeout(o.fetch ?? fetch, 60_000),
    };
  }
  private headers(extra: Record<string, string> = {}) {
    return { "x-treg-token": this.o.key, accept: "application/json", ...extra };
  }

  async search(query: string, limit: number) {
    const res = await this.o.fetch(
      `${this.o.base}/catalog/search?q=${encodeURIComponent(query)}&limit=${limit}`,
      { headers: this.headers() },
    );
    if (!res.ok) throw new Error(`Treg catalog answered ${res.status}`);
    const b = (await res.json()) as unknown;
    const list = (
      Array.isArray(b)
        ? b
        : ((b as { results?: unknown[]; items?: unknown[]; endpoints?: unknown[] }).results ??
          (b as { items?: unknown[] }).items ??
          (b as { endpoints?: unknown[] }).endpoints ??
          [])
    ) as Array<Record<string, unknown>>;
    return list.slice(0, limit).map(toService);
  }

  async describe(id: string) {
    const res = await this.o.fetch(`${this.o.base}/catalog/endpoints/${encodeURIComponent(id)}`, {
      headers: this.headers(),
    });
    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`Treg catalog answered ${res.status}`);
    const b = (await res.json()) as Record<string, unknown>;
    return toService((b.endpoint ?? b) as Record<string, unknown>);
  }

  async call(
    id: string,
    method: string,
    params: Record<string, unknown>,
    opts: { maxCostUsd?: number; idempotencyKey?: string },
  ) {
    const get = method === "GET";
    const qs = get
      ? `?${new URLSearchParams(Object.entries(params).map(([k, v]) => [k, typeof v === "string" ? v : JSON.stringify(v)])).toString()}`
      : "";
    const res = await this.o.fetch(`${this.o.base}/call/${id}${qs}`, {
      method,
      headers: this.headers({
        ...(get ? {} : { "content-type": "application/json" }),
        ...(opts.maxCostUsd !== undefined
          ? { "x-treg-route-max-cost": opts.maxCostUsd.toFixed(4) }
          : {}),
        ...(opts.idempotencyKey ? { "idempotency-key": opts.idempotencyKey } : {}),
        "x-treg-meta": "app=casama",
      }),
      body: get ? undefined : JSON.stringify(params),
    });
    const body = await res.text();
    if (res.headers.get("x-treg-error") === "1") {
      let code = "";
      try {
        code = String(
          (JSON.parse(body) as { code?: string; error?: string }).code ??
            (JSON.parse(body) as { error?: string }).error ??
            "",
        );
      } catch {}
      const why: Record<string, string> = {
        insufficient_balance: "The Treg account doesn't have enough balance for this call.",
        route_max_cost: "This call would cost more than the price you approved, so it wasn't made.",
        own_key_required:
          "This data service needs the workspace's own key for that provider, connected in Treg.",
        funds_required: "Add funds to the Treg account to use this service.",
        trial_allowance_reached: "Treg's free trial allowance is used up for today.",
      };
      throw new ToolError(
        code || "data_refused",
        why[code] ?? `Treg refused the call (${res.status}${code ? `, ${code}` : ""}).`,
      );
    }
    return {
      status: res.status,
      body,
      cost_usd: Number(res.headers.get("x-treg-cost-micro") ?? 0) / 1e6,
      call_id: res.headers.get("x-treg-call-id"),
    };
  }
}

/** Casama Cloud's resale markup: cost plus 20%. */
export const DATA_MARKUP = 1.2;

export interface DataAccess {
  provider: DataProvider;
  /** Casama's own key (resale): credits are charged cost × markup. Otherwise the workspace pays Treg. */
  resale: boolean;
}

export function priceText(
  s: Pick<DataService, "price_usd" | "price_type" | "price_unit">,
  resale: boolean,
) {
  if (s.price_usd === null) return "price not listed (check the Treg catalog)";
  const p = s.price_usd * (resale ? DATA_MARKUP : 1);
  const per = s.price_type === "per_result" ? `per ${s.price_unit ?? "result"}` : "per call";
  return `$${p.toFixed(p < 1 ? 4 : 2)} ${per}${resale ? " (includes Casama's 20%)" : ""}`;
}

export function registerDataTools(
  registry: ToolRegistry,
  deps: { db: Database; dataFor: (orgId: string) => Promise<DataAccess | null> },
) {
  const access = async (orgId: string) => {
    const a = await deps.dataFor(orgId);
    if (!a)
      throw new ToolError(
        "no_data_provider",
        "Paid data isn't set up. Add a Treg key in Settings → Model keys.",
      );
    return a;
  };

  registry.register({
    name: "data.search",
    // Outside content (audit 2026-11): later risky calls ask first.
    untrustedOutput: true,
    description:
      "Find paid data services (places, business and people lookups, emails, SEO, company data and more) and what each call costs. Then buy with data.call; the person approves the price first.",
    risk: "low",
    readOnly: true,
    schema: z.object({
      query: z.string().min(1).max(200),
      limit: z.number().int().min(1).max(20).optional(),
    }),
    async execute(args, ctx) {
      const a = await access(ctx.orgId);
      const found = await a.provider.search(args.query, args.limit ?? 8);
      if (!found.length) return { content: "No data services match.", preview: "0 services" };
      const text = found
        .map(
          (s) =>
            `- ${s.id} (data.${s.service}.${s.operation}): ${s.name}. ${priceText(s, a.resale)}. ${s.description}`,
        )
        .join("\n");
      return {
        content: `${text}\n\nUse data.call with the id and its parameters.`,
        preview: `${found.length} services`,
      };
    },
  });

  registry.register({
    name: "data.call",
    description:
      "Buy one call to a paid data service found with data.search: give its id and the parameters it takes. The person approves the price before anything is charged.",
    risk: "medium",
    confirm: true,
    untrustedOutput: true,
    schema: z.object({
      endpoint: z.string().min(1).max(200),
      params: z.record(z.string(), z.unknown()).optional(),
      method: z.enum(["GET", "POST"]).optional(),
    }),
    // The approval card shows what will be bought and its price.
    async approvalDetails(args, ctx) {
      const a = await deps.dataFor(ctx.orgId);
      const s = a ? await a.provider.describe(args.endpoint).catch(() => null) : null;
      return s
        ? { service: `data.${s.service}.${s.operation}`, price: priceText(s, a?.resale ?? false) }
        : {};
    },
    async execute(args, ctx) {
      const a = await access(ctx.orgId);
      const s = await a.provider.describe(args.endpoint);
      if (!s)
        throw new ToolError(
          "no_such_service",
          `No data service ${args.endpoint}. Search with data.search first.`,
        );
      // Never pay much more than the approved quote (per-result prices vary with the result count).
      const max =
        s.price_usd !== null
          ? Math.max(s.price_usd * (s.price_type === "per_result" ? 50 : 1.5), 0.01)
          : 0.5;
      const r = await a.provider.call(s.id, args.method ?? s.method, args.params ?? {}, {
        maxCostUsd: max,
        idempotencyKey: createHash("sha256")
          .update(`${ctx.runId}:${s.id}:${JSON.stringify(args.params ?? {})}`)
          .digest("hex")
          .slice(0, 40),
      });
      const charged = r.cost_usd * (a.resale ? DATA_MARKUP : 1);
      await deps.db.execute(sql`
        insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, billable, meta)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${ctx.runId}::uuid, 'data_calls', 1, ${charged}, ${a.resale},
                ${JSON.stringify({ provider: a.provider.name, endpoint: s.id, call_id: r.call_id, provider_cost_usd: r.cost_usd, status: r.status })}::jsonb)`);
      if (r.status >= 400)
        throw new ToolError(
          "data_failed",
          `The data service answered ${r.status} (not charged): ${r.body.slice(0, 300)}`,
        );
      return {
        content: wrapUntrusted(`data:${s.id}`, r.body.slice(0, 20_000)),
        preview: `data.${s.service}.${s.operation} · $${charged.toFixed(4)}`,
      };
    },
  });
}
