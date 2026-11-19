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
///   os_version?, at?}`: a watch asks to be signed in.
/// - native → Dart `open {link}`: Open on phone, from the watch.
/// - Dart → native `takeRequests` (the requests native code holds, one per watch, until each is
///   answered; taking them doesn't clear them), `answer` (which does), `setContext` (another
///   workspace), `signOut`, `status`.
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

/// The newest request of a watch whose sign-in is under way.
class _Asking {
  _Asking(this.requestId, this.at);
  String requestId;

  /// When native code got it (epoch ms); null from a native side that doesn't say.
  int? at;
}

class WatchBridge {
  WatchBridge(this._ref, this._channel);

  final Ref _ref;
  final MethodChannel _channel;

  /// False once the channel turned out to have no native side (desktop, web, an older build).
  var _native = true;

  /// Requests being answered or answered already in this run of the app: native code passes the
  /// same one live and again from every `takeRequests` until it is answered.
  final _seen = <String>{};

  /// The sign-ins under way, by the watch's fingerprint.
  final _asking = <String, _Asking>{};

  /// Whatever writes the watches' records or their keys on the server runs one at a time:
  /// registering a watch, a workspace move, taking keys back. Interleaved, a move could lose a
  /// watch that was signed in meanwhile, or a key could be deleted just after it was registered
  /// again.
  Future<void> _queue = Future.value();

  Future<T> _serial<T>(Future<T> Function() task) {
    final run = _queue.then((_) => task());
    _queue = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

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
            // A bare "/" (an older watch app, a push with no link) isn't a page: the chats are.
            _ref.read(watchOpenProvider)(link == '/' ? '/bots' : link);
          } catch (e) {
            debugPrint('watch open failed: $e');
          }
        }
    }
    return null;
  }

  /// At launch, on resume and once someone is signed in: finishes taking back the keys a sign-out
  /// couldn't delete, moves the watches a workspace switch left behind (it failed offline, say),
  /// and answers the requests native code holds.
  Future<void> catchUp() async {
    await _serial(_retryRemovals).catchError((Object e) {
      debugPrint('watch key removal failed: $e');
    });
    final orgId = _ref.mounted ? _ref.read(currentOrgIdProvider) : null;
    if (orgId != null) await workspaceChanged(orgId);
    await takeRequests();
  }

  /// Answers the requests native code holds (a watch asked while Flutter wasn't running, or while
  /// nobody was signed in). Native code keeps each one until it is answered, so one that is being
  /// answered already is skipped here.
  Future<void> takeRequests() async {
    final held = await _invoke<List<Object?>>('takeRequests');
    for (final r in held ?? const []) {
      if (r is Map) await answerRequest(Map<String, Object?>.from(r));
    }
  }

  /// Signs a watch in and answers it. Never throws: a failure answers `reason: "error"`.
  ///
  /// With nobody signed in the request isn't answered at all: native code keeps holding it and it
  /// is taken again once someone is ([catchUp]), so a watch that asked first is still signed in.
  Future<void> answerRequest(Map<String, Object?> args) async {
    final requestId = args['request_id'];
    if (requestId is! String ||
        requestId.isEmpty ||
        _seen.contains(requestId) ||
        !_signedIn) {
      return;
    }
    _seen.add(requestId);
    final fingerprint = args['fingerprint'] is String
        ? args['fingerprint'] as String
        : null;
    final at = args['at'] is num ? (args['at'] as num).toInt() : null;
    if (fingerprint != null) {
      // A watch asks again with a new id on every Try again and every time its app opens. It
      // joins the sign-in already under way (one question on screen, one registration), and the
      // answer goes to its newest request.
      final asking = _asking[fingerprint];
      if (asking != null) {
        final was = asking.at;
        if (at == null || was == null || at >= was) {
          asking
            ..requestId = requestId
            ..at = at ?? was;
        }
        return;
      }
      _asking[fingerprint] = _Asking(requestId, at);
    }
    Map<String, Object?> answer;
    try {
      answer = await _signIn(args);
    } catch (e) {
      debugPrint('watch sign-in failed: $e');
      answer = const {'ok': false, 'reason': 'error'};
    }
    final newest = fingerprint == null
        ? null
        : _asking.remove(fingerprint)?.requestId;
    await _invoke<void>('answer', {
      'request_id': newest ?? requestId,
      // So native code can drop whatever it still holds for this watch.
      'fingerprint': ?fingerprint,
      ...answer,
    });
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
    if (await _currentOrg() == null || !_ref.mounted) return error;
    // With the app lock on, a watch never signs in without the person saying so (§10), and it
    // starts with general words only.
    if (_ref.read(appLockSettingsProvider).activeFor(userId) ||
        _ref.read(appLockRequiredByProvider) != null) {
      final yes = await _ref.read(watchLockAskProvider)(name);
      if (!_ref.mounted) return error;
      if (!yes) return const {'ok': false, 'reason': 'declined'};
      await _startPrivate(userId);
      if (!_ref.mounted) return error;
    }
    final org = await _serial(() async {
      // The question can wait under the lock screen for a while: who is signed in and which
      // workspace is selected are read now, not from before it.
      if (!_signedIn || backend.userId != userId) return null;
      final org = await _currentOrg();
      if (org == null || !_ref.mounted) return null;
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
      return org;
    });
    if (org == null || !_ref.mounted) return error;
    _invalidateLists();
    final context = await _context(org);
    try {
      _ref.read(watchNoticeProvider)(_l10n().watchPhoneSignedIn(name));
    } catch (_) {}
    return {'ok': true, ...context};
  }

  /// With the app lock on a watch starts with general words only (§10): Show details goes off on
  /// the server before the watch is signed in. Once per person on this device, and marked only
  /// once the server has taken it; after that the switch in Settings → Watch is theirs.
  Future<void> _startPrivate(String userId) async {
    try {
      if (await WatchDetailsSettled.check(userId)) return;
      await _ref
          .read(backendProvider)
          .updateWatchPrefs(showDetails: false)
          .timeout(const Duration(seconds: 10));
      await WatchDetailsSettled.mark(userId);
      if (_ref.mounted) _ref.invalidate(watchPrefsProvider);
    } catch (e) {
      debugPrint('watch details off failed: $e');
    }
  }

  /// The lists Settings → Watch shows, after the records or the server's keys changed.
  void _invalidateLists() {
    _ref.invalidate(watchKeysProvider);
    _ref.invalidate(watchesElsewhereProvider);
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
      _serial(() => _moveTo(orgId)).catchError((Object e) {
        debugPrint('watch workspace move failed: $e');
      });

  Future<void> _moveTo(String orgId) async {
    if (!_signedIn || !_ref.mounted) return;
    final backend = _ref.read(backendProvider);
    final userId = backend.userId;
    bool elsewhere(WatchRecord r) =>
        r.userId == userId && r.active && r.orgId != orgId;
    final saved = await WatchKeyStore.load();
    if (!saved.any(elsewhere)) return;
    final org = await _currentOrg();
    if (org == null || org.id != orgId || !_ref.mounted) return;
    // A watch removed somewhere else is never signed in again by a move: its record goes first.
    // One the server had already moved here (the answer never reached this phone) is taken as
    // moved, and told so like the others.
    final records = await _withoutGone(saved, userId, first: orgId);
    var moved = _cameTo(orgId, saved, records);
    final next = <WatchRecord>[];
    for (final r in records) {
      if (!elsewhere(r)) {
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
    if (!_ref.mounted) return;
    if (moved || next.length != saved.length) _invalidateLists();
    if (!moved) return;
    await _invoke<void>('setContext', await _context(org));
  }

  /// Whether [next] has a watch in [orgId] that [before] had in another workspace.
  static bool _cameTo(
    String orgId,
    List<WatchRecord> before,
    List<WatchRecord> next,
  ) {
    final was = {for (final r in before) r.fingerprint: r.orgId};
    return next.any((r) => r.orgId == orgId && was[r.fingerprint] != orgId);
  }

  /// [records] checked against the server, so a fingerprint the server dropped (the watch was
  /// removed on another device, or signed itself out) is never registered again by a move, and a
  /// watch the server still has is never forgotten.
  ///
  /// A record whose key isn't in its recorded workspace is looked for in the person's other
  /// workspaces, [first] before the rest: the server keeps one key per watch and moves it, so a
  /// move whose answer never reached this phone left the key there. Found, the record follows it.
  /// It is dropped only when every workspace answered and none has it. Whenever one couldn't be
  /// asked (offline, a server that can't say), or its own workspace was left, the record stays.
  Future<List<WatchRecord>> _withoutGone(
    List<WatchRecord> records,
    String? userId, {
    String? first,
  }) async {
    final orgs = _ref.read(organizationsProvider).value;
    if (orgs == null) return records;
    final mine = [
      for (final o in orgs)
        if (o.id == first) o.id,
      for (final o in orgs)
        if (o.id != first) o.id,
    ];
    final backend = _ref.read(backendProvider);
    // What each workspace answered: its key ids, or null when the person isn't in it any more.
    // One that couldn't be asked is in [unknown].
    final answered = <String, Set<String>?>{};
    final unknown = <String>{};
    Future<void> ask(String orgId) async {
      if (answered.containsKey(orgId) || unknown.contains(orgId)) return;
      try {
        answered[orgId] = await backend
            .watchKeyIdsIn(orgId)
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        unknown.add(orgId);
      }
    }

    final next = <WatchRecord>[];
    for (final r in records) {
      if (r.userId != userId || !r.active) {
        next.add(r);
        continue;
      }
      final listedHome = mine.contains(r.orgId);
      if (listedHome) await ask(r.orgId);
      if (unknown.contains(r.orgId) ||
          answered[r.orgId]?.contains(r.keyId) == true) {
        next.add(r);
        continue;
      }
      // Not where the record says (or that workspace was left): somewhere else, or gone.
      String? found;
      var everyoneAnswered = true;
      for (final o in mine) {
        if (o == r.orgId) continue;
        await ask(o);
        if (unknown.contains(o)) {
          everyoneAnswered = false;
        } else if (answered[o]?.contains(r.keyId) == true) {
          found = o;
          break;
        }
      }
      // Its own workspace gave no answer about it when the person has left it.
      final homeAnswered = listedHome && answered[r.orgId] != null;
      if (found != null) {
        next.add(r.copyWith(orgId: found));
      } else if (!everyoneAnswered || !homeAnswered) {
        next.add(r);
      }
    }
    return next;
  }

  /// Checks this phone's records against the server: forgets the watches it no longer has, and
  /// follows one it moved. Settings → Watch asks for it when it opens.
  Future<void> prune() =>
      _serial(() async {
        if (!_signedIn || !_ref.mounted) return;
        final records = await WatchKeyStore.load();
        if (records.isEmpty) return;
        final here = _ref.read(currentOrgProvider);
        final next = await _withoutGone(
          records,
          _ref.read(backendProvider).userId,
          first: here?.id,
        );
        // The check only drops records or changes their workspace, and keeps their order.
        var same = next.length == records.length;
        for (var i = 0; same && i < next.length; i++) {
          same = next[i].orgId == records[i].orgId;
        }
        if (same) return;
        await WatchKeyStore.save(next);
        if (!_ref.mounted) return;
        _invalidateLists();
        // A watch the server had moved to this workspace may not have heard: tell it.
        if (here != null && _cameTo(here.id, records, next)) {
          await _invoke<void>(
            'setContext',
            await _context((id: here.id, name: here.name)),
          );
        }
      }).catchError((Object e) {
        debugPrint('watch records check failed: $e');
      });

  /// A sign-out that couldn't delete a watch's key (the session had ended by itself, or the phone
  /// was offline) left its record waiting. The same account is signed in again: the key goes now.
  Future<void> _retryRemovals() async {
    if (!_signedIn || !_ref.mounted) return;
    final backend = _ref.read(backendProvider);
    final userId = backend.userId;
    bool waiting(WatchRecord r) =>
        r.userId == userId && r.removal == WatchRemoval.pending;
    final records = await WatchKeyStore.load();
    if (!records.any(waiting)) return;
    final next = <WatchRecord>[];
    for (final r in records) {
      if (!waiting(r)) {
        next.add(r);
        continue;
      }
      try {
        await backend
            .deleteWatchKey(r.keyId)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        next.add(r);
      }
    }
    await WatchKeyStore.save(next);
  }

  /// The phone signed out: the watches it signed in are told to sign out, always, whether or not
  /// their keys could be deleted. The backend's sign-out deleted the keys it could while the
  /// session worked and marked those records done ([WatchKeyStore.signingOut]). A key it couldn't
  /// delete (offline, a slow server), or any key when the session ended by itself, is still on
  /// record as signed in: it is kept, waiting, and deleted when the same account is signed in here
  /// again ([catchUp]), since there is no session to delete it with now.
  Future<void> signedOut() => _serial(_signOut).catchError((Object e) {
    debugPrint('watch sign-out failed: $e');
  });

  Future<void> _signOut() async {
    final records = await WatchKeyStore.load();
    if (records.isEmpty) return;
    // The watches signed in until now: the ones whose key just went (done) and the ones whose key
    // couldn't be deleted (still marked signed in). One already waiting from an earlier sign-out
    // was told then.
    final tell = records.any((r) => r.removal != WatchRemoval.pending);
    await WatchKeyStore.save([
      for (final r in records)
        if (r.removal != WatchRemoval.done)
          r.copyWith(removal: WatchRemoval.pending),
    ]);
    if (tell) await _invoke<void>('signOut', const <String, Object?>{});
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
      unawaited(bridge.catchUp());
    }
  }, fireImmediately: true);
  ref.listen(currentOrgIdProvider, (prev, next) {
    if (next != null && next != prev) unawaited(bridge.workspaceChanged(next));
  }, fireImmediately: true);
  final lifecycle = AppLifecycleListener(
    onResume: () => unawaited(bridge.catchUp()),
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
