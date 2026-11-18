import 'dart:io';

import 'package:flutter/foundation.dart';

import 'local_server.dart';
import '../../core/remote_content.dart';

/// Where Docker stands on this computer, as the guided setup shows it (D-309).
enum DockerState {
  /// `docker info` answers and Compose v2 is there.
  ready,

  /// No `docker` command and no Docker Desktop app.
  notInstalled,

  /// Installed, but the engine isn't running (Docker Desktop closed, or the service stopped).
  notRunning,

  /// Linux: the engine runs, but this user may not use it (not in the `docker` group).
  noPermission,

  /// An engine without Compose v2 (an old or stripped-down install).
  noCompose,
}

/// Looks at Docker without changing anything, and opens it or its download when asked.
class DockerCheck {
  DockerCheck({
    ProcessRunner? runner,
    TargetPlatform? platform,
    bool Function(String path)? exists,
  }) : runner = runner ?? SystemProcessRunner(),
       platform = platform ?? defaultTargetPlatform,
       exists = exists ?? ((p) => Directory(p).existsSync());

  final ProcessRunner runner;
  final TargetPlatform platform;
  final bool Function(String path) exists;

  bool get isMac => platform == TargetPlatform.macOS;

  /// Docker Desktop's usual places on a Mac.
  static List<String> get macApps => [
    '/Applications/Docker.app',
    if ((Platform.environment['HOME'] ?? '').isNotEmpty)
      '${Platform.environment['HOME']}/Applications/Docker.app',
  ];

  Future<DockerState> state() async {
    final ProcessResult info;
    try {
      info = await runner.run('docker', ['info', '--format', '{{.ServerVersion}}']);
    } on ProcessException {
      // No command line yet: Docker Desktop puts it on the PATH the first time it is opened.
      return isMac && macApps.any(exists) ? DockerState.notRunning : DockerState.notInstalled;
    }
    if (info.exitCode != 0) {
      final said = '${info.stderr}'.toLowerCase();
      if (!isMac && said.contains('permission denied')) return DockerState.noPermission;
      return DockerState.notRunning;
    }
    try {
      final compose = await runner.run('docker', ['compose', 'version']);
      if (compose.exitCode != 0) return DockerState.noCompose;
    } on ProcessException {
      return DockerState.noCompose;
    }
    return DockerState.ready;
  }

  /// Whether this Mac has an Apple chip (true also when the app itself runs translated).
  Future<bool> appleChip() async {
    try {
      final r = await runner.run('sysctl', ['-n', 'hw.optional.arm64']);
      return r.exitCode == 0 && '${r.stdout}'.trim() == '1';
    } catch (_) {
      return false;
    }
  }

  /// The download for this computer: Docker Desktop's installer on a Mac (the right one for its
  /// chip), Docker's install guide on Linux.
  Future<Uri> downloadUrl() async {
    if (!isMac) return remoteUri('docker_linux', 'https://docs.docker.com/engine/install/');
    final arch = await appleChip() ? 'arm64' : 'amd64';
    return remoteUri('docker_mac_$arch', 'https://desktop.docker.com/mac/main/$arch/Docker.dmg');
  }

  /// Opens Docker Desktop on a Mac. Returns false when it couldn't be opened.
  Future<bool> open() async {
    if (!isMac) return false;
    try {
      return (await runner.run('open', ['-a', 'Docker'])).exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Free disk space in GB where the server's data goes, or null when it can't be read.
  Future<double?> freeDiskGb() async {
    try {
      final r = await runner.run('df', ['-Pk', Platform.environment['HOME'] ?? '/']);
      if (r.exitCode != 0) return null;
      final lines = '${r.stdout}'.trim().split('\n');
      if (lines.length < 2) return null;
      final cols = lines.last.trim().split(RegExp(r'\s+'));
      final kb = cols.length > 3 ? int.tryParse(cols[3]) : null;
      return kb == null ? null : kb / (1024 * 1024);
    } catch (_) {
      return null;
    }
  }
}

/// What the Linux fixes are, as commands the page shows to copy.
abstract final class DockerCommands {
  static const start = 'sudo systemctl start docker';
  static const allowUser = r'sudo usermod -aG docker $USER';
}
