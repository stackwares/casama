import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/tool_words.dart';
import 'active_call.dart';
import 'call_bubble.dart' show callClock;

/// The bot's screen on a call (D-327 §6): the one-a-second screenshots the computer already
/// makes, never video (video starts only in the full live view, after a tap). Amber when a job
/// needs the person on the computer; a short "Done" when the job ends. Nothing is fetched while
/// the app is in the background.
class CallLiveTile extends ConsumerStatefulWidget {
  const CallLiveTile({
    super.key,
    required this.computerId,
    required this.needsYou,
    required this.done,
    required this.onTap,
    required this.onClose,
    this.large = false,
  });

  final String computerId;
  final bool needsYou;
  final bool done;
  final VoidCallback onTap;
  final VoidCallback onClose;

  /// Wide screens: the desktop beside the call, rather than a small tile in a corner.
  final bool large;

  @override
  ConsumerState<CallLiveTile> createState() => _CallLiveTileState();
}

class _CallLiveTileState extends ConsumerState<CallLiveTile>
    with WidgetsBindingObserver {
  Uint8List? _shot;
  String? _etag;
  Timer? _poll;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didUpdateWidget(CallLiveTile old) {
    super.didUpdateWidget(old);
    if (old.computerId != widget.computerId) {
      _shot = null;
      _etag = null;
      _start();
    }
  }

  void _start() {
    _poll?.cancel();
    unawaited(_fetch());
    _poll = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_fetch()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_poll == null) _start();
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> _fetch() async {
    if (_busy) return;
    _busy = true;
    try {
      // The small JPEG the chat's screen card uses (SCREEN-CARD-PLAN), sent only when the screen
      // changed. It may wake the computer: the bot asked to show it.
      final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
      final pic = await ref
          .read(backendProvider)
          .screenPicture(
            widget.computerId,
            width: ((widget.large ? 640 : 140) * dpr).round().clamp(160, 1280),
            etag: _etag,
            wake: true,
          );
      if (mounted && pic.status == ScreenPictureStatus.fresh && pic.bytes != null && pic.bytes!.isNotEmpty) {
        setState(() {
          _shot = pic.bytes;
          _etag = pic.etag;
        });
      }
    } catch (_) {
      // Asleep or unreachable for a moment: keep the last picture.
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final amber = context.appColors.waiting;
    final shot = _shot;
    final label = widget.needsYou
        ? l10n.callTileNeedsYou
        : (widget.done ? l10n.callTileDone : l10n.callTileWatching);
    final radius = BorderRadius.circular(widget.large ? 20 : 14);
    return Semantics(
      button: true,
      label: l10n.callTileLabel(label),
      child: Material(
        key: const Key('callLiveTile'),
        color: scheme.surfaceContainerHighest,
        elevation: widget.large ? 0 : 6,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: widget.needsYou ? amber : scheme.outlineVariant,
            width: widget.needsYou ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (shot != null)
                  Image.memory(shot, fit: BoxFit.cover, gaplessPlayback: true)
                else
                  Center(
                    child: Icon(
                      LucideIcons.monitor,
                      color: scheme.onSurfaceVariant,
                      size: widget.large ? 40 : 22,
                    ),
                  ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  right: 30,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.needsYou
                            ? amber
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall?.copyWith(
                            // Amber is light in dark themes: dark text reads better there.
                            color: widget.needsYou && context.isDark
                                ? const Color(0xFF231400)
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: IconButton(
                    key: const Key('callLiveTileClose'),
                    tooltip: l10n.callTileHide,
                    visualDensity: VisualDensity.compact,
                    iconSize: 14,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(24, 24),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(LucideIcons.x),
                    onPressed: widget.onClose,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phones: the tile in a corner of the call screen. Drag it; it snaps to the nearest corner.
class CallTileCorner extends StatefulWidget {
  const CallTileCorner({
    super.key,
    required this.child,
    this.width = 140,
    this.insets = const EdgeInsets.all(AppSpace.sm),
  });
  final Widget child;
  final double width;

  /// Room to keep clear (the header above, the controls below).
  final EdgeInsets insets;

  @override
  State<CallTileCorner> createState() => _CallTileCornerState();
}

class _CallTileCornerState extends State<CallTileCorner> {
  var _corner = Alignment.topRight;
  Offset? _drag;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = widget.width;
        final h = w * 10 / 16;
        final i = widget.insets;
        final maxX = (box.maxWidth - w - i.right).clamp(
          i.left,
          double.infinity,
        );
        final maxY = (box.maxHeight - h - i.bottom).clamp(
          i.top,
          double.infinity,
        );
        Offset at(Alignment a) =>
            Offset(a.x < 0 ? i.left : maxX, a.y < 0 ? i.top : maxY);
        final pos = _drag ?? at(_corner);
        return Stack(
          children: [
            AnimatedPositioned(
              duration: _drag == null
                  ? const Duration(milliseconds: 220)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              left: pos.dx,
              top: pos.dy,
              width: w,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _drag = pos),
                onPanUpdate: (d) => setState(() {
                  final p = (_drag ?? pos) + d.delta;
                  _drag = Offset(
                    p.dx.clamp(i.left, maxX),
                    p.dy.clamp(i.top, maxY),
                  );
                }),
                onPanEnd: (_) => setState(() {
                  final p = _drag ?? pos;
                  _corner = Alignment(
                    p.dx + w / 2 < box.maxWidth / 2 ? -1 : 1,
                    p.dy + h / 2 < box.maxHeight / 2 ? -1 : 1,
                  );
                  _drag = null;
                }),
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// "Working on: book the flight · 0:42" under the bot's name while a job runs (D-327 §8).
class CallJobStrip extends StatefulWidget {
  const CallJobStrip({super.key, required this.job, required this.onTap});
  final CallJob job;
  final VoidCallback onTap;

  @override
  State<CallJobStrip> createState() => _CallJobStripState();
}

class _CallJobStripState extends State<CallJobStrip> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final job = widget.job;
    final waiting = job.state != CallJobState.running;
    final what = job.title.isNotEmpty
        ? job.title
        : toolWords(l10n, job.card.name, job.card.arguments).doing;
    final tint = waiting ? context.appColors.waiting : scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            key: const Key('callJobStrip'),
            color: Color.alphaBlend(
              tint.withValues(alpha: 0.1),
              scheme.surfaceContainerLow,
            ),
            shape: StadiumBorder(
              side: BorderSide(color: tint.withValues(alpha: 0.3)),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      waiting ? LucideIcons.hand : LucideIcons.loader,
                      size: 14,
                      color: tint,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        waiting
                            ? l10n.callJobNeedsYou(what)
                            : l10n.callJobStrip(what),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelLarge,
                      ),
                    ),
                    Text(
                      ' · ${callClock(DateTime.now().difference(job.started))}',
                      style: context.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
