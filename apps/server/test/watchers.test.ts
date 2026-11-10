/** Watchers (D-116): checks without a model; a change wakes the bot within one check. */
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { fileURLToPath } from "node:url";
import { checkWatchers, registerWatcherTools, ToolRegistry } from "@kasama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const FIXTURES = fileURLToPath(new URL("./fixtures/watchers.json", import.meta.url));
let h: Harness;
let page: Server;
let pageUrl: string;
let price = "$120";
let owner: { id: string; token: string };
let orgId: string;
let botId: string;
let runId: string;

const settle = async () => {
  for (let i = 0; i < 200; i++) {
    const [r] = await h.tdb.admin<
      { n: number }[]
    >`select count(*)::int as n from public.runs where status in ('queued', 'running')`;
    if (!r?.n) return;
    await new Promise((res) => setTimeout(res, 100));
  }
};
const check = async (at: Date) => {
  const started = await checkWatchers(
    { db: h.handle.db, fetch, startRun: (id) => h.deps.workflows.startRun(id) },
    at,
  );
  await settle();
  return started;
};
const tokens = async () =>
  Number(
    (
      await h.tdb.admin<
        { n: string }[]
      >`select coalesce(sum(quantity), 0) as n from public.usage_ledger`
    )[0]?.n ?? 0,
  );

beforeAll(async () => {
  page = createServer((_req, res) => {
    res.setHeader("content-type", "text/html");
    res.end(
      `<html><head><script>var x = ${Date.now()};</script></head><body><nav>Home</nav><h1>Price</h1><p>Now ${price}</p></body></html>`,
    );
  }).listen(0, "127.0.0.1");
  await new Promise((r) => page.once("listening", r));
  pageUrl = `http://127.0.0.1:${(page.address() as AddressInfo).port}/item`;
  h = await startHarness({ worker: { fixtures: FIXTURES } });
  owner = await h.user("watch@example.com");
  orgId = (
    await j(
      await h.request("/v1/orgs", { method: "POST", token: owner.token, json: { name: "W" } }),
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
          name: "Lookout",
          model_policy: { primary: { credential_id: cred.id, model: "fixture-main" } },
        },
      }),
    )
  ).id;
  const [run] = await h.tdb.admin<
    { id: string }[]
  >`insert into public.runs (org_id, bot_id, trigger, status, created_by) values (${orgId}, ${botId}, 'chat', 'completed', ${owner.id}) returning id`;
  runId = run!.id;
}, 60_000);
afterAll(async () => {
  await h?.stop();
  page?.close();
});

const reg = new ToolRegistry();
const ctx = () => ({ runId, botId, orgId, output: async () => {}, emit: async () => {} }) as never;

describe("watchers", () => {
  it("a page watcher records a baseline, ignores unchanged checks, and wakes the bot on a change", async () => {
    registerWatcherTools(reg, { db: h.handle.db });
    await reg
      .get("watchers.create")!
      .execute(
        {
          name: "Price drop",
          kind: "page_change",
          url: pageUrl,
          anchor: "Price",
          condition: "the price changes",
          check_every_minutes: 5,
        } as never,
        ctx(),
      );
    const t0 = new Date();
    expect(await check(t0)).toEqual([]); // baseline
    const before = await tokens();
    expect(await check(new Date(t0.getTime() + 5 * 60_000))).toEqual([]); // unchanged (the script tag changes; it's ignored)
    expect(await tokens()).toBe(before); // no model tokens
    price = "$99";
    const fired = await check(new Date(t0.getTime() + 10 * 60_000)); // within one interval
    expect(fired).toHaveLength(1);
    const [m] = await h.tdb.admin<
      { content: Array<{ text: string }> }[]
    >`select content from public.messages where run_id = ${fired[0] as string} and role = 'user'`;
    expect(m?.content[0]?.text).toContain("Now $99");
    const [r] = await h.tdb.admin<
      { status: string; trigger: string }[]
    >`select status, trigger from public.runs where id = ${fired[0] as string}`;
    expect(r).toEqual({ status: "completed", trigger: "watcher" });
  });

  it("a time watcher fires once and finishes; a reply watcher fires on a person's comment", async () => {
    await reg
      .get("watchers.create")!
      .execute(
        {
          name: "Call back",
          kind: "time",
          at: new Date(Date.now() + 60_000).toISOString(),
        } as never,
        ctx(),
      );
    const [task] = await h.tdb.admin<
      { id: string }[]
    >`insert into public.tasks (org_id, title) values (${orgId}, 'Quote') returning id`;
    await reg
      .get("watchers.create")!
      .execute(
        { name: "Client reply", kind: "reply", task_id: task!.id, check_every_minutes: 1 } as never,
        ctx(),
      );
    const later = new Date(Date.now() + 20 * 60_000);
    await check(later); // baselines; the time is due now
    const [tw] = await h.tdb.admin<
      { status: string; fired_count: number }[]
    >`select status, fired_count from public.watchers where name = 'Call back'`;
    expect(tw).toEqual({ status: "done", fired_count: 1 });
    await h.tdb
      .admin`insert into public.task_comments (org_id, task_id, author_type, author_user_id, body_md) values (${orgId}, ${task!.id}, 'user', ${owner.id}, 'Approved, go ahead')`;
    expect(await check(new Date(later.getTime() + 2 * 60_000))).toHaveLength(1);
  });

  it("people pause, resume and delete watchers", async () => {
    const list = await j(await h.request(`/v1/watchers?bot_id=${botId}`, { token: owner.token }));
    const w = list.items.find((x: { name: string }) => x.name === "Price drop");
    expect(w).toMatchObject({ kind: "page_change", fired_count: 1, status: "active" });
    expect(
      (
        await j(
          await h.request(`/v1/watchers/${w.id}`, {
            method: "PATCH",
            token: owner.token,
            json: { status: "paused" },
          }),
        )
      ).status,
    ).toBe("paused");
    price = "$50";
    expect(await check(new Date(Date.now() + 60 * 60_000))).toEqual([]);
    expect(
      (await h.request(`/v1/watchers/${w.id}`, { method: "DELETE", token: owner.token })).status,
    ).toBe(200);
  });
});
