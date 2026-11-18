/// MCP OAuth for local MCP servers (D-363): discovery, self-registration, PKCE sign-in and refresh.
///
/// Workspace connections sign in on the Casama server (D-089), which can't reach a server on
/// someone's 127.0.0.1 or home network. Local servers sign in on the computer itself: the desktop
/// app runs [McpOAuth.signInUrl] / [McpOAuth.finishSignIn] around a browser sign-in, and the bridge
/// refreshes with [McpOAuth.refresh]. Tokens never leave the computer.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

typedef JsonMap = Map<String, dynamic>;

class McpOAuthError implements Exception {
  McpOAuthError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// What a server publishes about signing in (RFC 9728 + RFC 8414).
class McpOAuthMetadata {
  McpOAuthMetadata({
    required this.resource,
    required this.issuer,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.registrationEndpoint,
    this.scopes = const [],
  });

  final String resource;
  final String issuer;
  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;
  final Uri? registrationEndpoint;
  final List<String> scopes;
}

/// A signed-in local server's tokens and the client they belong to. Kept with the server's other
/// secrets on the computer.
class McpOAuthCredentials {
  McpOAuthCredentials({
    required this.tokenEndpoint,
    required this.clientId,
    required this.accessToken,
    this.clientSecret,
    this.refreshToken,
    this.expiresAt,
    this.scopes = const [],
    this.resource,
  });

  factory McpOAuthCredentials.fromJson(JsonMap j) => McpOAuthCredentials(
    tokenEndpoint: Uri.parse(j['token_endpoint'] as String),
    clientId: j['client_id'] as String,
    clientSecret: j['client_secret'] as String?,
    accessToken: j['access_token'] as String,
    refreshToken: j['refresh_token'] as String?,
    expiresAt: j['expires_at'] is String
        ? DateTime.tryParse(j['expires_at'] as String)
        : null,
    scopes: [for (final s in (j['scopes'] as List? ?? const [])) '$s'],
    resource: j['resource'] as String?,
  );

  final Uri tokenEndpoint;
  final String clientId;
  final String? clientSecret;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final List<String> scopes;
  final String? resource;

  /// True when the token is past (or within [margin] of) its expiry.
  bool expiring([Duration margin = const Duration(seconds: 60)]) =>
      expiresAt != null &&
      DateTime.now().toUtc().add(margin).isAfter(expiresAt!);

  JsonMap toJson() => {
    'token_endpoint': tokenEndpoint.toString(),
    'client_id': clientId,
    'client_secret': ?clientSecret,
    'access_token': accessToken,
    'refresh_token': ?refreshToken,
    'expires_at': ?expiresAt?.toUtc().toIso8601String(),
    'scopes': scopes,
    'resource': ?resource,
  };
}

/// A sign-in in progress: open [url] in the browser, then pass the callback's query to
/// [McpOAuth.finishSignIn].
class McpOAuthStart {
  McpOAuthStart({
    required this.url,
    required this.state,
    required this.verifier,
    required this.clientId,
    this.clientSecret,
    required this.redirectUri,
    required this.metadata,
    required this.scopes,
  });
  final Uri url;
  final String state;
  final String verifier;
  final String clientId;
  final String? clientSecret;
  final String redirectUri;
  final McpOAuthMetadata metadata;
  final List<String> scopes;
}

const _loopbackHosts = {'127.0.0.1', 'localhost', '::1', '[::1]'};

/// True when [a] and [b] name the same machine: the same host, or both this computer.
bool sameHost(Uri a, Uri b) {
  final ha = a.host.toLowerCase(), hb = b.host.toLowerCase();
  if (ha == hb) return true;
  return _loopbackHosts.contains(ha) && _loopbackHosts.contains(hb);
}

String _random([int bytes = 32]) {
  final r = Random.secure();
  return base64Url
      .encode(List<int>.generate(bytes, (_) => r.nextInt(256)))
      .replaceAll('=', '');
}

/// The PKCE S256 challenge for [verifier].
String pkceChallenge(String verifier) => base64Url
    .encode(sha256.convert(ascii.encode(verifier)).bytes)
    .replaceAll('=', '');

class McpOAuth {
  McpOAuth({HttpClient? client, this.timeout = const Duration(seconds: 15)})
    : _http = client ?? HttpClient();

  final HttpClient _http;
  final Duration timeout;

  void close() => _http.close(force: true);

  Future<(int, JsonMap?, HttpHeaders)> _get(Uri url) async {
    final req = await _http.getUrl(url).timeout(timeout);
    req.headers.set('accept', 'application/json');
    final res = await req.close().timeout(timeout);
    final text = await res.transform(utf8.decoder).join().timeout(timeout);
    JsonMap? body;
    try {
      final v = jsonDecode(text);
      if (v is Map) body = v.cast<String, dynamic>();
    } catch (_) {}
    return (res.statusCode, body, res.headers);
  }

  Future<(int, JsonMap?)> _post(
    Uri url, {
    Map<String, String>? form,
    JsonMap? json,
  }) async {
    final req = await _http.postUrl(url).timeout(timeout);
    req.headers.set('accept', 'application/json');
    if (form != null) {
      req.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      req.write(Uri(queryParameters: form).query);
    } else {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(json));
    }
    final res = await req.close().timeout(timeout);
    final text = await res.transform(utf8.decoder).join().timeout(timeout);
    JsonMap? body;
    try {
      final v = jsonDecode(text);
      if (v is Map) body = v.cast<String, dynamic>();
    } catch (_) {}
    return (res.statusCode, body);
  }

  /// Whether [mcpUrl] asks for an OAuth sign-in: it refuses an unsigned initialize with 401 and a
  /// Bearer challenge. Returns the protected-resource metadata address when it names one.
  Future<({bool needsSignIn, Uri? resourceMetadata})> probe(
    Uri mcpUrl, {
    Map<String, String> headers = const {},
  }) async {
    final req = await _http.postUrl(mcpUrl).timeout(timeout);
    req.headers
      ..set('content-type', 'application/json')
      ..set('accept', 'application/json, text/event-stream');
    headers.forEach(req.headers.set);
    req.write(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 'casama-probe',
        'method': 'initialize',
        'params': {
          'protocolVersion': '2025-06-18',
          'capabilities': <String, dynamic>{},
          'clientInfo': {'name': 'casama-companion', 'version': '1'},
        },
      }),
    );
    final res = await req.close().timeout(timeout);
    await res.drain<void>().timeout(timeout, onTimeout: () {});
    if (res.statusCode != 401) {
      return (needsSignIn: false, resourceMetadata: null);
    }
    return (
      needsSignIn: true,
      resourceMetadata: resourceMetadataFrom(
        res.headers.value('www-authenticate'),
        mcpUrl,
      ),
    );
  }

  /// The `resource_metadata` address in a `WWW-Authenticate: Bearer …` header, resolved against [base].
  static Uri? resourceMetadataFrom(String? header, Uri base) {
    if (header == null) return null;
    final m =
        RegExp(r'resource_metadata="([^"]+)"').firstMatch(header) ??
        RegExp(r'resource_metadata=([^,\s]+)').firstMatch(header);
    return m == null ? null : base.resolve(m.group(1)!);
  }

  /// Finds how to sign in to [mcpUrl]. The sign-in must be on the same machine as the server: a
  /// local server that sends the browser somewhere else is refused.
  Future<McpOAuthMetadata> discover(Uri mcpUrl, {Uri? resourceMetadata}) async {
    final origin = mcpUrl.replace(path: '', query: null, fragment: null);
    final path = mcpUrl.path == '/' ? '' : mcpUrl.path;
    JsonMap? prm;
    for (final u in [
      ?resourceMetadata,
      origin.replace(path: '/.well-known/oauth-protected-resource$path'),
      origin.replace(path: '/.well-known/oauth-protected-resource'),
    ]) {
      final (status, body, _) = await _get(u);
      if (status == 200 && body != null) {
        prm = body;
        break;
      }
    }
    final servers = [
      for (final s in (prm?['authorization_servers'] as List? ?? const []))
        '$s',
    ];
    final issuer = servers.isNotEmpty ? Uri.parse(servers.first) : origin;
    if (!sameHost(issuer, mcpUrl)) {
      throw McpOAuthError(
        'This server sends sign-ins to ${issuer.host}, not to ${mcpUrl.host}. Casama only signs in to local servers on their own machine.',
      );
    }
    final ipath = issuer.path == '/' ? '' : issuer.path;
    final iorigin = issuer.replace(path: '', query: null, fragment: null);
    JsonMap? as;
    for (final u in [
      iorigin.replace(path: '/.well-known/oauth-authorization-server$ipath'),
      if (ipath.isNotEmpty)
        iorigin.replace(path: '/.well-known/openid-configuration$ipath'),
      iorigin.replace(path: '$ipath/.well-known/openid-configuration'),
      if (ipath.isNotEmpty)
        iorigin.replace(path: '/.well-known/oauth-authorization-server'),
    ]) {
      final (status, body, _) = await _get(u);
      if (status == 200 &&
          body != null &&
          body['authorization_endpoint'] is String &&
          body['token_endpoint'] is String) {
        as = body;
        break;
      }
    }
    if (as == null) {
      throw McpOAuthError(
        '${mcpUrl.host} asks for a sign-in but publishes no way to sign in (no OAuth metadata).',
      );
    }
    final authorize = Uri.parse(as['authorization_endpoint'] as String);
    final token = Uri.parse(as['token_endpoint'] as String);
    final reg = as['registration_endpoint'] is String
        ? Uri.parse(as['registration_endpoint'] as String)
        : null;
    for (final u in [authorize, token, ?reg]) {
      if (!sameHost(u, mcpUrl)) {
        throw McpOAuthError(
          'This server signs in at ${u.host}, not at ${mcpUrl.host}. Casama only signs in to local servers on their own machine.',
        );
      }
    }
    final methods = [
      for (final m
          in (as['code_challenge_methods_supported'] as List? ??
              const ['S256']))
        '$m',
    ];
    if (!methods.contains('S256')) {
      throw McpOAuthError(
        '${mcpUrl.host} does not support PKCE (S256), so Casama cannot sign in safely.',
      );
    }
    final scopes = [
      for (final s
          in (prm?['scopes_supported'] as List? ??
              as['scopes_supported'] as List? ??
              const []))
        '$s',
    ];
    return McpOAuthMetadata(
      resource: (prm?['resource'] as String?) ?? mcpUrl.toString(),
      issuer: (as['issuer'] as String?) ?? issuer.toString(),
      authorizationEndpoint: authorize,
      tokenEndpoint: token,
      registrationEndpoint: reg,
      scopes: scopes,
    );
  }

  /// Registers Casama as a client (RFC 7591) for [redirectUri]. Each sign-in registers again: the
  /// redirect's port changes every time.
  Future<(String, String?)> register(
    McpOAuthMetadata meta,
    String redirectUri, {
    String clientName = 'Casama',
  }) async {
    final reg = meta.registrationEndpoint;
    if (reg == null) {
      throw McpOAuthError(
        'This server does not let apps register themselves, so Casama cannot sign in to it. Use a token instead.',
      );
    }
    final (status, body) = await _post(
      reg,
      json: {
        'client_name': clientName,
        'redirect_uris': [redirectUri],
        'grant_types': ['authorization_code', 'refresh_token'],
        'response_types': ['code'],
        'token_endpoint_auth_method': 'none',
        if (meta.scopes.isNotEmpty) 'scope': meta.scopes.join(' '),
      },
    );
    final id = body?['client_id'];
    if (status >= 300 || id is! String) {
      throw McpOAuthError(
        'Registering with the server failed (${body?['error_description'] ?? body?['error'] ?? 'HTTP $status'}).',
      );
    }
    return (id, body?['client_secret'] as String?);
  }

  /// Discovers, registers and builds the browser address for a sign-in to [mcpUrl].
  Future<McpOAuthStart> signInUrl(
    Uri mcpUrl, {
    required String redirectUri,
    String clientName = 'Casama',
    List<String>? scopes,
    Uri? resourceMetadata,
  }) async {
    final meta = await discover(mcpUrl, resourceMetadata: resourceMetadata);
    final (clientId, secret) = await register(
      meta,
      redirectUri,
      clientName: clientName,
    );
    final verifier = _random(48);
    final state = _random(24);
    final want = scopes ?? meta.scopes;
    final url = meta.authorizationEndpoint.replace(
      queryParameters: {
        ...meta.authorizationEndpoint.queryParameters,
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'state': state,
        'code_challenge': pkceChallenge(verifier),
        'code_challenge_method': 'S256',
        'resource': meta.resource,
        if (want.isNotEmpty) 'scope': want.join(' '),
      },
    );
    return McpOAuthStart(
      url: url,
      state: state,
      verifier: verifier,
      clientId: clientId,
      clientSecret: secret,
      redirectUri: redirectUri,
      metadata: meta,
      scopes: want,
    );
  }

  /// Swaps the browser's code for tokens. [query] is the callback's query.
  Future<McpOAuthCredentials> finishSignIn(
    McpOAuthStart start,
    Map<String, String> query,
  ) async {
    if (query['error'] != null) {
      throw McpOAuthError(
        query['error_description'] ??
            (query['error'] == 'access_denied'
                ? 'The sign-in was declined.'
                : 'The sign-in failed (${query['error']}).'),
      );
    }
    if (query['state'] != start.state) {
      throw McpOAuthError(
        'The sign-in came back for a different request. Try again.',
      );
    }
    final iss = query['iss'];
    if (iss != null && iss != start.metadata.issuer) {
      throw McpOAuthError(
        'The sign-in came back from a different server. Try again.',
      );
    }
    final code = query['code'];
    if (code == null || code.isEmpty) {
      throw McpOAuthError('The sign-in came back without a code.');
    }
    final (status, body) = await _post(
      start.metadata.tokenEndpoint,
      form: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': start.redirectUri,
        'client_id': start.clientId,
        'client_secret': ?start.clientSecret,
        'code_verifier': start.verifier,
        'resource': start.metadata.resource,
      },
    );
    return _credentials(
      status,
      body,
      tokenEndpoint: start.metadata.tokenEndpoint,
      clientId: start.clientId,
      clientSecret: start.clientSecret,
      scopes: start.scopes,
      resource: start.metadata.resource,
    );
  }

  /// New tokens from the refresh token. Throws [McpOAuthError] when the server refuses it (the
  /// person has to sign in again).
  Future<McpOAuthCredentials> refresh(McpOAuthCredentials creds) async {
    final rt = creds.refreshToken;
    if (rt == null) {
      throw McpOAuthError('The sign-in expired and cannot be renewed.');
    }
    final (status, body) = await _post(
      creds.tokenEndpoint,
      form: {
        'grant_type': 'refresh_token',
        'refresh_token': rt,
        'client_id': creds.clientId,
        'client_secret': ?creds.clientSecret,
        'resource': ?creds.resource,
      },
    );
    final next = _credentials(
      status,
      body,
      tokenEndpoint: creds.tokenEndpoint,
      clientId: creds.clientId,
      clientSecret: creds.clientSecret,
      scopes: creds.scopes,
      resource: creds.resource,
    );
    // Servers that don't rotate refresh tokens leave it out of the answer.
    return next.refreshToken != null
        ? next
        : McpOAuthCredentials(
            tokenEndpoint: next.tokenEndpoint,
            clientId: next.clientId,
            clientSecret: next.clientSecret,
            accessToken: next.accessToken,
            refreshToken: rt,
            expiresAt: next.expiresAt,
            scopes: next.scopes,
            resource: next.resource,
          );
  }

  McpOAuthCredentials _credentials(
    int status,
    JsonMap? body, {
    required Uri tokenEndpoint,
    required String clientId,
    String? clientSecret,
    required List<String> scopes,
    String? resource,
  }) {
    final token = body?['access_token'];
    if (status >= 300 || token is! String) {
      throw McpOAuthError(
        'The server refused the sign-in (${body?['error_description'] ?? body?['error'] ?? 'HTTP $status'}).',
      );
    }
    final expiresIn = body?['expires_in'];
    final granted = body?['scope'] is String
        ? (body!['scope'] as String)
              .split(' ')
              .where((s) => s.isNotEmpty)
              .toList()
        : scopes;
    return McpOAuthCredentials(
      tokenEndpoint: tokenEndpoint,
      clientId: clientId,
      clientSecret: clientSecret,
      accessToken: token,
      refreshToken: body?['refresh_token'] as String?,
      expiresAt: expiresIn is num
          ? DateTime.now().toUtc().add(Duration(seconds: expiresIn.toInt()))
          : null,
      scopes: granted,
      resource: resource,
    );
  }
}
