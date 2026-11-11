import 'dart:async';
import 'dart:convert';


import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Neko's binary input protocol on the WebRTC data channel (D-054):
/// [op u8][payload length u16 big-endian][payload].
class NekoInput {
  static const opMove = 0x01;
  static const opScroll = 0x02;
  static const opKeyDown = 0x03;
  static const opKeyUp = 0x04;
  static const opButtonDown = 0x05;
  static const opButtonUp = 0x06;
  static const opPing = 0x07;
  static const opPong = 0x03; // server -> client

  static Uint8List _frame(int op, int length, void Function(ByteData d) write) {
    final d = ByteData(3 + length);
    d.setUint8(0, op);
    d.setUint16(1, length);
    write(d);
    return d.buffer.asUint8List();
  }

  static Uint8List move(int x, int y) => _frame(opMove, 4, (d) {
        d.setUint16(3, x.clamp(0, 65535));
        d.setUint16(5, y.clamp(0, 65535));
      });

  static Uint8List scroll(int dx, int dy, {bool control = false}) => _frame(opScroll, 5, (d) {
        d.setInt16(3, dx.clamp(-32768, 32767));
        d.setInt16(5, dy.clamp(-32768, 32767));
        d.setUint8(7, control ? 1 : 0);
      });

  static Uint8List key(int keysym, {required bool down}) =>
      _frame(down ? opKeyDown : opKeyUp, 4, (d) => d.setUint32(3, keysym));

  /// X11 buttons: 1 left, 2 middle, 3 right.
  static Uint8List button(int button, {required bool down}) =>
      _frame(down ? opButtonDown : opButtonUp, 4, (d) => d.setUint32(3, button));

  static Uint8List ping(int nowMs) => _frame(opPing, 8, (d) {
        d.setUint32(3, nowMs ~/ 0xffffffff);
        d.setUint32(7, nowMs % 0xffffffff);
      });
}

const _keysyms = <int, int>{
  0x00100000008: 0xff08, // backspace
  0x00100000009: 0xff09, // tab
  0x0010000000d: 0xff0d, // enter
  0x0010000001b: 0xff1b, // escape
  0x0010000007f: 0xffff, // delete
  0x00100000306: 0xff50, // home
  0x00100000302: 0xff51, // left
  0x00100000304: 0xff52, // up
  0x00100000303: 0xff53, // right
  0x00100000301: 0xff54, // down
  0x00100000308: 0xff55, // page up
  0x00100000307: 0xff56, // page down
  0x00100000305: 0xff57, // end
  0x00100000407: 0xff63, // insert
  0x00200000102: 0xffe1, // shift left
  0x00200000103: 0xffe2, // shift right
  0x00200000100: 0xffe3, // control left
  0x00200000101: 0xffe4, // control right
  0x00100000104: 0xffe5, // caps lock
  0x00200000104: 0xffe9, // alt left
  0x00200000105: 0xffea, // alt right
  0x00200000106: 0xffeb, // meta left (Super)
  0x00200000107: 0xffec, // meta right
};

/// The X11 keysym for a Flutter key, or null if it has none.
int? keysymFor(LogicalKeyboardKey key, {String? character}) {
  final special = _keysyms[key.keyId];
  if (special != null) return special;
  for (var i = 1; i <= 12; i++) {
    if (key == _functionKeys[i - 1]) return 0xffbe + i - 1;
  }
  final ch = character ?? (key.keyLabel.length == 1 ? key.keyLabel.toLowerCase() : null);
  if (ch == null || ch.isEmpty) return null;
  final cp = ch.runes.first;
  if (cp < 0x20) return null;
  return cp < 0x100 ? cp : 0x01000000 | cp;
}

final _functionKeys = [
  LogicalKeyboardKey.f1, LogicalKeyboardKey.f2, LogicalKeyboardKey.f3, LogicalKeyboardKey.f4,
  LogicalKeyboardKey.f5, LogicalKeyboardKey.f6, LogicalKeyboardKey.f7, LogicalKeyboardKey.f8,
  LogicalKeyboardKey.f9, LogicalKeyboardKey.f10, LogicalKeyboardKey.f11, LogicalKeyboardKey.f12,
];

enum LiveState { connecting, live, fallback, closed }

/// One live-view connection: video plus control over the data channel.
abstract class LiveConnection {
  /// The video renderer (null in fakes and fallback mode).
  RTCVideoRenderer? get renderer;
  ValueListenable<LiveState> get state;
  /// Whether this session holds Neko's control (host).
  ValueListenable<bool> get isHost;
  /// Remote screen size, once known.
  ValueListenable<Size?> get screenSize;
  void requestControl();
  void releaseControl();
  void send(Uint8List input);

  /// The computer's clipboard text as Neko last reported it (only while in control).
  ValueListenable<String?> get remoteClipboard;

  /// Puts [text] on the computer's clipboard (only while in control).
  void setClipboard(String text);
  /// Round trip over the data channel in ms (null if no answer).
  Future<double?> ping();
  Future<void> close();
}

abstract class LiveConnector {
  Future<LiveConnection> connect(StreamSession session);
}

/// flutter_webrtc on every platform; TURN relay only (the streamer is never reachable directly).
class WebRtcLiveConnector implements LiveConnector {
  @override
  Future<LiveConnection> connect(StreamSession session) => _WebRtcConnection.open(session);
}

class _WebRtcConnection implements LiveConnection {
  _WebRtcConnection(this._channel);

  final WebSocketChannel _channel;
  RTCPeerConnection? _pc;
  RTCDataChannel? _data;
  final _renderer = RTCVideoRenderer();
  final _state = ValueNotifier(LiveState.connecting);
  final _host = ValueNotifier(false);
  final _size = ValueNotifier<Size?>(null);
  final _clipboard = ValueNotifier<String?>(null);
  final _pongs = <Completer<void>>[];
  String? _sessionId;
  StreamSubscription<dynamic>? _sub;

  static Future<_WebRtcConnection> open(StreamSession session) async {
    final ws = WebSocketChannel.connect(Uri.parse(session.signalingUrl));
    final c = _WebRtcConnection(ws);
    await c._renderer.initialize();
    await c._start(session);
    return c;
  }

  void _sendJson(String event, [Map<String, Object?>? payload]) =>
      _channel.sink.add(jsonEncode({'event': event, 'payload': ?payload}));

  Future<void> _start(StreamSession session) async {
    _pc = await createPeerConnection({
      'iceServers': [
        for (final s in session.iceServers)
          {'urls': s.urls, 'username': ?s.username, 'credential': ?s.credential},
      ],
      'iceTransportPolicy': session.iceTransportPolicy.value,
      'sdpSemantics': 'unified-plan',
    });
    final pc = _pc!;
    pc.onTrack = (e) {
      if (e.track.kind == 'video' && e.streams.isNotEmpty) {
        _renderer.srcObject = e.streams.first;
      }
    };
    _renderer.onResize = () {
      if (_renderer.videoWidth > 0) {
        _size.value = Size(_renderer.videoWidth.toDouble(), _renderer.videoHeight.toDouble());
      }
    };
    pc.onDataChannel = (dc) {
      _data = dc;
      dc.onMessage = (m) {
        if (!m.isBinary || m.binary.length < 3) return;
        if (m.binary[0] == NekoInput.opPong && _pongs.isNotEmpty) _pongs.removeAt(0).complete();
      };
    };
    pc.onIceCandidate = (c) {
      if (c.candidate == null) return;
      _sendJson('signal/candidate', {'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMLineIndex});
    };
    pc.onConnectionState = (s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) _state.value = LiveState.live;
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) _state.value = LiveState.fallback;
    };
    // Handle signaling strictly in order; candidates wait until the offer is applied.
    var queue = Future<void>.value();
    final early = <RTCIceCandidate>[];
    var haveRemote = false;
    _sub = _channel.stream.listen((raw) {
      queue = queue.then((_) => _handle(raw, pc, early, () => haveRemote, () => haveRemote = true)).catchError((Object e) {
        debugPrint('live signaling: $e');
      });
    }, onDone: () {
      if (_state.value != LiveState.closed) _state.value = LiveState.fallback;
    }, onError: (_) {
      _state.value = LiveState.fallback;
    });
    // Networks that block WebRTC fall back to screenshots.
    Timer(const Duration(seconds: 12), () {
      if (_state.value == LiveState.connecting) _state.value = LiveState.fallback;
    });
  }

  Future<void> _handle(
    dynamic raw,
    RTCPeerConnection pc,
    List<RTCIceCandidate> early,
    bool Function() haveRemote,
    void Function() markRemote,
  ) async {
    {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final payload = (msg['payload'] as Map?)?.cast<String, dynamic>() ?? const {};
      switch (msg['event']) {
        case 'system/init':
          _sessionId = payload['session_id'] as String?;
          final screen = (payload['screen_size'] as Map?)?.cast<String, dynamic>();
          if (screen != null) {
            _size.value = Size((screen['width'] as num).toDouble(), (screen['height'] as num).toDouble());
          }
          _sendJson('signal/request', {'video': {}, 'audio': {}});
        case 'signal/provide':
          await pc.setRemoteDescription(RTCSessionDescription(payload['sdp'] as String, 'offer'));
          markRemote();
          for (final c in early.toList()) {
            await pc.addCandidate(c).catchError((_) {});
          }
          early.clear();
          final answer = await pc.createAnswer();
          await pc.setLocalDescription(answer);
          _sendJson('signal/answer', {'sdp': answer.sdp});
        case 'signal/candidate':
          final c = RTCIceCandidate(
            payload['candidate'] as String?,
            payload['sdpMid'] as String?,
            payload['sdpMLineIndex'] as int?,
          );
          if (haveRemote()) {
            await pc.addCandidate(c).catchError((_) {});
          } else {
            early.add(c);
          }
        case 'control/host':
          final hostId = payload['host_id'] as String?;
          _host.value = payload['has_host'] == true && hostId != null && hostId == _sessionId;
        case 'clipboard/updated':
          if (payload['text'] is String) _clipboard.value = payload['text'] as String;
        case 'screen/updated':
          if (payload['width'] != null) {
            _size.value = Size((payload['width'] as num).toDouble(), (payload['height'] as num).toDouble());
          }
      }
    }
  }

  @override
  RTCVideoRenderer? get renderer => _renderer;
  @override
  ValueListenable<LiveState> get state => _state;
  @override
  ValueListenable<bool> get isHost => _host;
  @override
  ValueListenable<Size?> get screenSize => _size;

  @override
  void requestControl() => _sendJson('control/request');

  @override
  ValueListenable<String?> get remoteClipboard => _clipboard;

  @override
  void setClipboard(String text) => _sendJson('clipboard/set', {'text': text});
  @override
  void releaseControl() {
    _sendJson('control/release');
    _host.value = false;
  }

  @override
  void send(Uint8List input) {
    if (!_host.value) return;
    _data?.send(RTCDataChannelMessage.fromBinary(input));
  }

  @override
  Future<double?> ping() async {
    final dc = _data;
    if (dc == null) return null;
    final done = Completer<void>();
    _pongs.add(done);
    final sw = Stopwatch()..start();
    await dc.send(RTCDataChannelMessage.fromBinary(NekoInput.ping(DateTime.now().millisecondsSinceEpoch)));
    try {
      await done.future.timeout(const Duration(seconds: 3));
      return sw.elapsedMicroseconds / 1000;
    } catch (_) {
      _pongs.remove(done);
      return null;
    }
  }

  @override
  Future<void> close() async {
    _state.value = LiveState.closed;
    await _sub?.cancel();
    await _channel.sink.close();
    await _data?.close();
    await _pc?.close();
    _renderer.srcObject = null;
    await _renderer.dispose();
  }
}

final liveConnectorProvider = Provider<LiveConnector>((ref) => WebRtcLiveConnector());
