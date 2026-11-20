/**
 * Saved resets through the admin bot (D-445, docs/ADMIN-BOT-RESETS-PLAN.md). Reads run in the
 * owner's admin chat; every change needs the owner's own fresh yes, and goes through the saved-reset
 * service so its log names the owner. Runs through the real run loop as the worker's own role.
 */

import {
  builtinTools,
  CredentialResolver,
  directSteps,
  type FixtureFile,
  hashEmbedder,
  PostgresMemoryStore,
  ReplayGateway,
  runAgent,
} from "@casama/agent";
import { createDb, type DbHandle } from "@casama/db";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import {
  type AdminBotDeps,
  adminRunCheck,
  registerAdminTools,
  setAdminBot,
} from "../src/services/admin-bot.ts";
import { type Harness, startHarness } from "./helpers.ts";

const OWNER = "admin@casama.test";
let h: Harness;
let owner: { id: string };
let stranger: { id: string };
let adminOrg: string;
let adminBotId: string;
let targetOrg: string;
let deps: AdminBotDeps;
let worker: DbHandle;
/** What the model calls next, keyed by a word in the owner's message. */
let calls: Record<string, { name: string; args: () => Record<string, unknown> }> = {};

const fin = {
  type: "finish" as const,
  usage: { inputTokens: 10, outputTokens: 5 },
  finishReason: "stop",
  model: "",
};
const fixtures = (): FixtureFile[] => [
  {
    name: "admin-bot-resets",
    turns: [
      {
        when: { systemIncludes: "extract lasting memories" },
        events: [{ type: "text", text: '{"memories":[]}' }, fin],
      },
      ...Object.entries(calls).map(([word, c]) => ({
        when: { lastRole: "user" as const, lastUserIncludes: word },
        events: [
          {
            type: "tool_call" as const,
            call: { callId: `c-${word}`, name: c.name.replaceAll(".", "__"), args: c.args() },
          },
          { ...fin, finishReason: "tool-calls" },
        ],
      })),
      { when: { lastRole: "tool" }, events: [{ type: "text", text: "Done." }, fin] },
    ],
  },
];

let decide: (approvalId: string) => Promise<void> = async () => {};
const approveAs =
  (userId: string, extra: { alwaysAllow?: boolean; ageMin?: number } = {}) =>
  async (approvalId: string) => {
    await h.tdb.admin`
      update public.approvals set status = 'approved', decided_by = ${userId},
        decided_at = now() - make_interval(mins => ${extra.ageMin ?? 0}),
        always_allow = ${extra.alwaysAllow ?? false}
      where id = ${approvalId}`;
  };

async function chat(text: string, o: { trigger?: string; group?: boolean } = {}) {
  const [conv] = await h.tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, kind)
    values (${adminOrg}, ${adminBotId}, ${o.group ? "group" : "direct"}) returning id`;
  const [run] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
    values (${adminOrg}, ${adminBotId}, ${conv!.id}, ${owner.id}, ${o.trigger ?? "chat"}) returning id`;
  await h.tdb
    .admin`insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${adminOrg}, ${conv!.id}, 'user', ${owner.id}, ${h.tdb.admin.json([{ type: "text", text }])}, ${run!.id})`;
  const tools = builtinTools({
    db: worker.db,
    memory: async () => new PostgresMemoryStore(worker.db, hashEmbedder()),
  });
  registerAdminTools(tools, deps);
  await runAgent(run!.id, {
    db: worker.db,
    gateway: new ReplayGateway(fixtures()),
    tools,
    credentials: new CredentialResolver(worker.db),
    embedderFor: async () => hashEmbedder(),
    step: directSteps,
    deltaIntervalMs: 20,
    cancelPollMs: 50,
    fallback: { backoffMs: 1 },
    instanceAdmin: adminRunCheck(deps),
    waitForApproval: async (id) => decide(id),
  });
  const approvals = await h.tdb.admin<{ id: string; status: string }[]>`
    select id, status from public.approvals where run_id = ${run!.id}`;
  const events = await h.tdb.admin<{ type: string; payload: Record<string, unknown> }[]>`
    select type, payload from public.run_events where run_id = ${run!.id} order by seq`;
  return {
    approvals,
    failed: events.find((e) => e.type === "tool.failed")?.payload,
    done: events.find((e) => e.type === "tool.completed")?.payload,
  };
}

const enabled = async () => {
  const [s] = await h.tdb.admin<{ on: boolean }[]>`
    select limit_resets_enabled as on from public.billing_settings limit 1`;
  return s!.on;
};
const setEnabled = (on: boolean) =>
  h.tdb.admin`update public.billing_settings set limit_resets_enabled = ${on}`;

async function orgWith(name: string, ownerId: string, plan = true) {
  const [o] = await h.tdb.admin<{ id: string }[]>`
    insert into public.organizations (name, slug, plan) values (${name}, ${`${name.toLowerCase()}-${Date.now()}`}, 'free') returning id`;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${o!.id}, ${ownerId}, 'owner')`;
  // A plan with a credit gate would stop the admin bot's own runs; only the target needs one.
  if (plan)
    await h.tdb
      .admin`insert into public.entitlements (org_id, plan_code, limits) select ${o!.id}, code, limits from public.plans where code = 'free'`;
  return o!.id;
}

beforeAll(async () => {
  h = await startHarness({ env: { INSTANCE_ADMIN_EMAILS: OWNER } });
  owner = await h.user(OWNER);
  stranger = await h.user("stranger@example.com");
  const target = await h.user("target@example.com");
  await h.tdb.admin`update auth.users set email_confirmed_at = now()`;
  adminOrg = await orgWith("Admin", owner.id, false);
  // The admin bot's own runs need credits like any run on a billed server.
  await h.tdb
    .admin`select public.credit_apply(${adminOrg}, 100, 'adjustment', 'admin-bot-test', null)`;
  targetOrg = await orgWith("Target", target.id);
  const [cred] = await h.tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id)
    values (${adminOrg}, 'openrouter', 'k', vault.create_secret('sk-test-123456')) returning id`;
  const [b] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, autonomy, model_policy)
    values (${adminOrg}, ${owner.id}, 'Admin', 'autonomous', ${h.tdb.admin.json({ primary: { credential_id: cred!.id, model: "m" } })}) returning id`;
  adminBotId = b!.id;
  await h.tdb.admin.unsafe("alter role casama_worker login password 'casama-worker-test'");
  worker = createDb(h.tdb.url.replace("postgres@", "casama_worker:casama-worker-test@"), {
    max: 4,
  });
  deps = { db: worker.db, ownerEmails: [OWNER], billingEnabled: true };
}, 60_000);
afterAll(async () => {
  await worker?.close();
  await h?.stop();
});
beforeEach(async () => {
  decide = async () => {};
  calls = {
    status: { name: "admin.resets.status", args: () => ({}) },
    switch: { name: "admin.resets.settings", args: () => ({ enabled: true }) },
    give: {
      name: "admin.resets.give",
      args: () => ({ org_id: targetOrg, message: "Sorry about the outage", expires_in_days: 7 }),
    },
  };
  await setAdminBot(h.handle.db, { enabled: true, bot_id: adminBotId });
  await setEnabled(false);
});

describe("admin bot saved resets: reads", () => {
  it("run without a card and return the settings and campaigns", async () => {
    const r = await chat("status please");
    expect(r.approvals).toHaveLength(0);
    expect(r.failed).toBeUndefined();
    expect(r.done?.result_preview).toBe("off, 0 campaigns");
  });

  it("a preview shows reach and cost without a card", async () => {
    calls.reach = {
      name: "admin.resets.preview",
      args: () => ({ workspace_ids: [targetOrg] }),
    };
    const r = await chat("reach of this");
    expect(r.approvals).toHaveLength(0);
    expect(r.done?.result_preview).toBe("1 workspaces");
  });
});

describe("admin bot saved resets: changes need the owner's fresh yes", () => {
  it("with it: switched on, logged with the owner as actor and in the audit log", async () => {
    decide = approveAs(owner.id);
    const r = await chat("switch them on");
    expect(r.approvals[0]!.status).toBe("approved");
    expect(await enabled()).toBe(true);
    const [e] = await h.tdb.admin<{ actor: string }[]>`
      select actor_id as actor from public.limit_reset_events where action = 'settings' order by created_at desc limit 1`;
    expect(e!.actor).toBe(owner.id);
    const [a] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.audit_log where action = 'admin_bot.resets.settings' and actor_id = ${owner.id}`;
    expect(a!.n).toBeGreaterThan(0);
  });

  it("nobody answers, someone else answers, a stale yes, an 'always allow': nothing changes", async () => {
    for (const d of [
      async () => {},
      approveAs(stranger.id),
      approveAs(owner.id, { ageMin: 20 }),
      approveAs(owner.id, { alwaysAllow: true }),
    ]) {
      decide = d;
      await chat("switch them on");
      expect(await enabled()).toBe(false);
    }
  });

  it("outside the owner's admin chat: no card, nothing changes", async () => {
    decide = approveAs(owner.id);
    for (const o of [{ trigger: "routine" }, { trigger: "voice" }, { group: true }]) {
      const r = await chat("switch them on", o);
      expect(r.approvals).toHaveLength(0);
    }
    await setAdminBot(h.handle.db, { enabled: false, bot_id: adminBotId });
    expect((await chat("switch them on")).approvals).toHaveLength(0);
    expect(await enabled()).toBe(false);
  });

  it("a campaign the bot proposes needs a budget", async () => {
    decide = approveAs(owner.id);
    calls.nobudget = {
      name: "admin.resets.create",
      args: () => ({ name: "No budget", message: "Saved", workspace_ids: [targetOrg] }),
    };
    await chat("nobudget campaign");
    const [n] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.limit_reset_campaigns where name = 'No budget'`;
    expect(n!.n).toBe(0);
  });

  it("creates and schedules a budgeted campaign that reaches its audience", async () => {
    await setEnabled(true);
    decide = approveAs(owner.id);
    calls.launch = {
      name: "admin.resets.create",
      args: () => ({
        name: "Outage",
        message: "Sorry about Tuesday",
        workspace_ids: [targetOrg],
        budget_usd: 5,
        schedule: true,
      }),
    };
    const r = await chat("launch it");
    expect(r.failed).toBeUndefined();
    const [c] = await h.tdb.admin<{ state: string; budget: string; by: string; given: number }[]>`
      select c.state, c.budget_usd::text as budget, c.created_by as by,
             (select count(*)::int from public.limit_resets r where r.campaign_id = c.id) as given
      from public.limit_reset_campaigns c where c.name = 'Outage'`;
    expect(c).toMatchObject({ state: "live", by: owner.id, given: 1 });
    expect(Number(c!.budget)).toBe(5);
  });

  it("gives a one-off only while switched on, and takes it back", async () => {
    decide = approveAs(owner.id);
    const off = await chat("give them one");
    expect(off.failed?.message).toContain("Turn saved resets on");
    await setEnabled(true);
    await chat("give them one");
    const [r] = await h.tdb.admin<{ id: string }[]>`
      select r.id from public.limit_resets r join public.limit_reset_campaigns c on c.id = r.campaign_id
      where r.org_id = ${targetOrg} and c.message = 'Sorry about the outage' and r.revoked_at is null`;
    expect(r).toBeDefined();
    calls.takeback = {
      name: "admin.resets.take_back",
      args: () => ({ reset_id: r!.id, action: "revoke" }),
    };
    await chat("takeback that reset");
    const [after] = await h.tdb.admin<{ revoked: boolean }[]>`
      select revoked_at is not null as revoked from public.limit_resets where id = ${r!.id}`;
    expect(after!.revoked).toBe(true);
  });
});
