import 'package:flutter/widgets.dart';

/// The largest text scale the app follows (D-191). The system text size is honoured up to here:
/// Android's largest standard size (1.3x) and iOS Dynamic Type through xxLarge pass through as
/// they are. The bigger accessibility sizes are held at 1.3x so fixed-height rows, chips and the
/// tab bar don't overflow.
const double kMaxTextScale = 1.3;

/// A [MaterialApp.builder]: [child] follows the system text size, but never above
/// [kMaxTextScale]. Smaller sizes are left alone.
Widget limitTextScale(BuildContext context, Widget? child) {
  final MediaQueryData mediaQueryData = MediaQuery.of(context);

  return MediaQuery(
    data: mediaQueryData.copyWith(textScaler: mediaQueryData.textScaler.clamp(maxScaleFactor: kMaxTextScale)),
    child: child ?? const SizedBox.shrink(),
  );
}
