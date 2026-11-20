// Milliseconds since the web page started loading (`performance.now()`), so motion that starts on
// the web loading page can carry on in Flutter at the same point. Null off the web.
export 'page_clock_stub.dart'
    if (dart.library.js_interop) 'page_clock_web.dart';
