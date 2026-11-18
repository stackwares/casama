import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:window_manager/window_manager.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bot_avatar.dart';
import '../island/island_bridge.dart' show islandOnScreenProvider;
import 'companion.dart';

/// Shows which bot is acting on this computer, with Stop, as a small card floating below the
/// screen's header, so the app under it never moves (D-394). While a bot acts, the window stays on
/// top so the user can always see and stop it (D-066). When the Mac's notch is on screen it shows
/// the bot and Stop there instead (D-324, decision 10), so the card stays hidden.
class CompanionOverlay extends ConsumerStatefulWidget {
  const CompanionOverlay({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<CompanionOverlay> createState() => _CompanionOverlayState();
}

class _CompanionOverlayState extends ConsumerState<CompanionOverlay> {
  bool? _onTop;

  /// Debug builds only: `?previewActing=1` in the address shows the card with a made-up step, so
  /// it can be seen on the web, where there's no companion. Stop hides it.
  final _preview = ValueNotifier<CompanionActivity?>(
    kDebugMode && Uri.base.queryParameters.containsKey('previewActing')
        ? const CompanionActivity(runId: 'preview', bot: 'Casama', tool: 'shell.exec', summary: 'cd "/Users/you/Downloads/drive-download-20261118T082042Z-1-001" && rm -f "Filing Dates (old).docx" "Itinerary draft.docx" && python3 fix_dates.py --filing 2027-01-01 --itinerary-start 2027-02-02')
        : null,
  );

  bool get _desktop => !kIsWeb && const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}.contains(defaultTargetPlatform);

  void _keepOnTop(bool on) {
    if (!_desktop || _onTop == on) return;
    _onTop = on;
    try {
      WindowManager.instance.getCurrent()?.isAlwaysOnTop = on;
    } catch (_) {
      // Window control is best effort (some Linux window managers refuse it).
    }
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companion = ref.watch(companionProvider);
    final notch = ref.watch(islandOnScreenProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([companion.activity, _preview]),
      builder: (context, child) {
        final a = companion.activity.value ?? _preview.value;
        _keepOnTop(a != null && !notch);
        final shown = a != null && !notch;
        final preview = a != null && companion.activity.value == null;
        // The same two children always, so the app below is never rebuilt from scratch.
        return Stack(
          children: [
            Positioned.fill(child: child!),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  // Below the screen's header and the chat's topic chips, so it never covers buttons.
                  padding: const EdgeInsets.fromLTRB(AppSpace.lg, kToolbarHeight * 2 + AppSpace.md, AppSpace.lg, 0),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (w, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(position: Tween(begin: const Offset(0, -0.4), end: Offset.zero).animate(anim), child: w),
                      ),
                      child: shown
                          ? _ActingCard(key: const Key('companionOverlay'), activity: a, onStop: preview ? () => _preview.value = null : null)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// The floating card: the acting bot (its own mascot, animated), what it's doing, and Stop. In the
/// theme's tertiary colors, so it reads as something apart from the chat's bubbles in light and
/// dark. A long step shows one line; tapping the card shows up to six.
class _ActingCard extends ConsumerStatefulWidget {
  const _ActingCard({super.key, required this.activity, this.onStop});
  final CompanionActivity activity;

  /// In place of stopping the run (the debug preview).
  final VoidCallback? onStop;

  @override
  ConsumerState<_ActingCard> createState() => _ActingCardState();
}

class _ActingCardState extends ConsumerState<_ActingCard> {
  bool _expanded = false;

  /// The acting bot: by id, else by name (older servers send no id), else, for the debug preview,
  /// the first bot, so a real mascot shows.
  Bot? _bot() {
    final a = widget.activity;
    if (a.botId != null) return ref.watch(botProvider(a.botId!));
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    for (final b in bots) {
      if (b.name == a.bot) return b;
    }
    return a.runId == 'preview' && bots.isNotEmpty ? bots.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.tertiaryContainer;
    final fg = scheme.onTertiaryContainer;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg);
    final text = context.l10n.botActingHere(a.bot, a.summary.isEmpty ? a.tool : a.summary);
    final bot = _bot();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Material(
        color: bg,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: scheme.tertiary.withValues(alpha: 0.45))),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, box) {
            // Whether the step fits on one line: the card's width less the avatar, chevron and Stop.
            final room = box.maxWidth - 6 - 30 - 10 - 28 - 96;
            final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              maxLines: 1,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: room > 0 ? room : 0);
            final long = painter.didExceedMaxLines;
            painter.dispose();
            final top = EdgeInsets.only(top: _expanded ? 6 : 0);
            return InkWell(
              key: const Key('companionExpand'),
              onTap: long ? () => setState(() => _expanded = !_expanded) : null,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 4, 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: _expanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      BotAvatar(name: bot?.name ?? a.bot, avatar: bot?.avatarUrl, size: 30, status: BotStatusEnum.working, ringColor: bg, animate: true),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Padding(
                          padding: top,
                          child: Text(text, key: const Key('companionText'), maxLines: _expanded ? 6 : 1, overflow: TextOverflow.ellipsis, style: style),
                        ),
                      ),
                      if (long)
                        Padding(
                          padding: top.copyWith(left: 4),
                          child: Icon(_expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18, color: fg),
                        ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        key: const Key('companionStop'),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.error,
                          backgroundColor: scheme.surface.withValues(alpha: 0.6),
                          visualDensity: VisualDensity.compact,
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(LucideIcons.circleStop, size: 18),
                        label: Text(context.l10n.stop),
                        onPressed: widget.onStop ?? () => runGuarded(context, () => ref.read(backendProvider).cancelRun(a.runId)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
