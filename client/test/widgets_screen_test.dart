// Settings → Widgets (D-405 §6.8): Add to Home screen on Android, how to add on iPhone and the
// Mac, the Lock Screen on iPhone, Show details in widgets and pinned bots.
import 'package:casama/core/providers.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/features/widgets/widget_settings.dart';
import 'package:casama/features/widgets/widgets_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

class _Bots extends BotsNotifier {
  _Bots(this.initial);
  final List<Bot> initial;
  @override
  Future<List<Bot>> build() async => initial;
}

class _Pinner implements WidgetPinner {
  final pinned = <String>[];
  var ok = true;
  @override
  Future<bool> pin(WidgetKind kind) async {
    pinned.add(kind.androidProvider);
    return ok;
  }

  @override
  Future<bool> pinBot(Bot bot) async {
    pinned.add('bot:${bot.id}');
    return ok;
  }
}

void main() {
  late FakeBackend backend;
  late _Pinner pinner;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLockSettingsNotifier.resetForTest();
    backend = FakeBackend();
    pinner = _Pinner();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<ProviderContainer> open(WidgetTester tester, TargetPlatform platform, {bool canPin = true, String? requiredBy}) async {
    debugDefaultTargetPlatformOverride = platform;
    await setSize(tester, const Size(800, 3000));
    await tester.pumpWidget(
      harness(
        backend,
        const WidgetsScreen(),
        overrides: [
          botsProvider.overrideWith(() => _Bots([backend.bot()])),
          pinWidgetSupportedProvider.overrideWith((ref) async => canPin),
          widgetPinnerProvider.overrideWithValue(pinner),
          if (requiredBy != null) appLockRequiredByProvider.overrideWithValue(requiredBy),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(WidgetsScreen)));
  }

  testWidgets('Android: every widget has Add to Home screen, and bots can be pinned', (tester) async {
    await open(tester, TargetPlatform.android);
    expect(find.text('Needs you'), findsWidgets);
    expect(find.text('See which bots are waiting on you'), findsOneWidget);
    expect(find.text('Add to Home screen'), findsNWidgets(WidgetKind.values.length));
    expect(find.byKey(const Key('widgetsHowTo')), findsNothing);
    expect(find.text('Lock Screen and controls'), findsNothing);
    await tester.tap(find.byKey(const Key('addWidget-needsYou')));
    await tester.pump();
    expect(pinner.pinned, ['NeedsYouWidget']);
    await tester.tap(find.descendant(of: find.byKey(const Key('pinBot-$botId')), matching: find.text('Pin')));
    await tester.pump();
    expect(pinner.pinned.last, 'bot:$botId');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Android: a launcher that can\'t place widgets gets the steps instead', (tester) async {
    await open(tester, TargetPlatform.android, canPin: false);
    expect(find.text('Add to Home screen'), findsNothing);
    expect(find.byKey(const Key('widgetsHowTo')), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iPhone: how to add, the Lock Screen and controls; no Add buttons or pinned bots', (tester) async {
    await open(tester, TargetPlatform.iOS);
    expect(find.text('Add to Home screen'), findsNothing);
    expect(find.textContaining('tap Edit, then Add Widget'), findsOneWidget);
    expect(find.text('Lock Screen and controls'), findsOneWidget);
    expect(find.textContaining('Add a Control'), findsOneWidget);
    expect(find.text('Pin a bot to your Home screen'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Mac: how to add, no Lock Screen section', (tester) async {
    await open(tester, TargetPlatform.macOS);
    expect(find.textContaining('Edit Widgets'), findsOneWidget);
    expect(find.text('Lock Screen and controls'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Show details in widgets: off and disabled without the app lock, a switch with it', (tester) async {
    final c = await open(tester, TargetPlatform.iOS);
    Switch details() => tester.widget<Switch>(find.byKey(const Key('widgetsShowDetails')));
    expect(details().value, isFalse);
    expect(details().onChanged, isNull);
    expect(find.textContaining('Only matters while the app lock is on'), findsOneWidget);

    await c.read(appLockSettingsProvider.notifier).save(const AppLockSettings(enabled: true, userId: 'me'));
    await tester.pumpAndSettle();
    expect(details().onChanged, isNotNull);
    expect(c.read(widgetsPrivateProvider), isTrue);
    await tester.tap(find.byKey(const Key('widgetsShowDetails')));
    await tester.pumpAndSettle();
    expect(c.read(widgetDetailsProvider), isTrue);
    expect(c.read(widgetsPrivateProvider), isFalse);
    expect((await SharedPreferences.getInstance()).getBool(WidgetDetails.prefKey), isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a workspace that requires the app lock keeps Show details off', (tester) async {
    final c = await open(tester, TargetPlatform.android, requiredBy: 'Acme');
    await c.read(widgetDetailsProvider.notifier).set(true);
    await tester.pumpAndSettle();
    final details = tester.widget<Switch>(find.byKey(const Key('widgetsShowDetails')));
    expect(details.value, isFalse);
    expect(details.onChanged, isNull);
    expect(find.text('Acme requires the app lock, so widgets keep details hidden.'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
