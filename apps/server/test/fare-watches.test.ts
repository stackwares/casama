/**
 * Price watches on Fares cards (docs/FLIGHT-SEARCH-PLAN.md §9, Phase 3 "done when"): a watch
 * started from the card or by the bot, checked by the worker with a fake fare provider, pushes once
 * when the price drops under the target, not again the same day, and ends after its date. Five
 * per workspace; Stop ends one; Settings lists them.
 */
import { readFileSync } from "node:fs";
import {
  type FareProvider,
  type FareSearch,
  LiveEngine,
  liveCache,
  liveHttp,
  parseKiwi,
  registerLiveTools,
  resetFareProviders,
  sweepFareWatches,
  ToolRegistry,
} from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const KIWI = parseKiwi(
  JSON.parse(
    readFileSync(
      new URL(
        "../../../packages/agent/test/fixtures/fares/kiwi-mnl-tyo-return.json",
        import.meta.url,
      ),
      "utf8",
    ),
  ),
);
const BASE = Math.min(...KIWI.options.map((o) => o.price));

/** An engine whose only fare provider (Kiwi, free) answers prices scaled by [k]. */
function engineAt(k: number) {
  resetFareProviders();
  const e = new LiveEngine(liveHttp(fetch), liveCache(null), {
    openMeteo: false,
    unofficial: false,
    kiwiMcpUrl: "https://mcp.kiwi.com",
  });
  const answer: FareSearch = {
    ...KIWI,
    options: KIWI.options.map((o) => ({ ...o, price: Math.round(o.price * k) })),
  };
  e.fareProviders = {
    kiwi: { id: "kiwi", paid: false, search: async () => answer } as FareProvider,
  };
  return e;
}

let h: Harness;
let me: { id: string; token: string };
let mate: { id: string; token: string };
let orgId = "";
let botId = "";
let runId = "";
const reg = new ToolRegistry();
const pushes: Array<{ userId: string; title: string; body: string; link?: string }> = [];
const notify = async (
  userId: string,
  _org: string,
  m: { title: string; body: string; link?: string },
) => void pushes.push({ userId, ...m });
const trip = { from: "Manila", to: "Tokyo", depart: "2027-03-12", return: "2027-03-19" };

const showCard = async (args: Record<string, unknown> = {}) => {
  const def = reg.get("live.fares")!;
  const events: Array<Record<string, unknown>> = [];
  const r = (await def.execute(
    def.schema.parse({ ...trip, ...args }) as never,
    {
      runId,
      botId,
      orgId,
      actingUserId: me.id,
      output: async () => {},
      emit: async (_t: string, payload: Record<string, unknown>) => void events.push(payload),
    } as never,
  )) as { content: string };
  const [card] = await h.tdb.admin<{ id: string }[]>`
    select id from public.live_cards where run_id = ${runId} order by created_at desc limit 1`;
  return { id: card!.id, content: r.content };
};

beforeAll(async () => {
  h = await startHarness();
  me = await h.user("watch-me@example.com");
  mate = await h.user("watch-mate@example.com");
  orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: me.token, json: { name: "W" } }))
  ).id;
  await h.tdb
    .admin`insert into public.memberships (org_id, user_id, role) values (${orgId}, ${mate.id}, 'member')`;
  const [b] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name) values (${orgId}, ${me.id}, 'Trips') returning id`;
  botId = b!.id;
  const [conv] = await h.tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${me.id}) returning id`;
  runId = (
    await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status, created_by, conversation_id)
      values (${orgId}, ${botId}, 'chat', 'running', ${me.id}, ${conv!.id}) returning id`
  )[0]!.id;
  registerLiveTools(reg, { db: h.handle.db, engine: engineAt(1) });
}, 90_000);
afterAll(async () => {
  await h?.stop();
});

describe("fare watches", () => {
  let cardId = "";

  it("starts from the card, is the person's own, and lists in settings", async () => {
    cardId = (await showCard()).id;
    const res = await h.request(`/v1/live-cards/${cardId}/watch`, {
      method: "POST",
      token: me.token,
      json: { below: Math.round(BASE * 0.95) },
    });
    expect(res.status).toBe(200);
    const w = await j(res);
    expect(w).toMatchObject({
      card_id: cardId,
      bot_id: botId,
      below: Math.round(BASE * 0.95),
      currency: "PHP",
      first_price: BASE,
    });
    expect(w.route).toMatch(/^Manila → Tokyo · Mar 12/);
    expect(w.ends_at.slice(0, 10) <= "2027-03-12").toBe(true);
    const mine = await j(await h.request("/v1/me/fare-watches", { token: me.token }));
    expect(mine.items.map((x: { id: string }) => x.id)).toEqual([w.id]);
    const theirs = await j(await h.request("/v1/me/fare-watches", { token: mate.token }));
    expect(theirs.items).toEqual([]);
  });

  it("pushes once when the price drops under the target, not again the same day", async () => {
    const [w] = await h.tdb.admin<{ id: string; next_check_at: Date }[]>`
      select id, next_check_at from public.fare_watches where live_card_id = ${cardId}`;
    const t1 = new Date(w!.next_check_at.valueOf() + 60_000);
    // Not due yet: nothing is checked.
    const early = await sweepFareWatches(h.handle.db, engineAt(0.5), notify, new Date());
    expect(early.checked).toBe(0);
    // A small move above the target: checked, no push.
    expect((await sweepFareWatches(h.handle.db, engineAt(0.99), notify, t1)).pushed).toBe(0);
    const t2 = new Date(t1.valueOf() + 7 * 3_600_000);
    const r = await sweepFareWatches(h.handle.db, engineAt(0.9), notify, t2);
    expect(r).toMatchObject({ checked: 1, pushed: 1 });
    expect(pushes).toHaveLength(1);
    expect(pushes[0]).toMatchObject({ userId: me.id, link: `/bots/${botId}/chat` });
    expect(pushes[0]!.body).toMatch(/Manila → Tokyo .* is now .*\(was /);
    const t3 = new Date(t2.valueOf() + 7 * 3_600_000);
    expect((await sweepFareWatches(h.handle.db, engineAt(0.7), notify, t3)).pushed).toBe(0);
    expect(pushes).toHaveLength(1);
    const [after] = await h.tdb.admin<{ last_price: string; pushed_price: string }[]>`
      select last_price, pushed_price from public.fare_watches where id = ${w!.id}`;
    expect(Number(after!.last_price)).toBe(
      Math.round(Math.min(...KIWI.options.map((o) => Math.round(o.price * 0.7)))),
    );
    expect(Number(after!.pushed_price)).toBeLessThan(BASE);
  });

  it("starts from the bot's call, up to five per workspace, and Stop ends one", async () => {
    const byBot = await showCard({ watch: {} });
    expect(byBot.content).toMatch(/Watching this price until/);
    const ids = [byBot.id];
    for (let i = 0; i < 3; i++) {
      const c = await showCard();
      const res = await h.request(`/v1/live-cards/${c.id}/watch`, {
        method: "POST",
        token: me.token,
        json: {},
      });
      expect(res.status).toBe(200);
      ids.push(c.id);
    }
    const sixth = await showCard();
    const res = await h.request(`/v1/live-cards/${sixth.id}/watch`, {
      method: "POST",
      token: me.token,
      json: {},
    });
    expect(res.status).toBe(400);
    expect((await j(res)).code).toBe("too_many_watches");
    expect((await showCard({ watch: { below: 1 } })).content).toMatch(/didn't start/);
    const stop = await h.request(`/v1/live-cards/${ids[0]}/watch`, {
      method: "DELETE",
      token: me.token,
    });
    expect(await j(stop)).toEqual({ ok: true });
    const list = await j(await h.request("/v1/me/fare-watches", { token: me.token }));
    expect(list.items).toHaveLength(4);
  });

  it("ends after its date", async () => {
    const [last] = await h.tdb.admin<{ ends_at: Date }[]>`
      select max(ends_at) as ends_at from public.fare_watches where org_id = ${orgId} and stopped_at is null`;
    const r = await sweepFareWatches(
      h.handle.db,
      engineAt(0.5),
      notify,
      new Date(last!.ends_at.valueOf() + 1000),
    );
    expect(r.ended).toBe(4);
    const [n] = await h.tdb.admin<{ n: number }[]>`
      select count(*)::int as n from public.fare_watches where org_id = ${orgId} and stopped_why = 'ended'`;
    expect(n!.n).toBe(4);
  });

  it("only watches Fares cards", async () => {
    const [other] = await h.tdb.admin<{ id: string }[]>`
      insert into public.live_cards (org_id, bot_id, run_id, user_id, card, tool, args, data)
      values (${orgId}, ${botId}, ${runId}, ${me.id}, 'Weather', 'weather', '{}', '{"component":"Weather"}') returning id`;
    const res = await h.request(`/v1/live-cards/${other!.id}/watch`, {
      method: "POST",
      token: me.token,
      json: {},
    });
    expect(res.status).toBe(400);
  });
});
