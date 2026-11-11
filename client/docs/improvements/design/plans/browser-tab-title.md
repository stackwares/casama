# Fix: Every browser tab of the web app just says "Casama"

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/browser-tab-title
- **Needs new dependency**: none

## Why

On the web, the tab title shows in the browser tab, the history, bookmarks and the address bar's suggestions.
Casama sets one fixed title, so a person with Settings, Inbox and two bot chats open in four tabs sees four
tabs all called "Casama" and can't tell them apart. Each page should say what it is ("Inbox · Casama",
"Memory · Ada · Casama", "Ada · Casama" for the chat with Ada).

## Where

All paths are relative to the `client/` folder (the Flutter app, where `pubspec.yaml` is).

1. The app's only title is a static one. `onGenerateTitle` reruns only when the app itself rebuilds, never
   on navigation, and the `builder` has nothing that follows the router:

```dart
// lib/app.dart:56-72 — current
    final appearance = ref.watch(appearanceProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      theme: AppTheme.light(appearance),
      darkTheme: AppTheme.dark(appearance),
      themeMode: appearance.mode,
      themeAnimationDuration: const Duration(milliseconds: 250),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => _DismissKeyboard(
        child: CompanionOverlay(
          child: _FirstRunSteps(push: ref.read(pushProvider), child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
```

2. The "Connecting to Casama…" / "Can't reach your Casama server" screen shown before the app starts is its
   own `MaterialApp` with no title at all (`MaterialApp.title` defaults to `''`), so on the web Flutter sets
   `document.title` to an empty string and the tab loses the page's `<title>Casama</title>` while it shows:

```dart
// lib/main.dart:119-124 — current
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
```

3. Strings: the product name lives in one place, `"appTitle": "Casama"` in `lib/l10n/app_en.arb` (line 3),
   and most pages' own titles already exist there (`settings`, `inbox`, `memory`, …). There is no format for
   "page · app", and no plain label for a chat, a call, a project or a group chat (those pages show a name
   from data instead):

```json
// lib/l10n/app_en.arb:1-4 — current
{
  "@@locale": "en",
  "appTitle": "Casama",
  "loading": "Loading…",
```

No `Title(` widget exists anywhere in `lib/`, and nothing listens to the router to retitle the tab.

## The fix

The article's fix: wrap once, in `MaterialApp`'s `builder` (the single place every page flows through), with
a `RouteTitle` widget that listens to the go_router and rebuilds a `Title` on every navigation; a
`titleForPath`-style function maps the current route to a readable name, with a fallback so the tab is never
blank. Adapted to this codebase:

- The route is read from `router.state.fullPath`, go_router's template for the page on top
  (`/bots/:botId/memory`), not from the browser URL: this app opens many pages with `context.push` (settings
  rows, a bot's pages, the skill catalog), and go_router does not put pushed pages in the URL by default, so the
  URL alone would leave the tab on the page underneath.
  The router delegate notifies on every go, push and pop.
- Names come from `lib/l10n/app_en.arb`, reusing each page's own title string; six new strings cover the format
  and the pages titled from data.
- A bot's pages add the bot's name, read from `botProvider` (`lib/core/providers.dart:202`), so two chats in
  two tabs read "Ada · Casama" and "Max · Casama".
- It is on for the web only (`enabled` defaults to `kIsWeb`). On Android, `Title` also renames the app in the
  Recents screen, which must keep saying "Casama"; iOS and desktop ignore it. Tests pass `enabled: true`.
- `onGenerateTitle` stays: it is the fallback before the first page is matched, and the app's name on Android.

New file `lib/core/route_title.dart`, complete:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'providers.dart';

/// Web: the browser tab names the open page ("Settings · Casama", "Memory · Ada · Casama"), so open tabs,
/// history and bookmarks can be told apart. It sits in MaterialApp's builder, above every page, and
/// rebuilds its [Title] on every navigation, pushes and pops included. Elsewhere it does nothing: the app's
/// own title stays (on Android that is the app's name in Recents).
class RouteTitle extends StatelessWidget {
  const RouteTitle({super.key, required this.router, required this.child, this.enabled = kIsWeb});

  final GoRouter router;
  final Widget child;

  /// On for the web only; tests turn it on.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ListenableBuilder(
      listenable: Listenable.merge([router.routerDelegate, router.routeInformationProvider]),
      builder: (context, _) {
        // Nothing is matched before the first location opens, nor on the error page.
        final state = router.routerDelegate.currentConfiguration.isEmpty ? null : router.state;
        final botId = state?.pathParameters['botId'];
        return Consumer(
          builder: (context, ref, _) {
            final botName = botId == null ? null : ref.watch(botProvider(botId))?.name;
            return Title(
              key: const Key('routeTitle'),
              title: tabTitleFor(state?.fullPath, AppLocalizations.of(context), botName: botName),
              // Required and must be opaque. On the web it also becomes the page's theme-color (the
              // browser toolbar tint on phones), so it matches the page's surface, light or dark.
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 1),
              child: child,
            );
          },
        );
      },
    );
  }
}

/// The tab title for the page whose route is [fullPath], a go_router template such as
/// "/bots/:botId/memory" (never the ids in the address). Pages without a name of their own say just the
/// app's name.
String tabTitleFor(String? fullPath, AppLocalizations l10n, {String? botName}) {
  final page = switch (fullPath) {
    '/sign-in' => l10n.signIn,
    '/onboarding' => l10n.createWorkspace,
    '/two-step' => l10n.twoStepPromptTitle,
    '/new-password' => l10n.newPasswordTitle,
    '/join/:token' => l10n.invitedToJoin,
    '/join-team' => l10n.yourTeamIsHere,
    '/oauth/consent/:id' => l10n.connectAiApp,
    '/import/:token' => l10n.importBot,
    '/bots' => l10n.navChats,
    '/bots/:botId/chat' => botName ?? l10n.tabTitleChat,
    '/bots/:botId/activity' => l10n.activity,
    '/bots/:botId/runs/:runId' => l10n.timelineTitle,
    '/bots/:botId/memory' => l10n.memory,
    '/bots/:botId/settings' => l10n.botProfile,
    '/bots/:botId/sharing' => l10n.sharing,
    '/bots/:botId/replays' => l10n.replays,
    '/bots/:botId/knowledge' => l10n.knowledge,
    '/bots/:botId/chat-apps' => l10n.chatApps,
    '/bots/:botId/links' => l10n.links,
    '/bots/:botId/plugins' => l10n.plugins,
    '/bots/:botId/watchers' => l10n.watchers,
    '/bots/:botId/rules' => l10n.actionRules,
    '/bots/:botId/history' => l10n.settingsHistory,
    '/bots/:botId/call' => l10n.tabTitleCall,
    '/bots/:botId/routines' => l10n.routines,
    '/bots/:botId/integrations' => l10n.integrations,
    '/quick-ask' => l10n.quickAsk,
    '/inbox' => l10n.inbox,
    '/tasks' => l10n.navTasks,
    '/projects' => l10n.projects,
    '/projects/:id' => l10n.tabTitleProject,
    '/search' => l10n.search,
    '/teach/:id' => l10n.teachDraftTitle,
    '/password-managers' => l10n.passwordManagers,
    '/calls/:id' => l10n.outCall,
    '/pages' => l10n.pages,
    '/groups/:id' => l10n.tabTitleGroupChat,
    '/approvals/:id' => l10n.approval,
    '/computer' => l10n.computerTitle,
    '/computer/live' => l10n.liveView,
    '/settings' => l10n.settings,
    '/settings/keys' => l10n.modelKeys,
    '/settings/themes' => l10n.themes,
    '/settings/theme' => l10n.colorScheme,
    '/settings/fonts' => l10n.fonts,
    '/settings/usage' => l10n.usage,
    '/settings/background' => l10n.background,
    '/settings/gallery' || '/settings/gallery/:type/:id' => l10n.gallery,
    '/settings/skills' => l10n.skills,
    '/settings/skills/catalog' => l10n.skillCatalog,
    '/settings/integrations' || '/settings/integrations/:id' => l10n.appsTitle,
    '/settings/secrets' => l10n.secrets,
    '/settings/computers' => l10n.computers,
    '/settings/companion' => l10n.useThisComputer,
    '/settings/devices' => l10n.deviceConnections,
    '/settings/admin' => l10n.adminConsole,
    '/settings/billing' => l10n.billing,
    '/settings/privacy' => l10n.privacy,
    '/settings/about-you' => l10n.aboutYou,
    '/settings/two-step' => l10n.twoStepSignIn,
    '/settings/passkeys' => l10n.passkeys,
    '/settings/account' => l10n.account,
    '/settings/workspace' => l10n.workspaceSettings,
    '/settings/people' => l10n.people,
    // /welcome, /joined/:orgId and /run-routine/:ref only pass through on the way to another page.
    _ => null,
  };
  if (page == null) return l10n.appTitle;
  // A bot's other pages name the bot too: "Memory · Ada". Its chat is already titled with the name.
  final onBotPage = fullPath != '/bots/:botId/chat' && (fullPath?.startsWith('/bots/:botId/') ?? false);
  final named = onBotPage && botName != null ? l10n.tabTitleBotPage(page, botName) : page;
  return l10n.tabTitle(named, l10n.appTitle);
}
```

Every existing key used above is a plain `String get` in `lib/l10n/generated/app_localizations.dart` today
(their English: "Sign in", "Create a workspace", "Enter your code", "Choose a new password", "You're invited
to join", "Your team is already here", "Connect an AI app", "Import a bot", "Chats", "Activity", "Run
timeline", "Memory", "Bot profile", "Sharing", "Replays", "Knowledge", "Chat apps", "Linked bots", "Plugins",
"Watchers", "Action rules", "Settings history", "Routines", "Integrations", "Quick ask", "Inbox", "Tasks",
"Projects", "Search", "New skill", "Password managers", "Call", "Pages", "Approval", "Computer", "Live view",
"Settings", "Model keys", "Themes", "Color scheme", "Fonts", "Usage", "Background", "Gallery", "Skills",
"Skill catalog", "Apps", "Secrets", "Computers", "Use this computer for bots", "Device connections", "Admin
console", "Billing", "Privacy", "About you", "Two-step sign-in", "Passkeys", "Account", "Workspace
settings", "People").

`lib/app.dart` target (only the lines shown change; `onGenerateTitle` stays):

```dart
// target: lib/app.dart
    final appearance = ref.watch(appearanceProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      theme: AppTheme.light(appearance),
      darkTheme: AppTheme.dark(appearance),
      themeMode: appearance.mode,
      themeAnimationDuration: const Duration(milliseconds: 250),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => RouteTitle(
        router: router,
        child: _DismissKeyboard(
          child: CompanionOverlay(
            child: _FirstRunSteps(push: ref.read(pushProvider), child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
```

`lib/main.dart` target (one line added, so the tab says "Casama" while connecting instead of going blank):

```dart
// target: lib/main.dart
    return MaterialApp(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
```

Match how this codebase already writes small wrapper widgets: imitate `_DismissKeyboard` in `lib/app.dart`
(a `StatelessWidget` with a doc comment that says why it exists).

## Steps

1. In `lib/l10n/app_en.arb`, directly after the line `  "appTitle": "Casama",` (line 3), insert these eight
   lines, indented with two spaces like their neighbours:

   ```json
     "tabTitle": "{page} · {app}",
     "@tabTitle": {"placeholders": {"page": {"type": "String"}, "app": {"type": "String"}}},
     "tabTitleBotPage": "{page} · {bot}",
     "@tabTitleBotPage": {"placeholders": {"page": {"type": "String"}, "bot": {"type": "String"}}},
     "tabTitleChat": "Chat",
     "tabTitleCall": "Call",
     "tabTitleProject": "Project",
     "tabTitleGroupChat": "Group chat",
   ```

   The separator is a middle dot `·` (U+00B7) with one space on each side.

2. From the `client/` folder run `flutter gen-l10n`. It rewrites `lib/l10n/generated/app_localizations.dart`
   and `lib/l10n/generated/app_localizations_en.dart` (generated files; never edit them by hand). It must
   finish without errors.

3. Create `lib/core/route_title.dart` with exactly the complete file shown in "The fix", then run
   `dart format -l 200 lib/core/route_title.dart` (only on this new file).

4. In `lib/app.dart`:
   - Add the import `import 'core/route_title.dart';` on its own line directly after `import 'core/router.dart';` (line 23).
   - Make the block quoted in "Where" item 1 look like the `lib/app.dart` target in "The fix", with three
     edits: add `final router = ref.watch(routerProvider);` on its own line after
     `final appearance = ref.watch(appearanceProvider);`, change `routerConfig: ref.watch(routerProvider),` to
     `routerConfig: router,`, and wrap the whole expression the `builder:` returns in
     `RouteTitle(router: router, child: ...)` so `RouteTitle` is the outermost call. If the builder has gained
     another outer wrapper since this plan was written (for example `limitTextScale(context, ...)` around
     `_DismissKeyboard`), keep it unchanged inside `RouteTitle`'s `child:`. Keep every other line as it is,
     and edit by hand; never run `dart format` on this file.

5. In `lib/main.dart`, in the `MaterialApp(` quoted in "Where" item 2, add the line
   `      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,` directly after `return MaterialApp(`.
   `AppLocalizations` is already imported there. Edit by hand; no formatter.

6. Create `test/route_title_test.dart` with this content, then run `dart format -l 200 test/route_title_test.dart`:

   ```dart
   // The browser tab names the open page (web) and follows every navigation, pushes and pops included.
   import 'dart:async';

   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:go_router/go_router.dart';
   import 'package:casama_app/core/local_cache.dart';
   import 'package:casama_app/core/providers.dart';
   import 'package:casama_app/core/route_title.dart';
   import 'package:casama_app/core/router.dart';
   import 'package:casama_app/l10n/generated/app_localizations.dart';
   import 'package:casama_app/theme/app_theme.dart';
   import 'package:shared_preferences/shared_preferences.dart';

   import 'fake_backend.dart';

   void main() {
     testWidgets('the tab title names the page and follows navigation', (tester) async {
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
             builder: (context, child) => RouteTitle(router: router, enabled: true, child: child!),
           ),
         ),
       );
       Future<void> settle() async {
         for (var i = 0; i < 15; i++) {
           await tester.pump(const Duration(milliseconds: 100));
         }
       }

       String title() => tester.widget<Title>(find.byKey(const Key('routeTitle'))).title;

       await settle();
       expect(title(), 'Chats · Casama');
       router.go('/settings');
       await settle();
       expect(title(), 'Settings · Casama');
       router.go('/bots/$botId/chat');
       await settle();
       expect(title(), 'Ada · Casama');
       router.go('/bots/$botId/memory');
       await settle();
       expect(title(), 'Memory · Ada · Casama');
       router.go('/settings/skills');
       await settle();
       expect(title(), 'Skills · Casama');
       // Pushed pages aren't in the URL; the tab follows them anyway.
       unawaited(router.push('/settings/skills/catalog'));
       await settle();
       expect(title(), 'Skill catalog · Casama');
       router.pop();
       await settle();
       expect(title(), 'Skills · Casama');

       // Every page in the router has a title of its own, except the ones that only pass through.
       final l10n = lookupAppLocalizations(const Locale('en'));
       final templates = <String>[];
       void walk(List<RouteBase> routes, String parent) {
         for (final r in routes) {
           if (r is GoRoute) {
             final full = r.path.startsWith('/') ? r.path : '$parent/${r.path}';
             if (r.pageBuilder != null || r.builder != null) templates.add(full);
             walk(r.routes, full);
           } else {
             walk(r.routes, parent);
           }
         }
       }

       walk(router.configuration.routes, '');
       expect(templates, contains('/bots/:botId/chat'));
       const passThrough = {'/welcome', '/joined/:orgId', '/run-routine/:ref'};
       for (final t in templates) {
         expect(tabTitleFor(t, l10n) == 'Casama', passThrough.contains(t), reason: t);
       }
       expect(tabTitleFor(null, l10n), 'Casama');

       await tester.pumpWidget(const SizedBox());
       await tester.pump(const Duration(minutes: 1));
     });
   }
   ```

7. From the `client/` folder run
   `flutter test test/route_title_test.dart test/navigation_test.dart test/phone_layout_test.dart`.
   All must pass.

## Check it

`dart analyze lib/core/route_title.dart lib/app.dart lib/main.dart test/route_title_test.dart` exits 0 and reports no issues. Then:

- `grep -c '"tabTitle' lib/l10n/app_en.arb` → `6`.
- `grep -c 'String get tabTitleChat' lib/l10n/generated/app_localizations.dart` → `1`.
- `grep -c 'String tabTitleBotPage(String page, String bot)' lib/l10n/generated/app_localizations.dart` → `1`.
- `grep -c 'class RouteTitle' lib/core/route_title.dart` → `1`.
- `grep -c 'RouteTitle(' lib/app.dart` → `1`.
- `grep -c 'routerConfig: router,' lib/app.dart` → `1`.
- `grep -c 'onGenerateTitle' lib/main.dart` → `1`.
- `grep -c 'onGenerateTitle' lib/app.dart` → `1` (the static title is still there as the fallback).

## Don't touch

- `lib/core/router.dart`: the title only reads the router's current state; no route, page builder or route
  name changes are needed for it.
- `web/index.html` and its `<title>Casama</title>`: it is the title until Flutter starts, and stays.
- Don't remove `onGenerateTitle` from `lib/app.dart`, and don't make `RouteTitle` run on Android, iOS or desktop
  (`enabled` defaults to `kIsWeb`).
- Don't add per-page `Title` widgets inside screens: two titles fight, and the one in the builder already covers every page.
- Don't edit `lib/l10n/generated/*` by hand, and don't change any existing string in `app_en.arb`.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix. Never run `dart format` on existing files or on
  directories; only on the two new files, as the steps say. No git commands (others commit in this tree).

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt
  (the codebase moved on since this plan was written), or `lib/core/route_title.dart` or
  `test/route_title_test.dart` already exists. Exceptions: in `lib/app.dart` only the lines
  `final appearance = ref.watch(appearanceProvider);`, `onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,`,
  `routerConfig: ref.watch(routerProvider),` and `builder: (context, child) =>` must match (another wrapper
  inside the builder is fine, see step 4); in `lib/main.dart` only `return MaterialApp(` must be there, with no
  `onGenerateTitle` or `title:` yet.
- Any `tabTitle…` key already exists in `app_en.arb`, or `flutter gen-l10n` reports an error.
- The router-wide check in the test fails for a route: a page was added or renamed since this plan was
  written. Report the route's template; don't guess a title for it.
- `flutter test` shows "setState() or markNeedsBuild() called during build" from `RouteTitle`, or any
  failure in `test/navigation_test.dart` or `test/phone_layout_test.dart` that the change caused.
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app
now and one place to open to see it. Not a list of files, the steps already
have those. For example: in the web build each tab now names its page ("Inbox · Casama",
"Memory · Ada · Casama", "Ada · Casama" for a chat), following every page opened or closed; the phone and
desktop apps are unchanged. To see it, run the web app, open Settings, then a bot's chat, and watch the tab.
