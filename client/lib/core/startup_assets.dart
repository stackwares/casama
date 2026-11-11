import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../features/integrations/app_logo.dart';
import '../ui/brand_sign_in_buttons.dart';
import '../ui/brand_splash.dart';
import '../ui/mascot.dart';

/// Decodes bundled pictures before a screen asks for them, so they paint with the screen instead of
/// a few frames later. SVGs go into flutter_svg's cache, everything else into Flutter's image cache.
/// A file that can't load is skipped: its widget shows its own fallback when it gets there.
Future<void> precacheAssets({required BuildContext context, required List<String> paths}) async {
  for (final path in paths) {
    if (!context.mounted) return;
    try {
      if (path.endsWith('.svg')) {
        final loader = SvgAssetLoader(path);
        await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
      } else {
        await precacheImage(AssetImage(path), context, onError: (_, _) {});
      }
    } catch (_) {}
  }
}

/// The still poses the first screens show: the ten cloud mascots (the sign-in screen shows all of
/// them; the home screen's Casama mark and the bots' avatars use them) and the blank bot that new
/// accounts see on the home and Bots screens before they have a bot.
List<String> get startupStills => [for (final m in Mascot.values) m.stillAsset, BlankBotImage.stillAsset];

/// Run by the startup gate while the app connects. Waits for the launch still and [startupStills].
/// Then starts, without waiting, what comes a tap or more later: the Google and Apple marks in the
/// sign-in sheet and the bundled app logos on the Connections screens. The mascot loops are left
/// alone: each still pose stands in until its loop loads. The brand loop is decoded by the startup
/// gate itself, so the launch screen can play it without waiting out the connection.
Future<void> precacheStartupAssets(BuildContext context) async {
  await precacheAssets(context: context, paths: [BrandSplash.stillAsset, ...startupStills]);
  if (!context.mounted) return;
  unawaited(_precacheLater(context));
}

Future<void> _precacheLater(BuildContext context) async {
  for (final loader in brandMarkLoaders) {
    try {
      await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
    } catch (_) {}
  }
  if (!context.mounted) return;
  await precacheAssets(context: context, paths: bundledLogoAssets);
}
