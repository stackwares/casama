import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_app/core/backend.dart';
import 'package:kasama_app/core/providers.dart';
import 'package:kasama_app/core/voice.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';
import 'package:kasama_app/features/voice/call_screen.dart';
import 'package:kasama_app/l10n/generated/app_localizations.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';
import 'fake_voice.dart';

Widget voiceHarness(FakeBackend backend, {FakeDictation? dictation, FakePlayer? player, FakeCallConnector? calls, required Widget home}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    GoRoute(path: '/bots/:id/chat', builder: (_, s) => Text('chat ${s.uri.queryParameters['c']}')),
    GoRoute(path: '/bots/:id/call', builder: (_, s) => Text('call ${s.uri.queryParameters['c']}')),
  ]);
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      if (dictation != null) dictationProvider.overrideWithValue(dictation),
      if (player != null) speechPlayerProvider.overrideWithValue(player),
      if (calls != null) voiceCallConnectorProvider.overrideWithValue(calls),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('dictation records, transcribes and fills the message box', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    final dictation = FakeDictation();
    await tester.pumpWidget(voiceHarness(backend, dictation: dictation, home: const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dictateButton')));
    await tester.pump();
    expect(dictation.started, 1);
    await tester.tap(find.byKey(const Key('dictateButton')));
    await tester.pumpAndSettle();
    expect(backend.transcribed, ['audio/wav']);
    expect(tester.widget<TextField>(find.byKey(const Key('messageInput'))).controller!.text, 'water the plants');
  });

  testWidgets('bot messages can be read aloud', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()
      ..storedMessages = [ChatMessageView(id: 'msg-1', role: 'assistant', text: 'Water the fern.', createdAt: DateTime(2026))];
    final player = FakePlayer();
    await tester.pumpWidget(voiceHarness(backend, player: player, home: const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('speak-msg-1')));
    await tester.pumpAndSettle();
    expect(backend.spoken, ['msg-1']);
    expect(player.played, [3]);
  });

  testWidgets('a live call forwards tool calls, shows reply latency and saves the transcript', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    final calls = FakeCallConnector();
    await tester.pumpWidget(voiceHarness(backend, calls: calls, home: const CallScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    expect(calls.session?.clientSecret, 'ek_test');
    expect(find.text('Live'), findsOneWidget);

    calls.call.say('user', 'What do you know about my plants?');
    calls.call.askTool('call-1', 'memory__search');
    await tester.pumpAndSettle();
    expect(backend.voiceTools, ['memory__search']);
    expect(calls.call.results['call-1'], 'Found 2 memories');
    calls.call.reply(640);
    calls.call.say('assistant', 'You water the fern on Fridays.');
    await tester.pumpAndSettle();
    expect(find.text('Reply started in 640 ms'), findsOneWidget);
    expect(find.text('You water the fern on Fridays.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('muteButton')));
    await tester.pump();
    expect(calls.call.muted, isTrue);
    await tester.tap(find.byKey(const Key('hangUpButton')));
    await tester.pumpAndSettle();
    expect(calls.call.hungUp, isTrue);
    expect(backend.savedTurns, [('user', 'What do you know about my plants?'), ('assistant', 'You water the fern on Fridays.')]);
    expect(find.text('chat $convId'), findsOneWidget);
  });
}
