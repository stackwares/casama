# Product analytics, funnels and crash reporting: plan

Status: **ready to execute** (Oliver, 2026-11-12: "we want an agent to start working on it").
The recommendations in §12 are adopted as defaults. Record them as decisions in
`docs/DECISIONS.md` when the first phase lands (check the highest number first; it was D-203 on
2026-11-12).

## Execution brief (read this first)

**Goal:** build Phases 0–3 of §11 in order, then the code side of Phase 4. Each phase ends at its
"Done when" check, then gets a commit and a push.

**Defaults adopted from §12:**

| # | Default |
|---|---|
| 1 | `ERROR_REPORTING=posthog` for official builds and Cloud; the Sentry path stays |
| 2 | Analytics on by default, with the sign-in notice, the Privacy switch and the workspace switch |
| 3 | On a self-hosted server: crash reports plus `app_active_daily` only |
| 4 | Lifecycle events off, screen dedupe, rollups |
| 5 | North star: weekly active doers |
| 6 | Add the "See plans" action on out-of-credits run failures |
| 9 | `telemetry.json` out of git |

If an agent finds a default unworkable, it picks the closest option, writes down why in the
decision entry, and keeps going.

**Rules (same as every Casama task):**
- **Commits:** stage by explicit path. Never `git add -A` or `git add .`. Never leave anything
  staged between turns. Other sessions share this tree and its index, so stage per hunk when
  another session's edits share a file.
- **Formatting:** `dart format` only new Dart files, never directories or existing client files.
  `biome --write` only on files you touched.
- **Before each push:** run the full suites (server incl. billing, agent, contracts, domain,
  pgTAP, Flutter) plus an Android and an iOS build check. `check.sh` prints
  `!!!! TYPECHECK FAILED !!!!`, so grep the whole log. The shell needs `LC_ALL=en_US.UTF-8`.
- **Pulling:** `git pull -q --rebase --autostash`.
- **Database:** new tables get RLS, `public.allow_worker` and a pgTAP test. The worker never reads
  `auth.*` directly; use a `public.worker_*` security-definer function. Apply migrations with
  `supabase migration up`.
- **Not allowed:**
  - Deploys, store uploads, or changes to the production VPS.
  - Any write to the PostHog project: dashboards, insights, cohorts, actions, project settings or
    transformations. Read-only queries through the PostHog MCP are fine.
  - Spending money.
- **Same commit:** privacy page, docs-site, privacy manifests and `docs/COSTS.md` change in the
  same commit as the code they describe.
- **Docs to update:** `docs/ARCHITECTURE.md` and `CHANGELOG.md` per phase.
- **Line numbers in this plan are from 2026-11-12.** Re-find each hook before editing.

**Needs Oliver's hands** (log in `docs/NEEDS-FROM-OLIVER.md` and work around it; don't block):

| Item | Work around it by |
|---|---|
| The real `client/config/telemetry.json` into Vaultwarden once it's gitignored (the current values are in the "Casama · PostHog project key" and "Casama · Sentry DSNs" items) | Commit `telemetry.example.json`; scripts skip telemetry when the file is missing |
| `POSTHOG_CLI_API_KEY` (symbol uploads) and `POSTHOG_PERSONAL_API_KEY` (person deletion on purge) | Upload steps and person deletion skip cleanly when the key is unset; tests use fakes |
| Setting `PRODUCT_ANALYTICS=on`, `ANALYTICS_ENVIRONMENT=production`, `ERROR_REPORTING=posthog` on the VPS | Document them in `deploy/casama-cloud/README.md` |
| The Phase 1 crash drill on real phones and desktops | Run it on simulators and emulators; list what's left for real devices |
| App Store privacy labels and Play Data safety form; PostHog and Sentry DPAs; EU legal view | List the exact answers to enter |
| All of §7.3 in PostHog: dashboards, cohorts, revenue setting, cohort 603648, the `FlutterVibe/AGENTS.md` slug row | Write the definitions into `docs/ANALYTICS-PLAN.md` as an appendix, ready to create |

**Also fix during Phase 1:** bugs 1–5 in §1.3 (with tests). Flag bug 6 (`cloud.casama.ai`) in
`docs/NEEDS-FROM-OLIVER.md`.

Line numbers point at the tree on 2026-11-12. Other sessions edit the same files, so expect drift
of a few lines.

---

## 0. Summary

**Where we are.** PostHog has received 23 Casama events in 30 days, from 4 test devices. None carry
the `app` or `environment` super properties, so the shared project's default test-account filter
hides all of them. Most app screens are never reported, because the shell navigator has no screen
observer. Handled errors reach neither Sentry nor PostHog. The web app at app.casama.ai sends
nothing. The server sends no product events, and only HTTP-handler errors get reported.

**What this plan does**, in five phases (about 9–12 working days):

| Phase | What | Days |
|---|---|---|
| 0 | Hygiene: fix the leaks, make data visible, stop self-builds reporting to us | 1–1.5 |
| 1 | Crash reporting that sees every platform, handled errors and the worker | 1.5–2 |
| 2 | Identity, consent switch, event catalog, core funnels (sign-up → first value → paid) | 3–4 |
| 3 | Feature adoption, reliability, daily server rollups | 2–3 |
| 4 | Dashboards, alerts, cohorts; later flags, surveys, experiments | 1–2 + ongoing |

**The privacy line.**
- Never any content (no text, names, emails, prompts, model output, tool arguments, file names, URLs).
- Product analytics only for official builds on Casama Cloud.
- One switch for the person, plus one for the workspace admin.
- Self-hosted servers send us nothing.
- The official app on someone's self-hosted server sends crash reports and one anonymous daily ping.

**The cost line.** Casama joins a shared project that is already past PostHog's free 1M events a
month. Every event costs money: roughly $0.03–0.05 per 1,000 anonymous events and $0.10–0.25 per
1,000 for signed-in people. The design counts heavy activity with one daily rollup per person
instead of one event per message or run. Target: **at most about 160 events per active person per
month**, which is about $0.02–0.04 per monthly active user. Error tracking stays free (the project
uses 351 of the 100,000 free exceptions a month).

**Recommended crash reporter:** PostHog error tracking for official builds and Casama Cloud, so
crashes sit next to the people, releases and funnels they affect. Sentry stays fully supported for
self-hosters (D-063 unchanged) and is a one-variable fallback. Decision 1 in §12.

---

## 1. What exists today

### 1.1 App (Flutter)

| Finding | Effect | Where |
|---|---|---|
| Screen observer only on the root `GoRouter`; the `ShellRoute` has none | Every page inside the shell (bots, chats, settings, inbox, tasks…) is never reported. PostHog saw 18 `$screen` in 30 days | `client/lib/core/router.dart:139`, `:259` |
| No `app` / `environment` super properties | The shared project's default filter (`environment = production`, cohort 603648, `$host`) drops every Casama event; per-app dashboards can't select Casama | `client/lib/core/telemetry.dart:62-84` |
| `$app_name` differs: `Casama` on Android, `casama_app` on iOS | Even the `$app_name` fallback splits Casama in two | iOS `CFBundleName` |
| `personProfiles = never`; `beforeSend` wipes user properties | `identify` is ignored, so no funnels across devices or between app and server | `telemetry.dart:67`, `:72-73` |
| No custom events at all | No funnels | — |
| PostHog SDK defaults left on: `capturePushNotificationSubscriptions`, `capturePushNotificationOpened`, `surveys`, `preloadFeatureFlags` (posthog_flutter 5.60.0) | On Android the SDK fetches the **FCM token and sends it to PostHog**, which the privacy page doesn't disclose. A flag request goes out on every launch even though we use no flags | `posthog_config.dart:171,290,338,358` in the package |
| The scrubber drops any property key containing `message`, `text`, `content`, `token`, `input`, `output`, `body`, `args`, `prompt`, `email`… | Product properties such as `message_count` or `input_mode` would silently vanish | `telemetry.dart:34-36` |
| Errors: only uncaught errors are reported, and they go to Sentry (`ERROR_REPORTING=auto` picks Sentry when a DSN is set) | Handled failures never reach any tool. `runGuarded` has 240 call sites; there are 51 empty `catch (_) {}` blocks | `client/lib/core/widgets.dart:324`, `:70` |
| Store purchase stream keeps only `purchased`/`restored`; a failed server check only goes to `debugPrint` | Purchase cancels and failures can't be seen; a failed check leaves money unconfirmed with no report | `client/lib/core/billing.dart:139`, `:195-197` |
| Web: no posthog-js in `client/web/index.html`; `scripts/build-web.sh`, `client/Dockerfile.web:24` and CI pass no telemetry config | app.casama.ai sends no errors and no analytics. The Flutter PostHog web plugin expects posthog-js already in the page | `posthog_flutter_web.dart:97` in the package |
| `client/config/telemetry.json` (Sentry DSN, PostHog key) is committed to the **public** repo, and all four desktop packaging scripts always pass it | Anyone who packages the app from source reports to our Sentry and PostHog. The privacy page says self-builds send nothing | `scripts/package-macos.sh:13`, `package-macos-appstore.sh:20`, `package-linux.sh:6`, `package-windows.ps1:9` |
| No iOS or Android packaging script | Mobile store builds only get telemetry if someone remembers the flag | — |
| Native auto-init is off (`Info.plist`, manifest) | Fine; Dart `Posthog().setup` runs | `client/macos/Runner/Info.plist:71` |

### 1.2 Server

| Finding | Where |
|---|---|
| One `captureError` call in the whole server: the API's HTTP error handler | `apps/server/src/api/app.ts:139` |
| The worker never reports. Model failures are info logs, run failures only `logger.error` | `packages/agent/src/run.ts:1106`, `:1705` |
| No `unhandledRejection` / `uncaughtException` handlers (Sentry adds its own, the PostHog reporter doesn't) | `apps/server/src/main.ts:61-62` |
| `initObservability` gets no `version`, so `release` is empty and OTel says "dev" | `main.ts:44-52`; `CASAMA_VERSION` is in `apps/server/src/api/routes/admin.ts:19` |
| The supervisor has no observability package at all; computerd (Dart) and the pages origin don't report | `apps/supervisor/src/app.ts:42-53`, `dart/computerd/lib/src/server.dart:214`, `apps/server/src/pages/app.ts:21` |
| No product events (one stray `casama_setup_check` in PostHog) | — |
| Prometheus `/metrics` already exposes run counts, failure ratio, time to first token, computer start time, cost per run | `apps/server/src/api/metrics.ts` |

### 1.3 Bugs found along the way (not analytics, but should be fixed)

1. **Runs can stay non-terminal for ever.** `agentRunWorkflow` has no catch. An exception in the
   `load` step, `cloudModels()` or the `fail` step leaves the DBOS workflow in ERROR. The queued
   sweep then re-enqueues it under the same workflow id, so the run never restarts.
   `apps/server/src/worker/workflows.ts:96-112`, `:291-301`; `run.ts:374`, `:380`.
2. **Lost billable usage.** The streaming Cloud Connect usage write is
   `meter(usage).catch(() => {})`. `apps/server/src/billing/connect.ts:269` (parse errors also at
   `:240`, `:263`).
3. **Account purge swallows failures.** Computer removal and memory-backend deletes inside the purge
   ignore errors, which is a privacy-compliance risk. `apps/server/src/services/privacy.ts:169`, `:178`.
4. **About 16 tick steps fail silently**: routines, calendar, watchers, projects, iMessage,
   knowledge, git-sync, encryption, cards, audit forwarding, call expiry. Each is
   `.catch(() => 0 | [])` with no log. `workflows.ts:150-301`.
5. **Passkeys and SSO can disappear quietly.** `authMethodsProvider` falls back to defaults on any
   error, which hides them. `client/lib/core/providers.dart:18-22`.
6. **Desktop packaging scripts default to `https://cloud.casama.ai`.** That host appears nowhere in
   D-172 and didn't answer when checked on 2026-11-12. The Cloud API is `api.casama.ai`. Check this
   before the next desktop release.

### 1.4 The PostHog project (checked live, 2026-11-12)

- **Project:** shared Stackwares project 637030, paid plan, period 2026-11-06 → 12-06. Projected
  about 1.98M events (the free tier is 1M), 1.88M of them identified; projected bill $366.
- **Marginal prices where Casama lands:**
  - Events: $0.00005 each up to 2M, $0.0000343 from 2M to 15M.
  - Identified-event add-on: **+$0.000198** up to 2M, +$0.0000697 from 2M to 15M.
  - Group analytics: not subscribed; it would add $0.000071 per event.
- **Free allowances:**
  - Error tracking: 100k exceptions a month (351 used).
  - Feature flags: 1M requests (11.6k used).
  - Surveys: 1,500 responses.
  - Mobile session replay: already past its 2,500 free recordings, so each new recording costs $0.005.
- **Project settings:**
  - The default test-account filter is on: cohort 603648, `environment = production`, `$host` not local.
  - `anonymize_ips` is off (project-wide, shared).
  - No group types.
  - Exception autocapture is opted in.
- **Conventions in use:**
  - Every other app sends `app = <slug>`; their servers send `$lib = <slug>-worker`.
  - Dashboards are named `<App> — Overview`, insights `<App> · <Metric>`, everything tagged with
    the slug. The rules are in `~/Desktop/Projects/FlutterVibe/AGENTS.md` ("PostHog dashboards and
    insights").
  - There is no Casama dashboard yet.

### 1.5 What we've promised publicly (must change in step)

- **`site/privacy.html`** ("Error reports and screen analytics", processors table): official apps
  send screen names and lifecycle only; "PostHog is not used to build a profile of you"; errors go
  to Sentry.
- **`docs-site/guide/privacy.md:145-153`**: off unless whoever builds the app adds a key.
- **`client/ios/Runner/PrivacyInfo.xcprivacy`** (and the macOS copy): crash data *unlinked*; no
  product-interaction data declared.
- **App Store privacy labels and the Play Data safety form**: they must match whatever ships.
- **`docs/COSTS.md:32`** says "PostHog $0 up to 1M events / month". That's wrong for us, because the
  shared project is already past it.

---

## 2. What we want to learn

Every event in §6 exists to answer one of these. If an event answers none of them, it doesn't ship.

**Acquisition and sign-up**
1. Which sign-in methods do people start, and which fail (by platform)?
2. How many people who reach the sign-in screen end up with an account?

**Activation**
3. Where do new people drop between account and first useful result? Which Welcome-chat step loses
   them?
4. Does connecting Google (or another app) during Welcome raise first-week retention?
5. Welcome chat vs "Set up manually" vs joining a team: which path activates better?
6. How long from sign-up to first value?

**Engagement and retention**
7. Week-1 and week-4 retention, by sign-up path, platform and first-week behaviour (routines,
   connections, computer, voice).
8. Which features get adopted, and which ones predict retention?
9. How much of the bots' work is automated (routines, watchers, chat apps) vs interactive?

**Monetization**
10. Which limit sends people to the paywall, and how many buy? Web checkout vs App Store vs Play.
11. Trial → paid, cancellations, refunds.
12. Cost per active person (from `usage_ledger`) vs revenue, free vs paid. This ties into
    `docs/COSTS.md` pricing.

**Reliability**
13. Crash-free users per release and platform.
14. Run failure rate and causes, computer start success and time, connection success per app,
    sign-in failure rate.
15. Do errors cause drop-off? For example, does a failed connection during Welcome kill activation?

---

## 3. Principles

1. **Never content.**
   - Allowed: ids from our own database (uuids), public catalog ids (app ids, template ids, model
     ids, skill catalog ids), enums, counts, durations, booleans, error codes, plan codes.
   - Never: names, emails, phone numbers, message or prompt text, model output, tool arguments or
     results, file names, URLs (custom MCP server URLs included), search queries, secret names,
     calendar or health values, typed answers. A free-text answer is logged as `provided`.
   - Audit-log metadata is never forwarded as-is. Several entries carry names or titles:
     `bot.imported`, `bot.created_by_bot`, `page.made_public`, `org.settings`,
     `cloud_connect.key_created`.
2. **The server is the source of truth for outcomes.** Sign-up, workspace and bot creation, runs,
   connections, purchases, renewals and refunds are emitted by the server after the database
   commit. The app emits intent and UI only: viewed, tapped, cancelled, and failures that never
   reached the server.
3. **Casama Cloud only.**
   - Product events reach the Stackwares project only from official builds talking to Casama Cloud,
     and from the Cloud server.
   - A self-hosted server's `POSTHOG_API_KEY` is its owner's project (D-063) and sends product
     events only if that owner turns them on (`PRODUCT_ANALYTICS=on`).
   - The official app on a self-hosted server never identifies, never sends server ids, and sends
     only crash reports plus one anonymous `app_active_daily` per day.
4. **One switch**, Settings → Privacy → "Share usage data and crash reports".
   - Stored on the device and on the account, so the server honors it too.
   - Workspace admins can turn usage data off for the whole workspace.
5. **Budget first.**
   - Per-message and per-run activity is counted by one daily rollup per person and per workspace.
   - Live events are for funnel steps and rare moments.
   - Screens are reported once per screen per session.
6. **Portfolio conventions.**
   - Super properties: `app = casama`, `environment`, `platform`.
   - Core event names: `paywall_view`, `purchase_started`, `purchase_completed`,
     `restore_purchases`, `paywall_dismiss`, `onboarding_begin`, `onboarding_step_view`,
     `onboarding_complete`, `first_value`, `enable_analytics_sharing`/`disable_analytics_sharing`,
     `purchase` for revenue.
   - Dashboard naming as in §1.4.
   - Names match `^[a-z][a-z0-9_]{0,39}$`, `<area>_<action>`, and are permanent once shipped.
   - Casama can't use `core_analytics_flutter`: it's a private path dependency and Casama is open
     source. So Casama mirrors the conventions in its own `telemetry.dart`.
7. **Catalog as code.**
   - Every event and property is declared once, in one file both sides generate from.
   - Tests fail on an unknown event, an unknown property, a bad name or a forbidden key.
   - Product events pass an allowlist rather than the regex scrubber; exceptions keep the scrubber.

---

## 4. Architecture

```
 Official Flutter app                                     Casama Cloud server (api + worker)
 ┌─────────────────────────────────┐                     ┌──────────────────────────────────────┐
 │ Analytics (catalog-typed)       │                     │ ProductAnalytics (consent-aware)      │
 │  $screen  (root + shell nav,    │                     │  live events after DB commit          │
 │           once per session)     │                     │  milestones (analytics_milestones)    │
 │  intent / UI events             │──── PostHog ───────▶│  daily rollups (DBOS scheduled job)   │
 │  feature_used (once a day)      │     project 637030  │ ErrorReporter  $exception             │
 │ Telemetry  $exception (+native) │     app = casama    │  api, worker, supervisor              │
 │ consent switch ⇄ account flag   │◀───────────────────▶│ Postgres = truth (runs, usage_ledger, │
 └─────────────────────────────────┘   distinct_id =     │  subscriptions, audit_log…)           │
                                        auth user uuid   └──────────────────────────────────────┘
```

### 4.1 One catalog, generated for both sides

- `packages/contracts/analytics/catalog.json` lists each event:
  - name and description
  - emitter: `client`, `server` or `both`
  - properties with type and allowed values
  - whether it's person-processed
  - which funnels use it
- `pnpm gen` already runs the contracts generators. It would also emit:
  - `packages/contracts/src/analytics.ts`: typed `AnalyticsEvent` unions for the server.
  - `client/lib/core/analytics_events.g.dart`: one class per event for the app.
- Tests:
  - Contracts: names match the regex, keys are snake_case, no forbidden key (the scrubber's word
    list plus `name`, `title`, `url`, `phone`, `query`), every enum is closed.
  - Client and server: every `capture` call takes a catalog type, never a string.

### 4.2 App

- **`client/lib/core/telemetry.dart`** (errors and setup) changes:
  - `personProfiles = identifiedOnly`.
  - Register super properties right after setup:
    - `app=casama`
    - `environment`: `production|staging|development`, from `POSTHOG_ENVIRONMENT`, defaulting to
      production in release
    - `platform`
    - `distribution`: `app_store|google_play|mac_app_store|direct|web`, from `kDistribution` and
      `defaultStore()`
    - `server_kind`: `cloud|self_hosted|local`, see below
  - Turn off push token capture, push-open capture, surveys and flag preloading, and set the
    `com.posthog.posthog.CAPTURE_PUSH_NOTIFICATION_OPENED` Info.plist key to false.
  - Turn off lifecycle events (budget, §9). Installs come from the stores.
  - `beforeSend` changes:
    - `$exception` keeps today's scrub.
    - `$screen` passes.
    - Catalog events are checked against the allowlist.
    - Anything else is dropped (in debug builds it throws, so tests catch it).
  - Error tracking options: §8.
- **New `client/lib/core/analytics.dart`** (the product facade):
  - `capture(AnalyticsEvent)`, `identify`, `reset`.
  - `featureUsed(Feature)`: at most once per feature per day per device, guarded by a
    SharedPreferences date key.
  - `screen` dedupe: once per route template per session. A session ends after 30 minutes in the
    background.
  - Every call is a no-op when telemetry is off, the switch is off, or (for anything but the daily
    ping) `server_kind != cloud`.
- **`server_kind`.** The app has no explicit Cloud flag:
  - `cloud`: `/v1/system/config` reports `billing_enabled` **and** the API URL equals the official
    default. `billing_enabled` is set from `BILLING_ENABLED`, which only Cloud turns on
    (`apps/server/src/api/routes/system.ts:45`).
  - `local`: the desktop local server.
  - `self_hosted`: everything else.
  - The URL itself is never sent.
- **Screen observer.** Pass `observers: Telemetry.observers` to the `ShellRoute`
  (`router.dart:259`). The getter builds a fresh observer per navigator, so this is safe. Wrap
  `PosthogObserver` to apply the per-session dedupe.
- **Identity:**
  - Where: next to the existing `ref.listen(signedInProvider)` in `client/lib/app.dart:57`. Use
    `signInFinishedProvider` (`client/lib/core/providers.dart:41`), so two-step and new-password
    flows finish first.
  - `identify(user.id)` only on Cloud with the switch on.
  - `reset()` on sign-out (`settings_screen.dart:311`, `onboarding_screen.dart:177`,
    `account_screen.dart:276/286`) and on account deletion (`privacy_screen.dart:73`).
- **web:**
  - Load posthog-js from Dart before `Posthog().setup`, and only when a key is set, so self-hosters'
    `index.html` stays untouched.
  - Options: `autocapture: false`, `capture_pageview: false` (Flutter sends `$screen`),
    `disable_session_recording: true`, `persistence: 'localStorage'` (no cookies).
  - The CSP gets the PostHog script and ingestion hosts.

### 4.3 Server

- **New `packages/observability/src/analytics.ts`**, next to `ErrorReporter`:

  ```ts
  interface ProductAnalytics {
    capture(e: AnalyticsEvent & {
      distinctId: string;          // auth user uuid, or `workspace:<org uuid>` for personless
      orgId?: string;              // becomes workspace_id
      personless?: boolean;        // sets $process_person_profile: false
      uuid?: string;               // deterministic for once-only events (UUIDv5 of event+entity)
      timestamp?: Date;            // the entity's own time, so a retry dedupes
      setOnce?: Record<string, string | number | boolean>;  // first-touch person properties
    }): void;
    flush(): Promise<void>;
    close(): Promise<void>;
  }
  ```

- **Off unless `PRODUCT_ANALYTICS=on` and `POSTHOG_API_KEY` are both set.**
  - Error reporting stays on `ERROR_REPORTING` as today. Self-hosters who set a PostHog key for
    errors get no product events by accident.
  - Cloud sets `PRODUCT_ANALYTICS=on` and `ANALYTICS_ENVIRONMENT=production` (the Mac dev stack
    sets `development`).
  - The admin console's integrations list shows the state, next to error reporting
    (`admin.ts:322`).
- **posthog-node settings:**
  - One shared client (the error reporter reuses it when PostHog is the reporter).
  - `flushAt: 20`, `flushInterval: 10s`; GeoIP disabled, since the server's IP is meaningless.
  - Super properties on every event: `app=casama`, `environment`, `source=server`,
    `server_version` (from `CASAMA_VERSION`).
- **Consent.** `analyticsAllowed(userId, orgId)` reads `profiles.analytics_opt_out` and the
  workspace's `analytics` setting through a 60-second cache, the same pattern as
  `connection-settings.ts:14-40`. Rollups filter in SQL.
- **Delivery and dedupe:**
  - Once-only events (`signed_up`, `purchase`, milestones, rollups) carry a deterministic `uuid`
    plus the entity's own timestamp. A retry with the same uuid, event, distinct id and day merges
    in PostHog.
  - Live events are best-effort. Postgres stays the truth for money.
- **Milestones.** New table `analytics_milestones(user_id, milestone, reached_at, primary key
  (user_id, milestone))`:
  - Only the service role and worker can write it (RLS on, `public.allow_worker`, a pgTAP test).
  - Code calls `reachMilestone(userId, m)`: `insert … on conflict do nothing returning`, and emits
    only when a row came back.
  - Activation is then also queryable in our own database.
- **Sign-ups happen in a DB trigger** the server never sees (`handle_new_user`,
  `supabase/migrations/20261109000001_workspaces.sql:169-182`):
  - The worker tick sweeps new profiles with no `analytics_signup_sent_at`.
  - It reads the provider through a new `public.worker_*` security-definer function (the worker
    never reads `auth.*` directly, per D-095).
  - It emits `signed_up` with `timestamp = created_at`, then stamps the profile.
  - Bot archives (a direct client write, `supabase_backend.dart:795-803`) and member removals (no
    code path) are counted in rollups, not as live events.

### 4.4 Identity

- **`distinct_id`** = the Supabase auth user uuid, on both sides.
  - The SDK's anonymous id from before sign-in merges into the person on `identify`, so the funnel
    runs from the sign-in screen.
  - Never identify with an email. Never identify on a self-hosted server.
- **Automated work has no person.** Routines, watchers, triggers, chat apps, A2A and the hosted MCP
  endpoint report inside `workspace_daily`, sent personless with `distinct_id =
  workspace:<org uuid>`. Automated runs never count as a person being active.
- **Workspace.** `workspace_id` and `workspace_plan` ride on server events as plain properties.
  - PostHog group analytics is deferred: it costs $0.000071 more per event. Turn it on when team
    plans need per-workspace funnels.
  - Workspace questions meanwhile: SQL on `properties.workspace_id`.
- **Internal accounts.** The server sets the person property `is_internal` (boolean only) when the
  email domain is in `INTERNAL_EMAIL_DOMAINS`. With Oliver's OK, it gets added to test-account
  cohort 603648.

### 4.5 Properties

**Super properties (every event):**

| Property | Values |
|---|---|
| `app` | `casama` |
| `environment` | `production`, `staging`, `development` |
| `platform` | `ios`, `android`, `macos`, `windows`, `linux`, `web`, `server` |
| `distribution` | `app_store`, `google_play`, `mac_app_store`, `direct`, `web` (app only) |
| `server_kind` | `cloud`, `self_hosted`, `local` (app only) |
| `source` | `client`, `server` |

The SDK adds `$app_version`/`$app_build`; the server adds `server_version`.

**Person properties (Cloud, switch on; at most 10):**

| Property | Set by | How |
|---|---|---|
| `signup_method` | server, from the auth provider | `set_once` |
| `signup_at` | server | `set_once` |
| `signup_platform` | app, on first identify | `set_once` |
| `onboarding_path` | `welcome_chat`, `manual`, `joined_team` | `set_once` |
| `first_value_at` | server | `set_once` |
| `first_value_kind` | server | `set_once` |
| `plan` | server: highest plan across the person's workspaces | updated on change |
| `is_internal` | server | updated |
| `analytics_opt_out` | never sent (opted-out people send nothing) | — |

---

## 5. Privacy, consent and store disclosures

### 5.1 The switch

- **Default on, with notice.** This matches the other Stackwares apps.
  - Sign-in screen line: "Casama collects usage data and crash reports to improve the app. Turn it
    off in Settings → Privacy." It links to the privacy page.
  - Opt-in for the EU instead is Decision 2. It needs the legal review already in
    `NEEDS-FROM-OLIVER.md`.
- **Where:** Settings → Privacy → "Your data", after Export (`privacy_screen.dart:117`).
  - Stored in SharedPreferences under `casama.analytics_enabled`, read before `Posthog().setup`
    (no provider exists that early).
  - Flipping it calls `Posthog().disable()/enable()` live. With Sentry it closes or re-inits Sentry.
  - When signed in, it also writes `profiles.analytics_opt_out` through a small API, so the server
    stops too.
  - Logs `disable_analytics_sharing` before turning off and `enable_analytics_sharing` after turning
    on (portfolio names).
- **Workspace switch:** Settings → Workspace → Privacy (admins), "Usage data for this workspace".
  - Turns off server product events and rollups for that workspace.
  - Turns off `identify` in the app while it's the current workspace.
  - Crash reports keep working.
  - Teams and enterprise buyers ask for this.
- **Self-hosted servers:** unchanged, they send us nothing. The official app connected to one sends
  crash reports and `app_active_daily {server_kind}` only (Decision 3).

### 5.2 Erasure and access

- **Account purge** (`apps/server/src/services/privacy.ts:159-187`): also deletes the PostHog person
  and their events through the API.
  - Needs `POSTHOG_PERSONAL_API_KEY` with person write scope, Cloud `.env` only.
  - A failure is retried on the next purge run and reported (§1.3 bug 3).
- **Data export:** no change. The privacy page states that usage data is held by PostHog and
  deleted with the account.

### 5.3 IP addresses

- The shared project keeps IPs (`anonymize_ips` is project-wide).
- For Casama, add a PostHog transformation that drops `$ip` after GeoIP enrichment, filtered to
  `app = casama`. Check during Phase 0 that the transformation runs after GeoIP.
- The server already sends no client IP.

### 5.4 Session replay and surveys

- **Replay: off.**
  - Chats and bot output are on almost every screen.
  - Mobile replay is already past the free tier.
  - Revisit only for onboarding screens, fully masked and sampled.
- **Surveys:** Phase 4 at the earliest, and only if posthog_flutter renders them as native widgets
  (no WebView, per Oliver's rule). Check before turning them on.

### 5.5 Documents that change in the same commit as the code

- **`site/privacy.html`:**
  - Usage data: what, why, the switch.
  - Processors table: PostHog gets "usage events, screen names, crash reports; linked to your
    account on Casama Cloud".
  - Sentry's row changes per Decision 1.
- **`docs-site/guide/privacy.md` § Telemetry:** the same, plus `PRODUCT_ANALYTICS` for self-hosters.
- **`PrivacyInfo.xcprivacy`** (iOS and macOS):
  - Add `NSPrivacyCollectedDataTypeProductInteraction`: linked, purpose Analytics.
  - Add `NSPrivacyCollectedDataTypeUserID`: linked, Analytics.
  - Change `CrashData` to linked (identified crash reports).
  - Add `OtherDiagnosticData`: linked, App Functionality.
  - Tracking stays `false`: nothing is shared with data brokers or used across companies' apps.
- **App Store privacy labels:**
  - Usage Data → Product Interaction: linked, Analytics.
  - Identifiers → User ID: linked.
  - Diagnostics → Crash Data and Other Diagnostic Data: linked.
- **Play Data safety:**
  - App activity → App interactions.
  - App info and performance → Crash logs and Diagnostics.
  - Device or other IDs.
  - Collected, not shared; encrypted in transit; deletable.
- **`.env.example`**, `docs-site/self-hosting/configuration.md`, `infra/compose/docker-compose.yml`:
  `PRODUCT_ANALYTICS`, `ANALYTICS_ENVIRONMENT`, `POSTHOG_PERSONAL_API_KEY`.

---

## 6. Event catalog

Columns:
- **By**: `C` = app, `S` = server.
- **Hook**: where to call it.
- **Props**: on top of the super properties.
- **F#**: the funnel in §7.1 that uses the event.

`workspace_id` rides on every server event that has one.

### 6.1 Sign-in and sign-up

| Event | By | Hook | Props | F# |
|---|---|---|---|---|
| `sign_in_started` | C | `sign_in_screen.dart`: password `:183`, email code `:212`, Apple/Google `:280`, passkey `:319`, SSO `:329` | `method` (`password`, `email_code`, `apple`, `google`, `passkey`, `sso`, `desktop_browser`), `is_sign_up` (password only), `surface` (`sign_in`, `join_invite`) | F1 |
| `sign_in_failed` | C | the same handlers' error paths; invalid code `:261-264`; passkey returns false `:369` (today ignored) | `method`, `reason` (`cancelled`, `invalid_code`, `invalid_credentials`, `rate_limited`, `network`, `provider_error`, `unknown`), `error_code` | F1 |
| `sign_in_completed` | C | `onAuthStateChange` signed-in (`supabase_backend.dart:26`). Needed because Apple, Google and the desktop browser return before the result (`:154`, `:235`) | `method` (from `appMetadata.provider`), `is_new_user` (`createdAt` within 10 minutes) | F1 |
| `two_step_completed` | C | `two_step_screen.dart:317` | `factor` | F1 |
| `signed_up` | S | worker sweep of new profiles (§4.3); deterministic uuid | `method`; `set_once` `signup_method`, `signup_at` | F1 F2 |
| `signup_blocked` | S | `apps/server/src/api/routes/abuse.ts:95-108`; personless | `reason` (`missing_proof`, `pow_*`, `app_check_*`) | F1 |
| `signed_out` | C | settings `:311`, onboarding `:177`, account `:276/286`; then `reset()` | `scope` (`this_device`, `everywhere`) | — |
| `account_deletion_requested` | S | `apps/server/src/api/routes/privacy.ts:51-65` | `owned_workspaces` | — |

### 6.2 Onboarding (Welcome chat, manual set-up, joining)

The Welcome chat is scripted by the server: steps `name → google → focus → scope → model → connect →
phone → invite → first_value → offer_setup → interview → learned → done`
(`packages/agent/src/welcome.ts:40-53`). So the server emits step events when it posts each card.

| Event | By | Hook | Props | F# |
|---|---|---|---|---|
| `onboarding_begin` | S/C | S: `startWelcome` success (`apps/server/src/api/routes/bots.ts:689-777`). C: "Set up manually" (`welcome_screen.dart:98`) and the join-team screen (`join_flow.dart:467`) | `path` (`welcome_chat`, `manual`, `joined_team`) | F2 |
| `onboarding_step_view` | S | `welcome.ts`, when each step's card is posted | `step` (the ids above), `step_index` | F2 |
| `onboarding_step_done` | S | `welcome.ts:819-1016` card actions: `welcome.name/connected/nogoogle/focus/scope/next/nocatchup/catchup/task/setup/later/learned` | `step`, `action` (`connected`, `skipped`, `picked`, `later`, `catchup`, `task`, `setup`), `choice` (stable option id; never `ctx.text`, which holds typed text) | F2 |
| `onboarding_step_done` | C | name overlay `name_step.dart:78` (saved `:86` / skipped `:88`); manual wizard steps `onboarding_screen.dart:86/121/141/159` | `step` (`name_overlay`, `manual_workspace`, `manual_join_code`, `manual_key`, `manual_bot`), `action` | F2 |
| `onboarding_complete` | S/C | S: Welcome reaches `done`. C: manual wizard creates the bot (`onboarding_screen.dart:159`) | `path`, `duration_s`, `steps_skipped` | F2 |
| `first_value` | S | milestone (§6.12): first completed run with a reply on the person's own bot, in `setTerminal` (`run.ts:2398-2441`) | `kind` (`welcome_catchup`, `welcome_task`, `chat`, `routine`, `voice`), `minutes_since_signup`; `set_once` `first_value_at`/`_kind` | F2 F3 |

### 6.3 Workspace and team

| Event | By | Hook | Props | F# |
|---|---|---|---|---|
| `workspace_created` | S | `apps/server/src/api/routes/workspaces.ts:82-113`; Welcome path `bots.ts:728-743` | `source` (`welcome`, `manual`, `spaces`), `plan` | — |
| `invite_created` | S | `createEmailInvite` (`apps/server/src/api/routes/joining.ts:870-895`; bulk `:621`); links/codes `joining.ts:245`, `:340`, `workspaces.ts:197` | `channel` (`email`, `link`, `code`, `standing_link`), `count`, `role`, `requires_approval` | F7 |
| `invite_shared` | C | `join_flow.dart:759/818/829` | `method` (`qr`, `copy`, `share`) | F7 |
| `join_completed` | C | `JoinScreen._join` (`join_flow.dart:141-163`); domain join `:547` | `status` (`joined`, `member`, `requested`), `via` (`link`, `code`, `domain`, `email`) | F7 |
| `member_joined` | S | `joining.ts:462`, `:506`, `:760`; approvals `:573`; legacy `workspaces.ts:233`, `:279` | `via`, `role`, `approved` | F7 |
| `join_request_decided` | S | `joining.ts:573/575` | `decision` | F7 |

### 6.4 Bots, chats and runs

Messages, runs, tool calls and approvals are counted in `usage_daily` and `workspace_daily`
(§6.12), not one event each.

| Event | By | Hook | Props | F# |
|---|---|---|---|---|
| `bot_created` | S | API `bots.ts:239-291` (after the audit at `:282`); Welcome `welcome.ts:1147-1176`; share-link import `bot-template.ts:165-247`; agent import `agent-import.ts:45`; by a bot `packages/agent/src/tools/bots.ts:119` | `source` (`manual`, `template`, `welcome`, `share_link`, `agent_import`, `bot`), `template_id` (catalog only), `autonomy`, `model_provider` | F3 |
| `bot_shared` | S | `bot-template.ts:119-148`; access change `bot-sharing.ts:90` | `kind` (`template_link`, `export`, `access`), `include_memories` | F7 |
| `run_refused` | S | admission refusals (`run.ts:472-476`), **interactive runs only** | `reason` (`no_model_configured`, `out_of_credits`, `quota_exceeded`, `daily_budget_exceeded`, `cloud_daily_cap`, `workspace_suspended`, …) | F6 |

### 6.5 Connections

| Event | By | Hook | Props | F# |
|---|---|---|---|---|
| `connection_started` | C | `connect_app_sheet.dart:81` | `app_id`, `app_category`, `method` (`oauth`, `managed`, `api_key`, `none`), `reconnect`, `surface` (`catalog`, `detail`, `welcome`, `chat_tile`) | F4 |
| `connection_added` | S | `saveConnection` (`apps/server/src/api/routes/apps.ts:179-233`) and the OAuth callback success (`:573-590`) | `app_id`, `method`, `provider` (`direct`, `composio`, `pipedream`, `mcp`), `reconnect` | F4 |
| `connection_failed` | C/S | C: `connect_app_sheet.dart:113/114/140/141`, sheet closed while waiting `:71-75`. S: OAuth callback cancelled/failed `apps.ts:549-553/591-594`, start failure `:461-471` | `app_id`, `method`, `reason` (`cancelled`, `oauth_error`, `invalid_key`, `expired`, `needs_setup`, `exception`), `error_code` | F4 |
| `connection_removed` | S | `apps.ts:623-632` | `app_id` | — |
| `model_key_added` | S | `bots.ts:869` | `provider` | — |
| `chatgpt_plan_connected` | S | `apps/server/src/api/routes/chatgpt.ts:233-290`; failure `:224-232` | `status` (`ok`, `plan_usage_off`, `failed`), `reconnect` | — |

Managed Composio connections finish on a static page the server never hears from
(`apps.ts:697`). Their `connection_added` comes from the next integration refresh, which sets
`ok`.

### 6.6 Computers, companion, devices

| Event | By | Hook | Props | F# |
|---|---|---|---|---|
| `computer_start_requested` | S | `ensureRunning` (`packages/agent/src/computers.ts:211-245`) | `kind` (`headless`, `desktop`), `mode` (`provision`, `restore`), `trigger` (`user`, `run`) | F5 |
| `computer_ready` | S | `setState` → `running` (`computers.ts:154-166`) | `kind`, `provider`, `start_ms`, `warm` | F5 |
| `computer_start_failed` | S | `ensureRunning` error (`:238-242`); refused `checkCanStart` `:251-272` | `kind`, `reason` | F5 |
| `live_view_failed` | C | `live_view_screen.dart:214` | `fallback` (`screenshot`) | F5 |
| `companion_paired` | C | `companion_screen.dart:62` | `os`, `capabilities` (count) | — |
| `device_data_toggled` | C | `device_connections_screen.dart:59` | `kind`, `result` (`granted`, `denied`, `needs_encryption`) | — |

### 6.7 Voice

| Event | By | Hook | Props | F# |
|---|---|---|---|---|
| `call_started` | C | `CallScreen._connect` (`call_screen.dart:222`, connected `:276`, failed `:278`) | `provider` (`gemini`, `openai`), `kind` (`in_app`, `incoming`, `takeover`), `result` (`connected`, `failed`), `error_code` | F8 |
| `call_ended` | S | `saveVoiceTranscript` (`apps/server/src/api/routes/voice.ts:268-306`) | `provider`, `duration_s`, `billable` | F8 |
| `bot_call_answered` | C | incoming bot calls `phone_calls.dart:157/170` | `answer` (`accepted`, `declined`) | F8 |

### 6.8 Monetization

These follow the portfolio contract.

| Event | By | Hook | Props | F# |
|---|---|---|---|---|
| `limit_reached` | S | `enforceLimit` 402 (`apps/server/src/billing/limits.ts:21-33`; callers `bots.ts:247`, `bot-template.ts:186`, `computers.ts:326`); out of credits at run admission (`run.ts:1399-1474`), computer start (`computers.ts:271`), live call (`voice.ts:140-148`) | `kind` (`max_bots`, `max_computers`, `out_of_credits`, `quota_exceeded`, `daily_budget_exceeded`, `computer_hours_exceeded`), `surface` (`bot`, `run`, `computer`, `call`), `plan` | F6 |
| `paywall_view` | C | `showPaywall` (`billing_screen.dart:55`); called from `runGuarded` 402 (`widgets.dart:333`) and dictation (`chat_screen.dart:488`); the billing screen itself | `source` (`credits_depleted`, `feature_gate`, `settings`, `dictation`, `onboarding`, `deep_link`), `placement`, `paywall_kind` (`regular`), `platform` | F6 |
| `paywall_plan_selected` | C | plan tap on the billing screen (`:177`) | `product_id`, `interval` | F6 |
| `purchase_started` | C | `_webCheckout` `:94`, `_storeBuy` `:99`, credit packs `:237/:252` | `product_id`, `store` (`dodo`, `app_store`, `google_play`), `kind` (`subscription`, `credit_pack`) | F6 |
| `purchase_completed` | C | store purchase stream (`billing.dart:138-139`, **changed to pass cancelled, error and pending through**); verify result `:189-197` | `outcome` (`purchased`, `pending`, `cancelled`, `failed`), `store`, `product_id`, `value`, `currency` | F6 |
| `restore_purchases` | C | `:101` | `outcome` (`restored`, `none`, `failed`) | — |
| `paywall_dismiss` | C | paywall closed without buying | `source` | F6 |
| `checkout_created` | S | `apps/server/src/billing/service.ts:342-370` (Dodo) | `product_id`, `kind` | F6 |
| `purchase` | S | **revenue truth.** `applySnapshot` on a new paid period (`service.ts:140-172`), `applyPayment` for packs (`:174-182`) | `value`, `currency`, `product_id`, `store`, `kind` (`new`, `renewal`, `upgrade`, `credit_pack`), `plan`, `interval`; deterministic uuid per provider transaction | F6 |
| `subscription_changed` | S | `applySnapshot`; read the old status and plan before the upsert (`:141-142` selects only `org_id` today) | `from_status`, `to_status`, `store`, `plan`, `change` (`trial_converted`, `cancelled`, `expired`, `refunded`, `grace`, `recovered`, `upgraded`, `downgraded`) | F6 |
| `refund_issued` | S | `service.ts:184-194` | `value`, `currency`, `store` | — |

- PostHog revenue analytics is pointed at `purchase.value` (a project setting, written only with
  Oliver's OK).
- `purchase_completed` stays without `$revenue`, as the portfolio rules say, so revenue isn't
  counted twice.

### 6.9 Automation and content (creation only; usage goes in rollups)

| Event | By | Hook | Props |
|---|---|---|---|
| `routine_created` | S | `apps/server/src/api/routes/autonomy.ts:664` | `trigger_kind` (`schedule`, `webhook`, `calendar`, `device`, `checkin`) |
| `watcher_created` | S | `packages/agent/src/watchers.ts` create path | `kind` |
| `action_rule_created` | S | `apps/server/src/api/routes/action-rules.ts:36` | `decision` |
| `skill_installed` | S/C | catalog `skill_catalog_screen.dart:223`; GitHub `skill_library.dart:86`; proposals `skill_proposals.dart:114`; gallery `gallery_screen.dart:1132` | `source` (`catalog`, `github`, `proposal`, `gallery`, `manual`), `skill_id` (catalog only) |
| `page_published` | S | `packages/agent/src/pages.ts:84`; made public `apps/server/src/api/routes/pages.ts:100-113` | `visibility` |
| `chat_app_connected` | S | channel setup in `apps/server/src/api/routes/channels.ts` | `channel` (`telegram`, `slack`, …) |

### 6.10 Notifications, app health, consent

| Event | By | Hook | Props |
|---|---|---|---|
| `push_permission_result` | C | `push.dart:168/191/193/201` (`app.dart:115` passes only a callback, so log inside `push.dart`) | `result` (`granted`, `denied`, `snoozed`, `web_blocked`), `surface` (`onboarding`, `settings`) |
| `push_opened` | C | `push.dart:229` | `kind` (`approval`, `run`, `call`, `checkin`, `mention`, `other`) |
| `app_startup_failed` | C | `main.dart:151` "cannot reach server" | `reason`, `server_kind` |
| `app_active_daily` | C | first foreground of the day, **only** when `server_kind != cloud` (Decision 3) | `server_kind` |
| `app_error_shown` | C | `showError` (`widgets.dart:70`) and the screens that skip `runGuarded` (§8.2); once per (code, screen) per session | `error_code` (problem code), `http_status`, `kind` (`network`, `server`, `auth`, `validation`, `unknown`), `screen` (route template) |
| `feature_used` | C | `Analytics.featureUsed`, once a day per feature | `feature`, from the closed list below |
| `enable_analytics_sharing` / `disable_analytics_sharing` | C | the switch (§5.1) | — |

**`feature_used` features** (each once a day per device):

| Area | Features |
|---|---|
| Voice and input | `dictation`, `read_aloud`, `voice_call`, `wake_word` |
| Chat | `quick_ask`, `edit_resend`, `branch_switch`, `search` |
| Content and work | `pages`, `routines_run_now`, `projects`, `tasks_board`, `inbox`, `for_you` |
| Computer | `computer_live`, `computer_take_control`, `teach` |
| Customize and share | `gallery_look`, `share_template`, `group_chat` |
| Platform | `desktop_hotkey`, `share_extension`, `mac_menu` |

### 6.11 Daily rollups (server)

One DBOS scheduled workflow at 00:20 UTC builds yesterday's numbers from Postgres:
- `runs`: one terminal row per run, written by `setTerminal`, with tokens, cost and duration.
- `usage_ledger`, `approvals`, `messages`, `computers`, `voice_calls`, `channel_events`.

Each event has a deterministic uuid, `rollup:<kind>:<id>:<date>`, and a timestamp at the end of
that day. Opted-out people and workspaces are skipped in SQL.

| Event | Distinct id | Sent when | Props (all numbers) |
|---|---|---|---|
| `usage_daily` | person (identified) | they sent a message, started a run, decided an approval or made a call that day | `messages_sent`, `runs_started`, `runs_completed`, `runs_failed`, `runs_cancelled`, `tool_calls`, `approvals_approved`, `approvals_denied`, `approval_wait_p50_s`, `voice_seconds`, `dictation_seconds`, `credits_used`, `cost_usd`, `bots_used`, `chats_active` |
| `workspace_daily` | `workspace:<org>` (personless) | the workspace had any run | `runs_by_trigger_*` (`chat`, `routine`, `webhook`, `calendar`, `device`, `watcher`, `channel`, `a2a`, `link`, `project`, `task`, `subagent`, `voice`), `runs_failed_by_reason_*` (`model`, `tool`, `limit`, `timeout`, `stuck`, `other`), `computer_seconds`, `computer_starts`, `computer_start_failures`, `cost_usd`, `members_active`, `bots_active`, `bots_archived`, `members_left`, `plan` |

The server's catalog allowlist replaces the regex scrubber, so keys such as `messages_sent` are
safe on the server.

### 6.12 Milestones (server, once per person)

- `milestone_reached` with `milestone` set to one of: `first_bot_created`, `first_message`,
  `first_run_completed`, `first_connection`, `first_routine`, `first_computer`, `first_invite`,
  `first_teammate_joined`, `first_approval`, `first_voice_call`, `first_purchase`.
- Props: `minutes_since_signup`; `set_once` person property `<milestone>_at`.
- `first_value` (§6.2) is the activation milestone and keeps its portfolio name.
- One event name with a property keeps the event list short. PostHog funnels can filter each step
  by property.

### 6.13 What we deliberately don't track

- **Per-event activity:** individual messages, runs, tool calls, approvals and routine runs. The
  rollups count them.
- **Any text:** message text, prompts, replies, tool arguments, search queries, typed onboarding
  answers, names, emails, URLs, file names.
- **Health, calendar, contacts and location values.**
- **Automatically captured noise:** lifecycle events, autocapture, rage clicks, push tokens, IPs
  (§5.3), and session replay.
- **Anything from a self-hosted server.** Anything about other people in a workspace beyond counts.

---

## 7. Funnels, metrics and dashboards

### 7.1 Funnels

All insights filter `app = casama` at the insight level and use the test-account filter, as the
dashboard convention requires.

| # | Funnel | Steps | Window | Break down by |
|---|---|---|---|---|
| F1 | Sign-up | `$screen` `/sign-in` → `sign_in_started` → `sign_in_completed` (`is_new_user`) → `signed_up` | 1 h | `method`, `platform` |
| F2 | Activation | `signed_up` → `onboarding_begin` → `onboarding_step_view` (one step per Welcome step) → `first_value` → `onboarding_complete` | 1 day, and 7 days | `path`, `platform`, `onboarding_step_done.action` at `google`, `choice` at `focus` |
| F3 | First-week habit | `first_value` → `usage_daily` on 3 different days within 7 (stickiness) | 7 days | `onboarding_path`, first connection, first routine |
| F4 | Connect an app | `connection_started` → `connection_added` | 15 min | `app_id`, `method`, `surface`; failures by `reason` |
| F5 | Computer start | `computer_start_requested` → `computer_ready` | 3 min | `kind`, `mode`, `warm`; p50/p95 `start_ms` |
| F6 | Paid conversion | `limit_reached` or `paywall_view` → `paywall_plan_selected` → `purchase_started` → `purchase` | 1 day | `store`, `source`, `platform`, `plan` |
| F7 | Team growth | `invite_created` → `$screen` `/join/:token` → `join_completed` → `member_joined` | 7 days | `channel`, `via` |
| F8 | Voice | `call_started` (`result=connected`) → `call_ended` with `duration_s ≥ 30` | 1 h | `provider`, `kind` |

**Plus the four standard portfolio insights:**
- `Casama · Drop-off: onboarding steps` (`onboarding_step_view` by `step_index`).
- `Casama · Drop-off: onboarding → paywall → purchase`.
- `Casama · Drop-off: first value` (`signed_up` → `first_value`).
- `Casama · Drop-off: week-1 retention`.

### 7.2 Metrics

| Metric | Definition | Notes |
|---|---|---|
| **Activation rate** | Share of `signed_up` people with `first_value` within 24 h | Measure two weeks of baseline before setting a target |
| **North star (proposed)**: weekly active doers | People with ≥1 completed run on ≥2 different days in the week (`usage_daily.runs_completed`), counting runs of their own bots | Decision 5; it rewards real, repeated work over opens |
| Retention | Week-1 and week-4 return on `usage_daily` (did something) and on `$screen` (opened) | Cohorts by `onboarding_path`, `signup_platform` |
| Stickiness | DAU/MAU on `usage_daily` | — |
| Feature adoption | Weekly unique people per `feature_used.feature` ÷ weekly active people | Plus milestone reach rates |
| Automation share | Non-chat runs ÷ all runs (`workspace_daily`) | Q9 in §2 |
| Crash-free users | 1 − people with a fatal or unhandled `$exception` ÷ people with any `$screen`, per day, release and platform | Aim for ≥99.5% before the store launch |
| Reliability | Run failure rate by reason; computer start success and p95; connection success by `app_id`; sign-in failure rate by method; `app_startup_failed` rate | Prometheus `/metrics` keeps the operational, minute-level view |
| Paid conversion | Funnel F6; trial → paid (`subscription_changed.change = trial_converted`); refunds | The billing tables stay the money truth |
| Unit economics | `usage_daily.cost_usd` per active person per week, free vs paid, against revenue | Feeds `docs/COSTS.md` pricing |
| Event budget | Events per active person per month | Alert above 250 (§9) |

### 7.3 Dashboards

Writing to the shared project needs Oliver's OK (Decision 7).

| Dashboard | Contents |
|---|---|
| `Casama — Overview` (pinned) | The four standard insights, weekly active doers, activation rate, crash-free users, purchases and revenue, events per active person |
| `Casama — Activation & onboarding` | F1, F2, F3; Welcome step drop-off; path comparison; time to first value |
| `Casama — Monetization` | F6; `limit_reached` by kind; store mix; trial conversion; refunds; cost vs revenue |
| `Casama — Reliability` | Crash-free users; top error issues; run failures by reason; F4 and F5 failures; sign-in failures; `app_error_shown` by code and screen |
| `Casama — Features & retention` | Adoption per feature, milestone reach, retention cohorts, automation share |

- Every dashboard and insight is tagged `casama`.
- Every insight gets a description of about 15 words.
- Add the row `Casama | casama` to the slug table in `FlutterVibe/AGENTS.md`.

**Cohorts:**
- Activated (`first_value`).
- Paying (`plan` not `free`).
- Internal (`is_internal`).
- Weekly active doers, 3 weeks or more.
- Connected Google during Welcome.

**Actions:**
- `Casama: Meaningful activity`: `usage_daily` or `milestone_reached`.
- `Casama: Purchase`: server `purchase`.

**Alerts** (PostHog insight alerts):
- Activation rate falls by more than 30% week on week.
- Daily `sign_in_failed` more than doubles.
- F4 failure rate above 25%.
- Crash-free users below 99%.
- Events per active person above 250.

---

## 8. Crash reporting and error tracking

### 8.1 Recommendation (Decision 1)

**Use PostHog error tracking for official builds and Casama Cloud.** Set `ERROR_REPORTING=posthog`
in the official app config and in Cloud's `.env`. Keep D-063's Sentry path for self-hosters.

**Why PostHog:**
- Errors join the same people, releases and funnels, so "do errors cause drop-off" (Q15) becomes
  one query.
- Free at our volume (351 of 100k exceptions used).
- Error tracking alerts, issue assignment and code context are built in.
- The other Stackwares apps already work this way.
- posthog_flutter 5.60 covers:
  - Dart errors on all six platforms (Windows and Linux use its pure-Dart client).
  - Native crashes on Android: Java/Kotlin, plus NDK on API 31+.
  - Native crashes on Apple: Mach exceptions, signals and NSExceptions, marked "experimental".

**What we give up vs Sentry:**
- Native crashes on Windows and Linux (Sentry uses sentry-native there).
- Release health out of the box. We replace it with the crash-free-users insight (§7.2).
- Sentry's mature app-hang and ANR detection. PostHog support for these needs checking during
  Phase 1.
- Sentry Team's $26 a month (§9) would no longer be needed.

**How we limit the risk:**
- Phase 1 runs a crash drill: a forced Dart error, a native crash and a handled error on each
  platform. Sentry's DSN stays in Vaultwarden until it passes.
- Falling back is one variable (`ERROR_REPORTING=sentry`). No code change.
- If Oliver prefers Sentry, everything else in this plan still holds. PostHog then only gets
  `app_error_shown` and the crash-free metric moves to Sentry release health.

### 8.2 App

- **`errorTrackingConfig`:**
  - `captureFlutterErrors`, `capturePlatformDispatcherErrors`, `captureIsolateErrors`.
  - `captureNativeExceptions` (Android and Apple), `captureNativeCrashes` (Android NDK).
  - `inAppIncludes = ['casama_app']`.
  - `exceptionSteps` on, with step text scrubbed.
- **Order of setup:** the handlers in `main.dart:86` are installed before `Posthog().setup`.
  PostHog chains to them, and the reverse order silently drops `$exception` events.
- **Handled errors** (`runGuarded`, `widgets.dart:324`, and `showError`, `:70`):
  - Always log `app_error_shown`.
  - Also capture a `$exception` at level `warning`, but only for unexpected errors: anything that
    isn't a `DioException` with a server problem code, a 401/402/403/404/409/422, or a connectivity
    failure.
- **Screens that bypass `runGuarded`** get the same two calls:
  - `welcome_screen.dart:70`, `run_routine_screen.dart:36`, `call_screen.dart:278`
  - `live_view_screen.dart:214`, `connect_app_sheet.dart:114`, `search_view.dart:93`
  - dictation in `chat_screen.dart:467-526`, startup in `main.dart:150`
  - `device_connections_screen.dart:48`
- **Silent catches that start reporting** (warning level, rate-limited):
  - `billing.dart:139/195-197`: the money path.
  - `main.dart:79`.
  - `push.dart:154/181/194/223`.
  - `updater.dart:48`.
  - `supabase_backend.dart:1361`, `:2913`.
  - `providers.dart:18-22`, `:96/197/201`.
  - `live.dart:212/243/256`, `gemini_live.dart:405`.
  - The desktop `LocalServerManager` failures (`local_server.dart:133-173`).
- **Releases:**
  - PostHog adds `$app_version` and `$app_build`.
  - We register `release = casama@<version>+<build>`, so client and server use one format.
- **Rate cap:** at most 20 exceptions a minute per process, and the same fingerprint at most once
  every 5 minutes, so an offline reconnect loop can't burn the quota.
- **Web:**
  - posthog-js `capture_exceptions` through the Flutter config.
  - The release build is dart2wasm. Whether PostHog can symbolicate wasm frames is unverified; the
    dart2js fallback build hits an open PostHog issue
    ([#76722](https://github.com/PostHog/posthog/issues/76722)).
  - Expect function names only on web until checked in Phase 1.

### 8.3 Server, worker, supervisor

Every capture carries:
- `service` (`casama-api`, `casama-worker`, `casama-supervisor`), `release`, `environment`
- `workspace_id`, `run_id`, `trace_id` (the run uuid without dashes, D-107), `step`

On Cloud with the person's switch on, `distinct_id` is that person, so "affected users" counts work.
Otherwise it stays `service:<name>`, personless. Nothing else from the request is sent (D-063
scrubbing stays).

| Fix | Where |
|---|---|
| Process handlers `unhandledRejection`/`uncaughtException` → capture, flush, then exit with code 1 | `apps/server/src/main.ts` |
| Pass `version: CASAMA_VERSION` to `initObservability` (move the constant from `admin.ts:19` into a shared module) | `main.ts:44-52` |
| Catch in `agentRunWorkflow`: mark the run failed (`run_error`), capture, never leave it non-terminal; add a test | `workflows.ts:96-112` (§1.3 bug 1) |
| Capture the catch-all run failure and model-attempt failures after failover is exhausted (info logs stay for single attempts) | `run.ts:1102-1126`, `:1687-1714` |
| Tick steps: replace each silent `.catch(() => 0)` with `.catch(captureStep('<name>'))`, which logs, captures and returns the old fallback | `workflows.ts:150-301`, `:308`, `:664-672`, `:692`, `:701-704`, `:715` |
| Capture lost usage meters and Dodo usage-report failures (these lose money) | `apps/server/src/billing/connect.ts:240/263/269`, `service.ts:443-445` |
| Purge failures: capture and retry (privacy) | `apps/server/src/services/privacy.ts:169`, `:178` |
| Computers: idle-sleep failures, live-view start and upstream errors | `computers.ts:335`, `apps/server/src/api/routes/live.ts:160/380/387` |
| Side-steps that only warn → warning-level captures, deduped per step and workspace per hour | `run.ts:~1005-1036`, `:2626-2633`, `:1628`; `packages/agent/src/notifications.ts:164/219` |
| OAuth, ChatGPT and invite-email failures | `apps.ts:463/592`, `chatgpt.ts:225`, `joining.ts:~865` |
| A2A internal errors | `apps/server/src/api/routes/a2a.ts:340` |
| Pages origin `onError` | `apps/server/src/pages/app.ts:21` |
| Supervisor: add `@casama/observability`, init it, capture in `app.onError` and the warm-pool failure | `apps/supervisor/src/app.ts:42-53`, `main.ts:221` |
| computerd: log the catch-all to stdout. **Don't** send telemetry from inside a person's computer; the supervisor reports what computerd returns | `dart/computerd/lib/src/server.dart:214`, `:735-736` |

DBOS retries steps, so a step's error is captured only when it fails for the last time. That keeps
retry storms out of the quota.

### 8.4 Symbols

Casama is open source, so obfuscation buys nothing. Release builds **don't** use `--obfuscate` or
`--split-debug-info`, which keeps Dart stack traces readable with no upload. Native frames still
need symbols:

| Platform | What | How |
|---|---|---|
| iOS, macOS | dSYMs | `upload-symbols.sh` Xcode build phase in Release (`ENABLE_USER_SCRIPT_SANDBOXING=No`) |
| Android | R8 mappings and NDK `.so` symbols | PostHog Gradle plugin `com.posthog.android` (Flutter release builds shrink with R8 by default) |
| Web | source maps for the dart2js fallback | `flutter build web --source-maps` in `scripts/build-web.sh`, then `posthog-cli sourcemap inject/upload` |
| Server | — | Node stack traces are readable as-is |

The CI key is `POSTHOG_CLI_API_KEY`: a personal API key with error-tracking write and organization
read scopes, kept in Vaultwarden next to the other Casama keys.

### 8.5 Noise and alerts

- **Grouping rules:** connectivity errors (`SocketException`, `DioExceptionType.connectionError`,
  timeouts while offline) group into one issue per platform.
- **Suppression rules,** only for proven noise, each confirmed first: for example
  `HandshakeException` while offline.
- **Error tracking alerts:**
  - New issue in `environment = production`.
  - A resolved issue that reopens (a regression).
  - A spike.
- Alerts go to Oliver's email or a Slack or Discord webhook (Decision 8).
- Daily triage can run through the PostHog MCP (`triaging-error-issues`).

---

## 9. Cost and event budget

Rates are from the shared project's current billing period (checked 2026-11-12). Casama's events
land on top of about 2M events already projected this month, so its marginal price sits between two
bands.

| Item | Marginal price for Casama | Notes |
|---|---|---|
| Anonymous event | $0.034–0.05 per 1,000 | Personless rollups, self-hosted pings, screens if made personless (below) |
| Identified event | $0.10–0.25 per 1,000 | The event plus the identified-event add-on |
| Exception | $0 (100k a month free, 351 used) | $0.37 per 1,000 above the free tier |
| Feature flag request | $0 (1M free, 11.6k used) | Flag preload stays off until we use flags |
| Survey response | $0 (1,500 free) | — |
| Session replay | not used | Mobile replay is already past its free tier |

**Budget per active Cloud person per month:** about 160 events.

| Source | Events | Identified? |
|---|---|---|
| `$screen`, once per screen per session | ~90 | yes |
| App product events and `feature_used` | ~30 | yes |
| Server live events and milestones | ~10 | yes |
| `usage_daily` | ~15 | yes |
| `workspace_daily` share | ~15 | no |

**What that costs:**

| Monthly active people | Events a month | Cost a month |
|---|---|---|
| 1,000 | ~160k | **about $20–40** |
| 10,000 | ~1.6M | **about $150–250** (lower bands) |

**Cost levers,** already in the plan:
- Lifecycle events off: about 10 a day per active device.
- Screen dedupe per session.
- Rollups instead of per-message or per-run events.
- Flag preload off.

**One lever to check in Phase 0:**
- Sending `$screen` and `feature_used` personless (`$process_person_profile: false`) would bill
  them at the anonymous rate and roughly halve the total.
- Whether personless events from an identified distinct id still join that person in funnels and
  retention isn't documented clearly.
- Test it with one internal account before relying on it.

**Billing limits:** PostHog billing limits are organization-wide and would cut off every Stackwares
app. Don't set one for Casama. Watch the "events per active person" insight and its alert instead.

**Update in `docs/COSTS.md`:**
- Replace the PostHog row: "Shared Stackwares project, already past the free 1M events. Casama adds
  about $0.02–0.04 per monthly active person; error tracking free to 100k exceptions a month (shared)."
- Drop Sentry Team ($26 a month) from the fixed floor if Decision 1 is PostHog. Keep the free
  Sentry plan as a fallback.

---

## 10. Testing and verification

**App:**
- A `FakeAnalytics` sink for widget tests. Builds without a key stay silent, as today.
- Tests:
  - Every route reports a screen through *both* navigators: extend
    `client/test/screen_names_test.dart` to assert observer calls, not just page names.
  - Catalog validation.
  - The scrubber keeps `$exception` clean (extend `client/test/telemetry_test.dart`).
  - The switch stops capture live.
  - `identify` only when `server_kind = cloud`.
  - The push token setting stays off.

**Server:**
- `ProductAnalytics` null implementation in tests. A recording fake for:
  - each live event's props
  - consent filtering
  - deterministic uuids
  - milestone once-only
  - rollup sums matching direct SQL on a fixture day
- pgTAP: RLS on `analytics_milestones` and the new profile columns.
- `packages/observability/test/errors.test.ts` gains process-handler and context tests.

**Contracts:** catalog lint (names, keys, forbidden words, closed enums).

**End to end, before each phase ships:**
- Run the journey on staging builds with `environment = staging`.
- Watch PostHog live events.
- Check one person's timeline runs from the anonymous sign-in screen through `signed_up`,
  `first_value` and a sandbox `purchase`.
- Phase 1 also runs the crash drill on Android, iOS, macOS, Windows, Linux and web.

**Data checks after launch:**
- Once a week for the first month, compare PostHog counts with Postgres:
  - `signed_up` vs new profiles.
  - `purchase` vs billing events.
  - `usage_daily.runs_completed` vs `runs`.
- A drift above 2% means a broken hook.

---

## 11. Rollout

Each phase is one or more small commits, staged by path, with the full suites and Android and iOS
build checks before pushing (as usual).

### Phase 0: hygiene and visibility (1–1.5 days)

1. **Super properties:** `app`, `environment`, `platform`, `distribution`, `server_kind`. Set iOS
   `CFBundleName` to Casama, so `$app_name` matches Android (check the home-screen label is
   unchanged).
2. **Screens:** observer on the `ShellRoute`, plus the per-session dedupe.
3. **SDK defaults:**
   - Turn off push subscription and open capture (plus the Info.plist key), surveys, flag preload
     and lifecycle events.
   - Split the scrubber: allowlist for product events, the regex scrub for `$exception`.
4. **Official builds only:**
   - Gitignore `client/config/telemetry.json` and commit `telemetry.example.json`.
   - Official builds fetch the real file from Vaultwarden.
   - Packaging scripts pass it only when it exists and `CASAMA_OFFICIAL_BUILD=1`.
   - Add `scripts/package-ios.sh` and `scripts/package-android.sh`.
   - The app.casama.ai deploy runs `build-web.sh` with the file.
   - The keys stay in git history. They're write-only by design. Rotating the Sentry `casama-app`
     DSN is optional. **Don't** rotate the PostHog token: every Stackwares app shares it.
5. **Web:** load posthog-js from Dart when a key is set; update the CSP.
6. **Server:**
   - Pass `version` to `initObservability`.
   - Add `ANALYTICS_ENVIRONMENT` and `PRODUCT_ANALYTICS` (still off), documented in
     `.env.example` and compose.
7. **Costs:** fix the PostHog row in `docs/COSTS.md`.
8. **Personless check:** the `$process_person_profile` test (§9).

Done when PostHog live events show `app = casama`, `environment = production` events from Android,
iOS, macOS and web release builds for every screen. There's no push token property, and a build
without the telemetry file sends nothing.

### Phase 1: crash reporting (1.5–2 days)

1. Decision 1 applied: client config and Cloud `.env`.
2. App error-tracking options, handled errors, the silent-catch list, releases, rate cap (§8.2).
3. Server, worker and supervisor fixes, including the stuck-run bug (§8.3).
4. Symbol uploads: dSYM build phase, Gradle plugin, web source maps (§8.4).
5. Crash drill on all six platforms. Then the crash-free-users insight and the error alerts.
6. Privacy page and Apple privacy manifest: crash data linked.

Done when a forced crash on each platform shows up symbolicated within 5 minutes, and a forced
worker exception arrives with `run_id` and `trace_id`. A run whose `load` step throws ends `failed`.

### Phase 2: identity, consent and the core funnels (3–4 days)

1. Catalog file, generators, contract tests (§4.1).
2. App `Analytics` facade; `identify`/`reset`; the switch and its strings in `app_en.arb`;
   `profiles.analytics_opt_out` and the workspace setting (migration, API, pgTAP).
3. Server `ProductAnalytics`, consent cache, `analytics_milestones` (migration, RLS, pgTAP), the
   sign-up sweep and its `worker_*` function.
4. Events for F1, F2, F4, F6 and F7 (§6.1–6.5, §6.8), including the purchase-stream fix in
   `billing.dart:139`.
5. Account purge deletes the PostHog person.
6. Privacy page, docs-site, `PrivacyInfo.xcprivacy`, App Store labels, Play Data safety, sign-in
   notice line. All in the same change.

Done when:
- One internal person's journey appears as one person, from the anonymous sign-in screen to
  `first_value` and a sandbox `purchase`.
- F1, F2, F4 and F6 render.
- Turning the switch off stops both app and server events (tested).

### Phase 3: adoption, reliability and rollups (2–3 days)

1. `feature_used` across the list in §6.10.
2. `usage_daily` and `workspace_daily` (DBOS scheduled workflow, deterministic uuids, consent in
   SQL).
3. Computer, voice, push, `app_startup_failed`, `app_error_shown`, `app_active_daily` events; the
   remaining milestones.

Done when rollup numbers match direct SQL for a fixture day, and events per active person stay
under the budget on internal use.

### Phase 4: dashboards, alerts, growth tools (1–2 days, then ongoing)

1. With Oliver's OK:
   - Dashboards, insights, cohorts and actions (§7.3).
   - Revenue analytics on `purchase`.
   - The test-account cohort.
   - The slug row in `FlutterVibe/AGENTS.md`.
2. Insight alerts (§7.3).
3. Later, each its own decision:
   - **Feature flags:** SPEC already says risky features go to 10% of people first. Use client
     flags, plus server local evaluation with a personal API key.
   - **Experiments:** Welcome chat variants.
   - **Surveys:** NPS after 14 active days, native widgets only.
   - **Reverse proxy** for the web app, to get past ad blockers.
   - **Group analytics,** when team plans matter.
   - **Data warehouse:** a Postgres source limited to analytics views, through an SSH tunnel. Only
     if rollups stop being enough.
   - **OTel traces and logs to PostHog,** so errors, traces and logs live in one place.

---

## 12. Decisions for Oliver

The recommendations below are adopted as defaults (see the execution brief). Oliver can override any
of them; the code keeps each one behind a setting where that's cheap.

| # | Question | Recommendation |
|---|---|---|
| 1 | Where do crashes go for official builds and Cloud? | **PostHog** error tracking, Sentry kept for self-hosters and as fallback (§8.1) |
| 2 | Consent default | **On by default** with a notice at sign-in and the switch in Privacy (matches the other apps); get the legal view on EU opt-in before marketing there |
| 3 | The official app on someone's self-hosted server | **Crash reports plus one anonymous daily ping**, nothing else |
| 4 | Event budget levers: lifecycle off, screen dedupe, rollups instead of per-message events | **Yes to all** |
| 5 | North star | **Weekly active doers** (≥1 completed run on ≥2 days in the week) |
| 6 | Out of credits during a run shows only a notice today. Add a "See plans" action that opens the paywall (`source = credits_depleted`)? | **Yes**; it's a small product change in `chat_controller.dart:630` / `errorFix` |
| 7 | Writes to the shared PostHog project: Casama dashboards, revenue setting, `is_internal` in cohort 603648, slug row in `FlutterVibe/AGENTS.md` | **Yes**, in Phase 4 |
| 8 | Where do error and metric alerts go? | Email to Oliver at first; Slack or Discord when there's a team channel |
| 9 | Take `telemetry.json` out of git | **Yes**; optionally rotate the Sentry `casama-app` DSN; never the shared PostHog token |
| 10 | Data processing agreements | Sign PostHog's DPA (and Sentry's if it stays); add both to the privacy page's processor list |

---

## 13. Risks and open questions

- **Personless linking** (§9) is unverified. It decides whether the cheaper option is available.
- **Native crash coverage is uneven.** Apple native capture is "experimental" in posthog_flutter;
  Windows and Linux native crashes aren't captured; web wasm symbolication is unverified. The crash
  drill decides, and falling back costs one variable.
- **posthog-node queues in memory**, so a hard crash loses unsent events. Deterministic uuids make
  retries safe, rollups recount activity, and billing truth stays in Postgres.
- **The shared project moves our price.** Other apps' volume changes our marginal price, and billing
  limits are organization-wide. That's why the budget insight and alert exist.
- **Event names are permanent.** The catalog review in Phase 2 is the moment to get them right.
- **Ad blockers** block PostHog domains on the web. Expect undercounting there until the reverse
  proxy (Phase 4).
- **The Welcome script will change.** `step` ids come from `welcome.ts`, so renaming a step breaks
  F2's history. Add new ids instead of renaming.
- **Line numbers drift** because the tree is shared. Each phase re-checks hook points before
  editing.
