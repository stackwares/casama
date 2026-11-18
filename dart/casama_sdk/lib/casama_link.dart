/// Casama Link for whoever runs a self-hosted server: the CLI and the desktop app (D-296).
///
/// A server is linked to a Casama Cloud workspace by a short code someone approves in a browser,
/// and with the key that follows it gets a public https address (remote access), so phones reach it
/// with no domain and no open port. This library is the part both callers share: the calls to
/// Casama Cloud, and the settings a self-host stack needs when remote access turns on or off.
/// Running the stack's installer with those settings is the caller's job.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Casama Cloud's own address; self-hosted clouds pass theirs.
const casamaCloudUrl = 'https://api.casama.ai';

/// Casama Cloud refused, or couldn't be reached. [code] is stable: plan_limit, suspended,
/// remote_access_unavailable, address_unavailable, unauthorized, link_expired, unreachable.
class LinkException implements Exception {
  LinkException(this.code, this.message, {this.status});
  final String code;
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// What a server shows while it waits to be linked.
class LinkCode {
  const LinkCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUrl,
    required this.interval,
    required this.expiresIn,
  });

  /// Kept by the server; collects the key once the code is approved.
  final String deviceCode;

  /// Shown to the person, like K7QM-2XFD.
  final String userCode;

  /// Where they approve it (the code is already in the address).
  final Uri verificationUrl;
  final Duration interval;
  final Duration expiresIn;
}

class LinkResult {
  const LinkResult({
    required this.key,
    required this.workspace,
    required this.scopes,
  });

  /// The server's key (`kcc_…`), handed over once.
  final String key;
  final String workspace;
  final List<String> scopes;
}

/// A server's public address.
class RemoteAddress {
  const RemoteAddress({
    required this.address,
    required this.pagesAddress,
    required this.generation,
  });
  final String address;
  final String pagesAddress;
  final int generation;
}

/// What Casama Cloud knows about a server's address.
class RemoteInfo {
  const RemoteInfo({
    required this.status,
    required this.address,
    required this.pagesAddress,
    this.reason,
    this.connector,
    this.lastSeenAt,
    this.liveView,
  });

  /// Live video for people away from the server's machine: `included` (the workspace's plan has
  /// it), `plan` (a higher plan has it; they see screenshots), or null when it isn't known.
  final String? liveView;

  /// active, parked, released or suspended.
  final String status;
  final String address;
  final String pagesAddress;
  final String? reason;

  /// healthy or degraded when a connector is attached; inactive or down when not; null when
  /// there is no tunnel (or the provider didn't answer).
  final String? connector;
  final DateTime? lastSeenAt;

  bool get connected => connector == 'healthy' || connector == 'degraded';
}

/// A new id for a server (a random UUID). Kept in the stack's settings: the same id gets the same
/// address back.
String newInstanceId([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// The calls a self-hosted server makes to Casama Cloud (`/link/v1`).
class CasamaLinkClient {
  CasamaLinkClient({
    String cloudUrl = casamaCloudUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 40),
  }) : cloudUrl = cloudUrl.replaceAll(RegExp(r'/+$'), ''),
       _http = client ?? http.Client();

  final String cloudUrl;
  final http.Client _http;
  final Duration timeout;

  void close() => _http.close();

  Future<(int, Map<String, dynamic>)> _call(
    String method,
    String path, {
    String? key,
    Map<String, Object?>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$cloudUrl/link/v1$path')
        .replace(queryParameters: query);
    final req = http.Request(method, uri);
    if (key != null) req.headers['authorization'] = 'Bearer $key';
    if (body != null) {
      req.headers['content-type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    try {
      final res = await http.Response.fromStream(
        await _http.send(req).timeout(timeout),
      );
      Map<String, dynamic> json = const {};
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {
        // A proxy or an outage answered with something that isn't the API's JSON.
      }
      return (res.statusCode, json);
    } on TimeoutException {
      throw LinkException(
        'unreachable',
        'Casama Cloud did not answer. Check the internet connection and try again.',
      );
    } on http.ClientException catch (e) {
      throw LinkException(
        'unreachable',
        'Casama Cloud could not be reached (${e.message}).',
      );
    }
  }

  Never _refuse(int status, Map<String, dynamic> json) {
    // /link/v1 answers { code, message }; rate limits and unknown routes answer problem JSON.
    final code =
        (json['code'] as String?) ??
        (status == 404 ? 'not_available' : 'error');
    final message =
        (json['message'] ?? json['detail'] ?? json['title']) as String?;
    throw LinkException(
      code,
      message ??
          (status == 404
              ? 'This Casama Cloud does not give out addresses.'
              : 'Casama Cloud answered $status.'),
      status: status,
    );
  }

  /// Asks to link a server. Show [LinkCode.userCode] and open [LinkCode.verificationUrl].
  Future<LinkCode> startLink({
    required String instanceId,
    required String instanceName,
    String? platform,
    String? version,
  }) async {
    final (status, j) = await _call(
      'POST',
      '/sign-in/start',
      body: {
        'instance_id': instanceId,
        'instance_name': instanceName,
        'platform': ?platform,
        'version': ?version,
      },
    );
    if (status != 200) _refuse(status, j);
    return LinkCode(
      deviceCode: j['device_code'] as String,
      userCode: j['user_code'] as String,
      verificationUrl: Uri.parse(j['verification_url'] as String),
      interval: Duration(seconds: (j['interval'] as num?)?.toInt() ?? 3),
      expiresIn: Duration(seconds: (j['expires_in'] as num?)?.toInt() ?? 900),
    );
  }

  /// One poll: the key once the code was approved, null while it's still waiting.
  /// Throws [LinkException] `link_expired` when the code ran out or was already used.
  Future<LinkResult?> pollLink(String deviceCode) async {
    final (status, j) = await _call(
      'POST',
      '/sign-in/poll',
      body: {'device_code': deviceCode},
    );
    if (status != 200) _refuse(status, j);
    switch (j['status']) {
      case 'pending':
        return null;
      case 'approved':
        return LinkResult(
          key: j['key'] as String,
          workspace: (j['workspace'] as String?) ?? '',
          scopes: ((j['scopes'] as List?) ?? const []).cast<String>(),
        );
      default:
        throw LinkException(
          'link_expired',
          'That code ran out before it was approved. Start again.',
        );
    }
  }

  /// Polls until the code is approved. [cancelled] is checked between polls; a cancelled wait
  /// throws `cancelled`. A poll that fails for a moment (no network) is tried again.
  Future<LinkResult> waitForLink(
    LinkCode code, {
    bool Function()? cancelled,
    Future<void> Function(Duration)? sleep,
  }) async {
    final wait = sleep ?? Future<void>.delayed;
    final until = DateTime.now().add(code.expiresIn);
    while (DateTime.now().isBefore(until)) {
      if (cancelled?.call() ?? false) {
        throw LinkException('cancelled', 'Linking was cancelled.');
      }
      try {
        final r = await pollLink(code.deviceCode);
        if (r != null) return r;
      } on LinkException catch (e) {
        if (e.code != 'unreachable' && e.status != 429) rethrow;
      }
      await wait(code.interval);
    }
    throw LinkException(
      'link_expired',
      'That code ran out before it was approved. Start again.',
    );
  }

  /// What the key may do: `remote_access` and `push` for a linked server.
  Future<Map<String, dynamic>> whoami(String key) async {
    final (status, j) = await _call('GET', '/whoami', key: key);
    if (status != 200) _refuse(status, j);
    return j;
  }

  /// This server's address. Safe to repeat: the same [instanceId] gets the same address.
  Future<RemoteAddress> address(
    String key, {
    required String instanceId,
    String? instanceName,
    String? platform,
    String? version,
  }) async {
    final (status, j) = await _call(
      'PUT',
      '/remote',
      key: key,
      body: {
        'instance_id': instanceId,
        'instance_name': ?instanceName,
        'platform': ?platform,
        'version': ?version,
      },
    );
    if (status != 200) _refuse(status, j);
    return RemoteAddress(
      address: j['address'] as String,
      pagesAddress: j['pages_address'] as String,
      generation: (j['generation'] as num).toInt(),
    );
  }

  /// The address and whether a connector is attached; null when this server has none.
  Future<RemoteInfo?> info(String key, String instanceId) async {
    final (status, j) = await _call(
      'GET',
      '/remote',
      key: key,
      query: {'instance_id': instanceId},
    );
    if (status == 404 && j['code'] == 'not_found') return null;
    if (status != 200) _refuse(status, j);
    final seen = j['last_seen_at'] as String?;
    return RemoteInfo(
      status: j['status'] as String,
      address: j['address'] as String,
      pagesAddress: j['pages_address'] as String,
      reason: j['reason'] as String?,
      connector: (j['connector'] as Map?)?['state'] as String?,
      lastSeenAt: seen == null ? null : DateTime.tryParse(seen),
      liveView: j['live_view'] is String ? j['live_view'] as String : null,
    );
  }

  /// Turns remote access off at Casama Cloud. The address stays reserved for a while.
  Future<void> release(String key, String instanceId) async {
    final (status, j) = await _call(
      'DELETE',
      '/remote',
      key: key,
      query: {'instance_id': instanceId},
    );
    if (status != 200) _refuse(status, j);
  }
}

// ---------------------------------------------------------------------------
// The self-host stack's settings
// ---------------------------------------------------------------------------

/// Reads `KEY=VALUE` lines (the stack's `.env`); the last value of a key wins.
Map<String, String> parseStackEnv(String text) {
  final out = <String, String>{};
  for (final line in const LineSplitter().convert(text)) {
    final m = RegExp(r'^([A-Z_][A-Z0-9_]*)=(.*)$').firstMatch(line);
    if (m != null) out[m.group(1)!] = m.group(2)!;
  }
  return out;
}

/// The settings remote access changes, and how to get back.
abstract final class RemoteAccessSettings {
  /// The keys remote access sets and restores when it turns off.
  static const changed = [
    'CASAMA_PUBLIC_URL',
    'CASAMA_PAGES_URL',
    'SIGNUP_HOOK_URI',
    'TRUSTED_CLIENT_IP_HEADER',
    'AUTH_RATE_LIMIT_HEADER',
    'DISABLE_SIGNUP',
    'SIGNUP_HOOK_ENABLED',
    'SIGNUP_INVITED_ONLY',
  ];

  /// Whether invited people may make an account while remote access is on.
  static bool invitesOn(Map<String, String> env) =>
      isOn(env) &&
      env['SIGNUP_INVITED_ONLY'] == 'true' &&
      env['DISABLE_SIGNUP'] != 'true';

  /// Where the values from before are kept (base64 JSON), so turning off restores them exactly.
  static const savedKey = 'CASAMA_REMOTE_ACCESS_BEFORE';

  static bool isOn(Map<String, String> env) =>
      env['CASAMA_REMOTE_ACCESS'] == 'on';

  /// Whether the stack already has an address others can reach (a domain, or someone's own
  /// tunnel): such a server doesn't need remote access.
  static bool hasOwnPublicAddress(Map<String, String> env) {
    if (isOn(env)) return false;
    final url = Uri.tryParse(env['CASAMA_PUBLIC_URL'] ?? '');
    if (url == null || !url.hasScheme) return false;
    return url.scheme == 'https' && !isLoopback(url.host);
  }

  static bool isLoopback(String host) =>
      host == 'localhost' ||
      host == '::1' ||
      host == '[::1]' ||
      host.startsWith('127.');

  /// What to merge into the stack's settings when remote access turns on at [address].
  ///
  /// The address becomes the server's public one (sign-in links, webhooks and phones use it), the
  /// old address stays as the one its own machine uses, sign-ups close, and the real caller
  /// address is read from the tunnel's header so sign-in limits count per person.
  ///
  /// With [invites], sign-ups aren't closed outright: Auth asks the server's sign-up hook, which
  /// lets in only an email someone on the server invited. Closed is the default because it
  /// depends on nothing else being set right.
  static Map<String, String> on(
    Map<String, String> env, {
    required String cloudUrl,
    required String key,
    required String instanceId,
    required RemoteAddress address,
    bool invites = false,
  }) {
    final already = isOn(env);
    final before = already ? null : {for (final k in changed) k: env[k] ?? ''};
    final local = env['CASAMA_LOCAL_URL']?.isNotEmpty == true
        ? env['CASAMA_LOCAL_URL']!
        : (env['CASAMA_PUBLIC_URL'] ?? '');
    return {
      'CASAMA_CLOUD_URL': cloudUrl,
      'CASAMA_CLOUD_KEY': key,
      'CASAMA_INSTANCE_ID': instanceId,
      'CASAMA_REMOTE_ACCESS': 'on',
      'CASAMA_LOCAL_URL': local,
      'CASAMA_PUBLIC_URL': address.address,
      'CASAMA_PAGES_URL': address.pagesAddress,
      'SIGNUP_HOOK_URI': '${address.address}/hooks/auth/before-user-created',
      'TRUSTED_CLIENT_IP_HEADER': 'cf-connecting-ip',
      'AUTH_RATE_LIMIT_HEADER': 'cf-connecting-ip',
      'DISABLE_SIGNUP': invites ? 'false' : 'true',
      // The hook only matters while sign-ups aren't closed; left as it was otherwise.
      if (invites) 'SIGNUP_HOOK_ENABLED': 'true',
      'SIGNUP_INVITED_ONLY': invites ? 'true' : 'false',
      savedKey: ?(before == null
          ? null
          : base64Url.encode(utf8.encode(jsonEncode(before)))),
    };
  }

  /// What to merge when it turns off: the values from before, exactly. The link to Casama Cloud
  /// (the key and the server's id) is kept, so the same address comes back next time.
  static Map<String, String> off(Map<String, String> env) {
    var before = <String, String>{};
    try {
      final saved = env[savedKey];
      if (saved != null && saved.isNotEmpty) {
        before = (jsonDecode(utf8.decode(base64Url.decode(saved))) as Map)
            .cast<String, String>();
      }
    } catch (_) {
      // Unreadable: fall back to the address on this machine below.
    }
    final local = env['CASAMA_LOCAL_URL'] ?? '';
    return {
      'CASAMA_REMOTE_ACCESS': 'off',
      for (final k in changed) k: before[k] ?? '',
      // Without a saved value the server would keep an address that no longer answers.
      if ((before['CASAMA_PUBLIC_URL'] ?? '').isEmpty && local.isNotEmpty)
        'CASAMA_PUBLIC_URL': local,
      'CASAMA_LOCAL_URL': '',
      savedKey: '',
    };
  }
}

/// Merges [changes] into the stack's `.env`: existing keys are replaced where they stand, new ones
/// are added at the end, and everything else is left as it was. The file holds every key of the
/// installation, so it is written whole (never half) and stays readable by its owner only.
Future<void> updateStackEnv(File file, Map<String, String> changes) async {
  final lines = const LineSplitter().convert(await file.readAsString());
  final left = Map.of(changes);
  final out = <String>[];
  for (final line in lines) {
    final key = RegExp(r'^([A-Z_][A-Z0-9_]*)=').firstMatch(line)?.group(1);
    if (key == null || !changes.containsKey(key)) {
      out.add(line);
    } else if (left.containsKey(key)) {
      // The first line of a key carries the new value; repeats of it go.
      out.add('$key=${left.remove(key)}');
    }
  }
  for (final e in left.entries) {
    out.add('${e.key}=${e.value}');
  }
  final tmp = File('${file.path}.tmp');
  await tmp.writeAsString('${out.join('\n')}\n', flush: true);
  if (!Platform.isWindows) await Process.run('chmod', ['600', tmp.path]);
  await tmp.rename(file.path);
}

enum RemoteSetupStep {
  /// Waiting for someone to approve the code ([RemoteSetupProgress.code]).
  linking,

  /// Casama Cloud is making the address.
  address,

  /// The stack restarts with the new settings ([RemoteSetupProgress.detail]: the installer's lines).
  restarting,

  /// The connector is dialling out.
  connecting,

  /// Done: [RemoteSetupProgress.address] answers.
  ready,

  /// Remote access is off again.
  off,
}

class RemoteSetupProgress {
  const RemoteSetupProgress(this.step, {this.code, this.address, this.detail});
  final RemoteSetupStep step;
  final LinkCode? code;
  final String? address;
  final String? detail;
}

/// Turns remote access on or off for the self-host stack in [stackDir] (the folder with
/// `install.sh`). Used by `casama selfhost remote` and by the desktop app's local server.
///
/// Before turning it on, the caller makes sure the server already has its owner's account:
/// sign-ups close when the address opens, and until then the first account to sign up owns the
/// server.
class RemoteAccessSetup {
  RemoteAccessSetup({
    required this.stackDir,
    required this.runInstaller,
    this.defaultCloudUrl = casamaCloudUrl,
    this.instanceName = 'Casama server',
    this.platform,
    this.version,
    http.Client? client,
    this.sleep = Future<void>.delayed,
    this.connectTimeout = const Duration(minutes: 3),
  }) : _client = client ?? http.Client();

  final Directory stackDir;

  /// Runs the stack's installer again (`bash install.sh`, which keeps the `.env` and restarts what
  /// changed), passing each line it prints to [onLine]. Returns its exit code.
  final Future<int> Function(void Function(String line) onLine) runInstaller;
  final String defaultCloudUrl;
  final String instanceName;
  final String? platform;
  final String? version;
  final http.Client _client;
  final Future<void> Function(Duration) sleep;
  final Duration connectTimeout;

  File get envFile => File('${stackDir.path}/infra/compose/.env');

  Future<Map<String, String>> readEnv() async {
    if (!envFile.existsSync()) {
      throw LinkException(
        'not_installed',
        'This server isn\'t installed yet (no ${envFile.path}).',
      );
    }
    return parseStackEnv(await envFile.readAsString());
  }

  CasamaLinkClient _cloud(Map<String, String> env) => CasamaLinkClient(
    cloudUrl: (env['CASAMA_CLOUD_URL'] ?? '').isNotEmpty
        ? env['CASAMA_CLOUD_URL']!
        : defaultCloudUrl,
    client: _client,
  );

  /// Waits for the code to be approved and keeps the key in the stack's settings. Kept at once:
  /// the key is handed over a single time.
  Future<String> _finishLink(
    CasamaLinkClient cloud,
    LinkCode code,
    String instanceId,
    bool Function()? cancelled,
  ) async {
    final linked = await cloud.waitForLink(
      code,
      cancelled: cancelled,
      sleep: sleep,
    );
    await updateStackEnv(envFile, {
      'CASAMA_CLOUD_URL': cloud.cloudUrl,
      'CASAMA_CLOUD_KEY': linked.key,
      'CASAMA_INSTANCE_ID': instanceId,
    });
    return linked.key;
  }

  /// Links the server to Casama Cloud and nothing more: no address, no change to who can reach
  /// it. For a server on its own domain, whose notifications then reach the apps from the stores
  /// through Casama Cloud (only Casama's keys can address those apps).
  ///
  /// Yields [RemoteSetupStep.linking] with the code to approve, [RemoteSetupStep.restarting] while
  /// the server picks the key up, and ends with [RemoteSetupStep.ready]. A server whose key can
  /// already send notifications ends at once, unless [relink].
  Stream<RemoteSetupProgress> link({
    bool Function()? cancelled,
    bool relink = false,
  }) async* {
    final env = await readEnv();
    final cloud = _cloud(env);
    final instanceId = (env['CASAMA_INSTANCE_ID'] ?? '').isNotEmpty
        ? env['CASAMA_INSTANCE_ID']!
        : newInstanceId();
    final key = relink ? '' : (env['CASAMA_CLOUD_KEY'] ?? '');
    if (key.isNotEmpty) {
      var revoked = false;
      try {
        final who = await cloud.whoami(key);
        if (who['push'] == true) {
          yield const RemoteSetupProgress(RemoteSetupStep.ready);
          return;
        }
      } on LinkException catch (e) {
        // A revoked key: link again. Anything else (no network) is told.
        if (e.status != 401) rethrow;
        revoked = true;
      }
      if (!revoked) {
        throw LinkException(
          'key_scope',
          'This server\'s Casama Cloud key can\'t send notifications. Link it again to get one that can. A key\'s scopes can\'t be changed, so if this server also uses cloud computers or credits, create a new key in Casama Cloud with those scopes too.',
        );
      }
    }
    final code = await cloud.startLink(
      instanceId: instanceId,
      instanceName: instanceName,
      platform: platform,
      version: version,
    );
    yield RemoteSetupProgress(RemoteSetupStep.linking, code: code);
    await _finishLink(cloud, code, instanceId, cancelled);

    yield const RemoteSetupProgress(RemoteSetupStep.restarting);
    final lines = StreamController<String>();
    final exit = runInstaller(lines.add).whenComplete(lines.close);
    await for (final l in lines.stream) {
      yield RemoteSetupProgress(RemoteSetupStep.restarting, detail: l);
    }
    if (await exit != 0) {
      throw LinkException(
        'install_failed',
        'The server didn\'t restart cleanly. Its link is saved; run the installer again to finish.',
      );
    }
    yield const RemoteSetupProgress(RemoteSetupStep.ready);
  }

  /// Links the server if it isn't linked, gets its address, switches the stack over and waits for
  /// the connector. Yields each step; ends with [RemoteSetupStep.ready]. Throws [LinkException]
  /// (`has_address`, `key_scope`, `plan_limit`, `install_failed`, `not_connected`, …).
  ///
  /// [relink] asks for a new link even when the server has a key. [invites] says whether invited
  /// people may make an account while it is on (see [RemoteAccessSettings.on]); left out, a server
  /// that is already on keeps what it had and a new one starts closed.
  Stream<RemoteSetupProgress> turnOn({
    bool Function()? cancelled,
    bool relink = false,
    bool? invites,
  }) async* {
    var env = await readEnv();
    final letInvited = invites ?? RemoteAccessSettings.invitesOn(env);
    if (RemoteAccessSettings.hasOwnPublicAddress(env)) {
      throw LinkException(
        'has_address',
        'This server already has a public address (${env['CASAMA_PUBLIC_URL']}). Remote access is for servers without one.',
      );
    }
    final cloud = _cloud(env);
    final instanceId = (env['CASAMA_INSTANCE_ID'] ?? '').isNotEmpty
        ? env['CASAMA_INSTANCE_ID']!
        : newInstanceId();
    var key = relink ? '' : (env['CASAMA_CLOUD_KEY'] ?? '');
    if (key.isNotEmpty) {
      try {
        final who = await cloud.whoami(key);
        if (who['remote_access'] != true) {
          throw LinkException(
            'key_scope',
            'This server\'s Casama Cloud key can\'t hold an address. Link it again to get one that can. A key\'s scopes can\'t be changed, so if this server also uses cloud computers or credits, create a new key in Casama Cloud with those scopes too.',
          );
        }
      } on LinkException catch (e) {
        // A revoked key: link again. Anything else (no network, the wrong kind of key) is told.
        if (e.status != 401) rethrow;
        key = '';
      }
    }
    if (key.isEmpty) {
      final code = await cloud.startLink(
        instanceId: instanceId,
        instanceName: instanceName,
        platform: platform,
        version: version,
      );
      yield RemoteSetupProgress(RemoteSetupStep.linking, code: code);
      key = await _finishLink(cloud, code, instanceId, cancelled);
      env = await readEnv();
    }

    yield const RemoteSetupProgress(RemoteSetupStep.address);
    final address = await cloud.address(
      key,
      instanceId: instanceId,
      instanceName: instanceName,
      platform: platform,
      version: version,
    );
    await updateStackEnv(
      envFile,
      RemoteAccessSettings.on(
        env,
        cloudUrl: cloud.cloudUrl,
        key: key,
        instanceId: instanceId,
        address: address,
        invites: letInvited,
      ),
    );

    yield RemoteSetupProgress(
      RemoteSetupStep.restarting,
      address: address.address,
    );
    final lines = StreamController<String>();
    final exit = runInstaller(lines.add).whenComplete(lines.close);
    await for (final l in lines.stream) {
      yield RemoteSetupProgress(
        RemoteSetupStep.restarting,
        address: address.address,
        detail: l,
      );
    }
    if (await exit != 0) {
      throw LinkException(
        'install_failed',
        'The server didn\'t restart cleanly. Its settings are saved; run the installer again to finish.',
      );
    }

    yield RemoteSetupProgress(
      RemoteSetupStep.connecting,
      address: address.address,
    );
    final until = DateTime.now().add(connectTimeout);
    while (true) {
      if (cancelled?.call() ?? false) {
        throw LinkException('cancelled', 'Cancelled.');
      }
      try {
        if ((await cloud.info(key, instanceId))?.connected ?? false) break;
      } on LinkException catch (e) {
        if (e.code != 'unreachable') rethrow;
      }
      if (!DateTime.now().isBefore(until)) {
        throw LinkException(
          'not_connected',
          'The address is set up, but this server\'s connector hasn\'t reached it yet. A network that blocks outbound port 7844 (a VPN or a strict firewall) is the usual cause.',
        );
      }
      await sleep(const Duration(seconds: 3));
    }
    yield RemoteSetupProgress(RemoteSetupStep.ready, address: address.address);
  }

  /// Turns remote access off: the address stops answering and the server is on this machine only
  /// again, with the settings it had before. The link to Casama Cloud is kept.
  Stream<RemoteSetupProgress> turnOff() async* {
    final env = await readEnv();
    final key = env['CASAMA_CLOUD_KEY'] ?? '';
    final id = env['CASAMA_INSTANCE_ID'] ?? '';
    if (key.isNotEmpty && id.isNotEmpty) {
      try {
        await _cloud(env).release(key, id);
      } on LinkException {
        // Off on this server is what matters; Casama Cloud parks an address nobody uses.
      }
    }
    await updateStackEnv(envFile, RemoteAccessSettings.off(env));
    yield const RemoteSetupProgress(RemoteSetupStep.restarting);
    final lines = StreamController<String>();
    final exit = runInstaller(lines.add).whenComplete(lines.close);
    await for (final l in lines.stream) {
      yield RemoteSetupProgress(RemoteSetupStep.restarting, detail: l);
    }
    if (await exit != 0) {
      throw LinkException(
        'install_failed',
        'The server didn\'t restart cleanly. Its settings are saved; run the installer again to finish.',
      );
    }
    yield const RemoteSetupProgress(RemoteSetupStep.off);
  }
}
