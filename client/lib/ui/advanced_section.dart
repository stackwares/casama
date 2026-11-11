import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Which [AdvancedSection]s are open on this device (D-182). Opening one keeps it open next time,
/// so people who use the expert options open each section once instead of flipping a mode.
class AdvancedOpen extends Notifier<Set<String>> {
  static const _key = 'advanced.open';

  @override
  Set<String> build() {
    SharedPreferences.getInstance()
        .then((p) {
          final saved = p.getStringList(_key);
          if (saved != null && saved.isNotEmpty) state = {...state, ...saved};
        })
        .catchError((_) {});
    return const {};
  }

  bool isOpen(String id) => state.contains(id);

  Future<void> set(String id, bool open) async {
    state = open ? {...state, id} : ({...state}..remove(id));
    try {
      await (await SharedPreferences.getInstance()).setStringList(_key, state.toList()..sort());
    } catch (_) {}
  }
}

final advancedOpenProvider = NotifierProvider<AdvancedOpen, Set<String>>(AdvancedOpen.new);

/// A screen's expert options, folded under one "Advanced" row at its end (D-182). Nothing is
/// hidden for good: tap to open it, and it stays open on this device.
///
/// [id] names the section for remembering (`settings.connections`, `bot.advanced`); the row's key
/// is `advanced-<id>`. [summary] says what's inside while it's folded ("Secrets, computers").
class AdvancedSection extends ConsumerWidget {
  const AdvancedSection({
    super.key,
    required this.id,
    required this.children,
    this.title,
    this.summary,
    this.padding,
    this.forceOpen = false,
    this.compact = false,
  });

  final String id;
  final List<Widget> children;

  /// Defaults to "Advanced".
  final String? title;
  final String? summary;

  /// Around the toggle row; defaults to a section header's spacing.
  final EdgeInsetsGeometry? padding;

  /// Shown open whatever was remembered, e.g. while one of its pages is open beside it.
  final bool forceOpen;

  /// Renders the toggle as a compact underlined text link instead of a full-width list tile row.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final open = forceOpen || ref.watch(advancedOpenProvider).contains(id);
    final label = title ?? AppLocalizations.of(context).advanced;
    final duration = AppMotion.of(context, AppMotion.fast);
    final toggle = Semantics(
      button: true,
      expanded: open,
      child: compact
          ? Center(
              child: InkWell(
                key: Key('advanced-$id'),
                borderRadius: AppRadius.rowAll,
                onTap: () => ref.read(advancedOpenProvider.notifier).set(id, !open),
                child: Padding(
                  padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                  child: Text(
                    label,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                      decorationColor: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            )
          : InkWell(
              key: Key('advanced-$id'),
              borderRadius: AppRadius.rowAll,
              onTap: () => ref.read(advancedOpenProvider.notifier).set(id, !open),
              child: Padding(
                padding: padding ?? const EdgeInsets.fromLTRB(AppSpace.xxs, AppSpace.lg, AppSpace.xxs, AppSpace.xs),
                child: Row(
                  children: [
                    Icon(LucideIcons.slidersHorizontal, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.1, color: scheme.onSurfaceVariant),
                          ),
                          if (!open && summary != null && summary!.isNotEmpty)
                            Text(
                              summary!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: duration,
                      child: Icon(LucideIcons.chevronDown, size: 18, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        toggle,
        AnimatedSize(
          duration: duration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children) : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
