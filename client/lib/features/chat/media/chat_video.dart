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
import '../../../core/media_cache.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import 'computer_thumbnail.dart';
import 'media_kind.dart';

/// A video in a chat. A still card (a poster, a play button, the length) until it's tapped;
/// then it plays right there with play/pause, a scrubber, mute and full screen. Never plays by
/// itself.
///
/// The poster is a picture, never a player: videos kept with the chat use the server's JPEG still
/// (`/v1/media/{id}/poster`), kept on the device like any chat picture, so a chat opened again
/// shows its clips on the first frame. Videos on the bot's computer use the thumbnail the
/// computer makes (D-226): from memory at once, from the device's cache right after, and from the
/// computer only for cards that stay on screen. A server that can't make posters falls back to
/// loading the player for its first frame. Where the official player has no implementation
/// (Windows, Linux) the card opens the system's player instead.
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

  /// Loaded but not started: its first frame is the poster, and play starts it. Only when the
  /// server has no poster for the clip.
  VideoPlayerController? _ready;
  var _loading = false;

  /// The poster: the server's still, or a computer file's thumbnail (D-226).
  Timer? _thumbTimer;
  ImageProvider? _thumb;
  Duration? _thumbDuration;
  double? _thumbAspect;

  /// Nothing more is coming: the card keeps its plain look (no shimmer).
  var _settled = false;

  /// A poster already in Flutter's image cache answers during initState, before setState is
  /// allowed.
  var _started = false;
  void _update(VoidCallback change) => _started ? setState(change) : change();

  AttachmentRef get _a => widget.attachment;

  /// The files API path of a video on the bot's computer, when a thumbnail can be asked for.
  String? get _computerPath =>
      _a.mediaId == null && widget.computerId != null
      ? computerPathFromLink(_a.path)
      : null;

  @override
  void initState() {
    super.initState();
    final backend = ref.read(backendProvider);
    if (_a.mediaId case final id?) {
      _thumb = cachedNetworkImage(
        backend.chatMediaPosterUrl(id),
        headers: backend.authHeaders,
      );
      _measure(_thumb!);
    } else if (_computerPath case final path?) {
      final kept = ComputerThumbnails.peek(widget.computerId!, path);
      if (kept != null) {
        _show(kept);
      } else {
        unawaited(_loadThumbnail(cachedOnly: true));
        // Only cards that stay on screen ask the computer: a chat scrolled past quickly
        // requests nothing.
        _thumbTimer = Timer(
          const Duration(milliseconds: 250),
          () => unawaited(_loadThumbnail()),
        );
      }
    } else {
      _settled = true;
    }
    _started = true;
  }

  void _show(ComputerThumbnail t) {
    _thumb = MemoryImage(t.bytes);
    _thumbDuration = t.duration;
    _settled = true;
    _measure(_thumb!);
  }

  Future<void> _loadThumbnail({bool cachedOnly = false}) async {
    final path = _computerPath;
    if (!mounted || path == null || _thumb != null) return;
    final t = await ComputerThumbnails.load(
      ref.read(backendProvider),
      widget.computerId!,
      path,
      cachedOnly: cachedOnly,
    );
    if (!mounted || _controller != null || _thumb != null) return;
    if (t == null) {
      if (!cachedOnly) setState(() => _settled = true);
      return;
    }
    _thumbTimer?.cancel();
    setState(() => _show(t));
  }

  /// Its shape, for videos whose size the chat doesn't know; and for chat media, whether the
  /// server had a poster at all (else the player draws the first frame).
  void _measure(ImageProvider image) {
    final known = _a.width != null && _a.height != null;
    if (known && _a.mediaId == null) return;
    final stream = image.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        final w = info.image.width, h = info.image.height;
        if (!mounted) return;
        _update(() {
          _settled = true;
          if (!known && w > 0 && h > 0) _thumbAspect = w / h;
        });
      },
      onError: (_, _) {
        stream.removeListener(listener);
        if (!mounted || _a.mediaId == null) return;
        _update(() {
          _thumb = null;
          _settled = !_canPreload;
        });
        if (_canPreload) unawaited(_preload());
      },
    );
    stream.addListener(listener);
  }

  /// Streams from the API with range requests, so this reads little more than the first frame.
  /// Not on the web, where the player can't send the sign-in header.
  bool get _canPreload =>
      _a.mediaId != null &&
      mediaPluginsAvailable &&
      inlineVideoSupported &&
      !kIsWeb;

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
      if (mounted) setState(() => _settled = true);
      return;
    }
    if (!mounted || _controller != null) {
      await c.dispose();
      return;
    }
    setState(() {
      _ready = c;
      _settled = true;
    });
  }

  @override
  void dispose() {
    _thumbTimer?.cancel();
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
              : _thumbAspect ?? 16 / 9);
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
                    image: _thumb,
                    duration: _thumbDuration,
                    loading: _loading,
                    waiting: !_settled,
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
    this.image,
    this.duration,
    required this.loading,
    this.waiting = false,
    required this.systemPlayer,
    required this.onPlay,
  });
  final AttachmentRef attachment;

  /// A loaded player whose first frame fills the card.
  final VideoPlayerController? frame;

  /// Otherwise a thumbnail from the bot's computer (D-226).
  final ImageProvider? image;

  /// The video's length from the computer, when the chat doesn't have it.
  final Duration? duration;
  final bool loading;

  /// Its picture is still coming: a soft light sweeps the card so it reads as loading.
  final bool waiting;
  final bool systemPlayer;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final seconds =
        attachment.durationS ??
        (duration == null ? null : duration!.inMilliseconds / 1000);
    final picture = frame != null || image != null;
    final fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
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
              // Under the picture, which covers it as it fades in.
              if (waiting) const Positioned.fill(child: _Sweep()),
              if (frame case final f?)
                Positioned.fill(child: VideoPlayer(f))
              else if (image case final i?)
                Positioned.fill(
                  child: Image(
                    key: const Key('videoThumbnail'),
                    image: i,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    frameBuilder: (context, child, shown, sync) => sync
                        ? child
                        : AnimatedOpacity(
                            opacity: shown == null ? 0 : 1,
                            duration: fade,
                            curve: Curves.easeOut,
                            child: child,
                          ),
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              if (picture) ...[
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

/// A slow band of light across a dark card whose picture is on its way. Still when the system
/// asks for less motion.
class _Sweep extends StatefulWidget {
  const _Sweep();

  @override
  State<_Sweep> createState() => _SweepState();
}

class _SweepState extends State<_Sweep> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value) * 3 - 1.5;
        return DecoratedBox(
          key: const Key('videoPosterLoading'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(t - 1, -0.3),
              end: Alignment(t + 1, 0.3),
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0),
              ],
            ),
          ),
        );
      },
    ),
  );
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
