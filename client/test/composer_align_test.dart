import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/chat/widgets/composer.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';

void main() {
  // Phones pad the buttons to 48pt tap targets; desktop keeps them at 40pt.
  for (final tapTarget in MaterialTapTargetSize.values) {
    testWidgets('the hint and the typed text sit on the send button ($tapTarget)', (tester) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(materialTapTargetSize: tapTarget),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ChatComposer(
                controller: controller,
                focusNode: focus,
                hint: 'Say something',
                running: false,
                onSend: () {},
                onStop: () {},
                recording: false,
                transcribing: false,
                onDictate: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      final sendCenter = tester.getCenter(find.byTooltip('Send')).dy;
      expect((tester.getCenter(find.text('Say something')).dy - sendCenter).abs(), lessThan(1));

      controller.text = 'Hello';
      await tester.pump();
      expect((tester.getCenter(find.text('Hello')).dy - sendCenter).abs(), lessThan(1));
    });
  }
}
