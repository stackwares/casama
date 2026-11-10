import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xterm/xterm.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import '../chat/chat_screen.dart';
import '../files/file_preview.dart';
import '../../ui/glow_button.dart';

String computerStateLabel(BuildContext context, ComputerState s) {
  final l10n = context.l10n;
  return switch (s) {
    ComputerState.provisioning => l10n.stateProvisioning,
    ComputerState.starting => l10n.stateStarting,
    ComputerState.running => l10n.stateRunning,
    ComputerState.idle => l10n.stateIdle,
    ComputerState.sleeping => l10n.stateSleeping,
    ComputerState.stopped => l10n.stateStopped,
    ComputerState.error => l10n.stateError,
  };
}

/// The team computer (or a bot's private one): state, screen, terminal, files, checkpoints.
class ComputerScreen extends ConsumerWidget {
  const ComputerScreen({super.key, this.botId, this.embedded = false});
  final String? botId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final computers = ref.watch(computersProvider);
    final body = AsyncView(
      value: computers,
      onRetry: () => ref.invalidate(computersProvider),
      data: (list) {
        final c = botId == null ? computerForBot(list, '') : computerForBot(list, botId!);
        if (c == null) return EmptyState(icon: LucideIcons.laptop, message: l10n.somethingWentWrong);
        return ComputerPanel(computer: c);
      },
    );
    if (embedded) return body;
    return Scaffold(
      appBar: ShellHeader(title: l10n.computerTitle),
      body: body,
    );
  }
}

/// Whether a computer is on its way up (the screen shows progress and polls faster).
bool computerWaking(ComputerState s) => s == ComputerState.provisioning || s == ComputerState.starting;

class ComputerPanel extends ConsumerStatefulWidget {
  const ComputerPanel({super.key, required this.computer});
  final Computer computer;

  @override
  ConsumerState<ComputerPanel> createState() => _ComputerPanelState();
}

class _ComputerPanelState extends ConsumerState<ComputerPanel> {
  // The computer's state changes without this screen: the live view and bots wake it, the idle
  // timer puts it to sleep. Refresh while visible: quickly while it wakes, gently otherwise.
  Timer? _poll;
  late final AppLifecycleListener _lifecycle;
  String? _action; // 'start' | 'sleep' while a button's request runs

  @override
  void initState() {
    super.initState();
    _schedule();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void didUpdateWidget(ComputerPanel old) {
    super.didUpdateWidget(old);
    if (old.computer.state != widget.computer.state) _schedule();
  }

  void _schedule() {
    _poll?.cancel();
    _poll = Timer.periodic(Duration(seconds: computerWaking(widget.computer.state) ? 3 : 10), (_) => _refresh());
  }

  void _refresh() {
    if (mounted) ref.invalidate(computersProvider);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _run(String action, Future<void> Function() call) async {
    setState(() => _action = action);
    await runGuarded(context, call);
    if (!mounted) return;
    setState(() => _action = null);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final computer = widget.computer;
    final running = computer.state == ComputerState.running || computer.state == ComputerState.idle;
    final waking = computerWaking(computer.state) || _action == 'start';
    final failed = computer.state == ComputerState.error;
    return DefaultTabController(
      length: 4,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          // Header, tabs and lists share one centered column on wide windows.
          constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (running ? context.appColors.working : context.colorScheme.onSurfaceVariant).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.icon),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        computer.profile == ComputerProfileEnum.desktop ? LucideIcons.monitor : LucideIcons.squareTerminal,
                        size: 20,
                        color: running ? context.appColors.working : context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            computer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: StatusLabel(
                                  key: const Key('computerState'),
                                  text: _action == 'start'
                                      ? l10n.stateStarting
                                      : _action == 'sleep'
                                      ? l10n.computerGoingToSleep
                                      : computerStateLabel(context, computer.state),
                                  color: failed
                                      ? context.appColors.negative
                                      : (running || waking ? context.appColors.working : context.colorScheme.onSurfaceVariant),
                                  pill: true,
                                ),
                              ),
                              if (waking || _action == 'sleep') ...[
                                const SizedBox(width: 6),
                                SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: context.appColors.working)),
                              ],
                            ],
                          ),
                          if (failed && computer.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                computer.error!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.bodySmall?.copyWith(color: context.appColors.negative),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (running)
                          OutlinedButton.icon(
                            key: const Key('computerSleep'),
                            onPressed: _action != null ? null : () => _run('sleep', () => ref.read(backendProvider).stopComputer(computer.id)),
                            icon: const Icon(LucideIcons.moon, size: 18),
                            label: Text(l10n.computerSleep),
                          )
                        else
                          FilledButton.tonalIcon(
                            key: const Key('computerStart'),
                            // Already waking: the button shows progress instead of starting it twice.
                            onPressed: waking || _action != null ? null : () => _run('start', () => ref.read(backendProvider).startComputer(computer.id)),
                            icon: waking
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(failed ? LucideIcons.rotateCw : LucideIcons.power, size: 18),
                            label: Text(waking ? l10n.stateStarting : (failed ? l10n.retry : l10n.computerWake)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: EdgeInsets.zero,
                    tabs: [
                      _IconTab(icon: LucideIcons.monitor, text: l10n.screen),
                      _IconTab(icon: LucideIcons.squareTerminal, text: l10n.terminal),
                      _IconTab(icon: LucideIcons.folder, text: l10n.files),
                      _IconTab(icon: LucideIcons.history, text: l10n.checkpoints),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Expanded(
                child: TabBarView(
                  children: [
                    computer.profile == ComputerProfileEnum.desktop
                        ? _LiveEntry(computer: computer)
                        : Column(
                            children: [
                              _DesktopSwitch(computer: computer),
                              Expanded(
                                child: running ? _ScreenTab(computerId: computer.id) : EmptyState(icon: LucideIcons.moon, message: l10n.computerAsleep),
                              ),
                            ],
                          ),
                    TerminalTab(computerId: computer.id),
                    FilesTab(computerId: computer.id),
                    CheckpointsTab(computerId: computer.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pill tab with a leading icon.
class _IconTab extends StatelessWidget {
  const _IconTab({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    // Phones keep all four tabs in view; the icons come back where there is room.
    final roomy = AppBreakpoints.of(MediaQuery.sizeOf(context).width) != WindowSize.compact;
    return Tab(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (roomy) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
          Text(text),
        ],
      ),
    );
  }
}

/// Desktop computers open the live view (it starts the computer if it is asleep, and says so).
class _LiveEntry extends ConsumerWidget {
  const _LiveEntry({required this.computer});
  final Computer computer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final awake = computer.state == ComputerState.running || computer.state == ComputerState.idle;
    return EmptyState(
      icon: awake ? LucideIcons.monitorPlay : LucideIcons.moon,
      message: awake ? l10n.liveViewHelp : l10n.liveViewWakesHelp,
      action: GlowButton.icon(
        key: const Key('openLiveView'),
        onPressed: () async {
          await GoRouter.of(context).push('/computer/live?c=${computer.id}');
          // The live view may have woken it up.
          ref.invalidate(computersProvider);
        },
        icon: Icon(awake ? LucideIcons.play : LucideIcons.sunrise),
        label: Text(awake ? l10n.openLiveView : l10n.wakeAndWatch),
      ),
    );
  }
}

/// Headless computers only have a browser; offer the desktop profile (restarts, files are kept).
class _DesktopSwitch extends ConsumerStatefulWidget {
  const _DesktopSwitch({required this.computer});
  final Computer computer;

  @override
  ConsumerState<_DesktopSwitch> createState() => _DesktopSwitchState();
}

class _DesktopSwitchState extends ConsumerState<_DesktopSwitch> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.xxs),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(l10n.headlessScreenNote, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonalIcon(
                key: const Key('switchToDesktop'),
                icon: const Icon(LucideIcons.monitor, size: 18),
                label: Text(l10n.switchToDesktop),
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await runGuarded(context, () => ref.read(backendProvider).updateComputer(widget.computer.id, profile: 'desktop'));
                        ref.invalidate(computersProvider);
                        if (mounted) setState(() => _busy = false);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenTab extends ConsumerStatefulWidget {
  const _ScreenTab({required this.computerId});
  final String computerId;

  @override
  ConsumerState<_ScreenTab> createState() => _ScreenTabState();
}

class _ScreenTabState extends ConsumerState<_ScreenTab> {
  Uint8List? _png;
  var _loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Periodic screenshots (live WebRTC view arrives in Phase 5).
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    final png = await ref.read(backendProvider).screenshot(widget.computerId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (png != null) _png = png;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_png == null) {
      return EmptyState(
        icon: LucideIcons.monitor,
        message: context.l10n.noScreen,
        action: OutlinedButton.icon(onPressed: _load, icon: const Icon(LucideIcons.rotateCw, size: 18), label: Text(context.l10n.refresh)),
      );
    }
    return InteractiveViewer(child: Center(child: Image.memory(_png!, gaplessPlayback: true)));
  }
}

/// Interactive terminal over WebSocket, rendered with xterm.
class TerminalTab extends ConsumerStatefulWidget {
  const TerminalTab({super.key, required this.computerId});
  final String computerId;

  @override
  ConsumerState<TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends ConsumerState<TerminalTab> with AutomaticKeepAliveClientMixin {
  final _terminal = Terminal(maxLines: 5000);
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  var _connected = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _connect() async {
    final (uri, _) = await ref.read(backendProvider).terminal(widget.computerId, cols: _terminal.viewWidth, rows: _terminal.viewHeight);
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    _terminal.onOutput = (data) => channel.sink.add(utf8.encode(data));
    _sub = channel.stream.listen(
      (msg) => _terminal.write(msg is String ? msg : utf8.decode(msg as List<int>, allowMalformed: true)),
      onDone: () {
        if (!mounted) return;
        _terminal.write('\r\n${context.l10n.terminalDisconnected}\r\n');
        setState(() => _connected = false);
      },
    );
    setState(() {
      _channel = channel;
      _connected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_connected) {
      return EmptyState(
        icon: LucideIcons.squareTerminal,
        title: context.l10n.terminal,
        message: context.l10n.terminalHelp,
        action: GlowButton.icon(
          onPressed: () => runGuarded(context, _connect),
          icon: const Icon(LucideIcons.plug, size: 18),
          label: Text(context.l10n.connectTerminal),
        ),
      );
    }
    return Padding(padding: const EdgeInsets.all(8), child: TerminalView(_terminal, autofocus: true));
  }
}

class FilesTab extends ConsumerStatefulWidget {
  const FilesTab({super.key, required this.computerId});
  final String computerId;

  @override
  ConsumerState<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends ConsumerState<FilesTab> {
  var _path = '';
  Future<List<ComputerFileEntry>>? _entries;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    // Start the request first; the setState callback must not return the Future.
    final next = ref.read(backendProvider).listFiles(widget.computerId, _path);
    setState(() {
      _entries = next;
    });
  }

  void _open(String path) {
    _path = path;
    _reload();
  }

  String get _parent {
    final parts = _path.split('/')..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '';
    parts.removeLast();
    return parts.join('/');
  }

  Future<void> _upload() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty || !mounted) return;
    final file = picked.first;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final target = _path.isEmpty ? file.name : '$_path/${file.name}';
    await runGuarded(context, () => ref.read(backendProvider).uploadFile(widget.computerId, target, bytes));
    _reload();
  }

  Future<void> _download(ComputerFileEntry e, {Rect? origin}) async {
    final bytes = await runGuarded(context, () => ref.read(backendProvider).downloadFile(widget.computerId, e.path));
    if (bytes == null || !mounted) return;
    await shareFiles(
      [XFile.fromData(bytes, name: e.name)],
      names: [e.name],
      origin: origin ?? shareOrigin(context),
    );
  }

  Future<void> _delete(ComputerFileEntry e) async {
    final l10n = context.l10n;
    final ok = await showConfirm(context: context, title: l10n.deleteFileTitle(e.name), confirmLabel: l10n.delete, destructive: true);
    if (!ok || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).deleteFile(widget.computerId, e.path));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final crumbs = _path.split('/')..removeWhere((p) => p.isEmpty);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = pageSide(constraints.maxWidth);
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.sm),
              child: Row(
                children: [
                  if (_path.isNotEmpty) ...[
                    IconButton.filledTonal(tooltip: l10n.up, onPressed: () => _open(_parent), icon: const Icon(LucideIcons.arrowUp, size: 20)),
                    const SizedBox(width: AppSpace.xs),
                  ],
                  Expanded(
                    child: LayoutBuilder(
                      // Starts at the left; long paths scroll so the current folder stays visible.
                      builder: (context, bar) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: bar.maxWidth),
                          child: Row(
                            children: [
                              _Crumb(icon: LucideIcons.house, label: 'workspace', onTap: crumbs.isEmpty ? null : () => _open('')),
                              for (var i = 0; i < crumbs.length; i++) ...[
                                Icon(LucideIcons.chevronRight, size: 18, color: scheme.onSurfaceVariant),
                                _Crumb(label: crumbs[i], onTap: i == crumbs.length - 1 ? null : () => _open(crumbs.sublist(0, i + 1).join('/'))),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(tooltip: l10n.refresh, onPressed: _reload, icon: const Icon(LucideIcons.rotateCw)),
                  FilledButton.tonalIcon(onPressed: _upload, icon: const Icon(LucideIcons.upload, size: 18), label: Text(l10n.upload)),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ComputerFileEntry>>(
                future: _entries,
                builder: (context, snap) {
                  if (snap.hasError) return EmptyState(icon: LucideIcons.circleAlert, isError: true, message: errorText(context, snap.error!));
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final items = [...snap.data!]
                    ..sort((a, b) {
                      final ad = a.type.name == 'dir', bd = b.type.name == 'dir';
                      if (ad != bd) return ad ? -1 : 1;
                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                    });
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.folderOpen,
                      title: l10n.emptyFolder,
                      message: l10n.emptyFolderHelp,
                      action: OutlinedButton.icon(onPressed: _upload, icon: const Icon(LucideIcons.upload, size: 18), label: Text(l10n.upload)),
                    );
                  }
                  return ListView(
                    padding: EdgeInsets.fromLTRB(side, 0, side, AppSpace.xl + MediaQuery.paddingOf(context).bottom),
                    children: [
                      GroupedCard(
                        children: [
                          for (final e in items)
                            if (e.type.name == 'dir')
                              GroupedTile(
                                icon: LucideIcons.folder,
                                iconColor: context.appColors.warning,
                                title: e.name,
                                onTap: () => _open(_path.isEmpty ? e.name : '$_path/${e.name}'),
                              )
                            else
                              GroupedTile(
                                icon: fileIconFor(e.name),
                                title: e.name,
                                subtitle: formatBytes(e.size),
                                onTap: () => showComputerFile(context, computerId: widget.computerId, path: e.path),
                                trailing: Builder(
                                  // The share sheet points at this button on iPad and macOS.
                                  builder: (anchor) => PopupMenuButton<String>(
                                    tooltip: l10n.moreActions,
                                    icon: Icon(LucideIcons.ellipsisVertical, color: scheme.onSurfaceVariant),
                                    onSelected: (v) async {
                                      if (v == 'download') await _download(e, origin: shareOrigin(anchor));
                                      if (v == 'delete') await _delete(e);
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'download',
                                        child: ListTile(dense: true, leading: const Icon(LucideIcons.share), title: Text(l10n.download)),
                                      ),
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
                                ),
                              ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.label, this.icon, this.onTap});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final current = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: current ? scheme.onSurface : scheme.primary), const SizedBox(width: 4)],
            Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: current ? scheme.onSurface : scheme.primary,
                fontWeight: current ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckpointsTab extends ConsumerStatefulWidget {
  const CheckpointsTab({super.key, required this.computerId});
  final String computerId;

  @override
  ConsumerState<CheckpointsTab> createState() => _CheckpointsTabState();
}

class _CheckpointsTabState extends ConsumerState<CheckpointsTab> {
  Future<List<Checkpoint>>? _items;

  @override
  void initState() {
    super.initState();
    _items = ref.read(backendProvider).checkpoints(widget.computerId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Checkpoint>>(
      future: _items,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(errorText(context, snap.error!)));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return EmptyState(icon: LucideIcons.history, title: context.l10n.noCheckpointsTitle, message: context.l10n.noCheckpoints);
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final side = pageSide(constraints.maxWidth);
            return ListView(
              padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xl + MediaQuery.paddingOf(context).bottom),
              children: [
                FormNote(context.l10n.checkpointsHelp),
                const SizedBox(height: AppSpace.md),
                GroupedCard(
                  children: [
                    for (final cp in items)
                      GroupedTile(
                        icon: LucideIcons.bookmark,
                        iconColor: context.appColors.warning,
                        title: cp.label,
                        subtitle: relativeTime(cp.createdAt, context),
                        trailing: OutlinedButton.icon(
                          onPressed: () => confirmRestore(context, ref, widget.computerId, cp.id),
                          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(LucideIcons.rotateCcw, size: 16),
                          label: Text(context.l10n.restore),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
