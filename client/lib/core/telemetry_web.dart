import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('window.posthog')
external JSObject? get _windowPosthog;

@JS('window.posthog.init')
external void _posthogInit(JSString apiKey, JSObject options);

/// Injects posthog-js dynamically when a PostHog key is set on web,
/// without modifying index.html for self-hosters (ANALYTICS-PLAN.md §4.2).
Future<void> initWebPosthog({
  required String apiKey,
  required String host,
}) async {
  if (_windowPosthog != null) return;

  final completer = Completer<void>();
  final script = web.document.createElement('script') as web.HTMLScriptElement;
  script.type = 'text/javascript';
  script.crossOrigin = 'anonymous';
  script.async = true;

  final assetHost = host.contains('.i.posthog.com')
      ? host.replaceAll('.i.posthog.com', '-assets.i.posthog.com')
      : host;
  script.src = '$assetHost/static/array.js';

  script.onload = ((web.Event _) {
    final options =
        {
              'api_host': host,
              'autocapture': false,
              'capture_pageview': false,
              'disable_session_recording': true,
              'persistence': 'localStorage',
            }.jsify()
            as JSObject;
    try {
      _posthogInit(apiKey.toJS, options);
    } catch (_) {}
    if (!completer.isCompleted) completer.complete();
  }).toJS;

  script.onerror = ((web.Event _) {
    if (!completer.isCompleted) completer.complete();
  }).toJS;

  web.document.head?.appendChild(script);
  await completer.future.timeout(const Duration(seconds: 3), onTimeout: () {});
}
