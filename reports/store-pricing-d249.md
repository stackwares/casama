# Store pricing update D-249 (2026-11-13)

Oliver approved this. It is pre-launch and nobody subscribes yet. No builds were uploaded, nothing went to App Review, and no other app was touched. The file holds no secrets. Every change below was read back from its store after it was made.

New list (USD): Plus $15/mo, $150/yr (unchanged). Pro $49/mo, $490/yr (was $39/$390). Max $99/mo, $899/yr (was $149/$1,490). Credit packs unchanged.

## 1. Dodo Payments (Live, business `bus_0NmI8F7BEBSstpR3E5s4y`)

Changed through the REST API (`PATCH /products/{id}`, `POST /addons`) with the Casama server key.

| Plan code | Product id | New price | Add-on attached |
|---|---|---|---|
| pro_monthly | `pdt_0NrouRq9R8OMMCSjPYcVN` | $49 / month (4900) | `adn_0NrpW888EhJ6X1o9dIPhr` |
| pro_yearly | `pdt_0NrouRvY4CM6AmKfVtdNg` | $490 / year (49000) | `adn_0NrpW8GLR2pGEnYlfUEZr` |
| max_monthly | `pdt_0NrouS0mx16rzz0V0VTCC` | $99 / month (9900) | `adn_0NrpW888EhJ6X1o9dIPhr` |
| max_yearly | `pdt_0NrouS7f0OrQAh7qntFQn` | $899 / year (89900) | `adn_0NrpW8GLR2pGEnYlfUEZr` |

- The products still have no trial (`trial_period_days: 0`), PPP is still off, and metadata (`app`, `plan_code`) and names are unchanged.
- New descriptions:
  - Pro: "Casama Pro: $15 of credits, 100 computer hours and room for 3 people each month. Billed monthly|yearly."
  - Max: "Casama Max: $30 of credits, 300 computer hours and room for 10 people each month. Billed monthly|yearly."
  - The old Pro text said "20 bots". The brief gave no bot count, so I dropped it.

### Add-ons (tax category `saas`, USD)

| Add-on id | Name | Price | Attached to |
|---|---|---|---|
| `adn_0NrpW888EhJ6X1o9dIPhr` | Extra person | $12 (1200) | pro_monthly, max_monthly |
| `adn_0NrpW8GLR2pGEnYlfUEZr` | Extra person (yearly) | $120 (12000) | pro_yearly, max_yearly |

An add-on has no billing period of its own. It is charged on the subscription's cycle, so the yearly one is a separate $120 add-on. I attached them with `PATCH /products/{id}` `{"addons": ["adn_…"]}`. Each product had no add-ons before. The docs don't say whether this list replaces or appends, so always send the full list.

### Dodo API findings

Source: docs.dodopayments.com, the API reference pages for checkout-sessions/create, subscriptions/change-plan, get-subscriptions, post-subscriptions, addons/create-addon and patch-products, plus features/addons and features/subscription. "Verified" means the docs state it. "Inferred" means my own reading.

**(a) A trial on one checkout session.** Verified. Send `subscription_data.trial_period_days` on `POST /checkouts`.
- Type: integer or null (int32), from 0 to 10000.
- The docs say: "If specified, this value overrides the trial period set in the product's price." The products keep 0.

```json
POST /checkouts
{
  "product_cart": [{ "product_id": "pdt_0NrouRq9R8OMMCSjPYcVN", "quantity": 1 }],
  "customer": { "customer_id": "cus_…" },
  "subscription_data": { "trial_period_days": 7 },
  "return_url": "https://…"
}
```

- If "Prevent Trial Misuse" is on for the business, passing `trial_period_days` explicitly skips that check and grants the trial. Verified. The server has to enforce one trial per user itself.
- A paid trial (`trial_amount`) can only be set on the product price, not per checkout.
- The deprecated `POST /subscriptions` also takes `trial_period_days` and `addons`.

**(b) A subscription in trial.** Verified.
- The `status` enum is `pending | active | on_hold | paused | cancelled | failed | expired | past_due`. **There is no `trialing`.** A trial subscription is `active`.
- The docs say: "The subscription object has no trial status field."
- Fields on the object:
  - `trial_period_days` (integer, required; 0 means no trial) is the configured length, not the days left.
  - `trial_amount` (integer or null) is null for a free trial.
  - `next_billing_date` (date-time, required) is "the end of current billing period".
  - `previous_billing_date` (date-time, required).
  - `has_payment_method` (boolean).
- **There is no `trial_end` or `trial_ends_at` field.**
- Inferred: during a trial, `next_billing_date` is when the trial ends. Count a subscription as in trial when `trial_period_days > 0` and now < `created_at + trial_period_days` (that equals `next_billing_date` on the first cycle).
- The docs' own way to detect a free trial is that the subscription has exactly one payment, with `total_amount` 0.

**(c) Add-on shapes.** Verified.

Checkout. `addons` is only valid on a subscription product. Each `quantity` is an integer ≥ 0. `feature_flags.allow_editing_addons: true` lets the buyer change them on the checkout page.

```json
POST /checkouts
{
  "product_cart": [
    {
      "product_id": "pdt_0NrouRq9R8OMMCSjPYcVN",
      "quantity": 1,
      "addons": [{ "addon_id": "adn_0NrpW888EhJ6X1o9dIPhr", "quantity": 2 }]
    }
  ],
  "subscription_data": { "trial_period_days": 7 }
}
```

Change plan. Required fields: `product_id`, `quantity` (at least 1) and `proration_billing_mode`.

```json
POST /subscriptions/{subscription_id}/change-plan
{
  "product_id": "pdt_0NrouS0mx16rzz0V0VTCC",
  "quantity": 1,
  "proration_billing_mode": "difference_immediately",
  "addons": [{ "addon_id": "adn_0NrpW888EhJ6X1o9dIPhr", "quantity": 2 }]
}
```

- `proration_billing_mode` takes `prorated_immediately | full_immediately | difference_immediately | do_not_bill | prorated_immediately_keep_cycle`.
- The docs say of `addons`: "Leaving this empty would remove any existing addons." `addons: []` removes them all. The docs don't say what happens if `addons` is left out entirely. **Always send the full add-on list on a plan change.**
- When switching between monthly and yearly, switch the add-on id too (monthly `adn_0NrpW888…` ↔ yearly `adn_0NrpW8GL…`).
- Optional fields: `effective_at` (`immediately | next_billing_date`), `on_payment_failure` (`prevent_change | apply_change`), `discount_codes`, `metadata`.
- The response carries only `payment_id`, `payment_link`, `client_secret`, `expires_on`, `invoice_id` and `refund_id`, not the subscription.

`GET /subscriptions/{id}` has a required `addons` array. Each item holds only `addon_id` and `quantity`, with no name or price:

```json
"addons": [{ "addon_id": "adn_0NrpW888EhJ6X1o9dIPhr", "quantity": 2 }]
```

A pending `scheduled_change` lists add-ons as `{ "addon_id", "name", "quantity" }`.

## 2. App Store Connect (app 6833509960, group 22574241)

Each price was set with `asc subscriptions pricing equalize` from the US price point, with Apple's equalized prices in the other 174 territories. All four now have 175/175 territories priced.

| Product id | Apple id | New US price | Intro offer |
|---|---|---|---|
| ai.casama.pro.monthly | 6834171411 | $49.00 | Free, 1 week, 175/175 territories |
| ai.casama.pro.yearly | 6834171444 | $490.00 | Free, 1 week, 175/175 territories |
| ai.casama.max.monthly | 6834171141 | $99.00 | none |
| ai.casama.max.yearly | 6834171246 | $899.00 (was unpriced) | none |

- The intro offers are `FREE_TRIAL`, `ONE_WEEK`, one period, starting 2026-11-12, with no end date. Apple's own rule limits an intro offer to one per customer per subscription group.
- The first pass hit Apple's 429 rate limit: 8 territories on Max Monthly, 11 on Max Yearly, and Korea and India on the Pro Monthly trial. I re-ran them more slowly and all succeeded. The pricing summary confirms the US prices above.
- New en-US descriptions (Apple's limit is 55 characters):
  - Pro Monthly and Pro Yearly: "$15 credits, 100 computer hours, 3 people monthly"
  - Max Monthly and Max Yearly: "$30 credits, 300 computer hours, 10 people monthly"
  - Display names are unchanged.
- The products are still MISSING_METADATA because they have no review screenshots. Nothing changed there.

## 3. Google Play (`ai.casama.app`)

| Product | Base plan | US price | State | Notes |
|---|---|---|---|---|
| casama_plus | monthly | $15 | ACTIVE | unchanged |
| casama_plus | yearly | $150 | ACTIVE | **already existed** (created 2026-11-13) at $150, unchanged |
| casama_pro | monthly | $49 (was $39) | ACTIVE | trial offer `free-trial-7d` |
| casama_pro | yearly | $490 (was $390) | ACTIVE | **already existed** at $390, repriced; trial offer `free-trial-7d` |
| casama_max | monthly | $99 (was $149) | ACTIVE | |
| casama_max | yearly | $899 | ACTIVE | **new**: P1Y auto-renewing, 7-day grace, not legacy-compatible |

- The brief asked to create `yearly` for all three plans. Plus and Pro already had one from the first setup, so I repriced Pro's and left Plus's alone at the correct $150. Only `casama_max:yearly` was new.
- Regional prices come from Play's `convertRegionPrices` for the US price (regions version 2026/01, 174 regions plus "other regions"). The US is set to the exact USD amount.
- **Play price ceilings:** where the converted price was above Play's maximum for a region, I set that region to the maximum, as the Console does. That affected:
  - Pro Yearly ($490): 1 region, KR, at ₩600,000.
  - Max Yearly ($899): 56 regions, so those regions are charged less than the equalized price. For example:
    - eurozone €940.00 (instead of €949.99–€999.99)
    - KR ₩600,000 (instead of ₩1,320,000)
    - IN ₹84,000 (instead of ₹99,800)
    - TR TRY 40,800, MX MX$17,200, JP ¥155,000
    - AL/BY/MD/MK/UG $999.99
- **Trial offers:** offer id `free-trial-7d` on `casama_pro:monthly` and `casama_pro:yearly`. Both are ACTIVE.
  - One phase: P7D, recurrence 1, free in all 174 regions and in other regions.
  - Eligibility: `acquisitionRule.scope.anySubscriptionInApp`, which means new customers who never had any subscription in this app.
  - Offer tag `free-trial`.
- **Listings (en-US):**
  - casama_pro: "$15 of credits, 100 computer hours and room for 3 people each month". Benefits: "$15 of credits each month", "100 computer hours each month", "Room for 3 people".
  - casama_max: "$30 of credits, 300 computer hours and room for 10 people each month". Benefits: "$30 of credits each month", "300 computer hours each month", "Room for 10 people".

## Needs Oliver / follow-ups

1. **Server catalog.** The plans table and pricing copy have to match the new prices. The server has to:
   - start Pro trials on Dodo with `subscription_data.trial_period_days: 7`, and enforce one trial per user itself;
   - carry the extra-person add-on with the right monthly or yearly id;
   - treat an `active` Dodo subscription with `trial_period_days > 0` inside its first cycle as a trial.

   `casama_max:yearly` now exists on Play, so the earlier "hide Max Yearly on Android" workaround can go.
2. **Max Yearly is capped in 56 Play regions** (see above). The US is exactly $899. Say if you want something different there, such as dropping those regions or picking a lower worldwide yearly price.
3. **Plus descriptions are unchanged** in all three stores: "5 bots' room, 30 computer hours, $5 of credits" and similar. The brief kept Plus unchanged, but if Plus's allowances changed too, those texts are now stale.
4. App Store review screenshots are still missing (as in the earlier report), and every product still needs submitting with the first app version.
5. Proceeds on the App Store show 85% (Small Business Program rate), for example $41.65 on Pro Monthly.

## Follow-up (2026-11-13): new Plus allowances, unlimited bots on Pro and Max

The new Plus allowances are $5 of credits a month, 30 computer hours, 1 person, 10 bots and 1 computer running at a time. Pro and Max now have unlimited bots. Only text changed. Prices, add-ons, trials and the Play regional caps are unchanged; read-backs confirm each one, for example Korea is still ₩600,000 on Pro Yearly and Max Yearly. This replaces follow-up 3 above.

**Dodo**
- Plus Monthly (`pdt_0NrouRdbGHkyosFNGd3Hr`) and Plus Yearly (`pdt_0NrouRkcQiKfdOzPLjSPv`): "Casama Plus: $5 of credits and 30 computer hours each month, 10 bots, 1 computer running at a time, for 1 person. Billed monthly|yearly."
- Pro: "Casama Pro: $15 of credits, 100 computer hours and room for 3 people each month, with unlimited bots. Billed monthly|yearly."
- Max: "Casama Max: $30 of credits, 300 computer hours and room for 10 people each month, with unlimited bots. Billed monthly|yearly."

**App Store (en-US, 55-character limit)**
- Plus Monthly (6834171595) and Plus Yearly (6834171628): "$5 credits, 30 computer hrs, 10 bots, 1 person monthly" (54). "1 computer at a time" doesn't fit.
- Pro and Max are unchanged. Their descriptions don't list bots, and "unlimited bots" doesn't fit next to the current text within 55 characters.

**Google Play (en-US listings only)**
- casama_plus:
  - Description: "$5 of credits and 30 computer hours each month, 10 bots, 1 computer running at a time, for 1 person"
  - Benefits: "$5 of credits each month", "30 computer hours each month", "10 bots", "1 computer running at a time". Play allows at most 4 benefits, so "1 person" is only in the description.
- casama_pro and casama_max:
  - Descriptions end in ", with unlimited bots".
  - Each has a fourth benefit, "Unlimited bots".
