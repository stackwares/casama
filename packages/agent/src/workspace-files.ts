/**
 * Routines and skills as files (D-124): exporting a workspace to Markdown files and applying a
 * folder of them back. Shared by the API (export, import) and the worker (git sync).
 */
import type { Database } from "@kasama/db";
import {
  type FolderIndex,
  INDEX_FILE,
  nextRunAt,
  parseIndex,
  parseWorkspaceFiles,
  renderRoutineFile,
  renderSkillFile,
  fileSlug,
  WORKSPACE_FOLDER,
} from "@kasama/domain";
import { sql } from "drizzle-orm";

const enc = (s: string) => new TextEncoder().encode(s);

/**
 * The workspace's routines and skills as files. Plugin skills and check-in routines are managed
 * elsewhere and left out.
 */
export async function exportWorkspaceFiles(db: Database, orgId: string) {
  const bots = await db.execute<{ id: string; name: string }>(
    sql`select id, name from public.bots where org_id = ${orgId}::uuid and archived_at is null order by created_at`,
  );
  const index: FolderIndex = { format: "kasama.files", version: 1, bots: {} };
  const folderOf = new Map<string, string>();
  for (const b of bots) {
    let f = fileSlug(b.name);
    if (f === WORKSPACE_FOLDER || index.bots[f]) {
      let i = 2;
      while (index.bots[`${f}-${i}`]) i++;
      f = `${f}-${i}`;
    }
    index.bots[f] = { id: b.id, name: b.name };
    folderOf.set(b.id, f);
  }
  const files = new Map<string, Uint8Array>([[INDEX_FILE, enc(`${JSON.stringify(index, null, 2)}\n`)]]);
  const routines = await db.execute<{
    id: string;
    bot_id: string;
    name: string;
    instructions_md: string;
    schedule_cron: string | null;
    timezone: string;
    trigger: { type?: string };
    enabled: boolean;
    notify: boolean;
  }>(sql`
    select id, bot_id, name, instructions_md, schedule_cron, timezone, trigger, enabled, notify from public.routines
    where org_id = ${orgId}::uuid and kind = 'task' order by created_at`);
  for (const r of routines) {
    const folder = folderOf.get(r.bot_id);
    if (!folder) continue;
    let p = `${folder}/routines/${fileSlug(r.name)}.md`;
    for (let i = 2; files.has(p); i++) p = `${folder}/routines/${fileSlug(r.name)}-${i}.md`;
    const trigger = r.trigger?.type === "webhook" || r.trigger?.type === "github" ? r.trigger.type : "schedule";
    files.set(
      p,
      enc(
        renderRoutineFile({
          id: r.id,
          name: r.name,
          schedule: r.schedule_cron,
          timezone: r.timezone,
          trigger,
          enabled: r.enabled,
          notify: r.notify,
          instructions: r.instructions_md,
        }),
      ),
    );
  }
  const skills = await db.execute<{ id: string; bot_id: string | null; name: string; description: string; body_md: string; enabled: boolean }>(sql`
    select id, bot_id, name, description, body_md, enabled from public.skills
    where org_id = ${orgId}::uuid and plugin_id is null order by name`);
  const skillFiles = await db.execute<{ skill_id: string; path: string; content: Buffer }>(sql`
    select f.skill_id, f.path, f.content from public.skill_files f join public.skills s on s.id = f.skill_id
    where s.org_id = ${orgId}::uuid and s.plugin_id is null`);
  for (const s of skills) {
    const folder = s.bot_id ? folderOf.get(s.bot_id) : WORKSPACE_FOLDER;
    if (!folder) continue;
    const dir = `${folder}/skills/${s.name}/`;
    files.set(`${dir}SKILL.md`, enc(renderSkillFile({ id: s.id, name: s.name, description: s.description, enabled: s.enabled, body: s.body_md })));
    for (const f of skillFiles) if (f.skill_id === s.id) files.set(dir + f.path, new Uint8Array(f.content));
  }
  return files;
}

export interface ApplyResult {
  created: string[];
  updated: string[];
  deleted: string[];
  unchanged: number;
  errors: string[];
}

/**
 * Applies a folder of files: creates and updates routines and skills (never deletes unless the
 * caller names what was deleted). Bad files are reported and skipped. With dryRun, nothing is
 * written.
 */
export async function applyWorkspaceFiles(
  db: Database,
  orgId: string,
  files: Map<string, Uint8Array>,
  opts: { dryRun?: boolean; actorUserId?: string | null; deletedPaths?: string[]; previous?: Map<string, Uint8Array> } = {},
): Promise<ApplyResult> {
  const result: ApplyResult = { created: [], updated: [], deleted: [], unchanged: 0, errors: [] };
  const parsed = parseWorkspaceFiles(files);
  result.errors.push(...parsed.errors);
  const index = parseIndex(files.get(INDEX_FILE) ? new TextDecoder().decode(files.get(INDEX_FILE)) : undefined);
  const bots = await db.execute<{ id: string; name: string }>(
    sql`select id, name from public.bots where org_id = ${orgId}::uuid and archived_at is null`,
  );
  const botFor = (folder: string): string | null | undefined => {
    if (folder === WORKSPACE_FOLDER) return null;
    const byIndex = index?.bots[folder];
    if (byIndex && bots.some((b) => b.id === byIndex.id)) return byIndex.id;
    return bots.find((b) => fileSlug(b.name) === folder || (byIndex && b.name === byIndex.name))?.id;
  };
  const write = async (fn: (tx: Database) => Promise<void>) => (opts.dryRun ? undefined : db.transaction(async (tx) => fn(tx as never)));
  const [tz] = opts.actorUserId
    ? await db.execute<{ timezone: string | null }>(sql`select timezone from public.profiles where user_id = ${opts.actorUserId}::uuid`)
    : [];
  void tz;

  for (const { folder, path, routine: r } of parsed.routines) {
    const botId = botFor(folder);
    if (!botId) {
      result.errors.push(`${path}: no bot matches the folder "${folder}"`);
      continue;
    }
    const [existing] = await db.execute<{
      id: string;
      name: string;
      instructions_md: string;
      schedule_cron: string | null;
      timezone: string;
      trigger: { type?: string };
      enabled: boolean;
      notify: boolean;
    }>(sql`
      select id, name, instructions_md, schedule_cron, timezone, trigger, enabled, notify from public.routines
      where org_id = ${orgId}::uuid and bot_id = ${botId}::uuid and kind = 'task'
        and (id = ${r.id ?? null}::uuid or (${r.id ?? null}::uuid is null and name = ${r.name}))
      order by (id = ${r.id ?? null}::uuid) desc nulls last limit 1`);
    const currentTrigger = existing?.trigger?.type ?? "schedule";
    if (r.trigger !== "schedule" && r.trigger !== currentTrigger) {
      result.errors.push(`${path}: set up ${r.trigger} triggers in the app (they need a secret)`);
      continue;
    }
    const next = r.schedule && r.enabled ? nextRunAt(r.schedule, r.timezone).toISOString() : null;
    if (!existing) {
      result.created.push(path);
      await write(async (tx) => {
        await tx.execute(sql`
          insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, trigger, notify, enabled, next_run_at)
          values (${orgId}::uuid, ${botId}::uuid, ${opts.actorUserId ?? null}::uuid, ${r.name}, ${r.instructions}, ${r.schedule}, ${r.timezone},
                  '{"type":"schedule"}'::jsonb, ${r.notify}, ${r.enabled}, ${next}::timestamptz)`);
      });
      continue;
    }
    const same =
      existing.name === r.name &&
      existing.instructions_md.trim() === r.instructions &&
      existing.schedule_cron === r.schedule &&
      existing.timezone === r.timezone &&
      existing.enabled === r.enabled &&
      existing.notify === r.notify;
    if (same) {
      result.unchanged++;
      continue;
    }
    result.updated.push(path);
    await write(async (tx) => {
      await tx.execute(sql`
        update public.routines set name = ${r.name}, instructions_md = ${r.instructions}, schedule_cron = ${r.schedule}, timezone = ${r.timezone},
          enabled = ${r.enabled}, notify = ${r.notify}, next_run_at = ${next}::timestamptz
        where id = ${existing.id}::uuid`);
    });
  }

  for (const { folder, path, skill: s, files: extra } of parsed.skills) {
    const botId = botFor(folder);
    if (botId === undefined) {
      result.errors.push(`${path}: no bot matches the folder "${folder}"`);
      continue;
    }
    const [existing] = await db.execute<{ id: string; description: string; body_md: string; enabled: boolean; plugin_id: string | null }>(sql`
      select id, description, body_md, enabled, plugin_id from public.skills
      where org_id = ${orgId}::uuid and bot_id is not distinct from ${botId}::uuid and name = ${s.name} limit 1`);
    if (existing?.plugin_id) {
      result.errors.push(`${path}: this skill comes from a plugin; change the plugin instead`);
      continue;
    }
    const oldFiles = existing
      ? await db.execute<{ path: string; content: Buffer }>(sql`select path, content from public.skill_files where skill_id = ${existing.id}::uuid`)
      : [];
    const filesSame =
      oldFiles.length === extra.length &&
      extra.every((f) => {
        const o = oldFiles.find((x) => x.path === f.path);
        return o && Buffer.compare(Buffer.from(o.content), Buffer.from(f.content)) === 0;
      });
    if (existing && existing.description === s.description && existing.body_md.trim() === s.body.trim() && existing.enabled === s.enabled && filesSame) {
      result.unchanged++;
      continue;
    }
    (existing ? result.updated : result.created).push(path);
    await write(async (tx) => {
      let id = existing?.id;
      if (id)
        await tx.execute(sql`update public.skills set description = ${s.description}, body_md = ${s.body}, enabled = ${s.enabled}, updated_at = now(), updated_by_bot = null where id = ${id}::uuid`);
      else {
        const [row] = await tx.execute<{ id: string }>(sql`
          insert into public.skills (org_id, bot_id, name, description, body_md, enabled, source)
          values (${orgId}::uuid, ${botId}::uuid, ${s.name}, ${s.description}, ${s.body}, ${s.enabled}, 'manual') returning id`);
        id = row?.id;
      }
      if (!filesSame) {
        await tx.execute(sql`delete from public.skill_files where skill_id = ${id}::uuid`);
        for (const f of extra)
          await tx.execute(sql`
            insert into public.skill_files (org_id, skill_id, path, content, executable)
            values (${orgId}::uuid, ${id}::uuid, ${f.path}, decode(${Buffer.from(f.content).toString("base64")}, 'base64'), false)`);
      }
    });
  }

  // Deletions (git sync): items whose files were removed from the repo.
  if (opts.deletedPaths?.length && opts.previous) {
    const prev = parseWorkspaceFiles(new Map([...opts.previous].filter(([p]) => opts.deletedPaths?.includes(p))));
    for (const r of prev.routines)
      if (r.routine.id) {
        result.deleted.push(r.path);
        await write(async (tx) => void (await tx.execute(sql`delete from public.routines where id = ${r.routine.id}::uuid and org_id = ${orgId}::uuid and kind = 'task'`)));
      }
    for (const s of prev.skills)
      if (s.skill.id) {
        result.deleted.push(s.path);
        await write(async (tx) => void (await tx.execute(sql`delete from public.skills where id = ${s.skill.id}::uuid and org_id = ${orgId}::uuid and plugin_id is null`)));
      }
  }
  return result;
}
