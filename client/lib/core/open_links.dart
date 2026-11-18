import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router.dart';

/// Links in emails and invites (D-326) point at `https://casama.ai/open/<route>`. With the app
/// installed, iOS, Android and the Mac App Store build open it here; elsewhere casama.ai sends the
/// browser to the web app at `<route>` (or, on a Mac, offers `casama://app/<route>`). The route is
/// the rest of the path, with the query and fragment kept. Null when [uri] isn't such a link.
String? openLinkTarget(Uri uri) {
  final path = uri.path;
  if (path != '/open' && !path.startsWith('/open/')) return null;
  // One leading slash, so `/open//x` can't become a `//x` location.
  var rest = path.substring('/open'.length).replaceFirst(RegExp(r'^/+'), '/');
  if (rest.isEmpty || rest == '/') rest = '/bots';
  if (rest.length > 1 && rest.endsWith('/')) {
    rest = rest.substring(0, rest.length - 1);
  }
  return [
    rest,
    if (uri.hasQuery) '?${uri.query}',
    if (uri.hasFragment && uri.fragment.isNotEmpty) '#${uri.fragment}',
  ].join();
}

/// Where a link the operating system hands the Mac app goes, or null to leave it alone.
/// iOS and Android route links to the router themselves; macOS doesn't, so app_links passes them.
/// `casama://app/<route>` opens `<route>`; a casama.ai link opens its path (the router reads
/// `/open/…` with [openLinkTarget]). Sign-in returns (`login-callback`) belong to Supabase, and
/// `casama://pair…` to the sign-in code reader.
String? macLinkLocation(Uri uri) {
  String path;
  if (uri.scheme == 'casama' && uri.host == 'app') {
    path = uri.path.isEmpty ? '/' : uri.path;
  } else if (uri.scheme == 'https' &&
      (uri.host == 'casama.ai' || uri.host == 'www.casama.ai')) {
    path = uri.path;
    final handled =
        path == '/open' ||
        path.startsWith('/open/') ||
        path.startsWith('/gallery/') ||
        path.startsWith('/i/') ||
        path == '/pair';
    if (!handled) return null;
  } else {
    return null;
  }
  if (path == '/login-callback' || path.startsWith('/login-callback/')) {
    return null;
  }
  if (path == '/') path = '/bots';
  return [
    path,
    if (uri.hasQuery) '?${uri.query}',
    if (uri.hasFragment && uri.fragment.isNotEmpty) '#${uri.fragment}',
  ].join();
}

/// Where a link opened while signed out was going (D-326), so signing in ends there instead of
/// at the bots. Kept on the device, since signing in can reload the web app (Google, a sign-in
/// email) or restart the phone app, and only for a while, so a sign-in much later doesn't land
/// somewhere long forgotten.
class PendingOpenLink extends Notifier<String?> {
  static const _key = 'casama.pending_open';
  static const keepFor = Duration(minutes: 30);

  /// Read during startup (see [preload]) so the first redirect after a reload already has it.
  static ({String location, DateTime at})? _preloaded;

  static Future<void> preload() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      _preloaded = _decode(raw);
    } catch (_) {}
  }

  static ({String location, DateTime at})? _decode(String? raw) {
    if (raw == null) return null;
    final tab = raw.indexOf('\t');
    if (tab <= 0) return null;
    final ms = int.tryParse(raw.substring(0, tab));
    if (ms == null) return null;
    return (
      location: raw.substring(tab + 1),
      at: DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }

  DateTime? _at;
  bool _reached = false;

  @override
  String? build() {
    final saved = _preloaded;
    if (saved == null) return null;
    _at = saved.at;
    return saved.location;
  }

  void set(String? location) {
    final at = location == null ? null : DateTime.now();
    _at = at;
    _reached = false;
    _preloaded = location == null ? null : (location: location, at: at!);
    state = location;
    SharedPreferences.getInstance()
        .then(
          (p) => location == null
              ? p.remove(_key)
              : p.setString(_key, '${at!.millisecondsSinceEpoch}\t$location'),
        )
        .catchError((_) => false);
  }

  /// The location, while it is recent enough to still be wanted, or once the app has reached it.
  String? get fresh {
    final at = _at;
    if (state == null || at == null) return null;
    if (_reached || DateTime.now().difference(at) <= keepFor) return state;
    return null;
  }

  /// The app has landed on [location]: the link once it is there, forgotten once it moves on.
  void landedOn(String location) {
    if (state == null) return;
    if (location == state) {
      _reached = true;
    } else if (_reached) {
      set(null);
    }
  }
}

final pendingOpenLinkProvider = NotifierProvider<PendingOpenLink, String?>(
  PendingOpenLink.new,
);

/// Signed-out places that aren't somewhere to come back to after signing in.
bool keepThroughSignIn(String location) {
  final path = Uri.tryParse(location)?.path ?? location;
  return !const {
    '/',
    '/bots',
    '/sign-in',
    '/login-callback',
    '/two-step',
    '/new-password',
    '/welcome',
    '/onboarding',
    '/link',
    '/setup',
  }.contains(path);
}

bool get _isMac => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// Opens the links macOS hands the app (a casama:// link, or a casama.ai link in the App Store
/// build). The stream starts with the link that launched the app, if any. Watched by the app root.
final macOpenLinksProvider = Provider<void>((ref) {
  if (!_isMac) return;
  final router = ref.read(routerProvider);
  final sub = AppLinks().uriLinkStream.listen((uri) {
    final location = macLinkLocation(uri);
    if (location != null) router.go(location);
  }, onError: (_) {});
  ref.onDispose(() => unawaited(sub.cancel()));
});
