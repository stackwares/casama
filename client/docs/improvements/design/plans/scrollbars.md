# Fix: Long lists on phones show no scrollbar, so you can't tell where you are or how much is left

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/scrollbars
- **Needs new dependency**: none

## Why

On iPhone and Android, no list in Casama shows a scrollbar: not the chats, the inbox, the tickets,
Settings, the model picker with hundreds of models, search results or a long chat. A scrollbar tells
people where they are in a list and how much is left. Flutter adds one only on desktop (and web in a
desktop browser); on phones it's the app's job. No scrollable in `client/lib` has a `Scrollbar` and
there is no app-wide `scrollBehavior`, so every vertical list on a phone is missing one.

## Where

1. The app root, `lib/app.dart:57-72`. `MaterialApp.router` sets no `scrollBehavior`, so Flutter's default
   (`MaterialScrollBehavior`: scrollbars on desktop only) applies to every screen, sheet and dialog.
   ```dart
   // lib/app.dart:65-66 — current
         supportedLocales: AppLocalizations.supportedLocales,
         debugShowCheckedModeBanner: false,
   ```
   ```dart
   // lib/app.dart:23-26 — current (imports)
   import 'core/router.dart';
   import 'core/theme.dart';
   import 'theme/appearance.dart';
   import 'l10n/generated/app_localizations.dart';
   ```

Four lists also need `primary: false`. On iOS, Flutter hands a page's shared scroll controller (its
`PrimaryScrollController`) to every vertical list on that page that has no controller of its own. That
is harmless today, but once lists get a scrollbar, the iOS scrollbar (which can be dragged) reports an
error whenever its controller drives more than one list. These four lists sit beside or inside another
list on the same page and would share it:

2. The wide-window sidebar's bot list, `lib/features/home/home_shell.dart:406-408` (shares with the Settings
   list or the computer panel beside it on an iPad in landscape).
   ```dart
   // lib/features/home/home_shell.dart:406-408 — current
               Expanded(
                 child: ListView(
                   padding: const EdgeInsets.only(bottom: 12),
   ```
3. Each status column on the tablet Tasks board, `lib/features/board/board_screen.dart:390-393` (five columns
   side by side share one controller).
   ```dart
   // lib/features/board/board_screen.dart:390-393 — current (in _Column)
               Expanded(
                 child: ListView(
                   children: [
                     for (final t in tasks)
   ```
4. `CodePanel`, the small scrolling code box in chat steps and error details,
   `lib/features/chat/widgets/chat_widgets.dart:968-969` (several in one chat share one controller, because
   the chat thread has its own controller and doesn't shield them).
   ```dart
   // lib/features/chat/widgets/chat_widgets.dart:968-969 — current
         child: SingleChildScrollView(
           reverse: reverse,
   ```
5. The "add a voice key" card on the call screen, `lib/features/voice/call_screen.dart:595-597` (sits beside
   the call activity list).
   ```dart
   // lib/features/voice/call_screen.dart:595-597 — current
                                     Flexible(
                                       child: SingleChildScrollView(
                                         child: _NeedsKeyCard(
   ```

## The fix

The article's "Automatic" approach: give `MaterialApp` a `scrollBehavior` whose `buildScrollbar`
wraps scrollables in a `Scrollbar`, so every list in the app gets one at once, including those in
sheets and dialogs. Applied to this codebase, it covers vertical scrollables only (the rule is about
vertical lists; horizontal chip rows and galleries stay without one, as Flutter itself does), and it
gives the `Scrollbar` the scrollable's own controller (`details.controller`) exactly as the article does.

On desktop this is the same scrollbar Flutter already shows, so nothing changes there. On iOS the
`Scrollbar` draws the native thin iOS indicator; on Android the Material one that fades in while you
scroll. The track keeps clear of `MediaQuery` padding, so on phone tab screens it ends above the
floating tab bar.

Per the article, never add a `Scrollbar` widget by hand anywhere once this behavior is in place: a
manual one on top of the automatic one makes both misbehave.

New file `lib/ui/app_scroll_behavior.dart`:

```dart
import 'package:flutter/material.dart';

/// Scrollbars on every vertical list, phones included (Flutter only adds them on desktop), so people
/// see where they are in a list and how much is left. Horizontal rows (chips, galleries) stay without
/// one. Don't also wrap lists in a Scrollbar by hand: two scrollbars on one list fight each other.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    if (axisDirectionToAxis(details.direction) == Axis.horizontal) return child;
    return Scrollbar(controller: details.controller, child: child);
  }
}
```

In `lib/app.dart`, `MaterialApp.router` gets `scrollBehavior: const AppScrollBehavior(),`.

The four lists in Where 2-5 get `primary: false`, so each keeps a controller of its own. (The only thing
they give up is the iOS status-bar tap scrolling them to the top, which they never needed: they're a
sidebar, board columns and small boxes inside other lists.)

## Steps

Edit files by hand. Never run `dart format` on an existing file or folder. Keep every existing `Key`.

1. **Create `lib/ui/app_scroll_behavior.dart`** with exactly the code under "The fix". Then run
   `dart format -l 200 lib/ui/app_scroll_behavior.dart` (this new file only).

2. **`lib/app.dart`, the import.** Replace `import 'core/theme.dart';` with:
   ```dart
   import 'core/theme.dart';
   import 'ui/app_scroll_behavior.dart';
   ```

3. **`lib/app.dart`, the behavior.** Replace the two lines from Where 1 (65-66) with:
   ```dart
         supportedLocales: AppLocalizations.supportedLocales,
         debugShowCheckedModeBanner: false,
         // Scrollbars on vertical lists on every platform, phones included.
         scrollBehavior: const AppScrollBehavior(),
   ```

4. **Sidebar (Where 2).** In `home_shell.dart` replace the three lines with:
   ```dart
               Expanded(
                 child: ListView(
                   primary: false,
                   padding: const EdgeInsets.only(bottom: 12),
   ```

5. **Board columns (Where 3).** In `board_screen.dart` replace the four lines with:
   ```dart
               Expanded(
                 child: ListView(
                   primary: false,
                   children: [
                     for (final t in tasks)
   ```

6. **CodePanel (Where 4).** In `chat_widgets.dart` replace the two lines with:
   ```dart
         child: SingleChildScrollView(
           primary: false,
           reverse: reverse,
   ```

7. **Call screen card (Where 5).** In `call_screen.dart` replace the three lines with:
   ```dart
                                     Flexible(
                                       child: SingleChildScrollView(
                                         primary: false,
                                         child: _NeedsKeyCard(
   ```

8. **Add a widget test.** Create `test/scrollbars_test.dart` with:
   ```dart
   // Vertical lists show a scrollbar on phones too, so people see where they are and how much is left.
   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/app.dart';
   import 'package:casama_app/core/providers.dart';
   import 'package:casama_app/ui/app_scroll_behavior.dart';

   import 'app_test.dart' show setSize;
   import 'fake_backend.dart';

   void main() {
     testWidgets('vertical lists get a scrollbar on phones; horizontal rows do not', (tester) async {
       await tester.pumpWidget(
         MaterialApp(
           scrollBehavior: const AppScrollBehavior(),
           home: Scaffold(
             body: Column(
               children: [
                 SizedBox(
                   height: 60,
                   child: ListView(
                     key: const Key('row'),
                     scrollDirection: Axis.horizontal,
                     children: [for (var i = 0; i < 30; i++) SizedBox(width: 80, child: Text('chip $i'))],
                   ),
                 ),
                 Expanded(
                   child: ListView(
                     key: const Key('list'),
                     children: [for (var i = 0; i < 60; i++) SizedBox(height: 56, child: Text('row $i'))],
                   ),
                 ),
               ],
             ),
           ),
         ),
       );
       expect(find.descendant(of: find.byKey(const Key('list')), matching: find.byType(Scrollbar)), findsOneWidget);
       expect(find.descendant(of: find.byKey(const Key('row')), matching: find.byType(Scrollbar)), findsNothing);

       // Scrolling shows it without errors.
       await tester.drag(find.byKey(const Key('list')), const Offset(0, -300));
       await tester.pumpAndSettle();
       expect(tester.takeException(), isNull);
     }, variant: TargetPlatformVariant.mobile());

     testWidgets('the app uses the scrollbar behavior', (tester) async {
       await setSize(tester, const Size(400, 860));
       await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(FakeBackend())], child: const CasamaApp()));
       await tester.pumpAndSettle();
       expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).scrollBehavior, isA<AppScrollBehavior>());
     });
   }
   ```
   Then run `dart format -l 200 test/scrollbars_test.dart` (this new file only).

9. **Run the tests** from `client/`:
   `flutter test test/scrollbars_test.dart test/phone_layout_test.dart test/navigation_test.dart test/sidebar_test.dart test/responsive_test.dart test/tasks_phone_test.dart test/board_test.dart test/simple_chat_test.dart test/voice_test.dart test/app_test.dart`

## Check it

Run from `client/`:
`dart analyze lib/ui/app_scroll_behavior.dart lib/app.dart lib/features/home/home_shell.dart lib/features/board/board_screen.dart lib/features/chat/widgets/chat_widgets.dart lib/features/voice/call_screen.dart test/scrollbars_test.dart`
reports no errors and no warnings. Existing `info` lines (for example `curly_braces_in_flow_control_structures`) were there before this change and are fine; the command exits with code 0.

- `grep -c "scrollBehavior: const AppScrollBehavior()" lib/app.dart` → 1
- `grep -c "import 'ui/app_scroll_behavior.dart';" lib/app.dart` → 1
- `grep -c "return Scrollbar(controller: details.controller, child: child);" lib/ui/app_scroll_behavior.dart` → 1
- `grep -c "primary: false" lib/features/home/home_shell.dart` → 1
- `grep -c "primary: false" lib/features/board/board_screen.dart` → 1
- `grep -c "primary: false" lib/features/chat/widgets/chat_widgets.dart` → 1
- `grep -c "primary: false" lib/features/voice/call_screen.dart` → 1
- The tests from step 9 pass.

## Don't touch

- `buildOverscrollIndicator`, scroll physics, drag devices: keep the inherited `MaterialScrollBehavior` behavior;
  override only `buildScrollbar`.
- Don't wrap any list in `Scrollbar` (or `CupertinoScrollbar`/`RawScrollbar`) by hand, and don't add
  `ScrollConfiguration` overrides; the app-wide behavior covers everything.
- Don't set `thumbVisibility`, `interactive`, thickness or a `scrollbarTheme`: platform defaults are the
  native look.
- Don't add `primary: false` anywhere except the four places in Where 2-5. The other lists keep inheriting
  their page's controller, which is what makes the iOS status-bar tap scroll them to the top.
- `ScrollController`s, `PrimaryScrollController`s, `keyboardDismissBehavior` and bottom padding are other fixes.
  If one of them already landed and added a line next to a line you replace, keep it.
- No new dependencies. No refactors, renames or cleanups beyond the fix.
- No git commands (the tree is shared; others commit).

## STOP if

- The text you are told to replace in a step isn't in the file. Lines right next to it may differ
  because another fix landed (for example an added `padding:` or `keyboardDismissBehavior:` line); that's
  fine as long as the exact text you replace is there.
- `MaterialApp.router` in `lib/app.dart` already has a `scrollBehavior:`. Report it: the new `buildScrollbar`
  must be merged into that behavior, not stacked on top.
- Any file in `lib/` already uses `Scrollbar(` (the clash the article warns about).
- A test reports "ScrollController attached to more than one ScrollPosition" or "attached to more than one
  ScrollPosition" for a list not listed in Where 2-5. Report which list; don't add `primary: false` on your own.
- The fix seems to require touching something in "Don't touch".
- A test fails because of this change, or a check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open
to see it. For example: on a phone, open New bot and tap the model field, then scroll the model list; a
thin scrollbar now appears at the right edge while it moves and shows how far down you are. Desktop looks
the same as before.
