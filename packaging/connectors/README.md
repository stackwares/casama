# Casama connector listings

Everything the AI-app connector directories ask for when we submit Casama's hosted MCP server:
Claude's Connectors Directory, ChatGPT apps, Gemini CLI extensions, Microsoft (Copilot Studio,
VS Code), Mistral Le Chat and others. Track each submission in `docs/launch/listings.md`.

Never put the review password or the review invite code in this folder: the repo is public. They
are in Vaultwarden, item **"Casama · store review account (review@casama.ai)"**.

## The server

| | |
| --- | --- |
| Name | Casama |
| MCP address | `https://api.casama.ai/mcp` (Streamable HTTP, stateless) |
| Docs-only address | `https://api.casama.ai/mcp/docs` (no sign-in) |
| Sign-in | OAuth 2.1: protected-resource and authorization-server metadata under `/.well-known/`, dynamic client registration (`/oauth/register`), PKCE S256 required, public clients. Redirects must be `https` or `localhost`. Access token 1 hour, rotating refresh token 60 days. |
| Scope of a connection | One person in one workspace, chosen on Casama's consent screen |
| Tool annotations | Every tool has a title, `readOnlyHint` and `openWorldHint`; every tool that writes has `destructiveHint` (checked by `packages/mcp/test/annotations.test.ts`) |
| Website | https://casama.ai |
| Docs for the connector | https://docs.casama.ai/guide/mcp |
| Privacy policy | https://casama.ai/privacy |
| Terms | https://casama.ai/terms |
| Support | support@casama.ai (security: security@casama.ai, privacy: privacy@casama.ai) |
| Status page | https://status.casama.ai |
| Publisher | Stackwares |
| Source | https://github.com/stackwares/casama (`packages/mcp`, Apache-2.0) |
| Category | Productivity (also: Automation, AI agents) |

## Logos

`assets/`: `casama-icon-1024.png`, `casama-icon-512.png`, `casama-icon-256.png`,
`casama-icon-64.png`. Square PNG, the same icon as the apps.

## Copy

**Name:** Casama

**Tagline (≤ 60 characters):** AI teammates with their own computers

**Short description (≤ 100 characters):**
Hand tasks to your Casama bots: each has its own computer and memory, and asks before risky steps.

**Long description:**

> Casama gives you AI teammates that do the work. Each Casama bot has its own cloud computer with
> a browser, files and apps, remembers how you like things done, and asks before it pays, sends or
> deletes anything.
>
> With the Casama connector, you can hand a task to one of your bots without leaving this chat:
> research a market, fill in a spreadsheet, check a website, draft a document. The bot works on
> its own computer and the reply comes back here, with the tools it used and what it cost.
>
> - **List your bots** and see which are busy.
> - **Ask a bot** and get its answer back, or continue an earlier conversation.
> - **Check on a run**: its status, cost, and the steps it took.
> - **Stay in charge**: see the steps waiting for approval. Approving from here is off unless a
>   workspace admin turns it on.
> - **Sites and domains**: see published sites, connect a domain and get the DNS records to add.
> - **Packs**: preview and install ready-made bots and skills from GitHub or Casama's directory.
>
> You sign in with your Casama account and choose one workspace; the connector can't see the
> others. Budgets, approvals and action rules from your workspace apply to everything it does.

**Example prompts** (use these in every form that asks for them):

1. "List my Casama bots."
2. "Ask my Casama bot to find three well-reviewed Italian restaurants in Lisbon and compare them in
   a table."
3. "Do any of my Casama bots have steps waiting for my approval?"
4. "What did that last Casama run cost, and which tools did it use?"
5. "Which of my Casama domains still need DNS records, and what should I add?"

## Tools

| Tool | Read only | Destructive | Open world | Notes |
| --- | --- | --- | --- | --- |
| `list_workspaces` | yes | | no | |
| `list_bots` | yes | | no | |
| `ask_bot` | no | yes | yes | The bot may use its computer and connected apps; risky steps wait for a person's approval |
| `get_run` | yes | | no | |
| `react_to_message` | no | no | no | Idempotent |
| `list_approvals` | yes | | no | |
| `decide_approval` | no | yes | yes | Refused unless the workspace allows approvals from AI apps |
| `list_sites` | yes | | no | |
| `list_domains` | yes | | no | |
| `get_domain` | yes | | no | |
| `check_domain` | no | no | yes | Looks up public DNS now; idempotent |
| `connect_domain` | no | no | yes | Admins; idempotent |
| `search_domains` | yes | | yes | Shows prices only; buying happens in the app |
| `list_packs` | yes | | no | |
| `preview_pack` | yes | | yes | Reads GitHub or the directory |
| `install_pack` | no | no | yes | No secrets over MCP |
| `search_docs`, `read_doc`, `list_doc_pages`, `get_api_operation` | yes | | no | Docs tools, also on `/mcp/docs` |

## Data and privacy (for the forms' data questions)

- **What the connector reads:** the workspace's bots and their status, the replies and run events
  of the conversations it starts or is given, pending approvals, sites, domains and packs.
- **What it can change:** sends messages to bots (which can then act through their own computer and
  connected apps, under the workspace's approvals and budgets), reactions, connecting a domain,
  installing a pack, and approvals only when an admin allows them.
- **What it never touches:** passwords and keys of the workspace's connections, billing, buying
  domains or credits, other workspaces.
- **Storage:** Casama stores hashed OAuth tokens and an audit log entry per connection. Messages
  and runs are stored as they are for chats in the Casama app. Model providers that receive chat
  content are listed in the privacy policy.
- **No selling or renting personal data, no ads, no training AI models on content** (privacy
  policy). Usage analytics never include message text and can be turned off in Settings → Privacy.

## Reviewer instructions

Paste this into the "testing instructions" field, then add the password and invite code from the
vault item in the form's own credential fields (never in a file in this repo).

> Casama Cloud is invite-only for now; use this demo account, which already has two bots
> ("Casama" and "Anna") and review credits, so nothing needs buying.
>
> 1. Add the connector with the address `https://api.casama.ai/mcp`.
> 2. When the Casama sign-in page opens, choose **Continue with Email → Use a Password Instead**
>    and sign in as `review@casama.ai` with the password provided. No two-step sign-in.
> 3. On "<app> wants to use Casama", keep the workspace **Reviewer's space** and tap **Allow**.
> 4. Try: "List my Casama bots", then "Ask the Casama bot to compare three note-taking apps in a
>    table". The answer takes about a minute and shows the tools used and the cost.
> 5. Approvals: steps that send, book, pay or delete wait for a person's approval. "Do any of my
>    Casama bots have steps waiting for approval?" lists them. Approving from the connector is
>    refused by default (a workspace setting); approve or deny in the web app at
>    https://app.casama.ai with the same account.

## Screenshots

Not taken yet. Most directories want 3–5 at 1280×800 or larger, from inside their own app:

1. The connector being added (the address field).
2. Casama's consent screen ("… wants to use Casama", workspace picker).
3. "List my Casama bots" with the answer.
4. An `ask_bot` answer with a table, the tools used and the cost.
5. A step waiting for approval, and the approval card in the Casama app.

Take them with the review account, in a browser tab, with no other personal data on screen. Save
them in `assets/screenshots/`.

## Per-directory notes

| Directory | Where | What's specific |
| --- | --- | --- |
| Claude Connectors Directory | Anthropic's remote MCP server submission form | Allow Claude's callback URLs (any https redirect is accepted by our dynamic registration). Needs the annotations, privacy policy, docs, support contact, reviewer account and example prompts above. |
| ChatGPT apps | OpenAI Platform → Apps (Apps SDK) | Needs a verified OpenAI organization. Tool-only apps are allowed; screenshots from ChatGPT. |
| Gemini CLI extensions | Public repo `stackwares/casama-gemini` with the `gemini-cli-extension` topic, built by `scripts/sync-gemini-extension.sh` from `packaging/gemini-cli/` | The gallery crawls daily; no form. |
| VS Code / GitHub MCP registry | github.com/mcp, which reads the official MCP Registry | `io.github.stackwares/casama` is already in the official registry; its `remotes` list only `/mcp/docs`. |
| Microsoft Copilot Studio | PR to `microsoft/PowerPlatformConnectors` (certified connector) | Slowest review; later. |
| Mistral Le Chat | Partnership request | Later. |
| xAI Grok | No public directory; business contact | Later. |
