/**
 * Live view and take control (Phase 5): stream sessions, the signaling proxy, control leases
 * and takeover requests. Signaling goes client <-> API <-> supervisor <-> the computer's Neko
 * streamer; media goes through the TURN relay only (D-054, D-055).
 */
import { createHmac, timingSafeEqual } from "node:crypto";
import type { IncomingMessage, Server } from "node:http";
import type { Duplex } from "node:stream";
import { routes } from "@casama/contracts";
import { type Database, type JwtClaims, schema, withUserSession } from "@casama/db";
import { captureError } from "@casama/observability";
import { turnCredentials, turnIceServer } from "@casama/sandbox";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { eq, sql } from "drizzle-orm";
import { WebSocket, WebSocketServer } from "ws";
import { ApiError } from "../errors.ts";
import { isPresence, throttledTouch } from "../keep-awake.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const { computers } = schema;
export const LEASE_MS = 15 * 60 * 1000;
const SESSION_MS = 5 * 60 * 1000;

export interface LiveConfig {
  /** coturn `static-auth-secret`. */
  turnSecret: string;
  /** TURN host and ports as clients reach them. */
  turnHost: string;
  turnPort: number;
  turnTlsPort?: number;
  /** Signs stream-session tokens. */
  tokenSecret: string;
}

interface StreamClaims {
  sub: string;
  cid: string;
  mode: "view" | "control";
  exp: number;
}

export function liveConfigFromEnv(env: import("../../env.ts").Env): LiveConfig | undefined {
  if (!env.TURN_SECRET || !env.SUPERVISOR_TOKEN) return undefined;
  return {
    turnSecret: env.TURN_SECRET,
    turnHost: env.TURN_PUBLIC_HOST,
    turnPort: env.TURN_PORT,
    turnTlsPort: env.TURN_TLS_PORT,
    tokenSecret: createHmac("sha256", env.SUPERVISOR_TOKEN).update("stream-tokens").digest("hex"),
  };
}

export function signStreamToken(secret: string, claims: StreamClaims) {
  const body = Buffer.from(JSON.stringify(claims)).toString("base64url");
  const sig = createHmac("sha256", secret).update(body).digest("base64url");
  return `${body}.${sig}`;
}

export function verifyStreamToken(secret: string, token: string): StreamClaims | null {
  const [body, sig] = token.split(".");
  if (!body || !sig) return null;
  const expected = createHmac("sha256", secret).update(body).digest();
  const given = Buffer.from(sig, "base64url");
  if (given.length !== expected.length || !timingSafeEqual(given, expected)) return null;
  try {
    const claims = JSON.parse(Buffer.from(body, "base64url").toString()) as StreamClaims;
    return claims.exp > Date.now() ? claims : null;
  } catch {
    return null;
  }
}

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

type LeaseRow = {
  holder_id: string;
  expires_at: string | Date;
  allow_shell: boolean;
};

async function activeLease(db: Database, computerId: string) {
  const [row] = await db.execute<LeaseRow>(sql`
    select holder_id, expires_at, allow_shell from public.computer_leases
    where computer_id = ${computerId}::uuid and holder_type = 'user' and mode = 'control'
      and released_at is null and expires_at > now()
    order by created_at desc limit 1`);
  return row ?? null;
}

const leaseOut = (computerId: string, row: LeaseRow | null, userId: string) =>
  row
    ? {
        computer_id: computerId,
        holder_type: "user" as const,
        holder_id: row.holder_id,
        mode: "control" as const,
        expires_at: iso(new Date(row.expires_at)),
        you: row.holder_id === userId,
      }
    : {
        computer_id: computerId,
        holder_type: "bot" as const,
        holder_id: null,
        mode: "control" as const,
        expires_at: null,
        you: false,
      };

/** Wakes runs paused on this computer so they re-check the lease or takeover state. */
async function wakeWaitingRuns(deps: AppDeps, computerId: string) {
  const rows = await deps.db.execute<{ id: string }>(
    sql`select id from public.runs where waiting_computer_id = ${computerId}::uuid and status = 'waiting_takeover'`,
  );
  await Promise.all(rows.map((r) => deps.workflows.signalRun(r.id).catch(() => {})));
}

async function audit(
  db: Database,
  orgId: string,
  userId: string,
  action: string,
  computerId: string,
  metadata: Record<string, unknown> = {},
) {
  await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
    values (${orgId}::uuid, 'user', ${userId}::uuid, ${action}, 'computer', ${computerId}::uuid, ${JSON.stringify(metadata)}::jsonb)`);
}

export function registerLiveRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const visible = async (claims: JwtClaims, id: string) => {
    const [c] = await withUserSession(db, claims, (tx) =>
      tx.select().from(computers).where(eq(computers.id, id)),
    );
    if (!c) throw new ApiError(404, "computer_not_found", "Computer not found");
    return c;
  };

  app.openapi(routes.createStreamSession, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { mode = "view" } = c.req.valid("json");
    const computer = await visible(claims, id);
    // The desktop app never streams the person's own screen (D-066); the app shows screenshots.
    if (computer.kind === "local")
      throw new ApiError(
        409,
        "not_on_companion",
        "Live view is not available on a personal computer.",
      );
    const live = deps.live;
    if (!live || !deps.computers)
      throw new ApiError(
        503,
        "live_view_unavailable",
        "Live view is not configured on this server",
      );
    if (computer.profile !== "desktop")
      throw new ApiError(
        409,
        "no_desktop",
        "This computer has no desktop. Switch it to the desktop profile first.",
      );
    await deps.computers.ensureRunning(id).catch((err) => {
      captureError(err, { service: "casama-api", step: "live-start", computer_id: id });
      throw new ApiError(
        503,
        "computer_unavailable",
        "The computer could not be started. Try again shortly.",
      );
    });
    const exp = Date.now() + SESSION_MS;
    const token = signStreamToken(live.tokenSecret, { sub: claims.sub, cid: id, mode, exp });
    const origin = deps.env.PUBLIC_API_URL ?? new URL(c.req.url).origin;
    const wsOrigin = origin.replace(/^http/, "ws");
    const creds = turnCredentials(live.turnSecret, `user-${claims.sub}`, 12 * 3600);
    return c.json(
      {
        signaling_url: `${wsOrigin}/v1/computers/${id}/stream?token=${encodeURIComponent(token)}`,
        token,
        mode,
        expires_at: iso(new Date(exp)),
        ice_servers: [turnIceServer(live.turnHost, live.turnPort, creds, live.turnTlsPort)],
        ice_transport_policy: "relay" as const,
        screenshot_url: `${origin}/v1/computers/${id}/screenshot`,
      },
      200,
    );
  });

  app.openapi(routes.computerStream, async () => {
    throw new ApiError(400, "websocket_required", "Connect to this endpoint with a WebSocket");
  });

  app.openapi(routes.getLease, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await visible(claims, id);
    return c.json(leaseOut(id, await activeLease(db, id), claims.sub), 200);
  });

  app.openapi(routes.takeLease, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { allow_shell = false } = c.req.valid("json");
    const computer = await visible(claims, id);
    const row = await db.transaction(async (tx) => {
      await tx.execute(sql`select pg_advisory_xact_lock(hashtextextended(${`lease:${id}`}, 0))`);
      const [current] = await tx.execute<LeaseRow & { id: string }>(sql`
        select id, holder_id, expires_at, allow_shell from public.computer_leases
        where computer_id = ${id}::uuid and holder_type = 'user' and mode = 'control'
          and released_at is null and expires_at > now()
        order by created_at desc limit 1`);
      if (current && current.holder_id !== claims.sub)
        throw new ApiError(409, "lease_held", "Someone else has control of this computer");
      const until = new Date(Date.now() + LEASE_MS);
      if (current) {
        const [renewed] = await tx.execute<LeaseRow>(sql`
          update public.computer_leases set expires_at = ${until.toISOString()}::timestamptz, allow_shell = ${allow_shell}
          where id = ${current.id}::uuid returning holder_id, expires_at, allow_shell`);
        return { lease: renewed as LeaseRow, created: false };
      }
      const [created] = await tx.execute<LeaseRow>(sql`
        insert into public.computer_leases (org_id, computer_id, holder_type, holder_id, mode, expires_at, allow_shell)
        values (${computer.orgId}::uuid, ${id}::uuid, 'user', ${claims.sub}::uuid, 'control', ${until.toISOString()}::timestamptz, ${allow_shell})
        returning holder_id, expires_at, allow_shell`);
      // Taking over answers any open request from a bot on this computer.
      await tx.execute(sql`update public.takeover_requests set status = 'taken'
        where computer_id = ${id}::uuid and status = 'pending'`);
      return { lease: created as LeaseRow, created: true };
    });
    if (row.created) {
      await audit(db, computer.orgId, claims.sub, "lease.taken", id, { allow_shell });
      await wakeWaitingRuns(deps, id);
    }
    return c.json(leaseOut(id, row.lease, claims.sub), 200);
  });

  app.openapi(routes.releaseLease, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { note } = c.req.valid("json");
    const computer = await visible(claims, id);
    const released = await db.execute<{ id: string }>(sql`
      update public.computer_leases set released_at = now(), note = ${note ?? null}
      where computer_id = ${id}::uuid and holder_type = 'user' and holder_id = ${claims.sub}::uuid
        and released_at is null
      returning id`);
    if (released.length) {
      await db.execute(sql`update public.takeover_requests
        set status = 'completed', note = ${note ?? null}, resolved_by = ${claims.sub}::uuid, resolved_at = now()
        where computer_id = ${id}::uuid and status in ('pending', 'taken')`);
      await audit(db, computer.orgId, claims.sub, "lease.released", id, { note: note ?? null });
      await wakeWaitingRuns(deps, id);
    }
    return c.json(leaseOut(id, await activeLease(db, id), claims.sub), 200);
  });

  const takeoverOut = (t: typeof schema.takeoverRequests.$inferSelect) => ({
    id: t.id,
    bot_id: t.botId,
    run_id: t.runId,
    computer_id: t.computerId,
    reason: t.reason,
    status: t.status as "pending",
    note: t.note,
    expires_at: iso(t.expiresAt),
    created_at: iso(t.createdAt),
  });

  app.openapi(routes.listTakeovers, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(schema.takeoverRequests)
        .where(
          sql`${schema.takeoverRequests.orgId} = ${org_id}::uuid and ${schema.takeoverRequests.status} in ('pending', 'taken') and ${schema.takeoverRequests.expiresAt} > now()`,
        )
        .orderBy(schema.takeoverRequests.createdAt),
    );
    return c.json({ items: rows.map(takeoverOut) }, 200);
  });

  app.openapi(routes.dismissTakeover, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { note } = c.req.valid("json");
    const [t] = await withUserSession(db, claims, (tx) =>
      tx.select().from(schema.takeoverRequests).where(eq(schema.takeoverRequests.id, id)),
    );
    if (!t) throw new ApiError(404, "takeover_not_found", "Takeover request not found");
    if (!["pending", "taken"].includes(t.status))
      throw new ApiError(409, "takeover_closed", "This request is already closed");
    const [updated] = await db
      .update(schema.takeoverRequests)
      .set({
        status: "dismissed",
        note: note ?? null,
        resolvedBy: claims.sub,
        resolvedAt: new Date().toISOString(),
      })
      .where(eq(schema.takeoverRequests.id, id))
      .returning();
    await deps.workflows.signalRun(t.runId).catch(() => {});
    return c.json(takeoverOut(updated as typeof t), 200);
  });
}

/** Messages a client may never send, whatever its mode. */
const ALWAYS_BLOCKED = /^(send|chat|filetransfer|system\/admin)\b/;
const CONTROL_EVENTS = /^(control|clipboard\/set|keyboard|screen\/set)\b/;

/**
 * Signaling proxy for live view. View tokens never send input; control tokens may request
 * control only while their user holds the lease, and lose it when the lease ends.
 */
export function attachStream(server: Server, deps: AppDeps) {
  const wss = new WebSocketServer({ noServer: true });
  server.on("upgrade", async (req: IncomingMessage, socket: Duplex, head: Buffer) => {
    const url = new URL(req.url ?? "/", "http://api");
    const id = url.pathname.match(/^\/v1\/computers\/([0-9a-f-]{36})\/stream$/)?.[1];
    if (!id) return;
    const reject = (status: string) => socket.end(`HTTP/1.1 ${status}\r\n\r\n`);
    try {
      if (!deps.live || !deps.computers) return reject("503 Service Unavailable");
      const claims = verifyStreamToken(deps.live.tokenSecret, url.searchParams.get("token") ?? "");
      if (!claims || claims.cid !== id) return reject("401 Unauthorized");
      const h = await deps.computers.ensureRunning(id);
      const target = await h.streamEndpoint({ mode: claims.mode });
      const svc = deps.computers;
      const db = deps.db;
      wss.handleUpgrade(req, socket, head, (client) => {
        const upstream = new WebSocket(target.url, { headers: target.headers });
        const pending: Array<{ data: unknown; binary: boolean }> = [];
        let isHost = false;
        const holdsLease = async () => (await activeLease(db, id))?.holder_id === claims.sub;
        // Only a person keeps the computer awake (D-195): their input or the app's presence beat.
        const touch = throttledTouch(() => svc.touch(id));
        // Drop control when the lease ends.
        const tick = setInterval(async () => {
          if (isHost && !(await holdsLease().catch(() => false))) {
            isHost = false;
            if (upstream.readyState === WebSocket.OPEN)
              upstream.send(JSON.stringify({ event: "control/release" }));
          }
        }, 5000);
        const forward = (data: unknown, binary: boolean) => {
          if (upstream.readyState === WebSocket.OPEN) upstream.send(data as Buffer, { binary });
          else pending.push({ data, binary });
        };
        client.on("message", async (data, binary) => {
          if (binary) return; // input travels on the WebRTC data channel, never here
          // Presence: the person is watching. It stays here; Neko doesn't know it.
          if (isPresence(data)) return touch();
          let event = "";
          try {
            event = (JSON.parse(String(data)) as { event?: string }).event ?? "";
          } catch {
            return;
          }
          if (ALWAYS_BLOCKED.test(event)) return;
          if (CONTROL_EVENTS.test(event)) {
            if (claims.mode !== "control") return;
            if (event === "control/request") {
              if (!(await holdsLease().catch(() => false))) return;
              isHost = true;
            }
            if (event === "control/release") isHost = false;
            // Control messages (taking control, clipboard, keyboard layout, screen size) are input.
            touch();
          }
          forward(data, false);
        });
        upstream.on("open", () => {
          for (const p of pending.splice(0)) upstream.send(p.data as Buffer, { binary: p.binary });
        });
        upstream.on("message", (data, binary) => {
          if (client.readyState === WebSocket.OPEN) client.send(data as Buffer, { binary });
        });
        const close = () => {
          clearInterval(tick);
          client.close();
          upstream.close();
        };
        upstream.on("close", close);
        upstream.on("error", close);
        client.on("close", close);
        client.on("error", close);
      });
    } catch (err) {
      captureError(err, { service: "casama-api", step: "live-upstream" });
      reject("503 Service Unavailable");
    }
  });
}
