import 'dart:async';

import 'package:casama_sdk/casama_link.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics.dart';
import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/server_address.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/motion.dart';
import '../../ui/app_card.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/revealable.dart';
import '../link/keep_awake.dart';
import '../link/link_screen.dart';
import '../settings/about_you_screen.dart';
import '../settings/model_keys_screen.dart';
import 'docker_check.dart';
import 'guided_setup.dart';
import 'local_server.dart';
import 'setup_art.dart';

/// The steps of the guided setup, in the order the page shows them.
enum SetupStage { docker, server, account, model, phone }

bool get _onMac => defaultTargetPlatform == TargetPlatform.macOS;

/// Opens a page outside the app (tests replace it).
Future<void> Function(Uri url) setupOpenUrl = (url) async {
  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    // The button is still there to try again.
  }
};

/// Guided setup of a server on this computer (D-309), at `/setup`: Docker, the server, the
/// owner's account, a model, a phone. Each step shows one thing to do and moves on by itself when
/// it is done. Which step shows comes from what is true right now, so quitting half way, or the
/// app reconnecting to the new server, picks up where it stopped.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  DockerState? _docker;
  Timer? _dockerPoll;
  var _checkingDocker = false;

  /// Docker was missing or stopped when the page opened, so the server starts by itself once
  /// Docker is ready: the page said it would continue.
  var _waitedForDocker = false;

  /// The installer is running: Docker isn't looked at again until it stops.
  var _installing = false;

  /// The step after the account, once chosen: it stays put while its own state changes (a key was
  /// added, the address came up), and moves on only when the person says so.
  SetupStage? _later;
  var _leaving = false;

  /// The step on screen now. A step that is busy (the account being made) stays mounted while
  /// what comes next is still loading.
  SetupStage? _shown;

  @override
  void initState() {
    super.initState();
    if (!GuidedSetup.active.value) unawaited(GuidedSetup.begin());
    Analytics.log('guided_setup_opened', const {});
    unawaited(_checkDocker());
    _dockerPoll = Timer.periodic(const Duration(seconds: 3), (_) => _checkDocker());
  }

  @override
  void dispose() {
    _dockerPoll?.cancel();
    super.dispose();
  }

  /// Looks at Docker while the server isn't installed yet (nothing else needs to know).
  Future<void> _checkDocker() async {
    if (_checkingDocker || _installing || !mounted) return;
    if (ref.read(usingLocalServerProvider).value == true) {
      _dockerPoll?.cancel();
      return;
    }
    _checkingDocker = true;
    try {
      final state = await ref.read(dockerCheckProvider).state();
      if (!mounted) return;
      if (state != DockerState.ready) _waitedForDocker = true;
      if (state != _docker) setState(() => _docker = state);
    } finally {
      _checkingDocker = false;
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    final signedIn = ref.read(signedInProvider).value == true;
    // The home card reads these: what was just done must not show as still left.
    ref.invalidate(credentialsProvider);
    ref.invalidate(setupRemoteStateProvider);
    await GuidedSetup.end();
    if (mounted) context.go(signedIn ? '/bots' : '/sign-in');
  }

  Future<void> _skip(String step, SetupStage? next) async {
    Analytics.log('guided_setup_step', {'step': step, 'action': 'skipped'});
    await GuidedSetup.skip(step);
    if (!mounted) return;
    if (next == null) return _leave();
    setState(() => _later = next);
  }

  void _modelDone() {
    Analytics.log('guided_setup_step', const {'step': 'ai', 'action': 'done'});
    unawaited(GuidedSetup.unskip('ai'));
    setState(() => _later = SetupStage.phone);
  }

  Future<void> _finish() async {
    Analytics.log('guided_setup_step', const {'step': 'phone', 'action': 'done'});
    await GuidedSetup.unskip('phone');
    await _leave();
  }

  /// The step to show, or null while what decides it is still loading.
  SetupStage? _stage() {
    final local = ref.watch(usingLocalServerProvider);
    if (local.isLoading && !local.hasValue) return null;
    if (local.value != true) {
      if (_docker == null) return null;
      return _docker == DockerState.ready ? SetupStage.server : SetupStage.docker;
    }
    final signedIn = ref.watch(signedInProvider);
    if (signedIn.isLoading && !signedIn.hasValue) return null;
    if (signedIn.value != true) return SetupStage.account;
    final orgs = ref.watch(organizationsProvider);
    if (orgs.isLoading && !orgs.hasValue) return _shown == SetupStage.account ? SetupStage.account : null;
    if ((orgs.value ?? const []).isEmpty) return SetupStage.account;
    if (_later != null) return _later;
    final keys = ref.watch(credentialsProvider);
    if (keys.isLoading && !keys.hasValue) return _shown == SetupStage.account ? SetupStage.account : null;
    final skipped = GuidedSetup.skipped.value;
    if ((keys.value ?? const []).isEmpty && !skipped.contains('ai')) return _later = SetupStage.model;
    if (!skipped.contains('phone')) return _later = SetupStage.phone;
    // Nothing left: straight into the app.
    WidgetsBinding.instance.addPostFrameCallback((_) => _leave());
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stage = _stage();
    _shown = stage;
    final body = switch (stage) {
      null => const Padding(
        padding: EdgeInsets.all(AppSpace.xxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      SetupStage.docker => DockerStep(
        state: _docker!,
        check: ref.watch(dockerCheckProvider),
        onCheck: _checkDocker,
      ),
      SetupStage.server => ServerStep(
        autoStart: _waitedForDocker,
        onRunning: (running) => _installing = running,
        onDockerLost: () {
          _installing = false;
          unawaited(_checkDocker());
        },
        onConnected: () => ref.invalidate(usingLocalServerProvider),
      ),
      SetupStage.account => const AccountStep(),
      SetupStage.model => ModelStep(
        onDone: _modelDone,
        onSkip: () => _skip('ai', SetupStage.phone),
      ),
      SetupStage.phone => PhoneStep(
        onFinish: _finish,
        onSkip: () => _skip('phone', null),
      ),
    };
    final title = Text(
      _onMac ? l10n.setupTitleMac : l10n.setupTitle,
      textAlign: TextAlign.center,
      style: context.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.sm, AppSpace.xs, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            key: const Key('setupClose'),
            tooltip: l10n.close,
            onPressed: _leave,
            icon: const Icon(LucideIcons.x),
          ),
        ],
      ),
    );
    final step = AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.fast),
      child: KeyedSubtree(key: ValueKey(stage), child: body),
    );
    return Scaffold(
      key: const Key('setupScreen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= setupWideWidth;
            // The bar and the step, a little way down a tall window. Pinned, not centred, so the bar
            // stays put while the step below it grows or shrinks; it scrolls when it doesn't fit.
            final content = LayoutBuilder(
              builder: (context, area) => SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpace.xl,
                  wide ? (area.maxHeight * 0.08).clamp(AppSpace.sm, 80.0) : AppSpace.sm,
                  AppSpace.xl,
                  BottomPadding.of(context, minimum: AppSpace.xl),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          title,
                          const SizedBox(height: AppSpace.lg),
                          _Steps(
                            at: stage,
                            skipped: {
                              if (GuidedSetup.skipped.value.contains('ai')) SetupStage.model.index,
                              if (GuidedSetup.skipped.value.contains('phone')) SetupStage.phone.index,
                            },
                          ),
                          const SizedBox(height: AppSpace.xxl),
                          step,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            if (!wide) return Column(children: [header, Expanded(child: content)]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 9,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, 0, AppSpace.md),
                    child: SetupArtPane(stage: stage),
                  ),
                ),
                Expanded(
                  flex: 11,
                  child: Column(children: [header, Expanded(child: content)]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The five steps across the top: done ones ticked, the current one filled.
class _Steps extends StatelessWidget {
  const _Steps({required this.at, this.skipped = const {}});
  final SetupStage? at;

  /// Steps passed over with Skip for Now: a muted dash, not a tick.
  final Set<int> skipped;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final labels = [
      l10n.setupStepDocker,
      l10n.setupStepServer,
      l10n.setupStepAccount,
      l10n.setupStepModel,
      l10n.setupStepPhone,
    ];
    final current = at?.index ?? -1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, label) in labels.indexed)
          Expanded(
            child: Semantics(
              selected: i == current,
              value: i < current && skipped.contains(i) ? l10n.setupStepSkipped : null,
              child: Column(
                spacing: AppSpace.xxs,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 2, color: i == 0 ? Colors.transparent : (i <= current ? scheme.primary : scheme.outlineVariant)),
                      ),
                      Container(
                        key: Key('setupStep-$i'),
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= current && !(i < current && skipped.contains(i)) ? scheme.primary : Colors.transparent,
                          border: Border.all(color: i <= current ? scheme.primary : scheme.outlineVariant, width: 2),
                        ),
                        child: i < current && skipped.contains(i)
                            ? Icon(LucideIcons.minus, key: Key('setupStepSkipped-$i'), size: 15, color: scheme.primary)
                            : i < current
                            ? Icon(LucideIcons.check, size: 15, color: scheme.onPrimary)
                            : Text(
                                '${i + 1}',
                                style: context.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: i == current ? scheme.onPrimary : scheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i == labels.length - 1 ? Colors.transparent : (i < current ? scheme.primary : scheme.outlineVariant),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: i == current ? scheme.onSurface : scheme.onSurfaceVariant,
                      fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A step's heading and the line under it.
class _Heading extends StatelessWidget {
  const _Heading(this.title, this.body, {this.icon});
  final String title;
  final String? body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpace.xs,
    children: [
      if (icon != null)
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(icon, size: 32, color: context.colorScheme.primary),
        ),
      Text(
        title,
        style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      ),
      if (body != null)
        Text(
          body!,
          style: context.textTheme.bodyLarge?.copyWith(color: context.colorScheme.onSurfaceVariant, height: 1.4),
        ),
    ],
  );
}

/// A line that something is being waited for.
class _Waiting extends StatelessWidget {
  const _Waiting(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    spacing: AppSpace.sm,
    children: [
      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      Expanded(
        child: Text(text, style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant)),
      ),
    ],
  );
}

Widget _primary({required Key key, required VoidCallback? onPressed, required String label, IconData? icon, bool busy = false}) => SizedBox(
  height: 52,
  child: GlowButton(
    key: key,
    onPressed: busy ? null : onPressed,
    child: busy
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.xs,
            children: [
              if (icon != null) Icon(icon, size: 20),
              Flexible(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
  ),
);

/// Step 1: Docker isn't ready. Says what is wrong, gives the one button or command that fixes it,
/// and waits; the page moves on when [DockerState.ready] comes.
class DockerStep extends StatefulWidget {
  const DockerStep({super.key, required this.state, required this.check, required this.onCheck});
  final DockerState state;
  final DockerCheck check;
  final Future<void> Function() onCheck;

  @override
  State<DockerStep> createState() => _DockerStepState();
}

/// The troubleshooting guide's Docker entries, linked from the "taking a while" help.
final dockerHelpUrl = Uri.parse('https://docs.casama.ai/self-hosting/troubleshooting#docker-is-not-running-or-this-user-cannot-use-it');
final dockerComposeHelpUrl = Uri.parse('https://docs.casama.ai/self-hosting/troubleshooting#docker-compose-v2-is-needed');

class _DockerStepState extends State<DockerStep> {
  var _opening = false;
  double? _freeGb;

  /// How long a wait goes before the page offers help instead of only a spinner.
  static const slowAfter = Duration(seconds: 45);
  Timer? _slowTimer;
  var _slow = false;
  var _rechecking = false;

  void _startSlowTimer() {
    _slowTimer?.cancel();
    _slow = false;
    _slowTimer = Timer(slowAfter, () {
      if (!mounted) return;
      Analytics.log('guided_setup_step', {'step': 'docker', 'action': 'slow', 'state': widget.state.name});
      setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  Future<void> _recheck() async {
    setState(() => _rechecking = true);
    // Try opening it again too: a Docker that was quit from its menu doesn't come back by itself.
    if (widget.state == DockerState.notRunning && widget.check.isMac) await widget.check.open();
    await widget.onCheck();
    if (mounted) setState(() => _rechecking = false);
  }

  @override
  void initState() {
    super.initState();
    _startSlowTimer();
    // Installed but closed: open it for them, once. Docker shows its own window if it needs a yes.
    if (widget.state == DockerState.notRunning && widget.check.isMac) unawaited(_open());
    unawaited(widget.check.freeDiskGb().then((gb) {
      if (mounted) setState(() => _freeGb = gb);
    }));
  }

  @override
  void didUpdateWidget(DockerStep old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _startSlowTimer();
    // Just installed: open it without another click.
    if (old.state == DockerState.notInstalled && widget.state == DockerState.notRunning && widget.check.isMac && !_opening) {
      unawaited(_open());
    }
  }

  Future<void> _open() async {
    setState(() => _opening = true);
    final ok = await widget.check.open();
    if (mounted && !ok) setState(() => _opening = false);
    unawaited(widget.onCheck());
  }

  Future<void> _download() async {
    Analytics.log('guided_setup_step', const {'step': 'docker', 'action': 'download'});
    await setupOpenUrl(await widget.check.downloadUrl());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mac = widget.check.isMac;
    final low = _freeGb != null && _freeGb! < 12;
    final children = switch (widget.state) {
      DockerState.notInstalled => [
        _Heading(l10n.setupDockerMissingTitle, mac ? l10n.setupDockerMissingBodyMac : l10n.setupDockerMissingBodyLinux, icon: LucideIcons.container),
        _primary(
          key: const Key('setupGetDocker'),
          onPressed: _download,
          icon: mac ? LucideIcons.download : LucideIcons.externalLink,
          label: mac ? l10n.setupDockerGetMac : l10n.setupDockerGetLinux,
        ),
        if (mac)
          GroupedCard(
            children: [
              for (final (i, text) in [l10n.setupDockerStep1, l10n.setupDockerStep2, l10n.setupDockerStep3].indexed)
                GroupedTile(
                  icon: [LucideIcons.folderDown, LucideIcons.squareCheckBig, LucideIcons.undo2][i],
                  title: text,
                ),
            ],
          ),
        _Waiting(l10n.setupDockerWaiting, key: const Key('setupDockerWaiting')),
      ],
      DockerState.notRunning => [
        _Heading(l10n.setupDockerStoppedTitle, mac ? l10n.setupDockerStoppedBodyMac : l10n.setupDockerStoppedBodyLinux, icon: LucideIcons.container),
        if (mac && !_opening)
          _primary(key: const Key('setupOpenDocker'), onPressed: _open, icon: LucideIcons.play, label: l10n.setupDockerOpen)
        else if (!mac)
          const CommandNote(DockerCommands.start),
        _Waiting(_opening ? l10n.setupDockerOpening : l10n.setupDockerWaiting, key: const Key('setupDockerWaiting')),
      ],
      DockerState.noPermission => [
        _Heading(l10n.setupDockerPermissionTitle, l10n.setupDockerPermissionBody, icon: LucideIcons.lock),
        const CommandNote(DockerCommands.allowUser),
        _Waiting(l10n.setupDockerWaiting, key: const Key('setupDockerWaiting')),
      ],
      DockerState.noCompose => [
        _Heading(l10n.setupDockerComposeTitle, l10n.setupDockerComposeBody, icon: LucideIcons.container),
        _Waiting(l10n.setupDockerWaiting, key: const Key('setupDockerWaiting')),
      ],
      DockerState.ready => const <Widget>[],
    };
    return Column(
      key: Key('setupDocker-${widget.state.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.lg,
      children: [
        ...children,
        if (low)
          FormNote(
            l10n.setupDiskLow(_freeGb!.toStringAsFixed(0)),
            key: const Key('setupDiskLow'),
            icon: LucideIcons.hardDrive,
            color: context.colorScheme.error,
          ),
        if (_slow) _slowHelp(context),
      ],
    );
  }

  /// After [slowAfter]: what to look at, what the app saw, a check-again button and the guide.
  Widget _slowHelp(BuildContext context) {
    final l10n = context.l10n;
    final mac = widget.check.isMac;
    final tips = switch (widget.state) {
      DockerState.notInstalled => [
        (LucideIcons.appWindow, l10n.setupDockerSlowInstalled),
        (LucideIcons.boxes, l10n.setupDockerSlowOther),
      ],
      DockerState.notRunning when mac => [
        (LucideIcons.menu, l10n.setupDockerSlowMenuBar),
        (LucideIcons.squareCheckBig, l10n.setupDockerSlowTerms),
        (LucideIcons.rotateCcw, l10n.setupDockerSlowRestart),
        (LucideIcons.boxes, l10n.setupDockerSlowOther),
      ],
      _ => [(LucideIcons.terminal, l10n.setupDockerSlowTerminal)],
    };
    final detail = widget.check.lastDetail;
    return Column(
      key: const Key('setupDockerSlow'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        Text(l10n.setupDockerSlowTitle, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        GroupedCard(
          children: [for (final (icon, text) in tips) GroupedTile(icon: icon, title: text)],
        ),
        if (detail != null && detail.isNotEmpty)
          FormNote(l10n.setupDockerSlowSaw(detail), key: const Key('setupDockerSaw'), icon: LucideIcons.terminal),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.xs,
          children: [
            TextButton.icon(
              key: const Key('setupDockerRecheck'),
              onPressed: _rechecking ? null : _recheck,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.setupDockerRecheck),
            ),
            TextButton.icon(
              key: const Key('setupDockerGuide'),
              onPressed: () {
                Analytics.log('guided_setup_step', const {'step': 'docker', 'action': 'guide'});
                unawaited(setupOpenUrl(widget.state == DockerState.noCompose ? dockerComposeHelpUrl : dockerHelpUrl));
              },
              icon: const Icon(LucideIcons.externalLink, size: 18),
              label: Text(l10n.setupDockerGuide),
            ),
          ],
        ),
      ],
    );
  }
}

/// Step 2: downloads, installs and starts the server, then connects the app to it.
class ServerStep extends ConsumerStatefulWidget {
  const ServerStep({
    super.key,
    required this.autoStart,
    required this.onRunning,
    required this.onDockerLost,
    required this.onConnected,
  });

  /// Start without a click (the Docker step said the page continues by itself).
  final bool autoStart;
  final ValueChanged<bool> onRunning;

  /// Docker stopped answering: back to its step.
  final VoidCallback onDockerLost;

  /// The app is on the new server (only reached when connecting didn't rebuild the app).
  final VoidCallback onConnected;

  @override
  ConsumerState<ServerStep> createState() => _ServerStepState();
}

class _ServerStepState extends ConsumerState<ServerStep> {
  LocalServerProgress? _p;
  final _log = <String>[];
  var _part = 0;
  var _details = false;

  /// The images the installer has started and finished pulling, from Compose's "Image … Pulling"
  /// and "Image … Pulled" lines, so the longest part says how far along it is.
  final _pulling = <String>{};
  final _pulled = <String>{};
  static final _imageLine = RegExp(r'^Image (\S+) (Pulling|Pulled)\b');
  double? _freeGb;
  StreamSubscription<LocalServerProgress>? _sub;

  bool get _busy => _p != null && _p!.step != LocalServerStep.failed;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(dockerCheckProvider).freeDiskGb().then((gb) {
      if (mounted) setState(() => _freeGb = gb);
    }));
    if (widget.autoStart) WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  /// Which of the five parts the installer is on, from the headings it prints.
  int _partOf(LocalServerProgress p) {
    switch (p.step) {
      case LocalServerStep.checking || LocalServerStep.downloading:
        return 0;
      case LocalServerStep.starting || LocalServerStep.ready:
        return 4;
      case LocalServerStep.failed:
        return _part;
      case LocalServerStep.installing:
        final line = p.detail ?? '';
        if (line.contains('Waiting for')) return 4;
        if (line.contains('Starting the stack')) return 3;
        if (line.contains('Pulling') || line.contains('Building')) return 2;
        return _part < 1 ? 1 : _part;
    }
  }

  void _start() {
    if (_busy || !mounted) return;
    Analytics.log('guided_setup_step', const {'step': 'server', 'action': 'started'});
    widget.onRunning(true);
    setState(() {
      _log.clear();
      _pulling.clear();
      _pulled.clear();
      _part = 0;
      _p = const LocalServerProgress(LocalServerStep.checking);
    });
    _sub = ref.read(localServerManagerProvider).start().listen(
      (p) async {
        if (!mounted) return;
        setState(() {
          _p = p;
          _part = _partOf(p);
          if (p.step == LocalServerStep.installing && p.detail != null) {
            final m = _imageLine.firstMatch(p.detail!);
            if (m != null) (m.group(2) == 'Pulled' ? _pulled : _pulling).add(m.group(1)!);
            _log.add(p.detail!);
            if (_log.length > 8) _log.removeAt(0);
          }
        });
        if (p.step == LocalServerStep.failed) {
          widget.onRunning(false);
          Analytics.log('guided_setup_step', const {'step': 'server', 'action': 'failed'});
          // Docker went away under it: its own step says how to bring it back.
          if (await ref.read(dockerCheckProvider).state() != DockerState.ready && mounted) widget.onDockerLost();
        }
        if (p.step == LocalServerStep.ready && p.detail != null) {
          Analytics.log('guided_setup_step', const {'step': 'server', 'action': 'done'});
          await ServerAddress.save(p.detail!);
          // Rebuilds the whole app on the new server; the setup opens again at the next step.
          await onChangeServer?.call(p.detail!);
          if (mounted) {
            widget.onRunning(false);
            widget.onConnected();
          }
        }
      },
      onError: (Object e) {
        if (!mounted) return;
        widget.onRunning(false);
        setState(() => _p = LocalServerProgress(LocalServerStep.failed, detail: '$e'));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final p = _p;
    final failed = p?.step == LocalServerStep.failed;
    final parts = [
      l10n.setupServerStageDownload,
      l10n.setupServerStagePrepare,
      l10n.setupServerStageParts,
      l10n.setupServerStageStart,
      l10n.setupServerStageWait,
    ];
    final done = p?.step == LocalServerStep.ready;
    return Column(
      key: const Key('setupServer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.lg,
      children: [
        _Heading(l10n.setupServerTitle, l10n.setupServerBody, icon: LucideIcons.serverCog),
        if (p == null) ...[
          if (_freeGb != null && _freeGb! < 12)
            FormNote(
              l10n.setupDiskLow(_freeGb!.toStringAsFixed(0)),
              key: const Key('setupDiskLow'),
              icon: LucideIcons.hardDrive,
              color: scheme.error,
            ),
          _primary(key: const Key('setupStartServer'), onPressed: _start, icon: LucideIcons.play, label: l10n.setupServerStart),
        ] else ...[
          GroupedCard(
            children: [
              for (final (i, label) in parts.indexed)
                GroupedTile(
                  key: Key('setupServerPart-$i'),
                  icon: done || i < _part
                      ? LucideIcons.circleCheck
                      : (i == _part ? (failed ? LucideIcons.circleAlert : LucideIcons.loaderCircle) : LucideIcons.circle),
                  iconColor: done || i < _part
                      ? context.appColors.positive
                      : (i == _part ? (failed ? scheme.error : scheme.primary) : scheme.outline),
                  title: label,
                  subtitle: i == 2 && !done && _part <= 2
                      ? (_pulling.isEmpty
                            ? l10n.setupServerStagePartsNote
                            : l10n.setupServerPartsCount(_pulled.length, _pulling.union(_pulled).length))
                      : null,
                ),
            ],
          ),
          if (failed) ...[
            FormNote(
              p.detail ?? l10n.setupServerFailed,
              key: const Key('setupServerFailure'),
              icon: LucideIcons.triangleAlert,
              color: scheme.error,
            ),
            _primary(key: const Key('setupStartServer'), onPressed: _start, icon: LucideIcons.refreshCw, label: l10n.tryAgain),
          ] else ...[
            LinearProgressIndicator(
              key: const Key('setupServerBar'),
              value: p.step == LocalServerStep.downloading ? p.fraction : null,
            ),
            Text(
              done ? l10n.setupServerConnecting : l10n.setupServerKeepOpen,
              key: const Key('setupServerStatus'),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (_log.isNotEmpty) ...[
            Center(
              child: TextButton(
                key: const Key('setupDetails'),
                onPressed: () => setState(() => _details = !_details),
                child: Text(_details ? l10n.setupHideDetails : l10n.setupShowDetails),
              ),
            ),
            if (_details)
              Text(
                _log.join('\n'),
                key: const Key('setupLog'),
                style: AppText.mono.copyWith(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
          ],
        ],
      ],
    );
  }
}

/// Step 3: the owner's account, made right here (the server confirms it at once, so no email goes
/// out), then the first space and bot, as the welcome page would make them.
class AccountStep extends ConsumerStatefulWidget {
  const AccountStep({super.key});

  @override
  ConsumerState<AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends ConsumerState<AccountStep> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _signIn = false;
  var _busy = false;
  var _preparing = false;

  @override
  void initState() {
    super.initState();
    // Signed in already (the app was closed after the account was made): finish its space.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(signedInProvider).value == true) unawaited(_prepare(''));
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  static bool _validEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    final name = _name.text.trim();
    final signingIn = _signIn || !backend.signUpsOpen;
    final ok = await runGuarded(context, () async {
      if (signingIn) {
        await backend.signIn(_email.text.trim(), _password.text);
        return true;
      }
      // A server that wants the address confirmed sends an email; a local one signs in at once.
      return backend.signUp(_email.text.trim(), _password.text);
    });
    if (!mounted) return;
    if (ok == false) {
      setState(() => _busy = false);
      showMessage(context, context.l10n.checkInboxBody(_email.text.trim()));
      return;
    }
    if (ok != true) {
      setState(() => _busy = false);
      return;
    }
    HapticsHelper.success();
    Analytics.log('guided_setup_step', {'step': 'account', 'action': signingIn ? 'signed_in' : 'created'});
    await _prepare(signingIn ? '' : name);
    if (mounted) setState(() => _busy = false);
  }

  /// The name, then the first space and bot. The page moves on when the space is there.
  Future<void> _prepare(String name) async {
    if (_preparing) return;
    setState(() => _preparing = true);
    final backend = ref.read(backendProvider);
    await runGuarded(context, () async {
      ref.invalidate(organizationsProvider);
      if ((await ref.read(organizationsProvider.future)).isNotEmpty) return;
      if (name.isNotEmpty) {
        try {
          final about = await backend.aboutYou();
          await backend.saveAboutYou(about.copyWith(preferredName: name));
          ref.invalidate(aboutYouProvider);
        } catch (_) {
          // The name step asks again after the setup.
        }
      }
      final first = name.split(RegExp(r'\s+')).first;
      final w = await backend.startWelcome(firstName: first.isEmpty ? null : first);
      ref.read(selectedOrgIdProvider.notifier).select(w.orgId);
      ref.invalidate(organizationsProvider);
      await ref.read(organizationsProvider.future);
      ref.invalidate(botsProvider);
    });
    if (mounted) setState(() => _preparing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final backend = ref.watch(backendProvider);
    final closed = !backend.signUpsOpen;
    final signingIn = _signIn || closed;
    if (_preparing && !_busy) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
        child: _Waiting(l10n.setupAccountPreparing, key: const Key('setupAccountPreparing')),
      );
    }
    return Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          key: const Key('setupAccount'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            _Heading(
              signingIn ? l10n.setupAccountSignInTitle : l10n.setupAccountTitle,
              closed ? l10n.setupAccountClosed : (signingIn ? l10n.setupAccountSignInBody : l10n.setupAccountBody),
              icon: LucideIcons.userRound,
            ),
            if (!signingIn)
              TextFormField(
                key: const Key('setupName'),
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.setupAccountName, prefixIcon: const Icon(LucideIcons.userRound, size: 20)),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) => (v ?? '').trim().isEmpty ? l10n.setupAccountNameMissing : null,
              ),
            TextFormField(
              key: const Key('setupEmail'),
              controller: _email,
              autofocus: signingIn,
              decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(LucideIcons.atSign, size: 20)),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) => _validEmail((v ?? '').trim()) ? null : l10n.invalidEmail,
            ),
            Revealable(
              builder: (context, hidden, toggle) => TextFormField(
                key: const Key('setupPassword'),
                controller: _password,
                decoration: InputDecoration(labelText: l10n.password, prefixIcon: const Icon(LucideIcons.lock, size: 20), suffixIcon: toggle),
                obscureText: hidden,
                autofillHints: [signingIn ? AutofillHints.password : AutofillHints.newPassword],
                validator: (v) => (v ?? '').length >= 6 ? null : l10n.passwordTooShort,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            _primary(
              key: const Key('setupAccountSubmit'),
              onPressed: _submit,
              busy: _busy,
              label: signingIn ? l10n.signIn : l10n.setupAccountCreate,
            ),
            if (!closed)
              Center(
                child: TextButton(
                  key: const Key('setupAccountToggle'),
                  onPressed: _busy ? null : () => setState(() => _signIn = !_signIn),
                  child: Text(_signIn ? l10n.setupAccountNew : l10n.setupAccountHave),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Step 4: a model for the bots. A ChatGPT plan in one click, or a key.
class ModelStep extends ConsumerWidget {
  const ModelStep({super.key, required this.onDone, required this.onSkip});
  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      key: const Key('setupModel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.lg,
      children: [
        _Heading(l10n.setupModelTitle, l10n.setupModelBody, icon: LucideIcons.sparkles),
        AddKeyForm(
          onAdded: () {
            ref.invalidate(credentialsProvider);
            onDone();
          },
        ),
        Center(
          child: TextButton(key: const Key('setupSkipModel'), onPressed: onSkip, child: Text(l10n.setupSkip)),
        ),
      ],
    );
  }
}

/// Step 5: an address a phone can reach (Casama Link), then the code the phone scans. The page
/// says so when the phone has signed in.
class PhoneStep extends ConsumerStatefulWidget {
  const PhoneStep({super.key, required this.onFinish, required this.onSkip});
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  @override
  ConsumerState<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends ConsumerState<PhoneStep> {
  RemoteSetupStep? _step;
  LinkCode? _linkCode;
  final _log = <String>[];
  String? _failure;
  var _cancelled = false;
  StreamSubscription<RemoteSetupProgress>? _turnOn;

  SignInCode? _qr;
  Object? _qrError;
  var _loadingQr = false;
  var _paired = false;
  Timer? _expiry;
  Timer? _lookForPhone;
  /// Sign-ins this account already had when the code went up (null until read).
  Set<String>? _before;
  StreamSubscription<NotificationView>? _signIns;

  @override
  void initState() {
    super.initState();
    // A phone that scans the code makes a "New sign-in" notification for this account.
    _signIns = ref.read(backendProvider).watchNotifications().listen((n) {
      if (n.kind == 'sign_in') _phoneSignedIn();
    }, onError: (_) {});
    // The server restarts when the address is made, which can drop the live channel: the list of
    // notifications is looked at too.
    _lookForPhone = Timer.periodic(const Duration(seconds: 4), (_) async {
      final before = _before;
      if (before == null || _paired || !mounted) return;
      try {
        final now = await _signInIds();
        if (now.difference(before).isNotEmpty) _phoneSignedIn();
      } catch (_) {
        // Looked at again in a moment.
      }
    });
  }

  Future<Set<String>> _signInIds() async =>
      (await ref.read(backendProvider).notifications()).where((n) => n.kind == 'sign_in').map((n) => n.id).toSet();

  void _phoneSignedIn() {
    if (!mounted || _qr == null || _paired) return;
    HapticsHelper.success();
    Analytics.log('guided_setup_step', const {'step': 'phone', 'action': 'paired'});
    _expiry?.cancel();
    setState(() => _paired = true);
  }

  @override
  void dispose() {
    _cancelled = true;
    _expiry?.cancel();
    _lookForPhone?.cancel();
    unawaited(_turnOn?.cancel());
    unawaited(_signIns?.cancel());
    super.dispose();
  }

  void _start(RemoteAccessSetup setup) {
    Analytics.log('guided_setup_step', const {'step': 'phone', 'action': 'link_started'});
    setState(() {
      _step = RemoteSetupStep.linking;
      _linkCode = null;
      _failure = null;
      _log.clear();
    });
    _turnOn = setup.turnOn(cancelled: () => _cancelled).listen(
      (p) {
        if (!mounted) return;
        setState(() {
          _step = p.step;
          if (p.code != null) _linkCode = p.code;
          if (p.detail != null) {
            _log.add(p.detail!);
            if (_log.length > 5) _log.removeAt(0);
          }
        });
        if (p.step == RemoteSetupStep.linking && p.code != null) unawaited(setupOpenUrl(p.code!.verificationUrl));
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _step = null;
          _failure = e is LinkException ? e.message : errorText(context, e);
        });
        ref.invalidate(remoteAccessProvider);
      },
      onDone: () {
        if (!mounted || _step == null) return;
        setState(() => _step = null);
        ref.invalidate(remoteAccessProvider);
        ref.invalidate(remoteAccessAvailableProvider);
      },
      cancelOnError: true,
    );
  }

  Future<void> _loadQr() async {
    if (_loadingQr) return;
    _loadingQr = true;
    _expiry?.cancel();
    setState(() {
      _qr = null;
      _qrError = null;
      _paired = false;
    });
    try {
      // Compared by id, not by time: the server's clock (inside Docker) can be off this one's.
      _before = null;
      try {
        _before = await _signInIds();
      } catch (_) {
        // The live channel still says when the phone is in.
      }
      final code = await ref.read(backendProvider).createSignInCode();
      if (!mounted) return;
      setState(() => _qr = code);
      // A code lasts a few minutes: a fresh one takes its place while the page waits.
      final left = code.expiresAt.difference(DateTime.now());
      _expiry = Timer(left.isNegative ? Duration.zero : left, () {
        if (mounted && !_paired) unawaited(_loadQr());
      });
    } catch (e) {
      if (mounted) setState(() => _qrError = e);
    } finally {
      _loadingQr = false;
    }
  }

  Widget _code(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final code = _qr;
    if (_paired) {
      return Column(
        key: const Key('setupPhonePaired'),
        spacing: AppSpace.xs,
        children: [
          Icon(LucideIcons.circleCheck, size: 56, color: context.appColors.positive),
          Text(l10n.setupPhoneConnected, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(
            l10n.setupPhoneConnectedBody,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          TextButton.icon(
            key: const Key('setupPhoneAnother'),
            onPressed: _loadQr,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: Text(l10n.pairDeviceNewCode),
          ),
        ],
      );
    }
    if (_qrError != null || (code != null && !code.reachable)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.sm,
        children: [
          FormNote(
            _qrError != null ? errorText(context, _qrError!) : l10n.pairDeviceNotReachable,
            key: const Key('setupPhoneCodeProblem'),
            icon: LucideIcons.triangleAlert,
            color: scheme.error,
          ),
          Center(
            child: TextButton.icon(
              key: const Key('setupPhoneRetry'),
              onPressed: () {
                ref.invalidate(remoteAccessProvider);
                unawaited(_loadQr());
              },
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.tryAgain),
            ),
          ),
        ],
      );
    }
    if (code == null) {
      return const SizedBox(height: 256, child: Center(child: CircularProgressIndicator()));
    }
    return Column(
      spacing: AppSpace.sm,
      children: [
        // Always dark on white: a code drawn in the app's colours doesn't scan in dark mode.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: QrImageView(
            key: const Key('setupPhoneQr'),
            data: code.pairUrl,
            size: 232,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.L,
            semanticsLabel: l10n.pairDevice,
          ),
        ),
        _Waiting(l10n.setupPhoneWaiting, key: const Key('setupPhoneWaiting')),
        FormNote(l10n.pairDeviceWarning, icon: LucideIcons.shieldAlert),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final status = ref.watch(remoteAccessProvider);
    final setup = ref.watch(linkSetupProvider).value;
    final s = status.value;
    final on = s != null && s.state != 'off';
    final busy = _step != null;
    // The address is up: show the code, once.
    if (on && !busy && _qr == null && _qrError == null && !_loadingQr && !_paired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadQr());
      });
    }
    final skip = Center(
      child: TextButton(key: const Key('setupSkipPhone'), onPressed: widget.onSkip, child: Text(l10n.setupSkip)),
    );
    final List<Widget> children;
    if (busy) {
      children = [
        _Heading(l10n.setupPhoneTitle, null, icon: LucideIcons.smartphone),
        LinkProgress(step: _step!, code: _linkCode, log: _log, turningOff: false, onOpenLink: setupOpenUrl),
      ];
    } else if (status.isLoading && !status.hasValue) {
      children = [
        _Heading(l10n.setupPhoneTitle, null, icon: LucideIcons.smartphone),
        const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator())),
      ];
    } else if (on) {
      children = [
        _Heading(_paired ? l10n.setupPhoneTitle : l10n.setupPhoneScanTitle, _paired ? null : l10n.setupPhoneScanBody, icon: LucideIcons.smartphone),
        Center(child: _code(context)),
        if (KeepAwake.supported)
          FormSwitch(
            key: const Key('setupKeepAwake'),
            icon: LucideIcons.coffee,
            title: l10n.linkKeepAwake,
            subtitle: l10n.linkKeepAwakeHelp,
            value: ref.watch(keepAwakeProvider).value ?? false,
            onChanged: (v) async {
              await KeepAwake.set(v);
              ref.invalidate(keepAwakeProvider);
            },
          ),
        _primary(key: const Key('setupFinish'), onPressed: widget.onFinish, label: l10n.setupFinish),
      ];
    } else {
      children = [
        _Heading(l10n.setupPhoneTitle, l10n.setupPhoneBody, icon: LucideIcons.smartphone),
        if (_failure != null)
          FormNote(_failure!, key: const Key('setupPhoneFailure'), icon: LucideIcons.triangleAlert, color: scheme.error)
        else if (status.hasError)
          FormNote(errorText(context, status.error!), key: const Key('setupPhoneFailure'), icon: LucideIcons.triangleAlert, color: scheme.error),
        if (setup != null && (s != null || status.hasError))
          _primary(
            key: const Key('setupPhoneTurnOn'),
            onPressed: status.hasError ? () => ref.invalidate(remoteAccessProvider) : () => _start(setup),
            icon: status.hasError ? LucideIcons.refreshCw : LucideIcons.smartphone,
            label: status.hasError ? l10n.tryAgain : l10n.setupPhoneTurnOn,
          )
        else
          FormNote(l10n.setupPhoneOwnerOnly, key: const Key('setupPhoneOwnerOnly'), icon: LucideIcons.lock),
        FormNote(l10n.linkSignupsNote, icon: LucideIcons.userLock),
        skip,
      ];
    }
    return Column(
      key: const Key('setupPhone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.lg,
      children: children,
    );
  }
}

/// Whether this server has its address yet, as its owner sees it (null for anyone else). Read
/// without the outside check the Casama Link page runs.
final setupRemoteStateProvider = FutureProvider.autoDispose<String?>((ref) async {
  try {
    return (await ref.watch(backendProvider).remoteAccess())?.state;
  } catch (_) {
    return null;
  }
});

/// On the home page of a server this computer runs: what the setup still has left (a model, a
/// phone), with a way back into it. Gone once both are done, or closed for good.
class FinishSetupCard extends ConsumerWidget {
  const FinishSetupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!localServerSupported) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([GuidedSetup.active, GuidedSetup.cardDismissed]),
      // Its checks finish at different times: the card slides in and out rather than jumping.
      builder: (context, _) => Consumer(builder: (context, ref, _) {
        if (GuidedSetup.active.value || GuidedSetup.cardDismissed.value) return const ShowHide(child: null);
        if (ref.watch(usingLocalServerProvider).value != true) return const ShowHide(child: null);
        final keys = ref.watch(credentialsProvider).value;
        final needsModel = keys != null && keys.isEmpty;
        final needsPhone = ref.watch(setupRemoteStateProvider).value == 'off';
        if (!needsModel && !needsPhone) return const ShowHide(child: null);
        final l10n = context.l10n;
        final scheme = context.colorScheme;
        return ShowHide(child: Card(
          key: const Key('finishSetupCard'),
          margin: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.xxs, AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.xs,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.setupCardTitle, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      key: const Key('finishSetupDismiss'),
                      tooltip: l10n.close,
                      visualDensity: VisualDensity.compact,
                      onPressed: GuidedSetup.dismissCard,
                      icon: Icon(LucideIcons.x, size: 18, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpace.xs,
                    children: [
                      if (needsModel) FormNote(l10n.setupCardModel, icon: LucideIcons.sparkles),
                      if (needsPhone) FormNote(l10n.setupCardPhone, icon: LucideIcons.smartphone),
                      const SizedBox(height: AppSpace.xxs),
                      FilledButton.tonal(
                        key: const Key('finishSetupOpen'),
                        onPressed: () async {
                          // Asked for again: the steps left for later are back on the list.
                          await GuidedSetup.unskip('ai');
                          await GuidedSetup.unskip('phone');
                          await GuidedSetup.begin();
                          if (context.mounted) context.go('/setup');
                        },
                        child: Text(l10n.setupCardOpen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
      }),
    );
  }
}
