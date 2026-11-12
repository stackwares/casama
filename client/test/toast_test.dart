import 'package:casama_app/core/widgets.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? clipboard;
  setUp(() {
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  Widget app(void Function(BuildContext) onTap) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onTap(context),
          child: const Text('Go'),
        ),
      ),
    ),
  );

  testWidgets('an error message has a Copy button that copies its full text', (
    tester,
  ) async {
    await tester.pumpWidget(
      app((c) => showError(c, StateError('token refresh failed'))),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.circleAlert), findsOneWidget);
    expect(find.byTooltip('Copy'), findsOneWidget);
    await tester.tap(find.byKey(const Key('toastCopy')));
    await tester.pump();
    expect(clipboard, contains('token refresh failed'));
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.copy), findsOneWidget);
  });

  testWidgets(
    'success, warning and plain messages have their own icon and no Copy button',
    (tester) async {
      for (final (show, icon) in [
        ((BuildContext c) => showSuccess(c, 'Saved'), LucideIcons.circleCheck),
        (
          (BuildContext c) => showWarning(c, 'Check the email'),
          LucideIcons.triangleAlert,
        ),
        ((BuildContext c) => showMessage(c, 'Copied'), LucideIcons.info),
      ]) {
        await tester.pumpWidget(app(show));
        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();
        expect(find.byIcon(icon), findsOneWidget);
        expect(find.byKey(const Key('toastCopy')), findsNothing);
        ScaffoldMessenger.of(tester.element(find.text('Go')))
            .removeCurrentSnackBar();
        await tester.pumpAndSettle();
      }
    },
  );
}
