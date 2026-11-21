/**
 * The live data tools bots call (RICH-CARDS-PLAN §4.1, §11), one lazy group (`tools.load live`):
 * as core tools they'd add ~700 tokens to every model call (USAGE-PLAN step 4), and a conversation
 * that used them keeps them loaded (remembered groups). Each call
 * shows its card itself (a `ui.shown` event, kept with the reply like any card), keeps the call in
 * `live_cards` so the app can refresh it without the model, and gives the model a short text.
 */
import { randomUUID } from "node:crypto";
import type { Database } from "@casama/db";
import { checkComponents, surfaceMessages, UiCheckError } from "@casama/domain";
import { sql } from "drizzle-orm";
import { z } from "zod";
import { actingUserOf } from "../acting.ts";
import { track } from "../analytics.ts";
import { needCredits } from "../tools/autonomy.ts";
import { leanSchema, type ToolContext, ToolError, type ToolRegistry } from "../tools/registry.ts";
import { LiveDataError } from "./core.ts";
import type { LiveEngine, LivePerson, LiveResult, LiveTool } from "./engine.ts";
import { type FaresBilling, type FaresMeter, fareMoney } from "./fares.ts";
import { pageCard } from "./page.ts";
import type { Place } from "./places.ts";
import { startFareWatch, WatchError } from "./watches.ts";

/** What the model reads after a live card was shown. */
export const LIVE_CARD_SHOWN =
  "The person now sees this as a card with every number above, its source and time, so don't repeat them: answer in one short sentence with what matters (advice, the answer to their question). Never write a table or list of these numbers.";

const PLACE = z
  .string()
  .max(120)
  .optional()
  .describe(
    'A city or place ("Manila", "Springfield, US", "14.6,121.0"). Leave out for the person\'s home city.',
  );
const CARD = z
  .boolean()
  .optional()
  .describe("false: text only, no card (the person asked for text)");

const SPECS: Record<LiveTool, { name: string; description: string; schema: z.ZodObject }> = {
  weather: {
    name: "live.weather",
    description:
      "Weather now, for a day (today, tomorrow, a weekday, a date) or the week, from a forecast service; shows a weather card. Use it for any weather, rain, temperature or what-to-wear question instead of web search.",
    schema: z.object({
      place: PLACE,
      when: z
        .string()
        .max(20)
        .optional()
        .describe('"now" (default), "today", "tomorrow", "saturday", "2026-11-21" or "week"'),
      card: CARD,
    }),
  },
  quote: {
    name: "live.quote",
    description:
      "Live prices of stocks, ETFs, indexes and crypto (tickers like AAPL, BTC, ^GSPC, PSEi, or names like Apple or Bitcoin), with a chart; one symbol shows a quote card, several a watchlist. Use it instead of web search for any price.",
    schema: z.object({
      symbols: z.array(z.string().min(1).max(40)).min(1).max(12),
      range: z.enum(["1D", "1W", "1M", "3M", "1Y", "5Y"]).optional(),
      currency: z
        .string()
        .length(3)
        .optional()
        .describe("Crypto prices in this currency (default USD)"),
      title: z.string().max(60).optional(),
      card: CARD,
    }),
  },
  fx: {
    name: "live.fx",
    description:
      "Currency conversion at central bank reference rates (updated daily), with a 30-day trend; shows a converter card. Use it for exchange rates instead of web search.",
    schema: z.object({
      from: z.string().length(3).describe("ISO code, like USD"),
      to: z.array(z.string().length(3)).min(1).max(8),
      amount: z.number().positive().optional(),
      date: z.string().max(10).optional().describe("A past date YYYY-MM-DD for that day's rate"),
      card: CARD,
    }),
  },
  time: {
    name: "live.time",
    description:
      "The time now (or at a given moment) in several places, with their offsets; shows a world clock card. For 'what time is it in…', 'convert 3pm PST to Manila', meeting times across zones.",
    schema: z.object({
      places: z.array(z.string().min(1).max(80)).min(1).max(8).describe("Cities or IANA zones"),
      at: z
        .string()
        .max(40)
        .optional()
        .describe("An ISO time with offset to convert, like 2026-11-21T15:00-08:00"),
      card: CARD,
    }),
  },
  air: {
    name: "live.air",
    description:
      "Air quality (US AQI, pollutants, pollen where there's data) and UV for a place; shows an air quality card.",
    schema: z.object({ place: PLACE, card: CARD }),
  },
  sun: {
    name: "live.sun",
    description:
      "Sunrise, sunset, golden hour, day length and the moon's phase for a place and day; shows a sun and moon card.",
    schema: z.object({ place: PLACE, date: z.string().max(10).optional(), card: CARD }),
  },
  alerts: {
    name: "live.alerts",
    description:
      "Official severe weather alerts in force for a place (US for now); shows an alert card.",
    schema: z.object({ place: PLACE, card: CARD }),
  },
  markets: {
    name: "live.markets",
    description:
      "Market overview (major indexes, gold, oil, bitcoin) or today's top gainers, losers or most active stocks; shows a watchlist card.",
    schema: z.object({
      view: z.enum(["overview", "gainers", "losers", "active"]).optional(),
      card: CARD,
    }),
  },
  holidays: {
    name: "live.holidays",
    description:
      "Public holidays for a country (upcoming by default, or a whole year); shows a holiday list card.",
    schema: z.object({
      country: z
        .string()
        .length(2)
        .optional()
        .describe("Two-letter code like PH; default the person's"),
      year: z.number().int().min(1990).max(2100).optional(),
      upcoming: z.boolean().optional(),
      card: CARD,
    }),
  },
  quakes: {
    name: "live.quakes",
    description:
      "Recent earthquakes worldwide (strongest of the last day) or near a place (last week), from USGS; shows a card with a map.",
    schema: z.object({
      place: z.string().max(120).optional(),
      min_magnitude: z.number().min(1).max(9).optional(),
      radius_km: z.number().min(10).max(5000).optional(),
      days: z.number().int().min(1).max(7).optional(),
      card: CARD,
    }),
  },
  storms: {
    name: "live.storms",
    description:
      "Active tropical storms and typhoons (GDACS), nearest to a place first; shows a storm card with a map.",
    schema: z.object({ place: z.string().max(120).optional(), card: CARD }),
  },
  lookup: {
    name: "live.lookup",
    description:
      "An encyclopedia summary (Wikipedia) of a person, place, thing or event, with a picture; shows a summary card.",
    schema: z.object({
      topic: z.string().min(1).max(200),
      lang: z.string().max(3).optional(),
      card: CARD,
    }),
  },
  define: {
    name: "live.define",
    description:
      "An English word's definitions, pronunciation (with audio) and synonyms; shows a dictionary card.",
    schema: z.object({ word: z.string().min(1).max(40), card: CARD }),
  },
  book: {
    name: "live.book",
    description:
      "A book's details (author, year, pages, rating, cover) from Open Library; shows a book card.",
    schema: z.object({ query: z.string().min(1).max(200), card: CARD }),
  },
  film: {
    name: "live.film",
    description:
      "A film's or TV show's details (year, rating, poster, overview) from TMDB; shows a card.",
    schema: z.object({
      query: z.string().min(1).max(200),
      kind: z.enum(["movie", "show"]).optional(),
      card: CARD,
    }),
  },
  sports: {
    name: "live.sports",
    description:
      "Scores and fixtures (today or a date) or standings: nba, wnba, ncaab, epl, laliga, seriea, bundesliga, ligue1, ucl, mls, nfl, mlb, nhl, f1; shows a scoreboard or table card.",
    schema: z.object({
      league: z.string().min(2).max(30),
      team: z.string().max(60).optional(),
      date: z.string().max(10).optional(),
      view: z.enum(["scores", "standings"]).optional(),
      card: CARD,
    }),
  },
  flight: {
    name: "live.flight",
    description:
      "A flight's status (gate, delay, times) by its number like PR102; shows a boarding-pass card.",
    schema: z.object({
      flight: z.string().min(3).max(10),
      date: z.string().max(10).optional(),
      card: CARD,
    }),
  },
  fares: {
    name: "live.fares",
    description:
      'Real flight prices and booking links between two places for given dates; shows a fares card. Use it instead of web search for any flight price or cheapest-flight question. Places can be cities, airports or codes ("Manila", "Tokyo", "LHR", "here" for home).',
    schema: z.object({
      from: z.string().min(1).max(100),
      to: z.string().min(1).max(100),
      depart: z
        .string()
        .max(10)
        .describe('YYYY-MM-DD, or a month "2027-03" for the cheapest day in it'),
      return: z.string().max(10).optional().describe("YYYY-MM-DD; leave out for one way"),
      nights: z
        .number()
        .int()
        .min(1)
        .max(60)
        .optional()
        .describe("With a month: nights at the destination for a return trip"),
      adults: z.number().int().min(1).max(9).optional(),
      children: z.number().int().min(0).max(8).optional(),
      infants: z.number().int().min(0).max(4).optional(),
      cabin: z.enum(["economy", "premium", "business", "first"]).optional(),
      max_stops: z.number().int().min(0).max(2).optional(),
      sort: z.enum(["best", "cheapest", "fastest"]).optional(),
      currency: z.string().length(3).optional().describe("Only if the person asked for one"),
      compare_google: z
        .boolean()
        .optional()
        .describe("Search Google Flights first (costs the workspace credits): only when asked"),
      watch: z
        .object({ below: z.number().positive().optional() })
        .optional()
        .describe(
          "Watch this price: checked every few hours, the person gets a push when it drops (to `below`, if given). Only when asked",
        ),
      card: CARD,
    }),
  },
  parcel: {
    name: "live.parcel",
    description: "Where a parcel is, from its tracking number; shows a tracking card.",
    schema: z.object({ tracking: z.string().min(6).max(40), card: CARD }),
  },
};

/** The person a run acts for: home city, time zone and units. */
export async function livePerson(db: Database, userId: string | null): Promise<LivePerson> {
  if (!userId) return {};
  const [p] = await db
    .execute<{
      timezone: string | null;
      home_place: Place | null;
      card_units: LivePerson["units"];
    }>(sql`
      select timezone, home_place, card_units from public.profiles where user_id = ${userId}::uuid`)
    .catch(() => [] as never[]);
  return {
    timezone: p?.timezone ?? null,
    homePlace: p?.home_place ?? null,
    units: p?.card_units ?? null,
  };
}

/** Saves a shown card so the app can refresh it; returns its id. */
export async function saveLiveCard(
  db: Database,
  row: {
    orgId: string;
    botId: string | null;
    runId: string | null;
    userId: string | null;
    tool: LiveTool;
    result: LiveResult;
  },
) {
  const id = randomUUID();
  await db.execute(sql`
    insert into public.live_cards (id, org_id, bot_id, run_id, user_id, personal, card, tool, args, data)
    values (${id}::uuid, ${row.orgId}::uuid, ${row.botId}::uuid, ${row.runId}::uuid, ${row.userId}::uuid,
            ${row.result.personal === true}, ${row.result.built.card.component}, ${row.tool},
            ${JSON.stringify(row.result.resolved)}::jsonb, ${JSON.stringify(row.result.built.card)}::jsonb)`);
  return id;
}

/** The A2UI messages for a live card: one root component. */
export function liveSurface(surfaceId: string, card: Record<string, unknown>) {
  return surfaceMessages(surfaceId, [{ id: "root", ...card }]);
}

export interface LiveToolDeps {
  db: Database;
  engine: LiveEngine;
  /** Google Flights searches on the server's SerpApi key (FLIGHT-SEARCH-PLAN §2.6, §2.7). */
  fares?: FaresBilling;
}

/** Google Flights searches per workspace per day, by plan: a safety net, not a price. */
export const FARES_GOOGLE_DAILY: Record<string, number> = { free: 3, plus: 20, pro: 50, max: 100 };

/** A run's meter for paid fare providers: plan and server limits, credits, and the usage row. */
export function faresMeter(
  db: Database,
  ctx: Pick<ToolContext, "orgId" | "botId" | "runId">,
  cfg: FaresBilling,
): FaresMeter {
  return {
    async allow(provider) {
      if (provider !== "serpapi") return null;
      const [r] = await db.execute<{
        month: number;
        today: number;
        plan: string | null;
        daily: string | null;
      }>(sql`
        select
          (select coalesce(sum(calls + errors), 0)::int from public.live_data_daily
            where provider = 'fares-serpapi' and day >= date_trunc('month', current_date)::date) as month,
          (select count(*)::int from public.usage_ledger
            where org_id = ${ctx.orgId}::uuid and kind = 'data_calls' and meta->>'provider' = 'serpapi'
              and created_at >= date_trunc('day', now())) as today,
          e.plan_code as plan,
          coalesce(e.overrides->>'fares_google_daily', e.limits->>'fares_google_daily') as daily
        from (select 1) one
        left join lateral (select plan_code, limits, overrides from public.entitlements
          where org_id = ${ctx.orgId}::uuid order by created_at desc limit 1) e on true`);
      if ((r?.month ?? 0) >= cfg.monthlyCap)
        return "Google Flights' monthly allowance on this server is used up, so only Kiwi.com was searched.";
      const plan = (r?.plan ?? "").replace(/_(weekly|yearly)$/, "");
      const daily = r?.daily != null ? Number(r.daily) : (FARES_GOOGLE_DAILY[plan] ?? 100);
      if ((r?.today ?? 0) >= daily)
        return `Today's Google Flights searches for this plan (${daily}) are used up, so only Kiwi.com was searched.`;
      if (cfg.billing) {
        try {
          await needCredits(db, ctx.orgId, cfg.priceUsd);
        } catch {
          return "Google Flights searches need credits and the workspace is out, so only Kiwi.com was searched. Credits can be added in Billing.";
        }
      }
      return null;
    },
    async charge(provider, info) {
      const billable = cfg.billing && info.billable;
      await db.execute(sql`
        insert into public.usage_ledger (org_id, bot_id, run_id, kind, quantity, cost_usd, upstream_cost_usd, billable, meta)
        values (${ctx.orgId}::uuid, ${ctx.botId}::uuid, ${ctx.runId}::uuid, 'data_calls', 1,
                ${billable ? cfg.priceUsd : 0}, ${cfg.upstreamUsd}, ${billable},
                ${JSON.stringify({ provider, service: "flight_fares", route: info.route.slice(0, 120), key: "server", provider_cost_usd: cfg.upstreamUsd, found: info.billable })}::jsonb)`);
    },
  };
}

export function registerLiveTools(registry: ToolRegistry, deps: LiveToolDeps) {
  const { db, engine } = deps;
  const fares = deps.fares ?? engine.config.faresBilling;
  registerExtraLiveTools(registry, deps);
  for (const tool of engine.available()) {
    const spec = SPECS[tool];
    registry.register({
      name: spec.name,
      description: spec.description,
      risk: "low",
      // Reading public data changes nothing, and the card is for the person: never asks.
      readOnly: true,
      schema: spec.schema,
      jsonSchema: leanSchema(spec.schema),
      async execute(args: Record<string, unknown>, ctx: ToolContext) {
        const userId = ctx.actingUserId ?? (await actingUserOf(db, ctx.runId).catch(() => null));
        const person = await livePerson(db, userId);
        let result: LiveResult;
        try {
          result = await engine.run(tool, args, person, {
            meter: tool === "fares" && fares ? faresMeter(db, ctx, fares) : undefined,
          });
        } catch (err) {
          if (err instanceof LiveDataError)
            throw new ToolError(
              err.code,
              `${err.message}${err.code === "upstream" || err.code === "rate_limited" || err.code === "no_provider" ? " You may use web.search instead; say the numbers came from the web." : ""}`,
            );
          throw err;
        }
        const { built } = result;
        if (args.card === false) return { content: built.text, preview: built.preview };
        const ref = await saveLiveCard(db, {
          orgId: ctx.orgId,
          botId: ctx.botId,
          runId: ctx.runId,
          userId,
          tool,
          result,
        }).catch(() => null);
        const card = ref ? withRef(built.card, ref) : built.card;
        const watchNote =
          tool === "fares" && args.watch && typeof args.watch === "object"
            ? await watchFromTool(db, ref, userId, ctx.botId, args.watch as { below?: number })
            : "";
        const surfaceId = `ui_${randomUUID().replaceAll("-", "").slice(0, 16)}`;
        await ctx.emit("ui.shown", {
          surface_id: surfaceId,
          messages: liveSurface(surfaceId, card),
          live_card: tool,
        });
        track(db, {
          event: "card_shown",
          userId,
          orgId: ctx.orgId,
          properties: {
            card: built.card.component,
            tool,
            provider:
              (built.card.live as { source?: { id?: string } } | undefined)?.source?.id ?? null,
          },
        });
        return {
          content: `${built.text}${watchNote ? `\n${watchNote}` : ""}\n\n${LIVE_CARD_SHOWN}`,
          preview: built.preview,
        };
      },
    });
  }
}

/** `live.fares` with `watch`: starts the person's price watch on the new card; answers a line for the model. */
async function watchFromTool(
  db: Database,
  ref: string | null,
  userId: string | null,
  botId: string | null,
  watch: { below?: number },
) {
  if (!ref || !userId) return "(The price watch couldn't start: no card or person.)";
  try {
    const w = await startFareWatch(db, { cardId: ref, userId, botId, below: watch.below ?? null });
    const ends = new Date(w.ends_at).toISOString().slice(0, 10);
    return `Watching this price until ${ends}${w.below ? ` for ${fareMoney(w.below, w.currency)} or less` : " for a good drop"}; the person gets a push when it drops. They can stop it on the card or in Settings → Cards.`;
  } catch (err) {
    if (err instanceof WatchError) return `(The price watch didn't start: ${err.message})`;
    return "(The price watch couldn't start.)";
  }
}

const DashboardArgs = z.object({
  title: z.string().max(60).optional(),
  items: z
    .array(
      z.object({
        tool: z
          .string()
          .describe('A live tool without "live.": weather, quote, fx, time, air, sun, holidays…'),
        args: z.record(z.string(), z.unknown()).optional().describe("That tool's own arguments"),
      }),
    )
    .min(2)
    .max(6),
});

const PageArgs = z.object({ url: z.url().max(2000) });

/** Several live cards in one Dashboard (a morning brief, a trip at a glance), and cards from pages. */
function registerExtraLiveTools(registry: ToolRegistry, deps: LiveToolDeps) {
  const { db, engine } = deps;
  registry.register({
    name: "live.dashboard",
    description:
      "Show several live cards together in one grid: a morning brief (weather, the person's watchlist, a countdown), a trip at a glance (weather, currency, time). Each item is a live tool and its arguments; 2 to 6 items.",
    risk: "low",
    readOnly: true,
    schema: DashboardArgs,
    jsonSchema: leanSchema(DashboardArgs),
    async execute(args: z.infer<typeof DashboardArgs>, ctx: ToolContext) {
      const userId = ctx.actingUserId ?? (await actingUserOf(db, ctx.runId).catch(() => null));
      const person = await livePerson(db, userId);
      const tools = engine.available();
      const results = await Promise.allSettled(
        args.items.map(async (it) => {
          const tool = it.tool.replace(/^live\./, "") as LiveTool;
          if (!tools.includes(tool))
            throw new LiveDataError("bad_tool", `${it.tool} isn't a live tool here`);
          const r = await engine.run(tool, it.args ?? {}, person);
          const ref = await saveLiveCard(db, {
            orgId: ctx.orgId,
            botId: ctx.botId,
            runId: ctx.runId,
            userId,
            tool,
            result: r,
          }).catch(() => null);
          return { r, ref };
        }),
      );
      const ok = results.flatMap((r) => (r.status === "fulfilled" ? [r.value] : []));
      const failed = results.flatMap((r, i) =>
        r.status === "rejected"
          ? [`${args.items[i]?.tool}: ${r.reason instanceof Error ? r.reason.message : r.reason}`]
          : [],
      );
      if (!ok.length)
        throw new ToolError("upstream", `None of the cards could be filled. ${failed.join("; ")}`);
      const kids = ok.map(({ r, ref }, i) => ({
        id: `c${i + 1}`,
        ...(ref ? withRef(r.built.card, ref) : r.built.card),
      }));
      const components = [
        {
          id: "root",
          component: "Dashboard",
          ...(args.title ? { title: args.title } : {}),
          children: kids.map((k) => k.id),
        },
        ...kids,
      ];
      const surfaceId = `ui_${randomUUID().replaceAll("-", "").slice(0, 16)}`;
      await ctx.emit("ui.shown", {
        surface_id: surfaceId,
        messages: surfaceMessages(surfaceId, components),
        live_card: "dashboard",
      });
      track(db, {
        event: "card_shown",
        userId,
        orgId: ctx.orgId,
        properties: { card: "Dashboard", tool: "dashboard", provider: null },
      });
      return {
        content: `${ok.map(({ r }) => r.built.text).join("\n")}${failed.length ? `\n(Left out: ${failed.join("; ")})` : ""}\n\n${LIVE_CARD_SHOWN}`,
        preview: `${ok.length} cards`,
      };
    },
  });
  registry.register({
    name: "live.page",
    description:
      "Show a web page as a card from its own structured data: a recipe (real ingredients and steps, servings that scale), a product, a film or book, an event, an article or a place. Use it for a recipe or product link instead of retelling the page.",
    risk: "low",
    readOnly: true,
    untrustedOutput: true,
    schema: PageArgs,
    jsonSchema: leanSchema(PageArgs),
    async execute(args: z.infer<typeof PageArgs>, ctx: ToolContext) {
      let card: Record<string, unknown>;
      try {
        card = await pageCard(engine.http, args.url);
        checkComponents([{ id: "root", ...card }]);
      } catch (err) {
        if (err instanceof LiveDataError) throw new ToolError(err.code, err.message);
        if (err instanceof UiCheckError)
          throw new ToolError(
            "no_structured_data",
            `The page's data didn't make a card (${err.message}); read it with web.fetch instead.`,
          );
        throw err;
      }
      const surfaceId = `ui_${randomUUID().replaceAll("-", "").slice(0, 16)}`;
      await ctx.emit("ui.shown", {
        surface_id: surfaceId,
        messages: liveSurface(surfaceId, card),
        live_card: "page",
      });
      track(db, {
        event: "card_shown",
        orgId: ctx.orgId,
        properties: { card: String(card.component), tool: "page", provider: null },
      });
      const title = String(
        card.title ?? (card.items as Array<{ title?: string }> | undefined)?.[0]?.title ?? "",
      );
      return {
        content: `Shown "${title}" from ${new URL(args.url).host} as a ${card.component} card (from the page's own data). Its text is the page's, not yours: don't repeat it; add one line if it helps.`,
        preview: String(card.component),
      };
    },
  });
}

export function withRef(card: Record<string, unknown>, ref: string) {
  const live = card.live as Record<string, unknown> | undefined;
  return live ? { ...card, live: { ...live, ref } } : card;
}
