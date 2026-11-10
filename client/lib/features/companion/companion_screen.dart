import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'companion.dart';
import 'companion_controller.dart';
import '../../ui/glow_button.dart';

/// Settings > Use this computer for bots (desktop only, D-066).
class CompanionScreen extends ConsumerWidget {
  const CompanionScreen({super.key});

  static const capabilityKeys = ['shell', 'files', 'browser', 'desktop', 'mcp'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final companion = ref.watch(companionProvider);
    final controller = ref.read(companionControllerProvider.notifier);
    final value = ref.watch(companionControllerProvider);
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    String capLabel(String c) => switch (c) {
      'shell' => l10n.capShell,
      'files' => l10n.capFiles,
      'browser' => l10n.capBrowser,
      'mcp' => l10n.capMcp,
      'messages' => l10n.capMessages,
      _ => l10n.capDesktop,
    };
    return SubPage(
      title: l10n.useThisComputer,
      body: !companion.supported
          ? EmptyState(icon: LucideIcons.monitorOff, title: l10n.useThisComputer, message: l10n.companionDesktopOnly)
          : AsyncView(
              value: value,
              onRetry: () => ref.invalidate(companionControllerProvider),
              data: (device) {
                if (device == null) {
                  return EmptyState(
                    icon: LucideIcons.laptop,
                    title: l10n.useThisComputer,
                    message: l10n.companionIntro,
                    action: GlowButton.icon(
                      key: const Key('pairComputer'),
                      onPressed: () => runGuarded(context, () => controller.pair(l10n.thisComputer)),
                      icon: const Icon(LucideIcons.link, size: 18),
                      label: Text(l10n.useThisComputer),
                    ),
                  );
                }
                final caps = capsOf(device);
                final scheme = context.colorScheme;
                return ValueListenableBuilder(
                  valueListenable: companion.status,
                  builder: (context, status, _) {
                    final (statusText, statusColor) = switch (status) {
                      CompanionStatus.online => (l10n.companionOnline, context.appColors.working),
                      CompanionStatus.connecting => (l10n.connectingLive, context.appColors.waiting),
                      CompanionStatus.error => (l10n.companionError, context.appColors.negative),
                      CompanionStatus.off => (l10n.companionOff, scheme.onSurfaceVariant),
                    };
                    return PageColumn(
                      children: [
                        AppCard(
                          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.sm, AppSpace.md),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                                alignment: Alignment.center,
                                child: Icon(LucideIcons.laptop, color: statusColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.useThisComputer, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    StatusLabel(key: const Key('companionStatus'), text: statusText, color: statusColor, pill: true),
                                  ],
                                ),
                              ),
                              Switch(
                                key: const Key('companionEnabled'),
                                value: device.enabled,
                                onChanged: (v) => runGuarded(context, () => controller.save(enabled: v)),
                              ),
                            ],
                          ),
                        ),
                        SectionHeader(title: l10n.companionCapabilities),
                        GroupedCard(
                          children: [
                            // Messages (iMessage chat apps, D-134) only exists on a Mac.
                            for (final c in [...capabilityKeys, if (defaultTargetPlatform == TargetPlatform.macOS) 'messages'])
                              GroupedTile(
                                key: Key('cap-$c'),
                                icon: switch (c) {
                                  'shell' => LucideIcons.squareTerminal,
                                  'files' => LucideIcons.folder,
                                  'browser' => LucideIcons.globe,
                                  'mcp' => LucideIcons.plug,
                                  'messages' => LucideIcons.messageCircle,
                                  _ => LucideIcons.mousePointer2,
                                },
                                title: capLabel(c),
                                onTap: () => runGuarded(context, () => controller.save(capabilities: caps.contains(c) ? ({...caps}..remove(c)) : {...caps, c})),
                                trailing: Switch(
                                  value: caps.contains(c),
                                  onChanged: (v) => runGuarded(context, () => controller.save(capabilities: v ? {...caps, c} : ({...caps}..remove(c)))),
                                ),
                              ),
                          ],
                        ),
                        Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: FormNote(l10n.companionCapabilitiesHelp)),
                        SectionHeader(
                          title: l10n.sharedFolders,
                          trailing: TextButton.icon(
                            key: const Key('addFolder'),
                            onPressed: () async {
                              final dir = await FilePicker.getDirectoryPath();
                              if (dir == null || !context.mounted) return;
                              await runGuarded(context, () => controller.save(roots: {...device.allowedRoots, dir}.toList()));
                            },
                            icon: const Icon(LucideIcons.folderPlus, size: 18),
                            label: Text(l10n.addFolder),
                          ),
                        ),
                        if (device.allowedRoots.isEmpty)
                          AppCard(child: FormNote(l10n.sharedFoldersHelp, icon: LucideIcons.folderX))
                        else
                          GroupedCard(
                            children: [
                              for (final r in device.allowedRoots)
                                GroupedTile(
                                  icon: LucideIcons.folder,
                                  title: r.split('/').where((p) => p.isNotEmpty).lastOrNull ?? r,
                                  subtitle: r,
                                  trailing: IconButton(
                                    tooltip: l10n.delete,
                                    icon: Icon(LucideIcons.x, color: scheme.onSurfaceVariant),
                                    onPressed: () => runGuarded(context, () => controller.save(roots: device.allowedRoots.where((x) => x != r).toList())),
                                  ),
                                ),
                            ],
                          ),
                        _CodingAgentsSection(
                          shellOn: caps.contains('shell'),
                          onAllow: () => runGuarded(context, () => controller.save(capabilities: {...caps, 'shell'})),
                        ),
                        _LocalMcpSection(device: device, enabled: caps.contains('mcp')),
                        SectionHeader(title: l10n.botsAllowed),
                        GroupedCard(
                          children: [
                            for (final b in bots)
                              CheckboxListTile(
                                key: Key('allowBot-${b.id}'),
                                secondary: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 32),
                                title: Text(b.name, style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                value: device.allowedBotIds.contains(b.id),
                                onChanged: (v) async {
                                  final ids = v == true ? {...device.allowedBotIds, b.id} : ({...device.allowedBotIds}..remove(b.id));
                                  await runGuarded(context, () async {
                                    await controller.save(botIds: ids.toList());
                                    // An allowed bot uses this computer; a removed one goes back to its default.
                                    await ref.read(backendProvider).setBotComputer(b.id, v == true ? device.computerId : null);
                                  });
                                  ref.invalidate(botsProvider);
                                },
                              ),
                          ],
                        ),
                        Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: FormNote(l10n.botsAllowedHelp)),
                        const SizedBox(height: AppSpace.lg),
                        GroupedCard(
                          children: [GroupedTile(icon: LucideIcons.unlink, destructive: true, title: l10n.unpairComputer, onTap: () => runGuarded(context, controller.unpair))],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

/// Splits a command line into words, keeping "quoted parts" together.
List<String> splitCommand(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  String? quote;
  var any = false;
  for (final ch in line.trim().split('')) {
    if (quote != null) {
      if (ch == quote) {
        quote = null;
      } else {
        buf.write(ch);
      }
    } else if (ch == '"' || ch == "'") {
      quote = ch;
      any = true;
    } else if (ch == ' ' || ch == '\t') {
      if (buf.isNotEmpty || any) out.add(buf.toString());
      buf.clear();
      any = false;
    } else {
      buf.write(ch);
    }
  }
  if (buf.isNotEmpty || any) out.add(buf.toString());
  return out;
}

/// Local MCP servers on this computer (D-096).
class _LocalMcpSection extends ConsumerWidget {
  const _LocalMcpSection({required this.device, required this.enabled});
  final LocalDevice device;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final servers = ref.watch(localMcpServersProvider).value ?? const <LocalMcpConfig>[];
    final controller = ref.read(companionControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.localMcpServers,
          trailing: TextButton.icon(
            key: const Key('addLocalMcp'),
            onPressed: () async {
              final added = await showAdaptiveSheet<LocalMcpConfig>(
                context: context,
                builder: (_) => _LocalMcpForm(device: device, taken: {for (final s in servers) s.key}),
              );
              if (added == null || !context.mounted) return;
              await runGuarded(context, () => controller.saveMcpServers([...servers, added]));
            },
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(l10n.localMcpAdd),
          ),
        ),
        if (servers.isEmpty)
          AppCard(child: FormNote(l10n.localMcpEmpty, icon: LucideIcons.plug))
        else
          GroupedCard(
            children: [
              for (final s in servers)
                GroupedTile(
                  key: Key('localMcp-${s.key}'),
                  icon: s.kind == 'loopback' ? LucideIcons.network : LucideIcons.squareTerminal,
                  title: s.label,
                  subtitle: s.summary,
                  trailing: IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => runGuarded(context, () => controller.saveMcpServers(servers.where((x) => x.key != s.key).toList())),
                  ),
                ),
            ],
          ),
        Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: FormNote(enabled ? l10n.localMcpHelp : l10n.localMcpNeedsCapability)),
      ],
    );
  }
}

class _LocalMcpForm extends StatefulWidget {
  const _LocalMcpForm({required this.device, required this.taken});
  final LocalDevice device;
  final Set<String> taken;

  @override
  State<_LocalMcpForm> createState() => _LocalMcpFormState();
}

class _LocalMcpFormState extends State<_LocalMcpForm> {
  final _label = TextEditingController();
  final _command = TextEditingController();
  final _url = TextEditingController();
  final _env = TextEditingController();
  var _kind = 'stdio';
  String? _cwd;
  String? _error;

  @override
  void dispose() {
    for (final c in [_label, _command, _url, _env]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final label = _label.text.trim();
    if (label.isEmpty) return;
    LocalMcpConfig? out;
    if (_kind == 'loopback') {
      final uri = Uri.tryParse(_url.text.trim());
      if (uri == null || uri.scheme != 'http' || !(uri.host == '127.0.0.1' || uri.host == '::1')) {
        setState(() => _error = l10n.localMcpBadUrl);
        return;
      }
      out = LocalMcpConfig(key: LocalMcpConfig.keyFor(label, widget.taken), label: label, kind: 'loopback', url: uri.toString());
    } else {
      final words = splitCommand(_command.text);
      if (words.isEmpty) return;
      final env = <String, String>{
        for (final line in _env.text.split('\n'))
          if (line.contains('=')) line.substring(0, line.indexOf('=')).trim(): line.substring(line.indexOf('=') + 1).trim(),
      }..removeWhere((k, _) => k.isEmpty);
      out = LocalMcpConfig(key: LocalMcpConfig.keyFor(label, widget.taken), label: label, kind: 'stdio', command: words.first, args: words.skip(1).toList(), cwd: _cwd, env: env);
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.plug,
      title: l10n.localMcpAdd,
      submitLabel: l10n.localMcpAdd,
      submitKey: const Key('saveLocalMcp'),
      onSubmit: _submit,
      children: [
        TextField(
          key: const Key('localMcpLabel'),
          controller: _label,
          decoration: InputDecoration(labelText: l10n.localMcpName),
        ),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'stdio', label: Text(l10n.localMcpStdio)),
            ButtonSegment(value: 'loopback', label: Text(l10n.localMcpLoopback)),
          ],
          selected: {_kind},
          onSelectionChanged: (v) => setState(() => _kind = v.first),
        ),
        if (_kind == 'loopback')
          TextField(
            key: const Key('localMcpUrl'),
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: l10n.localMcpUrl, hintText: 'http://127.0.0.1:3845/mcp'),
          )
        else ...[
          TextField(
            key: const Key('localMcpCommand'),
            controller: _command,
            autocorrect: false,
            decoration: InputDecoration(labelText: l10n.localMcpCommand, hintText: l10n.localMcpCommandHint),
          ),
          OutlinedButton.icon(
            icon: const Icon(LucideIcons.folder, size: 18),
            label: Text(_cwd ?? l10n.localMcpFolder),
            onPressed: () async {
              final dir = await FilePicker.getDirectoryPath();
              if (dir == null) return;
              final inside = widget.device.allowedRoots.any((r) => dir == r || dir.startsWith('$r/'));
              setState(() {
                _cwd = inside ? dir : null;
                _error = inside ? null : l10n.localMcpBadFolder;
              });
            },
          ),
          TextField(
            key: const Key('localMcpEnv'),
            controller: _env,
            minLines: 2,
            maxLines: 5,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: l10n.localMcpEnv),
          ),
        ],
        if (_error != null) FormNote(_error!, icon: LucideIcons.circleAlert, color: context.appColors.negative),
      ],
    );
  }
}

final _codingAgentsProvider = FutureProvider<List<String>>((ref) => ref.watch(companionProvider).detectCodingAgents());

/// Coding agents found on this computer (D-097).
class _CodingAgentsSection extends ConsumerWidget {
  const _CodingAgentsSection({required this.shellOn, required this.onAllow});
  final bool shellOn;
  final VoidCallback onAllow;

  static const _labels = {'claude': 'Claude Code', 'codex': 'Codex', 'cursor-agent': 'Cursor'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final found = ref.watch(_codingAgentsProvider).value ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.codingAgents),
        if (found.isEmpty)
          AppCard(child: FormNote(l10n.codingAgentsNone, icon: LucideIcons.codeXml))
        else
          GroupedCard(
            children: [for (final a in found) GroupedTile(key: Key('codingAgent-$a'), icon: LucideIcons.codeXml, title: _labels[a] ?? a, subtitle: a)],
          ),
        if (found.isNotEmpty && !shellOn)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                Expanded(child: FormNote(l10n.codingAgentsNeedShell)),
                TextButton(key: const Key('allowCodingAgents'), onPressed: onAllow, child: Text(l10n.allowCommands)),
              ],
            ),
          )
        else if (found.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: FormNote(l10n.codingAgentsHelp)),
      ],
    );
  }
}
