import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// Where a call's audio plays.
enum CallRouteKind { speaker, earpiece, bluetooth, headphones }

/// One place a call can play through: the speaker, the earpiece, or a connected headset.
@immutable
class CallRoute {
  const CallRoute(this.kind, {this.id = '', this.name = ''});
  final CallRouteKind kind;

  /// The device's id (a port uid on iOS, a device id on Android); empty for the built-in ones.
  final String id;

  /// The headset's own name ("AirPods Pro"); empty for the built-in ones.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is CallRoute && other.kind == kind && other.id == id;
  @override
  int get hashCode => Object.hash(kind, id);
}

/// Picks where a live call plays on phones: the speaker by default, the earpiece, or a Bluetooth
/// or wired headset that's connected. Desktop and web play through whatever the system uses.
abstract class CallAudioRoutes {
  /// Only phones have a choice.
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<List<CallRoute>> available();
  Future<CallRoute?> current();
  Future<void> select(CallRoute route);
}

/// The real routes, through the audio_session plugin (AVAudioSession on iOS, AudioManager on
/// Android).
class DeviceCallAudioRoutes implements CallAudioRoutes {
  static const _speaker = CallRoute(CallRouteKind.speaker);
  static const _earpiece = CallRoute(CallRouteKind.earpiece);

  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  // -- iOS
  static CallRouteKind? _iosKind(AVAudioSessionPort p) => switch (p) {
    AVAudioSessionPort.builtInSpeaker => CallRouteKind.speaker,
    AVAudioSessionPort.builtInReceiver => CallRouteKind.earpiece,
    AVAudioSessionPort.bluetoothHfp ||
    AVAudioSessionPort.bluetoothA2dp ||
    AVAudioSessionPort.bluetoothLe => CallRouteKind.bluetooth,
    AVAudioSessionPort.headphones ||
    AVAudioSessionPort.headsetMic ||
    AVAudioSessionPort.usbAudio => CallRouteKind.headphones,
    _ => null,
  };

  // -- Android
  static CallRouteKind? _androidKind(AndroidAudioDeviceType t) => switch (t) {
    AndroidAudioDeviceType.builtInSpeaker => CallRouteKind.speaker,
    AndroidAudioDeviceType.builtInEarpiece => CallRouteKind.earpiece,
    AndroidAudioDeviceType.bluetoothSco ||
    AndroidAudioDeviceType.hearingAid => CallRouteKind.bluetooth,
    AndroidAudioDeviceType.wiredHeadset ||
    AndroidAudioDeviceType.wiredHeadphones ||
    AndroidAudioDeviceType.usbHeadset => CallRouteKind.headphones,
    _ => null,
  };

  /// Android 12+ lists communication devices; older versions only switch the speakerphone.
  Future<List<AndroidAudioDeviceInfo>?> _androidDevices() async {
    try {
      return await AndroidAudioManager().getAvailableCommunicationDevices();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CallRoute>> available() async {
    if (!CallAudioRoutes.supported) return const [];
    if (_ios) {
      final inputs = await AVAudioSession().availableInputs;
      return [
        _speaker,
        _earpiece,
        for (final p in inputs)
          if (_iosKind(p.portType) case final kind?
              when kind != CallRouteKind.speaker &&
                  kind != CallRouteKind.earpiece)
            CallRoute(kind, id: p.uid, name: p.portName),
      ];
    }
    final devices = await _androidDevices();
    if (devices == null) return const [_speaker, _earpiece];
    final routes = <CallRoute>[];
    for (final d in devices) {
      final kind = _androidKind(d.type);
      if (kind == null) continue;
      final builtIn =
          kind == CallRouteKind.speaker || kind == CallRouteKind.earpiece;
      routes.add(
        CallRoute(kind, id: '${d.id}', name: builtIn ? '' : d.productName),
      );
    }
    routes.sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return routes;
  }

  @override
  Future<CallRoute?> current() async {
    if (!CallAudioRoutes.supported) return null;
    if (_ios) {
      final route = await AVAudioSession().currentRoute;
      for (final p in route.outputs) {
        final kind = _iosKind(p.portType);
        if (kind == CallRouteKind.speaker || kind == CallRouteKind.earpiece) {
          return CallRoute(kind!);
        }
        if (kind != null) {
          // Headsets are listed by their input port; match by name.
          final inputs = await AVAudioSession().availableInputs;
          final match = inputs
              .where((i) => i.portName == p.portName)
              .firstOrNull;
          return CallRoute(kind, id: match?.uid ?? p.uid, name: p.portName);
        }
      }
      return null;
    }
    try {
      final d = await AndroidAudioManager().getCommunicationDevice();
      if (d != null) {
        final kind = _androidKind(d.type);
        if (kind != null) {
          final builtIn =
              kind == CallRouteKind.speaker || kind == CallRouteKind.earpiece;
          return CallRoute(
            kind,
            id: '${d.id}',
            name: builtIn ? '' : d.productName,
          );
        }
      }
    } catch (_) {}
    return await AndroidAudioManager().isSpeakerphoneOn()
        ? _speaker
        : _earpiece;
  }

  @override
  Future<void> select(CallRoute route) async {
    if (!CallAudioRoutes.supported) return;
    if (_ios) {
      final session = AVAudioSession();
      if (route.kind == CallRouteKind.speaker) {
        await session.overrideOutputAudioPort(
          AVAudioSessionPortOverride.speaker,
        );
        return;
      }
      await session.overrideOutputAudioPort(AVAudioSessionPortOverride.none);
      final inputs = await session.availableInputs;
      final input = route.kind == CallRouteKind.earpiece
          ? inputs
                .where((i) => i.portType == AVAudioSessionPort.builtInMic)
                .firstOrNull
          : inputs.where((i) => i.uid == route.id).firstOrNull;
      if (input != null) await session.setPreferredInput(input);
      return;
    }
    final manager = AndroidAudioManager();
    final devices = await _androidDevices();
    if (devices == null) {
      await manager.setSpeakerphoneOn(route.kind == CallRouteKind.speaker);
      return;
    }
    final device = route.id.isNotEmpty
        ? devices.where((d) => '${d.id}' == route.id).firstOrNull
        : devices.where((d) => _androidKind(d.type) == route.kind).firstOrNull;
    if (device != null) {
      await manager.setCommunicationDevice(device);
    } else {
      await manager.setSpeakerphoneOn(route.kind == CallRouteKind.speaker);
    }
  }
}
