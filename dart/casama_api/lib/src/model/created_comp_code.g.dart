// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'created_comp_code.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatedCompCodeCWProxy {
  CreatedCompCode id(String id);

  CreatedCompCode hint(String hint);

  CreatedCompCode planCode(String planCode);

  CreatedCompCode months(int months);

  CreatedCompCode maxRedemptions(int maxRedemptions);

  CreatedCompCode redeemedCount(int redeemedCount);

  CreatedCompCode redeemBy(DateTime? redeemBy);

  CreatedCompCode note(String? note);

  CreatedCompCode disabled(bool disabled);

  CreatedCompCode createdAt(DateTime createdAt);

  CreatedCompCode code(String code);

  CreatedCompCode link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedCompCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedCompCode(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatedCompCode call({
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
    String code,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreatedCompCode.copyWith(...)` or call `instanceOfCreatedCompCode.copyWith.fieldName(value)` for a single field.
class _$CreatedCompCodeCWProxyImpl implements _$CreatedCompCodeCWProxy {
  const _$CreatedCompCodeCWProxyImpl(this._value);

  final CreatedCompCode _value;

  @override
  CreatedCompCode id(String id) => call(id: id);

  @override
  CreatedCompCode hint(String hint) => call(hint: hint);

  @override
  CreatedCompCode planCode(String planCode) => call(planCode: planCode);

  @override
  CreatedCompCode months(int months) => call(months: months);

  @override
  CreatedCompCode maxRedemptions(int maxRedemptions) =>
      call(maxRedemptions: maxRedemptions);

  @override
  CreatedCompCode redeemedCount(int redeemedCount) =>
      call(redeemedCount: redeemedCount);

  @override
  CreatedCompCode redeemBy(DateTime? redeemBy) => call(redeemBy: redeemBy);

  @override
  CreatedCompCode note(String? note) => call(note: note);

  @override
  CreatedCompCode disabled(bool disabled) => call(disabled: disabled);

  @override
  CreatedCompCode createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  CreatedCompCode code(String code) => call(code: code);

  @override
  CreatedCompCode link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedCompCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedCompCode(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatedCompCode call({
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
    Object? code = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return CreatedCompCode(
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
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $CreatedCompCodeCopyWith on CreatedCompCode {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatedCompCode.copyWith(...)` or `instanceOfCreatedCompCode.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatedCompCodeCWProxy get copyWith => _$CreatedCompCodeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatedCompCode _$CreatedCompCodeFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CreatedCompCode',
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
            'code',
            'link',
          ],
        );
        final val = CreatedCompCode(
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
          code: $checkedConvert('code', (v) => v as String),
          link: $checkedConvert('link', (v) => v as String),
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

Map<String, dynamic> _$CreatedCompCodeToJson(CreatedCompCode instance) =>
    <String, dynamic>{
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
      'code': instance.code,
      'link': instance.link,
    };
