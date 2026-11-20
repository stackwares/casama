# GA4 next to PostHog: plan

Status: **live** (D-439, 2026-11-20; see `docs/GA4-LAUNCH-PLAN.md`). Built 2026-11-18 (D-397), with the defaults below. Where the build differs from this text is listed in "What changed in the build" at the end. Oliver asked: "instead of just PostHog analytics and
funnels can we also support GA4 so it's a free alternative? but can we keep both for now?"

## Summary

Casama sends product analytics to PostHog today (D-206 to D-210). Project 637030 is shared with the other
Stackwares apps and is already past PostHog's free tier, so every event costs money. Google Analytics 4 is free
at our volume. This plan sends **the same catalog events to both** PostHog and GA4. Each one has its own on/off
setting, so PostHog can be cut back or dropped later without touching a call site.

- **The app** (iOS, Android, macOS, web): `firebase_analytics`, in the Firebase project we already ship
  (`kasama-ai`), linked to a new GA4 property.
- **The server** (50 of the 88 catalog events, including sign-up, purchase and refunds): the GA4 Measurement
  Protocol.
- **The same rules as PostHog:** one Privacy switch covers both, the workspace switch is honored, nothing goes
  to GA4 from a self-hosted server, there's no personal content, and deleting an account deletes its GA4 data.
- **Not in GA4:** crash reports (they stay on PostHog or Sentry, D-063), session replay (off anyway), feature
  flags, and the personless workspace rollups.

## What exists today

| Piece | Where |
|---|---|
| Event catalog: 88 events, 86 property keys, `by: client/server` | `packages/contracts/analytics/catalog.json` → `client/lib/core/analytics_events.g.dart` |
| App analytics facade (consent, identify, reset, capture, featureUsed, dailyPing) | `client/lib/core/analytics.dart` |
| PostHog setup, screens, errors; web loads posthog-js on the fly | `client/lib/core/telemetry.dart`, `telemetry_web.dart` |
| Build-time keys | `client/config/telemetry.json` (`POSTHOG_*`, `SENTRY_DSN`), `client/config/firebase.json` |
| Server sink (`ProductAnalytics`, null when off) | `packages/observability/src/analytics.ts` |
| Server callers | `apps/server/src/billing/service.ts`, `services/analytics-signups.ts`, `worker/analytics-rollup.ts`, `packages/agent/src/analytics.ts` |
| Opt-out (user + `organizations.analytics_opt_out`) | Privacy screen, `apps/server/src/services/privacy.ts` |
| Erasure | `apps/server/src/services/posthog-erase.ts` |
| Privacy policy | `site/privacy.html` (§ analytics + processor table), `docs-site/guide/privacy.md` |

Firebase is already in the app for push only (`firebase_core`, `firebase_messaging`). There's no
`firebase_analytics` and no GA4 property yet.

## What the platforms allow

- **`firebase_analytics` runs on Android, iOS, macOS and web.** It doesn't run on Windows or Linux. Calling the
  Measurement Protocol from the app instead would ship the API secret inside the binary, so those two platforms
  send nothing to GA4.
- **Names fit.** I checked every catalog event against GA4's rules: none is over 40 characters, none uses a
  reserved prefix (`firebase_`, `google_`, `ga_`) or a reserved name (`first_open`, `screen_view`, …), and none
  has more than 25 properties. GA4's cap of 500 distinct event names per app is far above our 88.
- **Custom dimensions: 50 event-scoped and 25 user-scoped on the free tier.** The catalog has 86 property keys.
  GA4 receives all of them, but only registered ones show in reports and Explorations; the rest are visible only
  in DebugView and the BigQuery export. So we register a chosen 50 at most (see Decision 4).
- **Values:** text values are cut at 100 characters, and user property values at 36.
- **Measurement Protocol:** an app stream needs the app's `app_instance_id`, and a web stream needs a
  `client_id`. `user_id` is optional and joins devices. The body must be under 130 kB. Audience events have to
  arrive within 30 days (web) or 42 days (app) of the id's last online activity.
- **No PII.** Google's terms forbid sending personal data. Our catalog already bans it (`forbidden_property_words`,
  ANALYTICS-PLAN §5), and ids are Casama uuids, which GA4 allows.
- **Cost:** standard GA4 and Firebase Analytics are free. BigQuery export is also free within the sandbox, with
  a daily export cap of 1M events.

## How it works

### Client

1. **Sinks:** `Analytics` stops calling `Posthog()` directly and fans out to a list of sinks with one interface
   (`identify`, `reset`, `capture`, `screen`, `setEnabled`):
   - `PosthogSink`: today's code, moved over unchanged.
   - `Ga4Sink`: `FirebaseAnalytics.instance`. `logEvent` takes the catalog name and the cleaned properties
     (booleans become `0`/`1`, nulls are dropped, text is cut at 100). `setUserId` takes the Casama user id.
     `logScreenView` takes the route template, never ids. `setAnalyticsCollectionEnabled` follows the switch.
2. **When each sink is on:** PostHog stays as it is. GA4 is on when `GA4_ENABLED=true` is set in
   `telemetry.json`, the build is official, the server is Casama Cloud, the platform is supported and the
   person's consent is on. The rule is the same as PostHog's, plus the platform check.
3. **Before any consent check:** `FIREBASE_ANALYTICS_COLLECTION_ENABLED=false` (Info.plist) and
   `firebase_analytics_collection_enabled=false` (AndroidManifest). Collection is turned on in code only after
   step 2 passes, so a self-hosted connection, or a person who switched it off, never sends even `first_open`.
4. **No ad ids:** on iOS and macOS, `$FirebaseAnalyticsWithoutAdIdSupport = true` in the Podfile, so there's no
   IDFA and no App Tracking Transparency prompt. On Android, `google_analytics_adid_collection_enabled=false`,
   and the merged manifest removes the `AD_ID` permission. Google Signals and ad personalization are off in
   the property.
5. **Web:** `firebase_analytics` loads gtag from `googletagmanager.com`. The web CSP gets
   `https://www.googletagmanager.com`, `https://*.google-analytics.com` and
   `https://*.analytics.google.com`. A self-host web build has no measurement id and loads nothing.
6. **Server id hand-off:** after sign-in, the app sends its GA4 `appInstanceId` to the server, the same way
   `syncOptOut` works: once per change, then cleared on sign-out. The server stores it per user and platform,
   so its events land on the same GA4 user and device as the app's.

### Server

1. `ProductAnalytics` becomes a fan-out of `PostHogProductAnalytics` and a new `Ga4ProductAnalytics`, each one
   on or off by itself:
   - `PRODUCT_ANALYTICS=on` keeps gating everything.
   - `POSTHOG_API_KEY` turns PostHog on.
   - `GA4_MEASUREMENT_ID` + `GA4_API_SECRET` (web stream) and/or `GA4_FIREBASE_APP_ID` + the same secret
     (app stream) turn GA4 on.
2. **Ids:** when we have a stored `appInstanceId`, the event goes to that app stream. Otherwise it goes to a
   "Casama server" web stream with `client_id = deterministicUuid('ga4', userId)`. `user_id` = Casama user id
   in both cases, so GA4's User-ID identity joins them.
3. **What GA4 gets:** person events only. Personless events and the daily workspace rollups are skipped,
   because GA4 has no personless mode and would count each workspace as a user. The per-user daily rollup is
   also skipped at first, since it would double-count `user_engagement` (Decision 5).
4. **Revenue:** `purchase` maps to GA4's recommended `purchase` event (`currency`, `value`, `transaction_id` =
   store transaction id). `refund_issued` also sends GA4's `refund` event. This is GA4's main free advantage:
   its built-in revenue and LTV reports work without extra setup.
5. **Sending:** batches of up to 25 events per request, a short flush interval, and the same retry and close
   behaviour as PostHog. A failure is logged and never blocks the caller.
   `GA4_DEBUG=1` uses the `/debug/mp/collect` validation endpoint in tests and staging.
6. **Erasure:** `posthog-erase.ts` becomes `analytics-erase.ts` with two backends. GA4 uses the User Deletion
   API (`userDeletionRequests:upsert`) by `user_id` and every stored `appInstanceId`. It needs a service account
   with Editor on the property (`GA4_PROPERTY_ID`, `GA4_SERVICE_ACCOUNT_JSON`). As with PostHog, a failure is
   reported and never blocks the purge.

### Shared

- **Catalog:** an optional `ga4` block per event, for a renamed GA4 event (`purchase` → recommended params) or a
  property mapping. The catalog test checks GA4's naming rules, so a future event can't break GA4.
- **GA4 property setup** (Oliver's account, or mine with an OK):
  - a new property "Casama", linked to Firebase project `kasama-ai`, with iOS/Android/web streams plus the
    "Casama server" web stream;
  - data retention set to 14 months;
  - Google Signals off and ads links off;
  - the custom dimensions from Decision 4;
  - key events: `signed_up`, `first_value`, `purchase`;
  - BigQuery export if wanted.

## What's not shipping

- Crash reporting in GA4 (Crashlytics). We keep a single error reporter (D-063).
- Windows and Linux in GA4 (no plugin, and the secret can't ship in the app).
- GA4 on self-hosted servers or on community builds. Self-hosters can still point `GA4_*` at their own
  property, the way they can with PostHog.
- Dropping PostHog. That's a later decision, once GA4 has run side by side for a few weeks (Decision 7).

## Phases

| # | Work | Done when |
|---|---|---|
| 0 | GA4 property + streams + secrets in Vaultwarden + COSTS.md entry ($0) | Property exists; ids in `telemetry.json`/`.env` |
| 1 | Server fan-out + GA4 MP sink + `purchase`/`refund` mapping + erase backend + catalog GA4 checks | Unit tests against a recording fake and the MP validation endpoint; PostHog behaviour unchanged |
| 2 | Client sinks + `firebase_analytics` + collection-off defaults + no ad ids + `appInstanceId` hand-off + web CSP | `flutter test` green; DebugView shows a sign-in → first value flow from a local run (needs a debug build: ask first) |
| 3 | Privacy policy, docs, store forms, D-entry | `site/privacy.html` lists Google Analytics; Apple/Play forms updated (Oliver) |
| 4 | Register custom dimensions, key events, build the GA4 funnels matching PostHog F1–F6 | Same funnel numbers within reason in both tools after a week |

Everything up to phase 2 is code only. A prod deploy and the app builds each need Oliver's yes.

## Decisions for Oliver

| # | Question | Default |
|---|---|---|
| 1 | One Privacy switch for both, or a separate GA4 switch? | One switch: "Share usage data" covers both |
| 2 | Server events with no app instance yet: send them through the "server" web stream, or skip them? | Send them (sign-up and purchase matter most) |
| 3 | Windows and Linux: nothing, or a server proxy that relays app events to the Measurement Protocol? | Nothing for now |
| 4 | Which 50 properties to register as custom dimensions? | Funnel and money first: `plan`, `interval`, `store`, `kind`, `method`, `step`, `step_index`, `feature`, `milestone`, `provider`, `trigger_kind`, `paywall_kind`, `surface`, `screen`, `error_code`, `outcome`, `reason`, `source`, `via`, `role`… (~35), leaving room |
| 5 | Send the per-user daily rollup (`usage_daily`) to GA4 too? | No: GA4 has its own engagement metrics |
| 6 | Turn on BigQuery export (free sandbox, 1M events/day)? | Yes, daily export |
| 7 | When do we decide on cutting PostHog? | After 4 weeks of both, comparing the funnels |
| 8 | GA4 property in which Google account? | The Stackwares account that owns Firebase `kasama-ai` |

## Risks

- **EU privacy:** some EU regulators ruled against GA in 2022. The EU-US Data Privacy Framework (2023) covers
  Google now, but GA4 draws more scrutiny than PostHog. Mitigations: analytics stay switchable, there's no ad
  id, Signals is off, and GA4 doesn't store IP addresses. The policy has to name Google as a processor.
- **Counts won't match exactly.** GA4 samples and applies thresholds in some reports and counts users its own
  way. PostHog stays the number of record until Decision 7.
- **Store forms:** adding Firebase Analytics changes the Apple privacy label and the Play data safety form
  ("App interactions" and "Device or other IDs", used for analytics and linked to the user). Shipping an app
  build before updating them risks a store rejection.
- **Bundle size:** `firebase_analytics` adds a little to the mobile builds, and gtag adds about 100 kB to the
  web app, loaded only when GA4 is on.

## Sources

- firebase_analytics platforms: https://pub.dev/packages/firebase_analytics/score
- Measurement Protocol reference: https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference
- Sending MP events (app vs web ids): https://developers.google.com/analytics/devguides/collection/protocol/ga4/sending-events
- MP use cases and timing windows: https://developers.google.com/analytics/devguides/collection/protocol/ga4/use-cases
- Event naming rules and limits: https://support.google.com/analytics/answer/13316687
- Custom dimension limits: https://support.google.com/analytics/answer/10075209
- User Deletion API: https://developers.google.com/analytics/devguides/config/userdeletion/v3

## What changed in the build (2026-11-18)

- **The property already existed.** Firebase `kasama-ai` is linked to GA4 property "kasama-ai" with five app
  streams (no data yet). Since D-396, its web stream "Kasama (web)" (`G-4GVRF0K324`) carries casama.ai page
  views. The server and the web app each need a stream of their own; neither may reuse that one.
- **Easy on/off for self-hosters (Oliver: "make it easier for other self hosters to be disabled/enabled").**
  - Server: `ANALYTICS_PROVIDERS` = `posthog`, `ga4`, `posthog,ga4` or `none`. Unset means every provider that
    has keys. `PRODUCT_ANALYTICS=on` stays the master switch.
  - App: the same `ANALYTICS_PROVIDERS` key in `client/config/telemetry.json`.
- **No `appInstanceId` hand-off in v1.** Server events always go to the server web stream with
  `user_id` = Casama user id and a `client_id` derived from it. GA4's User-ID identity joins them to app events.
  Plan step 6 and the app-stream routing are left for later.
- **No extra GA4 `refund` event.** `refund_issued` carries no transaction id that matches the purchase's, so it
  goes to GA4 as it is. `purchase` goes with `currency: USD` and `transaction_id` = the event's dedupe id.
- **No dedupe on retries.** PostHog merges a retried once-only event by its uuid; the Measurement Protocol
  has no equivalent. A retried server event can count twice in GA4.
- **Erasure:** `apps/server/src/services/analytics-erase.ts` deletes by `USER_ID` and by the derived
  `CLIENT_ID`. Pre-sign-in app events (app instance id only) aren't erased, because they aren't linked to the
  account.

## Funnels and the websites (D-398, 2026-11-18)

Oliver: "make sure we have a robust GA4 analytics and funnel implementation in both flutter apps and
websites".

### GA4's recommended events (app and server)

Catalog events can name a `ga4_twin`. GA4 then also gets one of its recommended events, built from the
event's own properties plus constants, and PostHog never sees the twin. `pnpm gen` writes the twins for both
sides: `analyticsGa4Twins` in `client/lib/core/analytics_events.g.dart` for the app, and
`packages/contracts/src/ga4-twins.generated.ts` for the server.

| Catalog event | GA4 twin | Side |
|---|---|---|
| `signed_up` | `sign_up` (`method`) | server |
| `sign_in_completed` | `login` | app |
| `onboarding_begin` / `onboarding_complete` | `tutorial_begin` / `tutorial_complete` (`path`) | both |
| `purchase_started` | `begin_checkout` (`store`, `kind`, `product_id`, `currency: USD`) | app |
| `invite_shared` / `referral_shared` | `share` (`method`, `content_type: invite/referral`) | app |
| `join_completed` | `join_group` (`via`, `status`) | app |
| `purchase` | sent as GA4's `purchase` itself (`currency`, `transaction_id`) | server |

The catalog test checks that every twin is a GA4 recommended event, doesn't share a name with a catalog
event, copies only properties the event has, and that both generated files are current. Server events that
carry `plan` also set the GA4 user property `plan`, so every report can be split by plan.

### Websites

See D-398 and `site/gallery-link.js`. casama.ai's Worker is the one collector for casama.ai, the docs, the
gallery and casama.link:
- the visitor id is daily and needs no cookie;
- funnel events come from the Worker routes;
- a short allowlist of on-page events comes from the beacon;
- links into the app carry `utm_*` (the web app) and a Play install referrer (Android), so GA4 attributes
  sign-ups to the site.

### Property setup and funnel reports

- `node scripts/ga4-setup.mts` shows the plan as a dry run; `--apply` makes the changes. It sets up:
  - 41 event-scoped custom dimensions, under the cap of 45 (the free limit is 50);
  - 4 user dimensions and 2 metrics;
  - the key events;
  - 14-month retention.

  It only adds; it never deletes.
- `node scripts/ga4-funnels.mts [--funnel F2] [--days 28] [--breakdown platform] [--json]` runs W1 and F1–F8
  through the Data API (`runFunnelReport`).
  - App and server steps count production only.
  - W1 (website → active user) is an open funnel. Website steps are scoped to a visitor-day, while app and
    server steps are scoped to the account.
- Tests: `node --test scripts/ga4-scripts.test.mts`.
- Credentials (Oliver), either one:
  - a service account added as Editor in GA4 Admin → Property access management, its key in
    `GA4_SERVICE_ACCOUNT_JSON` or `GA4_SERVICE_ACCOUNT_FILE`, with the Admin API and Data API enabled;
  - `gcloud auth login --scopes=https://www.googleapis.com/auth/analytics.edit,https://www.googleapis.com/auth/analytics.readonly`,
    then `GOOGLE_ACCESS_TOKEN=$(gcloud auth print-access-token)`.

## Windows and Linux (D-399, 2026-11-18)

- **Relay:** Firebase Analytics doesn't run on Windows or Linux, so the app's `Ga4RelaySink` batches catalog
  events and screen views (up to 25 per call, every 30 seconds) to `POST /v1/analytics/events`. The server
  forwards them to GA4 only (PostHog already gets them from the app).
- **What the server forwards:**
  - only catalog app events, with only their catalog properties, plus their twins;
  - screens as `page_view`s at `https://app.casama.ai<route>`;
  - nothing for opted-out people, or when it has no GA4 keys.
- **Signed-in only:** the endpoint needs a session, so events from before sign-in are dropped.
- **PostHog on Windows and Linux:** `posthog_flutter` has a pure-Dart client there, so it always worked. But
  the desktop workflow builds Windows and Linux from the repo secret `CASAMA_TELEMETRY_JSON`, and that secret
  didn't exist, so those builds had no keys. It now holds the PostHog key and Sentry DSN (Vaultwarden: "Casama ·
  PostHog project key", "Casama · Sentry DSNs") plus `GA4_ENABLED=true` (set 2026-11-18).
