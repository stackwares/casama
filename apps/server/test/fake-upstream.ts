import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { vi } from "vitest";
import { WebSocket, WebSocketServer } from "ws";

/**
 * A computer without Docker for the live-view and terminal proxies: its stream and terminal
 * endpoints are one local websocket server that records every frame it receives, and touches
 * are counted (D-195 keep-awake tests).
 */
export async function fakeComputer() {
  const upstream = new WebSocketServer({ port: 0 });
  await new Promise((r) => upstream.once("listening", r));
  const received: Array<{ data: string; binary: boolean }> = [];
  upstream.on("connection", (ws) =>
    ws.on("message", (data, binary) => received.push({ data: String(data), binary })),
  );
  const url = `ws://127.0.0.1:${(upstream.address() as AddressInfo).port}`;
  const touch = vi.fn(async (_id: string) => {});
  const handle = {
    streamEndpoint: async () => ({ url, headers: {} }),
    terminalEndpoint: async () => ({ url, headers: {} }),
  };
  const computers = { ensureRunning: async () => handle, touch };
  return { computers, touch, received, close: () => upstream.close() };
}

/** An HTTP server for the proxy under test, and a client socket that resolves once open. */
export async function proxyServer(attach: (server: Server) => void) {
  const server = createServer();
  attach(server);
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", () => r()));
  const base = `ws://127.0.0.1:${(server.address() as AddressInfo).port}`;
  const connect = async (path: string) => {
    const ws = new WebSocket(`${base}${path}`);
    await new Promise((resolve, reject) => {
      ws.once("open", resolve);
      ws.once("error", reject);
    });
    return ws;
  };
  return { connect, close: () => server.close() };
}

/** Lets in-flight websocket frames arrive. */
export const settle = (ms = 150) => new Promise((r) => setTimeout(r, ms));
