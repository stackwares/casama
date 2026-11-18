import 'dart:io';

import 'package:casama/features/permissions/os_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Dart table is a copy of packages/domain/src/os-permissions.ts (D-376): the server decides
/// which rows a card shows, the app how to turn them on. This reads the TypeScript and checks the
/// two agree on ids, platforms, how each is asked for, and restarts.
void main() {
  test('the app\'s permission table matches the server\'s', () {
    final ts = File('../packages/domain/src/os-permissions.ts').readAsStringSync();
    final start = ts.indexOf('export const OS_PERMISSIONS = [');
    final end = ts.indexOf('] as const satisfies readonly OsPermissionInfo[];');
    expect(start, greaterThan(0));
    expect(end, greaterThan(start));
    final body = ts.substring(start, end);
    final entries = RegExp(r'\{\s*id: "([a-z_]+)",(.*?)\n  \},', dotAll: true).allMatches(body).toList();
    expect(entries, isNotEmpty);
    final server = <String, (Map<String, String>, Set<String>)>{};
    for (final m in entries) {
      final rest = m.group(2)!;
      final platformsText = RegExp(r'platforms: \{(.*?)\}', dotAll: true).firstMatch(rest)!.group(1)!;
      final platforms = {for (final p in RegExp(r'(\w+): "(prompt|settings|casama)"').allMatches(platformsText)) p.group(1)!: p.group(2)!};
      final relaunchText = RegExp(r'relaunch: \[(.*?)\]').firstMatch(rest)?.group(1) ?? '';
      final relaunch = {for (final r in RegExp(r'"(\w+)"').allMatches(relaunchText)) r.group(1)!};
      server[m.group(1)!] = (platforms, relaunch);
    }
    expect([for (final p in osPermissions) p.id], server.keys.toList(), reason: 'same ids in the same order');
    for (final p in osPermissions) {
      final (platforms, relaunch) = server[p.id]!;
      expect({for (final e in p.platforms.entries) e.key: e.value.name}, platforms, reason: '${p.id} platforms');
      expect(p.relaunch, relaunch, reason: '${p.id} relaunch');
    }
  });

  test('asks, platforms and states', () {
    expect(permissionAsk('screen_recording', 'macos'), PermissionAsk.prompt);
    expect(permissionAsk('screen_recording', 'ios'), isNull);
    expect(permissionAsk('full_disk', 'Darwin'), PermissionAsk.settings);
    expect(permissionAsk('shared_folders', 'windows'), PermissionAsk.casama);
    expect(permissionNeedsRelaunch('screen_recording', 'macos'), isTrue);
    expect(permissionNeedsRelaunch('accessibility', 'macos'), isFalse);
    expect(permissionIdsFor('android'), containsAll(['location', 'notification_access', 'calendar']));
    expect(permissionIdsFor('android'), isNot(contains('screen_recording')));
    expect(permissionIdsFor('toaster'), isEmpty);
    expect(permissionOn('limited'), isTrue);
    expect(permissionOn('not_asked'), isFalse);
    expect(osPermission('made_up'), isNull);
  });
}
