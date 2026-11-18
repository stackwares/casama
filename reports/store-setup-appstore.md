# App Store in-app products and server API key: Casama AI

Date: 2026-11-13. App record **Casama AI** (app id 6833509960, bundle `ai.casama.app`). Oliver approved this on 2026-11-13.

Nothing has been submitted for review and no builds were uploaded. App metadata is unchanged, apart from the two Server Notifications URLs in step 4, which were part of the task.

## 1. Subscription group "Casama"

- Group id **22574241**, reference name "Casama". It didn't exist before, so I created it with an en-US group display name of "Casama".
- Every subscription is available in all **175** territories, plus new territories automatically. Each priced subscription's price is set from the US price point, using Apple's equalized prices for the other 174 territories.
- Upgrade order (level 1 is highest): Max = 1, Pro = 2, Plus = 3. A plan's monthly and yearly share a level.

| Product id | Apple id | Level | Period | Target | Final US price | State |
|---|---|---|---|---|---|---|
| ai.casama.max.monthly | 6834171141 | 1 | 1 month | $149 | **$149.00** | MISSING_METADATA |
| ai.casama.max.yearly | 6834171246 | 1 | 1 year | $1490 | **not set** (see blocked) | MISSING_METADATA |
| ai.casama.pro.monthly | 6834171411 | 2 | 1 month | $39 | **$39.00** | MISSING_METADATA |
| ai.casama.pro.yearly | 6834171444 | 2 | 1 year | $390 | **$390.00** | MISSING_METADATA |
| ai.casama.plus.monthly | 6834171595 | 3 | 1 month | $15 | **$15.00** | MISSING_METADATA |
| ai.casama.plus.yearly | 6834171628 | 3 | 1 year | $150 | **$150.00** | MISSING_METADATA |

The en-US display names are the plan and period ("Max Monthly", "Pro Yearly", …). Descriptions, shortened to Apple's 55-character limit:

- Plus: "5 bots' room, 30 computer hours, $5 of credits monthly" (54)
- Pro: "20 bots, 100 computer hours and $10 of credits monthly" (54)
- Max: "400 computer hours, $50 credits, the most room monthly" (54)

Each plan's yearly uses the same description as its monthly, because the allowance is per month either way.

## 2. Consumables

| Product id | Apple id | Name (en-US) | Description | Final US price | State |
|---|---|---|---|---|---|
| ai.casama.credits.10 | 6834172014 | $10 of credits | $10 of credits to spend in Casama | **$12.99** | MISSING_METADATA |
| ai.casama.credits.25 | 6834172077 | $25 of credits | $25 of credits to spend in Casama | **$29.99** | MISSING_METADATA |

`ai.casama.credits.10` didn't exist before, so I created it new. Both have a USA base price, which Apple equalizes for the other territories, and are available in all 175 territories plus new ones.

## 3. In-App Purchase key (App Store Server API)

- **Key id: HW9SYD2XPL**, named "Casama Server API 2026-11-13" in App Store Connect. It is active and Apple no longer lets anyone download it.
- **Issuer id: 69a6de87-3ae7-47e3-e053-5b8c7c11a4d1**
- **.p8 path:** `~/private_keys/SubscriptionKey_HW9SYD2XPL.p8` (mode 0600, P-256)
- **Vaultwarden:** "Casama · App Store In-App Purchase key" in the "Keys & Signing" folder (item a62cbad3-c52c-440e-abd5-747a5d7b6846). The password field holds the PEM; the notes give the key id, issuer id, scope and how to revoke it. The vault copy's hash matches the file.
- **Checked:** I registered it as the local `asc storekit` profile "Casama" and called the App Store Server API with it (sandbox notification history). Apple accepted the key.
- A separate, older IAP key already exists: "RevenueCat IAP 2026-10-31" (L2CZTWT939), used by RevenueCat. I left it alone.
- How it was made: the `asc` CLI can't create IAP keys, and the browser sign-in wouldn't finish in the background preview tab. I created the key through App Store Connect's own web API (`/iris/v1/subscriptionKeys`), using the `asc` web session.
- **Not done:** the key isn't in the production server's env yet. Deploying it needs a separate yes.

## 4. App Store Server Notifications

Production and sandbox are both set to `https://api.casama.ai/hooks/billing/app_store`, version **V2**. A read-back from the API confirms it.

## Couldn't finish

1. **Max Yearly has no price.** Apple's highest US subscription price point is **$1,000.00** (800 points in total), so no point exists at or above $1,490. I left it unpriced rather than undercut it. Oliver needs to pick one of these:
   - a lower yearly price, at most $1,000 (for example $999.99);
   - ask Apple for higher price points;
   - drop Max Yearly from the App Store and sell it only on the web.

   Once there's a price, set it with: `asc subscriptions setup --app 6833509960 --group-id 22574241 --product-id ai.casama.max.yearly … --repair`, or `asc subscriptions pricing equalize --subscription-id 6834171246 --base-price <price>`.
2. **No review screenshots.** There are no Casama screenshots in `~/Desktop/Projects/Marketing`, so subscriptions and consumables have no App Review screenshot. That's the main reason all eight products show MISSING_METADATA. Adding one per product (`asc subscriptions review screenshots create` / `asc iap review-screenshots create`) should make them Ready to Submit.
3. Products will also need submitting together with an app version when the first build goes up for review. That wasn't part of this task.
