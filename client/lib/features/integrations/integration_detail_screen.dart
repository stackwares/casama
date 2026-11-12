import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/advanced_section.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'app_logo.dart';
import 'connect_app_sheet.dart';
import 'integrations_screen.dart';
import 'provider_setup.dart';

/// One connection: its health, sign-in, which bots use it, and how freely each tool may run.
class IntegrationDetailScreen extends ConsumerStatefulWidget {
  const IntegrationDetailScreen({super.key, required this.integrationId});
  final String integrationId;

  @override
  ConsumerState<IntegrationDetailScreen> createState() =>
      _IntegrationDetailScreenState();
}

class _IntegrationDetailScreenState
    extends ConsumerState<IntegrationDetailScreen> {
  var _testing = false;
  final _risks = <String, String>{};
  var _risksLoaded = false;

  Future<void> _test(Integration i) async {
    final l10n = context.l10n;
    setState(() => _testing = true);
    final r = await runGuarded(
      context,
      () => ref.read(backendProvider).testIntegration(i.id),
    );
    if (!mounted) return;
    setState(() => _testing = false);
    ref.invalidate(integrationsProvider);
    if (r == null) return;
    if (r.ok) {
      showSuccess(context, l10n.integrationOk(r.tools.length));
    } else {
      showFailure(context, l10n.integrationFailed(r.error.orPlaceholder()));
    }
  }

  Future<void> _disconnect(Integration i, String name) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.disconnectTitle(name),
      message: l10n.disconnectBody,
      confirmLabel: l10n.disconnect,
      destructive: true,
      confirmKey: const Key('confirmDisconnect'),
    );
    if (!ok || !mounted) return;
    await runGuarded(
      context,
      () => ref.read(backendProvider).deleteIntegration(i.id),
    );
    ref.invalidate(integrationsProvider);
    if (mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _setRisk(Integration i, String tool, String risk) async {
    setState(() => _risks[tool] = risk);
    await runGuarded(
      context,
      () => ref.read(backendProvider).setToolRisks(i.id, Map.of(_risks)),
    );
    ref.invalidate(integrationsProvider);
  }

  Future<void> _setBot(Integration i, String botId, bool on) async {
    await runGuarded(
      context,
      () => ref.read(backendProvider).setBotIntegration(botId, i.id, on),
    );
    ref.invalidate(integrationsProvider);
    ref.invalidate(botIntegrationIdsProvider(botId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list = ref.watch(integrationsProvider);
    Integration? i;
    for (final x in list.value ?? const <Integration>[]) {
      if (x.id == widget.integrationId) i = x;
    }
    if (i == null) {
      return SubPage(
        title: l10n.appsTitle,
        body: list.isLoading
            ? const SkeletonDetail()
            : EmptyState(
                icon: LucideIcons.unplug,
                title: l10n.noIntegrationsTitle,
                message: '',
              ),
      );
    }
    final integration = i;
    final app = catalogAppFor(ref, integration);
    final name = app?.name ?? integration.name;
    if (!_risksLoaded) {
      _risks.addAll({
        for (final e
            in (integration.riskOverrides ?? const <String, Risk>{}).entries)
          e.key: e.value.value,
      });
      _risksLoaded = true;
    }
    final isProvider =
        integration.kind == IntegrationKind.composio ||
        integration.kind == IntegrationKind.pipedream;
    return SubPage(
      title: name,
      body: PageColumn(
        children: [
          _Hero(
            integration: integration,
            app: app,
            testing: _testing,
            onTest: () => _test(integration),
            onReconnect: app == null
                ? null
                : () => showConnectApp(context, app, reconnect: integration),
          ),
          if (isProvider) ...[
            SectionHeader(
              title: l10n.providerAppsTitle(
                integrationKindLabel(context, integration.kind),
              ),
            ),
            ProviderAccountsCard(integration: integration),
          ],
          SectionHeader(title: l10n.botsWithAccess),
          _BotAccess(
            integration: integration,
            onChanged: (b, v) => _setBot(integration, b, v),
          ),
          // How freely each tool may run: folded, the defaults suit most people (D-182).
          if (integration.tools.isNotEmpty)
            AdvancedSection(
              id: 'integration.tools',
              title: l10n.toolPermissions,
              summary: l10n.toolCount(integration.tools.length),
              children: [
                FormNote(l10n.toolsHelp),
                const SizedBox(height: AppSpace.sm),
                GroupedCard(
                  children: [
                    for (final t in integration.tools)
                      _ToolRow(
                        key: Key('tool-${t.name}'),
                        tool: t,
                        risk: _risks[t.name] ?? t.risk?.value ?? 'medium',
                        onChanged: (r) => _setRisk(integration, t.name, r),
                      ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: AppSpace.xl),
          Center(
            child: TextButton.icon(
              key: const Key('disconnectIntegration'),
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.error,
              ),
              onPressed: () => _disconnect(integration, name),
              icon: const Icon(LucideIcons.unplug, size: 18),
              label: Text(l10n.disconnect),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.integration,
    required this.app,
    required this.testing,
    required this.onTest,
    this.onReconnect,
  });
  final Integration integration;
  final CatalogApp? app;
  final bool testing;
  final VoidCallback onTest;
  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final i = integration;
    final brand = brandColor(app?.color, scheme.primary);
    final failing = i.status == IntegrationStatusEnum.error;
    final (status, statusColor) = switch (i.status) {
      IntegrationStatusEnum.ok => (l10n.statusReady, colors.positive),
      IntegrationStatusEnum.error => (
        l10n.statusNeedsAttention,
        colors.negative,
      ),
      IntegrationStatusEnum.pending => (
        l10n.statusChecking,
        scheme.onSurfaceVariant,
      ),
    };
    final signedIn = switch (i.auth) {
      IntegrationAuthEnum.oauth => l10n.signedInOAuth,
      IntegrationAuthEnum.apiKey => l10n.signedInKey,
      IntegrationAuthEnum.none => l10n.signedInNone,
      null => integrationKindLabel(context, i.kind),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.hairline),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              brand.withValues(alpha: context.isDark ? 0.26 : 0.12),
              context.isDark
                  ? scheme.surfaceContainer
                  : scheme.surfaceContainerLowest,
            ),
            context.isDark
                ? scheme.surfaceContainer
                : scheme.surfaceContainerLowest,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppLogo.forIntegration(i, app: app, size: 64),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app?.name ?? i.name,
                      style: context.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSpace.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusLabel(
                          text: status,
                          color: statusColor,
                          pill: true,
                        ),
                        Text(
                          signedIn,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (failing && i.error != null) ...[
            const SizedBox(height: AppSpace.md),
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.row),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.triangleAlert,
                    size: 16,
                    color: scheme.error,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: SelectableText(
                      i.error!,
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              if (onReconnect != null &&
                  (failing ||
                      i.auth == IntegrationAuthEnum.oauth ||
                      i.auth == IntegrationAuthEnum.apiKey))
                (failing ? FilledButton.icon : OutlinedButton.icon)(
                  key: const Key('reconnectIntegration'),
                  onPressed: onReconnect,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: Text(l10n.reconnect),
                ),
              OutlinedButton.icon(
                key: Key('testIntegration-${i.id}'),
                onPressed: testing ? null : onTest,
                icon: testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.activity, size: 16),
                label: Text(l10n.testConnection),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotAccess extends ConsumerWidget {
  const _BotAccess({required this.integration, required this.onChanged});
  final Integration integration;
  final void Function(String botId, bool on) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    final on = (integration.botIds ?? const <String>[]).toSet();
    if (bots.isEmpty) return FormNote(context.l10n.noIntegrationsForBot);
    return GroupedCard(
      children: [
        for (final b in bots)
          GroupedTile(
            key: Key('access-${b.id}'),
            icon: LucideIcons.bot,
            leading: BotAvatar(
              name: b.name,
              avatar: b.avatarUrl,
              size: 32,
              animate: false,
            ),
            title: b.name,
            onTap: () => onChanged(b.id, !on.contains(b.id)),
            trailing: Switch(
              value: on.contains(b.id),
              onChanged: hapticOnChanged((v) => onChanged(b.id, v)),
            ),
          ),
      ],
    );
  }
}

/// A tool with a plain-language name and how freely it may run.
class _ToolRow extends StatelessWidget {
  const _ToolRow({
    super.key,
    required this.tool,
    required this.risk,
    required this.onChanged,
  });
  final IntegrationToolsInner tool;
  final String risk;
  final ValueChanged<String> onChanged;

  static String humanize(String name) {
    final words = name
        .replaceAll(RegExp(r'[_\-.]+'), ' ')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .trim()
        .toLowerCase();
    return words.isEmpty
        ? name
        : '${words[0].toUpperCase()}${words.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final (label, color, icon) = switch (risk) {
      'low' => (l10n.toolRiskLow, colors.positive, LucideIcons.eye),
      'high' => (l10n.toolRiskHigh, colors.negative, LucideIcons.shieldAlert),
      _ => (l10n.toolRiskMedium, colors.warning, LucideIcons.pencil),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.icon),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  humanize(tool.name),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (tool.description.isNotEmpty &&
                    tool.description.toLowerCase() !=
                        humanize(tool.name).toLowerCase())
                  Text(
                    tool.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          PopupMenuButton<String>(
            key: Key('toolRisk-${tool.name}'),
            tooltip: label,
            initialValue: risk,
            onSelected: onChanged,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'low', child: Text(l10n.toolRiskLow)),
              PopupMenuItem(value: 'medium', child: Text(l10n.toolRiskMedium)),
              PopupMenuItem(value: 'high', child: Text(l10n.toolRiskHigh)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(LucideIcons.chevronDown, size: 14, color: color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
