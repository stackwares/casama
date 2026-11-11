import type { IncomingMessage, Server } from "node:http";
import type { Duplex } from "node:stream";
import {
  type ComputerSpec,
  SandboxError,
  type SandboxProvider,
  type SnapshotRef,
} from "@casama/sandbox";
import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { stream } from "hono/streaming";
import { WebSocket, WebSocketServer } from "ws";

/**
 * The default provider: Docker normally, or a hosted one (kubernetes in a cluster) with
 * DEFAULT_PROVIDER (D-147). Docker adds a ping for health and a list of running computers.
 */
export type MainProvider = SandboxProvider & {
  list?: () => Promise<unknown>;
  opts?: { docker?: { ping(): Promise<unknown> }; store?: { delete(key: string): Promise<void> } };
};

/**
 * Supervisor HTTP API: the only service with Docker access. The API and worker call it with
 * a bearer token; computers never receive that token.
 */
export function createSupervisorApp(
  provider: MainProvider,
  token: string,
  hosted: Record<string, SandboxProvider> = {},
) {
  const app = new Hono();
  /** Docker by default; E2B or Daytona when the caller names them (D-056). */
  const pick = (c: { req: { header(name: string): string | undefined } }): SandboxProvider => {
    const id = c.req.header("x-casama-provider");
    if (!id || id === "docker") return provider;
    const p = hosted[id];
    if (!p) throw new SandboxError("provider_unavailable", `Provider ${id} is not configured`, 400);
    return p;
  };

  app.onError((err, c) => {
    if (err instanceof SandboxError) {
      const status =
        err.status && err.status >= 400 && err.status < 600
          ? err.status
          : err.code === "not_found"
            ? 404
            : 502;
      return c.json({ code: err.code, message: err.message }, status as 400);
    }
    return c.json({ code: "internal_error", message: (err as Error).message }, 500);
  });

  app.get("/healthz", async (c) =>
    c.json({
      ok: provider.opts?.docker ? await provider.opts.docker.ping().catch(() => false) : true,
    }),
  );

  app.use("/computers/*", async (c, next) => {
    if (c.req.header("authorization") !== `Bearer ${token}`)
      return c.json({ code: "unauthorized" }, 401);
    await next();
  });
  app.use("/computers", async (c, next) => {
    if (c.req.header("authorization") !== `Bearer ${token}`)
      return c.json({ code: "unauthorized" }, 401);
    await next();
  });

  const running = async (
    ref: string,
    c?: { req: { header(name: string): string | undefined } },
  ) => {
    const h = await (c ? pick(c) : provider).get(ref);
    if (!h) throw new SandboxError("not_running", `Computer ${ref} is not running`, 409);
    return h;
  };

  app.get("/computers", async (c) => c.json({ running: (await provider.list?.()) ?? [] }));

  app.post("/computers", async (c) => {
    const spec = (await c.req.json()) as ComputerSpec;
    await pick(c).create(spec);
    return c.json({ ref: spec.ref, state: "running" }, 201);
  });

  app.get("/computers/:ref", async (c) => {
    const h = await pick(c).get(c.req.param("ref"));
    return c.json({
      ref: c.req.param("ref"),
      running: !!h,
      health: h ? await h.health().catch(() => null) : null,
    });
  });

  app.post("/computers/:ref/resume", async (c) => {
    const body = (await c.req.json().catch(() => ({}))) as {
      snapshot?: SnapshotRef;
      spec?: Partial<ComputerSpec>;
    };
    await pick(c).resume(c.req.param("ref"), body.snapshot, body.spec);
    return c.json({ ref: c.req.param("ref"), state: "running" });
  });

  app.post("/computers/:ref/sleep", async (c) => c.json(await pick(c).sleep(c.req.param("ref"))));

  app.delete("/computers/:ref", async (c) => {
    await pick(c).destroy(c.req.param("ref"));
    return c.json({ ok: true });
  });

  app.post("/computers/:ref/exec", async (c) => {
    const h = await running(c.req.param("ref"), c);
    const body = (await c.req.json()) as {
      cmd: string;
      cwd?: string;
      env?: Record<string, string>;
      timeoutMs?: number;
      stdin?: string;
    };
    c.header("content-type", "application/x-ndjson");
    return stream(c, async (s) => {
      let execId: string | undefined;
      s.onAbort(() => {
        if (execId) void h.kill(execId).catch(() => {});
      });
      for await (const chunk of h.exec(body.cmd, {
        cwd: body.cwd,
        env: body.env,
        timeoutMs: body.timeoutMs,
        stdin: body.stdin,
      })) {
        if (chunk.type === "start") execId = chunk.execId;
        await s.write(`${JSON.stringify(chunk)}\n`);
      }
    });
  });

  app.post("/computers/:ref/exec/:id/kill", async (c) => {
    await (await running(c.req.param("ref"), c)).kill(c.req.param("id"));
    return c.json({ ok: true });
  });

  app.get("/computers/:ref/files", async (c) => {
    const data = await (await running(c.req.param("ref"), c)).readFile(c.req.query("path") ?? "");
    return c.body(Buffer.from(data), 200, { "content-type": "application/octet-stream" });
  });
  app.put("/computers/:ref/files", async (c) => {
    const h = await running(c.req.param("ref"), c);
    await h.writeFile(c.req.query("path") ?? "", new Uint8Array(await c.req.arrayBuffer()));
    return c.json({ ok: true });
  });
  app.delete("/computers/:ref/files", async (c) => {
    await (await running(c.req.param("ref"), c)).deleteFile(c.req.query("path") ?? "");
    return c.json({ ok: true });
  });
  app.get("/computers/:ref/files/list", async (c) =>
    c.json({
      entries: await (await running(c.req.param("ref"), c)).listDir(c.req.query("path") ?? ""),
    }),
  );
  app.post("/computers/:ref/files/search", async (c) => {
    const body = (await c.req.json()) as { query: string; path?: string };
    return c.json({
      matches: await (await running(c.req.param("ref"), c)).search(body.query, body.path),
    });
  });

  app.post("/computers/:ref/checkpoints", async (c) => {
    const { label } = (await c.req.json()) as { label: string };
    return c.json(
      await (await running(c.req.param("ref"), c)).checkpoint(label ?? "checkpoint"),
      201,
    );
  });
  app.post("/computers/:ref/checkpoints/restore", async (c) => {
    const cp = (await c.req.json()) as Parameters<
      Awaited<ReturnType<typeof running>>["restore"]
    >[0];
    await (await running(c.req.param("ref"), c)).restore(cp);
    return c.json({ ok: true });
  });
  app.post("/objects/delete", async (c) => {
    if (c.req.header("authorization") !== `Bearer ${token}`)
      return c.json({ code: "unauthorized" }, 401);
    const { keys } = (await c.req.json()) as { keys: string[] };
    for (const k of keys) await provider.opts?.store?.delete(k);
    return c.json({ ok: true });
  });

  app.get("/computers/:ref/health", async (c) =>
    c.json(await (await running(c.req.param("ref"), c)).health()),
  );
  app.get("/computers/:ref/screenshot", async (c) =>
    c.body(Buffer.from(await (await running(c.req.param("ref"), c)).screenshot()), 200, {
      "content-type": "image/png",
    }),
  );
  app.post("/computers/:ref/stream/stop", async (c) => {
    await (await running(c.req.param("ref"), c)).stopStream();
    return c.json({ ok: true });
  });
  // Plugin MCP servers inside the computer (D-121): the list, and raw MCP requests to one.
  app.put("/computers/:ref/mcp-servers", async (c) => {
    const h = await running(c.req.param("ref"), c);
    if (!h.setMcpServers)
      throw new SandboxError("not_supported", "This computer can't run MCP servers", 501);
    await h.setMcpServers(await c.req.json());
    return c.json({ ok: true });
  });
  app.on(["GET", "POST", "DELETE"], "/computers/:ref/mcp/:key", async (c) => {
    const h = await running(c.req.param("ref"), c);
    if (!h.mcpFetch)
      throw new SandboxError("not_supported", "This computer can't run MCP servers", 501);
    const headers: Record<string, string> = {};
    for (const k of [
      "content-type",
      "accept",
      "mcp-session-id",
      "mcp-protocol-version",
      "last-event-id",
    ]) {
      const v = c.req.header(k);
      if (v) headers[k] = v;
    }
    const res = await h.mcpFetch(c.req.param("key"), {
      method: c.req.method,
      headers,
      body: c.req.method === "POST" ? await c.req.arrayBuffer() : undefined,
      signal: c.req.raw.signal,
    });
    const out = new Headers();
    for (const k of ["content-type", "mcp-session-id", "cache-control"]) {
      const v = res.headers.get(k);
      if (v) out.set(k, v);
    }
    return new Response(res.body, { status: res.status, headers: out });
  });
  app.post("/computers/:ref/input", async (c) => {
    await (await running(c.req.param("ref"), c)).input(await c.req.json());
    return c.json({ ok: true });
  });

  return app;
}

/** Client messages a view-only connection may never send (Neko also refuses them). */
const VIEW_BLOCKED = /^(control|clipboard|keyboard|screen\/set|send)\//;

/**
 * Proxies live-view signaling: API <-> supervisor <-> the computer's Neko streamer.
 * Starts the streamer on the first viewer and stops it `idleStopMs` after the last one leaves.
 */
export function attachStreamProxy(
  _server: Server,
  provider: MainProvider,
  token: string,
  opts: { idleStopMs?: number; hosted?: Record<string, SandboxProvider> } = {},
) {
  const wss = new WebSocketServer({ noServer: true });
  const viewers = new Map<string, number>();
  const stopTimers = new Map<string, NodeJS.Timeout>();
  const idleStopMs = opts.idleStopMs ?? 60_000;
  return async (req: IncomingMessage, socket: Duplex, head: Buffer): Promise<boolean> => {
    const url = new URL(req.url ?? "/", "http://supervisor");
    const ref = url.pathname.match(/^\/computers\/([\w-]+)\/stream$/)?.[1];
    if (!ref) return false;
    if (req.headers.authorization !== `Bearer ${token}`) {
      socket.end("HTTP/1.1 401 Unauthorized\r\n\r\n");
      return true;
    }
    const mode = url.searchParams.get("mode") === "control" ? "control" : "view";
    const which = req.headers["x-casama-provider"];
    const p = typeof which === "string" && which !== "docker" ? opts.hosted?.[which] : provider;
    const h = await p?.get(ref).catch(() => null);
    if (!h) {
      socket.end("HTTP/1.1 409 Conflict\r\n\r\n");
      return true;
    }
    let target: { url: string; headers: Record<string, string> };
    try {
      target = await h.streamEndpoint({ mode });
    } catch (err) {
      socket.end(`HTTP/1.1 502 Bad Gateway\r\n\r\n${(err as Error).message}`);
      return true;
    }
    clearTimeout(stopTimers.get(ref));
    viewers.set(ref, (viewers.get(ref) ?? 0) + 1);
    wss.handleUpgrade(req, socket, head, (client) => {
      const upstream = new WebSocket(target.url, { headers: target.headers });
      const pending: Array<{ data: unknown; binary: boolean }> = [];
      client.on("message", (data, binary) => {
        if (mode === "view" && !binary) {
          try {
            const event = (JSON.parse(String(data)) as { event?: string }).event ?? "";
            if (VIEW_BLOCKED.test(event)) return;
          } catch {
            return;
          }
        }
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
      let closed = false;
      const close = () => {
        client.close();
        upstream.close();
        if (closed) return;
        closed = true;
        const left = (viewers.get(ref) ?? 1) - 1;
        viewers.set(ref, left);
        if (left <= 0) {
          viewers.delete(ref);
          stopTimers.set(
            ref,
            setTimeout(() => {
              stopTimers.delete(ref);
              if (!viewers.has(ref)) void h.stopStream().catch(() => {});
            }, idleStopMs),
          );
        }
      };
      upstream.on("close", close);
      upstream.on("error", close);
      client.on("close", close);
      client.on("error", close);
    });
    return true;
  };
}

/** Proxies terminal WebSockets: client <-> supervisor <-> computerd. */
export function attachTerminalProxy(
  server: Server,
  provider: MainProvider,
  token: string,
  hosted: Record<string, SandboxProvider> = {},
) {
  const wss = new WebSocketServer({ noServer: true });
  const stream = attachStreamProxy(server, provider, token, {
    hosted,
    idleStopMs: process.env.STREAM_IDLE_STOP_MS
      ? Number(process.env.STREAM_IDLE_STOP_MS)
      : undefined,
  });
  server.on("upgrade", async (req: IncomingMessage, socket: Duplex, head: Buffer) => {
    if (await stream(req, socket, head)) return;
    const url = new URL(req.url ?? "/", "http://supervisor");
    const ref = url.pathname.match(/^\/computers\/([\w-]+)\/terminal$/)?.[1];
    if (!ref || req.headers.authorization !== `Bearer ${token}`) {
      socket.end("HTTP/1.1 401 Unauthorized\r\n\r\n");
      return;
    }
    const which = req.headers["x-casama-provider"];
    const p = typeof which === "string" && which !== "docker" ? hosted[which] : provider;
    const h = await p?.get(ref).catch(() => null);
    if (!h) {
      socket.end("HTTP/1.1 409 Conflict\r\n\r\n");
      return;
    }
    const target = await h.terminalEndpoint({
      cols: Number(url.searchParams.get("cols") ?? 120),
      rows: Number(url.searchParams.get("rows") ?? 32),
    });
    wss.handleUpgrade(req, socket, head, (client) => {
      const upstream = new WebSocket(target.url, { headers: target.headers });
      const pending: Array<{ data: unknown; binary: boolean }> = [];
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
        client.close();
        upstream.close();
      };
      upstream.on("close", close);
      upstream.on("error", close);
      client.on("close", close);
      client.on("error", close);
    });
  });
}

export function startSupervisor(
  provider: MainProvider,
  token: string,
  port: number,
  hosted: Record<string, SandboxProvider> = {},
) {
  const app = createSupervisorApp(provider, token, hosted);
  const server = serve({ fetch: app.fetch, port, hostname: "0.0.0.0" }) as Server;
  attachTerminalProxy(server, provider, token, hosted);
  return server;
}
