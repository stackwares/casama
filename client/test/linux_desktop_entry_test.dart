import 'dart:io';

import 'package:casama/core/linux_desktop_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the entry runs the bundle it was written from, with its icon and casama:// links', () {
    final entry = linuxDesktopEntry('/opt/casama/casama');
    expect(entry, contains('Exec=/opt/casama/casama %U'));
    expect(entry, contains('Icon=/opt/casama/data/casama.png'));
    expect(entry, contains('MimeType=x-scheme-handler/casama;'));
    expect(entry, contains('StartupWMClass=ai.casama.app'));
  });

  test('a path with spaces is quoted in Exec', () {
    expect(linuxDesktopEntry('/home/a b/casama/casama'), contains('Exec="/home/a b/casama/casama" %U'));
  });

  group('on Linux', () {
    late Directory home;
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      home = Directory.systemTemp.createTempSync('casama-home');
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      home.deleteSync(recursive: true);
    });
    File entryIn(Directory home) => File('${home.path}/.local/share/applications/ai.casama.app.desktop');

    test('writes the entry named after the application id, and rewrites it when the app moves', () async {
      await ensureLinuxDesktopEntry(environment: {'HOME': home.path}, executable: '/opt/one/casama');
      expect(entryIn(home).readAsStringSync(), contains('Exec=/opt/one/casama %U'));
      await ensureLinuxDesktopEntry(environment: {'HOME': home.path}, executable: '/opt/two/casama');
      expect(entryIn(home).readAsStringSync(), contains('Exec=/opt/two/casama %U'));
    });

    test('a snap or flatpak brings its own entry', () async {
      await ensureLinuxDesktopEntry(environment: {'HOME': home.path, 'SNAP': '/snap/casama/1'}, executable: '/x/casama');
      await ensureLinuxDesktopEntry(environment: {'HOME': home.path, 'FLATPAK_ID': 'ai.casama.app'}, executable: '/x/casama');
      expect(entryIn(home).existsSync(), isFalse);
    });
  });
}
