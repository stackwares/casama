// Toasts go away on their own (Flutter keeps one with an action, such as Undo, up until tapped),
// for longer when there's more to read or something to fix.
import 'package:casama/core/widgets.dart';
import 'package:casama/ui/toast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test(
    'durations follow the kind, an action and the length, up to 10 seconds',
    () {
      expect(toastDuration('Saved'), const Duration(seconds: 4));
      expect(
        toastDuration('Saved', kind: ToastKind.success),
        const Duration(seconds: 4),
      );
      expect(
        toastDuration('Deleted', hasAction: true),
        const Duration(seconds: 6),
      );
      expect(
        toastDuration('Check the address', kind: ToastKind.warning),
        const Duration(seconds: 6),
      );
      expect(
        toastDuration('Failed', kind: ToastKind.error),
        const Duration(seconds: 7),
      );
      expect(toastDuration('x' * 110), const Duration(seconds: 6));
      expect(
        toastDuration('x' * 2000, kind: ToastKind.error),
        const Duration(seconds: 10),
      );
    },
  );

  testWidgets('a toast with an Undo button still goes away by itself', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showToast(
                context,
                'Deleted',
                action: SnackBarAction(label: 'Undo', onPressed: () {}),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsNothing);
  });
}
