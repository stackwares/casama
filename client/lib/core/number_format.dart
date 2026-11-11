import 'package:intl/intl.dart';

/// Numbers as people read them, in their locale (pass `context.l10n.localeName`):
/// 1234567 → "1,234,567" in English, "1.234.567" in German.
extension HumanNumbers on num {
  /// A count or amount: 1234567 → "1,234,567". [decimalDigits] fixes the digits after the point.
  String humanizedCount(String locale, {int? decimalDigits}) {
    return NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimalDigits).format(this);
  }

  /// Money with its symbol and the currency's decimals: 1234.5 → "$1,234.50" in English,
  /// "1.234,50 $" in German. [decimalDigits] overrides the currency's usual decimals.
  String humanizedCurrency(String locale, String code, {int? decimalDigits}) {
    return NumberFormat.simpleCurrency(locale: locale, name: code, decimalDigits: decimalDigits).format(this);
  }

  /// Big numbers, short: 1234567 → "1.23M", 9800 → "9.8K".
  String humanizedCompact(String locale) {
    return NumberFormat.compact(locale: locale).format(this);
  }
}
