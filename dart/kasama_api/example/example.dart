import 'package:kasama_api/kasama_api.dart';

/// The generated client; most apps use package:kasama_sdk, which adds auth and run streams.
Future<void> main() async {
  final api = KasamaApi(basePathOverride: 'http://localhost:8787');
  final health = await api.getSystemApi().getConfig();
  print(health.data?.productName);
}
