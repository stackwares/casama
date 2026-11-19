import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
import '../../ui/app_card.dart';

/// The phone's switch for a ring filling the screen (D-424): Android 14+ can deny
/// USE_FULL_SCREEN_INTENT (Play may not pre-grant it), and then a bot's call is only a heads-up
/// notification. Answer on it still opens the call screen; this lets the person turn the full-screen
/// ring back on. Abstract so tests can say what the phone says.
abstract class FullScreenCalls {
  /// null where the phone has no such switch (not Android).
  Future<bool?> allowed();

  /// Opens the phone's page for the switch.
  Future<void> ask();
}

class DeviceFullScreenCalls implements FullScreenCalls {
  @override
  Future<bool?> allowed() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await FlutterCallkitIncoming.canUseFullScreenIntent();
    } catch (e) {
      debugPrint('full-screen check failed: $e');
      return null;
    }
  }

  @override
  Future<void> ask() async {
    try {
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (e) {
      debugPrint('full-screen ask failed: $e');
    }
  }
}

final fullScreenCallsProvider = Provider<FullScreenCalls>(
  (ref) => DeviceFullScreenCalls(),
);

final fullScreenCallsAllowedProvider = FutureProvider.autoDispose<bool?>(
  (ref) => ref.watch(fullScreenCallsProvider).allowed(),
);

/// Settings → App: shown only while the switch is off. Checks again when the person comes back
/// from the phone's settings.
class FullScreenCallsTile extends ConsumerStatefulWidget {
  const FullScreenCallsTile({super.key});

  @override
  ConsumerState<FullScreenCallsTile> createState() =>
      _FullScreenCallsTileState();
}

class _FullScreenCallsTileState extends ConsumerState<FullScreenCallsTile> {
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(
      onResume: () => ref.invalidate(fullScreenCallsAllowedProvider),
    );
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(fullScreenCallsAllowedProvider).value != false) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    return GroupedTile(
      key: const Key('settingsFullScreenCalls'),
      icon: LucideIcons.phoneIncoming,
      title: l10n.callFullScreenTitle,
      subtitle: l10n.callFullScreenOff,
      onTap: () => unawaited(ref.read(fullScreenCallsProvider).ask()),
    );
  }
}
