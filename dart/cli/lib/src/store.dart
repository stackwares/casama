import 'dart:convert';
import 'dart:io';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:path/path.dart' as p;

/// Config directory: $CASAMA_CONFIG_DIR, else ~/.config/casama (APPDATA on Windows).
Directory configDir() {
  final override = Platform.environment['CASAMA_CONFIG_DIR'];
  if (override != null && override.isNotEmpty) return Directory(override);
  final home = Platform.isWindows
      ? Platform.environment['APPDATA'] ?? '.'
      : p.join(Platform.environment['HOME'] ?? '.', '.config');
  return Directory(p.join(home, 'casama'));
}

void _writePrivate(File file, String contents) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
  if (!Platform.isWindows) Process.runSync('chmod', ['600', file.path]);
}

/// Session file, readable only by the current user.
class FileSessionStore implements SessionStore {
  FileSessionStore(this.file);
  final File file;

  @override
  Future<AuthSession?> load() async {
    if (!file.existsSync()) return null;
    try {
      return AuthSession.fromAuthResponse(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(AuthSession session) async =>
      _writePrivate(file, jsonEncode(session.toJson()));

  @override
  Future<void> clear() async {
    if (file.existsSync()) file.deleteSync();
  }
}

/// Small key-value settings file (api_url).
class Settings {
  Settings(this.file);
  final File file;

  Map<String, dynamic> _read() => file.existsSync()
      ? jsonDecode(file.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};

  String? get(String key) => _read()[key] as String?;
  void set(String key, String value) {
    final data = _read()..[key] = value;
    _writePrivate(file, const JsonEncoder.withIndent('  ').convert(data));
  }
}
