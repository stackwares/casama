import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';

import '../../core/providers.dart';
import 'companion.dart';
import '../../core/analytics.dart';

Set<String> capsOf(LocalDevice d) => {
  if (d.capabilities.shell == true) 'shell',
  if (d.capabilities.files == true) 'files',
  if (d.capabilities.browser == true) 'browser',
  if (d.capabilities.desktop == true) 'desktop',
  if (d.capabilities.mcp == true) 'mcp',
  if (d.capabilities.messages == true) 'messages',
};

/// This computer's local MCP servers in the current workspace (D-096).
final localMcpServersProvider = FutureProvider<List<LocalMcpConfig>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.read(localMcpStoreProvider).read(org.id);
});

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
    unawaited(_syncMcpServers(device));
    return device;
  }

  /// The servers live on this computer, the workspace's record of them under this device's id.
  /// When the device id changes (paired again, or a build that reads another token store), the
  /// local list stays but the workspace has nothing for the new id, so bots never see the tools.
  /// Registers them again then; a launch where both agree only reads the integrations.
  Future<void> _syncMcpServers(LocalDevice d) async {
    try {
      final servers = await ref.read(localMcpStoreProvider).read(d.orgId);
      if (servers.isEmpty) return;
      final backend = ref.read(backendProvider);
      final have = {
        for (final i in await backend.integrations(d.orgId))
          if (i.kind == IntegrationKind.localMcp && i.device?.id == d.id) i.name,
      };
      if (have.length == servers.length && servers.every((s) => have.contains(_mcpName(d, s.key)))) return;
      await _registerMcpServers(d, servers);
      ref.invalidate(integrationsProvider);
    } catch (e) {
      debugPrint('local MCP sync failed: $e');
    }
  }

  /// The API names each one `<key, 32 chars>_<first 6 of the device id>` (setLocalMcpServers).
  static String _mcpName(LocalDevice d, String key) {
    final id = d.id.replaceAll('-', '');
    return '${key.length > 32 ? key.substring(0, 32) : key}_${id.length > 6 ? id.substring(0, 6) : id}';
  }

  Future<void> _registerMcpServers(LocalDevice d, List<LocalMcpConfig> servers) => ref.read(backendProvider).setLocalMcpServers(d.id, [
    for (final s in servers)
      LocalMcpServerInfo(
        key: s.key,
        label: s.label,
        kind: s.kind == 'loopback' ? LocalMcpServerInfoKindEnum.loopback : LocalMcpServerInfoKindEnum.stdio,
        summary: s.summary.length > 300 ? s.summary.substring(0, 300) : s.summary,
        timeoutS: s.timeoutS,
        auth: LocalMcpServerInfoAuthEnum.values.firstWhere((a) => a.value == s.auth, orElse: () => LocalMcpServerInfoAuthEnum.none),
      ),
  ]);

  Future<void> _start(LocalDevice d, String token) async {
    final servers = await _followMovedServers(d);
    await ref
        .read(companionProvider)
        .start(
          apiUrl: ref.read(backendProvider).apiUrl,
          deviceToken: token,
          settings: CompanionSettings(
            capabilities: capsOf(d),
            roots: d.allowedRoots,
            mcpServers: servers,
            onMcpCredentials: (key, oauth) => unawaited(_keepCredentials(d.orgId, key, oauth)),
          ),
        );
  }

  /// T3 Code picks its port when it starts (D-363): use the address it has now.
  Future<List<LocalMcpConfig>> _followMovedServers(LocalDevice d) async {
    final store = ref.read(localMcpStoreProvider);
    final servers = await store.read(d.orgId);
    if (!servers.any((s) => s.source == 't3code')) return servers;
    final now = await ref.read(companionProvider).t3CodeMcpUrl().catchError((_) => null);
    if (now == null || servers.every((s) => s.source != 't3code' || s.url == now)) return servers;
    final next = [for (final s in servers) s.source == 't3code' ? s.copyWith(url: now) : s];
    await store.write(d.orgId, next);
    ref.invalidate(localMcpServersProvider);
    unawaited(_registerMcpServers(d, next).catchError((_) {}));
    return next;
  }

  /// computerd refreshed a server's sign-in (or it ran out): keep the tokens with the server,
  /// without restarting anything.
  Future<void> _keepCredentials(String orgId, String key, Map<String, dynamic>? oauth) async {
    try {
      final store = ref.read(localMcpStoreProvider);
      final servers = await store.read(orgId);
      if (!servers.any((s) => s.key == key)) return;
      await store.write(orgId, [for (final s in servers) s.key == key ? s.copyWith(oauth: () => oauth) : s]);
      ref.invalidate(localMcpServersProvider);
    } catch (e) {
      debugPrint('keeping local MCP sign-in failed: $e');
    }
  }

  /// Signs in to a server with the browser (MCP OAuth, D-363), then saves it and restarts.
  Future<void> signInMcpServer(String key) async {
    final d = state.value;
    if (d == null) return;
    final servers = await ref.read(localMcpStoreProvider).read(d.orgId);
    final server = servers.firstWhere((s) => s.key == key);
    final oauth = await ref.read(companionProvider).signInMcp(server);
    await saveMcpServers([for (final s in servers) s.key == key ? s.copyWith(oauth: () => oauth) : s]);
  }

  /// Saves this computer's local MCP servers: everything on the device, the non-secret parts to
  /// the workspace, then restarts the companion so computerd picks them up (D-096).
  Future<void> saveMcpServers(List<LocalMcpConfig> servers) async {
    final d = state.value;
    if (d == null) return;
    await ref.read(localMcpStoreProvider).write(d.orgId, servers);
    await _registerMcpServers(d, servers);
    ref.invalidate(localMcpServersProvider);
    final stored = await ref.read(deviceTokenStoreProvider).read(d.orgId);
    if (d.enabled && stored != null) await _start(d, stored.$2);
  }

  /// Tests one local MCP server the way a bot reaches it: the workspace lists its tools through
  /// the tunnel and this computer's computerd, which also refreshes the tools bots see. Null when
  /// the workspace has no record of the server.
  Future<IntegrationTestResult?> testMcpServer(String key) async {
    final d = state.value;
    if (d == null) return null;
    final backend = ref.read(backendProvider);
    final name = _mcpName(d, key);
    final match = (await backend.integrations(d.orgId)).where((i) => i.kind == IntegrationKind.localMcp && i.device?.id == d.id && i.name == name).firstOrNull;
    if (match == null) return null;
    final result = await backend.testIntegration(match.id);
    ref.invalidate(integrationsProvider);
    return result;
  }

  /// Pairs this machine (off until the user approves capabilities and folders).
  Future<void> pair(String name) async {
    final org = ref.read(currentOrgProvider)!;
    final created = await ref.read(backendProvider).createLocalDevice(org.id, name, platformName());
    await ref.read(deviceTokenStoreProvider).write(org.id, created.id, created.token);
    Analytics.log('companion_paired', {'os': platformName()});
    // Pairing adds this machine to the computers, and bots may be pointed at it right after.
    ref.invalidate(computersProvider);
    ref.invalidateSelf();
    await future;
  }

  Future<void> save({Set<String>? capabilities, List<String>? roots, List<String>? botIds, bool? enabled}) async {
    final d = state.value;
    if (d == null) return;
    final updated = await ref.read(backendProvider).updateLocalDevice(d.id, capabilities: capabilities, roots: roots, botIds: botIds, enabled: enabled);
    final stored = await ref.read(deviceTokenStoreProvider).read(updated.orgId);
    if (updated.enabled && stored != null) {
      await _start(updated, stored.$2);
    } else {
      await ref.read(companionProvider).stop();
    }
    // Allowing a bot makes this machine its computer; its screen looks it up in this list.
    ref.invalidate(computersProvider);
    state = AsyncData(updated);
  }

  /// One Allow for a coding agent this computer hasn't run before (D-370). Only the server's
  /// record changes: the companion keeps running, so nothing a bot is doing here stops.
  Future<void> allowCodingAgent(String id) async {
    final d = state.value;
    if (d == null) return;
    final updated = await ref.read(backendProvider).updateLocalDevice(d.id, codingAgents: {...?d.allowedCodingAgents, id}.toList());
    state = AsyncData(updated);
  }

  Future<void> unpair() async {
    final d = state.value;
    if (d == null) return;
    await ref.read(companionProvider).stop();
    await ref.read(backendProvider).deleteLocalDevice(d.id);
    await ref.read(deviceTokenStoreProvider).delete(d.orgId);
    // The server removed its computer and cleared the bots that used it.
    ref.invalidate(computersProvider);
    ref.invalidate(botsProvider);
    state = const AsyncData(null);
  }
}

final companionControllerProvider = AsyncNotifierProvider<CompanionController, LocalDevice?>(CompanionController.new);
