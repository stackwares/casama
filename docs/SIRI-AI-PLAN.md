# Siri AI: ask a bot, run a routine and find chats through Siri and Apple Intelligence

Status: **not started** (written 2026-11-20). Waiting on Oliver's answers in §13. No code yet.
Apple's rules below were read on 2026-11-19 and 2026-11-20 from Apple's own pages (sources at the
end) and compared with what is installed on this Mac (Xcode 27.2, iOS 27.2 SDK, macOS 27.2 SDK).
The decision gets its number when this is approved (the highest was D-432 on 2026-11-20).

## 0. Summary

Apple's new Siri ("Siri AI") doesn't plug an outside assistant in. Its model reads the **App
Intents** an app declares (actions), the **app entities** (things: a bot, a chat) and the
**schemas** they follow, then calls them as tools. An app that declares good ones can be asked for
things in plain words, by voice or typing, from anywhere on the phone or the Mac.

Casama has the start of this (D-111): "Ask a bot" and "Run a routine" for Siri, Spotlight and
Shortcuts. Both only open the app. This plan makes them answer inside Siri, makes bots, routines
and chats findable, and gets Casama ready for the part of Siri AI that isn't in the store yet.

| Phase | What people get | Works on | Can ship | Build time |
|---|---|---|---|---|
| 0. Proof on a device | Nothing yet: we measure the one path everything rests on | | | Half a day |
| 1. Answers inside Siri | "Ask Casama" is answered by voice, with no app opening. "What needs me". Run a routine in place | iOS 16+, macOS 13+, any Siri | Next app build | 2–3 days |
| 2. Findable and on screen | Bots, routines and chats in Spotlight; Siri AI can find them by description and knows which one is open | iOS 18+, macOS 15+ | Next app build | 1–1.5 days |
| 3. Schemas | "Tell my Research bot to…" in free wording; "search Casama for…" | iOS 27.0+, macOS 27.0+ | Any app build | 3–4 days |
| 4. Custom tools, skills, cards | Siri AI calls and chains Casama's own actions and shows our cards | 27.3 (beta today) | App Store "in the spring" (Apple) | 2–3 days, on a branch |

Build times are estimates in agent working days with tests. Real-device checks come on top and
need Oliver's phone (§16).

**Recommended:** Phases 0 to 2 with the next app build, Phase 4 as a short branch experiment so we
are ready when Apple opens submissions, and Phase 3 decided after Phase 2 is on a phone (§13,
decisions 2 and 7).

**The two biggest unknowns**, both answered by Phase 0 before anything is built on them:

1. Whether Dart comes up in time when Siri starts the app in the background. D-324 and D-405
   already rely on this for Stop, Allow and Run now, and it has never been checked on a real
   iPhone.
2. How long Siri waits for an intent before it gives up. Apple's pages don't say.

## 1. What exists today

| Where | What | Answers in place? |
|---|---|---|
| iPhone and Mac apps (`AppDelegate.swift` in each Runner, D-111) | `AskBotIntent` (bot, question), `RunRoutineIntent` (routine), `BotEntity`, `RoutineEntity`, `CasamaShortcuts` ("Ask Casama", "Run a routine in Casama") | No. Both set `openAppWhenRun` and hand a path to Flutter over `casama/shortcuts` |
| Apple Watch (`CasamaWatch/Siri.swift`, D-410) | `AskCasamaIntent` (opens the watch app listening), `RunRoutineNowIntent`, `WhatNeedsMeIntent` | "What needs me" and Run do, with the watch's own key. Ask opens the app |
| Live Activity and widgets (`RunActionIntents.swift`, D-324, D-405) | `StopRunIntent`, `AnswerRequestIntent`, Run now, Do it | Yes. iOS runs them in the app's process and they hand the action to Dart over `casama/island` → `action` |
| Controls (`ControlIntents.swift`, D-405) | `OpenCasamaIntent`, Talk to a bot, Run a routine | Run does; the others open a place |

What the intents know about the workspace:

- `flutter.casama.shortcuts` in the app's own preferences: bots and routines, ids and names only
  (`client/lib/core/shortcuts.dart` writes it).
- The glance in the App Group (D-405 §17): bots with their marks, routines, what needs the person,
  already made private when it must be.

What Dart can already do without the window (`client/lib/features/island/island_bridge.dart`):
`stop`, `allow`, `deny`, `run_routine`, `accept`, and `_ask` (a new chat with a bot, sent at
once), which the Mac's notch uses.

Nothing is in Spotlight, nothing tells the system what is on screen, and no intent follows one of
Apple's schemas.

## 2. What Apple offers, and when each part can ship

| Piece | What it does | Needs | In the SDK here | App Store today |
|---|---|---|---|---|
| App Intents that return a dialog or a small view | Siri speaks and shows the answer without opening the app | iOS 16, macOS 13 | Yes | Yes |
| `IndexedEntity` and `CSSearchableIndex.indexAppEntities` | Entities in Spotlight; Siri AI finds content through Spotlight's meaning search | iOS 18, macOS 15 | Yes | Yes |
| On-screen context (`appEntityIdentifier` on views, or one entity on an `NSUserActivity`) | "This chat", "this bot" | iOS 18.2, macOS 15.2 | Yes | Yes |
| Donations (`IntentDonationManager`) | Siri suggests what a person does often | iOS 16 | Yes | Yes |
| Schemas: `@AppIntent(schema:)`, `@AppEntity(schema:)`, `@AppEnum(schema:)` with `.messages.sendMessage`, `.messages.draftMessage`, `.messages.conversation`, `.messages.message`, `.messages.messagePerson`, `.system.searchInApp`, `.system.open` | Siri knows what the action means, so free wording works | iOS 27.0, macOS 27.0 (the macro itself is from iOS 18) | Apple lists them as 27.0. Not compiled here yet: Phase 3's first step | Yes |
| Tools: `@AppIntent(.tool)`, `ToolIntent`, `CardSnippet`, `@AppEntity(.generable)`, app skills (`Skills.skillsbundle`), the Siri Evaluations framework | Siri AI calls any custom action, chains several, shows our cards | 27.3, in beta since 2026-11-03 | **No.** Needs Xcode 27.3 beta | **No.** Xcode builds and internal TestFlight testers only |

Rules from Apple's pages that shape the plan:

- **The preview isn't for customers.** Tool features don't work for external TestFlight testers or
  App Store installs. Apple says customers get them "in a few months" and that App Store
  submission opens "in the spring". Apple also says it "will follow up with more details about the
  terms and usage policies". Nothing is published on fees.
- **When Siri AI may call an app's tool:** the person names the app, or the app is in front, or one
  of its entities came up in a search result. In the background, requests need to mention the app.
- **A tool turns off the app's phrases in Siri.** Adding any tool intent makes the app's App
  Shortcuts unavailable to Siri. They keep working in Spotlight and on the Action button. So the
  tools must cover everything the phrases do.
- **An intent that follows a schema from a primary domain doesn't get `.tool`.** It is already
  available to Siri.
- **Use-case groups come whole.** `draftMessage` and `sendMessage` are one group; Xcode warns when
  only one is there.
- **Only use a schema that truly fits.** "Only apply schemas for actions and content that genuinely
  match the domain's intended purpose."
- **Skills guide, they don't command.** One skills bundle per app target, one `SKILL.md` per folder.
  Siri reads the body only after the name and description matched the request.
- **Cards are still pictures.** The system renders a card ahead of time and stores it. Text and
  images only; nothing that changes later.
- **Devices and languages:** an Apple Intelligence device set to a supported language. English is
  one. The app's v1 is English only, so this fits.
- **Not for us:** `.assistant.activate` (the iPhone side button) works only in Japan and needs its
  own entitlement.

## 3. Goals and what this is not

**Goals**

1. Ask a bot from Siri and hear the answer, without the app opening.
2. Let Siri AI find a bot, a routine or a chat when someone describes it loosely.
3. Be in the store on the first day Apple accepts Siri AI tools, with tools we have already tried.
4. Add no new credential, no new server surface and no new vendor.

**Not this**

- Not a replacement for calls (D-327) or the chat. Siri is one more way in.
- Not a way to approve things by voice (§9).
- Not Android. Gemini's way into apps is a different system and would be its own plan.
- Not a new Apple Watch feature. The watch's Siri intents stay as they are.

## 4. Principles

1. **Acting goes through the app** (D-405 §8.4). Siri hands the action to Dart, which acts as the
   signed-in person with every check the app already makes. No key that can act lives in native
   code.
2. **Never leave the person with nothing.** If the app can't act in place, it opens where they can
   finish, with their words kept.
3. **Say less when unsure.** Private workspace, Hide reply text, or the app lock: Siri says that a
   bot replied, never what it said.
4. **Names in the index, never words from a chat.** Spotlight gets bot names, routine names and
   chat titles. Message text stays in the app.
5. **Old Siri first.** Phase 1 works for everyone on iOS 16 or later, not only on Apple
   Intelligence phones.
6. **Main always builds with the store's Xcode.** Preview code stays on its branch until the SDK is
   final.
7. **Write for the model as for a stranger.** Every title and description says what the thing is to
   someone who has never seen Casama.

## 5. What people can say

| Phase | Said | What happens |
|---|---|---|
| 1 | "Ask Casama" | Siri asks which bot (or takes the usual one, §13 decision 6) and what to ask, sends it, waits, then speaks and shows the reply |
| 1 | "What needs me in Casama" | "Two things need you. Research wants to send an email." |
| 1 | "Run a routine in Casama" → Morning brief | "Started Morning brief." The result arrives as it does today |
| 2 | Typing "research" in Spotlight | The Research bot and recent chats with it; a tap opens them |
| 2 | With a bot's chat open, on Siri AI: "ask this bot to…" | Siri AI knows which bot and chat "this" means, so the name isn't needed |
| 3 | "Tell my Research bot in Casama to pull last week's numbers" | Sent. The reply arrives as a notification |
| 3 | "Search Casama for the pricing deck" | The app opens on its search results |
| 4 | "Ask Research in Casama what's left on the launch list, then run the morning brief" | Siri AI calls Ask, reads the answer, asks to confirm, then runs the routine |

What Siri says for each outcome of an Ask (words live in `app_en.arb`, §6.9):

| Outcome | Siri says |
|---|---|
| The bot replied in time | The reply. Spoken in full when short; the first part spoken and all of it shown when long |
| Still working when time runs out | "Research is still working on it. You'll get a notification when it's done." The Live Activity and the reply push carry on |
| The bot needs an OK | "Research needs your OK first. Open Casama to review it." |
| Reply text is hidden (§4.3) | "Research replied. Open Casama to read it." |
| Out of credits, offline, signed out | One plain line each, as the app says it |
| The app couldn't act in place | The app opens on Quick ask with the bot and the words filled in |

## 6. How it works

### 6.1 One path: Siri → the app → Dart

An intent that lives in the app runs in the app's process. If the app isn't running, iOS starts it
in the background. The intent then hands a small map to Dart over the channel that Stop and Run now
already use (`casama/island` → `action`) and waits for the answer.

New actions beside `stop`, `allow`, `deny`, `run_routine` and `accept`:

| `kind` | Arguments | Dart answers |
|---|---|---|
| `ask` | `bot_id` (may be empty), `text`, `wait_ms`, `request_id` | `status` (`replied`, `working`, `needs_you`, `hidden`, `no_credits`, `offline`, `signed_out`, `failed`), and when allowed `text`, `bot`, `conversation_id`, `message_id`, `run_id` |
| `send` (Phase 3) | `bot_id` or `conversation_id`, `text`, `request_id` | `status`, `conversation_id`, `message_id` |
| `messages` (Phase 3) | `ids` | The messages, for Siri's entity lookups |

- **`ask` builds on `_ask`**, which the notch uses: a new chat with the bot, the message sent, the
  run tracked. Added: it waits for the run to end (up to `wait_ms`) and returns the reply.
- **`request_id` stops double sends.** Siri may call an intent again. The bridge remembers each id
  for a minute and answers a repeat with the first result.
- **At most five asks a minute from Siri.** A model that loops can't burn someone's credits.
- **Not ready in time:** as today, after ten seconds without Dart the intent asks iOS to bring the
  app forward and Quick ask opens with the words kept.
- **The app lock** (D-375): as with widgets, acting opens the app and the lock screen asks first.

"What needs me" needs no Dart. It reads the glance from the App Group, which is already private
when it has to be.

### 6.2 How long Siri waits

Unknown until Phase 0 measures it. The plan assumes Dart may wait about 20 seconds after sending,
and the number becomes whatever Phase 0 finds, less a safe margin. Replies that take longer go the
"still working" way (§5), so a slow bot is never an error.

### 6.3 Entities

| Entity | Fields Siri sees | From |
|---|---|---|
| Bot | Name, one-line description, mark | The shortcuts list, grown by a description and the mark |
| Routine | Name, bot, when it runs | The shortcuts list |
| Chat | Title, bot, last active | New: the 50 most recent chats, ids and titles only |
| Message (Phase 3) | Author, text, date, chat | Asked from Dart by id, never stored natively |

`client/lib/core/shortcuts.dart` keeps writing one JSON value (`flutter.casama.shortcuts`), now
with `chats` and the extra bot fields. The file is read in the app's process, so it stays in the
app's own preferences.

The intents and entities move out of the two `AppDelegate.swift` files into one folder that both
the iPhone and the Mac project compile, as the widget files already are.

### 6.4 Spotlight (Phase 2)

- Bot, Routine and Chat conform to `IndexedEntity`. After each sync the app indexes them with
  `indexAppEntities` and removes what is gone.
- Sign-out and a workspace switch clear the index first.
- Nothing is indexed while the workspace is private, the app lock is on, or the person turned
  **Show in Spotlight and Siri** off (Settings → Privacy; on by default, §13 decision 5).
- A tap on a result opens the bot's chat, the chat, or the routine, through the path the intents
  already hand to Flutter.

### 6.5 What is on screen (Phase 2)

Flutter draws its own views, so Apple's per-view tags can't be used. Apple's other way fits: one
entity on an `NSUserActivity`. Dart tells native which bot or chat is open whenever the route
changes; native sets the activity on the Flutter view controller (the window on the Mac) and drops
it when the person leaves. Nothing is set under the privacy rules of §6.4.

### 6.6 Donations (Phase 2)

When someone sends from Quick ask or presses Run now, the app donates the matching intent, so Siri
can suggest it. Not for every chat message.

### 6.7 Schemas (Phase 3, iOS 27.0)

- **Send and draft.** `SendMessageIntent` follows `.messages.sendMessage`; `DraftMessageIntent`
  follows `.messages.draftMessage`. The destination is a bot (`.messages.messagePerson`) or a chat
  (`.messages.conversation`). Contacts from the address book aren't a destination.
- **Send** uses the `send` action and returns the sent message at once. Siri says it is sent; the
  bot's reply arrives as a notification. **Draft** opens the chat with the words in the box.
- **Whether Send may also speak the reply** isn't clear from Apple's pages. The build tries it. If
  not, Ask stays the way to hear an answer.
- **Text and links first.** Files and pictures go through only if the existing upload path takes
  them without new work; otherwise Siri says to add them in the app.
- **The schema's other types** (message type, attributes, effect, reaction, custom attachment) get
  the smallest honest conformance; most fields are empty.
- **Search and open.** `.system.searchInApp` opens the app's search with the words;
  `.system.open` opens an entity.
- All of it sits behind `@available(iOS 27.0, macOS 27.0, *)`. The app's minimums don't move.

### 6.8 Tools, skills and cards (Phase 4, on a branch)

- **Tools** (`@AppIntent(.tool)`): Ask a bot, Run a routine, What needs me, Stop a bot, Call a bot
  (opens the call screen). Send and draft stay schema intents.
- **Run a routine asks first** as a tool ("Run Morning brief with Research?"), since the model
  picked the routine, not a tap.
- **Never tools:** Allow and Deny, anything about billing, sharing or settings, widget and Live
  Activity intents.
- **Descriptions** on every intent, parameter and entity field.
- **Cards:** a `CardSnippet` for a bot's reply (mark, name, the reply's first lines) and for a
  routine.
- **Skills:** `Skills.skillsbundle` with `ask-a-bot`, `run-a-routine` and `whats-waiting`. They
  say when to use which tool, to ask which bot when none was named and never guess, and that
  approvals are answered in the app.
- **Evaluations:** about twenty scripted requests with Apple's Siri Evaluations framework, run
  before and after each change to a description or skill.
- **Tooling:** Xcode 27.3 beta beside 27.2, picked per command with `DEVELOPER_DIR`, never
  switched for the whole Mac since other sessions build with 27.2. Its own worktree. The first
  step is finding out whether Flutter 3.50 builds with the beta at all.
- **Merge** when Xcode 27.3 is final and Apple has published the terms.

### 6.9 Words

- What Siri says back comes from `app_en.arb`, written beside the shortcuts list the way widgets
  get `glance_words`, with an English copy in native code for when it is missing.
- Intent titles and phrases must be literals Apple can index ahead of time, so they stay in Swift,
  in English, as today.

### 6.10 The Mac

The same files and the same phases. The Mac app hands actions to Dart over its own bridge
(`casama/mac`), and it is usually running already because of the menu bar and the notch. This Mac
runs macOS 27.2, so Phases 1 to 3 can be checked here if Apple Intelligence is on.

## 7. What we're not shipping, and why

| Not shipping | Why |
|---|---|
| A native key that lets Swift call the server by itself | D-405's rule: a key in native code reads, it never acts. Only if Phase 0 shows Dart can't come up in time (§13 decision 1) |
| Allow and Deny by voice | Approvals need eyes on the details. Apple's own advice is the same for actions a person must start themselves |
| Message text in Spotlight | Privacy (§9). Titles and names are enough to find a chat |
| Entities on notifications | Our pushes come from the server; tagging them needs a new notification extension. Later, if Siri AI's "reply to this" proves worth it |
| Edit, unsend and read-status message schemas | Optional, and the app has no unsend |
| Side-button activation | Japan only |
| Apple's per-view tagging | Flutter's views aren't UIKit views; one entity per screen instead (§6.5) |
| Watch, Android, Windows, Linux, web | Out of scope here |

## 8. Changes by area

| Area | Change |
|---|---|
| `client/ios/Siri/` (new; compiled into the iPhone and Mac apps) | Entities, intents, the shortcuts provider, the Spotlight indexer, the on-screen activity, words. The Mac and iPhone `AppDelegate.swift` lose their copies |
| `client/ios/Runner.xcodeproj`, `client/macos/Runner.xcodeproj` | The new files; in Phase 4 the skills bundle |
| `client/lib/core/shortcuts.dart` | Chats and bot details in the list; the on-screen call; donations; the words |
| `client/lib/features/island/island_bridge.dart` | `ask` that waits, `send`, `messages`, the request-id memory and the per-minute limit |
| `client/lib/features/settings/` | **Show in Spotlight and Siri** under Privacy |
| `client/lib/l10n/app_en.arb` | Siri's lines and the switch |
| `packages/contracts/analytics/catalog.json` | `siri_action` (§15) |
| `docs-site/guide/chat.md` (Shortcuts table), the privacy page | What Siri can do; what is shared with the system's search (§9) |
| `client/store/app_store/review_notes.txt` | How a reviewer tries it |
| Server, database | **Nothing** |

## 9. Security and privacy

- **Siri's model is an outside caller.** It chooses the tool and fills in the values. Every call
  goes through Dart's checks, exactly like a widget press. There is no new key and no new route.
- **A bot's reply becomes input to Siri's model.** A reply shaped by a bad web page could try to
  steer Siri. We return plain text, cap its length, expose no tool that destroys or spends without
  asking, and Run a routine confirms in Phase 4. What Siri does in other apps is Apple's to guard.
- **Replies leave the app when Siri reads them.** That is new: reply text goes to Apple
  Intelligence. The docs and the privacy page say so. Hide reply text (D-325), a private workspace
  and the app lock all stop it.
- **A locked phone** asks to unlock before Ask, What needs me and Run a routine (§13 decision 4),
  as D-405 does for Run now.
- **The index holds names and titles only**, on the device, and empties on sign-out, on a workspace
  switch and when the switch goes off.
- **Counting** (`siri_action`) carries the action and how it ended, never words.
- **Store privacy labels** don't change: we collect nothing new.
- **Apple's terms for Siri AI** aren't out. We read them before Phase 4 ships.

## 10. Cost

- **Apple:** nothing beyond the developer program, as far as Apple has said. If the coming terms
  add a fee, it goes in `docs/COSTS.md` before Phase 4 ships.
- **Running:** an Ask is a normal run on the person's plan. No new vendor, no new usage kind, no
  change to `docs/COSTS.md` now.
- **Ours:** the build time in §11; about 30 to 40 GB of disk for the Xcode beta (311 GB are free);
  re-testing when a beta changes the API.

## 11. Phases

Each phase ends at its "Done when", then gets a commit. Builds and device runs need Oliver's yes
each time.

### Phase 0: proof on a device (half a day, plus one debug build on the iPhone)

- Add timing to the existing Run now path and a throwaway intent that waits a set number of
  seconds.
- On the iPhone, with the app closed: run each from Siri and from Shortcuts.
- **Done when** we know (a) whether Dart is ready in a background start and how long it takes,
  (b) how long Siri waits, on the Lock Screen too, and (c) whether the phone has Apple
  Intelligence. If (a) fails, stop and take decision 1 again.

### Phase 1: answers inside Siri (2–3 days)

- `ask` that waits, the request-id memory, the limit.
- Ask, Run a routine and What needs me answer in place; a small view with the bot's mark and the
  reply; the fallbacks of §5.
- The move to `client/ios/Siri/` for both apps.
- **Done when** each row of §5's outcome table happens on the iPhone and the Mac, from Siri and
  from Shortcuts, app closed and app open.

### Phase 2: findable and on screen (1–1.5 days)

- The bigger list, `IndexedEntity`, the indexer, the switch, open-from-Spotlight, the on-screen
  activity, donations.
- **Done when** a bot, a routine and a chat come up in Spotlight and open; they vanish after
  sign-out and with the switch off; and on an Apple Intelligence device Siri AI resolves "this
  chat".

### Phase 3: schemas (3–4 days; after launch, if decision 7 says yes)

- First step: compile one schema intent with Xcode 27.2 to confirm the SDK has them.
- Send and draft with their entities; search and open.
- **Done when** "tell my … bot in Casama to …" sends without a set phrase on iOS 27, draft opens
  the chat with the words, Xcode shows no use-case warnings, and iOS 26 and earlier still build
  and run.

### Phase 4: tools, skills, cards (2–3 days, on a branch; needs a device on 27.3)

- Xcode beta and the Flutter compile check, then §6.8.
- **Done when** the twenty evaluation requests pass twice in a row on a 27.3 device, and the
  branch is ready to merge the day the SDK is final.

## 12. Checks

- **Dart:** tests for `ask` (each status), the request-id memory, the limit, the list the intents
  read, and that nothing is written under the privacy rules. `flutter test` on those files while
  working.
- **Swift:** small pure pieces (trimming a reply for speech, reading the list) in `RunnerTests`.
  Running them is an Xcode build, so it is asked for.
- **Full suites** once at the end through `scripts/heavy.sh`.
- **Device list** (Oliver's iPhone; this Mac for the Mac app): each "Done when" above, plus the
  Lock Screen, the app lock on, a private workspace, Hide reply text on, no network, signed out,
  and a reply that takes a minute.

## 13. Decisions for Oliver

| # | Question | Recommended | Other choice |
|---|---|---|---|
| 1 | How does Siri act? | **Through the app and Dart**, as widgets do. No new key, the code exists. (In chat I first leaned to a native key; reading D-405 changed that.) | A native key like the watch's, if Phase 0 shows Dart can't start in time. Costs server work and a security review |
| 2 | What to build now | **Phases 0–2 for the next app build; Phase 4 as a branch experiment; Phase 3 later** | Everything now (9–12 days), or only Phase 4 and wait for spring |
| 3 | Where an Ask lands | **A new chat each time**, as the notch does. Phase 3's Send can name an existing chat | The person's latest chat with that bot, as the watch does |
| 4 | Locked phone | **Unlock first** for Ask, What needs me and Run a routine | Allow from the Lock Screen, with reply text hidden |
| 5 | What goes in Spotlight | **Bots, routines and chat titles, with one switch** (on by default; off with a private workspace or the app lock) | Bots and routines only |
| 6 | No bot named | **The bot Quick ask would use**; Siri says which one answered | Always ask "Which bot?" |
| 7 | Phase 3 at all? | **Decide after Phase 2 is on a phone.** It is the most work for the least gain: Siri says "sent" and the answer comes as a notification | Build it straight after launch, or skip it and rely on tools in spring |
| 8 | Phase 4's test device | **Wait for the public 27.3 release**, so no beta goes on a daily phone | Put the 27.3 beta on a spare iPhone now |
| 9 | What we say in public | **"Works with Siri"** once Phase 1 ships; "Siri AI" only when tools are in the store | Announce Siri AI support early |

## 14. Risks

- **Dart doesn't start in the background, or starts too slowly.** Phase 0 exists for this. The way
  out is decision 1's other choice.
- **Siri's wait is short.** Then most answers become "still working" and Phase 1 is worth less.
  Phase 0 tells us before we build.
- **Apple changes the preview API.** Likely. Phase 4 stays on its branch and is small.
- **Apple's terms are unknown.** A fee or a rule could change whether Phase 4 ships.
- **App Review and the messages schema.** A bot as a message recipient is a fair reading for a chat
  app with coworkers and bots, but it is our reading.
- **Phrases stop working in Siri once a tool exists.** Covered by making the tools match the
  phrases; checked in Phase 4's "Done when".
- **More native code that only a device can prove.** We already have a pile of it (island,
  widgets, watch). Phase 0 and the device list are there so this doesn't add to it blindly.
- **Reach.** Phases 2 to 4 at their best need an Apple Intelligence device. One press report says
  Siri AI is delayed in the EU; not confirmed by Apple.

## 15. How we'll know it worked

One event, `siri_action`: `action` (`ask`, `run`, `needs`, `send`, `draft`, `search`, `open`),
`outcome` (`replied`, `working`, `needs_you`, `hidden`, `opened_app`, `failed`) and the wait in
seconds. No words.

- Of all asks, the share that never had to open the app. Aim: 8 in 10.
- Median seconds to a spoken reply.
- People who use Siri at least once a week, against weekly active people on iPhone and Mac.

## 16. Left for Oliver

- A yes for the Phase 0 debug build on the iPhone, and about an hour with the phone.
- Whether the iPhone has Apple Intelligence (15 Pro or later).
- Answers to §13.
- Later: a device on 27.3 for Phase 4, and a read of Apple's Siri AI terms when they appear.

## Sources

- Apple, "Siri AI is now open to all developers", 2026-11-03: https://developer.apple.com/news/?id=gdk2umrf
- Apple Intelligence and Siri AI: https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai
- Siri AI Developer Preview: https://developer.apple.com/documentation/appintents/siri-ai-developer-preview
- Bringing custom actions and content to Siri: https://developer.apple.com/documentation/appintents/bringing-custom-actions-and-content-to-siri
- Orchestrating complex actions with app skills: https://developer.apple.com/documentation/appintents/orchestrating-complex-actions-with-app-skills
- App schema domains: https://developer.apple.com/documentation/appintents/app-schema-domains
- Messages domain: https://developer.apple.com/documentation/appintents/app-schema-domain-messages
- Integrating your messaging app with Apple Intelligence: https://developer.apple.com/documentation/appintents/integrating-your-messaging-app-with-apple-intelligence
- Making actions and content discoverable by Apple Intelligence: https://developer.apple.com/documentation/appintents/making-actions-and-content-discoverable-by-apple-intelligence
- Providing contextual cues to Apple Intelligence and Siri: https://developer.apple.com/documentation/appintents/providing-contextual-cues-to-apple-intelligence-and-siri
- Making app entities available in Spotlight: https://developer.apple.com/documentation/appintents/making-app-entities-available-in-spotlight
- `ToolIntent`: https://developer.apple.com/documentation/appintents/toolintent
- `CardSnippet`: https://developer.apple.com/documentation/appintents/cardsnippet
- Siri Evaluations: https://developer.apple.com/documentation/sirievaluations
