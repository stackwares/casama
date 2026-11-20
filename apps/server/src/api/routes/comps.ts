/**
 * Free plans for friends (docs/COMP-PLANS-PLAN.md): instance owners grant plans and make gift
 * codes; workspace owners redeem a code. Hosted tools (MCP, in-process calls) can't reach any of it:
 * the admin bot has its own approved tools.
 */
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { Comps } from "../../billing/comps.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { clientIp } from "../util.ts";
import { instanceOwnerCheck } from "./admin.ts";
import { billingCall, billingFor } from "./billing.ts";
import { failureLimiter } from "./joining.ts";
import type { InProcessEnv } from "./mcp.ts";

export function registerCompRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  for (const path of [
    "/v1/admin/comps",
    "/v1/admin/comps/*",
    "/v1/admin/comp-codes",
    "/v1/admin/comp-codes/*",
    "/v1/admin/comp-settings",
    "/v1/me/comp/*",
  ]) {
    app.use(path, async (c, next) => {
      if ((c.env as InProcessEnv | undefined)?.casamaClaims)
        throw new ApiError(403, "forbidden", "Free plans need a signed-in person");
      await next();
    });
  }
  const billing = billingFor(deps);
  const comps = new Comps(deps.db, billing);
  const admin = instanceOwnerCheck(deps);
  const linkBase = deps.env.COMP_LINK_BASE.replace(/\/+$/, "");
  const limiter = failureLimiter();
  const claimsOf = (v: JwtClaims | undefined) => {
    if (!v) throw new ApiError(401, "unauthorized", "Sign in first");
    return v;
  };
  const limitKey = (c: { req: { header(n: string): string | undefined } }, claims?: JwtClaims) =>
    claims?.sub
      ? `u:${claims.sub}`
      : `ip:${clientIp((n) => c.req.header(n), deps.env.TRUSTED_CLIENT_IP_HEADER)}`;

  app.openapi(routes.adminCompSettings, async (c) => {
    await admin(claimsOf(c.get("claims")));
    return c.json(await comps.settings(), 200);
  });
  app.openapi(routes.setAdminCompSettings, async (c) => {
    const u = claimsOf(c.get("claims"));
    await admin(u);
    return c.json(await billingCall(() => comps.setSettings(u.sub, c.req.valid("json"))), 200);
  });
  app.openapi(routes.listAdminComps, async (c) => {
    await admin(claimsOf(c.get("claims")));
    const q = c.req.valid("query");
    return c.json(await comps.list({ running: q.running === "true", limit: q.limit }), 200);
  });
  app.openapi(routes.grantAdminComp, async (c) => {
    const u = claimsOf(c.get("claims"));
    await admin(u);
    return c.json(await billingCall(() => comps.grant(u.sub, c.req.valid("json"))), 200);
  });
  app.openapi(routes.updateAdminComp, async (c) => {
    const u = claimsOf(c.get("claims"));
    await admin(u);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    return c.json(
      await billingCall(() =>
        body.revoke ? comps.revoke(u.sub, id) : comps.extend(u.sub, id, body.extend_months ?? 0),
      ),
      200,
    );
  });
  app.openapi(routes.listAdminCompCodes, async (c) => {
    await admin(claimsOf(c.get("claims")));
    return c.json(await comps.codes(), 200);
  });
  app.openapi(routes.createAdminCompCode, async (c) => {
    const u = claimsOf(c.get("claims"));
    await admin(u);
    const made = await billingCall(() => comps.createCode(u.sub, c.req.valid("json")));
    c.header("cache-control", "no-store");
    return c.json({ ...made, link: `${linkBase}/${made.code}` }, 200);
  });
  app.openapi(routes.updateAdminCompCode, async (c) => {
    const u = claimsOf(c.get("claims"));
    await admin(u);
    return c.json(
      await billingCall(() =>
        comps.updateCode(u.sub, c.req.valid("param").id, c.req.valid("json")),
      ),
      200,
    );
  });

  app.openapi(routes.previewCompCode, async (c) => {
    const key = limitKey(c);
    limiter.check(key);
    const found = await comps.preview(c.req.valid("query").code);
    if (!found) {
      limiter.miss(key);
      throw new ApiError(404, "comp_code_invalid", "That code doesn't exist or can't be used");
    }
    c.header("cache-control", "private, max-age=60");
    return c.json(found, 200);
  });

  app.openapi(routes.redeemCompCode, async (c) => {
    const u = claimsOf(c.get("claims"));
    const key = limitKey(c, u);
    limiter.check(key);
    const body = c.req.valid("json");
    const [r] = await withUserSession(deps.db, u, (tx) =>
      tx.execute<{ owner: boolean }>(
        sql`select public.has_role(${body.org_id}::uuid, 'owner') as owner`,
      ),
    );
    if (!r?.owner)
      throw new ApiError(403, "forbidden", "Only the workspace's owner can redeem a gift code");
    try {
      const comp = await billingCall(() => comps.redeem(u.sub, body.org_id, body.code));
      const [plan] = await deps.db.execute<{ name: string }>(
        sql`select name from public.plans where code = ${comp.plan_code}`,
      );
      return c.json(
        {
          plan_code: comp.plan_code,
          plan_name: plan?.name ?? comp.plan_code,
          ends_at: comp.ends_at,
          org_id: comp.org_id,
        },
        200,
      );
    } catch (err) {
      if (err instanceof ApiError && err.code === "comp_code_invalid") limiter.miss(key);
      throw err;
    }
  });
}
