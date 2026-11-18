// The shell on an iPhone Duo (D-411): the side strip on the outer screen, two panes that meet on
// the fold on the inner screen, and nothing lost when the device opens and closes.
import 'package:casama/app.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/bots/bots_screen.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/home/home_shell.dart';
import 'package:casama/features/settings/settings_screen.dart';
import 'package:casama/ui/floating_tab_chrome.dart';
import 'package:casama/ui/side_strip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';
import 'support/poses.dart';

final _iphone = TargetPlatformVariant.only(TargetPlatform.iOS);

Future<void> _pumpApp(WidgetTester tester, DuoPose pose) async {
  SharedPreferences.setMockInitialValues({});
  setPose(tester, pose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [backendProvider.overrideWithValue(FakeBackend())],
      child: const CasamaApp(),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(HomeShell)));
String _location(WidgetTester tester) => _router(tester).state.uri.path;

void main() {
  testWidgets(
    'closed: the tabs and the header buttons are in the strip, and the page keeps clear of it',
    (tester) async {
      await _pumpApp(tester, DuoPose.closed);
      expect(find.byType(FloatingTabChrome), findsNothing);
      expect(find.byType(StripTabs), findsOneWidget);
      // The page stops where the strip starts.
      expect(tester.getSize(find.byType(BotsScreen)).width, 466 - 84);
      // Search and new chat sit in the strip, under what iOS draws at its top and above the tabs.
      for (final key in ['tabSearch', 'createMenu', 'meButton']) {
        final at = tester.getRect(find.byKey(Key(key)));
        expect(at.left, greaterThanOrEqualTo(466 - 84), reason: key);
        expect(at.top, greaterThanOrEqualTo(124), reason: key);
        expect(
          at.bottom,
          lessThan(tester.getRect(find.byType(StripTabs)).top),
          reason: key,
        );
      }
      // The tabs work from there.
      await tester.tap(find.byKey(const Key('stripTab-2')));
      await _settle(tester);
      expect(_location(tester), '/tasks');
      await tester.tap(find.byKey(const Key('stripTab-0')));
      await _settle(tester);
      // A page opened from a tab: Back at the top of the strip, the tabs gone.
      _router(tester).go('/bots/$botId/chat');
      await _settle(tester);
      expect(find.byType(StripTabs), findsNothing);
      final back = tester.getRect(find.byTooltip('Back').hitTestable());
      expect(back.left, greaterThanOrEqualTo(466 - 84));
      expect(tester.getSize(find.byType(ChatScreen)).width, 466 - 84);
      await tester.tap(find.byTooltip('Back').hitTestable());
      await _settle(tester);
      expect(_location(tester), '/bots');
      expect(find.byType(StripTabs), findsOneWidget);
    },
    variant: _iphone,
  );

  testWidgets('tent: the strip is on the left', (tester) async {
    await _pumpApp(tester, DuoPose.tent);
    expect(find.byType(StripTabs), findsOneWidget);
    expect(tester.getRect(find.byType(StripTabs)).right, lessThanOrEqualTo(84));
    expect(tester.getRect(find.byType(BotsScreen)).left, 84);
    expect(
      tester.getRect(find.byKey(const Key('createMenu'))).right,
      lessThanOrEqualTo(84),
    );
  }, variant: _iphone);

  testWidgets(
    'open wide: the list and the last chat meet on the fold, with the strip beside them',
    (tester) async {
      await _pumpApp(tester, DuoPose.openWide);
      // The chats on the left, as wide as half the screen.
      final list = tester.getRect(find.byType(BotsScreen));
      expect(list.left, 0);
      expect(list.right, 475.5);
      // The last chat opened by itself beside it (D-383).
      expect(_location(tester), '/bots/$botId/chat');
      final chat = tester.getRect(find.byType(ChatScreen));
      expect(chat.left, 475.5);
      expect(chat.right, 951 - 84);
      // Beside its list the chat has no Back; it hides the list instead.
      expect(
        find.descendant(
          of: find.byType(ChatScreen),
          matching: find.byTooltip('Back'),
        ),
        findsNothing,
      );
      expect(
        tester.getRect(find.byKey(const Key('listPaneToggle'))).left,
        greaterThanOrEqualTo(951 - 84),
      );
      // The list keeps its own header; the tabs are in the strip.
      expect(
        tester.getRect(find.byKey(const Key('createMenu'))).right,
        lessThan(475.5),
      );
      expect(find.byType(StripTabs), findsOneWidget);
      expect(find.byType(FloatingTabChrome), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);

      // Hide the list: the chat has the whole screen, and the button brings the list back.
      await tester.tap(find.byKey(const Key('listPaneToggle')));
      await _settle(tester);
      expect(find.byType(BotsScreen), findsNothing);
      expect(tester.getRect(find.byType(ChatScreen)).left, 0);
      await tester.tap(find.byKey(const Key('listPaneToggle')));
      await _settle(tester);
      expect(find.byType(BotsScreen), findsOneWidget);

      // Settings: the list of settings on the left, a page on the right.
      await tester.tap(find.byKey(const Key('meButton')));
      await _settle(tester);
      expect(_location(tester), '/settings');
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.getRect(find.byType(SettingsScreen)).right, 475.5);
    },
    variant: _iphone,
  );

  testWidgets('book: the band around the fold stays empty', (tester) async {
    await _pumpApp(tester, DuoPose.book);
    expect(tester.getRect(find.byType(BotsScreen)).right, 455.5);
    expect(tester.getRect(find.byType(ChatScreen)).left, 495.5);
    // Each half keeps its pane: no hiding the list while the device is folded.
    expect(find.byKey(const Key('listPaneToggle')), findsNothing);
    // Folding and flattening moves the edge of each pane and nothing else.
    final chat = tester.state(find.byType(ChatScreen));
    setPose(tester, DuoPose.openWide);
    await _settle(tester);
    expect(tester.getRect(find.byType(BotsScreen)).right, 475.5);
    expect(tester.state(find.byType(ChatScreen)), same(chat));
  }, variant: _iphone);

  testWidgets(
    'opening and closing keeps the chat, what was typed, and the keyboard focus',
    (tester) async {
      await _pumpApp(tester, DuoPose.closed);
      _router(tester).go('/bots/$botId/chat');
      await _settle(tester);
      await tester.enterText(
        find.byKey(const Key('messageInput')),
        'half a thought',
      );
      await tester.pump();
      final chat = tester.state(find.byType(ChatScreen));

      for (final pose in [
        DuoPose.openWide,
        DuoPose.book,
        DuoPose.openTall,
        DuoPose.laptop,
        DuoPose.closed,
      ]) {
        setPose(tester, pose);
        await _settle(tester);
        expect(_location(tester), '/bots/$botId/chat', reason: pose.name);
        expect(
          tester.state(find.byType(ChatScreen)),
          same(chat),
          reason: pose.name,
        );
        expect(find.text('half a thought'), findsOneWidget, reason: pose.name);
      }
    },
    variant: _iphone,
  );

  testWidgets(
    'a chat the shell opened by itself goes back to the list when the device closes untouched',
    (tester) async {
      await _pumpApp(tester, DuoPose.closed);
      expect(_location(tester), '/bots');
      setPose(tester, DuoPose.openWide);
      await _settle(tester);
      expect(_location(tester), '/bots/$botId/chat');
      // The chats list is the same one, moved into the left pane.
      setPose(tester, DuoPose.closed);
      await _settle(tester);
      expect(_location(tester), '/bots');
      expect(find.byType(ChatScreen), findsNothing);

      // Touched, it is the person's own: closing stays in the chat.
      setPose(tester, DuoPose.openWide);
      await _settle(tester);
      await tester.tapAt(tester.getCenter(find.byType(ChatScreen)));
      await _settle(tester);
      setPose(tester, DuoPose.closed);
      await _settle(tester);
      expect(_location(tester), '/bots/$botId/chat');
    },
    variant: _iphone,
  );

  testWidgets('split view and open tall are the phone layout', (tester) async {
    for (final pose in [DuoPose.splitView, DuoPose.openTall]) {
      await _pumpApp(tester, pose);
      expect(find.byType(FloatingTabChrome), findsOneWidget, reason: pose.name);
      expect(find.byType(StripTabs), findsNothing, reason: pose.name);
      expect(
        tester.getSize(find.byType(BotsScreen)).width,
        pose.size.width,
        reason: pose.name,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
    }
  }, variant: _iphone);

  testWidgets(
    'without a fold or a strip, a mid-width window gets the rail and two panes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [backendProvider.overrideWithValue(FakeBackend())],
          child: const CasamaApp(),
        ),
      );
      await _settle(tester);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(StripTabs), findsNothing);
      final list = tester.getRect(find.byType(BotsScreen));
      expect(list.width, 360);
      expect(
        tester.getRect(find.byType(ChatScreen)).left,
        closeTo(list.right, 1.5),
      );
      expect(tester.getRect(find.byType(ChatScreen)).right, 900);
      // The rail has search and the avatar, so the list's header doesn't repeat them.
      expect(find.byKey(const Key('tabSearch')), findsNothing);
    },
  );
}
