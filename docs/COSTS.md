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
| **Server: Contabo Cloud VPS 6** (6 vCPU / 12 GB / 200 GB, US Central; D-199) | **$11 / month** | Runs everything: API, worker, our own Supabase, search, TURN, and the bot computers. The stack uses about 2.2 GB, leaving about 9 GB for computers (about 6–7 headless at once). Bigger later: a dedicated server such as Hetzner AX102 (€159 / month, 128 GB) |
| Supabase Cloud (only if we don't self-host Postgres) | from $25 / month | Includes 8 GB database, 250 GB egress, 100k monthly active users |
| Composio | $0 now (Hobby), **$29 / month** on Pro | Pro needed at launch for the data processing agreement; usage on top, see below |
| E2B (only if hosted computers run on E2B) | **$150 / month** Pro, plus usage | Hobby has a one-time $100 credit, 1-hour sessions only |
| Sentry Team | $26 / month (annual) | 50k errors; free tier 5k errors |
| PostHog | Shared Stackwares project, already past the free 1M events. Casama adds about $0.02–0.04 per monthly active person; error tracking free to 100k exceptions a month (shared). | Then from $0.00005 per event |
| Langfuse (optional) | $0 up to 50k units, then $29 / month | |
| Email: Zoho Mail | $1–4 per mailbox / month | hello@ sends sign-in email; switch sign-in mail to Resend ($20 / month for 50k) when volume grows |
| Cloudflare (DNS, site, docs, gallery, tunnel) | $0; Workers Paid $5 / month if needed | The gallery (D-184) is static assets: free, no bandwidth charge; R2 at $0.015 per GB-month only if images outgrow the static limits |
| Off-site database backups (R2 bucket `casama-backups`, D-197) | $0 within the 10 GB-month free tier | Then $0.015 per GB-month, no egress fee. Daily age-encrypted dumps, 14 days kept |
| Unsplash API (wallpaper photo search, D-087) | $0 | Free at both Demo (50 requests/hour) and Production rate limits; Unsplash reserves the right to charge for very heavy use |
| Domain casama.ai | about $80 / year | Unverified; check the Cloudflare dashboard |
| Apple Developer Program | $99 / year | |
| Google Play registration | $25 once | |

**Floor before the first paying user: roughly $60–80 a month** (the $11 server, Sentry, Composio
Pro, mailboxes, domain, Apple). Computers run on the same server, so there's no E2B bill.

## Usage costs (scale with what people do)

| What | Our cost | How it's metered today (`usage_ledger.kind`, price in code) | Verdict |
|---|---|---|---|
| **Bot computers** | E2B: 2 vCPU / 4 GiB ≈ **$0.166 / hour**. Daytona: same ≈ **$0.166 / hour**. Own Hetzner servers: CPX42 runs about 4 computers of that size for €65 / month, ≈ **$0.025 / hour each if fully used** | `computer_seconds` at the provider's rate (D-180): E2B and Daytona $0.0504 per vCPU-hour + $0.0162 per GiB-hour; Docker $0.003 per vCPU-hour + $0.005 per GB-hour (1 vCPU / 1 GB ≈ $0.008 / hour); `COMPUTER_RATES` overrides | ✅ Real rates |
| **Models on our keys** (credits) | Per 1M tokens in / out: GPT-6.1 Sol $2 / $10, GPT-6 Luna $0.10 / $0.50, Claude Opus 5.5 $4 / $20, Sonnet 5.5 $2 / $10, Haiku 5.5 $0.10 / $0.50, Gemini 3.1 Pro $2 / $12, Gemini 3.8 Flash $0.75 / $3.75 (**doubles on 2027-01-01**), Grok 4.7 $2 / $6. Through OpenRouter: plus **5.5%** on credit purchases | `tokens_in` / `tokens_out` at OpenRouter's reported `usage.cost` when the response has it, otherwise the live price list (D-181). On Casama's key, with billing on: that cost × 1.055 × 1.3 (D-186) | ✅ Live cost, fee and 1.3 markup on Casama's key |
| **Voice calls, OpenAI Realtime** | Audio $32 in / $64 out per 1M tokens ≈ $0.02 / min listening + $0.08 / min speaking. Mini model: about a third | `voice_seconds`, **$0.06 / min** estimate | ⚠️ Close for a balanced call; long bot monologues cost more. Price from reported token usage, like Gemini |
| **Voice calls, Gemini Live** | $3 in / $12 out per 1M audio tokens ≈ $0.005 + $0.018 per min | `voice_seconds`, priced from the call's own token counts | ✅ |
| **Dictation (speech to text)** | **On the shared OpenRouter key: Whisper Large V3 Turbo $0.0002 / min** (OpenRouter list price 2026-11-11; a 2.8 s test clip cost $0.0000093), charged at cost × 1.055 × 1.3 from OpenRouter's reported cost (D-194). A workspace's own key: OpenAI `gpt-4o-mini-transcribe` $0.003 / min. Gemini 3.5 Transcribe is about $0.005 / min once the transcript is included, so dictation stays on OpenAI (D-187). Deepgram Nova-3 $0.0077 / min | `stt_seconds`, $0.003 / min | ✅ for OpenAI mini; ❌ if Deepgram is used on our key |
| **Read aloud (text to speech)** | Gemini 3.8 Flash-Lite TTS about $0.011 per 1k characters through 2026-12-31 ($6 per 1M audio tokens, 25 tokens a second), then about $0.022. OpenAI `gpt-4o-mini-tts` about $0.018 a minute of speech. ElevenLabs Flash $40 per 1M characters | Gemini at the audio rate above; other providers $0.015 per 1k characters (D-187) | ✅ |
| **Phone calls (Twilio)** | Outbound $0.014 / min, inbound $0.0085 / min, Media Streams +$0.0044 / min, **on the workspace's own Twilio account** (D-141), plus the voice model per minute | `phone_minutes` recorded, not billable (the workspace pays Twilio). The voice model inside the call is `voice_seconds`, billable at Google's price × markup on the server's key (D-244) | ✅ |
| **Phone numbers** | $1.15 / month (local US), $2.15 (toll-free) | The workspace's own Twilio account | ✅ Not ours |
| **SMS** | $0.0083 per segment plus carrier fees ($0.0025–0.007) | The workspace's own Twilio account (SMS channel) | ✅ Not ours |
| **Apps through Composio** (our account) | Free up to 20k calls and 1k connected accounts a month. Then (Pro) **$0.002 per call** (Slack, Gmail, Calendar, Sheets, Jira, HubSpot), $0.01 (Salesforce, YouTube, Reddit), $0.0005 (others); **$0.10 once** per connected account past 1k | `app_calls`, $0.002 per call × markup, billable, paid from credits (D-244) | ✅ Charged even inside the free allowance |
| **Web search** | Brave $5 per 1k searches; Tavily $0.008 per search; Exa $4–7 per 1k; our own SearXNG $0 (runs on the API server) | `search_queries`, priced per provider (D-179) | ✅ Metered. Workspace keys pay their own; without one, SearXNG (free). Cloud never pays per search today |
| **Invite rewards** (D-211) | **$2 of credits to the inviter** (at most 20 friends, $40 per person) **plus a $2 welcome bonus to the friend**, both once the friend verifies and finishes a first chat: up to **$4 per friend**. Credits are spent at marked-up prices (× 1.055 × 1.3 on Casama's key), so each $2 costs about **$1.46** in model spend at most (about **$2.92 per friend**), less if never fully used | `credit_ledger` rows with reason `grant` and references `referral:<friend>` / `referral-welcome:<friend>`; `REFERRAL_REWARD_USD`, `REFERRAL_WELCOME_USD`, `REFERRAL_REWARD_CAP` | ⚠️ A growth cost, not usage. Fake accounts could farm it: each needs a verified address, a sign-up proof and a first run, and the cap limits one person to $40 |
| **Images** | Per image at 1K: Gemini Nano Banana 2.1 $0.034 on OpenRouter (default with an OpenRouter key; LM Arena rank 7, Artificial Analysis rank 6). GPT Image 2.6 medium about $0.043 (LM Arena ranks 2–4); its max tier about $0.21 (ranks 1–4). Seedream 4.5 $0.04 is the fal fallback (rank 38). Budget: fal FLUX.2 klein 4B or Z-Image Turbo $0.005 per megapixel (ranks 72 and 61) | `media_images` at OpenRouter's reported cost or fal's list price per model (D-185); unknown models at $0.04 | ✅ Per model |
| **Video** | Gemini Omni Flash 1.2 at 720p, about $0.07 a second, when a Google AI key exists (D-189). Otherwise fal: PixVerse V6 $0.005, MiniMax H3 Max Turbo $0.025, Grok Imagine $0.05, LTX about $0.04–0.10. Animating a picture (image-to-video) uses the same model with the picture as input: Omni Flash at the same per-second price, fal's `…/image-to-video` endpoint of the same model | `media_video_seconds` at $0.0695 a second for Omni Flash, or fal's list price (an image-to-video endpoint without its own entry is recorded at the $0.10 / second default, so add its fal price when making one a default); unknown models at $0.10 / second | ✅ |
| **Paid data (places, emails, SEO)** | What the data seller charges | `data_calls`, cost + 20% | ✅ (consider +30% to cover payment fees) |
| **Memory embeddings** | OpenAI text-embedding-3-small $0.02 per 1M tokens, also on the shared OpenRouter key when a workspace has no OpenAI key (D-194); about $0.0000006 per memory | Not metered | ✅ Negligible; meter if volume ever matters |
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

## Plans (D-244, live 2026-11)

Plans, packs and the markup live in the database and change from the Admin screen without a deploy.
Credits are spent at cost × markup (1.3; OpenRouter also × 1.055), so each $1 of included credits
costs Casama about **$0.77** at most. Computers run on Docker at about $0.008 an hour.

| Plan | Price | Includes | Our cost if fully used | Margin after fees (web / iOS) |
|---|---|---|---|---|
| Free | $0 | $1 credits, 2 bots, 1 computer, 5 h, 1 seat | about $0.80 a month (plus invite credits) | marketing |
| Plus | **$15** / $150 a year | $5 credits, 5 bots, 2 computers, 30 h, 2 seats | about $4.10 | about 70% / 68% |
| Pro | **$39** / $390 | $10 credits, 20 bots, 5 computers, 100 h, 5 seats | about $8.50 | about 77% / 74% |
| Max | **$149** / $1,490 | $50 credits, 50 bots, 10 computers, 400 h, 10 seats | about $41.70 | about 70% / 67% |
| Credit packs | $10 / $25 web; **$12.99 / $29.99** in the stores | $10 / $25 of credits | $7.70 / $19.25 | about 16% web; 13–30% stores |

Most people won't use everything included, so real margins are higher. The step to watch is server
capacity: the $11 VPS fits 6–7 running computers; past that, a larger server (about €159 a month,
about 28 computers) is the next fixed cost.

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
   - ✅ Anthropic prompt caching: Claude requests ask for caching, so the instructions, tools and
     conversation so far are read back at a tenth of the price next turn. OpenAI, Gemini and xAI
     cache matching prefixes on their own.
   - ✅ Cached and cache-write tokens are recorded and priced (`costOf`): reads at 0.1× input (0.25× on
     Gemini), Anthropic writes at 1.25×.
   - ✅ Background work (conversation summaries, memory) runs on Muse Ember when the bot is on
     OpenRouter, and on the provider's small model otherwise (Claude Haiku 5.5, GPT-6 Luna,
     Gemini 3.5 Flash-Lite), when the bot hasn't picked a cheap model (D-187). It falls back to
     the main model.
   - ✅ Onboarding already puts the person's own AI first (ChatGPT subscription, own key, local
     model); Casama credits aren't offered there.
   - ☐ Batch APIs (50% off) for work that can wait hours. Routines run at set times, so only for
     truly deferrable jobs.
   - ☐ Call the big providers directly with our keys instead of OpenRouter (saves its 5.5% fee).
3. **Apps:** ☐ connect directly wherever the app allows (free); register our own GitHub, Asana and
   HubSpot apps (free, needs Oliver's sign-in); for the rest, our own app inside Composio ($0.0003 a
   call instead of $0.002, free connections, Casama on the sign-in screen).
4. **Voice and phone:** ✅ Gemini Live is the call for in-app and phone calls whenever a Google key
   exists (the workspace's, else the server's). OpenAI Realtime is only the last resort (D-187).
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
