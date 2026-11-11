import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

import '../theme/app_tokens.dart';

extension AdaptiveSheetRouteX on Widget {
  /// This widget as a full-height modal that opens from the bottom: the iOS 26 glass sheet on iOS,
  /// the package's plain sheet everywhere else. Pulling it down from the top closes it.
  Route<T> asAdaptiveSheetRoute<T>(BuildContext context) {
    final bool isIos = defaultTargetPlatform == TargetPlatform.iOS;
    // Reduced motion: the sheet appears and leaves without sliding.
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (isIos) {
      return StupidSimpleGlassSheetRoute<T>(
        child: this,
        blurBehindBarrier: false,
        backgroundColor: _sheetColor(Theme.of(context)),
        motion: reduceMotion ? const Motion.none() : const CupertinoMotion.smooth(duration: Duration(milliseconds: 350), snapToEnd: true),
      );
    } else {
      return StupidSimpleSheetRoute<T>(
        child: this,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        motion: reduceMotion ? const Motion.none() : const CupertinoMotion.smooth(snapToEnd: true),
      );
    }
  }
}

Color _sheetColor(ThemeData theme) => theme.bottomSheetTheme.modalBackgroundColor ?? theme.bottomSheetTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow;

/// The body of a tall sheet shown with [AdaptiveSheetRouteX.asAdaptiveSheetRoute]: a top bar with
/// a close button and the drag handle, then [builder]'s content, kept clear of the keyboard. On iOS
/// the glass sheet draws the surface and fills the screen. Elsewhere this draws the app's sheet
/// surface (28px top corners) at [heightFactor] of the screen, as the bottom sheet did before.
class TallSheet extends StatelessWidget {
  const TallSheet({super.key, required this.heightFactor, required this.builder, this.contentPadsBottom = false});

  final double heightFactor;
  final WidgetBuilder builder;

  /// The content ends its own scroll view with BottomPadding (see showAdaptiveSheet), so the sheet
  /// adds no bottom SafeArea and the list runs under the home indicator.
  final bool contentPadsBottom;

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.of(context);
    final body = Material(
      type: MaterialType.transparency,
      child: Padding(
        // Rises with the keyboard so the field being typed in stays visible.
        padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TallSheetTopBar(),
            Expanded(
              // The home-indicator inset is under the keyboard while it is open.
              child: SafeArea(
                top: false,
                bottom: !contentPadsBottom && view.viewInsets.bottom == 0,
                child: Builder(builder: builder),
              ),
            ),
          ],
        ),
      ),
    );
    if (defaultTargetPlatform == TargetPlatform.iOS) return body;

    // Never taller than the space under the status bar.
    final sheetHeight = math.min((view.size.height - view.viewInsets.bottom) * heightFactor, view.size.height - view.padding.top - view.viewInsets.bottom);
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: SheetBackground(
        backgroundColor: _sheetColor(Theme.of(context)),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SizedBox(height: sheetHeight + view.viewInsets.bottom, child: body),
      ),
    );
  }
}

/// A 48px strip: the close button at the top left (modals that open from the bottom close with an
/// X, not a back arrow) and the drag handle in the middle.
class _TallSheetTopBar extends StatelessWidget {
  const _TallSheetTopBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handle = theme.bottomSheetTheme.dragHandleColor ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    return SizedBox(
      height: kMinInteractiveDimension,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(color: handle, borderRadius: const BorderRadius.all(Radius.circular(2))),
          ),
          PositionedDirectional(
            start: AppSpace.xxs,
            child: IconButton(
              key: const Key('sheetClose'),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: const Icon(LucideIcons.x, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}
