import 'dart:typed_data';

import 'package:dio/dio.dart' show DioException, RequestOptions, Response;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/device_dictation.dart';
import 'package:casama_app/core/dictation_bytes_io.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/voice.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/voice/call_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';
import 'fake_voice.dart';

Widget voiceHarness(FakeBackend backend, {FakeDictation? dictation, FakeDeviceDictation? device, FakePlayer? player, FakeCallConnector? calls, required Widget home}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    GoRoute(path: '/bots/:id/chat', builder: (_, s) => Text('chat ${s.uri.queryParameters['c']}')),
    GoRoute(path: '/bots/:id/call', builder: (_, s) => Text('call ${s.uri.queryParameters['c']}')),
    GoRoute(path: '/settings/keys', builder: (_, s) => Text('keys ${s.uri.queryParameters['provider']}')),
  ]);
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      if (dictation != null) dictationProvider.overrideWithValue(dictation),
      deviceDictationProvider.overrideWithValue(device ?? FakeDeviceDictation()),
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

DioException transcribeProblem(int status, String code, String detail) {
  final req = RequestOptions(path: '/v1/voice/transcribe');
  return DioException(
    requestOptions: req,
    response: Response(
      requestOptions: req,
      statusCode: status,
      data: {'type': 'about:blank', 'title': 'Conflict', 'status': status, 'code': code, 'detail': detail},
    ),
  );
}

String messageText(WidgetTester tester) => tester.widget<TextField>(find.byKey(const Key('messageInput'))).controller!.text;

/// Lets async work and short animations run. Not pumpAndSettle: the mic pulses while it listens.
Future<void> settleSome(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapMic(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('dictateButton')));
  await settleSome(tester);
}

void main() {
  CallScreen.motion = false;
  ChatScreen.dictationRetryDelay = Duration.zero;

  group('dictation falls back without dead ends', () {
    final failed = transcribeProblem(409, 'transcription_failed', "Couldn't turn that recording into text.");
    final noService = transcribeProblem(409, 'dictation_unavailable', 'Add an OpenAI or Deepgram key to use dictation.');
    Widget chat(FakeBackend backend, FakeDictation dictation, FakeDeviceDictation device) =>
        voiceHarness(backend, dictation: dictation, device: device, home: const ChatScreen(botId: botId, conversationId: convId));

    testWidgets('a clip the service chokes on once is retried quietly', (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend()..transcribeErrors.add(failed);
      await tester.pumpWidget(chat(backend, FakeDictation(), FakeDeviceDictation()));
      await tester.pumpAndSettle();
      await tapMic(tester);
      await tapMic(tester);
      expect(backend.transcribed, ['audio/wav', 'audio/wav']);
      expect(messageText(tester), 'water the plants');
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('after two failures, Say it again listens on the device and types words live', (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend()..transcribeErrors.addAll([failed, failed]);
      final dictation = FakeDictation();
      final device = FakeDeviceDictation();
      await tester.pumpWidget(chat(backend, dictation, device));
      await tester.pumpAndSettle();
      await tapMic(tester);
      await tapMic(tester);
      expect(backend.transcribed, hasLength(2));
      expect(find.textContaining('your device will listen'), findsOneWidget);

      await tester.tap(find.text('Say it again'));
      await settleSome(tester);
      expect(device.started, 1);
      expect(dictation.started, 1, reason: 'the recorder is not used while the device listens');
      device.onWords!('water');
      await tester.pump();
      expect(messageText(tester), 'water');
      device.onWords!('water the fern');
      await tester.pump();
      expect(messageText(tester), 'water the fern');
      await tapMic(tester); // stop
      expect(messageText(tester), 'water the fern');
      expect(backend.transcribed, hasLength(2), reason: 'device dictation never uploads audio');

      // The mic itself stays on the device for a while.
      await tapMic(tester);
      expect(device.started, 2);
    });

    testWidgets('with no dictation service it says so once and offers the device', (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend()..transcribeErrors.add(noService);
      final device = FakeDeviceDictation();
      await tester.pumpWidget(chat(backend, FakeDictation(), device));
      await tester.pumpAndSettle();
      await tapMic(tester);
      await tapMic(tester);
      expect(backend.transcribed, hasLength(1), reason: 'nothing to retry');
      expect(find.textContaining("isn't set up for this workspace"), findsOneWidget);
      await tester.tap(find.text('Say it again'));
      await settleSome(tester);
      expect(device.started, 1);
    });

    testWidgets('without a device recognizer the failure is plain and Try again resends the clip', (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend()..transcribeErrors.addAll([failed, failed]);
      await tester.pumpWidget(chat(backend, FakeDictation(), FakeDeviceDictation(supported: false)));
      await tester.pumpAndSettle();
      await tapMic(tester);
      await tapMic(tester);
      expect(find.text("Couldn't turn that into text."), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await settleSome(tester);
      expect(backend.transcribed, hasLength(3));
      expect(messageText(tester), 'water the plants');
    });

    testWidgets('when the device recognizer fails the mic goes back to the server', (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend()..transcribeErrors.add(noService);
      final dictation = FakeDictation();
      final device = FakeDeviceDictation();
      await tester.pumpWidget(chat(backend, dictation, device));
      await tester.pumpAndSettle();
      await tapMic(tester);
      await tapMic(tester);
      await tester.tap(find.text('Say it again'));
      await settleSome(tester);
      device.end(DeviceDictationEnd.failed);
      await settleSome(tester);
      expect(find.textContaining('back on Casama'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(ChatScreen))).hideCurrentSnackBar();
      await settleSome(tester);
      await tapMic(tester);
      expect(dictation.started, 2);
    });

    testWidgets('a device that refuses to start asks for permission and the mic stays on the server', (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend()..transcribeErrors.add(noService);
      final dictation = FakeDictation();
      final device = FakeDeviceDictation(starts: false);
      await tester.pumpWidget(chat(backend, dictation, device));
      await tester.pumpAndSettle();
      await tapMic(tester);
      await tapMic(tester);
      await tester.tap(find.text('Say it again'));
      await settleSome(tester);
      expect(device.started, 1);
      expect(find.text('Allow speech recognition to dictate with this device.'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(ChatScreen))).hideCurrentSnackBar();
      await settleSome(tester);
      await tapMic(tester);
      expect(dictation.started, 2);
    });
  });

  test('the fallback lasts half an hour, then the server is tried again', () {
    var now = DateTime(2026, 11, 12, 9);
    final route = DictationRoute(now: () => now);
    expect(route.preferDevice, isFalse);
    route.useDevice();
    expect(route.preferDevice, isTrue);
    now = now.add(const Duration(minutes: 31));
    expect(route.preferDevice, isFalse);
  });

  test('an m4a counts as finished only once its index is written', () {
    Uint8List box(String type, int bodyLength) {
      final size = 8 + bodyLength;
      return Uint8List.fromList([size >> 24 & 255, size >> 16 & 255, size >> 8 & 255, size & 255, ...type.codeUnits, ...List.filled(bodyLength, 0)]);
    }

    // "moov" spelled inside the audio data must not count.
    final mdat = box('mdat', 12)..setAll(10, 'moov'.codeUnits);
    final unfinished = Uint8List.fromList([...box('ftyp', 16), ...mdat]);
    expect(hasMp4Index(unfinished), isFalse);
    expect(hasMp4Index(Uint8List.fromList([...unfinished, ...box('moov', 20)])), isTrue);
  });
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

  testWidgets('stopping with no recording leaves the box empty', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    final dictation = FakeDictation()..clip = null;
    await tester.pumpWidget(voiceHarness(backend, dictation: dictation, home: const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dictateButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dictateButton')));
    await tester.pumpAndSettle();
    expect(backend.transcribed, isEmpty);
    expect(tester.widget<TextField>(find.byKey(const Key('messageInput'))).controller!.text, isEmpty);
    expect(find.text('No speech came through. Try again.'), findsOneWidget);
  });

  testWidgets('a blank transcript is not typed into the box', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()..transcript = '   ';
    final dictation = FakeDictation();
    await tester.pumpWidget(voiceHarness(backend, dictation: dictation, home: const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dictateButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dictateButton')));
    await tester.pumpAndSettle();
    expect(backend.transcribed, ['audio/wav']);
    expect(tester.widget<TextField>(find.byKey(const Key('messageInput'))).controller!.text, isEmpty);
    expect(find.text('No speech came through. Try again.'), findsOneWidget);
  });

  testWidgets('bot messages can be read aloud', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()
      ..storedMessages = [ChatMessageView(id: 'msg-1', role: 'assistant', text: 'Water the fern.', createdAt: DateTime(2026))];
    final player = FakePlayer();
    await tester.pumpWidget(voiceHarness(backend, player: player, home: const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    // Read aloud lives in the message menu: long-press the reply.
    await tester.longPress(find.text('Water the fern.'));
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

  testWidgets('a call with two minutes of silence hangs up, and reported token counts are saved', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    final calls = FakeCallConnector();
    calls.call.usage = {'input_audio_tokens': 1500, 'input_text_tokens': 4000, 'output_audio_tokens': 1500, 'output_text_tokens': 0};
    await tester.pumpWidget(voiceHarness(backend, calls: calls, home: const CallScreen(botId: botId, conversationId: convId, idleLimit: Duration(seconds: 2))));
    await tester.pumpAndSettle();
    calls.call.say('user', 'Hi');
    await tester.pump(const Duration(seconds: 1));
    expect(calls.call.hungUp, isFalse);
    // While the bot speaks it isn't idle, however long that takes.
    calls.call.speakingNow.value = true;
    await tester.pump(const Duration(seconds: 3));
    expect(calls.call.hungUp, isFalse);
    calls.call.speakingNow.value = false;
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(calls.call.hungUp, isTrue);
    expect(backend.lastVoiceUsage?['input_text_tokens'], 4000);
  });
}
