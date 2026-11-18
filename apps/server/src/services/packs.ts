/**
 * Packs (docs/PLUGINS-AND-PACKS-PLAN.md): a plugin with a `com.casama/` folder that brings bots,
 * skills, routines, apps and looks to a workspace.
 *
 * Installing makes ordinary rows: bots through the bots route (limits and model policy apply),
 * skills under the person's own permissions, routines through the routines route, and the
 * plugin's tools as per-bot plugin rows marked with the pack. pack_items remembers what each
 * item became, with a hash of what a person can edit, so updates keep their changes and removal
 * keeps what they made their own.
 */
import { createHash, randomBytes } from "node:crypto";
import type { GalleryPack } from "@casama/contracts";
import { type JwtClaims, pgErrorCode, withUserSession } from "@casama/db";
import {
  buildPackFiles,
  type CheckedPack,
  checkGalleryInputValues,
  cronRunsPerWeek,
  diffPacks,
  fillGalleryText,
  fillPackBot,
  fillPackRoutine,
  findSecretsInFiles,
  galleryInputDefaults,
  type PackBot,
  type PackExportSkill,
  type PackInclude,
  type PackRoutine,
  type PackSnapshot,
  packItemHash,
  packSlug,
  packSnapshot,
  packTitle,
} from "@casama/domain";
import { sql } from "drizzle-orm";
import type { z } from "zod";
import { ApiError } from "../api/errors.ts";
import type { AppDeps } from "../api/types.ts";
import { iso } from "../api/util.ts";
import { appLink } from "../env.ts";
import { galleryPlugins, galleryRecord, gallerySets } from "./gallery.ts";
import {
  createGalleryApproval,
  galleryDecision,
  type InternalCall,
  installGalleryItem,
  repoPolicyKey,
  requireMember,
  type WorkspaceKind,
} from "./gallery-install.ts";
import { recordGalleryUse } from "./gallery-usage.ts";
import { packAppId } from "./pack-apps.ts";
import { knownApps, type LoadedPlugin, pluginInstaller } from "./plugin-install.ts";
import { type GitHubRef, parseGitHubUrl } from "./skills.ts";

type Kind = "bot" | "skill" | "routine" | "app" | "look" | "tools" | "include";
type ItemStatus = "installed" | "approval_pending" | "skipped" | "failed" | "device";

export interface PackFrom {
  url?: string;
  commit?: string;
  gallery_id?: string;
  share_token?: string;
  files?: Array<{ path: string; base64: string; executable?: boolean }>;
}

export interface InstallPackBody extends PackFrom {
  org_id: string;
  skip?: Array<{ kind: Kind; id: string }>;
  inputs?: Record<string, string>;
  secrets?: Record<string, string>;
  settings?: Record<string, string>;
  bot_id?: string;
  routines_on?: boolean;
  /** Run plugin tools on this computer of the installer's (D-344). */
  device_id?: string;
}

type Source = {
  kind: "github" | "gallery" | "share" | "upload";
  owner?: string;
  repo?: string;
  path?: string;
  ref?: string | null;
  url?: string;
  gallery_id?: string;
};

type Resolved = {
  l: LoadedPlugin & { checked: LoadedPlugin["checked"] & { pack: CheckedPack } };
  source: Source;
  reviewed: boolean;
};

type StoredContent = {
  document: CheckedPack["document"];
  bots: PackBot[];
  routines: PackRoutine[];
  apps: CheckedPack["apps"];
  looks: CheckedPack["looks"];
  workspaceSkills: string[];
  reach: CheckedPack["reach"];
  snapshot: PackSnapshot;
  skills: Array<{ name: string; description: string }>;
};

type PackRow = {
  id: string;
  org_id: string;
  name: string;
  version: string | null;
  description: string;
  summary: string;
  icon: string;
  source: Source;
  commit_sha: string | null;
  reviewed: boolean;
  content: StoredContent;
  inputs: Record<string, string>;
  installed_at: Date | string;
  updated_at: Date | string;
};

type ItemRow = {
  id: string;
  kind: Exclude<Kind, "tools">;
  item_id: string;
  target_id: string | null;
  bot_id: string | null;
  content_hash: string | null;
};

const sha256 = (s: string) => createHash("sha256").update(s).digest("hex");
const itemKey = (kind: string, id: string) => `${kind}:${id}`;

/** Gallery-checked pack contents by commit, for the shelf (a commit never changes). */
const shelfCache = new Map<string, GalleryContents | null>();
type GalleryContents = {
  summary: string;
  icon: string;
  bots: number;
  skills: number;
  routines: number;
  apps: number;
  looks: number;
  tools: number;
};

export function packService(deps: AppDeps) {
  const { db } = deps;
  const plugins = pluginInstaller(deps);

  // ---------------------------------------------------------------- where a pack comes from

  const resolve = async (from: PackFrom, orgId?: string): Promise<Resolved> => {
    const given = [from.url, from.gallery_id, from.share_token, from.files].filter(
      (x) => x !== undefined,
    );
    if (given.length !== 1)
      throw new ApiError(
        400,
        "validation_failed",
        "Give one of url, gallery_id, share_token or files",
      );
    let l: LoadedPlugin;
    let source: Source;
    let reviewed = false;
    if (from.gallery_id) {
      const listed = (await galleryPlugins(deps.env)).find((p) => p.id === from.gallery_id);
      if (!listed) throw new ApiError(404, "gallery_not_found", "That pack isn't in the gallery.");
      const ref = parseGitHubUrl(listed.url);
      l = await plugins.load(ref, from.commit ?? listed.commit, orgId);
      reviewed = l.commit === listed.commit;
      source = { kind: "gallery", ...refSource(ref), url: listed.url, gallery_id: listed.id };
    } else if (from.url) {
      const ref = parseGitHubUrl(from.url);
      l = await plugins.load(ref, from.commit ?? null, orgId);
      const listed = (await galleryPlugins(deps.env).catch(() => [])).find(
        (p) => p.url.replace(/\/$/, "") === from.url?.replace(/\/$/, "") && p.commit === l.commit,
      );
      reviewed = !!listed;
      source = listed
        ? { kind: "gallery", ...refSource(ref), url: listed.url, gallery_id: listed.id }
        : { kind: "github", ...refSource(ref), url: from.url };
    } else if (from.share_token) {
      const share = await shareByToken(from.share_token);
      l = await plugins.loadFiles(share.files);
      source = { kind: "share" };
    } else {
      l = await plugins.loadFiles(from.files ?? []);
      source = { kind: "upload" };
    }
    if (!l.checked.pack)
      throw new ApiError(
        400,
        "pack_not_a_pack",
        l.checked.warnings.find((w) => w.startsWith("Installed as a plain plugin")) ??
          "This is a plain plugin, not a pack: add it to a bot from the bot's Plugins page.",
      );
    return { l: l as Resolved["l"], source, reviewed };
  };

  const refSource = (ref: GitHubRef) => ({
    owner: ref.owner,
    repo: ref.repo,
    path: ref.path,
    ref: ref.ref,
  });

  const shareByToken = async (token: string) => {
    const [s] = await db.execute<{
      id: string;
      org_id: string;
      created_by: string | null;
      files: Array<{ path: string; base64: string; executable?: boolean }>;
      expires_at: Date | string;
    }>(sql`
      select id, org_id, created_by, files, expires_at from public.pack_shares
      where token_hash = ${sha256(token)} and taken_down_at is null and expires_at > now()`);
    if (!s)
      throw new ApiError(404, "pack_share_not_found", "This pack link has expired or was removed.");
    return s;
  };

  // ---------------------------------------------------------------- preview

  const buildPreview = async (r: Resolved, orgId?: string) => {
    const { l, source, reviewed } = r;
    const p = l.checked.pack;
    const m = l.checked.manifest;
    const base = plugins.preview(l);
    const defaults = galleryInputDefaults(p.document.inputs);
    const known = await knownApps(deps);
    const nameOf = (id: string) =>
      known.find((a) => a.id === id || a.id === id.replaceAll("-", "_"))?.name ?? id;
    const sets = new Map<string, boolean>();
    const includes = [];
    for (const inc of p.document.includes) {
      if ("url" in inc) {
        const listed = (await galleryPlugins(deps.env).catch(() => [])).find(
          (x) => x.url.replace(/\/$/, "") === inc.url.replace(/\/$/, ""),
        );
        includes.push({
          type: "plugin",
          id: null,
          url: inc.url,
          commit: inc.commit,
          name: listed?.name ?? inc.url.replace(/^https:\/\/github\.com\//, ""),
          found: true,
        });
      } else {
        const rec = await galleryRecord(deps.env, inc.type, inc.id).catch(() => undefined);
        sets.set(itemKey(inc.type, inc.id), !!rec);
        includes.push({
          type: inc.type,
          id: inc.id,
          url: null,
          commit: null,
          name: rec?.name ?? inc.id,
          found: !!rec,
        });
      }
    }
    const installed = orgId
      ? (
          await db.execute<{ id: string; version: string | null; commit_sha: string | null }>(sql`
            select id, version, commit_sha from public.packs where org_id = ${orgId}::uuid and name = ${m.name}`)
        )[0]
      : undefined;
    return {
      name: m.name,
      title: packTitle(p.document, m.name),
      version: m.version ?? null,
      description: m.description ?? "",
      summary: p.document.summary,
      icon: p.document.icon,
      author: m.author?.name ?? null,
      license: m.license ?? null,
      homepage: m.homepage ?? null,
      source: {
        kind: source.kind,
        repo: source.owner ? `${source.owner}/${source.repo}` : null,
        path: source.path ?? null,
        url: source.url ?? null,
        gallery_id: source.gallery_id ?? null,
      },
      commit: l.commit,
      reviewed,
      bots: p.bots.map((b) => ({
        id: b.id,
        // Names and descriptions read with the default answers; the instructions keep their
        // {{placeholders}} so people see where their answers go.
        name: fillGalleryText(b.name, defaults),
        description: fillGalleryText(b.description, defaults),
        icon: b.icon,
        mascot: b.mascot,
        autonomy: b.autonomy,
        persona: b.persona,
        starters: b.starters,
        skills: b.skills,
        routines: b.routines,
        tools: b.tools,
        rules: b.rules,
        knowledge: b.knowledge,
      })),
      routines: p.routines.map((rt) => ({
        id: rt.id,
        name: fillGalleryText(rt.name, defaults),
        description: fillGalleryText(rt.description, defaults),
        instructions_md: rt.instructions_md,
        schedule_cron: rt.schedule_cron,
        bot: p.bots.find((b) => b.routines.includes(rt.id))?.id ?? null,
        runs_per_week: cronRunsPerWeek(fillPackRoutine(rt, defaults).schedule_cron),
      })),
      skills: l.skills.map((s) => ({
        name: s.name,
        description: s.description,
        scope: p.workspaceSkills.includes(s.name) ? ("workspace" as const) : ("bot" as const),
        bots: p.bots.filter((b) => b.skills.includes(s.name)).map((b) => b.id),
        runs_scripts: s.files.some((f) => f.executable || /\.(sh|py|js|mjs|ts|rb)$/.test(f.path)),
      })),
      apps: p.apps.map((a) => {
        let host = "";
        try {
          host = new URL(a.doc.url).host;
        } catch {}
        return {
          id: packAppId(m.name, a.id),
          name: a.name,
          description: a.doc.description,
          host,
          url: a.doc.url,
          auth: [...a.doc.auth],
          capabilities: a.doc.capabilities,
          color: a.doc.color,
        };
      }),
      looks: p.looks.map((k) => ({ type: k.type, id: k.id, name: k.name, document: k.document })),
      includes,
      servers: base.servers,
      secrets: base.secrets,
      settings: base.settings,
      inputs: p.document.inputs,
      needs_apps: p.document.needs.apps.map((id) => ({ id, name: nameOf(id) })),
      examples: p.document.examples,
      reach: p.reach,
      warnings: [...new Set(l.checked.warnings)],
      installed: installed
        ? { id: installed.id, version: installed.version, commit: installed.commit_sha }
        : null,
    };
  };

  const preview = async (claims: JwtClaims, body: PackFrom & { org_id: string }) => {
    await requireMember(db, claims, body.org_id);
    return buildPreview(await resolve(body, body.org_id), body.org_id);
  };

  // ---------------------------------------------------------------- the policy for a pack

  const policyKey = (r: Resolved) =>
    r.source.gallery_id
      ? { type: "plugin", id: r.source.gallery_id }
      : r.source.owner
        ? repoPolicyKey({ owner: r.source.owner, repo: r.source.repo ?? "" })
        : { type: "pack", id: packSlug(r.l.checked.manifest.name).replaceAll(".", "-") };

  // ---------------------------------------------------------------- what the person edited

  const botHash = (b: { name: string; persona_md: string; autonomy: string }) =>
    packItemHash([b.name, b.persona_md, b.autonomy]);
  const skillHash = (s: { name: string; description: string; body_md: string }) =>
    packItemHash([s.name, s.description, s.body_md]);
  const routineHash = (r: {
    name: string;
    instructions_md: string;
    schedule_cron: string | null;
  }) => packItemHash([r.name, r.instructions_md, r.schedule_cron]);

  /** The current hash of what an item became (null when it's gone). */
  const currentHash = async (i: ItemRow): Promise<string | null> => {
    if (!i.target_id) return null;
    if (i.kind === "bot") {
      const [b] = await db.execute<{ name: string; persona_md: string; autonomy: string }>(sql`
        select name, persona_md, autonomy::text as autonomy from public.bots
        where id::text = ${i.target_id} and archived_at is null`);
      return b ? botHash(b) : null;
    }
    if (i.kind === "skill") {
      const [s] = await db.execute<{ name: string; description: string; body_md: string }>(
        sql`select name, description, body_md from public.skills where id::text = ${i.target_id}`,
      );
      return s ? skillHash(s) : null;
    }
    if (i.kind === "routine") {
      const [r] = await db.execute<{
        name: string;
        instructions_md: string;
        schedule_cron: string | null;
      }>(
        sql`select name, instructions_md, schedule_cron from public.routines where id::text = ${i.target_id}`,
      );
      return r ? routineHash(r) : null;
    }
    return i.content_hash;
  };

  const edited = async (i: ItemRow) => {
    if (!i.content_hash || !["bot", "skill", "routine"].includes(i.kind)) return false;
    const h = await currentHash(i);
    return h !== null && h !== i.content_hash;
  };

  const itemsOf = (packId: string) =>
    db.execute<ItemRow>(sql`
      select id, kind, item_id, target_id, bot_id, content_hash from public.pack_items
      where pack_id = ${packId}::uuid order by kind, item_id`);

  // ---------------------------------------------------------------- output

  const sourceOut = (s: Source) => ({
    kind: s.kind,
    repo: s.owner ? `${s.owner}/${s.repo}` : null,
    path: s.path ?? null,
    url: s.url ?? null,
    gallery_id: s.gallery_id ?? null,
  });

  const packOut = async (row: PackRow) => {
    const items = await itemsOf(row.id);
    const names = new Map<string, string>();
    for (const b of row.content.bots ?? []) names.set(itemKey("bot", b.id), b.name);
    for (const r of row.content.routines ?? []) names.set(itemKey("routine", r.id), r.name);
    for (const a of row.content.apps ?? []) names.set(itemKey("app", a.id), a.name);
    for (const k of row.content.looks ?? [])
      names.set(itemKey("look", `${k.type}/${k.id}`), k.name);
    return {
      id: row.id,
      org_id: row.org_id,
      name: row.name,
      title: packTitle(row.content.document, row.name),
      version: row.version,
      description: row.description,
      summary: row.summary,
      icon: row.icon,
      source: sourceOut(row.source),
      commit: row.commit_sha,
      reviewed: row.reviewed,
      items: await Promise.all(
        items.map(async (i) => ({
          kind: i.kind,
          id: i.item_id,
          name: names.get(itemKey(i.kind, i.item_id)) ?? i.item_id,
          target_id: i.target_id,
          bot_id: i.bot_id,
          edited: await edited(i),
        })),
      ),
      installed_at: iso(row.installed_at),
      updated_at: iso(row.updated_at),
    };
  };

  const stored = async (claims: JwtClaims, id: string) => {
    const [row] = await withUserSession(db, claims, (tx) =>
      tx.execute<PackRow>(sql`select * from public.packs where id = ${id}::uuid`),
    );
    if (!row) throw new ApiError(404, "pack_not_found", "Pack not found");
    return row;
  };

  const list = async (claims: JwtClaims, orgId: string) => {
    await requireMember(db, claims, orgId);
    const rows = await db.execute<PackRow>(
      sql`select * from public.packs where org_id = ${orgId}::uuid order by name`,
    );
    return Promise.all(rows.map(packOut));
  };

  const get = async (claims: JwtClaims, id: string) => packOut(await stored(claims, id));

  // ---------------------------------------------------------------- making the items

  type Ctx = {
    claims: JwtClaims;
    call: InternalCall;
    orgId: string;
    packId: string;
    r: Resolved;
    values: Record<string, string>;
    skip: Set<string>;
    secrets: Record<string, string>;
    settings: Record<string, string>;
    /** Where new plugin tools' stdio servers run (D-344): the installer's own computer, or null. */
    deviceId: string | null;
    botId: string | null;
    routinesOn: boolean;
    /** What's already there (an update): by kind:item_id[:bot]. */
    existing: Map<string, ItemRow>;
    /** Edited items to replace anyway. */
    takeTheirs: Set<string>;
    items: Array<{
      kind: Kind;
      id: string;
      name: string;
      status: ItemStatus;
      target_id: string | null;
      error: string | null;
    }>;
  };

  const record = async (
    c: Ctx,
    kind: ItemRow["kind"],
    itemId: string,
    targetId: string | null,
    hash: string | null,
    botId: string | null = null,
  ) => {
    await db.execute(sql`
      insert into public.pack_items (pack_id, org_id, kind, item_id, target_id, bot_id, content_hash)
      values (${c.packId}::uuid, ${c.orgId}::uuid, ${kind}, ${itemId}, ${targetId}, ${botId}::uuid, ${hash})
      on conflict (pack_id, kind, item_id, coalesce(bot_id, '00000000-0000-0000-0000-000000000000'::uuid))
      do update set target_id = excluded.target_id, content_hash = excluded.content_hash, updated_at = now()`);
  };

  const existingKey = (kind: string, id: string, botId?: string | null) =>
    `${kind}:${id}:${botId ?? ""}`;

  /** Whether to leave an existing item alone: the person edited it and didn't ask for ours. */
  const keepTheirs = async (c: Ctx, row: ItemRow) =>
    (await edited(row)) && !c.takeTheirs.has(itemKey(row.kind, row.item_id));

  const fail = (err: unknown) => {
    const e = err as ApiError;
    if (e.status === 403 || pgErrorCode(err) === "42501")
      return { status: "skipped" as const, error: "Needs an admin" };
    if (e.code === "skill_exists" || e.status === 409)
      return { status: "skipped" as const, error: e.message || "Already there" };
    if (e.code === "approval_pending") return { status: "approval_pending" as const, error: null };
    return { status: "failed" as const, error: e.message ?? String(err) };
  };

  const makeBots = async (c: Ctx) => {
    const map = new Map<string, string>();
    for (const raw of c.r.l.checked.pack.bots) {
      const b = fillPackBot(raw, c.values);
      const prev = c.existing.get(existingKey("bot", b.id));
      if (prev?.target_id) map.set(b.id, prev.target_id);
      if (c.skip.has(itemKey("bot", b.id))) {
        if (!prev) c.items.push(item("bot", b.id, b.name, "skipped", null, null));
        continue;
      }
      const hash = botHash({ name: b.name, persona_md: b.persona, autonomy: b.autonomy });
      try {
        if (prev?.target_id && (await currentHash(prev)) !== null) {
          if (await keepTheirs(c, prev)) {
            c.items.push(item("bot", b.id, b.name, "skipped", prev.target_id, "You changed it"));
            continue;
          }
          const [ok] = await withUserSession(db, c.claims, (tx) =>
            tx.execute<{ id: string }>(sql`
              update public.bots set name = ${b.name}, persona_md = ${b.persona}, autonomy = ${b.autonomy}::public.bot_autonomy
              where id = ${prev.target_id}::uuid returning id`),
          );
          if (!ok) throw new ApiError(403, "forbidden", "Needs someone who manages the bot");
          await record(c, "bot", b.id, prev.target_id, hash);
          c.items.push(item("bot", b.id, b.name, "installed", prev.target_id, null));
          continue;
        }
        const row = await c.call("POST", "/v1/bots", {
          org_id: c.orgId,
          name: b.name,
          persona_md: b.persona,
          autonomy: b.autonomy,
        });
        const id = String(row?.id);
        if (b.mascot)
          await db.execute(
            sql`update public.bots set avatar_url = ${`mascot:${b.mascot}`} where id = ${id}::uuid`,
          );
        map.set(b.id, id);
        await record(c, "bot", b.id, id, hash);
        const extras = await botExtras(c, id, b);
        c.items.push(item("bot", b.id, b.name, "installed", id, extras));
      } catch (err) {
        const f = fail(err);
        c.items.push(item("bot", b.id, b.name, f.status, null, f.error));
      }
    }
    return map;
  };

  /**
   * A new bot's rules (they only narrow: ask first or hand off) and knowledge sources, through
   * the same routes a person uses. What didn't work comes back as a note on the bot's line.
   */
  const botExtras = async (c: Ctx, botId: string, b: PackBot): Promise<string | null> => {
    const notes: string[] = [];
    for (const r of b.rules ?? []) {
      try {
        await c.call("POST", "/v1/action-rules", { org_id: c.orgId, bot_id: botId, ...r });
      } catch (err) {
        notes.push(`Rule for ${r.match_value}: ${(err as Error).message}`);
      }
    }
    for (const k of b.knowledge ?? []) {
      try {
        await c.call("POST", "/v1/knowledge-sources", {
          org_id: c.orgId,
          bot_id: botId,
          kind: k.kind,
          name: k.name,
          ...(k.kind === "website" ? { url: k.url, max_pages: k.max_pages } : { repo_url: k.url }),
        });
      } catch (err) {
        notes.push(`Knowledge ${k.name}: ${(err as Error).message}`);
      }
    }
    return notes.length ? notes.join("; ").slice(0, 500) : null;
  };

  const item = (
    kind: Kind,
    id: string,
    name: string,
    status: ItemStatus,
    target_id: string | null,
    error: string | null,
  ) => ({ kind, id, name, status, target_id, error });

  const makeSkills = async (c: Ctx, bots: Map<string, string>) => {
    const { saveSkill } = await import("../api/routes/skills.ts");
    const p = c.r.l.checked.pack;
    for (const s of c.r.l.skills) {
      if (c.skip.has(itemKey("skill", s.name))) {
        c.items.push(item("skill", s.name, s.name, "skipped", null, null));
        continue;
      }
      const targets: Array<string | null> = p.workspaceSkills.includes(s.name)
        ? [null]
        : p.bots
            .filter((b) => b.skills.includes(s.name))
            .map((b) => bots.get(b.id) ?? null)
            .filter((x): x is string => !!x);
      if (!targets.length && c.botId) targets.push(c.botId);
      if (!targets.length) {
        c.items.push(item("skill", s.name, s.name, "skipped", null, "Needs a bot"));
        continue;
      }
      for (const botId of targets) {
        const prev = c.existing.get(existingKey("skill", s.name, botId));
        try {
          let skillId: string | undefined;
          if (prev?.target_id && (await currentHash(prev)) !== null) {
            if (await keepTheirs(c, prev)) {
              c.items.push(
                item("skill", s.name, s.name, "skipped", prev.target_id, "You changed it"),
              );
              continue;
            }
            skillId = prev.target_id;
          }
          const row = await saveSkill(
            db,
            c.claims,
            { orgId: c.orgId, botId, ...(skillId ? { skillId } : {}) },
            s,
            {
              kind: c.r.source.owner ? "github" : "manual",
              ref: { pack: c.r.l.checked.manifest.name, pack_id: c.packId, commit: c.r.l.commit },
              category: null,
            },
          );
          await record(
            c,
            "skill",
            s.name,
            row.id,
            skillHash({ name: s.name, description: s.description, body_md: s.body }),
            botId,
          );
          c.items.push(item("skill", s.name, s.name, "installed", row.id, null));
        } catch (err) {
          const f = fail(err);
          c.items.push(item("skill", s.name, s.name, f.status, null, f.error));
        }
      }
    }
  };

  const makeRoutines = async (c: Ctx, bots: Map<string, string>) => {
    const p = c.r.l.checked.pack;
    for (const raw of p.routines) {
      const rt = fillPackRoutine(raw, c.values);
      if (c.skip.has(itemKey("routine", rt.id))) {
        c.items.push(item("routine", rt.id, rt.name, "skipped", null, null));
        continue;
      }
      const owner = p.bots.find((b) => b.routines.includes(rt.id));
      const botId =
        (owner ? bots.get(owner.id) : undefined) ?? c.botId ?? [...bots.values()][0] ?? null;
      if (!botId) {
        c.items.push(item("routine", rt.id, rt.name, "skipped", null, "Needs a bot"));
        continue;
      }
      const prev = c.existing.get(existingKey("routine", rt.id));
      const hash = routineHash(rt);
      try {
        if (prev?.target_id && (await currentHash(prev)) !== null) {
          if (await keepTheirs(c, prev)) {
            c.items.push(
              item("routine", rt.id, rt.name, "skipped", prev.target_id, "You changed it"),
            );
            continue;
          }
          await c.call("PATCH", `/v1/routines/${prev.target_id}`, {
            name: rt.name,
            instructions: rt.instructions_md,
            schedule_cron: rt.schedule_cron,
          });
          await record(c, "routine", rt.id, prev.target_id, hash);
          c.items.push(item("routine", rt.id, rt.name, "installed", prev.target_id, null));
          continue;
        }
        const row = await c.call("POST", "/v1/routines", {
          bot_id: botId,
          name: rt.name,
          instructions: rt.instructions_md,
          trigger: "schedule",
          schedule_cron: rt.schedule_cron,
          ...(c.values.timezone ? { timezone: c.values.timezone } : {}),
        });
        const id = String(row?.id);
        // Unreviewed packs start their routines off; reviewed ones on unless the person said no.
        if (!c.routinesOn) await c.call("PATCH", `/v1/routines/${id}`, { enabled: false });
        await record(c, "routine", rt.id, id, hash);
        c.items.push(item("routine", rt.id, rt.name, "installed", id, null));
      } catch (err) {
        const f = fail(err);
        c.items.push(item("routine", rt.id, rt.name, f.status, null, f.error));
      }
    }
  };

  /** The plugin's servers and files, as a plugin row on each bot that uses its tools. */
  const makeTools = async (c: Ctx, bots: Map<string, string>) => {
    const l = c.r.l;
    const hasTools =
      l.checked.servers.length > 0 ||
      l.files.some(
        (f) =>
          !f.path.startsWith("skills/") &&
          !f.path.startsWith("com.casama/") &&
          !/^(\.claude-plugin\/)?plugin\.json$|^README|^LICENSE|^mcp\.json$|^\.mcp\.json$/i.test(
            f.path,
          ),
      );
    if (!l.checked.servers.length || !hasTools) return;
    const name = `${l.checked.manifest.name} tools`;
    if (c.skip.has(itemKey("tools", "tools"))) {
      c.items.push(item("tools", "tools", name, "skipped", null, null));
      return;
    }
    const p = l.checked.pack;
    let targets = p.bots
      .filter((b) => b.tools.length)
      .map((b) => bots.get(b.id))
      .filter((x): x is string => !!x);
    if (!targets.length) targets = [...bots.values()];
    if (!targets.length && c.botId) targets = [c.botId];
    if (!targets.length) {
      c.items.push(item("tools", "tools", name, "skipped", null, "Needs a bot"));
      return;
    }
    const current = await db.execute<{ id: string; bot_id: string }>(
      sql`select id, bot_id from public.plugins where pack_id = ${c.packId}::uuid`,
    );
    for (const botId of [...new Set(targets)]) {
      try {
        await plugins.manageable(c.claims, botId);
        const prev = current.find((x) => x.bot_id === botId);
        const kept = prev ? await plugins.currentSecrets(prev.id, l.checked) : {};
        const keptSettings = prev ? await plugins.currentSettings(c.claims, prev.id) : {};
        const known = new Set(l.checked.settings.map((s) => s.name));
        const id = await plugins.apply(
          c.claims,
          { orgId: c.orgId, botId, ...(prev ? { pluginId: prev.id } : {}) },
          l,
          { ...kept, ...c.secrets },
          {
            packId: c.packId,
            skipSkills: true,
            // An update keeps where the tools run; a new install puts them where the person chose.
            ...(prev ? {} : { deviceId: c.deviceId }),
            settings: Object.fromEntries(
              Object.entries({ ...keptSettings, ...c.settings }).filter(([k]) => known.has(k)),
            ),
            source: c.r.source.owner
              ? refSource({
                  owner: c.r.source.owner,
                  repo: c.r.source.repo ?? "",
                  path: c.r.source.path ?? "",
                  ref: c.r.source.ref ?? null,
                })
              : { owner: "", repo: "", path: "", ref: null },
          },
        );
        await plugins.listTools(id, botId);
        c.items.push(item("tools", "tools", name, "installed", id, null));
      } catch (err) {
        const f = fail(err);
        c.items.push(item("tools", "tools", name, f.status, null, f.error));
      }
    }
  };

  const makeIncludes = async (c: Ctx, bots: Map<string, string>) => {
    const firstBot = [...bots.values()][0] ?? c.botId ?? null;
    for (const inc of c.r.l.checked.pack.document.includes as PackInclude[]) {
      const id = "url" in inc ? inc.url : `${inc.type}/${inc.id}`;
      if (c.existing.has(existingKey("include", id))) continue;
      if (c.skip.has(itemKey("include", id))) {
        c.items.push(item("include", id, id, "skipped", null, null));
        continue;
      }
      try {
        if ("url" in inc) {
          if (!firstBot) {
            c.items.push(item("include", id, id, "skipped", null, "Needs a bot"));
            continue;
          }
          await plugins.manageable(c.claims, firstBot);
          const l = await plugins.load(parseGitHubUrl(inc.url), inc.commit, c.orgId);
          const pid = await plugins.apply(
            c.claims,
            { orgId: c.orgId, botId: firstBot },
            l,
            c.secrets,
            { packId: c.packId, deviceId: c.deviceId },
          );
          await plugins.listTools(pid, firstBot);
          await record(c, "include", id, pid, null, firstBot);
          c.items.push(item("include", id, l.checked.manifest.name, "installed", pid, null));
          continue;
        }
        if (["theme", "scheme", "wallpaper"].includes(inc.type)) {
          c.items.push(item("include", id, id, "device", null, null));
          continue;
        }
        if ((inc.type === "routine" || inc.type === "plugin") && !firstBot) {
          c.items.push(item("include", id, id, "skipped", null, "Needs a bot"));
          continue;
        }
        const r = await installGalleryItem(deps, c.call, c.claims, {
          orgId: c.orgId,
          type: inc.type as WorkspaceKind,
          id: inc.id,
          botId: inc.type === "skill" || inc.type === "bot" || inc.type === "app" ? null : firstBot,
        });
        if (r.installed) await record(c, "include", id, r.installed.id, null);
        c.items.push(item("include", id, id, r.status, r.installed?.id ?? null, null));
      } catch (err) {
        const f = fail(err);
        c.items.push(item("include", id, id, f.status, null, f.error));
      }
    }
  };

  /** Needed apps the workspace hasn't connected, and the pack's own apps. */
  const missingApps = async (orgId: string, packName: string, r: Resolved) => {
    const rows = await db.execute<{ app: string | null; name: string }>(sql`
      select config ->> 'app' as app, name from public.integrations where org_id = ${orgId}::uuid and status <> 'error'`);
    const have = new Set(rows.flatMap((x) => [x.app ?? "", x.name]));
    const known = await knownApps(deps);
    const out: Array<{ id: string; name: string }> = [];
    for (const id of r.l.checked.pack.document.needs.apps)
      if (!have.has(id) && !have.has(id.replaceAll("-", "_")))
        out.push({ id, name: known.find((a) => a.id === id)?.name ?? id });
    for (const a of r.l.checked.pack.apps) {
      const id = packAppId(packName, a.id);
      if (!have.has(id)) out.push({ id, name: a.name });
    }
    return out;
  };

  const contentOf = (r: Resolved): StoredContent => {
    const p = r.l.checked.pack;
    return {
      document: p.document,
      bots: p.bots,
      routines: p.routines,
      apps: p.apps,
      looks: p.looks,
      workspaceSkills: p.workspaceSkills,
      reach: p.reach,
      snapshot: packSnapshot(
        p,
        r.l.checked,
        r.l.skills.map((s) => ({ name: s.name, md: s.skillMd })),
      ),
      skills: r.l.skills.map((s) => ({ name: s.name, description: s.description })),
    };
  };

  const writeFiles = async (packId: string, orgId: string, r: Resolved) => {
    await db.execute(sql`delete from public.pack_files where pack_id = ${packId}::uuid`);
    for (const f of r.l.files)
      await db.execute(sql`
        insert into public.pack_files (pack_id, org_id, path, content, executable)
        values (${packId}::uuid, ${orgId}::uuid, ${f.path}, decode(${f.content.toString("base64")}, 'base64'), ${f.executable})`);
  };

  // ---------------------------------------------------------------- install

  const install = async (
    claims: JwtClaims,
    call: InternalCall,
    body: InstallPackBody,
    opts: { skipPolicy?: boolean } = {},
  ) => {
    await requireMember(db, claims, body.org_id);
    const r = await resolve(body, body.org_id);
    const p = r.l.checked.pack;
    const m = r.l.checked.manifest;
    const checked = checkGalleryInputValues(p.document.inputs, body.inputs);
    const bad = Object.entries(checked.errors);
    if (bad.length)
      throw new ApiError(400, "inputs_invalid", "Some answers don't fit the questions.", {
        errors: bad.map(([path, message]) => ({ path: `inputs.${path}`, message })),
      });
    const [already] = await db.execute<{ id: string }>(
      sql`select id from public.packs where org_id = ${body.org_id}::uuid and name = ${m.name}`,
    );
    if (already)
      throw new ApiError(
        409,
        "pack_installed",
        `${packTitle(r.l.checked.pack.document, m.name)} is already here: update it instead.`,
      );
    if (!opts.skipPolicy) {
      const key = policyKey(r);
      const d = await galleryDecision(deps, claims, body.org_id, key.type, key.id, {
        runs_code: p.reach.runs_code,
        computer: p.reach.computer,
      } as never);
      if (d.decision === "block") throw new ApiError(403, "gallery_blocked", d.reason);
      if (d.decision === "approval") {
        // The whole request waits, except its secrets: the approver adds those later.
        const { secrets: _s, ...request } = body;
        const approvalId = await createGalleryApproval(deps, {
          orgId: body.org_id,
          userId: claims.sub,
          type: "pack",
          id: `${key.type}/${key.id}`,
          name: m.name,
          inputs: { request },
          botId: body.bot_id ?? null,
          reason: d.reason,
        });
        return {
          status: "approval_pending" as const,
          approval_id: approvalId,
          items: [],
          missing: { apps: [], skills: [] },
          looks: [],
        };
      }
    }
    const [row] = await db.execute<{ id: string }>(sql`
      insert into public.packs (org_id, name, version, description, summary, icon, source, commit_sha, reviewed, content, inputs, installed_by)
      values (${body.org_id}::uuid, ${m.name}, ${m.version ?? null}, ${(m.description ?? "").slice(0, 2000)},
              ${p.document.summary.slice(0, 200)}, ${p.document.icon}, ${JSON.stringify(r.source)}::jsonb,
              ${r.l.commit}, ${r.reviewed}, ${JSON.stringify(contentOf(r))}::jsonb,
              ${JSON.stringify(checked.values)}::jsonb, ${claims.sub}::uuid)
      returning id`);
    const packId = row?.id as string;
    await writeFiles(packId, body.org_id, r);
    const c: Ctx = {
      claims,
      call,
      orgId: body.org_id,
      packId,
      r,
      values: checked.values,
      skip: new Set((body.skip ?? []).map((s) => itemKey(s.kind, s.id))),
      secrets: body.secrets ?? {},
      settings: body.settings ?? {},
      deviceId: body.device_id ?? null,
      botId: body.bot_id ?? null,
      routinesOn: r.reviewed && body.routines_on !== false,
      existing: new Map(),
      takeTheirs: new Set(),
      items: [],
    };
    const result = await makeAll(c);
    // A directory pack counts like its plugin entry: usage numbers and contributor rewards.
    if (r.source.gallery_id)
      await recordGalleryUse(db, deps.env, claims.sub, "plugin", r.source.gallery_id).catch(
        () => {},
      );
    await audit(claims, body.org_id, "pack.installed", packId, {
      name: m.name,
      commit: r.l.commit,
      source: r.source.kind,
    });
    return {
      status: "installed" as const,
      approval_id: null,
      pack: await get(claims, packId),
      ...result,
    };
  };

  const makeAll = async (c: Ctx) => {
    const p = c.r.l.checked.pack;
    const bots = await makeBots(c);
    await makeSkills(c, bots);
    await makeRoutines(c, bots);
    await makeTools(c, bots);
    await makeIncludes(c, bots);
    for (const a of p.apps) {
      if (c.skip.has(itemKey("app", a.id))) continue;
      await record(c, "app", a.id, packAppId(c.r.l.checked.manifest.name, a.id), null);
      c.items.push(
        item("app", a.id, a.name, "installed", packAppId(c.r.l.checked.manifest.name, a.id), null),
      );
    }
    const looks = [];
    for (const k of p.looks) {
      const id = `${k.type}/${k.id}`;
      if (c.skip.has(itemKey("look", id))) continue;
      await record(c, "look", id, null, null);
      c.items.push(item("look", id, k.name, "device", null, null));
      looks.push({ type: k.type, id: k.id, name: k.name, document: k.document });
    }
    return {
      items: c.items,
      missing: {
        apps: await missingApps(c.orgId, c.r.l.checked.manifest.name, c.r),
        skills: [] as Array<{ id: string; name: string }>,
      },
      looks,
    };
  };

  /** An admin approved a waiting pack: install it as they would, with the requester's answers. */
  const installApproved = async (
    claims: JwtClaims,
    call: InternalCall,
    orgId: string,
    inputs: Record<string, unknown>,
  ) => {
    const request = (inputs.request ?? {}) as InstallPackBody;
    return install(claims, call, { ...request, org_id: orgId }, { skipPolicy: true });
  };

  const audit = (
    claims: JwtClaims,
    orgId: string,
    action: string,
    packId: string | null,
    meta: Record<string, unknown>,
  ) =>
    db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${orgId}::uuid, 'user', ${claims.sub}::uuid, ${action}, 'pack', ${packId}::uuid, ${JSON.stringify(meta)}::jsonb)`);

  // ---------------------------------------------------------------- updates

  const latestFor = async (row: PackRow): Promise<Resolved | null> => {
    if (row.source.kind === "gallery" && row.source.gallery_id)
      return resolve({ gallery_id: row.source.gallery_id }, row.org_id).catch(() => null);
    if (row.source.kind === "github" && row.source.owner)
      return resolve(
        {
          url:
            row.source.url ??
            `https://github.com/${row.source.owner}/${row.source.repo}/tree/${row.source.ref ?? "HEAD"}/${row.source.path ?? ""}`,
        },
        row.org_id,
      );
    return null;
  };

  const editedRefs = async (packId: string) => {
    const out: Array<{ kind: Kind; id: string }> = [];
    for (const i of await itemsOf(packId))
      if (await edited(i))
        if (!out.some((o) => o.kind === i.kind && o.id === i.item_id))
          out.push({ kind: i.kind, id: i.item_id });
    return out;
  };

  const emptyDiff = { added: [], removed: [], changed: [] };

  const updatePreview = async (claims: JwtClaims, id: string) => {
    const row = await stored(claims, id);
    const next = await latestFor(row);
    const editedList = await editedRefs(row.id);
    if (!next)
      return {
        up_to_date: true,
        can_check: false,
        from_commit: row.commit_sha,
        to_commit: null,
        from_version: row.version,
        to_version: null,
        bots: emptyDiff,
        routines: emptyDiff,
        skills: emptyDiff,
        apps: emptyDiff,
        looks: emptyDiff,
        servers: emptyDiff,
        hosts_added: [],
        secrets_added: [],
        schedules_changed: [],
        runs_per_week: {
          from: row.content.reach?.runs_per_week ?? 0,
          to: row.content.reach?.runs_per_week ?? 0,
        },
        reach_grew: false,
        edited: editedList,
      };
    const d = diffPacks(row.content.snapshot, contentOf(next).snapshot);
    return {
      up_to_date: next.l.commit === row.commit_sha,
      can_check: true,
      from_commit: row.commit_sha,
      to_commit: next.l.commit,
      from_version: row.version,
      to_version: next.l.checked.manifest.version ?? null,
      bots: d.bots,
      routines: d.routines,
      skills: d.skills,
      apps: d.apps,
      looks: d.looks,
      servers: d.servers,
      hosts_added: d.hosts_added,
      secrets_added: d.secrets_added,
      schedules_changed: d.schedules_changed,
      runs_per_week: d.runs_per_week,
      reach_grew: d.reach_grew,
      edited: editedList,
      preview: await buildPreview(next, row.org_id),
    };
  };

  const update = async (
    claims: JwtClaims,
    call: InternalCall,
    id: string,
    body: {
      commit: string;
      take_theirs?: Array<{ kind: Kind; id: string }>;
      confirm_reach?: boolean;
      secrets?: Record<string, string>;
      settings?: Record<string, string>;
    },
  ) => {
    const row = await stored(claims, id);
    if (!row.source.owner)
      throw new ApiError(
        400,
        "pack_no_source",
        "This pack came from a file or a link: install the newer file instead.",
      );
    const r = await resolve(
      row.source.gallery_id
        ? { gallery_id: row.source.gallery_id, commit: body.commit }
        : {
            url:
              row.source.url ??
              `https://github.com/${row.source.owner}/${row.source.repo}/tree/HEAD/${row.source.path ?? ""}`,
            commit: body.commit,
          },
      row.org_id,
    );
    if (r.l.checked.manifest.name !== row.name)
      throw new ApiError(400, "pack_renamed", "The new version has a different name");
    const next = contentOf(r);
    const d = diffPacks(row.content.snapshot, next.snapshot);
    if (d.reach_grew && !body.confirm_reach)
      throw new ApiError(
        409,
        "pack_reach_grew",
        "The new version can reach more than the one you have. Check what changed, then confirm.",
        {
          errors: [
            ...d.hosts_added.map((message) => ({ path: "hosts", message })),
            ...d.secrets_added.map((message) => ({ path: "secrets", message })),
            ...d.servers.added.map((message) => ({ path: "servers", message })),
          ],
        },
      );
    // The same policy as installing: a block or a new need for approval stops an update.
    const key = policyKey(r);
    const decision = await galleryDecision(deps, claims, row.org_id, key.type, key.id, {
      runs_code: r.l.checked.pack.reach.runs_code,
      computer: r.l.checked.pack.reach.computer,
    } as never);
    if (decision.decision === "block") throw new ApiError(403, "gallery_blocked", decision.reason);
    const items = await itemsOf(row.id);
    const existing = new Map(
      items.map((i) => [existingKey(i.kind, i.item_id, i.kind === "skill" ? i.bot_id : null), i]),
    );
    // Items the newer version dropped are left with the person, no longer tied to the pack.
    const keepIds = {
      bot: new Set(next.bots.map((b) => b.id)),
      routine: new Set(next.routines.map((x) => x.id)),
      skill: new Set(next.skills.map((s) => s.name)),
      app: new Set(next.apps.map((a) => a.id)),
      look: new Set(next.looks.map((k) => `${k.type}/${k.id}`)),
    } as Record<string, Set<string>>;
    for (const i of items)
      if (keepIds[i.kind] && !keepIds[i.kind]?.has(i.item_id))
        await db.execute(sql`delete from public.pack_items where id = ${i.id}::uuid`);
    const c: Ctx = {
      claims,
      call,
      orgId: row.org_id,
      packId: row.id,
      r,
      values: row.inputs ?? {},
      skip: new Set(),
      secrets: body.secrets ?? {},
      settings: body.settings ?? {},
      deviceId: null,
      botId: null,
      routinesOn: r.reviewed,
      existing,
      takeTheirs: new Set((body.take_theirs ?? []).map((t) => itemKey(t.kind, t.id))),
      items: [],
    };
    // Answers the newer version asks that the older didn't take their defaults.
    c.values = checkGalleryInputValues(r.l.checked.pack.document.inputs, c.values).values;
    const result = await makeAll(c);
    await db.execute(sql`
      update public.packs set version = ${r.l.checked.manifest.version ?? null}, description = ${(r.l.checked.manifest.description ?? "").slice(0, 2000)},
        summary = ${r.l.checked.pack.document.summary.slice(0, 200)}, icon = ${r.l.checked.pack.document.icon},
        commit_sha = ${r.l.commit}, reviewed = ${r.reviewed}, content = ${JSON.stringify(next)}::jsonb,
        inputs = ${JSON.stringify(c.values)}::jsonb, updated_at = now()
      where id = ${row.id}::uuid`);
    await writeFiles(row.id, row.org_id, r);
    await audit(claims, row.org_id, "pack.updated", row.id, {
      name: row.name,
      from: row.commit_sha,
      to: r.l.commit,
    });
    return {
      status: "installed" as const,
      approval_id: null,
      pack: await get(claims, row.id),
      ...result,
    };
  };

  // ---------------------------------------------------------------- removal

  const remove = async (claims: JwtClaims, id: string, bots: "keep" | "delete") => {
    const row = await stored(claims, id);
    const items = await itemsOf(row.id);
    let kept = 0;
    for (const i of items) {
      if (!i.target_id) continue;
      if (await edited(i)) {
        kept++;
        continue;
      }
      try {
        if (i.kind === "skill") {
          const gone = await withUserSession(db, claims, (tx) =>
            tx.execute<{ id: string }>(
              sql`delete from public.skills where id = ${i.target_id}::uuid returning id`,
            ),
          );
          if (!gone.length) kept++;
        } else if (i.kind === "routine") {
          const [ok] = await withUserSession(db, claims, (tx) =>
            tx.execute<{ ok: boolean }>(sql`
              select public.can_manage_bot(bot_id) as ok from public.routines where id = ${i.target_id}::uuid`),
          );
          if (ok?.ok)
            await db.execute(sql`delete from public.routines where id = ${i.target_id}::uuid`);
          else kept++;
        } else if (i.kind === "bot") {
          if (bots === "delete") {
            const gone = await withUserSession(db, claims, (tx) =>
              tx.execute<{ id: string }>(sql`
                update public.bots set archived_at = now() where id = ${i.target_id}::uuid and archived_at is null returning id`),
            );
            if (!gone.length) kept++;
          } else kept++;
        }
      } catch {
        kept++;
      }
    }
    const rows = await db.execute<{ id: string; org_id: string; bot_id: string; name: string }>(
      sql`select id, org_id, bot_id, name from public.plugins where pack_id = ${row.id}::uuid`,
    );
    for (const p of rows) await plugins.remove(claims, p);
    await db.execute(sql`delete from public.pack_items where pack_id = ${row.id}::uuid`);
    await db.execute(sql`delete from public.packs where id = ${row.id}::uuid`);
    await audit(claims, row.org_id, "pack.removed", null, { name: row.name, id: row.id, bots });
    return { deleted: row.id, kept };
  };

  const removeChecked = async (claims: JwtClaims, id: string, bots: "keep" | "delete") => {
    const row = await stored(claims, id);
    const r = await requireMember(db, claims, row.org_id);
    const [mine] = await db.execute<{ installed_by: string | null }>(
      sql`select installed_by from public.packs where id = ${id}::uuid`,
    );
    if (!r.admin && mine?.installed_by !== claims.sub)
      throw new ApiError(403, "forbidden", "Only admins and the person who added it remove a pack");
    return remove(claims, id, bots);
  };

  // ---------------------------------------------------------------- export and share

  type ExportBody = {
    name: string;
    summary: string;
    description?: string;
    icon?: string;
    bot_ids: string[];
    workspace_skill_ids?: string[];
    look?: {
      type: "theme" | "scheme" | "wallpaper";
      name: string;
      document: Record<string, unknown>;
    };
  };

  const skillsFor = async (where: ReturnType<typeof sql>): Promise<PackExportSkill[]> => {
    const rows = await db.execute<{
      id: string;
      name: string;
      description: string;
      body_md: string;
    }>(
      sql`select id, name, description, body_md from public.skills where ${where} and plugin_id is null order by name`,
    );
    const out: PackExportSkill[] = [];
    for (const s of rows) {
      const files = await db.execute<{ path: string; content: string; executable: boolean }>(sql`
        select path, encode(content, 'base64') as content, executable from public.skill_files where skill_id = ${s.id}::uuid order by path`);
      out.push({
        name: s.name,
        description: s.description,
        body_md: s.body_md,
        files: files.map((f) => ({ path: f.path, base64: f.content, executable: f.executable })),
      });
    }
    return out;
  };

  const exportPack = async (claims: JwtClaims, orgId: string, body: ExportBody) => {
    await requireMember(db, claims, orgId);
    const bots = [];
    for (const botId of body.bot_ids) {
      const [b] = await withUserSession(db, claims, (tx) =>
        tx.execute<{
          id: string;
          name: string;
          persona_md: string;
          autonomy: "ask_always" | "ask_risky" | "autonomous";
          avatar_url: string | null;
        }>(sql`
          select id, name, persona_md, autonomy::text as autonomy, avatar_url from public.bots
          where id = ${botId}::uuid and org_id = ${orgId}::uuid and archived_at is null`),
      );
      if (!b) throw new ApiError(404, "bot_not_found", "Bot not found");
      const routines = await db.execute<{
        name: string;
        instructions_md: string;
        schedule_cron: string | null;
      }>(sql`
        select name, instructions_md, schedule_cron from public.routines
        where bot_id = ${b.id}::uuid and trigger ->> 'type' = 'schedule' and schedule_cron is not null order by name`);
      const apps = await db.execute<{ app: string | null }>(sql`
        select distinct i.config ->> 'app' as app from public.bot_integrations bi
        join public.integrations i on i.id = bi.integration_id
        where bi.bot_id = ${b.id}::uuid and i.plugin_id is null`);
      const pl = await db.execute<{ source: Source; commit_sha: string }>(
        sql`select source, commit_sha from public.plugins where bot_id = ${b.id}::uuid and pack_id is null`,
      );
      bots.push({
        name: b.name,
        description: "",
        persona: b.persona_md,
        starters: [],
        autonomy: b.autonomy,
        mascot: b.avatar_url,
        skills: await skillsFor(sql`bot_id = ${b.id}::uuid`),
        routines: routines.map((x) => ({
          name: x.name,
          instructions_md: x.instructions_md,
          schedule_cron: x.schedule_cron as string,
        })),
        apps: apps.map((a) => a.app).filter((a): a is string => !!a && !a.includes(".")),
        plugins: pl
          .filter((x) => x.source.owner)
          .map((x) => ({
            url: `https://github.com/${x.source.owner}/${x.source.repo}/tree/${x.commit_sha}${x.source.path ? `/${x.source.path}` : ""}`,
            commit: x.commit_sha,
          })),
      });
    }
    const workspaceSkills = body.workspace_skill_ids?.length
      ? await skillsFor(
          sql`org_id = ${orgId}::uuid and bot_id is null and id in (${sql.join(
            body.workspace_skill_ids.map((x) => sql`${x}::uuid`),
            sql`, `,
          )})`,
        )
      : [];
    const [who] = await db.execute<{ name: string | null }>(sql`
      select nullif(display_name, '') as name from public.profiles where user_id = ${claims.sub}::uuid`);
    const files = buildPackFiles({
      name: body.name,
      summary: body.summary,
      description: body.description ?? body.summary,
      ...(body.icon ? { icon: body.icon } : {}),
      ...(who?.name ? { author: who.name } : {}),
      bots,
      workspaceSkills,
      ...(body.look ? { look: body.look } : {}),
    });
    const secrets = await db.execute<{ name: string; value: string | null }>(sql`
      select s.name, v.decrypted_secret as value from public.secrets s
      join vault.decrypted_secrets v on v.id = s.vault_secret_id where s.org_id = ${orgId}::uuid`);
    const findings = findSecretsInFiles(
      files,
      secrets.filter((s) => s.value).map((s) => ({ label: s.name, value: s.value as string })),
    );
    await audit(claims, orgId, "pack.exported", null, {
      name: body.name,
      bots: body.bot_ids.length,
    });
    return {
      name: packSlug(body.name),
      files: files.map((f) => ({
        path: f.path,
        text: f.text ?? null,
        base64: f.base64 ?? null,
        executable: f.executable === true,
      })),
      findings,
    };
  };

  const share = async (
    claims: JwtClaims,
    orgId: string,
    body: ExportBody & { ignore_findings?: boolean },
  ) => {
    const out = await exportPack(claims, orgId, body);
    if (out.findings.length && !body.ignore_findings)
      throw new ApiError(
        409,
        "pack_has_secrets",
        "Some lines look like keys. Remove them, or confirm they're safe to share.",
        { errors: out.findings.map((f) => ({ path: `${f.path}:${f.line}`, message: f.what })) },
      );
    const token = randomBytes(24).toString("base64url");
    const files = out.files.map((f) => ({
      path: f.path,
      base64: f.base64 ?? Buffer.from(f.text ?? "", "utf8").toString("base64"),
      executable: f.executable,
    }));
    const [row] = await db.execute<{ id: string; expires_at: Date | string }>(sql`
      insert into public.pack_shares (org_id, token_hash, name, summary, files, created_by, expires_at)
      values (${orgId}::uuid, ${sha256(token)}, ${out.name}, ${body.summary.slice(0, 200)}, ${JSON.stringify(files)}::jsonb,
              ${claims.sub}::uuid, now() + interval '30 days')
      returning id, expires_at`);
    await audit(claims, orgId, "pack.shared", null, { name: out.name, share_id: row?.id });
    return {
      id: row?.id as string,
      url: appLink(deps.env, `/packs/share/${token}`),
      token,
      expires_at: iso(row?.expires_at as string),
      findings: out.findings,
    };
  };

  const viewShare = async (claims: JwtClaims, token: string) => {
    const s = await shareByToken(token);
    const l = await plugins.loadFiles(s.files);
    if (!l.checked.pack)
      throw new ApiError(404, "pack_share_not_found", "This pack link is broken.");
    void claims;
    return {
      id: s.id,
      preview: await buildPreview({
        l: l as Resolved["l"],
        source: { kind: "share" },
        reviewed: false,
      }),
      expires_at: iso(s.expires_at),
    };
  };

  const revokeShare = async (claims: JwtClaims, token: string) => {
    const s = await shareByToken(token);
    const r = await requireMember(db, claims, s.org_id);
    if (!r.admin && s.created_by !== claims.sub)
      throw new ApiError(403, "forbidden", "Only admins and the person who shared it end a link");
    await db.execute(sql`delete from public.pack_shares where id = ${s.id}::uuid`);
    return { ok: true };
  };

  // ---------------------------------------------------------------- the shelf

  type ShelfItem = z.infer<typeof GalleryPack>;
  const shelf = async () => {
    const out: ShelfItem[] = [];
    for (const s of await gallerySets(deps.env).catch(() => []))
      out.push({
        kind: "set" as const,
        id: s.id,
        name: s.name,
        summary: s.description,
        icon: s.icon,
        author: s.author,
        featured: s.featured,
        reviewed: true,
        url: null,
        commit: null,
        contents: null,
        set_items: s.items,
        tags: [],
      });
    const listed = await galleryPlugins(deps.env).catch(() => []);
    await Promise.all(
      listed.map(async (p) => {
        const key = `${p.url}@${p.commit}`;
        if (!shelfCache.has(key)) {
          try {
            const l = await plugins.load(parseGitHubUrl(p.url), p.commit);
            const k = l.checked.pack;
            shelfCache.set(
              key,
              k
                ? {
                    summary: k.document.summary,
                    icon: k.document.icon,
                    bots: k.bots.length,
                    skills: l.skills.length,
                    routines: k.routines.length,
                    apps: k.apps.length,
                    looks: k.looks.length,
                    tools: l.checked.servers.length,
                  }
                : null,
            );
          } catch {
            return; // try again next time
          }
        }
        const c = shelfCache.get(key);
        if (!c) return;
        const { summary, icon, ...contents } = c;
        out.push({
          kind: "pack" as const,
          id: p.id,
          name: p.name,
          summary,
          icon: icon || p.icon || "package",
          author: p.author,
          featured: p.featured || !!p.pick,
          reviewed: true,
          url: p.url,
          commit: p.commit,
          contents,
          set_items: null,
          tags: [],
        });
      }),
    );
    // A pack replaces the starter set of the same id (Founder kit, Meetings handled); the set still
    // serves a new workspace's picker. Packs come first, then featured, then by name.
    const packIds = new Set(out.filter((i) => i.kind === "pack").map((i) => i.id));
    return out
      .filter((i) => i.kind === "pack" || !packIds.has(i.id))
      .sort(
        (a, b) =>
          Number(b.kind === "pack") - Number(a.kind === "pack") ||
          Number(b.featured) - Number(a.featured) ||
          a.name.localeCompare(b.name),
      );
  };

  return {
    preview,
    install,
    installApproved,
    list,
    get,
    updatePreview,
    update,
    remove: removeChecked,
    exportPack,
    share,
    viewShare,
    revokeShare,
    shelf,
  };
}
