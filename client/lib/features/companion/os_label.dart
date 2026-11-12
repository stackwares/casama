import 'dart:io';

/// A readable operating system name from what Dart reports, e.g. "macOS 26.2", "Windows 11 Pro"
/// or "Ubuntu 24.04.1 LTS" (D-227). The desktop app sends it when it connects, for the computer
/// card. [osRelease] is the text of /etc/os-release on Linux.
String osLabel({required String os, required String version, String? osRelease}) {
  switch (os) {
    case 'macos':
      final v = RegExp(r'Version ([\d.]+)').firstMatch(version)?.group(1);
      return v == null ? 'macOS' : 'macOS $v';
    case 'windows':
      var name = RegExp(r'"([^"]+)"').firstMatch(version)?.group(1)?.trim() ?? 'Windows';
      final build = int.tryParse(RegExp(r'Build (\d+)').firstMatch(version)?.group(1) ?? '');
      // Windows 11 still calls itself "Windows 10" in the registry; its builds start at 22000.
      if (build != null && build >= 22000 && name.startsWith('Windows 10')) {
        name = name.replaceFirst('Windows 10', 'Windows 11');
      }
      return name;
    case 'linux':
      final pretty = RegExp(r'^PRETTY_NAME="?([^"\n]+)"?\s*$', multiLine: true).firstMatch(osRelease ?? '')?.group(1)?.trim();
      return pretty == null || pretty.isEmpty ? 'Linux' : pretty;
    default:
      return os;
  }
}

/// This machine's operating system, for the computer card.
Future<String> currentOsLabel() async {
  String? release;
  if (Platform.isLinux) {
    try {
      release = await File('/etc/os-release').readAsString();
    } catch (_) {}
  }
  return osLabel(os: Platform.operatingSystem, version: Platform.operatingSystemVersion, osRelease: release);
}
