import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kasama_app/core/voice.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

class FakeDictation implements Dictation {
  var started = 0;
  @override
  Future<bool> start() async {
    started++;
    return true;
  }

  @override
  Future<(Uint8List, String)?> stop() async => (Uint8List.fromList([1, 2]), 'audio/wav');
  @override
  Future<void> cancel() async {}
}

class FakePlayer implements SpeechPlayer {
  final played = <int>[];
  @override
  Future<void> play(Uint8List mp3) async => played.add(mp3.length);
  @override
  Future<void> stop() async {}
}

class FakeCall implements VoiceCall {
  final _state = ValueNotifier(CallState.live);
  final _transcript = ValueNotifier<List<CallTurn>>(const []);
  final _latency = ValueNotifier<int?>(null);
  final _tools = StreamController<CallToolRequest>.broadcast();
  final results = <String, String>{};
  var hungUp = false;
  var muted = false;

  void say(String role, String text) => _transcript.value = [..._transcript.value, CallTurn(role, text)];
  void reply(int ms) => _latency.value = ms;
  void askTool(String id, String name) => _tools.add(CallToolRequest(id, name, const {'query': 'plants'}));

  @override
  ValueListenable<CallState> get state => _state;
  @override
  ValueListenable<List<CallTurn>> get transcript => _transcript;
  @override
  ValueListenable<int?> get replyLatencyMs => _latency;
  @override
  Stream<CallToolRequest> get toolCalls => _tools.stream;
  @override
  void sendToolResult(String callId, String output) => results[callId] = output;
  @override
  void setMuted(bool m) => muted = m;
  @override
  Future<void> hangUp() async {
    hungUp = true;
    _state.value = CallState.ended;
  }
}

class FakeCallConnector implements VoiceCallConnector {
  final call = FakeCall();
  VoiceSession? session;
  @override
  Future<VoiceCall> connect(VoiceSession s) async {
    session = s;
    return call;
  }
}
