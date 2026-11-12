import type { IncomingMessage, Server } from "node:http";
import type { Duplex } from "node:stream";
import { type ComputerRow, type ComputerService, milestone } from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, schema, withUserSession } from "@casama/db";
import { SandboxError } from "@casama/sandbox";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { desc, eq, inArray, sql } from "drizzle-orm";
import { WebSocket, WebSocketServer } from "ws";
import { enforceLimit } from "../../billing/limits.ts";
import { ApiError } from "../errors.ts";
import { isPresence, throttledTouch } from "../keep-awake.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const { computers, checkpoints, localDevices } = schema;
const MAX_UPLOAD = 100 * 1024 * 1024;

function requireClaims(claims: JwtClaims | undefined): JwtClaims {
  if (!claims) throw new ApiError(401, "unauthorized", "Missing or invalid bearer token");
  return claims;
}

type Row = typeof computers.$inferSelect;
type DeviceRow = typeof localDevices.$inferSelect;
type Platform = "macos" | "windows" | "linux";

/** What the computer images run (infra/images/computer/Dockerfile.*: FROM ubuntu:24.04). */
export const DOCKER_COMPUTER_OS = "Ubuntu 24.04";
const PLATFORM_NAMES: Record<Platform, string> = {
  macos: "macOS",
  windows: "Windows",
  linux: "Linux",
};

/** The operating system the card shows (D-227): the device's own report, else what we know. */
export function computerOs(c: Pick<Row, "kind" | "provider">, d?: DeviceRow | null): string | null {
  if (c.kind === "local") {
    if (!d) return null;
    return d.osVersion || PLATFORM_NAMES[d.platform as Platform] || null;
  }
  return c.provider === "docker" ? DOCKER_COMPUTER_OS : null;
}

const out = (c: Row, d?: DeviceRow | null, online?: boolean) => ({
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
  max_desktops: c.maxDesktops,
  last_active_at: c.lastActiveAt ? iso(c.lastActiveAt) : null,
  error: c.error,
  created_at: iso(c.createdAt),
  os: computerOs(c, d),
  device:
    c.kind === "local" && d
      ? {
          platform: d.platform as Platform,
          online: !!online,
          last_seen_at: d.lastSeenAt ? iso(d.lastSeenAt) : null,
          capabilities: deviceCaps(d.capabilities),
        }
      : null,
});

function deviceCaps(raw: unknown) {
  const v = (raw ?? {}) as Record<string, unknown>;
  const pick = ["shell", "files", "browser", "desktop", "mcp", "messages"] as const;
  return Object.fromEntries(pick.filter((k) => v[k] === true).map((k) => [k, true])) as Partial<
    Record<(typeof pick)[number], boolean>
  >;
}

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
  /** The API shape, with each personal computer's device (read after RLS let the rows through). */
  const present = async (rows: Row[]) => {
    const local = rows.filter((r) => r.kind === "local").map((r) => r.id);
    const devices = local.length
      ? await db.select().from(localDevices).where(inArray(localDevices.computerId, local))
      : [];
    const byComputer = new Map(devices.map((d) => [d.computerId, d]));
    return rows.map((r) => out(r, byComputer.get(r.id), !!deps.devices?.online(r.id)));
  };
  const reload = async (id: string) => {
    const [c] = await db.select().from(computers).where(eq(computers.id, id));
    return (await present([c as Row]))[0];
  };
  const handle = async (claims: JwtClaims, id: string) => {
    await visible(claims, id);
    return sandbox(() => service().ensureRunning(id));
  };

  app.openapi(routes.listComputers, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { org_id } = c.req.valid("query");
    const list = () =>
      withUserSession(db, claims, (tx) =>
        tx.select().from(computers).where(eq(computers.orgId, org_id)).orderBy(computers.createdAt),
      );
    let rows = await list();
    // The screen shows what the sandbox really is, not just the last recorded state.
    const svc = deps.computers;
    if (svc && rows.length) {
      const checks = rows.map((r) => svc.reconcile(r.id).catch(() => r.state));
      const settled = await Promise.race([
        Promise.all(checks),
        new Promise<null>((r) => setTimeout(() => r(null), 1500)),
      ]);
      if (settled?.some((s, i) => s !== rows[i]?.state)) rows = await list();
    }
    return c.json({ items: await present(rows) }, 200);
  });

  app.openapi(routes.getComputer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    return c.json((await present([await visible(claims, c.req.valid("param").id)]))[0], 200);
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

  // Office documents as PDF (D-205). LibreOffice on the computer converts them, once per file
  // version: the result is cached in ~/.cache/casama-previews under a hash of the path and its
  // modified time. Checked by extension first, so other files never wake the computer.
  app.openapi(routes.computerFilePdfPreview, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { path } = c.req.valid("query");
    if (!pdfPreviewable(path))
      throw new ApiError(415, "preview_unsupported", "This kind of file has no PDF preview");
    const h = await handle(claims, id);
    const { collectExec } = await import("@casama/sandbox");
    const r = await collectExec(
      h.exec(pdfPreviewScript(absoluteComputerPath(h.resolvePath?.(path) ?? path)), {
        timeoutMs: 90_000,
      }),
    );
    if (r.code === 44) throw new ApiError(404, "not_found", "No such file");
    if (r.code === 45)
      throw new ApiError(415, "preview_unsupported", "This computer can't make PDF previews");
    const out = r.stdout.trim().split("\n").pop() ?? "";
    if (r.code !== 0 || !out.endsWith(".pdf"))
      throw new ApiError(422, "preview_failed", "Couldn't make a preview of this document");
    const pdf = await sandbox(() => h.readFile(out));
    return c.body(Buffer.from(pdf), 200, {
      "content-type": "application/pdf",
      "cache-control": "private, no-cache",
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

  app.openapi(routes.computerScreenshot, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const h = await handle(claims, id);
    let png: Uint8Array;
    try {
      png = await h.screenshot();
    } catch (err) {
      if (!(err instanceof SandboxError) || err.status !== 501) throw err;
      // Headless: capture the bot's browser page instead, if a browser is open.
      const { collectExec } = await import("@casama/sandbox");
      const r = await collectExec(
        h.exec("agent-browser screenshot /tmp/casama-screen.png >/dev/null 2>&1 && echo ok", {
          timeoutMs: 20_000,
        }),
      );
      if (!r.stdout.includes("ok"))
        throw new ApiError(409, "nothing_to_show", "No desktop or open browser page to capture");
      png = await sandbox(() => h.readFile("/tmp/casama-screen.png"));
    }
    return c.body(Buffer.from(png), 200, {
      "content-type": "image/png",
      "cache-control": "no-store",
    }) as never;
  });

  /** Team computers are managed by admins; private computers by whoever manages the bot. */
  const canManage = async (claims: JwtClaims, orgId: string, ownerBotId: string | null) => {
    const [r] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(
        ownerBotId
          ? sql`select public.can_manage_bot(${ownerBotId}::uuid) as ok`
          : sql`select public.has_role(${orgId}::uuid, 'admin') as ok`,
      ),
    );
    if (!r?.ok)
      throw new ApiError(
        403,
        "forbidden",
        ownerBotId ? "Only the bot's managers can do that" : "Only workspace admins can do that",
      );
  };

  app.openapi(routes.createComputer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const body = c.req.valid("json");
    if (body.kind === "private" && !body.owner_bot_id)
      throw new ApiError(
        400,
        "owner_required",
        "Private computers belong to a bot: set owner_bot_id",
      );
    const owner = body.kind === "private" ? (body.owner_bot_id as string) : null;
    if (owner) {
      const [bot] = await db.execute<{ org_id: string }>(
        sql`select org_id from public.bots where id = ${owner}::uuid`,
      );
      if (bot?.org_id !== body.org_id)
        throw new ApiError(400, "bad_owner", "That bot is not in this workspace");
    }
    await canManage(claims, body.org_id, owner);
    await enforceLimit(db, body.org_id, "max_computers", claims.sub);
    if (body.provider === "casama-cloud" && !deps.env.CASAMA_CLOUD_KEY)
      throw new ApiError(
        409,
        "cloud_connect_off",
        "Cloud computers need a Cloud Connect key (CASAMA_CLOUD_URL and CASAMA_CLOUD_KEY)",
      );
    const inserted = await db
      .insert(computers)
      .values({
        orgId: body.org_id,
        kind: body.kind,
        ownerBotId: owner,
        name: body.name,
        profile: body.profile ?? "headless",
        provider: body.provider ?? "docker",
      })
      .returning()
      .catch((err: { code?: string; cause?: { code?: string } }) => {
        if ((err.code ?? err.cause?.code) === "23505")
          throw new ApiError(
            409,
            "team_computer_exists",
            "This workspace already has a team computer",
          );
        throw err;
      });
    milestone(db, claims.sub, "first_computer", body.org_id);
    return c.json((await present([inserted[0] as Row]))[0], 201);
  });

  app.openapi(routes.updateComputer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const current = await visible(claims, id);
    await canManage(claims, current.orgId, current.ownerBotId);
    if (body.max_desktops != null && current.kind !== "team")
      throw new ApiError(
        400,
        "team_computer_only",
        "Only team computers are shared, so only they have a desktop cap",
      );
    await db
      .update(computers)
      .set({
        ...(body.name ? { name: body.name } : {}),
        // A profile someone picks stays (D-178).
        ...(body.profile ? { profile: body.profile, desktopForTakeover: false } : {}),
        ...(body.max_desktops != null ? { maxDesktops: body.max_desktops } : {}),
      })
      .where(eq(computers.id, id));
    // A new profile needs a new container: restart it if it is running (files are kept).
    if (
      body.profile &&
      body.profile !== current.profile &&
      ["running", "idle"].includes(current.state)
    ) {
      await sandbox(async () => {
        await service().stop(id);
        await service().ensureRunning(id);
      });
    }
    return c.json(await reload(id), 200);
  });

  app.openapi(routes.deleteComputer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const current = await visible(claims, id);
    await canManage(claims, current.orgId, current.ownerBotId);
    if (deps.computers) await sandbox(() => service().remove(id));
    else await db.delete(computers).where(eq(computers.id, id));
    await db.execute(sql`insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id)
      values (${current.orgId}::uuid, 'user', ${claims.sub}::uuid, 'computer.deleted', 'computer', ${id}::uuid)`);
    return c.json({ deleted: id }, 200);
  });

  app.openapi(routes.computerTerminal, async () => {
    throw new ApiError(400, "websocket_required", "Connect to this endpoint with a WebSocket");
  });
}

/**
 * WebSocket terminal: client <-> API <-> supervisor <-> computerd. Keystrokes and the app's
 * presence beat keep the computer awake (D-195); an open terminal nobody uses does not.
 */
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
        const touch = throttledTouch(() => svc.touch(id));
        client.on("message", (data, binary) => {
          // Text frames are JSON control messages (resize) or the presence beat, which stays here.
          if (!binary && isPresence(data)) return touch();
          if (binary || !isResize(data)) touch();
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

/** computerd's terminal resize message, `{"type":"resize",...}`: not a person typing. */
function isResize(data: unknown) {
  try {
    return (JSON.parse(String(data)) as { type?: unknown }).type === "resize";
  } catch {
    return false;
  }
}

export type { ComputerRow };

const PDF_PREVIEW_TYPES = new Set([
  "doc",
  "docx",
  "odt",
  "rtf",
  "xls",
  "xlsx",
  "ods",
  "ppt",
  "pptx",
  "odp",
]);

/** Whether a file is an office document that previews as a PDF. */
export function pdfPreviewable(path: string) {
  const name = path.split("/").pop() ?? "";
  const dot = name.lastIndexOf(".");
  return dot > 0 && PDF_PREVIEW_TYPES.has(name.slice(dot + 1).toLowerCase());
}

const HOME = "/home/casama";

/** A files API path (relative to ~/workspace, `~/…`, or absolute) as an absolute path. */
export function absoluteComputerPath(path: string) {
  if (path.startsWith("/")) return path;
  if (path.startsWith("~/")) return `${HOME}/${path.slice(2)}`;
  return `${HOME}/workspace/${path.replace(/^\.\//, "")}`;
}

const shellQuote = (s: string) => `'${s.replace(/'/g, "'\\''")}'`;

/**
 * Converts one document with LibreOffice and prints the cached PDF's path. Exit 44: no such
 * file; 45: no LibreOffice here; 46: the conversion failed.
 */
export function pdfPreviewScript(file: string) {
  return [
    `f=${shellQuote(file)}`,
    `[ -f "$f" ] || exit 44`,
    "command -v soffice >/dev/null 2>&1 || exit 45",
    `key=$(printf '%s:%s' "$f" "$(stat -c %Y "$f")" | sha1sum | cut -c1-40)`,
    `d="$HOME/.cache/casama-previews"; mkdir -p "$d"`,
    `out="$d/$key.pdf"`,
    `if [ ! -s "$out" ]; then`,
    `  tmp=$(mktemp -d)`,
    `  timeout 60 soffice --headless --norestore "-env:UserInstallation=file:///tmp/casama-lo-profile" --convert-to pdf --outdir "$tmp" "$f" >/dev/null 2>&1 || { rm -rf "$tmp"; exit 46; }`,
    `  pdf=$(ls "$tmp"/*.pdf 2>/dev/null | head -n 1)`,
    `  [ -n "$pdf" ] || { rm -rf "$tmp"; exit 46; }`,
    `  mv "$pdf" "$out"; rm -rf "$tmp"`,
    "fi",
    `echo "$out"`,
  ].join("\n");
}
