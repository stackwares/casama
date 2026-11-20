# Moving all mail to Amazon SES: plan

Status: **not started** (written 2026-11-20). Oliver: "we will in the future migrate all our mail
stuffs to using AWS SES so I want you to write the full plan. This includes our transactional
emails, our bot's emails at mail.casama.app and all other mail stuffs AWS SES can cover." No code,
no AWS account and no DNS change until Oliver answers §14 and says to start.

This plan replaces the infrastructure parts of `docs/BOT-EMAIL-PLAN.md` (its §5.1, §5.2, §6.4,
§6.5, §9, §10 and question 1 of its §13). That plan's product design (addresses, claiming, the
inbox, the tools, approvals, limits) stays as written.

## 0. Summary

Casama's mail runs on four services today. After this plan, one service sends and receives all of
it, and Zoho Mail keeps only the inboxes people read.

| Mail | Today | After |
|---|---|---|
| Sign-in links and codes (Supabase Auth) | ZeptoMail, over SMTP | SES, over SMTP |
| Invites, account emails, support, waitlist, vendor alerts (API and worker) | ZeptoMail, with Resend behind it | SES, with a backup behind it (§14 Q5) |
| Server alerts (alertmanager) and uptime alerts (the Worker) | ZeptoMail, over SMTP | SES, over SMTP |
| The monthly email | Resend: the list, the sending and the unsubscribe webhook, on an account shared with another product | SES: the list and the sending. Issues are written in the repository and sent by a script |
| Bot addresses (planned, not built) | Cloudflare Email Routing and Email Sending, on a bare domain not yet bought | SES receiving and sending on `mail.casama.app` |
| Bounces and complaints | In each vendor's dashboard. Nothing reaches Casama | One queue. Counts and alerts in Admin |
| People's inboxes (`hello@casama.ai` and its aliases) | Zoho Mail | Zoho Mail. SES has no mailboxes (§2) |

Why move, honestly:

- **It is not about money yet.** At today's volume every option costs cents. At 100,000 app
  emails a month SES costs about $10 and ZeptoMail $25 (§10).
- **No more caps and expiring credits.** ZeptoMail sells prepaid credits that expire after six
  months, and held the account to 100 emails a day during its review. Resend's free plan stops at
  100 a day. SES bills for what was sent.
- **One vendor can do bot mail on a subdomain.** Cloudflare's catch-all rule works only on a
  bare domain, so `mail.casama.app` can't receive there. SES receives on any domain or subdomain.
- **Receiving comes with checks.** SES reports SPF, DKIM, DMARC, spam and virus results for every
  mail it receives.
- **Mail that waits instead of getting lost.** Received mail and delivery events sit in a queue
  until the server takes them, so a deploy or an outage loses nothing.

What it costs us:

- An AWS account to run: keys, permissions, a review by AWS before it may send to anyone.
- Receiving mail costs money (about $0.10 per 1,000), spam included. Cloudflare's was free.
- The monthly email loses Resend's editor. Issues become Markdown files and a send script.
- SES can't refuse an unknown bot address while the sending server is still connected (§7.3).

Five phases (§11). Phase 0 (the account, AWS's review, a proof of each path) has waiting time and
costs nothing, so it can be done early. Nothing in production changes before Phase 1.

## 1. What exists today

### 1.1 Who sends what

Checked in the code and in DNS on 2026-11-20.

| Mail | Sent by | Through | From |
|---|---|---|---|
| Sign-in links, confirmations, password resets, email changes | Supabase Auth (`GOTRUE_SMTP_*` in `infra/compose/docker-compose.yml:400`) | ZeptoMail SMTP (D-318). Moves to Resend SMTP by hand (D-433) | `hello@notify.casama.ai` |
| Invites | API (`apps/server/src/api/routes/joining.ts`) | The server's sender (`emailFromEnv`, `apps/server/src/main.ts:182`): ZeptoMail SMTP, then Resend by itself when it fails | `hello@notify.casama.ai` |
| Billing changes, the welcome series, domain notices (D-302), waitlist "You're in" | Worker, from `public.email_outbox` (`services/account-emails.ts:678`) | Same sender | `hello@notify.casama.ai` |
| Support messages and their copies (D-298), reports (D-301), vendor alerts | API and worker (`routes/support.ts`, `routes/moderation.ts`, `services/vendors/sweep.ts`) | Same sender | `hello@notify.casama.ai` |
| Prometheus alerts | alertmanager (`docker-compose.yml:800`) | The same `SMTP_*` settings as Auth | `hello@notify.casama.ai` |
| "Casama is down" and "back up" | The `casama-uptime` Worker, with its own small SMTP client (`infra/uptime/uptime.js:31`) | ZeptoMail SMTP, port 465 | `status@notify.casama.ai` |
| The monthly email: confirmation, welcome, issues (D-404, D-408) | The `casama-site` Worker (`site/newsletter.js`), the server (`services/newsletter.ts`), and broadcasts made in Resend | Resend, on the account shared with sayainvitations.com | `news@news.casama.ai` |
| Replies to app mail | Cloudflare Email Routing on `notify.casama.ai` forwards `hello@` and `status@` to the Zoho inbox | Cloudflare | |
| People's inboxes | Zoho Mail (`hello@casama.ai`, with aliases such as `review@`) | Zoho | `casama.ai` |
| The email chat app (D-270, D-342) | Each workspace's **own** Resend account and domain (`packages/agent/src/channels/adapters.ts:565`) | Theirs, not ours | Theirs |

Local development: Auth mail goes to Mailpit. The local server's own mail still goes out through
ZeptoMail.

### 1.2 DNS today

| Name | Records that matter |
|---|---|
| `casama.ai` | MX Zoho. SPF Zoho. DMARC `p=none`, no report address |
| `notify.casama.ai` | MX Cloudflare (Email Routing). SPF ZeptoMail + Cloudflare. DKIM for ZeptoMail (`1518530._domainkey`) and Resend (`resend._domainkey`). Return paths `bounce-zem.notify` (ZeptoMail) and `send.notify` (Resend). No DMARC record of its own, so `casama.ai`'s `p=none` applies |
| `news.casama.ai` | DKIM and return path for Resend. DMARC `p=none`, reports to `hello@casama.ai` |
| `casama.app` | On Cloudflare. MX Cloudflare (Email Routing on the bare domain). DMARC **`p=reject`**, which its subdomains inherit |
| `mail.casama.app` | Nothing yet |

Two things this shows:

- Resend's return path points at `feedback-smtp.us-east-1.amazonses.com`. **Resend itself sends
  through Amazon SES in us-east-1.** A backup on Resend is a different AWS account from ours, but
  not different infrastructure (§4.2, §14 Q5).
- Mail from `mail.casama.app` must pass DMARC from the first message, because the parent domain
  already says "reject what fails".

### 1.3 What nobody handles today

- Bounces and complaints stay in the vendors' dashboards. The server never learns that an
  address is dead, except that ZeptoMail quietly stops sending to it.
- There is no AWS account. The vault has no item for one (searched "aws" and "amazon" by name),
  and the `aws` command isn't installed on this Mac.
- The server already knows AWS a little: content keys can come from AWS KMS
  (`apps/server/src/content-keys.ts`), and `packages/sandbox` uses the S3 client.

## 2. What SES covers, and what it doesn't

| Need | SES | Notes |
|---|---|---|
| Sending app mail over SMTP | Yes | Ports 587 and 465. Auth and alertmanager need nothing but new settings |
| Sending over an API | Yes | Returns a message ID, takes a configuration set and a tenant |
| Receiving mail for a domain or subdomain | Yes | Up to 40 MB a mail. Stored in S3, announced through SNS |
| SPF, DKIM, DMARC, spam and virus results on received mail | Yes | Reported, never acted on. Acting is our job (§7.2) |
| Bounces, complaints, deliveries as events | Yes | Through a configuration set, to SNS, then a queue |
| A list of people who must not be mailed again | Yes | Hard bounces and complaints, for the account or per tenant |
| A subscriber list with topics | Yes, small | **One list per account**, 20 topics. No editor, no scheduling |
| Keeping one sender's trouble away from the others | Yes | Tenants: each has its own reputation and can be paused alone |
| Inboxes people log in to | **No** | SES has no mailboxes, IMAP or webmail. AWS's mailbox product, WorkMail, closed to new customers on 2026-04-30 and ends on 2027-03-31; AWS points its users to Zoho Mail among others. **Zoho stays** |
| Forwarding `hello@notify.casama.ai` to a person's inbox | Not by itself | It would need our own forwarder. **Cloudflare Email Routing stays** for this |
| Refusing an unknown address while the sender is still connected | No | Only whole IP ranges can be refused that early (§7.3) |
| A drag-and-drop newsletter editor | No | Issues are written as Markdown (§6) |

Also staying as they are, because they aren't ours to move:

- The email chat app with a workspace's own Resend account, and the gallery's Resend app.
- People's own Gmail and Zoho connections.
- Self-hosted servers: they keep `SMTP_*` or `RESEND_API_KEY`. SES works for them through the
  SMTP settings, and nothing in Casama requires AWS.
- Mail other companies send for us: store and Dodo receipts, the registrar's own confirmation
  emails, vendors' low-balance notices.

## 3. Principles

1. **Sign-in mail comes first.** It moves last, alone, at a quiet hour, with a tested way back.
2. **Nothing existing is removed until its replacement has run clean for 30 days.** New DNS
   records are added beside the old ones; SES's DKIM selectors live alongside ZeptoMail's and
   Resend's.
3. **Bot mail can't hurt sign-in mail.** It gets its own AWS account, not just its own domain
   (§4.1).
4. **The addresses people see don't change.** `hello@notify.casama.ai`, `status@notify.casama.ai`
   and `news@news.casama.ai` stay, so the domains keep the reputation they have.
5. **Each key can do one job.** The key in Auth can send from one address and nothing else.
6. **Self-hosters are untouched.** Every SES setting is optional and off by default.
7. **Secrets go to the vault in the same task**, never into chat, logs or commits.
8. **Every production step waits for Oliver's yes:** DNS, the VPS env, each deploy, each Worker
   secret, each newsletter send.

## 4. The AWS setup

### 4.1 Accounts

One AWS organization with a management account and two member accounts (recommended, §14 Q2):

| Account | Holds | Why separate |
|---|---|---|
| Management (Stackwares) | Billing, budgets, nothing else | The company's, so other Stackwares apps can get accounts later |
| `casama-mail` | `notify.casama.ai` and `news.casama.ai`: sign-in, account and monthly mail | The mail Casama can't run without |
| `casama-botmail` | `mail.casama.app`: bot mail in and out | Mail written by people's bots to strangers is the likeliest to draw complaints. AWS judges and pauses sending **per account**. A paused bot account leaves sign-in working |

Member accounts are free and need no second card. Each one goes through AWS's sending review on
its own (§4.5), so a slow or refused review of the bot account never holds up app mail.

Root users get MFA. Root logins, MFA seeds and backup codes go into Vaultwarden.

### 4.2 Region

**us-east-2 (Ohio)** for everything (recommended, §14 Q1).

- It supports receiving (22 regions do; us-east-1 and us-east-2 are both on the list).
- It is the closest to the server (Contabo, US Central).
- It is not us-east-1, where Resend's sending runs. If Resend stays as the backup, one region's
  outage can't stop both.

Everything SES needs for receiving (the topic, the queue) must be in the same region as the SES
endpoint. SMTP credentials are per region too.

### 4.3 Pricing mode

New SES accounts start on the **Essentials** plan since 2026-07-21: $0.16 per 1,000 emails, with
deliverability reports included. An account on the default can switch to **à la carte** at once:
$0.10 per 1,000, with each extra bought separately. À la carte is recommended (§14 Q4): we need
few extras, and tenants are sold à la carte for half a cent each.

### 4.4 Identities and DNS

All records are **added**; none is changed or removed until Phase 4. The DNS zones are on
Cloudflare.

| Domain | Account | Records to add |
|---|---|---|
| `notify.casama.ai` | `casama-mail` | 3 DKIM CNAMEs that SES hands out (`<token>._domainkey.notify`). A return path of its own: `bounce.notify` MX `10 feedback-smtp.us-east-2.amazonses.com` and TXT `v=spf1 include:amazonses.com ~all`. A DMARC record at `_dmarc.notify` |
| `news.casama.ai` | `casama-mail` | The same three kinds, on `news` and `bounce.news` |
| `mail.casama.app` | `casama-botmail` | 3 DKIM CNAMEs. Return path `bounce.mail`. **MX** `mail.casama.app` → `10 inbound-smtp.us-east-2.amazonaws.com` for receiving. DMARC at `_dmarc.mail`, with a report address |

Notes:

- Verifying a domain lets us send from any address at it. Easy DKIM uses a 2048-bit key.
- The return-path name must be used for nothing else, so it can't be `send.notify` (Resend's) or
  the domain that receives mail.
- Each domain gets a **default configuration set** (`app`, `news`, `bots`). Mail from the domain
  uses it without any header. This matters for Auth, which can't add custom headers.
- DMARC reports: turn on Cloudflare's DMARC Management for the `casama.ai` and `casama.app` zones.
  It is available on every plan, works on the bare domain, and adds its own report address.
- Add the three domains to Google Postmaster Tools to watch reputation at Gmail.

### 4.5 Leaving the sandbox

A new SES account is in a sandbox: 200 emails a day, one a second, and only to addresses we have
verified. Each account asks AWS for production access, once per region. AWS asks for the kind of
mail, the website, and how bounces and complaints are handled, and first answers within about
four days. It may ask more.

- `casama-mail`: transactional, casama.ai, sign-in and account mail people asked for, plus a
  double opt-in monthly email. The same story ZeptoMail's review accepted.
- `casama-botmail`: assistants that email on behalf of their owner. The request describes the
  approval on every first contact, the daily caps, the tenant per workspace and the automatic
  pause (§7.4). This one may be questioned or refused; §15 says what happens then.

The quota a new account starts with isn't published ("varies"). The waitlist's daily email cap
(`daily_emails_max`, 25 today because of ZeptoMail's review) is raised only after we see ours.

### 4.6 Keys

Long-lived keys, each with the smallest permission that works, each in Vaultwarden ("Keys &
Signing", named like "Casama · AWS SES SMTP (Auth, notify.casama.ai)").

| Key | Used by | May do |
|---|---|---|
| `casama-auth-smtp` (SMTP login) | Supabase Auth and alertmanager, through `SMTP_*` on the VPS | Send from `hello@notify.casama.ai` |
| `casama-server` | API and worker | Send from `notify.casama.ai` and `news.casama.ai`; read the events queue; read the sending quota; read and write the subscriber list |
| `casama-uptime` (SMTP login) | The `casama-uptime` Worker | Send from `status@notify.casama.ai` |
| `casama-site` | The `casama-site` Worker | Send from `news@news.casama.ai`; read and write the subscriber list |
| `casama-botmail` | API and worker | In the bot account: send from `mail.casama.app` as a tenant; make, pause and resume tenants; read both queues; read and delete in the inbound bucket; send bounces |
| `casama-ops` (one per account) | Setup scripts, run by Oliver or an agent on this Mac | Create and change the mail setup. Never on a server |

SMTP logins don't rotate by themselves. All keys are replaced every 90 days by a script
(`scripts/aws-mail.sh rotate`, with `--dry-run`), which writes the new value to the vault first.

### 4.7 Setup as files

- `infra/aws/mail-app.yml` and `infra/aws/mail-bots.yml`: CloudFormation templates for identities,
  configuration sets, event destinations, topics, queues, the inbound bucket, the receipt rule,
  the users and their policies, and the alarms.
- `scripts/aws-mail.sh`: `plan` shows the change set (the dry run), `apply --yes` runs it, `dns`
  prints (or with `--yes` creates) the Cloudflare records, `rotate` replaces keys, `inbound off`
  is the emergency switch for bot mail (§7.5).
- What CloudFormation can't do (to be found in Phase 0: tenants, activating the receipt rule set,
  the pricing mode) is done by the script with `aws sesv2` calls.

### 4.8 Watching it

- **Money:** an AWS budget on the organization with emails at $5, $20 and $50 to
  `alerts@casama.ai`.
- **Reputation:** alarms at a 2% bounce rate and a 0.05% complaint rate. AWS puts an account
  under review at 5% and 0.1%, and may pause it at 10% and 0.5%.
- **Queues:** an alarm when a message has waited 15 minutes, or when anything lands in a
  dead-letter queue.
- **Admin → Vendors** (`docs/VENDOR-USAGE-PLAN.md`): a new `ses` reader shows emails sent in the
  last 24 hours against the quota, the two rates, and whether sending is paused. The `zeptomail`
  and `resend` rows go away in Phase 4.
- Deliverability reports (Virtual Deliverability Manager, $0.07 per 1,000) on for the first 90
  days, to see inbox placement while the new sending path settles (§14 Q4).

## 5. App mail

### 5.1 Two ways in

| Sender | Path | Why |
|---|---|---|
| Supabase Auth, alertmanager, the uptime Worker | SES **SMTP** (`email-smtp.us-east-2.amazonaws.com`, 587 or 465) | They speak only SMTP. Settings change; no code |
| API and worker | SES **API** | It returns the message ID that ties a bounce to the email, and it lets server mail move before Auth does |

### 5.2 Code

- `apps/server/src/services/email.ts`: a third sender, `sesEmail`, beside `resendEmail` and
  `smtpEmail`. Same `EmailSender` interface, same skip for addresses that can't receive mail
  (`isUndeliverableAddress`), an injected `fetch` for tests. Requests are signed with `aws4fetch`
  (MIT, small, also runs in Workers), so the server needs no AWS SDK for mail.
- `apps/server/src/env.ts`: `SES_REGION`, `SES_ACCESS_KEY_ID`, `SES_SECRET_ACCESS_KEY`,
  `MAIL_EVENTS_QUEUE_URL`. All optional.
- `apps/server/src/main.ts` (`emailFromEnv`): SES when its settings are there, else Resend, else
  SMTP, as today. The backup wrapper (`withBackupEmail`) stays around whichever is first.
- `apps/server/src/services/vendors/count.ts`: `ses` joins the counted vendors, and `smtpVendor`
  recognizes `email-smtp.*.amazonaws.com`.
- Bounces and complaints: §8.
- Local development: the local server's mail goes to Mailpit, like Auth's. Real-send checks use
  SES's test addresses (`success@`, `bounce@`, `complaint@simulator.amazonses.com`), which never
  count against the rates.

### 5.3 The order of the switch

1. **Server mail.** Set `SES_*` on the VPS and deploy. Invites, account emails, support and
   alerts leave through SES. `SMTP_*` still points at ZeptoMail, so Auth is untouched. Resend
   stays behind it as the backup. Watch for a week.
2. **The uptime Worker.** New SMTP secrets (`wrangler secret put`), then its test mail.
3. **Sign-in mail.** Change `SMTP_HOST`, `SMTP_USER` and `SMTP_PASS` on the VPS to the SES SMTP
   login. Recreate `auth`, then **restart `kong`** (without it `auth.casama.ai` answers 502,
   D-318). alertmanager follows by itself: it reads the same settings. Send sign-in links to
   Gmail, Outlook, iCloud, Yahoo and Zoho test addresses and read the headers.

The way back from step 1 is to unset `SES_*`. From step 3 it is the `.env` backup, `auth`, `kong`.
Neither needs DNS, because ZeptoMail's records are still there.

`docs/EMAIL-RUNBOOK.md` is rewritten in the same change: signs SES is failing (the backup log
line, the account paused in Admin → Vendors, the AWS health page), the switch to the backup and
back.

## 6. The monthly email

### 6.1 The list

One SES contact list, `casama`, in the `casama-mail` account, with one topic, `updates`. A contact
holds the address, opted in or out of the topic, and where they signed up (today's
`signup_source`). SES allows only one list per account and 20 topics, which is enough.

| Today (Resend) | After (SES) |
|---|---|
| Contact + segment + topic | Contact in the list, opted in to the topic |
| `unsubscribed: true` | Opted out of the topic. The contact stays, so it stays off |
| `contact.updated` webhook to `/hooks/newsletter/resend` | The site Worker tells the API itself (below) |
| Broadcast in Resend's editor, `{{{RESEND_UNSUBSCRIBE_URL}}}` | A Markdown file and a send script, with our own signed unsubscribe link |

### 6.2 What changes where

- **`site/newsletter.js`** (sign-up, confirm, welcome, unsubscribe): the calls to Resend become
  calls to SES (send an email; create, read and update a contact). The double opt-in, the signed
  links, the cooldown and the pages stay exactly as they are.
- **Unsubscribing** stays ours: the signed link in the footer and the one-click headers
  (`List-Unsubscribe`, `List-Unsubscribe-Post`) point at `/newsletter/unsubscribe`, as the welcome
  email does today. The page is ours and looks like Casama. SES's own unsubscribe page is not
  used.
- **`POST /hooks/newsletter/unsubscribed`** (new, replaces the Resend webhook): after the Worker
  opts a contact out, it tells the API, signed with `NEWSLETTER_SECRET`, so the app's switch
  turns off. A late or repeated call is harmless, by the same rule as today (an event older than
  the last change in the app is ignored).
- **`apps/server/src/services/newsletter.ts`** (the app's switch, D-408): the same mapping.
  `NEWSLETTER_RESEND_API_KEY`, `NEWSLETTER_WEBHOOK_SECRET`, `NEWSLETTER_SEGMENT_ID` and
  `NEWSLETTER_TOPIC_ID` give way to `NEWSLETTER_CONTACT_LIST` and `NEWSLETTER_TOPIC`. The column
  `newsletter_subscriptions.resend_email` is renamed `list_email` in a migration.
- **A complaint** (someone marks an issue as spam) opts the contact out and turns the switch off,
  through the events queue (§8).

### 6.3 Sending an issue

Resend's editor goes away. An issue becomes a file:

1. Write `site/content/newsletter/2027-01.md` (subject, preview line, body).
2. `scripts/newsletter.sh preview 2027-01` builds the HTML and text with the same shell as the
   account emails, and prints both.
3. `scripts/newsletter.sh test 2027-01 hello@casama.ai` sends one copy.
4. `scripts/newsletter.sh send 2027-01 --dry-run` says how many people would get it.
5. After Oliver's yes, `--yes` queues one email per opted-in contact. The worker sends them at
   the account's allowed pace. A restart continues where it stopped, and a second run sends to
   nobody twice (one dedupe key per issue and address, the way `email_outbox` works today).

Each copy has its own unsubscribe link. The issue can also be published on `casama.ai/newsletter`
from the same file.

### 6.4 Moving the list

Export the contacts from Resend with their state. People who unsubscribed are imported as opted
out, never left out, so they can't be subscribed again by mistake. The list is small today (the
team's addresses and the first sign-ups), so this is one script run with a count check on both
sides. The Resend list is then frozen, not deleted, for 30 days.

This also closes an open item from D-404: Casama's list leaves the Resend account it shares with
sayainvitations.com.

## 7. Bot mail on `mail.casama.app`

This section replaces how `docs/BOT-EMAIL-PLAN.md` receives and sends. What a bot's address is
and what a bot may do with it are unchanged.

### 7.1 Receiving

```
sender → MX (inbound-smtp.us-east-2.amazonaws.com) → SES receipt rule
       → the mail itself into S3  +  a notice to SNS → SQS queue
       → the worker takes the notice, reads the mail from S3 → handleInbound
```

- **One receipt rule** for every address at `mail.casama.app`, with spam and virus scanning on.
  It stores the mail in a private bucket and announces it. The notice carries the real recipients
  (the envelope, not the To line), the five results (§7.2) and the bucket key.
- **The bucket** is private, encrypted at rest, and written only by SES. The worker copies each
  mail it keeps into Casama's own storage (`raw_key`, as planned) and deletes the original. A
  7-day rule clears anything left behind.
- **The worker pulls; nothing is pushed to the API.** A new loop (`startMailInbound`) asks the
  queue for work. There is no public webhook to protect, and `POST /hooks/mail` and the mail
  Worker from the first plan aren't needed. If the server is down or deploying, mail waits in
  the queue (up to 14 days) and nothing bounces. A mail that fails five times moves to a
  dead-letter queue and raises an alarm.
- **Size:** SES takes mail up to 40 MB. Plus addresses (`ada+shop@`) arrive like any other; the
  server splits off the tag.
- Repeats are skipped by Message-ID, as today.

### 7.2 Is the sender real?

SES gives each mail a result for SPF, DKIM, DMARC, spam and virus: pass, fail, grey, or "couldn't
check". It also writes an `Authentication-Results` header into the stored copy. **SES never acts
on these.** Cloudflare would have refused a mail that fails DMARC; here the server decides.

| Result | What the server does |
|---|---|
| Virus: fail | Deleted. Nothing kept |
| DMARC: fail, and the sender's domain asks to reject | Deleted. Nothing kept, no bounce |
| DMARC: pass | **Confirmed.** The allowed list applies |
| DMARC: grey (the domain has no policy) | Confirmed only when SPF or DKIM passed **for the From domain**, read from the header SES wrote (and only that header, the topmost one) |
| Anything else | A stranger, even if the From line is on the allowed list. Flagged "couldn't be confirmed" |
| Spam: fail, from a stranger | Kept 7 days under Spam, not 30. Starts nothing |

The same rule as the first plan (its §5.2), with a better source: results from the service that
received the mail, not a header a sender might have added.

### 7.3 Unknown addresses

SES accepts all mail for the domain and can't check a name against our list while the sending
server is still connected. So "no such address" is said afterwards, and with care: a bounce sent
to a forged sender is spam to an innocent person.

- **Unknown, released or retired address, and the sender is confirmed:** the server sends a
  proper bounce (SES's `SendBounce`, "mailbox does not exist"), at most one a second. Mailbox full
  is answered the same way.
- **The sender isn't confirmed:** the mail is deleted, with no reply.
- Either way nothing is stored, and the mail still costs its $0.0001.

### 7.4 Sending

- Through the SES API in the `casama-botmail` account, as full messages (threading headers,
  files up to the plan's 20 MiB). The `HostedMailSender` interface from the first plan stays, with
  SES as its first implementation and Resend still possible as the second.
- **One tenant per workspace**, made when the workspace claims its first address. Every bot mail
  is sent as its workspace's tenant. A tenant has its own reputation, and SES pauses a tenant by
  itself when its mail goes bad (the "standard" policy), without touching the others.
- **A list of blocked recipients per tenant:** a hard bounce or a complaint against one
  workspace's mail stops that workspace from mailing the address again, not everyone.
- The first plan's own rules stay on top: an address pauses after 2 complaints in 30 days or 1
  hard bounce in 10. When SES pauses a whole tenant, the workspace's addresses show as paused,
  the owner is told why, and the instance owner lifts it in Admin.
- SES allows 50 recipients a message; the plan's limit of 5 stands.
- AWS allows 10,000 tenants by default, and raises it on request.

### 7.5 Guards on cost

Receiving is billed per mail and per 256 KB, so a flood of large junk mail is money.

- The worker counts mails and bytes received per hour. Past a soft limit it alerts the admins;
  past a hard one it runs `scripts/aws-mail.sh inbound off`, which stops SES from accepting mail
  for the domain until someone turns it back on. Senders' servers get a failure and may retry.
- SES can refuse up to 100 IP ranges before a mail is accepted, free. That is the tool against
  one noisy source.
- The AWS budget alerts (§4.8) are the last line.

## 8. Bounces, complaints and blocked addresses

One mechanism for all three kinds of mail.

- Each configuration set publishes its events (sent, delivered, bounced, complained, delayed,
  rejected) to a topic and on to a queue. The worker reads the queue (`startMailEvents`), as it
  does for received mail.
- A new table, `mail_events`: the message ID, the stream (`app`, `news`, `bots`), the kind, the
  address, the time, and the row it belongs to (an `email_outbox` row, an issue, or a bot mail).
  Row-level security, `allow_worker`, a pgTAP test, like every new table. Rows are deleted after
  90 days, and with the account they belong to. No addresses go to analytics.
- **SES keeps its own list** of addresses that hard-bounced or complained, and silently drops
  mail to them. It is on by default for new accounts. So a dead address stops costing reputation
  without any code of ours.
- What the server adds:
  - Account emails skip an address that hard-bounced, and record why in `email_outbox.skipped`.
  - A complaint about a tips email turns `profiles.email_tips` off. A complaint about an issue
    opts the contact out (§6.2).
  - Admin → Vendors shows the 7-day bounce and complaint rates, and alerts before AWS's limits.
- Not included: telling an inviter that their invite bounced. Listed in §13.

## 9. Everything that changes

| Where | Change | Phase |
|---|---|---|
| `infra/aws/` (new), `scripts/aws-mail.sh` (new) | The setup as files (§4.7) | 0 |
| `apps/server/src/services/email.ts`, `env.ts`, `main.ts` | The SES sender and its settings | 1 |
| `apps/server/src/services/vendors/` | Count SES sends; a reader for quota and rates | 1 |
| `apps/server/src/services/mail-events.ts` (new), one migration | The events loop and `mail_events` | 1 |
| `apps/server/src/services/account-emails.ts` | Skip addresses that hard-bounced | 1 |
| `infra/compose/docker-compose.yml`, `infra/helm/`, `.env.example` | Pass the new optional settings through | 1 |
| `deploy/casama-cloud/settings.env`, `README.md` | SES values and the vault item names | 1 |
| `infra/uptime/` | Secrets only. A line in its comments | 1 |
| `docs/EMAIL-RUNBOOK.md` | Rewritten for SES | 1 |
| `site/newsletter.js`, `scripts/site-newsletter.test.mjs` | Resend calls become SES calls | 2 |
| `apps/server/src/services/newsletter.ts`, `api/routes/newsletter.ts`, one migration | The list on SES, the new hook, the column rename | 2 |
| `scripts/newsletter.sh` (new), `site/content/newsletter/` | Writing and sending an issue | 2 |
| `docs/BOT-EMAIL-PLAN.md` | Its infrastructure sections rewritten to match §7 | 3 |
| Bot mail code (not written yet) | Built on SES from the start | 3 |
| `site/privacy.html` (and the docs' privacy page where it names senders) | Amazon Web Services added (sending email; receiving bot mail; United States). Zoho becomes inboxes only. Resend removed, or listed as the backup | With each phase |
| `docs/COSTS.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `CHANGELOG.md` | In the same change as the code | Each phase |
| `docs-site/self-hosting/configuration.md` | A short note: SES works through the SMTP settings | 1 |

New tables get row-level security, `allow_worker` and a pgTAP test. Before naming a migration,
check every branch, worktree and the local database for the newest version. New migrations are
applied with `supabase migration up --include-all`.

## 10. Costs

Prices from aws.amazon.com/ses/pricing on 2026-11-20, à la carte. `docs/COSTS.md` gets these rows
in the same change as the code, and real cost goes to `usage_ledger` as today.

| Item | Price |
|---|---|
| Sending | $0.10 per 1,000 emails |
| Files sent | $0.12 per GB |
| Receiving | $0.10 per 1,000 emails, plus $0.09 per 1,000 chunks of 256 KB (a 5 MB mail is about 20 chunks: $0.0018) |
| Tenants | $0.005 a tenant a month, plus $0.005 per 1,000 emails sent as a tenant |
| Deliverability reports | $0.07 per 1,000 emails, optional |
| Storage, queues, notices, alarms | Cents, mostly inside AWS's free allowances at our size |
| The AWS accounts | Free |
| New AWS customers | Up to $200 in credits, to use within 12 months |

Not bought: a dedicated IP address ($24.95 a month; shared addresses suit our volume), the
Essentials or Pro plans, Mail Manager ($50 a month per open endpoint),
multi-region sending ($0.03 per 1,000 more), address validation ($0.01 an address).

Rough sizes:

| | Today's stack | On SES |
|---|---|---|
| Now: a few thousand app emails a month, a small list | Under $1 (ZeptoMail $2.50 per 10,000; Resend free) | Under $1 |
| 100,000 app emails a month | $25 (ZeptoMail) | $10 |
| A 5,000-person list, one issue a month | A paid Resend plan (the free one stops at 1,000 contacts) | $0.50 an issue |
| 1,000 bot addresses, each sending 5 and receiving 10 a day | About $56 (the first plan, on Cloudflare; receiving free) | About $62: $21 to send, about $41 to receive |

The bot row assumes one received mail in twenty is large (about 2 MB); a spam wave raises it,
which is what §7.5 guards. The credits should cover the first year whole. Money already spent
that doesn't come back: one ZeptoMail credit ($2.50, good until 2027-05-19).

## 11. Phases

Each phase ends with its targeted tests green; the full suites run once at the end of the phase
through `scripts/heavy.sh`. Nothing is pushed, deployed or changed in DNS without Oliver's yes.

### Phase 0: the accounts and a proof of each path

Half a day of work, then AWS's review (days). Needs Oliver for the account itself (§16).

Setup: the organization and both accounts, MFA, the budget, à la carte pricing, `casama-ops`
keys in the vault, the `aws` command on this Mac, the DNS records of §4.4 (all additions), both
production-access requests.

Then check, in the sandbox, and write each answer into this plan:

- us-east-2 offers tenants and deliverability reports, and the account can leave Essentials.
- Whether AWS's free plan limits SES or the review. If it does, start on the paid plan (the
  credits still apply).
- Which pieces CloudFormation can make, and which the script must.
- **Sending:** a mail from `hello@notify.casama.ai` shows SPF, DKIM and DMARC as pass at Gmail,
  Outlook, iCloud, Yahoo and Zoho. Local Supabase Auth sends a sign-in link through SES SMTP, and
  its event arrives in the queue with no custom header (the default configuration set works).
  The uptime Worker's SMTP client works against port 465.
- **Receiving:** a mail to any name at `mail.casama.app` arrives, and so does a plus address. What
  the notice and the stored header look like. A mail with a forged From line reads as failed. A
  20 MiB and a 40 MB mail. What a small mail costs in chunks, on the first bill. `SendBounce`
  works and what the sender sees. What happens to mail for `x@other.mail.casama.app`. What a
  sender sees while receiving is switched off (§7.5).
- **From the bot domain:** a mail from `ada@mail.casama.app` passes DMARC at Gmail despite the
  parent's `p=reject`.
- **Tenants:** make one, send as it, pause and resume it, see the event for the pause, set its
  own blocked list.
- Which Cloudflare account holds `casama.app`, and what its bare-domain Email Routing forwards
  today (it is left alone).

**Done when** every line has an answer, and `casama-mail` is out of the sandbox. Anything that
fails changes the design before code starts.

### Phase 1: app mail (1.5 to 2 days)

The code of §5.2 and §8, the setup files, the runbook, the docs and the privacy page. Then the
three steps of §5.3, each after a yes, with a week between server mail and sign-in mail.

**Done when** every kind of app mail arrives through SES and passes all three checks at the five
providers; a test bounce and a test complaint show in Admin → Vendors; the switch to the backup
and back has been drilled on the local stack; and seven days pass with a bounce rate under 2%.

### Phase 2: the monthly email (1.5 to 2 days)

The code of §6, the list moved, the Worker's secrets changed, the Resend webhook removed.

**Done when**, on SES: a sign-up on casama.ai gets its confirmation, Confirm sends the welcome, a
test issue arrives, one-click unsubscribe opts the contact out and turns the app's switch off, a
re-run of the send reaches nobody twice, and the counts match Resend's.

### Phase 3: bot mail

Built together with `docs/BOT-EMAIL-PLAN.md`, when Oliver approves that plan. This plan changes
its Phase 0 and the infrastructure half of its Phase 1: the worker loop instead of the mail
Worker and hook, SES results instead of Cloudflare's header, tenants and the events queue instead
of Cloudflare Queues. About the same amount of work as it had. Needs `casama-botmail` out of the
sandbox.

**Done when** that plan's Phase 1 check passes on SES: claim an address, forward a mail with a
PDF, get an answer by email, see the thread as a chat, and a mail with your address forged is not
answered.

### Phase 4: tidy up (half a day, 30 clean days after Phases 1 and 2)

Each line is a production change and needs its own yes.

- **ZeptoMail:** remove its DKIM record, `bounce-zem.notify` and its part of the SPF record;
  switch the agent off; retire the vault item.
- **Resend,** unless it stays as the backup (§14 Q5): the `notify` records, the backup key, the
  `EMAIL_BACKUP_*` settings. In every case: `news.casama.ai` on the shared account, its records,
  the newsletter keys and the old webhook.
- **DMARC:** `notify.casama.ai` and `news.casama.ai` go to `p=quarantine`, then `p=reject` after
  another clean month. `casama.ai` itself (people's mail, Zoho) is a separate decision.
- Admin → Vendors drops the old rows. `docs/COSTS.md`, the runbook and the privacy page lose the
  old names.

## 12. Going back

| After | The way back |
|---|---|
| Server mail on SES | Unset `SES_*`, deploy. The server sends through `SMTP_*` (ZeptoMail) again |
| Sign-in mail on SES | Restore the `.env` backup, recreate `auth`, restart `kong`. Two minutes |
| The uptime Worker | Put the old secrets back |
| The monthly email | Point the Worker and the server at Resend again. The frozen list is still there for 30 days; anyone who changed their mind since is carried over by the same script, the other way |
| Bot mail | Nothing to go back to: it starts on SES. If SES fails it, the first plan's Cloudflare and Resend path still fits behind `HostedMailSender` for sending, but receiving on a subdomain needs SES (§2) |

After Phase 4 the old records are gone, and going back means setting a provider up again.

## 13. Not in this plan

- **Inboxes on AWS.** They stay on Zoho Mail.
- **Replacing Cloudflare Email Routing** on `notify.casama.ai` or on bare `casama.app`.
- **SES for self-hosted servers** beyond the SMTP note, and SES as a provider for the
  bring-your-own email chat app.
- **A dedicated IP address**, until volume calls for one.
- **Sending from two regions at once.** It doesn't work over SMTP, so it couldn't cover Auth.
- **A brand logo beside our mail (BIMI).** It needs `p=quarantine` first and a paid certificate.
- **Telling an inviter that an invite bounced.** The events table makes it possible later.
- **A newsletter editor or scheduled sends.**
- **Your own domain for bot mail** (`ada@yourcompany.com`): still out, as in the first plan.

## 14. Decisions for Oliver

Each has a recommendation; the plan above assumes it.

1. **Region.** us-east-2, Ohio (recommended), or us-east-1.
2. **Accounts.** Two mail accounts under one organization, so bot mail can never pause sign-in
   mail (recommended). Or one account, with tenants keeping the streams apart: simpler, but AWS
   still judges the account as a whole.
3. **Whose AWS account.** A Stackwares organization with Casama's accounts inside it
   (recommended), or a Casama-only account. And which mailbox its root address lives in.
4. **Pricing.** À la carte, with deliverability reports on for the first 90 days (recommended).
   Or the Essentials plan.
5. **The backup after the move.** Keep Resend behind server mail, as today: free, already built,
   a different AWS account from ours (recommended). Or keep ZeptoMail instead: the only choice
   that doesn't run on AWS at all, but it needs a small code change and its credits expire. Or
   no backup.
6. **The monthly email.** SES's list plus issues as Markdown and a send script (recommended). Or
   Listmonk on the VPS in front of SES: a real editor, and one more service to run and protect.
   Or leave the monthly email on Resend and move only the rest.
7. **Receiving bot mail.** On SES (recommended: it is what `mail.casama.app` needs). Or on
   Cloudflare, free, which means a bare domain instead.
8. **Mail to an unknown bot address.** Bounce it when the sender is confirmed, drop it otherwise
   (recommended). Or never answer.
9. **When.** Phase 0 soon, since it costs nothing and waits on AWS; Phases 1 and 2 before
   launch, while volume is small and a mistake is cheap (recommended). Or wait for a trigger:
   ZeptoMail's last credit running low, or the day bot mail starts.
10. **DMARC.** Tighten the two sending subdomains to quarantine, then reject (recommended), or
    leave them at `p=none`.
11. **ZeptoMail after 30 clean days.** Remove it (recommended), or keep it idle until its credit
    expires on 2027-05-19.

## 15. Risks

- **AWS refuses or delays the review.** Likelier for the bot account. Nothing is switched before
  an account is approved, so the cost is time. If the bot account is refused: appeal with more
  detail, and otherwise send bot mail through Resend behind the same interface while SES only
  receives.
- **AWS pauses the account.** Bounces over 10% or complaints over 0.5% can stop all sending, and
  sign-in with it. Covered by: the test-address guard and sign-up rule we already have, SES's
  own blocked list, alarms at a fifth of AWS's limits, the backup sender and its runbook, and
  bot mail in another account.
- **A dip in delivery after the switch.** A new sending path, on addresses shared with other SES
  customers. Covered by keeping the same From addresses, moving in steps with a week between,
  checking five providers, and the reports of §4.8. The domains are new anyway (`notify` has
  sent only since 2026-11-16), so there is little reputation to lose.
- **Keys on the server.** A leaked key that can send from our domain is a phishing tool. Covered
  by one job per key, a From-address condition on each, no console access, rotation every 90
  days, and alarms on unusual volume.
- **A flood of mail to the bot domain.** Covered by §7.5.
- **Bounces sent to the wrong person.** Covered by §7.3: only confirmed senders get one.
- **Everything in one vendor.** One AWS problem could touch every kind of mail. Covered in part
  by two accounts and a backup sender outside our accounts. Not covered: an AWS-wide SES outage
  would stop the Resend backup too, unless the backup is ZeptoMail (§14 Q5).
- **The Kong restart.** Recreating `auth` without restarting `kong` takes sign-in down. It is
  in the runbook and in §5.3.
- **Prices and limits change.** New accounts already start on a plan that didn't exist a year
  ago. Phase 0 re-reads the pricing page before anything is bought.
- **Sign-up forms that refuse the bot domain**, and the other product risks of bot mail: see the
  first plan's §14.

## 16. Left for Oliver

- Answers to §14.
- Create the AWS account: it asks for a card and a phone number. Then MFA on the root user.
  Everything after that can be done from this Mac with the `casama-ops` keys.
- Answer AWS if the review asks questions.
- A yes for: the DNS additions (Phase 0), each VPS env change and deploy (Phase 1), the Worker
  secrets and deploys (Phases 1 and 2), each newsletter send, each removal in Phase 4.

## Sources

Checked 2026-11-20.

- Amazon SES pricing: https://aws.amazon.com/ses/pricing/
- SES endpoints and quotas (receiving regions): https://docs.aws.amazon.com/general/latest/gr/ses.html
- SES quotas: https://docs.aws.amazon.com/ses/latest/dg/quotas.html
- Receiving, concepts: https://docs.aws.amazon.com/ses/latest/dg/receiving-email-concepts.html
- Receiving, what a notice contains: https://docs.aws.amazon.com/ses/latest/dg/receiving-email-notifications-contents.html
- Receiving, the S3 action: https://docs.aws.amazon.com/ses/latest/dg/receiving-email-action-s3.html
- SendBounce: https://docs.aws.amazon.com/ses/latest/APIReference/API_SendBounce.html
- Tenants: https://docs.aws.amazon.com/ses/latest/dg/tenants.html
- Blocked addresses per tenant: https://docs.aws.amazon.com/ses/latest/dg/sending-email-suppression-list-tenant-level.html
- The account's blocked list: https://docs.aws.amazon.com/ses/latest/dg/sending-email-suppression-list.html
- Production access: https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html
- Bounce and complaint limits: https://docs.aws.amazon.com/ses/latest/dg/faqs-enforcement.html
- SMTP: https://docs.aws.amazon.com/ses/latest/dg/smtp-connect.html and https://docs.aws.amazon.com/ses/latest/dg/smtp-credentials.html
- Return path (MAIL FROM): https://docs.aws.amazon.com/ses/latest/dg/mail-from.html
- Identities and DKIM: https://docs.aws.amazon.com/ses/latest/dg/creating-identities.html
- Default configuration sets: https://docs.aws.amazon.com/ses/latest/dg/managing-configuration-sets.html
- Events: https://docs.aws.amazon.com/ses/latest/dg/monitor-using-event-publishing.html
- Contact lists: https://docs.aws.amazon.com/ses/latest/dg/sending-email-list-management.html
- Test addresses: https://docs.aws.amazon.com/ses/latest/dg/send-an-email-from-console.html
- Multi-region sending: https://docs.aws.amazon.com/ses/latest/dg/global-endpoints.html
- Amazon WorkMail ending: https://www.admin-magazine.com/News/Amazon-Ending-Support-for-WorkMail
- Supabase Auth's SMTP settings: https://github.com/supabase/auth
- Cloudflare Email Routing on subdomains: https://developers.cloudflare.com/email-routing/setup/subdomains/
- Cloudflare DMARC Management: https://developers.cloudflare.com/dmarc-management/
