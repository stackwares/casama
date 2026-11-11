# Fix: Tapping the iOS status bar does nothing in a chat

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/statusbar-tap-scroll
- **Needs new dependency**: none

## Why

On iOS, tapping the status bar scrolls the page back to its start, and people expect it. Flutter's `Scaffold` does it for free, but only through the `PrimaryScrollController`. The chat screen's message list uses its own `ScrollController`, so a status-bar tap in a chat silently does nothing.

## Where

All paths are relative to `client/`. A full sweep of `lib/` for `ScrollController(`:
- `lib/ui/tab_reselect.dart:11–13` (`chats`, `inbox`, `tasks`) are already provided through `PrimaryScrollController` at `lib/features/bots/bots_screen.dart:330`, `lib/features/inbox/inbox_screen.dart:74` and `lib/features/board/board_screen.dart:155`.
- One controller isn't:

```dart
// lib/features/chat/chat_screen.dart:97 — current
  final _scroll = ScrollController();
```

```dart
// lib/features/chat/chat_screen.dart:458 — current
    return Wallpaper(
      force: true,
      child: Scaffold(
        appBar: ShellHeader(
```

```dart
// lib/features/chat/chat_screen.dart:540 — current (the list it drives)
                    child: ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      shrinkWrap: true,
```

```dart
// lib/features/chat/chat_screen.dart:703 — current (end of build's return)
            );
          },
        ),
      ),
      ),
    );
```

## The fix

The article: with a custom `ScrollController`, wrap the `Scaffold` in a `PrimaryScrollController` that provides that same controller, and keep passing it to the scrollable. The `Scaffold`'s status-bar tap then animates that controller to offset 0.

**What the tap does here (decided, read this):** the chat list is `reverse: true`, so offset 0 is the **bottom**, the newest messages. A status-bar tap will therefore glide back to the latest message. That's the same place the chat's own "jump to latest" button goes (`_scroll.animateTo(0, ...)` at line 328), so the gesture is consistent within this screen. It's the scroll view's start, which is what the article's fix produces. Don't add a custom handler that goes to the oldest message: in a reversed, paginated chat that would mean jumping to whatever history happens to be loaded.

**Required guard:** set `automaticallyInheritForPlatforms: const <TargetPlatform>{}` on the wrapper.
- By default, on iOS and Android, every vertical scroll view under a `PrimaryScrollController` that has no controller of its own adopts it. That includes lists inside bot UI cards in messages, and the empty-thread view.
- Several scroll views on one controller make `_scroll.position` throw, and the screen reads `_scroll.position` at lines 263, 280 and 303.
- With the empty set, only the message list (which passes `controller: _scroll` explicitly) is attached. The `Scaffold` still finds the controller for the status-bar tap.

```dart
// target
    return Wallpaper(
      force: true,
      // The iOS status-bar tap scrolls this list back to its start; reversed, that's the latest
      // message. Nothing else inherits it, so lists inside messages keep their own scrolling.
      child: PrimaryScrollController(
        controller: _scroll,
        automaticallyInheritForPlatforms: const <TargetPlatform>{},
        child: Scaffold(
          appBar: ShellHeader(
            // unchanged
          ),
          // unchanged
        ),
      ),
    );
```

Keep `controller: _scroll` on the `ListView.builder` at line 541, as the article says to pass it to the scrollable as well. Exemplar of the wrapper in this repo: `lib/features/bots/bots_screen.dart:330`.

## Steps

1. In `lib/features/chat/chat_screen.dart` at line 460, replace `      child: Scaffold(` with:
   ```dart
         // The iOS status-bar tap scrolls this list back to its start; reversed, that's the latest
         // message. Nothing else inherits it, so lists inside messages keep their own scrolling.
         child: PrimaryScrollController(
           controller: _scroll,
           automaticallyInheritForPlatforms: const <TargetPlatform>{},
           child: Scaffold(
   ```
2. At the end of the same `return` (line 708, the `    );` that closes `Wallpaper`), add one closing line `      ),` directly before it, closing the new `PrimaryScrollController`.
3. Leave the Scaffold's inner indentation as it is (this existing file must not be re-formatted). Only the lines you add need sensible indentation. Don't run `dart format` on it.
4. This file has other uncommitted changes in the working tree from the developer. Don't revert, stage or commit them.

## Check it

- From `client/`, `flutter analyze lib/features/chat/chat_screen.dart` reports no issues.
- `grep -c "PrimaryScrollController(" lib/features/chat/chat_screen.dart` → 1.
- `grep -c "automaticallyInheritForPlatforms: const <TargetPlatform>{}" lib/features/chat/chat_screen.dart` → 1.
- `flutter test test/simple_chat_test.dart test/chat_keyboard_test.dart test/bot_ui_test.dart test/branches_test.dart test/app_test.dart` passes. These would catch "ScrollController attached to multiple scroll views".

## Don't touch

- `lib/ui/tab_reselect.dart` and the bots, inbox and board `PrimaryScrollController`s. They're already correct.
- The list's `reverse: true`, the jump-to-latest button, or any scroll logic in `_onScroll`, `_scrollToFocus` or `_followIfAtBottom`.
- Other scroll views inside the chat (the attachments row at line 689, the empty thread at 1201, the lists at 1419 and 1536).
- No new dependencies.
- No refactors, renames or cleanups beyond the fix.

## Repo rules

- Never `git add -A` or `git add .`. Stage by path only, and only if asked. **Don't commit**; the developer commits.
- Only run `dart format` on new files.

## STOP if

- The code at any location doesn't match the excerpts (the codebase moved on).
- A test fails with "ScrollController attached to multiple scroll views". Report it; don't remove the guard.
- The developer wants the tap to go to the oldest message instead. That needs a custom status-bar handler and a decision about loading history, which this plan doesn't cover.
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, that on iOS, tapping the status bar inside a chat now glides back to the latest message, as the jump-to-latest button does. Point them to any long chat on an iPhone or the iOS Simulator.
