import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_sdk/casama_sdk.dart'
    show VoiceToolResult, VoiceToolResultStatusEnum;
import 'package:casama_app/core/call_audio.dart';
import 'package:casama_app/core/voice.dart';
import 'package:casama_app/features/voice/call_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';
import 'fake_voice.dart';
import 'voice_test.dart' show voiceHarness;

/// Voice upgrades (D-144): barge-in and the call orb.
void main() {
  CallScreen.motion = false;
  test('speaking over the bot cancels its reply and clears its audio', () {
    final sent = <String>[];
    final ev = RealtimeEvents((e) => sent.add(e['type'] as String));
    void get(Map<String, Object?> e) => ev.handle(jsonEncode(e));
    get({'type': 'response.created'});
    get({'type': 'output_audio_buffer.started'});
    expect(ev.speaking.value, isTrue);
    get({'type': 'input_audio_buffer.speech_started'});
    expect(sent, ['response.cancel', 'output_audio_buffer.clear']);
    expect(ev.speaking.value, isFalse);
    // Talking while the bot is quiet changes nothing.
    get({'type': 'input_audio_buffer.speech_started'});
    expect(sent, hasLength(2));
    get({
      'type': 'response.output_audio_transcript.done',
      'transcript': 'Sure.',
    });
    expect(ev.transcript.value.single.text, 'Sure.');
  });

  testWidgets(
    'the orb follows the call, and captions can be hidden and stay hidden',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await setSize(tester, const Size(500, 900));
      final calls = FakeCallConnector();
      await tester.pumpWidget(
        voiceHarness(
          FakeBackend(),
          calls: calls,
          home: const CallScreen(botId: botId, conversationId: convId),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('callMascot-listening')), findsOneWidget);
      calls.call.speakingNow.value = true;
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('callMascot-speaking')), findsOneWidget);
      calls.call.speakingNow.value = false;
      await tester.pump(const Duration(milliseconds: 50));

      calls.call.say('assistant', 'Hello there.');
      await tester.pump();
      expect(find.text('Hello there.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('captionsButton')));
      await tester.pump();
      expect(find.text('Hello there.'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getBool('voice.captions'),
        isFalse,
      );

      await tester.tap(find.byKey(const Key('muteButton')));
      await tester.pump();
      expect(find.byKey(const Key('callMascot-muted')), findsOneWidget);
    },
  );

  testWidgets(
    'a workspace with no voice key is shown where to get one and where to add it',
    (tester) async {
      await setSize(tester, const Size(500, 900));
      final req = RequestOptions(path: '/v1/voice/session');
      final backend = FakeBackend()
        ..voiceSessionError = DioException(
          requestOptions: req,
          response: Response(
            requestOptions: req,
            statusCode: 409,
            data: {
              'type': 'about:blank',
              'title': 'Conflict',
              'status': 409,
              'code': 'voice_key_missing',
              'detail': 'Live calls need a Google AI (Gemini) or OpenAI key.',
            },
          ),
        );
      await tester.pumpWidget(
        voiceHarness(
          backend,
          calls: FakeCallConnector(),
          home: const CallScreen(botId: botId, conversationId: convId),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Calls need a voice key'), findsOneWidget);
      expect(find.byKey(const Key('callNeedsKey')), findsOneWidget);
      expect(find.byKey(const Key('callGetKey')), findsOneWidget);
      expect(find.byKey(const Key('callMascot-failed')), findsOneWidget);
      await tester.tap(find.byKey(const Key('callAddKey')));
      await tester.pumpAndSettle();
      expect(find.text('keys google'), findsOneWidget);
    },
  );

  testWidgets(
    'calls start on the speaker; the earpiece is a tap away, and headsets are offered when connected',
    (tester) async {
      await setSize(tester, const Size(500, 900));
      final calls = FakeCallConnector();
      final routes = _FakeRoutes();
      calls.call.routes = routes;
      await tester.pumpWidget(
        voiceHarness(
          FakeBackend(),
          calls: calls,
          home: const CallScreen(botId: botId, conversationId: convId),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Speaker'), findsOneWidget);
      await tester.tap(find.byKey(const Key('audioRouteButton')));
      await tester.pump();
      expect(routes.selected, const CallRoute(CallRouteKind.earpiece));
      expect(find.text('Phone'), findsOneWidget);

      routes.extra = const CallRoute(
        CallRouteKind.bluetooth,
        id: 'bt1',
        name: 'AirPods',
      );
      await tester.tap(find.byKey(const Key('audioRouteButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('callRoute-bluetooth-bt1')));
      await tester.pumpAndSettle();
      expect(routes.selected, routes.extra);
      expect(find.text('AirPods'), findsOneWidget);
    },
  );

  testWidgets(
    'the call fits a small phone, large text, captions and a tool card',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final problems = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.toString();
        if (text.contains('overflowed') || text.contains('unbounded')) {
          problems.add(text.split('\n').take(4).join(' '));
        }
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);

      Future<void> pumpAt(
        Size size, {
        double textScale = 1,
        bool needsKey = false,
      }) async {
        await setSize(tester, size);
        tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
        tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        final calls = FakeCallConnector()..call.routes = _FakeRoutes();
        final backend = FakeBackend();
        if (needsKey) {
          final req = RequestOptions(path: '/v1/voice/session');
          backend.voiceSessionError = DioException(
            requestOptions: req,
            response: Response(
              requestOptions: req,
              statusCode: 409,
              data: {
                'code': 'voice_key_missing',
                'detail': 'Live calls need a Google AI (Gemini) or OpenAI key.',
              },
            ),
          );
        } else {
          backend.voiceToolResults['memory__search'] = VoiceToolResult(
            status: VoiceToolResultStatusEnum.waitingApproval,
            runId: 'run-layout',
            output: 'Needs approval',
            approvalId: 'appr-layout',
          );
        }
        await tester.pumpWidget(
          voiceHarness(
            backend,
            calls: calls,
            home: const CallScreen(botId: botId, conversationId: convId),
          ),
        );
        await tester.pump();
        await tester.pump();
        if (!needsKey) {
          calls.call.say(
            'assistant',
            'Let me look that up for you, it may take a moment.',
          );
          calls.call.say(
            'user',
            'Please check the watering schedule and the forecast for the whole week.',
          );
          calls.call.say(
            'assistant',
            'The fern wants water on Fridays, and the forecast stays mild through Sunday evening.',
          );
          calls.call.askTool('layout-tool', 'memory__search');
          await tester.pump();
          await tester.pump();
        }
        expect(find.byKey(const Key('hangUpButton')), findsOneWidget);
        final hangUp = tester.getRect(find.byKey(const Key('hangUpButton')));
        expect(hangUp.right, lessThanOrEqualTo(size.width + 0.5));
        expect(hangUp.bottom, lessThanOrEqualTo(size.height + 0.5));
        final caught = tester.takeException();
        if (caught != null) {
          problems.add('$size key=$needsKey scale=$textScale: $caught');
        }
      }

      await pumpAt(const Size(320, 568));
      await pumpAt(const Size(375, 667));
      await pumpAt(const Size(390, 844));
      await pumpAt(const Size(390, 420));
      await pumpAt(const Size(320, 568), textScale: 1.6);
      await pumpAt(const Size(320, 568), needsKey: true);
      await pumpAt(const Size(320, 568), textScale: 1.4, needsKey: true);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      expect(problems, isEmpty, reason: problems.join('\n'));
    },
  );

  testWidgets(
    'tools show as cards in plain words, and an approval can be given without leaving the call',
    (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend()
        ..voiceToolResults['routines__create'] = VoiceToolResult(
          status: VoiceToolResultStatusEnum.waitingApproval,
          runId: 'run-2',
          output: 'Needs approval',
          approvalId: 'appr1',
        );
      final calls = FakeCallConnector();
      await tester.pumpWidget(
        voiceHarness(
          backend,
          calls: calls,
          home: const CallScreen(botId: botId, conversationId: convId),
        ),
      );
      await tester.pump();
      await tester.pump();

      backend.voiceToolGate = Completer<void>();
      calls.call.askTool('t1', 'memory__search');
      await tester.pump();
      expect(find.text('Searching your memories'), findsOneWidget);
      expect(find.byKey(const Key('callMascot-thinking')), findsOneWidget);
      backend.voiceToolGate!.complete();
      backend.voiceToolGate = null;
      await tester.pump();
      await tester.pump();
      expect(find.text('Searched your memories'), findsOneWidget);
      expect(find.text('“plants”'), findsOneWidget);
      // Finished cards fold away.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Searched your memories'), findsNothing);

      calls.call.askTool('t2', 'routines__create');
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Needs your OK to go ahead'), findsOneWidget);
      await tester.tap(find.byKey(const Key('toolAllow-t2')));
      await tester.pump();
      await tester.pump();
      expect(backend.decisions['appr1'], 'approved');
      expect(calls.call.notes.single, contains('approved routines.create'));
      expect(
        find.text('Allowed. The result will show in the chat'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    },
  );
}

class _FakeRoutes implements CallAudioRoutes {
  CallRoute current_ = const CallRoute(CallRouteKind.speaker);
  CallRoute? selected;
  CallRoute? extra;
  @override
  Future<List<CallRoute>> available() async => [
    const CallRoute(CallRouteKind.speaker),
    const CallRoute(CallRouteKind.earpiece),
    ?extra,
  ];
  @override
  Future<CallRoute?> current() async => current_;
  @override
  Future<void> select(CallRoute route) async => selected = current_ = route;
}
