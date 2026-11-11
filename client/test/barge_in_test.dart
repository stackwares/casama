import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/voice.dart';
import 'package:casama_app/features/voice/call_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';
import 'fake_voice.dart';
import 'voice_test.dart' show voiceHarness;

/// Voice upgrades (D-144): barge-in and the animated avatar.
void main() {
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
    get({'type': 'response.output_audio_transcript.done', 'transcript': 'Sure.'});
    expect(ev.transcript.value.single.text, 'Sure.');
  });

  testWidgets('the animated avatar follows the bot speaking, and the choice is remembered', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(500, 900));
    final calls = FakeCallConnector();
    await tester.pumpWidget(voiceHarness(FakeBackend(), calls: calls, home: const CallScreen(botId: botId, conversationId: convId)));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('avatarListening')), findsNothing);
    await tester.tap(find.byKey(const Key('avatarButton')));
    await tester.pump();
    expect(find.byKey(const Key('avatarListening')), findsOneWidget);
    calls.call.speakingNow.value = true;
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('avatarSpeaking')), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getBool('voice.avatar'), isTrue);
    calls.call.speakingNow.value = false;
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('avatarListening')), findsOneWidget);
  });
}
