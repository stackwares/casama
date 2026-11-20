# Waitlist and invite gate for Casama Cloud: plan

Status: **approved, being built** (Oliver, 2026-11-19: "Yes to all!" to the 18 decisions in §18, so
every recommendation there is adopted). Written 2026-11-19. What is built so far is in "Status of
the build" at the end. Deploys, app builds, turning the gate on and money changes still need
Oliver's yes each time.

## Execution brief (read this first)

**Goal:** Casama Cloud takes new accounts by invitation from late November 2026 until the public
launch (planned Tue 12 Jan 2027, 12:01 am San Francisco). It must be on in production before the
Hacker News post (planned Tue 8 Dec 2026, 8:30 am New York). Build Phases 1 to 3 of §15 in order;
each ends at its "Done when" check.

**Defaults adopted** (from §18, all 18 answered yes on 2026-11-19; the ones that shape the code):

| # | Default |
|---|---|
| 2 | The words are "invite-only". Never "beta", anywhere |
| 4 | People are let in by hand at first, then by a daily number Oliver sets (Phase 3). Start at 25 a day |
| 7 | One public code for self-hosters, in the Show HN post and the Casama Link docs, with a number per day |
| 8 | Each member gets 3 invites once they have finished a first chat |
| 9 | D-211's credits stay as they are ($2 for the inviter, $2 for the friend, after the friend's first chat) |
| 10 | Referring friends does not move anyone up. No position number is shown |
| 12 | The monthly-email box on the waitlist form is unticked; a yes is applied when the person first signs in |
| 13 | A workspace invite lets a new person in only when the workspace has a free seat |
| 16 | The gate opens by itself at a set time. The rest of the list is let in during the week before |

If a default turns out unworkable, pick the closest option, write down why in the decision entry,
and keep going.

**Rules:** everything in `AGENTS.md`. The ones that bite here:

- Shared working tree: stage by path, check the index is empty first, commit only your own hunks.
- New tables get RLS, `public.allow_worker` and a pgTAP test. The worker never reads `auth.*`
  directly; it uses a `public.worker_*` security-definer function.
- Functions that admit or redeem are callable by the API only, never by `anon` or `authenticated`
  (the hole D-211's audit found in `redeem_referral`).
- Check the newest migration version on `main`, every branch, every worktree, the local database
  and production right before naming yours. A new one (`20270212100001`) appeared in this checkout
  while this plan was being written. Apply with `supabase migration up --include-all`. Never
  `migration repair`, never a reset.
- New Dart files import `package:material_ui/material_ui.dart`. `dart format` only files you made.
- Targeted tests while working; the full suites once at the end through `scripts/heavy.sh`.
- `/v1/config` and other shared responses only gain optional fields. No new value in an existing
  enum: the shipped apps' generated client rejects values it doesn't know (D-297).
- `docs/COSTS.md`, the privacy page, `docs-site` and `CHANGELOG.md` change in the same commit as
  the code they describe. Take the next free `D-` number when Phase 1 lands (D-416 was the highest
  seen on 2026-11-19, on a branch).
- Line numbers in this plan are from 2026-11-19. Re-find each one before editing.

**Not allowed without Oliver's yes, each time:** any Flutter build or `flutter run`; any production
change (server deploy, site deploy, web app deploy, editing the server's env, turning the gate on or
off, admitting people); store uploads; writes to the PostHog project; spending money.

**Needs Oliver's hands** (log each in `docs/NEEDS-FROM-OLIVER.md`; work around it, don't block):

| Item | Why | Until then |
|---|---|---|
| ZeptoMail's KYC review passing (submitted 2026-11-19) | Sign-in links and "you're in" emails share a cap of 100 emails a day | At most 25 "you're in" emails a day; campaign codes sized to the cap (§6) |
| OpenRouter daily cap, $50 today | A burst of new people can hit it and stop model calls for everyone (§13) | Keep admissions at 50 a day or fewer |
| A yes or no on the larger server before 8 Dec (§18, question 6) | The server runs about 9 computers at once | The Hacker News code stays small (§8) |
| A yes for each deploy: server, casama.ai, web app, and the env line `REFERRAL_LINK_BASE` | Production changes | Everything is tested on the local stack first |
| A yes for app build 46, and later for the store uploads | Phase 2 ships in a new build | Phase 1 works with build 44 and web build 45 |
| App Store submission, the review notes and the reviewer code; Play's "Sign-in details" | §9 | The text is written into `client/store/` ready to paste |
| A yes to create the PostHog dashboard "Casama: Waitlist" | PostHog writes need permission | The same numbers are in Admin and in `scripts/waitlist.sh stats` |

---

## 0. Summary

**The design in ten lines.**

1. The gate is one check in the place every new account already passes through: Supabase Auth's
   "before user created" hook, which calls our API. Production has had this hook on since D-094.
2. The check is by email address: a new account is made only for an address that has been let in.
   Everything that lets someone in (a batch, an invite code, a hand-added address) does the same
   thing: it marks that address as admitted.
3. An invite code is therefore claimed together with an email address, before sign-up, on
   casama.ai or in the app. After that any sign-in method works for that address.
4. Existing accounts never reach the hook, so the 17 people in production, the App Review account
   and every way of signing in keep working with no change.
5. Self-hosted servers get nothing new. The feature exists only where billing is on (Casama
   Cloud), and even there it stays open until an owner turns it on in Admin.
6. The waitlist is a table in our own database. Joining sends no email. The one email a person
   gets is "You're in".
7. Invite codes reuse D-211: each member's existing 6-character code becomes their invite code,
   with 3 invites each. Shared campaign codes (for example one in the Hacker News post) are new
   and have a cap.
8. Opening on launch day is one setting, changed in Admin or set ahead with a time. No deploy, no
   app build.
9. Phase 1 (server and site, about 3 working days) works with the apps already shipped: build 44
   and web build 45 show an "accounts are by invitation" line they already contain, plus our
   sentence when someone tries.
10. Phase 2 (about 3 days, new app build 46, the web app first) adds the native screens: join the
    waitlist, enter a code, and Admin → Waitlist.

**Phases:**

| Phase | What | Working days | Needs an app build |
|---|---|---|---|
| 1 | The gate on the server, the waitlist, codes, casama.ai pages, a script for Oliver | about 3 | No |
| 2 | Native screens in the app, code entry at sign-up, Admin → Waitlist | about 3 | Yes: 46 (web deploy first, stores when Oliver asks) |
| 3 | A daily automatic batch tied to mail and capacity, funnel numbers | about 2 | No |
| 4 | Launch day: the list is let in, the gate opens, cleanup | about 1 | No |

**Dates if approved by 20 Nov:** Phase 1 built by Tue 24 Nov and on in production by Wed 25 Nov;
Phase 2 on the web app by Tue 1 Dec; Phase 3 by Fri 4 Dec; three days of slack before 8 Dec.

**The two limits that set every number in this plan:**

- **Mail.** ZeptoMail sends 100 emails a day until its review passes, and sign-in links for
  existing members come out of the same 100. The gate helps here: Auth asks the hook before it
  sends anything, so a refused sign-up costs no email.
- **Computers.** The server runs about 9 at once. See §6 for the arithmetic.

---

## 1. What exists today

Checked in the code and read-only in production on 2026-11-19.

### 1.1 Sign-up

| Fact | Where |
|---|---|
| Every account is made by Supabase Auth. The API has no route that makes one. The ways in: email link or code, password sign-up, Apple and Google (their own sheet, or the browser), the CLI (`casama signup`, `casama login --magic-link`), and direct calls to Auth | `client/lib/core/supabase_backend.dart:122-141`, `:285`, `:340`; `dart/cli/lib/src/runner.dart:208-262` |
| Passkeys only sign in to an account that already has one; they can't make an account | `supabase_backend.dart:524-600`, `sign_in_screen.dart:553` |
| Auth calls `POST /hooks/auth/before-user-created` before making any account. The hook already has two gates (the email allowlist of D-145 and "invited only" of D-296) and then the sign-up proof check of D-094 | `apps/server/src/api/routes/abuse.ts:41-145` |
| **Production has the hook on:** `SIGNUP_HOOK_ENABLED=true`, `SIGNUP_HOOK_URI=https://api.casama.ai/hooks/auth/before-user-created`, `AUTH_HOOK_SECRET` set, `ABUSE_CONTROLS=on`. `SIGNUP_ALLOWED_EMAILS`, `SIGNUP_INVITED_ONLY` and `DISABLE_SIGNUP` are unset | `/opt/casama/infra/compose/.env` |
| The apps read `GET /v1/config` signed out. It can carry `signups_open` and `signups_by_invitation` | `apps/server/src/api/routes/system.ts:63-66` |
| **Build 44 and web build 45 already act on `signups_by_invitation`.** The sign-in screen then shows "New accounts here are by invitation. Use the email address you were invited with." | `client/lib/features/auth/sign_in_screen.dart:766-775`, `app_en.arb:3541` |
| A sign-in error the app has no text for is shown as the server's own message | `client/lib/core/widgets.dart:28-48` (`return e.message`) |
| The only thing the app sends with a sign-up is `signup_proof`, and only for email and password. Apple and Google sign-ins carry nothing of ours | `supabase_backend.dart:111-119` |

### 1.2 Invites and referrals

| Fact | Where |
|---|---|
| D-211, "Invite friends: no gate": one 6-character code per person (`referral_codes`), redeemed after sign-up by a tap, $2 to the inviter and $2 to the friend after the friend's first finished chat, 20 rewarded friends at most. On only with billing | `docs/DECISIONS.md:2333`; `supabase/migrations/20270121000001_referrals.sql`; `apps/server/src/api/routes/referrals.ts` |
| `casama.ai/i/<code>` is the invite page (site Worker). On a phone with the app installed, the link opens the app's own invite screen | `site/gallery-link.js:78`, `:204`; `client/lib/core/router.dart:353` |
| The link a member shares is built by the server from `REFERRAL_LINK_BASE` (default `https://casama.ai/i`) | `apps/server/src/env.ts:169-178` |
| Wrong codes: 10 misses per caller per 10 minutes. Signed-out callers are told apart by `cf-connecting-ip` (`TRUSTED_CLIENT_IP_HEADER`, set in production) | `apps/server/src/api/routes/joining.ts:97` |
| Workspace invites (`public.invites`) are not checked against seats when they are made. Seats are enforced when the person joins (`memberships_enforce_seats`) | `joining.ts:897-935`; `supabase/migrations/20270129000001_pricing.sql:92` |
| Free credits and referral decisions are keyed on a hash of the normalised email (no "+tag", no Gmail dots) | D-333; `20270201160401_email_identities.sql` |

### 1.3 Settings that change without a deploy

| Fact | Where |
|---|---|
| `public.instance_settings` (key, JSON value) holds remote app settings, the model catalog and more; the server caches a read for 15 seconds | `20261116000001_production.sql:22`; `apps/server/src/services/app-config.ts` |
| `GET /v1/app-config` is signed out; owners change it at `PUT /v1/admin/app-config` | `apps/server/src/api/routes/gallery-content.ts:68-116` |
| Admin → Services → App settings is a card in the app | `client/lib/features/admin/app_settings_card.dart` |

### 1.4 Mail, newsletter, site

| Fact | Where |
|---|---|
| App mail goes through ZeptoMail (D-318): 100 a day until KYC passes; then $2.50 per 10,000 | `docs/COSTS.md` |
| The newsletter is on a free, shared Resend account: 100 emails a day, 1,000 contacts. casama.ai's form uses a confirmation email (D-404). The app subscribes a signed-in person's verified address with no confirmation email (D-408) | `site/newsletter.js`; `apps/server/src/services/newsletter.ts` |
| casama.ai's "Start free" buttons point at `app.casama.ai` or at `/get/start`, a Worker route. Generated pages get the button from the `cta` shortcode | `site/index.html:194`, `:599-617`, `:735`; `site/gallery-link.js:66-70`; `site/build.mjs:484` |
| The site Worker has no database | `site/wrangler.jsonc` |

### 1.5 Production numbers

- 17 accounts: 9 signed up with Google, 6 with email, 2 with Apple. So about two in three new
  people cause no email at all.
- 13 workspaces, 0 pending workspace invites, 12 referral codes, 0 referrals, 0 refused sign-ups
  in 7 days.
- The server: 6 cores, 12 GB, `COMPUTER_HOST_MEMORY_GB=9`.
- OpenRouter's cap: $50 a day. A Free user costs about $0.80 a month if they use everything.

### 1.6 The store listing

- Version in `client/pubspec.yaml` is `0.1.0+40` on this checkout; build 44 is what TestFlight and
  Play hold.
- `client/store/app_store/review_notes.txt` tells the reviewer to sign in with the demo account
  `review@casama.ai` by password. It already says the app can also connect to a server someone
  runs themselves.

---

## 2. Where the gate sits

**In the hook Auth already calls: `POST /hooks/auth/before-user-created`.** Nothing in the client
is trusted. A new rule is added there, before the proof check.

### 2.1 The rule

When the gate is on, a new account is allowed if any of these is true, checked in this order:

1. The email is on `SIGNUP_ALLOWED_EMAILS` (existing; unset in production). A server that sets
   this list keeps it deciding alone, as today (D-145): only its addresses get in.
2. A workspace invite for this email still stands **and** that workspace has a free seat for it
   (plan seats plus extra seats, minus members, minus older pending invites). Without the seat
   check any Free workspace could mint accounts by sending invites.
3. The email has been admitted (§5: a waitlist entry with status `admitted` or `joined`, matched
   on the normalised email of D-333).
4. Phase 2: the sign-up carries a good invite code in its metadata (§7.3).

Otherwise Auth is told to refuse, with one sentence (§2.3). After the rule, the proof check of
D-094 runs exactly as today.

If the setting or the lookup can't be read, the hook refuses, as it already does when its secret
is missing.

### 2.2 Why here and not after sign-in

The other shape is "anyone can make an account, and the account waits". It was set aside for now:

- Auth asks the hook **before** it sends a sign-in link, so a refused person costs no email. With
  100 emails a day, letting every Hacker News visitor make an account would use up the day's mail
  by mid-morning and lock existing members out of their own sign-in links.
- The shipped apps have no "you're waiting" screen. A waiting account in build 44 would land in
  onboarding and fail there.

### 2.3 What each caller sees

The sentence: **"Casama Cloud is invite-only for now. Join the waitlist or enter an invite code at
casama.ai/waitlist."**

| Way in | What happens to a new, uninvited person | Build 44, web 45 | New build (Phase 2) |
|---|---|---|---|
| Email link or code | Refused when they ask for the link. No email goes out | The sentence as a toast, under the "by invitation" line | A native sheet: Join the Waitlist, I Have an Invite |
| Password sign-up | Refused at sign-up | Same | Same |
| Apple or Google, their own sheet | Refused when the token is exchanged | The sentence as a toast | The sheet |
| Apple or Google, in the browser | Auth redirects back with the error | To check (§17) | The sheet |
| Passkey | Can't make an account at all | — | — |
| CLI `casama signup`, `login --magic-link` | Prints the sentence | | |
| Direct calls to Auth, the SDK | An error with the sentence | | |
| A workspace code or join link | Needs an account first, so the same rule applies | | |

An Apple "Hide My Email" address never matches an admitted address. For those the sentence is
"Your invite is for another email address. With Apple, choose Share My Email, or use Continue with
Email." Phase 2 removes the limit (§7.3).

Refusals are not written to `abuse_events`, so the Admin Abuse tab doesn't fill up with ordinary
visitors. Phase 3 counts them as an analytics event (`signup_refused`).

### 2.4 What the apps are told

`GET /v1/config`, while the gate is on:

- `signups_by_invitation: true`: the field shipped apps already understand.
- `signup_gate: { mode: "invite_only", waitlist_url }`: new and optional, for new builds.

Both are absent when the gate is open or the feature is off.

---

## 3. Cloud only, and the switch

Two layers, so that the default is always "nothing changes".

**Does the feature exist on this server?** `SIGNUP_WAITLIST=auto|on|off`, default `auto`: it exists
only where `BILLING_ENABLED` is true, the same rule as `REFERRALS` and `ABUSE_CONTROLS`. Where it
doesn't exist the routes answer 404, `/v1/config` is unchanged, Admin shows nothing, and the hook
skips the rule. A self-hosted server has nothing to set, and `SIGNUP_ALLOWED_EMAILS`,
`SIGNUP_INVITED_ONLY` and `DISABLE_SIGNUP` behave as today. A test compares a self-hosted server's
`/v1/config` and hook answers before and after.

**Is the gate on?** A row in `instance_settings`, key `signup_gate`:

```json
{
  "mode": "open",
  "opens_at": null,
  "invites_per_person": 3,
  "daily_admit": 0,
  "daily_emails_max": 25
}
```

- No row means `open`. Deploying the code changes nothing until an owner sets `invite_only`.
- Owners read and change it at `GET` / `PUT /v1/admin/signup-gate`. The hook sees a change within
  15 seconds.
- `opens_at`: from that moment the gate counts as open, whatever `mode` says. So it can open by
  itself at 12:01 am San Francisco on launch day.

**Opening on launch day:** Admin → Waitlist → Open Sign-Up (or `scripts/waitlist.sh open`, or the
time set ahead). No deploy and no app build. Apps drop the "by invitation" line the next time they
read `/v1/config`; `casama.ai/get/start` follows the gate by itself (§12).

---

## 4. Who is already in

- **The 17 existing accounts:** the hook runs only when an account is being made. Signing in by
  any method never reaches it. A test signs an existing account in with the gate on.
- **`review@casama.ai`:** an existing account that signs in by password. Before the gate goes on,
  check once that it still signs in on production.
- **People invited to a workspace:** rule 2 in §2.1. Production has none pending today.
- **Someone who deletes their account and comes back:** their entry stays `joined`, so they can
  sign up again.
- **The team and friends:** added by hand (`scripts/waitlist.sh add <email>`, later Admin), which
  admits without the waitlist.

---

## 5. The waitlist

### 5.1 Where entries live

In our database, not in Resend. The hook has to read it, Resend's free plan stops at 1,000
contacts, and that list is the newsletter's.

One migration (Phase 1):

- **`waitlist_entries`**: `email`, `email_key` (the normalised-email hash of D-333, unique),
  `status` (`waiting`, `admitted`, `joined`; removing deletes the row), `source` (the page or app it came from),
  `ref` (campaign tag from the link), `self_hosting`, `note` (one optional line, 280 characters),
  `newsletter_opt_in` with the time and the wording version, `priority`, `admitted_at`,
  `admitted_via` (`batch`, `auto`, `admin`, `campaign:<code>`, `invite:<user>`), `invite_code`,
  `notified_at`, `user_id`, `joined_at`, `ip_hash` (keyed hash, cleared after 30 days),
  `created_at`.
- **`invite_campaigns`**: `code`, `label`, `max_uses`, `used`, `per_day`, `starts_at`,
  `expires_at`, `disabled_at`, `created_by`.
- **`referral_codes.invite_bonus`**: extra invites for one person, on top of the setting.

RLS is on with no policy for `anon` or `authenticated` (only the API reads them), plus
`public.allow_worker`. The functions that admit, claim and count are security definer and granted
to nobody but the API's role and, where needed, the worker.

### 5.2 Where people join

- **casama.ai/waitlist** (new page, in the casama.link look, D-319).
- **Every "Start free" button** on casama.ai, the pricing section and the generated pages, through
  `/get/start` (§12).
- **The invite pages** `casama.ai/invite/<code>` and `casama.ai/i/<code>` (§7).
- **In the app** (Phase 2), as native Flutter screens on the sign-in screen. No WebView.

The form: email; one optional line, "What would you have a bot do first?"; a box "I run Casama on
my own server"; an unticked box "Also send me Casama's monthly email (once a month at most)". Below
it: "Have an invite code?".

### 5.3 The routes

Signed out, each needs a solved sign-up puzzle (the proof of work of D-094, single use):

| Route | Does | Answers |
|---|---|---|
| `POST /v1/waitlist` | Adds the address, or does nothing if it's there | Always the same "You're on the list", whether the address is new, already waiting, already in, or has an account. Nothing can be probed |
| `POST /v1/waitlist/redeem` | Claims an invite code for an address (§7) | Admitted; or code not found; or code used up (the address is put on the list, near the front). An address that has an account or is already let in gets the answer a stranger would get for that code and uses up nothing, unless this code let it in; joining likewise adds no row for an existing account. Nothing can be probed |
| `GET /v1/invites/preview?code=` | What the invite page shows: the inviter's first name or the campaign's label, and whether invites are left | D-211's `/v1/referral/preview` stays for shipped apps |
| `POST /v1/waitlist/leave` | Removes the address, from a signed link in the email | Done |

Owner only: `GET /v1/admin/waitlist` (counts and a page of entries, filtered by status, source,
self-hosting, text), `POST /v1/admin/waitlist/admit` (chosen entries, or the next N by the order in
§6.1), `POST /v1/admin/waitlist/entries` (add and admit addresses by hand), `DELETE …/entries/{id}`,
`GET` / `POST` / `PATCH /v1/admin/invite-campaigns`, `GET` / `PUT /v1/admin/signup-gate`.

### 5.4 After joining

The page (and the app screen) changes to:

> **You're on the list.** We're letting people in every day. You'll get one email when it's your
> turn, and nothing else unless you asked for the monthly email.
>
> Have an invite code? Enter it here.
>
> Don't want to wait? Casama is open source. Run it on your own computer today.

No position number (§7.5). No confirmation email: both mail services stop at 100 a day, and the
address proves itself when the person signs in.

### 5.5 The monthly email

Joining the waitlist is not consent to the newsletter. The box is unticked, and its wording and the
time are stored. A yes is applied when the person first signs in: by then the address is verified,
so D-408's path subscribes it with no confirmation email (`signup_source` `waitlist`). Someone who
never gets in is never subscribed. The alternative, sending D-404's confirmation email at once,
needs a paid Resend plan before Hacker News day, because confirmations count against 100 a day.

### 5.6 Privacy

The privacy page gains a short section in the same change: what the waitlist keeps (the address,
the optional line, the page it came from, the self-hosting box), why, that entries of people who
never join are deleted 90 days after public launch, and how to be removed (the link in the email,
or hello@casama.ai). Removing deletes the row.

---

## 6. Letting people in

### 6.1 By hand first (Phase 1)

Oliver, or an agent he asks, runs `scripts/waitlist.sh admit 25` or picks entries. The order for
"the next N": people whose code had run out first, then self-hosters (§8), then people who wrote
the optional line, then oldest first. Filters override it (for example "everyone from the Hacker
News link").

Being let in means: status `admitted`, and one "You're in" email, sent by the worker through the
server's mail sender (ZeptoMail). The email says to sign in with this address (Google, Apple and the email link all
work for it), has one button that opens the app or the web app (D-326), the download links, and a
"remove me" link.

### 6.2 The mail budget

- "You're in" emails are capped by `daily_emails_max`, 25 while ZeptoMail is capped at 100. The
  worker sends them a few a minute. An entry becomes `admitted` when its email goes out, so nobody
  is in without being told, and the day's number holds.
- 25 new people cause about 25 "you're in" emails plus about 9 sign-in links (two in three use
  Google or Apple). That leaves about 65 emails a day for existing members.
- Code claims (§7) send no "you're in" email: the page tells the person at once.
- Hand-added addresses can skip the email ("I told them myself").
- When KYC passes, raise the number in the setting: 100 to 300 a day costs cents.

### 6.3 Capacity

The server runs about 9 computers at once. An estimate, not a measurement: if an active person
keeps a computer awake for 20 minutes during a 5-hour evening peak, 150 active people need 10
computers at once (150 × 20 ÷ 300). If one account in three is active on a given day, that is
about **400 to 450 accounts on the current server**. The 100 to 300 planned by early December fit.

The number to watch is real, not estimated: the most computers running at once each day. The rule:
stop admitting when the peak reaches 7 of 9 on three days, and move to the larger server
(`docs/COSTS.md`: about €159 a month, about 28 computers).

### 6.4 The daily automatic batch (Phase 3)

Once a day at a set hour the worker admits `min(daily_admit, mail left today)` people in the order
of §6.1. It skips the day, and sends the owner a push saying why, when:

- yesterday's peak was 7 or more of 9 computers, or
- yesterday's model spend on Casama's key passed 60% of the OpenRouter daily cap ($30 of $50).

`daily_admit` is 0 until Oliver sets it. Hand batches keep working beside it.

---

## 7. Invite codes

One system, built on D-211. This plan amends D-211's "nothing is gated" for the launch period only.

### 7.1 Personal invites

- A member's invite code is their existing 6-character referral code. No second code.
- Each member has `invites_per_person` invites (3), plus any bonus given by hand. They unlock after
  the member's first finished chat (the `first_value` milestone), so only people who actually use
  Casama hand them out.
- A friend opens the link, sees "<Name> invited you to Casama", types their email, and is in at
  once. No email is sent. The page says "You're in. Sign in with <email>."
- The referral is attached when that friend signs up (a worker sweep each minute, beside the
  reward sweep). The friend's claim on the page is their choice, so no second tap is needed. D-211's
  $2 and $2 then follow after the friend's first chat, as today.
- **The link:** while the gate is on, production sets `REFERRAL_LINK_BASE=https://casama.ai/invite`.
  Shipped apps share whatever link the server gives them, so their Share button starts sending the
  new page with no app build. `/invite/…` is not an app link, so it always opens the web page;
  `/i/<code>` would open the installed app's old invite screen, which has no claim step.
  `casama.ai/i/<code>` on the web gets the claim form too.
- Build 44's Invite Friends screen shows the code and the credits but not "2 of 3 left". The page
  shows it; the app shows it from Phase 2.

### 7.2 Campaign codes

- Made by an owner: a code, a label, a total, an optional number per day, a start and an expiry.
  For example `SHOWHN-DEC8`, 200 uses, ends 15 Dec. The link is `casama.ai/invite/SHOWHN-DEC8`.
- A campaign code has 9 or more characters or a hyphen, so it can never look like a 6-character
  personal code or an 8-character workspace code.
- The count goes up inside the same statement that admits, so the last place can't be given twice.

### 7.3 Codes in the app (Phase 2)

- **I Have an Invite** on the sign-in screen: code, then email, then the sign-in buttons.
- For email and password sign-ups the code also rides in the sign-up's metadata, and the hook
  admits on the spot (rule 4 in §2.1).
- For Apple and Google the app gets the ID token from the native sheet first and sends it with the
  code to `POST /v1/waitlist/redeem`. The server checks the token against Apple's or Google's keys
  and admits the address inside it. That is how a "Hide My Email" address gets in.
- A "You're in" email carries a one-time code for the same purpose, for people let in from the
  list who want to sign in with a different address.

### 7.4 When a code runs out

Used up, past its day's number or expired: the page says "These invites are gone", keeps the email
the person typed, and puts them on the waitlist with the code as their tag and a higher priority.
They are first in the next batch. Admissions themselves don't expire in this version.

### 7.5 Does referring move you up?

Recommended: **no**, and no position number.

- A "share to move up" loop only works if joins are verified, which means a confirmation email per
  join, which neither mail service can send in volume yet. Unverified, it is trivially gamed.
- Apple's rules don't allow making people invite others to get in (§9), so it could never be in
  the app.
- A position number invites support mail ("why did I move back?").
- The viral part comes from members' 3 invites instead, which are scarce and cost nothing to verify.

---

## 8. Self-hosters and Casama Link

**The problem.** Casama Link (a `casama.link` address and notifications in the store apps) needs a
Casama Cloud account (D-296). The Show HN draft says Link is free. With the gate on, someone who
installs Casama from the Hacker News post can't get an account to link, and will say so.

**Recommended.** One public campaign code for self-hosters, printed in the Show HN post and on the
docs page "Use your server on your phone", with a number per day that Oliver sets. It is the same
mechanism as any campaign code, so it needs no extra build. People who aren't self-hosting can use
it too; the daily number is what bounds it. The "I run my own server" box on the waitlist form
puts everyone else who self-hosts ahead in the batches.

**The numbers follow the server.** On Hacker News day people arrive in a burst: 60 new people in
two hours, each keeping a computer for 15 minutes, is about 7 or 8 computers at once on top of
existing use. So:

| Server | Code on 8 Dec | After |
|---|---|---|
| Current (about 9 computers) | 60 | 30 a day |
| Larger (about 28 computers) | 200 | 100 a day |

While ZeptoMail is capped, a day's number above about 60 risks the mail cap, because one in three
claimers signs in by email link.

**Later, if it becomes a complaint:** an account type that can link a server but can't run bots on
Cloud. Not in this plan.

---

## 9. App Store and Google Play review

Checked on 2026-11-19 against Apple's App Review Guidelines page and Google's Play Console help.
Neither has a rule that names invitations or waitlists. The rules that apply:

| Rule | What it says | What the gate needs |
|---|---|---|
| Apple 2.1(a) | "include demo account info (and turn on your back-end service!) if your app includes a login" | `review@casama.ai` keeps working (§4). It signs in by password and never meets the gate |
| Apple, Before You Submit | "Provide App Review with full access to your app… provide either an active demo account or fully-featured demo mode" | The same account; the review notes say how |
| Apple 2.2 | "Demos, betas, and trial versions of your app don't belong on the App Store – use TestFlight instead" | **Never the word "beta"**: not in the app, the listing, the screenshots, the notes, or casama.ai. "Invite-only for now" |
| Apple 3.2.2 | Lists "arbitrarily restricting who may use the app, such as by location or carrier" as unacceptable (read from a summary of the page, not word for word: re-read it before submitting) | The app is open to anyone with their own server, and the hosted service lets people in as capacity grows. The notes say both |
| Apple 3.2.2 | Apps must not force people to take store-related actions to get in; inviting friends isn't core functionality (5.1.1(v)) | No "invite friends to get in" in the app (§7.5) |
| Apple 4.8, 5.1.1(v) | Sign in with Apple offered; account deletion in the app | Both already there. A reviewer who tries a new Apple sign-in is refused like anyone else, so the notes carry a reviewer invite code |
| Play, Sign-in details | "you must provide the necessary information for our team to log in and access all app functionality"; details "must be accessible at all times, reusable, and valid regardless of user location" | The same account and password, entered under App content → Sign-in details, with "new accounts are by invitation; use these details" in the instructions field |
| Play, Broken functionality | No apps that install but don't load or respond | The sign-in screen works and says plainly that Cloud is invite-only |

Invite-only apps have been on the App Store before (Clubhouse in 2020 and 2021, Bluesky in 2023 and
2024). Apple still decides each review on its own.

**What to prepare:**

- `client/store/app_store/review_notes.txt` gains a paragraph: Casama Cloud, our hosted service,
  is letting new accounts in by invitation while we add capacity; the demo account has full
  access; to make a new account with any sign-in method, use the invite code `APPREVIEW-…`; the
  app also works with a server someone runs themselves, which needs no invite.
- A campaign code for reviewers with a small total.
- One sentence at the top of both store descriptions: "Casama Cloud is invite-only for now: join
  the waitlist in the app or at casama.ai. Running Casama on your own server is open to everyone."
  It keeps "I can't sign up" out of the first reviews.
- The App Store's first submission should carry the Phase 2 screens (build 46 or later). In build
  44 a reviewer who taps sign-up gets a toast with a web address, which is a weaker thing to show
  a first review.
- If Apple still objects: answer with the notes and the demo account. The fallback is opening the
  gate earlier than planned, which is one setting.

---

## 10. Abuse

| Risk | Answer |
|---|---|
| Scripted waitlist joins | A solved puzzle per join (1 to 2 seconds of work, single use), 5 joins per address per 10 minutes and 30 a day, a keyed hash of the address kept 30 days. The puzzle's difficulty is the server's `SIGNUP_POW_DIFFICULTY`. Joining sends no email, so the list can't be used to mail-bomb anyone, and a fake entry costs nothing until it is let in |
| Throwaway addresses | A vendored open list of disposable-mail domains, checked on join and on claim ("Use a permanent email address"). "+tags" and Gmail dots collapse to one entry (D-333's hash) |
| Code guessing | A puzzle per try, plus the existing limit of 10 wrong codes per caller per 10 minutes, with callers told apart by `cf-connecting-ip` (the fix from D-211's audit). Personal codes: about a billion combinations against a few hundred live codes. Campaign codes are public by design and bounded by their totals |
| Mail to strangers | The only email to an unverified address is one "You're in", once per address, with a remove link |
| Workspace invites as a way round | The free-seat rule (§2.1). Check whether invite emails per workspace per day are already limited; if not, limit them, because each one also costs a ZeptoMail email |
| Finding out who is on the list or has an account | Join answers the same thing every time. Claim says only whether the code worked |
| Calling the database directly | The new functions are executable by the API only; a pgTAP test checks each one |
| Invite credit farming | Unchanged from D-211, and smaller under a gate: each fake friend now uses up one of 3 invites |
| Owner routes | `requireOwner`, and the cross-tenant route sweep covers them |

---

## 11. Numbers to watch

**The funnel:** joined the waitlist → let in → signed up → first finished chat, split by source
(page, campaign code, personal invite, self-hosting).

- **Where Oliver reads it, Phase 1:** `scripts/waitlist.sh stats` prints the funnel by source,
  today and in total, with "you're in" emails sent today, yesterday's peak computers and
  yesterday's model spend.
- **Phase 2:** the same as a card, Admin → Waitlist, with the Admit button beside the numbers that
  decide it.
- **Phase 3:** events into PostHog and GA4 through the catalog
  (`packages/contracts/analytics/catalog.json`): `waitlist_joined`, `invite_claimed`,
  `waitlist_admitted`, `signup_refused`; and `admitted_via` on the existing sign-up and first-chat
  events. No email address in any event. The website funnel (D-398) gains `waitlist_view` and
  `waitlist_join`. A PostHog dashboard "Casama: Waitlist", made only with Oliver's yes.

The database is the truth; the analytics tools are for trends.

---

## 12. Copy and pages

One line everywhere: **"Casama Cloud is invite-only for now."** With it, wherever there is room:
"Running Casama on your own server is open to everyone."

| Place | Change |
|---|---|
| casama.ai header | "Open app" becomes "Sign in" (people with an account) |
| Home hero, final call to action | "Join the waitlist" first, "Run it yourself" second |
| Pricing section and pricing pages | Plan buttons become "Join the waitlist"; one line above the table |
| Generated pages (`cta` shortcode in `site/build.mjs`) | The button text and target change in one place |
| `/get/start` | Follows the gate: the waitlist page while it's on, the app (or a store) when it's off. The Worker reads `/v1/config`, cached for a minute |
| `/download` | Store badges stay. One line says Cloud is invite-only and self-hosting is open |
| `/waitlist` (new) | §5.2, §5.4 |
| `/invite/<code>` (new), `/i/<code>` | §7 |
| FAQ and Help | "Why is Casama Cloud invite-only?", "How do I get an invite?", "I have a code" |
| Docs | A short guide page "Getting an invite"; a note on the Casama Link and remote access pages (§8); `/v1/config`'s new fields in `docs-site/develop/api.md`; `SIGNUP_WAITLIST` in the self-hosting settings list, marked as something a self-hosted server leaves alone |
| App (Phase 2) | Sign-in screen: the line, "Join the Waitlist", "I Have an Invite". Buttons in Title Case |
| Store listings | The sentence in §9, in `client/store/` |
| Launch drafts (`docs/launch/`) | The Show HN draft gains the self-hoster code line. Posting stays Oliver's call |
| Casama Help | Knows the gate, and can tell a member how many invites they have left (extends `get_invites`, D-308) |
| Emails | "You're in", in the branded template |

Site pages follow the casama.link look (D-319): plain background, Google Sans, Libre Baskerville
for the headings that use it today.

The button text is static HTML, so "Join the waitlist" turns back into "Start free" with the
launch-day site deploy. Until that deploy lands, `/get/start` already sends people to the right
place.

---

## 13. Costs

No new paid service. `docs/COSTS.md` changes in the same commit as Phase 1:

- **"You're in" emails:** ZeptoMail at $0.00025 each. 1,000 people cost $0.25. A note on the 100 a
  day cap and the number in the setting.
- **Invite credits (D-211, unchanged), worst case under the gate:** a friend who finishes a first
  chat brings up to $4 of credits ($2 each), about $2.92 of real model spend if both spend it all.
  With 3 invites, one member can cause at most $12 of credits, about $8.76 real. If 300 members
  each use all 3 invites and every credit is spent, that is 900 friends and about $2,630, spread
  over however long the credits last. Free credits are rarely spent in full, so expect a fraction.
- **Against the $50 a day OpenRouter cap:** the cap bounds model spend at $50 a day, about $1,500
  a month, whatever credits exist. The danger runs the other way: new people spending free credits
  can use up the day's cap and stop model calls for paying workspaces. One new person spending
  everything on day one ($1 from the plan, $2 welcome) is $2.19 at OpenRouter; 23 of them are $50.
  At a more usual $0.30 each on day one, 60 new people are $18. Hence: 50 admissions a day or
  fewer until the cap is raised, the pause rule in §6.4, and a recommendation to raise the cap to
  $100 before 8 Dec (Oliver's call).
- **The server:** not a cost of this plan, but the gate's numbers depend on it (§8).
- **Resend:** nothing changes. A launch-day email to the whole list would need a paid plan; §16
  avoids it.
- **Analytics:** four new events, once per person. Negligible.

Nothing new needs a `usage_ledger` kind: email isn't metered there today.

---

## 14. Tests

| Where | What |
|---|---|
| `apps/server/test/waitlist.test.ts` | The hook: feature off and gate open behave as today; gate on refuses a stranger and allows an admitted address, an invited address with a free seat (and refuses without one), an allowlisted address; "+tag" and capital letters match; the Apple relay sentence; refuses when the setting can't be read; an unsigned call is refused; the proof check still runs after the rule. `/v1/config` with the gate on, open and off. An existing account signs in with the gate on. Join: one entry per person, puzzle required and single use, limits, disposable domains, the same answer every time. Claim: personal codes (invites left, locked before the first chat, bonus), campaign codes (total, per day, expiry, twenty claims racing for the last place admit exactly one), used-up codes put the person on the list with a tag. Batches: order, one email each, the day's mail number. The referral attaches at sign-up and the reward follows. The newsletter yes is applied at first sign-in. The leave link. `opens_at` |
| Real Auth on the local stack, hook on | The five facts in §17, before anything else is built |
| `packages/contracts/test/events.test.ts` | The four signed-out routes join the list of routes with no 401, each with its reason. The analytics catalog test covers the new events |
| `apps/server/test/security.test.ts` | The owner routes in the cross-tenant sweep |
| `supabase/tests/waitlist_rls.test.sql` | `anon` and `authenticated` can read and write nothing; the worker policy exists (`worker_role_rls.test.sql` stays green); no new function is executable by `anon` or `authenticated` |
| Migration | The version checked as in the Execution brief |
| `scripts/site-waitlist.test.mjs` | `/get/start` follows the gate; the invite page's states; `node site/build.mjs --check` |
| `client/test/waitlist_test.dart` (Phase 2) | The sign-in screen with the gate on and off; join; code entry for each sign-in method; the refusal sheet; invites left; Admin → Waitlist. `flutter analyze` |
| Full suites | Once at the end of each phase: `scripts/heavy.sh pnpm test`, `scripts/heavy.sh pnpm --filter @casama/db test:pgtap`, `scripts/heavy.sh pnpm typecheck`, `scripts/heavy.sh sh -c 'cd client && flutter analyze && flutter test'` |

---

## 15. Phases

### Phase 1: the gate, server and site (about 3 working days; no app build)

1. Prove the five facts in §17 on the local stack with the hook on.
2. The migration (§5.1), `SIGNUP_WAITLIST`, the `signup_gate` setting and its owner routes.
3. The rule in the hook (§2.1, without rule 4) and the `/v1/config` fields.
4. The waitlist and claim routes, the owner routes, the "You're in" email, the referral sweep.
5. `scripts/waitlist.sh`: `stats`, `list`, `admit`, `add`, `code create|list|disable`, `on`, `open`.
   It calls the owner routes as the signed-in owner.
6. casama.ai: `/waitlist`, `/invite/<code>`, the claim form on `/i/<code>`, `/get/start` following
   the gate, the buttons, the FAQ, the privacy section. Docs. `docs/COSTS.md`. The store text.
7. Tests, then the full suites.

**Done when,** on the local stack with real Auth: a stranger is refused by email link, password,
Google and the CLI, and no email was sent; an admitted address gets in by email link and by Google;
a campaign code admits exactly its total; an existing account signs in; setting `open` lets
everyone in within 15 seconds; a self-hosted configuration answers exactly as before.

**Going live (each step needs Oliver's yes):** push; `scripts/deploy-prod.sh --dry-run`, then
`--yes`; the casama.ai deploy; `REFERRAL_LINK_BASE` on the server; check `review@casama.ai` signs
in; then `scripts/waitlist.sh on`.

**With the shipped apps (build 44, web 45):** the "by invitation" line and our sentence. Nothing
breaks; it is plain rather than polished.

### Phase 2: in the app (about 3 days; build 46)

1. Sign-in screen: the invite-only line, **Join the Waitlist** and **I Have an Invite** as native
   screens; a sheet instead of a toast when a sign-up is refused.
2. Codes at sign-up for every method, including Apple "Hide My Email" (§7.3); the one-time code in
   the "You're in" email.
3. Invite Friends shows invites left.
4. Admin → Waitlist: the numbers, Admit, add by hand, campaign codes, the switch and the opening
   time.

**Done when:** the Flutter tests pass and the flows work on the local stack.

**Shipping:** the web app first (a Flutter build and `scripts/deploy-app-web.sh`: ask), which gives
Oliver Admin → Waitlist on any device. Store builds 46 when Oliver asks. Item 2's Apple part can
slip past 8 Dec without hurting the Hacker News day, whose readers mostly arrive on the web.

### Phase 3: automatic batches and numbers (about 2 days; no app build)

The daily batch with its pause rules and the owner's push (§6.4); the events and website funnel
events (§11); the dashboard with Oliver's yes; Casama Help's invite answers.

**Done when:** a day's batch runs by itself on the local stack, stops at the mail number, and
skips with a push when either pause rule is met.

### Phase 4: launch day (about 1 day of work, spread out)

§16.

---

## 16. Opening on launch day

1. **5 to 11 Jan:** let the rest of the list in, in rising daily batches, so nobody is left
   waiting and no single mass email is needed. This needs ZeptoMail's cap lifted, and the server
   sized for it.
2. **Before 12 Jan:** set `opens_at` to 12:01 am San Francisco.
3. **At that time** the gate opens by itself. `/get/start` sends people to the app or the stores.
4. **Launch-day site deploy** (Oliver's yes): "Start free" back on the buttons, the launch copy.
5. `REFERRAL_LINK_BASE` back to `https://casama.ai/i`; `/invite/<code>` redirects there. Personal
   codes are plain D-211 referral codes again.
6. Store descriptions lose the invite-only sentence with the next update.
7. **90 days later:** entries of people who never joined are deleted.

The feature stays in the code, off, for the next time capacity is short.

---

## 17. Risks and things to prove first

**Five facts to prove against real Auth before building on them** (the unit tests call the hook
directly and can't show these). **All five were checked on 2026-11-19; the answers are in "Status
of the build".**

1. A refused email-link request sends no email.
2. What the app receives on a refusal: the HTTP status and whether our sentence arrives word for
   word. Supabase's docs disagree with themselves on 403; pick the status that passes the message
   through, and confirm build 44 shows it.
3. A new Apple or Google sign-in by ID token reaches the hook. So does the browser flow, and what
   the app shows when the browser comes back with an error.
4. Whether accounts made through Auth's admin API reach the hook, and that nothing of ours that
   uses it breaks.
5. Anonymous and phone sign-ups are off in production.

**Risks:**

| Risk | What limits it |
|---|---|
| ZeptoMail's review hasn't passed by 8 Dec | 25 emails a day for batches; the Hacker News code at 60 or under; Google and Apple sign-ins cost no mail |
| Hacker News day outruns 9 computers | The code's number (§8); the larger server if Oliver says yes. Worth checking separately: what a person sees today when no computer is free |
| The hook is slow or down | Auth gives it 5 seconds. The rule is two indexed lookups. If the API is down, sign-up fails, as it already does today |
| Apple rejects the first submission over the gate | §9: notes, demo account, reviewer code; the fallback is one setting |
| A member's shared link opens the old in-app invite screen | `REFERRAL_LINK_BASE` moves shared links to `/invite/…`; old `/i/…` links opened in build 44 end at the sentence, which names the page |
| People call it a beta | The copy never does (Apple 2.2) |
| Another session's migration lands first | Check the version right before naming |

---

## 18. Decisions for Oliver

Each has a recommendation. "Yes to all" adopts them.

1. **Dates.** Gate on about Wed 25 Nov; Hacker News Tue 8 Dec, 8:30 am New York; gate opens Tue 12
   Jan 2027, 12:01 am San Francisco. *Recommended: yes.* The plan only needs the first and last.
2. **The word.** "Invite-only", never "beta", everywhere including casama.ai. *Recommended: yes.*
   Apple's rule 2.2 turns away betas.
3. **Close sign-up today with the existing switch, until Phase 1 is live?** *Recommended: no.* 17
   accounts in a week is no load, and that switch's wording is written for self-hosted servers.
4. **How people are let in.** By hand until Phase 3, then a daily number you set, paused by itself
   when mail or capacity is short. Start at 25 a day. *Recommended: yes.* It matches the mail cap.
5. **How many.** About 300 by 7 Dec, and no more than about 400 on the current server.
   *Recommended: yes.* That is what 9 computers carry by the estimate in §6.3.
6. **The larger server (about €159 a month) before 8 Dec?** *Recommended: yes, decided by 1 Dec.*
   Hacker News day is the one day capacity can't be added afterwards; it also sets question 7.
7. **Self-hosters.** One public code in the Show HN post and the Link docs: 60 on the day and 30 a
   day after on the current server, or 200 and 100 on the larger one. *Recommended: yes.* Without
   it, "Link is free" isn't true for the people the post is written for.
8. **Invites per member.** 3, unlocked after a first finished chat. *Recommended: yes.* Scarce
   enough to mean something, and only real users hold them.
9. **D-211's credits during the gate.** Keep $2 for the inviter and $2 for the friend.
   *Recommended: keep.* Worst case is about $8.76 a member, and the first-chat condition pushes the
   number that matters.
10. **Referring moves you up the list? A position number? A public count?** *Recommended: no to
    all three for now.* Unverified joins make it gameable, and Apple doesn't allow it in the app.
11. **The form.** Email, one optional line ("What would you have a bot do first?"), and "I run
    Casama on my own server". *Recommended: yes.* It tells you who to let in first.
12. **The monthly-email box.** Unticked; a yes is applied when the person first signs in, with no
    confirmation email. *Recommended: yes.* The other way needs a paid Resend plan before 8 Dec.
13. **Workspace invites.** They let a new person past the gate only when the workspace has a free
    seat. *Recommended: yes.* Paying teams can add people; Free workspaces can't mint accounts.
14. **The app.** Phase 1 goes live on build 44 as it is; Phase 2 ships as build 46, web first; the
    App Store's first submission waits for build 46 and carries a reviewer code; both listings say
    invite-only. *Recommended: yes.*
15. **Admin.** A script first (you, or an agent you ask), then Admin → Waitlist with the web app
    deploy in Phase 2. *Recommended: yes.* It keeps Phase 1 free of any app build.
16. **Launch day.** The list is let in during the week before, and the gate opens by itself at the
    set time. No mass "we're open" email. *Recommended: yes.*
17. **Money and accounts.** Raise OpenRouter's daily cap to $100 before 8 Dec, and chase ZeptoMail's
    review. *Recommended: yes to both.* They are the two limits on how fast people can be let in.
18. **Keeping the list.** Entries of people who never join are deleted 90 days after public launch;
    the privacy page says so. *Recommended: yes.*

**Oliver's answers (2026-11-19):** "Yes to all!" Every recommendation above is adopted.

Three of them are things to do later, not now, and each still gets its own yes when the time
comes: the move to the larger server (6, decided by 1 Dec), raising OpenRouter's daily cap to $100
(17, when the gate goes on), and the App Store submission with build 46 (14).

---

## Status of the build

**2026-11-19: Phase 1 is built and tested locally. Nothing is committed, pushed or deployed, and
the gate is not on anywhere.** Phases 2 to 4 are not started.

### What was checked against real Auth (the five facts of §17)

Against a throwaway copy of the Auth service at production's version (GoTrue v2.197.0), and its
source at that tag:

1. **A refused email-link request sends no email.** 14 refusals sent none; one allowed request
   sent one.
2. **Auth passes the hook's sentence on word for word only when the hook answers HTTP 200** with
   `{"error": {"http_code": 403, "message": "…"}}`. The app then gets status 403 and the sentence.
   A hook that answers 403 itself reaches the app as `500 "Unexpected status code returned from
   hook: 403"`, and a 400 as "Invalid payload sent to hook". The hook answered 403 until now, so
   the reasons written for D-094, D-145 and D-296 never reached anyone. Fixed for all of them.
3. **Apple and Google reach the hook**, by ID token (`token_oidc.go`) and in the browser
   (`external.go`), but only when a new account would be made. What build 44 shows when the
   browser comes back with the error was not checked on a device.
4. **Accounts made with Auth's admin `POST /admin/users` skip the hook.** `/invite` and
   `generate_link` for a new address go through it. Nothing of ours makes accounts that way.
5. **Anonymous sign-ins are off** in production (Auth answers "Anonymous sign-ins are disabled"),
   and phone sign-up isn't configured.

Also: an email that already has an account never calls the hook, and what the app sends with a
sign-up reaches the hook in `user_metadata` (so Phase 2's code-at-sign-up works for email).

### What is built

- **Database:** `supabase/migrations/20270215100001_waitlist.sql` (`waitlist_entries`,
  `invite_campaigns`, `referral_codes.invite_bonus`, and the functions the hook, the claim and the
  worker use). `supabase/tests/waitlist_rls.test.sql`: 37 checks.
- **Server:** `apps/server/src/services/waitlist.ts`, `apps/server/src/api/routes/waitlist.ts`,
  the rule in `routes/abuse.ts`, the two fields in `/v1/config`, `invites` in `GET /v1/me/referral`,
  the worker loop in `main.ts`, `SIGNUP_WAITLIST` and `WAITLIST_URL` in `env.ts`.
  `apps/server/test/waitlist.test.ts`: 45 tests. Contracts, `openapi.json` and both generated
  clients are regenerated.
- **Owner's script:** `scripts/waitlist.sh` (every command tried against a stub server).
- **casama.ai:** `/waitlist`, `/invite/<code>`, the claim form on `/i/<code>` while the gate is on,
  `/waitlist/leave`, `/get/start` following the gate, the buttons, three FAQ entries, the privacy
  section. `scripts/site-waitlist.test.mjs`: 18 tests. **Not yet seen in a browser.**
- **Docs:** the guide page "Getting an invite", the API and settings pages, the Casama Link notes,
  `docs/COSTS.md`, `CHANGELOG.md`, D-427.

**Phase 2 and 3 (built 2026-11-19, not deployed, no app build yet):**

- **Server:** rule 4 in the hook (`user_metadata.invite_code`, claimed after the sign-up proof is
  checked, so Auth's sign-up can't spend codes without the puzzle); `POST /v1/waitlist/redeem` with
  an Apple or Google ID token (`services/id-token.ts`: signature against the provider's keys,
  issuer, expiry, the audiences Auth accepts, nonce as sha256 of the raw one); a one-time code
  `XXXX-XXXX` in each "You're in" email, kept as a hash, good for one more address (kind
  `one_time`); the daily batch at `batch_hour_utc` (default 15) that admits
  `min(daily_admit, mail left)` once a day, or skips and pushes the owners when yesterday's
  computers passed 7/9 of their memory or model spend passed 60% of `OPENROUTER_DAILY_CAP_USD`
  (default 50); `last_batch` in the stats; events `waitlist_joined`, `invite_claimed`,
  `waitlist_admitted`, `signup_refused` and `admitted_via` on `signed_up` and `first_value`;
  website beacons `waitlist_view`, `waitlist_join`; Casama Help's `get_invites` knows the gate.
  Migration `20270217100001_waitlist_phase3.sql`, pgTAP `waitlist_phase3.test.sql` (24).
  `waitlist.test.ts`: 67 tests. Also fixed: the owners' lookup in `capacity.ts` and the suspension
  notice in `abuse.ts` used `any(${list})`, which fails whenever `INSTANCE_ADMIN_EMAILS` is set.
- **App:** the sign-in screen's line with **Join the Waitlist** and **I Have an Invite**
  (`client/lib/features/auth/invite_gate.dart`, `join_waitlist_sheet.dart`,
  `have_invite_sheet.dart`), the refusal sheet in place of the toast, codes at sign-up (email:
  claim plus `invite_code` metadata; Apple and Google: the native sheet's token is redeemed first,
  then the same token signs in), `/i/<code>` opened signed out goes to I Have an Invite, invites
  left in Invite Friends, Admin → Waitlist (`client/lib/features/admin/waitlist_tab.dart`).
  `client/test/waitlist_gate_test.dart`: 18 tests. **Never run on a device; Apple and Google tokens
  never tried for real.** Browser-based Apple/Google sign-in (web, Windows, Linux) shows the
  old message on refusal and offers Continue with Email in I Have an Invite.
- **Not done:** the PostHog dashboard (needs Oliver's yes), the Show HN draft line.
- **Invite pages, 2026-11-20 (Oliver: "build it"):** the claim form on `/invite/<code>`, `/i/<code>`
  and `/waitlist` has the monthly email box, unticked. A tick rides with the claim
  (`newsletter: true` on `/v1/waitlist/redeem`, which the server already kept) and becomes a
  subscription when that address signs up, so no confirmation email goes out. After "You're in",
  a link opened inside Instagram, Facebook, Threads, TikTok, X, LinkedIn, Snapchat or Line says
  Google sign-in doesn't work there and leads with Get the apps and a button that copies
  app.casama.ai (`embeddedBrowser` in `site/assets/waitlist.js`). Site only: no server change.
  Open Casama (and the copied link) is `app.casama.ai/#/sign-in?email=<the claimed address>`:
  the sign-in screen opens the ways in with the address typed in and sends nothing until the
  person presses (`SignInScreen.initialEmail`, `client/test/sign_in_email_link_test.dart`; from
  app build 57). The address rides after the `#`, so no server sees it.

### Where the build differs from the plan above

- **The allowlist** (`SIGNUP_ALLOWED_EMAILS`) is not an extra way in. Where a server sets it, it
  keeps deciding alone. Production doesn't set it.
- **The puzzle's difficulty** is the server's own (`SIGNUP_POW_DIFFICULTY`), not a number in the
  gate setting.
- **"You're in" emails** are sent by the worker loop straight through the mail sender, a few a
  minute, and counted on the entries themselves (`notified_at`), not through `email_outbox`.
- **No events yet.** Refusals and joins are counted in the database only; the analytics events are
  Phase 3, as planned.
- **Added, not in the plan:** an entry is in the account's data export, and when an account is
  deleted its entry keeps only the inbox's hash and how it got in (the address and the line the
  person wrote go), so the same inbox can still come back.
- **Left as it was on casama.ai:** the page descriptions and the pricing heading still say "Start
  free". The Free plan is real, and the line above the plans says Cloud is invite-only.

### Going live (each step needs Oliver's yes)

1. Look at the pages: `python3 scripts/serve-web.py`, then `localhost:8731/waitlist`.
2. Commit and push. Check the migration version is still the newest first.
3. `scripts/deploy-prod.sh --dry-run`, then `--yes`. Deploying changes nothing people can see: the
   gate is open until step 7.
4. On the server, `REFERRAL_LINK_BASE=https://casama.ai/invite` in `infra/compose/.env`, and
   restart the API.
5. Deploy casama.ai (`scripts/deploy-web.sh`, from a clean worktree of the live commit plus this
   change). From here the buttons say "Join the waitlist", and `/get/start` still opens the app
   until the gate is on.
6. Check `review@casama.ai` still signs in. Make the codes:
   `scripts/waitlist.sh code create <CODE> "Self-hosters" 60 --per-day 30` and
   `scripts/waitlist.sh code create <CODE> "App Review" 20`.
7. `scripts/waitlist.sh on`. Then try a stranger's sign-up on app.casama.ai (refused, with the
   sentence), a claim with the App Review code (let in), and `scripts/waitlist.sh stats`.
8. Raise OpenRouter's daily cap to $100. Put the self-hoster code on the remote-access docs page.

Steps 5 and 7 should happen close together, so the site doesn't promise a waitlist that isn't on.

**Done on 2026-11-19 (Oliver: "deploy all you need"):** steps 1–3 and 5–7. Phase 1 is 640a82c9 on
origin; the server, casama.ai, docs and gallery are deployed from it; the gate is on (invite_only,
`daily_admit` 0, `daily_emails_max` 25). A stranger's sign-up is refused with the sentence, existing
accounts sign in, and a claim on casama.ai/invite/<App Review code> answers "You're in". Codes:
`SELFHOST-2026` (Self-hosters, 60, 30 a day) and the App Review code (20; kept out of this public
repo, Oliver has it). Step 4 was skipped: production's compose file doesn't pass
`REFERRAL_LINK_BASE` through, and `/i/<code>` already shows the claim form while the gate is on.
Still to do: step 8, and the App Review paragraph in the store notes on the next submission.

### Store text, ready to paste when the gate is on (§9)

**Top of both store descriptions:**

> Casama Cloud is invite-only for now: join the waitlist in the app or at casama.ai. Running Casama
> on your own server is open to everyone.

**App Store review notes, a new paragraph after "SIGN IN WITH THE DEMO ACCOUNT":**

> NEW ACCOUNTS ARE BY INVITATION FOR NOW
> Casama Cloud, our hosted service, is letting new accounts in by invitation while we add capacity.
> The demo account above has full access and needs no invite. To make a new account with any
> sign-in method instead, open casama.ai/invite/<APP REVIEW CODE>, enter the email address you
> will sign in with, then sign in with that address in the app. The app also works with a Casama
> server that someone runs themselves, which needs no invite.

**Google Play, App content → Sign-in details → Any other instructions:**

> New accounts on Casama Cloud are by invitation for now. Use the email and password above: this
> account has full access and no code or email step is needed.

---

## Sources

Store rules, read 2026-11-19:

- Apple, App Review Guidelines: developer.apple.com/app-store/review/guidelines (2.1, 2.2 and
  2.3 word for word; 3.2.2, 4.8 and 5.1.1(v) from a summary of the same page).
- Apple, App Review: developer.apple.com/distribute/app-review.
- Google Play Console help, "Prepare your app for review":
  support.google.com/googleplay/android-developer/answer/9859455.
- Google Play Console help, "Requirements for providing sign in details for review":
  support.google.com/googleplay/android-developer/answer/15748846.
- Google Play, "Functionality, Content, and User Experience":
  support.google.com/googleplay/android-developer/answer/9898783.
- Supabase, Before User Created hook:
  supabase.com/docs/guides/auth/auth-hooks/before-user-created-hook.
