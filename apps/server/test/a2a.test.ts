/** Agent-to-agent (D-140): a published bot serves A2A v1.0; another bot calls it as an a2a integration. */
import { fileURLToPath } from "node:url";
import { A2aClient } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/a2a.json", import.meta.url));
let h: Harness;
let base = "";

beforeAll(async () => {
  h = await startHarness({
    serve: true,
    worker: { fixtures: FIXTURES, egressExemptCidrs: ["127.0.0.1/32"] },
  });
  base = h.serverUrl as string;
}, 90_000);
afterAll(async () => h?.stop());

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

async function workspace(email: string, name: string) {
  const u = await h.user(email);
  const orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: u.token, json: { name } }))
  ).id;
  const cred = (
    await j(
      await h.request("/v1/credentials", {
        method: "POST",
        token: u.token,
        json: { org_id: orgId, provider: "openrouter", label: "m", api_key: "sk-or-a2a-key" },
      }),
    )
  ).id;
  const bot = await j(
    await h.request("/v1/bots", {
      method: "POST",
      token: u.token,
      json: {
        org_id: orgId,
        name,
        model_policy: { primary: { credential_id: cred, model: "fixture-main" } },
      },
    }),
  );
  return { u, orgId, bot };
}

describe("agent-to-agent", () => {
  it("publishes a bot, serves its agent card and runs A2A tasks; another bot hands it a task", async () => {
    const a = await workspace("planner@example.com", "Planner");
    // Off by default: no card, and publishing needs the workspace switch.
    expect((await fetch(`${base}/a2a/${a.bot.id}/.well-known/agent-card.json`)).status).toBe(404);
    expect(
      (
        await h.request(`/v1/bots/${a.bot.id}/a2a`, {
          method: "PUT",
          token: a.u.token,
          json: { published: true },
        })
      ).status,
    ).toBe(409);
    await h.request(`/v1/orgs/${a.orgId}/settings`, {
      method: "PATCH",
      token: a.u.token,
      json: { a2a_enabled: true },
    });
    const pub = await j(
      await h.request(`/v1/bots/${a.bot.id}/a2a`, {
        method: "PUT",
        token: a.u.token,
        json: { published: true },
      }),
    );
    expect(pub).toMatchObject({ workspace_enabled: true, published: true });

    const card = await (await fetch(`${base}/a2a/${a.bot.id}/.well-known/agent-card.json`)).json();
    expect(card).toMatchObject({
      name: "Planner",
      supportedInterfaces: [
        { url: `${base}/a2a/${a.bot.id}`, protocolBinding: "JSONRPC", protocolVersion: "1.0" },
      ],
    });

    // Calls need a workspace API key.
    const noKey = await fetch(`${base}/a2a/${a.bot.id}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "GetTask", params: { id: "x" } }),
    });
    expect(noKey.status).toBe(401);
    const key = (
      await j(
        await h.request(`/v1/orgs/${a.orgId}/mcp-keys`, {
          method: "POST",
          token: a.u.token,
          json: { name: "A2A partner" },
        }),
      )
    ).key as string;

    // An outside A2A client gets a task done (blocking SendMessage), then reads it back.
    const client = new A2aClient({ url: `${base}/a2a/${a.bot.id}`, token: key });
    const r = await client.send("Summarize the launch plan");
    expect(r.task?.status.state).toBe("TASK_STATE_COMPLETED");
    expect(r.text).toBe("The launch is Tuesday at 9am; docs are ready and support is staffed.");
    const again = await client.rpc<{ id: string; status: { state: string } }>("GetTask", {
      id: r.task!.id,
    });
    expect(again.status.state).toBe("TASK_STATE_COMPLETED");
    const list = await client.rpc<{ tasks: unknown[] }>("ListTasks", { contextId: r.contextId });
    expect(list.tasks).toHaveLength(1);
    await expect(client.rpc("GetTask", { id: crypto.randomUUID() })).rejects.toMatchObject({
      code: -32001,
    });
    await expect(client.rpc("FlyToTheMoon", {})).rejects.toMatchObject({ code: -32601 });
    const [run] = await h.tdb.admin<
      { trigger: string; created_by: string }[]
    >`select r.trigger, r.created_by from public.a2a_tasks t join public.runs r on r.id = t.run_id where t.id = ${r.task!.id}`;
    expect(run).toMatchObject({ trigger: "a2a", created_by: a.u.id });
    expect(
      await h.tdb
        .admin`select 1 from public.audit_log where action = 'a2a.task' and org_id = ${a.orgId}`,
    ).toHaveLength(1);

    // A bot elsewhere adds the planner as an A2A integration and hands it a task.
    const b = await workspace("asker@example.com", "Asker");
    const integ = await h.request("/v1/integrations", {
      method: "POST",
      token: b.u.token,
      json: {
        org_id: b.orgId,
        kind: "a2a",
        name: "planner",
        config: { url: `${base}/a2a/${a.bot.id}` },
        secret: key,
      },
    });
    expect(integ.status).toBe(201);
    const integration = await j(integ);
    const test = await j(
      await h.request(`/v1/integrations/${integration.id}/test`, {
        method: "POST",
        token: b.u.token,
      }),
    );
    expect(test).toEqual({ ok: true, tools: ["send"] });
    await h.request(`/v1/bots/${b.bot.id}/integrations`, {
      method: "POST",
      token: b.u.token,
      json: { integration_id: integration.id },
    });
    const conv = await j(
      await h.request("/v1/conversations", {
        method: "POST",
        token: b.u.token,
        json: { bot_id: b.bot.id },
      }),
    );
    const runId = (
      await j(
        await h.request(`/v1/conversations/${conv.id}/messages`, {
          method: "POST",
          token: b.u.token,
          json: { text: "Ask the planner agent about the launch" },
        }),
      )
    ).run_id;
    await waitFor(
      async () =>
        (await j(await h.request(`/v1/runs/${runId}`, { token: b.u.token }))).status ===
        "completed",
      "asker run",
      60_000,
    );
    const evs = (
      await j(await h.request(`/v1/runs/${runId}/events?limit=200`, { token: b.u.token }))
    ).items as Array<{ type: string; payload: Record<string, unknown> }>;
    expect(evs.find((e) => e.type === "tool.completed")?.payload.result_preview).toContain(
      "The launch is Tuesday at 9am",
    );
    expect(
      await h.tdb.admin`select 1 from public.a2a_tasks where bot_id = ${a.bot.id}`,
    ).toHaveLength(2);

    // Turning A2A off unpublishes the bot.
    await h.request(`/v1/orgs/${a.orgId}/settings`, {
      method: "PATCH",
      token: a.u.token,
      json: { a2a_enabled: false },
    });
    expect((await fetch(`${base}/a2a/${a.bot.id}/.well-known/agent-card.json`)).status).toBe(404);
  }, 120_000);
});
