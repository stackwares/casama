/**
 * Live data cards (docs/RICH-CARDS-PLAN.md): the live.* tools show a card and keep the call; the
 * routes refresh it without the model, only for people who can read the chat; views, reports,
 * pins and the person's card preferences. Providers answer from recorded fixtures.
 */
import { readFileSync } from "node:fs";
import {
  LIVE_CARD_SHOWN,
  LiveEngine,
  liveCache,
  liveHttp,
  registerLiveTools,
  ToolRegistry,
} from "@casama/agent";
import { afterAll, beforeAll, describe, expect, it, vi } from "vitest";
import { type Harness, j, startHarness } from "./helpers.ts";

const fx = (name: string) =>
  readFileSync(
    new URL(`../../../packages/agent/test/fixtures/live/${name}`, import.meta.url),
    "utf8",
  );

let providerCalls: string[] = [];
const fakeFetch = (async (input: string | URL | Request) => {
  const url = new URL(String(input instanceof Request ? input.url : input));
  providerCalls.push(url.host);
  const body =
    url.host === "geocoding-api.open-meteo.com"
      ? fx("geo-manila.json")
      : url.host === "api.met.no"
        ? fx("met-manila.json")
        : url.host === "api.coingecko.com"
          ? fx("cg-btc.json")
          : url.host === "api.frankfurter.dev"
            ? fx("fx-usd-php.json")
            : null;
  return body === null ? new Response("no", { status: 404 }) : new Response(body, { status: 200 });
}) as typeof fetch;

let h: Harness;
let me: { id: string; token: string };
let outsider: { id: string; token: string };
let orgId: string;
let botId: string;
let runId: string;
const reg = new ToolRegistry();
const events: Array<{ type: string; payload: Record<string, unknown> }> = [];

const call = async (name: string, args: unknown) => {
  const def = reg.get(name);
  if (!def) throw new Error(`no tool ${name}`);
  return def.execute(
    def.schema.parse(args) as never,
    {
      runId,
      botId,
      orgId,
      actingUserId: me.id,
      output: async () => {},
      emit: async (type: string, payload: Record<string, unknown>) =>
        void events.push({ type, payload }),
    } as never,
  );
};
const cardOf = (e: { payload: Record<string, unknown> }) => {
  const msgs = e.payload.messages as Array<{
    updateComponents?: { components: Array<Record<string, unknown>> };
  }>;
  return msgs.find((m) => m.updateComponents)?.updateComponents?.components[0] as Record<
    string,
    unknown
  >;
};

beforeAll(async () => {
  vi.useFakeTimers({ toFake: ["Date"] });
  vi.setSystemTime(new Date("2026-11-20T12:30:00Z"));
  h = await startHarness();
  const engine = new LiveEngine(liveHttp(fakeFetch), liveCache(h.handle.db), {
    openMeteo: false,
    unofficial: false,
  });
  h.deps.liveEngine = engine;
  registerLiveTools(reg, { db: h.handle.db, engine });
  me = await h.user("live-me@example.com");
  outsider = await h.user("live-outsider@example.com");
  orgId = (
    await j(await h.request("/v1/orgs", { method: "POST", token: me.token, json: { name: "L" } }))
  ).id;
  const [b] = await h.tdb.admin<{ id: string }[]>`
    insert into public.bots (org_id, created_by, name) values (${orgId}, ${me.id}, 'Sky') returning id`;
  botId = b!.id;
  const [conv] = await h.tdb.admin<{ id: string }[]>`
    insert into public.conversations (org_id, bot_id, created_by) values (${orgId}, ${botId}, ${me.id}) returning id`;
  runId = (
    await h.tdb.admin<{ id: string }[]>`
      insert into public.runs (org_id, bot_id, trigger, status, created_by, conversation_id)
      values (${orgId}, ${botId}, 'chat', 'running', ${me.id}, ${conv!.id}) returning id`
  )[0]!.id;
  await h.tdb.admin`update public.profiles set timezone = 'Asia/Manila' where user_id = ${me.id}`;
});

afterAll(async () => {
  vi.useRealTimers();
  await h?.stop();
});

describe("live.* tools", () => {
  it("only the core four go out with every call; the rest exist", () => {
    for (const n of [
      "live.weather",
      "live.quote",
      "live.fx",
      "live.time",
      "live.sun",
      "live.quakes",
      "live.define",
    ])
      expect(reg.get(n), n).toBeTruthy();
    // Paid or unofficial providers stay out without their keys.
    for (const n of [
      "live.flight",
      "live.parcel",
      "live.film",
      "live.sports",
      "live.markets",
      "live.air",
    ])
      expect(reg.get(n), n).toBeFalsy();
  });

  it("shows a weather card, keeps the call, and tells the model not to repeat it", async () => {
    events.length = 0;
    const r = await call("live.weather", { place: "Manila", when: "tomorrow" });
    expect(r.content).toContain("Manila, PH on 2026-11-21");
    expect(r.content).toContain(LIVE_CARD_SHOWN);
    const shown = events.find((e) => e.type === "ui.shown");
    expect(shown?.payload.live_card).toBe("weather");
    const card = cardOf(shown!);
    expect(card.component).toBe("Weather");
    const ref = (card.live as { ref: string }).ref;
    const [row] = await h.tdb.admin<
      { tool: string; card: string; args: { place: { name: string } }; run_id: string }[]
    >`
      select tool, card, args, run_id from public.live_cards where id = ${ref}`;
    expect(row).toMatchObject({ tool: "weather", card: "Weather", run_id: runId });
    expect(row!.args.place.name).toBe("Manila");
  });

  it("answers in text only when asked", async () => {
    events.length = 0;
    const r = await call("live.fx", { from: "USD", to: ["PHP"], amount: 10, card: false });
    expect(r.content).toMatch(/10 USD = 636\.95 PHP/);
    expect(r.content).not.toContain(LIVE_CARD_SHOWN);
    expect(events).toHaveLength(0);
  });

  it("says what's wrong in words the bot can act on", async () => {
    await expect(call("live.quote", { symbols: ["AAPL"] })).rejects.toThrow(
      /Stock prices aren't set up.*web\.search/s,
    );
  });
});

describe("refreshing a card", () => {
  let ref: string;
  beforeAll(async () => {
    events.length = 0;
    await call("live.quote", { symbols: ["BTC"] });
    ref = (cardOf(events.find((e) => e.type === "ui.shown")!).live as { ref: string }).ref;
  });

  it("runs the stored call again through the cache, with no model", async () => {
    providerCalls = [];
    const r = await j(
      await h.request(`/v1/live-cards/${ref}/refresh`, {
        method: "POST",
        token: me.token,
        json: {},
      }),
    );
    expect(r.card.component).toBe("Quote");
    expect(r.card.symbol).toBe("BTC");
    expect(r.card.live.ref).toBe(ref);
    expect(r.error).toBeNull();
    // Fresh in the shared cache: no provider call.
    expect(providerCalls).toHaveLength(0);
    const list = await j(await h.request(`/v1/live-cards?ids=${ref}`, { token: me.token }));
    expect(list.items[0].id).toBe(ref);
  });

  it("is only for people who can read the chat", async () => {
    const r = await h.request(`/v1/live-cards/${ref}/refresh`, {
      method: "POST",
      token: outsider.token,
      json: {},
    });
    expect(r.status).toBe(404);
    const list = await j(await h.request(`/v1/live-cards?ids=${ref}`, { token: outsider.token }));
    expect(list.items).toHaveLength(0);
  });

  it("takes only views the card has", async () => {
    const bad = await h.request(`/v1/live-cards/${ref}/refresh`, {
      method: "POST",
      token: me.token,
      json: { view: "../../etc" },
    });
    expect(bad.status).toBe(400);
  });

  it("shows another day of weather as a view, without saving it", async () => {
    events.length = 0;
    await call("live.weather", { place: "Manila" });
    const wref = (cardOf(events.find((e) => e.type === "ui.shown")!).live as { ref: string }).ref;
    const r = await j(
      await h.request(`/v1/live-cards/${wref}/refresh`, {
        method: "POST",
        token: me.token,
        json: { view: "tomorrow" },
      }),
    );
    expect(r.card.when).toBe("2026-11-21");
    const [row] = await h.tdb.admin<
      { data: { when: string } }[]
    >`select data from public.live_cards where id = ${wref}`;
    expect(row!.data.when).toBe("now");
  });

  it("takes reports of wrong data", async () => {
    const r = await j(
      await h.request(`/v1/live-cards/${ref}/report`, { method: "POST", token: me.token }),
    );
    expect(r.ok).toBe(true);
    const [row] = await h.tdb.admin<{ provider: string; card: string }[]>`
      select provider, card from public.live_card_reports where live_card_id = ${ref}`;
    expect(row).toMatchObject({ provider: "coingecko", card: "Quote" });
  });

  it("pins to the widgets as a canvas that waits for the bot's permission", async () => {
    const r = await j(
      await h.request(`/v1/live-cards/${ref}/pin`, {
        method: "POST",
        token: me.token,
        json: { units: { temp: "C" } },
      }),
    );
    expect(r.status).toBe("waiting");
    const [c] = await h.tdb.admin<
      { name: string; bot_id: string }[]
    >`select name, bot_id from public.widget_canvases where id = ${r.canvas_id}`;
    expect(c).toMatchObject({ name: "Price · BTC", bot_id: botId });
    const un = await j(
      await h.request(`/v1/live-cards/${ref}/pin`, { method: "DELETE", token: me.token }),
    );
    expect(un.ok).toBe(true);
    const gone = await h.tdb.admin`select 1 from public.widget_canvases where id = ${r.canvas_id}`;
    expect(gone).toHaveLength(0);
  });
});

describe("card preferences", () => {
  it("keeps a home city (rounded) and units, and the tools use them", async () => {
    const places = await j(await h.request("/v1/places?q=Manila", { token: me.token }));
    expect(places.items[0]).toMatchObject({ name: "Manila", country: "PH", tz: "Asia/Manila" });
    const saved = await j(
      await h.request("/v1/me/card-prefs", {
        method: "PUT",
        token: me.token,
        json: {
          home_place: { ...places.items[0], lat: 14.604256, lng: 120.98221 },
          units: { temp: "F" },
        },
      }),
    );
    expect(saved.home_place).toMatchObject({ name: "Manila", lat: 14.6, lng: 120.98 });
    // The effective units: the person's choice over their time zone's (Asia/Manila: metric).
    expect(saved.units).toEqual({ temp: "F", wind: "kph", precip: "mm", distance: "km" });
    const r = await call("live.weather", {});
    expect(r.content).toMatch(/°F/);
    const cleared = await j(
      await h.request("/v1/me/card-prefs", {
        method: "PUT",
        token: me.token,
        json: { home_place: null },
      }),
    );
    expect(cleared.home_place).toBeNull();
    expect(cleared.units).toMatchObject({ temp: "F" });
  });
});
