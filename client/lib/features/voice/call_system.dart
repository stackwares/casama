import 'dart:async';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../../l10n/generated/app_localizations.dart';

/// What the phone's own call controls ask of a live call (D-327 §7).
enum CallSystemAction {
  mute,
  unmute,
  end,

  /// Tapping the call notification: the call screen.
  open,

  /// Another call took over (CallKit put this one on hold), and gave it back.
  hold,
  resume,
}

/// A live call as the phone's call controls show it.
class CallSystemCall {
  const CallSystemCall({
    required this.id,
    required this.botName,
    this.botAvatar,
    this.phoneCallId,
  });

  /// A UUID for the call (its server record's id).
  final String id;
  final String botName;

  /// The bot's icon as it stores it (`mascot:<name>`; null for its initials).
  final String? botAvatar;

  /// An answered ring (D-135): CallKit already has this call, so it isn't reported again.
  final String? phoneCallId;
}

/// The phone's side of a live call (D-327 §7), so it carries on like a normal phone call outside
/// the app: CallKit on iPhone, a microphone foreground service with a call notification on
/// Android, nothing elsewhere. One per call.
abstract class CallSystem {
  /// Reports the call before it connects. Completes when the mic and speaker may start (iPhone:
  /// once CallKit has activated the audio session).
  Future<void> start(CallSystemCall call);

  /// The voice connection is live (the timer starts).
  Future<void> connected();

  /// Mute and the "Reconnecting" state, for the system's controls.
  Future<void> update({required bool muted, required bool reconnecting});

  /// The call is over. Safe to call more than once.
  Future<void> end();

  Stream<CallSystemAction> get actions;
}

/// Desktop, web and tests: no system call controls (the island and menu bar are Phase 4).
class NoCallSystem implements CallSystem {
  @override
  Future<void> start(CallSystemCall call) async {}
  @override
  Future<void> connected() async {}
  @override
  Future<void> update({
    required bool muted,
    required bool reconnecting,
  }) async {}
  @override
  Future<void> end() async {}
  @override
  Stream<CallSystemAction> get actions => const Stream.empty();
}

/// flutter_callkit_incoming's events, shared: each `onEvent` is a new listen on one event channel,
/// and a second listen would take the events from the first (the ringing calls' answer button).
final callKitEvents = FlutterCallkitIncoming.onEvent.asBroadcastStream();

/// iPhone: the call as an outgoing CallKit call (the green pill, the lock screen call UI, headset
/// and AirPods buttons). CallKit owns the audio session once it's active, so the mic and player
/// start after it says so (or after a short wait, so a slow CallKit never blocks a call).
class CallKitCallSystem implements CallSystem {
  CallKitCallSystem({this.audioWait = const Duration(seconds: 3)});
  final Duration audioWait;

  String? _id;
  var _own = false;
  var _ending = false;
  bool? _muted;
  StreamSubscription<CallEvent?>? _sub;
  final _actions = StreamController<CallSystemAction>.broadcast();

  @override
  Stream<CallSystemAction> get actions => _actions.stream;

  @override
  Future<void> start(CallSystemCall call) async {
    final id = call.phoneCallId ?? call.id;
    _id = id;
    _own = call.phoneCallId == null;
    final audio = Completer<void>();
    _sub = callKitEvents.listen((e) {
      switch (e) {
        case CallEventActionCallToggleAudioSession(:final isActive):
          if (isActive && !audio.isCompleted) audio.complete();
        case CallEventActionCallToggleMute(id: final i, :final isMuted)
            when i == id:
          _muted = isMuted;
          _actions.add(
            isMuted ? CallSystemAction.mute : CallSystemAction.unmute,
          );
        case CallEventActionCallToggleHold(id: final i, :final isOnHold)
            when i == id:
          _actions.add(
            isOnHold ? CallSystemAction.hold : CallSystemAction.resume,
          );
        case CallEventActionCallEnded(:final callKitParams)
            when callKitParams.id == id && !_ending:
          _actions.add(CallSystemAction.end);
        default:
      }
    });
    if (!_own) return; // An answered ring: CallKit's call and audio session are already up.
    try {
      await FlutterCallkitIncoming.startCall(
        CallKitParams(
          id: id,
          nameCaller: call.botName,
          appName: 'Casama',
          handle: call.botName,
          type: 0,
          extra: {'live_call_id': call.id},
          ios: const IOSParams(
            handleType: 'generic',
            supportsVideo: false,
            supportsDTMF: false,
            supportsHolding: true,
            supportsGrouping: false,
            supportsUngrouping: false,
            includesCallsInRecents: false,
            configureAudioSession: true,
            audioSessionMode: 'voiceChat',
          ),
        ),
      );
      await audio.future.timeout(audioWait, onTimeout: () {});
    } catch (e) {
      debugPrint('CallKit start failed: $e');
    }
  }

  @override
  Future<void> connected() async {
    final id = _id;
    if (id == null || !_own) return;
    try {
      await FlutterCallkitIncoming.setCallConnected(id);
    } catch (e) {
      debugPrint('CallKit connected failed: $e');
    }
  }

  @override
  Future<void> update({required bool muted, required bool reconnecting}) async {
    final id = _id;
    if (id == null || _muted == muted) return;
    _muted = muted;
    try {
      await FlutterCallkitIncoming.muteCall(id, isMuted: muted);
    } catch (e) {
      debugPrint('CallKit mute failed: $e');
    }
  }

  @override
  Future<void> end() async {
    if (_ending) return;
    _ending = true;
    final id = _id;
    await _sub?.cancel();
    if (id != null) {
      try {
        await FlutterCallkitIncoming.endCall(id);
      } catch (e) {
        debugPrint('CallKit end failed: $e');
      }
    }
    await _actions.close();
  }
}

/// Android: a microphone foreground service holding an ongoing call notification (CallStyle:
/// the bot, the timer, Mute and End Call), so the call keeps the mic with the screen off. It
/// starts with the call, while the app is in front: Android only lets a service start using the
/// mic then (`casama/call_service`, CallService.kt).
class AndroidCallService implements CallSystem {
  AndroidCallService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('casama/call_service');
  final MethodChannel _channel;
  final _actions = StreamController<CallSystemAction>.broadcast();
  Map<String, Object?>? _start;
  var _running = false;
  var _ended = false;

  @override
  Stream<CallSystemAction> get actions => _actions.stream;

  Future<bool> _invoke(String method, [Map<String, Object?>? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
      return true;
    } catch (e) {
      debugPrint('call service $method failed: $e');
      return false;
    }
  }

  @override
  Future<void> start(CallSystemCall call) async {
    _channel.setMethodCallHandler((m) async {
      if (m.method != 'action' || _ended) return;
      final action = switch ((m.arguments as Map?)?['action']) {
        'mute' => CallSystemAction.mute,
        'unmute' => CallSystemAction.unmute,
        'end' => CallSystemAction.end,
        'open' => CallSystemAction.open,
        _ => null,
      };
      if (action != null) _actions.add(action);
    });
    final l10n = callStrings();
    _start = {
      'id': call.id,
      'bot': call.botName,
      'avatar': ?call.botAvatar,
      'live': l10n.callNotificationLive,
      'muted': l10n.callNotificationMuted,
      'reconnecting': l10n.callReconnecting,
      'mute': l10n.mute,
      'unmute': l10n.unmute,
      'end': l10n.callEndCall,
      'channel': l10n.callNotificationChannel,
    };
    // The service starts alongside the call; the mic doesn't wait for it.
    _starting = _begin(call.phoneCallId);
  }

  Future<void>? _starting;

  Future<void> _begin(String? ring) async {
    _running = await _invoke('start', _start);
    // An answered ring (D-135): the calling screen's plugin keeps its own ongoing-call
    // notification; this one takes over, so there's one notification and it ends with the call.
    if (ring != null) {
      try {
        await FlutterCallkitIncoming.endCall(ring);
      } catch (e) {
        debugPrint('ring notification not cleared: $e');
      }
    }
  }

  @override
  Future<void> connected() async {
    await _starting;
    // The very first call asks for the mic only as it connects, and Android won't start a mic
    // service without it: start it now, while the app is still in front.
    if (!_running && _start != null && !_ended) {
      _running = await _invoke('start', _start);
    }
    if (_running) {
      await _invoke('connected', {
        'since': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  @override
  Future<void> update({required bool muted, required bool reconnecting}) async {
    await _starting;
    if (_running) {
      await _invoke('update', {'muted': muted, 'reconnecting': reconnecting});
    }
  }

  @override
  Future<void> end() async {
    if (_ended) return;
    _ended = true;
    await _starting;
    if (_start != null) await _invoke('stop');
    _channel.setMethodCallHandler(null);
    await _actions.close();
  }
}

/// The app's strings outside a widget (the notification's and other native surfaces' words).
AppLocalizations callStrings() {
  try {
    return lookupAppLocalizations(PlatformDispatcher.instance.locale);
  } catch (_) {
    return lookupAppLocalizations(const Locale('en'));
  }
}

/// CallKit isn't allowed in mainland China: there the call keeps going on background audio alone,
/// without the system call UI. Judged by the device's region.
bool get callKitAllowed =>
    PlatformDispatcher.instance.locale.countryCode?.toUpperCase() != 'CN';

/// The call controls for this platform.
CallSystem deviceCallSystem() {
  if (kIsWeb) return NoCallSystem();
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS when callKitAllowed => CallKitCallSystem(),
    TargetPlatform.android => AndroidCallService(),
    _ => NoCallSystem(),
  };
}

/// When something else takes the phone's audio (a phone call, FaceTime, Siri, an alarm), and
/// when headphones are unplugged (D-327 §7).
abstract class CallInterruptions {
  /// The call starts using audio (Android: it asks for audio focus, so it hears about others).
  Future<void> begin();

  /// true when the audio is taken, false when it's given back.
  Stream<bool> get interrupted;

  /// Headphones were unplugged (or a Bluetooth headset went away).
  Stream<void> get unplugged;

  /// Takes the audio back after an interruption.
  Future<void> reclaim();

  /// The call is over: the audio goes back to others.
  Future<void> finish();
}

/// Phones, through audio_session (AVAudioSession on iOS, audio focus on Android).
class DeviceCallInterruptions implements CallInterruptions {
  /// [callKit]: CallKit owns the iPhone's audio session and gives it back itself.
  DeviceCallInterruptions({this.callKit = false});
  final bool callKit;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static bool get _android => defaultTargetPlatform == TargetPlatform.android;

  final _session = AudioSession.instance;

  @override
  Future<void> begin() async {
    if (!_android) return;
    try {
      final s = await _session;
      await s.configure(
        const AudioSessionConfiguration(
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ),
      );
      await s.setActive(true);
    } catch (e) {
      debugPrint('audio focus not taken: $e');
    }
  }

  @override
  Stream<bool> get interrupted => Stream.fromFuture(_session)
      .asyncExpand(
        (s) => s.interruptionEventStream
            // A duck (a navigation prompt) only lowers the volume; the call goes on.
            .where((e) => e.type != AudioInterruptionType.duck)
            .map((e) => e.begin),
      )
      .handleError((Object e) => debugPrint('interruptions: $e'));

  @override
  Stream<void> get unplugged =>
      Stream.fromFuture(_session)
          .asyncExpand((s) => s.becomingNoisyEventStream)
          .handleError((Object e) => debugPrint('unplugged: $e'));

  @override
  Future<void> reclaim() async {
    if (callKit && !_android) return;
    try {
      await (await _session).setActive(true);
    } catch (e) {
      debugPrint('audio session not reclaimed: $e');
    }
  }

  @override
  Future<void> finish() async {
    if (!_android) return;
    try {
      await (await _session).setActive(false);
    } catch (e) {
      debugPrint('audio focus not released: $e');
    }
  }
}

/// The interruptions for this platform, or null where there are none to hear (desktop, web).
CallInterruptions? deviceCallInterruptions() =>
    DeviceCallInterruptions.supported
    ? DeviceCallInterruptions(
        callKit: defaultTargetPlatform == TargetPlatform.iOS && callKitAllowed,
      )
    : null;
