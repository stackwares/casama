import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:casama_sdk/casama_sdk.dart' show VoiceSession;
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'call_audio.dart';
import 'voice.dart';

/// Gemini Live's audio: 16 kHz 16-bit PCM from the mic, 24 kHz 16-bit PCM back.
const geminiInputRate = 16000;
const geminiOutputRate = 24000;

/// The server messages of a Gemini Live call, turned into what the call screen shows: the
/// transcript a turn at a time, tool calls, whether the bot is speaking, and the reply latency.
/// Audio itself goes to [onAudio]; [onInterrupted] means the person talked over the bot, so its
/// queued audio must be dropped.
class GeminiLiveEvents {
  GeminiLiveEvents({
    required this.send,
    required this.onAudio,
    required this.onInterrupted,
  });

  final void Function(Map<String, Object?> message) send;
  final void Function(Uint8List pcm24k) onAudio;
  final void Function() onInterrupted;

  final transcript = ValueNotifier<List<CallTurn>>(const []);
  final latency = ValueNotifier<int?>(null);
  final tools = StreamController<CallToolRequest>.broadcast();

  /// The latest handle to resume this session on a new connection, when the server allows it.
  String? resumeHandle;

  /// True once the server has accepted the setup message.
  bool ready = false;

  /// Set when the server says the connection is about to end ("goAway").
  bool goingAway = false;

  /// Token counts so far, from the server's usageMetadata (each one covers the latest response).
  final usage = <String, int>{
    'input_audio_tokens': 0,
    'input_text_tokens': 0,
    'output_audio_tokens': 0,
    'output_text_tokens': 0,
  };

  void _addUsage(Map<dynamic, dynamic> u) {
    int count(Object? v) => v is num ? v.toInt() : 0;
    (int, int) split(Object? details, Object? total) {
      if (details is! List) {
        return (0, count(total));
      }
      var audio = 0;
      var other = 0;
      for (final d in details) {
        if (d is! Map) continue;
        if (d['modality'] == 'AUDIO') {
          audio += count(d['tokenCount']);
        } else {
          other += count(d['tokenCount']);
        }
      }
      return (audio, other);
    }

    final (inAudio, inOther) = split(
      u['promptTokensDetails'],
      u['promptTokenCount'],
    );
    final (outAudio, outOther) = split(
      u['responseTokensDetails'],
      u['responseTokenCount'],
    );
    usage['input_audio_tokens'] = usage['input_audio_tokens']! + inAudio;
    usage['input_text_tokens'] =
        usage['input_text_tokens']! +
        inOther +
        count(u['toolUsePromptTokenCount']);
    usage['output_audio_tokens'] = usage['output_audio_tokens']! + outAudio;
    usage['output_text_tokens'] =
        usage['output_text_tokens']! +
        outOther +
        count(u['thoughtsTokenCount']);
  }

  /// Whether the server has reported any usage yet.
  bool get hasUsage => usage.values.any((v) => v > 0);

  final _names = <String, String>{};
  final _user = StringBuffer();
  final _bot = StringBuffer();
  DateTime? _heardUser;
  var _replying = false;

  void _add(String role, StringBuffer b) {
    final text = b.toString().trim();
    b.clear();
    if (text.isEmpty) return;
    transcript.value = [...transcript.value, CallTurn(role, text)];
  }

  /// The name of the function a tool call id belongs to (Gemini wants it back with the result).
  String? toolName(String id) => _names[id];

  void handle(String raw) {
    final Map<String, dynamic> m;
    try {
      m = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (m.containsKey('setupComplete')) ready = true;
    final resume = m['sessionResumptionUpdate'];
    if (resume is Map &&
        resume['resumable'] == true &&
        resume['newHandle'] is String) {
      resumeHandle = resume['newHandle'] as String;
    }
    if (m.containsKey('goAway')) goingAway = true;
    final u = m['usageMetadata'];
    if (u is Map) _addUsage(u);

    final sc = m['serverContent'];
    if (sc is Map) {
      final input = (sc['inputTranscription'] as Map?)?['text'];
      if (input is String && input.isNotEmpty) {
        _user.write(input);
        _heardUser = DateTime.now();
      }
      final parts = ((sc['modelTurn'] as Map?)?['parts'] as List?) ?? const [];
      for (final p in parts) {
        final data = (p is Map ? p['inlineData'] as Map? : null)?['data'];
        if (data is! String) continue;
        if (!_replying) {
          _replying = true;
          // The person's words are complete once the bot starts answering.
          _add('user', _user);
          if (_heardUser != null) {
            latency.value = DateTime.now()
                .difference(_heardUser!)
                .inMilliseconds;
            _heardUser = null;
          }
        }
        onAudio(base64Decode(data));
      }
      final output = (sc['outputTranscription'] as Map?)?['text'];
      if (output is String && output.isNotEmpty) _bot.write(output);
      if (sc['interrupted'] == true) onInterrupted();
      if (sc['turnComplete'] == true || sc['interrupted'] == true) {
        _replying = false;
        _add('user', _user);
        _add('assistant', _bot);
      }
    }

    final calls = (m['toolCall'] as Map?)?['functionCalls'] as List?;
    for (final c in calls ?? const []) {
      if (c is! Map || c['id'] is! String || c['name'] is! String) continue;
      final id = c['id'] as String;
      _names[id] = c['name'] as String;
      final args = c['args'];
      tools.add(
        CallToolRequest(
          id,
          c['name'] as String,
          args is Map ? args.cast<String, Object?>() : const {},
        ),
      );
    }
  }

  /// The reply to a tool call, in the shape Gemini expects.
  Map<String, Object?> toolResponse(String id, String output) => {
    'toolResponse': {
      'functionResponses': [
        {
          'id': id,
          'name': _names.remove(id) ?? '',
          'response': {'result': output},
        },
      ],
    },
  };
}

/// The mic and speaker of a call, as raw PCM. Swapped for a fake in tests.
abstract class PcmAudio {
  /// Starts the mic; [onChunk] gets 16 kHz mono 16-bit PCM.
  Future<void> startMic(void Function(Uint8List pcm16k) onChunk);
  Future<void> stopMic();

  /// Queues 24 kHz mono 16-bit PCM to play.
  void play(Uint8List pcm24k);

  /// Drops whatever is queued (barge-in).
  void flush();
  Future<void> dispose();
}

/// The mic through `record` (with echo cancellation, so the bot doesn't hear itself on speaker)
/// and playback through SoLoud's buffer stream, on every platform.
class DevicePcmAudio implements PcmAudio {
  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _mic;
  Future<AudioSource>? _stream;
  SoundHandle? _handle;

  /// Audio arrives in many small pieces; they're queued one after another so they play in order
  /// on one stream (starting the player once, not once per piece).
  Future<void> _queue = Future.value();

  @override
  Future<void> startMic(void Function(Uint8List pcm16k) onChunk) async {
    if (!await _recorder.hasPermission()) {
      throw StateError('Microphone permission denied');
    }
    final s = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: geminiInputRate,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceCommunication,
          audioManagerMode: AudioManagerMode.modeInCommunication,
          speakerphone: true,
        ),
      ),
    );
    _mic = s.listen(onChunk);
    // Calls start on the speaker; the call screen can switch to the earpiece or a headset.
    if (CallAudioRoutes.supported) {
      try {
        await DeviceCallAudioRoutes().select(const CallRoute(CallRouteKind.speaker));
      } catch (e) {
        debugPrint('call audio: could not switch to the speaker: $e');
      }
    }
  }

  @override
  Future<void> stopMic() async {
    await _mic?.cancel();
    _mic = null;
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  /// One player and one buffer stream for the whole call, made once.
  Future<AudioSource> _player() => _stream ??= () async {
    final soloud = SoLoud.instance;
    if (!soloud.isInitialized) await soloud.init();
    return soloud.setBufferStream(
      bufferingType: BufferingType.released,
      // Start as soon as a little audio is in: replies should feel instant.
      bufferingTimeNeeds: 0.1,
      sampleRate: geminiOutputRate,
      channels: Channels.mono,
      format: BufferType.s16le,
    );
  }();

  @override
  void play(Uint8List pcm24k) {
    _queue = _queue.then((_) async {
      final soloud = SoLoud.instance;
      final stream = await _player();
      soloud.addAudioDataStream(stream, pcm24k);
      // (Re)start the voice if it isn't playing (first piece, or it ended after a long pause).
      final h = _handle;
      if (h == null || !soloud.getIsValidVoiceHandle(h)) _handle = soloud.play(stream);
    }).catchError((Object e) => debugPrint('call audio: playback failed: $e'));
  }

  @override
  void flush() {
    _queue = _queue.then((_) async {
      final s = _stream;
      if (s == null) return;
      try {
        SoLoud.instance.resetBufferStream(await s);
      } catch (_) {
        // Already ended: nothing queued to drop.
      }
    });
  }

  @override
  Future<void> dispose() async {
    await stopMic();
    await _recorder.dispose();
    await _queue;
    final h = _handle;
    if (h != null && SoLoud.instance.getIsValidVoiceHandle(h)) await SoLoud.instance.stop(h);
    final s = _stream;
    if (s != null) await SoLoud.instance.disposeSource(await s);
    _handle = null;
    _stream = null;
  }
}

/// A live call on Gemini Live: a WebSocket to Google with the single-use token the server minted
/// (which locks the bot's instructions, tools and voice), the mic streamed up as PCM, and the
/// reply played as it arrives. Connections last about 10 minutes, so the call resumes the same
/// session on a new connection when Google says the current one is ending.
/// Loudness of a Gemini Live call: the microphone as it's captured, and the bot's voice in 50 ms
/// steps timed to when each piece plays (audio arrives ahead of playback).
class _GeminiLevels implements CallLevels {
  static const _step = Duration(milliseconds: 50);
  static const _stepBytes = geminiOutputRate * 2 ~/ 20;

  double _mic = 0;
  DateTime _micAt = DateTime(0);
  var muted = false;
  final _out = <(DateTime, double)>[];

  void heard(Uint8List pcm) {
    _mic = pcmLevel(pcm);
    _micAt = DateTime.now();
  }

  /// [pcm] starts playing at [at].
  void queued(Uint8List pcm, DateTime at) {
    for (var i = 0; i < pcm.length; i += _stepBytes) {
      _out.add((at, pcmLevel(pcm, i, i + _stepBytes)));
      at = at.add(_step);
    }
  }

  void clear() => _out.clear();

  @override
  double get input =>
      muted || DateTime.now().difference(_micAt) > const Duration(milliseconds: 300) ? 0 : _mic;

  @override
  double get output {
    final now = DateTime.now();
    while (_out.isNotEmpty && !_out.first.$1.add(_step).isAfter(now)) {
      _out.removeAt(0);
    }
    if (_out.isEmpty || _out.first.$1.isAfter(now)) return 0;
    return _out.first.$2;
  }
}

class GeminiLiveCall implements VoiceCall {
  GeminiLiveCall._(this._session, this._audio, this._connect);

  final VoiceSession _session;
  final PcmAudio _audio;
  final WebSocketChannel Function(Uri url) _connect;

  final _state = ValueNotifier(CallState.connecting);
  final _speaking = ValueNotifier(false);
  final _levels = _GeminiLevels();
  late final _ev = GeminiLiveEvents(
    send: _send,
    onAudio: _onAudio,
    onInterrupted: _onInterrupted,
  );
  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _sub;
  var _muted = false;
  var _ended = false;
  var _greeted = false;
  DateTime _playingUntil = DateTime.now();
  Timer? _speakingTimer;

  static Future<GeminiLiveCall> open(
    VoiceSession session, {
    PcmAudio? audio,
    WebSocketChannel Function(Uri url)? connect,
  }) async {
    final c = GeminiLiveCall._(
      session,
      audio ?? DevicePcmAudio(),
      connect ?? WebSocketChannel.connect,
    );
    await c._open();
    await c._audio.startMic(c._onMic);
    return c;
  }

  Future<void> _open({String? resume}) async {
    final url = Uri.parse(_session.connectUrl)
        .replace(queryParameters: {'access_token': _session.clientSecret});
    final ws = _connect(url);
    _ws = ws;
    _ev.ready = false;
    _ev.goingAway = false;
    _sub = ws.stream.listen(
      (data) =>
          _onMessage(data is String ? data : utf8.decode(data as List<int>)),
      onDone: () => _onClosed(ws),
      onError: (_) => _onClosed(ws),
    );
    await ws.ready;
    _send({
      'setup': {
        ...?_session.setup,
        'sessionResumption': resume == null
            ? <String, Object?>{}
            : {'handle': resume},
      },
    });
  }

  void _onMessage(String raw) {
    final wasReady = _ev.ready;
    _ev.handle(raw);
    if (!wasReady && _ev.ready) {
      _state.value = CallState.live;
      // An answered phone call: the bot opens with why it called.
      if (_session.speakFirst && !_greeted) {
        _greeted = true;
        _send({
          'clientContent': {
            'turns': [
              {
                'role': 'user',
                'parts': [
                  {'text': '(The call has connected. Start speaking.)'},
                ],
              },
            ],
            'turnComplete': true,
          },
        });
      }
    }
    if (_ev.goingAway) unawaited(_reconnect());
  }

  Future<void> _reconnect() async {
    final handle = _ev.resumeHandle;
    if (_ended || handle == null) return;
    _ev.goingAway = false;
    final old = _ws;
    await _sub?.cancel();
    await _open(resume: handle);
    await old?.sink.close();
  }

  void _onClosed(WebSocketChannel ws) {
    if (_ended || ws != _ws) return;
    // Dropped mid-call: resume the session if Google gave a handle, else the call is over.
    if (_ev.resumeHandle != null) {
      unawaited(
        _reconnect().catchError((_) => _state.value = CallState.failed),
      );
    } else {
      _state.value = _ev.ready ? CallState.ended : CallState.failed;
    }
  }

  void _send(Map<String, Object?> message) =>
      _ws?.sink.add(jsonEncode(message));

  void _onMic(Uint8List pcm) {
    if (_muted || !_ev.ready || _ended) return;
    _levels.heard(pcm);
    _send({
      'realtimeInput': {
        'audio': {
          'data': base64Encode(pcm),
          'mimeType': 'audio/pcm;rate=$geminiInputRate',
        },
      },
    });
  }

  void _onAudio(Uint8List pcm) {
    _audio.play(pcm);
    // Track when the queued audio will finish, to drive the speaking avatar.
    final now = DateTime.now();
    final start = _playingUntil.isAfter(now) ? _playingUntil : now;
    _levels.queued(pcm, start);
    _playingUntil = start.add(
      Duration(microseconds: pcm.length * 1000000 ~/ (geminiOutputRate * 2)),
    );
    _speaking.value = true;
    _speakingTimer?.cancel();
    _speakingTimer = Timer(
      _playingUntil.difference(now),
      () => _speaking.value = false,
    );
  }

  void _onInterrupted() {
    _audio.flush();
    _levels.clear();
    _speakingTimer?.cancel();
    _playingUntil = DateTime.now();
    _speaking.value = false;
  }

  @override
  ValueListenable<CallState> get state => _state;
  @override
  ValueListenable<List<CallTurn>> get transcript => _ev.transcript;
  @override
  ValueListenable<int?> get replyLatencyMs => _ev.latency;
  @override
  ValueListenable<bool> get speaking => _speaking;
  @override
  Stream<CallToolRequest> get toolCalls => _ev.tools.stream;

  @override
  Map<String, int>? get usage => _ev.hasUsage ? Map.of(_ev.usage) : null;

  @override
  CallLevels get levels => _levels;

  @override
  CallAudioRoutes? get routes => _audio is DevicePcmAudio && CallAudioRoutes.supported ? DeviceCallAudioRoutes() : null;

  @override
  void sendToolResult(String callId, String output) =>
      _send(_ev.toolResponse(callId, output));

  @override
  void tellModel(String note) => _send({
    'clientContent': {
      'turns': [
        {
          'role': 'user',
          'parts': [
            {'text': note},
          ],
        },
      ],
      'turnComplete': true,
    },
  });

  @override
  void setMuted(bool muted) {
    if (muted && !_muted) {
      _send({
        'realtimeInput': {'audioStreamEnd': true},
      });
    }
    _muted = muted;
    _levels.muted = muted;
  }

  @override
  Future<void> hangUp() async {
    if (_ended) return;
    _ended = true;
    _state.value = CallState.ended;
    _speakingTimer?.cancel();
    _speaking.value = false;
    await _audio.dispose();
    await _sub?.cancel();
    await _ws?.sink.close();
    await _ev.tools.close();
  }

  /// For tests: the largest gap between queued audio and now, in milliseconds.
  @visibleForTesting
  int get queuedAudioMs =>
      math.max(0, _playingUntil.difference(DateTime.now()).inMilliseconds);
}
