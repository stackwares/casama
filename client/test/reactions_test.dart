// Emoji reactions on messages (D-331): the quick strip, chips, double-tap, who reacted, and
// the change shown at once then put back when the server refuses.
import 'package:casama/core/backend.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _u1 = 'aaaaaaaa-0000-4000-8000-000000000001';
const _a1 = 'aaaaaaaa-0000-4000-8000-000000000002';

FakeBackend _backend() => FakeBackend()
  ..storedMessages = [
    ChatMessageView(
      id: _u1,
      role: 'user',
      text: 'Book the train to Lyon',
      createdAt: DateTime(2026, 11, 1),
    ),
    ChatMessageView(
      id: _a1,
      role: 'assistant',
      text: 'Booked the 9:04 to Lyon.',
      createdAt: DateTime(2026, 11, 1, 0, 1),
    ),
  ];

Future<FakeBackend> _open(WidgetTester tester, [FakeBackend? backend]) async {
  await setSize(tester, const Size(1200, 900));
  final b = backend ?? _backend();
  await tester.pumpWidget(
    harness(b, const ChatScreen(botId: botId, conversationId: convId)),
  );
  await tester.pumpAndSettle();
  return b;
}

Finder _chip(String messageId, String emoji) => find.descendant(
  of: find.byKey(Key('reactions-$messageId')),
  matching: find.byKey(Key('reactionChip-$emoji')),
);

Future<void> _longPress(WidgetTester tester, String text) async {
  await tester.longPress(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ReactionGroup', () {
    test('groups by emoji, most first, and knows yours', () {
      final groups = ReactionGroup.group([
        (emoji: '❤️', userId: 'ana', botId: null),
        (emoji: '👍', userId: 'me', botId: null),
        (emoji: '👍', userId: null, botId: 'bot1'),
      ], me: 'me');
      expect(groups.map((g) => (g.emoji, g.count, g.mine)), [
        ('👍', 2, true),
        ('❤️', 1, false),
      ]);
      expect(groups.first.bots, ['bot1']);
      expect(ReactionGroup.mineOf(groups), '👍');
    });

    test('withMine replaces your reaction and takes it back', () {
      final start = [
        const ReactionGroup(
          emoji: '👍',
          count: 2,
          mine: true,
          users: ['me', 'ana'],
        ),
      ];
      final swapped = ReactionGroup.withMine(start, '😂', me: 'me');
      expect(swapped.map((g) => (g.emoji, g.count, g.mine)), [
        ('👍', 1, false),
        ('😂', 1, true),
      ]);
      expect(swapped.first.users, ['ana']);
      expect(
        ReactionGroup.withMine(swapped, null, me: 'me').map((g) => g.emoji),
        ['👍'],
      );
    });

    test('round-trips through JSON', () {
      const g = ReactionGroup(
        emoji: '😮',
        count: 3,
        mine: true,
        users: ['me'],
        bots: ['b'],
      );
      expect(ReactionGroup.fromJson(g.toJson()), g);
    });
  });

  testWidgets('reactions already on a message show as chips with counts', (
    tester,
  ) async {
    final b = _backend()
      ..storedReactions[_a1] = [
        const ReactionGroup(emoji: '👍', count: 2, users: ['ana', 'li']),
      ];
    await _open(tester, b);
    expect(_chip(_a1, '👍'), findsOneWidget);
    expect(
      find.descendant(of: _chip(_a1, '👍'), matching: find.text('2')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reactions-$_u1')), findsNothing);
  });

  testWidgets('holding a reply shows the quick strip; a pick reacts at once', (
    tester,
  ) async {
    final b = await _open(tester);
    await _longPress(tester, 'Booked the 9:04 to Lyon.');
    expect(find.byKey(const Key('quickReactions')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quickReaction-❤️')));
    await tester.pumpAndSettle();
    expect(b.reactionCalls, ['set $_a1 ❤️']);
    expect(_chip(_a1, '❤️'), findsOneWidget);
  });

  testWidgets('picking your own reaction again in the strip takes it back', (
    tester,
  ) async {
    final b = _backend()
      ..storedReactions[_a1] = [
        const ReactionGroup(emoji: '😂', count: 1, mine: true, users: ['me']),
      ];
    await _open(tester, b);
    await _longPress(tester, 'Booked the 9:04 to Lyon.');
    await tester.tap(find.byKey(const Key('quickReaction-😂')));
    await tester.pumpAndSettle();
    expect(b.reactionCalls, ['remove $_a1']);
    expect(find.byKey(const Key('reactions-$_a1')), findsNothing);
  });

  testWidgets('another emoji replaces yours: one reaction per person', (
    tester,
  ) async {
    final b = _backend()
      ..storedReactions[_a1] = [
        const ReactionGroup(emoji: '👍', count: 1, mine: true, users: ['me']),
      ];
    await _open(tester, b);
    await _longPress(tester, 'Booked the 9:04 to Lyon.');
    await tester.tap(find.byKey(const Key('quickReaction-😮')));
    await tester.pumpAndSettle();
    expect(b.reactionCalls, ['set $_a1 😮']);
    expect(_chip(_a1, '👍'), findsNothing);
    expect(_chip(_a1, '😮'), findsOneWidget);
  });

  testWidgets('you can react to your own message too', (tester) async {
    final b = await _open(tester);
    await _longPress(tester, 'Book the train to Lyon');
    await tester.tap(find.byKey(const Key('quickReaction-👍')));
    await tester.pumpAndSettle();
    expect(b.reactionCalls, ['set $_u1 👍']);
    expect(_chip(_u1, '👍'), findsOneWidget);
  });

  testWidgets('a double-tap hearts a reply, and never takes the heart back', (
    tester,
  ) async {
    final b = await _open(tester);
    Future<void> doubleTap() async {
      final at = tester.getCenter(find.text('Booked the 9:04 to Lyon.'));
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(at);
      await tester.pumpAndSettle();
    }

    await doubleTap();
    expect(b.reactionCalls, ['set $_a1 ❤️']);
    await doubleTap();
    expect(b.reactionCalls, ['set $_a1 ❤️']);
  });

  testWidgets(
    'tapping a chip adds that reaction; tapping yours takes it back',
    (tester) async {
      final b = _backend()
        ..storedReactions[_a1] = [
          const ReactionGroup(emoji: '👍', count: 1, users: ['ana']),
        ];
      await _open(tester, b);
      await tester.tap(_chip(_a1, '👍'));
      await tester.pumpAndSettle();
      expect(b.reactionCalls, ['set $_a1 👍']);
      expect(
        find.descendant(of: _chip(_a1, '👍'), matching: find.text('2')),
        findsOneWidget,
      );
      await tester.tap(_chip(_a1, '👍'));
      await tester.pumpAndSettle();
      expect(b.reactionCalls, ['set $_a1 👍', 'remove $_a1']);
      expect(
        find.descendant(of: _chip(_a1, '👍'), matching: find.text('2')),
        findsNothing,
      );
    },
  );

  testWidgets('when the server refuses, the reaction is put back as it was', (
    tester,
  ) async {
    final b = _backend()..reactionError = Exception('nope');
    await _open(tester, b);
    await _longPress(tester, 'Booked the 9:04 to Lyon.');
    await tester.tap(find.byKey(const Key('quickReaction-👍')));
    await tester.pumpAndSettle();
    expect(b.reactionCalls, ['set $_a1 👍']);
    expect(find.byKey(const Key('reactions-$_a1')), findsNothing);
  });

  testWidgets("someone else's reaction arrives live", (tester) async {
    final b = await _open(tester);
    final reads = b.reactionReads;
    b.storedReactions[_a1] = [
      const ReactionGroup(emoji: '😢', count: 1, users: ['ana']),
    ];
    b.activity.add(const ConversationActivity.reaction(_a1));
    await tester.pumpAndSettle();
    expect(b.reactionReads, greaterThan(reads));
    expect(_chip(_a1, '😢'), findsOneWidget);
  });

  testWidgets(
    'holding a chip shows who reacted, and your row takes yours back',
    (tester) async {
      final b = _backend()
        ..storedReactions[_a1] = [
          const ReactionGroup(
            emoji: '👍',
            count: 2,
            mine: true,
            users: ['me', 'ana'],
          ),
          const ReactionGroup(emoji: '❤️', count: 1, bots: ['b1']),
        ]
        ..storedReactionPeople = const [
          ReactionPerson(emoji: '👍', name: 'Oliver', userId: 'me'),
          ReactionPerson(emoji: '👍', name: 'Ana', userId: 'ana'),
          ReactionPerson(emoji: '❤️', name: 'Helper', botId: 'b1'),
        ];
      await _open(tester, b);
      await tester.longPress(_chip(_a1, '❤️'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reactionPeople')), findsOneWidget);
      // Opens on the emoji held.
      expect(find.text('Helper'), findsOneWidget);
      expect(find.text('Ana'), findsNothing);
      await tester.tap(find.byKey(const Key('reactionTab-all')));
      await tester.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reactionPeople')), findsNothing);
      expect(b.reactionCalls, ['remove $_a1']);
    },
  );

  testWidgets('the + opens the full emoji picker', (tester) async {
    await _open(tester);
    await _longPress(tester, 'Booked the 9:04 to Lyon.');
    await tester.tap(find.byKey(const Key('moreReactions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emojiPicker')), findsOneWidget);
  });

  testWidgets('with a mouse, the smile in the hover buttons opens the strip', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final b = await _open(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(
        tester.getCenter(find.text('Booked the 9:04 to Lyon.')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hoverReact')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quickReaction-😂')));
      await tester.pumpAndSettle();
      expect(b.reactionCalls, ['set $_a1 😂']);
      expect(_chip(_a1, '😂'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
