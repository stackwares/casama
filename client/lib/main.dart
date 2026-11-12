import 'dart:async';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app.dart';
import 'core/local_cache.dart';
import 'core/config.dart';
import 'core/desktop_window.dart';
import 'core/providers.dart';
import 'core/server_address.dart';
import 'core/server_config_cache.dart';
import 'core/startup_assets.dart';
import 'core/supabase_backend.dart';
import 'core/telemetry.dart';
import 'core/timeout_http_client.dart';
import 'core/theme.dart';
import 'theme/appearance.dart';
import 'theme/fonts.dart';
import 'l10n/generated/app_localizations.dart';
import 'ui/brand_splash.dart';
import 'ui/glow_button.dart';
import 'ui/text_scale.dart';
import 'ui/friendly_error_view.dart';
import 'core/analytics.dart';

/// Connects to the API and Supabase and returns the app widget with its backend.
///
/// Supabase settings come from the API, so a build only needs the API URL. They are saved, and a
/// later launch starts from the saved ones at once (no network wait, and it opens offline with the
/// offline cache) while the server's are fetched in the background (D-158). If the server has
/// moved to another Supabase project since, [onServerMoved] reconnects.
Future<(Widget, SupabaseBackend)> bootstrap(AppConfig config, {VoidCallback? onServerMoved}) async {
  // The saved look and its Google Fonts load alongside the connection, so the app's first frame
  // already draws them and no text swaps fonts a moment later.
  final look = _savedLookWithFonts();
  final saved = await ServerConfigCache.read(config.apiUrl);
  final server = saved ?? (await CasamaClient.connect(config.apiUrl)).config;
  if (saved == null) unawaited(ServerConfigCache.write(config.apiUrl, server));
  unawaited(Telemetry.updateServerKind(apiUrl: config.apiUrl, billingEnabled: server.billingEnabled));
  unawaited(Analytics.dailyPing());
  await Supabase.initialize(url: server.supabaseUrl, publishableKey: server.supabaseAnonKey, httpClient: TimeoutHttpClient());
  final supabase = Supabase.instance.client;
  final api = await SupabaseBackend.connectApi(config.apiUrl, supabase, config: server);
  final backend = SupabaseBackend(supabase, api, config: server);
  if (saved != null) unawaited(_refreshServerConfig(config.apiUrl, api, backend, saved, onServerMoved));
  final appearance = await look;
  final app = ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      localCacheProvider.overrideWithValue(openLocalCache()),
      appearanceProvider.overrideWith(() => AppearanceNotifier(appearance)),
    ],
    child: const CasamaApp(),
  );
  return (app as Widget, backend);
}

/// The look saved on this device once its Google Fonts have loaded (see [preloadFonts]); null when
/// preferences are slow or unreadable, and the app then reads the look itself, as before.
Future<Appearance?> _savedLookWithFonts() async {
  try {
    final look = await AppearanceNotifier.readSaved().timeout(const Duration(seconds: 2));
    if (look != null) await preloadFonts(heading: look.headingFont, body: look.bodyFont);
    return look;
  } catch (_) {
    return null;
  }
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
  // A widget that fails to build shows a calm "Something went wrong" in the app's colors instead of
  // Flutter's red screen (debug) or an empty grey box (release). Telemetry still reports the error.
  ErrorWidget.builder = (details) => FriendlyErrorView(details: details);
  // Desktop: a window sized for the sidebar, chat and computer panel, or where it was last.
  await setUpDesktopWindow();
  // Draw at once; connecting happens behind the startup gate (never block runApp on the network).
  await Telemetry.run(const StartupGate(config: AppConfig.fromEnvironment));
}

/// Connects to the server. The first frame is the launch cloud, which then plays; a failure offers a retry.
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

  /// The first screens' pictures, decoding while the app connects (see [precacheStartupAssets]).
  Future<void>? _assets;

  /// The brand loop, decoded while the launch still is up. Null until then; the still stands in.
  LottieComposition? _brand;

  /// Stays up over the ready app until the cloud has faded out.
  var _splash = true;

  @override
  void initState() {
    super.initState();
    // Self-hosters point the app at their own server (D-076); the choice is remembered.
    onChangeServer = _switchServer;
    unawaited(_loadBrand());
    _start();
  }

  Future<void> _loadBrand() async {
    try {
      final composition = await AssetLottie(BrandSplash.lottieAsset).load();
      if (mounted) setState(() => _brand = composition);
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assets ??= precacheStartupAssets(context);
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      _config = await ServerAddress.load(fallback: widget.config);
      final connect = widget.connect ?? (c) async => (await bootstrap(c, onServerMoved: _reconnect)).$1;
      final app = await connect(_config).timeout(const Duration(seconds: 20));
      // The first screen opens with its pictures decoded; never more than half a second's wait.
      await (_assets ?? Future<void>.value()).timeout(const Duration(milliseconds: 500), onTimeout: () {});
      if (mounted) setState(() => _app = app);
    } catch (e) {
      Analytics.log('app_startup_failed', {
        'reason': e is TimeoutException ? 'timeout' : (e is DioException && e.response == null ? 'unreachable' : 'error'),
      });
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
    setState(() {
      _app = null;
      _splash = true;
    });
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    if (app != null && !_splash) return app;
    // The same splash element stays mounted when the app arrives underneath it, so the loop and
    // the delayed label are not rebuilt for the fade. Keys keep that element when the stack gains
    // the app as a sibling.
    final gate = SplashHandoff(
      key: const ValueKey('startup-splash'),
      leaving: app != null && _error == null,
      onLeft: () {
        if (mounted) setState(() => _splash = false);
      },
      child: _frame(),
    );
    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.expand,
      children: [
        if (app != null) KeyedSubtree(key: const ValueKey('startup-app'), child: app),
        gate,
      ],
    );
  }

  Widget _frame() {
    return MaterialApp(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: limitTextScale,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          final failed = _error != null;
          return Scaffold(
            key: failed ? null : const Key('startupSplash'),
            backgroundColor: BrandSplash.backgroundOf(context),
            body: failed
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
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
                  )
                : BrandSplash(
                    composition: _brand,
                    label: Text(l10n.connectingToServer, key: const Key('startupConnecting'), textAlign: TextAlign.center),
                  ),
          );
        },
      ),
    );
  }
}
