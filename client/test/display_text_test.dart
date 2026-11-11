import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/display_text.dart';

void main() {
  test('null, empty, blank and the word "null" are not usable', () {
    for (final value in <String?>[null, '', '   ', 'null']) {
      expect(value.isUsable, isFalse, reason: '$value');
      expect(value.orPlaceholder(), '—', reason: '$value');
      expect(value.orPlaceholder('Untitled chat'), 'Untitled chat', reason: '$value');
    }
  });

  test('real text passes through as it is', () {
    expect('Ada'.isUsable, isTrue);
    expect('Ada'.orPlaceholder(), 'Ada');
    expect(' Ada '.orPlaceholder(), ' Ada ');
    expect('nullable'.orPlaceholder(), 'nullable');
  });

  test('non-text values go through toString first', () {
    final Map<String, Object?> sourceRef = {'repo': null};
    expect((sourceRef['repo']?.toString()).orPlaceholder(), kMissingValue);
  });
}
