// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_summary_computer_hours.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BillingSummaryComputerHoursCWProxy {
  BillingSummaryComputerHours usedHours(num usedHours);

  BillingSummaryComputerHours limitHours(num limitHours);

  BillingSummaryComputerHours resetsAt(DateTime resetsAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingSummaryComputerHours(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingSummaryComputerHours(...).copyWith(id: 12, name: "My name")
  /// ```
  BillingSummaryComputerHours call({
    num usedHours,
    num limitHours,
    DateTime resetsAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBillingSummaryComputerHours.copyWith(...)` or call `instanceOfBillingSummaryComputerHours.copyWith.fieldName(value)` for a single field.
class _$BillingSummaryComputerHoursCWProxyImpl
    implements _$BillingSummaryComputerHoursCWProxy {
  const _$BillingSummaryComputerHoursCWProxyImpl(this._value);

  final BillingSummaryComputerHours _value;

  @override
  BillingSummaryComputerHours usedHours(num usedHours) =>
      call(usedHours: usedHours);

  @override
  BillingSummaryComputerHours limitHours(num limitHours) =>
      call(limitHours: limitHours);

  @override
  BillingSummaryComputerHours resetsAt(DateTime resetsAt) =>
      call(resetsAt: resetsAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingSummaryComputerHours(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingSummaryComputerHours(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BillingSummaryComputerHours call({
    Object? usedHours = const $CopyWithPlaceholder(),
    Object? limitHours = const $CopyWithPlaceholder(),
    Object? resetsAt = const $CopyWithPlaceholder(),
  }) {
    return BillingSummaryComputerHours(
      usedHours: usedHours == const $CopyWithPlaceholder() || usedHours == null
          ? _value.usedHours
          // ignore: cast_nullable_to_non_nullable
          : usedHours as num,
      limitHours:
          limitHours == const $CopyWithPlaceholder() || limitHours == null
          ? _value.limitHours
          // ignore: cast_nullable_to_non_nullable
          : limitHours as num,
      resetsAt: resetsAt == const $CopyWithPlaceholder() || resetsAt == null
          ? _value.resetsAt
          // ignore: cast_nullable_to_non_nullable
          : resetsAt as DateTime,
    );
  }
}

extension $BillingSummaryComputerHoursCopyWith on BillingSummaryComputerHours {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBillingSummaryComputerHours.copyWith(...)` or `instanceOfBillingSummaryComputerHours.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BillingSummaryComputerHoursCWProxy get copyWith =>
      _$BillingSummaryComputerHoursCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillingSummaryComputerHours _$BillingSummaryComputerHoursFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'BillingSummaryComputerHours',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['used_hours', 'limit_hours', 'resets_at'],
    );
    final val = BillingSummaryComputerHours(
      usedHours: $checkedConvert('used_hours', (v) => v as num),
      limitHours: $checkedConvert('limit_hours', (v) => v as num),
      resetsAt: $checkedConvert(
        'resets_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'usedHours': 'used_hours',
    'limitHours': 'limit_hours',
    'resetsAt': 'resets_at',
  },
);

Map<String, dynamic> _$BillingSummaryComputerHoursToJson(
  BillingSummaryComputerHours instance,
) => <String, dynamic>{
  'used_hours': instance.usedHours,
  'limit_hours': instance.limitHours,
  'resets_at': instance.resetsAt.toIso8601String(),
};
