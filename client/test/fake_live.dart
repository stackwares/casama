import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:kasama_app/core/live.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

/// A live connection without WebRTC: records input, toggles host on request.
class FakeLiveConnection implements LiveConnection {
  final sent = <Uint8List>[];
  var controlRequests = 0;
  var releases = 0;
  var closed = false;
  final _state = ValueNotifier(LiveState.live);
  final _host = ValueNotifier(false);
  final _size = ValueNotifier<Size?>(const Size(1280, 800));

  void goFallback() => _state.value = LiveState.fallback;

  @override
  RTCVideoRenderer? get renderer => null;
  @override
  ValueListenable<LiveState> get state => _state;
  @override
  ValueListenable<bool> get isHost => _host;
  @override
  ValueListenable<Size?> get screenSize => _size;
  @override
  void requestControl() {
    controlRequests++;
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

  @override
  Future<double?> ping() async => 12.0;
  @override
  Future<void> close() async => closed = true;
}

class FakeLiveConnector implements LiveConnector {
  final connection = FakeLiveConnection();
  StreamSession? session;
  @override
  Future<LiveConnection> connect(StreamSession session) async {
    this.session = session;
    return connection;
  }
}
