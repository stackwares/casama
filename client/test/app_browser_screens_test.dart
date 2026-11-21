import 'package:casama/features/app_browser/app_browser_admin.dart';
import 'package:casama/features/app_browser/app_browser_chat.dart';
import 'package:casama/features/app_browser/app_browser_controller.dart';
import 'package:casama/features/app_browser/app_browser_screen.dart';
import 'package:casama/features/app_browser/app_browser_service.dart';
import 'package:casama/features/app_browser/app_browser_sites.dart';
import 'package:casama/features/app_browser/app_browser_settings.dart';
import 'package:casama/features/workspaces/spaces.dart';
import 'package:casama/ui/shell_layout.dart';
import 'package:casama/ui/tool_words.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_browser_fakes.dart';
import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// The phone browser's screens: the settings with the consent first, the full view, the chat's
/// card and asks, the workspace switch and the owner's panel; and none of it without the switch.
void main() {
  late FakeBackend backend;
  late FakeAppBrowserChannel channel;
  late MemoryAppBrowserTokenStore tokens;
  String? focus;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    channel = FakeAppBrowserChannel();
    tokens = MemoryAppBrowserTokenStore();
    focus = 'conv1';
  });

  Widget app(Widget child, {bool on = true}) => harness(
    backend,
    child,
    overrides: appBrowserOverrides(
      channel: channel,
      focus: () => focus,
      tokens: tokens,
      on: on,
      timings: const AppBrowserTimings(),
    ),
  );

  ProviderContainer containerOf(WidgetTester tester, Type type) =>
      ProviderScope.containerOf(tester.element(find.byType(type)));

  testWidgets('without the build switch none of the entry points show', (
    tester,
  ) async {
    await setSize(tester, const Size(400, 900));
    backend.appBrowserDevice = null;
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: Column(
            children: [
              AppBrowserDeviceTile(),
              AppBrowserWorkspaceTile(orgId: orgId),
              AppBrowserAdminCard(),
              ChromeSwitches(orgId: orgId),
              Expanded(
                child: AppBrowserChatOverlay(
                  conversationId: 'conv1',
                  layout: LayoutSize.phone,
                ),
              ),
            ],
          ),
        ),
        on: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Browser on This Phone'), findsNothing);
    expect(find.text("Bots in Members' Phone Browsers"), findsNothing);
    expect(find.text('Phone Browser'), findsNothing);
    expect(find.byKey(const Key('appBrowserWorkspaceSwitch')), findsNothing);
    // The Chrome switches are still there.
    expect(find.text("Bots in Members' Browsers"), findsOneWidget);
    // A bot's call doesn't bring up the card either.
    final c = containerOf(tester, AppBrowserChatOverlay);
    final pending = c
        .read(appBrowserProvider.notifier)
        .handle(browserCall('ask'));
    await tester.pump();
    expect(find.byKey(const Key('appBrowserTile')), findsNothing);
    expect(find.byKey(const Key('appBrowserAsk')), findsNothing);
    c.read(appBrowserProvider.notifier).answerStep(false);
    await pending;
  });

  testWidgets(
    'Device connections shows the row only when the server offers it or a device exists',
    (tester) async {
      await setSize(tester, const Size(400, 900));
      await tester.pumpWidget(
        app(const Scaffold(body: Column(children: [AppBrowserDeviceTile()]))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Browser on This Phone'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);

      backend
        ..appBrowserAvailable = false
        ..appBrowserReason = 'not_a_tester';
      final c = containerOf(tester, AppBrowserDeviceTile);
      c.invalidate(appBrowserStatusProvider);
      await tester.pumpAndSettle();
      expect(find.text('Browser on This Phone'), findsNothing);

      await backend.pairAppBrowser(
        orgId,
        name: 'iPhone',
        system: 'ios',
        clientId: 'client-1',
      );
      c.invalidate(appBrowserStatusProvider);
      await tester.pumpAndSettle();
      expect(
        find.text('Switched off: only for testers for now.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'turning it on asks first, then pairs this phone with its system and client id',
    (tester) async {
      await setSize(tester, const Size(420, 2200));
      await tester.pumpWidget(app(const AppBrowserSettingsScreen()));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Switch>(find.byKey(const Key('appBrowserSwitch'))).value,
        isFalse,
      );

      // Not Now: nothing is paired.
      await tester.tap(find.byKey(const Key('appBrowserSwitch')));
      await tester.pumpAndSettle();
      expect(
        find.text('Let Bots Use a Browser on This Phone?'),
        findsOneWidget,
      );
      expect(
        find.textContaining("sent to Casama and to the bot's AI model"),
        findsOneWidget,
      );
      expect(find.textContaining('Bots never see passwords'), findsOneWidget);
      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle();
      expect(backend.appBrowserPairs, isEmpty);

      // Allow: paired, the token kept on the phone.
      await tester.tap(find.byKey(const Key('appBrowserSwitch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('appBrowserConsentAllow')));
      await tester.pumpAndSettle();
      expect(backend.appBrowserPairs, [
        ('Android Phone', 'android', 'client-1'),
      ]);
      expect(tokens.tokens['phone1'], 'kdev_phone');
      expect(
        tester.widget<Switch>(find.byKey(const Key('appBrowserSwitch'))).value,
        isTrue,
      );

      // Which bots may use it.
      expect(find.text('Bots That May Use It'), findsOneWidget);
      await tester.tap(find.byKey(const Key('appBrowserBot-$botId')));
      await tester.pumpAndSettle();
      expect(backend.appBrowserUpdates.last, 'bots:$botId');
      expect(
        tester
            .widget<Switch>(find.byKey(const Key('appBrowserBot-$botId')))
            .value,
        isTrue,
      );

      // A kind that stays off unless switched on.
      await tester.tap(find.byKey(const Key('appBrowserKind-banking')));
      await tester.pumpAndSettle();
      expect(backend.appBrowserUpdates.last, 'kinds:banking');

      // Switching it off keeps the pairing.
      await tester.tap(find.byKey(const Key('appBrowserSwitch')));
      await tester.pumpAndSettle();
      expect(backend.appBrowserUpdates.last, 'enabled:false');
      expect(backend.appBrowserDevice, isNotNull);
      // Back on: no second consent, no second pairing.
      await tester.tap(find.byKey(const Key('appBrowserSwitch')));
      await tester.pumpAndSettle();
      expect(find.text('Let Bots Use a Browser on This Phone?'), findsNothing);
      expect(backend.appBrowserUpdates.last, 'enabled:true');
      expect(backend.appBrowserPairs.length, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'sites can be removed, browsing data cleared and the phone unpaired',
    (tester) async {
      await setSize(tester, const Size(420, 2200));
      await backend.pairAppBrowser(
        orgId,
        name: 'iPhone',
        system: 'ios',
        clientId: 'client-1',
      );
      await backend.updateAppBrowser(
        'phone1',
        allowedSites: ['shop.example'],
        blockedSites: ['ads.example'],
      );
      backend.appBrowserUpdates.clear();
      tokens.tokens['phone1'] = 'kdev_phone';
      await tester.pumpWidget(app(const AppBrowserSettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('shop.example'), findsOneWidget);
      expect(find.text('ads.example'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('appBrowserRemoveSite-ads.example')),
      );
      await tester.pumpAndSettle();
      expect(backend.appBrowserUpdates.last, 'blocked:');
      expect(find.text('ads.example'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('appBrowserClearData')));
      await tester.tap(find.byKey(const Key('appBrowserClearData')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('appBrowserClearDataConfirm')));
      await tester.pumpAndSettle();
      expect(channel.cleared, [null]);

      await tester.ensureVisible(find.byKey(const Key('appBrowserUnpair')));
      await tester.tap(find.byKey(const Key('appBrowserUnpair')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('appBrowserUnpairConfirm')));
      await tester.pumpAndSettle();
      expect(backend.appBrowserDevice, isNull);
      expect(tokens.tokens, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('the chat shows the live page and the ask, answerable in place', (
    tester,
  ) async {
    await setSize(tester, const Size(400, 800));
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: AppBrowserChatOverlay(
            conversationId: 'conv1',
            layout: LayoutSize.phone,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appBrowserTile')), findsNothing);
    final c = containerOf(tester, AppBrowserChatOverlay);
    final browser = c.read(appBrowserProvider.notifier);
    await tester.runAsync(() => browser.handle(browserCall('snapshot')));
    await tester.pump();
    expect(find.byKey(const Key('appBrowserTile')), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(channel.calls.where((c) => c.startsWith('screenshot')), isNotEmpty);

    final pending = browser.handle(
      browserCall(
        'ask',
        args: {
          'reason': 'This posts the comment',
          'step': 'click',
          'name': 'Post',
        },
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('appBrowserAsk')), findsOneWidget);
    expect(find.text('Allow Ada to do this?'), findsOneWidget);
    expect(find.text('This posts the comment'), findsOneWidget);
    await tester.tap(find.byKey(const Key('appBrowserAllow')));
    await tester.pump();
    expect((await pending)['text'], 'allow');
    await tester.pump();
    expect(find.byKey(const Key('appBrowserAsk')), findsNothing);

    // Another chat's run doesn't show here.
    focus = 'conv2';
    await tester.runAsync(
      () => browser.handle(
        browserCall('snapshot', run: 'run2', conversation: 'conv2'),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('appBrowserTile')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'the full view: the bot, Stop, Take Over and Hand Back, and the site ask',
    (tester) async {
      await setSize(tester, const Size(400, 800));
      await tester.pumpWidget(app(const AppBrowserScreen()));
      await tester.pumpAndSettle();
      final browser = containerOf(
        tester,
        AppBrowserScreen,
      ).read(appBrowserProvider.notifier);
      await tester.runAsync(
        () => browser.handle(
          browserCall('open', args: {'url': 'https://shop.example/'}),
        ),
      );
      await tester.pump();
      expect(find.text('shop.example'), findsOneWidget);
      expect(find.byKey(const Key('appBrowserLock')), findsOneWidget);
      expect(find.text('Ada is working'), findsOneWidget);
      expect(find.byKey(const Key('fakeWebArea')), findsOneWidget);

      await tester.tap(find.byKey(const Key('appBrowserTakeOver')));
      await tester.pump();
      expect(find.text('Ada is paused while you use the page'), findsOneWidget);
      await tester.tap(find.byKey(const Key('appBrowserHandBack')));
      await tester.pump();
      expect(find.byKey(const Key('appBrowserTakeOver')), findsOneWidget);

      // A new site asks over the page.
      // The gate's lists were loaded in real time above, so this runs in real time too.
      late Future<Map<String, Object?>> pending;
      await tester.runAsync(() async {
        pending = browser.handle(
          browserCall(
            'open',
            args: {'url': 'https://news.example/'},
            policy: const AppSitePolicy(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(find.text('Ada wants to open news.example'), findsOneWidget);
      await tester.tap(find.byKey(const Key('appBrowserNever')));
      await tester.pump();
      final denied = await tester.runAsync(() => pending);
      expect(denied?['code'], 'asked_denied');

      // A handoff.
      await tester.runAsync(
        () => browser.handle(
          browserCall('handoff', args: {'reason': 'Type the code we sent you'}),
        ),
      );
      await tester.pump();
      expect(find.text('Your turn'), findsOneWidget);
      expect(find.text('Type the code we sent you'), findsOneWidget);

      await tester.tap(find.byKey(const Key('appBrowserStop')));
      await tester.pump();
      expect(find.text('Ada is working'), findsNothing);
      expect(find.byKey(const Key('appBrowserStop')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Sign In to a Site: an address, then Let My Bots Use This Site', (
    tester,
  ) async {
    await setSize(tester, const Size(400, 800));
    await backend.pairAppBrowser(
      orgId,
      name: 'iPhone',
      system: 'ios',
      clientId: 'client-1',
    );
    await tester.pumpWidget(app(const AppBrowserScreen(person: true)));
    await tester.pumpAndSettle();
    final browser = containerOf(
      tester,
      AppBrowserScreen,
    ).read(appBrowserProvider.notifier);
    browser.device = backend.appBrowserDevice;
    await tester.enterText(
      find.byKey(const Key('appBrowserAddress')),
      'mail.example',
    );
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    await tester.pump();
    expect(channel.calls, contains('load https://mail.example'));
    await tester.tap(find.byKey(const Key('appBrowserAllowSite')));
    await tester.pumpAndSettle();
    expect(backend.appBrowserDevice!.allowedSites, ['mail.example']);
    expect(
      find.text('mail.example added. Your bots can use it here.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'workspace admins switch it off beside Bots in Members\' Browsers',
    (tester) async {
      await setSize(tester, const Size(900, 1200));
      await tester.pumpWidget(
        app(const Scaffold(body: ChromeSwitches(orgId: orgId))),
      );
      await tester.pumpAndSettle();
      expect(find.text("Bots in Members' Phone Browsers"), findsOneWidget);
      await tester.tap(find.byKey(const Key('appBrowserWorkspaceSwitch')));
      await tester.pumpAndSettle();
      expect(backend.appBrowserWorkspaceOn, isFalse);
    },
  );

  testWidgets(
    'the owner sets the stage, testers, reasons and systems, and sees the numbers',
    (tester) async {
      await setSize(tester, const Size(700, 1600));
      await tester.pumpWidget(
        app(const Scaffold(body: AppBrowserAdminSheet())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Last 14 Days'), findsOneWidget);
      expect(find.text('Runs on a phone'), findsOneWidget);
      await tester.tap(find.text('Testers').first);
      await tester.enterText(
        find.byKey(const Key('adminAppBrowserTesters')),
        'user-1\nuser-2',
      );
      await tester.tap(find.byKey(const Key('adminAppBrowserSystem-ios')));
      await tester.tap(find.byKey(const Key('adminAppBrowserBlocked')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('adminAppBrowserSave')));
      await tester.tap(find.byKey(const Key('adminAppBrowserSave')));
      await tester.pumpAndSettle();
      final saved = backend.appBrowserSaves.single;
      expect(saved.stage, SaveAppBrowserRequestStageEnum.testers);
      expect(saved.testers, ['user-1', 'user-2']);
      expect(saved.reasons?.blocked, isTrue);
      expect([for (final s in saved.systems!) s.value], ['ios', 'android']);
    },
  );

  test('browser steps that ran on the phone say so', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(
      toolWords(l10n, 'browser.open', {
        'url': 'https://shop.example/a',
        'where': 'phone',
      }).detail,
      endsWith('on this phone'),
    );
    expect(
      toolWords(l10n, 'browser.click', {'where': 'phone'}).detail,
      'on this phone',
    );
    expect(toolWords(l10n, 'browser.click', {}).detail, isNull);
  });
}
