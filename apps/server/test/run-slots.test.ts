/**
 * D-413: a run holds a working slot while it works, not while it waits for a person. Before, five
 * runs waiting for an approval or a secret in one workspace used up its places in the queue, and
 * every new message there stayed queued for as long as they waited (up to 24 hours).
 */
import { fileURLToPath } from "node:url";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { RunSlots } from "../src/worker/run-slots.ts";
import { type Harness, j, startHarness } from "./helpers.ts";

describe("RunSlots", () => {
  const tick = () => new Promise((r) => setTimeout(r, 0));

  it("lets a workspace work on its limit, and the next run starts when one ends", async () => {
    const slots = new RunSlots(10, 2);
    await slots.acquire("a");
    await slots.acquire("a");
    let third = false;
    void slots.acquire("a").then(() => {
      third = true;
    });
    await tick();
    expect(third).toBe(false);
    // Another workspace isn't held back by it.
    await slots.acquire("b");
    slots.release("a");
    await tick();
    expect(third).toBe(true);
    expect(slots.counts).toEqual({ working: 3, waiting: 0 });
  });

  it("keeps to the worker's total, first come first served", async () => {
    const slots = new RunSlots(2, 0);
    await slots.acquire("a");
    await slots.acquire("b");
    const order: string[] = [];
    void slots.acquire("c").then(() => order.push("c"));
    void slots.acquire("d").then(() => order.push("d"));
    await tick();
    expect(order).toEqual([]);
    slots.release("a");
    await tick();
    expect(order).toEqual(["c"]);
    slots.release("b");
    await tick();
    expect(order).toEqual(["c", "d"]);
  });

  it("a run waiting for a person frees its slot, and takes one again afterwards", async () => {
    const slots = new RunSlots(1, 1);
    await slots.acquire("a");
    let answered = () => {};
    const approval = new Promise<void>((resolve) => {
      answered = resolve;
    });
    let resumed = false;
    const first = slots
      .idle("a", () => approval)
      .then(() => {
        resumed = true;
      });
    // While it waits, another run of the same workspace works.
    await slots.acquire("a");
    expect(slots.counts.working).toBe(1);
    answered();
    await tick();
    // The answer came, but the slot is taken: it goes on when that run ends.
    expect(resumed).toBe(false);
    slots.release("a");
    await first;
    expect(resumed).toBe(true);
    expect(slots.counts).toEqual({ working: 1, waiting: 0 });
  });

  it("takes its slot again even when the wait fails", async () => {
    const slots = new RunSlots(1, 1);
    await slots.acquire("a");
    await expect(slots.idle("a", () => Promise.reject(new Error("gone")))).rejects.toThrow("gone");
    expect(slots.counts.working).toBe(1);
  });
});

const fixture = (name: string) => fileURLToPath(new URL(`./fixtures/${name}`, import.meta.url));

describe("runs waiting for a person don't hold up the workspace", () => {
  let h: Harness;
  let token: string;
  let bot: string;
  let other: string;

  const post = async (path: string, json: unknown) => {
    const r = await h.request(path, { method: "POST", token, json });
    if (r.status >= 300) throw new Error(`${path}: ${r.status} ${await r.text()}`);
    return j(r);
  };
  const ask = async (text: string, to = bot) => {
    const conv = await post("/v1/conversations", { bot_id: to });
    return (await post(`/v1/conversations/${conv.id}/messages`, { text })).run_id as string;
  };

  beforeAll(async () => {
    // secrets.json first: chat.json answers anything else.
    h = await startHarness({
      worker: { fixtures: `${fixture("secrets.json")},${fixture("chat.json")}` },
    });
    token = (await h.user("slots-owner@example.com")).token;
    const org = (await post("/v1/orgs", { name: "Slots" })).id;
    const credential = (
      await post("/v1/credentials", {
        org_id: org,
        provider: "openrouter",
        label: "k",
        api_key: "sk-slots",
      })
    ).id;
    await h.tdb
      .admin`update public.entitlements set limits = limits - 'max_bots' where org_id = ${org}`;
    const make = async (name: string) =>
      (
        await post("/v1/bots", {
          org_id: org,
          name,
          model_policy: { primary: { credential_id: credential, model: "fixture-main" } },
        })
      ).id as string;
    bot = await make("Waiter");
    other = await make("Greeter");
  }, 60_000);

  afterAll(async () => {
    await h?.stop();
  });

  it("a new message is answered while five runs wait for the person", async () => {
    // Five runs each ask for a secret and wait for it: as many as the workspace may have working.
    const waiting = [];
    for (let i = 0; i < 5; i++) waiting.push(await ask("please charge the customer"));
    for (let i = 0; i < 150; i++) {
      const [n] = await h.tdb.admin<{ n: number }[]>`
        select count(*)::int as n from public.secret_requests
        where run_id in ${h.tdb.admin(waiting)} and status = 'pending'`;
      if (n?.n === 5) break;
      await new Promise((r) => setTimeout(r, 200));
    }
    const [asked] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.secret_requests
      where run_id in ${h.tdb.admin(waiting)} and status = 'pending'`;
    expect(asked?.n).toBe(5);

    // Another bot of the same workspace (a bot is told what it is doing in its other chats, and
    // the fixture would answer that note instead).
    const hello = await ask("hello", other);
    let status = "";
    for (let i = 0; i < 100 && status !== "completed"; i++) {
      status = (await j(await h.request(`/v1/runs/${hello}`, { token }))).status;
      if (status !== "completed") await new Promise((r) => setTimeout(r, 200));
    }
    // Before, it stayed queued behind the five until one of them was answered or gave up.
    expect(status).toBe("completed");
    const still = await h.tdb.admin<{ status: string }[]>`
      select status from public.runs where id in ${h.tdb.admin(waiting)}`;
    expect(still.every((r) => !["completed", "failed", "cancelled"].includes(r.status))).toBe(true);
  }, 90_000);
});
