/// Which addresses a local MCP server may have (D-096, D-363).
library;

import 'dart:io';

const _loopback = {'127.0.0.1', '::1', '[::1]', 'localhost'};

/// Why [uri] can't be a local MCP server's address, or null when it can. Without [network], only
/// http on this computer. With it: https anywhere, http on this computer, private and link-local
/// addresses, and local names (one word, .local, .lan, .home.arpa, .internal).
String? localMcpAddressProblem(Uri? uri, {bool network = false}) {
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return 'Enter a full address, like http://127.0.0.1:3845/mcp';
  }
  if (uri.userInfo.isNotEmpty) {
    return 'Put the password in Sign-in, not in the address';
  }
  final host = uri.host.toLowerCase();
  if (!network) {
    return uri.scheme == 'http' &&
            _loopback.contains(host) &&
            host != 'localhost'
        ? null
        : 'Use an address on this computer: http://127.0.0.1 or http://[::1]';
  }
  if (uri.scheme == 'https') return null;
  if (uri.scheme != 'http') return 'Use an http:// or https:// address';
  return isLocalNetworkHost(host)
      ? null
      : 'Use https:// for servers outside your own network';
}

/// This computer, a private or link-local address, or a name only a local network resolves.
bool isLocalNetworkHost(String host) {
  final h = host.toLowerCase().replaceAll(RegExp(r'^\[|\]$'), '');
  if (_loopback.contains(h) || h == '::1') return true;
  final ip = InternetAddress.tryParse(h);
  if (ip != null) {
    if (ip.isLoopback || ip.isLinkLocal) return true;
    if (ip.type == InternetAddressType.IPv4) {
      final b = ip.rawAddress;
      return b[0] == 10 ||
          (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
          (b[0] == 192 && b[1] == 168) ||
          (b[0] == 100 && b[1] >= 64 && b[1] <= 127);
    }
    return (ip.rawAddress[0] & 0xfe) == 0xfc; // fc00::/7, unique local
  }
  return !h.contains('.') ||
      h.endsWith('.local') ||
      h.endsWith('.lan') ||
      h.endsWith('.home.arpa') ||
      h.endsWith('.internal');
}
