/**
 * Payments (D-142), the API side: owners connect the workspace's own Stripe Issuing account, see
 * card requests, and Stripe's real-time authorization webhook approves only the named merchant and
 * amount on a live single-use card, then cancels the card once it's used.
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { merchantMatches, PAYMENT_TOLERANCE, StripeIssuingProvider } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type JwtClaims, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

/** Stripe-Signature: t=<unix>,v1=<hex HMAC of "t.body">, within 5 minutes. */
export function stripeSignatureValid(header: string | undefined, body: string, secret: string, nowS = Math.floor(Date.now() / 1000)) {
  if (!header) return false;
  const parts = Object.fromEntries(header.split(",").map((p) => p.split("=") as [string, string]));
  const t = Number(parts.t);
  if (!t || Math.abs(nowS - t) > 300) return false;
  const want = createHmac("sha256", secret).update(`${t}.${body}`).digest("hex");
  return header
    .split(",")
    .filter((p) => p.startsWith("v1="))
    .some((p) => {
      const got = Buffer.from(p.slice(3));
      return got.length === want.length && timingSafeEqual(got, Buffer.from(want));
    });
}

export function registerPaymentRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const base = (c: { req: { url: string } }) => (deps.env.PUBLIC_API_URL ?? new URL(c.req.url).origin).replace(/\/$/, "");
  const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    return claims;
  };
  const role = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ member: boolean; owner: boolean }>(sql`select public.has_role(${orgId}::uuid, 'member') as member, public.has_role(${orgId}::uuid, 'owner') as owner`),
    );
    if (!r?.member) throw new ApiError(404, "org_not_found", "Workspace not found");
    return r;
  };
  const out = async (c: { req: { url: string } }, orgId: string) => {
    const [p] = await db.execute<{ provider: "stripe"; monthly_cap_usd: string; bot_monthly_cap_usd: string }>(sql`
      select provider, monthly_cap_usd, bot_monthly_cap_usd from public.org_payments where org_id = ${orgId}::uuid`);
    const [s] = await db.execute<{ cents: string }>(sql`
      select coalesce(sum(coalesce(spent_cents, amount_cents)), 0)::text as cents from public.payment_requests
      where org_id = ${orgId}::uuid and status in ('issued', 'used') and created_at >= date_trunc('month', now())`);
    return {
      connected: !!p,
      provider: p?.provider ?? null,
      monthly_cap_usd: Number(p?.monthly_cap_usd ?? 500),
      bot_monthly_cap_usd: Number(p?.bot_monthly_cap_usd ?? 200),
      spent_this_month_usd: Number(s?.cents ?? 0) / 100,
      webhook_url: p ? `${base(c)}/hooks/payments/${orgId}` : null,
    };
  };

  app.openapi(routes.getPaymentSettings, async (c) => {
    const { id } = c.req.valid("param");
    if (!(await role(claimsOf(c), id)).owner) throw new ApiError(403, "forbidden", "Only owners manage payments");
    return c.json(await out(c, id), 200);
  });

  app.openapi(routes.setPaymentSettings, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    if (!(await role(claims, id)).owner) throw new ApiError(403, "forbidden", "Only owners manage payments");
    let cardholder: { id: string };
    try {
      cardholder = await StripeIssuingProvider.createCardholder({ secretKey: b.secret_key, apiUrl: deps.env.STRIPE_API_URL, fetch: deps.apps?.fetch ?? fetch }, b.cardholder);
    } catch (e) {
      throw new ApiError(400, "stripe_failed", `Stripe didn't accept the setup: ${(e as Error).message}`);
    }
    await db.execute(sql`
      with old as (select vault_secret_id, webhook_secret_id from public.org_payments where org_id = ${id}::uuid)
      delete from vault.secrets where id in (select vault_secret_id from old union select webhook_secret_id from old)`);
    await db.execute(sql`
      insert into public.org_payments (org_id, vault_secret_id, webhook_secret_id, cardholder_id, monthly_cap_usd, bot_monthly_cap_usd, updated_at)
      values (${id}::uuid, (select vault.create_secret(${b.secret_key}, null, 'stripe issuing')), (select vault.create_secret(${b.webhook_secret}, null, 'stripe webhook')),
              ${cardholder.id}, ${b.monthly_cap_usd ?? 500}, ${b.bot_monthly_cap_usd ?? 200}, now())
      on conflict (org_id) do update set vault_secret_id = excluded.vault_secret_id, webhook_secret_id = excluded.webhook_secret_id, cardholder_id = excluded.cardholder_id,
        monthly_cap_usd = excluded.monthly_cap_usd, bot_monthly_cap_usd = excluded.bot_monthly_cap_usd, updated_at = now()`);
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${id}::uuid, 'user', ${claims.sub}::uuid, 'payments.set', 'organization', ${id}::uuid, ${JSON.stringify({ monthly_cap_usd: b.monthly_cap_usd ?? 500, bot_monthly_cap_usd: b.bot_monthly_cap_usd ?? 200 })}::jsonb)`);
    return c.json(await out(c, id), 200);
  });

  app.openapi(routes.deletePaymentSettings, async (c) => {
    const { id } = c.req.valid("param");
    if (!(await role(claimsOf(c), id)).owner) throw new ApiError(403, "forbidden", "Only owners manage payments");
    await db.execute(sql`
      with gone as (delete from public.org_payments where org_id = ${id}::uuid returning vault_secret_id, webhook_secret_id)
      delete from vault.secrets where id in (select vault_secret_id from gone union select webhook_secret_id from gone)`);
    return c.json(await out(c, id), 200);
  });

  app.openapi(routes.listPaymentRequests, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await role(claims, id);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; bot_id: string; merchant: string; amount_cents: string; currency: string; reason: string; status: "issued"; last4: string | null; spent_cents: string | null; expires_at: string; created_at: string }>(sql`
        select id, bot_id, merchant, amount_cents, currency, reason, status, last4, spent_cents, expires_at, created_at
        from public.payment_requests where org_id = ${id}::uuid order by created_at desc limit 100`),
    );
    return c.json(
      {
        items: rows.map((r) => ({
          ...r,
          amount_cents: Number(r.amount_cents),
          spent_cents: r.spent_cents === null ? null : Number(r.spent_cents),
          expires_at: iso(r.expires_at),
          created_at: iso(r.created_at),
        })),
      },
      200,
    );
  });

  // Stripe Issuing webhooks: real-time authorization requests, and authorizations once made.
  app.post("/hooks/payments/:org", async (c) => {
    const org = c.req.param("org");
    if (!/^[0-9a-f-]{36}$/.test(org)) return c.json({}, 404);
    const [p] = await db.execute<{ secret: string; key: string }>(sql`
      select w.decrypted_secret as secret, k.decrypted_secret as key from public.org_payments p
      join vault.decrypted_secrets w on w.id = p.webhook_secret_id join vault.decrypted_secrets k on k.id = p.vault_secret_id where p.org_id = ${org}::uuid`);
    if (!p) return c.json({}, 404);
    const body = await c.req.text();
    if (!stripeSignatureValid(c.req.header("stripe-signature"), body, p.secret)) return c.json({ error: "bad signature" }, 400);
    const ev = JSON.parse(body) as {
      type: string;
      data: { object: { id: string; approved?: boolean; amount?: number; pending_request?: { amount: number; currency: string } | null; currency?: string; card: { id: string }; merchant_data?: { name?: string } } };
    };
    const a = ev.data.object;
    const [r] = await db.execute<{ id: string; merchant: string; amount_cents: string; currency: string; status: string; expired: boolean }>(sql`
      select id, merchant, amount_cents, currency, status, expires_at < now() as expired from public.payment_requests
      where provider_card_id = ${a.card?.id ?? ""} and org_id = ${org}::uuid`);
    if (ev.type === "issuing_authorization.request") {
      const amount = a.pending_request?.amount ?? a.amount ?? 0;
      const currency = (a.pending_request?.currency ?? a.currency ?? "").toUpperCase();
      const ok =
        !!r &&
        r.status === "issued" &&
        !r.expired &&
        currency === r.currency &&
        amount <= Math.ceil(Number(r.amount_cents) * (1 + PAYMENT_TOLERANCE)) &&
        merchantMatches(r.merchant, a.merchant_data?.name ?? "");
      if (r && !ok)
        await db.execute(sql`update public.payment_requests set error = ${`Declined ${a.merchant_data?.name ?? "a merchant"} for ${amount / 100} ${currency}`} where id = ${r.id}::uuid`);
      // Stripe reads the decision from the response body.
      c.header("stripe-version", "2025-01-27.acacia");
      return c.json({ approved: ok });
    }
    if (ev.type === "issuing_authorization.created" && r && a.approved) {
      await db.execute(sql`update public.payment_requests set status = 'used', used_at = now(), spent_cents = ${a.amount ?? null} where id = ${r.id}::uuid and status = 'issued'`);
      // Single use: the card is cancelled once it's been used.
      const [card] = await db.execute<{ cardholder_id: string }>(sql`select cardholder_id from public.org_payments where org_id = ${org}::uuid`);
      await new StripeIssuingProvider({ secretKey: p.key, cardholderId: card?.cardholder_id ?? "", apiUrl: deps.env.STRIPE_API_URL, fetch: deps.apps?.fetch ?? fetch })
        .cancelCard(a.card.id)
        .catch(() => {});
    }
    return c.json({ received: true });
  });
}
