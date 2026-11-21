import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../core/analytics.dart';
import '../../core/backend.dart';
import '../../core/mobile_extras.dart';
import '../../core/providers.dart';
import '../../core/push.dart';
import '../../core/router.dart';
import '../../core/shortcuts.dart' show askPath;
import '../../l10n/generated/app_localizations.dart';
import '../app_lock/app_lock.dart';
import '../companion/desktop_shell.dart';
import '../inbox/for_you.dart' show forYouProvider, needsYouCountProvider;
import '../widgets/widget_settings.dart';
import '../voice/active_call.dart';
import '../voice/call_system.dart';
import 'island_call.dart';
import 'island_feed.dart';
import 'island_settings.dart';
import 'run_tracker.dart';

/// The bridge between the island feed and the native surfaces (D-324, §8.3): one method channel,
/// `casama/island`, on macOS, iOS and Android.
///
/// - Dart → native `state`: the feed's items, the inbox count, the bots quick ask can go to, and
///   the button labels (from app_en.arb, so native code holds no text).
/// - Native → Dart `action`: open a link, stop a run, allow or deny an approval, ask (bot and
///   text), drop (file paths), quick ask, show the window, seen (the list or panel was opened,
///   for analytics). From a widget (D-405, with `from: "widget"`): also run a routine
///   (`run_routine`) and accept a suggestion (`accept`).
/// - Native → Dart `token`: a Live Activity's push token (or an Android phone's), registered for
///   its run.
///
/// Native sides: macOS `client/macos/Runner/Island.swift` (Phase 1), iOS
/// `client/ios/Runner/IslandActivities.swift` (Phase 3), Android
/// `client/android/app/src/main/kotlin/ai/casama/app/LiveRun.kt` (Phase 5).
const islandChannelName = 'casama/island';

final islandChannelProvider = Provider<MethodChannel>(
  (ref) => const MethodChannel(islandChannelName),
);

/// The labels native code shows, keyed as it reads them.
Map<String, String> islandLabels(AppLocalizations l10n) => {
  'open': l10n.islandOpen,
  'stop': l10n.islandStop,
  'allow': l10n.islandAllow,
  'deny': l10n.islandDeny,
  'review': l10n.islandReview,
  'needs_ok': l10n.islandNeedsOk,
  'working': l10n.islandWorking,
  'take_over': l10n.islandTakeOver,
  'finished': l10n.islandFinished,
  'problem': l10n.islandStoppedProblem,
  'on_this_mac': l10n.islandOnThisMac,
  'stale': l10n.islandStale,
  'nothing': l10n.islandNothing,
  'quick_ask': l10n.islandQuickAsk,
  'open_casama': l10n.islandOpenCasama,
  'settings': l10n.islandSettings,
  'quit': l10n.islandQuit,
  'ask_hint': l10n.islandAskHint,
  'needs_you': l10n.islandNeedsYou,
  'on_a_call': l10n.islandOnACall,
  'mute': l10n.mute,
  'unmute': l10n.unmute,
  'hang_up': l10n.hangUp,
  'drop_here': l10n.islandDropHere,
  'bot_working': l10n.islandBotWorking,
  'bots_at_work': l10n.islandBotsAtWork,
  'steps_one': l10n.islandSteps(1),
  // Android fills in the number (%d); the plural's "other" form.
  'steps_other': l10n.islandSteps(1000001).replaceAll('1000001', '%d'),
};

/// Whether the native island answered that it can be on screen (the notch on this Mac). While it
/// is, a bot using this computer shows there with Stop, so the window no longer has to force
/// itself on top (D-324, decision 10); otherwise D-066's on-top window stays.
class IslandOnScreen extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final islandOnScreenProvider = NotifierProvider<IslandOnScreen, bool>(IslandOnScreen.new);

/// The longest step on a phone's Lock Screen. A Live Activity's whole state must stay under 4 KB,
/// the same limit a server push has (Phase 4), so items are cut down here, in one place (D-324,
/// §8.5).
const lockScreenStep = 60;

String _cut(String s, int max) => s.length <= max ? s : '${s.substring(0, max - 1).trimRight()}…';

/// [item] as a Live Activity or an Android live notification shows it. The Lock Screen can be read without unlocking, so it gets
/// the same general words a server push carries (§10): the step in words anyone may read, and no
/// detail (what was searched, a site, a file). Nothing it doesn't draw.
Map<String, Object?> forLockScreen(Map<String, Object?> item) => {
  for (final e in item.entries)
    if (!const {'cost_usd', 'here', 'detail', 'public_step'}.contains(e.key)) e.key: e.value,
  'step': _cut('${item['public_step'] ?? item['step'] ?? ''}', lockScreenStep),
};

/// The whole state sent to native code: everything it needs to draw, nothing it must decide.
final islandStateProvider = Provider<Map<String, Object?>>((ref) {
  final l10n = ref.watch(islandL10nProvider);
  final bots = [
    for (final b in ref.watch(botsProvider).value ?? const <Bot>[])
      if (b.status != BotStatusEnum.disabled) b,
  ];
  final saved = ref.watch(islandAskBotProvider);
  final feed = ref.watch(islandFeedProvider);
  // Each bot's icon as it stores it (`mascot:<name>`, or none for initials), so native code draws
  // the same mark the app does (bot_avatar.dart).
  final avatars = {for (final b in ref.watch(botsProvider).value ?? const <Bot>[]) b.id: b.avatarUrl};
  Map<String, Object?> withAvatar(Map<String, Object?> item) => {...item, 'bot_avatar': ?avatars[item['bot_id']]};
  return {
    'items': switch (defaultTargetPlatform) {
      // A phone's lock screen shows it (Android shows the full notification there unless the
      // person hides sensitive content), so both phones get the same general words.
      TargetPlatform.iOS || TargetPlatform.android => [
        for (final i in feed)
          if (i.runId != null && !i.onThisComputer) withAvatar(forLockScreen(i.toJson())),
      ],
      _ => [for (final i in feed) withAvatar(i.toJson())],
    },
    // The tracker has heard from the server since launch: a Live Activity for a run it doesn't
    // list can end.
    'synced': ref.watch(islandSyncedProvider),
    // Labelled "Needs you" in the notch and menu bar, so the same count as the sidebar's Needs you
    // (approvals, takeovers, suggestions), not unread updates as well.
    'inbox': ref.watch(needsYouCountProvider),
    'bots': [
      for (final b in bots) {'id': b.id, 'name': b.name},
    ],
    // The bot the ask field goes to: the one talked to last, else the first.
    'ask_bot': bots.any((b) => b.id == saved) ? saved : bots.firstOrNull?.id,
    'notch': ref.watch(islandNotchOnProvider),
    'hover': ref.watch(islandHoverOpensProvider),
    'labels': islandLabels(l10n),
    // A voice call on this Mac (D-324, Phase 6): the notch shows it with a level meter, Mute and End.
    if (defaultTargetPlatform == TargetPlatform.macOS) 'call': ?_callState(ref.watch(islandCallProvider), bots),
  };
});

Map<String, Object?>? _callState(IslandCall? call, List<Bot> bots) => call == null
    ? null
    : {
        'bot_id': call.botId,
        'bot': bots.where((b) => b.id == call.botId).firstOrNull?.name ?? '',
        'bot_avatar': ?bots.where((b) => b.id == call.botId).firstOrNull?.avatarUrl,
        'started_at': call.startedAt.millisecondsSinceEpoch / 1000,
        'muted': call.muted,
      };

/// Sends the island's state to native code and carries out what native code asks.
class IslandBridge {
  IslandBridge(this._ref, this._channel);
  final Ref _ref;
  final MethodChannel _channel;

  /// False once native code turned out not to listen (no native side on this build).
  bool _native = true;
  String? _lastSent;

  /// Runs this Android phone has asked the server to push to (its Firebase token per run).
  final _liveRegistered = <String>{};

  /// This iPhone's push-to-start token, as ActivityKit handed it over (`start_token`).
  String? _iosStartToken;

  /// What the server was last told about push-to-start: account, token and the switch.
  String? _startSynced;

  /// The sync in flight: syncs run one after another, so a late "on" can't land after an "off".
  Future<void> _startSync = Future.value();

  /// Push-to-start (D-324, Phase 6; decision 11): tells the server where to start a run this person
  /// starts on another device (an Android phone's Firebase token, which can change, is read each
  /// time), and whether this phone wants them (Settings → Bots you start elsewhere; off keeps the
  /// row, so a shared phone keeps following the account signed in last). Only phones; only when
  /// something changed. Public for tests.
  Future<void> syncStartToken() => _startSync = _startSync.then((_) => _syncStartToken()).catchError((Object e) {
    debugPrint('island start token failed: $e');
  });

  Future<void> _syncStartToken() async {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    if (!ios && defaultTargetPlatform != TargetPlatform.android) return;
    final backend = _ref.read(backendProvider);
    final userId = backend.userId;
    if (userId == null) return;
    final push = _ref.read(pushProvider);
    final token = ios ? _iosStartToken : await push.silentToken();
    if (token == null || token.isEmpty || !_ref.mounted) return;
    // Read after every wait: the switch may have changed meanwhile.
    final on = _ref.read(islandStartElsewhereProvider);
    final key = '$userId|$token|$on';
    if (key == _startSynced) return;
    final pushToken = ios ? await push.silentToken() : null;
    if (!_ref.mounted || _ref.read(islandStartElsewhereProvider) != on) return;
    _startSynced = key;
    try {
      await backend.registerLiveStartToken(_platform, token, pushToken: pushToken, enabled: on);
    } catch (_) {
      _startSynced = null;
      rethrow;
    }
  }

  /// Runs a phone has shown on its Lock Screen, counted once each (plan §15).
  final _liveCounted = <String>{};

  void _countStarted(Map<String, Object?> state) {
    final event = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'live_activity_started',
      TargetPlatform.android => 'live_notification_started',
      _ => null,
    };
    if (event == null) return;
    for (final i in (state['items'] as List? ?? const [])) {
      if (i is Map && i['run_id'] is String && i['ended_at'] == null && _liveCounted.add(i['run_id'] as String)) {
        Analytics.feature(event);
      }
    }
  }

  void start() => _channel.setMethodCallHandler(handle);

  void dispose() {
    _levels?.cancel();
    _channel.setMethodCallHandler(null);
  }

  /// The call's level meter: ten times a second while a call is live, only when it moved.
  Timer? _levels;
  double _lastLevel = -1;

  /// Starts or stops sending the call's level to the notch. Public for tests.
  void followCall(IslandCall? call) {
    if (call == null || defaultTargetPlatform != TargetPlatform.macOS) {
      _levels?.cancel();
      _levels = null;
      _lastLevel = -1;
      return;
    }
    _levels ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      final controls = _ref.read(islandCallProvider.notifier).controls;
      if (controls == null || !_native) return;
      final level = (controls.level * 20).roundToDouble() / 20;
      if (level == _lastLevel) return;
      _lastLevel = level;
      _channel.invokeMethod<void>('level', level).catchError((_) {});
    });
  }

  /// Sends [state] unless it is what was sent last.
  Future<void> send(Map<String, Object?> state) async {
    if (!_native) return;
    final key = state.toString();
    if (key == _lastSent) return;
    _lastSent = key;
    try {
      final shown = await _channel.invokeMethod<Object?>('state', state);
      _ref.read(islandOnScreenProvider.notifier).set(shown == true);
      _countStarted(state);
      if (defaultTargetPlatform == TargetPlatform.android) unawaited(_registerAndroid(state));
      unawaited(syncStartToken());
    } on MissingPluginException {
      _native = false;
      _ref.read(islandOnScreenProvider.notifier).set(false);
    } catch (e) {
      // Native code failed to draw it: the next change tries again.
      _lastSent = null;
      debugPrint('island state failed: $e');
    }
  }

  /// An Android phone has no per-run token: it registers its own Firebase token for each run it
  /// shows, so the server's updates (data-only messages LiveRunReceiver draws) reach it while the
  /// app sleeps. Once per run; a run that has ended needs none.
  Future<void> _registerAndroid(Map<String, Object?> state) async {
    final runs = [
      for (final i in (state['items'] as List? ?? const []))
        if (i is Map && i['run_id'] is String && i['ended_at'] == null) i['run_id'] as String,
    ];
    final fresh = runs.where(_liveRegistered.add).toList();
    if (fresh.isEmpty) return;
    final left = [...fresh];
    try {
      final token = await _ref.read(pushProvider).silentToken();
      // No token yet (Firebase not ready, no network): the next state tries again.
      if (token == null || token.isEmpty) {
        _liveRegistered.removeAll(left);
        return;
      }
      final backend = _ref.read(backendProvider);
      for (final run in fresh) {
        await backend.registerLiveToken(run, 'android', token);
        left.remove(run);
      }
    } catch (e) {
      // The ones not registered try again on the next state.
      _liveRegistered.removeAll(left);
      debugPrint('island live token failed: $e');
    }
  }

  /// Answers one call from native code. Public for tests.
  Future<Object?> handle(MethodCall call) async {
    final args = call.arguments is Map
        ? Map<String, Object?>.from(call.arguments as Map)
        : const <String, Object?>{};
    try {
      switch (call.method) {
        case 'action':
          return await _action(args);
        case 'start_token':
          final token = args['token'];
          if (token is! String || token.isEmpty) return false;
          _iosStartToken = token;
          await syncStartToken();
          return true;
        case 'token':
          final runId = args['run_id'];
          final token = args['token'];
          if (runId is! String || token is! String || token.isEmpty) {
            return false;
          }
          // An iPhone's own Firebase token goes along, even with notifications off (D-324).
          final pushToken = _platform == 'ios'
              ? await _ref.read(pushProvider).silentToken()
              : null;
          await _ref
              .read(backendProvider)
              .registerLiveToken(runId, _platform, token, pushToken: pushToken);
          return true;
      }
    } catch (e) {
      debugPrint('island ${call.method} failed: $e');
    }
    return false;
  }

  static String get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => 'macos',
  };

  /// Allow and Deny are answered in place only for a request the feed shows as waiting
  /// (decision 5): on a computer (the Mac's notch, the tray menu on Windows and Linux) at a click;
  /// on a phone (D-324, Phase 6) only once the phone was unlocked for it (Face ID or the passcode
  /// on iPhone, the lock screen on Android: native code says so with `unlocked`), and only for a
  /// request whose risk is known and isn't high; a high-risk one is reviewed in the app.
  bool _answersInPlace(String approvalId, {required bool unlocked}) {
    final phone = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.android => true,
      _ when islandDesktops.contains(defaultTargetPlatform) => false,
      _ => null,
    };
    if (phone == null || (phone && !unlocked)) return false;
    return _ref
        .read(islandFeedProvider)
        .any(
          (i) =>
              i.phase == IslandPhase.needsOk &&
              i.approvalId == approvalId &&
              (!phone || (i.risk != null && i.risk != 'high')),
        );
  }

  /// What a person did on the island, counted once a day as a feature (plan §15).
  static const _counted = {'stop', 'allow', 'deny', 'ask', 'drop', 'quickAsk'};

  /// Asked from the notch (§6 B 6): a new chat with [botId], sent without opening the window, and
  /// the run shows in the notch at once. With nothing to send, or if sending fails, Quick ask opens
  /// with the text so nothing typed is lost.
  Future<bool> _ask(String? botId, String text) async {
    final bots = _ref.read(botsProvider).value ?? const <Bot>[];
    final bot = bots.where((b) => b.id == botId).firstOrNull;
    if (bot != null && text.isNotEmpty) {
      try {
        final backend = _ref.read(backendProvider);
        final c = await backend.createConversation(bot.id);
        final sent = await backend.send(c.id, text);
        if (!_ref.mounted) return true;
        _ref.read(runTrackerProvider.notifier).startedHere(sent.runId, botId: bot.id, conversationId: c.id);
        unawaited(_ref.read(islandAskBotProvider.notifier).set(bot.id));
        return true;
      } catch (e) {
        debugPrint('island ask failed: $e');
        if (!_ref.mounted) return false;
      }
    }
    _ref.read(routerProvider).go(askPath(botId: bot?.id, text: text));
    _ref.read(desktopShellProvider).showWindow();
    return false;
  }

  /// The app lock is up (D-375): what's behind it waits, as if the window were the only way in.
  bool get _locked {
    final settings = _ref.read(appLockSettingsProvider);
    return settings.activeFor(_ref.read(backendProvider).userId) && _ref.read(appLockProvider).locked;
  }

  /// What a widget or control pressed (native passes `from: "widget"`), as `widget_action` names
  /// it (plan D-405 §15).
  static const _widgetActions = {'run_routine': 'run', 'accept': 'do_it', 'allow': 'allow', 'deny': 'deny', 'stop': 'stop'};

  /// A widget's button on a phone (D-405 §8.4): nothing is done in place while widgets are private
  /// (the app lock, §10). Native code then opens the app at the fallback link, behind the lock.
  bool get _widgetMayAct => _phone && !_ref.read(widgetsPrivateProvider);

  static bool get _phone => defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;

  /// Allow and Deny from a widget (D-405 decision 5): only a request that is still waiting and is
  /// low risk, read fresh from the server, since the widget may be minutes old. Medium and high
  /// show Review in the widget and are answered in the app.
  Future<bool> _widgetAnswers(String approvalId) async {
    if (!_widgetMayAct) return false;
    final orgId = _ref.read(currentOrgIdProvider);
    if (orgId == null) return false;
    final waiting = await _ref.read(backendProvider).approvals(orgId);
    return waiting.any((a) => a.id == approvalId && a.status == ApprovalStatusEnum.pending && a.risk == Risk.low);
  }

  Future<bool> _action(Map<String, Object?> args) async {
    // Run now and Do it only ever come from a widget or control.
    final fromWidget = args['from'] == 'widget' || args['kind'] == 'run_routine' || args['kind'] == 'accept';
    final done = await _carryOut(args, fromWidget: fromWidget);
    final action = fromWidget ? _widgetActions[args['kind']] : null;
    if (done && action != null) Analytics.widgetAction(action);
    return done;
  }

  Future<bool> _carryOut(Map<String, Object?> args, {required bool fromWidget}) async {
    final backend = _ref.read(backendProvider);
    if (!fromWidget && _counted.contains(args['kind'])) Analytics.feature('notch_action');
    // Widgets' buttons (D-405): Run now, Do it, Allow and Deny, on phones only. The Mac's widgets
    // only open links.
    if (fromWidget) {
      switch (args['kind']) {
        case 'run_routine':
          final routineId = args['routine_id'];
          if (routineId is! String || routineId.isEmpty || !_widgetMayAct) return false;
          final runId = await backend.runRoutine(routineId);
          // Started by hand here, so the phone follows it on the Lock Screen (D-324).
          final botId = args['bot_id'];
          if (botId is String && botId.isNotEmpty && _ref.mounted) {
            _ref.read(runTrackerProvider.notifier).startedHere(runId, botId: botId);
          }
          return true;
        case 'accept':
          final suggestionId = args['suggestion_id'];
          if (suggestionId is! String || suggestionId.isEmpty || !_widgetMayAct) return false;
          await backend.acceptSuggestion(suggestionId);
          _ref.invalidate(forYouProvider);
          return true;
        case 'allow' || 'deny':
          final approvalId = args['approval_id'];
          if (approvalId is! String || !await _widgetAnswers(approvalId)) return false;
          await backend.decideApproval(approvalId, approve: args['kind'] == 'allow');
          _ref.invalidate(approvalsProvider);
          return true;
        default:
          // Stop and Open work as from the Live Activity, below.
          break;
      }
    }
    // While locked, nothing is sent or answered from the notch or the tray: Allow, Deny and Ask
    // open the window (the lock screen) instead. Stop and the call's controls still work. Phones
    // answer only after the phone itself was unlocked for it (see [_answersInPlace]).
    if (isDesktop && _locked && const {'allow', 'deny', 'ask', 'drop'}.contains(args['kind'])) {
      _ref.read(desktopShellProvider).showWindow();
      return false;
    }
    switch (args['kind']) {
      case 'seen':
        // The person opened the notch's list (by hovering) or the menu bar panel.
        final what = switch (args['what']) {
          'notch' => 'notch_opened',
          'menu_bar' => 'menu_bar_panel',
          _ => null,
        };
        if (what == null) return false;
        Analytics.feature(what);
        return true;
      case 'open':
        final link = args['link'];
        // Only places inside the app, as the feed gave them.
        if (link is! String || !link.startsWith('/') || link.startsWith('//')) {
          return false;
        }
        _ref.read(routerProvider).go(link);
        return true;
      case 'stop':
        final runId = args['run_id'];
        if (runId is! String) return false;
        try {
          await backend.cancelRun(runId);
        } on RunAlreadyFinished {
          // It ended a moment ago; the tracker says how.
        }
        unawaited(_ref.read(runTrackerProvider.notifier).check());
        return true;
      case 'call_mute':
        final controls = _ref.read(islandCallProvider.notifier).controls;
        if (controls == null) return false;
        controls.toggleMute();
        return true;
      case 'call_end':
        final controls = _ref.read(islandCallProvider.notifier).controls;
        if (controls == null) return false;
        controls.hangUp();
        return true;
      case 'call_open':
        // The notch's call row: the call screen, in the window brought forward.
        if (_ref.read(islandCallProvider) == null) return false;
        _ref.read(activeCallProvider).act(CallSystemAction.open);
        return true;
      case 'allow' || 'deny':
        final approvalId = args['approval_id'];
        if (approvalId is! String || !_answersInPlace(approvalId, unlocked: args['unlocked'] == true)) {
          return false;
        }
        // Allowing a high-risk request asks to unlock again (D-375): it opens in the app instead.
        if (args['kind'] == 'allow' && _ref.read(appLockSettingsProvider).askBeforeRisky) {
          final item = _ref.read(islandFeedProvider).where((i) => i.approvalId == approvalId).firstOrNull;
          if (item?.risk == 'high') {
            final link = item!.link;
            if (link.startsWith('/') && !link.startsWith('//')) _ref.read(routerProvider).go(link);
            if (isDesktop) _ref.read(desktopShellProvider).showWindow();
            return false;
          }
        }
        await backend.decideApproval(
          approvalId,
          approve: args['kind'] == 'allow',
        );
        _ref.invalidate(approvalsProvider);
        return true;
      case 'ask':
        final text = args['text'] is String ? (args['text'] as String).trim() : '';
        final botId = args['bot_id'] is String ? args['bot_id'] as String : null;
        return _ask(botId, text);
      case 'drop':
        final paths = [
          for (final p in (args['paths'] as List? ?? const []))
            if (p is String && p.isNotEmpty) p,
        ];
        if (paths.isEmpty) return false;
        _ref.read(pendingSharedFilesProvider.notifier).set([
          for (final p in paths)
            SharedAttachment(
              name: p.split('/').last,
              read: () => XFile(p).readAsBytes(),
            ),
        ]);
        _ref.read(routerProvider).go('/quick-ask');
        return true;
      case 'quickAsk':
        // Full quick ask with what's in front as context (D-152), as Cmd+Shift+K opens it.
        _ref.read(desktopShellProvider).openQuickAsk();
        return true;
      case 'show':
        // Native code brings the window forward itself.
        return true;
    }
    return false;
  }
}

/// The live bridge where there is an island; null elsewhere. Whatever keeps it watched (app.dart,
/// from Phase 1) keeps the feed flowing to native code.
final islandBridgeProvider = Provider<IslandBridge?>((ref) {
  if (!ref.watch(islandSupportedProvider)) return null;
  final bridge = IslandBridge(ref, ref.watch(islandChannelProvider))..start();
  ref.onDispose(bridge.dispose);
  ref.listen(
    islandStateProvider,
    (_, next) => unawaited(bridge.send(next)),
    fireImmediately: true,
  );
  ref.listen(islandStartElsewhereProvider, (_, _) => unawaited(bridge.syncStartToken()));
  ref.listen(islandCallProvider, (_, next) => bridge.followCall(next), fireImmediately: true);
  // The Mac's notch follows the app's live call (D-327), wherever its screen is.
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    ref.onDispose(followActiveCall(ref.read(activeCallProvider), ref.read(islandCallProvider.notifier)));
  }
  return bridge;
});
