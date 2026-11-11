# Fix: Tapping the status bar on iPhone doesn't scroll a chat back to the top

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/statusbar-tap-scroll
- **Needs new dependency**: none

## Why

On iOS, tapping the status bar (the clock at the top) scrolls the page to the top. People use it
without thinking, especially in long chats where they want the start of the conversation. Flutter's
`Scaffold` does this on its own, but only for lists that use the page's shared scroll controller. The
chat thread has its own `ScrollController` (it needs one to follow new messages and jump to the latest),
so in Casama the status-bar tap silently does nothing inside a chat.

## Where

The app has exactly one custom `ScrollController` (`grep -rn "ScrollController(" lib` finds only this one),
and it drives a vertical list inside a `Scaffold` with no `PrimaryScrollController` providing it:

1. `lib/features/chat/chat_screen.dart:93`, the controller, owned by `_ChatScreenState` (disposed in `dispose()`):
   ```dart
   // lib/features/chat/chat_screen.dart:93 — current
     final _scroll = ScrollController();
   ```
2. `lib/features/chat/chat_screen.dart:495-496`, the chat thread that uses it:
   ```dart
   // lib/features/chat/chat_screen.dart:495-496 — current
                     return ListView.builder(
                       controller: _scroll,
   ```
3. `lib/features/chat/chat_screen.dart:417-419`, the `Scaffold` that `build` returns, with no `PrimaryScrollController` above it:
   ```dart
   // lib/features/chat/chat_screen.dart:417-419 — current
       return Scaffold(
         appBar: ShellHeader(
           title: name,
   ```
4. `lib/features/chat/chat_screen.dart:657-661`, the end of that `Scaffold` and of `build`:
   ```dart
   // lib/features/chat/chat_screen.dart:657-661 — current
         ),
       );
     }

     /// File links and attachments open from the bot's computer; on desktop and the web, files
   ```

The same screen is used for group chats, the welcome chat and every bot chat, so one change covers them all.

## The fix

The article's fix: wrap the `Scaffold` in a `PrimaryScrollController` that provides the screen's own
controller, and keep passing that controller to the scrollable. The `Scaffold` looks the controller up
from above itself when the status bar is tapped, which is why the wrapper goes around the `Scaffold`
and not inside it.

One adaptation for this screen: `automaticallyInheritForPlatforms: const <TargetPlatform>{}`. By default,
on phones, every vertical list below a `PrimaryScrollController` that has no controller of its own picks
it up automatically. Chat messages contain small scrolling code boxes (`CodePanel`), and they would then
attach to `_scroll` as well; the screen reads `_scroll.position`, which throws once more than one list is
attached. The empty set turns that automatic pickup off. The `Scaffold` still finds the controller for the
status-bar tap, because that lookup doesn't depend on the set.

Target code for the start of the return in `build`:

```dart
    // The thread has its own ScrollController, so hand it to the Scaffold as well: tapping the status
    // bar on iOS then scrolls the thread to the top. Nothing else on the screen picks it up by itself
    // (the empty set), so code boxes inside messages keep their own scrolling.
    return PrimaryScrollController(
      controller: _scroll,
      automaticallyInheritForPlatforms: const <TargetPlatform>{},
      child: Scaffold(
      appBar: ShellHeader(
        title: name,
```

and for its end (one extra `),` closes the `Scaffold`; the last `);` now closes the `PrimaryScrollController`):

```dart
      ),
      ),
    );
  }

  /// File links and attachments open from the bot's computer; on desktop and the web, files
```

The inner lines keep their current indentation; don't reformat them.

## Steps

Edit the file by hand. Never run `dart format` on an existing file or folder. Keep every existing `Key`.

1. **`lib/features/chat/chat_screen.dart`, the start.** Find this exact text (Where 3):
   ```dart
       return Scaffold(
         appBar: ShellHeader(
           title: name,
   ```
   and replace it with the "start" target code under "The fix" (the comment, `PrimaryScrollController(`,
   `controller: _scroll,`, `automaticallyInheritForPlatforms: const <TargetPlatform>{},`, then
   `child: Scaffold(` followed by the unchanged `appBar: ShellHeader(` and `title: name,` lines).

2. **`lib/features/chat/chat_screen.dart`, the end.** Find this exact text (Where 4):
   ```dart
         ),
       );
     }

     /// File links and attachments open from the bot's computer; on desktop and the web, files
   ```
   and replace it with:
   ```dart
         ),
         ),
       );
     }

     /// File links and attachments open from the bot's computer; on desktop and the web, files
   ```

3. Leave `controller: _scroll,` on the `ListView.builder` (Where 2) and the `_scroll` field (Where 1)
   exactly as they are.

4. **Add a widget test.** Create `test/statusbar_tap_test.dart` with:
   ```dart
   // Tapping the iOS status bar scrolls a chat back to its first message, though the thread has its
   // own ScrollController.
   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/core/backend.dart';
   import 'package:casama_app/features/chat/chat_screen.dart';

   import 'app_test.dart' show harness, setSize;
   import 'fake_backend.dart';

   FakeBackend _longChat() => FakeBackend()
     ..storedMessages = [
       for (var i = 0; i < 30; i++)
         ChatMessageView(id: 'm$i', role: i.isEven ? 'user' : 'assistant', text: 'Message number $i', createdAt: DateTime(2026, 11, 1, 0, i)),
     ];

   void main() {
     testWidgets('the chat hands its own scroll controller to the Scaffold', (tester) async {
       await setSize(tester, const Size(390, 844));
       await tester.pumpWidget(harness(_longChat(), const ChatScreen(botId: botId, conversationId: convId)));
       await tester.pumpAndSettle();
       final thread = tester.widget<ListView>(find.byType(ListView).first);
       expect(thread.controller, isNotNull);
       expect(PrimaryScrollController.maybeOf(tester.element(find.byType(Scaffold).first)), same(thread.controller));
     });

     testWidgets('tapping the status bar scrolls the chat to its first message', (tester) async {
       await setSize(tester, const Size(390, 844));
       tester.view.padding = const FakeViewPadding(top: 47);
       await tester.pumpWidget(harness(_longChat(), const ChatScreen(botId: botId, conversationId: convId)));
       await tester.pumpAndSettle();
       final thread = tester.state<ScrollableState>(find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
       expect(thread.position.pixels, greaterThan(0), reason: 'a chat opens at its latest message');

       tester.simulateStatusBarTap();
       await tester.pumpAndSettle();
       expect(thread.position.pixels, 0);
     }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
   }
   ```
   Then run `dart format -l 200 test/statusbar_tap_test.dart` (this new file only).

5. **Run the tests** from `client/`:
   `flutter test test/statusbar_tap_test.dart test/chat_keyboard_test.dart test/simple_chat_test.dart test/group_chats_test.dart test/phone_layout_test.dart test/app_test.dart`

## Check it

Run from `client/`:
`dart analyze lib/features/chat/chat_screen.dart test/statusbar_tap_test.dart` reports no errors and no warnings. Existing `info` lines (for example `curly_braces_in_flow_control_structures`) were there before this change and are fine; the command exits with code 0.

- `grep -c "return PrimaryScrollController(" lib/features/chat/chat_screen.dart` → 1
- `grep -c "automaticallyInheritForPlatforms: const <TargetPlatform>{}," lib/features/chat/chat_screen.dart` → 1
- `grep -c "      child: Scaffold(" lib/features/chat/chat_screen.dart` → 1
- `grep -c "controller: _scroll," lib/features/chat/chat_screen.dart` → 2 (the new wrapper and the thread)
- The tests from step 5 pass.

## Don't touch

- The `_scroll` field, its listener (`_onScroll`), `_toEnd`, `_jumpToLatest`, `_onThreadMetrics` and `dispose()`:
  the controller keeps doing everything it does today.
- `keyboardDismissBehavior` on the thread and on `_EmptyThread`: another fix may change those lines; leave
  whatever is there.
- Other screens: they use no custom `ScrollController`, so Flutter already handles the status-bar tap there.
- Don't drop the empty `automaticallyInheritForPlatforms` set, and don't use the default: see "The fix".
- No new dependencies. No refactors, renames or cleanups beyond the fix.
- No git commands (the tree is shared; others commit).

## STOP if

- The text you are told to replace in step 1 or step 2 isn't in the file (lines around it may differ
  because another fix landed; that's fine as long as the exact text you replace is there).
- `chat_screen.dart` already contains `PrimaryScrollController`, or `build` no longer returns the `Scaffold`
  directly.
- `grep -rn "ScrollController(" lib --include='*.dart'` (from `client/`) now finds a second custom controller
  that drives a vertical list in a `Scaffold`. Report it instead of fixing it here.
- In the second test, `thread.position.pixels` is 0 before the tap (the chat isn't long enough to scroll). Raise
  the message count in `_longChat` from 30 to 60 once; if it is still 0, stop.
- The fix seems to require touching something in "Don't touch".
- A test fails because of this change, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open
to see it. For example: on an iPhone, open a long chat, then tap the clock in the status bar; the chat
now glides back to its first message, as Messages and WhatsApp do.
