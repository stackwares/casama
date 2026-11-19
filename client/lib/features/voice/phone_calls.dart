import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/server_address.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../core/analytics.dart';
import 'active_call.dart';
import 'call_system.dart';

/// Phone-call voice (D-135): a bot rings this person. iOS shows CallKit (from a PushKit push,
/// handled in AppDelegate.swift), Android its own calling screen (from a high-priority FCM data
/// message), and desktop and web a ringing banner. Answering opens the live call; the bot speaks first.
class IncomingCall {
  const IncomingCall({required this.id, required this.botId, required this.botName, required this.reason, this.conversationId});
  final String id;
  final String botId;
  final String botName;
  final String reason;
  final String? conversationId;

  factory IncomingCall.fromCall(PhoneCall c) => IncomingCall(id: c.id, botId: c.botId, botName: c.botName, reason: c.reason, conversationId: c.conversationId);

  /// From a push payload or CallKit's `extra`.
  static IncomingCall? fromData(Map<dynamic, dynamic> d) {
    final id = d['call_id'];
    final bot = d['bot_id'];
    if (id is! String || id.isEmpty || bot is! String || bot.isEmpty) return null;
    final conv = d['conversation_id'];
    return IncomingCall(id: id, botId: bot, botName: d['bot_name'] as String? ?? 'Casama', reason: d['reason'] as String? ?? '', conversationId: conv is String && conv.isNotEmpty ? conv : null);
  }

  Map<String, Object?> toData() => {'call_id': id, 'bot_id': botId, 'bot_name': botName, 'reason': reason, 'conversation_id': conversationId ?? ''};

  /// Where answering goes: the live call in the bot's conversation.
  String get callPath => '/bots/$botId/call?call=$id${conversationId != null ? '&c=$conversationId' : ''}';
}

enum CallAction { accept, decline }

/// The phone's own calling UI, when there is one.
abstract class CallSurface {
  bool get native;
  Future<void> show(IncomingCall call);
  Future<void> end(String id);
  Stream<(CallAction, IncomingCall)> get actions;

  /// Rings the person already answered on the phone's calling screen while no app was listening
  /// (Android, app closed: the plugin keeps them, but its answer event went nowhere) (D-424).
  Future<List<IncomingCall>> answered();

  /// The iOS PushKit token (null elsewhere).
  Future<String?> voipToken();
}

/// Desktop and web: no system call UI; the banner does the ringing.
class NoCallSurface implements CallSurface {
  @override
  bool get native => false;
  @override
  Future<void> show(IncomingCall call) async {}
  @override
  Future<void> end(String id) async {}
  @override
  Stream<(CallAction, IncomingCall)> get actions => const Stream.empty();
  @override
  Future<List<IncomingCall>> answered() async => const [];
  @override
  Future<String?> voipToken() async => null;
}

/// iOS CallKit and Android's full-screen calling screen, through flutter_callkit_incoming.
class NativeCallSurface implements CallSurface {
  @override
  bool get native => true;

  @override
  Future<void> show(IncomingCall call) => FlutterCallkitIncoming.showCallkitIncoming(
    CallKitParams(
      id: call.id,
      nameCaller: call.botName,
      appName: 'Casama',
      handle: call.reason,
      type: 0,
      duration: 45000,
      extra: call.toData(),
      missedCallNotification: const NotificationParams(showNotification: false),
      android: const AndroidParams(isCustomNotification: false, isShowFullLockedScreen: true, textAccept: 'Answer', textDecline: 'Decline'),
      ios: const IOSParams(handleType: 'generic', supportsVideo: false, audioSessionMode: 'voiceChat'),
    ),
  );

  @override
  Future<void> end(String id) => FlutterCallkitIncoming.endCall(id);

  @override
  Stream<(CallAction, IncomingCall)> get actions => callKitEvents.expand((e) {
    final (action, params) = switch (e) {
      CallEventActionCallAccept(:final callKitParams) => (CallAction.accept, callKitParams),
      CallEventActionCallDecline(:final callKitParams) => (CallAction.decline, callKitParams),
      _ => (null, null),
    };
    final call = params == null ? null : IncomingCall.fromData(params.extra ?? {'call_id': params.id});
    return action == null || call == null ? const <(CallAction, IncomingCall)>[] : [(action, call)];
  });

  @override
  Future<List<IncomingCall>> answered() async {
    // iOS hands a cold-start answer to Dart itself (and lists the app's own outgoing calls here).
    if (defaultTargetPlatform != TargetPlatform.android) return const [];
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      return [
        for (final c in calls)
          if (c.isAccepted) ?IncomingCall.fromData(c.extra ?? {'call_id': c.id}),
      ];
    } catch (e) {
      debugPrint('answered rings not read: $e');
      return const [];
    }
  }

  @override
  Future<String?> voipToken() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    final t = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    return t is String && t.isNotEmpty ? t : null;
  }
}

final callSurfaceProvider = Provider<CallSurface>(
  (ref) => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) ? NativeCallSurface() : NoCallSurface(),
);

/// Rings answered on this phone (D-424, D-425). A cancel for one of these is about this phone's own
/// call, which keeps going.
final answeredRings = <String>{};

/// Rings stopped because the call was taken, declined or missed elsewhere (D-425): the Decline
/// event ending them makes isn't the person's, so nothing declines them on the server.
final cancelledRings = <String>{};

/// The call was answered, declined or missed on another device (D-425): stop ringing here. Never
/// a call answered here: [answeredRings] (this isolate) or the plugin's own answered flag (Android,
/// any isolate). iOS's `endCall` after a VoIP ring ends that ring whatever the id, so it is only
/// called while a call with this id is up.
Future<void> stopRing(String id, {Future<List<CallKitParams>> Function()? active, Future<void> Function(String id)? end}) async {
  if (answeredRings.contains(id)) return;
  List<CallKitParams> calls;
  try {
    calls = await (active ?? FlutterCallkitIncoming.activeCalls)();
  } catch (e) {
    debugPrint('ring not stopped: $e');
    return;
  }
  final ring = calls.where((c) => c.id == id).firstOrNull;
  if (ring == null || ring.isAccepted) return;
  cancelledRings.add(id);
  try {
    await (end ?? FlutterCallkitIncoming.endCall)(id);
  } catch (e) {
    debugPrint('ring not stopped: $e');
  }
}

/// The call id in a `call_cancel` push (D-425), or null for any other push.
String? cancelledCallId(Map<String, dynamic> data) {
  final id = data['call_id'];
  return data['kind'] == 'call_cancel' && id is String && id.isNotEmpty ? id : null;
}

/// Pushes while the app is in the background or closed: on Android a call push rings the calling
/// screen; on both phones a `call_cancel` stops a ring another device took (D-425). Android runs
/// this in its own isolate; iPhones in the app's (a background push, so only while it runs).
@pragma('vm:entry-point')
Future<void> casamaBackgroundMessage(RemoteMessage message) async {
  final cancelled = cancelledCallId(message.data);
  if (cancelled != null) return stopRing(cancelled);
  if (defaultTargetPlatform != TargetPlatform.android) return;
  final call = message.data['kind'] == 'call' ? IncomingCall.fromData(message.data) : null;
  if (call == null) return;
  // Listening before the ring shows, so a quick Decline isn't missed.
  final token = message.data['decline_token'];
  final declined = token is String && token.isNotEmpty ? ringDeclined(callKitEvents, call.id) : null;
  await NativeCallSurface().show(call);
  if (declined != null && await declined && !cancelledRings.contains(call.id)) await sendRingDecline(call.id, token as String);
}

/// Android, app closed (D-424): Decline on the calling screen goes only to the isolate that rang,
/// which has no sign-in. True once this ring is declined; false when it's answered, ends or times
/// out, or after [limit] (a little over the ring's 45 seconds).
Future<bool> ringDeclined(Stream<CallEvent?> events, String id, {Duration limit = const Duration(seconds: 60)}) =>
    events
        .map(
          (e) => switch (e) {
            CallEventActionCallDecline(:final callKitParams) when callKitParams.id == id => true,
            CallEventActionCallAccept(:final callKitParams) when callKitParams.id == id => false,
            CallEventActionCallEnded(:final callKitParams) when callKitParams.id == id => false,
            CallEventActionCallTimeout(id: final i) when i == id => false,
            _ => null,
          },
        )
        .firstWhere((d) => d != null, orElse: () => false)
        .then((d) => d!)
        .timeout(limit, onTimeout: () => false)
        .catchError((Object _) => false);

/// Declines the ring with its own token from the push: no sign-in needed, good for this call only.
/// Already over (or an older server): nothing changes, the call is missed as before.
Future<void> sendRingDecline(String id, String token, {http.Client? client, Future<String> Function()? apiUrl}) async {
  final c = client ?? http.Client();
  try {
    final base = await (apiUrl ?? () async => (await ServerAddress.load()).apiUrl)();
    await c
        .post(Uri.parse('$base/v1/calls/$id/decline-ring'), headers: {'content-type': 'application/json'}, body: jsonEncode({'token': token}))
        .timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('ring decline not sent: $e');
  } finally {
    if (client == null) c.close();
  }
}

/// Answers and declines, wherever they come from.
class PhoneCalls {
  PhoneCalls(this.ref);
  final Ref ref;
  final _subs = <StreamSubscription<Object?>>[];
  var _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final surface = ref.read(callSurfaceProvider);
    if (!surface.native) return;
    _subs.add(surface.actions.listen((a) => unawaited(a.$1 == CallAction.accept ? answer(a.$2) : decline(a.$2.id))));
    // While the app is open: a call push rings (Android), and a cancel stops a ring another
    // device took (both phones, D-425).
    _subs.add(
      FirebaseMessaging.onMessage.listen((m) {
        final cancelled = cancelledCallId(m.data);
        if (cancelled != null) return unawaited(stopRing(cancelled));
        if (defaultTargetPlatform != TargetPlatform.android) return;
        final call = m.data['kind'] == 'call' ? IncomingCall.fromData(m.data) : null;
        if (call != null) unawaited(surface.show(call));
      }),
    );
    // Android, opened by Answer with the app closed: the answer event fired before anything here
    // listened, so the answered ring is picked up from the plugin instead (D-424).
    for (final call in await surface.answered()) {
      unawaited(answer(call));
    }
  }

  /// The iPhone's PushKit token, on every sign-in: another account signing in after a sign-out
  /// takes this phone's call rings over (D-437).
  Future<void> registerToken() async {
    final surface = ref.read(callSurfaceProvider);
    if (!surface.native) return;
    try {
      final token = await surface.voipToken();
      if (token != null) await ref.read(backendProvider).registerVoipToken(token);
    } catch (e) {
      debugPrint('VoIP registration failed: $e');
    }
  }

  Future<void> answer(IncomingCall call) async {
    // The answer event and the launch check can both report one ring.
    if (!answeredRings.add(call.id)) return;
    try {
      await ref.read(backendProvider).answerCall(call.id);
    } catch (_) {
      // Already over (missed, or answered elsewhere): open the conversation instead.
      await ref.read(callSurfaceProvider).end(call.id).catchError((_) {});
      ref.read(routerProvider).go(call.conversationId != null ? '/bots/${call.botId}/chat?c=${call.conversationId}' : '/bots/${call.botId}/chat');
      return;
    }
    Analytics.log('bot_call_answered', {'answer': 'accepted'});
    ref.invalidate(ringingCallsProvider);
    // One call at a time (D-327): answering a ring during a call ends that call first (saved as
    // usual). The person chose End and Answer, or answered on the phone's own calling screen.
    await ref.read(activeCallProvider).end(CallEnd.replaced);
    unawaited(ref.read(routerProvider).pushOnce(call.callPath));
  }

  Future<void> decline(String id) async {
    // Ended because another device took it (D-425), not declined by the person.
    if (cancelledRings.contains(id)) return;
    try {
      await ref.read(backendProvider).declineCall(id);
    } catch (_) {
      // Already over; nothing to do.
    }
    Analytics.log('bot_call_answered', {'answer': 'declined'});
    ref.invalidate(ringingCallsProvider);
  }

  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
  }
}

final phoneCallsProvider = Provider<PhoneCalls>((ref) {
  final calls = PhoneCalls(ref);
  ref.onDispose(calls.dispose);
  ref.listen(signedInProvider, (_, next) {
    if (next.value == true) unawaited(calls.start().then((_) => calls.registerToken()));
  }, fireImmediately: true);
  return calls;
});

/// Desktop and web: the ringing banner over the app, while a call rings.
class IncomingCallBanner extends ConsumerStatefulWidget {
  const IncomingCallBanner({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<IncomingCallBanner> createState() => _IncomingCallBannerState();
}

class _IncomingCallBannerState extends ConsumerState<IncomingCallBanner> {
  Timer? _expiry;

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(phoneCallsProvider);
    if (ref.watch(callSurfaceProvider).native) return widget.child;
    final calls = ref.watch(ringingCallsProvider).value ?? const <PhoneCall>[];
    final call = calls.where((c) => c.expiresAt.isAfter(DateTime.now())).firstOrNull;
    _expiry?.cancel();
    if (call != null) _expiry = Timer(call.expiresAt.difference(DateTime.now()), () => ref.invalidate(ringingCallsProvider));
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final onCall = ref.watch(activeCallProvider).live != null;
    return Stack(
      children: [
        widget.child,
        if (call != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + AppSpace.md,
            left: AppSpace.md,
            right: AppSpace.md,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Material(
                  key: const Key('incomingCall'),
                  elevation: 8,
                  borderRadius: BorderRadius.circular(20),
                  color: scheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(LucideIcons.phoneIncoming, color: scheme.onPrimaryContainer),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.callIncoming(call.botName), style: Theme.of(context).textTheme.titleMedium),
                              Text(call.reason, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          key: const Key('declineCall'),
                          tooltip: l10n.callDecline,
                          style: IconButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
                          icon: const Icon(LucideIcons.phoneOff),
                          onPressed: () => unawaited(ref.read(phoneCallsProvider).decline(call.id)),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        IconButton.filled(
                          key: const Key('answerCall'),
                          // During a call, answering ends it first (D-327).
                          tooltip: onCall ? l10n.callEndAndAnswer : l10n.callAnswer,
                          style: IconButton.styleFrom(
                            backgroundColor: context.appColors.positive,
                            foregroundColor: ThemeData.estimateBrightnessForColor(context.appColors.positive) == Brightness.dark ? Colors.white : Colors.black,
                          ),
                          icon: const Icon(LucideIcons.phone),
                          onPressed: () => unawaited(ref.read(phoneCallsProvider).answer(IncomingCall.fromCall(call))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
