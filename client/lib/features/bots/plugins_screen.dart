import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/revealable.dart';

/// A bot's plugins (D-121): Agent Plugins 1.0 packages from GitHub, with what each one added.
final pluginsProvider = FutureProvider.autoDispose.family<List<Plugin>, String>((ref, botId) => ref.watch(backendProvider).plugins(botId));

class PluginsScreen extends ConsumerWidget {
  const PluginsScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    Future<void> add() async {
      final org = ref.read(currentOrgProvider);
      if (org == null) return;
      await showAdaptiveSheet<void>(
        context: context,
        builder: (_) => _AddPlugin(orgId: org.id, botId: botId),
      );
      ref.invalidate(pluginsProvider(botId));
    }

    return SubPage(
      title: l10n.plugins,
      subtitle: ref.watch(botProvider(botId))?.name,
      actions: [IconButton(key: const Key('addPlugin'), tooltip: l10n.addPlugin, icon: const Icon(LucideIcons.plus), onPressed: add)],
      body: AsyncView(
        value: ref.watch(pluginsProvider(botId)),
        onRetry: () => ref.invalidate(pluginsProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.puzzle,
                title: l10n.noPlugins,
                message: l10n.pluginsHelp,
                action: FilledButton(onPressed: add, child: Text(l10n.addPlugin)),
              )
            : PageColumn(
                children: [
                  FormNote(l10n.pluginsHelp),
                  const SizedBox(height: AppSpace.md),
                  for (final p in items) ...[_PluginCard(plugin: p, botId: botId), const SizedBox(height: AppSpace.md)],
                ],
              ),
      ),
    );
  }
}

class _PluginCard extends ConsumerWidget {
  const _PluginCard({required this.plugin, required this.botId});
  final Plugin plugin;
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = plugin;
    final backend = ref.read(backendProvider);
    Future<void> update() async {
      final u = await runGuarded(context, () => backend.pluginUpdate(p.id));
      if (u == null || !context.mounted) return;
      if (u.upToDate) return showMessage(context, l10n.pluginUpToDate);
      await showAdaptiveSheet<void>(
        context: context,
        builder: (_) => _UpdatePlugin(plugin: p, update: u),
      );
      ref.invalidate(pluginsProvider(botId));
    }

    Future<void> uninstall() async {
      final ok = await showConfirm(
        context: context,
        title: l10n.uninstallPluginTitle(p.name),
        message: l10n.uninstallPluginBody,
        confirmLabel: l10n.uninstall,
        destructive: true,
        confirmKey: const Key('confirmUninstall'),
      );
      if (!ok || !context.mounted) return;
      await runGuarded(context, () => backend.uninstallPlugin(p.id));
      ref.invalidate(pluginsProvider(botId));
    }

    return GroupedCard(
      key: Key('plugin-${p.id}'),
      children: [
        GroupedTile(
          icon: LucideIcons.puzzle,
          title: '${p.name}${p.version.isUsable ? ' ${p.version}' : ''}',
          subtitle: '${p.repo}${p.path.isEmpty ? '' : '/${p.path}'} @ ${p.commit.substring(0, 7)}',
          trailing: PopupMenuButton<String>(
            key: Key('pluginMenu-${p.id}'),
            icon: const Icon(LucideIcons.ellipsis, size: 18),
            onSelected: (v) => v == 'update' ? update() : uninstall(),
            itemBuilder: (_) => [PopupMenuItem(value: 'update', child: Text(l10n.checkForUpdate)), PopupMenuItem(value: 'uninstall', child: Text(l10n.uninstall))],
          ),
        ),
        for (final s in p.skills) GroupedTile(icon: LucideIcons.bookOpen, title: s.name, subtitle: l10n.pluginSkill),
        for (final s in p.servers)
          GroupedTile(
            key: Key('pluginServer-${s.key}'),
            icon: s.type == InstalledPluginServerTypeEnum.stdio ? LucideIcons.cpu : LucideIcons.globe,
            title: s.key,
            subtitle: s.status == InstalledPluginServerStatusEnum.error
                ? s.error.orPlaceholder(l10n.pluginServerError)
                : s.tools.isEmpty
                ? (s.type == InstalledPluginServerTypeEnum.stdio ? l10n.pluginRunsOnComputer : s.url.orPlaceholder())
                : s.tools.map((t) => '${t.name} (${riskLabel(context, t.risk.name)})').join(', '),
          ),
        if (p.hosts.isNotEmpty) GroupedTile(icon: LucideIcons.network, title: l10n.pluginHosts, subtitle: p.hosts.join(', ')),
      ],
    );
  }
}

String riskLabel(BuildContext context, String risk) => switch (risk) {
  'low' => context.l10n.riskLow,
  'high' => context.l10n.riskHigh,
  _ => context.l10n.riskMedium,
};

/// What a package would add, before anything is installed.
class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.preview});
  final PluginPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = preview;
    final style = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${p.name}${p.version.isUsable ? ' ${p.version}' : ''}', style: style.titleMedium),
        if (p.description.isNotEmpty) Text(p.description),
        Text('${p.repo} @ ${p.commit.substring(0, 7)}', style: style.bodySmall),
        const SizedBox(height: AppSpace.sm),
        Text(l10n.pluginAdds, style: style.labelLarge),
        for (final s in p.skills) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(LucideIcons.bookOpen, size: 18), title: Text(s.name), subtitle: Text(s.description)),
        for (final s in p.servers)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(s.type == PluginServerInfoTypeEnum.stdio ? LucideIcons.cpu : LucideIcons.globe, size: 18),
            title: Text(s.key),
            subtitle: Text(s.type == PluginServerInfoTypeEnum.stdio ? l10n.pluginStdio([s.command.orPlaceholder(), ...s.args].join(' ')) : l10n.pluginRemote(s.url.orPlaceholder())),
          ),
        if (p.hosts.isNotEmpty) Text(l10n.pluginTalksTo(p.hosts.join(', ')), style: style.bodySmall),
        for (final w in p.warnings) Text(w, style: style.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
      ],
    );
  }
}

class _AddPlugin extends ConsumerStatefulWidget {
  const _AddPlugin({required this.orgId, required this.botId});
  final String orgId;
  final String botId;

  @override
  ConsumerState<_AddPlugin> createState() => _AddPluginState();
}

class _AddPluginState extends ConsumerState<_AddPlugin> {
  final _url = TextEditingController();
  final _secrets = <String, TextEditingController>{};
  PluginPreview? _preview;
  var _busy = false;

  @override
  void dispose() {
    _url.dispose();
    for (final c in _secrets.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final backend = ref.read(backendProvider);
    setState(() => _busy = true);
    if (_preview == null) {
      final p = await runGuarded(context, () => backend.previewPlugin(widget.orgId, _url.text.trim()));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _preview = p;
        for (final s in p?.secrets ?? const <PluginSecretInfo>[]) {
          _secrets[s.name] = TextEditingController();
        }
      });
      return;
    }
    final p = _preview!;
    final done = await runGuarded(context, () => backend.installPlugin(widget.orgId, widget.botId, _url.text.trim(), p.commit, {for (final e in _secrets.entries) e.key: e.value.text}));
    if (!mounted) return;
    setState(() => _busy = false);
    if (done != null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = _preview;
    final ready = p == null ? _url.text.trim().isNotEmpty : _secrets.values.every((c) => c.text.trim().isNotEmpty);
    return FormSheet(
      icon: LucideIcons.puzzle,
      title: l10n.addPlugin,
      subtitle: l10n.addPluginHelp,
      submitLabel: p == null ? l10n.preview : l10n.install,
      submitKey: const Key('pluginSubmit'),
      onSubmit: !ready || _busy ? null : _submit,
      children: [
        TextField(
          key: const Key('pluginUrl'),
          controller: _url,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (ready && !_busy) _submit();
          },
          enabled: p == null,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'GitHub', hintText: 'https://github.com/owner/repo/tree/main/plugin'),
        ),
        if (p != null) ...[
          _PreviewList(preview: p),
          for (final s in p.secrets)
            Revealable(builder: (context, hidden, toggle) => TextField(
              key: Key('pluginSecret-${s.name}'),
              controller: _secrets[s.name],
              textInputAction: s == p.secrets.last ? TextInputAction.done : TextInputAction.next,
              onSubmitted: s == p.secrets.last
                  ? (_) {
                      if (ready && !_busy) _submit();
                    }
                  : null,
              obscureText: hidden,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: s.name, helperText: s.description.isEmpty ? null : s.description, suffixIcon: toggle),
            )),
        ],
      ],
    );
  }
}

class _UpdatePlugin extends ConsumerStatefulWidget {
  const _UpdatePlugin({required this.plugin, required this.update});
  final Plugin plugin;
  final PluginUpdatePreview update;

  @override
  ConsumerState<_UpdatePlugin> createState() => _UpdatePluginState();
}

class _UpdatePluginState extends ConsumerState<_UpdatePlugin> {
  final _secrets = <String, TextEditingController>{};
  var _busy = false;

  @override
  void initState() {
    super.initState();
    for (final n in widget.update.secretsAdded) {
      _secrets[n] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _secrets.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = widget.update;
    String list(List<String> xs) => xs.join(', ');
    final lines = [
      if (u.skillsAdded.isNotEmpty) l10n.pluginDiffSkillsAdded(list(u.skillsAdded)),
      if (u.skillsChanged.isNotEmpty) l10n.pluginDiffSkillsChanged(list(u.skillsChanged)),
      if (u.skillsRemoved.isNotEmpty) l10n.pluginDiffSkillsRemoved(list(u.skillsRemoved)),
      if (u.serversAdded.isNotEmpty) l10n.pluginDiffServersAdded(list(u.serversAdded)),
      if (u.serversChanged.isNotEmpty) l10n.pluginDiffServersChanged(list(u.serversChanged)),
      if (u.serversRemoved.isNotEmpty) l10n.pluginDiffServersRemoved(list(u.serversRemoved)),
      if (u.hostsAdded.isNotEmpty) l10n.pluginDiffHosts(list(u.hostsAdded)),
    ];
    VoidCallback? submit;
    return FormSheet(
      icon: LucideIcons.refreshCw,
      title: l10n.updatePluginTitle(widget.plugin.name),
      subtitle: '${u.fromVersion ?? u.fromCommit.substring(0, 7)} → ${u.toVersion ?? u.toCommit.substring(0, 7)}',
      submitLabel: l10n.update,
      submitKey: const Key('pluginUpdate'),
      // Also run by the keyboard's Done key on the last field.
      onSubmit: submit = _busy || _secrets.values.any((c) => c.text.trim().isEmpty)
          ? null
          : () async {
              setState(() => _busy = true);
              final r = await runGuarded(context, () => ref.read(backendProvider).updatePlugin(widget.plugin.id, u.toCommit, secrets: {for (final e in _secrets.entries) e.key: e.value.text}));
              if (!mounted) return;
              setState(() => _busy = false);
              if (!context.mounted) return;
              if (r != null) Navigator.pop(context);
            },
      children: [
        for (final l in lines.isEmpty ? [l10n.pluginDiffNone] : lines) Text(l),
        for (final e in _secrets.entries)
          Revealable(builder: (context, hidden, toggle) => TextField(
            key: Key('pluginSecret-${e.key}'),
            controller: e.value,
            textInputAction: e.key == _secrets.keys.last ? TextInputAction.done : TextInputAction.next,
            onSubmitted: e.key == _secrets.keys.last ? (_) => submit?.call() : null,
            obscureText: hidden,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: e.key, suffixIcon: toggle),
          )),
      ],
    );
  }
}
