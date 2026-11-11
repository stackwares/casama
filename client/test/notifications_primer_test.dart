import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/notifications/notifications_primer.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('the notifications page explains why, and its buttons turn on or put it off', (tester) async {
    var on = 0, later = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NotificationsPrimer(onEnable: () => on++, onLater: () => later++),
    ));
    await tester.pump();
    expect(find.text('Turn on notifications'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notificationsTurnOn')));
    await tester.tap(find.byKey(const Key('notificationsNotNow')));
    expect((on, later), (1, 1));
  });
}
