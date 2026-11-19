/**
 * The admin bot (D-435, docs/ADMIN-BOT-PLAN.md). Every test tries to get an admin action through
 * without the owner's own fresh approval in their own chat, and checks that nothing happened.
 */
import { createDb, type DbHandle } from "@casama/db";
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
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import {
  type AdminBotDeps,
  adminRunCheck,
  banUser,
  registerAdminTools,
  setAdminBot,
  unbanUser,
} from "../src/services/admin-bot.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

const OWNER = "admin@casama.test";
let h: Harness;
let owner: { id: string; email: string; token: string };
let target: { id: string; email: string; token: string };
let stranger: { id: string; email: string; token: string };
let adminOrg: string;
let adminBotId: string;
let targetOrg: string;
let deps: AdminBotDeps;
let credId: string;
/** The worker's own least-privilege role (D-095): the tools must work with its grants alone. */
let worker: DbHandle;

const fin = {
  type: "finish" as const,
  usage: { inputTokens: 10, outputTokens: 5 },
  finishReason: "stop",
  model: "",
};
const fixtures = (): FixtureFile[] => [
  {
    name: "admin-bot",
    turns: [
      {
        when: { systemIncludes: "extract lasting memories" },
        events: [{ type: "text", text: '{"memories":[]}' }, fin],
      },
      {
        when: { lastRole: "user" as const, lastUserIncludes: "ban" },
        events: [
          {
            type: "tool_call" as const,
            call: {
              callId: "c-ban",
              name: "admin__users__ban",
              args: { user_id: target.id, reason: "spam" },
            },
          },
          { ...fin, finishReason: "tool-calls" },
        ],
      },
      {
        when: { lastRole: "user" as const, lastUserIncludes: "look" },
        events: [
          {
            type: "tool_call" as const,
            call: { callId: "c-find", name: "admin__users__find", args: { email: "target" } },
          },
          { ...fin, finishReason: "tool-calls" },
        ],
      },
      { when: { lastRole: "tool" }, events: [{ type: "text", text: "Done." }, fin] },
    ],
  },
];

function tools() {
  const t = builtinTools({
    db: worker.db,
    memory: async () => new PostgresMemoryStore(worker.db, hashEmbedder()),
  });
  registerAdminTools(t, deps);
  return t;
}

/** How the "owner" answers the approval card in a test. */
let decide: (approvalId: string) => Promise<void> = async () => {};

async function chat(
  text: string,
  o: { org?: string; bot?: string; by?: string; trigger?: string; group?: boolean } = {},
) {
  const org = o.org ?? adminOrg;
  const bot = o.bot ?? adminBotId;
  const by = o.by ?? owner.id;
  const [conv] = await h.tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, kind) values (${org}, ${bot}, ${o.group ? "group" : "direct"}) returning id`;
  const [run] = await h.tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, conversation_id, created_by, trigger)
    values (${org}, ${bot}, ${conv!.id}, ${by}, ${o.trigger ?? "chat"}) returning id`;
  await h.tdb.admin`insert into public.messages (org_id, conversation_id, role, author_user_id, content, run_id)
    values (${org}, ${conv!.id}, 'user', ${by}, ${h.tdb.admin.json([{ type: "text", text }])}, ${run!.id})`;
  await runAgent(run!.id, {
    db: worker.db,
    gateway: new ReplayGateway(fixtures()),
    tools: tools(),
    credentials: new CredentialResolver(worker.db),
    embedderFor: async () => hashEmbedder(),
    step: directSteps,
    deltaIntervalMs: 20,
    cancelPollMs: 50,
    fallback: { backoffMs: 1 },
    instanceAdmin: adminRunCheck(deps),
    waitForApproval: async (id) => decide(id),
  });
  const approvals = await h.tdb.admin<{ id: string; risk: string; status: string }[]>`
    select id, risk, status from public.approvals where run_id = ${run!.id}`;
  const events = await h.tdb.admin<{ type: string; payload: Record<string, unknown> }[]>`
    select type, payload from public.run_events where run_id = ${run!.id} order by seq`;
  return { runId: run!.id, approvals, events };
}

const banned = async () => {
  const [u] = await h.tdb.admin<{ b: boolean }[]>`
    select coalesce(banned_until > now(), false) as b from auth.users where id = ${target.id}`;
  return u!.b;
};

const approveAs = (userId: string, extra: { alwaysAllow?: boolean; ageMin?: number } = {}) =>
  async (approvalId: string) => {
    await h.tdb.admin`
      update public.approvals set status = 'approved', decided_by = ${userId},
        decided_at = now() - make_interval(mins => ${extra.ageMin ?? 0}),
        always_allow = ${extra.alwaysAllow ?? false}
      where id = ${approvalId}`;
  };

async function orgWith(name: string, ownerId: string) {
  const [o] = await h.tdb.admin<{ id: string }[]>`
    insert into public.organizations (name, slug) values (${name}, ${`${name.toLowerCase()}-${Date.now()}`}) returning id`;
  await h.tdb.admin`insert into public.memberships (org_id, user_id, role) values (${o!.id}, ${ownerId}, 'owner')`;
  return o!.id;
}

async function botIn(org: string, by: string) {
  const [cred] = await h.tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id)
    values (${org}, 'openrouter', 'k', vault.create_secret('sk-test-123456')) returning id`;
  credId = cred!.id;
  // The loosest autonomy, so anything that asks is the admin gate's doing.
  const [b] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, autonomy, model_policy)
    values (${org}, ${by}, 'Admin', 'autonomous', ${h.tdb.admin.json({ primary: { credential_id: credId, model: "m" } })}) returning id`;
  return b!.id;
}

beforeAll(async () => {
  h = await startHarness({ env: { INSTANCE_ADMIN_EMAILS: OWNER } });
  owner = await h.user(OWNER);
  target = await h.user("target@example.com");
  stranger = await h.user("stranger@example.com");
  await h.tdb.admin`update auth.users set email_confirmed_at = now()`;
  adminOrg = await orgWith("Admin", owner.id);
  adminBotId = await botIn(adminOrg, owner.id);
  targetOrg = await orgWith("Target", target.id);
  await h.tdb.admin.unsafe("alter role casama_worker login password 'casama-worker-test'");
  worker = createDb(h.tdb.url.replace("postgres@", "casama_worker:casama-worker-test@"), { max: 4 });
  deps = { db: worker.db, ownerEmails: [OWNER] };
}, 60_000);
afterAll(async () => {
  await worker?.close();
  await h?.stop();
});

beforeEach(async () => {
  decide = async () => {};
  await h.tdb.admin`update auth.users set banned_until = null where id = ${target.id}`;
  await h.tdb.admin`update public.organizations set suspended_at = null, suspended_reason = null where id = ${targetOrg}`;
  await h.tdb.admin`update public.organizations set full_access = false where id = ${adminOrg}`;
  await h.tdb.admin`delete from public.memberships where org_id = ${adminOrg} and user_id <> ${owner.id}`;
  await setAdminBot(h.handle.db, { enabled: true, bot_id: adminBotId });
});

describe("admin bot: who and where", () => {
  it("off: no approval, nothing happens, even when the model calls the tool by name", async () => {
    await setAdminBot(h.handle.db, { enabled: false, bot_id: adminBotId });
    decide = approveAs(owner.id);
    const r = await chat("ban them");
    expect(r.approvals).toHaveLength(0);
    expect(r.events.find((e) => e.type === "tool.failed")?.payload.message).toContain(
      "aren't available",
    );
    expect(await banned()).toBe(false);
  });

  it("only in-app chats: routines, tasks and voice calls are refused", async () => {
    decide = approveAs(owner.id);
    for (const trigger of ["task", "routine", "voice", "channel", "mention"]) {
      const r = await chat("ban them", { trigger });
      expect(r.approvals, trigger).toHaveLength(0);
    }
    expect(await banned()).toBe(false);
  });

  it("not in a group chat", async () => {
    decide = approveAs(owner.id);
    const r = await chat("ban them", { group: true });
    expect(r.approvals).toHaveLength(0);
    expect(await banned()).toBe(false);
  });

  it("not when anyone else is in the admin workspace", async () => {
    await h.tdb.admin`insert into public.memberships (org_id, user_id, role) values (${adminOrg}, ${stranger.id}, 'member')`;
    decide = approveAs(owner.id);
    expect((await chat("ban them")).approvals).toHaveLength(0);
    expect(await banned()).toBe(false);
  });

  it("not for another workspace's bot, even an owner's", async () => {
    const otherOrg = await orgWith("Other", owner.id);
    const otherBot = await botIn(otherOrg, owner.id);
    decide = approveAs(owner.id);
    expect((await chat("ban them", { org: otherOrg, bot: otherBot })).approvals).toHaveLength(0);
    expect(await banned()).toBe(false);
  });

  it("the owner by the explicit list only, with a confirmed email", async () => {
    const check = adminRunCheck({ db: worker.db, ownerEmails: [] });
    const r = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, created_by, trigger) values (${adminOrg}, ${adminBotId}, ${owner.id}, 'chat') returning id`;
    expect(await check(r[0]!.id)).toBe(false);
    await h.tdb.admin`update auth.users set email_confirmed_at = null where id = ${owner.id}`;
    decide = approveAs(owner.id);
    expect((await chat("ban them")).approvals).toHaveLength(0);
    await h.tdb.admin`update auth.users set email_confirmed_at = now() where id = ${owner.id}`;
    expect(await banned()).toBe(false);
  });
});

describe("admin bot: approvals", () => {
  it("always asks at high risk, under autonomous + Full access + an allow rule", async () => {
    await h.tdb.admin`update public.organizations set full_access = true where id = ${adminOrg}`;
    const [rule] = await h.tdb.admin<{ id: string }[]>`
      insert into public.action_rules (org_id, bot_id, match_kind, match_value, rule)
      values (${adminOrg}, null, 'tool', 'admin.users.ban', 'allow') returning id`;
    const r = await chat("ban them"); // nobody answers
    expect(r.approvals).toHaveLength(1);
    expect(r.approvals[0]!.risk).toBe("high");
    expect(await banned()).toBe(false);
    await h.tdb.admin`delete from public.action_rules where id = ${rule!.id}`;
  });

  it("the owner's fresh yes: banned, sessions ended, their own workspace suspended, audited", async () => {
    decide = approveAs(owner.id);
    const r = await chat("ban them");
    expect(r.approvals[0]!.status).toBe("approved");
    expect(await banned()).toBe(true);
    const [o] = await h.tdb.admin<{ reason: string | null }[]>`
      select suspended_reason as reason from public.organizations where id = ${targetOrg}`;
    expect(o!.reason).toBe("account_banned");
    const [a] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.audit_log where action = 'admin_bot.users.ban' and actor_id = ${owner.id}`;
    expect(a!.n).toBeGreaterThan(0);
  });

  it("refused when someone other than an owner decided it", async () => {
    decide = approveAs(stranger.id);
    const r = await chat("ban them");
    expect(r.events.find((e) => e.type === "tool.failed")?.payload.error_code).toBe(
      "admin_not_approved",
    );
    expect(await banned()).toBe(false);
  });

  it("refused when it was 'always allowed'", async () => {
    decide = approveAs(owner.id, { alwaysAllow: true });
    await chat("ban them");
    expect(await banned()).toBe(false);
  });

  it("refused when the yes is stale", async () => {
    decide = approveAs(owner.id, { ageMin: 20 });
    await chat("ban them");
    expect(await banned()).toBe(false);
  });

  it("refused when the switch goes off while it waits", async () => {
    decide = async (id) => {
      await setAdminBot(h.handle.db, { enabled: false, bot_id: adminBotId });
      await approveAs(owner.id)(id);
    };
    await chat("ban them");
    expect(await banned()).toBe(false);
  });

  it("reads run without asking and mark their output as untrusted", async () => {
    const r = await chat("look them up");
    expect(r.approvals).toHaveLength(0);
    const done = r.events.find((e) => e.type === "tool.completed");
    expect(done?.payload.result_preview).toBe("1 accounts");
  });
});

describe("admin bot: approving through the API", () => {
  const card = async () => {
    const [run] = await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status, created_by)
      values (${adminOrg}, ${adminBotId}, 'chat', 'waiting_approval', ${owner.id}) returning id`;
    const [a] = await h.tdb.admin<{ id: string }[]>`
      insert into public.approvals (org_id, bot_id, run_id, call_id, tool_name, args_redacted, summary, risk, expires_at)
      values (${adminOrg}, ${adminBotId}, ${run!.id}, 'c1', 'admin.users.ban', '{}', 'ban', 'high', now() + interval '1 hour') returning id`;
    return a!.id;
  };
  const answer = (id: string, token: string, json: unknown) =>
    h.request(`/v1/approvals/${id}/decision`, { method: "POST", token, json });

  it("never 'always allow'", async () => {
    const res = await answer(await card(), owner.token, {
      decision: "approved",
      always_allow: true,
    });
    expect(res.status).toBe(400);
  });

  it("an owner of the instance only (a workspace admin isn't enough)", async () => {
    const id = await card();
    await h.tdb.admin`insert into public.memberships (org_id, user_id, role) values (${adminOrg}, ${stranger.id}, 'admin')`;
    expect((await answer(id, stranger.token, { decision: "approved" })).status).toBe(403);
    expect((await answer(id, owner.token, { decision: "approved" })).status).toBe(200);
  });
});

describe("admin bot: the switch", () => {
  it("owner only, and only for a bot in an owners-only workspace", async () => {
    const put = (token: string, json: unknown) =>
      h.request("/v1/admin/admin-bot", { method: "PUT", token, json });
    expect((await put(stranger.token, { enabled: true, bot_id: adminBotId })).status).toBe(403);
    const targetBot = await botIn(targetOrg, target.id);
    expect((await put(owner.token, { enabled: true, bot_id: targetBot })).status).toBe(400);
    const ok = await put(owner.token, { enabled: true, bot_id: adminBotId });
    expect(ok.status).toBe(200);
    expect(await j(ok)).toMatchObject({ enabled: true, bot_id: adminBotId, available: true });
    expect(await j(await put(owner.token, { enabled: false }))).toMatchObject({ enabled: false });
  });
});

describe("ban and unban", () => {
  it("owners can't be banned; unban lifts only the ban's suspensions", async () => {
    expect(await banUser(deps, owner.id, "x", owner.id)).toMatchObject({ ok: false });
    const r = await banUser(deps, target.id, "spam", owner.id);
    expect(r).toMatchObject({ ok: true, suspended: [targetOrg] });
    const u = await unbanUser(deps, target.id, owner.id);
    expect(u).toMatchObject({ ok: true, unsuspended: [targetOrg] });
    expect(await banned()).toBe(false);
  });

  it("an account being deleted stays banned", async () => {
    await h.tdb.admin`insert into public.account_deletions (user_id, purge_after) values (${stranger.id}, now() + interval '7 days')`;
    expect(await unbanUser(deps, stranger.id, owner.id)).toMatchObject({ ok: false });
  });
});
