import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../theme/app_colors.dart';

/// A group chat before anyone has written (D-118): who is in it, how a message finds its bot, and
/// one tap per member (or everyone) to start a message to them.
class EmptyGroupThread extends StatelessWidget {
  const EmptyGroupThread({
    super.key,
    required this.title,
    required this.members,
    required this.side,
    required this.onMention,
  });

  final String title;

  /// The group's bots, the lead first.
  final List<Bot> members;
  final double side;

  /// Starts the message with `@name ` in the composer.
  final ValueChanged<String> onMention;

  static const _shown = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final lead = members.firstOrNull;
    final extra = members.length - _shown;
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(side, AppSpace.lg, side, AppSpace.md),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // The members' avatars, overlapping.
                Center(
                  child: SizedBox(
                    height: 56,
                    width:
                        56 +
                        38.0 *
                            ((members.length.clamp(1, _shown)) -
                                1 +
                                (extra > 0 ? 1 : 0)),
                    child: Stack(
                      children: [
                        for (var i = 0; i < members.length && i < _shown; i++)
                          Positioned(
                            left: 38.0 * i,
                            child: _Ring(
                              child: BotAvatar(
                                name: members[i].name,
                                avatar: members[i].avatarUrl,
                                size: 52,
                              ),
                            ),
                          ),
                        if (extra > 0)
                          Positioned(
                            left: 38.0 * _shown,
                            child: _Ring(
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: scheme.surfaceContainerHigh,
                                child: Text(
                                  '+$extra',
                                  style: context.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ).appCardEntrance(),
                const SizedBox(height: AppSpace.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ).appCardEntrance(delay: const Duration(milliseconds: 60)),
                const SizedBox(height: AppSpace.xs),
                Text(
                  l10n.groupEmptySubtitle(members.length),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ).appCardEntrance(delay: const Duration(milliseconds: 100)),
                const Spacer(),
                AppCard(
                  key: const Key('groupHowItWorks'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Tip(
                        icon: LucideIcons.atSign,
                        text: l10n.groupTipMention,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      _Tip(
                        icon: LucideIcons.usersRound,
                        text: l10n.groupTipEveryone(lead?.name ?? ''),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      _Tip(
                        icon: LucideIcons.messageCircle,
                        text: l10n.groupTipNoMention(lead?.name ?? ''),
                      ),
                    ],
                  ),
                ).appListItemEntrance(2),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    for (final b in members)
                      ActionChip(
                        key: Key('groupMention-${b.id}'),
                        avatar: BotAvatar(
                          name: b.name,
                          avatar: b.avatarUrl,
                          size: 20,
                        ),
                        label: Text('@${b.name}'),
                        onPressed: () => onMention(b.name),
                      ),
                    ActionChip(
                      key: const Key('groupMention-everyone'),
                      avatar: const Icon(LucideIcons.usersRound, size: 16),
                      label: Text('@${l10n.mentionEveryone}'),
                      onPressed: () => onMention(l10n.mentionEveryone),
                    ),
                  ],
                ).appListItemEntrance(3),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A gap in the page colour around each avatar, so the overlapping ones stay apart.
class _Ring extends StatelessWidget {
  const _Ring({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      shape: BoxShape.circle,
    ),
    child: child,
  );
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(icon, size: 18, color: context.colorScheme.primary),
      ),
      const SizedBox(width: AppSpace.sm),
      Expanded(
        child: Text(
          text,
          style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ),
    ],
  );
}
