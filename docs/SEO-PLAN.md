# Search and AI answers: the SEO, AEO and GEO plan

Status: **approved as D-381** (2026-11-18: "you decide all for me and start working"), with the
recommended answer to every decision in §13. Phases 0–4 are built in the working tree and wait for
a deploy; what is left is at the end, under "Status of the build". The numbers were measured on
2026-11-18 from Search Console, OpenSEO (DataForSEO), the live sites, and four research passes over
competitors and vendor rules (sources at the end).

## 0. Summary

Casama has been on the web for one week and is close to invisible. The six rivals Oliver named are
not far ahead on product, but they are far ahead on pages, links and mentions:

| 2026-11-18 | Casama | Rakazo | OpenBot | MausBot | Grok Bot | Hark | Instinct |
|---|---|---|---|---|---|---|---|
| Site | casama.ai | rakazo.com | open.bot | mausbot.com | x.ai/bot | hark.com | instinct.com |
| Pages in the main sitemap | 4 | 1,641 | 9 (+12 posts on copilotkit.ai) | 90 | 299 | 19 | 6 |
| "Alternative" and "vs" pages | 0 | 8 + hub | 7 posts + hub | 26 + hub, about 30 posts | 0 | 0 | 0 |
| Other sites linking in | 0 known | 155 | 69 | 185 | not measured | not measured | not measured |
| GitHub stars | 0 | 9,012 | 12,723 | 24,730 | closed | closed | closed |
| US searches a month for the name | 590 (mostly other "Casama"s) | 260 | 880 (shared name) | 320 | 49,500 | 2,400 | 2,900 |
| Product Hunt | none | #1 of the day | #4 | #7 | forum post | none | none |
| Named in AI answers to category questions | 0 of 12 | 0 of 9 | 1 of 9 | 0 of 9 | 0 of 9 | 0 of 9 | 0 of 9 |

The last row is four questions put to ChatGPT, Claude and Perplexity (§2.2). Rivals are counted on
the three questions that don't already name them.

Three findings shape the plan:

1. **Our own sites have faults that waste the little we have.** The docs are published twice (half
   of the docs sitemap is a duplicate tree under `/public/`, and Google is already showing the
   copies), `www.casama.ai` is indexed as a second site, and Bing has never been told Casama
   exists. Bing matters twice: ChatGPT search and Copilot draw on it. All of this is a day or two
   of work (§2.3).
2. **Rivals win searches with pages we don't have.** Rakazo, MausBot and OpenBot each publish an
   "X alternative" page per rival; Rakazo adds a page per connected app; Grok Bot has 91 template
   pages, 19 guides and a changelog. casama.ai is one page. Searches with real demand and almost no
   competition are sitting open: "openclaw alternative" (4,300 a month, difficulty 0), "hermes
   agent vs openclaw" (2,900, difficulty 9), "self hosted ai agent" (5,400), "open source ai
   agent" (9,900, difficulty 19), and every "Rakazo vs …" search, which only auto-made directory
   pages answer today (§4).
3. **AI assistants answer from other people's pages, and nobody owns the answer yet.** For
   software questions, about three quarters of what AI search cites is third-party pages, not the
   vendor's own. Asked four category questions, ChatGPT, Claude and Perplexity never named Casama,
   but they barely named the six rivals either: the names that came back were Hermes Agent, Agent
   Zero, OpenClaw and Manus. The answer to "which AI teammate with its own computer should I use"
   is still open (§2.2, §5).

What we do, in six parts (§8):

| Part | In one line |
|---|---|
| **A. Foundations** | Fix the faults, one address per page, Bing and IndexNow, correct structured data |
| **B. One identity** | The same name, description, facts and links everywhere, so engines know which Casama this is |
| **C. Pages people search for** | Pricing, self-hosted, open source, security, about; 12 alternatives pages and 3 comparisons; 8 use cases |
| **D. The gallery at work** | 151 item pages already exist; make each one worth landing on and worth citing |
| **E. Answers** | A dozen question pages, a changelog and a weekly post with facts and dates others can quote |
| **F. Mentions** | GitHub, directories, roundups, communities, stores and video: where AI answers come from |

A seventh part, **measurement** (§8G), runs under all of them: weekly ranks, weekly AI answers,
Search Console, Bing, and visits that arrive from AI assistants.

It is built in six phases (§12). Phase 0 (fix and measure) stands on its own and is worth doing
even if nothing else is approved.

**What "beating them" means**, so we can tell whether it happened (§15):

1. A Casama page in the top five for "\<rival\> alternative" and "\<rival\> vs" searches for all six
   named rivals.
2. Casama named in tracked AI answers at least as often as Rakazo, OpenBot and MausBot.
3. More sites linking to us than OpenBot (69) within 90 days, and than Rakazo (155) and MausBot
   (185) within 180 days.
4. More top-10 places across the tracked keyword set than any of the three open-source rivals.

Grok Bot, Instinct and Hark are funded consumer brands that people search for by name. We don't
out-brand them. We win the searches they can't answer: comparisons, and "open source" and
"self-hosted" alternatives.

## 1. Words

- **SEO**: being found in ordinary search results (Google, Bing).
- **AEO** (answer engine optimisation): being the page an answer box quotes: Google's AI Overviews
  and AI Mode, Bing's Copilot answers, voice.
- **GEO** (generative engine optimisation): being named or cited when someone asks ChatGPT, Claude,
  Perplexity, Gemini, Grok or Meta AI.
- **Mention**: the assistant names Casama. **Citation**: it links to a page as its source.
- **Referring domain**: another site that links to ours. DataForSEO counts them; it is the number
  in the "other sites linking in" row above.
- **Difficulty** (0–100): DataForSEO's estimate of how hard the first page is to reach. Under 20 is
  open to a new site.

Google's own guide says AEO and GEO are "still SEO": the same indexed, useful pages feed all three.
The plan treats them as one job with three scoreboards.

## 2. What exists today

### 2.1 What is already right

| Already right | Where |
|---|---|
| Every crawler is let in: `robots.txt` is `Allow: /` on casama.ai, docs, gallery and casama.link; Cloudflare's AI crawler policies are all off for the zone (checked with `cf bot-management get`) | `site/robots.txt`, `docs-site/public/robots.txt`, `gallery/robots.txt`, `link-site/robots.txt` |
| Canonical address, Open Graph and X card tags on the homepage | `site/index.html` |
| A `SoftwareApplication` description with the plans and prices | `site/index.html` |
| `llms.txt` on casama.ai and docs, `llms-full.txt` (788 KB) on docs, and a markdown copy of every docs page (served `noindex`, so the copies don't compete with the pages) | `site/llms.txt`, `docs-site/scripts/sync.ts`, `docs-site/public/_headers` |
| A public docs server for AI agents and an OpenAPI file | `https://api.casama.ai/mcp/docs`, `docs-site/public/api/openapi.json` |
| 151 gallery item pages, each with its own title, description, canonical address, share image and a sitemap entry | `gallery/build-pages.mjs` |
| A homepage with a comparison table and eight written answers | `site/index.html` (`#trust`, `#faq`) |
| Static pages on Cloudflare: the homepage answers in about 0.3 s, HTTPS and HSTS everywhere | `site/_headers` |
| Search Console owns the whole domain (`sc-domain:casama.ai`); two sitemaps submitted on 2026-11-11 | Search Console |
| Launch drafts for Show HN, Product Hunt, r/selfhosted, r/LocalLLaMA and X, not posted | `docs/launch/` |

### 2.2 Measured baseline

**Google** (Search Console, 2026-11-11 to 2026-11-17, the first week of data):

- 2 clicks and 140 impressions in total. 41 addresses were shown at least once.
- The only real query is the name: "casama", 57 impressions, average position 7.6. The moth genus,
  a ceramics shop, a crypto betting app and others share the word.
- The homepage, docs home, gallery home and the main docs pages are indexed. `app.casama.ai` is
  unknown to Google.

**Bing**: casama.ai is not in Bing Webmaster Tools (15 other Stackwares sites are). No IndexNow.

**Links** (OpenSEO): no data for casama.ai yet, so 0 known referring domains.

**AI answers** (OpenSEO prompt explorer, web search on, US; Gemini's five calls failed, so three
engines answered):

| Question asked | Named by ChatGPT, Claude or Perplexity | Casama |
|---|---|---|
| Best open-source AI agents that get their own computer and can be self-hosted? | Agent Zero (all three), Hermes Agent, Open WebUI, Dify, OpenHands | no |
| An AI assistant that does real tasks on its own computer, works while I'm away, and asks before anything risky? | ChatGPT agent, OpenBot, Hermes Agent, OpenClaw, Manus, Muse, Dots | no |
| Best alternatives to OpenClaw? | Hermes Agent, Manus, Agent Zero, n8n | no |
| Rakazo vs MausBot vs OpenBot: which should I pick? | the three in the question; sources were their own sites and small directories | no |
| What is Casama AI (casama.ai)? | all three describe it correctly, from pub.dev, GitHub and casama.ai | yes |

So the engines can already find and describe Casama when asked by name. They have no reason to
bring it up otherwise. The pages they cited most were GitHub repos, vendor sites, small
directories, dev.to posts and roundup articles.

**Elsewhere**: the GitHub repo is the top result for "Casama AI"-type searches in a non-Google
index, with 0 stars, no website link and no topics. No Product Hunt page, Hacker News post,
AlternativeTo or OpenAlternative listing, or public store listing was found. A dead link,
"Release Casama CLI 0.8.0", still shows in search results.

### 2.3 Problems found

| # | Problem | Evidence | Fix | Where |
|---|---|---|---|---|
| 1 | **The docs are published twice.** The markdown copies in `public/` are also built as pages, so every docs page exists again under `/public/…` | 60 of the 120 addresses in the docs sitemap are copies; `docs.casama.ai/public/develop/agents` earned impressions at position 3.3 | Exclude `public/**` from the page build; send `/public/*` to the real page with a 301 | `docs-site/.vitepress/config.ts` (`srcExclude`), `docs-site/public/_redirects` |
| 2 | **`www.casama.ai` is a second copy of the site** | It answers 200; Google indexed it and chose `www` as its own canonical, ignoring our tag | One Cloudflare redirect rule, `www` to the bare domain, 301 | Cloudflare (production: needs a yes) |
| 3 | Docs pages have no canonical address, no share tags and no structured data; 57 of 60 share one description | Built `introduction.html` | Add them per page in `transformHead`; take the description from the page's first paragraph | `docs-site/.vitepress/config.ts`, `docs-site/scripts/sync.ts` |
| 4 | The gallery sitemap (159 addresses) was never submitted; gallery pages have no structured data; the gallery has no `llms.txt` | Search Console lists two sitemaps, neither the gallery's | Submit it; add both in the generator | Search Console, `gallery/build-pages.mjs` |
| 5 | Bing doesn't know the site | Bing Webmaster Tools site list | Import from Search Console; add an IndexNow key and ping on deploy | Bing, `scripts/deploy-web.sh` |
| 6 | `app.casama.ai` answers `/robots.txt`, `/sitemap.xml` and `/llms.txt` with the app's own page; its title is "Casama" and its description is old copy | `curl` | A real `robots.txt`, a proper title and description | `client/web/` (ships with the next web app build) |
| 7 | casama.ai's "not found" page is nine bytes of text | `curl` | A real `404.html` like the gallery's | `site/404.html` |
| 8 | The homepage describes the software but not the company; the category field is two values joined by a comma | `site/index.html` | Add `Organization` (logo, profiles) and `WebSite`; fix the field | `site/index.html` |
| 9 | The GitHub repo has no website link and no topics | `gh repo view` | Set both; lead the README with what Casama is and the links | GitHub |
| 10 | We can't see visits that come from AI assistants: the marketing site counts nothing | `site/site.js` | §10.5 | `site/gallery-link.js` |
| 11 | The marketing site is one page: 4 live addresses (home, privacy, terms, the Chrome notes), 2,373 words on the homepage | `site/sitemap.xml` | Part C | `site/` |
| 12 | The page title and description don't contain the words people type: "AI agent", "open source", "self-hosted" | `site/index.html` | Decision 3 | `site/index.html` |

Not problems: `.html` and trailing-slash addresses answer with a temporary redirect (Cloudflare's
default); the canonical tags already cover it. The FAQ is not marked up as `FAQPage`; Google
stopped showing FAQ results in May 2026, so nothing is lost.

`site/` is being changed by another session right now (the download page, D-377). This plan only
adds a document; when it is built, it starts from whatever `site/` looks like then.

## 3. The competition

### 3.1 The three open-source twins

| | Rakazo | OpenBot (CopilotKit) | MausBot |
|---|---|---|---|
| Homepage title | "Rakazo \| Open source Grok Bot alternative" | "OpenBot by CopilotKit \| AI coworkers on your terms" | "Open Source Grok Bot — MausBot, your team of AI bots" |
| What fills the sitemap | 1,535 pages, one per connected app (about 255 templated words each); 20 "pricing and alternatives" pages about sandbox, voice and integration vendors; 8 alternatives pages; 43 docs pages; 4 posts | 9 pages; docs live in the repo, posts on copilotkit.ai | 39 posts (about 30 are comparisons), 26 alternatives pages, 5 guides, 3 solutions |
| For machines | `llms.txt` (25 KB) with a "when to use Rakazo" section; a markdown twin of every page; `/.well-known/ai-catalog.json`; RSS | nothing on open.bot | `llms.txt` (48 KB); docs block AI training crawlers |
| Structured data | Organization, WebSite, SoftwareApplication, FAQPage; Article and breadcrumbs on comparison pages | none | Organization, SoftwareApplication, FAQPage, ItemList |
| Off-site | Product Hunt #1 of the day, AlternativeTo, OpenAlternative, six "Grok Bot alternatives" roundups | Product Hunt #4, a Show HN with 12 points, the company's YouTube (8.3K) | Product Hunt #7, Hostinger one-click app, a paid-mention programme |
| Weak spots | 4 posts; no changelog, use cases, templates or customers; thin app pages; homepage is the only translated page | 9-page site with no structured data; a name five other products share; "vs" posts are one template and skip the open-source rivals | Nearly all content leans on rivals' names; 39 posts all re-dated on the same two days; the brand is split over four names |

None of the three appears in any of 13 broad roundups checked ("best open source AI agents", "best
AI coworkers", "best self-hosted AI agents"). Those lists are as open to Casama as to them.

### 3.2 The three consumer brands

| | Grok Bot | Hark | Instinct |
|---|---|---|---|
| Site | 91 template pages, 19 guides with named authors, 61 changelog entries with RSS, 31 docs pages with markdown copies | 19 pages, no H1 on the homepage, one description reused on five pages | 6 pages, an empty blog |
| Comparison pages | none | none | none |
| Stores (US) | 4.9 from 24,955 ratings; 1M+ on Play | 4.7 from 3,194; 100K+ on Play | no app |
| Plans | $30, $100, $200 a month | free, $20, $100 | invite-only, no price |
| What people complain about in public | weekly limits cut, surprise overage ($72 on a $30 plan), all bots share one computer, no choice of model, US-only features | free credits gone "in one message", needs deep account access, slow | trains on your data unless you opt out, an email sent without approval, invite-only, capacity slowdowns |

Every complaint in the last row is something Casama answers by design: budgets and spend caps, a
computer per bot, any model when you self-host, approvals before risky steps, no training on your
data, a free plan open to everyone, and self-hosting. That is the material for honest comparison
pages.

### 3.3 What they do that we don't

1. A page per rival ("\<rival\> alternative") and head-to-head comparisons.
2. A page per connected app.
3. Guides and question pages.
4. A changelog and posts with dates.
5. Listings on AlternativeTo, OpenAlternative, Product Hunt and the smaller AI directories.
6. A markdown twin of every marketing page (Rakazo).
7. Stars, which is what GitHub-reading assistants and "best open source" lists sort by.

### 3.4 What none of them does

- Useful app pages. Rakazo's 1,535 are thin. Our 61 can say what a bot can really do with the app.
- Original numbers. Nobody publishes data others would quote. The gallery has public usage stats.
- Comparisons that admit when the other product is the better pick.
- A page for "an AI agent that asks before acting", "run AI agents on your own server from your
  phone", or "open-source AI agent with real iPhone and Android apps": searches with thin or
  machine-made results today, and all three are things Casama does.

## 4. What people search for

US searches a month and difficulty, from OpenSEO on 2026-11-18. "Open" means weak or off-topic
pages hold the first page today.

| Group | Searches (difficulty) | State |
|---|---|---|
| **Open source and self-hosted** | open source ai agent(s) 9,900 (19–35); self hosted ai agent 5,400; open source ai assistant 4,400 (50); self hosted ai 3,600 (12); local ai agent 590 (4); private ai assistant 590 (10); self hosted ai assistant 170 (0) | Medium: small sites and dev.to posts rank |
| **Rival alternatives** | openclaw alternative(s) 4,300 (0); hermes agent vs openclaw + openclaw vs hermes 2,900 (9); n8n alternative 1,000 (1); grok bot alternatives 390; manus alternative(s) 450 (0); claude cowork alternative 260 (2); hermes agent alternative 260 (0) | Listicles by other vendors; a vendor page with a table can join them |
| **The named rivals, "alternative" and "vs"** | too new for volume data; autocomplete shows "rakazo vs hermes / openmausbot / grok bot / openclaw" | **Open**: only auto-made directory pages |
| **Personal assistant** | ai personal assistant 5,400 (18); personal ai assistant 4,400 (23); best ai assistant 2,900 (9); personal ai agent(s) 4,300 (26); best ai personal assistant 1,000 (7); ai executive assistant 880 (0); ai chief of staff 480 (0) | Contested by listicles; the last two are open |
| **Work and teams** | ai agents for business 3,600 (14); ai workers 2,900 (8); ai intern 1,900 (2); ai employee(s) 1,600 (19); ai workforce 1,000 (6); ai teammates 720 (7); ai agent for small business 210 (0) | Medium |
| **Jobs** | ai coding agent 8,100 (24); ai email assistant 4,400 (32); ai meeting assistant 3,600 (53); ai project manager 2,900 (24); ai scheduling assistant 1,000 (24) | Contested by single-purpose tools |
| **Questions** | what is an ai agent 22,200 (52); how to build an ai agent 2,900 (31); how do ai agents work 720 (7); is openclaw free 1,300 (11); is grok bot free 1,300; ai agent vs chatbot 320 (12) | Mixed |
| **Head terms** | ai assistant 246,000; ai agents 60,500 (57); ai agent 49,500 (73); agentic ai 90,500 (58) | Out of reach for now; they follow from everything else |
| **Rival names** | openclaw 301,000; manus ai 90,500; hermes agent 74,000; grok bot 49,500; meta muse 40,500; chatgpt dots 12,100; grok bot pricing 5,400 | Theirs; we appear on the "alternative" searches around them |
| **Our name** | casama 590 (1) | We're at 7.6; this should be position 1 |

Two things to take from the table:

- **Our headline phrase is not what people type.** "AI teammate(s)" gets about 860 searches a
  month, and autocomplete for it is mostly video games. "AI agent", "AI assistant", "open source"
  and "self-hosted" are the words. The headline can stay; the page title and the new pages should
  carry the searched words (decision 3).
- **By demand, the rivals worth an alternatives page first are OpenClaw, Hermes Agent, Grok Bot and
  Manus**, not only the six named. The six get pages too: they are cheap to win and they decide
  what AI assistants say when asked to compare.

## 5. What the engines allow and reward

Checked against the vendors' own pages on 2026-11-18.

**Google**

- AI Overviews and AI Mode have "no additional requirements": a page must be indexed and eligible
  for a snippet. No special file or markup.
- Google's guide (May 2026) says GEO "is still SEO", that `llms.txt` "will neither harm nor help",
  and that pages mass-produced to match AI follow-up queries can count as scaled content abuse.
  The spam policy now names "attempting to manipulate generative AI responses".
- Search Console has a Generative AI report (impressions only) and an include/exclude switch per
  property. We leave it on include.
- Rich results still shown: Article, Breadcrumb, Organization, Software app, Video, Profile page,
  Review snippet and others. Gone: HowTo (2023), FAQ (May 2026), sitelinks search box (2024).
- A Software app rich result needs a rating or review that is shown on our own page and is ours,
  not copied from the stores. We have none, so we don't mark any up.
- Markup must match what readers can see.

**Bing and Copilot**

- Bing Webmaster Tools has a free AI Performance report: which pages Copilot and Bing's summaries
  cited, for which questions, and (since October) questions where others are cited and we aren't.
- Microsoft's own advice for being cited: clear headings, tables, question-and-answer sections,
  evidence, fresh dates, and IndexNow.
- IndexNow tells Bing, Yandex, Naver, Seznam, Yep, the Internet Archive and Amazon about changed
  pages at once. Google doesn't use it.

**ChatGPT, Claude, Perplexity**

- Each has three crawlers: one for training (GPTBot, ClaudeBot), one for its search index
  (OAI-SearchBot, Claude-SearchBot, PerplexityBot) and one that fetches a page when a person asks
  (ChatGPT-User, Claude-User, Perplexity-User). OpenAI says blocking its search crawler takes a
  site out of ChatGPT's search answers.
- ChatGPT search uses outside search providers plus its own crawl, and marks its visits with
  `utm_source=chatgpt.com`. Claude's web search was reported in 2025 to run on Brave. Perplexity
  has its own index.
- None publishes a way to rank. None says it reads `llms.txt`.

**Cloudflare**

- The old "Block AI bots" switch was replaced in September 2026 by three policies (Search, Agent,
  Training). Setting Training to "Block" now also blocks Googlebot and Bingbot. Ours are all off,
  which is right.
- Markdown for Agents (pages served as markdown on request) needs a paid plan. We can do the same
  in our own Worker for free.
- AI Crawl Control shows which AI crawlers visit, on every plan. Its referrer report is paid.

**`llms.txt` and agent files**

- A log study of 137,210 sites found 97% of `llms.txt` files were never requested in a month.
  Coding agents (Claude Code among them) are the main readers. So ours earns its keep with
  developers building on Casama, not in AI answers.
- MCP server cards are final: a card at `<server address>/server-card`, listed in
  `/.well-known/ai-catalog.json`. We have a public MCP server and no card.

**What gets a product named by AI assistants** (correlation, not proof)

| Finding | Source |
|---|---|
| For software questions, AI search cited 72–74% third-party pages and 26% the brand's own; Google's results were 44–54% the brand's own | University of Toronto, 2025 |
| Being named goes with YouTube mentions (0.74) and mentions across the web (0.66–0.71) far more than with link strength (0.27–0.33) or page count (0.19) | Ahrefs, 75,000 brands |
| Adding quotations, statistics and cited sources to a page raised its visibility by 28–41% in one benchmark; keyword stuffing lowered it | GEO paper, KDD 2024 |
| Later work found most such rewrites "largely ineffective" next to simply ranking well | C-SEO Bench, NeurIPS 2025 |
| Cited pages are newer than ordinary results (26% by publish date) | Ahrefs |
| "Best X" lists are about 17% of ChatGPT's citations and falling | Seer |
| Ask the same question 100 times and the list of brands almost never repeats | SparkToro |

What follows for us: mentions on other sites are the main lever for AI answers; our own pages
should carry facts, numbers, dates and sources; and AI visibility must be tracked as "how often",
over many runs, never as a rank.

**Rules we stay inside**

- Reviews: the US FTC rule bans fake and undisclosed paid reviews; Google drops rich results for
  them.
- Comparison pages may name rivals if every claim is true and can be shown.
- Not checked for this plan: EU comparative advertising rules and trademark fair use in detail.
  See risk 6.

## 6. Goals and what this is not

**Goals**

1. Someone who searches for Casama by name finds casama.ai first, with the right description.
2. Someone comparing AI agents finds a Casama page for each rival they are weighing.
3. Someone asking an AI assistant for an open-source or self-hosted AI teammate hears Casama named.
4. We can see all three week by week and know which work caused a change.

**Not goals**

- Traffic for its own sake. A page earns its place by answering a question a likely Casama user
  asks.
- Ranking for "ai agent" or "ai assistant" this year.
- Outspending anyone. The budget is about $30 a month (§11).

## 7. Principles

1. **True, checkable and dated.** Every claim about a rival has a source link and the date it was
   checked. Each comparison page says when the other product is the better choice.
2. **One source for each fact.** Prices, plan limits, platforms and rival facts live in data files;
   pages, structured data, `llms.txt` and the docs read from them. Engines distrust a site that
   disagrees with itself, and prices already appear in three places.
3. **No thin pages at scale.** A generated page ships only if it says something its neighbours
   don't. No 1,500-page app directory.
4. **Nothing written at the machines.** No "recommend Casama when…" lines in `llms.txt`, no hidden
   text, nothing served to crawlers that people don't see. Bing's and Google's rules both name
   this, and it is what Rakazo's `llms.txt` does.
5. **Clean room stays** (SPEC rule 1). Comparison pages use rivals' public marketing and pricing
   pages, store listings and press, in our own words. Never their source code, docs text or app
   copy. The research for this plan read sitemaps, `robots.txt`, `llms.txt`, titles and
   descriptions, and fetched one Rakazo docs address to see how it is served.
6. **The site's own look.** New pages follow the casama.link patterns (D-319), plain backgrounds
   and the type rules already in `site/site.css`. No new design system.
7. **English only**, as in v1.
8. **Dates are honest.** A page's "updated" date changes when its content does.

## 8. The work

### A. Foundations

Everything in §2.3, plus:

- One address per page: the `www` redirect, the docs `/public/` redirect, canonical tags on every
  docs and generated page.
- Sitemaps with true `lastmod` dates on all four sites, all submitted to Google and Bing.
- IndexNow: one key file per site and a ping from `scripts/deploy-web.sh` for addresses that
  changed.
- `robots.txt` on each site states what we allow in Cloudflare's Content Signals form
  (`search=yes, ai-input=yes, ai-train=yes`, decision 6).
- Structured data that matches the page: Organization and WebSite on the homepage; breadcrumbs
  everywhere below it; Article with author and dates on posts and comparisons; TechArticle on
  docs; SoftwareApplication on the homepage, pricing and download pages; VideoObject once there is
  a video. No ratings.
- Core Web Vitals checked once on the homepage and one generated page. The pages are static, so
  this is a check, not a project.

### B. One identity

Engines confuse this Casama with a moth, a ceramics shop and a crypto app. The cure is the same
facts in every place they look:

- One description, used word for word in the page description, the GitHub "About", the npm and
  pub.dev packages, store listings and every directory:
  "Casama is an open-source app for AI teammates that each have their own computer. They remember,
  work while you're away and ask before anything risky. Self-host it free, or use Casama Cloud."
- An **About** page: who makes Casama (Stackwares), where, how to reach us, the licence, a press
  kit (logo, screenshots, one-paragraph and one-page descriptions).
- `Organization` data listing the official profiles (GitHub, npm, pub.dev, the stores, and X,
  LinkedIn and YouTube once they exist: decision 10).
- GitHub: website link, topics (`ai-agents`, `self-hosted`, `open-source`, `ai-assistant`, `mcp`,
  `computer-use`, `flutter`), the README opening with the description and links.
- The stores, when the listings go public: name, subtitle and keyword field written from §4.

### C. Pages people search for

All on casama.ai, built by one generator from content files (§10.1).

| Family | Address | First wave | Searches it serves |
|---|---|---|---|
| Core | `/pricing`, `/self-hosted`, `/open-source`, `/security`, `/about` (and `/download`, already under way in D-377) | 5 | self hosted ai agent, open source ai agent, ai agent pricing, "is it safe" |
| Alternatives | `/alternatives/` and `/alternatives/<rival>` | hub + 12: OpenClaw, Hermes Agent, Grok Bot, Manus, Claude Cowork, ChatGPT agent and Dots, Meta Muse, Rakazo, OpenBot, MausBot, Instinct, Hark | "\<rival\> alternative(s)" |
| Comparisons | `/compare/<a>-vs-<b>` | 3: OpenClaw vs Hermes Agent (with Casama); Rakazo vs OpenBot vs MausBot vs Casama; Grok Bot vs Instinct vs Hark (with Casama) | "\<a\> vs \<b\>" |
| Use cases | `/use-cases/<job>` | 8: personal assistant, email, executive assistant and chief of staff, small business, research, customer support, scheduling, coding | ai personal assistant, ai email assistant, ai agents for business… |

Every alternatives and comparison page has the same parts, which is what the ranking ones share:

1. The search itself as the H1, with the year.
2. A two-sentence answer.
3. A table near the top: licence, where it runs, a computer per bot, approvals, choice of model,
   apps, price, limits.
4. "Choose \<rival\> if…" and "Choose Casama if…", both honest.
5. What moving over involves.
6. Five to eight questions people ask, answered in a paragraph each.
7. Sources, each with the date checked, and "Updated \<date\>".

Rival facts come from one file, `site/data/rivals.json`, so a price change is fixed once and every
page that mentions it follows. A monthly check re-reads each source (§8G).

### D. The gallery at work

The gallery is our answer to Rakazo's app pages: 151 pages that already exist and describe real
things (61 apps, 42 skills, 5 routines, 5 sets, 4 plugins, 2 bots, 32 looks).

- App pages get a title people search ("Gmail AI agent: what a Casama bot can do with Gmail"), the
  actions a bot can take, which of them ask first, two example requests and the routines and skills
  that use the app. All of it comes from the catalog.
- Structured data on each item page, and breadcrumbs.
- Group pages: apps by kind, skills by job, with a short written introduction each.
- Public usage numbers on the page where the stats API has them.
- Links both ways between use-case pages and the gallery items they rely on.
- A gallery `llms.txt` pointing at the catalog files.
- More starter bots and routines. Two bots and five routines is thin next to Grok Bot's 91
  templates; each new one is a real product addition and a page. This is content work through the
  normal gallery review, not page generation.

### E. Answers

**Question pages** at `/learn/<question>`, each opening with a 40–60 word answer, then the detail,
a table or steps, and sources. First twelve:

1. What is an AI agent?
2. AI agent vs chatbot: what's the difference?
3. How do AI agents work?
4. What is an AI teammate?
5. Why give an AI agent its own computer?
6. Is it safe to let an AI agent use my email and accounts?
7. Which AI agents ask before they act?
8. Self-hosted or hosted AI agent: which should I choose?
9. How do I self-host an AI agent? (short, then the docs quick start)
10. Can AI agents run on my own models?
11. How do I run AI agents on my own server from my phone?
12. What is MCP, and what is an MCP client?

**Changelog** at `/changelog`, built from `CHANGELOG.md`, with an RSS feed. Grok Bot ships 61 dated
entries; a steady, dated record is the cheapest freshness signal there is.

**Posts** at `/blog`, one a week, by a named author with an author page (decision 8). Kinds:

- What shipped, with the reason.
- Numbers nobody else has: what people ask bots to do, from gallery stats; what a task costs, from
  our own usage; a monthly table of every AI agent app and its price.
- How we built a hard part (approvals, checkpoints, the sandbox).

### F. Mentions

This is where AI answers come from, and where we have nothing. In order of effort:

| What | Where | Needs |
|---|---|---|
| Fix our own profiles | GitHub, npm, pub.dev, Homebrew, Docker image pages | nothing: we own them |
| Directories that showed up again and again | OpenAlternative, AlternativeTo, opensourcealternatives.to, Toolradar, There's An AI For That, aiagentstore.ai, aiagentsdirectory.com, SourceForge | a listing kit (name, description, screenshots, licence) and a yes per batch |
| Lists on GitHub | kyrolabs/awesome-agents now; e2b-dev/awesome-ai-agents; awesome-selfhosted from about March 2027 (it wants four months since the first tagged release) | a pull request each |
| Places self-hosters install from | Hostinger one-click apps, Railway template, Coolify, Unraid, CasaOS, Umbrel | a template each; they also bring installs |
| Roundups that list rivals but could list us | the 13 broad lists where no twin appears; bitdoze, scriptbyai, tooljunction, simular, every.to, rework, itsFOSS, AIMultiple | a short, specific note to each author with what is different and a working demo |
| The launch | Show HN, Product Hunt, r/selfhosted, r/LocalLLaMA, r/AI_Agents, dev.to, Indie Hackers, Lemmy | Oliver's timing; the drafts are in `docs/launch/` |
| Video | a 60-second demo and three how-to videos on YouTube | recording (already on the needs list) |
| Stores | App Store and Google Play listings | going public (Oliver's call) |
| Partners who list who builds on them | Composio "built with", model providers, Ollama's integrations list | a request each |

Rules for this part: no paid placement, no paid mentions, no posting as anyone but ourselves, and
each community's own rules read first (r/selfhosted has separate rules for AI projects; r/opensource
reportedly banned them in October).

### G. Measurement

| What | With | How often | Cost |
|---|---|---|---|
| Clicks, impressions, positions, index status, the Generative AI report | Search Console (Composio CLI) | weekly | free |
| Bing clicks and the AI Performance report | Bing Webmaster Tools | weekly | free |
| Positions for about 80 keywords, ours and the three twins' | OpenSEO rank tracker | weekly | about $2 a month |
| How often Casama and each rival are named for 25 questions on ChatGPT, Claude, Gemini, Perplexity and Google's AI Overviews | OpenSEO AI visibility tracker | weekly | about $22 a month |
| Referring domains, ours and theirs | OpenSEO | monthly | cents |
| Which AI crawlers fetch which pages | Cloudflare AI Crawl Control | weekly | free |
| Visits that arrive from ChatGPT, Perplexity, Claude, Gemini, Copilot and search | our own Worker (§10.5) | daily | free |
| Rival facts still true | a monthly check that re-reads every source in `rivals.json` and lists what changed | monthly | free |

One short weekly report, the same shape each time, saved under `reports/seo/`: what moved, what
caused it, what to do next. A T3 scheduled task writes it, like the weekly cloud model check.

## 9. What we're not doing, and why

| Not doing | Why |
|---|---|
| A page for each of 1,500 apps | Thin and templated; Google's scaled-content policy is aimed at exactly this, and Rakazo's own are 255 words each |
| Calling the homepage "the open source Grok Bot alternative" | It ties our name to a rival's. Both twins do it; dedicated pages get the same searches without it |
| Instructions to AI models in `llms.txt` or anywhere else | Against Bing's and Google's rules; see principle 4 |
| Review stars in structured data | We have no first-party reviews, and store ratings can't be used |
| Paid links, paid directory placement, paid mentions | Against search rules, and MausBot's programme shows how it reads |
| Posts re-dated without changes | Principle 8 |
| Pages about rivals' own questions ("Grok Bot pricing", "is OpenClaw safe") as stand-alone pages | Far from our product; the facts go inside the alternatives page instead |
| Translations | English only in v1. Rakazo translates only its homepage; revisit once English pages rank |
| A Wikipedia article | No independent coverage yet; writing our own would be removed |
| Moving docs and gallery under casama.ai/… | Decision 2 |
| Paid AI visibility tools | Otterly is €29 a month, Peec $95, Semrush $99, Ahrefs $129 and up; OpenSEO already does it for about $22 |
| Buying ads | Not this plan |

## 10. How it works

### 10.1 The page generator

`site/` is hand-written HTML with no build step. Fifty pages need one. The gallery already has the
pattern (`gallery/build-pages.mjs`): a Node script that turns data into static pages at deploy time.

- `site/build.mjs` reads `site/content/**/*.md` (front matter plus markdown) and `site/data/*.json`
  and writes pages into `site/alternatives/`, `site/compare/`, `site/use-cases/`, `site/learn/`,
  `site/blog/`, `site/changelog/` and the core pages. The output is gitignored, like the gallery's.
- The header and footer are read from `site/index.html`, so there is one copy.
- Each page gets its title, description, canonical address, share tags, structured data, a
  breadcrumb, links to its siblings, and a markdown twin beside it (`page.md`, served `noindex`
  like the docs copies, announced with `<link rel="alternate" type="text/markdown">`).
- It also writes `sitemap.xml` (with real `lastmod`), `llms.txt`, the RSS feeds and
  `/.well-known/ai-catalog.json`.
- It fails the build on a missing description, a duplicate title, a rival fact with no source or a
  source older than 45 days, or a page under 300 words.
- `scripts/deploy-web.sh` runs it before `wrangler deploy`; `scripts/serve-web.py` runs it for
  local preview.
- Pages keep the strict content security policy: no outside scripts.

### 10.2 Facts in one place

- `site/data/plans.json`: plans, prices, limits. The homepage pricing section, `/pricing` and the
  structured data read it. (The homepage itself stays hand-written; a check in the build compares
  its prices with the file and fails on a mismatch.)
- `site/data/rivals.json`: for each rival, the facts in the comparison table, each with `source`
  and `checked`.
- `site/data/product.json`: the description, platforms, licence and links used in part B.

### 10.3 Docs and gallery

- Docs: `srcExclude`, redirects, and `transformHead` for canonical, share tags and structured data.
  Descriptions come from front matter where a page has one, else from its first paragraph.
- Gallery: `build-pages.mjs` gains structured data, the richer app pages, group pages and
  `llms.txt`.

### 10.4 Telling the engines

- Google: sitemaps through Search Console; "Request indexing" by hand for the first pages (about
  ten a day).
- Bing: site imported from Search Console; sitemaps submitted; IndexNow from the deploy script,
  which compares the new sitemap with the live one and sends only changed addresses.
- Brave (which Claude searches) and Perplexity have no console; they find pages by crawling and
  through links, which part F provides.

### 10.5 Counting visits from AI assistants

No cookies, no visitor IDs, no outside script:

- `site/site.js` sends one request to `/b` on our own domain when a page opens, with the referring
  site's host and any `utm_source`.
- The site Worker (`site/gallery-link.js`, already deployed for `/gallery`, `/i/`, `/open`, `/get`)
  handles `/b`: it sorts the referrer into a short list (ChatGPT, Perplexity, Claude, Gemini,
  Copilot, Google, Bing, other, none) and writes one row to Workers Analytics Engine: day, page,
  source. Nothing about the visitor is stored.
- The weekly report reads the totals.
- The privacy page gains one sentence saying so.
- Analytics Engine is free up to 100,000 rows a day on the Workers free plan.

Crawler visits don't run scripts; those come from Cloudflare's AI Crawl Control.

### 10.6 For agents

- `/.well-known/ai-catalog.json` on casama.ai lists the docs MCP server, the OpenAPI file and
  `llms.txt`.
- The MCP server answers `/server-card` (a small server change, shipped with a normal server
  deploy).
- `Link` headers on the sites point to the sitemap, the markdown twins and the API catalog.
- Serving markdown when a request asks for it (`Accept: text/markdown`) would need the Worker in
  front of every page request. Left out for now; the twins and `Link` headers cover the same need.

## 11. Cost

| Item | Unit price | A month |
|---|---|---|
| OpenSEO rank tracker, about 80 keywords, weekly (DataForSEO) | $1.98 for 83 keywords weekly, from the tool's estimate | about $2 |
| OpenSEO AI answers, 25 questions on 5 engines, weekly | $4.47 per 5 questions, from the tool's estimate | about $22 |
| Keyword and link lookups | cents each | about $5 |
| Search Console, Bing Webmaster Tools, IndexNow, Cloudflare, GitHub | free | $0 |
| **Total** | | **about $30, capped at $35** |

Casama pays; nothing is passed on to users. It goes into `docs/COSTS.md` when approved. Spent so
far on this plan: two keyword pulls, five AI questions on four engines and five link lookups,
roughly $1–2 of DataForSEO credit (estimated from the tool's prices, not a bill).

## 12. Phases

Each phase ends with one deploy of casama.ai, docs and gallery (`scripts/deploy-web.sh`), which
needs Oliver's yes each time.

**Phase 0: fix and measure.**

- Problems 1–5 and 7–9 in §2.3. Problem 6 (`app.casama.ai`) rides the next web app build.
- Bing: import the site, submit sitemaps, IndexNow.
- Search Console: submit the gallery sitemap; request indexing for the main pages.
- OpenSEO: the rank tracker and the AI answers tracker (Appendix A and B); the first weekly report.
- GitHub website link, topics and README opening.
- Done when: the docs sitemap has no `/public/` address and each one redirects; `www` redirects;
  every docs page has its own canonical address and description; Bing shows the site verified with
  three sitemaps; a deploy pings IndexNow; the first report exists with the baseline in it.

**Phase 1: the generator and core pages.**

- `site/build.mjs`, the three data files, the markdown twins, the new sitemap and `llms.txt`.
- `/pricing`, `/self-hosted`, `/open-source`, `/security`, `/about`; the homepage title and
  description (decision 3); navigation and footer links.
- Visit counting (§10.5) if decision 5 says yes.
- Done when: the five pages are live, the build fails on each rule in §10.1, and the homepage
  prices are checked against `plans.json`.

**Phase 2: alternatives and comparisons.**

- `rivals.json` with sources for all twelve rivals; the hub, twelve alternatives pages and three
  comparisons.
- Done when: every claim has a source dated within 45 days, each page names when the rival is the
  better pick, and all 16 are indexed.

**Phase 3: use cases and the gallery.**

- Eight use-case pages; the richer gallery app pages, group pages, structured data and `llms.txt`.
- Done when: each use-case page links to the gallery items it uses and back, and the gallery
  sitemap shows the new pages indexed.

**Phase 4: answers, changelog, posts.**

- Twelve question pages; `/changelog` with RSS; the blog with its first four posts and the author
  page; the agent files in §10.6.
- Done when: the changelog builds from `CHANGELOG.md` with no hand edits, and posts carry author
  and dates in structured data.

**Phase 5: mentions.** Runs alongside from Phase 0.

- Now: our own profiles; the listing kit in `docs/launch/listings.md`; directory submissions; the
  first GitHub list pull requests; install templates.
- With the launch: Show HN, Product Hunt, Reddit, dev.to; roundup outreach; video; stores.
- Done when: Casama is listed in at least eight directories and two GitHub lists, and each roundup
  author on the list has had one note.

**Phase 6: the loop.**

- Weekly: the report; one post; fixes for anything Search Console or Bing flags.
- Monthly: the rival facts check; refresh the pages whose facts changed; add the next alternatives
  page by demand; review which tracked questions name rivals and not us, and what those answers
  cite.
- Quarterly: re-run the audit in §2.

Phases 0–4 are about three to four weeks of building. Results lag the work: indexing takes days to
weeks, first-page places for the open searches four to twelve weeks, and AI answers follow the
mentions in part F, not our own pages.

## 13. Decisions for Oliver

| # | Decision | Recommendation |
|---|---|---|
| 1 | Scope | Build phases 0–4 in order without stopping between them; Phase 5's self-serve items alongside |
| 2 | Docs and gallery: stay on `docs.` and `gallery.`, or move under `casama.ai/docs` and `/gallery`? | **Stay.** A subfolder would pool link strength, but those addresses are baked into the apps, the CLI, npm and pub.dev packages and the agent kit. All new marketing pages go on casama.ai |
| 3 | Homepage title and description | Keep the H1, "AI teammates with their own computers." Change the title to "Casama \| Open-source AI agents with their own computers" and put "open source" and "self-hosted" in the description |
| 4 | Name rivals on our site | **Yes**: the twelve in part C, with sourced facts, dates and an honest "choose them if" |
| 5 | Count visits on the marketing site | **Yes, our own count only** (§10.5): no cookies, no IDs, no outside script. Without it we can't tell whether AI assistants send anyone |
| 6 | AI training crawlers | **Allow all**, and say so in `robots.txt`. Being in the training data is how a model knows Casama without searching |
| 7 | Monthly spend | About $30 through OpenSEO, capped at $35. No paid tools, placements or mentions |
| 8 | Author and pace | Posts and comparisons under Oliver's name with an author page; drafted by me, read by Oliver before publishing; one post a week |
| 9 | Off-site submissions | I prepare the listing kit and submit directories and GitHub list pull requests after one yes per batch. Hacker News, Product Hunt and Reddit stay Oliver's to post |
| 10 | Official profiles | Create X, LinkedIn and YouTube for Casama (or say which exist), so the About page and structured data can list them |
| 11 | `app.casama.ai` in search | Index the front page only, with a proper title ("Casama: sign in"), so "casama login" finds it. Ships with the next web build |
| 12 | Gallery app pages | The 61 real ones, made useful. No bulk app directory |
| 13 | Translations | Not now |
| 14 | Store listings | Outside this plan's build. I write the name, subtitle and keyword text from §4 for when they go public |

## 14. Risks

1. **The name is shared.** A moth genus has the Wikipedia page, and a crypto app holds the Product
   Hunt address `casama`. Part B is the answer; position 1 for "casama" is realistic, a knowledge
   panel is not promised.
2. **A new domain ranks slowly.** One week old, no links. The open searches come first; the
   contested ones need part F.
3. **A Google core update has been running since 2026-11-10**, and spam updates ran three times this
   year. Pages made in bulk are what they hit. Principle 3 and the 300-word and unique-title checks
   are the guard.
4. **Rival facts go stale.** Rakazo ships daily. The 45-day source rule and the monthly check keep
   pages from saying something false.
5. **AI answers are noisy.** The same question gives different lists each run. We track frequency
   over weeks and don't react to one run.
6. **Naming rivals.** True, sourced comparisons are allowed in the US. EU comparative advertising
   rules and trademark use were not checked in detail; the licensing lawyer items are still open
   (D-339). A lawyer's read of one comparison page before Phase 2 ships would settle it.
7. **Rivals copy the format.** They already have more pages. What they can't copy quickly is
   honest comparisons, real gallery pages and our own numbers.
8. **`llms.txt` and agent files may never matter for answers.** They cost little and serve
   developers either way.
9. **The launch decides part F.** Stars, Hacker News and Product Hunt can't be manufactured by this
   plan; without a launch, the mention targets in §15 slip.
10. **Shared working tree.** `site/` and `gallery/` are being edited by other sessions. The build
    starts from the files as they are then, and commits go by path.

## 15. How we'll know it worked

Targets, not forecasts. They assume the public launch happens inside the first 60 days.

| Measure | Today | 30 days | 90 days | 180 days |
|---|---|---|---|---|
| Sitemap addresses indexed by Google | not counted yet; 41 addresses shown in results, some of them duplicates | 90% | 95% | 95% |
| Bing | not listed | verified, 80% indexed | 95% | 95% |
| Position for "casama" (US) | 7.6 | top 3 | 1 | 1 |
| Tracked keywords in the top 10 (of about 80) | 0 | 5 | 20 | 35 |
| Clicks a month from Google | under 10 | 150 | 1,500 | 6,000 |
| Referring domains | 0 known | 15 | 70 | 190 |
| Tracked AI answers that name Casama | 0 of 12 | 10% | 25% | 40% |
| Top five for "\<rival\> alternative", six named rivals | 0 of 6 | 2 of 6 | 5 of 6 | 6 of 6 |

And against the three twins, from the weekly tracker: our share of top-10 places and of AI mentions
next to theirs.

## 16. Left for Oliver

- Answers to §13.
- A yes for each production step: the `www` redirect rule, each `deploy-web.sh`, the server deploy
  that adds the MCP server card.
- Bing Webmaster Tools: one click on "Import from Google Search Console" (or a yes for me to do it
  in the T3 browser).
- "Request indexing" clicks in Search Console (I can do these in the T3 browser, about ten a day).
- The launch timing, and posting on Hacker News, Product Hunt and Reddit.
- The 60-second demo video (already on `docs/NEEDS-FROM-OLIVER.md`).
- Public store listings.
- The Casama profiles on X, LinkedIn and YouTube.
- A lawyer's read of one comparison page (risk 6).

Already done while writing this: an OpenSEO project named Casama
(`f38d6b3d-09c9-42bc-baf6-5dc7a58ec674`) holding the keyword and AI-answer lookups above. Nothing
is scheduled in it.

## Status of the build (2026-11-18)

Built, in the working tree, not committed and not deployed:

| Part | State |
|---|---|
| Docs duplicate, canonical addresses, descriptions, share tags, structured data | Done; the docs build has 60 pages and no `/public/` copies |
| casama.ai title and description, `Organization` and `WebSite` data, not-found page, footer links | Done |
| `Content-Signal` lines in four `robots.txt` files | Done |
| Page generator with its checks, markdown copies, sitemap, `llms.txt`, RSS | Done: `site/build.mjs`, 50 pages |
| Core pages (5), alternatives (12 + hub), comparisons (3 + hub), use cases (8 + hub), questions (12 + hub), posts (4), changelog | Written |
| Gallery structured data, app titles, `llms.txt` | Done |
| IndexNow | Script and key files done; first ping happens on deploy |
| Visit counts | Done in `site/site.js` and `site/gallery-link.js`; starts on deploy |
| Search Console | Gallery sitemap submitted |
| GitHub | Website link, description and topics set |
| OpenSEO | Rank tracker (75 keywords) and AI answers (25 questions, 5 engines), both weekly; the first AI run was queued |
| Cost and decision records | `docs/COSTS.md`, D-381 |

Done later on 2026-11-18:

| Part | State |
|---|---|
| Deploy | casama.ai, docs and gallery are live with all of the above |
| `www.casama.ai` | A Cloudflare redirect rule sends it to `casama.ai` with a 301 |
| Bing Webmaster Tools | casama.ai and docs.casama.ai imported from Search Console and verified; three sitemaps submitted |
| Gallery group pages | `/c/<kind>/` and `/c/app|skill/<category>/`, 22 pages, in the sitemap |
| Agent files | `/.well-known/ai-catalog.json` and a server card for the docs MCP server |
| Weekly report | T3 scheduled task, Tuesdays 18:00, writes `reports/seo/<date>.md`; the first Tuesday of a month it also re-checks rival facts |
| GitHub lists | Pull requests open on punkpeye/awesome-mcp-servers and e2b-dev/awesome-ai-agents |
| Listing kit and roundup notes | `docs/launch/listings.md`, `docs/launch/roundup-notes.md` |
| Visit counts | On: Analytics Engine enabled, `/b` writes to the `casama_site_visits` dataset |
| Blog pictures | Four header pictures made with gpt-6-luna; each is the post's share image (`site/assets/blog/`) |
| More pages | `/compare/best-open-source-ai-agents`, `/alternatives/n8n`, `/learn/what-is-an-ai-employee`, `/learn/are-there-free-ai-agents` (54 written pages) |
| Google indexing | "Request indexing" clicked in Search Console for the first pages (about ten a day are allowed) |

First data, later on 2026-11-18:

| Part | State |
|---|---|
| AI answers | 0 of the first 28 answers mention Casama. They cite rivals' GitHub repos, "alternatives" articles on other sites, directories (Product Hunt, AlternativeTo, opensourcealternatives.to) and rivals' own pages |
| Google | "casama" alone means Kasama (restaurants) to Google, and casama.ai sits around 7th; "Casama AI" is now an `alternateName` in the homepage data |
| Bing | Had crawled none of the new pages; every casama.ai and docs address was sent through Bing's URL submission |
| New pages | Agent Zero, NanoClaw, nanobot and Lindy alternatives; OpenClaw and Hermes Agent alternatives roundups; the best open-source list now has nine (74 pages, live) |
| Outreach list | The 12 cited articles, authors and contact routes are in `docs/launch/roundup-notes.md`; askgpu.com is the best fit |
| OpenSEO | Claude and Perplexity checks failed on Cloudflare's 50-subrequest cap; the fix (child workflows per batch, retries) is merged and a self-host deploy config is ready (`openseo-web` branch `selfhost-wrangler-config`), but the bundle is 4.6 MiB gzipped and Workers Free allows 3 MiB: it needs Workers Paid ($5 a month) |

Not done:

| Part | Why |
|---|---|
| `app.casama.ai` robots file and description | In `client/web/`. Shipping them means building and deploying the whole web app, which would also publish every unreleased app change on `main` |
| Directory listings | Each directory needs a signed-in account; the kit is ready |
| kyrolabs/awesome-agents, awesome-selfhosted | Their rules turn away new repositories; after the launch, and March 2027 |
| Roundup notes | Drafted, not sent: they should come from Oliver's mailbox, after the launch |
| More starter bots and routines, install templates | Not started |
| The MCP server answering `/server-card` itself | The card is served from casama.ai for now; the server route needs a server deploy |
| The four posts under Oliver's name | Live; they still need his read |

## First full check (2026-11-20)

Written up in `reports/seo/2026-11-20.md`. Google had 85 of 97 casama.ai addresses indexed; Bing showed
no data yet; the AI answers named Casama in 0 of 115 answers (run of 2026-11-18). Fixed the same day:
the deleted Wikidata item left `sameAs`, a 512 px logo and the missing icons, `llms-full.txt`, "Keep
reading" links on every written page, docs titles and descriptions, unique gallery descriptions. What
no edit fixes: 0 GitHub stars and no referring domains (the launch), and a Wikidata item (wait for
independent coverage).

## Appendix A: tracked keywords (first set)

- **Name**: casama, casama ai, casama app
- **Open source and self-hosted**: open source ai agent, open source ai agents, open source ai
  assistant, self hosted ai agent, self hosted ai, self hosted ai assistant, local ai agent,
  private ai assistant, open source ai agent platform, best open source ai agents, best self hosted
  ai agents
- **Alternatives**: openclaw alternative, openclaw alternatives, hermes agent alternative, grok bot
  alternatives, grok bot alternative, manus alternative, manus alternatives, claude cowork
  alternative, rakazo alternative, openbot alternative, mausbot alternative, instinct ai
  alternative, hark alternative, meta muse alternative, chatgpt agent alternative
- **Comparisons**: openclaw vs hermes, hermes agent vs openclaw, rakazo vs openclaw, rakazo vs
  hermes, rakazo vs openmausbot, rakazo vs grok bot, openbot vs grok bot
- **Personal assistant**: ai personal assistant, personal ai assistant, personal ai agent, personal
  ai agents, best ai assistant, best ai personal assistant, ai executive assistant, ai chief of
  staff, proactive ai assistant
- **Work**: ai agents for business, ai workers, ai intern, ai employee, ai employees, ai workforce,
  ai teammates, ai teammate, ai coworker, ai agent for small business, best ai agents, free ai
  agent
- **Jobs**: ai email assistant, ai scheduling assistant, ai research assistant, ai coding agent
- **Questions and ideas**: what is an ai agent, how do ai agents work, ai agent vs chatbot, ai agent
  with its own computer, ai agents with their own computer, computer use agent, human in the loop
  ai, mcp client, is openclaw safe, is openclaw free
- **Apps**: ai assistant app, ai agent app, ai assistant for iphone, ai assistant android

Tracked with the three twins' domains as competitors: rakazo.com, open.bot, mausbot.com.

## Appendix B: tracked AI questions (first set)

Asked weekly on ChatGPT, Claude, Gemini, Perplexity and Google's AI Overviews, counting how often
Casama and each rival is named.

1. What are the best open-source AI agents that get their own computer and can be self-hosted?
2. I want an AI assistant that does real tasks for me on its own computer, works while I'm away,
   and asks before doing anything risky. What should I use?
3. What are the best alternatives to OpenClaw?
4. What are the best alternatives to Hermes Agent?
5. What are the best open-source alternatives to Grok Bot?
6. What are the best alternatives to Manus?
7. Rakazo vs MausBot vs OpenBot: which AI teammate platform should I pick?
8. What are the alternatives to Rakazo?
9. Is there an open-source alternative to Instinct?
10. Is there an open-source alternative to Hark Pro?
11. What is the best self-hosted AI assistant I can use from my phone?
12. Which AI agents have real iPhone and Android apps?
13. Which AI agent asks for approval before it sends, books or pays for anything?
14. What is the safest way to give an AI agent access to my email?
15. Which AI agents let me choose the model or use my own API keys?
16. Which AI agents can run on local models with Ollama?
17. What is the best AI personal assistant in 2026?
18. What is the best AI agent for a small business?
19. Which AI agents can run tasks on a schedule?
20. Which AI agents let me watch and take over their computer?
21. What does an AI agent with its own cloud computer cost a month?
22. Which AI agents don't train on my data?
23. What is an AI teammate?
24. What is Casama AI?
25. Is Casama open source, and how do I self-host it?

## Sources

Measured on 2026-11-18:

- Google Search Console, property `sc-domain:casama.ai`: search analytics, sitemaps, URL inspection.
- Bing Webmaster Tools: site list.
- OpenSEO at `seo.stackwares.com`, self-hosted on a VPS since 2026-11-18 (DataForSEO): keyword volumes and
  difficulty (US), backlink summaries, prompt explorer answers, tracker cost estimates.
- Live checks with `curl` on casama.ai, www, docs, gallery, app, casama.link and status; `cf
  bot-management get` and `cf ai-audit robots get` for the zone; `gh repo view stackwares/casama`.

Vendor rules:

- Google, AI features and your website: https://developers.google.com/search/docs/appearance/ai-features
- Google, AI optimisation guide: https://developers.google.com/search/docs/fundamentals/ai-optimization-guide
- Google, structured data gallery: https://developers.google.com/search/docs/appearance/structured-data/search-gallery
- Google, software app markup: https://developers.google.com/search/docs/appearance/structured-data/software-app
- Google, review snippet rules: https://developers.google.com/search/docs/appearance/structured-data/review-snippet
- Google, structured data policies: https://developers.google.com/search/docs/appearance/structured-data/sd-policies
- Google, spam policies: https://developers.google.com/search/docs/essentials/spam-policies
- Google, Search updates log (FAQ retired): https://developers.google.com/search/updates
- Google, Search status (2026 updates): https://status.search.google.com/summary
- Google, Generative AI report: https://support.google.com/webmasters/answer/16984139
- Google, crawlers: https://developers.google.com/search/docs/crawling-indexing/google-common-crawlers
- Bing, AI Performance report: https://blogs.bing.com/webmaster/February-2026/Introducing-AI-Performance-in-Bing-Webmaster-Tools-Public-Preview
- Bing, Topics Portfolio: https://blogs.bing.com/webmaster/2026/10/introducing-topics-portfolio-beta-in-ai-performance/
- Bing, training and grounding preferences: https://blogs.bing.com/search/2026/10/your-content-your-choice-clearer-preferences-for-training-and-grounding/
- IndexNow participants: https://www.indexnow.org/searchengines.json
- OpenAI crawlers: https://developers.openai.com/api/docs/bots
- OpenAI publishers FAQ: https://help.openai.com/en/articles/12627856-publishers-and-developers-faq
- Anthropic crawlers: https://support.claude.com/en/articles/8896518-does-anthropic-crawl-data-from-the-web-and-how-can-site-owners-block-the-crawler
- Perplexity crawlers: https://docs.perplexity.ai/guides/bots
- Cloudflare, crawler policies: https://blog.cloudflare.com/accountable-mixed-use-ai-crawlers
- Cloudflare, Content Signals: https://blog.cloudflare.com/content-signals-policy/
- Cloudflare, Markdown for Agents: https://developers.cloudflare.com/fundamentals/reference/markdown-for-agents/
- Cloudflare, AI Crawl Control: https://developers.cloudflare.com/ai-crawl-control/
- Cloudflare, agent readiness: https://blog.cloudflare.com/agent-readiness/
- MCP server cards: https://modelcontextprotocol.io/seps/2127-mcp-server-cards
- FTC, reviews rule: https://www.ftc.gov/business-guidance/resources/consumer-reviews-testimonials-rule-questions-answers
- FTC, comparative advertising: https://www.law.cornell.edu/cfr/text/16/14.15

Studies:

- GEO: Generative Engine Optimization (KDD 2024): https://arxiv.org/abs/2311.09735
- C-SEO Bench (NeurIPS 2025): https://arxiv.org/abs/2506.11097
- Earned media in AI search (University of Toronto, 2025): https://arxiv.org/html/2509.08919v1
- Ahrefs, what goes with AI brand visibility: https://ahrefs.com/blog/ai-brand-visibility-correlations/
- Ahrefs, `llms.txt` log study: https://ahrefs.com/blog/llmstxt-study/
- Ahrefs, freshness of cited pages: https://ahrefs.com/blog/do-ai-assistants-prefer-to-cite-fresh-content
- Seer, listicles in ChatGPT citations: https://www.seerinteractive.com/insights/the-listicle-window-is-closing-in-ai-search-30-decline-mom
- SparkToro, inconsistency of AI brand lists: https://sparktoro.com/blog/new-research-ais-are-highly-inconsistent-when-recommending-brands-or-products-marketers-should-take-care-when-tracking-ai-visibility/

Competitors (public pages, read 2026-11-18):

- Rakazo: https://rakazo.com/, https://rakazo.com/sitemap-index.xml, https://rakazo.com/llms.txt, https://rakazo.com/alternatives/, https://github.com/elie222/rakazo
- OpenBot: https://open.bot/, https://open.bot/sitemap.xml, https://www.copilotkit.ai/blog/openbot-vs-grok-bot, https://github.com/CopilotKit/OpenBot
- MausBot: https://mausbot.com/, https://mausbot.com/sitemap.xml, https://mausbot.com/llms.txt, https://mausbot.com/alternatives, https://github.com/milind-soni/OpenMausBot
- Grok Bot: https://x.ai/bot, https://docs.x.ai/grok-bot/faq.md, https://apps.apple.com/us/app/grok-bot/id6794501026, https://forum.cursor.com/t/grok-bot-gives-no-warning-before-weekly-usage-spills-into-paid-on-demand/169679
- Hark: https://hark.com/, https://hark.com/pricing, https://hark.com/using-hark, https://apps.apple.com/us/app/hark-pro/id6772362941, https://techcrunch.com/2026/10/06/hark-releases-an-ai-personal-assistant-with-a-focus-on-privacy/
- Instinct: https://instinct.com/, https://instinct.com/privacy-policy, https://instinct.com/terms, https://techcrunch.com/2026/08/24/instincts-powerful-ai-assistant-is-raising-privacy-and-security-concerns/
- Directories and roundups: https://openalternative.co/alternatives/rakazo, https://alternativeto.net/software/rakazo/, https://www.opensourcealternatives.to/alternative-to/grok-bot, https://www.bitdoze.com/best-open-source-grok-bot-alternatives/, https://every.to/personal-agents-comparison, https://github.com/kyrolabs/awesome-agents, https://github.com/awesome-selfhosted/awesome-selfhosted

Not verified: Reddit (blocked to the research tools); G2 and Capterra; xAI's crawler names; whether
Hark requires Gmail at sign-up (the page needs a browser).
