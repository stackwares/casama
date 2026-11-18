import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import 'docker_check.dart';
import 'local_server.dart';

/// Guided setup of a server on this computer (D-309): Docker, the server, the owner's account, a
/// model, and a phone, one step after another at `/setup`.
///
/// Connecting to the new server rebuilds the whole app, so what the setup remembers lives here,
/// outside the widget tree, and on disk: quitting half way picks up at the same step. Which step
/// that is comes from what is true (the server answers, someone is signed in, a key exists), never
/// from a saved number.
abstract final class GuidedSetup {
  static const _activeKey = 'casama.setup.active';
  static const _skippedKey = 'casama.setup.skipped';
  static const _cardKey = 'casama.setup.card_dismissed';

  /// The setup is under way: signed-out launches open it instead of the sign-in screen, and the
  /// first-run pages (name, notifications) stay out of its way.
  static final active = ValueNotifier<bool>(false);

  /// Steps the person chose to leave for later (`ai`, `phone`).
  static final skipped = ValueNotifier<Set<String>>(const {});

  /// The "Finish setting up" card was closed for good.
  static final cardDismissed = ValueNotifier<bool>(false);

  /// Read at startup, before the first frame, so the router already knows.
  static Future<void> preload() async {
    try {
      final p = await SharedPreferences.getInstance();
      active.value = p.getBool(_activeKey) ?? false;
      skipped.value = (p.getStringList(_skippedKey) ?? const []).toSet();
      cardDismissed.value = p.getBool(_cardKey) ?? false;
    } catch (_) {}
  }

  static Future<void> _save(void Function(SharedPreferences p) write) async {
    try {
      write(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  static Future<void> begin() {
    active.value = true;
    return _save((p) => p.setBool(_activeKey, true));
  }

  /// Leaves the setup (finished, or closed part way); what was skipped stays for the card.
  static Future<void> end() {
    active.value = false;
    return _save((p) => p.setBool(_activeKey, false));
  }

  static Future<void> skip(String step) {
    skipped.value = {...skipped.value, step};
    return _save((p) => p.setStringList(_skippedKey, skipped.value.toList()));
  }

  /// A skipped step was done after all.
  static Future<void> unskip(String step) {
    if (!skipped.value.contains(step)) return Future.value();
    skipped.value = {...skipped.value}..remove(step);
    return _save((p) => p.setStringList(_skippedKey, skipped.value.toList()));
  }

  static Future<void> dismissCard() {
    cardDismissed.value = true;
    return _save((p) => p.setBool(_cardKey, true));
  }

  @visibleForTesting
  static void reset() {
    active.value = false;
    skipped.value = const {};
    cardDismissed.value = false;
  }
}

/// Installs and starts the server on this computer.
final localServerManagerProvider = Provider<LocalServerManager>((ref) => LocalServerManager());

/// Looks at Docker on this computer.
final dockerCheckProvider = Provider<DockerCheck>((ref) => DockerCheck());

/// Whether the app is talking to the server this app installed on this computer.
final usingLocalServerProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (!localServerSupported) return false;
  final local = await ref.watch(localServerManagerProvider).installed();
  if (local == null) return false;
  final using = Uri.tryParse(ref.watch(backendProvider).apiUrl);
  final own = Uri.parse(local.url);
  return using != null && using.port == own.port && RemoteAccessSettings.isLoopback(using.host);
});
