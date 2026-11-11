import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/inbox/for_you.dart';
import 'package:casama_app/features/skills/skill_proposals.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

SkillProposal proposal(String id, SkillProposalKindEnum kind, {String? previous}) => SkillProposal(
      id: id,
      botId: botId,
      kind: kind,
      skillId: kind == SkillProposalKindEnum.edit ? 'sk-1' : null,
      name: 'weekly-sales-report',
      description: 'Make the weekly sales report',
      bodyMd: '1. Query sales for 7 days.\n2. Summarize.',
      previousBodyMd: previous,
      tools: const ['crm.query'],
      reason: kind == SkillProposalKindEnum.edit ? 'Use 7 days.' : "You've asked for this 3 times.",
      status: SkillProposalStatusEnum.pending,
      createdAt: DateTime(2026, 11, 10),
    );

void main() {
  test('line diff marks removed and added lines', () {
    expect(lineDiff('a\nb\nc', 'a\nB\nc'), [(' ', 'a'), ('-', 'b'), ('+', 'B'), (' ', 'c')]);
  });

  testWidgets('For you shows skill ideas and edits as a diff; save and dismiss', (tester) async {
    await setSize(tester, const Size(900, 1600));
    final backend = FakeBackend()
      ..proposals.addAll([
        proposal('p1', SkillProposalKindEnum.new_),
        proposal('p2', SkillProposalKindEnum.edit, previous: '1. Query sales for the month.\n2. Summarize.'),
      ]);
    await tester.pumpWidget(harness(backend, const Scaffold(body: ForYouList())));
    await tester.pumpAndSettle();
    expect(find.text('Skill ideas'), findsOneWidget);
    expect(find.text('Uses: crm.query'), findsOneWidget);
    expect(find.text('- 1. Query sales for the month.'), findsOneWidget);
    expect(find.text('+ 1. Query sales for 7 days.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('acceptProposal-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dismissProposal-p2')));
    await tester.pumpAndSettle();
    expect(backend.proposalActions, ['accept:p1', 'dismiss:p2']);
  });

  testWidgets('a skill shows its uses, success rate and history', (tester) async {
    await setSize(tester, const Size(900, 1200));
    await tester.pumpWidget(harness(FakeBackend(), const Scaffold(body: SkillStatsSheet(skillId: 'sk-1', name: 'weekly-sales-report'))));
    await tester.pumpAndSettle();
    expect(find.text('Used 4 times · 75% went well · 1 failed · 0 corrected'), findsOneWidget);
    expect(find.text('Old steps'), findsOneWidget);
  });
}
