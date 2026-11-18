import 'dart:convert';

import 'package:casama/app.dart';
import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/router.dart';
import 'package:casama/features/gallery/gallery_install.dart';
import 'package:casama/features/gallery/gallery_logic.dart';
import 'package:casama/features/gallery/gallery_requests.dart';
import 'package:casama/features/integrations/integrations_screen.dart'
    show connectedAppIdsProvider;
import 'package:casama/features/settings/gallery_screen.dart';
import 'package:casama_sdk/casama_sdk.dart' show ReportTarget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

final _now = DateTime(2026, 11, 16);

GalleryItem _item(
  String type,
  String id, {
  String? name,
  String? added,
  List<String> tags = const [],
  String? description,
  bool featured = false,
  String? pick,
  GalleryNeeds? needs,
  GalleryAccess? access,
  GallerySeason? season,
  GalleryStats? stats,
  String? minApp,
  List<GalleryInput> inputs = const [],
  Map<String, Object?>? document,
  int version = 1,
}) => GalleryItem(
  id: id,
  type: type,
  name: name ?? id,
  authorName: 'Casama',
  license: 'CC0-1.0',
  tags: tags,
  description: description,
  featured: featured,
  pick: pick,
  added: added,
  needs: needs,
  access: access,
  season: season,
  stats: stats,
  minApp: minApp,
  inputs: inputs,
  document: document,
  version: version,
);

const _lagoonDoc = {
  'v': 2,
  'scheme': {
    'light': {
      'seed': '#0E6E78',
      'background': '#F4FBFC',
      'onBackground': '#102226',
    },
    'dark': {
      'seed': '#8FE8E2',
      'background': '#0C2428',
      'onBackground': '#E7F6F5',
    },
  },
  'headingFont': 'Fraunces',
  'bodyFont': 'Figtree',
  'wallpaper': {'pattern': 'sea', 'palette': 'ocean', 'intensity': 0.5},
};

final _brief = _item(
  'routine',
  'daily-brief',
  name: 'Daily brief',
  description: 'Your day in one message.',
  access: const GalleryAccess(reads: ['email', 'calendar'], credits: 'low'),
  needs: const GalleryNeeds(apps: ['gmail']),
  inputs: const [
    GalleryInput(key: 'city', label: 'Your city', defaultValue: 'Manila'),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  FakeBackend backend,
  Widget screen, {
  List<dynamic> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final org = (await backend.organizations()).first;
  await tester.pumpWidget(
    harness(
      backend,
      screen,
      overrides: [
        currentOrgProvider.overrideWithValue(org),
        connectedAppIdsProvider.overrideWith((ref) async => <String>{}),
        ...overrides,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('rows', () {
    test('new means added in the last 30 days', () {
      expect(
        galleryIsNew(_item('skill', 'a', added: '2026-11-01'), _now),
        isTrue,
      );
      expect(
        galleryIsNew(_item('skill', 'a', added: '2026-09-01'), _now),
        isFalse,
      );
      expect(galleryIsNew(_item('skill', 'a'), _now), isFalse);
    });

    test('the New row hides while more than half the catalog is new', () {
      final mostlyNew = [
        _item('skill', 'a', added: '2026-11-10'),
        _item('skill', 'b', added: '2026-11-11'),
        _item('skill', 'c', added: '2026-01-01'),
      ];
      expect(galleryNewShown(mostlyNew, _now), isFalse);
      expect(GalleryRows.from(mostlyNew, now: _now).fresh, isEmpty);
      final someNew = [
        _item('skill', 'a', added: '2026-11-10'),
        _item('skill', 'b', added: '2026-01-11'),
        _item('skill', 'c', added: '2026-01-01'),
      ];
      expect(galleryNewShown(someNew, _now), isTrue);
      expect(GalleryRows.from(someNew, now: _now).fresh.map((i) => i.id), [
        'a',
      ]);
    });

    test('seasons can wrap the year end', () {
      const winter = GallerySeason('12-01', '01-15');
      expect(winter.contains(DateTime(2026, 12, 24)), isTrue);
      expect(winter.contains(DateTime(2027, 1, 10)), isTrue);
      expect(winter.contains(DateTime(2026, 11, 16)), isFalse);
      const autumn = GallerySeason('11-01', '11-30');
      final rows = GalleryRows.from([
        _item('wallpaper', 'snow', season: winter),
        _item('wallpaper', 'leaves', season: autumn),
      ], now: _now);
      expect(rows.seasonal.map((i) => i.id), ['leaves']);
    });

    test('works with what you have: everything needed is connected, or it is about a connected app', () {
      final items = [
        _item(
          'routine',
          'inbox-zero',
          needs: const GalleryNeeds(apps: ['gmail']),
        ),
        _item(
          'routine',
          'standup',
          needs: const GalleryNeeds(apps: ['gmail', 'slack']),
        ),
        _item('skill', 'gmail-filters', tags: const ['gmail']),
        _item('theme', 'gmail-red', tags: const ['gmail']),
      ];
      final rows = GalleryRows.from(items, now: _now, connected: {'gmail'});
      expect(rows.worksWith.map((i) => i.id), ['inbox-zero', 'gmail-filters']);
      expect(GalleryRows.from(items, now: _now).worksWith, isEmpty);
    });

    test('most used covers apps, skills, wallpapers and themes; trending sorts by this week', () {
      final rows = GalleryRows.from([
        _item(
          'skill',
          'a',
          stats: const GalleryStats(installers: 50, trending: 2),
        ),
        _item(
          'routine',
          'b',
          stats: const GalleryStats(installers: 900, trending: 30),
        ),
        _item('theme', 'c', stats: const GalleryStats(installers: 120)),
      ], now: _now);
      expect(rows.mostUsed.map((i) => i.id), ['c', 'a']);
      expect(rows.trending.map((i) => i.id), ['b', 'a']);
    });

    test('picks lead with a note and take turns by kind', () {
      final rows = GalleryRows.from([
        _item('theme', 't1', featured: true),
        _item('theme', 't2', featured: true, pick: 'Calm and warm'),
        _item('skill', 's1', featured: true),
        _item('set', 'kit', featured: true),
      ], now: _now);
      expect(rows.picks.map((i) => i.id), ['t2', 's1', 't1']);
    });
  });

  group('search and filters', () {
    final items = [
      _item(
        'skill',
        'inbox-triage',
        name: 'Inbox triage',
        tags: const ['gmail'],
      ),
      _item(
        'routine',
        'agenda',
        name: 'Morning agenda',
        tags: const ['calendar'],
      ),
      _item('theme', 'lagoon', name: 'Lagoon', tags: const ['teal']),
    ];

    test('synonyms find the same thing by another word', () {
      expect(gallerySearch(items, 'mail').map((i) => i.id), ['inbox-triage']);
      expect(gallerySearch(items, 'cal').map((i) => i.id), ['agenda']);
      expect(gallerySearch(items, 'zebra'), isEmpty);
      // Every word must match.
      expect(gallerySearch(items, 'mail teal'), isEmpty);
    });

    test('name matches lead', () {
      final found = gallerySearch([
        _item('skill', 'x', name: 'Helper', tags: const ['email']),
        _item('skill', 'y', name: 'Email digest'),
      ], 'email');
      expect(found.map((i) => i.id), ['y', 'x']);
    });

    test('filters: free, computer and tag', () {
      final all = [
        _item('theme', 'look'),
        _item('skill', 'free', access: const GalleryAccess(credits: 'none')),
        _item(
          'skill',
          'pc',
          access: const GalleryAccess(computer: true, credits: 'high'),
        ),
      ];
      expect(
        const GalleryFilter(price: GalleryPrice.free)
            .apply(all)
            .map((i) => i.id),
        ['look', 'free'],
      );
      expect(const GalleryFilter(computer: true).apply(all).map((i) => i.id), [
        'pc',
      ]);
      expect(const GalleryFilter(tag: 'teal').apply(items).map((i) => i.id), [
        'lagoon',
      ]);
    });

    test('items for a newer app are hidden', () {
      final visible = galleryVisible([
        _item('skill', 'old'),
        _item('skill', 'new', minApp: '9.0.0'),
        _item('skill', 'ok', minApp: '0.1.0'),
      ], appVersion: '0.2.0');
      expect(visible.map((i) => i.id), ['old', 'ok']);
    });
  });

  group('gallery home', () {
    testWidgets(
      'rows show starter sets and picks with their note, and the stats line in detail',
      (tester) async {
        final backend = FakeBackend()
          ..galleryItems = [
            _item(
              'theme',
              'lagoon',
              name: 'Lagoon',
              featured: true,
              pick: 'Sea colors',
              document: _lagoonDoc,
            ),
            _item(
              'set',
              'founder-kit',
              name: 'Founder kit',
              description: 'Everything to run a small company.',
              document: const {
                'items': [
                  {'type': 'routine', 'id': 'daily-brief'},
                ],
              },
            ),
            _brief.withStats(
              const GalleryStats(installers: 120, success: 0.96),
            ),
          ];
        await _pump(tester, backend, const GalleryScreen());
        expect(find.byKey(const Key('galleryRow-sets')), findsOneWidget);
        expect(find.text('Sea colors'), findsOneWidget);
        // Nothing has a date here: no New row.
        expect(find.byKey(const Key('galleryRow-new')), findsNothing);
        await tester.tap(find.byKey(const Key('gallery-routine-daily-brief')));
        await tester.pumpAndSettle();
        expect(
          find.text('Used by 120 people · 96% of runs finish'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('galleryAccess')), findsOneWidget);
        expect(find.text('Reads your email, calendar'), findsOneWidget);
        expect(find.text('Made by Casama'), findsOneWidget);
      },
    );

    testWidgets('an empty search offers a request and asking Casama', (
      tester,
    ) async {
      final backend = FakeBackend()..galleryItems = [_brief];
      await _pump(tester, backend, const GalleryScreen());
      await tester.enterText(
        find.byKey(const Key('gallerySearch')),
        'tide charts',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('galleryRequestThis')), findsOneWidget);
      expect(find.byKey(const Key('galleryAskCasama')), findsOneWidget);
    });

    testWidgets('applying a look counts its use and tracks it on the device', (
      tester,
    ) async {
      final backend = FakeBackend()
        ..galleryItems = [
          _item('theme', 'lagoon', name: 'Lagoon', document: _lagoonDoc),
        ];
      await _pump(
        tester,
        backend,
        const GalleryScreen(openType: 'theme', openId: 'lagoon'),
      );
      await tester.tap(find.byKey(const Key('galleryUse-lagoon')));
      await tester.pumpAndSettle();
      expect(backend.galleryUses, ['theme/lagoon']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('gallery.localLooks'), contains('lagoon'));
    });
  });

  group('install wizard', () {
    Widget launcher() => Consumer(
      builder: (context, ref, _) => Scaffold(
        body: Center(
          child: FilledButton(
            key: const Key('launch'),
            onPressed: () async {
              final ok = await showGalleryInstall(
                context,
                ref,
                type: 'routine',
                id: 'daily-brief',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('result $ok')));
              }
            },
            child: const Text('Add'),
          ),
        ),
      ),
    );

    // A routine goes to a bot (the server answers 400 bot_required without one).
    Future<void> pickBot(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('galleryWizardBot')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ada').last);
      await tester.pumpAndSettle();
    }

    testWidgets('answers, then apps to connect, then done', (tester) async {
      final backend = FakeBackend()
        ..galleryItems = [_brief]
        ..galleryInstallResult = const GalleryInstallResult(
          installedKind: 'routine',
          installedId: 'r1',
          missingApps: [GalleryMissing('gmail', 'Gmail')],
        );
      await _pump(tester, backend, launcher());
      await tester.tap(find.byKey(const Key('launch')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('galleryWizardReview')), findsOneWidget);
      expect(find.text('Reads your email, calendar'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('galleryInput-city')),
      );
      expect(field.controller!.text, 'Manila');
      await tester.enterText(
        find.byKey(const Key('galleryInput-city')),
        'Cebu',
      );
      // No bot yet: asked for, and nothing is sent.
      await tester.tap(find.byKey(const Key('galleryWizardAdd')));
      await tester.pumpAndSettle();
      expect(backend.galleryItemInstalls, isEmpty);
      expect(find.text('Pick a bot'), findsOneWidget);
      await pickBot(tester);
      await tester.tap(find.byKey(const Key('galleryWizardAdd')));
      await tester.pumpAndSettle();
      expect(backend.galleryItemInstalls.single.$1, 'routine/daily-brief');
      expect(backend.galleryItemInstalls.single.$3, {'city': 'Cebu'});
      expect(backend.galleryInstallBots['routine/daily-brief'], botId);
      expect(find.byKey(const Key('galleryNeed-gmail')), findsOneWidget);
      await tester.tap(find.byKey(const Key('galleryWizardContinue')));
      await tester.pumpAndSettle();
      expect(find.text('Daily brief is ready'), findsOneWidget);
      expect(
        find.text('It works fully once you connect Gmail.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('galleryWizardFinish')));
      await tester.pumpAndSettle();
      expect(find.text('result true'), findsOneWidget);
    });

    testWidgets('the server turning an answer down shows it on the field', (
      tester,
    ) async {
      final backend = FakeBackend()
        ..galleryItems = [_brief]
        ..galleryInputErrors = {'city': 'Pick a real city'};
      await _pump(tester, backend, launcher());
      await tester.tap(find.byKey(const Key('launch')));
      await tester.pumpAndSettle();
      await pickBot(tester);
      await tester.tap(find.byKey(const Key('galleryWizardAdd')));
      await tester.pumpAndSettle();
      expect(find.text('Pick a real city'), findsOneWidget);
      expect(find.byKey(const Key('galleryWizardReview')), findsOneWidget);
      // Fixed and sent again, it goes through.
      await tester.tap(find.byKey(const Key('galleryWizardAdd')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('galleryWizardDone')), findsOneWidget);
    });

    testWidgets(
      'a set asks where its routines go, applies its looks here and names what was left out',
      (tester) async {
        final backend = FakeBackend()
          ..galleryItems = [
            _item(
              'set',
              'sea-kit',
              name: 'Sea kit',
              document: const {
                'items': [
                  {'type': 'routine', 'id': 'daily-brief'},
                  {'type': 'theme', 'id': 'lagoon'},
                ],
              },
            ),
            _brief,
            _item('theme', 'lagoon', name: 'Lagoon', document: _lagoonDoc),
          ]
          ..galleryInstallResult = const GalleryInstallResult(
            items: [
              GallerySetItemResult(
                type: 'theme',
                id: 'lagoon',
                status: 'device',
              ),
              GallerySetItemResult(
                type: 'routine',
                id: 'daily-brief',
                status: 'failed',
                error: 'Can\'t be read',
              ),
            ],
          );
        await _pump(
          tester,
          backend,
          Consumer(
            builder: (context, ref, _) => Scaffold(
              body: FilledButton(
                key: const Key('launch'),
                onPressed: () => showGalleryInstall(
                  context,
                  ref,
                  type: 'set',
                  id: 'sea-kit',
                ),
                child: const Text('Add'),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const Key('launch')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('galleryWizardBot')), findsOneWidget);
        await pickBot(tester);
        await tester.tap(find.byKey(const Key('galleryWizardAdd')));
        await tester.pumpAndSettle();
        expect(backend.galleryItemInstalls.single.$1, 'set/sea-kit');
        expect(backend.galleryInstallBots['set/sea-kit'], botId);
        expect(backend.galleryUses, ['theme/lagoon']);
        expect(find.byKey(const Key('galleryWizardNotAdded')), findsOneWidget);
        expect(find.text('Daily brief · Can\'t be read'), findsOneWidget);
      },
    );

    testWidgets('an install waiting for an admin says so', (tester) async {
      final backend = FakeBackend()
        ..galleryItems = [_brief]
        ..galleryInstallResult = const GalleryInstallResult(pending: true);
      await _pump(tester, backend, launcher());
      await tester.tap(find.byKey(const Key('launch')));
      await tester.pumpAndSettle();
      await pickBot(tester);
      await tester.tap(find.byKey(const Key('galleryWizardAdd')));
      await tester.pumpAndSettle();
      expect(find.text('Waiting for approval'), findsOneWidget);
    });
  });

  group('installed', () {
    testWidgets(
      'update asks first when access grew, remove confirms, retired points at its replacement',
      (tester) async {
        final backend = FakeBackend()
          ..galleryItems = [
            _item(
              'theme',
              'lagoon',
              name: 'Lagoon',
              version: 2,
              document: _lagoonDoc,
            ),
          ]
          ..galleryInstalledItems = [
            const GalleryInstalledItem(
              type: 'skill',
              id: 'notes',
              name: 'Notes',
              installedVersion: 1,
              latestVersion: 2,
              update: true,
              accessAdded: GalleryAccessDiff(reads: ['calendar']),
              changelog: [
                GalleryChange(
                  version: 2,
                  date: '2026-11-10',
                  note: 'Reads your calendar too.',
                ),
              ],
            ),
            const GalleryInstalledItem(
              type: 'routine',
              id: 'brief',
              name: 'Brief',
              installedVersion: 1,
              latestVersion: 2,
              update: true,
            ),
            const GalleryInstalledItem(
              type: 'bot',
              id: 'old-bot',
              name: 'Old bot',
              installedVersion: 1,
              retired: true,
              replacement: GalleryRef('bot', 'new-bot'),
            ),
          ];
        SharedPreferences.setMockInitialValues({
          'gallery.localLooks': jsonEncode([
            {'type': 'theme', 'id': 'lagoon', 'name': 'Lagoon', 'version': 1},
          ]),
        });
        await _pump(tester, backend, const GalleryScreen(installed: true));
        expect(find.text('2 updates'), findsOneWidget);
        expect(
          find.byKey(const Key('galleryReplacement-old-bot')),
          findsOneWidget,
        );
        // The device look has a newer version in the gallery.
        expect(
          find.byKey(const Key('galleryLookUpdate-lagoon')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('galleryUpdate-notes')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('galleryUpdateDialog')), findsOneWidget);
        expect(find.text('Now reads your calendar'), findsOneWidget);
        expect(find.text('Reads your calendar too.'), findsOneWidget);
        await tester.tap(find.byKey(const Key('galleryUpdateConfirm')));
        await tester.pumpAndSettle();
        expect(backend.galleryUpdates, [('skill/notes', true)]);

        // No new access: updates at once.
        await tester.tap(find.byKey(const Key('galleryUpdate-brief')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('galleryUpdateDialog')), findsNothing);
        expect(backend.galleryUpdates.last, ('routine/brief', false));

        await tester.tap(find.byKey(const Key('galleryRemove-brief')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('galleryRemoveConfirm')));
        await tester.pumpAndSettle();
        expect(backend.galleryRemovals, ['routine/brief']);
        expect(
          find.byKey(const Key('galleryInstalled-routine-brief')),
          findsNothing,
        );
      },
    );
  });

  group('requests board', () {
    final requests = [
      GalleryRequest(
        id: 'r1',
        kind: 'skill',
        title: 'Tide charts',
        votes: 3,
        createdAt: DateTime(2026, 11, 15),
      ),
      GalleryRequest(
        id: 'r2',
        kind: 'routine',
        title: 'Weekly budget',
        votes: 10,
        createdAt: DateTime(2026, 11, 1),
      ),
    ];

    testWidgets('top first, votes, and a new request', (tester) async {
      final backend = FakeBackend()..galleryRequestList = requests;
      await _pump(tester, backend, const GalleryRequestsScreen());
      final top = tester
          .getTopLeft(find.byKey(const Key('galleryRequest-r2')))
          .dy;
      final next = tester
          .getTopLeft(find.byKey(const Key('galleryRequest-r1')))
          .dy;
      expect(top, lessThan(next));
      await tester.tap(find.byKey(const Key('galleryVote-r1')));
      await tester.pumpAndSettle();
      expect(backend.galleryVotes, [('r1', true)]);
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      final newest = tester
          .getTopLeft(find.byKey(const Key('galleryRequest-r1')))
          .dy;
      final older = tester
          .getTopLeft(find.byKey(const Key('galleryRequest-r2')))
          .dy;
      expect(newest, lessThan(older));

      await tester.tap(find.byKey(const Key('galleryRequestNew')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('galleryRequestTitle')),
        'Plant care',
      );
      await tester.tap(find.byKey(const Key('galleryRequestSend')));
      await tester.pumpAndSettle();
      expect(backend.galleryRequestList.last.title, 'Plant care');
      expect(find.text('Request sent'), findsOneWidget);
    });

    testWidgets(
      'others\' requests can be reported, yours say so, and a similar title votes for the existing one',
      (tester) async {
        final backend = FakeBackend()
          ..galleryRequestList = [
            ...requests,
            const GalleryRequest(
              id: 'r3',
              kind: 'app',
              title: 'Notion sync',
              mine: true,
            ),
          ];
        await _pump(tester, backend, const GalleryRequestsScreen());
        expect(find.byKey(const Key('galleryRequestReport-r3')), findsNothing);
        expect(find.textContaining('Yours'), findsOneWidget);
        await tester.tap(find.byKey(const Key('galleryRequestNew')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('galleryRequestTitle')),
          'Tide charts',
        );
        await tester.tap(find.byKey(const Key('galleryRequestSend')));
        await tester.pumpAndSettle();
        expect(backend.galleryRequestList, hasLength(3));
        expect(
          find.text(
            '"Tide charts" was already asked for, so your vote went to it',
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('galleryRequestReport-r1')));
        await tester.pumpAndSettle();
        expect(find.text('Report request'), findsWidgets);
        await tester.tap(find.byKey(const Key('reportReason-spam')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('reportSend')));
        await tester.pumpAndSettle();
        expect(backend.reports.single.$1, ReportTarget.galleryRequest);
        expect(backend.reports.single.$2, 'r1');
      },
    );

    testWidgets('a deep link opens the new request with its title', (
      tester,
    ) async {
      final backend = FakeBackend();
      await _pump(
        tester,
        backend,
        const GalleryRequestsScreen(openNew: true, newTitle: 'Tide charts'),
      );
      final field = tester.widget<TextField>(
        find.byKey(const Key('galleryRequestTitle')),
      );
      expect(field.controller!.text, 'Tide charts');
    });
  });

  group('links', () {
    Future<GoRouterLike> app(WidgetTester tester, FakeBackend backend) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [backendProvider.overrideWithValue(backend)],
          child: const CasamaApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CasamaApp)),
      );
      return GoRouterLike((loc) => container.read(routerProvider).go(loc));
    }

    testWidgets(
      'casama://app/gallery/requests/new opens the board with a new request filled in',
      (tester) async {
        final go = await app(tester, FakeBackend());
        go('/gallery/requests/new?title=Tide%20charts');
        await tester.pumpAndSettle();
        expect(find.byType(GalleryRequestsScreen), findsOneWidget);
        final field = tester.widget<TextField>(
          find.byKey(const Key('galleryRequestTitle')),
        );
        expect(field.controller!.text, 'Tide charts');
      },
    );

    testWidgets('casama://app/gallery/set/<id> opens the set with Add', (
      tester,
    ) async {
      final backend = FakeBackend()
        ..galleryItems = [
          _item(
            'set',
            'founder-kit',
            name: 'Founder kit',
            document: const {
              'items': [
                {'type': 'routine', 'id': 'daily-brief'},
              ],
            },
          ),
          _brief,
        ];
      final go = await app(tester, backend);
      go('/gallery/set/founder-kit');
      await tester.pumpAndSettle();
      expect(find.byType(GalleryScreen), findsOneWidget);
      expect(find.byKey(const Key('galleryUse-founder-kit')), findsOneWidget);
      expect(
        find.byKey(const Key('gallerySetItem-routine-daily-brief')),
        findsOneWidget,
      );
    });
  });

  group('server shapes', () {
    test(
      'an install answers installed, or approval_pending with its approval',
      () {
        final done = GalleryInstallResult.fromJson(
          jsonDecode(
            '''{"status":"installed","installed":{"kind":"routine","id":"r1"},
          "approval_id":null,"missing":{"apps":[{"id":"gmail","name":"Gmail"}],
          "skills":[{"id":"meeting-notes","name":"Meeting notes"}]}}''',
          ) as Map<String, dynamic>,
        );
        expect(done.pending, isFalse);
        expect(done.installedKind, 'routine');
        expect(done.installedId, 'r1');
        expect(done.missingApps.single.name, 'Gmail');
        expect(done.missingSkills.single.id, 'meeting-notes');

        final waiting = GalleryInstallResult.fromJson(
          jsonDecode('''{"status":"approval_pending","installed":null,
          "approval_id":"0b1c2d3e-0000-4000-8000-000000000001",
          "missing":{"apps":[],"skills":[]}}''') as Map<String, dynamic>,
        );
        expect(waiting.pending, isTrue);
        expect(waiting.installedId, isNull);
        expect(waiting.approvalId, '0b1c2d3e-0000-4000-8000-000000000001');
      },
    );

    test('a set install lists each item under items, looks as device', () {
      final r = GalleryInstallResult.fromJson(
        jsonDecode('''{"items":[
          {"type":"bot","id":"founder","status":"installed","installed":{"kind":"bot","id":"b1"},"error":null},
          {"type":"theme","id":"lagoon","status":"device","installed":null,"error":null},
          {"type":"routine","id":"brief","status":"approval_pending","installed":null,"error":null},
          {"type":"skill","id":"notes","status":"skipped","installed":null,"error":"Already added"},
          {"type":"plugin","id":"x","status":"failed","installed":null,"error":"Can't be read"}],
          "missing":{"apps":[{"id":"gmail","name":"Gmail"}],"skills":[]}}''')
            as Map<String, dynamic>,
      );
      expect(r.items, hasLength(5));
      expect(r.items.first.installedId, 'b1');
      expect(r.deviceItems.single.key, 'theme/lagoon');
      expect(r.pending, isTrue);
      expect(r.notAdded.map((i) => i.key), ['skill/notes', 'plugin/x']);
      expect(r.notAdded.first.error, 'Already added');
      expect(r.missingApps.single.id, 'gmail');
    });

    test(
      'access_changed reads what the update adds from the Problem errors',
      () {
        final errors = jsonDecode('''[
        {"path":"reads","message":"your calendar"},
        {"path":"writes","message":"your email"},
        {"path":"runs_code","message":"true"},
        {"path":"breaking","message":"true"}]''');
        final diff = GalleryAccessDiff.fromProblemErrors(errors);
        expect(diff.reads, ['your calendar']);
        expect(diff.writes, ['your email']);
        expect(diff.runsCode, isTrue);
        expect(diff.computer, isFalse);
        expect(GalleryAccessDiff.problemBreaking(errors), isTrue);
        expect(GalleryAccessDiff.problemBreaking(const []), isFalse);
      },
    );

    test(
      'installed items, requests, submissions, author items and approvals',
      () {
        final installed = GalleryInstalledItem.fromJson(
          jsonDecode(
            '''{"type":"routine","id":"brief","name":"Daily brief",
          "installed_version":1,"latest_version":2,"update":true,"breaking":false,
          "access_added":{"reads":["your calendar"],"writes":[],"runs_code":false,"computer":false},
          "retired":false,"changelog":[{"version":2,"date":"2026-11-10","note":"Weather"}],
          "installed_at":"2026-11-01T00:00:00.000Z","target":{"kind":"routine","id":"r1"}}''',
          ) as Map<String, dynamic>,
        );
        expect(installed.update, isTrue);
        expect(installed.asksFirst, isTrue);
        expect(installed.targetId, 'r1');
        expect(installed.newChanges.single.note, 'Weather');

        final request = GalleryRequest.fromJson(
          jsonDecode(
            '''{"id":"r1","kind":"skill","title":"Tide charts","details":"",
          "status":"done","done_item_key":"skill/tides","votes":4,"voted":true,
          "mine":true,"created_at":"2026-11-15T00:00:00.000Z"}''',
          ) as Map<String, dynamic>,
        );
        expect(request.mine, isTrue);
        expect(request.votes, 4);
        expect(request.doneItem, const GalleryRef('skill', 'tides'));

        final sub = GallerySubmission.fromJson(
          jsonDecode(
            '''{"id":"s1","type":"skill","item_id":"tides","name":"Tides",
          "pr_url":null,"status":"failed","created_at":"2026-11-15T00:00:00.000Z"}''',
          ) as Map<String, dynamic>,
        );
        expect(sub.itemKey, 'skill/tides');
        expect(sub.status, 'failed');

        final mine = GalleryMyItem.fromJson(
          jsonDecode('''{"type":"skill","id":"tides","name":"Tides","version":2,
          "stats":{"installers":40,"installers_7d":6,"active":12,"runs_ok":18,"runs_total":20},
          "reports_open":1}''') as Map<String, dynamic>,
        );
        expect(mine.stats!.trending, 6);
        expect(mine.stats!.active, 12);
        expect(mine.stats!.success, closeTo(0.9, 0.001));

        final approval = WorkspaceGalleryApproval.fromJson(
          jsonDecode(
            '''{"id":"a1","org_id":"o1","type":"plugin","item_id":"github",
          "name":"GitHub","requested_by":"u1","requested_by_name":"Mia",
          "reason":"Runs code","status":"pending","error":null,
          "created_at":"2026-11-15T00:00:00.000Z","decided_at":null}''',
          ) as Map<String, dynamic>,
        );
        expect(approval.key, 'plugin/github');
        expect(approval.requestedByName, 'Mia');
        expect(approval.decidedAt, isNull);
      },
    );
  });
}

/// Goes to a location in the app's router.
class GoRouterLike {
  GoRouterLike(this._go);
  final void Function(String) _go;
  void call(String location) => _go(location);
}
