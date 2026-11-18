import 'dart:async';
import 'dart:io';

import 'package:casama_sdk/casama_link.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../selfhost/local_server.dart';
import '../selfhost/guided_setup.dart';
import 'keep_awake.dart';
import 'pair_device_sheet.dart';

/// This server's own address through Casama Link, as its owner sees it; null for everyone else
/// and on servers that can't have one. Checked afresh each time the page opens.
final remoteAccessProvider = FutureProvider.autoDispose<RemoteAccessStatus?>(
  (ref) => ref.watch(backendProvider).remoteAccess(check: true),
);

/// Whether the settings list offers Casama Link: the instance owner, on a self-hosted server.
final remoteAccessAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) async => await ref.watch(backendProvider).remoteAccess() != null,
);

/// Turns remote access on and off for the server this app runs on this computer. Tests replace it.
typedef LinkSetupFactory = Future<RemoteAccessSetup?> Function(Ref ref);

/// The setup for this computer's own server: only when this app installed it and is using it now.
/// A server someone runs elsewhere is switched with `casama selfhost remote on` on that machine.
final linkSetupProvider = FutureProvider.autoDispose<RemoteAccessSetup?>((
  ref,
) async {
  if (!localServerSupported) return null;
  final manager = ref.watch(localServerManagerProvider);
  final local = await manager.installed();
  if (local == null) return null;
  final using = Uri.tryParse(ref.watch(backendProvider).apiUrl);
  final own = Uri.parse(local.url);
  if (using == null ||
      using.port != own.port ||
      !RemoteAccessSettings.isLoopback(using.host)) {
    return null;
  }
  return RemoteAccessSetup(
    stackDir: local.dir,
    runInstaller: (onLine) => manager.rerunInstaller(local.dir, onLine),
    instanceName: Platform.localHostname.trim().isEmpty
        ? 'Casama server'
        : Platform.localHostname.trim(),
    platform: Platform.operatingSystem,
  );
});

/// Settings → Casama Link (D-296), on a self-hosted server: give it an address a phone can
/// reach from anywhere, see whether that works and where it stops, and turn it off again.
class LinkScreen extends ConsumerStatefulWidget {
  const LinkScreen({super.key});
  @override
  ConsumerState<LinkScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<LinkScreen> {
  /// A switch under way: the step it is on, the link code while waiting for approval, and the
  /// installer's last lines.
  RemoteSetupStep? _step;
  LinkCode? _code;
  final _log = <String>[];
  String? _failure;
  var _turningOff = false;
  var _cancelled = false;
  StreamSubscription<RemoteSetupProgress>? _sub;

  bool get _busy => _step != null;

  @override
  void dispose() {
    _cancelled = true;
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _run(Stream<RemoteSetupProgress> steps, {required bool off}) {
    setState(() {
      _step = off ? RemoteSetupStep.restarting : RemoteSetupStep.linking;
      _turningOff = off;
      _code = null;
      _failure = null;
      _log.clear();
    });
    _sub = steps.listen(
      (p) {
        if (!mounted) return;
        setState(() {
          _step = p.step;
          if (p.code != null) _code = p.code;
          if (p.detail != null) {
            _log.add(p.detail!);
            if (_log.length > 5) _log.removeAt(0);
          }
        });
        if (p.step == RemoteSetupStep.linking && p.code != null) {
          unawaited(_openLink(p.code!.verificationUrl));
        }
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
        final ready = _step == RemoteSetupStep.ready;
        setState(() => _step = null);
        ref.invalidate(remoteAccessProvider);
        ref.invalidate(remoteAccessAvailableProvider);
        // The point of turning it on: show the code the phone scans.
        if (ready) unawaited(showPairDevice(context));
      },
      cancelOnError: true,
    );
  }

  Future<void> _openLink(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // The page can be opened again from the button; the code is on screen.
    }
  }

  /// [invites] changes who may sign up while it is on; left out, that stays as it is.
  void _turnOn(RemoteAccessSetup setup, {bool? invites}) => _run(
    setup.turnOn(cancelled: () => _cancelled, invites: invites),
    off: false,
  );

  Future<void> _setPrivate(bool on) async {
    await runGuarded(
      context,
      () => ref.read(backendProvider).setPrivateNotifications(on),
    );
    ref.invalidate(remoteAccessProvider);
  }

  Future<void> _setKeepAwake(bool on) async {
    await KeepAwake.set(on);
    ref.invalidate(keepAwakeProvider);
  }

  /// The owner's switches: what the notifications carry, who may sign up, and keeping the Mac awake.
  Widget? _options(
    RemoteAccessStatus s,
    RemoteAccessSetup? setup, {
    required bool on,
  }) {
    final l10n = context.l10n;
    final tiles = [
      // What the linked workspace's plan says about live video for people away from this computer.
      // Other values (ones a newer server may send) show nothing.
      if (on && (s.liveView == 'included' || s.liveView == 'plan'))
        GroupedTile(
          key: const Key('linkLiveView'),
          icon: LucideIcons.monitorPlay,
          title: l10n.linkLiveView,
          subtitle: s.liveView == 'included'
              ? l10n.linkLiveViewIncluded
              : l10n.linkLiveViewPlan,
        ),
      // Only when notifications go through Casama Cloud; a server with its own key sends directly.
      if (s.push == 'relay')
        GroupedTile(
          icon: LucideIcons.bellOff,
          title: l10n.linkPrivateNotifications,
          subtitle: l10n.linkPrivateNotificationsHelp,
          trailing: Switch(
            key: const Key('linkPrivateNotifications'),
            value: s.privateNotifications ?? false,
            onChanged: _setPrivate,
          ),
        ),
      if (on && setup != null)
        GroupedTile(
          icon: LucideIcons.userPlus,
          title: l10n.linkInvites,
          subtitle: l10n.linkInvitesHelp,
          trailing: Switch(
            key: const Key('linkInvites'),
            value: s.invites ?? false,
            onChanged: (v) => _turnOn(setup, invites: v),
          ),
        ),
      if (on && setup != null && KeepAwake.supported)
        GroupedTile(
          icon: LucideIcons.coffee,
          title: l10n.linkKeepAwake,
          subtitle: l10n.linkKeepAwakeHelp,
          trailing: Switch(
            key: const Key('linkKeepAwake'),
            value: ref.watch(keepAwakeProvider).value ?? false,
            onChanged: _setKeepAwake,
          ),
        ),
    ];
    return tiles.isEmpty ? null : GroupedCard(children: tiles);
  }

  Future<void> _turnOff(RemoteAccessSetup setup) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.linkTurnOff,
      message: l10n.linkTurnOffConfirm,
      confirmLabel: l10n.linkTurnOff,
      destructive: true,
      confirmKey: const Key('linkTurnOffConfirm'),
    );
    if (ok && mounted) _run(setup.turnOff(), off: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = ref.watch(remoteAccessProvider);
    final setup = ref.watch(linkSetupProvider).value;
    return SubPage(
      title: l10n.casamaLink,
      children: [
        AsyncView(
          value: status,
          onRetry: () => ref.invalidate(remoteAccessProvider),
          data: (s) {
            if (s == null) {
              return FormNote(
                l10n.linkNeedsOwner,
                key: const Key('linkNeedsOwner'),
                icon: LucideIcons.lock,
              );
            }
            if (_busy) {
              return LinkProgress(
                step: _step!,
                code: _code,
                log: _log,
                turningOff: _turningOff,
                onOpenLink: _openLink,
              );
            }
            final on = s.state != 'off';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.md,
              children: [
                if (_failure != null)
                  FormNote(
                    _failure!,
                    key: const Key('linkFailure'),
                    icon: LucideIcons.triangleAlert,
                    color: context.colorScheme.error,
                  ),
                if (!on) ...[
                  Text(l10n.linkIntro, style: context.textTheme.titleMedium),
                  FormNote(l10n.linkIntroDetails, icon: LucideIcons.route),
                  FormNote(l10n.linkSignupsNote, icon: LucideIcons.userLock),
                  if (setup != null)
                    FilledButton.icon(
                      key: const Key('linkTurnOn'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () => _turnOn(setup),
                      icon: const Icon(LucideIcons.smartphone, size: 20),
                      label: Text(l10n.linkTurnOn),
                    )
                  else
                    // A server on another machine: its own command line turns this on.
                    const CommandNote('casama selfhost remote on'),
                  // A linked server pushes through Casama Cloud with or without an address.
                  ?_options(s, setup, on: false),
                ] else ...[
                  _StatusCard(status: s),
                  ?_options(s, setup, on: true),
                  if (!ref.watch(backendProvider).twoStepVerified)
                    GroupedCard(
                      children: [
                        GroupedTile(
                          key: const Key('linkTwoStep'),
                          icon: LucideIcons.smartphone,
                          title: l10n.twoStepSignIn,
                          subtitle: l10n.linkTwoStepTip,
                          onTap: () => context.pushOnce('/settings/two-step'),
                        ),
                      ],
                    ),
                  FilledButton.icon(
                    key: const Key('linkShowCode'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: s.state == 'needs_attention'
                        ? null
                        : () => showPairDevice(context),
                    icon: const Icon(LucideIcons.scanQrCode, size: 20),
                    label: Text(l10n.linkShowCode),
                  ),
                  Row(
                    spacing: AppSpace.sm,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('linkCheck'),
                          onPressed: () => ref.invalidate(remoteAccessProvider),
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                          label: Text(l10n.linkCheck),
                        ),
                      ),
                      if (setup != null)
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('linkTurnOff'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.colorScheme.error,
                            ),
                            onPressed: () => _turnOff(setup),
                            child: Text(l10n.linkTurnOff),
                          ),
                        ),
                    ],
                  ),
                  // Problems that only turning it on again fixes offer exactly that.
                  if (setup != null && _needsRelink(s.problem))
                    OutlinedButton.icon(
                      key: const Key('linkTurnOnAgain'),
                      onPressed: () => _turnOn(setup),
                      icon: const Icon(LucideIcons.smartphone, size: 18),
                      label: Text(l10n.linkTurnOn),
                    ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// States and problems arrive as text (see packages/contracts/src/link.ts): a server newer than
// this app may send one it doesn't know, and that must read as "needs attention", not crash.

/// Problems that only turning remote access on again fixes.
bool _needsRelink(String? p) => const {
  'not_linked',
  'key_rejected',
  'removed',
  'unknown_server',
  'address_changed',
}.contains(p);

/// What's wrong, in the person's words.
String remoteAccessProblemText(BuildContext context, String p) {
  final l10n = context.l10n;
  return switch (p) {
    'not_linked' => l10n.linkProblemNotLinked,
    'cloud_unreachable' => l10n.linkProblemCloudUnreachable,
    'key_rejected' => l10n.linkProblemKeyRejected,
    'suspended' => l10n.linkProblemSuspended,
    'removed' => l10n.linkProblemRemoved,
    'plan_limit' => l10n.linkProblemPlanLimit,
    'unknown_server' => l10n.linkProblemUnknownServer,
    'address_changed' => l10n.linkProblemAddressChanged,
    'connector_missing' => l10n.connectProblemConnectorMissing,
    'connector_blocked' => l10n.connectProblemConnectorBlocked,
    'address_unanswered' => l10n.linkProblemAddressUnanswered,
    _ => l10n.linkStateAttention,
  };
}

/// The address, whether it is working, and what's wrong when it isn't.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});
  final RemoteAccessStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final (label, color) = switch (status.state) {
      'online' => (l10n.linkStateOnline, colors.positive),
      'starting' => (l10n.linkStateStarting, colors.warning),
      'offline' => (l10n.linkStateOffline, scheme.error),
      'off' => (l10n.linkStateOff, scheme.onSurfaceVariant),
      _ => (l10n.linkStateAttention, scheme.error),
    };
    final address = status.address;
    final problem = status.problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('linkState'),
              icon: LucideIcons.radio,
              iconColor: color,
              title: label,
              subtitle: problem == null
                  ? null
                  : remoteAccessProblemText(context, problem),
            ),
            if (address != null)
              GroupedTile(
                key: const Key('linkAddress'),
                icon: LucideIcons.globe,
                title: l10n.linkAddress,
                subtitle: address,
                trailing: IconButton(
                  key: const Key('linkCopyAddress'),
                  tooltip: l10n.copy,
                  icon: const Icon(LucideIcons.copy, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: address));
                    if (context.mounted) showSuccess(context, l10n.copied);
                  },
                ),
              ),
            if (status.localAddress != null)
              GroupedTile(
                icon: LucideIcons.monitor,
                title: l10n.linkLocalAddress,
                subtitle: status.localAddress,
              ),
          ],
        ),
      ],
    );
  }
}

/// The switch while it runs: four steps, the code to approve, and the installer's last lines.
class LinkProgress extends StatelessWidget {
  const LinkProgress({
    super.key,
    required this.step,
    required this.code,
    required this.log,
    required this.turningOff,
    required this.onOpenLink,
  });
  final RemoteSetupStep step;
  final LinkCode? code;
  final List<String> log;
  final bool turningOff;
  final Future<void> Function(Uri) onOpenLink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    if (turningOff) {
      return Column(
        key: const Key('linkTurningOff'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Text(l10n.linkTurningOff, style: context.textTheme.titleMedium),
          const LinearProgressIndicator(),
          if (log.isNotEmpty) _Log(log),
        ],
      );
    }
    const order = [
      RemoteSetupStep.linking,
      RemoteSetupStep.address,
      RemoteSetupStep.restarting,
      RemoteSetupStep.connecting,
    ];
    final labels = [
      l10n.linkStepSignIn,
      l10n.linkStepAddress,
      l10n.linkStepRestart,
      l10n.linkStepConnect,
    ];
    final at = step == RemoteSetupStep.ready
        ? order.length
        : order.indexOf(step);
    final waiting = code;
    return Column(
      key: const Key('linkProgress'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.md,
      children: [
        GroupedCard(
          children: [
            for (final (i, label) in labels.indexed)
              GroupedTile(
                key: Key('linkStep-$i'),
                icon: i < at
                    ? LucideIcons.circleCheck
                    : (i == at ? LucideIcons.loaderCircle : LucideIcons.circle),
                iconColor: i < at
                    ? context.appColors.positive
                    : (i == at ? scheme.primary : scheme.outline),
                title: label,
              ),
          ],
        ),
        if (step == RemoteSetupStep.linking && waiting != null) ...[
          Center(
            child: SelectableText(
              waiting.userCode,
              key: const Key('linkSignInCode'),
              style: context.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                fontFeatures: AppText.tabular,
              ),
            ),
          ),
          Text(
            l10n.linkSignInBody,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Center(
            child: TextButton.icon(
              key: const Key('linkOpenSignIn'),
              onPressed: () => onOpenLink(waiting.verificationUrl),
              icon: const Icon(LucideIcons.externalLink, size: 18),
              label: Text(l10n.linkSignInOpen),
            ),
          ),
        ] else
          const LinearProgressIndicator(),
        if (log.isNotEmpty) _Log(log),
      ],
    );
  }
}

class _Log extends StatelessWidget {
  const _Log(this.lines);
  final List<String> lines;
  @override
  Widget build(BuildContext context) => Text(
    lines.join('\n'),
    key: const Key('linkLog'),
    style: TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: context.colorScheme.onSurfaceVariant,
    ),
  );
}

/// A command to run on the server, with a copy button.
class CommandNote extends StatelessWidget {
  const CommandNote(this.command, {super.key});
  final String command;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GroupedCard(
      children: [
        GroupedTile(
          key: const Key('linkCommand'),
          icon: LucideIcons.terminal,
          title: command,
          trailing: IconButton(
            tooltip: l10n.copy,
            icon: const Icon(LucideIcons.copy, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: command));
              if (context.mounted) showSuccess(context, l10n.copied);
            },
          ),
        ),
      ],
    );
  }
}

/// Whether this build can run a server on this computer at all (never on the web).
bool get linkSetupSupported => !kIsWeb && localServerSupported;
