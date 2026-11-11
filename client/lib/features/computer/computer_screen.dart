import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xterm/xterm.dart';

import 'live_view_screen.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/user_activity.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/edge_fade.dart';
import '../../ui/advanced_section.dart';
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
    // A bot's own pick wins, so the profile tile and the chat open the computer the chat uses.
    final defaultComputerId = botId == null
        ? null
        : ref.watch(botProvider(botId!))?.defaultComputerId;
    final body = AsyncView(
      value: computers,
      onRetry: () => ref.invalidate(computersProvider),
      data: (list) {
        final c = computerForBot(
          list,
          botId ?? '',
          defaultComputerId: defaultComputerId,
        );
        if (c == null) {
          return EmptyState(
            icon: LucideIcons.laptop,
            message: l10n.somethingWentWrong,
          );
        }
        return ComputerPanel(computer: c, embedded: embedded);
      },
    );
    if (embedded) return body;
    return Scaffold(
      // Opened from a chat or Settings, not a tab (D-176): phones always get a way back.
      appBar: ShellHeader(title: l10n.computerTitle, phoneFallback: '/bots'),
      body: body,
    );
  }
}

/// Whether a computer is on its way up (the screen shows progress and polls faster).
bool computerWaking(ComputerState s) =>
    s == ComputerState.provisioning || s == ComputerState.starting;

class ComputerPanel extends ConsumerStatefulWidget {
  const ComputerPanel({
    super.key,
    required this.computer,
    this.embedded = false,
  });
  final Computer computer;

  /// In the side panel next to the chat (large screens): a desktop's live view plays here once
  /// the person starts, wakes, or opens it, with a button to open it full screen.
  final bool embedded;

  @override
  ConsumerState<ComputerPanel> createState() => _ComputerPanelState();
}

class _ComputerPanelState extends ConsumerState<ComputerPanel> {
  // The computer's state changes without this screen: the live view and bots wake it, the idle
  // timer puts it to sleep. Refresh while visible: quickly while it wakes, gently otherwise.
  Timer? _poll;
  late final AppLifecycleListener _lifecycle;
  String? _action; // 'start' | 'sleep' while a button's request runs
  // The side panel does not open the live stream just because the computer is already on (a bot
  // may have started it). It opens after this person wakes it or asks to watch.
  var _watchLive = false;
  // The tab that's open, by name, so it keeps its place when Terminal and Checkpoints come and go.
  var _tab = 'screen';
  var _tabIds = const <String>[];

  @override
  void initState() {
    super.initState();
    _schedule();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void didUpdateWidget(ComputerPanel old) {
    super.didUpdateWidget(old);
    if (old.computer.id != widget.computer.id) {
      _watchLive = false;
    } else if (_watchLive &&
        _computerAwake(old.computer.state) &&
        !_computerAwake(widget.computer.state) &&
        _action != 'start' &&
        !computerWaking(widget.computer.state)) {
      // It went to sleep on its own. A later wake (often a bot) should not reopen the stream.
      _watchLive = false;
    }
    if (old.computer.state != widget.computer.state) _schedule();
  }

  bool _computerAwake(ComputerState s) =>
      s == ComputerState.running || s == ComputerState.idle;

  void _schedule() {
    _poll?.cancel();
    _poll = Timer.periodic(
      Duration(seconds: computerWaking(widget.computer.state) ? 3 : 10),
      (_) => _refresh(),
    );
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

  Future<T?> _run<T>(String action, Future<T> Function() call) async {
    setState(() => _action = action);
    final result = await runGuarded(context, call);
    if (!mounted) return null;
    setState(() => _action = null);
    _refresh();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final computer = widget.computer;
    final running =
        computer.state == ComputerState.running ||
        computer.state == ComputerState.idle;
    final waking = computerWaking(computer.state) || _action == 'start';
    final failed = computer.state == ComputerState.error;
    // Screen and Files always; Terminal and Checkpoints once Advanced is opened here (D-182).
    final advanced = ref
        .watch(advancedOpenProvider)
        .contains(computerTabsAdvancedId);
    final tabIds = [
      for (final t in const ['screen', 'terminal', 'files', 'checkpoints'])
        if (advanced || t == 'screen' || t == 'files') t,
    ];
    _tabIds = tabIds;
    final tabIndex = tabIds.indexOf(_tab);
    if (tabIndex < 0) _tab = tabIds.first;
    return DefaultTabController(
      // A new controller when tabs come or go; the open tab stays when it still exists.
      key: ValueKey(tabIds.length),
      length: tabIds.length,
      initialIndex: tabIndex < 0 ? 0 : tabIndex,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          // Header, tabs and lists share one centered column on wide windows.
          constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.sm,
                  AppSpace.md,
                  AppSpace.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            (running
                                    ? context.appColors.working
                                    : context.colorScheme.onSurfaceVariant)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.icon),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        computer.profile == ComputerProfileEnum.desktop
                            ? LucideIcons.monitor
                            : LucideIcons.squareTerminal,
                        size: 20,
                        color: running
                            ? context.appColors.working
                            : context.colorScheme.onSurfaceVariant,
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
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
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
                                      : computerStateLabel(
                                          context,
                                          computer.state,
                                        ),
                                  color: failed
                                      ? context.appColors.negative
                                      : (running || waking
                                            ? context.appColors.working
                                            : context
                                                  .colorScheme
                                                  .onSurfaceVariant),
                                  pill: true,
                                ),
                              ),
                              if (waking || _action == 'sleep') ...[
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.6,
                                    color: context.appColors.working,
                                  ),
                                ),
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
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.appColors.negative,
                                ),
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
                            onPressed: _action != null
                                ? null
                                : () {
                                    setState(() => _watchLive = false);
                                    _run(
                                      'sleep',
                                      () => ref
                                          .read(backendProvider)
                                          .stopComputer(computer.id),
                                    );
                                  },
                            icon: const Icon(LucideIcons.moon, size: 18),
                            label: Text(l10n.computerSleep),
                          )
                        else
                          FilledButton.tonalIcon(
                            key: const Key('computerStart'),
                            // Already waking: the button shows progress instead of starting it twice.
                            onPressed: waking || _action != null
                                ? null
                                : () async {
                                    final started = await _run(
                                      'start',
                                      () => ref
                                          .read(backendProvider)
                                          .startComputer(computer.id),
                                    );
                                    if (started != null && mounted) {
                                      setState(() => _watchLive = true);
                                    }
                                  },
                            icon: waking
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    failed
                                        ? LucideIcons.rotateCw
                                        : LucideIcons.power,
                                    size: 18,
                                  ),
                            label: Text(
                              waking
                                  ? l10n.stateStarting
                                  : (failed ? l10n.retry : l10n.computerWake),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: EdgeFade(
                          child: TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            padding: const EdgeInsetsDirectional.only(
                              start: AppSpace.sm,
                            ),
                            onTap: (_) => HapticsHelper.light(),
                            tabs: [
                              for (final t in tabIds)
                                switch (t) {
                                  'terminal' => _IconTab(
                                    icon: LucideIcons.squareTerminal,
                                    text: l10n.terminal,
                                  ),
                                  'files' => _IconTab(
                                    icon: LucideIcons.folder,
                                    text: l10n.files,
                                  ),
                                  'checkpoints' => _IconTab(
                                    icon: LucideIcons.history,
                                    text: l10n.checkpoints,
                                  ),
                                  _ => _IconTab(
                                    icon: LucideIcons.monitor,
                                    text: l10n.screen,
                                  ),
                                },
                            ],
                          ),
                        ),
                      ),
                    ),
                    _AdvancedTabsToggle(open: advanced),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Expanded(
                child: _TabWatch(
                  onChanged: (i) {
                    if (i < _tabIds.length) _tab = _tabIds[i];
                  },
                  child: TabBarView(
                    children: [
                      for (final t in tabIds)
                        switch (t) {
                          'terminal' => TerminalTab(computerId: computer.id),
                          'files' => FilesTab(computerId: computer.id),
                          'checkpoints' => CheckpointsTab(
                            computerId: computer.id,
                          ),
                          _ =>
                            computer.profile == ComputerProfileEnum.desktop
                                ? (widget.embedded
                                      ? _InlineLive(
                                          computer: computer,
                                          watching: _watchLive,
                                          onWatch: () =>
                                              setState(() => _watchLive = true),
                                        )
                                      : _LiveEntry(computer: computer))
                                : Column(
                                    children: [
                                      const _HeadlessNote(),
                                      Expanded(
                                        child: running
                                            ? _ScreenTab(
                                                computerId: computer.id,
                                              )
                                            : EmptyState(
                                                icon: LucideIcons.moon,
                                                message: l10n.computerAsleep,
                                              ),
                                      ),
                                    ],
                                  ),
                        },
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The [AdvancedSection] id whose open state shows the Terminal and Checkpoints tabs (D-182).
const computerTabsAdvancedId = 'computer.tabs';

/// At the end of the tab row: shows or hides Terminal and Checkpoints, remembered on this device
/// like any Advanced section (D-182).
class _AdvancedTabsToggle extends ConsumerWidget {
  const _AdvancedTabsToggle({required this.open});
  final bool open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final color = open ? scheme.primary : scheme.onSurfaceVariant;
    return Tooltip(
      message: open
          ? l10n.computerAdvancedTabsHide
          : l10n.computerAdvancedTabsShow,
      child: Semantics(
        toggled: open,
        child: TextButton.icon(
          key: const Key('advanced-$computerTabsAdvancedId'),
          style: TextButton.styleFrom(
            foregroundColor: color,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => ref
              .read(advancedOpenProvider.notifier)
              .set(computerTabsAdvancedId, !open),
          icon: Icon(LucideIcons.slidersHorizontal, size: 16, color: color),
          label: Text(l10n.advanced),
        ),
      ),
    );
  }
}

/// Tells [onChanged] which tab is open, including after a swipe.
class _TabWatch extends StatefulWidget {
  const _TabWatch({required this.onChanged, required this.child});
  final ValueChanged<int> onChanged;
  final Widget child;

  @override
  State<_TabWatch> createState() => _TabWatchState();
}

class _TabWatchState extends State<_TabWatch> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = DefaultTabController.of(context);
    if (c == _controller) return;
    _controller?.removeListener(_changed);
    _controller = c..addListener(_changed);
  }

  void _changed() => widget.onChanged(_controller!.index);

  @override
  void dispose() {
    _controller?.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A pill tab with a leading icon.
class _IconTab extends StatelessWidget {
  const _IconTab({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    // Phones keep all four tabs in view; the icons come back where there is room.
    final roomy =
        AppBreakpoints.of(MediaQuery.sizeOf(context).width) !=
        WindowSize.compact;
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
    final awake =
        computer.state == ComputerState.running ||
        computer.state == ComputerState.idle;
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

/// The live view inside the side panel. It stays closed until [watching] (this person woke the
/// computer or asked to watch). Asleep, it offers to wake the computer here; while the full-screen
/// view is open it steps aside, so there is one stream, not two.
class _InlineLive extends ConsumerStatefulWidget {
  const _InlineLive({
    required this.computer,
    required this.watching,
    required this.onWatch,
  });
  final Computer computer;

  /// This person started, woke, or opened the live view during this visit to the panel.
  final bool watching;
  final VoidCallback onWatch;

  @override
  ConsumerState<_InlineLive> createState() => _InlineLiveState();
}

class _InlineLiveState extends ConsumerState<_InlineLive> {
  var _expanded = false;
  var _waking = false;

  Future<void> _expand() async {
    setState(() => _expanded = true);
    await GoRouter.of(context).push('/computer/live?c=${widget.computer.id}');
    if (!mounted) return;
    setState(() => _expanded = false);
    ref.invalidate(computersProvider);
  }

  Future<void> _wake() async {
    setState(() => _waking = true);
    final started = await runGuarded(
      context,
      () => ref.read(backendProvider).startComputer(widget.computer.id),
    );
    if (!mounted) return;
    setState(() => _waking = false);
    if (started != null) widget.onWatch();
    ref.invalidate(computersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = widget.computer;
    final awake =
        c.state == ComputerState.running || c.state == ComputerState.idle;
    if (_expanded) {
      return EmptyState(
        icon: LucideIcons.maximize2,
        message: l10n.liveShownFullScreen,
        action: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(LucideIcons.minimize2, size: 18),
          label: Text(l10n.liveMinimize),
        ),
      );
    }
    // Already on, but this person has not asked to watch: leave the stream closed.
    if (awake && !widget.watching) {
      return EmptyState(
        icon: LucideIcons.monitorPlay,
        message: l10n.liveViewHelp,
        action: GlowButton.icon(
          key: const Key('openLiveView'),
          onPressed: widget.onWatch,
          icon: const Icon(LucideIcons.play),
          label: Text(l10n.openLiveView),
        ),
      );
    }
    if (!awake) {
      final waking = _waking || computerWaking(c.state);
      return EmptyState(
        icon: LucideIcons.moon,
        message: l10n.liveViewWakesHelp,
        action: GlowButton.icon(
          key: const Key('openLiveView'),
          onPressed: waking ? null : _wake,
          icon: waking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.sunrise),
          label: Text(waking ? l10n.stateStarting : l10n.wakeAndWatch),
        ),
      );
    }
    return LiveViewScreen(
      key: ValueKey(c.id),
      computerId: c.id,
      embedded: true,
      onExpand: _expand,
    );
  }
}

/// Headless computers only have a browser. Switching to a desktop lives in Settings > Computers
/// (one place for it, D-182); this says so and links there.
class _HeadlessNote extends StatelessWidget {
  const _HeadlessNote();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.xxs,
      ),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    l10n.headlessScreenNoteSettings,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: const Key('openComputerSettings'),
                icon: const Icon(LucideIcons.settings, size: 16),
                label: Text(l10n.openComputerSettings),
                onPressed: () =>
                    GoRouter.maybeOf(context)?.push('/settings/computers'),
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
        action: OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(LucideIcons.rotateCw, size: 18),
          label: Text(context.l10n.refresh),
        ),
      );
    }
    return InteractiveViewer(
      child: Center(child: Image.memory(_png!, gaplessPlayback: true)),
    );
  }
}

/// Interactive terminal over WebSocket, rendered with xterm.
class TerminalTab extends ConsumerStatefulWidget {
  const TerminalTab({super.key, required this.computerId});
  final String computerId;

  @override
  ConsumerState<TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends ConsumerState<TerminalTab>
    with AutomaticKeepAliveClientMixin {
  final _terminal = Terminal(maxLines: 5000);
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  var _connected = false;
  // An open terminal keeps the computer awake only while the person is here (D-195).
  PresenceBeat? _presence;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _presence?.dispose();
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _connect() async {
    final (uri, _) = await ref
        .read(backendProvider)
        .terminal(
          widget.computerId,
          cols: _terminal.viewWidth,
          rows: _terminal.viewHeight,
        );
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    _terminal.onOutput = (data) => channel.sink.add(utf8.encode(data));
    _sub = channel.stream.listen(
      (msg) => _terminal.write(
        msg is String
            ? msg
            : utf8.decode(msg as List<int>, allowMalformed: true),
      ),
      onDone: () {
        _presence?.dispose();
        _presence = null;
        if (!mounted) return;
        _terminal.write('\r\n${context.l10n.terminalDisconnected}\r\n');
        setState(() => _connected = false);
      },
    );
    _presence?.dispose();
    _presence = PresenceBeat(
      () => channel.sink.add(jsonEncode({'event': 'presence'})),
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TerminalView(
        _terminal,
        autofocus: true,
        // xterm's default (an email keyboard) becomes an <input type="email"> on the web, and
        // browsers drop spaces typed into those. Plain text there; the email keyboard elsewhere
        // still keeps autocorrect and capitals away.
        keyboardType: kIsWeb ? TextInputType.text : TextInputType.emailAddress,
      ),
    );
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
    await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .uploadFile(widget.computerId, target, bytes),
    );
    _reload();
  }

  Future<void> _download(ComputerFileEntry e, {Rect? origin}) async {
    final bytes = await runGuarded(
      context,
      () => ref.read(backendProvider).downloadFile(widget.computerId, e.path),
    );
    if (bytes == null || !mounted) return;
    await shareFiles(
      [XFile.fromData(bytes, name: e.name)],
      names: [e.name],
      origin: origin ?? shareOrigin(context),
    );
  }

  Future<void> _delete(ComputerFileEntry e) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.deleteFileTitle(e.name),
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await runGuarded(
      context,
      () => ref.read(backendProvider).deleteFile(widget.computerId, e.path),
    );
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
              padding: EdgeInsets.fromLTRB(
                side,
                AppSpace.xs,
                side,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  if (_path.isNotEmpty) ...[
                    IconButton.filledTonal(
                      tooltip: l10n.up,
                      onPressed: () => _open(_parent),
                      icon: const Icon(LucideIcons.arrowUp, size: 20),
                    ),
                    const SizedBox(width: AppSpace.xs),
                  ],
                  Expanded(
                    child: LayoutBuilder(
                      // Starts at the left; long paths scroll so the current folder stays visible.
                      builder: (context, bar) => EdgeFade(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: bar.maxWidth),
                            child: Row(
                              children: [
                                _Crumb(
                                  icon: LucideIcons.house,
                                  label: 'workspace',
                                  onTap: crumbs.isEmpty
                                      ? null
                                      : () => _open(''),
                                ),
                                for (var i = 0; i < crumbs.length; i++) ...[
                                  Icon(
                                    LucideIcons.chevronRight,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  _Crumb(
                                    label: crumbs[i],
                                    onTap: i == crumbs.length - 1
                                        ? null
                                        : () => _open(
                                            crumbs.sublist(0, i + 1).join('/'),
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.refresh,
                    onPressed: _reload,
                    icon: const Icon(LucideIcons.rotateCw),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _upload,
                    icon: const Icon(LucideIcons.upload, size: 18),
                    label: Text(l10n.upload),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ComputerFileEntry>>(
                future: _entries,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return EmptyState(
                      icon: LucideIcons.circleAlert,
                      isError: true,
                      message: errorText(context, snap.error!),
                    );
                  }
                  if (!snap.hasData) return const SkeletonList();
                  final items = [...snap.data!]
                    ..sort((a, b) {
                      final ad = a.type.name == 'dir',
                          bd = b.type.name == 'dir';
                      if (ad != bd) return ad ? -1 : 1;
                      return a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                    });
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.folderOpen,
                      title: l10n.emptyFolder,
                      message: l10n.emptyFolderHelp,
                      action: OutlinedButton.icon(
                        onPressed: _upload,
                        icon: const Icon(LucideIcons.upload, size: 18),
                        label: Text(l10n.upload),
                      ),
                    );
                  }
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      0,
                      side,
                      AppSpace.xl + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      GroupedCard(
                        children: [
                          for (final e in items)
                            if (e.type.name == 'dir')
                              GroupedTile(
                                icon: LucideIcons.folder,
                                iconColor: context.appColors.warning,
                                title: e.name,
                                onTap: () => _open(
                                  _path.isEmpty ? e.name : '$_path/${e.name}',
                                ),
                              )
                            else
                              GroupedTile(
                                icon: fileIconFor(e.name),
                                title: e.name,
                                subtitle: formatBytes(
                                  e.size,
                                  context.l10n.localeName,
                                ),
                                onTap: () => showComputerFile(
                                  context,
                                  computerId: widget.computerId,
                                  path: e.path,
                                ),
                                trailing: Builder(
                                  // The share sheet points at this button on iPad and macOS.
                                  builder: (anchor) => PopupMenuButton<String>(
                                    tooltip: l10n.moreActions,
                                    icon: Icon(
                                      LucideIcons.ellipsisVertical,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    onSelected: (v) async {
                                      if (v == 'download') {
                                        await _download(
                                          e,
                                          origin: shareOrigin(anchor),
                                        );
                                      }
                                      if (v == 'delete') await _delete(e);
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'download',
                                        child: ListTile(
                                          dense: true,
                                          leading: const Icon(
                                            LucideIcons.share,
                                          ),
                                          title: Text(l10n.download),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          dense: true,
                                          leading: Icon(
                                            LucideIcons.trash2,
                                            color: scheme.error,
                                          ),
                                          title: Text(
                                            l10n.delete,
                                            style: TextStyle(
                                              color: scheme.error,
                                            ),
                                          ),
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
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: current ? scheme.onSurface : scheme.primary,
              ),
              const SizedBox(width: 4),
            ],
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
        if (snap.hasError && snap.connectionState == ConnectionState.done) {
          return EmptyState(
            icon: LucideIcons.cloudOff,
            title: context.l10n.somethingWentWrong,
            message: errorText(context, snap.error!),
            isError: true,
            action: FilledButton.tonalIcon(
              onPressed: () {
                final items = ref
                    .read(backendProvider)
                    .checkpoints(widget.computerId);
                setState(() {
                  _items = items;
                });
              },
              icon: const Icon(LucideIcons.rotateCw, size: 18),
              label: Text(context.l10n.retry),
            ),
          );
        }
        if (!snap.hasData) return const SkeletonList();
        final items = snap.data!;
        if (items.isEmpty) {
          return EmptyState(
            icon: LucideIcons.history,
            title: context.l10n.noCheckpointsTitle,
            message: context.l10n.noCheckpoints,
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final side = pageSide(constraints.maxWidth);
            return ListView(
              padding: EdgeInsets.fromLTRB(
                side,
                AppSpace.xs,
                side,
                AppSpace.xl + MediaQuery.paddingOf(context).bottom,
              ),
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
                          onPressed: () => confirmRestore(
                            context,
                            ref,
                            widget.computerId,
                            cp.id,
                          ),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
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
