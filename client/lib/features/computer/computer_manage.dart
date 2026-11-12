import 'dart:async';
import 'dart:math' as math;

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/haptics.dart';
import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../chat/chat_screen.dart' show confirmRestore;

// Managing a computer (D-240): what it's doing, fixing it when it misbehaves (restart, reset,
// erase), what it costs, when it sleeps, what takes up its space and what happened to it.

/// 8.1 GB, 512 MB, 12 KB.
String formatStorage(int bytes, String locale) {
  const k = 1024.0;
  if (bytes < k * k)
    return '${(bytes / k).humanizedCount(locale, decimalDigits: 0)} KB';
  if (bytes < k * k * k) {
    return '${(bytes / (k * k)).humanizedCount(locale, decimalDigits: bytes < 10 * k * k ? 1 : 0)} MB';
  }
  return '${(bytes / (k * k * k)).humanizedCount(locale, decimalDigits: 1)} GB';
}

/// A reset that is still going (the server gives up on one after 20 minutes).
bool resetRunning(Computer c) {
  final op = c.operation;
  if (op == null) return false;
  if (op.step == ComputerOperationStepEnum.done ||
      op.step == ComputerOperationStepEnum.failed)
    return false;
  return DateTime.now().difference(op.startedAt.toLocal()) <
      const Duration(minutes: 20);
}

/// The reset's steps, in order: saving the restore point only when one was asked for.
List<ComputerOperationStepEnum> _resetSteps(ComputerOperation op) => [
  if (op.checkpointId != null || op.step == ComputerOperationStepEnum.saving)
    ComputerOperationStepEnum.saving,
  ComputerOperationStepEnum.wiping,
  ComputerOperationStepEnum.restarting,
];

/// "Resetting… 2 of 3" for the header while a reset runs.
String resetStatusText(BuildContext context, ComputerOperation op) {
  final steps = _resetSteps(op);
  final i = math.max(0, steps.indexOf(op.step)) + 1;
  final l10n = context.l10n;
  return op.kind == ComputerOperationKindEnum.erase
      ? l10n.erasingStatus(i, steps.length)
      : l10n.resettingStatus(i, steps.length);
}

/// Puts the computer back the way it was before a reset (its "Before reset" restore point).
Future<void> undoReset(BuildContext context, WidgetRef ref, Computer c) async {
  final cp = c.operation?.checkpointId;
  if (cp == null) return;
  final l10n = context.l10n;
  final ok = await runGuarded(context, () async {
    await ref.read(backendProvider).restoreCheckpoint(c.id, cp);
    return true;
  });
  if (ok == true && context.mounted) {
    ref.invalidate(computersProvider);
    showSuccess(context, l10n.restoredPrevious);
  }
}

/// The toast when a reset this person watched finishes, with Undo.
void announceResetDone(BuildContext context, WidgetRef ref, Computer c) {
  final op = c.operation;
  if (op == null) return;
  final l10n = context.l10n;
  HapticsHelper.success();
  showToast(
    context,
    op.kind == ComputerOperationKindEnum.erase
        ? l10n.eraseDone
        : l10n.resetDone,
    kind: ToastKind.success,
    duration: const Duration(seconds: 8),
    action: op.checkpointId == null
        ? null
        : SnackBarAction(
            label: l10n.undo,
            onPressed: () => undoReset(context, ref, c),
          ),
  );
}

// ---------------------------------------------------------------------------------------------
// Vitals in the header

/// CPU, memory and disk as three small meters, refreshed every 15 seconds while it's on and the
/// app is in front. Asking never wakes the computer or keeps it awake.
class ComputerVitalsStrip extends ConsumerStatefulWidget {
  const ComputerVitalsStrip({super.key, required this.computerId, this.onTap});
  final String computerId;
  final VoidCallback? onTap;

  @override
  ConsumerState<ComputerVitalsStrip> createState() =>
      _ComputerVitalsStripState();
}

class _ComputerVitalsStripState extends ConsumerState<ComputerVitalsStrip> {
  Timer? _timer;
  ComputerVitals? _vitals;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void didUpdateWidget(ComputerVitalsStrip old) {
    super.didUpdateWidget(old);
    if (old.computerId != widget.computerId) _load();
  }

  Future<void> _load() async {
    final state = WidgetsBinding.instance.lifecycleState;
    if (_loaded && state != null && state != AppLifecycleState.resumed) return;
    final v = await ref
        .read(backendProvider)
        .computerVitals(widget.computerId)
        .catchError((Object _) => null);
    if (!mounted) return;
    setState(() {
      _vitals = v;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _vitals;
    if (_loaded && v == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.appColors;
    final locale = l10n.localeName;
    double frac(int used, int limit) =>
        limit <= 0 ? 0 : (used / limit).clamp(0.0, 1.0);
    final disk = v == null ? 0.0 : frac(v.diskUsedBytes, v.diskLimitBytes);
    final meters = [
      _Meter(
        key: const Key('vitalCpu'),
        label: l10n.vitalsCpu,
        value: v == null ? '–' : '${v.cpuPercent.round()}%',
        fraction: v == null ? 0 : (v.cpuPercent / 100).clamp(0.0, 1.0),
        color: colors.working,
      ),
      _Meter(
        key: const Key('vitalMemory'),
        label: l10n.vitalsMemory,
        value: v == null
            ? '–'
            : '${formatStorage(v.memoryUsedBytes, locale)} / ${formatStorage(v.memoryLimitBytes, locale)}',
        fraction: v == null ? 0 : frac(v.memoryUsedBytes, v.memoryLimitBytes),
        color: colors.info,
      ),
      _Meter(
        key: const Key('vitalDisk'),
        label: l10n.vitalsDisk,
        value: v == null
            ? '–'
            : '${formatStorage(v.diskUsedBytes, locale)} / ${formatStorage(v.diskLimitBytes, locale)}',
        fraction: disk,
        // Amber from 80% full and red from 90%, so a full disk never comes as a surprise.
        color: disk >= 0.9
            ? colors.negative
            : (disk >= 0.8 ? colors.warning : context.colorScheme.primary),
      ),
    ];
    return Semantics(
      button: widget.onTap != null,
      child: InkWell(
        key: const Key('computerVitals'),
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadius.row),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpace.sm),
          child: AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: v == null ? 0.45 : 1,
            child: Row(
              children: [
                for (var i = 0; i < meters.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpace.sm),
                  Expanded(child: meters[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });
  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        _Bar(fraction: fraction, color: color, height: 4),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: AppText.tabular,
          ),
        ),
      ],
    );
  }
}

/// A rounded track with an animated fill.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color, this.height = 6});
  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: context.appColors.hairline,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction),
          duration: AppMotion.of(context, const Duration(milliseconds: 500)),
          curve: Curves.easeOutCubic,
          builder: (_, f, _) => FractionallySizedBox(
            widthFactor: f,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// The Manage tab

class ManageTab extends ConsumerStatefulWidget {
  const ManageTab({super.key, required this.computer});
  final Computer computer;

  @override
  ConsumerState<ManageTab> createState() => _ManageTabState();
}

/// Reset results this person closed, by when the reset started (kept while the app runs).
final _dismissedResets = <String>{};

class _ManageTabState extends ConsumerState<ManageTab> {
  Future<ComputerUsage>? _usage;
  Future<List<ComputerHistoryEntry>>? _history;
  Future<List<ComputerBotUse>>? _bots;
  Future<List<Checkpoint>>? _points;
  Future<ComputerStorage?>? _storage;
  Future<List<ComputerProcess>?>? _processes;
  Timer? _timer;

  /// The action running now: restart, clean, archive, save, undo, sleep, or `stop:` and a pid.
  String? _busy;
  var _allPoints = false;
  var _allHistory = false;

  Computer get _c => widget.computer;
  bool get _running =>
      _c.state == ComputerState.running || _c.state == ComputerState.idle;

  @override
  void initState() {
    super.initState();
    _loadAll();
    // What's running changes by itself; the rest changes when someone does something.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      final state = WidgetsBinding.instance.lifecycleState;
      if (state != null && state != AppLifecycleState.resumed) return;
      if (_running && mounted) setState(_loadProcesses);
    });
  }

  @override
  void didUpdateWidget(ManageTab old) {
    super.didUpdateWidget(old);
    final o = old.computer;
    if (o.id != _c.id ||
        o.state != _c.state ||
        o.operation?.step != _c.operation?.step ||
        o.idleSleepMinutes != _c.idleSleepMinutes) {
      _loadAll();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadAll() {
    final b = ref.read(backendProvider);
    final id = _c.id;
    _usage = b.computerUsage(id);
    _history = b.computerHistory(id);
    _bots = b.computerBots(id);
    _points = b.checkpoints(id);
    _loadLive();
  }

  void _loadLive() {
    _storage = _running
        ? ref.read(backendProvider).computerStorage(_c.id)
        : Future.value(null);
    _loadProcesses();
  }

  void _loadProcesses() {
    _processes = _running
        ? ref.read(backendProvider).computerProcesses(_c.id)
        : Future.value(null);
  }

  Future<void> _refresh() async {
    setState(_loadAll);
    ref.invalidate(computersProvider);
    await Future.wait<Object?>(
      [
        _usage!,
        _history!,
        _storage!,
        _processes!,
      ].map((f) => f.catchError((Object _) => null)),
    );
  }

  /// Runs [call] with [action] showing as busy; reloads afterwards. Null when it failed.
  Future<T?> _act<T>(String action, Future<T> Function() call) async {
    setState(() => _busy = action);
    final r = await runGuarded(context, call);
    if (!mounted) return r;
    setState(() {
      _busy = null;
      _loadAll();
    });
    return r;
  }

  Future<void> _restart() async {
    final l10n = context.l10n;
    HapticsHelper.medium();
    final ok = await _act(
      'restart',
      () => ref.read(backendProvider).restartComputer(_c.id),
    );
    if (ok != null && mounted) {
      ref.invalidate(computersProvider);
      showSuccess(context, l10n.computerRestarted);
    }
  }

  Future<void> _reset({required bool erase}) async {
    final started = await showResetSheet(context, _c, erase: erase);
    if (started && mounted) ref.invalidate(computersProvider);
  }

  // The handlers below use the State's own context, so their mounted checks match it.
  @override
  Widget build(BuildContext _) {
    final op = _c.operation;
    final resetting = resetRunning(_c);
    final finished =
        op != null &&
        !resetting &&
        (op.step == ComputerOperationStepEnum.done ||
            op.step == ComputerOperationStepEnum.failed) &&
        DateTime.now().difference((op.finishedAt ?? op.startedAt).toLocal()) <
            const Duration(hours: 24) &&
        !_dismissedResets.contains(op.startedAt.toIso8601String());
    final fix = <Widget>[
      if (resetting)
        _ResetProgress(op: op!)
      else ...[
        if (finished)
          _ResetResult(
            op: op,
            busy: _busy == 'undo',
            onUndo: () async {
              setState(() => _busy = 'undo');
              await undoReset(context, ref, _c);
              if (!mounted) return;
              setState(() {
                _busy = null;
                _dismissedResets.add(op.startedAt.toIso8601String());
              });
            },
            onRetry: () =>
                _reset(erase: op.kind == ComputerOperationKindEnum.erase),
            onDismiss: () => setState(
              () => _dismissedResets.add(op.startedAt.toIso8601String()),
            ),
          ),
        if (finished) const SizedBox(height: AppSpace.sm),
        _FixIt(
          busy: _busy,
          onRestart: _restart,
          onReset: () => _reset(erase: false),
          onErase: () => _reset(erase: true),
        ),
      ],
    ];
    final fixAndUsage = <Widget>[
      ...fix,
      _UsageSection(usage: _usage!),
      _SleepTimer(
        minutes: _c.idleSleepMinutes ?? 5,
        busy: _busy == 'sleep',
        onPick: (m) async {
          final l10n = context.l10n;
          final label = m == 60
              ? l10n.sleepTimerHour
              : l10n.sleepTimerMinutes(m);
          HapticsHelper.selection();
          final ok = await _act(
            'sleep',
            () => ref
                .read(backendProvider)
                .updateComputer(_c.id, idleSleepMinutes: m),
          );
          if (ok != null && mounted) {
            ref.invalidate(computersProvider);
            showSuccess(context, l10n.sleepTimerSaved(label));
          }
        },
      ),
    ];
    final details = <Widget>[
      _StorageSection(
        storage: _storage!,
        running: _running,
        busy: _busy == 'clean',
        onClean: () async {
          final l10n = context.l10n;
          final r = await _act(
            'clean',
            () => ref.read(backendProvider).cleanComputerStorage(_c.id),
          );
          if (r != null && mounted)
            showSuccess(
              context,
              l10n.storageFreed(formatStorage(r.freedBytes, l10n.localeName)),
            );
        },
      ),
      _ProcessesSection(
        processes: _processes!,
        running: _running,
        busy: _busy,
        onStop: (p) async {
          final l10n = context.l10n;
          final name = processName(p);
          final ok = await showConfirm(
            context: context,
            title: l10n.processStopTitle(name),
            message: l10n.processStopMessage,
            confirmLabel: l10n.processStop,
            destructive: true,
            icon: LucideIcons.squareStop,
            confirmKey: const Key('confirmStopProcess'),
          );
          if (!ok || !mounted) return;
          final done = await _act('stop:${p.pid}', () async {
            await ref.read(backendProvider).stopComputerProcess(_c.id, p.pid);
            return true;
          });
          if (done == true && mounted)
            showSuccess(context, l10n.processStopped(name));
        },
      ),
      _UsedBy(bots: _bots!),
      _RestorePoints(
        points: _points!,
        showAll: _allPoints,
        busy: _busy == 'save',
        onShowAll: () => setState(() => _allPoints = true),
        onRestore: (cp) async {
          await confirmRestore(context, ref, _c.id, cp.id);
          if (mounted) setState(_loadAll);
        },
        onSave: () async {
          final l10n = context.l10n;
          final label = await showTextPrompt(
            context,
            title: l10n.restorePointSaveTitle,
            label: l10n.label,
            initial: l10n.restorePointDefaultLabel,
            submitLabel: l10n.save,
            icon: LucideIcons.bookmarkPlus,
          );
          if (label == null || label.trim().isEmpty || !mounted) return;
          final cp = await _act(
            'save',
            () =>
                ref.read(backendProvider).createCheckpoint(_c.id, label.trim()),
          );
          if (cp != null && mounted)
            showSuccess(context, l10n.restorePointSaved);
        },
      ),
      _History(
        history: _history!,
        showAll: _allHistory,
        onShowAll: () => setState(() => _allHistory = true),
      ),
      _YourData(
        computer: _c,
        busy: _busy == 'archive',
        onDownload: () async {
          final l10n = context.l10n;
          final origin = shareOrigin(context);
          final bytes = await _act(
            'archive',
            () => ref.read(backendProvider).downloadComputerArchive(_c.id),
          );
          if (!mounted) return;
          if (bytes == null) {
            if (_busy == null) showMessage(context, l10n.downloadNothing);
            return;
          }
          final name =
              '${_c.name.replaceAll(RegExp(r'[^\w.-]+'), '-')}-files.zip';
          await shareFiles(
            [XFile.fromData(bytes, name: name, mimeType: 'application/zip')],
            names: [name],
            origin: origin,
          );
        },
        onDelete: () async {
          final l10n = context.l10n;
          final ok = await showConfirm(
            context: context,
            title: l10n.deleteComputerTitle(_c.name),
            message: l10n.deleteComputerConfirm(_c.name),
            confirmLabel: l10n.delete,
            destructive: true,
          );
          if (!ok || !mounted) return;
          final done = await runGuarded(context, () async {
            await ref.read(backendProvider).deleteComputer(_c.id);
            return true;
          });
          if (done == true && mounted) ref.invalidate(computersProvider);
        },
      ),
    ];
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpace.xxl;
    // One column at the page's width, like the rest of the computer screen.
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const Key('manageList'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.xs,
          AppSpace.md,
          bottom,
        ),
        children: [...fixAndUsage, ...details],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Fixing it

/// "Not working right?": restart, reset, erase, in the order to try them.
class _FixIt extends StatelessWidget {
  const _FixIt({
    required this.busy,
    required this.onRestart,
    required this.onReset,
    required this.onErase,
  });
  final String? busy;
  final VoidCallback onRestart;
  final VoidCallback onReset;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final dark = context.isDark;
    final restarting = busy == 'restart';
    return Container(
      key: const Key('fixIt'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: dark ? 0.16 : 0.10),
            colors.info.withValues(alpha: dark ? 0.07 : 0.05),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.wrench, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  l10n.fixItTitle,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: AppSpace.sm),
            child: Text(
              l10n.fixItSubtitle,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          _FixStep(
            key: const Key('fixRestart'),
            n: 1,
            title: l10n.fixRestart,
            help: restarting ? l10n.computerRestarting : l10n.fixRestartHelp,
            action: l10n.fixRestart,
            color: scheme.primary,
            busy: restarting,
            onTap: busy == null ? onRestart : null,
          ),
          const SizedBox(height: 6),
          _FixStep(
            key: const Key('fixReset'),
            n: 2,
            title: l10n.fixResetSystem,
            help: l10n.fixResetSystemHelp,
            action: l10n.fixResetAction,
            color: scheme.primary,
            onTap: busy == null ? onReset : null,
          ),
          const SizedBox(height: 6),
          _FixStep(
            key: const Key('fixErase'),
            n: 3,
            title: l10n.fixErase,
            help: l10n.fixEraseHelp,
            action: l10n.fixEraseAction,
            color: colors.negative,
            onTap: busy == null ? onErase : null,
          ),
        ],
      ),
    );
  }
}

class _FixStep extends StatelessWidget {
  const _FixStep({
    super.key,
    required this.n,
    required this.title,
    required this.help,
    required this.action,
    required this.color,
    this.busy = false,
    this.onTap,
  });
  final int n;
  final String title;
  final String help;
  final String action;
  final Color color;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: context.isDark ? 0.45 : 0.7),
      borderRadius: BorderRadius.circular(AppRadius.row),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.row),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.onSurface.withValues(alpha: 0.07),
                ),
                child: Text(
                  '$n',
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      help,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              if (busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Text(
                  action,
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onTap == null ? scheme.onSurfaceVariant : color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The reset as it happens: each step ticks off, so the wait never looks stuck.
class _ResetProgress extends StatelessWidget {
  const _ResetProgress({required this.op});
  final ComputerOperation op;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final steps = _resetSteps(op);
    final current = steps.indexOf(op.step);
    final erase = op.kind == ComputerOperationKindEnum.erase;
    String label(ComputerOperationStepEnum s) => switch (s) {
      ComputerOperationStepEnum.saving => l10n.resetStepSaving,
      ComputerOperationStepEnum.wiping =>
        erase ? l10n.resetStepWipingErase : l10n.resetStepWipingSystem,
      _ => l10n.resetStepRestarting,
    };
    return AppCard(
      key: const Key('resetProgress'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            resetStatusText(context, op),
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: i < current
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.positive.withValues(alpha: 0.18),
                            ),
                            child: Icon(
                              LucideIcons.check,
                              size: 13,
                              color: colors.positive,
                            ),
                          )
                        : i == current
                        ? Padding(
                            padding: const EdgeInsets.all(2),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: scheme.primary,
                            ),
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.hairline,
                                width: 2,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label(steps[i]),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: i == current
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: i > current ? scheme.onSurfaceVariant : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            l10n.resetLeaveHint,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// How the last reset ended: ready (with Undo) or failed (with Try again).
class _ResetResult extends StatelessWidget {
  const _ResetResult({
    required this.op,
    required this.busy,
    required this.onUndo,
    required this.onRetry,
    required this.onDismiss,
  });
  final ComputerOperation op;
  final bool busy;
  final VoidCallback onUndo;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final failed = op.step == ComputerOperationStepEnum.failed;
    final tone = failed ? colors.negative : colors.positive;
    final erase = op.kind == ComputerOperationKindEnum.erase;
    return AppCard(
      key: const Key('resetResult'),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
      color: tone.withValues(alpha: context.isDark ? 0.10 : 0.07),
      borderColor: tone.withValues(alpha: 0.28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              failed ? LucideIcons.circleAlert : LucideIcons.circleCheck,
              size: 20,
              color: tone,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failed
                      ? l10n.resetFailed
                      : (erase ? l10n.eraseDone : l10n.resetDone),
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  failed
                      ? (op.error ?? '')
                      : (op.checkpointId == null ? '' : l10n.resetUndoHint),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (failed || op.checkpointId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        key: Key(failed ? 'resetRetry' : 'resetUndo'),
                        onPressed: busy ? null : (failed ? onRetry : onUndo),
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                failed
                                    ? LucideIcons.rotateCw
                                    : LucideIcons.undo2,
                                size: 16,
                              ),
                        label: Text(failed ? l10n.retry : l10n.undo),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const Key('resetDismiss'),
            tooltip: l10n.close,
            onPressed: onDismiss,
            icon: Icon(LucideIcons.x, size: 18, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Picks how far to reset, says what stays and what goes, and asks for the name before erasing.
Future<bool> showResetSheet(
  BuildContext context,
  Computer computer, {
  required bool erase,
}) async =>
    await showAdaptiveSheet<bool>(
      context: context,
      dialogMaxWidth: 520,
      builder: (_) => _ResetSheet(computer: computer, erase: erase),
    ) ??
    false;

class _ResetSheet extends ConsumerStatefulWidget {
  const _ResetSheet({required this.computer, required this.erase});
  final Computer computer;
  final bool erase;

  @override
  ConsumerState<_ResetSheet> createState() => _ResetSheetState();
}

class _ResetSheetState extends ConsumerState<_ResetSheet> {
  late var _erase = widget.erase;
  var _savePoint = true;
  var _busy = false;
  final _name = TextEditingController();
  late final Future<List<ComputerBotUse>> _bots = ref
      .read(backendProvider)
      .computerBots(widget.computer.id);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _confirmed =>
      !_erase ||
      _name.text.trim().toLowerCase() ==
          widget.computer.name.trim().toLowerCase();

  Future<void> _submit() async {
    setState(() => _busy = true);
    final ok = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .resetComputer(
            widget.computer.id,
            erase: _erase,
            checkpoint: _savePoint,
          ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == null) return;
    HapticsHelper.heavy();
    Navigator.pop(context, true);
  }

  /// "Ava", "Ava and Scout", "Ava, Scout and Mo".
  static String _names(List<String> n) => n.length <= 1
      ? n.join()
      : '${n.sublist(0, n.length - 1).join(', ')} and ${n.last}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final danger = colors.negative;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xs,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.resetSheetTitle(widget.computer.name),
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          FutureBuilder<List<ComputerBotUse>>(
            future: _bots,
            builder: (context, snap) {
              final names = [
                for (final b in snap.data ?? const <ComputerBotUse>[]) b.name,
              ];
              return Text(
                names.isEmpty
                    ? l10n.resetSheetBusyNone
                    : l10n.resetSheetBusy(_names(names.take(3).toList())),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpace.md),
          _ResetOption(
            key: const Key('resetOptionSystem'),
            selected: !_erase,
            color: scheme.primary,
            icon: LucideIcons.rotateCcw,
            title: l10n.resetOptionSystem,
            help: l10n.resetOptionSystemHelp,
            onTap: () => setState(() => _erase = false),
          ),
          const SizedBox(height: AppSpace.xs),
          _ResetOption(
            key: const Key('resetOptionErase'),
            selected: _erase,
            color: danger,
            icon: LucideIcons.eraser,
            title: l10n.resetOptionErase,
            help: l10n.resetOptionEraseHelp,
            onTap: () => setState(() => _erase = true),
          ),
          const SizedBox(height: AppSpace.sm),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: Row(
              key: ValueKey(_erase),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _KeptList(
                    title: l10n.resetKept,
                    color: colors.positive,
                    icon: LucideIcons.check,
                    items: [
                      if (!_erase) l10n.resetKeptFiles,
                      l10n.resetKeptSettings,
                      l10n.resetKeptRestorePoints,
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: _KeptList(
                    title: l10n.resetRemoved,
                    color: danger,
                    icon: LucideIcons.minus,
                    items: [
                      if (_erase) l10n.resetRemovedFiles,
                      l10n.resetRemovedApps,
                      l10n.resetRemovedPrograms,
                      if (!_erase) l10n.resetRemovedCaches,
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          SwitchListTile.adaptive(
            key: const Key('resetSavePoint'),
            contentPadding: EdgeInsets.zero,
            value: _savePoint,
            onChanged: _busy ? null : (v) => setState(() => _savePoint = v),
            secondary: Icon(LucideIcons.lifeBuoy, color: scheme.primary),
            title: Text(
              l10n.resetSavePoint,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(l10n.resetSavePointHelp),
          ),
          if (_erase) ...[
            const SizedBox(height: AppSpace.xs),
            TextField(
              key: const Key('eraseConfirmField'),
              controller: _name,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.eraseTypeName(widget.computer.name),
                prefixIcon: const Icon(LucideIcons.keyboard, size: 18),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          FilledButton(
            key: const Key('resetConfirm'),
            style: _erase
                ? FilledButton.styleFrom(
                    backgroundColor: danger,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: _busy || !_confirmed ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _erase ? l10n.resetConfirmErase : l10n.resetConfirmSystem,
                  ),
          ),
          const SizedBox(height: AppSpace.xxs),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class _ResetOption extends StatelessWidget {
  const _ResetOption({
    super.key,
    required this.selected,
    required this.color,
    required this.icon,
    required this.title,
    required this.help,
    required this.onTap,
  });
  final bool selected;
  final Color color;
  final IconData icon;
  final String title;
  final String help;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: context.isDark ? 0.12 : 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(
            color: selected ? color : context.appColors.hairline,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: () {
            HapticsHelper.selection();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? color : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        help,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? color : scheme.onSurfaceVariant,
                      width: selected ? 5 : 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeptList extends StatelessWidget {
  const _KeptList({
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
  });
  final String title;
  final Color color;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.row),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 12, color: color),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: muted,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Usage and the sleep timer

class _UsageSection extends StatelessWidget {
  const _UsageSection({required this.usage});
  final Future<ComputerUsage> usage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.usageThisMonth),
        AppCard(
          key: const Key('usageCard'),
          padding: const EdgeInsets.all(14),
          child: FutureBuilder<ComputerUsage>(
            future: usage,
            builder: (context, snap) {
              final u = snap.data;
              if (u == null)
                return const SizedBox(
                  height: 92,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                );
              if (u.seconds == 0) {
                return Row(
                  children: [
                    Icon(
                      LucideIcons.moon,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        l10n.usageNone,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                );
              }
              final cost = u.costUsd.toDouble();
              final max = u.days.fold<int>(1, (m, d) => math.max(m, d.seconds));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: l10n.usageDuration(
                        u.seconds ~/ 3600,
                        (u.seconds % 3600) ~/ 60,
                      ),
                      children: [
                        if (cost > 0)
                          TextSpan(
                            text:
                                '  ·  ${cost < 0.01 ? '<\$0.01' : '\$${cost.toStringAsFixed(2)}'}',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    key: const Key('usageTotal'),
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      fontFeatures: AppText.tabular,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  SizedBox(
                    height: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < u.days.length; i++) ...[
                          if (i > 0) const SizedBox(width: 3),
                          Expanded(
                            child: Tooltip(
                              message:
                                  '${u.days[i].date}: ${l10n.usageDuration(u.days[i].seconds ~/ 3600, (u.days[i].seconds % 3600) ~/ 60)}',
                              child: Container(
                                height: math.max(
                                  3,
                                  40 * u.days[i].seconds / max,
                                ),
                                decoration: BoxDecoration(
                                  color: u.days[i].seconds == 0
                                      ? context.appColors.hairline
                                      : scheme.primary.withValues(
                                          alpha: i == u.days.length - 1
                                              ? 1
                                              : 0.4,
                                        ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                    bottom: Radius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    l10n.usageCostNote,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SleepTimer extends StatelessWidget {
  const _SleepTimer({
    required this.minutes,
    required this.busy,
    required this.onPick,
  });
  final int minutes;
  final bool busy;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.sleepTimerTitle,
          trailing: busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  for (final m in const [5, 15, 30, 60])
                    ChoiceChip(
                      key: Key('sleep-$m'),
                      label: Text(
                        m == 60
                            ? l10n.sleepTimerHour
                            : l10n.sleepTimerMinutes(m),
                        style: TextStyle(
                          color: m == minutes
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontWeight: m == minutes
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      selected: m == minutes,
                      showCheckmark: false,
                      selectedColor: scheme.primary,
                      // The picked one stays enabled so it reads clearly; tapping it again does nothing.
                      onSelected: busy
                          ? null
                          : (_) {
                              if (m != minutes) onPick(m);
                            },
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.sleepTimerHelp,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Storage and programs

/// A short note in place of live details while the computer sleeps.
class _AsleepNote extends StatelessWidget {
  const _AsleepNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurfaceVariant;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(LucideIcons.moon, size: 18, color: muted),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageSection extends StatelessWidget {
  const _StorageSection({
    required this.storage,
    required this.running,
    required this.busy,
    required this.onClean,
  });
  final Future<ComputerStorage?> storage;
  final bool running;
  final bool busy;
  final VoidCallback onClean;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final locale = l10n.localeName;
    final palette = {
      StorageCategoryIdEnum.files: (scheme.primary, l10n.storageFiles),
      StorageCategoryIdEnum.apps: (colors.info, l10n.storageApps),
      StorageCategoryIdEnum.caches: (colors.warning, l10n.storageCaches),
      StorageCategoryIdEnum.browser: (colors.positive, l10n.storageBrowser),
      StorageCategoryIdEnum.other: (colors.idle, l10n.storageOther),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.storageTitle),
        if (!running)
          _AsleepNote(text: l10n.storageAsleep)
        else
          FutureBuilder<ComputerStorage?>(
            future: storage,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const AppCard(
                  child: SizedBox(
                    height: 84,
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                );
              }
              final s = snap.data;
              if (s == null) return _AsleepNote(text: l10n.storageAsleep);
              final limit = math.max(s.limitBytes, s.usedBytes);
              final parts = [
                for (final c in s.categories)
                  if (c.bytes > 0) c,
              ];
              return AppCard(
                key: const Key('storageCard'),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: formatStorage(s.usedBytes, locale),
                        children: [
                          TextSpan(
                            text:
                                '  ${l10n.storageOf(formatStorage(s.limitBytes, locale))}',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            for (final c in parts)
                              Flexible(
                                flex: math.max(
                                  1,
                                  (1000 * c.bytes / limit).round(),
                                ),
                                child: Container(color: palette[c.id]!.$1),
                              ),
                            Flexible(
                              flex: math.max(
                                1,
                                (1000 * (limit - s.usedBytes) / limit).round(),
                              ),
                              child: Container(color: colors.hairline),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: 4,
                      children: [
                        for (final c in parts)
                          _Legend(
                            color: palette[c.id]!.$1,
                            text:
                                '${palette[c.id]!.$2} ${formatStorage(c.bytes, locale)}',
                          ),
                        _Legend(
                          color: colors.hairline,
                          text:
                              '${l10n.storageFree} ${formatStorage(math.max(0, s.limitBytes - s.usedBytes), locale)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    if (s.cleanableBytes > 0)
                      FilledButton.tonalIcon(
                        key: const Key('freeUpSpace'),
                        onPressed: busy ? null : onClean,
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.sparkles, size: 16),
                        label: Text(
                          l10n.storageFreeUp(
                            formatStorage(s.cleanableBytes, locale),
                          ),
                        ),
                      )
                    else
                      Text(
                        l10n.storageNothingToClean,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        text,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontFeatures: AppText.tabular,
        ),
      ),
    ],
  );
}

/// A program's everyday name: "Chrome" rather than "chrome".
String processName(ComputerProcess p) => switch (p.name) {
  'chrome' || 'chromium' || 'chrome_crashpad' => 'Chrome',
  'python3' || 'python' => 'Python',
  'node' => 'Node.js',
  'bash' || 'sh' || 'zsh' => 'Shell',
  'soffice.bin' || 'soffice' => 'LibreOffice',
  'ffmpeg' => 'FFmpeg',
  _ => p.name,
};

IconData _processIcon(ComputerProcess p) => switch (p.name) {
  'chrome' || 'chromium' || 'chrome_crashpad' => LucideIcons.globe,
  'python3' || 'python' || 'node' => LucideIcons.code,
  'bash' || 'sh' || 'zsh' => LucideIcons.squareTerminal,
  'soffice.bin' || 'soffice' => LucideIcons.fileText,
  'ffmpeg' => LucideIcons.film,
  _ => LucideIcons.cog,
};

/// 3 min, 2 h, 4 d.
String _duration(BuildContext context, int seconds) {
  final l10n = context.l10n;
  if (seconds < 3600) return l10n.durationMinutes(math.max(1, seconds ~/ 60));
  if (seconds < 86400) return l10n.durationHours(seconds ~/ 3600);
  return l10n.durationDays(seconds ~/ 86400);
}

class _ProcessesSection extends StatelessWidget {
  const _ProcessesSection({
    required this.processes,
    required this.running,
    required this.busy,
    required this.onStop,
  });
  final Future<List<ComputerProcess>?> processes;
  final bool running;
  final String? busy;
  final ValueChanged<ComputerProcess> onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return FutureBuilder<List<ComputerProcess>?>(
      future: processes,
      builder: (context, snap) {
        final mine = [
          for (final p in snap.data ?? const <ComputerProcess>[])
            if (!p.system) p,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: l10n.processesTitle,
              count: mine.isEmpty ? null : '${mine.length}',
            ),
            if (!running)
              _AsleepNote(text: l10n.processesAsleep)
            else if (snap.connectionState != ConnectionState.done &&
                snap.data == null)
              const AppCard(
                child: SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
              )
            else if (mine.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.circleCheck,
                      size: 18,
                      color: context.appColors.positive,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        l10n.processesNone,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              GroupedCard(
                dividerIndent: 56,
                children: [
                  for (final p in mine.take(8))
                    Padding(
                      key: Key('process-${p.pid}'),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.md,
                        10,
                        AppSpace.xs,
                        10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: scheme.onSurface.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(
                                AppRadius.icon,
                              ),
                            ),
                            child: Icon(
                              _processIcon(p),
                              size: 17,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  processName(p),
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  p.command,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.mono.copyWith(
                                    fontSize: 11.5,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  l10n.processLine(
                                    _duration(context, p.elapsedSeconds),
                                    p.cpuPercent.toStringAsFixed(
                                      p.cpuPercent < 10 ? 1 : 0,
                                    ),
                                    formatStorage(
                                      p.memoryBytes,
                                      l10n.localeName,
                                    ),
                                  ),
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontFeatures: AppText.tabular,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (busy == 'stop:${p.pid}')
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              key: Key('stop-${p.pid}'),
                              tooltip: l10n.processStop,
                              onPressed: busy == null ? () => onStop(p) : null,
                              icon: Icon(
                                LucideIcons.squareStop,
                                size: 20,
                                color: context.appColors.negative,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Bots, restore points, history and your data

class _UsedBy extends ConsumerWidget {
  const _UsedBy({required this.bots});
  final Future<List<ComputerBotUse>> bots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return FutureBuilder<List<ComputerBotUse>>(
      future: bots,
      builder: (context, snap) {
        final list = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: l10n.usedByTitle,
              count: list == null || list.isEmpty ? null : '${list.length}',
            ),
            if (list == null)
              const AppCard(
                child: SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
              )
            else if (list.isEmpty)
              _AsleepNoteLike(icon: LucideIcons.bot, text: l10n.usedByNone)
            else
              GroupedCard(
                children: [
                  for (final b in list)
                    GroupedTile(
                      key: Key('usedBy-${b.botId}'),
                      icon: LucideIcons.bot,
                      leading: BotAvatar(
                        name: b.name,
                        avatar: ref.watch(botProvider(b.botId))?.avatarUrl,
                        size: 32,
                      ),
                      title: b.name,
                      subtitle: b.lastActiveAt == null
                          ? l10n.botNeverActive
                          : l10n.botLastActive(
                              relativeTime(b.lastActiveAt!, context),
                            ),
                      onTap: () => context.push('/bots/${b.botId}/settings'),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _AsleepNoteLike extends StatelessWidget {
  const _AsleepNoteLike({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurfaceVariant;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestorePoints extends StatelessWidget {
  const _RestorePoints({
    required this.points,
    required this.showAll,
    required this.busy,
    required this.onShowAll,
    required this.onRestore,
    required this.onSave,
  });
  final Future<List<Checkpoint>> points;
  final bool showAll;
  final bool busy;
  final VoidCallback onShowAll;
  final ValueChanged<Checkpoint> onRestore;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return FutureBuilder<List<Checkpoint>>(
      future: points,
      builder: (context, snap) {
        final list = snap.data ?? const <Checkpoint>[];
        final shown = showAll ? list : list.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: l10n.restorePointsTitle,
              count: list.isEmpty ? null : '${list.length}',
            ),
            GroupedCard(
              children: [
                if (snap.connectionState == ConnectionState.done &&
                    list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      l10n.restorePointsNone,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (final cp in shown)
                  GroupedTile(
                    key: Key('restorePoint-${cp.id}'),
                    icon: LucideIcons.history,
                    title: cp.label,
                    subtitle: [
                      relativeTime(cp.createdAt, context),
                      if (cp.size > 0) formatStorage(cp.size, l10n.localeName),
                    ].join(' · '),
                    trailing: TextButton(
                      onPressed: () => onRestore(cp),
                      child: Text(l10n.restore),
                    ),
                  ),
                if (!showAll && list.length > 3)
                  GroupedTile(
                    key: const Key('restorePointsAll'),
                    icon: LucideIcons.chevronsDown,
                    title: l10n.restorePointsShowAll(list.length),
                    onTap: onShowAll,
                    showChevron: false,
                  ),
                GroupedTile(
                  key: const Key('saveRestorePoint'),
                  icon: LucideIcons.bookmarkPlus,
                  title: l10n.restorePointSaveNow,
                  trailing: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: busy ? null : onSave,
                  showChevron: false,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _History extends ConsumerWidget {
  const _History({
    required this.history,
    required this.showAll,
    required this.onShowAll,
  });
  final Future<List<ComputerHistoryEntry>> history;
  final bool showAll;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final me = ref.watch(backendProvider).userId;
    String label(ComputerHistoryEntry e) {
      final m = e.metadata;
      return switch (e.action) {
        'computer.started' => l10n.historyStarted,
        'computer.slept' =>
          m['reason'] == 'idle' ? l10n.historySleptIdle : l10n.historySlept,
        'computer.restarted' => l10n.historyRestarted,
        'computer.reset' => l10n.historyReset,
        'computer.erased' => l10n.historyErased,
        'checkpoint.created' =>
          m['label'] is String
              ? '${l10n.historyCheckpointCreated}: ${m['label']}'
              : l10n.historyCheckpointCreated,
        'checkpoint.restored' => l10n.historyCheckpointRestored,
        'computer.storage_cleaned' =>
          m['freed_bytes'] is num && (m['freed_bytes'] as num) > 0
              ? l10n.historyStorageCleaned(
                  formatStorage(
                    (m['freed_bytes'] as num).toInt(),
                    l10n.localeName,
                  ),
                )
              : l10n.historyStorageCleanedPlain,
        'computer.process_stopped' => l10n.historyProcessStopped(
          m['name'] is String ? m['name'] as String : '${m['pid'] ?? ''}',
        ),
        'computer.updated' => l10n.historyUpdated,
        _ => e.action,
      };
    }

    Color tone(String action) => switch (action) {
      'computer.started' => colors.working,
      'computer.reset' || 'computer.erased' => colors.warning,
      'checkpoint.created' || 'checkpoint.restored' => colors.info,
      'computer.process_stopped' => colors.negative,
      _ => colors.idle,
    };
    return FutureBuilder<List<ComputerHistoryEntry>>(
      future: history,
      builder: (context, snap) {
        final list = snap.data ?? const <ComputerHistoryEntry>[];
        final shown = showAll ? list : list.take(6).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.historyTitle),
            AppCard(
              key: const Key('historyCard'),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child:
                  snap.connectionState != ConnectionState.done &&
                      snap.data == null
                  ? const SizedBox(
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    )
                  : list.isEmpty
                  ? Text(
                      l10n.historyNone,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < shown.length; i++)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 14,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 2,
                                        height: 7,
                                        color: i == 0
                                            ? Colors.transparent
                                            : colors.hairline,
                                      ),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: tone(shown[i].action),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          color: i == shown.length - 1
                                              ? Colors.transparent
                                              : colors.hairline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Text.rich(
                                      TextSpan(
                                        text: label(shown[i]),
                                        children: [
                                          TextSpan(
                                            text:
                                                '  ·  ${[if (shown[i].actorType == ComputerHistoryEntryActorTypeEnum.user && shown[i].actorId == me) l10n.historyYou else if (shown[i].actorName != null) shown[i].actorName!, relativeTime(shown[i].createdAt, context)].join(' · ')}',
                                            style: TextStyle(
                                              color: scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!showAll && list.length > shown.length)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              key: const Key('historyAll'),
                              onPressed: onShowAll,
                              child: Text(
                                l10n.restorePointsShowAll(list.length),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _YourData extends StatelessWidget {
  const _YourData({
    required this.computer,
    required this.busy,
    required this.onDownload,
    required this.onDelete,
  });
  final Computer computer;
  final bool busy;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.yourDataTitle),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('downloadAllFiles'),
              icon: LucideIcons.download,
              title: l10n.downloadAllFiles,
              subtitle: l10n.downloadAllFilesHelp,
              trailing: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: busy ? null : onDownload,
              showChevron: false,
            ),
            // The team computer can't be deleted; private ones can.
            if (computer.kind != ComputerKindEnum.team)
              GroupedTile(
                key: const Key('deleteComputer'),
                icon: LucideIcons.trash2,
                title: l10n.delete,
                subtitle: l10n.deleteComputerHelp,
                destructive: true,
                onTap: onDelete,
                showChevron: false,
              ),
          ],
        ),
      ],
    );
  }
}
