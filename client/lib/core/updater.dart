import 'dart:async';
import 'dart:convert';

import 'package:auto_updater/auto_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'distribution.dart';
import 'telemetry.dart';

/// Where releases live: a public repo with only installers and update feeds (the source repo is
/// private, so its release files aren't downloadable without signing in). Overridable per build.
const kReleasesRepo = String.fromEnvironment('CASAMA_RELEASES_REPO', defaultValue: 'stackwares/casama-releases');

/// The update feeds (appcasts), one per platform, attached to the latest release.
const kUpdateFeedBase = String.fromEnvironment(
  'CASAMA_UPDATE_FEED',
  defaultValue: 'https://github.com/$kReleasesRepo/releases/latest/download',
);

/// The direct-download desktop apps update themselves (Sparkle on macOS, WinSparkle on Windows).
/// The stores update theirs, so the Mac App Store build never starts the updater.
bool get selfUpdating =>
    !kIsWeb && !isMacAppStoreBuild && (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows);

/// Linux installs come from packages; the app only says when a newer one is out.
bool get updateNoticeOnly => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

const _mac = MethodChannel('casama/mac');
const _autoKey = 'updates.auto';
const _checkEvery = 6 * 3600;

/// Starts the updater once (watched by the app root): the feed, and background checks unless they
/// were turned off.
final updaterProvider = Provider<void>((ref) {
  if (!selfUpdating) return;
  unawaited(() async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.macOS ? 'macos' : 'windows';
      await autoUpdater.setFeedURL('$kUpdateFeedBase/appcast-$platform.xml');
      if (await autoUpdateChecks()) {
        await autoUpdater.setScheduledCheckInterval(_checkEvery);
        await autoUpdater.checkForUpdates(inBackground: true);
      }
    } catch (e, st) {
      debugPrint('updater: $e');
      Telemetry.captureException(e, st, context: {'service': 'updater'}, warning: true);
    }
  }());
});

/// "Check for updates": the updater's own window (found, downloading, up to date).
Future<void> checkForUpdatesNow() => autoUpdater.checkForUpdates();

/// Whether the app checks (and installs) updates on its own. On by default.
Future<bool> autoUpdateChecks() async {
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    return await _mac.invokeMethod<bool>('autoUpdateChecks').catchError((_) => true) ?? true;
  }
  return (await SharedPreferences.getInstance()).getBool(_autoKey) ?? true;
}

Future<void> setAutoUpdateChecks(bool on) async {
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    // Sparkle schedules its own checks from this setting.
    await _mac.invokeMethod<void>('setAutoUpdateChecks', on);
    return;
  }
  await (await SharedPreferences.getInstance()).setBool(_autoKey, on);
  // Windows: on, the app schedules checks; off, it stops asking (WinSparkle rejects a zero interval).
  if (on) {
    await autoUpdater.setScheduledCheckInterval(_checkEvery);
    await autoUpdater.checkForUpdates(inBackground: true);
  }
}

final autoUpdateChecksProvider = FutureProvider<bool?>((ref) async => selfUpdating ? autoUpdateChecks() : null);

/// This app's version ("0.8.0").
final appVersionProvider = FutureProvider<String>((ref) async => (await PackageInfo.fromPlatform()).version);

/// This build's version and build number, "0.8.0 (8)", for the line at the foot of Settings (just
/// "0.8.0" where a platform reports no build number). Null when it can't be read (widget tests).
final appVersionLabelProvider = FutureProvider<String?>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isEmpty ? info.version : '${info.version} (${info.buildNumber})';
  } catch (_) {
    return null;
  }
});

/// A newer release than this one (Linux only), as its version and page.
final newerReleaseProvider = FutureProvider<({String version, Uri page})?>((ref) async {
  if (!updateNoticeOnly) return null;
  try {
    final current = await ref.watch(appVersionProvider.future);
    final res = await http
        .get(Uri.parse('https://api.github.com/repos/$kReleasesRepo/releases/latest'), headers: {'accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final latest = '${j['tag_name'] ?? ''}'.replaceFirst(RegExp(r'^v'), '');
    if (!isNewerVersion(latest, current)) return null;
    return (version: latest, page: Uri.parse('${j['html_url']}'));
  } catch (_) {
    return null;
  }
});

/// Whether [candidate] ("0.9.0") is a newer release than [current] ("0.8.0").
bool isNewerVersion(String candidate, String current) {
  List<int> parts(String v) => [for (final p in v.split('+').first.split('.')) int.tryParse(p) ?? 0];
  final a = parts(candidate), b = parts(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}
