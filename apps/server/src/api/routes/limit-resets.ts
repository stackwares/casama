import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { LimitResets } from "../../billing/limit-resets.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { instanceOwnerCheck } from "./admin.ts";
import { billingCall, billingFor } from "./billing.ts";
import type { InProcessEnv } from "./mcp.ts";
export function registerLimitResetRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  // Hosted tools may carry a person's claims but cannot manage or redeem resets.
  for (const path of [
    "/v1/admin/limit-resets",
    "/v1/admin/limit-resets/*",
    "/v1/orgs/:id/billing/resets",
    "/v1/orgs/:id/billing/resets/*",
  ]) {
    app.use(path, async (c, next) => {
      if ((c.env as InProcessEnv | undefined)?.casamaClaims)
        throw new ApiError(403, "forbidden", "Saved resets require a signed-in person");
      await next();
    });
  }
  const service = new LimitResets(deps.db, billingFor(deps).enabled);
  const claims = (v: JwtClaims | undefined) => {
    if (!v) throw new ApiError(401, "unauthorized", "Sign in first");
    return v;
  };
  const admin = instanceOwnerCheck(deps);
  const member = async (c: JwtClaims, id: string) => {
    const [r] = await withUserSession(deps.db, c, (tx) =>
      tx.execute<{ member: boolean; owner: boolean }>(
        sql`select public.is_member(${id}::uuid) as member,public.has_role(${id}::uuid,'owner') as owner`,
      ),
    );
    if (!r?.member) throw new ApiError(404, "org_not_found", "Workspace not found");
    return r.owner;
  };
  app.openapi(routes.listSavedLimitResets, async (c) => {
    const u = claims(c.get("claims"));
    const { id } = c.req.valid("param");
    const owner = await member(u, id);
    return c.json(await billingCall(() => service.saved(id, owner)), 200);
  });
  app.openapi(routes.redeemSavedLimitReset, async (c) => {
    const u = claims(c.get("claims"));
    const { id } = c.req.valid("param");
    await member(u, id);
    return c.json(await billingCall(() => service.redeem(id, u.sub)), 200);
  });
  app.openapi(routes.adminLimitResetSettings, async (c) => {
    await admin(claims(c.get("claims")));
    return c.json(await service.settings(), 200);
  });
  app.openapi(routes.setAdminLimitResetSettings, async (c) => {
    const u = claims(c.get("claims"));
    await admin(u);
    return c.json(await service.setSettings(u.sub, c.req.valid("json")), 200);
  });
  app.openapi(routes.adminLimitResetCampaigns, async (c) => {
    await admin(claims(c.get("claims")));
    return c.json(await service.campaigns(), 200);
  });
  app.openapi(routes.previewAdminLimitResetCampaign, async (c) => {
    await admin(claims(c.get("claims")));
    return c.json(await service.preview(c.req.valid("json")), 200);
  });
  app.openapi(routes.createAdminLimitResetCampaign, async (c) => {
    const u = claims(c.get("claims"));
    await admin(u);
    return c.json(await billingCall(() => service.create(u.sub, c.req.valid("json"))), 200);
  });
  app.openapi(routes.updateAdminLimitResetCampaign, async (c) => {
    const u = claims(c.get("claims"));
    await admin(u);
    return c.json(
      await billingCall(() => service.update(u.sub, c.req.valid("param").id, c.req.valid("json"))),
      200,
    );
  });
  app.openapi(routes.actionAdminLimitResetCampaign, async (c) => {
    const u = claims(c.get("claims"));
    await admin(u);
    await billingCall(() =>
      service.action(u.sub, c.req.valid("param").id, c.req.valid("json").action),
    );
    return c.json({ ok: true }, 200);
  });
  app.openapi(routes.adminWorkspaceLimitResets, async (c) => {
    await admin(claims(c.get("claims")));
    return c.json(await service.events(undefined, c.req.valid("param").id), 200);
  });
  app.openapi(routes.giveAdminWorkspaceLimitReset, async (c) => {
    const u = claims(c.get("claims"));
    await admin(u);
    const campaign = await billingCall(() =>
      service.create(u.sub, c.req.valid("json"), c.req.valid("param").id),
    );
    await service.action(u.sub, campaign.id, "schedule");
    await service.tick();
    return c.json((await service.campaigns()).find((v) => v.id === campaign.id)!, 200);
  });
  app.openapi(routes.actionAdminWorkspaceLimitReset, async (c) => {
    const u = claims(c.get("claims"));
    await admin(u);
    await billingCall(() =>
      service.resetAction(u.sub, c.req.valid("param").id, c.req.valid("json").action),
    );
    return c.json({ ok: true }, 200);
  });
  app.openapi(routes.adminLimitResetEvents, async (c) => {
    await admin(claims(c.get("claims")));
    const q = c.req.valid("query");
    return c.json(await service.events(q.campaign_id, q.org_id, q.limit), 200);
  });
  app.openapi(routes.exportAdminLimitResetEvents, async (c) => {
    await admin(claims(c.get("claims")));
    const q = c.req.valid("query");
    const iterator = service.csv(q.campaign_id, q.org_id);
    const encoder = new TextEncoder();
    const body = new ReadableStream<Uint8Array>({
      async pull(controller) {
        try {
          const next = await iterator.next();
          if (next.done) controller.close();
          else controller.enqueue(encoder.encode(next.value));
        } catch (e) {
          controller.error(e);
        }
      },
      async cancel() {
        await iterator.return();
      },
    });
    return c.body(body, 200, {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": 'attachment; filename="saved-reset-events.csv"',
    });
  });
}
