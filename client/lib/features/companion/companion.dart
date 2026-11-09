import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'companion_stub.dart' if (dart.library.io) 'companion_io.dart' as impl;

/// What a bot is doing on this computer right now (shown in the overlay and tray).
class CompanionActivity {
  const CompanionActivity({required this.runId, required this.bot, required this.tool, required this.summary});
  final String runId;
  final String bot;
  final String tool;
  final String summary;
}

enum CompanionStatus { off, connecting, online, error }

/// Settings the user approved on this machine (D-066). Capabilities: shell, files, browser, desktop.
class CompanionSettings {
  const CompanionSettings({required this.capabilities, required this.roots});
  final Set<String> capabilities;
  final List<String> roots;
}

/// The desktop companion: runs computerd locally and answers the API's tunnel requests.
/// Keeps this machine's device id and token per workspace (secure storage; a 0600 file if the
/// keychain is unavailable, for example in unsigned development builds).
abstract class DeviceTokenStore {
  Future<(String, String)?> read(String orgId);
  Future<void> write(String orgId, String deviceId, String token);
  Future<void> delete(String orgId);
}

abstract class Companion {
  ValueListenable<CompanionStatus> get status;
  ValueListenable<CompanionActivity?> get activity;
  bool get supported;
  Future<void> start({required String apiUrl, required String deviceToken, required CompanionSettings settings});
  Future<void> stop();
}

final deviceTokenStoreProvider = Provider<DeviceTokenStore>((ref) => impl.createTokenStore());

final companionProvider = Provider<Companion>((ref) {
  final c = impl.createCompanion();
  ref.onDispose(c.stop);
  return c;
});
