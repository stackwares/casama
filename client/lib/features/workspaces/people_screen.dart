import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/number_format.dart';
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
import 'join_flow.dart';

final _defaultInviteProvider = FutureProvider.autoDispose
    .family<CreatedInviteLink, String>(
      (ref, orgId) => ref.watch(backendProvider).defaultInvite(orgId),
    );
final _membersProvider = FutureProvider.autoDispose
    .family<List<WorkspaceMember>, String>(
      (ref, orgId) => ref.watch(backendProvider).members(orgId),
    );
final _requestsProvider = FutureProvider.autoDispose
    .family<List<JoinRequest>, String>(
      (ref, orgId) => ref.watch(backendProvider).joinRequests(orgId),
    );
final _pendingProvider = FutureProvider.autoDispose
    .family<List<PendingInvite>, String>(
      (ref, orgId) => ref.watch(backendProvider).pendingInvites(orgId),
    );
final _domainsProvider = FutureProvider.autoDispose.family<JoinDomains, String>(
  (ref, orgId) => ref.watch(backendProvider).joinDomains(orgId),
);
final _linksProvider = FutureProvider.autoDispose
    .family<List<InviteLink>, String>(
      (ref, orgId) => ref.watch(backendProvider).inviteLinks(orgId),
    );

/// Settings → People (D-167): the standing invite link (copy, share, QR), requests waiting for
/// approval, email invites, pending invites and members; a short code, joining by email domain and
/// custom links fold under Advanced (D-182).
class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final org = ref.watch(currentOrgProvider);
    if (org == null) return const SizedBox.shrink();
    final admin = org.role != OrgRole.member;
    final members =
        ref.watch(_membersProvider(org.id)).value ?? const <WorkspaceMember>[];
    return SubPage(
      title: l10n.people,
      subtitle: admin ? l10n.peopleHelp : null,
      children: [
        if (admin) ...[
          _InviteLinkCard(org: org),
          _RequestsSection(orgId: org.id),
          SectionHeader(title: l10n.inviteByEmail),
          _EmailInviteCard(orgId: org.id),
          _PendingInvitesSection(orgId: org.id),
        ] else
          FormNote(l10n.askAdminToInvite),
        SectionHeader(
          title: l10n.members,
          count: members.isEmpty
              ? null
              : members.length.humanizedCount(context.l10n.localeName),
        ),
        GroupedCard(
          children: [
            for (final m in members)
              GroupedTile(
                key: Key('member-${m.userId}'),
                icon: LucideIcons.user,
                // About you (D-169): the name they go by and their pronouns, then the email.
                title: [
                  m.name.orPlaceholder(m.email.orPlaceholder(m.userId)),
                  if (m.pronouns.isUsable) '(${m.pronouns})',
                ].join(' '),
                subtitle: m.name != null ? m.email : null,
                trailing: Text(
                  _roleLabel(context, m.role.value),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        // A code to type, joining by email domain and custom links fold away (D-182).
        if (admin)
          AdvancedSection(
            id: 'workspace.people',
            summary: l10n.peopleAdvancedSummary,
            children: [
              _InviteCodeCard(orgId: org.id),
              SectionHeader(title: l10n.joinByDomain),
              _DomainCard(orgId: org.id),
              const SizedBox(height: AppSpace.md),
              _CustomLinks(orgId: org.id),
            ],
          ),
        const SizedBox(height: AppSpace.lg),
      ],
    );
  }
}

String _roleLabel(BuildContext context, String role) => switch (role) {
  'owner' => context.l10n.roleOwner,
  'admin' => context.l10n.roleAdmin,
  _ => context.l10n.roleMember,
};

/// A link with Copy, Share and QR.
class _LinkBox extends StatelessWidget {
  const _LinkBox({super.key, required this.url, required this.workspace});
  final String url;
  final String workspace;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(
              alpha: context.isDark ? 0.14 : 0.07,
            ),
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: SelectableText(
            url,
            key: const Key('inviteUrl'),
            maxLines: 2,
            style: AppText.mono,
          ),
        ),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            FilledButton.icon(
              key: const Key('copyInvite'),
              onPressed: () => copyInvite(context, url),
              icon: const Icon(LucideIcons.copy, size: 18),
              label: Text(l10n.copyLink),
            ),
            Builder(
              builder: (c) => OutlinedButton.icon(
                key: const Key('shareInvite'),
                onPressed: () => shareInvite(c, url: url, workspace: workspace),
                icon: const Icon(LucideIcons.share2, size: 18),
                label: Text(l10n.shareLinkLabel),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('qrInvite'),
              onPressed: () =>
                  showInviteQr(context, url: url, workspace: workspace),
              icon: const Icon(LucideIcons.qrCode, size: 18),
              label: Text(l10n.qrCode),
            ),
          ],
        ),
      ],
    );
  }
}

class _InviteLinkCard extends ConsumerWidget {
  const _InviteLinkCard({required this.org});
  final OrganizationWithRole org;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final link = ref.watch(_defaultInviteProvider(org.id));
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: link.when(
        loading: () => const SkeletonList(count: 2, padding: EdgeInsets.zero),
        error: (e, _) => Text(errorText(context, e)),
        data: (l) {
          final approval = l.requiresApproval ?? false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.sm,
            children: [
              Text(
                l10n.inviteLink,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                approval ? l10n.inviteLinkApprovalHelp : l10n.inviteLinkHelp,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              _LinkBox(key: ValueKey(l.url), url: l.url, workspace: org.name),
              SwitchListTile(
                key: const Key('inviteApproval'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.askBeforeJoining),
                subtitle: Text(l10n.askBeforeJoiningHelp),
                value: approval,
                onChanged: hapticOnChanged((v) async {
                  await runGuarded(
                    context,
                    () => ref
                        .read(backendProvider)
                        .updateDefaultInvite(org.id, requiresApproval: v),
                  );
                  ref.invalidate(_defaultInviteProvider(org.id));
                }),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('resetInvite'),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: Text(l10n.resetLink),
                  onPressed: () async {
                    final ok = await showConfirm(
                      context: context,
                      title: l10n.resetLink,
                      message: l10n.resetLinkHelp,
                      confirmLabel: l10n.resetLink,
                      destructive: true,
                    );
                    if (!ok || !context.mounted) return;
                    await runGuarded(
                      context,
                      () => ref
                          .read(backendProvider)
                          .updateDefaultInvite(org.id, reset: true),
                    );
                    ref.invalidate(_defaultInviteProvider(org.id));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InviteCodeCard extends ConsumerStatefulWidget {
  const _InviteCodeCard({required this.orgId});
  final String orgId;

  @override
  ConsumerState<_InviteCodeCard> createState() => _InviteCodeCardState();
}

class _InviteCodeCardState extends ConsumerState<_InviteCodeCard> {
  String? _code;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.sm,
        children: [
          Text(
            l10n.inviteCode,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            l10n.inviteCodeCardHelp,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_code != null)
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _code!,
                    key: const Key('inviteCode'),
                    style: AppText.mono.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.copy,
                  icon: const Icon(LucideIcons.copy),
                  onPressed: () => copyInvite(context, _code!),
                ),
              ],
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: const Key('makeInviteCode'),
              icon: const Icon(LucideIcons.hash, size: 18),
              label: Text(_code == null ? l10n.getCode : l10n.getNewCode),
              onPressed: () async {
                final c = await runGuarded(
                  context,
                  () =>
                      ref.read(backendProvider).createInviteCode(widget.orgId),
                );
                if (c != null && mounted) setState(() => _code = c.token);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "a@x.com, b@y.com\nc@z.com" -> the addresses that look valid, without repeats.
List<String> parseEmails(String text) {
  final seen = <String>{};
  return [
    for (final e in text.split(RegExp(r'[\s,;]+')))
      if (RegExp(r'^[^@\s<>]+@[^@\s<>]+\.[^@\s<>]+$').hasMatch(e.trim()) &&
          seen.add(e.trim().toLowerCase()))
        e.trim().toLowerCase(),
  ];
}

class _EmailInviteCard extends ConsumerStatefulWidget {
  const _EmailInviteCard({required this.orgId});
  final String orgId;

  @override
  ConsumerState<_EmailInviteCard> createState() => _EmailInviteCardState();
}

class _EmailInviteCardState extends ConsumerState<_EmailInviteCard> {
  final _emails = TextEditingController();
  var _admin = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _emails.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emails.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final list = parseEmails(_emails.text);
    if (list.isEmpty) return;
    setState(() => _busy = true);
    final sent = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .inviteMany(widget.orgId, list, admin: _admin),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (sent == null) return;
    _emails.clear();
    ref.invalidate(_pendingProvider(widget.orgId));
    final unsent = sent
        .where((i) => !i.emailSent && i.acceptToken != null)
        .toList();
    if (unsent.isEmpty) {
      showSuccess(context, l10n.invitesSent(sent.length));
      return;
    }
    // No email on this server: hand over the links to send another way.
    final base =
        (ref.read(_defaultInviteProvider(widget.orgId)).value?.url ?? '')
            .replaceFirst(RegExp(r'/join/.*$'), '');
    await showAdaptiveSheet<void>(
      context: context,
      contentPadsBottom: true,
      builder: (c) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.lg,
          BottomPadding.of(c, minimum: AppSpace.lg),
        ),
        child: Column(
          key: const Key('unsentInvites'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.sm,
          children: [
            Text(
              l10n.sendInvitesYourself,
              style: c.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(l10n.sendInvitesYourselfHelp, style: c.textTheme.bodyMedium),
            // A label and a copy button, not the raw token.
            for (final i in unsent)
              GroupedCard(
                children: [
                  GroupedTile(
                    key: Key('unsent-${i.email}'),
                    icon: LucideIcons.mail,
                    title: i.email,
                    subtitle: l10n.inviteLinkToCopy,
                    onTap: () => copyInvite(
                      c,
                      base.isEmpty
                          ? i.acceptToken!
                          : '$base/join/${i.acceptToken}',
                    ),
                    trailing: IconButton(
                      tooltip: l10n.copyLink,
                      icon: const Icon(LucideIcons.copy, size: 18),
                      onPressed: () => copyInvite(
                        c,
                        base.isEmpty
                            ? i.acceptToken!
                            : '$base/join/${i.acceptToken}',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = parseEmails(_emails.text).length;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.sm,
        children: [
          TextField(
            key: const Key('inviteEmails'),
            controller: _emails,
            minLines: 2,
            maxLines: 6,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.emailAddresses,
              hintText: 'ana@company.com, ben@company.com',
              helperText: l10n.emailAddressesHelp,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  key: const Key('inviteAsAdmin'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.inviteAsAdmin),
                  value: _admin,
                  onChanged: hapticOnChanged((v) => setState(() => _admin = v)),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              FilledButton.icon(
                key: const Key('sendInvites'),
                onPressed: count == 0 || _busy ? null : _send,
                icon: const Icon(LucideIcons.send, size: 18),
                label: Text(
                  count > 1 ? l10n.sendInvitesCount(count) : l10n.sendInvite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestsSection extends ConsumerWidget {
  const _RequestsSection({required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list =
        ref.watch(_requestsProvider(orgId)).value ?? const <JoinRequest>[];
    if (list.isEmpty) return const SizedBox.shrink();
    Future<void> decide(JoinRequest r, bool approve) async {
      await runGuarded(
        context,
        () => ref.read(backendProvider).decideJoinRequest(orgId, r.id, approve),
      );
      ref.invalidate(_requestsProvider(orgId));
      ref.invalidate(_membersProvider(orgId));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.waitingToJoin,
          count: list.length.humanizedCount(context.l10n.localeName),
        ),
        GroupedCard(
          children: [
            for (final r in list)
              GroupedTile(
                key: Key('request-${r.id}'),
                icon: LucideIcons.userPlus,
                title: r.displayName.orPlaceholder(
                  r.email.orPlaceholder(r.userId),
                ),
                subtitle: [
                  if (r.displayName.isUsable && r.email.isUsable) r.email!,
                  relativeTime(r.createdAt, context),
                ].join(' · '),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      key: Key('decline-${r.id}'),
                      onPressed: () => decide(r, false),
                      child: Text(l10n.decline),
                    ),
                    FilledButton.tonal(
                      key: Key('approve-${r.id}'),
                      onPressed: () => decide(r, true),
                      child: Text(l10n.approve),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PendingInvitesSection extends ConsumerWidget {
  const _PendingInvitesSection({required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list =
        ref.watch(_pendingProvider(orgId)).value ?? const <PendingInvite>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.pendingInvites,
          count: list.length.humanizedCount(context.l10n.localeName),
        ),
        GroupedCard(
          children: [
            for (final i in list)
              GroupedTile(
                key: Key('pending-${i.id}'),
                icon: LucideIcons.mail,
                title: i.email,
                subtitle: i.expiresAt.isBefore(DateTime.now())
                    ? l10n.inviteExpired
                    : l10n.inviteExpires(relativeTime(i.expiresAt, context)),
                trailing: PopupMenuButton<String>(
                  key: Key('pendingMenu-${i.id}'),
                  onOpened: unfocusBeforeModal,
                  icon: const Icon(LucideIcons.ellipsis),
                  onSelected: (v) async {
                    final backend = ref.read(backendProvider);
                    if (v == 'resend') {
                      final r = await runGuarded(
                        context,
                        () => backend.resendInvite(orgId, i.id),
                      );
                      if (r != null && context.mounted) {
                        showSuccess(
                          context,
                          r.emailSent
                              ? l10n.inviteSent(i.email)
                              : l10n.inviteRenewed,
                        );
                      }
                    } else {
                      await runGuarded(
                        context,
                        () => backend.revokeInvite(orgId, i.id),
                      );
                    }
                    ref.invalidate(_pendingProvider(orgId));
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'resend',
                      child: Text(l10n.resendInvite),
                    ),
                    PopupMenuItem(
                      value: 'revoke',
                      child: Text(l10n.revokeInvite),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DomainCard extends ConsumerWidget {
  const _DomainCard({required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = ref.watch(_domainsProvider(orgId)).value;
    if (d == null) return const SizedBox.shrink();
    final mine = d.myDomain;
    final on = mine != null && d.items.contains(mine);
    final others = d.items.where((x) => x != mine).toList();
    return GroupedCard(
      children: [
        if (d.canUse && mine != null)
          SwitchListTile(
            key: const Key('joinDomain'),
            title: Text(l10n.joinByDomainSwitch(mine)),
            subtitle: Text(l10n.joinByDomainHelp),
            value: on,
            onChanged: hapticOnChanged((v) async {
              await runGuarded(
                context,
                () => ref.read(backendProvider).setJoinDomain(orgId, v),
              );
              ref.invalidate(_domainsProvider(orgId));
            }),
          )
        else
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: FormNote(l10n.joinByDomainUnavailable),
          ),
        for (final x in others)
          GroupedTile(
            key: Key('domain-$x'),
            icon: LucideIcons.atSign,
            title: '@$x',
            trailing: TextButton(
              onPressed: () async {
                await runGuarded(
                  context,
                  () => ref
                      .read(backendProvider)
                      .setJoinDomain(orgId, false, domain: x),
                );
                ref.invalidate(_domainsProvider(orgId));
              },
              child: Text(l10n.remove),
            ),
          ),
      ],
    );
  }
}

/// Links with their own role, expiry and use limit (D-099), and the codes made from this screen.
class _CustomLinks extends ConsumerStatefulWidget {
  const _CustomLinks({required this.orgId});
  final String orgId;

  @override
  ConsumerState<_CustomLinks> createState() => _CustomLinksState();
}

class _CustomLinksState extends ConsumerState<_CustomLinks> {
  var _role = 'member';
  int? _days = 7;
  int? _uses;
  CreatedInviteLink? _created;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final org = ref.watch(currentOrgProvider);
    final links =
        (ref.watch(_linksProvider(widget.orgId)).value ?? const <InviteLink>[])
            .where((l) => l.isDefault != true)
            .toList();
    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: const Key('customLinks'),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(LucideIcons.slidersHorizontal),
        title: Text(l10n.customLinks),
        subtitle: Text(l10n.customLinksHelp),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          0,
          AppSpace.lg,
          AppSpace.lg,
        ),
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final fields = [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: const Key('linkRole'),
                  initialValue: _role,
                  decoration: InputDecoration(labelText: l10n.inviteRole),
                  items: [
                    DropdownMenuItem(
                      value: 'member',
                      child: Text(l10n.roleMember),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text(l10n.roleAdmin),
                    ),
                  ],
                  onChanged: hapticOnChanged(
                    (v) => setState(() => _role = v ?? _role),
                    haptic: HapticsHelper.selection,
                  ),
                ),
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: _days,
                  decoration: InputDecoration(labelText: l10n.linkExpires),
                  items: [
                    for (final d in [1, 7, 30])
                      DropdownMenuItem(value: d, child: Text(l10n.linkDays(d))),
                    DropdownMenuItem(value: null, child: Text(l10n.linkNever)),
                  ],
                  onChanged: hapticOnChanged(
                    (v) => setState(() => _days = v),
                    haptic: HapticsHelper.selection,
                  ),
                ),
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: _uses,
                  decoration: InputDecoration(labelText: l10n.linkMaxUses),
                  items: [
                    for (final u in [1, 5, 25])
                      DropdownMenuItem(value: u, child: Text('$u')),
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.linkUnlimited),
                    ),
                  ],
                  onChanged: hapticOnChanged(
                    (v) => setState(() => _uses = v),
                    haptic: HapticsHelper.selection,
                  ),
                ),
              ];
              // Side by side where there's room, stacked on phones.
              if (box.maxWidth < 520) {
                return Column(spacing: AppSpace.sm, children: fields);
              }
              return Row(
                spacing: AppSpace.sm,
                children: [for (final f in fields) Expanded(child: f)],
              );
            },
          ),
          const SizedBox(height: AppSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              key: const Key('createInviteLink'),
              icon: const Icon(LucideIcons.link, size: 18),
              label: Text(l10n.createInviteLink),
              onPressed: () async {
                final created = await runGuarded(
                  context,
                  () => ref
                      .read(backendProvider)
                      .createInviteLink(
                        widget.orgId,
                        role: _role,
                        expiresInDays: _days,
                        maxUses: _uses,
                      ),
                );
                if (created == null || !context.mounted) return;
                setState(() => _created = created);
                ref.invalidate(_linksProvider(widget.orgId));
              },
            ),
          ),
          if (_created != null) ...[
            const SizedBox(height: AppSpace.sm),
            Container(
              key: const Key('createdLink'),
              child: _LinkBox(
                key: ValueKey(_created!.url),
                url: _created!.url,
                workspace: org?.name ?? '',
              ),
            ),
          ],
          if (links.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            GroupedCard(
              children: [
                // What it is, who it's for and when it was made; not the token's first letters.
                for (final l in links)
                  GroupedTile(
                    key: Key('link-${l.id}'),
                    icon: l.kind == InviteLinkKindEnum.code
                        ? LucideIcons.hash
                        : LucideIcons.link,
                    title:
                        '${l.kind == InviteLinkKindEnum.code ? l10n.inviteCode : l10n.inviteLink} · ${l.role == InviteLinkRoleEnum.admin ? l10n.roleAdmin : l10n.roleMember}',
                    subtitle: [
                      l10n.linkMade(relativeTime(l.createdAt, context)),
                      l10n.linkUses(
                        '${l.uses.humanizedCount(context.l10n.localeName)}${l.maxUses == null ? '' : '/${l.maxUses!.humanizedCount(context.l10n.localeName)}'}',
                      ),
                      if (l.revokedAt != null) l10n.linkRevoked,
                    ].join(' · '),
                    trailing: l.revokedAt != null
                        ? null
                        : TextButton(
                            key: Key('revoke-${l.id}'),
                            onPressed: () async {
                              final ok = await showConfirm(
                                context: context,
                                title: l10n.revokeLink,
                                message: l10n.inviteLinksHelp,
                                confirmLabel: l10n.revokeLink,
                                destructive: true,
                              );
                              if (!ok || !context.mounted) return;
                              await runGuarded(
                                context,
                                () => ref
                                    .read(backendProvider)
                                    .revokeInviteLink(widget.orgId, l.id),
                              );
                              ref.invalidate(_linksProvider(widget.orgId));
                            },
                            child: Text(l10n.revokeLink),
                          ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
