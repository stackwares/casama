# GA4 live everywhere: launch plan

Status: **built and live** (2026-11-20, D-439). Server, web app (build 50) and all five websites
send to GA4; the property is set up; the store privacy forms are updated; store builds 50 are made
and wait for Oliver to say when to upload. Left: step 7 (funnels after a week of data). The web app
shares the websites' stream `G-4GVRF0K324` instead of its own (D-439).
Oliver: "let's make google analytics live everywhere, the app and all our websites of course.
write the full plan to get it up and running."

## Summary

Almost all of the code is already built (D-396 to D-399, `docs/GA4-PLAN.md`), and the four websites already
send to GA4. What's left is mostly setup: credentials, two streams, server keys, one config file, the property
settings, and the builds that carry the switch. It goes in this order:

1. **Access:** a service account that can manage the GA4 property (Oliver, about 10 minutes).
2. **Property:** streams, API secret, custom dimensions, key events, retention (me, with the scripts that exist).
3. **Server:** keys on prod. That turns on GA4 for server events (sign-up, purchase) and for Windows/Linux.
   Needs a yes.
4. **Web app:** a new official web build with GA4 on. Needs a yes for the build and another for the deploy.
5. **Store apps:** the next store builds carry the same switch, after the store privacy forms are checked.
   Needs a yes for each build; uploads only when Oliver says.
6. **Websites:** check the data is arriving and add the pages that aren't covered yet.
7. **Funnels:** the GA4 funnels and the paywall report, checked against PostHog after a week.

GA4 costs nothing at our volume (`docs/COSTS.md` already has its row). PostHog keeps running next to it, and
it stays the number of record until we compare the two (GA4-PLAN Decision 7).

## Where things stand (checked 2026-11-20)

| Surface | Code | Sending to GA4? | What's missing |
|---|---|---|---|
| casama.ai, docs.casama.ai, gallery.casama.ai, casama.link | Worker collector `site/gallery-link.js` (D-396, D-398); docs/gallery/link pages beacon to `casama.ai/b` (live) | **Yes**, through the Measurement Protocol into web stream `G-4GVRF0K324` (property `563408057`). Worker secret `GA_API_SECRET` is set | Not checked in GA4 reports (no access). `plan_click` waits on per-plan pricing buttons |
| status.casama.ai | uptime Worker (D-304) | No | Decision 5 |
| share.casama.page (share links) | | No | Decision 5 |
| Server (API and worker) | GA4 sink live in the prod image (`f410f8bd`); `PRODUCT_ANALYTICS=on` | **No**: `GA4_*` unset, `ANALYTICS_PROVIDERS` unset | A server web stream + API secret; erase credentials |
| Web app (app.casama.ai, build 49) | GA4 sink in the build | **No**: `client/config/telemetry.json` has no `GA4_ENABLED` and no `FIREBASE_WEB_MEASUREMENT_ID` | The web app's measurement id; a rebuild |
| iOS, Android, macOS (store builds 48 and older) | `firebase_analytics` in the app; collection off in Info.plist/AndroidManifest until consent; no ad ids (Podfile flag, manifest) | **No**: same `telemetry.json` gap | The switch in the next store builds; store privacy forms |
| Windows, Linux | relay `POST /v1/analytics/events` (D-399); the CI secret `CASAMA_TELEMETRY_JSON` has `GA4_ENABLED=true` | **No**: the server forwards only when it has GA4 keys | Server keys (step 3) |
| Property settings | `scripts/ga4-setup.mts` (custom dimensions, key events, retention) | Not applied | Credentials (step 1) |
| Funnels | `scripts/ga4-funnels.mts` (W1, F1–F8) | Can't run | Credentials and a week of data |
| Account deletion | `apps/server/src/services/analytics-erase.ts` | Off | `GA4_PROPERTY_ID` + `GA4_SERVICE_ACCOUNT_JSON` on prod |
| Privacy policy | `site/privacy.html` names GA4/Firebase for the app and the sites | Done | Nothing |

## Steps

### Step 1: access (Oliver, about 10 minutes)

The setup and funnel scripts, account erasure, and my own checks all need access to GA4 property `563408057`.
None of the gcloud sign-ins on this machine have Analytics scopes.

1. I search Vaultwarden first for an existing GA4 or Google Cloud service-account key.
2. If nothing fits, I create the service account `casama-ga4@kasama-ai.iam.gserviceaccount.com` in the Firebase
   project's Google Cloud project, turn on the Analytics Admin API and the Analytics Data API, and make a JSON key.
   The key goes straight into a 0600 file and Vaultwarden ("Casama · GA4 service account (property 563408057)"),
   never into the chat.
3. **Oliver:** in GA4 Admin → Property access management, add that service account's email as **Editor**.
   I can do it in the T3 browser instead if the stackwares Google account is signed in there and Oliver says so.
   - If the organization blocks key creation, the fallback is a scoped
     `gcloud auth login --scopes=…analytics.edit,…analytics.readonly` that Oliver approves in the browser.
     That covers the scripts, but not erasure on the server, which needs the key.

**Done when:** `node scripts/ga4-setup.mts` (dry run) lists the property's current streams and settings.

### Step 2: property setup (me)

1. **List the streams.** The property has a web stream (`G-4GVRF0K324`, the websites) and five app streams with
   no data. Find which stream belongs to the Firebase web app (`FIREBASE_WEB_APP_ID`). If none does, link the
   Firebase web app to the property, which creates it.
2. **Streams the plan needs:**
   - **Websites:** `G-4GVRF0K324`, as now. Nothing else may reuse it.
   - **Web app:** the Firebase web app's stream. Its `G-…` id becomes `FIREBASE_WEB_MEASUREMENT_ID`.
   - **iOS, Android, macOS:** the Firebase app streams that already exist. They need no new ids, because
     `firebase_analytics` uses the app ids in `firebase.json`.
   - **Server:** a new web stream named "Casama server" with a Measurement Protocol API secret. That gives
     `GA4_MEASUREMENT_ID` + `GA4_API_SECRET`.
3. **Secrets:** each one goes to Vaultwarden ("Keys & Signing") in the same step: the server stream's API secret
   and the service-account key. Measurement ids aren't secret, but they go in each item's notes.
4. **`node scripts/ga4-setup.mts --apply`:** 41 event dimensions, 4 user dimensions, 2 metrics, key events
   (`sign_up`, `first_value`, `purchase`, …) and 14-month retention. It only adds, never deletes.
5. **By hand in GA4 Admin** (the Admin API doesn't cover these well):
   - Google Signals off;
   - ads personalization off, no Google Ads links;
   - reporting identity "Blended" → "Observed" (no modelled users);
   - an internal-traffic filter for our own test accounts (Decision 4);
   - BigQuery export if Decision 3 is yes.
6. **Data streams' settings:** turn off enhanced measurement's page-change and form events on the web app
   stream. Flutter routes send their own `screen_view`, so those would count twice.

**Done when:** the dry run shows no pending changes, and every new secret is in Vaultwarden.

### Step 3: server (prod, needs Oliver's yes)

1. **Check locally first:** set the server stream's keys in the local `.env` with `GA4_DEBUG=1`, which sends to
   GA4's validation endpoint. Then run the server tests for the GA4 sink and the relay, and send one of each
   event (sign-up, purchase, a relayed Windows event) to check GA4 accepts them.
2. **Prod `.env`** (`/opt/casama/infra/compose/.env`), written from the files, never echoed:
   `ANALYTICS_PROVIDERS=posthog,ga4`, `GA4_MEASUREMENT_ID`, `GA4_API_SECRET`, `GA4_PROPERTY_ID=563408057`,
   `GA4_SERVICE_ACCOUNT_JSON`.
3. **Restart the API and worker** so they read the new env: `scripts/deploy-prod.sh --dry-run`, show it, then
   `--yes`. That way it gets the smooth-deploy handling (D-402) and the health checks.
4. **Check:** the GA4 Realtime report shows `sign_up`/`login` from a test sign-up and `page_view` from the
   Windows relay. Erasure is checked by purging a throwaway account and seeing the deletion request accepted.

This step alone turns on GA4 for server events and for the Windows and Linux apps already shipped.

### Step 4: web app (needs a yes for the build and a yes for the deploy)

1. **`client/config/telemetry.json`** (official builds; git-ignored) gets `ANALYTICS_PROVIDERS=posthog,ga4`,
   `GA4_ENABLED=true` and `FIREBASE_WEB_MEASUREMENT_ID=<web app stream id>`.
   - The same three values go into the repo secret `CASAMA_TELEMETRY_JSON` for the CI desktop builds, with
     its other keys unchanged.
   - A copy goes into the Vaultwarden item that holds the telemetry config.
2. **Paywall events (small code change, Decision 2):**
   - `paywall_view` gets `default_plan` and `default_period`, so the paywall report can be split by what the
     paywall opened on (weekly since 2026-11-20);
   - a new `paywall_plan_select` (`plan`, `interval`) for each tap on a plan;
   - GA4 twins: `paywall_view` → `view_item_list`, `paywall_plan_select` → `select_item`, so GA4's built-in
     monetization reports fill in.
   - The catalog test, `pnpm gen`, and the targeted Flutter and server tests cover it.
3. **Official web build** (bump the build number): `CASAMA_OFFICIAL_BUILD=1 scripts/build-web.sh …`. Then
   `scripts/deploy-app-web.sh --dry-run`, and `--yes` after Oliver's yes.
4. **Check:** open app.casama.ai with `?debug_mode=1` in a throwaway account. DebugView should show
   `screen_view`, `login`, `paywall_view` and `begin_checkout`, and with the switch in Settings → Privacy
   off, nothing.

### Step 5: store apps (needs a yes for each build; uploads only when Oliver says)

1. **Store privacy forms first**, before any build carrying GA4 goes to review (see `client/store/README.md`):
   - **App Store, App Privacy:** add **Product Interaction** (Analytics, linked to the user, no tracking) and
     **Device ID** (Analytics, linked, no tracking) if they aren't already declared. Then publish again.
   - **Play, Data safety:** **App interactions** (collected, Analytics) and **Device or other IDs** (already
     declared for messaging and Crashlytics; add the Analytics purpose).
   - Write down what changed in `client/store/README.md`, as was done for Crashlytics.
2. **The next store builds** (iOS, Android, macOS) pick up the same `telemetry.json`. No native changes are
   needed: the collection-off defaults and the no-ad-id settings are already in the repo. Builds 48 and older
   send nothing to GA4 and can't be switched on remotely.
3. **Check before upload** on a simulator/emulator debug build (needs its own yes):
   - iOS with `-FIRDebugEnabled`, Android with `adb shell setprop debug.firebase.analytics.app ai.casama…`;
   - DebugView shows sign-in, screens and the paywall;
   - no ATT prompt, and no `AD_ID` permission in the merged Android manifest.
4. **Uploads:** only when Oliver says (standing rule).

### Step 6: websites

1. **Check what's live:** the Realtime report shows `page_view`s from all four sites, split by `site`, plus the
   funnel events (`start_click`, `download_click`, `qr_open`, `invite_open`, `gallery_open`). Fix whatever is
   missing.
2. **Fill the gaps (Decision 5):**
   - status.casama.ai: the uptime Worker sends one anonymous `page_view` per visit through the same collector
     (`casama.ai/b`, site key `status`);
   - share.casama.page: the same for opened share links, page path only and never the share id. Or leave it
     out, since those pages are the users' content;
   - per-plan buttons on casama.ai/pricing, so `plan_click` (already allowlisted) has something to fire on.
3. **Search Console** is already linked to the website stream. Link the Firebase project's Play account too, so
   installs show up next to the website funnel.
4. **Deploy:** `scripts/deploy-web.sh` (casama.ai, docs, gallery) and `scripts/deploy-link-web.sh`. Each needs
   a yes, with the changed pages checked locally through `scripts/serve-web.py` first.

### Step 7: funnels and reports

1. **After 7 days of data:** run `node scripts/ga4-funnels.mts` for W1 (website → active user) and F1–F8.
2. **Build them as saved GA4 Explorations**, so Oliver can open them without the script:
   - W1: website visit → start click → sign-up → first value;
   - activation: sign-up → onboarding complete → first message → first value;
   - **paywall:** `paywall_view` → `paywall_plan_select` → `begin_checkout` → `purchase`, split by
     `default_period` and `interval`. This answers whether opening on weekly sells more;
   - retention and revenue: GA4's built-in monetization and retention reports, plus `plan` as a user property.
3. **Compare with PostHog:** the same funnels in both tools should agree within about 10%. Any bigger gap gets a
   finding in this plan.
4. **Optional:** a Looker Studio dashboard on top (free) if Oliver wants one page.

### Step 8: docs and records

- A D-entry for the launch: which streams, which surfaces are on, and the form changes.
- Update `docs/GA4-PLAN.md`, this plan's status line and `docs/PLANS.md` in the same commit.
- `docs-site/guide/privacy.md` and the self-hosting docs already describe `ANALYTICS_PROVIDERS`. Check that
  they still read right.

## Order, owners and what needs a yes

| Step | Who | Needs Oliver | Time |
|---|---|---|---|
| 1 Access | Oliver + me | Add the service account in GA4 (or say I may) | 10 min |
| 2 Property | me | No (property settings aren't production traffic), unless Decision 3 or 4 changes it | 1 h |
| 3 Server | me | **Yes**: prod env + `deploy-prod.sh` | 1 h |
| 4 Web app | me | **Yes** for the Flutter build, **yes** for `deploy-app-web.sh` | 2–3 h with the paywall events |
| 5 Store apps | me + Oliver | **Yes** per build; uploads only when Oliver says; store form edits | with the next release |
| 6 Websites | me | **Yes** for each site deploy | 1–2 h |
| 7 Funnels | me | No | 1 h, a week after step 4 |

Steps 3, 4 and 6 can go the same day. Step 5 rides along with the next store release.

## Decisions for Oliver

| # | Question | Default |
|---|---|---|
| 1 | Who adds the service account to the GA4 property: you in GA4 Admin, or me in the T3 browser on the stackwares Google account? | You (one screen) |
| 2 | Add the paywall events (`default_plan`/`default_period` on `paywall_view`, a new `paywall_plan_select`, GA4 twins) in step 4? | Yes: without them, GA4 and PostHog can't tell whether weekly-first sells more |
| 3 | Turn on BigQuery export (free sandbox, 1M events a day)? | Yes, daily |
| 4 | Filter our own and test accounts out of GA4 reports (internal-traffic rule by a `test_account` user property)? | Yes |
| 5 | Add status.casama.ai and share.casama.page to the website collector? | status: yes. share pages: no (they're people's content) |
| 6 | When does PostHog get cut back? | Still after 4 weeks of both (GA4-PLAN Decision 7) |

## Risks

- **Store review:** an app build that sends GA4 before the privacy forms are updated can be rejected. Step 5.1
  comes first for that reason.
- **Old builds stay dark:** store builds 48 and older can't be switched on remotely. Their server events
  (sign-up, purchase) still reach GA4 after step 3, but their screens and taps don't.
- **Counts differ:** GA4 applies thresholds and its own user counting. The website ids are daily and the app
  ids per install, so cross-surface funnels are open funnels.
- **Retried server events can count twice in GA4** (no dedupe in the Measurement Protocol; D-397 "Not done").
  `purchase` is the one that matters. It carries `transaction_id`, which GA4 dedupes in its revenue reports.
- **EU scrutiny:** see GA4-PLAN "Risks". Unchanged: no ad ids, Signals off, one consent switch, and the policy
  names Google.
