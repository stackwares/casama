import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/pressable_scale.dart';

/// How a suggestion is put away: for now, or for good (the bot keeps a pinned memory of it).
enum SuggestionDismissal { once, forever }

/// Asks how to put [s] away (D-114). Shows what is being dismissed, then two choices that each say
/// what happens next, so the person never has to guess what "for good" means. Null when cancelled.
Future<SuggestionDismissal?> showDismissSuggestion(
  BuildContext context, {
  required Suggestion s,
  required String botName,
}) => showAdaptiveSheet<SuggestionDismissal>(
  context: context,
  dialogMaxWidth: 460,
  builder: (_) => DismissSuggestionSheet(s: s, botName: botName),
);

class DismissSuggestionSheet extends StatelessWidget {
  const DismissSuggestionSheet({
    super.key,
    required this.s,
    required this.botName,
  });
  final Suggestion s;
  final String botName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final compact =
        AppBreakpoints.of(MediaQuery.sizeOf(context).width) ==
        WindowSize.compact;
    final bot = botName.trim().isEmpty ? l10n.theBot : botName.trim();
    void pick(SuggestionDismissal d) {
      HapticsHelper.light();
      Navigator.of(context).pop(d);
    }

    final cancel = TextButton(
      key: const Key('dismissCancel'),
      onPressed: () => Navigator.of(context).maybePop(),
      child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.xl,
        compact ? 0 : AppSpace.xs,
        AppSpace.xl,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.dismissSuggestion,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dismissSuggestionHelp(bot),
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _Preview(s: s, bot: bot),
          const SizedBox(height: AppSpace.lg),
          _Choice(
            key: const Key('dismissOnce'),
            icon: LucideIcons.clock,
            title: l10n.justThisOnce,
            body: l10n.justThisOnceHelp(bot),
            onTap: () => pick(SuggestionDismissal.once),
          ),
          const SizedBox(height: AppSpace.xs),
          _Choice(
            key: const Key('dismissNever'),
            icon: LucideIcons.bellOff,
            title: l10n.dontSuggestAgain,
            body: l10n.dontSuggestAgainHelp(bot),
            onTap: () => pick(SuggestionDismissal.forever),
          ),
          const SizedBox(height: AppSpace.sm),
          if (compact)
            SizedBox(height: 46, child: cancel)
          else
            Align(alignment: AlignmentDirectional.centerEnd, child: cancel),
        ],
      ),
    );
  }
}

/// The suggestion being dismissed, in a quiet card with an accent rule, so it reads as a quote.
class _Preview extends StatelessWidget {
  const _Preview({required this.s, required this.bot});
  final Suggestion s;
  final String bot;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final urgent = s.urgency == SuggestionUrgencyEnum.urgent;
    final accent = urgent ? colors.warning : scheme.primary;
    return Container(
      key: const Key('dismissPreview'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLow,
        borderRadius: AppRadius.tileAll,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.sm,
                  AppSpace.sm,
                  AppSpace.md,
                  AppSpace.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        urgent ? LucideIcons.zap : LucideIcons.lightbulb,
                        size: 18,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            s.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall?.copyWith(
                              height: 1.3,
                            ),
                          ),
                          Text(
                            context.l10n.suggestedBy(bot),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One way to dismiss: an icon tile, what it's called and what happens next. Tapping it answers.
class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.tileAll,
      side: BorderSide(color: scheme.outlineVariant),
    );
    return PressableScale(
      scale: 0.98,
      child: Semantics(
        button: true,
        child: Material(
          color: context.isDark
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerLowest,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.sm,
                AppSpace.sm,
                AppSpace.sm,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(
                        alpha: context.isDark ? 0.1 : 0.06,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.icon),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 20, color: scheme.onSurface),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          title,
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          body,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: scheme.onSurfaceVariant,
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
