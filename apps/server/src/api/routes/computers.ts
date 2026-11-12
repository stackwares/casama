import type { IncomingMessage, Server } from "node:http";
import type { Duplex } from "node:stream";
import {
  auditComputer,
  COMPUTER_RATES,
  type ComputerRow,
  type ComputerService,
  computerCostUsd,
  IDLE_SLEEP_CHOICES,
  milestone,
} from "@casama/agent";
import { routes } from "@casama/contracts";
import { type JwtClaims, schema, withUserSession } from "@casama/db";
import { type FileThumbnail, SandboxError } from "@casama/sandbox";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { desc, eq, inArray, sql } from "drizzle-orm";
import { WebSocket, WebSocketServer } from "ws";
import { enforceLimit } from "../../billing/limits.ts";
import { ApiError } from "../errors.ts";
import { isPresence, throttledTouch } from "../keep-awake.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";

const { computers, checkpoints, localDevices } = schema;
const user = (claims: JwtClaims) => ({ type: "user" as const, id: claims.sub });
type ComputerSize = { cpus?: number; memory_mb?: number; disk_gb?: number };
type ComputerHandle = Awaited<ReturnType<ComputerService["ensureRunning"]>>;
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
  idle_sleep_minutes: c.idleSleepMinutes ?? 5,
  operation: (c.operation as ComputerOperationOut | null) ?? null,
});

type ComputerOperationOut = {
  kind: "reset_system" | "erase";
  step: "saving" | "wiping" | "restarting" | "done" | "failed";
  checkpoint_id: string | null;
  error: string | null;
  started_at: string;
  finished_at: string | null;
};

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
      // A personal computer refuses anyone but its owner and the bots they allowed.
      if (err.status === 403)
        throw new ApiError(
          403,
          "computer_forbidden",
          "Only the person who owns this computer, and the bots they allowed, can open its files.",
        );
      // A personal computer whose app isn't connected: say what to do, not "try again shortly".
      if (err.code === "device_offline")
        throw new ApiError(
          409,
          "device_offline",
          'This computer is offline. Open the Casama app on it and turn on "Use this computer for bots".',
        );
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
  /** For reads the person makes from the app: a personal computer lets its owner through. */
  const viewerHandle = async (claims: JwtClaims, id: string) => {
    const h = await handle(claims, id);
    return h.forViewer?.(claims.sub) ?? h;
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
    const current = await visible(claims, id);
    await sandbox(() => service().stop(id));
    if (current.kind !== "local")
      await auditComputer(db, current.orgId, id, "computer.slept", user(claims), {
        reason: "user",
      });
    return c.json(await reload(id), 200);
  });

  app.openapi(routes.restartComputer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const current = await visible(claims, id);
    await sandbox(async () => {
      await service().stop(id);
      await service().ensureRunning(id);
    });
    await auditComputer(db, current.orgId, id, "computer.restarted", user(claims));
    return c.json(await reload(id), 200);
  });

  app.openapi(routes.listComputerFiles, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { path = "" } = c.req.valid("query");
    // On a personal computer the app reads as its owner (no bot is acting); cloud computers ignore it.
    const h = await viewerHandle(claims, id);
    const entries = await sandbox(() => h.listDir(path));
    return c.json({ path: path || "~/workspace", entries }, 200);
  });

  app.openapi(routes.downloadComputerFile, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { path } = c.req.valid("query");
    const h = await viewerHandle(claims, id);
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

  // Thumbnails (D-226). Cost rule: never start, wake or restore a computer for one, and don't
  // count it as activity. A computer that isn't already up (or a personal computer that isn't
  // connected) answers 409 at once and the app keeps its plain tile. Nothing is stored here.
  app.openapi(routes.computerFileThumbnail, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { path, size } = c.req.valid("query");
    await visible(claims, id);
    const unavailable = () =>
      new ApiError(409, "thumbnail_unavailable", "The computer isn't running, so no thumbnail");
    const running = await service()
      .ifRunning(id)
      .catch(() => null);
    if (!running?.thumbnail) throw unavailable();
    // A personal computer lets its owner see thumbnails with no bot involved; others are refused.
    const h = running.forViewer?.(claims.sub) ?? running;
    const px = Math.min(640, Math.max(128, Math.round(size ?? 480)));
    let t: FileThumbnail | null;
    try {
      t = (await h.thumbnail?.(path, px)) ?? null;
    } catch {
      throw unavailable();
    }
    if (!t) throw new ApiError(404, "no_thumbnail", "No thumbnail for this file");
    return c.body(Buffer.from(t.data), 200, {
      "content-type": /^image\/(jpeg|png)$/.test(t.contentType) ? t.contentType : "image/jpeg",
      "cache-control": "private, max-age=86400",
      ...(t.mtimeMs !== undefined ? { "x-file-mtime": String(Math.round(t.mtimeMs)) } : {}),
      ...(t.durationMs !== undefined ? { "x-duration-ms": String(Math.round(t.durationMs)) } : {}),
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
    const current = await visible(claims, id);
    const { checkpointId } = await sandbox(() => service().checkpoint(id, label, null));
    await auditComputer(db, current.orgId, id, "checkpoint.created", user(claims), { label });
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
    if (
      body.idle_sleep_minutes != null &&
      !(IDLE_SLEEP_CHOICES as readonly number[]).includes(body.idle_sleep_minutes)
    )
      throw new ApiError(400, "bad_sleep_timer", "The sleep timer is 5, 15, 30 or 60 minutes");
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
        // Five minutes is the default, kept as null so a later default change reaches it.
        ...(body.idle_sleep_minutes != null
          ? { idleSleepMinutes: body.idle_sleep_minutes === 5 ? null : body.idle_sleep_minutes }
          : {}),
      })
      .where(eq(computers.id, id));
    const changed = Object.keys(body).filter((k) => body[k as keyof typeof body] !== undefined);
    if (changed.length)
      await auditComputer(db, current.orgId, id, "computer.updated", user(claims), {
        fields: changed,
        ...(body.name ? { name: body.name } : {}),
        ...(body.profile ? { profile: body.profile } : {}),
        ...(body.idle_sleep_minutes != null ? { idle_sleep_minutes: body.idle_sleep_minutes } : {}),
      });
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

  // -------------------------------------------------------------------------------------------
  // Managing a computer (D-240). Looking (vitals, storage, programs) never wakes a computer or
  // counts as activity; doing something (clean up, reset, download) wakes it like any file action.

  /** The handle of a cloud computer that is already running, else 409; personal ones refuse. */
  const runningHandle = async (claims: JwtClaims, id: string) => {
    const current = await visible(claims, id);
    if (current.kind === "local")
      throw new ApiError(400, "personal_computer", "Personal computers are managed on the device");
    const h = await service()
      .ifRunning(id)
      .catch(() => null);
    if (!h) throw new ApiError(409, "computer_not_running", "The computer is asleep");
    return { h, current };
  };
  const cloudComputer = async (claims: JwtClaims, id: string) => {
    const current = await visible(claims, id);
    if (current.kind === "local")
      throw new ApiError(400, "personal_computer", "Personal computers are managed on the device");
    return current;
  };
  const run = async (h: { exec: ComputerHandle["exec"] }, script: string, timeoutMs = 30_000) => {
    const { collectExec } = await import("@casama/sandbox");
    return sandbox(() => collectExec(h.exec(script, { timeoutMs })));
  };

  app.openapi(routes.computerVitals, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { h, current } = await runningHandle(claims, id);
    const r = await run(h, VITALS_SCRIPT, 15_000);
    return c.json(parseVitals(r.stdout, current.size as ComputerSize), 200);
  });

  app.openapi(routes.computerStorage, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { h, current } = await runningHandle(claims, id);
    const r = await run(h, STORAGE_SCRIPT, 45_000);
    return c.json(parseStorage(r.stdout, current.size as ComputerSize), 200);
  });

  app.openapi(routes.cleanComputerStorage, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const current = await cloudComputer(claims, id);
    const h = await sandbox(() => service().ensureRunning(id));
    const before = parseStorage(
      (await run(h, STORAGE_SCRIPT, 45_000)).stdout,
      current.size as ComputerSize,
    );
    await run(h, CLEAN_SCRIPT, 60_000);
    const storage = parseStorage(
      (await run(h, STORAGE_SCRIPT, 45_000)).stdout,
      current.size as ComputerSize,
    );
    const freed = Math.max(0, before.used_bytes - storage.used_bytes);
    await auditComputer(db, current.orgId, id, "computer.storage_cleaned", user(claims), {
      freed_bytes: freed,
    });
    return c.json({ freed_bytes: freed, storage }, 200);
  });

  app.openapi(routes.listComputerProcesses, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { h } = await runningHandle(claims, id);
    const r = await run(h, PROCESSES_SCRIPT, 15_000);
    return c.json({ items: parseProcesses(r.stdout) }, 200);
  });

  app.openapi(routes.stopComputerProcess, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id, pid } = c.req.valid("param");
    const { h, current } = await runningHandle(claims, id);
    const r = await run(h, stopProcessScript(pid), 20_000);
    if (r.code === 44)
      throw new ApiError(404, "process_not_found", "That program has already stopped");
    if (r.code === 45)
      throw new ApiError(
        400,
        "system_process",
        "That's part of the computer itself and can't be stopped",
      );
    if (r.code !== 0) throw new ApiError(503, "computer_unavailable", "Couldn't stop that program");
    await auditComputer(db, current.orgId, id, "computer.process_stopped", user(claims), {
      pid,
      name: r.stdout.trim().split("\n").pop()?.slice(0, 80) ?? null,
    });
    return c.json({ stopped: pid }, 200);
  });

  app.openapi(routes.resetComputer, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { mode, checkpoint = true } = c.req.valid("json");
    const current = await cloudComputer(claims, id);
    await canManage(claims, current.orgId, current.ownerBotId);
    const svc = service();
    if (!(await svc.claimReset(id, mode, checkpoint)))
      throw new ApiError(409, "reset_in_progress", "This computer is already resetting");
    await auditComputer(
      db,
      current.orgId,
      id,
      mode === "erase" ? "computer.erased" : "computer.reset",
      user(claims),
      { checkpoint },
    );
    // Runs on after the response (about a minute): the app follows `operation`.
    const done = svc.reset(id, mode, { checkpoint });
    deps.onBackgroundTask?.(done);
    return c.json(await reload(id), 202);
  });

  app.openapi(routes.computerUsage, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const current = await visible(claims, id);
    const rows = await db.execute<{ d: string; s: string; cost: string; m: string }>(sql`
      select to_char(date_trunc('day', created_at at time zone 'utc'), 'YYYY-MM-DD') as d,
        sum(quantity)::text as s, sum(cost_usd)::text as cost,
        to_char(date_trunc('month', now() at time zone 'utc'), 'YYYY-MM-DD') as m
      from public.usage_ledger
      where computer_id = ${id}::uuid and kind = 'computer_seconds'
        and created_at >= date_trunc('month', now() at time zone 'utc') at time zone 'utc'
      group by 1`);
    const now = new Date();
    const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    const days = new Map<string, number>();
    for (let d = new Date(monthStart); d <= now; d.setUTCDate(d.getUTCDate() + 1))
      days.set(d.toISOString().slice(0, 10), 0);
    let seconds = 0;
    let cost = 0;
    for (const r of rows) {
      days.set(r.d, (days.get(r.d) ?? 0) + Number(r.s));
      seconds += Number(r.s);
      cost += Number(r.cost);
    }
    // The time it has been on now is not in the ledger until it sleeps.
    if (current.runningSince && current.kind !== "local") {
      const from = Math.max(new Date(current.runningSince).getTime(), monthStart.getTime());
      const live = Math.max(0, Math.round((now.getTime() - from) / 1000));
      const today = now.toISOString().slice(0, 10);
      days.set(today, (days.get(today) ?? 0) + live);
      seconds += live;
      cost += computerCostUsd(
        current.provider,
        current.size as ComputerSize,
        live,
        deps.computers?.rates ?? COMPUTER_RATES,
      );
    }
    return c.json(
      {
        month_start: monthStart.toISOString().slice(0, 10),
        seconds: Math.round(seconds),
        cost_usd: Math.round(cost * 10_000) / 10_000,
        days: [...days].map(([date, s]) => ({ date, seconds: Math.round(s) })),
      },
      200,
    );
  });

  app.openapi(routes.computerHistory, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await visible(claims, id);
    const rows = await db.execute<{
      id: string;
      action: string;
      actor_type: "user" | "bot" | "system";
      actor_id: string | null;
      actor_name: string | null;
      metadata: Record<string, unknown>;
      created_at: Date | string;
    }>(sql`
      select a.id, a.action, a.actor_type, a.actor_id, a.metadata, a.created_at,
        case a.actor_type
          when 'user' then (select p.display_name from public.profiles p where p.user_id = a.actor_id)
          when 'bot' then (select b.name from public.bots b where b.id = a.actor_id)
        end as actor_name
      from public.audit_log a
      where a.target_id = ${id}::uuid and a.target_type = 'computer'
      order by a.created_at desc limit 50`);
    return c.json(
      {
        items: rows.map((r) => ({
          id: r.id,
          action: r.action,
          actor_type: r.actor_type,
          actor_id: r.actor_id,
          actor_name: r.actor_name,
          metadata: r.metadata ?? {},
          created_at: iso(r.created_at),
        })),
      },
      200,
    );
  });

  app.openapi(routes.computerBots, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await visible(claims, id);
    // The same choice as ComputerService.forBot: its default, else its private computer, else
    // the team computer. Read as the person, so only bots they can see are listed.
    const rows = await withUserSession(db, claims, (tx) =>
      tx.execute<{ bot_id: string; name: string; last_active_at: Date | string | null }>(sql`
        select b.id as bot_id, b.name,
          (select max(r.created_at) from public.runs r where r.bot_id = b.id) as last_active_at
        from public.bots b
        join public.computers c on c.id = ${id}::uuid and c.org_id = b.org_id
        where b.archived_at is null and (
          b.default_computer_id = c.id
          or (b.default_computer_id is null and (
            c.owner_bot_id = b.id
            or (c.kind = 'team' and not exists (
              select 1 from public.computers p where p.owner_bot_id = b.id)))))
        order by last_active_at desc nulls last, b.name`),
    );
    return c.json(
      {
        items: rows.map((r) => ({
          bot_id: r.bot_id,
          name: r.name,
          last_active_at: r.last_active_at ? iso(r.last_active_at) : null,
        })),
      },
      200,
    );
  });

  app.openapi(routes.downloadComputerArchive, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const current = await cloudComputer(claims, id);
    const h = await sandbox(() => service().ensureRunning(id));
    const r = await run(h, ARCHIVE_SCRIPT, 300_000);
    if (r.code === 44)
      throw new ApiError(422, "nothing_to_download", "There are no files on this computer yet");
    const size = Number(r.stdout.trim().split("\n").pop());
    if (r.code !== 0 || !Number.isFinite(size))
      throw new ApiError(503, "computer_unavailable", "Couldn't make the zip. Try again shortly.");
    if (size > MAX_ARCHIVE) {
      await run(h, `rm -f ${ARCHIVE_PATH}`);
      throw new ApiError(413, "archive_too_large", "Over 1 GB: download folders one at a time");
    }
    const data = await sandbox(() => h.readFile(ARCHIVE_PATH));
    await run(h, `rm -f ${ARCHIVE_PATH}`).catch(() => {});
    const name = `${current.name.replace(/[^\w.-]+/g, "-").replace(/^-|-$/g, "") || "computer"}-files.zip`;
    return c.body(Buffer.from(data), 200, {
      "content-type": "application/zip",
      "content-disposition": `attachment; filename="${name}"`,
    }) as never;
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

// -------------------------------------------------------------------------------------------
// Managing a computer (D-240): small shell scripts run on the computer, and their parsers.

const GIB = 1024 ** 3;
const MIB = 1024 ** 2;
const MAX_ARCHIVE = GIB;
const ARCHIVE_PATH = "/tmp/casama-files.zip";

/** key=value lines → a map. */
function kv(stdout: string) {
  const m = new Map<string, string>();
  for (const line of stdout.split("\n")) {
    const i = line.indexOf("=");
    if (i > 0) m.set(line.slice(0, i).trim(), line.slice(i + 1).trim());
  }
  return m;
}
const num = (v: string | undefined) => {
  const n = Number(v);
  return Number.isFinite(n) && n >= 0 ? n : 0;
};

/**
 * CPU over 0.3 s and memory from the container's cgroup; disk is the home folder's size, cached
 * for a minute in /tmp and refreshed in the background so looking stays cheap.
 */
export const VITALS_SCRIPT = [
  "cg=/sys/fs/cgroup",
  "cpu() { if [ -r $cg/cpu.stat ]; then awk '/^usage_usec/{print $2}' $cg/cpu.stat; else awk '/^cpu /{printf \"%d\\n\", ($2+$3+$4+$7+$8)*10000}' /proc/stat; fi; }",
  "a=$(cpu); sleep 0.3; b=$(cpu)",
  'echo "cpu_usec=$(( ${b:-0} - ${a:-0} ))"',
  'echo "cpu_max=$(cat $cg/cpu.max 2>/dev/null)"',
  'echo "mem=$(cat $cg/memory.current 2>/dev/null)"',
  "echo \"mem_inactive=$(awk '/^inactive_file /{print $2}' $cg/memory.stat 2>/dev/null)\"",
  'echo "mem_max=$(cat $cg/memory.max 2>/dev/null)"',
  'f=/tmp/.casama-du; now=$(date +%s); disk=""; t=0',
  "[ -f $f ] && read disk t < $f",
  'if [ -z "$disk" ]; then disk=$(timeout 8 du -sb "$HOME" 2>/dev/null | cut -f1); echo "$disk $now" > $f',
  `elif [ $((now - \${t:-0})) -gt 60 ]; then (nohup sh -c 'd=$(du -sb "$HOME" 2>/dev/null | cut -f1); echo "$d $(date +%s)" > /tmp/.casama-du.n && mv /tmp/.casama-du.n /tmp/.casama-du' >/dev/null 2>&1 &); fi`,
  'echo "disk=${disk:-0}"',
].join("\n");

export function parseVitals(stdout: string, size: ComputerSize) {
  const v = kv(stdout);
  const [quota, period] = (v.get("cpu_max") ?? "").split(/\s+/);
  const cores =
    quota && quota !== "max" && num(period) > 0 ? num(quota) / num(period) : (size.cpus ?? 1);
  const cpu = (num(v.get("cpu_usec")) / (300_000 * Math.max(cores, 0.1))) * 100;
  const memMax = v.get("mem_max");
  const memLimit =
    memMax && memMax !== "max" && num(memMax) > 0 ? num(memMax) : (size.memory_mb ?? 1024) * MIB;
  return {
    cpu_percent: Math.round(Math.min(100, Math.max(0, cpu)) * 10) / 10,
    memory_used_bytes: Math.round(Math.max(0, num(v.get("mem")) - num(v.get("mem_inactive")))),
    memory_limit_bytes: Math.round(memLimit),
    disk_used_bytes: Math.round(num(v.get("disk"))),
    disk_limit_bytes: Math.round((size.disk_gb ?? 10) * GIB),
    at: new Date().toISOString(),
  };
}

const BROWSER_CACHES =
  "find .browser-profile -maxdepth 3 -type d \\( -name Cache -o -name 'Code Cache' -o -name GPUCache \\) -prune";

/** Sizes of the home folder's parts. Apps: what was installed into it; caches: safe to delete. */
export const STORAGE_SCRIPT = [
  'cd "$HOME" || exit 3',
  'sz() { s=0; for d in "$@"; do if [ -e "$d" ]; then x=$(du -sb "$d" 2>/dev/null | cut -f1); s=$((s + ${x:-0})); fi; done; echo $s; }',
  'echo "total=$(sz .)"',
  'echo "files=$(sz workspace)"',
  'echo "apps=$(sz .npm-global .local .cargo .rustup go .deno .nvm .pyenv .bun)"',
  'echo "caches=$(sz .cache .npm .yarn .pnpm-store)"',
  'echo "browser=$(sz .browser-profile)"',
  `echo "browser_cache=$(${BROWSER_CACHES} -exec du -sbc {} + 2>/dev/null | awk '$2 == "total" {s += $1} END {print s + 0}')"`,
].join("\n");

export function parseStorage(stdout: string, size: ComputerSize) {
  const v = kv(stdout);
  const total = num(v.get("total"));
  const parts = {
    files: num(v.get("files")),
    apps: num(v.get("apps")),
    caches: num(v.get("caches")),
    browser: num(v.get("browser")),
  };
  const known = parts.files + parts.apps + parts.caches + parts.browser;
  return {
    used_bytes: Math.round(total),
    limit_bytes: Math.round((size.disk_gb ?? 10) * GIB),
    categories: [
      { id: "files" as const, bytes: Math.round(parts.files) },
      { id: "apps" as const, bytes: Math.round(parts.apps) },
      { id: "caches" as const, bytes: Math.round(parts.caches) },
      { id: "browser" as const, bytes: Math.round(parts.browser) },
      { id: "other" as const, bytes: Math.round(Math.max(0, total - known)) },
    ],
    cleanable_bytes: Math.round(parts.caches + num(v.get("browser_cache"))),
  };
}

/** Caches only: never ~/workspace, installed tools, settings or the browser's sign-ins. */
export const CLEAN_SCRIPT = [
  'cd "$HOME" || exit 3',
  "rm -rf .cache/* .cache/.[!.]* .npm/_cacache .yarn/cache .pnpm-store 2>/dev/null",
  `${BROWSER_CACHES} -exec rm -rf {} + 2>/dev/null`,
  "rm -f /tmp/.casama-du",
  "exit 0",
].join("\n");

/** Every process but this script's own, busiest first; the first line is our user id. */
export const PROCESSES_SCRIPT = [
  'echo "uid=$(id -u)"',
  "self=$$",
  "ps -eo pid=,ppid=,etimes=,pcpu=,rss=,uid=,comm=,args= --sort=-pcpu 2>/dev/null | awk -v self=$self '$1 != self && $2 != self' | head -200",
].join("\n");

/** Parts of the computer itself: listed as system, never stopped. */
const SYSTEM_PROCESSES = new Set([
  "computerd",
  "tini",
  "dumb-init",
  "Xvfb",
  "Xorg",
  "openbox",
  "tint2",
  "neko",
  "pulseaudio",
  "pipewire",
  "dbus-daemon",
  "dbus-launch",
  "supervisord",
  "x11vnc",
  "desktop-start.s",
]);

const isSystem = (p: { pid: number; uid: number; name: string; command: string }, uid: number) =>
  p.pid === 1 ||
  p.uid !== uid ||
  SYSTEM_PROCESSES.has(p.name) ||
  p.command.includes("casama-proxy-relay") ||
  p.command.includes("desktop-start.sh");

/**
 * Parses ps output. A process whose parent has the same name (Chrome's helpers, worker pools) is
 * folded into that parent, so a browser shows once with its total CPU and memory.
 */
export function parseProcesses(stdout: string) {
  const lines = stdout.split("\n");
  const uid = num(kv(lines[0] ?? "").get("uid"));
  type P = {
    pid: number;
    ppid: number;
    elapsed: number;
    cpu: number;
    rss: number;
    uid: number;
    name: string;
    command: string;
  };
  const all: P[] = [];
  for (const line of lines.slice(1)) {
    const m = line
      .trim()
      .match(/^(\d+)\s+(\d+)\s+(\d+)\s+([\d.]+)\s+(\d+)\s+(\d+)\s+(\S+)\s*(.*)$/);
    if (!m) continue;
    all.push({
      pid: Number(m[1]),
      ppid: Number(m[2]),
      elapsed: Number(m[3]),
      cpu: Number(m[4]),
      rss: Number(m[5]) * 1024,
      uid: Number(m[6]),
      name: m[7] as string,
      command: (m[8] || m[7]) as string,
    });
  }
  const byPid = new Map(all.map((p) => [p.pid, p]));
  const rootOf = (p: P): P => {
    let r = p;
    for (let i = 0; i < 20; i++) {
      const parent = byPid.get(r.ppid);
      if (!parent || parent.name !== r.name) break;
      r = parent;
    }
    return r;
  };
  const groups = new Map<number, P & { root: P }>();
  for (const p of all) {
    const root = rootOf(p);
    const g = groups.get(root.pid) ?? { ...root, cpu: 0, rss: 0, root };
    g.cpu += p.cpu;
    g.rss += p.rss;
    groups.set(root.pid, g);
  }
  return [...groups.values()]
    .map((g) => ({
      pid: g.pid,
      name: g.name,
      command: g.command.slice(0, 300),
      cpu_percent: Math.round(g.cpu * 10) / 10,
      memory_bytes: Math.round(g.rss),
      elapsed_seconds: g.elapsed,
      system: isSystem(g, uid),
    }))
    .sort((a, b) => b.cpu_percent - a.cpu_percent || b.memory_bytes - a.memory_bytes);
}

/**
 * Stops one process and its children: TERM, then KILL after 3 s. Prints its name. Exit 44: not
 * running; 45: part of the computer itself.
 */
export function stopProcessScript(pid: number) {
  const p = Math.trunc(pid);
  const system = [...SYSTEM_PROCESSES].join("|");
  return [
    `p=${p}`,
    '[ "$p" -gt 1 ] && [ -d /proc/$p ] || exit 44',
    'c=$(cat /proc/$p/comm 2>/dev/null); a=$(tr "\\0" " " < /proc/$p/cmdline 2>/dev/null)',
    `case "$c" in ${system}) exit 45;; esac`,
    'case "$a" in *casama-proxy-relay*|*desktop-start.sh*) exit 45;; esac',
    '[ "$(stat -c %u /proc/$p)" = "$(id -u)" ] || exit 45',
    "kids=$(pgrep -P $p 2>/dev/null)",
    "kill -TERM $p $kids 2>/dev/null",
    "for i in 1 2 3 4 5 6; do [ -d /proc/$p ] || break; sleep 0.5; done",
    "kill -KILL $p $kids 2>/dev/null",
    'echo "$c"',
  ].join("\n");
}

/** Zips ~/workspace into /tmp and prints the zip's size. Exit 44: no files. */
export const ARCHIVE_SCRIPT = [
  'cd "$HOME/workspace" 2>/dev/null || exit 44',
  '[ -n "$(ls -A . 2>/dev/null)" ] || exit 44',
  `rm -f ${ARCHIVE_PATH}`,
  `zip -qry ${ARCHIVE_PATH} . -x '.casama-restore-*' || exit 46`,
  `stat -c %s ${ARCHIVE_PATH}`,
].join("\n");
