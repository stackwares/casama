import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/backend.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import 'media_kind.dart';

/// A video in a chat. A still card (its first frame, a play button, the length) until it's tapped;
/// then it plays right there with play/pause, a scrubber, mute and full screen. Never plays by
/// itself. Videos kept with the chat load their first frame up front; others show a dark tile.
/// Where the official player has no implementation (Windows, Linux) the card opens the system's
/// player instead.
class ChatVideo extends ConsumerStatefulWidget {
  const ChatVideo({
    super.key,
    required this.attachment,
    this.computerId,
    this.maxWidth = 320,
  });

  final AttachmentRef attachment;

  /// The bot's computer, for videos that live there.
  final String? computerId;
  final double maxWidth;

  @override
  ConsumerState<ChatVideo> createState() => _ChatVideoState();
}

class _ChatVideoState extends ConsumerState<ChatVideo> {
  VideoPlayerController? _controller;

  /// Loaded but not started: its first frame is the poster, and play starts it.
  VideoPlayerController? _ready;
  var _loading = false;

  AttachmentRef get _a => widget.attachment;

  @override
  void initState() {
    super.initState();
    // Streams from the API with range requests, so this reads little more than the first frame.
    // Not on the web, where the player can't send the sign-in header.
    if (_a.mediaId != null &&
        mediaPluginsAvailable &&
        inlineVideoSupported &&
        !kIsWeb) {
      unawaited(_preload());
    }
  }

  Future<void> _preload() async {
    final backend = ref.read(backendProvider);
    final c = VideoPlayerController.networkUrl(
      Uri.parse(backend.chatMediaUrl(_a.mediaId!)),
      httpHeaders: backend.authHeaders,
    );
    try {
      await c.initialize();
      // Shows the first frame (iOS draws nothing until a seek).
      await c.seekTo(Duration.zero);
    } catch (_) {
      await c.dispose();
      return;
    }
    if (!mounted || _controller != null) {
      await c.dispose();
      return;
    }
    setState(() => _ready = c);
  }

  @override
  void dispose() {
    _controller?.dispose();
    if (!identical(_ready, _controller)) _ready?.dispose();
    super.dispose();
  }

  Future<Uint8List> _bytes() {
    final backend = ref.read(backendProvider);
    final id = _a.mediaId;
    if (id != null) return backend.chatMedia(id);
    final path = computerPathFromLink(_a.path) ?? _a.path;
    return backend.downloadFile(widget.computerId ?? '', path);
  }

  Future<File> _tempFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/casama/video-${_a.path.hashCode}-${_a.name}',
    );
    await file.parent.create(recursive: true);
    if (!await file.exists() || await file.length() != bytes.length) {
      await file.writeAsBytes(bytes);
    }
    return file;
  }

  Future<void> _play() async {
    if (!inlineVideoSupported) {
      final bytes = await _bytes();
      if (mounted) await openFileBytes(context, _a.name, bytes);
      return;
    }
    if (_ready case final ready?) {
      setState(() => _controller = ready);
      await ready.play();
      return;
    }
    setState(() => _loading = true);
    try {
      final backend = ref.read(backendProvider);
      final id = _a.mediaId;
      final VideoPlayerController c;
      if (id != null) {
        // Streams from the API with range requests.
        c = VideoPlayerController.networkUrl(
          Uri.parse(backend.chatMediaUrl(id)),
          httpHeaders: backend.authHeaders,
        );
      } else if (kIsWeb) {
        final bytes = await _bytes();
        c = VideoPlayerController.networkUrl(
          Uri.dataFromBytes(bytes, mimeType: mimeFor(_a.name)),
        );
      } else {
        c = VideoPlayerController.file(await _tempFile(await _bytes()));
      }
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
      await c.play();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final shape = c ?? _ready;
    final aspect = shape != null && shape.value.isInitialized
        ? shape.value.aspectRatio
        : (_a.width != null && _a.height != null && _a.height! > 0
              ? _a.width! / _a.height!
              : 16 / 9);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          widget.maxWidth,
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : widget.maxWidth,
        );
        // Portrait clips stay a sensible height.
        final height = math.min(width / aspect, kChatImageMaxHeight);
        return ClipRRect(
          borderRadius: AppRadius.tileAll,
          child: SizedBox(
            width: math.min(width, height * aspect),
            height: height,
            child: c == null
                ? _Poster(
                    key: attachmentKey(_a.path),
                    attachment: _a,
                    frame: _ready,
                    loading: _loading,
                    systemPlayer: !inlineVideoSupported,
                    onPlay: () => runGuarded(context, _play),
                  )
                : VideoSurface(
                    controller: c,
                    onFullScreen: () => openFullScreenVideo(context, c),
                  ),
          ),
        );
      },
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    super.key,
    required this.attachment,
    this.frame,
    required this.loading,
    required this.systemPlayer,
    required this.onPlay,
  });
  final AttachmentRef attachment;

  /// A loaded player whose first frame fills the card.
  final VideoPlayerController? frame;
  final bool loading;
  final bool systemPlayer;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final seconds = attachment.durationS;
    return Material(
      color: Colors.black,
      child: InkWell(
        onTap: loading ? null : onPlay,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.35),
                  const Color(0xFF15131A),
                ),
                const Color(0xFF0B0A0E),
              ],
            ),
          ),
          child: Stack(
            children: [
              if (frame case final f?) ...[
                Positioned.fill(child: VideoPlayer(f)),
                // Keeps the label at the bottom readable on any frame.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                  ),
                ),
              ],
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          systemPlayer
                              ? LucideIcons.squareArrowOutUpRight
                              : LucideIcons.play,
                          color: Colors.white,
                          size: 26,
                        ),
                ),
              ),
              PositionedDirectional(
                start: 12,
                end: 12,
                bottom: 10,
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.film,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        systemPlayer
                            ? context.l10n.openInSystemPlayer
                            : attachmentLabel(context.l10n, attachment),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (seconds != null && seconds > 0)
                      _Chip(
                        formatClock(
                          Duration(milliseconds: (seconds * 1000).round()),
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

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFeatures: AppText.tabular,
        ),
      ),
    ),
  );
}

/// A playing video with its controls: tap shows or hides them; they fade by themselves while
/// it plays.
class VideoSurface extends StatefulWidget {
  const VideoSurface({
    super.key,
    required this.controller,
    this.onFullScreen,
    this.fullScreen = false,
  });
  final VideoPlayerController controller;
  final VoidCallback? onFullScreen;
  final bool fullScreen;

  @override
  State<VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<VideoSurface> {
  var _controls = true;
  Timer? _hide;

  VideoPlayerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_changed);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hide?.cancel();
    _c.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted && _c.value.isPlaying) setState(() => _controls = false);
    });
  }

  void _toggle() {
    setState(() => _controls = !_controls);
    if (_controls) _scheduleHide();
  }

  Future<void> _playPause() async {
    final v = _c.value;
    if (v.isPlaying) {
      await _c.pause();
    } else {
      if (v.position >= v.duration && v.duration > Duration.zero) {
        await _c.seekTo(Duration.zero);
      }
      await _c.play();
    }
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final v = _c.value;
    final l10n = context.l10n;
    return ColoredBox(
      color: Colors.black,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: v.aspectRatio,
                child: VideoPlayer(_c),
              ),
            ),
            AnimatedOpacity(
              opacity: _controls || !v.isPlaying ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !(_controls || !v.isPlaying),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                      stops: [0.55, 1],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: IconButton.filled(
                          key: const Key('videoPlayPause'),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: Colors.white,
                            fixedSize: const Size(56, 56),
                          ),
                          tooltip: v.isPlaying ? l10n.pause : l10n.playMedia,
                          onPressed: _playPause,
                          icon: Icon(
                            v.isPlaying ? LucideIcons.pause : LucideIcons.play,
                            size: 26,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 4,
                        right: 4,
                        bottom: 0,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '${formatClock(v.position)} / ${formatClock(v.duration)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: AppText.tabular,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: VideoProgressIndicator(
                                _c,
                                allowScrubbing: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                colors: VideoProgressColors(
                                  playedColor: Colors.white,
                                  bufferedColor: Colors.white38,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: v.volume == 0 ? l10n.unmute : l10n.mute,
                              color: Colors.white,
                              iconSize: 18,
                              onPressed: () =>
                                  _c.setVolume(v.volume == 0 ? 1 : 0),
                              icon: Icon(
                                v.volume == 0
                                    ? LucideIcons.volumeX
                                    : LucideIcons.volume2,
                              ),
                            ),
                            IconButton(
                              tooltip: widget.fullScreen
                                  ? l10n.exitFullScreen
                                  : l10n.fullScreen,
                              color: Colors.white,
                              iconSize: 18,
                              onPressed: widget.fullScreen
                                  ? () => Navigator.of(context).maybePop()
                                  : widget.onFullScreen,
                              icon: Icon(
                                widget.fullScreen
                                    ? LucideIcons.minimize2
                                    : LucideIcons.maximize2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The same video, full screen; it keeps playing where it was when you come back.
Future<void> openFullScreenVideo(
  BuildContext context,
  VideoPlayerController controller,
) => Navigator.of(context, rootNavigator: true).push(
  PageRouteBuilder<void>(
    opaque: true,
    barrierColor: Colors.black,
    pageBuilder: (_, _, _) => Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: VideoSurface(controller: controller, fullScreen: true),
      ),
    ),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
);
