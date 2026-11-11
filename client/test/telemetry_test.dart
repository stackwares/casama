import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/telemetry.dart';

void main() {
  test('error payloads lose secrets and emails', () {
    final s = Telemetry.scrub('failed for ada@example.com using sk-or-v1-abcdef1234567890 and Bearer abcdefghijklmnop');
    expect(s, isNot(contains('ada@example.com')));
    expect(s, isNot(contains('sk-or-v1')));
    expect(s, isNot(contains('abcdefghijklmnop')));
  });

  test('reporting is off without keys', () {
    expect(Telemetry.sentryErrors, isFalse);
    expect(Telemetry.posthogOn, isFalse);
    expect(Telemetry.observers, isEmpty);
  });
}
