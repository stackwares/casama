# Weekly plans as a price anchor: plan

Status: **approved 2026-11-20 (D-432)**. Oliver picked the higher prices, $7.99 / $19.99 / $39.99 a
week; the other questions took the proposed answers. The tables below show the first draft's prices.

## 0. Summary

Add a weekly billing period to Plus, Pro and Max, priced well above the monthly rate. Few people
should buy it; its job is to make monthly look reasonable and yearly look cheap next to it. This
is **price anchoring** (a high reference price changes how the others feel). An option added mainly
to steer people toward another one is also called a **decoy** (the "decoy effect"). Weekly also
earns money from people who need Casama for one short job.

The paywall's period picker becomes **Weekly | Monthly | Yearly**, and each card shows a per-week
price, so the gap is visible at a glance:

| Tier | Weekly | Monthly (per week) | Yearly (per week) | Weekly vs monthly |
|------|--------|--------------------|-------------------|-------------------|
| Plus | **$5.99/wk** | $15 ($3.46/wk) | $150 ($2.88/wk) | 1.73× |
| Pro  | **$17.99/wk** | $49 ($11.31/wk) | $490 ($9.42/wk) | 1.59× |
| Max  | **$34.99/wk** | $99 ($22.85/wk) | $899 ($17.29/wk) | 1.53× |

(Proposed prices. All are standard App Store and Play price points and fit D-249's $899 ceiling.)

## 1. What exists today

- `plans.interval` allows only `none | month | year` (`supabase/migrations/20261109000002_billing_stubs.sql`),
  and so do the contracts (`packages/contracts/src/billing.ts:12`, `admin.ts:175,228`).
- Plan codes pair up as `pro` / `pro_yearly`. The paywall groups them by that suffix
  (`client/lib/features/billing/paywall.dart:56-105`) and draws a two-way Monthly | Yearly pill
  (`_PeriodToggle`, line 1127) with a "Save up to N%" badge.
- Included credits are granted once per period through `grant_month()` (D-333,
  `20270201160301_billing_periods.sql`), with references like `monthly:<YYYY-MM>:<plan>`. Any
  interval other than month or year falls back to the **calendar month**. A weekly subscriber
  would get a full month of credits for one week's payment.
- Computer hours are counted per calendar month (`apps/server/src/billing/service.ts:1163`).
- D-332's `paywall_default` / `paywall_popular` flags pick where the paywall opens and which plan
  gets the badge.
- **Shipped apps would break.** The generated Dart model parses `interval` as a strict enum
  (`dart/casama_api/lib/src/model/plan.dart:188`, no `unknownEnumValue`). One `week` row in
  `/v1/billing/plans` makes the whole plan list fail to parse in every app already in the stores
  (the same trap as adding a new `AppCategory` value). The server can't tell app versions apart today: no build
  header is sent.

## 2. Design

### 2.1 Plans and data

- New plan rows: `plus_weekly`, `pro_weekly`, `max_weekly`, `interval = 'week'`, same `limits` as
  the monthly plan except the ones below. Sort them before monthly so tiers read weekly → yearly.
- Migration: widen the `interval` check to include `'week'`. Contracts and the admin enums get
  `week`. Regenerate the TS and Dart clients.
- **Only newer apps see weekly plans.** `/v1/billing/plans` leaves out `week` plans unless the
  request opts in (`?periods=week`, or a `Casama-Client-Features: weekly-plans` header). The web
  app and new app builds opt in. Admin always sees them. (Making the generated
  Dart enums tolerate unknown values is a separate change: it touches every enum in the client.)

### 2.2 What a week includes

- **Credits:** granted every paid week, a quarter of the monthly amount (Plus $1.25, Pro $3.75,
  Max $7.50). `grant_month()` gets a weekly branch, with references `weekly:<IYYY-IW>:<plan>`, so
  each paid week grants once and one payment never earns a month.
- **Computer hours, seats, bots, running computers, computer size:** the same as the monthly plan.
  Hours keep their calendar-month cap. They cost little (D-249), and splitting them by week adds
  complexity for little gain.
- **Pro trial:** not offered on weekly. A weekly trial would undercut the anchor and invites abuse.
  Store weekly products get no intro offer.
- **Extra people ($12 add-on):** not sold on weekly. A weekly workspace that needs more people
  upgrades or moves to monthly.

### 2.3 Where people buy it

| Channel | Work |
|---------|------|
| Web (Dodo) | 3 new subscription products with a weekly interval; ids in `plans.dodo_product_id`. Plan switches use the existing Dodo change-plan path (prorated). |
| App Store | 3 new auto-renewable products, 1-week duration, in the existing subscription group at the **same level** as their tier, so weekly ↔ monthly ↔ yearly is a crossgrade. Review screenshot for each (as with the current 8). |
| Google Play | A `weekly` base plan (P1W, auto-renewing) on the existing plus / pro / max subscriptions. No offers. |
| RevenueCat | Attach the 6 new store products to the plus / pro / max entitlements (project `proj864b35e1`). The app looks products up by server id, so offerings don't change. |

D-297's webhook and re-read flow already map any product to its plan, so no server change there
beyond the new rows.

### 2.4 Paywall

- Period pill: **Weekly | Monthly | Yearly** (three segments, keys `paywallInterval-week` etc.).
  If a tier has no weekly plan, or the store returns no weekly product, the segment hides (same
  rule as D-248 for missing periods).
- Each card shows **per-week equivalents** under the main price on monthly and yearly
  ("$3.46/wk"), so the anchor reads directly. Weekly shows "$5.99 billed weekly".
- The yearly save badge keeps comparing against **monthly** ("Save up to 17%"). Comparing against
  weekly would show a bigger number (about 50–60%), but Apple has rejected apps for inflated
  savings claims and it reads as a trick. Option in Q4.
- The paywall still opens on monthly (D-332 flag, unchanged). Weekly is never the default and
  never gets the Popular badge.
- Out-of-credits, plan switching and Settings → Plan show "Weekly" where they show
  "Monthly"/"Yearly" today (`purchase_terms.dart`, `out_of_credits.dart`, l10n strings).
- Store disclosure: the weekly card states the charge and the renewal ("$5.99 every week until
  you cancel"), as App Store 3.1.2 requires for auto-renewing subscriptions.

### 2.5 Website and docs

- casama.ai pricing and docs-site billing page: add the weekly price as a small line under each
  tier ("or $17.99 a week"), not a third toggle. The page sells monthly and yearly.
- `docs/COSTS.md`: a "Weekly plans" row under revenue (store cut is the same 15%; Dodo fee per
  charge hits weekly 4× as often, about $0.50 a charge, noted in the margin check).
- `docs/DECISIONS.md`: one new `D-…` entry.

### 2.6 Margin check

Worst case Pro weekly through the App Store: $17.99 × 0.85 = $15.29 net. Included credits cost at
most $3.75 / 1.4 ≈ $2.68 a week, plus hours. Weekly earns more per week than monthly at every tier,
so the D-249 formula `price × (1 − fee) ≥ included costs × 1.3 + fixed` holds with room.

## 3. Rollout

1. Server + migration + contracts + regenerated clients (weekly hidden from apps that don't opt
   in). Tests: grant once per week, no trial on weekly, seats refused, old-client plan list has no
   `week`, admin save with `week`.
2. Store products: App Store (3), Play base plans (3), Dodo (3), RevenueCat attachments. I create
   these with `asc`, `gplay`, the Dodo CLI and the RC API. Nothing is submitted for review.
3. Paywall + strings + tests (`client/test/paywall_*`).
4. Website/docs copy.
5. Asks for your yes: prod deploy (`scripts/deploy-prod.sh`), app.casama.ai build + deploy,
   website deploy, store builds.

## 4. Questions for Oliver

1. **Prices.** $5.99 / $17.99 / $34.99 a week (about 1.5–1.7× the monthly rate)? Higher,
   like $7.99 / $19.99 / $39.99 (about 2×), makes the anchor stronger and sells fewer weeklies.
2. **Tiers.** All three, or only Plus and Pro? (Max weekly at $35 may never sell, but the pill
   looks odd when one tier has no weekly.)
3. **Credits per week.** A quarter of the monthly amount (proposed), or the full monthly amount
   once per calendar month?
4. **Save badge.** Keep yearly savings against monthly (proposed, safe for App Review), or show
   savings against weekly for the bigger number?
5. **Website.** Small "or $X a week" line under each tier (proposed), or leave weekly off the
   website and keep it in the app only?
