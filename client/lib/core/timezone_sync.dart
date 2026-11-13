import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers.dart';

/// Keeps the profile's timezone on this device's (D-250), so briefs, quiet hours and routines run
/// on the person's clock instead of UTC. Saved after sign-in and whenever the app comes back to
/// the front (travel changes it). The server moves the person's routines when it changes.
class TimezoneSync {
  TimezoneSync({required this.read, required this.current, required this.save});

  /// The device's IANA timezone ("Asia/Manila").
  final Future<String?> Function() read;

  /// The timezone the profile has now.
  final Future<String?> Function() current;
  final Future<void> Function(String timezone) save;
  String? _sent;

  /// A name the server can use: IANA ("Area/City") or UTC, never a bare abbreviation like "PST".
  @visibleForTesting
  static bool usable(String? tz) => tz != null && (tz == 'UTC' || RegExp(r'^[A-Za-z_]+(/[A-Za-z0-9_+\-]+)+$').hasMatch(tz));

  Future<void> sync() async {
    try {
      final tz = await read();
      if (!usable(tz) || tz == _sent) return;
      if (await current() != tz) await save(tz!);
      _sent = tz;
    } catch (e) {
      // Best effort: the profile keeps its last timezone.
      debugPrint('timezone sync failed: $e');
    }
  }
}

final timezoneSyncProvider = Provider<TimezoneSync>((ref) {
  SupabaseClient? client() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null; // Not set up (tests, or before start-up finishes).
    }
  }

  final sync = TimezoneSync(
    read: () async => (await FlutterTimezone.getLocalTimezone()).identifier,
    current: () async {
      final c = client();
      final uid = c?.auth.currentUser?.id;
      if (c == null || uid == null) return null;
      final r = await c.from('profiles').select('timezone').eq('user_id', uid).maybeSingle();
      return r?['timezone'] as String?;
    },
    save: (tz) async {
      final c = client();
      final uid = c?.auth.currentUser?.id;
      if (c == null || uid == null) return;
      await c.from('profiles').update({'timezone': tz}).eq('user_id', uid);
    },
  );
  var signedIn = false;
  ref.listen(signedInProvider, (_, next) {
    signedIn = next.value == true;
    if (signedIn) unawaited(sync.sync());
  }, fireImmediately: true);
  final lifecycle = AppLifecycleListener(
    onResume: () {
      if (signedIn) unawaited(sync.sync());
    },
  );
  ref.onDispose(lifecycle.dispose);
  return sync;
});
