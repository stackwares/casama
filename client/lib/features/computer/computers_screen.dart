import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import '../companion/companion_controller.dart';
import 'computer_details.dart';
import 'computer_screen.dart';

/// Team and private computers: create, rename, switch between headless and desktop, delete.
class ComputersScreen extends ConsumerWidget {
  const ComputersScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showAdaptiveSheet<bool>(context: context, builder: (_) => const NewComputerSheet());
    if (created == true) ref.invalidate(computersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SubPage(
      title: l10n.computers,
      actions: [HeaderIconButton(key: const Key('newComputer'), icon: LucideIcons.plus, tooltip: l10n.newComputer, onPressed: () => _create(context, ref))],
      body: AsyncView(
        value: ref.watch(computersProvider),
        onRetry: () => ref.invalidate(computersProvider),
        data: (items) => PageListView(
          header: FormNote(l10n.computersHelp),
          itemCount: items.length,
          itemBuilder: (context, i) => _ComputerCard(computer: items[i]).appListItemEntrance(i),
        ),
      ),
    );
  }
}

class _ComputerCard extends ConsumerWidget {
  const _ComputerCard({required this.computer});
  final Computer computer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final c = computer;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    Bot? ownerBot;
    for (final b in bots) {
      if (b.id == c.ownerBotId) ownerBot = b;
    }
    final desktop = c.profile == ComputerProfileEnum.desktop;
    final running = c.state == ComputerState.running || c.state == ComputerState.idle;
    final local = c.kind == ComputerKindEnum.local;
    // Whose computer it is, unless the name already says so; a personal computer says "This
    // device" in its system line instead (D-227).
    final owner = local
        ? null
        : (c.kind == ComputerKindEnum.team
              ? l10n.teamComputer
              : (ownerBot != null ? l10n.privateComputerOf(ownerBot.name) : l10n.privateComputer));
    final showOwner = owner != null && owner.toLowerCase() != c.name.trim().toLowerCase();
    // Without a device from the server (an older one), the companion knows if it's this machine.
    final thisDevice = local && ref.watch(companionControllerProvider).value?.computerId == c.id;
    final system = computerSystemLine(context, c, thisDevice: thisDevice);
    final access = local ? computerAccessLine(context, c) : null;
    final activity = computerActivityLine(context, c);
    final error = c.state == ComputerState.error ? c.error?.trim() : null;
    final meta = context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final stateColor = running ? colors.working : (c.state == ComputerState.error ? colors.negative : scheme.onSurfaceVariant);
    final backend = ref.read(backendProvider);

    Future<void> action(String v) async {
      switch (v) {
        case 'live':
          context.push('/computer/live?c=${c.id}');
          return;
        case 'profile':
          await runGuarded(context, () => backend.updateComputer(c.id, profile: desktop ? 'headless' : 'desktop'));
        case 'desktops':
          // Team computers (D-148): how many bots may use the desktop at the same time.
          final n = (await showChoiceSheet<int>(
            context,
            icon: LucideIcons.users,
            title: l10n.desktopUsers,
            subtitle: l10n.desktopUsersHelp,
            selected: c.maxDesktops,
            choices: [
              for (final v in const [1, 2, 3, 4, 5]) Choice(key: Key('desktops-$v'), value: v, label: l10n.desktopUsersCount(v)),
            ],
          ))?.value;
          if (n == null || n == c.maxDesktops || !context.mounted) return;
          await runGuarded(context, () => backend.updateComputer(c.id, maxDesktops: n));
        case 'rename':
          final name = await showTextPrompt(
            context,
            title: l10n.renameComputer,
            label: l10n.computerName,
            initial: c.name,
            submitLabel: l10n.save,
            icon: LucideIcons.pencil,
          );
          if (name == null || !context.mounted) return;
          await runGuarded(context, () => backend.updateComputer(c.id, name: name));
        case 'delete':
          final ok = await showConfirm(
            context: context,
            title: l10n.deleteComputerTitle(c.name),
            message: l10n.deleteComputerConfirm(c.name),
            confirmLabel: l10n.delete,
            destructive: true,
          );
          if (!ok || !context.mounted) return;
          await runGuarded(context, () => backend.deleteComputer(c.id));
      }
      ref.invalidate(computersProvider);
    }

    return AppCard(
      key: Key('computer-${c.id}'),
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.xxs, 14),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: stateColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.icon + 2)),
                alignment: Alignment.center,
                child: Icon(desktop ? LucideIcons.monitor : LucideIcons.squareTerminal, color: stateColor, size: 22),
              ),
              if (ownerBot != null)
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: BotAvatar(name: ownerBot.name, avatar: ownerBot.avatarUrl, size: 22, ringColor: scheme.surfaceContainerLow),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (showOwner) ...[
                  const SizedBox(height: 2),
                  Text(owner, maxLines: 1, overflow: TextOverflow.ellipsis, style: meta),
                ],
                if (system.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(system, key: Key('computerSystem-${c.id}'), maxLines: 2, overflow: TextOverflow.ellipsis, style: meta),
                ],
                if (access != null) ...[
                  const SizedBox(height: 2),
                  Text(access, key: Key('computerAccess-${c.id}'), maxLines: 2, overflow: TextOverflow.ellipsis, style: meta),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    StatusLabel(text: computerStatusLabel(context, c), color: stateColor, pill: true),
                    // Desktop or headless, and the provider, mean nothing on a personal computer (D-218).
                    if (!isPersonalComputer(c))
                    StatusLabel(
                      text: desktop ? l10n.profileDesktop : l10n.profileHeadless,
                      color: scheme.onSurfaceVariant,
                      pill: true,
                      icon: desktop ? LucideIcons.monitor : LucideIcons.squareTerminal,
                    ),
                    if (c.hasSnapshot && !isPersonalComputer(c))
                      Tooltip(
                        message: l10n.computerSavedHelp,
                        child: StatusLabel(text: l10n.computerSaved, color: scheme.onSurfaceVariant, pill: true, icon: LucideIcons.archive),
                      ),
                    if (c.provider != 'docker' && !isPersonalComputer(c)) StatusLabel(text: c.provider, color: scheme.onSurfaceVariant, pill: true),
                  ],
                ),
                if (error != null && error.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(error, key: Key('computerError-${c.id}'), maxLines: 2, overflow: TextOverflow.ellipsis, style: meta?.copyWith(color: colors.negative)),
                ] else if (activity != null) ...[
                  const SizedBox(height: 6),
                  Text(activity, key: Key('computerActivity-${c.id}'), style: meta),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            key: Key('computerMenu-${c.id}'),
            tooltip: l10n.moreActions,
            icon: Icon(LucideIcons.ellipsisVertical, color: scheme.onSurfaceVariant),
            onSelected: action,
            itemBuilder: (_) => [
              if (desktop && !isPersonalComputer(c))
                PopupMenuItem(
                  value: 'live',
                  child: ListTile(dense: true, leading: const Icon(LucideIcons.monitorPlay), title: Text(l10n.liveView)),
                ),
              if (!isPersonalComputer(c))
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  dense: true,
                  leading: Icon(desktop ? LucideIcons.squareTerminal : LucideIcons.monitor),
                  title: Text(desktop ? l10n.switchToHeadless : l10n.switchToDesktop),
                ),
              ),
              if (c.kind == ComputerKindEnum.team)
                PopupMenuItem(
                  value: 'desktops',
                  child: ListTile(dense: true, leading: const Icon(LucideIcons.users), title: Text(l10n.desktopUsers), subtitle: Text(l10n.desktopUsersCount(c.maxDesktops))),
                ),
              PopupMenuItem(
                value: 'rename',
                child: ListTile(dense: true, leading: const Icon(LucideIcons.pencil), title: Text(l10n.rename)),
              ),
              if (c.kind != ComputerKindEnum.team)
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    leading: Icon(LucideIcons.trash2, color: scheme.error),
                    title: Text(l10n.delete, style: TextStyle(color: scheme.error)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class NewComputerSheet extends ConsumerStatefulWidget {
  const NewComputerSheet({super.key});

  @override
  ConsumerState<NewComputerSheet> createState() => _NewComputerSheetState();
}

class _NewComputerSheetState extends ConsumerState<NewComputerSheet> {
  final _name = TextEditingController();
  String? _botId;
  var _desktop = false;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    final org = ref.read(currentOrgProvider)!;
    final c = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .createComputer(org.id, name: _name.text.trim(), private: true, ownerBotId: _botId, profile: _desktop ? 'desktop' : 'headless'),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (c != null) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    _botId ??= bots.isEmpty ? null : bots.first.id;
    return FormSheet(
      icon: LucideIcons.monitorUp,
      title: l10n.newComputer,
      subtitle: l10n.newComputerHelp,
      submitLabel: l10n.create,
      submitKey: const Key('createComputer'),
      busy: _busy,
      onSubmit: _botId == null || _name.text.trim().isEmpty ? null : _create,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: const Key('computerBot'),
          initialValue: _botId,
          decoration: InputDecoration(labelText: l10n.forBot, prefixIcon: const Icon(LucideIcons.bot, size: 20)),
          items: [for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name))],
          onChanged: hapticOnChanged((v) => setState(() => _botId = v), haptic: HapticsHelper.selection),
        ),
        TextField(
          key: const Key('computerName'),
          controller: _name,
          decoration: InputDecoration(labelText: l10n.computerName, prefixIcon: const Icon(LucideIcons.idCard, size: 20)),
          onChanged: (_) => setState(() {}),
        ),
        FormSwitch(
          key: const Key('computerDesktop'),
          icon: LucideIcons.monitor,
          title: l10n.withDesktop,
          subtitle: l10n.withDesktopHelp,
          value: _desktop,
          onChanged: (v) => setState(() => _desktop = v),
        ),
      ],
    );
  }
}
