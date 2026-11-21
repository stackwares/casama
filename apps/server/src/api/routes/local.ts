/**
 * Local computer companion (Phase 6, D-066): pairing, the device WebSocket, and the internal tunnel
 * the worker uses to reach a device's embedded computerd.
 *
 * Tunnel protocol (JSON text frames):
 *   API -> device  {type:"request", id, method, path, headers, body?: base64, activity?}
 *   device -> API  {type:"response", id, status, headers} {type:"chunk", id, data: base64}* {type:"end", id}
 *                  {type:"error", id, message}
 *   device -> API  {type:"hello", platform, version}   API -> device {type:"ready", device_id}
 * The connect request may carry x-casama-os ("macOS 26.2"), kept for the computer card (D-227).
 */
import { createHash, createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import type { IncomingMessage, Server } from "node:http";
import type { Duplex } from "node:stream";
import { actingUserOf } from "@casama/agent";
import { BrowserCallBody, type BrowserResult, routes } from "@casama/contracts";
import { type Database, type JwtClaims, schema, withUserSession } from "@casama/db";
import {
  APP_BROWSER_CHECKED,
  APP_BROWSER_FOCUS_S,
  APP_BROWSER_UNSUPPORTED,
  type AppBrowserSystem,
  appBrowserFor,
  browsable,
  CODING_TEST_TASK,
  checkAppBrowserSettings,
  checkOwnCodingAgent,
  cleanSitePattern,
  isCasamaAddress,
  OWN_AGENT_PREFIX,
  ownCodingAgentSpec,
  PREALLOWED_CODING_AGENTS,
  renderCodingCommand,
  summarizeAgentOutput,
} from "@casama/domain";
import type { OpenAPIHono } from "@hono/zod-openapi";
import { eq, sql } from "drizzle-orm";
import type { Hono } from "hono";
import { stream } from "hono/streaming";
import { type WebSocket, WebSocketServer } from "ws";
import {
  appBrowserNumbers,
  getAppBrowserSettings,
  rememberRead,
  type StepFacts,
  setAppBrowserSettings,
  stepVerdict,
} from "../../services/app-browser.ts";
import { syncCompanionPluginsQuietly } from "../../services/companion-plugins.ts";
import { galleryCodingAgents } from "../../services/gallery.ts";
import { ApiError } from "../errors.ts";
import type { AppDeps, AppEnv } from "../types.ts";
import { iso } from "../util.ts";
import { integrationOut } from "./autonomy.ts";

const { localDevices, computers } = schema;
const REQUEST_TIMEOUT_MS = 15 * 60 * 1000;
/**
 * Local MCP calls and commands may run up to two hours: MCP servers have their own timeout (D-096)
 * and computerd stops a command at its timeout_ms (coding agents allow 120 minutes). The margin
 * lets that own timeout answer first, so the tunnel doesn't cut a long command off midway.
 */
const LONG_TIMEOUT_MS = 2 * 60 * 60 * 1000 + 5 * 60 * 1000;
/** How often the API pings each connected device; one missed pong drops it. */
const PING_MS = 25_000;
/** JSON-RPC methods that may reach a local MCP server without a run (listing its tools). */
const MCP_LIST_METHODS = new Set(["initialize", "notifications/initialized", "tools/list"]);

/**
 * A browser-only device (Casama for Chrome, D-323) has no computer: its socket is kept under this key
 * instead of a computer id.
 */
export const browserKey = (deviceId: string) => `browser:${deviceId}`;
/** How long a browser call may take: page loads, waiting for the person to answer or hand back. */
const BROWSER_TIMEOUT_MS = 10 * 60 * 1000;

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
    // A device that went away without closing (sleep, a network change) would stay "online" here
    // and every call would wait for its timeout: ping it, and drop it when a pong doesn't come back.
    let alive = true;
    ws.on("pong", () => {
      alive = true;
    });
    const heartbeat = setInterval(() => {
      if (!alive) return ws.terminate();
      alive = false;
      ws.ping();
    }, PING_MS);
    ws.on("close", () => {
      clearInterval(heartbeat);
      if (this.sockets.get(computerId)?.ws === ws) this.sockets.delete(computerId);
      for (const p of entry.pending.values()) p.onError("The computer disconnected");
      entry.pending.clear();
    });
  }

  /** Closes every device's socket with "service restart" (1012), so the apps redial right away. */
  closeAll() {
    for (const s of this.sockets.values()) s.ws.close(1012, "server restarting");
  }

  online(computerId: string) {
    return this.sockets.has(computerId);
  }

  /** A one-way message to the device's app (D-376: a permission card's button). False if offline. */
  notify(computerId: string, message: Record<string, unknown>) {
    const entry = this.sockets.get(computerId);
    if (!entry || entry.ws.readyState !== entry.ws.OPEN) return false;
    entry.ws.send(JSON.stringify(message));
    return true;
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
      req.path.startsWith("/mcp/") || req.path === "/exec"
        ? LONG_TIMEOUT_MS
        : req.path.startsWith("/browser/")
          ? BROWSER_TIMEOUT_MS
          : REQUEST_TIMEOUT_MS,
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

/**
 * Runs one command through a device's companion and collects what it printed (the Test button
 * for coding agents, D-371). The device itself still checks that commands are allowed.
 */
export function execOnDevice(
  registry: DeviceRegistry,
  computerId: string,
  req: { cmd: string; cwd?: string; timeoutMs: number },
): Promise<{ out: string; code: number; timedOut: boolean }> {
  return new Promise((resolve, reject) => {
    let status = 0;
    const chunks: Buffer[] = [];
    let settled = false;
    const finish = (f: () => void) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      f();
    };
    const cancel = registry.request(
      computerId,
      {
        method: "POST",
        path: "/exec",
        headers: { "content-type": "application/json" },
        body: Buffer.from(
          JSON.stringify({ cmd: req.cmd, cwd: req.cwd, timeout_ms: req.timeoutMs }),
        ),
      },
      {
        onResponse: (s) => {
          status = s;
        },
        onChunk: (b) => chunks.push(b),
        onEnd: () =>
          finish(() => {
            const text = Buffer.concat(chunks).toString("utf8");
            if (status !== 200) {
              let message = "The computer refused the command";
              try {
                message = (JSON.parse(text) as { message?: string }).message ?? message;
              } catch {}
              return reject(new ApiError(409, "device_refused", message));
            }
            let out = "";
            let code = -1;
            let timedOut = false;
            for (const line of text.split("\n")) {
              if (!line.trim()) continue;
              try {
                const m = JSON.parse(line) as {
                  type: string;
                  data?: string;
                  code?: number;
                  timed_out?: boolean;
                };
                if ((m.type === "stdout" || m.type === "stderr") && m.data) out += m.data;
                else if (m.type === "exit") {
                  code = m.code ?? -1;
                  timedOut = m.timed_out === true;
                }
              } catch {}
            }
            resolve({ out, code, timedOut });
          }),
        onError: (m) => finish(() => reject(new ApiError(502, "device_error", m))),
      },
    );
    // computerd stops the command at its timeout; this only covers a device that goes silent.
    const timer = setTimeout(
      () =>
        finish(() => {
          cancel();
          reject(new ApiError(504, "device_timeout", "The computer did not answer in time"));
        }),
      req.timeoutMs + 30_000,
    );
  });
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
  /** Columns newer than the generated schema: the phone browser's system and chat-focus id. */
  const extrasOf = async (ids: string[]) => {
    const m = new Map<string, { system: AppBrowserSystem | null; client_id: string | null }>();
    if (!ids.length) return m;
    const rows = await db.execute<{
      id: string;
      system: AppBrowserSystem | null;
      client_id: string | null;
    }>(sql`select id, system, client_id from public.local_devices
           where id = any(${`{${ids.join(",")}}`}::uuid[])`);
    for (const r of rows) m.set(r.id, { system: r.system, client_id: r.client_id });
    return m;
  };
  /** Whether [userId] may use the phone app's browser in [orgId] on [system]. */
  const appBrowserAllowed = async (
    userId: string,
    orgId: string,
    system: AppBrowserSystem | null,
  ) => {
    const [o] = await db.execute<{ app_browser: boolean }>(
      sql`select app_browser from public.organizations where id = ${orgId}::uuid`,
    );
    return appBrowserFor(await getAppBrowserSettings(db), {
      userId,
      system,
      workspaceOn: !!o?.app_browser,
    });
  };
  const out = (d: DeviceRow, system?: AppBrowserSystem | null) => ({
    ...(d.platform === "app" ? { system: system ?? null } : {}),
    id: d.id,
    org_id: d.orgId,
    user_id: d.userId,
    computer_id: d.computerId,
    name: d.name,
    platform: d.platform as "macos",
    os_version: d.osVersion ?? null,
    capabilities: caps(d.capabilities),
    allowed_roots: d.allowedRoots,
    allowed_bot_ids: d.allowedBotIds,
    allowed_sites: d.allowedSites ?? [],
    blocked_sites: d.blockedSites ?? [],
    allowed_kinds: (d.allowedKinds ?? []) as Array<"banking">,
    allowed_coding_agents: d.allowedCodingAgents ?? [],
    enabled: d.enabled,
    online: !!registry?.online(d.computerId ?? browserKey(d.id)),
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
    // A browser (Casama for Chrome): no computer, browser tools only (D-323 C1).
    if (body.platform === "chrome") {
      const [o] = await db.execute<{ chrome_extension: boolean; chrome_act: boolean }>(
        sql`select chrome_extension, chrome_act from public.organizations where id = ${body.org_id}::uuid`,
      );
      if (!o?.chrome_extension || !o.chrome_act)
        throw new ApiError(403, "act_off", "This workspace doesn't let bots use members' browsers");
      const [d] = await db
        .insert(localDevices)
        .values({
          orgId: body.org_id,
          userId: claims.sub,
          name: body.name,
          platform: "chrome",
          tokenHash: hashDeviceToken(token),
          capabilities: { browser: true },
          allowedRoots: [],
          allowedBotIds: [],
          allowedSites: [],
          blockedSites: [],
          allowedKinds: [],
        })
        .returning();
      return c.json({ ...out(d as DeviceRow), token }, 201);
    }
    // The browser inside the phone app: no computer either, and one per app install.
    if (body.platform === "app") {
      if (!registry)
        throw new ApiError(403, "unavailable", "This server has no device connections");
      if (!body.system || !body.client_id)
        throw new ApiError(400, "bad_request", "A phone browser needs its system and client id");
      const may = await appBrowserAllowed(claims.sub, body.org_id, body.system);
      if (!may.available)
        throw new ApiError(
          403,
          "app_browser_off",
          `The phone browser isn't available (${may.reason})`,
        );
      // Pairing again from the same install replaces the token and keeps its bots and sites.
      const [old] = await db.execute<{ id: string }>(sql`
        select id from public.local_devices where platform = 'app' and org_id = ${body.org_id}::uuid
          and user_id = ${claims.sub}::uuid and client_id = ${body.client_id}`);
      let d: DeviceRow | undefined;
      if (old) {
        registry.disconnect(old.id);
        [d] = await db
          .update(localDevices)
          .set({ name: body.name, tokenHash: hashDeviceToken(token), enabled: true })
          .where(eq(localDevices.id, old.id))
          .returning();
      } else {
        [d] = await db
          .insert(localDevices)
          .values({
            orgId: body.org_id,
            userId: claims.sub,
            name: body.name,
            platform: "app",
            tokenHash: hashDeviceToken(token),
            capabilities: { browser: true },
            allowedRoots: [],
            allowedBotIds: [],
            allowedSites: [],
            blockedSites: [],
            allowedKinds: [],
          })
          .returning();
      }
      await db.execute(sql`
        update public.local_devices set system = ${body.system}, client_id = ${body.client_id}
        where id = ${(d as DeviceRow).id}::uuid`);
      return c.json({ ...out(d as DeviceRow, body.system), token }, 201);
    }
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
    const { org_id, all_platforms } = c.req.valid("query");
    const all = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(localDevices)
        .where(eq(localDevices.orgId, org_id))
        .orderBy(localDevices.createdAt),
    );
    // Apps from before the phone browser read `platform` strictly: one "app" row would break their
    // whole list, so it is left out unless the caller asks for it.
    const rows = all_platforms === "true" ? all : all.filter((d) => d.platform !== "app");
    const extras = await extrasOf(rows.filter((d) => d.platform === "app").map((d) => d.id));
    return c.json({ items: rows.map((d) => out(d, extras.get(d.id)?.system)) }, 200);
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
    const sites = (list: string[] | undefined) => {
      if (!list) return undefined;
      const out = new Set<string>();
      for (const raw of list) {
        const p = cleanSitePattern(raw);
        if (!p) throw new ApiError(400, "bad_site", `"${raw.slice(0, 80)}" isn't a site address`);
        out.add(p);
      }
      return [...out];
    };
    const allowedSites = sites(body.allowed_sites);
    const blockedSites = sites(body.blocked_sites);
    const [updated] = await db
      .update(localDevices)
      .set({
        ...(allowedSites ? { allowedSites } : {}),
        ...(blockedSites ? { blockedSites } : {}),
        ...(body.allowed_kinds ? { allowedKinds: [...new Set(body.allowed_kinds)] } : {}),
        // One Allow per agent on this computer (D-370); only the device's owner gets here.
        ...(body.allowed_coding_agents
          ? { allowedCodingAgents: [...new Set(body.allowed_coding_agents)] }
          : {}),
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
    return c.json(out(updated as DeviceRow, (await extrasOf([id])).get(id)?.system), 200);
  });

  // --- The browser inside the phone app (docs/PHONE-BROWSER-PLAN.md) -----------------------------

  app.openapi(routes.getAppBrowser, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const q = c.req.valid("query");
    const [m] = await withUserSession(db, claims, (tx) =>
      tx.execute<{ ok: boolean }>(sql`select public.is_member(${q.org_id}::uuid) as ok`),
    );
    if (!m?.ok) throw new ApiError(403, "forbidden", "You are not a member of this workspace");
    const [row] = await db.execute<{ id: string }>(sql`
      select id from public.local_devices where platform = 'app' and org_id = ${q.org_id}::uuid
        and user_id = ${claims.sub}::uuid and client_id = ${q.client_id}`);
    const [d] = row ? await db.select().from(localDevices).where(eq(localDevices.id, row.id)) : [];
    const may = registry
      ? await appBrowserAllowed(claims.sub, q.org_id, q.system)
      : ({ available: false, reason: "unavailable" } as const);
    return c.json(
      {
        available: may.available,
        reason: may.available ? null : may.reason,
        device: d ? out(d, q.system) : null,
      },
      200,
    );
  });

  /** Instance owners: INSTANCE_ADMIN_EMAILS, or the first user to sign up when unset (as in Admin). */
  const requireOwner = async (claims: JwtClaims) => {
    const allow = (deps.env.INSTANCE_ADMIN_EMAILS ?? "")
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean);
    const [u] = await db.execute<{ email: string | null; first: boolean }>(sql`
      select u.email, u.id = (select id from auth.users order by created_at limit 1) as first
      from auth.users u where u.id = ${claims.sub}::uuid`);
    const ok = allow.length ? allow.includes((u?.email ?? "").toLowerCase()) : !!u?.first;
    if (!ok)
      throw new ApiError(403, "not_instance_owner", "Only the instance owner can change this");
  };

  app.openapi(routes.adminAppBrowser, async (c) => {
    await requireOwner(requireClaims(c.get("claims")));
    const { days } = c.req.valid("query");
    return c.json(
      {
        settings: await getAppBrowserSettings(db),
        numbers: await appBrowserNumbers(db, days ?? 14),
      },
      200,
    );
  });

  app.openapi(routes.saveAppBrowser, async (c) => {
    const claims = requireClaims(c.get("claims"));
    await requireOwner(claims);
    const { settings, errors } = checkAppBrowserSettings(c.req.valid("json"));
    if (!settings) throw new ApiError(400, "validation_failed", errors.join("; "));
    await setAppBrowserSettings(db, settings);
    deps.logger.info("phone browser stage changed", { by: claims.sub, stage: settings.stage });
    // Going back a stage takes effect at once: phones that may no longer connect are dropped.
    if (registry) {
      const rows = await db.execute<{
        id: string;
        user_id: string;
        system: AppBrowserSystem | null;
        app_browser: boolean;
      }>(sql`select d.id, d.user_id, d.system, o.app_browser from public.local_devices d
             join public.organizations o on o.id = d.org_id where d.platform = 'app'`);
      for (const r of rows)
        if (
          !appBrowserFor(settings, {
            userId: r.user_id,
            system: r.system,
            workspaceOn: r.app_browser,
          }).available
        )
          registry.disconnect(r.id);
    }
    return c.json({ settings, numbers: await appBrowserNumbers(db, 14) }, 200);
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
        where kind = 'local_mcp' and config->>'device_id' = ${d.id} and plugin_id is null`);
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
          // How it signs in (D-363); the token or sign-in itself stays on the computer.
          auth: s.auth ?? "none",
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
        and plugin_id is null
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

  // Coding agents (D-370): what bots can hand coding tasks to, for the desktop app's scan.
  app.openapi(routes.listCodingAgents, async (c) => {
    requireClaims(c.get("claims"));
    const agents = await galleryCodingAgents(deps.env);
    return c.json(
      {
        items: agents.map((a) => ({
          id: a.id,
          label: a.label,
          bin: a.bin,
          where: a.where,
          needs_folder: a.needsFolder,
          hint: a.hint,
          preallowed: PREALLOWED_CODING_AGENTS.includes(a.id),
        })),
      },
      200,
    );
  });

  // People's own agents (D-371): per person, per computer. Only the device's owner reads or writes
  // them (own() and RLS), so an admin can't put a command on a member's computer.
  const ownList = async (claims: JwtClaims, deviceId: string) => {
    const rows = await withUserSession(db, claims, (tx) =>
      tx
        .select()
        .from(schema.ownCodingAgents)
        .where(eq(schema.ownCodingAgents.deviceId, deviceId))
        .orderBy(schema.ownCodingAgents.label),
    );
    return rows.map((r) => ({
      id: `${OWN_AGENT_PREFIX}${r.key}`,
      key: r.key,
      label: r.label,
      bin: r.bin,
      command: r.command,
      result: r.result,
      timeout_min: r.timeoutMin,
    }));
  };

  app.openapi(routes.listOwnCodingAgents, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    await own(claims, id);
    return c.json({ items: await ownList(claims, id) }, 200);
  });

  app.openapi(routes.setOwnCodingAgents, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const { agents } = c.req.valid("json");
    const d = await own(claims, id);
    if (d.platform === "chrome")
      throw new ApiError(400, "not_a_computer", "Coding agents run on a computer, not a browser");
    if (new Set(agents.map((a) => a.key)).size !== agents.length)
      throw new ApiError(400, "duplicate_agent", "Each of your agents needs its own name");
    for (const a of agents) {
      const errors = checkOwnCodingAgent(a);
      if (errors.length)
        throw new ApiError(400, "bad_agent", `${a.label}: ${errors.slice(0, 3).join("; ")}`);
    }
    await withUserSession(db, claims, async (tx) => {
      await tx.delete(schema.ownCodingAgents).where(eq(schema.ownCodingAgents.deviceId, d.id));
      if (agents.length)
        await tx.insert(schema.ownCodingAgents).values(
          agents.map((a) => ({
            orgId: d.orgId,
            userId: claims.sub,
            deviceId: d.id,
            key: a.key,
            label: a.label,
            bin: a.bin,
            command: a.command,
            result: a.result,
            timeoutMin: a.timeout_min ?? 30,
          })),
        );
    });
    return c.json({ items: await ownList(claims, id) }, 200);
  });

  // Test: a tiny task through this computer's companion, the way coding.delegate runs it.
  app.openapi(routes.testOwnCodingAgent, async (c) => {
    const claims = requireClaims(c.get("claims"));
    const { id } = c.req.valid("param");
    const body = c.req.valid("json");
    const d = await own(claims, id);
    const errors = checkOwnCodingAgent({ ...body, key: "test" });
    if (errors.length) throw new ApiError(400, "bad_agent", errors.slice(0, 3).join("; "));
    if (!registry || !d.computerId || !d.enabled || !registry.online(d.computerId))
      throw new ApiError(
        409,
        "device_offline",
        "This computer isn't connected. Turn on Use this computer for bots and try again.",
      );
    if (!caps(d.capabilities).shell)
      throw new ApiError(
        409,
        "commands_off",
        "Turn on Run commands first: agents run as commands.",
      );
    const spec = ownCodingAgentSpec({ ...body, key: "test" });
    const command = renderCodingCommand(spec, "my_computer", { task: CODING_TEST_TASK });
    const timeoutMs = (body.timeout_min ?? 3) * 60_000;
    const r = await execOnDevice(registry, d.computerId, {
      cmd: command,
      cwd: d.allowedRoots[0],
      timeoutMs,
    });
    const summary = summarizeAgentOutput(r.out, spec.result);
    const tail = r.out.trim();
    return c.json(
      {
        ok: r.code === 0 && !r.timedOut && !summary.error && summary.text.trim().length > 0,
        exit_code: r.code,
        timed_out: r.timedOut,
        reply: summary.text.slice(0, 2000),
        output: tail.length > 4000 ? `…${tail.slice(-4000)}` : tail,
        command,
      },
      200,
    );
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
  // --- Browser devices (Casama for Chrome, D-323 Phase 3) ---------------------------------------

  /** A browser device as the tunnel sees it, with what its owner and workspace decided. */
  const browserDevice = async (deviceId: string) => {
    const [d] = await deps.db.execute<{
      id: string;
      org_id: string;
      user_id: string;
      enabled: boolean;
      platform: string;
      capabilities: { browser?: boolean };
      allowed_bot_ids: string[];
      allowed_sites: string[];
      blocked_sites: string[];
      allowed_kinds: string[];
      chrome_act: boolean;
      org_blocked: string[];
      system: AppBrowserSystem | null;
      client_id: string | null;
      app_browser: boolean;
    }>(sql`
      select d.id, d.org_id, d.user_id, d.enabled, d.platform, d.capabilities, d.allowed_bot_ids,
             d.allowed_sites, d.blocked_sites, d.allowed_kinds, d.system, d.client_id,
             o.chrome_extension and o.chrome_act as chrome_act, o.chrome_blocked_sites as org_blocked,
             o.app_browser
      from public.local_devices d join public.organizations o on o.id = d.org_id
      where d.id = ${deviceId}::uuid`);
    if (d?.platform === "chrome") return d;
    if (d?.platform !== "app") return null;
    // The phone app's browser: the workspace's own switch and the instance's stage stand in for
    // the Chrome switches.
    const may = appBrowserFor(await getAppBrowserSettings(deps.db), {
      userId: d.user_id,
      system: d.system,
      workspaceOn: d.app_browser,
    });
    return { ...d, chrome_act: may.available };
  };

  app.get("/internal/browser/:device/status", async (c) => {
    const d = await browserDevice(c.req.param("device"));
    return c.json({
      online: !!d?.enabled && d.chrome_act && !!registry?.online(browserKey(d.id)),
    });
  });

  /**
   * One browser tool call for a run (or a page check for a watcher), forwarded to the extension.
   * Only runs acting for the browser's owner, by a bot they allowed, in the browser's workspace, may
   * use it (owner only, as D-091); Casama's own addresses and blocked sites are refused here too.
   */
  app.post("/internal/browser/:device/call", async (c) => {
    if (!registry) return c.json({ code: "unavailable" }, 503);
    const fail = (code: string, message: string, status = 403) =>
      c.json({ ok: false, code, message } satisfies BrowserResult, status as 403);
    const d = await browserDevice(c.req.param("device"));
    if (!d?.enabled || !d.capabilities?.browser)
      return fail("device_not_found", "That browser isn't paired", 404);
    if (!d.chrome_act)
      return fail(
        "act_off",
        d.platform === "app"
          ? "The phone browser is switched off"
          : "This workspace doesn't let bots use members' browsers",
      );
    const phone = d.platform === "app";
    const raw = (await c.req.json().catch(() => null)) as {
      action?: unknown;
      args?: unknown;
      run_id?: string;
      watcher_id?: string;
    } | null;
    const parsed = BrowserCallBody.safeParse(raw ?? {});
    if (!parsed.success) return fail("bad_call", "Unknown browser action", 400);
    const { action, args } = parsed.data;
    let who: {
      kind: "run" | "watcher";
      id: string;
      bot_id: string;
      bot_name: string;
      conversation_id?: string | null;
    };
    if (raw?.run_id) {
      const [r] = await deps.db.execute<{
        org_id: string;
        bot_id: string;
        name: string;
        conversation_id: string | null;
        status: string;
        trigger: string;
        routine_id: string | null;
        created_by: string | null;
        on_screen: boolean;
      }>(sql`select r.org_id, r.bot_id, b.name, r.conversation_id, r.status, r.trigger, r.routine_id,
                    r.created_by,
                    exists (select 1 from public.chat_focus f
                            where f.user_id = ${d.user_id}::uuid and f.client_id = ${d.client_id ?? ""}
                              and f.conversation_id = r.conversation_id
                              and f.updated_at > now() - make_interval(secs => ${APP_BROWSER_FOCUS_S})) as on_screen
             from public.runs r
             join public.bots b on b.id = r.bot_id where r.id = ${raw.run_id}::uuid`);
      if (!r) return fail("run_not_found", "No such run", 404);
      if (r.org_id !== d.org_id || !d.allowed_bot_ids.includes(r.bot_id))
        return fail("bot_not_allowed", "This bot isn't allowed to use that browser");
      if ((await actingUserOf(deps.db, raw.run_id)) !== d.user_id)
        return fail("not_your_browser", "Only the browser's owner's own chats can use it");
      if (phone) {
        // Only the person's own chat message, and only while that chat is on this phone's screen.
        if (r.trigger !== "chat" || r.routine_id || r.created_by !== d.user_id)
          return fail("not_a_chat", "The phone's browser is only for the person's own chats");
        if (!r.on_screen)
          return fail("away", "The person doesn't have this chat open on that phone", 409);
      }
      who = {
        kind: "run",
        id: raw.run_id,
        bot_id: r.bot_id,
        bot_name: r.name,
        conversation_id: r.conversation_id,
      };
    } else if (raw?.watcher_id) {
      const [w] = await deps.db.execute<{
        org_id: string;
        bot_id: string;
        name: string;
        created_by: string | null;
      }>(
        sql`select w.org_id, w.bot_id, b.name, w.created_by from public.watchers w
            join public.bots b on b.id = w.bot_id where w.id = ${raw.watcher_id}::uuid and w.status = 'active'`,
      );
      if (!w) return fail("watcher_not_found", "No such watcher", 404);
      if (phone) return fail("bot_not_allowed", "Watchers can't use a phone's browser");
      if (
        w.org_id !== d.org_id ||
        !d.allowed_bot_ids.includes(w.bot_id) ||
        w.created_by !== d.user_id
      )
        return fail("bot_not_allowed", "This watcher can't use that browser");
      if (action !== "page_text") return fail("bad_call", "Watchers only read pages", 400);
      who = { kind: "watcher", id: raw.watcher_id, bot_id: w.bot_id, bot_name: w.name };
    } else return fail("bad_call", "A browser call needs a run or a watcher", 400);
    // Addresses a bot asks for directly; the extension checks every page it lands on as well.
    const asked = typeof args.url === "string" ? args.url : null;
    if (asked) {
      if (!browsable(asked)) return fail("refused", "Only web pages can be opened");
      if (
        isCasamaAddress(asked, [
          deps.env.PUBLIC_API_URL,
          deps.env.PUBLIC_APP_URL,
          deps.env.SUPABASE_URL,
        ])
      )
        return fail("refused", "Casama's own pages can't be opened by a bot");
    }
    const call = {
      action,
      args,
      ...(who.kind === "run"
        ? {
            run: {
              id: who.id,
              bot_id: who.bot_id,
              bot_name: who.bot_name,
              conversation_id: who.conversation_id ?? null,
            },
          }
        : { watcher: { id: who.id, bot_id: who.bot_id, bot_name: who.bot_name } }),
      policy: {
        blocked_sites: [...new Set([...(d.org_blocked ?? []), ...(d.blocked_sites ?? [])])],
        allowed_sites: d.allowed_sites ?? [],
        allowed_kinds: d.allowed_kinds ?? [],
        own_urls: [deps.env.PUBLIC_API_URL, deps.env.PUBLIC_APP_URL, deps.env.SUPABASE_URL].filter(
          Boolean,
        ),
      },
    };
    /** Sends one request to the device and waits for its whole answer. */
    const forward = (path: string, payload: unknown) =>
      new Promise<{ status: number; body: Buffer } | { error: string }>((resolve) => {
        const chunks: Buffer[] = [];
        let status = 502;
        let cancel = () => {};
        try {
          cancel = registry.request(
            browserKey(d.id),
            {
              method: "POST",
              path,
              headers: { "content-type": "application/json" },
              body: Buffer.from(JSON.stringify(payload)),
            },
            {
              onResponse: (st) => {
                status = st;
              },
              onChunk: (b) => chunks.push(b),
              onEnd: () => resolve({ status, body: Buffer.concat(chunks) }),
              onError: (m) => resolve({ error: m }),
            },
          );
        } catch {
          resolve({ error: "offline" });
        }
        // The worker gave up (the run was cancelled): tell the browser to stop this call.
        c.req.raw.signal?.addEventListener("abort", () => cancel());
      });
    const offline = (error: string) =>
      fail(
        "offline",
        error === "offline" ? "The browser is offline" : `The browser didn't answer: ${error}`,
        409,
      );
    const audit = (what: string, host: string | null, more: Record<string, unknown> = {}) =>
      void deps.db
        .execute(sql`
          insert into public.audit_log (org_id, actor_type, actor_id, action, target_type, target_id, metadata)
          values (${d.org_id}::uuid, 'bot', ${who.bot_id}::uuid, ${`browser.${what}`}, 'local_device', ${d.id}::uuid,
                  ${JSON.stringify({ run_id: who.id, host, ...more })}::jsonb)`)
        .catch(() => {});

    // The phone app's browser: what it can't do, and the step rules, which the server runs so
    // there is one copy of them (docs/PHONE-BROWSER-PLAN.md §8.5).
    let expect: string | undefined;
    if (phone) {
      if ((APP_BROWSER_UNSUPPORTED as readonly string[]).includes(action))
        return fail(
          "unsupported",
          `The phone's browser has no ${action}; use your own computer for that (where: "computer").`,
          200,
        );
      if ((APP_BROWSER_CHECKED as readonly string[]).includes(action)) {
        const probed = await forward("/browser/probe", {
          ...call,
          action: "probe",
          args: action === "type" || action === "press" ? { focused: true } : { ref: args.ref },
        });
        if ("error" in probed) return offline(probed.error);
        let facts: StepFacts;
        try {
          const a = JSON.parse(probed.body.toString()) as BrowserResult;
          // The page couldn't say what the step is aimed at (a stale ref, focus it can't see).
          if (!a.ok)
            return a.code === "out_of_sight"
              ? fail(
                  "handed_off",
                  "The page's focus is somewhere a bot can't see into, so this step is the person's to do on their phone. Tell them what's left, and don't try another way.",
                  200,
                )
              : c.json(a, 200);
          const p = JSON.parse(a.text) as { facts?: StepFacts; fingerprint?: string };
          if (!p.facts || typeof p.fingerprint !== "string") throw new Error("no facts");
          facts = p.facts;
          expect = p.fingerprint;
        } catch {
          return fail("bad_answer", "The phone's answer about that element couldn't be read", 502);
        }
        const host = typeof facts.host === "string" ? facts.host : null;
        const verdict = stepVerdict(who.id, action, args, facts);
        if (verdict.kind === "hand_off") {
          audit("step_handed_off", host, { step: action, reason: verdict.reason });
          void forward("/browser/handoff", {
            ...call,
            action: "handoff",
            args: { reason: verdict.reason },
          });
          return fail(
            "handed_off",
            `${verdict.reason}. This step is the person's to do themselves, on the page on their phone. Tell them what's left, and don't try another way.`,
            200,
          );
        }
        if (verdict.kind === "ask") {
          const asked = await forward("/browser/ask", {
            ...call,
            action: "ask",
            args: { reason: verdict.reason, step: action, name: facts.name ?? "" },
          });
          if ("error" in asked) return offline(asked.error);
          let yes = false;
          try {
            const a = JSON.parse(asked.body.toString()) as BrowserResult;
            yes = a.ok && a.text === "allow";
          } catch {
            yes = false;
          }
          if (!yes) {
            audit("step_denied", host, { step: action, reason: verdict.reason });
            return fail(
              "asked_denied",
              `The person didn't allow this step (${verdict.reason}). Don't try another way; ask them what they'd like instead.`,
              200,
            );
          }
        }
      }
    }
    const result = await forward(`/browser/${action}`, expect ? { ...call, expect } : call);
    if ("error" in result) return offline(result.error);
    try {
      const answer = JSON.parse(result.body.toString()) as BrowserResult;
      let host: string | null = null;
      try {
        host = answer.ok && answer.url ? new URL(answer.url).hostname : null;
      } catch {
        host = null;
      }
      // What the run read on a phone, by site, for the cross-site check on later steps.
      if (phone && answer.ok && ["snapshot", "read", "extract"].includes(action))
        rememberRead(who.id, host, answer.text);
      // Every step that changes something in a person's browser goes in the audit log (plan §11).
      if (
        who.kind === "run" &&
        answer.ok &&
        [
          "open",
          "click",
          "fill",
          "type",
          "press",
          "upload",
          "download",
          "dialog",
          "switch_tab",
        ].includes(action)
      )
        audit(action, host);
      return c.json(answer, 200);
    } catch {
      return fail("bad_answer", "The browser's answer couldn't be read", 502);
    }
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

    // Plugin packages and their server list are pushed by the API itself (D-344), never by a run.
    if (/^\/plugin(s|-servers)(\/|\?|$)/.test(path))
      return c.json({ code: "forbidden", message: "Not through the tunnel" }, 403);
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
    // The device's owner may open, list and see thumbnails of files in the folders they shared,
    // read-only and with no bot involved (D-226), and see their own screen in the app's Screen tab
    // (D-218; the device refuses it unless desktop access is on). The API route sets the viewer
    // after checking the person's sign-in; the device still refuses paths outside the shared folders.
    const viewer = c.req.header("x-casama-viewer");
    const ownerRead =
      !!viewer &&
      c.req.method === "GET" &&
      (/^\/files(\/thumbnail|\/list)?(\?|$)/.test(path) || /^\/screenshot(\?|$)/.test(path)) &&
      !!(
        await deps.db.execute<{ ok: boolean }>(sql`
          select true as ok from public.local_devices
          where computer_id = ${computerId}::uuid and enabled and user_id::text = ${viewer} limit 1`)
      )[0]?.ok;
    // Only bots the user allowed may act on their machine (health checks carry no run).
    if (path !== "/health" && !listingOnly && !ownerRead) {
      const runId = (activity as { run_id?: string } | undefined)?.run_id;
      // iMessage chat apps (D-134) poll and send with no run: allowed when the Mac's owner
      // connected it to a bot they allowed on this machine.
      const imessage = !runId && /^\/imessage\/(new|send)(\?|$)/.test(path);
      // A plugin's servers placed on this computer (D-344) answer the bot they were installed for,
      // in runs acting for the computer's owner (D-131), without allowing the bot anything else.
      const pluginKey = /^\/mcp\/([a-z][a-z0-9_]{0,39})(\?|$)/.exec(path)?.[1];
      const [plugin] =
        runId && pluginKey
          ? await deps.db.execute<{ ok: boolean; owner: string }>(sql`
            select d.enabled as ok, d.user_id::text as owner
            from public.integrations i
            join public.local_devices d on d.computer_id = ${computerId}::uuid
            join public.runs r on r.id = ${runId}::uuid
            join public.bot_integrations bi on bi.integration_id = i.id and bi.bot_id = r.bot_id
            where i.kind = 'local_mcp' and i.plugin_id is not null
              and i.config ->> 'computer_id' = ${computerId} and i.config ->> 'bridge_key' = ${pluginKey}
              and i.config ->> 'owner_user_id' = d.user_id::text
            limit 1`)
          : [];
      if (plugin) {
        if (!plugin.ok || (await actingUserOf(deps.db, runId as string)) !== plugin.owner)
          return c.json(
            {
              code: "bot_not_allowed",
              message:
                "These tools run on someone else's own computer, so only they can use them from their own chats.",
            },
            403,
          );
      }
      const [allowed] = plugin
        ? [{ ok: true }]
        : imessage
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
    if (!d?.enabled || (!d.computerId && d.platform !== "chrome" && d.platform !== "app"))
      return reject("401 Unauthorized");
    if (d.platform === "app") {
      // The phone app's browser connects only while the stage and the workspace allow its owner.
      const [x] = await deps.db
        .execute<{ system: AppBrowserSystem | null; app_browser: boolean }>(
          sql`select d.system, o.app_browser from public.local_devices d
              join public.organizations o on o.id = d.org_id where d.id = ${d.id}::uuid`,
        )
        .catch(() => [] as Array<{ system: AppBrowserSystem | null; app_browser: boolean }>);
      const may = x
        ? appBrowserFor(await getAppBrowserSettings(deps.db), {
            userId: d.userId,
            system: x.system,
            workspaceOn: x.app_browser,
          })
        : { available: false };
      if (!may.available) return reject("403 Forbidden");
    }
    if (d.platform === "chrome") {
      const [o] = await deps.db
        .execute<{ ok: boolean }>(
          sql`select chrome_extension and chrome_act as ok from public.organizations where id = ${d.orgId}::uuid`,
        )
        .catch(() => [] as Array<{ ok: boolean }>);
      if (!o?.ok) return reject("403 Forbidden");
    }
    const registry = deps.devices;
    const computerId = d.computerId ?? browserKey(d.id);
    const browserOnly = !d.computerId;
    // What the desktop app says it runs, e.g. "macOS 26.2" (D-227). Display text only.
    const os = deviceOsVersion(req.headers["x-casama-os"]);
    if (os && os !== d.osVersion)
      void deps.db
        .update(localDevices)
        .set({ osVersion: os })
        .where(eq(localDevices.id, d.id))
        .catch(() => {});
    wss.handleUpgrade(req, socket, head, (ws) => {
      registry.attach(computerId, d.id, ws);
      ws.send(
        JSON.stringify({
          type: "ready",
          device_id: d.id,
          computer_id: browserOnly ? null : computerId,
        }),
      );
      const seen = () =>
        void (
          browserOnly
            ? deps.db.execute(
                sql`update public.local_devices set last_seen_at = now() where id = ${d.id}::uuid`,
              )
            : touch(deps.db, d.id, computerId)
        ).catch(() => {});
      seen();
      // Plugin servers placed on this computer (D-344) live in computerd's memory: hand them
      // over again on every connection.
      if (!browserOnly) void syncCompanionPluginsQuietly(deps, computerId);
      const t = setInterval(seen, 60_000);
      ws.on("close", () => {
        clearInterval(t);
        if (browserOnly) return;
        void deps.db
          .execute(
            sql`update public.computers set state = 'stopped' where id = ${computerId}::uuid`,
          )
          .catch(() => {});
      });
    });
  });
}

/** The OS a device reported: printable text, at most 80 characters, or null. */
export function deviceOsVersion(raw: string | string[] | undefined): string | null {
  const v = (Array.isArray(raw) ? raw[0] : raw) ?? "";
  const clean = v.replace(/[\p{Cc}\s]+/gu, " ").trim();
  return clean ? clean.slice(0, 80).trim() : null;
}

async function touch(db: Database, deviceId: string, computerId: string) {
  await db.execute(
    sql`update public.local_devices set last_seen_at = now() where id = ${deviceId}::uuid`,
  );
  await db.execute(
    sql`update public.computers set state = 'running', last_active_at = now() where id = ${computerId}::uuid`,
  );
}
