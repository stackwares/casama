# An email address for every bot: plan

Status: **built, not live** (written 2026-11-20; Phases 1–4 merged to `main` with audit fixes,
D-449, not deployed). §13 is built on the recommendations until Oliver says otherwise. It stays
off until a server has MAIL_DOMAIN and its keys. Cloudflare is set up on `casama.app` (routing,
the Worker, sending, delivery events) and Phase 0 is mostly answered; what's left is the server's
settings and the deploy.

As built (Phase 1): the Worker's existence check is `GET /hooks/mail?to=…`, not HEAD (Hono
doesn't match HEAD routes). Resend's received-email API reports sender checks in an
`authentication` object (`pass`/`fail`/`gray`/…), which the self-hosted app reads; its webhook
carries no headers at all.

As built (Phase 2): blocking a sender refuses their mail at the door (the hook answers 404 and
the Worker rejects it). Automatic mail reaches routines only with `include_automatic`. The
full test suites run once at the end (per AGENTS.md), not after each phase.

As built (Phase 3): mail to new people asks through a new async approval hook
(`alwaysAskForAsync`), since the allowed list lives in the database. The bounce-rate
auto-pause needs at least 10 sends before it can fire, so one typo can't pause an address.
The sender check verifies the passing domain matches the From line's organizational domain
(the plan's "same domain" rule). Resend delivery events are out of scope (Cloudflare only).

## 0. Summary

A bot gets its own address, such as `ada@<mail domain>`, claimed in one step from the bot's
profile or by asking the bot. Nothing to set up: no Resend account, no DNS, no webhook.

With it a bot can:

- take mail you forward to it, and answer you by email in the same thread, with files;
- be written to by the people you allow;
- keep receipts, newsletters and other mail sent to its address, and act on it in routines;
- sign up for services and read the verification code itself, with your approval;
- write to other people for you, each message shown to you first.

Most of the machinery exists. Casama already has an email chat app (D-270, D-342): signed
webhooks, repeat-skipping, attachments, threads, replies, allowed senders and routines on
messages. Today it needs your own Resend account and domain. This plan adds the hosted part and
the pieces a public address needs that a private one didn't.

| Piece | Today | After |
|---|---|---|
| Address | Your own domain on your own Resend account | `name@<mail domain>`, claimed in the app |
| Who checks the sender is real | Nobody (see §1.2) | SPF, DKIM and DMARC results checked on every mail |
| Mail from strangers | A 200-character preview in Activity | Kept in the bot's inbox for 30 days; starts nothing |
| Reading old mail | Not possible | `mail.search` and `mail.read` tools, and a Mail screen |
| Sending to new people | Not possible (allowed list only) | `mail.send`, always behind an approval card |
| Cost to Casama | None | About $5 a month plus $0.35 per 1,000 sent (§10) |

Four phases (§11). Phase 1 alone (receive, and reply to you and the people you allow) is a
complete feature; the later phases add the inbox, sending to new people, and sign-ups.

## 1. What exists today

### 1.1 The email chat app

| Piece | Where | Reused as |
|---|---|---|
| Email adapter: signature check, body and attachment fetch, send with files, threading headers | `packages/agent/src/channels/adapters.ts` (`email`, line 591) | The self-hosted path, unchanged. The hosted path reuses its message shape |
| Inbound pipeline: repeats skipped, allowed senders, a conversation per sender and subject, files saved, runs started | `packages/agent/src/channels/service.ts` `handleInbound` | The hosted address feeds the same function |
| Allowed senders, with `*@example.com` | `senderAllowed` in `adapters.ts`; `channels.allowed_senders` | Unchanged |
| Activity with **Allow** on ignored mail | `channel_events`; `client/lib/features/bots/channels_screen.dart` | Unchanged |
| Routines on messages, filtered by sender, subject and text (D-134) | `MessageTriggerConfig` in `packages/contracts/src/autonomy.ts`; `messageMatches` | Gains a filter on the plus tag (§5.4) |
| Starting a new message | `channel.send` (high risk, allowed list only) | Stays; `mail.send` is added beside it (§6) |
| Tools that must always ask | `alwaysAsk` / `alwaysAskFor` on a tool (`packages/agent/src/run.ts:4451`) | Used for mail to new people |
| Tables | `supabase/migrations/20261224000001_channels.sql`, `…000301_channel_inbound_seen.sql` | A hosted address is a `channels` row of kind `email` |
| Plan limits | `apps/server/src/billing/limits.ts` (`max_bots`, `max_computers`) | Gains the mail limits (§8) |

### 1.2 A gap found along the way

The email chat app matches allowed senders on the From line alone. The code makes no SPF, DKIM
or DMARC check (`grep -i "dmarc\|dkim\|spf"` over `packages/agent/src/channels` finds nothing),
and Resend's `email.received` webhook carries no such results. Someone who knows an allowed
address can write a mail that claims to come from it, and the bot will treat it as that person.
Whether Resend drops such mail before the webhook is not documented on the pages we read.

It matters little while the address is private to one workspace. It is the first thing to fix
before an address is public and guessable. Phase 1 fixes it for hosted addresses, and tries the
same check for self-hosted ones from the headers of Resend's received-email API (§5.2).

### 1.3 Mail Casama already sends

| Mail | Through | From |
|---|---|---|
| Sign-in links, invites, account and support mail (D-318) | ZeptoMail, Resend as backup (D-433) | `hello@notify.casama.ai` |
| The monthly email (D-404) | Resend | `news.casama.ai` |
| People's inboxes (`hello@casama.ai`) | Zoho Mail | `casama.ai` |

None of these can carry bot mail. ZeptoMail approved Casama for transactional mail only, and
`casama.ai`'s own mail goes to Zoho. Bot mail gets its own domain, its own sending account and
its own reputation.

## 2. How Grok Bot does it

From press and blogs that quote xAI's docs; we could not read the docs themselves.

- `name@mail.grokbot.com`, claimed by asking a Bot (with an approval card) or in settings.
- **One address per account**, shared by all of a person's Bots. Plus addresses
  (`name+shop@`) give each job a lane. It can't be renamed or deleted and is never reissued.
- Anyone can write to it. Mail is kept, but wakes nothing unless a routine watches for it.
  Routines hear only mail that passes sender checks, and filter by sender.
- No inbox view and no new-mail notification: you ask a Bot what arrived.
- Sending needs approval; mail from a routine waits as a draft.
- A Bot can sign up for services and read the code from its inbox.
- On teams an admin switches it on. No custom domains.

Where Casama would differ, on purpose:

| | Grok Bot | Casama |
|---|---|---|
| Scope | One per account, every Bot reads it | One per bot; only that bot reads it |
| Seeing mail | Ask the Bot | A Mail screen, and threads as chats |
| Mail from you | Needs a routine | Is a chat message: the bot answers |
| Moving it | Fixed forever | Can move to another bot in the workspace |
| Self-hosted | Not applicable | Bring-your-own email chat app stays |

## 3. Principles

1. **Mail from a stranger never starts anything.** It is kept and shown. Only you, the people
   you allow, and routines you set up make the bot act.
2. **A sender is who they say only when their domain confirms it.** No confirmation, no trust.
3. **Text inside an email is never your permission.** An email can ask the bot to do something;
   only you can approve it.
4. **Every first message to a new person is shown to you first**, at every autonomy level.
5. **Bot mail can't hurt sign-in mail.** Separate domain, separate sending account.
6. **An address is never reissued.** Whoever claimed it may have used it to sign up somewhere;
   the next person must not receive their password resets.
7. **No WebViews.** Mail is shown as text with native components. HTML mail is turned into text
   on the server, as it is today.

## 4. Addresses

### 4.1 Shape and rules

- `name@<mail domain>`, on the bare domain (§9.1).
- One address per bot. A bot has at most one; a workspace has as many as its plan allows (§8).
- Names: lowercase letters, digits, dots, hyphens and underscores; start and end with a letter
  or digit; 3 to 40 characters; no two dots in a row. The namespace is shared by every
  workspace on Casama Cloud, first come first served.
- Reserved, in `packages/domain/src/mail-names.ts`: role names (`admin`, `support`, `billing`,
  `security`, `abuse`, `postmaster`, `hostmaster`, `webmaster`, `noreply`, `help`, `info`,
  `team`, `hello`, `mailer-daemon`), Casama's own names (`casama`, `stackwares`, `oliver`), and
  a list of brands that are impersonation targets (banks, payment and mail providers, stores).
  The instance owner can add names in Admin.
- Plus addresses: `ada+shop@` reaches Ada, with the tag `shop` kept on the mail. Anyone can use
  any tag; it's a label, not a lock.

### 4.2 Claiming

Two ways, both ending in the same call (`POST /v1/bots/{id}/email`):

1. **Bot profile → Email.** A sheet with one field, the name, checked as you type. It says the
   name can't be changed later. **Create address**.
2. **Ask the bot** ("get yourself an email address"). A `mail.claim` tool, marked always-ask:
   the bot proposes a name, and an approval card shows the full address before anything is
   claimed.

On a claim:

- a `channels` row of kind `email` is made for the bot, with `config.hosted = true`;
- your own account email goes on its allowed senders, so mail from you works at once;
- the conversation and its runs belong to you, as with every chat app.

### 4.3 Changing your mind

- **Rename:** no. Claim a new one instead (below).
- **Move:** the address can move to another bot in the same workspace. Its mail moves with it.
- **Pause:** a switch. A paused address still receives and keeps mail; nothing runs or sends.
- **Release:** the address stops receiving (senders get "no such address") and is retired for
  good. Its mail is deleted after 30 days. The bot can then claim a new one. Releasing always
  works; to stop people cycling through names, a workspace can claim at most its plan's address
  limit plus 3 addresses in any 365 days (archiving a bot counts like releasing).
- **Bot deleted, workspace deleted, account deleted:** the address is retired the same way and
  its mail deleted with the rest of the data.

### 4.4 Data

New tables (one migration; check every branch, worktree and the local database for the newest
migration version before naming it):

- `mail_addresses`: `local_part` (unique over every row, retired ones included), `org_id`,
  `bot_id`, `channel_id`, `created_by`, `status` (`active`, `paused`, `retired`), timestamps.
- `mail_messages`: one row per mail in or out. `address_id`, `direction`, `from_addr`,
  `to_tag`, `subject`, `message_id`, `in_reply_to`, `thread_key`, `sender_check` (`pass`,
  `fail`, `none`), `verdict` (`allowed`, `stranger`, `automatic`), `conversation_id` when it
  became a chat, `size`, `raw_key` (the original in object storage), `expires_at`. The text is
  stored the way chat messages are (the same sealing, D-238).
- `mail_suppressions`: addresses we must not send to (hard bounces, complaints, opt-outs).
- `mail_events`: delivered, bounced, complained, per sent mail.

All four with row-level security for workspace members who can manage the bot, and
`allow_worker` for the worker. `mail_addresses.local_part` lookups for the inbound door run as
the server, not as a member.

### 4.5 Getting people started

An address nobody has written to is worth nothing, so the goal of onboarding is the first mail
arriving and being answered, not the claim.

**Where the offer appears.** Never as a required step, and never claimed for someone without
asking: a name can't be changed, so it must be chosen.

1. **When it's needed.** The bot offers it when a request is mail-shaped ("keep my receipts",
   "sign up for…", "email the restaurant", "can I forward you this?"). One approval card with
   a suggested name; approve and carry on with the request.
2. **After making a bot**, as one optional row on the bot's first screen: "Give Ada an email
   address". Skipping it costs nothing.
3. **Bot profile → Email**, always there.
4. **One suggestion card** (D-306) for bots without an address, shown once.
5. **One tip in the welcome emails** (D-302).

**The claim sheet.** One field, already filled with a free name built from the bot's name
(`ada`, then `ada.oliver`, `ada.martinez`…). Taken names show two or three free alternatives
to tap. One line says the name can't be changed later. One button.

**Straight after claiming: the first mail.** The bot sends a short welcome mail from its new
address to your account email: who it is, and "reply to this, or forward me anything". This:

- puts the address in your mail app, where replying and forwarding start;
- proves the whole loop when you reply (the reply is answered, and shows as a chat);
- costs nothing to send, since it goes to the owner.

The sheet then shows the address with **Copy**, **Add to contacts** (a contact card through
the share sheet) and **Write to Ada** (opens your mail app with the address filled in).

**Three things to try**, as cards under the address, each one tap:

- **Forward a bill or a booking**: explains forwarding in one line.
- **Keep my receipts**: makes a routine on `ada+receipts@` and shows that address to copy.
- **One digest a week**: makes a routine on `ada+news@` for newsletters.

**The usual stumble: writing from another address.** People forward from a work or second
address that isn't on the allowed list, and the bot stays silent. When a confirmed mail arrives
from an unknown sender in the first 14 days, you get a notification: "Mail from
oliver@work.com. Is this you?" with **Allow**. After that it's the quieter Phase 2 setting.

**Measured as a funnel:** offer shown → claimed → welcome mail opened or replied → first mail
received from the owner within 7 days → second week with mail.

## 5. Receiving

### 5.1 The path

```
sender → MX (Cloudflare Email Routing, catch-all) → mail Worker → POST /hooks/mail → handleInbound
```

- **Cloudflare Email Routing** on the mail domain, with one catch-all rule to a Worker. Free and
  unlimited; mail up to 25 MiB. Cloudflare already refuses mail that fails both SPF and DKIM,
  and mail that fails the sender domain's DMARC policy.
- **The mail Worker** (`infra/mail/`, new). For each mail it posts the raw message to
  `POST /hooks/mail` on the API with the envelope sender and recipient, signed with a shared
  secret (HMAC over the timestamp and body, like the other hooks). It parses nothing.
  - The API answers "no such address" for an unknown, released or retired name; the Worker then
    rejects the mail, so the sender gets a proper bounce and we store nothing.
  - For a mail over 1 MiB the Worker asks first (`HEAD /hooks/mail?to=…`) before posting it.
  - If the API can't be reached, the Worker fails the delivery so the sending server tries
    again later. How the Worker signals "try again" is checked in Phase 0.
- **`/hooks/mail`** (new route beside `apps/server/src/api/routes/channels.ts`): checks the
  signature, parses the message with `postal-mime` (MIT), reads the sender check (§5.2), stores
  the original in object storage and a `mail_messages` row, then hands an `InboundMessage` to
  `handleInbound`. Repeats are skipped by Message-ID as today.

### 5.2 Is the sender real?

Cloudflare adds an `Authentication-Results` header from `mx.cloudflare.net` with the SPF, DKIM
and DMARC results. The server reads the first header with that name and nothing else (a sender
can add fake ones below it).

A sender counts as **confirmed** when DMARC passes, or, for a domain with no DMARC record, when
SPF or DKIM passes for the same domain as the From line. Cloudflare's own refusal is not
enough: a large mail provider with a relaxed policy lets through mail that claims its users'
addresses.

- **Confirmed and on the allowed list:** a chat message. The bot answers.
- **Not confirmed but claiming an allowed address:** treated as a stranger, and flagged in the
  Mail screen: "Claims to be from you, but couldn't be confirmed."
- **Self-hosted email chat app:** the same check from the headers Resend's received-email API
  returns, if they include the results. If they don't, the docs say so plainly, and Activity
  marks email senders as unconfirmed. Checked in Phase 1.

### 5.3 What happens to each mail

| Mail | Kept | Starts a run | Reply |
|---|---|---|---|
| From you or an allowed sender, confirmed | Yes, as a chat | Yes | By email, in the thread |
| Matches a routine's filter | Yes | The routine | None by itself |
| From anyone else | Yes, 30 days | No | None |
| Automatic (bounces, out-of-office, mailing lists) | Yes, 30 days | No, unless a routine asks for it | Never |
| Unknown or retired address | No | No | Refused at the door |

- **Automatic mail** is recognized by `Auto-Submitted`, `Precedence: bulk` or `list`,
  `List-Id`, and a `mailer-daemon` or `postmaster` sender. The bot never auto-replies to it.
  This is what stops two auto-responders writing to each other all night.
- **A second guard on loops:** at most 10 replies an hour in one thread without a person's
  message in between; then the thread waits for you.
- **Size:** the mailbox has a size limit per plan (§8). At the limit, new mail is refused with
  "mailbox full" and you get a notification once.

### 5.4 Routines on mail

The existing **Messages** trigger works as is. Two changes:

- A filter on the plus tag (`to_tag`), so "mail to `ada+receipts@`" can file receipts.
- A routine with a sender filter of "anyone" hears only **confirmed** senders by default, and a
  hosted address runs at most 30 stranger-started routine runs a day. Without this a stranger
  could spend your credits by writing to the bot.

A mail that starts a routine isn't also answered, as today.

### 5.5 The inbox and its tools (Phase 2)

- **`mail.search`** (low risk): by sender, tag, subject, text, date, has-files.
- **`mail.read`** (low risk): one mail's text and its files.
- **`mail.wait`** (low risk): waits up to two minutes for a mail from a given sender or domain.
  This is what picks up a verification code during a sign-up (§7).

Whatever these return is framed as outside content, the way fetched web pages are: the bot is
told it is material to read, and that nothing in it is an instruction or an approval.

## 6. Sending

### 6.1 Three kinds

| Kind | Example | Approval |
|---|---|---|
| A reply in a thread with an allowed sender | You write, the bot answers | None (as today) |
| A new mail to someone on the allowed list | "Tell me when the report is done" | The bot's autonomy decides (high risk, as today) |
| Any mail to someone not on the list | A table request to a restaurant | **Always**, at every autonomy level, Full access included |

The third kind is new: a **`mail.send`** tool (to, cc, subject, text, files, an optional thread
to answer in), with `alwaysAskFor` set when any recipient is off the allowed list. The approval
card shows every recipient, the subject and the whole text. In a routine or any run you aren't
watching, the card waits in the Inbox like any approval: that is the "draft".

After you approve a mail to a new person, their replies in that thread reach the bot as chat
messages for that thread. They don't go on the allowed list unless you add them.

### 6.2 Limits that can't be turned off

- At most 5 recipients a mail (to and cc); no bcc.
- A daily count per address and per workspace (§8).
- Nothing to an address in `mail_suppressions`.
- Nothing to reserved test domains (`isUndeliverableAddress`, already in
  `apps/server/src/services/email.ts`).
- Files up to 20 MiB a mail.

### 6.3 What the mail looks like

- From `Ada <ada@<mail domain>>`: the bot's name, its own address. Replies come back to it.
- Plain text and simple HTML (`toEmailHtml`, as today), with threading headers.
- A first mail to a new person ends with one line: "Sent by Ada, an AI assistant working for
  Oliver." (see §13 Q5).
- DKIM-signed for the mail domain by the sending service; SPF and a DMARC record on the domain,
  starting at `p=quarantine`.

### 6.4 The sender

**Cloudflare Email Sending**, called over its REST API from the server (the server runs on the
VPS, not in a Worker). It is in beta. So the sender sits behind a small interface
(`HostedMailSender`), with **Resend** as the second implementation; the Resend code already
exists in the email adapter. Switching is a setting, not a rewrite.

### 6.5 Bounces and complaints

Cloudflare publishes delivery events (delivered, bounced, complained) through Cloudflare
Queues. The mail Worker consumes that queue and posts each event to `POST /hooks/mail/events`.

- A hard bounce or a complaint puts the recipient in `mail_suppressions`.
- **An address is paused by itself** after 2 complaints in 30 days, or when more than 1 in 10
  of its last 20 sends hard-bounced. The owner gets a notification that says why; the instance
  owner sees it in Admin and is the one who can lift it.
- A reply of "stop" or "unsubscribe" from someone not on the allowed list suppresses them for
  that address.

## 7. Signing up for services (Phase 4)

No new machinery, mostly instructions:

- The bot fills the form on its computer with its own address, then calls `mail.wait` for the
  code or link.
- Creating the account is an action on a website and follows the usual autonomy rules.
- A built-in note in the bot's context when it has an address: use it for sign-ups you asked
  for; never as the recovery address for a bank, a domain registrar or an admin account; never
  as a place to receive another person's mail.

## 8. Plans and limits

Proposed; the numbers are §13 Q3.

| | Free | Plus | Pro | Max |
|---|---|---|---|---|
| Addresses per workspace | 1 | 2 | 5 | 15 |
| Receive, and reply to people on the allowed list | Yes | Yes | Yes | Yes |
| Mail to new people, a day | None | 10 | 30 | 100 |
| All mail sent, a day | 20 | 100 | 300 | 1,000 |
| Mailbox size per address | 100 MB | 1 GB | 5 GB | 20 GB |

- Free can't write to new people. A free account sending mail from our domain is the easiest
  way for a spammer to use us, and the waitlist gate won't be there forever.
- The limits are plan limits (`max_mail_addresses`, `mail_new_day`, `mail_sent_day`,
  `mail_storage_mb`), changeable per workspace in Admin like the others.
- Runs started by mail spend the owner's credits like any run. Sending itself isn't charged.

## 9. Infrastructure

### 9.1 The domain

- **`casama.app`** (bought 2026-11-20, Stackwares Cloudflare account): bots are `ada@casama.app`.
  Its web traffic (`casama.app`, `www.casama.app`) only redirects to `casama.ai` (301, path and
  query kept); nothing else may live on it, so bot mail has the domain's reputation to itself.
- Used bare (`ada@domain`). Cloudflare's catch-all routing rule works on a zone's apex only; a
  subdomain such as `mail.casama.app` takes only literal rules, at most 200 per domain, which
  would cap the product at about 200 addresses. That ruled out `mail.casama.app`.
- The name is a setting (`MAIL_DOMAIN`); nothing in code or copy hard-codes it. Phases 1 to 4
  can be built and tested against fakes before it's bought. Only Phase 0 and going live need it.
- New mail domains start with no reputation. Sending starts low and grows over the first weeks
  (Cloudflare starts new accounts on "a conservative daily quota" too).

### 9.2 Pieces to stand up

| Piece | Where | Notes |
|---|---|---|
| Zone, Email Routing, catch-all rule | Cloudflare | A production change: needs Oliver's yes |
| The mail Worker | `infra/mail/` + a `scripts/deploy-mail-worker.sh` with `--dry-run` | Same shape as `infra/uptime` |
| Email Sending on the domain | Cloudflare | Beta; needs Workers Paid |
| A queue for delivery events | Cloudflare Queues | Consumed by the same Worker |
| Shared secret between Worker and API | Vaultwarden, "Keys & Signing"; a Worker secret and the server's env | Search the vault first |
| Cloudflare API token for sending | Vaultwarden; the server's env | Scoped to Email Sending on this zone |

### 9.3 Self-hosted servers

Hosted addresses are a Casama Cloud service. A self-hosted server keeps the bring-your-own
email chat app, which gains the sender check (§5.2). The hosted pieces switch on only when
`MAIL_DOMAIN` and the hook secret are set, so a self-hoster with their own Cloudflare zone can
run the same Worker; the self-hosting docs get a short page for it. Hosted addresses for
self-hosted servers through Casama Link are left out (§12).

### 9.4 Switching it off

A remote flag, `bot_email`, hides claiming in the app. A server setting pauses all sending.
Both exist from Phase 1.

## 10. Costs

Checked on the vendors' own pages on 2026-11-20. `docs/COSTS.md` gets these rows in the same
change as the code.

| Item | Price | Who pays |
|---|---|---|
| The mail domain | About $10 to $25 a year | Casama |
| Cloudflare Workers Paid | $5 a month; includes 3,000 sent emails. Whether the Stackwares account is already on it is a Phase 0 check | Casama |
| Sending | $0.35 per 1,000 after the first 3,000. Hard bounces count | Casama |
| Receiving | Free, unlimited | |
| The Worker's requests | Workers pricing; one or two requests a mail | Casama |
| Stored mail | Our own object storage, on the server | Casama |
| Runs started by mail | Model usage | The workspace's credits |

Rough size: 1,000 addresses each sending 5 mails a day is 150,000 a month, about **$56**.
Spam costs nothing to receive.

Why not the others:

| Option | Price | Why not |
|---|---|---|
| Resend, receiving on our domain | $20 a month for 50,000, then $0.90 per 1,000; received mail counts | Spam and newsletters eat the quota; no sender-check results in the webhook. Kept as the fallback sender |
| Resend Inboxes | $1 an inbox a month after 3 | 1,000 bots would cost $1,000 a month |
| AgentMail | About $1.30 to $2 an inbox a month (third-party pages) | Same |
| Amazon SES | $0.10 to $0.16 per 1,000 sent; receiving needs a $50-a-month endpoint | New vendor and account review, and dearer to receive |
| ZeptoMail | $0.25 per 1,000 | Transactional mail only; carries our sign-in links |

Each sent mail is recorded in `usage_ledger` (kind `emails_sent`, with its real cost, not
billable), so the cost can be counted per workspace.

## 11. Phases

Each phase ends with its targeted tests green; the full suites run once at the end of the phase
through `scripts/heavy.sh`. Nothing is pushed, deployed or built for the stores without
Oliver's yes.

### Phase 0: prove the path (half a day; needs the domain)

Against the local stack through `api-dev.casama.ai`, with a throwaway Worker.

Findings (2026-11-20, on `casama.app`, with real mail sent from `casama.app` to itself):

- **Set up:** Email Routing on, catch-all rule → `casama-mail` Worker (with `MAIL_HOOK_SECRET`,
  vault "Casama · Mail hook secret"). Workers Paid bought. Email Sending onboarded on
  `casama.app` (bounce MX, SPF, DKIM, `DMARC p=reject`). Queue `casama-mail-events` (dead
  letters to `casama-mail-events-dlq`) fed by the event subscription `casama-app-sending`
  (delivered, bounced, complained), consumed by the Worker. Server token with Email Sending only:
  vault "Casama · Cloudflare Email Sending token (casama.app bot mail)".
- **Quota:** starts at 1,000 sends a day; recipients arbitrary.
- **Message-ID:** Cloudflare **refuses a send that sets its own `Message-ID`** (`email.invalid`).
  It gives each mail `<random@casama.app>`, returns it as `message_id`, puts it in the header,
  and delivery events carry the same value. So on Cloudflare the code keeps that id; Casama's own
  Message-ID goes out only through senders that take one (Resend).
- **Authentication-Results:** Cloudflare puts its trace block (Received, ARC-*, Received-SPF,
  then `Authentication-Results: mx.cloudflare.net; … dmarc=pass header.from=… policy.dmarc=…`)
  above every header of the original mail, so the first `Authentication-Results` header is
  always Cloudflare's; anything a sender plants sits below it. Planting one through Email Sending
  itself isn't possible: it refuses custom `Authentication-Results` headers.
- **Size:** a 20.5 MiB mail reached the Worker whole.
- **Envelope sender:** Cloudflare-sent mail arrives from `…@cf-bounce.casama.app` (not empty),
  so it isn't taken for automatic mail.
- Still to check after the deploy: what senders see for "no such address" and retries, and a mail
  to Gmail and Outlook landing in the inbox.

- A mail to any name on the domain reaches the Worker; so does a plus address.
- The `Authentication-Results` header is there and reads as documented, including for a mail
  with a faked From line. Cloudflare's own header is always the topmost one, including when the
  sender planted their own `Authentication-Results: mx.cloudflare.net; dmarc=pass` lower down
  (the code trusts only the topmost header, so this must hold).
- Whether Email Sending keeps a custom `Message-ID` header (the code sets `<uuid@domain>`) and
  which id its delivery events carry.
- How the Worker says "no such address" and "try again later", and what the sender sees.
- A 20 MiB mail gets through to the API.
- Email Sending is available on the account; its starting daily quota; a mail to Gmail and to
  Outlook lands in the inbox.
- Delivery events arrive through a queue.
- Whether the account is already on Workers Paid. It wasn't; bought 2026-11-20.

**Done when** each line has an answer written into this plan. Anything that fails changes the
design before code starts (the fallback is Resend for sending).

### Phase 1: an address, and mail with you and the people you allow

- Migration: `mail_addresses`, `mail_messages`; plan limits.
- Names: rules, reserved list, availability check.
- API: claim, read, pause, move, release (`/v1/bots/{id}/email`); OpenAPI and the generated
  clients.
- The mail Worker and `POST /hooks/mail`; parsing; the sender check; automatic-mail and loop
  guards.
- The hosted sender behind `HostedMailSender`; replies through it.
- The sender check for the self-hosted email chat app.
- App: the **Email** row and sheet in the bot profile; address with copy and share; the allowed
  list; pause.
- `mail.claim` tool.
- Getting started (§4.5): name suggestions, the welcome mail, contact card, the "Is this you?"
  notification, the offer after making a bot and the suggestion card. The three "things to
  try" cards come with Phase 2, when routines on plus addresses exist.
- Docs: a new `docs-site/guide/bot-email.md`; `chat-apps.md`; `moving-from-grok-bot.md`;
  `privacy.md`; the site's privacy page and terms; `docs/COSTS.md`; `docs/ARCHITECTURE.md`.
- Analytics catalog: `bot_email_claimed`, and daily counts of mail in and out. No addresses,
  subjects or text.

**Done when** you can claim an address in the app, forward a mail with a PDF to it, get an
answer by email, see the thread as a chat, and a mail with your address faked is not answered.

### Phase 2: the inbox

- Stranger mail kept in full for 30 days; the purge job; mailbox size limits.
- `mail.search`, `mail.read`, `mail.wait`, with the outside-content frame.
- The **Mail** screen under the bot's Email row: threads, strangers with **Allow** and
  **Block**, the "couldn't be confirmed" flag, files.
- Routines: the plus-tag filter; confirmed-senders-only and the daily cap for "anyone".
- An optional notification for mail from a new sender, at most one a day per bot (off by
  default).

**Done when** a receipt sent to `name+receipts@` is filed by a routine, and "what arrived this
week?" gets a true answer.

### Phase 3: writing to new people

- `mail.send` with the always-ask rule; the approval card with recipients and full text.
- Limits (§6.2, §8); `mail_suppressions`; `mail_events`; the events queue and
  `POST /hooks/mail/events`; the automatic pause.
- Admin: addresses, sends, bounces and complaints per workspace; pause and lift; reserved names.
- The terms gain the mail rules: no bulk or marketing mail, no pretending to be someone else.
- `usage_ledger` rows for sent mail.

**Done when** the bot writes to an outside address after one approval, the reply comes back
into the same chat, and a complaint event pauses a test address.

### Phase 4: sign-ups

- The context note (§7) and a built-in skill for signing up with the bot's address.
- A check against three real services (one with a code, one with a link, one that refuses the
  domain) on a computer.

**Done when** a bot signs up for a real service end to end with one approval.

## 12. Not in this plan

- **Your own domain** (`ada@yourcompany.com`). The domain work in D-329 makes it possible
  later; it needs per-domain DKIM and its own reputation handling.
- **Hosted addresses for self-hosted servers** through Casama Link.
- **A shared team address** that several members' chats use.
- **Calendar invites** sent or answered by mail.
- **Mailing-list sending** of any kind.
- **IMAP, POP or a webmail login.** The address is for the bot.
- **Approving by replying to an email.** Approvals stay in the app (and in Telegram and Slack
  buttons).

## 13. Decisions for Oliver

Each has a recommendation; the plan above assumes it.

1. **The domain.** Decided 2026-11-20: `casama.app`, used bare (§9.1).
2. **One address per bot** (recommended), or one per account with plus addresses, as Grok does.
3. **The numbers in §8.** Addresses, daily sends and mailbox sizes per plan.
4. **Free can't write to new people** (recommended), or a small number a day.
5. **The "Sent by Ada, an AI assistant working for Oliver" line** on first mails to new people:
   always (recommended), a switch per bot, or never.
6. **Full access never skips the approval for mail to new people** (recommended), or it can
   after the first approved mail to that person.
7. **Releasing an address:** allowed, with claims capped at the plan limit plus 3 a year (recommended), or never, as Grok does.
8. **Workspace admins:** on a workspace with several members, can any member who manages a bot
   claim an address (recommended), or only owners and admins?
9. **Stranger mail kept for 30 days** (recommended), or longer on paid plans.

## 14. Risks

- **Abuse of our domain.** Someone uses bots to send unwanted mail, and the whole domain's mail
  starts landing in spam. Covered by: approval on every first contact, no sending to new
  people on Free, daily caps, automatic pause, a separate domain so only bot mail suffers.
- **A stranger steering a bot.** Mail text that reads like an instruction. Covered by: stranger
  mail starts nothing; read mail is framed as outside content; the sender check; nothing in a
  mail counts as approval. A person who forwards a hostile mail to their bot is still exposed
  to what the bot does with it, as with a hostile web page.
- **Cloudflare Email Sending is in beta.** Its starting quota may be too low, or it may change.
  Covered by Phase 0 and the Resend fallback behind the same interface.
- **Sign-up forms that refuse the domain.** New domains and unusual endings get refused by some
  services. A `.com` reduces it; Phase 4 measures it.
- **People treating the address as their own mailbox.** It has no login, and mail from
  strangers expires. The claim sheet and the docs say so.
- **Private mail on our server.** Forwarded mail holds other people's personal details. It is
  stored like chat content, deleted with the workspace, never used for analytics, and named in
  the privacy page.
- **Squatting on names.** First come first served invites grabbing. Covered by the reserved
  list, the plan limits and the claims-a-year limit (plan limit plus 3).

## 15. How we'll know it worked

- Of bots in active workspaces, the share with an address after 30 days.
- Of addresses, the share that received mail from their owner in the first week.
- Mail-started runs a week, and the share that end without an error.
- Bounce and complaint rates on sent mail: under 2% and under 0.1%.
- Addresses paused automatically, and how many of those were real abuse.

## 16. Left for Oliver

- ~~Buy the mail domain and add it to the Stackwares Cloudflare account.~~ Done: `casama.app`.
- ~~Subscribe the Stackwares account to Workers Paid, for Email Sending.~~ Done 2026-11-20.
- Answers to §13.
- A yes for the Cloudflare changes (Email Routing, the Worker, Email Sending) when Phase 0
  starts, and for each deploy and app build after that.

## Sources

Checked 2026-11-20.

- Cloudflare Email Service pricing: https://developers.cloudflare.com/email-service/platform/pricing/
- Cloudflare Email Service limits: https://developers.cloudflare.com/email-service/platform/limits/
- Cloudflare Email Workers: https://developers.cloudflare.com/email-routing/email-workers/
- Cloudflare Email Routing postmaster notes: https://developers.cloudflare.com/email-routing/postmaster/
- Cloudflare routing addresses and plus addressing: https://developers.cloudflare.com/email-service/configuration/email-routing-addresses/
- Cloudflare delivery events: https://developers.cloudflare.com/email-service/reference/event-subscriptions/
- Resend pricing: https://resend.com/pricing
- Resend receiving: https://resend.com/docs/dashboard/receiving/introduction
- Amazon SES pricing: https://aws.amazon.com/ses/pricing/
- 9to5Mac on Grok Bot's address: https://9to5mac.com/2026/10/09/grok-bot-just-got-its-own-email-address-heres-how-to-claim-yours/
- CIAOPS on Grok Bot's address (quotes xAI's docs): https://blog.ciaops.com/2026/11/17/your-grok-bot-can-have-its-own-email-address-claim-it-carefully/
- CellCog on Grok Bot email: https://cellcog.ai/blog/grok-bot-email/
- Shipmail on Grok Bot email: https://shipmail.to/blog/grok-bot-email-on-your-own-domain
- AgentMail pricing (third party): https://www.eesel.ai/blog/agentmail-pricing
