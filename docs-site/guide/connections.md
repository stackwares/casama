# Apps and connections

Connections give your bots tools beyond their own computer: your team's apps, any MCP server or
OpenAPI source, logins from a password manager, and keys they use for you. Every connection is
stored encrypted, and each bot gets only the connections you give it.

## Connect an app

Casama ships with a catalog of apps that run their own hosted MCP servers, so you connect them
directly with no middleman. Owners and admins connect apps for the workspace.

1. Open **Settings** → **Integrations**. The screen is called **Apps**.
2. Pick the **Browse** tab, then search or filter by category.
3. Tap an app. The connect sheet shows what bots can do with it.
4. Connect it one of these ways, depending on the app:
   - **Continue with** the app: one-click sign-in. Your browser opens the vendor's sign-in page.
     Approve access there and the sheet updates by itself.
   - **API key**: follow the steps on the sheet, which link to the vendor's key page. Casama tests
     the key when you save it.
   - No sign-in: some apps work as soon as you add them.
5. Under **Which bots can use it?**, pick the bots, then tap **Done**.

The connection now shows on the **Connected** tab. You can also give a connection to a bot later
from the bot's settings: **Bot settings** → **Integrations for this bot**. Its tools show up the next
time the bot runs.

### The catalog

Each app tile shows how it connects: **One click**, **API key**, **No sign-in** or **Needs setup**.

| Category     | Apps                                                                                  |
| ------------ | ------------------------------------------------------------------------------------- |
| Developer    | GitHub, Sentry, Linear, Vercel, Supabase, Neon, Cloudflare Docs, Context7              |
| Data         | PostHog, Hugging Face, Airtable, Exa                                                   |
| Productivity | Notion, Jira & Confluence, Asana, monday.com, Box, Slack                               |
| Google       | Gmail, Google Calendar, Drive, Docs, Sheets, Slides, Contacts                          |
| Payments     | Stripe                                                                                 |
| Design       | Figma, Webflow                                                                         |
| Sales        | HubSpot, Intercom                                                                      |
| Automation   | Zapier, Composio, Pipedream                                                            |

Cloudflare Docs works without signing in. Hugging Face, Context7 and Exa work without signing in
and also take an optional API key.

### When an app says "Needs setup"

Some vendors don't let apps register themselves for one-click sign-in. For those, whoever runs
your Casama server registers an OAuth client with the vendor once. The connect sheet says so and
shows the redirect address to register, which is `<your API address>/oauth/callback`.

| App                                          | What the server needs                                     |
| -------------------------------------------- | --------------------------------------------------------- |
| Gmail, Calendar, Drive, Docs, Sheets, Slides, Contacts | `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` |
| GitHub, Slack, Asana, HubSpot, Box, Figma    | An entry in `MCP_OAUTH_CLIENTS`                           |

Until that's done there are two other ways in:

- **The server has a Composio key** (`COMPOSIO_API_KEY`, as on Casama Cloud): these apps show
  **Sign in through Composio**. One click, and you sign in to the app itself; Composio handles the
  connection on the server's account, and the bot gets the app's tools.
- **No Composio key:** the connect sheet offers **Composio**, **Pipedream** or **Zapier** with one
  click (sign in with your own account there), then ask your bot to use the app through it.

Vendors only send people back to `https` or `localhost` addresses. A server on a private network
address over `http` (local development) uses `http://localhost:<port>/oauth/callback`, so finish
the sign-in in a browser on that machine. Set `OAUTH_REDIRECT_URL` to use another address.

`MCP_OAUTH_CLIENTS` is JSON keyed by app id:

```json
{ "slack": { "client_id": "123.456", "client_secret": "your-client-secret" } }
```

GitHub also accepts a fine-grained personal access token, so it works without this setup. See
[Configuration](/self-hosting/configuration) for where server settings go.

## Manage a connection

Tap a connection on the **Connected** tab to open its page. From there you can:

- See its health (**Ready** or **Needs attention**) and **Test connection**, which also refreshes
  its list of tools.
- **Reconnect** when a sign-in expired or was revoked.
- Change **Bots with access**.
- Set each tool's approval level under **Tools**:

| Level             | What happens                                                                        |
| ----------------- | ----------------------------------------------------------------------------------- |
| **Read-only**     | Runs on its own.                                                                    |
| **Makes changes** | Asks first when the bot has read something untrusted, per the bot's autonomy level. |
| **Always asks**   | Waits for you every time.                                                           |

- **Disconnect**. Bots lose its tools right away, and the saved sign-in is deleted.

Signed-in connections refresh their tokens automatically shortly before they expire.

On a run's timeline, tools from a connection are named after it, such as `mcp.github.create_issue`.

## Google permissions

Casama uses Google's own MCP servers and asks for as little as it can:

| Connection          | Google scopes                                               | What a bot can do                                  |
| ------------------- | ----------------------------------------------------------- | -------------------------------------------------- |
| **Gmail**           | `gmail.modify`, `gmail.compose`                             | Search and read email, draft replies, label threads |
| **Google Calendar** | `calendar.events`, `calendar.calendarlist.readonly`, `calendar.events.freebusy` | See your schedule, create and move events, find free time |
| **Google Drive**    | `drive.file`                                                | Only files you pick or that the bot creates        |
| **Google Docs**     | `documents`                                                 | Read and edit documents                            |
| **Google Sheets**   | `spreadsheets`                                              | Read and update spreadsheets                       |
| **Google Slides**   | `presentations`                                             | Read and edit presentations                        |
| **Google Contacts** | `contacts.readonly`, `directory.readonly`                   | Look up people                                     |

Google's Gmail server can't send email: the bot writes drafts and you send them from Gmail. Each
Google app is its own connection with its own consent.

::: warning Google Developer Preview
Google's MCP servers are in Developer Preview. Tool calls only work once your server's Google
Cloud project is enrolled in the
[Workspace Developer Preview Program](https://developers.google.com/workspace/preview), which
needs a Google Workspace account. When you set up the Google client, turn on **Use this client
for an AI-powered agent**, enable each product's API and MCP API (for example `gmail.googleapis.com`
and `gmailmcp.googleapis.com`), and add your redirect address.
:::

On Casama Cloud, Gmail connects through Composio's Google sign-in until Google's servers are
generally available.

## Composio and Pipedream

Composio and Pipedream each sign in to hundreds or thousands of apps for you, so you never handle
those apps' keys. The quickest way is the **Composio** or **Pipedream** tile in the catalog: one
click, sign in with your account there, and each app is connected the first time a bot needs it.

If you'd rather use your own API key or Pipedream Connect project:

1. Open **Settings** → **Integrations** → **Browse**, and scroll to **More ways to connect**.
2. Tap **Composio** or **Pipedream**.
3. Tap **Get a free key** to open the provider's site, then paste your key. Pipedream needs a
   **Project ID**, **Client ID** and **Client secret**.
4. Tap **Connect**.
5. Tap **Add an app**, search the provider's directory and tap **Connect** next to an app. The
   provider's own sign-in page opens.

Connected accounts show with their status: connected, pending or error.

## Add a custom server

Connect any MCP server, an OpenAPI spec or another AI agent.

1. Open **Settings** → **Integrations**, then tap **Custom server**.
2. Choose a **Type**:

| Type               | You fill in                                                                    |
| ------------------ | ------------------------------------------------------------------------------ |
| **MCP server**     | **Server URL**, and an optional **Authorization header**                       |
| **OpenAPI**        | **OpenAPI spec URL**, an optional **Base URL**, and an optional secret's name  |
| **AI agent (A2A)** | **Agent address or agent card URL**, and an optional **Access token**          |
| Composio           | Toolkits, such as `github, gmail`, and an API key                              |
| Pipedream Connect  | Project ID, client ID, client secret and apps                                  |

3. Give it a **Name**: lowercase letters, numbers and underscores. Its tools are named after it.
4. Tap **Save**, then give it to bots from its page or from **Integrations for this bot**.

MCP servers can use Streamable HTTP or legacy SSE. For OpenAPI, the secret's name refers to a
secret from **Settings** → **Secrets** and is sent as a bearer token.

MCP servers that run on your own computer are added from the desktop app. See
[Your own computer](/guide/companion). For agents, see [Bots working together](/guide/bots-together).

## Secrets

A secret is a token or password a bot can put into a request without ever seeing it. Each secret
is sent only to the hosts you allow.

1. Open **Settings** → **Secrets** and tap **Add secret**.
2. Choose **Key or password**.
3. Enter a **Name** in uppercase, such as `GITHUB_TOKEN`, and the **Value**.
4. Under **Allowed hosts**, list where it may go, comma-separated, such as `api.github.com`.
5. Tap **Save**.

Bots write `{{secret:GITHUB_TOKEN}}` in a request. Casama fills in the real value only when the
request goes to an allowed host or one of its subdomains, and refuses otherwise. Secrets can be
used in `http.request` (headers or body) and typed into web pages with `browser.fill`. Filled
values are scrubbed from tool output, so they never reach the model or the timeline.

Owners and admins add secrets. Admins can also keep secrets in the workspace's own Infisical
project: **Settings** → **Workspace settings** → **Where secrets are kept**.

### When a bot asks for a secret

If a bot needs a key you haven't saved, it can ask for one in the chat. A protected card appears:
"Ada needs a Stripe key", with the hosts it's for and the bot's reason.

1. Paste the value into the masked field. The field never suggests, autocorrects or learns.
2. Tap **Save**, or **Decline**.

The value goes straight into the vault, limited to that bot and those hosts. The bot only hears
that the secret was saved and how to use it. The run waits up to 24 hours for an answer.

The person who started the run or an admin can answer. A bot can only ask for hosts under one
domain, such as `api.stripe.com` and `files.stripe.com`. If a secret with that name already
exists, only an admin can replace it.

## Sign-in codes

Bots can sign in to sites that use two-step codes, without holding the two-step key.

1. Open **Settings** → **Secrets** → **Add secret** and choose **Sign-in code**.
2. Paste the site's **Two-step key or otpauth:// link**. On a phone, tap **Scan QR code** instead.
   The name is suggested from the site.
3. Add the **Allowed hosts** and tap **Save**.

Bots write `{{totp:NAME}}` and get the current code at the moment the tool runs, only on the
allowed hosts. The key itself never leaves the vault: `{{secret:NAME}}` on a sign-in code is
refused. A bot can also ask for a sign-in code in the chat, with the same card.

Casama supports time-based codes: SHA-1, SHA-256 or SHA-512, 6 to 8 digits, with periods from 10
to 300 seconds.

## Password managers

Bots can sign in with logins from 1Password or Bitwarden. They never see a password.

1. Open **Settings** → **Workspace settings** → **Password managers**.
2. Tap **Connect a password manager** and choose one:
   - **1Password**: your **Connect server address** and a service account's **Connect token**.
   - **Bitwarden**: your **bw serve address** and an optional **Access token**. This uses
     Bitwarden's Vault Management API for your organization's collections.
3. Choose **Just me** or, as an admin, **For the whole workspace**.
4. Under **Vaults bots may use**, tick the vaults or collections. Nothing is available until you do.

Casama checks the token before saving it, and never shows it again.

How bots use logins:

- A bot lists logins by name, with each login's sites and whether it has one-time codes.
- It writes `{{login:Name:username}}`, `{{login:Name:password}}` or `{{login:Name:otp}}` into
  `browser.fill`.
- Casama fills the value only when the page is on one of that login's own sites or their
  subdomains. Anywhere else it refuses and names the login's sites.
- Filled values are scrubbed from output.

A **Just me** password manager works only in runs acting for you, such as your own chats and your
own routines.

## Paid data services

Bots can buy single calls to paid data APIs (places, emails, SEO and more) through Treg's catalog.

1. Open **Settings** → **Model keys** → **Add key**.
2. Choose **Treg** as the **Provider** and paste your Treg key.

A bot searches the catalog, and each result shows its price. Buying a call asks first under the
default autonomy, with the service and price on the approval card, such as "for $0.0040 per call".
Treg charges your own account directly, with no Casama markup, and each call shows in
[Usage](/guide/usage). A call can't cost much more than the approved price, and failed calls
aren't charged.

## Plugins

A plugin bundles skills and MCP tools in one install from GitHub. Open **Bot settings** →
**Plugins** to add one. Plugin servers run on the bot's computer, never on Casama's servers. To
build one, see [Building plugins](/develop/plugins).

## Limits

- The Composio and Pipedream connections follow the providers' public API docs and haven't been
  checked against live accounts yet.
- The Treg connection follows Treg's public guides and hasn't been checked against a live account
  yet. Buying data calls through Casama Cloud credits isn't offered.
- Bitwarden Secrets Manager isn't supported. Use named secrets for key-value secrets.
- In the app, a secret is available to every bot in the workspace. Limiting a secret to certain
  bots is possible through the API only.

## Related

- [Autonomy and approvals](/guide/autonomy)
- [Your own computer](/guide/companion)
- [Bots working together](/guide/bots-together)
- [Building plugins](/develop/plugins)
- [Privacy and data](/guide/privacy)
