import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/backend.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import 'media_kind.dart';

/// A sound in a chat: a compact player with play/pause, a scrubber and the time. The audio
/// loads on the first tap and never plays by itself.
class ChatAudio extends ConsumerStatefulWidget {
  const ChatAudio({super.key, required this.attachment, this.computerId});
  final AttachmentRef attachment;
  final String? computerId;

  @override
  ConsumerState<ChatAudio> createState() => _ChatAudioState();
}

class _ChatAudioState extends ConsumerState<ChatAudio> {
  AudioPlayer? _player;
  final _subs = <StreamSubscription<Object?>>[];
  var _loading = false;
  var _playing = false;
  Duration _position = Duration.zero;
  Duration? _duration;

  AttachmentRef get _a => widget.attachment;

  @override
  void initState() {
    super.initState();
    final s = _a.durationS;
    if (s != null) _duration = Duration(milliseconds: (s * 1000).round());
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  Future<AudioPlayer> _load() async {
    final backend = ref.read(backendProvider);
    final player = AudioPlayer();
    final id = _a.mediaId;
    if (id != null) {
      await player.setUrl(
        backend.chatMediaUrl(id),
        headers: backend.authHeaders,
      );
    } else {
      final path = computerPathFromLink(_a.path) ?? _a.path;
      final bytes = await backend.downloadFile(widget.computerId ?? '', path);
      if (kIsWeb) {
        await player.setAudioSource(
          AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: mimeFor(_a.name))),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/casama/audio-${_a.path.hashCode}-${_a.name}',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        await player.setFilePath(file.path);
      }
    }
    _subs
      ..add(
        player.positionStream.listen((p) {
          if (mounted) setState(() => _position = p);
        }),
      )
      ..add(
        player.durationStream.listen((d) {
          if (mounted && d != null) setState(() => _duration = d);
        }),
      )
      ..add(
        player.playerStateStream.listen((s) {
          if (!mounted) return;
          if (s.processingState == ProcessingState.completed) {
            player
              ..pause()
              ..seek(Duration.zero);
          }
          setState(
            () => _playing =
                s.playing && s.processingState != ProcessingState.completed,
          );
        }),
      );
    return player;
  }

  Future<void> _toggle() async {
    var player = _player;
    if (player == null) {
      setState(() => _loading = true);
      try {
        player = await _load();
        if (!mounted) {
          await player.dispose();
          return;
        }
        _player = player;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
    if (player.playing) {
      await player.pause();
    } else {
      unawaited(player.play());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final total = _duration ?? Duration.zero;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    return Material(
      key: attachmentKey(_a.path),
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.rowAll,
        side: BorderSide(color: context.appColors.hairline),
      ),
      child: SizedBox(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          child: Row(
            children: [
              IconButton.filled(
                key: Key('audioPlay-${_a.path}'),
                tooltip: _playing ? context.l10n.pause : context.l10n.playMedia,
                onPressed: _loading ? null : () => runGuarded(context, _toggle),
                icon: _loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Icon(
                        _playing ? LucideIcons.pause : LucideIcons.play,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attachmentLabel(context.l10n, _a),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        overlayShape: SliderComponentShape.noOverlay,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: SizedBox(
                        height: 20,
                        child: Slider(
                          value: progress,
                          onChanged: _player == null || total == Duration.zero
                              ? null
                              : (v) => _player!.seek(total * v),
                        ),
                      ),
                    ),
                    Text(
                      total == Duration.zero
                          ? formatClock(_position)
                          : '${formatClock(_position)} / ${formatClock(total)}',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
