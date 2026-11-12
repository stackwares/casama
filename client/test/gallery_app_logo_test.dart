import 'dart:convert';

import 'package:casama_app/core/app_marks.dart';
import 'package:casama_app/core/media_cache.dart';
import 'package:casama_app/features/integrations/app_logo.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _url = 'https://gallery.casama.ai/apps/canva/logo.svg';
const _svg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="10"/></svg>';

CatalogApp _app(String id, {String? logoUrl}) => CatalogApp(
  id: id,
  name: id,
  description: '',
  category: CatalogAppCategoryEnum.design,
  color: '00C4CC',
  homepage: 'https://example.com',
  url: 'https://example.com/mcp',
  auth: const [CatalogAppAuthEnum.oauth],
  capabilities: const [],
  popular: false,
  oauthAvailable: true,
  logoUrl: logoUrl,
);

void main() {
  setUp(galleryAppMarks.clear);

  test('only https marks from the catalog are kept', () {
    rememberAppMarks([
      _app('canva', logoUrl: _url),
      _app('plain', logoUrl: 'http://x.test/a.svg'),
      _app('none'),
    ]);
    expect(galleryAppMarks, {'canva': _url});
  });

  testWidgets('a gallery app draws its mark tinted on its brand color', (
    tester,
  ) async {
    rememberAppMarks([_app('canva', logoUrl: _url)]);
    await MediaCache.write('logo:$_url', utf8.encode(_svg));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(
            child: AppLogo(appId: 'canva', name: 'Canva', color: '00C4CC'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('C'), findsNothing);
  });

  testWidgets('an app without a mark keeps its initial', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(
            child: AppLogo(
              appId: 'deepwiki',
              name: 'DeepWiki',
              color: '1A1A2E',
            ),
          ),
        ),
      ),
    );
    expect(find.text('D'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });
}
