/**
 * Local stand-ins for the E2B and Daytona control planes, for tests. Each "sandbox" is a local
 * container of Kasama's computer image; requests use the real REST shapes the adapters send
 * (D-057), and every request is recorded so tests can check authentication headers.
 */
import { execFile } from "node:child_process";
import { randomBytes } from "node:crypto";
import { createServer, type IncomingMessage, request, type Server } from "node:http";
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
  kind: MockKind;
  apiKey: string;
  requests: Array<{ method: string; path: string; headers: IncomingMessage["headers"] }>;
  /** Where a sandbox port is reachable from this machine. */
  portUrl(id: string, port: number): Promise<string>;
  stop(): Promise<void>;
}

/** Control planes the stand-in speaks (D-057, D-139). */
export type MockKind = "e2b" | "daytona" | "kubernetes" | "incus" | "boat" | "railway";

const body = async (req: IncomingMessage) => {
  let s = "";
  for await (const c of req) s += c;
  return s ? (JSON.parse(s) as Record<string, unknown>) : {};
};

export async function startMockControlPlane(opts: {
  kind: MockKind;
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
    fixedId?: string,
  ) => {
    const id = fixedId ?? `sb${randomBytes(6).toString("hex")}`;
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
      if (opts.kind === "kubernetes") {
        // /api/v1/namespaces/{ns}/pods[/{name}[:{port}/proxy/...]]
        const [, , , ns, kind, name, ...rest] = seg;
        if (seg[0] !== "api" || kind !== "pods" || !ns) return json(404, { message: "no route" });
        if (req.method === "POST" && !name) {
          const b = await body(req);
          const meta = b.metadata as { name: string; labels: Record<string, string> };
          const c = (
            b.spec as {
              containers: Array<{ image: string; env: Array<{ name: string; value: string }> }>;
            }
          ).containers[0]!;
          const sb = await start(
            c.image,
            Object.fromEntries(c.env.map((e) => [e.name, e.value])),
            meta.labels,
            meta.name,
          );
          return json(201, {
            metadata: { name: sb.id, labels: sb.labels },
            status: { phase: "Pending" },
          });
        }
        if (req.method === "GET" && !name) {
          const [k, v] = (url.searchParams.get("labelSelector") ?? "").split("=");
          return json(200, {
            items: [...sandboxes.values()]
              .filter((s) => !k || s.labels[k] === v)
              .map((s) => ({
                metadata: { name: s.id, labels: s.labels },
                status: { phase: "Running", podIP: "10.0.0.9" },
              })),
          });
        }
        const [podName, port] = (name ?? "").split(":");
        if (port && rest[0] === "proxy") {
          // The API server's pod proxy: forward the request (streaming) to the pod's port.
          const target = new URL(await portUrl(podName ?? "", Number(port)));
          const path = `/${rest.slice(1).join("/")}${url.search}`;
          const headers = { ...req.headers, host: target.host };
          delete headers.authorization;
          const up = request(
            { host: target.hostname, port: target.port, method: req.method, path, headers },
            (r) => {
              res.writeHead(r.statusCode ?? 502, r.headers);
              r.pipe(res);
            },
          );
          up.on("error", (e) => json(502, { message: e.message }));
          req.pipe(up);
          return;
        }
        if (req.method === "GET" && podName) {
          const sb = sandboxes.get(podName);
          return sb
            ? json(200, {
                metadata: { name: sb.id, labels: sb.labels },
                status: { phase: "Running", podIP: "10.0.0.9" },
              })
            : json(404, { message: "not found" });
        }
        if (req.method === "DELETE" && podName) return json((await kill(podName)) ? 200 : 404, {});
      }
      if (opts.kind === "incus") {
        // /1.0/instances[/{name}[/state]] and /1.0/operations/{id}/wait
        if (seg[0] === "1.0" && seg[1] === "operations")
          return json(200, { type: "sync", metadata: { status: "Success" } });
        if (seg[0] !== "1.0" || seg[1] !== "instances") return json(404, { message: "no route" });
        const name = seg[2];
        const op = () =>
          json(202, {
            type: "async",
            operation: `/1.0/operations/op${randomBytes(4).toString("hex")}`,
          });
        if (req.method === "POST" && !name) {
          const b = await body(req);
          const config = b.config as Record<string, string>;
          const env = Object.fromEntries(
            Object.entries(config)
              .filter(([k]) => k.startsWith("environment."))
              .map(([k, v]) => [k.slice(12), v]),
          );
          const src = b.source as { alias: string; protocol: string };
          if (src.protocol !== "oci")
            return json(400, { error: "only OCI images in this stand-in" });
          await start(
            src.alias,
            env,
            { "user.kasama_ref": config["user.kasama_ref"] ?? "" },
            String(b.name),
          );
          return op();
        }
        if (req.method === "GET" && !name)
          return json(200, {
            type: "sync",
            metadata: [...sandboxes.values()].map((s) => ({
              name: s.id,
              status: "Running",
              config: s.labels,
            })),
          });
        if (req.method === "PUT" && seg[3] === "state")
          return sandboxes.has(name ?? "") ? op() : json(404, { error: "not found" });
        if (req.method === "DELETE" && name)
          return (await kill(name)) ? op() : json(404, { error: "not found" });
      }
      if (opts.kind === "boat") {
        if (req.method === "POST" && url.pathname === "/sandboxes") {
          const b = await body(req);
          // Boat runs the computer image with Docker inside its VM, from the setup script.
          const image = /docker pull '([^']+)'/.exec(String(b.setupScript))?.[1] ?? "";
          if (!image) return json(400, { error: "setup script doesn't pull an image" });
          const sb = await start(
            image,
            (b.env ?? {}) as Record<string, string>,
            (b.labels ?? {}) as Record<string, string>,
            `bx_${randomBytes(4).toString("hex")}`,
          );
          return json(202, { sandbox: { id: sb.id, state: "starting", labels: sb.labels } });
        }
        if (req.method === "GET" && url.pathname === "/sandboxes") {
          const [k, v] = (url.searchParams.get("label") ?? "").split("=");
          return json(200, {
            sandboxes: [...sandboxes.values()]
              .filter((s) => !k || s.labels[k] === v)
              .map((s) => ({ id: s.id, state: "running", labels: s.labels })),
          });
        }
        if (req.method === "POST" && seg[0] === "sandboxes" && seg[2] === "host") {
          const b = await body(req);
          return json(200, {
            url: await portUrl(seg[1] ?? "", Number(b.port)),
            isProtected: !b.public,
          });
        }
        if (req.method === "DELETE" && seg[0] === "sandboxes" && seg[1])
          return (await kill(seg[1]))
            ? json(202, { operation: { id: "bdop_1" } })
            : json(404, { error: "not found" });
      }
      if (opts.kind === "railway") {
        const b = await body(req);
        const q = String(b.query);
        const v = (b.variables ?? {}) as Record<string, unknown>;
        if (q.includes("serviceCreate")) {
          const input = v.input as {
            name: string;
            source: { image: string };
            variables: Record<string, string>;
          };
          const sb = await start(input.source.image, input.variables, { name: input.name });
          return json(200, { data: { serviceCreate: { id: sb.id, name: input.name } } });
        }
        if (q.includes("serviceInstanceDeployV2"))
          return json(200, { data: { serviceInstanceDeployV2: "dep_1" } });
        if (q.includes("project(id"))
          return json(200, {
            data: {
              project: {
                services: {
                  edges: [...sandboxes.values()].map((s) => ({
                    node: { id: s.id, name: s.labels.name },
                  })),
                },
              },
            },
          });
        if (q.includes("serviceDomainCreate")) {
          const input = v.input as { serviceId: string; targetPort: number };
          return json(200, {
            data: {
              serviceDomainCreate: {
                id: "dom_1",
                domain: (await portUrl(input.serviceId, input.targetPort)).replace(
                  /^http:\/\//,
                  "",
                ),
              },
            },
          });
        }
        if (q.includes("serviceDelete"))
          return (await kill(String(v.id)))
            ? json(200, { data: { serviceDelete: true } })
            : json(200, { errors: [{ message: "Service not found" }] });
        return json(200, { errors: [{ message: "unknown operation" }] });
      }
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
