import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/gemini_live.dart';
import 'package:casama_app/core/voice.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

String _audio(int bytes) => base64Encode(Uint8List(bytes));

class _FakeSink implements WebSocketSink {
  final sent = <Map<String, dynamic>>[];
  var closed = false;
  @override
  void add(dynamic data) =>
      sent.add(jsonDecode(data as String) as Map<String, dynamic>);
  @override
  Future<void> close([int? closeCode, String? closeReason]) async =>
      closed = true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChannel implements WebSocketChannel {
  _FakeChannel(this.url);
  final Uri url;
  final incoming = StreamController<dynamic>();
  @override
  final _FakeSink sink = _FakeSink();
  @override
  Stream<dynamic> get stream => incoming.stream;
  @override
  Future<void> get ready => Future.value();
  void server(Map<String, Object?> m) => incoming.add(jsonEncode(m));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudio implements PcmAudio {
  void Function(Uint8List)? mic;
  final played = <int>[];
  var flushed = 0;
  var disposed = false;
  @override
  Future<void> startMic(void Function(Uint8List pcm16k) onChunk) async =>
      mic = onChunk;
  @override
  Future<void> stopMic() async => mic = null;
  @override
  void play(Uint8List pcm24k) => played.add(pcm24k.length);
  @override
  void flush() => flushed++;
  @override
  Future<void> dispose() async => disposed = true;
}

VoiceSession _session({bool speakFirst = false}) => VoiceSession(
  provider: VoiceSessionProviderEnum.gemini,
  model: 'gemini-3.8-live',
  clientSecret: 'auth_tokens/t1',
  expiresAt: DateTime.now().add(const Duration(minutes: 30)),
  connectUrl: 'wss://example.invalid/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained',
  setup: const {'model': 'models/gemini-3.8-live'},
  conversationId: 'c1',
  tools: 2,
  speakFirst: speakFirst,
);

void main() {
  group('GeminiLiveEvents', () {
    late List<Map<String, Object?>> sent;
    late List<int> audio;
    late int interrupted;
    late GeminiLiveEvents ev;
    setUp(() {
      sent = [];
      audio = [];
      interrupted = 0;
      ev = GeminiLiveEvents(
        send: sent.add,
        onAudio: (b) => audio.add(b.length),
        onInterrupted: () => interrupted++,
      );
    });

    test(
      'builds the transcript a turn at a time and plays audio as it arrives',
      () {
        ev.handle(jsonEncode({'setupComplete': {}}));
        expect(ev.ready, isTrue);
        ev.handle(
          jsonEncode({
            'serverContent': {
              'inputTranscription': {'text': 'How often should I '},
            },
          }),
        );
        ev.handle(
          jsonEncode({
            'serverContent': {
              'inputTranscription': {'text': 'water the fern?'},
            },
          }),
        );
        ev.handle(
          jsonEncode({
            'serverContent': {
              'modelTurn': {
                'parts': [
                  {
                    'inlineData': {
                      'data': _audio(4800),
                      'mimeType': 'audio/pcm;rate=24000',
                    },
                  },
                ],
              },
              'outputTranscription': {'text': 'Once a week.'},
            },
          }),
        );
        expect(audio, [4800]);
        expect(ev.transcript.value.map((t) => '${t.role}: ${t.text}'), [
          'user: How often should I water the fern?',
        ]);
        expect(ev.latency.value, isNotNull);
        ev.handle(
          jsonEncode({
            'serverContent': {'turnComplete': true},
          }),
        );
        expect(ev.transcript.value.last.text, 'Once a week.');
        expect(ev.transcript.value.last.role, 'assistant');
      },
    );

    test('barge-in drops queued audio and ends the bot turn', () {
      ev.handle(
        jsonEncode({
          'serverContent': {
            'outputTranscription': {'text': 'Let me tell you about'},
          },
        }),
      );
      ev.handle(
        jsonEncode({
          'serverContent': {'interrupted': true},
        }),
      );
      expect(interrupted, 1);
      expect(ev.transcript.value.single.text, 'Let me tell you about');
    });

    test('tool calls come out as requests and their results go back with the function name', () async {
      final calls = <CallToolRequest>[];
      final sub = ev.tools.stream.listen(calls.add);
      ev.handle(
        jsonEncode({
          'toolCall': {
            'functionCalls': [
              {
                'id': 'f1',
                'name': 'memory__search',
                'args': {'query': 'fern'},
              },
            ],
          },
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(calls.single.name, 'memory__search');
      expect(calls.single.arguments, {'query': 'fern'});
      expect(ev.toolResponse('f1', 'Water weekly'), {
        'toolResponse': {
          'functionResponses': [
            {
              'id': 'f1',
              'name': 'memory__search',
              'response': {'result': 'Water weekly'},
            },
          ],
        },
      });
      await sub.cancel();
    });

    test('adds up usageMetadata by modality', () {
      ev.handle(
        jsonEncode({
          'usageMetadata': {
            'promptTokenCount': 5500,
            'promptTokensDetails': [
              {'modality': 'AUDIO', 'tokenCount': 1500},
              {'modality': 'TEXT', 'tokenCount': 4000},
            ],
            'responseTokensDetails': [
              {'modality': 'AUDIO', 'tokenCount': 1500},
            ],
            'toolUsePromptTokenCount': 100,
          },
        }),
      );
      ev.handle(
        jsonEncode({
          'usageMetadata': {'promptTokenCount': 200, 'responseTokenCount': 50},
        }),
      );
      expect(ev.usage, {
        'input_audio_tokens': 1500,
        'input_text_tokens': 4300,
        'output_audio_tokens': 1500,
        'output_text_tokens': 50,
      });
      expect(ev.hasUsage, isTrue);
    });

    test('remembers the resumption handle and notices goAway', () {
      ev.handle(
        jsonEncode({
          'sessionResumptionUpdate': {'newHandle': 'h1', 'resumable': true},
        }),
      );
      ev.handle(
        jsonEncode({
          'sessionResumptionUpdate': {'newHandle': 'h2', 'resumable': false},
        }),
      );
      expect(ev.resumeHandle, 'h1');
      ev.handle(
        jsonEncode({
          'goAway': {'timeLeft': '10s'},
        }),
      );
      expect(ev.goingAway, isTrue);
      ev.handle('not json');
    });
  });

  group('GeminiLiveCall', () {
    test('connects with the token, sends the setup, streams the mic, and resumes on goAway', () async {
      final channels = <_FakeChannel>[];
      final audio = _FakeAudio();
      final call = await GeminiLiveCall.open(
        _session(),
        audio: audio,
        connect: (u) {
          final c = _FakeChannel(u);
          channels.add(c);
          return c;
        },
      );
      final first = channels.single;
      expect(first.url.queryParameters['access_token'], 'auth_tokens/t1');
      expect(first.sink.sent.first, {
        'setup': {
          'model': 'models/gemini-3.8-live',
          'sessionResumption': <String, Object?>{},
        },
      });
      // The mic waits for the server to accept the setup.
      audio.mic!(Uint8List(320));
      expect(first.sink.sent, hasLength(1));
      first.server({'setupComplete': {}});
      await Future<void>.delayed(Duration.zero);
      expect(call.state.value, CallState.live);
      audio.mic!(Uint8List(320));
      expect(
        first.sink.sent.last['realtimeInput']['audio']['mimeType'],
        'audio/pcm;rate=16000',
      );

      // The reply plays, and the person talking over it flushes the queue.
      first.server({
        'serverContent': {
          'modelTurn': {
            'parts': [
              {
                'inlineData': {'data': _audio(48000)},
              },
            ],
          },
        },
      });
      await Future<void>.delayed(Duration.zero);
      expect(audio.played, [48000]);
      expect(call.speaking.value, isTrue);
      first.server({
        'serverContent': {'interrupted': true},
      });
      await Future<void>.delayed(Duration.zero);
      expect(audio.flushed, 1);
      expect(call.speaking.value, isFalse);

      // Muting tells Gemini the audio stream paused.
      call.setMuted(true);
      expect(first.sink.sent.last, {
        'realtimeInput': {'audioStreamEnd': true},
      });
      call.setMuted(false);

      // Google ends connections after about 10 minutes: the call resumes on a new one.
      first.server({
        'sessionResumptionUpdate': {'newHandle': 'h1', 'resumable': true},
      });
      first.server({
        'goAway': {'timeLeft': '5s'},
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(channels, hasLength(2));
      expect(channels.last.sink.sent.first['setup']['sessionResumption'], {
        'handle': 'h1',
      });
      expect(first.sink.closed, isTrue);

      await call.hangUp();
      expect(call.state.value, CallState.ended);
      expect(audio.disposed, isTrue);
    });

    test('an answered phone call has the bot speak first', () async {
      late _FakeChannel ch;
      final call = await GeminiLiveCall.open(
        _session(speakFirst: true),
        audio: _FakeAudio(),
        connect: (u) => ch = _FakeChannel(u),
      );
      ch.server({'setupComplete': {}});
      await Future<void>.delayed(Duration.zero);
      expect(ch.sink.sent.last['clientContent']['turnComplete'], isTrue);
      await call.hangUp();
    });
  });
}
