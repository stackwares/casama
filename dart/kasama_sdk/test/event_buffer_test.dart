import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:test/test.dart';

Map<String, dynamic> ev(int seq, String type, Map<String, dynamic> payload) => {
      'v': 1,
      'run_id': '11111111-1111-4111-8111-111111111111',
      'seq': seq,
      'ts': '2026-11-09T09:30:00.000Z',
      'bot_id': '22222222-2222-4222-8222-222222222222',
      'type': type,
      'payload': payload,
    };

void main() {
  test('parses known event types into typed items', () {
    final item = RunEventItem.fromJson(
        ev(1, 'tool.output', {'call_id': 'c1', 'chunk': 'hello\n'}));
    expect(item, isA<ToolOutputItem>());
    expect((item as ToolOutputItem).event.payload.chunk, 'hello\n');
  });

  test('unknown types parse to UnknownRunEventItem', () {
    final item = RunEventItem.fromJson(ev(1, 'future.thing', {'x': 1}));
    expect(item, isA<UnknownRunEventItem>());
    expect(item.seq, 1);
  });

  test('buffer orders by seq and drops duplicates', () {
    final buf = RunEventBuffer();
    final e = [for (var i = 1; i <= 4; i++) RunEventItem.fromJson(ev(i, 'future.thing', {}))];
    expect(buf.add(e[1]), isEmpty);
    expect(buf.hasGap, isTrue);
    expect(buf.add(e[0]).map((x) => x.seq), [1, 2]);
    expect(buf.add(e[0]), isEmpty);
    expect(buf.addAll([e[3], e[2], e[3]]).map((x) => x.seq), [3, 4]);
    expect(buf.hasGap, isFalse);
    expect(buf.lastSeq, 4);
  });
}
