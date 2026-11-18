/**
 * Casama Link keys (`kcc_`, D-071 and D-296): what a self-hosted server presents to Casama
 * Cloud. A key belongs to a workspace and carries scopes: computers and models spend the
 * workspace's credits; remote_access and push don't.
 */
import { createHash, randomBytes } from "node:crypto";
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";
import type { Context, MiddlewareHandler } from "hono";

export interface LinkCaller {
  keyId: string;
  orgId: string;
  instance: string;
  scopes: string[];
}

export const hashLinkKey = (key: string) => createHash("sha256").update(key).digest("hex");

export function newLinkKey() {
  const key = `kcc_${randomBytes(24).toString("base64url")}`;
  return { key, hash: hashLinkKey(key), hint: `${key.slice(0, 8)}…${key.slice(-4)}` };
}

/**
 * Whether the key's workspace, or the server linked with this key, is suspended. A suspended
 * server has lost its address already; it also gets nothing that costs money or reaches people
 * (relay credentials, notifications) until the suspension is lifted.
 */
export async function linkSuspended(db: Database, k: LinkCaller) {
  const [row] = await db.execute<{ blocked: boolean }>(sql`
    select (o.suspended_at is not null or exists (
      select 1 from public.link_servers s
      where s.key_id = ${k.keyId}::uuid and s.status = 'suspended')) as blocked
    from public.organizations o where o.id = ${k.orgId}::uuid`);
  return !row || row.blocked;
}

const callers = new WeakMap<Request, LinkCaller>();

/** The key behind this request (set by linkKeyAuth). */
export const linkCaller = (c: Context) => callers.get(c.req.raw) as LinkCaller;

/**
 * Bearer auth for /link/v1/*: a key that exists and isn't revoked. Linking is the one part with
 * no key yet (it is how a server gets one), so it passes through.
 */
export function linkKeyAuth(db: Database): MiddlewareHandler {
  const lastUsed = new Map<string, number>();
  return async (c, next) => {
    if (c.req.path.startsWith("/link/v1/sign-in/")) return next();
    const auth = c.req.header("authorization") ?? "";
    const key = auth.startsWith("Bearer ") ? auth.slice(7) : "";
    if (!key.startsWith("kcc_"))
      return c.json({ code: "unauthorized", message: "Missing Casama Link key" }, 401);
    const [k] = await db.execute<{
      id: string;
      org_id: string;
      instance_name: string;
      scopes: string[];
    }>(sql`
      select id, org_id, instance_name, scopes from public.link_keys
      where key_hash = ${hashLinkKey(key)} and revoked_at is null`);
    if (!k)
      return c.json({ code: "unauthorized", message: "This Casama Link key is not valid" }, 401);
    if ((lastUsed.get(k.id) ?? 0) < Date.now() - 60_000) {
      lastUsed.set(k.id, Date.now());
      await db.execute(
        sql`update public.link_keys set last_used_at = now() where id = ${k.id}::uuid`,
      );
    }
    callers.set(c.req.raw, {
      keyId: k.id,
      orgId: k.org_id,
      instance: k.instance_name,
      scopes: k.scopes,
    });
    await next();
  };
}
