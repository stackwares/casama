import 'package:casama/core/backend.dart' show ChatMessageView;
import 'package:casama/features/chat/chat_controller.dart' show chatControllerProvider;
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/permissions/companion_hook.dart';
import 'package:casama/features/permissions/permissions_card.dart';
import 'package:casama/features/permissions/permissions_platform.dart';
import 'package:casama/features/permissions/permissions_reporter.dart';
import 'package:casama/features/permissions/permissions_screen.dart';
import 'package:casama/features/permissions/permissions_view.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const mac = 'computer:11111111-1111-4111-8111-111111111111';
const otherMac = 'computer:55555555-5555-4555-8555-555555555555';
const phone = 'source:66666666-6666-4666-8666-666666666666';

/// This device's permissions, without any system (D-376).
class FakePermissionsPlatform implements PermissionsPlatform {
  FakePermissionsPlatform(this.platform, [Map<String, String>? states]) : states = states ?? {};
  @override
  final String platform;
  final Map<String, String> states;

  /// What a request leaves the permission at.
  String answer = 'granted';
  final requested = <String>[];
  final opened = <String>[];
  var relaunched = 0;
  var checks = 0;

  @override
  Future<Map<String, String>> check(Iterable<String> ids) async {
    checks++;
    return {for (final id in ids) id: states[id] ?? 'not_asked'};
  }

  @override
  Future<String> request(String id) async {
    requested.add(id);
    return states[id] = answer;
  }

  @override
  Future<bool> openSettings(String id) async {
    opened.add(id);
    return true;
  }

  @override
  Future<bool> relaunch() async {
    relaunched++;
    return true;
  }
}

DevicePermissions device(String ref, String name, String platform, Map<String, String> states, {bool online = true}) => DevicePermissions(
  deviceRef: ref,
  type: ref.startsWith('computer:') ? DevicePermissionType.computer : DevicePermissionType.source_,
  id: ref.substring(ref.indexOf(':') + 1),
  name: name,
  platform: platform,
  permissions: {for (final e in states.entries) e.key: OsPermissionState.values.firstWhere((s) => s.value == e.value)},
  reportedAt: DateTime(2026, 11, 18),
  online: online,
);

PermissionsRequest request(String ref, String name, String platform, List<String> ids) =>
    PermissionsRequest(deviceRef: ref, deviceName: name, platform: platform, permissions: ids, reason: 'So I can see and click in your apps', botId: botId);

void main() {
  late FakeBackend backend;
  late FakePermissionsPlatform platform;
  late PermissionsReporter reporter;
  late Set<String> myRefs;
  var casamaOpened = 0;

  void setUpDevice({String os = 'macos', Map<String, String>? states, Set<String> refs = const {mac}}) {
    backend = FakeBackend();
    platform = FakePermissionsPlatform(os, states);
    myRefs = refs;
    casamaOpened = 0;
    reporter = PermissionsReporter(
      backend: backend,
      platform: platform,
      computerId: () async => myRefs.where((r) => r.startsWith('computer:')).map((r) => r.substring(9)).firstOrNull,
      sourceId: () async => myRefs.where((r) => r.startsWith('source:')).map((r) => r.substring(7)).firstOrNull,
      openCasamaSettings: () => casamaOpened++,
      interval: const Duration(hours: 1),
    );
  }

  List<Object> overrides() => [permissionsReporterProvider.overrideWithValue(reporter), permissionsPlatformProvider.overrideWithValue(platform)];

  Future<List<String>> pumpCard(WidgetTester tester, PermissionsRequest r) async {
    final sentText = <String>[];
    await setSize(tester, const Size(500, 900));
    await tester.pumpWidget(
      harness(
        backend,
        Scaffold(
          body: SingleChildScrollView(
            child: PermissionsCard(request: r, onContinue: (t) async => sentText.add(t)),
          ),
        ),
        overrides: overrides(),
      ),
    );
    await tester.pumpAndSettle();
    return sentText;
  }

  group('the card on the device it names', () {
    testWidgets('rows show each state and Turn on asks the system here', (tester) async {
      setUpDevice(states: {'accessibility': 'not_asked', 'screen_recording': 'denied'});
      backend.permissionDevices.add(device(mac, 'MacBook Pro', 'macos', {'accessibility': 'not_asked', 'screen_recording': 'denied'}));
      await pumpCard(tester, request(mac, 'MacBook Pro', 'macos', ['accessibility', 'screen_recording']));
      expect(find.text('Turn these on for MacBook Pro'), findsOneWidget);
      expect(find.text('Accessibility'), findsOneWidget);
      expect(find.text('Not asked yet'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      // Never asked: the system prompt; said no: its settings.
      expect(find.descendant(of: find.byKey(const Key('permTurnOn-accessibility')), matching: find.text('Turn on')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('permTurnOn-screen_recording')), matching: find.text('Open settings')), findsOneWidget);
      await tester.tap(find.byKey(const Key('permTurnOn-accessibility')));
      await tester.pumpAndSettle();
      expect(platform.requested, ['accessibility']);
      expect(find.byKey(const Key('permTurnOn-accessibility')), findsNothing);
      // The device reported again after the ask.
      expect(backend.reportedPermissions[mac]?['accessibility'], 'granted');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Screen Recording turned on asks for a restart before Continue', (tester) async {
      setUpDevice(states: {'accessibility': 'granted', 'screen_recording': 'denied'});
      backend.permissionDevices.add(device(mac, 'MacBook Pro', 'macos', {'accessibility': 'granted', 'screen_recording': 'denied'}));
      final sent = await pumpCard(tester, request(mac, 'MacBook Pro', 'macos', ['accessibility', 'screen_recording']));
      expect(tester.widget<FilledButton>(find.byKey(const Key('permContinue'))).onPressed, isNull);
      // The person flips the switch in System Settings; the next check sees it.
      platform.states['screen_recording'] = 'granted';
      await reporter.report();
      await tester.pumpAndSettle();
      expect(find.text('Restart Casama to finish'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('permContinue'))).onPressed, isNull);
      await tester.tap(find.byKey(const Key('permRestart-screen_recording')));
      await tester.pumpAndSettle();
      expect(platform.relaunched, 1);
      expect(tester.widget<FilledButton>(find.byKey(const Key('permContinue'))).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('permContinue')));
      await tester.pumpAndSettle();
      expect(sent, ["They're on, go ahead."]);
      expect(find.text('Turned on'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Shared folders opens Use this computer', (tester) async {
      setUpDevice();
      backend.permissionDevices.add(device(mac, 'MacBook Pro', 'macos', {'shared_folders': 'denied'}));
      await pumpCard(tester, request(mac, 'MacBook Pro', 'macos', ['shared_folders']));
      expect(find.descendant(of: find.byKey(const Key('permTurnOn-shared_folders')), matching: find.text('Choose')), findsOneWidget);
      await tester.tap(find.byKey(const Key('permTurnOn-shared_folders')));
      await tester.pumpAndSettle();
      expect(casamaOpened, 1);
      expect(platform.requested, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the card on another device', () {
    testWidgets('a computer opens the page there at once', (tester) async {
      setUpDevice(os: 'ios', refs: {phone});
      backend.permissionDevices
        ..add(device(phone, 'iPhone', 'ios', {}))
        ..add(device(otherMac, 'MacBook Pro', 'macos', {'accessibility': 'denied'}));
      await pumpCard(tester, request(otherMac, 'MacBook Pro', 'macos', ['accessibility']));
      await tester.tap(find.byKey(const Key('permTurnOn-accessibility')));
      await tester.pumpAndSettle();
      expect(backend.permissionAsks, [(otherMac, 'accessibility', 'request', botId)]);
      expect(platform.requested, isEmpty);
      expect(find.text('Opened on MacBook Pro'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a phone gets a notification to tap', (tester) async {
      setUpDevice(refs: {mac});
      backend.permissionDevices
        ..add(device(mac, 'MacBook Pro', 'macos', {}))
        ..add(device(phone, 'iPhone', 'ios', {'location_always': 'not_asked'}));
      await pumpCard(tester, request(phone, 'iPhone', 'ios', ['location_always']));
      await tester.tap(find.byKey(const Key('permTurnOn-location_always')));
      await tester.pumpAndSettle();
      expect(backend.permissionAsks.single.$1, phone);
      expect(find.text('Sent to iPhone: tap the notification there'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an offline computer says so and sends nothing', (tester) async {
      setUpDevice(os: 'ios', refs: {phone});
      backend.permissionDevices.add(device(otherMac, 'MacBook Pro', 'macos', {'accessibility': 'denied'}, online: false));
      await pumpCard(tester, request(otherMac, 'MacBook Pro', 'macos', ['accessibility']));
      await tester.tap(find.byKey(const Key('permTurnOn-accessibility')));
      await tester.pumpAndSettle();
      expect(backend.permissionAsks, isEmpty);
      expect(find.text('MacBook Pro is offline'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('someone else\'s device is read only', (tester) async {
      setUpDevice(refs: {mac});
      backend.permissionDevices.add(device(mac, 'MacBook Pro', 'macos', {}));
      await pumpCard(tester, request(otherMac, 'Sam\'s Mac', 'macos', ['accessibility']));
      expect(find.text('Only Sam\'s Mac\'s owner can turn these on'), findsOneWidget);
      expect(find.byKey(const Key('permTurnOn-accessibility')), findsNothing);
      expect(find.byKey(const Key('permNotNow')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Not now snoozes the bot\'s ask and folds the card', (tester) async {
    setUpDevice();
    backend.permissionDevices.add(device(mac, 'MacBook Pro', 'macos', {'accessibility': 'denied'}));
    await pumpCard(tester, request(mac, 'MacBook Pro', 'macos', ['accessibility']));
    await tester.tap(find.byKey(const Key('permNotNow')));
    await tester.pumpAndSettle();
    final snooze = backend.permissionSnoozes.single;
    expect((snooze.$1, snooze.$2), (mac, botId));
    expect(snooze.$3, ['accessibility']);
    expect(find.text('Not now'), findsOneWidget);
    expect(find.byKey(const Key('permTurnOn-accessibility')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a permission this app doesn\'t know says to update', (tester) async {
    setUpDevice();
    backend.permissionDevices.add(device(mac, 'MacBook Pro', 'macos', {}));
    await pumpCard(tester, request(mac, 'MacBook Pro', 'macos', ['teleport']));
    expect(find.text('Update Casama to turn this on here'), findsOneWidget);
    expect(find.byKey(const Key('permTurnOn-teleport')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  group('in a chat', () {
    Map<String, dynamic> payload() => {
      'device_ref': mac,
      'device_name': 'MacBook Pro',
      'platform': 'macos',
      'permissions': ['accessibility', 'screen_recording'],
      'reason': 'So I can see and click in your apps',
      'bot_id': botId,
    };

    testWidgets('the event shows one card, a replay adds none, and a reload keeps it', (tester) async {
      setUpDevice();
      backend.permissionDevices.add(device(mac, 'MacBook Pro', 'macos', {}));
      await setSize(tester, const Size(500, 900));
      await tester.pumpWidget(
        harness(
          backend,
          const ChatScreen(botId: botId, conversationId: convId),
          overrides: overrides(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('messageInput')), 'click around my Mac');
      await tester.pump();
      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pump();
      backend.runEventsController.add(ev(1, 'device.permission_needed', payload()));
      backend.runEventsController.add(ev(2, 'device.permission_needed', payload()));
      backend.runEventsController.add(ev(3, 'run.completed', {'final_message_id': null}));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chatPermissions')), findsOneWidget);
      expect(find.text('Turn these on for MacBook Pro'), findsOneWidget);
      backend.storedMessages = [
        ChatMessageView(id: 'm1', role: 'user', text: 'click around my Mac', runId: runId, createdAt: DateTime(2026, 11, 18, 9)),
        ChatMessageView(id: 'm2', role: 'assistant', text: 'Tap Turn on in the card.', runId: runId, createdAt: DateTime(2026, 11, 18, 9, 1)),
      ];
      final chat = ProviderScope.containerOf(tester.element(find.byType(ChatScreen))).read(chatControllerProvider(botId).notifier);
      await chat.open(convId);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chatPermissions')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a chat opened later brings the card back from its run', (tester) async {
      setUpDevice();
      backend
        ..permissionDevices.add(device(mac, 'MacBook Pro', 'macos', {}))
        ..storedMessages = [
          ChatMessageView(id: 'm1', role: 'user', text: 'click around my Mac', runId: runId, createdAt: DateTime(2026, 11, 18, 9)),
          ChatMessageView(id: 'm2', role: 'assistant', text: 'Tap Turn on in the card.', runId: runId, createdAt: DateTime(2026, 11, 18, 9, 1)),
        ]
        ..storedEvents = [ev(1, 'device.permission_needed', payload())];
      await setSize(tester, const Size(500, 900));
      await tester.pumpWidget(
        harness(
          backend,
          const ChatScreen(botId: botId, conversationId: convId),
          overrides: overrides(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chatPermissions')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the permissions screen and its link', () {
    testWidgets('lists this device\'s permissions with their buttons', (tester) async {
      setUpDevice(states: {'accessibility': 'granted'});
      backend.permissionDevices.add(device(mac, 'MacBook Pro', 'macos', {'accessibility': 'granted', 'shared_folders': 'granted'}));
      await setSize(tester, const Size(500, 1400));
      await tester.pumpWidget(harness(backend, const DevicePermissionsScreen(), overrides: overrides()));
      await tester.pumpAndSettle();
      for (final id in ['microphone', 'accessibility', 'screen_recording', 'automation', 'full_disk', 'shared_folders']) {
        expect(find.byKey(Key('permRow-$id')), findsOneWidget, reason: id);
      }
      expect(find.byKey(const Key('permRow-camera')), findsNothing);
      expect(find.byKey(const Key('permTurnOn-accessibility')), findsNothing);
      await tester.tap(find.byKey(const Key('permTurnOn-full_disk')));
      await tester.pumpAndSettle();
      // Full Disk Access has no prompt: its settings page.
      expect(platform.opened, ['full_disk']);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a notification\'s link runs the ask on the device it names', (tester) async {
      setUpDevice(os: 'ios', refs: {phone});
      backend.permissionDevices.add(device(phone, 'iPhone', 'ios', {}));
      await setSize(tester, const Size(500, 1400));
      await tester.pumpWidget(
        harness(
          backend,
          const DevicePermissionsScreen(device: phone, ask: 'location_always', action: 'request'),
          overrides: overrides(),
        ),
      );
      await tester.pumpAndSettle();
      expect(platform.requested, ['location_always']);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a link for another device says so and asks nothing', (tester) async {
      setUpDevice(os: 'ios', refs: {phone});
      backend.permissionDevices
        ..add(device(phone, 'iPhone', 'ios', {}))
        ..add(device('source:77777777-7777-4777-8777-777777777777', 'iPad', 'ios', {}));
      await setSize(tester, const Size(500, 1400));
      await tester.pumpWidget(
        harness(
          backend,
          const DevicePermissionsScreen(device: 'source:77777777-7777-4777-8777-777777777777', ask: 'camera', action: 'request'),
          overrides: overrides(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('This was for iPad. Open Casama there to turn it on.'), findsOneWidget);
      expect(platform.requested, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the reporter', () {
    test('sends the whole map to each of this device\'s refs, without Casama\'s own settings', () async {
      setUpDevice(states: {'accessibility': 'granted'}, refs: {mac, 'source:88888888-8888-4888-8888-888888888888'});
      await reporter.report();
      expect(backend.reportedPermissions.keys, unorderedEquals([mac, 'source:88888888-8888-4888-8888-888888888888']));
      final sentMap = backend.reportedPermissions[mac]!;
      expect(sentMap['accessibility'], 'granted');
      expect(sentMap['screen_recording'], 'not_asked');
      expect(sentMap.containsKey('shared_folders'), isFalse);
      expect(sentMap.containsKey('camera'), isFalse);
    });

    test('a card tapped elsewhere reaches it through the companion\'s socket', () async {
      setUpDevice(states: {'screen_recording': 'denied'});
      reporter.start();
      addTearDown(reporter.dispose);
      expect(companionPermissionHandler, isNotNull);
      await companionPermissionHandler!({'type': 'permission', 'permission': 'screen_recording', 'do': 'open_settings', 'bot_id': null});
      expect(platform.opened, ['screen_recording']);
      await companionPermissionHandler!({'type': 'permission', 'permission': 'accessibility', 'do': 'request'});
      expect(platform.requested, ['accessibility']);
      await companionPermissionHandler!({'type': 'permission', 'permission': 'screen_recording', 'do': 'relaunch'});
      expect(platform.relaunched, 1);
      reporter.dispose();
      expect(companionPermissionHandler, isNull);
    });
  });

  testWidgets('Health on an iPhone: Turn on first, then Open Health once it reads as off', (tester) async {
    Future<void> row(String state) => tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: PermissionRow(id: 'health', platform: 'ios', state: state, onTurnOn: () {})),
    ));
    await row('not_asked');
    expect(find.text('Turn on'), findsOneWidget);
    expect(tester.getSemantics(find.byKey(const Key('permTurnOn-health'))).label, contains('Health'));
    await row('denied');
    expect(find.text('Open Health'), findsOneWidget);
    await row('granted');
    expect(find.byKey(const Key('permTurnOn-health')), findsNothing);
  });
}
