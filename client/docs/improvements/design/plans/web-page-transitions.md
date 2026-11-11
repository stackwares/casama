# Fix: Pages slide and fade like a phone app on the web and on desktop

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/web-page-transitions
- **Needs new dependency**: none

## Why

The web and desktop are click and open: a click shows the next page at once. Casama plays phone transitions
there instead: on a Mac every page slides in from the right like an iPhone, on Windows, Linux and the web
pages fade forward like Android, and the Chats, Inbox and Tasks tabs crossfade. It makes the app feel slow and
cheap next to native desktop apps and websites. Android and iOS should keep their own transitions; the web
(even on a phone's browser) and desktop should switch pages with no transition.

## Where

All paths are relative to the `client/` folder (the Flutter app, where `pubspec.yaml` is).

1. The theme maps every platform to a phone transition, with no branch for the web or desktop (the web uses
   the transition of whatever OS the browser runs on):

```dart
// lib/theme/app_theme.dart:88-97 — current
  /// Every page route paints the wallpaper under its content (see [WallpaperPageTransitionsBuilder]).
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: WallpaperPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
      TargetPlatform.fuchsia: WallpaperPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
      TargetPlatform.iOS: WallpaperPageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
      TargetPlatform.macOS: WallpaperPageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
      TargetPlatform.linux: WallpaperPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
      TargetPlatform.windows: WallpaperPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
    },
  );
```

   It is assigned once, at `lib/theme/app_theme.dart:120` (`pageTransitionsTheme: _pageTransitions,`), and
   every page goes through it: the router builds each page as a `MaterialPage` (`_page` in
   `lib/core/router.dart:72-80`), and the five `Navigator.of(context).push(MaterialPageRoute(...))` calls in
   the app use it too. `foundation.dart` (which has `kIsWeb`) is already imported at line 3.

2. The three tab pages (Chats `/bots`, Inbox `/inbox`, Tasks `/tasks`) don't use the theme: the router builds
   them as a `CustomTransitionPage` with a 180 ms crossfade on every platform:

```dart
// lib/core/router.dart:91-93 — current (inside `_tab`, lines 88-106)
  final duration = MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);
```

   `lib/core/router.dart` imports only `package:flutter/material.dart` from Flutter (line 1), which does not
   export `kIsWeb`.

Context the fix must respect: `WallpaperPageTransitionsBuilder` (`lib/theme/wallpaper.dart:515-533`) paints
the wallpaper under every page by wrapping the page in `Wallpaper(child: child)` before handing it to the
platform transition. It does not pass its inner builder's `transitionDuration` / `reverseTransitionDuration`
through, so pages get Flutter's default 300 ms. That is why the no-transition builder below paints the
wallpaper itself instead of being wrapped in `WallpaperPageTransitionsBuilder`: wrapped, it would keep 300 ms
and a closing page would hang on screen for 300 ms with nothing moving. Making the wrapper forward durations
would change the Android and iOS timings, which stay as they are.

## The fix

The article's fix: a `_NoPageTransitionsBuilder` with zero durations that returns the page as is, used for
macOS, Windows, Linux and Fuchsia, and for Android and iOS when `kIsWeb`; set once in the theme's
`pageTransitionsTheme`. Here it returns `Wallpaper(child: child)` instead of `child`, so pages still paint the
wallpaper exactly as `WallpaperPageTransitionsBuilder` does. For the tab pages, which bypass the theme, the
article's "customize it at your router" applies: their crossfade duration becomes zero on the web and desktop.

```dart
// target: lib/theme/app_theme.dart, replacing the block quoted in "Where" item 1
  /// Every page route paints the wallpaper under its content (see [WallpaperPageTransitionsBuilder]).
  /// The web and desktop are click and open, so pages there switch with no transition; Android and iOS
  /// keep their own, except in a browser.
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: kIsWeb ? _NoPageTransitionsBuilder() : WallpaperPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
      TargetPlatform.iOS: kIsWeb ? _NoPageTransitionsBuilder() : WallpaperPageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
      TargetPlatform.macOS: _NoPageTransitionsBuilder(),
      TargetPlatform.windows: _NoPageTransitionsBuilder(),
      TargetPlatform.linux: _NoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: _NoPageTransitionsBuilder(),
    },
  );
```

```dart
// target: lib/theme/app_theme.dart, appended at the very end of the file
/// The web and desktop: the page appears at once, with no transition, still over the wallpaper that
/// [WallpaperPageTransitionsBuilder] paints under every other page.
class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => Wallpaper(child: child);
}
```

```dart
// target: lib/core/router.dart, new top-level function directly above `_tab`'s doc comment
/// The web and desktop are click and open: pages and tabs switch there with no transition.
bool _switchesInstantly(BuildContext context) =>
    kIsWeb || const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}.contains(Theme.of(context).platform);
```

```dart
// target: lib/core/router.dart, inside `_tab` (replaces the three lines quoted in "Where" item 2)
  final duration = MediaQuery.disableAnimationsOf(context) || _switchesInstantly(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);
```

The platform comes from `Theme.of(context).platform`, the same value `MaterialPage` uses to pick a builder from
the theme, so pages and tabs always agree.

## Steps

1. In `lib/theme/app_theme.dart`, replace the 11 lines quoted in "Where" item 1 (from
   `  /// Every page route paints the wallpaper under its content (see [WallpaperPageTransitionsBuilder]).`
   to the `  );` that closes `_pageTransitions`) with the first target block. Edit by hand; never run
   `dart format` on this file.

2. In `lib/theme/app_theme.dart`, after the last line of the file (the `}` that closes
   `abstract final class AppTheme`, right after `      labelSmall: sans(theme.labelSmall, 0.2, FontWeight.w500),`,
   `    );` and `  }`), add one blank line and then the `_NoPageTransitionsBuilder` class from the second target
   block. `Wallpaper` comes from `wallpaper.dart`, already imported at line 10; nothing else to import.

3. In `lib/core/router.dart`, add the line `import 'package:flutter/foundation.dart' show kIsWeb;` as the new
   first line of the file, directly above `import 'package:flutter/material.dart';`.

4. In `lib/core/router.dart`, find the line
   `/// The tab pages (Chats, Inbox, Tasks). They paint no wallpaper of their own: the shell's page`
   and insert, directly above it, the `_switchesInstantly` function from the third target block followed by
   one blank line.

5. In `lib/core/router.dart`, inside `_tab`, replace the three lines quoted in "Where" item 2 with the fourth
   target block. Only those three lines change; leave the rest of `_tab` (including its `name:` line and the
   `FadeTransition`) exactly as you find it, even if it differs from the line numbers above. Edit by hand; no
   formatter on this file.

6. Create `test/page_transitions_test.dart` with this content, then run
   `dart format -l 200 test/page_transitions_test.dart` (only on this new file):

   ```dart
   // The web and desktop are click and open: pages and tabs switch there with no transition, and pages still
   // paint the wallpaper. Android and iOS keep their own transitions.
   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/core/local_cache.dart';
   import 'package:casama_app/core/providers.dart';
   import 'package:casama_app/core/router.dart';
   import 'package:casama_app/features/inbox/inbox_screen.dart';
   import 'package:casama_app/l10n/generated/app_localizations.dart';
   import 'package:casama_app/theme/app_theme.dart';
   import 'package:casama_app/theme/wallpaper.dart';
   import 'package:shared_preferences/shared_preferences.dart';

   import 'fake_backend.dart';

   void main() {
     testWidgets('desktop pages have no transition; Android and iOS keep theirs', (tester) async {
       final builders = AppTheme.light().pageTransitionsTheme.builders;
       for (final platform in const [TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux]) {
         expect(builders[platform]!.transitionDuration, Duration.zero, reason: '$platform');
         expect(builders[platform]!.reverseTransitionDuration, Duration.zero, reason: '$platform');
       }
       for (final platform in const [TargetPlatform.android, TargetPlatform.iOS]) {
         expect(builders[platform], isA<WallpaperPageTransitionsBuilder>(), reason: '$platform');
       }
     });

     testWidgets('on desktop a page opens and closes at once, over the wallpaper', (tester) async {
       await tester.pumpWidget(
         MaterialApp(
           theme: AppTheme.light().copyWith(platform: TargetPlatform.macOS),
           home: Builder(
             builder: (context) => TextButton(
               onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Text('second page'))),
               child: const Text('open'),
             ),
           ),
         ),
       );
       await tester.tap(find.text('open'));
       await tester.pump();
       final second = find.text('second page');
       expect(ModalRoute.of(tester.element(second))!.animation!.status, AnimationStatus.completed);
       expect(find.ancestor(of: second, matching: find.byType(Wallpaper)), findsOneWidget);
       Navigator.of(tester.element(second)).pop();
       await tester.pump();
       expect(second, findsNothing);
     });

     testWidgets('on desktop the Chats, Inbox and Tasks tabs switch at once too', (tester) async {
       SharedPreferences.setMockInitialValues({});
       tester.view.physicalSize = const Size(430, 932);
       tester.view.devicePixelRatio = 1;
       addTearDown(tester.view.reset);
       final container = ProviderContainer(retry: (_, _) => null, overrides: [backendProvider.overrideWithValue(FakeBackend()), localCacheProvider.overrideWithValue(const NoCache())]);
       addTearDown(container.dispose);
       final router = container.read(routerProvider);
       await tester.pumpWidget(
         UncontrolledProviderScope(
           container: container,
           child: MaterialApp.router(
             theme: AppTheme.light().copyWith(platform: TargetPlatform.macOS),
             routerConfig: router,
             localizationsDelegates: AppLocalizations.localizationsDelegates,
             supportedLocales: AppLocalizations.supportedLocales,
           ),
         ),
       );
       for (var i = 0; i < 15; i++) {
         await tester.pump(const Duration(milliseconds: 100));
       }
       router.go('/inbox');
       await tester.pump();
       expect(ModalRoute.of(tester.element(find.byType(InboxScreen)))!.animation!.status, AnimationStatus.completed);
       await tester.pumpWidget(const SizedBox());
       await tester.pump(const Duration(minutes: 1));
     });
   }
   ```

7. From the `client/` folder run
   `flutter test test/page_transitions_test.dart test/navigation_test.dart test/phone_layout_test.dart`.
   All must pass.

## Check it

`dart analyze lib/theme/app_theme.dart lib/core/router.dart test/page_transitions_test.dart` exits 0, and the
only issues it lists are the six `curly_braces_in_flow_control_structures` infos that already exist in the
router's `redirect` (they were there before this change). Then:

- `grep -c 'kIsWeb ? _NoPageTransitionsBuilder()' lib/theme/app_theme.dart` → `2`.
- `grep -c 'TargetPlatform.macOS: _NoPageTransitionsBuilder(),' lib/theme/app_theme.dart` → `1`.
- `grep -c 'WallpaperPageTransitionsBuilder(CupertinoPageTransitionsBuilder())' lib/theme/app_theme.dart` → `1` (iOS only; macOS no longer slides).
- `grep -c 'WallpaperPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder())' lib/theme/app_theme.dart` → `1` (Android only).
- `grep -c 'class _NoPageTransitionsBuilder extends PageTransitionsBuilder' lib/theme/app_theme.dart` → `1`.
- `grep -c 'Duration get transitionDuration => Duration.zero;' lib/theme/app_theme.dart` → `1`.
- `grep -c "import 'package:flutter/foundation.dart' show kIsWeb;" lib/core/router.dart` → `1`.
- `grep -c 'bool _switchesInstantly(BuildContext context)' lib/core/router.dart` → `1`.
- `grep -c '|| _switchesInstantly(context)' lib/core/router.dart` → `1`.

## Don't touch

- `lib/theme/wallpaper.dart` and `WallpaperPageTransitionsBuilder`: don't make it forward durations or
  `delegatedTransition`; that would change the Android and iOS transitions, which stay exactly as they are.
- Sheets, dialogs and menus (`showAdaptiveSheet`, `showDialog`, `showModalBottomSheet` and friends): only page
  transitions are in scope.
- `_page` and the `ShellRoute`'s `MaterialPage` in `lib/core/router.dart`: they already follow the theme.
- The `name:`, `key:` and `transitionsBuilder:` lines of `_tab`, and the `MediaQuery.disableAnimationsOf`
  check (keep it; reduced motion still turns the crossfade off on phones).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix. Never run `dart format` on existing files or on
  directories; only on the new test file. No git commands (others commit in this tree).

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt
  (the codebase moved on since this plan was written); for `_tab`, only the three `duration` lines must match.
- `test/page_transitions_test.dart` already exists, or `lib/core/router.dart` already imports
  `package:flutter/foundation.dart`.
- The analyzer says the `kIsWeb ? … : …` entries aren't constant, or reports any new issue.
- A test fails because of the change, in the new test or in `test/navigation_test.dart` or
  `test/phone_layout_test.dart` (for example one that waits for a page to slide on a desktop platform).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app
now and one place to open to see it. Not a list of files, the steps already
have those. For example: on the web and on Mac, Windows and Linux, pages and the Chats/Inbox/Tasks tabs now
switch at once, like a website or a desktop app, still over the wallpaper; Android and iOS keep their own
transitions. To see it, open Settings in the macOS app or the web build and click into Themes and back.
