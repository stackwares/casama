// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_summary_comp.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BillingSummaryCompCWProxy {
  BillingSummaryComp planCode(String planCode);

  BillingSummaryComp endsAt(DateTime endsAt);

  BillingSummaryComp from(BillingSummaryCompFromEnum from);

  BillingSummaryComp keepFrom(DateTime keepFrom);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingSummaryComp(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingSummaryComp(...).copyWith(id: 12, name: "My name")
  /// ```
  BillingSummaryComp call({
    String planCode,
    DateTime endsAt,
    BillingSummaryCompFromEnum from,
    DateTime keepFrom,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBillingSummaryComp.copyWith(...)` or call `instanceOfBillingSummaryComp.copyWith.fieldName(value)` for a single field.
class _$BillingSummaryCompCWProxyImpl implements _$BillingSummaryCompCWProxy {
  const _$BillingSummaryCompCWProxyImpl(this._value);

  final BillingSummaryComp _value;

  @override
  BillingSummaryComp planCode(String planCode) => call(planCode: planCode);

  @override
  BillingSummaryComp endsAt(DateTime endsAt) => call(endsAt: endsAt);

  @override
  BillingSummaryComp from(BillingSummaryCompFromEnum from) => call(from: from);

  @override
  BillingSummaryComp keepFrom(DateTime keepFrom) => call(keepFrom: keepFrom);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingSummaryComp(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingSummaryComp(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BillingSummaryComp call({
    Object? planCode = const $CopyWithPlaceholder(),
    Object? endsAt = const $CopyWithPlaceholder(),
    Object? from = const $CopyWithPlaceholder(),
    Object? keepFrom = const $CopyWithPlaceholder(),
  }) {
    return BillingSummaryComp(
      planCode: planCode == const $CopyWithPlaceholder() || planCode == null
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String,
      endsAt: endsAt == const $CopyWithPlaceholder() || endsAt == null
          ? _value.endsAt
          // ignore: cast_nullable_to_non_nullable
          : endsAt as DateTime,
      from: from == const $CopyWithPlaceholder() || from == null
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as BillingSummaryCompFromEnum,
      keepFrom: keepFrom == const $CopyWithPlaceholder() || keepFrom == null
          ? _value.keepFrom
          // ignore: cast_nullable_to_non_nullable
          : keepFrom as DateTime,
    );
  }
}

extension $BillingSummaryCompCopyWith on BillingSummaryComp {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBillingSummaryComp.copyWith(...)` or `instanceOfBillingSummaryComp.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BillingSummaryCompCWProxy get copyWith =>
      _$BillingSummaryCompCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillingSummaryComp _$BillingSummaryCompFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'BillingSummaryComp',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['plan_code', 'ends_at', 'from', 'keep_from'],
        );
        final val = BillingSummaryComp(
          planCode: $checkedConvert('plan_code', (v) => v as String),
          endsAt: $checkedConvert(
            'ends_at',
            (v) => DateTime.parse(v as String),
          ),
          from: $checkedConvert(
            'from',
            (v) => $enumDecode(_$BillingSummaryCompFromEnumEnumMap, v),
          ),
          keepFrom: $checkedConvert(
            'keep_from',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'planCode': 'plan_code',
        'endsAt': 'ends_at',
        'keepFrom': 'keep_from',
      },
    );

Map<String, dynamic> _$BillingSummaryCompToJson(BillingSummaryComp instance) =>
    <String, dynamic>{
      'plan_code': instance.planCode,
      'ends_at': instance.endsAt.toIso8601String(),
      'from': _$BillingSummaryCompFromEnumEnumMap[instance.from]!,
      'keep_from': instance.keepFrom.toIso8601String(),
    };

const _$BillingSummaryCompFromEnumEnumMap = {
  BillingSummaryCompFromEnum.grant: 'grant',
  BillingSummaryCompFromEnum.code: 'code',
};
