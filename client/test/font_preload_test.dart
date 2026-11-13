import 'package:casama_app/theme/appearance.dart';
import 'package:casama_app/theme/fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startup reads the saved look, so the very first frame already has its fonts', () async {
    SharedPreferences.setMockInitialValues({'appearance.font.heading': 'Fraunces', 'appearance.font.body': 'Figtree', 'appearance.mode': 'dark'});
    final look = (await AppearanceNotifier.readSaved())!;
    expect(look.headingFont, 'Fraunces');
    expect(look.bodyFont, 'Figtree');
    expect(look.mode, ThemeMode.dark);
    final container = ProviderContainer(overrides: [appearanceProvider.overrideWith(() => AppearanceNotifier(look))]);
    addTearDown(container.dispose);
    // The first read, with nothing awaited: the saved look, not the defaults.
    expect(container.read(appearanceProvider).headingFont, 'Fraunces');
    expect(container.read(appearanceProvider).mode, ThemeMode.dark);
  });

  test('without a look from startup, the notifier still reads the saved one itself', () async {
    SharedPreferences.setMockInitialValues({'appearance.font.body': 'Figtree'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(appearanceProvider, (_, _) {});
    expect(container.read(appearanceProvider).bodyFont, plainFont);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(appearanceProvider).bodyFont, 'Figtree');
  });

  test('bundled fonts need nothing, and a font that cannot load never blocks startup', () async {
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = true);
    await preloadFonts(heading: defaultHeadingFont, body: defaultBodyFont);
    // Not bundled and not fetchable here: it gives up quietly instead of throwing.
    await preloadFonts(heading: 'Lora', body: 'Inter', timeout: const Duration(seconds: 1));
  });
}
