# Sites and domains: the plan

Status: **approved for execution** (Oliver, 2026-11-16: "start executing the plan in a separate
worktree, don't stop until all phases complete"). Being built: see Progress. Open decisions in §13 are
taken at their recommendation unless Oliver changes them. Vendor facts below were checked against
the vendors' own pages on 2026-11-16 (sources at the end); the ones that could not be checked are
marked. The decision number is the next free `D-` number when the first phase merges.

## Progress

Built on branch `t3/sites-and-domains` (worktree `t3-67fbf5ea-…`), not merged or deployed. The
decision is **D-329**.

| Phase | Commits | What passed |
|---|---|---|
| 1 A site has an address | `fa097c89` rules, `e6d3eacd` tables (every phase's, in one migration), `cad2ea39` serving, `f473f877` bot note and `/_casama/` kept, `da8a4592` zone page and live check, `c4555791` docs, `8454fce3` sweep fix, `09fa3478` app | typecheck; server 747 tests (sites 17), domain 139, agent 294, contracts 11; pgTAP 37 files (sites 28); `pnpm gen` clean; docs build; `flutter analyze` clean, `flutter test` 1032. `pnpm lint` fails on `main` already (1,301 errors in files this track doesn't touch); every file this track touches passes `biome check`. `sites-live-check.ts` written, not run: it needs the sites zone (§14 #1, #2) |
| 2 Connect a domain you own | `0deb4293` Cloudflare client and proof checks, `1908f147` routes, proof, upkeep, pause rule and `domains.connect`, `ae0c62da` on-demand TLS for self-hosted, `873a7a37` docs and hostnames live check, `7340e09c` app | typecheck; server tests, domain 139; pgTAP; `pnpm gen` clean; docs build; `flutter analyze` clean, `flutter test` 1048 (domains 16). `hostnames-live-check.ts` written, not run (§14 #1, #2) |
| 3 Buy a domain | `3ee89785` registrar adapter, fake and live check, `2ac0c546` Dodo domain payments, `ba1d6f06` contracts, `409d0484` search, checkout, registration workflow, refunds, Admin → Domains, `domains.search`, `241839ef` docs, terms and runbook, `6283c9f4` app (with Phase 4's screens) | server `domains-buy.test.ts` 19; everything against fakes (Name.com Core API v1 shapes, Dodo PWYW and on-demand). `registrar-live-check.ts` written, not run (§14 #3, #4) |
| 4 Keep a domain | `f9a795bd` registrant email by address and the notice emails, `f132bb44` contracts, `49577fa8` renewals, charges, expiry, DNS records, reminders, transfer out, released domains, reconcile, `ca33bfd1` docs, `6283c9f4` app | server `domains-lifecycle.test.ts` 9 (clock moved: automatic renewal from E − 31; failed charge, expiry, late Renew Now; lapsed and gone; records; reminders; transfer out; moved out; deleted workspace); pgTAP sites 30 |
| 5 The rest | `653b2052` CLI `casama sites` / `casama domains`, TS and Dart SDK helpers, MCP tools, `0b443149` agent-kit skill, `llms.txt`, changelog, PSL submission (`docs/PSL-SUBMISSION.md`), `2e6790c4` docs, `a85fa456` `c26d2209` `bad18baa` fixes | Final run: typecheck 14/14; server 794 passed / 19 skipped; agent 294 (gallery test flaked once under load, passes alone); domain 139; contracts 11; client 16; mcp 17; Dart CLI 38; pgTAP all files pass; `pnpm gen` clean; docs build; `flutter analyze` clean, `flutter test` 1078. The CLI against the local stack and the PSL request wait for the zone (§14) |

Deviations, each on purpose:

- The registrant's email for a bought domain is kept in a server-only table
  (`domain_registrants`), not sealed with the workspace key: the key goes when the workspace is
  deleted, and the registrant must still hear about the domain (§7.10). The registrant's other
  details (`domain_contacts`) are sealed.
- Search engines and turning the badge off follow `max_custom_domains > 0`, so the plan needs only
  the two limit keys of §7.13.
- Upkeep for bought domains has no advisory lock: it runs from the hourly scheduled workflow
  (once per hour by DBOS) and every step is keyed `<domain>:<expiry date>:<step>`, which is what
  stops a double charge or email.
- A finished transfer out turns the row into a `connected` domain instead of keeping
  `moved_out`, so the normal proof checks keep the site up or take it down (§7.10's outcome).
- The app has no "delete workspace" screen; **Delete My Account** lists the bought domains of the
  workspaces you own before deleting. A re-sign-in for the transfer code uses an email code
  (refreshing a token doesn't renew its sign-in time).
- Connected hosts are registered at the edge when the domain is connected (§7.4 step 1, since the
  ownership record comes from the edge). The test in §10 "nothing is sent to the edge before
  proof" is read as "nothing is served before proof, whatever the edge says".

## 0. Summary

Bots already build websites: a page with its own files (D-289) is a real multi-page site. What a
person can't do is put it on the web at a name they'd tell someone. Today a public page lives at
`pages.casama.ai/s/<random token>`, marked `noindex`, with a "Updated … UTC" line at the bottom.

This plan adds three things, each usable without the next:

| Part | What a person gets | Built on |
|---|---|---|
| **Site addresses** | **Publish to the Web** in the Library puts a site at `name.<sites zone>`, over HTTPS, in one tap | A new zone on Cloudflare, a wildcard record, a second tunnel, and serving by host name in the existing pages server |
| **Connect a domain you own** | Type `bakery.com`, add the records shown, the site is live on it with a certificate a few minutes later | Cloudflare for SaaS custom hostnames on that zone, with Casama's own proof of ownership in front |
| **Buy a domain** | Search, pay, and the site is live on the new domain with no DNS step; renewals are announced and charged; the domain can be moved out any time | A wholesale registrar's API (Name.com recommended), Dodo Payments, and a durable workflow for every money step |

The suppliers:

| Need | Recommended | Why | Fallback |
|---|---|---|---|
| HTTPS for strangers' host names | **Cloudflare for SaaS** | Casama is already on Cloudflare; 100 hostnames included, then $0.10 each a month; per-hostname origin now on every plan; works through a tunnel | Caddy on-demand TLS (self-hosted servers); Approximated |
| Registering domains for people | **Name.com reseller API** | Clean REST API with a full test system; pays by card, no deposit; the end user is the registrant; free privacy; ANAME records; renewals, lock and transfer codes over the API. It is what Vercel, Netlify, Replit, Bolt and Lovable use | Openprovider (cheapest .com at cost, no ANAME), OpenSRS (Shopify's, XML, prepaid) |
| Taking the money | **Dodo Payments**, already wired | One payment provider, merchant of record, a changing amount per purchase and charges on a stored mandate for renewals | Only if Dodo says no (§2.4): Stripe directly, with Stripe Tax |

Three findings shape the build more than anything else:

1. **Cloudflare activates any host whose DNS points into our zone, whichever customer asked.**
   So "active" at Cloudflare proves nothing, and the classic takeover of a forgotten DNS record
   applies. Casama keeps its own proof per domain (§7.4).
2. **Dodo's acceptance policy lists "resale model" and "hosting plans" among businesses it can't
   support.** Domains aren't named. Selling them needs Dodo's written yes before Phase 3 goes
   live (§2.4, §14). The code is built and tested either way.
3. **A domain is a promise that lasts years.** Buying is the easy half; renewal notices, failed
   charges, expiry, transfer codes and what happens when a workspace is deleted are most of
   the work, and they ship together with buying (decision 13).

## 1. What exists today

No site has its own address and no domain code exists. D-289 lists custom domains under "Not
done"; `docs/LIBRARY-PLAN.md` lists them under "Later, not planned". What the feature stands on:

| Already built | Where | What this plan does with it |
|---|---|---|
| Pages: one HTML document plus a data block, versions, private / workspace / public | D-119; `packages/agent/src/pages.ts`, `packages/domain/src/pages.ts`, `supabase/migrations/20261211000001_pages.sql` | A site is a public page served at its own address. No second content model |
| Sites and games with their own files (300 files, 25 MB) | D-289; `page_assets`, `PAGE_CSP_ASSETS`, `readSiteFolder` | These are the files a site address serves at `/img/hero.png`, `/about.html` |
| The pages origin: a separate server port with its own host name | D-092; `apps/server/src/pages/app.ts` (`createPagesApp`), started in `apps/server/src/main.ts:195` on `PAGES_PORT`, public at `PAGES_URL` | Gains a second app for site hosts, chosen by the request's `Host` |
| Pages that take input | D-279; `/s/{token}/collect`, `page_submissions`, `collectScript` | Contact forms work on a site at `/_casama/collect` |
| Public links, reports, takedown | D-281; `creation_reports`, three reporters hide a page, `GET /v1/admin/reports`, `POST /v1/admin/creations/{id}/takedown` | The same reports and takedown take a site offline on every address |
| The Library: every page is a creation with a label (**Site**, **Game**) | D-274, D-294; `client/lib/features/library/creation_detail.dart` | **Publish to the Web** lives on the creation's screen |
| A Cloudflare adapter written with plain `fetch`, and a fake Cloudflare for tests | D-296; `apps/server/src/link/tunnels.ts`, `apps/server/test/fake-cloudflare.ts` | The custom hostname adapter copies its shape and extends the same fake |
| An address zone that is "a new domain, never `casama.ai`" | D-296, casama.link | The same rule for the sites zone (§7.1) |
| Hourly upkeep in the worker with advisory locks, and a once-a-day capacity notice to the instance owners | `apps/server/src/link/upkeep.ts`, `apps/server/src/worker/workflows.ts` (`link-upkeep`) | `domains-upkeep` follows the same pattern |
| Billing behind one interface: Dodo Payments on web and desktop, RevenueCat for the stores; webhooks verified, stored once, then re-fetched | D-070, D-297; `apps/server/src/billing/` | Domain payments are a new kind of Dodo payment handled in the same webhook path |
| Plan limits in `plans.limits` and `entitlements.limits`, `enforceLimit` | `apps/server/src/billing/limits.ts`, `public.entitlement_limits` | Two new keys (§7.13) |
| Where web payment may be offered | `purchaseChannels` in `client/lib/core/billing.dart` | The buy flow is gated on it (§2.4) |
| Account email outbox with dedupe keys; ZeptoMail | D-302, D-318; `apps/server/src/services/account-emails.ts` | Renewal and expiry notices |
| Notifications with a free-text `kind` | `packages/agent/src/notifications.ts` | New kinds without breaking shipped apps |
| Workspace suspension | `apps/server/src/services/abuse.ts` (`suspendOrg`) | A suspended workspace's sites stop serving at once |
| Content encryption at rest, opened by the database client | `packages/db/src/content-crypto.ts`, `packages/db/src/index.ts:44` | Registrant contact details are sealed like other content |
| Links that open the installed app | D-326; `appLink(env, path)` | Every email and bot link to **Domains** |
| Self-host Caddy with one site for the app and one for pages | `infra/compose/selfhost/Caddyfile` | A third, on-demand TLS site for connected domains (§7.12) |

How production serves pages today (read from the server on 2026-11-16, nothing changed):
`pages.casama.ai` (since D-378: `share.casama.page`) is a public hostname on the remotely managed `casama-prod` tunnel; `cloudflared`
on the server forwards it to Caddy on `127.0.0.1:8790`, which forwards to the API process's pages
port. Caddy keeps the `Host` header. Ports 80, 443 and 8790 are bound to loopback
(`HTTP_BIND=127.0.0.1`), so nothing reaches the pages server except through the tunnel.

Five things do not exist and have to be built:

1. **Serving by host name.** The pages server ignores `Host`; every page lives under
   `/p/{id}` or `/s/{token}` on one shared origin.
2. **A stable public address.** A public link is a random token that changes each time the page is
   made public again. Nothing a person could print on a business card.
3. **A document fit for a website.** Every page is sent with `noindex`, `no-store`, an
   "Updated … UTC" line at the bottom, and other `.html` files in the folder are served without
   the form script.
4. **TLS for host names we don't own.**
5. **Anything that talks to a registrar,** takes a payment whose amount isn't a fixed product, or
   charges a renewal a year later.

## 2. What the platforms and rules allow

These shape the design, so they come before it.

### 2.1 Cloudflare for SaaS

| Fact | Consequence |
|---|---|
| Free, Pro and Business zones include **100 custom hostnames**, then **$0.10 per hostname** (a month, per Cloudflare's 2022 announcement; the plans page doesn't say the period). Up to 50,000; past an enforcement threshold the API refuses new ones | Cost row in §8; usage read from `GET …/custom_hostnames/quota` |
| "Each custom hostname counts toward usage until you delete it. This includes hostnames that are pending" | Unproved claims expire after 7 days and are capped (§7.4) |
| `custom_origin_server` per hostname is on Free, Pro and Business since May 2025 | Not needed here (one origin), but it makes custom domains for Casama Link servers possible later (§6) |
| Wildcard custom hostnames, custom certificates, apex proxying with fixed IPs: **Enterprise only** | Bare domains depend on the person's DNS company (§7.5) |
| API: `POST/GET/PATCH/DELETE /zones/{zone}/custom_hostnames[/{id}]`; fallback origin `PUT …/custom_hostnames/fallback_origin`. `ssl.method` is `http`, `txt` or `email`. Ready means `status` **and** `ssl.status` are `active`. A bare PATCH can reset `ssl` settings; send them back | `CloudflareHostnames` (§7.3) |
| Token permission **SSL and Certificates: Edit**, which can be scoped to one zone | A token for the sites zone only |
| Real-time validation: the person adds one CNAME to our target, and Cloudflare activates the host, issues a certificate (Google Trust Services first, Let's Encrypt if CAA blocks it), usually within minutes. It retries for about 7 days, then the hostname is `moved` or deleted | The flow and timings in §7.4 |
| Every hostname also has an ownership TXT record (`_cf-custom-hostname.<host>`) with a value per registration | Proof B (§7.4) |
| A host in the person's own Cloudflare account works (a proxied CNAME, "orange to orange"), but pre-validation doesn't, and their settings run first. Cloudflare recommends the end customer **not** proxy it | The connect screen tells Cloudflare users to set the record to **DNS only** |
| A CNAME at a bare domain: works when their DNS is Cloudflare (it flattens). ALIAS/ANAME at other DNS companies: **not documented** | Phase 2 live check decides; forwarding to `www` always works (§7.5) |
| "Multiple SaaS providers can hold an active custom hostname for the same domain"; traffic goes where the CNAME points. Cloudflare's advice: delete a customer's hostname when they leave | Daily proof checks and removal (§7.4) |
| The fallback origin may be "a CNAME DNS record that points to a public hostname exposed by Cloudflare Tunnel"; the `Host` header and SNI reach the origin unchanged. Tunnel ingress matches on host name and needs a final catch-all | A dedicated tunnel whose catch-all goes to the pages port (§7.1). Exact ingress verified in the Phase 1 live check |
| Webhooks exist for certificate events only; hostname status must be polled. 15 new certificates a minute; the account API allows 1,200 requests per 5 minutes | Upkeep polls in small batches (§7.4) |
| Proxied wildcard records work on every plan; Universal SSL covers one level below the zone | Site addresses are one label deep (`name.<zone>`), never `a.b.<zone>` |
| Terms: SSL for SaaS may be used "solely to secure your end customers' … subdomains as part of your integrated SaaS application"; not to resell Cloudflare | That is exactly this use |

### 2.2 Name.com (the recommended registrar)

| Fact | Consequence |
|---|---|
| Core API v1: REST and JSON, an OpenAPI description, Basic auth with a username and token. Test system at `api.dev.name.com` with $100,000 of test credit, webhooks included | `NameComRegistrar` and its live check run on the test system (§10) |
| No fee, no application to start. Purchases use the account's card or prepaid credit; default purchase limit $2,500 | No deposit; the balance check (§7.6) watches credit when used |
| Wholesale price table is only visible after signing up. For scale: Vercel resells Name.com at cost and charges **$12.03** for .com today; the .com registry fee rose to $10.97 on 2026-11-01 (plus $0.20 ICANN fee) | The price formula reads the live cost from the API, never a constant (§8) |
| Availability up to 50 names a call, prices per name including premium, register, renew, auto-renew switch, lock, transfer code, contacts, nameservers | The adapter in §7.6 |
| WHOIS privacy free. DNS records A, AAAA, **ANAME**, CNAME, MX, NS, SRV, TXT; minimum TTL 300 s; **no CAA**. URL and email forwarding | DNS editor scope (§7.9) |
| Webhooks (HMAC signed): balance, contact verification, expiry, lock, registry notices, removal, transfers in and out | `POST /hooks/registrar/namecom` |
| Registrant email verification: 15 days, then the domain stops resolving. Three ways: Casama as contact, Name.com sends (white label on request), Casama sends (needs an addendum) | Name.com sends, white-labelled once approved (decision 9) |
| Renewal notices (about 30 and 5 days before, within 5 after) and the yearly data reminder are sent by Name.com the same way | Our own emails carry the price and the link; in-app notices and pushes state facts only (§2.4, §7.8) |
| 20 requests a second, 3,000 an hour, for the whole account | Call budget in the adapter (§7.6) |
| After 25 days past expiry the domain leaves the API; late renewal and restore only in Name.com's dashboard | `lapsed` state, support-only restore (§7.8) |
| Sub-accounts and "mark verified" need reseller approval | Not used |

Other suppliers checked: Openprovider (REST, sandbox, .com at $11.17 with a $50-a-year membership,
personalised emails, **no ANAME**, no webhooks found), OpenSRS/Enom (Tucows; XML, prepaid, $95
activation, .com $12.25–15.25 by tier; Shopify's), CentralNic Reseller (100-domain first-year
minimum), Porkbun (clean API, but "not a reseller service"), Vercel (Name.com at cost, no reseller
terms), GoDaddy (API reseller plan by invitation), Squarespace reseller program, Entri Sell (Entri
and a partner registrar sell, Casama gets a commission; $249 a month), Cloudflare Registrar API
(beta, at cost, but domains stay in Casama's account on Cloudflare nameservers, no renewals or
transfers over the API yet, 500 domains per account, and no reseller grant). The adapter interface
keeps Openprovider a one-file switch.

### 2.3 Domain rules that reach a reseller

| Rule | What it means here |
|---|---|
| Registrant contact checked, and email confirmed within **15 days** of registration or a change, or the domain is suspended (RAA, Whois Accuracy Specification) | The domain screen shows the step; reminders on days 3, 7, 12 (§7.17) |
| Renewal notices about one month and one week before expiry, and one within 5 days after (ERRP); **renewal, late renewal and restore fees must be shown on the reseller's website** | Our notices, plus a public price page in the docs listing all three per ending (§7.11, Phase 3) |
| .com: expiry → registrar grace (up to 45 days, Name.com keeps it in the API 25) → 30-day redemption → 5 days pending delete | §7.8 timeline |
| Transfer to another registrar may be refused for **60 days after registration** and after a registrant change. The revised Transfer Policy (30 days, 14-day codes) was adopted on 2026-06-07 with **no effective date** | `transfer_after = registered + 60 days`; one constant to change later |
| The five-day Add Grace Period refund is capped per registrar (10% of new registrations or 50 names a month) | No change-of-mind refunds; failed registrations always refunded (§7.7) |
| Reseller duties (RAA 3.12): no ICANN logo; the registration agreement names the sponsoring registrar and carries the required terms; link the registrant benefits and educational pages | The domain terms page and the checkout (Phase 3) |
| Registration data is redacted by policy since 2025-08-21; paid privacy isn't needed where the registrar redacts | Privacy on and free; nothing to sell |
| DNS abuse (phishing, malware, botnets) must be acted on promptly once reported with evidence; the registrar keeps the duty, a reseller should acknowledge, log and suspend | Runbook and **Suspend** (§7.11) |
| Endings with residency or presence rules (.us, .ca, .eu, .de, .uk) and two-year minimums (.ai) | Not sold in v1 |

**Endings on sale in v1:** .com .net .org .co .io .app .dev .xyz .me .info — no eligibility rules,
one-year terms. `.app` and `.dev` are HTTPS-only by browser rule, which every Casama site is. .site,
.online, .store, .tech and .shop are cheap for the first year and three to eight times dearer at
renewal, with very many premium names; they are left out until the renewal price is shown
everywhere and premium names are refused (they are, but the support load isn't worth it yet).

### 2.4 Payments and the app stores

**Dodo Payments**

| Fact | Consequence |
|---|---|
| A one-time **Pay What You Want** product takes `amount` per item in `product_cart` on `POST /checkouts` (USD base, a minimum price required, no maximum) | First purchase and **Renew Now**: a checkout for exactly the order's price |
| **On-demand subscriptions**: a checkout with `subscription_data.on_demand` stores a mandate; later `POST /subscriptions/{id}/charge` with `product_price` charges any amount. No approval needed. No automatic retries; `409` while a payment is pending; `429` after more than four failures since the last success; webhooks `payment.succeeded`/`payment.failed` | One "Domains" mandate per workspace, made with its first purchase when **Renew automatically** is on; renewals and later purchases are charges on it; Casama schedules retries (§7.8) |
| Fees 4% + $0.40, +1.5% international, +0.5% on subscriptions; refund $1, chargeback $30; original fees aren't returned on refund | Price formula (§8) |
| Tax is added by Dodo as merchant of record unless the price is marked tax-inclusive. Whether on-demand charges get tax the same way is **not documented** | Ask Dodo (§14); screens say "plus tax" |
| Acceptance policy, "Businesses We Can't Support": item 23 "hosting plans … persistent infrastructure"; item 30 "selling on behalf of others … taking funds and forwarding them elsewhere". Domain registration isn't named | **Written yes from Dodo before Phase 3 is turned on.** If no: a `DomainPayments` interface already separates domain charges from plans, and a Stripe adapter is the fallback (Casama then collects sales tax itself through Stripe Tax; a decision for Oliver, not part of this build) |

**App stores**

| Store | Rule | Decision 5 default |
|---|---|---|
| Apple 3.1.1 | In-app purchase to "unlock features or functionality within your app" | A domain unlocks nothing in the app |
| Apple 3.1.3(e) | Goods or "services that will be consumed outside of the app" **must** use other payment methods | A domain is used on the web; Namecheap's iOS app sells domains with card and Apple Pay and no in-app purchase |
| Apple, US storefront | Links and buttons to outside purchase are allowed | iOS and Mac App Store: **Buy**, **Renew Now** and the price follow `purchaseChannels` (web channel present: US storefront). Other storefronts: none of them and no pointer elsewhere (3.1.1(a): no "buttons, external links, or other calls to action"), as on Android. Checked 2026-11-17 |
| Google Play | Play Billing for in-app "features or services", naming "cloud software and services"; the only exemptions are physical goods, physical services, bill payments and a few others. Domains aren't named, so a domain bought in the app could be read as needing Play Billing. §4: no "buttons, links, messaging" toward another way to pay | Android: no **Buy**, no **Renew Now**, no price, no turning renewals on, and no mention of buying elsewhere (as with plans, Google's link program was declined 2026-11-14). Android lists, connects and manages domains and can turn renewals off. Checked against the policy page 2026-11-17 |
| Web and desktop | — | **Buy** everywhere |
| Notices in the app | The same rules cover the inbox and pushes on Android and outside the US storefront | In-app notices and pushes about renewals state facts only: the date, whether it renews by itself, that a charge failed. No price, no "renew now". The emails keep the price and how to pay; outside the app that's allowed. Changed 2026-11-17 |

**If App Review objects.** Remote settings carry `buy_domains_app_store`. Set to `false`, it hides
**Buy**, **Renew Now** and the price in the iOS and Mac App Store builds only, without a release;
web, desktop and the server are unaffected, and Android never shows them. Absent or `true`, the
storefront rule above applies.

**App Review notes** (paste into the review notes of the first build with domains):

> Casama can register internet domain names for websites people publish with it. A domain is a
> service used outside the app, on the web (guideline 3.1.3(e)); it unlocks no feature or content
> in the app. Like other registrars' apps, it is paid by card through our web checkout (Dodo
> Payments), not in-app purchase. Following 3.1.1(a), the button to buy appears only on the United
> States storefront; on every other storefront the app shows no price, no buy button and no
> pointer to buying elsewhere, and people can still connect a domain they already own. Plans and
> credits are sold through in-app purchase as before. To see it on a US account: Settings →
> Domains → Find a Domain.

### 2.5 Browsers, block lists, the Public Suffix List

- Safe Browsing and similar lists match a host and every parent up to the registrable domain. A
  phishing page on one site address can get the **whole sites zone** flagged unless the zone is on
  the Public Suffix List, and it can never touch `casama.ai` because the zone is a different
  domain (Google's own advice: serve user content from a separate domain).
- The list's private section takes a pull request from the domain's owner, a `_psl` TXT record, a
  registration paid more than two years ahead, and "a minimum of 2000 - 3000 distinct users".
  Entries made to dodge rate limits are refused. No timeline.
- So: buy the zone for three years or more, and submit once there are a few thousand live sites
  (Phase 5 prepares it; Oliver sends it).
- Google Search Console verifies a domain by TXT record, and a subdomain by a meta tag or a file at
  the root. Sites can do both: a meta tag in their HTML, a file in their folder, and TXT records
  in **DNS Records**.

### 2.6 Caddy on-demand TLS (self-hosted servers)

- `on_demand_tls { ask <url> }` globally and `tls { on_demand }` on a catch-all `https://` site.
  Caddy calls the ask URL with `?domain=<name>` before each new certificate; any 2xx allows it. It
  must answer in milliseconds, with no network calls. "On-demand TLS must be both enabled and
  restricted to prevent abuse."
- Let's Encrypt allows 50 certificates per registered domain per week and 300 new orders per
  account per three hours; failures are limited per host. A self-hosted zone with many site
  addresses should use one wildcard certificate (DNS challenge) instead of one per address; the
  docs say so.

## 3. Goals and what this is not

**Goals**

1. A person who asked a bot for a website can put it on the web at a name they'd say out loud, in
   one tap, and on their own domain in a few minutes.
2. A person with no domain can find one, pay, and have their site live on it without ever seeing
   a DNS record.
3. The domain is theirs. They are the registrant, they can edit its DNS, and they can move it to
   another registrar without asking us.
4. Nobody loses a domain by surprise: renewals are announced, retried and visible.
5. Sites can't be used to take over someone's host name or to phish, and one bad site can't hurt
   Casama's own addresses.
6. It pays for itself: every domain sold covers its wholesale price, the payment fee and the
   hostname fee with a margin (§8).

**Not goals**

- A general web host. A site is a page a bot published: static files, forms that post to Casama.
  No server-side code, no databases, no file uploads from visitors.
- A registrar business. Casama resells one registrar's service inside the product. It has no
  storefront, no bulk tools, no auctions, no premium names.
- Email hosting. People can add their mail provider's records in **DNS Records**.

## 4. Principles

1. **One content model.** A site is a public page with an address. There is no second place where
   site content, versions or sharing rules live.
2. **Our proof before our edge.** A host is served when Casama has seen the proof, whatever
   Cloudflare says.
3. **The server decides, the worker does.** Routes record what a person asked for; a durable
   workflow talks to the registrar and the edge, so a crash mid-purchase resumes instead of
   charging twice or leaving a paid order unregistered.
4. **Every provider behind an interface with a fake.** `HostnameProvider`, `Registrar` and the
   existing `BillingProvider`. Swapping a registrar is one file.
5. **Money moves once.** Each payment, registration, renewal and refund has an idempotency key
   that comes from one row.
6. **Off by default.** Every part is a setting that is unset on a fresh server and in production
   until Oliver turns it on, and a remote flag that can turn it back off without a deploy.
7. **Nothing shipped breaks.** No existing route, enum value or page link changes.
8. **Plain words.** People see "address", "domain", "records to add", **Live**. They never see
   "custom hostname", "DCV", "CNAME flattening" or "EPP".

## 5. Words

| Word | Meaning |
|---|---|
| **Site** | A page (often with its own files, D-289) that has been published to the web |
| **Address** | The free name every site gets: `name.<sites zone>` |
| **Domain** | A name like `bakery.com`, either connected (bought elsewhere) or bought in Casama |
| **Host** | One exact name a site answers on: `bakery.com` and `www.bakery.com` are two hosts of one domain |
| **Primary** | The host the site lives on; its other hosts send visitors there |
| **Target** | The name a domain's DNS records point at; one per domain, on the sites zone |
| **The edge** | Whatever terminates HTTPS for a host: Cloudflare on Casama Cloud, Caddy on a self-hosted server |
| **Registrant** | The person or company a bought domain legally belongs to |

## 6. What's not shipping

| Left out | Why | Revisit when |
|---|---|---|
| Premium names, names with non-English letters, endings with residency rules | Price surprises, look-alike attacks and eligibility checks | There is demand and a support process |
| Multi-year registration | One price path to get right first | After the first renewals have run cleanly |
| Moving a domain **in** from another registrar | A second purchase flow with week-long states. Connecting covers the need | People ask to have Casama run their DNS |
| Buying from a self-hosted server | Needs Casama Link to carry orders and payments | Link has a paid feature to sit beside |
| Custom domains for Casama Link servers | Possible with a per-hostname origin (§2.1), but a separate design | After Phase 2 has run in production |
| Fixed IP addresses for bare domains | Cloudflare Enterprise only (§2.1) | Hostnames or revenue justify the contract |
| Scripts, fonts and images from other sites; embeds | The closed policy is the anti-phishing and anti-leak rule (§7.2) | Decision 12 |
| Server-side code, visitor accounts, a database, payments on a site | Not a page any more | A separate "apps" plan |
| Visitor statistics | Needs edge analytics or a counter that survives caching | After launch |
| Email addresses on the domain | A second paid product | People ask; registrars' forwarding is the cheap start |
| A path on a domain pointing at a different site (`/blog`) | One site per host keeps the lookup and the origin rules simple | — |
| A bot buying a domain | Money and legal ownership need a person | — |

## 7. How it works

### 7.1 Three kinds of host reach the pages server

| Host | Example | Served by |
|---|---|---|
| The pages origin | `share.casama.page` (was `pages.casama.ai` until D-378) | Today's `createPagesApp`, unchanged (`/v/`, `/p/`, `/s/`, `/c/`, `/t/`) |
| A site address | `bakery.<sites zone>` | New `createSitesApp` |
| A connected or bought domain | `www.bakery.com`, `bakery.com` | New `createSitesApp` |

- **The sites zone is a new domain, never `casama.ai` and not `casama.link`** (decision 1). A
  phishing report or a browser block list entry lands on that domain. `casama.ai` holds the app's
  sign-in; `casama.link` holds people's servers. Neither should share a reputation with strangers'
  websites.
- **One dispatcher** (`apps/server/src/pages/hosts.ts`) sits in front of both apps on
  `PAGES_PORT`. It lowercases `Host`, drops the port, and sends the request to the sites app when
  the host is under `CASAMA_SITES_ZONE` or is a known row in `site_hosts`; everything else goes to
  today's pages app. With no zone set and no rows, behaviour is byte-for-byte what it is now, so
  self-hosted servers and Casama Link's `<label>-p` hosts are untouched.
- **Host lookups are cached** in the process for 60 seconds (hit and miss), at most 10,000
  entries. A change made through the API clears that host's entry in the same process. The API and
  the pages port are one process, so on one server a change shows at once; with several servers
  it shows within a minute.
- **The `Host` header is trusted because of where the port listens**, not because of the header:
  in production port 8790 is on loopback and only the tunnel reaches it; on a self-hosted server
  Caddy only obtains a certificate for hosts the API approves (§7.12).

Production routing (Casama Cloud):

```
visitor ── https://bakery.<zone> ───────┐
visitor ── https://www.bakery.com ──┐   │        Cloudflare edge (the sites zone)
                                    ▼   ▼
                     custom hostname      wildcard *.<zone>
                              └──────┬───────┘
                                     ▼
                      tunnel "casama-sites" (its own tunnel, one catch-all rule)
                                     ▼
                      cloudflared on the server → 127.0.0.1:8790 (Caddy) → api:8790
                                     ▼
                         dispatcher → sites app → page + page_assets
```

- **A second tunnel, `casama-sites`,** carries only site traffic. Its single ingress rule is a
  catch-all to `http://localhost:8790`. The existing `casama-prod` tunnel keeps its named
  hostnames and its `http_status:404` catch-all, so a made-up host name can never reach the API
  or Auth through the sites path.
- **DNS on the sites zone:** `*.<zone>` proxied CNAME to the tunnel (covers every site address
  and every per-domain target, §7.4), and `<zone>` itself for the zone's own page (§7.11). No
  record per site, so the zone's record limit never matters.
- **Custom hostnames** live on the sites zone with the tunnel's host as fallback origin (§2.1).

### 7.2 What a site host serves

Routes in `apps/server/src/pages/sites.ts`:

| Request | Answer |
|---|---|
| `GET /` | The page's HTML through `renderSite` (below) |
| `GET /some/path.ext` | The file `some/path.ext` from `page_assets` at the live `assets_version` |
| `GET /about` | First match of `about`, `about.html`, `about/index.html` |
| No match | `404.html` from the site's files with status 404 when it has one; otherwise a plain built-in page |
| `GET /robots.txt`, `/sitemap.xml` | The site's own file when it has one; otherwise generated: allow all and list the `.html` files when the site is indexable, `Disallow: /` when not |
| `GET /favicon.ico` | The site's file, else 204 |
| `POST /_casama/collect` | The existing `receive()` (D-279), same 64 KB and 20-an-hour limits |
| `GET`, `POST /_casama/report` | The existing report form and count (D-281) |
| Any path on a host that isn't the site's primary | `301` to the same path on the primary host |
| A host with no live site | A plain "This site isn't available" page, `404`, `noindex` |

Everything under `/_casama/` is reserved; a site file at that path is never served.
`readSiteFolder` already skips dot-files, and the publish tool refuses a folder with a top-level
`_casama` entry.

A site is served only while **all** of these hold, checked in the one lookup query:

- its host row is `active`;
- its page's `visibility` is `public` and not expired;
- its creation is not in the trash and not taken down;
- its workspace is not suspended.

So today's takedown (`visibility = 'private'`), the Library's delete and undo, and `suspendOrg`
take a site offline on every address with no new code path. Publishing a site sets
`visibility = 'public'` (and clears any expiry), which is why it is as risky as `pages.share`
with `public` and asks first.

`renderSite` (new, in `packages/domain/src/sites.ts`, next to `renderPage`) differs from
`renderPage` in exactly these ways:

| | `renderPage` (today) | `renderSite` |
|---|---|---|
| `noindex` meta and `X-Robots-Tag` | Always | Only when the site is not indexable |
| "Updated … UTC" line | Always | Never |
| Badge | None | "Made with Casama · Report" on site addresses; none on a custom domain (decision 7) |
| `<base>` | `/s/{token}/a/` | None: the site is at the root, relative links already work |
| Form script | Index only | Every `.html` file the site serves, when the page collects |
| Data block, theme variables | Yes | Yes, on the index |
| Content security policy | `PAGE_CSP_ASSETS` or stricter | `PAGE_CSP_ASSETS`, with `form-action 'self'` when the page collects |
| `Cache-Control` | `private, no-store` | HTML `public, max-age=60`; other files `public, max-age=300`; both with an `ETag` of page version and path |
| `Referrer-Policy` | `no-referrer` | `strict-origin-when-cross-origin` |
| `Strict-Transport-Security` | Not sent | `max-age=31536000` (no `includeSubDomains`, no `preload`: it's their domain) |

The content security policy stays closed in this plan: a site loads scripts, styles, images, fonts
and data from itself only. That is the rule that stops a tricked bot from publishing a page that
sends a visitor's form answers somewhere else, and it is what keeps a Casama-hosted site from
being a useful phishing kit. Ordinary links to other sites work. Embeds (a map, a video) are
decision 12.

Bots are told about sites in the `pages.publish` description (`PAGE_SITE_NOTE`, new): relative
links only, one `index.html`, a `404.html` if wanted, a `<title>` and meta description per page, a
favicon file, no external resources.

### 7.3 Custom hostnames

One interface, in `apps/server/src/sites/hostnames.ts`, shaped like `TunnelProvider`:

```ts
interface HostnameProvider {
  /** Registers the host at the edge. Safe to repeat: adopts one that already exists. */
  add(hostname: string): Promise<{ ref: string; ownership: { name: string; value: string } }>;
  /** null when it no longer exists. */
  get(ref: string): Promise<{ state: "pending" | "active" | "failed"; reason?: string } | null>;
  /** Asks the edge to look again now (resets its back-off). */
  recheck(ref: string): Promise<void>;
  /** Safe to repeat, and safe when already gone. */
  remove(ref: string): Promise<void>;
  /** How many the account holds, and how many it may, for the cost notice. */
  usage(): Promise<{ used: number; allocated: number } | null>;
}
```

- **`CloudflareHostnames`:** Cloudflare for SaaS on the sites zone (§2.1), with plain `fetch`.
  The envelope and error handling are shared with `CloudflareTunnels` by moving its private
  `call` into `apps/server/src/cloudflare.ts`. `add` posts `{ hostname, ssl: { method: "http",
  type: "dv" } }`, then reads the hostname again when the answer has no ownership record yet.
  `active` means the hostname's `status` **and** its `ssl.status` are both `active`. `recheck` is
  a `PATCH` that sends back the `ssl` settings it just read (a bare PATCH can reset them).
  `usage` is `GET …/custom_hostnames/quota`.
- **`OwnEdgeHostnames`:** for a self-hosted server whose Caddy answers on 80 and 443 (§7.12).
  `add` makes the ownership record itself (`_casama.<host>`); `get` is `active` once
  `https://<host>/_casama/probe` answers with the server's instance id.
- Reasons the edge reports are mapped to a short list the app can explain: `not_pointed`,
  `caa_blocks`, `held_elsewhere` (the person's own Cloudflare account has a zone hold), `timed_out`,
  `refused`.
- Tests use `fake-cloudflare.ts`, extended with custom hostnames whose state the test moves.

### 7.4 Proving a domain is theirs, and not letting anyone take it later

Cloudflare activates any host whose CNAME points into our zone, whichever workspace asked for it
(§2.1). So the edge saying "active" is not proof of anything, and the classic attack on site hosts
applies: someone removes a domain from the product but leaves the DNS record, and a stranger
claims the host. Casama therefore keeps its own proof, and the pages server only serves a host
whose row has it.

Every connected or bought domain gets **its own target**, `d-<16 random letters and
digits>.<sites zone>`, when its row is made. It is never reused. The wildcard record makes it
resolve; nothing is created for it.

A host is **proved** when either holds, checked from our side with DNS-over-HTTPS against two
public resolvers that must agree:

| Proof | Record | Used for |
|---|---|---|
| A | `CNAME <host>` ends at **this domain's own target** | Subdomains such as `www` |
| B | The ownership `TXT` record the edge returned for **this registration** (`_cf-custom-hostname.<host>` on Cloudflare, `_casama.<host>` on a self-hosted server) | The bare domain (its CNAME is flattened away), and a host proxied through the person's own Cloudflare account, where the CNAME can't be seen |

A leftover CNAME names a target that belonged to the removed row, and a leftover TXT holds the
value of a registration that no longer exists, so neither proves a new claim. (That a deleted and
re-added hostname gets a new ownership value is checked in the Phase 2 live check; if it doesn't,
proof B becomes our own `_casama.<host>` record with a code per row.)

The order of events for one host:

1. **Connect.** The row is made (`pending_dns`) and the host is registered at the edge at once,
   because the ownership record comes from the edge. The screen shows the records to add.
2. **Proof.** Upkeep looks every minute for the first hour, then every hour. **Check Again**
   looks now and asks the edge to look now.
3. **Certificate.** Proved → `pending_cert` until the edge reports active.
4. **Live.** `active`. Only now does the host match in the pages server's lookup.

Rules around it:

- **A host belongs to one workspace at a time** (`site_hosts.hostname` is unique). An unproved
  claim never blocks the real owner: after one hour another workspace may claim the host, which
  removes the unproved row and its edge registration and tells its workspace. A proved host can
  only be moved by proving it again: the new workspace is shown a record
  `TXT _casama-claim.<host>` with its own code, and on proof the old row is removed.
- **Unproved claims are capped and expire.** At most 10 unproved hosts a workspace, three claims
  a day per host, removed after 7 days. Cloudflare bills pending hostnames (§2.1), so this is
  also the cost guard.
- **Proof is checked every day after that.** When it has been gone for 7 days in a row (the
  record was removed or points elsewhere) the host goes to `disconnected`, is removed at the edge
  and the workspace is told. Cloudflare's own guidance is to delete a hostname as soon as the
  customer leaves (§2.1). A domain bought through Casama is checked the same way, since its owner
  can edit its DNS.

Host states (`site_hosts.status`):

```
pending_dns ──proved──▶ pending_cert ──edge active──▶ active
     │                       │                          │
     └─7 days──▶ failed      └─72 hours──▶ failed       ├─proof gone 7 days──▶ disconnected
                                                        ├─plan no longer covers it──▶ paused
                                                        └─admin or abuse──▶ suspended
```

`failed` and `disconnected` keep their row and their records, so **Check Again** puts the host
back at `pending_dns` (registering it at the edge again when needed).

### 7.5 The bare domain and `www`

- Entering `bakery.com` or `www.bakery.com` makes one domain with two hosts. Entering
  `shop.bakery.com` makes one domain with one host. Which is which comes from the Public Suffix
  List (`tldts`, a new dependency in `packages/domain`), so `bakery.co.uk` is understood as a
  bare domain.
- One host is **primary**; every other host of the site, the site address included, answers 301
  to it.
- **`www` always works:** one CNAME record, at every DNS company.
- **The bare domain depends on their DNS company,** because Cloudflare gives no fixed IP
  addresses below Enterprise (§2.1):

| Their DNS | What they add | Status |
|---|---|---|
| Cloudflare | A CNAME at the root (Cloudflare flattens it) to the target, set to **DNS only**, plus the ownership TXT | Documented by Cloudflare |
| A company with ALIAS or ANAME records | An ALIAS to the target, plus the ownership TXT | **Not documented by Cloudflare. The Phase 2 live check decides whether this row ships** |
| Anything else | Nothing for the bare domain. They turn on **forwarding** from `bakery.com` to `www.bakery.com` at their registrar | Always works; the screen explains it in plain words |

- So for a connected domain the default primary is `www`, and the bare host is offered as "Also
  use bakery.com" with the right instructions for the DNS company we detect from the domain's
  nameservers.
- For a bought domain we run the DNS, so both hosts are set up for the person. Whether the bare
  domain is primary (ANAME at the registrar's DNS) or forwards to `www` follows the same live
  check (§7.7).

### 7.6 The registrar adapter

One interface in `apps/server/src/sites/registrar.ts`; the first implementation is
`NameComRegistrar` (`namecom.ts`, decision 2), the test one is `FakeRegistrar`
(`apps/server/test/fake-registrar.ts`, which serves the same HTTP shapes so the real adapter is
what the tests run).

```ts
interface Registrar {
  readonly id: string;
  /** Up to 50 names in one call. Costs are what we pay, in USD. */
  check(names: string[]): Promise<Array<{
    name: string; available: boolean; premium: boolean;
    registerCostUsd: number | null; renewCostUsd: number | null }>>;
  register(o: { name: string; contact: Contact; maxCostUsd: number; reference: string }):
    Promise<{ expiresAt: Date }>;
  renew(o: { name: string; maxCostUsd: number; reference: string }): Promise<{ expiresAt: Date }>;
  get(name: string): Promise<{
    expiresAt: Date; locked: boolean; autoRenew: boolean; privacy: boolean;
    nameservers: string[]; contactVerified: boolean } | null>;
  setAutoRenew(name: string, on: boolean): Promise<void>;
  setLock(name: string, locked: boolean): Promise<void>;
  transferCode(name: string): Promise<string>;
  setContact(name: string, contact: Contact): Promise<void>;
  resendVerification(name: string): Promise<void>;
  records(name: string): Promise<DnsRecord[]>;
  putRecord(name: string, r: DnsRecord): Promise<DnsRecord>;
  deleteRecord(name: string, id: string): Promise<void>;
  setForwarding(name: string, to: string | null): Promise<void>;
  /** null when the account pays by card and has no balance to watch. */
  balanceUsd(): Promise<number | null>;
  verifyWebhook(req: WebhookRequest): Promise<RegistrarEvent>;
}
```

- **All domains sit in Casama's one reseller account,** each with the person's own contact as
  registrant. No sub-accounts (Name.com gates those behind approval, §2.2).
- **A budget on calls.** Name.com allows 20 requests a second and 3,000 an hour for the whole
  account (§2.2). The adapter keeps a counter: search may use at most 2,400 an hour, so
  registrations and renewals always have room. Search results are cached for 60 seconds.
- **Webhooks** (`POST /hooks/registrar/{id}`, signature checked, stored once, then the domain is
  read again with `get`, the same rule as billing): contact verified, expiry, lock changes,
  transfer out, domain removed, low balance. A daily reconcile reads every domain with `get`, so a
  missed webhook is corrected within a day.

### 7.7 Buying a domain

**Search.** The person types a name or a few words. The server builds candidates (the exact name
on each ending on sale, then simple variants: with a hyphen, `get…`, `…hq`, `try…`), checks them
in one call, and returns for each: available or taken, the price for the first year and the price
it renews at. Premium names and endings not on the list show as "Not available here".

**The price** is one pure function, `domainPriceUsd(costUsd, settings)` in
`packages/domain/src/sites.ts`, used by search, checkout and renewal notices (§8).

**The order** (`domain_orders.status`):

```
quote ─▶ checkout ─▶ paid ─▶ registering ─▶ registered ─▶ done
            │          │          │
            │          │          └─ name gone, cost rose, registrar refused ─▶ refunding ─▶ refunded
            │          └─ registrar unreachable: retry for 24 hours, then ─▶ refunding
            └─ not paid within 24 hours ─▶ abandoned               refund failed ─▶ needs_attention
```

1. **Checkout** (`POST /v1/orgs/{id}/domains/checkout`). Checks, in order: the feature is on and
   the plan allows it; the name is on sale and not premium; the workspace is inside its purchase
   caps (§7.11); a contact is saved and complete; the terms box was ticked (the time and the
   terms version are stored on the order); no other live checkout holds the name. It checks the
   name again at the registrar, stores the cost and the price on the order, and opens a payment
   for exactly that price with the order id in its metadata (§2.4): a Pay What You Want checkout
   with `amount` set to the price, or, when **Renew automatically** is on and the workspace has
   no domain mandate yet, an on-demand subscription checkout that charges the price now and keeps
   the mandate for renewals. A workspace that already has a mandate confirms in the app and is
   charged on it directly (`POST /subscriptions/{id}/charge`), with no browser step.
2. **Paid.** The existing billing webhook path verifies, stores the event once, re-reads the
   payment, finds the order by the id in its metadata, checks the amount paid equals the order's
   price, and starts the `domainRegister` workflow **with the order id as the workflow id**.
3. **Registering.** The workflow checks the name once more. Not available, premium, or costing
   more than the stored cost plus $1: refund. Otherwise it registers for one year with the
   order id as the registrar's reference, the person's contact as registrant, privacy on, lock on,
   and the registrar's own auto-renew **off**.
4. **Registered.** It writes the `domains` row (`registered`, `expires_at`, `transfer_after`),
   sets the DNS records, makes both hosts and attaches the site chosen at checkout:
   - `www` → `CNAME` to the domain's target;
   - the bare domain → `ANAME` to the target plus the ownership `TXT`, or forwarding to `www`
     (§7.5, by the Phase 2 result);
   - the hosts then go through the same proof and certificate steps as a connected domain.
5. **Done.** Notices go out (§7.17). The domain's screen shows the registrant-email step until
   the registrar reports the contact verified.

Rules:

- **One year, renewing yearly.** No other terms.
- **Sales are final once registered.** The checkout says so. A domain that couldn't be
  registered is always refunded in full. (Registries do allow deleting a new name within five
  days, but registrars limit and charge for it, §2.3; it stays a support-only tool.)
- **The refund is part of the workflow,** not a person's job. When the refund call itself fails,
  the order goes to `needs_attention`, instance owners are told, and **Admin** → **Domains**
  shows it with **Retry**.
- **Contact details** are checked before checkout: every required field, a two-letter country, a
  phone number in international form, and an email address. The default email is the account's
  confirmed address. Saving different details later updates every domain of the workspace at the
  registrar (which can start the email confirmation again, §2.3).

### 7.8 Keeping a domain: renewal, expiry, after expiry

`domains.status` for a bought domain:

```
active ──expiry date passes unrenewed──▶ expired ──25 days──▶ lapsed ──▶ gone
   ▲                                        │                   │
   └──────── renewed (charge or by hand) ◀──┘                   └─ restore, by support only
active ──transfer completes──▶ moved_out          any state ──admin──▶ suspended
```

`domains-upkeep` runs hourly in the worker under an advisory lock and does one thing per domain
per step, each with a dedupe key (`<domain>:<expiry date>:<step>`), so a late or repeated run
never charges or emails twice. For a domain expiring on day **E**:

| Day | What happens |
|---|---|
| E − 30 | Notice 1: "bakery.com renews on E for $X plus tax" (that day's price), and whether it will be charged or needs **Renew Now** |
| E − 14 | **Renew automatically** on: a charge on the workspace's domain mandate (§2.4), for every domain due that day in one charge each. Paid → renew one year at the registrar with the charge id as reference → receipt. Failed → an in-app notice that says so and an email with **Renew Now**, and the charge is tried again on E − 10, E − 7 and E − 3 |
| E − 7 | Notice 2 if still unrenewed |
| E − 1 | Last notice |
| E | `expired`. The registrar stops the domain resolving; its hosts lose their proof and say why |
| E + 3 | Notice 3: it has expired, and can still be renewed at the normal price until E + 25 |
| E + 20 | Final notice |
| E + 25 | `lapsed`. Name.com removes it from the API (§2.2). It may still be restorable through the registrar at a restore fee, by Casama's support by hand, for as long as the registry allows; the notice says this is not guaranteed and gives the fee |
| After the registry's redemption time | `gone`. The row and its history are kept; hosts are removed |

- Renewing early or late always adds one year to the current expiry date, so charging at
  E − 14 loses the person nothing.
- **Renew Now** is the same checkout as a purchase, with an order of kind `renew`.
- The renewal workflow has the same refund rule as registration: charged but the registrar
  refused → refund and notice.
- With **Renew automatically** off, every notice is still sent and nothing is charged.
- The registrar also sends its own required notices to the registrant (§2.2, §2.3). Ours carry
  the price and the button; theirs satisfy the policy.

### 7.9 DNS records

For bought domains, on the registrar's DNS (free with the domain).

- **Read and written live** through the adapter; nothing is copied into our database except which
  record ids Casama manages for the site.
- **Types:** A, AAAA, CNAME, MX, TXT, SRV. That covers pointing a subdomain elsewhere, any mail
  provider (MX, SPF, DKIM, DMARC), and site-verification records. Name.com's DNS has no CAA
  record type (§2.2), which also means a person can't block our certificates by accident.
- **Managed records are shown and locked** ("Used by your Casama site"). Disconnecting the site
  from the domain is what removes them.
- **Checks before saving** (pure, in `packages/domain`): a name inside this domain; no CNAME
  beside other records at the same name; valid addresses and host names; TXT up to 2,048
  characters; a TTL of 300 seconds or more; at most 100 records.
- **A subdomain can show another site:** adding `shop.bakery.com` under a bought domain makes the
  records by itself, since we run the DNS.
- Changing nameservers away from the registrar's is not offered. A person who wants their own
  DNS can move the domain out (§7.10) and connect it.

### 7.10 Leaving: moving a domain out, deleting a workspace

**Move to Another Registrar.**

- Before `transfer_after` (the lock after registration, §2.3) the screen gives the date.
- After it: the workspace **owner** types the domain's name to confirm. The server unlocks the
  domain and returns the transfer code once. The code is never stored. The owner gets an email
  saying a code was issued, and every admin gets a notice.
- **Lock Again** relocks. Upkeep relocks by itself after 14 days when no transfer started.
- When the registrar reports the transfer finished, the domain becomes `moved_out`. If its DNS
  still proves its hosts, it turns into a `connected` domain and the site stays up; otherwise
  its hosts are removed.
- Nothing about leaving is gated on plan, payment state or support.

**Deleting a workspace or an account** that holds bought domains.

- The delete screen lists them and says what happens: the domains stay registered to their
  registrant until they expire, they stop renewing, and their sites go offline. The person types
  to confirm, as today.
- `domains.org_id` is set null by the delete; the row keeps the name, expiry, and the
  registrant's email (sealed). Renewal is turned off. The registrant gets one email: the domain is
  theirs until its expiry date, and how to get the transfer code from support.
- Hosts are deleted by cascade and removed at the edge through `provider_cleanups`.
- Connected domains are simply removed.

**Suspending a workspace** stops its sites (§7.2) and leaves its domains registered. Suspending a
domain for abuse (§7.11) also turns on the registrar's lock and removes the site's records.

### 7.11 Abuse

A site builder with free addresses and cheap domains is what phishing crews look for. The guards,
in the order an attacker meets them:

| Guard | Detail |
|---|---|
| Who can publish | A confirmed email address. On Free, one live site (decision 3) |
| Address names | 3 to 40 characters, letters, digits and hyphens (the existing `SLUG_PATTERN`). A reserved list (`www`, `mail`, `api`, `admin`, `login`, `secure`, `support`, `billing`, `status`, `casama` and names starting `d-`), a list of brands that get impersonated (banks, payment companies, the large tech sign-in pages), and one change of name a day. ASCII only: no look-alike letters |
| What a site can do | The closed content security policy of §7.2: a form on a site can only send to Casama, never to an attacker's server |
| Search engines | Off until the person turns it on; on Free it stays off (decision 6). Spam sites gain nothing |
| Reports | Every site address shows **Report**. `/_casama/report` exists on every site, custom domains too. The zone's own page (below) takes a report for any address. Three different reporters hide the site at once (D-281), on all its hosts |
| Takedown | **Admin** → **Reports** (existing) and **Admin** → **Domains** → **Suspend**: hosts go to `suspended`, the site stops, the edge hostname is removed. A suspended workspace's sites stop in the same lookup |
| Buying | Paid plans only (decision 4). At most 3 domains in a workspace's first 30 days and 10 a month after, more through support. Stolen-card purchases cost us the wholesale price plus a chargeback fee, so the first purchase on a workspace younger than 24 hours waits for an instance owner's approval |
| Complaints to the registrar | Arrive at an `abuse@` address we give the registrar. The runbook (`docs/DOMAINS-RUNBOOK.md`) says: look, suspend within 24 hours when it's real, answer the registrar |

**The zone's own page.** The bare sites zone serves a small static page, built like
`link-site/` (D-317) in a new `sites-site/` folder: what these addresses are, that Casama doesn't
write the sites, and a report form that posts to `POST /v1/site-reports`. It also serves
`/.well-known/security.txt`. It is deployed with its own script after Oliver's yes, like
`scripts/deploy-link-web.sh`.

**The Public Suffix List.** The zone is submitted to the list's private section once site
addresses are live (§2.5), so browsers treat each site as its own site for cookies and block
lists treat one bad site as one bad site.

### 7.12 Self-hosted servers

| Server | Site addresses | Connect a domain | Buy a domain |
|---|---|---|---|
| Own domain, Caddy answers on 80 and 443 | Optional: set `CASAMA_SITES_ZONE` to a domain whose wildcard record points at the server | Yes, with `CASAMA_SITES_OWN_EDGE=true` | No (decision 10) |
| Behind someone else's proxy (`CASAMA_SITE=:80`) | Same, the proxy handles certificates | Yes: the docs say to send the host to port 8790 with its `Host` header intact; we verify with the probe only | No |
| Casama Link (a tunnel on casama.link) | No | Not in this plan (§6) | No |

With `CASAMA_SITES_OWN_EDGE=true` the Caddyfile gains a global `on_demand_tls { ask … }` block
pointing at the API's `/internal/tls-ask`, and a catch-all `https://` site with
`tls { on_demand }` that forwards to `api:8790`. Caddy asks before every new certificate, and the
API says yes only for a host that is a verified `site_hosts` row or a label under the server's
zone, so nobody can make the server request certificates for arbitrary names (§2.6). Proof B
(the TXT record) is always required on a self-hosted server, since any stranger can point a
domain at a public IP address. The records shown are an `A`/`AAAA` record to the server's address
or a `CNAME` to its pages host.

The Helm chart gets the same switch and a note that the ingress must pass unknown hosts to the
pages service.

### 7.13 Plans and limits

Two new limit keys, added by merge (§7.14) and enforced with `enforceLimit`. Self-hosted servers
have no value set, which means no limit, as with bots and computers. The numbers are decision 3.

| | Free | Plus | Pro | Max |
|---|---|---|---|---|
| `max_sites`: live sites | 1 | 3 | 10 | 50 |
| `max_custom_domains`: connected or bought domains in use | 0 | 1 | 5 | 20 |
| Search engines may list the site | No | Yes | Yes | Yes |
| The badge can be turned off | No | On a custom domain | On a custom domain | On a custom domain |

A domain counts once, however many of its hosts are in use. A bought domain that isn't pointed at
a site still counts, so the limit can't be dodged by parking.

**When a plan ends or drops** and the workspace is over a limit:

- Nothing changes for 14 days. A notice on day 0 and day 10 says what will happen.
- Then the newest custom domains over the limit go to `paused`: visitors are sent (302, not
  cached) to the site's own address, which keeps working. Nothing is deleted. Upgrading puts them
  back within the hour.
- Sites over `max_sites` keep serving but can't be changed until the count is back under.
- **A bought domain is never taken away for a plan change.** It stays registered, its DNS can be
  edited, it can be renewed and moved out. Only its link to a Casama site pauses.

### 7.14 Data model

One migration, `supabase/migrations/<next>_sites_domains.sql`. Every table has row-level security
on, a pgTAP test in `supabase/tests/sites_domains_rls.test.sql`, and
`select public.allow_worker('public.<table>')`.

| Table | Holds | Key columns |
|---|---|---|
| `sites` | One row per published page | `page_id` (primary key, → `pages`, cascade), `org_id`, `indexable` (default false), `badge` (default true), `created_by` |
| `site_hosts` | Every host name a site answers on | `hostname` (unique, lowercase, ASCII), `kind` (`address` or `custom`), `page_id` (→ `sites`, set null), `domain_id` (→ `domains`, cascade; null for an address), `is_primary`, `status` (§7.4), `status_reason`, `provider_ref`, `verified_at`, `last_checked_at`, `proof_missing_since` |
| `site_labels_retired` | Names that may not be taken again yet | `label`, `retired_at`, `org_id` |
| `domains` | A connected or bought domain | `name` (unique), `kind` (`connected` or `registered`), `org_id` (**set null** on workspace delete, §7.10), `target` (unique), `verify_code`, and for bought ones: `registrar`, `status` (§7.8), `expires_at`, `auto_renew`, `locked`, `privacy`, `transfer_after`, `registrant_verified_at`, `renew_price_usd`, `mandate_ref`, `purchased_by`, `released_at` |
| `domain_contacts` | The registrant's details, one per workspace | `org_id` (unique), `data` (sealed JSON: name, organisation, address, country, phone, email) |
| `domain_orders` | Every payment for a domain | `kind` (`register`, `renew`, `restore`), `name`, `years`, `price_usd`, `cost_usd`, `status` (§7.7), `payment_ref` (unique), `checkout_ref`, `failure`, `refunded_at`, `created_by` |
| `domain_events` | The domain's history, shown on its screen | `domain_id`, `kind`, `detail`, `created_at` |
| `provider_cleanups` | Things to remove at a provider after their row is gone | `kind` (`hostname`), `ref`, `hostname`, `attempts`, `last_error`, `done_at` |

Rules the migration encodes, each of which a test checks:

- **Clients only read.** Members of the workspace can `select` `sites`, `site_hosts`, `domains`
  and `domain_events`; `domain_contacts` and `domain_orders` are for admins. No table has an
  insert, update or delete policy for `authenticated`: every write goes through the API. (A
  column on `pages` would have been writable through the existing `pages_update` policy, which is
  why sites get their own table.)
- **One primary host per site:** a partial unique index on `site_hosts (page_id) where is_primary`.
- **One live checkout per name:** a partial unique index on
  `domain_orders (name) where status in ('checkout', 'paid', 'registering')`.
- **A deleted host is always cleaned up at the edge.** An `after delete` trigger on `site_hosts`
  writes a `provider_cleanups` row when `provider_ref` is set. Cascades (a deleted workspace, a
  deleted domain) therefore can't leave a billed, serving hostname behind. Upkeep works the queue.
- **A retired address stays retired.** Deleting an `address` host writes its label to
  `site_labels_retired`; the name can be taken again after 90 days, and by its old workspace at
  once.
- **Plan limits are merged, never replaced:**
  `update public.plans set limits = limits || '{"max_sites": …, "max_custom_domains": …}'`, then
  every entitlement is recomputed with `public.entitlement_limits(...)`, as
  `20270201100301_restore_plan_limits.sql` had to do after an earlier migration replaced the
  object.
- `hostname`, `name` and `label` have `check` constraints (lowercase, length, pattern), so a bug
  in the API can't store a host the lookup would never match.

No existing table changes shape, and no value is added to an enum a shipped app decodes
(`CreationKind`, the three `visibility` values): installed apps parse those strictly and a new
value breaks the whole response.

### 7.15 API

Contracts first (`packages/contracts/src/sites.ts`, `routes/sites.ts`, `routes/domains.ts`), then
`pnpm gen`. Every route below answers 401 without a session unless marked.

| Route | Who | What it does |
|---|---|---|
| `GET /v1/config` (existing) | Anyone | Gains an optional `sites` object: `{ zone, custom_domains, buy_domains, tlds }`. Old apps ignore it |
| `GET /v1/orgs/{id}/sites` | Member | Published sites with their hosts and states |
| `GET /v1/sites/address?label=` | Member | Whether a name is free, and why not when it isn't |
| `PUT /v1/pages/{id}/site` | Can manage the page | Publish: `{ label?, indexable? }`. Makes the page public, reserves the address |
| `DELETE /v1/pages/{id}/site` | Can manage the page | Unpublish: the page goes private, hosts are kept but serve nothing |
| `GET /v1/orgs/{id}/domains` | Member | Connected and bought domains |
| `POST /v1/orgs/{id}/domains` | Admin | Connect: `{ name, page_id? }`. Answers the records to add |
| `GET /v1/domains/{id}` | Member | States, the records to add (and what we see in DNS now), history |
| `POST /v1/domains/{id}/check` | Admin | Check DNS now (at most once every 10 seconds) |
| `PATCH /v1/domains/{id}` | Admin | `{ page_id?, primary_host?, auto_renew? }` |
| `DELETE /v1/domains/{id}` | Admin | Disconnect. A bought domain stays registered; only its site link goes |
| `GET /v1/domains/search?org_id=&q=` | Admin | Names, availability and prices (§7.7). 30 a minute per person |
| `GET`, `PUT /v1/orgs/{id}/domain-contact` | Admin | The registrant's details |
| `POST /v1/orgs/{id}/domains/checkout` | Admin | `{ name, page_id?, accept_terms: true }` → a checkout address |
| `POST /v1/domains/{id}/renew` | Admin | A checkout for one more year, or a restore |
| `GET`, `POST`, `PATCH`, `DELETE /v1/domains/{id}/records` | Admin | DNS records of a bought domain (§7.9) |
| `POST /v1/domains/{id}/transfer-out` | Owner | Unlocks and returns the transfer code once (§7.10) |
| `POST /v1/domains/{id}/verify-email` | Admin | Sends the registrant verification email again |
| `GET /v1/admin/domains`, `POST /v1/admin/domains/{id}/suspend`, `…/unsuspend`, `…/retry` | Instance owner | All domains, the registrar balance, stuck orders |
| `POST /hooks/billing/dodo` (existing) | Dodo | Also handles domain payments, refunds and renewal charges |
| `POST /v1/site-reports` | **Signed out** | A report by address from the zone's own page; rate limited by address. Goes on the signed-out list in `packages/contracts/test/events.test.ts` with its reason |
| `GET /internal/tls-ask?domain=` | Caddy only | 200 when the host is a verified row; internal network, never routed publicly (§7.12) |

Errors use the existing shapes: `402 plan_limit` from `enforceLimit`, `409` with a code the app
can show (`address_taken`, `domain_in_use`, `checkout_in_progress`, `transfer_locked`).

### 7.16 In the app

All native Flutter, no web views. New folder `client/lib/features/sites/`. Text in
`client/lib/l10n/app_en.arb`. Any Flutter build needs Oliver's yes first.

| Place | What's there |
|---|---|
| **Library** → a page, site or game | **Publish to the Web**: pick the address name (checked as typed), a line saying anyone will be able to open it, **Publish**. Once live: the address with Copy and Open, **Use Your Own Domain**, **Let search engines find it**, **Unpublish** |
| **Settings** → **Domains** (new; admins) | The workspace's domains: name, the site it shows, a state chip (**Live**, **Waiting for DNS**, **Getting its certificate**, **Needs attention**, **Expires in 12 days**), and **Find a Domain** / **Connect a Domain You Own** |
| **Connect a Domain You Own** | Step 1: type the domain. Step 2: the records to add, each with Copy, written for the DNS company we detect from the domain's nameservers when we know it; "what we see now" beside each; **Check Again**; it also checks by itself. Step 3: **Live** |
| **Find a Domain** | A search box, results with price per year and renewal price, taken names greyed, **Buy**. First purchase: the registrant form (prefilled from the profile), the terms checkbox, then checkout in the browser |
| A domain's screen | Hosts and states, the site picker, **Renews on** with the price and the **Renew automatically** switch, **DNS Records**, **Contact Details**, **Move to Another Registrar**, history |
| Chat | The publish step's card shows the address once a site is live. A bot's domain suggestions are a normal reply with a link that opens **Find a Domain** with the name filled in |
| **Admin** (instance owner) | Domains: counts, the registrar balance, orders that need attention, **Suspend** |

Where **Buy** appears follows `purchaseChannels` (§2.4, decision 5). Where it doesn't, the screen
still lists, connects and manages domains and says a domain can be bought on the web.

Shipped apps that don't know about sites keep working: they see a public page with its link, as
today.

### 7.17 Notices

In-app notifications use new free-text kinds (`domain_live`, `domain_needs_dns`,
`domain_disconnected`, `domain_renewal`, `domain_expired`, `domain_registered`,
`domain_order_failed`, `domain_verify_email`); old apps show them as plain notifications. Emails
go through the account email outbox with a dedupe key per domain and step, so a retry never sends
twice:

| When | In app | Email |
|---|---|---|
| A host goes live | Yes | No |
| DNS still not found after 1 hour, 1 day, 6 days | Yes | At 1 day |
| A host is disconnected or paused | Yes | Yes |
| A domain is registered | Yes | Yes, with what was bought and that the registrant must confirm their email |
| A paid order couldn't be completed and was refunded | Yes | Yes |
| Renewal notices and results (§7.8) | Yes | Yes, always: these are required notices and ignore email preferences |
| The registrant hasn't confirmed their email (day 3, 7, 12) | Yes | Yes |
| The transfer code was shown | Yes | Yes, to the workspace owner |

### 7.18 Bot tools

| Tool | Risk | What it does |
|---|---|---|
| `sites.publish` | High, category `publish`: asks first, like `pages.share` public | Puts one of the bot's own pages on a site address; answers the address |
| `sites.status` | Low, read only | The bot's sites, their addresses and host states |
| `domains.search` | Low, read only | Names and prices; the reply links to **Find a Domain** |
| `domains.connect` | High, category `publish` | Points a domain the workspace **already has** at one of the bot's pages |

No tool buys, renews, transfers or edits DNS. Money and ownership stay with a person.

### 7.19 Analytics

New events in `packages/contracts/analytics/catalog.json`: `site_published`, `site_unpublished`,
`domain_search`, `domain_connect_started`, `domain_connected`, `domain_connect_failed`,
`domain_checkout_started`, `domain_purchased`, `domain_order_failed`, `domain_renewed`,
`domain_renewal_failed`, `domain_expired`, `domain_transfer_out`. Properties are the TLD, the
kind and the plan. A domain name or address is never a property.

### 7.20 Settings and secrets

| Setting | Meaning |
|---|---|
| `CASAMA_SITES_ZONE` | The sites zone. Unset: no site addresses |
| `CASAMA_SITES_CF_ZONE_ID`, `CASAMA_SITES_CF_API_TOKEN`, `CASAMA_SITES_CF_API_URL` | Custom hostnames on that zone. The token is scoped to this one zone (§2.1). Unset: no connected domains on this cloud |
| `CASAMA_SITES_OWN_EDGE` | `true` on a self-hosted server whose Caddy issues certificates on demand (§7.12) |
| `CASAMA_DOMAINS_REGISTRAR` | `none` (default) or the registrar's id |
| The registrar's credentials and API address | Named after the registrar chosen in decision 2 |
| `CASAMA_DOMAINS_TLDS` | The endings on sale (§2.3) |
| `billing_settings.domain_markup`, `domain_fee_usd` | The price formula (§8), changed from **Admin** like the credit markup |

Every key and token made for this goes into Vaultwarden under "Keys & Signing" in the same task,
with its scope and how to revoke it. Compose passes the new settings through
(`infra/compose/docker-compose.yml`), and `.env.example` and the self-hosting docs list them.

## 8. Costs and prices

Rows added to `docs/COSTS.md` in Phase 0, with the unit price, who pays and how it's metered.

| Item | Cost | Who pays | Metered |
|---|---|---|---|
| The sites zone | about $10–30 a year; bought for 3 years (§2.5) | Casama | Fixed |
| Custom hostnames | 100 free, then $0.10 per hostname a month | Casama, covered by plans and domain prices | `usage()` hourly; notice to owners at 80 and 95 included |
| Second tunnel | $0 (inside the 1,000 included) | Casama | — |
| Domains | Wholesale, read live (.com about $11.2–12.5 a year) | The person, through the price | Every order stores `cost_usd` |
| Dodo on domain payments | 4% + $0.40, +1.5% international, +0.5% on mandate charges; refund $1, chargeback $30 | Covered by the price | Per order |
| DNS-over-HTTPS checks | $0 (public resolvers) | — | — |

**The price** (`domainPriceUsd`, settings in `billing_settings`, changeable in **Admin**):

```
price = round_up_to_.99( cost × domain_markup + domain_fee_usd )
defaults: domain_markup = 1.25, domain_fee_usd = 1.50
```

| | .com at $12.03 cost |
|---|---|
| Price | **$16.99** a year (Shopify charges about $16) |
| Dodo, international mandate charge | about $1.50 |
| Two hostnames past the free 100 | $2.40 a year |
| Left over | about **$1.06** worst case, **$3.46** inside the free 100 |

The renewal price is computed the same way from that day's cost and shown in the 30-day notice.
A plan's connected domains cost Casama only hostname fees (at most $2.40 a year each), covered by
the plan price.

## 9. Phases

Built on a branch in its own worktree (as Casama Link was), merged at the end of each phase after
its tests pass. Each phase is useful by itself and leaves production working: every new setting
is off until Oliver turns it on. Commits use the private-index recipe; nothing is deployed, built
for a store or published without Oliver's yes for that one step.

**Phase 0: decisions and accounts.** Nothing is coded. Oliver answers §13 and does §14: buys the
sites zone and adds it to Cloudflare, opens the registrar's reseller account, and confirms with
Dodo that domains may be sold (§2.4). In the same phase, with no production change: the scoped
Cloudflare token and the registrar's test credentials go into Vaultwarden, and `docs/COSTS.md`
gets its new rows (§8).
*Done when:* the zone is active on Cloudflare, Cloudflare for SaaS is switched on for it, the
registrar's test system answers a signed request, and Dodo has said yes in writing.

**Phase 1: a site has an address.** §7.1, §7.2, the `sites` and `site_hosts` tables (`address`
kind only), `PUT`/`DELETE /v1/pages/{id}/site`, the address check, `max_sites`, the
`sites.publish` and `sites.status` tools, **Publish to the Web** in the Library, reports on site
hosts, the zone's own page, the docs page, the second tunnel and the wildcard record.
*Done when:* on the local stack a bot builds a three-page site with a contact form; **Publish to
the Web** puts it on `name.<zone>` over HTTPS through the real tunnel; `/about` and the form work;
three reports take it down on its address; unpublish and the Library's delete stop it within a
minute; every existing page link still works; `sites-live-check.ts` passes.

**Phase 2: connect a domain you own.** §7.3 to §7.5, the `domains` table (`connected` kind),
`provider_cleanups`, the connect routes, `domains-upkeep` (proof, certificates, daily re-checks,
cleanup, the usage notice), `max_custom_domains` and the pause rule, **Settings** → **Domains**,
**Connect a Domain You Own**, the `domains.connect` tool, notices, self-hosted on-demand TLS
(§7.12).
*Done when:* a real test domain's `www` goes live on a site within five minutes of adding one
record; the bare domain is live on Cloudflare DNS and its result on an ALIAS provider is written
down; a second workspace can't take the host with the old record; removing the record
disconnects it after the wait (shortened in the test); deleting the workspace removes the
hostname at Cloudflare; a self-hosted stack serves a connected domain with a certificate Caddy
obtained only after the API said yes; `hostnames-live-check.ts` passes.

**Phase 3: buy a domain.** §7.6 and §7.7, `domain_contacts`, `domain_orders`, `domain_events`,
the registrar adapter and its fake, search, checkout, the registration workflow, refunds,
**Find a Domain**, the registrant form and terms, **Admin** → **Domains**, the balance notice,
`domains.search`, the runbook.
*Done when:* against the registrar's test system and Dodo's test mode a domain is searched, paid
for, registered, pointed at a site and live with no DNS step by the person; a name that
disappears between payment and registration is refunded by itself; a webhook sent three times
registers once; then, with Oliver's yes, one real domain is bought end to end.

**Phase 4: keep a domain.** §7.8 to §7.10: renewal notices and charges, expiry, grace and
redemption, **DNS Records**, **Contact Details**, registrant email confirmation, **Move to Another
Registrar**, workspace and account deletion with domains, the daily reconcile with the registrar.
*Done when:* with the clock moved in tests, a domain walks from 31 days before expiry through a
successful automatic renewal, and another through failed charges, expiry, late renewal and
deletion, sending each notice once; on the registrar's test system a renewal adds exactly one
year, a record is added and removed, and a transfer code is issued after the lock date.

**Phase 5: the rest.** `casama` CLI commands (`casama sites`, `casama domains`), the TypeScript
and Dart SDK helpers, MCP tools in `@casama/mcp`, the agent-kit skill, `llms.txt`, the Public
Suffix List submission, a "what's new" entry, and whichever of §6 Oliver pulls in.
*Done when:* the docs build, the CLI lists and connects a domain against the local stack, and the
list has accepted or is reviewing the zone.

Phase 4 must be live before the first bought domain is nine months old, since that is when its
renewal notices start. In practice Phases 3 and 4 ship to production together (decision 13).

Relative size: Phase 0 small, Phase 1 medium, Phase 2 large, Phase 3 large, Phase 4 large and the
one with the most edge cases, Phase 5 small.

## 10. Tests and checks

No test calls a real provider. Three fakes carry the suites: `fake-cloudflare.ts` (extended with
custom hostnames), `fake-registrar.ts` (new) and the existing `fake-billing.ts` (extended with
changing-amount payments and renewal charges).

| Layer | File | What it must prove |
|---|---|---|
| Pure logic | `packages/domain/test/sites.test.ts` | Address rules and the reserved and brand lists; host normalising (case, trailing dot, port, `www`, `co.uk`, an IP address refused, a non-ASCII name refused); `renderSite` differences from §7.2; the form script in every HTML file; the generated `robots.txt` and `sitemap.xml`; the price formula and rounding; the renewal step for every day from 31 days before expiry to deletion; DNS record checks (CNAME beside other records, managed records protected) |
| Host routing | `apps/server/test/sites-serving.test.ts` | The pages origin still serves every existing route; a site address serves `/`, a file, `/about` → `about.html`, the site's `404.html`; `/_casama/collect` stores an answer; a second host 301s to the primary with the path kept; a private, trashed, taken-down or suspended-workspace site answers 404 on every host; an unknown host answers 404 and never reaches a pages route; a `/s/{token}` link does **not** work on a site host; the cache forgets a host when it changes |
| Publishing | `apps/server/test/sites.test.ts` | Publish makes the page public and reserves the address; taken, reserved and retired names are refused; the limit answers 402; unpublish stops serving and keeps the name; another workspace can't publish or read; a bot's `sites.publish` waits for approval |
| Connecting | `apps/server/test/domains-connect.test.ts` | Records returned for a bare domain, a `www` and a subdomain; proof A and proof B; a CNAME to **another** row's target is not proof; nothing is sent to the edge before proof; pending → active; 7-day and 72-hour failures; disconnect after 7 days without proof; a verified claim replaces an unverified one and tells its workspace; deleting a workspace queues the edge cleanup and upkeep completes it; cleanup retries after an edge error |
| Buying | `apps/server/test/domains-buy.test.ts` | Search prices follow the formula; premium and off-list names can't be bought; checkout needs the contact and the terms; two checkouts for one name → the second gets 409; a paid webhook delivered three times registers once; the name gone at registration → refund and notice; registrar error → retry, then refund; refund failure → `needs_attention` and an admin notice; after registration the records exist, both hosts go live, lock and privacy are on, the registrar's own auto-renew is off |
| Keeping | `apps/server/test/domains-lifecycle.test.ts` | Each notice is sent once on its day; a renewal charge that succeeds renews one year exactly once; a failed charge retries on the set days; expiry, grace and redemption states; **Renew automatically** off sends notices and charges nothing; DNS records: add, change, delete, managed ones refused; transfer code refused before `transfer_after`, shown once after, owner only; a domain that left becomes `connected` when its DNS still proves it, otherwise its hosts are removed; workspace deletion keeps the domain row, turns renewal off and emails the registrant |
| Row-level security | `supabase/tests/sites_domains_rls.test.sql` | Members read, only admins read contacts and orders, nobody writes from a client, another workspace sees nothing, and every table calls `allow_worker` (the existing `worker_role_rls.test.sql` fails otherwise) |
| Contracts | `packages/contracts/test/events.test.ts` | Every new `/v1/` route documents 401; `/v1/site-reports` is on the signed-out list with its reason |
| App | `client/test/sites_test.dart`, `domains_test.dart` | The publish sheet, the connect steps with each state chip, the search and buy flow up to the checkout hand-off, the domain screen, **Buy** hidden where `purchaseChannels` has no web |
| Self-host | `apps/server/test/tls-ask.test.ts`, `scripts/check-helm.sh` | `/internal/tls-ask` says yes only for verified hosts and zone labels; the Caddyfile parses with the switch on and off (`caddy validate`) |

Before any phase is called done, from the repository root:
`pnpm lint`, `pnpm typecheck`, `SKIP_DOCKER_TESTS=1 pnpm test`,
`pnpm --filter @casama/db test:pgtap`, `pnpm gen && git diff --exit-code`,
`(cd client && flutter gen-l10n && flutter analyze && flutter test)`,
`pnpm --filter @casama/docs build`.

**Live checks**, each a script under `apps/server/scripts/` that prints what it did and removes
what it made, run on the local stack against real providers. None touches production.

| Script | When | Proves | Costs |
|---|---|---|---|
| `sites-live-check.ts` | End of Phase 1 | A wildcard record and the second tunnel serve a site address over HTTPS from the local stack | Nothing |
| `hostnames-live-check.ts` | End of Phase 2 | A real custom hostname on a test domain goes pending → active through the tunnel; a bare domain through ALIAS; a host on someone's own Cloudflare account; removal stops it | Nothing (inside the included 100) |
| `registrar-live-check.ts` | End of Phase 3 | Against the registrar's **test** system: search, register, records, lock, renew, transfer code | Nothing |
| One real purchase | End of Phase 3, **with Oliver's yes** | A cheap real domain bought through the local stack's checkout in test mode, registered for real, DNS set, site live on it, then kept as the demo domain | About $10–15 |

## 11. Turning it on in production

Every step needs Oliver's yes for that step. Nothing here is done by the build phases.

| # | Step | How | Undo |
|---|---|---|---|
| 1 | Deploy the server with every new setting unset | `scripts/deploy-prod.sh --dry-run`, then `--yes` | `--rollback` (migrations stay; they only add tables and limit keys) |
| 2 | Make the `casama-sites` tunnel and run a second `cloudflared` service on the server with its token | Cloudflare API, then a systemd unit beside the existing one | Stop the unit, delete the tunnel |
| 3 | Add the wildcard record, the zone's own page and the fallback origin on the sites zone | Cloudflare API; `scripts/deploy-sites-web.sh --dry-run`, then `--yes` | Delete the records |
| 4 | Set `CASAMA_SITES_ZONE` and restart the API | Edit the production `.env` (back it up first), deploy script | Unset it: addresses stop, pages are untouched |
| 5 | Publish one site of Oliver's and open it | The app | Unpublish |
| 6 | Set the custom hostname token; connect one real domain | `.env`, the app | Unset; hostnames stay until removed |
| 7 | Set the registrar's live credentials with a small balance; buy one domain | `.env`, the app | Set the registrar to `none`: buying stops, existing domains keep renewing by hand |
| 8 | Turn the features on for everyone in **Admin** → remote settings | The existing app settings | Turn them off |
| 9 | New app builds, the docs and the site | Each its own script and its own yes | — |

Remote settings (D-239) carry three switches, `sites`, `custom_domains` and `buy_domains`, so
each can be turned off without a deploy if something goes wrong. A fourth, `buy_domains_app_store`,
hides buying in the App Store builds only (§2.4), read by the app, not the server.

## 12. Mistakes this plan is built to prevent

Each row is a way this kind of feature goes wrong, here or at other site builders, and the rule
that stops it. The person building a phase reads this table first and again before saying "done".

**Security and trust**

| What goes wrong | The rule |
|---|---|
| A stranger claims a host whose old DNS record was left behind | Own target per domain, ownership value per registration, and the pages server only serves a host with our proof (§7.4) |
| The edge says "active", so the code serves it | "Active" needs our proof **and** the edge (§7.4). One function, `hostIsLive(row)`, is the only place that decides |
| A made-up `Host` header reaches the API or Auth through the sites path | A separate tunnel whose only rule goes to the pages port (§7.1) |
| A public page link works on someone's domain, or a site's cookie reaches another site | Site hosts never mount `/p/`, `/s/`, `/c/`, `/t/`, `/v/`; each site is its own origin; the zone goes on the Public Suffix List |
| A site becomes a phishing kit | The content security policy stays closed; forms post only to Casama; reports, the brand list and suspension (§7.11) |
| A self-hosted server is made to request certificates for any name | `on_demand` is never on without `ask`; the answer is a cached database lookup (§7.12) |
| A workspace member edits a site row straight through Supabase | No client write policies on any new table (§7.14) |
| A registrant's home address shows in logs, analytics or a bot's context | Sealed at rest, admin-only, never a tool input or output, never an analytics property |
| Someone with a stolen session moves a domain away | The transfer code needs the workspace owner, a fresh sign-in, and is emailed to the owner too (§7.10) |

**Money**

| What goes wrong | The rule |
|---|---|
| Paid, but the name was taken or the registrar failed | The workflow refunds by itself and says so; a refund that fails raises an admin notice (§7.7) |
| A webhook arrives twice and two domains are registered, or two years are added | The order id is the workflow id and the registrar reference; `payment_ref` is unique |
| Two people pay for the same name | One live checkout per name (§7.14) |
| The wholesale price moved, or the name turned out to be premium | The price is re-read before registering; over the quoted cost → refund, no registration |
| A domain renews at a loss | The renewal price is computed from that day's wholesale price and shown in the 30-day notice; it is never a number stored a year earlier |
| The registrar balance runs out and registrations fail | Balance read hourly; notice to instance owners under a threshold; orders wait and retry, then refund |
| Unused hostnames keep costing | 7-day expiry for unproved hosts, daily proof checks, the cleanup queue, and a usage notice (§7.4, §7.14) |
| The registrar's own auto-renew charges us for a domain the person stopped paying for | The registrar's auto-renew is off for every domain; only our upkeep renews |
| A price is shown that the checkout doesn't charge | One function, `domainPriceUsd`, feeds search, checkout and the renewal notice; tax is added by the payment provider and the screen says "plus tax" |

**Data and compatibility**

| What goes wrong | The rule |
|---|---|
| A new enum value breaks every installed app | No new value in `CreationKind` or `visibility`; new state lives in new optional fields and new routes; notification kinds are free text |
| A migration replaces `plans.limits` and loses other keys | Merge with `\|\|`, then recompute entitlements (§7.14) |
| The worker sees no rows in a new table | `allow_worker` on every table; the pgTAP suite fails without it |
| A signed-out route fails the contracts test | `/v1/site-reports` is on the signed-out list with its reason |
| Deleting a workspace deletes the record of a domain a person still owns | `domains.org_id` is set null, not cascaded; the row keeps the registrant's email (§7.10) |
| A cascade removes a host row and the edge keeps serving and billing it | The delete trigger and `provider_cleanups` |
| The local database is reset to "fix" a migration | Never. Forward migrations only, `supabase migration up` |
| Generated files are stale | `pnpm gen && git diff --exit-code` before every commit that touches contracts |

**Behaviour**

| What goes wrong | The rule |
|---|---|
| An existing page link, the PDF export or a Casama Link pages host changes behaviour | The dispatcher sends a host to the sites app only when it is under the zone or a known row; the serving test runs every existing route |
| A republished site shows old files for a long time | Short cache times, an `ETag` per version, the host cache cleared on change |
| A site keeps serving after its page is made private, trashed or reported | One lookup query with every condition (§7.2); no second "is it live" flag to drift |
| A person is told "connected" while visitors see a certificate error | **Live** is shown only at `active`; before that the chip says what is being waited for |
| DNS checks hammer a resolver or hang upkeep | DNS-over-HTTPS with a 5-second limit, two resolvers, at most 20 hosts a minute, back-off per host |
| A required renewal notice is not sent because the person turned emails off | Domain notices ignore email preferences and say why at the bottom |
| An address name is reused and old links show a stranger's site | 90-day retirement (§7.14) |
| A domain is bought, then expires quietly because renewals weren't built | Phases 3 and 4 go to production together (decision 13) |

**Process**

| What goes wrong | The rule |
|---|---|
| A commit sweeps up another session's files | The private-index recipe, every time |
| A build or deploy is run without asking | Ask first, for each one |
| A key is made and left in a shell history | Into Vaultwarden in the same task |
| A paid service is added without a cost row | `docs/COSTS.md` in the same change (§8) |
| Whole folders are reformatted | `biome` and `dart format` on touched files only |
| A real provider is called from a test | Fakes only; live checks are separate scripts that clean up |

## 13. Decisions

Oliver approved execution on 2026-11-16; each is taken at its recommendation until he changes it.

| # | Question | Taken |
|---|---|---|
| 1 | The sites zone | A new domain, never `casama.ai` or `casama.link`, bought for 3+ years. Oliver picks the name. The code reads it from `CASAMA_SITES_ZONE` |
| 2 | Registrar | Name.com reseller API; Openprovider stays a one-file switch |
| 3 | Plan limits | Live sites 1 / 3 / 10 / 50, domains 0 / 1 / 5 / 20 (Free / Plus / Pro / Max) |
| 4 | Who may buy | Paid plans only; caps of 3 domains in the first 30 days and 10 a month after |
| 5 | Where **Buy** shows | Where `purchaseChannels` has the web channel: web, desktop, iOS and Mac App Store on the US storefront. Never on Android |
| 6 | Search engines | Off by default; Plus and up can turn it on |
| 7 | Badge | "Made with Casama · Report" on site addresses always; can be turned off on a custom domain from Plus |
| 8 | Price | Cost × 1.25 + $1.50, rounded up to .99 |
| 9 | Registrant emails | Name.com sends them, white-labelled once Name.com approves; Casama's own notices on top |
| 10 | Self-hosted servers | Site addresses and connected domains with on-demand TLS; buying only on Casama Cloud |
| 11 | Payments if Dodo says no | Stop at Phase 3's switch and ask Oliver (Stripe directly is the fallback) |
| 12 | Embeds and outside resources on sites | Not in this plan; the content security policy stays closed |
| 13 | Ship buying without renewals? | No: Phases 3 and 4 go to production together |
| 14 | Endings on sale | .com .net .org .co .io .app .dev .xyz .me .info |
| 15 | Where it's built | Its own worktree and branch, merged to `main` after the last phase; production steps only with Oliver's yes |

## 14. Left for Oliver

Nothing below is done by the build. The track keeps this list current in this file.

| # | What | Needed for |
|---|---|---|
| 1 | ~~Pick and buy the sites zone, add it to Cloudflare, switch on Cloudflare for SaaS~~ **Done 2026-11-17**: `casama.page` (Cloudflare Registrar, 3 years, auto-renew, zone `4bb61ecdfc78a497b55021e37722dd05`). Cloudflare for SaaS is on ($0 base, 100 hostnames included). Tunnel `casama-sites` (`e0709229-5122-4ae3-89a0-f5d7c1f2cdb5`, one catch-all rule to `http://localhost:8790`); `*.casama.page` and `sites.casama.page` are proxied CNAMEs to it; the fallback origin is `sites.casama.page` (active). The zone's own page is live (`scripts/deploy-sites-web.sh`). No connector runs yet, so site addresses answer 530 until §11 step 2 | — |
| 2 | ~~A Cloudflare API token for the sites zone~~ **Done 2026-11-17**: "Casama sites (production)": SSL and Certificates, DNS and Zone Read on `casama.page` only, plus Cloudflare Tunnel: Edit on the account. In Vaultwarden, with the tunnel token | — |
| 3 | ~~Open a Name.com reseller account; test and live tokens into Vaultwarden~~ **Done 2026-11-17**: account 3373919, reseller program joined (tier Base), production and test tokens in Vaultwarden ("Casama · Name.com API token …"). Still to do: ask Name.com for white-label registrant emails; add the production server's IP to the token allow-list before going live | Production |
| 4 | Ask Dodo in writing whether domain resale is allowed, and how tax applies to on-demand charges. The products exist in live mode since 2026-11-17: `DODO_DOMAIN_PRODUCT_ID=pdt_0Ns5xuLNvmn68iK6QybBG` ("Casama domain", PWYW, minimum $1) and `DODO_DOMAIN_RENEWAL_PRODUCT_ID=pdt_0Ns5xuT3r3hwhSFkhtf2c` ("Casama domains renewal", yearly subscription used as the on-demand mandate); not in test mode yet | Turning on buying |
| 5 | Approve each production step in §11, one at a time | Going live |
| 6 | Approve the one real domain purchase (§10) | Phase 3 done |
| 7 | App builds and store releases with the new screens | Users seeing it |
| 8 | An `abuse@` mailbox for the registrar and the zone's page | Going live |
| 9 | Send the Public Suffix List pull request when there are a few thousand sites (`docs/PSL-SUBMISSION.md`) | Later |
| 10 | ~~Run `registrar-live-check.ts` against Name.com's test system~~ **Passed 2026-11-17** after two fixes it found: phone numbers go as E.164 (`+14155550100`, not `+1.4155550100`), and a POST with no fields still needs a JSON body, or Name.com refuses it. Resending the verification email now uses `GET /contacts/unverified` and `POST /contacts/verify/{id}:resend`, because `:resendVerificationEmail` doesn't exist. Confirmed: checkAvailability fields, register with `purchasePrice`/`clientReference`, a second register refused (400 "Domain is not available"), GET domain fields, CNAME/TXT records, **ANAME at the bare domain accepted** (bought domains can use `CASAMA_SITES_APEX=aname`), URL forwarding, `:getPricing`, `:renew` (+1 year), lock (unlock is refused for 60 days after registering, as ICANN requires), auto-renew off, `:setContacts`, `/accountinfo/balance`. Not checked yet: `:getAuthCode` (needs a domain more than 60 days old) and the webhook signature (needs a webhook set up) | Turning on buying |
| 11 | Check in Dodo's test mode: a PWYW checkout with `amount`, an on-demand subscription with `mandate_only: false`, `POST /subscriptions/{id}/charge`, `POST /refunds`, and that `total_amount − tax` is what we compare with the price | Turning on buying |
| 12 | Fill in the domain terms' price table with live costs and Name.com's restore fee | Turning on buying |
| 13 | `sites-live-check.ts` **passed 2026-11-17**: a published site on the local stack was served at `https://sites-check-….casama.page` through a fresh tunnel (the script's own Host-header request was fixed: `fetch()` drops `Host`). Still to do: `hostnames-live-check.ts`, which needs a spare test domain on the Cloudflare account (its `www` and bare records get replaced while it runs, so not a live product domain), plus the bare-domain result on an ALIAS provider and the hostname quota check | Phase 2 done |
| 14 | `casama domains connect` against the local stack once the zone exists | Phase 5 done |
| 15 | The new email kinds (`domain_renewal`, `domain_renewed`, `domain_renewal_failed`, `domain_expired`, `domain_verify_email`, `domain_transfer_code`, `domain_released`) seen once in a real inbox | Going live |

## 15. Risks

| Risk | What happens | What we do |
|---|---|---|
| Dodo refuses domain resale | Buying can't go live | Phases 1–2 don't depend on it; the payment interface keeps a switch to another provider |
| A site address is used for phishing | The zone is listed by a browser | Separate zone, closed policy, reports, brand list, suspension, the PSL later. `casama.ai` is never affected |
| Bare domains through ALIAS don't validate at Cloudflare | Some people can only use `www` | Forwarding works everywhere; the live check decides what the screen offers |
| The registrar fails between payment and registration | Money taken, no domain | Durable workflow, retries, automatic refund, admin notice |
| A renewal is missed | Someone loses their domain | Notices from both Casama and Name.com, retries, grace and redemption, daily reconcile |
| Hostname fees grow with free users | Cost without revenue | Custom domains need Plus; unproved hosts expire; usage notice |
| Name.com's wholesale price is higher than expected | Thin margin | The markup is a live setting; the price is computed from live cost |
| ICANN's new Transfer Policy takes effect | The 60-day rule changes | One constant |
| The pages server is now reached by many more host names | A bug serves the wrong content | One lookup function, a serving test that runs every existing route, a separate tunnel |

## Sources

Checked 2026-11-16.

- Cloudflare for SaaS plans: https://developers.cloudflare.com/cloudflare-for-platforms/cloudflare-for-saas/plans/
- Quotas and billing: https://developers.cloudflare.com/cloudflare-for-platforms/cloudflare-for-saas/quotas-and-billing/
- Per-hostname origin on all plans: https://developers.cloudflare.com/changelog/post/2025-05-19-paygo-updates/
- Custom hostname API: https://developers.cloudflare.com/api/resources/custom_hostnames/methods/create/
- Fallback origin API: https://developers.cloudflare.com/api/resources/custom_hostnames/subresources/fallback_origin/methods/update/
- Validation and back-off: https://developers.cloudflare.com/cloudflare-for-platforms/cloudflare-for-saas/domain-support/hostname-validation/backoff-schedule/
- Pre-validation: https://developers.cloudflare.com/cloudflare-for-platforms/cloudflare-for-saas/domain-support/hostname-validation/pre-validation/
- Apex proxying: https://developers.cloudflare.com/cloudflare-for-platforms/cloudflare-for-saas/start/advanced-settings/apex-proxying/
- Customers on Cloudflare (O2O): https://developers.cloudflare.com/cloudflare-for-platforms/cloudflare-for-saas/saas-customers/how-it-works/
- Tunnel as fallback origin: https://developers.cloudflare.com/reference-architecture/design-guides/extending-cloudflares-benefits-to-saas-providers-end-customers/
- Removing hostnames: https://developers.cloudflare.com/cloudflare-for-platforms/cloudflare-for-saas/domain-support/remove-custom-hostnames/
- Certificate webhooks: https://developers.cloudflare.com/cloudflare-for-platforms/cloudflare-for-saas/security/certificate-management/webhook-definitions/
- API limits: https://developers.cloudflare.com/fundamentals/api/reference/limits/
- Wildcard records: https://developers.cloudflare.com/dns/manage-dns-records/reference/wildcard-dns-records/
- SSL for SaaS terms: https://www.cloudflare.com/service-specific-terms-application-services/
- Cloudflare Registrar API: https://developers.cloudflare.com/registrar/registrar-api/
- Caddy on-demand TLS: https://caddyserver.com/docs/automatic-https#on-demand-tls
- Let's Encrypt limits: https://letsencrypt.org/docs/rate-limits/
- Name.com API: https://docs.name.com/api/v1/overview.md, testing https://docs.name.com/guides/testing-environment.md, registrant emails https://docs.name.com/guides/registrant-communications.md, renewals https://docs.name.com/guides/domain-renewals-expiration.md, reseller https://www.name.com/reseller
- Openprovider .com: https://www.openprovider.com/get/com
- OpenSRS payment terms: https://opensrs.com/payment-terms/
- Vercel at-cost domains: https://vercel.com/changelog/vercel-domains-at-cost-pricing-and-the-fastest-on-the-web
- Replit on Name.com: https://www.businesswire.com/news/home/20251209365505/en
- Entri Sell: https://developers.entri.com/sell/overview.md
- RAA 2013: https://www.icann.org/resources/pages/approved-with-specs-2013-09-17-en
- ERRP: https://www.icann.org/resources/pages/errp-2013-02-28-en
- Transfer Policy: https://www.icann.org/en/contracted-parties/accredited-registrars/resources/domain-name-transfers/policy
- Revised Transfer Policy adoption: https://www.icann.org/en/board-activities-and-meetings/materials/approved-resolutions-regular-meeting-of-the-icann-board-07-06-2026-en
- AGP limits: https://www.icann.org/resources/pages/agp-policy-2008-12-17-en
- Registration Data Policy: https://www.icann.org/en/contracted-parties/consensus-policies/registration-data-policy
- DNS abuse advisory: https://www.icann.org/en/contracted-parties/advisories/documents/advisory-compliance-with-dns-abuse-obligations-in-the-registrar-accreditation-agreement-and-the-registry-agreement-05-02-2024-en
- .dev and .app HSTS: https://www.registry.google/domains/dev/
- Apple guidelines: https://developer.apple.com/app-store/review/guidelines/
- Google Play payments: https://support.google.com/googleplay/android-developer/answer/9858738
- Dodo PWYW checkout: https://docs.dodopayments.com/developer-resources/dynamic-pricing-checkout.md
- Dodo on-demand subscriptions: https://docs.dodopayments.com/developer-resources/ondemand-subscriptions.md
- Dodo acceptance policy: https://docs.dodopayments.com/miscellaneous/merchant-acceptance.md
- Dodo pricing: https://dodopayments.com/pricing
- Public Suffix List guidelines: https://github.com/publicsuffix/list/wiki/Guidelines
- Hosting user content safely: https://web.dev/articles/securely-hosting-user-data
- Search Console verification: https://support.google.com/webmasters/answer/9008080
