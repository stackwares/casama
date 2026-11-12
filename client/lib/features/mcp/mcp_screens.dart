import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/one_time_secret.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';

/// Hosted MCP (D-117): AI apps connect to /mcp with OAuth (this consent screen) or an API key.

/// An AI app asks to connect: pick the workspace it may use, then allow or refuse.
class McpConsentScreen extends ConsumerStatefulWidget {
  const McpConsentScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<McpConsentScreen> createState() => _McpConsentScreenState();
}

class _McpConsentScreenState extends ConsumerState<McpConsentScreen> {
  late final Future<McpAuthRequestInfo> _info = ref
      .read(backendProvider)
      .mcpAuthRequest(widget.requestId);
  String? _org;
  var _done = false;

  Future<void> _answer(bool approve) async {
    final org = _org ?? ref.read(currentOrgProvider)?.id;
    if (org == null) return;
    final url = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .decideMcpAuthRequest(widget.requestId, orgId: org, approve: approve),
    );
    if (url == null || !mounted) return;
    setState(() => _done = true);
    // Back to the AI app: its own redirect address, opened in the browser.
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final orgs =
        ref.watch(organizationsProvider).value ??
        const <OrganizationWithRole>[];
    _org ??= ref.watch(currentOrgProvider)?.id;
    return FutureBuilder<McpAuthRequestInfo>(
      future: _info,
      builder: (context, snap) => SubPage(
        title: l10n.connectAiApp,
        children: [
          if (snap.hasError)
            FormNote(
              errorText(context, snap.error!),
              icon: LucideIcons.triangleAlert,
            ),
          if (snap.data == null && !snap.hasError) const SkeletonDetail(),
          if (snap.data != null && _done)
            FormNote(l10n.connectAiAppDone, icon: LucideIcons.circleCheck),
          if (snap.data != null && !_done)
            AppCard(
              key: const Key('mcpConsent'),
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.md,
                children: [
                  Text(
                    l10n.connectAiAppAsk(snap.data!.clientName),
                    style: context.textTheme.titleMedium,
                  ),
                  Text(
                    l10n.connectAiAppHelp(snap.data!.redirectHost),
                    style: TextStyle(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: const Key('mcpOrg'),
                    initialValue: _org,
                    decoration: InputDecoration(labelText: l10n.workspace),
                    items: [
                      for (final o in orgs)
                        DropdownMenuItem(value: o.id, child: Text(o.name)),
                    ],
                    onChanged: hapticOnChanged(
                      (v) => setState(() => _org = v),
                      haptic: HapticsHelper.selection,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: AppSpace.sm,
                    children: [
                      TextButton(
                        key: const Key('mcpDeny'),
                        onPressed: () => _answer(false),
                        child: Text(l10n.refuse),
                      ),
                      GlowButton(
                        key: const Key('mcpAllow'),
                        onPressed: () => _answer(true),
                        child: Text(l10n.allow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

final _mcpKeysProvider = FutureProvider.autoDispose
    .family<List<McpKey>, String>(
      (ref, orgId) => ref.watch(backendProvider).mcpKeys(orgId),
    );
final _mcpApprovalsProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, orgId) => ref.watch(backendProvider).mcpDecideApprovals(orgId),
);

/// Workspace settings → Connect AI apps: the MCP address, API keys, and whether approvals can be
/// decided from connected apps.
class McpSettingsSection extends ConsumerStatefulWidget {
  const McpSettingsSection({super.key, required this.orgId});
  final String orgId;

  @override
  ConsumerState<McpSettingsSection> createState() => _McpSettingsSectionState();
}

class _McpSettingsSectionState extends ConsumerState<McpSettingsSection> {
  CreatedMcpKey? _created;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    final url = '${backend.apiUrl.replaceAll(RegExp(r'/$'), '')}/mcp';
    final keys =
        ref.watch(_mcpKeysProvider(widget.orgId)).value ?? const <McpKey>[];
    final approvals =
        ref.watch(_mcpApprovalsProvider(widget.orgId)).value ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.connectAiApps),
        FormNote(l10n.connectAiAppsHelp),
        const SizedBox(height: AppSpace.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  url,
                  key: const Key('mcpUrl'),
                  style: AppText.mono.copyWith(fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: l10n.copy,
                icon: const Icon(LucideIcons.copy, size: 18),
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) showMessage(context, l10n.copied);
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
        SwitchListTile(
          key: const Key('mcpApprovals'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.mcpApprovals),
          subtitle: Text(l10n.mcpApprovalsHelp),
          value: approvals,
          onChanged: hapticOnChanged((v) async {
            await runGuarded(
              context,
              () => backend.setMcpDecideApprovals(widget.orgId, v),
            );
            ref.invalidate(_mcpApprovalsProvider(widget.orgId));
          }),
        ),
        if (_created != null)
          OneTimeSecretCard(
            key: const Key('mcpNewKey'),
            value: _created!.key,
            onDone: () => setState(() => _created = null),
          ),
        GroupedCard(
          children: [
            for (final k in keys)
              GroupedTile(
                key: Key('mcpKey-${k.id}'),
                icon: LucideIcons.keyRound,
                title: k.name,
                subtitle: '…${k.hint}',
                trailing: TextButton(
                  key: Key('revokeMcpKey-${k.id}'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colorScheme.error,
                  ),
                  onPressed: () async {
                    // Apps using the key lose access at once, and it can't be undone: ask first.
                    final ok = await showConfirm(
                      context: context,
                      title: l10n.revokeApiKeyTitle(k.name),
                      message: l10n.revokeApiKeyBody,
                      confirmLabel: l10n.revokeLink,
                      destructive: true,
                      icon: LucideIcons.keyRound,
                      confirmKey: const Key('confirmRevokeMcpKey'),
                    );
                    if (!ok || !context.mounted) return;
                    await runGuarded(
                      context,
                      () => backend.revokeMcpKey(widget.orgId, k.id),
                    );
                    ref.invalidate(_mcpKeysProvider(widget.orgId));
                  },
                  child: Text(l10n.revokeLink),
                ),
              ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('mcpCreateKey'),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(l10n.newApiKey),
            onPressed: () async {
              final name = await showTextPrompt(
                context,
                title: l10n.newApiKey,
                label: l10n.apiKeyName,
                submitLabel: l10n.create,
                fieldKey: const Key('mcpKeyName'),
              );
              if (name == null || name.trim().isEmpty || !context.mounted) {
                return;
              }
              final k = await runGuarded(
                context,
                () => backend.createMcpKey(widget.orgId, name.trim()),
              );
              if (k != null && mounted) setState(() => _created = k);
              ref.invalidate(_mcpKeysProvider(widget.orgId));
            },
          ),
        ),
      ],
    );
  }
}
