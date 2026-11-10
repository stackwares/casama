import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
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
        unawaited(GoRouter.maybeOf(context)?.push(provider is String ? '$path?provider=$provider' : path) ?? Future<void>.value());
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
      final link = await runGuarded(context, () => ref.read(backendProvider).createInviteLink(org.id, expiresInDays: 7));
      if (link != null && context.mounted) {
        try {
          await Clipboard.setData(ClipboardData(text: link.url));
        } catch (_) {}
        if (context.mounted) showMessage(context, context.l10n.inviteLinkCopied);
      }
  }
  return true;
}
