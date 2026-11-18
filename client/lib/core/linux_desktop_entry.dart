import 'dart:io';

import 'package:flutter/foundation.dart';

/// The application id (linux/CMakeLists.txt), which is also the Wayland app id.
const linuxAppId = 'ai.casama.app';

/// Linux: the desktop portal (the global shortcut) and casama:// links find the app by a desktop
/// entry named after its application id. A snap or flatpak brings its own; the tar.gz bundle and
/// development builds don't, so the app writes one into the user's applications folder, pointing
/// at wherever it runs from. Best effort: without it the shortcut and casama:// links don't work.
Future<void> ensureLinuxDesktopEntry({
  Map<String, String>? environment,
  String? executable,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.linux) return;
  final env = environment ?? Platform.environment;
  // snapd and flatpak set these for the apps they run.
  if (env.containsKey('SNAP') || env.containsKey('FLATPAK_ID')) return;
  final home = env['HOME'];
  if (home == null || home.isEmpty) return;
  try {
    final dataHome = (env['XDG_DATA_HOME'] ?? '').isNotEmpty ? env['XDG_DATA_HOME']! : '$home/.local/share';
    final file = File('$dataHome/applications/$linuxAppId.desktop');
    final content = linuxDesktopEntry(executable ?? Platform.resolvedExecutable);
    if (file.existsSync() && file.readAsStringSync() == content) return;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    // Lets casama:// find the entry; missing on some systems, which is fine.
    await Process.run('update-desktop-database', [file.parent.path]).catchError((_) => ProcessResult(0, 1, '', ''));
  } catch (e) {
    debugPrint('desktop entry unavailable: $e');
  }
}

/// The entry's text for the app at [executable] (bundle/casama, with bundle/data/casama.png).
@visibleForTesting
String linuxDesktopEntry(String executable) {
  final dir = File(executable).parent.path;
  String quoted(String s) => s.contains(RegExp(r'[\s"\\`$]')) ? '"${s.replaceAllMapped(RegExp(r'["\\`$]'), (m) => '\\${m[0]}')}"' : s;
  return '''[Desktop Entry]
Type=Application
Name=Casama
Comment=Persistent AI teammates
Exec=${quoted(executable)} %U
Icon=$dir/data/casama.png
Terminal=false
Categories=Office;Chat;Utility;
MimeType=x-scheme-handler/casama;
StartupWMClass=$linuxAppId
Keywords=AI;assistant;agent;bot;chat;
''';
}
