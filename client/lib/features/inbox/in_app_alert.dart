import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/chat_focus.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';

/// The banner over the app when something that needs the person (an approval, a takeover, a
/// secret) or a reply in another chat (D-325) arrives while the app is open (Fix 16). It works on every platform, with or without
/// push: it comes from the live inbox. It hides itself after [showFor], and never shows for the
/// screen the person is already on.
class InAppAlertBanner extends ConsumerStatefulWidget {
  const InAppAlertBanner({
    super.key,
    required this.location,
    required this.child,
  });

  /// Where the app is now; an alert that links here is not shown.
  final String location;
  final Widget child;

  static const showFor = Duration(seconds: 10);
  static const replyShowFor = Duration(seconds: 5);

  @override
  ConsumerState<InAppAlertBanner> createState() => _InAppAlertBannerState();
}

class _InAppAlertBannerState extends ConsumerState<InAppAlertBanner> {
  Timer? _hide;
  String? _timedId;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  bool _isHere(NotificationView n) {
    final link = n.openLink;
    if (link == null) return false;
    final uri = Uri.tryParse(link);
    final path = uri?.path;
    if (uri == null || path == null || path.isEmpty || path == '/' || widget.location != path) return false;
    // A bot's chats share one path (D-253): a reply in another topic of the bot on screen is
    // somewhere else, and gets its banner (D-413). Before, it was never shown at all.
    final conversation = uri.queryParameters['c'];
    final open = ref.read(chatFocusProvider).conversation;
    return conversation == null || open == null || conversation == open;
  }

  void _open(NotificationView n) {
    ref.read(inAppAlertProvider.notifier).dismiss(n.id);
    unawaited(
      ref
          .read(notificationsProvider.notifier)
          .markRead(n.id)
          .catchError((_) {}),
    );
    final link = n.openLink;
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (link != null && link.startsWith('/')) {
      router.pushOnce(link);
    } else {
      router.go('/inbox');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the live inbox open, which is what feeds the banner.
    ref.listen(notificationsProvider, (_, _) {});
    final alert = ref.watch(inAppAlertProvider);
    final n = alert == null || _isHere(alert) ? null : alert;
    if (n?.id != _timedId) {
      _hide?.cancel();
      _timedId = n?.id;
      if (n != null) {
        // A reply (D-325) is a glance, not a request: it goes sooner.
        _hide = Timer(n.isReply ? InAppAlertBanner.replyShowFor : InAppAlertBanner.showFor, () {
          if (mounted) ref.read(inAppAlertProvider.notifier).dismiss(n.id);
        });
      }
    }
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.paddingOf(context).top + AppSpace.md,
          left: AppSpace.md,
          right: AppSpace.md,
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: n == null
                ? const SizedBox.shrink()
                : Center(
                    key: ValueKey(n.id),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Semantics(
                        liveRegion: true,
                        child: Material(
                          key: const Key('inAppAlert'),
                          elevation: 8,
                          borderRadius: BorderRadius.circular(20),
                          color: scheme.surfaceContainerHigh,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _open(n),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpace.md,
                                AppSpace.sm,
                                AppSpace.xs,
                                AppSpace.sm,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: scheme.primaryContainer,
                                    child: Icon(switch (n.kind) {
                                      'takeover' => LucideIcons.hand,
                                      'secret' => LucideIcons.keyRound,
                                      'link_exchange' => LucideIcons.link,
                                      'reply' => LucideIcons.messageCircle,
                                      _ =>
                                        n.isRequest
                                            ? LucideIcons.shieldCheck
                                            : LucideIcons.bell,
                                    }, color: scheme.onPrimaryContainer),
                                  ),
                                  const SizedBox(width: AppSpace.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          n.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: text.titleSmall,
                                        ),
                                        if (n.body.isNotEmpty)
                                          Text(
                                            n.body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: text.bodySmall?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.xs),
                                  TextButton(
                                    key: const Key('inAppAlertOpen'),
                                    onPressed: () => _open(n),
                                    child: Text(n.isReply ? l10n.inAppAlertOpen : l10n.inAppAlertReview),
                                  ),
                                  IconButton(
                                    key: const Key('inAppAlertDismiss'),
                                    tooltip: l10n.dismiss,
                                    icon: const Icon(LucideIcons.x, size: 18),
                                    onPressed: () => ref
                                        .read(inAppAlertProvider.notifier)
                                        .dismiss(n.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
