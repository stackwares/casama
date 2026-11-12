import 'package:material_ui/material_ui.dart';

import 'appearance.dart';
import 'fonts.dart';
import 'presets.dart';
import 'schemes.dart';

/// A look a bot suggested in a chat card (D-242): `app:appearance` with any of preset, mode,
/// scheme, heading_font, body_font and fewer_effects. Unknown values are dropped, so a bot can't
/// set a scheme or font this app doesn't have. Applied on this device only; returns [before] (the
/// current look), for Undo, or null when nothing in it was usable.
Future<Appearance?> applySuggestedLook(Appearance before, AppearanceNotifier notifier, Map<String, Object?> ctx) async {
  var changed = false;

  final preset = builtInPresets.where((p) => p.id == ctx['preset']).firstOrNull;
  if (preset != null) {
    await notifier.applyPreset(preset);
    changed = true;
  }
  final scheme = ctx['scheme'];
  if (scheme is String && themeChoices.any((c) => c.id == scheme)) {
    await notifier.setScheme(scheme);
    changed = true;
  }
  bool known(Object? font, List<String> curated) =>
      font is String && (curated.contains(font) || bundledFonts.contains(font));
  final heading = ctx['heading_font'];
  final body = ctx['body_font'];
  final okHeading = known(heading, curatedHeadingFonts);
  final okBody = known(body, curatedBodyFonts);
  if (okHeading || okBody) {
    await notifier.setFonts(heading: okHeading ? heading as String : null, body: okBody ? body as String : null);
    changed = true;
  }
  final mode = ThemeMode.values.asNameMap()[ctx['mode']];
  if (mode != null) {
    await notifier.setMode(mode);
    changed = true;
  }
  final fewer = ctx['fewer_effects'];
  if (fewer is bool) {
    await notifier.setFewerEffects(fewer);
    changed = true;
  }
  return changed ? before : null;
}

/// Puts back a look saved by [applySuggestedLook].
Future<void> restoreLook(AppearanceNotifier notifier, Appearance look) async {
  await notifier.apply(
    schemeId: look.schemeId,
    headingFont: look.headingFont,
    bodyFont: look.bodyFont,
    wallpaper: look.wallpaper,
    fewerEffects: look.fewerEffects,
  );
  await notifier.setMode(look.mode);
}
