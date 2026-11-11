/** Projects (D-113): plan, approve, sessions to done with no person between milestones; budget stop. */
import { fileURLToPath } from "node:url";
import { NotificationService, projectHeartbeat, RecordingPushSender } from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/projects.json", import.meta.url));
const T1 = "00000000-0000-4000-8000-0000000000a1";
const T2 = "00000000-0000-4000-8000-0000000000a2";
let h: Harness;
let owner: { id: string; token: string };
let orgId: string;
let botId: string;
let projectId: string;

const settle = async () => {
  for (let i = 0; i < 200; i++) {
    const [r] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.runs where status in ('queued', 'running', 'waiting_approval')`;
    if (!r?.n) return;
    await new Promise((res) => setTimeout(res, 100));
  }
  throw new Error("runs did not settle");
};
const beat = async () => {
  const started = await projectHeartbeat(
    h.handle.db,
    (id) => h.deps.workflows.startRun(id),
    new NotificationService(h.handle.db, new RecordingPushSender()),
  );
  await settle();
  return started;
};
const project = async () => j(await h.request(`/v1/projects/${projectId}`, { token: owner.token }));

beforeAll(async () => {
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("project-owner@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "Proj" } }),
    )
  ).id;
  const cred = await j(
    await h.request("/v1/credentials", {
      method: "POST",
      token: owner.token,
      json: { org_id: orgId, provider: "openrouter", label: "k", api_key: "sk-or-v1-abcdefabcdef" },
    }),
  );
  botId = (
    await j(
      await h.request("/v1/bots", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          name: "Lead",
          autonomy: "autonomous",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    )
  ).id;
}, 60_000);
afterAll(async () => h?.stop());

describe("projects", () => {
  it("plans first: the lead bot proposes milestones and tickets for approval", async () => {
    const res = await h.request("/v1/projects", {
      method: "POST",
      token: owner.token,
      json: {
        org_id: orgId,
        title: "Launch site",
        goal_md: "Put the launch page live.",
        done_criteria_md: "The page is public.",
        lead_bot_id: botId,
        budget_usd: 50,
      },
    });
    expect(res.status).toBe(201);
    projectId = (await j(res)).id;
    await settle();
    const p = await project();
    expect(p).toMatchObject({
      status: "planning",
      plan_status: "proposed",
      plan_md: "Build the page, then ship it.",
    });
    expect(
      p.milestones.map((m: { name: string; tickets_total: number }) => [m.name, m.tickets_total]),
    ).toEqual([
      ["Build", 1],
      ["Ship", 1],
    ]);
    // No sessions before approval.
    expect(await beat()).toEqual([]);
    // Pin the ticket ids so the scripted model can name them.
    await h.tdb
      .admin`update public.tasks set id = ${T1} where project_id = ${projectId} and title = 'Write the page'`;
    await h.tdb
      .admin`update public.tasks set id = ${T2} where project_id = ${projectId} and title = 'Publish the page'`;
    const tickets = await j(
      await h.request(`/v1/tasks?org_id=${orgId}&project_id=${projectId}`, { token: owner.token }),
    );
    expect(tickets.items).toHaveLength(2);
  });

  it("after approval, sessions work milestone by milestone until the goal is done", async () => {
    const ok = await h.request(`/v1/projects/${projectId}/plan/approve`, {
      method: "POST",
      token: owner.token,
    });
    expect((await j(ok)).status).toBe("active");
    expect(await beat()).toHaveLength(1); // session 1: "Write the page"
    let p = await project();
    expect(p.milestones[0]).toMatchObject({ status: "open", tickets_done: 1 });
    expect(await beat()).toHaveLength(1); // closes Build, session 2: "Publish the page"
    p = await project();
    expect(p.milestones.map((m: { status: string }) => m.status)).toEqual(["done", "open"]);
    expect(await beat()).toHaveLength(1); // closes Ship, wrap-up confirms done
    p = await project();
    expect(p.status).toBe("done");
    expect(p.sessions).toBe(3);
    expect(p.spent_usd).toBeGreaterThan(0);
    expect(p.runs.every((r: { bot_id: string }) => r.bot_id === botId)).toBe(true);
    expect(await beat()).toEqual([]);
  });

  it("stops cleanly at its budget and tells the owner", async () => {
    const [p2] = await h.tdb.admin<{ id: string }[]>`
      insert into public.projects (org_id, slug, title, goal_md, lead_bot_id, owner_user_id, budget_usd, status, plan_status)
      values (${orgId}, 'tiny', 'Tiny budget', 'x', ${botId}, ${owner.id}, 1, 'active', 'approved') returning id`;
    await h.tdb
      .admin`insert into public.tasks (org_id, title, project_id) values (${orgId}, 'Do a thing', ${p2!.id})`;
    await h.tdb
      .admin`insert into public.runs (org_id, bot_id, trigger, status, project_id, cost_usd) values (${orgId}, ${botId}, 'project', 'completed', ${p2!.id}, 1.5)`;
    expect(await beat()).toEqual([]);
    const [row] = await h.tdb.admin<
      { status: string; status_reason: string }[]
    >`select status, status_reason from public.projects where id = ${p2!.id}`;
    expect(row?.status).toBe("paused");
    expect(row?.status_reason).toContain("Budget reached");
    const [n] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.notifications where kind = 'project' and payload->>'project_id' = ${p2!.id}`;
    expect(n?.n).toBe(1);
    // Raising the budget and resuming continues (the heartbeat keeps no state of its own, so a
    // restart picks up the same way).
    const resumed = await j(
      await h.request(`/v1/projects/${p2!.id}`, {
        method: "PATCH",
        token: owner.token,
        json: { budget_usd: 100, status: "active" },
      }),
    );
    expect(resumed.status).toBe("active");
  });
});
