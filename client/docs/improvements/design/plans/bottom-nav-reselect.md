# Fix: Tapping the tab you're already on does nothing instead of scrolling back to the top

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/bottom-nav-reselect
- **Needs new dependency**: none

## Why

Scroll down your Chats, Inbox or Tasks on a phone and tap that same tab again: nothing happens. In
iOS and Android apps, tapping the current tab scrolls its page back to the top; both Apple's and
Google's guidelines spec it, so people do it from muscle memory and expect Casama to follow.

## Where

1. The tab tap handler, `lib/features/home/home_shell.dart:146-147`. Every place picker calls it: the phone's
   floating tab bar, the tablet rail (`NavigationRail.onDestinationSelected`) and the desktop sidebar. It always
   navigates, so tapping the current tab only re-opens the same path and has no reselect branch.
   ```dart
   // lib/features/home/home_shell.dart:146-147 — current
       final dests = _destinations(context);
       void go(int i) => context.go(dests[i].path);
   ```
   The phone tab bar does call back for the tab that's already selected (no guard), so the handler above
   is the one place to add the reselect:
   ```dart
   // lib/ui/floating_tab_chrome.dart:165-168 — current (no change needed)
                       onTap: () {
                         HapticFeedback.selectionClick();
                         onSelected(i);
                       },
   ```
2. The Chats tab page, `lib/features/bots/bots_screen.dart` (`BotsScreen.build`), whose list has no controller the
   shell can reach:
   ```dart
   // lib/features/bots/bots_screen.dart:242-244 — current
       return Scaffold(
         appBar: ShellHeader(
           title: context.l10n.navChats,
   ```
   ```dart
   // lib/features/bots/bots_screen.dart:254-257 — current
         body: const BotsList(),
       );
     }
   }
   ```
3. The Inbox tab page, `lib/features/inbox/inbox_screen.dart` (`_InboxScreenState.build`). Its body is either the
   feed list or, with the Pages filter, `PagesList`:
   ```dart
   // lib/features/inbox/inbox_screen.dart:67-69 — current
       return Scaffold(
         appBar: ShellHeader(
           title: l10n.inbox,
   ```
   ```dart
   // lib/features/inbox/inbox_screen.dart:95-97 — current
         body: _filter == InboxFilter.pages ? const PagesList() : _InboxFeed(filter: _filter),
       );
     }
   ```
4. The Tasks tab page, `lib/features/board/board_screen.dart` (`_BoardScreenState.build`), built on `SubPage`
   (which makes the `Scaffold`):
   ```dart
   // lib/features/board/board_screen.dart:118-119 — current
       return SubPage(
         title: l10n.navTasks,
   ```
   ```dart
   // lib/features/board/board_screen.dart:200-205 — current (end of build)
         ),
       );
     }
   }

   /// The project filter in the header: all projects or one, and the way to manage them.
   ```

## The fix

The article's fix: keep one `ScrollController` per tab, and when the tapped tab equals the current
one, animate that tab's list to the top (300 ms, `Curves.easeOutCubic`) instead of navigating. The
article's second step (focus the page's search field when the list is already at the top) doesn't
apply here: none of the three tab pages has a text field (search lives in its own sheet behind the
round button), so don't add it.

How it's wired in this app: the controllers live in a new `TabReselect` class (app lifetime, as the
article says: never dispose them). Each tab page wraps its `Scaffold` in a
`PrimaryScrollController(controller: TabReselect.<tab>, ...)` instead of passing `controller:` to a
specific list. On phones, Flutter hands that controller to whichever vertical list the page is showing
(the Chats list, the Inbox feed, the Inbox Pages list, the Tasks list, or an empty state), so no list
code changes. Because the controller sits above the `Scaffold`, the iOS status-bar tap keeps
scrolling these pages to the top too (a custom controller passed straight to a list would break that).

Reduced motion: use `AppMotion.of(context, ...)`; when it returns `Duration.zero`, jump instead of
animating (Flutter doesn't allow a zero-length scroll animation).

The reselect branch fires only when the tapped tab's path equals the current location exactly
(`/bots`, `/inbox`, `/tasks`). From a page under a tab (a chat, Projects, Pages) the tap still navigates,
as today. On desktop computers Flutter doesn't hand the controller down automatically, so there the tap
is a quiet no-op, exactly as now; the tab bar is a phone feature.

New file `lib/ui/tab_reselect.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Scroll controllers for the three tab pages (Chats, Inbox, Tasks), so tapping the tab you're already
/// on scrolls its list back to the top, as on iOS and Android. Each tab page wraps its Scaffold in a
/// PrimaryScrollController with its controller here: on phones whichever list the page shows picks it
/// up by itself, and the iOS status-bar tap keeps working. They live as long as the app, like the tab
/// bar, so they are never disposed.
abstract final class TabReselect {
  static final ScrollController chats = ScrollController();
  static final ScrollController inbox = ScrollController();
  static final ScrollController tasks = ScrollController();

  /// The controller of the tab at [index] in HomeShell's places: 0 Chats, 1 Inbox, 2 Tasks.
  static ScrollController of(int index) => switch (index) {
    0 => chats,
    1 => inbox,
    _ => tasks,
  };

  /// Scrolls the tab at [index] back to the top. Does nothing when its list isn't on screen.
  static void scrollToTop(BuildContext context, int index) {
    final scroller = of(index);
    if (!scroller.hasClients) return;
    final duration = AppMotion.of(context, const Duration(milliseconds: 300));
    // Reduced motion: jump instead (a scroll animation can't be zero-length).
    if (duration == Duration.zero) {
      scroller.jumpTo(0);
    } else {
      scroller.animateTo(0, duration: duration, curve: Curves.easeOutCubic);
    }
  }
}
```

Target code for the handler in `HomeShell.build`:

```dart
    final dests = _destinations(context);
    void go(int i) {
      // The tab you're already on: back to the top of its list, as on iOS and Android.
      if (location == dests[i].path) {
        TabReselect.scrollToTop(context, i);
        return;
      }
      context.go(dests[i].path);
    }
```

## Steps

Edit files by hand. Never run `dart format` on an existing file or folder. Keep every existing `Key`.

1. **Create `lib/ui/tab_reselect.dart`** with exactly the code under "The fix". Then run
   `dart format -l 200 lib/ui/tab_reselect.dart` (this new file only).

2. **`lib/features/home/home_shell.dart`, the import.** Replace `import '../../ui/floating_tab_chrome.dart';` with:
   ```dart
   import '../../ui/floating_tab_chrome.dart';
   import '../../ui/tab_reselect.dart';
   ```

3. **`lib/features/home/home_shell.dart`, the handler.** Replace the line
   `    void go(int i) => context.go(dests[i].path);` with:
   ```dart
       void go(int i) {
         // The tab you're already on: back to the top of its list, as on iOS and Android.
         if (location == dests[i].path) {
           TabReselect.scrollToTop(context, i);
           return;
         }
         context.go(dests[i].path);
       }
   ```

4. **`lib/features/bots/bots_screen.dart`.** Replace `import '../../ui/page.dart';` with:
   ```dart
   import '../../ui/page.dart';
   import '../../ui/tab_reselect.dart';
   ```
   Replace the three lines from Where 2 (`    return Scaffold(` … `title: context.l10n.navChats,`) with:
   ```dart
       // Tapping Chats again scrolls this list to the top (TabReselect); so does the iOS status bar.
       return PrimaryScrollController(
         controller: TabReselect.chats,
         child: Scaffold(
         appBar: ShellHeader(
           title: context.l10n.navChats,
   ```
   Replace the four lines from Where 2 (`      body: const BotsList(),` … `}`) with:
   ```dart
         body: const BotsList(),
       ),
       );
     }
   }
   ```

5. **`lib/features/inbox/inbox_screen.dart`.** Replace `import '../../ui/page.dart';` with:
   ```dart
   import '../../ui/page.dart';
   import '../../ui/tab_reselect.dart';
   ```
   Replace the three lines from Where 3 (`    return Scaffold(` … `title: l10n.inbox,`) with:
   ```dart
       // Tapping Inbox again scrolls the feed (or Pages) to the top (TabReselect); so does the iOS status bar.
       return PrimaryScrollController(
         controller: TabReselect.inbox,
         child: Scaffold(
         appBar: ShellHeader(
           title: l10n.inbox,
   ```
   Replace the three lines from Where 3 (`      body: _filter == ...` … `  }`) with:
   ```dart
         body: _filter == InboxFilter.pages ? const PagesList() : _InboxFeed(filter: _filter),
       ),
       );
     }
   ```

6. **`lib/features/board/board_screen.dart`.** Replace `import '../../ui/page.dart';` with:
   ```dart
   import '../../ui/page.dart';
   import '../../ui/tab_reselect.dart';
   ```
   Replace the two lines from Where 4 (`    return SubPage(` and `      title: l10n.navTasks,`) with:
   ```dart
       // Tapping Tasks again scrolls the tickets to the top (TabReselect); so does the iOS status bar.
       return PrimaryScrollController(
         controller: TabReselect.tasks,
         child: SubPage(
         title: l10n.navTasks,
   ```
   Replace the end of `build` from Where 4 with (one more `),` closes `SubPage`):
   ```dart
         ),
         ),
       );
     }
   }

   /// The project filter in the header: all projects or one, and the way to manage them.
   ```

7. **Add a widget test.** Create `test/tab_reselect_test.dart` with:
   ```dart
   // Tapping the tab you're already on scrolls its list back to the top, as on iOS and Android.
   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:go_router/go_router.dart';
   import 'package:casama_app/app.dart';
   import 'package:casama_app/core/providers.dart';
   import 'package:casama_app/ui/floating_tab_chrome.dart';
   import 'package:casama_app/ui/tab_reselect.dart';

   import 'app_test.dart' show setSize;
   import 'fake_backend.dart';

   Widget _longTab({bool reduceMotion = false}) => MaterialApp(
     home: Builder(
       builder: (context) => MediaQuery(
         data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
         child: PrimaryScrollController(
           controller: TabReselect.inbox,
           child: Scaffold(
             body: ListView(children: [for (var i = 0; i < 100; i++) SizedBox(height: 80, child: Text('row $i'))]),
           ),
         ),
       ),
     ),
   );

   void main() {
     testWidgets('the tab list animates back to the top', (tester) async {
       await tester.pumpWidget(_longTab());
       TabReselect.inbox.jumpTo(2000);
       await tester.pump();
       TabReselect.scrollToTop(tester.element(find.byType(ListView)), 1);
       await tester.pump();
       expect(TabReselect.inbox.offset, greaterThan(0), reason: 'it animates rather than jumps');
       await tester.pumpAndSettle();
       expect(TabReselect.inbox.offset, 0);
     });

     testWidgets('with reduced motion it jumps straight to the top', (tester) async {
       await tester.pumpWidget(_longTab(reduceMotion: true));
       TabReselect.inbox.jumpTo(2000);
       await tester.pump();
       TabReselect.scrollToTop(tester.element(find.byType(ListView)), 1);
       expect(TabReselect.inbox.offset, 0);
     });

     testWidgets('tapping the current tab stays on it; the tab pages use the tab controllers', (tester) async {
       await setSize(tester, const Size(400, 860));
       await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(FakeBackend())], child: const CasamaApp()));
       await tester.pumpAndSettle();
       expect(TabReselect.chats.hasClients, isTrue, reason: 'the Chats list picks up the tab controller');

       final bar = find.byType(FloatingTabChrome);
       await tester.tap(find.descendant(of: bar, matching: find.text('Chats')));
       await tester.pumpAndSettle();
       expect(GoRouter.of(tester.element(bar)).state.uri.path, '/bots');
       expect(tester.takeException(), isNull);

       await tester.tap(find.descendant(of: bar, matching: find.text('Inbox')));
       await tester.pumpAndSettle();
       expect(TabReselect.inbox.hasClients, isTrue, reason: 'the Inbox list picks up the tab controller');

       await tester.tap(find.descendant(of: bar, matching: find.text('Tasks')));
       await tester.pumpAndSettle();
       expect(TabReselect.tasks.hasClients, isTrue, reason: 'the Tasks list picks up the tab controller');

       await tester.pumpWidget(const SizedBox());
       await tester.pump(const Duration(minutes: 1));
     });
   }
   ```
   Then run `dart format -l 200 test/tab_reselect_test.dart` (this new file only).

8. **Run the tests** from `client/`:
   `flutter test test/tab_reselect_test.dart test/navigation_test.dart test/phone_layout_test.dart test/inbox_feed_test.dart test/tasks_phone_test.dart test/board_test.dart test/responsive_test.dart test/sidebar_test.dart test/app_test.dart`

## Check it

Run from `client/`:
`dart analyze lib/ui/tab_reselect.dart lib/features/home/home_shell.dart lib/features/bots/bots_screen.dart lib/features/inbox/inbox_screen.dart lib/features/board/board_screen.dart test/tab_reselect_test.dart`
reports no errors and no warnings. Existing `info` lines (for example `curly_braces_in_flow_control_structures`) were there before this change and are fine; the command exits with code 0.

- `grep -c "void go(int i) => context.go" lib/features/home/home_shell.dart` → 0
- `grep -c "TabReselect.scrollToTop(context, i);" lib/features/home/home_shell.dart` → 1
- `grep -c "if (location == dests\[i\].path)" lib/features/home/home_shell.dart` → 1
- `grep -c "controller: TabReselect.chats," lib/features/bots/bots_screen.dart` → 1
- `grep -c "controller: TabReselect.inbox," lib/features/inbox/inbox_screen.dart` → 1
- `grep -c "controller: TabReselect.tasks," lib/features/board/board_screen.dart` → 1
- `grep -c "import '../../ui/tab_reselect.dart';" <file>` → 1 for each of `lib/features/home/home_shell.dart`,
  `lib/features/bots/bots_screen.dart`, `lib/features/inbox/inbox_screen.dart`, `lib/features/board/board_screen.dart`
- The tests from step 8 pass.

## Don't touch

- `lib/ui/floating_tab_chrome.dart`, `_Rail` and `_Sidebar` in `home_shell.dart`: they already call the handler
  for every tap, including the current tab.
- `BotsList`, `_InboxFeed`, `PagesList`, `PageColumn`, `_GroupedList` and every list inside the tab pages: don't
  pass `controller:` to them; the `PrimaryScrollController` hands it down.
- Don't add a "focus search when already at the top" step: there is no search field on these pages.
- Don't dispose the `TabReselect` controllers anywhere.
- Don't change `automaticallyInheritForPlatforms` on these wrappers (leave the default): the default is what lets
  the page's list pick up the controller.
- Bottom padding, scrollbars and `keyboardDismissBehavior` are other fixes. If one already landed and changed lines
  inside these pages (for example `primary: false` on the tablet board columns), keep it.
- No new dependencies. No refactors, renames or cleanups beyond the fix.
- No git commands (the tree is shared; others commit).

## STOP if

- The text you are told to replace in a step isn't in the file. Lines right next to it may differ because another
  fix landed; that's fine as long as the exact text you replace is there.
- `lib/ui/glass/` exists and `HomeShell` no longer uses `FloatingTabChrome` (a glass tab bar replaced it). Check that
  the new tab bar calls `onDestinationSelected` for the tab that's already selected; if it ignores taps on the
  selected tab, report it instead of changing the glass adapter.
- One of the three tab pages already wraps its `Scaffold`/`SubPage` in a `PrimaryScrollController`, or its list
  already has its own `ScrollController`.
- The fix seems to require touching something in "Don't touch".
- A test fails because of this change, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open
to see it. For example: on a phone, scroll down the Inbox and tap the Inbox tab again; the feed now
glides back to the top (it jumps there with Reduce Motion on). The same works for Chats and Tasks, and
on the tablet rail.
