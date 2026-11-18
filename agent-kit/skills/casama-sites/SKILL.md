---
name: casama-sites
description: "Put a Casama page on the web at its own address and connect a domain to it: publish and unpublish sites, check address names, connect bakery.com or shop.bakery.com, read the DNS records to add and the host states, Check Again, and look up domains to buy. Use for Casama sites, custom domains, DNS records, CLI `casama sites`/`casama domains`, @casama/client `sites`/`domains`, or the MCP domain tools."
---

# Casama sites and domains

A **site** is a page, game or folder site a bot built, made public at `<name>.<sites zone>`
(Casama Cloud: the sites zone in `GET /v1/config` → `sites.zone`). A **domain** is a name the
workspace owns elsewhere and **connects**, or one it **bought** through Casama. Full guide:
https://docs.casama.ai/guide/sites-and-domains.md. Operations: `get_api_operation` on the docs MCP
server, or https://docs.casama.ai/api/openapi.json (tags `sites`, `domains`).

## Is it on?

`GET /v1/config` (no auth) has `sites: { zone, custom_domains, buy_domains, tlds }`. No `sites`
object, or `zone: null`: this server has no sites. `custom_domains` false: no connecting.
`buy_domains` false: no buying (self-hosted servers never sell domains).

## Publish a site

```sh
# Is the name free? (answers why not: taken, retired, reserved, a brand)
curl -s "$API/v1/sites/address?org_id=$ORG&label=crumb" -H "$AUTH"
# Publish (the page becomes public); label is optional (default: from the title)
curl -s -X PUT "$API/v1/pages/$PAGE/site" -H "$AUTH" -H 'content-type: application/json' \
  -d '{"label":"crumb","indexable":false}'
# Unpublish (the page goes private; the name is kept for this workspace)
curl -s -X DELETE "$API/v1/pages/$PAGE/site" -H "$AUTH"
```

- Who: someone who can manage the page. Limits per plan (`402 plan_limit`): live sites 1 / 3 / 10
  / 50 (Free / Plus / Pro / Max). `indexable` (search engines) needs a paid plan.
- Errors: `409 address_taken`, `400 address_invalid` (with the reason), `403 email_unconfirmed`
  (Casama Cloud: the account's email must be confirmed before anything is public).
- A site serves the page's files only. No `/p/`, `/s/` or app paths, no cookies from the app.

## Connect a domain

```sh
curl -s -X POST "$API/v1/orgs/$ORG/domains" -H "$AUTH" -H 'content-type: application/json' \
  -d '{"name":"bakery.com","page_id":"'$PAGE'"}'
```

- `bakery.com` or `www.bakery.com` connects both `www` and (where the DNS company can point it)
  the bare domain; `shop.bakery.com` connects just that host. Admins only; domains per plan
  0 / 1 / 5 / 20.
- The answer's `domain.records` are what to add at the DNS company, in order: a CNAME from the
  host to the domain's own `target`, and a TXT ownership record. Each has `seen` (what DNS shows
  now) and `ok`. Don't invent records; show these.
- `claim` instead of `domain`: another workspace has it. Add the `_casama-claim` TXT record it
  names and connect again.
- States (`domain.state`, and per host `status`): `waiting_dns` → `waiting_cert` → `live`;
  `needs_attention` (a record was removed or changed: `status_reason` says which), `paused` (over
  the plan's limit). Only `live` serves visitors.
- `POST /v1/domains/{id}/check` checks now (at most once every 10 seconds; it also checks by
  itself). `PATCH /v1/domains/{id}` `{ "page_id": … }` changes the site; `DELETE` disconnects.

## Bought domains

- `GET /v1/domains/search?org_id=&q=` (admins, 30 a minute): names with `available`, `reason`,
  `price_usd` and `renew_price_usd` (before tax).
- Buying, renewing, DNS record edits and transfers are API routes for workspace admins
  (`/v1/orgs/{id}/domains/checkout`, `/v1/domains/{id}/renew`, `/records`, `/transfer-out`), but a
  person pays in the browser and the transfer code needs the workspace owner with a fresh sign-in.
  **Never buy, renew or move a domain on someone's behalf from a script or bot.** Bots get
  `domains.search` only, which links to Find a Domain in the app.

## From code

- CLI: `casama sites list|publish <page id> [--name]|unpublish <page id>`,
  `casama domains list|show <domain>|connect <name> [--page <id>]|check <domain>|disconnect <domain>`.
  Add `--json` for machine output.
- TypeScript (`@casama/client`): `client.sites.list(orgId)`, `.publish(pageId, { label })`,
  `.unpublish(pageId)`; `client.domains.list(orgId)`, `.get(id)`, `.connect(orgId, name, { pageId })`,
  `.check(id)`, `.setSite(id, pageId)`, `.disconnect(id)`, `.search(orgId, q)`.
- Dart (`casama_sdk`): `client.sites` (SitesApi) and `client.domains` (DomainsApi).
- MCP (`@casama/mcp`, and the hosted `/mcp`): `list_sites`, `list_domains`, `get_domain`,
  `check_domain`, `connect_domain`, `search_domains`.

## Bot tools

Inside Casama, bots have `sites.publish` (asks first), `sites.status`, `domains.connect` (asks
first; only a domain the workspace already has) and `domains.search`. No tool buys, renews,
transfers or edits DNS.
