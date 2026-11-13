import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'call_audio.dart';
import 'dictation_bytes_web.dart' if (dart.library.io) 'dictation_bytes_io.dart';
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

  // AAC in an m4a file: the format both phone recorders actually fill. A 16 kHz WAV often
  // comes back header-only, and Bluetooth A2DP on iOS can leave the mic silent.
  static const _nativeConfig = RecordConfig(
    encoder: AudioEncoder.aacLc,
    numChannels: 1,
    sampleRate: 44100,
    bitRate: 64000,
    androidConfig: AndroidRecordConfig(audioSource: AndroidAudioSource.mic, manageBluetooth: false),
    iosConfig: IosRecordConfig(categoryOptions: [IosAudioCategoryOption.defaultToSpeaker, IosAudioCategoryOption.allowBluetooth]),
  );

  @override
  Future<bool> start() async {
    if (!await _rec.hasPermission()) return false;
    try {
      await beginDictationCapture(() async {
        final path = '${(await getTemporaryDirectory()).path}/casama-dictation.m4a';
        await _rec.start(_nativeConfig, path: path);
      });
      return true;
    } catch (e, st) {
      debugPrint('dictation failed to start: $e\n$st');
      try {
        await cancel();
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<(Uint8List, String)?> stop() async {
    final clip = await endDictationCapture(_rec.stop);
    if (clip == null) return null;
    debugPrint('dictation clip ${clip.$1.length} bytes ${clip.$2}');
    return clip;
  }

  @override
  Future<void> cancel() => cancelDictationCapture(_rec.cancel);
}

/// Plays read-aloud audio.
/// Where read-aloud playback is (see [SpeechPlayer.playback]).
@immutable
class SpeechPlayback {
  const SpeechPlayback({
    required this.playing,
    required this.position,
    this.duration,
    this.completed = false,
  });
  final bool playing;
  final Duration position;
  final Duration? duration;

  /// It played to the end.
  final bool completed;
}

/// Plays a reply read aloud: one clip at a time, with pause, seeking and speed.
abstract class SpeechPlayer {
  /// Starts [mp3] from the beginning, replacing whatever was playing.
  Future<void> play(Uint8List mp3);
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);

  /// Changes while something plays: position, length, paused or not, and the end.
  Stream<SpeechPlayback> get playback;
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

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() async {
    if (_player.processingState == ProcessingState.completed) await _player.seek(Duration.zero);
    unawaited(_player.play());
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Stream<SpeechPlayback> get playback {
    SpeechPlayback now() => SpeechPlayback(
      playing: _player.playing && _player.processingState != ProcessingState.completed,
      position: _player.position,
      duration: _player.duration,
      completed: _player.processingState == ProcessingState.completed,
    );
    late final StreamController<SpeechPlayback> out;
    final subs = <StreamSubscription<Object?>>[];
    out = StreamController<SpeechPlayback>(
      onListen: () {
        void emit(Object? _) {
          if (!out.isClosed) out.add(now());
        }

        subs
          ..add(_player.playerStateStream.listen(emit))
          ..add(_player.positionStream.listen(emit))
          ..add(_player.durationStream.listen(emit));
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        await out.close();
      },
    );
    return out.stream;
  }
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
    final wav = bytes.length >= 4 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46;
    // ignore: experimental_member_use
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

final dictationProvider = Provider<Dictation>((ref) => RecordDictation());
final speechPlayerProvider = Provider<SpeechPlayer>((ref) => JustAudioPlayer());
/// Opens a live call: every call is Gemini Live (D-260).
class RealtimeVoiceConnector implements VoiceCallConnector {
  @override
  Future<VoiceCall> connect(VoiceSession session) => GeminiLiveCall.open(session);
}

final voiceCallConnectorProvider = Provider<VoiceCallConnector>((ref) => RealtimeVoiceConnector());
