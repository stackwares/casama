/**
 * Scan to sign in (D-296): a signed-in app asks for a one-time code and shows it as a QR code; a
 * phone that scans it trades the code here for a one-time sign-in token from Auth, and finishes
 * with Auth's own verify call, so it holds a session of its own. Works on any server, Casama Cloud
 * included. On a self-hosted server it is how a phone gets in after remote access is turned on.
 *
 * The code never passes through Casama Cloud or casama.ai: it goes from one screen to the phone's
 * camera, and from the phone to this server. The session is a plain one, so an account with
 * two-step sign-in is still asked for its second step on the new device.
 */
import { createHash, randomBytes } from "node:crypto";
import { routes } from "@casama/contracts";
import type { JwtClaims } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { requireFreshOwnerAction } from "../admin-security.ts";
import { ApiError } from "../errors.ts";
import { requireLiveSession } from "../live-session.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { isInstanceOwner } from "./admin.ts";

const CODE_TTL_MS = 5 * 60_000;
const PER_MINUTE = 5;

const hash = (v: string) => createHash("sha256").update(v).digest("hex");

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

/** Auth's admin API, as this server reaches it. */
export function authAdminFor(deps: AppDeps) {
  if (deps.authAdmin) return deps.authAdmin;
  const key = deps.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!key) return undefined;
  const base = (deps.env.SUPABASE_INTERNAL_URL ?? deps.env.SUPABASE_URL).replace(/\/$/, "");
  return { url: `${base}/auth/v1`, serviceRoleKey: key };
}

/** Whether a phone somewhere else could reach [url]: https, and not this machine or a private network. */
export function reachableFromOutside(url: string) {
  let u: URL;
  try {
    u = new URL(url);
  } catch {
    return false;
  }
  const host = u.hostname.replace(/^\[|\]$/g, "").toLowerCase();
  if (u.protocol !== "https:") return false;
  if (host === "localhost" || host.endsWith(".localhost") || host.endsWith(".local")) return false;
  if (host === "::1" || /^f[cd]|^fe80/.test(host)) return false;
  if (/^(127\.|10\.|192\.168\.|169\.254\.|172\.(1[6-9]|2\d|3[01])\.)/.test(host)) return false;
  return true;
}

export function registerSignInCodeRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;
  const isOwner = isInstanceOwner(deps);
  const serverUrl = () => (env.PUBLIC_API_URL ?? env.SUPABASE_URL).replace(/\/$/, "");

  app.openapi(routes.createSignInCode, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireLiveSession(db, claims);
    // The code becomes a brand-new sign-in on another device, which would count as a fresh one for
    // the admin console. An instance owner proves a fresh sign-in first, so an unattended app can't
    // mint one.
    if (await isOwner(claims)) await requireFreshOwnerAction(db, claims);
    if (!authAdminFor(deps))
      throw new ApiError(
        409,
        "sign_in_codes_unavailable",
        "This server can't make sign-in codes (it has no Auth service key)",
      );
    const [recent] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.signin_codes
      where user_id = ${claims.sub}::uuid and created_at > now() - interval '1 minute'`);
    if ((recent?.n ?? 0) >= PER_MINUTE)
      throw new ApiError(429, "rate_limited", "Too many codes; wait a minute", {
        headers: { "retry-after": "60" },
      });
    const code = `ksc_${randomBytes(32).toString("base64url")}`;
    const expires = new Date(Date.now() + CODE_TTL_MS);
    // A new code ends the ones this person hasn't used: only the QR on screen now works.
    await db.execute(sql`
      update public.signin_codes set expires_at = now()
      where user_id = ${claims.sub}::uuid and used_at is null and expires_at > now()`);
    await db.execute(sql`
      delete from public.signin_codes
      where user_id = ${claims.sub}::uuid and created_at < now() - interval '30 days'`);
    await db.execute(sql`
      insert into public.signin_codes (user_id, code_hash, expires_at)
      values (${claims.sub}::uuid, ${hash(code)}, ${expires.toISOString()}::timestamptz)`);
    const server = serverUrl();
    // After "#", so the code is never sent to the page that opens the app.
    const link = `${env.PAIR_LINK_URL}#v=1&s=${encodeURIComponent(server)}&c=${encodeURIComponent(code)}`;
    return c.json(
      {
        code,
        expires_at: expires.toISOString(),
        server_url: server,
        reachable: reachableFromOutside(server),
        pair_url: link,
      },
      201,
    );
  });

  app.openapi(routes.redeemSignInCode, async (c) => {
    const { code, device_name } = c.req.valid("json");
    const admin = authAdminFor(deps);
    if (!admin)
      throw new ApiError(409, "sign_in_codes_unavailable", "This server has no sign-in codes");
    const device = (device_name ?? "").trim().slice(0, 80) || "another device";
    // Marked used in the same statement that finds it, so a code works once.
    const [row] = await db.execute<{ user_id: string; email: string | null }>(sql`
      with taken as (
        update public.signin_codes set used_at = now(), used_by = ${device}
        where code_hash = ${hash(code)} and used_at is null and expires_at > now()
        returning user_id)
      select t.user_id, u.email from taken t join auth.users u on u.id = t.user_id`);
    if (!row?.email)
      throw new ApiError(404, "code_not_valid", "That code isn't valid any more. Show a new one.");

    let tokenHash: string | undefined;
    try {
      const res = await (admin.fetch ?? fetch)(`${admin.url}/admin/generate_link`, {
        method: "POST",
        headers: {
          authorization: `Bearer ${admin.serviceRoleKey}`,
          apikey: admin.serviceRoleKey,
          "content-type": "application/json",
        },
        body: JSON.stringify({ type: "magiclink", email: row.email }),
        signal: AbortSignal.timeout(15_000),
      });
      const json = (await res.json().catch(() => ({}))) as {
        hashed_token?: string;
        properties?: { hashed_token?: string };
      };
      if (res.ok) tokenHash = json.hashed_token ?? json.properties?.hashed_token;
    } catch {
      // Answered below.
    }
    if (!tokenHash)
      throw new ApiError(503, "auth_unavailable", "Sign-in isn't available right now. Try again.");

    await db.execute(sql`
      insert into public.notifications (user_id, kind, payload)
      values (${row.user_id}::uuid, 'sign_in', ${JSON.stringify({
        title: "New sign-in",
        body: `Signed in on ${device} by scanning a code. If this wasn't you, change your password.`,
        link: "/settings",
      })}::jsonb)`);
    return c.json({ token_hash: tokenHash, email: row.email }, 200);
  });
}
