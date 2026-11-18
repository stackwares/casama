# Domains runbook

What to do when something about sites, connected domains or bought domains needs a person
(D-329, `docs/SITES-AND-DOMAINS-PLAN.md`). Everything here is done from **Admin** → **Domains**
in the app (instance owners) or with read-only queries; nothing needs a deploy.

## Where to look

- **Admin** → **Domains**: counts, the registrar balance, orders that need a person (waiting for
  approval, retried more than once, refund failed), and every domain with **Suspend**.
- Read-only on the database:
  - `select * from domain_orders where status in ('needs_attention', 'refunding', 'paid', 'registering') order by created_at desc;`
  - `select kind, detail, created_at from domain_events where domain_id = '<id>' order by created_at desc;`
  - `select * from provider_cleanups where done_at is null;` (edge hostnames still to remove)
- Notifications instance owners get: `domain_order_approval`, `domain_order_attention`,
  `domains_balance`, `domains_capacity`.

## An order is waiting for approval

A workspace less than a day old paid for its first domain (§7.11: stolen cards buy domains).

1. Look at the workspace: its age, members, the name bought, other activity, reports.
2. Fine: **Approve**. It registers within a minute.
3. Not fine: do nothing. It's refunded automatically a day after payment (`not_approved`). For a
   clear fraud case, also suspend the workspace.

## A refund failed (`needs_attention`)

The domain couldn't be registered and Dodo refused or didn't answer the refund. The person was
not told yet that they were refunded.

1. Check the payment in the Dodo dashboard (the order's `payment_ref`): already refunded there?
2. **Retry** in Admin → Domains. Success sends the person the refund notice and email.
3. Still failing: refund by hand in the Dodo dashboard. Dodo's `refund.succeeded` webhook marks
   the order `refunded`. Tell the person, since the automatic notice only goes out on a refund
   Casama made itself.

## An order keeps retrying

`registering` with `attempts` above a few means the registrar isn't answering or is refusing.

- Registrar down: nothing to do; attempts continue with back-off and the order is refunded a day
  after payment if it never works (`registrar_unavailable`).
- Balance too low (Name.com answers 402): add credit at Name.com, then **Retry**.
- Contact refused by the registrar (a 4xx that isn't "not available"): the order is refunded
  (`registrar_refused`); ask the person to check their **Contact Details**.

**Retry** gives the order a fresh day of attempts from now.

## The registrar balance is low

`domains_balance` arrives when Name.com's prepaid credit is under `CASAMA_DOMAINS_BALANCE_ALERT`
(default $100), once a day at most. Add credit at Name.com. While it's empty, registrations and
renewals wait and retry, then refund.

## An abuse complaint (from the registrar, or reports)

Complaints reach the `abuse@` address given to the registrar, and site reports take a site down
by themselves at three reporters.

1. Look at the site and the evidence within 24 hours.
2. Real: **Suspend** the domain in Admin → Domains. Its hosts stop serving and leave the edge; a
   bought domain is also locked at the registrar and its site records are removed. For a whole
   workspace, suspend the workspace (its sites stop in the same lookup).
3. Answer the registrar with what was done and when.
4. Mistake: **Unsuspend**. Hosts go back through the DNS and certificate steps; a bought domain's
   records are set again.

## A customer asks about a domain they bought

- The registrar sends registrant emails (verification, its own renewal notices); Casama sends its
  notices with the price and a button. Both are expected.
- "My domain stopped working": check `registrant_verified_at`. Unconfirmed after 15 days, the
  registrar suspends it; the domain's screen offers to send the email again.
- Refunds after registration: sales are final. The registry's five-day delete window exists but
  is capped and charged by the registrar; use it only for clear mistakes, by hand at Name.com.

## A renewal didn't happen

- **The charge failed** (`domain_renewal_failed`): the person was told and the charge is tried
  again at E − 10, E − 7 and E − 3. Nothing for a person to do unless they write in; **Renew Now**
  on the domain's screen works any time.
- **Paid but not renewed:** the renew order sits in `registering` with attempts, like a stuck
  registration. Same steps as "An order keeps retrying"; a renewal that never works is refunded
  a day after payment.
- Check what the registrar has: `select expires_at, status from domains where name = '<name>';`
  against the registrar's dashboard. The daily reconcile copies the registrar's expiry; an
  expired domain renewed at the registrar becomes `active` at the next renewal or upkeep.

## A person asks to restore a lapsed domain

A domain 25 or more days past expiry is `lapsed`: Name.com removed it from the API. It may still
be in the registry's redemption period. Quote the restore fee from Name.com, take payment by hand,
restore it at Name.com, then set the row back:
`update domains set status = 'active', expires_at = '<new expiry>' where name = '<name>';`
(the next reconcile corrects the date). After the redemption period it's `gone` and can't be
restored.

## A registrant of a deleted workspace asks for the transfer code

The `domain_released` email tells them to write to support from the registrant address.

1. Check the address matches: `select r.email from domain_registrants r join domains d on d.id = r.domain_id where d.name = '<name>';`
2. Unlock and get the code at Name.com (the domain is in Casama's account), and send it to that
   address only.
3. It leaves the account when the transfer completes; nothing else to do.

## Custom hostnames are close to the included 100

`domains_capacity` arrives at 80 and 95 used. Past 100, Cloudflare charges $0.10 a hostname a
month; it's covered by plan and domain prices. Check `provider_cleanups` is draining, and that
unproved hosts are being given up on after 7 days.

## Live checks

Run against test systems only, never production:

- `apps/server/scripts/hostnames-live-check.ts`: custom hostnames on a test domain.
- `apps/server/scripts/registrar-live-check.ts`: Name.com's test system (api.dev.name.com).
