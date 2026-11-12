import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/remote_config.dart';
import 'package:casama_app/features/admin/app_settings_card.dart';
import 'package:casama_app/features/bots/plugin_directory.dart';
import 'package:casama_app/features/routines/routine_ideas.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:casama_app/ui/lucide_names.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

Widget _app(FakeBackend backend, Widget child, {String version = '0.8.0'}) =>
    ProviderScope(
      overrides: [
        backendProvider.overrideWithValue(backend),
        appVersionProvider.overrideWith((ref) async => version),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

RemoteAppConfig _config({
  Map<String, String> min = const {},
  String? maintenance,
  List<Announcement> announcements = const [],
}) => RemoteAppConfig(
  minVersions: RemoteAppConfigMinVersions(
    ios: min['ios'],
    android: min['android'],
  ),
  updateUrls: RemoteAppConfigUpdateUrls(ios: 'https://apps.apple.com/app/id1'),
  maintenance: maintenance == null
      ? null
      : RemoteAppConfigMaintenance(message: maintenance),
  announcements: announcements,
  flags: const {'new_home': true},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('compares versions and checks when an announcement applies', () {
    expect(compareVersions('0.8.0', '0.10.0'), -1);
    expect(compareVersions('1.0.0+12', '1.0.0'), 0);
    final a = Announcement(
      id: 'a',
      title: 'Hi',
      body: '',
      level: AnnouncementLevelEnum.info,
      platforms: [AnnouncementPlatformsEnum.ios],
      minVersion: '0.9.0',
    );
    expect(announcementApplies(a, platform: 'ios', version: '0.9.1'), isTrue);
    expect(
      announcementApplies(a, platform: 'android', version: '0.9.1'),
      isFalse,
    );
    expect(announcementApplies(a, platform: 'ios', version: '0.8.0'), isFalse);
    final ended = Announcement(
      id: 'b',
      title: 'Old',
      body: '',
      level: AnnouncementLevelEnum.info,
      endsAt: '2020-01-01T00:00:00Z',
    );
    expect(
      announcementApplies(ended, platform: 'ios', version: '1.0.0'),
      isFalse,
    );
    expect(lucideByName('house'), isNotNull);
    expect(lucideByName('not-an-icon'), isNull);
  });

  testWidgets('an app below the minimum version must update', (tester) async {
    final backend = FakeBackend()
      ..remoteConfig = _config(min: {'ios': '0.9.0'});
    await tester.pumpWidget(
      _app(
        backend,
        const RemoteConfigGate(platform: 'ios', child: Text('the app')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('remoteUpdate')), findsOneWidget);
    expect(find.byKey(const Key('remoteUpdateButton')), findsOneWidget);
    expect(find.text('the app'), findsNothing);
  });

  testWidgets('other platforms and newer apps carry on', (tester) async {
    final backend = FakeBackend()
      ..remoteConfig = _config(min: {'ios': '0.9.0'});
    await tester.pumpWidget(
      _app(
        backend,
        const RemoteConfigGate(platform: 'android', child: Text('the app')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('the app'), findsOneWidget);
  });

  testWidgets('maintenance covers the app with the owner\'s message', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..remoteConfig = _config(maintenance: 'Back at 3 pm.');
    await tester.pumpWidget(
      _app(
        backend,
        const RemoteConfigGate(platform: 'ios', child: Text('the app')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Back at 3 pm.'), findsOneWidget);
    expect(find.text('the app'), findsNothing);
  });

  testWidgets(
    'an announcement shows until it is dismissed, and stays dismissed',
    (tester) async {
      final backend = FakeBackend()
        ..remoteConfig = _config(
          announcements: [
            Announcement(
              id: 'launch',
              title: "We're live",
              body: 'Thanks!',
              level: AnnouncementLevelEnum.info,
            ),
          ],
        );
      await tester.pumpWidget(
        _app(
          backend,
          const RemoteConfigGate(platform: 'ios', child: Text('the app')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("We're live"), findsOneWidget);
      expect(find.text('the app'), findsOneWidget);
      await tester.tap(find.byKey(const Key('announcementDismiss')));
      await tester.pumpAndSettle();
      expect(find.text("We're live"), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getStringList(
          'remoteConfig.dismissed',
        ),
        ['launch'],
      );
    },
  );

  testWidgets('a routine idea fills in the routine', (tester) async {
    final backend = FakeBackend()
      ..routineIdeaList.add(
        RoutineIdea(
          id: 'weekly-review',
          name: 'Weekly review',
          description: 'Fridays.',
          category: RoutineIdeaCategoryEnum.work,
          icon: 'calendar-check',
          instructionsMd: 'Write my weekly review.',
          scheduleCron: '0 16 * * 5',
          featured: true,
          author: ContentAuthor(name: 'Casama'),
        ),
      );
    RoutineIdea? picked;
    await tester.pumpWidget(
      _app(backend, RoutineIdeasStrip(onPick: (i) => picked = i)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('routineIdea-weekly-review')));
    expect(picked?.scheduleCron, '0 16 * * 5');
  });

  testWidgets('no ideas take no room', (tester) async {
    await tester.pumpWidget(
      _app(FakeBackend(), RoutineIdeasStrip(onPick: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routineIdeas')), findsNothing);
  });

  testWidgets('a reviewed plugin is picked with its commit', (tester) async {
    final backend = FakeBackend()
      ..directoryPlugins.add(
        DirectoryPlugin(
          id: 'hello-casama',
          name: 'Hello Casama',
          description: 'An example.',
          url: 'https://github.com/stackwares/casama/tree/main/examples/hello-plugin',
          commit: '6efc18250f69b9c2938b689076384237324136e3',
          adds: const ['A skill'],
          author: ContentAuthor(name: 'Casama'),
        ),
      );
    DirectoryPlugin? picked;
    await tester.pumpWidget(
      _app(
        backend,
        SingleChildScrollView(
          child: PluginDirectoryList(onPick: (p) => picked = p),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('directoryPlugin-hello-casama')));
    expect(picked?.commit, '6efc18250f69b9c2938b689076384237324136e3');
  });

  testWidgets('the owner edits the remote settings as JSON', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend();
    await tester.pumpWidget(_app(backend, const AppSettingsCard()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminAppSettings')));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('adminAppSettingsJson'));
    expect(
      tester.widget<TextField>(field).controller!.text,
      contains('"min_versions"'),
    );
    await tester.enterText(field, '{not json');
    await tester.tap(find.byKey(const Key('adminAppSettingsSave')));
    await tester.pumpAndSettle();
    expect(find.textContaining("isn't valid JSON"), findsOneWidget);
    await tester.enterText(field, '{"min_versions": {"ios": "0.9.0"}}');
    await tester.tap(find.byKey(const Key('adminAppSettingsSave')));
    await tester.pumpAndSettle();
    expect(backend.remoteConfig.minVersions.ios, '0.9.0');
    expect(field, findsNothing);
  });
}
