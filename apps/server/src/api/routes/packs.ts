/**
 * Packs (docs/PLUGINS-AND-PACKS-PLAN.md): preview, install, update, remove, export and share.
 * The work is in services/packs.ts; these are thin.
 */
import { routes } from "@casama/contracts";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { internalCaller } from "../../services/gallery-install.ts";
import { packService } from "../../services/packs.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { requireClaims } from "./autonomy.ts";

export function registerPackRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const packs = packService(deps);
  const call = (c: { req: { header(n: string): string | undefined } }) =>
    internalCaller(app, c.req.header("authorization") ?? "");

  app.openapi(routes.previewPack, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(await packs.preview(claims, c.req.valid("json")), 200);
  });

  app.openapi(routes.installPack, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const r = await packs.install(claims, call(c), c.req.valid("json"));
    return r.status === "installed" ? c.json(r, 201) : c.json(r, 202);
  });

  app.openapi(routes.listPacks, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json({ items: await packs.list(claims, c.req.valid("query").org_id) }, 200);
  });

  app.openapi(routes.getPack, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(await packs.get(claims, c.req.valid("param").id), 200);
  });

  app.openapi(routes.getPackUpdate, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(await packs.updatePreview(claims, c.req.valid("param").id), 200);
  });

  app.openapi(routes.updatePack, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(
      await packs.update(claims, call(c), c.req.valid("param").id, c.req.valid("json")),
      200,
    );
  });

  app.openapi(routes.removePack, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(
      await packs.remove(claims, c.req.valid("param").id, c.req.valid("query").bots ?? "keep"),
      200,
    );
  });

  app.openapi(routes.exportPack, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(
      await packs.exportPack(claims, c.req.valid("param").id, c.req.valid("json")),
      200,
    );
  });

  app.openapi(routes.sharePack, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(await packs.share(claims, c.req.valid("param").id, c.req.valid("json")), 201);
  });

  app.openapi(routes.getPackShare, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(await packs.viewShare(claims, c.req.valid("param").token), 200);
  });

  app.openapi(routes.revokePackShare, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(await packs.revokeShare(claims, c.req.valid("param").token), 200);
  });

  app.openapi(routes.listGalleryPacks, async (c) => {
    requireClaims(c.get("claims"));
    return c.json({ items: await packs.shelf() }, 200);
  });
}
