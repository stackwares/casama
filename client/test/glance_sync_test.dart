// The widgets' carrier (D-405 §8.3, §17): what it writes, when it makes the glance private, how
// often it fetches, what signing out clears, the fallback for a server without the glance, and the
// widget key's life.
import 'dart:convert';

import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/push.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/features/widgets/glance_sync.dart';
import 'package:casama/features/widgets/widget_key_store.dart';
import 'package:casama/features/widgets/widget_settings.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

class _Bots extends BotsNotifier {
  _Bots(this.initial);
  final List<Bot> initial;
  @override
  Future<List<Bot>> build() async => initial;
}

class _TokenPush extends PushRegistrar {
  _TokenPush(Backend backend, this.token) : super(backend, (_) {});
  String? token;
  @override
  Future<String?> silentToken() async => token;
}

/// Records what would reach native code.
class _Surface implements WidgetSurface {
  final published = <({String? glance, String words, String server, bool signedIn, String? key})>[];
  final keys = <String?>[];
  List<Object?>? placed;

  Map<String, Object?> get lastGlance => jsonDecode(published.last.glance!) as Map<String, Object?>;

  @override
  Future<void> publish({required String? glance, required String words, required String server, required bool signedIn, String? key}) async =>
      published.add((glance: glance, words: words, server: server, signedIn: signedIn, key: key));

  @override
  Future<void> setKey(String? key) async => keys.add(key);

  @override
  Future<List<Object?>?> installed() async => placed;

  final checks = <DateTime>[];
  @override
  Future<void> checked(DateTime at) async => checks.add(at);
}

Map<String, Object?> sampleGlance() => {
  'version': 'v1',
  'made_at': '2026-11-18T09:00:00Z',
  'org_id': orgId,
  'needs': {
    'count': 1,
    'items': [
      {
        'kind': 'approval', 'id': 'a1', 'bot_id': botId, 'bot': 'Ada', 'bot_avatar': '', 'text': 'Email Ana the contract',
        'risk': 'low', 'urgent': false, 'created_at': '2026-11-18T08:59:00Z', 'link': '/approvals/a1',
      },
    ],
  },
  'bots': [
    {
      'id': botId, 'name': 'Ada', 'avatar': '', 'status': 'working', 'step': 'Searching the web', 'last_text': 'Here are the flights',
      'last_at': null, 'busy_at': null, 'link': '/bots/$botId/chat',
    },
  ],
  'next': [
    {'id': 'r1', 'bot_id': botId, 'name': 'Check my inbox', 'bot': 'Ada', 'bot_avatar': '', 'next_at': null, 'every': 'Every day', 'enabled': true, 'link': '/x'},
  ],
  'brief': {'bot_id': botId, 'bot': 'Ada', 'bot_avatar': '', 'text': 'Standup at 10', 'at': null, 'next_at': null, 'link': '/x'},
  'lately': [
    {'bot_id': botId, 'bot': 'Ada', 'bot_avatar': '', 'title': 'Trip plan', 'at': '2026-11-18T08:00:00Z', 'link': '/x'},
  ],
  'recent': [
    {'id': 'c1', 'kind': 'page', 'title': 'Trip plan', 'bot': 'Ada', 'has_cover': false, 'version': 1, 'at': '2026-11-18T08:00:00Z', 'link': '/x'},
  ],
  'tasks': {
    'counts': {'todo': 1, 'in_progress': 0, 'in_review': 0, 'blocked': 0},
    'items': [
      {'id': 't1', 'title': 'Book the hotel', 'status': 'todo', 'bot': 'Ada', 'link': '/tasks'},
    ],
  },
  'credits': {'billing': true, 'unlimited': false, 'plan': 'Plus', 'used_share': 0.4, 'left_usd': 9, 'today_usd': 0.5, 'month_usd': 6, 'daily_cap_usd': null, 'daily_used_usd': null, 'resets_at': null},
  'starters': [
    {'emoji': '✈️', 'text': 'Find me a flight'},
  ],
  'flags': {'private': false, 'hide_reply_text': false},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeBackend backend;
  late _Surface surface;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLockSettingsNotifier.resetForTest();
    backend = FakeBackend()
      ..glanceJson = sampleGlance()
      ..pendingApprovals = [];
    surface = _Surface();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  ProviderContainer container({List<Bot>? bots, String? requiredBy, String? pushToken = 'fcm-1'}) {
    final c = ProviderContainer(
      overrides: [
        backendProvider.overrideWithValue(backend),
        pushProvider.overrideWithValue(_TokenPush(backend, pushToken)),
        currentOrgIdProvider.overrideWithValue(orgId),
        botsProvider.overrideWith(() => _Bots(bots ?? [backend.bot()])),
        widgetSurfaceProvider.overrideWithValue(surface),
        widgetClicksProvider.overrideWithValue(false),
        if (requiredBy != null) appLockRequiredByProvider.overrideWithValue(requiredBy),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// A carrier without the app's listeners, for driving it step by step.
  GlanceSync carrier(ProviderContainer c, {Duration gap = glanceGap}) {
    final p = Provider<GlanceSync>((ref) => GlanceSync(ref, surface, gap: gap));
    final sync = c.read(p);
    addTearDown(sync.dispose);
    return sync;
  }

  Future<void> signedIn(ProviderContainer c) async {
    c.listen(signedInProvider, (_, _) {});
    await c.read(signedInProvider.future);
  }

  test('writes the glance, the words, the server and signed in, then redraws once', () async {
    final c = container();
    await signedIn(c);
    final sync = carrier(c);
    await sync.sync();
    expect(surface.published, hasLength(1));
    final p = surface.published.single;
    expect(p.signedIn, isTrue);
    expect(p.server, 'http://localhost:8787');
    expect(surface.lastGlance['version'], 'v1');
    expect((surface.lastGlance['bots'] as List).single, containsPair('last_text', 'Here are the flights'));
    final words = jsonDecode(p.words) as Map<String, Object?>;
    expect(words['needs_you'], 'Needs you');
    expect(words['all_clear'], 'All clear');
    expect(words['ask_bot'], 'Ask {bot}');
    expect(words['brief_at'], 'Brief at {time}');
    expect(words['used_pct'], '{n}% used');
    expect(words['low_risk'], 'Low risk');
    expect(words['this_month'], 'This month');
    // Every §17 word is there.
    for (final k in const ['needs_you', 'do_it', 'run_now', 'take_over', 'next_brief', 'nothing_next', 'update_server', 'sign_in', 'as_of']) {
      expect(words[k], isA<String>(), reason: k);
    }
    // Asked again: the server answers "not changed" and nothing is redrawn.
    await sync.sync();
    expect(backend.glanceCalls, [null, '"g1"']);
    expect(surface.published, hasLength(1));
    // Checked both times, so the widgets' "as of" stays away.
    expect(surface.checks, hasLength(2));
  });

  test('the app lock makes widgets private: the person\'s words go, counts and names stay', () async {
    final c = container();
    await signedIn(c);
    await c.read(appLockSettingsProvider.notifier).save(const AppLockSettings(enabled: true, userId: 'me'));
    expect(c.read(widgetsPrivateProvider), isTrue);
    final sync = carrier(c);
    await sync.sync();
    final g = surface.lastGlance;
    expect((g['flags'] as Map)['private'], isTrue);
    final needs = g['needs'] as Map;
    expect(needs['count'], 1);
    expect((needs['items'] as List).single, allOf(containsPair('text', ''), containsPair('bot', 'Ada')));
    expect((g['bots'] as List).single, allOf(containsPair('step', null), containsPair('last_text', null), containsPair('name', 'Ada')));
    expect((g['next'] as List).single, containsPair('name', ''));
    expect((g['brief'] as Map)['text'], isNull);
    expect((g['lately'] as List).single, containsPair('title', ''));
    expect((g['recent'] as List).single, containsPair('title', ''));
    expect(((g['tasks'] as Map)['items'] as List).single, containsPair('title', ''));
    expect((g['tasks'] as Map)['counts'], containsPair('todo', 1));

    // Show details in widgets: the words come back without another fetch.
    await c.read(widgetDetailsProvider.notifier).set(true);
    expect(c.read(widgetsPrivateProvider), isFalse);
    await sync.privacyChanged();
    expect((surface.lastGlance['needs'] as Map)['items'], [containsPair('text', 'Email Ana the contract')]);
    expect(backend.glanceCalls, hasLength(1));
  });

  test('a workspace that requires the app lock keeps widgets private, Show details or not', () async {
    final c = container(requiredBy: 'Acme');
    await signedIn(c);
    await c.read(widgetDetailsProvider.notifier).set(true);
    expect(c.read(widgetsPrivateProvider), isTrue);
    final sync = carrier(c);
    await sync.sync();
    expect((surface.lastGlance['flags'] as Map)['private'], isTrue);
    expect((surface.lastGlance['bots'] as List).single, containsPair('last_text', null));
  });

  test('a glance the server already made private is written private', () async {
    backend.glanceJson = {
      ...sampleGlance(),
      'flags': {'private': true, 'hide_reply_text': false},
    };
    final c = container();
    await signedIn(c);
    await carrier(c).sync();
    expect((surface.lastGlance['next'] as List).single, containsPair('name', ''));
  });

  test('fetches at most once in the gap, and once more at its end', () async {
    final c = container();
    await signedIn(c);
    final sync = carrier(c, gap: const Duration(milliseconds: 200));
    for (var i = 0; i < 5; i++) {
      sync.schedule();
    }
    await pumpEventQueue();
    expect(backend.glanceCalls, hasLength(1));
    sync.schedule();
    sync.schedule();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(backend.glanceCalls, hasLength(1), reason: 'still inside the gap');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(backend.glanceCalls, hasLength(2), reason: 'one trailing fetch for the burst');
  });

  test('signing out clears the glance and the key and redraws signed out', () async {
    final c = container();
    await signedIn(c);
    final sync = carrier(c);
    await sync.sync();
    expect(await WidgetKeyStore.load(), isNotNull);
    await backend.signOut();
    await pumpEventQueue();
    await sync.sync();
    final last = surface.published.last;
    expect(last.signedIn, isFalse);
    expect(last.glance, isNull);
    expect(jsonDecode(last.words), containsPair('sign_in', 'Open Casama to sign in'));
    expect(surface.keys.last, isNull);
    expect(await WidgetKeyStore.load(), isNull);
    // Once is enough.
    final count = surface.published.length;
    await sync.signedOut();
    expect(surface.published, hasLength(count));
  });

  test('a server without the glance gets one the app builds: bots, Needs you and today\'s spend', () async {
    backend
      ..glanceJson = null
      ..pendingApprovals = [
        Approval(
          id: 'a9', botId: botId, runId: runId, toolName: 'email.send', argsRedacted: const {}, summary: 'Send the invoice',
          risk: Risk.low, status: ApprovalStatusEnum.pending, decidedAt: null, expiresAt: DateTime(2026, 11, 19), createdAt: DateTime(2026, 11, 18),
        ),
      ];
    final c = container(bots: [backend.bot(status: BotStatusEnum.working), backend.bot(id: 'b2', name: 'Milo', status: BotStatusEnum.disabled)]);
    await signedIn(c);
    await c.read(botsProvider.future);
    await c.read(approvalsProvider.future);
    final sync = carrier(c);
    await sync.sync();
    final g = surface.lastGlance;
    expect(g['source'], 'app');
    expect(g['org_id'], orgId);
    expect(g['needs'], containsPair('count', 1));
    expect(((g['needs'] as Map)['items'] as List).single, allOf(containsPair('kind', 'approval'), containsPair('risk', 'low'), containsPair('text', 'Send the invoice')));
    final bots = g['bots'] as List;
    expect(bots.first, allOf(containsPair('name', 'Ada'), containsPair('status', 'waiting')));
    expect(bots.last, containsPair('status', 'disabled'));
    expect(g['next'], isEmpty);
    expect(g['routines'], isEmpty);
    expect((g['credits'] as Map)['billing'], isFalse);
    // No widget key from a server without the glance, and the glance isn't asked for again.
    expect(backend.widgetKeysCreated, isEmpty);
    await sync.sync();
    expect(backend.glanceCalls, hasLength(1));
  });

  test('offline: what the widgets have stays', () async {
    final c = container();
    await signedIn(c);
    final sync = carrier(c);
    await sync.sync();
    backend.glanceError = Exception('offline');
    await expectLater(sync.sync(), throwsException);
    expect(surface.published, hasLength(1));
  });

  group('the widget key', () {
    test('is made once per account and workspace, handed to native code, and kept by id', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final c = container();
      await signedIn(c);
      final sync = carrier(c);
      await sync.sync();
      expect(backend.widgetKeysCreated.single.$1, orgId);
      expect(backend.widgetKeysCreated.single.$2, 'ios');
      expect(surface.keys.single, 'cwk_secret1');
      expect((await WidgetKeyStore.load())?.id, 'wk1');
      // No Firebase token on iPhone: the widget extension registers its own push token.
      expect(backend.widgetPushTokens, isEmpty);
      // The key never goes into the glance store.
      expect(surface.published.single.glance, isNot(contains('cwk_secret1')));
      await sync.ensureKey(orgId);
      expect(backend.widgetKeysCreated, hasLength(1));
    });

    test('Android registers the phone\'s Firebase token with it; a new token makes a new key', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final c = container();
      await signedIn(c);
      final sync = carrier(c);
      await sync.sync();
      expect(backend.widgetKeysCreated.single.$2, 'android');
      expect(backend.widgetPushTokens.single, ('cwk_secret1', 'fcm-1', 'fcm'));
      (c.read(pushProvider) as _TokenPush).token = 'fcm-2';
      await sync.ensureKey(orgId);
      expect(backend.widgetKeysDeleted, ['wk1']);
      expect(backend.widgetPushTokens.last, ('cwk_secret2', 'fcm-2', 'fcm'));
      expect(surface.keys.last, 'cwk_secret2');
    });

    test('the Mac gets the key with the glance', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final c = container();
      await signedIn(c);
      await carrier(c).sync();
      expect(backend.widgetKeysCreated.single.$2, 'macos');
      expect(surface.published.single.key, 'cwk_secret1');
    });

    test('goes private on the server with the app lock', () async {
      final c = container();
      await signedIn(c);
      final sync = carrier(c);
      await sync.sync();
      await c.read(appLockSettingsProvider.notifier).save(const AppLockSettings(enabled: true, userId: 'me'));
      await sync.privacyChanged();
      expect(backend.widgetKeyPrivacy.last, ('wk1', true));
    });

    test('a server without widget keys is asked once', () async {
      backend.widgetKeysSupported = false;
      final c = container();
      await signedIn(c);
      final sync = carrier(c);
      await sync.sync();
      await sync.ensureKey(orgId);
      expect(surface.keys, isEmpty);
      expect(await WidgetKeyStore.load(), isNull);
    });
  });

  test('the app\'s carrier fetches on start and counts placed widgets once a day', () async {
    surface.placed = [
      {'kind': 'NeedsYouWidget', 'family': 'systemSmall'},
      {'kind': 'NeedsYouWidget', 'family': 'accessoryCircular'},
    ];
    final c = container();
    c.listen(glanceSyncProvider, (_, _) {});
    await c.read(signedInProvider.future);
    await pumpEventQueue();
    expect(backend.glanceCalls, isNotEmpty);
    expect(surface.published, isNotEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('casama.widgets.placed_day'), isNotNull);
  });

  test('the real phone surfaces write the §17 keys and redraw', () async {
    final homeWidget = <MethodCall>[];
    final widgets = <MethodCall>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('home_widget'), (call) async {
      homeWidget.add(call);
      return true;
    });
    messenger.setMockMethodCallHandler(widgetsChannel, (call) async {
      widgets.add(call);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(const MethodChannel('home_widget'), null);
      messenger.setMockMethodCallHandler(widgetsChannel, null);
    });

    await IosWidgetSurface().publish(glance: '{}', words: '{"a":"b"}', server: 'https://api.example', signedIn: true);
    final saved = {
      for (final c in homeWidget.where((c) => c.method == 'saveWidgetData')) (c.arguments as Map)['id']: (c.arguments as Map)['data'],
    };
    expect(saved, {'glance': '{}', 'glance_words': '{"a":"b"}', 'glance_server': 'https://api.example', 'glance_signed_in': '1', 'glance_unsupported': null});
    expect(homeWidget.first.method, 'setAppGroupId');
    expect(widgets.single.method, 'reload');

    homeWidget.clear();
    widgets.clear();
    await AndroidWidgetSurface().publish(glance: null, words: '{}', server: 's', signedIn: false);
    expect(homeWidget.where((c) => c.method == 'saveWidgetData').map((c) => (c.arguments as Map)['data']), [null, '{}', 's', null, null]);
    expect(
      homeWidget.where((c) => c.method == 'updateWidget').map((c) => (c.arguments as Map)['android']),
      androidWidgetProviders,
    );
    await AndroidWidgetSurface().setKey('k');
    expect(widgets.single.method, 'setKey');
    expect(widgets.single.arguments, {'key': 'k'});
  });
}
