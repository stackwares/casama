/**
 * Gallery browse (D-184) and gallery v2 (D-315): use counts, installs with questions and needs,
 * starter sets, Installed and updates, workspace rules and approvals, the requests board,
 * submissions and authors' stats. Installing a skill also stays on the skills route.
 */

import { routes } from "@casama/contracts";
import type { JwtClaims } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import {
  type GalleryRecord,
  galleryAuthors,
  galleryIndex,
  galleryItem,
  galleryRecord,
  galleryRecords,
  gallerySets,
  setGalleryWarn,
} from "../../services/gallery.ts";
import {
  createGalleryRequest,
  createGallerySubmission,
  listGalleryRequests,
  listGallerySubmissions,
  myGalleryItems,
  type SubmitEnv,
  setGalleryRequestStatus,
  voteGalleryRequest,
} from "../../services/gallery-community.ts";
import {
  decideGalleryApproval,
  galleryPolicyFor,
  installGalleryItem,
  installGallerySet,
  internalCaller,
  listGalleryApprovals,
  listGalleryInstalled,
  removeGalleryInstalled,
  requireMember,
  setGalleryPolicyFor,
  updateGalleryInstalled,
} from "../../services/gallery-install.ts";
import { galleryStats, recordGalleryUse, withStats } from "../../services/gallery-usage.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { instanceOwnerCheck } from "./admin.ts";

const claimsOf = (c: { get(k: "claims"): JwtClaims | undefined }) => {
  const claims = c.get("claims");
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

const ITEM_ID = /^([a-z0-9][a-z0-9-]{0,39}:)?[a-z0-9][a-z0-9-]{0,62}$/;

/** Looks marked used: 30 a minute per person is plenty for a real device. */
const USED_PER_MINUTE = 30;

export interface GalleryRouteOptions {
  /** Where gallery stats and GitHub are fetched from (tests). Default: fetch. */
  fetch?: typeof fetch;
}

export function registerGalleryRoutes(
  app: OpenAPIHono<AppEnv>,
  deps: AppDeps,
  opts: GalleryRouteOptions = {},
) {
  const { db, env } = deps;
  const fetchImpl = opts.fetch ?? fetch;
  const requireOwner = instanceOwnerCheck(deps);
  const call = (c: { req: { header(n: string): string | undefined } }) =>
    internalCaller(app, c.req.header("authorization") ?? "");
  const usedWindows = new Map<string, { start: number; count: number }>();
  setGalleryWarn((msg, extra) => deps.logger.warn(msg, extra));

  // Static paths first: /v1/gallery/{type}/{id} would otherwise match them.

  // No sign-in: aggregate numbers only, for the app, the web gallery and self-hosted servers.
  app.openapi(routes.getGalleryStats, async (c) => {
    c.header("Cache-Control", "public, max-age=600");
    c.header("Access-Control-Allow-Origin", "*");
    return c.json({ items: await galleryStats(db, env, fetchImpl) }, 200);
  });

  app.openapi(routes.listGallerySets, async (c) => {
    claimsOf(c);
    return c.json({ items: await gallerySets(env) }, 200);
  });

  app.openapi(routes.listGalleryAuthors, async (c) => {
    claimsOf(c);
    return c.json({ items: await galleryAuthors(env) }, 200);
  });

  app.openapi(routes.listGalleryInstalled, async (c) => {
    const claims = claimsOf(c);
    const { org_id } = c.req.valid("query");
    return c.json({ items: await listGalleryInstalled(deps, claims, org_id) }, 200);
  });

  app.openapi(routes.updateGalleryInstalled, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    const out = await updateGalleryInstalled(deps, call(c), claims, {
      orgId: b.org_id,
      type: b.type,
      id: b.id,
      acceptAccess: b.accept_access,
    });
    return c.json(out, 200);
  });

  app.openapi(routes.removeGalleryInstalled, async (c) => {
    const claims = claimsOf(c);
    const { type, id } = c.req.valid("param");
    const { org_id } = c.req.valid("query");
    await removeGalleryInstalled(deps, call(c), claims, { orgId: org_id, type, id });
    return c.body(null, 204);
  });

  app.openapi(routes.installGalleryItem, async (c) => {
    const claims = claimsOf(c);
    const b = c.req.valid("json");
    const out = await installGalleryItem(deps, call(c), claims, {
      orgId: b.org_id,
      type: b.type,
      id: b.id,
      inputs: b.inputs,
      botId: b.bot_id ?? null,
    });
    return c.json(out, out.status === "approval_pending" ? 202 : 201);
  });

  app.openapi(routes.installGallerySet, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    const out = await installGallerySet(deps, call(c), claims, {
      orgId: b.org_id,
      id,
      botId: b.bot_id ?? null,
    });
    return c.json(out, 200);
  });

  app.openapi(routes.getGalleryPolicy, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    await requireMember(db, claims, id);
    return c.json(await galleryPolicyFor(db, id), 200);
  });

  app.openapi(routes.setGalleryPolicy, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    return c.json(await setGalleryPolicyFor(deps, claims, id, c.req.valid("json")), 200);
  });

  app.openapi(routes.listGalleryApprovals, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { status } = c.req.valid("query");
    return c.json({ items: await listGalleryApprovals(deps, claims, id, status) }, 200);
  });

  app.openapi(routes.decideGalleryApproval, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    const { decision } = c.req.valid("json");
    return c.json(await decideGalleryApproval(deps, call(c), claims, id, decision), 200);
  });

  app.openapi(routes.listGalleryRequests, async (c) => {
    const claims = claimsOf(c);
    const q = c.req.valid("query");
    return c.json({ items: await listGalleryRequests(db, claims.sub, q) }, 200);
  });

  app.openapi(routes.createGalleryRequest, async (c) => {
    const claims = claimsOf(c);
    const out = await createGalleryRequest(db, claims.sub, c.req.valid("json"));
    return c.json(out.request, out.created ? 201 : 200);
  });

  app.openapi(routes.updateGalleryRequest, async (c) => {
    const claims = claimsOf(c);
    await requireOwner(claims);
    const { id } = c.req.valid("param");
    return c.json(await setGalleryRequestStatus(db, claims.sub, id, c.req.valid("json")), 200);
  });

  app.openapi(routes.voteGalleryRequest, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    return c.json(await voteGalleryRequest(db, claims.sub, id, true), 200);
  });

  app.openapi(routes.unvoteGalleryRequest, async (c) => {
    const claims = claimsOf(c);
    const { id } = c.req.valid("param");
    return c.json(await voteGalleryRequest(db, claims.sub, id, false), 200);
  });

  app.openapi(routes.createGallerySubmission, async (c) => {
    const claims = claimsOf(c);
    const out = await createGallerySubmission(
      db,
      env as SubmitEnv,
      claims,
      c.req.valid("json"),
      fetchImpl,
    );
    return c.json(out, 201);
  });

  app.openapi(routes.listGallerySubmissions, async (c) => {
    const claims = claimsOf(c);
    return c.json(
      { items: await listGallerySubmissions(db, env as SubmitEnv, claims.sub, fetchImpl) },
      200,
    );
  });

  app.openapi(routes.listMyGalleryItems, async (c) => {
    const claims = claimsOf(c);
    return c.json({ items: await myGalleryItems(db, env, claims.sub) }, 200);
  });

  app.openapi(routes.markGalleryItemUsed, async (c) => {
    const claims = claimsOf(c);
    const { type, id } = c.req.valid("param");
    if (!ITEM_ID.test(id)) throw new ApiError(400, "validation_failed", "Not a gallery item id");
    const now = Date.now();
    let w = usedWindows.get(claims.sub);
    if (!w || now - w.start >= 60_000) {
      w = { start: now, count: 0 };
      usedWindows.set(claims.sub, w);
      if (usedWindows.size > 50_000)
        for (const [k, v] of usedWindows) if (now - v.start >= 60_000) usedWindows.delete(k);
    }
    if (++w.count > USED_PER_MINUTE)
      throw new ApiError(429, "rate_limited", "Too many requests", {
        headers: { "retry-after": String(Math.ceil((w.start + 60_000 - now) / 1000)) },
      });
    await recordGalleryUse(db, env, claims.sub, type, id);
    return c.body(null, 204);
  });

  app.openapi(routes.listGallery, async (c) => {
    claimsOf(c);
    const listed = await galleryIndex(deps.env);
    if (!listed.enabled)
      throw new ApiError(404, "gallery_disabled", "The gallery is turned off on this server.");
    const { type, kinds, q, tag, featured } = c.req.valid("query");
    const query = q?.trim().toLowerCase();
    // kinds=all (D-315): every kind in one list. Without it, looks and skills as old apps expect.
    const NEWER = ["app", "bot", "routine", "plugin", "set"];
    const wantNewer = kinds === "all" || (type !== undefined && NEWER.includes(type));
    const newer = wantNewer
      ? (await galleryRecords(env, type && NEWER.includes(type) ? [type] : NEWER)).map(
          (r) =>
            ({
              tags: [],
              featured: false,
              retired: false,
              version: 1,
              sha256: "",
              files: [],
              license: "",
              ...r,
              author: (r.author as { name: string } | undefined) ?? { name: "Unknown" },
            }) as unknown as GalleryRecord,
        )
      : [];
    const all =
      kinds === "all" || !type || !NEWER.includes(type) ? [...listed.items, ...newer] : newer;
    const items = all.filter((item) => {
      if (item.retired) return false;
      if (type && item.type !== type) return false;
      if (tag && !item.tags.includes(tag)) return false;
      if (featured === "true" && !item.featured) return false;
      if (featured === "false" && item.featured) return false;
      if (!query) return true;
      const hay = [item.name, item.author.name, item.id, ...(item.tags ?? [])]
        .join(" ")
        .toLowerCase();
      return hay.includes(query);
    });
    const stats = await galleryStats(db, env, fetchImpl).catch(() => ({}));
    return c.json(
      { available: listed.available, items: withStats((i) => i.type, items, stats) },
      200,
    );
  });

  app.openapi(routes.getGalleryItem, async (c) => {
    claimsOf(c);
    const { type, id } = c.req.valid("param");
    if (!ITEM_ID.test(id))
      throw new ApiError(404, "gallery_not_found", "That gallery item isn't there.");
    if (!["theme", "scheme", "wallpaper", "skill"].includes(type)) {
      // The newer kinds (D-315): the record as its file has it.
      const rec = await galleryRecord(env, type, id);
      if (!rec) throw new ApiError(404, "gallery_not_found", "That gallery item isn't there.");
      return c.json(
        {
          tags: [],
          featured: false,
          retired: false,
          version: 1,
          sha256: "",
          files: [],
          license: "",
          ...rec,
          type: type as "app",
          author: (rec.author as { name: string } | undefined) ?? { name: "Unknown" },
          document: (rec.document as Record<string, unknown> | undefined) ?? null,
          skill_md: null,
        } as never,
        200,
      );
    }
    const found = await galleryItem(deps.env, type as "skill", id);
    return c.json(
      {
        ...found.item,
        document: found.document,
        skill_md: found.skillMd,
      },
      200,
    );
  });
}
