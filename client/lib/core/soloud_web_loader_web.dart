import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _script = 'assets/packages/flutter_soloud/web/init_soloud.js';

Future<void>? _loading;

/// Loads flutter_soloud's start-up script the first time a live call needs audio, not with the
/// page: it fetches and compiles a 2.6 MB WebAssembly module and starts audio threads, which slowed
/// every page load for a feature few visits use. Once the script has run, `SoLoud.init()` waits
/// for the module itself (flutter_soloud_ready).
Future<void> ensureSoloudLoaded() => _loading ??= _load();

Future<void> _load() {
  final done = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src = _script
    ..onload = ((web.Event _) => done.complete()).toJS
    ..onerror = ((web.Event _) {
      _loading = null;
      done.completeError(StateError('Could not load $_script'));
    }).toJS;
  web.document.head!.appendChild(script);
  return done.future;
}
