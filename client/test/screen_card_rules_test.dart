// When the screen card shows and hides (SCREEN-CARD-PLAN §4): only for screen steps, from the
// second one or a long look; "Done" for a moment after a good reply; closed for one reply only;
// off with the setting; dimmed, then hidden, when pictures stop; never fetching when not wanted.
import 'dart:typed_data';

import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/chat/chat_controller.dart';
import 'package:casama/features/chat/chat_detail.dart';
import 'package:casama/features/chat/widgets/screen_card.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/theme/app_theme.dart';
import 'package:casama/ui/screen_tile.dart';
import 'package:casama/ui/shell_layout.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

const _bot = 'bot-1';

class _Chat extends ChatController {
  _Chat(super.botId);
  static ChatState initial = const ChatState();

  @override
  ChatState build() => initial;

  void set(ChatState s) => state = s;
}

// A 1×1 PNG, enough for Image.memory.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

const _ask = MessageEntry(id: 'u1', role: 'user', text: 'book it');

ToolEntry _step(String id, {String tool = 'browser.click', ToolStatus status = ToolStatus.done}) =>
    ToolEntry(callId: id, tool: tool, args: const {}, status: status);

ChatState _running(List<ChatEntry> entries) => ChatState(entries: [_ask, ...entries], activeRunId: 'run-1');
ChatState _ended(List<ChatEntry> entries) => ChatState(entries: [_ask, ...entries]);

late FakeBackend _fake;
late ProviderContainer _container;
final _opened = <String>[];

Future<void> _pumpCard(WidgetTester tester, {ChatState? state, bool group = false}) async {
  _Chat.initial = state ?? const ChatState();
  _container = ProviderContainer(overrides: [backendProvider.overrideWithValue(_fake), chatControllerProvider.overrideWith2(_Chat.new)]);
  addTearDown(_container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 700,
            child: ScreenCard(
              botId: _bot,
              botName: group ? 'Trip team' : 'Ava',
              computerId: 'pc-1',
              layout: LayoutSize.phone,
              onOpen: _opened.add,
              computerFor: group ? (id) => 'pc-$id' : null,
              faceFor: group ? (id) => SizedBox(key: Key('face-$id'), width: 18, height: 18) : null,
              nameFor: group ? (id) => id == 'mia' ? 'Mia' : 'Ava' : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void _set(ChatState s) => (_container.read(chatControllerProvider(_bot).notifier) as _Chat).set(s);

bool _visible(WidgetTester tester) {
  final opacity = tester.widget<AnimatedOpacity>(
    find.ancestor(of: find.byKey(const Key('screenCard')), matching: find.byType(AnimatedOpacity)).first,
  );
  return opacity.opacity == 1;
}

ScreenTileState _state(WidgetTester tester) => tester.widget<ScreenTile>(find.byKey(const Key('screenCard'))).state;

/// Lets a fetch and its frame land.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _fake = FakeBackend()..screen = _png;
    _opened.clear();
  });

  testWidgets('one quick screen step: no card and no fetching; the second step shows it', (tester) async {
    await _pumpCard(tester);
    _set(_running([_step('a')]));
    await _settle(tester);
    expect(_visible(tester), isFalse);
    expect(_fake.screenPictureCalls, isEmpty);

    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    expect(_visible(tester), isTrue);
    expect(_state(tester), ScreenTileState.watching);
    expect(_fake.screenPictureCalls, ['pc-1']);

    // About one picture a second while it shows.
    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    expect(_fake.screenPictureCalls.length, 2);
  });

  testWidgets('one screen step that runs past 2 seconds shows it', (tester) async {
    await _pumpCard(tester);
    _set(_running([_step('a', status: ToolStatus.running)]));
    await _settle(tester);
    expect(_visible(tester), isFalse);
    await tester.pump(const Duration(milliseconds: 2100));
    await _settle(tester);
    expect(_visible(tester), isTrue);
  });

  testWidgets('terminal and file steps never show it', (tester) async {
    await _pumpCard(tester);
    _set(
      _running([
        _step('a', tool: 'shell.run'),
        _step('b', tool: 'files.write'),
        _step('c', tool: 'desktop.files_search', status: ToolStatus.running),
      ]),
    );
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    expect(_visible(tester), isFalse);
    expect(_fake.screenPictureCalls, isEmpty);
  });

  testWidgets('a good reply says Done for 3 seconds, then hides; a failed one hides at once', (tester) async {
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 7)); // past the minimum time shown
    await _settle(tester);
    _set(_ended([_step('a'), _step('b')]));
    await _settle(tester);
    expect(_visible(tester), isTrue);
    expect(_state(tester), ScreenTileState.done);
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    expect(_visible(tester), isFalse);

    // The next reply fails.
    const ask2 = MessageEntry(id: 'u2', role: 'user', text: 'again');
    _set(ChatState(entries: [ask2, _step('c'), _step('d')], activeRunId: 'run-2'));
    await _settle(tester);
    expect(_visible(tester), isTrue);
    _set(
      ChatState(
        entries: [
          ask2,
          _step('c'),
          _step('d'),
          const NoticeEntry(kind: NoticeKind.failed, text: 'x'),
        ],
      ),
    );
    await _settle(tester);
    expect(_visible(tester), isFalse);
  });

  testWidgets('screen readers get one node the size of the card, with Hide as an action', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    final node = tester.getSemantics(find.byKey(const Key('screenCard')));
    expect(node.label, contains('Ava'));
    // Found on Android: it used to merge into the full-screen layer, so TalkBack framed the chat.
    final tile = tester.getRect(find.byKey(const Key('screenTile')));
    expect(node.rect.width, closeTo(tile.width, 1));
    expect(node.rect.height, closeTo(tile.height, 1));

    final hide = CustomSemanticsAction.getIdentifier(CustomSemanticsAction(label: lookupAppLocalizations(const Locale('en')).callTileHide));
    expect(node.getSemanticsData().customSemanticsActionIds, contains(hide));
    tester.binding.performSemanticsAction(
      SemanticsActionEvent(type: SemanticsAction.customAction, viewId: tester.view.viewId, nodeId: node.id, arguments: hide),
    );
    await _settle(tester);
    expect(_visible(tester), isFalse);
    handle.dispose();
  });

  testWidgets('closing hides it for this reply only', (tester) async {
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('screenTileClose')));
    await _settle(tester);
    expect(_visible(tester), isFalse);
    _set(_running([_step('a'), _step('b'), _step('c')]));
    await _settle(tester);
    expect(_visible(tester), isFalse);

    const ask2 = MessageEntry(id: 'u2', role: 'user', text: 'next');
    _set(ChatState(entries: [_ask, _step('a'), ask2, _step('x'), _step('y')], activeRunId: 'run-2'));
    await _settle(tester);
    expect(_visible(tester), isTrue);
  });

  testWidgets('the setting turns it off', (tester) async {
    await _pumpCard(tester);
    _container.read(showScreenCardProvider.notifier).set(false);
    _set(_running([_step('a'), _step('b')]));
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    expect(_visible(tester), isFalse);
    expect(_fake.screenPictureCalls, isEmpty);
  });

  testWidgets('pictures stop: dimmed at 8 seconds, hidden at 20', (tester) async {
    await _pumpCard(tester);
    var calls = 0;
    _fake.onScreenPicture = (_, _) => calls++ == 0
        ? ScreenPicture(ScreenPictureStatus.fresh, bytes: _png, etag: '"s-1"')
        : const ScreenPicture(ScreenPictureStatus.failed);
    // Steps keep coming, so the bot hasn't moved on.
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    expect(_state(tester), ScreenTileState.watching);
    for (var i = 0; i < 9; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    _set(_running([_step('a'), _step('b'), _step('c')]));
    await _settle(tester);
    expect(_visible(tester), isTrue);
    expect(_state(tester), ScreenTileState.stale);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await _settle(tester);
    expect(_visible(tester), isFalse);
  });

  testWidgets('a takeover request shows it at once as needing you, on the named computer', (tester) async {
    await _pumpCard(tester);
    _set(_running([const TakeoverEntry(computerId: 'pc-2', reason: 'sign in')]));
    await _settle(tester);
    expect(_visible(tester), isTrue);
    expect(_state(tester), ScreenTileState.needsYou);
    expect(_fake.screenPictureCalls.last, 'pc-2');
    await tester.tap(find.byKey(const Key('screenCard')));
    expect(_opened, ['pc-2']);
  });

  testWidgets('a sleeping computer shows nothing', (tester) async {
    _fake.screen = null;
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    expect(_visible(tester), isFalse);
    expect(_fake.screenPictureCalls, isNotEmpty);
  });

  // Phase 2 (SCREEN-CARD-PLAN §3, §5, §6).

  testWidgets('a held screen keeps its last picture, paused: no fetching, no dimming, no hiding', (tester) async {
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    _set(_running([_step('a'), _step('b'), const NoticeEntry(kind: NoticeKind.userControl, text: '', refId: 'pc-1')]));
    await _settle(tester);
    expect(_state(tester), ScreenTileState.held);
    expect(find.text('You have the screen'), findsOneWidget);
    final calls = _fake.screenPictureCalls.length;
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(_fake.screenPictureCalls.length, calls);
    expect(_visible(tester), isTrue);
    expect(_state(tester), ScreenTileState.held);

    // Handed back: pictures again.
    _set(
      _running([
        _step('a'),
        _step('b'),
        const NoticeEntry(kind: NoticeKind.userControl, text: '', refId: 'pc-1'),
        const NoticeEntry(kind: NoticeKind.botControl, text: '', refId: 'pc-1'),
      ]),
    );
    await _settle(tester);
    expect(_state(tester), ScreenTileState.watching);
    expect(_fake.screenPictureCalls.length, greaterThan(calls));
  });

  testWidgets('needs you is announced to screen readers once, and nothing else is', (tester) async {
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeAnnouncements(), isEmpty);
    _set(_running([_step('a'), _step('b'), const TakeoverEntry(computerId: 'pc-1', reason: 'sign in')]));
    await _settle(tester);
    expect(_state(tester), ScreenTileState.needsYou);
    final said = tester.takeAnnouncements();
    expect(said.map((a) => a.message), ['Ava needs you on the screen']);
    await tester.pump(const Duration(seconds: 2));
    await _settle(tester);
    expect(tester.takeAnnouncements(), isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the first time ever, a line says what it is for four seconds; never again', (tester) async {
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    await _settle(tester);
    expect(find.text("Ava's screen. Tap to watch, drag to move."), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await _settle(tester);
    expect(find.byKey(const Key('screenCardIntro')), findsNothing);

    // A new chat on the same device: no line.
    await tester.pumpWidget(const SizedBox());
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    await _settle(tester);
    expect(_visible(tester), isTrue);
    expect(find.byKey(const Key('screenCardIntro')), findsNothing);
  });

  testWidgets('closed on three replies in a row: a toast offers to turn it off', (tester) async {
    await _pumpCard(tester);
    for (var r = 1; r <= 3; r++) {
      final ask = MessageEntry(id: 'u$r', role: 'user', text: 'go');
      _set(ChatState(entries: [ask, _step('a$r'), _step('b$r')], activeRunId: 'run-$r'));
      await _settle(tester);
      expect(_visible(tester), isTrue, reason: 'reply $r');
      await tester.tap(find.byKey(const Key('screenTileClose')));
      await _settle(tester);
      await _settle(tester);
      if (r < 3) expect(find.text('Hiding the screen card a lot? You can turn it off.'), findsNothing);
    }
    expect(find.text('Hiding the screen card a lot? You can turn it off.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600)); // the toast slides in
    await tester.tap(find.text('Turn Off'));
    await _settle(tester);
    expect(_container.read(showScreenCardProvider), isFalse);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('a reply watched to the end starts the closes over', (tester) async {
    SharedPreferences.setMockInitialValues({'screenCard.closesInARow': 2});
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    _set(_ended([_step('a'), _step('b')]));
    await _settle(tester);
    expect((await SharedPreferences.getInstance()).getInt('screenCard.closesInARow'), 0);
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('long press: Hide for Now hides this reply; Don\'t Show Automatically turns it off', (tester) async {
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    await tester.longPress(find.byKey(const Key('screenCard')));
    await tester.pumpAndSettle();
    expect(find.text('Open full screen'), findsOneWidget);
    await tester.tap(find.text('Hide for Now'));
    await tester.pumpAndSettle();
    expect(_visible(tester), isFalse);
    expect(_container.read(showScreenCardProvider), isTrue);

    const ask2 = MessageEntry(id: 'u2', role: 'user', text: 'next');
    _set(ChatState(entries: [ask2, _step('x'), _step('y')], activeRunId: 'run-2'));
    await _settle(tester);
    expect(_visible(tester), isTrue);
    await tester.longPress(find.byKey(const Key('screenCard')));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Don't Show Automatically"));
    await tester.pumpAndSettle();
    expect(_container.read(showScreenCardProvider), isFalse);
    expect(_visible(tester), isFalse);
    expect(find.text('The screen card is off. Turn it back on in Settings.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('a group chat follows the bot on its screen, with its face and name', (tester) async {
    await _pumpCard(tester, group: true);
    _set(
      _running([
        const ToolEntry(callId: 'a', tool: 'browser.open', args: {}, status: ToolStatus.done, botId: 'mia'),
        const ToolEntry(callId: 'b', tool: 'browser.click', args: {}, status: ToolStatus.done, botId: 'mia'),
      ]),
    );
    await _settle(tester);
    expect(_visible(tester), isTrue);
    expect(_fake.screenPictureCalls.last, 'pc-mia');
    expect(find.byKey(const Key('face-mia')), findsOneWidget);
    expect(tester.widget<ScreenTile>(find.byKey(const Key('screenCard'))).botName, 'Mia');
    await tester.tap(find.byKey(const Key('screenCard')));
    expect(_opened, ['pc-mia']);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('with Reduce Motion on, it only fades', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pumpCard(tester);
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    final scale = tester.widget<AnimatedScale>(
      find.ancestor(of: find.byKey(const Key('screenCard')), matching: find.byType(AnimatedScale)).first,
    );
    expect(scale.scale, 1);
    expect(scale.duration, Duration.zero);
    expect(_visible(tester), isTrue);
  });

  testWidgets('an unexpected error fetching a picture keeps it asking', (tester) async {
    await _pumpCard(tester);
    _fake.onScreenPicture = (_, _) => throw StateError('boom');
    _set(_running([_step('a'), _step('b')]));
    await _settle(tester);
    expect(_fake.screenPictureCalls.length, 1);
    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    expect(_fake.screenPictureCalls.length, 2);
    expect(_visible(tester), isFalse);
  });
}
