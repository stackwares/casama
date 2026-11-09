import type { OpenAPIHono } from "@hono/zod-openapi";
import { PRODUCT_NAME, routes } from "@kasama/contracts";
import { type JwtClaims, pgErrorCode, pgErrorMessage, schema, withUserSession } from "@kasama/db";
import { withSpan } from "@kasama/observability";
import { eq, sql } from "drizzle-orm";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso, newToken, randomSuffix, sha256Hex, slugify } from "../util.ts";

const { organizations, memberships, profiles, invites } = schema;

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
  createdAt: string | Date;
}) => ({
  id: o.id,
  name: o.name,
  slug: o.slug,
  plan: o.plan,
  region: o.region,
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
    ).then((rows) => rows.map((r) => ({ ...orgOut(r.org), role: r.role })));

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
    const role = body.role ?? "member";
    const token = newToken();

    const result = await withUserSession(db, claims, async (tx) => {
      const [org] = await tx.select().from(organizations).where(eq(organizations.id, orgId));
      if (!org) throw new ApiError(404, "org_not_found", "Organization not found");
      const [{ allowed } = { allowed: false }] = await tx.execute<{ allowed: boolean }>(
        sql`select public.has_role(${orgId}::uuid, 'admin') as allowed`,
      );
      if (!allowed) throw new ApiError(403, "forbidden", "Only owners and admins can invite");
      const [invite] = await tx
        .insert(invites)
        .values({
          orgId,
          email: body.email.toLowerCase(),
          role,
          tokenHash: sha256Hex(token),
          invitedBy: claims.sub,
        })
        .returning();
      if (!invite) throw new Error("invite insert returned nothing");
      return { org, invite };
    });

    let emailSent = false;
    if (deps.email.enabled) {
      const link = `${deps.env.PUBLIC_APP_URL}/invites/${token}`;
      try {
        await deps.email.send({
          to: result.invite.email,
          subject: `You're invited to ${result.org.name} on ${PRODUCT_NAME}`,
          text: `You've been invited to join ${result.org.name} on ${PRODUCT_NAME}.\n\nAccept: ${link}\n\nThis link expires in 7 days.`,
        });
        emailSent = true;
      } catch (err) {
        deps.logger.warn("invite email failed", { org_id: orgId, error: (err as Error).message });
      }
    }

    return c.json(
      {
        id: result.invite.id,
        org_id: result.invite.orgId,
        email: result.invite.email,
        role: result.invite.role,
        expires_at: iso(result.invite.expiresAt),
        email_sent: emailSent,
        ...(emailSent ? {} : { accept_token: token }),
      },
      201,
    );
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
