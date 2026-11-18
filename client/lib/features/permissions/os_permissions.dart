import 'package:flutter/foundation.dart';

import '../../l10n/generated/app_localizations.dart';

/// System permissions a bot may need on the person's own devices (D-376).
///
/// The same table as `packages/domain/src/os-permissions.ts` (test/os_permissions_test.dart keeps
/// them identical). Only permissions Casama's builds declare are listed; ids are plain strings on
/// the wire, so a newer server may name one this table doesn't have ([osPermission] is null).
enum PermissionAsk {
  /// The system can ask once; after a "no" only its settings can change it.
  prompt,

  /// Only the system's settings can turn it on.
  settings,

  /// One of Casama's own settings (Use this computer).
  casama,
}

class OsPermissionInfo {
  const OsPermissionInfo(this.id, this.platforms, {this.relaunch = const {}});
  final String id;
  final Map<String, PermissionAsk> platforms;

  /// Platforms where a change only takes effect after Casama restarts.
  final Set<String> relaunch;
}

const _p = PermissionAsk.prompt;
const _s = PermissionAsk.settings;
const _c = PermissionAsk.casama;

const osPermissions = <OsPermissionInfo>[
  OsPermissionInfo('location', {'ios': _p, 'android': _p, 'web': _p}),
  OsPermissionInfo('location_always', {'ios': _p, 'android': _p}),
  OsPermissionInfo('camera', {'ios': _p, 'web': _p}),
  OsPermissionInfo('microphone', {'ios': _p, 'android': _p, 'macos': _p, 'windows': _s, 'web': _p}),
  OsPermissionInfo('speech', {'ios': _p, 'macos': _p}),
  OsPermissionInfo('photos', {'ios': _p}),
  OsPermissionInfo('contacts', {'ios': _p, 'android': _p, 'macos': _p}),
  OsPermissionInfo('calendar', {'ios': _p, 'android': _p}),
  OsPermissionInfo('health', {'ios': _p, 'android': _p}),
  OsPermissionInfo('notifications', {'ios': _p, 'android': _p, 'macos': _p, 'windows': _s, 'web': _p}),
  OsPermissionInfo('notification_access', {'android': _s}),
  OsPermissionInfo('accessibility', {'macos': _p}),
  OsPermissionInfo('screen_recording', {'macos': _p}, relaunch: {'macos'}),
  OsPermissionInfo('automation', {'macos': _p}),
  OsPermissionInfo('full_disk', {'macos': _s}),
  OsPermissionInfo('shared_folders', {'macos': _c, 'windows': _c, 'linux': _c}),
  OsPermissionInfo('local_tools', {'macos': _c, 'windows': _c, 'linux': _c}),
];

final _byId = {for (final p in osPermissions) p.id: p};

OsPermissionInfo? osPermission(String id) => _byId[id];

/// The states a device reports (checked without prompting).
abstract final class PermissionState {
  static const granted = 'granted';
  static const limited = 'limited';
  static const denied = 'denied';
  static const notAsked = 'not_asked';
  static const restricted = 'restricted';
  static const unknown = 'unknown';
  static const unavailable = 'unavailable';
}

/// Usable as it is (limited counts: some photos, approximate location).
bool permissionOn(String? state) => state == PermissionState.granted || state == PermissionState.limited;

/// Casama's platform names onto the table's columns.
String? permissionPlatformOf(String platform) {
  final p = platform.toLowerCase();
  if (p == 'mac' || p == 'darwin') return 'macos';
  if (p == 'chrome' || p == 'browser') return 'web';
  return const {'ios', 'android', 'macos', 'windows', 'linux', 'web'}.contains(p) ? p : null;
}

/// This app's platform, in the table's names.
String currentPermissionPlatform() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'linux',
  };
}

/// How [id] is asked for on [platform]; null when that platform doesn't have it.
PermissionAsk? permissionAsk(String id, String platform) {
  final p = permissionPlatformOf(platform);
  return p == null ? null : osPermission(id)?.platforms[p];
}

bool permissionNeedsRelaunch(String id, String platform) {
  final p = permissionPlatformOf(platform);
  return p != null && (osPermission(id)?.relaunch.contains(p) ?? false);
}

/// Every permission [platform] has.
List<String> permissionIdsFor(String platform) {
  final p = permissionPlatformOf(platform);
  return [
    for (final i in osPermissions)
      if (p != null && i.platforms.containsKey(p)) i.id,
  ];
}

/// The row's name; for an id this table doesn't know, the id with spaces.
String osPermissionLabel(AppLocalizations l10n, String id) => switch (id) {
  'location' => l10n.permLocation,
  'location_always' => l10n.permLocationAlways,
  'camera' => l10n.permCamera,
  'microphone' => l10n.permMicrophone,
  'speech' => l10n.permSpeech,
  'photos' => l10n.permPhotos,
  'contacts' => l10n.permContacts,
  'calendar' => l10n.permCalendar,
  'health' => l10n.permHealth,
  'notifications' => l10n.permNotifications,
  'notification_access' => l10n.permNotificationAccess,
  'accessibility' => l10n.permAccessibility,
  'screen_recording' => l10n.permScreenRecording,
  'automation' => l10n.permAutomation,
  'full_disk' => l10n.permFullDisk,
  'shared_folders' => l10n.permSharedFolders,
  'local_tools' => l10n.permLocalTools,
  _ => id.replaceAll('_', ' '),
};
