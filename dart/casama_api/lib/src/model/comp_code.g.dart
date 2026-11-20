// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comp_code.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CompCodeCWProxy {
  CompCode id(String id);

  CompCode hint(String hint);

  CompCode planCode(String planCode);

  CompCode months(int months);

  CompCode maxRedemptions(int maxRedemptions);

  CompCode redeemedCount(int redeemedCount);

  CompCode redeemBy(DateTime? redeemBy);

  CompCode note(String? note);

  CompCode disabled(bool disabled);

  CompCode createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CompCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CompCode(...).copyWith(id: 12, name: "My name")
  /// ```
  CompCode call({
    String id,
    String hint,
    String planCode,
    int months,
    int maxRedemptions,
    int redeemedCount,
    DateTime? redeemBy,
    String? note,
    bool disabled,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCompCode.copyWith(...)` or call `instanceOfCompCode.copyWith.fieldName(value)` for a single field.
class _$CompCodeCWProxyImpl implements _$CompCodeCWProxy {
  const _$CompCodeCWProxyImpl(this._value);

  final CompCode _value;

  @override
  CompCode id(String id) => call(id: id);

  @override
  CompCode hint(String hint) => call(hint: hint);

  @override
  CompCode planCode(String planCode) => call(planCode: planCode);

  @override
  CompCode months(int months) => call(months: months);

  @override
  CompCode maxRedemptions(int maxRedemptions) =>
      call(maxRedemptions: maxRedemptions);

  @override
  CompCode redeemedCount(int redeemedCount) =>
      call(redeemedCount: redeemedCount);

  @override
  CompCode redeemBy(DateTime? redeemBy) => call(redeemBy: redeemBy);

  @override
  CompCode note(String? note) => call(note: note);

  @override
  CompCode disabled(bool disabled) => call(disabled: disabled);

  @override
  CompCode createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CompCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CompCode(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CompCode call({
    Object? id = const $CopyWithPlaceholder(),
    Object? hint = const $CopyWithPlaceholder(),
    Object? planCode = const $CopyWithPlaceholder(),
    Object? months = const $CopyWithPlaceholder(),
    Object? maxRedemptions = const $CopyWithPlaceholder(),
    Object? redeemedCount = const $CopyWithPlaceholder(),
    Object? redeemBy = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? disabled = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return CompCode(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      hint: hint == const $CopyWithPlaceholder() || hint == null
          ? _value.hint
          // ignore: cast_nullable_to_non_nullable
          : hint as String,
      planCode: planCode == const $CopyWithPlaceholder() || planCode == null
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String,
      months: months == const $CopyWithPlaceholder() || months == null
          ? _value.months
          // ignore: cast_nullable_to_non_nullable
          : months as int,
      maxRedemptions:
          maxRedemptions == const $CopyWithPlaceholder() ||
              maxRedemptions == null
          ? _value.maxRedemptions
          // ignore: cast_nullable_to_non_nullable
          : maxRedemptions as int,
      redeemedCount:
          redeemedCount == const $CopyWithPlaceholder() || redeemedCount == null
          ? _value.redeemedCount
          // ignore: cast_nullable_to_non_nullable
          : redeemedCount as int,
      redeemBy: redeemBy == const $CopyWithPlaceholder()
          ? _value.redeemBy
          // ignore: cast_nullable_to_non_nullable
          : redeemBy as DateTime?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      disabled: disabled == const $CopyWithPlaceholder() || disabled == null
          ? _value.disabled
          // ignore: cast_nullable_to_non_nullable
          : disabled as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $CompCodeCopyWith on CompCode {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCompCode.copyWith(...)` or `instanceOfCompCode.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CompCodeCWProxy get copyWith => _$CompCodeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompCode _$CompCodeFromJson(Map<String, dynamic> json) => $checkedCreate(
  'CompCode',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'hint',
        'plan_code',
        'months',
        'max_redemptions',
        'redeemed_count',
        'redeem_by',
        'note',
        'disabled',
        'created_at',
      ],
    );
    final val = CompCode(
      id: $checkedConvert('id', (v) => v as String),
      hint: $checkedConvert('hint', (v) => v as String),
      planCode: $checkedConvert('plan_code', (v) => v as String),
      months: $checkedConvert('months', (v) => (v as num).toInt()),
      maxRedemptions: $checkedConvert(
        'max_redemptions',
        (v) => (v as num).toInt(),
      ),
      redeemedCount: $checkedConvert(
        'redeemed_count',
        (v) => (v as num).toInt(),
      ),
      redeemBy: $checkedConvert(
        'redeem_by',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      note: $checkedConvert('note', (v) => v as String?),
      disabled: $checkedConvert('disabled', (v) => v as bool),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'planCode': 'plan_code',
    'maxRedemptions': 'max_redemptions',
    'redeemedCount': 'redeemed_count',
    'redeemBy': 'redeem_by',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$CompCodeToJson(CompCode instance) => <String, dynamic>{
  'id': instance.id,
  'hint': instance.hint,
  'plan_code': instance.planCode,
  'months': instance.months,
  'max_redemptions': instance.maxRedemptions,
  'redeemed_count': instance.redeemedCount,
  'redeem_by': instance.redeemBy?.toIso8601String(),
  'note': instance.note,
  'disabled': instance.disabled,
  'created_at': instance.createdAt.toIso8601String(),
};
