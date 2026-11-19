# Casama Help links to the place in the app: plan

Status: **built** (2026-11-19, D-431) with the defaults in §9. Differences from the text below are in D-431.

Asked 2026-11-19 (Oliver, with a screenshot of a Casama Help answer): "our chat support agent inside
the app is good but I think it should use clickable links to let the user click where they should go
so it's easier for the user. using routing?"

When it lands, record it as a decision in `docs/DECISIONS.md` (check the highest number first; it was
D-430 on 2026-11-19).

---

## 0. Summary

Casama Help (D-298) tells people where to go in words: "Open **Settings → Billing** and check **Your
plan**", "tap **Restore Purchases** on the Billing page". The person then has to leave the help
chat, find Settings, find Billing, and come back. The app already has a route for every one of those
screens, so the answer can carry the route as a link they tap.

The plan:

1. **A fixed list of places** (`places.json`): every screen Help may send someone to, with the label
   the app shows, its route, and when it applies (Cloud only, which platforms, which roles).
2. **The model links places by id**, never by route: `[Billing](place:billing)`. The server checks
   every id against the list (and bot ids against what its tools returned), turns good ones into
   `casama://app/<route>` links and drops bad ones to plain text. A made-up place never reaches the
   person, the same way made-up doc links don't today (`citedSources`).
3. **The app opens them in place:** tapping a link in a Help answer pushes that screen over the help
   chat. Back returns to the conversation, which is kept (`helpChatProvider`). The answer also gets
   up to two **Go to** buttons, next to the docs buttons it has now.
4. **The website assistant** (D-401) links the same places as `casama.ai/open/<route>` (D-326), which
   opens the app or the web app.

What the screenshot's answer becomes:

> A couple of quick things to try:
> 1. Open [Settings → Billing](place:billing) and check **Your plan** — it shows how you're billed
>    and whether anything is pending.
> 2. If you bought on iPhone or Android, tap [Restore Purchases](place:billing-restore), and check
>    the store's receipt ([Apple subscriptions](place:apple-subscriptions) on iPhone).
> 3. If you paid on the web, check whether your card or bank declined it.
>
> `[→ Billing]` `[📖 Purchases and plans]`

On an iPhone, "Apple subscriptions" opens the App Store's subscriptions page; on Android the Play
Store's link shows instead and Apple's isn't offered. Restore Purchases opens Billing with the
button highlighted; it never runs the restore by itself.

## 1. What exists today

- **Server:** `apps/server/src/api/routes/support.ts` (`POST /v1/support/chat`). The system prompt
  says "Name settings the way the app shows them" (`SHARED_RULES.brief`) but gives no list of
  names, so the model guesses from the docs. Answers end with a "Sources:" line that `citedSources`
  checks against what `search_docs` returned and returns as `sources[]`.
- **Website assistant:** `support-web.ts` shares `SHARED_RULES` and `citedSources` (D-401).
- **App:** `client/lib/features/settings/support_screen.dart`. `_HelpBubble` draws the answer with
  `ChatMarkdown` and the sources as `ActionChip`s that open the docs in the browser. The
  conversation lives in `helpChatProvider` (not auto-disposed), so it survives leaving the screen.
- **Links in `ChatMarkdown`** (`features/chat/widgets/chat_markdown.dart`, `LinkConfig.onTap`): http
  and https go to `openWebLink`, file paths open the bot's file. Anything else does nothing.
- **Routes:** `client/lib/core/router.dart` (GoRouter) has a route for every screen Help talks
  about: `/settings/billing`, `/settings/usage`, `/settings/support`, `/settings/integrations`,
  `/settings/privacy`, `/settings/people`, `/bots/:botId/settings`, and so on. Some take a query
  already (`?tab=`, `?do=`, `?provider=`).
- **App links (D-326):** `casama://app/<route>` and `https://casama.ai/open/<route>` are already
  understood (`core/open_links.dart`), so the link format exists.

## 2. The place list

One file, `packages/contracts/support/places.json`, read by the server and by a Flutter test.
About 35 places to start: the Settings pages, a bot's pages, Inbox, Library, Usage, the Gallery,
the two store subscription pages and Apple's refund page.

```json
{
  "id": "billing-restore",
  "label": "Restore Purchases",
  "route": "/settings/billing?highlight=restore",
  "cloudOnly": true,
  "platforms": ["ios", "android", "macos"],
  "minBuild": 47
}
{
  "id": "bot-settings",
  "label": "{bot}'s settings",
  "route": "/bots/{bot}/settings",
  "params": ["bot"]
}
{
  "id": "apple-subscriptions",
  "label": "Apple subscriptions",
  "url": "https://apps.apple.com/account/subscriptions",
  "platforms": ["ios", "macos"]
}
```

Fields: `route` (in-app) or `url` (an outside page, opened with `openWebLink`); `params` filled
from tool results only; `cloudOnly`; `platforms`; `roles` (owner/admin pages such as People and
Workspace); `minBuild` for places added after a build is out.

**Checks:**
- A Flutter test walks the list and matches every `route` against the real `GoRouter` with
  placeholder ids, so a renamed screen fails the build instead of giving a dead link.
- A server test checks ids are unique, labels match the app's English strings, and every `url` is
  on an allowlisted host.

## 3. Server

- **The prompt gets the places that apply to this person**: filtered by platform and app build
  (from `client`, which the app already sends), Cloud vs self-hosted, and role. One line each,
  `billing: Settings → Billing`, about 400–600 input tokens. New rule in `SHARED_RULES`:
  "When you tell the person to go somewhere in the app, link it: `[Billing](place:billing)`. Only ids
  from the list. For a bot's page, use the bot id from get_bot or get_account:
  `[Ava's settings](place:bot-settings?bot=<id>)`. Never write app routes or casama:// links
  yourself."
- **`linkPlaces(reply, ctx)`** (next to `citedSources`): finds `](place:…)` links, keeps those whose
  id is in the filtered list and whose params appeared in a tool result this turn, rewrites them to
  `casama://app/<route>` (or the place's `url`), and turns the rest into their plain text. Returns
  `places[]` (id, label, link) for the Go to buttons: the first two distinct places, in order.
- **Old app builds:** the app sends `features: ["places"]` with the chat request. Without it the
  server leaves places out of the prompt and strips any that slip through, so builds already in
  stores keep getting today's plain answers.
- **Cost:** no new vendor; a few hundred more input tokens per Help message on the same model, well
  inside `SUPPORT_DAILY_USD` and the per-person cap. `docs/COSTS.md` gets a one-line note on the
  Help line (no price change).

## 4. App

- **`ChatMarkdown` link taps** handle `casama://app/<route>` (and `https://casama.ai/open/<route>`)
  through the existing `macLinkLocation`/`openLinkTarget` parsing, then `context.push(route)`. This
  helps any chat, not only Help, but only Help answers will contain them for now (bots never get
  the place list).
- **Help answers** get **Go to** chips (`LucideIcons.arrowRight`, the place's label) before the
  docs chips, at most two. Same chip style as today.
- **Back comes back:** the screen is pushed over the help chat, so Back (or the close button on
  wide layouts) returns to the conversation, scrolled where it was. On the desktop layout, where
  Settings shows in a pane, it opens in that pane and Back works the same.
- **Highlights instead of actions:** a few places point at one control: Restore Purchases, Manage
  subscription, Delete account, Analytics switch. Their screen reads `?highlight=<name>`, scrolls to
  that control and pulses it once (respecting reduced motion). Nothing runs on its own; the person
  still taps it. Start with Billing (restore, manage) and Privacy; add more as Help needs them.
- **Signed-out / wrong workspace:** places need a signed-in app, which Help already requires. A bot
  page link for a bot in another workspace switches nothing: the server only fills bot ids from this
  workspace's tool results.
- **Analytics:** `help_place_opened {place, from: "link" | "chip"}` in the catalog
  (`packages/contracts/analytics/catalog.json`), so we can see which places people use and whether
  answers with links lead to fewer hand-offs.

## 5. Website assistant (D-401)

Visitors on casama.ai often aren't in the app. It gets the same rule but only the places with no
params and no role (Billing, Privacy, Help & support, Gallery…), rendered as
`https://casama.ai/open/<route>` links. Those open the installed app or the web app (D-326; on
iPhone they go to the web app until `/open/*` is in the AASA). Its Go to chips say "Open in Casama".

## 6. Not in this plan

- **Bots linking places in normal chats** ("open Ava's settings"). Same machinery would work: give
  bots the place list as a tool or prompt section. Left for later because it costs every bot run
  tokens; see §9 question 4.
- **Help doing things for the person** (restore, change plan, turn a switch). Help stays read-only
  (D-298); it shows the way, the person taps.
- Languages other than English (v1 is English only; labels come from the app's English strings).

## 7. Phases

### Phase 1: links and chips (about 1 day)
- `places.json` with the first ~35 places, server filter + prompt rule + `linkPlaces`, `features`
  flag, tests (`support.test.ts`: good id kept, unknown id dropped, bot id not from a tool dropped,
  platform filter, old client gets no places).
- `ChatMarkdown` handles `casama://app/…`; Go to chips in `_HelpBubble`; Flutter tests: tap pushes
  the route, Back returns with the conversation, route-list test against `GoRouter`.
- **Done when:** asking "my purchase didn't show up" on the local stack gives an answer whose
  Billing link and chip open Billing, and Back lands in the same help conversation.

### Phase 2: highlights and store pages (about half a day)
- `?highlight=` on Billing and Privacy; Apple and Play subscription places; refund page places.
- **Done when:** Restore Purchases opens Billing with the button pulsing, on iOS simulator and an
  Android emulator.

### Phase 3: website assistant (a couple of hours)
- Public places as `casama.ai/open/…` links in `support-web.ts`.

Then: docs-site (Help & support page: "answers link straight to the screen"), `CHANGELOG.md`,
decision entry. Server deploy and app build need Oliver's yes as usual; the server part is safe to
deploy before the app build because of the `features` flag.

## 8. Risks

- **Model ignores the rule or links too much.** Mitigated by the prompt ("link a place once, the
  first time you name it") and by `linkPlaces` dropping anything bad. A link-free answer is still a
  good answer.
- **Route drift:** the GoRouter test catches renamed routes before a build ships.
- **A place that doesn't apply** (Restore Purchases on the web app): filtered out by `platforms`
  before the model sees it.

## 9. Decisions for Oliver

| # | Question | Recommended default |
|---|---|---|
| 1 | Links inline in the text, Go to buttons under the answer, or both? | **Both**: inline where the step names the place, plus up to two buttons |
| 2 | Tapping a link: push the screen over Help (Back returns), or close Help and go there? | **Push**, so the conversation is one Back away |
| 3 | Highlight the exact control (Restore Purchases) when Help points at one? | **Yes**, for Billing and Privacy first; never press it for them |
| 4 | Should every bot be able to link app screens in normal chats too? | **Not now**; Help only, revisit after we see `help_place_opened` numbers |
| 5 | Website assistant links too (`casama.ai/open/…`)? | **Yes**, public places only |
