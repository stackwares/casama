/**
 * Local stand-ins for the E2B and Daytona control planes, for tests. Each "sandbox" is a local
 * container of Kasama's computer image; requests use the real REST shapes the adapters send
 * (D-057), and every request is recorded so tests can check authentication headers.
 */
import { execFile } from "node:child_process";
import { randomBytes } from "node:crypto";
import { createServer, type IncomingMessage, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { promisify } from "node:util";

const run = promisify(execFile);
const docker = async (...args: string[]) => (await run("docker", args)).stdout.trim();

interface MockSandbox {
  id: string;
  container: string;
  labels: Record<string, string>;
  state: "started" | "destroyed";
}

export interface MockControlPlane {
  url: string;
  kind: "e2b" | "daytona";
  apiKey: string;
  requests: Array<{ method: string; path: string; headers: IncomingMessage["headers"] }>;
  /** Where a sandbox port is reachable from this machine. */
  portUrl(id: string, port: number): Promise<string>;
  stop(): Promise<void>;
}

const body = async (req: IncomingMessage) => {
  let s = "";
  for await (const c of req) s += c;
  return s ? (JSON.parse(s) as Record<string, unknown>) : {};
};

export async function startMockControlPlane(opts: {
  kind: "e2b" | "daytona";
  images: { headless: string; desktop: string };
  /** Docker network the sandboxes join (to reach the test TURN relay). */
  network?: string;
  prefix?: string;
}): Promise<MockControlPlane> {
  const apiKey = `test-${randomBytes(12).toString("hex")}`;
  const prefix = opts.prefix ?? `km${randomBytes(3).toString("hex")}`;
  const sandboxes = new Map<string, MockSandbox>();
  const requests: MockControlPlane["requests"] = [];
  const previewTokens = new Map<string, string>();

  const portUrl = async (id: string, port: number) => {
    const sb = sandboxes.get(id);
    if (!sb) throw new Error(`no sandbox ${id}`);
    const out = await docker("port", sb.container, `${port}/tcp`);
    return `http://127.0.0.1:${out.split("\n")[0]?.split(":").pop()}`;
  };

  const start = async (
    template: string,
    env: Record<string, string>,
    labels: Record<string, string>,
  ) => {
    const id = `sb${randomBytes(6).toString("hex")}`;
    const container = `${prefix}-${id}`;
    const image = template.includes("desktop") ? opts.images.desktop : opts.images.headless;
    await docker(
      "run",
      "-d",
      "--name",
      container,
      "--label",
      "dev.kasama.test=1",
      ...(opts.network ? ["--network", opts.network] : []),
      "-p",
      "127.0.0.1::7070",
      "-p",
      "127.0.0.1::8080",
      ...Object.entries(env).flatMap(([k, v]) => ["-e", `${k}=${v}`]),
      image,
    );
    const sb: MockSandbox = { id, container, labels, state: "started" };
    sandboxes.set(id, sb);
    return sb;
  };
  const kill = async (id: string) => {
    const sb = sandboxes.get(id);
    if (!sb) return false;
    sb.state = "destroyed";
    await docker("rm", "-f", sb.container).catch(() => {});
    sandboxes.delete(id);
    return true;
  };

  const server: Server = createServer(async (req, res) => {
    const url = new URL(req.url ?? "/", "http://mock");
    requests.push({ method: req.method ?? "GET", path: url.pathname, headers: req.headers });
    const json = (status: number, data: unknown) => {
      res.writeHead(status, { "content-type": "application/json" });
      res.end(data === undefined ? "" : JSON.stringify(data));
    };
    const authed =
      opts.kind === "e2b"
        ? req.headers["x-api-key"] === apiKey
        : req.headers.authorization === `Bearer ${apiKey}`;
    if (!authed) return json(401, { message: "unauthorized" });
    try {
      const seg = url.pathname.split("/").filter(Boolean);
      if (opts.kind === "e2b") {
        if (req.method === "POST" && url.pathname === "/sandboxes") {
          const b = await body(req);
          const sb = await start(
            String(b.templateID),
            (b.envVars ?? {}) as Record<string, string>,
            (b.metadata ?? {}) as Record<string, string>,
          );
          return json(201, {
            sandboxID: sb.id,
            templateID: b.templateID,
            clientID: "mock",
            domain: null,
          });
        }
        if (req.method === "GET" && url.pathname === "/sandboxes") {
          const [k, v] = (url.searchParams.get("metadata") ?? "").split("=");
          return json(
            200,
            [...sandboxes.values()]
              .filter((s) => !k || s.labels[k] === v)
              .map((s) => ({ sandboxID: s.id, state: "running", metadata: s.labels })),
          );
        }
        if (req.method === "DELETE" && seg[0] === "sandboxes" && seg[1])
          return json((await kill(seg[1])) ? 204 : 404, undefined);
        if (req.method === "POST" && seg[0] === "sandboxes" && seg[2] === "timeout")
          return json(sandboxes.has(seg[1] ?? "") ? 204 : 404, undefined);
      } else {
        if (req.method === "POST" && url.pathname === "/sandbox") {
          const b = await body(req);
          const sb = await start(
            String(b.snapshot),
            (b.env ?? {}) as Record<string, string>,
            (b.labels ?? {}) as Record<string, string>,
          );
          return json(200, { id: sb.id, state: "creating", labels: sb.labels });
        }
        if (req.method === "GET" && url.pathname === "/sandbox") {
          const filter = JSON.parse(url.searchParams.get("labels") ?? "{}") as Record<
            string,
            string
          >;
          return json(
            200,
            [...sandboxes.values()]
              .filter((s) => Object.entries(filter).every(([k, v]) => s.labels[k] === v))
              .map((s) => ({ id: s.id, state: s.state, labels: s.labels })),
          );
        }
        if (
          req.method === "GET" &&
          seg[0] === "sandbox" &&
          seg[2] === "ports" &&
          seg[4] === "preview-url"
        ) {
          const id = seg[1] ?? "";
          const token = randomBytes(8).toString("hex");
          previewTokens.set(`${id}:${seg[3]}`, token);
          return json(200, { url: await portUrl(id, Number(seg[3])), token, sandboxId: id });
        }
        if (req.method === "GET" && seg[0] === "sandbox" && seg[1]) {
          const sb = sandboxes.get(seg[1]);
          return sb
            ? json(200, { id: sb.id, state: sb.state, labels: sb.labels })
            : json(404, { message: "not found" });
        }
        if (req.method === "DELETE" && seg[0] === "sandbox" && seg[1])
          return json((await kill(seg[1])) ? 200 : 404, {});
      }
      json(404, { message: `no route ${req.method} ${url.pathname}` });
    } catch (err) {
      json(500, { message: (err as Error).message });
    }
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  const url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  return {
    url,
    kind: opts.kind,
    apiKey,
    requests,
    portUrl,
    async stop() {
      for (const id of [...sandboxes.keys()]) await kill(id);
      await new Promise((r) => server.close(r));
    },
  };
}
