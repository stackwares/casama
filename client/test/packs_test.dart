// Packs in the app (docs/PLUGINS-AND-PACKS-PLAN.md): the shelf, the install wizard, installed
// packs with updates and removal, Share as pack, plugin settings and pack links.
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:casama/core/backend.dart';
import 'package:casama/core/local_cache.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/bots/plugins_screen.dart';
import 'package:casama/features/packs/installed_packs_screen.dart';
import 'package:casama/features/packs/pack_files.dart';
import 'package:casama/features/packs/pack_preview_screen.dart';
import 'package:casama/features/packs/packs_shelf.dart';
import 'package:casama/features/packs/share_pack_screen.dart';
import 'package:casama/features/workspaces/gallery_policy_screen.dart' show galleryPolicyTypedKey;
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/theme/app_theme.dart';
import 'package:casama_sdk/casama_sdk.dart'
    show
        GalleryPack,
        LocalCapabilities,
        LocalDevice,
        LocalDevicePlatformEnum,
        Pack,
        PackFileInput,
        PackPreview,
        PackSecretFinding,
        PackUpdatePreview,
        Plugin;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _url = 'https://github.com/acme/trip-kit';

/// The pack pages behind a small router, opened at [initial].
Widget _routed(FakeBackend backend, String initial, {void Function(String id)? onOpenSet}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/shelf',
        builder: (_, _) => Scaffold(
          body: ListView(children: [PacksShelf(side: 16, width: 400, onOpenSet: onOpenSet ?? (_) {})]),
        ),
      ),
      GoRoute(
        path: '/settings/gallery/packs',
        builder: (_, _) => const InstalledPacksScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, s) => PackPreviewScreen(
              from: switch (s.extra) {
                final PackFrom f => f,
                _ => PackFrom(url: s.uri.queryParameters['url'], galleryId: s.uri.queryParameters['gallery_id']),
              },
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (_, s) => InstalledPackScreen(id: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/settings/share-pack', builder: (_, _) => const SharePackScreen()),
    ],
  );
  return ProviderScope(
    overrides: [backendProvider.overrideWithValue(backend), localCacheProvider.overrideWithValue(const NoCache())],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Map<String, dynamic> _diff({List<String> added = const [], List<Map<String, dynamic>> changed = const []}) => {
  'added': added,
  'removed': <String>[],
  'changed': changed,
};

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('packNext')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the shelf lists packs and starter sets, featured first, with what each holds', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend()
      ..galleryPackList.addAll([
        GalleryPack.fromJson({
          'kind': 'set',
          'id': 'morning',
          'name': 'Morning set',
          'summary': 'Start the day',
          'icon': 'sun',
          'author': {'name': 'Casama'},
          'featured': false,
          'reviewed': true,
          'url': null,
          'commit': null,
          'contents': null,
          'set_items': [
            {'type': 'bot', 'id': 'a'},
            {'type': 'routine', 'id': 'b'},
          ],
          'tags': [],
        }),
        GalleryPack.fromJson({
          'kind': 'pack',
          'id': 'trip-kit',
          'name': 'Trip kit',
          'summary': 'Plan trips',
          'icon': 'plane',
          'author': {'name': 'Acme'},
          'featured': true,
          'reviewed': true,
          'url': _url,
          'commit': '1' * 40,
          'contents': {'bots': 1, 'skills': 2, 'routines': 1, 'apps': 0, 'looks': 1, 'tools': 1},
          'set_items': null,
          'tags': [],
        }),
      ]);
    final opened = <String>[];
    await tester.pumpWidget(_routed(backend, '/shelf', onOpenSet: opened.add));
    await tester.pumpAndSettle();

    expect(find.text('Packs'), findsOneWidget);
    final pack = find.byKey(const Key('packCard-pack-trip-kit'));
    final set = find.byKey(const Key('packCard-set-morning'));
    expect(tester.getTopLeft(pack).dx, lessThan(tester.getTopLeft(set).dx));
    expect(find.descendant(of: pack, matching: find.text('Reviewed')), findsOneWidget);
    expect(find.textContaining('1 bot · 2 skills · 1 routine · 1 look · 1 tool'), findsOneWidget);
    expect(find.textContaining('Starter set · 2 items'), findsOneWidget);

    // A starter set opens the existing set install.
    await tester.tap(set);
    await tester.pumpAndSettle();
    expect(opened, ['morning']);

    // A pack opens its preview.
    await tester.tap(pack);
    await tester.pumpAndSettle();
    expect(backend.packActions, contains('preview:trip-kit'));
    expect(find.byKey(const Key('packAdd')), findsOneWidget);
  });

  testWidgets('the wizard sends what was left out, the answers and the keys, then shows each item', (tester) async {
    await setSize(tester, const Size(900, 2200));
    final backend = FakeBackend();
    await tester.pumpWidget(_routed(backend, '/settings/gallery/packs/add?url=$_url'));
    await tester.pumpAndSettle();
    expect(backend.packActions, ['preview:$_url']);
    expect(find.text('Not reviewed by Casama'), findsOneWidget);

    await tester.tap(find.byKey(const Key('packAdd')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('packStep-inside')), findsOneWidget);
    await tester.tap(find.byKey(const Key('packItem-skill:budget')));
    await tester.pump();
    await _next(tester);

    expect(find.byKey(const Key('packStep-questions')), findsOneWidget);
    await _next(tester);
    expect(find.text('Fill this in'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('packInput-city')), 'Lisbon');
    await _next(tester);

    expect(find.byKey(const Key('packStep-secrets')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('packSecret-WEATHER_KEY')), 'wk-1');
    await _next(tester);

    expect(find.byKey(const Key('packStep-reach')), findsOneWidget);
    Finder inSheet(Finder f) => find.descendant(of: find.byKey(const Key('packStep-reach')), matching: f);
    expect(inSheet(find.text('Runs code')), findsOneWidget);
    expect(inSheet(find.text("Uses the bot's computer")), findsOneWidget);
    expect(inSheet(find.text('Talks to api.weather.example')), findsOneWidget);
    expect(inSheet(find.text('About 1 scheduled run a week')), findsOneWidget);
    expect(inSheet(find.byKey(const Key('packUnreviewedWarning'))), findsOneWidget);
    await _next(tester);

    expect(backend.lastPackInstall, {
      'url': _url,
      'commit': '1' * 40,
      'gallery_id': null,
      'share_token': null,
      'skip': ['skill:budget'],
      'inputs': {'city': 'Lisbon'},
      'secrets': {'WEATHER_KEY': 'wk-1'},
      'settings': {'UNITS': 'metric'},
      'bot_id': null,
    });
    expect(find.byKey(const Key('packResult')), findsOneWidget);
    expect(find.text('Trip kit is in'), findsOneWidget);
    expect(find.text('Added'), findsOneWidget);
    expect(find.text('Skipped · Left out'), findsOneWidget);
    expect(find.text("Didn't work · Plan limit reached"), findsOneWidget);
    expect(find.text('On this device'), findsOneWidget);
    expect(find.byKey(const Key('packConnect-flights')), findsOneWidget);
    expect(find.byKey(const Key('packUseLook-scheme/sunset')), findsOneWidget);
  });

  testWidgets("a pack's tools can run on my own computer (D-344)", (tester) async {
    await setSize(tester, const Size(900, 2200));
    final backend = FakeBackend()
      ..device = LocalDevice(
        id: 'dev1',
        orgId: orgId,
        userId: 'me',
        computerId: 'local-computer',
        name: 'Studio Mac',
        platform: LocalDevicePlatformEnum.macos,
        capabilities: LocalCapabilities(mcp: true),
        allowedRoots: const [],
        allowedBotIds: const [],
        enabled: true,
        online: true,
        lastSeenAt: null,
        createdAt: DateTime(2026),
      );
    await tester.pumpWidget(_routed(backend, '/settings/gallery/packs/add?url=$_url'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('packAdd')));
    await tester.pumpAndSettle();
    await _next(tester);
    await tester.enterText(find.byKey(const Key('packInput-city')), 'Lisbon');
    await _next(tester);
    await tester.enterText(find.byKey(const Key('packSecret-WEATHER_KEY')), 'wk-1');
    await _next(tester);
    expect(find.byKey(const Key('packStep-reach')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pluginPlace-dev1')));
    await tester.pumpAndSettle();
    await _next(tester);
    expect(backend.lastPackInstall?['device_id'], 'dev1');
  });

  testWidgets('a pack without a bot asks for one, and a workspace that asks first waits for an admin', (tester) async {
    await setSize(tester, const Size(900, 2200));
    final json = FakeBackend.packPreviewJson(reviewed: true, withBot: false)
      ..['inputs'] = []
      ..['secrets'] = []
      ..['settings'] = [];
    final backend = FakeBackend()
      ..packApprovalPending = true
      ..packPreviewValue = PackPreview.fromJson(json);
    await tester.pumpWidget(_routed(backend, '/settings/gallery/packs/add?url=$_url'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('packAdd')));
    await tester.pumpAndSettle();
    await _next(tester); // inside
    expect(find.byKey(const Key('packStep-reach')), findsOneWidget);
    expect(find.byKey(const Key('packUnreviewedWarning')), findsNothing);
    await _next(tester); // reach
    expect(find.byKey(const Key('packStep-bot')), findsOneWidget);
    await _next(tester);
    expect(find.text('Pick a bot'), findsOneWidget);
    await tester.tap(find.byKey(const Key('packBot')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ada').last);
    await tester.pumpAndSettle();
    await _next(tester);

    expect(backend.lastPackInstall?['bot_id'], botId);
    expect(find.text('Waiting for approval'), findsOneWidget);
    expect(find.text("We've asked an admin. The pack is added once they approve."), findsOneWidget);
  });

  testWidgets('installing a pack the workspace has links to the installed packs', (tester) async {
    await setSize(tester, const Size(900, 2200));
    final json = FakeBackend.packPreviewJson(reviewed: true)
      ..['inputs'] = []
      ..['secrets'] = []
      ..['settings'] = [];
    final backend = FakeBackend()
      ..packPreviewValue = PackPreview.fromJson(json)
      ..packInstallError = const PackError('pack_installed', 'trip-kit is already here: update it instead.');
    await tester.pumpWidget(_routed(backend, '/settings/gallery/packs/add?url=$_url'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('packAdd')));
    await tester.pumpAndSettle();
    await _next(tester);
    await _next(tester);
    expect(find.text('trip-kit is already here: update it instead.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('packOpenInstalled')));
    await tester.pumpAndSettle();
    expect(find.text('Installed packs'), findsOneWidget);
  });

  testWidgets('an update shows its diff, keeps edits unless switched, and asks before reaching further', (
    tester,
  ) async {
    await setSize(tester, const Size(900, 2200));
    final backend = FakeBackend()
      ..installedPacks.add(Pack.fromJson(FakeBackend.packJson()))
      ..packUpdateValue = PackUpdatePreview.fromJson({
        'up_to_date': false,
        'can_check': true,
        'from_commit': '1' * 40,
        'to_commit': '2' * 40,
        'from_version': '1.0.0',
        'to_version': '1.1.0',
        'bots': _diff(
          changed: [
            {
              'id': 'planner',
              'diff': ['- You plan trips.', '+ You plan trips and budgets.'],
            },
          ],
        ),
        'routines': _diff(added: ['Daily weather']),
        'skills': _diff(),
        'apps': _diff(),
        'looks': _diff(),
        'servers': _diff(),
        'hosts_added': ['api.tides.example'],
        'secrets_added': [],
        'schedules_changed': ['Weekly deals'],
        'runs_per_week': {'from': 1, 'to': 8},
        'reach_grew': true,
        'edited': [
          {'kind': 'bot', 'id': 'planner'},
        ],
      });
    await tester.pumpWidget(_routed(backend, '/settings/gallery/packs/pack-1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('packEdited-bot:planner')), findsOneWidget);
    expect(find.text('Edited by you'), findsOneWidget);

    await tester.tap(find.byKey(const Key('packCheckUpdate')));
    await tester.pumpAndSettle();
    expect(find.text('1.0.0 → 1.1.0'), findsOneWidget);
    expect(find.text('Changed: planner'), findsOneWidget);
    expect(find.text('+ You plan trips and budgets.'), findsOneWidget);
    expect(find.text('New: Daily weather'), findsOneWidget);
    expect(find.text('New sites it talks to: api.tides.example'), findsOneWidget);
    expect(find.text('New schedules: Weekly deals'), findsOneWidget);
    expect(find.text('Scheduled runs a week: 1 → 8'), findsOneWidget);
    expect(find.byKey(const Key('packReachGrew')), findsOneWidget);
    // It reaches further: nothing happens until the person says yes.
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('packUpdateConfirm'))).onPressed, isNull);

    // The dialog's height is capped, so scroll each control into view before tapping it.
    await tester.ensureVisible(find.byKey(const Key('packTheirs-bot:planner')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('packTheirs-bot:planner')));
    await tester.ensureVisible(find.byKey(const Key('packConfirmReach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('packConfirmReach')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('packUpdateConfirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('packUpdateConfirm')));
    await tester.pumpAndSettle();
    expect(backend.packActions.last, 'update:pack-1:${'2' * 40}:theirs=bot:planner:reach=true:secrets=');
    expect(find.byKey(const Key('packUpdateSheet')), findsNothing);
  });

  testWidgets("a pack from a file can't check for updates", (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend()
      ..installedPacks.add(
        Pack.fromJson(
          FakeBackend.packJson(source: {'kind': 'upload', 'repo': null, 'path': null, 'url': null, 'gallery_id': null}),
        ),
      )
      ..packUpdateValue = PackUpdatePreview.fromJson({
        'up_to_date': false,
        'can_check': false,
        'from_commit': null,
        'to_commit': null,
        'from_version': null,
        'to_version': null,
        for (final k in ['bots', 'routines', 'skills', 'apps', 'looks', 'servers']) k: _diff(),
        'hosts_added': [],
        'secrets_added': [],
        'schedules_changed': [],
        'runs_per_week': {'from': 0, 'to': 0},
        'reach_grew': false,
        'edited': [],
      });
    await tester.pumpWidget(_routed(backend, '/settings/gallery/packs/pack-1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('From a file'), findsOneWidget);
    await tester.tap(find.byKey(const Key('packCheckUpdate')));
    await tester.pumpAndSettle();
    expect(find.text("This pack came from a file or link and can't check for updates."), findsOneWidget);
  });

  testWidgets('removing a pack asks about its bots and says what stayed', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend()
      ..installedPacks.add(Pack.fromJson(FakeBackend.packJson()))
      ..packRemoveKept = 1;
    await tester.pumpWidget(_routed(backend, '/settings/gallery/packs/pack-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('packRemove')));
    await tester.pumpAndSettle();
    expect(find.text('Remove Trip kit?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('packRemoveBots')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('packRemoveConfirm')));
    await tester.pumpAndSettle();
    expect(backend.packActions.last, 'remove:pack-1:delete');
    expect(find.text('Pack removed. 1 item stayed because you changed it.'), findsOneWidget);
    // Back on the list, now empty.
    expect(find.text('No packs yet. Find one on the Packs shelf, or add one from a link.'), findsOneWidget);
  });

  testWidgets('share as pack shows lines that look like keys, then the link', (tester) async {
    await setSize(tester, const Size(900, 1600));
    final backend = FakeBackend()
      ..packFindings = [PackSecretFinding(path: 'skills/plan-trip/SKILL.md', line: 3, what: 'Looks like an API key')];
    await tester.pumpWidget(_routed(backend, '/settings/share-pack'));
    await tester.pumpAndSettle();
    final check = find.byKey(const Key('shareCheck'));
    expect(tester.widget<ButtonStyleButton>(check).onPressed, isNull);
    await tester.tap(find.byKey(const Key('shareBot-$botId')));
    await tester.enterText(find.byKey(const Key('shareName')), 'Trip kit');
    await tester.enterText(find.byKey(const Key('shareSummary')), 'Plan trips with Ada');
    await tester.pump();
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(backend.lastPackExport?.botIds, [botId]);
    expect(find.text('skills/plan-trip/SKILL.md, line 3: Looks like an API key'), findsOneWidget);

    // Back to the form, then share anyway.
    await tester.tap(find.byKey(const Key('shareGoBack')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shareName')), findsOneWidget);
    await tester.tap(check);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shareAnyway')));
    await tester.pumpAndSettle();
    expect(backend.packActions, contains('share:Trip kit:ignore=true'));
    expect(find.text('https://app.casama.ai/packs/share/tok-1234567890'), findsOneWidget);
    expect(find.textContaining('until Dec 17, 2026'), findsOneWidget);
    expect(find.byKey(const Key('shareSaveFile')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shareStop')));
    await tester.pumpAndSettle();
    expect(backend.packActions.last, 'revoke:tok-1234567890');
  });

  testWidgets("a plugin's settings can be changed, and a pack's plugin points to its pack", (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    final json = jsonDecode(jsonEncode(backend.installed('1' * 40).toJson())) as Map<String, dynamic>
      ..['settings'] = [
        {
          'name': 'UNITS',
          'label': 'Units',
          'description': 'metric or imperial',
          'server': 'forecast',
          'default': 'metric',
          'value': 'metric',
        },
      ]
      ..['pack_id'] = '88888888-8888-4888-8888-888888888888'
      ..['pack_name'] = 'Trip kit';
    backend.pluginList.add(Plugin.fromJson(json));
    await tester.pumpWidget(harness(backend, const PluginsScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('From the Trip kit pack'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pluginMenu-plugin-1')));
    await tester.pumpAndSettle();
    // Updates and removal go through the pack.
    expect(find.text('Check for Update'), findsNothing);
    expect(find.text('Uninstall'), findsNothing);
    await tester.tap(find.text('Edit settings'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pluginSettingField-UNITS')), 'imperial');
    await tester.tap(find.byKey(const Key('pluginSettingsSave')));
    await tester.pumpAndSettle();
    expect(backend.pluginActions.last, 'settings:plugin-1:UNITS=imperial');
    expect(find.text('imperial'), findsOneWidget);
  });

  test('a pack .zip is read from inside its one folder, without macOS extras', () {
    final archive = Archive()
      ..add(ArchiveFile.string('trip-kit/.claude-plugin/plugin.json', '{"name":"trip-kit"}'))
      ..add(ArchiveFile.string('trip-kit/com.casama/pack.json', '{}'))
      ..add(ArchiveFile.bytes('trip-kit/bin/run', utf8.encode('#!/bin/sh'))..mode = 0x1ed)
      ..add(ArchiveFile.string('__MACOSX/trip-kit/._pack.json', 'x'));
    final files = packFilesFromZip(ZipEncoder().encodeBytes(archive)) as List<PackFileInput>;
    expect(files.map((f) => f.path), ['.claude-plugin/plugin.json', 'com.casama/pack.json', 'bin/run']);
    expect(files.last.executable, isTrue);
    expect(utf8.decode(base64Decode(files.first.base64)), '{"name":"trip-kit"}');
    expect(packFilesFromZip(Uint8List.fromList([1, 2, 3])), PackFileProblem.unreadable);
  });

  test('admins can type repository and pack keys', () {
    expect(galleryPolicyTypedKey('repo/Acme:trip-kit'), 'repo/acme:trip-kit');
    expect(galleryPolicyTypedKey('repo/acme:trip.kit'), 'repo/acme:trip-kit');
    expect(galleryPolicyTypedKey('pack/trip-kit'), 'pack/trip-kit');
    expect(galleryPolicyTypedKey('trip kit'), isNull);
    expect(galleryPolicyTypedKey('repo/acme'), isNull);
  });
}
