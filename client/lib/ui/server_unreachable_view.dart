import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/generated/app_localizations.dart';
import 'bot_loader.dart';
import 'glow_button.dart';
import 'mascot.dart';

/// What the app shows when it can't reach its server at launch: Sleepy dozing over its shadow while
/// it waits, Focused while it tries again, the server's address in a chip that opens the server
/// switcher, and a countdown to the next automatic try. Takes the colours of the splash it replaces.
class ServerUnreachableView extends StatefulWidget {
  const ServerUnreachableView({
    super.key,
    required this.apiUrl,
    required this.retrying,
    required this.nextRetryAt,
    required this.onRetry,
    required this.onChangeServer,
  });

  final String apiUrl;

  /// A try is under way: the button waits and Focused stands in for Sleepy.
  final bool retrying;

  /// When the next automatic try starts; null when none is planned.
  final DateTime? nextRetryAt;

  final VoidCallback onRetry;
  final VoidCallback onChangeServer;

  @override
  State<ServerUnreachableView> createState() => _ServerUnreachableViewState();
}

class _ServerUnreachableViewState extends State<ServerUnreachableView> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(ServerUnreachableView old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  /// Redraws once a second while a countdown is showing.
  void _syncTicker() {
    final counting = widget.nextRetryAt != null && !widget.retrying;
    if (counting && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!counting) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String get _host {
    final uri = Uri.tryParse(widget.apiUrl);
    return (uri != null && uri.host.isNotEmpty) ? uri.host : widget.apiUrl;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final next = widget.nextRetryAt;
    final seconds = next == null
        ? null
        : (next.difference(DateTime.now()).inMilliseconds / 1000).ceil().clamp(
            1,
            999,
          );
    final status = widget.retrying
        ? l10n.retryingNow
        : seconds != null
        ? l10n.retryingIn(seconds)
        : null;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(anim),
              child: child,
            ),
          ),
          child: BotLoader(
            key: ValueKey(widget.retrying),
            mascot: widget.retrying ? Mascot.focused : Mascot.sleepy,
            size: 132,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.cannotReachServer,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.serverUnreachableBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        _ServerChip(
          host: _host,
          tooltip: l10n.changeServer,
          onTap: widget.onChangeServer,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: GlowButton.icon(
            key: const Key('startupRetry'),
            onPressed: widget.retrying ? null : widget.onRetry,
            icon: widget.retrying
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : const Icon(LucideIcons.refreshCw, size: 18),
            label: Text(l10n.retry),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 20,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: status == null
                ? const SizedBox.shrink()
                : Text(
                    status,
                    key: ValueKey(status),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('startupChangeServer'),
          onPressed: widget.onChangeServer,
          child: Text(l10n.changeServer),
        ),
      ],
    );

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Semantics(
              liveRegion: true,
              child: _Entrance(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// The server's host with a little "offline" dot; tapping it opens the server switcher.
class _ServerChip extends StatelessWidget {
  const _ServerChip({
    required this.host,
    required this.tooltip,
    required this.onTap,
  });

  final String host;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
        shape: StadiumBorder(
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: scheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    host,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
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

/// Fades and lifts the view in once, so it doesn't snap in over the splash.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
