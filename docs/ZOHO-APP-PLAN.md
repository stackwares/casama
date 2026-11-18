# Casama's own Zoho app: plan

Status: **built as D-350 (2026-11-17)**, with two changes from this draft: **one sign-in for all
four apps** (Zoho keeps at most 20 refresh tokens per person per client, so four separate
connections would use them up), and **no new integration kind** (it's `kind: "mcp"` with
`config.provider: "zoho"`, because shipped apps parse the kind strictly). See D-350 in
docs/DECISIONS.md for what was built; the rest of this page is the original draft.

## Why

Today (D-346, D-349) Zoho connects in two ways:

- **Zoho Mail, CRM, Desk, Books** sign in through Composio's managed sign-in. This works only
  where the server has Composio, and every tool call goes through Composio, which costs us usage
  and puts a third party in the middle.
- **Zoho MCP**: the person creates their own server on mcp.zoho.com and pastes its URL. It works
  everywhere, but it's fiddly.

Zoho has no MCP sign-in a client can register with, so an MCP-style "Sign in with Zoho" needs
Casama to own the sign-in and the tools. Goal: people sign in to Zoho with one click on Casama
Cloud **and** on self-hosted servers, with no Composio and no URL to paste, and bots get a small,
well-made set of tools for each Zoho app.

## Decisions to make (defaults in bold)

1. **Shape: a native integration kind (`zoho`) in the worker** (like the Composio and Pipedream
   adapters), not a separately hosted MCP server. It needs no new service to run or deploy,
   self-hosters get it for free, and the run's approvals, risks and cards (D-345) apply as with
   any integration. The alternative, a Casama-hosted MCP server at `api.casama.ai/mcp/zoho` that
   proxies Zoho's sign-in, would also serve other MCP clients, but nobody asks for that and it
   doubles the OAuth work.
2. **Which apps: Mail, CRM, Desk, Books** (the four D-349 tiles), one catalog app each, each its
   own connection, so a person can connect Mail without CRM. Later: Projects, Calendar, WorkDrive,
   Invoice, Bigin, which Composio doesn't manage or which people may ask for.
3. **Sign-in: one Casama client in Zoho's API console** ("Server-based application", multi-DC
   enabled) for Casama Cloud. Self-hosters register their own client and set
   `ZOHO_OAUTH_CLIENT_ID` / `ZOHO_OAUTH_CLIENT_SECRET`, as with Google. Scopes are asked per app,
   only what its tools need (below), plus `offline_access` (`access_type=offline`) for a refresh
   token.
4. **Order of preference in the catalog: own sign-in first, then Composio, then Zoho MCP.** The
   four apps become `auth: ["oauth"]`, `oauthClient: "preregistered"`, `composio: <slug>`.
   `catalogFor` already turns a preregistered app without a client into Composio's managed
   sign-in, so servers without a Zoho client keep today's behaviour and nothing changes for
   connections people already made through Composio.
5. **Data centres: follow Zoho's multi-DC flow.** Start the sign-in at `accounts.zoho.com`
   (`accounts.zoho.com.cn` stays out: China needs its own client). The callback carries
   `location` and `accounts-server`; the code is exchanged at that accounts server, and the token
   answer's `api_domain` is where API calls go. Both are kept in the connection's config; tokens
   are refreshed against the same accounts server. Accounts servers are checked against Zoho's
   list (`accounts.zoho.{com,eu,in,com.au,jp,ca,sa,uk}`, `accounts.zohocloud.ca`) so a forged
   callback can't send our client secret elsewhere.
6. **Tools: a hand-picked set per app, not the whole API.** Small and well described works better
   for models than hundreds of tools (Composio's CRM toolkit alone has 113). Each tool has a risk
   (reads low, writes medium, sends and deletes high) and returns structured results so plugin-style
   cards can show them.

## Tools (first version)

| App | Read (low) | Write (medium) | High |
| --- | --- | --- | --- |
| Mail | search messages, read message, list folders and labels | move, label, flag, mark read, save draft | send, reply, forward, delete |
| CRM | search records (any module), get record, list modules | create and update leads, contacts, deals, accounts; add note or task | delete record, convert lead |
| Desk | search tickets, get ticket with thread, find contact | update status, priority, owner; add private comment | reply to customer |
| Books | list and get invoices, bills, expenses, contacts; balance owed | create draft invoice, record expense, create contact | send invoice, record payment, void |

Scopes, in order: Mail `ZohoMail.messages.ALL,ZohoMail.folders.ALL,ZohoMail.accounts.READ`; CRM
`ZohoCRM.modules.ALL,ZohoCRM.settings.modules.READ`; Desk `Desk.tickets.ALL,Desk.contacts.READ,
Desk.basic.READ`; Books `ZohoBooks.fullaccess.all`, narrowed if Books' scopes allow. To check in
Zoho's API console when the client is made.

Account and organisation ids (Mail's account id, Desk's `orgId` header, Books' `organization_id`)
are looked up once after sign-in and kept in the config. When someone has several Desk or Books
organisations, the connect sheet asks which one (one connection per organisation).

## Pieces

1. **domain:** the four catalog entries switch to own sign-in with the Composio fallback; a
   `ZOHO_APPS` table (scopes, API base path, tools).
2. **server:** `/v1/apps/connect` gains a Zoho branch: builds the authorize URL with Casama's
   client, state and PKCE (Zoho supports it); the existing `/oauth/callback` handles Zoho's extra
   `location` / `accounts-server` params, checks the host, exchanges the code, looks up the account
   or organisation ids, and stores tokens in Vault as with other OAuth apps. Env:
   `ZOHO_OAUTH_CLIENT_ID`, `ZOHO_OAUTH_CLIENT_SECRET`, and optional per-DC secrets if Zoho's
   console gives different ones.
3. **agent:** `ZohoAdapter` (kind `zoho`): lists the app's tools from the table, calls Zoho's REST
   API on `api_domain`, refreshes tokens like `loadIntegration` does for OAuth secrets, and turns
   Zoho errors into the ToolErrors runs already understand (expired sign-in → the reconnect card,
   rate limit → retry later).
4. **app:** nothing new beyond the organisation picker when there's more than one; the connect
   sheet already handles OAuth apps.
5. **docs:** connections guide, self-hosting configuration (the two env vars and how to make a
   Zoho client), D-350, changelog, docs/COSTS.md (Zoho's APIs are free; per-app daily API
   limits noted).

## Tests

- domain: the table's tools have schemas, risks and scopes; catalog order own → Composio → MCP.
- server: a fake Zoho (accounts + API on 127.0.0.1) covering sign-in through a non-US data centre
  (callback with `accounts-server`, token exchange there, `api_domain` used), a forged accounts
  server refused, refresh, organisation lookup and the picker case, revoked access becoming
  "reconnect".
- agent: each tool against the fake API, including Mail send needing approval.
- A live check with a real Zoho account (Oliver's or a free test org) on the local stack before
  release, and once on Casama Cloud.

## Phases

1. Zoho client in the API console (Oliver: needs a Zoho account login; the client id and secret
   go to Vaultwarden), sign-in and callback with multi-DC, Mail tools, tests.
2. CRM, Desk, Books tools and the organisation picker.
3. Docs, live check, deploy (with Oliver's yes), app build if the picker needs it.

## Open questions for Oliver

- OK to use your Zoho account for the API-console client, or should we make a Casama Zoho
  account first?
- Keep Composio as the fallback once our own sign-in works on Cloud (default: yes, for servers
  without a Zoho client), or remove the Zoho Composio tiles on Cloud entirely?
- Any Zoho app beyond these four you want in the first version?
