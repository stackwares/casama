import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'form_sheet.dart';

bool _compact(BuildContext context) => AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;

/// Opens [builder] as a bottom sheet on phones and as a centered dialog on larger windows, so
/// pickers and forms sit where each device expects them. [heightFactor] gives list-style content a
/// fixed height; leave it null for content that sizes itself.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double? heightFactor,
  double dialogMaxWidth = 560,
  double dialogMaxHeight = 720,
}) {
  if (_compact(context)) {
    return showModalBottomSheet<T>(
      context: context,
      // Above the shell (the phone's floating tab bar), not inside the tab's navigator.
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final view = MediaQuery.of(context);
        // The home-indicator inset is under the keyboard while it is open.
        final content = SafeArea(top: false, bottom: view.viewInsets.bottom == 0, child: builder(context));
        // Rises with the keyboard so the focused field and the main action stay visible.
        if (heightFactor == null) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
            child: content,
          );
        }
        final sheetHeight = (view.size.height - view.viewInsets.bottom) * heightFactor;
        return Padding(
          padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
          child: SizedBox(height: sheetHeight - kMinInteractiveDimension, child: content),
        );
      },
    );
  }
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      final width = math.min(dialogMaxWidth, size.width - 80);
      final maxHeight = math.min(dialogMaxHeight, size.height * 0.85);
      return Dialog(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: width,
          height: heightFactor == null ? null : maxHeight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(padding: const EdgeInsets.only(top: 20), child: builder(context)),
          ),
        ),
      );
    },
  );
}

/// A short confirmation: an [AlertDialog] on larger windows, and on phones a bottom sheet with
/// full-width pill buttons, the main action first. Returns true when confirmed.
Future<bool> showConfirm({
  required BuildContext context,
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  IconData? icon,
  Key? confirmKey,
}) async {
  final ok = await showAdaptiveSheet<bool>(
    context: context,
    dialogMaxWidth: 460,
    builder: (c) => FormSheet(
      icon: icon ?? (destructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
      title: title,
      subtitle: message,
      submitLabel: confirmLabel,
      submitKey: confirmKey,
      cancelLabel: cancelLabel,
      destructive: destructive,
      onSubmit: () => Navigator.pop(c, true),
      children: const [],
    ),
  );
  return ok ?? false;
}

/// Title row for content inside [showAdaptiveSheet].
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.title, {super.key, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.md, AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
