// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_summary_daily.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BillingSummaryDailyCWProxy {
  BillingSummaryDaily usedUsd(num usedUsd);

  BillingSummaryDaily capUsd(num capUsd);

  BillingSummaryDaily resetsAt(DateTime resetsAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingSummaryDaily(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingSummaryDaily(...).copyWith(id: 12, name: "My name")
  /// ```
  BillingSummaryDaily call({num usedUsd, num capUsd, DateTime resetsAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBillingSummaryDaily.copyWith(...)` or call `instanceOfBillingSummaryDaily.copyWith.fieldName(value)` for a single field.
class _$BillingSummaryDailyCWProxyImpl implements _$BillingSummaryDailyCWProxy {
  const _$BillingSummaryDailyCWProxyImpl(this._value);

  final BillingSummaryDaily _value;

  @override
  BillingSummaryDaily usedUsd(num usedUsd) => call(usedUsd: usedUsd);

  @override
  BillingSummaryDaily capUsd(num capUsd) => call(capUsd: capUsd);

  @override
  BillingSummaryDaily resetsAt(DateTime resetsAt) => call(resetsAt: resetsAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingSummaryDaily(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingSummaryDaily(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BillingSummaryDaily call({
    Object? usedUsd = const $CopyWithPlaceholder(),
    Object? capUsd = const $CopyWithPlaceholder(),
    Object? resetsAt = const $CopyWithPlaceholder(),
  }) {
    return BillingSummaryDaily(
      usedUsd: usedUsd == const $CopyWithPlaceholder() || usedUsd == null
          ? _value.usedUsd
          // ignore: cast_nullable_to_non_nullable
          : usedUsd as num,
      capUsd: capUsd == const $CopyWithPlaceholder() || capUsd == null
          ? _value.capUsd
          // ignore: cast_nullable_to_non_nullable
          : capUsd as num,
      resetsAt: resetsAt == const $CopyWithPlaceholder() || resetsAt == null
          ? _value.resetsAt
          // ignore: cast_nullable_to_non_nullable
          : resetsAt as DateTime,
    );
  }
}

extension $BillingSummaryDailyCopyWith on BillingSummaryDaily {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBillingSummaryDaily.copyWith(...)` or `instanceOfBillingSummaryDaily.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BillingSummaryDailyCWProxy get copyWith =>
      _$BillingSummaryDailyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillingSummaryDaily _$BillingSummaryDailyFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'BillingSummaryDaily',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['used_usd', 'cap_usd', 'resets_at'],
        );
        final val = BillingSummaryDaily(
          usedUsd: $checkedConvert('used_usd', (v) => v as num),
          capUsd: $checkedConvert('cap_usd', (v) => v as num),
          resetsAt: $checkedConvert(
            'resets_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'usedUsd': 'used_usd',
        'capUsd': 'cap_usd',
        'resetsAt': 'resets_at',
      },
    );

Map<String, dynamic> _$BillingSummaryDailyToJson(
  BillingSummaryDaily instance,
) => <String, dynamic>{
  'used_usd': instance.usedUsd,
  'cap_usd': instance.capUsd,
  'resets_at': instance.resetsAt.toIso8601String(),
};
