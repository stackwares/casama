// Message actions: hover buttons with a mouse, a long-press that shows it's registering on touch.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/chat/widgets/message_actions.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

Widget _message({VoidCallback? onEdit}) => Scaffold(
  body: Center(
    child: MessageActions(
      text: 'Pack the snow boots',
      onEdit: onEdit,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Pack the snow boots', key: Key('bubble')),
      ),
    ),
  ),
);

double _opacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byKey(const Key('messageHoverBar')),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

void main() {
  testWidgets(
    'a mouse over a message shows its buttons, without moving anything',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      var edited = false;
      await tester.pumpWidget(
        harness(FakeBackend(), _message(onEdit: () => edited = true)),
      );
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.byKey(const Key('bubble')));
      expect(_opacity(tester), 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(const Key('bubble'))));
      await tester.pumpAndSettle();
      expect(_opacity(tester), 1);
      expect(tester.getTopLeft(find.byKey(const Key('bubble'))), before);

      await tester.tap(find.byKey(const Key('hoverEdit')));
      await tester.pumpAndSettle();
      expect(edited, isTrue);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'holding a bubble shrinks it as the long-press builds, then opens the menu',
    (tester) async {
      await tester.pumpWidget(harness(FakeBackend(), _message()));
      await tester.pumpAndSettle();
      // The x scale of the bubble's own Transform (the z axis always stays 1).
      double scale() => tester
          .widget<Transform>(
            find.descendant(
              of: find.byType(MessageActions),
              matching: find.byType(Transform),
            ),
          )
          .transform
          .storage[0];
      final hold = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('bubble'))),
      );
      // The first frame starts the animation's clock; the second is 300 ms into the hold.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scale(), lessThan(1));
      await tester.pump(const Duration(milliseconds: 300));
      await hold.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('msgCopy')), findsOneWidget);
      expect(scale(), 1);
    },
  );
}
