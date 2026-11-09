/// Build-time configuration. Override with --dart-define=KASAMA_API_URL=https://api.example.com
class AppConfig {
  const AppConfig({required this.apiUrl});

  final String apiUrl;

  static const fromEnvironment = AppConfig(
    apiUrl: String.fromEnvironment('KASAMA_API_URL', defaultValue: 'http://localhost:8787'),
  );
}
