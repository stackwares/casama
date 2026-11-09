import type { IncomingMessage, Server } from "node:http";
import type { Duplex } from "node:stream";
import type { OpenAPIHono } from "@hono/zod-openapi";
import type { ComputerRow, ComputerService } from "@kasama/agent";
import { routes } from "@kasama/contracts";
import { type JwtClaims, schema, withUserSession } from "@kasama/db";
import { SandboxError } from "@kasama/sandbox";
import { desc, eq, sql } from "drizzle-orm";
import { WebSocket, WebSocketServer } from "ws";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const { computers, checkpoints } = schema;
const MAX_UPLOAD = 100 * 1024 * 1024;

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

type Row = typeof computers.$inferSelect;
const out = (c: Row) => ({
  id: c.id,
  org_id: c.orgId,
  kind: c.kind as "team",
  name: c.name,
  owner_bot_id: c.ownerBotId,
  provider: c.provider,
  profile: c.profile as "headless",
  state: c.state as "running",
  size: c.size as { cpus?: number; memory_mb?: number; disk_gb?: number },
  has_snapshot: c.snapshotRef != null,
  last_active_at: c.lastActiveAt ? iso(c.lastActiveAt) : null,
  error: c.error,
  created_at: iso(c.createdAt),
});

/** Turns sandbox errors into problem responses. */
async function sandbox<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (err) {
    if (err instanceof SandboxError) {
      if (err.status === 404 || err.code === "not_found")
        throw new ApiError(404, "not_found", err.message);
      if (err.status === 400) throw new ApiError(400, err.code, err.message);
      throw new ApiError(
        503,
        "computer_unavailable",
        "The computer could not be reached. Try again shortly.",
      );
    }
    throw err;
  }
}

export function registerComputerRoutes(app: OpenAPIHono<AppEnv>, deps: AppDeps) {
  const { db } = deps;
  const service = (): ComputerService => {
    if (!deps.computers)
      throw new ApiError(
        503,
        "computers_unavailable",
        "Computers are not configured on this server",
      );
    return deps.computers;
  };

  /** Loads a computer the caller can see (RLS), or 404. */
  const visible = async (claims: JwtClaims, id: string) => {
    const [c] = await withUserSession(db, claims, (tx) =>
      tx.select().from(computers).where(eq(computers.id, id)),
    );
    if (!c) throw new ApiError(404, "computer_not_found", "Computer not found");
    return c;
  };
  const reload = async (id: string) => {
    const [c] = await db.select().from(computers).where(eq(computers.id, id));
    return out(c as Row);
  };
  const handle = async (claims: JwtClaims, id: string) => {
    await visible(claims, id);
    return sandbox(() => service().ensureRunning(id));
  };

  app.openapi(routes.listComputers, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id } = c.req.valid("query");
    const rows = await withUserSession(db, claims, (tx) =>
      tx.select().from(computers).where(eq(computers.orgId, org_id)).orderBy(computers.createdAt),
    );
    return c.json({ items: rows.map(out) }, 200);
  });

  app.openapi(routes.getComputer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json(out(await visible(claims, c.req.valid("param").id)), 200);
  });

  app.openapi(routes.startComputer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await handle(claims, id);
    return c.json(await reload(id), 200);
  });

  app.openapi(routes.stopComputer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await visible(claims, id);
    await sandbox(() => service().stop(id));
    return c.json(await reload(id), 200);
  });

  app.openapi(routes.restartComputer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await visible(claims, id);
    await sandbox(async () => {
      await service().stop(id);
      await service().ensureRunning(id);
    });
    return c.json(await reload(id), 200);
  });

  app.openapi(routes.listComputerFiles, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { path = "" } = c.req.valid("query");
    const h = await handle(claims, id);
    const entries = await sandbox(() => h.listDir(path));
    return c.json({ path: path || "~/workspace", entries }, 200);
  });

  app.openapi(routes.downloadComputerFile, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { path } = c.req.valid("query");
    const h = await handle(claims, id);
    const data = await sandbox(() => h.readFile(path));
    const name = path.split("/").pop() ?? "file";
    return c.body(Buffer.from(data), 200, {
      "content-type": "application/octet-stream",
      "content-disposition": `attachment; filename="${name.replace(/[^\w.-]/g, "_")}"`,
    }) as never;
  });

  app.openapi(routes.uploadComputerFile, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { path } = c.req.valid("query");
    const length = Number(c.req.header("content-length") ?? 0);
    if (length > MAX_UPLOAD)
      throw new ApiError(400, "file_too_large", "Uploads are limited to 100 MB");
    const data = new Uint8Array(await c.req.arrayBuffer());
    if (data.length > MAX_UPLOAD)
      throw new ApiError(400, "file_too_large", "Uploads are limited to 100 MB");
    const h = await handle(claims, id);
    await sandbox(() => h.writeFile(path, data));
    return c.json({ path, size: data.length }, 200);
  });

  app.openapi(routes.deleteComputerFile, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { path } = c.req.valid("query");
    const h = await handle(claims, id);
    await sandbox(() => h.deleteFile(path));
    return c.json({ deleted: path }, 200);
  });

  const cpOut = (r: typeof checkpoints.$inferSelect) => ({
    id: r.id,
    computer_id: r.computerId,
    run_id: r.runId,
    label: r.label,
    size: Number((r.storageRef as { size?: number }).size ?? 0),
    created_at: iso(r.createdAt),
  });

  app.openapi(routes.listCheckpoints, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await visible(claims, id);
    const rows = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(checkpoints)
        .where(eq(checkpoints.computerId, id))
        .orderBy(desc(checkpoints.createdAt)),
    );
    return c.json({ items: rows.map(cpOut) }, 200);
  });

  app.openapi(routes.createCheckpoint, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { label } = c.req.valid("json");
    await visible(claims, id);
    const { checkpointId } = await sandbox(() => service().checkpoint(id, label, null));
    const [row] = await db.select().from(checkpoints).where(eq(checkpoints.id, checkpointId));
    return c.json(cpOut(row as typeof checkpoints.$inferSelect), 201);
  });

  app.openapi(routes.restoreCheckpoint, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, cid } = c.req.valid("param");
    await visible(claims, id);
    const [cp] = await withUserSession(db, claims, (tx) =>
      tx.select().from(checkpoints).where(eq(checkpoints.id, cid)),
    );
    if (!cp || cp.computerId !== id)
      throw new ApiError(404, "checkpoint_not_found", "Checkpoint not found");
    await sandbox(() => service().restoreCheckpoint(cid));
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
      values (${cp.orgId}::uuid, 'user', ${claims.sub}::uuid, 'checkpoint.restored', 'computer', ${id}::uuid, ${JSON.stringify({ checkpoint_id: cid })}::jsonb)`);
    return c.json(await reload(id), 200);
  });

  app.openapi(routes.computerTerminal, async () => {
    throw new ApiError(400, "websocket_required", "Connect to this endpoint with a WebSocket");
  });
}

/** WebSocket terminal: client <-> API <-> supervisor <-> computerd. Keeps the computer awake while open. */
export function attachTerminal(server: Server, deps: AppDeps) {
  const wss = new WebSocketServer({ noServer: true });
  server.on("upgrade", async (req: IncomingMessage, socket: Duplex, head: Buffer) => {
    const url = new URL(req.url ?? "/", "http://api");
    const id = url.pathname.match(/^\/v1\/computers\/([0-9a-f-]{36})\/terminal$/)?.[1];
    if (!id) return;
    const reject = (status: string) => socket.end(`HTTP/1.1 ${status}\r\n\r\n`);
    try {
      if (!deps.computers) return reject("503 Service Unavailable");
      const header = req.headers.authorization;
      const token = header?.startsWith("Bearer ")
        ? header.slice(7)
        : url.searchParams.get("access_token");
      if (!token) return reject("401 Unauthorized");
      const claims = await deps.verifyToken(token).catch(() => null);
      if (!claims) return reject("401 Unauthorized");
      const [c] = await withUserSession(deps.db, claims, (tx) =>
        tx.select().from(computers).where(eq(computers.id, id)),
      );
      if (!c) return reject("404 Not Found");
      const h = await deps.computers.ensureRunning(id);
      const target = await h.terminalEndpoint({
        cols: Number(url.searchParams.get("cols") ?? 120),
        rows: Number(url.searchParams.get("rows") ?? 32),
      });
      const svc = deps.computers;
      wss.handleUpgrade(req, socket, head, (client) => {
        const upstream = new WebSocket(target.url, { headers: target.headers });
        const pending: Array<{ data: unknown; binary: boolean }> = [];
        const keepAlive = setInterval(() => void svc.touch(id).catch(() => {}), 60_000);
        client.on("message", (data, binary) => {
          if (upstream.readyState === WebSocket.OPEN) upstream.send(data as Buffer, { binary });
          else pending.push({ data, binary });
        });
        upstream.on("open", () => {
          for (const p of pending.splice(0)) upstream.send(p.data as Buffer, { binary: p.binary });
        });
        upstream.on(
          "message",
          (data, binary) =>
            client.readyState === WebSocket.OPEN && client.send(data as Buffer, { binary }),
        );
        const close = () => {
          clearInterval(keepAlive);
          client.close();
          upstream.close();
        };
        upstream.on("close", close);
        upstream.on("error", close);
        client.on("close", close);
        client.on("error", close);
      });
    } catch {
      reject("503 Service Unavailable");
    }
  });
}

export type { ComputerRow };
