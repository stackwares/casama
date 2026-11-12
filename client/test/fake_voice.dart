import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:casama_app/core/call_audio.dart';
import 'package:casama_app/core/device_dictation.dart';
import 'package:casama_app/core/voice.dart';
import 'package:casama_sdk/casama_sdk.dart';

class FakeDictation implements Dictation {
  var started = 0;
  (Uint8List, String)? clip = (Uint8List.fromList([1, 2]), 'audio/wav');
  @override
  Future<bool> start() async {
    started++;
    return true;
  }

  @override
  Future<(Uint8List, String)?> stop() async => clip;
  @override
  Future<void> cancel() async {}
}

class FakeDeviceDictation implements DeviceDictation {
  FakeDeviceDictation({this.supported = true, this.starts = true});
  @override
  final bool supported;
  final bool starts;
  var started = 0;
  void Function(String words)? onWords;
  void Function(DeviceDictationEnd end)? onEnd;

  @override
  Future<bool> start({required void Function(String words) onWords, required void Function(DeviceDictationEnd end) onEnd}) async {
    started++;
    if (!starts) return false;
    this.onWords = onWords;
    this.onEnd = onEnd;
    return true;
  }

  /// The recognizer stops by itself or after [stop].
  void end(DeviceDictationEnd how) {
    final cb = onEnd;
    onEnd = null;
    cb?.call(how);
  }

  @override
  Future<void> stop() async => end(DeviceDictationEnd.done);
  @override
  Future<void> cancel() async => onEnd = null;
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
  final speakingNow = ValueNotifier(false);
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
  ValueListenable<bool> get speaking => speakingNow;
  @override
  Stream<CallToolRequest> get toolCalls => _tools.stream;
  @override
  void sendToolResult(String callId, String output) => results[callId] = output;
  final notes = <String>[];
  @override
  void tellModel(String note) => notes.add(note);
  @override
  void setMuted(bool m) => muted = m;
  @override
  Map<String, int>? usage;
  @override
  CallLevels? levels;
  @override
  CallAudioRoutes? routes;
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
