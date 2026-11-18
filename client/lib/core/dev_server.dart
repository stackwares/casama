/// Whether [apiUrl] is one of Casama's development servers rather than production: the local
/// stack (localhost, the Android emulator's 10.0.2.2, a LAN or `.local` address) or its tunnel,
/// `api-dev.casama.ai`. The app marks these with a small amber dot on your avatar, so a test
/// build pointed at the wrong server is obvious. A self-hosted server on its own domain isn't
/// one: its people never see the dot.
bool isDevServer(String apiUrl) {
  final host = Uri.tryParse(apiUrl)?.host.toLowerCase() ?? '';
  if (host.isEmpty) return false;
  if (host == 'api-dev.casama.ai' || host.endsWith('-dev.casama.ai')) {
    return true;
  }
  if (host == 'localhost' || host.endsWith('.local')) return true;
  final ip = host.split('.').map(int.tryParse).toList();
  if (ip.length != 4 || ip.contains(null)) return false;
  final (a, b) = (ip[0]!, ip[1]!);
  return a == 127 ||
      a == 10 ||
      (a == 192 && b == 168) ||
      (a == 172 && b >= 16 && b <= 31);
}

/// The host part of [apiUrl], for labels.
String serverHost(String apiUrl) => Uri.tryParse(apiUrl)?.host ?? apiUrl;
