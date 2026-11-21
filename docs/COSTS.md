# What Casama costs to run

Every paid service Casama Cloud depends on, what it costs per unit, who pays it, and how we meter
it. Plans and credits must cover these with a margin. Self-hosted servers pay their own vendors and
none of this applies to them.

Prices are list prices for a startup, checked on **2026-11-11** from each vendor's pricing page
(sources at the end). USD unless marked €. Update this file in the same change whenever a feature
adds a paid service or a vendor changes its price.

## How the money works

- **Users pay for usage through credits**, metered in `usage_ledger` (`kind`, `quantity`, `cost_usd`).
  A plan includes some credits and computer hours; beyond that they buy credit packs.
- **Bring-your-own keys and the ChatGPT plan cost us nothing** for models: the run is logged with
  `cost_usd = 0` (or `source = chatgpt_plan`), and when `instance_settings.model_access.own_providers`
  is on (D-465), a Casama Cloud workspace can run its bots on its own model key with zero credits.
  The instance owner can also turn Casama's models off per plan (`casama_models`), so a plan's model
  cost drops to $0 while workspaces on their own keys keep running. Everything else (computers,
  phone, voice on our keys, Composio, search on our keys) is ours to cover.
- **Stores and payments take a cut before we see anything** (see "Fees on revenue"). A price has to
  cover costs *after* that cut.
- **Rule of thumb:** charge at least **cost × 1.3** for metered usage, and price plans so that
  `price × (1 − store fee) ≥ included costs × 1.3 + fixed costs per user`.

## Vendor monitoring

The **Admin → Vendors** implementation is built locally; production rollout is pending. Its hourly usage checks use read-only
vendor APIs and local counters; they add no paid dependency. Usage tracking does not change
vendor caps or buy credits. See `docs/VENDOR-USAGE-PLAN.md` for rollout status.

## Fixed costs (paid whether or not anyone uses it)

| Item | Cost | Notes |
|---|---|---|
| **Server: Contabo Cloud VPS 6** (6 vCPU / 12 GB / 200 GB, US Central; D-199) | **$11 / month** | Runs everything: API, worker, our own Supabase, search, TURN, and the bot computers. The stack uses about 2.2 GB, leaving about 9 GB for computers (about 6–7 headless at once). Bigger later: a dedicated server such as Hetzner AX102 (€159 / month, 128 GB) |
| Supabase Cloud (only if we don't self-host Postgres) | from $25 / month | Includes 8 GB database, 250 GB egress, 100k monthly active users |
| Composio | $0 now (Hobby), **$29 / month** on Pro | Pro needed at launch for the data processing agreement; usage on top, see below |
| Search and AI-answer tracking (OpenSEO on DataForSEO; D-381, `docs/SEO-PLAN.md`) | **about $23 / month**, capped at $35 | Casama pays; nothing is passed on. 75 keywords checked weekly ($0.75 a month by the tool's estimate) and 25 questions asked weekly on ChatGPT, Claude, Gemini, Perplexity and Google's AI Overviews ($22.36 a month, about 4.5 cents an answer). Metered in OpenSEO (project Casama). Search Console, Bing Webmaster Tools, IndexNow and the site's own visit counts are free |
| E2B (only if hosted computers run on E2B) | **$150 / month** Pro, plus usage | Hobby has a one-time $100 credit, 1-hour sessions only |
| Sentry Team | $26 / month (annual) | 50k errors; free tier 5k errors. Since D-416 also script errors from casama.ai, the docs, the gallery and the web app's page (capped at 10 per page load, nothing sent with Do Not Track or GPC); watch the monthly count, no new line item |
| Firebase Crashlytics (D-416) | **$0** | Free with no quota on the Spark and Blaze plans; second crash reporter for the iOS, Android and macOS apps. Nothing is passed on |
| PostHog | Casama's own PostHog Cloud project 750357 (US, account hello@casama.ai, since 2026-11-19, D-430), so its events no longer count against the shared Stackwares project 637030. Free for the first 1M events a month; about $0.02–0.04 per monthly active person after that; error tracking free to 100k exceptions a month. | Then from $0.00005 per event |
| Google Analytics 4 (D-397, `docs/GA4-PLAN.md`) | **$0** | Standard GA4 and Firebase Analytics are free; the same events as PostHog (minus rollups) go there too. BigQuery daily export (D-439) goes to project `kasama-ai`, which has billing on: export is free up to 1M events a day, and storage and queries stay free within 10 GB stored and 1 TB queried a month (above that about $0.02 per GB a month stored and $6.25 per TB queried). Streaming export, the paid part, is off. Nothing is passed on |
| Langfuse (optional) | $0 up to 50k units, then $29 / month | |
| Email: Zoho Mail | $1–4 per mailbox / month | People's inboxes only (hello@, support). App mail moved to ZeptoMail (D-318) |
| Cloudflare (DNS, site, docs, gallery, tunnel) | $0; Workers Paid $5 / month if needed | The gallery (D-184) is static assets: free, no bandwidth charge; casama.link's page (D-317) runs its Worker on every request (to redirect www), inside the free 100,000 requests a day; R2 at $0.015 per GB-month only if images outgrow the static limits |
| Web app's large files (R2 bucket `casama-app-large`, D-316) | $0 within the free tier (10 GB-month, 10 M reads a month) | Then $0.015 per GB-month and $0.36 per million reads, no egress fee. About 0.1 GB per deploy (plain, Brotli and gzip copies of `main.dart.wasm`/`main.dart.js`); old keys stay for rollbacks. Each data centre caches its copy, so R2 is read about once per place per deploy |
| Off-site database backups (R2 bucket `casama-backups`, D-197) | $0 within the 10 GB-month free tier | Then $0.015 per GB-month, no egress fee. Daily age-encrypted dumps, 14 days kept |
| Unsplash API (wallpaper photo search, D-087) | $0 | Free at both Demo (50 requests/hour) and Production rate limits; Unsplash reserves the right to charge for very heavy use |
| Domain casama.ai | about $80 / year | Unverified; check the Cloudflare dashboard |
| **Casama Link: the address zone** (a new domain, never casama.ai; D-296) | about $10–30 / year | Not bought yet; Oliver buys it. Every linked self-hosted server gets `<label>.<zone>` |
| **Casama Link: Cloudflare tunnels and DNS** (D-296) | **$0 for the first 1,000 tunnels** on the account, then **$4.50 per tunnel a month**, idle ones too. DNS: a new Free zone holds **200 records** (2 per server, so about 100 servers); a Pro zone (about $25 / month) holds 3,500 | Cloudflare's published amounts, checked 2026-11-14. Production's own tunnels count toward the 1,000. Kept under it by parking tunnels of servers silent for 14 days (`CASAMA_LINK_PARKING`, off until there are numbers) and warning the owners at 700 tunnels and at three quarters of the record limit (`CASAMA_LINK_TUNNEL_ALERT`, `CASAMA_LINK_RECORD_LIMIT`). Traffic through a tunnel is free |
| **RevenueCat** (App Store and Google Play purchases, D-297) | **$0 to $2,500 of monthly tracked revenue, then 1% of it**, measured before store commission and tax, on the whole Stackwares account | Price from revenuecat.com/pricing, checked 2026-11-15. Casama shares the account with the other Stackwares apps, so their revenue counts toward the $2,500: plan on 1% of Casama's store revenue from the first sale. Web (Dodo) sales aren't tracked, so they cost nothing here. Store prices are already higher than the web's |
| **Google Map Tiles API** (first source for bots' Map cards, D-444) | **$0 within 100,000 2D tiles/month** (Essentials free cap, per billing account), then about **$0.60 per 1,000 tiles**, cheaper at volume | Checked at developers.google.com/maps/billing-and-pricing/pricing on 2026-11-20. Casama pays; not metered or charged to anyone. **Hard-capped at $0:** project `kasama-ai` has a 2D tiles quota of **3,200/day** (31 × 3,200 = 99,200 < 100k) and **600/min**, Street View and 3D tiles at **0**; past the cap Google answers 429 and cards fall back to MapTiler, HERE, then OpenStreetMap. Tiles API is the only Maps API enabled in that project, and the key (`CASAMA_GOOGLE_MAPS_KEY`, Vaultwarden) only allows it. Budget "Casama kasama-ai project (map tiles tripwire)" emails at $1/$2.50/$5. Raise the daily quota only together with a COSTS update. Session and viewport (credit line) calls aren't billed |
| **MapTiler** (map tiles for bots' Map cards, D-310, D-428) | **$0 on Free** (100k API requests/month, 5k sessions/month, non-commercial use only); **Flex** includes **500k API requests/month** (25k sessions/month) for commercial use, then **$0.15 per 1,000 extra API requests** ($2.50 per 1,000 extra sessions); confirm Flex monthly base fee on checkout | Quotas and overage rates checked at maptiler.com/cloud/pricing on 2026-11-19 (base Flex monthly fee is shown at subscription checkout). Casama pays; not metered or charged to anyone. A map card loads about 12–20 tiles (or 4 requests per 512px HiDPI tile), more as people pan and zoom. The key ships in official builds (`CASAMA_MAPTILER_KEY`); restrict it in MapTiler's dashboard, watch usage, and rely on D-428's session-wide OpenStreetMap fallback only as a safety net (OSM allows light use only) |
| **HERE Raster Tile API** (third source for bots' Map cards, D-444) | **$0 within 30,000 tiles/month** on the Base plan, then about **$0.11 per 1,000** | Checked at here.com pricing on 2026-11-20. **Not set up:** the Base plan needs a card and HERE has **no hard cap** (usage alerts only), so official builds ship without `CASAMA_HERE_MAPS_KEY` and the app skips HERE. Turn it on only with a usage watchdog that disables the HERE app at the free limit |
| **Sites: the sites zone** (a new domain, never casama.ai or casama.link; D-329) | about $10–30 / year, bought for 3 years | Not bought yet; Oliver buys it. Every site gets `<name>.<zone>`. Casama pays; fixed |
| **Sites: second tunnel** (D-329) | $0, inside the 1,000 included tunnels | The sites zone's catch-all tunnel to the pages port |
| Apple Developer Program | $99 / year | |
| Google Play registration | $25 once | |
| Chrome Web Store developer registration (Casama for Chrome, D-323) | about $5 once | Confirm at sign-up. Edge Add-ons is free. Pushes to the extension ride the existing FCM project at $0; no hosting cost (the extension talks to the same API) |

**Floor before the first paying user: roughly $60–80 a month** (the $11 server, Sentry, Composio
Pro, mailboxes, domain, Apple). Computers run on the same server, so there's no E2B bill.

## Usage costs (scale with what people do)

The prices "in code" below are also editable in the admin console since D-373 (Services > Model
catalog, Pricing > Cost tables); the values there start as these and were not changed. Admin
computer rates win over `COMPUTER_RATES`.

| What | Our cost | How it's metered today (`usage_ledger.kind`, price in code) | Verdict |
|---|---|---|---|
| **Bot computers** | E2B: 2 vCPU / 4 GiB ≈ **$0.166 / hour**. Daytona: same ≈ **$0.166 / hour**. Own Hetzner servers: CPX42 runs about 4 computers of that size for €65 / month, ≈ **$0.025 / hour each if fully used** | `computer_seconds` at the provider's rate (D-180): E2B and Daytona $0.0504 per vCPU-hour + $0.0162 per GiB-hour; Docker $0.003 per vCPU-hour + $0.005 per GB-hour (1 vCPU / 1 GB ≈ $0.008 / hour); `COMPUTER_RATES` overrides | ✅ Real rates |
| **Models on our keys** (credits) | Per 1M tokens in / out: GPT-6.1 Sol $2 / $10, GPT-6 Luna $0.10 / $0.50, Claude Opus 5.5 $4 / $20, Sonnet 5.5 $2 / $10, Haiku 5.5 $0.10 / $0.50, Gemini 3.1 Pro $2 / $12, Gemini 3.8 Flash $0.75 / $3.75 (**doubles on 2027-01-01**), Grok 4.7 $2 / $6. Through OpenRouter: plus **5.5%** on credit purchases | `tokens_in` / `tokens_out` at OpenRouter's reported `usage.cost` when the response has it, otherwise the live price list (D-181). On Casama's key, with billing on: that cost × 1.055 × 1.3 (D-186) | ✅ Live cost, fee and 1.3 markup on Casama's key |
| **Voice calls, Gemini Live** | $3 in / $12 out per 1M audio tokens ≈ $0.005 + $0.018 per min for the audio alone. **Measured in production (2026-11-17, 16 calls, 745 s): about $0.06 a minute**, because every turn is billed the whole session so far (instructions, tools and earlier audio; text in at $0.75 per 1M): a 155 s call counted 83k text and 27k audio input tokens. D-355 cuts what a call carries. **A scripted ten-turn spoken call (D-357): $0.055 a minute before, $0.038 after**, at Google's prices; what's left is mostly the call's own audio so far, billed again each turn. If Google bills its prompt total and not the per-kind counts, $0.041: each call now records both, so one day's invoice settles it | `voice_seconds`, priced from the call's own token counts | ✅ |
| **App email: ZeptoMail** (sign-in links, invites, account emails D-302, support replies; D-318) | **$2.50 per 10,000 emails**, prepaid credits that expire 6 months after purchase; the first 10,000 were free | Casama pays. Count with `select date(sent_at), count(*) from email_outbox where sent_at is not null group by 1` plus ZeptoMail → Analytics (Auth mail isn't in `email_outbox`) | ✅ Buy a credit when the balance runs low; Amazon SES ($0.10 per 1k) if volume gets large |
| **Waitlist "You're in" emails** (Casama Cloud's invite gate) | **$0.00025 each** through ZeptoMail (1,000 people: $0.25) | Casama pays. Capped by the gate setting `daily_emails_max`: 25 while ZeptoMail's review holds the account to 100 emails a day, which sign-in links share. Joining the waitlist and claiming a code send no email. Count with `scripts/waitlist.sh stats` ("You're in" emails today), or `select count(*) from waitlist_entries where notified_at >= current_date` | ✅ Negligible. Raise `daily_emails_max` when the review passes |
| **Newsletter: Resend** (monthly email from news.casama.ai, D-404; the app-mail backup from notify.casama.ai, D-433, is on Casama's own Resend account with its own free allowance) | Free up to 1,000 contacts, 3,000 emails a month and 100 a day per account (the newsletter shares its account with sayainvitations.com); paid plans above that (check resend.com/pricing before upgrading) | Casama pays. Resend → Usage, or the Resend connector's get-usage | ✅ Free now. Upgrade before the first issue goes to more than ~90 people; Listmonk + Amazon SES ($0.10 per 1k) if the list gets large |
| **Status page** (D-304) | $0: the existing uptime Worker and its KV, about 300 writes a day (free tier 1,000) | Casama pays | ✅ |
| **Casama Help, the support assistant** (D-298) | The cloud chat model on Casama's OpenRouter key, about **$0.001–0.003 per answer** (a few thousand tokens of docs and account facts in, under 900 out) | Not charged to anyone: Casama pays. Each answer's OpenRouter `usage.cost` is added to `support_usage`; capped at **$10 a day for everyone** (`SUPPORT_DAILY_USD`) and $0.50 a person a day, 60 messages a person a day | ✅ Capped; watch `select day, usd, messages from support_usage where key = 'all'` |
| **Casama Help on the websites** (casama.ai + docs, D-401) | The same model on its own OpenRouter key "Casama Help (websites)", about **$0.001–0.002 per answer** (docs in, under 600 out); Cloudflare Turnstile is free | Not charged to anyone: Casama pays. Each answer's `usage.cost` goes into `support_usage` key `web:all`; capped at **$5 a day** (`SUPPORT_WEB_DAILY_USD`), $0.10 and 20 messages a visitor's address a day, and the key itself stops at **$100 a month** at OpenRouter | ✅ Capped twice; Admin console → Support shows today's spend, or `select day, usd, messages from support_usage where key = 'web:all'` |
| **Dictation (speech to text)** | **Whisper Large V3 Turbo on OpenRouter, $0.0002 / min** (OpenRouter list price 2026-11-13; a 2.5 s test clip cost $0.0000084), on the workspace's OpenRouter key or Casama's shared one; on the shared key charged at cost × 1.055 × 1.3 (D-194, D-261) | `stt_seconds` at OpenRouter's reported `usage.cost`; $0.0002 / min if a response has none | ✅ |
| **Read aloud and spoken audio** (text to speech; `media.audio.generate`, D-284) | Gemini 3.8 Flash-Lite TTS on OpenRouter: $6 per 1M audio tokens (25 tokens a second), about $0.009 a minute of speech; Google's rate doubles on 2027-01-01. Text in at $0.50 per 1M tokens (negligible) | `tts_chars`, **estimated** from the audio length at that rate (OpenRouter's speech endpoint reports no cost); on the shared key × 1.055 × 1.3 (D-187, D-261) | ✅ Estimate; check against the OpenRouter bill |
| **Phone calls (Twilio)** | Outbound $0.014 / min, inbound $0.0085 / min, Media Streams +$0.0044 / min, **on the workspace's own Twilio account** (D-141), plus the voice model per minute | `phone_minutes` recorded, not billable (the workspace pays Twilio). The voice model inside the call is `voice_seconds`, billable at Google's price × markup on the server's key (D-244) | ✅ |
| **Phone numbers** | $1.15 / month (local US), $2.15 (toll-free) | The workspace's own Twilio account | ✅ Not ours |
| **SMS** | $0.0083 per segment plus carrier fees ($0.0025–0.007) | The workspace's own Twilio account (SMS channel) | ✅ Not ours |
| **Apps through Composio** (our account) | Free up to 20k calls and 1k connected accounts a month. Then (Pro) **$0.002 per call** (Slack, Gmail, Calendar, Sheets, Jira, HubSpot), $0.01 (Salesforce, YouTube, Reddit), $0.0005 (others); **$0.10 once** per connected account past 1k | `app_calls`, $0.002 per call × markup, billable, paid from credits (D-244) | ✅ Charged even inside the free allowance |
| **Zoho with one sign-in** (D-350) | $0: Casama's own Zoho client calls Zoho's APIs directly, no Composio in between. Zoho's per-account daily API limits apply to the person's own Zoho plan (Books: 1,000 calls a day free, 2,000 Standard, 5,000 Professional, 10,000 Premium+) | Not metered: no cost to us | ✅ Moves Zoho calls off Composio's per-call price |
| **Check-in scans** (D-247) | Model tokens plus 2–4 Composio reads ($0.002 each) per scan. The first prod scans read 38k–192k input tokens over up to 13 turns: **$0.006–0.029 each** before markup, against $0.0002–0.0013 estimated without tools. After the 2026-11-13 fixes (reads only, no lazy loading, 8 steps, 8k-character app results) the target is **under $0.01 a scan, Composio included** | Model usage and `app_calls`, billable, under the bot's check-in cap. Event scans only for mail from people and calendar changes in the next 48 h, at least 2 h apart, at most 6 a day per bot (`event_scans_day`) | ⚠️ Re-measured 2026-11-17 (34 scans): **about $0.0135 charged for the model and about 3.7 app reads ($0.010) a scan**, over the target. Half of the model part was provider routing (fixed in D-354). D-355 makes the reads up front (two app reads a scan, no model call when nothing changed) and ends every scan with something; re-measure after the deploy |
| **Starter requests in an empty chat** (D-338) | One call on the bot's background (small) model: about 1,000 tokens in, 120 out, **≈ $0.0002 each** on DeepSeek V4.1 Flash, under $0.001 on a mid-size model. At most one per person and bot every 20 hours (3 hours while rules stand in), and only when someone opens an empty chat | `tokens_in` / `tokens_out` with no run, `meta.purpose = "starters"`, billable on Casama's key like any run; counts toward the bot's daily budget and needs credits on a credit-gated plan, otherwise rules write them for free | ✅ |
| **Web search** | Brave $5 per 1k searches; Tavily $0.008 per search; **Parallel Search (fast mode) $1 per 1k** (10 results included, $0.001 per result past 10, capped at 10); **Serper $1 per 1k** ($50 for 50k credits; $0.75–0.30 per 1k at volume, credits last 6 months); **DeepSeek Search $0.75 per 1k** (only searches with results are billed; off unless named); Exa $4–7 per 1k; our own SearXNG $0 (runs on the API server) | `search_queries`, one row per query at the price of the provider that answered, `meta.provider` names it (D-179, D-384). A cached answer (same words within 6 h, per workspace) is a row at $0 with `meta.cached` | ✅ Metered. Workspace keys pay their own. Without one, the server's chain (`SEARCH_PROVIDER_ORDER`, default Parallel → Serper → SearXNG; Casama Cloud runs DeepSeek → Parallel → Serper → SearXNG since D-386): **Casama pays** about $0.00075–0.001 a search, not billed to credits (`billable` false). At 20 searches a day that is $0.60 a month per active workspace; revisit and bill it with markup if search use grows past that |
| **Invite rewards** (D-211) | **$2 of credits to the inviter** (at most 20 friends, $40 per person) **plus a $2 welcome bonus to the friend**, both once the friend verifies and finishes a first chat: up to **$4 per friend**. Credits are spent at marked-up prices (× 1.055 × 1.3 on Casama's key), so each $2 costs about **$1.46** in model spend at most (about **$2.92 per friend**), less if never fully used. **While the invite gate is on, worst case:** with 3 invites a member, one member can cause at most $12 of credits (about $8.76 of model spend); 300 members using every invite is 900 friends and about $2,630 at the very most, spread over as long as the credits last | `credit_ledger` rows with reason `grant` and references `referral:<friend>` / `referral-welcome:<friend>`; `REFERRAL_REWARD_USD`, `REFERRAL_WELCOME_USD`, `REFERRAL_REWARD_CAP` | ⚠️ A growth cost, not usage. Fake accounts could farm it: each needs a verified address, a sign-up proof and a first run, and the cap limits one person to $40 |
| **Gallery contributor rewards** (D-315) | **$10 of credits** when an item someone submitted (packs included) reaches 50 active users, **$25** at 250 and **$75** at 1,000 (`GALLERY_REWARDS`), once per item and milestone. At most **$110 per item** (about **$80** in model spend, since credits are spent at marked-up prices and each $1 costs about $0.73 at most). For scale: one invite costs up to $2.92, and an item 50 people keep using brings far more retention than one friend | `credit_ledger` rows with reason `grant` and reference `gallery_reward:<type>/<id>:<milestone>`; `gallery_rewards` table; hourly worker job | ⚠️ A growth cost, not usage. Needs a reviewed, merged pull request and real active users (counted from distinct people's use in 14 days), so farming it means getting a farmed item merged |
| **Call summaries** (D-429) | One call on the bot's background (small) model after a call of 30 seconds or more: about 1,500 tokens of speech a minute (a 4-minute call ≈ 7,000 in, 250 out; input capped near 6,500 tokens), **≈ $0.001 each** on DeepSeek V4.1 Flash, about $0.004 on a mid-size model. Free on a local model; off per bot with "Summarize calls" | `tokens_in` / `tokens_out` with no run, `meta.purpose = "call_summary"`, billable on Casama's key like the starter requests; counts toward the bot's daily budget, and with no credits on a credit-gated plan the card simply has no summary | ✅ |
| **Bot pictures drawn with AI** (D-456) | Two images per tap on the image model (Gemini Nano Banana 2.1 at 1K, **≈ $0.034 each, ≈ $0.07 a tap**), after the image safety check below. Uploaded pictures cost nothing but storage: about 70 KB per picture in Postgres (512 and 128 px WebP), five kept per bot, plus at most two originals of up to 3 MB | `media_images` with no run (or the run, when the bot draws itself), `meta.purpose = "bot_picture"`, billable with markup on Casama's key like any image; needs credits on a credit-gated plan. At most 20 drawings and 20 uploads a day per bot | ✅ |
| **Image and video safety check** (D-419) | One call on the bot's background (small) model before each image or video: about 450 tokens in, under 20 out, **≈ $0.0001 each** on DeepSeek V4.1 Flash. Free on a local model | `tokens_in` / `tokens_out` with no run, `meta.purpose = "media_safety"`, billable on Casama's key like the starter requests; an obvious refusal makes no call | ✅ |
| **Decision models** (D-454; docs/DECISION-MODEL-PLAN.md) | Input only, no output charge. Per 1M input tokens on OpenRouter: Jev 1.14 (TypeSafe) **$0.042**, GPT-6 Luna Decisions (OpenAI) $0.10, Decider Flash v1.2 (Perplexity) $0.01. A call is about 3,000–4,000 tokens: **$0.00004–0.00017 each**. Every use is off until the owner sets it in Admin → Decisions | `tokens_in` with `meta.purpose = "decide:<use>"` at OpenRouter's `usage.cost`. **Shadow calls: Casama pays** (`billable` false, `cost_usd` 0 so no budget moves, `upstream_cost_usd` set). A use that is on: billable on Casama's key like the starter requests. Shadow with two models (Jev and OpenAI's, the default) on today's volume: under $0.05 a day | ✅ Metered; see `decision_log` for answers, latency and cost per model |
| **Images** | Per image at 1K: Gemini Nano Banana 2.1 $0.034 on OpenRouter (default with an OpenRouter key; LM Arena rank 7, Artificial Analysis rank 6). GPT Image 2.6 medium about $0.043 (LM Arena ranks 2–4); its max tier about $0.21 (ranks 1–4). OpenRouter is the only image service (D-260) | `media_images` at OpenRouter's reported cost (D-185); unknown models at $0.04 | ✅ Per model |
| **Video** | Gemini Omni Flash 1.2 at 720p with audio on OpenRouter, **$0.069504 a second** (same as Google direct; D-189, D-261). Animating a picture sends it as the first frame, at the same price | `media_video_seconds` at the finished job's reported `usage.cost`, else $0.069504 a second; unknown models at $0.10 / second | ✅ |
| **Paid data (places, emails, SEO)** | What the data seller charges | `data_calls`, cost + 20% | ✅ (consider +30% to cover payment fees) |
| **Memory embeddings** | OpenAI text-embedding-3-small $0.02 per 1M tokens, also on the shared OpenRouter key when a workspace has no OpenAI key (D-194); about $0.0000006 per memory | Not metered | ✅ Negligible; meter if volume ever matters |
| **Live view and take control** (TURN relay) | Our own coturn on the server: bandwidth only (about €1 / TB over 20 TB). Cloudflare TURN $0.05 / GB if we switch | `stream_seconds` (not priced) | ✅ For now |
| **Live view away from a self-hosted server** (Casama Link, D-296) | **Cloudflare TURN: the first 1,000 GB a month free, then $0.05 per GB** (checked 2026-11-14). A desktop stream is roughly 0.7–1.4 GB an hour (an estimate at 1.5–3 Mbps; measure it), so about **$0.03–0.07 an hour** past the free amount. The free 1,000 GB is about 700–1,400 hours of watching across all customers | **Not metered per workspace.** Gated by plan (`link_live_view`: Plus and up), 24 credential requests a day per key, credentials that last 12 hours. People on the server's own computer never use it | ⚠️ Unmetered. One workspace watching 8 hours a day is about 170–340 GB a month ($8–17 past the free amount), which is more than Plus earns. Watch the Cloudflare TURN usage; if it shows up, meter it or cap hours per plan |
| **Push and call rings for self-hosted servers** (Casama Link relay, D-296) | $0: Firebase and Apple push are free | Not metered; 2,000 pushes an hour per key | ✅ |
| **Bots on the Lock Screen and in the notch** (D-324) | $0: Firebase and Apple's Live Activity pushes are free. The server adds one cached token lookup per run event that changes what a phone shows, and at most one small push every 5 seconds per run a phone follows; the Mac asks for unfinished runs every 3 seconds while a bot works | Not metered; self-hosted live pushes count toward the relay's 2,000 an hour per key | ✅ |
| **Home and Lock Screen widgets** (D-405) | $0: WidgetKit pushes and Firebase data messages are free. The server builds one small glance (8 short reads) per widget refresh, answered with 304 when nothing changed; widget keys are held to 120 requests an hour. Refresh pushes go at once only for Needs you changes, otherwise at most one per person every 5 minutes | Not metered; self-hosted widget pushes count toward the relay's 2,000 an hour per key | ✅ |
| **Bot widgets: the Canvas widget** (D-455) | $0: no new paid service. The same free widget pushes as D-405. The server adds one small indexed read per Canvas refresh (304 when nothing changed) and keeps a few hundred KB of shrunk pictures per canvas. A rotation costs one model run for up to a year of daily changes; a routine that rewrites a canvas spends credits like any routine | Not metered | ✅ |
| **Live data cards** (D-458: weather, prices, rates, time, hazards, reference) | **$0 as built.** MET Norway, Frankfurter, CoinGecko (Demo tier, attribution), USGS, GDACS, NWS, Wikipedia, Wiktionary, Open Library, Nager.Date and GeoNames are free; sun and moon are worked out locally. **Open-Meteo's free API is non-commercial** (10,000 calls/day; checked 2026-11-20): with `BILLING_ENABLED` on it's used only with `LIVE_OPEN_METEO_KEY` (a paid commercial plan, price on open-meteo.com/en/pricing) or self-hosted, otherwise rain chances, UV and air quality are left out. Yahoo Finance and ESPN have no published API terms and run only where billing is off. **Not bought:** a stock plan for Casama Cloud (`LIVE_FINNHUB_KEY`; likely $30–200/month, check before buying), flights (aviationstack), parcels (17TRACK), films (TMDB) | Shared cache per provider and query (`live_data_cache`: weather 30–60 min per 0.1° grid point, prices 60 s, rates 3 h), so a popular question is one upstream call per window for everyone; refreshes with no model call. Counted in `live_data_daily` (calls, cache hits, errors per provider and day), not in `usage_ledger` while every provider is free. A paid provider, once added, writes `usage_ledger` kind `live_data_calls` per upstream call (cache hits free) and gets its own row here. Saves tokens: a weather answer was a search, page reads and 3–8k tokens; now one cached call and ~300 tokens plus a `tools.load` in a chat's first use | ✅ $0; revisit when a paid provider is switched on |
| **Apple Watch and Wear OS** (D-410) | $0 new: no new paid service. Apple and Firebase pushes are free. **Watch dictation and read-aloud are charged exactly as from the phone** (the dictation and voice lines above). The server adds a key lookup per call and small reads; watch keys are held to 60 requests a minute. No model call is added: quick replies are a fixed list | Dictation as `stt_seconds`, read-aloud as on the phone; the rest not metered. Self-hosted watch pushes count toward the relay's 2,000 an hour per key | ✅ |
| **Sign-in and other email** | ZeptoMail: $0.00025 per email | Not metered | ✅ Negligible per user |
| **Bot mail: receiving** (BOT-EMAIL-PLAN) | $0, unlimited, on Cloudflare Email Routing | Not metered | ✅ Spam costs nothing |
| **Bot mail: storage** (D-451) | On the server's own disk, no vendor charge. Mailboxes are 100 MB / 500 MB / 1 GB / 2 GB per address; originals deleted after 30 days; people can delete mail | Mailbox size per address in Admin | ✅ Free; move to R2 ($0.015 per GB-month) once the disk passes 60% |
| **Bot mail: sending** (BOT-EMAIL-PLAN, D-451) | Workers Paid $5 / month (3,000 included), then **$0.35 per 1,000**; hard bounces count. Cloudflare allows 1,000 a day to start; `MAIL_SEND_DAILY_MAX` stops all workspaces together at 900, so the bill can't pass ≈ $14 / month until both are raised | `emails_sent`, with its real cost, not billable. Worst case a workspace at its daily cap every day: Free $0.21, Plus $0.53, Pro $1.58, Max $3.15 a month | ✅ Covered by plan prices |
| **File storage** (the Library, D-274, D-276) | Cloudflare R2 $0.015 per GB-month (no egress fee); on the production VPS today, its own disk (D-199) | Counted per workspace (`organizations.storage_bytes`: pages, generated media, kept files, chat attachments, knowledge uploads (D-334)); capped by plan `storage_gb`: Free 1, Plus 10, Pro 50, Max 200 GB. A full Max workspace costs about $3 a month on R2. Older versions of a kept file (up to 5) aren't counted | ✅ Capped; at the cap nothing new is kept and nothing is deleted |
| **Custom hostnames for connected and bought domains** (Cloudflare for SaaS, D-329) | **100 free, then $0.10 per hostname a month** (a domain with `www` and the bare name is 2) | Casama pays, covered by plan prices and domain prices. Counted hourly by the domains upkeep; owners get a notice at 80 and 95 of the included 100 | ✅ At most $2.40 a year per domain |
| **Domains bought through Casama** (Name.com reseller, D-329) | Wholesale, read live from the registrar (.com about $11.2–12.5 a year) | The person pays: price = round up to .99 of (cost × `domain_markup` 1.25 + `domain_fee_usd` $1.50), both in `billing_settings`. Every order stores `cost_usd` and `price_usd` | ✅ .com at $12.03 cost sells at $16.99; about $1.06 left worst case |
| **Dodo on domain payments** (D-329) | 4% + $0.40, +1.5% international, +0.5% on on-demand (mandate) charges; refund $1, chargeback $30 | Covered by the domain price | ✅ Per order |
| **DNS checks for connected domains** (DNS-over-HTTPS, D-329) | $0: public resolvers | — | ✅ |
| **Abuse checks** (App Check, reCAPTCHA) | Free to 10k assessments / month, then about $1 per 1k | n/a | ✅ |

## Fees on revenue

| Channel | What they keep |
|---|---|
| Web and desktop (Dodo Payments, merchant of record) | **4% + $0.40** per payment, +1.5% international, +0.5% subscriptions. Refund $1, chargeback $30 |
| Apple App Store | **15%** under the Small Business Program (under $1M a year), otherwise 30% in a subscription's first year and 15% after |
| Google Play (US, EEA, UK since 2026-06-30) | Subscriptions **10% + 5% billing fee**; other purchases 20–25% + 5%. Elsewhere 15% |

So a $20 subscription becomes about **$18.70 on the web** (outside the US: about $18.40) and **$17 on
iOS or Android**. Small prices lose the most to the $0.40 fixed fee: a $5 credit pack keeps about $4.40.

## Plans (D-244, revised D-249, 2026-11)

Plans, packs and the markup live in the database and change from the Admin screen without a deploy.
Each usage row keeps what the provider charged us next to what the workspace was charged
(`upstream_cost_usd`, D-395); the admin console's **Usage margin** card adds them up. Since
D-400 that covers every charge: computer time at the provider's rate (`COMPUTER_RATES`, not
Admin → Pricing) and the server's own web search, which Casama pays and doesn't charge.
Credits are spent at cost × markup (1.3; OpenRouter also × 1.055), so each $1 of included credits
costs Casama about **$0.77** at most. A Docker computer costs about $0.008 an hour per size step
(1 vCPU + 1 GB), so 2× is about $0.016 and 4× about $0.032. Every price is at most $899, so the same
list works on the web, the App Store (no request for high price points) and Google Play ($999.99 cap).

| Plan | Price | Includes | Our cost if fully used | Margin after fees (web / iOS) |
|---|---|---|---|---|
| Free | $0 | $1 credits, 3 bots, 1 computer (1 running, 1×), 5 h, 1 seat | about $0.80 a month (plus invite credits) | marketing |
| Plus | **$15** / $150 a year | $5 credits, 10 bots, 2 computers (1 running, 1×), 30 h, 1 seat | about $4.10 | about 66% / 58% |
| Pro | **$49** / $490 | $15 credits, unlimited bots, 5 computers (2 running, 2×), 100 h, 3 seats | about $13.20 | about 68% / 58% |
| Max | **$99** a month | $30 credits, unlimited bots, 10 computers (2 running, 4×), 300 h, 10 seats | about $32.70 | about 62% / 52% |
| Max yearly | **$899** a year (about $74.90 a month) | the same | about $32.70 a month | about 52% / 41% |
| Plus / Pro / Max weekly (D-432) | **$7.99 / $19.99 / $39.99** a week | the monthly plan's limits; a quarter of its credits each week ($1.25 / $3.75 / $7.50); no trial, no extra people | about $0.95 / $3.05 / $7.55 a week | about 79% / 73%, 78% / 70%, 76% / 66% |
| Extra person (Pro, Max; web only) | **$12** a month ($120 a year) | one more seat | none directly (usage stays within the plan's credits and hours) | about 92% |
| Pro trial (7 days, once per person) | $0 | $2 credits, 10 h | about $1.70 per trial | acquisition |
| Credit packs | $10 / $25 web; **$12.99 / $29.99** in the stores | $10 / $25 of credits | $7.70 / $19.25 | about 16% web; 13–30% stores |

Margins are after payment fees with everything used, at the 1.3 markup; store figures assume the
15% rate, so **enroll in Apple's Small Business Program and Google Play's 15% tier** (at 30% the store
column drops by about 15 points). Raising the markup to **1.4** (pending Oliver's yes; it's a live
setting in the Admin screen) makes $1 of included credits cost about $0.71 and lifts each plan by
about 2 points: Plus 67% / 60%, Pro 70% / 60%, Max 64% / 54%, Max yearly 54% / 43%.

**Casama Link (D-296)** adds nothing to these columns. Every plan links self-hosted servers
(Free 1, Plus 1, Pro 3, Max 10), with the address, sign-in by QR code and push free: each server
costs us one tunnel of the 1,000 Cloudflare includes. Plus and up also get live video away from
home, the one part that costs per use (see the usage table).

Weekly plans (D-432) are priced as an anchor at about twice the monthly rate. Dodo's $0.40 fixed fee
is charged each week, four times as often as on monthly, and computer hours keep their monthly cap,
so a single paid week can use a month of hours (worst case Max: 300 h × $0.032 ≈ $9.60). Both are
covered by the price.

Most people won't use everything included, so real margins are higher. The step to watch is server
capacity: the $11 VPS has about 9 GB for computers. Memory sizes are limits, not reservations, so a
4× computer only uses what it needs, but a few busy Max workspaces fill the server (Max runs 2 at
once, not 3, until then); move to a larger
server (about €159 a month, 128 GB) by about 15–20 paying workspaces.

New people spending free credits can use up OpenRouter's $50 daily cap (one person spending all $3 on day one is $2.19 upstream; 23 of them are $50), so admissions stay at 50 a day or fewer until the cap is raised.

## Lowering costs (so prices can come down)

Ranked by saving. ✅ = done, ☐ = to do.

1. **Bot computers on our own dense servers** (biggest lever, up to 15× cheaper): a dedicated server
   such as Hetzner AX102 (16 cores, 128 GB, €159 / month) holds about 28 standard computers, because
   bots mostly wait on the model (CPU can be shared; memory is the limit). That is about **$0.01 per
   computer-hour** against $0.17 on E2B or Daytona. ☐ Needs a server. Also, on any provider:
   - ✅ Headless by default at 1 vCPU / 1 GB (instead of 4 GB); the desktop only when needed.
   - ✅ Sleep after 5 minutes idle instead of 10 (D-178). Live viewers and open terminals keep a
     computer awake; waking restores its files.
   - ✅ A computer switched to the desktop for a takeover goes back to headless when it next
     sleeps (D-178). A desktop someone picks stays.
   - ✅ Chat thumbnails of videos and PDFs on a computer (D-226) never wake or keep it awake, are
     made one at a time under an 8 s limit, and are cached on the computer and the device. PDF
     cards no longer download the whole file (and wake the computer) just to draw page one.
   - Casama runs computers on **Docker** (all of them today); E2B and Daytona are optional
     adapters for self-hosters, not something Casama pays for. If they're ever used: computers
     carry their size and Daytona gets it on create; E2B's size comes from its template, so build
     those at 1 vCPU / 1 GB (headless) and 2 vCPU / 4 GB (desktop).
   - A small warm pool (built); EU servers (US ones cost about twice as much).
2. **Models on our keys:**
   - ☐ The scan gate (D-454): a decision model checks a scan's changed reads first and, when it is
     sure nothing is worth telling, ends the scan without the model, at most 3 in a row per bot.
     Measured 2026-11-18 to 20: 24 of 35 model scans found nothing, about 1% of spend; the gate's
     own calls cost about as much, so it is roughly even. Built and off; turned on only after its
     shadow results meet the bar in the plan.
   - ✅ Chat history on a fixed budget (D-253): 16k tokens of recent turns, older ones folded into
     the conversation's summary down to 8k. Before, history grew to 70% of the window (about 730k
     tokens on Muse Ember) before any summary, so a long chat's message cost up to about $0.07–0.20
     on Muse Ember and 20× that on Sonnet-class models; now about $0.006 on Muse Ember, flat.
     Summaries cost about $0.002 each, once every couple of dozen turns.
   - ✅ Anthropic prompt caching: Claude requests ask for caching, so the instructions, tools and
     conversation so far are read back at a tenth of the price next turn. OpenAI, Gemini and xAI
     cache matching prefixes on their own.
   - ✅ Cached and cache-write tokens are recorded and priced (`costOf`): reads at 0.1× input (0.25× on
     Gemini), Anthropic writes at 1.25×.
   - ✅ Background work (conversation summaries, memory) runs on DeepSeek V4.1 Flash 1017 (Muse Ember before D-258) when the
     bot is on OpenRouter, and on the provider's small model otherwise (Claude Haiku 5.5, GPT-6 Luna,
     Gemini 3.5 Flash-Lite), when the bot hasn't picked a cheap model (D-187). It falls back to
     the main model.
   - ✅ Output cap on Casama's key is 16,384 tokens a step (D-268; was 4,096, which cut replies
     mid-way). A cut-off reply is continued at most 3 times, and long runs trim old tool results
     at 75% of the context window, so a single run can't grow its input without bound. Run and
     day budgets still hold total spend.
   - ✅ Onboarding already puts the person's own AI first (ChatGPT subscription, own key, local
     model); Casama credits aren't offered there.
   - ☐ Batch APIs (50% off) for work that can wait hours. Routines run at set times, so only for
     truly deferrable jobs.
   - ✅ The cheapest provider first on our key (D-354, `CLOUD_MODEL_PROVIDER_SORT=price`). A model's
     price on OpenRouter is its cheapest provider's: DeepSeek V4.1 Flash 1017 is sold by 50, from
     $0.036 to $0.60 per 1M input tokens, each with its own prompt cache. Without a preference
     OpenRouter spread our calls across them: in production (2026-11-13 to 17) 19% of calls cost 2
     to 7.5 times the list price and were 47% of model spend, and a call that landed on a new
     provider lost its cache. Replaying that traffic on the cheapest provider with the cache
     holding inside each run: $0.79 instead of $1.70. Twelve tool-use tasks run twice on each of
     eight routes passed alike (22 to 24 of 24), and the cheapest route was the fastest.
   - ✅ The rest of the usage plan (`docs/USAGE-PLAN.md`, D-355): check-ins read first, skip an
     unchanged scan and stop at 40% of the day's limit; a fixed 48,000-token budget for a task's
     own steps; a conversation keeps its tool groups and its history stays cached between
     messages; smaller always-sent tools; smaller voice sessions. ☐ Measure each on production
     after the deploy with the queries in that plan's section 1.
   - ☐ Call the big providers directly with our keys instead of OpenRouter (saves its 5.5% fee).
3. **Apps:** ☐ connect directly wherever the app allows (free); register our own GitHub, Asana and
   HubSpot apps (free, needs Oliver's sign-in); for the rest, our own app inside Composio ($0.0003 a
   call instead of $0.002, free connections, Casama on the sign-in screen).
4. **Voice and phone:** ✅ Gemini Live is the only call service, in the app and on the phone, on
   the workspace's Google key or else the server's (D-187, D-260). Read-aloud and dictation run on
   OpenRouter like the models (D-261). ✅ Call guardrails (D-426): a quiet call hangs up after a
   minute (was two), a call lasts at most an hour, and a call on credits ends when the credits,
   the daily or monthly limit or the bot's budget run out, checked every 20 s instead of only at
   the start. At about $0.04–0.06 a minute, the longest call costs Casama about $2.40–3.60.
   ☐ Compare Telnyx and other carriers with Twilio.
5. **Search:** ✅ our own SearXNG (free) for workspaces without a Brave or Tavily key (D-179; turn it
   on in production with `--search`). ☐ Cache results;
   Gemini grounding's 5,000 free searches a month.
6. **Platform and fees:** our own Postgres on the same server (not Supabase Cloud); R2 for snapshots
   (no egress fees); our own TURN (built); free tiers for PostHog and Sentry at first; yearly plans
   and $10+ credit packs so Dodo's $0.40 fee matters less; web checkout links on iOS in the US where
   Apple must allow them (re-check the 2026 rules).

**What it allows** (computers at about $0.01 an hour, most apps off Composio, credits at 1.4× cost,
smaller included credits):

| Plan | Price | Our cost if fully used | Margin after fees (web / iOS) |
|---|---|---|---|
| Plus: 30 computer hours, $5 credits | **$15** | about $4.00 | 71% / 69% |
| Pro: 100 hours, $10 credits, 1 phone number | **$39** | about $9.80 | 73% / 70% |
| Max: 400 hours, $50 credits, 3 numbers | **$149** | about $45.00 | 68% / 65% |

Competitors for reference (third-party reports, 2026): Manus $20 / $40 / $200, SuperGrok $30 /
$100 / $300, Lindy $29.99 / $99.99 / $199.99, ChatGPT and Claude $20 / $100 / $200. Without the
cheaper infrastructure the suggestion is $24 / $59 / $199 (see the plan table in the pricing
discussion); with it, $15 / $39 / $149 undercuts every product that gives bots their own computer.

## To fix before charging anyone

1. ✅ **Computer time:** charged at the real provider rate, vCPU-hours plus GiB-hours (D-180), instead
   of the $0.01 per vCPU-hour placeholder. Re-set `COMPUTER_RATES` for Docker when the server changes.
2. ✅ **Model prices:** OpenRouter's live per-model prices (refreshed daily) win over the
   hand-written table, and nothing on OpenRouter is priced at $0 unless it's a `:free` model
   (D-181). ☐ Add OpenRouter's 5.5% credit fee through the markup setting (item 5).
3. ✅ **Meter what isn't metered** (D-244): Composio calls (`app_calls`) and the voice model inside
   phone calls. Twilio minutes, numbers and SMS are the workspace's own account. (Web search ✅, D-179.)
4. ✅ **Per-model media prices** for images and video (D-182).
5. ✅ **A markup setting** (`billing_settings.markup`, default 1.3, Admin screen; D-244) applied to
   usage on Casama's keys, and plan prices that account for store and payment fees.
6. **Caps per plan** for Composio calls, search, storage and computer hours, so one heavy bot can't
   run up the bill. Computer hours ✅ and a daily cap on Casama's key ✅ (`cloud_daily_usd`); every
   metered cost is paid from credits, so credits bound the rest.

## Sources (checked 2026-11-11)

E2B e2b.dev/pricing · Daytona daytona.io/pricing · Hetzner hetzner.com/cloud,
hetzner.com/dedicated-rootserver/matrix-ax · OpenAI developers.openai.com/api/docs/pricing ·
Anthropic platform.claude.com/docs/en/about-claude/pricing · Google aistudio.google.com/docs/pricing ·
xAI docs.x.ai/docs/models · OpenRouter openrouter.ai/pricing · Twilio
twilio.com/en-us/voice/pricing/us, twilio.com/en-us/sms/pricing/us, twilio.com/en-us/stun-turn/pricing ·
Brave brave.com/search/api · Tavily tavily.com/pricing · Exa exa.ai/pricing ·
Supabase supabase.com/pricing · Cloudflare developers.cloudflare.com/r2/pricing,
developers.cloudflare.com/workers/platform/pricing, developers.cloudflare.com/realtime/turn,
developers.cloudflare.com/email-service/platform/pricing (bot mail, checked 2026-11-20) ·
Composio composio.dev/pricing/platform and the Casama org's billing page · Resend resend.com/pricing ·
Zoho zoho.com/mail/zohomail-pricing.html · ZeptoMail zoho.com/zeptomail/pricing.html · Sentry sentry.io/pricing · PostHog posthog.com/pricing ·
Langfuse langfuse.com/pricing · Dodo Payments dodopayments.com/pricing · Apple
developer.apple.com/app-store/small-business-program · Google Play
support.google.com/googleplay/android-developer/answer/112622 · reCAPTCHA
docs.cloud.google.com/recaptcha/docs/compare-tiers · casama.ai renewal cfdomainpricing.com (unofficial).

## Comps (free plans for friends)

Comps (`docs/COMP-PLANS-PLAN.md`, D-461) give a workspace a paid plan free for 1 to 12 months, by an
instance owner's grant or a gift code. No new vendor or paid dependency: a comp costs what its
included credits and computer hours are spent on, at the rates above. Worst case per comp a month,
everything used: **Plus about $4.10, Pro about $13.20, Max about $32.70**. With the cap of 50 running
at once (Admin setting `comp_max_active`), the ceiling is about **$660 a month** if all are Pro and
about $1,635 if all are Max (Max only by direct grant). Codes are Plus and Pro only by default.

Grants land in `credit_ledger` as `monthly:<YYYY-MM>:<plan>:comp`; usage stays in `usage_ledger`.
What comps actually cost, per month:

```sql
select date_trunc('month', u.created_at) as month, count(distinct c.org_id) as workspaces,
       round(sum(coalesce(u.upstream_cost_usd, 0)), 2) as upstream_usd
from public.comps c
join public.usage_ledger u on u.org_id = c.org_id
  and u.created_at >= c.starts_at and u.created_at < coalesce(c.ended_at, c.ends_at)
group by 1 order by 1 desc;
```

Comps are left out of revenue: they never go through a store or Dodo and fire no purchase events.
Count them on their own with `subscriptions.source = 'comp'`; Admin → Pricing's workspace count per
plan includes them.

## Saved resets

Saved resets refill included credits without a purchase. Campaign previews show the maximum
charged-credit exposure; budgets cap actual refills, and settings cap uses per billing period
and the number held. The preview uses the current billing markup: at 1.4 it estimates
$0.714 in provider cost per $1 refilled. OpenRouter’s fee is already included on both sides of
the usage price and is not counted a second time. This is an estimate, not an additional vendor charge:
actual model, computer and service costs remain recorded in `usage_ledger` when used. Refills
appear in `credit_ledger` with reason `reset`, with a period-ending credit lot. Undo removes only
that lot's unspent portion. There is no new paid dependency.
