import 'package:flutter/widgets.dart';

/// Whether the app plays its decorative motion: celebration bursts, the tab bar's stretch and
/// wobble, a thinking bot's wiggle, the bots animating on empty screens. Off with Settings →
/// Appearance → Fewer effects (the Plain theme turns it on) and with the system's reduce-motion
/// setting. Motion that tells you something (loading, page changes) isn't decorative and stays.
class Effects extends InheritedWidget {
  const Effects({super.key, required this.fewer, required super.child});

  /// Fewer effects is on.
  final bool fewer;

  /// Whether decorative motion should play here.
  static bool decorative(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context) &&
      !(context.dependOnInheritedWidgetOfExactType<Effects>()?.fewer ?? false);

  @override
  bool updateShouldNotify(Effects old) => old.fewer != fewer;
}
