import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics.dart';
import '../../core/backend.dart';
import '../../core/mobile_extras.dart' show appGroupId;
import '../../core/providers.dart';
import '../../core/push.dart';
import '../../l10n/generated/app_localizations.dart';
import '../inbox/for_you.dart' show forYouProvider;
import 'widget_key_store.dart';
import 'widget_settings.dart';

/// The app's carrier for widgets (D-405, docs/WIDGETS-PLAN.md §8.3 step 1, §17). While Casama is
/// open it fetches the glance from the server, writes it where the widgets read, and asks them to
/// redraw. It also holds this device's widget key (§8.3 step 3), so widgets can fetch on their own.

/// Native widget code on iOS and Android: `setKey {key}`, `reload`, `installed`, and on Android
/// `pin {provider}` and `pinBot {bot_id, name, avatar}`.
const widgetsChannelName = 'casama/widgets';
const widgetsChannel = MethodChannel(widgetsChannelName);

/// The Mac's bridge (`MacBridge`): `glance` writes the glance into the Mac's app group.
const _macChannel = MethodChannel('casama/mac');

/// Android widget providers, by class name in the app's package (`ai.casama.app`). One list, so a
/// rename on the Kotlin side is one change here.
const androidWidgetProviders = [
  'AskWidget',
  'NeedsYouWidget',
  'BotStatusWidget',
  'RoutinesWidget',
  'TodayWidget',
  'BriefWidget',
  'LibraryWidget',
  'TasksWidget',
  'CreditsWidget',
];

/// How often the glance is fetched at most while things change (§8.3: once in 15 seconds).
const glanceGap = Duration(seconds: 15);

/// The words widgets show, keyed as native code reads them (§17). Placeholders stay in braces
/// (`{bot}`, `{time}`, `{n}`, `{amount}`): native code fills them in.
Map<String, String> glanceWords(AppLocalizations l10n) => {
  'needs_you': l10n.widgetNeedsYou,
  'all_clear': l10n.widgetAllClear,
  'allow': l10n.widgetAllow,
  'deny': l10n.widgetDeny,
  'review': l10n.widgetReview,
  'open': l10n.widgetOpen,
  'do_it': l10n.widgetDoIt,
  'run_now': l10n.widgetRunNow,
  'started': l10n.widgetStarted,
  'stop': l10n.widgetStop,
  'ask': l10n.widgetAsk,
  'ask_bot': l10n.widgetAskBot('{bot}'),
  'talk': l10n.widgetTalk,
  'try': l10n.widgetTry,
  'up_next': l10n.widgetUpNext,
  'no_routines': l10n.widgetNoRoutines,
  'working': l10n.widgetWorking,
  'waiting': l10n.widgetWaiting,
  'idle': l10n.widgetIdle,
  'off': l10n.widgetStatusOff,
  'replied_at': l10n.widgetRepliedAt('{time}'),
  'brief': l10n.widgetBrief,
  'brief_at': l10n.widgetBriefAt('{time}'),
  'no_brief': l10n.widgetNoBrief,
  'today': l10n.widgetToday,
  'credits': l10n.widgetCredits,
  'credits_left': l10n.widgetCreditsLeft('{amount}'),
  'spent_today': l10n.widgetSpentToday('{amount}'),
  'used_pct': l10n.widgetUsedPct('{n}'),
  'resets_at': l10n.widgetResetsAt('{time}'),
  'finished': l10n.widgetFinished,
  'library': l10n.widgetLibrary,
  'no_creations': l10n.widgetNoCreations,
  'tasks': l10n.widgetTasks,
  'todo': l10n.widgetTodo,
  'in_progress': l10n.widgetInProgress,
  'in_review': l10n.widgetInReview,
  'blocked': l10n.widgetBlocked,
  'sign_in': l10n.widgetSignIn,
  'no_bots': l10n.widgetNoBots,
  'as_of': l10n.widgetAsOf('{time}'),
  'update_server': l10n.widgetUpdateServer,
  'needs_ok_from': l10n.widgetNeedsOkFrom('{bot}'),
  'suggests': l10n.widgetSuggests('{bot}'),
  'take_over': l10n.widgetTakeOver('{bot}'),
  'next_brief': l10n.widgetNextBrief('{time}'),
  'nothing_next': l10n.widgetNothingNext,
  'low_risk': l10n.widgetLowRisk,
  'this_month': l10n.widgetThisMonth,
};

/// A small glance built from what the app already holds, for a server from before `/v1/glance`
/// (§6.6 "Server too old"). Bots, the Needs you count and today's spend; everything else empty.
/// `source: "app"` tells widgets that need more (Routines, Brief, Library, Tasks) to say "Update
/// your Casama server" instead of looking empty.
Map<String, Object?> localGlance({
  required String orgId,
  required List<Bot> bots,
  required List<Approval> approvals,
  required List<TakeoverRequest> takeovers,
  required List<Suggestion> suggestions,
  num todayUsd = 0,
  DateTime? now,
}) {
  final byId = {for (final b in bots) b.id: b};
  String name(String botId) => byId[botId]?.name ?? '';
  String avatar(String botId) => byId[botId]?.avatarUrl ?? '';
  String iso(DateTime t) => t.toUtc().toIso8601String();
  // A blocked bot first (approvals, takeovers), newest first; then suggestions, urgent first.
  final blocked = <Map<String, Object?>>[
    for (final a in approvals)
      {
        'kind': 'approval', 'id': a.id, 'bot_id': a.botId, 'bot': name(a.botId), 'bot_avatar': avatar(a.botId),
        'text': a.summary, 'risk': a.risk.value, 'urgent': false, 'created_at': iso(a.createdAt), 'link': '/approvals/${a.id}',
      },
    for (final t in takeovers)
      {
        'kind': 'takeover', 'id': t.id, 'bot_id': t.botId, 'bot': name(t.botId), 'bot_avatar': avatar(t.botId),
        'text': t.reason, 'risk': null, 'urgent': false, 'created_at': iso(t.createdAt), 'link': '/inbox',
      },
  ]..sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
  final ideas = [...suggestions]
    ..sort((a, b) {
      final urgent = (b.urgency == SuggestionUrgencyEnum.urgent ? 1 : 0) - (a.urgency == SuggestionUrgencyEnum.urgent ? 1 : 0);
      return urgent != 0 ? urgent : b.createdAt.compareTo(a.createdAt);
    });
  final items = [
    ...blocked,
    for (final s in ideas)
      {
        'kind': 'suggestion', 'id': s.id, 'bot_id': s.botId, 'bot': name(s.botId), 'bot_avatar': avatar(s.botId),
        'text': s.title, 'risk': null, 'urgent': s.urgency == SuggestionUrgencyEnum.urgent, 'created_at': iso(s.createdAt),
        'link': '/inbox',
      },
  ];
  final waiting = {for (final i in blocked) i['bot_id']};
  final active = [for (final b in bots) if (b.status != BotStatusEnum.disabled) b];
  return {
    'version': 'app-${bots.length}-${items.length}-${active.map((b) => b.status.value).join()}',
    'made_at': iso(now ?? DateTime.now()),
    'org_id': orgId,
    'source': 'app',
    'needs': {'count': items.length, 'items': items.take(4).toList()},
    'bots': [
      for (final b in bots.take(8))
        {
          'id': b.id, 'name': b.name, 'avatar': b.avatarUrl ?? '',
          'status': waiting.contains(b.id) && b.status != BotStatusEnum.disabled ? 'waiting' : b.status.value,
          'step': null, 'last_text': null, 'last_at': null, 'busy_at': null, 'link': '/bots/${b.id}/chat',
        },
    ],
    'next': const [],
    // For the widgets' routine pickers; an older server gives the app no list across bots.
    'routines': const [],
    'brief': null,
    'lately': const [],
    'recent': const [],
    'tasks': const {
      'counts': {'todo': 0, 'in_progress': 0, 'in_review': 0, 'blocked': 0},
      'items': [],
    },
    'credits': {
      'billing': false, 'unlimited': false, 'plan': null, 'used_share': null, 'left_usd': null,
      'today_usd': todayUsd, 'month_usd': 0, 'daily_cap_usd': null, 'daily_used_usd': null, 'resets_at': null,
    },
    'starters': const [],
    'flags': {'private': false, 'hide_reply_text': false},
  };
}

/// Where widgets read, per platform: the App Group on iPhone, home_widget's store on Android, the
/// Mac's app group through `MacBridge`. Replaced in tests.
abstract class WidgetSurface {
  /// Writes the four §17 values (null removes one) and asks every widget to redraw. [key] is the
  /// widget key, for the Mac, whose bridge stores it with the glance.
  Future<void> publish({required String? glance, required String words, required String server, required bool signedIn, String? key});

  /// Hands the widget key to native code (null forgets it). The Mac takes it in [publish].
  Future<void> setKey(String? key);

  /// The widgets placed now, as native code lists them; null when it can't say.
  Future<List<Object?>?> installed();

  /// The glance was just checked with the server (also when nothing changed): `glance_checked_at`,
  /// in epoch milliseconds, so widgets don't call current data old.
  Future<void> checked(DateTime at);

  static WidgetSurface? forPlatform() {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => IosWidgetSurface(),
      TargetPlatform.android => AndroidWidgetSurface(),
      TargetPlatform.macOS => MacWidgetSurface(),
      _ => null,
    };
  }
}

/// iPhone and Android share home_widget's store; only the redraw differs.
abstract class _PhoneSurface implements WidgetSurface {
  Future<void> _prepare() async {}
  Future<void> _redraw();

  @override
  Future<void> publish({required String? glance, required String words, required String server, required bool signedIn, String? key}) async {
    await _prepare();
    await HomeWidget.saveWidgetData<String>('glance', glance);
    await HomeWidget.saveWidgetData<String>('glance_words', words);
    await HomeWidget.saveWidgetData<String>('glance_server', server);
    await HomeWidget.saveWidgetData<String>('glance_signed_in', signedIn ? '1' : null);
    // The app's own fallback glance stands in for an older server, so this flag stays off; it is
    // cleared in case an earlier build set it.
    await HomeWidget.saveWidgetData<String>('glance_unsupported', null);
    await _redraw();
  }

  @override
  Future<void> setKey(String? key) => widgetsChannel.invokeMethod<void>('setKey', {'key': key});

  @override
  Future<List<Object?>?> installed() => widgetsChannel.invokeMethod<List<Object?>>('installed');

  @override
  Future<void> checked(DateTime at) async {
    await _prepare();
    await HomeWidget.saveWidgetData<String>('glance_checked_at', '${at.millisecondsSinceEpoch}');
  }
}

class IosWidgetSurface extends _PhoneSurface {
  @override
  Future<void> _prepare() async => HomeWidget.setAppGroupId(appGroupId);

  /// One WidgetCenter reload covers every kind.
  @override
  Future<void> _redraw() => widgetsChannel.invokeMethod<void>('reload');
}

class AndroidWidgetSurface extends _PhoneSurface {
  @override
  Future<void> _redraw() async {
    for (final name in androidWidgetProviders) {
      try {
        await HomeWidget.updateWidget(androidName: name);
      } catch (_) {
        // A provider this build doesn't have yet.
      }
    }
  }
}

class MacWidgetSurface implements WidgetSurface {
  /// The last glance sent, so a check that found nothing new can restamp it.
  Map<String, Object?>? _last;

  @override
  Future<void> publish({required String? glance, required String words, required String server, required bool signedIn, String? key}) {
    final args = <String, Object?>{'glance': glance, 'words': words, 'server': server, 'signed_in': signedIn, 'key': ?key};
    _last = signedIn ? args : null;
    return _macChannel.invokeMethod<void>('glance', {...args, 'checked_at': DateTime.now().millisecondsSinceEpoch});
  }

  @override
  Future<void> setKey(String? key) async {}

  @override
  Future<List<Object?>?> installed() async => null;

  /// The Mac's bridge keeps `checked_at` with the glance: the last one goes again, restamped.
  @override
  Future<void> checked(DateTime at) async {
    final last = _last;
    if (last != null) await _macChannel.invokeMethod<void>('glance', {...last, 'checked_at': at.millisecondsSinceEpoch});
  }
}

/// Asks the Android launcher to place [provider] (one of [androidWidgetProviders]). False when the
/// launcher can't, or this build has no such widget.
Future<bool> pinWidget(String provider) async {
  try {
    return await widgetsChannel.invokeMethod<bool>('pin', {'provider': provider}) ?? false;
  } catch (_) {
    return false;
  }
}

/// Puts [bot] on the Android Home screen as its own icon (a pinned shortcut to its chat).
Future<bool> pinBotShortcut(Bot bot) async {
  try {
    return await widgetsChannel.invokeMethod<bool>('pinBot', {'bot_id': bot.id, 'name': bot.name, 'avatar': bot.avatarUrl ?? ''}) ?? false;
  } catch (_) {
    return false;
  }
}

/// Keeps the widgets' store in step with the app. Public for tests.
class GlanceSync {
  GlanceSync(this._ref, this._surface, {this.gap = glanceGap, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Ref _ref;
  final WidgetSurface _surface;
  final Duration gap;
  final DateTime Function() _now;

  Timer? _timer;
  DateTime? _lastFetch;
  var _running = false;
  var _again = false;

  /// The last glance the server sent (or the app built), before any privacy is applied: a change
  /// of the privacy switch rewrites it without a fetch.
  Map<String, Object?>? _raw;
  String? _rawOrg;
  String? _etag;

  /// What was written last, so an unchanged glance doesn't redraw every widget.
  String? _written;

  /// The server answered 404 for the glance or the widget keys: don't ask again this session.
  var _noGlance = false;
  var _noKeys = false;

  /// The widget key made this session (the Mac takes it with every glance).
  String? _key;
  Future<void>? _keying;

  /// Fetches soon: now if the last fetch was [gap] ago, else once at the end of the gap.
  void schedule() {
    if (_timer != null) return;
    final last = _lastFetch;
    final since = last == null ? gap : _now().difference(last);
    if (since >= gap) {
      unawaited(_run());
    } else {
      _timer = Timer(gap - since, () {
        _timer = null;
        unawaited(_run());
      });
    }
  }

  void dispose() => _timer?.cancel();

  Future<void> _run() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    _lastFetch = _now();
    try {
      await sync();
    } catch (e) {
      debugPrint('glance sync failed: $e');
    } finally {
      _running = false;
    }
    if (_again && _ref.mounted) {
      _again = false;
      schedule();
    }
  }

  /// One fetch and write, without the gap. Public for tests.
  Future<void> sync() async {
    if (!_ref.mounted) return;
    if (_ref.read(signedInProvider).value != true) return signedOut();
    final orgId = _ref.read(currentOrgIdProvider);
    if (orgId == null) return;
    final backend = _ref.read(backendProvider);
    if (_rawOrg != orgId) {
      _etag = null;
      _raw = null;
    }
    GlanceData? glance;
    if (!_noGlance) {
      // Offline: what the widgets have stays, and they show its age.
      glance = await backend.glance(orgId, ifNoneMatch: _etag);
      if (!_ref.mounted) return;
      if (glance == null) _noGlance = true;
    }
    if (glance == null) {
      _raw = _fallback(orgId);
      _etag = null;
    } else if (!glance.unchanged) {
      _raw = glance.json;
      _etag = glance.etag ?? '"${glance.version}"';
    }
    // Unchanged: the last one is still right (the words or the privacy may not be).
    _rawOrg = orgId;
    try {
      await _surface.checked(_now());
    } catch (_) {}
    // Widgets fetch on their own only from a server that has the glance.
    if (glance != null) await ensureKey(orgId);
    await write();
  }

  Map<String, Object?> _fallback(String orgId) => localGlance(
    orgId: orgId,
    bots: _ref.read(botsProvider).value ?? const [],
    approvals: _ref.read(approvalsProvider).value ?? const [],
    takeovers: _ref.read(takeoversProvider).value ?? const [],
    suggestions: _ref.read(forYouProvider.exists) ? _ref.read(forYouProvider).value?.suggestions ?? const [] : const [],
    todayUsd: _ref.read(usageTodayProvider).value?.totalCostUsd ?? 0,
    now: _now(),
  );

  /// Writes the last glance, made private when it should be (§10). Public for tests.
  Future<void> write() async {
    final raw = _raw;
    if (raw == null || !_ref.mounted) return;
    final flags = raw['flags'];
    final private = _ref.read(widgetsPrivateProvider) || (flags is Map && flags['private'] == true);
    final glance = jsonEncode(private ? privateGlance(raw) : raw);
    final words = jsonEncode(glanceWords(_l10n()));
    final server = _ref.read(backendProvider).apiUrl;
    final key = '$glance|$words|$server|$_key';
    if (key == _written) return;
    _written = key;
    try {
      await _surface.publish(glance: glance, words: words, server: server, signedIn: true, key: _key);
    } catch (e) {
      _written = null;
      debugPrint('glance write failed: $e');
    }
  }

  /// Signed out: the widgets forget everything and show "Open Casama to sign in". The server side
  /// of the key goes in the backend's sign-out, while the session still works.
  Future<void> signedOut() async {
    _timer?.cancel();
    _timer = null;
    _raw = null;
    _rawOrg = null;
    _etag = null;
    _key = null;
    _noGlance = false;
    _noKeys = false;
    if (_written == 'signed-out') return;
    _written = 'signed-out';
    await WidgetKeyStore.clear();
    try {
      await _surface.setKey(null);
    } catch (_) {}
    try {
      await _surface.publish(glance: null, words: jsonEncode(glanceWords(_l10n())), server: _ref.read(backendProvider).apiUrl, signedIn: false);
    } catch (e) {
      debugPrint('glance clear failed: $e');
    }
  }

  /// The privacy switch or the app lock changed: rewrite at once, and tell the server, which
  /// makes the key's own fetches private too.
  Future<void> privacyChanged() async {
    await write();
    final record = await WidgetKeyStore.load();
    if (record == null || !_ref.mounted) return;
    try {
      await _ref.read(backendProvider).setWidgetKeyPrivate(record.id, _ref.read(widgetsPrivateProvider));
    } catch (e) {
      debugPrint('widget key privacy failed: $e');
    }
  }

  /// Makes sure this device holds a widget key for [orgId] (§8.3): one per device, made for the
  /// signed-in account and workspace. Another account or workspace replaces it. On Android the
  /// phone's Firebase token goes with it, so the server can wake the widgets; a new token makes a
  /// new key, since the key itself lives only in native code. Public for tests.
  Future<void> ensureKey(String orgId) => _keying ??= _ensureKey(orgId).whenComplete(() => _keying = null);

  Future<void> _ensureKey(String orgId) async {
    if (_noKeys) return;
    final backend = _ref.read(backendProvider);
    final userId = backend.userId;
    if (userId == null) return;
    final android = defaultTargetPlatform == TargetPlatform.android;
    final pushToken = android ? await _ref.read(pushProvider).silentToken() : null;
    if (!_ref.mounted) return;
    final record = await WidgetKeyStore.load();
    if (record != null && record.userId == userId && record.orgId == orgId && (!android || pushToken == null || record.pushToken == pushToken)) {
      return;
    }
    if (record != null) {
      try {
        await backend.deleteWidgetKey(record.id);
      } catch (_) {}
      await WidgetKeyStore.clear();
    }
    final made = await backend.createWidgetKey(orgId, _platformName, label: _deviceLabel());
    if (!_ref.mounted) return;
    if (made == null) {
      _noKeys = true;
      return;
    }
    _key = made.key;
    var registered = false;
    if (pushToken != null && pushToken.isNotEmpty) {
      try {
        await backend.registerWidgetPushToken(made.key, pushToken, kind: 'fcm');
        registered = true;
      } catch (e) {
        debugPrint('widget push token failed: $e');
      }
    }
    await WidgetKeyStore.save(WidgetKeyRecord(id: made.id, userId: userId, orgId: orgId, pushToken: registered ? pushToken : null));
    try {
      await _surface.setKey(made.key);
    } catch (e) {
      debugPrint('widget key hand-over failed: $e');
    }
    if (_ref.read(widgetsPrivateProvider)) {
      try {
        await backend.setWidgetKeyPrivate(made.id, true);
      } catch (_) {}
    }
  }

  static String get _platformName => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => 'macos',
  };

  /// The device's name, where the system gives a real one (a Mac's host name), for the list of
  /// keys. Phones answer "localhost" or a generic model name: nothing is sent then.
  static String? _deviceLabel() {
    try {
      final host = Platform.localHostname.replaceAll(RegExp(r'\.local$'), '').trim();
      if (host.isEmpty || host == 'localhost') return null;
      return host.length > 80 ? host.substring(0, 80) : host;
    } catch (_) {
      return null;
    }
  }

  /// `widgets_placed` (§15), once a day per device, from what native code lists.
  Future<void> countPlaced() async {
    List<Object?>? placed;
    try {
      placed = await _surface.installed();
    } catch (_) {
      return;
    }
    if (placed == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      if (prefs.getString('casama.widgets.placed_day') == today) return;
      await prefs.setString('casama.widgets.placed_day', today);
    } catch (_) {
      return;
    }
    // iPhone lists each widget's family (`accessoryCircular` and friends on the Lock Screen);
    // Android a provider and id, plus `lock_screen` once it has lock screen widgets.
    final lockScreen = placed.any(
      (w) => w is Map && (w['lock_screen'] == true || '${w['family'] ?? ''}'.startsWith('accessory')),
    );
    Analytics.log('widgets_placed', {'count': placed.length, 'lock_screen': lockScreen});
  }

  static AppLocalizations _l10n() =>
      lookupAppLocalizations(basicLocaleListResolution(PlatformDispatcher.instance.locales, AppLocalizations.supportedLocales));
}

/// Fetches again soon (at most once in [glanceGap]): for changes the app knows about but this
/// carrier doesn't watch, such as a routine made or changed.
void refreshGlance(WidgetRef ref) => ref.read(glanceSyncProvider)?.schedule();

/// The carrier, on iPhone, Android and the Mac; null elsewhere. Watched by the app root.
final glanceSyncProvider = Provider<GlanceSync?>((ref) {
  final surface = ref.watch(widgetSurfaceProvider);
  if (surface == null) return null;
  final sync = GlanceSync(ref, surface);
  ref.onDispose(sync.dispose);
  ref.listen(signedInProvider, (_, next) {
    if (next.value == false) {
      unawaited(sync.signedOut());
    } else if (next.value == true) {
      sync.schedule();
    }
  }, fireImmediately: true);
  // What a widget shows changed: bots (status), what waits on the person (approvals, takeovers,
  // notifications), the workspace.
  ref.listen(botsProvider, (_, _) => sync.schedule());
  ref.listen(inboxBadgeProvider, (_, _) => sync.schedule());
  ref.listen(currentOrgIdProvider, (_, _) => sync.schedule());
  ref.listen(widgetsPrivateProvider, (prev, next) {
    if (prev != next) unawaited(sync.privacyChanged());
  });
  final lifecycle = AppLifecycleListener(
    onResume: () {
      sync.schedule();
      unawaited(sync.countPlaced());
    },
  );
  ref.onDispose(lifecycle.dispose);
  unawaited(sync.countPlaced());
  if (ref.watch(widgetClicksProvider)) _countWidgetOpens(ref);
  return sync;
});

/// Where widgets read on this device; null where there are none. Overridden in tests.
final widgetSurfaceProvider = Provider<WidgetSurface?>((ref) => WidgetSurface.forPlatform());

/// Whether to listen for Casama being opened from a widget (home_widget's launch links). Off in
/// tests, which have no plugin behind it.
final widgetClicksProvider = Provider<bool>(
  (ref) => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android),
);

/// `feature_used: widget_opened` (§15) when Casama opens from a widget. The router opens the link
/// itself; this only counts.
void _countWidgetOpens(Ref ref) {
  void opened(Uri? uri) {
    if (uri != null) Analytics.feature('widget_opened');
  }

  unawaited(HomeWidget.initiallyLaunchedFromHomeWidget().then(opened).catchError((_) {}));
  final sub = HomeWidget.widgetClicked.listen(opened, onError: (_) {});
  ref.onDispose(sub.cancel);
}
