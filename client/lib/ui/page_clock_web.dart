import 'package:web/web.dart' as web;

/// `performance.now()`: milliseconds since navigation started.
double? pageClockMs() => web.window.performance.now();
