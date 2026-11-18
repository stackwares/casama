import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/chat/chat_controller.dart';
import 'package:casama/features/chat/widgets/gallery_cards.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Records what the draft card saves and submits.
class _DraftBackend extends FakeBackend {
  final savedSkills = <({String name, String description, String body})>[];
  final submissions =
      <({String type, Map<String, Object?> item, Map<String, String> files})>[];

  @override
  Future<void> saveSkill(
    String orgId, {
    String? id,
    String? botId,
    required String name,
    required String description,
    required String bodyMd,
    bool enabled = true,
  }) async =>
      savedSkills.add((name: name, description: description, body: bodyMd));

  @override
  Future<GallerySubmission> submitToGallery({
    required String type,
    String? id,
    required Map<String, Object?> item,
    required Map<String, String> files,
    GalleryRef? remixOf,
  }) async {
    submissions.add((type: type, item: item, files: files));
    return GallerySubmission(id: 's1', type: type, itemId: '${item['name']}');
  }
}

const _suggestionJson = {
  'type': 'gallery_suggestion',
  'item': {
    'type': 'routine',
    'id': 'morning-brief',
    'name': 'Morning brief',
    'description': 'A short summary of your day every morning.',
    'icon': 'sun',
    'access': {
      'reads': ['email', 'calendar'],
      'writes': ['sends you a message'],
      'runs_code': false,
    },
    'needs': {
      'apps': ['gmail'],
    },
  },
  'reason': 'You asked for a daily summary three times this week.',
};

const _draftJson = {
  'kind': 'gallery_draft',
  'draft': {
    'type': 'skill',
    'item': {
      'name': 'Weekly report',
      'description': 'Writes the Friday team report.',
    },
    'files': {
      'SKILL.md': '---\nname: Weekly report\ndescription: Writes the Friday team report.\n---\n\nCollect the week\'s wins and blockers.',
    },
  },
};

Widget _card(FakeBackend backend, Widget child) => harness(
  backend,
  Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'gallery parts parse from message content, tolerating missing fields',
    () {
      final parts = galleryPartsOf([
        {'type': 'text', 'text': 'Here you go'},
        _suggestionJson,
        _draftJson,
        {
          'type': 'gallery_suggestion',
          'item': {'type': 'skill', 'id': 'bare'},
        },
        {
          'type': 'gallery_suggestion',
          'item': {'name': 'no id'},
        },
        {
          'type': 'gallery_draft',
          'draft': {'item': {}},
        },
      ]);
      expect(parts, hasLength(3));
      final s = parts[0] as GallerySuggestionPart;
      expect(s.key, 'routine/morning-brief');
      expect(s.access?.reads, ['email', 'calendar']);
      expect(s.needs?.apps, ['gmail']);
      final d = parts[1] as GalleryDraftPart;
      expect(d.name, 'Weekly report');
      expect(d.instructions, "Collect the week's wins and blockers.");
      expect(d.skillName, 'weekly-report');
      final bare = parts[2] as GallerySuggestionPart;
      expect(bare.name, 'bare');
      expect(bare.reason, '');
    },
  );

  test('a finished reply with gallery parts adds one card entry per part, without a text bubble', () {
    final container = ProviderContainer(
      overrides: [backendProvider.overrideWithValue(FakeBackend())],
    );
    addTearDown(container.dispose);
    final c = container.read(chatControllerProvider(botId).notifier);
    final content = [_suggestionJson, _draftJson];
    c.apply(
      ev(1, 'message.completed', {'message_id': 'm1', 'content': content}),
    );
    c.apply(
      ev(2, 'message.completed', {'message_id': 'm1', 'content': content}),
    );
    final entries = container.read(chatControllerProvider(botId)).entries;
    expect(entries.whereType<MessageEntry>(), isEmpty);
    expect(entries.whereType<GalleryCardEntry>().map((e) => e.part.key), [
      'routine/morning-brief',
      'draft/skill/Weekly report',
    ]);
  });

  testWidgets(
    'suggestion card shows the item, reason and access; Add runs the install flow',
    (tester) async {
      await setSize(tester, const Size(600, 900));
      final installs = <String>[];
      Future<bool> install(
        BuildContext context,
        WidgetRef ref, {
        required String type,
        required String id,
      }) async {
        installs.add('$type/$id');
        return true;
      }

      final part =
          galleryPartsOf([_suggestionJson]).single as GallerySuggestionPart;
      await tester.pumpWidget(
        _card(
          FakeBackend(),
          GallerySuggestionCard(
            part: part,
            conversationId: 'c1',
            install: install,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Morning brief'), findsOneWidget);
      expect(
        find.text('A short summary of your day every morning.'),
        findsOneWidget,
      );
      expect(
        find.text('You asked for a daily summary three times this week.'),
        findsOneWidget,
      );
      final access = tester
          .widget<Text>(
            find.byKey(
              const Key('gallerySuggestionAccess-routine/morning-brief'),
            ),
          )
          .data!;
      expect(access, contains('Reads email, calendar'));
      expect(access, contains('Sends you a message'));
      expect(access, contains('Needs'));

      await tester.tap(
        find.byKey(const Key('gallerySuggestionAdd-routine/morning-brief')),
      );
      await tester.pumpAndSettle();
      expect(installs, ['routine/morning-brief']);
      expect(
        find.byKey(const Key('gallerySuggestionAdded-routine/morning-brief')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('gallerySuggestionAdd-routine/morning-brief')),
        findsNothing,
      );
    },
  );

  testWidgets('a cancelled install leaves the card as it was', (tester) async {
    await setSize(tester, const Size(600, 900));
    Future<bool> install(
      BuildContext context,
      WidgetRef ref, {
      required String type,
      required String id,
    }) async => false;
    final part =
        galleryPartsOf([_suggestionJson]).single as GallerySuggestionPart;
    await tester.pumpWidget(
      _card(
        FakeBackend(),
        GallerySuggestionCard(
          part: part,
          conversationId: 'c1',
          install: install,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('gallerySuggestionAdd-routine/morning-brief')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('gallerySuggestionAdd-routine/morning-brief')),
      findsOneWidget,
    );
  });

  testWidgets(
    'Not now hides the suggestion and remembers it for the conversation',
    (tester) async {
      await setSize(tester, const Size(600, 900));
      final part =
          galleryPartsOf([_suggestionJson]).single as GallerySuggestionPart;
      await tester.pumpWidget(
        _card(
          FakeBackend(),
          GallerySuggestionCard(part: part, conversationId: 'c1'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('gallerySuggestionNotNow-routine/morning-brief')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Morning brief'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('gallery_cards.c1'), contains('dismissed'));

      // A fresh card in the same conversation (after a reload) stays hidden.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _card(
          FakeBackend(),
          GallerySuggestionCard(
            key: const Key('again'),
            part: part,
            conversationId: 'c1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Morning brief'), findsNothing);

      // Another conversation still shows it.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _card(
          FakeBackend(),
          GallerySuggestionCard(part: part, conversationId: 'c2'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Morning brief'), findsOneWidget);
    },
  );

  testWidgets(
    'draft card folds its instructions, saves to skills and submits to the gallery',
    (tester) async {
      await setSize(tester, const Size(600, 1200));
      final backend = _DraftBackend();
      final part = galleryPartsOf([_draftJson]).single as GalleryDraftPart;
      await tester.pumpWidget(
        _card(backend, GalleryDraftCard(part: part, conversationId: 'c1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Weekly report'), findsOneWidget);
      expect(find.text('Writes the Friday team report.'), findsOneWidget);
      expect(find.byKey(const Key('galleryDraftInstructions')), findsNothing);
      await tester.tap(find.byKey(const Key('galleryDraftToggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('galleryDraftInstructions')), findsOneWidget);
      expect(
        find.text("Collect the week's wins and blockers."),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('galleryDraftSave')));
      await tester.pumpAndSettle();
      expect(backend.savedSkills.single.name, 'weekly-report');
      expect(
        backend.savedSkills.single.body,
        "Collect the week's wins and blockers.",
      );
      expect(find.text('Saved'), findsOneWidget);

      await tester.tap(find.byKey(const Key('galleryDraftSubmit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('galleryDraftSubmitConfirm')));
      await tester.pumpAndSettle();
      expect(backend.submissions.single.type, 'skill');
      expect(backend.submissions.single.item['name'], 'Weekly report');
      expect(backend.submissions.single.files.keys, ['SKILL.md']);
      expect(find.text('Sent'), findsOneWidget);
    },
  );
}
