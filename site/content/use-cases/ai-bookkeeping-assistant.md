---
title: AI bookkeeping assistant that matches receipts and asks first
h1: An AI bookkeeping assistant that prepares the books and asks before paying
card: Bookkeeping
crumb: Bookkeeping
description: A Casama bot matches receipts to transactions, sorts expenses and flags what's missing. It prepares everything for review, and every payment asks first.
lead: Bookkeeping is mostly matching one list against another. A Casama bot does the matching, sorts the expenses and shows you what is missing. It prepares the work for you or your accountant to check, and it never moves money without asking.
updated: 2026-11-18
order: 10
---

## What the bot does

- **Matches receipts to transactions.** By amount, date and merchant, with a note on how confident
  each match is.
- **Flags the gaps.** Transactions with no receipt, receipts with no transaction, and its best
  guess for each.
- **Sorts expenses.** Into categories, with recurring costs and simple totals.
- **Collects invoices.** From mail and files you point it to.
- **Builds a budget.** From your real numbers, in plain words.
- **Hands over a file.** A spreadsheet-ready list for each month that you or your accountant can
  check.

## Where it stops to ask

- **Every payment.** Payments always ask, whatever the bot's settings, and "always allow" has no
  effect on them.
- Sending email, such as a reminder about a late invoice, under the default setting.
- Changes in a connected accounting or payments app that you marked "always asks".

The Expense matcher persona is also told never to submit expense reports or move money. You set
the rest of the rules per bot and per action. See [how approvals work](/security).

## What it looks like

An example month:

1. You export the card transactions as a CSV file and send it to the bot with a folder of receipts.
2. The bot matches 61 of 68 transactions and marks four matches as uncertain.
3. It lists the seven with no receipt, with a guess for each: "probably the software subscription
   that renews on the 3rd".
4. You send two missing receipts. It updates the file and hands back the final list.
5. One supplier invoice is overdue. The bot drafts a polite reminder and asks before sending.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

## Set it up

1. Create a bot with the **Expense matcher** persona for receipts, or the **Budget** persona for
   sorting spending and planning.
2. Give it the data. A CSV export of transactions is enough. You can also connect mail, Google
   Drive or Sheets, Stripe or Zoho Books under Apps.
3. Mark each connected tool read-only, makes changes, or always asks. Read-only is a good start
   for anything that touches money.
4. Add a routine, such as "on the 1st of each month, match last month's receipts and list what is
   missing".

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## What it won't do for you

- It is not an accountant or a licensed adviser. The Budget persona is told to suggest a
  professional for tax and legal questions.
- A match can be wrong. The bot notes its confidence so you know which ones to check.
- It doesn't file returns or sign off the books. A person does that.

## Questions

### Can it pay an invoice?

Only with your approval each time, and only if your workspace owner has set up payments. The bot
never sees the card number. Money transfers and wires are never allowed.

### Does it need access to my bank?

No. An exported file of transactions is enough to start.

### Is my financial data used to train AI?

No. If you want it to stay on your own machine, self-host Casama.

### Does it work with my accounting software?

Stripe and Zoho Books are in the app catalog. Other tools connect through connector services or an
MCP server, where one exists. The bot can also work from exported files.

See [what else Casama bots do](/use-cases/).

{{cta}}
