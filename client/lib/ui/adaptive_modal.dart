import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'adaptive_sheet_route.dart';
import 'form_sheet.dart';
import 'spring_sheet.dart';

bool _compact(BuildContext context) => AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;

/// Puts the keyboard away before a sheet, dialog, picker or menu opens, so closing it doesn't bring
/// the keyboard back: the person was done typing. Phones and tablets only. With a hardware keyboard
/// (desktop), focus going back to the field afterwards is what people expect.
void unfocusBeforeModal() {
  if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

/// Opens [builder] as a bottom sheet on phones and as a centered dialog on larger windows, so
/// pickers and forms sit where each device expects them. [heightFactor] gives list-style content a
/// fixed height; leave it null for content that sizes itself.
///
/// Set [contentPadsBottom] when the content ends in a list or scroll view that runs to the bottom
/// edge and adds BottomPadding to its own end: the phone sheet then leaves out its bottom SafeArea,
/// so the list scrolls under the home indicator instead of being cut off above it.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double? heightFactor,
  double dialogMaxWidth = 560,
  double dialogMaxHeight = 720,
  bool contentPadsBottom = false,
}) {
  unfocusBeforeModal();
  // Phones, content-sized sheets (forms, pickers, confirmations): a spring-driven sheet that
  // follows the finger and closes with a flick down.
  if (_compact(context) && heightFactor == null) {
    return showSpringBottomSheet<T>(
      context: context,
      // Above the shell (the phone's floating tab bar), not inside the tab's navigator.
      useRootNavigator: true,
      builder: (context) {
        final view = MediaQuery.of(context);
        // Rises with the keyboard so the focused field and the main action stay visible. The
        // home-indicator inset is under the keyboard while it is open. Content that pads its own
        // bottom (contentPadsBottom) gets no bottom SafeArea, so its list runs to the edge.
        return AnimatedPadding(
          duration: AppMotion.of(context, const Duration(milliseconds: 120)),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
          child: SafeArea(top: false, bottom: !contentPadsBottom && view.viewInsets.bottom == 0, child: builder(context)),
        );
      },
    );
  }
  // Phones, tall sheets with a fixed height (lists, search, previews): the modern full-height
  // sheet, closed with its X or by pulling it down from the top.
  if (_compact(context) && heightFactor != null) {
    // Above the shell (the phone's floating tab bar), with the themes of the screen that opened it.
    final navigator = Navigator.of(context, rootNavigator: true);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return navigator.push<T>(themes.wrap(TallSheet(heightFactor: heightFactor, contentPadsBottom: contentPadsBottom, builder: builder)).asAdaptiveSheetRoute<T>(context));
  }
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      final width = math.min(dialogMaxWidth, size.width - 80);
      // Tall windows get taller dialogs (up to 90% of the window), so long forms rarely scroll.
      final maxHeight = math.min(math.max(dialogMaxHeight, size.height * 0.9 - 40), size.height * 0.9);
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
      icon: icon ?? (destructive ? LucideIcons.triangleAlert : LucideIcons.circleQuestionMark),
      title: title,
      subtitle: message,
      submitLabel: confirmLabel,
      submitKey: confirmKey,
      cancelLabel: cancelLabel,
      destructive: destructive,
      onSubmit: () {
        // Confirming something destructive (delete, archive, remove) gets a firm haptic.
        if (destructive) HapticsHelper.heavy();
        Navigator.pop(c, true);
      },
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
