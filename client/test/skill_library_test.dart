import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/skills/skill_catalog_screen.dart';
import 'package:casama_app/features/skills/skills_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the catalog opens as its own page, filters by category and installs to a bot', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const SkillsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browseCatalog')));
    await tester.pumpAndSettle();
    expect(find.byType(SkillCatalogScreen), findsOneWidget);
    // Browsing groups by category; each skill shows its own icon.
    expect(find.byKey(const Key('section-work')), findsOneWidget);
    expect(find.byKey(const Key('section-data')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('catalog-meeting-notes')), matching: find.byIcon(LucideIcons.notebookPen)), findsOneWidget);
    expect(find.text('Meeting notes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('category-data')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('catalog-meeting-notes')), findsNothing);
    await tester.tap(find.byKey(const Key('install-csv-cleanup')));
    await tester.pumpAndSettle();
    // Asked where, since there are bots.
    await tester.tap(find.byKey(const Key('installTarget-$botId')));
    await tester.pumpAndSettle();
    expect(backend.catalogInstalls, [('csv-cleanup', botId)]);
    // Installed state comes from the installed skills, not the open page.
    expect(find.byKey(const Key('installed-csv-cleanup')), findsOneWidget);
    expect(find.byKey(const Key('install-csv-cleanup')), findsNothing);
  });

  testWidgets('search finds skills and the detail shows the instructions and installs', (tester) async {
    await setSize(tester, const Size(390, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const SkillCatalogScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('catalogSearch')), 'meetings');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('catalog-csv-cleanup')), findsNothing);
    await tester.tap(find.byKey(const Key('catalog-meeting-notes')));
    await tester.pumpAndSettle();
    expect(find.textContaining('List the decisions.'), findsOneWidget);
    expect(find.textContaining('name: meeting-notes'), findsNothing);
    expect(find.text('/meeting-notes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('detailInstall')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('installTarget-workspace')));
    await tester.pumpAndSettle();
    expect(backend.catalogInstalls, [('meeting-notes', null)]);
    expect(find.textContaining('Installed for The whole workspace'), findsOneWidget);
  });

  testWidgets('installed catalog skills keep their catalog icon', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend()
      ..skillViews = [
        const SkillView(id: 'sk9', name: 'csv-cleanup', description: 'Clean', bodyMd: 'x', enabled: true, source: 'catalog', sourceRef: {'id': 'csv-cleanup'}, category: 'data'),
      ];
    await tester.pumpWidget(harness(backend, const SkillsScreen()));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('skill-sk9')), matching: find.byIcon(LucideIcons.sheet)), findsOneWidget);
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
