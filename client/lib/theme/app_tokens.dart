import 'package:flutter/material.dart';

import '../ui/motion.dart';

/// Spacing scale shared by every screen.
abstract final class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page gutter for cards and lists.
  static const double gutter = 16;
}

/// Corner radii shared by every screen.
abstract final class AppRadius {
  static const double card = 18;
  static const double tile = 14;
  static const double row = 12;
  static const double icon = 10;
  static const double pill = 999;

  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get tileAll => BorderRadius.circular(tile);
  static BorderRadius get rowAll => BorderRadius.circular(row);
}

/// The app's three typefaces (D-084), bundled under assets/fonts.
abstract final class AppFonts {
  /// The default headline and text faces. They are a setting (Appearance.headingFont /
  /// bodyFont, see fonts.dart), so widgets should read them from the text theme instead.
  static const serif = 'Noto Serif';
  static const sans = 'Google Sans';

  /// Code, terminal output and tool arguments.
  static const mono = 'JetBrains Mono';
}

/// Text helpers that the theme can't express.
abstract final class AppText {
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Code, terminal output and tool arguments.
  static const mono = TextStyle(fontFamily: AppFonts.mono, fontFamilyFallback: ['SF Mono', 'Menlo', 'Consolas', 'monospace'], fontSize: 13, height: 1.45);
}

/// Window size classes, after Material 3: phone, tablet, desktop.
enum WindowSize { compact, medium, expanded }

abstract final class AppBreakpoints {
  /// Tablets and narrow desktop windows: navigation rail.
  static const double medium = 700;

  /// Wide windows: sidebar with the bot list, chat, and the computer panel.
  static const double expanded = 1100;

  /// Widest a single column of content grows before it centers.
  static const double readableWidth = 760;

  static WindowSize of(double width) => width >= expanded
      ? WindowSize.expanded
      : width >= medium
      ? WindowSize.medium
      : WindowSize.compact;

  /// Side inset that centers a column of [maxWidth] in [available] width.
  static double centeringInset(double available, {double maxWidth = readableWidth}) => available > maxWidth ? (available - maxWidth) / 2 : 0;
}

/// Shared motion timing.
abstract final class AppMotion {
  static const Duration duration = Duration(milliseconds: 320);
  static const Duration fast = Duration(milliseconds: 180);
  static const Curve curve = Curves.easeOutCubic;
  static const int staggerMs = 18;
  static const int maxStaggerIndex = 8;

  static Duration staggerDelay(int index) => Duration(milliseconds: (index < maxStaggerIndex ? index : maxStaggerIndex) * staggerMs);

  /// [d], or zero when the system asks to reduce motion.
  static Duration of(BuildContext context, Duration d) => MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

extension AppMotionWidget on Widget {
  /// Staggered fade and slight upward slide for list rows.
  Widget appListItemEntrance(int index) => RepaintBoundary(
    child: Entrance(delay: AppMotion.staggerDelay(index), child: this),
  );

  /// Cards and heroes: fade and a subtle scale.
  Widget appCardEntrance({Duration delay = Duration.zero}) => RepaintBoundary(
    child: Entrance(delay: delay, offset: Offset.zero, scale: 0.98, child: this),
  );

  /// A new chat entry: fade and rise from slightly below.
  Widget appMessageEntrance() => Entrance(duration: const Duration(milliseconds: 260), offset: const Offset(0, 0.08), child: this);
}
