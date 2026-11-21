/**
 * Free plans through the admin bot (docs/COMP-PLANS-PLAN.md §9). Reads run in the owner's admin
 * chat; every change needs the owner's own fresh yes, and goes through the comps service. Runs
 * through the real run loop as the worker's own role, so the service works with its grants alone.
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
import { BillingService } from "../src/billing/service.ts";
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
let target: { id: string; email: string };
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
    name: "admin-bot-comps",
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
  target = await h.user("comp-target@example.com");
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
  deps = {
    db: worker.db,
    ownerEmails: [OWNER],
    billingEnabled: true,
    billing: new BillingService({ db: worker.db, enabled: true, providers: {} }),
  };
  await h.tdb.admin`update public.billing_settings set comps_enabled = true`;
}, 60_000);
afterAll(async () => {
  await worker?.close();
  await h?.stop();
});
beforeEach(async () => {
  decide = async () => {};
  calls = {
    list: { name: "admin.comps.list", args: () => ({}) },
    grant: {
      name: "admin.comps.grant",
      args: () => ({ email: target.email, plan_code: "pro", months: 2, note: "Friend" }),
    },
    code: { name: "admin.compCodes.create", args: () => ({ plan_code: "plus", months: 1 }) },
  };
  await setAdminBot(h.handle.db, { enabled: true, bot_id: adminBotId });
});

const runningComps = async () => {
  const rows = await h.tdb.admin<{ id: string; plan_code: string }[]>`
    select id, plan_code from public.comps where org_id = ${targetOrg} and ended_at is null`;
  return rows;
};

describe("admin bot free plans", () => {
  it("lists without a card", async () => {
    const r = await chat("list them");
    expect(r.approvals).toEqual([]);
    expect(r.done?.result_preview).toMatch(/^\d+ free plans?$/);
  });

  it("refuses a grant nobody approved, or approved by someone else, or stale", async () => {
    await chat("grant one");
    decide = approveAs(stranger.id);
    await chat("grant one");
    decide = approveAs(owner.id, { ageMin: 30 });
    await chat("grant one");
    decide = approveAs(owner.id, { alwaysAllow: true });
    await chat("grant one");
    expect(await runningComps()).toEqual([]);
  });

  it("grants with the owner's fresh yes, as the worker, and logs the owner", async () => {
    decide = approveAs(owner.id);
    const r = await chat("grant one");
    expect(r.failed).toBeUndefined();
    const running = await runningComps();
    expect(running).toEqual([expect.objectContaining({ plan_code: "pro" })]);
    const [ent] = await h.tdb.admin<{ plan_code: string }[]>`
      select plan_code from public.entitlements where org_id = ${targetOrg}
      order by created_at desc limit 1`;
    expect(ent?.plan_code).toBe("pro");
    const [ev] = await h.tdb.admin<{ actor_id: string }[]>`
      select actor_id from public.comp_events where comp_id = ${running[0]!.id} and action = 'granted'`;
    expect(ev?.actor_id).toBe(owner.id);
    const [audit] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.audit_log where action = 'admin_bot.comps.grant'`;
    expect(audit?.n).toBe(1);

    // Revoke it the same way.
    calls.revoke = { name: "admin.comps.revoke", args: () => ({ comp_id: running[0]!.id }) };
    await chat("revoke it");
    expect(await runningComps()).toEqual([]);
  });

  it("makes a gift code once approved, and shows it only in the result", async () => {
    decide = approveAs(owner.id);
    const r = await chat("code please");
    expect(r.failed).toBeUndefined();
    expect(r.done?.result_preview).toMatch(/^Gift code …[0-9A-Z]{4}/);
    const [n] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.comp_codes`;
    expect(n?.n).toBe(1);
  });

  it("disables a gift code only with the owner's yes, and can enable it again", async () => {
    const [code] = await h.tdb.admin<{ id: string }[]>`
      select id from public.comp_codes order by created_at desc limit 1`;
    const disabledAt = async () => {
      const [r] = await h.tdb.admin<{ disabled_at: Date | null }[]>`
        select disabled_at from public.comp_codes where id = ${code!.id}`;
      return r?.disabled_at ?? null;
    };
    calls.disable = { name: "admin.compCodes.disable", args: () => ({ code_id: code!.id }) };
    await chat("disable it");
    decide = approveAs(stranger.id);
    await chat("disable it");
    expect(await disabledAt()).toBeNull();

    decide = approveAs(owner.id);
    const r = await chat("disable it");
    expect(r.failed).toBeUndefined();
    expect(await disabledAt()).not.toBeNull();
    const [audit] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.audit_log where action = 'admin_bot.compCodes.disable'`;
    expect(audit?.n).toBe(1);

    calls.enable = {
      name: "admin.compCodes.disable",
      args: () => ({ code_id: code!.id, enable: true }),
    };
    await chat("enable it");
    expect(await disabledAt()).toBeNull();
  });

  it("outside the owner's admin chat: nothing changes", async () => {
    decide = approveAs(owner.id);
    await chat("grant one", { group: true });
    await chat("grant one", { trigger: "routine" });
    expect(await runningComps()).toEqual([]);
  });
});
