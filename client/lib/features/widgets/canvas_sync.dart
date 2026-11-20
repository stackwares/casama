import 'dart:async';
import 'dart:convert';

import 'package:casama_sdk/casama_sdk.dart' show Canvas, CanvasBackgroundKindEnum, CanvasEntryTemplateEnum, CanvasList, CanvasStatusEnum;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/mobile_extras.dart' show appGroupId;
import 'glance_sync.dart' show glanceGap, widgetsChannel;
import 'widget_settings.dart';

/// The app's carrier for the Canvas widget (bot widgets, docs/BOT-WIDGET-PLAN.md §10.3). While
/// Casama is open, after the person changes something and when the app opens or comes forward, it
/// fetches the canvases with the session (at most once in [glanceGap], with the list's version as
/// ETag) and writes them where the widgets read, then asks them to redraw. On iPhone and Android
/// the widgets also fetch on their own with the widget key, pictures included; the Mac's widgets
/// can't, so there the app hands the pictures over too (`casama/mac` → `canvases`).

const _macChannel = MethodChannel('casama/mac');

/// The Android provider of the Canvas widget, in [androidWidgetProviders].
const canvasAndroidProvider = 'CanvasWidget';

/// Where the Canvas widget reads on this device. Replaced in tests.
abstract class CanvasSurface {
  /// The Mac: its widgets take the pictures from the app; elsewhere they fetch them.
  bool get takesPictures;

  /// Writes the list as JSON (null when signed out, which forgets it) and asks the Canvas widgets
  /// to redraw. [pictures] by hash, for the Mac.
  Future<void> publish(String? canvases, Map<String, Uint8List> pictures);

  static CanvasSurface? forPlatform() {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => _IosCanvasSurface(),
      TargetPlatform.android => _AndroidCanvasSurface(),
      TargetPlatform.macOS => _MacCanvasSurface(),
      _ => null,
    };
  }
}

/// home_widget's store, under `canvases` beside the glance.
abstract class _PhoneCanvasSurface implements CanvasSurface {
  @override
  bool get takesPictures => false;

  Future<void> _prepare() async {}
  Future<void> _redraw();

  @override
  Future<void> publish(String? canvases, Map<String, Uint8List> pictures) async {
    await _prepare();
    await HomeWidget.saveWidgetData<String>('canvases', canvases);
    await _redraw();
  }
}

class _IosCanvasSurface extends _PhoneCanvasSurface {
  @override
  Future<void> _prepare() => HomeWidget.setAppGroupId(appGroupId).then((_) {});

  /// One WidgetCenter reload covers every kind.
  @override
  Future<void> _redraw() => widgetsChannel.invokeMethod<void>('reload');
}

class _AndroidCanvasSurface extends _PhoneCanvasSurface {
  @override
  Future<void> _redraw() async {
    try {
      await HomeWidget.updateWidget(androidName: canvasAndroidProvider);
    } catch (_) {
      // A build without the Canvas widget yet.
    }
  }
}

class _MacCanvasSurface implements CanvasSurface {
  @override
  bool get takesPictures => true;

  @override
  Future<void> publish(String? canvases, Map<String, Uint8List> pictures) =>
      _macChannel.invokeMethod<void>('canvases', {'canvases': canvases, 'pictures': pictures});
}

/// The pictures a canvas's entries draw: a picture background, or the picture template's own.
Set<String> canvasPictureHashes(Canvas canvas) => {
  for (final e in canvas.entries) ...[
    if (e.look.background.kind == CanvasBackgroundKindEnum.picture && (e.look.background.picture ?? '').isNotEmpty) e.look.background.picture!,
    if (e.template == CanvasEntryTemplateEnum.picture && (e.picture ?? '').isNotEmpty) e.picture!,
  ],
};

/// What the Mac's widgets get: only canvases that show (as a widget key would read them), and with
/// [private] names and bots only (the app lock, D-405).
Map<String, Object?> widgetCanvasJson(CanvasList list, {required bool private}) {
  final json = list.toJson();
  final hide = private || list.private;
  json['private'] = hide;
  json['items'] = [
    for (final c in list.items)
      if (c.status == CanvasStatusEnum.shown) {...c.toJson(), if (hide) 'entries': const <Object?>[]},
  ];
  return json;
}

/// Keeps the Canvas widgets in step with the app. Public for tests.
class CanvasSync {
  CanvasSync(this._ref, this._surface, {this.gap = glanceGap, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Ref _ref;
  final CanvasSurface _surface;
  final Duration gap;
  final DateTime Function() _now;

  Timer? _timer;
  DateTime? _last;
  var _running = false;
  var _again = false;

  /// The last list fetched, its workspace, and (the Mac) the pictures it draws.
  CanvasList? _list;
  String? _listOrg;
  final _pictures = <String, Uint8List>{};
  String? _written;

  /// Soon: at most once in [gap]. [now] (the person just changed something) goes at once.
  void schedule({bool now = false}) {
    if (now) {
      _timer?.cancel();
      _timer = null;
      unawaited(_run());
      return;
    }
    if (_timer != null) return;
    final last = _last;
    final since = last == null ? gap : _now().difference(last);
    if (since >= gap) {
      unawaited(_run());
    } else {
      _timer = Timer(gap - since, () {
        _timer = null;
        unawaited(_run());
      });
    }
  }

  void dispose() => _timer?.cancel();

  Future<void> _run() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    _last = _now();
    try {
      await sync();
    } catch (e) {
      debugPrint('canvas sync failed: $e');
    } finally {
      _running = false;
    }
    if (_again && _ref.mounted) {
      _again = false;
      schedule();
    }
  }

  /// One fetch and write, without the gap. Public for tests.
  Future<void> sync() async {
    if (!_ref.mounted) return;
    if (_ref.read(signedInProvider).value != true) return signedOut();
    final orgId = _ref.read(currentOrgIdProvider);
    if (orgId == null) return;
    final backend = _ref.read(backendProvider);
    final known = _listOrg == orgId ? _list : null;
    final fetched = await backend.canvases(orgId, ifNoneMatch: known?.version);
    if (!_ref.mounted) return;
    final list = fetched ?? known;
    if (list == null) return;
    _list = list;
    _listOrg = orgId;
    await write();
  }

  /// Writes the last list, made private when it should be; on the Mac with the pictures it draws
  /// (fetched once each: a hash is always the same picture). Public for tests.
  Future<void> write() async {
    final list = _list;
    if (list == null || !_ref.mounted) return;
    final private = _ref.read(widgetsPrivateProvider);
    final json = widgetCanvasJson(list, private: private);
    final needed = <String, String>{
      if (_surface.takesPictures && !(private || list.private))
        for (final c in list.items)
          if (c.status == CanvasStatusEnum.shown)
            for (final h in canvasPictureHashes(c)) h: c.id,
    };
    final backend = _ref.read(backendProvider);
    for (final MapEntry(key: hash, value: canvasId) in needed.entries) {
      if (_pictures.containsKey(hash)) continue;
      try {
        final bytes = await backend.canvasPicture(canvasId, hash);
        if (bytes != null) _pictures[hash] = bytes;
      } catch (e) {
        debugPrint('canvas picture failed: $e');
      }
      if (!_ref.mounted) return;
    }
    _pictures.removeWhere((h, _) => !needed.containsKey(h));
    final encoded = jsonEncode(json);
    final key = '$encoded|${(_pictures.keys.toList()..sort()).join(',')}';
    if (key == _written) return;
    _written = key;
    try {
      await _surface.publish(encoded, Map.of(_pictures));
    } catch (e) {
      _written = null;
      debugPrint('canvas write failed: $e');
    }
  }

  /// Signed out: the widgets forget every canvas.
  Future<void> signedOut() async {
    _timer?.cancel();
    _timer = null;
    _list = null;
    _listOrg = null;
    _pictures.clear();
    if (_written == 'signed-out') return;
    _written = 'signed-out';
    try {
      await _surface.publish(null, const {});
    } catch (e) {
      debugPrint('canvas clear failed: $e');
    }
  }
}

/// Where the Canvas widget lives on this device; null where there is none. Overridden in tests.
final canvasSurfaceProvider = Provider<CanvasSurface?>((ref) => CanvasSurface.forPlatform());

/// The carrier, on iPhone, Android and the Mac; null elsewhere. Watched by the app root.
final canvasSyncProvider = Provider<CanvasSync?>((ref) {
  final surface = ref.watch(canvasSurfaceProvider);
  if (surface == null) return null;
  final sync = CanvasSync(ref, surface);
  ref.onDispose(sync.dispose);
  ref.listen(signedInProvider, (_, next) {
    if (next.value == false) {
      unawaited(sync.signedOut());
    } else if (next.value == true) {
      sync.schedule();
    }
  }, fireImmediately: true);
  ref.listen(currentOrgIdProvider, (_, _) => sync.schedule());
  ref.listen(widgetsPrivateProvider, (prev, next) {
    if (prev != next) unawaited(sync.write());
  });
  final lifecycle = AppLifecycleListener(onResume: sync.schedule);
  ref.onDispose(lifecycle.dispose);
  return sync;
});

/// The canvases in the current workspace, for Settings → Widgets and the preview card. Null with
/// no workspace.
final canvasListProvider = FutureProvider.autoDispose<CanvasList?>((ref) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return null;
  return ref.watch(backendProvider).canvases(orgId);
});

/// The person changed a canvas or a bot's permission: the lists read again and the widgets redraw
/// at once.
void canvasesChanged(WidgetRef ref) {
  ref.invalidate(canvasListProvider);
  ref.read(canvasSyncProvider)?.schedule(now: true);
}

/// `/canvases/:id`: the canvas's own link (its bot's chat), or Settings → Widgets when it is gone.
Future<String> canvasLocation(Backend backend, String? orgId, String id) async {
  const fallback = '/settings/widgets';
  if (orgId == null) return fallback;
  try {
    final list = await backend.canvases(orgId);
    final link = list?.items.where((c) => c.id == id).firstOrNull?.link ?? '';
    return link.startsWith('/') ? link : fallback;
  } catch (_) {
    return fallback;
  }
}
