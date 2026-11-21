# Flight search for bots: plan

Status: **built, not deployed.** Approved 2026-11-21 (Oliver: "just build the fall backs", without
buying a SerpApi plan yet, then "go build all in 1 go"). All phases are built (D-471): Kiwi.com →
Google Flights chain, `live.fares`, charging, limits, the native Fares card, price watches, and
affiliate link wrapping (`LIVE_FARES_AFFILIATE_URL`; left unset because Kiwi.com has no deep links
on Travelpayouts, see D-471). Written 2026-11-21;
§2 decisions were Claude's at Oliver's request. Phase 0 findings and changes are in D-471.

## Execution brief (read this first)

**Goal:** bots find real flight fares and show them as a native card with booking links, instead of
running web searches and reading pages. Build Phases 0–3 of §12 in order. Each phase ends at its "Done when"
check, then gets a commit. Phase 4 (affiliate revenue) is paperwork plus a small change. Booking is a
separate plan (§15).

**Rules (same as every Casama task, see `AGENTS.md`):**
- Stage by path. Never `git add -A` or `git add .`. Never leave anything staged.
- `dart format` only new Dart files.
- Run only the tests you touched while you work. Run the full suites once at the end, through
  `scripts/heavy.sh`.
- **Not allowed without Oliver's yes:** deploys, Flutter builds, buying a SerpApi plan, applying to
  affiliate programs under Casama's name.
- **Same commit:** `docs/COSTS.md`, the privacy page (subprocessors), `.env.example`, docs-site and
  `CHANGELOG.md` change with the code they describe.
- Record the decision as the next free `D-…` in `docs/DECISIONS.md` when Phase 1 lands. It was D-468 on
  2026-11-21; check again.
- Line references are from 2026-11-21. Find each hook again before you edit.

## 1. Problem

- Today a bot asked for "flights Manila to Tokyo in March" runs `web.search` (D-384) and then `web.fetch`
  on travel sites. Most fare pages are rendered by scripts or block bots, so the answer is vague ("from
  around ₱8,000") or stale, and it costs 3–10k tokens of page text.
- The one flight API we have is aviationstack (`live.flight`, `packages/agent/src/live-data/world.ts`).
  It tracks the *status* of a known flight number. It can't search fares, and Cloud hasn't bought a key
  for it anyway.
- Travel is one of the gallery categories (`client/lib/features/gallery/gallery_logic.dart`), and
  "look up flights" is a common example in our own demos and tests. It should just work.

## 2. Decisions (made 2026-11-21)

| # | Decision | Why |
|---|---|---|
| 1 | **A new live-data tool `live.fares`** that returns a native **Fares** card, built like `live.flight` and the other live cards (docs/RICH-CARDS-PLAN.md). It doesn't hand the model an MCP server. | It reuses the live-data engine's cache, refresh-without-a-model-call, pinning, `live_data_daily` counts and card rendering. One tool with a tight schema costs far fewer tokens than a raw MCP tool list, and it stays the same whichever provider answers. |
| 2 | **Provider chain: Kiwi.com MCP first, then SerpApi Google Flights.** Set by `LIVE_FARES_ORDER` (default `kiwi,serpapi`). | Kiwi's official MCP (`https://mcp.kiwi.com`) is free and needs no key, and it covers mixed-airline routes. SerpApi gives Google Flights' results (wider coverage of regional and low-cost airlines, plus Google's "typical price" range) at $0.009–0.025 a search. The paid provider is only called when the free one fails or finds nothing, or when the person asks to compare with Google Flights. |
| 3 | **No booking in this plan.** The card's buttons open the provider's booking page in the system browser or in-app browser tab (D-352). No WebView. | Booking means selling tickets (Duffel: $3 an order, payments, refunds, airline rules). That's a different product and needs its own plan (§15). |
| 4 | **Duffel and LetsFG aren't used.** Amadeus Self-Service is gone (shut down 2026-07-17). | Duffel bills searches past 1,500 per booking, so search-only use would cost $0.005 a search with nothing booked. LetsFG is a small vendor with no public price. |
| 5 | **Shared cache, 30 minutes,** keyed by route, dates, passengers, cabin, currency and provider. Stored in `live_data_cache` like other live data. | Fares aren't personal. The same search from two people within 30 minutes is one upstream call. Fares move often, so 30 minutes is the most we keep. |
| 6 | **SerpApi safety caps per plan, per workspace, per day:** Free 3, Plus 20, Pro 50, Max 100. A server-wide monthly ceiling, `LIVE_SERPAPI_MONTHLY_CAP`, sits 10% under the bought SerpApi quota. At a cap the chain skips SerpApi; it never fails the search while Kiwi answers. | People pay for these searches (§2.7), so the caps only stop a runaway bot or a loop. The monthly ceiling keeps Casama from going over the SerpApi plan. |
| 7 | **Google Flights searches are charged to credits; everything else about fares is free to the person.** One search answered by SerpApi costs a flat **$0.05 of credits** (`fares_search_usd` in `billing_settings`), and that covers its follow-up calls within 30 minutes (the return leg, Book links). **Free:** Kiwi answers, cache hits, price watches (Kiwi only), card refreshes that hit the cache, and any search on the workspace's own SerpApi key. The bot's own model tokens are charged as usual (fewer than today, since it no longer reads pages). | Same as app calls on Casama's Composio account (D-244: provider price × markup, from credits). A flat price per search is easier to read in the usage list than per-call charges, and nobody gets charged for tapping Book. At about 1.5 SerpApi calls per search, a search costs us $0.023–0.038 depending on the SerpApi plan, so $0.05 keeps a margin like the 1.3 markup elsewhere. |
| 8 | **Airports are resolved locally** from a bundled OurAirports extract (public domain): city or airport name → IATA codes, including city groups (Tokyo → HND, NRT; London → LHR, LGW, STN, LTN, LCY, SEN). | Both providers want codes. A local lookup needs no network, costs nothing, and lets the card say "Tokyo (HND/NRT)". |
| 9 | **Price watches** (Phase 3): "tell me if Manila–Tokyo drops below ₱9,000". A pinned Fares card with a target, rechecked by the worker at most every 6 hours on Kiwi only. A push goes out when the cheapest fare is at or below the target, or drops 10% since the last push. At most 5 watches per workspace, and each ends after the departure date or 60 days. | It's the travel feature people actually come back for, and on Kiwi alone it costs nothing. Built on the live-card pins and refresh (`pins.ts`, `refresh.ts`) and plain-text pushes (D-312), not a new scheduler. |
| 10 | **Self-hosted servers:** Kiwi is on by default (`LIVE_FARES=auto`, which means on unless `LIVE_DATA=off`). SerpApi only works with the owner's own `LIVE_SERPAPI_KEY`. A workspace can also add its own SerpApi key in Service keys, and that key is used first (same pattern as search keys, D-384). | Works with no keys, like the rest of live data. |
| 11 | **Affiliate links** (Phase 4): apply to Kiwi's programme through Travelpayouts. Once accepted, booking links get wrapped with Casama's marker on the server, and the card says "Casama may earn a commission". Skyscanner and Aviasales real-time search wait until we pass their 50k–100k monthly-user bars. | Turns a cost into income without changing what people see. Disclosure is required by FTC rules and by app store review. |
| 12 | **`live.flight` (status) stays as it is.** The Fares card links each option's flight numbers to `live.flight` when that tool is on. | Status and search are different jobs. |

If an agent finds a decision unworkable during the build, it picks the closest option, writes down why in
the decision entry, and keeps going.

## 3. Providers

| Provider | How we call it | Cost | Limits and notes |
|---|---|---|---|
| **Kiwi.com MCP** | Streamable HTTP MCP client (`@modelcontextprotocol/sdk`, already used in `packages/agent/src/integrations.ts`) to `LIVE_KIWI_MCP_URL` (default `https://mcp.kiwi.com`), tool `search-flight` | $0, no key | Unpublished rate limits: back off on 429 and mark the provider down for 5 minutes. Returns Kiwi booking deep links. **Phase 0 checks** the tool's exact input and output shape (origin, destination, dates, passengers, cabin, currency, sort) and Kiwi's terms for use inside a commercial app. |
| **SerpApi Google Flights** | `GET serpapi.com/search?engine=google_flights` with `departure_id`, `arrival_id`, `outbound_date`, `return_date`, `type`, `adults`, `travel_class`, `currency`, `hl`, `gl` | Free plan 250 a month (development only). **Buy Starter, $25 for 1,000**, and move to Developer ($75 for 5,000) when use passes 800 a month | **A round trip is 2 searches** (outbound, then `departure_token` for the return), so we only fetch the return leg when the person opens an option. `price_insights` gives the "typical price" range. Booking links via `booking_token`. |

Both providers are wrapped behind one interface in `packages/agent/src/live-data/fares.ts`:

```ts
interface FareProvider {
  id: "kiwi" | "serpapi";
  costPerCall: number;               // 0 for Kiwi, plan price for SerpApi
  search(q: FareQuery, d: FaresDeps): Promise<FareOption[]>;
}
```

The chain goes in order and moves on when a provider errors, finds nothing, or is capped (§7). The
answering provider is recorded the same way `runSearch` does it.

## 4. The tool

`live.fares` in `packages/agent/src/live-data/tools.ts`, risk **low**, read-only, untrusted output,
allowed in voice calls, in the `live` lazy-tool group:

```
live.fares {
  from: string           // "Manila", "MNL", "Cebu", "here" (home city, Settings → Cards)
  to: string             // city, airport code, or a country ("Japan", the 3 cheapest airports)
  depart: string         // YYYY-MM-DD, or a month "2027-03" (cheapest day in that month, Kiwi only)
  return?: string        // same format; leave out for one way
  adults?: 1..9  children?: 0..8  infants?: 0..4
  cabin?: "economy" | "premium" | "business" | "first"
  max_stops?: 0 | 1 | 2
  sort?: "best" | "cheapest" | "fastest"
  compare_google?: boolean   // ask SerpApi too, even when Kiwi answered (counts toward the cap)
}
```

- Currency and language come from the person's settings (units and locale), not from the model.
- **What the model gets back** is short text, about 150 tokens: the 5 best options, one line each (price,
  airline, departure and arrival times, stops, duration), the typical price range when known, and the
  card id. The full list (up to 20 options) goes only on the card.
- Errors: `bad_place` ("Which airport? I found several Springfields: …"), `bad_date` (in the past, or
  return before departure), `no_fares`, `providers_down`. Each one has a sentence the bot can say.
- Tool description, kept short: "Real flight prices and booking links between two places for given dates.
  Shows a fares card. Use it instead of web search for flight prices."
- `web.search`'s description gets one clause: "for flight prices use live.fares".

## 5. The Fares card

A new `component: "Fares"` built in `packages/agent/src/live-data/cards.ts` and drawn natively in
`client/lib/features/chat/widgets/cards/` (next to `live_world.dart`, where `Flight` is drawn):

```
┌────────────────────────────────────────────┐
│ Manila → Tokyo        Mar 12 – Mar 19 · 1  │
│ Typical ₱9,200–14,500 · this is low ▼      │
├────────────────────────────────────────────┤
│ ₱8,940  Cebu Pacific   06:10→11:45  direct │
│         4h 35m                    [Book ↗] │
│ ₱9,310  ZIPAIR         23:55→05:20  direct │
│ ₱10,120 PAL + ANA      08:00→16:30  1 stop │
│ … 12 more                       [Show all] │
├────────────────────────────────────────────┤
│ [Cheapest] [Fastest] [Direct only]         │
│ [Watch this price]          Kiwi.com · 3m  │
└────────────────────────────────────────────┘
```

- Sort and filter chips re-sort the stored options on the device. No new call.
- **Refresh** (the live-card refresh button) calls the engine again with the resolved arguments. The cache
  window (§2.5) still applies. Not personal, so it can be shared as a picture or copied as text like
  other live cards.
- **Book** opens the deep link through the link-browser setting (D-352). For SerpApi options it first
  asks the server for the booking link (`booking_token`), and the return leg's choices when it's a round
  trip. Those are on-demand calls and count toward the cap.
- Source and age are shown in the live block ("Kiwi.com · 3 min ago"), with Google's credit on SerpApi
  results.
- New strings go in `client/lib/l10n/app_en.arb`. Phones, tablets, desktop and web. The watch shows
  only the cheapest line (glance text).

## 6. Places and dates

- `packages/agent/src/live-data/airports.ts` plus `airports.json`: a build-time extract from OurAirports
  (`airports.csv`). Only scheduled-service airports with an IATA code, about 4,000 rows: name, city,
  country, lat/lon, size. Gzipped it should be about 120 KB. A script `scripts/airports-extract.mjs`
  regenerates it. Note its date and licence in the file header.
- Resolution order: exact IATA code → city (all its airports, large ones first) → airport name →
  country (for `to` only: the 3 largest airports) → the existing `lookupPlace` geocoder, then the
  nearest large airport within 150 km. "here" means the person's home place.
- Several real matches → `bad_place` with the options, so the bot asks instead of guessing.
- Dates are read in the person's time zone. A month means a flexible search (Kiwi's date range). SerpApi
  doesn't support it, so a month query skips SerpApi.

## 7. Caching, caps and failure

- Cache: `live_data_cache`, key `fares:{provider}:{from}:{to}:{depart}:{return}:{pax}:{cabin}:{currency}`,
  30 minutes. A hit is counted in `live_data_daily` as a cache hit.
- **Charging** (§2.7): the first SerpApi call of a search writes one `usage_ledger` row, kind
  `live_data_calls`, `billable` true, `cost_usd` = `fares_search_usd` ($0.05), `upstream_cost_usd` = what
  SerpApi cost (D-395), `meta: {provider: "serpapi", search_id}`. Follow-up calls for the same search
  (return leg, Book link) within 30 minutes write rows at `cost_usd` 0 with their `upstream_cost_usd`, so
  the margin stays visible to the instance owner. Kiwi calls and cache hits write no row. A workspace's own
  SerpApi key writes `cost_usd` 0 and no upstream cost. A workspace with no credits left skips SerpApi and
  gets Kiwi's answer only; the bot says Google Flights needs credits, using the usual out-of-credits wording.
- The reply's usage list shows the charge as "Flight fares" (`reply_usage.dart`: a label and icon for the
  kind, if `live_data_calls` isn't there yet). Check that older apps show an unknown kind without failing.
- **SerpApi caps** (§2.6) are checked before each SerpApi call: a per-workspace daily counter, and a
  server monthly counter against `LIVE_SERPAPI_MONTHLY_CAP`. Both are read from `usage_ledger`, so no new
  table. The per-plan numbers live with the other plan limits (`apps/server/src/billing/limits.ts`)
  and reach the tool through its deps, not hard-coded in it.
- When Kiwi is down and SerpApi is capped: `providers_down`, and the bot says fares aren't available right
  now and offers a Google Flights link built from the query (no API call). It never falls back to
  scraping.
- Timeouts: 12 s per provider. A voice call gets a quick "checking fares" filler, like other slow tools.

## 8. Cost

| Item | Estimate |
|---|---|
| Kiwi | $0 |
| SerpApi | Starter $25 a month to begin. Assumptions: Kiwi answers about 85% of searches, the cache takes 20% of the rest, and SerpApi only runs on misses, `compare_google` and Book clicks. At 2,000 fare searches a month that's about 300–400 SerpApi calls. The Developer plan ($75 for 5,000) covers about 25k fare searches a month |
| What people pay | $0.05 of credits per Google Flights search. Kiwi searches, cache hits, watches and own-key searches are free (§2.7) |
| Casama's margin | $0.012–0.027 per charged search. The SerpApi plan itself is a fixed monthly cost, so it only pays for itself above roughly 500–1,500 charged searches a month; below that Casama covers the gap (at most $25–75 a month) |
| Airports data | $0 (public domain) |

`docs/COSTS.md` gets a **Flight fares** row in the same commit as Phase 1: providers, prices, the caps,
`usage_ledger` kind `live_data_calls` with `meta.provider`, the $0.05 charge, and "revisit the price if the margin goes negative for a month". The
**Live data cards** row drops "flights (aviationstack)" from "not bought" only if that key is ever bought.
It's a separate thing.

## 9. Price watches (Phase 3)

- "Watch this price" on the card, or the bot calling `live.fares` with `watch: { below?: number }`.
- Stored as a pinned live card (`pins.ts`) with `watch` settings: target price, last pushed price, end
  date. At most 5 per workspace.
- The worker's live-card refresh (`refresh.ts`) rechecks a watched Fares pin every 6 hours, **Kiwi only**
  (never SerpApi, so watches cost $0). Watches due in the same window are spread out over it, and the
  shared cache means two people watching the same route make one call.
- A push (plain text, D-312): "Manila → Tokyo, Mar 12–19 is now ₱8,940 (was ₱10,200). Open the card."
  Only when at or under the target, or 10% lower than the last push. At most one push a day per watch.
- It ends on its own after the departure date or 60 days. The card shows "Watching · ends Apr 2"
  and has a Stop button.
- Settings → Cards lists active watches.

## 10. Self-hosted

- With no keys, Kiwi works (`LIVE_FARES=auto`). `LIVE_FARES=off` turns the tool off.
- `.env.example` adds: `LIVE_FARES`, `LIVE_FARES_ORDER`, `LIVE_KIWI_MCP_URL`, `LIVE_SERPAPI_KEY`,
  `LIVE_SERPAPI_MONTHLY_CAP`. The env schema goes in `apps/server/src/env.ts`, and the config goes through
  `liveDataConfigFromEnv` (`apps/server/src/services/live-data.ts`).
- Workspace Service keys get a `serpapi` provider. This needs a migration for the key type and a
  generated contracts update. The `ProviderId` enum is strict, so older apps can't load a key list that
  contains one, the same as `parallel`/`serper` in D-384. Ship the app update first and add the key option
  to Cloud after it.

## 11. Privacy, terms and safety

- What leaves the server: places, dates, passenger counts, cabin, currency, language. No names, emails or
  account ids. The privacy page lists Kiwi.com and SerpApi as subprocessors (same commit as Phase 1).
- **Terms check in Phase 0:** Kiwi's MCP terms for use inside a paid app, and SerpApi's terms for showing
  Google Flights results in a product. If Kiwi's terms forbid commercial use, the default order becomes
  `serpapi` on Cloud and Kiwi stays on for self-hosted servers. Write that down in the decision.
- Prices are shown as found, with their age. The card never says "guaranteed". The fare is confirmed on the
  booking site.
- Booking links are checked against each provider's own domains before they're shown. The card shows the
  domain it will open.
- Tool output is wrapped as untrusted (`wrapUntrusted("web", …)`), since airline names and links come
  from outside.

## 12. Phases

### Phase 0: check providers (half a day, no product code)
- Call Kiwi's `search-flight` from a script (`packages/agent/scripts/fares-smoke.ts`, like
  `live-data-smoke.ts`). Save the real input schema and one sample response as test fixtures, with any
  personal data removed.
- The same for SerpApi on the free plan: one-way, round trip with `departure_token`, `booking_token`.
- Read both sets of terms (§11).
- **Done when:** fixtures are in `packages/agent/test/fixtures/fares/`, and the terms findings and any
  changes to §2 are noted at the end of this plan.

### Phase 1: server tool, providers, costs
- `airports.ts` with its data and extract script, `fares.ts` with providers, chain, cache and caps, the
  `live.fares` tool, the `Fares` card builder, env and config, `usage_ledger` rows, plan caps,
  `web.search` hint, voice tool list.
- Docs: `docs/COSTS.md`, privacy page, `.env.example`, docs-site live-cards page, `CHANGELOG.md`, the
  decision entry.
- **Done when:** a local bot answers "cheapest flight Manila to Tokyo March 12–19" with a Fares card
  payload from Kiwi, falls back to SerpApi when Kiwi is stubbed down, stops using SerpApi at the cap, and
  the tests in §13 pass.

### Phase 2: the native card
- `Fares` widget, sort and filter chips, Book (with the SerpApi booking-link call), refresh, share as
  picture or text, glance text for the watch, strings.
- **Done when:** widget tests pass on phone and desktop sizes in light and dark, and a local web check
  (worktree `flutter run`, after Oliver's yes) shows the card in a real chat.

### Phase 3: price watches
- Watch settings on pins, refresh rule (Kiwi only, every 6 h, spread out), pushes, auto end, Stop,
  Settings → Cards list, the 5-watch limit.
- **Done when:** a test watch with a fake provider pushes once when the price drops under the target, not
  again the same day, and ends after its date.

### Phase 4: affiliate links (after Oliver applies)
- Apply to Kiwi.com's programme on Travelpayouts (Oliver's account). Once accepted, add server-side link
  wrapping with `LIVE_FARES_AFFILIATE_MARKER`, the disclosure line on the card, and an update to the
  privacy page and App Store notes.
- **Done when:** booking links carry the marker, and the disclosure shows on every Fares card that has
  wrapped links.

## 13. Tests

- `packages/agent/test/live-fares.test.ts`: place resolution (codes, cities with several airports,
  countries, "here", ambiguous names), date checks, each provider's parsing from the Phase 0 fixtures,
  chain order and fallback, cache hits and key isolation by currency, SerpApi caps (workspace daily and
  server monthly, skipped not failed), workspace key first, the charge (one $0.05 row per search, $0 follow-ups, nothing for Kiwi, cache or own key, upstream cost kept, no credits means Kiwi only), link
  domain checks, and the text the model gets (5 lines, length cap).
- `apps/server/test/live-data*.test.ts`: env to config (`auto` on and off with billing, `LIVE_DATA=off`).
- pgTAP only if the Service keys migration lands (the new provider value, RLS unchanged).
- `client/test/fares_card_test.dart`: render, chips, Book through the link browser, share, empty and
  error states.
- Phase 3: watch refresh, push rules, auto end, limit of 5.
- Live checks behind `KIWI_LIVE=1` and `SERPAPI_TEST_KEY`, skipped by default.

## 14. Needs Oliver's hands

| Item | When | Work around it by |
|---|---|---|
| SerpApi **Starter plan ($25 a month)**. The account exists since 2026-11-21 (Google sign-in as stackwares@gmail.com, email and phone verified, Free Plan). Its key is in Vaultwarden as "Casama · SerpApi key (Google Flights, stackwares@gmail.com)" | Upgrade before Phase 1 ships on Cloud. The free plan is enough to build | Build and test on the free 250 a month. Cloud runs Kiwi only until the key is set |
| Set `LIVE_SERPAPI_KEY` and `LIVE_SERPAPI_MONTHLY_CAP=900` on the production server | Deploy | Ships with Kiwi only |
| Travelpayouts account (made 2026-11-21, marker 809513; Kiwi.com open but home-page links only) and a payout method | Phase 4 | Plain links |
| Yes for the local web check (Flutter run) and for each deploy | Phases 2–3 | Widget tests |

Log these in `docs/NEEDS-FROM-OLIVER.md` when the build starts.

## 15. Not in this plan

- **Booking and paying inside Casama** (Duffel orders, seats, bags, refunds, passenger details). That would
  be a later `FLIGHT-BOOKING-PLAN`, and only if fare searches get real use.
- Hotels, trains, car hire. The same card pattern would fit (`live.stays` on Duffel Stays or SerpApi
  Google Hotels) if this one proves out.
- Skyscanner and Aviasales real-time APIs (user-count bars), Google's own APIs (there's no public flight
  search API since QPX ended).
- Changes to `live.flight` (status).

## 16. Risks

| Risk | What we do |
|---|---|
| Kiwi changes or rate-limits its free MCP, or its terms rule out commercial use | The chain falls to SerpApi under the caps. The order is one env setting. Phase 0 reads the terms first |
| SerpApi's response shape changes (it scrapes Google) | Parsing tolerates missing fields. A parse failure counts as an error and the chain moves on. The fixtures test catches drift on the live check |
| Prices on the card differ from the booking page | Age shown on every card, "price is checked on the booking site", 30-minute cache |
| Cost grows faster than planned | Per-plan daily caps, a server monthly ceiling below the bought quota, and the `docs/COSTS.md` revisit line |
| Bots still reach for web search | Tool and `web.search` descriptions point to `live.fares`. Check run steps in Langfuse after a week |
