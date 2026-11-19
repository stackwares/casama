/**
 * One run at a time drives a computer's screen: its browser and its desktop (D-413).
 *
 * A bot has one computer with one browser. Two of its runs working at once (two topics, a routine
 * beside a chat) both drove that browser: one run's snapshot showed the other's page, and its click
 * landed there. On a team computer the same happened between bots. The run that uses the screen now
 * holds a lease on it; another run waits a while for it, and is then told who has it.
 */
import type { Database } from "@casama/db";
import { sql } from "drizzle-orm";

/** A lease is renewed with each use; this long after the last one the screen is free again. */
export const SCREEN_LEASE_SECONDS = 120;
/** How long a run waits for the screen before it is told it's in use. */
export const SCREEN_WAIT_MS = 90_000;
const SCREEN_POLL_MS = 3_000;

export interface ScreenHolder {
  bot: string;
  /** The chat the holding run works in, when it has a title. */
  chat: string | null;
  /** The same bot, in another of its runs. */
  sameBot: boolean;
}

/**
 * Takes (or renews) the screen for a run. Returns null when the run holds it, else who does.
 *
 * The screen is free when nobody holds it, the lease ran out, or the holding run has ended. A run
 * that this run was asked by (a sub-run's parent, at any depth) doesn't block it: it is waiting for
 * this one, so both are the same piece of work.
 */
export async function claimScreen(
  db: Database,
  computer: { id: string; org_id: string },
  run: { runId: string; botId: string },
): Promise<ScreenHolder | null> {
  return db.transaction(async (tx) => {
    // One claim at a time per computer, so two runs can't both find it free.
    await tx.execute(
      sql`select pg_advisory_xact_lock(hashtextextended(${`screen:${computer.id}`}, 0))`,
    );
    const [held] = await tx.execute<{
      run_id: string;
      bot_id: string;
      bot: string | null;
      chat: string | null;
      live: boolean;
      family: boolean;
    }>(sql`
      with recursive asked_by as (
        select parent_run_id as id, 0 as depth from public.runs where id = ${run.runId}::uuid
        union all
        select r.parent_run_id, a.depth + 1 from public.runs r join asked_by a on r.id = a.id
        where a.id is not null and a.depth < 8
      )
      select l.run_id, l.bot_id, b.name as bot, c.title as chat,
             l.expires_at > now()
               and coalesce(r.status in ('queued', 'running', 'waiting_approval', 'waiting_takeover'), false) as live,
             l.run_id in (select id from asked_by where id is not null) as family
      from public.computer_screen_leases l
      left join public.runs r on r.id = l.run_id
      left join public.bots b on b.id = l.bot_id
      left join public.conversations c on c.id = r.conversation_id
      where l.computer_id = ${computer.id}::uuid`);
    if (held && held.run_id !== run.runId && held.live && !held.family)
      return {
        bot: held.bot ?? "another bot",
        chat: held.chat,
        sameBot: held.bot_id === run.botId,
      };
    await tx.execute(sql`
      insert into public.computer_screen_leases (computer_id, org_id, bot_id, run_id, expires_at)
      values (${computer.id}::uuid, ${computer.org_id}::uuid, ${run.botId}::uuid, ${run.runId}::uuid,
              now() + make_interval(secs => ${SCREEN_LEASE_SECONDS}))
      on conflict (computer_id) do update
        set org_id = excluded.org_id, bot_id = excluded.bot_id, run_id = excluded.run_id, expires_at = excluded.expires_at`);
    return null;
  });
}

/**
 * Waits for the screen up to [waitMs] (it is usually given back within seconds: a run ended, or
 * finished the part that needed the browser). Returns null once this run holds it, else who still
 * does. Stops waiting when the run was stopped.
 */
export async function waitForScreen(
  db: Database,
  computer: { id: string; org_id: string },
  run: { runId: string; botId: string },
  opts: { waitMs?: number; pollMs?: number } = {},
): Promise<ScreenHolder | null> {
  const until = Date.now() + (opts.waitMs ?? SCREEN_WAIT_MS);
  for (;;) {
    const holder = await claimScreen(db, computer, run);
    if (!holder || Date.now() >= until) return holder;
    const [r] = await db.execute<{ stopped: boolean }>(sql`
      select cancel_requested_at is not null as stopped from public.runs where id = ${run.runId}::uuid`);
    if (r?.stopped) return holder;
    await new Promise((resolve) => setTimeout(resolve, opts.pollMs ?? SCREEN_POLL_MS));
  }
}

/** What a run is told when the screen stayed in use. */
export function screenBusyMessage(h: ScreenHolder) {
  const where = h.chat ? ` ("${h.chat.slice(0, 80)}")` : "";
  const who = h.sameBot
    ? `You are using your computer's browser and screen in another chat right now${where}`
    : `${h.bot} is using this computer's browser and screen right now${where}`;
  return `${who}, and only one piece of work can use them at a time. Go on with what doesn't need them (shell, files, web.fetch, web.search), or try again in a few minutes. If this can't be done without them, tell the person it is waiting for the other work to finish.`;
}

/** Gives the screen back when a run ends. */
export async function releaseScreen(db: Database, runId: string) {
  await db.execute(sql`delete from public.computer_screen_leases where run_id = ${runId}::uuid`);
}
