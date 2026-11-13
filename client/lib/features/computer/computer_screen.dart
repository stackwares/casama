import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xterm/xterm.dart';

import 'computer_details.dart';
import 'computer_manage.dart';
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

/// A person's own computer, connected from the desktop app ("Use this computer for bots"). The
/// app doesn't offer what it can't do: live view, terminal, checkpoints, sleep, or switching
/// between desktop and headless (D-218).
bool isPersonalComputer(Computer c) => c.kind == ComputerKindEnum.local;

/// The state a person sees. A personal computer is connected or offline, never awake or asleep.
String computerStatusLabel(BuildContext context, Computer c) {
  if (!isPersonalComputer(c)) return computerStateLabel(context, c.state);
  final on = c.state == ComputerState.running || c.state == ComputerState.idle;
  return on
      ? context.l10n.personalComputerConnected
      : context.l10n.personalComputerOffline;
}

/// The team computer (or a bot's private one): state, screen, terminal, files, checkpoints.
class ComputerScreen extends ConsumerWidget {
  const ComputerScreen({super.key, this.botId, this.embedded = false, this.computerId, this.initialTab});
  final String? botId;
  final bool embedded;

  /// Opens this computer instead of a bot's (Settings > Computers, D-240).
  final String? computerId;

  /// The tab to open first ('screen', 'files', 'manage').
  final String? initialTab;

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
      loading: const _ComputerSkeleton(),
      data: (list) {
        final c = computerId != null
            ? list.where((x) => x.id == computerId).firstOrNull
            : computerForBot(
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
        return ComputerPanel(computer: c, embedded: embedded, initialTab: initialTab);
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

/// The computer panel still loading: the header card, the tabs and the screen stage, in the
/// same centered column as [ComputerPanel].
class _ComputerSkeleton extends StatelessWidget {
  const _ComputerSkeleton();

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return SkeletonScope(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // _ComputerHeader.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md,
                      AppSpace.xs,
                      AppSpace.md,
                      AppSpace.sm,
                    ),
                    child: SkeletonCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const SkeletonBone(
                                width: 46,
                                height: 46,
                                radius: AppRadius.tile,
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SkeletonText(
                                      style: text.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                      widthFactor: 0.55,
                                    ),
                                    const SizedBox(height: 4),
                                    SkeletonText(
                                      style: text.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.15,
                                      ),
                                      widthFactor: 0.7,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpace.xs),
                              const SkeletonBone(
                                width: 96,
                                height: 38,
                                radius: AppRadius.pill,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: context.appColors.hairline,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const SkeletonBone(width: 14, height: 14, radius: 7),
                              const SizedBox(width: AppSpace.xs),
                              Expanded(
                                child: SkeletonText(
                                  style: text.bodySmall,
                                  widthFactor: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // _ComputerTabs with the Advanced toggle beside them.
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpace.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: SkeletonBone(height: 46, radius: AppRadius.pill),
                        ),
                        SizedBox(width: AppSpace.xs),
                        SkeletonBone(width: 46, height: 46, radius: 23),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  // _ScreenStage: the monitor, its stand, the help line and the button.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.md,
                          AppSpace.lg,
                          AppSpace.md,
                          AppSpace.xl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AspectRatio(
                              aspectRatio: 16 / 10,
                              child: SkeletonBone(
                                height: double.infinity,
                                radius: AppRadius.card,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const SkeletonBone(
                              width: 64,
                              height: 5,
                              radius: AppRadius.pill,
                            ),
                            const SizedBox(height: AppSpace.xl),
                            SkeletonText(
                              style: text.bodyMedium?.copyWith(height: 1.45),
                              widthFactor: 0.7,
                              center: true,
                            ),
                            const SizedBox(height: AppSpace.lg),
                            const SkeletonBone(
                              width: 180,
                              height: 48,
                              radius: AppRadius.pill,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    this.initialTab,
  });
  final Computer computer;

  /// The tab to open first; Screen otherwise.
  final String? initialTab;

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
  late var _tab = widget.initialTab ?? 'screen';
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
    if (old.computer.state != widget.computer.state ||
        resetRunning(old.computer) != resetRunning(widget.computer)) {
      _schedule();
    }
    // A reset this screen watched has finished: say so, with Undo (D-240).
    final was = old.computer.operation;
    final now = widget.computer.operation;
    if (was != null &&
        now != null &&
        was.startedAt == now.startedAt &&
        was.step != now.step &&
        now.step == ComputerOperationStepEnum.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) announceResetDone(context, ref, widget.computer);
      });
    }
  }

  bool _computerAwake(ComputerState s) =>
      s == ComputerState.running || s == ComputerState.idle;

  void _schedule() {
    _poll?.cancel();
    _poll = Timer.periodic(
      Duration(
        seconds:
            computerWaking(widget.computer.state) ||
                resetRunning(widget.computer)
            ? 3
            : 10,
      ),
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
    final personal = isPersonalComputer(computer);
    final resetting = resetRunning(computer);
    // Screen, Files and Manage always; Terminal once Advanced is opened here (D-182). Restore
    // points live in Manage now (D-240). A personal computer has only Screen, and Files while
    // it is online (D-218).
    final advanced = ref
        .watch(advancedOpenProvider)
        .contains(computerTabsAdvancedId);
    final tabIds = [
      for (final t in const ['screen', 'terminal', 'files', 'manage'])
        if (personal
            ? t == 'screen' || (t == 'files' && running)
            : advanced || t != 'terminal')
          t,
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
              _ComputerHeader(
                computer: computer,
                statusText: resetting
                    ? resetStatusText(context, computer.operation!)
                    : _action == 'start'
                    ? l10n.stateStarting
                    : _action == 'sleep'
                    ? l10n.computerGoingToSleep
                    : computerStatusLabel(context, computer),
                running: running,
                busy: waking || _action == 'sleep' || resetting,
                failed: failed,
                // CPU, memory and disk while it's on; a tap opens Manage (D-240).
                footer: personal || !running || resetting
                    ? null
                    : Builder(
                        builder: (tabContext) => ComputerVitalsStrip(
                          computerId: computer.id,
                          onTap: () {
                            final i = _tabIds.indexOf('manage');
                            if (i >= 0) {
                              DefaultTabController.of(tabContext).animateTo(i);
                            }
                          },
                        ),
                      ),
                // A personal computer is on while the desktop app is connected (D-218).
                action: personal || resetting
                    ? null
                    : running
                    ? _HeaderAction(
                        key: const Key('computerSleep'),
                        icon: LucideIcons.moon,
                        label: l10n.computerSleep,
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
                      )
                    : _HeaderAction(
                        key: const Key('computerStart'),
                        filled: true,
                        busy: waking,
                        icon: failed ? LucideIcons.rotateCw : LucideIcons.power,
                        label: waking
                            ? l10n.stateStarting
                            : (failed ? l10n.retry : l10n.computerWake),
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
                      ),
              ),
              _ComputerTabs(
                tabIds: tabIds,
                advanced: personal ? null : advanced,
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
                          'manage' => ManageTab(computer: computer),
                          _ when personal => Column(
                            children: [
                              _ScreenNote(text: l10n.personalScreenNote),
                              Expanded(
                                child: running
                                    ? _ScreenTab(computerId: computer.id)
                                    : EmptyState(
                                        key: const Key('personalOffline'),
                                        icon: LucideIcons.wifiOff,
                                        message: l10n.personalComputerOfflineHelp,
                                      ),
                              ),
                            ],
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
                                      _ScreenNote(
                                        text: l10n.headlessScreenNoteSettings,
                                        settingsLink: true,
                                      ),
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

/// The computer at a glance: what it is, whether it's on, what it runs on, and the one thing to
/// do about it (wake or sleep), in a single card.
class _ComputerHeader extends StatelessWidget {
  const _ComputerHeader({
    required this.computer,
    required this.statusText,
    required this.running,
    required this.busy,
    required this.failed,
    this.action,
    this.footer,
  });
  final Computer computer;
  final String statusText;

  /// Under the details: the live vitals (D-240).
  final Widget? footer;
  final bool running;

  /// Waking or going to sleep: a small spinner next to the state.
  final bool busy;
  final bool failed;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final muted = scheme.onSurfaceVariant;
    final tone = failed
        ? colors.negative
        : (running || busy ? colors.working : muted);
    final personal = isPersonalComputer(computer);
    final desktop = computer.profile == ComputerProfileEnum.desktop;
    final system = computerSystemLine(context, computer, thisDevice: false);
    final activity = computerActivityLine(context, computer);
    // When it was last used matters more than its specs, so it leads (the specs may truncate).
    final details = [?activity, if (system.isNotEmpty) system].join(' · ');
    final error = failed ? computer.error : null;
    // With large text on a narrow screen the button goes under the name, so the state line
    // never gets squeezed.
    final stacked =
        MediaQuery.textScalerOf(context).scale(100) > 115 &&
        MediaQuery.sizeOf(context).width < 420;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _DeviceTile(
                  icon: personal
                      ? LucideIcons.laptop
                      : (desktop
                            ? LucideIcons.monitor
                            : LucideIcons.squareTerminal),
                  tone: tone,
                  lit: running || busy || failed,
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
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (busy)
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.6,
                                color: tone,
                              ),
                            )
                          else
                            _StatusDot(color: tone, lit: running || failed),
                          const SizedBox(width: 7),
                          Flexible(
                            child: StatusLabel(
                              key: const Key('computerState'),
                              text: statusText,
                              color: tone,
                            ),
                          ),
                          if (!personal) ...[
                            Text(
                              '  ·  ',
                              style: context.textTheme.labelMedium?.copyWith(
                                color: muted.withValues(alpha: 0.6),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                desktop
                                    ? l10n.profileDesktop
                                    : l10n.profileHeadless,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (action != null && !stacked) ...[
                  const SizedBox(width: AppSpace.xs),
                  action!,
                ],
              ],
            ),
            if (action != null && stacked) ...[
              const SizedBox(height: AppSpace.sm),
              action!,
            ],
            if (error != null) ...[
              const SizedBox(height: AppSpace.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.negative.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.row),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.circleAlert,
                        size: 16,
                        color: colors.negative,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          error,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.negative,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (details.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              Divider(height: 1, thickness: 1, color: colors.hairline),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    activity != null
                        ? LucideIcons.clock
                        : LucideIcons.cpu,
                    size: 14,
                    color: muted,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            ?footer,
          ],
        ),
      ),
    );
  }
}

/// The machine's icon in a soft tile that takes the state's color, glowing while it's on.
class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.icon, required this.tone, required this.lit});
  final IconData icon;
  final Color tone;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.duration,
      curve: AppMotion.curve,
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: lit ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: tone.withValues(alpha: lit ? 0.35 : 0.14)),
        boxShadow: [
          if (lit)
            BoxShadow(
              color: tone.withValues(alpha: 0.22),
              blurRadius: 16,
              spreadRadius: -2,
            ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: tone),
    );
  }
}

/// A small state dot; a soft halo while the computer is on.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.lit});
  final Color color;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          if (lit)
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 6,
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }
}

/// Wake or Sleep: compact, so it sits beside the name instead of crowding it.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.busy = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
      padding: const WidgetStatePropertyAll(
        EdgeInsetsDirectional.fromSTEB(12, 0, 14, 0),
      ),
      textStyle: WidgetStatePropertyAll(
        context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
    final iconWidget = busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 17);
    return filled
        ? FilledButton.tonalIcon(
            style: style,
            onPressed: onPressed,
            icon: iconWidget,
            label: Text(label),
          )
        : OutlinedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: iconWidget,
            label: Text(label),
          );
  }
}

/// Screen, Files, Manage (and Terminal with Advanced) as one segmented control that always
/// fits the width, so nothing scrolls or clips on a phone. [advanced] null: no toggle.
class _ComputerTabs extends StatelessWidget {
  const _ComputerTabs({required this.tabIds, required this.advanced});
  final List<String> tabIds;
  final bool? advanced;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final track = scheme.onSurface.withValues(
      alpha: context.isDark ? 0.07 : 0.05,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Icons join the labels when every segment has room for both.
                final segment = constraints.maxWidth / tabIds.length;
                final icons = segment >= 116;
                // Four segments on a phone: one smaller size for all, so no label shrinks alone.
                final base = segment < 96
                    ? context.textTheme.labelMedium
                    : context.textTheme.labelLarge;
                return Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: track,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: context.appColors.hairline),
                  ),
                  child: TabBar(
                    tabAlignment: TabAlignment.fill,
                    dividerHeight: 0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    labelColor: scheme.primary,
                    unselectedLabelColor: scheme.onSurfaceVariant,
                    labelStyle: base?.copyWith(fontWeight: FontWeight.w700),
                    unselectedLabelStyle: base?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    splashBorderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: (_) => HapticsHelper.light(),
                    tabs: [
                      for (final t in tabIds)
                        switch (t) {
                          'terminal' => _IconTab(
                            icon: LucideIcons.squareTerminal,
                            text: l10n.terminal,
                            showIcon: icons,
                          ),
                          'files' => _IconTab(
                            icon: LucideIcons.folder,
                            text: l10n.files,
                            showIcon: icons,
                          ),
                          'manage' => _IconTab(
                            icon: LucideIcons.settings2,
                            text: l10n.manageTab,
                            showIcon: icons,
                          ),
                          _ => _IconTab(
                            icon: LucideIcons.monitor,
                            text: l10n.screen,
                            showIcon: icons,
                          ),
                        },
                    ],
                  ),
                );
              },
            ),
          ),
          if (advanced != null) ...[
            const SizedBox(width: AppSpace.xs),
            _AdvancedTabsToggle(open: advanced!),
          ],
        ],
      ),
    );
  }
}

/// Beside the tabs: shows or hides the Terminal, remembered on this device like any
/// Advanced section (D-182).
class _AdvancedTabsToggle extends ConsumerWidget {
  const _AdvancedTabsToggle({required this.open});
  final bool open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final label = open
        ? l10n.computerAdvancedTabsHide
        : l10n.computerAdvancedTabsShow;
    return Semantics(
      toggled: open,
      label: l10n.advanced,
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: open
                ? scheme.primary.withValues(alpha: 0.2)
                : scheme.onSurface.withValues(
                    alpha: context.isDark ? 0.07 : 0.05,
                  ),
            border: Border.all(
              color: open
                  ? scheme.primary.withValues(alpha: 0.35)
                  : context.appColors.hairline,
            ),
          ),
          child: IconButton(
            key: const Key('advanced-$computerTabsAdvancedId'),
            onPressed: () {
              HapticsHelper.light();
              ref
                  .read(advancedOpenProvider.notifier)
                  .set(computerTabsAdvancedId, !open);
            },
            icon: Icon(
              LucideIcons.slidersHorizontal,
              size: 18,
              color: open ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
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

/// A segment's label, with its icon where there is room.
class _IconTab extends StatelessWidget {
  const _IconTab({
    required this.icon,
    required this.text,
    required this.showIcon,
  });
  final IconData icon;
  final String text;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 36,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
            Text(text, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

/// A desktop computer's Screen tab before the live view opens: a monitor showing a fresh
/// screenshot while the computer is on (so you see what the bot is doing at a glance), dark and
/// asleep otherwise. Tapping the monitor does what [action] does.
class _ScreenStage extends ConsumerStatefulWidget {
  const _ScreenStage({
    required this.computer,
    required this.message,
    required this.action,
    this.onTapScreen,
    this.waking = false,
  });
  final Computer computer;
  final String message;
  final Widget action;
  final VoidCallback? onTapScreen;
  final bool waking;

  @override
  ConsumerState<_ScreenStage> createState() => _ScreenStageState();
}

class _ScreenStageState extends ConsumerState<_ScreenStage> {
  Uint8List? _shot;
  Timer? _timer;

  bool get _awake =>
      widget.computer.state == ComputerState.running ||
      widget.computer.state == ComputerState.idle;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_ScreenStage old) {
    super.didUpdateWidget(old);
    final wasAwake =
        old.computer.state == ComputerState.running ||
        old.computer.state == ComputerState.idle;
    if (old.computer.id != widget.computer.id || wasAwake != _awake) _sync();
  }

  // Screenshots only while it's on: asking never wakes it, and a sleeping screen is dark anyway.
  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (!_awake) {
      _shot = null;
      return;
    }
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  Future<void> _load() async {
    final id = widget.computer.id;
    final png = await ref.read(backendProvider).screenshot(id);
    if (!mounted || png == null || !_awake || widget.computer.id != id) return;
    setState(() => _shot = png.isEmpty ? null : png);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final awake = _awake;
    final shot = _shot;
    // The screen itself is always dark, like a real monitor, in either theme.
    const glass = Color(0xFF0D0E13);
    final monitor = AspectRatio(
      aspectRatio: 16 / 10,
      child: Material(
        color: glass,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: awake
                ? scheme.primary.withValues(alpha: 0.35)
                : colors.hairline,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: widget.onTapScreen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.duration,
                child: shot != null
                    ? Image.memory(
                        shot,
                        key: const ValueKey('shot'),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : DecoratedBox(
                        key: ValueKey(awake),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.4),
                            radius: 1.1,
                            colors: [
                              scheme.primary.withValues(
                                alpha: awake ? 0.3 : 0.1,
                              ),
                              glass,
                            ],
                          ),
                        ),
                      ),
              ),
              if (shot != null)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x26000000), Color(0x8C000000)],
                    ),
                  ),
                ),
              Center(child: _disc(context, awake)),
            ],
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          // Near the top on phones (the tabs above lead into it); centered where it's tall.
          child: Align(
            alignment: constraints.maxHeight > 900
                ? Alignment.center
                : Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.lg,
                  AppSpace.md,
                  AppSpace.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    monitor,
                    const SizedBox(height: 8),
                    // The stand, so it reads as a computer at a glance.
                    Container(
                      width: 64,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.hairline,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    widget.action,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Play while it's on; a moon (or progress while it wakes) while it sleeps.
  Widget _disc(BuildContext context, bool awake) {
    final scheme = context.colorScheme;
    if (awake) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.5),
              blurRadius: 24,
            ),
          ],
        ),
        child: Icon(LucideIcons.play, size: 28, color: scheme.onPrimary),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      alignment: Alignment.center,
      child: widget.waking
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            )
          : const Icon(LucideIcons.moon, size: 24, color: Colors.white70),
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
    Future<void> open() async {
      await GoRouter.of(context).push('/computer/live?c=${computer.id}');
      // The live view may have woken it up.
      ref.invalidate(computersProvider);
    }

    return _ScreenStage(
      computer: computer,
      waking: computerWaking(computer.state),
      message: awake ? l10n.liveViewHelp : l10n.liveViewWakesHelp,
      onTapScreen: open,
      action: GlowButton.icon(
        key: const Key('openLiveView'),
        onPressed: open,
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
      return _ScreenStage(
        computer: c,
        message: l10n.liveViewHelp,
        onTapScreen: widget.onWatch,
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
      return _ScreenStage(
        computer: c,
        waking: waking,
        message: l10n.liveViewWakesHelp,
        onTapScreen: waking ? null : _wake,
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

/// A note above the screen. Headless computers only have a browser, and switching to a desktop
/// lives in Settings > Computers (one place for it, D-182), so theirs links there. A personal
/// computer's says it shows screenshots, not a live view (D-218).
class _ScreenNote extends StatelessWidget {
  const _ScreenNote({required this.text, this.settingsLink = false});
  final String text;
  final bool settingsLink;

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
                    text,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (settingsLink)
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
      // Empty: the screen went blank (the bot closed its page), so the placeholder returns.
      // Null: the request failed, so the last picture stays.
      if (png != null) _png = png.isEmpty ? null : png;
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
                  if (!snap.hasData) return _FilesSkeleton(side: side);
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

/// A folder still loading: one grouped card of rows, folders first (no subtitle, a chevron)
/// then files (a size line and a menu button), inside the same side padding as the list.
class _FilesSkeleton extends StatelessWidget {
  const _FilesSkeleton({required this.side});
  final double side;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: side),
          child: const SkeletonGroupedCard(
            rows: [
              SkeletonRow(subtitle: false, titleWidth: 0.32),
              SkeletonRow(subtitle: false, titleWidth: 0.24),
              _FileRowSkeleton(titleWidth: 0.46, subtitleWidth: 0.18),
              _FileRowSkeleton(titleWidth: 0.38, subtitleWidth: 0.14),
              _FileRowSkeleton(titleWidth: 0.52, subtitleWidth: 0.16),
              _FileRowSkeleton(titleWidth: 0.3, subtitleWidth: 0.12),
            ],
          ),
        ),
      ),
    );
  }
}

/// A file row still loading: a [GroupedTile] whose trailing is a 48-point menu button.
class _FileRowSkeleton extends StatelessWidget {
  const _FileRowSkeleton({required this.titleWidth, required this.subtitleWidth});
  final double titleWidth;
  final double subtitleWidth;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
      child: Row(
        children: [
          const SkeletonBone(width: 32, height: 32, radius: AppRadius.icon),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonText(
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  widthFactor: titleWidth,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: SkeletonText(
                    style: text.bodySmall?.copyWith(height: 1.3),
                    widthFactor: subtitleWidth,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          const SizedBox(
            width: 48,
            height: 48,
            child: Center(child: SkeletonBone(width: 4, height: 16, radius: 2)),
          ),
        ],
      ),
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
