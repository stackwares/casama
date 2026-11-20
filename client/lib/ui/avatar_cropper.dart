import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../core/haptics.dart';
import '../core/widgets.dart';
import '../theme/app_tokens.dart';

/// The cropper every avatar in the app goes through (docs/BOT-PICTURES-PLAN.md §4): a still frame
/// in the avatar's exact final shape, the picture moving and scaling under it, and live previews
/// at the sizes the avatar really appears, so a face that turns to mush at 24 px is seen before
/// Done, not after.
///
/// All on the device in Flutter: no web view, nothing uploaded until Done.

/// The final shape the frame is cut in.
enum AvatarShape {
  /// A bot's rounded square (radius 0.32 × side, as BotAvatar draws it).
  bot,

  /// A person's circle.
  person,
}

/// What fills the see-through parts of a picture (logos, stickers).
enum CropBackground { none, accent, white, black }

/// Where the frame sat on the picture: kept with the picture so Re-crop opens where it was left.
@immutable
class AvatarCrop {
  const AvatarCrop({
    required this.x,
    required this.y,
    required this.scale,
    this.turns = 0,
    this.mirror = false,
    this.background = CropBackground.none,
  });

  /// The frame's centre on the picture as picked (before turning), 0–1 across and down.
  final double x;
  final double y;

  /// The frame's side as a share of the picture's shorter side (1 = filling it).
  final double scale;

  /// Quarter turns clockwise.
  final int turns;
  final bool mirror;
  final CropBackground background;
}

/// The cropped picture and how it was made.
class CroppedAvatar {
  const CroppedAvatar({
    required this.png,
    required this.crop,
    required this.transparent,
    required this.zoomed,
    required this.turned,
  });

  /// A square PNG of the framed part, background baked in.
  final Uint8List png;
  final AvatarCrop crop;

  /// The picture had see-through parts.
  final bool transparent;

  /// It was zoomed in from "fill", or turned.
  final bool zoomed;
  final bool turned;
}

/// Opens the cropper on [bytes]. [name] labels the previews (and "Ada's colour"); [accent] is the
/// gradient a bot without a picture would have, offered as a background for see-through pictures.
/// [initial] reopens a previous crop (Re-crop). Returns null when the person backs out.
Future<CroppedAvatar?> showAvatarCropper(
  BuildContext context, {
  required Uint8List bytes,
  required AvatarShape shape,
  required String name,
  List<Color> accent = const [Color(0xFF6366F1), Color(0xFF4338CA)],
  AvatarCrop? initial,
  int outputSide = 768,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final cropper = AvatarCropper(
    bytes: bytes,
    shape: shape,
    name: name,
    accent: accent,
    initial: initial,
    outputSide: outputSide,
  );
  // Phones: the whole screen, on black, like the system's own croppers. Larger windows: a dialog.
  if (width < 600) {
    return Navigator.of(context, rootNavigator: true).push<CroppedAvatar>(
      PageRouteBuilder(
        fullscreenDialog: true,
        opaque: true,
        transitionDuration: AppMotion.of(
          context,
          const Duration(milliseconds: 260),
        ),
        reverseTransitionDuration: AppMotion.of(
          context,
          const Duration(milliseconds: 200),
        ),
        pageBuilder: (_, _, _) => cropper,
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: AppMotion.curve),
          child: ScaleTransition(
            scale: Tween(
              begin: 0.98,
              end: 1.0,
            ).animate(CurvedAnimation(parent: a, curve: AppMotion.curve)),
            child: child,
          ),
        ),
      ),
    );
  }
  return showDialog<CroppedAvatar>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => Dialog(
      backgroundColor: _Ink.panel,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppSpace.lg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: SizedBox(
          width: 560,
          height: math.min(720, MediaQuery.sizeOf(context).height - 48),
          child: cropper,
        ),
      ),
    ),
  );
}

/// The cropper's own colours: it's always dark, whatever the app's theme, so the picture's colours
/// read true.
abstract final class _Ink {
  static const page = Color(0xFF000000);
  static const panel = Color(0xFF111113);
  static const raised = Color(0xFF1F1F23);
  static const text = Color(0xFFF5F5F7);
  static const muted = Color(0xFFA1A1AA);
  static const hairline = Color(0x99FFFFFF);
  static const scrim = Color(0x8C000000);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF1C1C1E);
}

/// The cropper's page; [showAvatarCropper] puts it on screen.
class AvatarCropper extends StatefulWidget {
  const AvatarCropper({
    super.key,
    required this.bytes,
    required this.shape,
    required this.name,
    required this.accent,
    this.initial,
    this.outputSide = 768,
  });

  final Uint8List bytes;
  final AvatarShape shape;
  final String name;
  final List<Color> accent;
  final AvatarCrop? initial;
  final int outputSide;

  @override
  State<AvatarCropper> createState() => _AvatarCropperState();
}

/// The picture decoded for editing, at most 2,048 px on its long side.
class _Source {
  _Source(
    this.image, {
    required this.transparent,
    required this.margin,
    required this.animated,
  });
  final ui.Image image;
  final bool transparent;

  /// Its edges are mostly see-through (a logo with room around it).
  final bool margin;
  final bool animated;
}

/// Opens a picture for editing, or throws [AvatarSourceError].
@visibleForTesting
Future<({ui.Image image, bool transparent, bool margin, bool animated})>
decodeAvatarSource(Uint8List bytes) async {
  if (bytes.length > 40 * 1024 * 1024) {
    throw AvatarSourceError.tooBig(bytes.length);
  }
  final ui.ImageDescriptor descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(
      await ui.ImmutableBuffer.fromUint8List(bytes),
    );
  } catch (_) {
    throw const AvatarSourceError.unreadable();
  }
  try {
    final long = math.max(descriptor.width, descriptor.height);
    final f = long > 2048 ? 2048 / long : 1.0;
    final codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (descriptor.width * f).round()),
      targetHeight: math.max(1, (descriptor.height * f).round()),
    );
    final animated = codec.frameCount > 1;
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    // See-through parts, from a small copy: any pixel under 250 alpha.
    final small = await _thumb(image, 64);
    final data = await small.toByteData(format: ui.ImageByteFormat.rawRgba);
    small.dispose();
    var transparent = false;
    var edgeClear = 0;
    var edge = 0;
    if (data != null) {
      const w = 64;
      const h = 64;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final a = data.getUint8((y * w + x) * 4 + 3);
          if (a < 250) transparent = true;
          if (x == 0 || y == 0 || x == w - 1 || y == h - 1) {
            edge++;
            if (a < 40) edgeClear++;
          }
        }
      }
    }
    return (
      image: image,
      transparent: transparent,
      margin: edge > 0 && edgeClear / edge > 0.8,
      animated: animated,
    );
  } catch (_) {
    throw const AvatarSourceError.unreadable();
  } finally {
    descriptor.dispose();
  }
}

Future<ui.Image> _thumb(ui.Image image, int side) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
    Paint()..filterQuality = FilterQuality.low,
  );
  return recorder.endRecording().toImage(side, side);
}

/// Why a picture can't be opened.
class AvatarSourceError implements Exception {
  const AvatarSourceError.unreadable() : bytes = null;
  const AvatarSourceError.tooBig(int this.bytes);

  /// Set when the file was over 40 MB.
  final int? bytes;
}

/// The frame's position on the picture: how many of the turned picture's pixels the frame's side
/// covers ([visible]), and which point of the turned picture sits at the frame's centre
/// ([center], from the picture's middle). Independent of the window, so resizing, turning and
/// rendering the result all use the same numbers.
@immutable
class _View {
  const _View(this.visible, this.center);
  final double visible;
  final Offset center;

  _View lerp(_View to, double t) => _View(
    ui.lerpDouble(visible, to.visible, t)!,
    Offset.lerp(center, to.center, t)!,
  );
}

class _AvatarCropperState extends State<AvatarCropper>
    with TickerProviderStateMixin {
  _Source? _source;
  AvatarSourceError? _error;

  var _view = const _View(1, Offset.zero);
  var _turns = 0;
  var _mirror = false;
  var _background = CropBackground.none;
  late _View _start;
  late int _startTurns;
  late bool _startMirror;

  /// Springs back into bounds after a gesture, and eases double-taps and resets.
  late final AnimationController _settle = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onSettle);
  _View? _settleFrom;
  _View? _settleTo;

  /// The quarter turn's animation: an extra angle that runs from −90° to 0.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  /// Rule-of-thirds lines while a finger or the mouse is down.
  late final AnimationController _grid = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  final _focus = FocusNode(debugLabel: 'avatarCropper');
  var _frameSide = 300.0;
  var _interacting = false;
  var _lastScale = 1.0;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await decodeAvatarSource(widget.bytes);
      if (!mounted) {
        s.image.dispose();
        return;
      }
      final source = _Source(
        s.image,
        transparent: s.transparent,
        margin: s.margin,
        animated: s.animated,
      );
      setState(() {
        _source = source;
        _restore(widget.initial);
        _background =
            widget.initial?.background ??
            (!s.transparent
                ? CropBackground.none
                : (s.margin
                      ? CropBackground.none
                      : (widget.shape == AvatarShape.bot
                            ? CropBackground.accent
                            : CropBackground.white)));
        _start = _view;
        _startTurns = _turns;
        _startMirror = _mirror;
      });
      _focus.requestFocus();
    } on AvatarSourceError catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    _turn.dispose();
    _grid.dispose();
    _focus.dispose();
    _source?.image.dispose();
    super.dispose();
  }

  // --- geometry --------------------------------------------------------------------------------

  Size get _turned {
    final img = _source!.image;
    return _turns.isOdd
        ? Size(img.height.toDouble(), img.width.toDouble())
        : Size(img.width.toDouble(), img.height.toDouble());
  }

  /// The frame's side in picture pixels when it just fills the frame.
  double get _fill => _turned.shortestSide;

  /// Closest zoom: the frame covers 256 of the picture's pixels (or all of a small picture).
  double get _minVisible => math.min(256, _fill);

  /// Furthest zoom: filling the frame, or for see-through pictures, leaving room around them.
  double get _maxVisible =>
      _source!.transparent ? _turned.longestSide * 1.6 : _fill;

  double _limitX(double v) => (_turned.width - v).abs() / 2;
  double _limitY(double v) => (_turned.height - v).abs() / 2;

  _View _clamp(_View v) {
    final visible = v.visible.clamp(_minVisible, _maxVisible);
    final lx = _limitX(visible);
    final ly = _limitY(visible);
    return _View(
      visible,
      Offset(v.center.dx.clamp(-lx, lx), v.center.dy.clamp(-ly, ly)),
    );
  }

  /// A point of the turned picture back on the picture as picked (0–1), undoing turn then mirror.
  Offset _toSource(Offset c) {
    final img = _source!.image;
    var p = c;
    for (var i = 0; i < _turns; i++) {
      p = Offset(
        p.dy,
        -p.dx,
      ); // a quarter turn back, anticlockwise (y points down)
    }
    if (_mirror) p = Offset(-p.dx, p.dy);
    return Offset(p.dx / img.width + 0.5, p.dy / img.height + 0.5);
  }

  Offset _fromSource(double x, double y) {
    final img = _source!.image;
    var p = Offset((x - 0.5) * img.width, (y - 0.5) * img.height);
    if (_mirror) p = Offset(-p.dx, p.dy);
    for (var i = 0; i < _turns; i++) {
      p = Offset(-p.dy, p.dx); // a quarter turn clockwise
    }
    return p;
  }

  void _restore(AvatarCrop? crop) {
    final img = _source!.image;
    if (crop != null) {
      _turns = crop.turns % 4;
      _mirror = crop.mirror;
      final shorter = math.min(img.width, img.height).toDouble();
      _view = _clamp(_View(crop.scale * shorter, _fromSource(crop.x, crop.y)));
      return;
    }
    _turns = 0;
    _mirror = false;
    // Portraits start a little high: faces sit in the upper part of nearly every portrait photo.
    final t = _turned;
    final portrait = t.height > t.width * 1.08;
    _view = _clamp(
      _View(
        _source!.transparent && _source!.margin ? t.longestSide : _fill,
        Offset(0, portrait ? -0.1 * t.height : 0),
      ),
    );
  }

  AvatarCrop get _crop {
    final img = _source!.image;
    final p = _toSource(_view.center);
    return AvatarCrop(
      x: p.dx,
      y: p.dy,
      scale: _view.visible / math.min(img.width, img.height),
      turns: _turns,
      mirror: _mirror,
      background: _background,
    );
  }

  bool get _changed =>
      _turns != _startTurns ||
      _mirror != _startMirror ||
      (_view.visible - _start.visible).abs() > 0.5 ||
      (_view.center - _start.center).distance > 0.5;

  /// The zoom as people read it: 100 % fills the frame.
  int get _zoomPercent => (_fill / _view.visible * 100).round();

  // --- moving ----------------------------------------------------------------------------------

  /// How hard it gets to pull past an edge: half speed at the edge, less the further past.
  double _resist(double overPx) => 0.5 / (1 + overPx / 36);

  void _panBy(Offset viewDelta) {
    final s = _frameSide / _view.visible;
    var d = -viewDelta / s;
    final lx = _limitX(_view.visible);
    final ly = _limitY(_view.visible);
    final c = _view.center;
    double axis(double pos, double delta, double limit) {
      final next = pos + delta;
      final over = next.abs() - limit;
      if (over <= 0 || next.abs() < pos.abs()) return delta;
      return delta * _resist(math.max(0, pos.abs() - limit) * s);
    }

    d = Offset(axis(c.dx, d.dx, lx), axis(c.dy, d.dy, ly));
    setState(() => _view = _View(_view.visible, c + d));
  }

  /// Scales by [ratio] around [focal] (view coordinates from the frame's centre).
  void _zoomBy(double ratio, Offset focal, {bool rubber = true}) {
    if (ratio == 1) return;
    var next = _view.visible / ratio;
    if (rubber) {
      final lo = _minVisible;
      final hi = _maxVisible;
      if ((next < lo && ratio > 1) || (next > hi && ratio < 1)) {
        final over = next < lo ? lo / next : next / hi;
        next =
            _view.visible /
            math.pow(ratio, _resist((over - 1) * 120)).toDouble();
      }
    } else {
      next = next.clamp(_minVisible, _maxVisible);
    }
    final before = _view.visible;
    final p = _view.center + focal * (before / _frameSide);
    final center = p - focal * (next / _frameSide);
    _tick(before, next);
    setState(
      () => _view = rubber ? _View(next, center) : _clamp(_View(next, center)),
    );
  }

  /// A light tick when the zoom crosses "fill" or reaches its closest.
  void _tick(double before, double after) {
    final fill = _fill;
    final crossed =
        (before - fill).sign != (after - fill).sign &&
        (before - fill).abs() > 0.01;
    final hitMax = before > _minVisible && after <= _minVisible;
    if (crossed || hitMax) HapticsHelper.selection();
  }

  void _animateTo(_View target, {double velocity = 0}) {
    _settleFrom = _view;
    _settleTo = target;
    final spring = SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: 420,
      ratio: 1,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _view = target);
      return;
    }
    _settle.animateWith(SpringSimulation(spring, 0, 1, velocity));
  }

  void _onSettle() {
    final from = _settleFrom;
    final to = _settleTo;
    if (from == null || to == null) return;
    setState(() => _view = from.lerp(to, _settle.value));
  }

  void _settleIntoBounds() {
    final target = _clamp(_view);
    if ((target.visible - _view.visible).abs() > 0.01 ||
        (target.center - _view.center).distance > 0.01) {
      _animateTo(target);
    }
  }

  void _setInteracting(bool on) {
    if (_interacting == on) return;
    _interacting = on;
    on ? _grid.forward() : _grid.reverse();
  }

  void _onScaleStart(ScaleStartDetails d) {
    _settle.stop();
    _lastScale = 1;
    _setInteracting(true);
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Offset frameCenter) {
    if (d.focalPointDelta != Offset.zero) _panBy(d.focalPointDelta);
    final ratio = d.scale / _lastScale;
    _lastScale = d.scale;
    if (ratio != 1) _zoomBy(ratio, d.localFocalPoint - frameCenter);
  }

  void _onScaleEnd(ScaleEndDetails d) {
    _setInteracting(false);
    _settleIntoBounds();
  }

  void _onDoubleTap(Offset focal) {
    final fill = _fill;
    final target = (_view.visible - fill).abs() < fill * 0.05 ? fill / 2 : fill;
    final next = target.clamp(_minVisible, _maxVisible);
    final p = _view.center + focal * (_view.visible / _frameSide);
    final center = p - focal * (next / _frameSide);
    HapticsHelper.selection();
    _animateTo(_clamp(_View(next, center)));
  }

  void _rotate() {
    if (_source == null) return;
    HapticsHelper.selection();
    _settle.stop();
    setState(() {
      _turns = (_turns + 1) % 4;
      final c = _view.center;
      _view = _View(_view.visible, Offset(-c.dy, c.dx));
    });
    if (!MediaQuery.disableAnimationsOf(context)) _turn.forward(from: 0);
    _settleIntoBounds();
  }

  void _flip() {
    if (_source == null) return;
    HapticsHelper.selection();
    setState(() {
      _mirror = !_mirror;
      _view = _View(_view.visible, Offset(-_view.center.dx, _view.center.dy));
    });
  }

  void _reset() {
    HapticsHelper.selection();
    _settle.stop();
    setState(() {
      _turns = _startTurns;
      _mirror = _startMirror;
    });
    _animateTo(_start);
  }

  /// Zoom from the slider: 0 is "fill" (or furthest), 1 is closest; logarithmic, so it feels even.
  double get _slider {
    final lo = math.log(_minVisible);
    final hi = math.log(_maxVisible);
    if (hi - lo < 1e-6) return 0;
    return ((hi - math.log(_view.visible)) / (hi - lo)).clamp(0.0, 1.0);
  }

  void _setSlider(double t) {
    final lo = math.log(_minVisible);
    final hi = math.log(_maxVisible);
    final next = math.exp(hi - t * (hi - lo));
    _zoomBy(_view.visible / next, Offset.zero, rubber: false);
  }

  void _nudge(Offset viewDelta) {
    final s = _frameSide / _view.visible;
    setState(
      () => _view = _clamp(_View(_view.visible, _view.center - viewDelta / s)),
    );
  }

  // --- finishing -------------------------------------------------------------------------------

  Future<void> _finish() async {
    final source = _source;
    if (source == null || _done) return;
    _done = true;
    _settle.stop();
    final view = _clamp(_view);
    final side = widget.outputSide;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble());
    _paintBackground(canvas, rect, _background, widget.accent);
    _paintPicture(
      canvas,
      source.image,
      rect,
      view,
      _turns,
      _mirror,
      0,
      FilterQuality.high,
    );
    final out = await recorder.endRecording().toImage(side, side);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    if (!mounted || data == null) return;
    HapticsHelper.light();
    Navigator.of(context).pop(
      CroppedAvatar(
        png: data.buffer.asUint8List(),
        crop: _crop,
        transparent: source.transparent && _background == CropBackground.none,
        zoomed: view.visible < _fill * 0.97,
        turned: _turns != 0 || _mirror,
      ),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      return _handled(() => Navigator.of(context).maybePop());
    }
    if (_source == null) return KeyEventResult.ignored;
    final step = HardwareKeyboard.instance.isShiftPressed ? 10.0 : 1.0;
    final k = e.logicalKey;
    // Arrows move the picture the way the arrow points.
    if (k == LogicalKeyboardKey.arrowLeft) {
      return _handled(() => _nudge(Offset(-step, 0)));
    }
    if (k == LogicalKeyboardKey.arrowRight) {
      return _handled(() => _nudge(Offset(step, 0)));
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      return _handled(() => _nudge(Offset(0, -step)));
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      return _handled(() => _nudge(Offset(0, step)));
    }
    if (k == LogicalKeyboardKey.equal ||
        k == LogicalKeyboardKey.add ||
        k == LogicalKeyboardKey.numpadAdd) {
      return _handled(() => _zoomBy(1.1, Offset.zero, rubber: false));
    }
    if (k == LogicalKeyboardKey.minus ||
        k == LogicalKeyboardKey.numpadSubtract) {
      return _handled(() => _zoomBy(1 / 1.1, Offset.zero, rubber: false));
    }
    if (k == LogicalKeyboardKey.keyR) return _handled(_rotate);
    if (k == LogicalKeyboardKey.keyM) return _handled(_flip);
    if (k == LogicalKeyboardKey.digit0 || k == LogicalKeyboardKey.numpad0) {
      return _handled(_reset);
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      return _handled(() => unawaited(_finish()));
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handled(VoidCallback f) {
    f();
    return KeyEventResult.handled;
  }

  // --- building --------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final base = Theme.of(context);
    final dark = ColorScheme.fromSeed(
      seedColor: base.colorScheme.primary,
      brightness: Brightness.dark,
    );
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Theme(
      data: base.copyWith(
        colorScheme: dark,
        sliderTheme: base.sliderTheme.copyWith(
          activeTrackColor: _Ink.text,
          inactiveTrackColor: _Ink.text.withValues(alpha: 0.18),
          thumbColor: _Ink.text,
          overlayColor: _Ink.text.withValues(alpha: 0.12),
          trackHeight: 3,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: _Ink.text),
        child: IconTheme.merge(
          data: const IconThemeData(color: _Ink.text),
          child: Material(
            color: compact ? _Ink.page : _Ink.panel,
            child: Focus(
              focusNode: _focus,
              autofocus: true,
              onKeyEvent: _onKey,
              child: SafeArea(
                child: Column(
                  children: [
                    _Header(
                      title: l10n.cropTitle,
                      cancel: l10n.cancel,
                      done: l10n.cropDone,
                      onDone: _source == null
                          ? null
                          : () => unawaited(_finish()),
                    ),
                    Expanded(
                      child: _error != null ? _errorView() : _editor(context),
                    ),
                    if (_source != null) _controls(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    final big = _error?.bytes;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.md,
          children: [
            const Icon(LucideIcons.imageOff, size: 36, color: _Ink.muted),
            Text(
              big != null
                  ? context.l10n.cropTooBig(
                      '${(big / (1024 * 1024)).toStringAsFixed(0)} MB',
                    )
                  : context.l10n.cropUnreadable,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _Ink.text,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editor(BuildContext context) {
    final source = _source;
    if (source == null) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: _Ink.muted),
        ),
      );
    }
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, c) {
        _frameSide = math.max(120, math.min(c.maxWidth, c.maxHeight) * 0.78);
        final frame = Rect.fromCenter(
          center: Offset(c.maxWidth / 2, c.maxHeight / 2),
          width: _frameSide,
          height: _frameSide,
        );
        return Semantics(
          container: true,
          label: l10n.cropPosition,
          value: '$_zoomPercent %',
          increasedValue: '${(_zoomPercent * 1.1).round()} %',
          decreasedValue: '${(_zoomPercent / 1.1).round()} %',
          onIncrease: () => _zoomBy(1.1, Offset.zero, rubber: false),
          onDecrease: () => _zoomBy(1 / 1.1, Offset.zero, rubber: false),
          customSemanticsActions: {
            CustomSemanticsAction(label: l10n.cropMoveUp): () =>
                _nudge(const Offset(0, -10)),
            CustomSemanticsAction(label: l10n.cropMoveDown): () =>
                _nudge(const Offset(0, 10)),
            CustomSemanticsAction(label: l10n.cropMoveLeft): () =>
                _nudge(const Offset(-10, 0)),
            CustomSemanticsAction(label: l10n.cropMoveRight): () =>
                _nudge(const Offset(10, 0)),
            CustomSemanticsAction(label: l10n.cropRotate): _rotate,
            CustomSemanticsAction(label: l10n.cropReset): _reset,
          },
          child: Listener(
            onPointerDown: (_) => _setInteracting(true),
            onPointerUp: (_) => _setInteracting(false),
            onPointerCancel: (_) => _setInteracting(false),
            onPointerSignal: (e) {
              if (e is PointerScrollEvent) {
                GestureBinding.instance.pointerSignalResolver.register(e, (e) {
                  final s = e as PointerScrollEvent;
                  _zoomBy(
                    math.exp(-s.scrollDelta.dy / 420),
                    s.localPosition - frame.center,
                    rubber: false,
                  );
                });
              }
            },
            child: GestureDetector(
              key: const Key('avatarCropFrame'),
              behavior: HitTestBehavior.opaque,
              onScaleStart: _onScaleStart,
              onScaleUpdate: (d) => _onScaleUpdate(d, frame.center),
              onScaleEnd: _onScaleEnd,
              onDoubleTapDown: (d) =>
                  _lastDoubleTap = d.localPosition - frame.center,
              onDoubleTap: () => _onDoubleTap(_lastDoubleTap),
              child: AnimatedBuilder(
                animation: Listenable.merge([_turn, _grid]),
                builder: (context, _) => CustomPaint(
                  size: Size(c.maxWidth, c.maxHeight),
                  painter: _EditorPainter(
                    image: source.image,
                    frame: frame,
                    view: _view,
                    turns: _turns,
                    mirror: _mirror,
                    extraAngle: _turn.isAnimating
                        ? -(math.pi / 2) *
                              (1 - Curves.easeOutCubic.transform(_turn.value))
                        : 0,
                    shape: widget.shape,
                    background: _background,
                    accent: widget.accent,
                    checker:
                        source.transparent &&
                        _background == CropBackground.none,
                    grid: _grid.value,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _lastDoubleTap = Offset.zero;

  Widget _controls(BuildContext context) {
    final l10n = context.l10n;
    final source = _source!;
    final soft = _view.visible < 320 && _fill > 320;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.sm,
        children: [
          _Previews(
            image: source.image,
            view: _view,
            turns: _turns,
            mirror: _mirror,
            shape: widget.shape,
            background: _background,
            accent: widget.accent,
            name: widget.name,
          ),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.fast),
            child: soft || source.animated
                ? Text(
                    soft ? l10n.cropSoft : l10n.cropAnimatedStill,
                    key: ValueKey(soft),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _Ink.muted, fontSize: 13),
                  )
                : const SizedBox(height: 0, key: ValueKey('none')),
          ),
          _Toolbar(
            slider: _slider,
            onSlider: _setSlider,
            onSliderStart: () => _setInteracting(true),
            onSliderEnd: () => _setInteracting(false),
            onRotate: _rotate,
            onMirror: _flip,
            onReset: _changed ? _reset : null,
          ),
          if (source.transparent)
            _BackgroundRow(
              value: _background,
              shape: widget.shape,
              accent: widget.accent,
              accentLabel: l10n.cropBackgroundBot(widget.name),
              onChanged: (b) {
                HapticsHelper.selection();
                setState(() => _background = b);
              },
            ),
        ],
      ),
    );
  }
}

// --- painting ----------------------------------------------------------------------------------

/// The frame's shape at [rect].
Path _shapePath(Rect rect, AvatarShape shape) => shape == AvatarShape.person
    ? (Path()..addOval(rect))
    : (Path()..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.32)),
      ));

void _paintBackground(
  Canvas canvas,
  Rect rect,
  CropBackground background,
  List<Color> accent,
) {
  switch (background) {
    case CropBackground.none:
      return;
    case CropBackground.white:
      canvas.drawRect(rect, Paint()..color = Colors.white);
    case CropBackground.black:
      canvas.drawRect(rect, Paint()..color = Colors.black);
    case CropBackground.accent:
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: accent,
          ).createShader(rect),
      );
  }
}

/// Draws the picture so [view] lands in [frame]: centre, scale, an extra angle (the turn's
/// animation, around the frame's centre), the quarter turns, then the mirror.
void _paintPicture(
  Canvas canvas,
  ui.Image image,
  Rect frame,
  _View view,
  int turns,
  bool mirror,
  double extraAngle,
  FilterQuality quality,
) {
  final s = frame.width / view.visible;
  canvas
    ..save()
    ..translate(frame.center.dx, frame.center.dy)
    ..rotate(extraAngle)
    ..scale(s)
    ..translate(-view.center.dx, -view.center.dy)
    ..rotate(turns * math.pi / 2);
  if (mirror) canvas.scale(-1, 1);
  canvas.drawImage(
    image,
    Offset(-image.width / 2, -image.height / 2),
    Paint()..filterQuality = quality,
  );
  canvas.restore();
}

class _EditorPainter extends CustomPainter {
  _EditorPainter({
    required this.image,
    required this.frame,
    required this.view,
    required this.turns,
    required this.mirror,
    required this.extraAngle,
    required this.shape,
    required this.background,
    required this.accent,
    required this.checker,
    required this.grid,
  });

  final ui.Image image;
  final Rect frame;
  final _View view;
  final int turns;
  final bool mirror;
  final double extraAngle;
  final AvatarShape shape;
  final CropBackground background;
  final List<Color> accent;
  final bool checker;
  final double grid;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Offset.zero & size;
    final cut = _shapePath(frame, shape);
    // Inside the frame: the background a see-through picture will have.
    canvas.save();
    canvas.clipPath(cut);
    if (checker) {
      const cell = 10.0;
      final a = Paint()..color = const Color(0xFF2A2A2E);
      final b = Paint()..color = const Color(0xFF38383D);
      for (var y = frame.top; y < frame.bottom; y += cell) {
        for (var x = frame.left; x < frame.right; x += cell) {
          final odd =
              (((x - frame.left) / cell).floor() +
                      ((y - frame.top) / cell).floor())
                  .isOdd;
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), odd ? a : b);
        }
      }
    } else {
      _paintBackground(canvas, frame, background, accent);
    }
    canvas.restore();
    _paintPicture(
      canvas,
      image,
      frame,
      view,
      turns,
      mirror,
      extraAngle,
      FilterQuality.medium,
    );
    // Outside the frame: dimmed, so what will be cut off reads at a glance.
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(all), cut),
      Paint()..color = _Ink.scrim,
    );
    canvas.drawPath(
      cut,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _Ink.hairline,
    );
    if (grid > 0) {
      final line = Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.35 * grid);
      canvas.save();
      canvas.clipPath(cut);
      for (final f in [1 / 3, 2 / 3]) {
        canvas.drawLine(
          Offset(frame.left + frame.width * f, frame.top),
          Offset(frame.left + frame.width * f, frame.bottom),
          line,
        );
        canvas.drawLine(
          Offset(frame.left, frame.top + frame.height * f),
          Offset(frame.right, frame.top + frame.height * f),
          line,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_EditorPainter old) =>
      old.view != view ||
      old.view.visible != view.visible ||
      old.view.center != view.center ||
      old.turns != turns ||
      old.mirror != mirror ||
      old.extraAngle != extraAngle ||
      old.frame != frame ||
      old.background != background ||
      old.checker != checker ||
      old.grid != grid ||
      old.image != image;
}

/// A small copy of the result, clipped to the avatar's shape.
class _PreviewPainter extends CustomPainter {
  _PreviewPainter(
    this.image,
    this.view,
    this.turns,
    this.mirror,
    this.shape,
    this.background,
    this.accent,
  );
  final ui.Image image;
  final _View view;
  final int turns;
  final bool mirror;
  final AvatarShape shape;
  final CropBackground background;
  final List<Color> accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(_shapePath(rect, shape));
    _paintBackground(canvas, rect, background, accent);
    _paintPicture(
      canvas,
      image,
      rect,
      view,
      turns,
      mirror,
      0,
      FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.view.visible != view.visible ||
      old.view.center != view.center ||
      old.turns != turns ||
      old.mirror != mirror ||
      old.background != background ||
      old.image != image;
}

// --- pieces ------------------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.cancel,
    required this.done,
    required this.onDone,
  });
  final String title;
  final String cancel;
  final String done;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xs,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          TextButton(
            key: const Key('avatarCropCancel'),
            style: TextButton.styleFrom(foregroundColor: _Ink.text),
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(cancel, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _Ink.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            key: const Key('avatarCropDone'),
            style: FilledButton.styleFrom(
              backgroundColor: _Ink.text,
              foregroundColor: Colors.black,
              disabledBackgroundColor: _Ink.raised,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: onDone,
            child: Text(done),
          ),
        ],
      ),
    );
  }
}

/// The result at the sizes it really appears: big, list size and sidebar size, and a sidebar row
/// on the app's light and dark surfaces. Redrawn on every frame of a gesture, from the same
/// decoded picture, so it costs next to nothing.
class _Previews extends StatelessWidget {
  const _Previews({
    required this.image,
    required this.view,
    required this.turns,
    required this.mirror,
    required this.shape,
    required this.background,
    required this.accent,
    required this.name,
  });

  final ui.Image image;
  final _View view;
  final int turns;
  final bool mirror;
  final AvatarShape shape;
  final CropBackground background;
  final List<Color> accent;
  final String name;

  Widget _avatar(double size) => CustomPaint(
    size: Size.square(size),
    painter: _PreviewPainter(
      image,
      view,
      turns,
      mirror,
      shape,
      background,
      accent,
    ),
  );

  Widget _row(Color surface, Color text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _avatar(24),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: AppSpace.md,
        children: [
          _avatar(56),
          _avatar(40),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                _row(_Ink.lightSurface, const Color(0xFF18181B)),
                _row(_Ink.darkSurface, _Ink.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.slider,
    required this.onSlider,
    required this.onSliderStart,
    required this.onSliderEnd,
    required this.onRotate,
    required this.onMirror,
    required this.onReset,
  });

  final double slider;
  final ValueChanged<double> onSlider;
  final VoidCallback onSliderStart;
  final VoidCallback onSliderEnd;
  final VoidCallback onRotate;
  final VoidCallback onMirror;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget tool(Key key, IconData icon, String tip, VoidCallback? onTap) =>
        IconButton(
          key: key,
          tooltip: tip,
          onPressed: onTap,
          color: _Ink.text,
          disabledColor: _Ink.muted.withValues(alpha: 0.5),
          icon: Icon(icon, size: 20),
        );
    final zoom = Row(
      children: [
        tool(
          const Key('avatarCropZoomOut'),
          LucideIcons.zoomOut,
          '${l10n.cropZoomOut} (−)',
          () => onSlider((slider - 0.1).clamp(0.0, 1.0)),
        ),
        Expanded(
          child: Slider(
            key: const Key('avatarCropZoom'),
            value: slider,
            semanticFormatterCallback: (_) => l10n.cropZoom,
            onChangeStart: (_) => onSliderStart(),
            onChangeEnd: (_) => onSliderEnd(),
            onChanged: onSlider,
          ),
        ),
        tool(
          const Key('avatarCropZoomIn'),
          LucideIcons.zoomIn,
          '${l10n.cropZoomIn} (+)',
          () => onSlider((slider + 0.1).clamp(0.0, 1.0)),
        ),
      ],
    );
    final tools = [
      tool(
        const Key('avatarCropRotate'),
        LucideIcons.rotateCw,
        '${l10n.cropRotate} (R)',
        onRotate,
      ),
      tool(
        const Key('avatarCropMirror'),
        LucideIcons.flipHorizontal2,
        '${l10n.cropMirror} (M)',
        onMirror,
      ),
    ];
    final reset = TextButton(
      key: const Key('avatarCropReset'),
      style: TextButton.styleFrom(
        foregroundColor: _Ink.text,
        disabledForegroundColor: _Ink.muted.withValues(alpha: 0.5),
      ),
      onPressed: onReset,
      child: Text(l10n.cropReset),
    );
    // Large text: the zoom gets its own line rather than squeezing the buttons.
    if (MediaQuery.textScalerOf(context).scale(14) > 20) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          zoom,
          Row(children: [...tools, const Spacer(), reset]),
        ],
      );
    }
    return Row(
      children: [
        ...tools,
        Expanded(child: zoom),
        reset,
      ],
    );
  }
}

class _BackgroundRow extends StatelessWidget {
  const _BackgroundRow({
    required this.value,
    required this.shape,
    required this.accent,
    required this.accentLabel,
    required this.onChanged,
  });
  final CropBackground value;
  final AvatarShape shape;
  final List<Color> accent;
  final String accentLabel;
  final ValueChanged<CropBackground> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget chip(CropBackground b, String label, Widget swatch) {
      final on = value == b;
      return Semantics(
        selected: on,
        button: true,
        child: InkWell(
          key: Key('avatarCropBackground-${b.name}'),
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(b),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            decoration: BoxDecoration(
              color: on
                  ? _Ink.text.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: on ? _Ink.text : _Ink.text.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                SizedBox.square(dimension: 18, child: swatch),
                Text(
                  label,
                  style: const TextStyle(color: _Ink.text, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget dot(Decoration d) => DecoratedBox(decoration: d);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(
          l10n.cropBackground,
          style: const TextStyle(
            color: _Ink.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: AppSpace.xs,
            children: [
              chip(
                CropBackground.none,
                l10n.cropBackgroundNone,
                dot(
                  BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _Ink.muted),
                    color: Colors.transparent,
                  ),
                ),
              ),
              if (shape == AvatarShape.bot)
                chip(
                  CropBackground.accent,
                  accentLabel,
                  dot(
                    BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: accent),
                    ),
                  ),
                ),
              chip(
                CropBackground.white,
                l10n.cropBackgroundWhite,
                dot(
                  const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
              chip(
                CropBackground.black,
                l10n.cropBackgroundBlack,
                dot(
                  BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(color: _Ink.muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
