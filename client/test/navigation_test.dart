// Three places on every size (D-176): Chats, Inbox and Tasks. Settings sits behind the person's
// avatar, search beside the phone tab bar, and a bot's computer inside its chat.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/app.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/bots/bots_screen.dart';
import 'package:casama_app/features/search/search_view.dart';
import 'package:casama_app/features/settings/settings_screen.dart';
import 'package:casama_app/ui/floating_tab_chrome.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  await setSize(tester, size);
  await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(FakeBackend())], child: const CasamaApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phones have three tabs and a search button beside them', (tester) async {
    await _pumpApp(tester, const Size(400, 860));
    final bar = find.byType(FloatingTabChrome);
    for (final label in ['Chats', 'Inbox', 'Tasks']) {
      expect(
        find.descendant(of: bar, matching: find.text(label)),
        findsOneWidget,
        reason: label,
      );
    }
    for (final label in ['Bots', 'Board', 'Computer', 'Settings', 'Search']) {
      expect(
        find.descendant(of: bar, matching: find.text(label)),
        findsNothing,
        reason: label,
      );
    }

    // Search opens over the tabs, as Cmd/Ctrl+K does on larger windows.
    await tester.tap(find.byKey(const Key('tabSearch')));
    await tester.pumpAndSettle();
    expect(find.byType(SearchView), findsOneWidget);
    Navigator.of(tester.element(find.byType(SearchView))).pop();
    await tester.pumpAndSettle();

    // Tasks is a tab.
    await tester.tap(find.descendant(of: bar, matching: find.text('Tasks')));
    await tester.pumpAndSettle();
    expect(GoRouter.of(tester.element(find.byType(FloatingTabChrome))).state.uri.path, '/tasks');
  });

  testWidgets('on phones the avatar opens Settings full screen, and back returns to the chats', (tester) async {
    await _pumpApp(tester, const Size(400, 860));
    expect(find.text('Chats'), findsWidgets);
    await tester.tap(find.byKey(const Key('meButton')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    for (final section in ['Workspace', 'App', 'Connections', 'Sign-in & security']) {
      await tester.scrollUntilVisible(find.text(section), 200, scrollable: find.byType(Scrollable).last);
      expect(find.text(section), findsOneWidget, reason: section);
    }
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(BotsScreen), findsOneWidget);
  });

  testWidgets('a link straight to Settings or the computer on a phone still has a way back', (tester) async {
    await _pumpApp(tester, const Size(400, 860));
    for (final path in ['/settings', '/computer', '/search']) {
      GoRouter.of(tester.element(find.byType(BotsScreen))).go(path);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(BotsScreen), findsOneWidget, reason: path);
    }
  });

  testWidgets('tablets get a rail with the three places, search, and the avatar for Settings', (tester) async {
    await _pumpApp(tester, const Size(900, 1000));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(3));
    expect(find.byKey(const Key('railSearch')), findsOneWidget);
    await tester.tap(find.byKey(const Key('railMe')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex, isNull);
  });

  testWidgets('wide windows list Inbox, Tasks and the person under the chats; no Pages or Computer rows', (tester) async {
    await _pumpApp(tester, const Size(1600, 1000));
    expect(find.byKey(const Key('sidebar-nav-/inbox')), findsOneWidget);
    expect(find.byKey(const Key('sidebar-nav-/tasks')), findsOneWidget);
    expect(find.byKey(const Key('sidebarMe')), findsOneWidget);
    for (final gone in ['sidebarPages', 'sidebar-nav-/computer', 'sidebar-nav-/settings']) {
      expect(find.byKey(Key(gone)), findsNothing, reason: gone);
    }
    await tester.tap(find.byKey(const Key('sidebarMe')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
