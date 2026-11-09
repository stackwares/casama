import { lookup } from "node:dns/promises";
import { createServer, type IncomingMessage, request as httpRequest, type Server, type ServerResponse } from "node:http";
import { isIP, connect, type Socket } from "node:net";
import { type DomainRules, domainAllowed, isBlocked, makeBlockList, makeExemptList } from "./policy.ts";

export interface ComputerRegistration {
  ref: string;
  token: string;
  rules?: DomainRules;
  /** New outbound connections per minute. */
  connectionsPerMinute?: number;
  /** Bytes per minute, both directions. */
  bytesPerMinute?: number;
}

export interface ProxyOptions {
  /** Extra CIDRs to block, for example the internal service network. */
  blockedCidrs?: string[];
  /** Addresses exempt from blocking. Only for tests and local development; leave empty in production. */
  exemptCidrs?: string[];
  /** Token for the control API (registering computers). */
  controlToken: string;
  resolve?: (host: string) => Promise<string[]>;
  log?: (event: Record<string, unknown>) => void;
}

interface Usage {
  windowStart: number;
  connections: number;
  bytes: number;
}

/**
 * Egress proxy: the only route out of a computer's network.
 * Forward proxy (absolute-URI HTTP and CONNECT) with per-computer auth, private-range blocking
 * on resolved addresses (connecting to the vetted IP defeats DNS rebinding), domain rules and rate limits.
 */
export class EgressProxy {
  readonly computers = new Map<string, ComputerRegistration>();
  private readonly usage = new Map<string, Usage>();
  private readonly blockList;
  private readonly exempt;
  private readonly resolve;
  private readonly log;
  private readonly controlToken;

  constructor(opts: ProxyOptions) {
    this.blockList = makeBlockList(opts.blockedCidrs);
    this.exempt = opts.exemptCidrs?.length ? makeExemptList(opts.exemptCidrs) : null;
    this.controlToken = opts.controlToken;
    this.resolve = opts.resolve ?? (async (host: string) => (await lookup(host, { all: true, verbatim: true })).map((a) => a.address));
    this.log = opts.log ?? (() => {});
  }

  // --- auth, limits, policy -------------------------------------------------

  private authenticate(req: IncomingMessage): ComputerRegistration | null {
    const header = req.headers["proxy-authorization"];
    if (!header?.startsWith("Basic ")) return null;
    const [ref, token] = Buffer.from(header.slice(6), "base64").toString().split(":");
    const c = ref ? this.computers.get(ref) : undefined;
    return c && token && c.token === token ? c : null;
  }

  private meter(c: ComputerRegistration, connections: number, bytes: number) {
    const now = Date.now();
    let u = this.usage.get(c.ref);
    if (!u || now - u.windowStart >= 60_000) {
      u = { windowStart: now, connections: 0, bytes: 0 };
      this.usage.set(c.ref, u);
    }
    u.connections += connections;
    u.bytes += bytes;
    return (
      u.connections <= (c.connectionsPerMinute ?? 600) && u.bytes <= (c.bytesPerMinute ?? 2 * 1024 * 1024 * 1024)
    );
  }

  /** Resolves and vets a destination; returns the address to connect to. */
  async vet(c: ComputerRegistration, host: string): Promise<{ ok: true; address: string } | { ok: false; reason: string }> {
    const bare = host.replace(/^\[|\]$/g, "");
    if (!domainAllowed(bare, c.rules ?? {})) return { ok: false, reason: "domain_not_allowed" };
    let addresses: string[];
    try {
      addresses = isIP(bare) ? [bare] : await this.resolve(bare);
    } catch {
      return { ok: false, reason: "dns_failed" };
    }
    if (addresses.length === 0) return { ok: false, reason: "dns_failed" };
    // Refuse if any address is internal: a mixed answer is a rebinding attempt.
    const blocked = (a: string) => isBlocked(this.blockList, a) && !(this.exempt && isBlocked(this.exempt, a));
    if (addresses.some(blocked)) return { ok: false, reason: "blocked_address" };
    return { ok: true, address: addresses[0] as string };
  }

  // --- servers --------------------------------------------------------------

  /** The proxy server computers use (HTTP_PROXY / HTTPS_PROXY). */
  createProxyServer(): Server {
    const server = createServer((req, res) => void this.handleHttp(req, res));
    server.on("connect", (req, socket: Socket, head) => void this.handleConnect(req, socket, head));
    return server;
  }

  private deny(c: ComputerRegistration | null, target: string, reason: string) {
    this.log({ event: "egress_denied", computer: c?.ref ?? null, target, reason });
  }

  private async handleConnect(req: IncomingMessage, socket: Socket, head: Buffer) {
    socket.on("error", () => {});
    const c = this.authenticate(req);
    const target = req.url ?? "";
    if (!c) {
      socket.end("HTTP/1.1 407 Proxy Authentication Required\r\nProxy-Authenticate: Basic realm=\"kasama\"\r\n\r\n");
      return this.deny(null, target, "unauthenticated");
    }
    const m = target.match(/^(\[[^\]]+\]|[^:]+):(\d+)$/);
    if (!m) return void socket.end("HTTP/1.1 400 Bad Request\r\n\r\n");
    const [, host = "", port = "443"] = m;
    if (!this.meter(c, 1, 0)) {
      socket.end("HTTP/1.1 429 Too Many Requests\r\n\r\n");
      return this.deny(c, target, "rate_limited");
    }
    const verdict = await this.vet(c, host);
    if (!verdict.ok) {
      socket.end(`HTTP/1.1 403 Forbidden\r\nX-Kasama-Egress: ${verdict.reason}\r\n\r\n`);
      return this.deny(c, target, verdict.reason);
    }
    const upstream = connect({ host: verdict.address, port: Number(port) }, () => {
      socket.write("HTTP/1.1 200 Connection Established\r\n\r\n");
      if (head.length) upstream.write(head);
      socket.pipe(upstream);
      upstream.pipe(socket);
    });
    const count = (b: Buffer) => {
      if (!this.meter(c, 0, b.length)) {
        this.deny(c, target, "bandwidth_limited");
        socket.destroy();
        upstream.destroy();
      }
    };
    socket.on("data", count);
    upstream.on("data", count);
    upstream.on("error", () => socket.destroy());
    socket.on("close", () => upstream.destroy());
  }

  private async handleHttp(req: IncomingMessage, res: ServerResponse) {
    const c = this.authenticate(req);
    if (!c) {
      res.writeHead(407, { "proxy-authenticate": 'Basic realm="kasama"' }).end();
      return this.deny(null, req.url ?? "", "unauthenticated");
    }
    let url: URL;
    try {
      url = new URL(req.url ?? "");
      if (url.protocol !== "http:") throw new Error("only http");
    } catch {
      return void res.writeHead(400).end("absolute http:// URL required");
    }
    if (!this.meter(c, 1, 0)) {
      res.writeHead(429).end();
      return this.deny(c, url.host, "rate_limited");
    }
    const verdict = await this.vet(c, url.hostname);
    if (!verdict.ok) {
      res.writeHead(403, { "x-kasama-egress": verdict.reason }).end(`Blocked by egress policy: ${verdict.reason}\n`);
      return this.deny(c, url.host, verdict.reason);
    }
    const headers = { ...req.headers };
    delete headers["proxy-authorization"];
    delete headers["proxy-connection"];
    headers.host = url.host;
    const upstream = httpRequest(
      { host: verdict.address, port: Number(url.port || 80), method: req.method, path: `${url.pathname}${url.search}`, headers },
      (up) => {
        res.writeHead(up.statusCode ?? 502, up.headers);
        up.on("data", (b: Buffer) => this.meter(c, 0, b.length));
        up.pipe(res);
      },
    );
    upstream.on("error", () => {
      if (!res.headersSent) res.writeHead(502).end("upstream error");
      else res.destroy();
    });
    req.pipe(upstream);
  }

  /** Control API for the supervisor: register and unregister computers. */
  createControlServer(): Server {
    return createServer(async (req, res) => {
      if (req.headers.authorization !== `Bearer ${this.controlToken}`) return void res.writeHead(401).end();
      const url = new URL(req.url ?? "/", "http://control");
      const json = (status: number, body: unknown) => res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(body));
      if (req.method === "GET" && url.pathname === "/healthz") return json(200, { ok: true, computers: this.computers.size });
      const ref = url.pathname.match(/^\/computers\/([\w-]+)$/)?.[1];
      if (!ref) return json(404, { code: "not_found" });
      if (req.method === "PUT") {
        const chunks: Buffer[] = [];
        for await (const c of req) chunks.push(c as Buffer);
        const body = JSON.parse(Buffer.concat(chunks).toString() || "{}") as Omit<ComputerRegistration, "ref">;
        if (!body.token || body.token.length < 16) return json(400, { code: "bad_request", message: "token required" });
        this.computers.set(ref, { ...body, ref });
        return json(200, { ok: true });
      }
      if (req.method === "DELETE") {
        this.computers.delete(ref);
        this.usage.delete(ref);
        return json(200, { ok: true });
      }
      json(405, { code: "method_not_allowed" });
    });
  }
}
