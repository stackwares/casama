import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:record/record.dart';

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
  static const _nativeConfig = RecordConfig(encoder: AudioEncoder.wav, numChannels: 1, sampleRate: 16000);

  @override
  Future<bool> start() async {
    if (!await _rec.hasPermission()) return false;
    _chunks.clear();
    final stream = await _rec.startStream(kIsWeb ? _webConfig : _nativeConfig);
    _sub = stream.listen(_chunks.addAll);
    return true;
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
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(bytes.sublist(s, e)),
      contentType: 'audio/mpeg',
    );
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
  /// Tool calls the model wants run; answer each with [sendToolResult].
  Stream<CallToolRequest> get toolCalls;
  void sendToolResult(String callId, String output);
  void setMuted(bool muted);
  Future<void> hangUp();
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

class _RealtimeCall implements VoiceCall {
  final _state = ValueNotifier(CallState.connecting);
  final _transcript = ValueNotifier<List<CallTurn>>(const []);
  final _latency = ValueNotifier<int?>(null);
  final _tools = StreamController<CallToolRequest>.broadcast();
  RTCPeerConnection? _pc;
  RTCDataChannel? _events;
  MediaStream? _mic;
  DateTime? _speechStopped;
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
    _events!.onMessage = (m) => _onEvent(m.text);
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    final res = await http.post(
      Uri.parse(s.connectUrl),
      headers: {'authorization': 'Bearer ${s.clientSecret}', 'content-type': 'application/sdp'},
      body: offer.sdp,
    );
    if (res.statusCode >= 300) {
      _state.value = CallState.failed;
      throw StateError('Realtime connection refused (${res.statusCode})');
    }
    await pc.setRemoteDescription(RTCSessionDescription(res.body, 'answer'));
  }

  void _send(Map<String, Object?> event) => _events?.send(RTCDataChannelMessage(jsonEncode(event)));

  void _add(String role, String text) {
    if (text.trim().isEmpty) return;
    _transcript.value = [..._transcript.value, CallTurn(role, text.trim())];
  }

  void _onEvent(String raw) {
    final e = jsonDecode(raw) as Map<String, dynamic>;
    switch (e['type']) {
      case 'input_audio_buffer.speech_stopped':
        _speechStopped = DateTime.now();
      case 'output_audio_buffer.started' || 'response.output_audio.delta':
        if (_speechStopped != null) {
          _latency.value = DateTime.now().difference(_speechStopped!).inMilliseconds;
          _speechStopped = null;
        }
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
        _tools.add(CallToolRequest(e['call_id'] as String, e['name'] as String, args));
    }
  }

  @override
  ValueListenable<CallState> get state => _state;
  @override
  ValueListenable<List<CallTurn>> get transcript => _transcript;
  @override
  ValueListenable<int?> get replyLatencyMs => _latency;
  @override
  Stream<CallToolRequest> get toolCalls => _tools.stream;

  @override
  void sendToolResult(String callId, String output) {
    _send({
      'type': 'conversation.item.create',
      'item': {'type': 'function_call_output', 'call_id': callId, 'output': output},
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
    await _tools.close();
  }
}

final dictationProvider = Provider<Dictation>((ref) => RecordDictation());
final speechPlayerProvider = Provider<SpeechPlayer>((ref) => JustAudioPlayer());
final voiceCallConnectorProvider = Provider<VoiceCallConnector>((ref) => OpenAiRealtimeConnector());
