import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_controller.dart';
import 'package:casama_app/features/chat/widgets/chat_widgets.dart';
import 'package:casama_app/features/bots/bots_screen.dart';
import 'package:casama_app/features/settings/about_you_screen.dart';
import 'package:casama_app/features/workspaces/people_screen.dart';
import 'package:casama_app/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('settings shows the name bots use and opens About you', (tester) async {
    await setSize(tester, const Size(800, 2400));
    final backend = FakeBackend()..about = const AboutYouView(displayName: 'Robin Park', preferredName: 'Rob');
    await tester.pumpWidget(harness(backend, const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Rob'), findsOneWidget);
    expect(find.text('What your bots call you and know about you'), findsOneWidget);
  });

  testWidgets('About you saves the name, reply style and space choice, and edits learned facts', (tester) async {
    await setSize(tester, const Size(900, 2600));
    final backend = FakeBackend()..about = const AboutYouView(displayName: 'Robin Park');
    await backend.addUserFacts([(kind: 'fact', content: 'Has a dog named Miso.')]);
    await tester.pumpWidget(harness(backend, const AboutYouScreen()));
    await tester.pumpAndSettle();

    // The sign-in name's first word is filled in; saving stays off until something changes.
    expect(tester.widget<TextField>(find.byKey(const Key('aboutName'))).controller!.text, 'Robin');
    await tester.enterText(find.byKey(const Key('aboutName')), 'Rob');
    await tester.enterText(find.byKey(const Key('aboutStyle')), 'Short answers.');
    await tester.pump();
    await tester.tap(find.byKey(const Key('aboutSave')));
    await tester.pumpAndSettle();
    expect(backend.about.preferredName, 'Rob');
    expect(backend.about.replyStyle, 'Short answers.');

    await tester.tap(find.byKey(const Key('learnAboutMe')));
    await tester.pumpAndSettle();
    expect(backend.about.learn, isFalse);

    // Off by default in a team space; turning it on is per workspace.
    final sw = find.byKey(const Key('useInThisSpace'));
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);
    await tester.ensureVisible(sw);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    expect(backend.profileShared.values, [true]);

    expect(find.text('Has a dog named Miso.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('addFact')));
    await tester.tap(find.byKey(const Key('addFact')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('factText')), findsOneWidget, reason: 'sheet open');
    await tester.enterText(find.byKey(const Key('factText')), 'Lives near the coast.');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(const Key('factSave'))).onPressed, isNotNull, reason: 'save enabled');
    await tester.tap(find.byKey(const Key('factSave')));
    await tester.pumpAndSettle();
    expect(backend.facts.map((f) => f.content), ['Has a dog named Miso.', 'Lives near the coast.']);
    expect(find.text('Lives near the coast.'), findsOneWidget);
  });

  testWidgets('a fact saved to the profile shows in chat and can be undone', (tester) async {
    final backend = FakeBackend();
    await backend.addUserFacts([(kind: 'fact', content: 'Has two kids.')]);
    final container = ProviderContainer(overrides: [backendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);
    final c = container.read(chatControllerProvider(botId).notifier);
    c.apply(ev(1, 'memory.written', {'memory_id': 'fact-1', 'kind': 'fact', 'scope': 'profile'}));
    c.apply(ev(2, 'memory.written', {'memory_id': 'm-2', 'kind': 'fact'}));
    final notices = container.read(chatControllerProvider(botId)).entries.whereType<NoticeEntry>().toList();
    expect(notices.map((n) => n.kind), [NoticeKind.profileSaved, NoticeKind.memory]);
    expect(notices.first.refId, 'fact-1');

    String? undone;
    await tester.pumpWidget(
      harness(
        backend,
        Scaffold(
          body: NoticeLine(entry: notices.first, onUndo: (id) => undone = id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved to your profile'), findsOneWidget);
    await tester.tap(find.byKey(const Key('undoProfileFact')));
    expect(undone, 'fact-1');
  });

  testWidgets('people who joined before the welcome question get the name card once', (tester) async {
    await setSize(tester, const Size(800, 1600));
    final backend = FakeBackend()..about = const AboutYouView(displayName: 'Robin Park', nameAsked: false);
    await tester.pumpWidget(harness(backend, const BotsScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nameCard')), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('nameCardField'))).controller!.text, 'Robin');
    await tester.enterText(find.byKey(const Key('nameCardField')), 'Rob');
    await tester.pump();
    await tester.tap(find.byKey(const Key('nameCardSave')));
    await tester.pumpAndSettle();
    expect(backend.about.preferredName, 'Rob');
    expect(find.byKey(const Key('nameCard')), findsNothing);
  });

  testWidgets('"Not now" dismisses the name card for good', (tester) async {
    await setSize(tester, const Size(800, 1600));
    final backend = FakeBackend()..about = const AboutYouView(displayName: 'Robin Park', nameAsked: false);
    await tester.pumpWidget(harness(backend, const BotsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nameCardLater')));
    await tester.pumpAndSettle();
    expect(backend.nameAskedMarked, isTrue);
    expect(find.byKey(const Key('nameCard')), findsNothing);
  });

  testWidgets('People shows the name someone goes by and their pronouns', (tester) async {
    await setSize(tester, const Size(800, 2000));
    final backend = FakeBackend();
    backend.workspaceMembers = [WorkspaceMember(userId: 'u-ana', email: 'ana@acme.test', role: WorkspaceMemberRoleEnum.member, name: 'Ana', pronouns: 'she/her')];
    await tester.pumpWidget(harness(backend, const PeopleScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Ana (she/her)'), findsOneWidget);
    expect(find.text('ana@acme.test'), findsOneWidget);
  });
}
