import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/number_format.dart';
import 'package:casama_app/core/providers.dart' show formatUsd;
import 'package:casama_app/features/chat/widgets/chat_widgets.dart' show formatDuration;
import 'package:casama_app/features/files/file_preview.dart' show formatBytes;

void main() {
  test('counts group digits the way the locale writes them', () {
    expect(1234567.humanizedCount('en'), '1,234,567');
    expect(1234567.humanizedCount('de'), '1.234.567');
    expect(2.humanizedCount('en', decimalDigits: 2), '2.00');
  });

  test('money carries its symbol where the locale puts it', () {
    expect(1234.5.humanizedCurrency('en', 'USD'), r'$1,234.50');
    expect(1234.5.humanizedCurrency('de', 'USD'), '1.234,50\u00a0\$');
    expect(25.humanizedCurrency('en', 'USD', decimalDigits: 0), r'$25');
  });

  test('big numbers read short', () {
    expect(1234567.humanizedCompact('en'), '1.23M');
    expect(9800.humanizedCompact('en'), '9.8K');
    expect(999.humanizedCompact('en'), '999');
  });

  test('formatUsd keeps two decimals from a dollar up and four below', () {
    expect(formatUsd(1234.5, 'en'), r'$1,234.50');
    expect(formatUsd(0, 'en'), r'$0.00');
    expect(formatUsd(0.0123, 'en'), r'$0.0123');
  });

  test('durations and file sizes', () {
    expect(formatDuration(42, 'en'), '42 ms');
    expect(formatDuration(1500, 'en'), '1.5 s');
    expect(formatDuration(12000, 'en'), '12 s');
    expect(formatBytes(512, 'en'), '512 B');
    expect(formatBytes(1536, 'en'), '1.5 KB');
    expect(formatBytes(3 * 1024 * 1024, 'en'), '3.0 MB');
  });
}
