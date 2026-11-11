import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

final _membersProvider = FutureProvider.autoDispose<List<WorkspaceMember>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).members(org.id);
});

/// Bot sharing (D-131): who can chat with, edit or administer a bot.
class SharingScreen extends ConsumerStatefulWidget {
  const SharingScreen({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<SharingScreen> createState() => _SharingScreenState();
}

typedef _Entry = ({String? userId, String? role, String label, String access});

class _SharingScreenState extends ConsumerState<SharingScreen> {
  BotAccess? _access;
  var _private = false;
  final _entries = <_Entry>[];
  var _dirty = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final backend = ref.read(backendProvider);
    final a = await runGuarded(context, () => backend.botAccess(widget.botId));
    if (!mounted || a == null) return;
    setState(() {
      _access = a;
      _private = a.visibility == BotAccessVisibilityEnum.private;
      _entries
        ..clear()
        ..addAll(a.entries.map((e) => (userId: e.userId, role: e.role?.value, label: e.email.isUsable ? e.email! : (e.role?.value).orPlaceholder(), access: e.access.value)));
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final r = await runGuarded(
      context,
      () => ref.read(backendProvider).setBotAccess(
            widget.botId,
            SetBotAccessRequest(
              visibility: _private ? SetBotAccessRequestVisibilityEnum.private : SetBotAccessRequestVisibilityEnum.team,
              entries: [
                for (final e in _entries)
                  SetBotAccessRequestEntriesInner(
                    userId: e.userId,
                    role: e.role == null ? null : SetBotAccessRequestEntriesInnerRoleEnum.values.byName(e.role!),
                    access: SetBotAccessRequestEntriesInnerAccessEnum.values.byName(e.access),
                  ),
              ],
            ),
          ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r != null) _dirty = false;
    });
    if (r != null) showSuccess(context, context.l10n.sharingSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = _access;
    final canAdmin = a?.canAdmin ?? false;
    String accessLabel(String v) => switch (v) { 'admin' => l10n.accessAdmin, 'edit' => l10n.accessEdit, _ => l10n.accessChat };
    final listed = _entries.map((e) => e.userId).toSet();
    final membersValue = ref.watch(_membersProvider);
    final members = membersValue.value ?? const <WorkspaceMember>[];
    final addable = members.where((m) => !listed.contains(m.userId) && m.userId != a?.createdBy).toList();
    return SubPage(
      title: l10n.sharing,
      subtitle: ref.watch(botProvider(widget.botId))?.name,
      body: a == null
          ? const Center(child: CircularProgressIndicator())
          : PageColumn(
              children: [
                FormNote(l10n.sharingHelp, icon: LucideIcons.users),
                const SizedBox(height: AppSpace.md),
                GroupedCard(children: [
                  SwitchListTile(
                    key: const Key('sharingPrivate'),
                    title: Text(l10n.sharingPrivate),
                    subtitle: Text(_private ? l10n.sharingPrivateOn : l10n.sharingPrivateOff),
                    value: _private,
                    onChanged: hapticOnChanged(canAdmin
                        ? (v) => setState(() {
                              _private = v;
                              _dirty = true;
                            })
                        : null),
                  ),
                ]),
                SectionHeader(title: l10n.sharingPeople),
                GroupedCard(children: [
                  for (final (i, e) in _entries.indexed)
                    ListTile(
                      key: Key('entry-${e.userId ?? e.role}'),
                      leading: Icon(e.role != null ? LucideIcons.users : LucideIcons.user, size: 18),
                      title: Text(e.role != null ? l10n.sharingEveryoneRole(e.role!) : e.label),
                      trailing: canAdmin
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              DropdownButton<String>(
                                key: Key('access-${e.userId ?? e.role}'),
                                value: e.access,
                                items: [for (final v in ['chat', 'edit', 'admin']) DropdownMenuItem(value: v, child: Text(accessLabel(v)))],
                                onChanged: hapticOnChanged((v) => setState(() {
                                  _entries[i] = (userId: e.userId, role: e.role, label: e.label, access: v ?? e.access);
                                  _dirty = true;
                                }), haptic: HapticsHelper.selection),
                              ),
                              IconButton(
                                key: Key('remove-${e.userId ?? e.role}'),
                                icon: const Icon(LucideIcons.x, size: 18),
                                onPressed: () => setState(() {
                                  _entries.removeAt(i);
                                  _dirty = true;
                                }),
                              ),
                            ])
                          : Text(accessLabel(e.access)),
                    ),
                  if (_entries.isEmpty) ListTile(title: Text(_private ? l10n.sharingOnlyCreator : l10n.sharingEveryoneChats)),
                ]),
                if (canAdmin && membersValue.hasError) ...[
                  const SizedBox(height: AppSpace.sm),
                  InlineError(error: membersValue.error!, onRetry: () => ref.invalidate(_membersProvider)),
                ],
                if (canAdmin && addable.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  Wrap(spacing: AppSpace.sm, children: [
                    for (final m in addable)
                      ActionChip(
                        key: Key('add-${m.userId}'),
                        avatar: const Icon(LucideIcons.plus, size: 16),
                        label: Text(m.email.orPlaceholder(m.userId)),
                        onPressed: () => setState(() {
                          _entries.add((userId: m.userId, role: null, label: m.email.orPlaceholder(m.userId), access: 'chat'));
                          _dirty = true;
                        }),
                      ),
                  ]),
                ],
                // Someone who isn't in the workspace yet: invite them first (D-167).
                if (canAdmin && (ref.watch(currentOrgProvider)?.role ?? OrgRole.member) != OrgRole.member) ...[
                  const SizedBox(height: AppSpace.xs),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const Key('sharingInvite'),
                      icon: const Icon(LucideIcons.userPlus, size: 18),
                      label: Text(l10n.inviteSomeoneNew),
                      onPressed: () => context.push('/settings/people'),
                    ),
                  ),
                ],
                if (canAdmin) ...[
                  const SizedBox(height: AppSpace.lg),
                  FilledButton(key: const Key('saveSharing'), onPressed: !_dirty || _busy ? null : _save, child: Text(l10n.save)),
                ],
              ],
            ),
    );
  }
}
