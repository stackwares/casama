import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/analytics.dart';
import '../../core/providers.dart';
import '../../core/sign_in_sheet.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/glow_button.dart';
import 'app_logo.dart';
import 'connect_app_sheet.dart';

/// An MCP server a bot offered on a card that isn't one of Casama's apps (D-473): what people
/// call it, its address (none when the person types it, so a key in it stays out of the chat),
/// or the command that runs it on the person's own computer, and the bot that offered it.
class OfferedServer {
  const OfferedServer({
    required this.name,
    this.url,
    this.command,
    this.args = const [],
    this.botId,
  });
  final String name;
  final String? url;
  final String? command;
  final List<String> args;
  final String? botId;

  /// Runs on the person's computer, not at an address.
  bool get isLocal => command != null;

  /// From a card button's context (`server` and `bot` beside the path), or null.
  static OfferedServer? fromContext(Map<String, Object?> ctx) {
    final s = ctx['server'];
    if (s is! Map) return null;
    final name = s['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final url = s['url'],
        command = s['command'],
        args = s['args'],
        bot = ctx['bot'];
    return OfferedServer(
      name: name.trim(),
      url: url is String && url.startsWith('https://') ? url : null,
      command: command is String && command.trim().isNotEmpty
          ? command.trim()
          : null,
      args: [
        if (args is List)
          for (final a in args)
            if (a is String) a,
      ],
      botId: bot is String ? bot : null,
    );
  }
}

/// Opens the connect flow for a server at an address. Returns the connection when it worked.
Future<Integration?> showConnectServer(
  BuildContext context,
  OfferedServer server,
) => showAdaptiveSheet<Integration>(
  context: context,
  dialogMaxWidth: 520,
  contentPadsBottom: true,
  builder: (_) => ConnectServerSheet(server: server),
);

enum _Step { address, probing, intro, connecting, waiting, success, failed }

/// Connecting one server, start to finish: its address (when the bot didn't give one), how it
/// lets people in (asked from the server itself), the sign-in or key, then which tools the bot
/// that offered it may use.
class ConnectServerSheet extends ConsumerStatefulWidget {
  const ConnectServerSheet({super.key, required this.server});
  final OfferedServer server;

  @override
  ConsumerState<ConnectServerSheet> createState() => _ConnectServerSheetState();
}

class _ConnectServerSheetState extends ConsumerState<ConnectServerSheet> {
  late var _step = widget.server.url == null ? _Step.address : _Step.probing;
  final _address = TextEditingController();
  final _key = TextEditingController();
  final _header = TextEditingController();
  var _showKey = false;
  // The person asked for the key form on a server that also signs in with the browser.
  var _useKey = false;
  ProbeServerResponse? _probe;
  String? _authorizeUrl;
  String? _flowId;
  String? _error;
  Integration? _result;
  // Tools switched off on the last step.
  final _off = <String>{};
  Timer? _poll;
  ProviderContainer? _container;
  late final AppLifecycleListener _lifecycle;

  OfferedServer get server => widget.server;

  /// The address being connected: the bot's, or the one typed here.
  String get _url => server.url ?? _address.text.trim();
  String get _host => _probe?.host ?? Uri.tryParse(_url)?.host ?? '';
  bool get _typed => server.url == null;

  bool get _signsIn => _probe?.auth == ProbeServerResponseAuthEnum.oauth;
  bool get _signInWorks => _signsIn && _probe?.oauthAvailable != false;
  String get _method => switch (_probe?.auth) {
    ProbeServerResponseAuthEnum.oauth when _signInWorks && !_useKey => 'oauth',
    ProbeServerResponseAuthEnum.oauth ||
    ProbeServerResponseAuthEnum.key => 'api_key',
    _ => 'none',
  };

  @override
  void initState() {
    super.initState();
    if (server.url != null) Future.microtask(_check);
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_step == _Step.waiting) _pollFlow();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    _poll?.cancel();
    // Closed while still signing in elsewhere: keep checking, so the connection still shows up.
    final container = _container, flow = _flowId;
    if (container != null && flow != null && _step == _Step.waiting) {
      finishInBackground(container, flow);
    }
    _lifecycle.dispose();
    for (final c in [_address, _key, _header]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Asks the server how it lets people in. A built-in app's own address opens that app instead.
  Future<void> _check() async {
    final org = ref.read(currentOrgProvider);
    if (org == null || !mounted) return;
    setState(() {
      _step = _Step.probing;
      _error = null;
    });
    try {
      final backend = ref.read(backendProvider);
      final p = await backend.probeServer(org.id, _url);
      if (!mounted) return;
      if (p.appId != null) {
        final catalog = await ref.read(appCatalogProvider.future);
        final app = catalog.apps.where((a) => a.id == p.appId).firstOrNull;
        if (app != null && mounted) {
          final nav = Navigator.of(context);
          final connected = await showConnectApp(nav.context, app);
          if (mounted) nav.pop(connected);
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _probe = p;
        _step = _Step.intro;
      });
    } catch (e) {
      if (mounted) _fail(errorText(context, e));
    }
  }

  Future<void> _connect() async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    final method = _method;
    setState(() {
      _step = _Step.connecting;
      _error = null;
    });
    Analytics.log('connection_started', {
      'app_id': 'custom',
      'method': method,
      'reconnect': false,
    });
    try {
      final header = _header.text.trim();
      final r = await ref
          .read(backendProvider)
          .connectServer(
            org.id,
            url: _url,
            name: server.name,
            method: method,
            apiKey: method == 'api_key' ? _key.text.trim() : null,
            authHeader: method == 'api_key' && header.isNotEmpty
                ? header
                : null,
            // A typed address that needs nothing else may hold its own key: it goes to the vault.
            privateUrl: _typed && method == 'none',
            botId: server.botId,
            returnToApp: signInSheetAvailable,
          );
      if (!mounted) return;
      switch (r.status) {
        case ConnectAppResponseStatusEnum.authorize:
          _authorizeUrl = r.authorizeUrl;
          _flowId = r.flowId;
          setState(() => _step = _Step.waiting);
          _poll = Timer.periodic(
            const Duration(seconds: 2),
            (_) => _pollFlow(),
          );
          unawaited(_openSignIn());
        case ConnectAppResponseStatusEnum.connected:
          _succeed(r.integration!);
        case ConnectAppResponseStatusEnum.error:
          _fail(r.error ?? r.integration?.error);
      }
    } catch (e) {
      Analytics.log('connection_failed', {
        'app_id': 'custom',
        'method': method,
        'reason': 'exception',
      });
      if (mounted) _fail(errorText(context, e));
    }
  }

  Future<void> _openSignIn() async {
    final url = _authorizeUrl;
    // The server checks this too: a sign-in page is a web page, never another kind of link.
    if (url == null || Uri.tryParse(url)?.scheme != 'https') return;
    final r = await openSignIn(url);
    if (mounted && r != SignInSheetResult.browser) unawaited(_pollFlow());
  }

  var _checking = false;
  Future<void> _pollFlow() async {
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

  void _succeed(Integration i) {
    _poll?.cancel();
    HapticFeedback.mediumImpact();
    ref.invalidate(integrationsProvider);
    setState(() {
      _result = i;
      _off.clear();
      _step = _Step.success;
    });
  }

  void _fail(String? message) {
    _poll?.cancel();
    ref.invalidate(integrationsProvider);
    setState(() {
      _error = message;
      _step = _Step.failed;
    });
  }

  /// Saves which tools the bot keeps: all of them is how it was connected, none takes it away.
  Future<void> _finish() async {
    final i = _result!;
    final bot = server.botId;
    if (bot != null && _off.isNotEmpty) {
      final keep = [
        for (final t in i.tools)
          if (!_off.contains(t.name)) t.name,
      ];
      final backend = ref.read(backendProvider);
      await runGuarded(
        context,
        () => keep.isEmpty
            ? backend.setBotIntegration(bot, i.id, false)
            : backend.setBotIntegrationTools(bot, i.id, keep),
      );
      ref.invalidate(botIntegrationIdsProvider(bot));
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
        child: KeyedSubtree(
          key: ValueKey(_step == _Step.connecting ? _Step.intro : _step),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              BottomPadding.of(context, minimum: AppSpace.lg),
            ),
            child: switch (_step) {
              _Step.address => _addressStep(context),
              _Step.probing => _probing(context),
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

  Widget _logo({double size = 72, bool glow = false}) => AppLogo(
    name: server.name,
    color: '64748B',
    icon: LucideIcons.plug,
    size: size,
    glow: glow,
  );

  Widget _head(BuildContext context, {String? subtitle}) {
    final scheme = context.colorScheme;
    return Column(
      children: [
        _logo(glow: true),
        const SizedBox(height: AppSpace.md),
        Text(
          server.name,
          style: context.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if ((subtitle ?? _host).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle ?? _host,
            key: const Key('serverHost'),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// Nobody at Casama checked this server: said before anything is connected.
  Widget _notChecked(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('serverNotChecked'),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: context.appColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.shieldAlert,
            size: 18,
            color: context.appColors.warning,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              _host.isEmpty
                  ? l10n.serverNotCheckedShort
                  : l10n.serverNotChecked(_host),
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  bool get _addressOk {
    final u = Uri.tryParse(_address.text.trim());
    return u != null && u.scheme == 'https' && u.host.contains('.');
  }

  Widget _addressStep(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _head(context, subtitle: ''),
        const SizedBox(height: AppSpace.lg),
        _notChecked(context),
        const SizedBox(height: AppSpace.md),
        TextField(
          key: const Key('serverAddress'),
          controller: _address,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l10n.serverAddressLabel,
            hintText: 'https://',
            helperText: l10n.serverAddressHelp,
            helperMaxLines: 3,
            prefixIcon: const Icon(LucideIcons.link, size: 20),
            suffixIcon: IconButton(
              tooltip: l10n.pasteLabel,
              icon: const Icon(LucideIcons.clipboardPaste, size: 18),
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  setState(() => _address.text = data!.text!.trim());
                }
              },
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _addressOk ? _check() : null,
        ),
        const SizedBox(height: AppSpace.lg),
        GlowButton(
          key: const Key('serverAddressNext'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _addressOk ? _check : null,
          child: Text(l10n.continueLabel),
        ),
      ],
    );
  }

  Widget _probing(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _head(context),
      const SizedBox(height: AppSpace.lg),
      const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
      const SizedBox(height: AppSpace.sm),
      Text(
        context.l10n.serverChecking,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpace.md),
    ],
  );

  Widget _intro(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final busy = _step == _Step.connecting;
    final method = _method;
    final keyOk = method != 'api_key' || _key.text.trim().length >= 4;
    final muted = context.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _head(context),
        const SizedBox(height: AppSpace.lg),
        _notChecked(context),
        const SizedBox(height: AppSpace.md),
        if (method == 'oauth')
          Text(
            l10n.serverSignInOn(_probe?.signInHost ?? _host),
            key: const Key('serverSignInOn'),
            textAlign: TextAlign.center,
            style: muted,
          ),
        if (method == 'none')
          Text(l10n.serverNoSignIn, textAlign: TextAlign.center, style: muted),
        if (method == 'api_key') ...[
          if (_signsIn && !_signInWorks) ...[
            Text(
              l10n.serverSignInUnavailable(server.name),
              textAlign: TextAlign.center,
              style: muted,
            ),
            const SizedBox(height: AppSpace.md),
          ],
          TextField(
            key: const Key('serverKey'),
            controller: _key,
            obscureText: !_showKey,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l10n.authApiKey,
              prefixIcon: const Icon(LucideIcons.keyRound, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.pasteLabel,
                    icon: const Icon(LucideIcons.clipboardPaste, size: 18),
                    onPressed: () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (data?.text != null) {
                        setState(() => _key.text = data!.text!.trim());
                      }
                    },
                  ),
                  IconButton(
                    tooltip: _showKey ? l10n.hide : l10n.show,
                    icon: Icon(
                      _showKey ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _showKey = !_showKey),
                  ),
                ],
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(
            key: const Key('serverHeader'),
            controller: _header,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l10n.serverHeaderLabel,
              hintText: 'Authorization',
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        GlowButton.icon(
          key: const Key('connectServerSubmit'),
          style: GlowButton.glow(context).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          ),
          onPressed: busy || !keyOk ? null : _connect,
          icon: busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : Icon(
                  method == 'oauth'
                      ? LucideIcons.arrowUpRight
                      : LucideIcons.plug,
                  size: 18,
                ),
          label: Text(
            busy
                ? l10n.connectingLabel
                : (method == 'oauth'
                      ? l10n.continueWith(server.name)
                      : l10n.connect),
          ),
        ),
        if (_signInWorks) ...[
          const SizedBox(height: AppSpace.xs),
          TextButton(
            key: const Key('serverSwitchMethod'),
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
            onPressed: busy ? null : () => setState(() => _useKey = !_useKey),
            child: Text(_useKey ? l10n.serverUseSignIn : l10n.serverUseKey),
          ),
        ],
        // Nothing is stored for a server that needs no sign-in or key.
        if (_method != 'none') ...[
          const SizedBox(height: AppSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.shieldCheck,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.privacyNote,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

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
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: scheme.primary.withValues(alpha: 0.8),
                  ),
                ),
                _logo(size: 64),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          l10n.finishSignIn(server.name),
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.finishSignInHelp(server.name),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        OutlinedButton.icon(
          key: const Key('reopenServerSignIn'),
          onPressed: _openSignIn,
          icon: const Icon(LucideIcons.externalLink, size: 16),
          label: Text(l10n.reopenSignIn),
        ),
        const SizedBox(height: AppSpace.xs),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _success(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final i = _result!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _logo(glow: true),
              Positioned(
                right: -6,
                bottom: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.appColors.positive,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 3),
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          l10n.appConnected(server.name),
          key: const Key('serverConnected'),
          textAlign: TextAlign.center,
          style: context.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.appToolsReady(i.tools.length),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (server.botId != null && i.tools.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          Text(l10n.serverToolsTitle, style: context.textTheme.titleSmall),
          Text(
            l10n.serverToolsHelp,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          for (final t in i.tools)
            SwitchListTile(
              key: Key('serverTool-${t.name}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(t.name),
              subtitle: t.description.isEmpty || t.description == t.name
                  ? null
                  : Text(
                      t.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              value: !_off.contains(t.name),
              onChanged: (v) =>
                  setState(() => v ? _off.remove(t.name) : _off.add(t.name)),
            ),
        ],
        const SizedBox(height: AppSpace.lg),
        GlowButton(
          key: const Key('connectServerDone'),
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
        _head(context),
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
                    Text(
                      l10n.connectFailedTitle,
                      style: context.textTheme.titleSmall,
                    ),
                    if ((_error ?? '').isNotEmpty)
                      SelectableText(
                        _error!,
                        key: const Key('serverError'),
                        style: context.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        GlowButton(
          key: const Key('connectServerRetry'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          // Back to where the person can change something: the address they typed, the key, or
          // (when the server never answered) another try at asking it.
          onPressed: () => _probe != null
              ? setState(() => _step = _Step.intro)
              : _typed
              ? setState(() => _step = _Step.address)
              : _check(),
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}
