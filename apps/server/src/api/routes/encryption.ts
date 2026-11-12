/** Encryption at rest (D-136): status, on and off, key rotation, data key replacement (D-238). Owners only. */

import {
  encryptionStatus,
  replaceDataKey,
  rotateEncryptionKey,
  setEncryption,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

export function registerEncryptionRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const role = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ member: boolean; owner: boolean }>(sql`
        select public.has_role(${orgId}::uuid, 'member') as member, public.has_role(${orgId}::uuid, 'owner') as owner`),
    );
    if (!r?.member) throw new ApiError(404, "org_not_found", "Workspace not found");
    return r;
  };
  const audit = (
    orgId: string,
    userId: string,
    action: string,
    metadata: Record<string, unknown>,
  ) =>
    db.execute(sql`
      insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${orgId}::uuid, 'user', ${userId}::uuid, ${action}, 'organization', ${orgId}::uuid, ${JSON.stringify(metadata)}::jsonb)`);

  app.openapi(routes.getEncryption, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await role(claims, id);
    return c.json(await encryptionStatus(db, id), 200);
  });

  app.openapi(routes.setEncryption, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { enabled } = c.req.valid("json");
    if (!(await role(claims, id)).owner)
      throw new ApiError(403, "forbidden", "Only workspace owners can change encryption");
    try {
      const s = await setEncryption(db, id, enabled);
      await audit(id, claims.sub, enabled ? "encryption.enabled" : "encryption.disabled", {});
      return c.json(s, 200);
    } catch (e) {
      if ((e as Error).message === "not_configured")
        throw new ApiError(
          409,
          "encryption_unavailable",
          "This server has no encryption key. Set CONTENT_ENCRYPTION_KEY or AWS KMS first.",
        );
      throw e;
    }
  });

  app.openapi(routes.rotateEncryptionKey, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    if (!(await role(claims, id)).owner)
      throw new ApiError(403, "forbidden", "Only workspace owners can rotate keys");
    try {
      const s = await rotateEncryptionKey(db, id);
      await audit(id, claims.sub, "encryption.rotated", {});
      return c.json(s, 200);
    } catch (e) {
      if ((e as Error).message === "no_key")
        throw new ApiError(409, "encryption_off", "Encryption isn't on for this workspace");
      throw e;
    }
  });

  app.openapi(routes.replaceEncryptionKey, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    if (!(await role(claims, id)).owner)
      throw new ApiError(403, "forbidden", "Only workspace owners can replace keys");
    try {
      const s = await replaceDataKey(db, id);
      await audit(id, claims.sub, "encryption.key_replaced", {});
      return c.json(s, 200);
    } catch (e) {
      const m = (e as Error).message;
      if (m === "not_encrypted")
        throw new ApiError(409, "encryption_off", "Encryption isn't on for this workspace");
      if (m === "not_configured")
        throw new ApiError(409, "encryption_unavailable", "This server has no encryption key.");
      throw e;
    }
  });
}
