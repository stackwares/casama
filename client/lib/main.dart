import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/providers.dart';
import 'core/supabase_backend.dart';
import 'core/telemetry.dart';

/// Connects to the API and Supabase and returns the app widget with its backend.
Future<(Widget, SupabaseBackend)> bootstrap(AppConfig config) async {
  // Supabase settings come from the API, so a build only needs the API URL.
  final connection = await KasamaClient.connect(config.apiUrl);
  await Supabase.initialize(url: connection.config.supabaseUrl, publishableKey: connection.config.supabaseAnonKey);
  final supabase = Supabase.instance.client;
  final api = await SupabaseBackend.connectApi(config.apiUrl, supabase);
  final backend = SupabaseBackend(supabase, api, config: connection.config);
  final app = ProviderScope(overrides: [backendProvider.overrideWithValue(backend)], child: const KasamaApp());
  return (app as Widget, backend);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (app, _) = await bootstrap(AppConfig.fromEnvironment);
  await Telemetry.run(app);
}
