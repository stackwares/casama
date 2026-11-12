import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/glow_button.dart';
import 'app_logo.dart';
import '../../core/analytics.dart';

/// Opens the connect flow for a built-in app. Returns the connection when it worked.
Future<Integration?> showConnectApp(BuildContext context, CatalogApp app, {Integration? reconnect}) =>
    showAdaptiveSheet<Integration>(
      context: context,
      dialogMaxWidth: 520,
      contentPadsBottom: true,
      builder: (_) => ConnectAppSheet(app: app, reconnect: reconnect),
    );

enum _Step { intro, waiting, connecting, success, failed }

/// Connecting one app, start to finish: what it does, how to sign in (one click, or an API key
/// with steps), waiting for the browser sign-in, then choosing which bots get it.
class ConnectAppSheet extends ConsumerStatefulWidget {
  const ConnectAppSheet({super.key, required this.app, this.reconnect});
  final CatalogApp app;
  final Integration? reconnect;

  @override
  ConsumerState<ConnectAppSheet> createState() => _ConnectAppSheetState();
}

class _ConnectAppSheetState extends ConsumerState<ConnectAppSheet> {
  late CatalogAppAuthEnum _method;
  var _step = _Step.intro;
  final _key = TextEditingController();
  var _showKey = false;
  String? _authorizeUrl;
  String? _flowId;
  String? _error;
  Integration? _result;
  final _bots = <String>{};
  Timer? _poll;
  late final AppLifecycleListener _lifecycle;

  CatalogApp get app => widget.app;

  @override
  void initState() {
    super.initState();
    // One click when it works on this server; otherwise the next way in.
    final usable = app.auth.where((m) => m != CatalogAppAuthEnum.oauth || app.oauthAvailable).toList();
    _method = usable.isNotEmpty ? usable.first : app.auth.first;
    // Coming back from the browser: check straight away instead of waiting for the next poll.
    _lifecycle = AppLifecycleListener(onResume: () {
      if (_step == _Step.waiting) _check();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    // Closed while the person is still signing in (in another tab or app): keep checking for a few
    // minutes, so the connection still shows up once the sign-in finishes.
    final flow = _flowId;
    if (_step == _Step.waiting) Analytics.log('connection_failed', {'app_id': app.id, 'method': _method.value, 'reason': 'cancelled'});
    if (flow != null && _step == _Step.waiting) finishInBackground(ProviderScope.containerOf(context, listen: false), flow);
    _lifecycle.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    setState(() {
      _step = _Step.connecting;
      _error = null;
    });
    // The connect funnel (F4). The server reports the outcome it sees; this side reports what it can't.
    Analytics.log('connection_started', {'app_id': app.id, 'method': _method.value, 'reconnect': widget.reconnect != null});
    try {
      final r = await ref.read(backendProvider).connectApp(
            org.id,
            appId: app.id,
            method: _method.value,
            apiKey: _method == CatalogAppAuthEnum.apiKey ? _key.text.trim() : null,
            integrationId: widget.reconnect?.id,
          );
      if (!mounted) return;
      switch (r.status) {
        // Composio's managed sign-in (D-130): no flow to poll; the connection finishes in the browser.
        case ConnectAppResponseStatusEnum.authorize when r.flowId == null && r.integration != null:
          _authorizeUrl = r.authorizeUrl;
          unawaited(_openSignIn());
          _succeed(r.integration!);
        case ConnectAppResponseStatusEnum.authorize:
          _authorizeUrl = r.authorizeUrl;
          _flowId = r.flowId;
          setState(() => _step = _Step.waiting);
          _poll = Timer.periodic(const Duration(seconds: 2), (_) => _check());
          unawaited(_openSignIn());
        case ConnectAppResponseStatusEnum.connected:
          _succeed(r.integration!);
        case ConnectAppResponseStatusEnum.error:
          _fail(r.error ?? r.integration?.error);
      }
    } catch (e) {
      Analytics.log('connection_failed', {'app_id': app.id, 'method': _method.value, 'reason': 'exception'});
      if (mounted) _fail(errorText(context, e));
    }
  }

  Future<void> _openSignIn() async {
    final url = _authorizeUrl;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    } catch (_) {
      // No browser handler (tests, locked-down devices): "Open the sign-in page again" stays available.
    }
  }

  var _checking = false;
  Future<void> _check() async {
    final id = _flowId;
    if (id == null || _checking || _step != _Step.waiting) return;
    _checking = true;
    try {
      final s = await ref.read(backendProvider).connectStatus(id);
      if (!mounted) return;
      switch (s.status) {
        case ConnectFlowStatusStatusEnum.connected:
          _succeed(s.integration!);
        case ConnectFlowStatusStatusEnum.error:
          _fail(s.error);
        case ConnectFlowStatusStatusEnum.expired:
          Analytics.log('connection_failed', {'app_id': app.id, 'method': _method.value, 'reason': 'expired'});
          _fail(context.l10n.connectFailedTitle);
        case ConnectFlowStatusStatusEnum.pending:
          break;
      }
    } catch (_) {
      // A missed poll is fine; the next one will try again.
    } finally {
      _checking = false;
    }
  }

  Future<void> _succeed(Integration i) async {
    _poll?.cancel();
    HapticFeedback.mediumImpact();
    final bots = await ref.read(botsProvider.future).catchError((_) => const <Bot>[]);
    if (!mounted) return;
    setState(() {
      _result = i;
      _step = _Step.success;
      _bots
        ..clear()
        // Reconnecting keeps who had it; a new app goes to every bot (they still ask before risky steps).
        ..addAll(widget.reconnect != null ? (i.botIds ?? const []) : bots.map((b) => b.id));
    });
    ref.invalidate(integrationsProvider);
  }

  void _fail(String? message) {
    _poll?.cancel();
    setState(() {
      _error = message;
      _step = _Step.failed;
    });
  }

  Future<void> _finish() async {
    final i = _result!;
    final had = (i.botIds ?? const []).toSet();
    final backend = ref.read(backendProvider);
    for (final b in ref.read(botsProvider).value ?? const <Bot>[]) {
      final want = _bots.contains(b.id);
      if (want != had.contains(b.id)) {
        await runGuarded(context, () => backend.setBotIntegration(b.id, i.id, want));
        ref.invalidate(botIntegrationIdsProvider(b.id));
      }
    }
    ref.invalidate(integrationsProvider);
    if (mounted) Navigator.of(context).pop(i);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.duration),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.duration),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a), child: child),
        ),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
            child: switch (_step) {
              _Step.intro || _Step.connecting => _intro(context),
              _Step.waiting => _waiting(context),
              _Step.success => _success(context),
              _Step.failed => _failed(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, {String? subtitle}) {
    final scheme = context.colorScheme;
    return Column(
      children: [
        AppLogo(appId: app.id, name: app.name, color: app.color, size: 72, glow: true),
        const SizedBox(height: AppSpace.md),
        Text(widget.reconnect != null ? '${context.l10n.reconnect} ${app.name}' : app.name, style: context.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(subtitle ?? app.description, textAlign: TextAlign.center, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _intro(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final brand = brandColor(app.color, scheme.primary);
    final busy = _step == _Step.connecting;
    final oauthBlocked = _method == CatalogAppAuthEnum.oauth && !app.oauthAvailable;
    final keyOk = _method != CatalogAppAuthEnum.apiKey || _key.text.trim().length >= 8;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        const SizedBox(height: AppSpace.lg),
        // What it can do, at a glance.
        Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: brand.withValues(alpha: context.isDark ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: brand.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.whatBotsCanDo, style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpace.xs),
              for (final c in app.capabilities)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(LucideIcons.circleCheck, size: 16, color: context.appColors.positive),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(child: Text(c, style: context.textTheme.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (app.note != null) ...[
          const SizedBox(height: AppSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpace.xs),
              Expanded(child: Text(app.note!, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        if (app.auth.length > 1) ...[
          SegmentedButton<CatalogAppAuthEnum>(
            key: const Key('connectMethod'),
            showSelectedIcon: false,
            segments: [
              for (final m in app.auth)
                ButtonSegment(
                  value: m,
                  icon: Icon(switch (m) {
                    CatalogAppAuthEnum.oauth => LucideIcons.logIn,
                    CatalogAppAuthEnum.apiKey => LucideIcons.keyRound,
                    CatalogAppAuthEnum.none => LucideIcons.zap,
                    CatalogAppAuthEnum.managed => LucideIcons.logIn,
                  }, size: 16),
                  label: Text(switch (m) {
                    CatalogAppAuthEnum.oauth => l10n.signInTab,
                    CatalogAppAuthEnum.apiKey => l10n.authApiKey,
                    CatalogAppAuthEnum.none => l10n.authNone,
                    CatalogAppAuthEnum.managed => l10n.connectManaged,
                  }),
                ),
            ],
            selected: {_method},
            onSelectionChanged: busy ? null : (v) => setState(() => _method = v.first),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        if (_method == CatalogAppAuthEnum.apiKey) ..._keyFields(context),
        if (oauthBlocked) _adminSetup(context),
        if (_method == CatalogAppAuthEnum.managed) ...[
          Text(l10n.connectManagedHelp(app.name), textAlign: TextAlign.center, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpace.md),
        ],
        if (_method == CatalogAppAuthEnum.none) ...[
          Text(l10n.connectNoSignIn, textAlign: TextAlign.center, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpace.md),
        ],
        GlowButton.icon(
          key: const Key('connectAppSubmit'),
          style: GlowButton.glow(context, color: _method == CatalogAppAuthEnum.oauth ? brand : null).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          ),
          onPressed: busy || oauthBlocked || !keyOk ? null : _connect,
          icon: busy
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onSurfaceVariant))
              : Icon(_method == CatalogAppAuthEnum.oauth ? LucideIcons.arrowUpRight : LucideIcons.plug, size: 18),
          label: Text(busy
              ? l10n.connectingLabel
              : (_method == CatalogAppAuthEnum.oauth ? l10n.continueWith(app.name) : (_method == CatalogAppAuthEnum.managed ? l10n.connectManaged : l10n.connect))),
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.shieldCheck, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(child: Text(l10n.privacyNote, textAlign: TextAlign.center, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
          ],
        ),
      ],
    );
  }

  List<Widget> _keyFields(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final help = app.apiKey;
    return [
      if (help != null) ...[
        for (final (i, step) in help.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Text('${i + 1}', style: context.textTheme.labelSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Padding(padding: const EdgeInsets.only(top: 1), child: Text(step, style: context.textTheme.bodyMedium))),
              ],
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('openKeyPage'),
            onPressed: () => launchUrl(Uri.parse(help.url), mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank'),
            icon: const Icon(LucideIcons.externalLink, size: 16),
            label: Text(l10n.openApp(app.name)),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
      ],
      TextField(
        key: const Key('appApiKey'),
        controller: _key,
        obscureText: !_showKey,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: help?.label ?? l10n.authApiKey,
          hintText: help?.placeholder,
          prefixIcon: const Icon(LucideIcons.keyRound, size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.pasteLabel,
                icon: const Icon(LucideIcons.clipboardPaste, size: 18),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) setState(() => _key.text = data!.text!.trim());
                },
              ),
              IconButton(
                tooltip: _showKey ? l10n.hide : l10n.show,
                icon: Icon(_showKey ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                onPressed: () => setState(() => _showKey = !_showKey),
              ),
            ],
          ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _key.text.trim().length >= 8 ? _connect() : null,
      ),
      const SizedBox(height: AppSpace.md),
    ];
  }

  Widget _adminSetup(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(appCatalogProvider).value;
    final uri = catalog?.redirectUri;
    final host = uri == null ? null : Uri.tryParse(uri);
    final insecure = host != null && host.scheme == 'http' && !const {'localhost', '127.0.0.1', '::1'}.contains(host.host);
    final hubs = [
      for (final id in _hubIds)
        ...?catalog?.apps.where((a) => a.id == id && a.id != app.id && a.oauthAvailable && a.auth.contains(CatalogAppAuthEnum.oauth)),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: context.appColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.wrench, size: 16, color: context.appColors.warning),
            const SizedBox(width: AppSpace.xs),
            // A server on plain http (a LAN address while testing) can't take sign-ins: providers
            // only send people back to an https address. Say that, not "an admin must set up".
            Expanded(child: Text(insecure ? l10n.oauthNeedsHttps(app.name, host.origin) : l10n.adminSetupNeeded(app.name), style: context.textTheme.bodyMedium)),
          ]),
          if (uri != null && !insecure) ...[
            const SizedBox(height: AppSpace.xs),
            SelectableText(l10n.adminSetupRedirect(uri), style: context.textTheme.bodySmall),
          ],
          if (hubs.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(l10n.connectThroughHub(app.name), style: context.textTheme.bodyMedium),
            const SizedBox(height: AppSpace.xs),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (final hub in hubs)
                  ActionChip(
                    key: Key('connectVia_${hub.id}'),
                    avatar: AppLogo(appId: hub.id, name: hub.name, color: hub.color, size: 18),
                    label: Text(hub.name),
                    onPressed: () {
                      final nav = Navigator.of(context);
                      final root = nav.context;
                      nav.pop();
                      showConnectApp(root, hub);
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Hubs (packages/domain HUB_APPS) that sign in here with one click: the way in when this app's
  /// own sign-in isn't set up on the server.
  static const _hubIds = ['composio', 'pipedream', 'zapier'];

  Widget _waiting(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CircularProgressIndicator(strokeWidth: 3, color: brandColor(app.color, scheme.primary).withValues(alpha: 0.8)),
                ),
                AppLogo(appId: app.id, name: app.name, color: app.color, size: 64),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(l10n.finishSignIn(app.name), textAlign: TextAlign.center, style: context.textTheme.titleLarge),
        const SizedBox(height: AppSpace.xs),
        Text(l10n.finishSignInHelp(app.name), textAlign: TextAlign.center, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppSpace.lg),
        OutlinedButton.icon(
          key: const Key('reopenSignIn'),
          onPressed: _openSignIn,
          icon: const Icon(LucideIcons.externalLink, size: 16),
          label: Text(l10n.reopenSignIn),
        ),
        const SizedBox(height: AppSpace.xs),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
      ],
    );
  }

  Widget _success(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final i = _result!;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: AppMotion.of(context, const Duration(milliseconds: 520)),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AppLogo(appId: app.id, name: app.name, color: app.color, size: 72, glow: true),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: context.appColors.positive, shape: BoxShape.circle, border: Border.all(color: scheme.surface, width: 3)),
                    child: const Icon(LucideIcons.check, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text(l10n.appConnected(app.name), key: const Key('appConnected'), textAlign: TextAlign.center, style: context.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(l10n.appToolsReady(i.tools.length), textAlign: TextAlign.center, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        if (bots.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          Text(l10n.whichBots, style: context.textTheme.titleSmall),
          Text(l10n.whichBotsHelp, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (final b in bots)
                FilterChip(
                  key: Key('grant-${b.id}'),
                  avatar: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 22, animate: false),
                  label: Text(b.name),
                  selected: _bots.contains(b.id),
                  showCheckmark: false,
                  onSelected: (v) => setState(() => v ? _bots.add(b.id) : _bots.remove(b.id)),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        GlowButton(
          key: const Key('connectDone'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _finish,
          child: Text(l10n.doneLabel),
        ),
      ],
    );
  }

  Widget _failed(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, subtitle: ''),
        const SizedBox(height: AppSpace.md),
        Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.triangleAlert, size: 18, color: scheme.error),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.connectFailedTitle, style: context.textTheme.titleSmall),
                    if ((_error ?? '').isNotEmpty) SelectableText(_error!, key: const Key('connectError'), style: context.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        GlowButton(
          key: const Key('connectRetry'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: () => setState(() => _step = _Step.intro),
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}

/// Polls a connect flow after its sheet closed, for up to three minutes, and refreshes the
/// workspace's connections once it finishes.
void finishInBackground(ProviderContainer container, String flowId, {Duration every = const Duration(seconds: 3), int tries = 60}) {
  var left = tries;
  Timer.periodic(every, (t) async {
    if (--left < 0) return t.cancel();
    try {
      final s = await container.read(backendProvider).connectStatus(flowId);
      if (s.status == ConnectFlowStatusStatusEnum.pending) return;
      t.cancel();
      if (s.status == ConnectFlowStatusStatusEnum.connected) container.invalidate(integrationsProvider);
    } catch (_) {
      // Try again on the next tick.
    }
  });
}
