import 'package:casama_api/casama_api.dart';

/// The generated client; most apps use package:casama_sdk, which adds auth and run streams.
Future<void> main() async {
  final api = CasamaApi(basePathOverride: 'http://localhost:8787');
  final health = await api.getSystemApi().getConfig();
  print(health.data?.productName);
}
