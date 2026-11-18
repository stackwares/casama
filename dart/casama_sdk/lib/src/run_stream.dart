import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'client.dart';
import 'event_buffer.dart';
import 'generated/run_events.dart';

const terminalRunEventTypes = {'run.completed', 'run.failed', 'run.cancelled'};

/// One server-sent event.
class SseMessage {
  SseMessage(this.event, this.data, this.id);
  final String event;
  final String data;
  final String? id;
}

/// Parses a text/event-stream byte stream into messages.
Stream<SseMessage> parseSse(Stream<List<int>> bytes) async* {
  var event = 'message';
  final data = StringBuffer();
  String? id;
  await for (final line in bytes.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) yield SseMessage(event, data.toString(), id);
      event = 'message';
      data.clear();
      continue;
    }
    if (line.startsWith(':')) continue;
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        event = value;
      case 'data':
        if (data.isNotEmpty) data.write('\n');
        data.write(value);
      case 'id':
        id = value;
    }
  }
}

/// Streams a run's events in seq order: missed events first, then live ones, until the run ends.
/// Reconnects with backoff, resuming after the last seq it delivered.
Stream<RunEventItem> watchRun(CasamaClient client, String runId, {int afterSeq = 0, int maxRetries = 8}) async* {
  final buffer = RunEventBuffer(lastSeq: afterSeq);
  var failures = 0;
  while (true) {
    try {
      final session = await client.currentSession();
      final res = await client.api.dio.get<ResponseBody>(
        '/v1/runs/$runId/events',
        queryParameters: {'after_seq': buffer.lastSeq},
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 2),
          headers: {
            'accept': 'text/event-stream',
            if (buffer.lastSeq > 0) 'last-event-id': '${buffer.lastSeq}',
            if (session != null) 'authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );
      failures = 0;
      await for (final msg in parseSse(res.data!.stream)) {
        if (msg.event != 'run_event') continue;
        final item = RunEventItem.fromJson(jsonDecode(msg.data) as Map<String, dynamic>);
        for (final ready in buffer.add(item)) {
          yield ready;
          if (terminalRunEventTypes.contains(ready.type)) return;
        }
      }
      // The server closes the stream after a terminal event; if we got here without one, check the run.
      final run = (await client.api.getRunsApi().getRun(id: runId)).data!;
      if (['completed', 'failed', 'cancelled'].contains(run.status.value) && run.lastSeq <= buffer.lastSeq) return;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500 && status != 408 && status != 429) rethrow;
      failures++;
      if (failures > maxRetries) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 250 * (1 << (failures - 1)).clamp(1, 32)));
    }
  }
}
