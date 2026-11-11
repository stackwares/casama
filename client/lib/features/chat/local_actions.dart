import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../settings/model_keys_screen.dart';
import '../integrations/connect_app_sheet.dart';
import 'widgets/bot_ui.dart';

/// Card actions the app handles itself (D-129): "app:connect" opens a connection, "app:route" a
/// screen, "app:invite" makes an invite link. They never reach the server. Returns whether the
/// action was one of these.
Future<bool> handleLocalUiAction(BuildContext context, WidgetRef ref, BotUiAction action) async {
  if (!action.name.startsWith('app:')) return false;
  final ctx = action.context;
  switch (action.name) {
    case 'app:route':
      final path = ctx['path'];
      if (path is String && path.startsWith('/')) {
        final provider = ctx['provider'];
        // "Continue with ChatGPT" signs in right here where the app can (desktop, D-091).
        if (provider == 'chatgpt' && ref.read(backendProvider).canConnectChatGpt) {
          final cred = await connectChatGptPlan(context, ref);
          if (cred != null) ref.invalidate(credentialsProvider);
          return true;
        }
        // Elsewhere ChatGPT sign-in can't run; say so and offer a key instead.
        if (provider == 'chatgpt') showMessage(context, context.l10n.chatGptDesktopOnly);
        final target = provider is String && provider != 'chatgpt' ? '$path?provider=$provider' : path;
        unawaited(GoRouter.maybeOf(context)?.push(target) ?? Future<void>.value());
      }
    case 'app:connect':
      final id = ctx['app'];
      final catalog = await runGuarded(context, () => ref.read(appCatalogProvider.future));
      final app = catalog?.apps.where((a) => a.id == id).firstOrNull;
      if (app != null && context.mounted) {
        await showConnectApp(context, app);
        ref.invalidate(integrationsProvider);
      }
    case 'app:invite':
      final org = ref.read(currentOrgProvider);
      if (org == null) return true;
      // The workspace's standing link (D-167), not a new one each time.
      final link = await runGuarded(context, () => ref.read(backendProvider).defaultInvite(org.id));
      if (link != null && context.mounted) {
        try {
          await Clipboard.setData(ClipboardData(text: link.url));
        } catch (_) {}
        if (context.mounted) showMessage(context, context.l10n.inviteLinkCopied);
      }
  }
  return true;
}
