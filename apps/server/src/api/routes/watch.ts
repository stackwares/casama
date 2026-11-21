/**
 * Casama on the wrist (D-410, docs/WATCH-PLAN.md §8, docs/WATCH-PROTOCOL.md): watch keys, signing a
 * watch in, and the few routes a watch calls.
 *
 * A watch makes its own key and keeps it; the server stores only its fingerprint. With
 * `Authorization: Watch <key>` a caller may use the routes in WATCH_ROUTES and nothing else
 * (403 watch_key_not_allowed: a 401 tells a watch its key is gone). Each key is held to 60
 * requests a minute. Registering, listing and removing watches and allowing a code needs the
 * person's session; asking for a code is the one route that works signed out.
 */
import { randomBytes, randomUUID } from "node:crypto";
import {
  buildWatchChat,
  buildWatchRun,
  loadWatchApproval,
  track,
  watchPrefsFor,
  watchRunEnded,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { type Database, type JwtClaims, withUserSession } from "@casama/db";
import { casamaModelsAllowed } from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { sql } from "drizzle-orm";
import type { Context } from "hono";
import { streamSSE } from "hono/streaming";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv, WatchCaller } from "../types.ts";
import { clientIp, iso, sha256Hex } from "../util.ts";
import { billingFor } from "./billing.ts";
import type { InProcessEnv } from "./mcp.ts";
import { serverVoice } from "./system.ts";

/** How many requests one watch key may make in a minute (§8.4). */
export const WATCH_KEY_PER_MINUTE = 60;
/** Watch keys that don't work, per address and minute, before 429 (the lookup costs queries). */
export const WATCH_FAILED_KEYS_PER_MINUTE = 30;
/** Run streams one watch key keeps open; a new one closes the oldest. */
export const WATCH_STREAMS_PER_KEY = 3;
/** Watches a person keeps per workspace; the least recently used go past this. */
export const WATCH_KEYS_KEPT = 10;
/** Codes one address may ask for in an hour, and wrong codes one person may type in an hour. */
export const WATCH_CODES_PER_HOUR = 5;
export const WATCH_WRONG_CODES_PER_HOUR = 5;
/** How long a key that worked skips the per-address count of keys that don't, and how many are kept. */
export const WATCH_WORKED_MS = 10 * 60_000;
const WATCH_WORKED_KEPT = 20_000;
/** Eight characters without look-alikes (no 0, O, 1, I, L). */
const CODE_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";
const CODE_LENGTH = 8;
/** How often a watch showing a code asks whether it was allowed. */
const POLL_EVERY_S = 5;
/** A run stream's limits (tests shorten them), and how many snapshots streams have read. */
export const WATCH_STREAM = {
  ms: 110_000,
  beatMs: 15_000,
  minGapMs: 1000,
  recheckMs: 30_000,
  reads: 0,
};

const UUID = "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}";

/** The only requests a watch key may make. */
const WATCH_ROUTES: Array<[string, RegExp]> = [
  ["GET", /^\/v1\/glance\/?$/],
  ["GET", /^\/v1\/config\/?$/],
  ["GET", /^\/v1\/watch\/me\/?$/],
  ["GET", new RegExp(`^/v1/watch/chats/${UUID}/?$`, "i")],
  ["GET", new RegExp(`^/v1/watch/runs/${UUID}/?$`, "i")],
  ["GET", new RegExp(`^/v1/watch/approvals/${UUID}/?$`, "i")],
  ["GET", new RegExp(`^/v1/messages/${UUID}/speech/?$`, "i")],
  ["POST", /^\/v1\/watch\/ask\/?$/],
  ["POST", /^\/v1\/watch\/handoff\/?$/],
  ["POST", new RegExp(`^/v1/approvals/${UUID}/decision/?$`, "i")],
  ["POST", new RegExp(`^/v1/suggestions/${UUID}/(accept|dismiss)/?$`, "i")],
  ["POST", new RegExp(`^/v1/routines/${UUID}/run/?$`, "i")],
  ["POST", new RegExp(`^/v1/runs/${UUID}/cancel/?$`, "i")],
  ["POST", /^\/v1\/voice\/transcribe\/?$/],
  ["PUT", /^\/v1\/watch-keys\/current\/?$/],
  ["DELETE", /^\/v1\/watch-keys\/current\/?$/],
];

/** What a watch did, for watch_action (§15), by route; decisions and asks are counted where made. */
export function watchAction(method: string, path: string): string | null {
  if (method !== "POST" && method !== "GET") return null;
  if (method === "POST" && /^\/v1\/suggestions\/[^/]+\/accept\/?$/.test(path)) return "do_it";
  if (method === "POST" && /^\/v1\/routines\/[^/]+\/run\/?$/.test(path)) return "run";
  if (method === "POST" && /^\/v1\/runs\/[^/]+\/cancel\/?$/.test(path)) return "stop";
  if (method === "GET" && /^\/v1\/messages\/[^/]+\/speech\/?$/.test(path)) return "read_aloud";
  return null;
}

const SURFACES = new Set([
  "app",
  "notification",
  "complication",
  "smart_stack",
  "tile",
  "control",
  "siri",
]);
/** Where on the watch it was done: the body's surface, else the X-Casama-Surface header. */
export const watchSurface = (given: string | undefined | null) =>
  given && SURFACES.has(given) ? given : "app";

export const hashWatchKey = (key: string) => sha256Hex(`casama-watch-key:${key}`);
const hashWatchCode = (code: string) => sha256Hex(`casama-watch-code:${code}`);
/** A code as typed ("kq7m-2xab", "KQ7M 2XAB") in the form it was made. */
export const normalizeWatchCode = (code: string) => code.toUpperCase().replace(/[\s-]/g, "");

export function newWatchCode() {
  const bytes = randomBytes(CODE_LENGTH);
  let out = "";
  for (const b of bytes) out += CODE_ALPHABET[b % CODE_ALPHABET.length];
  return out;
}

/**
 * The address a limit counts by. An IPv6 address counts as its /64: one network hands out as many
 * addresses as it likes, so counting each would be no limit at all.
 */
export function addressKey(ip: string): string {
  const a = ip
    .trim()
    .toLowerCase()
    .replace(/^\[|\]$/g, "")
    .replace(/%.*$/, "");
  if (!a.includes(":")) return a;
  // An IPv4 address written the IPv6 way (::ffff:203.0.113.9) is that IPv4 address.
  const mapped = /^(?:0{0,4}:){0,5}:?ffff:(\d{1,3}(?:\.\d{1,3}){3})$/.exec(a);
  if (mapped) return mapped[1] as string;
  const [head = "", tail] = a.split("::", 2);
  const h = head ? head.split(":") : [];
  const t = tail ? tail.split(":") : [];
  const groups =
    tail === undefined ? h : [...h, ...Array(Math.max(0, 8 - h.length - t.length)).fill("0"), ...t];
  const net = groups.slice(0, 4).map((g) => g.replace(/^0+(?=.)/, "") || "0");
  return `${net.join(":")}::/64`;
}

/** Past this many windows a counter looks for ones that ran out; it never keeps more than the cap. */
const WINDOWS_SWEEP_AT = 10_000;
const WINDOWS_CAP = 200_000;

/** A fixed window per key; returns the seconds to wait when over. */
export function windowCounter(
  ms: number,
  max: number,
  now: () => number,
  o: { sweepAt?: number; cap?: number } = {},
) {
  const sweepAt = o.sweepAt ?? WINDOWS_SWEEP_AT;
  const cap = o.cap ?? WINDOWS_CAP;
  const windows = new Map<string, { start: number; count: number }>();
  let sweepPast = sweepAt;
  return {
    hit(key: string): number | null {
      const t = now();
      let w = windows.get(key);
      if (!w || t - w.start >= ms) {
        w = { start: t, count: 0 };
        // A renewed window moves to the end, so the map stays oldest first.
        windows.delete(key);
        windows.set(key, w);
        if (windows.size > sweepPast) {
          // Windows that ran out go first: a flood of new keys shouldn't reset anyone's limit. The
          // map is bounded all the same, so past the cap the oldest go, and the next look waits
          // until the map has grown by half again (not one scan per new key).
          for (const [k, v] of windows) if (t - v.start >= ms) windows.delete(k);
          for (const k of windows.keys()) {
            if (windows.size <= cap) break;
            windows.delete(k);
          }
          sweepPast = Math.max(sweepAt, Math.floor(windows.size * 1.5));
        }
      }
      if (w.count >= max) return Math.max(1, Math.ceil((w.start + ms - t) / 1000));
      w.count += 1;
      return null;
    },
    /** How many windows are kept (tests). */
    size: () => windows.size,
    /** Gives back one counted hit (it turned out fine). */
    refund(key: string) {
      const w = windows.get(key);
      if (w && w.count > 0) w.count -= 1;
    },
    /** Whether the key is already over, without counting. */
    over(key: string): number | null {
      const t = now();
      const w = windows.get(key);
      if (!w || t - w.start >= ms || w.count < max) return null;
      return Math.max(1, Math.ceil((w.start + ms - t) / 1000));
    },
  };
}

const tooMany = (detail: string, retry: number) =>
  new ApiError(429, "rate_limited", detail, { headers: { "retry-after": String(retry) } });

/**
 * Resolves `Authorization: Watch <key>`: the route must be one a watch may use, the key must exist
 * and its person must still be in its workspace. Marks it used (at most once a minute) and counts
 * it against the minute.
 */
export function watchCaller(deps: Pick<AppDeps, "db">, o: { now?: () => number } = {}) {
  const now = o.now ?? Date.now;
  const limit = windowCounter(60_000, WATCH_KEY_PER_MINUTE, now);
  // Keys that don't work, per address: counted before the lookup, given back when the key works.
  const failed = windowCounter(60_000, WATCH_FAILED_KEYS_PER_MINUTE, now);
  // Keys that worked a moment ago, by fingerprint, and until when. They skip the per-address
  // count: junk keys sent from the same address (shared Wi-Fi, a carrier's network) must not lock
  // out the watches there that are signed in.
  const worked = new Map<string, number>();
  return async (
    method: string,
    path: string,
    key: string,
    ip = "unknown",
  ): Promise<WatchCaller> => {
    const m = method === "HEAD" ? "GET" : method;
    if (!WATCH_ROUTES.some(([wm, re]) => wm === m && re.test(path)))
      throw new ApiError(403, "watch_key_not_allowed", "A watch can't do this; use the phone");
    const from = addressKey(ip);
    const wellFormed = /^cwt_[A-Za-z0-9_-]{43}$/.test(key);
    const hash = wellFormed ? hashWatchKey(key) : "";
    const t = now();
    const known = wellFormed && (worked.get(hash) ?? 0) > t;
    if (!known) {
      const wait = failed.hit(from);
      if (wait !== null) throw tooMany("Too many watch keys that don't work from here", wait);
    }
    if (!wellFormed) throw new ApiError(401, "invalid_watch_key", "The watch key is invalid");
    const [row] = await deps.db.execute<{
      id: string;
      user_id: string;
      org_id: string;
      platform: "watchos" | "wearos";
      allow: string | null;
      show_details: boolean | null;
    }>(sql`
      with k as (
        select k.id, k.user_id, k.org_id, k.platform, k.last_used_at
        from public.watch_keys k
        join public.memberships m on m.user_id = k.user_id and m.org_id = k.org_id
        where k.key_hash = ${hash}
      ), touched as (
        update public.watch_keys w set last_used_at = now()
        from k where w.id = k.id
          and (k.last_used_at is null or k.last_used_at < now() - interval '1 minute')
        returning w.id
      )
      select k.id, k.user_id, k.org_id, k.platform, p.allow, p.show_details
      from k left join public.watch_prefs p on p.user_id = k.user_id`);
    if (!row) {
      // A key that worked until now was removed: from here on it counts like any other.
      if (known) {
        worked.delete(hash);
        failed.hit(from);
      }
      // A watch showing a code asks until the code is allowed: tell it it's still waiting.
      const [pending] = await deps.db.execute<{ id: string }>(sql`
        select id from public.watch_key_requests
        where key_hash = ${hash} and claimed_at is null and expires_at > now() limit 1`);
      if (pending) {
        // Waiting on a code isn't a key that doesn't work: a few watches signing in at one address
        // (each asks every five seconds) must not use up its budget. Each is held to its own minute.
        failed.refund(from);
        const slow = limit.hit(`code:${hash}`);
        if (slow !== null) throw tooMany("This watch asked too often; wait a moment", slow);
        throw new ApiError(401, "watch_code_pending", "The code on the watch isn't allowed yet");
      }
      throw new ApiError(401, "invalid_watch_key", "The watch key is invalid");
    }
    if (!known) failed.refund(from);
    worked.delete(hash);
    worked.set(hash, t + WATCH_WORKED_MS);
    for (const k of worked.keys()) {
      if (worked.size <= WATCH_WORKED_KEPT) break;
      worked.delete(k);
    }
    const retry = limit.hit(row.id);
    if (retry !== null) throw tooMany("This watch made too many requests this minute", retry);
    return {
      id: row.id,
      userId: row.user_id,
      orgId: row.org_id,
      platform: row.platform,
      allow: row.allow === "low" || row.allow === "none" ? row.allow : "medium",
      showDetails: row.show_details ?? true,
    };
  };
}

/** Claims for a watch key's person, so row-level security reads as them. */
export const watchClaims = (w: WatchCaller): JwtClaims => ({
  sub: w.userId,
  role: "authenticated",
  aud: "authenticated",
  watch_key: w.id,
});

/**
 * The workspace a borrowed route's target lives in, by path (D-410): a watch key's claims carry only
 * its person, so row-level security would open every workspace they're in. Null: not a borrowed
 * route with a target (the watch's own routes check their workspace themselves).
 */
const BORROWED_TARGETS: Array<[string, RegExp, (id: string) => ReturnType<typeof sql>]> = [
  [
    "POST",
    new RegExp(`^/v1/routines/(${UUID})/run/?$`, "i"),
    (id) => sql`select org_id from public.routines where id = ${id}::uuid`,
  ],
  [
    "POST",
    new RegExp(`^/v1/runs/(${UUID})/cancel/?$`, "i"),
    (id) => sql`select org_id from public.runs where id = ${id}::uuid`,
  ],
  [
    "POST",
    new RegExp(`^/v1/suggestions/(${UUID})/(?:accept|dismiss)/?$`, "i"),
    (id) => sql`select org_id from public.suggestions where id = ${id}::uuid`,
  ],
  [
    "POST",
    new RegExp(`^/v1/approvals/(${UUID})/decision/?$`, "i"),
    (id) => sql`select org_id from public.approvals where id = ${id}::uuid`,
  ],
  [
    "GET",
    new RegExp(`^/v1/messages/(${UUID})/speech/?$`, "i"),
    (id) => sql`select org_id from public.messages where id = ${id}::uuid`,
  ],
];

/**
 * Keeps a watch key in its own workspace on the routes it borrows from the phone: the target
 * (routine, run, suggestion, request, message, or the bot a recording is for) must be in the key's
 * workspace, else 404 as if it weren't there. A reply read aloud also needs details shown and reply
 * text not hidden. Runs before the route's own handler.
 */
export function watchScope(db: Database) {
  return async (watch: WatchCaller, method: string, path: string, query: URLSearchParams) => {
    const m = method === "HEAD" ? "GET" : method;
    let target: ReturnType<typeof sql> | null = null;
    for (const [wm, re, q] of BORROWED_TARGETS) {
      const hit = wm === m && re.exec(path);
      if (hit) {
        target = q(hit[1] as string);
        break;
      }
    }
    if (!target && m === "POST" && /^\/v1\/voice\/transcribe\/?$/.test(path)) {
      const botId = query.get("bot_id") ?? "";
      if (!new RegExp(`^${UUID}$`, "i").test(botId))
        throw new ApiError(404, "bot_not_found", "Bot not found");
      target = sql`select org_id from public.bots where id = ${botId}::uuid`;
    }
    if (!target) return;
    const [row] = await db.execute<{ org_id: string }>(target);
    if (!row || row.org_id !== watch.orgId)
      throw new ApiError(404, "not_found", "Not found in this watch's workspace");
    if (m === "GET" && /\/speech\/?$/.test(path)) {
      const [p] = await db.execute<{ hide: boolean | null }>(sql`
        select (push_prefs ->> 'hide_reply_text')::boolean as hide
        from public.profiles where user_id = ${watch.userId}::uuid`);
      if (!watch.showDetails || p?.hide === true)
        throw new ApiError(
          403,
          "watch_details_hidden",
          "Replies aren't shown on this watch, so they aren't read aloud",
        );
    }
  };
}

type Ctx = Context<AppEnv>;

/** The person's own session: not a widget's or a watch's key. */
const requireSession = (c: Ctx) => {
  const claims = c.get("claims");
  if (!claims || c.get("widgetKey") || c.get("watchKey"))
    throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
};

/** A watch key's caller. */
const requireWatch = (c: Ctx) => {
  const watch = c.get("watchKey");
  const claims = c.get("claims");
  if (!watch || !claims)
    throw new ApiError(401, "invalid_watch_key", "Sign in on the watch with a watch key");
  return { watch, claims };
};

type KeyRow = {
  id: string;
  org_id: string;
  platform: "watchos" | "wearos";
  name: string;
  model: string | null;
  app_version: string | null;
  os_version: string | null;
  paired_by: "phone" | "code";
  push_kind: string | null;
  last_used_at: string | Date | null;
  created_at: string | Date;
  /** From saveKey: the row is new, not one registered again or moved to another workspace. */
  inserted?: boolean;
};
const KEY_COLUMNS = sql`id, org_id, platform, name, model, app_version, os_version, paired_by,
  push_kind, last_used_at, created_at`;
const keyOut = (k: KeyRow) => ({
  id: k.id,
  org_id: k.org_id,
  platform: k.platform,
  name: k.name,
  model: k.model,
  app_version: k.app_version,
  os_version: k.os_version,
  paired_by: k.paired_by,
  has_push: !!k.push_kind,
  last_used_at: k.last_used_at ? iso(k.last_used_at) : null,
  created_at: iso(k.created_at),
});

/**
 * A watch's decision the server refuses (§6.1 B, §10): always-allow never comes from a watch, and
 * an allow needs the request to be one this watch may allow. Deny always works. Null: go on.
 */
export async function refuseWatchDecision(
  db: Database,
  watch: WatchCaller,
  id: string,
  decision: "approved" | "denied",
  alwaysAllow: boolean | undefined,
) {
  if (alwaysAllow && decision === "approved")
    throw new ApiError(403, "watch_always_allow", "Always allow can only be set on the phone");
  const approval = await loadWatchApproval(db, id, {
    userId: watch.userId,
    orgId: watch.orgId,
    private: true,
    level: watch.allow,
  });
  if (!approval) throw new ApiError(404, "approval_not_found", "Approval not found");
  if (decision === "approved" && approval.can_allow === "phone")
    throw new ApiError(403, "watch_allow_refused", approval.why_phone ?? "setting");
  return approval;
}

export function registerWatchRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const billing = billingFor(deps);
  const now = Date.now;
  const codesByAddress = windowCounter(3_600_000, WATCH_CODES_PER_HOUR, now);
  const wrongCodes = windowCounter(3_600_000, WATCH_WRONG_CODES_PER_HOUR, now);

  const isMember = async (claims: JwtClaims, orgId: string) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${orgId}::uuid) as ok`),
    );
    return r?.ok === true;
  };

  /** Keep the person's most recently used watches in a workspace, and always the one just made. */
  const trimKeys = (userId: string, orgId: string, keep: string) =>
    db.execute(sql`
      delete from public.watch_keys where id in (
        select id from public.watch_keys
        where user_id = ${userId}::uuid and org_id = ${orgId}::uuid and id <> ${keep}::uuid
        order by coalesce(last_used_at, created_at) desc offset ${WATCH_KEYS_KEPT - 1})`);

  /**
   * Tells the person's own phones a watch was signed in as them, so one signed in by mistake (a code
   * someone else read out) is noticed. Never holds up the answer.
   */
  const signedInNotice = (userId: string, name: string) => {
    const task = (
      deps.notifications?.handoff(userId, {
        title: `${name.slice(0, 60)} is signed in to Casama`,
        body: "Not you? Remove it in Settings → Watch.",
        link: "/settings/watch",
        tag: "watch-signed-in",
      }) ?? Promise.resolve(0)
    ).catch(() => 0);
    deps.onBackgroundTask?.(task);
  };

  /**
   * Saves a watch key for a person; a fingerprint already someone else's is refused. Registering
   * one again (the phone moved to another workspace, a reinstall) updates it and keeps how it was
   * first signed in; `inserted` says which happened.
   */
  const saveKey = async (
    userId: string,
    orgId: string,
    hash: string,
    d: {
      platform: string;
      name: string;
      model?: string | null;
      app_version?: string | null;
      os_version?: string | null;
    },
    pairedBy: "phone" | "code",
  ) => {
    const [row] = await db.execute<KeyRow>(sql`
      insert into public.watch_keys
        (user_id, org_id, platform, key_hash, name, model, app_version, os_version, paired_by)
      values (${userId}::uuid, ${orgId}::uuid, ${d.platform}, ${hash}, ${d.name.trim()},
              ${d.model?.trim() || null}, ${d.app_version?.trim() || null},
              ${d.os_version?.trim() || null}, ${pairedBy})
      on conflict (key_hash) do update set
        org_id = excluded.org_id, platform = excluded.platform, name = excluded.name,
        model = excluded.model, app_version = excluded.app_version,
        os_version = excluded.os_version
      where public.watch_keys.user_id = excluded.user_id
      returning ${KEY_COLUMNS}, (xmax = 0) as inserted`);
    if (!row) throw new ApiError(409, "watch_key_taken", "This watch is signed in as someone else");
    await trimKeys(userId, orgId, row.id);
    return row;
  };

  // Before DELETE /v1/watch-keys/{id}, which would take "current" for an id.
  app.openapi(routes.signOutWatch, async (c) => {
    const { watch } = requireWatch(c);
    await db.execute(sql`delete from public.watch_keys where id = ${watch.id}::uuid`);
    return c.json({ ok: true as const }, 200);
  });

  // --- the phone ----------------------------------------------------------------------------

  app.openapi(routes.listWatchKeys, async (c) => {
    const claims = requireSession(c);
    const { org_id } = c.req.valid("query");
    if (!(await isMember(claims, org_id)))
      throw new ApiError(404, "org_not_found", "Workspace not found");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<KeyRow>(sql`
        select ${KEY_COLUMNS} from public.watch_keys
        where user_id = ${claims.sub}::uuid and org_id = ${org_id}::uuid
        order by coalesce(last_used_at, created_at) desc`),
    );
    return c.json({ items: rows.map(keyOut) }, 200);
  });

  app.openapi(routes.registerWatchKey, async (c) => {
    const claims = requireSession(c);
    const body = c.req.valid("json");
    if (!(await isMember(claims, body.org_id)))
      throw new ApiError(404, "org_not_found", "Workspace not found");
    const row = await saveKey(claims.sub, body.org_id, body.fingerprint, body, "phone");
    // A new watch only: the phone registers its watches again on every workspace switch.
    if (row.inserted) {
      signedInNotice(claims.sub, row.name);
      track(db, {
        event: "watch_paired",
        userId: claims.sub,
        orgId: body.org_id,
        properties: { method: "phone", platform: body.platform },
      });
    }
    return c.json(keyOut(row), 201);
  });

  // "Sign Out Everywhere" on the phone: every watch the person signed in, in every workspace.
  app.openapi(routes.deleteAllWatchKeys, async (c) => {
    const claims = requireSession(c);
    const rows = await db.execute<{ id: string }>(sql`
      delete from public.watch_keys where user_id = ${claims.sub}::uuid returning id`);
    return c.json({ deleted: rows.length }, 200);
  });

  app.openapi(routes.deleteWatchKey, async (c) => {
    const claims = requireSession(c);
    const { id } = c.req.valid("param");
    const [row] = await db.execute<{ id: string }>(sql`
      delete from public.watch_keys where id = ${id}::uuid and user_id = ${claims.sub}::uuid
      returning id`);
    if (!row) throw new ApiError(404, "watch_key_not_found", "Watch not found");
    return c.json({ deleted: row.id }, 200);
  });

  app.openapi(routes.getWatchPrefs, async (c) => {
    const claims = requireSession(c);
    return c.json(await watchPrefsFor(db, claims.sub), 200);
  });

  app.openapi(routes.updateWatchPrefs, async (c) => {
    const claims = requireSession(c);
    const body = c.req.valid("json");
    const replies =
      body.quick_replies === undefined
        ? undefined
        : body.quick_replies === null
          ? null
          : body.quick_replies.map((r) => r.trim()).filter(Boolean);
    const clearReplies = replies === null || (Array.isArray(replies) && replies.length === 0);
    const repliesJson = Array.isArray(replies) && replies.length ? JSON.stringify(replies) : null;
    await db.execute(sql`
      insert into public.watch_prefs (user_id, allow, show_details, quick_replies)
      values (${claims.sub}::uuid, coalesce(${body.allow ?? null}, 'medium'),
              coalesce(${body.show_details ?? null}::boolean, true),
              (select array_agg(v) from jsonb_array_elements_text(${repliesJson}::jsonb) v))
      on conflict (user_id) do update set
        allow = coalesce(${body.allow ?? null}, public.watch_prefs.allow),
        show_details = coalesce(${body.show_details ?? null}::boolean, public.watch_prefs.show_details),
        quick_replies = case
          when ${clearReplies} then null
          when ${repliesJson}::jsonb is not null then excluded.quick_replies
          else public.watch_prefs.quick_replies end,
        updated_at = now()`);
    // The glance (complications, tiles) reads show_details; tell it now.
    deps.glance?.changed(claims.sub, { urgent: true });
    return c.json(await watchPrefsFor(db, claims.sub), 200);
  });

  /**
   * A code still waiting to be allowed, counting wrong ones against the person. Looking a code up
   * doesn't use it up: it stops working when it is allowed, replaced or ten minutes old, and until
   * then its watch is told it is still waiting.
   */
  const openCode = async (claims: JwtClaims, raw: string) => {
    // Counted before the lookup (given back when the code is right), so guesses sent all at once
    // can't slip past the limit.
    const over = wrongCodes.hit(claims.sub);
    if (over !== null) throw tooMany("Too many wrong codes; try again later", over);
    const code = normalizeWatchCode(raw);
    const [row] = /^[0-9A-Z]{8}$/.test(code)
      ? await db.execute<{
          id: string;
          key_hash: string;
          platform: "watchos" | "wearos";
          name: string;
          model: string | null;
          app_version: string | null;
          os_version: string | null;
          expires_at: string | Date;
        }>(sql`
          select id, key_hash, platform, name, model, app_version, os_version, expires_at
          from public.watch_key_requests
          where code_hash = ${hashWatchCode(code)} and claimed_at is null and expires_at > now()`)
      : [];
    if (!row) throw new ApiError(404, "watch_code_not_found", "That code isn't on any watch now");
    wrongCodes.refund(claims.sub);
    return row;
  };

  app.openapi(routes.getWatchCode, async (c) => {
    const claims = requireSession(c);
    const row = await openCode(claims, c.req.valid("param").code);
    return c.json(
      {
        platform: row.platform,
        name: row.name,
        model: row.model,
        expires_at: iso(row.expires_at),
      },
      200,
    );
  });

  app.openapi(routes.claimWatchCode, async (c) => {
    const claims = requireSession(c);
    const { org_id } = c.req.valid("json");
    if (!(await isMember(claims, org_id)))
      throw new ApiError(404, "org_not_found", "Workspace not found");
    const req = await openCode(claims, c.req.valid("param").code);
    const [claimed] = await db.execute<{ id: string }>(sql`
      update public.watch_key_requests
      set claimed_by = ${claims.sub}::uuid, claimed_org = ${org_id}::uuid, claimed_at = now()
      where id = ${req.id}::uuid and claimed_at is null returning id`);
    if (!claimed)
      throw new ApiError(404, "watch_code_not_found", "That code isn't on any watch now");
    const row = await saveKey(claims.sub, org_id, req.key_hash, req, "code");
    if (row.inserted) {
      signedInNotice(claims.sub, row.name);
      track(db, {
        event: "watch_paired",
        userId: claims.sub,
        orgId: org_id,
        properties: { method: "code", platform: req.platform },
      });
    }
    return c.json(keyOut(row), 201);
  });

  // --- signed out ---------------------------------------------------------------------------

  app.openapi(routes.requestWatchCode, async (c) => {
    const body = c.req.valid("json");
    const ip = addressKey(clientIp((n) => c.req.header(n), deps.env.TRUSTED_CLIENT_IP_HEADER));
    const retry = codesByAddress.hit(ip);
    if (retry !== null) throw tooMany("Too many codes from here; try again later", retry);
    // A watch asking again gets a new code; the old one stops working.
    await db.execute(sql`
      delete from public.watch_key_requests
      where key_hash = ${body.fingerprint} and claimed_at is null`);
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = newWatchCode();
      const [row] = await db.execute<{ expires_at: string | Date }>(sql`
        insert into public.watch_key_requests
          (code_hash, key_hash, platform, name, model, app_version, os_version)
        values (${hashWatchCode(code)}, ${body.fingerprint}, ${body.platform}, ${body.name.trim()},
                ${body.model?.trim() || null}, ${body.app_version?.trim() || null},
                ${body.os_version?.trim() || null})
        on conflict (code_hash) do nothing
        returning expires_at`);
      if (row)
        return c.json({ code, expires_at: iso(row.expires_at), poll_every_s: POLL_EVERY_S }, 201);
    }
    throw new ApiError(503, "try_again", "Couldn't make a code; try again");
  });

  // --- the watch ----------------------------------------------------------------------------

  /** Voice features for a workspace: the server's own keys, or the workspace's OpenRouter key. */
  const voiceFor = async (orgId: string) => {
    let allowPlatform = true;
    if (billing.enabled) {
      const [ent] = await db.execute<{ plan_code: string | null }>(sql`
        select plan_code from public.entitlements
        where org_id = ${orgId}::uuid order by created_at desc limit 1`);
      allowPlatform = casamaModelsAllowed(ent?.plan_code ?? "free", true);
    }
    const own = allowPlatform ? serverVoice(deps.env) : [];
    if (own.includes("dictation") && own.includes("read_aloud"))
      return { dictation: true, speech: true };
    const [k] = await db.execute<{ ok: boolean }>(sql`
      select exists (select 1 from public.model_credentials
        where org_id = ${orgId}::uuid and provider = 'openrouter') as ok`);
    return {
      dictation: own.includes("dictation") || k?.ok === true,
      speech: own.includes("read_aloud") || k?.ok === true,
    };
  };

  const hideReplyText = async (userId: string) => {
    const [p] = await db.execute<{ hide: boolean | null }>(sql`
      select (push_prefs ->> 'hide_reply_text')::boolean as hide
      from public.profiles where user_id = ${userId}::uuid`);
    return p?.hide === true;
  };

  const outOfCredits = async (orgId: string) => {
    if (!billing.enabled) return false;
    try {
      const s = await billing.summary(orgId);
      return !s.unlimited && s.credits_usd <= 0;
    } catch {
      return false;
    }
  };

  app.openapi(routes.getWatchSelf, async (c) => {
    const { watch } = requireWatch(c);
    const [info] = await db.execute<{ org_name: string; person: string | null }>(sql`
      select o.name as org_name,
             coalesce(nullif(trim(p.preferred_name), ''), nullif(trim(p.display_name), ''),
                      split_part(u.email, '@', 1)) as person
      from public.organizations o
      left join public.profiles p on p.user_id = ${watch.userId}::uuid
      left join auth.users u on u.id = ${watch.userId}::uuid
      where o.id = ${watch.orgId}::uuid`);
    // Ask goes to the first bot in the person's order that they can use.
    const [bot] = await withUserSession(db, watchClaims(watch), (tx) =>
      tx.execute<{ id: string }>(sql`
        select b.id from public.bots b
        where b.org_id = ${watch.orgId}::uuid and b.archived_at is null
          and public.can_access_bot(b.id)
        order by b.sort_key, b.created_at limit 1`),
    );
    const [prefs, hide, voice, broke] = await Promise.all([
      watchPrefsFor(db, watch.userId),
      hideReplyText(watch.userId),
      voiceFor(watch.orgId),
      outOfCredits(watch.orgId),
    ]);
    return c.json(
      {
        key_id: watch.id,
        org_id: watch.orgId,
        org_name: (info?.org_name ?? "").slice(0, 80),
        person: { name: (info?.person ?? "").slice(0, 80) },
        prefs,
        hide_reply_text: hide,
        ask_bot_id: bot?.id ?? null,
        features: { ...voice, out_of_credits: broke },
      },
      200,
    );
  });

  app.openapi(routes.updateWatchSelf, async (c) => {
    const { watch } = requireWatch(c);
    const body = c.req.valid("json");
    if (body.push_token) {
      const kind = body.push_kind ?? (watch.platform === "watchos" ? "apns" : "fcm");
      // Apple's tokens on Apple Watches, Firebase tokens on Wear OS.
      if ((watch.platform === "watchos") !== (kind === "apns"))
        throw new ApiError(400, "wrong_token_kind", "That kind of token doesn't fit this watch");
      if (kind === "apns" && !/^[0-9a-f]{16,200}$/i.test(body.push_token))
        throw new ApiError(400, "bad_token", "Apple's push token is hex");
      // A token belongs to one watch: a reinstall's new key takes it over from the old one.
      await db.execute(sql`
        update public.watch_keys set push_token = null, push_kind = null, push_sandbox = null
        where push_token = ${body.push_token} and id <> ${watch.id}::uuid`);
      await db.execute(sql`
        update public.watch_keys
        set push_token = ${body.push_token}, push_kind = ${kind},
            push_sandbox = ${kind === "apns" ? body.sandbox === true : null}
        where id = ${watch.id}::uuid`);
    } else if (body.push_token === null) {
      await db.execute(sql`
        update public.watch_keys set push_token = null, push_kind = null, push_sandbox = null
        where id = ${watch.id}::uuid`);
    }
    if (body.app_version !== undefined || body.os_version !== undefined || body.name !== undefined)
      await db.execute(sql`
        update public.watch_keys set
          app_version = coalesce(${body.app_version?.trim() || null}, app_version),
          os_version = coalesce(${body.os_version?.trim() || null}, os_version),
          name = coalesce(${body.name?.trim() || null}, name)
        where id = ${watch.id}::uuid`);
    return c.json({ ok: true as const }, 200);
  });

  app.openapi(routes.getWatchChat, async (c) => {
    const { watch } = requireWatch(c);
    const { bot_id } = c.req.valid("param");
    const { conversation_id } = c.req.valid("query");
    const [hide, voice] = await Promise.all([hideReplyText(watch.userId), voiceFor(watch.orgId)]);
    const chat = await buildWatchChat(db, {
      userId: watch.userId,
      botId: bot_id,
      conversationId: conversation_id ?? null,
      orgId: watch.orgId,
      private: !watch.showDetails,
      hideReplyText: hide,
      speech: voice.speech,
    });
    if (!chat) throw new ApiError(404, "chat_not_found", "Chat not found");
    return c.json(chat, 200);
  });

  /** Calls another route in-process as the watch's person (that route's own checks apply). */
  const inner = async (
    claims: JwtClaims,
    path: string,
    body: unknown,
    idempotencyKey: string | undefined,
  ) => {
    const res = await app.request(
      path,
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
          ...(idempotencyKey ? { "idempotency-key": idempotencyKey } : {}),
        },
        body: JSON.stringify(body),
      },
      { casamaClaims: claims } satisfies InProcessEnv,
    );
    const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
    if (res.status >= 300) {
      const status = [400, 402, 403, 404, 409, 429].includes(res.status) ? res.status : 500;
      throw new ApiError(
        status as 400,
        String(json.code ?? "ask_failed"),
        String(json.detail ?? json.title ?? "Couldn't send that"),
      );
    }
    return json;
  };

  /** A UUID made from the watch's idempotency key, so a retried ask makes the same chat and message. */
  const derivedKey = (key: string | undefined, part: string) => {
    if (!key) return undefined;
    const h = sha256Hex(`watch-ask:${part}:${key}`);
    return `${h.slice(0, 8)}-${h.slice(8, 12)}-4${h.slice(13, 16)}-${((Number.parseInt(h[16] ?? "0", 16) & 3) | 8).toString(16)}${h.slice(17, 20)}-${h.slice(20, 32)}`;
  };

  app.openapi(routes.watchAsk, async (c) => {
    const { watch, claims } = requireWatch(c);
    const body = c.req.valid("json");
    const idem = c.req.header("idempotency-key") ?? undefined;
    if (!body.text?.trim() && !body.audio)
      throw new ApiError(400, "nothing_to_send", "Say or type something to send");
    const [bot] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ id: string; org_id: string }>(sql`
        select id, org_id from public.bots
        where id = ${body.bot_id}::uuid and archived_at is null and public.can_access_bot(id)`),
    );
    if (!bot || bot.org_id !== watch.orgId)
      throw new ApiError(404, "bot_not_found", "Bot not found");
    // A reply goes on in that bot's chat, in this watch's workspace (checked before any paid
    // transcription).
    if (body.conversation_id) {
      const [conv] = await withUserSession(db, claims, (tx) =>
        tx.execute<{ id: string }>(sql`
          select c.id from public.conversations c
          where c.id = ${body.conversation_id}::uuid and c.org_id = ${watch.orgId}::uuid
            and (c.bot_id = ${bot.id}::uuid or exists (
              select 1 from public.conversation_bots cb
              where cb.conversation_id = c.id and cb.bot_id = ${bot.id}::uuid))`),
      );
      if (!conv) throw new ApiError(404, "conversation_not_found", "Conversation not found");
    }
    let text = body.text?.trim() ?? "";
    if (!text && body.audio) {
      const bytes = Math.floor((body.audio.data.length * 3) / 4);
      if (bytes < 16 || bytes > 1_100_000)
        throw new ApiError(400, "bad_audio", "Recordings must be under about a minute");
      const r = await deps.workflows.voiceTranscribe(
        watch.orgId,
        bot.id,
        body.audio.data,
        body.audio.mime,
        body.language,
      );
      if (!r.ok) throw new ApiError(409, r.code ?? "voice_unavailable", r.error);
      text = r.text.trim();
      if (!text) throw new ApiError(400, "nothing_heard", "Nothing was heard in the recording");
    }
    let conversationId = body.conversation_id;
    if (!conversationId) {
      const conv = await inner(
        claims,
        "/v1/conversations",
        { bot_id: bot.id },
        derivedKey(idem, "chat"),
      );
      conversationId = String(conv.id);
    }
    const sent = await inner(
      claims,
      `/v1/conversations/${conversationId}/messages`,
      { text: text.slice(0, 4000) },
      derivedKey(idem, "message") ?? randomUUID(),
    );
    track(db, {
      event: "watch_action",
      userId: watch.userId,
      orgId: watch.orgId,
      properties: {
        action: body.conversation_id ? "reply" : "ask",
        surface: watchSurface(body.surface ?? c.req.header("x-casama-surface")),
        platform: watch.platform,
      },
    });
    return c.json(
      {
        conversation_id: String(sent.conversation_id ?? conversationId),
        message_id: String(sent.message_id),
        run_id: sent.run_id ? String(sent.run_id) : null,
        heard: text.slice(0, 4000),
      },
      201,
    );
  });

  /** Open run streams per watch key. */
  const streams = new Map<string, Array<{ close: () => void }>>();
  /** What a key's person lets it show and allow now, or null once the key no longer works. */
  const keyNow = async (watch: WatchCaller) => {
    const [k] = await db.execute<{
      allow: string | null;
      show_details: boolean | null;
      hide: boolean | null;
    }>(sql`
      select p.allow, p.show_details, (pr.push_prefs ->> 'hide_reply_text')::boolean as hide
      from public.watch_keys k
      join public.memberships m on m.user_id = k.user_id and m.org_id = k.org_id
      left join public.watch_prefs p on p.user_id = k.user_id
      left join public.profiles pr on pr.user_id = k.user_id
      where k.id = ${watch.id}::uuid`);
    if (!k) return null;
    return {
      private: k.show_details === false,
      level: (k.allow === "low" || k.allow === "none" ? k.allow : "medium") as WatchCaller["allow"],
      hide: k.hide === true,
    };
  };

  app.openapi(routes.getWatchRun, async (c) => {
    const { watch } = requireWatch(c);
    const { id } = c.req.valid("param");
    const { stream } = c.req.valid("query");
    const [hide, voice] = await Promise.all([hideReplyText(watch.userId), voiceFor(watch.orgId)]);
    // What the stream shows follows the person's settings while it is open (rechecked below).
    let view = { private: !watch.showDetails, level: watch.allow, hide };
    const read = () =>
      buildWatchRun(db, id, {
        userId: watch.userId,
        orgId: watch.orgId,
        private: view.private,
        level: view.level,
        hideReplyText: view.hide,
        speech: voice.speech,
      });
    const first = await read();
    if (!first) throw new ApiError(404, "run_not_found", "Run not found");
    const wantsStream =
      stream === "1" || (c.req.header("accept") ?? "").includes("text/event-stream");
    if (!wantsStream) return c.json(first, 200);
    return streamSSE(c, async (s) => {
      const startedAt = Date.now();
      let last = JSON.stringify(first);
      let lastRead = Date.now();
      let lastCheck = Date.now();
      let done = watchRunEnded(first);
      let wake: (() => void) | undefined;
      // A few streams per watch: a new one closes the oldest.
      const mine = {
        close: () => {
          done = true;
          wake?.();
        },
      };
      const open = streams.get(watch.id) ?? [];
      open.push(mine);
      streams.set(watch.id, open);
      while (open.length > WATCH_STREAMS_PER_KEY) open.shift()?.close();
      await s.writeSSE({ event: "run", data: last });
      const unsubscribe = deps.hub.subscribe(id, () => {
        wake?.();
      });
      s.onAbort(() => {
        done = true;
        wake?.();
      });
      try {
        while (!done) {
          const left = WATCH_STREAM.ms - (Date.now() - startedAt);
          if (left <= 0) break;
          let beat = false;
          await new Promise<void>((resolve) => {
            const t = setTimeout(
              () => {
                beat = true;
                resolve();
              },
              Math.min(WATCH_STREAM.beatMs, left),
            );
            wake = () => {
              clearTimeout(t);
              resolve();
            };
          });
          wake = undefined;
          if (done) break;
          // At most one snapshot a second, counted from the last one read: a watch's radio is the
          // cost, and a reply being written (several events a second that change nothing a watch
          // shows) mustn't read the run each time.
          const gap = WATCH_STREAM.minGapMs - (Date.now() - lastRead);
          if (gap > 0 && !beat) await new Promise((r) => setTimeout(r, gap));
          if (done) break;
          // A removed or signed-out watch's stream ends, and one whose person changed what watches
          // show or allow follows that (both checked every 30 seconds).
          if (Date.now() - lastCheck >= WATCH_STREAM.recheckMs) {
            lastCheck = Date.now();
            const fresh = await keyNow(watch);
            if (!fresh) break;
            view = fresh;
          }
          const now = await read();
          lastRead = Date.now();
          WATCH_STREAM.reads += 1;
          if (!now) break;
          const json = JSON.stringify(now);
          if (json !== last) {
            await s.writeSSE({ event: "run", data: json });
            last = json;
          } else if (beat) {
            await s.write(": ping\n\n");
          }
          if (watchRunEnded(now)) done = true;
        }
      } finally {
        unsubscribe();
        const left = (streams.get(watch.id) ?? []).filter((x) => x !== mine);
        if (left.length) streams.set(watch.id, left);
        else streams.delete(watch.id);
      }
    }) as never;
  });

  app.openapi(routes.getWatchApproval, async (c) => {
    const { watch } = requireWatch(c);
    const { id } = c.req.valid("param");
    const approval = await loadWatchApproval(db, id, {
      userId: watch.userId,
      orgId: watch.orgId,
      private: !watch.showDetails,
      level: watch.allow,
    });
    if (!approval) throw new ApiError(404, "approval_not_found", "Approval not found");
    const { org_id: _org, ...out } = approval;
    return c.json(out, 200);
  });

  app.openapi(routes.watchHandoff, async (c) => {
    const { watch } = requireWatch(c);
    const body = c.req.valid("json");
    const sent = (await deps.notifications?.handoff(watch.userId, body)) ?? 0;
    return c.json({ sent }, 200);
  });
}
