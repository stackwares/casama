# Bot email, next round: limits, storage, a sending ceiling and getting started

Status: **live** (written 2026-11-20, built and shipped the same day, D-451). Server deployed
(`9cfc36a2`); the web app with the email screens is live as build 61 (app.casama.ai). Cloudflare's
limit-increase form was filed for 10,000 sends a day. Left: the store builds, and raising
`MAIL_SEND_DAILY_MAX` once Cloudflare answers.

## 0. Summary

Bot email stays free per message. People pay through their plan's limits and through the credits
that mail-started runs spend. This round makes that safe and visible:

| Part | What changes |
|---|---|
| A. Limits | Smaller mailboxes and lower daily sending, before anyone relies on today's numbers |
| B. Storage | The mailbox size counts what is really stored; originals expire; people can delete mail |
| C. Sending ceiling | One count across all workspaces, under Cloudflare's daily allowance, with an alert |
| D. Getting started | The bot offers an address when it's needed; the offer card waits a day; plans show email |
| E. Shipping | Server, docs, and an app build that finally includes the email screens |

Nothing here adds a paid vendor or a new price.

## 1. What is true today (checked 2026-11-20)

- **Cost:** $5 a month for Cloudflare Workers Paid (3,000 sent emails included), then $0.35 per
  1,000. Receiving is free. Cloudflare allows the account **1,000 sends a day**, so the bill
  can't pass about $14.45 a month until that is raised.
- **Use:** none yet. Production has no addresses, no mail and no `emails_sent` rows.
- **Charging:** sent mail is recorded with its real cost, not billed. A run costs us $0.005 at
  the median and $0.014 on average (385 production runs, 14 days), 14 to 40 times the email that
  started it, and runs are already charged at cost × 1.4.
- **Limits live in production:**

  | | Free | Plus | Pro | Max |
  |---|---|---|---|---|
  | Addresses | 1 | 2 | 5 | 15 |
  | Mail to new people a day | 0 | 10 | 30 | 100 |
  | All mail a day | 20 | 100 | 300 | 1,000 |
  | Mailbox per address | 100 MB | 1 GB | 5 GB | 20 GB |

- **Storage:** mail sits on the server's own disk (193 GB, 129 GB free). The mailbox size is a
  cap on what an address holds at one time, not a monthly allowance.
- **Problems found:**
  1. Max's daily sending cap equals the whole Cloudflare allowance, and nothing counts sends
     across workspaces.
  2. One Max workspace may hold 15 × 20 GB = 300 GB, more than the server has.
  3. An attachment from an allowed sender is stored three times (inside the original mail, as a
     file, and as a chat attachment). Only the first is counted, so real use is about 2.5 times
     the mailbox size.
  4. Mail from allowed senders and sent mail never expire, and no mail can be deleted. A full
     mailbox refuses new mail, and the only ways out are upgrading or giving the address up.
  5. Nothing stored the original mail for: no code reads it back.
  6. A bot without an address is never told it could offer one.
  7. The offer card shows in the very first empty chat.
  8. The paywall and the plans table don't mention email.
  9. The welcome emails say "give a bot its own address", but no shipped app has the screens:
     web build 59 and the store builds were made from local `main`, which lacks the email work.

## 2. Part A: limits

One migration sets the new numbers and recomputes every workspace's limits. It overwrites these
two keys on every plan, weekly plans included (production still holds the defaults, so no Admin
edit is lost). Addresses and mail to new people stay as they are.

| | Free | Plus | Pro | Max |
|---|---|---|---|---|
| All mail a day (`mail_sent_day`) | 20 | 50 | 150 | 300 |
| Mailbox per address (`mail_storage_mb`) | 100 MB | 500 MB | 1 GB | 2 GB |

Worst case for a workspace that hits its sending cap every day: $0.21, $0.53, $1.58 and $3.15 a
month. Worst case for storage: 100 MB, 1 GB, 5 GB and 30 GB a workspace.

Also: `supabase/tests/plan_limits.test.sql`, `docs-site/guide/limits.md`,
`docs-site/guide/bot-email.md`, `docs/COSTS.md`.

## 3. Part B: storage

### 3.1 Count what is stored

`mail_messages.size` becomes the original plus the separately stored files. The mailbox check
and the Admin figures read the same column, so nothing else changes. The copy in the chat stays
under the chat attachment allowance, like any attachment sent in a chat app.

### 3.2 Originals expire

The original `.eml` is deleted 30 days after the mail arrived. The text (sealed in the row) and
the files stay. A new pass in `purgeExpiredMail` removes the object, clears `raw_key` and lowers
`size`. Nothing reads the original today; 30 days is kept for looking into a delivery problem.

### 3.3 People can delete mail

- **API:** `DELETE /v1/bots/{id}/email/messages/{messageId}`, and
  `POST /v1/bots/{id}/email/messages/delete` with `ids` (up to 200) or `before` (a date).
  Both remove the row's text and its stored objects. Members who can manage the bot only.
- **Caps can't be reset by deleting.** A sent mail younger than a day, and any mail younger than
  an hour in a thread, stays as an empty row (no text, no files) until the purge takes it, so
  the daily caps and the reply-loop guard still count it.
- **`GET /v1/bots/{id}/email`** gains `storage_used` and `storage_limit` in bytes.
- **Mail screen:** a storage line ("312 MB of 500 MB"), Delete on a mail and on a thread,
  select several, and "Delete mail older than…" (30 days, 6 months, a year), each confirmed.
- **Notices:** "almost full" once at 90%, and the mailbox-full notice now says "Delete old mail
  to make room, or upgrade" and opens the Mail screen. Today it says to release the address.
- **The bot does not delete mail.** No tool for it (§6 Q3).
- The chat copy of a file stays in its chat; deleting mail doesn't touch conversations.

## 4. Part C: a sending ceiling

- **`MAIL_SEND_DAILY_MAX`** (default 900): sends from every workspace together in the last 24
  hours, counted inside the same locked step as the workspace caps, so parallel sends can't pass
  it. Unset on a self-hosted server: no ceiling.
- **At the ceiling:** the send fails with "Mail is busy right now. Try again in a few hours",
  for every path (`mail.send`, replies, `channel.send`, the welcome mail).
- **Alert:** one notification a day to the instance owner at 80% and at 100%, and Admin → Mail
  shows "Sent today: 412 of 900".
- **Cap hits are tracked:** `limit_reached` with `kind` `mail_sent_day`, `mail_new_day`,
  `mail_send_ceiling` or `mail_storage`. No addresses, no text. Added to
  `packages/contracts/analytics/catalog.json`.
- **Ask Cloudflare for a higher daily allowance** (their limit-increase form). When it's
  raised, `MAIL_SEND_DAILY_MAX` on the server goes up with it. Both need Oliver's yes.

## 5. Part D: getting started, and showing it in the plans

- **The bot offers it.** `mailHint` gets a second branch, for a bot with no address on a server
  with hosted mail whose workspace still has room for one: "You can have your own email
  address. When the person asks for something mail would solve (forwarding you things, keeping
  receipts, signing up for a service, writing to someone), offer once in this chat to claim one
  with mail.claim. Don't bring it up otherwise." The claim still shows an approval card.
- **The offer card waits.** It shows once the bot is a day old or the person has had three chats
  with it, whichever comes first, and never in the Welcome chat. It stays dismissible.
- **The welcome email tip** becomes "ask your bot to get itself an email address", which works
  in every app version.
- **The paywall** gets one perk row from the plan's own limits: "Email addresses: 2", with
  "Writes to new people" where `mail_new_day` is above zero, and "Replies to you" on Free.
- **The plans table** in `docs-site/guide/usage.md` gets an email row.
- **Unchanged:** nothing in sign-up, no address claimed for anyone, Free keeps one address that
  can only reply to its allowed list.

## 6. Decisions for Oliver

1. **The numbers in §2**: 20 / 50 / 150 / 300 mails a day and 100 MB / 500 MB / 1 GB / 2 GB.
2. **Originals deleted after 30 days** (recommended), kept forever, or not kept at all.
3. **Only people delete mail** (recommended), or the bot may too, with an approval each time.
4. **The ceiling at 900 a day** until Cloudflare raises the allowance, and filing that request.
5. **The offer card after a day or three chats** (recommended), or as today, at once.

## 7. Phases

Targeted tests while building; the full suites once at the end through `scripts/heavy.sh`.

1. **Server and database:** Part A, Part B's server side, Part C, the bot's offer line, the
   welcome tip, tests. *Done when* a full mailbox can be emptied through the API, a 901st send
   is refused, and the caps hold after sent mail is deleted.
2. **App:** the storage line and deleting in the Mail screen, the offer card's timing, the
   paywall row, tests. *Done when* `flutter analyze` and the app tests pass.
3. **Docs:** limits, bot email guide, usage, `docs/COSTS.md`, the decision record (next free
   `D-` number), this plan's status and its row in `docs/PLANS.md`.
4. **Ship**, each with Oliver's yes:
   - the server (`scripts/deploy-prod.sh --dry-run`, then `--yes`) and the docs site;
   - the Cloudflare request;
   - **an app build that includes the email screens.** Local `main` (9 commits not pushed) and
     pushed `main` (12 commits local `main` lacks, the email work among them) have to be
     brought together first, in a clean worktree, and shown to Oliver before any build. Then the
     web app, and the store builds when he says.

## 8. Not in this round

- One storage allowance for the Library and mail together.
- Paid extras: more addresses (about $2 a month each, web only), addresses on a customer's own
  domain. Decide after 30 days of real use.
- Moving files to Cloudflare R2 ($0.015 per GB a month); worth it once the disk passes 60%.
- Moving bot mail to Amazon SES. It would cost about the same.
- A public "answer anyone" mode.

## 9. How we'll know it worked

- Storage per address in Admin matches the disk used by `mail/` to within a few percent.
- No workspace reaches the ceiling by itself.
- Of bots without an address, the share that claim one after the bot offered it.
- Cap hits by kind, a month in: which limit people reach first tells us what to raise or sell.
