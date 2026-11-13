import 'package:material_ui/material_ui.dart';

import '../../../theme/app_colors.dart';

/// One look for everything in a chat (D-256): filled bubbles with soft, even corners, and cards
/// (forms, requests, suggestions) in the same fill with a hairline edge. Opaque, so they read on any
/// wallpaper.
abstract final class ChatLook {
  /// Bubbles: the same radius on every corner, no tail.
  static const double bubbleRadius = 22;

  /// Cards and forms: a little rounder than a bubble.
  static const double cardRadius = 24;

  static const EdgeInsets bubblePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 11,
  );
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(18, 16, 18, 16);

  /// The bot's bubble and every card.
  static Color botFill(BuildContext context) =>
      context.colorScheme.surfaceContainerHigh;

  /// Your bubble: the accent, with its own text color.
  static Color userFill(BuildContext context) => context.colorScheme.primary;
  static Color userText(BuildContext context) => context.colorScheme.onPrimary;

  /// Fields and option rows inside a card: one step lighter than the card.
  static Color fieldFill(BuildContext context) =>
      context.colorScheme.surfaceContainerHighest;

  static BoxDecoration card(BuildContext context, {bool quiet = false}) =>
      BoxDecoration(
        color: botFill(context),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: quiet ? Colors.transparent : context.appColors.hairline,
        ),
      );
}
