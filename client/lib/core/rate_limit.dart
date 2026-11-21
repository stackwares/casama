import 'dart:async';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';

/// How long the server asked us to wait (its `retry-after` header) when [error] is a 429, or null.
Duration? retryAfterOf(Object error) {
  if (error is! DioException || error.response?.statusCode != 429) return null;
  final raw = error.response?.headers.value('retry-after');
  final seconds = int.tryParse(raw?.trim() ?? '');
  if (seconds == null || seconds < 0) return null;
  return Duration(seconds: seconds);
}

/// Waits out a short 429 and sends the call once more, so a tap at the end of a rate window still
/// goes through instead of showing an error. The server turns a call away before it runs, so
/// sending it again is safe. Longer waits reach the caller, which shows a countdown.
class RateLimitRetryInterceptor extends Interceptor {
  RateLimitRetryInterceptor(
    this._dio, {
    this.maxWait = const Duration(seconds: 3),
  });

  final Dio _dio;
  final Duration maxWait;
  static const _retried = 'casama_rate_limit_retried';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final wait = retryAfterOf(err);
    final options = err.requestOptions;
    if (wait == null || wait > maxWait || options.extra[_retried] == true) {
      handler.next(err);
      return;
    }
    await Future<void>.delayed(wait);
    try {
      options.extra[_retried] = true;
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// A toast's message while a rate limit lasts: "Try again in 12 seconds", counting down, then
/// "You can try again now".
class RateLimitCountdown extends StatefulWidget {
  const RateLimitCountdown({super.key, required this.until, this.style});

  final DateTime until;
  final TextStyle? style;

  @override
  State<RateLimitCountdown> createState() => _RateLimitCountdownState();
}

class _RateLimitCountdownState extends State<RateLimitCountdown> {
  Timer? _timer;
  late final int _start = _byClock;
  int _ticks = 0;

  int get _byClock {
    final ms = widget.until.difference(DateTime.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  /// By the timer's own ticks, or the clock when timers ran late (the app was in the background).
  int get _left {
    final byTicks = _start - _ticks;
    final left = byTicks < _byClock ? byTicks : _byClock;
    return left < 0 ? 0 : left;
  }

  @override
  void initState() {
    super.initState();
    _start;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _ticks++);
      if (_left == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final left = _left;
    return Text(
      left > 0 ? l10n.tooManyRequestsWait(left) : l10n.tooManyRequestsReady,
      style: widget.style,
    );
  }
}
