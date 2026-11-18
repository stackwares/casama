# Payments with approval

A bot can pay a merchant for you, such as checking out an order on a website, with a single-use
virtual card that you approve each time. Cards come from your workspace's own Stripe Issuing
account, and the bot never sees the card number.

## Set up payments

Workspace owners connect payments once.

1. In Stripe, make sure your account has Issuing.
2. In Casama, open **Settings** → **Workspace settings** → **Payments**.
3. Enter your **Stripe secret key (with Issuing)**.
4. In Stripe, add a webhook pointing at the address shown under **Point a Stripe webhook here**,
   for the `issuing_authorization.request` and `issuing_authorization.created` events. Paste its
   **Webhook signing secret** into Casama.
5. Fill in the cardholder details: **Name on cards**, email, address and country.
6. Set the limits (see below), then tap **Save**.

Casama checks the key before saving, stores the key and signing secret encrypted, and creates the
cardholder in your Stripe account.

## Spending limits

| Limit                                 | Default | What it caps                                  |
| ------------------------------------- | ------- | --------------------------------------------- |
| **Workspace limit per month (USD)**   | $500    | Approved amounts across all bots this month   |
| **Per-bot limit per month (USD)**     | $200    | Approved amounts for each bot this month      |

Limits count the amounts of issued and used cards in the current calendar month. A request that
would go over a limit is refused before any card exists. The **Payments** row shows how much has
been spent this month.

## How a payment works

1. The bot asks to pay, with the merchant, amount, currency and reason.
2. You get an approval card showing the amount and merchant, such as "for $89.50". Approve or deny
   it.
3. When you approve, Casama issues a virtual card for that one purchase.
4. The bot fills in the checkout form. It gets placeholders, not card details, and Casama fills the
   real number, expiry date and security code into the page.
5. When the merchant charges the card, Stripe asks Casama to approve it in real time. Casama
   approves only the right charge, then cancels the card.

::: warning Payments always ask
Every payment asks you first, whatever the bot's autonomy level, "always allow" grants or action
rules. Choosing "always allow" on a payment approval has no effect.
:::

## Card rules

Each card is:

- **Single use.** After the first approved charge, the card is cancelled.
- **Limited to the amount plus 5%**, to cover tax or small differences.
- **Limited to one hour.** Unused cards are cancelled automatically.
- **Tied to the merchant.** A charge is approved only if a distinctive word from the approved
  merchant's name appears in the charge's merchant name, the currency matches, the amount is within
  the 5%, and the card is still valid.

Some purchases are never allowed, and no rule can relax this. Casama refuses these before a card
exists, based on the merchant and reason:

- Securities, stocks and brokerages
- Crypto
- Gift cards and prepaid cards
- Money transfers and wires
- Payment apps used to pay individuals

As a backstop, every card also blocks these merchant categories: securities brokers, money orders,
stored-value and gift card loads, wires, financial institutions, cash disbursements and gambling.

## Keeping card details private

The bot only ever handles placeholders. Casama fills them in only:

- in tools that accept secrets, such as filling a web form or making an HTTP request,
- for the card issued to that same run, while it's still valid.

Filled values are scrubbed from tool output, so card details never reach the model, the timeline or
the logs.

## Review payments

The **Payments** section in workspace settings lists the five most recent cards, with the amount,
merchant, status and reason. Statuses include issued, used, declined, expired and canceled.

## Limits

- Payments work only with your own Stripe Issuing account. Casama-issued cards on Casama Cloud
  aren't offered.
- Only owners can set up payments and change the limits.
- The per-bot limit applies to every bot. There's no setting to give one bot a different limit yet.
- Monthly limits are set in US dollars and compared with each card's amount as requested, without
  currency conversion.
- The Stripe connection follows Stripe's public API docs and has been tested against a stand-in, not
  yet against a live Issuing account.

## Related

- [Autonomy and approvals](/guide/autonomy)
- [Apps and connections](/guide/connections)
- [Usage and budgets](/guide/usage)
- [Privacy and data](/guide/privacy)
