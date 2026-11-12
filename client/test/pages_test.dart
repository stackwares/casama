import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/pages/pages_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('pages open in the browser through a view link, export PDF, go public with a warning, and delete', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend();
    final opened = <Uri>[];
    await tester.pumpWidget(harness(backend, const PagesScreen(), overrides: [pageOpenerProvider.overrideWithValue((Uri u) async => opened.add(u))]));
    await tester.pumpAndSettle();
    expect(find.text('Weekly sales'), findsOneWidget);
    expect(find.textContaining('Refreshes on schedule'), findsOneWidget);

    await tester.tap(find.text('Weekly sales'));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), 'https://pages.example.com/v/tok-page-1');

    await tester.tap(find.byKey(const Key('pageMenu-page-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export PDF'));
    await tester.pumpAndSettle();
    expect(backend.pageActions.last, 'pdf:page-1');

    await tester.tap(find.byKey(const Key('pageMenu-page-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anyone with the link'));
    await tester.pumpAndSettle();
    expect(find.text('Make this page public?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmPublic')));
    await tester.pumpAndSettle();
    expect(backend.pageActions.last, 'public:page-1');
    expect(tester.widget<SelectableText>(find.byKey(const Key('publicPageUrl'))).data, 'https://pages.example.com/s/public-page-1');
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pageMenu-page-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeletePage')));
    await tester.pumpAndSettle();
    expect(backend.pageActions.last, 'delete:page-1');
    expect(find.text('No pages yet'), findsOneWidget);
  });
}
