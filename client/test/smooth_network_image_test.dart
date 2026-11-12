import 'package:casama_app/features/integrations/app_logo.dart';
import 'package:casama_app/ui/smooth_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 120, height: 160, child: child)),
    ),
  );

  // Widget tests answer every web request with HTTP 400, so these pictures always fail.
  Future<void> letItFail(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('a web picture holds a plain tone while loading, then a faint mark if it fails', (tester) async {
    await tester.pumpWidget(host(const SmoothNetworkImage('https://example.com/photo.jpg', placeholderColor: Color(0xFF336699))));
    expect(find.byType(Image), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == const Color(0xFF336699)), findsOneWidget);
    expect(find.byIcon(LucideIcons.imageOff), findsNothing);
    await letItFail(tester);
    expect(find.byIcon(LucideIcons.imageOff), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a remote app logo that cannot load shows the app initial, not a broken mark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppLogo(name: 'Notion', imageUrl: 'https://example.com/logo.png', size: 40),
          ),
        ),
      ),
    );
    await letItFail(tester);
    expect(find.text('N'), findsOneWidget);
    expect(find.byIcon(LucideIcons.imageOff), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
