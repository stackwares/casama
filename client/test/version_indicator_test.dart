import 'package:casama_app/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('Settings ends with the version and build; a tap copies it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(appName: 'casama_app', packageName: 'ai.casama.app', version: '0.8.0', buildNumber: '8', buildSignature: '');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await setSize(tester, const Size(430, 3200));
    await tester.pumpWidget(harness(FakeBackend(), const SettingsScreen()));
    await tester.pumpAndSettle();
    // "Casama", not the package name, and the build number in brackets.
    expect(find.text('Casama 0.8.0 (8)'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('appVersion')));
    await tester.tap(find.byKey(const Key('appVersion')));
    await tester.pumpAndSettle();
    expect(copied, 'Casama 0.8.0 (8)');
    expect(find.text('Copied'), findsOneWidget);
  });
}
