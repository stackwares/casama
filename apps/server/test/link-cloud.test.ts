import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import { dockerAvailable, type SandboxStack, startSandboxStack } from "@casama/sandbox/testing";
import { sql } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { clampSize } from "../src/billing/link.ts";
import { billingEnv, type FakeBilling, startFakeBilling } from "./fake-billing.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const enabled = (await dockerAvailable()) && process.env.SKIP_DOCKER_TESTS !== "1";
const FIXTURES = fileURLToPath(new URL("./fixtures/cloud.json", import.meta.url));

it("a cloud computer is cut to the plan's size", () => {
  const create = JSON.parse(
    clampSize(
      JSON.stringify({ ref: "r", size: { cpus: 8, memoryMb: 65_536, diskGb: 5 } }),
      true,
      2,
    ) ?? "",
  );
  expect(create).toEqual({ ref: "r", size: { cpus: 2, memoryMb: 2048, diskGb: 5 } });
  expect(
    JSON.parse(clampSize(JSON.stringify({ ref: "r", size: { cpus: 1 } }), true, 2) ?? ""),
  ).toEqual({ ref: "r", size: { cpus: 1, memoryMb: 2048 } });
  const resume = JSON.parse(clampSize(JSON.stringify({ snapshot: { key: "k" } }), false, 1) ?? "");
  expect(resume).toEqual({ snapshot: { key: "k" }, spec: { size: { cpus: 1, memoryMb: 1024 } } });
});

/**
 * Phase 7 gate: a self-hosted instance runs a bot on a Casama Cloud computer with a Casama Link
 * key, and the usage shows on the cloud workspace's bill. Two servers share one test database (as
 * separate workspaces): the "cloud" API with billing and a real sandbox supervisor, and the
 * "self-hosted" API and worker with no sandbox of their own.
 */
describe.skipIf(!enabled)("Casama Link (Phase 7 gate)", () => {
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
      casamaLink: {
        supervisor: { url: stack.supervisorUrl, token: stack.token },
        models: { url: `${f.url}/models`, key: "upstream-key", routing: { sort: "price" } },
      },
    });
    cloudOwner = await cloud.user("casama-link-owner@example.com");
    cloudOrg = (
      await j(
        await cloud.request("/v1/orgs", {
          method: "POST",
          token: cloudOwner.token,
          json: { name: "Cloud account" },
        }),
      )
    ).id;
    const created = await cloud.request(`/v1/orgs/${cloudOrg}/link/keys`, {
      method: "POST",
      token: cloudOwner.token,
      json: { instance_name: "home-server" },
    });
    expect(created.status).toBe(201);
    key = (await j(created)).key;

    home = await startHarness({
      worker: { fixtures: FIXTURES },
      env: { CASAMA_CLOUD_URL: cloud.serverUrl as string, CASAMA_CLOUD_KEY: key },
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
        provider: "casama-cloud",
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
    expect((await fetch(`${cloud.serverUrl}/link/v1/whoami`)).status).toBe(401);
    const bad = await fetch(`${cloud.serverUrl}/link/v1/whoami`, {
      headers: { authorization: "Bearer kcc_nope" },
    });
    expect(bad.status).toBe(401);
    const who = await (
      await fetch(`${cloud.serverUrl}/link/v1/whoami`, {
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
      sql`select org_id, instance_name from public.link_computers where ref = ${computerId}`,
    );
    expect(owned).toMatchObject({ org_id: cloudOrg, instance_name: "home-server" });

    // Sleeping it on the self-hosted side closes the metered interval.
    // The self-hosted side puts it to sleep (idle timer); the snapshot goes to cloud storage.
    await home.computers?.sleep(computerId);
    const [state] = await cloud.handle.db.execute<{ running_since: Date | null }>(
      sql`select running_since from public.link_computers where ref = ${computerId}`,
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
        await cloud.request(`/v1/orgs/${otherOrg}/link/keys`, {
          method: "POST",
          token: other.token,
          json: { instance_name: "intruder", scopes: ["computers"] },
        }),
      )
    ).key;
    const h = { authorization: `Bearer ${otherKey}`, "content-type": "application/json" };
    const peek = await fetch(`${cloud.serverUrl}/link/v1/sandbox/computers/${computerId}`, {
      headers: h,
    });
    expect(await peek.json()).toEqual({ running: false });
    const exec = await fetch(`${cloud.serverUrl}/link/v1/sandbox/computers/${computerId}/exec`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({ cmd: "id" }),
    });
    expect(exec.status).toBe(404);
    const steal = await fetch(`${cloud.serverUrl}/link/v1/sandbox/computers`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({ ref: computerId, profile: "headless" }),
    });
    expect(steal.status).toBe(409);
    const list = await j(
      await fetch(`${cloud.serverUrl}/link/v1/sandbox/computers`, { headers: h }),
    );
    expect(list.running).toEqual([]);
    // Models are not in this key's scopes.
    const m = await fetch(`${cloud.serverUrl}/link/v1/models/chat/completions`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({ model: "openai/gpt-6-luna", messages: [] }),
    });
    expect(m.status).toBe(403);
    // Revoked keys stop working.
    const keys = await j(
      await cloud.request(`/v1/orgs/${otherOrg}/link/keys`, { token: other.token }),
    );
    await cloud.request(`/v1/orgs/${otherOrg}/link/keys/${keys.items[0].id}`, {
      method: "DELETE",
      token: other.token,
    });
    expect((await fetch(`${cloud.serverUrl}/link/v1/whoami`, { headers: h })).status).toBe(401);
  });

  it("plan limits hold through the proxy, and the sweep puts a computer to sleep at zero credits", async () => {
    const db = cloud.handle.db;
    const h = { authorization: `Bearer ${key}`, "content-type": "application/json" };
    // The workspace's plan, with room for computers but one running at once.
    const added: string[] = [];
    const setLimits = async (extra: Record<string, unknown>) => {
      const [row] = await db.execute<{ id: string }>(sql`
        insert into public.entitlements (org_id, plan_code, limits)
        select org_id, plan_code, limits || ${JSON.stringify(extra)}::jsonb from public.entitlements
        where org_id = ${cloudOrg}::uuid order by created_at desc limit 1
        returning id`);
      if (row) added.push(row.id);
    };
    await setLimits({ max_computers: 10, max_running_computers: 1, computer_size: 1 });
    const create = (ref: string, size?: Record<string, number>) =>
      fetch(`${cloud.serverUrl}/link/v1/sandbox/computers`, {
        method: "POST",
        headers: h,
        body: JSON.stringify({ ref, profile: "headless", ...(size ? { size } : {}) }),
      });
    const a = randomUUID();
    const b = randomUUID();
    const first = await create(a, { cpus: 8, memoryMb: 65_536 });
    expect(first.status, await first.clone().text()).toBe(201);
    const [ra] = await db.execute<{ running: boolean }>(
      sql`select running_since is not null as running from public.link_computers where ref = ${a}`,
    );
    expect(ra?.running).toBe(true);

    // max_running_computers: the second is refused, and its ref isn't kept.
    const second = await create(b);
    expect(second.status).toBe(402);
    expect(((await second.json()) as { code: string }).code).toBe("plan_limit");
    expect(
      await db.execute(sql`select 1 from public.link_computers where ref = ${b}`),
    ).toHaveLength(0);

    // computer_hours: past this month's hours, no start, even with room to run.
    await setLimits({ max_running_computers: 5, computer_hours: 1 });
    await db.execute(sql`
      insert into public.usage_ledger (org_id, kind, quantity, cost_usd, billable, meta)
      values (${cloudOrg}::uuid, 'computer_seconds', 3600, 0, false, '{"source":"test"}'::jsonb)`);
    const overHours = await create(b);
    expect(overHours.status).toBe(402);
    expect(((await overHours.json()) as { code: string }).code).toBe("computer_hours_exceeded");
    await setLimits({ computer_hours: null });

    // Zero credits: the sweep puts the running one to sleep, keeps its snapshot, stops the meter.
    await db.execute(
      sql`select public.credit_apply(${cloudOrg}::uuid, -1000, 'adjustment', 'test-sweep-drain')`,
    );
    const swept = await cloud.deps.billing?.sleepLinkComputers({
      url: stack.supervisorUrl,
      token: stack.token,
    });
    expect(swept?.slept).toBe(1);
    const [after] = await db.execute<{ running_since: Date | null; swept_snapshot: unknown }>(
      sql`select running_since, swept_snapshot from public.link_computers where ref = ${a}`,
    );
    expect(after?.running_since).toBeNull();
    expect(after?.swept_snapshot).toMatchObject({ key: expect.stringContaining(a) });
    const there = await fetch(`${stack.supervisorUrl}/computers/${a}`, {
      headers: { authorization: `Bearer ${stack.token}` },
    });
    expect(((await there.json()) as { running: boolean }).running).toBe(false);
    const [billed] = await db.execute<{ n: number; costed: number }>(sql`
      select count(*)::int as n, count(upstream_cost_usd)::int as costed from public.usage_ledger
      where org_id = ${cloudOrg}::uuid and kind = 'computer_seconds' and meta->>'ref' = ${a}`);
    expect(billed?.n).toBeGreaterThan(0);
    // What the computer cost the server is kept next to the charge (D-400).
    expect(billed?.costed).toBe(billed?.n);
    // And it can't wake up again until there are credits.
    const wake = () =>
      fetch(`${cloud.serverUrl}/link/v1/sandbox/computers/${a}/resume`, {
        method: "POST",
        headers: h,
        body: JSON.stringify({}),
      });
    expect((await wake()).status).toBe(402);

    // With credits back, waking it restores from the cloud's snapshot.
    await db.execute(
      sql`select public.credit_apply(${cloudOrg}::uuid, 1000, 'adjustment', 'test-sweep-refill')`,
    );
    const woke = await wake();
    expect(woke.status, await woke.clone().text()).toBe(200);
    const [back] = await db.execute<{ running: boolean; swept_snapshot: unknown }>(sql`
      select running_since is not null as running, swept_snapshot from public.link_computers where ref = ${a}`);
    expect(back).toMatchObject({ running: true, swept_snapshot: null });
    await fetch(`${cloud.serverUrl}/link/v1/sandbox/computers/${a}`, {
      method: "DELETE",
      headers: h,
    });
    for (const id of added)
      await db.execute(sql`delete from public.entitlements where id = ${id}::uuid`);
  }, 300_000);

  it("model credits: the proxy streams and bills the upstream's usage, and stops at zero credits", async () => {
    const h = { authorization: `Bearer ${key}`, "content-type": "application/json" };
    const plain = await fetch(`${cloud.serverUrl}/link/v1/models/chat/completions`, {
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
    const streamed = await fetch(`${cloud.serverUrl}/link/v1/models/chat/completions`, {
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
      // The cloud's routing: the cheapest provider first (D-354).
      provider: { sort: "price" },
    });
    expect(f.models.calls[0]).toMatchObject({ reasoning: { effort: "medium" } });
    // Output is capped (billing audit 2026-11-17): none asked gets the cap, more is cut to it.
    expect(last.max_tokens).toBe(32_768);
    await new Promise((r) => setTimeout(r, 200));
    const bill = await j(
      await cloud.request(`/v1/orgs/${cloudOrg}/billing/usage`, { token: cloudOwner.token }),
    );
    const tokens = bill.items.filter(
      (i: { kind: string; instance: string }) =>
        i.kind.startsWith("tokens") && i.instance === "home-server",
    );
    expect(tokens.reduce((a: number, b: { quantity: number }) => a + b.quantity, 0)).toBe(300);
    // The upstream's $0.0018 at the same price as Casama's own key: OpenRouter's 5.5% fee and the
    // 1.3 markup (D-248).
    expect(tokens.reduce((a: number, b: { cost_usd: number }) => a + b.cost_usd, 0)).toBeCloseTo(
      0.0018 * 1.055 * 1.3,
      5,
    );

    // Asking for more than the cap gets the cap.
    await fetch(`${cloud.serverUrl}/link/v1/models/chat/completions`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({
        model: "openai/gpt-6-luna",
        max_tokens: 10_000_000,
        messages: [{ role: "user", content: "hi" }],
      }),
    }).then((r) => r.text());
    expect((f.models.calls.at(-1) as Record<string, unknown>).max_tokens).toBe(32_768);

    // Out of credits: 402.
    await cloud.handle.db.execute(
      sql`select public.credit_apply(${cloudOrg}::uuid, -100, 'adjustment', 'test-drain')`,
    );
    const broke = await fetch(`${cloud.serverUrl}/link/v1/models/chat/completions`, {
      method: "POST",
      headers: h,
      body: JSON.stringify({ model: "openai/gpt-6-luna", messages: [] }),
    });
    expect(broke.status).toBe(402);
  });
});
