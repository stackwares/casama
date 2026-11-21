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

Future<void> _pumpCard(WidgetTester tester, {ChatState? state}) async {
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
            child: ScreenCard(botId: _bot, botName: 'Ava', computerId: 'pc-1', layout: LayoutSize.phone, onOpen: _opened.add),
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
}
