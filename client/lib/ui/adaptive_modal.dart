import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

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
}) async {
  final cancel = cancelLabel ?? MaterialLocalizations.of(context).cancelButtonLabel;
  final scheme = context.colorScheme;
  final confirmStyle = destructive ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError) : null;
  if (!_compact(context)) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(cancel)),
          FilledButton(style: confirmStyle, onPressed: () => Navigator.pop(c, true), child: Text(confirmLabel)),
        ],
      ),
    );
    return ok ?? false;
  }
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (c) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: c.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message, style: c.textTheme.bodyMedium?.copyWith(color: c.colorScheme.onSurfaceVariant, height: 1.4)),
          ],
          const SizedBox(height: AppSpace.xl),
          SizedBox(height: 50, child: FilledButton(style: confirmStyle, onPressed: () => Navigator.pop(c, true), child: Text(confirmLabel))),
          const SizedBox(height: AppSpace.xs),
          SizedBox(height: 50, child: TextButton(onPressed: () => Navigator.pop(c, false), child: Text(cancel))),
        ]),
      ),
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
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle!, style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant)),
              ),
          ]),
        ),
        ?trailing,
      ]),
    );
  }
}
