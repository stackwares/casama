// A call on a folding phone (D-411): partly folded, the bot and the captions on the half you look
// at and the buttons on the half under the hand; standing like a tent, everything fits the short,
// wide outer screen.
import 'package:casama/core/fold/fold.dart';
import 'package:casama/features/voice/call_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';
import 'fake_voice.dart';
import 'support/poses.dart';
import 'voice_test.dart' show voiceHarness;

final _iphone = TargetPlatformVariant.only(TargetPlatform.iOS);

Future<FakeCallConnector> _pump(WidgetTester tester, DuoPose pose) async {
  SharedPreferences.setMockInitialValues({});
  setPose(tester, pose);
  final calls = FakeCallConnector();
  await tester.pumpWidget(
    voiceHarness(
      FakeBackend(),
      calls: calls,
      home: const FoldScope(
        child: CallScreen(botId: botId, conversationId: convId),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  calls.call.say('assistant', 'The 9:40 has a window seat left in Comfort.');
  calls.call.say(
    'user',
    'Book it, and add it to my calendar for Friday morning please.',
  );
  await tester.pump();
  await tester.pump();
  return calls;
}

const _buttons = [
  'muteButton',
  'captionsButton',
  'hangUpButton',
  'minimiseCall',
];

void main() {
  testWidgets(
    'laptop: who the call is with above the fold, every button below it',
    (tester) async {
      await _pump(tester, DuoPose.laptop);
      expect(
        tester.getRect(find.byKey(const Key('callStatus'))).bottom,
        lessThanOrEqualTo(455.5),
      );
      for (final key in _buttons) {
        expect(
          tester.getRect(find.byKey(Key(key))).top,
          greaterThanOrEqualTo(495.5),
          reason: key,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: _iphone,
  );

  testWidgets(
    'book: the bot on the left of the fold, the buttons on the right',
    (tester) async {
      await _pump(tester, DuoPose.book);
      expect(
        tester.getRect(find.byKey(const Key('callStatus'))).right,
        lessThanOrEqualTo(455.5),
      );
      for (final key in _buttons) {
        final at = tester.getRect(find.byKey(Key(key)));
        expect(at.left, greaterThanOrEqualTo(495.5), reason: key);
        expect(at.right, lessThanOrEqualTo(951 - 84), reason: key);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: _iphone,
  );

  testWidgets(
    'tent: the short, wide screen fits the call with nothing cut off',
    (tester) async {
      await _pump(tester, DuoPose.tent);
      for (final key in ['muteButton', 'captionsButton', 'hangUpButton']) {
        final at = tester.getRect(find.byKey(Key(key)));
        expect(at.bottom, lessThanOrEqualTo(466 - 34), reason: key);
        expect(at.left, greaterThanOrEqualTo(84), reason: key);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: _iphone,
  );

  testWidgets('closed and open flat keep the phone layout', (tester) async {
    for (final pose in [DuoPose.closed, DuoPose.openTall, DuoPose.openWide]) {
      await _pump(tester, pose);
      expect(
        find.byKey(const Key('hangUpButton')),
        findsOneWidget,
        reason: pose.name,
      );
      expect(tester.takeException(), isNull, reason: pose.name);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  }, variant: _iphone);
}
