/** Action rules API (D-115): who can change rules, previews, and "always allow" becoming a rule. */
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

let h: Harness;
let owner: { id: string; token: string };
let member: { id: string; token: string };
let orgId: string;
let botId: string;

beforeAll(async () => {
  h = await startHarness();
  owner = await h.user("rules-owner@example.com");
  member = await h.user("rules-member@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "R" } }),
    )
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${member.id}, 'member')`;
  const [b] = await h.tdb.admin<
    { id: string }[]
  >`insert into public.bots (org_id, name, created_by, visibility) values (${orgId}, 'Mailer', ${owner.id}, 'team') returning id`;
  botId = b!.id;
}, 60_000);
afterAll(async () => h?.stop());

describe("action rules API", () => {
  it("admins add workspace rules with a plain-language preview; members can't", async () => {
    const json = {
      org_id: orgId,
      match_kind: "category",
      match_value: "send",
      target: { domains: ["acme.com"] },
      rule: "allow_within_limits",
    };
    expect(
      (await h.request("/v1/action-rules", { method: "POST", token: member.token, json })).status,
    ).toBe(403);
    const res = await h.request("/v1/action-rules", { method: "POST", token: owner.token, json });
    expect(res.status).toBe(201);
    expect((await j(res)).preview).toBe("Sends messages to anyone at acme.com without asking");
    expect(
      (
        await h.request("/v1/action-rules", {
          method: "POST",
          token: owner.token,
          json: { ...json, target: null },
        })
      ).status,
    ).toBe(400);
  });

  it("lists a bot's rules with the workspace's, and deletes", async () => {
    const r = await j(
      await h.request("/v1/action-rules", {
        method: "POST",
        token: owner.token,
        json: {
          org_id: orgId,
          bot_id: botId,
          match_kind: "category",
          match_value: "pay",
          rule: "hand_off",
        },
      }),
    );
    const list = await j(
      await h.request(`/v1/action-rules?org_id=${orgId}&bot_id=${botId}`, { token: member.token }),
    );
    expect(list.items.map((x: { match_value: string }) => x.match_value)).toEqual(["send", "pay"]);
    expect(
      (await h.request(`/v1/action-rules/${r.id}`, { method: "DELETE", token: member.token }))
        .status,
    ).toBe(404);
    expect(
      (await h.request(`/v1/action-rules/${r.id}`, { method: "DELETE", token: owner.token }))
        .status,
    ).toBe(200);
  });

  it("'always allow this tool' becomes a tool rule", async () => {
    const [run] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.runs (org_id, bot_id, trigger, status) values (${orgId}, ${botId}, 'chat', 'waiting_approval') returning id`;
    const [a] = await h.tdb.admin<{ id: string }[]>`
      insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, args_redacted, summary, risk, expires_at)
      values (${orgId}, ${botId}, ${run!.id}, 'c1', 'mail.send', '{}', 'send', 'high', now() + interval '1 hour') returning id`;
    const res = await h.request(`/v1/approvals/${a!.id}/decision`, {
      method: "POST",
      token: owner.token,
      json: { decision: "approved", always_allow: true },
    });
    expect(res.status).toBe(200);
    const [r] = await h.tdb.admin<
      { rule: string }[]
    >`select rule from public.action_rules where bot_id = ${botId} and match_kind = 'tool' and match_value = 'mail.send'`;
    expect(r?.rule).toBe("allow");
  });
});
