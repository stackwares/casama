import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/adaptive_modal.dart';
import '../app_lock/app_lock.dart';
import '../settings/about_you_screen.dart' show aboutYouProvider;
import 'watch_key_store.dart';
import 'watch_state.dart';

/// The phone's side of signing a watch in (D-410, docs/WATCH-PLAN.md §8.2, §8.9;
/// docs/WATCH-PROTOCOL.md §3). Native code (`WatchBridge.swift`, `WearBridge.kt`) only carries
/// messages: this decides whether someone is signed in, whether the app lock asks first, and which
/// workspace, registers the watch's fingerprint, and answers. It never sees a watch's key.
///
/// - native → Dart `request {request_id, platform, fingerprint, name, model?, app_version?,
///   os_version?}`: a watch asks to be signed in.
/// - native → Dart `open {link}`: Open on phone, from the watch.
/// - Dart → native `takeRequests` (held while Flutter wasn't running), `answer`, `setContext`
///   (another workspace), `signOut`, `status`.
const watchChannelName = 'casama/watch';

final watchChannelProvider = Provider<MethodChannel>(
  (ref) => const MethodChannel(watchChannelName),
);

/// Watches pair with phones: the bridge runs on iOS and Android only. Overridden in tests.
final watchBridgeSupportedProvider = Provider<bool>(
  (ref) =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android),
);

/// With the app lock on, asks before signing [watchName] in (§10). Overridden in tests.
final watchLockAskProvider = Provider<Future<bool> Function(String watchName)>(
  (ref) =>
      (name) => _askOnScreen(ref, name),
);

/// Shows a short line on the phone ("Oliver's Apple Watch is signed in"). Overridden in tests.
final watchNoticeProvider = Provider<void Function(String message)>(
  (ref) =>
      (message) => _noticeOnScreen(ref, message),
);

/// Opens an app route the watch sent. Overridden in tests.
final watchOpenProvider = Provider<void Function(String link)>(
  (ref) =>
      (link) => ref.read(routerProvider).go(link),
);

/// What `status` says about this phone's watch.
class WatchStatus {
  const WatchStatus({
    this.supported = false,
    this.paired = false,
    this.installed = false,
  });

  /// The phone can pair a watch at all (WatchConnectivity / the Wear OS Data Layer).
  final bool supported;

  /// A watch is paired with this phone.
  final bool paired;

  /// The Casama watch app is on it.
  final bool installed;
}

final _fingerprintPattern = RegExp(r'^[0-9a-f]{64}$');

class WatchBridge {
  WatchBridge(this._ref, this._channel);

  final Ref _ref;
  final MethodChannel _channel;

  /// False once the channel turned out to have no native side (desktop, web, an older build).
  var _native = true;

  /// Requests being answered or answered already: native code may pass the same one live and
  /// again from `takeRequests`.
  final _seen = <String>{};

  /// Workspace moves and sign-outs one at a time, so two quick switches can't interleave.
  Future<void> _queue = Future.value();

  void start() => _channel.setMethodCallHandler(handle);

  void dispose() => _channel.setMethodCallHandler(null);

  /// A call from native code. Public for tests.
  Future<Object?> handle(MethodCall call) async {
    final args = call.arguments is Map
        ? Map<String, Object?>.from(call.arguments as Map)
        : const <String, Object?>{};
    switch (call.method) {
      case 'request':
        await answerRequest(args);
      case 'open':
        final link = args['link'];
        // Only places inside the app.
        if (link is String && link.startsWith('/') && !link.startsWith('//')) {
          try {
            _ref.read(watchOpenProvider)(link);
          } catch (e) {
            debugPrint('watch open failed: $e');
          }
        }
    }
    return null;
  }

  /// Answers the requests native code held while Flutter wasn't running (at launch, on resume,
  /// once signed in).
  Future<void> takeRequests() async {
    final held = await _invoke<List<Object?>>('takeRequests');
    for (final r in held ?? const []) {
      if (r is Map) await answerRequest(Map<String, Object?>.from(r));
    }
  }

  /// Signs a watch in and answers it. Never throws: a failure answers `reason: "error"`.
  Future<void> answerRequest(Map<String, Object?> args) async {
    final requestId = args['request_id'];
    if (requestId is! String || requestId.isEmpty || !_seen.add(requestId)) {
      return;
    }
    Map<String, Object?> answer;
    try {
      answer = await _signIn(args);
    } catch (e) {
      debugPrint('watch sign-in failed: $e');
      answer = const {'ok': false, 'reason': 'error'};
    }
    await _invoke<void>('answer', {'request_id': requestId, ...answer});
  }

  bool get _signedIn {
    final backend = _ref.read(backendProvider);
    return backend.isSignedIn &&
        !backend.twoStepCodeNeeded &&
        backend.userId != null;
  }

  Future<Map<String, Object?>> _signIn(Map<String, Object?> args) async {
    const error = {'ok': false, 'reason': 'error'};
    final fingerprint = args['fingerprint'];
    final platform = WatchSystem.parse(args['platform']);
    if (fingerprint is! String ||
        !_fingerprintPattern.hasMatch(fingerprint) ||
        platform == null) {
      return error;
    }
    final rawName = args['name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : (platform == WatchSystem.watchos ? 'Apple Watch' : 'Wear OS');
    String? text(String key) =>
        args[key] is String && (args[key] as String).isNotEmpty
        ? args[key] as String
        : null;

    if (!_signedIn) return const {'ok': false, 'reason': 'signed_out'};
    final backend = _ref.read(backendProvider);
    final userId = backend.userId!;
    final org = await _currentOrg();
    if (org == null || !_ref.mounted) return error;
    // With the app lock on, a watch never signs in without the person saying so (§10).
    if (_ref.read(appLockSettingsProvider).activeFor(userId) ||
        _ref.read(appLockRequiredByProvider) != null) {
      final yes = await _ref.read(watchLockAskProvider)(name);
      if (!_ref.mounted) return error;
      if (!yes) return const {'ok': false, 'reason': 'declined'};
    }
    final key = await backend.registerWatchKey(
      orgId: org.id,
      fingerprint: fingerprint,
      platform: platform,
      name: name,
      model: text('model'),
      appVersion: text('app_version'),
      osVersion: text('os_version'),
    );
    await WatchKeyStore.upsert(
      WatchRecord(
        fingerprint: fingerprint,
        platform: platform,
        name: name,
        model: text('model'),
        appVersion: text('app_version'),
        osVersion: text('os_version'),
        keyId: key.id,
        orgId: org.id,
        userId: userId,
      ),
    );
    if (!_ref.mounted) return error;
    _ref.invalidate(watchKeysProvider);
    final context = await _context(org);
    try {
      _ref.read(watchNoticeProvider)(_l10n().watchPhoneSignedIn(name));
    } catch (_) {}
    return {'ok': true, ...context};
  }

  /// What a watch needs to know about the phone's workspace: `server`, `org_id`, `org_name`,
  /// `person_name`.
  Future<Map<String, Object?>> _context(({String id, String name}) org) async =>
      {
        'server': _ref.read(backendProvider).apiUrl,
        'org_id': org.id,
        'org_name': org.name,
        'person_name': await _personName(),
      };

  /// The workspace selected now. At launch the list may still be loading.
  Future<({String id, String name})?> _currentOrg() async {
    var org = _ref.read(currentOrgProvider);
    // At launch the sign-in, then the workspaces, load first: a request held overnight waits for
    // them (up to 15 seconds) rather than failing.
    for (var i = 0; org == null && i < 75; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!_ref.mounted) return null;
      org = _ref.read(currentOrgProvider);
    }
    return org == null ? null : (id: org.id, name: org.name);
  }

  /// The name the watch greets with ("Signed in as Oliver"): what bots call the person.
  Future<String> _personName() async {
    try {
      final name =
          (await _ref
                  .read(aboutYouProvider.future)
                  .timeout(const Duration(seconds: 5)))
              .name;
      return name.length > 80 ? name.substring(0, 80) : name;
    } catch (_) {
      return '';
    }
  }

  /// The phone switched to [orgId]: each watch it signed in follows, its fingerprint registered
  /// for the new workspace, and the watches are told (§2 `context`).
  Future<void> workspaceChanged(String orgId) =>
      _queue = _queue.then((_) => _moveTo(orgId)).catchError((Object e) {
        debugPrint('watch workspace move failed: $e');
      });

  Future<void> _moveTo(String orgId) async {
    if (!_signedIn || !_ref.mounted) return;
    final backend = _ref.read(backendProvider);
    final userId = backend.userId;
    final records = await WatchKeyStore.load();
    if (!records.any((r) => r.userId == userId && r.orgId != orgId)) return;
    final org = await _currentOrg();
    if (org == null || org.id != orgId || !_ref.mounted) return;
    var moved = false;
    final next = <WatchRecord>[];
    for (final r in records) {
      if (r.userId != userId || r.orgId == orgId) {
        next.add(r);
        continue;
      }
      try {
        final key = await backend.registerWatchKey(
          orgId: orgId,
          fingerprint: r.fingerprint,
          platform: r.platform,
          name: r.name,
          model: r.model,
          appVersion: r.appVersion,
          osVersion: r.osVersion,
        );
        // A server that keeps a key per workspace gives a new id: the old one goes, so the watch
        // is in one workspace at a time, as the phone is.
        if (key.id != r.keyId) {
          try {
            await backend.deleteWatchKey(r.keyId);
          } catch (_) {}
        }
        next.add(r.copyWith(keyId: key.id, orgId: orgId));
        moved = true;
      } catch (e) {
        debugPrint('watch re-register failed: $e');
        next.add(r);
      }
    }
    await WatchKeyStore.save(next);
    if (!moved || !_ref.mounted) return;
    _ref.invalidate(watchKeysProvider);
    await _invoke<void>('setContext', await _context(org));
  }

  /// The phone signed out: the watches it signed in are removed on the server (best effort; the
  /// backend's sign-out already tried while the session worked) and told to sign out.
  Future<void> signedOut() =>
      _queue = _queue.then((_) => _signOut()).catchError((Object e) {
        debugPrint('watch sign-out failed: $e');
      });

  Future<void> _signOut() async {
    final records = await WatchKeyStore.load();
    if (records.isEmpty) return;
    await WatchKeyStore.clear();
    final backend = _ref.read(backendProvider);
    for (final r in records) {
      try {
        await backend
            .deleteWatchKey(r.keyId)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    await _invoke<void>('signOut', const <String, Object?>{});
  }

  /// Whether a watch is paired and has Casama, for the one nudge (§6.10). Null when native code
  /// can't say.
  Future<WatchStatus?> status() async {
    final s = await _invoke<Map<Object?, Object?>>('status');
    if (s == null) return null;
    return WatchStatus(
      supported: s['supported'] == true,
      paired: s['paired'] == true,
      installed: s['installed'] == true,
    );
  }

  Future<T?> _invoke<T>(String method, [Object? args]) async {
    if (!_native) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      _native = false;
    } catch (e) {
      debugPrint('watch $method failed: $e');
    }
    return null;
  }

  static AppLocalizations _l10n() => lookupAppLocalizations(
    basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    ),
  );
}

/// The bridge, on iPhone and Android; null elsewhere. Watched by the app root.
final watchBridgeProvider = Provider<WatchBridge?>((ref) {
  if (!ref.watch(watchBridgeSupportedProvider)) return null;
  final bridge = WatchBridge(ref, ref.watch(watchChannelProvider))..start();
  ref.onDispose(bridge.dispose);
  ref.listen(signedInProvider, (_, next) {
    if (next.value == false) {
      unawaited(bridge.signedOut());
    } else if (next.value == true) {
      unawaited(bridge.takeRequests());
    }
  }, fireImmediately: true);
  ref.listen(currentOrgIdProvider, (prev, next) {
    if (next != null && next != prev) unawaited(bridge.workspaceChanged(next));
  }, fireImmediately: true);
  final lifecycle = AppLifecycleListener(
    onResume: () => unawaited(bridge.takeRequests()),
  );
  ref.onDispose(lifecycle.dispose);
  unawaited(bridge.takeRequests());
  return bridge;
});

/// The app lock's question, once the app is unlocked and on screen.
Future<bool> _askOnScreen(Ref ref, String watchName) async {
  // A request can arrive with the lock screen up: the question waits until it's gone.
  for (
    var i = 0;
    i < 600 && ref.mounted && ref.read(appLockProvider).locked;
    i++
  ) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  BuildContext? context;
  for (var i = 0; i < 20 && ref.mounted; i++) {
    context = ref
        .read(routerProvider)
        .routerDelegate
        .navigatorKey
        .currentContext;
    if (context != null && !ref.read(appLockProvider).locked) break;
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  if (context == null || !context.mounted) return false;
  final l10n = context.l10n;
  return showConfirm(
    context: context,
    title: l10n.watchPhoneLockAsk,
    message: watchName,
    confirmLabel: l10n.watchPhoneCodeAllow,
    confirmKey: const Key('watchLockAllow'),
  );
}

void _noticeOnScreen(Ref ref, String message) {
  final context = ref
      .read(routerProvider)
      .routerDelegate
      .navigatorKey
      .currentContext;
  if (context == null ||
      !context.mounted ||
      ScaffoldMessenger.maybeOf(context) == null) {
    return;
  }
  showSuccess(context, message);
}
