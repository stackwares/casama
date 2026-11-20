# Plans and where they stand

Every `docs/*-PLAN*.md` and its status, in one list. Last checked **2026-11-20** against each plan's
status line, `docs/DECISIONS.md`, the live stores and session notes.

**Keep it current.** When you write a plan, add its row here in the same commit. When a plan's status
changes (approved, built, shipped, dropped), update the row **and** the plan's own status line in the
same commit. Shipping details (deploys, app builds) move fast, so check them before acting on one.

| Status | Meaning |
|---|---|
| **Not started** | Written, waiting for Oliver's answers or go-ahead. No code |
| **In progress** | Approved, partly built; some phases or items still to do |
| **Built** | All the planned code is done; waiting to ship (deploy, push, app or store builds, device checks) |
| **Done** | Shipped, nothing left from the plan |

## Not started

| Plan | Written | Waiting on |
|---|---|---|
| [ADS-ATTRIBUTION-PLAN](ADS-ATTRIBUTION-PLAN.md) | 2026-11-20 | §15 decisions; then a Meta business portfolio, ad account and app (Oliver) |
| [RETENTION-MESSAGING-PLAN](RETENTION-MESSAGING-PLAN.md) | 2026-11-20 | §14 decisions; then 1.0 release and Apple's access |
| [SES-MIGRATION-PLAN](SES-MIGRATION-PLAN.md) | 2026-11-20 | §14 decisions; then an AWS account (Oliver) and AWS's sending review in Phase 0 |
| [SIRI-AI-PLAN](SIRI-AI-PLAN.md) | 2026-11-20 | §13 decisions; then a debug build on the iPhone for Phase 0 |
| [USAGE-LIMITS-PLAN](USAGE-LIMITS-PLAN.md) | 2026-11-20 | Oliver's go-ahead to build; the decisions are made (§2) |

## In progress

| Plan | Decisions | What's left |
|---|---|---|
| [BOT-EMAIL-PLAN](BOT-EMAIL-PLAN.md) | D-449 | Live 2026-11-20 (`87f520fd`): bots get `name@casama.app`, sending through Cloudflare Email Sending; 10/10 on mail-tester, Gmail inbox. Left: Outlook placement check |
| [GAPS-PLAN-2026-11](GAPS-PLAN-2026-11.md) | D-301..D-305 | Items 1–5 live. Item 6 (accessibility pass) and item 7 (more languages) not started; v1 is English only |
| [LAUNCH-VIDEO-PLAN](LAUNCH-VIDEO-PLAN.md) |  | Main cut v2, 30 s cut and 15 s cut made. Launch date and the narration voice are open; every video needs narration |
| [LIBRARY-PLAN](LIBRARY-PLAN.md) | D-274, D-276, D-281, D-291, D-294, D-295 | Pins, select several, "Recently opened", "what was made for a ticket" |
| [MASTER-PLAN-2026-11](MASTER-PLAN-2026-11.md) | D-267..D-293 | Most stages built. Left: Add 8 (languages, same as Gaps 7), Add 13 (start by text), Add 15 (SOC 2, data processing agreement), Library Phase 4 items above. Not checked item by item |
| [VENDOR-USAGE-PLAN](VENDOR-USAGE-PLAN.md) | §10 approved | Phases 1–4 implemented and verified locally; Phase 5 account setup/live checks remain. Production env/deploy need a separate yes |
| [WAITLIST-PLAN](WAITLIST-PLAN.md) | D-427 | Phases 1–3 live; Phase 4 on launch day; store builds |

## Built (waiting to ship)

| Plan | Decisions | What's left |
|---|---|---|
| [ADMIN-SECURITY-PLAN](ADMIN-SECURITY-PLAN.md) | D-448, D-450, D-452 | Server, docs and web app (build 60) live 2026-11-20, with passkey and Face ID unlock (D-450); passkey-or-PIN checks (D-452) built, waiting on a server, docs and web app deploy; store and desktop builds pending |
| [LIMIT-RESETS-PLAN](LIMIT-RESETS-PLAN.md) | D-443 | Server + docs live 2026-11-20 (6d11b195); switched on, test grant on Oliver's space (expires 2026-12-04); app builds with Use Reset pending |
| [APP-ART-PLAN](APP-ART-PLAN.md) | D-440 | Web app (51), server and gallery live 2026-11-20; store builds and a low-end Android startup check |
| [ADMIN-BOT-PLAN](ADMIN-BOT-PLAN.md) | D-435 | Push and deploy; then turn it on for admin@casama.ai's bot |
| [CALL-RECAP-PLAN](CALL-RECAP-PLAN.md) | D-429 | Server live; app builds and a real call check |
| [CALLS-PLAN](CALLS-PLAN.md) | D-327 | App builds; real-device checks |
| [CHAT-APP-FILES-PLAN](CHAT-APP-FILES-PLAN.md) | D-341, D-342 | Live; Mac build for iMessage files. Teams file consent and Telegram albums left for later |
| [CHROME-EXTENSION-PLAN](CHROME-EXTENSION-PLAN.md) | D-323 | Push, deploy, Chrome Web Store; real-device checks (§19) |
| [COMPUTER-UPDATES-PLAN](COMPUTER-UPDATES-PLAN.md) | D-360 | On origin/main; deploy |
| [GA4-LAUNCH-PLAN](GA4-LAUNCH-PLAN.md) | D-439 | Live everywhere; store uploads of build 50 when Oliver says; funnels (step 7) after a week of data |
| [GA4-PLAN](GA4-PLAN.md) | D-397..D-399, D-439 | Live (D-439); see GA4-LAUNCH-PLAN |
| [GROK-BOT-IMPORT-PLAN](GROK-BOT-IMPORT-PLAN.md) | D-415 | Live and in build 44; checks in the real app |
| [HELP-LINKS-PLAN](HELP-LINKS-PLAN.md) | D-431 | Server live; app builds |
| [IPHONE-DUO-PLAN](IPHONE-DUO-PLAN.md) | D-411 | On main; no deploy or store build; never seen on a device. Store screenshots and preview live |
| [ISLAND-AND-MENU-BAR-PLAN](ISLAND-AND-MENU-BAR-PLAN.md) | D-324 | Push, deploy, app builds; real-device checks (§19) |
| [LOCAL-MCP-PLAN](LOCAL-MCP-PLAN.md) | D-363 | On local main; push, deploy; real T3 Code sign-in needs a Mac build |
| [NOTIFICATIONS-PLAN](NOTIFICATIONS-PLAN.md) | D-325 | Live; native code never compiled; app builds |
| [OS-PERMISSIONS-PLAN](OS-PERMISSIONS-PLAN.md) | D-376 | Deploy; native code never compiled; app builds |
| [PLUGIN-CARDS-PLAN](PLUGIN-CARDS-PLAN.md) | D-345 | Pushed; deploy |
| [REMOTE-CONTENT-PLAN](REMOTE-CONTENT-PLAN.md) | D-370..D-374 | Push, deploy; gallery publish; app builds |
| [SEO-PLAN](SEO-PLAN.md) | D-381 | Phases 0–4 built; deploy; see "Status of the build" |
| [SITES-AND-DOMAINS-PLAN](SITES-AND-DOMAINS-PLAN.md) | D-329 | On local main; production steps and Oliver's yes on Dodo |
| [SMOOTH-DEPLOYS-PLAN](SMOOTH-DEPLOYS-PLAN.md) | D-402 | Live in prod; app builds. Phase 3b (start the new worker first) not built |
| [WATCH-PLAN](WATCH-PLAN.md) | D-410 | Audit fixes not deployed; watch builds; Wear never on a real watch |
| [WIDGETS-PLAN](WIDGETS-PLAN.md) | D-405 | Push, deploy; native never compiled; push key, Mac profiles, app builds |
| [ZOHO-APP-PLAN](ZOHO-APP-PLAN.md) | D-350 | Live; app build for the logos; no real Zoho sign-in tested |

## Done

| Plan | Decisions | Notes |
|---|---|---|
| [ADMIN-BOT-RESETS-PLAN](ADMIN-BOT-RESETS-PLAN.md) | D-445 | Server and docs live 2026-11-20 (14281b6d); the admin bot was already on |
| [ANALYTICS-PLAN](ANALYTICS-PLAN.md) | D-206..D-210 | |
| [APP-MENTIONS-PLAN](APP-MENTIONS-PLAN.md) | D-434 | Live (confirmed by Oliver 2026-11-20) |
| [DOCS-REFRESH-PLAN](DOCS-REFRESH-PLAN.md) | | Live on docs.casama.ai 2026-11-20 |
| [DOCUMENT-FILES-PLAN](DOCUMENT-FILES-PLAN.md) | D-351 | Live and in app build 32 |
| [LINK-PLAN](LINK-PLAN.md) | D-296 | Live in prod |
| [PLUGINS-AND-PACKS-PLAN](PLUGINS-AND-PACKS-PLAN.md) | D-343 | Live in prod |
| [REACTIONS-PLAN](REACTIONS-PLAN.md) | D-331 | Live everywhere 2026-11-17 |
| [SHOWCASE-PLAN](SHOWCASE-PLAN.md) |  | Live on casama.ai 2026-11-19 |
| [STORE-SCREENSHOTS-PLAN](STORE-SCREENSHOTS-PLAN.md) |  | Checked live 2026-11-20: App Store iPhone, iPad, Mac 10 each (+ folding iPhone 9, Watch 5, previews); Play phone, 7" and 10" tablets 8 each, feature graphic, Wear 5 |
| [WEEKLY-PLAN-PLAN](WEEKLY-PLAN-PLAN.md) | D-432 | Live (confirmed by Oliver 2026-11-20) |
| [USAGE-PLAN](USAGE-PLAN.md) | D-354, D-355 | Steps 1–8 live; step 9 dropped (false on Casama Cloud) |
| [VISUALS-PLAN](VISUALS-PLAN.md) | D-379 | Share cards, heroes, 404 scene, wallpapers live. Not checked item by item |
