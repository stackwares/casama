import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:casama/features/app_browser/app_browser_channel.dart';
import 'package:casama/features/app_browser/app_browser_controller.dart';
import 'package:casama/features/app_browser/app_browser_flag.dart';
import 'package:casama/features/app_browser/app_browser_service.dart';
import 'package:casama/features/app_browser/app_browser_sites.dart';
import 'package:casama/features/app_browser/app_browser_socket.dart';
import 'package:casama/features/app_browser/app_browser_view.dart';
import 'package:casama/core/remote_config.dart' show appVersionProvider;
import 'package:material_ui/material_ui.dart';

/// A 1×1 PNG, standing in for the page's picture.
const pixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

AppBrowserGuard loadGuard() => AppBrowserGuard.fromJson(
  jsonDecode(File('assets/app_browser/guard.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// The native side of `casama/app_browser`, in memory: loading a page reports it started, landed
/// and finished (through the controller's gate) unless [autoFinish] is off.
class FakeAppBrowserChannel implements AppBrowserChannel {
  AppBrowserSupport support = const AppBrowserSupport(supported: true);
  AppBrowserNativeEvents? handler;
  AppBrowserPage page = const AppBrowserPage(url: 'about:blank');
  bool autoFinish = true;
  String? picture = pixelPng;

  /// Every call, as "method arg".
  final calls = <String>[];
  final commands = <Map<String, Object?>>[];
  final taps = <(double, double)>[];
  final dialogAnswers = <(bool, String?)>[];
  final cleared = <String?>[];

  /// The page script's answer to each command; by default `{ok: true, text: "<cmd> done"}`.
  Map<String, dynamic> Function(Map<String, Object?> command) answer = (c) => {
    'id': c['id'],
    'ok': true,
    'text': '${c['cmd']} done',
    'url': 'https://shop.example/',
  };

  @override
  Future<AppBrowserSupport> supported() async => support;

  @override
  Future<void> load(String url) async {
    calls.add('load $url');
    if (!autoFinish) return;
    scheduleMicrotask(() async {
      final h = handler;
      if (h == null) return;
      if (!await h.navigate(url, redirect: false, user: false)) return;
      h.pageStarted(url);
      if (!await h.landed(url)) return;
      page = AppBrowserPage(url: url, title: 'Shop');
      h.pageFinished(url, 'Shop');
    });
  }

  @override
  Future<Map<String, dynamic>> command(
    Map<String, Object?> command, {
    int? timeoutMs,
  }) async {
    commands.add(command);
    return answer(command);
  }

  @override
  Future<void> tap(double x, double y) async {
    taps.add((x, y));
    calls.add('tap $x,$y');
  }

  @override
  Future<String?> screenshot({int quality = 70}) async {
    calls.add('screenshot $quality');
    return picture;
  }

  @override
  Future<AppBrowserPage> url() async => page;

  @override
  Future<void> back() async => calls.add('back');
  @override
  Future<void> forward() async => calls.add('forward');
  @override
  Future<void> reload() async => calls.add('reload');
  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> answerDialog({required bool accept, String? text}) async =>
      dialogAnswers.add((accept, text));

  @override
  Future<void> clearData({String? host}) async => cleared.add(host);

  @override
  Future<void> dispose() async => calls.add('dispose');

  @override
  void setHandler(AppBrowserNativeEvents? handler) => this.handler = handler;
}

/// A server end for the device socket.
class FakeConnection implements AppBrowserConnection {
  final _incoming = StreamController<String>();
  final sent = <Map<String, dynamic>>[];
  var closed = false;

  @override
  Stream<String> get messages => _incoming.stream;

  @override
  void send(String message) =>
      sent.add((jsonDecode(message) as Map).cast<String, dynamic>());

  @override
  Future<void> close() async {
    closed = true;
    if (!_incoming.isClosed) await _incoming.close();
  }

  /// A message from the server.
  void push(Map<String, Object?> m) => _incoming.add(jsonEncode(m));

  /// The server sends `POST /browser/<action>` with [body].
  void request(String id, String action, Map<String, Object?> body) => push({
    'type': 'request',
    'id': id,
    'method': 'POST',
    'path': '/browser/$action',
    'body': base64Encode(utf8.encode(jsonEncode(body))),
  });

  /// The frames answering [id].
  List<Map<String, dynamic>> framesFor(String id) => [
    for (final m in sent)
      if (m['id'] == id) m,
  ];

  /// The decoded result answering [id], once its end has come.
  Map<String, dynamic>? resultFor(String id) {
    final f = framesFor(id);
    if (f.isEmpty || f.last['type'] != 'end') return null;
    final chunk = f.firstWhere((m) => m['type'] == 'chunk');
    return (jsonDecode(
      utf8.decode(base64Decode(chunk['data'] as String)),
    ) as Map).cast<String, dynamic>();
  }
}

class FakeTransport implements AppBrowserTransport {
  final connections = <FakeConnection>[];
  final headers = <Map<String, String>>[];
  final urls = <Uri>[];

  @override
  Future<AppBrowserConnection> connect(
    Uri url,
    Map<String, String> headers,
  ) async {
    urls.add(url);
    this.headers.add(headers);
    final c = FakeConnection();
    connections.add(c);
    return c;
  }
}

const fastTimings = AppBrowserTimings(
  ask: Duration(milliseconds: 300),
  takeOver: Duration(milliseconds: 300),
  settle: Duration(milliseconds: 300),
  dialog: Duration(milliseconds: 100),
);

/// The overrides that switch the phone browser on in a test, with fakes for native and the socket.
List<dynamic> appBrowserOverrides({
  required FakeAppBrowserChannel channel,
  String? Function()? focus,
  AppBrowserTimings timings = fastTimings,
  AppBrowserTokenStore? tokens,
  FakeTransport? transport,
  bool on = true,
}) => [
  appBrowserBuildProvider.overrideWithValue(on),
  appBrowserChannelProvider.overrideWithValue(channel),
  appBrowserGuardProvider.overrideWith((ref) async => loadGuard()),
  appBrowserExtraSitesProvider.overrideWith(
    (ref) async => const <String, List<String>>{},
  ),
  appBrowserFocusProvider.overrideWithValue(focus ?? () => null),
  appBrowserTimingsProvider.overrideWithValue(timings),
  appBrowserClientIdProvider.overrideWith((ref) async => 'client-1'),
  appBrowserTokenStoreProvider.overrideWithValue(
    tokens ?? MemoryAppBrowserTokenStore(),
  ),
  appBrowserTransportProvider.overrideWithValue(transport ?? FakeTransport()),
  appBrowserWebAreaProvider.overrideWithValue(
    (_) => const ColoredBox(key: Key('fakeWebArea'), color: Color(0xFFEEEEEE)),
  ),
  appVersionProvider.overrideWith((ref) async => '1.0.0'),
];

/// A call for run [run] from conversation [conversation].
AppBrowserCall browserCall(
  String action, {
  Map<String, dynamic> args = const {},
  String run = 'run1',
  String conversation = 'conv1',
  String bot = 'Ada',
  AppSitePolicy policy = const AppSitePolicy(allowedSites: ['shop.example']),
  String? expect,
}) => AppBrowserCall(
  action: action,
  args: args,
  run: AppBrowserRun(
    id: run,
    botId: 'bot1',
    botName: bot,
    conversationId: conversation,
  ),
  policy: policy,
  expect: expect,
);
