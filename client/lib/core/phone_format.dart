import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Phone numbers in Casama are international (E.164, like +14155550123): each starts with + and
/// its country code, so the country comes from the number itself.
extension PhoneNumberText on String {
  /// "+14155550123" → "+1 415-555-0123": the country code, then the number grouped the way that
  /// country writes it. Text that isn't an international number comes back as it is.
  String get formattedPhoneNumber {
    final String digits = replaceAll(RegExp(r'[^0-9]'), '');
    if (!trim().startsWith('+') || digits.isEmpty) return this;

    try {
      final PhoneNumber phone = PhoneNumber.parse('+$digits');
      final String national = phone.formatNsn(format: NsnFormat.international);

      return national.isEmpty ? '+${phone.countryCode}' : '+${phone.countryCode} $national';
    } catch (_) {
      // Not a known country code yet (still typing): keep the digits.
      return '+$digits';
    }
  }

  /// "+1 415-555-0123" → "+14155550123", for sending to the server.
  String get unformattedPhoneNumber {
    final String digits = replaceAll(RegExp(r'[^0-9]'), '');

    return trim().startsWith('+') ? '+$digits' : digits;
  }
}

/// Formats an international phone number while it's typed (see [PhoneNumberText]).
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String text = newValue.text.formattedPhoneNumber;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
