import 'package:casama_app/core/widgets.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Past times read as "3 hours ago", with the exact date and time on hover or long press.
void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('shows how long ago, and the exact time in a tooltip', (
    tester,
  ) async {
    final at = DateTime.now().subtract(const Duration(hours: 3));
    await tester.pumpWidget(app(TimeAgo(at, label: (when) => 'Updated $when')));
    expect(find.text('Updated 3 hours ago'), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, contains('${at.year}'));
    expect(tooltip.message, contains(' · '));
  });

  testWidgets('older than a week shows the date', (tester) async {
    await tester.pumpWidget(app(TimeAgo(DateTime(2026, 1, 5, 9))));
    expect(find.text('Jan 5, 2026'), findsOneWidget);
  });
}
