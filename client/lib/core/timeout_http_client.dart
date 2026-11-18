import 'dart:async';

import 'package:http/http.dart' as http;

/// An HTTP client that gives up on a server that stops answering.
///
/// [headers] limits the wait for the response to start; [idle] limits a gap
/// while its body arrives. The Supabase client uses it, which otherwise waits
/// on the operating system's own limit (minutes) and leaves a screen loading.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({http.Client? inner, this.headers = const Duration(seconds: 30), this.idle = const Duration(seconds: 30)}) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration headers;
  final Duration idle;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final res = await _inner.send(request).timeout(headers, onTimeout: () => throw TimeoutException('No answer from ${request.url.host} in ${headers.inSeconds} s', headers));
    return http.StreamedResponse(
      res.stream.timeout(
        idle,
        onTimeout: (sink) {
          sink.addError(TimeoutException('${request.url.host} stopped sending for ${idle.inSeconds} s', idle));
          sink.close();
        },
      ),
      res.statusCode,
      contentLength: res.contentLength,
      request: res.request,
      headers: res.headers,
      isRedirect: res.isRedirect,
      persistentConnection: res.persistentConnection,
      reasonPhrase: res.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
