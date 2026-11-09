import type { IncomingMessage, Server } from "node:http";
import type { Duplex } from "node:stream";
import { serve } from "@hono/node-server";
import { type ComputerSpec, type DockerProvider, SandboxError, type SnapshotRef } from "@kasama/sandbox";
import { Hono } from "hono";
import { stream } from "hono/streaming";
import { WebSocket, WebSocketServer } from "ws";

/**
 * Supervisor HTTP API: the only service with Docker access. The API and worker call it with
 * a bearer token; computers never receive that token.
 */
export function createSupervisorApp(provider: DockerProvider, token: string) {
  const app = new Hono();

  app.onError((err, c) => {
    if (err instanceof SandboxError) {
      const status = err.status && err.status >= 400 && err.status < 600 ? err.status : err.code === "not_found" ? 404 : 502;
      return c.json({ code: err.code, message: err.message }, status as 400);
    }
    return c.json({ code: "internal_error", message: (err as Error).message }, 500);
  });

  app.get("/healthz", async (c) => c.json({ ok: await provider.opts.docker.ping().catch(() => false) }));

  app.use("/computers/*", async (c, next) => {
    if (c.req.header("authorization") !== `Bearer ${token}`) return c.json({ code: "unauthorized" }, 401);
    await next();
  });
  app.use("/computers", async (c, next) => {
    if (c.req.header("authorization") !== `Bearer ${token}`) return c.json({ code: "unauthorized" }, 401);
    await next();
  });

  const running = async (ref: string) => {
    const h = await provider.get(ref);
    if (!h) throw new SandboxError("not_running", `Computer ${ref} is not running`, 409);
    return h;
  };

  app.get("/computers", async (c) => c.json({ running: await provider.list() }));

  app.post("/computers", async (c) => {
    const spec = (await c.req.json()) as ComputerSpec;
    await provider.create(spec);
    return c.json({ ref: spec.ref, state: "running" }, 201);
  });

  app.get("/computers/:ref", async (c) => {
    const h = await provider.get(c.req.param("ref"));
    return c.json({ ref: c.req.param("ref"), running: !!h, health: h ? await h.health().catch(() => null) : null });
  });

  app.post("/computers/:ref/resume", async (c) => {
    const body = (await c.req.json().catch(() => ({}))) as { snapshot?: SnapshotRef; spec?: Partial<ComputerSpec> };
    await provider.resume(c.req.param("ref"), body.snapshot, body.spec);
    return c.json({ ref: c.req.param("ref"), state: "running" });
  });

  app.post("/computers/:ref/sleep", async (c) => c.json(await provider.sleep(c.req.param("ref"))));

  app.delete("/computers/:ref", async (c) => {
    await provider.destroy(c.req.param("ref"));
    return c.json({ ok: true });
  });

  app.post("/computers/:ref/exec", async (c) => {
    const h = await running(c.req.param("ref"));
    const body = (await c.req.json()) as { cmd: string; cwd?: string; env?: Record<string, string>; timeoutMs?: number; stdin?: string };
    c.header("content-type", "application/x-ndjson");
    return stream(c, async (s) => {
      let execId: string | undefined;
      s.onAbort(() => {
        if (execId) void h.kill(execId).catch(() => {});
      });
      for await (const chunk of h.exec(body.cmd, { cwd: body.cwd, env: body.env, timeoutMs: body.timeoutMs, stdin: body.stdin })) {
        if (chunk.type === "start") execId = chunk.execId;
        await s.write(`${JSON.stringify(chunk)}\n`);
      }
    });
  });

  app.post("/computers/:ref/exec/:id/kill", async (c) => {
    await (await running(c.req.param("ref"))).kill(c.req.param("id"));
    return c.json({ ok: true });
  });

  app.get("/computers/:ref/files", async (c) => {
    const data = await (await running(c.req.param("ref"))).readFile(c.req.query("path") ?? "");
    return c.body(Buffer.from(data), 200, { "content-type": "application/octet-stream" });
  });
  app.put("/computers/:ref/files", async (c) => {
    const h = await running(c.req.param("ref"));
    await h.writeFile(c.req.query("path") ?? "", new Uint8Array(await c.req.arrayBuffer()));
    return c.json({ ok: true });
  });
  app.delete("/computers/:ref/files", async (c) => {
    await (await running(c.req.param("ref"))).deleteFile(c.req.query("path") ?? "");
    return c.json({ ok: true });
  });
  app.get("/computers/:ref/files/list", async (c) =>
    c.json({ entries: await (await running(c.req.param("ref"))).listDir(c.req.query("path") ?? "") }),
  );
  app.post("/computers/:ref/files/search", async (c) => {
    const body = (await c.req.json()) as { query: string; path?: string };
    return c.json({ matches: await (await running(c.req.param("ref"))).search(body.query, body.path) });
  });

  app.post("/computers/:ref/checkpoints", async (c) => {
    const { label } = (await c.req.json()) as { label: string };
    return c.json(await (await running(c.req.param("ref"))).checkpoint(label ?? "checkpoint"), 201);
  });
  app.post("/computers/:ref/checkpoints/restore", async (c) => {
    const cp = (await c.req.json()) as Parameters<Awaited<ReturnType<typeof running>>["restore"]>[0];
    await (await running(c.req.param("ref"))).restore(cp);
    return c.json({ ok: true });
  });
  app.post("/objects/delete", async (c) => {
    if (c.req.header("authorization") !== `Bearer ${token}`) return c.json({ code: "unauthorized" }, 401);
    const { keys } = (await c.req.json()) as { keys: string[] };
    for (const k of keys) await provider.opts.store.delete(k);
    return c.json({ ok: true });
  });

  app.get("/computers/:ref/health", async (c) => c.json(await (await running(c.req.param("ref"))).health()));
  app.get("/computers/:ref/screenshot", async (c) =>
    c.body(Buffer.from(await (await running(c.req.param("ref"))).screenshot()), 200, { "content-type": "image/png" }),
  );
  app.post("/computers/:ref/input", async (c) => {
    await (await running(c.req.param("ref"))).input(await c.req.json());
    return c.json({ ok: true });
  });

  return app;
}

/** Proxies terminal WebSockets: client <-> supervisor <-> computerd. */
export function attachTerminalProxy(server: Server, provider: DockerProvider, token: string) {
  const wss = new WebSocketServer({ noServer: true });
  server.on("upgrade", async (req: IncomingMessage, socket: Duplex, head: Buffer) => {
    const url = new URL(req.url ?? "/", "http://supervisor");
    const ref = url.pathname.match(/^\/computers\/([\w-]+)\/terminal$/)?.[1];
    if (!ref || req.headers.authorization !== `Bearer ${token}`) {
      socket.end("HTTP/1.1 401 Unauthorized\r\n\r\n");
      return;
    }
    const h = await provider.get(ref).catch(() => null);
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
      upstream.on("message", (data, binary) => client.readyState === WebSocket.OPEN && client.send(data as Buffer, { binary }));
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

export function startSupervisor(provider: DockerProvider, token: string, port: number) {
  const app = createSupervisorApp(provider, token);
  const server = serve({ fetch: app.fetch, port, hostname: "0.0.0.0" }) as Server;
  attachTerminalProxy(server, provider, token);
  return server;
}
