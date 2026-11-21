import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:casama_computerd/mcp_address.dart';
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
import 'coding_agents_section.dart';
import 'companion.dart';
import 'companion_controller.dart';
import '../../ui/glow_button.dart';
import '../../ui/painted_cover.dart';

/// Settings > Use this computer for bots (desktop only, D-066).
class CompanionScreen extends ConsumerWidget {
  const CompanionScreen({super.key});

  static const capabilityKeys = ['shell', 'files', 'browser', 'desktop', 'mcp'];

  /// Shown under Advanced, with coding agents and local MCP servers (D-182).
  static const expertCapabilityKeys = ['shell', 'mcp'];

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
              loading: _CompanionSkeleton(
                capabilities: [
                  ...capabilityKeys,
                  if (defaultTargetPlatform == TargetPlatform.macOS) 'messages',
                ].where((c) => !expertCapabilityKeys.contains(c)).length,
              ),
              data: (device) {
                if (device == null) {
                  return EmptyState(
                    illustration: const PaintedHero(name: 'computer-waking', size: 132, icon: LucideIcons.laptop),
                    title: l10n.useThisComputer,
                    message: l10n.companionIntro,
                    action: GlowButton.icon(
                      key: const Key('pairComputer'),
                      onPressed: () => runGuarded(context, () => controller.pair(localComputerName() ?? l10n.thisComputer)),
                      icon: const Icon(LucideIcons.link, size: 18),
                      label: Text(l10n.useThisComputer),
                    ),
                  );
                }
                final caps = capsOf(device);
                final scheme = context.colorScheme;
                Widget capTile(String c) => GroupedTile(
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
                    onChanged: hapticOnChanged((v) => runGuarded(context, () => controller.save(capabilities: v ? {...caps, c} : ({...caps}..remove(c))))),
                  ),
                );
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
                                onChanged: hapticOnChanged((v) => runGuarded(context, () => controller.save(enabled: v))),
                              ),
                            ],
                          ),
                        ),
                        SectionHeader(title: l10n.companionCapabilities),
                        GroupedCard(
                          children: [
                            // Messages (iMessage chat apps, D-134) only exists on a Mac.
                            for (final c in [...capabilityKeys, if (defaultTargetPlatform == TargetPlatform.macOS) 'messages'])
                              if (!expertCapabilityKeys.contains(c)) capTile(c),
                          ],
                        ),
                        Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: FormNote(l10n.companionCapabilitiesHelp)),
                        SectionHeader(
                          title: l10n.sharedFolders,
                          trailing: TextButton.icon(
                            key: const Key('addFolder'),
                            onPressed: () async {
                              // This needs a file path for dart:io, not the Uri pickDirectory() gives.
                              // ignore: deprecated_member_use
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
                        SectionHeader(title: l10n.botsAllowed),
                        GroupedCard(
                          children: [
                            for (final b in bots)
                              SwitchListTile(
                                key: Key('allowBot-${b.id}'),
                                // The title says the name; the avatar's image label made screen readers call the row an image, not something to toggle.
                                secondary: ExcludeSemantics(child: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 32)),
                                title: Text(b.name, style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                value: device.allowedBotIds.contains(b.id),
                                onChanged: hapticOnChanged((v) async {
                                  final ids = v == true ? {...device.allowedBotIds, b.id} : ({...device.allowedBotIds}..remove(b.id));
                                  await runGuarded(context, () async {
                                    await controller.save(botIds: ids.toList());
                                    // An allowed bot uses this computer; a removed one goes back to its default.
                                    await ref.read(backendProvider).setBotComputer(b.id, v == true ? device.computerId : null);
                                  });
                                  ref.invalidate(botsProvider);
                                }, haptic: HapticsHelper.soft),
                              ),
                          ],
                        ),
                        Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: FormNote(l10n.botsAllowedHelp)),
                        // Commands, local MCP servers and coding agents: for people who code (D-182).
                        AdvancedSection(
                          id: 'companion',
                          summary: l10n.companionAdvancedSummary,
                          children: [
                            GroupedCard(children: [for (final c in expertCapabilityKeys) capTile(c)]),
                            CodingAgentsSection(
                              device: device,
                              shellOn: caps.contains('shell'),
                              onAllow: () => runGuarded(context, () => controller.save(capabilities: {...caps, 'shell'})),
                            ),
                            _LocalMcpSection(device: device, enabled: caps.contains('mcp')),
                          ],
                        ),
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


/// Local MCP servers on this computer (D-096).
/// The companion page still loading: the status card with its switch, then the capabilities
/// card of switch rows and its note.
class _CompanionSkeleton extends StatelessWidget {
  const _CompanionSkeleton({required this.capabilities});
  final int capabilities;

  static const _titles = [0.34, 0.26, 0.42, 0.3];

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final pill = text.labelMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.15);
    const switchBone = SizedBox(
      height: 48,
      child: Center(child: SkeletonBone(width: 52, height: 32, radius: AppRadius.pill)),
    );
    return SkeletonPage(
      children: [
        SkeletonCard(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.sm, AppSpace.md),
          child: Row(
            children: [
              const SkeletonBone(width: 48, height: 48, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700), widthFactor: 0.5),
                    const SizedBox(height: 4),
                    // The status pill: its text line plus 4 points above and below.
                    SizedBox(
                      width: 64,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: SkeletonText(style: pill, width: 0),
                          ),
                          const Positioned.fill(
                            child: SkeletonBone(height: double.infinity, radius: AppRadius.pill),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              switchBone,
            ],
          ),
        ),
        const SkeletonSectionHeader(width: 112),
        SkeletonGroupedCard(
          rows: [
            for (var i = 0; i < capabilities; i++)
              Row(
                children: [
                  Expanded(
                    child: SkeletonRow(
                      trailing: SkeletonTrailing.none,
                      subtitle: false,
                      titleWidth: _titles[i % _titles.length],
                      padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.md, 12, 0, 12),
                    ),
                  ),
                  // The Switch keeps a 48-point tap target.
                  const Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(AppSpace.xs, 12, AppSpace.md, 12),
                    child: switchBone,
                  ),
                ],
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: SkeletonBone(width: 16, height: 16, radius: 8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SkeletonText(style: text.bodySmall?.copyWith(height: 1.35), widthFactor: 0.8, lines: 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A bot offered a server that runs on the person's own computer (D-473): opens the add form with
/// its name and command filled in, for the person to check and save. False when this device can't
/// run one, or isn't set up to (the caller then says where to add it).
Future<bool> addOfferedLocalServer(
  BuildContext context,
  WidgetRef ref, {
  required String label,
  required String command,
  List<String> args = const [],
}) async {
  if (!ref.read(companionProvider).supported) return false;
  final device = await ref.read(companionControllerProvider.future).catchError((_) => null);
  if (device == null || !capsOf(device).contains('mcp') || !context.mounted) return false;
  final servers = await ref.read(localMcpServersProvider.future).catchError((_) => const <LocalMcpConfig>[]);
  if (!context.mounted) return false;
  final added = await showAdaptiveSheet<LocalMcpConfig>(
    context: context,
    builder: (_) => _LocalMcpForm(
      device: device,
      taken: {for (final s in servers) s.key},
      prefill: LocalMcpConfig(key: '', label: label, kind: 'stdio', command: command, args: args),
    ),
  );
  if (added == null || !context.mounted) return true;
  await runGuarded(context, () => ref.read(companionControllerProvider.notifier).saveMcpServers([...servers, added]));
  return true;
}

class _LocalMcpSection extends ConsumerStatefulWidget {
  const _LocalMcpSection({required this.device, required this.enabled});
  final LocalDevice device;
  final bool enabled;

  @override
  ConsumerState<_LocalMcpSection> createState() => _LocalMcpSectionState();
}

class _LocalMcpSectionState extends ConsumerState<_LocalMcpSection> {
  /// The server being tested or signed in to, if any.
  String? _testing;
  String? _signingIn;

  Future<void> _test(LocalMcpConfig s) async {
    final l10n = context.l10n;
    setState(() => _testing = s.key);
    final r = await runGuarded(context, () async => (await ref.read(companionControllerProvider.notifier).testMcpServer(s.key)) ?? IntegrationTestResult(ok: false, tools: const [], error: l10n.localMcpNotSaved));
    if (!mounted) return;
    setState(() => _testing = null);
    if (r == null) return;
    if (r.ok) {
      showSuccess(context, l10n.integrationOk(r.tools.length));
    } else {
      showFailure(context, l10n.integrationFailed(r.error.orPlaceholder()));
    }
  }

  /// Signs in with the browser (D-363), then checks the server the way a bot reaches it.
  Future<void> _signIn(LocalMcpConfig s) async {
    final l10n = context.l10n;
    setState(() => _signingIn = s.key);
    final ok = await runGuarded(context, () async {
      await ref.read(companionControllerProvider.notifier).signInMcpServer(s.key);
      return true;
    });
    if (!mounted) return;
    setState(() => _signingIn = null);
    if (ok == true) showSuccess(context, l10n.localMcpSignedIn(s.label));
  }

  Future<void> _edit(List<LocalMcpConfig> servers, LocalMcpConfig s) async {
    final controller = ref.read(companionControllerProvider.notifier);
    final edited = await showAdaptiveSheet<LocalMcpConfig>(
      context: context,
      builder: (_) => _LocalMcpForm(device: device, taken: {for (final x in servers) if (x.key != s.key) x.key}, initial: s),
    );
    if (edited == null || !mounted) return;
    await runGuarded(context, () => controller.saveMcpServers([for (final x in servers) x.key == s.key ? edited : x]));
    if (mounted && edited.needsSignIn) await _signIn(edited);
  }

  Future<void> _import(List<LocalMcpConfig> servers) async {
    final controller = ref.read(companionControllerProvider.notifier);
    final found = await runGuarded(context, () => ref.read(companionProvider).findMcpServers());
    if (found == null || !mounted) return;
    final picked = await showAdaptiveSheet<List<LocalMcpConfig>>(
      context: context,
      builder: (_) => _LocalMcpImportSheet(found: found, existing: servers),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    await runGuarded(context, () => controller.saveMcpServers([...servers, ...picked]));
    for (final s in picked.where((p) => p.needsSignIn)) {
      if (!mounted) return;
      await _signIn(s);
    }
  }

  LocalDevice get device => widget.device;
  bool get enabled => widget.enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final servers = ref.watch(localMcpServersProvider).value ?? const <LocalMcpConfig>[];
    final controller = ref.read(companionControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.localMcpServers,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // An icon only: two labelled buttons don't fit beside the header on a small phone.
              IconButton(
                key: const Key('importLocalMcp'),
                tooltip: l10n.localMcpImport,
                onPressed: () => _import(servers),
                icon: const Icon(LucideIcons.download, size: 18),
              ),
              TextButton.icon(
                key: const Key('addLocalMcp'),
                onPressed: () async {
                  final added = await showAdaptiveSheet<LocalMcpConfig>(
                    context: context,
                    builder: (_) => _LocalMcpForm(device: device, taken: {for (final s in servers) s.key}),
                  );
                  if (added == null || !context.mounted) return;
                  await runGuarded(context, () => controller.saveMcpServers([...servers, added]));
                  if (context.mounted && added.needsSignIn) await _signIn(added);
                },
                icon: const Icon(LucideIcons.plus, size: 18),
                // The header names what's added; the full label doesn't fit beside it on a small phone.
                label: Text(l10n.add),
              ),
            ],
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
                  icon: s.kind == 'loopback' ? (s.network ? LucideIcons.globe : LucideIcons.network) : LucideIcons.squareTerminal,
                  title: s.label,
                  subtitle: s.needsSignIn ? '${l10n.localMcpNeedsSignIn} · ${s.summary}' : s.summary,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (s.auth == 'oauth')
                        IconButton(
                          key: Key('signInLocalMcp-${s.key}'),
                          tooltip: l10n.localMcpSignIn,
                          icon: _signingIn == s.key
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(LucideIcons.logIn, color: s.needsSignIn ? context.appColors.warning : null),
                          onPressed: _signingIn == null ? () => _signIn(s) : null,
                        ),
                      IconButton(
                        key: Key('testLocalMcp-${s.key}'),
                        tooltip: l10n.testConnection,
                        icon: _testing == s.key
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(LucideIcons.activity),
                        onPressed: _testing == null ? () => _test(s) : null,
                      ),
                      IconButton(
                        key: Key('editLocalMcp-${s.key}'),
                        tooltip: l10n.edit,
                        icon: const Icon(LucideIcons.pencil),
                        onPressed: () => _edit(servers, s),
                      ),
                      IconButton(
                        tooltip: l10n.delete,
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => runGuarded(context, () => controller.saveMcpServers(servers.where((x) => x.key != s.key).toList())),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: FormNote(enabled ? l10n.localMcpHelp : l10n.localMcpNeedsCapability)),
      ],
    );
  }
}

/// Adds or edits a local MCP server: a command, or an address with how it signs in (D-363).
class _LocalMcpForm extends StatefulWidget {
  const _LocalMcpForm({required this.device, required this.taken, this.initial, this.prefill});
  final LocalDevice device;
  final Set<String> taken;

  /// The server being edited; null when adding one.
  final LocalMcpConfig? initial;

  /// A new server's fields to start from (one a bot offered, D-473); the person checks and saves.
  final LocalMcpConfig? prefill;

  @override
  State<_LocalMcpForm> createState() => _LocalMcpFormState();
}

class _LocalMcpFormState extends State<_LocalMcpForm> {
  final _label = TextEditingController();
  final _command = TextEditingController();
  final _url = TextEditingController();
  final _env = TextEditingController();
  final _token = TextEditingController();
  final _headerName = TextEditingController();
  final _headerValue = TextEditingController();
  var _kind = 'stdio';
  var _auth = 'none';
  String? _cwd;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? widget.prefill;
    if (i == null) return;
    _label.text = i.label;
    _kind = i.kind;
    _auth = i.auth;
    _cwd = i.cwd;
    _url.text = i.url ?? '';
    if (i.kind == 'stdio') _command.text = [i.command ?? '', for (final a in i.args) a.contains(' ') ? '"$a"' : a].join(' ').trim();
    _env.text = [for (final e in i.env.entries) '${e.key}=${e.value}'].join('\n');
    if (i.auth == 'token') {
      final v = i.headers.entries.where((e) => e.key.toLowerCase() == 'authorization').firstOrNull?.value ?? '';
      _token.text = v.toLowerCase().startsWith('bearer ') ? v.substring(7) : v;
    } else if (i.auth == 'header' && i.headers.isNotEmpty) {
      _headerName.text = i.headers.keys.first;
      _headerValue.text = i.headers.values.first;
    }
  }

  @override
  void dispose() {
    for (final c in [_label, _command, _url, _env, _token, _headerName, _headerValue]) {
      c.dispose();
    }
    super.dispose();
  }

  Uri? get _uri => Uri.tryParse(_url.text.trim());

  /// The address isn't on this computer, so it needs the person's network allowed (D-363).
  bool get _offComputer {
    final u = _uri;
    return u != null && u.host.isNotEmpty && localMcpAddressProblem(u) != null;
  }

  void _submit() {
    final l10n = context.l10n;
    final label = _label.text.trim();
    if (label.isEmpty) return;
    final key = widget.initial?.key ?? LocalMcpConfig.keyFor(label, widget.taken);
    LocalMcpConfig? out;
    if (_kind == 'loopback') {
      final uri = _uri;
      final network = _offComputer;
      if (localMcpAddressProblem(uri, network: network) != null) {
        setState(() => _error = l10n.localMcpBadUrl);
        return;
      }
      final headers = switch (_auth) {
        'token' when _token.text.trim().isNotEmpty => {'Authorization': 'Bearer ${_token.text.trim()}'},
        'header' when _headerName.text.trim().isNotEmpty => {_headerName.text.trim(): _headerValue.text.trim()},
        _ => const <String, String>{},
      };
      final auth = _auth == 'oauth' || headers.isNotEmpty ? _auth : 'none';
      final same = widget.initial?.kind == 'loopback' && widget.initial?.url == uri.toString() && widget.initial?.auth == 'oauth';
      out = LocalMcpConfig(
        key: key,
        label: label,
        kind: 'loopback',
        url: uri.toString(),
        headers: headers,
        auth: auth,
        // An edit that keeps the same server and browser sign-in keeps the sign-in.
        oauth: auth == 'oauth' && same ? widget.initial?.oauth : null,
        network: network,
        source: same ? widget.initial?.source : null,
        timeoutS: widget.initial?.timeoutS,
      );
    } else {
      final words = splitCommand(_command.text);
      if (words.isEmpty) return;
      final env = <String, String>{
        for (final line in _env.text.split('\n'))
          if (line.contains('=')) line.substring(0, line.indexOf('=')).trim(): line.substring(line.indexOf('=') + 1).trim(),
      }..removeWhere((k, _) => k.isEmpty);
      out = LocalMcpConfig(key: key, label: label, kind: 'stdio', command: words.first, args: words.skip(1).toList(), cwd: _cwd, env: env, timeoutS: widget.initial?.timeoutS);
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = widget.initial != null;
    return FormSheet(
      icon: LucideIcons.plug,
      title: editing ? l10n.localMcpEdit : l10n.localMcpAdd,
      submitLabel: editing ? l10n.save : l10n.localMcpAdd,
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
        if (_kind == 'loopback') ...[
          TextField(
            key: const Key('localMcpUrl'),
            controller: _url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(labelText: l10n.localMcpUrl, hintText: 'http://127.0.0.1:3845/mcp'),
          ),
          if (_offComputer) FormNote(l10n.localMcpNetworkWarning, icon: LucideIcons.globe, color: context.appColors.warning),
          Text(l10n.localMcpSignInKind, style: context.textTheme.labelLarge),
          SegmentedButton<String>(
            key: const Key('localMcpAuth'),
            segments: [
              ButtonSegment(value: 'none', label: Text(l10n.localMcpAuthNone)),
              ButtonSegment(value: 'token', label: Text(l10n.localMcpAuthToken)),
              ButtonSegment(value: 'header', label: Text(l10n.localMcpAuthHeader)),
              ButtonSegment(value: 'oauth', label: Text(l10n.localMcpAuthOAuth)),
            ],
            selected: {_auth},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => _auth = v.first),
          ),
          if (_auth == 'token')
            TextField(
              key: const Key('localMcpToken'),
              controller: _token,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: l10n.localMcpToken),
            ),
          if (_auth == 'header') ...[
            TextField(
              key: const Key('localMcpHeaderName'),
              controller: _headerName,
              autocorrect: false,
              decoration: InputDecoration(labelText: l10n.localMcpHeaderName, hintText: 'X-API-Key'),
            ),
            TextField(
              key: const Key('localMcpHeaderValue'),
              controller: _headerValue,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: l10n.localMcpHeaderValue),
            ),
          ],
          if (_auth == 'oauth') FormNote(l10n.localMcpOAuthHelp, icon: LucideIcons.logIn),
        ] else ...[
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
              // This needs a file path for dart:io, not the Uri pickDirectory() gives.
              // ignore: deprecated_member_use
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

/// Servers found in other apps' settings (D-363): pick which to add, and fill in values those
/// apps only refer to.
class _LocalMcpImportSheet extends StatefulWidget {
  const _LocalMcpImportSheet({required this.found, required this.existing});
  final List<FoundMcpServer> found;
  final List<LocalMcpConfig> existing;

  @override
  State<_LocalMcpImportSheet> createState() => _LocalMcpImportSheetState();
}

class _LocalMcpImportSheetState extends State<_LocalMcpImportSheet> {
  final _picked = <int>{};
  final _values = <(int, String), TextEditingController>{};

  bool _added(FoundMcpServer f) => widget.existing.any((e) => e.summary == f.identity);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.found.length; i++) {
      final f = widget.found[i];
      if (!_added(f) && !f.remote) _picked.add(i);
      for (final m in f.missing) {
        _values[(i, m)] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fills a missing value wherever the server used it: an empty env value or header with that
  /// name, or the token in an Authorization header.
  LocalMcpConfig _filled(int i, LocalMcpConfig c) {
    final f = widget.found[i];
    if (f.missing.isEmpty) return c;
    final env = Map<String, String>.from(c.env);
    final headers = Map<String, String>.from(c.headers);
    // With one missing value, every blank it left is that value; with more, only same-named ones.
    final only = f.missing.length == 1;
    for (final m in f.missing) {
      final v = _values[(i, m)]!.text.trim();
      if (v.isEmpty) continue;
      for (final k in env.keys.toList()) {
        if (env[k]!.isEmpty && (k == m || only)) env[k] = v;
      }
      for (final k in headers.keys.toList()) {
        if (headers[k]!.isEmpty && (k == m || only)) headers[k] = v;
      }
      for (final h in headers.keys.toList()) {
        if (h.toLowerCase() == 'authorization' && headers[h]!.trim().toLowerCase() == 'bearer') headers[h] = 'Bearer $v';
      }
    }
    return c.copyWith(env: env, headers: headers);
  }

  void _submit() {
    final taken = {for (final e in widget.existing) e.key};
    final out = <LocalMcpConfig>[];
    for (final i in _picked.toList()..sort()) {
      final f = widget.found[i];
      final key = LocalMcpConfig.keyFor(f.name, taken);
      taken.add(key);
      out.add(_filled(i, f.config.copyWith(key: key)));
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final found = widget.found;
    return FormSheet(
      icon: LucideIcons.download,
      title: l10n.localMcpImport,
      subtitle: l10n.localMcpImportHelp,
      submitLabel: l10n.localMcpImportAddCount(_picked.length),
      submitKey: const Key('importLocalMcpAdd'),
      onSubmit: _picked.isEmpty ? () => Navigator.pop(context) : _submit,
      children: [
        if (found.isEmpty) FormNote(l10n.localMcpImportNone, icon: LucideIcons.plug),
        for (var i = 0; i < found.length; i++) ...[
          CheckboxListTile(
            key: Key('importLocalMcp-$i'),
            contentPadding: EdgeInsets.zero,
            value: _added(found[i]) ? true : _picked.contains(i),
            onChanged: _added(found[i]) ? null : (v) => setState(() => v == true ? _picked.add(i) : _picked.remove(i)),
            title: Text(found[i].name),
            subtitle: Text(
              [
                l10n.localMcpImportFrom(found[i].source),
                found[i].identity,
                if (_added(found[i])) l10n.localMcpImportAdded,
                if (found[i].remote && !_added(found[i])) l10n.localMcpImportRemote,
              ].join(' · '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_picked.contains(i))
            for (final m in found[i].missing)
              TextField(
                key: Key('importLocalMcpValue-$i-$m'),
                controller: _values[(i, m)],
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: l10n.localMcpMissingValue(m)),
              ),
        ],
      ],
    );
  }
}
