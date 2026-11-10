/**
 * Enterprise routes (D-073), registered by the API. Each checks the license feature and the
 * caller's workspace role; without a valid key they answer 402 license_required.
 */
import { type Database, type JwtClaims, withUserSession } from "@kasama/db";
import { sql } from "drizzle-orm";
import type { Context, Hono } from "hono";
import { type EeFeature, type License, verifyLicense } from "./license.ts";

export { type License, verifyLicense } from "./license.ts";
export { forwardAuditLogs, otlpLogs, sendBatch, signAuditBatch } from "./audit-forward.ts";

export interface EeDeps {
  db: Database;
  licenseKey?: string;
  /** Test-only override of the license public key. */
  licensePublicKey?: string;
  /** Supabase Auth admin API (for SSO providers): <SUPABASE_URL>/auth/v1 and a service role key. */
  authAdmin?: { url: string; serviceRoleKey: string; fetch?: typeof fetch };
  claims: (c: Context) => JwtClaims | undefined;
}

const problem = (c: Context, status: number, code: string, detail: string) =>
  c.json(
    { type: `https://kasama.dev/problems/${code}`, title: code, status, code, detail },
    status as 400,
  );

export function registerEnterpriseRoutes(app: Hono, deps: EeDeps) {
  let cached: Promise<License | null> | undefined;
  const license = () => (cached ??= verifyLicense(deps.licenseKey, deps.licensePublicKey));

  const guard = async (c: Context, feature: EeFeature, orgId: string) => {
    const claims = deps.claims(c);
    if (!claims)
      return { error: problem(c, 401, "unauthorized", "Missing or invalid bearer token") };
    const l = await license();
    if (!l || l.expiresAt < new Date() || !l.features.includes(feature))
      return {
        error: problem(
          c,
          402,
          "license_required",
          `This is an enterprise feature (${feature}). Add a Kasama Enterprise license key.`,
        ),
      };
    const [r] = await withUserSession(deps.db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.has_role(${orgId}::uuid, 'admin') as ok`),
    );
    if (!r?.ok)
      return {
        error: problem(c, 403, "forbidden", "Only workspace owners and admins can do this"),
      };
    return { claims, license: l };
  };

  // ---------------------------------------------------------------- audit forwarding (D-146)
  const forwarderOut = (r: Record<string, unknown>) => ({
    id: r.id,
    kind: r.kind,
    config: r.config,
    enabled: r.enabled,
    sent_rows: Number(r.sent_rows ?? 0),
    last_sent_at: r.last_sent_at ? new Date(String(r.last_sent_at)).toISOString() : null,
    last_error: r.last_error ?? null,
  });
  app.get("/v1/orgs/:id/audit-forwarders", async (c) => {
    const orgId = c.req.param("id");
    const g = await guard(c, "audit_forwarding", orgId);
    if (g.error) return g.error;
    const rows = await deps.db.execute<Record<string, unknown>>(sql`
      select id, kind, config, enabled, sent_rows, last_sent_at, last_error from public.audit_forwarders where org_id = ${orgId}::uuid order by created_at`);
    return c.json({ items: rows.map(forwarderOut) });
  });
  app.post("/v1/orgs/:id/audit-forwarders", async (c) => {
    const orgId = c.req.param("id");
    const g = await guard(c, "audit_forwarding", orgId);
    if (g.error) return g.error;
    const b = (await c.req.json().catch(() => ({}))) as { kind?: string; config?: Record<string, unknown>; secret?: string; from?: "now" | "start" };
    const cfg = b.config ?? {};
    const okUrl = (u: unknown) => typeof u === "string" && /^https?:\/\//.test(u);
    if (b.kind === "webhook" && (!okUrl(cfg.url) || !b.secret)) return problem(c, 400, "validation_failed", "A webhook needs config.url and a signing secret");
    if (b.kind === "otlp" && !okUrl(cfg.url)) return problem(c, 400, "validation_failed", "OTLP needs config.url");
    if (b.kind === "s3" && (typeof cfg.bucket !== "string" || !b.secret)) return problem(c, 400, "validation_failed", "S3 needs config.bucket and credentials");
    if (!["webhook", "otlp", "s3"].includes(String(b.kind))) return problem(c, 400, "validation_failed", "kind is webhook, otlp or s3");
    // From now on (default), or the whole history from the start.
    const [r] = await deps.db.execute<Record<string, unknown>>(sql`
      insert into public.audit_forwarders (org_id, kind, config, vault_secret_id, cursor_at, cursor_id)
      values (${orgId}::uuid, ${b.kind}, ${JSON.stringify(cfg)}::jsonb, ${b.secret ? sql`(select vault.create_secret(${b.secret}, null, 'audit forwarder'))` : sql`null`},
              ${b.from === "start" ? sql`null` : sql`clock_timestamp()`}, ${b.from === "start" ? null : "ffffffff-ffff-ffff-ffff-ffffffffffff"}::uuid)
      returning id, kind, config, enabled, sent_rows, last_sent_at, last_error`);
    await deps.db.execute(sql`
      insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${orgId}::uuid, 'user', ${g.claims.sub}::uuid, 'audit.forwarder_added', 'audit_forwarder', ${String(r?.id)}::uuid, ${JSON.stringify({ kind: b.kind })}::jsonb)`);
    return c.json(forwarderOut(r ?? {}), 201);
  });
  app.delete("/v1/orgs/:id/audit-forwarders/:fid", async (c) => {
    const orgId = c.req.param("id");
    const g = await guard(c, "audit_forwarding", orgId);
    if (g.error) return g.error;
    await deps.db.execute(sql`
      with gone as (delete from public.audit_forwarders where id = ${c.req.param("fid")}::uuid and org_id = ${orgId}::uuid returning vault_secret_id)
      delete from vault.secrets where id in (select vault_secret_id from gone)`);
    return c.json({ deleted: c.req.param("fid") });
  });

  // ---------------------------------------------------------------- audit export
  app.get("/v1/orgs/:id/audit-log/export", async (c) => {
    const orgId = c.req.param("id");
    const g = await guard(c, "audit_export", orgId);
    if (g.error) return g.error;
    const from = c.req.query("from") ?? new Date(Date.now() - 90 * 86_400_000).toISOString();
    const to = c.req.query("to") ?? new Date().toISOString();
    const rows = await deps.db.execute<Record<string, unknown>>(sql`
      select id, created_at, actor_type, actor_id, action, target_type, target_id, metadata
      from public.audit_log where org_id = ${orgId}::uuid
        and created_at >= ${from}::timestamptz and created_at < ${to}::timestamptz
      order by created_at`);
    await deps.db.execute(sql`
      insert into public.audit_log (org_id, actor_type, actor_id, action, metadata)
      values (${orgId}::uuid, 'user', ${g.claims.sub}::uuid, 'audit.export', ${JSON.stringify({ from, to, rows: rows.length })}::jsonb)`);
    if (c.req.query("format") === "json") return c.json({ items: rows });
    const cols = [
      "id",
      "created_at",
      "actor_type",
      "actor_id",
      "action",
      "target_type",
      "target_id",
      "metadata",
    ];
    const cell = (v: unknown) => {
      const s =
        v == null
          ? ""
          : v instanceof Date
            ? v.toISOString()
            : typeof v === "object"
              ? JSON.stringify(v)
              : String(v);
      return /[",\n]/.test(s) ? `"${s.replaceAll('"', '""')}"` : s;
    };
    const csv = [cols.join(","), ...rows.map((r) => cols.map((k) => cell(r[k])).join(","))].join(
      "\n",
    );
    return c.body(`${csv}\n`, 200, {
      "content-type": "text/csv; charset=utf-8",
      "content-disposition": `attachment; filename="audit-${orgId}.csv"`,
    });
  });

  // ---------------------------------------------------------------- SSO (SAML via Supabase Auth)
  const authAdmin = async (path: string, init: RequestInit = {}) => {
    if (!deps.authAdmin) throw new Error("sso_not_configured");
    const f = deps.authAdmin.fetch ?? fetch;
    const r = await f(`${deps.authAdmin.url.replace(/\/$/, "")}/admin/sso/providers${path}`, {
      ...init,
      headers: {
        authorization: `Bearer ${deps.authAdmin.serviceRoleKey}`,
        apikey: deps.authAdmin.serviceRoleKey,
        "content-type": "application/json",
      },
    });
    const body = (await r.json().catch(() => ({}))) as Record<string, unknown>;
    if (!r.ok)
      throw Object.assign(new Error(String(body.msg ?? body.message ?? r.status)), {
        status: r.status,
      });
    return body;
  };
  const ssoProviderId = async (orgId: string) =>
    (
      await deps.db.execute<{ value: { provider_id: string; domains: string[] } }>(
        sql`select value from public.instance_settings where key = ${`sso:${orgId}`}`,
      )
    )[0]?.value;

  app.post("/v1/orgs/:id/sso", async (c) => {
    const orgId = c.req.param("id");
    const g = await guard(c, "sso", orgId);
    if (g.error) return g.error;
    if (!deps.authAdmin)
      return problem(
        c,
        409,
        "sso_not_configured",
        "Set SUPABASE_SERVICE_ROLE_KEY and enable SAML in Supabase Auth",
      );
    const b = (await c.req.json().catch(() => ({}))) as {
      metadata_url?: string;
      metadata_xml?: string;
      domains?: string[];
    };
    const domains = (b.domains ?? [])
      .map((d) => d.toLowerCase().trim())
      .filter((d) => /^[a-z0-9.-]+\.[a-z]{2,}$/.test(d));
    if ((!b.metadata_url && !b.metadata_xml) || !domains.length)
      return problem(
        c,
        400,
        "validation_failed",
        "Give metadata_url (or metadata_xml) and at least one email domain",
      );
    try {
      const existing = await ssoProviderId(orgId);
      const body = JSON.stringify({
        type: "saml",
        metadata_url: b.metadata_url,
        metadata_xml: b.metadata_xml,
        domains,
      });
      const p = existing
        ? await authAdmin(`/${existing.provider_id}`, { method: "PUT", body })
        : await authAdmin("", { method: "POST", body });
      await deps.db.execute(sql`
        insert into public.instance_settings (key, value) values (${`sso:${orgId}`}, ${JSON.stringify({ provider_id: p.id, domains })}::jsonb)
        on conflict (key) do update set value = excluded.value, updated_at = now()`);
      await deps.db.execute(sql`
        insert into public.audit_log (org_id, actor_type, actor_id, action, metadata)
        values (${orgId}::uuid, 'user', ${g.claims.sub}::uuid, 'sso.configure', ${JSON.stringify({ domains })}::jsonb)`);
      return c.json({ provider_id: p.id, domains }, existing ? 200 : 201);
    } catch (err) {
      return problem(c, 502, "sso_provider_error", (err as Error).message);
    }
  });

  app.get("/v1/orgs/:id/sso", async (c) => {
    const orgId = c.req.param("id");
    const g = await guard(c, "sso", orgId);
    if (g.error) return g.error;
    const s = await ssoProviderId(orgId);
    return c.json({ configured: !!s, domains: s?.domains ?? [] });
  });

  app.delete("/v1/orgs/:id/sso", async (c) => {
    const orgId = c.req.param("id");
    const g = await guard(c, "sso", orgId);
    if (g.error) return g.error;
    const s = await ssoProviderId(orgId);
    if (!s) return problem(c, 404, "not_found", "SSO is not configured");
    await authAdmin(`/${s.provider_id}`, { method: "DELETE" }).catch(() => {});
    await deps.db.execute(sql`delete from public.instance_settings where key = ${`sso:${orgId}`}`);
    return c.json({ deleted: true });
  });
}
