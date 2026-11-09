/**
 * A stand-in for the desktop app's companion side: connects to the device WebSocket and answers
 * tunnel requests from a real computerd started in companion mode (D-066).
 */
import { type ChildProcess, execFileSync, spawn } from "node:child_process";
import { existsSync, mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { WebSocket } from "ws";

const COMPUTERD_DIR = fileURLToPath(new URL("../../../dart/computerd", import.meta.url));
let binary: string | undefined;

/** Compiles computerd once per test run. */
export function computerdBinary() {
  if (binary && existsSync(binary)) return binary;
  const out = join(mkdtempSync(join(tmpdir(), "computerd-")), "computerd");
  execFileSync("dart", ["compile", "exe", "bin/computerd.dart", "-o", out], {
    cwd: COMPUTERD_DIR,
    stdio: "ignore",
  });
  binary = out;
  return out;
}

export interface FakeDevice {
  activities: Array<{ run_id: string; bot: string; tool: string; summary: string }>;
  close(): Promise<void>;
}

export async function startFakeDevice(opts: {
  serverUrl: string;
  token: string;
  roots: string[];
  capabilities: string[];
}): Promise<FakeDevice> {
  const port = 17000 + Math.floor(Math.random() * 2000);
  const cdToken = "fake-device-computerd-token-0123";
  const proc: ChildProcess = spawn(computerdBinary(), [], {
    env: {
      ...process.env,
      COMPUTERD_TOKEN: cdToken,
      COMPUTERD_PORT: String(port),
      COMPUTERD_ADDRESS: "127.0.0.1",
      COMPUTERD_HOME: opts.roots[0],
      COMPUTERD_ALLOWED_ROOTS: opts.roots.join(":"),
      COMPUTERD_CAPABILITIES: opts.capabilities.join(","),
    },
    stdio: "ignore",
  });
  const local = `http://127.0.0.1:${port}`;
  for (let i = 0; ; i++) {
    try {
      if ((await fetch(`${local}/health`)).ok) break;
    } catch {}
    if (i > 100) throw new Error("computerd did not start");
    await new Promise((r) => setTimeout(r, 100));
  }
  const ws = new WebSocket(`${opts.serverUrl.replace("http", "ws")}/v1/local-computer/connect`, {
    headers: { authorization: `Device ${opts.token}` },
  });
  const activities: FakeDevice["activities"] = [];
  const aborts = new Map<string, AbortController>();
  await new Promise<void>((resolve, reject) => {
    ws.once("message", () => resolve());
    ws.once("error", reject);
    ws.once("unexpected-response", (_q, r) => reject(new Error(`connect refused ${r.statusCode}`)));
  });
  ws.on("message", async (raw) => {
    const m = JSON.parse(String(raw)) as {
      type: string;
      id: string;
      method: string;
      path: string;
      headers: Record<string, string>;
      body?: string;
      activity?: FakeDevice["activities"][number];
    };
    if (m.type === "cancel") return aborts.get(m.id)?.abort();
    if (m.type !== "request") return;
    if (m.activity) activities.push(m.activity);
    const ctrl = new AbortController();
    aborts.set(m.id, ctrl);
    try {
      const res = await fetch(`${local}${m.path}`, {
        method: m.method,
        headers: { ...m.headers, authorization: `Bearer ${cdToken}` },
        body: m.body ? Buffer.from(m.body, "base64") : undefined,
        signal: ctrl.signal,
      });
      ws.send(
        JSON.stringify({
          type: "response",
          id: m.id,
          status: res.status,
          headers: Object.fromEntries(res.headers),
        }),
      );
      if (res.body)
        for await (const chunk of res.body as unknown as AsyncIterable<Uint8Array>)
          ws.send(
            JSON.stringify({
              type: "chunk",
              id: m.id,
              data: Buffer.from(chunk).toString("base64"),
            }),
          );
      ws.send(JSON.stringify({ type: "end", id: m.id }));
    } catch (err) {
      ws.send(JSON.stringify({ type: "error", id: m.id, message: (err as Error).message }));
    } finally {
      aborts.delete(m.id);
    }
  });
  return {
    activities,
    async close() {
      ws.close();
      proc.kill();
    },
  };
}
