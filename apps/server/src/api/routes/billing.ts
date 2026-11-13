/** Billing (Phase 7, D-070): plans, entitlements, checkout, store purchases, webhooks, Cloud Connect keys. */

import { track } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { newConnectKey } from "../../billing/connect.ts";
import { BillingService } from "../../billing/service.ts";
import { BillingError, type BillingSource } from "../../billing/types.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

/** BillingError -> problem JSON. */
export async function billingCall<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (err) {
    if (err instanceof BillingError) throw new ApiError(err.status as 400, err.code, err.message);
    throw err;
  }
}

export function billingFor(deps: AppDeps) {
  return deps.billing ?? new BillingService({ db: deps.db, enabled: false, providers: {} });
}

export function registerBillingRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;
  const billing = billingFor(deps);

  const role = async (claims: JwtClaims, orgId: string, needed: "member" | "admin") => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.has_role(${orgId}::uuid, ${needed}) as ok`),
    );
    if (!r?.ok) {
      if (needed === "member") throw new ApiError(404, "org_not_found", "Workspace not found");
      throw new ApiError(403, "forbidden", "Only owners and admins can manage billing");
    }
  };
  const requireEnabled = () => {
    if (!billing.enabled)
      throw new ApiError(409, "billing_disabled", "Billing is off on this server (self-hosted)");
  };
  const returnUrl = (given?: string) => given ?? `${env.PUBLIC_APP_URL}/billing`;

  app.openapi(routes.listPlans, async (c) => {
    requireClaims(c.get("claims"));
    if (!billing.enabled) return c.json({ enabled: false, plans: [], packs: [] }, 200);
    // The self-hosted plan is not offered on Casama Cloud.
    const plans = (await billing.plans()).filter((p) => p.code !== "selfhost");
    const packs = await billing.packs();
    return c.json(
      {
        enabled: true,
        plans: plans.map((p) => ({
          code: p.code,
          name: p.name,
          interval: p.interval as "none" | "month" | "year",
          limits: Object.fromEntries(
            Object.entries(p.limits).filter(([, v]) => typeof v === "number"),
          ) as Record<string, number>,
          price_label: p.price_label ?? null,
          web: !!p.dodo_product_id && !!billing.providers.dodo,
          store_product_ids: p.store_product_ids ?? {},
        })),
        packs: packs.map((p) => ({
          code: p.code,
          name: p.name,
          credits_usd: Number(p.credits_usd),
          web: !!p.dodo_product_id && !!billing.providers.dodo,
          price_label: p.price_label ?? null,
          store_product_ids: p.store_product_ids ?? {},
        })),
      },
      200,
    );
  });

  app.openapi(routes.getBilling, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await role(claims, id, "member");
    return c.json(await billing.summary(id), 200);
  });

  app.openapi(routes.createCheckout, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    await role(claims, id, "admin");
    requireEnabled();
    const r = await billingCall(() =>
      billing.checkout(
        id,
        { planCode: body.plan_code, packCode: body.pack_code },
        claims.email ?? null,
        returnUrl(body.return_url),
      ),
    );
    track(deps.db, {
      event: "checkout_created",
      userId: claims.sub,
      orgId: id,
      properties: {
        store: "dodo",
        kind: body.pack_code ? "credit_pack" : "subscription",
        product_id: body.pack_code ?? body.plan_code ?? null,
      },
    });
    return c.json({ url: r.url }, 200);
  });

  app.openapi(routes.billingPortal, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    await role(claims, id, "admin");
    requireEnabled();
    const r = await billingCall(() => billing.portal(id, returnUrl(body.return_url)));
    return c.json({ url: r.url }, 200);
  });

  app.openapi(routes.verifyPurchase, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    await role(claims, id, "admin");
    requireEnabled();
    await billingCall(() =>
      billing.verifyPurchase(id, body.source, {
        productId: body.product_id,
        transactionId: body.transaction_id,
        purchaseToken: body.purchase_token,
      }),
    );
    return c.json(await billing.summary(id), 200);
  });

  app.openapi(routes.billingUsage, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await role(claims, id, "member");
    if (billing.enabled) await billing.flushCloudComputers();
    const start = new Date();
    start.setUTCDate(1);
    start.setUTCHours(0, 0, 0, 0);
    const items = await db.execute<{
      kind: string;
      instance: string | null;
      quantity: string;
      cost: string;
    }>(sql`
      select kind, meta->>'instance' as instance, sum(quantity)::text as quantity, sum(cost_usd)::text as cost
      from public.usage_ledger
      where org_id = ${id}::uuid and billable and created_at >= ${start.toISOString()}::timestamptz
      group by 1, 2 order by 1, 2`);
    const credits = await db.execute<{
      delta: string;
      reason: string;
      note: string | null;
      balance_after: string;
      created_at: Date;
    }>(sql`
      select delta, reason, note, balance_after, created_at from public.credit_ledger
      where org_id = ${id}::uuid order by seq desc limit 50`);
    const out = items.map((i) => ({
      kind: i.kind,
      instance: i.instance,
      quantity: Number(i.quantity),
      cost_usd: Number(i.cost),
    }));
    return c.json(
      {
        period_start: start.toISOString(),
        items: out,
        total_usd: out.reduce((a, b) => a + b.cost_usd, 0),
        credits: credits.map((e) => ({
          delta: Number(e.delta),
          reason: e.reason,
          note: e.note,
          balance_after: Number(e.balance_after),
          created_at: iso(e.created_at),
        })),
      },
      200,
    );
  });

  // Cloud Connect keys (cloud side).
  const keyOut = (k: {
    id: string;
    instance_name: string;
    key_hint: string;
    scopes: string[];
    last_used_at: Date | null;
    created_at: Date;
  }) => ({
    id: k.id,
    instance_name: k.instance_name,
    key_hint: k.key_hint,
    scopes: k.scopes,
    last_used_at: k.last_used_at ? iso(k.last_used_at) : null,
    created_at: iso(k.created_at),
  });

  app.openapi(routes.listConnectKeys, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await role(claims, id, "admin");
    const rows = await db.execute<Parameters<typeof keyOut>[0]>(sql`
      select id, instance_name, key_hint, scopes, last_used_at, created_at from public.cloud_connect_keys
      where org_id = ${id}::uuid and revoked_at is null order by created_at`);
    return c.json({ items: rows.map(keyOut) }, 200);
  });

  app.openapi(routes.createConnectKey, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    await role(claims, id, "admin");
    requireEnabled();
    const k = newConnectKey();
    const scopes = body.scopes ?? ["computers", "models"];
    const [row] = await db.execute<Parameters<typeof keyOut>[0]>(sql`
      insert into public.cloud_connect_keys (org_id, key_hash, key_hint, instance_name, scopes, created_by)
      values (${id}::uuid, ${k.hash}, ${k.hint}, ${body.instance_name}, ${`{${scopes.join(",")}}`}::text[], ${claims.sub}::uuid)
      returning id, instance_name, key_hint, scopes, last_used_at, created_at`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${id}::uuid, 'user', ${claims.sub}::uuid, 'cloud_connect.key_created', 'cloud_connect_key', ${row?.id}::uuid,
              ${JSON.stringify({ instance_name: body.instance_name, scopes })}::jsonb)`);
    return c.json({ ...keyOut(row as Parameters<typeof keyOut>[0]), key: k.key }, 201);
  });

  app.openapi(routes.revokeConnectKey, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, key_id } = c.req.valid("param");
    await role(claims, id, "admin");
    const rows = await db.execute<{ id: string }>(sql`
      update public.cloud_connect_keys set revoked_at = now()
      where id = ${key_id}::uuid and org_id = ${id}::uuid and revoked_at is null returning id`);
    if (!rows.length) throw new ApiError(404, "key_not_found", "Key not found");
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id)
      values (${id}::uuid, 'user', ${claims.sub}::uuid, 'cloud_connect.key_revoked', 'cloud_connect_key', ${key_id}::uuid)`);
    return c.json({ revoked: key_id }, 200);
  });

  // Provider webhooks: Dodo (Standard Webhooks), App Store Server Notifications V2, Play RTDN.
  app.post("/hooks/billing/:source", async (c) => {
    const source = c.req.param("source") as BillingSource;
    if (!billing.enabled || !["dodo", "app_store", "google_play"].includes(source))
      throw new ApiError(404, "not_found", "No such route");
    const rawBody = await c.req.text();
    try {
      const r = await billing.handleWebhook(source, {
        headers: c.req.raw.headers,
        rawBody,
        url: c.req.url,
      });
      return c.json({ ok: true, duplicate: r.duplicate }, 200);
    } catch (err) {
      if (err instanceof BillingError && err.status < 500) {
        deps.logger.warn("billing webhook rejected", { source, code: err.code });
        throw new ApiError(err.status as 400, err.code, err.message);
      }
      throw err;
    }
  });
}
