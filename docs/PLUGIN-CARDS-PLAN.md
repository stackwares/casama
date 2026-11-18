# Cards for a plugin's tools: the plan

Status: **built** (2026-11-17, D-345), all three phases, every decision at its default (Oliver
approved). Item 36 of docs/PLUGINS-AND-PACKS-PLAN.md. What was built, and where it differs from
this text, is in "As built" at the end.

## The problem

A plugin's MCP tools return text or JSON. The bot then either pastes it as text or rebuilds it
with `ui.show` (D-086), which costs tokens and comes out differently every time. Casama's own
tools get native cards (Event, Task list, Details and the rest, D-310, D-322, D-337); a plugin's
tools get none.

## The idea

A plugin may declare, per tool, which card shows its result:

```text
my-plugin/com.casama/cards/<tool>.json
```

```json
{
  "card": "Details",
  "title": "{{result.name}}",
  "rows": [
    { "label": "Status", "value": "{{result.status}}" },
    { "label": "Due", "value": "{{result.due}}" }
  ],
  "when": "result.status"
}
```

- `card` names a component already in Casama's native catalog (basic A2UI plus Casama's own:
  Details, Task list, Event, Schedule, Map, and so on). **No new widgets, no HTML, no WebViews**
  (the app stays fully native). An unknown name is refused by the checker.
- Fields use `{{result.path}}` bindings into the tool's structured result (`structuredContent`,
  else the text parsed as JSON). Lists bind with `"each": "result.items"`.
- `when` is optional: the card shows only when that path has a value; otherwise the result stays
  text.
- Buttons are limited to what the card already offers and send a normal message (as D-086), never
  a direct tool call, so approvals and rules still apply.

## How it would work

1. `checkPack` / `checkPlugin` validate each card file against the catalog's schema (the same one
   `ui.show` checks with), with `{{…}}` allowed in string fields. plugin-check prints which tools
   have cards.
2. At install the card files are stored with the plugin (they are already in `pack_files` and the
   plugin's stored files).
3. After an MCP call, the run fills the template from the result, validates the filled card the
   same way `ui.show` does, and emits a `ui.shown` event. A failed fill falls back to the text
   result silently, logged for the author.
4. The model gets the plain result as before, plus one line: "Shown to the person as a card."
   It then needn't repeat it.
5. The app draws it with the existing renderer. Nothing new on the device, so older apps already
   understand it (unknown components are skipped already).

## Not in it

- Cards with their own layout or styling, or new components from a plugin.
- Live updates to a shown card.
- Cards for tools that aren't from a plugin (built-in apps already have theirs).

## Cost and risk

- No model cost; a template fill per tool call.
- Risk: a template that leaks more than the bot would have said. It only shows the tool's own
  result to the person who ran it, the same data the bot already sees.
- Risk: catalog changes breaking published cards. The catalog's component names and fields become
  a public contract; changing them needs a version in the card file (`"format": 1`).

## Phases

1. Format and checker (domain + plugin-check), docs section in `docs-site/develop/plugins.md`.
2. The run fills and emits cards; server tests with the fake computer's MCP server.
3. One first-party pack uses it (Dev kit: a pull request as a Details card).

## Decisions for Oliver

| # | Question | Default |
|---|---|---|
| 1 | Build it at all | Yes, after packs are live and used |
| 2 | Only existing catalog components | Yes |
| 3 | Buttons send messages, never call tools directly | Yes |
| 4 | Cards for every tool or only when `when` matches | Only when it matches, else text |

## As built

- Format and checker: `packages/domain/src/plugin-cards.ts`; the catalog's checks moved to
  `packages/domain/src/a2ui.ts` so `ui.show`, the checker and the run share them. Card files take
  either `"card"` plus its fields (as above) or `"components": [...]` for a tree of basic
  components. `each` takes an optional `max` (default 20, at most 60) and also gives `{{index}}`.
- A bad card is skipped with a warning rather than refusing the plugin (as a bad server or skill
  is, D-121), so `plugin-check --strict` fails on it while installs keep working.
- Cards are kept in `plugins.summary.cards` at install (not in `pack_files` or the computer).
- The run adds the same Send/Skip a `ui.show` card gets, and doesn't end the turn after a card.
- Phase 3: the Dev kit had no tool server, so it gained one (`server/github.mjs`, public
  repositories, no key) with `get_pull_request` (Details) and `list_pull_requests` (Results).
- No app change was needed.
