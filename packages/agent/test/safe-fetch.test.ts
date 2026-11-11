import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { createSafeFetch } from "../src/safe-fetch.ts";

let base = "";
const server = createServer((req, res) => {
  if (req.url === "/empty") {
    res.writeHead(204).end();
    return;
  }
  let body = "";
  req.on("data", (c) => (body += c));
  req.on("end", () => {
    res.writeHead(400, { "content-type": "application/json", "x-echo-method": req.method ?? "" });
    res.end(JSON.stringify({ error: "invalid_redirect_uri", sent: body }));
  });
});
beforeAll(async () => {
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
});
afterAll(() => server.close());

describe("safe fetch hands back Node's own Response", () => {
  const f = createSafeFetch({ exemptCidrs: ["127.0.0.1/32"] });

  it("so libraries that check `instanceof Response` read error bodies (the MCP SDK's OAuth code)", async () => {
    const res = await f(`${base}/register`, { method: "POST", body: "hi" });
    expect(res).toBeInstanceOf(Response);
    expect(res.status).toBe(400);
    expect(res.headers.get("content-type")).toBe("application/json");
    expect(await res.json()).toEqual({ error: "invalid_redirect_uri", sent: "hi" });
  });

  it("accepts a Request object, as SDKs pass, and empty responses", async () => {
    const res = await f(new Request(`${base}/token`, { method: "PUT", body: "x" }));
    expect(res.headers.get("x-echo-method")).toBe("PUT");
    expect((await res.json()).sent).toBe("x");
    const empty = await f(`${base}/empty`);
    expect(empty).toBeInstanceOf(Response);
    expect(empty.status).toBe(204);
  });

  it("still refuses private addresses without an exemption", async () => {
    await expect(createSafeFetch()(`${base}/register`)).rejects.toThrow(/blocked/);
  });
});
