import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
import 'providers.dart';

/// Remote app settings (D-241): what the server's owner changes in every installed app without a
/// release. The oldest version each platform still accepts, a maintenance notice, announcements
/// and feature switches. Read without signing in, refreshed every half hour and when the app comes
/// back to the front, and kept on the device so a minimum version holds offline too.

const _savedKey = 'remoteConfig.saved';
const _dismissedKey = 'remoteConfig.dismissed';

/// This device's platform, as the settings name it.
String remotePlatform() {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  return 'linux';
}

/// -1, 0 or 1 for x.y.z versions (anything after a + or - is ignored).
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp('[+-]'))
      .first
      .split('.')
      .map((n) => int.tryParse(n) ?? 0)
      .toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < pa.length ? pa[i] : 0) - (i < pb.length ? pb[i] : 0);
    if (d != 0) return d < 0 ? -1 : 1;
  }
  return 0;
}

String? _perPlatform(Map<String, dynamic> m, String platform) {
  final v = m[platform];
  return v is String && v.isNotEmpty ? v : null;
}

/// The app's own version (pubspec), or null while it loads.
final appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);

final remoteConfigProvider =
    AsyncNotifierProvider<RemoteConfigNotifier, RemoteAppConfig?>(
      RemoteConfigNotifier.new,
    );

class RemoteConfigNotifier extends AsyncNotifier<RemoteAppConfig?> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  @override
  Future<RemoteAppConfig?> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) => refresh());
    _lifecycle?.dispose();
    _lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
    });
    final saved = await _readSaved();
    unawaited(refresh());
    return saved;
  }

  /// Fetches the settings; offline or on an older server, what's known stays.
  Future<void> refresh() async {
    try {
      final fresh = await ref.read(backendProvider).appConfig();
      state = AsyncData(fresh);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_savedKey, jsonEncode(fresh.toJson()));
      } catch (_) {}
    } catch (_) {}
  }

  Future<RemoteAppConfig?> _readSaved() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_savedKey);
      return raw == null
          ? null
          : RemoteAppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// A feature switch from the server's owner; [fallback] when the server doesn't name it.
bool remoteFlag(WidgetRef ref, String name, {bool fallback = false}) =>
    ref.watch(remoteConfigProvider).value?.flags[name] ?? fallback;

/// Whether [a] applies to this app now: its time window, platforms and versions.
bool announcementApplies(
  Announcement a, {
  required String platform,
  required String? version,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final starts = a.startsAt == null ? null : DateTime.tryParse(a.startsAt!);
  final ends = a.endsAt == null ? null : DateTime.tryParse(a.endsAt!);
  if (starts != null && at.isBefore(starts)) return false;
  if (ends != null && at.isAfter(ends)) return false;
  final platforms = a.platforms;
  if (platforms != null && platforms.isNotEmpty && !platforms.any((p) => p.value == platform)) {
    return false;
  }
  final min = a.minVersion, max = a.maxVersion;
  if (version != null && min != null && compareVersions(version, min) < 0) return false;
  if (version != null && max != null && compareVersions(version, max) > 0) return false;
  return true;
}

/// Puts the remote settings over the app: maintenance or a required update cover it; the newest
/// announcement that applies shows as a banner at the top until it's dismissed.
class RemoteConfigGate extends ConsumerStatefulWidget {
  const RemoteConfigGate({super.key, required this.child, this.platform});
  final Widget child;

  /// Tests pick the platform; the device's otherwise.
  final String? platform;

  @override
  ConsumerState<RemoteConfigGate> createState() => _RemoteConfigGateState();
}

class _RemoteConfigGateState extends ConsumerState<RemoteConfigGate> {
  Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadDismissed());
  }

  Future<void> _loadDismissed() async {
    try {
      final ids =
          (await SharedPreferences.getInstance()).getStringList(
            _dismissedKey,
          ) ??
          const [];
      if (mounted) setState(() => _dismissed = {..._dismissed, ...ids});
    } catch (_) {}
  }

  Future<void> _dismiss(String id) async {
    setState(() => _dismissed = {..._dismissed, id});
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only recent ids: announcements are few and short-lived.
      await prefs.setStringList(
        _dismissedKey,
        _dismissed.toList().reversed.take(50).toList(),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigProvider).value;
    final version = ref.watch(appVersionProvider).value;
    if (config == null) return widget.child;
    final platform = widget.platform ?? remotePlatform();
    final min = _perPlatform(config.minVersions.toJson(), platform);
    final updateUrl = _perPlatform(config.updateUrls.toJson(), platform);
    if (version != null && min != null && compareVersions(version, min) < 0) {
      return _Cover(
        key: const Key('remoteUpdate'),
        icon: LucideIcons.download,
        kind: _CoverKind.update,
        url: updateUrl,
      );
    }
    final maintenance = config.maintenance?.message;
    if (maintenance != null && maintenance.isNotEmpty) {
      return _Cover(
        key: const Key('remoteMaintenance'),
        icon: LucideIcons.wrench,
        kind: _CoverKind.maintenance,
        message: maintenance,
        onRetry: () => ref.read(remoteConfigProvider.notifier).refresh(),
      );
    }
    final shown = config.announcements
        .where(
          (a) =>
              !_dismissed.contains(a.id) &&
              announcementApplies(a, platform: platform, version: version),
        )
        .firstOrNull;
    if (shown == null) return widget.child;
    return Stack(
      // The app fills the window; the banner floats over its top edge.
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: _AnnouncementBanner(
              announcement: shown,
              onDismiss: () => _dismiss(shown.id),
            ),
          ),
        ),
      ],
    );
  }
}

enum _CoverKind { update, maintenance }

/// A full-window page in place of the app (no navigator above it: plain widgets only).
class _Cover extends StatelessWidget {
  const _Cover({
    super.key,
    required this.icon,
    required this.kind,
    this.url,
    this.message,
    this.onRetry,
  });
  final IconData icon;
  final _CoverKind kind;
  final String? url;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final update = kind == _CoverKind.update;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: scheme.primary),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    update
                        ? l10n.remoteUpdateTitle
                        : l10n.remoteMaintenanceTitle,
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    update
                        ? (url == null
                              ? l10n.remoteUpdateNoLink
                              : l10n.remoteUpdateBody)
                        : message!,
                    style: text.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.xl),
                  if (update && url != null)
                    FilledButton.icon(
                      key: const Key('remoteUpdateButton'),
                      onPressed: () => launchUrl(
                        Uri.parse(url!),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(LucideIcons.download, size: 18),
                      label: Text(l10n.update),
                    ),
                  if (!update)
                    OutlinedButton(
                      onPressed: onRetry,
                      child: Text(l10n.tryAgain),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner({
    required this.announcement,
    required this.onDismiss,
  });
  final Announcement announcement;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final warning = announcement.level == AnnouncementLevelEnum.warning;
    final bg = warning ? scheme.errorContainer : scheme.primaryContainer;
    final fg = warning ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    final url = announcement.url;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Material(
            key: Key('announcement-${announcement.id}'),
            color: bg,
            elevation: 3,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.xs,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    warning ? LucideIcons.triangleAlert : LucideIcons.megaphone,
                    size: 20,
                    color: fg,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          announcement.title,
                          style: text.titleSmall?.copyWith(color: fg),
                        ),
                        if (announcement.body.isNotEmpty)
                          Text(
                            announcement.body,
                            style: text.bodySmall?.copyWith(color: fg),
                          ),
                      ],
                    ),
                  ),
                  if (url != null)
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
                      style: TextButton.styleFrom(foregroundColor: fg),
                      child: Text(l10n.openLink),
                    ),
                  Semantics(
                    label: l10n.dismiss,
                    button: true,
                    child: IconButton(
                      key: const Key('announcementDismiss'),
                      onPressed: onDismiss,
                      icon: Icon(LucideIcons.x, size: 18, color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
