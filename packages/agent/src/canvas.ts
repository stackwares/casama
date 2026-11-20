/**
 * Bot widgets (docs/BOT-WIDGET-PLAN.md §7, §9): the canvases bots keep on a person's Canvas
 * widget. A canvas belongs to one person and one bot; bots write through `widget.*`
 * (tools/widgets.ts), people read, pause and clear through the API, and widgets read with their
 * key. The rules (limits, short forms, contrast, rotations) live in @casama/domain.
 */
import { createHash } from "node:crypto";
import type { Canvas, CanvasEntry } from "@casama/contracts";
import { contentKeys, type Database } from "@casama/db";
import {
  CANVAS_LIMITS,
  type CanvasBackground,
  type CanvasContent,
  type CanvasEntryBody,
  type CanvasLook,
  currentEntries,
  DEFAULT_LOOK,
  inkFor,
  rhythmWords,
  rotationAt,
} from "@casama/domain";
import { sql } from "drizzle-orm";

export interface CanvasRow extends Record<string, unknown> {
  id: string;
  org_id: string;
  user_id: string;
  bot_id: string;
  name: string;
  content: CanvasContent;
  version: number;
  status: "waiting" | "shown" | "paused";
  hide_when_locked: boolean;
  until: Date | null;
  set_at: Date;
  set_by_run: string | null;
  bot_name: string;
  bot_avatar: string;
  conversation_id: string | null;
  writes_hour: number;
  hour_from: Date;
  writes_day: number;
  day_from: Date;
}

const SELECT = sql`
  select c.id, c.org_id, c.user_id, c.bot_id, c.name, c.content, c.version, c.status,
         c.hide_when_locked, c.until, c.set_at, c.set_by_run, c.writes_hour, c.hour_from,
         c.writes_day, c.day_from, b.name as bot_name, coalesce(b.avatar_url, '') as bot_avatar,
         r.conversation_id
  from public.widget_canvases c
  join public.bots b on b.id = c.bot_id
  left join public.runs r on r.id = c.set_by_run`;

const opened = (r: CanvasRow): CanvasRow => ({
  ...r,
  content: contentKeys.open(r.content) as CanvasContent,
  until: r.until ? new Date(r.until) : null,
  set_at: new Date(r.set_at),
  hour_from: new Date(r.hour_from),
  day_from: new Date(r.day_from),
});

const iso = (d: Date | string) => new Date(d).toISOString();

/** A canvas's look with an entry's own changes on top. */
export function mergeLook(base: CanvasLook, over?: Partial<CanvasLook>): CanvasLook {
  return { ...DEFAULT_LOOK, ...base, ...(over ?? {}) };
}

function backgroundOut(bg: CanvasBackground): Canvas["entries"][number]["look"]["background"] {
  const none = { color: null, from: null, to: null, picture: null };
  switch (bg.kind) {
    case "auto":
      return { kind: "auto", ...none };
    case "color":
      return { kind: "color", ...none, color: bg.color };
    case "gradient":
      return { kind: "gradient", ...none, from: bg.from, to: bg.to };
    case "picture":
      return { kind: "picture", ...none, picture: bg.picture };
    case "painting":
      return { kind: "picture", ...none, picture: `painting-${bg.name}` };
  }
}

/** One entry as widgets read it. */
export function entryOut(
  e: CanvasEntryBody & { at: string | null },
  look: CanvasLook,
): CanvasEntry {
  const l = mergeLook(look, e.look);
  // A picture entry draws its picture as the background, so the text colour follows it.
  const bg: CanvasBackground =
    e.template === "picture" && e.picture
      ? { kind: "picture", picture: e.picture.hash, tone: e.picture.tone }
      : l.background;
  return {
    at: e.at,
    template: e.template,
    title: e.title ?? null,
    text: e.text ?? null,
    footer: e.footer ?? null,
    target: e.target ?? null,
    count: e.template === "countdown" ? (e.count ?? "down") : null,
    value: e.value ?? null,
    of: e.of ?? null,
    unit: e.unit ?? null,
    items: e.items ?? [],
    picture: e.picture?.hash ?? null,
    short: e.short,
    tiny: e.tiny,
    look: {
      background: backgroundOut(l.background),
      font: l.font,
      align: l.align,
      icon: l.icon,
      accent: l.accent,
      ink: inkFor(bg),
    },
  };
}

/** A canvas as the API, the widgets and the preview card read it. */
export function canvasOut(r: CanvasRow, o: { private?: boolean; now?: number } = {}): Canvas {
  const now = o.now ?? Date.now();
  const c = r.content;
  const spot = c.rotation ? rotationAt(c.rotation, r.id, now) : null;
  return {
    id: r.id,
    org_id: r.org_id,
    name: r.name,
    bot_id: r.bot_id,
    bot: r.bot_name.slice(0, 80),
    bot_avatar: r.bot_avatar.slice(0, 64),
    status: r.status,
    hide_when_locked: r.hide_when_locked,
    version: r.version,
    set_at: iso(r.set_at),
    until: r.until ? iso(r.until) : null,
    link: r.conversation_id
      ? `/bots/${r.bot_id}/chat?c=${r.conversation_id}`
      : `/bots/${r.bot_id}/chat`,
    rotation:
      c.rotation && spot
        ? {
            count: c.rotation.items.length,
            showing: spot.item,
            left: spot.left,
            every: rhythmWords(c.rotation).slice(0, 120),
          }
        : null,
    entries: o.private ? [] : currentEntries(c, r.id, now).map((e) => entryOut(e, c.look)),
  };
}

/** Picture hashes a content names (backgrounds and picture entries). */
export function picturesOf(c: CanvasContent): string[] {
  const out = new Set<string>();
  const look = (l?: Partial<CanvasLook>) => {
    if (l?.background?.kind === "picture") out.add(l.background.picture);
  };
  look(c.look);
  for (const e of [...(c.entries ?? []), ...(c.rotation?.items ?? [])]) {
    look(e.look);
    if (e.picture) out.add(e.picture.hash);
  }
  return [...out];
}

/** One person's canvases in one workspace, newest first. Widgets see only shown ones. */
export async function listCanvases(
  db: Database,
  o: { userId: string; orgId: string; botId?: string; shownOnly?: boolean; now?: Date },
): Promise<CanvasRow[]> {
  const now = o.now ?? new Date();
  const rows = await db.execute<CanvasRow>(sql`${SELECT}
    where c.user_id = ${o.userId}::uuid and c.org_id = ${o.orgId}::uuid
      and (c.until is null or c.until > ${now.toISOString()}::timestamptz)
      ${o.botId ? sql`and c.bot_id = ${o.botId}::uuid` : sql``}
      ${o.shownOnly ? sql`and c.status = 'shown'` : sql``}
    order by c.set_at desc limit ${CANVAS_LIMITS.perPerson}`);
  return rows.map(opened);
}

export async function getCanvas(db: Database, id: string, userId: string) {
  const [r] = await db.execute<CanvasRow>(sql`${SELECT}
    where c.id = ${id}::uuid and c.user_id = ${userId}::uuid`);
  return r ? opened(r) : null;
}

/** The version a list answers `If-None-Match` with: a hash of what it shows. */
export function canvasListVersion(body: unknown): string {
  return createHash("sha256").update(JSON.stringify(body)).digest("base64url").slice(0, 22);
}

// ------------------------------------------------------------------ the grant

export async function widgetsAllowed(db: Database, userId: string, botId: string) {
  const rows = await db.execute(sql`
    select 1 from public.device_grants
    where user_id = ${userId}::uuid and bot_id = ${botId}::uuid and kind = 'widgets'`);
  return rows.length > 0;
}

/**
 * Show on my widgets, or the switch in Settings turned off. Allowing shows what the bot left
 * waiting; stopping clears what it showed.
 */
export async function setWidgetsAllowed(
  db: Database,
  userId: string,
  botId: string,
  allowed: boolean,
): Promise<{ shown: number; cleared: number }> {
  if (allowed) {
    await db.execute(sql`
      insert into public.device_grants (user_id, bot_id, kind)
      values (${userId}::uuid, ${botId}::uuid, 'widgets') on conflict do nothing`);
    const shown = await db.execute(sql`
      update public.widget_canvases set status = 'shown'
      where user_id = ${userId}::uuid and bot_id = ${botId}::uuid and status = 'waiting'
      returning id`);
    return { shown: shown.length, cleared: 0 };
  }
  await db.execute(sql`
    delete from public.device_grants
    where user_id = ${userId}::uuid and bot_id = ${botId}::uuid and kind = 'widgets'`);
  const gone = await db.execute(sql`
    delete from public.widget_canvases
    where user_id = ${userId}::uuid and bot_id = ${botId}::uuid returning id`);
  return { shown: 0, cleared: gone.length };
}

export async function widgetGrants(db: Database, userId: string, orgId: string) {
  return db.execute<{ bot_id: string; bot: string; created_at: Date }>(sql`
    select g.bot_id, b.name as bot, g.created_at from public.device_grants g
    join public.bots b on b.id = g.bot_id
    where g.user_id = ${userId}::uuid and g.kind = 'widgets' and b.org_id = ${orgId}::uuid
    order by b.name limit 200`);
}

// ------------------------------------------------------------------ where it shows

/** A Canvas widget drew this recently: it counts as placed. */
const PLACED_FOR_MS = 3 * 86_400_000;

export interface Placement {
  platform: "ios" | "android" | "macos";
  label: string | null;
  sizes: string[];
  seen_at: string;
}

/** The person's devices with a Canvas widget placed (they asked for canvases lately). */
export async function placements(
  db: Database,
  userId: string,
  orgId: string,
  now = Date.now(),
): Promise<Placement[]> {
  const rows = await db.execute<{
    platform: Placement["platform"];
    label: string | null;
    canvas_seen: { sizes?: string[]; at?: string } | null;
  }>(sql`
    select platform, label, canvas_seen from public.widget_keys
    where user_id = ${userId}::uuid and org_id = ${orgId}::uuid and canvas_seen is not null
    order by last_used_at desc nulls last limit 20`);
  return rows
    .filter((r) => r.canvas_seen?.at && now - Date.parse(r.canvas_seen.at) < PLACED_FOR_MS)
    .map((r) => ({
      platform: r.platform,
      label: r.label,
      sizes: (r.canvas_seen?.sizes ?? []).slice(0, 12),
      seen_at: iso(r.canvas_seen?.at as string),
    }));
}

const SIZE_NAMES = new Set([
  "home_small",
  "home_medium",
  "home_large",
  "home_xl",
  "lock_rect",
  "lock_inline",
  "lock_circle",
  "keyguard",
]);

/** A widget key's device asked for canvases: what sizes it draws (§7, `canvas_seen`). */
export async function recordCanvasSeen(db: Database, keyId: string, sizes: string | undefined) {
  const list = [...new Set((sizes ?? "").split(",").map((s) => s.trim()))].filter((s) =>
    SIZE_NAMES.has(s),
  );
  // An empty list means a widget fetched without a placed Canvas (the glance's widgets): no change.
  if (!list.length) return;
  await db.execute(sql`
    update public.widget_keys
    set canvas_seen = ${JSON.stringify({ sizes: list.sort(), at: new Date().toISOString() })}::jsonb
    where id = ${keyId}::uuid`);
}

/** "iPhone (Lock Screen, Home Screen) and Mac (desktop)": where a canvas shows, in words. */
export function placementWords(list: Placement[]): string {
  const device = (p: Placement) =>
    p.label?.trim() ||
    (p.platform === "ios" ? "iPhone" : p.platform === "macos" ? "Mac" : "Android phone");
  const where = (p: Placement) => {
    const lock = p.sizes.some((s) => s.startsWith("lock_") || s === "keyguard");
    const home = p.sizes.some((s) => s.startsWith("home_"));
    const parts = [
      lock ? (p.platform === "android" ? "lock screen" : "Lock Screen") : null,
      home ? (p.platform === "macos" ? "desktop" : "Home Screen") : null,
    ].filter(Boolean);
    return parts.length ? ` (${parts.join(", ")})` : "";
  };
  const items = list.map((p) => `${device(p)}${where(p)}`);
  if (items.length <= 1) return items[0] ?? "";
  return `${items.slice(0, -1).join(", ")} and ${items.at(-1)}`;
}

// ------------------------------------------------------------------ writing

export class CanvasLimitError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

/** How many writes are left today for this person's canvases, and for one canvas. */
export async function writesLeft(db: Database, userId: string, now = new Date()) {
  const dayAgo = new Date(now.getTime() - 86_400_000).toISOString();
  const [r] = await db.execute<{ n: number }>(sql`
    select coalesce(sum(writes_day), 0)::int as n from public.widget_canvases
    where user_id = ${userId}::uuid and day_from > ${dayAgo}::timestamptz`);
  return Math.max(0, CANVAS_LIMITS.personWritesPerDay - (r?.n ?? 0));
}

/**
 * Saves a canvas (a new name makes a new one). Holds the limits of §12.3. A canvas from a bot the
 * person hasn't allowed waits for Show on my widgets; a paused one stays paused.
 */
export async function saveCanvas(
  db: Database,
  o: {
    orgId: string;
    userId: string;
    botId: string;
    runId: string | null;
    name: string;
    content: CanvasContent;
    allowed: boolean;
    private: boolean;
    until: Date | null;
    now?: Date;
  },
): Promise<CanvasRow> {
  const now = o.now ?? new Date();
  const [existing] = await db.execute<CanvasRow>(sql`${SELECT}
    where c.user_id = ${o.userId}::uuid and c.bot_id = ${o.botId}::uuid and c.name = ${o.name}`);
  const L = CANVAS_LIMITS;
  if (!existing) {
    const [n] = await db.execute<{ bot: number; person: number }>(sql`
      select count(*) filter (where bot_id = ${o.botId}::uuid)::int as bot, count(*)::int as person
      from public.widget_canvases where user_id = ${o.userId}::uuid and org_id = ${o.orgId}::uuid`);
    if ((n?.bot ?? 0) >= L.perBot)
      throw new CanvasLimitError(
        "too_many_canvases",
        `You already keep ${L.perBot} canvases for this person. Replace one by using its name, or clear one with widget.clear.`,
      );
    if ((n?.person ?? 0) >= L.perPerson)
      throw new CanvasLimitError(
        "too_many_canvases",
        `This person already has ${L.perPerson} canvases from their bots. Replace one of yours by its name instead.`,
      );
  }
  if ((await writesLeft(db, o.userId, now)) <= 0)
    throw new CanvasLimitError(
      "write_limit",
      `This person's canvases have had ${L.personWritesPerDay} changes today. Try tomorrow, and plan changes ahead with schedule or rotate.`,
    );
  let hour = 0;
  let day = 0;
  let hourFrom = now;
  let dayFrom = now;
  if (existing) {
    const e = opened(existing);
    if (now.getTime() - e.hour_from.getTime() < 3_600_000) {
      hour = e.writes_hour;
      hourFrom = e.hour_from;
    }
    if (now.getTime() - e.day_from.getTime() < 86_400_000) {
      day = e.writes_day;
      dayFrom = e.day_from;
    }
    if (hour >= L.writesPerHour)
      throw new CanvasLimitError(
        "write_limit",
        `This canvas changed ${L.writesPerHour} times in the last hour. Plan changes ahead with schedule (up to 14 entries) instead of writing each one.`,
      );
    if (day >= L.writesPerDay)
      throw new CanvasLimitError(
        "write_limit",
        `This canvas changed ${L.writesPerDay} times today. Plan changes ahead with schedule or rotate.`,
      );
  }
  const status = o.allowed ? "shown" : "waiting";
  const content = contentKeys.sealJson(o.orgId, o.content);
  const [row] = await db.execute<{ id: string }>(sql`
    insert into public.widget_canvases (org_id, user_id, bot_id, name, content, status,
      hide_when_locked, until, set_at, set_by_run, writes_hour, hour_from, writes_day, day_from)
    values (${o.orgId}::uuid, ${o.userId}::uuid, ${o.botId}::uuid, ${o.name}, ${content}::jsonb,
      ${status}, ${o.private}, ${o.until?.toISOString() ?? null}::timestamptz,
      ${now.toISOString()}::timestamptz, ${o.runId}::uuid, 1, ${now.toISOString()}::timestamptz,
      1, ${now.toISOString()}::timestamptz)
    on conflict (user_id, bot_id, name) do update set
      content = excluded.content,
      version = public.widget_canvases.version + 1,
      status = case
        when public.widget_canvases.status = 'paused' then 'paused'
        else excluded.status end,
      hide_when_locked = public.widget_canvases.hide_when_locked or excluded.hide_when_locked,
      until = excluded.until,
      set_at = excluded.set_at,
      set_by_run = excluded.set_by_run,
      writes_hour = ${hour + 1}, hour_from = ${hourFrom.toISOString()}::timestamptz,
      writes_day = ${day + 1}, day_from = ${dayFrom.toISOString()}::timestamptz
    returning id`);
  const saved = await getCanvas(db, row?.id as string, o.userId);
  if (!saved) throw new Error("canvas not saved");
  return saved;
}

/** Clears one named canvas, or all this bot keeps for this person. */
export async function clearCanvases(
  db: Database,
  o: { userId: string; botId: string; name?: string },
): Promise<string[]> {
  const rows = await db.execute<{ id: string; status: string }>(sql`
    delete from public.widget_canvases
    where user_id = ${o.userId}::uuid and bot_id = ${o.botId}::uuid
      ${o.name ? sql`and name = ${o.name}` : sql``}
    returning id, status`);
  return rows.map((r) => r.id);
}
