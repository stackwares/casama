import 'package:flutter/material.dart';
import '../mcp/mcp_screens.dart';
import 'workspace_files.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

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
          : Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(), style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: size * 0.45)),
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
                      child: Text(org.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
      builder: (c) => Consumer(
        builder: (context, ref, _) {
          final l10n = context.l10n;
          final orgs = ref.watch(organizationsProvider).value ?? const <OrganizationWithRole>[];
          final current = ref.watch(currentOrgProvider);
          final badges = ref.watch(workspaceBadgesProvider).value ?? const {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
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
                            if ((badges[o.id] ?? 0) > 0) Badge(label: Text('${badges[o.id]}')),
                            if (o.id == current?.id) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(LucideIcons.check, color: context.colorScheme.primary)),
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
                TextButton.icon(
                  key: const Key('joinWorkspace'),
                  icon: const Icon(LucideIcons.link, size: 18),
                  label: Text(l10n.joinWithLink),
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
          children: [
            for (final e in spaceIcons.entries)
              ChoiceChip(key: Key('icon-${e.key}'), label: Icon(e.value, size: 18), selected: icon == e.key, onSelected: (_) => onIcon(e.key)),
          ],
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
        ref.invalidate(organizationsProvider);
        ref.read(selectedOrgIdProvider.notifier).select(org.id);
        Navigator.pop(context);
      },
      children: [
        TextField(key: const Key('workspaceNameField'), controller: _name, decoration: InputDecoration(labelText: l10n.workspaceName)),
        _LookPicker(icon: _icon, color: _color, onIcon: (v) => setState(() => _icon = v), onColor: (v) => setState(() => _color = v)),
      ],
    );
  }
}

/// Extracts the token from a pasted invite link (or takes a bare token).
String? inviteTokenFrom(String input) {
  final m = RegExp(r'(kjoin_[A-Za-z0-9_-]{16,})').firstMatch(input.trim());
  return m?.group(1);
}

class JoinSpaceSheet extends ConsumerStatefulWidget {
  const JoinSpaceSheet({super.key});

  @override
  ConsumerState<JoinSpaceSheet> createState() => _JoinSpaceSheetState();
}

class _JoinSpaceSheetState extends ConsumerState<JoinSpaceSheet> {
  final _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.link,
      title: l10n.joinWithLink,
      subtitle: l10n.joinWorkspaceHelp,
      submitLabel: l10n.joinWithLink,
      submitKey: const Key('joinWorkspaceSubmit'),
      onSubmit: () async {
        final token = inviteTokenFrom(_link.text);
        if (token == null) return;
        final ok = await joinWorkspace(context, ref, token);
        if (ok && context.mounted) Navigator.pop(context);
      },
      children: [
        TextField(key: const Key('inviteLinkField'), controller: _link, decoration: InputDecoration(labelText: l10n.inviteLinkField, hintText: 'https://…/join/kjoin_…')),
      ],
    );
  }
}

/// Joins with a link and switches to the workspace.
Future<bool> joinWorkspace(BuildContext context, WidgetRef ref, String token) async {
  final l10n = context.l10n;
  final org = await runGuarded(context, () => ref.read(backendProvider).acceptInviteLink(token));
  if (org == null) return false;
  ref.invalidate(organizationsProvider);
  ref.read(selectedOrgIdProvider.notifier).select(org.id);
  if (context.mounted) showMessage(context, l10n.joinedWorkspace(org.name));
  return true;
}

/// `/join/<token>`: joins after sign-in, then opens the workspace.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, required this.token});
  final String token;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  var _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(pendingJoinTokenProvider.notifier).set(null);
      final ok = await joinWorkspace(context, ref, widget.token);
      if (!mounted) return;
      if (ok) {
        context.go('/bots');
      } else {
        setState(() => _failed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: _failed
            ? EmptyState(icon: LucideIcons.unlink, title: l10n.joinWithLink, message: l10n.joinFailed)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(l10n.joiningWorkspace)],
              ),
      ),
    );
  }
}

final _linksProvider = FutureProvider.family<List<InviteLink>, String>((ref, orgId) => ref.watch(backendProvider).inviteLinks(orgId));

/// Settings → Workspace: name, look, invite links (admins).
class WorkspaceSettingsScreen extends ConsumerStatefulWidget {
  const WorkspaceSettingsScreen({super.key});

  @override
  ConsumerState<WorkspaceSettingsScreen> createState() => _WorkspaceSettingsScreenState();
}

class _WorkspaceSettingsScreenState extends ConsumerState<WorkspaceSettingsScreen> {
  final _name = TextEditingController();
  String? _loadedFor;
  var _role = 'member';
  int? _days = 7;
  int? _uses;
  CreatedInviteLink? _created;

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
    final links = admin ? (ref.watch(_linksProvider(org.id)).value ?? const <InviteLink>[]) : const <InviteLink>[];
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
        if (admin) ...[
          SectionHeader(title: l10n.inviteLinks),
          AppCard(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.sm,
              children: [
                FormNote(l10n.inviteLinksHelp),
                Wrap(
                  spacing: AppSpace.md,
                  runSpacing: AppSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String>(
                      key: const Key('linkRole'),
                      value: _role,
                      items: [DropdownMenuItem(value: 'member', child: Text(l10n.roleMember)), DropdownMenuItem(value: 'admin', child: Text(l10n.roleAdmin))],
                      onChanged: (v) => setState(() => _role = v ?? _role),
                    ),
                    DropdownButton<int?>(
                      value: _days,
                      items: [
                        for (final d in [1, 7, 30]) DropdownMenuItem(value: d, child: Text('${l10n.linkExpires}: ${l10n.linkDays('$d')}')),
                        DropdownMenuItem(value: null, child: Text('${l10n.linkExpires}: ${l10n.linkNever}')),
                      ],
                      onChanged: (v) => setState(() => _days = v),
                    ),
                    DropdownButton<int?>(
                      value: _uses,
                      items: [
                        for (final u in [1, 5, 25]) DropdownMenuItem(value: u, child: Text('${l10n.linkMaxUses}: $u')),
                        DropdownMenuItem(value: null, child: Text('${l10n.linkMaxUses}: ${l10n.linkUnlimited}')),
                      ],
                      onChanged: (v) => setState(() => _uses = v),
                    ),
                    FilledButton.icon(
                      key: const Key('createInviteLink'),
                      icon: const Icon(LucideIcons.link, size: 18),
                      label: Text(l10n.createInviteLink),
                      onPressed: () async {
                        final created = await runGuarded(context, () => ref.read(backendProvider).createInviteLink(org.id, role: _role, expiresInDays: _days, maxUses: _uses));
                        if (created == null || !context.mounted) return;
                        setState(() => _created = created);
                        ref.invalidate(_linksProvider(org.id));
                        try {
                          await Clipboard.setData(ClipboardData(text: created.url));
                          if (context.mounted) showMessage(context, l10n.linkCopied);
                        } catch (_) {
                          // The link stays on screen to copy by hand.
                        }
                      },
                    ),
                  ],
                ),
                if (_created != null) SelectableText(_created!.url, key: const Key('createdLink')),
              ],
            ),
          ),
          if (links.isNotEmpty)
            GroupedCard(
              children: [
                for (final l in links)
                  GroupedTile(
                    key: Key('link-${l.id}'),
                    icon: LucideIcons.link,
                    title: '${l.tokenHint}… · ${l.role == InviteLinkRoleEnum.admin ? l10n.roleAdmin : l10n.roleMember}',
                    subtitle: [
                      l10n.linkUses('${l.uses}${l.maxUses == null ? '' : '/${l.maxUses}'}'),
                      if (l.revokedAt != null) l10n.linkRevoked,
                    ].join(' · '),
                    trailing: l.revokedAt != null
                        ? null
                        : TextButton(
                            key: Key('revoke-${l.id}'),
                            onPressed: () async {
                              await runGuarded(context, () => ref.read(backendProvider).revokeInviteLink(org.id, l.id));
                              ref.invalidate(_linksProvider(org.id));
                            },
                            child: Text(l10n.revokeLink),
                          ),
                  ),
              ],
            ),
        ],
        if (admin) ...[const SizedBox(height: AppSpace.lg), McpSettingsSection(orgId: org.id)],
        if (admin) ...[const SizedBox(height: AppSpace.lg), WorkspaceFilesSection(orgId: org.id)],
      ],
    );
  }
}
