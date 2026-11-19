import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/motion.dart';

/// Casama's monthly email (D-408): what's new and what's next, once a month at most. Opt-in, off
/// by default, and only on a server that sends it (Casama Cloud). Null otherwise, or when it can't
/// be read, so everything about it stays out of sight.
///
/// A choice made in the sign-up box waits on this device until the account is signed in, then is
/// sent here once.
final newsletterProvider = FutureProvider.autoDispose<NewsletterChoice?>((
  ref,
) async {
  final backend = ref.watch(backendProvider);
  if (!backend.newsletterAvailable) return null;
  try {
    final now = await backend.newsletter();
    if (now == null) return null;
    final pending = await NewsletterSignUpChoice.read();
    if (pending == null) return now;
    final sent = now.asked
        ? now
        : await backend.setNewsletter(subscribed: pending, from: 'signup');
    await NewsletterSignUpChoice.clear();
    return sent;
  } catch (_) {
    return null;
  }
});

/// The sign-up box's answer, kept until the new account signs in (the address may need
/// confirming first, so the account doesn't exist yet when the box is ticked).
abstract final class NewsletterSignUpChoice {
  static const key = 'casama.newsletter.signup';

  static Future<void> save(bool subscribed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, subscribed);
    } catch (_) {}
  }

  static Future<bool?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}

/// Settings → Notifications: "Casama's monthly email", with a switch.
class NewsletterTile extends ConsumerWidget {
  const NewsletterTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(newsletterProvider).value;
    if (choice == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    Future<void> set(bool v) async {
      HapticsHelper.light();
      await runGuarded(
        context,
        () => ref.read(backendProvider).setNewsletter(subscribed: v),
      );
      ref.invalidate(newsletterProvider);
    }

    return GroupedTile(
      key: const Key('settingsNewsletter'),
      icon: LucideIcons.newspaper,
      title: l10n.newsletterTitle,
      subtitle: l10n.newsletterHelp,
      onTap: () => set(!choice.subscribed),
      trailing: Switch(
        key: const Key('newsletterSwitch'),
        value: choice.subscribed,
        onChanged: set,
      ),
    );
  }
}

/// The unticked box under the sign-up form. Shown only where the server sends the email.
class NewsletterSignUpBox extends StatelessWidget {
  const NewsletterSignUpBox({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: const Key('newsletterSignUpBox'),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        context.l10n.newsletterSignUp,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One small card above the chats, once, for people who haven't been asked: "Get Casama's monthly
/// email?" with Yes and No thanks. Any answer, or closing it, counts as asked on every device.
class NewsletterCard extends ConsumerStatefulWidget {
  const NewsletterCard({super.key});

  @override
  ConsumerState<NewsletterCard> createState() => _NewsletterCardState();
}

class _NewsletterCardState extends ConsumerState<NewsletterCard> {
  var _gone = false;

  Future<void> _answer(bool? subscribed) async {
    setState(() => _gone = true);
    final l10n = context.l10n;
    final ok = await runGuarded(context, () async {
      await ref
          .read(backendProvider)
          .setNewsletter(subscribed: subscribed, from: 'card');
      return true;
    });
    if (!mounted) return;
    if (ok == true && subscribed == true) {
      HapticsHelper.success();
      showSuccess(context, l10n.newsletterCardDone);
    }
    ref.invalidate(newsletterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final choice = ref.watch(newsletterProvider).value;
    final show =
        !_gone && choice != null && !choice.asked && !choice.subscribed;
    if (!show) return const ShowHide(child: null);
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return ShowHide(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.sm,
        ),
        child: AppCard(
          key: const Key('newsletterCard'),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.sm,
            AppSpace.xxs,
            AppSpace.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.newspaper,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.newsletterCardTitle,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('newsletterCardClose'),
                    tooltip: l10n.close,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _answer(null),
                    icon: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpace.sm),
                child: Text(
                  l10n.newsletterCardBody,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: AppSpace.xs,
                  top: AppSpace.xs,
                ),
                // Side by side when they fit; stacked (Yes on top) in a narrow card or with
                // large text, instead of running off the edge.
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  overflowDirection: VerticalDirection.up,
                  spacing: AppSpace.xs,
                  overflowSpacing: AppSpace.xs,
                  children: [
                    TextButton(
                      key: const Key('newsletterCardNo'),
                      onPressed: () => _answer(false),
                      child: Text(l10n.newsletterCardNo),
                    ),
                    FilledButton.tonal(
                      key: const Key('newsletterCardYes'),
                      onPressed: () => _answer(true),
                      child: Text(l10n.newsletterCardYes),
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
