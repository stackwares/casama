import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/skills/skills_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the catalog filters by category and installs to a bot', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const SkillsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browseCatalog')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('catalog-meeting-notes')), findsOneWidget);
    await tester.tap(find.byKey(const Key('category-data')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('catalog-meeting-notes')), findsNothing);
    await tester.tap(find.byKey(const Key('skillScope')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ada').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('install-csv-cleanup')));
    await tester.pumpAndSettle();
    expect(backend.catalogInstalls, [('csv-cleanup', botId)]);
  });

  testWidgets('GitHub import shows every file before installing at the previewed commit', (tester) async {
    await setSize(tester, const Size(900, 1100));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const SkillsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openGitHubImport')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('githubUrl')), 'https://github.com/acme/skills/tree/main/pr-labels');
    await tester.pump();
    await tester.tap(find.byKey(const Key('githubSubmit')));
    await tester.pumpAndSettle();
    expect(find.text('pr-labels'), findsOneWidget);
    expect(find.textContaining('label.sh (executable)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('githubSubmit')));
    await tester.pumpAndSettle();
    expect(backend.githubInstalls.single.$2, 'a' * 40);
  });

  testWidgets('GitHub skills show a diff before updating', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend()
      ..skillViews = [
        const SkillView(id: 'sk1', name: 'pr-labels', description: 'Label PRs', bodyMd: 'x', enabled: true, source: 'github', sourceRef: {'repo': 'acme/skills'}),
      ];
    await tester.pumpWidget(harness(backend, const SkillsScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('GitHub acme/skills'), findsOneWidget);
    await tester.tap(find.byKey(const Key('checkUpdate-sk1')));
    await tester.pumpAndSettle();
    expect(find.text('+ new step'), findsOneWidget);
    expect(find.textContaining('label.sh'), findsOneWidget);
    await tester.tap(find.byKey(const Key('applySkillUpdate')));
    await tester.pumpAndSettle();
    expect(backend.appliedUpdate, 'b' * 40);
  });

  testWidgets('typing / picks a skill for the next message', (tester) async {
    await setSize(tester, const Size(600, 900));
    final backend = FakeBackend()
      ..skillViews = [
        const SkillView(id: 'sk2', name: 'meeting-notes', description: 'Summarize meetings', bodyMd: 'x', enabled: true),
        const SkillView(id: 'sk3', name: 'other-bot', description: 'Not mine', bodyMd: 'x', enabled: true, botId: 'someone-else'),
      ];
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageInput')), '/me');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pickSkill-meeting-notes')), findsOneWidget);
    expect(find.byKey(const Key('pickSkill-other-bot')), findsNothing);
    await tester.tap(find.byKey(const Key('pickSkill-meeting-notes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pickedSkill-meeting-notes')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('messageInput')), 'Here are the notes');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    expect(backend.sentSkills.last, ['meeting-notes']);
    expect(find.byKey(const Key('pickedSkill-meeting-notes')), findsNothing);
  });
}
