/// Build-time configuration. Override with --dart-define=CASAMA_API_URL=https://api.example.com
/// (an empty value on web means "the server that serves this page"; users can also pick a server
/// at sign-in, see ServerAddress).
class AppConfig {
  const AppConfig({required this.apiUrl});

  final String apiUrl;

  static const fromEnvironment = AppConfig(
    apiUrl: String.fromEnvironment('CASAMA_API_URL', defaultValue: 'http://localhost:8787'),
  );
}
