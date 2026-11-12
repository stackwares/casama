import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/ui/otp_code_field.dart';

void main() {
  testWidgets(
    'fills six boxes from typing or a pasted code, and submits once',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final completed = <String>[];
      await tester.pumpWidget(_host(controller, onCompleted: completed.add));

      expect(find.byKey(const ValueKey('otp-cell-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('otp-cell-5')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('code')), '123');
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(completed, isEmpty);

      await tester.enterText(find.byKey(const Key('code')), '1234567');
      await tester.pump();
      expect(controller.text, '123456');
      expect(completed, ['123456']);

      await tester.enterText(find.byKey(const Key('code')), '12345');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('code')), '12 34-56');
      await tester.pump();
      expect(controller.text, '123456');
      expect(completed, ['123456', '123456']);
    },
  );

  testWidgets('a rejected code shakes, then clears if it is still there', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var invalid = false;
    Future<void> pump() =>
        tester.pumpWidget(_host(controller, invalid: invalid));

    await pump();
    await tester.enterText(find.byKey(const Key('code')), '654321');
    await tester.pump();
    invalid = true;
    await pump();
    expect(find.text('6'), findsOneWidget);
    expect(
      controller.selection.extentOffset - controller.selection.baseOffset,
      6,
    );

    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(find.text('6'), findsNothing);
  });

  testWidgets('the boxes fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: OtpCodeField(
              key: const Key('code'),
              controller: controller,
              label: '6-digit code',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Widget _host(
  TextEditingController controller, {
  ValueChanged<String>? onCompleted,
  bool invalid = false,
  ValueChanged<String>? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: OtpCodeField(
        key: const Key('code'),
        controller: controller,
        label: '6-digit code',
        invalid: invalid,
        onChanged: onChanged,
        onCompleted: onCompleted,
      ),
    ),
  );
}
