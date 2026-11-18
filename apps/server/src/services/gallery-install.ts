/**
 * Gallery v2 installs (D-315): one install route for every workspace kind with install questions
 * and needs, starter sets, the Installed list with updates, removal, and the workspace's gallery
 * rules with admin approvals.
 *
 * The actual creating goes through the existing routes (skills, bots, routines, plugins) as the
 * caller, so limits, permissions and what each route records stay exactly as they are; those
 * routes remember the install (gallery_links) and count the person.
 */
import { type JwtClaims, withUserSession } from "@casama/db";
import {
  APP_CATALOG,
  checkGalleryInputValues,
  DEFAULT_GALLERY_POLICY,
  type GalleryAccess,
  type GalleryInput,
  type GalleryPolicy,
  galleryAccessAdded,
  galleryAccessGrew,
  galleryChangesSince,
  galleryItemKey,
  galleryPolicyDecision,
  parseGalleryPolicy,
  starterBotName,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import { ApiError } from "../api/errors.ts";
import type { AppDeps } from "../api/types.ts";
import {
  botFromRecord,
  fetchGallerySkill,
  galleryApps,
  galleryRecord,
  galleryRecords,
  gallerySets,
  routineFromRecord,
  splitGalleryId,
} from "./gallery.ts";
import { recordGalleryUse } from "./gallery-usage.ts";

type Deps = Pick<AppDeps, "db" | "env" | "logger">;
export type WorkspaceKind = "skill" | "app" | "bot" | "routine" | "plugin";
const WORKSPACE_KINDS: WorkspaceKind[] = ["skill", "app", "bot", "routine", "plugin"];

/** Calls another API route as the same person (their bearer token), throwing its problem. */
export type InternalCall = (
  method: string,
  path: string,
  json?: unknown,
) => Promise<Record<string, unknown> | null>;

export function internalCaller(
  app: { request: (path: string, init: RequestInit) => Response | Promise<Response> },
  authorization: string,
): InternalCall {
  return async (method, path, json) => {
    const res = await app.request(path, {
      method,
      headers: {
        authorization,
        ...(json !== undefined ? { "content-type": "application/json" } : {}),
      },
      ...(json !== undefined ? { body: JSON.stringify(json) } : {}),
    });
    const text = await res.text();
    let body: Record<string, unknown> | null = null;
    try {
      body = text ? (JSON.parse(text) as Record<string, unknown>) : null;
    } catch {
      body = null;
    }
    if (res.status >= 400)
      throw new ApiError(
        res.status as 400,
        typeof body?.code === "string" ? body.code : "gallery_install_failed",
        typeof body?.detail === "string" ? body.detail : `Couldn't add it (${res.status})`,
        Array.isArray(body?.errors) ? { errors: body.errors as never } : undefined,
      );
    return body;
  };
}

// ---------------------------------------------------------------- membership and roles

async function role(db: Deps["db"], claims: JwtClaims, orgId: string) {
  const [r] = await withUserSession(db, claims, (tx) =>
    tx.execute<{ member: boolean; admin: boolean }>(
      sql`select public.is_member(${orgId}::uuid) as member, public.has_role(${orgId}::uuid, 'admin') as admin`,
    ),
  );
  return { member: !!r?.member, admin: !!r?.admin };
}

export async function requireMember(db: Deps["db"], claims: JwtClaims, orgId: string) {
  const r = await role(db, claims, orgId);
  if (!r.member) throw new ApiError(404, "org_not_found", "Workspace not found");
  return r;
}

// ---------------------------------------------------------------- the workspace's rules

export async function galleryPolicyFor(db: Deps["db"], orgId: string): Promise<GalleryPolicy> {
  const [row] = await db.execute<{ policy: unknown }>(
    sql`select policy from public.gallery_policies where org_id = ${orgId}::uuid`,
  );
  return row ? parseGalleryPolicy(row.policy).policy : { ...DEFAULT_GALLERY_POLICY };
}

export async function setGalleryPolicyFor(
  deps: Deps,
  claims: JwtClaims,
  orgId: string,
  raw: unknown,
): Promise<GalleryPolicy> {
  const r = await requireMember(deps.db, claims, orgId);
  if (!r.admin)
    throw new ApiError(403, "forbidden", "Only owners and admins change the gallery rules");
  const { policy, errors } = parseGalleryPolicy(raw);
  if (errors.length)
    throw new ApiError(400, "validation_failed", errors.join("; "), {
      errors: errors.map((message) => ({ path: "policy", message })),
    });
  await deps.db.execute(sql`
    insert into public.gallery_policies (org_id, policy, updated_by, updated_at)
    values (${orgId}::uuid, ${JSON.stringify(policy)}::jsonb, ${claims.sub}::uuid, now())
    on conflict (org_id) do update set policy = excluded.policy, updated_by = excluded.updated_by, updated_at = now()`);
  await deps.db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
    values (${orgId}::uuid, 'user', ${claims.sub}::uuid, 'gallery.policy_changed', 'organization', ${orgId}::uuid,
            ${JSON.stringify({ mode: policy.mode })}::jsonb)`);
  return policy;
}

const isOpen = (p: GalleryPolicy) => p.mode === "open" && !p.block.length && !p.approval_for.length;

/** What the rules say about this person adding this item. */
export async function galleryDecision(
  deps: Deps,
  claims: JwtClaims,
  orgId: string,
  type: string,
  id: string,
  access?: GalleryAccess,
) {
  const policy = await galleryPolicyFor(deps.db, orgId);
  if (isOpen(policy)) return { decision: "allow" as const };
  const { admin } = await role(deps.db, claims, orgId);
  let itemAccess = access;
  if (!itemAccess && policy.approval_for.includes("runs_code")) {
    const rec = await galleryRecord(deps.env, type, id).catch(() => undefined);
    itemAccess = (rec?.access as GalleryAccess | undefined) ?? undefined;
  }
  return galleryPolicyDecision(policy, { type, id, access: itemAccess }, { admin });
}

/** Tells the workspace's owners and admins there's something to approve. */
async function notifyAdmins(deps: Deps, orgId: string, approvalId: string, what: string) {
  const admins = await deps.db.execute<{ user_id: string }>(
    sql`select user_id from public.memberships where org_id = ${orgId}::uuid and role in ('owner', 'admin')`,
  );
  for (const a of admins)
    await deps.db.execute(sql`
      insert into public.notifications (user_id, org_id, kind, payload, push_status, push_after)
      values (${a.user_id}::uuid, ${orgId}::uuid, 'gallery_approval',
              ${JSON.stringify({
                title: "A gallery item is waiting for you",
                body: `Someone asked to add ${what}. Approve or decline it in Settings > Gallery.`,
                link: "/settings/gallery",
                gallery_approval_id: approvalId,
              })}::jsonb, 'deferred', now())`);
}

export async function createGalleryApproval(
  deps: Deps,
  a: {
    orgId: string;
    userId: string;
    type: WorkspaceKind | "pack";
    id: string;
    name: string;
    inputs?: Record<string, unknown>;
    botId?: string | null;
    reason: string;
  },
): Promise<string> {
  const [row] = await deps.db.execute<{ id: string }>(sql`
    insert into public.gallery_approvals (org_id, requested_by, item_type, item_id, name, inputs, bot_id, reason)
    values (${a.orgId}::uuid, ${a.userId}::uuid, ${a.type}, ${a.id}, ${a.name.slice(0, 120)},
            ${JSON.stringify(a.inputs ?? {})}::jsonb, ${a.botId ?? null}::uuid, ${a.reason.slice(0, 200)})
    on conflict (org_id, requested_by, item_type, item_id) where status = 'pending'
      do update set inputs = excluded.inputs, bot_id = excluded.bot_id
    returning id, (xmax = 0) as fresh`);
  const id = row?.id as string;
  if ((row as { fresh?: boolean } | undefined)?.fresh !== false)
    await notifyAdmins(deps, a.orgId, id, a.name).catch(() => {});
  return id;
}

/**
 * The rules on the older install routes: blocked is 403 `gallery_blocked`; one that needs an
 * admin asks them and answers 403 `approval_pending` (older apps show it as a message).
 */
export async function enforceGalleryPolicy(
  deps: Deps,
  claims: JwtClaims,
  orgId: string,
  type: WorkspaceKind,
  id: string,
): Promise<void> {
  const d = await galleryDecision(deps, claims, orgId, type, id);
  if (d.decision === "allow") return;
  if (d.decision === "block") throw new ApiError(403, "gallery_blocked", d.reason);
  const rec = await galleryRecord(deps.env, type, id).catch(() => undefined);
  await createGalleryApproval(deps, {
    orgId,
    userId: claims.sub,
    type,
    id,
    name: rec?.name ?? id,
    reason: d.reason,
  });
  throw new ApiError(
    403,
    "approval_pending",
    `${d.reason} We've asked them; it's added once they approve.`,
  );
}

/** The policy key for something added from a link: `repo/<owner>:<repo>`, lowercased. */
export function repoPolicyKey(ref: { owner: string; repo: string }) {
  const part = (v: string, n: number) =>
    v
      .toLowerCase()
      .replace(/[^a-z0-9-]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, n) || "x";
  return { type: "repo", id: `${part(ref.owner, 40)}:${part(ref.repo, 63)}` };
}

/**
 * The rules for a plugin or pack added from a link rather than the reviewed directory. Links run
 * whatever the repository holds, so "items that run code" covers them; block and allow lists
 * name them as `repo/<owner>:<repo>`.
 */
export async function enforceLinkPolicy(
  deps: Deps,
  claims: JwtClaims,
  orgId: string,
  ref: { owner: string; repo: string },
  what: "plugin" | "pack",
): Promise<void> {
  const key = repoPolicyKey(ref);
  const d = await galleryDecision(deps, claims, orgId, key.type, key.id, {
    runs_code: true,
  } as GalleryAccess);
  if (d.decision === "allow") return;
  if (d.decision === "block") throw new ApiError(403, "gallery_blocked", d.reason);
  if (what === "pack") return; // packs ask for approval themselves, with the whole request
  await createGalleryApproval(deps, {
    orgId,
    userId: claims.sub,
    type: "plugin",
    id: `${key.type}/${key.id}`,
    name: `${ref.owner}/${ref.repo}`,
    reason: d.reason,
  });
  throw new ApiError(
    403,
    "approval_pending",
    `${d.reason} We've asked them; it's added once they approve.`,
  );
}

// ---------------------------------------------------------------- install with needs and inputs

export interface Missing {
  apps: { id: string; name: string }[];
  skills: { id: string; name: string }[];
}

export interface InstallResult {
  status: "installed" | "approval_pending";
  installed: { kind: WorkspaceKind; id: string } | null;
  approval_id: string | null;
  missing: Missing;
}

async function appName(deps: Deps, id: string): Promise<string> {
  const built = APP_CATALOG.find((a) => a.id === id || a.id === id.replaceAll("-", "_"));
  if (built) return built.name;
  const g = (await galleryApps(deps.env).catch(() => [])).find((a) => a.id === id);
  return g?.name ?? id;
}

/** Needed apps this workspace hasn't connected yet. */
async function missingApps(deps: Deps, orgId: string, ids: string[]): Promise<Missing["apps"]> {
  if (!ids.length) return [];
  const rows = await deps.db.execute<{ app: string | null; name: string; toolkits: unknown }>(sql`
    select config ->> 'app' as app, name, config -> 'toolkits' as toolkits
    from public.integrations where org_id = ${orgId}::uuid and status <> 'error'`);
  const have = new Set<string>();
  for (const r of rows) {
    if (r.app) have.add(r.app);
    have.add(r.name);
    if (Array.isArray(r.toolkits)) for (const t of r.toolkits) have.add(String(t));
  }
  const out: Missing["apps"] = [];
  for (const id of ids) {
    const alt = id.replaceAll("-", "_");
    if (have.has(id) || have.has(alt)) continue;
    out.push({ id, name: await appName(deps, id) });
  }
  return out;
}

/** The skill install route's answer for a needed skill that is already there. */
async function hasSkill(deps: Deps, orgId: string, name: string, botId: string | null) {
  const [r] = await deps.db.execute<{ ok: boolean }>(sql`
    select exists(select 1 from public.skills where org_id = ${orgId}::uuid and name = ${name}
      and (bot_id is null or bot_id = ${botId}::uuid)) as ok`);
  return !!r?.ok;
}

/** Records install answers on what was just made, so updates fill the newer version the same way. */
async function rememberInputs(
  deps: Deps,
  orgId: string,
  kind: WorkspaceKind,
  targetId: string,
  inputs: Record<string, string>,
) {
  if (!Object.keys(inputs).length) return;
  await deps.db.execute(sql`
    update public.gallery_links set inputs = ${JSON.stringify(inputs)}::jsonb
    where org_id = ${orgId}::uuid and target_kind = ${kind} and target_id = ${targetId}`);
}

export async function installGalleryItem(
  deps: Deps,
  call: InternalCall,
  claims: JwtClaims,
  req: {
    orgId: string;
    type: WorkspaceKind;
    id: string;
    inputs?: Record<string, string>;
    botId?: string | null;
  },
  opts: { skipPolicy?: boolean } = {},
): Promise<InstallResult> {
  await requireMember(deps.db, claims, req.orgId);
  const rec = await galleryRecord(deps.env, req.type, req.id);
  if (!rec || rec.retired === true)
    throw new ApiError(404, "gallery_not_found", "That item isn't in the gallery.");
  const inputs = Array.isArray(rec.inputs) ? (rec.inputs as GalleryInput[]) : [];
  const checked = checkGalleryInputValues(inputs, req.inputs);
  const bad = Object.entries(checked.errors);
  if (bad.length)
    throw new ApiError(400, "inputs_invalid", "Some answers don't fit the questions.", {
      errors: bad.map(([path, message]) => ({ path, message })),
    });
  const values = checked.values;
  if (!opts.skipPolicy) {
    const d = await galleryDecision(
      deps,
      claims,
      req.orgId,
      req.type,
      req.id,
      rec.access as GalleryAccess | undefined,
    );
    if (d.decision === "block") throw new ApiError(403, "gallery_blocked", d.reason);
    if (d.decision === "approval") {
      const approvalId = await createGalleryApproval(deps, {
        orgId: req.orgId,
        userId: claims.sub,
        type: req.type,
        id: req.id,
        name: rec.name,
        inputs: req.inputs,
        botId: req.botId,
        reason: d.reason,
      });
      return {
        status: "approval_pending",
        installed: null,
        approval_id: approvalId,
        missing: { apps: [], skills: [] },
      };
    }
  }
  const needs = (rec.needs ?? {}) as { apps?: string[]; skills?: string[] };
  const missing: Missing = {
    apps: await missingApps(deps, req.orgId, needs.apps ?? []),
    skills: [],
  };
  let installed: InstallResult["installed"] = null;
  let skillsTo: string | null = req.botId ?? null;

  if (req.type === "skill") {
    const row = await call("POST", "/v1/skills/install", {
      org_id: req.orgId,
      gallery_id: req.id,
      ...(req.botId ? { bot_id: req.botId } : {}),
    });
    installed = { kind: "skill", id: String(row?.id) };
  } else if (req.type === "bot") {
    const t = botFromRecord(rec, values);
    if (!t) throw new ApiError(502, "gallery_unavailable", "This starter bot can't be read.");
    const row = await call("POST", "/v1/bots", {
      org_id: req.orgId,
      // A person's name ("Rome"), as the new-bot sheet fills in; the gallery name is its job.
      name: starterBotName(req.id),
      template_id: req.id,
      persona_md: t.persona,
    });
    installed = { kind: "bot", id: String(row?.id) };
    skillsTo = installed.id;
    await rememberInputs(deps, req.orgId, "bot", installed.id, values);
  } else if (req.type === "routine") {
    if (!req.botId)
      throw new ApiError(400, "bot_required", "Pick the bot this routine runs on.", {
        errors: [{ path: "bot_id", message: "Required for a routine" }],
      });
    const r = routineFromRecord(rec, values);
    if (!r) throw new ApiError(502, "gallery_unavailable", "This routine can't be read.");
    const row = await call("POST", "/v1/routines", {
      bot_id: req.botId,
      name: r.name,
      instructions: r.instructions_md,
      trigger: "schedule",
      schedule_cron: r.schedule_cron,
      ...(values.timezone ? { timezone: values.timezone } : {}),
      gallery_id: req.id,
    });
    installed = { kind: "routine", id: String(row?.id) };
    await rememberInputs(deps, req.orgId, "routine", installed.id, values);
  } else if (req.type === "plugin") {
    if (!req.botId)
      throw new ApiError(400, "bot_required", "Pick the bot this plugin goes to.", {
        errors: [{ path: "bot_id", message: "Required for a plugin" }],
      });
    const doc = (rec.document ?? {}) as { url?: string; commit?: string };
    const row = await call("POST", "/v1/plugins", {
      org_id: req.orgId,
      bot_id: req.botId,
      url: doc.url,
      commit: doc.commit,
    });
    installed = { kind: "plugin", id: String(row?.id) };
  } else {
    // An app: the person signs in, so it comes back for the app to walk through.
    const own = await missingApps(deps, req.orgId, [req.id]);
    for (const a of own) if (!missing.apps.some((m) => m.id === a.id)) missing.apps.push(a);
    await recordGalleryUse(deps.db, deps.env, claims.sub, "app", req.id).catch(() => {});
  }

  // Needed skills come along (on the new bot, or the routine's bot, else the workspace).
  for (const skillId of needs.skills ?? []) {
    const raw = splitGalleryId(skillId).id;
    if (await hasSkill(deps, req.orgId, raw, skillsTo)) continue;
    try {
      await call("POST", "/v1/skills/install", {
        org_id: req.orgId,
        gallery_id: skillId,
        ...(skillsTo ? { bot_id: skillsTo } : {}),
      });
    } catch (err) {
      const rec2 = await galleryRecord(deps.env, "skill", skillId).catch(() => undefined);
      missing.skills.push({ id: skillId, name: rec2?.name ?? skillId });
      deps.logger.warn("gallery needed skill not added", {
        skill: skillId,
        error: (err as Error).message,
      });
    }
  }
  return { status: "installed", installed, approval_id: null, missing };
}

export async function installGallerySet(
  deps: Deps,
  call: InternalCall,
  claims: JwtClaims,
  req: { orgId: string; id: string; botId?: string | null },
) {
  await requireMember(deps.db, claims, req.orgId);
  const set = (await gallerySets(deps.env)).find((s) => s.id === req.id);
  if (!set) throw new ApiError(404, "gallery_not_found", "That starter set isn't in the gallery.");
  const missing: Missing = { apps: [], skills: [] };
  const items: {
    type: "app" | "bot" | "plugin" | "routine" | "scheme" | "skill" | "theme" | "wallpaper";
    id: string;
    status: "installed" | "approval_pending" | "skipped" | "failed" | "device";
    installed: InstallResult["installed"];
    error: string | null;
  }[] = [];
  // Bots first, so a set's routines can go to the bot it brings when no bot was picked.
  const order = (t: string) => ["bot", "skill", "plugin", "app", "routine"].indexOf(t);
  let botId = req.botId ?? null;
  for (const ref of [...set.items].sort((a, b) => order(a.type) - order(b.type))) {
    if (!WORKSPACE_KINDS.includes(ref.type as WorkspaceKind)) {
      items.push({
        ...(ref as { type: "skill"; id: string }),
        status: "device",
        installed: null,
        error: null,
      });
      continue;
    }
    if ((ref.type === "routine" || ref.type === "plugin") && !botId) {
      items.push({
        ...(ref as { type: "skill"; id: string }),
        status: "skipped",
        installed: null,
        error: "Needs a bot",
      });
      continue;
    }
    try {
      const r = await installGalleryItem(deps, call, claims, {
        orgId: req.orgId,
        type: ref.type as WorkspaceKind,
        id: ref.id,
        botId: ref.type === "skill" ? null : botId,
      });
      if (r.installed?.kind === "bot" && !botId) botId = r.installed.id;
      for (const a of r.missing.apps)
        if (!missing.apps.some((m) => m.id === a.id)) missing.apps.push(a);
      for (const s of r.missing.skills)
        if (!missing.skills.some((m) => m.id === s.id)) missing.skills.push(s);
      items.push({
        ...(ref as { type: "skill"; id: string }),
        status: r.status,
        installed: r.installed,
        error: null,
      });
    } catch (err) {
      const e = err as ApiError;
      items.push({
        ...(ref as { type: "skill"; id: string }),
        status: e.code === "skill_exists" ? "skipped" : "failed",
        installed: null,
        error: e.message,
      });
    }
  }
  await recordGalleryUse(deps.db, deps.env, claims.sub, "set", req.id).catch(() => {});
  return { items, missing };
}

// ---------------------------------------------------------------- approvals

type ApprovalRow = {
  id: string;
  org_id: string;
  item_type: WorkspaceKind | "pack";
  item_id: string;
  name: string;
  requested_by: string | null;
  requested_by_name: string | null;
  reason: string;
  status: "pending" | "approved" | "denied" | "failed";
  error: string | null;
  created_at: Date | string;
  decided_at: Date | string | null;
  inputs: Record<string, unknown>;
  bot_id: string | null;
};

const isoOf = (d: Date | string | null) => (d ? new Date(d).toISOString() : null);

export const approvalOut = (r: ApprovalRow) => ({
  id: r.id,
  org_id: r.org_id,
  // Older apps know five kinds; a pack shows as a plugin there, with `pack` for newer ones.
  type: (r.item_type === "pack" ? "plugin" : r.item_type) as WorkspaceKind,
  ...(r.item_type === "pack" ? { pack: true } : {}),
  item_id: r.item_id,
  name: r.name,
  requested_by: r.requested_by,
  requested_by_name: r.requested_by_name,
  reason: r.reason,
  status: r.status,
  error: r.error,
  created_at: isoOf(r.created_at) as string,
  decided_at: isoOf(r.decided_at),
});

const approvalSelect = sql`
  select a.*, coalesce(nullif(p.display_name, ''), u.email::text) as requested_by_name
  from public.gallery_approvals a
  left join auth.users u on u.id = a.requested_by left join public.profiles p on p.user_id = a.requested_by`;

export async function listGalleryApprovals(
  deps: Deps,
  claims: JwtClaims,
  orgId: string,
  status?: string,
) {
  const r = await requireMember(deps.db, claims, orgId);
  const rows = await deps.db.execute<ApprovalRow>(sql`${approvalSelect}
    where a.org_id = ${orgId}::uuid ${status ? sql`and a.status = ${status}` : sql``}
      ${r.admin ? sql`` : sql`and a.requested_by = ${claims.sub}::uuid`}
    order by a.created_at desc limit 200`);
  return rows.map(approvalOut);
}

export async function decideGalleryApproval(
  deps: Deps,
  call: InternalCall,
  claims: JwtClaims,
  id: string,
  decision: "approved" | "denied",
) {
  const [a] = await deps.db.execute<ApprovalRow>(sql`${approvalSelect} where a.id = ${id}::uuid`);
  if (!a) throw new ApiError(404, "approval_not_found", "Approval not found");
  const r = await role(deps.db, claims, a.org_id);
  if (!r.member) throw new ApiError(404, "approval_not_found", "Approval not found");
  if (!r.admin) throw new ApiError(403, "forbidden", "Only owners and admins approve these");
  const [claimed] = await deps.db.execute<{ id: string }>(sql`
    update public.gallery_approvals set status = ${decision}, decided_by = ${claims.sub}::uuid, decided_at = now()
    where id = ${id}::uuid and status = 'pending' returning id`);
  if (!claimed)
    throw new ApiError(409, "approval_already_decided", "This request was already decided");
  if (decision === "approved") {
    try {
      // Added by the approver (an admin skips the rules); the answers are the requester's.
      if (a.item_type === "pack") {
        const { packService } = await import("./packs.ts");
        await packService(deps as AppDeps).installApproved(claims, call, a.org_id, a.inputs);
      } else if (a.item_id.startsWith("repo/")) {
        // A plugin link: approving lets the person add it themselves now.
        const policy = await galleryPolicyFor(deps.db, a.org_id);
        if (!policy.allow.includes(a.item_id))
          await setGalleryPolicyFor(deps, claims, a.org_id, {
            ...policy,
            allow: [...policy.allow, a.item_id],
          });
      } else
        await installGalleryItem(
          deps,
          call,
          claims,
          {
            orgId: a.org_id,
            type: a.item_type,
            id: a.item_id,
            inputs: a.inputs as Record<string, string>,
            botId: a.bot_id,
          },
          { skipPolicy: true },
        );
    } catch (err) {
      await deps.db.execute(sql`
        update public.gallery_approvals set status = 'failed', error = ${String((err as Error).message).slice(0, 500)}
        where id = ${id}::uuid`);
    }
  }
  if (a.requested_by)
    await deps.db
      .execute(sql`
        insert into public.notifications (user_id, org_id, kind, payload, push_status, push_after)
        values (${a.requested_by}::uuid, ${a.org_id}::uuid, 'gallery_approval_decided',
                ${JSON.stringify({
                  title:
                    decision === "approved"
                      ? `${a.name} was approved`
                      : `${a.name} wasn't approved`,
                  body:
                    decision === "approved"
                      ? "It's been added to your workspace."
                      : "An admin declined it. Ask them if you need it.",
                  link:
                    decision === "approved" ? "/settings/gallery/installed" : "/settings/gallery",
                })}::jsonb, 'deferred', now())`)
      .catch(() => {});
  const [out] = await deps.db.execute<ApprovalRow>(sql`${approvalSelect} where a.id = ${id}::uuid`);
  return approvalOut(out as ApprovalRow);
}

// ---------------------------------------------------------------- installed, updates, removal

type LinkRow = {
  id: string;
  target_kind: WorkspaceKind;
  target_id: string;
  item_key: string;
  version: number;
  access: GalleryAccess;
  inputs: Record<string, string>;
  installed_at: Date | string;
};

/** Forgets links whose skill, bot, routine, connection or plugin is gone. */
async function pruneLinks(deps: Deps, orgId: string) {
  await deps.db.execute(sql`
    delete from public.gallery_links l where l.org_id = ${orgId}::uuid and not (
      (l.target_kind = 'skill' and exists (select 1 from public.skills s where s.id::text = l.target_id))
      or (l.target_kind = 'bot' and exists (select 1 from public.bots b where b.id::text = l.target_id and b.archived_at is null))
      or (l.target_kind = 'routine' and exists (select 1 from public.routines r where r.id::text = l.target_id))
      or (l.target_kind = 'app' and exists (select 1 from public.integrations i where i.id::text = l.target_id))
      or (l.target_kind = 'plugin' and exists (select 1 from public.plugins p where p.id::text = l.target_id)))`);
}

async function linksOf(deps: Deps, orgId: string, itemKey?: string) {
  return deps.db.execute<LinkRow>(sql`
    select id, target_kind, target_id, item_key, version, access, inputs, installed_at
    from public.gallery_links where org_id = ${orgId}::uuid
      ${itemKey ? sql`and item_key = ${itemKey}` : sql``}
    order by installed_at desc`);
}

const splitKey = (key: string) => {
  const i = key.indexOf("/");
  return { type: key.slice(0, i), id: key.slice(i + 1) };
};

export async function listGalleryInstalled(deps: Deps, claims: JwtClaims, orgId: string) {
  await requireMember(deps.db, claims, orgId);
  await pruneLinks(deps, orgId);
  const links = await linksOf(deps, orgId);
  if (!links.length) return [];
  const types = [...new Set(links.map((l) => splitKey(l.item_key).type))];
  const records = await galleryRecords(deps.env, types).catch(() => []);
  const byKey = new Map(records.map((r) => [galleryItemKey(r.type, r.id), r]));
  return links.map((l) => {
    const { type, id } = splitKey(l.item_key);
    const rec = byKey.get(l.item_key);
    const latest = rec && typeof rec.version === "number" ? rec.version : rec ? 1 : null;
    const changes = galleryChangesSince(
      rec?.changelog as { version: number; date: string; note: string; breaking?: boolean }[],
      l.version,
    );
    const replacement = rec?.replaced_by as { type: string; id: string } | undefined;
    return {
      type: type as WorkspaceKind,
      id,
      name: rec?.name ?? id,
      installed_version: l.version,
      latest_version: latest,
      update: latest != null && latest > l.version,
      breaking: changes.breaking,
      access_added: galleryAccessAdded(l.access, rec?.access as GalleryAccess | undefined),
      retired: !rec || rec.retired === true,
      ...(replacement ? { replacement } : {}),
      changelog: changes.entries,
      installed_at: new Date(l.installed_at).toISOString(),
      target: { kind: l.target_kind, id: l.target_id },
    };
  });
}

export async function updateGalleryInstalled(
  deps: Deps,
  call: InternalCall,
  claims: JwtClaims,
  req: { orgId: string; type: WorkspaceKind; id: string; acceptAccess?: boolean },
) {
  await requireMember(deps.db, claims, req.orgId);
  const key = galleryItemKey(req.type, req.id);
  await pruneLinks(deps, req.orgId);
  const links = await linksOf(deps, req.orgId, key);
  if (!links.length) throw new ApiError(404, "not_installed", "That item isn't installed here.");
  const rec = await galleryRecord(deps.env, req.type, req.id);
  if (!rec) throw new ApiError(404, "gallery_not_found", "That item isn't in the gallery anymore.");
  const latest = typeof rec.version === "number" ? rec.version : 1;
  const stale = links.filter((l) => l.version < latest);
  if (!stale.length) return { updated: 0, version: latest };
  const oldest = Math.min(...stale.map((l) => l.version));
  const changes = galleryChangesSince(
    rec.changelog as { version: number; breaking?: boolean }[],
    oldest,
  );
  const added = galleryAccessAdded(stale[0]?.access, rec.access as GalleryAccess | undefined);
  if ((galleryAccessGrew(added) || changes.breaking) && !req.acceptAccess)
    throw new ApiError(
      409,
      "access_changed",
      changes.breaking
        ? "This update changes how it works. Check what's new before updating."
        : "The new version can reach more than the one you have. Check what it can access before updating.",
      {
        errors: [
          ...added.reads.map((message) => ({ path: "reads", message })),
          ...added.writes.map((message) => ({ path: "writes", message })),
          ...(added.runs_code ? [{ path: "runs_code", message: "true" }] : []),
          ...(added.computer ? [{ path: "computer", message: "true" }] : []),
          ...(changes.breaking ? [{ path: "breaking", message: "true" }] : []),
        ],
      },
    );
  let updated = 0;
  for (const l of stale) {
    if (l.target_kind === "skill") {
      const { saveSkill } = await import("../api/routes/skills.ts");
      const [s] = await withUserSession(deps.db, claims, (tx) =>
        tx.execute<{ bot_id: string | null; source: string; category: string | null }>(sql`
          select bot_id, source, category from public.skills where id = ${l.target_id}::uuid`),
      );
      if (!s) continue;
      const fetched = await fetchGallerySkill(deps.env, req.id);
      await saveSkill(
        deps.db,
        claims,
        { orgId: req.orgId, botId: s.bot_id, skillId: l.target_id },
        fetched.bundle,
        {
          kind: s.source === "catalog" ? "catalog" : "gallery",
          ref: { id: req.id, sha256: fetched.sha256 },
          category: fetched.category ?? s.category,
        },
      );
    } else if (l.target_kind === "routine") {
      const r = routineFromRecord(rec, l.inputs);
      if (!r) throw new ApiError(502, "gallery_unavailable", "This routine can't be read.");
      await call("PATCH", `/v1/routines/${l.target_id}`, {
        instructions: r.instructions_md,
        schedule_cron: r.schedule_cron,
      });
    } else if (l.target_kind === "bot") {
      const t = botFromRecord(rec, l.inputs);
      if (!t) throw new ApiError(502, "gallery_unavailable", "This starter bot can't be read.");
      // Bots are edited through the database API under RLS; the same rule applies here.
      const done = await withUserSession(deps.db, claims, (tx) =>
        tx.execute<{ id: string }>(sql`
          update public.bots set persona_md = ${t.persona} where id = ${l.target_id}::uuid returning id`),
      );
      if (!done.length)
        throw new ApiError(403, "forbidden", "Only people who manage this bot can update it");
    } else if (l.target_kind === "plugin") {
      const doc = (rec.document ?? {}) as { commit?: string };
      if (doc.commit)
        await call("POST", `/v1/plugins/${l.target_id}/update`, { commit: doc.commit });
    }
    // Apps: the catalog entry is read live, so a newer one applies by itself.
    await deps.db.execute(sql`
      update public.gallery_links set version = ${latest}, access = ${JSON.stringify(rec.access ?? {})}::jsonb, updated_at = now()
      where id = ${l.id}::uuid`);
    updated++;
  }
  return { updated, version: latest };
}

export async function removeGalleryInstalled(
  deps: Deps,
  call: InternalCall,
  claims: JwtClaims,
  req: { orgId: string; type: WorkspaceKind; id: string },
) {
  await requireMember(deps.db, claims, req.orgId);
  const links = await linksOf(deps, req.orgId, galleryItemKey(req.type, req.id));
  if (!links.length) throw new ApiError(404, "not_installed", "That item isn't installed here.");
  const path: Partial<Record<WorkspaceKind, string>> = {
    routine: "/v1/routines/",
    app: "/v1/integrations/",
    plugin: "/v1/plugins/",
  };
  for (const l of links) {
    const route = path[l.target_kind];
    if (route) {
      try {
        await call("DELETE", `${route}${l.target_id}`);
      } catch (err) {
        if ((err as ApiError).status !== 404) throw err;
      }
    } else {
      // Skills and bots are changed through the database API under RLS (a bot is archived).
      const done = await withUserSession(deps.db, claims, (tx) =>
        l.target_kind === "skill"
          ? tx.execute<{ id: string }>(
              sql`delete from public.skills where id = ${l.target_id}::uuid returning id`,
            )
          : tx.execute<{ id: string }>(
              sql`update public.bots set archived_at = now() where id = ${l.target_id}::uuid returning id`,
            ),
      );
      const [still] = await deps.db.execute<{ ok: boolean }>(
        l.target_kind === "skill"
          ? sql`select exists(select 1 from public.skills where id = ${l.target_id}::uuid) as ok`
          : sql`select exists(select 1 from public.bots where id = ${l.target_id}::uuid and archived_at is null) as ok`,
      );
      if (!done.length && still?.ok)
        throw new ApiError(403, "forbidden", "You can't remove this one; ask an admin.");
    }
    await deps.db.execute(sql`delete from public.gallery_links where id = ${l.id}::uuid`);
  }
}
