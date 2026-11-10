// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_report_by_day_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UsageReportByDayInnerCWProxy {
  UsageReportByDayInner day(String day);

  UsageReportByDayInner costUsd(num costUsd);

  UsageReportByDayInner tokensIn(int tokensIn);

  UsageReportByDayInner tokensOut(int tokensOut);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportByDayInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportByDayInner(...).copyWith(id: 12, name: "My name")
  /// ```
  UsageReportByDayInner call({
    String day,
    num costUsd,
    int tokensIn,
    int tokensOut,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUsageReportByDayInner.copyWith(...)` or call `instanceOfUsageReportByDayInner.copyWith.fieldName(value)` for a single field.
class _$UsageReportByDayInnerCWProxyImpl
    implements _$UsageReportByDayInnerCWProxy {
  const _$UsageReportByDayInnerCWProxyImpl(this._value);

  final UsageReportByDayInner _value;

  @override
  UsageReportByDayInner day(String day) => call(day: day);

  @override
  UsageReportByDayInner costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  UsageReportByDayInner tokensIn(int tokensIn) => call(tokensIn: tokensIn);

  @override
  UsageReportByDayInner tokensOut(int tokensOut) => call(tokensOut: tokensOut);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportByDayInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportByDayInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UsageReportByDayInner call({
    Object? day = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? tokensIn = const $CopyWithPlaceholder(),
    Object? tokensOut = const $CopyWithPlaceholder(),
  }) {
    return UsageReportByDayInner(
      day: day == const $CopyWithPlaceholder() || day == null
          ? _value.day
          // ignore: cast_nullable_to_non_nullable
          : day as String,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      tokensIn: tokensIn == const $CopyWithPlaceholder() || tokensIn == null
          ? _value.tokensIn
          // ignore: cast_nullable_to_non_nullable
          : tokensIn as int,
      tokensOut: tokensOut == const $CopyWithPlaceholder() || tokensOut == null
          ? _value.tokensOut
          // ignore: cast_nullable_to_non_nullable
          : tokensOut as int,
    );
  }
}

extension $UsageReportByDayInnerCopyWith on UsageReportByDayInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUsageReportByDayInner.copyWith(...)` or `instanceOfUsageReportByDayInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UsageReportByDayInnerCWProxy get copyWith =>
      _$UsageReportByDayInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageReportByDayInner _$UsageReportByDayInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UsageReportByDayInner',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['day', 'cost_usd', 'tokens_in', 'tokens_out'],
    );
    final val = UsageReportByDayInner(
      day: $checkedConvert('day', (v) => v as String),
      costUsd: $checkedConvert('cost_usd', (v) => v as num),
      tokensIn: $checkedConvert('tokens_in', (v) => (v as num).toInt()),
      tokensOut: $checkedConvert('tokens_out', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'costUsd': 'cost_usd',
    'tokensIn': 'tokens_in',
    'tokensOut': 'tokens_out',
  },
);

Map<String, dynamic> _$UsageReportByDayInnerToJson(
  UsageReportByDayInner instance,
) => <String, dynamic>{
  'day': instance.day,
  'cost_usd': instance.costUsd,
  'tokens_in': instance.tokensIn,
  'tokens_out': instance.tokensOut,
};
