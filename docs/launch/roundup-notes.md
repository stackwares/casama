# Notes to roundup authors (drafts, not sent)

Part F of `docs/SEO-PLAN.md` (D-381). Short notes to people who already wrote a list where Casama
belongs. Send from Oliver's own mailbox, one at a time, each changed to fit the article. Don't send
before the public launch: a list author will open the repository first, and stars and a release
history are what they look at.

Rules: one note per author, no follow-up more than once, never ask for a link or a ranking, and say
plainly that we make Casama.

## Where to send

| Article | Why Casama fits |
|---|---|
| https://www.bitdoze.com/best-open-source-grok-bot-alternatives/ | Its criteria include "a real computer per bot"; it lists Rakazo, MausBot and OpenBot |
| https://www.scriptbyai.com/best-open-source-grok-bot-alternatives/ | Same set of products |
| https://www.tooljunction.io/blog/open-source-grok-bot-alternatives | Same set of products |
| https://www.simular.ai/alternatives/grok-bot-alternatives | Lists Rakazo |
| https://every.to/personal-agents-comparison | Has rows for approvals, computer use and where it runs |
| https://resources.rework.com/tools/ai-agents/best-personal-ai-agents-2026 | Updated monthly |
| https://itsfoss.com/openclaw-alternatives/ | Self-hosted angle |
| https://aimultiple.com/openclaw-alternatives | Research-style roundup |
| https://openalternative.co/blog/best-open-source-ai-agents | Lists none of the twins yet |
| https://dev.to/paxrel/12-best-open-source-ai-agents-you-can-self-host-in-2026-1nbc | Self-host angle |
| https://www.ssdnodes.com/learn/best-self-hosted-ai-agents | Self-host angle |
| https://toolradar.com/guides/best-open-source-ai-agents | Lists none of the twins yet |

## The note, for an open-source or self-hosted list

Subject: An open-source agent for your \<article title\> list

Hi \<name\>,

I read your piece on \<topic\>. You judged the tools on \<the criterion they used, in their words\>,
which is the thing I care about too, so I thought you might want to know about one more.

I make Casama. It's open source (AGPL-3.0) and gives each bot its own sandboxed Linux computer,
with approvals on by default and a checkpoint saved before destructive commands. It self-hosts with
one command and any model, including local ones, and has native apps on phone and desktop.

Where it's weaker than what you listed: it's new, the community is small, and it has ten chat apps
where OpenClaw has about thirty.

Code: https://github.com/stackwares/casama
A comparison with sources, including where the others are the better pick:
https://casama.ai/compare/rakazo-vs-openbot-vs-mausbot

If you try it and something is wrong or missing, I'd like to hear it either way.

Oliver

## The note, for a personal-assistant comparison

Subject: One more for your personal agents comparison

Hi \<name\>,

Your comparison has rows for \<approvals / where it runs / computer use\>, which most write-ups
skip. I make Casama, an open-source agent that might fit a row: each bot works on its own computer
that you can watch and take over, payments always ask, and you can run the whole thing on your own
server.

It isn't as polished as the big labs' apps, and it's a week into being public. It's free to try at
https://app.casama.ai, and the rules for what a bot must ask are written down here:
https://casama.ai/security

Happy to answer anything, or to be told why it doesn't belong.

Oliver

## Articles AI answers cite (checked 2026-11-18)

Articles that ChatGPT, Gemini and Google AI Overviews cite for open-source agent and
OpenClaw/Hermes/Grok Bot/Instinct alternatives. Fetched on 2026-11-18. Only contact routes the site
or author publishes are listed; none of these has been contacted. "Updated" is the date the page
shows; "not shown" means the page has none (the published date is given instead). Vendor pages
(a company's own blog) rarely list rivals, so they are marked poor fit.

| Article | Updated | Author | How to reach them | Lists | Fit |
|---|---|---|---|---|---|
| [7 Best Open-Source AI Agent Platforms in 2026](https://agenta.ai/blog/best-open-source-ai-agent-platforms) | not shown (published 2026-10-23) | none shown (Agenta blog) | team@agenta.ai and https://www.linkedin.com/company/agenta-ai/ (company, from agenta.ai/contact); no form | Agenta, Dify, n8n, OpenHands, Langflow, LibreChat, CrewAI | Poor fit: Agenta's own blog ranks Agenta first, and the list is workflow/LLMOps platforms, not personal agents |
| [8 Best Grok Bot Alternatives in 2026](https://agenta.ai/blog/best-grok-bot-alternatives) | not shown (published 2026-09-07) | Mahmoud Mabrouk | team@agenta.ai (company); no personal profile published | Agenta, OpenClaw, Manus, ChatGPT Work, Claude Cowork, Perplexity Computer, Lindy, Hermes Agent | Poor fit: vendor roundup that puts its own product first, though it does list OpenClaw and Hermes; low odds |
| [9 Best AI Coworker Platforms for Business Teams in 2026](https://agenta.ai/blog/ai-coworker-platforms-for-business) | not shown (published 2026-09-22) | Mahmoud Mabrouk | team@agenta.ai (company); no personal profile published | Agenta, Claude Cowork, ChatGPT Work, Microsoft 365 Copilot Cowork, Dust, Relevance AI, Lindy, Zapier Agents, n8n | Poor fit: business-team coworker tools from a vendor, no open-source personal agents |
| [The Best Hermes Agent Alternatives in 2026](https://aiengineerinsights.com/blog/hermes-agent-alternatives/) | 2026-10-27 (published 2026-08-10) | Gurram Poorna Prudhvi | No email or form shown; site footer links https://github.com/aiengineerinsights and a mentorship booking page (topmate.io/poorna_prudhvi_gurram, a paid-session page, not a tool-submission route) | Hermes Agent, OpenClaw, LangGraph, CrewAI, Microsoft AutoGen, Open Interpreter, Agent Zero (Manus in FAQ only) | Good fit: independent blog, recently updated, covers open-source agents; Casama is a self-hostable open-source alternative with a computer per bot. No clean contact route, so a GitHub issue or the author page is the only public way |
| [10 Best OpenClaw Alternatives in 2026](https://composio.dev/content/openclaw-alternatives) | 2026-09-16 | Sunil Kumar Dash (composio.dev/authors/sunil-kumar-dash) | No email, form or social link shown | Hermes Agent, TrustClaw, ZeroClaw, PicoClaw, NanoClaw, Oasis, Instinct, Grok Bot, Claude Cowork, Perplexity Computer, Vellum (Manus, Kimi Claw named only) | Poor fit: Composio's marketing blog, and no public route; it mixes open and hosted agents, so the content would fit if a contact turned up |
| [OpenClaw alternatives in 2026: Hermes, NanoClaw, Claude and more](https://askgpu.com/openclaw-alternatives/) | 2026-10-20 | Saurabh Khatri | hello@askgpu.com (shown on the page); also askgpu.com/contact/ and /partners/ | Hermes Agent, NanoClaw, nanobot, ZeroClaw, PicoClaw, IronClaw, NVIDIA NemoClaw, KiloClaw, managed OpenClaw hosts, Claude, Claude Code, ChatGPT Work, Microsoft Autopilot, n8n | Good fit: independent guide in an "OpenClaw, analyzed" series that already lists many small open-source agents; Casama adds a sandboxed computer and approvals by default. Best contact route of the set |
| [Hermes Agent Alternatives: 7 Agents Checked for Import, Local Models and Approvals](https://atomicagent.io/compare/hermes-agent-alternatives/) | not shown (published 2026-10-23) | Nadya Dudka and Andrew Dyuzhov | No email or form; site links X https://x.com/atomicagent_io, LinkedIn, GitHub issues and a Discord | Atomic Agent, OpenClaw, Goose, Moltis, NanoClaw, ZeroClaw, Nanobot | Poor fit: Atomic Agent's own site, but its criteria (local models, approvals) match Casama, so a vendor-to-vendor note is possible; low odds |
| [OpenClaw Alternatives in 2026: 7 Options Compared](https://atomicbot.ai/blog/openclaw-alternatives-in-2026) | not shown (published 2026-08-11) | Andrew Dyuzhov | support@atomicbot.ai (shown on page) | Hermes Agent, Codex, NanoClaw, ZeroClaw, nanobot/PicoClaw, Claude Cowork, Claude Code (OpenClaw, Atomic Bot, Manus, Kimi Claw named in text) | Poor fit: Atomic Bot sells managed hosting and the support address is not a suggestions route |
| [Best 50+ Open Source AI Agents Listed](https://aimultiple.com/open-source-ai-agents) | 2026-10-13 (header also says Aug 16, 2026) | Cem Dilmegani and Hazal Simsek | https://www.linkedin.com/in/cem-dilmegani/ and https://www.linkedin.com/in/hazal-simsek/; contact form at https://aimultiple.com/contact-us (work-email form, a sales-style form); a comment form on the article; https://x.com/aimultiple | Frameworks and runtimes (LangGraph, AutoGen, CrewAI, Auto-GPT, OpenManus...), workflow tools (n8n, Activepieces...), web, coding, finance and other categories; no OpenClaw-style personal agents | Partial fit: a broad directory that could take Casama under "Agent runtimes" or "Personal assistance"; it is a commercial analyst site, so use the LinkedIn route, not the sales form |
| [Best AI Personal Assistant Apps: 10 That Actually Work (2026)](https://cowork.ink/blog/ai-personal-assistant-app/) | not shown (no date) | none shown | None: nav is Home, Blog, Company only | ChatGPT, Claude, Gemini, Microsoft Copilot, Motion, Reclaim.ai, Perplexity, Notion AI, Superhuman, GoGogot | Poor fit: mainstream assistants plus the publisher's own products, and no contact route |
| [Instinct AI Alternatives You Can Use Today, No Invite Needed](https://cellcog.ai/blog/instinct-ai-alternatives/) | 2026-10-26 (published 2026-08-27) | Nitish Garg, founder and CEO of CellCog (cellcog.ai/blog/authors/nitish-garg/) | No email, form or social link shown | CellCog, OpenClaw, ChatGPT agent, Grok Bot, Vellum, Lindy, Manus (Instinct, Poke, Tab, Underdog named only) | Poor fit: CellCog's own blog ranks CellCog first and no public contact route; Casama is open source and self-hostable, but this is a hosted-product list |
| [I Ignored 30+ OpenClaw Alternatives Until OpenFang](https://agentnativedev.medium.com/i-ignored-30-openclaw-alternatives-until-openfang-ff11851b83f1) | 2026-03-09 (published; no later date; Medium blocks direct fetch, read through a mirror) | "Agent Native" (Medium publication, no personal name shown) | Medium profile https://agentnativedev.medium.com/ (follow, responses); no email or social link seen in the article | OpenFang (main subject); mentions OpenClaw, ZeroClaw, LangGraph, CrewAI, AutoGen | Poor fit: a single-product OpenFang walkthrough from March, not a roundup; Casama would only fit a future "OpenClaw variants" piece by the same author |
