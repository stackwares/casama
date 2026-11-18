# Sites and domains

A site a bot builds for you can go on the web at an address you'd tell someone: a name on Casama's
sites domain in one tap, or your own domain. Visitors open it like any website, over HTTPS, with
no sign-in.

A site is one of your [pages](/guide/pages): the same page in your [Library](/guide/library), with
the same versions and changes. Putting it on the web makes the page public.

## Put a site on the web

1. Ask a bot for a site, for example "Make a three-page site for my bakery with a contact form."
2. Open the site in the **Library** and tap **Publish to the Web**.
3. Choose its address name. The full address shows as you type, and Casama checks that it's free.
4. Tap **Publish**.

The address is `https://<name>.<sites domain>`, for example `https://crumb-bakery.<sites domain>`.
It works at once. Once it's on the web, the site's screen shows the address with **Copy** and
**Open**, and:

- **Let Search Engines Find It**: off at first. While it's off, search engines are asked not to list
  the site. On the Free plan it stays off.
- **Use Your Own Domain**: puts the site on a domain your workspace has, where the server offers it.
- **Unpublish**: takes the site off the web. The page goes private, and the address stays yours, so
  publishing again brings it back at the same address.

A bot can also put one of its own pages on the web with `sites.publish`. It always asks you first,
because the page becomes public.

### Address names

- 3 to 40 characters: letters a to z, digits and hyphens, not starting or ending with a hyphen.
- Some names are kept for Casama (such as `www`, `mail`, `api`, `admin`, `login`, `support`), and
  names that look like another company's sign-in page (a bank, a payment company, a large email or
  social site) can't be used.
- You can change a site's address once a day. The old name is kept for 90 days, so old links never
  show someone else's site. Your workspace can take it back sooner.

### What a site serves

- The page is the home page, at `/`. The site's other files are at their own paths:
  `/about.html`, `/img/logo.png`. A link to `/about` opens `about.html` (or `about/index.html`).
- A `404.html` in the site's files is shown for addresses that don't exist.
- `robots.txt` and `sitemap.xml` are made for you unless the site has its own. While search engines
  aren't allowed, `robots.txt` asks them to stay away.
- Forms work on every page of a site that takes input. Answers go to Casama, never to another
  server. See [Pages that take input](/guide/pages#pages-that-take-input).
- A site loads only its own files. Scripts, styles, fonts and pictures from other sites don't load;
  ordinary links to other sites work.
- Pages update for visitors within a minute of a change.

### Ask a bot for a good site

Bots are told how to build a site for the web: one `index.html`, relative links, a title and
description on every page, a `favicon.ico`, and their own `404.html` if you want one. To prove
ownership to Google Search Console, ask the bot to add the meta tag or file Google gives you.

### The badge and reports

Every site on a Casama address shows a small **Made with Casama · Report** link in a corner.
Visitors use **Report** to tell Casama about phishing, malware or anything illegal. When three
different people report a site, it goes offline on every address at once until someone checks it.
The sites domain's own page takes reports by address too.

## Use your own domain

A site can also open at a domain your workspace owns, such as `www.crumbbakery.com`. Workspace
admins connect domains in **Settings** → **Domains**, or from a site's screen with **Use Your Own
Domain**.

1. Tap **Connect a Domain You Own** and type the domain: `crumbbakery.com`, `www.crumbbakery.com`
   or a subdomain like `shop.crumbbakery.com`. Pick the site it should show.
2. Casama shows the DNS records to add, each with **Copy**. Add them where your domain's DNS is
   run (often the company you bought it from). When Casama knows that company, the steps are
   written for it.
3. Casama checks by itself: every minute for the first hour, then every hour. **Check Again**
   looks now. Beside each record you see whether Casama can find it yet.
4. Once the records are found, the domain gets its certificate (usually a few minutes), then
   shows **Live**. Visitors to the site's Casama address are sent to your domain from then on.

### `www` and the bare domain

Typing `crumbbakery.com` or `www.crumbbakery.com` connects both. `www` always works: it's one
CNAME record. Whether `crumbbakery.com` itself can open the site depends on your DNS company:

| Your DNS | What you add for `crumbbakery.com` |
|---|---|
| Cloudflare | A CNAME at the root (Cloudflare flattens it), set to **DNS only**, plus the TXT record |
| Anything else | Turn on **forwarding** from `crumbbakery.com` to `https://www.crumbbakery.com` at your registrar |

The domain's screen says which applies. One host is the **primary**; every other host of the
site sends visitors there. **Make Primary** changes it.

### Keeping it connected

- The records stay in place for as long as the domain shows your site. Casama checks once a day
  that they're still there. If they're missing for 7 days in a row, the domain is
  **disconnected**, and you get an email. Put them back and tap **Check Again**.
- Records that are never found are given up on after 7 days, and a certificate that never comes
  after 72 hours; the domain shows **Needs Attention** and why. **Check Again** starts over.
- A domain belongs to one workspace at a time. If another workspace started connecting it but
  never added the records, you can take it over after an hour. If another workspace has proved
  it, Casama shows a TXT record to add that proves it's yours, and then moves it.
- **Disconnect** removes a connected domain from Casama. Remove its records at your DNS company
  too.

A bot can point one of its own sites at a domain the workspace already has with
`domains.connect`. It always asks first. Bots can't connect, buy or move domains.

## Buy a domain

On Casama Cloud, workspace admins on a paid plan can buy a domain for a site without touching DNS.

1. In **Settings** → **Domains**, tap **Find a Domain** and type a name or a few words. Casama
   shows names on each ending it sells (.com .net .org .co .io .app .dev .xyz .me .info), with
   the price for the first year and the price it renews at. Taken and premium names are greyed.
2. Tap **Buy**. The first time, fill in the registrant's details: the person or business the
   domain is registered to. The email starts as your account's. Tick that you accept the
   [domain terms](/guide/domain-terms).
3. Pay in the browser. With **Renew automatically** on, the payment also keeps your payment method
   for renewals, and later purchases are charged to it with no browser step.
4. Casama registers the domain, sets its DNS, and points it at the site you picked. It's live in
   a few minutes, with nothing for you to add.

What to know:

- **Prices are before tax**; the payment provider adds tax where it applies. The renewal price is
  worked out from the registrar's cost on the day and shown on the domain's screen and in the
  notice a month before.
- **Sales are final once a domain is registered.** If a paid domain can't be registered (someone
  else got it first, its price went up, or the registrar refused it), Casama refunds you in full
  by itself and tells you.
- **Confirm the registrant email.** Within 15 days the registrar sends an email to the
  registrant's address; open it and confirm. Domain rules require it, and the domain stops working
  until it's done. The domain's screen shows the step until it is.
- A domain is registered for one year at a time and renews each year. Registration details are
  private: the registrar redacts them from public lookups at no charge.
- A workspace can buy 3 domains in its first 30 days and 10 a month after. A brand-new workspace's
  first purchase is checked by Casama before it registers, which can take a few hours.
- Buying and renewing show on the web, the desktop app, and the iPhone, iPad and Mac apps in the
  US App Store. In the Android app, and the App Store apps elsewhere, you can see, connect and
  manage your domains and turn automatic renewal off; buy or renew them from Casama on the web or
  the desktop app.

Bots can look up names and prices with `domains.search`, and their reply links to **Find a
Domain**. Only a person can buy a domain.

## Keep a bought domain

Everything about a bought domain is on its screen in **Settings** → **Domains**.

### Renewing

- **Renew automatically** (on by default) charges the payment method saved at purchase about two
  weeks before the domain expires, at that day's renewal price. If the charge fails, Casama tells
  you and tries again 10, 7 and 3 days before.
- You get a notice and an email a month before (with the price and whether it'll be charged), a
  week before and the day before. These are required notices about something you own, so they
  arrive even when other emails are off.
- **Renew Now** renews for a year at any time, in the browser. Renewing early never loses days:
  the year is added to the current expiry date.
- With **Renew automatically** off, you still get every notice and nothing is charged.

### If it expires

- On its expiry date the domain stops working, and so does the site on it.
- For 25 days after, it can still be renewed at the normal price with **Renew Now**. You get a
  reminder 3 days and 20 days after.
- After that the registrar takes it back. It may still be restorable for a while, for a restore
  fee, by writing to support; that isn't guaranteed.

### DNS records

**DNS Records** shows the domain's records, read live from the registrar. Add, change or delete
A, AAAA, CNAME, MX, TXT and SRV records: for email at another provider (MX, SPF, DKIM, DMARC), a
subdomain pointed elsewhere, or a site-verification record. The records your Casama site uses
are marked and locked; disconnecting the site is what removes them.

Showing another site on a subdomain (`shop.bakery.com`) needs no records: connect it, and Casama
adds its record by itself.

### Contact details and the registrant email

**Contact Details** changes the registrant's details for every domain the workspace bought. A
changed email has to be confirmed again: the registrar sends an email to the new address. Until
the registrant email is confirmed the domain's screen shows the step, with **Send Again**, and
Casama reminds you 3, 7 and 12 days after purchase.

### Moving a domain to another registrar

1. On the domain's screen, tap **Move to Another Registrar**. A new domain can't move for 60 days
   after purchase (a domain rule); the screen gives the date.
2. The workspace owner types the domain's name to confirm. You may be asked to sign in again.
3. Casama unlocks the domain and shows its transfer code once. Give it to the new registrar. The
   owner gets an email that a code was issued, and admins a notice.
4. **Lock Again** relocks it if you change your mind; Casama relocks it after 14 days if no
   transfer started.

When the move finishes, the domain shows as connected: the site stays up while the domain's DNS
at the new registrar still points here.

### Deleting a workspace with bought domains

The domains stay registered to their registrant until they expire, but they stop renewing and
their sites go offline. The registrant gets one email saying so, and can ask support for the
transfer code to move them.

## Limits

| | Free | Plus | Pro | Max |
|---|---|---|---|---|
| Live sites | 1 | 3 | 10 | 50 |
| Domains (connected or bought) | 0 | 1 | 5 | 20 |
| Search engines may list a site | No | Yes | Yes | Yes |

When you're at the limit, unpublish a site before publishing another, or upgrade. Self-hosted
servers have no limits.

If your plan changes and your workspace has more domains than it includes, nothing changes for 14
days; you hear about it on the first day and the tenth. Then the newest domains over the limit
are **paused**: visitors are sent to the site's own Casama address, which keeps working. Nothing
is deleted, and upgrading brings them back within the hour.

A site stops serving at once when its page is made private, deleted from the Library, taken down
after reports, or when its workspace is suspended. Undoing a delete brings it back.

## Who can publish

Anyone who can change the page: the person it was made for and the people who manage the bot. On
Casama Cloud you need to have confirmed your email address.

## Self-hosted servers

Site addresses are off until the server has a sites domain, and connected domains need the
server to make certificates for them. See
[Configuration](/self-hosting/configuration#sites-and-domains). On a self-hosted server the TXT
record is always required.
