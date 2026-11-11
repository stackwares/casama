import type { Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { dockerAvailable, type SandboxStack, startSandboxStack } from "@casama/sandbox/testing";
import { serve } from "@hono/node-server";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { WebSocket } from "ws";
import { attachTerminal } from "../src/api/routes/computers.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const enabled = (await dockerAvailable()) && process.env.SKIP_DOCKER_TESTS !== "1";
const FIXTURES = fileURLToPath(new URL("./fixtures/computer.json", import.meta.url));

describe.skipIf(!enabled)("computers (Phase 2 gate)", () => {
  let stack: SandboxStack;
  let h: Harness;
  let owner: { id: string; token: string };
  let orgId: string;
  let computerId: string;
  let botId: string;

  beforeAll(async () => {
    stack = await startSandboxStack();
    h = await startHarness({ worker: { fixtures: FIXTURES }, sandbox: stack });
    owner = await h.user("computer-owner@example.com");
    orgId = (
      await j(
        await h.request("/v1/orgs", {
          method: "POST",
          token: owner.token,
          json: { name: "Computer Org" },
        }),
      )
    ).id;
    const cred = await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          provider: "openrouter",
          label: "k",
          api_key: "sk-computer-test-key",
        },
      }),
    );
    botId = (
      await j(
        await h.request("/v1/bots", {
          method: "POST",
          token: owner.token,
          json: {
            org_id: orgId,
            name: "Researcher",
            model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
          },
        }),
      )
    ).id;
  }, 180_000);
  afterAll(async () => {
    await h?.stop();
    await stack?.stop();
  }, 180_000);

  async function chat(text: string) {
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: owner.token,
        json: { bot_id: botId },
      }),
    );
    const sent = await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text },
      }),
    );
    for (let i = 0; i < 600; i++) {
      const run = await j(await h.request(`/v1/runs/${sent.run_id}`, { token: owner.token }));
      if (["completed", "failed", "cancelled"].includes(run.status)) {
        const events = await j(
          await h.request(`/v1/runs/${sent.run_id}/events?limit=1000`, { token: owner.token }),
        );
        return {
          run,
          events: events.items as Array<{ type: string; payload: Record<string, unknown> }>,
        };
      }
      await new Promise((r) => setTimeout(r, 200));
    }
    throw new Error("run did not finish");
  }

  const download = async (path: string) =>
    (
      await h.request(`/v1/computers/${computerId}/files?path=${encodeURIComponent(path)}`, {
        token: owner.token,
      })
    ).text();

  it("every org has a team computer, stopped until first use", async () => {
    const list = await j(await h.request(`/v1/computers?org_id=${orgId}`, { token: owner.token }));
    expect(list.items).toHaveLength(1);
    expect(list.items[0]).toMatchObject({ kind: "team", state: "stopped", has_snapshot: false });
    computerId = list.items[0].id;
  });

  it("a bot researches a web page and writes a report file", async () => {
    const { run, events } = await chat("Please research example.com and write a short report.");
    expect(
      run.status,
      JSON.stringify(events.filter((e) => e.type.startsWith("tool") || e.type === "run.failed")),
    ).toBe("completed");
    const types = events.map((e) => e.type);
    expect(types).toContain("computer.state");
    expect(events.filter((e) => e.type === "tool.started").map((e) => e.payload.tool)).toEqual([
      "browser.open",
      "browser.read",
      "shell.exec",
    ]);
    expect(types).toContain("tool.output");
    // The bot runs on the team computer, so its files are in its own folder (D-148).
    const report = await download("bots/researcher/report.md");
    expect(report).toContain("# Research report: example.com");
    expect(report).toContain("Example Domain");
  }, 240_000);

  it("checkpoints automatically before destructive commands, and restoring reverts files", async () => {
    await h.request(`/v1/computers/${computerId}/files?path=bots/researcher/old/keep.txt`, {
      method: "PUT",
      token: owner.token,
      body: "important",
      headers: { "content-type": "application/octet-stream" },
    });
    const { events } = await chat("Please clean up the old folder.");
    const cp = events.find((e) => e.type === "checkpoint.created");
    expect(cp?.payload.label).toMatch(/^Before: rm -rf old/);
    expect(
      (
        await h.request(`/v1/computers/${computerId}/files?path=bots/researcher/old/keep.txt`, {
          token: owner.token,
        })
      ).status,
    ).toBe(404);

    const list = await j(
      await h.request(`/v1/computers/${computerId}/checkpoints`, { token: owner.token }),
    );
    expect(list.items[0].id).toBe(cp?.payload.checkpoint_id);
    const restored = await h.request(
      `/v1/computers/${computerId}/checkpoints/${cp?.payload.checkpoint_id}/restore`,
      {
        method: "POST",
        token: owner.token,
      },
    );
    expect(restored.status).toBe(200);
    expect(await download("bots/researcher/old/keep.txt")).toBe("important");
  }, 240_000);

  it("uploads, lists and deletes files", async () => {
    const up = await h.request(`/v1/computers/${computerId}/files?path=uploads/a.txt`, {
      method: "PUT",
      token: owner.token,
      body: "hello file",
      headers: { "content-type": "application/octet-stream" },
    });
    expect(await j(up)).toEqual({ path: "uploads/a.txt", size: 10 });
    const list = await j(
      await h.request(`/v1/computers/${computerId}/files/list?path=uploads`, {
        token: owner.token,
      }),
    );
    expect(list.entries.map((e: { name: string }) => e.name)).toEqual(["a.txt"]);
    expect(
      (
        await h.request(`/v1/computers/${computerId}/files?path=uploads`, {
          method: "DELETE",
          token: owner.token,
        })
      ).status,
    ).toBe(200);
  }, 60_000);

  it("opens an interactive terminal over WebSocket", async () => {
    const server = serve({ fetch: h.app.fetch, port: 0 }) as unknown as Server;
    await new Promise((r) => server.once("listening", r));
    attachTerminal(server, {
      computers: h.computers,
      db: h.handle.db,
      verifyToken: (await import("../src/api/auth.ts")).createTokenVerifier({
        supabaseUrl: "http://127.0.0.1:54321",
        jwtSecret: (await import("./helpers.ts")).JWT_SECRET,
      }),
    } as never);
    const port = (server.address() as AddressInfo).port;
    try {
      const ws = new WebSocket(
        `ws://127.0.0.1:${port}/v1/computers/${computerId}/terminal?access_token=${owner.token}`,
      );
      let output = "";
      await new Promise<void>((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error(`no terminal output: ${output}`)), 20_000);
        ws.on("open", () => ws.send(Buffer.from("echo TERM-$((6*7))\n"), { binary: true }));
        ws.on("message", (d) => {
          output += d.toString();
          if (output.includes("TERM-42")) {
            clearTimeout(timer);
            resolve();
          }
        });
        ws.on("error", reject);
      });
      ws.close();
      const denied = new WebSocket(
        `ws://127.0.0.1:${port}/v1/computers/${computerId}/terminal?access_token=bad`,
      );
      await new Promise<void>((resolve) => {
        denied.on("error", () => resolve());
        denied.on("unexpected-response", () => resolve());
      });
    } finally {
      server.close();
    }
  }, 60_000);

  it("sleeps when idle and restores files on the next use", async () => {
    await h.request(`/v1/computers/${computerId}/files?path=persist.txt`, {
      method: "PUT",
      token: owner.token,
      body: "survives sleep",
      headers: { "content-type": "application/octet-stream" },
    });
    const slept = await h.computers?.sleepIdle(0);
    expect(slept).toContain(computerId);
    const after = await j(await h.request(`/v1/computers/${computerId}`, { token: owner.token }));
    expect(after).toMatchObject({ state: "sleeping", has_snapshot: true });
    const [usage] = await h.tdb.admin<
      { n: string }[]
    >`select coalesce(sum(quantity), 0) as n from public.usage_ledger where kind = 'computer_seconds' and org_id = ${orgId}`;
    expect(Number(usage?.n)).toBeGreaterThan(0);
    const started = await j(
      await h.request(`/v1/computers/${computerId}/start`, { method: "POST", token: owner.token }),
    );
    expect(started.state).toBe("running");
    expect(await download("persist.txt")).toBe("survives sleep");
    expect(await download("bots/researcher/report.md")).toContain("Example Domain");

    // The list reports what the sandbox really is, even if the stored state drifted.
    await h.tdb.admin`update public.computers set state = 'sleeping' where id = ${computerId}`;
    const listed = await j(
      await h.request(`/v1/computers?org_id=${orgId}`, { token: owner.token }),
    );
    expect(listed.items.find((x: { id: string }) => x.id === computerId)?.state).toBe("running");
  }, 240_000);

  it("hides computers from other organizations", async () => {
    const stranger = await h.user("computer-stranger@example.com");
    expect((await h.request(`/v1/computers/${computerId}`, { token: stranger.token })).status).toBe(
      404,
    );
    expect(
      (await h.request(`/v1/computers/${computerId}/files/list`, { token: stranger.token })).status,
    ).toBe(404);
    expect(
      (
        await h.request(`/v1/computers/${computerId}/start`, {
          method: "POST",
          token: stranger.token,
        })
      ).status,
    ).toBe(404);
  });
});
