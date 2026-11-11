import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/edge_fade.dart';
import '../../ui/reveal_when_selected.dart';
import '../../ui/advanced_section.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/glow_button.dart';
import '../../ui/segmented.dart';
import 'app_logo.dart';
import 'connect_app_sheet.dart';
import 'provider_setup.dart';

String integrationKindLabel(BuildContext context, IntegrationKind kind) =>
    switch (kind) {
      IntegrationKind.mcp => context.l10n.kindMcp,
      IntegrationKind.openapi => context.l10n.kindOpenapi,
      IntegrationKind.composio => 'Composio',
      IntegrationKind.pipedream => 'Pipedream Connect',
      IntegrationKind.localMcp => context.l10n.kindLocalMcp,
      IntegrationKind.a2a => context.l10n.kindA2a,
    };

IconData integrationKindIcon(IntegrationKind kind) => switch (kind) {
  IntegrationKind.mcp => LucideIcons.network,
  IntegrationKind.openapi => LucideIcons.braces,
  IntegrationKind.composio => LucideIcons.blocks,
  IntegrationKind.pipedream => LucideIcons.cable,
  IntegrationKind.a2a => LucideIcons.bot,
  IntegrationKind.localMcp => LucideIcons.laptop,
};

String appCategoryLabel(BuildContext context, CatalogAppCategoryEnum c) {
  final l10n = context.l10n;
  return switch (c) {
    CatalogAppCategoryEnum.developer => l10n.appCatDeveloper,
    CatalogAppCategoryEnum.productivity => l10n.appCatProductivity,
    CatalogAppCategoryEnum.google => l10n.appCatGoogle,
    CatalogAppCategoryEnum.payments => l10n.appCatPayments,
    CatalogAppCategoryEnum.design => l10n.appCatDesign,
    CatalogAppCategoryEnum.sales => l10n.appCatSales,
    CatalogAppCategoryEnum.data => l10n.appCatData,
    CatalogAppCategoryEnum.automation => l10n.appCatAutomation,
  };
}

/// The catalog app a connection came from, if any.
CatalogApp? catalogAppFor(WidgetRef ref, Integration i) {
  if (i.appId == null) return null;
  for (final a
      in ref.watch(appCatalogProvider).value?.apps ?? const <CatalogApp>[]) {
    if (a.id == i.appId) return a;
  }
  return null;
}

enum _HubTab { connected, browse }

bool _isHub(Integration i) =>
    i.kind == IntegrationKind.composio || i.kind == IntegrationKind.pipedream;

/// One app signed in through a Composio or Pipedream connection (D-173), listed like any other
/// connection rather than hidden inside its hub.
class HubApp {
  const HubApp({
    required this.hub,
    required this.slug,
    required this.status,
    this.app,
  });
  final Integration hub;
  final String slug;
  final ProviderAccountStatusEnum status;

  /// The catalog app it matches, when there is one.
  final CatalogApp? app;

  String get name =>
      app?.name ??
      slug
          .split(RegExp(r'[_\-\s]+'))
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
}

/// The apps signed in through the workspace's hubs, one per app. Sign-ins that never finished are
/// left out; a hub that can't be reached lists nothing, so its own card shows instead.
final hubAppsProvider = FutureProvider<List<HubApp>>((ref) async {
  final hubs = [
    for (final i in await ref.watch(integrationsProvider.future))
      if (_isHub(i)) i,
  ];
  if (hubs.isEmpty) return const [];
  final catalog =
      ref.watch(appCatalogProvider).value?.apps ?? const <CatalogApp>[];
  final backend = ref.watch(backendProvider);
  final perHub = await Future.wait([
    for (final h in hubs)
      backend
          .providerAccounts(h.id)
          .then<List<ProviderAccount>>(
            (a) => a,
            onError: (_) => const <ProviderAccount>[],
          ),
  ]);
  final bySlug = <String, HubApp>{};
  for (var n = 0; n < hubs.length; n++) {
    final hub = hubs[n];
    for (final a in perHub[n]) {
      if (a.app.isEmpty || a.status == ProviderAccountStatusEnum.pending) {
        continue;
      }
      final seen = bySlug[a.app];
      if (seen != null &&
          (seen.status == ProviderAccountStatusEnum.connected ||
              a.status != ProviderAccountStatusEnum.connected)) {
        continue;
      }
      final app = catalog
          .where(
            (c) =>
                (hub.kind == IntegrationKind.composio && c.composio == a.app) ||
                c.id == a.app,
          )
          .firstOrNull;
      bySlug[a.app] = HubApp(hub: hub, slug: a.app, status: a.status, app: app);
    }
  }
  return bySlug.values.toList();
});

/// Settings → Apps (D-089): the workspace's connections, and a catalog of apps to connect in one
/// step (vendors' own MCP servers), plus Composio, Pipedream and custom servers for the rest.
class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  _HubTab? _tab;
  final _search = TextEditingController();
  CatalogAppCategoryEnum? _category;
  // Back from a sign-in in the browser (or another app): show what changed meanwhile.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(integrationsProvider),
    );
    // hubAppsProvider follows integrationsProvider, so it refreshes with it.
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _addCustom() async {
    final added = await showAdaptiveSheet<bool>(
      context: context,
      builder: (_) => const AddIntegrationSheet(),
    );
    if (added == true) ref.invalidate(integrationsProvider);
  }

  Future<void> _connect(CatalogApp app) async {
    final i = await showConnectApp(context, app);
    if (!mounted) return;
    // However the sheet closed, the list catches up (a sign-in may have finished in the browser).
    ref.invalidate(integrationsProvider);
    ref.invalidate(hubAppsProvider);
    if (i != null) setState(() => _tab = _HubTab.connected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connections = ref.watch(integrationsProvider);
    final catalog = ref.watch(appCatalogProvider);
    final items = connections.value ?? const <Integration>[];
    final hubApps = ref.watch(hubAppsProvider).value ?? const <HubApp>[];
    final tab = _tab ?? (items.isEmpty ? _HubTab.browse : _HubTab.connected);
    return SubPage(
      title: l10n.appsTitle,
      subtitle: l10n.appsSubtitle,
      body: AsyncView(
        value: connections,
        onRetry: () => ref.invalidate(integrationsProvider),
        // A catalog: wide windows show more apps per row rather than one narrow column.
        data: (items) {
          // A hub with signed-in apps is listed as those apps, not as one "Composio" card.
          final hubsWithApps = {for (final h in hubApps) h.hub.id};
          final count = items.length - hubsWithApps.length + hubApps.length;
          return PageColumn(
            maxWidth: kWidePageMaxWidth,
            children: [
              _Readable(
                child: AppSegmentedControl<_HubTab>(
                  values: _HubTab.values,
                  labels: {
                    _HubTab.connected: count == 0
                        ? l10n.connectedTab
                        : '${l10n.connectedTab} · $count',
                    _HubTab.browse: l10n.browseTab,
                  },
                  icons: const {
                    _HubTab.connected: LucideIcons.plug,
                    _HubTab.browse: LucideIcons.layoutGrid,
                  },
                  groupValue: tab,
                  onValueChanged: (t) => setState(() => _tab = t),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              if (tab == _HubTab.connected)
                _Readable(
                  child: _Connected(
                    items: items,
                    hubApps: hubApps,
                    onBrowse: () => setState(() => _tab = _HubTab.browse),
                  ),
                )
              else
                // Spread into the page, so each part gets the page's side padding and the sideways
                // lists can reach the edges (PageBleed).
                ...catalog.when<List<Widget>>(
                  loading: () => const [
                    SkeletonGrid(count: 6, tileHeight: 100),
                  ],
                  error: (e, _) => [
                    FormNote(
                      errorText(context, e),
                      icon: LucideIcons.triangleAlert,
                    ),
                  ],
                  data: (cat) => _browse(context, cat, items, hubApps),
                ),
              // Hubs and custom servers, folded on both tabs (D-182): the one way to add a server by hand.
              _Readable(
                start: tab == _HubTab.browse,
                child: AdvancedSection(
                  id: 'integrations',
                  summary: l10n.integrationsAdvancedSummary,
                  children: [
                    GroupedCard(
                      children: [
                        GroupedTile(
                          key: const Key('setupComposio'),
                          icon: LucideIcons.blocks,
                          title: 'Composio',
                          subtitle: l10n.composioHelp,
                          onTap: () =>
                              showProviderSetup(context, ProviderKind.composio),
                        ),
                        GroupedTile(
                          key: const Key('setupPipedream'),
                          icon: LucideIcons.cable,
                          title: 'Pipedream',
                          subtitle: l10n.pipedreamHelp,
                          onTap: () => showProviderSetup(
                            context,
                            ProviderKind.pipedream,
                          ),
                        ),
                        GroupedTile(
                          key: const Key('addIntegration'),
                          icon: LucideIcons.squareTerminal,
                          title: l10n.customServer,
                          subtitle: l10n.customServerHelp,
                          onTap: _addCustom,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _browse(
    BuildContext context,
    AppCatalog cat,
    List<Integration> connected,
    List<HubApp> hubApps,
  ) {
    final l10n = context.l10n;
    final q = _search.text.trim().toLowerCase();
    final connectedIds = {
      for (final i in connected) ?i.appId,
      for (final h in hubApps)
        if (h.status == ProviderAccountStatusEnum.connected) ?h.app?.id,
    };
    final categories = [
      for (final c in CatalogAppCategoryEnum.values)
        if (cat.apps.any((a) => a.category == c)) c,
    ];
    final shown = [
      for (final a in cat.apps)
        if ((_category == null || a.category == _category) &&
            (q.isEmpty ||
                '${a.name} ${a.description} ${a.capabilities.join(' ')}'
                    .toLowerCase()
                    .contains(q)))
          a,
    ];
    final popular = [
      for (final a in cat.apps)
        if (a.popular) a,
    ];
    final filtering = q.isNotEmpty || _category != null;
    return [
      TextField(
        key: const Key('appSearch'),
        controller: _search,
        decoration: InputDecoration(
          hintText: l10n.searchApps,
          prefixIcon: const Icon(LucideIcons.search, size: 20),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: MaterialLocalizations.of(context)
                      .deleteButtonTooltip,
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => setState(_search.clear),
                ),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: AppSpace.sm),
      PageBleed(
        child: SizedBox(
          height: 38,
          child: EdgeFade(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
              children: [
                for (final c in [null, ...categories])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: RevealWhenSelected(
                      selected: _category == c,
                      child: ChoiceChip(
                        key: Key('appCategory-${c?.name ?? 'all'}'),
                        showCheckmark: false,
                        selected: _category == c,
                        label: Text(
                          c == null
                              ? l10n.allApps
                              : appCategoryLabel(context, c),
                        ),
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      if (!filtering && popular.isNotEmpty) ...[
        SectionHeader(title: l10n.popularApps),
        PageBleed(
          child: SizedBox(
            height: 204,
            child: EdgeFade(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.gutter,
                ),
                itemCount: popular.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
                itemBuilder: (_, i) => _FeaturedApp(
                  app: popular[i],
                  connected: connectedIds.contains(popular[i].id),
                  onTap: () => _connect(popular[i]),
                ),
              ),
            ),
          ),
        ),
      ],
      SectionHeader(
        title: filtering
            ? shown.length.humanizedCount(context.l10n.localeName)
            : l10n.allApps,
      ),
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
          child: Text(
            l10n.noThemesFound,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
        )
      else
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth > 1120
                ? 4
                : (c.maxWidth > 820 ? 3 : (c.maxWidth > 560 ? 2 : 1));
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpace.sm,
                crossAxisSpacing: AppSpace.sm,
                mainAxisExtent: 100,
              ),
              itemCount: shown.length,
              itemBuilder: (_, i) => _AppTile(
                app: shown[i],
                connected: connectedIds.contains(shown[i].id),
                onTap: () => _connect(shown[i]),
              ),
            );
          },
        ),
    ];
  }
}

String _authLabel(BuildContext context, CatalogApp a) {
  final l10n = context.l10n;
  if (a.auth.contains(CatalogAppAuthEnum.oauth) && a.oauthAvailable) {
    return l10n.authOneClick;
  }
  // Through the server's Composio account (D-172): still one click for the person.
  if (a.auth.contains(CatalogAppAuthEnum.managed)) return l10n.authOneClick;
  if (a.auth.contains(CatalogAppAuthEnum.none)) return l10n.authNone;
  if (a.auth.contains(CatalogAppAuthEnum.apiKey)) return l10n.authApiKey;
  return l10n.authAdminSetup;
}

class _ConnectedBadge extends StatelessWidget {
  const _ConnectedBadge();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        LucideIcons.circleCheck,
        size: 14,
        color: context.appColors.positive,
      ),
      const SizedBox(width: 4),
      Text(
        context.l10n.connectedBadge,
        style: context.textTheme.labelMedium?.copyWith(
          color: context.appColors.positive,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

/// A popular app as a big card with a wash of its brand color.
class _FeaturedApp extends StatelessWidget {
  const _FeaturedApp({
    required this.app,
    required this.connected,
    required this.onTap,
  });
  final CatalogApp app;
  final bool connected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final brand = brandColor(app.color, scheme.primary);
    final dark = context.isDark;
    return SizedBox(
      width: 220,
      child: Material(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: context.appColors.hairline),
        ),
        color: dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
        child: InkWell(
          key: Key('featured-${app.id}'),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  brand.withValues(alpha: dark ? 0.32 : 0.16),
                  brand.withValues(alpha: 0),
                ],
              ),
            ),
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppLogo(
                      appId: app.id,
                      name: app.name,
                      color: app.color,
                      size: 48,
                    ),
                    const Spacer(),
                    if (connected) const _ConnectedBadge(),
                  ],
                ),
                const Spacer(),
                Text(app.name, style: context.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  app.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Icon(
                      (app.oauthAvailable &&
                                  app.auth.contains(
                                    CatalogAppAuthEnum.oauth,
                                  )) ||
                              app.auth.contains(CatalogAppAuthEnum.managed)
                          ? LucideIcons.zap
                          : LucideIcons.keyRound,
                      size: 13,
                      color: brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _authLabel(context, app),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({
    required this.app,
    required this.connected,
    required this.onTap,
  });
  final CatalogApp app;
  final bool connected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: context.appColors.hairline),
      ),
      color: context.isDark
          ? scheme.surfaceContainer
          : scheme.surfaceContainerLowest,
      child: InkWell(
        key: Key('app-${app.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          child: Row(
            children: [
              AppLogo(
                appId: app.id,
                name: app.name,
                color: app.color,
                size: 48,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    connected
                        ? const _ConnectedBadge()
                        : Text(
                            _authLabel(context, app),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The workspace's connections, each with its health and who uses it.
class _Connected extends ConsumerWidget {
  const _Connected({
    required this.items,
    required this.hubApps,
    required this.onBrowse,
  });
  final List<Integration> items;
  final List<HubApp> hubApps;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.xl),
        child: EmptyState(
          icon: LucideIcons.plug,
          title: l10n.noConnectionsTitle,
          message: l10n.noConnections,
          action: GlowButton.icon(
            onPressed: onBrowse,
            icon: const Icon(LucideIcons.layoutGrid, size: 18),
            label: Text(l10n.browseApps),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final i in items)
          if (_isHub(i) && hubApps.any((h) => h.hub.id == i.id))
            for (final h in hubApps.where((h) => h.hub.id == i.id)) ...[
              _HubAppCard(hubApp: h),
              const SizedBox(height: AppSpace.sm),
            ]
          else ...[
            _ConnectionCard(integration: i),
            const SizedBox(height: AppSpace.sm),
          ],
      ],
    );
  }
}

class _ConnectionCard extends ConsumerWidget {
  const _ConnectionCard({required this.integration});
  final Integration integration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final i = integration;
    final app = catalogAppFor(ref, i);
    final users = _botsUsing(ref, i);
    final error = i.status == IntegrationStatusEnum.error;
    final (status, statusColor) = switch (i.status) {
      IntegrationStatusEnum.ok => (l10n.statusReady, colors.positive),
      IntegrationStatusEnum.error => (
        l10n.statusNeedsAttention,
        colors.negative,
      ),
      IntegrationStatusEnum.pending => (
        l10n.statusChecking,
        context.colorScheme.onSurfaceVariant,
      ),
    };
    return _ConnectionTile(
      key: Key('integration-${i.id}'),
      logo: AppLogo.forIntegration(i, app: app, size: 48),
      title: app?.name ?? i.name,
      status: status,
      statusColor: statusColor,
      detail: error && i.error.isUsable
          ? i.error!
          : [
              if (i.tools.isNotEmpty) l10n.toolCount(i.tools.length),
              l10n.usedByBots(users.length),
            ].join(' · '),
      error: error,
      users: users,
      onTap: () => context.push('/settings/integrations/${i.id}'),
    );
  }
}

/// An app signed in through Composio or Pipedream; opens its hub's page, where it's managed.
class _HubAppCard extends ConsumerWidget {
  const _HubAppCard({required this.hubApp});
  final HubApp hubApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final h = hubApp;
    final users = _botsUsing(ref, h.hub);
    final error = h.status != ProviderAccountStatusEnum.connected;
    return _ConnectionTile(
      key: Key('hubApp-${h.hub.id}-${h.slug}'),
      logo: AppLogo(
        appId: h.app?.id,
        name: h.name,
        color: h.app?.color,
        size: 48,
      ),
      title: h.name,
      status: error ? l10n.statusNeedsAttention : l10n.statusReady,
      statusColor: error ? colors.negative : colors.positive,
      detail: [
        l10n.connectedThroughHub(integrationKindLabel(context, h.hub.kind)),
        l10n.usedByBots(users.length),
      ].join(' · '),
      error: error,
      users: users,
      onTap: () => context.push('/settings/integrations/${h.hub.id}'),
    );
  }
}

List<Bot> _botsUsing(WidgetRef ref, Integration i) => [
  for (final b in ref.watch(botsProvider).value ?? const <Bot>[])
    if (i.botIds?.contains(b.id) ?? false) b,
];

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    super.key,
    required this.logo,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.detail,
    required this.error,
    required this.users,
    required this.onTap,
  });
  final Widget logo;
  final String title;
  final String status;
  final Color statusColor;
  final String detail;
  final bool error;
  final List<Bot> users;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final colors = context.appColors;
    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: error
              ? colors.negative.withValues(alpha: 0.4)
              : colors.hairline,
        ),
      ),
      color: context.isDark
          ? scheme.surfaceContainer
          : scheme.surfaceContainerLowest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              logo,
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        StatusLabel(
                          text: status,
                          color: statusColor,
                          pill: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: error
                            ? colors.negative
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (users.isNotEmpty) ...[
                const SizedBox(width: AppSpace.sm),
                _AvatarStack(bots: users),
              ],
              const SizedBox(width: AppSpace.xs),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Up to three overlapping bot avatars.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.bots});
  final List<Bot> bots;

  @override
  Widget build(BuildContext context) {
    final shown = bots.take(3).toList();
    const size = 26.0;
    return SizedBox(
      width: size + (shown.length - 1) * 16,
      height: size,
      child: Stack(
        children: [
          for (final (i, b) in shown.indexed)
            Positioned(
              left: i * 16.0,
              child: BotAvatar(
                name: b.name,
                avatar: b.avatarUrl,
                size: size,
                animate: false,
              ),
            ),
        ],
      ),
    );
  }
}

class AddIntegrationSheet extends ConsumerStatefulWidget {
  const AddIntegrationSheet({super.key});

  @override
  ConsumerState<AddIntegrationSheet> createState() =>
      _AddIntegrationSheetState();
}

class _AddIntegrationSheetState extends ConsumerState<AddIntegrationSheet> {
  var _kind = IntegrationKind.mcp;
  final _name = TextEditingController();
  // mcp: url; openapi: spec url; composio: toolkits; pipedream: project id
  final _primary = TextEditingController();
  // openapi: base url; pipedream: client id
  final _secondary = TextEditingController();
  // pipedream: apps
  final _apps = TextEditingController();
  final _secret = TextEditingController();
  var _busy = false;
  var _showSecret = false;

  @override
  void dispose() {
    for (final c in [_name, _primary, _secondary, _apps, _secret]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _list(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Map<String, Object?> _config() => switch (_kind) {
    IntegrationKind.localMcp => const {},
    IntegrationKind.mcp => {'url': _primary.text.trim()},
    // An outside A2A agent (D-140): its address or agent card; the secret is its bearer token.
    IntegrationKind.a2a => {'url': _primary.text.trim()},
    IntegrationKind.openapi => {
      'spec': _primary.text.trim(),
      if (_secondary.text.trim().isNotEmpty) 'base_url': _secondary.text.trim(),
      // OpenAPI auth comes from a named secret so it obeys that secret's host allowlist.
      if (_secret.text.trim().isNotEmpty)
        'auth': {'type': 'bearer', 'secret': _secret.text.trim()},
    },
    IntegrationKind.composio => {'toolkits': _list(_primary.text)},
    IntegrationKind.pipedream => {
      'project_id': _primary.text.trim(),
      'client_id': _secondary.text.trim(),
      'apps': _list(_apps.text),
    },
  };

  Future<void> _save(String name) async {
    setState(() => _busy = true);
    final org = ref.read(currentOrgProvider)!;
    final backend = ref.read(backendProvider);
    final created = await runGuarded(context, () async {
      final i = await backend.createIntegration(
        org.id,
        kind: _kind.value,
        name: name,
        config: _config(),
        secret: _secret.text.isEmpty || _kind == IntegrationKind.openapi
            ? null
            : _secret.text,
      );
      // Prove the connection and cache tools right away; failures show on the list.
      try {
        await backend.testIntegration(i.id);
      } catch (_) {}
      return i;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (created != null) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (primaryLabel, secondaryLabel, secretLabel) = switch (_kind) {
      IntegrationKind.mcp || IntegrationKind.localMcp => (
        l10n.serverUrl,
        null,
        l10n.authHeaderOptional,
      ),
      IntegrationKind.a2a => (l10n.a2aAgentUrl, null, l10n.a2aAgentToken),
      IntegrationKind.openapi => (
        l10n.specUrl,
        l10n.baseUrlOptional,
        l10n.authSecretName,
      ),
      IntegrationKind.composio => (l10n.composioToolkits, null, l10n.apiKey),
      IntegrationKind.pipedream => (
        l10n.pipedreamProject,
        l10n.pipedreamClientId,
        l10n.pipedreamClientSecret,
      ),
    };
    final name = integrationSlug(_name.text);
    final nameOk = RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(name);
    final primary = _primary.text.trim();
    final needsUrl =
        _kind == IntegrationKind.mcp ||
        _kind == IntegrationKind.openapi ||
        _kind == IntegrationKind.a2a;
    final primaryOk =
        primary.isNotEmpty &&
        (!needsUrl || RegExp(r'^https?://').hasMatch(primary));
    // Say what is missing instead of leaving a disabled button unexplained.
    final missing = !nameOk
        ? l10n.integrationNeedsName
        : (!primaryOk ? l10n.integrationNeedsField(primaryLabel) : null);
    final secretIsName = _kind == IntegrationKind.openapi;
    return FormSheet(
      icon: LucideIcons.puzzle,
      title: l10n.addIntegration,
      subtitle: l10n.integrationsHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveIntegration'),
      busy: _busy,
      onSubmit: missing != null ? null : () => _save(name),
      footer: missing == null || _name.text.isEmpty ? null : FormNote(missing),
      children: [
        DropdownButtonFormField<IntegrationKind>(
          isExpanded: true,
          key: const Key('integrationKind'),
          initialValue: _kind,
          decoration: InputDecoration(
            labelText: l10n.integrationType,
            prefixIcon: Icon(integrationKindIcon(_kind), size: 20),
          ),
          // Local MCP servers are added from the desktop app's companion settings (D-096).
          items: [
            for (final k in IntegrationKind.values)
              if (k != IntegrationKind.localMcp)
                DropdownMenuItem(
                  value: k,
                  child: Text(integrationKindLabel(context, k)),
                ),
          ],
          onChanged: hapticOnChanged(
            (v) => setState(() => _kind = v ?? _kind),
            haptic: HapticsHelper.selection,
          ),
        ),
        TextField(
          key: const Key('integrationName'),
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.integrationName,
            prefixIcon: const Icon(LucideIcons.idCard, size: 20),
            helperText: _name.text.trim().isEmpty
                ? l10n.integrationNameHelp
                : (nameOk
                      ? l10n.integrationSavedAs(name)
                      : l10n.integrationNeedsName),
          ),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          key: const Key('integrationPrimary'),
          controller: _primary,
          textInputAction: TextInputAction.next,
          keyboardType: needsUrl ? TextInputType.url : TextInputType.text,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: primaryLabel,
            hintText: needsUrl ? 'https://' : null,
            prefixIcon: Icon(
              needsUrl ? LucideIcons.link : LucideIcons.list,
              size: 20,
            ),
            errorText: primary.isNotEmpty && !primaryOk
                ? l10n.integrationUrlInvalid
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (secondaryLabel != null)
          TextField(
            controller: _secondary,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: secondaryLabel,
              prefixIcon: Icon(
                _kind == IntegrationKind.openapi
                    ? LucideIcons.server
                    : LucideIcons.idCard,
                size: 20,
              ),
            ),
          ),
        if (_kind == IntegrationKind.pipedream)
          TextField(
            controller: _apps,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.pipedreamApps,
              prefixIcon: const Icon(LucideIcons.layoutGrid, size: 20),
            ),
          ),
        TextField(
          key: const Key('integrationSecret'),
          controller: _secret,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (missing == null) _save(name);
          },
          obscureText: !secretIsName && !_showSecret,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: secretLabel,
            prefixIcon: Icon(
              secretIsName ? LucideIcons.lock : LucideIcons.rectangleEllipsis,
              size: 20,
            ),
            helperText: secretIsName
                ? l10n.authSecretNameHelp
                : l10n.storedEncrypted,
            suffixIcon: secretIsName
                ? null
                : IconButton(
                    tooltip: _showSecret ? l10n.hide : l10n.show,
                    icon: Icon(
                      _showSecret ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showSecret = !_showSecret),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Tool names are prefixed with the integration's name, so it must be a short identifier:
/// "GitHub tools" is saved as "github_tools".
String integrationSlug(String name) {
  var out = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  out = out.replaceAll(RegExp(r'^_+|_+$'), '');
  if (out.isNotEmpty && !RegExp(r'^[a-z]').hasMatch(out)) out = 'x_$out';
  return out.length > 40
      ? out.substring(0, 40).replaceAll(RegExp(r'_+$'), '')
      : out;
}

/// Which integrations one bot may use.
class BotIntegrationsScreen extends ConsumerWidget {
  const BotIntegrationsScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final attached =
        ref.watch(botIntegrationIdsProvider(botId)).value ?? const <String>{};
    final bot = ref.watch(botProvider(botId));

    Future<void> set(Integration i, bool v) async {
      await runGuarded(
        context,
        () => ref.read(backendProvider).setBotIntegration(botId, i.id, v),
      );
      ref.invalidate(botIntegrationIdsProvider(botId));
    }

    return SubPage(
      title: l10n.integrations,
      subtitle: bot?.name,
      body: AsyncView(
        value: ref.watch(integrationsProvider),
        onRetry: () => ref.invalidate(integrationsProvider),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.puzzle,
                title: l10n.noIntegrationsTitle,
                message: l10n.noIntegrationsForBot,
                action: FilledButton.tonalIcon(
                  onPressed: () => context.push('/settings/integrations'),
                  icon: const Icon(LucideIcons.settings, size: 18),
                  label: Text(l10n.openSettings),
                ),
              )
            : PageColumn(
                children: [
                  FormNote(l10n.botIntegrationsHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final i in items)
                        GroupedTile(
                          key: Key('attach-${i.id}'),
                          icon: integrationKindIcon(i.kind),
                          leading: AppLogo.forIntegration(
                            i,
                            app: catalogAppFor(ref, i),
                            size: 36,
                          ),
                          title: catalogAppFor(ref, i)?.name ?? i.name,
                          // No "MCP server" / "OpenAPI" label here (D-182); the connection's page still says.
                          subtitle: i.tools.isEmpty
                              ? null
                              : l10n.toolCount(i.tools.length),
                          onTap: () => set(i, !attached.contains(i.id)),
                          trailing: Switch(
                            value: attached.contains(i.id),
                            onChanged: hapticOnChanged((v) => set(i, v)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Lists and controls keep a readable width, centered, on the wide catalog page.
class _Readable extends StatelessWidget {
  const _Readable({required this.child, this.start = false});
  final Widget child;

  /// Aligned with the section header above it instead of centered.
  final bool start;

  @override
  Widget build(BuildContext context) => Align(
    alignment: start ? AlignmentDirectional.centerStart : Alignment.center,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
      child: child,
    ),
  );
}
