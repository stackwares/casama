# Weekly store products D-432 (2026-11-20)

Weekly plans as a price anchor above monthly (D-432, approved by Oliver). Nothing existed beforehand, so all items below are new. Nothing was submitted for review, no build was uploaded, no offers or trials were added, and existing monthly/yearly products, base plans, the `free-trial-7d` offers and RevenueCat offerings were left unchanged. Everything was read back after creation. No secrets in this file.

| Tier | USD / week | App Store | Google Play | RevenueCat entitlement |
|---|---|---|---|---|
| Plus | 7.99 | ai.casama.plus.weekly | casama_plus : weekly | plus |
| Pro | 19.99 | ai.casama.pro.weekly | casama_pro : weekly | pro |
| Max | 39.99 | ai.casama.max.weekly | casama_max : weekly | max |

## App Store Connect (app 6833509960, group 22574241)

Created with `asc subscriptions setup` (ONE_WEEK, US price, Apple's equalized prices in the other 174 territories).

| Product id | Apple id | Level | US price | Territories | State |
|---|---|---|---|---|---|
| ai.casama.plus.weekly | 6836967063 | 3 (same as Plus Monthly/Yearly) | $7.99 | 175/175 priced + available, new territories auto | READY_TO_SUBMIT |
| ai.casama.pro.weekly | 6836967074 | 2 (same as Pro) | $19.99 | 175/175 | READY_TO_SUBMIT |
| ai.casama.max.weekly | 6836967271 | 1 (same as Max) | $39.99 | 175/175 | READY_TO_SUBMIT |

- Same level as the tier's monthly and yearly, so weekly, monthly and yearly are crossgrades.
- Reference name and en-US display name follow the existing pattern ("Plus Monthly" → "Plus Weekly", "Pro Weekly", "Max Weekly").
- en-US descriptions (55-char limit), using the weekly allowance from docs/WEEKLY-PLAN-PLAN.md §2.2 (a quarter of the monthly credits each week; hours stay a monthly cap):
  - Plus: "$1.25 credits weekly, 30 computer hrs/mo, 10 bots"
  - Pro: "$3.75 credits weekly, 100 computer hrs/mo, 3 people"
  - Max: "$7.50 credits weekly, 300 computer hrs/mo, 10 people"
  Change these if the weekly allowance in the final plan differs.
- No introductory offers (0 on each). Family Sharing off, like the others. The monthly products have no review note, so none was copied.
- App Review screenshot: the same 1206x2622 simulator paywall screenshot that is on the monthly products (downloaded from Plus Monthly's review screenshot), state COMPLETE. It shows the yearly paywall without a Weekly segment; replace it with a shot of the weekly paywall before review.

## Google Play (`ai.casama.app`)

New `weekly` base plan on each existing subscription, added with `gplay subscriptions update --update-mask basePlans` (existing base plans sent back unchanged), then `gplay baseplans activate`.

| Subscription | Base plan | Period | US price | Regions | State |
|---|---|---|---|---|---|
| casama_plus | weekly | P1W auto-renewing | $7.99 | 174 + other regions | ACTIVE |
| casama_pro | weekly | P1W auto-renewing | $19.99 | 174 + other regions | ACTIVE |
| casama_max | weekly | P1W auto-renewing | $39.99 | 174 + other regions | ACTIVE |

- Regional prices from Play's `convertRegionPrices` for the USD price (regions version 2026/01); other regions USD + EUR (EUR 7.28 / 18.21 / 36.44). No price ceilings were hit at these amounts.
- Grace period P3D (Play's limit for weekly; monthly/yearly use P7D), resubscribe on, proration "charge on next billing date" like the others, not legacy-compatible (monthly stays the legacy-compatible plan).
- No offers on any weekly base plan. Pro's `free-trial-7d` on monthly and yearly is still ACTIVE.

## RevenueCat (project proj864b35e1)

Created with the `rc` CLI (OAuth login; the Casama v2 key in the vault is read-only and can't create products).

| Store identifier | App | RC product id | Entitlement |
|---|---|---|---|
| ai.casama.plus.weekly | App Store app0ade906844 | prod7e37920f86 | plus (entl36d8894960) |
| casama_plus:weekly | Play appc65a698928 | prodddf34ee2e1 | plus |
| ai.casama.pro.weekly | App Store | prod890f23a7c2 | pro (entl48f3d6f259) |
| casama_pro:weekly | Play | prod5f93b2090a | pro |
| ai.casama.max.weekly | App Store | prod2ebdcf340d | max (entlbc7a5548b3) |
| casama_max:weekly | Play | prod276d1f7004 | max |

- Display names "Casama Plus Weekly" etc., like the existing ones. Offerings unchanged.
- A first attach call briefly put the Plus and Pro weekly products on the `max` entitlement; they were detached within a minute and attached to the right ones. Final read-back: each entitlement holds exactly its tier's 6 products (monthly, yearly, weekly on both stores). The products had never been sold, so nothing was affected.

## Pending

1. Proper App Review screenshots of the weekly paywall for the 3 App Store products (current one is a stand-in).
2. Submit the 3 App Store products with the first app version that shows weekly plans.
3. Dodo (web) weekly products, the server/plan rows and the app changes from docs/WEEKLY-PLAN-PLAN.md are not part of this task.
4. Descriptions on Play subscriptions are per subscription, not per base plan, so no Play listing change was needed.
