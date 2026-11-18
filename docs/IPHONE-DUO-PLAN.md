# iPhone Duo: the outer screen, the inner screen, and every pose between them

Status: **approved and built, D-411** (2026-11-19). Oliver said "go and build all now", taking
every §8 default, and then "You decide all for me" on what was left open (§11.5). It was built on
branch `worktree-iphone-duo` (cut from origin/main `b1f64481`) and goes to main through a pull
request. Nothing is deployed and there is no store build. What was built, where it differs from
this plan, and what has not been checked yet are in **§11**. Sections 0 to 10 are the proposal as
approved.

Every platform fact below carries a mark for where it comes from:

- **[SDK]** read in the iOS 27.2 SDK headers on this Mac (Xcode 27.2).
- **[Sim]** read in the iPhone Duo simulator profile on this Mac.
- **[Apple]** Apple's design and developer pages and Tech Talks.
- **[3P]** measured by other people on the simulator (Flutter's own pull request, two Flutter
  packages, two agency write-ups). §11.4 has our own readings from the iPhone Duo simulator,
  taken after the build: they agree with these.

## 0. Summary

The iPhone Duo is Apple's first folding iPhone (on sale 2026-10-23, from $1,999). Closed, it is a
short, wide phone with a 5.4-inch outer screen. Open, it is a 7.6-inch inner screen, almost
square, with a fold down the middle. It can also sit half open like a book, a laptop or a tent.

This plan makes Casama feel built for it:

| Pose | Window | What Casama becomes |
|---|---|---|
| **Closed** (outer screen) | 466 × 678 | The phone app, with its buttons and tabs in the strip down the right edge where iOS puts its own, so content gets the full height |
| **Open, wide** | 951 × 669 | Two panes that meet on the fold: the chat list on the left, the chat on the right. Same strip, same buttons, same place |
| **Book** (wide, partly folded) | 951 × 669 | The same two panes, with the 40-point fold band left empty. Sheets and dialogs open on the right half |
| **Laptop** (tall, partly folded) | 669 × 951 | The bot's computer on the top half, a trackpad, keys and the chat line on the bottom half. Calls put the bot on top and the buttons below |
| **Tent** (outer screen, on its side) | 678 × 466 | Hands-free: a call or the bot's computer fills the screen, and the screen stays awake |
| **Open, tall** | 669 × 951 | The phone app with room to breathe |
| **Split View** (beside another app) | 469 × 669 | The phone app; files dragged from the other app drop into the chat |

Opening and closing the device never loses anything: the same chat, scroll position, draft and
keyboard carry across both screens.

Four findings shape the plan:

1. **Casama already runs full screen on a Duo, and nobody designed it.** Builds made on this Mac
   use the iOS 27.2 SDK (the last archive says `DTSDKName iphoneos27.2`), which is the SDK that
   opts an app into the whole screen [Apple]. On the outer screen iOS then reserves an 84-point
   column down the right side for the camera, clock and battery [3P]. Apple's own apps put their
   buttons in that column. A Flutter app gets nothing there: either a blank column, or content
   running under the clock, depending on the screen.
2. **Flutter cannot see the fold.** `MediaQuery.displayFeatures` is empty on iOS in Flutter 3.50.
   The pull request that fills it (flutter/flutter #193025) is open and waiting for Flutter's CI to
   move to Xcode 27.1. The SDK has everything we need, so we read it with a small native bridge of
   our own (§6.1).
3. **Our layout rules were written for phones, tablets and desktops.** They look only at width:
   under 700 is a phone, 700 to 1100 gets a rail and one page at a time, 1100 and up gets the
   sidebar. The inner screen is 951 wide, so today it shows the tablet rail and a single page. On
   its side it is 669 wide, so it shows the phone layout. Neither uses the screen.
4. **Nothing in the app blocks this.** It already uses the scene lifecycle, locks no orientation,
   has no `UIRequiresFullScreen`, and keeps a page's state when the shell around it changes. The
   Android app already survives a fold without restarting.

It is built in six phases (§7). Phase 1 (the strip on the outer screen) and Phase 2 (two panes on
the inner screen) are the ones people will see first. Each phase is usable on its own.

Mockups for every pose: `docs/media/iphone-duo-mockups.html`.

## 1. What exists today

| Already built | Where | What it does on a Duo |
|---|---|---|
| Width classes | `client/lib/theme/app_tokens.dart` (`AppBreakpoints`: 700, 1100), `client/lib/features/home/home_shell.dart` (`LayoutSize`, `layoutFor`) | Outer screen: phone. Inner wide: tablet. Inner tall: phone |
| Three shells | `home_shell.dart` `_buildShell`: floating tab bar (phone), rail (tablet), sidebar + chat + computer panel (desktop) | The inner screen never reaches the desktop shell, so it never shows a list beside a chat |
| One header for main screens | `client/lib/ui/shell_header.dart` (`ShellHeader`, `HeaderIconButton`), used by 15 files; 5 others still use a plain `AppBar` (`totp_scan`, `chat_markdown`, `bot_ui_map`, `join_flow`, `pairing`) | A horizontal bar. On the outer screen it sits beside the status column instead of under a status bar |
| One sheet helper | `client/lib/ui/adaptive_modal.dart` (`showAdaptiveSheet`, `showConfirm`), `form_sheet.dart`, `spring_sheet.dart`, `adaptive_sheet_route.dart` | Under 700 wide a bottom sheet, otherwise a centred dialog. Chosen when it opens and never again, so a sheet opened on the outer screen stays a 951-point-wide sheet after opening the device. A centred dialog sits right on the fold |
| Chat list beside the chat | Desktop only: `_Sidebar` in `home_shell.dart`; `/bots` renders nothing on desktop (`client/lib/core/router.dart:426`); a wide window opens the last chat (D-383, `last_chat.dart`) | The pattern Phase 2 reuses |
| Settings list beside a settings page | Desktop only: `SettingsScreen(pane: true)` in `home_shell.dart` | Reused as is |
| The bot's computer beside the chat | Desktop only: `ComputerScreen(embedded: true)` in a resizable panel (D-090) | Reused in the left pane |
| Live view with a sideways mode | `client/lib/features/computer/live_view_screen.dart`: full screen when height is under 500 and the window is wider than tall (D-219) | Turns on by itself in the tent pose (678 × 466), but knows nothing about the status column |
| State that survives a layout switch | go_router gives the shell's navigator a global key, so pages move instead of being rebuilt; drafts are saved per chat | Opening and closing keeps the chat, its scroll position and its draft. Not yet tested across a fold |
| Scene lifecycle on iOS | `client/ios/Runner/SceneDelegate.swift` (`FlutterSceneDelegate`), `Info.plist` scene manifest | Required by the iOS 27 SDK. Already there |
| Orientation | `Info.plist`: portrait and both landscapes on iPhone; nothing in Dart locks it | Good: the inner screen ignores orientation settings anyway [Apple] |
| Android fold handling | `AndroidManifest.xml` `configChanges` includes `screenSize`, `smallestScreenSize`, `screenLayout` | The activity is not recreated on fold. No layout uses the fold |
| Live Activity and Dynamic Island | D-324: `client/ios/Runner/IslandActivities.swift`, `client/ios/CasamaWidgets/` | Should appear in the outer screen's camera corner [Apple]. Not checked |
| Layout tests | `client/test/phone_layout_test.dart` sweeps every route at 430 × 932 and 375 × 667; `navigation_test.dart`, `sidebar_test.dart` | No Duo sizes, no fold, nothing that crosses a size change |

Gaps on a Duo, from reading the code (to be confirmed on the simulator in Phase 0):

- **The status column is unplanned.** Screens that use `SafeArea` lose 84 points on the right for
  nothing. Screens that only pad top and bottom run under the clock and camera.
- **The floating tab bar and Apple's tab position disagree.** Ours floats at the bottom; every
  Apple app on this phone has its tabs at the bottom of the side column.
- **The inner screen shows one page at a time.**
- **Width checks read the whole window** (`MediaQuery.sizeOf(context).width`, in 13 files). Inside
  a pane they would get the wrong answer.
- **No screen knows the fold exists.** Dialogs, the minimised call bubble, toasts, the live view
  and the call screen can all land on it.
- **Split View: files can't be dropped into a chat.** Drag and drop uses `desktop_drop`, which is
  desktop only.

## 2. What the device and iOS give us

### 2.1 The two screens

| | Outer | Inner |
|---|---|---|
| Size | 5.4 in | 7.6 in |
| Points | 466 × 678 [Sim] | 669 × 951, used wide as 951 × 669 [Sim] |
| Pixels | 1398 × 2034 at 3x [Sim] | Drawn at 2007 × 2853 at 3x, shown on a 1878 × 2670 panel [Sim, Apple] |
| Corners | 8 pt on the hinge side (left), 59 pt on the right [Sim] | 55 pt all round [Sim] |
| Front camera | In the top right corner, always visible [Apple] | Under the screen, hidden until the camera is in use [Apple] |
| Size classes | Compact width, regular height (upright); compact both ways on its side [Apple] | Regular both ways [Apple] |

### 2.2 The poses

Apple names six [Apple]. Insets are what iOS reports to a Flutter app [3P].

| Pose | Screen | Window | Safe-area insets | Fold |
|---|---|---|---|---|
| Closed | Outer | 466 × 678 | right 84, bottom 34, top 0 | none |
| Tent | Outer, on its side | 678 × 466 | left 84, bottom 34 | none |
| Open, wide | Inner | 951 × 669 | right 84, bottom 34 | inactive |
| Book | Inner | 951 × 669 | right 84, bottom 34 | active: a vertical band 40 pt wide, x 455.5 to 495.5 |
| Open, tall | Inner, rotated | 669 × 951 | top 82, bottom 34 | inactive |
| Laptop | Inner, rotated | 669 × 951 | top 82, bottom 34 | active: a horizontal band 40 pt tall |
| Split View | Inner, half | 469 × 669 | bottom 34 only | not ours |

Opening, closing and rotating are window resizes: the process keeps running and no lifecycle event
fires [Apple, 3P]. Folding the open device part-way changes nothing but the fold [3P]. The fold
becomes active about a second after the device comes to rest half open on the simulator, and
clears within 15 ms of lying flat [3P].

### 2.3 The side strip (Apple calls it a vertical bar)

- With the iOS 27.1 SDK or later an app reaches the screen's edge, and "standard navigation and
  toolbar buttons now lay out vertically under the status bar" [Apple].
- Top to bottom along that edge: Dynamic Island, status bar, toolbar buttons, tab bar [Apple].
- It appears on the outer screen and on the inner screen held wide. Held tall, the inner screen
  goes back to ordinary horizontal bars [Apple].
- It follows the hardware, not the language: it stays on the same side in right-to-left
  languages [Apple]. It can be on either side (`UIVerticalBarEdge`: leading or trailing [SDK]).
- Back or close sits at the top, then the main action, then the rest. Items with an icon go
  vertical. Text-only items (an "Edit" button) stay horizontal with the content [Apple].
- When there isn't room (keyboard up, tent pose), items overflow from the bottom into a "…" menu
  that shows icon and title [Apple].
- In a split view only the detail side uses the strip; the list side keeps a horizontal bar [Apple].
- Accessory bars stay attached to the keyboard [Apple].
- **It only works with Apple's own navigation classes** [Apple]. Flutter draws its own bars, so
  Flutter gets the inset and nothing else. Flutter does not read the trait either [3P].

### 2.4 The fold and the hinge

All iOS 27.1 and later [SDK]:

- `UIHingeInteraction(updateHandler:)` added to a view reports a `UIHinge`: `status` (unknown,
  closed, partiallyOpen, fullyOpen) and `angle` in radians. `hinge` is nil on a device without one.
  Apple says to use the status for layout and the angle only for effects.
- `UIView.reservedRegions(ofKind:options:)` returns `UIViewReservedRegion` objects with `frame`,
  `margins` and `isActive`. Two kinds: `.division` (the fold) and `.occlusion` (a camera). The
  `includeInactive` option returns the fold while the device lies flat.
- `UITraitCollection.verticalBarEdge` and `systemTraitsAffectingVerticalBarEdge` say which side
  the strip is on and when that changes.

Apple's layout rules for the fold [Apple]:

- Lists, feeds and articles may cross it. Nothing else should sit on it while it is active.
- "Avoid extreme layout changes as people fold the device. Move only what's necessary."
- A list beside a detail becomes an even 50/50 split around the fold.
- Grids use an even number of columns, keep their outer margins and widen the gap at the fold.
- Alerts, menus and sheets move off the fold to the trailing side, so they are close to where
  they will be when the device closes.
- Propped up (laptop): the top half is for what you look at, the bottom half for what you touch.

### 2.5 What iOS decides for us

- **The inner screen ignores supported orientations.** An app cannot lock it [Apple].
- **Split View** is there for every app [Apple], and is 50/50 only [3P].
- **A second window of the same app** is possible on the inner screen only, and only if the app
  supports multiple scenes [Apple]. Ours does not (`UIApplicationSupportsMultipleScenes` is false).
- **Showing something on the outer screen while the device is open** is reserved for camera apps:
  `UISceneAccessory.cameraCapture` needs an active camera session [SDK]. Not for us.
- **Screenshots.** App Store Connect accepts 1398 × 2034 (outer) and 2007 × 2853 (inner). From
  April 2027 they are required for any app built with the iOS 27.1 SDK or later, and an app that
  has them gets a "made for iPhone Duo" badge on its page [Apple, read through a summary: check
  the page before relying on the date].

### 2.6 Where Flutter 3.50 stands

- **Works:** the window resizes on open, close and rotate; state is kept; no `initState` runs
  again [3P]. Flutter 3.50 includes the fix that reports the right screen after a fold (#195690).
- **Missing:** the fold (`displayFeatures`, PR #193025 open, last activity 2026-11-12), the strip
  trait, vertical bars.
- **Open bugs:** the keyboard closes when the device changes pose (#193096, open, no fix). One
  write-up reports a black frame for a moment while the app moves between the two screens; the
  Flutter issue was closed as an iOS bug. Both go on the Phase 0 checklist.
- **Stock dialogs avoid the fold by themselves once they know about it.** Flutter's dialog, menu
  and bottom sheet routes already keep clear of display features (added for Android foldables).
  They only need the fold in `MediaQuery`, which §6.2 provides.

## 3. Principles

1. **One app, one state, two screens.** What is on one screen is on the other after a fold.
2. **Controls go where iOS puts them.** On this phone that is the strip.
3. **The fold is a divider.** While it is active nothing you can tap sits on it.
4. **Layout follows the window and the fold, never "is this a Duo".** The same rules then serve
   Android foldables and iPad, and keep working on whatever Apple folds next.
5. **Move only what has to move.** Folding the device part-way opens a gap; it does not rearrange
   the screen.

## 4. What ships

### A. The side strip

A column drawn by Casama inside the inset iOS reserves, on whichever side it is.

- **Top:** left alone. iOS draws the camera, clock and battery there.
- **Under them:** Back (or close), then the screen's icon buttons. These are the same buttons
  that sit in the header today (`HeaderIconButton`), stacked.
- **Bottom:** the three tabs (Chats, Library, Tasks) as icons with the unread badge, and the
  Apps button under them. Shown where the floating tab bar shows today.
- **The title stays with the content:** avatar, name and status in a row at the top of the page.
  Text buttons ("Save", "Done") stay in that row.
- **When space runs out** (keyboard up, tent pose): buttons fold from the bottom into a "…" menu
  with icon and label. Every header button already has a label (its tooltip).
- **No strip, no change:** on an ordinary iPhone, in Split View without the inset, and on the
  inner screen held tall, headers and the floating tab bar stay exactly as they are.
- Page backgrounds and chat wallpapers run under the strip. Rows and bubbles do not.

### B. Two panes on the inner screen

For windows from 840 to 1099 points wide (decision 1), which on a Duo means the inner screen held
wide:

- **Left pane:** the tab you are on. Chats shows the chat list with its own header (workspace,
  search, new chat). The open chat is highlighted.
- **Right pane:** what you opened. Its buttons are in the strip. Pages opened from it (a bot's
  settings, activity, memory) open inside it, with Back in the strip.
- **They meet on the fold**, 50/50 (decision 2). The left pane is 475 points wide, almost exactly
  the outer screen, so the chat list looks the same on both screens. The right pane is 392 points
  plus the strip: an ordinary iPhone's width.
- **Nothing selected:** the right pane shows the last chat (D-383), without navigating to it. It
  becomes the current page on first touch, so opening and closing the device without touching
  anything brings you back to the list you were on.
- **Expand:** a button at the top of the strip hides the list and gives the chat the whole width,
  centred at the readable width (760). Folding the device part-way brings the list back
  (decision 8).
- **The bot's computer:** the monitor button swaps the left pane to the bot's computer (the panel
  desktop shows beside the chat), with the chat still on the right. One more tap takes the
  computer full screen.
- **Other tabs:** Library shows its grid on the left and the opened item on the right. Tasks has
  no item pages, so its board spans both halves with an even number of columns and the fold
  between two of them (decision 13). Settings shows its list on the left and the page on the
  right, as on desktop. Search opens over the left pane and results open on the right.
- On a device with no strip (iPad, a desktop window, an Android foldable) the same two panes sit
  beside today's rail.

### C. Continuity

| You are here | You open or close the device | You get |
|---|---|---|
| Chat list, outer screen | Open | The list on the left, the last chat resting on the right |
| A chat, outer screen | Open | The list on the left with that chat highlighted, the same chat on the right: same scroll position, draft, keyboard and cursor |
| Typing, either screen | Open or close | The keyboard stays up and the text is untouched |
| A sheet or dialog is open | Open or close | It stays open and re-centres on its new place. Never a sheet as wide as the inner screen |
| On a call | Open or close | The call screen re-flows; audio is untouched |
| Watching a bot's computer | Open or close | The live view stays connected and re-flows |
| Two panes, a chat on the right | Close | That chat, full screen, its buttons in the same place on the strip |
| Two panes, nothing touched | Close | The list |
| The computer in the left pane | Close | The chat, with the live dot on its monitor button |

### D. The poses

- **Book.** The two panes stay. The 40-point band between them is empty; only the page background
  runs through it. The left pane narrows to 455.5 points and the right to 371.5. Sheets, dialogs,
  menus and toasts open on the right half.
- **Laptop.** Screens made of something to watch and something to touch split at the fold:
  - *The bot's computer:* its screen fills the top half (a 16:10 screen shows at about 597 × 373
    under the status bar). The bottom half is a trackpad, the key row, and the chat line to tell
    the bot what to do. During a takeover this is a small laptop for the bot's computer.
  - *A call:* the bot and live captions on top; mute, speaker, captions and end below.
  - *Read aloud, a video, a file:* the content on top, its controls below.
  - A chat needs nothing: the thread scrolls across the fold (lists may), and the composer and
    keyboard are already at the bottom. The top half never jumps when the keyboard opens.
- **Tent.** The outer screen on its side, standing up, for hands-free use. A call shows the bot
  large with captions and three big buttons. The live view goes full screen (it already does at
  this size) with its controls in the strip. The screen stays awake during a call or a live view
  (the `casama/screen_awake` channel exists).
- **Open, tall.** The phone layout at 669 wide: horizontal header, floating tab bar. This is what
  Apple's apps do in this pose.

### E. Every screen

| Screen | Outer (closed) | Inner, wide and book | Laptop | Tent |
|---|---|---|---|---|
| Chats | List; tabs in the strip | Left pane | Phone layout | List beside the strip |
| Chat | Title row; buttons in the strip; composer at the bottom | Right pane | Thread across the fold | Usable; buttons overflow |
| Library | Grid; tabs in the strip | Grid left, item right | Phone layout | Grid |
| Tasks | List; tabs in the strip | Board across both halves, even columns | Phone layout | List |
| Settings | Pages; Back in the strip | List left, page right | Phone layout | Pages |
| Bot's computer | Live view; controls in the strip | Left pane, or full screen | **Screen on top, controls below** | **Full screen** |
| Call | Phone layout; minimise in the strip | Across both halves: bot left, controls right | **Bot on top, controls below** | **Hands-free** |
| Search | Full screen | Over the left pane | Phone layout | Full screen |
| Sign-in, welcome, onboarding | Stacked, clear of the status column | Picture on the left half, form on the right | Picture on top, form below | Stacked |
| Paywall | Stacked plans | What you get on the left, plans on the right | What you get on top, plans below | Stacked |
| File preview, read aloud | Full screen | Right pane | Content on top, controls below | Full screen |
| Minimised call bubble | Stays clear of the strip | Stays clear of the fold and the strip | Same | Same |

### F. Sheets, dialogs, menus and the keyboard

- A sheet or dialog picks its place from the window it is in **and follows it** when the window
  changes: a bottom sheet on the outer screen, a card centred in the right half on the inner
  screen held wide, a centred card when the inner screen lies flat and tall.
- Bottom sheets get a maximum width of 560 points everywhere, so none can stretch across the
  inner screen.
- While the fold is active nothing modal sits on it.
- Nothing above the panes makes room for the keyboard (already true: the shells set
  `resizeToAvoidBottomInset: false`); only the pane that owns the text field moves.

### G. Motion

- Opening the device: the list pane slides in from the fold while the chat settles to the right,
  260 ms, the app's curve. Closing reverses it. Off when the system asks for reduced motion.
- **The hinge drives it** (decision 7): between a right angle and flat, the list pane's reveal
  follows the angle of the hinge, so the app opens like the device does. Subtle, and only this
  one effect. It stays off until checked on a real device, because nobody has read a real hinge
  yet (§9).

### H. Multitasking

- **Split View:** the phone layout at 469 wide. No extra work beyond the route sweep at that size.
- **Drag and drop:** photos, files and text dragged from the app beside us drop onto the composer,
  as they do on desktop. Needs iOS drop support, which `desktop_drop` does not have (decision 14).
- **Hardware keyboards:** Cmd+K search and Cmd+F find already work on every layout that is not
  the phone layout.

### I. System surfaces

- **Live Activity and Dynamic Island (D-324):** no new code expected. Checked in Phase 5 in the
  outer screen's camera corner and on the inner screen.
- **Widgets (D-405, on the `widgets` branch):** iOS 27.1 lists a new family,
  `systemExtraLargePortrait` [Apple forum]. Out of this plan; noted for that branch.
- **Notifications, Lock Screen:** nothing to do.

### J. Android foldables

The Dart side is the same. On Android Flutter already fills `MediaQuery.displayFeatures`, so
Galaxy Z Fold and Pixel Fold get the two panes and the book and laptop poses from the same code.
Android has no strip, so its panes sit beside the rail. Checked on a foldable emulator
(decision 4).

### K. Store and website

- Duo screenshots, outer and inner, added to the store screenshot work
  (`docs/STORE-SCREENSHOTS-PLAN.md` on main), once the layouts exist (decision 9).
- One line and a picture on casama.ai once it has been seen on a real device (decision 10).
- A short page in `docs-site` on what the app does on a folding phone.

## 5. What is not shipping, and why

| Not shipping | Why |
|---|---|
| A second Casama window on the inner screen | Each window would be a second Flutter engine: double the memory, two copies of every provider, and two sign-in sessions racing to refresh the same token. The two panes cover the common case |
| Two chats side by side | Wanted, and the left pane can hold one later. Left out so the first version has one clear rule for the left pane |
| A draggable divider | The fold is the divider. Expand covers "give the chat more room" |
| Anything on the outer screen while the device is open | iOS allows it for camera apps only |
| Apple's own bars inside the Flutter app | Would mean native views over Flutter content. We draw the strip ourselves and match Apple's rules |
| Fold awareness for the web app in Safari | The web APIs for it are behind experimental flags in iOS 27.1 |
| Hinge effects beyond the one in §4 G | The hinge is for delight, not layout; one is enough |

## 6. How it works

### 6.1 The native bridge (iOS)

A new file, `client/ios/Runner/FoldBridge.swift`, registered next to the existing channels in
`AppDelegate.swift`. One event channel, `casama/fold`. About 150 lines.

- Adds a `UIHingeInteraction` to the Flutter view (iOS 27.1 and later, behind `#available`).
- Adds an invisible view pinned to the Flutter view and re-reads everything in its
  `layoutSubviews`, because the fold lags the hinge and Flutter's own reviewers found that reading
  regions only from the hinge handler misses updates.
- Sends one small map whenever something changed:
  hinge status and angle; the fold's frame and whether it is active; camera regions; which side
  the strip is on; the status bar's frame (`UIStatusBarManager.statusBarFrame`); size classes;
  whether the scene is full screen.
- The angle is sent only while Dart listens for it, and only when it moved by 2 degrees or more.
- Sends nothing on iOS before 27.1 and on devices without a hinge. The Dart side then reports "no
  fold" and every layout behaves as today.

Our own bridge rather than a package (decision 5): the `foldable` package (pub.dev, 49 likes)
covers the hinge and the fold but not the strip side, the status bar frame or the full-screen
flag, and this is a small file next to eight channels we already maintain.

### 6.2 Dart: one description of the window

New folder `client/lib/core/fold/`:

- `FoldState`: hinge status, angle, fold rectangle and whether it is active, strip side and width,
  the top of the usable strip.
- `Pose`: `plain`, `closed`, `tent`, `openWide`, `book`, `openTall`, `laptop`, worked out from
  the window size and the `FoldState`. `plain` is every device without a fold.
- `foldProvider`: fed by the channel on iOS and by `MediaQuery.displayFeatures` on Android.
- At the app root, the active fold is written into `MediaQuery.displayFeatures` as a
  `DisplayFeature` of type fold. Only while the hinge is partly open, never with a zero side,
  never while closed: the same rules Flutter's pull request uses. Flutter's own dialogs, menus
  and sheets then avoid the fold with no further code.
- When Flutter ships the fold on iOS itself, the root sees a non-empty list and stops adding ours.

### 6.3 Layout

- `LayoutSize` (in `home_shell.dart`) gains `split`, between `tablet` and `desktop`: 840 to 1099.
- `_buildShell` gains the split branch: `[left pane | right pane]` plus the strip or the rail.
- **Each pane overrides `MediaQuery`** with its own size and padding. The 13 files that ask "how
  wide is the window" then get the pane's width without being touched, and screens inside a pane
  behave as they do on a phone of that width.
- Modal helpers are the exception: `adaptive_modal.dart` reads the root window and the fold.
- **The strip** is built by the shell. `ShellHeader` stops drawing Back and icon actions when a
  strip is present and hands them to the shell through an inherited slot; it keeps the title row
  and text actions. The 5 screens that still use a plain `AppBar` move to `ShellHeader` first.
- New small widgets in `client/lib/ui/`: `SideStrip`, `FoldSplit(leading:, trailing:)` for the
  screens that split in half (sign-in, onboarding, paywall, call, live view), and `FoldGap` for
  the empty band.

### 6.4 Routing

No route changes. As on desktop today:

- The left pane is built by the shell from the current tab (`BotsScreen`, `LibraryScreen`,
  `BoardScreen`, `SettingsScreen(pane: true)`), not by the router.
- The right pane is the router's navigator. In split layout the tab's own root page renders
  nothing (`router.dart:426` already does this for desktop).
- The resting chat (§4 B) is a `ChatScreen` under a global key placed by the shell while the
  location is `/bots`. On first touch the shell navigates to `/bots/:id/chat` and the same widget
  moves into the route, keeping its state.

### 6.5 Tests

- `client/test/support/poses.dart`: one helper that pumps a widget in each of the seven windows
  of §2.2 with its insets and fold.
- `client/test/duo_layout_test.dart`: every route in every pose. No overflow, nothing tappable
  under the status area, nothing tappable on an active fold.
- `client/test/duo_continuity_test.dart`: type a draft and scroll in a chat on the outer window,
  switch to the wide window, to book, and back; the same `State` object, draft, scroll offset and
  focus each time. The same for an open sheet.
- `client/test/side_strip_test.dart`: order, overflow with the keyboard up, both sides, no strip.
- Unit tests for `Pose` from size and `FoldState`.
- On the simulator (Xcode's Device Hub can open, close, rotate and fold it): the checklist in §10.

## 7. Phases

| Phase | What | Size | Done when |
|---|---|---|---|
| **0. Look and measure** | The bridge and a readout screen under Settings’ advanced section showing live values. Run today's app on the Duo simulator in all seven windows | S | Every [3P] number in §2 is replaced by ours; screenshots of today's app in each pose are in `docs/media/duo-before/`; the list of what is actually broken is written into §1; the keyboard and black-frame bugs are confirmed or cleared on Flutter 3.50 |
| **1. The strip** | `SideStrip`, header slots, tabs in the strip, overflow, the 5 `AppBar` screens moved over; every screen checked on the outer window and in tent | M | The route sweep passes at 466 × 678 and 678 × 466; no blank column and nothing under the status area on any screen; an ordinary iPhone is unchanged: the existing phone tests pass untouched |
| **2. Two panes** | `LayoutSize.split`, pane `MediaQuery`, the resting chat, expand, the computer in the left pane, Library, Tasks, Settings and Search in split, sheets and dialogs that follow the window, the fold in `MediaQuery`, the book pose | L | The route sweep passes at 951 × 669 flat and book; the continuity tests pass; desktop at 1100 and wider is unchanged |
| **3. Laptop and tent** | `FoldSplit` layouts for the live view, the call screen, read aloud and file preview; tent call layout; screen awake; call bubble and toast bounds | M | The sweep passes in laptop and tent; a takeover can be driven end to end in laptop pose on the simulator |
| **4. The rest of the app** | Sign-in, welcome, onboarding and paywall in two halves; drag and drop in Split View; the opening motion and the hinge effect (off by default until a device check) | M | Every screen in §4 E matches its row |
| **5. Around the app** | Android foldable emulator check; Live Activity check; Duo store screenshots; the docs page; the DECISIONS entry | S | §10's checklist is filled in, with what could not be checked said plainly |

All work stays in this worktree. Tests while working are the changed files only; the full suites
run once at the end of each phase through `scripts/heavy.sh`.

## 8. Decisions for Oliver

Oliver took every default on 2026-11-19 ("go and build all now"). Decision 14 was then built
differently (§11.2), and decisions 9 and 10 wait for real screens (§11.3).

| # | Decision | Default | The other choice |
|---|---|---|---|
| 1 | Who gets two panes | Every window from 840 to 1099 points: the Duo, Android foldables, a 13-inch iPad upright, and desktop or web windows of that width, which today show the rail and one page | Only windows with a fold or a strip. Nothing changes for iPad and desktop, at the cost of a rule that asks what device it is |
| 2 | Where the two panes meet when the device lies flat | On the fold, 50/50. The crease hides in the divider, nothing moves when you fold it, and the list matches the outer screen | A narrow list (360) and a wide chat (507) when flat, sliding to 50/50 when folded. More room for the chat, but the crease runs through it and the layout shifts |
| 3 | Tabs on the outer screen | In the strip, like every Apple app on this phone | Keep the floating tab bar and use the strip for header buttons only |
| 4 | Android foldables in the same work | Yes. Same Dart code, checked on an emulator only | iPhone Duo only for now |
| 5 | Reading the fold | Our own bridge file | The `foldable` package from pub.dev |
| 6 | Laptop pose for the bot's computer | Yes: screen on top, trackpad, keys and chat line below | Leave the live view as it is |
| 7 | The hinge-driven opening motion | Build it, keep it off until checked on a real Duo | Don't build it |
| 8 | Expand (hide the list) on the inner screen | Yes | Always two panes |
| 9 | Duo screenshots for the App Store | Yes, with the store screenshot work, after Phase 2 | Wait until Apple requires them (April 2027, to be confirmed) |
| 10 | A "made for iPhone Duo" line on casama.ai | After it has been seen on a real device | Now, or never |
| 11 | Releasing before anyone has held it on a real Duo | Yes for layouts: they depend only on window size and fall back to today's app. Hinge effects wait | Hold everything until a real device check |
| 12 | A second Casama window | Not now (§5) | Plan it as its own piece of work |
| 13 | Tasks on the inner screen | The board across both halves, an even number of columns | List on the left, an empty right pane until tasks get their own page |
| 14 | Dropping files into a chat in Split View | Add `super_drag_and_drop` for iOS (also works on Android and desktop, could replace `desktop_drop` later) | A small native drop handler in the bridge, or leave it out |
| 15 | Simulator builds | A standing yes for debug simulator builds from this worktree, for this plan only. Device and release builds still ask each time | Ask before each one |
| 16 | Driving the Duo simulator | With `xcrun simctl` and Xcode's Device Hub, because the T3 device panel does not list it (§10) | You run the checks by hand from a list I give you |
| 17 | Do you have a Duo, or one coming? | Not assumed. If yes, Phase 5 adds a device pass and decision 7 can turn on | n/a |

## 9. Risks and unknowns

- **The numbers are other people's.** 84, 40, 82 and 469 come from third-party simulator
  measurements. If they are off, the design holds (everything reads the real insets and regions at
  run time), but the mockups shift.
- **Nobody outside Apple's labs has published a real hinge reading.** Every source tested on the
  simulator. The fold's timing, the angle's smoothness and how visible the crease is are unknown.
- **Where the status area ends inside the strip is not given by any API we have confirmed.**
  `statusBarFrame` should report it. If it does not, the fallback is the camera region plus a
  measured constant, which is fragile.
- **The strip is ours to keep right.** Apple will tune its vertical bars; ours can drift. If
  Flutter or `cupertino_ui` ships them, we switch.
- **Flutter bugs on this device are open:** keyboard closing on a pose change (#193096) and
  reported text input problems. Phase 0 finds out which ones we hit on 3.50; the workaround for the
  keyboard is to ask for focus again after the resize.
- **Decision 1 changes iPad and desktop windows between 840 and 1099.** Better, in my view, but it
  is a visible change for people who are not on a Duo.
- **A pane that lies about the window size** can confuse a widget that needs the real one (an
  overlay, a drag bound). Modals are handled; others will show up in the sweep.
- **Two other branches touch the same native files.** `widgets` and `watch` both edit
  `AppDelegate.swift` and the Xcode project. Whichever lands later rebases.
- **The required-screenshots date** (April 2027) was read through a summariser, not from Apple's
  page directly.

## 10. Left for Oliver, and what I could not check

- **The Duo simulator cannot be opened from the T3 device panel.** The Duo needs its own runtime
  (`iOS-27-2-iPhone19-4`), and the panel lists only devices on the general iOS 27.2 runtime:
  `device_open` answered "No device 811FEDCC-… on 'This machine'". The simulator "Casama Duo"
  exists and is shut down. Decision 16 covers how to drive it.
- **No Flutter build was made.** Each needs a yes (decision 15).
- Simulator checklist for Phases 0 to 5 (filled in as phases finish): the seven windows of §2.2;
  open and close while typing; open and close with a sheet up; a call through open, close, laptop
  and tent; a takeover in laptop pose; Split View on both sides; right-to-left; largest text size;
  Reduce Motion; the Live Activity on both screens.
- Real-device pass, if there is a device: the hinge effect, the crease against the divider, reach
  on the outer screen with one hand.
- Store uploads and production deploys are not part of this plan.

## 11. What was built (D-411, 2026-11-19)

All six phases, in one pass, on branch `worktree-iphone-duo`. `docs/DECISIONS.md` D-411 has the
decision and the mechanisms; this section is the plan's own ledger.

### 11.1 By phase

| Phase | Built | Where |
|---|---|---|
| 0. Look and measure | The bridge, the description of the window, the readout page, debug logging | `client/ios/Runner/AppDelegate.swift` (`FoldBridge`), `client/lib/core/fold/fold.dart`, `client/lib/features/settings/fold_screen.dart` (Settings → Folding screen) |
| 1. The strip | Tabs and header buttons in the strip, on either side; the page keeps clear of it; the title row stays | `client/lib/ui/side_strip.dart`, `client/lib/ui/shell_header.dart`, `home_shell.dart` |
| 2. Two panes | `LayoutSize.split`, panes on the fold, the last chat beside the list, hide and show the list, the bot's computer in the left pane, Library, Settings, the Tasks board around the fold, sheets and dialogs that follow the window, the book pose | `client/lib/features/home/home_shell.dart`, `client/lib/ui/shell_layout.dart`, `client/lib/core/app_page.dart`, `client/lib/core/nav.dart`, `client/lib/features/board/board_screen.dart`, `client/lib/ui/adaptive_modal.dart`, `spring_sheet.dart`, `toast.dart` |
| 3. Laptop and tent | The bot's computer with a trackpad, the call screen, in both the laptop and the book pose; a call layout for short, wide windows; the call bubble off the fold | `client/lib/ui/fold_split.dart`, `client/lib/features/computer/live_view_screen.dart`, `client/lib/features/voice/call_screen.dart`, `call_bubble.dart` |
| 4. The rest of the app | Pages outside the shell, dropped files in Split View, the list pane's arrival, the hinge effect (off) | `client/lib/ui/outside_shell.dart`, `client/lib/core/dropped_files.dart`, `DropBridge` in `AppDelegate.swift`, `_PaneReveal` in `home_shell.dart`, `hingeMotionProvider` |
| 5. Around the app | Android foldables through the same code (tests only), a tour of every pose for a simulator or a device, the guide page, the decision | `client/test/fold_test.dart`, `client/integration_test/duo_tour_test.dart`, `docs-site/guide/folding-phones.md`, D-411 |

### 11.2 Where it differs from sections 4 to 6

- **Overflow in the strip (§4 A).** The gaps between buttons close first, then the column scrolls.
  There is no "…" menu: header actions are free-form widgets with no label to show in one, and no
  screen needs it today (a chat's six buttons fit on the outer screen with the keyboard up).
- **In a tent the Apps button leaves the strip** so three of the page's own buttons still fit.
- **The last chat beside the list (§4 B, §6.4)** is a real navigation that is undone when the
  device closes without a touch in that pane. The plan's "shown without navigating" needed the
  same chat in two places in the tree.
- **The tabs stay in the strip on every page of the inner screen held wide**, as a rail would,
  not only on the tabs themselves: otherwise a page that spans both halves had no way out.
- **Held like a book, a page that wasn't made for the fold** (search, the computer page, a
  project) takes the right half and the chats take the left. Lying flat it spans both.
- **The Tasks board (§4 B)** has all its columns the width of the narrower half, one ending at the
  fold and the next starting after it, and comes to rest on those positions. The space left on the
  wider side shows the edge of the column before.
- **The bot's computer in the book pose** splits too: screen on the left half, trackpad and
  controls on the right.
- **Pages outside the shell (§4 E)** keep clear of the strip, and take the half you touch while
  the fold divides the window, with Casama's mark on the other half. Lying flat they stay
  centered: no picture on one half and form on the other.
- **Dropped files (§4 H, decision 14)** use a small native handler of ours, not
  `super_drag_and_drop`.
- **Decision number:** D-411. It was D-408 while it was being built; main took D-407 to D-410 the
  same day, so it was renumbered before the pull request.

### 11.3 Not built

- **Read aloud and the file preview** keep their layouts in the laptop pose.
- **Right-to-left:** the list pane is always on the left. Dialogs, sheets and pages outside the
  shell already follow the reading direction.
- **Duo screenshots for the stores, and the line on casama.ai** (decisions 9 and 10): they need
  the real screens on a simulator or a device first.
- **The Live Activity on both screens** was not looked at.
- **An Android foldable emulator** was not run; Android is covered by tests that feed the app the
  display features Android reports.

### 11.4 Checked, and not

**By tests** (`flutter test`): every route in all seven windows of §2.2 with no overflow or error;
the strip on both sides; two panes flat and folded; open and close with a draft in the composer;
the untouched chat returning to the list; sheets, dialogs and toasts in every pose; the
trackpad's moves, clicks and scrolling; the call screen in laptop, book and tent; pages outside
the shell; an Android foldable's window.

**On the iPhone Duo simulator** (iOS 27.2, a debug build, signed out, so the welcome page only).
The app was installed and launched with `xcrun simctl`, and the simulator was opened, folded and
rotated by scripting the buttons of Xcode's Device Hub. What the app's own log said in each pose:

| Pose | Window | Insets | Hinge | Fold | What iOS covers |
|---|---|---|---|---|---|
| Closed | 466 × 678 | right 84, bottom 34 | closed, 0° | none | The camera, 37 × 37 at (399.7, 29.3), and the top 174 points of the strip |
| Open, wide | 951 × 669 | right 84, bottom 34 | open, 180° | 455.5 to 495.5, not dividing | The top 124 points of the strip |
| Book | 951 × 669 | right 84, bottom 34 | partly open, 128.6° | the same band, dividing | The same |
| Open, tall | 669 × 951 | top 82, bottom 34 | open, 180° | y 455.5 to 495.5, not dividing | The top right corner, 144 × 82 |
| Laptop | 669 × 951 | top 82, bottom 34 | partly open, 128.6° | the same band, dividing | The same |
| Tent (closed while rotated) | 678 × 466 | right 84, bottom 34 | closed | none | The camera and the **bottom** 82 points of the strip |

What that settled:

- The [3P] sizes, insets and the 40-point band of §2 are right.
- **iOS reports its part of the strip as a covered region**, so the app reads where its own part
  starts and ends instead of assuming it. In the tent pose that region is at the bottom of the
  strip, which the first version did not expect; `FoldInfo` now has `stripTop` and `stripBottom`
  from those regions.
- `UIStatusBarManager.statusBarFrame` is a 2-point sliver across the top and says nothing.
  `UIWindowScene.isFullScreen` read false in every pose. Nothing depends on either.
- `verticalBarEdge` reaches a plain view: trailing on the outer screen and the inner screen held
  wide, unspecified held tall.
- The fold's region turned active after the hinge said partly open (two log lines apart), as
  Flutter's reviewers saw. The app's rule (both must agree) handled it.
- The welcome page was where §4 says: clear of the strip closed and open; on the right half with
  Casama's mark on the left in the book pose; on the lower half in the laptop pose. In the laptop
  pose its floating mascots crowd the half-height page and one sits behind the button.

**Signed in, on the simulator, closed pose only.** `client/integration_test/duo_tour_test.dart`
runs the real app on the device with sample data and walks through Chats, a chat, the Library,
Tasks, Settings, the Folding screen page, the live view and a call. Its screenshots showed the
strip as designed: iOS's camera, clock and battery at the top, the page's buttons from 182 points
down, the tabs and the Apps button at the bottom. They also showed two things, both fixed:

- iOS centers its strip items 36 points from the strip's inner edge, not in the middle of its 84
  points. Ours sat 6 points off to the right; the strip now keeps 12 points off the screen's edge
  (`FoldInfo.stripOuterMargin`).
- The live view's "Live" chip was as wide as the strip. In the strip it is the dot alone.

**Not checked:**

- **On a device.** Nobody has held it on an iPhone Duo.
- **The signed-in app on the inner screen of the simulator:** the two panes, the trackpad, a call
  across the fold. After its first session Device Hub stopped showing a window to script, so the
  tour ran in the closed pose only. Those layouts are covered by tests that put the app in the
  same windows, with the same insets and fold, that the simulator reported.
- **Split View, and the tent pose rotated the other way.**
- **The keyboard staying up across a pose change** (flutter/flutter #193096) and the black frame
  between screens.
- **The hinge-driven motion.** `hingeMotionProvider` is off.

Device Hub quit once while it was being scripted (Rotate Right with the device partly open), and
took the booted simulators down with it. Rotating first and folding second worked. Later it ran
without a window and had to be force-quit.

### 11.5 Decided for Oliver, and what is left

On 2026-11-19 Oliver answered the three open points with "You decide all for me":

- **Two panes stay on for every window from 840 to 1099 points** (decision 1 as proposed). A
  13-inch iPad held upright and a 900-point window were rendered and looked right: the rail, the
  list at 360 points, the page beside it.
- **It lands on main through a pull request**, merged when CI is green. A pull request rather
  than a merge in the main checkout, which holds other sessions' uncommitted work.
- **No app builds for the stores and no deploys.** The next regular build carries it. Store
  uploads and production deploys stay Oliver's to ask for.

Left:

1. Look at the inner screen signed in:
   `flutter test integration_test/duo_tour_test.dart -d <device>` on the "Casama Duo" simulator
   (or a device), with Device Hub open to put it in each pose the tour asks for. Settings →
   Folding screen has the numbers; debug builds print them as `fold:` and `casama/fold:` lines.
2. If the buttons in the strip sit over the clock, or too far from it: the app takes that from
   the regions iOS reports (`FoldInfo.resolve`), with 8 points of air.
3. Store builds and deploys, when wanted.

## Sources

Apple:

- Designing for iPhone Duo (HIG): https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo
- Preparing your app for iPhone Duo: https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo
- Tech Talks: Prepare your app for iPhone Duo https://developer.apple.com/videos/play/tech-talks/111461/ ·
  Raise the bar https://developer.apple.com/videos/play/tech-talks/111462/ ·
  Strike a pose with adaptive layouts https://developer.apple.com/videos/play/tech-talks/111463/ ·
  Leverage multiple displays and scenes https://developer.apple.com/videos/play/tech-talks/111464/
- iPhone Duo Group Lab summary: https://developer.apple.com/forums/thread/847644
- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/
- On this Mac: `UIHinge.h`, `UIHingeInteraction.h`, `UIViewReservedRegion.h`, `UIVerticalBarEdge.h`,
  `UISceneAccessory.h`, `UIView.h` in `iPhoneOS27.2.sdk`; `iPhone Duo.simdevicetype`
  (`capabilities.plist`).

Flutter:

- Fold on iOS, proposal and pull request: https://github.com/flutter/flutter/issues/192515 ·
  https://github.com/flutter/flutter/pull/193025
- Keyboard closes on a pose change: https://github.com/flutter/flutter/issues/193096
- Flutter 3.50 on this Mac (`ab2912035e`), which includes #195690.

Third-party measurements and write-ups:

- https://somniosoftware.com/blog/iphone-duo-and-flutter-what-the-foldable-iphone-changes
- https://leancode.co/blog/prepare-your-flutter-app-for-iphone-duo
- https://verygood.ventures/blog/iphone-duo-is-your-app-ready/
- https://pub.dev/packages/foldable · https://github.com/Geekles007/duo_display
- Hardware: https://www.gsmarena.com/apple_iphone_duo_fold-13804.php ·
  https://www.macrumors.com/roundup/iphone-duo/
