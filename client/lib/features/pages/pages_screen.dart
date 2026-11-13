import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Pages (D-092, D-119): web pages bots publish. The app never embeds them: they open in the
/// system's in-app browser (Safari View Controller, Chrome Custom Tabs), the default browser on
/// desktop, or a new tab on the web, through a single-use view link. They are listed, shared and
/// deleted in the Library now (D-274); this file keeps what opens them.
final pagesProvider = FutureProvider.autoDispose.family<List<BotPage>, String?>((ref, botId) async {
  // Every bot's recent pages show among the Updates: kept when it closes, so it opens with what
  // it showed (it refreshes them as it opens).
  if (botId == null) ref.keepAlive();
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).pages(org.id, botId: botId);
});

/// Opens a page link; replaced in tests.
final pageOpenerProvider = Provider<Future<void> Function(Uri url)>((ref) => openInAppBrowser);

Future<void> openInAppBrowser(Uri url) async {
  final mobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  await launchUrl(url, mode: mobile ? LaunchMode.inAppBrowserView : LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}

/// Opens [page] through a single-use view link (or its PDF), never inside the app.
Future<void> openBotPage(BuildContext context, WidgetRef ref, BotPage page, {bool pdf = false}) async {
  final url = await runGuarded(context, () => ref.read(backendProvider).pageViewLink(page.id, pdf: pdf));
  if (url != null) await ref.read(pageOpenerProvider)(Uri.parse(url));
}
