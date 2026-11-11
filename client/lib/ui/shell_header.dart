import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Top bar for main screens: a bold title, an optional muted subtitle, and round icon actions.
class ShellHeader extends StatelessWidget implements PreferredSizeWidget {
  const ShellHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.titleLeading,
    this.titleTrailing,
    this.actions = const [],
    this.bottom,
    this.onTitleTap,
    this.showBack,
    this.phoneFallback,
  });

  final String title;
  final String? subtitle;

  /// Before the title, after the back button (an avatar, for example).
  final Widget? titleLeading;

  /// After the title (a chevron that says the title opens a menu, for example).
  final Widget? titleTrailing;

  /// Replaces the back button.
  final Widget? leading;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onTitleTap;

  /// Defaults to whether the route can pop.
  final bool? showBack;

  /// For screens opened from the chats rather than a tab (settings, the computer, search): on
  /// phones there is no tab bar to leave by, so the back button always shows and goes here when
  /// there is nothing to pop (a deep link).
  final String? phoneFallback;

  static const double toolbarHeight = 64;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final routeCanPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final phone = AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;
    final canPop = showBack ?? (routeCanPop || (phoneFallback != null && phone));
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.4, height: 1.15),
        ),
        if (subtitle != null && subtitle!.isNotEmpty)
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.fast),
            child: Text(
              subtitle!,
              key: ValueKey(subtitle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500, height: 1.25),
            ),
          ),
      ],
    );
    Widget title0 = Row(
      children: [
        if (titleLeading != null) ...[titleLeading!, const SizedBox(width: AppSpace.sm)],
        Flexible(child: titleBlock),
        if (titleTrailing != null) ...[const SizedBox(width: AppSpace.xs), titleTrailing!],
      ],
    );
    if (onTitleTap != null) {
      title0 = InkWell(
        onTap: onTitleTap,
        borderRadius: AppRadius.rowAll,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: title0),
      );
    }
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      leadingWidth: 56,
      leading:
          leading ??
          (canPop
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: HeaderIconButton(
                      icon: LucideIcons.arrowLeft,
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        if (phoneFallback != null && !navigator.canPop()) {
                          GoRouter.of(context).go(phoneFallback!);
                        } else {
                          navigator.maybePop();
                        }
                      },
                    ),
                  ),
                )
              : null),
      titleSpacing: (leading != null || canPop) ? 4 : 20,
      title: title0,
      actions: [...actions, const SizedBox(width: 12)],
      bottom: bottom,
    );
  }
}

/// 36px round icon button used in [ShellHeader].
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.badge = false, this.selected = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Small accent dot (unseen items, active filter).
  final bool badge;

  /// Accent-tinted when its panel is open.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final fill = context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            style: IconButton.styleFrom(
              fixedSize: const Size(36, 36),
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              backgroundColor: selected ? scheme.primary.withValues(alpha: 0.14) : fill,
              foregroundColor: selected ? scheme.primary : scheme.onSurface,
              disabledBackgroundColor: fill.withValues(alpha: 0.5),
              side: BorderSide(color: selected ? scheme.primary.withValues(alpha: 0.4) : context.appColors.hairline),
            ),
          ),
          if (badge)
            Positioned(
              top: 4,
              right: 4,
              child: IgnorePointer(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
