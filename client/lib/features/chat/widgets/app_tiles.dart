import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../integrations/app_logo.dart';
import '../../integrations/connect_app_sheet.dart';
import '../../integrations/integrations_screen.dart' show hubAppsProvider;

/// The apps most people connect first, in the order shown (D-204).
const starterAppIds = ['gmail', 'google_calendar', 'google_drive', 'notion', 'github', 'slack'];

/// Once this bot has this many apps, an empty chat stops suggesting more.
const _enoughApps = 2;

/// One-tap tiles for the apps worth connecting first, shown in an empty chat until the bot has two
/// apps (D-204). An app the workspace already connected but this bot doesn't have yet is offered
/// as "add to this bot" (no new sign-in); one it already has is left out, and so is one connected
/// only through a hub such as Composio. Only apps that connect in one click on this server are
/// offered to connect. More opens the apps catalog directly, where a second account or any other app is added.
class ConnectAppTiles extends ConsumerWidget {
  const ConnectAppTiles({super.key, required this.botId, required this.botName});
  final String botId;
  final String botName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(appCatalogProvider).value;
    final integrations = ref.watch(integrationsProvider).value;
    final attached = ref.watch(botIntegrationIdsProvider(botId)).value;
    final hubApps = ref.watch(hubAppsProvider).value ?? const [];
    if (catalog == null || integrations == null || attached == null) return const SizedBox.shrink();
    final hubConnected = {
      for (final h in hubApps)
        if (h.status == ProviderAccountStatusEnum.connected) ?h.app?.id,
    };
    final botApps = {
      for (final i in integrations)
        if (attached.contains(i.id)) ?i.appId,
    };
    if (botApps.length >= _enoughApps) return const SizedBox.shrink();
    final tiles = <Widget>[
      for (final id in starterAppIds)
        if (catalog.apps.where((a) => a.id == id).firstOrNull case final app?)
          if (!botApps.contains(app.id) && !hubConnected.contains(app.id))
            if (integrations.where((i) => i.appId == app.id).firstOrNull case final existing?)
              _AppTile(app: app, add: true, onTap: () => _add(context, ref, app, existing))
            else if (_oneClick(app))
              _AppTile(
                app: app,
                onTap: () async {
                  await showConnectApp(context, app);
                  ref
                    ..invalidate(integrationsProvider)
                    ..invalidate(botIntegrationIdsProvider(botId));
                },
              ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    final scheme = context.colorScheme;
    final l10n = context.l10n;
    return Column(
      key: const Key('connectAppTiles'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(l10n.connectAppsTitle, textAlign: TextAlign.center, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(l10n.connectAppsHint, textAlign: TextAlign.center, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            ...tiles,
            _MoreTile(
              onTap: () async {
                await context.push('/settings/integrations');
                ref
                  ..invalidate(integrationsProvider)
                  ..invalidate(botIntegrationIdsProvider(botId));
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Switches an app the workspace already connected on for this bot: no new sign-in.
  Future<void> _add(BuildContext context, WidgetRef ref, CatalogApp app, Integration existing) async {
    final l10n = context.l10n;
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).setBotIntegration(botId, existing.id, true);
      return true;
    });
    if (ok != true) return;
    ref
      ..invalidate(botIntegrationIdsProvider(botId))
      ..invalidate(integrationsProvider);
    if (context.mounted) showSuccess(context, l10n.appAddedToBot(app.name, botName));
  }
}

/// Connects without a key: the app's own sign-in, or the server's Composio account.
bool _oneClick(CatalogApp a) =>
    (a.auth.contains(CatalogAppAuthEnum.oauth) && a.oauthAvailable) || a.auth.contains(CatalogAppAuthEnum.managed);

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app, required this.onTap, this.add = false});
  final CatalogApp app;
  final VoidCallback onTap;

  /// Already connected in the workspace: tapping adds it to this bot.
  final bool add;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Semantics(
      button: true,
      label: add ? l10n.addAppTile(app.name) : l10n.connectAppTile(app.name),
      excludeSemantics: true,
      child: Tooltip(
        message: add ? l10n.addAppTile(app.name) : app.name,
        child: InkWell(
          key: Key('${add ? 'addTile' : 'connectTile'}-${app.id}'),
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppLogo(appId: app.id, name: app.name, color: app.color, size: 44),
                      if (add)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                            ),
                            child: Icon(LucideIcons.plus, size: 12, color: scheme.onPrimary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_shortName(app.name), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: context.textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The last tile: every app, including a second account of one already connected.
class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final l10n = context.l10n;
    return Tooltip(
      message: l10n.browseApps,
      child: InkWell(
        key: const Key('moreAppsTile'),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.icon + 2),
                  ),
                  child: Icon(LucideIcons.layoutGrid, size: 20, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(l10n.moreApps, maxLines: 1, textAlign: TextAlign.center, style: context.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tile's label: the brand dropped from suite apps ("Google Calendar" → "Calendar"), since the
/// logo already says whose it is and the full name doesn't fit 64 points.
String _shortName(String name) {
  for (final brand in const ['Google ', 'Microsoft ']) {
    if (name.startsWith(brand) && name.length > brand.length) return name.substring(brand.length);
  }
  return name;
}
