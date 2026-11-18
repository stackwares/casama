import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:casama/core/live.dart';
import 'package:casama_sdk/casama_sdk.dart';

/// A live connection without WebRTC: records input, toggles host on request.
class FakeLiveConnection implements LiveConnection {
  final sent = <Uint8List>[];
  var controlRequests = 0;
  var releases = 0;
  var closed = false;
  final _state = ValueNotifier(LiveState.live);
  final _host = ValueNotifier(false);
  final _size = ValueNotifier<Size?>(const Size(1280, 800));
  final clipboardSet = <String>[];
  final remote = ValueNotifier<String?>(null);

  @override
  ValueListenable<String?> get remoteClipboard => remote;
  @override
  void setClipboard(String text) => clipboardSet.add(text);

  void goFallback() => _state.value = LiveState.fallback;

  /// The stream is cut (a server restart, D-360): fallback with [dropped] set.
  void drop() {
    dropped = true;
    _state.value = LiveState.fallback;
  }

  /// A fresh connection after a redial.
  void goLive() {
    dropped = false;
    _state.value = LiveState.live;
  }

  @override
  var dropped = false;

  @override
  RTCVideoRenderer? get renderer => null;
  @override
  ValueListenable<LiveState> get state => _state;
  @override
  ValueListenable<bool> get isHost => _host;
  @override
  ValueListenable<Size?> get screenSize => _size;
  /// Refuses this many control requests, like a live server whose seat another view still holds.
  var refuse = 0;

  @override
  void requestControl() {
    controlRequests++;
    if (refuse > 0) {
      refuse--;
      return;
    }
    _host.value = true;
  }

  @override
  void releaseControl() {
    releases++;
    _host.value = false;
  }

  @override
  void send(Uint8List input) {
    if (_host.value) sent.add(input);
  }

  var presences = 0;
  @override
  void presence() => presences++;

  @override
  Future<double?> ping() async => 12.0;
  @override
  Future<void> close() async => closed = true;
}

class FakeLiveConnector implements LiveConnector {
  final connection = FakeLiveConnection();
  StreamSession? session;
  var connects = 0;
  /// This many connects fail, like an API that is still restarting.
  var failNext = 0;
  @override
  Future<LiveConnection> connect(StreamSession session) async {
    this.session = session;
    connects++;
    if (failNext > 0) {
      failNext--;
      throw Exception('server restarting');
    }
    connection.closed = false;
    // Each connect is a fresh connection: live again (D-360).
    connection.goLive();
    return connection;
  }
}
