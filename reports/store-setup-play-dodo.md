# Store setup: Google Play and Dodo Payments (2026-11-13)

Oliver approved this on 2026-11-13. No app builds were uploaded and no store listings were changed. This file holds no secrets; they are in Vaultwarden ("Keys & Signing") and `~/.config/casama/`.

## Google Play (`ai.casama.app`, Stackwares account 6609804826699409799)

Prices are in USD. Google converted the regional prices (regions version 2026/01, 174 regions); the US price is the exact USD amount. Listings are en-US only.

### Subscriptions (auto-renewing, 7-day grace period, ACTIVE)

| Product | Base plan | Server id (`google_play`) | US price |
|---|---|---|---|
| casama_plus | monthly | `casama_plus:monthly` | $15.00 / month |
| casama_plus | yearly | `casama_plus:yearly` | $150.00 / year |
| casama_pro | monthly | `casama_pro:monthly` | $39.00 / month |
| casama_pro | yearly | `casama_pro:yearly` | $390.00 / year |
| casama_max | monthly | `casama_max:monthly` | $149.00 / month |
| casama_max | yearly | — | **not created (blocked, see below)** |

`casama_pro` did not exist before; all three subscriptions were created new.

Descriptions are the full sentences from the brief. Play limits each benefit to 40 characters, so the benefits are split into short lines:
- Plus: "30 computer hours each month", "$5 of credits each month"
- Pro: "20 bots", "100 computer hours each month", "$10 of credits each month"
- Max: "400 computer hours each month", "$50 of credits each month"

### One-time products (purchase option `default`, ACTIVE)

| Product | Title | US price |
|---|---|---|
| casama_credits_10 | $10 of credits | $12.99 |
| casama_credits_25 | $25 of credits | $29.99 |

These ids match `supabase/migrations/20270129000001_pricing.sql`.

### Purchase-verification service account

- **Dedicated account `casama-billing@pc-api-6609804826699409799-626.iam.gserviceaccount.com`**, in GCP project `pc-api-6609804826699409799-626` ("Google Play Console Developer", owned by ciphere.bytes).
- **Why not play-publisher:** play-publisher (in `stackwares-core`) does have the needed permissions, but ciphere.bytes has no access to `stackwares-core`. That means no Pub/Sub topic can be made beside it, and no separate key can be issued. play-publisher is also an account-wide admin, which is too much for a server key.
- **Play access:** app-level on ai.casama.app only: View financial data, Manage orders and subscriptions, View app information. It has no GCP project roles.
- **Key:** id `493a5b4b…`, saved at `~/.config/casama/play-billing-sa.json` (0600) and in Vaultwarden as "Casama · Play billing service account". Server env: `GOOGLE_PLAY_SERVICE_ACCOUNT` (inline JSON or a file path).
- **Checked:** with this key, the Play API lists casama_max, casama_plus and casama_pro.

### Real-time developer notifications

- **Topic:** `projects/pc-api-6609804826699409799-626/topics/casama-play-rtdn`. `google-play-developer-notifications@system.gserviceaccount.com` has Pub/Sub Publisher on it.
- **Push subscription:** `casama-play-rtdn-push` → `https://api.casama.ai/hooks/billing/google_play?token=<GOOGLE_PLAY_RTDN_TOKEN>`. The route is `/hooks/billing/:source` and the query parameter is `token`, as `google-play.ts verifyWebhook` expects. Ack deadline 30 s, retention 7 days, retry backoff 10–600 s.
- **OIDC on the push:** service account (`GOOGLE_PLAY_RTDN_EMAIL`) `casama-billing@pc-api-6609804826699409799-626.iam.gserviceaccount.com`; audience (`GOOGLE_PLAY_RTDN_AUDIENCE`) `https://api.casama.ai/hooks/billing/google_play`. The Pub/Sub service agent has Token Creator on that account.
- **Token:** 32 random characters, saved in Vaultwarden as "Casama · Play RTDN token" and in billing.env.
- **Play Console → Monetization setup:** real-time notifications enabled with this topic, content "Subscriptions and voided purchases only". I did not send a test notification.

## Dodo Payments (LIVE, business `bus_0NmI8F7BEBSstpR3E5s4y`)

The products and webhook were made through the Dodo REST API, using the Live key the `dodo` CLI is signed in with. All products are tax category `saas`, have no trial, have PPP off, and carry metadata `app=casama` plus `plan_code`.

| Plan code | Dodo product id | Name | Price |
|---|---|---|---|
| plus_monthly | `pdt_0NrouRdbGHkyosFNGd3Hr` | Casama Plus Monthly | $15 / month |
| plus_yearly | `pdt_0NrouRkcQiKfdOzPLjSPv` | Casama Plus Yearly | $150 / year |
| pro_monthly | `pdt_0NrouRq9R8OMMCSjPYcVN` | Casama Pro Monthly | $39 / month |
| pro_yearly | `pdt_0NrouRvY4CM6AmKfVtdNg` | Casama Pro Yearly | $390 / year |
| max_monthly | `pdt_0NrouS0mx16rzz0V0VTCC` | Casama Max Monthly | $149 / month |
| max_yearly | `pdt_0NrouS7f0OrQAh7qntFQn` | Casama Max Yearly | $1,490 / year |
| credits_10 | `pdt_0NrouSCO85SNIHHfO3uPS` | $10 of credits | $10 one-time |
| credits_25 | `pdt_0NrouSHczr2Prk68IBRYr` | $25 of credits | $25 one-time |

### Webhook

- **Endpoint `ep_3M1nPB2YTmVkajY3ZNbGNOSATU1`** → `https://api.casama.ai/hooks/billing/dodo`.
- **Events:** subscription.active, renewed, updated, plan_changed, on_hold, past_due, paused, unpaused, cancelled, failed, expired and update_payment_method; payment.succeeded; refund.succeeded; dispute.lost. These match what `apps/server/src/billing/dodo.ts parseEvent` handles: all `subscription.*` events, plus `payment.succeeded`, `refund.succeeded` and `dispute.lost`.
- **Signing secret:** in Vaultwarden as "Casama · Dodo webhook secret" and in billing.env.

## `~/.config/casama/billing.env` (0600)

It holds `DODO_API_KEY`, `DODO_WEBHOOK_SECRET`, `DODO_ENVIRONMENT=live`, `GOOGLE_PLAY_RTDN_TOKEN`, `GOOGLE_PLAY_RTDN_EMAIL` and `GOOGLE_PLAY_RTDN_AUDIENCE`.

### Dodo API key

Oliver created a dedicated Live key named "Casama server" in the dashboard (Dodo's API can't create keys). It is saved in Vaultwarden as "Casama · Dodo live API key" and in billing.env. Checked: it reads the Casama products and webhooks on live.dodopayments.com. The business is shared, so the key can reach other apps' Dodo data too.

## Blocked / for Oliver

1. **Play `casama_max` yearly at $1,490:** Play's ceiling is $999.99 in the US, and lower in some regions, such as AED 3,700. Choose $999.99 on Play only, a different yearly price, or no yearly Max on Android. The server catalog maps `max_yearly` to `casama_max:yearly`, so the app must hide that option on Android until the plan exists.
2. **Not done here (outside the brief):**
   - Putting these values on the prod server (`/opt/casama` env: `GOOGLE_PLAY_SERVICE_ACCOUNT`, `GOOGLE_PLAY_RTDN_*`, `DODO_*`).
   - Writing the Dodo product ids into the plans table (`dodo_product_id`).
   - Until the server has the RTDN token, Pub/Sub keeps retrying pushes, for up to 7 days.
3. **Billing service account status:** Play shows it as INVITED. Service accounts don't need to accept, and API calls already work.
