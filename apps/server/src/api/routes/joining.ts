/**
 * Joining a workspace (D-167): the standing invite link, short invite codes, a public preview of
 * an invite, one join endpoint for every kind of invite, requests that wait for an admin, email
 * invites (batch, resend, revoke), joining by a verified email domain, and the web pieces that
 * make links open the app (the join landing page and the app-link association files).
 */
import { randomBytes, randomInt } from "node:crypto";
import { milestone, track } from "@casama/agent";
import { PRODUCT_NAME, routes } from "@casama/contracts";
import {
  contentKeys,
  type JwtClaims,
  pgErrorCode,
  pgErrorMessage,
  withUserSession,
} from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import {
  type BrandedEmail,
  renderEmailHtml,
  renderEmailText,
} from "../../services/email-layout.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso, newToken, sha256Hex } from "../util.ts";

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

// --- parsing invites ---------------------------------------------------------------

/** Crockford base32: no I, L, O or U, so codes read out loud aren't misheard. */
const CODE_ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
const CODE_LENGTH = 8;
export const CODE_TTL_HOURS = 48;

export type ParsedInvite =
  | { kind: "link"; token: string }
  | { kind: "email"; token: string }
  | { kind: "code"; token: string };

/** A new invite code, shown as XXXX-XXXX. */
export function newInviteCode() {
  let s = "";
  for (let i = 0; i < CODE_LENGTH; i++) s += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
  return s;
}
export const formatCode = (code: string) => `${code.slice(0, 4)}-${code.slice(4)}`;

/** A code as typed ("7f3q 9xwd", "7F3Q-9XWD", with O for 0 or L for 1) in its stored form. */
export function normalizeCode(input: string): string | null {
  const s = input
    .toUpperCase()
    .replace(/[^0-9A-Z]/g, "")
    .replace(/O/g, "0")
    .replace(/[IL]/g, "1")
    .replace(/U/g, "V");
  if (s.length !== CODE_LENGTH) return null;
  for (const ch of s) if (!CODE_ALPHABET.includes(ch)) return null;
  return s;
}

/** Whatever was pasted or opened: a link, a bare token, an email invite token or a code. */
export function parseInvite(input: string): ParsedInvite | null {
  const raw = input.trim();
  const link = /(kjoin_[A-Za-z0-9_-]{16,})/.exec(raw);
  if (link?.[1]) return { kind: "link", token: link[1] };
  const email = /(kinv_[A-Za-z0-9_-]{16,})/.exec(raw);
  if (email?.[1]) return { kind: "email", token: email[1] };
  // A code, or a link to one (…/join/7F3Q-9XWD).
  const last =
    raw
      .replace(/[?#].*$/, "")
      .replace(/\/+$/, "")
      .split("/")
      .pop() ?? raw;
  const code = normalizeCode(last);
  return code ? { kind: "code", token: code } : null;
}

/** a•••@example.com */
export function maskEmail(email: string) {
  const [local = "", domain = ""] = email.split("@");
  return `${local.slice(0, 1)}•••@${domain}`;
}

// --- guessing limits ---------------------------------------------------------------

/**
 * Wrong invites per person (or address when signed out): codes are short, so guessing is capped at
 * 10 misses per 10 minutes. In memory, like the request rate limit.
 */
export function failureLimiter(opts: { max?: number; windowMs?: number; now?: () => number } = {}) {
  const max = opts.max ?? 10;
  const windowMs = opts.windowMs ?? 10 * 60_000;
  const now = opts.now ?? Date.now;
  const misses = new Map<string, { start: number; count: number }>();
  const current = (key: string) => {
    const t = now();
    const w = misses.get(key);
    if (!w || t - w.start >= windowMs) return null;
    return w;
  };
  return {
    check(key: string) {
      const w = current(key);
      if (w && w.count >= max) {
        const retry = Math.max(1, Math.ceil((w.start + windowMs - now()) / 1000));
        throw new ApiError(429, "too_many_attempts", "Too many wrong invites. Try again later.", {
          headers: { "retry-after": String(retry) },
        });
      }
    },
    miss(key: string) {
      const w = current(key) ?? { start: now(), count: 0 };
      w.count++;
      misses.set(key, w);
      if (misses.size > 50_000)
        for (const [k, v] of misses) if (now() - v.start >= windowMs) misses.delete(k);
    },
  };
}

// --- shared helpers ----------------------------------------------------------------

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
const LINK_COLUMNS = sql.raw(
  "id, org_id, role, token_hint, expires_at, max_uses, uses, revoked_at, created_at, kind, requires_approval, is_default",
);
export const linkOut = (l: LinkRow) => ({
  ...l,
  expires_at: l.expires_at ? iso(l.expires_at) : null,
  revoked_at: l.revoked_at ? iso(l.revoked_at) : null,
  created_at: iso(l.created_at),
});

type InviteRow = {
  id: string;
  org_id: string;
  email: string;
  role: "owner" | "admin" | "member";
  expires_at: Date;
  created_at: Date;
};

export function registerJoiningRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const limiter = failureLimiter();
  const appUrl = () => deps.env.PUBLIC_APP_URL.replace(/\/$/, "");
  const joinUrl = (token: string) => `${appUrl()}/join/${token}`;

  const requireAdmin = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.has_role(${orgId}::uuid, 'admin') as ok`),
    );
    if (!r?.ok) throw new ApiError(403, "forbidden", "Only owners and admins can invite people");
  };

  const orgWithRole = async (claims: JwtClaims, orgId: string) => {
    const [o] = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        id: string;
        name: string;
        slug: string;
        plan: string;
        region: string;
        icon: string | null;
        color: string | null;
        created_at: Date;
        role: "owner" | "admin" | "member";
        require_mfa: boolean;
        suspended_at: Date | null;
      }>(sql`
        select o.id, o.name, o.slug, o.plan, o.region, o.icon, o.color, o.created_at, m.role, o.require_mfa, o.suspended_at
        from public.organizations o join public.memberships m on m.org_id = o.id and m.user_id = ${claims.sub}::uuid
        where o.id = ${orgId}::uuid`),
    );
    if (!o) return null;
    const { suspended_at, ...rest } = o;
    return { ...rest, created_at: iso(o.created_at), suspended: suspended_at != null };
  };

  const personName = async (userId: string) => {
    const [p] = await db.execute<{ name: string | null }>(sql`
      select coalesce(nullif(p.display_name, ''), u.email::text) as name
      from auth.users u left join public.profiles p on p.user_id = u.id where u.id = ${userId}::uuid`);
    return p?.name ?? "Someone";
  };

  const notify = async (
    userIds: string[],
    orgId: string,
    kind: string,
    payload: { title: string; body: string; link: string },
  ) => {
    for (const userId of new Set(userIds))
      await db.execute(sql`
        insert into public.notifications (user_id, org_id, kind, payload, push_status, push_after)
        values (${userId}::uuid, ${orgId}::uuid, ${kind}, ${JSON.stringify(payload)}::jsonb, 'deferred', now())`);
  };

  const admins = async (orgId: string) =>
    (
      await db.execute<{ user_id: string }>(
        sql`select user_id from public.memberships where org_id = ${orgId}::uuid and role in ('owner', 'admin')`,
      )
    ).map((r) => r.user_id);

  const audit = async (orgId: string, actor: string, action: string, metadata: object) => {
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${orgId}::uuid, 'user', ${actor}::uuid, ${action}, 'organization', ${orgId}::uuid, ${JSON.stringify(metadata)}::jsonb)`);
    // Team growth (F7): ids and enums only (`via` is email, link, code or domain).
    const via = (metadata as { via?: string }).via ?? null;
    const events: Record<string, [string, Record<string, string | null>]> = {
      "member.joined": ["member_joined", { via }],
      "member.requested": ["join_requested", { via }],
      "member.approved": ["join_request_decided", { decision: "approved" }],
      "member.declined": ["join_request_decided", { decision: "declined" }],
    };
    const e = events[action];
    if (e) track(db, { event: e[0], userId: actor, orgId, properties: e[1] });
  };

  /** Tells the person who made the invite (and, for domain joins, the admins) who joined. */
  const announceJoin = async (orgId: string, joinerId: string, toUserIds: string[]) => {
    const to = toUserIds.filter((id) => id && id !== joinerId);
    if (!to.length) return;
    const [org] = await db.execute<{ name: string }>(
      sql`select name from public.organizations where id = ${orgId}::uuid`,
    );
    const who = await personName(joinerId);
    await notify(to, orgId, "member_joined", {
      title: `${who} joined ${org?.name ?? "your workspace"}`,
      body: "Say hello, and share the bots they'll need.",
      link: "/settings/people",
    });
  };

  // --- the standing link -----------------------------------------------------------

  const insertLink = async (
    claims: JwtClaims,
    orgId: string,
    v: {
      token: string;
      hint: string;
      role: "admin" | "member";
      kind: "link" | "code";
      expires: Date | null;
      maxUses: number | null;
      approval: boolean;
      isDefault: boolean;
    },
  ) => {
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<LinkRow>(sql`
        insert into public.invite_links (org_id, role, token_hash, token_hint, expires_at, max_uses, created_by, kind, requires_approval, is_default, share_token)
        values (${orgId}::uuid, ${v.role}, ${sha256Hex(v.token)}, ${v.hint}, ${v.expires?.toISOString() ?? null}::timestamptz,
                ${v.maxUses}, ${claims.sub}::uuid, ${v.kind}, ${v.approval}, ${v.isDefault},
                ${v.isDefault ? contentKeys.seal(orgId, v.token) : null})
        returning ${LINK_COLUMNS}`),
    );
    if (!row) throw new Error("invite link insert returned nothing");
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${orgId}::uuid, 'user', ${claims.sub}::uuid, 'invite_link.created', 'invite_link', ${row.id}::uuid,
              ${JSON.stringify({ role: row.role, kind: row.kind, default: row.is_default, approval: row.requires_approval })}::jsonb)`);
    track(db, {
      event: "invite_created",
      userId: claims.sub,
      orgId,
      properties: {
        channel: row.is_default ? "standing_link" : row.kind,
        role: row.role,
        requires_approval: row.requires_approval,
      },
    });
    milestone(db, claims.sub, "first_invite", orgId);
    return row;
  };

  const loadDefault = async (orgId: string) => {
    const [row] = await db.execute<LinkRow & { share_token: string | null }>(sql`
      select ${LINK_COLUMNS}, share_token from public.invite_links
      where org_id = ${orgId}::uuid and is_default and revoked_at is null`);
    return row ?? null;
  };

  const ensureDefault = async (claims: JwtClaims, orgId: string, approval = false) => {
    for (let attempt = 0; attempt < 3; attempt++) {
      const existing = await loadDefault(orgId);
      if (existing?.share_token) {
        const { share_token, ...row } = existing;
        return { ...linkOut(row), token: share_token, url: joinUrl(share_token) };
      }
      const token = `kjoin_${randomBytes(24).toString("base64url")}`;
      try {
        const row = await insertLink(claims, orgId, {
          token,
          hint: token.slice(0, 10),
          role: "member",
          kind: "link",
          expires: null,
          maxUses: null,
          approval,
          isDefault: true,
        });
        return { ...linkOut(row), token, url: joinUrl(token) };
      } catch (err) {
        // Another admin made it at the same moment: read theirs.
        if (pgErrorCode(err) !== "23505") throw err;
      }
    }
    throw new ApiError(409, "conflict", "Could not make the invite link; try again");
  };

  app.openapi(routes.getDefaultInvite, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await requireAdmin(claims, id);
    return c.json(await ensureDefault(claims, id), 200);
  });

  app.openapi(routes.updateDefaultInvite, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    await requireAdmin(claims, id);
    const current = await loadDefault(id);
    const approval = b.requires_approval ?? current?.requires_approval ?? false;
    if (b.reset && current) {
      await withUserSession(db, claims, (tx) =>
        tx.execute(
          sql`update public.invite_links set revoked_at = now() where id = ${current.id}::uuid`,
        ),
      );
      await audit(id, claims.sub, "invite_link.reset", { link_id: current.id });
    } else if (current && b.requires_approval !== undefined) {
      await withUserSession(db, claims, (tx) =>
        tx.execute(
          sql`update public.invite_links set requires_approval = ${approval} where id = ${current.id}::uuid`,
        ),
      );
    }
    return c.json(await ensureDefault(claims, id, approval), 200);
  });

  app.openapi(routes.createInviteCode, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    await requireAdmin(claims, id);
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = newInviteCode();
      try {
        const row = await insertLink(claims, id, {
          token: code,
          hint: code.slice(0, 4),
          role: b.role ?? "member",
          kind: "code",
          expires: new Date(Date.now() + CODE_TTL_HOURS * 3_600_000),
          maxUses: null,
          approval: false,
          isDefault: false,
        });
        const shown = formatCode(code);
        return c.json({ ...linkOut(row), token: shown, url: joinUrl(shown) }, 201);
      } catch (err) {
        if (pgErrorCode(err) !== "23505") throw err;
      }
    }
    throw new ApiError(409, "conflict", "Could not make a code; try again");
  });

  // --- preview and join ------------------------------------------------------------

  const limitKey = (c: { req: { header(n: string): string | undefined } }, claims?: JwtClaims) =>
    claims?.sub
      ? `u:${claims.sub}`
      : `ip:${c.req.header("x-forwarded-for")?.split(",")[0]?.trim() ?? c.req.header("x-real-ip") ?? "unknown"}`;

  type PreviewRow = {
    kind: "link" | "code" | "email";
    org_id: string;
    org_name: string;
    org_icon: string | null;
    org_color: string | null;
    member_count: number;
    role: "owner" | "admin" | "member";
    inviter_name: string | null;
    requires_approval: boolean;
    email: string | null;
  };
  const lookup = async (parsed: ParsedInvite) => {
    const [row] = await db.execute<PreviewRow>(
      sql`select * from public.invite_preview(${sha256Hex(parsed.token)})`,
    );
    return row ?? null;
  };

  app.openapi(routes.previewInvite, async (c) => {
    const claims = c.get("claims");
    const key = limitKey(c, claims);
    limiter.check(key);
    const parsed = parseInvite(c.req.valid("query").invite);
    const row = parsed ? await lookup(parsed) : null;
    if (!row) {
      limiter.miss(key);
      throw new ApiError(404, "invite_invalid", "This invite is invalid, used up or expired");
    }
    let alreadyMember: boolean | null = null;
    if (claims) {
      const [m] = await db.execute<{ ok: boolean }>(sql`
        select exists(select 1 from public.memberships where org_id = ${row.org_id}::uuid and user_id = ${claims.sub}::uuid) as ok`);
      alreadyMember = !!m?.ok;
    }
    return c.json(
      {
        kind: row.kind,
        workspace: {
          name: row.org_name,
          icon: row.org_icon,
          color: row.org_color,
          member_count: row.member_count,
        },
        role: row.role,
        inviter_name: row.inviter_name,
        requires_approval: row.requires_approval,
        email_hint: row.email ? maskEmail(row.email) : null,
        already_member: alreadyMember,
      },
      200,
    );
  });

  app.openapi(routes.joinWithInvite, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const key = limitKey(c, claims);
    limiter.check(key);
    const parsed = parseInvite(c.req.valid("json").invite);
    const invalid = () => {
      limiter.miss(key);
      return new ApiError(404, "invite_invalid", "This invite is invalid, used up or expired");
    };
    if (!parsed) throw invalid();

    if (parsed.kind === "email") {
      let orgId: string;
      try {
        const [m] = await withUserSession(db, claims, (tx) =>
          tx.execute<{ org_id: string }>(
            sql`select org_id from public.accept_invite(${sha256Hex(parsed.token)})`,
          ),
        );
        if (!m) throw new Error("accept_invite returned nothing");
        orgId = m.org_id;
      } catch (err) {
        if (pgErrorCode(err) === "P0002") throw invalid();
        if (pgErrorCode(err) === "42501" && pgErrorMessage(err) === "invite_email_mismatch")
          throw new ApiError(
            403,
            "invite_email_mismatch",
            "This invite was sent to a different email address. Sign in with that address to join.",
          );
        throw err;
      }
      const [inv] = await db.execute<{ invited_by: string | null }>(
        sql`select invited_by from public.invites where token_hash = ${sha256Hex(parsed.token)}`,
      );
      await audit(orgId, claims.sub, "member.joined", { via: "email" });
      await announceJoin(orgId, claims.sub, inv?.invited_by ? [inv.invited_by] : []);
      const org = await orgWithRole(claims, orgId);
      return c.json(
        {
          status: "joined" as const,
          organization: org ?? undefined,
          workspace_name: org?.name ?? "",
        },
        200,
      );
    }

    let used: {
      org_id: string;
      status: "joined" | "member" | "requested";
      created_by: string | null;
    };
    try {
      const [r] = await withUserSession(db, claims, (tx) =>
        tx.execute<typeof used>(
          sql`select org_id, status, created_by from public.use_invite_link(${sha256Hex(parsed.token)})`,
        ),
      );
      if (!r) throw new Error("use_invite_link returned nothing");
      used = r;
    } catch (err) {
      if (pgErrorCode(err) === "P0002") throw invalid();
      throw err;
    }
    const [org] = await db.execute<{ name: string }>(
      sql`select name from public.organizations where id = ${used.org_id}::uuid`,
    );
    if (used.status === "requested") {
      const who = await personName(claims.sub);
      await notify(await admins(used.org_id), used.org_id, "join_request", {
        title: `${who} asked to join ${org?.name ?? "your workspace"}`,
        body: "Approve or decline in People.",
        link: "/settings/people",
      });
      await audit(used.org_id, claims.sub, "member.requested", { via: parsed.kind });
      return c.json({ status: "requested" as const, workspace_name: org?.name ?? "" }, 200);
    }
    if (used.status === "joined") {
      await audit(used.org_id, claims.sub, "member.joined", { via: parsed.kind });
      await announceJoin(used.org_id, claims.sub, used.created_by ? [used.created_by] : []);
    }
    return c.json(
      {
        status: used.status,
        organization: (await orgWithRole(claims, used.org_id)) ?? undefined,
        workspace_name: org?.name ?? "",
      },
      200,
    );
  });

  // --- requests --------------------------------------------------------------------

  type RequestRow = {
    id: string;
    org_id: string;
    user_id: string;
    email: string | null;
    display_name: string | null;
    role: "admin" | "member";
    status: "pending" | "approved" | "declined";
    created_at: Date;
  };
  const requestOut = (r: RequestRow) => ({ ...r, created_at: iso(r.created_at) });

  app.openapi(routes.listJoinRequests, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await requireAdmin(claims, id);
    const rows = await db.execute<RequestRow>(sql`
      select r.id, r.org_id, r.user_id, u.email::text as email, nullif(p.display_name, '') as display_name, r.role, r.status, r.created_at
      from public.join_requests r
      left join auth.users u on u.id = r.user_id
      left join public.profiles p on p.user_id = r.user_id
      where r.org_id = ${id}::uuid and r.status = 'pending' order by r.created_at`);
    return c.json({ items: rows.map(requestOut) }, 200);
  });

  app.openapi(routes.decideJoinRequest, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, request_id } = c.req.valid("param");
    const { approve } = c.req.valid("json");
    let decided: { id: string; org_id: string; user_id: string; status: string };
    try {
      const [r] = await withUserSession(db, claims, (tx) =>
        tx.execute<typeof decided>(
          sql`select id, org_id, user_id, status from public.decide_join_request(${request_id}::uuid, ${approve})`,
        ),
      );
      if (!r || r.org_id !== id) throw new ApiError(404, "request_not_found", "Request not found");
      decided = r;
    } catch (err) {
      if (pgErrorCode(err) === "P0002")
        throw new ApiError(404, "request_not_found", "Request not found");
      throw err;
    }
    if (approve && decided.status === "approved") {
      const [org] = await db.execute<{ name: string }>(
        sql`select name from public.organizations where id = ${id}::uuid`,
      );
      await notify([decided.user_id], id, "join_approved", {
        title: `You're in ${org?.name ?? "the workspace"}`,
        body: "Your request to join was approved.",
        link: `/joined/${id}`,
      });
      await audit(id, claims.sub, "member.approved", { user_id: decided.user_id });
    } else if (!approve) {
      await audit(id, claims.sub, "member.declined", { user_id: decided.user_id });
    }
    const [row] = await db.execute<RequestRow>(sql`
      select r.id, r.org_id, r.user_id, u.email::text as email, nullif(p.display_name, '') as display_name, r.role, r.status, r.created_at
      from public.join_requests r
      left join auth.users u on u.id = r.user_id
      left join public.profiles p on p.user_id = r.user_id
      where r.id = ${decided.id}::uuid`);
    return c.json(requestOut(row as RequestRow), 200);
  });

  // --- email invites ---------------------------------------------------------------

  const inviteOut = (i: InviteRow, emailSent: boolean, token: string) => ({
    id: i.id,
    org_id: i.org_id,
    email: i.email,
    role: i.role,
    expires_at: iso(i.expires_at),
    email_sent: emailSent,
    ...(emailSent ? {} : { accept_token: token }),
  });

  app.openapi(routes.listInvites, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await requireAdmin(claims, id);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<InviteRow>(sql`
        select id, org_id, email::text as email, role, expires_at, created_at from public.invites
        where org_id = ${id}::uuid and accepted_at is null order by created_at desc limit 200`),
    );
    return c.json(
      {
        items: rows.map((r) => ({
          id: r.id,
          email: r.email,
          role: r.role,
          expires_at: iso(r.expires_at),
          created_at: iso(r.created_at),
        })),
      },
      200,
    );
  });

  app.openapi(routes.createInvites, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    await requireAdmin(claims, id);
    const emails = [...new Set(b.emails.map((e) => e.trim().toLowerCase()))];
    const items = [];
    for (const email of emails)
      items.push(await createEmailInvite(deps, claims, id, email, b.role ?? "member"));
    return c.json({ items }, 201);
  });

  app.openapi(routes.resendInvite, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, invite_id } = c.req.valid("param");
    await requireAdmin(claims, id);
    const token = newToken();
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<InviteRow>(sql`
        update public.invites set token_hash = ${sha256Hex(token)}, expires_at = now() + interval '7 days'
        where id = ${invite_id}::uuid and org_id = ${id}::uuid and accepted_at is null
        returning id, org_id, email::text as email, role, expires_at, created_at`),
    );
    if (!row) throw new ApiError(404, "invite_not_found", "Invite not found");
    const sent = await sendInviteEmail(deps, id, row.email, token);
    return c.json(inviteOut(row, sent, token), 200);
  });

  app.openapi(routes.revokeInvite, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, invite_id } = c.req.valid("param");
    await requireAdmin(claims, id);
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string }>(sql`
        delete from public.invites where id = ${invite_id}::uuid and org_id = ${id}::uuid and accepted_at is null returning id`),
    );
    if (!rows.length) throw new ApiError(404, "invite_not_found", "Invite not found");
    return c.body(null, 204);
  });

  // --- email domains ---------------------------------------------------------------

  const joinDomains = async (claims: JwtClaims, orgId: string) => {
    const [mine] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ domain: string | null; shared: boolean | null }>(sql`
        select d as domain, public.is_shared_email_domain(d) as shared from (select public.my_email_domain() as d) x`),
    );
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ domain: string }>(
        sql`select domain::text as domain from public.org_join_domains where org_id = ${orgId}::uuid order by domain`,
      ),
    );
    const myDomain = mine?.domain ?? null;
    return {
      items: rows.map((r) => r.domain),
      my_domain: myDomain,
      can_use: !!myDomain && !mine?.shared,
    };
  };

  app.openapi(routes.getJoinDomains, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await requireAdmin(claims, id);
    return c.json(await joinDomains(claims, id), 200);
  });

  app.openapi(routes.setJoinDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const b = c.req.valid("json");
    await requireAdmin(claims, id);
    const current = await joinDomains(claims, id);
    if (b.enabled) {
      if (!current.can_use || !current.my_domain)
        throw new ApiError(
          400,
          "domain_unavailable",
          "Only your own verified work email domain can be used (not gmail.com and the like)",
        );
      await withUserSession(db, claims, (tx) =>
        tx.execute(sql`
          insert into public.org_join_domains (org_id, domain, created_by)
          values (${id}::uuid, ${current.my_domain}, ${claims.sub}::uuid) on conflict do nothing`),
      );
      await audit(id, claims.sub, "join_domain.added", { domain: current.my_domain });
    } else {
      const domain = (b.domain ?? current.my_domain ?? "").toLowerCase();
      await withUserSession(db, claims, (tx) =>
        tx.execute(
          sql`delete from public.org_join_domains where org_id = ${id}::uuid and domain = ${domain}`,
        ),
      );
      await audit(id, claims.sub, "join_domain.removed", { domain });
    }
    return c.json(await joinDomains(claims, id), 200);
  });

  app.openapi(routes.listJoinableWorkspaces, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{
        org_id: string;
        org_name: string;
        org_icon: string | null;
        org_color: string | null;
        member_count: number;
        domain: string;
      }>(sql`select * from public.joinable_workspaces()`),
    );
    return c.json(
      {
        items: rows.map((r) => ({
          id: r.org_id,
          name: r.org_name,
          icon: r.org_icon,
          color: r.org_color,
          member_count: r.member_count,
          domain: r.domain,
        })),
      },
      200,
    );
  });

  app.openapi(routes.joinByDomain, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const before = await orgWithRole(claims, id);
    try {
      await withUserSession(db, claims, (tx) =>
        tx.execute(sql`select 1 from public.join_by_domain(${id}::uuid)`),
      );
    } catch (err) {
      if (pgErrorCode(err) === "P0002")
        throw new ApiError(404, "org_not_found", "This workspace isn't open to your email domain");
      throw err;
    }
    if (!before) {
      await audit(id, claims.sub, "member.joined", { via: "domain" });
      await announceJoin(id, claims.sub, await admins(id));
    }
    const org = await orgWithRole(claims, id);
    if (!org) throw new ApiError(404, "org_not_found", "Workspace not found");
    return c.json(org, 200);
  });

  // --- web: the join page and app-link association files ---------------------------

  // Universal links (iOS) and App Links (Android) for /join/*, when the app's ids are configured.
  app.get("/.well-known/apple-app-site-association", (c) => {
    const ids = (deps.env.APPLE_APP_IDS ?? "")
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
    if (!ids.length) throw new ApiError(404, "not_found", "App links aren't set up here");
    return c.json({
      applinks: {
        details: [
          {
            appIDs: ids,
            components: [{ "/": "/join/*" }, { "/": "/invites/*" }],
          },
        ],
      },
    });
  });
  app.get("/.well-known/assetlinks.json", (c) => {
    const prints = (deps.env.ANDROID_CERT_SHA256 ?? "")
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
    if (!prints.length) throw new ApiError(404, "not_found", "App links aren't set up here");
    return c.json([
      {
        relation: ["delegate_permission/common.handle_all_urls"],
        target: {
          namespace: "android_app",
          package_name: deps.env.ANDROID_APP_PACKAGE,
          sha256_cert_fingerprints: prints,
        },
      },
    ]);
  });

  // The page a link opens in a browser when the web app isn't served here (Caddy sends /join/*
  // to it then): what the invite is, "Open in the app" and where to get the app.
  app.get("/join/:token", async (c) => {
    const token = c.req.param("token");
    const parsed = /^[A-Za-z0-9_-]{6,80}$/.test(token) ? parseInvite(token) : null;
    const key = limitKey(c);
    limiter.check(key);
    const row = parsed ? await lookup(parsed) : null;
    if (!row) limiter.miss(key);
    const server = (deps.env.PUBLIC_API_URL ?? new URL(c.req.url).origin).replace(/\/$/, "");
    const openUrl = `casama://app/join/${encodeURIComponent(token)}?server=${encodeURIComponent(server)}`;
    c.header(
      "content-security-policy",
      "default-src 'none'; style-src 'unsafe-inline'; img-src data:; frame-ancestors 'none'",
    );
    c.header("cache-control", "no-store");
    return c.html(
      joinPage({
        product: PRODUCT_NAME,
        preview: row,
        openUrl,
        server,
        appStoreUrl: deps.env.APP_STORE_URL,
        playStoreUrl: deps.env.PLAY_STORE_URL,
      }),
      row ? 200 : 404,
    );
  });
}

// --- email invites (also used by POST /v1/orgs/{id}/invites) -------------------------

export async function sendInviteEmail(deps: AppDeps, orgId: string, email: string, token: string) {
  if (!deps.email.enabled) return false;
  const [org] = await deps.db.execute<{ name: string }>(
    sql`select name from public.organizations where id = ${orgId}::uuid`,
  );
  const name = org?.name ?? "a workspace";
  const link = `${deps.env.PUBLIC_APP_URL.replace(/\/$/, "")}/join/${token}`;
  try {
    const message: BrandedEmail = {
      mascot: "starry",
      preheader: `Join ${name} on ${PRODUCT_NAME}`,
      title: `You're invited to ${name}`,
      intro: [
        `You've been invited to join ${name} on ${PRODUCT_NAME}, where AI teammates work for you on their own computers.`,
        `Sign in with ${email} to accept.`,
      ],
      button: { label: "Join the workspace", url: link },
      note: "This link expires in 7 days. If you weren't expecting it, you can ignore this email.",
    };
    await deps.email.send({
      to: email,
      subject: `You're invited to ${name} on ${PRODUCT_NAME}`,
      text: renderEmailText(message),
      html: renderEmailHtml(message),
    });
    return true;
  } catch (err) {
    deps.logger.warn("invite email failed", { org_id: orgId, error: (err as Error).message });
    return false;
  }
}

export async function createEmailInvite(
  deps: AppDeps,
  claims: JwtClaims,
  orgId: string,
  email: string,
  role: "admin" | "member",
) {
  const token = newToken();
  const [invite] = await withUserSession(deps.db, claims, (tx) =>
    tx.execute<InviteRow>(sql`
      insert into public.invites (org_id, email, role, token_hash, invited_by)
      values (${orgId}::uuid, ${email.toLowerCase()}, ${role}, ${sha256Hex(token)}, ${claims.sub}::uuid)
      returning id, org_id, email::text as email, role, expires_at, created_at`),
  );
  if (!invite) throw new Error("invite insert returned nothing");
  const sent = await sendInviteEmail(deps, orgId, invite.email, token);
  track(deps.db, {
    event: "invite_created",
    userId: claims.sub,
    orgId,
    properties: { channel: "email", role: invite.role, email_sent: sent },
  });
  milestone(deps.db, claims.sub, "first_invite", orgId);
  return {
    id: invite.id,
    org_id: invite.org_id,
    email: invite.email,
    role: invite.role,
    expires_at: iso(invite.expires_at),
    email_sent: sent,
    ...(sent ? {} : { accept_token: token }),
  };
}

// --- the join page -------------------------------------------------------------------

const esc = (s: string) =>
  s.replace(
    /[&<>"']/g,
    (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[ch] as string,
  );

function joinPage(p: {
  product: string;
  preview: {
    org_name: string;
    org_color: string | null;
    member_count: number;
    role: string;
    inviter_name: string | null;
    requires_approval: boolean;
    kind: string;
    email: string | null;
  } | null;
  openUrl: string;
  server: string;
  appStoreUrl?: string;
  playStoreUrl?: string;
}) {
  const color =
    p.preview?.org_color && /^#[0-9a-fA-F]{6}$/.test(p.preview.org_color)
      ? p.preview.org_color
      : "#6366f1";
  const initial = esc((p.preview?.org_name ?? "?").slice(0, 1).toUpperCase());
  const stores = [
    p.appStoreUrl ? `<a class="store" href="${esc(p.appStoreUrl)}">App Store</a>` : "",
    p.playStoreUrl ? `<a class="store" href="${esc(p.playStoreUrl)}">Google Play</a>` : "",
  ].join("");
  const body = p.preview
    ? `<div class="tile" style="background:${color}22;color:${color}">${initial}</div>
      <p class="eyebrow">${p.preview.inviter_name ? `${esc(p.preview.inviter_name)} invited you to join` : "You're invited to join"}</p>
      <h1>${esc(p.preview.org_name)}</h1>
      <p class="meta">${p.preview.member_count} ${p.preview.member_count === 1 ? "member" : "members"} · you'd join as ${p.preview.role === "admin" ? "an admin" : "a member"}</p>
      ${p.preview.requires_approval ? `<p class="note">An admin approves new people before they join.</p>` : ""}
      ${p.preview.email ? `<p class="note">Sign in with ${esc(p.preview.email.replace(/^(.).*@/, "$1•••@"))} to accept.</p>` : ""}
      <a class="primary" href="${esc(p.openUrl)}">Open in ${esc(p.product)}</a>
      <p class="small">Don't have ${esc(p.product)} yet? Get the app, sign in to <b>${esc(p.server.replace(/^https?:\/\//, ""))}</b>, and open this link again.</p>
      ${stores ? `<div class="stores">${stores}</div>` : ""}`
    : `<div class="tile" style="background:#64748b22;color:#64748b">?</div>
      <h1>This invite doesn't work</h1>
      <p class="meta">It may have expired, been used up or been turned off. Ask for a new one.</p>`;
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex"><title>${p.preview ? `Join ${esc(p.preview.org_name)}` : "Invite"} · ${esc(p.product)}</title>
<style>
:root{color-scheme:light dark;--bg:#f7f7f8;--card:#fff;--text:#18181b;--muted:#71717a;--accent:#6366f1}
@media (prefers-color-scheme:dark){:root{--bg:#0b0b0e;--card:#17171c;--text:#f4f4f5;--muted:#a1a1aa}}
*{box-sizing:border-box}body{margin:0;min-height:100vh;display:grid;place-items:center;padding:16px;background:var(--bg);color:var(--text);font:16px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}
main{width:100%;max-width:420px;background:var(--card);border-radius:20px;padding:32px 24px;text-align:center;box-shadow:0 1px 3px #0000001a}
.tile{width:64px;height:64px;border-radius:18px;margin:0 auto 16px;display:grid;place-items:center;font-weight:800;font-size:28px}
.eyebrow{margin:0;color:var(--muted);font-size:14px}h1{margin:4px 0 8px;font-size:26px;line-height:1.2}
.meta{margin:0 0 16px;color:var(--muted);font-size:14px}.note{margin:0 0 16px;font-size:14px}
.primary{display:block;margin:20px 0 12px;padding:14px;border-radius:12px;background:var(--accent);color:#fff;text-decoration:none;font-weight:700}
.small{margin:0;color:var(--muted);font-size:13px}.stores{display:flex;gap:8px;justify-content:center;margin-top:12px}
.store{padding:8px 14px;border-radius:10px;border:1px solid #71717a55;color:var(--text);text-decoration:none;font-size:14px}
</style></head><body><main>${body}</main></body></html>`;
}
