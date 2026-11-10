import 'dart:convert';

import 'package:http/http.dart' as http;

/// A Supabase Auth session.
class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    this.email,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;
  final String? email;

  bool get isExpired => DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 60)));

  factory AuthSession.fromAuthResponse(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final expiresAt = json['expires_at'] is int
        ? DateTime.fromMillisecondsSinceEpoch((json['expires_at'] as int) * 1000)
        : DateTime.now().add(Duration(seconds: (json['expires_in'] as num?)?.toInt() ?? 3600));
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: expiresAt,
      userId: user['id'] as String? ?? '',
      email: user['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.millisecondsSinceEpoch ~/ 1000,
        'user': {'id': userId, 'email': email},
      };
}

class AuthException implements Exception {
  AuthException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'AuthException($statusCode): $message';
}

/// Minimal client for the Supabase Auth REST API (email and password, magic link, refresh).
class AuthClient {
  AuthClient({required this.supabaseUrl, required this.anonKey, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final String supabaseUrl;
  final String anonKey;
  final http.Client _http;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$supabaseUrl/auth/v1$path').replace(queryParameters: query);

  Map<String, String> get _headers => {
        'apikey': anonKey,
        'content-type': 'application/json',
      };

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {Map<String, String>? query}) async {
    final res = await _http.post(_uri(path, query), headers: _headers, body: jsonEncode(body));
    final decoded = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    if (res.statusCode >= 400) {
      final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      throw AuthException(
        (map['msg'] ?? map['error_description'] ?? map['message'] ?? 'Request failed').toString(),
        statusCode: res.statusCode,
      );
    }
    return decoded as Map<String, dynamic>;
  }

  /// Signs up. Returns a session when email confirmation is off, otherwise null.
  Future<AuthSession?> signUp({required String email, required String password}) async {
    final json = await _post('/signup', {'email': email, 'password': password});
    return json.containsKey('access_token') ? AuthSession.fromAuthResponse(json) : null;
  }

  Future<AuthSession> signInWithPassword({required String email, required String password}) async {
    final json = await _post('/token', {'email': email, 'password': password},
        query: {'grant_type': 'password'});
    return AuthSession.fromAuthResponse(json);
  }

  /// Sends a magic link email.
  Future<void> sendMagicLink({required String email, String? redirectTo}) async {
    await _post('/otp', {'email': email, 'create_user': true},
        query: redirectTo == null ? null : {'redirect_to': redirectTo});
  }

  /// Exchanges the one-time code from a magic link email for a session.
  Future<AuthSession> verifyEmailOtp({required String email, required String token}) async {
    final json = await _post('/verify', {'email': email, 'token': token, 'type': 'email'});
    return AuthSession.fromAuthResponse(json);
  }

  /// The account's verified authenticator apps (two-step sign-in), as factor ids.
  Future<List<String>> verifiedTotpFactors(String accessToken) async {
    final res = await _http.get(_uri('/user'), headers: {..._headers, 'authorization': 'Bearer $accessToken'});
    if (res.statusCode >= 400) throw AuthException('Could not read the account', statusCode: res.statusCode);
    final user = jsonDecode(res.body) as Map<String, dynamic>;
    final factors = (user['factors'] as List?) ?? const [];
    return [
      for (final f in factors.cast<Map<String, dynamic>>())
        if (f['factor_type'] == 'totp' && f['status'] == 'verified') f['id'] as String,
    ];
  }

  /// Passes the second step with a code from an authenticator app; returns the upgraded (aal2) session.
  Future<AuthSession> verifyTotp({required String accessToken, required String factorId, required String code}) async {
    final auth = {..._headers, 'authorization': 'Bearer $accessToken'};
    Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
      final res = await _http.post(_uri(path), headers: auth, body: jsonEncode(body));
      final decoded = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) {
        throw AuthException((decoded['msg'] ?? decoded['message'] ?? 'Invalid code').toString(), statusCode: res.statusCode);
      }
      return decoded;
    }

    final challenge = await post('/factors/$factorId/challenge', {});
    final json = await post('/factors/$factorId/verify', {'challenge_id': challenge['id'], 'code': code});
    return AuthSession.fromAuthResponse(json);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final json = await _post('/token', {'refresh_token': refreshToken},
        query: {'grant_type': 'refresh_token'});
    return AuthSession.fromAuthResponse(json);
  }

  void close() => _http.close();
}
