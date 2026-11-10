/** Self-improving skills (D-126): proposals from repeated work, edits after failures and corrections. */
import { hashEmbedder, learnFromRun } from "@kasama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;
let convId: string;
const prompts: string[] = [];
const notified: string[] = [];

const complete = async (system: string, text: string) => {
  prompts.push(text);
  if (system.includes("reusable skill"))
    return JSON.stringify({ name: "weekly-sales-report", description: "Make the weekly sales report", steps: "1. Query sales with crm.query.\n2. Summarize.", tools: ["crm.query", "sheets.write"] });
  return 'Here you go: {"description": "Make the weekly sales report", "body": "1. Query sales for the last 7 days with crm.query.\\n2. Summarize.", "reason": "Use the last 7 days, not the month."}';
};
const deps = () => ({ db: h.handle.db, embedder: hashEmbedder(), complete, notify: async (_u: string, _o: string, p: { title: string }) => void notified.push(p.title) });

/** A finished run with its tool and skill events. */
const run = async (task: string, opts: { tools?: string[]; skill?: string; status?: "completed" | "failed"; error?: string } = {}) => {
  const [r] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, trigger, status, created_by)
    values (${orgId}, ${botId}, ${convId}, 'chat', ${opts.status ?? "completed"}, ${owner.id}) returning id`;
  let seq = 1;
  for (const t of opts.tools ?? []) await h.tdb.admin`insert into public.run_events (org_id, bot_id, run_id, seq, type, payload) values (${orgId}, ${botId}, ${r!.id}, ${seq++}, 'tool.started', ${JSON.stringify({ tool: t })}::text::jsonb)`;
  if (opts.skill) await h.tdb.admin`insert into public.run_events (org_id, bot_id, run_id, seq, type, payload) values (${orgId}, ${botId}, ${r!.id}, ${seq++}, 'skill.loaded', ${JSON.stringify({ name: opts.skill })}::text::jsonb)`;
  return learnFromRun(deps(), {
    runId: r!.id,
    orgId,
    botId,
    conversationId: convId,
    task,
    status: opts.status ?? "completed",
    error: opts.error,
    owner: owner.id,
  });
};

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("learn@example.com");
  member = await h.user("learn-member@example.com");
  orgId = (await j(await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "L" } }))).id;
  await h.tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
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
        json: { org_id: orgId, name: "Analyst", model_policy: { primary: { credential_id: cred.id, model: "m" } } },
      }),
    )
  ).id;
  const [c] = await h.tdb.admin<{ id: string }[]>`insert into public.conversations (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${owner.id}) returning id`;
  convId = c!.id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
});

describe("self-improving skills", () => {
  let proposalId: string;

  it("proposes a skill once the same task succeeded three times with tools", async () => {
    expect(await run("Make the weekly sales report for the team", { tools: ["crm.query", "sheets.write"] })).toBeNull();
    expect(await run("make the weekly sales report for the team please", { tools: ["crm.query", "sheets.write"] })).toBeNull();
    // Too simple (one tool) or different work doesn't count.
    expect(await run("What's the capital of France", { tools: [] })).toBeNull();
    const third = await run("Weekly sales report for the team", { tools: ["crm.query", "sheets.write", "memory.search"] });
    expect(third).toMatchObject({ applied: false });
    proposalId = third!.id;
    expect(prompts.at(-1)).toContain("Tools used: crm.query, sheets.write");
    expect(notified).toEqual(['Save "weekly-sales-report" as a skill?']);
    // Not proposed again for the same runs.
    expect(await run("weekly sales report for the team", { tools: ["crm.query", "sheets.write"] })).toBeNull();
    const list = await j(await h.request(`/v1/skill-proposals?org_id=${orgId}&bot_id=${botId}`, { token: owner.token }));
    expect(list.items).toHaveLength(1);
    expect(list.items[0]).toMatchObject({ kind: "new", name: "weekly-sales-report", tools: ["crm.query", "sheets.write"] });
  });

  it("the owner accepts it (with a change); members can't", async () => {
    expect((await h.request(`/v1/skill-proposals/${proposalId}/accept`, { method: "POST", token: member.token, json: {} })).status).toBe(403);
    const p = await j(
      await h.request(`/v1/skill-proposals/${proposalId}/accept`, { method: "POST", token: owner.token, json: { body_md: "1. Query sales.\n2. Summarize for the team." } }),
    );
    expect(p.status).toBe("accepted");
    const [s] = await h.tdb.admin<{ body_md: string; source: string }[]>`select body_md, source from public.skills where name = 'weekly-sales-report'`;
    expect(s).toEqual({ body_md: "1. Query sales.\n2. Summarize for the team.", source: "bot" });
    expect((await h.request(`/v1/skill-proposals/${proposalId}/accept`, { method: "POST", token: owner.token, json: {} })).status).toBe(409);
  });

  it("a correction after a run that used the skill proposes an edit as a diff; stats count it", async () => {
    await run("Weekly sales report", { tools: ["crm.query"], skill: "weekly-sales-report" });
    const edit = await run("No, use the last 7 days, not the whole month");
    expect(edit).toMatchObject({ applied: false });
    expect(prompts.at(-1)).toContain("The person then corrected it: No, use the last 7 days");
    const [p] = (await j(await h.request(`/v1/skill-proposals?org_id=${orgId}`, { token: owner.token }))).items;
    expect(p).toMatchObject({ kind: "edit", previous_body_md: "1. Query sales.\n2. Summarize for the team.", reason: "Use the last 7 days, not the month." });
    expect(p.body_md).toContain("last 7 days");
    await h.request(`/v1/skill-proposals/${p.id}/accept`, { method: "POST", token: owner.token, json: {} });
    const [s] = await h.tdb.admin<{ id: string }[]>`select id from public.skills where name = 'weekly-sales-report'`;
    const stats = await j(await h.request(`/v1/skills/${s!.id}/stats`, { token: owner.token }));
    expect(stats).toMatchObject({ uses: 1, corrections: 1, successes: 0, success_rate: 0 });
    expect(stats.revisions).toHaveLength(1);
    expect(stats.revisions[0]).toMatchObject({ body_md: "1. Query sales.\n2. Summarize for the team.", by_bot: true });
  });

  it("a failed run that used a skill proposes an edit, applied at once when an action rule allows skill updates", async () => {
    await h.tdb.admin`insert into public.action_rules (org_id, bot_id, match_kind, match_value, rule, created_by)
      values (${orgId}, ${botId}, 'tool', 'skills.update', 'allow', ${owner.id})`;
    await h.tdb.admin`update public.skills set body_md = 'Old steps.' where name = 'weekly-sales-report'`;
    const r = await run("Weekly sales report", { tools: ["crm.query"], skill: "weekly-sales-report", status: "failed", error: "crm.query: permission denied" });
    expect(r).toMatchObject({ applied: true });
    expect(prompts.at(-1)).toContain("It failed: crm.query: permission denied");
    const [s] = await h.tdb.admin<{ body_md: string }[]>`select body_md from public.skills where name = 'weekly-sales-report'`;
    expect(s?.body_md).toContain("last 7 days");
    const dismissable = await run("Make the weekly sales report for the team!", { tools: ["crm.query", "sheets.write"] });
    expect(dismissable).toBeNull();
  });
});
