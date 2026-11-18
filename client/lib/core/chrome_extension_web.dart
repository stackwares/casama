import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Sends [message] to the extension [id] with `chrome.runtime.sendMessage`. Chrome only offers that
/// on pages an installed extension lists in `externally_connectable`, so null means no extension
/// here, or not that one.
Future<Map<String, Object?>?> sendToChromeExtension(
  String id,
  Map<String, Object?> message,
) {
  final chrome = globalContext['chrome'];
  if (chrome.isUndefinedOrNull) return Future.value(null);
  final runtime = (chrome! as JSObject)['runtime'];
  if (runtime.isUndefinedOrNull || !(runtime! as JSObject).has('sendMessage')) {
    return Future.value(null);
  }
  final api = runtime as JSObject;
  final done = Completer<Map<String, Object?>?>();
  void reply(JSAny? answer) {
    // Reading lastError tells Chrome a missing extension was expected.
    api['lastError'];
    if (done.isCompleted) return;
    final value = answer?.dartify();
    done.complete(value is Map ? value.map((k, v) => MapEntry('$k', v)) : null);
  }

  try {
    api.callMethodVarArgs('sendMessage'.toJS, [
      id.toJS,
      message.jsify(),
      reply.toJS,
    ]);
  } catch (_) {
    // Chrome throws at once for an id it can't message from this page.
    return Future.value(null);
  }
  return done.future.timeout(
    const Duration(seconds: 30),
    onTimeout: () => null,
  );
}
