import 'dart:convert';
import 'dart:typed_data';

import 'package:casama_app/core/media_cache.dart';
import 'package:casama_app/features/integrations/app_logo.dart';
import 'package:casama_app/ui/smooth_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  testWidgets('an SVG app logo (Composio serves SVG) draws as a vector, not the initial', (tester) async {
    const url = 'https://logos.composio.dev/api/gmail';
    final svg = '<?xml version="1.0"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect width="10" height="10" fill="#f00"/></svg>';
    await MediaCache.write('logo:$url', Uint8List.fromList(utf8.encode(svg)));
    await tester.pumpWidget(host(const AppLogo(name: 'Gmail', imageUrl: url, size: 40)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('G'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a raster app logo (Pipedream serves PNG) draws as an image', (tester) async {
    const url = 'https://assets.pipedream.net/s.v0/app_github/logo/orig';
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==');
    await MediaCache.write('logo:$url', png);
    await tester.pumpWidget(host(const AppLogo(name: 'GitHub', imageUrl: url, size: 40)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
