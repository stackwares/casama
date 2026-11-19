# Import a Grok Bot: plan

Status: **built** (2026-11-19, D-415), on branch `paste-import`. Oliver said "go and build all now", so
§8 went with the recommendations: all four sources (plus Hark and Instinct, added on request), no
share links. One change from this plan: the
model fallback (§2.2) was left out. A paste that doesn't follow the format becomes the bot's
instructions, with a note. `backgroundComplete` needs an existing bot, and the free path is enough to
start. D-415 has what shipped; the text below is the plan as written.

## 0. Summary

Someone moving from Grok Bot pastes their Bot's setup into Casama and gets a Casama bot back: name,
instructions, routines, skills and the apps to connect, shown on a review screen before anything is
created. Today the guide (`docs-site/guide/moving-from-grok-bot.md`) says "there is no import", so
people rebuild each Bot by hand.

Most of the machinery already exists. The OpenClaw and Hermes import (D-122) already turns outside
material into a `casama.bot` template (D-110), shows it on a review screen with a checkbox per item,
and creates the bot through `POST /v1/bots/import`. Grok Bot import is a new **source** for that
pipeline, not a new pipeline.

## 1. What exists today

| Piece | Where | Reused as |
| --- | --- | --- |
| Template format, caps (30 skills, 20 routines, 200 memories, 20k persona) | `packages/contracts/src/bot-template.ts` | The output of the Grok parser |
| Agent import plan + review screen | `packages/domain/src/agent-import.ts` `planAgentImport`, `client/lib/features/bots/agent_import.dart` `AgentImportReviewScreen` | Same review screen, same plan shape |
| "Copy this prompt, paste the answer" | `MEMORY_EXPORT_PROMPT` + `parseMemoryExport` (D-122) | The same trick for a Bot's setup |
| Readable schedules to cron | `cronFromText` ("every 2h", "daily at 7am") | Routine schedules |
| Create the bot | `POST /v1/bots/import` | Unchanged |

## 2. How Grok Bot setups reach us

We don't know Grok Bot's internal format, and xAI publishes no export. Three ways in, in order of how
much we trust them:

1. **Ask the Bot to describe itself (recommended default).** Casama shows a prompt to paste into the
   Grok Bot: "Describe your setup in exactly this format…" with `NAME:`, `DESCRIPTION:`,
   `INSTRUCTIONS:` (fenced block), `SCHEDULE:` lines (`<when> | <what to do>`), `SKILL:` blocks
   (name, description, steps), `APP:` lines and `ASK_FIRST:` lines. The person pastes the answer back.
   A deterministic parser reads it. No model call, so no cost, and it works on self-hosted servers
   with no key. This is exactly how memory import already works.
2. **Paste anything.** If the paste doesn't follow the format (someone copied the Bot's settings page,
   or a share page's text), the server asks a cheap model to fill the same structure, then runs the
   same parser on the result. One `backgroundComplete` call, billed to the person, recorded in
   `usage_ledger`. On a self-hosted server it uses the workspace's default key; with no key, the
   person is asked to use the prompt in (1) instead.
3. **A share link (not in v1, see §8 Q2).** Fetching a public `x.ai` template page and reading it.
   Brittle (their page changes, may need sign-in) and a terms question, so left out unless Oliver
   wants it.

## 3. Mapping

| Grok Bot | Casama | Notes |
| --- | --- | --- |
| Name, description | `name`, `description` | Trimmed to 80 / 300 chars |
| Instructions | `persona_md` | Secrets scrubbed (§5) |
| Schedules | `routines[]` via `cronFromText` | Unreadable ones become a note, not a routine |
| Event triggers (new email, meeting…) | A note naming the closest Casama trigger | Not auto-created in v1; the guide already says there's no one-to-one match |
| Recorded workflows / skills | `skills[]` with `body_md` | Names fixed up as in D-122 |
| Apps it uses | `connections[]` (names only) | Matched against our Composio/MCP catalog so the review shows "Connect Gmail" tiles |
| "Ask first" rules | `autonomy` (`ask_always` / `ask_risky`) + lines appended to the persona | Default stays `ask_risky` |
| Its shared computer, files, sign-ins | Not imported | Said on the review screen |

## 4. App

- **Entry points:** Add → Import a bot gets a third choice, **Paste a bot's setup** (next to file and
  folder). The bot list's empty state and the Grok Bot guide link to it. Deep link
  `casama.ai/open/import/paste` so the website's Grok Bot pages can send people straight there.
- **Sheet:** step 1 "Copy this prompt" (copy button, short how-to: "open your Bot in Grok, paste this,
  copy its reply"); step 2 a large paste field. Then the existing `AgentImportReviewScreen`, with a
  "Came from Grok Bot" source label and the notes list.
- **Native only** (no WebView). New strings in `app_en.arb`. Works on every platform, including web,
  since there's no file picking.

## 5. Server

- `GET /v1/bot-imports/paste/prompt?source=grok_bot` returns the prompt (versioned, so the parser
  knows which format it reads).
- `POST /v1/bot-imports/paste` `{ org_id, text, source }` returns the same plan shape as
  `/v1/agent-imports` (template + notes + item origins). Text capped at 100 KB.
- `@casama/domain` `planPastedBot(text)`: the deterministic parser, pure and unit-tested. The model
  fallback lives in the server and only produces text in the prompt's format, so the domain parser
  stays the single source of truth.
- **Secret scrubbing:** before anything else, strip lines that look like keys or passwords (`sk-…`,
  `xai-…`, `ghp_…`, `Bearer …`, long base64) and list "1 line that looked like a key was removed" as a
  note. The model fallback only ever sees the scrubbed text.
- Rate-limited per person (the model path costs money). No new tables: the plan isn't stored; the
  app sends the ticked template to `POST /v1/bots/import` as it does today.

## 6. Docs, site, costs

- `docs-site/guide/moving-from-grok-bot.md`: replace "There is no import" with the paste flow; keep
  the manual steps as the fallback. `guide/sharing.md` gets the new choice.
- `site/content/compare/*grok-bot*` and the homepage box: "Import your Grok Bot in a minute".
  (Website deploy needs Oliver's yes, as always.)
- `docs/COSTS.md`: the model fallback as a new usage kind (`bot_import_parse`), about one short call.
- A D-415 entry (number checked at build time) and `CHANGELOG.md`.

## 7. Tests and rollout

- Domain: the prompt-format answer end to end; messy answers (bullets, bold, missing sections);
  schedules that `cronFromText` can't read; secret scrubbing; caps.
- API: paste → plan → `/v1/bots/import` → bot with routines and skills; model fallback with a fake
  model; no-key self-hosted path; rate limit.
- Widget: the paste sheet, copy prompt, review with unticking.
- **One real check:** paste the prompt into a real Grok Bot and confirm it answers in the format.
  That needs a Grok account (§8 Q4).
- Size: about 2 days. Phase 1 server + domain, phase 2 app, phase 3 docs/site. Push after each phase;
  deploy and app builds wait for Oliver.

## 8. Questions for Oliver

1. **Generic or Grok-only?** Recommended: build it as "Paste a bot's setup" with four named sources
   in v1: Grok Bot, Meta Muse, ChatGPT Dots and Claude Duet (and Cowork). One parser, one prompt with
   a short per-source intro. Hermes Agent is already imported from its folder (D-122). What each gives
   (from `site/data/rivals.json`, checked 2026-11-18):
   - **Grok Bot:** instructions, schedules, some events, apps. Fullest import.
   - **Meta Muse:** schedules and events, and memory kept as readable files, so its memory can be
     pasted too and become Casama memories.
   - **Claude Duet / Cowork:** instructions, scheduled tasks (the morning brief becomes a routine),
     memory by asking.
   - **ChatGPT Dots:** instructions and what it remembers when asked; it has no schedules to bring
     and single memories can't be viewed, so this import is thinner and the review says so.
   Extra cost over Grok alone: about half a day (prompt variants, source labels, sample answers in
   tests). Each source's real check needs an account there; Muse and Duet are US-only.
2. **Share links:** leave out of v1 (recommended), or try fetching public `x.ai` template pages?
3. **Model fallback on Cloud:** charge it to the person (recommended, it's cents) or absorb it?
4. **A Grok account to test with:** Vaultwarden has none (searched "grok" and "x.ai", 2026-11-19).
   Make one (check `site/content/compare/grok-bot-pricing.md` for which plan has Bots), or let the
   real check wait?
