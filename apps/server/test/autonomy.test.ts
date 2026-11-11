import { once } from "node:events";
import { createServer, type IncomingMessage, type Server, type ServerResponse } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { RecordingPushSender } from "@casama/agent";
import { DBOS } from "@dbos-inc/dbos-sdk";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { z } from "zod";
import { signBody } from "../src/worker/routines.ts";
import { routinesTickWorkflow } from "../src/worker/workflows.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/autonomy.json", import.meta.url));
const push = new RecordingPushSender();
let services: Server;
let servicesUrl: string;
let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let credId: string;

async function startServices() {
  const json = (res: ServerResponse, status: number, data: unknown) =>
    res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(data));
  services = createServer(async (req: IncomingMessage, res) => {
    const chunks: Buffer[] = [];
    for await (const c of req) chunks.push(c as Buffer);
    const raw = Buffer.concat(chunks).toString();
    const url = new URL(req.url ?? "/", "http://x");
    if (url.pathname === "/mcp") {
      const server = new McpServer({ name: "calc", version: "1.0.0" });
      server.registerTool(
        "add",
        { description: "Add two numbers", inputSchema: { a: z.number(), b: z.number() } },
        async ({ a, b }) => ({
          content: [{ type: "text", text: String(a + b) }],
        }),
      );
      const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
      res.on("close", () => void transport.close());
      await server.connect(transport);
      return transport.handleRequest(req, res, raw ? JSON.parse(raw) : undefined);
    }
    if (url.pathname === "/fal-ai/flux-2/klein/4b")
      return json(res, 200, {
        images: [{ url: `${servicesUrl}/img.png`, content_type: "image/png" }],
      });
    json(res, 404, {});
  }).listen(0, "127.0.0.1");
  await once(services, "listening");
  servicesUrl = `http://127.0.0.1:${(services.address() as AddressInfo).port}`;
}

const waitFor = async <T>(
  fn: () => Promise<T | undefined | null | false>,
  what: string,
  ms = 30_000,
): Promise<T> => {
  const until = Date.now() + ms;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > until) throw new Error(`timed out waiting for ${what}`);
    await new Promise((r) => setTimeout(r, 100));
  }
};

const runStatus = async (runId: string) =>
  (await j(await h.request(`/v1/runs/${runId}`, { token: owner.token }))).status as string;
const events = async (runId: string) =>
  (await j(await h.request(`/v1/runs/${runId}/events?limit=1000`, { token: owner.token })))
    .items as Array<{ type: string; payload: Record<string, unknown> }>;

async function makeBot(name: string, autonomy = "ask_risky", extra: object = {}) {
  return j(
    await h.request("/v1/bots", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name,
        autonomy,
        model_policy: { primary: { credential_id: credId, model: "fixture-main" } },
        ...extra,
      },
    }),
  );
}

async function chat(botId: string, text: string) {
  const conv = await j(
    await h.request("/v1/conversations", {
      method: "POST",
      token: owner.token,
      json: { bot_id: botId },
    }),
  );
  return (
    await j(
      await h.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: owner.token,
        json: { text },
      }),
    )
  ).run_id as string;
}

beforeAll(async () => {
  await startServices();
  h = await startHarness({
    worker: {
      fixtures: FIXTURES,
      push,
      egressExemptCidrs: ["127.0.0.1/32"],
      providerBases: { fal: servicesUrl },
    },
  });
  owner = await h.user("phase4@example.com");
  await h.tdb
    .admin`update public.profiles set timezone = 'America/Chicago' where user_id = ${owner.id}`;
  await h.tdb
    .admin`insert into public.devices (user_id, platform, fcm_token) values (${owner.id}, 'android', 'phone-token')`;
  orgId = (
    await j(
      await h.request("/v1/orgs", {
        method: "POST",
        token: owner.token,
        json: { name: "Phase Four" },
      }),
    )
  ).id;
  credId = (
    await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, provider: "openrouter", label: "m", api_key: "sk-or-phase4-key" },
      }),
    )
  ).id;
}, 90_000);
afterAll(async () => {
  services?.close();
  await h?.stop();
});

describe("Phase 4 gate", () => {
  it("a daily 08:00 routine in the owner's timezone runs and pushes its result", async () => {
    const bot = await makeBot("Briefer");
    const created = await j(
      await h.request("/v1/routines", {
        method: "POST",
        token: owner.token,
        json: {
          bot_id: bot.id,
          name: "Morning summary",
          instructions: "Prepare the morning summary.",
          schedule_cron: "0 8 * * *",
        },
      }),
    );
    expect(created).toMatchObject({
      timezone: "America/Chicago",
      trigger: "schedule",
      enabled: true,
    });
    const next = new Date(created.next_run_at);
    const chicagoHour = Number(
      new Intl.DateTimeFormat("en-US", {
        timeZone: "America/Chicago",
        hour: "numeric",
        hour12: false,
      }).format(next),
    );
    expect(chicagoHour).toBe(8);
    expect(next.getUTCMinutes()).toBe(0);

    // Make it due and let the scheduler tick (normally every minute).
    await h.tdb
      .admin`update public.routines set next_run_at = now() - interval '1 minute' where id = ${created.id}`;
    const before = push.sent.length;
    await (await DBOS.startWorkflow(routinesTickWorkflow)(new Date(), null)).getResult();
    const [routine] = await h.tdb.admin<
      { last_run_id: string; next_run_at: Date }[]
    >`select last_run_id, next_run_at from public.routines where id = ${created.id}`;
    expect(routine?.last_run_id).toBeTruthy();
    await waitFor(
      async () => (await runStatus(routine!.last_run_id)) === "completed",
      "routine run",
    );
    const pushed = await waitFor(
      async () => push.sent.slice(before).find((p) => p.message.title.includes("Morning summary")),
      "routine push",
    );
    expect(pushed.tokens).toEqual(["phone-token"]);
    expect(pushed.message.body).toContain("Three things changed overnight");
    expect(pushed.message.link).toContain(`/bots/${bot.id}/chat`);
    // The next run is tomorrow at 08:00 Chicago time.
    expect(new Date(routine!.next_run_at).getTime()).toBeGreaterThan(Date.now());
  }, 60_000);

  it("a one-time routine runs once, then switches itself off; routines can be deleted", async () => {
    const bot = await makeBot("Reminder");
    const runAt = new Date(Date.now() + 60_000).toISOString();
    const created = await j(
      await h.request("/v1/routines", {
        method: "POST",
        token: owner.token,
        json: {
          bot_id: bot.id,
          name: "Water",
          instructions: "Remind me to drink water.",
          trigger: "once",
          run_at: runAt,
        },
      }),
    );
    expect(created).toMatchObject({ trigger: "once", schedule_cron: null, enabled: true });
    expect(new Date(created.next_run_at).toISOString()).toBe(runAt);
    // A time in the past is refused.
    const past = await h.request("/v1/routines", {
      method: "POST",
      token: owner.token,
      json: {
        bot_id: bot.id,
        name: "Late",
        instructions: "x",
        trigger: "once",
        run_at: "2020-01-01T00:00:00Z",
      },
    });
    expect(past.status).toBe(400);

    await h.tdb
      .admin`update public.routines set next_run_at = now() - interval '1 minute' where id = ${created.id}`;
    await (await DBOS.startWorkflow(routinesTickWorkflow)(new Date(), null)).getResult();
    // A second tick must not run it again.
    await (
      await DBOS.startWorkflow(routinesTickWorkflow)(new Date(Date.now() + 120_000), null)
    ).getResult();
    const [row] = await h.tdb.admin<{ enabled: boolean; next_run_at: Date | null; runs: number }[]>`
      select enabled, next_run_at, (select count(*)::int from public.runs where routine_id = ${created.id}) as runs
      from public.routines where id = ${created.id}`;
    expect(row).toMatchObject({ enabled: false, next_run_at: null, runs: 1 });

    const del = await h.request(`/v1/routines/${created.id}`, {
      method: "DELETE",
      token: owner.token,
    });
    expect(del.status).toBe(200);
    const list = await j(await h.request(`/v1/bots/${bot.id}/routines`, { token: owner.token }));
    expect(list.items).toEqual([]);
    // Someone outside the workspace can't delete routines.
    const stranger = await h.user("routine-stranger@example.com");
    const other = await j(
      await h.request("/v1/routines", {
        method: "POST",
        token: owner.token,
        json: { bot_id: bot.id, name: "Keep", instructions: "x", schedule_cron: "0 8 * * *" },
      }),
    );
    expect(
      (await h.request(`/v1/routines/${other.id}`, { method: "DELETE", token: stranger.token }))
        .status,
    ).toBe(404);
  }, 60_000);

  let riskyBot: (name: string) => Promise<{ id: string }> = async (name: string) => {
    // An MCP tool whose risk an admin raised to high.
    const integ = await j(
      await h.request("/v1/integrations", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, kind: "mcp", name: "risky", config: { url: `${servicesUrl}/mcp` } },
      }),
    );
    await h.tdb
      .admin`update public.integrations set risk_overrides = '{"add": "high"}' where id = ${integ.id}`;
    riskyBot = async (n: string) => {
      const b = await makeBot(n);
      await h.request(`/v1/bots/${b.id}/integrations`, {
        method: "POST",
        token: owner.token,
        json: { integration_id: integ.id },
      });
      return b;
    };
    return riskyBot(name);
  };

  it("a high-risk tool waits for approval; approving through the API resumes the run", async () => {
    const bot = await riskyBot("Cleaner");
    const runId = await chat(bot.id, "Please clean the system folder");
    await waitFor(async () => (await runStatus(runId)) === "waiting_approval", "waiting_approval");
    const pending = await j(
      await h.request(`/v1/approvals?org_id=${orgId}&status=pending`, { token: owner.token }),
    );
    const approval = pending.items.find((a: { run_id: string }) => a.run_id === runId);
    expect(approval).toMatchObject({ tool_name: "mcp.risky.add", risk: "high", status: "pending" });
    expect(approval.summary).toContain("Cleaner wants to run mcp.risky.add");
    expect(push.sent.some((p) => p.message.link === `/approvals/${approval.id}`)).toBe(true);

    const decided = await h.request(`/v1/approvals/${approval.id}/decision`, {
      method: "POST",
      token: owner.token,
      json: { decision: "approved" },
    });
    expect(await j(decided)).toMatchObject({ status: "approved" });
    await waitFor(
      async () => (await runStatus(runId)) === "completed",
      "run to finish after approval",
    );
    const evs = await events(runId);
    expect(evs.map((e) => e.type)).toEqual(
      expect.arrayContaining(["approval.requested", "approval.resolved"]),
    );
    expect(evs.find((e) => e.type === "tool.completed")?.payload.result_preview).toBe("3");
    const again = await h.request(`/v1/approvals/${approval.id}/decision`, {
      method: "POST",
      token: owner.token,
      json: { decision: "denied" },
    });
    expect(again.status).toBe(409);
  }, 60_000);

  it("denying an approval cancels that step only", async () => {
    const bot = await riskyBot("Cleaner2");
    const runId = await chat(bot.id, "Please clean the system folder");
    await waitFor(async () => (await runStatus(runId)) === "waiting_approval", "waiting_approval");
    const pending = await j(
      await h.request(`/v1/approvals?org_id=${orgId}&status=pending`, { token: owner.token }),
    );
    const approval = pending.items.find((a: { run_id: string }) => a.run_id === runId);
    await h.request(`/v1/approvals/${approval.id}/decision`, {
      method: "POST",
      token: owner.token,
      json: { decision: "denied" },
    });
    await waitFor(
      async () => (await runStatus(runId)) === "completed",
      "run to finish after denial",
    );
    const evs = await events(runId);
    expect(evs.find((e) => e.type === "tool.failed")?.payload).toMatchObject({
      error_code: "approval_denied",
    });
    expect(evs.find((e) => e.type === "message.completed")).toBeTruthy();
  }, 60_000);

  it("a subagent stops at its budget and the parent receives its summary (child workflow)", async () => {
    const bot = await makeBot("Lead", "ask_risky", { budget: { per_run_usd: 5, daily_usd: 100 } });
    const runId = await chat(bot.id, "Please research with a helper");
    await waitFor(async () => (await runStatus(runId)) === "completed", "parent run", 60_000);
    const done = (await events(runId)).find((e) => e.type === "subrun.completed");
    expect(done?.payload).toMatchObject({ status: "failed" });
    expect(String(done?.payload.summary)).toContain("budget_exceeded");
  }, 90_000);

  it("MCP tools appear and run after adding the server URL", async () => {
    const created = await j(
      await h.request("/v1/integrations", {
        method: "POST",
        token: owner.token,
        json: { org_id: orgId, kind: "mcp", name: "calc", config: { url: `${servicesUrl}/mcp` } },
      }),
    );
    expect(created).toMatchObject({
      status: "ok",
      tools: [expect.objectContaining({ name: "add" })],
    });
    expect(JSON.stringify(created)).not.toContain("vault");
    const bot = await makeBot("Calculator", "autonomous");
    expect(
      (
        await h.request(`/v1/bots/${bot.id}/integrations`, {
          method: "POST",
          token: owner.token,
          json: { integration_id: created.id },
        })
      ).status,
    ).toBe(200);
    const runId = await chat(bot.id, "Please use the calculator");
    await waitFor(async () => (await runStatus(runId)) === "completed", "mcp run");
    const evs = await events(runId);
    expect(evs.find((e) => e.type === "tool.completed")?.payload.result_preview).toBe("42");
    const test = await j(
      await h.request(`/v1/integrations/${created.id}/test`, {
        method: "POST",
        token: owner.token,
      }),
    );
    expect(test).toEqual({ ok: true, tools: ["add"] });
  }, 60_000);

  it("image generation succeeds with a test provider key and is recorded", async () => {
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "fal", label: "fal", api_key: "fal-test-key-123" },
    });
    const bot = await makeBot("Painter", "autonomous");
    const runId = await chat(bot.id, "Please draw a teal robot");
    await waitFor(async () => (await runStatus(runId)) === "completed", "media run");
    expect(
      (await events(runId)).find((e) => e.type === "tool.completed")?.payload.result_preview,
    ).toBe("image generated");
    const usage = await j(
      await h.request(`/v1/usage?org_id=${orgId}&period=day`, { token: owner.token }),
    );
    expect(usage.total_cost_usd).toBeGreaterThan(0);
    const [row] = await h.tdb.admin<
      { n: string }[]
    >`select count(*) as n from public.usage_ledger where run_id = ${runId} and kind = 'media_images'`;
    expect(Number(row?.n)).toBe(1);
  }, 60_000);

  it("a signed custom webhook starts its routine; a bad signature does not", async () => {
    const bot = await makeBot("Reviewer");
    const created = await j(
      await h.request("/v1/routines", {
        method: "POST",
        token: owner.token,
        json: {
          bot_id: bot.id,
          name: "Push review",
          instructions: "Review the pushed commit.",
          trigger: "webhook",
        },
      }),
    );
    expect(created.webhook_url).toContain(`/hooks/custom/${created.id}`);
    expect(created.webhook_secret).toHaveLength(48);
    const body = JSON.stringify({ ref: "refs/heads/main", commits: 1 });
    const bad = await h.request(`/hooks/custom/${created.id}`, {
      method: "POST",
      body,
      headers: { "x-casama-signature": "sha256=deadbeef" },
    });
    expect(bad.status).toBe(202);
    const good = await h.request(`/hooks/custom/${created.id}`, {
      method: "POST",
      body,
      headers: {
        "x-casama-signature": signBody(created.webhook_secret, body),
        "x-casama-event": "push",
      },
    });
    expect(good.status).toBe(202);
    const runId = await waitFor(async () => {
      const [r] = await h.tdb.admin<
        { last_run_id: string | null }[]
      >`select last_run_id from public.routines where id = ${created.id}`;
      return r?.last_run_id;
    }, "webhook run");
    await waitFor(async () => (await runStatus(runId)) === "completed", "webhook run to finish");
    const runs = await h.tdb.admin`select id from public.runs where routine_id = ${created.id}`;
    expect(runs).toHaveLength(1);
  }, 60_000);

  it("secrets are created write-only and templates create a working bot", async () => {
    const secret = await h.request("/v1/secrets", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        name: "GITHUB_TOKEN",
        value: "ghp_not_a_real_token_value",
        allowed_hosts: ["api.github.com"],
      },
    });
    expect(secret.status).toBe(201);
    const body = await secret.text();
    expect(body).not.toContain("ghp_not_a_real_token_value");
    const dup = await h.request("/v1/secrets", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, name: "GITHUB_TOKEN", value: "x", allowed_hosts: ["api.github.com"] },
    });
    expect(dup.status).toBe(409);
    const list = await j(await h.request(`/v1/secrets?org_id=${orgId}`, { token: owner.token }));
    expect(list.items[0]).toMatchObject({
      name: "GITHUB_TOKEN",
      allowed_hosts: ["api.github.com"],
    });

    const templates = await j(await h.request("/v1/templates", { token: owner.token }));
    expect(templates.items.length).toBeGreaterThanOrEqual(20);
    // Each persona carries its instructions, so the app can show and edit them.
    expect(templates.items.find((t: { id: string }) => t.id === "daily-briefing")).toMatchObject({
      category: "work",
      mascot: "sleepy",
    });
    const bot = await makeBot("My briefing", undefined, { template_id: "daily-briefing" });
    expect(bot.persona_md).toContain("briefings");
    const routines = await j(
      await h.request(`/v1/bots/${bot.id}/routines`, { token: owner.token }),
    );
    expect(routines.items[0]).toMatchObject({
      name: "Morning briefing",
      schedule_cron: "0 8 * * *",
      timezone: "America/Chicago",
    });
  });
});
