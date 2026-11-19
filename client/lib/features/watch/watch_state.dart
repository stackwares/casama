import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import 'watch_key_store.dart';

/// The person's signed-in watches in the selected workspace (Settings → Watch). The bridge
/// refreshes it after signing one in.
final watchKeysProvider = FutureProvider.autoDispose<List<WatchKeyView>>((
  ref,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return const [];
  return ref.watch(backendProvider).listWatchKeys(orgId);
});

/// The watches this phone signed in that are in another workspace than the selected one: a move
/// that hasn't happened yet (the switch was made offline, say). Settings → Watch lists them too,
/// so a signed-in watch never looks signed out. The bridge refreshes it with [watchKeysProvider].
final watchesElsewhereProvider = FutureProvider.autoDispose<List<WatchRecord>>((
  ref,
) async {
  final orgId = ref.watch(currentOrgIdProvider);
  final userId = ref.watch(backendProvider).userId;
  if (orgId == null || userId == null) return const [];
  return [
    for (final r in await WatchKeyStore.load())
      if (r.userId == userId && r.active && r.orgId != orgId) r,
  ];
});

/// The person's watch settings; null on a server without watches.
final watchPrefsProvider = FutureProvider.autoDispose<WatchPrefsView?>(
  (ref) => ref.watch(backendProvider).watchPrefs(),
);
