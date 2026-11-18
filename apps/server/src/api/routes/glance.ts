/**
 * Widgets (D-405, docs/WIDGETS-PLAN.md §8): the glance, widget keys and their push tokens.
 *
 * A widget key is read-only by design: with `Authorization: Widget <key>` a caller may read the
 * glance, read a creation's cover in the key's workspace, and register the key's own push token.
 * Every other route answers 401 to it (widgetCaller), and each key is held to 120 requests an
 * hour. Creating, changing and deleting keys needs the person's session.
 */
import { randomBytes } from "node:crypto";
import { buildGlance, type GlanceCreditsSource } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv, WidgetCaller } from "../types.ts";
import { iso, sha256Hex } from "../util.ts";
import { billingFor } from "./billing.ts";

/** How many requests one widget key may make in an hour (§8.9). */
export const WIDGET_KEY_PER_HOUR = 120;
/** Keys a person keeps per workspace; the least recently used go past this (old installs). */
export const WIDGET_KEYS_KEPT = 20;

/** The only requests a widget key may make. */
const WIDGET_ROUTES: Array<[string, RegExp]> = [
  ["GET", /^\/v1\/glance\/?$/],
  ["PUT", /^\/v1\/widget-keys\/current\/push-token\/?$/],
  ["GET", /^\/v1\/creations\/[0-9a-f-]{36}\/cover\/?$/i],
];

export const newWidgetKey = () => `cwk_${randomBytes(32).toString("base64url")}`;
export const hashWidgetKey = (key: string) => sha256Hex(`casama-widget-key:${key}`);

/**
 * Resolves `Authorization: Widget <key>`: the route must be one a key may use, the key must exist
 * and its person must still be in its workspace. Marks it used and counts it against the hour.
 */
export function widgetCaller(deps: Pick<AppDeps, "db">, o: { now?: () => number } = {}) {
  const now = o.now ?? Date.now;
  const windows = new Map<string, { start: number; count: number }>();
  return async (method: string, path: string, key: string): Promise<WidgetCaller> => {
    const m = method === "HEAD" ? "GET" : method;
    if (!WIDGET_ROUTES.some(([wm, re]) => wm === m && re.test(path)))
      throw new ApiError(401, "widget_key_not_allowed", "A widget key can't be used here");
    if (!key.startsWith("cwk_") || key.length > 200)
      throw new ApiError(401, "invalid_widget_key", "The widget key is invalid");
    const [row] = await deps.db.execute<{
      id: string;
      user_id: string;
      org_id: string;
      private: boolean;
    }>(sql`
      update public.widget_keys k set last_used_at = now()
      from public.memberships m
      where k.key_hash = ${hashWidgetKey(key)} and m.user_id = k.user_id and m.org_id = k.org_id
      returning k.id, k.user_id, k.org_id, k.private`);
    if (!row) throw new ApiError(401, "invalid_widget_key", "The widget key is invalid");
    const t = now();
    let w = windows.get(row.id);
    if (!w || t - w.start >= 3_600_000) {
      if (windows.size > 50_000) windows.clear();
      w = { start: t, count: 0 };
      windows.set(row.id, w);
    }
    if (w.count >= WIDGET_KEY_PER_HOUR) {
      const retry = Math.max(1, Math.ceil((w.start + 3_600_000 - t) / 1000));
      throw new ApiError(429, "rate_limited", "This widget key made too many requests this hour", {
        headers: { "retry-after": String(retry) },
      });
    }
    w.count += 1;
    return { id: row.id, userId: row.user_id, orgId: row.org_id, private: row.private };
  };
}

/** Claims for a widget key's person, so row-level security reads as them. */
export const widgetClaims = (w: WidgetCaller): JwtClaims => ({
  sub: w.userId,
  role: "authenticated",
  aud: "authenticated",
  widget_key: w.id,
});

const requireSession = (c: {
  get(k: "claims"): JwtClaims | undefined;
  get(k: "widgetKey"): WidgetCaller | undefined;
  get(k: "watchKey"): unknown;
}) => {
  const claims = c.get("claims");
  if (!claims || c.get("widgetKey") || c.get("watchKey"))
    throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

type KeyRow = {
  id: string;
  org_id: string;
  platform: "ios" | "android" | "macos";
  label: string | null;
  private: boolean;
  push_kind: string | null;
  last_used_at: string | Date | null;
  created_at: string | Date;
};
const keyOut = (k: KeyRow) => ({
  id: k.id,
  org_id: k.org_id,
  platform: k.platform,
  label: k.label,
  private: k.private,
  has_push: !!k.push_kind,
  last_used_at: k.last_used_at ? iso(k.last_used_at) : null,
  created_at: iso(k.created_at),
});

/** Whether an If-None-Match header names this version (quoted, weak or bare). */
export function matchesVersion(header: string | undefined, version: string) {
  if (!header) return false;
  return header
    .split(",")
    .map((v) => v.trim().replace(/^W\//, "").replace(/^"|"$/g, ""))
    .some((v) => v === version || v === "*");
}

export function registerGlanceRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const billing = billingFor(deps);

  const isMember = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${orgId}::uuid) as ok`),
    );
    return r?.ok === true;
  };

  /** Billing's view for the credits part; billing off on self-hosted servers. */
  const credits = (orgId: string) => async (): Promise<GlanceCreditsSource | null> => {
    if (!billing.enabled) return null;
    const s = await billing.summary(orgId);
    return {
      billing: true,
      unlimited: s.unlimited,
      plan: s.plan_name,
      left_usd: s.credits_usd,
      daily: s.daily
        ? { used_usd: s.daily.used_usd, cap_usd: s.daily.cap_usd, resets_at: s.daily.resets_at }
        : null,
    };
  };

  app.openapi(routes.getGlance, async (c) => {
    const widget = c.get("widgetKey");
    const watch = c.get("watchKey");
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const asked = c.req.valid("query").org_id;
    let orgId: string;
    let priv = false;
    if (widget) {
      if (asked && asked !== widget.orgId)
        throw new ApiError(403, "forbidden", "This widget key reads another workspace");
      orgId = widget.orgId;
      priv = widget.private;
    } else if (watch) {
      // A watch reads its own workspace, privately when the person turned details off (D-410).
      if (asked && asked !== watch.orgId)
        throw new ApiError(403, "forbidden", "This watch key reads another workspace");
      orgId = watch.orgId;
      priv = !watch.showDetails;
    } else {
      if (!asked) throw new ApiError(400, "org_required", "Say which workspace (org_id)");
      if (!(await isMember(claims, asked)))
        throw new ApiError(404, "org_not_found", "Workspace not found");
      orgId = asked;
    }
    const glance = await buildGlance(db, {
      userId: claims.sub,
      orgId,
      private: priv,
      credits: credits(orgId),
    });
    c.header("etag", `"${glance.version}"`);
    c.header("cache-control", "private, no-cache");
    if (matchesVersion(c.req.header("if-none-match"), glance.version))
      return c.body(null, 304) as never;
    return c.json(glance, 200);
  });

  app.openapi(routes.createWidgetKey, async (c) => {
    const claims = requireSession(c);
    const body = c.req.valid("json");
    if (!(await isMember(claims, body.org_id)))
      throw new ApiError(404, "org_not_found", "Workspace not found");
    const key = newWidgetKey();
    const [row] = await db.execute<{ id: string; created_at: string | Date }>(sql`
      insert into public.widget_keys (user_id, org_id, platform, key_hash, label)
      values (${claims.sub}::uuid, ${body.org_id}::uuid, ${body.platform}, ${hashWidgetKey(key)},
              ${body.label?.trim() || null})
      returning id, created_at`);
    // An app reinstalled many times leaves keys nobody uses: keep the most recent ones.
    await db.execute(sql`
      delete from public.widget_keys where id in (
        select id from public.widget_keys
        where user_id = ${claims.sub}::uuid and org_id = ${body.org_id}::uuid
        order by coalesce(last_used_at, created_at) desc offset ${WIDGET_KEYS_KEPT})`);
    return c.json({ id: row?.id as string, key, created_at: iso(row?.created_at as string) }, 201);
  });

  app.openapi(routes.updateWidgetKey, async (c) => {
    const claims = requireSession(c);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const [row] = await db.execute<KeyRow>(sql`
      update public.widget_keys set private = coalesce(${body.private ?? null}::boolean, private)
      where id = ${id}::uuid and user_id = ${claims.sub}::uuid
      returning id, org_id, platform, label, private, push_kind, last_used_at, created_at`);
    if (!row) throw new ApiError(404, "widget_key_not_found", "Widget key not found");
    // The widgets read the change next time; tell them now.
    deps.glance?.changed(claims.sub, { urgent: true });
    return c.json(keyOut(row), 200);
  });

  app.openapi(routes.deleteWidgetKey, async (c) => {
    const claims = requireSession(c);
    const { id } = c.req.valid("param");
    const [row] = await db.execute<{ id: string }>(sql`
      delete from public.widget_keys where id = ${id}::uuid and user_id = ${claims.sub}::uuid
      returning id`);
    if (!row) throw new ApiError(404, "widget_key_not_found", "Widget key not found");
    return c.json({ deleted: row.id }, 200);
  });

  app.openapi(routes.setWidgetPushToken, async (c) => {
    const widget = c.get("widgetKey");
    const claims = c.get("claims");
    if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
    const keyId = widget ? widget.id : c.req.valid("query").key_id;
    if (!keyId) throw new ApiError(400, "key_required", "Say which widget key (key_id)");
    const body = c.req.valid("json");
    const [key] = await db.execute<{ platform: string }>(sql`
      select platform from public.widget_keys where id = ${keyId}::uuid and user_id = ${claims.sub}::uuid`);
    if (!key) throw new ApiError(404, "widget_key_not_found", "Widget key not found");
    // Apple's widget tokens on Apple's devices, Firebase tokens on Android.
    if ((key.platform === "android") !== (body.kind === "fcm"))
      throw new ApiError(400, "wrong_token_kind", "That kind of token doesn't fit this device");
    if (body.kind === "apns_widgets" && !/^[0-9a-f]{16,200}$/i.test(body.token))
      throw new ApiError(400, "bad_token", "Apple's widget token is hex");
    // A token belongs to one key: a reinstall's new key takes it over from the old one.
    await db.execute(sql`
      update public.widget_keys set push_token = null, push_kind = null, push_sandbox = null
      where push_token = ${body.token} and id <> ${keyId}::uuid`);
    await db.execute(sql`
      update public.widget_keys
      set push_token = ${body.token}, push_kind = ${body.kind},
          push_sandbox = ${body.kind === "apns_widgets" ? body.sandbox === true : null}
      where id = ${keyId}::uuid`);
    return c.json({ ok: true as const }, 200);
  });
}
