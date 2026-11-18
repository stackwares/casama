/**
 * System permission cards (D-376, docs/OS-PERMISSIONS-PLAN.md). When a tool hits a switch only the
 * person can flip on their own device (Accessibility, Screen Recording, Location…), the run shows
 * them a card with a button per permission instead of trusting the model to write out the steps.
 *
 * The thing that failed posts the card (the D-328 lesson: a bot once said it had sent a card it
 * never sent). A run shows each device and permission once; "Not now" quiets that bot for 24 hours.
 */
import type { Database } from "@casama/db";
import {
  deviceRef,
  OS_PERMISSIONS,
  osPermission,
  osPermissionForKind,
  osPermissionList,
  osPermissionMissing,
  osPermissionOn,
  osPermissionsFromToolError,
} from "@casama/domain";
import { sql } from "drizzle-orm";

/** A device of the person's that a card can be about. */
export interface PermissionDevice {
  ref: string;
  type: "computer" | "source";
  id: string;
  userId: string;
  name: string;
  platform: string;
  /** What the device last reported, plus Casama's own settings for computers. */
  permissions: Record<string, string>;
  snoozes: Record<string, string>;
  lastSeenAt: Date | null;
  /** Data kinds a source shares (D-149). */
  kinds: string[];
}

type ComputerRow = {
  id: string;
  user_id: string;
  name: string;
  platform: string;
  permissions: Record<string, string> | null;
  permission_snoozes: Record<string, string> | null;
  allowed_roots: string[] | null;
  capabilities: Record<string, unknown> | null;
  last_seen_at: Date | null;
};
type SourceRow = {
  id: string;
  user_id: string;
  name: string;
  platform: string;
  permissions: Record<string, string> | null;
  permission_snoozes: Record<string, string> | null;
  kinds: Record<string, unknown> | null;
  last_seen_at: Date | null;
};

/** Casama's own settings on a computer count as permissions too (D-376 §1). */
export function computerPermissions(row: {
  permissions: Record<string, string> | null;
  allowed_roots: string[] | null;
  capabilities: Record<string, unknown> | null;
}): Record<string, string> {
  return {
    ...(row.permissions ?? {}),
    shared_folders: (row.allowed_roots ?? []).length ? "granted" : "denied",
    local_tools: row.capabilities?.mcp ? "granted" : "denied",
  };
}

const fromComputer = (r: ComputerRow): PermissionDevice => ({
  ref: deviceRef("computer", r.id),
  type: "computer",
  id: r.id,
  userId: r.user_id,
  name: r.name,
  platform: r.platform,
  permissions: computerPermissions(r),
  snoozes: r.permission_snoozes ?? {},
  lastSeenAt: r.last_seen_at ? new Date(r.last_seen_at) : null,
  kinds: [],
});
const fromSource = (r: SourceRow): PermissionDevice => ({
  ref: deviceRef("source", r.id),
  type: "source",
  id: r.id,
  userId: r.user_id,
  name: r.name,
  platform: r.platform,
  permissions: r.permissions ?? {},
  snoozes: r.permission_snoozes ?? {},
  lastSeenAt: r.last_seen_at ? new Date(r.last_seen_at) : null,
  kinds: Object.keys(r.kinds ?? {}),
});

/** The person's own computer this bot works on (D-066), if that's what it uses. */
export async function botOwnComputer(
  db: Database,
  botId: string,
): Promise<PermissionDevice | null> {
  const [r] = await db.execute<ComputerRow>(sql`
    select d.id, d.user_id, d.name, d.platform, d.permissions, d.permission_snoozes, d.allowed_roots,
           d.capabilities, d.last_seen_at
    from public.bots b
    join public.computers c on c.id = b.default_computer_id and c.kind = 'local'
    join public.local_devices d on d.computer_id = c.id
    where b.id = ${botId}::uuid limit 1`);
  return r ? fromComputer(r) : null;
}

/** Every device of the person's: computers they use for bots, then devices that share data. */
export async function personDevices(db: Database, userId: string): Promise<PermissionDevice[]> {
  const computers = await db.execute<ComputerRow>(sql`
    select id, user_id, name, platform, permissions, permission_snoozes, allowed_roots, capabilities, last_seen_at
    from public.local_devices where user_id = ${userId}::uuid and computer_id is not null
    order by last_seen_at desc nulls last`);
  const sources = await db.execute<SourceRow>(sql`
    select id, user_id, name, platform, permissions, permission_snoozes, kinds, last_seen_at
    from public.device_sources where user_id = ${userId}::uuid order by last_seen_at desc nulls last`);
  return [...computers.map(fromComputer), ...sources.map(fromSource)];
}

export async function sourceDevice(db: Database, id: string): Promise<PermissionDevice | null> {
  const [r] = await db.execute<SourceRow>(sql`
    select id, user_id, name, platform, permissions, permission_snoozes, kinds, last_seen_at
    from public.device_sources where id = ${id}::uuid`);
  return r ? fromSource(r) : null;
}

/** Cards already shown, by run, device and permission: a run shows each one once. */
const shown = new Set<string>();

export interface CardTarget {
  runId: string;
  botId: string;
  emit(type: string, payload: Record<string, unknown>): Promise<void>;
}

export interface CardOutcome {
  /** On the card now (or already shown earlier in this run). */
  shown: string[];
  /** The person said "Not now" to these recently. */
  snoozed: string[];
}

const snoozedNow = (d: PermissionDevice, botId: string, id: string) => {
  const until = d.snoozes[`${botId}:${id}`];
  return !!until && new Date(until).getTime() > Date.now();
};

/**
 * Shows a card for these permissions on the device: only ones its platform has, not snoozed by
 * this bot, once per run. Emits `device.permission_needed` when anything is new.
 */
export async function showPermissionCard(
  t: CardTarget,
  device: PermissionDevice,
  ids: readonly string[],
  reason?: string,
): Promise<CardOutcome> {
  const usable = [...new Set(ids)].filter((id) => osPermissionOn(id, device.platform));
  const snoozed = usable.filter((id) => snoozedNow(device, t.botId, id));
  const want = usable.filter((id) => !snoozed.includes(id));
  const fresh = want.filter((id) => !shown.has(`${t.runId}:${device.ref}:${id}`));
  if (fresh.length) {
    if (shown.size > 5000) shown.clear();
    for (const id of fresh) shown.add(`${t.runId}:${device.ref}:${id}`);
    await t.emit("device.permission_needed", {
      device_ref: device.ref,
      device_name: device.name,
      platform: device.platform,
      permissions: fresh,
      reason: (reason?.trim() || osPermission(fresh[0]!)?.why || "So I can do this").slice(0, 300),
      bot_id: t.botId,
    });
  }
  return { shown: want, snoozed };
}

/** What the model is told after a card (or a "Not now"). */
export function cardText(outcome: CardOutcome, device: PermissionDevice): string {
  const parts: string[] = [];
  if (outcome.shown.length)
    parts.push(
      `The person now sees a card to turn on ${osPermissionList(outcome.shown)} on ${device.name}. Tell them in one short line to tap it, then wait for them; don't write out the steps.`,
    );
  if (outcome.snoozed.length)
    parts.push(
      `They said not now to ${osPermissionList(outcome.snoozed)} on ${device.name} recently; don't ask again, carry on without it.`,
    );
  return parts.join(" ");
}

/**
 * A failed tool on the person's own computer that points at a permission (agent-desktop's
 * PERM_DENIED, computerd's screen_recording_denied, no shared folders, an MCP server's
 * casama_permission): shows the card and returns text to add to the model's error, or null.
 */
export async function cardForToolError(
  db: Database,
  t: CardTarget & { actingUserId: string | null | undefined },
  code: string,
  message: string,
): Promise<string | null> {
  const ids = osPermissionsFromToolError(code, message);
  if (!ids.length || !t.actingUserId) return null;
  const device = await botOwnComputer(db, t.botId);
  // Only on the person's own computer, in their own run (D-131: nobody else's run uses it).
  if (!device || device.userId !== t.actingUserId) return null;
  const outcome = await showPermissionCard(t, device, ids);
  return cardText(outcome, device) || null;
}

/**
 * device.read and the device writes (D-149): when every device sharing the kind reports the system
 * permission it needs as off, the card goes to the most recently seen one. Null when the read can
 * go ahead.
 */
export async function cardForDeviceKind(
  db: Database,
  t: CardTarget,
  sources: Array<{ id: string; platform: string }>,
  kind: string,
): Promise<string | null> {
  if (!sources.length) return null;
  const devices = (
    await Promise.all(sources.map((s) => sourceDevice(db, s.id).catch(() => null)))
  ).filter((d): d is PermissionDevice => !!d);
  const blocked = devices.filter((d) => {
    const id = osPermissionForKind(kind, d.platform);
    return !!id && osPermissionMissing(d.permissions[id]);
  });
  if (!blocked.length || blocked.length < devices.length) return null;
  const device = [...blocked].sort(
    (a, b) => (b.lastSeenAt?.getTime() ?? 0) - (a.lastSeenAt?.getTime() ?? 0),
  )[0]!;
  const id = osPermissionForKind(kind, device.platform)!;
  const outcome = await showPermissionCard(t, device, [id]);
  return (
    cardText(outcome, device) ||
    `${osPermissionList([id])} is off on ${device.name}, so it can't share this.`
  );
}

/** Permissions worth a line in the bot's prompt, per device (the "who you're talking with" block). */
const COMPUTER_PROMPT = ["accessibility", "screen_recording", "automation"];

/**
 * One line per device with something off that matters: this bot's own computer (its desktop and
 * folders), and devices sharing data whose kinds need a permission that's off.
 */
export async function permissionLines(
  db: Database,
  userId: string,
  botId: string,
): Promise<string[]> {
  const own = await botOwnComputer(db, botId).catch(() => null);
  const devices = await personDevices(db, userId);
  const lines: string[] = [];
  for (const d of devices) {
    const off: string[] = [];
    let noFolders = false;
    if (d.type === "computer") {
      if (!own || own.id !== d.id) continue;
      off.push(...COMPUTER_PROMPT.filter((id) => osPermissionMissing(d.permissions[id])));
      noFolders = d.permissions.shared_folders === "denied";
    } else {
      for (const kind of d.kinds) {
        const id = osPermissionForKind(kind, d.platform);
        if (id && osPermissionMissing(d.permissions[id]) && !off.includes(id)) off.push(id);
      }
    }
    if (!off.length && !noFolders) continue;
    const said = [
      off.length ? `${osPermissionList(off)} ${off.length > 1 ? "are" : "is"} off` : "",
      noFolders ? "no shared folders" : "",
    ]
      .filter(Boolean)
      .join("; ");
    lines.push(`${d.name}: ${said}.`);
  }
  return lines;
}

/** Ids the registry knows, for tool schemas. */
export const PERMISSION_IDS = OS_PERMISSIONS.map((p) => p.id) as [string, ...string[]];
