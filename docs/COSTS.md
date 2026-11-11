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
  `cost_usd = 0` (or `source = chatgpt_plan`). Everything else (computers, phone, voice on our keys,
  Composio, search on our keys) is ours to cover.
- **Stores and payments take a cut before we see anything** (see "Fees on revenue"). A price has to
  cover costs *after* that cut.
- **Rule of thumb:** charge at least **cost × 1.3** for metered usage, and price plans so that
  `price × (1 − store fee) ≥ included costs × 1.3 + fixed costs per user`.

## Fixed costs (paid whether or not anyone uses it)

| Item | Cost | Notes |
|---|---|---|
| Server for API, worker, database (Hetzner CPX42, 8 vCPU / 16 GB, EU) | €59.49–69.99 / month | One machine to start; self-hosted Postgres instead of Supabase Cloud. Traffic: 20 TB included, then about €1/TB |
| Supabase Cloud (only if we don't self-host Postgres) | from $25 / month | Includes 8 GB database, 250 GB egress, 100k monthly active users |
| Composio | $0 now (Hobby), **$29 / month** on Pro | Pro needed at launch for the data processing agreement; usage on top, see below |
| E2B (only if hosted computers run on E2B) | **$150 / month** Pro, plus usage | Hobby has a one-time $100 credit, 1-hour sessions only |
| Sentry Team | $26 / month (annual) | 50k errors; free tier 5k errors |
| PostHog | $0 up to 1M events / month | Then from $0.00005 per event |
| Langfuse (optional) | $0 up to 50k units, then $29 / month | |
| Email: Zoho Mail | $1–4 per mailbox / month | hello@ sends sign-in email; switch sign-in mail to Resend ($20 / month for 50k) when volume grows |
| Cloudflare (DNS, site, docs, tunnel) | $0; Workers Paid $5 / month if needed | |
| Domain casama.ai | about $80 / year | Unverified; check the Cloudflare dashboard |
| Apple Developer Program | $99 / year | |
| Google Play registration | $25 once | |

**Floor before the first paying user: roughly $110–150 a month** (server, Sentry, Composio Pro,
mailboxes, domain, Apple), plus E2B's $150 if we use it for computers.

## Usage costs (scale with what people do)

| What | Our cost | How it's metered today (`usage_ledger.kind`, price in code) | Verdict |
|---|---|---|---|
| **Bot computers** | E2B: 2 vCPU / 4 GiB ≈ **$0.166 / hour**. Daytona: same ≈ **$0.166 / hour**. Own Hetzner servers: CPX42 runs about 4 computers of that size for €65 / month, ≈ **$0.025 / hour each if fully used** | `computer_seconds`, **$0.01 per vCPU-hour** (placeholder) = $0.02 / hour for 2 vCPU | ❌ **8× too low on E2B or Daytona.** Use the real provider rate (vCPU and RAM) |
| **Models on our keys** (credits) | Per 1M tokens in / out: GPT-6.1 Sol $2 / $10, GPT-6 Luna $0.10 / $0.50, Claude Opus 5.5 $4 / $20, Sonnet 5.5 $2 / $10, Haiku 5.5 $0.10 / $0.50, Gemini 3.1 Pro $2 / $12, Gemini 3.8 Flash $0.75 / $3.75 (**doubles on 2027-01-01**), Grok 4.7 $2 / $6. Through OpenRouter: plus **5.5%** on credit purchases | `tokens_in` / `tokens_out` from a hand-written price table | ❌ **Table is stale** (old model names), **open-weight models (Llama, Qwen, DeepSeek) priced at $0**, and no OpenRouter fee. Use OpenRouter's live per-model prices |
| **Voice calls, OpenAI Realtime** | Audio $32 in / $64 out per 1M tokens ≈ $0.02 / min listening + $0.08 / min speaking. Mini model: about a third | `voice_seconds`, **$0.06 / min** estimate | ⚠️ Close for a balanced call; long bot monologues cost more. Price from reported token usage, like Gemini |
| **Voice calls, Gemini Live** | $3 in / $12 out per 1M audio tokens ≈ $0.005 + $0.018 per min | `voice_seconds`, priced from the call's own token counts | ✅ |
| **Dictation (speech to text)** | OpenAI mini transcribe $0.003 / min; Deepgram $0.0077 / min | `stt_seconds`, $0.003 / min | ✅ for OpenAI mini; ❌ if Deepgram is used on our key |
| **Read aloud (text to speech)** | OpenAI tts-1 $15 per 1M characters; ElevenLabs $40–80 per 1M | $0.015 per 1k characters | ✅ for OpenAI; ❌ for ElevenLabs on our key |
| **Phone calls (Twilio)** | Outbound $0.014 / min, inbound $0.0085 / min, **Media Streams +$0.0044 / min**, plus the voice model per minute | `phone_minutes`, $0.014 / min only | ❌ Missing Media Streams and the voice model's cost in the same call |
| **Phone numbers** | $1.15 / month (local US), $2.15 (toll-free) | Not charged | ❌ Charge monthly per number held |
| **SMS** | $0.0083 per segment plus carrier fees ($0.0025–0.007) | Not metered separately | ❌ |
| **Apps through Composio** (our account) | Free up to 20k calls and 1k connected accounts a month. Then (Pro) **$0.002 per call** (Slack, Gmail, Calendar, Sheets, Jira, HubSpot), $0.01 (Salesforce, YouTube, Reddit), $0.0005 (others); **$0.10 once** per connected account past 1k | Not metered | ❌ Add a `app_calls` kind and cap it per plan |
| **Web search on our key** | Brave $5 per 1k searches; Tavily $0.008 per search; Exa $4–7 per 1k | Not metered | ❌ Meter per search |
| **Images** | fal FLUX schnell $0.003 per image; FLUX dev $0.025; Nano Banana / Seedream about $0.04 | $0.003 per image | ⚠️ Right for schnell only; price per model |
| **Video** | fal per second: Kling 2.5 / 2.6 Pro $0.07, Kling v3 $0.14, Grok Imagine $0.05, PixVerse V6 $0.005 | `media_video_seconds`, $0.04 / second | ❌ Below Kling. Price per model |
| **Paid data (places, emails, SEO)** | What the data seller charges | `data_calls`, cost + 20% | ✅ (consider +30% to cover payment fees) |
| **Memory embeddings** | OpenAI text-embedding-3-small $0.02 per 1M tokens | Not metered | ✅ Negligible |
| **Live view and take control** (TURN relay) | Our own coturn on the server: bandwidth only (about €1 / TB over 20 TB). Cloudflare TURN $0.05 / GB if we switch | `stream_seconds` (not priced) | ✅ For now |
| **Sign-in and other email** | Zoho: within the mailbox. Resend: $0.90 per 1k past the plan | Not metered | ✅ Negligible per user |
| **File storage** | Cloudflare R2 $0.015 per GB-month (no egress fee); Supabase $0.0213 per GB | Not metered | ✅ Cap per plan (`limits`) |
| **Abuse checks** (App Check, reCAPTCHA) | Free to 10k assessments / month, then about $1 per 1k | n/a | ✅ |

## Fees on revenue

| Channel | What they keep |
|---|---|
| Web and desktop (Dodo Payments, merchant of record) | **4% + $0.40** per payment, +1.5% international, +0.5% subscriptions. Refund $1, chargeback $30 |
| Apple App Store | **15%** under the Small Business Program (under $1M a year), otherwise 30% in a subscription's first year and 15% after |
| Google Play (US, EEA, UK since 2026-06-30) | Subscriptions **10% + 5% billing fee**; other purchases 20–25% + 5%. Elsewhere 15% |

So a $20 subscription becomes about **$18.70 on the web** (outside the US: about $18.40) and **$17 on
iOS or Android**. Small prices lose the most to the $0.40 fixed fee: a $5 credit pack keeps about $4.40.

## What the current placeholder plans would cost us

The plans in the database (`20261115000001_billing.sql`, no prices set yet):

| Plan | Includes | Our cost if fully used (E2B or Daytona computers) | Minimum price to break even with a 30% margin |
|---|---|---|---|
| Free | $1 credits, 5 computer hours, 2 bots | $1 + 5 × $0.166 ≈ **$1.83 a month per active user** | Free users must be capped hard; budget it as marketing |
| Pro | $20 credits, 100 computer hours, 20 bots, 5 seats | $20 + 100 × $0.166 ≈ **$36.60 a month** | about **$56 a month on iOS** ($36.60 × 1.3 ÷ 0.85), about $51 on the web |

With our own Hetzner servers for computers (about $0.025 an hour each, if kept busy) Pro's 100
hours cost about $2.50, and the break-even price drops to about **$31 a month on the web, $35 on iOS**. **Computers are the
biggest lever:** either run them on our own servers or include far fewer hours per plan.

## Lowering costs (so prices can come down)

Ranked by saving. ✅ = done, ☐ = to do.

1. **Bot computers on our own dense servers** (biggest lever, up to 15× cheaper): a dedicated server
   such as Hetzner AX102 (16 cores, 128 GB, €159 / month) holds about 28 standard computers, because
   bots mostly wait on the model (CPU can be shared; memory is the limit). That is about **$0.01 per
   computer-hour** against $0.17 on E2B or Daytona. Also: headless by default (1–2 GB instead of 4;
   the desktop only when needed), sleep after about 5 minutes idle (sleep and wake already work),
   a small warm pool (built), EU servers (US ones cost about twice as much). ☐ Needs a server.
2. **Models on our keys:**
   - ✅ Anthropic prompt caching: Claude requests ask for caching, so the instructions, tools and
     conversation so far are read back at a tenth of the price next turn. OpenAI, Gemini and xAI
     cache matching prefixes on their own.
   - ✅ Cached and cache-write tokens are recorded and priced (`costOf`): reads at 0.1× input (0.25× on
     Gemini), Anthropic writes at 1.25×.
   - ✅ Background work (conversation summaries, memory) runs on the provider's small model (Claude
     Haiku 5.5, GPT-6 Luna, Gemini 3.5 Flash-Lite) when the bot hasn't picked a cheap model,
     falling back to its main model.
   - ✅ Onboarding already puts the person's own AI first (ChatGPT subscription, own key, local
     model); Casama credits aren't offered there.
   - ☐ Batch APIs (50% off) for work that can wait hours. Routines run at set times, so only for
     truly deferrable jobs.
   - ☐ Call the big providers directly with our keys instead of OpenRouter (saves its 5.5% fee).
3. **Apps:** ☐ connect directly wherever the app allows (free); register our own GitHub, Asana and
   HubSpot apps (free, needs Oliver's sign-in); for the rest, our own app inside Composio ($0.0003 a
   call instead of $0.002, free connections, Casama on the sign-in screen).
4. **Voice and phone:** ✅ Gemini Live is the default voice (about $0.02 a minute against about $0.10
   for OpenAI Realtime). ☐ Compare Telnyx and other carriers with Twilio.
5. **Search:** ☐ our own SearXNG by default, Brave or Tavily as the paid fallback; cache results;
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

1. **Computer time:** charge the real provider rate (vCPU-seconds plus GiB-seconds of RAM for E2B and
   Daytona; a per-hour rate per size for our own servers) instead of the $0.01 per vCPU-hour placeholder.
2. **Model prices:** read OpenRouter's live per-model prices instead of the hand-written table,
   never price an unknown or open-weight model at $0, and add OpenRouter's 5.5% fee.
3. **Meter what isn't metered:** Composio calls and connected accounts, web search, phone numbers
   per month, SMS, Twilio Media Streams, and the voice model inside phone calls.
4. **Per-model media prices** for images and video.
5. **A markup setting** (default 1.3) applied to every metered cost, and plan prices that account for
   store and payment fees.
6. **Caps per plan** for Composio calls, search, storage and computer hours, so one heavy bot can't
   run up the bill.

## Sources (checked 2026-11-11)

E2B e2b.dev/pricing · Daytona daytona.io/pricing · Hetzner hetzner.com/cloud,
hetzner.com/dedicated-rootserver/matrix-ax · OpenAI developers.openai.com/api/docs/pricing ·
Anthropic platform.claude.com/docs/en/about-claude/pricing · Google aistudio.google.com/docs/pricing ·
xAI docs.x.ai/docs/models · OpenRouter openrouter.ai/pricing · Deepgram deepgram.com/pricing ·
ElevenLabs elevenlabs.io/pricing/api · Cartesia cartesia.ai/pricing · Twilio
twilio.com/en-us/voice/pricing/us, twilio.com/en-us/sms/pricing/us, twilio.com/en-us/stun-turn/pricing ·
Brave brave.com/search/api · Tavily tavily.com/pricing · Exa exa.ai/pricing · fal fal.ai/pricing ·
Supabase supabase.com/pricing · Cloudflare developers.cloudflare.com/r2/pricing,
developers.cloudflare.com/workers/platform/pricing, developers.cloudflare.com/realtime/turn ·
Composio composio.dev/pricing/platform and the Casama org's billing page · Resend resend.com/pricing ·
Zoho zoho.com/mail/zohomail-pricing.html · Sentry sentry.io/pricing · PostHog posthog.com/pricing ·
Langfuse langfuse.com/pricing · Dodo Payments dodopayments.com/pricing · Apple
developer.apple.com/app-store/small-business-program · Google Play
support.google.com/googleplay/android-developer/answer/112622 · reCAPTCHA
docs.cloud.google.com/recaptcha/docs/compare-tiers · casama.ai renewal cfdomainpricing.com (unofficial).
