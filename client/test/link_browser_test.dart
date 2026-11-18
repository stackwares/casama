import 'package:casama/core/link_browser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('links open in the app until turned off', () async {
    SharedPreferences.setMockInitialValues({});
    await LinkBrowserInApp.preload();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(linkBrowserInAppProvider), isTrue);
  });

  test('the choice is kept on the device and read at startup', () async {
    SharedPreferences.setMockInitialValues({});
    await LinkBrowserInApp.preload();
    final first = ProviderContainer();
    await first.read(linkBrowserInAppProvider.notifier).set(false);
    first.dispose();
    expect(
      (await SharedPreferences.getInstance()).getBool('links.inApp'),
      isFalse,
    );

    LinkBrowserInApp.debugSet(true);
    await LinkBrowserInApp.preload();
    final next = ProviderContainer();
    addTearDown(next.dispose);
    expect(next.read(linkBrowserInAppProvider), isFalse);
  });

  test('only web addresses open', () async {
    expect(await openWebLink(Uri.parse('mailto:a@b.c')), isFalse);
    expect(await openWebLink(Uri.parse('javascript:alert(1)')), isFalse);
  });
}
