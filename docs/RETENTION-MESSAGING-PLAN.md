# Retention messages on the App Store's cancel screen (iOS, iPadOS, macOS): plan

Status: **waiting for Oliver's answers** (§14). Written 2026-11-20. No code, store or dashboard change
has been made. When this is approved, record it as a decision in `docs/DECISIONS.md` (check the
highest number first; it was D-431 on 2026-11-20).

## Execution brief (read this first)

**Goal:** when someone who pays through the App Store starts to cancel, Apple's Confirm Cancellation
screen shows a reason to stay from Casama: a short message, a cheaper plan to switch to, or an
offer. It covers the iPhone and iPad app and the Mac App Store build.

**Route (Decision 1):** RevenueCat runs the real-time endpoint and the messages. App Store Connect's
own retention messages are the fallback for when Apple can't reach RevenueCat. We write no server
endpoint of our own (§5).

**Order:** Phase 0 can start now. Phase 1 waits for the 1.0 release. Phase 2 waits for Apple to
grant access. Phase 3 is optional follow-up (§12). Each phase ends at its "Done when" check.

**Rules (as for every Casama task):**
- Every change customers can see is a production change: App Store Connect submissions, Apple's
  access form, RevenueCat production messages, promotional offers. Each one needs Oliver's yes
  first, and a yes covers only that step (AGENTS.md, "Production").
- Only the account holder (Oliver) can send Apple's access request form.
- Any Flutter build in Phase 3 needs its own yes. No store uploads unless Oliver asks.
- Keys: reuse the existing ones (§8.1). No new key is needed for Phases 0 to 2. If Phase 3 adds a
  RevenueCat write key, search Vaultwarden first and save the new key there in the same task.
- Commits: stage by path, through a private index (see memory "Stage by path"). Never `git add -A`.
- Targeted tests while working, then the full suites once through `scripts/heavy.sh` (only for
  Phase 3 code).

---

## 0. Summary

- Apple's **Retention Messaging API** lets an app choose what the Confirm Cancellation screen shows.
  That screen appears after someone taps **Cancel Subscription** on a subscription's details page,
  in Settings > Apple Account > Subscriptions or in the App Store. Apple calls our chosen endpoint
  in real time, and we answer with a message we uploaded earlier and Apple approved.
- There are four kinds of message: **text**, **text with an image**, **switch plan** (text plus
  another subscription in the same group) and **promotional offer** (text plus a signed discount).
  Only text messages, with or without an image, can be default messages.
- Messages show on **iOS 15.1+, iPadOS 15.1+, visionOS 1+ and macOS 14+**. That covers the App Store
  builds of Casama. The direct Mac download and the web pay through Dodo, and Android pays through
  Google Play, so neither is touched by this plan (§11.6).
- Since D-297, every App Store purchase goes through RevenueCat. RevenueCat already runs this
  endpoint for its customers: it handles Apple's 700 ms deadline, request checks, offer signing,
  per-language submission to Apple, audience rules and experiments. **Recommendation: use
  RevenueCat**, and add one text message per plan in App Store Connect as the fallback.
- **Blockers:** (1) Casama 1.0 isn't on the App Store yet (iOS and macOS 1.0 are still
  `PREPARE_FOR_SUBMISSION`, and the six subscriptions are `READY_TO_SUBMIT`). Messages only matter
  once people subscribe, and Apple's access form asks whether the app "currently has a
  subscription on the App Store". (2) The real-time API is still a **pre-release** that Apple has
  to grant.
- **What we can do before launch:** write and approve the copy, decide on offers, create the
  promotional offers in App Store Connect, check our RevenueCat plan, and prepare the App Store
  Connect fallback messages without submitting them.
- **Costs:** no new vendor, and RevenueCat bills by revenue as it already does. The real cost is
  revenue given up on discounts, which §9 caps and `docs/COSTS.md` records.
- **Expectations:** RevenueCat's benchmark across 309 apps (March to September 2026) found a
  median save rate of **16.7%**. Offer acceptance was about **1.1%** for promotional offers and
  **0.6%** for plan switches. It found no clear effect on overall cancellation rates. The text
  message does most of the work. Discounts get accepted rarely and can teach people that starting
  to cancel gets them a lower price.

---

## 1. What exists today (checked 2026-11-20)

### 1.1 Store and billing setup

| Item | State |
|---|---|
| App Store record | "Casama AI", Apple ID **6833509960**, bundle `ai.casama.app` (iOS + macOS) |
| Versions | iOS 1.0 and macOS 1.0 both `PREPARE_FOR_SUBMISSION`; App Store preflight work done (D-418..D-422) |
| Subscription group | "Casama" **22574241**, one group for every plan (D-249 relies on this: iOS plan changes need nothing) |
| Group levels | Max = 1, Pro = 2, Plus = 3 (Apple treats level 1 as the top) |
| Products | `ai.casama.{plus,pro,max}.{monthly,yearly}`, all `READY_TO_SUBMIT` |
| Prices (D-249) | Plus $15 / $150 yr, Pro $49 / $490 yr, Max $99 / $899 yr |
| Intro offers | Pro monthly and Pro yearly: 1-week free trial. No others |
| Promotional offers | **None** on any subscription |
| Win-back offers | None |
| Retention messages in App Store Connect | None (`GET /v1/apps/6833509960/retentionMessages` → 0) |
| RevenueCat | Project "Casama" `proj864b35e1`; App Store app with In-App Purchase key **HW9SYD2XPL** and App Store Connect key **CC7KG77GYT**; App Store Server Notifications (production and sandbox) point at RevenueCat (D-297) |
| RevenueCat plan | Self-serve, free to $2,500 of monthly tracked revenue then 1% (`docs/COSTS.md`). Which tier exactly, and whether it includes retention experiments, isn't confirmed (§13) |
| Apple fees | 15% under the Small Business Program (`docs/COSTS.md`) |

### 1.2 Server

- `apps/server/src/billing/revenuecat.ts` turns RevenueCat webhooks into subscription snapshots.
  It never trusts the webhook body: it re-reads the customer through the v2 REST API with a
  **read-only** key. `auto_renewal_status === "will_not_renew"` maps to `cancel_at_period_end`.
  A cancellation with `cancel_reason: CUSTOMER_SUPPORT` counts as a refund.
- `apps/server/src/billing/service.ts` (`applySnapshot`) sends the "renewal turned off" email when
  `cancel_at_period_end` turns true (D-302). Monthly credits follow the **plan**, not the price
  paid, so a discounted month still gets the full allowance.
- `apps/server/src/billing/analytics.ts` (`subscriptionChange`) emits `started`, `trial_started`,
  `trial_converted`, `renewed`, `recovered`, `grace`, `cancelled`, `expired`, `refunded` and
  `plan_changed`. **There's no event when renewal is turned off or back on.** We can see a plan end
  but not "pressed cancel, then kept it", which is exactly what this feature changes (§10.2).
- Downgrades (D-248): the workspace keeps everything, and only the plan's number of bots and hosted
  computers run, oldest first.

### 1.3 App

- Billing > **Manage Subscription** (`client/lib/features/billing/billing_screen.dart`, `_manage`)
  opens the remote link `manage_subscription_app_store`, which defaults to
  `https://apps.apple.com/account/subscriptions`, in the browser. It doesn't use StoreKit's in-app
  manage sheet. RevenueCat's testing guide assumes an in-app sheet (`showManageSubscriptions()`).
  The URL works for a real cancel, but the in-app sheet is smoother and easier to test (§8.5,
  Phase 3).
- The app is English only in v1.

### 1.4 Docs that mention cancelling

- `docs-site/faq.md` ("How do I cancel?", lines ~197–205) and `docs-site/guide/usage.md` (~273).
  The FAQ says "Settings > Apple ID > Subscriptions". Apple renamed it **Apple Account**, so fix
  that while we're there.
- The Casama Help system prompt (D-298) holds store-cancelling facts.

### 1.5 Found along the way (not retention, but worth fixing)

- `site/privacy.html` names "Apple, Google or Dodo Payments" but not **RevenueCat**, which has
  handled store purchases since D-297. Retention messaging adds no new data. The gap is older than
  this plan.
- Max yearly: an older note says Apple's US price list stopped at $1,000 and left Max Yearly
  unpriced at $1,490. D-249 lowered it to $899. Check that `ai.casama.max.yearly` has a price in
  every territory before 1.0, because a switch-plan or offer can't point at an unpriced product.

---

## 2. What Apple offers (facts this plan relies on)

From Apple's Retention Messaging docs (changelog up to **1.6, 2026-11-04**) and the App Store
Connect API guide. The full endpoint list is in Appendix A.

### 2.1 Where and when the message shows

- Someone with an active subscription opens its details page and taps **Cancel Subscription**.
  Apple then shows **Confirm Cancellation**, with a "From the developer" section and the buttons
  **Cancel Subscription** and **Keep Subscription**, plus **Switch Plan** or **Accept Offer** when
  the message has one.
- Since 1.6, Apple **always** calls the real-time URL, whether or not a default exists.

### 2.2 Which message wins (1.6)

1. The message our real-time endpoint returns. It can also be an App Store Connect message, by id.
2. The message set up in **App Store Connect** for that subscription, with its retention offer if
   any.
3. The API **default message** for that product and locale, or the closest configured locale.
4. Nothing.

### 2.3 Limits

| Field | Max |
|---|---|
| Header | 66 characters |
| Body | 144 characters |
| Image alt text | 150 characters |
| Bullet point text | 66 characters |
| Messages per app (API) | 2,000 |
| Images per app (API) | 2,000 |
| App Store Connect messages | 10 per app, at most 1 per subscription |
| App Store Connect retention offers | 10 active per subscription per `targetSubscriptionPlanType` |

- Text must be UTF-8 with no disallowed characters (`BadRequestInvalidTextFieldError`).
- Images: PNG, no transparency, and they must work in light and dark mode. Full size is 3840 px wide
  by 160–2160 px tall. Universal asset images are 5244 × 2950. Bullet icons are 1024 × 1024.
  RevenueCat's form asks for 3840 × 2160.
- Switch-plan and promotional-offer messages **can't include an image or bullets**.
- The switch-plan product must be in the **same subscription group**. All of ours are.

### 2.4 Review

- Apple reviews every uploaded message and image (`PENDING` → `APPROVED`), one locale at a time.
  In **sandbox** they're approved automatically.
- App Store Connect messages go through App Review as a `retentionMessageVersion`:
  `PREPARE_FOR_SUBMISSION` → `READY_FOR_REVIEW` → `WAITING_FOR_REVIEW` → `IN_REVIEW` →
  `ACCEPTED`/`REJECTED` → `APPROVED`. A version can't be changed after it's created. To change
  approved text, make a new version.
- Copy guidance from Apple and RevenueCat: **don't mention a price or discount** in the header or
  body. Apple shows the offer and its price itself and rejects messages that state them. No
  misleading or inaccurate claims.

### 2.5 The real-time endpoint (RevenueCat runs this for us)

- `POST` over HTTPS with TLS 1.2, answered within **700 ms** in production. It has to pass Apple's
  **performance test** in sandbox (about 700 ms; the exact limit comes back as
  `responseTimeThreshold`) before a production URL is accepted.
- The body is a JWS `signedPayload`. Its x5c chain runs from a leaf to the Apple WWDR intermediate
  (`1.2.840.113635.100.6.2.1`) to the Apple root. Decoded, it holds `originalTransactionId`,
  `appAppleId` (must match ours), `productId`, `userLocale`, `requestIdentifier`, `environment` and
  `signedDate`.
- The response picks one of these: `message`, `alternateProduct` (switch plan, plus
  `billingPlanType` since 1.5), `promotionalOffer` (with a V2 JWS or V1 signature) or
  `advancedCommerceInfo`.
- Rate limits on the management API are 1 request per second per endpoint (Configure Default
  Message: 10/s), enforced hourly, and 10% of that in sandbox.

### 2.6 Promotional offers versus App Store Connect retention offers

These are two different things:
- **Promotional offers** (Subscriptions > a subscription > Promotional Offers) are what the
  **real-time API and RevenueCat** sign and present.
- **Retention offers** (App Store Connect API `retentionOffers`) belong only to **App Store Connect
  messages**. They need 1–60 months of paid subscription to be eligible, an optional 2–24 month
  wait between offers, and are not available during a free trial.

---

## 3. What we want

1. Fewer App Store subscribers lost at the moment they cancel, without training people to cancel for
   a discount.
2. People who are paying for more than they need move **down** (Max → Pro, Pro → Plus) instead of
   leaving.
3. Honest copy: what actually stops on Free, never a scare.
4. Numbers we can trust: exposures, saves, plan switches and offer uptake, and whether churn
   actually falls.

## 4. Principles

- **Accurate to the plan.** The copy describes what really changes on Free (D-249 limits). Avoid
  numbers that Admin → Pricing can change. If a message quotes a limit, a pricing change has to
  update the message too (§11.4).
- **Text first, discounts sparingly.** One guarded offer at most, only on monthly plans, only for
  people who have paid for a while and haven't had one recently (§9).
- **One source of truth.** RevenueCat picks the message. App Store Connect holds only the fallback,
  so nobody edits the same thing in two places.
- **No new server surface.** No new public endpoint, key or Apple certificate code (D-297 removed
  those on purpose).
- **No personal data in messages.** Copy is fixed and approved in advance. No names and no account
  data.

---

## 5. Options and recommendation (Decision 1)

| | A. RevenueCat (**recommended**) | B. App Store Connect only | C. Our own endpoint |
|---|---|---|---|
| Message kinds | All four | Text (image via Asset Library) + retention offer | All four |
| Picks per person | Audience rules: spending, first purchase, custom attributes, last offer redeemed, storefront, offer/trial period | One message per subscription | Anything in our database |
| A/B tests | Yes (experiments, plan tier to confirm) | No | Build it ourselves |
| Apple access | Needed | **Not needed** | Needed |
| Our code | None | None (API calls through `asc`) | Endpoint, JWS checks, offer signing, Apple management client, 700 ms budget, perf test |
| Ops risk | RevenueCat outage → fallback | None | Our API's latency and uptime become Apple's problem |
| Cost | Inside current RevenueCat pricing | Free | Our time, plus brings back what D-297 removed |

**Recommendation: A, with B as the fallback layer.** Apple's precedence (§2.2) makes the two work
together. RevenueCat answers in real time. If that fails, Apple shows the App Store Connect message
before any API default. B is also the only route open **before** Apple grants access, so it's the
bridge at launch (Phase 1).

C only makes sense if we later want messages chosen from Casama-only data that RevenueCat custom
attributes can't carry. Its design is sketched in Appendix B so the option stays open.

---

## 6. The messages

### 6.1 Set

| # | Name (reference) | Where | Kind | Audience | Shows |
|---|---|---|---|---|---|
| M1 | `default-plus` | RevenueCat default + App Store Connect fallback | Text | Plus monthly/yearly | What Plus keeps running |
| M2 | `default-pro` | RevenueCat default + App Store Connect fallback | Text | Pro monthly/yearly | What Pro keeps (bots, people, hours) |
| M3 | `default-max` | RevenueCat default + App Store Connect fallback | Text | Max monthly/yearly | What Max keeps |
| M4 | `switch-max-to-pro` | RevenueCat real-time | Switch plan → Pro, same period | Max subscribers | "Need less? Keep going on Pro" |
| M5 | `switch-pro-to-plus` | RevenueCat real-time | Switch plan → Plus, same period | Pro subscribers **not** in a free trial (Decision 4) | "Need less? Keep going on Plus" |
| M6 | `offer-monthly` *(if Decision 3 = yes)* | RevenueCat real-time | Promotional offer on the same plan | Monthly subscribers with ≥ 2 paid months, no promotional offer in the last 6 months, not in any offer period | "An offer to stay" |
| M7 | `trial-pro` | RevenueCat real-time | Text | Pro in its free trial | What the trial week unlocks; no offer, no switch |

Selection in RevenueCat: when several real-time messages fit, **the one created first wins**. So
create them in this order: M7 (trial) → M6 (offer, narrowest) → M4 / M5 (switch) → defaults. Plus
has no cheaper plan to switch to (Free isn't a product), so Plus gets M1 or M6.

### 6.2 Draft copy (English; header ≤ 66, body ≤ 144)

Character counts include spaces. They were checked with a script when this plan was written.

| # | Header | Body |
|---|---|---|
| M1 | Keep your bots working for you (30) | On Free, most of your bots pause and check-ins slow down. Plus keeps your routines, briefs and errands running. (111) |
| M2 | Your bots and your team, still in step (38) | Pro keeps every bot running, room for more people and more computer time. Cancel and the extras pause when this period ends. (124) |
| M3 | Keep the room your work needs (29) | Max keeps the most bots, people and computer time running at once. Your chats and files stay either way. (104) |
| M4 | Need less? Keep going on Pro (28) | Switch instead of leaving: your bots, chats and routines carry over, and you can move back up any time. (103) |
| M5 | Need less? Keep going on Plus (29) | Switch instead of leaving: your bots, chats and routines carry over, and you can move back up any time. (103) |
| M6 | Before you go, an offer to stay (31) | Keep your bots, routines and chats running just as they are. You can still cancel whenever you like. (100) |
| M7 | Your Pro week is just getting started (37) | Try a routine or a check-in before you decide. Your bots keep working until the trial ends either way. (102) |

Rules for editing these: no prices, discounts or "free"; no "you'll lose everything" (on Free you
keep your chats and files, per D-248); "bots", "routines", "check-ins" and "computer time" match
the app's own words.

### 6.3 Languages (Decision 5)

The app is English only. Apple uses the closest configured locale when the exact one is missing,
but a RevenueCat community report (June 2026) had a default message that never showed in
production while only en-US was filled. **Recommendation:** fill the same English text into every
locale RevenueCat lists, rather than machine translations of an app that's in English. Then check
in sandbox from a non-English storefront (§8.5). Translations come with the app's localization
work, not before.

### 6.4 Images (optional, Phase 3)

Text-only for v1. If an image helps M1–M3 later: 3840 × 2160 PNG, no transparency, readable on
light and dark, with original app art (not stock), made with `codex/gpt-6-luna` per AGENTS.md and
checked before upload. Alt text ≤ 150 characters.

---

## 7. App Store Connect fallback messages (route B layer)

- Three App Store Connect messages, M1–M3. Each is assigned to that plan's monthly and yearly
  subscriptions, which uses 3 of the 10 allowed per app.
- **No App Store Connect retention offers** (Decision 3b). A fallback with a discount would hand
  discounts to everyone whenever RevenueCat is down.
- Done through the API with the existing key, in this order: create the message
  (`POST /v1/retentionMessages`, `referenceName` ≤ 64 characters and fixed once created), then the
  version (`POST /v1/retentionMessageVersions`, no `placement` because it's text only), then the
  en-US localization (`POST /v1/retentionMessageLocalizations`), then assign it to each subscription
  (`PATCH /v1/subscriptions/{id}/relationships/retentionMessage`), then submit
  (`POST /v1/reviewSubmissionItems` with the version).
- Submit **after** 1.0 is approved, as its own review submission, so it can't hold up or complicate
  the app's first review.

---

## 8. Setup with RevenueCat

### 8.1 Keys and accounts (nothing new)

- App Store Connect API key **CC7KG77GYT** (issuer `69a6de87-…`, p8 at `~/private_keys`, in
  Vaultwarden): App Store Connect messages, promotional offers, checks. `asc` needs the
  `ASC_KEY_ID`/`ASC_ISSUER_ID`/`ASC_PRIVATE_KEY_PATH` env vars (keychain reads hang in agent
  sessions).
- In-App Purchase key **HW9SYD2XPL**, already in RevenueCat. RevenueCat uses it to sign
  promotional offers.
- RevenueCat dashboard: Oliver's account. The server's v2 key stays read-only.
- A **sandbox tester** Apple Account for the performance test and device checks. Search Vaultwarden
  for an existing Casama sandbox tester first, and save a new one there if needed.

### 8.2 Apple access (Oliver)

Form: `https://developer.apple.com/contact/request/retention-messaging-api/`, sent by the account
holder. It asks for:
- App name: Casama AI
- Apple ID: 6833509960
- Endpoint URL: copied from RevenueCat (App Store app settings page)
- Confirmation that the app "currently has a subscription on the App Store". Send it only once 1.0
  is live and that's true.

### 8.3 RevenueCat dashboard (Lifecycle → Retention → Apple Retention Messaging API)

1. **Sandbox realtime URL**: connect it.
2. **Performance test**: needs an **active sandbox or TestFlight subscription** (not a `.storekit`
   file). It can take up to an hour, and the subscription must stay active the whole time. Buy
   **Max yearly** with the sandbox tester, and set that tester's subscription renewal rate to the
   slowest option in App Store Connect (Users and Access > Sandbox) so it doesn't lapse mid-test.
   If it fails, start it again by hand.
3. **Default messages** (sandbox): M1, M2, M3, each with its two products and the English text in
   every locale (§6.3).
4. **Real-time messages** (sandbox), in creation order M7, M6, M4, M5 (§6.1). Each one has a single
   **active product**, so a message for "Pro monthly and Pro yearly" is two entries. Switch plans
   keep the period: Max monthly → Pro monthly, Max yearly → Pro yearly.
5. Test on devices (§8.5).
6. **Production realtime URL** (needs the passed test). Turn off **SANDBOX DATA** and create the
   production messages again. Nothing carries over from sandbox. Each production locale goes to
   Apple's review, so watch for "Active, with messages in review" and "Active, with rejected
   messages".
7. Leave a message **inactive** to pull it without deleting it.

### 8.4 Promotional offers (only if Decision 3 = yes)

Create one per **monthly** subscription in App Store Connect (Plus, Pro, Max), e.g.:
- Reference `stay-2mo-half`, offer id `ai.casama.<plan>.monthly.stay`
- Pay as you go, 2 months at the discounted price (Decision 3a sets the size)
- Prices for every territory through the subscription's price points

Then pick the offer in M6's "Associated offers". RevenueCat signs it with HW9SYD2XPL. Yearly plans
get no offer in v1 (§9).

### 8.5 Testing on devices

- **iPhone or iPad (TestFlight + sandbox tester):** buy a plan, then Settings > *your name* >
  Subscriptions > Casama > Cancel Subscription (or Billing > Manage Subscription in the app), then
  check Confirm Cancellation. Try every path: Keep, Switch Plan, Accept Offer, Cancel.
- **Mac (macOS 14+, Mac App Store build from TestFlight):** App Store > account > Account Settings >
  Subscriptions > Manage, or System Settings > *your name* > Media & Purchases > Subscriptions >
  Manage.
- **Matrix:** each of the 6 products; in trial and paid (Pro); a storefront outside the US and a
  non-English device language (§6.3); dark and light mode; an older OS (iOS < 15.1 or macOS < 14)
  shows nothing and must still cancel normally.
- **After each action, check the server:** Switch Plan → `plan_changed` once the change takes
  effect (Apple applies downgrades at renewal). Accept Offer → the plan stays the same, with full
  credits, and the next renewal is discounted. Cancel → `cancel_at_period_end` is true and the
  "renewal turned off" email arrives. Keep → nothing changes and no email.

---

## 9. Offers and money (Decision 3)

Monthly credits follow the plan, not the price paid, so a discount cuts revenue while costs stay the
same. Rough floor per discounted month at **50% off** (Apple 15%, RevenueCat 1%, included credits
fully used at markup 1.4, so cost ≈ credits ÷ 1.4; computer hours and server share left out, see
`docs/COSTS.md`):

| Plan | Price | 50% off | Net after Apple + RevenueCat | Included credits cost | Left |
|---|---|---|---|---|---|
| Plus monthly | $15 | $7.50 | $6.30 | $5 → $3.57 | ~$2.70 |
| Pro monthly | $49 | $24.50 | $20.58 | $15 → $10.71 | ~$9.90 |
| Max monthly | $99 | $49.50 | $41.58 | $30 → $21.43 | ~$20.10 |

A 50% offer stays above direct costs on every plan, though Plus gets thin once computer hours are
counted. Recommendation:
- **3a. Size:** 30% off for 2 months on monthly plans (keeps Plus clearly positive). 50% only if an
  experiment shows it earns more **revenue per subscriber**, not just a higher save rate. Dipsea
  saw 22.1% saves at 50% off versus 18.8% with none, but less than half the revenue per subscriber.
- **3b. Guard rails:** at least 2 paid months; no promotional offer redeemed in the last 6 months;
  not in a trial or any offer period; monthly plans only (a yearly discount gives away too much at
  once).
- **3c. No discounts in the App Store Connect fallback** (§7).
- Record the offer and its cost in `docs/COSTS.md` (a "Discounts" note under RevenueCat or Apple),
  as AGENTS.md "Paid services" requires for any price change.

---

## 10. Changes in our code (small, and optional until Phase 3)

Phases 0–2 need **no code**. These follow-ups make it measurable and smoother:

### 10.1 App: in-app manage sheet on iPhone and iPad

`_manage` for `app_store` on iOS/iPadOS opens StoreKit's manage-subscriptions sheet through
RevenueCat (`showManageSubscriptions` in `purchases_flutter`; check the exact call in the SDK
version we pin). If that fails, it falls back to the remote URL as today. macOS keeps the URL,
since the sheet is iOS only and the URL opens the App Store app. Test with
`client/test/billing_test.dart` and a fake store. Needs a Flutter build (ask).

### 10.2 Server: count "pressed cancel" and "kept it"

Add `renewal_off` and `renewal_on` to `SubscriptionChange` in
`apps/server/src/billing/analytics.ts`. They fire when `cancel_at_period_end` flips with the same
status and plan. They go to the PostHog billing events and the analytics catalog
(`packages/contracts/analytics/catalog.json`). This shows, for every store and Dodo:
- how many turn renewal off, and how many turn it back on before the period ends;
- plan switches downward (`plan_changed` with a lower plan) right after a cancel attempt.

It doesn't see exposures; those stay in RevenueCat. Tests: `apps/server/test/billing.test.ts`
(flip off, flip on, no event on re-fetch).

### 10.3 RevenueCat custom attributes (Phase 3, only if useful)

Audience rules can read custom attributes. The app could set counts like `members` (people in the
workspace), `bots_active_30d` and `routines_active` with `Purchases.setAttributes` when Billing
opens. Use cases: don't show M5 (Pro → Plus) to workspaces with more than 1 person, since Plus has
1 seat. Show a "your routines" message only to people who have routines. These are counts only,
nothing personal. If they're set from the server instead, it needs a RevenueCat **write** key (new
key → Vaultwarden, same task).

### 10.4 Emails

Check that the `plan_changed` email reads correctly for a **downgrade** (it was written as "Welcome
to Plus" for upgrades, D-302). If it would welcome someone to a smaller plan, give downgrades their
own wording. Test in `apps/server/test/billing.test.ts`.

---

## 11. Edge cases

1. **Free trial (Pro):** trial users get M7, never an offer (Apple's rules and ours) or a switch.
2. **Workspaces with several people:** switching Pro → Plus drops seats from 3 to 1. What happens
   to members past the seat count on a store downgrade isn't spelled out (the D-248 downgrade rule
   covers bots and computers only). **Settle this before M5 goes live:** either define it (members
   stay, nobody new can join) or exclude multi-person workspaces with 10.3.
3. **Family Sharing:** not enabled on our subscriptions. If it ever is, Apple doesn't send shared
   members' transactions to the performance test, and their cancel flow differs.
4. **Pricing changes in Admin:** copy that names a limit gets out of date. M1–M7 avoid numbers. Add
   "check retention copy" to the Admin → Pricing change routine in the decision entry.
5. **Plan changes across stores:** someone on Dodo or Play never sees this. Someone who cancels on
   iOS and resubscribes on the web is handled by D-297's mapping as today.
6. **Other channels (not in this plan):** Google Play has no equivalent real-time API (its
   cancellation survey and win-back offers are a separate topic). The web (Dodo portal) cancel flow
   is ours to design, and a "before you go" step there would be a separate small plan.
7. **RevenueCat down or slow:** Apple falls back to App Store Connect M1–M3 (§2.2). Nothing breaks.
8. **Refunds:** unrelated. A refund still arrives as `CUSTOMER_SUPPORT` cancellation.
9. **Counts disagree:** Apple counts a view only when at least 50% of the sheet shows, and a save
   only when the screen is dismissed. RevenueCat counts every request and treats "didn't cancel
   within 24 h" as a save. Expect RevenueCat to show more of both.

## 12. Rollout

### Phase 0: before launch (no Apple access needed)

- Oliver answers §14.
- Final copy approved (§6.2), and the counts re-checked.
- Promotional offers created in App Store Connect if Decision 3 = yes. They can exist before
  approval, and creating them needs a yes.
- Confirm Max yearly has prices (§1.5).
- Check RevenueCat: plan tier, whether Lifecycle → Retention and experiments are available.
- Prepare App Store Connect fallback messages M1–M3 (create, version, en-US text, assign) but **don't
  submit**.

**Done when:** copy approved, offers exist (or are declined), fallback versions sit in
`PREPARE_FOR_SUBMISSION`, RevenueCat tier known.

### Phase 1: at and right after 1.0 release

- After 1.0 is approved and live: submit M1–M3 for review (a yes first).
- Oliver sends Apple's access request (§8.2).
- Docs: FAQ and usage guide say a message or offer may appear when cancelling on Apple devices, and
  "Apple ID" becomes "Apple Account". Casama Help's prompt gets the same fact. Docs deploy needs a
  yes.

**Done when:** M1–M3 `APPROVED` and showing on a real cancel screen; access request sent.

### Phase 2: after Apple grants access

- RevenueCat sandbox → performance test → sandbox defaults and real-time messages → device matrix
  (§8.5) → production URL → production messages → Apple approves each one.
- Write the decision entry and update `docs/COSTS.md` and memory.

**Done when:** every product shows the intended message in production on iOS and macOS; one live
check of Switch Plan and (if used) Accept Offer reaches the server correctly.

### Phase 3: improve (optional, each piece separately approved)

- 10.2 events, 10.4 email wording, 10.1 in-app sheet (Flutter build: ask), 10.3 attributes.
- First experiment: M1/M2/M3 copy A versus B, or M6 30% versus no offer (needs experiments on our
  RevenueCat tier).
- Images (§6.4).

### Phase 4: review after 30 days of production

- Compare in RevenueCat: save rate, offer acceptance, switches. Against PostHog: `renewal_off`,
  `renewal_on`, downgrades, App Store churn before and after.
- Decide: keep, change copy, change or drop the offer.

## 13. Testing and verification

| What | How |
|---|---|
| Copy limits | Script counts (header ≤ 66, body ≤ 144) before every upload |
| App Store Connect fallback | `GET /v1/retentionMessageVersions/{id}` state; real cancel screen on iOS and Mac |
| Performance test | RevenueCat shows passed; re-run after any RevenueCat URL change |
| Message choice | Device matrix §8.5 in sandbox, then one real check per platform in production with a real (later refunded or cancelled) subscription, after Oliver's yes |
| Server reaction | Billing snapshot, emails and PostHog events for Keep / Switch / Offer / Cancel |
| Code (Phase 3) | Targeted tests while working; `scripts/heavy.sh pnpm test`, pgTAP and Flutter suites once at the end |

## 14. Decisions for Oliver

| # | Question | Recommendation |
|---|---|---|
| 1 | Route | **RevenueCat**, with App Store Connect text messages as the fallback (§5) |
| 2 | Copy | Approve or edit M1–M7 (§6.2) |
| 3 | Offers | **Yes, one guarded offer:** 30% off for 2 months, monthly plans only, ≥ 2 paid months, none in 6 months (§9). 3b: fallback has no offers |
| 4 | Plan switches | **Yes:** Max → Pro and Pro → Plus, same period. Pro → Plus only after edge case 11.2 is settled |
| 5 | Languages | English text in every locale now; translations later with the app (§6.3) |
| 6 | Phase 3 code | 10.2 (events) and 10.4 (email wording) yes; 10.1 (in-app sheet) with the next app build; 10.3 only if a use case appears |
| 7 | Timing | Phase 0 now; fallback review and the access request right after 1.0 is live |

## 15. Risks and open questions

- **Apple access** is pre-release and may take time or be refused. The App Store Connect fallback
  still gives us the main benefit (a text message).
- **Rejection:** copy that implies a price, or claims we can't back up. Keep to §6.2's rules.
- **Discount training:** guard rails in §9; measure revenue per subscriber, not just saves.
- **RevenueCat tier:** experiments are "Pro and Enterprise" per RevenueCat's docs. Our tier needs
  checking (Phase 0).
- **Locale gaps:** the community report suggests filling every locale (§6.3).
- **Store downgrade and seats:** open (§11.2).
- **macOS:** messages need macOS 14+. Older Macs see the plain cancel screen.
- **Unknown:** how long Apple's production review of each message takes. RevenueCat doesn't say.

---

## Appendix A: Retention Messaging API endpoints (base `api.storekit.apple.com`, sandbox `api.storekit-sandbox.apple.com`, since 2026-05-05)

| Area | Endpoints |
|---|---|
| Images | Upload Image, Delete Image, Get Image List |
| Messages | Upload Message, Delete Message, Get Message List |
| Defaults | Configure Default Message, Get Default Message, Delete Default Message |
| Real-time URL | Configure Realtime URL, Get Realtime URL, Delete Realtime URL |
| Performance | Initiate Performance Test, Get Performance Test Results |
| Ours to host | Get Retention Message (`POST`, `RealtimeRequestBody` in, `RealtimeResponseBody` out) |

Errors worth knowing: `MessageNotApprovedError` / `ImageNotApprovedError` (default needs approved
content), `ForbiddenNoPassingTestError` (production URL before a passed test),
`MessageAlreadyExistsError` / `ImageAlreadyExistsError` (uploads aren't idempotent),
`BadRequestTransactionIdNotSupportedForFamilySharingError`, `RateLimitExceededError` (HTTP 429 with
`Retry-After` in Unix ms), `GeneralInternalError` (retry).

Changelog: 1.0 (2025-07-16) pre-release; 1.1 (2025-09-04) `environment`, `signedDate`; 1.2
(2025-11-05) `advancedCommerceInfo`; 1.3 (2025-12-09) performance test; 1.4 (2026-03-31) realtime
URL endpoints, bullets, `headerPosition`, `imageSize`; 1.5 (2026-04-27) `billingPlanType`; 1.6
(2026-11-04) universal asset images, `BadRequestInvalidTextFieldError`, always calls the realtime
URL, App Store Connect message ids allowed in responses.

## Appendix B: our own endpoint (route C, not recommended now)

If it's ever needed:
- `POST /hooks/apple/retention/{sandbox|production}` in `apps/server`, outside the auth middleware,
  with rate limits like the other hooks.
- Check the JWS x5c chain against Apple's root (pinned in the image), check `appAppleId` =
  6833509960 and `environment`, then reject anything older than a few minutes by `signedDate`.
- Map `originalTransactionId` → subscription → workspace through RevenueCat's v2 API. That's too
  slow within 700 ms, so keep a local index from webhooks (`subscriptions.raw` already holds store
  ids) and never call out on the hot path.
- Choose from a table `retention_messages` (id, kind, product, audience, approved), editable in
  Admin, and answer from memory. Sign promotional offers with HW9SYD2XPL (V2 JWS).
- A management client for upload, list and default, reusing `asc`-style JWT with the In-App
  Purchase key. Performance test, then production URL.
- Lost: RevenueCat's experiments and per-locale tooling. Gained: messages chosen from Casama's own
  data.

## Appendix C: sources

- Apple: Retention Messaging API, Setting up retention messages, Setting up your Get Retention
  Message endpoint, Responding to real-time retention messaging requests, Upload Message, Upload
  Image, Configure Default Message, Configure Realtime URL, Initiate Performance Test, Identifying
  rate limits, Error codes, changelog (developer.apple.com/documentation/retentionmessaging).
- Apple: Setting up retention messaging for auto-renewable subscriptions (App Store Connect API).
- RevenueCat: Apple Retention Messaging API docs; engineering blog (2025-11-04); App Store Connect
  guide (2026-11-05); benchmarks (2026-10-06); community thread 7736 (June–July 2026).
- Casama: D-248, D-249, D-297, D-298, D-302, `docs/COSTS.md`, App Store Connect API reads on
  2026-11-20.
