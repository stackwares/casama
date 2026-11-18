import 'dart:convert';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The server's public settings (Supabase address, defaults, feature switches), saved per server
/// so the app starts from them without waiting on the network, or with no network at all, and
/// refreshes them in the background (D-158). Public data: kept across sign-outs.
abstract final class ServerConfigCache {
  static String _key(String apiUrl) => 'casama.server_config.$apiUrl';

  /// The settings saved for [apiUrl], or null (never saved, unreadable, or from an older app).
  static Future<PublicConfig?> read(String apiUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      final saved = prefs.getString(_key(apiUrl));
      return saved == null ? null : PublicConfig.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String apiUrl, PublicConfig config) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key(apiUrl), jsonEncode(config.toJson()));
    } catch (_) {}
  }

  /// Whether the server now uses another Supabase project than [saved] (a running app can't
  /// switch over; it reconnects).
  static bool moved(PublicConfig saved, PublicConfig fresh) => saved.supabaseUrl != fresh.supabaseUrl || saved.supabaseAnonKey != fresh.supabaseAnonKey;
}
