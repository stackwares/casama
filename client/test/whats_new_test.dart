import 'dart:io';

import 'package:casama_app/features/whats_new/whats_new.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

/// The app's version from pubspec.yaml ("0.1.0" from "version: 0.1.0+10").
final _appVersion = RegExp(r'^version:\s*([^+\s]+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  setUp(() => PackageInfo.setMockInitialValues(appName: 'Casama', packageName: 'ai.casama.app', version: _appVersion, buildNumber: '1', buildSignature: ''));

  test("every app version has its what's-new lines (add them when pubspec.yaml's version goes up)", () {
    expect(whatsNewByVersion(l10n)[_appVersion], isNotEmpty, reason: 'Add $_appVersion to whatsNewByVersion in lib/features/whats_new/whats_new.dart, with its strings in app_en.arb');
  });

  test('someone who skipped updates sees everything since the version they last saw, newest first', () {
    const log = {
      '1.3.0': ['c'],
      '1.2.0': ['a', 'b'],
      '1.1.0': ['old'],
    };
    expect(unseenChanges(lastSeen: '1.1.0', current: '1.3.0', changelog: log), ['c', 'a', 'b']);
    expect(unseenChanges(lastSeen: '1.2.0', current: '1.3.0', changelog: log), ['c']);
    expect(unseenChanges(lastSeen: '1.3.0', current: '1.3.0', changelog: log), isEmpty);
    // A downgrade, or a version that can't be read: nothing.
    expect(unseenChanges(lastSeen: '1.3.0', current: '1.2.0', changelog: log), isEmpty);
    expect(unseenChanges(lastSeen: 'garbage', current: '1.3.0', changelog: log), isEmpty);
  });

  Future<void> openApp(WidgetTester tester) async {
    final backend = FakeBackend();
    // The name page was answered, so nothing sits above the app.
    backend.about = backend.about.copyWith(nameAsked: true);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(harness(backend, const WhatsNewGate(child: Scaffold(body: Text('home')))));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('a fresh install shows nothing and remembers this version', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await openApp(tester);
    expect(find.byKey(const Key('whatsNewSheet')), findsNothing);
    expect((await SharedPreferences.getInstance()).getString(whatsNewSeenKey), _appVersion);
  });

  testWidgets('after an update the new lines come up once', (tester) async {
    SharedPreferences.setMockInitialValues({whatsNewSeenKey: '0.0.1'});
    await openApp(tester);
    expect(find.byKey(const Key('whatsNewSheet')), findsOneWidget);
    expect(find.text(l10n.whatsNewTitle(_appVersion)), findsOneWidget);
    expect(find.text(whatsNewByVersion(l10n)[_appVersion]!.first), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString(whatsNewSeenKey), _appVersion);
    await tester.tap(find.byKey(const Key('whatsNewDone')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('whatsNewSheet')), findsNothing);
    // The next open: nothing new.
    await openApp(tester);
    expect(find.byKey(const Key('whatsNewSheet')), findsNothing);
  });
}
