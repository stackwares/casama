# Live data cards (weather, markets, money, time, travel and more): plan

Status: **not started** (written 2026-11-20). Waiting for Oliver's answers to §16 and his go-ahead.
No code yet. When the first phase lands, record the decision in `docs/DECISIONS.md` (check the
highest number first; it was D-452 on 2026-11-20).

Asked for by Oliver on 2026-11-20, with two screenshots: "weather in Manila tomorrow, one line" got
a paragraph about cached Yandex mirror pages with conflicting data, and "weather in San Francisco
tomorrow" got a paragraph built from Open-Meteo and WeatherBug. His words: "I am sure we can leverage
a2ui to make beautiful cards for weather, stock prices, crypto prices, currency stuffs, and even
more… The most extensive list. And they should all look beautiful." Then: "Write the most extensive
full plan we need."

## Execution brief (for the agent that builds it, once approved)

**Goal:** build the phases in §14 in order. Each phase ends at its "Done when" check, then gets a
commit. Push only when Oliver asks or a deploy needs it.

**Rules (same as every Casama task, see `AGENTS.md`):**
- Stage by path; never `git add -A`, `git add .` or `git commit -a`. Other sessions share this tree.
- `dart format` only new Dart files. Edit existing client files by hand.
- New Dart files import `package:material_ui/material_ui.dart`, not `package:flutter/material.dart`.
- Ask before any Flutter build and any production deploy. Targeted `flutter test test/<file>` and
  `flutter analyze` need no permission; full suites go through `scripts/heavy.sh`.
- New tables get RLS, `public.allow_worker` and a pgTAP test. Apply migrations with
  `supabase migration up --include-all`. Never reset the local database.
- Every paid provider: `docs/COSTS.md` in the same commit, real cost in `usage_ledger`. Any new API
  key: search the vault first, save new ones in "Keys & Signing" in the same task.
- Privacy page, docs-site and store privacy answers change in the same commit as the code they
  describe (§10.6).
- Line numbers and file names here are from 2026-11-20. Re-find each hook before editing.

**Needs Oliver's hands** (log in `docs/NEEDS-FROM-OLIVER.md`; don't block on them):

| Item | Work around it by |
|---|---|
| Accounts and keys for paid providers he picks in §16 (stocks, flights, parcels, sports) | Build each provider behind its interface; a missing key hides that tool and its cards |
| A commercial Open-Meteo plan, if decision 3 picks it | MET Norway (free for commercial use) is the default for forecasts |
| Approving Flutter builds and devices for the widget and watch phases | Golden tests and type checks as with D-405 and D-452 |

## 0. Summary

Casama already draws native cards from A2UI (D-086): Map (D-310), Video and Audio (D-322), the
email draft (D-335), nine cards for mail, calendar, tasks, stats and results (D-337), and plugin
cards (D-345). What it lacks is **live data**: numbers that come from a real source, are stamped with
that source and its time, and can be refreshed without asking the model again.

This plan adds:

1. **Data tools** (`weather.get`, `markets.quote`, `fx.convert`, `time.compare` and so on) that call
   fixed, vetted providers from the server, cache the answers for everyone, and return compact
   structured results. They replace web search for these questions.
2. **Data cards**, filled by the server from a data tool's result, never by the model. The model
   gets a short summary and writes one line; the card carries the detail. This generalizes D-345's
   plugin-card path to Casama's own tools.
3. **Composed cards**, filled by the bot from what it knows or read (a recipe, a definition, a
   comparison), drawn with the same design and marked with where the content came from.
4. **Live refresh:** each data card keeps its query on the server. ↻, opening the chat, or a chart
   range switch calls the provider again (through the cache) with no model call and no tokens.
5. **Pin to widgets and watches:** a data card can become a home screen, Lock Screen, Mac or watch
   widget that the server keeps fresh, built on D-405 and D-452.
6. **One design system** for every card: the same anatomy, type, colors, motion and states, each
   card with its own character (weather follows the sky, prices follow their direction).
7. **A catalog of about 150 cards** in 16 groups (§6), built in waves: weather and money first.

Rough size: Phase 1 (foundation plus weather) is the big one; each later wave is mostly a provider,
a tool and a few card widgets on the shared kit.

## 1. What exists today

### 1.1 Cards in the app

- `client/lib/features/chat/widgets/bot_ui.dart` renders `ui` parts with `a2ui_flutter`.
- Casama's own components are built with `casamaCard(...)` in `bot_ui_kit.dart` (header with a
  status pill, a plain panel, the card's own buttons). Cards live in `bot_ui_cards.dart` (Event,
  Stats with fl_chart, Details, Schedule…), `bot_ui_lists.dart` (Agenda, MessageList, Checklist,
  Results, PersonPicker), `bot_ui_map.dart` (Map, flutter_map), `bot_ui_draft.dart`
  (MessageDraft), `bot_ui_previews.dart` (approval previews).
- Packages already in `client/pubspec.yaml` that this plan uses: `fl_chart`, `lottie`,
  `flutter_svg`, `flutter_map`, `intl`, `timezone`, `geolocator`, `home_widget`,
  `lucide_icons_flutter`. **No new Flutter dependency is needed for Waves 1 and 2.**
- Older apps skip components they don't know (the A2UI renderer drops unknown types), so the bot
  always writes a line of text too (D-310, D-337).

### 1.2 The catalog on the server

- The component list and its checks live in `packages/domain/src/a2ui.ts` (`UI_COMPONENTS`,
  `checkComponents`, `UiCheckError`), shared by `ui.show`, the plugin checker and the run (D-345).
- The model-facing reference is `packages/agent/src/tools/ui-catalog.ts` (`UI_REFERENCE`, read on
  demand through `ui.catalog`), so `ui.show`'s own description stays small (USAGE-PLAN step 4).
- **Tool-emitted cards already exist for plugins** (D-345, `run.ts`): after a successful tool call
  the run fills a card from the result, checks it, emits `ui.shown` with `plugin_card: <tool>`, and
  tells the model "Shown to the person as a card, so don't repeat it in full". The turn doesn't end.
  D-345's "Not done" list names the two things this plan adds: **cards for tools that aren't from a
  plugin**, and **live updates to a shown card**.

### 1.3 How bots get data today

- `web.search` (`packages/agent/src/tools/autonomy.ts`, `packages/agent/src/search.ts`): the
  workspace's key, else the server's chain (Casama Cloud: DeepSeek → Parallel → Serper → SearXNG,
  D-384, D-386), cached 6 hours per workspace, `search_queries` in `usage_ledger`, server-paid.
- `web.fetch` reads a page as text. `http.request` calls an API from the bot's computer.
- `data.search` / `data.call` (`packages/agent/src/data.ts`, D-138): paid data through Treg, always
  asks first, `data_calls` at cost + 20%.
- **Weather, prices and rates come from search snippets.** That's what the screenshots show: a
  cached Yandex mirror for Manila, two weather sites stitched together for San Francisco, and a
  paragraph explaining the doubt. It costs a search, two or three page reads and a few thousand
  tokens per question, and still isn't trustworthy.

### 1.4 Widgets and watches

- D-405: nine widgets on iPhone, iPad, Mac and Android, fed by the glance (`GET /v1/glance`),
  refresh pushes that carry nothing but "changed", widget keys.
- D-452: the **Canvas** widget a bot fills in (five templates: text, countdown, number, list,
  picture; looks; rotations), `widget.set`, a per-bot grant, `widget_canvases`. Its tool text
  already says a routine may "write on the day… the weather", which costs a model run each time.
- D-410: Apple Watch and Wear OS apps, complications, watch keys.

### 1.5 Gaps this plan closes

| Gap | Today | After |
|---|---|---|
| Trustworthy numbers | Search snippets, caveats | Named providers, stamped source and time |
| Cost per question | 1 search + 1–3 page reads + ~3–8k tokens | 1 cached provider call + ~300 tokens |
| Looks | A paragraph | A card made for the data |
| Freshness | Frozen in the reply | ↻ and auto-refresh with no model call |
| Glanceable | Open the chat | Pinned widget, watch complication |
| Geocoding | Not done (D-310 "Not done") | `places.lookup` shared by Map, Weather, Time |

## 2. Goals and non-goals

### Goals

1. Everyday questions about the world (weather, prices, rates, time, flights, parcels, scores,
   words, facts) are answered by a card and one line, with real data.
2. Every card looks designed, in light and dark, phone to desktop, with reduced motion respected.
3. Data cards never show a number the model typed. The server fills them.
4. Refresh costs no tokens. A popular query (Bitcoin's price, Manila's weather) costs one upstream
   call per cache window for everyone, not one per person.
5. Self-hosted servers get the free providers with no key and no setup.
6. A card can live on the home screen and the wrist.
7. Plugins can fill the same cards (D-345), so the catalog grows without app releases.

### Non-goals

- **Trading, payments or betting.** Market cards show prices and news; no buy, sell, order or odds
  buttons. Sports cards show scores; no betting lines.
- **Investment advice.** Cards show data with a "Not financial advice" line where it matters.
- **Real-time exchange feeds** that need exchange licenses. Quotes are labeled delayed when they are
  (§10.3).
- **WebViews or HTML.** Everything is native Flutter (and SwiftUI/RemoteViews on widgets).
- **A general-purpose dashboard builder.** The Dashboard card (§6.16) composes existing cards only.
- **Health data leaving the device.** Health cards (§6.9) read on-device data the app already has.

## 3. Principles

1. **Data from tools, words from the model.** A data card is filled by the server from a provider's
   answer. The model may pick which card and write the line above it; it never writes the numbers.
2. **Source and time on every card.** A footer: provider name (linked to its attribution), "Updated
   2 min ago", ↻. Delayed data says "Delayed 15 min". Composed cards say "From <site>" or "From
   the bot".
3. **One job per card.** One big fact, one picture (chart, gauge, icon or map), up to six detail
   rows, up to three buttons. Anything more is a second card or the Expanded view.
4. **Same anatomy, own character.** Shared kit (§5) for structure; each card gets one signature
   element (the sky gradient, the price sparkline, the day/night arc, the boarding-pass notch).
5. **Fast and calm.** First paint from the snapshot in the message; refresh in the background;
   numbers count to their new value; nothing flashes. Motion stops with reduced motion.
6. **Fail gracefully.** No provider, no key, a timeout: the tool says so, the bot falls back to
   `web.search`, and the reply says the data is from the web. A stale card says how stale.
7. **Cheap by design.** Shared cache by normalized query; refresh windows per kind (§4.4); paid
   providers only where free ones can't do it.
8. **Older apps still work.** Every data tool's result also has a one-line text form; the bot's line
   above the card is enough on an app that skips the card.
9. **Accessible.** Every card has a spoken summary ("Manila, 31 degrees, light rain, high 31, low
   27"), meets contrast on every background, scales with text size, and never uses color alone for
   up or down (arrow and sign too).
10. **Localized.** Units, numbers, currencies, dates and times follow the person's settings and
    locale (§4.6), not the provider's.

## 4. Architecture

### 4.1 Data tools and providers

New folder `packages/agent/src/live-data/`:

```text
live-data/
  provider.ts      LiveProvider interface, errors, attribution, cost
  cache.ts         shared cache (Postgres table + in-memory LRU), single-flight
  registry.ts      which provider answers which tool, by config and fallback order
  places.ts        geocoding (places.lookup) shared by every place-based tool
  weather/         met-norway.ts, open-meteo.ts, nws.ts (US alerts), astro.ts (sun and moon, local math)
  air/             open-meteo-air.ts, openaq.ts
  markets/         <stock provider>.ts, coingecko.ts, frankfurter.ts
  time/            zones.ts (IANA tz from the timezone package data), holidays.ts (Nager.Date)
  travel/          flights.ts, parcels.ts
  sports/          scores.ts
  reference/       wikipedia.ts, dictionary.ts, books.ts
  geo/             usgs-quakes.ts, gdacs.ts
```

**`LiveProvider`:**

```ts
interface LiveProvider<Q, R> {
  id: string;                       // "met_norway"
  name: string;                     // "MET Norway", shown in the card footer
  attribution: { text: string; url: string; license?: string };
  costUsd(q: Q): number;            // 0 for free providers
  ttlSeconds(q: Q, r?: R): number;  // honors Expires/Cache-Control when the provider sends one
  key(q: Q): string;                // normalized cache key (rounded coordinates, upper-case symbols)
  fetch(q: Q, signal: AbortSignal): Promise<R>;
}
```

- **Calls go out from the API/worker server** through the existing egress guard
  (`net-policy.ts`, `safe-fetch.ts` with `withTimeout`), to a fixed host list per provider. No URL
  from the model or the client ever reaches a provider.
- **Identifying User-Agent** (`Casama/<version> (+https://casama.ai; contact)`), required by MET
  Norway, Wikipedia and Nominatim-style services.
- **Keys** come from env (`LIVE_<PROVIDER>_KEY`) and the admin console (Services), same pattern as
  search providers. A workspace may add its own key for paid providers (Model keys page), as with
  search; then it pays its own.
- **Fallback order** per tool, like `SEARCH_PROVIDER_ORDER`: `LIVE_WEATHER_ORDER=met_norway,open_meteo`.
- **Timeouts:** 4 s per provider, 8 s per tool call overall.

**Cache** (`live_data_cache`, server-only table, plus a per-process LRU in front):

| Column | |
|---|---|
| `provider` | text |
| `key` | text (normalized query) |
| `payload` | jsonb (the provider's normalized answer, not the raw body) |
| `fetched_at`, `expires_at` | timestamptz |
| `etag` / `last_modified` | for conditional requests (MET Norway asks for them) |

- Public data only (a weather grid point, a ticker, a currency pair). **No person or workspace id in
  the key or the row.** Personal data (parcels with tracking numbers, flight bookings) is cached
  per workspace in a separate table with RLS (`live_data_private_cache`), or not cached at all.
- **Single-flight:** concurrent misses on the same key wait for one upstream call.
- **Serve stale on error:** if the provider fails and a row is younger than 6× its TTL, return it
  marked stale.
- Rows past expiry plus a day are deleted by an hourly worker job.

**Tools** (one lazy group, `live`, loaded with `tools.load`; also listed in the core index so the
model knows they exist). All `risk: "low"`, `readOnly: true`, `untrustedOutput: false` (structured,
from vetted hosts; strings inside are still escaped).

| Tool | Args | Card(s) it shows |
|---|---|---|
| `places.lookup` | `query`, `near?` | none (feeds others); Map when asked |
| `weather.get` | `place` or `{lat,lng}`, `when?: "now"\|"today"\|"tomorrow"\|date\|"week"`, `detail?: "hourly"\|"daily"\|"rain"` | Weather, Forecast, RainNow, SunMoon |
| `weather.air` | place, `include?: ["pollen"]` | AirQuality |
| `weather.alerts` | place | WeatherAlert |
| `markets.quote` | `symbols: [..]` (stocks, ETFs, indexes, crypto) | Quote, Watchlist |
| `markets.chart` | `symbol`, `range` | Quote (expanded) |
| `markets.movers` | `market?`, `kind: "gainers"\|"losers"\|"active"` | Movers |
| `markets.profile` | `symbol` | CompanyProfile |
| `fx.convert` | `amount?`, `from`, `to: [..]`, `date?` | Currency, CurrencyTable |
| `time.compare` | `places: [..]`, `at?` | WorldClock, MeetingPlanner |
| `time.until` | `target` (date, event, holiday) | Countdown |
| `calendar.holidays` | `country`, `year?` | Holidays |
| `flights.status` | `flight`, `date?` | Flight |
| `parcels.track` | `tracking`, `carrier?` | Parcel |
| `sports.scores` | `team?`, `league?`, `date?` | Score, Fixtures, Table |
| `quakes.recent` | `near?`, `min_magnitude?` | Quake |
| `storms.active` | `region?` | Storm |
| `facts.lookup` | `topic` (Wikipedia summary) | Summary |
| `words.define` | `word`, `lang?` | Definition |
| `books.lookup` | `query` | Book |

Each tool returns:

```json
{
  "text": "Manila tomorrow: 27–31°C, showers likely (80%), heaviest 3–6 pm.",
  "data": { "...normalized fields the model may use..." },
  "card": "Weather"
}
```

The model sees `text` and a trimmed `data` (no long arrays: hourly series become "peak 31° at
2 pm"), about 150–400 tokens. The app gets the full card.

### 4.2 From tool result to card

Generalize D-345's plugin-card path in `run.ts`:

- `ToolSpec` gains `card?: (result) => CardFill | null` for built-in tools (plugins keep their JSON
  files). It returns the component name, its fields and the `live` block (§4.3).
- After a successful call the run fills the card, checks it with `checkComponents`, emits
  `ui.shown` with `live_card: <id>` (instead of `plugin_card`), and stores it as a `ui` part like
  any card. **No Send/Skip is added** to data cards (they're display cards with their own buttons).
- The model gets: the text, the trimmed data, and "Shown to the person as a <Weather> card. Don't
  repeat its numbers; add one line only if it helps (what to wear, whether to go)." The turn
  continues, so the bot can show two cards ("Manila vs Tokyo") or add a Map.
- **Several calls, one reply:** a run that shows more than 4 data cards groups the rest into a
  carousel (the Dashboard card, §6.16) so the chat doesn't become a wall.
- **Voice calls** (Gemini Live): the tool returns `text` for speech; the card is posted to the chat
  after the call, inside the call card (D-429).
- **When the person asks for text only** ("one line", "no card"), the bot passes `card: false`; the
  tool returns text only. The person's preference is remembered per bot if they say so twice
  (memory, not a new setting).

### 4.3 Wire format

Data cards are A2UI components like any other (`{id, component: "Weather", ...fields}`), plus one
reserved field:

```json
{
  "id": "root",
  "component": "Weather",
  "place": { "name": "Manila", "region": "Metro Manila", "country": "PH", "lat": 14.6, "lng": 121.0, "tz": "Asia/Manila" },
  "when": "2026-11-21",
  "now": null,
  "day": { "high": 31, "low": 27, "feelsHigh": 36, "code": "showers", "precipChance": 80, "precipMm": 12, "windKph": 14, "gustKph": 21, "uv": 9, "sunrise": "05:58", "sunset": "17:24" },
  "hours": [ { "t": "2026-11-21T06:00+08:00", "temp": 27, "code": "showers", "chance": 70 } ],
  "units": { "temp": "C", "wind": "kph", "precip": "mm" },
  "live": {
    "ref": "lc_01JD…",
    "source": { "provider": "met_norway", "name": "MET Norway", "url": "https://api.met.no", "license": "CC BY 4.0" },
    "fetchedAt": "2026-11-20T14:02:11Z",
    "staleAfter": "2026-11-20T14:32:11Z",
    "delayed": null,
    "views": ["now", "today", "tomorrow", "week"]
  }
}
```

- Data is in **SI and ISO** on the wire (°C, km/h, mm, UTC times plus the place's tz). The app
  converts to the person's units (§4.6). Providers' own units never reach the app.
- `live.ref` points at a `live_cards` row (§4.4). Composed cards have no `ref`; they carry
  `provenance: {kind: "web"|"bot"|"plugin", name?, url?}` instead.
- Schemas for every card go in `packages/contracts` (JSON Schema, generated Dart and TS with
  `pnpm gen`), versioned per card (`"v": 1`). The app ignores fields it doesn't know and shows a
  card at a newer version with what it understands.
- `checkComponents` validates each card's fields (types, ranges, list limits). Data cards accept
  `live` only when the run filled them (a `ui.show` call with `live` is refused, so a bot can't fake
  a source).

### 4.4 Live cards: refresh without the model

**Table `live_cards`** (migration, RLS: members of the workspace who can read the chat):

| Column | |
|---|---|
| `id` | `lc_` ULID |
| `org_id`, `bot_id`, `chat_id`, `message_id` | where it was shown |
| `user_id` | who asked (for private sources) |
| `card` | component name |
| `tool`, `args` | the call to repeat (sealed like other text, D-136, when private: parcels, flights) |
| `data` | latest filled card (jsonb) |
| `fetched_at`, `stale_after` | |
| `pinned` | bool (§4.5) |
| `refreshes_today`, `refresh_day` | per-card limiter |

**Routes:**

- `POST /v1/live-cards/:id/refresh` → re-runs `tool(args)` through the cache, refills, returns the
  card. **The client sends nothing but the id.** Rate-limited: per card, at most once per its
  minimum window (§4.4 table); per person, 300 refreshes an hour.
- `POST /v1/live-cards/:id/view` `{view: "week"}` or `{range: "1Y"}` or `{amount: 250}` → only
  values listed in the card's `live.views` / allowed params. Returns a card; doesn't overwrite the
  stored one unless `save: true`.
- `GET /v1/live-cards?ids=…` → latest data for cards on screen (one call per chat open).

**When a card refreshes:**

| Kind | Auto-refresh when visible and older than | Cache TTL (shared) | Manual ↻ floor |
|---|---|---|---|
| Weather now / rain | 15 min | MET Norway's Expires (~30–60 min) | 1 min |
| Forecast, air, pollen | 60 min | 60 min | 5 min |
| Stock quote (market open) | 1 min | 60 s (delayed feeds: 5 min) | 15 s |
| Stock quote (market closed) | never | until next open | 5 min |
| Crypto | 1 min | 60 s | 15 s |
| FX (ECB/central-bank rates) | 6 h | until next publication | 10 min |
| Flight (within 24 h of departure) | 2 min | 2 min | 30 s |
| Parcel | 60 min | 30 min | 5 min |
| Live score | 30 s | 30 s | 10 s |
| Earthquakes, storms | 10 min | 5 min | 1 min |
| Reference (definition, summary) | never | 7 days | — |

- The app refreshes **only cards on screen** (visibility detector), only while the app is in the
  foreground, at most 4 cards at once, and stops after 30 minutes on the same chat without input.
- A refreshed card animates its numbers to the new value and updates its footer. If refresh fails,
  the footer says "Couldn't update · 14 min old" with ↻.
- **Old chats:** cards in messages older than 7 days don't auto-refresh; they show "Nov 20, 2:02 pm"
  and ↻. The message keeps its original snapshot; `live_cards.data` holds the latest.
- **Exports and shared chats** use the snapshot, with its time.

### 4.5 Pin to widgets and watches

A data card's overflow menu gets **Pin to Home Screen** (and **Add to Watch** where a watch is
paired). Two stages:

**Stage A (Wave 1, no native widget work): a Canvas fed by the server.**
- Pinning creates a D-452 canvas for the person, owned by the card's bot, with a new `source`:
  `{live_card: "lc_…"}`, using the existing templates: Weather → `number` (temperature, condition
  word, icon, sky gradient look), Quote → `number` (price, change), Countdown → `countdown`,
  Watchlist / WorldClock → `list`.
- A worker job refreshes pinned live cards at their kind's window (weather 30 min, quotes 15 min
  during market hours, FX 6 h), writes the canvas, and lets `GlancePusher.changed()` push. **No
  model run, no credits.**
- The D-452 grant still applies: the first pin shows the canvas preview card.
- Lock Screen forms (80 and 24 characters) come from the card's `text` and a short form per card
  ("31° Showers", "BTC $97,412 ▲2.1%").

**Stage B (later wave): native Live card widgets** for the top cards (Weather, Quote, Watchlist,
WorldClock, Countdown, Flight), drawn natively in SwiftUI (`client/ios/CasamaWidgets/LiveCard*.swift`)
and RemoteViews (`LiveCardWidget.kt`) with the card's own design, plus watch complications
(temperature, price) and a Wear tile. Decision 9.

**Limits:** 12 pinned live cards per person; quotes on widgets are always marked delayed.

### 4.6 Places, location and preferences

- **`places.lookup`** (geocoding): place name → `{name, region, country, lat, lng, tz}`. Provider
  order: Open-Meteo geocoding (GeoNames data) on self-hosted servers, MapTiler geocoding on Casama
  Cloud if `CASAMA_MAPTILER_KEY` exists server-side (decision 4), Photon as fallback. Cached 30 days.
  Map cards (D-310) use it too, closing D-310's "Not done: geocoding".
- **"Here" and "my weather":** in order, (1) a place the person named, (2) their **home place**, a new
  optional profile field (Settings → You → Home: a city, never a street), (3) the device's location,
  once, through D-376's permission card, rounded to 0.1° (~11 km) before it leaves the phone,
  (4) their timezone's main city, with a line "Using Asia/Manila; tell me your city for better
  results".
- **Units** (Settings → Language & region): temperature °C/°F, wind km/h, mph, m/s, knots, rain
  mm/in, distance km/mi, 12/24-hour clock, first day of week, **main currency** (for prices and the
  Currency card's default). Defaults from the device locale (en-US → °F, mph, in, USD; en-PH → °C,
  km/h, mm, PHP). Server stores them on the profile so widgets and watches match.
- Conversions happen in the app (`client/lib/core/units.dart`) and in the native widgets with the
  same tested rules.

### 4.7 Composed cards

Cards whose content comes from the bot's knowledge or a page it read: Recipe, Definition (when no
dictionary provider), Comparison, Steps, Quote of the day, Pros & cons, Timeline, Itinerary, etc.

- Offered through `ui.show` like D-337's cards, documented in `ui.catalog` (not in `ui.show`'s
  description, to keep every call small).
- They carry `provenance` and the footer says it ("From seriouseats.com", "From the bot, may be
  wrong").
- **Structured pages first:** `web.fetch` already strips pages; it gains a `structured` field with
  schema.org JSON-LD it finds (Recipe, Product, Event, Book, Movie, FAQ, HowTo). A tool
  `cards.fromPage {url}` fills a composed card directly from that JSON-LD, so a recipe card from a
  recipe site has the site's real ingredients, not the model's retelling.
- Composed cards never carry `live`.

### 4.8 Plugins and the gallery

- D-345 card files may target every new component. A plugin filling a Weather card shows the
  plugin's name as the source ("From Acme Weather plugin"); it can't claim another provider.
- A plugin can't add `live.ref` refresh in this plan (its tools run on the bot's computer or a
  remote MCP; repeating them without a run needs D-345's open question on secrets). Later: a
  plugin tool marked `readOnly` and `refreshable` could be repeated by the worker.
- The gallery gets a "Cards" section later showing each card with sample data (data from
  `packages/contracts/cards/samples/`), useful for plugin authors.

## 5. Design system

The goal Oliver set: **they should all look beautiful.** The kit makes that the default, so a new
card is mostly data mapping.

### 5.1 Anatomy

```text
┌─────────────────────────────────────────────┐
│ [icon] Title · subtitle            [pill] ⋯ │  Header: 1 line, icon in a 28 px tile
│                                             │
│  31°        Showers                         │  Hero: the one big fact + its words
│  Feels 36°  H 31° · L 27°                   │
│                                             │
│  ▁▂▃▅▆▇▆▅▃  (signature: chart, art, gauge)  │  Signature
│                                             │
│  Rain 80%   Wind 14 km/h   UV 9 very high   │  Facts: up to 6 chips or rows
│                                             │
│  [ Hourly ] [ 7 days ]                      │  Buttons / segmented views (≤ 3)
│ ─────────────────────────────────────────── │
│  MET Norway · Updated 2 min ago        ↻    │  Footer: source, freshness, refresh
└─────────────────────────────────────────────┘
```

Shared widgets in `client/lib/features/chat/widgets/cards/kit/` (new folder; existing
`bot_ui_kit.dart` keeps its role for D-337 cards and gets the shell):

| Widget | Use |
|---|---|
| `CardShell` | Surface, radius 24, padding 16/20, header, footer, overflow menu (Pin, Copy as text, Share image, Refresh, Report wrong data) |
| `HeroValue` | Big tabular number with unit, animated count, optional sign and arrow |
| `ChangePill` | ▲ 2.14% / ▼ 0.8%, color by direction and by `good` (D-337's rule), never color alone |
| `Sparkline` | fl_chart line without axes, gradient fill, last-point dot, optional baseline (previous close) |
| `RangeChart` | Interactive line with scrub (haptic ticks), range chips 1D 1W 1M 3M 1Y 5Y |
| `RangeBar` | Low–high bar with a marker (day temp range, 52-week range) |
| `Gauge` | Semi-circle with bands (AQI, UV, fear & greed, server load) |
| `Ring` | Activity, progress, battery |
| `Arc` | Sun/moon path, day/night arc on clocks |
| `Strip` | Horizontal scroll of small cells (hourly, days, fixtures) with snap |
| `Stepper` | Stages with times (parcel, flight, order) |
| `Timeline` | Vertical events (play-by-play, itinerary, on-this-day) |
| `FactChips` / `FactRows` | Label–value pairs, icons from Lucide |
| `SkyBackground` | Weather gradients by condition × day/night × season, subtle animated layer |
| `Crest` / `Logo` | Circular or rounded logo with letter fallback (§5.6) |
| `Flag` | Country flags (bundled SVG set, §5.6) |
| `SourceFooter` | Provider, link, freshness ("Updated 2 min ago", "Delayed 15 min", "Stale: 3 h"), ↻ |
| `CardSkeleton` | Shimmer in the card's own shape while a view loads |
| `CardError` | Inline problem + retry; the card never collapses to nothing |

### 5.2 Sizes

- **Compact** (in a carousel, dashboard or reply with several cards): header + hero + one line.
- **Regular** (default in the chat): everything above, width capped at 440 px.
- **Expanded** (tap the card or "More"): full-screen sheet with the big chart, all rows, every view;
  on desktop a side panel. Same data; no extra provider call unless a view needs one.
- Widgets (§4.5) and watch: their own small forms per card.

### 5.3 Type and numbers

- Numbers use **tabular figures** (`FontFeature.tabularFigures()`) so prices don't jiggle on update.
- Hero numbers in the heading font at 44–56 px, weight 600; units at 45% size, raised.
- Text font for everything else. Respects the person's chosen fonts (D-087) and text scale up to
  200% (layout switches to stacked rows past 130%).
- Formatting with `intl`: currency symbols and decimals per currency (JPY 0, BTC up to 8 shown as
  needed, small coins with significant digits), compact numbers (1.2T market cap), percentages with
  sign, locale grouping.

### 5.4 Color

- Cards sit on the app's glass panels (D-087) and use the theme's scheme for chrome.
- **Semantic colors** (from the scheme, tuned for contrast in light and dark): up/good, down/bad,
  neutral, warning, danger, info. Finance colors can be flipped (Settings: "Red means up", for East
  Asian markets; default by locale: zh, ja, ko → red up).
- **Signature palettes:**
  - Weather: `SkyBackground` gradients for 14 condition groups × day/dusk/night (clear, mostly clear,
    partly cloudy, cloudy, fog, drizzle, rain, heavy rain, thunder, snow, sleet, hail, wind, smoke/haze),
    with the text color picked for contrast like D-452's `inkFor`.
  - Air quality and UV: the standard bands (AQI green→maroon, UV green→violet).
  - Crypto and stocks: neutral card, direction only in the pill and the line.
  - Sports: team colors as a thin top accent only (never as text background).
  - Flights: airline color accent; boarding-pass layout.
- Everything checked against WCAG AA (4.5:1 for text) in golden tests on every background.

### 5.5 Motion

- Numbers count to new values (300 ms, ease-out). Sparklines draw left to right on first show
  (500 ms). Weather art loops gently (rain, clouds drifting, sun rays) at low frame rates.
- Live score goal, price crossing an alert, parcel delivered: one short highlight pulse, no
  confetti in the chat (confetti only on the Expanded "Delivered" state, once).
- Reduced motion (system setting or app setting): no loops, no counting, instant changes.
- Animations pause when the card is off screen (visibility) and in a hidden tab.

### 5.6 Art and assets

| Asset | Source | License | Notes |
|---|---|---|---|
| Weather icons (static + animated) | Meteocons by Bas Milius, SVG and Lottie | MIT (check at Phase 0) | Bundled, ~60 icons, day/night variants; or commissioned set (decision 6) |
| Sky backgrounds | Drawn in code (gradients + painter layers) | ours | No images to download |
| Flags | `flag-icons` SVG set | MIT (check) | Bundled, ~250 small SVGs |
| Crypto logos | CoinGecko's image URLs | Per CoinGecko terms (check) | Cached on our server's object store; letter fallback |
| Company logos | The stock provider's logo endpoint if licensed, else letter tile | Varies | Never scrape logos |
| Airline logos | None at first | — | Airline code in a colored tile; licensed set later |
| Team crests | Provider's images if its license allows display | Varies | Else initials in team color |
| Condition words | Our own wording per code, translated | ours | "Showers", never provider text |

Bundled assets add roughly 1.5–2.5 MB to the app; measure in Phase 1.

### 5.7 States every card has

Loading (skeleton), fresh, refreshing (subtle spinner on ↻), stale (footer amber), error (inline,
retry), empty ("No flights found for PR 102 today"), partial (some rows missing, shown as "—"),
offline (snapshot, "Offline · from 2:02 pm"), older app (the bot's line), dimmed history (like D-337
cards after an answer: data cards don't dim; they're not questions).

### 5.8 Interactions

- Tap card → Expanded. Long-press → overflow menu (also the ⋯).
- Scrub charts with a finger; value and date follow; haptic tick per point.
- Segmented views (Now / Hourly / 7 days; 1D 1W 1M 1Y) call `/view`.
- Currency card: edit the amount and swap locally from the rate (no call); changing a currency calls
  `/view`.
- Buttons that need the bot ("Plan my day around the rain", "Set a price alert") send a message like
  any card button (D-086), never call tools directly.
- **Share image:** renders the card to a PNG (RepaintBoundary) with a small Casama mark; uses the
  share sheet.
- **Copy as text:** the card's `text` plus source and time.
- **Report wrong data:** one tap stores a report (card id, provider, data snapshot; new small table
  `live_card_reports`, no free text) and fires `card_reported`. Helps pick providers.

### 5.9 Mockups

Phase 0 makes `docs/media/cards-mockups.html` (like `widgets-mockups.html`) for Wave 1 in light and
dark, compact/regular/expanded, plus generated concept images for the signature looks (weather skies,
quote card) made by an image subagent on `codex/gpt-6-luna` (AGENTS.md's image model). Oliver picks
a direction before Phase 1's widgets are built.

## 6. The card catalog

**D** = data card (server-filled, live), **C** = composed card (bot- or page-filled), **L** = local
(computed in the app or server with no provider: time, math, astronomy). **Wave** is the build
order in §14 (1 first; "—" means later or optional). Providers are in §8.

### 6.1 Weather and sky

| Card | Kind | Shows | Interactions | Wave |
|---|---|---|---|---|
| **Weather** | D | Place, now or a day: temp, condition art on `SkyBackground`, feels-like, high/low, rain chance, wind, UV, humidity; hourly strip | Now/Hourly/7 days, Expanded, Pin | 1 |
| **Forecast** | D | 7–10 days: icon, rain %, `RangeBar` for each day's low–high on a shared scale | Tap a day → that day's Weather | 1 |
| **RainNow** | D | Next 2 hours of rain intensity (where nowcast exists) or next 12 hours; "Rain starts ~3:20 pm" | — | 1 |
| **WeatherAlert** | D | Severity banner, event, area, from–until, what to do, issuer | Open issuer page | 1 |
| **SunMoon** | L | Sun arc with now marker, sunrise/sunset, golden and blue hours, day length change; moon phase, rise/set, illumination | Date picker | 1 |
| **AirQuality** | D | AQI `Gauge` with band and advice, main pollutant, PM2.5/PM10/O₃/NO₂ chips, 24 h trend | Pollen tab | 2 |
| **Pollen** | D | Tree/grass/weed levels by day (Europe from CAMS; elsewhere where available) | — | 2 |
| **UV** | D | UV now, peak time, burn time by skin type, sunscreen hint | — | 2 |
| **Typhoon / Storm** | D | Track on a Map, category, wind, cone, nearest landfall, signal number for PH | Expanded map | 2 |
| **Earthquake** | D | Magnitude, depth, distance from the person, time ago, felt map, tsunami note | Map | 2 |
| **Tides** | D | Tide curve for today, next high/low | — | — |
| **Surf / Marine** | D | Wave height, period, swell direction, wind, water temp | — | — |
| **Ski** | D | Snow depth, new snow, lifts open (where data exists) | — | — |
| **Stargazing** | L+D | Cloud cover tonight, moon, visible planets, ISS passes | — | — |
| **Climate normals** | D | "Is this unusual?": today vs 30-year average for the date | — | — |
| **What to wear** | C | Bot's outfit/umbrella advice drawn on top of Weather data | — | 2 |

### 6.2 Money and markets

| Card | Kind | Shows | Interactions | Wave |
|---|---|---|---|---|
| **Quote** | D | Stock, ETF, index or crypto: logo, name, price, `ChangePill`, `Sparkline` vs previous close, market state (open, pre, after, closed), delayed label | 1D–5Y ranges, Expanded with day range, 52-week `RangeBar`, volume, market cap, P/E | 2 |
| **Watchlist** | D | Up to 12 symbols, each with price, change and mini sparkline; sort by change | Tap → Quote | 2 |
| **Currency** | D | Amount in → amount out, swap, rate, inverse rate, 30-day trend, rate date and source | Edit amount, swap, change currency | 1 |
| **CurrencyTable** | D | One amount in up to 8 currencies with flags | Edit amount | 1 |
| **Movers** | D | Top gainers/losers/most active for a market | Tap → Quote | 2 |
| **MarketOverview** | D | Major indexes (S&P 500, Nasdaq, Dow, PSEi, Nikkei, FTSE…), BTC, gold, oil, USD index | — | 2 |
| **CompanyProfile** | D | Logo, sector, description, market cap, P/E, dividend yield, next earnings, employees, HQ | Website link | — |
| **Earnings** | D | Date, time, estimates vs actual EPS and revenue, surprise % | — | — |
| **Dividends** | D | Next ex-date, pay date, amount, yield, history bars | — | — |
| **Commodity** | D | Gold, silver, oil (WTI/Brent), natural gas, per unit and in the person's currency | — | — |
| **Rates** | D | Central bank rates (Fed, ECB, BSP…), next meeting | — | — |
| **Fuel prices** | D | Local pump prices where open data exists (e.g. PH DOE weekly) | — | — |
| **FearGreed** | D | Crypto Fear & Greed `Gauge` with 30-day line | — | — |
| **Gas fees** | D | Ethereum gas low/avg/high in gwei and fiat | — | — |
| **Wallet** | D | Read-only balance of a public address (no keys, ever) | — | — |
| **Portfolio** | C/D | Holdings the person typed (kept in memory, not linked accounts): value, day P&L, allocation donut, using live quotes | Edit holdings via the bot | — |
| **PriceAlert** | D | Confirms a watcher on a price ("Tell me when BTC < $90k"), like Schedule (D-337) with current price and distance to target | Change, Cancel | 2 |
| **Inflation** | D | CPI for a country, latest and 12-month trend (World Bank / national stats) | — | — |
| **Salary / Tax** | L | Take-home pay breakdown for a country's rules (PH, US federal first) | Edit inputs | — |

### 6.3 Calculators (local, no provider)

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Loan** | L | Monthly payment, total interest, principal vs interest donut, amortization chart; edit amount, rate, term | 3 |
| **Savings** | L | Compound growth curve with contributions vs growth | 3 |
| **TipSplit** | L | Bill, tip %, people steppers, per person | 3 |
| **UnitConvert** | L | Value in → out with related units (length, weight, volume, speed, cooking) | 3 |
| **Percent / Discount** | L | Price, discount, final, saved | 3 |
| **VAT / Sales tax** | L | Net, tax, gross by country rate | 3 |
| **Budget** | C | Category bars vs limits (from what the person told the bot or a connected sheet) | — |
| **Subscriptions** | C | What renews this month, total per month/year (from email receipts the bot read) | — |
| **Math** | C | A problem with worked steps, final answer highlighted; plain text math (no math renderer is in the app today; adding one is a separate choice) | 3 |
| **Random** | L | Dice, coin, number, picker wheel from a list, with a re-roll that happens on the card | 3 |

### 6.4 Time and dates

| Card | Kind | Shows | Interactions | Wave |
|---|---|---|---|---|
| **WorldClock** | L | Up to 8 places: live time, day/night `Arc`, offset from the person, date if different | Pin | 1 |
| **MeetingPlanner** | L | Hours grid across places with working hours shaded, best overlap highlighted; "Propose" sends Event (D-337) | Drag a slot | 3 |
| **Countdown** | L | Days/hours to a date or event, live ticking, progress since start; holiday or launch art | Pin | 1 |
| **Holidays** | D | Next public holidays for a country, long weekends marked | Add to calendar | 3 |
| **DateMath** | L | "90 days from today", "days between", weekday, week number | — | 3 |
| **Timer / Stopwatch** | L | Running timer on the card (local; a reminder for long ones via Schedule) | Pause, reset | 3 |
| **PrayerTimes** | L | Five daily prayers by method and place, next highlighted, Qibla direction | Method setting | — |
| **Calendars** | L | Today in Hijri, Hebrew, Chinese lunar | — | — |
| **TimeConvert** | L | "3 pm PST in Manila" with both clocks | — | 1 |

### 6.5 Travel and transport

| Card | Kind | Shows | Interactions | Wave |
|---|---|---|---|---|
| **Flight** | D | Boarding-pass layout: airline, number, route arc, scheduled vs actual times, terminal, gate, status (on time, delayed, boarding, departed, landed), delay minutes, aircraft | Track (live), Pin, Share | 4 |
| **Trip** | C | Itinerary timeline: flights, hotel, events, with weather per day | Expand day | 4 |
| **Hotel** | C | Photo, dates, nights, address with Map, confirmation number (from email the bot read) | Directions | 4 |
| **Parcel** | D | Carrier, `Stepper` (ordered → shipped → out for delivery → delivered), last scan place and time, ETA | Track, Pin | 4 |
| **Place** | D/C | Photo, rating, price level, open now/closes at, hours, phone, Map; Directions and Call | Results (D-337) for many | 3 |
| **Directions** | D | Route on Map, duration, distance, mode, traffic delay (needs a routing provider) | Open in Maps | — |
| **Transit** | D | Next departures for a stop (GTFS-realtime where available) | — | — |
| **Destination** | D+L | Local time, weather, currency rate, plug type, language, emergency numbers, visa note link | — | 4 |
| **Visa** | C | Entry needs for a passport → country, from official sources with links and "check before you go" | — | — |
| **Advisory** | D | Government travel advisory level (US State Dept/other open feeds) | — | — |
| **Ride** | C | Grab/Uber trip summary from an email receipt | — | — |

### 6.6 Sports

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Score** | D | Crests, score, period/clock, status, scorers; live pulse on change | 5 |
| **Fixtures** | D | Next and last games for a team, `Strip` of results (W/D/L) | 5 |
| **Table** | D | League standings, the person's team highlighted, form | 5 |
| **Bracket** | D | Tournament tree | — |
| **Player** | D | Photo or initials, season stats bars | — |
| **F1** | D | Next race with countdown, last results, driver and constructor standings | — |
| **Boxing / Fight** | D | Fight card with records | — |

Sports leagues to cover first: football (EPL, La Liga, Champions League), NBA, PBA, F1, tennis
majors (decision 10).

### 6.7 Food and drink

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Recipe** | C (from page JSON-LD) | Hero photo, time, servings stepper scaling ingredients, ingredient checklist, steps with timers, nutrition | 3 |
| **Nutrition** | C | Nutrition-facts layout for a food or meal | 3 |
| **MealPlan** | C | Week grid, shopping list button → Checklist | — |
| **Wine / Coffee** | C | Tasting notes, pairing | — |
| **Restaurant** | D/C | Place card variant with menu link, price, reservations link | 3 |

### 6.8 Knowledge and reference

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Definition** | D | Word, phonetics, play pronunciation (TTS, D-284), senses with examples, synonyms | 3 |
| **Translation** | C | Source and target, play both (TTS), swap, formality note | 3 |
| **Summary** | D | Wikipedia lead image, title, 3 key facts, 2-sentence summary, "Read on Wikipedia" | 3 |
| **Person** | D | Photo, born/died, known for, key facts | — |
| **Organization** | D | Logo, founded, HQ, people, website | — |
| **Country** | D+L | Flag, capital, population, currency, languages, time, calling code | 3 |
| **Element** | L | Periodic table tile with properties | — |
| **Comparison** | C | 2–4 things side by side, rows of attributes, winner marks per row | 3 |
| **ProsCons** | C | Two columns with icons | 3 |
| **Steps** | C | Numbered how-to with images where given | 3 |
| **Timeline** | C | Dated events (history, a project) | 3 |
| **OnThisDay** | D | Events, births and deaths for today | — |
| **Quote** | C | Quote card with author, share image | — |
| **Sources** | C | Citation list with site favicon, date, and a reliability note when the bot read them | 3 |
| **Code** | C | Snippet with language, copy, line numbers (already Markdown; a card adds a title and run hints) | — |

### 6.9 Health and fitness (on-device data, never sent to providers)

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Activity** | L | Steps, distance, active energy rings for today vs goal | — |
| **Sleep** | L | Night's stages chart, duration, consistency | — |
| **Workout** | C/L | Plan (sets/reps checklist) or summary (time, HR zones) | — |
| **Water** | L | Glasses today with +1 | — |
| **Medication** | C | Schedule with "Took it" (a Checklist variant) | — |
| **Cycle** | L | Phase ring and prediction | — |
| **BMI / Body** | L | Value and band, with a "talk to a doctor" note | — |

These depend on what device data the app already reads (D-376 permissions). Decision 12 decides
whether they're in this plan at all.

### 6.10 News and media

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Headlines** | C (search results) | 3–6 stories with thumbnail, source, time; Results (D-337) variant | 3 |
| **Article** | C | Image, source, date, 3-bullet summary, read link | 3 |
| **Movie / Show** | D | Poster, year, runtime, ratings, genres, where to stream in the person's country, trailer link | 5 |
| **Showtimes** | D | Cinemas near the person, times | — |
| **Book** | D | Cover, author, pages, rating, description, buy/borrow links | 3 |
| **Song / Album** | D | Art, artist, year, tracks, play links (Spotify/Apple Music links, not playback) | — |
| **Podcast** | D | Episode art, show, duration, AudioPlayer (D-322) when a feed has an MP3 | — |
| **Video** | C | YouTube preview: thumbnail, title, channel, length, opens externally | 3 |
| **SocialPost** | C | A post from X, Threads, Reddit, Mastodon drawn natively from text the bot fetched | — |
| **Game** | D | Cover, platforms, price, deals | — |
| **PhotoOfTheDay** | D | NASA APOD with explanation | — |

### 6.11 Shopping

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Product** | C (page JSON-LD) | Image, title, price, rating, store, availability, key specs | 3 |
| **PriceCompare** | C | One product across stores, lowest highlighted | — |
| **PriceHistory** | D | A product's price line (needs a provider; later) | — |
| **Order** | C | Stepper for an order from email: ordered, shipped, delivered, items, total | 4 |
| **Receipt** | C | Details (D-337) with store logo, items, totals, tax | 4 |
| **Deal** | C | Coupon code with copy, expiry | — |
| **GiftIdeas** | C | Results carousel with prices and reasons | 3 |

### 6.12 Work and dev (from connected apps)

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **PullRequest** | D (connection) | Repo, title, author, status, checks summary, diff stats, reviewers | 5 |
| **Issue** | D | Tracker issue (GitHub, Linear, Jira) with state, assignee, priority | 5 |
| **CIRun** | D | Steps with pass/fail, duration, failing step | 5 |
| **Deploy** | D | Environment, version, status, when | — |
| **Uptime** | D | Status of monitored services, incidents | — |
| **ServerHealth** | D | CPU, memory, disk `Gauge`s for the bot's computer or a server | 5 |
| **ErrorIssue** | D | Sentry issue: count sparkline, users, top frame | — |
| **Metric** | D | One KPI with sparkline (PostHog, Stripe MRR) | 5 |
| **Doc** | C | Document preview: icon, title, owner, updated, first lines | — |
| **File** | C | File type icon, name, size, open | — |
| **Diff** | C | Code diff with colors | — |
| **Poll** | C | Question with options, live tallies in a group chat | — |

These reuse connections (D-089) and are mostly plugin or connector card files (D-345) over the
same components, so they cost little once the kit exists.

### 6.13 Home and life

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Contact** | C | Photo, name, numbers, email; Call, Message, Save | 3 |
| **Birthday** | C | Upcoming birthdays with age and a draft greeting button | — |
| **Bills** | C | Due bills from email: biller, amount, due, paid status | 4 |
| **Outage** | D | Power or water interruption schedule for the person's area (Meralco advisories, where parseable) | — |
| **Energy** | D | Use over time from a connected meter/app | — |
| **SmartHome** | D | Devices with state and toggles (only with a home connection; buttons send a message) | — |
| **Habit** | C | Streak calendar heat-map | — |
| **Plant / Pet** | C | Care schedule | — |
| **Packing** | C | Checklist variant grouped by bag, with the trip's weather | 4 |
| **Chores** | C | Rota table | — |

### 6.14 Fun

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Trivia** | C | Question, options, reveal (answers send a message) | 3 |
| **Horoscope** | C | Sign art, today's text | — |
| **Lottery** | D | Latest draw numbers (PCSO, Powerball, EuroMillions) where a clean source exists | — |
| **WordGame** | C | Word of the day, anagram, crossword clue | — |
| **Joke** | C | Setup, tap to reveal punchline | — |

### 6.15 Location and maps (extends D-310)

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Map** | — | Existing (D-310), now with `places.lookup` so bots can pass a name | 1 |
| **NearMe** | D | Results + Map split: nearby places by category | 3 |
| **Distance** | L | Straight-line distance and bearing between two places, flight time estimate | 3 |

### 6.16 Composite

| Card | Kind | Shows | Wave |
|---|---|---|---|
| **Dashboard** | D | A grid of compact cards (2 columns on phones): morning brief = Weather + Agenda + unread MessageList + Watchlist + Countdown | 3 |
| **Compare** | D | Two data cards of the same kind side by side (two cities' weather, two stocks' charts normalized to %) | 3 |
| **Carousel** | — | Several cards of the same kind swiped horizontally | 1 |

The morning brief (D-312) switches to a Dashboard once Wave 3 is in.

## 7. Wave 1 and 2 cards in detail

Field lists are the wire contract (§4.3). `?` means optional. All times ISO 8601 with offset.

### 7.1 Weather

```text
place: {name, region?, country, lat, lng, tz}
when: "now" | "YYYY-MM-DD"
now?: {temp, feels, code, isDay, humidity, windKph, windDir, gustKph?, pressureHpa?, visibilityKm?, uv?, cloud?}
day?: {high, low, feelsHigh?, feelsLow?, code, precipChance, precipMm, windKph, gustKph?, uv?, sunrise, sunset}
hours: [{t, temp, code, isDay, chance, mm?}]   ≤ 48
alerts?: [{severity, event, until}]            → shows a banner row; full card is WeatherAlert
```

- **Code** is our own enum of 28 conditions (clear, mostly_clear, partly_cloudy, cloudy, fog, drizzle,
  light_rain, rain, heavy_rain, showers, thunder, thunder_rain, snow… haze, smoke, dust, windy),
  mapped from each provider's symbols in its adapter.
- Layout: `SkyBackground` fills the card; hero temp left, art right; condition words; H/L and
  feels-like; hourly `Strip` (24 cells, now first, rain % in blue under each); facts chips (rain,
  wind with direction arrow, UV band, humidity). "Tomorrow" mode makes the hero the day's high/low
  and the strip tomorrow's hours.
- Views: Now, Tomorrow, 7 days (switches to Forecast in place).
- The model's line suggestion: one sentence of advice ("Bring an umbrella for the afternoon").
- **The screenshot test:** "weather in Manila tomorrow, one line" → `weather.get` → a Weather card in
  Tomorrow mode and the line "Hot and humid with afternoon showers, bring an umbrella." No search.

### 7.2 Forecast

```text
place, days: [{date, code, high, low, precipChance, precipMm?, windKph?, uv?, sunrise?, sunset?}] (3–14)
```

Rows: weekday, icon, rain %, `RangeBar` positioned on the week's overall min–max with a gradient
from cool to warm; today's bar shows a "now" dot.

### 7.3 RainNow

```text
place, start, stepMinutes (5 | 15 | 60), values: [mm/h] (12–48), summary: "Rain starts around 3:20 pm and lasts about 40 min"
```

Bar chart in rain blues with "light / moderate / heavy" guides. Where only hourly data exists, says
"Next 12 hours" and uses hourly steps.

### 7.4 WeatherAlert

```text
place, alerts: [{severity: "minor"|"moderate"|"severe"|"extreme", event, headline, area, start, end, instruction?, issuer, url?}]
```

Banner in severity color with icon; expands to text. US from NWS; Europe from MeteoAlarm feeds where
licensed; MET Norway for Norway; PH typhoon signals through the Storm card (decision 11).

### 7.5 SunMoon (local math)

Sun and moon positions from a port of SunCalc's algorithms in TypeScript and Dart (both tested
against the same fixtures). Arc with sun position now, sunrise/sunset, golden hour bands, day length
and its change from yesterday; moon phase drawn (not an emoji), illumination %, rise/set.

### 7.6 Currency and CurrencyTable

```text
from: "USD", amount: 100, rates: [{to: "PHP", rate: 58.21}], date: "2026-11-20", trend?: {to, points: [{date, rate}]} (30 days)
```

- Hero: "100 US dollars = 5,821.00 Philippine pesos", flags, swap button, inverse rate line,
  trend sparkline with % change over 30 days.
- Amount edits and swaps are computed in the app from `rate` (no call). Different currency → `/view`.
- Footer: "European Central Bank via Frankfurter · rates of Nov 20" (FX reference rates are daily,
  not live; the card says so). Crypto pairs route to Quote.

### 7.7 WorldClock, TimeConvert, Countdown (local)

- WorldClock: `places: [{name, tz, country}]`, `at?`. Live ticking from the device clock with tz rules
  from the `timezone` package (Dart) and `Intl` (server); day/night `Arc` per row from SunMoon; "+16
  h, tomorrow".
- TimeConvert: one time in one place → others, with both clocks drawn.
- Countdown: `{title, target, start?, art?: "new_year"|"birthday"|"launch"|"holiday"|"trip"…}`, ticks
  live, days/hours/minutes, progress ring if `start`, Pin → Canvas `countdown` template.

### 7.8 Quote and Watchlist

```text
symbol, name, kind: "stock"|"etf"|"index"|"crypto"|"fund", exchange?, currency,
price, change, changePct, prevClose?, open?, dayLow?, dayHigh?, low52?, high52?, volume?, marketCap?, pe?,
marketState: "pre"|"open"|"post"|"closed"|"24h", asOf, delayedMinutes?: 15,
chart: {range: "1D", points: [{t, p}]}
```

- Header: logo, symbol, name, exchange and market state pill. Hero price with ChangePill. Sparkline
  colored by direction vs previous close, with a dotted prev-close line. Range chips call `/view`.
- Expanded: scrub chart, day range and 52-week `RangeBar`s, stats grid, "Not financial advice".
- Watchlist rows: logo, symbol, name, mini sparkline, price, change pill; header sort.
- Price in the person's currency shown under the native one when they differ ("≈ ₱5.7M").

### 7.9 AirQuality

```text
place, aqi: {value, scale: "us"|"eu", band, dominant}, pollutants: [{id, value, unit}], hours?: [{t, aqi}], pollen?: [{kind, level}]
```

`Gauge` with band colors, advice by band ("Sensitive groups should limit outdoor exercise"), chips per
pollutant, 24 h line.

### 7.10 Storm and Earthquake

- Storm: `{name, localName?, category, windKph, pressureHpa?, position, track: [{t, lat, lng, cat}], cone?, nearest?: {place, distanceKm, eta?}, signals?: [{area, level}]}` → Map with track colored by category, header with PAGASA local name when known.
- Earthquake: `{magnitude, depthKm, place, time, lat, lng, distanceKm?, tsunami?, felt?, url}` → Map with
  rings, magnitude badge, "312 km from you".

## 8. Data providers

**Checked on 2026-11-20** means read on the provider's site today; everything else is from prior
knowledge and must be checked in Phase 0 (terms, price, limits, attribution) before any code depends
on it. A provider only ships after its row here says "checked".

| Domain | Default provider | Terms | Cost | Fallback / notes |
|---|---|---|---|---|
| Forecast, now | **MET Norway Locationforecast** | Free incl. commercial; CC BY 4.0, attribution required; identifying User-Agent; honor Expires/If-Modified-Since (checked 2026-11-20: CC BY 4.0) | $0 | Open-Meteo (see next) |
| Forecast, hourly extras, nowcast-like | **Open-Meteo** | **Free API is non-commercial only, 10,000 calls a day; a subscription gives a commercial licence** (checked 2026-11-20); the server is open source and can be self-hosted | Subscription price to check | Free tier allowed on self-hosted personal servers; Casama Cloud needs the plan or self-hosting (decision 3) |
| US alerts | NWS api.weather.gov | US government, public domain | $0 | — |
| Other alerts | MeteoAlarm (EU), MET Norway (NO) | Check each | $0 | Skip where no clean source |
| Air quality, pollen | Open-Meteo Air Quality (CAMS) | Same licence question as above | — | OpenAQ (free key, measured stations; check terms) |
| Sun, moon | Local math (SunCalc algorithms) | ours | $0 | — |
| Geocoding | Open-Meteo geocoding (GeoNames) / MapTiler / Photon | Check each; GeoNames CC BY | $0–MapTiler plan | Bundled cities list (GeoNames cities15000, CC BY) as offline fallback |
| FX | **Frankfurter** | "Free… Is the API free for commercial use? Yes" (checked 2026-11-20); blended central-bank rates; self-hostable | $0 | Self-host Frankfurter; exchangerate.host-style paid if intraday needed |
| Crypto | CoinGecko Demo API (free key, attribution) | Check rate limits and commercial terms | $0 → paid plan if needed | CoinPaprika, exchange public tickers (Binance, Coinbase) for top coins |
| Stocks | **Decision 2** (Finnhub, Twelve Data, Polygon/Massive, Alpha Vantage, FMP, EODHD) | Redistribution in a commercial app usually needs a paid plan; real-time US needs exchange agreements | Likely $30–200/month to start (check) | Delayed 15 min by default |
| Commodities | From the stock provider (futures/ETFs) or metals API | Check | — | Later |
| Holidays | Nager.Date | Open source, free (check) | $0 | Bundled calendar for PH/US |
| Time zones | IANA tz database (bundled) | Public domain | $0 | — |
| Flights | **Decision 7** (AeroDataBox, FlightAware AeroAPI, aviationstack, AviationEdge) | Per-call pricing | Check: typical $0.002–0.02 per lookup | Off unless a key is set |
| Parcels | **Decision 7** (17TRACK, AfterShip, Ship24) | Per-shipment pricing | Check | Off unless a key is set; else link to carrier page |
| Sports | **Decision 10** (API-Sports, football-data.org, TheSportsDB, SportMonks) | Free tiers limited; check commercial | Check | Off unless a key is set |
| Earthquakes | USGS GeoJSON feeds | Public domain | $0 | EMSC; PHIVOLCS has no API (link) |
| Storms | GDACS (EU JRC) feeds; JTWC | Check | $0 | PAGASA bulletins as links |
| Wikipedia | Wikimedia REST API | CC BY-SA text, image licenses vary; User-Agent | $0 | — |
| Dictionary | Wiktionary via Wikimedia REST / dictionaryapi.dev | Check | $0 | Bot composed |
| Books | Open Library | Free, check | $0 | Google Books |
| Movies, TV | TMDB | Free with attribution; **commercial use needs their agreement** (check) | Check | JustWatch-style "where to stream" via TMDB's watch providers |
| APOD | NASA API | Public domain | $0 | — |

## 9. Costs and metering

- **Free providers:** no `usage_ledger` row per call (refreshes would flood it). A daily rollup
  `live_data_daily(provider, calls, cache_hits)` (server-only) shows volume in the admin console.
- **Paid providers:** every upstream call writes a `usage_ledger` row, kind **`live_data_calls`**
  (new), `meta.provider`, cost from the provider's price; cache hits write nothing.
- **Who pays (default, decision 5):** like web search (D-384, D-400), Casama Cloud pays from its own
  keys and doesn't bill credits for free and cheap providers; flights and parcels are billed to
  credits at cost × 1.3 because each lookup is per person and not shareable. A workspace key pays
  itself.
- **Caps:** per workspace per day, `live_paid_calls_day` in plan limits (Free 20, Plus 200, Pro 1,000,
  Max 5,000 to start); refresh limits in §4.4; pinned cards refresh on the worker's schedule only.
- **Estimated Cloud cost** at 1,000 daily active people, 5 data cards each a day, 70% weather/FX/time
  (free), 30% markets: with shared caching, markets need roughly one call per symbol per minute
  during market hours for the few hundred popular symbols, well inside a $50–200/month plan. Flights
  and parcels scale per person and are billed through.
- **Tokens saved:** a weather answer today costs a search (~$0.001) plus page reads and ~3–8k tokens
  (~$0.002–0.02 on mid models); after, ~300–600 tokens. This likely pays for the stock plan on its own.
- `docs/COSTS.md` gets a "Live data cards" row (and one per paid provider) in the same commit as each
  provider.

## 10. Privacy, safety and compliance

1. **What leaves Casama:** place coordinates rounded to 0.01° (~1 km) for weather (cache keys at
   0.1°), symbols, currency codes, flight numbers, tracking numbers. Never names, emails, chat text
   or ids. Tracking and flight numbers go only to the provider the person's workspace uses.
2. **Device location** only through D-376's permission card, rounded on the device, used for that
   question; stored only if the person saves it as home.
3. **Finance:** "Not financial advice" in Expanded quote views and on Portfolio; delayed data labeled;
   no buy/sell; the bot's instructions forbid recommendations dressed as facts.
4. **Health cards** use on-device data only; never cached on the server; private on Lock Screen.
5. **Lock Screen and private mode** (D-405): pinned cards with personal data (parcels, flights,
   portfolio) are `privacySensitive`; public data (weather, BTC) isn't.
6. **Documents to update in the same commit:** privacy policy (new sub-processors: each provider that
   receives coordinates or tracking numbers), store privacy labels (approximate location, if device
   location is used), docs-site page for cards, `THIRD_PARTY_NOTICES.md` (Meteocons, flag-icons,
   GeoNames, SunCalc port), in-app attributions (Settings → About → Data sources).
7. **Untrusted text:** provider strings (place names, headlines, descriptions) are escaped and length-
   limited; Wikipedia and news text count as untrusted when shown to the model (`wrapUntrusted`).
8. **Abuse:** refresh and view routes are rate-limited; args come from the stored row, never the
   client; providers' hosts are fixed; widget keys may read pinned live cards only (added to
   `WIDGET_ROUTES` like D-452).
9. **App Store:** no gambling (no odds), no trading; weather alerts state their issuer and don't
   claim to be official warnings unless they are.

## 11. What bots are told

- The `live` group's index line: "Weather, air, sun and moon, stock and crypto prices, currency
  rates, time zones, countdowns, holidays, flights, parcels, scores, earthquakes, storms, word
  definitions and encyclopedia summaries come from these tools, not from web search. They show the
  person a card; answer in one short line and don't repeat the numbers."
- `web.search`'s description gains: "For weather, prices, rates, time zones, flights, parcels and
  scores, use the live tools first; search only when they can't answer."
- `ui.catalog` gets the composed cards with examples; `ui.show`'s own description adds only "Recipe,
  Comparison, Steps… are in ui.catalog."
- Voice prompts (`voice.ts`) get the live tools with speech-friendly text results.
- **Evals** (`packages/evals`): 40 prompts in English, Filipino and Taglish (weather tomorrow,
  "magkano ang dollar ngayon", BTC price, "what time is it in SF", "PR102 status", "is it going to rain
  later", two-city compare). Pass = right tool, card shown, no web.search, reply ≤ 2 sentences, no
  invented numbers in text. Run in the nightly evals.

## 12. Analytics

Events (PostHog catalog, `packages/contracts/analytics/catalog.json`), no content, no places, no
symbols:

| Event | Properties |
|---|---|
| `card_shown` | `card`, `kind` (data/composed/local), `source` (tool/plugin/ui_show), `provider` |
| `card_refreshed` | `card`, `trigger` (auto/manual/view), `result` (ok/stale/error) |
| `card_view_changed` | `card`, `view` |
| `card_expanded` | `card` |
| `card_pinned` / `card_unpinned` | `card`, `surface` (home/lock/watch/mac) |
| `card_shared` | `card`, `as` (image/text) |
| `card_reported` | `card`, `provider` |

Server: `live_data_daily` volumes; tool error rates by provider in the observability package.
North-star check after Wave 1: share of weather/price/rate questions answered without `web.search`
(target 90%), and median tokens per such answer.

## 13. Testing

- **Providers:** each adapter tested against recorded fixtures (`packages/agent/test/live-data/fixtures/`),
  including errors, rate limits, odd symbols, missing fields, units. No live calls in CI. A manual
  `scripts/live-data-smoke.ts` hits real providers once per Phase for the record.
- **Cache:** single-flight, TTLs, stale-on-error, key normalization, cleanup.
- **Tools and run:** `apps/server/test/live-cards.test.ts` with fake providers: card emitted, model told,
  `card: false`, fallback to search on provider failure, `ui.show` refusing a forged `live`.
- **Routes:** refresh/view auth (RLS), limits, args from row only, widget-key access.
- **pgTAP:** `live_cards`, `live_data_private_cache`, `live_card_reports` RLS; `live_data_cache` and
  `live_data_daily` service-only.
- **Contracts:** JSON Schemas with sample fixtures per card, shared by TS and Dart tests.
- **Flutter:** golden tests per card × light/dark × compact/regular/expanded × text scale 1.0/2.0 ×
  states (fresh, stale, error, empty) on the Wave's cards (`client/test/cards/`), contrast checks on
  every sky background, unit conversion tests, number formatting per locale (en-US, en-PH, fil, ja,
  de), reduced-motion test.
- **Native widgets (Stage B):** Swift and Kotlin model tests like D-452's scripts.
- **Evals:** §11.

## 14. Phases

Each phase: code, tests, `CHANGELOG.md`, `docs-site` card pages, `docs/ARCHITECTURE.md` where it
changes, the decision entry, and PLANS.md status.

### Phase 0: Decide and design (no app code)

- Oliver's answers to §16.
- Check every Wave 1–2 provider's terms, limits and prices (§8 rows to "checked"); open accounts only
  where Oliver agrees; keys into the vault.
- `docs/media/cards-mockups.html` for Wave 1 and 2 cards + generated concept images; Oliver picks.
- License check for Meteocons, flag-icons, GeoNames, SunCalc port.
- **Done when:** §16 answered, §8 Wave 1–2 rows checked, mockups approved.

### Phase 1: Foundation and weather (Wave 1)

- `live-data/` providers, cache tables, `places.lookup`, `weather.get`, SunMoon math, `fx.convert`,
  `time.compare`, `time.until`.
- Run: built-in tool cards (generalized D-345 path), `live` block, `card: false`.
- `live_cards`, refresh/view/get routes, limits.
- App: card kit (§5.1), Weather, Forecast, RainNow, WeatherAlert, SunMoon, Currency, CurrencyTable,
  WorldClock, TimeConvert, Countdown, Carousel; units settings and home place; auto-refresh.
- Bot text and evals (§11); analytics events; privacy page and notices; COSTS rows.
- **Done when:** the two screenshot questions answer with a Weather card and one line in the app on
  iPhone, Android, web and Mac (device checks after Oliver approves a build); evals ≥ 90%; goldens
  pass; refresh works with no model call (checked in run events and ledger).

### Phase 2: Markets, air, hazards (Wave 2)

- Stock provider (decision 2), CoinGecko, `markets.quote/chart/movers`, Quote, Watchlist, Movers,
  MarketOverview, PriceAlert (a watcher with a price condition, using the existing watchers).
- Air quality, pollen, UV, Storm, Earthquake.
- **Pin to widgets, Stage A** (Canvas fed by live cards; worker refresh).
- **Done when:** quotes refresh during market hours from the shared cache (one upstream call per
  symbol per window, checked in `live_data_daily`), pinned Weather and BTC widgets update with no
  runs, delayed labels everywhere.

### Phase 3: Composed cards and reference (Wave 3)

- `web.fetch` JSON-LD extraction and `cards.fromPage`; Recipe, Product, Place, Restaurant, NearMe.
- Definition, Summary, Country, Translation, Comparison, ProsCons, Steps, Timeline, Sources,
  Headlines, Article, Book, Video, Contact, Trivia.
- Calculators (§6.3), MeetingPlanner, Holidays, DateMath, Timer, Distance.
- Dashboard and Compare; the morning brief becomes a Dashboard.
- **Done when:** each card has goldens, a catalog entry and an eval prompt; the brief shows as a
  Dashboard.

### Phase 4: Travel and life admin (Wave 4)

- Flights and parcels providers (decision 7), Flight, Parcel, Trip, Hotel, Destination, Order,
  Receipt, Bills, Packing; private cache; live flight tracking near departure (auto-refresh and a
  push on gate change or delay via a watcher).
- **Done when:** a flight and a parcel track end to end against fakes and one real lookup each.

### Phase 5: Sports, media, dev (Wave 5)

- Sports provider (decision 10): Score, Fixtures, Table. TMDB (decision 13): Movie/Show.
- Dev cards over connections and Dev kit card files: PullRequest, Issue, CIRun, ServerHealth, Metric.
- **Done when:** live score refreshes every 30 s while visible; dev cards render from GitHub via the
  Dev kit.

### Phase 6: Native live widgets and watches (Stage B)

- SwiftUI and RemoteViews Live card widgets for Weather, Quote, Watchlist, WorldClock, Countdown,
  Flight; watch complications and a Wear tile (temperature, price, countdown).
- **Done when:** Swift/Kotlin model tests pass; device checks after approved builds.

### Phase 7: The long tail

The "—" rows in §6, picked by `card_shown` demand and `card_reported` data, plus plugin-refreshable
cards (§4.8) and a gallery Cards section.

## 15. Risks

| Risk | Mitigation |
|---|---|
| Free provider changes terms or rate-limits us | Fallback order, shared cache, self-hostable Open-Meteo and Frankfurter, provider health in the admin console |
| Stock data licensing | Delayed data by default, a licensed plan before launch, clear labels |
| Bots keep using web search | Tool text, evals, and a soft nudge: when `web.search` gets a weather/price query, the result adds "Use weather.get for this" |
| Card sprawl in the chat | Max 4 data cards per reply then a Carousel; compact size in carousels |
| App size from assets | Measure; load Lottie weather art lazily; drop animated set if over budget |
| Refresh load | Visible-only, foreground-only, caps, shared cache, 304s for widgets |
| Wrong place (two Springfields) | `places.lookup` returns candidates; ambiguous → PersonPicker-style PlacePicker card ("Which Springfield?") |
| Time zones and DST bugs | tz database on both sides, fixtures around DST changes |
| Older apps | One line of text always; the card is a bonus |
| Looks drift across 150 cards | One kit, golden tests, mockups per wave, a design review per wave |

## 16. Decisions for Oliver

Defaults are what the plan assumes if he says "defaults".

| # | Decision | Options | Default |
|---|---|---|---|
| 1 | Scope of the first go-ahead | Phase 0–1 only / 0–2 / everything in §14 | **0–2** (weather, money, time, widgets Stage A) |
| 2 | Stock data provider | Finnhub / Twelve Data / Polygon (Massive) / FMP / EODHD / none yet | **Pick in Phase 0** after checking commercial terms; lowest-priced plan that allows display in a commercial app, delayed 15 min |
| 3 | Open-Meteo on Casama Cloud | Paid plan / self-host the open-source server / MET Norway only | **MET Norway first**, Open-Meteo self-hosted on the existing server for air quality and extras |
| 4 | Geocoding on Cloud | MapTiler (paid, also unlocks D-310 tiles) / Open-Meteo geocoding / Photon | **Open-Meteo geocoding**, MapTiler later with map tiles |
| 5 | Who pays | Casama pays all / credits for paid lookups / credits for all | **Casama pays free and markets; flights and parcels from credits at cost × 1.3** |
| 6 | Weather art | Meteocons (MIT) / commissioned set via image model / both | **Meteocons**, with our own sky backgrounds |
| 7 | Flights and parcels providers | Pick per §8 / skip for now | **Wave 4, pick in Phase 0** |
| 8 | Data cards only from tools, never from `ui.show` | Yes / allow bots to fill data cards | **Yes** (no invented numbers) |
| 9 | Native live widgets (Stage B) | Yes, Phase 6 / Canvas only | **Yes, after Stage A proves use** |
| 10 | First sports leagues | Football, NBA, PBA, F1, tennis / other | **Football + NBA + PBA + F1** |
| 11 | Philippines-specific sources | PAGASA signals, PHIVOLCS, DOE fuel prices, BSP rates, PCSO | **Links and GDACS/USGS in Wave 2; scraping none** |
| 12 | Health cards in this plan | Yes / separate plan | **Separate plan** |
| 13 | TMDB for movies | Yes (check commercial terms) / skip | **Check in Phase 0** |
| 14 | Units default | By locale / always metric | **By locale**, editable |
| 15 | Red means up in Asia | By locale / never / setting only | **Setting, default by locale** |
| 16 | Morning brief as a Dashboard | Yes in Phase 3 / no | **Yes** |
| 17 | Max data cards per reply before a carousel | 2 / 4 / 6 | **4** |
| 18 | Auto-refresh in old chats | 7 days / 24 h / never | **7 days** |
| 19 | Share as image watermark | Small Casama mark / none | **Small mark** |
| 20 | Plan limits for paid lookups a day | As §9 / other | **As §9** |

## 17. Docs and files that change

- `docs/DECISIONS.md` (one entry per phase), `docs/PLANS.md` (row), `docs/COSTS.md`,
  `docs/ARCHITECTURE.md`, `CHANGELOG.md`, `THIRD_PARTY_NOTICES.md`, `docs/NEEDS-FROM-OLIVER.md`.
- `docs-site`: a "Cards" page (what each card shows, sources), self-hosting page (provider env vars),
  plugin docs (new components for card files), privacy page.
- `agent-kit/skills/`: the plugin-cards skill lists the new components.
- Code (new): `packages/agent/src/live-data/**`, `packages/contracts/cards/**`,
  `client/lib/features/chat/widgets/cards/**`, `client/lib/core/units.dart`, migrations for
  `live_cards`, `live_data_cache`, `live_data_private_cache`, `live_data_daily`,
  `live_card_reports`, profile units and home place.
- Code (changed): `packages/domain/src/a2ui.ts` (components and checks),
  `packages/agent/src/tools/ui-catalog.ts`, `run.ts` (built-in tool cards), `tools/autonomy.ts`
  (`web.search` text, `web.fetch` JSON-LD), `voice.ts`, `glance.ts`/canvas worker (pins),
  `bot_ui.dart` (registering cards), settings screens (units, home place).
