import 'package:casama/features/admin/remote_settings_cards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

void main() {
  testWidgets(
    'the owner edits a JSON setting; bad JSON is refused before saving',
    (tester) async {
      final backend = FakeBackend();
      await tester.pumpWidget(
        harness(
          backend,
          const Scaffold(
            body: AdminJsonSettingTile(kind: AdminJsonSettingKind.modelCatalog),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('adminJson-modelCatalog')));
      await tester.pumpAndSettle();

      final field = find.byKey(const Key('adminJsonField-modelCatalog'));
      await tester.enterText(field, '{not json');
      await tester.tap(find.byKey(const Key('adminJsonSave-modelCatalog')));
      await tester.pumpAndSettle();
      expect(backend.adminJsonSettings, isEmpty);

      await tester.enterText(
        field,
        '{"default_models": {"openrouter": "acme/model-1"}}',
      );
      await tester.tap(find.byKey(const Key('adminJsonSave-modelCatalog')));
      await tester.pumpAndSettle();
      expect(backend.adminJsonSettings[AdminJsonSettingKind.modelCatalog], {
        'default_models': {'openrouter': 'acme/model-1'},
      });
      expect(field, findsNothing);
    },
  );
}
