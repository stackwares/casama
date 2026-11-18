import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Whether the app's server answers while the app is open (D-296). Launch has its own screen for a
/// server it can't reach; after that, a request that gets no answer used to fail quietly behind
/// the offline cache, so a phone away from a self-hosted server looked frozen. Every API call
/// reports here, and the bar over the app ([ServerReachabilityBar]) reads it.
enum Reachability {
  /// The last request got an answer (any answer, errors included: the server is there).
  ok,

  /// No answer at all: the phone is offline, or the server or the way to it is down.
  unreachable,

  /// The address answered but the computer behind it didn't: a tunnel with no connector (530) or
  /// a server that is down behind a working one (502 to 504). Only for servers people run
  /// themselves, as on the launch screen ([tunnelSaysOffline]).
  serverOffline,
}

/// The app's one server: what its requests last found.
final serverReachability = ValueNotifier<Reachability>(Reachability.ok);

/// What a request's outcome says about the server, or null when it says nothing (a cancelled
/// request, or a response the server itself sent).
@visibleForTesting
Reachability? reachabilityOf(DioException e, String apiUrl) {
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
      return Reachability.unreachable;
    case DioExceptionType.unknown:
      // Socket and TLS failures that Dio doesn't name arrive here without a response.
      return e.response == null ? Reachability.unreachable : null;
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final gateway =
          status == 530 || status == 502 || status == 503 || status == 504;
      if (!gateway) return Reachability.ok;
      return isCasamaCloud(apiUrl)
          ? Reachability.unreachable
          : Reachability.serverOffline;
    // A slow answer (a long run, a big file) means the server is there.
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
      return null;
  }
}

/// Casama Cloud has no computer of anyone's to be asleep, so its gateway errors aren't "offline".
bool isCasamaCloud(String apiUrl) {
  final host = Uri.tryParse(apiUrl)?.host ?? '';
  return host == 'casama.ai' || host.endsWith('.casama.ai');
}

/// Reports every outcome of [dio]'s requests to [serverReachability].
void watchReachability(Dio dio, String apiUrl) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) {
        serverReachability.value = Reachability.ok;
        handler.next(response);
      },
      onError: (e, handler) {
        final r = reachabilityOf(e, apiUrl);
        if (r != null) serverReachability.value = r;
        handler.next(e);
      },
    ),
  );
}

/// Asks the server whether it answers, for the bar's Try Again and its own retries. Reports the
/// result to [serverReachability] and returns whether it answered.
Future<bool> checkServer(String apiUrl) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );
  try {
    await dio.get<Object?>(
      '${apiUrl.replaceAll(RegExp(r'/+$'), '')}/v1/config',
    );
    serverReachability.value = Reachability.ok;
    return true;
  } on DioException catch (e) {
    serverReachability.value =
        reachabilityOf(e, apiUrl) ?? Reachability.unreachable;
    return serverReachability.value == Reachability.ok;
  } finally {
    dio.close();
  }
}
