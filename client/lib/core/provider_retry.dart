import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When a failed provider tries again (the app's ProviderScope).
///
/// Riverpod retries every failed provider up to ten times, about 40 seconds in all, and the
/// provider reads as loading the whole time, so a screen shows its skeleton instead of the error.
/// That helps when the network or server is away for a moment. An answer the server gave on purpose
/// (400 bad request, 403 not allowed, 404 not found) comes back the same each time: it shows at
/// once, and the person can still tap Try again. Timeouts (408) and rate limits (429) do retry.
Duration? appProviderRetry(int retryCount, Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode ?? 0;
    if (status >= 400 && status < 500 && status != 408 && status != 429) {
      return null;
    }
  }
  return ProviderContainer.defaultRetry(retryCount, error);
}
