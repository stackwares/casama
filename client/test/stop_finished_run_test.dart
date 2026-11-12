import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

// D-230: a chat that missed a run's end doesn't keep a Stop button that does nothing.
void main() {
  testWidgets(
    'Stop on a run that had already ended clears it instead of doing nothing',
    (tester) async {
      final backend = _StaleRun();
      await tester.pumpWidget(
        harness(
          backend,
          const ChatScreen(botId: botId, conversationId: convId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // The chat thinks a run is going (its end never reached this device): Stop shows.
      expect(find.byKey(const Key('stopButton')), findsOneWidget);

      // The server has nothing running any more and answers Stop with "already finished".
      backend
        ..stale = null
        ..runAlreadyFinished = true;
      await tester.tap(find.byKey(const Key('stopButton')));
      await tester.pump();
      // Past the composer's switch animation.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('stopButton')), findsNothing);
      expect(backend.cancelled, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

/// The server reports a run as going when the chat opens; it has ended by the time Stop is pressed.
class _StaleRun extends FakeBackend {
  String? stale = 'run-old';
  @override
  Future<String?> activeRun(String conversationId) async => stale;
}
