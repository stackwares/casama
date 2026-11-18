import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/fold/fold.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import '../../ui/toast.dart';

/// What Casama sees of a folding phone's screens right now (D-411): the pose it worked out, the
/// window, the side strip, the fold and the hinge, and what iOS itself reports. It is here to
/// check a layout on a device (or a simulator) and to send the numbers when something looks off.
/// Settings lists it only on a device that folds.
class FoldScreen extends ConsumerWidget {
  const FoldScreen({super.key});

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  static String _rect(Rect? r) => r == null
      ? '–'
      : '${_n(r.left)}, ${_n(r.top)}  ${_n(r.width)} × ${_n(r.height)}';
  static String _insets(EdgeInsets e) =>
      'left ${_n(e.left)}, top ${_n(e.top)}, right ${_n(e.right)}, bottom ${_n(e.bottom)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // The window's own numbers, not the pane's this page may be shown in.
    final window =
        Navigator.maybeOf(context, rootNavigator: true)?.context ?? context;
    final media = MediaQuery.of(window);
    final fold = FoldInfo.of(window);
    final native = ref.watch(nativeFoldProvider);
    final rows = <(String, String)>[
      (l10n.foldPose, fold.pose.name),
      (l10n.foldWindow, '${_n(media.size.width)} × ${_n(media.size.height)}'),
      (l10n.foldInsets, _insets(media.viewPadding)),
      (
        l10n.foldStrip,
        fold.hasStrip
            ? '${fold.strip.name}, ${_n(fold.stripWidth)} wide, free from ${_n(fold.stripTop)} to ${_n(fold.stripBottom)}'
            : '–',
      ),
      (
        l10n.foldFold,
        fold.fold == null
            ? '–'
            : '${_rect(fold.fold)}${fold.foldActive ? ', dividing' : ''}',
      ),
      (
        l10n.foldHinge,
        native.known
            ? '${native.hinge.name}${native.angle == null ? '' : ', ${_n(native.angle!)}°'}'
            : '–',
      ),
    ];
    final system = <(String, String)>[
      ('fold', '${_rect(native.fold)}${native.foldActive ? ', active' : ''}'),
      ('bar', native.bar.name),
      ('status bar', _rect(native.statusFrame)),
      (
        'covered',
        native.cameras.isEmpty ? '–' : native.cameras.map(_rect).join('; '),
      ),
      ('full screen', '${native.fullScreen}'),
      ('display features', '${media.displayFeatures.length}'),
      ('platform', kIsWeb ? 'web' : defaultTargetPlatform.name),
    ];
    final all = [
      for (final (k, v) in [...rows, ...system]) '$k: $v',
    ].join('\n');
    return SubPage(
      title: l10n.foldScreenTitle,
      actions: [
        HeaderIconButton(
          key: const Key('foldCopy'),
          icon: LucideIcons.copy,
          tooltip: l10n.copy,
          onPressed: () {
            unawaited(Clipboard.setData(ClipboardData(text: all)));
            ScaffoldMessenger.of(context).showSnackBar(
              toastSnackBar(context, l10n.copied, kind: ToastKind.success),
            );
          },
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxs,
            0,
            AppSpace.xxs,
            AppSpace.sm,
          ),
          child: Text(
            l10n.foldScreenHelp,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        GroupedCard(
          dividerIndent: 16,
          children: [for (final (k, v) in rows) _Row(k, v)],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxs,
            AppSpace.lg,
            AppSpace.xxs,
            AppSpace.xs,
          ),
          child: Text(
            l10n.foldSystemSays,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GroupedCard(
          dividerIndent: 16,
          children: [for (final (k, v) in system) _Row(k, v)],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.md,
      vertical: AppSpace.sm,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            key: Key('fold-$label'),
            style: context.textTheme.bodyMedium?.copyWith(
              fontFeatures: AppText.tabular,
            ),
          ),
        ),
      ],
    ),
  );
}
