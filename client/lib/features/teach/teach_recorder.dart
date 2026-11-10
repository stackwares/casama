import 'dart:async';

import 'package:kasama_sdk/kasama_sdk.dart';

/// Turns live-view input into teach steps (D-120): a click is a step, typing is gathered into one
/// step until something else happens (a click, a special key, a pause), and scrolling likewise.
class TeachRecorder {
  TeachRecorder(this.onStep, {this.idle = const Duration(milliseconds: 1500)});

  final void Function(AddTeachStepRequest step) onStep;
  final Duration idle;
  var _text = '';
  var _dx = 0;
  var _dy = 0;
  Timer? _timer;

  void click(int x, int y, {int button = 1}) {
    flush();
    onStep(AddTeachStepRequest(kind: AddTeachStepRequestKindEnum.click, x: x, y: y, button: button));
  }

  void char(String c) {
    _flushScroll();
    _text += c;
    _arm();
  }

  void backspace() {
    if (_text.isEmpty) return key('Backspace');
    _text = _text.substring(0, _text.length - 1);
    _arm();
  }

  void key(String name) {
    flush();
    onStep(AddTeachStepRequest(kind: AddTeachStepRequestKindEnum.key, key: name.length > 40 ? name.substring(0, 40) : name));
  }

  void scroll(int dx, int dy) {
    _flushText();
    _dx += dx;
    _dy += dy;
    _arm();
  }

  void flush() {
    _timer?.cancel();
    _flushText();
    _flushScroll();
  }

  void dispose() => _timer?.cancel();

  void _arm() {
    _timer?.cancel();
    _timer = Timer(idle, flush);
  }

  void _flushText() {
    if (_text.isEmpty) return;
    final t = _text;
    _text = '';
    for (var i = 0; i < t.length; i += 2000) {
      onStep(AddTeachStepRequest(kind: AddTeachStepRequestKindEnum.type, text: t.substring(i, i + 2000 > t.length ? t.length : i + 2000)));
    }
  }

  void _flushScroll() {
    if (_dx == 0 && _dy == 0) return;
    onStep(AddTeachStepRequest(kind: AddTeachStepRequestKindEnum.scroll, dx: _dx.clamp(-10000, 10000), dy: _dy.clamp(-10000, 10000)));
    _dx = 0;
    _dy = 0;
  }
}
