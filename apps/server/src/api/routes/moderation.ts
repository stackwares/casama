/**
 * Reporting and blocking (D-301), and account email preferences (D-302).
 *
 * The App Store (Guideline 1.2) and Google Play require apps with other people's content to let
 * people report it and block whoever posted it, and to act on reports. Public pages and chats have
 * their own report form (D-281, D-282); this covers what people meet inside the app: gallery items,
 * bots shared with them, other people's messages, people and workspaces. Each report reaches the
 * instance owners' queue (Admin console > Reports) and ABUSE_INBOX by email.
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import { routes } from "@casama/contracts";
import { type JwtClaims, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import { maskEmail } from "../../billing/comps.ts";
import { suspendOrg } from "../../services/abuse.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { instanceOwnerCheck } from "./admin.ts";

/** Reports a person may file in a day: enough for real use, not enough to flood the queue. */
export const REPORTS_PER_DAY = 20;

const requireClaims = (claims: JwtClaims | undefined): JwtClaims => {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

/** The unsubscribe token: the user id and an HMAC of it, so a link works without signing in. */
export function unsubscribeToken(secret: string, userId: string): string {
  const mac = createHmac("sha256", secret).update(`unsubscribe:${userId}`).digest("base64url");
  return `${userId}.${mac.slice(0, 32)}`;
}

export function userFromUnsubscribeToken(secret: string, token: string): string | null {
  const [userId, mac] = token.split(".");
  if (!userId || !mac || !/^[0-9a-f-]{36}$/i.test(userId)) return null;
  const want = unsubscribeToken(secret, userId).split(".")[1] ?? "";
  const a = Buffer.from(mac);
  const b = Buffer.from(want);
  return a.length === b.length && timingSafeEqual(a, b) ? userId : null;
}

/** The secret behind unsubscribe links: the JWT secret, so nothing new has to be configured. */
export const emailLinkSecret = (env: AppDeps["env"]) => `email-links:${env.SUPABASE_JWT_SECRET}`;

type ReportRow = {
  id: string;
  target_kind: string;
  target_id: string;
  target_org_id: string | null;
  target_org_name: string | null;
  reason: string;
  note: string | null;
  snapshot: string | null;
  reporter_email: string | null;
  same_target: number;
  status: string;
  created_at: Date;
};

/**
 * Kinds and reasons older apps know (D-315): a gallery request shows as the gallery item
 * `request/<id>`, and the nightly check's `health:<check>` as `other` with the check in the note.
 */
const reportOut = (r: ReportRow) => ({
  ...r,
  target_kind: (r.target_kind === "gallery_request" || r.target_kind === "pack_share"
    ? "gallery_item"
    : r.target_kind) as "gallery_item" | "bot" | "message" | "user" | "workspace",
  target_id:
    r.target_kind === "gallery_request"
      ? `request/${r.target_id}`
      : r.target_kind === "pack_share"
        ? `pack_share/${r.target_id}`
        : r.target_id,
  note: r.reason.startsWith("health:") ? `${r.reason}${r.note ? `: ${r.note}` : ""}` : r.note,
  reason: (r.reason.startsWith("health:") ? "other" : r.reason) as
    | "spam"
    | "sexual"
    | "violence"
    | "harassment"
    | "illegal"
    | "impersonation"
    | "other",
  status: r.status as "open" | "actioned" | "dismissed",
  same_target: Number(r.same_target),
  created_at: new Date(r.created_at).toISOString(),
});

/** Plain text of a message's parts, for the reviewer's copy. */
function messageText(content: unknown): string {
  if (!Array.isArray(content)) return "";
  return content
    .map((p) =>
      p && typeof p === "object" && "text" in p ? String((p as { text: unknown }).text ?? "") : "",
    )
    .filter(Boolean)
    .join("\n");
}

export function registerModerationRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db, env } = deps;
  const requireOwner = instanceOwnerCheck(deps);

  /**
   * What a report points at, checked against what the reporter can see: a message in a chat
   * they're in, a bot in one of their workspaces, a person who shares a workspace with them. A
   * gallery item is public. Returns the content's workspace and a short copy for the reviewer.
   */
  const resolveTarget = async (
    claims: JwtClaims,
    kind: string,
    id: string,
  ): Promise<{ orgId: string | null; snapshot: string }> => {
    const uuid = /^[0-9a-f-]{36}$/i.test(id);
    const visible = async (orgId: string) => {
      const [r] = await withUserSession(db, claims, (tx) =>
        tx.execute<{ ok: boolean }>(sql`select public.has_role(${orgId}::uuid, 'member') as ok`),
      );
      return !!r?.ok;
    };
    if (kind === "gallery_item") return { orgId: null, snapshot: `Gallery item ${id}` };
    if (kind === "gallery_request") {
      if (!uuid) throw new ApiError(404, "not_found", "Not found");
      const [q] = await db.execute<{ title: string; details: string }>(sql`
        select title, details from public.gallery_requests where id = ${id}::uuid and not hidden`);
      if (!q) throw new ApiError(404, "not_found", "Not found");
      return {
        orgId: null,
        snapshot: `Gallery request: ${q.title}${q.details ? `\n${q.details}` : ""}`.slice(0, 4000),
      };
    }
    if (!uuid) throw new ApiError(404, "not_found", "Not found");
    if (kind === "pack_share") {
      // Anyone with the link sees a shared pack; its id comes with the link's preview.
      const [s] = await db.execute<{ org_id: string; name: string; summary: string }>(sql`
        select org_id, name, summary from public.pack_shares
        where id = ${id}::uuid and taken_down_at is null and expires_at > now()`);
      if (!s) throw new ApiError(404, "not_found", "Not found");
      return {
        orgId: s.org_id,
        snapshot: `Shared pack ${s.name}${s.summary ? `: ${s.summary}` : ""}`.slice(0, 4000),
      };
    }
    if (kind === "message") {
      const [m] = await db.execute<{
        org_id: string;
        content: unknown;
        author: string | null;
        name: string | null;
      }>(sql`
        select m.org_id, m.content, m.author_user_id as author, p.display_name as name
        from public.messages m left join public.profiles p on p.user_id = m.author_user_id
        where m.id = ${id}::uuid`);
      if (!m || !(await visible(m.org_id))) throw new ApiError(404, "not_found", "Not found");
      return {
        orgId: m.org_id,
        snapshot: `${m.name ?? m.author ?? "Someone"}: ${messageText(m.content)}`.slice(0, 4000),
      };
    }
    if (kind === "bot") {
      const [b] = await db.execute<{
        org_id: string;
        name: string;
        description: string | null;
      }>(sql`
        select org_id, name, description from public.bots where id = ${id}::uuid`);
      if (!b || !(await visible(b.org_id))) throw new ApiError(404, "not_found", "Not found");
      return {
        orgId: b.org_id,
        snapshot: `${b.name}${b.description ? ` - ${b.description}` : ""}`.slice(0, 4000),
      };
    }
    if (kind === "workspace") {
      const [o] = await db.execute<{ name: string }>(
        sql`select name from public.organizations where id = ${id}::uuid`,
      );
      if (!o || !(await visible(id))) throw new ApiError(404, "not_found", "Not found");
      return { orgId: id, snapshot: `Workspace ${o.name}` };
    }
    // A person: someone who shares a workspace with the reporter, or invited them to one.
    const [p] = await db.execute<{ name: string | null; email: string | null }>(sql`
      select p.display_name as name, u.email from auth.users u left join public.profiles p on p.user_id = u.id
      where u.id = ${id}::uuid and (
        exists (select 1 from public.memberships a join public.memberships b on a.org_id = b.org_id
                where a.user_id = ${claims.sub}::uuid and b.user_id = u.id)
        or exists (select 1 from public.invites i join auth.users me on lower(me.email) = lower(i.email)
                   where me.id = ${claims.sub}::uuid and i.invited_by = u.id))`);
    if (!p) throw new ApiError(404, "not_found", "Not found");
    return {
      orgId: null,
      snapshot: `Person ${p.name ?? ""} <${p.email ?? "no email"}>`.slice(0, 4000),
    };
  };

  const reportRows = (where: ReturnType<typeof sql>) =>
    db.execute<ReportRow>(sql`
      select r.id, r.target_kind, r.target_id, r.target_org_id, o.name as target_org_name, r.reason, r.note,
             r.snapshot, u.email as reporter_email, r.status, r.created_at,
             (select count(*)::int from public.content_reports x
              where x.target_kind = r.target_kind and x.target_id = r.target_id and x.status = 'open') as same_target
      from public.content_reports r
      left join public.organizations o on o.id = r.target_org_id
      left join auth.users u on u.id = r.reporter_id
      ${where}`);

  app.openapi(routes.createReport, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const [today] = await db.execute<{ n: number }>(sql`
      select count(*)::int as n from public.content_reports
      where reporter_id = ${claims.sub}::uuid and created_at > now() - interval '1 day'`);
    if ((today?.n ?? 0) >= REPORTS_PER_DAY)
      throw new ApiError(
        429,
        "report_limit",
        "You've sent a lot of reports today. We'll review those first.",
      );
    const target = await resolveTarget(claims, body.target_kind, body.target_id);
    // Reporting the same thing twice while it's open keeps the first report (and its note).
    const [row] = await db.execute<{ id: string; created: boolean }>(sql`
      insert into public.content_reports (reporter_id, target_kind, target_id, target_org_id, reason, note, snapshot)
      values (${claims.sub}::uuid, ${body.target_kind}, ${body.target_id}, ${target.orgId}::uuid, ${body.reason},
              ${body.note?.trim() || null}, ${target.snapshot})
      on conflict (reporter_id, target_kind, target_id) where status = 'open'
      do update set note = coalesce(excluded.note, public.content_reports.note)
      returning id, (xmax = 0) as created`);
    if (!row) throw new ApiError(500, "report_failed", "The report couldn't be saved");
    if (row.created && deps.email.enabled) {
      const [r] = await reportRows(sql`where r.id = ${row.id}::uuid`);
      void deps.email
        .send({
          to: env.ABUSE_INBOX,
          subject: `[report] ${body.target_kind} · ${body.reason}${r && r.same_target >= 3 ? ` · ${r.same_target} open reports` : ""}`,
          text: [
            `Reason: ${body.reason}`,
            body.note ? `Note: ${body.note}` : "",
            `What: ${body.target_kind} ${body.target_id}`,
            r?.target_org_name ? `Workspace: ${r.target_org_name} (${target.orgId})` : "",
            `Open reports about it: ${r?.same_target ?? 1}`,
            `Reporter: ${r?.reporter_email ?? claims.sub}`,
            "",
            `What they saw:\n${target.snapshot}`,
            "",
            "Review it in the app: Settings > Admin console > Reports.",
          ]
            .filter((l) => l !== "")
            .join("\n"),
        })
        .catch((err) => deps.logger.warn("report email failed", { error: String(err) }));
    }
    // Reporting a person also blocks them, as people expect from "Report and block".
    if (body.target_kind === "user" && body.target_id !== claims.sub)
      await db.execute(sql`
        insert into public.user_blocks (blocker_id, blocked_id) values (${claims.sub}::uuid, ${body.target_id}::uuid)
        on conflict do nothing`);
    return c.json({ id: row.id }, 200);
  });

  const blockRows = (userId: string, only?: string) =>
    db.execute<{
      user_id: string;
      name: string | null;
      email: string | null;
      blocked_at: Date;
    }>(sql`
      select b.blocked_id as user_id, p.display_name as name, u.email, b.created_at as blocked_at
      from public.user_blocks b left join public.profiles p on p.user_id = b.blocked_id
      left join auth.users u on u.id = b.blocked_id
      where b.blocker_id = ${userId}::uuid ${only ? sql`and b.blocked_id = ${only}::uuid` : sql``}
      order by b.created_at desc`);
  const blockOut = (b: Awaited<ReturnType<typeof blockRows>>[number]) => ({
    user_id: b.user_id,
    // Blocking needs only a user id, not a shared workspace: a full email here would let anyone
    // holding an id read that person's address.
    name: b.name || maskEmail(b.email) || "Someone",
    blocked_at: new Date(b.blocked_at).toISOString(),
  });

  app.openapi(routes.listBlocks, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json({ items: (await blockRows(claims.sub)).map(blockOut) }, 200);
  });

  app.openapi(routes.blockPerson, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { user_id } = c.req.valid("json");
    if (user_id === claims.sub)
      throw new ApiError(400, "validation_failed", "You can't block yourself");
    const [exists] = await db.execute<{ id: string }>(
      sql`select id from auth.users where id = ${user_id}::uuid`,
    );
    if (!exists) throw new ApiError(404, "not_found", "Not found");
    await db.execute(sql`
      insert into public.user_blocks (blocker_id, blocked_id) values (${claims.sub}::uuid, ${user_id}::uuid)
      on conflict do nothing`);
    // Their pending invites to this person go away.
    await db.execute(sql`
      delete from public.invites i using auth.users me
      where me.id = ${claims.sub}::uuid and lower(i.email) = lower(me.email) and i.invited_by = ${user_id}::uuid
        and i.accepted_at is null`);
    const [b] = await blockRows(claims.sub, user_id);
    return c.json(blockOut(b as NonNullable<typeof b>), 200);
  });

  app.openapi(routes.unblockPerson, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { user_id } = c.req.valid("param");
    await db.execute(sql`
      delete from public.user_blocks where blocker_id = ${claims.sub}::uuid and blocked_id = ${user_id}::uuid`);
    return c.body(null, 204);
  });

  app.openapi(routes.listContentReports, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const status = c.req.valid("query").status ?? "open";
    const rows = await reportRows(
      status === "all"
        ? sql`order by (r.status = 'open') desc, r.created_at desc limit 300`
        : sql`where r.status = ${status} order by r.created_at desc limit 300`,
    );
    return c.json({ items: rows.map(reportOut) }, 200);
  });

  app.openapi(routes.reviewContentReport, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const [r] = await db.execute<{
      target_kind: string;
      target_id: string;
      target_org_id: string | null;
    }>(sql`
      select target_kind, target_id, target_org_id from public.content_reports where id = ${id}::uuid`);
    if (!r) throw new ApiError(404, "report_not_found", "Report not found");
    // A decision closes every open report about the same thing.
    await db.execute(sql`
      update public.content_reports set status = ${body.decision}, reviewed_by = ${claims.sub}::uuid, reviewed_at = now()
      where status = 'open' and target_kind = ${r.target_kind} and target_id = ${r.target_id}`);
    await db.execute(sql`
      update public.content_reports set status = ${body.decision}, reviewed_by = ${claims.sub}::uuid,
        reviewed_at = coalesce(reviewed_at, now())
      where id = ${id}::uuid`);
    // A request on the gallery's board that broke the rules comes off the board (D-315).
    if (body.decision === "actioned" && r.target_kind === "gallery_request")
      await db.execute(
        sql`update public.gallery_requests set hidden = true where id = ${r.target_id}::uuid`,
      );
    // A shared pack that broke the rules stops working (its link answers 404).
    if (body.decision === "actioned" && r.target_kind === "pack_share")
      await db.execute(
        sql`update public.pack_shares set taken_down_at = now() where id = ${r.target_id}::uuid`,
      );
    if (body.decision === "actioned" && body.suspend_workspace && r.target_org_id)
      await suspendOrg(
        { db, stopComputer: deps.computers ? (cid) => deps.computers!.sleep(cid) : undefined },
        r.target_org_id,
        `Report ${id}: ${r.target_kind}`,
        { kind: "user", id: claims.sub },
      );
    const [out] = await reportRows(sql`where r.id = ${id}::uuid`);
    return c.json(reportOut(out as ReportRow), 200);
  });

  const prefs = async (userId: string) => {
    const [p] = await db.execute<{ tips: boolean; gallery_digest: boolean }>(sql`
      select email_tips as tips, gallery_digest from public.profiles where user_id = ${userId}::uuid`);
    return { tips: p?.tips ?? true, gallery_digest: p?.gallery_digest ?? false };
  };

  app.openapi(routes.getEmailPreferences, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(await prefs(claims.sub), 200);
  });

  app.openapi(routes.setEmailPreferences, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { tips, gallery_digest } = c.req.valid("json");
    await db.execute(sql`
      update public.profiles set email_tips = ${tips},
        gallery_digest = coalesce(${gallery_digest ?? null}::boolean, gallery_digest)
      where user_id = ${claims.sub}::uuid`);
    return c.json(await prefs(claims.sub), 200);
  });

  // Unsubscribe from a link in an email (D-302): no sign-in, the token is signed. GET shows a
  // button (link scanners in mail systems follow links, so a visit alone changes nothing); POST
  // turns tips and news off, and is also what mail apps send for one-click unsubscribe (RFC 8058).
  const page = (body: string) =>
    `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>Casama emails</title><div style="font:16px/1.5 system-ui,sans-serif;max-width:420px;margin:15vh auto;padding:0 24px;color:#2A1035">${body}</div>`;
  // ?list=gallery: the monthly gallery picks (D-315) instead of tips and news.
  app.get("/v1/email/unsubscribe/:token", (c) => {
    const gallery = c.req.query("list") === "gallery";
    if (gallery && userFromUnsubscribeToken(emailLinkSecret(env), c.req.param("token")))
      return c.html(
        page(
          `<h1>Stop monthly gallery picks?</h1><p>You'll still get emails about your account, plan and purchases.</p><form method="post"><button style="font:inherit;padding:12px 24px;border-radius:999px;border:0;background:#7A3FA8;color:#fff;cursor:pointer">Unsubscribe</button></form>`,
        ),
      );
    if (!userFromUnsubscribeToken(emailLinkSecret(env), c.req.param("token")))
      return c.html(
        page(
          "<h1>This link isn't valid</h1><p>Turn emails off in the app: Settings &gt; Notifications.</p>",
        ),
        400,
      );
    return c.html(
      page(
        `<h1>Stop tips and news emails?</h1><p>You'll still get emails about your account, plan and purchases.</p><form method="post"><button style="font:inherit;padding:12px 24px;border-radius:999px;border:0;background:#7A3FA8;color:#fff;cursor:pointer">Unsubscribe</button></form>`,
      ),
    );
  });
  app.post("/v1/email/unsubscribe/:token", async (c) => {
    const userId = userFromUnsubscribeToken(emailLinkSecret(env), c.req.param("token"));
    if (!userId) return c.html(page("<h1>This link isn't valid</h1>"), 400);
    if (c.req.query("list") === "gallery") {
      await db.execute(
        sql`update public.profiles set gallery_digest = false where user_id = ${userId}::uuid`,
      );
      return c.html(
        page(
          "<h1>You're unsubscribed</h1><p>No more monthly gallery picks. Turn them back on any time in Settings &gt; Notifications.</p>",
        ),
      );
    }
    await db.execute(
      sql`update public.profiles set email_tips = false where user_id = ${userId}::uuid`,
    );
    return c.html(
      page(
        "<h1>You're unsubscribed</h1><p>No more tips and news emails. Turn them back on any time in Settings &gt; Notifications.</p>",
      ),
    );
  });
}
