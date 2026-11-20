import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'motion.dart';
import 'shell_layout.dart';
import 'side_strip.dart';

/// Top bar for main screens: a bold title, an optional muted subtitle, and round icon actions.
///
/// Where the window has a side strip (an iPhone Duo, D-411) the Back button and the icon actions
/// go into the strip and only the title row stays here. Beside its list in a two-pane layout, a
/// page's first screen has no Back: it shows and hides the list instead.
class ShellHeader extends StatelessWidget implements PreferredSizeWidget {
  const ShellHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleShimmer = false,
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

  /// A status that's happening now (a bot working): the subtitle shimmers.
  final bool subtitleShimmer;

  /// Before the title, after the back button (an avatar, for example).
  final Widget? titleLeading;

  /// After the title (a chevron that says the title opens a menu, for example).
  final Widget? titleTrailing;

  /// Replaces the back button. The bare button: the header places it.
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
    final shell = ShellLayout.maybeOf(context);
    // No rail or sidebar to leave by: the page needs its own way back. Inside a pane the width
    // says nothing, so the shell is asked.
    final phone = shell?.navInPage ?? AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;
    final beside = shell != null && (shell.splitDetail || shell.pane == PaneRole.detail) && isDetailRoot(context);
    final canPop = !beside && (showBack ?? (routeCanPop || (phoneFallback != null && phone)));
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
        // Coming and going (a bot starts or stops working) slides the title instead of jumping it.
        ShowHide(
          child: subtitle == null || subtitle!.isEmpty
              ? null
              : AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: _maybeShimmer(
                    subtitleShimmer,
                    scheme.onSurface,
                    Text(
                      subtitle!,
                      key: ValueKey(subtitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500, height: 1.25),
                    ),
                  ),
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
    final Widget? lead = beside
        ? (shell.canToggleList ? const ListPaneToggle() : null)
        : leading ??
              (canPop
                  ? HeaderIconButton(
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
                    )
                  : null);
    final slot = StripSlot.of(context);
    final inRow = slot == null ? actions : [for (final a in actions) if (a is HeaderTextAction) a];
    final bar = AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      leadingWidth: 56,
      leading: slot != null || lead == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(child: lead),
            ),
      titleSpacing: slot == null && lead != null ? 4 : 20,
      title: title0,
      actions: [...inRow, const SizedBox(width: 12)],
      bottom: bottom,
    );
    if (slot == null) return bar;
    return StripButtons(
      rect: slot,
      buttons: [?lead, for (final a in actions) if (a is! HeaderTextAction) a],
      child: bar,
    );
  }
}

/// A header action with words on it ("Save"). It stays in the title row when the icon actions
/// move to the side strip, as text buttons do in Apple's vertical bars.
class HeaderTextAction extends StatelessWidget {
  const HeaderTextAction({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Two panes: hides the list so the open page has the whole window, and brings it back.
class ListPaneToggle extends ConsumerWidget {
  const ListPaneToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(splitExpandedProvider);
    final l10n = AppLocalizations.of(context);
    return HeaderIconButton(
      key: const Key('listPaneToggle'),
      icon: hidden ? LucideIcons.panelLeftOpen : LucideIcons.panelLeftClose,
      tooltip: hidden ? l10n.showList : l10n.hideList,
      onPressed: ref.read(splitExpandedProvider.notifier).toggle,
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

Widget _maybeShimmer(bool on, Color color, Text text) => on ? Shimmer(key: text.key, color: color, band: 0.35, duration: const Duration(milliseconds: 1100), child: text) : text;
