/**
 * Routines and skills as files (D-124): exporting a workspace to Markdown files and applying a
 * folder of them back. Shared by the API (export, import) and the worker (git sync).
 */
import {
  CalendarTriggerConfig,
  DeviceTriggerConfig,
  MessageTriggerConfig,
} from "@casama/contracts";
import type { Database } from "@casama/db";
import {
  browserTriggerSite,
  type FolderIndex,
  fileSlug,
  hasTriggerConfig,
  INDEX_FILE,
  nextRunAt,
  parseIndex,
  parseWorkspaceFiles,
  ROUTINE_FILE_TRIGGERS,
  type RoutineFile,
  type RoutineFileTrigger,
  renderRoutineFile,
  renderSkillFile,
  TRIGGER_CONFIG_KEY,
  WORKSPACE_FOLDER,
} from "@casama/domain";
import { sql } from "drizzle-orm";

const enc = (s: string) => new TextEncoder().encode(s);

/** The settings an event trigger's file carries: the API's own fields, nothing internal. */
const CONFIG_SCHEMA = {
  calendar_event: CalendarTriggerConfig,
  message: MessageTriggerConfig,
  device: DeviceTriggerConfig,
} as const;
type ConfigTrigger = keyof typeof CONFIG_SCHEMA;

type TriggerJson = { type?: string } & Record<string, unknown>;
const kindOf = (t: TriggerJson | null | undefined): RoutineFileTrigger => {
  const k = (t?.type ?? "schedule") as RoutineFileTrigger;
  return ROUTINE_FILE_TRIGGERS.includes(k) ? k : "schedule";
};
const configOf = (kind: ConfigTrigger, t: TriggerJson | null | undefined) =>
  Object.fromEntries(
    Object.keys(CONFIG_SCHEMA[kind].shape)
      .filter((k) => t?.[k] !== undefined && t?.[k] !== null)
      .map((k) => [k, t?.[k]]),
  );
const stable = (o: Record<string, unknown>) =>
  JSON.stringify(Object.entries(o).sort(([a], [b]) => a.localeCompare(b)));
const iso = (v: string | Date | null | undefined) => (v ? new Date(v).toISOString() : null);
const isTimed = (k: RoutineFileTrigger | null) => k === "schedule" || k === "once";

/**
 * The workspace's routines and skills as files. Plugin skills and check-in routines are managed
 * elsewhere and left out.
 */
export async function exportWorkspaceFiles(db: Database, orgId: string) {
  const bots = await db.execute<{ id: string; name: string }>(
    sql`select id, name from public.bots where org_id = ${orgId}::uuid and archived_at is null order by created_at`,
  );
  const index: FolderIndex = { format: "casama.files", version: 1, bots: {} };
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
  const files = new Map<string, Uint8Array>([
    [INDEX_FILE, enc(`${JSON.stringify(index, null, 2)}\n`)],
  ]);
  const routines = await db.execute<{
    id: string;
    bot_id: string;
    name: string;
    instructions_md: string;
    schedule_cron: string | null;
    timezone: string;
    trigger: TriggerJson;
    enabled: boolean;
    notify: boolean;
    next_run_at: string | Date | null;
    ends_at: string | Date | null;
    max_runs: number | null;
  }>(sql`
    select id, bot_id, name, instructions_md, schedule_cron, timezone, trigger, enabled, notify, next_run_at, ends_at, max_runs
    from public.routines where org_id = ${orgId}::uuid and kind = 'task' order by created_at`);
  for (const r of routines) {
    const folder = folderOf.get(r.bot_id);
    if (!folder) continue;
    let p = `${folder}/routines/${fileSlug(r.name)}.md`;
    for (let i = 2; files.has(p); i++) p = `${folder}/routines/${fileSlug(r.name)}-${i}.md`;
    const trigger = kindOf(r.trigger);
    files.set(
      p,
      enc(
        renderRoutineFile({
          id: r.id,
          name: r.name,
          schedule: trigger === "schedule" ? r.schedule_cron : null,
          timezone: r.timezone,
          trigger,
          ...(trigger === "once" ? { runAt: r.enabled ? iso(r.next_run_at) : null } : {}),
          ...(hasTriggerConfig(trigger) ? { triggerConfig: configOf(trigger, r.trigger) } : {}),
          endsAt: iso(r.ends_at),
          maxRuns: r.max_runs,
          enabled: r.enabled,
          notify: r.notify,
          instructions: r.instructions_md,
        }),
      ),
    );
  }
  const skills = await db.execute<{
    id: string;
    bot_id: string | null;
    name: string;
    description: string;
    body_md: string;
    enabled: boolean;
  }>(sql`
    select id, bot_id, name, description, body_md, enabled from public.skills
    where org_id = ${orgId}::uuid and plugin_id is null order by name`);
  const skillFiles = await db.execute<{ skill_id: string; path: string; content: Buffer }>(sql`
    select f.skill_id, f.path, f.content from public.skill_files f join public.skills s on s.id = f.skill_id
    where s.org_id = ${orgId}::uuid and s.plugin_id is null`);
  for (const s of skills) {
    const folder = s.bot_id ? folderOf.get(s.bot_id) : WORKSPACE_FOLDER;
    if (!folder) continue;
    const dir = `${folder}/skills/${s.name}/`;
    files.set(
      `${dir}SKILL.md`,
      enc(
        renderSkillFile({
          id: s.id,
          name: s.name,
          description: s.description,
          enabled: s.enabled,
          body: s.body_md,
        }),
      ),
    );
    for (const f of skillFiles)
      if (f.skill_id === s.id) files.set(dir + f.path, new Uint8Array(f.content));
  }
  return files;
}

interface ExistingRoutine {
  name: string;
  instructions_md: string;
  schedule_cron: string | null;
  timezone: string;
  trigger: TriggerJson;
  enabled: boolean;
  notify: boolean;
  next_run_at: string | Date | null;
  ends_at: string | Date | null;
  max_runs: number | null;
  run_count: number;
}

type RoutinePlan =
  | { error: string }
  | { same: true }
  | {
      same: false;
      values: {
        schedule: string | null;
        trigger: TriggerJson;
        nextRunAt: string | null;
        endsAt: string | null;
        maxRuns: number | null;
        runCount: number;
      };
    };

/** Checks an event trigger's settings from a file the way the API checks them on create. */
async function checkTriggerConfig(
  db: Database,
  orgId: string,
  kind: ConfigTrigger,
  raw: Record<string, unknown>,
): Promise<{ error: string } | { config: Record<string, unknown> }> {
  const key = TRIGGER_CONFIG_KEY[kind];
  const parsed = CONFIG_SCHEMA[kind].safeParse(raw);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    return { error: `${key}.${issue?.path.join(".") || "?"}: ${issue?.message ?? "invalid"}` };
  }
  const c = parsed.data as Record<string, unknown>;
  if (
    kind === "message" &&
    !["channel_id", "channel_kind", "sender", "subject_match", "text_match", "to_tag"].some(
      (k) => c[k] !== undefined,
    )
  )
    return {
      error: "a message routine needs at least one filter (channel_kind, sender, subject_match…)",
    };
  if (kind === "device") {
    const d = c as { event: string; place?: string; app?: string; folder?: string; site?: string };
    if ((d.event === "arrive" || d.event === "leave") && !d.place)
      return { error: "arrive and leave routines need a named place" };
    if (d.event === "notification" && !d.app)
      return { error: "notification routines need the app to watch" };
    if (d.event === "file_added" && !d.folder)
      return { error: "file routines need the watched folder" };
    if (d.event === "site_opened") {
      const r = browserTriggerSite(d.site ?? "");
      if ("error" in r) return { error: r.error };
      d.site = r.site;
    }
  }
  if (kind === "calendar_event") {
    const [i] = await db.execute<{ id: string }>(sql`
      select id from public.integrations where id = ${c.integration_id as string}::uuid and org_id = ${orgId}::uuid`);
    if (!i)
      return { error: "calendar.integration_id isn't a calendar connected in this workspace" };
  }
  return {
    config: Object.fromEntries(Object.entries(c).filter(([, v]) => v !== undefined)),
  };
}

/**
 * What a routine file changes, under the same rules as `PATCH /v1/routines/{id}` (D-262):
 * schedule ↔ once may switch but event triggers keep their kind; a changed max_runs counts from
 * now; a routine can't be on past its end or out of runs; a once routine keeps its pending run
 * unless the file moves it.
 */
async function planRoutine(
  db: Database,
  orgId: string,
  r: RoutineFile,
  existing: ExistingRoutine | undefined,
  hasActor: boolean,
): Promise<RoutinePlan> {
  const kind = r.trigger;
  const was = existing ? kindOf(existing.trigger) : null;
  if (kind !== was && (kind === "webhook" || kind === "github"))
    return { error: `set up ${kind} triggers in the app (they need a secret)` };
  if (existing && kind !== was && !(isTimed(kind) && isTimed(was)))
    return {
      error: `a ${was} routine can't become a ${kind} one in a file; create a new routine instead`,
    };
  if (!existing && kind === "device" && !hasActor)
    return {
      error:
        "device routines follow one person's phone or computer: import them from the app or the CLI",
    };
  let config: Record<string, unknown> | undefined;
  if (hasTriggerConfig(kind)) {
    const c = await checkTriggerConfig(db, orgId, kind, r.triggerConfig ?? {});
    if ("error" in c) return c;
    config = c.config;
  }

  const isOnce = kind === "once";
  const endsAt = isOnce ? null : r.endsAt === undefined ? iso(existing?.ends_at) : r.endsAt;
  const maxRuns = isOnce
    ? null
    : r.maxRuns === undefined
      ? (existing?.max_runs ?? null)
      : r.maxRuns;
  // A new limit counts from now, as in the API.
  const runCount = existing && maxRuns === existing.max_runs ? existing.run_count : 0;
  const now = Date.now();
  const pending =
    existing && was === "once" && existing.next_run_at && iso(existing.next_run_at)
      ? (iso(existing.next_run_at) as string)
      : null;
  // A once file without run_at (or with null) keeps the pending run.
  const runAt = isOnce ? (r.runAt ?? pending) : null;

  if (
    existing &&
    existing.name === r.name &&
    existing.instructions_md.trim() === r.instructions &&
    (existing.schedule_cron ?? null) === r.schedule &&
    existing.timezone === r.timezone &&
    existing.enabled === r.enabled &&
    existing.notify === r.notify &&
    kind === was &&
    endsAt === iso(existing.ends_at) &&
    maxRuns === existing.max_runs &&
    (!config || stable(config) === stable(configOf(kind as ConfigTrigger, existing.trigger))) &&
    (!isOnce || runAt === pending)
  )
    return { same: true };

  let next: string | null = null;
  if (r.enabled) {
    if (endsAt && Date.parse(endsAt) <= now)
      return { error: "its end time (ends_at) has passed: pick a later one or remove it" };
    if (maxRuns != null && runCount >= maxRuns)
      return {
        error: `it already ran its ${maxRuns} times: raise max_runs or remove the limit to switch it on`,
      };
    if (isOnce) {
      if (!runAt || Date.parse(runAt) < now - 60_000)
        return { error: "a once routine needs run_at in the future to be switched on" };
      next = runAt;
    } else if (kind === "schedule" && r.schedule) {
      const n = nextRunAt(r.schedule, r.timezone);
      if (endsAt && n.getTime() > Date.parse(endsAt))
        return { error: "it would end (ends_at) before its next run" };
      next = n.toISOString();
    }
  }

  let trigger: TriggerJson;
  if (existing && kind === was) {
    trigger = { ...existing.trigger };
    if (config) {
      // Keep what Casama keeps for itself (like a calendar's checked_at); replace the settings.
      for (const k of Object.keys(CONFIG_SCHEMA[kind as ConfigTrigger].shape)) delete trigger[k];
      Object.assign(trigger, config);
    }
    trigger.type = kind;
  } else trigger = { type: kind, ...config };

  return {
    same: false,
    values: {
      schedule: kind === "schedule" ? r.schedule : null,
      trigger,
      nextRunAt: next,
      endsAt,
      maxRuns,
      runCount,
    },
  };
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
  opts: {
    dryRun?: boolean;
    actorUserId?: string | null;
    deletedPaths?: string[];
    previous?: Map<string, Uint8Array>;
  } = {},
): Promise<ApplyResult> {
  const result: ApplyResult = { created: [], updated: [], deleted: [], unchanged: 0, errors: [] };
  const parsed = parseWorkspaceFiles(files);
  result.errors.push(...parsed.errors);
  const index = parseIndex(
    files.get(INDEX_FILE) ? new TextDecoder().decode(files.get(INDEX_FILE)) : undefined,
  );
  const bots = await db.execute<{ id: string; name: string }>(
    sql`select id, name from public.bots where org_id = ${orgId}::uuid and archived_at is null`,
  );
  const botFor = (folder: string): string | null | undefined => {
    if (folder === WORKSPACE_FOLDER) return null;
    const byIndex = index?.bots[folder];
    if (byIndex && bots.some((b) => b.id === byIndex.id)) return byIndex.id;
    return bots.find((b) => fileSlug(b.name) === folder || (byIndex && b.name === byIndex.name))
      ?.id;
  };
  const write = async (fn: (tx: Database) => Promise<void>) =>
    opts.dryRun ? undefined : db.transaction(async (tx) => fn(tx as never));
  const [tz] = opts.actorUserId
    ? await db.execute<{ timezone: string | null }>(
        sql`select timezone from public.profiles where user_id = ${opts.actorUserId}::uuid`,
      )
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
      trigger: TriggerJson;
      enabled: boolean;
      notify: boolean;
      next_run_at: string | Date | null;
      ends_at: string | Date | null;
      max_runs: number | null;
      run_count: number;
    }>(sql`
      select id, name, instructions_md, schedule_cron, timezone, trigger, enabled, notify, next_run_at, ends_at, max_runs, run_count
      from public.routines
      where org_id = ${orgId}::uuid and bot_id = ${botId}::uuid and kind = 'task'
        and (id = ${r.id ?? null}::uuid or (${r.id ?? null}::uuid is null and name = ${r.name}))
      order by (id = ${r.id ?? null}::uuid) desc nulls last limit 1`);
    const plan = await planRoutine(db, orgId, r, existing, Boolean(opts.actorUserId));
    if ("error" in plan) {
      result.errors.push(`${path}: ${plan.error}`);
      continue;
    }
    if (plan.same) {
      result.unchanged++;
      continue;
    }
    const v = plan.values;
    if (!existing) {
      result.created.push(path);
      await write(async (tx) => {
        await tx.execute(sql`
          insert into public.routines (org_id, bot_id, created_by, name, instructions_md, schedule_cron, timezone, trigger, notify, enabled,
                                       next_run_at, ends_at, max_runs)
          values (${orgId}::uuid, ${botId}::uuid, ${opts.actorUserId ?? null}::uuid, ${r.name}, ${r.instructions}, ${v.schedule}, ${r.timezone},
                  ${JSON.stringify(v.trigger)}::jsonb, ${r.notify}, ${r.enabled}, ${v.nextRunAt}::timestamptz,
                  ${v.endsAt}::timestamptz, ${v.maxRuns})`);
      });
      continue;
    }
    result.updated.push(path);
    await write(async (tx) => {
      await tx.execute(sql`
        update public.routines set name = ${r.name}, instructions_md = ${r.instructions}, schedule_cron = ${v.schedule}, timezone = ${r.timezone},
          trigger = ${JSON.stringify(v.trigger)}::jsonb, enabled = ${r.enabled}, notify = ${r.notify}, next_run_at = ${v.nextRunAt}::timestamptz,
          ends_at = ${v.endsAt}::timestamptz, max_runs = ${v.maxRuns}, run_count = ${v.runCount}, retime_pending = false
        where id = ${existing.id}::uuid`);
    });
  }

  for (const { folder, path, skill: s, files: extra } of parsed.skills) {
    const botId = botFor(folder);
    if (botId === undefined) {
      result.errors.push(`${path}: no bot matches the folder "${folder}"`);
      continue;
    }
    const [existing] = await db.execute<{
      id: string;
      description: string;
      body_md: string;
      enabled: boolean;
      plugin_id: string | null;
    }>(sql`
      select id, description, body_md, enabled, plugin_id from public.skills
      where org_id = ${orgId}::uuid and bot_id is not distinct from ${botId}::uuid and name = ${s.name} limit 1`);
    if (existing?.plugin_id) {
      result.errors.push(`${path}: this skill comes from a plugin; change the plugin instead`);
      continue;
    }
    const oldFiles = existing
      ? await db.execute<{ path: string; content: Buffer }>(
          sql`select path, content from public.skill_files where skill_id = ${existing.id}::uuid`,
        )
      : [];
    const filesSame =
      oldFiles.length === extra.length &&
      extra.every((f) => {
        const o = oldFiles.find((x) => x.path === f.path);
        return o && Buffer.compare(Buffer.from(o.content), Buffer.from(f.content)) === 0;
      });
    if (
      existing &&
      existing.description === s.description &&
      existing.body_md.trim() === s.body.trim() &&
      existing.enabled === s.enabled &&
      filesSame
    ) {
      result.unchanged++;
      continue;
    }
    (existing ? result.updated : result.created).push(path);
    await write(async (tx) => {
      let id = existing?.id;
      if (id)
        await tx.execute(
          sql`update public.skills set description = ${s.description}, body_md = ${s.body}, enabled = ${s.enabled}, updated_at = now(), updated_by_bot = null where id = ${id}::uuid`,
        );
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
    const prev = parseWorkspaceFiles(
      new Map([...opts.previous].filter(([p]) => opts.deletedPaths?.includes(p))),
    );
    for (const r of prev.routines)
      if (r.routine.id) {
        result.deleted.push(r.path);
        await write(
          async (tx) =>
            void (await tx.execute(
              sql`delete from public.routines where id = ${r.routine.id}::uuid and org_id = ${orgId}::uuid and kind = 'task'`,
            )),
        );
      }
    for (const s of prev.skills)
      if (s.skill.id) {
        result.deleted.push(s.path);
        await write(
          async (tx) =>
            void (await tx.execute(
              sql`delete from public.skills where id = ${s.skill.id}::uuid and org_id = ${orgId}::uuid and plugin_id is null`,
            )),
        );
      }
  }
  return result;
}
