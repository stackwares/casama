import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:record/record.dart';

import 'call_audio.dart';
import 'gemini_live.dart';

/// Records a short clip for dictation.
abstract class Dictation {
  Future<bool> start();

  /// Stops and returns the audio and its MIME type (null if nothing was recorded).
  Future<(Uint8List, String)?> stop();
  Future<void> cancel();
}

class RecordDictation implements Dictation {
  final _rec = AudioRecorder();
  final _chunks = <int>[];
  StreamSubscription<Uint8List>? _sub;

  // Web records Opus in WebM; native platforms stream 16 kHz mono PCM, uploaded as WAV
  // (both formats are accepted by OpenAI and Deepgram).
  static const _webConfig = RecordConfig(encoder: AudioEncoder.opus, numChannels: 1);
  // Streaming takes raw PCM on every native platform; WAV is only for recording to a file.
  static const _nativeConfig = RecordConfig(encoder: AudioEncoder.pcm16bits, numChannels: 1, sampleRate: 16000);

  @override
  Future<bool> start() async {
    if (!await _rec.hasPermission()) return false;
    _chunks.clear();
    try {
      final stream = await _rec.startStream(kIsWeb ? _webConfig : _nativeConfig);
      _sub = stream.listen(_chunks.addAll);
      return true;
    } catch (e) {
      debugPrint('dictation failed to start: $e');
      return false;
    }
  }

  @override
  Future<(Uint8List, String)?> stop() async {
    await _rec.stop();
    await _sub?.cancel();
    if (_chunks.isEmpty) return null;
    final data = Uint8List.fromList(_chunks);
    return kIsWeb ? (data, 'audio/webm') : (_wav(data, 16000), 'audio/wav');
  }

  @override
  Future<void> cancel() async {
    await _rec.cancel();
    await _sub?.cancel();
    _chunks.clear();
  }

  /// Wraps 16-bit mono PCM in a WAV header.
  static Uint8List _wav(Uint8List pcm, int rate) {
    final b = BytesBuilder();
    void u32(int v) => b.add([v & 255, (v >> 8) & 255, (v >> 16) & 255, (v >> 24) & 255]);
    void u16(int v) => b.add([v & 255, (v >> 8) & 255]);
    b.add(ascii.encode('RIFF'));
    u32(36 + pcm.length);
    b.add(ascii.encode('WAVEfmt '));
    u32(16);
    u16(1);
    u16(1);
    u32(rate);
    u32(rate * 2);
    u16(2);
    u16(16);
    b.add(ascii.encode('data'));
    u32(pcm.length);
    b.add(pcm);
    return b.toBytes();
  }
}

/// Plays read-aloud audio.
abstract class SpeechPlayer {
  Future<void> play(Uint8List mp3);
  Future<void> stop();
}

class JustAudioPlayer implements SpeechPlayer {
  final _player = AudioPlayer();

  @override
  Future<void> play(Uint8List mp3) async {
    await _player.setAudioSource(_BytesSource(mp3));
    unawaited(_player.play());
  }

  @override
  Future<void> stop() => _player.stop();
}

// ignore: experimental_member_use
class _BytesSource extends StreamAudioSource {
  _BytesSource(this.bytes);
  final Uint8List bytes;

  @override
  // ignore: experimental_member_use
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? bytes.length;
    // ignore: experimental_member_use
    final wav = bytes.length >= 4 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46;
    return StreamAudioResponse(sourceLength: bytes.length, contentLength: e - s, offset: s, stream: Stream.value(bytes.sublist(s, e)), contentType: wav ? 'audio/wav' : 'audio/mpeg');
  }
}

/// One turn of a live call's transcript.
class CallTurn {
  const CallTurn(this.role, this.text);
  final String role;
  final String text;
}

/// A tool call the realtime model asked for.
class CallToolRequest {
  const CallToolRequest(this.callId, this.name, this.arguments);
  final String callId;
  final String name;
  final Map<String, Object?> arguments;
}

enum CallState { connecting, live, ended, failed }

/// A live voice call with a realtime speech-to-speech model.
abstract class VoiceCall {
  ValueListenable<CallState> get state;
  ValueListenable<List<CallTurn>> get transcript;

  /// Time from the end of the user's speech to the start of the reply, for the last turn.
  ValueListenable<int?> get replyLatencyMs;

  /// Whether the bot is speaking now (drives the animated avatar, D-144).
  ValueListenable<bool> get speaking;

  /// Tool calls the model wants run; answer each with [sendToolResult].
  Stream<CallToolRequest> get toolCalls;
  void sendToolResult(String callId, String output);

  /// Tells the model something that happened in the app (the person approved an action), so it
  /// can say so and carry on. Not shown as the person speaking.
  void tellModel(String note);
  void setMuted(bool muted);
  Future<void> hangUp();

  /// The call's token counts as the provider reported them (Gemini Live), so usage can record the
  /// real cost; null when the provider doesn't report them.
  Map<String, int>? get usage;

  /// How loud each side is right now, for the call screen; null when the call can't tell (the
  /// screen then follows [speaking]).
  CallLevels? get levels;

  /// Where the call plays (speaker, earpiece, headset); null where there's no choice (desktop,
  /// web).
  CallAudioRoutes? get routes;
}

/// Loudness of a live call, 0 (silent) to 1 (loud), read once per frame by the call screen.
abstract class CallLevels {
  /// The person's microphone (0 while muted).
  double get input;

  /// The bot's voice, as it plays.
  double get output;
}

/// Loudness of 16-bit little-endian PCM, mapped so normal speech lands around 0.4–0.9.
double pcmLevel(Uint8List pcm, [int start = 0, int? end]) {
  final to = math.min(end ?? pcm.length, pcm.length) & ~1;
  if (to - start < 2) return 0;
  final data = ByteData.sublistView(pcm);
  var sum = 0.0;
  var n = 0;
  for (var i = start; i < to; i += 2) {
    final s = data.getInt16(i, Endian.little) / 32768;
    sum += s * s;
    n++;
  }
  return (math.sqrt(math.sqrt(sum / n)) * 1.6).clamp(0.0, 1.0);
}

abstract class VoiceCallConnector {
  Future<VoiceCall> connect(VoiceSession session);
}

/// OpenAI Realtime over WebRTC (GA interface): the app talks to the provider directly with the
/// ephemeral key; events travel on the "oai-events" data channel.
class OpenAiRealtimeConnector implements VoiceCallConnector {
  @override
  Future<VoiceCall> connect(VoiceSession session) => _RealtimeCall.open(session);
}

/// Realtime events for a live call (D-065), with barge-in (D-144): when the person starts talking
/// while the bot speaks, its response is cancelled and its queued audio dropped, so it listens.
class RealtimeEvents {
  RealtimeEvents(this.send);
  final void Function(Map<String, Object?> event) send;
  final transcript = ValueNotifier<List<CallTurn>>(const []);
  final latency = ValueNotifier<int?>(null);
  final speaking = ValueNotifier(false);
  final tools = StreamController<CallToolRequest>.broadcast();
  DateTime? _speechStopped;
  var _responding = false;

  void _add(String role, String text) {
    if (text.trim().isEmpty) return;
    transcript.value = [...transcript.value, CallTurn(role, text.trim())];
  }

  void handle(String raw) {
    final e = jsonDecode(raw) as Map<String, dynamic>;
    switch (e['type']) {
      case 'response.created':
        _responding = true;
      case 'response.done':
        _responding = false;
      case 'input_audio_buffer.speech_started':
        // Barge-in: stop the bot's reply and its buffered audio, then listen.
        if (speaking.value || _responding) {
          if (_responding) send({'type': 'response.cancel'});
          send({'type': 'output_audio_buffer.clear'});
          speaking.value = false;
          _responding = false;
        }
      case 'input_audio_buffer.speech_stopped':
        _speechStopped = DateTime.now();
      case 'output_audio_buffer.started' || 'response.output_audio.delta':
        speaking.value = true;
        if (_speechStopped != null) {
          latency.value = DateTime.now().difference(_speechStopped!).inMilliseconds;
          _speechStopped = null;
        }
      case 'output_audio_buffer.stopped' || 'output_audio_buffer.cleared':
        speaking.value = false;
      case 'conversation.item.input_audio_transcription.completed':
        _add('user', e['transcript'] as String? ?? '');
      case 'response.output_audio_transcript.done':
        _add('assistant', e['transcript'] as String? ?? '');
      case 'response.function_call_arguments.done':
        Map<String, Object?> args;
        try {
          args = (jsonDecode(e['arguments'] as String? ?? '{}') as Map).cast<String, Object?>();
        } catch (_) {
          args = const {};
        }
        tools.add(CallToolRequest(e['call_id'] as String, e['name'] as String, args));
    }
  }
}

class _RealtimeCall implements VoiceCall {
  final _state = ValueNotifier(CallState.connecting);
  late final _ev = RealtimeEvents(_send);
  RTCPeerConnection? _pc;
  RTCDataChannel? _events;
  MediaStream? _mic;
  final _remoteRenderer = RTCVideoRenderer();

  static Future<_RealtimeCall> open(VoiceSession s) async {
    final c = _RealtimeCall();
    await c._start(s);
    return c;
  }

  Future<void> _start(VoiceSession s) async {
    await _remoteRenderer.initialize();
    final pc = await createPeerConnection({'sdpSemantics': 'unified-plan'});
    _pc = pc;
    pc.onTrack = (e) {
      // Native platforms play remote audio by themselves; web needs a media element.
      if (e.streams.isNotEmpty) _remoteRenderer.srcObject = e.streams.first;
    };
    pc.onConnectionState = (st) {
      if (st == RTCPeerConnectionState.RTCPeerConnectionStateConnected) _state.value = CallState.live;
      if (st == RTCPeerConnectionState.RTCPeerConnectionStateFailed) _state.value = CallState.failed;
    };
    _mic = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    for (final t in _mic!.getAudioTracks()) {
      await pc.addTrack(t, _mic!);
    }
    _events = await pc.createDataChannel('oai-events', RTCDataChannelInit());
    _events!.onMessage = (m) => _ev.handle(m.text);
    // An answered phone call (D-135): the bot opens the conversation.
    if (s.speakFirst) {
      _events!.onDataChannelState = (st) {
        if (st == RTCDataChannelState.RTCDataChannelOpen) _send({'type': 'response.create'});
      };
    }
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    final res = await http.post(Uri.parse(s.connectUrl), headers: {'authorization': 'Bearer ${s.clientSecret}', 'content-type': 'application/sdp'}, body: offer.sdp);
    if (res.statusCode >= 300) {
      _state.value = CallState.failed;
      throw StateError('Realtime connection refused (${res.statusCode})');
    }
    await pc.setRemoteDescription(RTCSessionDescription(res.body, 'answer'));
  }

  void _send(Map<String, Object?> event) => _events?.send(RTCDataChannelMessage(jsonEncode(event)));

  @override
  ValueListenable<CallState> get state => _state;
  @override
  ValueListenable<List<CallTurn>> get transcript => _ev.transcript;
  @override
  ValueListenable<int?> get replyLatencyMs => _ev.latency;
  @override
  ValueListenable<bool> get speaking => _ev.speaking;
  @override
  Stream<CallToolRequest> get toolCalls => _ev.tools.stream;
  @override
  Map<String, int>? get usage => null;
  @override
  CallLevels? get levels => null;
  @override
  CallAudioRoutes? get routes => CallAudioRoutes.supported ? DeviceCallAudioRoutes() : null;

  @override
  void sendToolResult(String callId, String output) {
    _send({
      'type': 'conversation.item.create',
      'item': {'type': 'function_call_output', 'call_id': callId, 'output': output},
    });
    _send({'type': 'response.create'});
  }

  @override
  void tellModel(String note) {
    _send({
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {'type': 'input_text', 'text': note},
        ],
      },
    });
    _send({'type': 'response.create'});
  }

  @override
  void setMuted(bool muted) {
    for (final t in _mic?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      t.enabled = !muted;
    }
  }

  @override
  Future<void> hangUp() async {
    _state.value = CallState.ended;
    for (final t in _mic?.getTracks() ?? const <MediaStreamTrack>[]) {
      await t.stop();
    }
    await _events?.close();
    await _pc?.close();
    _remoteRenderer.srcObject = null;
    await _remoteRenderer.dispose();
    await _ev.tools.close();
  }
}

final dictationProvider = Provider<Dictation>((ref) => RecordDictation());
final speechPlayerProvider = Provider<SpeechPlayer>((ref) => JustAudioPlayer());
/// Picks the call client for the provider the server chose: Gemini Live (when the workspace has a
/// Google AI key) or OpenAI Realtime.
class RealtimeVoiceConnector implements VoiceCallConnector {
  @override
  Future<VoiceCall> connect(VoiceSession session) => switch (session.provider) {
        VoiceSessionProviderEnum.gemini => GeminiLiveCall.open(session),
        _ => _RealtimeCall.open(session),
      };
}

final voiceCallConnectorProvider = Provider<VoiceCallConnector>((ref) => RealtimeVoiceConnector());
