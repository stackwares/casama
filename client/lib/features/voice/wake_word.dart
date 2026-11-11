import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../core/router.dart';

/// Wake word (D-144): on desktop and Android, saying the phrase opens a live call with the chosen
/// bot. Detection runs on the device with an open-source keyword spotter (sherpa-onnx, Apache-2.0,
/// and its Apache-2.0 GigaSpeech keyword model), downloaded the first time it's turned on. Audio
/// never leaves the device until the call opens. It listens while the app is open.
bool get wakeWordSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

class WakeWordSettings {
  const WakeWordSettings({this.enabled = false, this.phrase = 'hey casama', this.botId});
  final bool enabled;
  final String phrase;
  final String? botId;

  WakeWordSettings copyWith({bool? enabled, String? phrase, String? botId}) => WakeWordSettings(enabled: enabled ?? this.enabled, phrase: phrase ?? this.phrase, botId: botId ?? this.botId);
}

/// The phrase as the keyword model's tokens (its BPE pieces, words starting with ▁): every
/// segmentation with the fewest pieces, up to four, each as a keyword line for the same tag. The
/// model's own tokenizer isn't shipped, and listing the shortest spellings matches it closely.
List<String> keywordLines(String phrase, Set<String> vocab, {String tag = 'WAKE', int max = 4}) {
  final words = phrase.toUpperCase().replaceAll(RegExp(r"[^A-Z' ]"), ' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  List<List<String>> segment(String s) {
    // best[i]: the fewest pieces covering s[0..i), with every segmentation that achieves it.
    final best = List<List<List<String>>?>.filled(s.length + 1, null)..[0] = [<String>[]];
    for (var i = 0; i < s.length; i++) {
      final from = best[i];
      if (from == null) continue;
      for (var j = i + 1; j <= s.length; j++) {
        final piece = s.substring(i, j);
        if (!vocab.contains(piece)) continue;
        final next = [
          for (final p in from) [...p, piece],
        ];
        final cur = best[j];
        if (cur == null || next.first.length < cur.first.length) {
          best[j] = next.take(max).toList();
        } else if (next.first.length == cur.first.length) {
          best[j] = [...cur, ...next].take(max).toList();
        }
      }
    }
    return best[s.length] ?? const [];
  }

  var combos = <List<String>>[<String>[]];
  for (final w in words) {
    final segs = segment('\u2581$w');
    if (segs.isEmpty) return const [];
    combos = [
      for (final c in combos)
        for (final s in segs) [...c, ...s],
    ].take(max).toList();
  }
  return [for (final c in combos) '${c.join(' ')} @$tag'];
}

/// Something that hears a phrase.
abstract class WakeWordEngine {
  /// Prepares the model (downloading it once) and reports progress from 0 to 1.
  Future<void> prepare({void Function(double)? onProgress});

  /// Starts listening; the stream fires each time the phrase is heard.
  Stream<void> listen(String phrase);
  Future<void> stop();
}

/// The model: sherpa-onnx's GigaSpeech keyword spotter (about 13 MB).
class WakeWordModel {
  static const url = 'https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01.tar.bz2';
  static const folder = 'sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01';

  /// The archive's SHA-256, checked before anything is unpacked.
  static const sha256Hex = 'f170013b4716e41b62b9bfd809687c207cef798ef9bc6534d524e17af9b6561a';
  static const files = ['encoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx', 'decoder-epoch-12-avg-2-chunk-16-left-64.int8.onnx', 'joiner-epoch-12-avg-2-chunk-16-left-64.int8.onnx', 'tokens.txt'];

  /// Downloads and unpacks the model into the app's support folder; returns that folder.
  static Future<String> ensure({void Function(double)? onProgress, http.Client? client}) async {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/wake-word/$folder');
    if (files.every((f) => File('${dir.path}/$f').existsSync())) return dir.path;
    final c = client ?? http.Client();
    final res = await c.send(http.Request('GET', Uri.parse(url)));
    if (res.statusCode != 200) throw StateError('The wake word model could not be downloaded (${res.statusCode})');
    final total = res.contentLength ?? 0;
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in res.stream) {
      bytes.add(chunk);
      if (total > 0) onProgress?.call(bytes.length / total);
    }
    final data = bytes.takeBytes();
    if (sha256.convert(data).toString() != sha256Hex) throw StateError("The wake word model didn't match its checksum");
    final tar = TarDecoder().decodeBytes(BZip2Decoder().decodeBytes(data));
    for (final f in tar.files) {
      if (!f.isFile) continue;
      final name = f.name.split('/').last;
      if (!files.contains(name)) continue;
      final out = File('${dir.path}/$name');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(f.content as List<int>);
    }
    if (!files.every((f) => File('${dir.path}/$f').existsSync())) throw StateError('The wake word model is incomplete');
    return dir.path;
  }
}

/// 16-bit little-endian mono PCM from the microphone, as samples between -1 and 1. Chunks can
/// start at an odd byte and end halfway through a sample, so it reads bytes rather than viewing
/// the buffer as 16-bit values (which needs an even offset), and keeps a leftover byte for the
/// next chunk.
class Pcm16Decoder {
  int? _carry;

  Float32List decode(Uint8List chunk) {
    final carry = _carry;
    final total = chunk.length + (carry == null ? 0 : 1);
    final out = Float32List(total ~/ 2);
    var i = 0;
    var o = 0;
    if (carry != null && chunk.isNotEmpty) {
      out[o++] = _sample(carry, chunk[0]);
      i = 1;
    }
    for (; i + 1 < chunk.length; i += 2) {
      out[o++] = _sample(chunk[i], chunk[i + 1]);
    }
    _carry = i < chunk.length ? chunk[i] : (chunk.isEmpty ? carry : null);
    return out;
  }

  static double _sample(int lo, int hi) {
    final v = (hi << 8) | lo;
    return (v >= 0x8000 ? v - 0x10000 : v) / 32768.0;
  }
}

class SherpaWakeWordEngine implements WakeWordEngine {
  String? _dir;
  final _rec = AudioRecorder();
  sherpa.KeywordSpotter? _spotter;
  sherpa.OnlineStream? _stream;
  StreamSubscription<Uint8List>? _sub;
  StreamController<void>? _out;

  @override
  Future<void> prepare({void Function(double)? onProgress}) async {
    _dir ??= await WakeWordModel.ensure(onProgress: onProgress);
  }

  @override
  Stream<void> listen(String phrase) {
    final out = _out = StreamController<void>();
    unawaited(() async {
      try {
        await prepare();
        sherpa.initBindings();
        final d = _dir!;
        final vocab = {
          for (final l in await File('$d/tokens.txt').readAsLines())
            if (l.trim().isNotEmpty) l.split(' ').first,
        };
        final lines = keywordLines(phrase, vocab);
        if (lines.isEmpty) throw StateError("That wake phrase can't be spelled with the model's tokens; try simpler words");
        final keywords = lines.join('\n');
        _spotter = sherpa.KeywordSpotter(
          sherpa.KeywordSpotterConfig(
            model: sherpa.OnlineModelConfig(
              transducer: sherpa.OnlineTransducerModelConfig(encoder: '$d/${WakeWordModel.files[0]}', decoder: '$d/${WakeWordModel.files[1]}', joiner: '$d/${WakeWordModel.files[2]}'),
              tokens: '$d/tokens.txt',
              debug: false,
            ),
            keywordsBuf: keywords,
            keywordsBufSize: keywords.length,
          ),
        );
        _stream = _spotter!.createStream();
        if (!await _rec.hasPermission()) throw StateError('Microphone permission is needed for the wake word');
        final audio = await _rec.startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1));
        final pcm = Pcm16Decoder();
        _sub = audio.listen(
          (chunk) {
            final samples = pcm.decode(chunk);
            final s = _stream;
            final spotter = _spotter;
            if (s == null || spotter == null || samples.isEmpty) return;
            s.acceptWaveform(samples: samples, sampleRate: 16000);
            while (spotter.isReady(s)) {
              spotter.decode(s);
            }
            if (spotter.getResult(s).keyword.isNotEmpty) {
              spotter.reset(s);
              if (!out.isClosed) out.add(null);
            }
          },
          // A microphone error ends listening through the stream, not as an unhandled crash.
          onError: (Object e) {
            if (!out.isClosed) out.addError(e);
          },
        );
      } catch (e) {
        if (!out.isClosed) out.addError(e);
      }
    }());
    return out.stream;
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _rec.stop().catchError((_) => null);
    _stream?.free();
    _spotter?.free();
    _stream = null;
    _spotter = null;
    await _out?.close();
  }
}

final wakeWordEngineProvider = Provider<WakeWordEngine>((ref) => SherpaWakeWordEngine());

/// The device's wake word settings, and listening while it's on.
class WakeWordController extends Notifier<WakeWordSettings> {
  StreamSubscription<void>? _sub;
  late WakeWordEngine _engine;

  @override
  WakeWordSettings build() {
    _engine = ref.read(wakeWordEngineProvider);
    ref.onDispose(() {
      unawaited(_sub?.cancel());
      unawaited(_engine.stop());
    });
    unawaited(_load());
    return const WakeWordSettings();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = WakeWordSettings(enabled: p.getBool('wake.enabled') ?? false, phrase: p.getString('wake.phrase') ?? 'hey casama', botId: p.getString('wake.bot'));
      if (state.enabled) await _startListening();
    } catch (_) {}
  }

  Future<void> save(WakeWordSettings s, {void Function(double)? onProgress}) async {
    if (s.enabled) await _engine.prepare(onProgress: onProgress);
    state = s;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('wake.enabled', s.enabled);
      await p.setString('wake.phrase', s.phrase);
      if (s.botId != null) await p.setString('wake.bot', s.botId!);
    } catch (_) {}
    await _stopListening();
    if (s.enabled) await _startListening();
  }

  Future<void> _startListening() async {
    if (!wakeWordSupported && !_testing) return;
    final botId = state.botId;
    if (botId == null) return;
    _sub = _engine.listen(state.phrase).listen((_) {
      // Heard it: open a live call with the chosen bot.
      unawaited(ref.read(routerProvider).push('/bots/$botId/call'));
    }, onError: (Object e) => debugPrint('wake word: $e'));
  }

  Future<void> _stopListening() async {
    await _sub?.cancel();
    _sub = null;
    await _engine.stop();
  }

  /// Tests run on a host platform that may not be a wake word platform.
  static bool _testing = false;
  @visibleForTesting
  static set testing(bool v) => _testing = v;
}

final wakeWordProvider = NotifierProvider<WakeWordController, WakeWordSettings>(WakeWordController.new);
