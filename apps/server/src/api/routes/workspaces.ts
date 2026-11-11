import { randomBytes } from "node:crypto";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { routes } from "@kasama/contracts";
import { type JwtClaims, pgErrorCode, pgErrorMessage, schema, withUserSession } from "@kasama/db";
import { withSpan } from "@kasama/observability";
import { eq, sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso, randomSuffix, sha256Hex, slugify } from "../util.ts";
import { createEmailInvite } from "./joining.ts";

const { organizations, memberships, profiles } = schema;

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

const orgOut = (o: {
  id: string;
  name: string;
  slug: string;
  plan: string;
  region: string;
  icon?: string | null;
  color?: string | null;
  createdAt: string | Date;
}) => ({
  id: o.id,
  name: o.name,
  slug: o.slug,
  plan: o.plan,
  region: o.region,
  icon: o.icon ?? null,
  color: o.color ?? null,
  created_at: iso(o.createdAt),
});

export function registerWorkspaceRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;

  const listMyOrgs = (claims: JwtClaims) =>
    withUserSession(db, claims, (tx) =>
      tx
        .select({ org: organizations, role: memberships.role })
        .from(memberships)
        .innerJoin(organizations, eq(organizations.id, memberships.orgId))
        .where(eq(memberships.userId, claims.sub))
        .orderBy(organizations.createdAt),
    ).then((rows) =>
      rows.map((r) => ({
        ...orgOut(r.org),
        role: r.role,
        require_mfa: r.org.requireMfa,
        suspended: r.org.suspendedAt != null,
      })),
    );

  app.openapi(routes.getMe, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const [profile] = await withUserSession(db, claims, (tx) =>
      tx.select().from(profiles).where(eq(profiles.userId, claims.sub)),
    );
    return c.json(
      {
        user_id: claims.sub,
        email: typeof claims.email === "string" ? claims.email : null,
        display_name: profile?.displayName ?? null,
        locale: profile?.locale ?? "en",
        timezone: profile?.timezone ?? "UTC",
        organizations: await listMyOrgs(claims),
      },
      200,
    );
  });

  app.openapi(routes.listOrgs, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json({ items: await listMyOrgs(claims) }, 200);
  });

  app.openapi(routes.createOrg, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    return withSpan("orgs.create", {}, async () => {
      const base = body.slug ?? slugify(body.name);
      for (let attempt = 0; attempt < 5; attempt++) {
        const slug = attempt === 0 ? base : `${base.slice(0, 40)}-${randomSuffix()}`;
        try {
          const [row] = await withUserSession(db, claims, (tx) =>
            tx.execute<{
              id: string;
              name: string;
              slug: string;
              plan: string;
              region: string;
              created_at: Date;
            }>(
              sql`select id, name, slug, plan, region, created_at from public.create_organization(${body.name}, ${slug})`,
            ),
          );
          if (!row) throw new Error("create_organization returned nothing");
          // Kasama Cloud: new workspaces start on the free plan with its included credits.
          if (deps.billing?.enabled) row.plan = (await deps.billing.recompute(row.id)).planCode;
          return c.json(orgOut({ ...row, createdAt: row.created_at }), 201);
        } catch (err) {
          if (pgErrorCode(err) !== "23505") throw err;
          if (body.slug) throw new ApiError(409, "slug_taken", `The slug "${body.slug}" is taken`);
        }
      }
      throw new ApiError(409, "slug_taken", "Could not find a free slug; pass one explicitly");
    });
  });

  app.openapi(routes.createInvite, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id: orgId } = c.req.valid("param");
    const body = c.req.valid("json");
    const [org] = await withUserSession(db, claims, (tx) =>
      tx.select().from(organizations).where(eq(organizations.id, orgId)),
    );
    if (!org) throw new ApiError(404, "org_not_found", "Organization not found");
    const [{ allowed } = { allowed: false }] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ allowed: boolean }>(
        sql`select public.has_role(${orgId}::uuid, 'admin') as allowed`,
      ),
    );
    if (!allowed) throw new ApiError(403, "forbidden", "Only owners and admins can invite");
    return c.json(
      await createEmailInvite(deps, claims, orgId, body.email.toLowerCase(), body.role ?? "member"),
      201,
    );
  });

  // --- spaces (D-099): look, invite links, badges ---------------------------------

  type LinkRow = {
    id: string;
    org_id: string;
    role: "admin" | "member";
    token_hint: string;
    expires_at: Date | null;
    max_uses: number | null;
    uses: number;
    revoked_at: Date | null;
    created_at: Date;
    kind: "link" | "code";
    requires_approval: boolean;
    is_default: boolean;
  };
  const linkOut = (l: LinkRow) => ({
    ...l,
    expires_at: l.expires_at ? iso(l.expires_at) : null,
    revoked_at: l.revoked_at ? iso(l.revoked_at) : null,
    created_at: iso(l.created_at),
  });
  const requireAdmin = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.has_role(${orgId}::uuid, 'admin') as ok`),
    );
    if (!r?.ok)
      throw new ApiError(403, "forbidden", "Only owners and admins can change this workspace");
  };

  app.openapi(routes.updateOrg, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    await requireAdmin(claims, id);
    const [row] = await withUserSession(db, claims, (tx) =>
      tx
        .update(organizations)
        .set({
          ...(b.name !== undefined ? { name: b.name } : {}),
          ...(b.icon !== undefined ? { icon: b.icon } : {}),
          ...(b.color !== undefined ? { color: b.color } : {}),
        })
        .where(eq(organizations.id, id))
        .returning(),
    );
    if (!row) throw new ApiError(404, "org_not_found", "Workspace not found");
    return c.json(orgOut(row), 200);
  });

  app.openapi(routes.listInviteLinks, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await requireAdmin(claims, id);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<LinkRow>(sql`
        select id, org_id, role, token_hint, expires_at, max_uses, uses, revoked_at, created_at, kind, requires_approval, is_default
        from public.invite_links where org_id = ${id}::uuid order by created_at desc`),
    );
    return c.json({ items: rows.map(linkOut) }, 200);
  });

  app.openapi(routes.createInviteLink, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    await requireAdmin(claims, id);
    const token = `kjoin_${randomBytes(24).toString("base64url")}`;
    const expires = b.expires_in_days
      ? new Date(Date.now() + b.expires_in_days * 86_400_000)
      : null;
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<LinkRow>(sql`
        insert into public.invite_links (org_id, role, token_hash, token_hint, expires_at, max_uses, created_by, requires_approval)
        values (${id}::uuid, ${b.role ?? "member"}, ${sha256Hex(token)}, ${token.slice(0, 10)}, ${expires?.toISOString() ?? null}::timestamptz,
                ${b.max_uses ?? null}, ${claims.sub}::uuid, ${b.requires_approval ?? false})
        returning id, org_id, role, token_hint, expires_at, max_uses, uses, revoked_at, created_at, kind, requires_approval, is_default`),
    );
    if (!row) throw new Error("invite link insert returned nothing");
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${id}::uuid, 'user', ${claims.sub}::uuid, 'invite_link.created', 'invite_link', ${row.id}::uuid, ${JSON.stringify({ role: row.role })}::jsonb)`);
    const url = `${deps.env.PUBLIC_APP_URL.replace(/\/$/, "")}/join/${token}`;
    return c.json({ ...linkOut(row), token, url }, 201);
  });

  app.openapi(routes.revokeInviteLink, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, link_id } = c.req.valid("param");
    await requireAdmin(claims, id);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string }>(sql`
        update public.invite_links set revoked_at = coalesce(revoked_at, now())
        where id = ${link_id}::uuid and org_id = ${id}::uuid returning id`),
    );
    if (!rows.length) throw new ApiError(404, "link_not_found", "Invite link not found");
    return c.body(null, 204);
  });

  app.openapi(routes.acceptInviteLink, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { token } = c.req.valid("param");
    let orgId: string;
    try {
      const [m] = await withUserSession(db, claims, (tx) =>
        tx.execute<{ org_id: string; status: string }>(
          sql`select org_id, status from public.use_invite_link(${sha256Hex(token)})`,
        ),
      );
      if (!m) throw new Error("use_invite_link returned nothing");
      // Links that ask an admin first go through POST /v1/join, which files the request (D-167).
      if (m.status === "requested")
        throw new ApiError(
          403,
          "join_requested",
          "An admin needs to approve you; use POST /v1/join",
        );
      orgId = m.org_id;
    } catch (err) {
      if (pgErrorCode(err) === "P0002")
        throw new ApiError(
          404,
          "invite_invalid",
          "This invite link is invalid, used up, revoked or expired",
        );
      throw err;
    }
    const org = (await listMyOrgs(claims)).find((o) => o.id === orgId);
    if (!org) throw new ApiError(404, "org_not_found", "Workspace not found");
    return c.json(org, 200);
  });

  app.openapi(routes.workspaceBadges, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ org_id: string; approvals: number; unread: number }>(sql`
        select m.org_id,
          (select count(*)::int from public.approvals a where a.org_id = m.org_id and a.status = 'pending') as approvals,
          (select count(*)::int from public.notifications n
             where n.org_id = m.org_id and n.user_id = ${claims.sub}::uuid and n.read_at is null) as unread
        from public.memberships m where m.user_id = ${claims.sub}::uuid`),
    );
    return c.json({ items: rows }, 200);
  });

  app.openapi(routes.acceptInvite, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { token } = c.req.valid("param");
    try {
      const [m] = await withUserSession(db, claims, (tx) =>
        tx.execute<{
          id: string;
          org_id: string;
          user_id: string;
          role: "owner" | "admin" | "member";
          created_at: Date;
        }>(
          sql`select id, org_id, user_id, role, created_at from public.accept_invite(${sha256Hex(token)})`,
        ),
      );
      if (!m) throw new Error("accept_invite returned nothing");
      return c.json({ ...m, created_at: iso(m.created_at) }, 200);
    } catch (err) {
      const code = pgErrorCode(err);
      const msg = pgErrorMessage(err);
      if (code === "P0002")
        throw new ApiError(404, "invite_invalid", "This invite is invalid, used or expired");
      if (code === "42501" && msg === "invite_email_mismatch")
        throw new ApiError(
          403,
          "invite_email_mismatch",
          "This invite was sent to a different email address",
        );
      throw err;
    }
  });
}
