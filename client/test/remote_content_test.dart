import 'package:casama/core/backend.dart';
import 'package:casama/features/admin/app_settings_card.dart';
import 'package:casama/core/remote_content.dart';
import 'package:casama/features/chat/widgets/reactions.dart';
import 'package:casama/features/gallery/gallery_logic.dart';
import 'package:casama/features/library/library_starters.dart';
import 'package:casama/features/sites/domains_providers.dart';
import 'package:casama/features/welcome/gallery_picks_step.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart' show RemoteAppConfig, GalleryLists;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Settings as a server sends them; [extra] adds fields (new or from the future).
RemoteAppConfig _config([Map<String, dynamic> extra = const {}]) =>
    RemoteAppConfig.fromJson({
      'min_versions': <String, dynamic>{},
      'update_urls': <String, dynamic>{},
      'maintenance': null,
      'announcements': <dynamic>[],
      'flags': <String, dynamic>{},
      ...extra,
    });

GalleryItem _item(
  String id, {
  List<String> tags = const [],
  String name = 'Item',
}) => GalleryItem(
  id: id,
  type: 'skill',
  name: name,
  authorName: 'Casama',
  license: 'MIT',
  tags: tags,
);

void main() {
  tearDown(RemoteContent.reset);

  group('remote settings (D-372)', () {
    test(
      'a shipped-shape answer and one with fields from the future both parse',
      () {
        expect(_config().links, isNull);
        final future = _config({
          'links': {'status': 'https://status.example.com'},
          'something_new': {'a': 1},
        });
        expect(future.links, {'status': 'https://status.example.com'});
      },
    );

    test('links, names and quick reactions from the server, the app\'s own otherwise', () {
      expect(
        remoteLink('status', 'https://status.casama.ai'),
        'https://status.casama.ai',
      );
      expect(remoteQuickReactions(quickReactions), quickReactions);
      expect(remoteName('apps', 'github'), isNull);
      applyRemoteContent(
        _config({
          'links': {
            'status': 'https://status.example.com',
            'docs': 'http://insecure.example.com',
          },
          'quick_reactions': ['🔥', '👍'],
          'names': {
            'apps': {'github': 'GitHub'},
            'dns_providers': {'namecom': 'Name.com'},
          },
        }),
      );
      expect(remoteLink('status', 'x'), 'https://status.example.com');
      // Only https links are taken.
      expect(
        remoteLink('docs', 'https://docs.casama.ai'),
        'https://docs.casama.ai',
      );
      expect(
        remoteUri('terms', 'https://casama.ai/terms').toString(),
        'https://casama.ai/terms',
      );
      expect(remoteQuickReactions(quickReactions), ['🔥', '👍']);
      expect(remoteName('apps', 'github'), 'GitHub');
    });

    testWidgets(
      'the DNS company is named from the domain, then the server, then the app',
      (tester) async {
        late AppLocalizations l10n;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(
          domainRecordsIntro(l10n, 'route53'),
          l10n.domainRecordsAt('Amazon Route 53'),
        );
        expect(
          domainRecordsIntro(l10n, 'newdns', name: 'New DNS'),
          l10n.domainRecordsAt('New DNS'),
        );
        applyRemoteContent(
          _config({
            'names': {
              'dns_providers': {'newdns': 'New DNS Co'},
            },
          }),
        );
        expect(
          domainRecordsIntro(l10n, 'newdns'),
          l10n.domainRecordsAt('New DNS Co'),
        );
        expect(domainRecordsIntro(l10n, 'unknown'), l10n.domainRecordsGeneric);
      },
    );

    testWidgets('the quick reactions row follows the server', (tester) async {
      applyRemoteContent(
        _config({
          'quick_reactions': ['🔥', '🙏'],
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: QuickReactionStrip(onPick: (_) {}, onMore: () {}),
          ),
        ),
      );
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('👍'), findsNothing);
    });
  });

  group('gallery lists (D-372)', () {
    test('search uses the gallery\'s words, and the built-in ones without', () {
      final items = [
        _item('homework-helper', name: 'Homework helper', tags: ['school']),
      ];
      expect(gallerySearch(items, 'jungle'), isEmpty);
      expect(
        gallerySearch(
          items,
          'jungle',
          searchWords: {
            'jungle': ['school'],
          },
        ).map((i) => i.id),
        ['homework-helper'],
      );
      // An empty list from the server never turns synonyms off.
      expect(
        gallerySearch(items, 'study', searchWords: const {}).map((i) => i.id),
        ['homework-helper'],
      );
    });

    test('a starter set\'s tags are its match words', () {
      const sets = [
        GalleryItem(
          id: 'a-set',
          type: 'set',
          name: 'Kit A',
          authorName: 'Casama',
          license: 'CC0-1.0',
        ),
        GalleryItem(
          id: 'garden-kit',
          type: 'set',
          name: 'Garden kit',
          authorName: 'Casama',
          license: 'CC0-1.0',
          tags: ['garden', 'plants', 'allotment'],
        ),
      ];
      expect(
        pickStarterSet(
          sets,
          const AboutYouView(about: 'I keep an allotment.'),
        ).id,
        'garden-kit',
      );
    });

    testWidgets(
      'the empty Library shows the gallery\'s starters, and its own without',
      (tester) async {
        await setSize(tester, const Size(600, 1000));
        final backend = FakeBackend()
          ..galleryListsValue = GalleryLists.fromJson({
            'starters': {
              'library': [
                {
                  'id': 'poem',
                  'label': 'A poem',
                  'prompt': 'Write a poem about ',
                  'icon': 'feather',
                  'hue': 300,
                },
                {
                  'id': 'game',
                  'label': 'A tiny game',
                  'prompt': 'Make a tiny game.',
                  'icon': 'not-shipped',
                  'hue': 265,
                },
              ],
            },
          });
        String? picked;
        await tester.pumpWidget(
          harness(
            backend,
            SingleChildScrollView(
              child: LibraryStarters(onPick: (p) => picked = p),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('A poem'), findsOneWidget);
        expect(find.text('A tiny game'), findsOneWidget);
        expect(find.text('A logo'), findsNothing);
        await tester.tap(find.byKey(const Key('libraryStarter-poem')));
        expect(picked, 'Write a poem about ');

        await tester.pumpWidget(
          harness(
            FakeBackend(),
            SingleChildScrollView(child: LibraryStarters(onPick: (_) {})),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('A logo'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'Admin edits the welcome emails\' words, starting from Casama\'s',
    (tester) async {
      await setSize(tester, const Size(800, 1200));
      final backend = FakeBackend();
      await tester.pumpWidget(
        harness(backend, const SingleChildScrollView(child: AppSettingsCard())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('adminEmailCopy')));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('adminEmailCopyJson'));
      expect(
        tester.widget<TextField>(field).controller!.text,
        contains('Welcome to Casama'),
      );
      await tester.enterText(field, '{"welcome": {"subject": "Hi there"}}');
      await tester.tap(find.byKey(const Key('adminEmailCopySave')));
      await tester.pumpAndSettle();
      expect(backend.emailCopy, {
        'welcome': {'subject': 'Hi there'},
      });
    },
  );
}
