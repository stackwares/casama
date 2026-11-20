import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../../core/analytics.dart';
import '../../../core/link_browser.dart';
import '../../../core/providers.dart';
import '../../../core/remote_config.dart';
import '../../../core/remote_content.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/app_card.dart';
import '../media/media_kind.dart';

/// The intro film (D-390, D-459), played in the app's own player: no ads, no suggestions, no
/// Shorts feed after it. Every address is a remote link (D-372), changed in Admin → App settings
/// without a release; these are the fallbacks.
///
/// - `intro_video`: the 16:9 film. `intro_video_vertical`: the 9:16 cut for upright phones; when
///   it isn't set, phones use `intro_video` too.
/// - `intro_video_youtube` / `intro_video_youtube_vertical`: "Watch on YouTube" in the player.
///
/// A film link that isn't a video file (`.mp4`, `.m4v`, `.mov`, `.webm`, `.m3u8`), say a YouTube
/// page, opens in the browser instead, so any https link set there works.
const kIntroFilmUrl = 'https://casama.ai/assets/film/casama-film-v8-16x9.mp4';
const kIntroFilmVerticalUrl =
    'https://casama.ai/assets/film/casama-film-v8-9x16.mp4';
const kIntroYoutubeUrl = 'https://www.youtube.com/watch?v=cype-154_p0';
const kIntroYoutubeVerticalUrl = 'https://www.youtube.com/shorts/-WthSEA26ag';

/// A phone held upright gets the 9:16 cut; everything else 16:9 (casama.ai's film dialog rule).
bool introUpright(Size screen) =>
    screen.height > screen.width && screen.width <= 600;

/// The film for this screen.
Uri introFilmUri(Size screen) => introUpright(screen)
    ? remoteUri(
        'intro_video_vertical',
        remoteLink('intro_video', kIntroFilmVerticalUrl),
      )
    : remoteUri('intro_video', kIntroFilmUrl);

/// The film on YouTube, for this screen.
Uri introYoutubeUri(Size screen) => introUpright(screen)
    ? remoteUri(
        'intro_video_youtube_vertical',
        remoteLink('intro_video_youtube', kIntroYoutubeVerticalUrl),
      )
    : remoteUri('intro_video_youtube', kIntroYoutubeUrl);

/// Whether the app's player can take [film]: a video file, on a platform with a player (not
/// Windows or Linux). Anything else opens in the browser.
bool introPlaysInApp(Uri film, {bool? playerAvailable}) {
  final path = film.path.toLowerCase();
  final file = const [
    '.mp4',
    '.m4v',
    '.mov',
    '.webm',
    '.m3u8',
  ].any(path.endsWith);
  return file &&
      (playerAvailable ?? (inlineVideoSupported && mediaPluginsAvailable));
}

/// Plays the film, in the app's player or (see [introPlaysInApp]) the browser. Says whether it
/// got going, so the empty-chat row stays when it couldn't (offline, say).
Future<bool> showIntroFilm(BuildContext context, String surface) async {
  final screen = MediaQuery.sizeOf(context);
  final film = introFilmUri(screen);
  if (!introPlaysInApp(film)) {
    Analytics.log('intro_video_opened', {
      'surface': surface,
      'player': 'browser',
    });
    return openWebLink(film);
  }
  Analytics.log('intro_video_opened', {'surface': surface, 'player': 'app'});
  final played = await Navigator.of(context, rootNavigator: true).push<bool>(
    PageRouteBuilder<bool>(
      opaque: true,
      transitionDuration: AppMotion.duration,
      reverseTransitionDuration: AppMotion.duration,
      pageBuilder: (_, _, _) =>
          IntroFilmPlayer(film: film, youtube: introYoutubeUri(screen)),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
  return played ?? false;
}

/// The film full screen on black: tap for the controls, a scrubber, sound, and at the end Replay
/// and Watch on YouTube. Esc closes and Space pauses on a keyboard. Pops true once it played.
class IntroFilmPlayer extends StatefulWidget {
  const IntroFilmPlayer({
    super.key,
    required this.film,
    required this.youtube,
    this.controllerFor,
  });
  final Uri film;
  final Uri youtube;

  /// Tests pass a player of their own.
  final VideoPlayerController Function(Uri film)? controllerFor;

  @override
  State<IntroFilmPlayer> createState() => _IntroFilmPlayerState();
}

class _IntroFilmPlayerState extends State<IntroFilmPlayer> {
  VideoPlayerController? _c;
  var _failed = false;
  var _ended = false;
  var _controls = true;
  var _played = false;
  Timer? _hide;

  /// How far they got, for analytics (0 to 100).
  var _furthest = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final old = _c;
    _c = null;
    await old?.dispose();
    if (_failed || _ended) {
      setState(() {
        _failed = false;
        _ended = false;
      });
    }
    final c =
        widget.controllerFor?.call(widget.film) ??
        VideoPlayerController.networkUrl(widget.film);
    try {
      await c.initialize().timeout(const Duration(seconds: 20));
    } catch (_) {
      await c.dispose();
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) {
      await c.dispose();
      return;
    }
    c.addListener(_tick);
    setState(() {
      _c = c;
      _played = true;
    });
    try {
      await c.play();
    } catch (_) {
      // A browser that lost the tap on the way here only plays muted; the sound button turns it on.
      await c.setVolume(0);
      try {
        await c.play();
      } catch (_) {}
    }
    _scheduleHide();
  }

  void _tick() {
    final c = _c;
    if (c == null || !mounted) return;
    final v = c.value;
    final total = v.duration.inMilliseconds;
    if (total > 0) {
      final pct = (v.position.inMilliseconds * 100 / total).round().clamp(
        0,
        100,
      );
      if (pct > _furthest) _furthest = pct;
    }
    final ended =
        total > 0 && !v.isPlaying && v.position.inMilliseconds >= total - 300;
    if (ended != _ended) {
      setState(() {
        _ended = ended;
        if (ended) _controls = true;
      });
    } else {
      setState(() {});
    }
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && (_c?.value.isPlaying ?? false)) {
        setState(() => _controls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controls = !_controls);
    if (_controls) _scheduleHide();
  }

  Future<void> _playPause() async {
    final c = _c;
    if (c == null) return;
    if (_ended) {
      await c.seekTo(Duration.zero);
      await c.play();
    } else if (c.value.isPlaying) {
      await c.pause();
      _hide?.cancel();
      setState(() => _controls = true);
      return;
    } else {
      await c.play();
    }
    _scheduleHide();
  }

  Future<void> _toggleSound() async {
    final c = _c;
    if (c == null) return;
    await c.setVolume(c.value.volume > 0 ? 0 : 1);
    _scheduleHide();
  }

  void _close() => Navigator.of(context).pop(_played);

  Future<void> _youtube() async {
    Analytics.log('intro_video_youtube', const {});
    await _c?.pause();
    await openWebLink(widget.youtube);
  }

  @override
  void dispose() {
    _hide?.cancel();
    Analytics.log('intro_video_closed', {
      'percent': _furthest,
      'played': _played,
    });
    _c?.removeListener(_tick);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = _c;
    final playing = c?.value.isPlaying ?? false;
    final muted = (c?.value.volume ?? 1) == 0;
    Widget round(
      IconData icon,
      String tip,
      VoidCallback onTap, {
      Key? key,
      double size = 22,
    }) => IconButton(
      key: key,
      tooltip: tip,
      onPressed: onTap,
      icon: Icon(icon, size: size, color: Colors.white),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.45),
      ),
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.space): _playPause,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (c != null) ...[
                Center(
                  child: AspectRatio(
                    aspectRatio: c.value.aspectRatio > 0
                        ? c.value.aspectRatio
                        : 16 / 9,
                    child: VideoPlayer(c),
                  ),
                ),
                // Its own layer over the picture: on the web the video element takes taps given
                // to a parent.
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('introFilmSurface'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleControls,
                  ),
                ),
              ] else if (_failed)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpace.md,
                      children: [
                        const Icon(
                          LucideIcons.wifiOff,
                          size: 36,
                          color: Colors.white70,
                        ),
                        Text(
                          l10n.introVideoFailed,
                          key: const Key('introFilmFailed'),
                          textAlign: TextAlign.center,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Wrap(
                          spacing: AppSpace.sm,
                          runSpacing: AppSpace.sm,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton(
                              key: const Key('introFilmRetry'),
                              onPressed: _load,
                              child: Text(l10n.tryAgain),
                            ),
                            OutlinedButton(
                              key: const Key('introFilmYoutube'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                              onPressed: _youtube,
                              child: Text(l10n.introVideoOnYoutube),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              // The controls: fade out while it plays, back on a tap, a pause or the end.
              if (c != null)
                IgnorePointer(
                  ignoring: !_controls,
                  child: AnimatedOpacity(
                    opacity: _controls ? 1 : 0,
                    duration: AppMotion.duration,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Align(
                          // The end buttons sit low, so the film's last frame (its title) stays clear.
                          alignment: _ended
                              ? const Alignment(0, 0.78)
                              : Alignment.center,
                          child: _ended
                              ? Wrap(
                                  spacing: AppSpace.sm,
                                  runSpacing: AppSpace.sm,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    FilledButton.icon(
                                      key: const Key('introFilmReplay'),
                                      onPressed: _playPause,
                                      icon: const Icon(
                                        LucideIcons.rotateCcw,
                                        size: 18,
                                      ),
                                      label: Text(l10n.introVideoReplay),
                                    ),
                                    OutlinedButton.icon(
                                      key: const Key('introFilmYoutube'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.black
                                            .withValues(alpha: 0.45),
                                        side: const BorderSide(
                                          color: Colors.white54,
                                        ),
                                      ),
                                      onPressed: _youtube,
                                      icon: const Icon(
                                        LucideIcons.externalLink,
                                        size: 16,
                                      ),
                                      label: Text(l10n.introVideoOnYoutube),
                                    ),
                                  ],
                                )
                              : round(
                                  playing
                                      ? LucideIcons.pause
                                      : LucideIcons.play,
                                  playing ? l10n.pause : l10n.playMedia,
                                  _playPause,
                                  key: const Key('introFilmPlayPause'),
                                  size: 32,
                                ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpace.md,
                                0,
                                AppSpace.md,
                                AppSpace.md,
                              ),
                              child: VideoProgressIndicator(
                                c,
                                allowScrubbing: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                colors: VideoProgressColors(
                                  playedColor: Colors.white,
                                  bufferedColor: Colors.white38,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Close and sound stay reachable always (sound only once there's a player).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.sm),
                    child: Row(
                      children: [
                        round(
                          LucideIcons.x,
                          l10n.close,
                          _close,
                          key: const Key('introFilmClose'),
                        ),
                        const Spacer(),
                        if (c != null)
                          round(
                            muted ? LucideIcons.volumeOff : LucideIcons.volume2,
                            muted ? l10n.unmute : l10n.mute,
                            _toggleSound,
                            key: const Key('introFilmSound'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One optional row in a new person's empty chats: "See how Casama works". It goes once the film
/// played, they closed the row, or they've had a few chats with this bot. `intro_video` in remote
/// flags turns it off everywhere.
class IntroVideoTile extends ConsumerStatefulWidget {
  const IntroVideoTile({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<IntroVideoTile> createState() => _IntroVideoTileState();
}

class _IntroVideoTileState extends ConsumerState<IntroVideoTile> {
  static const _prefKey = 'introVideo.done';

  /// Unknown until the saved choice is read, so the row doesn't flash in and out.
  bool? _done;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((p) {
          if (mounted) setState(() => _done = p.getBool(_prefKey) ?? false);
        })
        .catchError((_) {
          if (mounted) setState(() => _done = false);
        });
  }

  Future<void> _finish() async {
    if (mounted) setState(() => _done = true);
    try {
      await (await SharedPreferences.getInstance()).setBool(_prefKey, true);
    } catch (_) {}
  }

  Future<void> _open() async {
    // Only a film that got going takes the row away; a failed start (offline) leaves it.
    if (await showIntroFilm(context, 'empty_chat')) await _finish();
  }

  @override
  Widget build(BuildContext context) {
    if (_done != false || !remoteFlag(ref, 'intro_video', fallback: true)) {
      return const SizedBox.shrink();
    }
    final chats = ref.watch(conversationsProvider(widget.botId)).value?.length;
    if (chats == null || chats >= 3) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        key: const Key('introVideo'),
        onTap: _open,
        radius: AppRadius.tile,
        padding: const EdgeInsets.fromLTRB(AppSpace.md, 10, 4, 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.play, size: 16, color: scheme.onPrimary),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.introVideoTitle,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  Text(
                    l10n.introVideoSubtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('dismissIntroVideo'),
              tooltip: l10n.dismiss,
              icon: Icon(
                LucideIcons.x,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Analytics.log('intro_video_dismissed', const {});
                _finish();
              },
            ),
          ],
        ),
      ),
    );
  }
}
