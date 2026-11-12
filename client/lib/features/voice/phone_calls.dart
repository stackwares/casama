import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../core/analytics.dart';

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
  Stream<(CallAction, IncomingCall)> get actions => FlutterCallkitIncoming.onEvent.expand((e) {
    final (action, params) = switch (e) {
      CallEventActionCallAccept(:final callKitParams) => (CallAction.accept, callKitParams),
      CallEventActionCallDecline(:final callKitParams) => (CallAction.decline, callKitParams),
      _ => (null, null),
    };
    final call = params == null ? null : IncomingCall.fromData(params.extra ?? {'call_id': params.id});
    return action == null || call == null ? const <(CallAction, IncomingCall)>[] : [(action, call)];
  });

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

/// Android: a call push while the app is in the background or closed rings the calling screen.
@pragma('vm:entry-point')
Future<void> casamaBackgroundMessage(RemoteMessage message) async {
  final call = message.data['kind'] == 'call' ? IncomingCall.fromData(message.data) : null;
  if (call != null) await NativeCallSurface().show(call);
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
    // Android: a call push while the app is open.
    if (defaultTargetPlatform == TargetPlatform.android) {
      _subs.add(
        FirebaseMessaging.onMessage.listen((m) {
          final call = m.data['kind'] == 'call' ? IncomingCall.fromData(m.data) : null;
          if (call != null) unawaited(surface.show(call));
        }),
      );
    }
    try {
      final token = await surface.voipToken();
      if (token != null) await ref.read(backendProvider).registerVoipToken(token);
    } catch (e) {
      debugPrint('VoIP registration failed: $e');
    }
  }

  Future<void> answer(IncomingCall call) async {
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
    unawaited(ref.read(routerProvider).push(call.callPath));
  }

  Future<void> decline(String id) async {
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
    if (next.value == true) unawaited(calls.start());
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
                          tooltip: l10n.callAnswer,
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
