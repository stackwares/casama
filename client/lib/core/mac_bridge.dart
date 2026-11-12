import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/bots/bots_screen.dart' show CreateBotSheet;
import '../features/chat/chat_controller.dart';
import '../features/search/search_view.dart';
import '../ui/adaptive_modal.dart';
import 'providers.dart';
import 'router.dart';
import 'updater.dart';
import 'analytics.dart';

/// Where Help in the menu bar goes (overridable per build until the docs site has its address).
const kHelpUrl = String.fromEnvironment('CASAMA_HELP_URL', defaultValue: 'https://github.com/stackwares/casama/tree/main/docs-site');

const _channel = MethodChannel('casama/mac');

bool get _isMac => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// The Mac app's menu bar actions (File, Go, Settings…, Help) and its dock badge: the count of
/// what waits for you, the same as the Inbox badge. Watched by the app root on macOS.
final macBridgeProvider = Provider<void>((ref) {
  if (!_isMac) return;
  _channel.setMethodCallHandler((call) async {
    if (call.method == 'menu' && call.arguments is String) await _menu(ref, call.arguments as String);
    return null;
  });
  ref.onDispose(() => _channel.setMethodCallHandler(null));
  ref.listen<int>(inboxBadgeProvider, (_, count) => unawaited(_channel.invokeMethod('badge', count).catchError((_) => null)), fireImmediately: true);
});

Future<void> _menu(Ref ref, String action) async {
  Analytics.feature('mac_menu');
  final router = ref.read(routerProvider);
  final context = router.routerDelegate.navigatorKey.currentContext;
  final location = router.routerDelegate.currentConfiguration.uri.path;
  switch (action) {
    case 'settings':
      router.go('/settings');
    case 'newChat':
      // In a bot's chat: a fresh conversation there. Elsewhere: the bots.
      final bot = RegExp(r'^/bots/([^/]+)/chat').firstMatch(location)?.group(1);
      if (bot != null) {
        await ref.read(chatControllerProvider(bot).notifier).newChat();
      } else {
        router.go('/bots');
      }
    case 'newBot':
      if (context != null && context.mounted) await showAdaptiveSheet<void>(context: context, contentPadsBottom: true, builder: (_) => const CreateBotSheet());
    case 'search':
      if (context != null && context.mounted) await showWorkspaceSearch(context);
    case 'checkUpdates':
      await checkForUpdatesNow();
    case 'help':
      await launchUrl(Uri.parse(kHelpUrl), mode: LaunchMode.externalApplication);
    default:
      if (action.startsWith('go:/')) router.go(action.substring(3));
  }
}

/// "Open at login" (macOS 13+): null where the system can't do it.
final launchAtLoginProvider = FutureProvider<bool?>((ref) async {
  if (!_isMac) return null;
  try {
    return await _channel.invokeMethod<bool>('launchAtLogin');
  } catch (_) {
    return null;
  }
});

Future<bool?> setLaunchAtLogin(bool on) => _channel.invokeMethod<bool>('setLaunchAtLogin', on);
