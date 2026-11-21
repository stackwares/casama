/**
 * The phone browser's stage through the admin bot (docs/PHONE-BROWSER-PLAN.md §6). The read runs in
 * the owner's admin chat; a change needs the owner's own fresh yes. Runs through the real run loop
 * as the worker's own role.
 */

import {
  builtinTools,
  CredentialResolver,
  directSteps,
  type FixtureFile,
  hashEmbedder,
  PostgresMemoryStore,
  ReplayGateway,
  resetAppBrowserCache,
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
    name: "admin-bot-app-browser",
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

async function orgWith(name: string, ownerId: string) {
  const [o] = await h.tdb.admin<{ id: string }[]>`
    insert into public.organizations (name, slug, plan) values (${name}, ${`${name.toLowerCase()}-${Date.now()}`}, 'free') returning id`;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${o!.id}, ${ownerId}, 'owner')`;
  return o!.id;
}
const stored = async () => {
  const [r] = await h.tdb.admin<{ value: { stage: string; testers: string[] } }[]>`
    select value from public.instance_settings where key = 'app_browser'`;
  return r?.value ?? null;
};

beforeAll(async () => {
  h = await startHarness({ env: { INSTANCE_ADMIN_EMAILS: OWNER } });
  owner = await h.user(OWNER);
  stranger = await h.user("stranger@example.com");
  await h.tdb.admin`update auth.users set email_confirmed_at = now()`;
  adminOrg = await orgWith("Admin", owner.id);
  await h.tdb
    .admin`select public.credit_apply(${adminOrg}, 100, 'adjustment', 'admin-bot-test', null)`;
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
  resetAppBrowserCache();
});
beforeEach(async () => {
  decide = async () => {};
  resetAppBrowserCache();
  calls = {
    status: { name: "admin.phone_browser.status", args: () => ({}) },
    testers: {
      name: "admin.phone_browser.set",
      args: () => ({ stage: "testers", testers: [owner.id] }),
    },
    everyone: {
      name: "admin.phone_browser.set",
      args: () => ({ stage: "on", systems: ["android"] }),
    },
  };
  await setAdminBot(h.handle.db, { enabled: true, bot_id: adminBotId });
});

describe("admin bot: the phone browser's stage", () => {
  it("reads the stage and the numbers without a card, and says what the owner must confirm", async () => {
    const r = await chat("status please");
    expect(r.approvals).toHaveLength(0);
    expect(r.failed).toBeUndefined();
    expect(r.done?.result_preview).toBe("off, 0 phone runs");
  });

  it("changes nothing without the owner's own fresh yes", async () => {
    for (const d of [async () => {}, approveAs(stranger.id), approveAs(owner.id, { ageMin: 30 })]) {
      decide = d;
      await chat("give it to the testers");
      expect(await stored()).toBeNull();
    }
  });

  it("with it: the stage changes, keeps what wasn't named, and is logged with the owner", async () => {
    decide = approveAs(owner.id);
    const r = await chat("give it to the testers");
    expect(r.approvals[0]!.status).toBe("approved");
    expect(await stored()).toMatchObject({ stage: "testers", testers: [owner.id] });
    await chat("now everyone on android");
    expect(await stored()).toMatchObject({
      stage: "on",
      testers: [owner.id],
      systems: ["android"],
      reasons: { asked: true, blocked: false, signed_in: false },
    });
    const [a] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.audit_log where action = 'admin_bot.phone_browser.set' and actor_id = ${owner.id}`;
    expect(a!.n).toBe(2);
    const s = await chat("status please");
    expect(s.done?.result_preview).toBe("on, 0 phone runs");
  });
});
