import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../core/providers.dart';
import '../core/server_reachability.dart';
import '../features/settings/about_you_screen.dart' show aboutYouProvider, userFactsProvider;
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
import '../core/link_browser.dart';
import '../core/remote_content.dart';
import '../features/selfhost/local_docker.dart';

/// A bar over the top of the app while its server doesn't answer (D-296), with Try Again. It
/// checks by itself every few seconds and when the app comes back to the front, and goes away,
/// refreshing what's on screen, once the server answers. Launch has its own full screen for this
/// ([ServerUnreachableView]); this covers the server going away while the app is open.
class ServerReachabilityBar extends ConsumerStatefulWidget {
  const ServerReachabilityBar({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ServerReachabilityBar> createState() =>
      _ServerReachabilityBarState();
}

class _ServerReachabilityBarState extends ConsumerState<ServerReachabilityBar> {
  static const _every = Duration(seconds: 10);

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  var _checking = false;

  /// This computer's own server is down because Docker isn't running: the bar says so and
  /// offers to open it.
  var _dockerDown = false;

  @override
  void initState() {
    super.initState();
    serverReachability.addListener(_changed);
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (serverReachability.value != Reachability.ok) unawaited(_check());
      },
    );
    _changed();
  }

  @override
  void dispose() {
    serverReachability.removeListener(_changed);
    _lifecycle?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Reachability _last = serverReachability.value;

  void _changed() {
    final now = serverReachability.value;
    final back = _last != Reachability.ok && now == Reachability.ok;
    _last = now;
    if (now == Reachability.ok) {
      _timer?.cancel();
      _timer = null;
      _dockerDown = false;
    } else {
      _timer ??= Timer.periodic(_every, (_) => unawaited(_check()));
      unawaited(_lookAtDocker());
    }
    // Back: what's on screen came from the offline cache or failed to load; fetch it again.
    if (back) {
      ref.invalidate(organizationsProvider);
      ref.invalidate(botsProvider);
      // The computer panel beside a chat failed too while the server was away.
      ref.invalidate(computersProvider);
      ref.invalidate(templatesProvider);
      ref.invalidate(credentialsProvider);
      ref.invalidate(aboutYouProvider);
      ref.invalidate(userFactsProvider);
      ref.invalidate(skillsProvider);
      ref.invalidate(integrationsProvider);
      ref.invalidate(secretsProvider);
      ref.invalidate(tasksProvider);
      ref.invalidate(approvalsProvider);
      ref.invalidate(takeoversProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(usageTodayProvider);
      ref.invalidate(usageMonthProvider);
    }
    if (mounted) setState(() {});
  }

  Future<void> _lookAtDocker() async {
    final down = await checkLocalDocker(ref.read(backendProvider).apiUrl);
    if (mounted && down != _dockerDown && serverReachability.value != Reachability.ok) {
      setState(() => _dockerDown = down);
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await checkServer(ref.read(backendProvider).apiUrl);
      if (serverReachability.value != Reachability.ok) await _lookAtDocker();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openDocker() async {
    await openDocker();
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    final state = serverReachability.value;
    final shown = state != Reachability.ok;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // The same two children always, so the app below is never rebuilt from scratch when the bar
    // comes and goes; only the top padding moves from the app to the bar.
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !shown
              ? const SizedBox(width: double.infinity)
              : Material(
                  key: const Key('serverReachabilityBar'),
                  color: scheme.inverseSurface,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.md,
                        AppSpace.xxs,
                        AppSpace.xs,
                        AppSpace.xxs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state == Reachability.serverOffline
                                ? LucideIcons.serverOff
                                : LucideIcons.wifiOff,
                            size: 18,
                            color: scheme.onInverseSurface,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              _dockerDown
                                  ? l10n.localDockerStopped
                                  : state == Reachability.serverOffline
                                  ? l10n.serverOfflineTitle
                                  : l10n.cannotReachServer,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onInverseSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Casama Cloud's public status page (D-304): is it us or them?
                          if (Uri.tryParse(ref.watch(backendProvider).apiUrl)?.host == 'api.casama.ai')
                            TextButton(
                              key: const Key('serverReachabilityStatus'),
                              onPressed: () => openWebLink(remoteUri('status', 'https://status.casama.ai')),
                              style: TextButton.styleFrom(foregroundColor: scheme.inversePrimary),
                              child: Text(l10n.serviceStatus),
                            ),
                          if (_dockerDown && canOpenDocker())
                            TextButton(
                              key: const Key('serverReachabilityOpenDocker'),
                              onPressed: _checking ? null : _openDocker,
                              style: TextButton.styleFrom(foregroundColor: scheme.inversePrimary),
                              child: Text(l10n.setupDockerOpen),
                            ),
                          TextButton(
                            key: const Key('serverReachabilityRetry'),
                            onPressed: _checking ? null : _check,
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.inversePrimary,
                            ),
                            child: _checking
                                ? SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.inversePrimary,
                                    ),
                                  )
                                : Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: shown,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
