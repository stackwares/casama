# Production gaps plan, November 2026

Status: items 1–5 **built** 2026-11-15 (D-301 to D-305), not yet deployed; item 6–7 proposed. Oliver asked for "the final plan for all of the gaps worth
building" after the production review. Each section names the existing code it hooks into, what to
build, what's done when, and what only Oliver can supply. Decision numbers start at D-299 when
building begins.

## Order

| # | Gap | Why now | Size |
| - | --- | ------- | ---- |
| 1 | [Reporting and moderation](#1-reporting-and-moderation) | **Blocks store approval.** Public Pages, shared bots and the gallery are user-generated content; App Store Guideline 1.2 and Google Play's UGC policy require a way to report content and block users | 2–3 days |
| 2 | [Account emails](#2-account-emails) (billing + welcome) | Protects revenue: failed payments, ending trials and cancellations currently get no email at all | 4–5 days |
| 3 | [Public status page](#3-public-status-page) | Users can't see an outage; only we get the uptime email | 1 day |
| 4 | [In-app review prompt](#4-in-app-review-prompt) | Store ranking and ratings from launch day | 0.5 day |
| 5 | [Support ticket log](#5-support-ticket-log) | Casama Help and the admin console can find a ticket by its reference | 1 day |
| 6 | [Accessibility pass](#6-accessibility-pass) | Store featuring, legal exposure, and real users with screen readers | 2 days |
| 7 | [More languages](#7-more-languages) | Wider store audience after launch | 3–4 days + review |

Items 1–4 before submitting to the stores; 5–6 alongside review; 7 after launch.

---

## 1. Reporting and moderation

**Today:** suspending a workspace exists (`apps/server/src/services/abuse.ts`, Admin console). The
gallery has a "Report" link that opens an email (`client/lib/features/settings/gallery_screen.dart`).
Public Pages, shared bots and Casama Link addresses have no report path, and there's no way to
block a person.

**Build:**
- `content_reports` table (API only, `allow_worker`): reporter (user or none for public pages),
  target kind (`page`, `bot`, `gallery_item`, `workspace`, `user`), target id, reason (spam,
  sexual content, violence or threats, harassment, illegal, impersonation, other), note, status
  (`open`, `actioned`, `dismissed`), reviewer, timestamps.
- `POST /v1/reports` (signed in) and `POST /public/reports` (public Pages, with Turnstile or the
  existing proof-of-work and an IP rate limit).
- Report buttons:
  - in the app on shared bots, gallery items and other people's messages in group chats;
  - in the footer of every public Page ("Report this page").
- **Blocking:** `user_blocks` table; a blocked person's messages are hidden in group chats and
  they can't invite or message the blocker. "Block" sits next to "Report" on people.
- **Admin console > Reports** queue:
  - open reports newest first, with the content shown and the reporter's note;
  - actions: unpublish the Page, hide the gallery item, suspend the workspace (existing), dismiss.
- Each action is written to the audit log, and the reporter gets an email
  ("Thanks, we reviewed your report"). An email also goes to `abuse@casama.ai` when a report
  arrives, and a push to instance owners when three or more open reports point at one target.
- **Automatic first line for public Pages:** a Page reported by 3 different people within 24 hours
  is hidden until reviewed.

**Done when:** a report from the app and from a public Page appears in the queue; unpublish and
suspend work from there; a blocked person's messages disappear; pgTAP covers the new tables;
the review notes for App Store Connect describe the flow.

**Needs Oliver:** the `abuse@casama.ai` mailbox or alias; who reviews reports and how fast (store
reviewers ask).

---

## 2. Account emails

**Today:** the server only sends invite emails (`api/routes/joining.ts`), server capacity alerts
(`services/capacity.ts`) and support messages (`api/routes/support.ts`), plus the sign-in emails
from Auth. Billing changes reach PostHog (`billing/analytics.ts` classifies them as `started`,
`trial_started`, `trial_converted`, `renewed`, `recovered`, `grace`, `cancelled`, `expired`,
`refunded`, `plan_changed`) but never the customer. "Credits are running low" is a push only
(`worker/workflows.ts`, `billingSettleWorkflow`).

### Foundation (build first)

- `services/account-email.ts`: one function `sendAccountEmail(kind, recipient, data)`.
  - It renders with the existing branded layout (`services/email-layout.ts`) in HTML and text.
  - It sends through `deps.email` (prod: Zoho SMTP from hello@casama.ai).
- `email_log` table (API and worker, `allow_worker`):
  - columns: user id, org id, kind, dedupe key, sent_at;
  - unique on (kind, dedupe key), so a retried webhook or sweep never sends twice.
- **Two classes of email:**
  - *Account* (billing, security, support): always sent; they're part of the service.
  - *Tips and news* (welcome series, nudges, win-back): on by default and switchable off.
    The switch lives in Settings > Notifications ("Tips and product news by email") and in a
    one-click unsubscribe link with a `List-Unsubscribe` header.
  - The unsubscribe link carries a signed token, works without signing in, and is answered by the
    API.
  - `EmailMessage` gains `headers` for the `List-Unsubscribe` header.
- **Recipients:** billing emails go to the workspace's owners and admins, never to plain members.
  Welcome emails go to the person who signed up.
- **Sending volume:** Zoho SMTP caps daily sends per mailbox. When account emails pass a few
  hundred a day, switch to Resend ($20 / month for 50k; the adapter exists). This goes into
  `docs/COSTS.md` when built.

### Billing emails

Fired from `BillingService.trackSubscription` (it already knows the change) and from one new daily
sweep (`account-emails-daily`, registered next to `privacy-daily` in `worker/index.ts`).

| Trigger | Email | Notes |
| ------- | ----- | ----- |
| `trial_started` | "Your Pro trial has started": end date; how to cancel in the store it came from or on the web | |
| Trial ends within 3 days (daily sweep on `subscriptions.status = 'trialing'`) | "Your trial ends on {date}": what they keep and what they lose; how to cancel | Apple and Google don't send this reminder for monthly trials |
| `started`, `trial_converted`, `plan_changed` | "Welcome to {plan}": what's included now, credits added, Billing link | Not a tax invoice. Dodo (merchant of record) sends invoices for web purchases; the stores send their own receipts. **Verify Dodo's invoice email is on** |
| `grace` (payment failed) | "Your payment didn't go through": update the card in the App Store, Google Play, or the web portal (Dodo portal link); when access stops | Repeat once 3 days later if still failing |
| `cancel_at_period_end` turns true (new: compare old vs new in `applySnapshot`) | "Your plan ends on {date}": what happens then; resubscribe link only where web checkout is allowed (never on Android, per the store rules) | |
| `expired` | "You're on the Free plan now": what changed (limits, bots paused), how to come back | |
| `refunded` | "Your refund went through": plan and credits effect | |
| Credits low (existing `lowCreditWorkspaces`) | "Credits are running low", like the push | At most once a week per workspace |
| Credits ran out (balance ≤ 0 with bots on Casama models) | "Your bots are paused: out of credits" | Once until credits are added |
| Yearly plan renews within 7 days (web plans) | "Your yearly plan renews on {date} for {price}" | Some US states require this for yearly auto-renewal; stores send their own |

`renewed` sends nothing; the store and Dodo already send receipts.

### Welcome and activation emails (tips class)

| When | Email |
| ---- | ----- |
| Email confirmed, first sign-in | "Welcome to Casama": what it does in two lines; three first steps (make a bot, give it a routine, connect an app); the Help & support page; the docs |
| Day 2, no bot made or no message sent | "Your first bot in two minutes": one concrete starter with a deep link that opens the bot templates |
| Day 7, active | "Three things people love": routines, computers, voice, picked by what they haven't used |
| 14 days quiet after being active | "Your bots are still here": what they did lately (routine runs, briefs), one tap back |

Activation state comes from existing tables (bots, messages, runs, routines) and the analytics
milestones (`milestone(..., "first_purchase")` shows the pattern). Each email is sent once per
person; a person who unsubscribed gets none of these.

**Done when:**
- Every trigger has a server test against the fake billing providers (`test/fake-billing.ts`);
  each test checks it sends once, to owners and admins only.
- Unsubscribe works without signing in and stops the tips class only.
- Emails render in Gmail, Apple Mail and Outlook: the HTML layout's test plus one real send of
  each to Oliver.

**Needs Oliver:**
- **A postal business address for the footer** of tips and news emails (US CAN-SPAM; also
  expected by EU rules).
- Confirming Dodo's invoice email setting.
- When to move from Zoho to Resend.
- A yes on the wording of the payment-failed and trial-ending emails.

---

## 3. Public status page

**Today:** the Cloudflare Worker `casama-uptime` (`infra/uptime/`) checks the API's `/readyz` and
the web app every 5 minutes and emails the owner after two failures. Nothing is public. The app
shows "Can't reach your Casama server" (`core/server_reachability.dart`) with no link.

**Build:**
- Extend the same worker (it already runs on Cloudflare, so it stays up when our server is down):
  - Each run writes one compact state record to its KV namespace: the last check result per
    target and a per-day rollup. One write per run is about 288 a day, inside the free tier.
  - Keep 90 days of rollups.
- A `fetch` handler serves `status.casama.ai`:
  - a light page (same type as the site) with the current status of API, Web app, Sign-in
    (`auth.casama.ai` health) and Docs;
  - 90-day uptime bars and current incident notes;
  - `/status.json` for the app.
- **Incidents:** a note written with `wrangler kv key put incident ...` (text, severity, start)
  shows at the top until removed. A small `scripts/status-incident.sh` wraps it.
- **App:** the "Can't reach" bar gets a "Status" button opening status.casama.ai, shown only
  for Casama Cloud (`api.casama.ai`).
- Add `auth` and `docs` to `CHECKS`.

**Done when:** status.casama.ai shows live results; stopping the API on a test target flips it to
down within 10 minutes and back; an incident note appears and clears; costs stay $0.

**Needs Oliver:** a yes to the `status.casama.ai` DNS record (production infrastructure).

---

## 4. In-app review prompt

**Build:**
- Add the `in_app_review` package and a `ReviewPrompt` service in `client/lib/core/`.
- **When to ask:** only after a good moment, and only when all of these hold:
  - the app was used on 5 different days;
  - no error toast in this session;
  - the account is at least 7 days old.
- **The good moments:**
  - a routine run finished and its result was opened;
  - a bot's reply got a thumbs-up;
  - a purchase went through (after the post-purchase screen closes).
- **At most once every 120 days per device,** stored locally. Apple adds its own cap of three a
  year, and the call may show nothing.
- **Platforms:** iOS, Android and the Mac App Store build only. Never on web or the direct desktop
  download.
- A remote-settings flag (`review_prompt`, `services/app-config.ts`) can turn it off without a
  release.
- Analytics: `review_prompt_shown` (the store doesn't tell us whether they rated).

**Done when:** widget tests cover the rules (shown once on the third qualifying day, never after
an error, never on web); one manual check on a TestFlight or internal-testing build.

**Needs Oliver:** nothing.

---

## 5. Support ticket log

**Today:** `POST /v1/support/tickets` emails support@casama.ai and keeps nothing but counters
(D-298).

**Build:**
- `support_tickets` table: reference, user, workspace, topic, subject line, created_at, status
  (`open` or `closed`), with no message body. The body stays in email, so the database holds no
  support content.
- Casama Help gets a `get_my_tickets` tool, so "did you get my message?" is answered with the
  reference and date.
- Admin console > Support lists tickets by reference and status; support marks them closed.
- **Later, not now:** a shared helpdesk once tickets pass about 20 a day. For now, Zoho filters
  on the `[billing]`, `[broken]` and other subject tags already sent.

**Done when:** a ticket shows in the admin list; Casama Help finds it by reference; tests cover it.

**Needs Oliver:** nothing.

---

## 6. Accessibility pass

**Today:** about 45 files use `Semantics`; the mascot respects reduced motion; there's no
systematic check.

**Build:**
- **Guideline tests** (`meetsGuideline`: Android tap targets, labelled tap targets, text contrast)
  on the main screens:
  - bots list, chat and composer, Settings, Billing and paywall, Help & support;
  - sign-in and onboarding.
- Run them in both themes and two of the eight looks with the most contrast risk.
- Fix what they find.
- **Text scaling:** pump the same screens at 200% text scale and fix overflow.
- **Screen readers:** a scripted pass with VoiceOver (iOS simulator) and TalkBack (Android
  emulator) through sign-in, making a bot, chatting, buying and contacting support. Unlabelled
  icons get labels; custom controls get roles.
- **Desktop and web:** keyboard focus order and visible focus on the same flows.

**Done when:** the guideline tests pass in CI; the screen-reader pass completes those flows with
nothing unlabelled; findings and fixes go into `docs/AUDIT-2026-11.md`.

**Needs Oliver:** nothing; the device passes use the simulators.

---

## 7. More languages

**Today:** English only (v1 scope). The app's text all lives in `client/lib/l10n/app_en.arb`
(about 2,600 keys), generated with `flutter gen-l10n`. The language row in Settings lists English
only.

**Build:**
- **First languages (proposed):** Spanish, Portuguese (Brazil), French, German and Japanese:
  - the largest app markets where English isn't the default;
  - Casama's pricing and payments already work there.
- **A pseudo-locale first:** about 40% longer text with accents. Run the screen tests in it to
  catch layouts that break, before any real translation.
- **Translation:**
  - The model translates with a glossary: Casama, Casama Help, bot, routine, workspace and the
    plan names stay fixed; "credits" has one agreed word per language.
  - A second pass checks placeholders, plurals and tone.
  - A native speaker reviews each language before release (paid per language, or volunteers).
- CI fails when a key is missing in any language or a placeholder doesn't match.
- **Server text:** emails from §2 and notification texts get the person's language
  (`profiles.locale`, new). Bots already answer in the language people write in.
- **Not translated:** the docs stay English; Casama Help answers in the person's language from
  English docs.
- **Store listings:** translated per language (`client/store/`; the `asc-metadata-sync` and
  `gplay` workflows).

**Done when:** each language passes the missing-key check and the pseudo-locale layout run; one
reviewed language ships first and the others follow.

**Needs Oliver:**
- The language list.
- A budget for native review (rough guide: $100–300 per language for about 2,600 short strings).

---

## Across all items

- Each item gets its decision entry (`docs/DECISIONS.md`), cost rows (`docs/COSTS.md`) and docs
  pages where users see it.
- Each item also gets tests in the suite that covers it (server, Flutter, pgTAP for new tables).
  The full suites run before any commit.
- Builds, store uploads and production deploys still need Oliver's yes each time (`AGENTS.md`).
- **Total:** about 14–17 days of build work; items 1–4 (about 8–10 days) are the pre-submission set.
