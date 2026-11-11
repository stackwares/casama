import 'dart:async';

import 'package:flutter/material.dart';

import '../mcp/mcp_screens.dart';
import 'join_flow.dart';
import 'workspace_files.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/number_format.dart';
import '../../core/date_format.dart';
import '../../core/phone_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/advanced_section.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/revealable.dart';
import '../../ui/celebration.dart';

/// Icons a workspace can have (D-099).
const spaceIcons = <String, IconData>{
  'boxes': LucideIcons.boxes,
  'house': LucideIcons.house,
  'briefcase': LucideIcons.briefcase,
  'rocket': LucideIcons.rocket,
  'code': LucideIcons.codeXml,
  'users': LucideIcons.users,
  'heart': LucideIcons.heart,
  'star': LucideIcons.star,
  'book': LucideIcons.bookOpen,
  'sparkles': LucideIcons.sparkles,
  'leaf': LucideIcons.leaf,
  'flask': LucideIcons.flaskConical,
};

const spaceColors = ['#6366f1', '#0ea5e9', '#22aa66', '#f59e0b', '#ef4444', '#ec4899', '#8b5cf6', '#64748b'];

Color? _hex(String? s) {
  if (s == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(s)) return null;
  return Color(int.parse('ff${s.substring(1)}', radix: 16));
}

/// A workspace's colored tile with its icon (or its initial).
class SpaceAvatar extends StatelessWidget {
  const SpaceAvatar({super.key, required this.name, this.icon, this.color, this.size = 32});
  final String name;
  final String? icon;
  final String? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = _hex(color) ?? context.colorScheme.primary;
    final glyph = spaceIcons[icon];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(size * 0.3)),
      alignment: Alignment.center,
      child: glyph != null
          ? Icon(glyph, size: size * 0.55, color: c)
          : Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: size * 0.45),
            ),
    );
  }
}

final workspaceBadgesProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(organizationsProvider);
  final items = await ref.watch(backendProvider).workspaceBadges();
  return {for (final b in items) b.orgId: b.approvals + b.unread};
});

/// The current workspace at the top of the navigation; opens the workspace list.
class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = ref.watch(currentOrgProvider);
    if (org == null) return const SizedBox.shrink();
    final badges = ref.watch(workspaceBadgesProvider).value ?? const {};
    final others = badges.entries.where((e) => e.key != org.id).fold<int>(0, (a, e) => a + e.value);
    final avatar = Badge(
      isLabelVisible: others > 0,
      smallSize: 8,
      child: SpaceAvatar(name: org.name, icon: org.icon, color: org.color, size: compact ? 36 : 30),
    );
    return Tooltip(
      message: context.l10n.spaces,
      child: InkWell(
        key: const Key('workspaceSwitcher'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => showSpacesSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: compact
              ? avatar
              : Row(
                  children: [
                    avatar,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        org.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(LucideIcons.chevronsUpDown, size: 16, color: context.colorScheme.onSurfaceVariant),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The workspace list: switch, create, or join with a link.
Future<void> showSpacesSheet(BuildContext context, WidgetRef ref) => showAdaptiveSheet<void>(
  context: context,
  contentPadsBottom: true,
  builder: (c) => Consumer(
    builder: (context, ref, _) {
      final l10n = context.l10n;
      final orgs = ref.watch(organizationsProvider).value ?? const <OrganizationWithRole>[];
      final current = ref.watch(currentOrgProvider);
      final badges = ref.watch(workspaceBadgesProvider).value ?? const {};
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.spaces, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpace.md),
            GroupedCard(
              children: [
                for (final o in orgs)
                  ListTile(
                    key: Key('space-${o.id}'),
                    leading: SpaceAvatar(name: o.name, icon: o.icon, color: o.color),
                    title: Text(o.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((badges[o.id] ?? 0) > 0) Badge(label: Text('${badges[o.id]}', style: const TextStyle(fontFeatures: AppText.tabular))),
                        if (o.id == current?.id)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(LucideIcons.check, color: context.colorScheme.primary),
                          ),
                      ],
                    ),
                    onTap: () {
                      ref.read(selectedOrgIdProvider.notifier).select(o.id);
                      Navigator.pop(c);
                      GoRouter.maybeOf(context)?.go('/bots');
                    },
                  ),
              ],
            ),
            JoinableWorkspacesSection(onJoined: () => Navigator.pop(c)),
            const SizedBox(height: AppSpace.md),
            OutlinedButton.icon(
              key: const Key('newWorkspace'),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(l10n.newWorkspace),
              onPressed: () async {
                Navigator.pop(c);
                await showAdaptiveSheet<void>(context: context, builder: (_) => const NewSpaceSheet());
              },
            ),
            const SizedBox(height: AppSpace.sm),
            if (current != null && current.role != OrgRole.member) ...[
              OutlinedButton.icon(
                key: const Key('invitePeople'),
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: Text(l10n.invitePeopleTo(current.name)),
                onPressed: () {
                  Navigator.pop(c);
                  GoRouter.maybeOf(context)?.push('/settings/people');
                },
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            TextButton.icon(
              key: const Key('joinWorkspace'),
              icon: const Icon(LucideIcons.link, size: 18),
              label: Text(l10n.joinWithLinkOrCode),
              onPressed: () async {
                Navigator.pop(c);
                await showAdaptiveSheet<void>(context: context, builder: (_) => const JoinSpaceSheet());
              },
            ),
          ],
        ),
      );
    },
  ),
);

/// The icon and color pickers shared by the new-workspace sheet and workspace settings.
class _LookPicker extends StatelessWidget {
  const _LookPicker({required this.icon, required this.color, required this.onIcon, required this.onColor});
  final String icon;
  final String color;
  final ValueChanged<String> onIcon;
  final ValueChanged<String> onColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.sm,
      children: [
        Text(l10n.workspaceIcon, style: context.textTheme.labelLarge),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final e in spaceIcons.entries) ChoiceChip(key: Key('icon-${e.key}'), label: Icon(e.value, size: 18), selected: icon == e.key, onSelected: (_) => onIcon(e.key))],
        ),
        Text(l10n.workspaceColor, style: context.textTheme.labelLarge),
        Wrap(
          spacing: 8,
          children: [
            for (final c in spaceColors)
              InkWell(
                key: Key('color-$c'),
                customBorder: const CircleBorder(),
                onTap: () => onColor(c),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _hex(c),
                    shape: BoxShape.circle,
                    border: Border.all(color: c == color ? context.colorScheme.onSurface : Colors.transparent, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class NewSpaceSheet extends ConsumerStatefulWidget {
  const NewSpaceSheet({super.key});

  @override
  ConsumerState<NewSpaceSheet> createState() => _NewSpaceSheetState();
}

class _NewSpaceSheetState extends ConsumerState<NewSpaceSheet> {
  final _name = TextEditingController();
  var _icon = 'boxes';
  var _color = spaceColors.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.boxes,
      title: l10n.newWorkspace,
      submitLabel: l10n.newWorkspace,
      submitKey: const Key('createWorkspaceSubmit'),
      onSubmit: () async {
        final name = _name.text.trim();
        if (name.isEmpty) return;
        final backend = ref.read(backendProvider);
        final org = await runGuarded(context, () async {
          final o = await backend.createOrganization(name);
          await backend.updateOrg(o.id, icon: _icon, color: _color);
          return o;
        });
        if (org == null || !context.mounted) return;
        showCelebration(context, context.l10n.celebrateNewSpace(org.name));
        ref.invalidate(organizationsProvider);
        ref.read(selectedOrgIdProvider.notifier).select(org.id);
        Navigator.pop(context);
      },
      children: [
        TextField(
          key: const Key('workspaceNameField'),
          controller: _name,
          decoration: InputDecoration(labelText: l10n.workspaceName),
        ),
        _LookPicker(icon: _icon, color: _color, onIcon: (v) => setState(() => _icon = v), onColor: (v) => setState(() => _color = v)),
      ],
    );
  }
}

/// Settings → Workspace: name, look and People up top (People has the invites, D-167); the
/// technical setup folds under Advanced (D-182).
class WorkspaceSettingsScreen extends ConsumerStatefulWidget {
  const WorkspaceSettingsScreen({super.key});

  @override
  ConsumerState<WorkspaceSettingsScreen> createState() => _WorkspaceSettingsScreenState();
}

class _WorkspaceSettingsScreenState extends ConsumerState<WorkspaceSettingsScreen> {
  final _name = TextEditingController();
  String? _loadedFor;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save({String? icon, String? color}) async {
    final org = ref.read(currentOrgProvider)!;
    await runGuarded(context, () => ref.read(backendProvider).updateOrg(org.id, name: _name.text.trim().isEmpty ? null : _name.text.trim(), icon: icon, color: color));
    ref.invalidate(organizationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final org = ref.watch(currentOrgProvider);
    if (org == null) return const SizedBox.shrink();
    if (_loadedFor != org.id) {
      _loadedFor = org.id;
      _name.text = org.name;
    }
    final admin = org.role != OrgRole.member;
    return SubPage(
      title: l10n.workspaceSettings,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              Row(
                children: [
                  SpaceAvatar(name: org.name, icon: org.icon, color: org.color, size: 44),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: TextField(
                      key: const Key('workspaceRename'),
                      controller: _name,
                      enabled: admin,
                      decoration: InputDecoration(labelText: l10n.workspaceName),
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                ],
              ),
              if (admin)
                _LookPicker(
                  icon: org.icon ?? 'boxes',
                  color: org.color ?? spaceColors.first,
                  onIcon: (v) => _save(icon: v),
                  onColor: (v) => _save(color: v),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('workspacePeople'),
              icon: LucideIcons.users,
              title: l10n.people,
              subtitle: admin ? l10n.peopleRow : l10n.members,
              showChevron: true,
              onTap: () => context.push('/settings/people'),
            ),
          ],
        ),
        // The setup most workspaces never touch, in one fold that stays open once opened (D-182).
        AdvancedSection(
          id: 'workspace.settings',
          summary: admin ? l10n.workspaceAdvancedSummary : l10n.passwordManagers,
          children: [
            GroupedCard(
              children: [
                GroupedTile(
                  key: const Key('passwordManagers'),
                  icon: LucideIcons.keyRound,
                  title: l10n.passwordManagers,
                  subtitle: l10n.passwordManagersRow,
                  onTap: () => context.push('/password-managers'),
                ),
              ],
            ),
            if (admin) ...[const SizedBox(height: AppSpace.lg), BotToBotSwitch(orgId: org.id)],
            if (admin) ...[const SizedBox(height: AppSpace.lg), A2aSwitch(orgId: org.id)],
            if (admin && phoneCallsEnabled) ...[const SizedBox(height: AppSpace.lg), PhoneCallsSection(orgId: org.id)],
            if (admin) ...[const SizedBox(height: AppSpace.lg), SecretStoreSection(orgId: org.id)],
            if (admin) ...[const SizedBox(height: AppSpace.lg), MemoryBackendSection(orgId: org.id)],
            if (org.role.value == 'owner') ...[const SizedBox(height: AppSpace.lg), EncryptionSection(orgId: org.id)],
            if (org.role.value == 'owner') ...[const SizedBox(height: AppSpace.lg), PaymentsSection(orgId: org.id)],
            if (admin) ...[const SizedBox(height: AppSpace.lg), McpSettingsSection(orgId: org.id)],
            if (admin) ...[const SizedBox(height: AppSpace.lg), WorkspaceFilesSection(orgId: org.id)],
          ],
        ),
      ],
    );
  }
}

final _botToBotProvider = FutureProvider.autoDispose.family<bool, String>((ref, orgId) => ref.watch(backendProvider).allowBotToBot(orgId));

/// Bot-to-bot switch (D-133): whether bots may @mention, message and delegate to each other.
class BotToBotSwitch extends ConsumerWidget {
  const BotToBotSwitch({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final on = ref.watch(_botToBotProvider(orgId)).value ?? true;
    return GroupedCard(
      children: [
        SwitchListTile(
          key: const Key('botToBot'),
          title: Text(l10n.botToBot),
          subtitle: Text(l10n.botToBotHelp),
          value: on,
          onChanged: hapticOnChanged((v) async {
            await runGuarded(context, () => ref.read(backendProvider).setAllowBotToBot(orgId, v));
            ref.invalidate(_botToBotProvider(orgId));
          }),
        ),
      ],
    );
  }
}

final _encryptionProvider = FutureProvider.autoDispose.family<EncryptionStatus, String>((ref, orgId) => ref.watch(backendProvider).encryption(orgId));

/// Encryption at rest (D-136): owners turn it on or off and rotate the key.
class EncryptionSection extends ConsumerWidget {
  const EncryptionSection({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(_encryptionProvider(orgId)).value;
    if (s == null) return const SizedBox.shrink();
    final on = s.mode == EncryptionStatusModeEnum.on_ || s.mode == EncryptionStatusModeEnum.encrypting;
    final status = switch (s.mode) {
      EncryptionStatusModeEnum.encrypting => l10n.encryptionEncrypting,
      EncryptionStatusModeEnum.on_ => s.key == EncryptionStatusKeyEnum.awsKms ? l10n.encryptionOnKms : l10n.encryptionOnServer,
      EncryptionStatusModeEnum.decrypting => l10n.encryptionDecrypting,
      _ => s.available ? l10n.encryptionOff : l10n.encryptionUnavailable,
    };
    Future<void> toggle(bool v) async {
      if (v) {
        unfocusBeforeModal();
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: Text(l10n.encryption),
            content: Text(l10n.encryptionConfirm),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l10n.cancel)),
              FilledButton(key: const Key('confirmEncryption'), onPressed: () => Navigator.pop(d, true), child: Text(l10n.encryptionTurnOn)),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;
      }
      await runGuarded(context, () => ref.read(backendProvider).setEncryption(orgId, v));
      ref.invalidate(_encryptionProvider(orgId));
    }

    return GroupedCard(
      children: [
        SwitchListTile(
          key: const Key('encryption'),
          title: Text(l10n.encryption),
          subtitle: Text('$status\n${l10n.encryptionHelp}${on ? '\n${l10n.encryptionKeyManaged}' : ''}'),
          isThreeLine: true,
          value: on,
          onChanged: hapticOnChanged(s.available || on ? toggle : null),
        ),
        if (on)
          GroupedTile(
            key: const Key('rotateKey'),
            icon: LucideIcons.rotateCw,
            title: l10n.encryptionRotate,
            subtitle: s.rotatedAt != null ? l10n.encryptionRotated(s.rotatedAt!.toLocal().formattedDate(context)) : l10n.encryptionRotateHelp,
            onTap: () async {
              final ok = await showConfirm(
                context: context,
                title: l10n.encryptionRotateTitle,
                message: l10n.encryptionRotateBody,
                confirmLabel: l10n.encryptionRotate,
                icon: LucideIcons.rotateCw,
                confirmKey: const Key('confirmRotateKey'),
              );
              if (!ok || !context.mounted) return;
              await runGuarded(context, () => ref.read(backendProvider).rotateEncryptionKey(orgId));
              ref.invalidate(_encryptionProvider(orgId));
            },
          ),
      ],
    );
  }
}

final _memoryBackendProvider = FutureProvider.autoDispose.family<MemoryBackend, String>((ref, orgId) => ref.watch(backendProvider).memoryBackend(orgId));

/// Memory backends (D-137): built-in memory, Honcho or Supermemory with the workspace's own key.
class MemoryBackendSection extends ConsumerWidget {
  const MemoryBackendSection({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final b = ref.watch(_memoryBackendProvider(orgId)).value;
    if (b == null) return const SizedBox.shrink();
    final name = switch (b.provider) {
      MemoryBackendProviderEnum.honcho => 'Honcho',
      MemoryBackendProviderEnum.supermemory => 'Supermemory',
      _ => l10n.memoryBuiltIn,
    };
    return GroupedCard(
      children: [
        GroupedTile(
          key: const Key('memoryBackend'),
          icon: LucideIcons.brain,
          title: l10n.memoryBackend,
          subtitle: '$name · ${l10n.memoryBackendHelp}',
          onTap: () async {
            final changed = await showAdaptiveSheet<bool>(
              context: context,
              builder: (_) => _MemoryBackendSheet(orgId: orgId, current: b),
            );
            if (changed == true) ref.invalidate(_memoryBackendProvider(orgId));
          },
        ),
      ],
    );
  }
}

class _MemoryBackendSheet extends ConsumerStatefulWidget {
  const _MemoryBackendSheet({required this.orgId, required this.current});
  final String orgId;
  final MemoryBackend current;

  @override
  ConsumerState<_MemoryBackendSheet> createState() => _MemoryBackendSheetState();
}

class _MemoryBackendSheetState extends ConsumerState<_MemoryBackendSheet> {
  var _provider = SetMemoryBackendRequestProviderEnum.supermemory;
  final _key = TextEditingController();
  final _workspace = TextEditingController();
  final _url = TextEditingController();
  var _copy = true;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.current.provider == MemoryBackendProviderEnum.honcho) _provider = SetMemoryBackendRequestProviderEnum.honcho;
    _workspace.text = widget.current.workspace ?? '';
    _url.text = widget.current.baseUrl ?? '';
  }

  @override
  void dispose() {
    _key.dispose();
    _workspace.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final r = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .setMemoryBackend(
            widget.orgId,
            SetMemoryBackendRequest(
              provider: _provider,
              apiKey: _key.text.trim(),
              workspace: _provider == SetMemoryBackendRequestProviderEnum.honcho && _workspace.text.trim().isNotEmpty ? _workspace.text.trim() : null,
              baseUrl: _url.text.trim().isEmpty ? null : _url.text.trim(),
              copyExisting: _copy,
            ),
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r != null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final external = widget.current.provider != MemoryBackendProviderEnum.postgres;
    return FormSheet(
      icon: LucideIcons.brain,
      title: l10n.memoryBackend,
      subtitle: l10n.memoryBackendSheetHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveMemoryBackend'),
      onSubmit: _busy || _key.text.trim().length < 8 ? null : _save,
      children: [
        SegmentedButton<SetMemoryBackendRequestProviderEnum>(
          segments: const [
            ButtonSegment(value: SetMemoryBackendRequestProviderEnum.supermemory, label: Text('Supermemory')),
            ButtonSegment(value: SetMemoryBackendRequestProviderEnum.honcho, label: Text('Honcho')),
          ],
          selected: {_provider},
          onSelectionChanged: (v) => setState(() => _provider = v.first),
        ),
        Revealable(builder: (context, hidden, toggle) => TextField(
          key: const Key('memoryApiKey'),
          controller: _key,
          textInputAction: TextInputAction.next,
          obscureText: hidden,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.chApiKey, suffixIcon: toggle),
        )),
        if (_provider == SetMemoryBackendRequestProviderEnum.honcho)
          TextField(
            key: const Key('memoryWorkspace'),
            controller: _workspace,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.memoryHonchoWorkspace, helperText: l10n.memoryHonchoWorkspaceHelp),
          ),
        TextField(
          key: const Key('memoryUrl'),
          controller: _url,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_busy && _key.text.trim().length >= 8) _save();
          },
          decoration: InputDecoration(labelText: l10n.memoryBaseUrl, helperText: l10n.memoryBaseUrlHelp),
        ),
        SwitchListTile(key: const Key('memoryCopy'), contentPadding: EdgeInsets.zero, title: Text(l10n.memoryCopyExisting), value: _copy, onChanged: hapticOnChanged((v) => setState(() => _copy = v))),
        if (external)
          TextButton(
            key: const Key('memoryBuiltIn'),
            onPressed: () async {
              final r = await runGuarded(context, () => ref.read(backendProvider).removeMemoryBackend(widget.orgId));
              if (r != null && context.mounted) Navigator.pop(context, true);
            },
            child: Text(l10n.memoryUseBuiltIn),
          ),
      ],
    );
  }
}

final _a2aProvider = FutureProvider.autoDispose.family<bool, String>((ref, orgId) => ref.watch(backendProvider).a2aEnabled(orgId));

/// Agent-to-agent (D-140): whether bots may be published as A2A agents.
class A2aSwitch extends ConsumerWidget {
  const A2aSwitch({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return GroupedCard(
      children: [
        SwitchListTile(
          key: const Key('a2aSwitch'),
          title: Text(l10n.a2a),
          subtitle: Text(l10n.a2aHelp),
          value: ref.watch(_a2aProvider(orgId)).value ?? false,
          onChanged: hapticOnChanged((v) async {
            await runGuarded(context, () => ref.read(backendProvider).setA2aEnabled(orgId, v));
            ref.invalidate(_a2aProvider(orgId));
          }),
        ),
      ],
    );
  }
}

final _telephonyProvider = FutureProvider.autoDispose.family<TelephonySettings, String>((ref, orgId) => ref.watch(backendProvider).telephony(orgId));

/// Phone calls through Twilio are off for now; the setup stays. Build with
/// `--dart-define=PHONE_CALLS=true` to show the section.
const phoneCallsEnabled = bool.fromEnvironment('PHONE_CALLS');

/// Calls for you (D-141): the workspace's Twilio account (admins).
class PhoneCallsSection extends ConsumerWidget {
  const PhoneCallsSection({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = ref.watch(_telephonyProvider(orgId)).value;
    if (t == null) return const SizedBox.shrink();
    return GroupedCard(
      children: [
        GroupedTile(
          key: const Key('phoneCalls'),
          icon: LucideIcons.phoneOutgoing,
          title: l10n.phoneCalls,
          subtitle: t.connected ? '${(t.fromNumber ?? '').formattedPhoneNumber} · ${l10n.phoneCallsCap}: ${t.dailyCap}' : '${l10n.phoneCallsOff} · ${l10n.phoneCallsHelp}',
          onTap: () async {
            final changed = await showAdaptiveSheet<bool>(
              context: context,
              builder: (_) => _PhoneCallsSheet(orgId: orgId, current: t),
            );
            if (changed == true) ref.invalidate(_telephonyProvider(orgId));
          },
        ),
      ],
    );
  }
}

class _PhoneCallsSheet extends ConsumerStatefulWidget {
  const _PhoneCallsSheet({required this.orgId, required this.current});
  final String orgId;
  final TelephonySettings current;

  @override
  ConsumerState<_PhoneCallsSheet> createState() => _PhoneCallsSheetState();
}

class _PhoneCallsSheetState extends ConsumerState<_PhoneCallsSheet> {
  late final _sid = TextEditingController(text: widget.current.accountSid ?? '');
  final _token = TextEditingController();
  late final _from = TextEditingController(text: (widget.current.fromNumber ?? '').formattedPhoneNumber);
  late final _cap = TextEditingController(text: '${widget.current.dailyCap}');
  late var _personal = widget.current.allowPersonalNumbers;
  var _busy = false;

  @override
  void dispose() {
    for (final c in [_sid, _token, _from, _cap]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      RegExp(r'^AC[0-9a-fA-F]{32}$').hasMatch(_sid.text.trim()) && RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(_from.text.unformattedPhoneNumber) && (widget.current.connected || _token.text.trim().length >= 16);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    VoidCallback? submit;
    return FormSheet(
      icon: LucideIcons.phoneOutgoing,
      title: l10n.phoneCalls,
      subtitle: l10n.phoneCallsHelp,
      submitLabel: l10n.save,
      submitKey: const Key('savePhoneCalls'),
      // Also run by the keyboard's Done key on the last field.
      onSubmit: submit = !_valid || _busy
          ? null
          : () async {
              setState(() => _busy = true);
              final r = await runGuarded(
                context,
                () => ref
                    .read(backendProvider)
                    .setTelephony(
                      widget.orgId,
                      SetTelephonyRequest(
                        accountSid: _sid.text.trim(),
                        authToken: _token.text.trim().isEmpty ? null : _token.text.trim(),
                        fromNumber: _from.text.unformattedPhoneNumber,
                        allowPersonalNumbers: _personal,
                        dailyCap: int.tryParse(_cap.text.trim()) ?? 10,
                      ),
                    ),
              );
              if (!mounted) return;
              setState(() => _busy = false);
              if (!context.mounted) return;
              if (r != null) Navigator.pop(context, true);
            },
      children: [
        TextField(
          key: const Key('twilioSid'),
          controller: _sid,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.twilioSid),
        ),
        Revealable(builder: (context, hidden, toggle) => TextField(
          key: const Key('twilioToken'),
          controller: _token,
          textInputAction: TextInputAction.next,
          obscureText: hidden,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.twilioToken, suffixIcon: toggle),
        )),
        TextField(
          key: const Key('twilioFrom'),
          controller: _from,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          inputFormatters: const [PhoneInputFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.twilioFrom),
        ),
        TextField(
          key: const Key('phoneCallsCap'),
          controller: _cap,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => submit?.call(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.phoneCallsCap),
        ),
        SwitchListTile(key: const Key('phoneCallsPersonal'), contentPadding: EdgeInsets.zero, title: Text(l10n.phoneCallsPersonal), value: _personal, onChanged: hapticOnChanged((v) => setState(() => _personal = v))),
      ],
    );
  }
}

final _paymentsProvider = FutureProvider.autoDispose.family<PaymentSettings, String>((ref, orgId) => ref.watch(backendProvider).paymentSettings(orgId));
final _paymentRequestsProvider = FutureProvider.autoDispose.family<List<PaymentRequest>, String>((ref, orgId) => ref.watch(backendProvider).paymentRequests(orgId));

String _money(int cents, String currency, String locale) => (cents / 100).humanizedCurrency(locale, currency.toUpperCase());

/// Payments (D-142): the workspace's card issuing account, caps and recent single-use cards (owners).
class PaymentsSection extends ConsumerWidget {
  const PaymentsSection({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = ref.watch(_paymentsProvider(orgId)).value;
    if (p == null) return const SizedBox.shrink();
    final recent = p.connected ? (ref.watch(_paymentRequestsProvider(orgId)).value ?? const <PaymentRequest>[]) : const <PaymentRequest>[];
    return GroupedCard(
      children: [
        GroupedTile(
          key: const Key('payments'),
          icon: LucideIcons.creditCard,
          title: l10n.payments,
          subtitle: p.connected ? l10n.paymentsOn(p.spentThisMonthUsd.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 2), p.monthlyCapUsd.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 0)) : l10n.paymentsHelp,
          onTap: () async {
            final changed = await showAdaptiveSheet<bool>(
              context: context,
              builder: (_) => _PaymentsSheet(orgId: orgId, current: p),
            );
            if (changed == true) ref.invalidate(_paymentsProvider(orgId));
          },
        ),
        for (final r in recent.take(5))
          GroupedTile(
            key: Key('payment-${r.id}'),
            icon: LucideIcons.receipt,
            title: '${_money(r.spentCents ?? r.amountCents, r.currency, context.l10n.localeName)} · ${r.merchant}',
            subtitle: '${r.status.value} · ${r.reason}',
          ),
      ],
    );
  }
}

class _PaymentsSheet extends ConsumerStatefulWidget {
  const _PaymentsSheet({required this.orgId, required this.current});
  final String orgId;
  final PaymentSettings current;

  @override
  ConsumerState<_PaymentsSheet> createState() => _PaymentsSheetState();
}

class _PaymentsSheetState extends ConsumerState<_PaymentsSheet> {
  final _key = TextEditingController();
  final _whsec = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _country = TextEditingController(text: 'US');
  late final _cap = TextEditingController(text: widget.current.monthlyCapUsd.toStringAsFixed(0));
  late final _botCap = TextEditingController(text: widget.current.botMonthlyCapUsd.toStringAsFixed(0));
  var _busy = false;

  List<TextEditingController> get _all => [_key, _whsec, _name, _email, _line1, _city, _state, _zip, _country, _cap, _botCap];

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => [_key, _whsec, _name, _email, _line1, _city, _zip].every((c) => c.text.trim().isNotEmpty) && _country.text.trim().length == 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    VoidCallback? submit;
    Widget field(String key, TextEditingController c, String label, {bool secret = false, bool last = false}) => Revealable(builder: (context, hidden, toggle) => TextField(
      key: Key(key),
      controller: c,
      obscureText: hidden && (secret),
      // Next moves down the form; Done on the last field saves it.
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onSubmitted: last ? (_) => submit?.call() : null,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label, suffixIcon: (secret) ? toggle : null),
    ));
    return FormSheet(
      icon: LucideIcons.creditCard,
      title: l10n.payments,
      subtitle: l10n.paymentsSheetHelp,
      submitLabel: l10n.save,
      submitKey: const Key('savePayments'),
      // Also run by the keyboard's Done key on the last field.
      onSubmit: submit = !_valid || _busy
          ? null
          : () async {
              setState(() => _busy = true);
              final r = await runGuarded(
                context,
                () => ref
                    .read(backendProvider)
                    .setPaymentSettings(
                      widget.orgId,
                      SetPaymentSettingsRequest(
                        secretKey: _key.text.trim(),
                        webhookSecret: _whsec.text.trim(),
                        cardholder: SetPaymentSettingsRequestCardholder(
                          name: _name.text.trim(),
                          email: _email.text.trim(),
                          line1: _line1.text.trim(),
                          city: _city.text.trim(),
                          state: _state.text.trim().isEmpty ? null : _state.text.trim(),
                          postalCode: _zip.text.trim(),
                          country: _country.text.trim().toUpperCase(),
                        ),
                        monthlyCapUsd: num.tryParse(_cap.text.trim()),
                        botMonthlyCapUsd: num.tryParse(_botCap.text.trim()),
                      ),
                    ),
              );
              if (!mounted) return;
              setState(() => _busy = false);
              if (!context.mounted) return;
              if (r != null) Navigator.pop(context, true);
            },
      children: [
        if (widget.current.webhookUrl.isUsable) SelectableText('${l10n.paymentsWebhook}: ${widget.current.webhookUrl}'),
        field('stripeKey', _key, l10n.paymentsStripeKey, secret: true),
        field('stripeWebhookSecret', _whsec, l10n.paymentsWebhookSecret, secret: true),
        field('cardholderName', _name, l10n.paymentsCardholder),
        field('cardholderEmail', _email, l10n.email),
        field('cardholderLine1', _line1, l10n.paymentsAddress),
        field('cardholderCity', _city, l10n.paymentsCity),
        field('cardholderState', _state, l10n.paymentsState),
        field('cardholderZip', _zip, l10n.paymentsZip),
        field('cardholderCountry', _country, l10n.paymentsCountry),
        field('paymentsCap', _cap, l10n.paymentsCap),
        field('paymentsBotCap', _botCap, l10n.paymentsBotCap, last: true),
      ],
    );
  }
}

final _secretStoreProvider = FutureProvider.autoDispose.family<SecretStoreSettings, String>((ref, orgId) => ref.watch(backendProvider).secretStore(orgId));

/// Secret store (D-145): bots' named secrets in Vault, or the workspace's Infisical project.
class SecretStoreSection extends ConsumerWidget {
  const SecretStoreSection({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(_secretStoreProvider(orgId)).value;
    if (s == null) return const SizedBox.shrink();
    final infisical = s.provider == SecretStoreSettingsProviderEnum.infisical;
    return GroupedCard(
      children: [
        GroupedTile(
          key: const Key('secretStore'),
          icon: LucideIcons.vault,
          title: l10n.secretStore,
          subtitle: infisical ? 'Infisical · ${s.projectId.orPlaceholder()} · ${s.environment.orPlaceholder()}' : l10n.secretStoreVault,
          onTap: () async {
            final changed = await showAdaptiveSheet<bool>(
              context: context,
              builder: (_) => _SecretStoreSheet(orgId: orgId, current: s),
            );
            if (changed == true) ref.invalidate(_secretStoreProvider(orgId));
          },
        ),
      ],
    );
  }
}

class _SecretStoreSheet extends ConsumerStatefulWidget {
  const _SecretStoreSheet({required this.orgId, required this.current});
  final String orgId;
  final SecretStoreSettings current;
  @override
  ConsumerState<_SecretStoreSheet> createState() => _SecretStoreSheetState();
}

class _SecretStoreSheetState extends ConsumerState<_SecretStoreSheet> {
  late final _site = TextEditingController(text: widget.current.siteUrl ?? 'https://app.infisical.com');
  late final _project = TextEditingController(text: widget.current.projectId ?? '');
  late final _env = TextEditingController(text: widget.current.environment ?? 'prod');
  final _clientId = TextEditingController();
  final _clientSecret = TextEditingController();
  var _move = true;
  var _busy = false;

  @override
  void dispose() {
    for (final c in [_site, _project, _env, _clientId, _clientSecret]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = [_site, _project, _clientId, _clientSecret].every((c) => c.text.trim().isNotEmpty);
    VoidCallback? submit;
    Widget field(String key, TextEditingController c, String label, {bool secret = false, bool last = false}) => Revealable(builder: (context, hidden, toggle) => TextField(
      key: Key(key),
      controller: c,
      obscureText: hidden && (secret),
      // Next moves down the form; Done on the last field saves it.
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onSubmitted: last ? (_) => submit?.call() : null,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label, suffixIcon: (secret) ? toggle : null),
    ));
    return FormSheet(
      icon: LucideIcons.vault,
      title: l10n.secretStore,
      subtitle: l10n.secretStoreHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveSecretStore'),
      // Also run by the keyboard's Done key on the last field.
      onSubmit: submit = !valid || _busy
          ? null
          : () async {
              setState(() => _busy = true);
              final r = await runGuarded(
                context,
                () => ref
                    .read(backendProvider)
                    .setSecretStore(
                      widget.orgId,
                      SetSecretStoreRequest(
                        siteUrl: _site.text.trim(),
                        projectId: _project.text.trim(),
                        environment: _env.text.trim().isEmpty ? null : _env.text.trim(),
                        clientId: _clientId.text.trim(),
                        clientSecret: _clientSecret.text.trim(),
                        moveExisting: _move,
                      ),
                    ),
              );
              if (!mounted) return;
              setState(() => _busy = false);
              if (!context.mounted) return;
              if (r != null) Navigator.pop(context, true);
            },
      children: [
        field('infisicalSite', _site, l10n.secretStoreSite),
        field('infisicalProject', _project, l10n.secretStoreProject),
        field('infisicalEnv', _env, l10n.secretStoreEnv),
        field('infisicalClientId', _clientId, l10n.secretStoreClientId),
        field('infisicalClientSecret', _clientSecret, l10n.secretStoreClientSecret, secret: true, last: true),
        SwitchListTile(key: const Key('infisicalMove'), contentPadding: EdgeInsets.zero, title: Text(l10n.secretStoreMove), value: _move, onChanged: hapticOnChanged((v) => setState(() => _move = v))),
        if (widget.current.provider == SecretStoreSettingsProviderEnum.infisical)
          TextButton(
            key: const Key('secretStoreVault'),
            onPressed: () async {
              final r = await runGuarded(context, () => ref.read(backendProvider).removeSecretStore(widget.orgId));
              if (r != null && context.mounted) Navigator.pop(context, true);
            },
            child: Text(l10n.secretStoreBack),
          ),
      ],
    );
  }
}

/// A link just created: shown once in full, with copy and share.
