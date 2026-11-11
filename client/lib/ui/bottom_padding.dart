import 'package:flutter/widgets.dart';

/// Room at the end of a scrolling list or page so its last item clears the system navigation bar
/// (the home indicator on iPhone, the gesture bar or buttons on Android) instead of sitting under it.
/// Use it instead of a SafeArea around a scrollable: a SafeArea shrinks the scrolling area, so items
/// get cut off at its edge instead of sliding under the bar.
///
/// It reads MediaQuery padding: the bar's height, 0 while the keyboard is open, and on the phone's tab
/// screens the floating tab bar too (HomeShell sets it). Without a bar it is the minimum (16 unless
/// given), so content never touches the bottom edge.
class BottomPadding extends StatelessWidget {
  const BottomPadding({super.key});

  static double of(BuildContext context, {double minimum = 16}) {
    final double padding = MediaQuery.paddingOf(context).bottom;
    return padding > minimum ? padding : minimum;
  }

  @override
  Widget build(BuildContext context) => SizedBox(height: of(context));
}
