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

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../chat/chat_screen.dart';

String computerStateLabel(ComputerState s) => s.value;

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
        if (c == null) return EmptyState(icon: Icons.computer, message: l10n.somethingWentWrong);
        return ComputerPanel(computer: c);
      },
    );
    if (embedded) return body;
    return Scaffold(appBar: AppBar(title: Text(l10n.computerTitle)), body: body);
  }
}

class ComputerPanel extends ConsumerWidget {
  const ComputerPanel({super.key, required this.computer});
  final Computer computer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final running = computer.state == ComputerState.running || computer.state == ComputerState.idle;
    return DefaultTabController(
      length: 4,
      child: Column(children: [
        ListTile(
          leading: Icon(Icons.computer, color: running ? Colors.green : Theme.of(context).colorScheme.outline),
          title: Text(computer.name),
          subtitle: Text(computerStateLabel(computer.state)),
          trailing: Wrap(spacing: 8, children: [
            if (!running)
              FilledButton.tonal(
                onPressed: () async {
                  await runGuarded(context, () => ref.read(backendProvider).startComputer(computer.id));
                  ref.invalidate(computersProvider);
                },
                child: Text(l10n.computerStart),
              )
            else
              OutlinedButton(
                onPressed: () async {
                  await runGuarded(context, () => ref.read(backendProvider).stopComputer(computer.id));
                  ref.invalidate(computersProvider);
                },
                child: Text(l10n.computerSleep),
              ),
          ]),
        ),
        TabBar(isScrollable: true, tabs: [
          Tab(text: l10n.screen),
          Tab(text: l10n.terminal),
          Tab(text: l10n.files),
          Tab(text: l10n.checkpoints),
        ]),
        Expanded(
          child: TabBarView(children: [
            computer.profile == ComputerProfileEnum.desktop
                ? _LiveEntry(computer: computer)
                : (running ? _ScreenTab(computerId: computer.id) : EmptyState(icon: Icons.bedtime_outlined, message: l10n.computerAsleep)),
            TerminalTab(computerId: computer.id),
            FilesTab(computerId: computer.id),
            CheckpointsTab(computerId: computer.id),
          ]),
        ),
      ]),
    );
  }
}

/// Desktop computers open the live view (it starts the computer if it is asleep).
class _LiveEntry extends StatelessWidget {
  const _LiveEntry({required this.computer});
  final Computer computer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: Icons.live_tv_outlined,
      message: l10n.liveViewHelp,
      action: FilledButton.icon(
        key: const Key('openLiveView'),
        onPressed: () => GoRouter.of(context).push('/computer/live?c=${computer.id}'),
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.openLiveView),
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
        icon: Icons.desktop_windows_outlined,
        message: context.l10n.noScreen,
        action: OutlinedButton(onPressed: _load, child: Text(context.l10n.refresh)),
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
        icon: Icons.terminal,
        message: context.l10n.terminal,
        action: FilledButton(onPressed: () => runGuarded(context, _connect), child: Text(context.l10n.connectTerminal)),
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

  void _reload() => setState(() => _entries = ref.read(backendProvider).listFiles(widget.computerId, _path));

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

  Future<void> _download(ComputerFileEntry e) async {
    final bytes = await runGuarded(context, () => ref.read(backendProvider).downloadFile(widget.computerId, e.path));
    if (bytes == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: e.name)], fileNameOverrides: [e.name]));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(children: [
      Row(children: [
        IconButton(onPressed: _path.isEmpty ? null : () => _open(_parent), icon: const Icon(Icons.arrow_upward)),
        Expanded(child: Text(_path.isEmpty ? '~/workspace' : '~/workspace/$_path', overflow: TextOverflow.ellipsis)),
        IconButton(tooltip: l10n.refresh, onPressed: _reload, icon: const Icon(Icons.refresh)),
        IconButton(tooltip: l10n.upload, onPressed: _upload, icon: const Icon(Icons.upload_file)),
      ]),
      Expanded(
        child: FutureBuilder<List<ComputerFileEntry>>(
          future: _entries,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text(errorText(context, snap.error!)));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final items = snap.data!;
            if (items.isEmpty) return EmptyState(icon: Icons.folder_open, message: l10n.emptyFolder);
            return ListView(children: [
              for (final e in items)
                ListTile(
                  leading: Icon(e.type.name == 'dir' ? Icons.folder : Icons.insert_drive_file_outlined),
                  title: Text(e.name),
                  subtitle: e.type.name == 'dir' ? null : Text('${e.size} bytes'),
                  onTap: e.type.name == 'dir' ? () => _open(_path.isEmpty ? e.name : '$_path/${e.name}') : () => _download(e),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'download') await _download(e);
                      if (v == 'delete' && context.mounted) {
                        await runGuarded(context, () => ref.read(backendProvider).deleteFile(widget.computerId, e.path));
                        _reload();
                      }
                    },
                    itemBuilder: (_) => [
                      if (e.type.name != 'dir') PopupMenuItem(value: 'download', child: Text(l10n.download)),
                      PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                    ],
                  ),
                ),
            ]);
          },
        ),
      ),
    ]);
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
        if (items.isEmpty) return EmptyState(icon: Icons.restore, message: context.l10n.noCheckpoints);
        return ListView(children: [
          for (final cp in items)
            ListTile(
              leading: const Icon(Icons.restore),
              title: Text(cp.label),
              subtitle: Text(relativeTime(cp.createdAt, context)),
              trailing: TextButton(
                onPressed: () => confirmRestore(context, ref, widget.computerId, cp.id),
                child: Text(context.l10n.restore),
              ),
            ),
        ]);
      },
    );
  }
}
