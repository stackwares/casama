import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app.dart';
import 'core/local_cache.dart';
import 'core/config.dart';
import 'core/providers.dart';
import 'core/server_address.dart';
import 'core/supabase_backend.dart';
import 'core/telemetry.dart';
import 'core/theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'ui/glow_button.dart';

/// Connects to the API and Supabase and returns the app widget with its backend.
Future<(Widget, SupabaseBackend)> bootstrap(AppConfig config) async {
  // Supabase settings come from the API, so a build only needs the API URL.
  final connection = await KasamaClient.connect(config.apiUrl);
  await Supabase.initialize(url: connection.config.supabaseUrl, publishableKey: connection.config.supabaseAnonKey);
  final supabase = Supabase.instance.client;
  final api = await SupabaseBackend.connectApi(config.apiUrl, supabase);
  final backend = SupabaseBackend(supabase, api, config: connection.config);
  final app = ProviderScope(
    overrides: [backendProvider.overrideWithValue(backend), localCacheProvider.overrideWithValue(openLocalCache())],
    child: const KasamaApp(),
  );
  return (app as Widget, backend);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw at once; connecting happens behind the startup gate (never block runApp on the network).
  await Telemetry.run(const StartupGate(config: AppConfig.fromEnvironment));
}

/// Connects to the server, showing progress and a retry when it cannot be reached.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, required this.config, this.connect = _connectApp});
  final AppConfig config;
  final Future<Widget> Function(AppConfig) connect;

  static Future<Widget> _connectApp(AppConfig c) async => (await bootstrap(c)).$1;

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
      final app = await widget.connect(_config).timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _app = app);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _switchServer(String url) async {
    await ServerAddress.save(url);
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
