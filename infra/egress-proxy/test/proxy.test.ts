import { once } from "node:events";
import { createServer, request, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { connect } from "node:net";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { domainAllowed, isBlocked, makeBlockList } from "../src/policy.ts";
import { EgressProxy } from "../src/proxy.ts";

describe("policy", () => {
  const list = makeBlockList(["172.30.0.0/16"]);
  it.each([
    ["169.254.169.254", true],
    ["10.1.2.3", true],
    ["172.16.5.5", true],
    ["192.168.1.1", true],
    ["127.0.0.1", true],
    ["100.64.0.1", true],
    ["0.0.0.0", true],
    ["::1", true],
    ["fe80::1", true],
    ["fd00::1", true],
    ["::ffff:10.0.0.1", true],
    ["::ffff:169.254.169.254", true],
    ["not-an-ip", true],
    ["8.8.8.8", false],
    ["1.1.1.1", false],
    ["2606:4700:4700::1111", false],
  ])("%s blocked=%s", (ip, blocked) => expect(isBlocked(list, ip)).toBe(blocked));

  it("applies allow and deny domain rules", () => {
    expect(domainAllowed("api.github.com", { allow: ["github.com"] })).toBe(true);
    expect(domainAllowed("evil.com", { allow: ["github.com"] })).toBe(false);
    expect(domainAllowed("ads.example.com", { deny: ["example.com"] })).toBe(false);
    expect(domainAllowed("anything.org", {})).toBe(true);
  });
});

describe("proxy", () => {
  let target: Server;
  let targetPort: number;
  let proxyServer: Server;
  let proxyPort: number;
  let control: Server;
  let controlPort: number;
  const DNS: Record<string, string[]> = {
    "public.test": ["127.0.0.1"], // exempt below, stands in for a public site
    "metadata.test": ["169.254.169.254"],
    "rebind.test": ["127.0.0.1", "10.0.0.5"],
  };
  const proxy = new EgressProxy({
    controlToken: "control-token-0123456789",
    exemptCidrs: ["127.0.0.1/32"],
    resolve: async (h) => {
      const r = DNS[h];
      if (!r) throw new Error("NXDOMAIN");
      return r;
    },
  });

  const auth = (ref: string, token: string) =>
    `Basic ${Buffer.from(`${ref}:${token}`).toString("base64")}`;

  function viaProxy(url: string, proxyAuth?: string) {
    return new Promise<{ status: number; body: string; headers: Record<string, unknown> }>(
      (resolve, reject) => {
        const req = request(
          {
            host: "127.0.0.1",
            port: proxyPort,
            method: "GET",
            path: url,
            headers: proxyAuth ? { "proxy-authorization": proxyAuth } : {},
          },
          (res) => {
            let body = "";
            res.on("data", (d) => (body += d));
            res.on("end", () =>
              resolve({ status: res.statusCode ?? 0, body, headers: res.headers }),
            );
          },
        );
        req.on("error", reject);
        req.end();
      },
    );
  }

  function connectVia(target: string, proxyAuth: string) {
    return new Promise<string>((resolve, reject) => {
      const s = connect(proxyPort, "127.0.0.1", () => {
        s.write(
          `CONNECT ${target} HTTP/1.1\r\nHost: ${target}\r\nProxy-Authorization: ${proxyAuth}\r\n\r\n`,
        );
      });
      let data = "";
      s.on("data", (d) => {
        data += d;
        if (data.includes("\r\n\r\n")) {
          resolve(data.split("\r\n")[0] ?? "");
          s.destroy();
        }
      });
      s.on("error", reject);
    });
  }

  beforeAll(async () => {
    target = createServer((req, res) => res.end(`hello from ${req.headers.host}`)).listen(
      0,
      "127.0.0.1",
    );
    await once(target, "listening");
    targetPort = (target.address() as AddressInfo).port;
    DNS["public.test"] = ["127.0.0.1"];
    proxyServer = proxy.createProxyServer().listen(0, "127.0.0.1");
    control = proxy.createControlServer().listen(0, "127.0.0.1");
    await Promise.all([once(proxyServer, "listening"), once(control, "listening")]);
    proxyPort = (proxyServer.address() as AddressInfo).port;
    controlPort = (control.address() as AddressInfo).port;
    const reg = await fetch(`http://127.0.0.1:${controlPort}/computers/c1`, {
      method: "PUT",
      headers: { authorization: "Bearer control-token-0123456789" },
      body: JSON.stringify({ token: "computer-token-0123456789", connectionsPerMinute: 20 }),
    });
    expect(reg.status).toBe(200);
  });
  afterAll(() => {
    target.close();
    proxyServer.close();
    control.close();
  });

  const good = () => auth("c1", "computer-token-0123456789");

  it("requires per-computer auth", async () => {
    expect((await viaProxy(`http://public.test:${targetPort}/`)).status).toBe(407);
    expect(
      (await viaProxy(`http://public.test:${targetPort}/`, auth("c1", "wrong-token-xxxxxxxxxx")))
        .status,
    ).toBe(407);
  });

  it("forwards allowed HTTP requests to the vetted address", async () => {
    const r = await viaProxy(`http://public.test:${targetPort}/x`, good());
    expect(r.status).toBe(200);
    expect(r.body).toBe(`hello from public.test:${targetPort}`);
  });

  it("blocks cloud metadata, private ranges and DNS rebinding", async () => {
    for (const host of ["metadata.test", "169.254.169.254", "10.0.0.1", "rebind.test", "[::1]"]) {
      const r = await viaProxy(`http://${host}/latest/meta-data/`, good());
      expect(r.status, host).toBe(403);
    }
    expect(await connectVia("169.254.169.254:80", good())).toContain("403");
    expect(await connectVia("rebind.test:443", good())).toContain("403");
  });

  it("tunnels CONNECT to allowed hosts", async () => {
    expect(await connectVia(`public.test:${targetPort}`, good())).toContain("200");
  });

  it("rate-limits new connections per computer", async () => {
    let limited = false;
    for (let i = 0; i < 30 && !limited; i++)
      limited = (await viaProxy(`http://public.test:${targetPort}/`, good())).status === 429;
    expect(limited).toBe(true);
  });

  it("protects the control API", async () => {
    expect(
      (await fetch(`http://127.0.0.1:${controlPort}/computers/c2`, { method: "PUT", body: "{}" }))
        .status,
    ).toBe(401);
  });
});

describe("abuse controls (D-094)", () => {
  const reports: Array<{ computer: string; kind: string; target: string }> = [];
  const proxy = new EgressProxy({
    controlToken: "control-token-0123456789",
    exemptCidrs: ["127.0.0.1/32"],
    resolve: async () => ["127.0.0.1"],
    abuse: { report: (computer, kind, target) => reports.push({ computer, kind, target }) },
  });
  proxy.computers.set("c9", {
    ref: "c9",
    token: "computer-token-0123456789",
    connectionsPerMinute: 3,
  });
  let port = 0;
  let server: Server;
  const auth = `Basic ${Buffer.from("c9:computer-token-0123456789").toString("base64")}`;
  const tunnel = (target: string) =>
    new Promise<string>((resolve, reject) => {
      const s = connect(port, "127.0.0.1", () =>
        s.write(
          `CONNECT ${target} HTTP/1.1\r\nHost: ${target}\r\nProxy-Authorization: ${auth}\r\n\r\n`,
        ),
      );
      let data = "";
      s.on("data", (d) => {
        data += d;
        if (data.includes("\r\n\r\n")) {
          resolve(data.split("\r\n")[0] ?? "");
          s.destroy();
        }
      });
      s.on("error", reject);
      s.on("close", () => resolve(data.split("\r\n")[0] ?? ""));
    });

  beforeAll(async () => {
    server = proxy.createProxyServer().listen(0, "127.0.0.1");
    await once(server, "listening");
    port = (server.address() as AddressInfo).port;
  });
  afterAll(() => server.close());

  it("refuses SMTP, Stratum ports and mining pools, and reports them", async () => {
    expect(await tunnel("smtp.example.com:25")).toContain("403");
    expect(await tunnel("example.com:3333")).toContain("403");
    expect(await tunnel("xmr-eu1.nanopool.org:443")).toContain("403");
    expect(reports.map((r) => r.kind)).toEqual(["blocked_port", "mining_pool", "mining_pool"]);
    expect(reports[2]).toEqual({
      computer: "c9",
      kind: "mining_pool",
      target: "xmr-eu1.nanopool.org:443",
    });
  });

  it("reports a connection flood once a minute", async () => {
    reports.length = 0;
    for (let i = 0; i < 8; i++) await tunnel("public.example:443").catch(() => "");
    expect(reports.filter((r) => r.kind === "egress_flood")).toHaveLength(1);
  });
});
