import 'dart:convert';

import 'package:flutter/services.dart';

/// Where a bot may work in the phone browser (PROTOCOL.md §2, plan §8.5): decided here, in Dart,
/// before a page loads and again on the address it lands on.
///
/// A port of `appSiteDecision` (packages/domain/src/app-browser-sites.ts) and the helpers in
/// packages/domain/src/browser-guard.ts. test/app_browser_sites_test.dart checks it against every
/// case in test/fixtures/app_browser_sites.json, which the TypeScript writes; change both together.

/// The lists from `assets/app_browser/guard.json` (written by `pnpm --filter @casama/domain
/// gen:app-browser`): Casama's domains, the off-by-default kinds in the order they're checked, the
/// well-known hosts of each kind, and a pattern per kind for the words their hosts carry.
class AppBrowserGuard {
  AppBrowserGuard({
    required this.casama,
    required this.kinds,
    required this.hosts,
    required this.words,
  });

  factory AppBrowserGuard.fromJson(Map<String, dynamic> json) =>
      AppBrowserGuard(
        casama: [for (final d in json['casama'] as List) '$d'],
        kinds: [for (final k in json['kinds'] as List) '$k'],
        hosts: {
          for (final e in (json['hosts'] as Map).entries)
            '${e.key}': [for (final h in e.value as List) '$h'],
        },
        words: {
          for (final e in (json['words'] as Map? ?? const {}).entries)
            '${e.key}': RegExp('${e.value}'),
        },
      );

  static const asset = 'assets/app_browser/guard.json';

  /// Reads the lists shipped with the app.
  static Future<AppBrowserGuard> load([AssetBundle? bundle]) async =>
      AppBrowserGuard.fromJson(
        jsonDecode(await (bundle ?? rootBundle).loadString(asset))
            as Map<String, dynamic>,
      );

  final List<String> casama;
  final List<String> kinds;
  final Map<String, List<String>> hosts;
  final Map<String, RegExp> words;
}

/// The site rules a call carries (`policy` in PROTOCOL.md §1).
class AppSitePolicy {
  const AppSitePolicy({
    this.blockedSites = const [],
    this.allowedSites = const [],
    this.allowedKinds = const [],
    this.ownUrls = const [],
  });

  factory AppSitePolicy.fromJson(Map<String, dynamic>? json) {
    List<String> list(String key) => [
      for (final v in (json?[key] as List?) ?? const [])
        if (v != null) '$v',
    ];
    return AppSitePolicy(
      blockedSites: list('blocked_sites'),
      allowedSites: list('allowed_sites'),
      allowedKinds: list('allowed_kinds'),
      ownUrls: list('own_urls'),
    );
  }

  final List<String> blockedSites;
  final List<String> allowedSites;
  final List<String> allowedKinds;

  /// This server's own addresses (API, web app, sign-in), refused like Casama's domains.
  final List<String> ownUrls;

  /// This policy with the person's answers in this session added (an "always" or "never" saved on
  /// the device before the server's next call carries it).
  AppSitePolicy plus({
    Iterable<String> allowed = const [],
    Iterable<String> blocked = const [],
  }) => AppSitePolicy(
    blockedSites: [...blockedSites, ...blocked],
    allowedSites: [...allowedSites, ...allowed],
    allowedKinds: allowedKinds,
    ownUrls: ownUrls,
  );
}

/// What the gate decided for an address.
sealed class AppSiteDecision {
  const AppSiteDecision();
  Map<String, Object?> toJson();
}

class AppSiteAllowed extends AppSiteDecision {
  const AppSiteAllowed();
  @override
  Map<String, Object?> toJson() => {'kind': 'allowed'};
}

/// Ask the person: Once, Always or Never. [siteKind] is set for a kind switched back on, which
/// asks once per run.
class AppSiteAsk extends AppSiteDecision {
  const AppSiteAsk(this.host, {this.siteKind});
  final String host;
  final String? siteKind;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'ask',
    'host': host,
    'site_kind': ?siteKind,
  };
}

/// Never: [why] is `not_web`, `casama`, `blocked` or the off-by-default kind.
class AppSiteRefused extends AppSiteDecision {
  const AppSiteRefused(this.host, this.why);
  final String host;
  final String why;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'refused',
    'host': host,
    'why': why,
  };
}

/// The gate (PROTOCOL.md §2), in the order of `appSiteDecision`. [once]: sites answered "once" in
/// this run. [extra]: hosts the server added to the kinds without a release (`GET /v1/browser-guard`).
AppSiteDecision appSiteDecision(
  String url,
  AppSitePolicy policy,
  AppBrowserGuard guard, {
  List<String> once = const [],
  Map<String, List<String>> extra = const {},
}) {
  if (url == 'about:blank') return const AppSiteAllowed();
  final host = hostOf(url);
  if (host == null || host.isEmpty || !browsable(url)) {
    return AppSiteRefused(host ?? url, 'not_web');
  }
  if (isCasamaAddress(url, guard, policy.ownUrls)) {
    return AppSiteRefused(host, 'casama');
  }
  if (policy.blockedSites.any((p) => siteMatches(host, p))) {
    return AppSiteRefused(host, 'blocked');
  }
  final off = sensitiveSiteKind(
    host,
    guard,
    allowed: policy.allowedKinds,
    extra: extra,
  );
  if (off != null) return AppSiteRefused(host, off);
  // A kind switched back on still asks, once per run.
  final kind = sensitiveSiteKind(host, guard, extra: extra);
  if (kind != null && !once.any((p) => siteMatches(host, p))) {
    return AppSiteAsk(host, siteKind: kind);
  }
  if ([...policy.allowedSites, ...once].any((p) => siteMatches(host, p))) {
    return const AppSiteAllowed();
  }
  return AppSiteAsk(host);
}

/// The person's own browsing (Sign In to a Site): only the first two steps of the gate apply.
AppSiteDecision personSiteDecision(
  String url,
  AppBrowserGuard guard, {
  List<String> ownUrls = const [],
}) {
  if (url == 'about:blank') return const AppSiteAllowed();
  final host = hostOf(url);
  if (host == null || host.isEmpty || !browsable(url)) {
    return AppSiteRefused(host ?? url, 'not_web');
  }
  if (isCasamaAddress(url, guard, ownUrls)) {
    return AppSiteRefused(host, 'casama');
  }
  return const AppSiteAllowed();
}

bool _within(String host, String domain) =>
    host == domain || host.endsWith('.$domain');

/// The host of an address without a trailing dot or "www.", lowercased; empty for an address with
/// no host (`file:///x`, `javascript:`), null when it isn't an address at all.
String? hostOf(String url) {
  final u = _WebUrl.parse(url);
  if (u == null) return null;
  return u.hostname
      .toLowerCase()
      .replaceFirst(RegExp(r'\.$'), '')
      .replaceFirst(RegExp(r'^www\.'), '');
}

/// Addresses a browser tool may open at all: web pages only, never browser or extension pages.
bool browsable(String url) =>
    RegExp(r'^https?://', caseSensitive: false).hasMatch(url) &&
    !RegExp(
      r'^https?://(chrome\.google\.com/webstore|chromewebstore\.google\.com)',
      caseSensitive: false,
    ).hasMatch(url);

/// Whether [url] is one of Casama's own pages: a Casama domain, or one of this server's own
/// addresses ([ownUrls]), compared with the port.
bool isCasamaAddress(
  String url,
  AppBrowserGuard guard, [
  List<String?> ownUrls = const [],
]) {
  final host = hostOf(url);
  if (host == null || host.isEmpty) return false;
  if (guard.casama.any((d) => _within(host, d))) return true;
  final u = _WebUrl.parse(url);
  if (u == null) return false;
  final hostPort = _dropDotBeforePort(u.host.toLowerCase());
  for (final own in ownUrls) {
    if (own == null || own.isEmpty) continue;
    final o = _WebUrl.parse(own);
    if (o != null && o.host.toLowerCase() == hostPort) return true;
  }
  return false;
}

/// JavaScript's `.replace(/\.(?=:|$)/, "")`: the first dot right before the port or the end.
String _dropDotBeforePort(String s) {
  for (var i = 0; i < s.length; i++) {
    if (s[i] == '.' && (i + 1 == s.length || s[i + 1] == ':')) {
      return s.substring(0, i) + s.substring(i + 1);
    }
  }
  return s;
}

/// A site list entry matches a host: "example.com" matches it and its subdomains; "*.example.com"
/// only subdomains; a leading "www." is ignored.
bool siteMatches(String host, String pattern) {
  final p = pattern
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'/.*$'), '');
  if (p.isEmpty) return false;
  if (p.startsWith('*.')) return host.endsWith(p.substring(1));
  return _within(host, p.replaceFirst(RegExp(r'^www\.'), ''));
}

/// A site list entry as stored: a bare host or *.host, at most 253 characters; null when [raw]
/// isn't one.
String? cleanSitePattern(String raw) {
  final p = raw
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'[/?#].*$'), '')
      .replaceFirst(RegExp(r':\d+$'), '')
      .replaceFirst(RegExp(r'^www\.'), '');
  if (p.isEmpty || p.length > 253) return null;
  return RegExp(r'^(\*\.)?[a-z0-9-]+(\.[a-z0-9-]+)+$').hasMatch(p) ||
          p == 'localhost'
      ? p
      : null;
}

/// The off-by-default kind [host] belongs to, or null. [allowed]: kinds the person switched back
/// on. [extra]: hosts the server added; they only add to the lists in the app.
String? sensitiveSiteKind(
  String host,
  AppBrowserGuard guard, {
  List<String> allowed = const [],
  Map<String, List<String>> extra = const {},
}) {
  final h = host
      .toLowerCase()
      .replaceFirst(RegExp(r'\.$'), '')
      .replaceFirst(RegExp(r'^www\.'), '');
  for (final kind in guard.kinds) {
    if (allowed.contains(kind)) continue;
    if ((guard.hosts[kind] ?? const []).any((d) => _within(h, d)) ||
        (guard.words[kind]?.hasMatch(h) ?? false) ||
        (extra[kind] ?? const []).any((d) => _within(h, d))) {
      return kind;
    }
  }
  return null;
}

/// Just enough of the WHATWG URL parser for the gate: the scheme, the hostname and `host` (with a
/// port that isn't the scheme's default), so the answers match `new URL()` in the server's
/// reference. Null where `new URL()` throws.
class _WebUrl {
  _WebUrl(this.scheme, this.hostname, this.port);

  final String scheme;
  final String hostname;
  final int? port;

  static const _special = {
    'http': 80,
    'https': 443,
    'ws': 80,
    'wss': 443,
    'ftp': 21,
    'file': null,
  };
  static final _forbidden = RegExp(r'[\x00-\x20#%/:<>?@\[\\\]^|\x7f]');

  /// `URL.host`: the hostname, plus the port when it isn't the default.
  String get host => port == null ? hostname : '$hostname:$port';

  static _WebUrl? parse(String input) {
    final s = input
        .replaceAll(RegExp(r'^[\x00-\x20]+|[\x00-\x20]+$'), '')
        .replaceAll(RegExp('[\t\n\r]'), '');
    final m = RegExp(r'^([A-Za-z][A-Za-z0-9+.\-]*):').firstMatch(s);
    if (m == null) return null;
    final scheme = m.group(1)!.toLowerCase();
    var rest = s.substring(m.end);
    final special = _special.containsKey(scheme);
    if (special && scheme != 'file') {
      rest = rest.replaceFirst(RegExp(r'^[/\\]*'), '');
    } else {
      final slashes = special ? RegExp(r'^[/\\]{2}') : RegExp(r'^//');
      if (!slashes.hasMatch(rest)) return _WebUrl(scheme, '', null);
      rest = rest.substring(2);
    }
    final end = rest.indexOf(RegExp(special ? r'[/\\?#]' : r'[/?#]'));
    var authority = end < 0 ? rest : rest.substring(0, end);
    final at = authority.lastIndexOf('@');
    if (at >= 0) authority = authority.substring(at + 1);
    // The host ends at a colon outside [brackets].
    var hostPart = authority;
    String? portPart;
    var bracket = false;
    for (var i = 0; i < authority.length; i++) {
      final c = authority[i];
      if (c == '[') bracket = true;
      if (c == ']') bracket = false;
      if (c == ':' && !bracket) {
        hostPart = authority.substring(0, i);
        portPart = authority.substring(i + 1);
        break;
      }
    }
    int? port;
    if (portPart != null && portPart.isNotEmpty) {
      if (!RegExp(r'^\d+$').hasMatch(portPart)) return null;
      port = int.parse(portPart);
      if (port > 65535) return null;
    }
    if (special && port == _special[scheme]) port = null;
    if (hostPart.isEmpty) {
      if (special && scheme != 'file') return null;
      return _WebUrl(scheme, '', port);
    }
    if (!special) return _WebUrl(scheme, hostPart, port);
    if (hostPart.startsWith('[')) {
      return hostPart.endsWith(']')
          ? _WebUrl(scheme, hostPart.toLowerCase(), port)
          : null;
    }
    String decoded;
    try {
      decoded = Uri.decodeComponent(hostPart);
    } catch (_) {
      return null;
    }
    if (_forbidden.hasMatch(decoded)) return null;
    var hostname = decoded.toLowerCase();
    if (scheme == 'file' && hostname == 'localhost') hostname = '';
    return _WebUrl(scheme, hostname, port);
  }
}
