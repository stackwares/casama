---
name: casama-overview
description: "Start here for anything built on or around Casama (AI teammates called bots, each with its own computer). Use when the user mentions Casama, casama.ai, a Casama bot, workspace, run, routine or approval, or asks how to integrate with it; it says which casama-* skill to load next."
---

# Casama overview

Casama gives people AI teammates, called **bots**, that keep working after the chat closes. Each
bot has instructions, memory, skills and its own sandboxed Linux computer. It is open source
(AGPL-3.0; SDKs, CLI, MCP server and plugin kit Apache-2.0; `ee/` separate), runs self-hosted or as Casama Cloud, and is reached from apps on every
platform, the `casama` CLI, chat apps, MCP clients and an HTTP API.

Full page: https://docs.casama.ai/introduction.md

## The nouns you will meet

| Concept | What it is | API paths |
| --- | --- | --- |
| Workspace (`org`) | Holds bots, chats, connections, model keys. Roles: owner, admin, member. Almost every row carries `org_id`. | `/v1/orgs`, `/v1/me` |
| Bot | Instructions (`persona_md`), a model policy, memory, skills, a computer, an autonomy level and budgets | `/v1/bots` |
| Conversation | A chat. Each bot has one main chat with you (**General**); bigger work gets **topics**. A conversation can include more than one bot. People and bots react to messages with one emoji each (D-331); the bot reads reactions as feedback. | `/v1/conversations` |
| Run | One piece of bot work, from a message, routine, webhook, chat app, A2A call or device trigger. A durable sequence of steps with a gap-free, numbered event log. | `/v1/runs` |
| Tool and risk | Bots act through tools (shell, files, browser, memory, connections, MCP). Each tool is low, medium or high risk. | |
| Autonomy and approvals | `ask_always`, `ask_risky` (default) or `autonomous` decides which tool calls wait for a person. A waiting run emits `approval.requested`. | `/v1/approvals` |
| Computer | An isolated Linux machine per bot (Ubuntu 24.04, Node.js 24, Python 3, Chromium). Sleeps when idle, wakes intact, has checkpoints. Internet only through an egress proxy that blocks private addresses. | `/v1/computers` |
| Routine | Starts runs without a person: `schedule`, `once`, `webhook`, `github`, `calendar_event`, `message`, `device`. Can end at `ends_at` or after `max_runs`. | `/v1/routines` |
| Skill | Agent Skills `SKILL.md` folder; bots see name and description each run and load the body when relevant. Workspace-wide or per bot. | `/v1/skills` |
| Plugin | Agent Plugins 1.0 package on GitHub (skills plus MCP servers), installed per bot, pinned to a commit | `/v1/plugins` |
| Connection | Built-in apps, any MCP server, OpenAPI, Composio, A2A agents. Secrets live in a vault and never reach the model. | `/v1/integrations`, `/v1/apps` |
| Library / creation | Everything a bot makes (pages, images, video, audio, documents, files), with versions and share links | `/v1/creations` |
| Gallery | Open catalog of themes, color schemes, wallpapers, skills, apps (hosted MCP servers), starter bots, routine ideas and reviewed plugins | gallery.casama.ai |

## Which skill to load next

| The task | Load |
| --- | --- |
| Write, test or publish a plugin (skills + MCP tools for bots) | `casama-plugin` |
| Call Casama from code: sign in, chat with a bot, stream run events, approvals, cancel, webhooks, Dart SDK, CLI | `casama-api` |
| Let outside agents call a bot, or let a bot call an outside agent | `casama-a2a` |
| A bot as a shareable `.casama-bot.json`, or routines and skills as Markdown files / git sync | `casama-bot-template` |
| Add an app, skill, starter bot, routine idea, plugin or look to the gallery | `casama-gallery` |
| Change the Casama repository itself (server, app, docs, migrations) | `casama-contribute` |

## Look things up instead of guessing

The `casama-docs` MCP server (Streamable HTTP, `https://api.casama.ai/mcp/docs`, no auth) answers
from the published docs and the OpenAPI document:

| Tool | Use it for |
| --- | --- |
| `search_docs(query, limit?)` | Find the page that covers a feature |
| `read_doc(page)` | Read a page; `page` is a path such as `/develop/plugins` or a full URL |
| `list_doc_pages()` | Every page, to browse |
| `get_api_operation(query)` | An operationId (`sendMessage`), `"METHOD /path"` (`"POST /v1/routines"`) or keywords; returns matching operations with parameters and schemas |

The local stdio server `npx -y @casama/mcp` has the same docs tools plus `check_plugin(path)`,
`gallery_search(query, types?)` (ready-made skills, apps, routines, bots, plugins, sets and looks
on https://gallery.casama.ai) and account tools (`list_workspaces`, `list_bots`, `ask_bot`, `get_run`, `list_approvals`,
`decide_approval`) that act as the person signed in with `casama login` or `CASAMA_TOKEN`.

Without MCP, fetch the docs directly:

- Index for agents: https://docs.casama.ai/llms.txt, everything in one file:
  https://docs.casama.ai/llms-full.txt
- Every page has a Markdown copy at its URL plus `.md`, e.g.
  https://docs.casama.ai/develop/plugins.md
- OpenAPI 3.1: https://docs.casama.ai/api/openapi.json (a running server also serves its own at
  `/openapi.json`, and an interactive reference at `/docs`)

Developer pages: `/develop/architecture`, `/develop/api`, `/develop/webhooks`, `/develop/a2a`,
`/develop/plugins`, `/develop/bot-templates`, `/develop/workspace-files`, `/develop/sdk`,
`/develop/cli`, `/develop/contributing`. User guides live under `/guide/`, self-hosting under
`/self-hosting/`.

## Where to send requests

- Casama Cloud API: `https://api.casama.ai` (the CLI's and `@casama/mcp`'s default). Everything is
  under `/v1`.
- A self-hosted server: its own API address (`https://casama.example.com` in the docs). The
  install is `git clone https://github.com/stackwares/casama && cd casama && ./install.sh --domain
  <domain>` (or `--local` to try it on one machine). Self-hosted has no paywall; billing is off.
- `GET /v1/config` (no auth) tells a client where to sign in (`supabase_url`,
  `supabase_anon_key`), the `api_version`, and whether `billing_enabled`.

## How it fits together

```text
Apps, CLI, chat apps, MCP clients
            |
        API server --- enqueues runs ---> Worker (agent loop, durable steps)
            |                                  |
 Postgres (RLS on every table) + Auth     Sandbox supervisor --> bot computers
 + Realtime                                                     (via egress proxy)
```

Full map: https://docs.casama.ai/develop/architecture.md

## Rules of thumb

- Check the gallery before building a skill, bot, routine, plugin or look: `gallery_search`,
  `casama gallery search`, or https://gallery.casama.ai/index.json and its sibling files.
- Never invent an endpoint or field: check `get_api_operation` or the OpenAPI document.
- Ignore unknown fields and unknown run event types; new ones arrive inside `/v1` without notice.
- Match errors on the problem `code`, never on `title` or `detail`.
- Secrets go in the vault (plugin secrets, workspace secrets, model keys), never in prompts, files
  or plugin `env`/`headers`.
- Anything a bot runs (plugin `stdio` servers, skill scripts) runs on the bot's computer, never on
  the Casama server.
