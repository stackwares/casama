import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import 'companion.dart';

Set<String> capsOf(LocalDevice d) => {
      if (d.capabilities.shell == true) 'shell',
      if (d.capabilities.files == true) 'files',
      if (d.capabilities.browser == true) 'browser',
      if (d.capabilities.desktop == true) 'desktop',
    };

String platformName() => switch (defaultTargetPlatform) {
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      _ => 'linux',
    };

/// This machine as a bot computer in the current workspace: pairing, settings, and keeping the
/// companion running while it is turned on.
class CompanionController extends AsyncNotifier<LocalDevice?> {
  @override
  Future<LocalDevice?> build() async {
    final org = ref.watch(currentOrgProvider);
    final companion = ref.watch(companionProvider);
    if (org == null || !companion.supported) return null;
    final stored = await ref.read(deviceTokenStoreProvider).read(org.id);
    if (stored == null) return null;
    final devices = await ref.read(backendProvider).localDevices(org.id);
    final device = devices.where((d) => d.id == stored.$1).firstOrNull;
    if (device == null) {
      await ref.read(deviceTokenStoreProvider).delete(org.id);
      return null;
    }
    if (device.enabled) await _start(device, stored.$2);
    return device;
  }

  Future<void> _start(LocalDevice d, String token) => ref.read(companionProvider).start(
        apiUrl: ref.read(backendProvider).apiUrl,
        deviceToken: token,
        settings: CompanionSettings(capabilities: capsOf(d), roots: d.allowedRoots),
      );

  /// Pairs this machine (off until the user approves capabilities and folders).
  Future<void> pair(String name) async {
    final org = ref.read(currentOrgProvider)!;
    final created = await ref.read(backendProvider).createLocalDevice(org.id, name, platformName());
    await ref.read(deviceTokenStoreProvider).write(org.id, created.id, created.token);
    ref.invalidateSelf();
    await future;
  }

  Future<void> save({Set<String>? capabilities, List<String>? roots, List<String>? botIds, bool? enabled}) async {
    final d = state.value;
    if (d == null) return;
    final updated = await ref
        .read(backendProvider)
        .updateLocalDevice(d.id, capabilities: capabilities, roots: roots, botIds: botIds, enabled: enabled);
    final stored = await ref.read(deviceTokenStoreProvider).read(updated.orgId);
    if (updated.enabled && stored != null) {
      await _start(updated, stored.$2);
    } else {
      await ref.read(companionProvider).stop();
    }
    state = AsyncData(updated);
  }

  Future<void> unpair() async {
    final d = state.value;
    if (d == null) return;
    await ref.read(companionProvider).stop();
    await ref.read(backendProvider).deleteLocalDevice(d.id);
    await ref.read(deviceTokenStoreProvider).delete(d.orgId);
    state = const AsyncData(null);
  }
}

final companionControllerProvider = AsyncNotifierProvider<CompanionController, LocalDevice?>(CompanionController.new);
