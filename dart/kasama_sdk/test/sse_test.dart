import 'dart:convert';

import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('parses server-sent events across chunk boundaries', () async {
    const raw = 'event: run_event\nid: 1\ndata: {"a":1}\n\n: comment\nevent: ping\ndata: {}\n\nevent: run_event\nid: 2\ndata: {"b":\ndata: 2}\n\n';
    final bytes = utf8.encode(raw);
    final chunks = [bytes.sublist(0, 7), bytes.sublist(7, 40), bytes.sublist(40)];
    final msgs = await parseSse(Stream.fromIterable(chunks)).toList();
    expect(msgs.map((m) => m.event), ['run_event', 'ping', 'run_event']);
    expect(msgs.first.id, '1');
    expect(msgs.last.data, '{"b":\n2}');
  });
}
