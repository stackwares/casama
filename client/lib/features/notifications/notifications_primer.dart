import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/web_notification_prompt_web.dart' if (dart.library.io) '../../core/web_notification_prompt_stub.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/mascot.dart';

/// "Turn on notifications", shown once after sign-in before the system prompt: a bot, the reason
/// in one line, and the system prompt behind "Turn on". "Not now" asks again in a week.
class NotificationsPrimer extends StatelessWidget {
  const NotificationsPrimer({super.key, required this.onEnable, required this.onLater, this.blocked = false});
  final VoidCallback onEnable;
  final VoidCallback onLater;

  /// Chrome already refused, so Turn on cannot show the prompt until the site setting changes.
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Material(
      key: const Key('notificationsPrimer'),
      color: scheme.surface,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.md),
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  // The bot, with what it's saying above it.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6))],
                    ),
                    child: Text(l10n.notificationsPrimerBubble, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const MascotImage(Mascot.wow, size: 104),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Text(
                    l10n.notificationsPrimerTitle,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    blocked ? l10n.notificationsPrimerBlockedBody : l10n.notificationsPrimerBody,
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4, fontWeight: FontWeight.w400),
                  ),
                  const Spacer(flex: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: kIsWeb ? ExcludeSemantics(child: IgnorePointer(child: _turnOnButton(context, scheme))) : _turnOnButton(context, scheme),
                        ),
                        // A real browser button, so Chrome's prompt opens on this click.
                        if (kIsWeb)
                          Positioned.fill(
                            child: HtmlElementView.fromTagName(
                              tagName: 'button',
                              onElementCreated: (element) => bindNotificationButton(
                                element,
                                label: l10n.notificationsTurnOn,
                                background: _css(scheme.onSurface),
                                foreground: _css(scheme.surface),
                                onPressed: onEnable,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  TextButton(
                    key: const Key('notificationsNotNow'),
                    onPressed: onLater,
                    child: Text(l10n.notNow, style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _turnOnButton(BuildContext context, ColorScheme scheme) => FilledButton(
    key: const Key('notificationsTurnOn'),
    style: FilledButton.styleFrom(
      backgroundColor: scheme.onSurface,
      foregroundColor: scheme.surface,
      shape: const StadiumBorder(),
      textStyle: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    onPressed: onEnable,
    child: Text(context.l10n.notificationsTurnOn),
  );
}

String _css(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}
