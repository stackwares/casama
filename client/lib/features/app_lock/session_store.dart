import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The keychain the app lock uses (D-375). On iPhone, items stay readable after the first unlock
/// since a restart, so a background wake (a geofence, a push) still finds the sign-in.
const appSecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

/// Where the Supabase sign-in is kept (D-375). Normally in the app's preferences, as
/// supabase_flutter does by default; while the app lock is on, in the system keychain (Keychain on
/// Apple platforms, the Keystore on Android, a DPAPI-encrypted file on Windows, libsecret on Linux),
/// so it isn't in a plain file. If the keychain fails, it falls back to the preferences rather
/// than signing the person out. The web keeps the browser's storage.
class AuthSessionStore extends LocalStorage {
  AuthSessionStore._(this._key, this._prefs);

  /// The app's one store, once [create] made it (null on the web and in tests).
  static AuthSessionStore? instance;

  static const _keychainPref = 'casama.appLock.keychainSession';

  /// supabase_flutter's own key, so a session saved before this store existed is found.
  static String keyFor(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  /// The store for [supabaseUrl]: the plain one on the web.
  static LocalStorage create(String supabaseUrl) {
    final key = keyFor(supabaseUrl);
    final prefs = SharedPreferencesLocalStorage(persistSessionKey: key);
    if (kIsWeb) return prefs;
    return instance = AuthSessionStore._(key, prefs);
  }

  final String _key;
  final SharedPreferencesLocalStorage _prefs;
  var _keychain = false;
  var _ready = false;

  @override
  Future<void> initialize() async {
    if (_ready) return;
    await _prefs.initialize();
    try {
      _keychain =
          (await SharedPreferences.getInstance()).getBool(_keychainPref) ??
          false;
    } catch (_) {}
    _ready = true;
  }

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() async {
    if (_keychain) {
      try {
        final saved = await appSecureStorage.read(key: _key);
        if (saved != null) return saved;
      } catch (_) {}
    }
    return _prefs.accessToken();
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (_keychain) {
      try {
        await appSecureStorage.write(key: _key, value: persistSessionString);
        await _prefs.removePersistedSession();
        return;
      } catch (_) {}
    }
    await _prefs.persistSession(persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await appSecureStorage.delete(key: _key);
    } catch (_) {}
    await _prefs.removePersistedSession();
  }

  /// Moves the saved sign-in into the keychain ([on]) or back to the preferences.
  Future<void> useKeychain(bool on) async {
    await initialize();
    if (on == _keychain) return;
    final current = await accessToken();
    _keychain = on;
    try {
      await (await SharedPreferences.getInstance()).setBool(_keychainPref, on);
    } catch (_) {}
    if (current != null) await persistSession(current);
    if (!on) {
      try {
        await appSecureStorage.delete(key: _key);
      } catch (_) {}
    }
  }
}
