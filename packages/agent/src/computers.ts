import { type Database, liftTimeouts } from "@casama/db";
import { captureError } from "@casama/observability";
import type { CheckpointRef, SandboxHandle, SandboxProvider, SnapshotRef } from "@casama/sandbox";
import { sql } from "drizzle-orm";
import { track } from "./analytics.ts";

/**
 * Idle computers sleep after 5 minutes (D-178); waking restores their files. Only bots, running
 * commands and a person's input or presence keep them awake (D-195, apps/server/src/api/keep-awake.ts).
 */
export const IDLE_SLEEP_MS = 5 * 60_000;
export const CHECKPOINT_KEEP = 20;
export const CHECKPOINT_MAX_AGE_DAYS = 7;

/** What a computer costs per hour: per vCPU plus per GiB of memory (USD, D-180). */
export interface ComputerRate {
  cpu_hour: number;
  gb_hour: number;
}

/**
 * Default computer prices by provider. E2B and Daytona: their published per-second prices
 * ($0.000014 per vCPU-second, $0.0000045 per GiB-second; 2 vCPU / 4 GiB ≈ $0.166 an hour).
 * Docker on our own servers: a Hetzner CPX42 (8 vCPU / 16 GB, about $75 a month) spread over what
 * it holds, memory being the limit (1 vCPU / 1 GB ≈ $0.008 an hour). Local computers are the
 * person's own. Cloud Connect computers: Casama Cloud's price per computer-hour.
 * Override with COMPUTER_RATES (JSON by provider). See docs/COSTS.md.
 */
const DOCKER_RATE: ComputerRate = { cpu_hour: 0.003, gb_hour: 0.005 };
export const COMPUTER_RATES: Record<string, ComputerRate> = {
  docker: DOCKER_RATE,
  e2b: { cpu_hour: 0.0504, gb_hour: 0.0162 },
  daytona: { cpu_hour: 0.0504, gb_hour: 0.0162 },
  local: { cpu_hour: 0, gb_hour: 0 },
  "casama-cloud": { cpu_hour: 0.05, gb_hour: 0 },
};

/** The default rates with COMPUTER_RATES' overrides (JSON by provider) on top. */
export function computerRates(json?: string): Record<string, ComputerRate> {
  if (!json) return COMPUTER_RATES;
  const parsed = JSON.parse(json) as Record<string, Partial<ComputerRate>>;
  const out = { ...COMPUTER_RATES };
  for (const [id, r] of Object.entries(parsed)) {
    const base = out[id] ?? DOCKER_RATE;
    const cpu = r.cpu_hour ?? base.cpu_hour;
    const gb = r.gb_hour ?? base.gb_hour;
    if (!(cpu >= 0 && gb >= 0)) throw new Error(`COMPUTER_RATES: bad rate for ${id}`);
    out[id] = { cpu_hour: cpu, gb_hour: gb };
  }
  return out;
}

/** What `seconds` of a computer of this size cost on this provider, in USD. */
export function computerCostUsd(
  provider: string,
  size: { cpus?: number; memory_mb?: number } | null | undefined,
  seconds: number,
  rates: Record<string, ComputerRate> = COMPUTER_RATES,
): number {
  const r = rates[provider] ?? rates.docker ?? DOCKER_RATE;
  const cpus = size?.cpus ?? 1;
  const gb = (size?.memory_mb ?? 1024) / 1024;
  return (seconds / 3600) * (r.cpu_hour * cpus + r.gb_hour * gb);
}

export interface ComputerRow {
  id: string;
  org_id: string;
  kind: string;
  owner_bot_id: string | null;
  profile: "headless" | "desktop";
  /** Switched to the desktop only for a takeover: back to headless on the next sleep. */
  desktop_for_takeover?: boolean;
  provider?: string;
  state: string;
  size: { cpus?: number; memory_mb?: number };
  snapshot_ref: SnapshotRef | null;
  running_since: Date | null;
  [key: string]: unknown;
}

/** The provider plus optional object deletion (the supervisor client has it). */
export type ComputerProvider = SandboxProvider & {
  deleteObjects?: (keys: string[]) => Promise<void>;
  /** The same backend scoped to one provider (docker, e2b, daytona); see D-056. */
  forProvider?: (id: string) => ComputerProvider;
};

type Emit = (type: string, payload: Record<string, unknown>) => Promise<void>;

/**
 * Computer lifecycle on top of a SandboxProvider: provisioning on demand, idle sleep to object
 * storage, restore on the next use, checkpoints with retention, and computer-second usage.
 */
export class ComputerService {
  readonly db: Database;
  readonly provider: ComputerProvider;
  /** Providers that are not behind the supervisor (the `local` desktop companion, D-066). */
  readonly extra: Record<string, ComputerProvider>;
  /** Casama Cloud (D-094): free-plan workspaces start computers only with a verified owner email. */
  requireVerifiedEmail = false;
  /** Prices for computer-seconds usage (D-180). */
  rates: Record<string, ComputerRate> = COMPUTER_RATES;
  constructor(
    db: Database,
    provider: ComputerProvider,
    extra: Record<string, ComputerProvider> = {},
  ) {
    this.db = db;
    this.provider = provider;
    this.extra = extra;
  }

  /** The computer a bot uses: its default, else its private computer, else the org's team computer. */
  async forBot(botId: string): Promise<ComputerRow> {
    const [row] = await this.db.execute<ComputerRow>(sql`
      select c.* from public.bots b
      join public.computers c on c.org_id = b.org_id
      where b.id = ${botId}::uuid
        and (c.id = b.default_computer_id or (b.default_computer_id is null and (c.owner_bot_id = b.id or c.kind = 'team')))
      order by (c.id = b.default_computer_id) desc nulls last, (c.owner_bot_id = b.id) desc nulls last
      limit 1`);
    if (!row) throw new Error("no_computer");
    return row;
  }

  /** The provider a computer runs on. */
  providerFor(c: ComputerRow): ComputerProvider {
    const id = typeof c.provider === "string" ? c.provider : "docker";
    if (this.extra[id]) return this.extra[id];
    return id === "docker" ? this.provider : (this.provider.forProvider?.(id) ?? this.provider);
  }

  /** Destroys a computer's sandbox and stored archives, then deletes it. */
  async remove(computerId: string) {
    const c = await this.byId(computerId);
    if (!c) return;
    const p = this.providerFor(c);
    if (await p.get(computerId).catch(() => null)) await this.recordUsage(c);
    await p.destroy(computerId);
    const cps = await this.db.execute<{ key: string }>(
      sql`select storage_ref ->> 'key' as key from public.checkpoints where computer_id = ${computerId}::uuid`,
    );
    const keys = [...cps.map((r) => r.key), ...(c.snapshot_ref?.key ? [c.snapshot_ref.key] : [])];
    if (keys.length) await this.provider.deleteObjects?.(keys).catch(() => {});
    await this.db.execute(sql`delete from public.computers where id = ${computerId}::uuid`);
  }

  async byId(id: string): Promise<ComputerRow | null> {
    const [row] = await this.db.execute<ComputerRow>(
      sql`select * from public.computers where id = ${id}::uuid`,
    );
    return row ?? null;
  }

  private async setState(
    id: string,
    state: string,
    emit?: Emit,
    extra: Record<string, unknown> = {},
  ) {
    await this.db.execute(sql`
      update public.computers set state = ${state}, error = ${(extra.error as string) ?? null},
        running_since = case when ${state} = 'running' then coalesce(running_since, now()) when ${state} in ('sleeping', 'stopped', 'error') then null else running_since end,
        last_active_at = case when ${state} = 'running' then now() else last_active_at end
      where id = ${id}::uuid`);
    await emit?.("computer.state", { computer_id: id, state });
  }

  /**
   * Makes the stored state match the sandbox: a row says running but the container is gone (host
   * restart, crash), or says asleep but the container is still up (a sleep that didn't finish).
   * Returns the state it settled on. Starting, provisioning and local computers are left alone.
   */
  async reconcile(computerId: string): Promise<string | null> {
    const c = await this.byId(computerId);
    if (!c || c.kind === "local") return c?.state ?? null;
    if (c.state === "starting" || c.state === "provisioning") return c.state;
    const h = await this.providerFor(c)
      .get(computerId)
      .catch(() => undefined);
    if (h === undefined) return c.state; // provider unreachable: don't guess
    const up = !!h && !!(await h.health().catch(() => null));
    const saysUp = c.state === "running" || c.state === "idle";
    if (saysUp && !up) {
      await this.recordUsage(c);
      await this.setState(computerId, c.snapshot_ref ? "sleeping" : "stopped");
      return c.snapshot_ref ? "sleeping" : "stopped";
    }
    if (!saysUp && up) {
      await this.setState(computerId, "running");
      return "running";
    }
    return c.state;
  }

  /** Records computer-seconds for the interval that is ending. */
  private async recordUsage(c: ComputerRow) {
    if (!c.running_since) return;
    const seconds = Math.max(
      0,
      Math.round((Date.now() - new Date(c.running_since).getTime()) / 1000),
    );
    if (seconds === 0) return;
    const provider = typeof c.provider === "string" ? c.provider : "docker";
    const cost = computerCostUsd(provider, c.size, seconds, this.rates);
    await this.db.execute(sql`
      insert into public.usage_ledger (org_id, bot_id, kind, quantity, cost_usd)
      values (${c.org_id}::uuid, ${c.owner_bot_id}::uuid, 'computer_seconds', ${seconds}, ${cost})`);
  }

  /** Makes sure the computer is running and returns its handle. Serialized per computer. */
  async ensureRunning(computerId: string, emit?: Emit): Promise<SandboxHandle> {
    return this.db.transaction(async (tx) => {
      // Provisioning can take minutes while this holds the lock (and others wait on it).
      await liftTimeouts(tx);
      await tx.execute(sql`select pg_advisory_xact_lock(hashtext(${`computer:${computerId}`}))`);
      const [c] = await tx.execute<ComputerRow>(
        sql`select * from public.computers where id = ${computerId}::uuid`,
      );
      if (!c) throw new Error("computer_not_found");
      if (c.state === "running" || c.state === "idle") {
        const h = await this.providerFor(c).get(computerId);
        if (h) {
          await tx.execute(
            sql`update public.computers set last_active_at = now(), state = 'running' where id = ${computerId}::uuid`,
          );
          return h;
        }
      }
      // The computer funnel (F5): requested → ready or failed. Workspace-level (no person), ids and enums only.
      const started = Date.now();
      const facts = {
        kind: c.kind,
        provider: c.provider ?? null,
        mode: c.snapshot_ref ? "restore" : "provision",
      };
      track(this.db, { event: "computer_start_requested", orgId: c.org_id, properties: facts });
      try {
        await this.checkCanStart(c.org_id, { credits: c.kind !== "local" });
      } catch (err) {
        track(this.db, {
          event: "computer_start_failed",
          orgId: c.org_id,
          properties: { ...facts, reason: (err as { code?: string }).code ?? "refused" },
        });
        throw err;
      }
      await this.setState(computerId, c.snapshot_ref ? "starting" : "provisioning", emit);
      try {
        const spec = {
          profile: c.profile,
          size: { cpus: c.size?.cpus, memoryMb: c.size?.memory_mb },
          labels: { "dev.casama.org": c.org_id },
        };
        const h = await this.providerFor(c).resume(computerId, c.snapshot_ref ?? undefined, spec);
        await this.setState(computerId, "running", emit);
        track(this.db, {
          event: "computer_ready",
          orgId: c.org_id,
          properties: { ...facts, start_ms: Date.now() - started },
        });
        return h;
      } catch (err) {
        track(this.db, {
          event: "computer_start_failed",
          orgId: c.org_id,
          properties: { ...facts, reason: "provider_error" },
        });
        await this.setState(computerId, "error", emit, {
          error: (err as Error).message.slice(0, 500),
        });
        throw err;
      }
    });
  }

  /**
   * Throws workspace_suspended or email_unverified when a computer must not start (D-094).
   * With credits, a credit-gated workspace that has nothing left cannot start a hosted computer.
   */
  async checkCanStart(orgId: string, opts: { credits?: boolean } = {}) {
    const [o] = await this.db.execute<{
      suspended: boolean;
      plan: string | null;
      verified: boolean;
      gate: boolean | null;
      credits: string | null;
      unbilled: string | null;
    }>(sql`
      select o.suspended_at is not null as suspended,
             (select e.plan_code from public.entitlements e where e.org_id = o.id order by e.created_at desc limit 1) as plan,
             public.worker_owner_email_verified(o.id) as verified,
             (select (e.limits->>'credit_gate')::boolean from public.entitlements e where e.org_id = o.id order by e.created_at desc limit 1) as gate,
             (select balance_after from public.credit_ledger where org_id = o.id order by seq desc limit 1) as credits,
             (select coalesce(sum(cost_usd), 0) from public.usage_ledger where org_id = o.id and billable and billed_at is null) as unbilled
      from public.organizations o where o.id = ${orgId}::uuid`);
    if (o?.suspended) throw new Error("workspace_suspended");
    if (this.requireVerifiedEmail && (o?.plan ?? "free") === "free" && !o?.verified)
      throw new Error("email_unverified");
    if (opts.credits && o?.gate && Number(o.credits ?? 0) - Number(o.unbilled ?? 0) <= 0)
      throw new Error("out_of_credits");
  }

  async touch(computerId: string) {
    await this.db.execute(
      sql`update public.computers set last_active_at = now() where id = ${computerId}::uuid`,
    );
  }

  /** Archives the home directory to object storage and stops the computer. */
  async sleep(computerId: string, emit?: Emit) {
    const c = await this.byId(computerId);
    if (!c) throw new Error("computer_not_found");
    const p = this.providerFor(c);
    if (!(await p.get(computerId))) {
      await this.setState(computerId, c.snapshot_ref ? "sleeping" : "stopped", emit);
      await this.endTakeoverDesktop(c);
      return;
    }
    const snap = await p.sleep(computerId);
    await this.recordUsage(c);
    await this.db.execute(
      sql`update public.computers set snapshot_ref = ${JSON.stringify(snap)}::jsonb where id = ${computerId}::uuid`,
    );
    await this.setState(computerId, "sleeping", emit);
    await this.endTakeoverDesktop(c);
    if (c.snapshot_ref?.key && c.snapshot_ref.key !== snap.key)
      await this.provider.deleteObjects?.([c.snapshot_ref.key]).catch(() => {});
  }

  /**
   * A computer switched to the desktop only for a takeover wakes up headless once no takeover is
   * open (D-178): a desktop needs about four times the memory.
   */
  private async endTakeoverDesktop(c: ComputerRow) {
    if (c.profile !== "desktop" || !c.desktop_for_takeover) return;
    await this.db.execute(sql`
      update public.computers set profile = 'headless', desktop_for_takeover = false
      where id = ${c.id}::uuid and not exists (
        select 1 from public.takeover_requests t
        where t.computer_id = ${c.id}::uuid and t.status in ('pending', 'taken') and t.expires_at > now())`);
  }

  /**
   * Sleeps running computers with no activity or running commands for idleMs. An open terminal
   * alone no longer counts (D-195): its keystrokes and the app's presence beat touch the computer,
   * so a terminal someone is using, or a command they watch, stays awake through last_active_at.
   */
  async sleepIdle(idleMs = IDLE_SLEEP_MS) {
    const rows = await this.db.execute<ComputerRow>(sql`
      select * from public.computers
      where state in ('running', 'idle') and kind <> 'local' and coalesce(last_active_at, created_at) < now() - (${idleMs} * interval '1 millisecond')`);
    const slept: string[] = [];
    for (const c of rows) {
      const h = await this.providerFor(c)
        .get(c.id)
        .catch(() => null);
      if (h) {
        const health = await h.health().catch(() => null);
        if (health && health.runningExecs > 0) {
          await this.touch(c.id);
          continue;
        }
      }
      await this.sleep(c.id).catch((err) =>
        captureError(err, { service: "casama-worker", step: "idle-sleep", computer_id: c.id }),
      );
      slept.push(c.id);
    }
    return slept;
  }

  /** Stops a computer, keeping its files (sleep). */
  async stop(computerId: string, emit?: Emit) {
    await this.sleep(computerId, emit);
  }

  async checkpoint(
    computerId: string,
    label: string,
    runId: string | null,
    handle?: SandboxHandle,
  ) {
    const c = await this.byId(computerId);
    if (!c) throw new Error("computer_not_found");
    const h = handle ?? (await this.ensureRunning(computerId));
    const ref: CheckpointRef = await h.checkpoint(label);
    const [row] = await this.db.execute<{ id: string }>(sql`
      insert into public.checkpoints (org_id, computer_id, run_id, label, storage_ref)
      values (${c.org_id}::uuid, ${computerId}::uuid, ${runId}::uuid, ${label.slice(0, 200)}, ${JSON.stringify(ref)}::jsonb)
      returning id`);
    await this.prune(computerId);
    return { checkpointId: row?.id as string, ref };
  }

  /** Keeps the last 20 checkpoints per computer or 7 days, whichever is fewer. */
  async prune(computerId: string) {
    const doomed = await this.db.execute<{ id: string; key: string }>(sql`
      delete from public.checkpoints where id in (
        select id from (
          select id, created_at, row_number() over (order by created_at desc) as n
          from public.checkpoints where computer_id = ${computerId}::uuid
        ) t where n > ${CHECKPOINT_KEEP} or created_at < now() - (${CHECKPOINT_MAX_AGE_DAYS} * interval '1 day')
      ) returning id, storage_ref ->> 'key' as key`);
    if (doomed.length)
      await this.provider.deleteObjects?.(doomed.map((d) => d.key)).catch(() => {});
    return doomed.length;
  }

  async restoreCheckpoint(checkpointId: string) {
    const [cp] = await this.db.execute<{ computer_id: string; storage_ref: CheckpointRef }>(
      sql`select computer_id, storage_ref from public.checkpoints where id = ${checkpointId}::uuid`,
    );
    if (!cp) throw new Error("checkpoint_not_found");
    const h = await this.ensureRunning(cp.computer_id);
    await h.restore(cp.storage_ref);
    await this.touch(cp.computer_id);
    return cp.computer_id;
  }
}
