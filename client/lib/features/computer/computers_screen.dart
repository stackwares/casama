import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Team and private computers: create, rename, switch between headless and desktop, delete.
class ComputersScreen extends ConsumerWidget {
  const ComputersScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const NewComputerSheet(),
    );
    if (created == true) ref.invalidate(computersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    String owner(Computer c) {
      if (c.kind == ComputerKindEnum.team) return l10n.teamComputer;
      for (final b in bots) {
        if (b.id == c.ownerBotId) return l10n.privateComputerOf(b.name);
      }
      return l10n.privateComputer;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.computers)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newComputer'),
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.newComputer),
      ),
      body: AsyncView(
        value: ref.watch(computersProvider),
        onRetry: () => ref.invalidate(computersProvider),
        data: (items) => ListView(children: [
          for (final c in items)
            ListTile(
              key: Key('computer-${c.id}'),
              leading: Icon(c.profile == ComputerProfileEnum.desktop ? Icons.desktop_windows_outlined : Icons.terminal),
              title: Text(c.name),
              subtitle: Text([
                owner(c),
                c.profile == ComputerProfileEnum.desktop ? l10n.profileDesktop : l10n.profileHeadless,
                c.provider,
                c.state.value,
              ].join(' · ')),
              trailing: PopupMenuButton<String>(
                key: Key('computerMenu-${c.id}'),
                onSelected: (v) async {
                  final backend = ref.read(backendProvider);
                  switch (v) {
                    case 'live':
                      context.push('/computer/live?c=${c.id}');
                      return;
                    case 'profile':
                      await runGuarded(
                        context,
                        () => backend.updateComputer(
                          c.id,
                          profile: c.profile == ComputerProfileEnum.desktop ? 'headless' : 'desktop',
                        ),
                      );
                    case 'rename':
                      final name = await _ask(context, l10n.rename, c.name);
                      if (name == null || name.isEmpty) return;
                      if (!context.mounted) return;
                      await runGuarded(context, () => backend.updateComputer(c.id, name: name));
                    case 'delete':
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (d) => AlertDialog(
                          content: Text(l10n.deleteComputerConfirm(c.name)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l10n.cancel)),
                            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l10n.delete)),
                          ],
                        ),
                      );
                      if (ok != true || !context.mounted) return;
                      await runGuarded(context, () => backend.deleteComputer(c.id));
                  }
                  ref.invalidate(computersProvider);
                },
                itemBuilder: (_) => [
                  if (c.profile == ComputerProfileEnum.desktop) PopupMenuItem(value: 'live', child: Text(l10n.liveView)),
                  PopupMenuItem(
                    value: 'profile',
                    child: Text(c.profile == ComputerProfileEnum.desktop ? l10n.switchToHeadless : l10n.switchToDesktop),
                  ),
                  PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              ),
            ),
        ]),
      ),
    );
  }
}

Future<String?> _ask(BuildContext context, String title, String initial) async {
  final controller = TextEditingController(text: initial);
  final value = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: Text(context.l10n.save)),
      ],
    ),
  );
  controller.dispose();
  return value;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    _botId ??= bots.isEmpty ? null : bots.first.id;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.newComputer, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(l10n.newComputerHelp, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('computerBot'),
          initialValue: _botId,
          decoration: InputDecoration(labelText: l10n.forBot),
          items: [for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name))],
          onChanged: (v) => setState(() => _botId = v),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('computerName'),
          controller: _name,
          decoration: InputDecoration(labelText: l10n.computerName),
          onChanged: (_) => setState(() {}),
        ),
        SwitchListTile(
          key: const Key('computerDesktop'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.withDesktop),
          subtitle: Text(l10n.withDesktopHelp),
          value: _desktop,
          onChanged: (v) => setState(() => _desktop = v),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('createComputer'),
          onPressed: _busy || _botId == null || _name.text.trim().isEmpty
              ? null
              : () async {
                  setState(() => _busy = true);
                  final org = ref.read(currentOrgProvider)!;
                  final c = await runGuarded(
                    context,
                    () => ref.read(backendProvider).createComputer(
                          org.id,
                          name: _name.text.trim(),
                          private: true,
                          ownerBotId: _botId,
                          profile: _desktop ? 'desktop' : 'headless',
                        ),
                  );
                  if (!context.mounted) return;
                  setState(() => _busy = false);
                  if (c != null) Navigator.of(context).pop(true);
                },
          child: Text(l10n.create),
        ),
      ]),
    );
  }
}
