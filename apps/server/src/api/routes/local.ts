/**
 * Local computer companion (Phase 6, D-066): pairing, the device WebSocket, and the internal tunnel
 * the worker uses to reach a device's embedded computerd.
 *
 * Tunnel protocol (JSON text frames):
 *   API -> device  {type:"request", id, method, path, headers, body?: base64, activity?}
 *   device -> API  {type:"response", id, status, headers} {type:"chunk", id, data: base64}* {type:"end", id}
 *                  {type:"error", id, message}
 *   device -> API  {type:"hello", platform, version}   API -> device {type:"ready", device_id}
 */
import { createHash, createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import type { IncomingMessage, Server } from "node:http";
import type { Duplex } from "node:stream";
import { routes } from "@casama/contracts";
import { type Database, type JwtClaims, schema, withUserSession } from "@casama/db";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { eq, sql } from "drizzle-orm";
import type { Hono } from "hono";
import { stream } from "hono/streaming";
import { type WebSocket, WebSocketServer } from "ws";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";
import { integrationOut } from "./autonomy.ts";

const { localDevices, computers } = schema;
const REQUEST_TIMEOUT_MS = 15 * 60 * 1000;
/** Local MCP calls may run up to two hours (their own timeout, D-096, is usually shorter). */
const MCP_TIMEOUT_MS = 2 * 60 * 60 * 1000;
/** JSON-RPC methods that may reach a local MCP server without a run (listing its tools). */
const MCP_LIST_METHODS = new Set(["initialize", "notifications/initialized", "tools/list"]);

export const hashDeviceToken = (t: string) => createHash("sha256").update(t).digest("hex");

/** Secret for /internal/* shared by the API and worker (both know DATABASE_URL). */
export function internalToken(env: { INTERNAL_TOKEN?: string; DATABASE_URL: string }) {
  return (
    env.INTERNAL_TOKEN ??
    createHmac("sha256", env.DATABASE_URL).update("casama-internal").digest("hex")
  );
}

type Pending = {
  onResponse: (status: number, headers: Record<string, string>) => void;
  onChunk: (data: Buffer) => void;
  onEnd: () => void;
  onError: (message: string) => void;
};

/** Connected devices by computer id (one API instance holds the sockets; D-066). */
export class DeviceRegistry {
  private readonly sockets = new Map<
    string,
    { ws: WebSocket; deviceId: string; pending: Map<string, Pending> }
  >();
  private seq = 0;

  attach(computerId: string, deviceId: string, ws: WebSocket) {
    this.sockets.get(computerId)?.ws.close(4000, "replaced by a newer connection");
    const entry = { ws, deviceId, pending: new Map<string, Pending>() };
    this.sockets.set(computerId, entry);
    ws.on("message", (raw) => {
      let m: {
        type: string;
        id?: string;
        status?: number;
        headers?: Record<string, string>;
        data?: string;
        message?: string;
      };
      try {
        m = JSON.parse(String(raw));
      } catch {
        return;
      }
      const p = m.id ? entry.pending.get(m.id) : undefined;
      if (!p) return;
      if (m.type === "response") p.onResponse(m.status ?? 502, m.headers ?? {});
      else if (m.type === "chunk" && m.data) p.onChunk(Buffer.from(m.data, "base64"));
      else if (m.type === "end") {
        entry.pending.delete(m.id as string);
        p.onEnd();
      } else if (m.type === "error") {
        entry.pending.delete(m.id as string);
        p.onError(m.message ?? "device error");
      }
    });
    ws.on("close", () => {
      if (this.sockets.get(computerId)?.ws === ws) this.sockets.delete(computerId);
      for (const p of entry.pending.values()) p.onError("The computer disconnected");
      entry.pending.clear();
    });
  }

  online(computerId: string) {
    return this.sockets.has(computerId);
  }

  deviceIds() {
    return new Set([...this.sockets.values()].map((s) => s.deviceId));
  }

  disconnect(deviceId: string) {
    for (const s of this.sockets.values())
      if (s.deviceId === deviceId) s.ws.close(4001, "unpaired");
  }

  request(
    computerId: string,
    req: {
      method: string;
      path: string;
      headers: Record<string, string>;
      body?: Buffer;
      activity?: unknown;
    },
    handlers: Pending,
  ) {
    const entry = this.sockets.get(computerId);
    if (!entry) throw new ApiError(409, "device_offline", "The computer is offline");
    const id = `r${++this.seq}`;
    const timer = setTimeout(
      () => {
        entry.pending.delete(id);
        handlers.onError("The computer did not answer in time");
      },
      req.path.startsWith("/mcp/") ? MCP_TIMEOUT_MS : REQUEST_TIMEOUT_MS,
    );
    const done =
      <A extends unknown[]>(f: (...a: A) => void) =>
      (...a: A) => {
        clearTimeout(timer);
        f(...a);
      };
    entry.pending.set(id, {
      ...handlers,
      onEnd: done(handlers.onEnd),
      onError: done(handlers.onError),
    });
    entry.ws.send(
      JSON.stringify({
        type: "request",
        id,
        method: req.method,
        path: req.path,
        headers: req.headers,
        body: req.body?.length ? req.body.toString("base64") : undefined,
        activity: req.activity,
      }),
    );
    return () => {
      // The caller went away (for example a killed exec): tell the device to stop.
      if (entry.pending.delete(id)) entry.ws.send(JSON.stringify({ type: "cancel", id }));
    };
  }
}

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

type DeviceRow = typeof localDevices.$inferSelect;
const caps = (c: unknown) =>
  (c ?? {}) as {
    shell?: boolean;
    files?: boolean;
    browser?: boolean;
    desktop?: boolean;
    messages?: boolean;
  };

export function registerLocalRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const registry = deps.devices;
  const out = (d: DeviceRow) => ({
    id: d.id,
    org_id: d.orgId,
    user_id: d.userId,
    computer_id: d.computerId,
    name: d.name,
    platform: d.platform as "macos",
    capabilities: caps(d.capabilities),
    allowed_roots: d.allowedRoots,
    allowed_bot_ids: d.allowedBotIds,
    enabled: d.enabled,
    online: !!d.computerId && !!registry?.online(d.computerId),
    last_seen_at: d.lastSeenAt ? iso(d.lastSeenAt) : null,
    created_at: iso(d.createdAt),
  });
  const own = async (claims: JwtClaims, id: string) => {
    const [d] = await withUserSession(db, claims, (tx) =>
      tx.select().from(localDevices).where(eq(localDevices.id, id)),
    );
    if (!d || d.userId !== claims.sub)
      throw new ApiError(404, "device_not_found", "Device not found");
    return d;
  };

  app.openapi(routes.createLocalDevice, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    const [m] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${body.org_id}::uuid) as ok`),
    );
    if (!m?.ok) throw new ApiError(403, "forbidden", "You are not a member of this workspace");
    const token = `kdev_${randomBytes(32).toString("base64url")}`;
    const created = await db.transaction(async (tx) => {
      const [computer] = await tx
        .insert(computers)
        .values({
          orgId: body.org_id,
          kind: "local",
          provider: "local",
          name: body.name,
          profile: "desktop",
          state: "stopped",
        })
        .returning();
      const [d] = await tx
        .insert(localDevices)
        .values({
          orgId: body.org_id,
          userId: claims.sub,
          computerId: computer?.id,
          name: body.name,
          platform: body.platform,
          tokenHash: hashDeviceToken(token),
        })
        .returning();
      return d as DeviceRow;
    });
    return c.json({ ...out(created), token }, 201);
  });

  app.openapi(routes.listLocalDevices, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(localDevices)
        .where(eq(localDevices.orgId, org_id))
        .orderBy(localDevices.createdAt),
    );
    return c.json({ items: rows.map(out) }, 200);
  });

  app.openapi(routes.updateLocalDevice, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const d = await own(claims, id);
    if (body.allowed_bot_ids?.length) {
      const ok = await db.execute<{ n: number }>(sql`select count(*)::int as n from public.bots
        where org_id = ${d.orgId}::uuid and id = any(${`{${body.allowed_bot_ids.join(",")}}`}::uuid[])`);
      if (ok[0]?.n !== body.allowed_bot_ids.length)
        throw new ApiError(400, "bad_bots", "Some bots are not in this workspace");
    }
    const [updated] = await db
      .update(localDevices)
      .set({
        ...(body.name ? { name: body.name } : {}),
        ...(body.capabilities ? { capabilities: body.capabilities } : {}),
        ...(body.allowed_roots ? { allowedRoots: body.allowed_roots } : {}),
        ...(body.allowed_bot_ids ? { allowedBotIds: body.allowed_bot_ids } : {}),
        ...(body.enabled !== undefined ? { enabled: body.enabled } : {}),
      })
      .where(eq(localDevices.id, id))
      .returning();
    if (body.enabled === false) registry?.disconnect(id);
    if (body.name && d.computerId)
      await db.update(computers).set({ name: body.name }).where(eq(computers.id, d.computerId));
    return c.json(out(updated as DeviceRow), 200);
  });

  // Local MCP servers (D-096): the app registers what it runs; each is a local_mcp integration.
  app.openapi(routes.setLocalMcpServers, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { servers } = c.req.valid("json");
    const d = await own(claims, id);
    const suffix = d.id.replace(/-/g, "").slice(0, 6);
    const nameOf = (key: string) => `${key.slice(0, 32)}_${suffix}`;
    const keys = new Set(servers.map((s) => s.key));
    if (keys.size !== servers.length)
      throw new ApiError(400, "duplicate_server", "Each local MCP server needs its own key");
    await db.transaction(async (tx) => {
      const existing = await tx.execute<{ id: string; server: string }>(sql`
        select id, config->>'server' as server from public.integrations
        where kind = 'local_mcp' and config->>'device_id' = ${d.id}`);
      for (const row of existing)
        if (!keys.has(row.server))
          await tx.execute(sql`delete from public.integrations where id = ${row.id}::uuid`);
      for (const s of servers) {
        const config = {
          device_id: d.id,
          computer_id: d.computerId,
          owner_user_id: d.userId,
          server: s.key,
          label: s.label,
          summary: s.summary,
          timeout_s: s.timeout_s ?? 1800,
        };
        const [row] = await tx.execute<{ id: string; inserted: boolean }>(sql`
          insert into public.integrations (org_id, kind, name, config, status, created_by)
          values (${d.orgId}::uuid, 'local_mcp', ${nameOf(s.key)}, ${JSON.stringify(config)}::jsonb, 'pending', ${claims.sub}::uuid)
          on conflict (org_id, name) do update set config = excluded.config,
            tools_cached_at = null
          returning id, (xmax = 0) as inserted`);
        // New servers start with the bots this computer already allows.
        if (row?.inserted && d.allowedBotIds?.length)
          await tx.execute(sql`
            insert into public.bot_integrations (org_id, bot_id, integration_id)
            select ${d.orgId}::uuid, b.id, ${row.id}::uuid from public.bots b
            where b.id = any(${`{${d.allowedBotIds.join(",")}}`}::uuid[]) and b.org_id = ${d.orgId}::uuid
            on conflict do nothing`);
      }
    });
    const rows = await db.execute<{ id: string }>(sql`
      select id from public.integrations where kind = 'local_mcp' and config->>'device_id' = ${d.id}
      order by name`);
    const items = [];
    for (const r of rows) {
      const [i] = await db
        .select()
        .from(schema.integrations)
        .where(eq(schema.integrations.id, r.id));
      if (i) items.push(integrationOut(i));
    }
    return c.json({ items }, 200);
  });

  app.openapi(routes.deleteLocalDevice, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const d = await own(claims, id);
    registry?.disconnect(id);
    await db.delete(localDevices).where(eq(localDevices.id, id));
    if (d.computerId) {
      await db.execute(
        sql`update public.bots set default_computer_id = null where default_computer_id = ${d.computerId}::uuid`,
      );
      await db.delete(computers).where(eq(computers.id, d.computerId));
    }
    return c.json({ deleted: id }, 200);
  });

  app.openapi(routes.localComputerConnect, async () => {
    throw new ApiError(400, "websocket_required", "Connect to this endpoint with a WebSocket");
  });
}

/** /internal/local/:computerId/... — the worker's tunnel to a device (not in the public API). */
export function registerInternalRoutes(app: Hono<AppEnv>, deps: AppDeps) {
  const token = internalToken(deps.env);
  const registry = deps.devices;
  const ok = (h: string | undefined) => {
    if (!h) return false;
    const a = Buffer.from(h);
    const b = Buffer.from(token);
    return a.length === b.length && timingSafeEqual(a, b);
  };
  app.use("/internal/*", async (c, next) => {
    if (!ok(c.req.header("x-casama-internal"))) return c.json({ code: "unauthorized" }, 401);
    await next();
  });
  app.get("/internal/local/:computer/status", async (c) => {
    const id = c.req.param("computer");
    const [d] = await deps.db.execute<{ allowed_bot_ids: string[]; enabled: boolean }>(
      sql`select allowed_bot_ids, enabled from public.local_devices where computer_id = ${id}::uuid`,
    );
    return c.json({ online: !!registry?.online(id) && !!d?.enabled });
  });
  app.all("/internal/local/:computer/http/*", async (c) => {
    if (!registry) return c.json({ code: "unavailable" }, 503);
    const computerId = c.req.param("computer");
    const url = new URL(c.req.url);
    const path = url.pathname.replace(`/internal/local/${computerId}/http`, "") + url.search;
    const body = ["GET", "HEAD"].includes(c.req.method)
      ? undefined
      : Buffer.from(await c.req.arrayBuffer());
    const headers: Record<string, string> = {};
    for (const h of ["content-type", "content-length"]) {
      const v = c.req.header(h);
      if (v) headers[h] = v;
    }
    const activityHeader = c.req.header("x-casama-activity");
    let activity: unknown;
    try {
      activity = activityHeader
        ? JSON.parse(Buffer.from(activityHeader, "base64").toString())
        : undefined;
    } catch {}

    // Listing a local MCP server's tools needs no run; calling them does (D-096).
    const listingOnly = (() => {
      if (!path.startsWith("/mcp/") || (activity as { run_id?: string } | undefined)?.run_id)
        return false;
      try {
        const parsed = JSON.parse(body?.toString() ?? "null") as unknown;
        const msgs = (Array.isArray(parsed) ? parsed : [parsed]) as Array<{ method?: unknown }>;
        return msgs.length > 0 && msgs.every((m) => MCP_LIST_METHODS.has(String(m?.method)));
      } catch {
        return false;
      }
    })();
    // Only bots the user allowed may act on their machine (health checks carry no run).
    if (path !== "/health" && !listingOnly) {
      const runId = (activity as { run_id?: string } | undefined)?.run_id;
      // iMessage chat apps (D-134) poll and send with no run: allowed when the Mac's owner
      // connected it to a bot they allowed on this machine.
      const imessage = !runId && /^\/imessage\/(new|send)(\?|$)/.test(path);
      const [allowed] = imessage
        ? await deps.db.execute<{ ok: boolean }>(sql`
            select true as ok from public.channels ch, public.local_devices d
            where ch.kind = 'imessage' and ch.enabled and ch.config ->> 'computer_id' = ${computerId}
              and d.computer_id = ${computerId}::uuid and d.enabled and ch.bot_id = any(d.allowed_bot_ids) limit 1`)
        : runId
          ? await deps.db.execute<{ ok: boolean }>(sql`
            select r.bot_id = any(d.allowed_bot_ids) and d.enabled as ok
            from public.runs r, public.local_devices d
            where r.id = ${runId}::uuid and d.computer_id = ${computerId}::uuid`)
          : [];
      if (!allowed?.ok)
        return c.json(
          { code: "bot_not_allowed", message: "This bot is not allowed to use that computer" },
          403,
        );
    }
    let resolveHead!: (v: { status: number; headers: Record<string, string> }) => void;
    let rejectHead!: (e: unknown) => void;
    const headPromise = new Promise<{ status: number; headers: Record<string, string> }>(
      (res, rej) => {
        resolveHead = res;
        rejectHead = rej;
      },
    );
    const chunks: Buffer[] = [];
    let push: ((b: Buffer | null) => void) | null = null;
    let finished = false;
    let failure: string | null = null;
    const cancel = (() => {
      try {
        return registry.request(
          computerId,
          { method: c.req.method, path, headers, body, activity },
          {
            onResponse: (status, h) => resolveHead({ status, headers: h }),
            onChunk: (d) => (push ? push(d) : chunks.push(d)),
            onEnd: () => {
              finished = true;
              push?.(null);
            },
            onError: (m) => {
              failure = m;
              rejectHead(new ApiError(502, "device_error", m));
              finished = true;
              push?.(null);
            },
          },
        );
      } catch (err) {
        rejectHead(err);
        return () => {};
      }
    })();
    const { status, headers: resHeaders } = await headPromise;
    for (const [k, v] of Object.entries(resHeaders))
      if (!/^(content-length|transfer-encoding|connection)$/i.test(k)) c.header(k, String(v));
    c.status(status as 200);
    return stream(c, async (s) => {
      s.onAbort(cancel);
      for (const b of chunks.splice(0)) await s.write(b);
      if (finished) return;
      await new Promise<void>((resolve) => {
        push = (b) => {
          if (b === null) return resolve();
          void s.write(b);
        };
      });
      if (failure) await s.write("");
    });
  });
}

/** Accepts device WebSockets: authenticates the token and registers the device. */
export function attachLocalConnect(server: Server, deps: AppDeps) {
  const wss = new WebSocketServer({ noServer: true });
  server.on("upgrade", async (req: IncomingMessage, socket: Duplex, head: Buffer) => {
    const url = new URL(req.url ?? "/", "http://api");
    if (url.pathname !== "/v1/local-computer/connect") return;
    const reject = (s: string) => socket.end(`HTTP/1.1 ${s}\r\n\r\n`);
    if (!deps.devices) return reject("503 Service Unavailable");
    const auth = req.headers.authorization;
    const token = auth?.startsWith("Device ") ? auth.slice(7) : url.searchParams.get("token");
    if (!token) return reject("401 Unauthorized");
    const [d] = await deps.db
      .select()
      .from(localDevices)
      .where(eq(localDevices.tokenHash, hashDeviceToken(token)))
      .catch(() => [] as DeviceRow[]);
    if (!d?.enabled || !d.computerId) return reject("401 Unauthorized");
    const registry = deps.devices;
    const computerId = d.computerId;
    wss.handleUpgrade(req, socket, head, (ws) => {
      registry.attach(computerId, d.id, ws);
      ws.send(JSON.stringify({ type: "ready", device_id: d.id, computer_id: computerId }));
      const seen = () => void touch(deps.db, d.id, computerId).catch(() => {});
      seen();
      const t = setInterval(seen, 60_000);
      ws.on("close", () => {
        clearInterval(t);
        void deps.db
          .execute(
            sql`update public.computers set state = 'stopped' where id = ${computerId}::uuid`,
          )
          .catch(() => {});
      });
    });
  });
}

async function touch(db: Database, deviceId: string, computerId: string) {
  await db.execute(
    sql`update public.local_devices set last_seen_at = now() where id = ${deviceId}::uuid`,
  );
  await db.execute(
    sql`update public.computers set state = 'running', last_active_at = now() where id = ${computerId}::uuid`,
  );
}
