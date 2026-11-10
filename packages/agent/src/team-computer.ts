import type { Database } from "@kasama/db";
import type { ExecOptions, SandboxHandle } from "@kasama/sandbox";
import { slugify } from "@kasama/domain";
import { sql } from "drizzle-orm";

/**
 * Team computer layout (SPEC: Ops extras; D-148). On a team computer each bot works in its own
 * folder, `~/workspace/bots/<folder>`, and `~/workspace/shared` holds what the bots share. A cap
 * (`computers.max_desktops`) limits how many bots use the desktop at the same time.
 */
export const WORKSPACE = "/home/kasama/workspace";
export const DESKTOP_LEASE_SECONDS = 120;

/** "Research Bot!" → "research-bot" (the shared slug rule; "bot" when nothing is left). */
export const folderSlug = (name: string) => slugify(name, "bot");

/** The bot's folder name on its team computer, picked once from its name (renames keep it). */
export async function teamFolder(db: Database, botId: string): Promise<string> {
  const [bot] = await db.execute<{ team_folder: string | null; name: string; org_id: string }>(
    sql`select team_folder, name, org_id from public.bots where id = ${botId}::uuid`,
  );
  if (!bot) throw new Error("bot_not_found");
  if (bot.team_folder) return bot.team_folder;
  const base = folderSlug(bot.name);
  for (let n = 1; n <= 50; n++) {
    const candidate = n === 1 ? base : `${base}-${n}`;
    try {
      const [row] = await db.execute<{ team_folder: string }>(sql`
        update public.bots set team_folder = coalesce(team_folder, ${candidate})
        where id = ${botId}::uuid
          and not exists (select 1 from public.bots o where o.org_id = ${bot.org_id}::uuid and o.team_folder = ${candidate} and o.id <> ${botId}::uuid)
        returning team_folder`);
      if (row) return row.team_folder;
    } catch (err) {
      if (!/duplicate key|unique/i.test((err as Error).message)) throw err;
    }
  }
  throw new Error("no_team_folder");
}

/**
 * A handle whose relative paths start in the bot's folder. Paths under `shared/` or `bots/` stay
 * relative to the workspace (so every bot reaches the shared folder the same way); absolute and
 * home (`~`) paths are left alone.
 */
export function inTeamFolder(h: SandboxHandle, folder: string): SandboxHandle {
  const own = `bots/${folder}`;
  const resolve = (p: string | undefined): string => {
    const v = (p ?? "").trim().replace(/^\.\/+/, "");
    if (!v || v === ".") return own;
    if (v.startsWith("/") || v.startsWith("~")) return v;
    if (v === "shared" || v.startsWith("shared/") || v === "bots" || v.startsWith("bots/")) return v;
    return `${own}/${v}`;
  };
  const absolute = (p: string | undefined) => {
    const r = resolve(p);
    return r.startsWith("/") || r.startsWith("~") ? r : `${WORKSPACE}/${r}`;
  };
  let made: Promise<void> | null = null;
  const ensure = () => {
    made ??= (async () => {
      for await (const _ of h.exec(`mkdir -p ${WORKSPACE}/${own} ${WORKSPACE}/shared`, { timeoutMs: 30_000 })) {
        // drain
      }
    })().catch(() => {
      made = null;
    });
    return made;
  };
  return {
    ...h,
    resolvePath: resolve,
    exec: (cmd: string, opts?: ExecOptions) => {
      const inner = h;
      return (async function* () {
        await ensure();
        yield* inner.exec(cmd, { ...opts, cwd: absolute(opts?.cwd) });
      })();
    },
    readFile: (p) => h.readFile(resolve(p)),
    writeFile: async (p, data) => {
      await ensure();
      return h.writeFile(resolve(p), data);
    },
    deleteFile: (p) => h.deleteFile(resolve(p)),
    listDir: async (p) => {
      await ensure();
      return h.listDir(resolve(p));
    },
    search: (q, p) => h.search(q, p === undefined ? undefined : resolve(p)),
  };
}

/**
 * Takes (or renews) this bot's desktop lease on a team computer. Returns the names of the bots
 * holding the desktop when the cap is reached, or null when this bot may use it.
 */
export async function claimDesktop(
  db: Database,
  c: { id: string; org_id: string },
  botId: string,
  runId: string,
): Promise<string[] | null> {
  return db.transaction(async (tx) => {
    // One claim at a time per computer, so two bots can't both take the last place.
    await tx.execute(sql`select 1 from public.computers where id = ${c.id}::uuid for update`);
    await tx.execute(sql`delete from public.computer_desktop_leases where computer_id = ${c.id}::uuid and expires_at < now()`);
    const [cap] = await tx.execute<{ max_desktops: number }>(sql`select max_desktops from public.computers where id = ${c.id}::uuid`);
    const others = await tx.execute<{ name: string }>(sql`
      select b.name from public.computer_desktop_leases l join public.bots b on b.id = l.bot_id
      where l.computer_id = ${c.id}::uuid and l.bot_id <> ${botId}::uuid order by l.expires_at`);
    if (others.length >= (cap?.max_desktops ?? 1)) return others.map((o) => o.name);
    await tx.execute(sql`
      insert into public.computer_desktop_leases (computer_id, bot_id, org_id, run_id, expires_at)
      values (${c.id}::uuid, ${botId}::uuid, ${c.org_id}::uuid, ${runId}::uuid, now() + make_interval(secs => ${DESKTOP_LEASE_SECONDS}))
      on conflict (computer_id, bot_id) do update set run_id = excluded.run_id, expires_at = excluded.expires_at`);
    return null;
  });
}

/** Gives up a run's desktop leases (when it ends). */
export async function releaseDesktop(db: Database, runId: string) {
  await db.execute(sql`delete from public.computer_desktop_leases where run_id = ${runId}::uuid`);
}
