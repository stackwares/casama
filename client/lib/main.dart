import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app.dart';
import 'core/local_cache.dart';
import 'core/config.dart';
import 'core/desktop_window.dart';
import 'core/providers.dart';
import 'core/server_address.dart';
import 'core/server_config_cache.dart';
import 'core/supabase_backend.dart';
import 'core/telemetry.dart';
import 'core/theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'ui/glow_button.dart';

/// Connects to the API and Supabase and returns the app widget with its backend.
///
/// Supabase settings come from the API, so a build only needs the API URL. They are saved, and a
/// later launch starts from the saved ones at once (no network wait, and it opens offline with the
/// offline cache) while the server's are fetched in the background (D-158). If the server has
/// moved to another Supabase project since, [onServerMoved] reconnects.
Future<(Widget, SupabaseBackend)> bootstrap(AppConfig config, {VoidCallback? onServerMoved}) async {
  final saved = await ServerConfigCache.read(config.apiUrl);
  final server = saved ?? (await CasamaClient.connect(config.apiUrl)).config;
  if (saved == null) unawaited(ServerConfigCache.write(config.apiUrl, server));
  await Supabase.initialize(url: server.supabaseUrl, publishableKey: server.supabaseAnonKey);
  final supabase = Supabase.instance.client;
  final api = await SupabaseBackend.connectApi(config.apiUrl, supabase, config: server);
  final backend = SupabaseBackend(supabase, api, config: server);
  if (saved != null) unawaited(_refreshServerConfig(config.apiUrl, api, backend, saved, onServerMoved));
  final app = ProviderScope(
    overrides: [backendProvider.overrideWithValue(backend), localCacheProvider.overrideWithValue(openLocalCache())],
    child: const CasamaApp(),
  );
  return (app as Widget, backend);
}

/// Replaces the saved server settings with the server's; offline, the saved ones stay.
Future<void> _refreshServerConfig(String apiUrl, CasamaClient api, SupabaseBackend backend, PublicConfig saved, VoidCallback? onServerMoved) async {
  try {
    final fresh = (await api.system.getConfig()).data;
    if (fresh == null) return;
    await ServerConfigCache.write(apiUrl, fresh);
    backend.config = fresh;
    if (ServerConfigCache.moved(saved, fresh)) onServerMoved?.call();
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Desktop: a window sized for the sidebar, chat and computer panel, or where it was last.
  await setUpDesktopWindow();
  // Draw at once; connecting happens behind the startup gate (never block runApp on the network).
  await Telemetry.run(const StartupGate(config: AppConfig.fromEnvironment));
}

/// Connects to the server, showing progress and a retry when it cannot be reached.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, required this.config, this.connect});
  final AppConfig config;

  /// Builds the connected app (tests pass their own); defaults to [bootstrap].
  final Future<Widget> Function(AppConfig)? connect;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  Widget? _app;
  Object? _error;
  late AppConfig _config = widget.config;

  @override
  void initState() {
    super.initState();
    // Self-hosters point the app at their own server (D-076); the choice is remembered.
    onChangeServer = _switchServer;
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      _config = await ServerAddress.load(fallback: widget.config);
      final connect = widget.connect ?? (c) async => (await bootstrap(c, onServerMoved: _reconnect)).$1;
      final app = await connect(_config).timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _app = app);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _switchServer(String url) async {
    await ServerAddress.save(url);
    await _reconnect();
  }

  /// Starts over with a fresh Supabase client (another server, or the server moved projects).
  Future<void> _reconnect() async {
    try {
      await Supabase.instance.dispose();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _app = null);
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    if (app != null) return app;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _error == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(l10n.connectingToServer, key: const Key('startupConnecting')),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.cloudOff, size: 48, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(l10n.cannotReachServer, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text(l10n.cannotReachServerHelp(_config.apiUrl), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          GlowButton(key: const Key('startupRetry'), onPressed: _start, child: Text(l10n.retry)),
                          TextButton(
                            key: const Key('startupChangeServer'),
                            onPressed: () => changeServerDialog(
                              context,
                              _config.apiUrl,
                              title: l10n.server,
                              label: l10n.serverAddress,
                              cancel: l10n.cancel,
                              connect: l10n.connect,
                            ),
                            child: Text(l10n.changeServer),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
