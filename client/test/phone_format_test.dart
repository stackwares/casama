import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/phone_format.dart';

void main() {
  test('international numbers read in groups', () {
    expect('+14155550123'.formattedPhoneNumber, '+1 415-555-0123');
    expect('+1 (415) 555-0123'.formattedPhoneNumber, '+1 415-555-0123');
  });

  test('the number goes back to the server without the grouping', () {
    expect('+1 415-555-0123'.unformattedPhoneNumber, '+14155550123');
    expect('+14155550123'.formattedPhoneNumber.unformattedPhoneNumber, '+14155550123');
  });

  test('text that is not an international number is left as typed', () {
    expect(''.formattedPhoneNumber, '');
    expect('+'.formattedPhoneNumber, '+');
    expect('4155550123'.formattedPhoneNumber, '4155550123');
  });

  test('the field formats while typing and keeps the cursor at the end', () {
    const formatter = PhoneInputFormatter();
    final value = formatter.formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: '+14155550123'));
    expect(value.text, '+1 415-555-0123');
    expect(value.selection, const TextSelection.collapsed(offset: 15));
  });
}
