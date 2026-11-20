# Ads and attribution (Meta first, with Firebase and RevenueCat): plan

Status: **waiting for Oliver's answers** (§15). Written 2026-11-20. No code, account, store or
dashboard change has been made. When this is approved, record it as a decision in
`docs/DECISIONS.md` (check the highest number first; it was D-433 on 2026-11-20).

Oliver asked: "We will be supporting Facebook Ads soon, we will run facebook ads for our apps so make
sure we setup attributions for Meta, Firebase, RevenueCat and whatever else we need. We need to be
able to keep track of everything without mistakes."

## Execution brief (read this first)

**Goal:** for every person who joins or pays, Casama knows which ad (if any) brought them, how much
they paid, and what that ad cost. Meta is told about the same sign-ups and purchases, once each, so
its campaigns can be measured and can optimise. Firebase (GA4), PostHog and RevenueCat show the
same numbers.

**Route (Decision 1):** Casama's server is the one sender of conversions. It keeps its own record
of where each person came from and of every conversion, and delivers each conversion once to each
tool. The Meta SDK in the iOS and Android apps reports only the install and app opens. RevenueCat
stays the source of truth for store purchases, and its own forwarders to Meta and Firebase stay
off, so nothing is counted twice (§5).

**Order:** Phase 0 (accounts and checks) and Phase 1 (our own record) can start as soon as §15 is
answered. Phase 2 (web conversions to Meta) is what ads to the waitlist need. Phase 3 (the apps)
has to be inside an app build that passed store review before app-install ads start. Phases 4 and 5
follow (§13).

**Rules (as for every Casama task):**
- Every step that real people or the stores can see needs Oliver's yes first, and a yes covers only
  that step: production deploys, app builds, store uploads, store privacy forms, creating or
  changing anything in Meta, RevenueCat, GA4 or PostHog, and spending money (AGENTS.md,
  "Production").
- Keys: search Vaultwarden before making one, and save every new one to "Keys & Signing" in the
  same task. Checked 2026-11-20: the vault has no Meta, Facebook developer, ad account, dataset or
  Pixel item, so Phase 0 creates them.
- The privacy page, docs, privacy manifests, store form notes and `docs/COSTS.md` change in the
  same commit as the code they describe.
- New tables get RLS, `public.allow_worker` and a pgTAP test. Check every branch, worktree and the
  local database for the newest migration version before naming one.
- Flutter: ask before any build. New Dart files import `package:material_ui/material_ui.dart`.
  `dart format` only new files.
- Commits: stage by path, through a private index (memory "Stage by path"). Never `git add -A`.
- Targeted tests while working, then the full suites once through `scripts/heavy.sh`.

**Needs Oliver's hands** (log in `docs/NEEDS-FROM-OLIVER.md`; code that doesn't depend on them
carries on):

| Item | Why only Oliver |
|---|---|
| A Meta business portfolio, an ad account with a payment method, and business verification | His Facebook login, identity documents and card |
| A yes to create the Meta app and the dataset (I can do it in the T3 browser once he says so) | New outside accounts |
| The ad budget and who pays (§11) | Money |
| A yes for each store privacy form change and each app build | Stores |
| The ads themselves (creative, audiences, campaign setup) | Not part of this plan; §6.10 gives the link rules every ad must follow |

---

## 0. Summary

- **What's missing today:** Casama records what people do (PostHog and GA4, D-206 to D-399) but
  not where they came from. The apps and the server keep no campaign, no click id and no install
  source. Purchases reach GA4 and PostHog with no money amount. Nothing talks to Meta.
- **What this plan adds:**
  1. **Our own record** of every touch (an ad click, a store referrer, an invite link), one
     credited source per person, and one row per conversion with its money amount.
  2. **Delivery** of each conversion, once, to Meta (Conversions API), GA4 and PostHog, with a
     written reason whenever one is not sent.
  3. **The Meta SDK** in the iOS and Android apps, for installs and app opens only.
  4. **A switch and region rules**, so nothing goes to Meta without a lawful footing.
  5. **A daily check** that compares our record with the stores, RevenueCat, Meta and GA4, and a
     report of spend, sign-ups, subscribers, revenue and return per campaign.
- **What it can't do, on any setup:** on iPhone and iPad, Apple doesn't let anyone tie a single
  install to a single ad unless the person allows tracking. Per-campaign numbers for iOS app ads
  come from Meta's aggregated reports. Our own record covers Android, the web, and everyone who
  arrives through a link we control. The report shows which numbers are ours and which are Meta's.
- **What it costs:** no new paid tool. The ad spend itself is the new cost (§11).
- **What changes publicly:** the privacy policy, the App Store privacy label, Play's Data safety
  form and advertising ID declaration all change, because Casama starts sharing data with Meta to
  measure its own ads (§8).

## 1. What exists today (checked 2026-11-20)

### 1.1 Analytics

| Piece | Where | State |
|---|---|---|
| Event catalog, 99 events | `packages/contracts/analytics/catalog.json` | Live |
| App analytics (PostHog, GA4 through `firebase_analytics`, a relay for Windows and Linux) | `client/lib/core/analytics.dart`, `analytics_sinks.dart` | In code; GA4 keys and streams still not set (GA4-PLAN is "Built, waiting to ship") |
| Server analytics (PostHog, GA4 Measurement Protocol) | `packages/observability/src/analytics.ts`, `ga4.ts` | Same |
| Website counts for casama.ai, docs, gallery, casama.link | `site/gallery-link.js` (the casama.ai Worker), GA4 stream `G-4GVRF0K324` | Live, with no cookie and no script |
| PostHog | Casama's own project 750357 (D-430) | Live |

### 1.2 Billing

- Store purchases go through RevenueCat (D-297). **The RevenueCat customer is the workspace, not
  the person or the device** (`client/lib/core/billing.dart`). The server never trusts a webhook
  body: it re-reads the customer with RevenueCat's REST API v2 (`apps/server/src/billing/revenuecat.ts`).
- Web and direct-Mac purchases go through Dodo.
- The server emits `purchase`, `subscription_changed` and `refund_issued` with fixed ids
  (`apps/server/src/billing/service.ts`), so a repeated webhook can't count twice in PostHog.
- **`purchase` has no amount.** The code says so: plans only have a text price label
  (`plans.price_label`), and GA4 gets `currency: USD` with no `value`.

### 1.3 Website and links

- `casama.ai/get` and `/get/<platform>` send people to a store, a download or the web app, and
  label the hand-off: `utm_source=casama.ai&utm_medium=website&utm_campaign=<page>` on the web app
  and inside Google Play's `referrer`. App Store links carry nothing.
- The waitlist (`waitlist_entries`) keeps a `source` and a `ref`. The gate is on until launch
  (D-427), so today "Start free" leads to the waitlist.
- `STORES_LIVE` is false: the store listings aren't public yet.
- `site/site.js` already reads the referring site's host name (`document.referrer`) on every page
  view, but only for an anonymous count (`/b`). It isn't kept for the visit or passed on, so a
  person who arrives from Reddit, a blog or a search engine and then joins is never credited to it.

### 1.4 What the apps block on purpose

- No advertising id anywhere (D-397): Android removes the `AD_ID` permission, iOS and macOS build
  Firebase without ad id support, and GA4's ad id, vendor id and ad personalisation flags are off.
- No App Tracking Transparency prompt, and `NSPrivacyTracking` is false in every privacy manifest.
- The web app's content security policy allows no ad scripts.

### 1.5 What we've promised publicly

- The privacy policy says: "We don't sell your data, show ads, or train AI models on your
  content", "Google Analytics runs without advertising ids", "This website casama.ai sets no
  cookies and runs no ad or tracking scripts", and (for Google user data and health data) "We don't
  use it for advertising".
- The App Store privacy label says 18 data types, all linked to the person, **no tracking**.
- Play's Data safety form lists Device or other IDs for app functions and analytics only.

Sending anything to Meta makes some of these untrue unless they change first (§8).

### 1.6 Accounts and keys

| Thing | State |
|---|---|
| Casama Facebook Page (61596357437044) and Instagram | Exist |
| Meta business portfolio, ad account, Meta app, dataset, tokens | **None** (vault and the Facebook account both checked) |
| RevenueCat project `proj864b35e1`, v2 key (read-only), webhook | Live |
| Firebase project `kasama-ai` and its GA4 property (563408057) | Exist; app and server streams not wired |
| App Store app 6833509960, Play app `ai.casama.app` | Exist, not public |

### 1.7 Gaps found along the way

1. **The site would erase an ad's label.** `withAttribution()` in `site/gallery-link.js` always
   writes `utm_source=casama.ai`. A person who clicks a Meta ad, lands on casama.ai and then presses
   "Start free" would arrive at the web app or Google Play labelled as coming from the site, not
   the ad. §6.3 fixes this.
2. **No money on purchases** (§1.2). Without it nothing can report revenue per campaign.
3. **The web app ignores campaign labels** in its address.
4. **The Android app never reads the Play install referrer** itself (Firebase reads it for its own
   reports, but our server never sees it).
5. **GA4 isn't wired** (keys, streams, credentials, deploy). "Attribution for Firebase" depends
   on finishing that first.
6. **Other sites are lost.** A visit from a site that links to us without `utm_*` labels (a
   search engine, a forum post, a blog, an AI assistant) reaches the waitlist or the web app as
   "casama.ai" or with no source at all. §6.3 ("Referring sites") fixes this.

## 2. What the platforms allow (facts this plan relies on)

Sources are in Appendix B. Items marked "check in Phase 0" are ones the public docs don't settle.

### 2.1 Meta

- **Two ways in.** The Meta SDK inside an app (iOS and Android only; no macOS, Windows, Linux or
  web), and the Conversions API, which takes events from a server for apps (`action_source: app`)
  and for websites (`action_source: website`).
- **One dataset.** A dataset holds a product's events. It must be linked to the Meta app before it
  takes app events, and one dataset links to only one app.
- **Same event from two senders.** Meta drops the second copy when both carry the same `event_id`
  and event name. This works between the SDK and the Conversions API, not only on the web.
  RevenueCat's forwarder can't share an id with the SDK, which is why RevenueCat tells people to
  remove purchase logging from the app.
- **Installs.** Only the SDK on the device can report an install for attribution. Meta counts one
  install per 90 days.
- **Server events are limited in time.** An event older than 7 days is refused, along with the whole
  batch it's in.
- **Web without a Pixel.** A server can send web events with no Pixel script and no cookie. The
  click id from the ad's link (`fbclid`) becomes `fbc` = `fb.1.<time first seen, ms>.<fbclid>`,
  unchanged in case. Website events must carry the browser's user agent.
- **Android.** For installs that come from a Meta ad through Google Play, Meta puts encrypted ad
  details into the Play install referrer. With the app's decryption key they give the campaign, ad
  set and ad ids and names.
- **iOS.** Meta measures iOS app ads in two separate ways: Apple's SKAdNetwork (a conversion value
  that only code on the device can update) and Meta's own Aggregated Event Measurement, which takes
  events from people who haven't allowed tracking. Aggregated measurement needs the SDK, Universal
  Links, and the link that opened the app passed to the SDK. Meta's deferred deep links aren't
  available for iOS 14+ campaigns.
- **US state privacy laws.** Events can carry a "Limited Data Use" flag for people who opt out.
- **The Flutter plugin** `facebook_app_events` 0.34.0 (November 2026) wraps Meta SDK 19. It needs
  Flutter 3.41+, iOS 15+ and Xcode 26.4+; Casama has Flutter 3.50, iOS 15.0 and Xcode 27.2. It can
  start with the SDK switched off (`FacebookAutoInitEnabled=false`) and be turned on later in code.

### 2.2 Apple

- Apple's meaning of **tracking**: linking data from our app with data from other companies' apps
  or sites for ad targeting or ad measurement. It needs the tracking permission prompt.
- Without that permission, **no other identifier may stand in**: Apple names hashed email and
  hashed phone number, and bans fingerprinting.
- Apple's examples include "placing a third-party SDK in your app that combines user data from your
  app with user data from other developers' apps to … measure advertising efficiency". We are
  responsible for what an SDK does.
- The privacy label has a purpose called **Developer's Advertising or Marketing**, which includes
  "sharing data with entities who will display your ads". Data that reaches Meta falls under it.
- App Store links can't carry a campaign to the app. They can carry a campaign token (`ct=`), which
  App Store Connect reports in totals.

### 2.3 Android

- An app that targets Android 13 or later can read the advertising ID only if its manifest
  declares the `AD_ID` permission. Play Console asks what the ID is used for.
- The Play Install Referrer API gives the app the referrer text of its own install, once.

### 2.4 RevenueCat

- It **isn't an attribution tool**: it only shows campaign data that we give it, except Apple
  Search Ads.
- Its Meta forwarder needs `$fbAnonId` (or an ad id) on the customer. Its Firebase forwarder needs
  `$firebaseAppInstanceId` and would send its own `purchase` events to GA4.
- Its forwarder to Meta doesn't send refunds, and it never updates SKAdNetwork values.
- Attribution fields (`$mediaSource`, `$campaign`, `$adGroup`, `$ad`) and device ids can't be
  changed once set. `$fbAnonId` can be overwritten.
- REST API v2 gives each charge's money: `GET /projects/{id}/subscriptions/{id}/transactions`
  returns `revenue_in_usd` and `revenue_in_local_currency`, each with `gross`, `commission`, `tax`
  and `proceeds`. One-time purchases carry `revenue_in_usd`. Both carry `environment` (production
  or sandbox) and `country`.
- Pricing is unchanged: all features are included; 1% of tracked revenue above $2,500 a month.

### 2.5 Firebase and GA4

- On Android, Firebase reads the install referrer by itself and credits `first_open` to its
  `utm_*` labels. On iOS it can't see where an install came from.
- GA4 has a link to Meta ("Meta Links") that imports cost, clicks and impressions every day. It
  joins on `utm_source`, `utm_medium` and the date, and the values must match exactly.
- GA4 dedupes `purchase` by `transaction_id`.

### 2.6 PostHog

- Marketing analytics (an opt-in beta) can read Meta Ads campaigns and spend, and joins them to
  our events by `utm_campaign` and `utm_source`.

## 3. What we want

Questions the finished system must answer, with a number we can trust:

1. How much did we spend yesterday, per campaign, ad set and ad?
2. How many installs, waitlist joins, sign-ups, first uses, trials, new subscribers and renewals
   did each one bring?
3. How much money came back (before and after store fees, less refunds), and what is the return
   on spend and the cost per subscriber?
4. For any one account: where did this person come from?
5. What share of new people have a known source, and is any number in any tool wrong?

Also: Meta gets what it needs to optimise campaigns toward sign-ups and subscribers, not only
installs.

## 4. Principles (the rules that prevent mistakes)

1. **One sender per event per tool.** Each conversion has exactly one piece of code allowed to
   send it to each tool. No tool forwards to another tool.
2. **Money events come from the billing record, never from the app.** A purchase is sent only
   after the server has checked it with RevenueCat or Dodo.
3. **Our own record is the number of record.** Meta, GA4, PostHog and RevenueCat are compared
   against it every day.
4. **Every conversion has a fixed id** made from the store's own transaction id, so a retry, a
   repeated webhook or a second sender can't count twice.
5. **Written once, delivered later.** A conversion row is written in the same database step as the
   billing change. Delivery reads those rows, retries, and records "sent" or "not sent, because …"
   for each tool. Nothing is fire-and-forget.
6. **Sandbox, TestFlight, review and staff purchases never reach a production tool.**
7. **Consent is checked at the last moment**, when the row is delivered, and the answer is stored.
8. **Send the least that works.** Only the events in §7, never content, names, emails or ids of
   bots, chats or workspaces.
9. **Ids are the keys, names are labels.** Campaign, ad set and ad ids join spend to people. Names
   can change.
10. **Self-hosted servers and community builds send nothing**, and the Meta SDK never starts there.

## 5. Options and recommendation (Decision 1)

Who sends purchases to Meta?

| | A. RevenueCat's forwarder | B. Our server (recommended) |
|---|---|---|
| Work | Dashboard settings, plus setting ids on the customer | A sender module, a table and a worker job |
| Store purchases | Yes, with renewals and trial conversions | Yes, the same, from the same RevenueCat data |
| Web (Dodo) purchases | **No** | Yes |
| Sign-up, first use, waitlist | **No**: needs our own sender anyway | Yes |
| Which device a purchase is tied to | The workspace's last device to write `$fbAnonId`. Casama's customer is a workspace, so a second phone, a Mac or a teammate overwrites it | The install of the person who pressed Buy |
| Shared id with the SDK (for SKAdNetwork later) | **No** | Yes |
| GA4 | Its Firebase forwarder would add a second `purchase` next to ours | One `purchase`, ours |
| Refunds | Not sent | Not sent to Meta either, but in our record and report |
| A written reason when something isn't sent | Per customer in RevenueCat's dashboard | One table for every tool |
| Who fixes it when Meta changes the API | RevenueCat | Us |

**Recommendation: B.** With A we would still have to build our own sender for the web, for
sign-ups and for the waitlist, so we would run two senders into one dataset. That is the setup most
likely to double count or miss. With B there is one sender, one record and one place to look.
RevenueCat keeps doing what it does well: telling the server the truth about store purchases.

If Oliver prefers A for store purchases, the plan still works: §6.8 lists what changes.

## 6. Design

### 6.1 The picture

```
 ad click ──► casama.ai ──► waitlist / web app ───────────────┐
    │                └────► Google Play (referrer) ──► app ───┤  touches
    └──────────────────────► App Store ──────────────► app ───┘  (where people came from)
                                                              ▼
   stores ─► RevenueCat ─┐                            ┌── our record ──┐
   Dodo ─────────────────┴─► billing (server) ───────►│  touches       │
   sign-up, first use ───────────────────────────────►│  credited src  │
                                                      │  conversions   │
                                                      └───────┬────────┘
                                             one delivery job │ (once per tool)
                              ┌───────────────┬───────────────┼────────────────┐
                              ▼               ▼               ▼                ▼
                       Meta Conversions     GA4           PostHog       RevenueCat
                       API (app + web)   (value, source) (source)    (source fields)

   Meta SDK in the iOS / Android app ──► Meta: install and app opens only
   Meta Marketing API ──► spend per campaign per day ──► our report and daily check
```

### 6.2 Our own record

Four new tables (names can change in review), all with RLS, readable only by the worker and the
admin API:

| Table | One row per | Holds |
|---|---|---|
| `installs` | App install or browser | A random install id made on the device; platform; how the app was distributed; first seen; country; app and device details Meta's app events require; Meta's anonymous id; the GA4 app instance id; the person, once they sign in |
| `touches` | Thing that brought someone | Kind (ad click, Play referrer, App Store token, invite, referral, another site (`referral_site`), site page, self-reported); network; campaign, ad set and ad ids and names; the `utm_*` labels; the referring site's host name (`ref_host`, never the full address); the click id (`fbc`), kept 90 days and then cleared; when; which install or waitlist entry it belongs to |
| `acquisitions` | Person | The one credited touch, frozen at sign-up, with the rule version that picked it |
| `conversions` | Conversion | Its fixed id; kind; person, workspace and install; when; money (currency, gross, store fee, tax, proceeds, in USD and in the paid currency); store; product; environment; and per tool: sent, skipped (with the reason) or failed, the tries, and Meta's trace id |

**Which touch gets the credit** (one SQL function, so the rule lives in one place):
1. the last paid click in the 7 days before sign-up (the same window Meta uses by default);
2. otherwise the last other touch in the 30 days before sign-up (invite, referral, another site
   that linked to us, a site page);
3. otherwise `unknown`.

All touches are kept, so the rule can be changed and re-run. A purchase is credited to the buyer's
acquisition, and to the workspace creator's when the buyer isn't known.

When an account is deleted, its installs, touches and acquisition go with it. Its conversion rows
stay for the accounts, with the person removed.

### 6.3 Capturing where people come from

| Route | How the label survives |
|---|---|
| Ad → casama.ai → waitlist | The page keeps the landing labels (`utm_*`, `fbclid`) for the tab and sends them with the join. They are stored as a touch on the waitlist entry and move to the account when that address signs up |
| Ad → casama.ai → web app | `/get` passes the ad's labels on instead of overwriting them (fixes §1.7 no. 1). The site page becomes a separate `via` label. The web app reads the labels at first load and posts them at sign-in |
| Ad → casama.ai → Google Play | The same labels go into Play's `referrer`. The app reads the referrer once at first open and posts it at sign-in |
| Ad → Google Play directly (app-install ad) | Meta's encrypted referrer. The server decrypts it with the app's key and stores the campaign, ad set and ad |
| Ad → App Store directly (app-install ad) | **No per-person label exists.** Meta reports these in totals. Our record marks the person `unknown`, or uses the answer to the question below |
| Ad → casama.ai → App Store | The link carries an App Store campaign token for Apple's totals. Per person: only if they joined the waitlist or signed up on the web first, through the matching address |
| Another site → casama.ai → waitlist, web app or Google Play | The referring site's host name is kept with the landing labels and travels the same way (see "Referring sites" below) |
| Another site → app.casama.ai directly | The web app reads the referring host name at first load, the same as its `utm_*` labels |
| Invite and referral links | Already known to the server; written as touches |
| Mac, Windows, Linux downloads | Through the account: the web or waitlist touch of the same person |

**Referring sites** (fixes §1.7 no. 6):
- On the first page of a visit, `site/site.js` keeps the referring site's **host name only**
  (`reddit.com`, `www.google.com`) in session storage beside the landing labels, the same storage
  §6.6 already adds. Browsers mostly send only the origin anyway; anything after the host is
  dropped. Casama's own hosts (casama.ai, docs, gallery, casama.link, app.casama.ai, share pages)
  are ignored, so moving around our sites never overwrites it. The first outside site in the tab
  wins.
- It goes with the waitlist join, through `/get` (as `ref_host` next to the `utm_*` labels on the
  web app address and inside Play's `referrer`), and with the web app's sign-in.
- **Labels win over the host.** With `utm_*` present, those are the source and the host is kept as
  extra detail. Without them, the server fills the source from the host: `utm_source` = the host
  (minus `www.`), and `utm_medium` from a short list kept in one place: `organic_search` (Google,
  Bing, DuckDuckGo, …), `social` (Reddit, X, Facebook, Instagram, LinkedIn, YouTube, TikTok, …),
  `ai_assistant` (ChatGPT, Perplexity, Claude, Gemini, Copilot, …), otherwise `referral`. The
  groups come from `SOURCES` / `visitSource()` in `site/gallery-link.js`, which the `/b` page count
  already uses; that list moves to a small shared module the Worker and the server both import, so
  the page counts and our record never disagree on what a site is.
- No referrer at all (typed address, bookmark, many in-app browsers, privacy settings) stays
  `direct`, which the crediting rule treats as no touch.
- These touches are kind `referral_site`, so they rank under paid clicks (rule 1) and compete
  with invites and site pages under rule 2.

Two more pieces:
- **"How did you hear about us?"** One optional, skippable tap in onboarding (Instagram, Facebook,
  TikTok, YouTube, a friend, search, other). It is the only per-person signal for iOS app-install
  ads, and a sanity check on everything else (Decision 9).
- **The app posts its install record only after sign-in.** Before that, nothing about the install
  reaches our server. A conversion waits up to 15 minutes for its install record, then goes with
  what we have or is skipped as `no_identifiers`.

### 6.4 Conversions and delivery

- **Writing:** billing writes a conversion row in the same transaction as the subscription or
  credit change. The sign-up sweep, the first-value milestone and the waitlist join write theirs.
- **Money:** for store purchases the server reads the charge from RevenueCat's transactions
  endpoint (§2.4) and stores gross, fee, tax and proceeds. For Dodo it uses the payment's amount.
  A purchase with no known amount is held and flagged, never sent as zero.
- **The buyer:** when someone presses Buy, the app tells the server which person and install
  started it. The server ties the next charge on that workspace and product to them.
- **Delivery:** a worker job runs every minute. For each row and each tool it checks, in order:
  environment is production; the person isn't staff; the server is Casama Cloud; the ad switch and
  the region allow it (§8); the event is under 7 days old; identifiers exist. Then it sends, with
  backoff on failure, for up to 7 days.
- **Destinations are a list** (`AD_DESTINATIONS`, the same idea as `ANALYTICS_PROVIDERS`). Meta is
  the first. TikTok, Google Ads or Apple Search Ads would be new entries later, not a redesign.
- **Sandbox:** sandbox and TestFlight purchases go to a separate test dataset in Meta, so the whole
  path can be watched end to end without touching production numbers.

### 6.5 Meta in the iOS and Android apps

- Add `facebook_app_events`. iOS and Android only; every call is guarded on other platforms.
- **Off until allowed.** The SDK doesn't start by itself (`FacebookAutoInitEnabled=false`, and the
  Android twin). It starts in code only when: the build is official, the app points at Casama
  Cloud, the region allows it and the ad switch is on (§8). The app asks the server once whether
  the region allows it and remembers the answer; with no answer it stays off.
- **Install and opens only.** Automatic event logging and automatic purchase logging are off, in
  the app and in Meta's dashboard. The app calls `activateApp()` and nothing else.
- **Links:** the link that opens the app is passed to the SDK (the plugin does this), which Meta's
  aggregated measurement needs.
- **iOS identifiers:** no tracking prompt in v1 (Decision 2). So events for iPhone and iPad carry
  Meta's anonymous id and the app and device details only: no advertising id, no vendor id, no
  email, no IP address.
- **Android identifiers:** Meta's anonymous id, the install referrer, and the advertising ID if
  Decision 3 says yes. GA4 keeps running without the advertising ID.
- **The keys** (`META_APP_ID`, `META_CLIENT_TOKEN`) come from the gitignored
  `client/config/telemetry.json`, as the other telemetry keys do. A build without them has no Meta
  code path that can run.
- **SKAdNetwork:** in v1 it sees installs only. Phase 4 adds an on-device copy of sign-up, trial
  and first purchase with the same ids as the server's, after a test proves Meta drops the
  duplicates (§12). That lets SKAdNetwork campaigns see purchases too.

### 6.6 Meta on the web

- **No Pixel, no cookie, no script.** The server sends web conversions through the Conversions
  API, so casama.ai still "runs no ad or tracking scripts".
- Sent only for visits that arrived with a Meta click id, from an allowed region, with no Global
  Privacy Control or Do Not Track signal.
- What goes with the event: the click id, the IP address and browser of the request that caused
  it (the waitlist join or the sign-up), and the page address. Kept on the conversion row only
  until it's delivered.
- The page keeps the landing labels and the referring host name for the tab (session storage).
  The privacy page says so.

### 6.7 Firebase and GA4

1. **Finish GA4-PLAN's open items first** (streams, keys, credentials, deploy). Nothing else here
   works without them.
2. `purchase` gains `value` (gross, USD) and a `transaction_id` made from the store's transaction
   id. This also fixes GA4's revenue reports.
3. New user properties from our record: `acq_source`, `acq_medium`, `acq_campaign`. They fill the
   gap on iOS, where GA4 can't see an install's source. (4 of 25 user dimensions are used today.)
4. The web app keeps `utm_*` in its address at first load, so GA4 credits the session.
5. Link GA4 to Meta (Meta Links) for spend, clicks and impressions.
6. **RevenueCat's Firebase forwarder stays off**: our server already sends `purchase`, and a second
   one would double GA4's revenue.
7. Firebase's ad settings stay as they are: no advertising id, no ad personalisation, no Google
   Signals. Google isn't an ad destination in this plan.

### 6.8 RevenueCat

- **Stays the source for store purchases.** New: the server also reads each charge's money (§6.4).
  No new key is needed; the read-only v2 key covers it.
- **Source fields for its own records and exports:** the app sets `$mediaSource`, `$campaign`,
  `$adGroup` and `$ad` once per workspace, from the acquisition the server reports. These can't be
  changed later, so the app sets them only after the server has frozen the acquisition.
- **Forwarders to Meta and Firebase: off** (Decision 1).
- **If Decision 1 is A instead:** turn on the Meta forwarder with the Conversions API, a dataset id
  and token, "send events when tracking isn't authorised", and gross revenue. The app sets
  `$fbAnonId` right before each purchase (so it's the buyer's device, not the last one opened) and
  calls `collectDeviceIdentifiers()`. Our own sender then skips store purchases and still sends
  Dodo purchases, sign-ups and the rest. The Firebase forwarder still stays off.
- **Daily check:** RevenueCat's gross revenue per day must equal our record's store gross (§9).

### 6.9 PostHog

- Person properties `acq_source`, `acq_medium`, `acq_campaign`, `acq_ad_set`, `acq_ad`, set once at
  sign-up by the server. Every funnel can then be split by campaign.
- Turn on Marketing analytics and connect Meta Ads for spend (a change to the PostHog project:
  needs Oliver's yes, Decision 14).

### 6.10 Link rules for every ad

Every ad that goes to a web address uses this exact ending (Meta fills in the braces):

```
utm_source=meta&utm_medium=paid_social&utm_campaign={{campaign.name}}&utm_id={{campaign.id}}
&utm_term={{adset.id}}&utm_content={{ad.id}}
```

- `meta` and `paid_social` never vary, because GA4's Meta link needs one exact source and medium.
- A campaign's name doesn't change after it starts. Suggested shape:
  `cas_<platform>_<goal>_<audience>_<yyyymm>`, for example `cas_ios_trial_us-broad_202701`.
- Meta adds `fbclid` by itself. Nothing may strip it.
- App-install ads go to the store, so they carry no address labels. Android gets the referrer; iOS
  gets Meta's totals.
- A small page in the admin (or a script) builds and checks links, so nobody types them by hand.

## 7. What Meta is told

| What happened | Meta event | Sent by | Money |
|---|---|---|---|
| App installed or opened | Install / Activate app | Meta SDK on the device | none |
| Joined the waitlist (from an ad click) | Lead | Server, web | none |
| Account created | Complete Registration | Server | none |
| First real use (`first_value`) | Complete Tutorial | Server | none |
| Trial started | Start Trial | Server | 0 |
| First paid charge of a subscription, including a trial that converts | Subscribe | Server | Gross, USD |
| Every later charge, and credit packs | Purchase | Server | Gross, USD |
| Refund or chargeback | Not sent (Meta takes no negative amounts) | Our record only | Negative, in our report |

Nothing else goes to Meta: no screens, no feature use, no bot, chat, workspace or content data.
Subscribe and Purchase never overlap, so their values add up to total revenue. The exact wire names
are confirmed against Meta's payload helper in Phase 0.

## 8. Privacy, consent and store forms

### 8.1 Who gets what

| Case | What reaches Meta |
|---|---|
| iPhone or iPad, no tracking permission (everyone in v1) | Anonymous id, app and device details, the events in §7, flagged as "tracking not allowed" |
| Android, switch on | The same, plus the install referrer, the IP address, and the advertising ID if Decision 3 is yes |
| Web visit that arrived with a Meta click id | Click id, IP address, browser, the events in §7 |
| Switch off; workspace analytics off; EEA, UK or Switzerland before a consent prompt exists; Global Privacy Control or Do Not Track; self-hosted server; community build; Mac, Windows, Linux, watch | **Nothing** |

No email goes to Meta in v1, hashed or not (Decision 4). On iOS Apple forbids it without the
tracking prompt; elsewhere it is allowed but not needed to start.

### 8.2 The switch

- A new switch in Settings → Privacy, next to "Share usage data": **"Help measure our ads"**, with
  one line saying what it does. On by default where the law allows, off and not offered where it
  isn't yet (Decision 6).
- It is its own switch because sharing with an ad company is a different thing from our own
  analytics, and US state laws want a clear way to say no to it. Turning off "Share usage data"
  also turns this off.
- The server keeps the choice, as it does for the analytics switch, and checks it at delivery.

### 8.3 Regions

- **EEA, UK and Switzerland: off** until a proper consent prompt exists. Ads don't target those
  countries at first (Decision 5). A consent prompt is a later, separate piece of work.
- **United States:** the switch is the "do not share" control, and the site honours Global
  Privacy Control. A person in a state on Meta's list who opts out sends nothing at all, which is
  stricter than Meta's Limited Data Use flag.

### 8.4 Documents and forms that change with the code

| Where | Change |
|---|---|
| `site/privacy.html`, `docs-site/guide/privacy.md` | A new "Measuring our ads" part; Meta in the processors table; the switch and the browser signals; a clear "we don't show ads in Casama" next to "we tell Meta when someone who saw our ad joins or pays"; the sentences in §1.5 reworded so each stays true (health data and Google user data still never go to any ad company) |
| App Store privacy label | Add the purpose **Developer's Advertising or Marketing** to Device ID, Product Interaction and Purchase History. "Tracking" stays no while there's no tracking prompt (see the risk in §16) |
| `PrivacyInfo.xcprivacy` (Runner) | The same purposes; `NSPrivacyTracking` stays false |
| Play Data safety | Device or other IDs, App interactions and Purchase history: **shared**, for advertising or marketing. Advertising ID declaration: yes, for advertising, if Decision 3 is yes |
| `AndroidManifest.xml` | Meta's keys and "off until allowed" flags; the `AD_ID` permission comes back if Decision 3 is yes (D-397's note changes) |
| `Info.plist` (iOS) | Meta's app id, client token and name, and the "off until allowed" flags |
| `client/store/README.md` | The form answers above, as it has for Crashlytics |
| `docs/COSTS.md`, `docs/ARCHITECTURE.md`, `CHANGELOG.md` | The usual |

The forms must be updated before the build that contains the Meta SDK goes to review.

## 9. Reports and the daily check

**The report** (a script first, `scripts/ads-report.mts`; an admin page later, Decision 12). Per
day, campaign, ad set and ad:

- from Meta's Marketing API: spend, impressions, clicks, and what Meta itself attributes;
- from our record: waitlist joins, sign-ups, first uses, trials, new subscribers, renewals, gross,
  proceeds, refunds;
- worked out: cost per sign-up and per subscriber, and return on spend on proceeds less refunds.

"Meta says" and "we counted" are separate columns, and each row shows what share of new people had
a known source. For iOS app-install ads the per-campaign people numbers are Meta's.

**The daily check** (a worker job; a failed check raises an alert):

1. Every paid billing change has exactly one conversion row, and every conversion row has a billing
   change behind it.
2. Every conversion older than a day is "sent" or "skipped with a reason" for each tool. None stuck.
3. What we sent Meta equals what Meta says it received, within 2%.
4. Our store gross equals RevenueCat's for the day. Our Dodo gross equals Dodo's.
5. GA4's purchase revenue is within 5% of ours (GA4 hides small numbers).
6. No sandbox, staff or review purchase was sent to production.
7. No conversion has a zero, negative or implausible amount, or a currency other than expected.
8. The share of new sign-ups with an unknown source hasn't jumped.

## 10. Edge cases

| Case | What happens |
|---|---|
| Reinstall | Meta counts one install in 90 days. Our install id is new; the person is the same after sign-in |
| Several devices | Each is an install. The acquisition is the person's, frozen at sign-up |
| Team workspace | A purchase is credited to the buyer; the creator when the buyer isn't known |
| Restore or transfer | No conversion |
| Upgrade or plan change | A conversion for the charge actually made, from RevenueCat's or Dodo's amount |
| Trial that never converts | Start Trial only |
| Refund, chargeback | In our record and report; not sent to Meta |
| Arrived from a forum post, then later from a Meta ad | Both are touches; the ad click in the last 7 days gets the credit, the forum stays in the history |
| Instagram or Facebook in-app browser | Usually no referrer, but the ad's `fbclid` and `utm_*` are in the address, so the ad still gets the credit |
| Search engine visit | Only the engine's host (`www.google.com`), never the search words; medium `organic_search` |
| Sign-up on the web, install later | The acquisition is already frozen. Meta may still count an install from the SDK |
| Ad seen on a phone, sign-up on a computer | Unknown in our record, unless the waitlist address links them |
| Switch turned off later | Nothing more is sent. Events already sent can't be recalled |
| Account deleted | Our rows go (§6.2). Meta holds no account id of ours and no email, so there's nothing to erase by person |
| Meta is down | Retries for 7 days, then skipped as `too_old` and flagged |
| App Review, TestFlight, staff | Sandbox goes to the test dataset; staff accounts are on a skip list |

## 11. Cost

| Item | Cost |
|---|---|
| Meta SDK, Conversions API, Marketing API | $0 |
| GA4 and its Meta link | $0 |
| PostHog Marketing analytics | Beta; price not stated. Check before turning on |
| RevenueCat | Unchanged (1% of tracked store revenue; no new feature fee) |
| A measurement partner (AppsFlyer, Adjust, Singular) | Not used (Decision 10) |
| Server | One small job a minute and four small tables |
| **Ad spend** | New. Needs a monthly cap and an owner (Decision 16) |

`docs/COSTS.md` gets an "Ads" line with the cap, and a note on how long a subscriber takes to pay
back what they cost. The store's fee (15% to 30%) and RevenueCat's 1% come out before that sum.

## 12. Testing

- **Unit tests** for the sender against a recording fake: the payload for app and web events, the
  16 device fields in order, the tracking flag, the fixed ids, the 7-day rule, batching and retry.
- **Tests for every reason to skip** (§8.1, §6.4), each proving nothing leaves.
- **pgTAP** for the four tables (RLS, worker access, the crediting function, deletion).
- **Contract tests:** new routes on the security list; catalog entries for the new events.
- **Flutter tests:** the SDK never starts when any gate is closed; other platforms never call it.
- **Meta's test dataset:** a sandbox purchase on a real iPhone and a real Android phone, and a web
  join, each seen in Events Manager with the right name, id and amount.
- **Duplicate test (before Phase 4):** the same event from the SDK and the server with one id
  shows once in Meta.
- **A tracer run before spending:** one small real ad per route in §6.3. Follow one person through
  each: the touch, the acquisition, the conversion, Meta, GA4, PostHog, RevenueCat, the report.
- The full suites through `scripts/heavy.sh` before each push.

## 13. Rollout

### Phase 0: accounts and checks (1 day, mostly Oliver's)

- Answer §15.
- Create the Meta pieces in Appendix A. Save every key to Vaultwarden.
- Finish GA4's open items (GA4-PLAN).
- Check the facts the docs leave open: the wire names of the events; that RevenueCat's transactions
  endpoint returns each charge for both stores (one sandbox purchase each); whether Meta's Android
  SDK reads the install referrer itself; that Meta treats server events from people without
  tracking permission as eligible for aggregated measurement.

**Done when:** the keys are in the vault, GA4 receives events, and the open facts are written into
this plan.

### Phase 1: our own record (3–4 days)

Tables; the install record; touches from the web (landing labels and the referring host name), the
waitlist, Android's referrer, invites and referrals; the crediting rule; money on purchases; conversions written by billing, sign-up, first
use and the waitlist; `acq_*` in GA4 and PostHog; the "how did you hear" question; the `/get` fix.
Nothing goes to Meta yet.

**Done when:** a test sign-up through a labelled link shows its source on the account, a test join
that arrived from another site with no labels shows that site as its source, and a test
purchase has a conversion row with the right money.

### Phase 2: the web to Meta (2 days)

The sender, the delivery job, web events, the region and signal rules, the privacy page.
**This is all that ads to the waitlist need.**

**Done when:** a join through a test ad link shows as a Lead in Meta's test dataset, once, and a
join without a click id sends nothing.

### Phase 3: the apps to Meta (3–4 days, plus store review)

The SDK with its gates; the switch; app events from the server; the Android referrer decrypted;
store forms; RevenueCat source fields. Then an app build (ask first) and review.

**Done when:** a sandbox purchase on each phone shows once in Meta's test dataset with the right
amount, and with the switch off nothing leaves the phone or the server.

### Phase 4: reports and the daily check (2–3 days)

Spend from Meta; the report; the eight checks; GA4's Meta link and PostHog's Marketing analytics;
then, after the duplicate test, the on-device copies for SKAdNetwork.

**Done when:** the tracer run in §12 passes on every route and the daily check is green for a week.

### Phase 5: review after four weeks of ads

Look at Meta's match quality, the share of unknown sources, and iOS results. Then decide: a
tracking prompt on iOS; hashed email on Android and the web; a consent prompt for Europe; a
measurement partner; a copy of Apple's SKAdNetwork postbacks to our own server.

## 14. What this plan leaves out

- Making the ads, the audiences and the budgets day to day.
- Google Ads, TikTok, Apple Search Ads. The design takes them as new destinations later.
- Retargeting and custom audiences (they need email or ad ids, and a consent story).
- A consent prompt for Europe.
- The other Stackwares apps. One Meta business portfolio can hold them, each with its own app,
  dataset and ad account.

## 15. Decisions for Oliver

| # | Question | Default |
|---|---|---|
| 1 | Who sends purchases to Meta: our server, or RevenueCat's forwarder? (§5) | Our server. RevenueCat's forwarders to Meta and Firebase stay off |
| 2 | Show Apple's tracking prompt on iPhone and iPad? | No in v1. Decide again in Phase 5 with real numbers |
| 3 | Let Meta have the Android advertising ID? It reverses part of D-397 for Meta only, and makes Android attribution much better | Yes, for Meta only, and only while the switch is on |
| 4 | Send hashed email to Meta (never on iOS without the prompt)? | No in v1 |
| 5 | Europe (EEA, UK, Switzerland): nothing to Meta and no ads there until a consent prompt exists? | Yes |
| 6 | A separate "Help measure our ads" switch, on by default where allowed? | Yes |
| 7 | Which amount goes to Meta and GA4: gross, or after store fees? | Gross, in USD. Our report uses proceeds less refunds |
| 8 | The event map in §7 (first charge = Subscribe, later charges and packs = Purchase, first use = Complete Tutorial)? | As written |
| 9 | Add the skippable "How did you hear about us?" tap to onboarding? | Yes |
| 10 | Use a paid measurement partner now? | No. Look again when a second ad network starts |
| 11 | One Stackwares business portfolio for all apps, with a Casama ad account, app and dataset? Ad account in USD, in a time zone that stays on UTC (so Meta's days match ours)? | Yes to both, if Meta's list offers such a zone |
| 12 | The report: a script first, or an admin page from the start? | A script first |
| 13 | Timing: will ads run to the waitlist before the 12 January launch, or only app-install ads after it? And should the first public app build wait for Phase 3? | Build in the order of §13, which serves both. The first public build should contain Phase 3, so app-install ads can start without a second review |
| 14 | May I turn on PostHog Marketing analytics and GA4's Meta link (changes to those projects)? | Yes |
| 15 | On-device copies for SKAdNetwork, and Apple's postback copies to our server? | The first in Phase 4 after the duplicate test; the second in Phase 5 |
| 16 | The monthly ad budget cap, and who pays | Open: a number is needed for `docs/COSTS.md` |

## 16. Risks and open questions

- **Apple's wording on SDKs is strict** (§2.2). Many apps ship the Meta SDK with no tracking
  prompt and a "no tracking" label, relying on Meta treating those events in aggregate. Apple
  could read it differently in review. If it does, the choices are a tracking prompt or SKAdNetwork
  only. This is Oliver's call; the plan takes the common reading and sends as little as possible.
- **Meta sees less on iOS without the prompt**, so iOS campaigns learn more slowly and report
  later. Phase 5 revisits it.
- **The privacy promise changes.** "No ads" stays true inside the product, but Casama starts
  sharing data with an ad company. The wording has to be exact, and it's a public change for a
  product that sells on privacy and self-hosting.
- **The Meta SDK isn't open source.** Community builds leave its keys out, so it never runs, but
  the code is linked into the iOS and Android apps, as Firebase's already is.
- **Two senders with one id** (Phase 4) rests on Meta's dedupe. It ships only after the duplicate
  test, and a remote setting can turn the on-device copies off.
- **Numbers will never match exactly** between Meta, GA4, PostHog and our record: different
  windows, time zones, aggregation and thresholds. Our record is the number of record; the daily
  check sets how far apart is still fine.
- **Session storage for landing labels and the referring host** is storage on the visitor's device. It isn't used in
  Europe under Decision 5 and is named on the privacy page.
- **Business verification and ad account review at Meta can take days**, and new ad accounts
  often start with spend limits.
- **Open:** whether RevenueCat's `gross` is before or after tax in practice (Phase 0, one sandbox
  purchase per store); the price of PostHog Marketing analytics; whether Meta's newer install
  referrer (read from the Facebook and Instagram apps) is needed on top of Play's.

## Appendix A: Meta setup checklist (Phase 0)

Search Vaultwarden first; save each key as "Casama · Meta …" in "Keys & Signing".

1. Business portfolio (Decision 11), with the Casama Page and Instagram account added, two-factor
   sign-in on, and business verification started.
2. Ad account: USD, the chosen time zone, a payment method, a spend limit.
3. Meta app "Casama" (type Business):
   - iOS: bundle id `ai.casama.app`, App Store id 6833509960.
   - Android: package `ai.casama.app`, the main activity's class, the key hashes of **both** the
     upload key and Play's app signing key.
   - Note the app id and client token.
   - Link the ad account to the app.
   - Set "Log in-app events automatically" to **No**.
   - Copy the Install Referrer Decryption Key.
4. Dataset "Casama", linked to the app; a Conversions API token.
5. Dataset "Casama test" with its own token, for sandbox.
6. Verify the domain casama.ai in the business settings.
7. A system user with read access to the ad account, and its token, for spend.
8. In Events Manager, set up the SKAdNetwork events once the app is linked.
9. Server env names (values only in the vault and the VPS `.env`): `AD_DESTINATIONS`,
   `META_APP_ID`, `META_DATASET_ID`, `META_CAPI_TOKEN`, `META_TEST_DATASET_ID`,
   `META_TEST_CAPI_TOKEN`, `META_INSTALL_REFERRER_KEY`, `META_AD_ACCOUNT_ID`, `META_ADS_READ_TOKEN`.
   App: `META_APP_ID`, `META_CLIENT_TOKEN` in `client/config/telemetry.json` and the
   `CASAMA_TELEMETRY_JSON` repo secret.

## Appendix B: sources (read 2026-11-20)

- RevenueCat, Meta Ads integration and its event reference:
  https://www.revenuecat.com/docs/integrations/attribution/meta-ads ·
  https://www.revenuecat.com/docs/integrations/attribution/reference/meta-ads
- RevenueCat staff on SKAdNetwork next to server events (July 2026):
  https://community.revenuecat.com/third-party-integrations-53/how-to-handle-meta-ads-skan-revenuecat-for-ios-subscriptions-server-to-server-vs-on-device-conflict-7761
- RevenueCat, Firebase integration, customer attributes, webhooks, API v2, pricing:
  https://www.revenuecat.com/docs/integrations/third-party-integrations/firebase-integration ·
  https://www.revenuecat.com/docs/customers/customer-attributes ·
  https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields ·
  https://www.revenuecat.com/docs/api-v2 · https://www.revenuecat.com/pricing
- Meta, Conversions API for app events, app data, using the API, `fbc` and `fbp`, customer
  information, dedupe:
  https://developers.facebook.com/docs/marketing-api/conversions-api/app-events ·
  https://developers.facebook.com/docs/marketing-api/conversions-api/parameters/app-data ·
  https://developers.facebook.com/docs/marketing-api/conversions-api/using-the-api ·
  https://developers.facebook.com/docs/marketing-api/conversions-api/parameters/fbp-and-fbc ·
  https://developers.facebook.com/docs/marketing-api/conversions-api/parameters/customer-information-parameters ·
  https://developers.facebook.com/docs/marketing-api/conversions-api/deduplicate-pixel-and-server-events
- Meta, aggregated measurement for iOS apps, SKAdNetwork limits, install referrer, tracking flag,
  data processing options:
  https://developers.facebook.com/docs/app-events/guides/aggregated-event-measurement/ ·
  https://developers.facebook.com/docs/app-ads/SKAdNetwork-aem-and-limitations/ ·
  https://developers.facebook.com/docs/app-ads/install-referrer/ ·
  https://developers.facebook.com/docs/app-events/guides/advertising-tracking-enabled ·
  https://developers.facebook.com/docs/marketing-apis/data-processing-options
- The Flutter plugin: https://pub.dev/packages/facebook_app_events
- Apple, tracking and privacy labels:
  https://developer.apple.com/app-store/user-privacy-and-data-use/ ·
  https://developer.apple.com/app-store/app-privacy-details/
- Google Play, advertising ID: https://support.google.com/googleplay/android-developer/answer/6048248
- GA4, campaign data import and Meta Links: https://support.google.com/analytics/answer/10071301 ·
  https://support.google.com/analytics/answer/16536051
- Firebase consent settings for apps: https://developers.google.com/tag-platform/security/guides/app-consent
- PostHog Marketing analytics: https://posthog.com/docs/web-analytics/marketing-analytics

Meta's two Help Centre pages on aggregated measurement would not load for reading, so the iOS
points in §2.1 come from Meta's developer guide and RevenueCat's staff answers. Phase 0 confirms
them in Events Manager.
