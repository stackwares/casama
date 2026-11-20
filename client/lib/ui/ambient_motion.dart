import 'package:material_ui/material_ui.dart';

/// Looping, decorative motion (the splash scene's slow zoom, a sheet hero's float). Tests turn it
/// off in flutter_test_config.dart so `pumpAndSettle` can settle; a test that checks the motion
/// turns it back on.
bool ambientMotionEnabled = true;

/// Whether looping motion should run here: allowed, and the system isn't asking to reduce motion.
/// Paused tickers (a screen off view, TickerMode off) stop it on their own.
bool ambientMotionOn(BuildContext context) =>
    ambientMotionEnabled && !MediaQuery.disableAnimationsOf(context);
