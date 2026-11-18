/**
 * Cancelling a command: hanging up computerd's exec stream doesn't stop the process, so the
 * client kills it by id (a cancelled run used to leave a coding agent working on the computer).
 */
import { createServer, type Server, type ServerResponse } from "node:http";
import type { AddressInfo } from "node:net";
import { afterEach, describe, expect, it } from "vitest";
import { ComputerdClient } from "../src/computerd-client.ts";

let server: Server | undefined;
afterEach(() => server?.close());

/** A computerd that starts an endless command and records kill calls. */
async function fakeComputerd() {
  const kills: string[] = [];
  const streams: ServerResponse[] = [];
  server = createServer((req, res) => {
    if (req.method === "POST" && req.url === "/exec") {
      res.writeHead(200, { "content-type": "application/x-ndjson", "x-exec-id": "x1-42" });
      res.write(`${JSON.stringify({ type: "start", exec_id: "x1-42" })}\n`);
      res.write(`${JSON.stringify({ type: "stdout", data: "working…\n" })}\n`);
      streams.push(res); // never ends on its own
      return;
    }
    const kill = /^\/exec\/([^/]+)\/kill$/.exec(req.url ?? "");
    if (req.method === "POST" && kill) {
      kills.push(decodeURIComponent(kill[1] as string));
      for (const s of streams)
        s.end(
          `${JSON.stringify({ type: "exit", code: 137, timed_out: false, killed: true, truncated: false })}\n`,
        );
      return res.writeHead(200, { "content-type": "application/json" }).end("{}");
    }
    res.writeHead(404).end();
  }).listen(0, "127.0.0.1");
  await new Promise((r) => server?.once("listening", r));
  const url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  return { client: new ComputerdClient(url, "t"), kills };
}

const until = async (ok: () => boolean) => {
  for (let i = 0; i < 100 && !ok(); i++) await new Promise((r) => setTimeout(r, 10));
};

describe("exec cancel", () => {
  it("kills the command when the caller's signal aborts", async () => {
    const { client, kills } = await fakeComputerd();
    const ctrl = new AbortController();
    const seen: string[] = [];
    const reading = (async () => {
      for await (const c of client.exec("claude -p 'long task'", { signal: ctrl.signal }))
        seen.push(c.type);
    })().catch(() => {});
    await until(() => seen.includes("stdout"));
    ctrl.abort(new Error("cancelled"));
    await reading;
    await until(() => kills.length > 0);
    expect(kills).toEqual(["x1-42"]);
  });

  it("kills the command when the reader stops early", async () => {
    const { client, kills } = await fakeComputerd();
    for await (const c of client.exec("sleep 999")) if (c.type === "stdout") break;
    await until(() => kills.length > 0);
    expect(kills).toEqual(["x1-42"]);
  });

  it("doesn't kill a command that finished", async () => {
    const kills: string[] = [];
    server = createServer((req, res) => {
      if (req.url === "/exec") {
        res.writeHead(200, { "content-type": "application/x-ndjson", "x-exec-id": "x2-1" });
        res.end(
          `${JSON.stringify({ type: "start", exec_id: "x2-1" })}\n${JSON.stringify({ type: "exit", code: 0, timed_out: false, killed: false, truncated: false })}\n`,
        );
        return;
      }
      kills.push(req.url ?? "");
      res.end("{}");
    }).listen(0, "127.0.0.1");
    await new Promise((r) => server?.once("listening", r));
    const client = new ComputerdClient(
      `http://127.0.0.1:${(server.address() as AddressInfo).port}`,
      "t",
    );
    const ctrl = new AbortController();
    for await (const _ of client.exec("true", { signal: ctrl.signal })) {
      // drain
    }
    ctrl.abort();
    await new Promise((r) => setTimeout(r, 50));
    expect(kills).toEqual([]);
  });
});
