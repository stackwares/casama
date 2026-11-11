# Fix: Analytics never learns which screens people use

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/analytics-screen-names
- **Needs new dependency**: none

## Why

Casama sends screen views to PostHog through `PosthogObserver`, which reports a page only when its route has a
name. No route in the app has one, so not a single screen view is ever recorded: the team can't tell whether
people live in Chats, the Inbox or Settings, or where they drop off. Every page should be reported by a stable,
readable name such as `/bots/:botId/chat`, never with the ids from its address.

## Where

All paths are relative to the `client/` folder (the Flutter app, where `pubspec.yaml` is).

The observer is wired, and the shell's pages reach it: go_router 18.1.3's `ShellRoute` passes the router's
observers to its own navigator (`notifyRootObserver` defaults to `true`), so no `observers:` list is needed on
the `ShellRoute`.

```dart
// lib/core/router.dart:119-124 — current (context, no change)
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/bots',
    observers: Telemetry.observers,
```

```dart
// lib/core/telemetry.dart:109-110 — current (context, no change)
  /// Screen views for PostHog (no-op when PostHog is off).
  static List<NavigatorObserver> get observers => posthogOn ? [PosthogObserver()] : const [];
```

`PosthogObserver` (posthog_flutter 5.60.0) sends `Posthog().screen(screenName: route.settings.name)` and skips
any route whose name is null or empty.

Native automatic screen reporting is already off, nothing to change: posthog_flutter forces
`captureScreenViews = false` in its own native setup on iOS/macOS (`darwin/posthog_flutter/Sources/posthog_flutter/PosthogFlutterPlugin.swift:200`
in the package) and Android (`android/src/main/kotlin/com/posthog/flutter/PosthogFlutterPlugin.kt:601`), and native
auto-init is off in `ios/Runner/Info.plist:107-108`, `macos/Runner/Info.plist:69-70` and
`android/app/src/main/AndroidManifest.xml:95-97` (`com.posthog.posthog.AUTO_INIT` = false). So no
`FlutterViewController` / `MainActivity` noise; the missing piece is names.

The event scrubber already keeps the name: `$screen_name` is in `_keepKeys` (`lib/core/telemetry.dart:38`), and
`beforeSend` runs on screen events.

**Missing piece 1: go_router pages have no name.** No `GoRoute` sets `name:`, so `state.name` is always null,
and the two page builders every route uses pass exactly that:

```dart
// lib/core/router.dart:72-80 — current
GoRouterPageBuilder _page(
  Widget Function(BuildContext context, GoRouterState state) build,
) =>
    (context, state) => MaterialPage<void>(
      key: state.pageKey,
      name: state.name,
      arguments: state.extra,
      child: build(context, state),
    );
```

```dart
// lib/core/router.dart:94-96 — current (inside `_tab`, the Chats/Inbox/Tasks tab pages)
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
```

(The `ShellRoute`'s own `MaterialPage` at `lib/core/router.dart:239-244` has no name either; that is right, it is
the frame around the tabs, not a screen, and naming it would count every visit twice.)

**Missing piece 2: plain `Navigator.push` calls have no `RouteSettings` name.**

```dart
// lib/features/bots/bot_template.dart:115 — current (bot template imported from a file)
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ImportBotScreen(template: t)));
```

```dart
// lib/features/bots/agent_import.dart:57 — current (review of an imported agent)
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgentImportReviewScreen(plan: plan)));
```

```dart
// lib/features/settings/totp_scan.dart:24 — current (QR scanner for a sign-in code)
        final link = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _ScanPage()));
```

```dart
// lib/features/workspaces/join_flow.dart:534 — current (QR scanner for an invite)
                      final v = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _ScanInvitePage()));
```

```dart
// lib/features/skills/skill_catalog_screen.dart:31-33 — current (the catalog where there is no router)
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SkillCatalogScreen()));
```

## The fix

The article's fix: turn native screen reporting off (already done, see above) and name every route. For
go_router with a custom `pageBuilder`, the article sets the page's name from the route:
`name: state.name ?? state.path`. Here `state.path` alone isn't enough, because nested routes' paths are
relative (`keys` for `/settings/keys`, and `:id` for both `/projects/:id` and `/settings/integrations/:id`), and
`state.fullPath` can't be used as is: it is the template of the page on top, the same for every page under it.
So a small helper builds each page's full template from the top template, keeping as many segments as the
page's own address has. The result is id-free by construction (`/bots/<uuid>/chat` becomes
`/bots/:botId/chat`, and query strings such as `?c=<conversation id>` are never part of it), it is the same name
go_router users see in their routes, and new routes get a name with no extra work. Plain pushes get a
`RouteSettings(name: ...)` in the same path style.

```dart
// target: lib/core/router.dart, new top-level function directly above `_page`'s doc comment
/// The page's screen name for analytics (PostHog's `$screen`): its route as a template, such as
/// /bots/:botId/chat, never the ids in its address. A nested route's own path is relative ("keys" for
/// /settings/keys), and [GoRouterState.fullPath] is the template of the page on top, the same for every
/// page under it, so this keeps as many of its segments as this page's own address has: on
/// /bots/<id>/chat the tab underneath is "/bots".
String _screenName(GoRouterState state) {
  final depth = state.matchedLocation.split('/').where((s) => s.isNotEmpty).length;
  final template = (state.fullPath ?? '').split('/').where((s) => s.isNotEmpty);
  return '/${template.take(depth).join('/')}';
}
```

```dart
// target: lib/core/router.dart, inside `_page`
      name: state.name ?? _screenName(state),
```

```dart
// target: lib/core/router.dart, inside `_tab`
    name: state.name ?? _screenName(state),
```

```dart
// target: lib/features/bots/bot_template.dart:115
    await Navigator.of(context).push(MaterialPageRoute(settings: const RouteSettings(name: '/import/file'), builder: (_) => ImportBotScreen(template: t)));
```

```dart
// target: lib/features/bots/agent_import.dart:57
  await Navigator.of(context).push(MaterialPageRoute(settings: const RouteSettings(name: '/import/agent'), builder: (_) => AgentImportReviewScreen(plan: plan)));
```

```dart
// target: lib/features/settings/totp_scan.dart:24
        final link = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, settings: const RouteSettings(name: '/scan/sign-in-code'), builder: (_) => const _ScanPage()));
```

```dart
// target: lib/features/workspaces/join_flow.dart:534
                      final v = await Navigator.of(context).push<String>(MaterialPageRoute(fullscreenDialog: true, settings: const RouteSettings(name: '/scan/invite'), builder: (_) => const _ScanInvitePage()));
```

```dart
// target: lib/features/skills/skill_catalog_screen.dart, replacing lines 31-33
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/settings/skills/catalog'),
        builder: (_) => const SkillCatalogScreen(),
      ),
    );
```

The skill catalog uses `/settings/skills/catalog` because that is the same page's route when the router is
there, so both ways in count as one screen.

## Steps

1. Confirm native screen capture is still forced off by the installed plugin. Read the version on the line
   after `posthog_flutter:` in `pubspec.lock` (`version: "5.60.0"` today), then run
   `grep -rn "captureScreenViews = false" ~/.pub-cache/hosted/pub.dev/posthog_flutter-<that version>/android ~/.pub-cache/hosted/pub.dev/posthog_flutter-<that version>/darwin`.
   It must print two lines (one `.kt`, one `.swift`). Change nothing for this step.

2. In `lib/core/router.dart`, find the line
   `/// Every route is a [MaterialPage], so pages slide or fade the way each platform expects and the`
   and insert, directly above it, the `_screenName` function from the first target block followed by one blank
   line. `GoRouterState` is already available from `package:go_router/go_router.dart`.

3. In `lib/core/router.dart`, inside `_page` (the `MaterialPage<void>(` block quoted in "Where"), change the line
   `      name: state.name,` to `      name: state.name ?? _screenName(state),`. Only that line changes.

4. In `lib/core/router.dart`, inside `_tab` (the `CustomTransitionPage<void>(` block), change the line
   `    name: state.name,` to `    name: state.name ?? _screenName(state),`. Only that line changes; leave the
   rest of `_tab` (its `duration`, `transitionsBuilder` and so on) exactly as you find it. Edit by hand; never
   run `dart format` on this file.

5. Replace each of the five push lines quoted in "Where" under "Missing piece 2" with its target above, by
   hand, keeping each file's existing indentation (the four one-line calls stay one line). `RouteSettings` comes
   from `package:flutter/material.dart`, which each of these files already imports. Don't format these files.

6. Create `test/screen_names_test.dart` with this content, then run
   `dart format -l 200 test/screen_names_test.dart` (only on this new file):

   ```dart
   // Screen analytics (PostHog's $screen) name each page by its route's template, never by the ids in its
   // address, so every page is reported and no id leaves the device.
   import 'dart:async';

   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/core/local_cache.dart';
   import 'package:casama_app/core/providers.dart';
   import 'package:casama_app/core/router.dart';
   import 'package:casama_app/features/skills/skill_catalog_screen.dart';
   import 'package:casama_app/features/skills/skills_screen.dart';
   import 'package:casama_app/l10n/generated/app_localizations.dart';
   import 'package:casama_app/theme/app_theme.dart';
   import 'package:shared_preferences/shared_preferences.dart';

   import 'app_test.dart' show harness, setSize;
   import 'fake_backend.dart';
   import 'phone_layout_test.dart' show routes;

   void main() {
     testWidgets('every page has a screen name: its route template, without ids', (tester) async {
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
             theme: AppTheme.light(),
             routerConfig: router,
             localizationsDelegates: AppLocalizations.localizationsDelegates,
             supportedLocales: AppLocalizations.supportedLocales,
           ),
         ),
       );
       Future<void> settle() async {
         for (var i = 0; i < 15; i++) {
           await tester.pump(const Duration(milliseconds: 100));
         }
       }

       // The names of the pages on every navigator (the app's and the shell's).
       List<String> names() => [
         for (final navigator in tester.widgetList<Navigator>(find.byType(Navigator, skipOffstage: false))) ...navigator.pages.map((page) => page.name).whereType<String>(),
       ];

       await settle();
       router.go('/bots/$botId/chat');
       await settle();
       expect(names(), containsAll(['/bots', '/bots/:botId/chat']));
       router.go('/settings/keys');
       await settle();
       expect(names(), containsAll(['/settings', '/settings/keys']));

       for (final location in routes) {
         router.go(location);
         await settle();
         expect(names(), contains(router.state.fullPath), reason: location);
         expect(names().where((n) => n.contains(botId) || n.contains(runId)), isEmpty, reason: location);
       }

       // A page opened with push is named too.
       router.go('/settings/skills');
       await settle();
       unawaited(router.push('/settings/skills/catalog'));
       await settle();
       expect(names(), contains('/settings/skills/catalog'));

       await tester.pumpWidget(const SizedBox());
       await tester.pump(const Duration(minutes: 1));
     });

     testWidgets('a page pushed without the router is named too', (tester) async {
       await setSize(tester, const Size(900, 1000));
       await tester.pumpWidget(harness(FakeBackend(), const SkillsScreen()));
       await tester.pumpAndSettle();
       await tester.tap(find.byKey(const Key('browseCatalog')));
       await tester.pumpAndSettle();
       expect(ModalRoute.of(tester.element(find.byType(SkillCatalogScreen)))!.settings.name, '/settings/skills/catalog');
     });
   }
   ```

7. From the `client/` folder run
   `flutter test test/screen_names_test.dart test/navigation_test.dart test/phone_layout_test.dart test/telemetry_test.dart`.
   All must pass.

## Check it

`dart analyze lib/core/router.dart lib/features/bots/bot_template.dart lib/features/bots/agent_import.dart lib/features/settings/totp_scan.dart lib/features/workspaces/join_flow.dart lib/features/skills/skill_catalog_screen.dart test/screen_names_test.dart`
exits 0, and the only issues it lists are the six `curly_braces_in_flow_control_structures` infos that already
exist in the router's `redirect` (they were there before this change). Then:

- `grep -c 'String _screenName(GoRouterState state)' lib/core/router.dart` → `1`.
- `grep -c 'name: state.name ?? _screenName(state),' lib/core/router.dart` → `2`.
- `grep -c 'name: state.name,' lib/core/router.dart` → `0`.
- `grep -c "RouteSettings(name: '/import/file')" lib/features/bots/bot_template.dart` → `1`.
- `grep -c "RouteSettings(name: '/import/agent')" lib/features/bots/agent_import.dart` → `1`.
- `grep -c "RouteSettings(name: '/scan/sign-in-code')" lib/features/settings/totp_scan.dart` → `1`.
- `grep -c "RouteSettings(name: '/scan/invite')" lib/features/workspaces/join_flow.dart` → `1`.
- `grep -c "RouteSettings(name: '/settings/skills/catalog')" lib/features/skills/skill_catalog_screen.dart` → `1`.

## Don't touch

- `lib/core/telemetry.dart`: the observer, its default route filter (pages only; dialogs and sheets are not
  screens) and `_keepKeys` (it already keeps `$screen_name`) stay as they are. Don't add a `nameExtractor`.
- `ios/Runner/Info.plist`, `macos/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`: native
  screen capture is already off (step 1 confirms it); adding keys there does nothing for PostHog.
- The `ShellRoute`'s `MaterialPage` (no name on purpose) and the `GoRoute`s themselves: don't add `name:` to
  routes; the helper names them all.
- The `GoRouter(observers: ...)` line and the `ShellRoute` (no `observers:` needed there).
- `showDialog`, `showModalBottomSheet`, `showAdaptiveSheet` calls: not screens.
- `web/index.html`: the web build loads no PostHog script, so web screen views are out of scope here.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix. Never run `dart format` on existing files or on
  directories; only on the new test file. No git commands (others commit in this tree).

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt
  (the codebase moved on since this plan was written). For `_page` and `_tab` only their `name: state.name,`
  line must match.
- Step 1 prints fewer than two lines (the plugin no longer forces native screen capture off).
- A `GoRoute` in `lib/core/router.dart` now has a `name:`; or `test/screen_names_test.dart` already exists.
- A screen name in the test contains an id, or a location's `router.state.fullPath` is missing from the names.
- A test fails because of the change, in the new test or in `test/navigation_test.dart`,
  `test/phone_layout_test.dart` or `test/telemetry_test.dart`.
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app
now and one place to open to see it. Not a list of files, the steps already
have those. For example: with a PostHog key set, every page now sends a screen view named after its route
(`/bots`, `/bots/:botId/chat`, `/settings/keys`), never with ids; before, none were sent. To see it, run a
build with `--dart-define=POSTHOG_API_KEY=...`, open a chat and Settings, and look at PostHog's
Activity for `$screen` events.
