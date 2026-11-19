import 'package:casama/core/backend.dart';
import 'package:casama/features/notifications/gallery_digest.dart';
import 'package:casama/features/welcome/gallery_picks_step.dart';
import 'package:casama/features/workspaces/gallery_policy_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _sets = [
  GalleryItem(
    id: 'founder-kit',
    type: 'set',
    name: 'Founder kit',
    authorName: 'Casama',
    license: 'CC0-1.0',
    icon: 'rocket',
    description: 'Investor updates, inbox triage and a weekly plan.',
  ),
  GalleryItem(
    id: 'student-kit',
    type: 'set',
    name: 'Student kit',
    authorName: 'Casama',
    license: 'CC0-1.0',
    icon: 'graduation-cap',
    description: 'Study plans, flashcards and class notes.',
  ),
];

/// A set that lists what it adds: a skill the gallery has and an app it doesn't list.
const _kitWithItems = GalleryItem(
  id: 'reading-kit',
  type: 'set',
  name: 'Reading kit',
  authorName: 'Casama',
  license: 'CC0-1.0',
  icon: 'book-open',
  description: 'Summaries of what you read.',
  document: {
    'items': [
      {'type': 'app', 'id': 'gmail'},
      {'type': 'skill', 'id': 'pdf-summary'},
    ],
  },
);

const _skill = GalleryItem(
  id: 'pdf-summary',
  type: 'skill',
  name: 'PDF summary',
  authorName: 'Casama',
  license: 'MIT',
  description: 'Summarizes long PDFs.',
);

/// A gallery with starter sets, recording set installs.
class _GalleryBackend extends FakeBackend {
  final installedSets = <String>[];
  List<String> missingApps = const [];
  List<GalleryItem> sets = _sets;

  @override
  Future<GalleryPage> galleryEverything() async =>
      const GalleryPage(available: true, items: [_skill]);

  @override
  Future<List<GalleryItem>> gallerySets() async => sets;

  @override
  Future<GalleryInstallResult> installGallerySet(
    String orgId,
    String id, {
    String? botId,
  }) async {
    installedSets.add(id);
    return GalleryInstallResult(
      missingApps: [for (final a in missingApps) GalleryMissing(a, a)],
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'the starter set follows what the person shared, else the first one',
    () {
      expect(pickStarterSet(_sets, null).id, 'founder-kit');
      expect(
        pickStarterSet(
          _sets,
          const AboutYouView(
            about: 'I am a university student studying biology.',
          ),
        ).id,
        'student-kit',
      );
      expect(
        pickStarterSet(
          _sets,
          const AboutYouView(about: 'I run a small startup.'),
        ).id,
        'founder-kit',
      );
    },
  );

  testWidgets(
    'picks step pre-selects the matching set and adds the one picked',
    (tester) async {
      await setSize(tester, const Size(500, 1000));
      final backend = _GalleryBackend()
        ..about = const AboutYouView(about: 'Student at college.')
        ..missingApps = const ['Gmail'];
      late WidgetRef ref;
      await tester.pumpWidget(
        harness(
          backend,
          Consumer(
            builder: (context, r, _) {
              ref = r;
              return const GalleryPicksStep();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Picks for you'), findsOneWidget);
      expect(find.text('Founder kit'), findsOneWidget);
      expect(find.text('Student kit'), findsOneWidget);

      // Pre-selected from About you; a tap changes it.
      await tester.tap(find.byKey(const Key('galleryPicksAdd')));
      await tester.pumpAndSettle();
      expect(backend.installedSets, ['student-kit']);
      expect(ref.read(galleryPicksDoneProvider), isTrue);
      expect(find.textContaining('Connect Gmail'), findsOneWidget);
    },
  );

  testWidgets('picking another set adds that one', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = _GalleryBackend();
    await tester.pumpWidget(harness(backend, const GalleryPicksStep()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('galleryPicksSet-student-kit')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('galleryPicksAdd')));
    await tester.pumpAndSettle();
    expect(backend.installedSets, ['student-kit']);
  });

  testWidgets('Skip for now adds nothing and finishes the step for good', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1000));
    final backend = _GalleryBackend();
    late WidgetRef ref;
    await tester.pumpWidget(
      harness(
        backend,
        Consumer(
          builder: (context, r, _) {
            ref = r;
            return const GalleryPicksStep();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('galleryPicksSkip')));
    await tester.pumpAndSettle();
    expect(backend.installedSets, isEmpty);
    expect(ref.read(galleryPicksDoneProvider), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((k) => k.startsWith('gallery_picks_done.')),
      isNotEmpty,
    );
  });

  test('a starter pick says whether what the person shared matched it', () {
    expect(starterPick(_sets, null).matched, isFalse);
    expect(
      starterPick(
        _sets,
        const AboutYouView(about: 'I just like gardening.'),
      ).matched,
      isFalse,
    );
    final student = starterPick(
      _sets,
      const AboutYouView(about: 'Studying for my university exams.'),
    );
    expect(student.set.id, 'student-kit');
    expect(student.matched, isTrue);
  });

  testWidgets(
    'the best match leads the list with a badge, and Add names the set',
    (tester) async {
      await setSize(tester, const Size(500, 1000));
      final backend = _GalleryBackend()
        ..about = const AboutYouView(about: 'Student at college.');
      await tester.pumpWidget(harness(backend, const GalleryPicksStep()));
      await tester.pumpAndSettle();
      final student = tester.getTopLeft(
        find.byKey(const Key('galleryPicksSet-student-kit')),
      );
      final founder = tester.getTopLeft(
        find.byKey(const Key('galleryPicksSet-founder-kit')),
      );
      expect(student.dy, lessThan(founder.dy));
      expect(
        find.descendant(
          of: find.byKey(const Key('galleryPicksSet-student-kit')),
          matching: find.byKey(const Key('galleryPicksBestMatch')),
        ),
        findsOneWidget,
      );
      expect(find.text('Add Student kit'), findsOneWidget);

      await tester.tap(find.byKey(const Key('galleryPicksSet-founder-kit')));
      await tester.pumpAndSettle();
      expect(find.text('Add Founder kit'), findsOneWidget);
      // The badge stays with the set that matched.
      expect(find.byKey(const Key('galleryPicksBestMatch')), findsOneWidget);
    },
  );

  testWidgets('with nothing shared to match, no set is called the best match', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1000));
    await tester.pumpWidget(
      harness(_GalleryBackend(), const GalleryPicksStep()),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('galleryPicksBestMatch')), findsNothing);
    expect(find.text('Add Founder kit'), findsOneWidget);
  });

  testWidgets(
    'the picked set shows what it adds, named from the gallery or its id',
    (tester) async {
      await setSize(tester, const Size(500, 1000));
      final backend = _GalleryBackend()..sets = [_kitWithItems, ..._sets];
      await tester.pumpWidget(harness(backend, const GalleryPicksStep()));
      await tester.pumpAndSettle();
      // Pre-picked (first, nothing shared), so it is open: a count line and a chip per item.
      expect(find.text('1 skill · 1 app'), findsOneWidget);
      expect(find.text('PDF summary'), findsOneWidget);
      expect(find.text('Gmail'), findsOneWidget);

      // Picking another set closes it.
      await tester.tap(find.byKey(const Key('galleryPicksSet-student-kit')));
      await tester.pumpAndSettle();
      expect(find.text('PDF summary'), findsNothing);
    },
  );

  testWidgets(
    'a wide window previews the picked set beside the list and adds it',
    (tester) async {
      await setSize(tester, const Size(1280, 820));
      final backend = _GalleryBackend()..sets = [_kitWithItems, ..._sets];
      await tester.pumpWidget(harness(backend, const GalleryPicksStep()));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('galleryPicksPreview-reading-kit')),
        findsOneWidget,
      );
      expect(find.text('What\'s inside'), findsOneWidget);
      expect(find.text('PDF summary'), findsOneWidget);

      await tester.tap(find.byKey(const Key('galleryPicksSet-student-kit')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('galleryPicksPreview-student-kit')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('galleryPicksPreview-reading-kit')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('galleryPicksAdd')));
      await tester.pumpAndSettle();
      expect(backend.installedSets, ['student-kit']);
    },
  );

  testWidgets('the step stays hidden when the gallery has no sets', (
    tester,
  ) async {
    final backend = FakeBackend();
    late WidgetRef ref;
    await tester.pumpWidget(
      harness(
        backend,
        Consumer(
          builder: (context, r, _) {
            ref = r;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(ref.read(galleryPicksNeededProvider), isFalse);
  });

  testWidgets(
    'admins set the mode, approval rules and allow and block lists, then save',
    (tester) async {
      await setSize(tester, const Size(700, 2200));
      final backend = _GalleryBackend();
      await tester.pumpWidget(harness(backend, const GalleryPolicyScreen()));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('galleryPolicySave')))
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const Key('galleryPolicyMode-approval')));
      await tester.pumpAndSettle();
      // Asking first for code-running items replaces "everything".
      await tester.tap(find.byKey(const Key('galleryPolicyRule-runs_code')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('galleryPolicyAddBlocked')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('galleryPolicySearch')),
        'pdf',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('galleryPolicyPick-set/founder-kit')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const Key('galleryPolicyPick-skill/pdf-summary')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('galleryPolicyItem-skill/pdf-summary')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('galleryPolicySave')));
      await tester.pumpAndSettle();
      final saved = backend.savedGalleryPolicies.single;
      expect(saved.mode, GalleryPolicyMode.approval);
      expect(saved.approvalFor, ['runs_code']);
      expect(saved.block, ['skill/pdf-summary']);
      expect(saved.toJson()['mode'], 'approval');
      expect(find.text('Gallery rules saved'), findsOneWidget);
    },
  );

  testWidgets('admins approve or decline adds waiting for them', (
    tester,
  ) async {
    await setSize(tester, const Size(700, 2200));
    final backend = _GalleryBackend()
      ..galleryApprovalList = [
        const WorkspaceGalleryApproval(
          id: 'a1',
          type: 'skill',
          itemId: 'pdf-summary',
          name: 'PDF summary',
          requestedByName: 'Mia',
          reason: 'This workspace asks an admin first.',
        ),
        const WorkspaceGalleryApproval(
          id: 'a2',
          type: 'plugin',
          itemId: 'github',
          name: 'GitHub',
        ),
      ];
    await tester.pumpWidget(harness(backend, const GalleryPolicyScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('galleryPolicyWaiting')), findsOneWidget);
    expect(
      find.textContaining('Waiting for approval', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Mia asked'), findsOneWidget);
    await tester.tap(find.byKey(const Key('galleryPolicyApprove-a1')));
    await tester.pumpAndSettle();
    expect(backend.galleryDecisions, [('a1', true)]);
    expect(find.text('PDF summary approved and added'), findsOneWidget);
    expect(find.byKey(const Key('galleryPolicyApproval-a1')), findsNothing);
    await tester.tap(find.byKey(const Key('galleryPolicyDecline-a2')));
    await tester.pumpAndSettle();
    expect(backend.galleryDecisions.last, ('a2', false));
    expect(find.byKey(const Key('galleryPolicyWaiting')), findsNothing);
  });

  testWidgets(
    'the monthly picks email switch turns on and hides on older servers',
    (tester) async {
      final backend = FakeBackend();
      await tester.pumpWidget(
        harness(backend, const Scaffold(body: GalleryDigestTile())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Monthly gallery picks'), findsOneWidget);
      await tester.tap(find.byKey(const Key('galleryDigestSwitch')));
      await tester.pumpAndSettle();
      expect(backend.galleryDigestEmails, isTrue);

      await tester.pumpWidget(
        harness(
          FakeBackend()..galleryDigestEmails = null,
          const Scaffold(body: GalleryDigestTile()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Monthly gallery picks'), findsNothing);
    },
  );
}
