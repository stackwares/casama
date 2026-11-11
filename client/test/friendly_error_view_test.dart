import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:casama_app/ui/friendly_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FlutterErrorDetails details() => FlutterErrorDetails(exception: StateError('boom'), stack: StackTrace.current);

  Widget app(Widget home) => MaterialApp(theme: AppTheme.light(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: home);

  testWidgets('a broken screen says something went wrong, in the app colors', (tester) async {
    await tester.pumpWidget(app(FriendlyErrorView(details: details())));
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Restarting the app should fix it.'), findsOneWidget);
    // Tests run in debug, where the view also shows what broke.
    expect(find.textContaining('boom'), findsOneWidget);
    // The view's own box (the badge uses a ShapeDecoration, the box a BoxDecoration).
    final box = tester.widgetList<Container>(find.descendant(of: find.byType(FriendlyErrorView), matching: find.byType(Container))).firstWhere((c) => c.decoration is BoxDecoration);
    expect((box.decoration! as BoxDecoration).color, AppTheme.light().colorScheme.primaryContainer);
  });

  testWidgets('a broken small slot shows only the badge', (tester) async {
    await tester.pumpWidget(
      app(
        Center(
          child: SizedBox(width: 60, height: 60, child: FriendlyErrorView(details: details())),
        ),
      ),
    );
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
  });

  testWidgets('it works above the app too, in English', (tester) async {
    await tester.pumpWidget(FriendlyErrorView(details: details()));
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('a long press copies the error, with no visible button', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(app(FriendlyErrorView(details: details())));
    await tester.longPress(find.byType(FriendlyErrorView));
    await tester.pump();
    expect(copied, contains('boom'));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
  });

  testWidgets('a widget that throws while building shows it', (tester) async {
    final original = ErrorWidget.builder;
    ErrorWidget.builder = (d) => FriendlyErrorView(details: d);
    try {
      await tester.pumpWidget(app(Builder(builder: (_) => throw StateError('boom'))));
      expect(tester.takeException(), isA<StateError>());
      expect(find.byType(FriendlyErrorView), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    } finally {
      // The test framework checks this right after the test body, before tear-downs run.
      ErrorWidget.builder = original;
    }
  });
}
