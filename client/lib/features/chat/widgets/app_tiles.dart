import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../integrations/app_logo.dart';
import '../../integrations/connect_app_sheet.dart';
import '../../integrations/integrations_screen.dart' show hubAppsProvider;

/// The apps most people connect first, in the order shown (D-204).
const starterAppIds = ['gmail', 'google_calendar', 'google_drive', 'notion', 'github', 'slack'];

/// Once this many apps are connected, an empty chat stops suggesting more.
const _enoughApps = 2;

/// One-tap tiles for the apps worth connecting first, shown in an empty chat until two apps are
/// connected (D-204). Only apps that connect in one click on this server are offered, and ones
/// already connected (directly or through a hub such as Composio) are left out.
class ConnectAppTiles extends ConsumerWidget {
  const ConnectAppTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(appCatalogProvider).value;
    final integrations = ref.watch(integrationsProvider).value;
    final hubApps = ref.watch(hubAppsProvider).value ?? const [];
    if (catalog == null || integrations == null) return const SizedBox.shrink();
    final connected = {
      for (final i in integrations) ?i.appId,
      for (final h in hubApps)
        if (h.status == ProviderAccountStatusEnum.connected) ?h.app?.id,
    };
    if (connected.length >= _enoughApps) return const SizedBox.shrink();
    final apps = [
      for (final id in starterAppIds)
        if (catalog.apps.where((a) => a.id == id).firstOrNull case final app?)
          if (!connected.contains(app.id) && _oneClick(app)) app,
    ];
    if (apps.isEmpty) return const SizedBox.shrink();
    final scheme = context.colorScheme;
    final l10n = context.l10n;
    return Column(
      key: const Key('connectAppTiles'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.connectAppsTitle, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(l10n.connectAppsHint, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [for (final app in apps) _AppTile(app: app)],
        ),
      ],
    );
  }
}

/// Connects without a key: the app's own sign-in, or the server's Composio account.
bool _oneClick(CatalogApp a) =>
    (a.auth.contains(CatalogAppAuthEnum.oauth) && a.oauthAvailable) || a.auth.contains(CatalogAppAuthEnum.managed);

class _AppTile extends ConsumerWidget {
  const _AppTile({required this.app});
  final CatalogApp app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: context.l10n.connectAppTile(app.name),
      excludeSemantics: true,
      child: Tooltip(
        message: app.name,
        child: InkWell(
          key: Key('connectTile-${app.id}'),
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: () async {
            await showConnectApp(context, app);
            ref.invalidate(integrationsProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(appId: app.id, name: app.name, color: app.color, size: 44),
                  const SizedBox(height: 6),
                  Text(
                    app.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
