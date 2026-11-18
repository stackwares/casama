import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { afterEach, describe, expect, it } from "vitest";
import { LocalProvider } from "../src/local.ts";
import { SandboxError } from "../src/types.ts";

// A stand-in for the API's /internal/local/{ref}/status: offline for the first `offlineFor` checks.
async function statusServer(offlineFor: number) {
  let checks = 0;
  const server = createServer((_req, res) => {
    checks++;
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify({ online: checks > offlineFor }));
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  const { port } = server.address() as AddressInfo;
  return { server, url: `http://127.0.0.1:${port}`, checks: () => checks };
}

let server: Server | undefined;
afterEach(() => server?.close());

describe("local provider reconnect grace", () => {
  it("waits for a device that dials back after an API restart", async () => {
    const s = await statusServer(2);
    server = s.server;
    const p = new LocalProvider({ apiUrl: s.url, internalToken: "t", reconnectGraceMs: 5000 });
    const h = await p.resume("dev-1");
    expect(h).toBeTruthy();
    expect(s.checks()).toBe(3);
  });

  it("says offline once the grace period is over", async () => {
    const s = await statusServer(Number.POSITIVE_INFINITY);
    server = s.server;
    const p = new LocalProvider({ apiUrl: s.url, internalToken: "t", reconnectGraceMs: 1500 });
    const err = await p.resume("dev-1").catch((e: unknown) => e);
    expect(err).toBeInstanceOf(SandboxError);
    expect((err as SandboxError).code).toBe("device_offline");
    expect(s.checks()).toBeGreaterThanOrEqual(2);
  });

  it("doesn't wait when the grace period is zero", async () => {
    const s = await statusServer(Number.POSITIVE_INFINITY);
    server = s.server;
    const p = new LocalProvider({ apiUrl: s.url, internalToken: "t", reconnectGraceMs: 0 });
    await expect(p.resume("dev-1")).rejects.toThrow(/offline/);
    expect(s.checks()).toBe(1);
  });

  it("checking whether it's online never waits", async () => {
    const s = await statusServer(Number.POSITIVE_INFINITY);
    server = s.server;
    const p = new LocalProvider({ apiUrl: s.url, internalToken: "t", reconnectGraceMs: 5000 });
    expect(await p.get("dev-1")).toBeNull();
    expect(s.checks()).toBe(1);
  });
});
