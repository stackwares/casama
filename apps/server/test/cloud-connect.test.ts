import { fileURLToPath } from "node:url";
import { dockerAvailable, type SandboxStack, startSandboxStack } from "@kasama/sandbox/testing";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { billingEnv, type FakeBilling, startFakeBilling } from "./fake-billing.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const enabled = (await dockerAvailable()) && process.env.SKIP_DOCKER_TESTS !== "1";
const FIXTURES = fileURLToPath(new URL("./fixtures/cloud.json", import.meta.url));

/**
 * Phase 7 gate: a self-hosted instance runs a bot on a Kasama Cloud computer with a Cloud Connect
 * key, and the usage shows on the cloud workspace's bill. Two servers share one test database (as
 * separate workspaces): the "cloud" API with billing and a real sandbox supervisor, and the
 * "self-hosted" API and worker with no sandbox of their own.
 */
describe.skipIf(!enabled)("Cloud Connect (Phase 7 gate)", () => {
  let stack: SandboxStack;
  let f: FakeBilling;
  let cloud: Harness;
  let home: Harness;
  let cloudOwner: { token: string };
  let cloudOrg: string;
  let key: string;
  let homeOwner: { token: string };
  let botId: string;
  let computerId: string;

  beforeAll(async () => {
    stack = await startSandboxStack();
    f = await startFakeBilling();
    cloud = await startHarness({
      serve: true,
      env: billingEnv(f),
      connect: {
        supervisor: { url: stack.supervisorUrl, token: stack.token },
        models: { url: `${f.url}/models`, key: "upstream-key" },
      },
    });
    cloudOwner = await cloud.user("cloud-connect-owner@example.com");
    cloudOrg = (
      await j(
        await cloud.request("/v1/orgs", {
          method: "POST",
          token: cloudOwner.token,
          json: { name: "Cloud account" },
        }),
      )
    ).id;
    const created = await cloud.request(`/v1/orgs/${cloudOrg}/cloud-connect/keys`, {
      method: "POST",
      token: cloudOwner.token,
      json: { instance_name: "home-server" },
    });
    expect(created.status).toBe(201);
    key = (await j(created)).key;

    home = await startHarness({
      worker: { fixtures: FIXTURES },
      env: { KASAMA_CLOUD_URL: cloud.serverUrl as string, KASAMA_CLOUD_KEY: key },
      cloud: { url: cloud.serverUrl as string, key },
    });
    homeOwner = await home.user("selfhoster@example.com");
    const homeOrg = (
      await j(
        await home.request("/v1/orgs", {
          method: "POST",
          token: homeOwner.token,
          json: { name: "Home lab" },
        }),
      )
    ).id;
    const cred = await j(
      await home.request("/v1/credentials", {
        method: "POST",
        token: homeOwner.token,
        json: { org_id: homeOrg, provider: "openrouter", label: "k", api_key: "sk-home-key" },
      }),
    );
    botId = (
      await j(
        await home.request("/v1/bots", {
          method: "POST",
          token: homeOwner.token,
          json: {
            org_id: homeOrg,
            name: "Homebot",
            autonomy: "autonomous",
            model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
          },
        }),
      )
    ).id;
    const comp = await home.request("/v1/computers", {
      method: "POST",
      token: homeOwner.token,
      json: {
        org_id: homeOrg,
        kind: "private",
        owner_bot_id: botId,
        name: "Cloud box",
        provider: "kasama-cloud",
      },
    });
    expect(comp.status).toBe(201);
    computerId = (await j(comp)).id;
    await home.handle.db.execute(
      sql`update public.bots set default_computer_id = ${computerId}::uuid where id = ${botId}::uuid`,
    );
  }, 300_000);

  afterAll(async () => {
    await home?.stop();
    await cloud?.stop();
    await f?.stop();
    await stack?.stop();
  }, 180_000);

  it("rejects requests without a valid key", async () => {
    expect((await fetch(`${cloud.serverUrl}/connect/v1/whoami`)).status).toBe(401);
    const bad = await fetch(`${cloud.serverUrl}/connect/v1/whoami`, {
      headers: { authorization: "Bearer kcc_nope" },
    });
    expect(bad.status).toBe(401);
    const who = await (
      await fetch(`${cloud.serverUrl}/connect/v1/whoami`, {
        headers: { authorization: `Bearer ${key}` },
      })
    ).json();
    expect(who).toMatchObject({
      org_id: cloudOrg,
      instance_name: "home-server",
      computers: true,
      models: true,
    });
  });

  it("a self-hosted bot runs a command on a cloud computer and the time shows on the cloud bill", async () => {
    const conv = await j(
      await home.request("/v1/conversations", {
        method: "POST",
        token: homeOwner.token,
        json: { bot_id: botId },
      }),
    );
    const sent = await j(
      await home.request(`/v1/conversations/${conv.id}/messages`, {
        method: "POST",
        token: homeOwner.token,
        json: { text: "Please run a check on the cloud computer." },
      }),
    );
    let run: { status: string } = { status: "queued" };
    for (let i = 0; i < 900 && !["completed", "failed"].includes(run.status); i++) {
      await new Promise((r) => setTimeout(r, 200));
      run = await j(await home.request(`/v1/runs/${sent.run_id}`, { token: homeOwner.token }));
    }
    const events = (
      await j(
        await home.request(`/v1/runs/${sent.run_id}/events?limit=500`, { token: homeOwner.token }),
      )
    ).items as Array<{ type: string; payload: Record<string, unknown> }>;
    expect(
      run.status,
      JSON.stringify(events.filter((e) => e.type.startsWith("tool") || e.type === "run.failed")),
    ).toBe("completed");
    const out = events
      .filter((e) => e.type === "tool.output")
      .map((e) => e.payload.chunk)
      .join("");
    expect(
      out,
      JSON.stringify(
        events.filter((e) => e.type.startsWith("tool") || e.type.startsWith("computer")),
      ),
    ).toContain("cloud-ok-Linux");

    // The computer belongs to the cloud workspace, attributed to the instance.
    const [owned] = await cloud.handle.db.execute<{ org_id: string; instance_name: string }>(
      sql`select org_id, instance_name from public.cloud_connect_computers where ref = ${computerId}`,
    );
    expect(owned).toMatchObject({ org_id: cloudOrg, instance_name: "home-server" });

    // Sleeping it on the self-hosted side closes the metered interval.
    // The self-hosted side puts it to sleep (idle timer); the snapshot goes to cloud storage.
    await home.computers?.sleep(computerId);
    const [state] = await cloud.handle.db.execute<{ running_since: Date | null }>(
      sql`select running_since from public.cloud_connect_computers where ref = ${computerId}`,
    );
    expect(state?.running_since).toBeNull();
    const bill = await j(
      await cloud.request(`/v1/orgs/${cloudOrg}/billing/usage`, { token: cloudOwner.token }),
    );
    const line = bill.items.find(
      (i: { kind: string; instance: string }) =>
        i.kind === "computer_seconds" && i.instance === "home-server",
    );
    expect(line?.quantity).toBeGreaterThan(0);
    expect(line?.cost_usd).toBeGreaterThan(0);
    const before = (
      await j(await cloud.request(`/v1/orgs/${cloudOrg}/billing`, { token: cloudOwner.token }))
    ).credits_usd;
    await cloud.deps.billing?.settle();
    const after = (
      await j(await cloud.request(`/v1/orgs/${cloudOrg}/billing`, { token: cloudOwner.token }))
    ).credits_usd;
    expect(after).toBeLessThan(before);
  }, 300_000);

  it("the key only reaches its own workspace's computers", async () => {
    const other = await cloud.user("someone-else@example.com");
    const otherOrg = (
      await j(
        await cloud.request("/v1/orgs", {
          method: "POST",
          token: other.token,
          json: { name: "Other" },
        }),
      )
    ).id;
    const otherKey = (
      await j(
        await cloud.request(`/v1/orgs/${otherOrg}/cloud-connect/keys`, {
          method: "POST",
          token: other.token,
          json: { instance_name: "intruder", scopes: ["computers"] },
        }),
      )
    ).key;
    const h = { authorization: `Bearer ${otherKey}`, "content-type": "application/json" };
    const peek = await fetch(`${cloud.serverUrl}/connect/v1/sandbox/computers/${computerId}`, {
      headers: h,
    });
    expect(await peek.json()).toEqual({ running: false });
    const exec = await fetch(`${cloud.serverUrl}/connect/v1/sandbox/computers/${computerId}/exec`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({ cmd: "id" }),
    });
    expect(exec.status).toBe(404);
    const steal = await fetch(`${cloud.serverUrl}/connect/v1/sandbox/computers`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({ ref: computerId, profile: "headless" }),
    });
    expect(steal.status).toBe(409);
    const list = await j(
      await fetch(`${cloud.serverUrl}/connect/v1/sandbox/computers`, { headers: h }),
    );
    expect(list.running).toEqual([]);
    // Models are not in this key's scopes.
    const m = await fetch(`${cloud.serverUrl}/connect/v1/models/chat/completions`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({ model: "openai/gpt-6-luna", messages: [] }),
    });
    expect(m.status).toBe(403);
    // Revoked keys stop working.
    const keys = await j(
      await cloud.request(`/v1/orgs/${otherOrg}/cloud-connect/keys`, { token: other.token }),
    );
    await cloud.request(`/v1/orgs/${otherOrg}/cloud-connect/keys/${keys.items[0].id}`, {
      method: "DELETE",
      token: other.token,
    });
    expect((await fetch(`${cloud.serverUrl}/connect/v1/whoami`, { headers: h })).status).toBe(401);
  });

  it("model credits: the proxy streams and bills the upstream's usage, and stops at zero credits", async () => {
    const h = { authorization: `Bearer ${key}`, "content-type": "application/json" };
    const plain = await fetch(`${cloud.serverUrl}/connect/v1/models/chat/completions`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({
        model: "openai/gpt-6-luna",
        messages: [{ role: "user", content: "hi" }],
        reasoning: { effort: "medium" },
      }),
    });
    expect(plain.status).toBe(200);
    expect((await j(plain)).choices[0].message.content).toBe("Hello from the cloud.");
    const streamed = await fetch(`${cloud.serverUrl}/connect/v1/models/chat/completions`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({
        model: "openai/gpt-6-luna",
        stream: true,
        messages: [{ role: "user", content: "hi" }],
      }),
    });
    const text = await streamed.text();
    expect(text).toContain(" the cloud.");
    expect(text).toContain("[DONE]");
    // The upstream got our key and model, with usage reporting on; the client's key never left.
    const last = f.models.calls.at(-1) as Record<string, unknown>;
    expect(last).toMatchObject({
      model: "openai/gpt-6-luna",
      stream_options: { include_usage: true },
    });
    expect(f.models.calls[0]).toMatchObject({ reasoning: { effort: "medium" } });
    await new Promise((r) => setTimeout(r, 200));
    const bill = await j(
      await cloud.request(`/v1/orgs/${cloudOrg}/billing/usage`, { token: cloudOwner.token }),
    );
    const tokens = bill.items.filter(
      (i: { kind: string; instance: string }) =>
        i.kind.startsWith("tokens") && i.instance === "home-server",
    );
    expect(tokens.reduce((a: number, b: { quantity: number }) => a + b.quantity, 0)).toBe(300);
    expect(tokens.reduce((a: number, b: { cost_usd: number }) => a + b.cost_usd, 0)).toBeCloseTo(
      0.0018,
      6,
    );

    // Out of credits: 402.
    await cloud.handle.db.execute(
      sql`select public.credit_apply(${cloudOrg}::uuid, -100, 'adjustment', 'test-drain')`,
    );
    const broke = await fetch(`${cloud.serverUrl}/connect/v1/models/chat/completions`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({ model: "openai/gpt-6-luna", messages: [] }),
    });
    expect(broke.status).toBe(402);
  });
});
