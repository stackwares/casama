import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import {
  decodeStreamRelay,
  encodeStreamRelay,
  STREAM_RELAY_HEADER,
  type StreamRelay,
  SupervisorProvider,
} from "@casama/sandbox";
import { describe, expect, it } from "vitest";
import { WebSocket, WebSocketServer } from "ws";
import { attachStreamProxy } from "../src/app.ts";

/**
 * Casama Link, live view away from the computer (D-296): the API hands the supervisor a relay
 * outside the server for the streamer to use too. It travels in a header on the stream's
 * WebSocket, never in the address.
 */
describe("a relay outside the server, from the API to the computer", () => {
  const TOKEN = "supervisor-token-0123456789";
  const relay: StreamRelay = {
    urls: ["turn:turn.cloudflare.com:3478?transport=udp"],
    username: "outside-user",
    credential: "outside-secret",
    key: "0123456789abcdef",
  };

  it("survives the trip in a header, and nonsense is ignored", () => {
    expect(decodeStreamRelay(encodeStreamRelay(relay))).toEqual(relay);
    expect(decodeStreamRelay(undefined)).toBeUndefined();
    expect(decodeStreamRelay("not-base64-json")).toBeUndefined();
    expect(decodeStreamRelay(["a", "b"])).toBeUndefined();
    const partial = Buffer.from(JSON.stringify({ ...relay, key: "" })).toString("base64url");
    expect(decodeStreamRelay(partial)).toBeUndefined();
  });

  it("the supervisor passes it to the computer's streamer", async () => {
    // The computer's streamer: a WebSocket that says hello.
    const streamer = new WebSocketServer({ port: 0 });
    await new Promise((r) => streamer.once("listening", r));
    streamer.on("connection", (ws) => ws.send("hello"));
    const asked: Array<{ mode?: string; relay?: StreamRelay }> = [];
    const provider = {
      get: async () => ({
        streamEndpoint: async (opts: { mode?: string; relay?: StreamRelay }) => {
          asked.push(opts);
          return {
            url: `ws://127.0.0.1:${(streamer.address() as AddressInfo).port}`,
            headers: {},
          };
        },
        stopStream: async () => {},
      }),
    } as never;
    const server = createServer();
    const proxy = attachStreamProxy(server, provider, TOKEN, { idleStopMs: 10 });
    server.on("upgrade", (req, socket, head) => void proxy(req, socket, head));
    await new Promise<void>((r) => server.listen(0, "127.0.0.1", () => r()));
    const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;

    const open = async (opts: { mode: "view" | "control"; relay?: StreamRelay }) => {
      // What the API does: the supervisor client builds the address and headers.
      const target = await new SupervisorProvider(base, TOKEN)
        .handle("11111111-2222-4333-8444-555555555555")
        .streamEndpoint(opts);
      expect(target.url).not.toContain("outside");
      const ws = new WebSocket(target.url, { headers: target.headers });
      const first = await new Promise<string>((resolve, reject) => {
        ws.once("message", (d) => resolve(String(d)));
        ws.once("error", reject);
      });
      ws.close();
      return { first, headers: target.headers };
    };

    try {
      const away = await open({ mode: "control", relay });
      expect(away.first).toBe("hello");
      expect(away.headers[STREAM_RELAY_HEADER]).toBeTruthy();
      const home = await open({ mode: "view" });
      expect(home.headers[STREAM_RELAY_HEADER]).toBeUndefined();
      expect(asked).toEqual([
        { mode: "control", relay },
        { mode: "view", relay: undefined },
      ]);
    } finally {
      server.close();
      streamer.close();
    }
  });
});
