import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('payloads with null values parse', () {
    final item = RunEventItem.fromJson({
      'v': 1,
      'run_id': '11111111-1111-4111-8111-111111111111',
      'seq': 1,
      'ts': '2026-11-09T09:30:00.000Z',
      'bot_id': '22222222-2222-4222-8222-222222222222',
      'type': 'run.started',
      'payload': {'trigger': 'chat', 'model': 'm', 'computer_id': null},
    });
    expect(item, isA<RunStartedItem>());
    expect((item as RunStartedItem).event.payload.computerId, isNull);
  });
}
