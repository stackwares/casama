import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A stand-in for Casama Cloud's `/link/v1` (and for a server's own address), with the same
/// answers the real one gives. Shared by the SDK's tests and the CLI's.
class FakeLinkCloud {
  FakeLinkCloud({this.url = 'https://cloud.test'});

  final String url;
  final List<String> calls = [];

  /// Polls that answer "pending" before the code counts as approved.
  int pollsBeforeApproval = 1;
  int _polls = 0;
  int _links = 0;

  /// The key this cloud issued (or was told to accept).
  String? key;
  bool keyHanded = false;

  /// Whether the key may hold an address.
  bool remoteScope = true;

  /// Whether the key may send notifications.
  bool pushScope = true;
  final String label = 'k7qm2xfd9abc';
  final String zone = 'link.test';

  /// none, active, released or suspended.
  String status = 'none';
  bool connected = true;
  int generation = 0;

  /// Refuse the next request for an address: 402 (plan limit) or 403 (suspended).
  int? refuseAddress;

  /// No network at all.
  bool down = false;

  /// Whether the address answers from outside.
  bool answers = true;

  /// What the workspace's plan says about live view away from the computer: included, plan, or
  /// null when this cloud runs no relay.
  String? liveView;

  /// What the server sent with its request for an address.
  Map<String, dynamic>? lastServerInfo;

  String get address => 'https://$label.$zone';
  String get pagesAddress => 'https://$label-p.$zone';

  late final http.Client client = MockClient(_handle);

  http.Response _json(int status, Map<String, Object?> body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> _handle(http.Request req) async {
    final where = '${req.url.origin}${req.url.path}';
    calls.add('${req.method} $where');
    if (down) throw http.ClientException('Connection failed', req.url);
    if (where == '$address/readyz') {
      return answers ? _json(200, {'status': 'ok'}) : http.Response('', 530);
    }
    if (!where.startsWith('$url/link/v1')) {
      return http.Response('not found', 404);
    }
    final path = req.url.path.substring('/link/v1'.length);
    final body = req.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(req.body) as Map<String, dynamic>;

    if (path == '/sign-in/start') {
      // A new code: it can hand over a key of its own, once.
      _polls = 0;
      keyHanded = false;
      _links++;
      return _json(200, {
        'device_code': 'kcl_device-code-0123456789',
        'user_code': 'K7QM-2XFD',
        'verification_url': 'https://app.example.test/link?code=K7QM-2XFD',
        'interval': 3,
        'expires_in': 900,
      });
    }
    if (path == '/sign-in/poll') {
      if (keyHanded) return _json(200, {'status': 'expired'});
      if (++_polls <= pollsBeforeApproval) {
        return _json(200, {'status': 'pending'});
      }
      key = _links <= 1 ? 'kcc_linked-key' : 'kcc_linked-key-$_links';
      keyHanded = true;
      return _json(200, {
        'status': 'approved',
        'key': key,
        'workspace': 'Home',
        'scopes': ['remote_access', 'push'],
      });
    }

    if (key == null || req.headers['authorization'] != 'Bearer $key') {
      return _json(401, {
        'code': 'unauthorized',
        'message': 'This Casama Link key is not valid',
      });
    }
    if (path == '/whoami') {
      return _json(200, {
        'instance_name': 'Home Mac',
        'remote_access': remoteScope,
        'push': pushScope,
        'computers': false,
        'models': false,
      });
    }
    if (path == '/remote' && req.method == 'PUT') {
      lastServerInfo = body;
      final refused = refuseAddress;
      if (refused != null) {
        refuseAddress = null;
        return refused == 402
            ? _json(402, {
                'code': 'plan_limit',
                'message': 'Your plan connects 1 server. Remove one or upgrade to add more.',
              })
            : _json(403, {
                'code': 'suspended',
                'message': 'Remote access was turned off for this server',
              });
      }
      if (status != 'active') generation++;
      status = 'active';
      return _json(200, {
        'server_id': 'srv-1',
        'address': address,
        'pages_address': pagesAddress,
        'token': 'tunnel-secret',
        'generation': generation,
      });
    }
    if (path == '/remote' && req.method == 'GET') {
      if (status == 'none') {
        return _json(404, {
          'code': 'not_found',
          'message': 'This server has no address',
        });
      }
      return _json(200, {
        'status': status,
        'reason': status == 'suspended' ? 'reported' : null,
        'generation': generation,
        'address': address,
        'pages_address': pagesAddress,
        'connector': status == 'active'
            ? {'state': connected ? 'healthy' : 'inactive', 'since': null}
            : null,
        'last_seen_at': '2026-11-14T08:00:00.000Z',
        'live_view': liveView,
      });
    }
    if (path == '/remote' && req.method == 'DELETE') {
      final had = status == 'active';
      if (had) status = 'released';
      return _json(200, {'released': had});
    }
    return _json(404, {'code': 'not_found', 'message': 'No such route'});
  }
}
