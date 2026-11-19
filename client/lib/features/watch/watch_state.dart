import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';

/// The person's signed-in watches in the selected workspace (Settings → Watch). The bridge
/// refreshes it after signing one in.
final watchKeysProvider = FutureProvider.autoDispose<List<WatchKeyView>>((
  ref,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return const [];
  return ref.watch(backendProvider).listWatchKeys(orgId);
});

/// The person's watch settings; null on a server without watches.
final watchPrefsProvider = FutureProvider.autoDispose<WatchPrefsView?>(
  (ref) => ref.watch(backendProvider).watchPrefs(),
);
