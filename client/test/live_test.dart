import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:casama_app/core/live.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/computer/computer_screen.dart';
import 'package:casama_app/features/computer/computers_screen.dart';
import 'package:casama_app/features/computer/live_view_screen.dart';
import 'package:casama_app/features/inbox/inbox_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';
import 'fake_live.dart';

Widget liveHarness(FakeBackend backend, FakeLiveConnector live, Widget child) => ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend), liveConnectorProvider.overrideWithValue(live)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

TakeoverRequest takeoverFor() => TakeoverRequest(
      id: 'tk1',
      botId: botId,
      runId: runId,
      computerId: computerId,
      reason: 'Please sign in to the site',
      status: TakeoverRequestStatusEnum.pending,
      note: null,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now(),
    );

void main() {
  group('Neko input protocol', () {
    test('frames are op, big-endian length, payload', () {
      expect(NekoInput.move(321, 234), [0x01, 0, 4, 0x01, 0x41, 0x00, 0xea]);
      expect(NekoInput.button(1, down: true), [0x05, 0, 4, 0, 0, 0, 1]);
      expect(NekoInput.key(0xff0d, down: false), [0x04, 0, 4, 0, 0, 0xff, 0x0d]);
      expect(NekoInput.scroll(0, -3), [0x02, 0, 5, 0, 0, 0xff, 0xfd, 0]);
    });

    test('keys map to X11 keysyms', () {
      expect(keysymFor(LogicalKeyboardKey.enter), 0xff0d);
      expect(keysymFor(LogicalKeyboardKey.arrowLeft), 0xff51);
      expect(keysymFor(LogicalKeyboardKey.f5), 0xffc2);
      expect(keysymFor(LogicalKeyboardKey.keyA, character: 'a'), 0x61);
      expect(keysymFor(LogicalKeyboardKey.keyA, character: 'é'), 0xe9);
      expect(keysymFor(LogicalKeyboardKey.keyA, character: '€'), 0x010020ac);
    });
  });

  testWidgets('live view: take control, click, type and hand back with a note', (tester) async {
    await setSize(tester, const Size(900, 900));
    final backend = FakeBackend();
    final live = FakeLiveConnector();
    await tester.pumpWidget(liveHarness(backend, live, const LiveViewScreen(computerId: computerId)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(live.session?.mode, StreamMode.control);
    expect(find.textContaining('Bot in control'), findsOneWidget);

    await tester.tap(find.byKey(const Key('takeControl')));
    await tester.pump();
    await tester.pump();
    expect(backend.leaseHeld, isTrue);
    expect(live.connection.controlRequests, 1);
    // In control: the dock holds the tools and Hand Back; the privacy note shows once.
    expect(find.byKey(const Key('handBack')), findsOneWidget);
    expect(find.byKey(const Key('liveCopy')), findsOneWidget);
    expect(find.textContaining('nothing you type or see is sent'), findsOneWidget);

    // A tap in the middle of the surface clicks the middle of the remote screen.
    await tester.tap(find.byKey(const Key('liveSurface')));
    await tester.pump();
    final ops = live.connection.sent.map((f) => f[0]).toList();
    expect(ops, containsAllInOrder([NekoInput.opMove, NekoInput.opButtonDown, NekoInput.opButtonUp]));
    final move = live.connection.sent.firstWhere((f) => f[0] == NekoInput.opMove);
    final x = (move[3] << 8) | move[4];
    final y = (move[5] << 8) | move[6];
    expect((x - 640).abs(), lessThan(4));
    expect((y - 400).abs(), lessThan(4));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(live.connection.sent.where((f) => f[0] == NekoInput.opKeyDown).isNotEmpty, isTrue);

    await tester.tap(find.byKey(const Key('handBack')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('handBackNote')), 'I signed in');
    await tester.tap(find.byKey(const Key('confirmHandBack')));
    await tester.pump();
    await tester.pump();
    expect(backend.releasedNote, 'I signed in');
    expect(live.connection.releases, 1);
    expect(find.byKey(const Key('takeControl')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('live view falls back to screenshots and shows latency', (tester) async {
    final backend = FakeBackend();
    final live = FakeLiveConnector();
    await tester.pumpWidget(liveHarness(backend, live, const LiveViewScreen(computerId: computerId)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('12 ms'), findsOneWidget);
    live.connection.goFallback();
    await tester.pump();
    expect(find.textContaining('Screenshots'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a takeover request shows in the live view and can be dismissed', (tester) async {
    final backend = FakeBackend()..openTakeovers = [takeoverFor()];
    final live = FakeLiveConnector();
    await tester.pumpWidget(liveHarness(backend, live, const LiveViewScreen(computerId: computerId, takeoverId: 'tk1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('takeoverBanner')), findsOneWidget);
    expect(find.textContaining('Please sign in to the site'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pump();
    await tester.pump();
    expect(backend.dismissed, ['tk1']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the inbox lists takeover requests first', (tester) async {
    final backend = FakeBackend()..openTakeovers = [takeoverFor()];
    await tester.pumpWidget(harness(backend, const InboxScreen(initialFilter: InboxFilter.needsYou)));
    await tester.pumpAndSettle();
    expect(find.text('Ada needs your help'), findsOneWidget);
    expect(find.byKey(const Key('openTakeover')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dismissTakeover')));
    await tester.pumpAndSettle();
    expect(backend.dismissed, ['tk1']);
  });

  testWidgets('chat shows takeover requests and pause notices from run events', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageInput')), 'sign in to the site');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    backend.runEventsController
      ..add(ev(1, 'lease.changed', {'computer_id': computerId, 'holder_type': 'user', 'mode': 'control'}))
      ..add(ev(2, 'lease.changed', {'computer_id': computerId, 'holder_type': 'bot', 'mode': 'control'}))
      ..add(ev(3, 'takeover.requested', {'computer_id': computerId, 'reason': 'Please sign in to the site'}));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('a person is in control'), findsOneWidget);
    expect(find.text('The bot is back in control'), findsOneWidget);
    expect(find.byKey(const Key('chatTakeover')), findsOneWidget);
    expect(find.byKey(const Key('chatTakeControl')), findsOneWidget);
    backend.runEventsController.add(ev(4, 'takeover.resolved', {'computer_id': computerId, 'outcome': 'completed', 'note': 'Done'}));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Handed back'), findsOneWidget);
    expect(find.byKey(const Key('chatTakeControl')), findsNothing);
  });

  testWidgets('computers: create a private desktop computer and switch a profile', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ComputersScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Team computer'), findsWidgets);

    await tester.tap(find.byKey(const Key('newComputer')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('computerName')), 'Ada desktop');
    await tester.tap(find.byKey(const Key('computerDesktop')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createComputer')));
    await tester.pumpAndSettle();
    expect(backend.createdComputers, ['Ada desktop:desktop:$botId']);

    await tester.tap(find.byKey(const Key('computerMenu-$computerId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch to Desktop'));
    await tester.pumpAndSettle();
    expect(backend.computerUpdates, ['desktop']);

    // Team computers: how many bots use the desktop at once (D-148).
    await tester.tap(find.byKey(const Key('computerMenu-$computerId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desktop users at once'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('desktops-3')));
    await tester.pumpAndSettle();
    expect(backend.computerUpdates, ['desktop', 'desktops:3']);
  });

  testWidgets('side panel: the live view plays inline, opens full screen and comes back', (tester) async {
    await setSize(tester, const Size(1300, 900));
    final backend = _AwakeDesktop();
    final live = FakeLiveConnector();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: SizedBox(width: 420, child: ComputerScreen(embedded: true)))),
      GoRoute(path: '/computer/live', builder: (_, s) => LiveViewScreen(computerId: s.uri.queryParameters['c']!)),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend), liveConnectorProvider.overrideWithValue(live)],
      child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Already running: the panel waits until the person opens the live view.
    expect(find.byKey(const Key('liveSurface')), findsNothing);
    expect(live.session, isNull);
    expect(find.byKey(const Key('openLiveView')), findsOneWidget);

    await tester.tap(find.byKey(const Key('openLiveView')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Inline: the stream is open in the panel, with control and a full-screen button.
    expect(find.byKey(const Key('liveSurface')), findsOneWidget);
    expect(find.byKey(const Key('takeControl')), findsOneWidget);
    expect(live.session?.mode, StreamMode.control);

    await tester.tap(find.byKey(const Key('liveExpand')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Full screen: one stream (the panel steps aside), and a way back to the panel.
    expect(find.byKey(const Key('liveSurface')), findsOneWidget);
    expect(find.byKey(const Key('liveMinimize')), findsOneWidget);

    await tester.tap(find.byKey(const Key('liveMinimize')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('liveExpand')), findsOneWidget);
  });
  testWidgets('live view on a phone: rotate hint upright, controls beside the screen sideways', (tester) async {
    final backend = FakeBackend();
    final live = FakeLiveConnector();
    await setSize(tester, const Size(390, 844));
    await tester.pumpWidget(liveHarness(backend, live, const LiveViewScreen(computerId: computerId)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('liveRotateHint')), findsOneWidget);
    expect(find.byType(AppBar), findsWidgets);

    // Sideways: no header, the tools in the bar beside the screen, nothing over it.
    await setSize(tester, const Size(844, 390));
    await tester.pump();
    expect(find.byKey(const Key('liveRotateHint')), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    await tester.tap(find.byKey(const Key('takeControl')));
    await tester.pump();
    await tester.pump();
    expect(backend.leaseHeld, isTrue);
    for (final k in ['liveKeyboard', 'liveRightClick', 'livePaste', 'liveCopy', 'handBack', 'liveMore', 'liveStatus']) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    // Save Screenshot waits behind ⋯.
    await tester.tap(find.byKey(const Key('liveMore')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('liveScreenshot')), findsOneWidget);
    expect(find.byKey(const Key('teachStart')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  // D-218: the app offers only what a personal computer can do.
  testWidgets('a personal computer shows screenshots, not live view, terminal, checkpoints or sleep', (tester) async {
    await setSize(tester, const Size(1300, 900));
    final backend = _PersonalComputer();
    Future<void> show(ComputerState state) async {
      await tester.pumpWidget(liveHarness(
        backend,
        FakeLiveConnector(),
        Scaffold(body: SizedBox(width: 420, child: ComputerPanel(key: ValueKey(state), computer: _personal(state), embedded: true))),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    await show(ComputerState.running);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.textContaining('a new screenshot every few seconds'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    for (final gone in ['openLiveView', 'liveSurface', 'computerSleep', 'computerStart', 'openComputerSettings']) {
      expect(find.byKey(Key(gone)), findsNothing, reason: gone);
    }
    expect(find.text('Terminal'), findsNothing);
    expect(find.text('Checkpoints'), findsNothing);
    expect(find.byIcon(LucideIcons.slidersHorizontal), findsNothing);

    await show(ComputerState.stopped);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.byKey(const Key('personalOffline')), findsOneWidget);
    expect(find.text('Files'), findsNothing);
    expect(find.byKey(const Key('computerStart')), findsNothing);
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('the computers list offers no live view or desktop switch on a personal computer', (tester) async {
    await setSize(tester, const Size(600, 1000));
    await tester.pumpWidget(harness(_PersonalComputer(), const ComputersScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('local'), findsNothing);
    await tester.tap(find.byKey(const Key('computerMenu-$computerId')));
    await tester.pumpAndSettle();
    expect(find.text('Live view'), findsNothing);
    expect(find.text('Switch to Headless'), findsNothing);
    expect(find.text('Rename'), findsOneWidget);
  });

  testWidgets('live view quick actions: paste and copy go through the clipboard; Enter on the phone keyboard sends Return', (tester) async {
    await setSize(tester, const Size(900, 900));
    String? deviceClipboard = 'from my phone';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') deviceClipboard = (call.arguments as Map)['text'] as String?;
      if (call.method == 'Clipboard.getData') return {'text': deviceClipboard};
      return null;
    });
    final backend = FakeBackend();
    final live = FakeLiveConnector();
    await tester.pumpWidget(liveHarness(backend, live, const LiveViewScreen(computerId: computerId)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('takeControl')));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('livePaste')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(live.connection.clipboardSet, ['from my phone']);
    // Ctrl+V: Control down, v down, v up, Control up.
    final keys = live.connection.sent.where((f) => f[0] == NekoInput.opKeyDown).map((f) => (f[5] << 8) | f[6]).toList();
    expect(keys, containsAllInOrder([0xffe3, 0x76]));

    await tester.tap(find.byKey(const Key('liveCopy')));
    await tester.pump(const Duration(milliseconds: 50));
    live.connection.remote.value = 'copied on the computer';
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    expect(deviceClipboard, 'copied on the computer');

    // The phone keyboard: Enter types Return, and Backspace still works on an "empty" field.
    live.connection.sent.clear();
    final field = tester.widget<TextField>(find.byKey(const Key('liveTyping')));
    field.onChanged!('\u200bhi\n');
    field.onChanged!('');
    final downs = live.connection.sent.where((f) => f[0] == NekoInput.opKeyDown).map((f) => (f[5] << 8) | f[6]).toList();
    expect(downs, [0x68, 0x69, 0xff0d, 0xff08]);
  });
}

Computer _personal(ComputerState state) => Computer(
      id: computerId,
      orgId: orgId,
      kind: ComputerKindEnum.local,
      name: 'Work laptop',
      ownerBotId: null,
      lastActiveAt: null,
      error: null,
      provider: 'local',
      profile: ComputerProfileEnum.desktop,
      state: state,
      size: ComputerSize(cpus: 1),
      hasSnapshot: false,
      maxDesktops: 1,
      createdAt: DateTime(2026),
    );

class _PersonalComputer extends FakeBackend {
  ComputerState state = ComputerState.running;
  @override
  Future<List<Computer>> computers(String orgId) async => [_personal(state)];
}

class _AwakeDesktop extends FakeBackend {
  @override
  Future<List<Computer>> computers(String orgId) async => [
    for (final c in await super.computers(orgId)) c.copyWith(profile: ComputerProfileEnum.desktop, state: ComputerState.running),
  ];
}
