# Message reactions: the plan

Status: **done** (live everywhere 2026-11-17, D-331).

Original status: **built, not deployed** (2026-11-17), as D-331, with every default answer in §9. On branch
`t3/reactions`. What changed from this plan while building is in §10; what's left for Oliver is in
§11.

## 0. Summary

People react to any message in a chat with an emoji, the way Facebook and Messenger do: hold a
message (or hover it with a mouse), tap one of six quick reactions or pick any emoji, and a small
chip shows under the bubble. Tap your chip again to take it back. Everyone who can see the chat sees
the reactions live, on every device.

What makes it more than decoration in Casama: **the bot sees them**. A 👍 or ❤️ on a reply tells the
bot that worked; a 👎 or 😡 tells it something went wrong, the same way a correction does today
(`run_digests.corrected`, skill learning). And bots can react too, so "👍" can be the whole answer to
"thanks" instead of another paragraph.

| Phase | What ships |
|---|---|
| 1 | React and unreact in the app (all platforms), chips with counts, who reacted, live updates, the API |
| 2 | Bots see reactions and learn from them; bots can react; the Chrome extension |
| 3 | Chat apps: reactions in Telegram, Slack, WhatsApp, Discord come into Casama and go back out |

## 1. What exists today

Nothing of reactions exists. What they stand on:

| Already built | Where | Use |
|---|---|---|
| Messages, one row per turn | `public.messages` (`supabase/migrations/20261110000001_bots_chat_runs.sql`), `bot_id` from D-118 | Reactions hang off `messages.id` |
| Who may see a chat | `can_access_conversation()` (`20261210000001_group_chats.sql`) | Same check for seeing and adding reactions |
| Thread for the app | `GET /v1/conversations/{id}/thread` (`packages/contracts/src/routes/bots.ts:479`) | Gains a `reactions` summary per message |
| Per-message routes | `DELETE …/messages/{message_id}`, `POST …/edit` (same file, 401–440) | The new reaction route sits beside them |
| Live chat updates | `conversation:<id>` private topic, `conversation_activity` broadcast (D-224, `20270124000001_live_conversations.sql`); `watchConversation` in `client/lib/core/supabase_backend.dart:2598` | A reaction sends `{kind: 'reaction', message_id}` on the same topic |
| Message menu | `client/lib/features/chat/widgets/message_actions.dart`: long-press sheet on touch, hover row on mouse (D-256); copy, read aloud, edit, regenerate, delete, report | The quick-reaction strip goes on top of the sheet and a smile button into the hover row |
| Learning from corrections | `run_digests.corrected`, `packages/agent/src/skill-learning.ts` | A negative reaction counts like a correction (Phase 2) |
| Chat-app acknowledgement | `ChannelAdapter.acknowledge` (D-277, `packages/agent/src/channels/adapters.ts:71`), Slack `reactions.add` | Outbound bot reactions reuse it (Phase 3) |
| Extension chat | `apps/extension/src/panel/chat.ts` (`msg-actions`) | Same chips and picker (Phase 2) |

## 2. Feature set

### 2.1 Reacting (Phase 1)

- **Quick reactions:** 👍 ❤️ 😂 😮 😢 👎, then a **+** that opens the full emoji picker (search,
  recent, skin tones). Facebook uses 😡 as the sixth; 👎 is more useful to a bot (decision 2).
- **One reaction per person per message**, like Facebook. Picking another replaces it; picking the
  same one removes it (decision 1).
- **Any message:** bot replies and people's messages, direct chats, group chats, topics. Not on
  info lines, cards, tool steps or Allow cards.
- **Touch:** hold the bubble (it already shrinks as the hold builds); the sheet opens with the
  reaction strip on top and the current actions below. Light haptic on pick. **Double-tap a bubble**
  adds ❤️ (decision 3).
- **Mouse:** a smile button joins the hover row under the message; it opens a small popover with the
  strip and +. Right-click menu gets "React…".
- **Chips:** under the bubble's bottom corner (bot side left, your side right), overlapping it a
  little: the emojis in order of count, then the total when more than one. Your own reaction is
  outlined in the accent colour. Tap your chip to remove; tap someone else's emoji to add the same.
- **Who reacted:** long-press (touch) or hover (mouse) a chip shows a sheet/tooltip: tabs per emoji,
  a face and name per person, the bot's face for a bot.
- **Live:** every open copy of the chat updates within a second; no full thread reload.
- **Accessibility:** chips read as "2 reactions: heart from you and Mara; thumbs up from Writer".
  Reduce Motion turns off the pop animation.

### 2.2 Bots and reactions (Phase 2)

- **Bots see them.** In the history a bot reads, a message with reactions gets a short note after it:
  `[Reactions: ❤️ Oliver]`. Only the most recent 50 turns carry notes, so old ones cost nothing.
- **A reaction doesn't start a run.** It isn't a message (decision 4). The bot sees it next turn.
- **Learning:** 👎 😡 😢 on a reply mark its run digest `reaction = 'negative'`; 👍 ❤️ 😂 mark it
  `positive`. Negative reactions feed skill learning the way a correction does; positive ones keep a
  skill from being "improved" away. Changing your mind updates the digest.
- **Bots can react:** a `chat.react` tool (`{message_id?, emoji}`, default the person's last message).
  The prompt tells bots to use it instead of a reply only for acknowledgements ("thanks", "ok") and,
  in group chats, to agree without posting. One reaction per bot per message, like people.
- **Extension:** side panel chat shows chips and offers the strip under the hover actions.

### 2.3 Chat apps (Phase 3)

| App | In (person reacts in the app → Casama) | Out (bot reacts → app) |
|---|---|---|
| Telegram | `message_reaction` update (add to `allowed_updates`; in groups the bot must be an admin) | `setMessageReaction` |
| Slack | `reaction_added` / `reaction_removed` events (`reactions:read` scope) | `reactions.add` (scope already asked) |
| WhatsApp Cloud | inbound `reaction` message type | `type: reaction` message |
| Discord | `MESSAGE_REACTION_ADD/REMOVE` (gateway intent) | `PUT …/reactions/{emoji}/@me` |
| Messenger, Teams, Feishu, iMessage, email, SMS, Linear, Jira | Not in this plan | Not in this plan |

Mapping needs the channel's message id kept on our message (most adapters already store it for
replies; checked per adapter during Phase 3). Reactions from apps arrive as the person linked to that
channel identity; an unknown sender's reaction is dropped.

## 3. Not shipping

- Several reactions per person per message (Slack-style), unless decision 1 says otherwise.
- Custom/uploaded emoji, animated reactions, stickers.
- Push notifications for reactions. The other side is almost always a bot; in a group chat with other
  people a reaction still doesn't push (decision 5).
- Reactions in search results, chat export and shared chat links (Phase 1 export shows them as a line
  of text; links later).
- Reactions as an analytics "rating" dashboard. Counts go to PostHog only as events (§5.6).

## 4. Platform notes

No store rule limits reactions. Apple's Guideline 1.2 asks for reporting on user content; reactions
carry no text, and the existing Report action covers the message itself. Emoji render with the
system font on each platform, so the same emoji can look different on Android and iOS; that is
expected. The Flutter picker needs a font with full emoji coverage on web. Not checked yet whether
the web build already falls back to Noto Color Emoji; if it doesn't, the picker loads it only when
opened (about 10 MB), so it never adds to first load.

## 5. How it works

### 5.1 Data

```sql
create table public.message_reactions (
  message_id uuid not null references public.messages (id) on delete cascade,
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid references auth.users (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete cascade,
  emoji text not null check (char_length(emoji) between 1 and 16),
  source text not null default 'app' check (source in ('app', 'api', 'channel', 'bot')),
  created_at timestamptz not null default now(),
  check ((user_id is null) <> (bot_id is null))
);
create unique index message_reactions_user_uq on public.message_reactions (message_id, user_id) where user_id is not null;
create unique index message_reactions_bot_uq on public.message_reactions (message_id, bot_id) where bot_id is not null;
create index message_reactions_conversation_idx on public.message_reactions (conversation_id, message_id);
```

- RLS: select with `can_access_conversation(conversation_id)`; insert/update/delete only your own row
  (`user_id = auth.uid()`) and only where you can access the conversation. Bot rows only through the
  worker. `allow_worker('public.message_reactions')`. pgTAP tests for each policy.
- Not encrypted (D-136 covers message content; an emoji and who sent it is metadata like
  `created_at`). Decision 6.
- `run_digests` gains `reaction text check (reaction in ('positive','negative'))` in Phase 2.
- Deleting a message deletes its reactions. Edit and regenerate make a new message, so the old
  version keeps its reactions and the new one starts clean.

### 5.2 API

- `PUT /v1/conversations/{id}/messages/{message_id}/reaction` `{emoji}` → `200 {reactions}`. Sets or
  replaces yours. `DELETE` the same path removes it. 404 when you can't see the message, 422 for a
  string that isn't one emoji (server checks a single grapheme with `\p{Extended_Pictographic}` or a
  keycap/flag sequence).
- `GET …/thread` adds per message `reactions: [{emoji, count, mine, bots: [bot_id], users: [user_id]}]`
  (users capped at 20 per emoji; the who-reacted sheet asks
  `GET …/messages/{message_id}/reactions` for the full list with names).
- Rate limit: 60 reaction changes a minute per person (the abuse limiter from D-298).
- Contracts, the TS client (`@casama/client`), OpenAPI and `/mcp/docs` pick it up; the MCP server gets
  `react_to_message`.

### 5.3 Live updates

A trigger on `message_reactions` sends
`realtime.send({kind:'reaction', message_id}, 'conversation_activity', 'conversation:<id>', true)`.
`watchConversation` today emits a run id or null; it becomes a small sealed event (`RunActivity`,
`ReactionActivity`) and the chat controller re-fetches only that message's reactions
(`GET …/messages/{message_id}/reactions`). The app applies its own change optimistically and rolls
back on error.

### 5.4 App (Flutter)

- `message_actions.dart`: reaction strip at the top of the sheet; smile button in the hover row;
  "React…" in the right-click menu. New `widgets/reactions.dart` for chips, the strip, the who-reacted
  sheet. The full picker uses `emoji_picker_flutter` (MIT, pure Dart, works on all six targets) inside
  the adaptive modal (decision 7).
- `ChatEntry` message types gain `reactions`; `ChatController.react(messageId, emoji?)`.
- Strings in `app_en.arb`. Widget tests: strip picks, replace, remove, chip semantics, double-tap.

### 5.5 Agent (Phase 2)

- History builder adds the reaction note for user and assistant messages (`packages/agent`).
- `chat.react` tool in the chat tool set; the worker inserts with `bot_id` and `source = 'bot'`.
- Run digest and skill learning read `reaction` alongside `corrected`.

### 5.6 Analytics

`message_reacted` (`emoji`, `on: bot|person`, `surface: sheet|hover|double_tap|chip|picker`,
`conversation_kind`) and `message_reaction_removed`. No message content, ids hashed as elsewhere.

## 6. Phases

| Phase | Work | Done when |
|---|---|---|
| 1 | Migration + pgTAP; API + contracts + client; realtime trigger; Flutter chips, strip, picker, who-reacted, double-tap; docs-site chat page; CHANGELOG | Two devices on the local stack react to the same reply and see each other's chip in under a second; `pnpm test`, pgTAP, `flutter test` pass |
| 2 | History notes; `run_digests.reaction` + skill learning; `chat.react` tool and prompt; extension chips | A 👎 on a reply makes the next run's history carry it and marks the digest; a bot answers "thanks" with 👍 only; extension shows and adds reactions |
| 3 | Telegram, Slack, WhatsApp, Discord in and out | A reaction in each app shows in the Casama chat and a bot reaction shows in the app (checked live on each) |

App builds and production deploys follow the usual asks; nothing in this plan needs a store upload.

## 7. Risks

- **Bots overreacting:** a bot that reacts to everything is noise. The prompt limits it to
  acknowledgements; an eval checks a "thanks" turn gets a reaction and a real question doesn't.
- **History cost:** notes on every message would add tokens. Capped to the last 50 turns and a few
  bytes each.
- **Emoji validation:** grapheme rules change with Unicode versions; the server check allows any
  single extended grapheme up to 16 code points, so new emoji work without a server update.
- **Realtime fan-out:** a reaction is one small broadcast, the same size as today's run events.
- **Telegram groups:** reactions arrive only when the bot is an admin; the channel setup text says so.

## 8. Docs to update

`docs/DECISIONS.md` (D-331), `docs-site` chat guide and API reference, `CHANGELOG.md`,
`agent-kit/skills` (API skill: the new route and tool).

## 9. Decisions for Oliver

| # | Question | Default |
|---|---|---|
| 1 | One reaction per person per message (Facebook) or several (Slack)? | One |
| 2 | Quick six: 👍 ❤️ 😂 😮 😢 👎, or Facebook's exact six with 😡 instead of 👎? | With 👎 (a clearer signal for the bot) |
| 3 | Double-tap a bubble to ❤️? | Yes (touch only) |
| 4 | Can a reaction wake the bot (e.g. 👎 makes it try again)? | No; it sees it next turn. Regenerate already exists |
| 5 | Push for reactions from other people in shared group chats? | No |
| 6 | Store reactions unencrypted (metadata)? | Yes |
| 7 | Add `emoji_picker_flutter` for the full picker, or only a fixed grid of ~60 emoji? | Add the package |
| 8 | Bots react (Phase 2 `chat.react`)? | Yes, acknowledgements only |
| 9 | Phase 3 (chat apps) in this track, or later? | In this track, after 1 and 2 |

## 10. As built: changes from the plan

- **Discord dropped from Phase 3.** Casama's Discord adapter hears only its slash command (no
  gateway connection), so reaction events never reach it. Telegram, Slack and WhatsApp are in.
- **Chat-app senders are stored as themselves**, not as a linked person: `external_sender`
  (`<channel id>:<sender>`) and `external_name`, `source = 'channel'`, one reaction per sender per
  message. Senders not on the channel's allowed list are ignored.
- **Message refs:** a new `channel_message_links (channel_id, ref, message_id)` table maps each
  app's message id to ours, for messages received and sent from now on. Older messages aren't
  matched. Adapters' `send` now returns the app's ref.
- **Telegram:** `allowed_updates` gains `message_reaction`; new channels set
  `config.reaction_updates`, older ones get their webhook reset on their next message. Telegram's
  fixed reaction set: the nearest allowed emoji (😂 → 🤣, 😮 → 😱) or nothing.
- **Broadcast event name:** `message_reaction` (not `conversation_activity`) on the same
  `conversation:<id>` topic, with `{kind: 'reaction', message_id}`. `watchConversation` returns a
  `ConversationActivity` (run or reaction).
- **Errors:** 400 `invalid_emoji` (not 422), 400 `not_reactable` for tool and system rows, 404
  `message_not_found`, 429 `rate_limited`.
- **Chips:** one chip per emoji with its count (shown when more than one, or when yours), under the
  bubble rather than overlapping it. Each chip reads "👍, 2 reactions, including yours". Who
  reacted opens on long-press or right-click (no hover tooltip), with a tab for all and one per
  emoji; your row there takes yours back.
- **Analytics surfaces:** `menu` (touch menu and right-click), `hover`, `double_tap`, `chip`,
  `picker`; `feature_used` gains `reactions`.
- **`chat.react`** defaults to the message the run is answering; `remove: true` takes the bot's
  back. When the chat came from a chat app, the reaction is mirrored there.
- **Extension:** chips and the quick six only (no full picker, no who-reacted), through the API;
  a failed change is put back with a toast.
- **Web emoji:** the app sets no font-fallback override and no CSP, so Flutter web's default
  fallback loads Noto Color Emoji from Google Fonts only when emoji appear. Not checked live.

## 11. Left for Oliver

1. **Local database:** after the merge, apply `20270202000001_message_reactions.sql` from the main
   tree with `supabase migration up --include-all` (never a reset). From this branch the CLI
   refuses, because the local database already has newer migrations (20270201190001–190201) that
   the branch doesn't.
2. **Review and merge** branch `t3/reactions` into `main`.
3. **Production deploy** (needs your yes): `scripts/deploy-prod.sh --dry-run`, then `--yes`.
   Runs the migration.
4. **Casama's Slack app:** add the `reactions:read` scope and the `reaction_added` and
   `reaction_removed` bot events in the Slack app settings; workspaces already installed need to
   reinstall to grant the scope.
5. **App builds** (needs your yes for each): the new `emoji_picker_flutter` plugin means native
   builds for iOS, Android and macOS, and a web build for app.casama.ai.
6. **Live checks:** two devices reacting to the same reply on the local stack (under a second);
   double-tap and haptics on a real phone; the picker on web; a reaction in Telegram (bot as group
   admin), Slack and WhatsApp showing in Casama and a bot reaction showing back there.
7. **Docs site and the Chrome extension** go out with their usual deploy and release.
