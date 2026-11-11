import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend.dart';
import '../../core/server_address.dart';
import '../../core/server_config_cache.dart';
import '../../core/supabase_backend.dart';

/// Device triggers (D-151): events this device reports (arrive and leave named places, watched-app
/// notifications), kept in a small queue until the server has them. Only place names travel, never
/// coordinates; one-time codes are masked here before anything leaves the device.

/// Masks one-time codes ("Your code is 482913") in notification text.
String maskCodes(String text) => text.replaceAllMapped(RegExp(r'\b(?=[A-Z0-9-]*\d)[A-Z0-9]{3,4}-?[A-Z0-9]{3,4}\b|\b\d{4,8}\b'), (_) => '••••');

class DeviceEventQueue {
  static const _pref = 'kasama.device_events';
  static const _keyPref = 'kasama.device_key';

  static Future<List<Map<String, Object?>>> pending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    try {
      return [for (final e in jsonDecode(prefs.getString(_pref) ?? '[]') as List) Map<String, Object?>.from(e as Map)];
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(Map<String, Object?> event) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await pending();
    list.add(event);
    // A long offline stretch keeps the newest 200.
    await prefs.setString(_pref, jsonEncode(list.length > 200 ? list.sublist(list.length - 200) : list));
  }

  /// Sends what's queued; keeps it on failure for the next try. Returns how many went.
  static Future<int> flush(Backend backend) async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyPref);
    final list = await pending();
    if (key == null || list.isEmpty) return 0;
    final events = [
      for (final e in list)
        DeviceEventInput(
          id: '${e['id']}',
          type: DeviceEventInputTypeEnum.values.firstWhere((t) => t.value == e['type']),
          at: DateTime.parse('${e['at']}'),
          place: e['place'] as String?,
          app: e['app'] as String?,
          title: e['title'] as String?,
          text: e['text'] as String?,
        ),
    ];
    for (var i = 0; i < events.length; i += 50) {
      await backend.reportDeviceEvents(key, events.sublist(i, i + 50 > events.length ? events.length : i + 50));
    }
    // Only drop what was sent (an event may have arrived meanwhile).
    final sent = {for (final e in list) e['id']};
    final now = await pending();
    await prefs.setString(
      _pref,
      jsonEncode([
        for (final e in now)
          if (!sent.contains(e['id'])) e,
      ]),
    );
    return events.length;
  }
}

/// A backend for work that runs without the app's UI (a geofence waking the app in the background).
Future<Backend?> backgroundBackend() async {
  try {
    final config = await ServerAddress.load();
    // The settings the app saved (D-158): a background wake may have little or no network.
    final server = await ServerConfigCache.read(config.apiUrl) ?? (await KasamaClient.connect(config.apiUrl)).config;
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(url: server.supabaseUrl, publishableKey: server.supabaseAnonKey);
    }
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentSession == null) return null;
    final api = await SupabaseBackend.connectApi(config.apiUrl, supabase, config: server);
    return SupabaseBackend(supabase, api, config: server);
  } catch (_) {
    return null;
  }
}

/// Geofences are named `"place:<name>"`; entering one is "arrive", leaving it "leave".
@visibleForTesting
Map<String, Object?>? geofenceEvent(String geofenceId, GeofenceEvent event, DateTime at) {
  if (!geofenceId.startsWith('place:')) return null;
  final type = switch (event) {
    GeofenceEvent.enter => 'arrive',
    GeofenceEvent.exit => 'leave',
    _ => null,
  };
  if (type == null) return null;
  final place = geofenceId.substring(6);
  return {'id': 'geo-$place-$type-${at.millisecondsSinceEpoch ~/ 60000}', 'type': type, 'at': at.toUtc().toIso8601String(), 'place': place};
}

/// Runs when the OS reports a geofence, even with the app closed.
@pragma('vm:entry-point')
Future<void> placeGeofenceTriggered(GeofenceCallbackParams params) async {
  final at = params.triggeredAt ?? DateTime.now();
  for (final g in params.geofences) {
    final e = geofenceEvent(g.id, params.event, at);
    if (e != null) await DeviceEventQueue.add(e);
  }
  // iOS gives a callback about a minute: send now if we can, else the app sends it when it next runs.
  final backend = await backgroundBackend().timeout(const Duration(seconds: 20), onTimeout: () => null);
  if (backend != null) await DeviceEventQueue.flush(backend).timeout(const Duration(seconds: 20)).catchError((_) => 0);
}

/// What device triggers need from the platform (a seam for tests).
abstract class DeviceTriggerPlatform {
  bool get supportsPlaces;
  bool get supportsNotifications;
  Future<bool> requestPlaces();
  Future<({double lat, double lng})?> currentLocation();
  Future<void> watchPlaces(List<DevicePlace> places);
  Future<void> stopPlaces();
  Future<bool> requestNotifications();
  Stream<({String app, String title, String text})> notifications();
}

class PluginTriggerPlatform implements DeviceTriggerPlatform {
  bool get _mobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  var _geoReady = false;

  @override
  bool get supportsPlaces => _mobile;
  @override
  bool get supportsNotifications => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> requestPlaces() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    // Arrive and leave with the app closed need "Always"; the OS asks for it after "While using".
    if (p == LocationPermission.whileInUse) p = await Geolocator.requestPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  @override
  Future<({double lat, double lng})?> currentLocation() async {
    final p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)),
    );
    return (lat: pos.latitude, lng: pos.longitude);
  }

  @override
  Future<void> watchPlaces(List<DevicePlace> places) async {
    if (!_geoReady) {
      await NativeGeofenceManager.instance.initialize();
      _geoReady = true;
    }
    await NativeGeofenceManager.instance.removeAllGeofences();
    for (final p in places.take(20)) {
      await NativeGeofenceManager.instance.createGeofence(
        Geofence(
          id: 'place:${p.name}',
          location: Location(latitude: p.latitude.toDouble(), longitude: p.longitude.toDouble()),
          radiusMeters: p.radiusM.toDouble(),
          triggers: {GeofenceEvent.enter, GeofenceEvent.exit},
          iosSettings: const IosGeofenceSettings(initialTrigger: false),
          androidSettings: const AndroidGeofenceSettings(initialTriggers: {}, notificationResponsiveness: Duration(minutes: 1)),
        ),
        placeGeofenceTriggered,
      );
    }
  }

  @override
  Future<void> stopPlaces() async {
    if (!_geoReady) {
      await NativeGeofenceManager.instance.initialize();
      _geoReady = true;
    }
    await NativeGeofenceManager.instance.removeAllGeofences();
  }

  @override
  Future<bool> requestNotifications() async {
    if (await NotificationListenerService.isPermissionGranted()) return true;
    return NotificationListenerService.requestPermission();
  }

  @override
  Stream<({String app, String title, String text})> notifications() =>
      NotificationListenerService.notificationsStream.where((n) => !n.hasRemoved).map((n) => (app: n.packageName, title: n.title, text: n.content));
}
