/**
 * Check-ins fetch first (docs/USAGE-PLAN.md step 5): the usual reads run before the first model
 * call, an unchanged scheduled scan makes no model call at all, a scan out of steps still saves
 * what it found, a quiet scan saves no memories, and check-ins leave room in the day's limit.
 */
import { createDb, type DbHandle } from "@casama/db";
import { createAuthUser, startTestDatabase, type TestDatabase } from "@casama/db/testing";
import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { z } from "zod";
import {
  checkinPrefetch,
  PREFETCH_CALL_PREFIX,
  prefetchCoversApps,
  scanDigest,
} from "../src/checkin-prefetch.ts";
import { CHECKIN_MAX_STEPS, checkinCapReached, NOTHING_NEW, scanCronFor } from "../src/checkins.ts";
import type { GatewayEvent, ModelGateway, ModelRequest } from "../src/gateway/types.ts";
import {
  builtinTools,
  CredentialResolver,
  directSteps,
  hashEmbedder,
  PostgresMemoryStore,
  runAgent,
} from "../src/index.ts";

const GMAIL = "composio.apps.gmail_fetch_emails";
const CALENDAR = "composio.apps.googlecalendar_events_list";
const inbox = (...ids: string[]) =>
  JSON.stringify({
    data: {
      messages: ids.map((id) => ({ messageId: id, threadId: `t-${id}`, subject: `Mail ${id}` })),
    },
    log_id: `log-${Math.random()}`,
  });
const calendar = (...events: Array<[string, string]>) =>
  JSON.stringify({
    data: { items: events.map(([id, etag]) => ({ id, etag, summary: `Event ${id}` })) },
    log_id: `log-${Math.random()}`,
  });

describe("the first reads", () => {
  const now = new Date("2026-11-17T09:30:00Z");
  it("are the inbox, the next two days of calendar and the board, once per app", () => {
    const calls = checkinPrefetch(
      [
        { name: "suggestions.add" },
        { name: "tasks.list" },
        { name: CALENDAR },
        { name: GMAIL },
        { name: "composio.work.gmail_fetch_emails" },
        { name: "composio.apps.gmail_list_threads" },
        { name: "mcp.linear.list_issues" },
      ],
      now,
    );
    expect(calls.map((c) => c.name)).toEqual([GMAIL, CALENDAR, "tasks.list"]);
    expect(calls.every((c) => c.callId.startsWith(PREFETCH_CALL_PREFIX))).toBe(true);
    expect(calls[0]?.args).toMatchObject({ max_results: 10, include_payload: false });
    expect(calls[1]?.args).toMatchObject({
      calendarId: "primary",
      timeMin: "2026-11-17T09:30:00.000Z",
      timeMax: "2026-11-19T09:30:00.000Z",
      singleEvents: true,
    });
    expect(checkinPrefetch([{ name: "suggestions.add" }], now)).toEqual([]);
  });

  it("cover a check-in only when it has no other app to look at", () => {
    expect(
      prefetchCoversApps([{ name: GMAIL }, { name: "composio.apps.gmail_list_threads" }]),
    ).toBe(true);
    expect(prefetchCoversApps([{ name: "tasks.list" }, { name: "suggestions.add" }])).toBe(true);
    expect(prefetchCoversApps([{ name: GMAIL }, { name: "mcp.linear.list_issues" }])).toBe(false);
  });

  it("digest to the same value until a message arrives or an event changes", () => {
    const a = scanDigest([
      { name: GMAIL, content: inbox("m1", "m2") },
      { name: CALENDAR, content: calendar(["e1", "v1"]) },
    ]);
    // Another call's log id, another order, a result cut short after the ids: still the same.
    expect(
      scanDigest([
        { name: CALENDAR, content: calendar(["e1", "v1"]) },
        { name: GMAIL, content: inbox("m2", "m1") },
      ]),
    ).toBe(a);
    expect(a).toMatch(/^[0-9a-f]{32}$/);
    expect(
      scanDigest([
        { name: GMAIL, content: inbox("m1", "m2", "m3") },
        { name: CALENDAR, content: calendar(["e1", "v1"]) },
      ]),
    ).not.toBe(a);
    expect(
      scanDigest([
        { name: GMAIL, content: inbox("m1", "m2") },
        { name: CALENDAR, content: calendar(["e1", "v2"]) },
      ]),
    ).not.toBe(a);
  });

  it("have no digest when a read failed or came back in an unknown shape", () => {
    expect(scanDigest([])).toBeNull();
    expect(
      scanDigest([{ name: GMAIL, content: "Error (app_error): Gmail is unreachable" }]),
    ).toBeNull();
    expect(scanDigest([{ name: GMAIL, content: '{"something":"else"}' }])).toBeNull();
    // An empty inbox and an empty calendar are states, not failures.
    expect(
      scanDigest([
        { name: GMAIL, content: '{"data":{"messages":[]}}' },
        { name: CALENDAR, content: '{"data":{"items":[]}}' },
      ]),
    ).toMatch(/^[0-9a-f]{32}$/);
  });
});

let tdb: TestDatabase;
let h: DbHandle;
let orgId: string;
let userId: string;
let credId: string;
/** What the fake apps return, and the calls they got. */
let mail: string;
let events: string;
const calls: Array<{ tool: string; args: Record<string, unknown> }> = [];

beforeAll(async () => {
  tdb = await startTestDatabase();
  h = createDb(tdb.url, { max: 5 });
  userId = (await createAuthUser(tdb.admin, "scanner@example.com")).id;
  const [org] = await tdb.admin<
    { id: string }[]
  >`insert into public.organizations (name, slug) values ('Scan Org', 'scan-org') returning id`;
  orgId = org!.id;
  await tdb.admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${userId}, 'owner')`;
  const [cred] = await tdb.admin<{ id: string }[]>`
    insert into public.model_credentials (org_id, provider, label, vault_secret_id)
    values (${orgId}, 'openrouter', 'Main', vault.create_secret('sk-live-SECRET-1234567890')) returning id`;
  credId = cred!.id;
});
afterAll(async () => {
  await h?.close();
  await tdb?.stop();
});
beforeEach(() => {
  mail = inbox("m1", "m2");
  events = calendar(["e1", "v1"]);
  calls.length = 0;
});

async function newBot(org = orgId) {
  const policy = { primary: { credential_id: credId, model: "fixture-primary" } };
  const [bot] = await tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name, model_policy, budget)
    values (${org}, ${userId}, 'Ada', ${tdb.admin.json(policy)}, ${tdb.admin.json({ per_run_usd: 50, daily_usd: 500 })})
    returning id`;
  await tdb.admin`
    insert into public.bot_checkins (bot_id, org_id, user_id, enabled, daily_cap_usd)
    values (${bot!.id}, ${org}, ${userId}, true, 1)`;
  const [routine] = await tdb.admin<{ id: string }[]>`
    insert into public.routines (org_id, bot_id, name, instructions_md, kind, notify, created_by)
    values (${org}, ${bot!.id}, 'Check-in scan', 'Check-in scan.', 'scan', false, ${userId}) returning id`;
  return { botId: bot!.id, routineId: routine!.id, org };
}

async function scan(
  b: { botId: string; routineId: string; org: string },
  reason?: string,
  costUsd = 0,
) {
  const budget = {
    task: "Check-in scan. Look over what you can reach.",
    ...(reason ? { scan_reason: reason } : {}),
  };
  const [run] = await tdb.admin<{ id: string }[]>`
    insert into public.runs (org_id, bot_id, created_by, trigger, routine_id, budget, cost_usd)
    values (${b.org}, ${b.botId}, ${userId}, 'routine', ${b.routineId}, ${tdb.admin.json(budget)}, ${costUsd})
    returning id`;
  return run!.id;
}

const finish: GatewayEvent = {
  type: "finish",
  usage: { inputTokens: 100, outputTokens: 10 },
  finishReason: "stop",
  model: "",
};
/** A model scripted by a function of the request; every request is kept. */
function scripted(reply: (req: ModelRequest, n: number) => GatewayEvent[]) {
  const requests: ModelRequest[] = [];
  const gateway: ModelGateway = {
    async *stream(req) {
      requests.push(req);
      for (const ev of reply(req, requests.length)) yield ev;
      yield finish;
    },
  };
  return { gateway, requests };
}
const isMemoryPass = (req: ModelRequest) =>
  req.system.join("\n").includes("extract lasting memories");

function deps(gateway: ModelGateway) {
  const embedder = hashEmbedder();
  const tools = builtinTools({
    db: h.db,
    memory: async () => new PostgresMemoryStore(h.db, embedder),
  });
  const read = (name: string, result: () => string) =>
    tools.register({
      name,
      description: `Reads ${name}.`,
      risk: "low",
      readOnly: true,
      schema: z.object({}).passthrough(),
      async execute(args) {
        calls.push({ tool: name, args: args as Record<string, unknown> });
        return { content: result() };
      },
    });
  read(GMAIL, () => mail);
  read(CALENDAR, () => events);
  read("composio.apps.googlecalendar_find_event", () => '{"data":{"items":[]}}');
  tools.register({
    name: "suggestions.add",
    description: "Suggests something to the person.",
    risk: "low",
    schema: z.object({ title: z.string() }),
    async execute(args) {
      calls.push({ tool: "suggestions.add", args });
      return { content: "Suggested." };
    },
  });
  return {
    db: h.db,
    gateway,
    tools,
    credentials: new CredentialResolver(h.db),
    embedderFor: async () => embedder,
    step: directSteps,
    deltaIntervalMs: 20,
    cancelPollMs: 50,
    fallback: { backoffMs: 1, sleep: async () => {} },
  };
}
const statusOf = async (runId: string) =>
  (await tdb.admin<{ status: string }[]>`select status from public.runs where id = ${runId}`)[0]
    ?.status;
const digestOf = async (botId: string) =>
  (
    await tdb.admin<
      { scan_digest: string | null }[]
    >`select scan_digest from public.bot_checkins where bot_id = ${botId}`
  )[0]?.scan_digest;

describe("a scan", () => {
  it("reads first, so the model starts with the results; a quiet one saves no memories", async () => {
    const bot = await newBot();
    const m = scripted(() => [{ type: "text", text: NOTHING_NEW }]);
    const runId = await scan(bot);
    expect((await runAgent(runId, deps(m.gateway))).status).toBe("completed");
    // Both reads ran before the only model call, which already had their results.
    // (The two reads run together, so either may land first.)
    expect(calls.map((c) => c.tool).sort()).toEqual([GMAIL, CALENDAR].sort());
    expect(m.requests).toHaveLength(1);
    const results = m.requests[0]?.messages.filter((x) => x.role === "tool") ?? [];
    expect(results.map((r) => r.name)).toEqual([GMAIL, CALENDAR]);
    expect(results[0]?.content).toContain("Mail m1");
    // No memory pass after NOTHING_NEW, and the digest is kept for next time.
    expect(m.requests.some(isMemoryPass)).toBe(false);
    expect(await digestOf(bot.botId)).toMatch(/^[0-9a-f]{32}$/);
  });

  it("on its schedule makes no model call when nothing changed since the last one", async () => {
    const bot = await newBot();
    const first = scripted(() => [{ type: "text", text: NOTHING_NEW }]);
    await runAgent(await scan(bot), deps(first.gateway));
    expect(first.requests).toHaveLength(1);

    const second = scripted(() => [{ type: "text", text: "should not be asked" }]);
    const runId = await scan(bot);
    expect((await runAgent(runId, deps(second.gateway))).status).toBe("completed");
    expect(second.requests).toHaveLength(0);
    expect(await statusOf(runId)).toBe("completed");
  });

  it("goes to the model when a message arrived, and when it was asked for", async () => {
    const bot = await newBot();
    const quiet = () =>
      scripted((req) => [
        { type: "text", text: isMemoryPass(req) ? '{"memories":[]}' : NOTHING_NEW },
      ]);
    await runAgent(await scan(bot), deps(quiet().gateway));

    // An app event asked for this scan: it runs even though the reads look the same.
    const asked = quiet();
    await runAgent(await scan(bot, "event"), deps(asked.gateway));
    expect(asked.requests).toHaveLength(1);

    // New mail: the scheduled scan runs, and what it suggests is saved.
    mail = inbox("m1", "m2", "m3");
    const before = await digestOf(bot.botId);
    const changed = scripted((req, n) =>
      isMemoryPass(req)
        ? [{ type: "text", text: '{"memories":[]}' }]
        : n === 1
          ? [
              {
                type: "tool_call",
                call: { callId: "s1", name: "suggestions__add", args: { title: "Reply to m3" } },
              },
            ]
          : [{ type: "text", text: "Added one suggestion." }],
    );
    const runId = await scan(bot);
    expect((await runAgent(runId, deps(changed.gateway))).status).toBe("completed");
    expect(calls.filter((c) => c.tool === "suggestions.add")).toHaveLength(1);
    expect(await digestOf(bot.botId)).not.toBe(before);
  });

  it("out of steps saves what it found on a last step and ends, instead of failing", async () => {
    const bot = await newBot();
    let lastStepTools: string[] | null = null;
    const m = scripted((req, n) => {
      const last = req.messages.at(-1);
      if (last?.role === "user" && last.content.includes("this is your last step")) {
        lastStepTools = (req.tools ?? []).map((t) => t.name);
        return [
          {
            type: "tool_call",
            call: { callId: "s-last", name: "suggestions__add", args: { title: "Book the ride" } },
          },
        ];
      }
      // A model that never stops reading.
      return [
        {
          type: "tool_call",
          call: {
            callId: `r${n}`,
            name: "composio__apps__googlecalendar_find_event",
            args: { query: `q${n}` },
          },
        },
      ];
    });
    const runId = await scan(bot);
    expect((await runAgent(runId, deps(m.gateway))).status).toBe("completed");
    expect(await statusOf(runId)).toBe("completed");
    // The reads took the first step; the last step offered only suggestions.add.
    expect(m.requests).toHaveLength(CHECKIN_MAX_STEPS - 1);
    expect(lastStepTools).toEqual(["suggestions__add"]);
    expect(calls.at(-1)).toEqual({ tool: "suggestions.add", args: { title: "Book the ride" } });
  });
});

describe("a scan that reaches the day's limit while it works", () => {
  it("gets one last step for its suggestions and ends, with no more reading", async () => {
    const bot = await newBot();
    // Today's check-ins already cost more than this bot's limit.
    await tdb.admin`update public.bot_checkins set daily_cap_usd = 0.01 where bot_id = ${bot.botId}`;
    await scan(bot, undefined, 0.05);
    const tools: string[][] = [];
    const m = scripted((req) => {
      tools.push((req.tools ?? []).map((t) => t.name));
      return [
        {
          type: "tool_call",
          call: { callId: "s1", name: "suggestions__add", args: { title: "Reply to m2" } },
        },
      ];
    });
    const runId = await scan(bot, "event");
    expect((await runAgent(runId, deps(m.gateway))).status).toBe("completed");
    // One model call: the reads came first, then the last step with only suggestions.add.
    expect(m.requests).toHaveLength(1);
    expect(tools).toEqual([["suggestions__add"]]);
    expect(
      calls
        .slice(0, 2)
        .map((c) => c.tool)
        .sort(),
    ).toEqual([GMAIL, CALENDAR].sort());
    expect(calls.slice(2).map((c) => c.tool)).toEqual(["suggestions.add"]);
  });
});

describe("when scans run", () => {
  it("every N hours from midnight, but once a day runs six hours after the brief", () => {
    expect(scanCronFor("08:00", 3)).toBe("0 */3 * * *");
    expect(scanCronFor("07:45", 12)).toBe("45 */12 * * *");
    // Midnight is inside quiet hours, where scheduled scans are skipped: it would never run.
    expect(scanCronFor("08:00", 24)).toBe("0 14 * * *");
    expect(scanCronFor("20:15", 24)).toBe("15 2 * * *");
  });
});

describe("check-ins and the day's limit", () => {
  it("stop at their share of the workspace's limit on Casama's key", async () => {
    // A workspace of its own, so the scans of the tests above don't count.
    const [org] = await tdb.admin<
      { id: string }[]
    >`insert into public.organizations (name, slug) values ('Share Org', 'share-org') returning id`;
    const shareOrg = org!.id;
    await tdb.admin`
      insert into public.entitlements (org_id, plan_code, limits)
      values (${shareOrg}, 'free', ${tdb.admin.json({ cloud_daily_usd: 0.25 })})`;
    const bot = await newBot(shareOrg);
    const other = await newBot(shareOrg);
    expect(await checkinCapReached(h.db, bot.botId)).toBe(false);
    // Another bot's scans count too: the share is the workspace's (40% of $0.25 is $0.10).
    await scan(other, undefined, 0.06);
    await scan(bot, undefined, 0.03);
    expect(await checkinCapReached(h.db, bot.botId)).toBe(false);
    await scan(bot, undefined, 0.02);
    expect(await checkinCapReached(h.db, bot.botId)).toBe(true);
    await tdb.admin`delete from public.entitlements where org_id = ${shareOrg}`;
    // Without a plan limit (self-hosted) only the bot's own cap counts.
    expect(await checkinCapReached(h.db, bot.botId)).toBe(false);
  });
});
