import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// What a bot's screen is doing, as the floating screen card shows it (SCREEN-CARD-PLAN §5).
enum ScreenTileState {
  /// The bot is driving the screen: the picture and a green dot.
  watching,

  /// The bot asked the person to take over: amber border and "Needs you".
  needsYou,

  /// A person holds the screen: the picture dimmed, "You have the screen".
  held,

  /// The reply finished: the last picture and "Done", briefly.
  done,

  /// No new picture for a while: dimmed, with a small spinner.
  stale,
}

/// A small live picture of a bot's computer screen, for a corner of a chat (SCREEN-CARD-PLAN §3).
/// Nothing is controlled through it: a tap opens the full live view.
class ScreenTile extends StatelessWidget {
  const ScreenTile({
    super.key,
    required this.picture,
    required this.state,
    required this.botName,
    required this.onTap,
    required this.onClose,
    this.heldBy,
    this.onLongPress,
    this.face,
    this.aspectRatio = 16 / 10,
  });

  /// The screen itself (an image of the latest picture), or null before the first one.
  final Widget? picture;
  final ScreenTileState state;

  /// For the screen reader: "Ava's screen, live".
  final String botName;

  /// Who holds the screen in [ScreenTileState.held]; null means the person using the app.
  final String? heldBy;
  final VoidCallback onTap;
  final VoidCallback onClose;

  /// Long press: the card's menu (SCREEN-CARD-PLAN §6).
  final VoidCallback? onLongPress;

  /// Group chats: the working bot's face, in the bottom left (§3).
  final Widget? face;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final amber = context.appColors.waiting;
    final needsYou = state == ScreenTileState.needsYou;
    final dim = state == ScreenTileState.held || state == ScreenTileState.stale;
    final label = switch (state) {
      ScreenTileState.watching || ScreenTileState.stale => null,
      ScreenTileState.needsYou => l10n.callTileNeedsYou,
      ScreenTileState.held => heldBy == null ? l10n.screenCardYouHave : l10n.screenCardHeldBy(heldBy!),
      ScreenTileState.done => l10n.callTileDone,
    };
    final duration = AppMotion.of(context, AppMotion.fast);
    return Semantics(
      button: true,
      label: l10n.screenCardLabel(botName, label ?? l10n.screenCardLive),
      onTapHint: l10n.screenCardOpen,
      onLongPressHint: onLongPress == null ? null : l10n.screenCardMore,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.45 : 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          key: const Key('screenTile'),
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: needsYou ? amber : context.appColors.hairline, width: needsYou ? 2.5 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedOpacity(
                    opacity: dim ? 0.55 : 1,
                    duration: duration,
                    child: picture ?? Center(child: Icon(LucideIcons.monitor, color: scheme.onSurfaceVariant, size: 22)),
                  ),
                  if (state == ScreenTileState.watching) const Positioned(top: 7, left: 7, child: _LiveDot()),
                  if (state == ScreenTileState.stale)
                    const Center(
                      child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    ),
                  if (label != null || face != null)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      right: 6,
                      child: Row(
                        children: [
                          if (face != null) ...[face!, const SizedBox(width: 4)],
                          if (label != null) Flexible(child: _Label(text: label, amber: needsYou)),
                        ],
                      ),
                    ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      key: const Key('screenTileClose'),
                      tooltip: l10n.callTileHide,
                      visualDensity: VisualDensity.compact,
                      iconSize: 12,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.45),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(22, 22),
                        // A bigger target than it looks: the card is small.
                        tapTargetSize: MaterialTapTargetSize.padded,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(LucideIcons.x),
                      onPressed: onClose,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Still, not animated, so the card doesn't redraw between pictures.
class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: context.appColors.positive,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.35), width: 1.5),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.amber});
  final String text;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: amber ? context.appColors.waiting : Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelSmall?.copyWith(
            // Amber is light in dark themes: dark text reads better there.
            color: amber && context.isDark ? const Color(0xFF231400) : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// The corner the screen card was last dragged to, kept on this device (SCREEN-CARD-PLAN §6).
class ScreenCardCorner extends Notifier<Alignment> {
  static const _key = 'screenCard.corner';

  @override
  Alignment build() {
    _load();
    return Alignment.topRight;
  }

  Future<void> _load() async {
    try {
      final v = (await SharedPreferences.getInstance()).getString(_key);
      final a = _decode(v);
      if (a != null && ref.mounted) state = a;
    } catch (_) {
      // No saved corner: top right.
    }
  }

  void set(Alignment corner) {
    state = corner;
    SharedPreferences.getInstance().then((p) => p.setString(_key, '${corner.x.round()},${corner.y.round()}')).ignore();
  }

  static Alignment? _decode(String? v) {
    final parts = v?.split(',');
    if (parts == null || parts.length != 2) return null;
    final x = double.tryParse(parts[0]), y = double.tryParse(parts[1]);
    if (x == null || y == null) return null;
    return Alignment(x < 0 ? -1 : 1, y < 0 ? -1 : 1);
  }
}

final screenCardCornerProvider = NotifierProvider<ScreenCardCorner, Alignment>(ScreenCardCorner.new);

/// Holds [child] in a corner of the space it's given. Drag it; it snaps to the nearest corner,
/// which is remembered. Only the card takes touches: the rest of the space passes them through.
class ScreenTileCorner extends ConsumerStatefulWidget {
  const ScreenTileCorner({
    super.key,
    required this.child,
    required this.width,
    this.aspectRatio = 16 / 10,
    this.insets = const EdgeInsets.all(AppSpace.sm),
    this.caption,
  });
  final Widget child;
  final double width;
  final double aspectRatio;

  /// A line beside the card, under it in a top corner and over it in a bottom one (the first-time
  /// hint, SCREEN-CARD-PLAN §3). It takes no touches.
  final Widget? caption;

  /// Room to keep clear on each side.
  final EdgeInsets insets;

  @override
  ConsumerState<ScreenTileCorner> createState() => _ScreenTileCornerState();
}

class _ScreenTileCornerState extends ConsumerState<ScreenTileCorner> {
  Offset? _drag;

  @override
  Widget build(BuildContext context) {
    final corner = ref.watch(screenCardCornerProvider);
    return LayoutBuilder(
      builder: (context, box) {
        final w = widget.width;
        final h = w / widget.aspectRatio;
        final i = widget.insets;
        final maxX = (box.maxWidth - w - i.right).clamp(i.left, double.infinity);
        final maxY = (box.maxHeight - h - i.bottom).clamp(i.top, double.infinity);
        Offset at(Alignment a) => Offset(a.x < 0 ? i.left : maxX, a.y < 0 ? i.top : maxY);
        final pos = _drag ?? at(corner);
        return Stack(
          children: [
            AnimatedPositioned(
              duration: _drag == null ? AppMotion.of(context, const Duration(milliseconds: 220)) : Duration.zero,
              curve: AppMotion.curve,
              left: pos.dx,
              top: pos.dy,
              width: w,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _drag = pos),
                onPanUpdate: (d) => setState(() {
                  final p = (_drag ?? pos) + d.delta;
                  _drag = Offset(p.dx.clamp(i.left, maxX), p.dy.clamp(i.top, maxY));
                }),
                onPanEnd: (_) {
                  final p = _drag ?? pos;
                  ref
                      .read(screenCardCornerProvider.notifier)
                      .set(Alignment(p.dx + w / 2 < box.maxWidth / 2 ? -1 : 1, p.dy + h / 2 < box.maxHeight / 2 ? -1 : 1));
                  setState(() => _drag = null);
                },
                child: widget.child,
              ),
            ),
            if (widget.caption != null && _drag == null)
              Positioned(
                left: pos.dx,
                width: w,
                top: corner.y < 0 ? pos.dy + h + 6 : null,
                bottom: corner.y < 0 ? null : box.maxHeight - pos.dy + 6,
                child: IgnorePointer(child: widget.caption!),
              ),
          ],
        );
      },
    );
  }
}
