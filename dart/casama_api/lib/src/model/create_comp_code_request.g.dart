// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_comp_code_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateCompCodeRequestCWProxy {
  CreateCompCodeRequest planCode(String planCode);

  CreateCompCodeRequest months(int months);

  CreateCompCodeRequest maxRedemptions(int? maxRedemptions);

  CreateCompCodeRequest redeemBy(DateTime? redeemBy);

  CreateCompCodeRequest note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateCompCodeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateCompCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateCompCodeRequest call({
    String planCode,
    int months,
    int? maxRedemptions,
    DateTime? redeemBy,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateCompCodeRequest.copyWith(...)` or call `instanceOfCreateCompCodeRequest.copyWith.fieldName(value)` for a single field.
class _$CreateCompCodeRequestCWProxyImpl
    implements _$CreateCompCodeRequestCWProxy {
  const _$CreateCompCodeRequestCWProxyImpl(this._value);

  final CreateCompCodeRequest _value;

  @override
  CreateCompCodeRequest planCode(String planCode) => call(planCode: planCode);

  @override
  CreateCompCodeRequest months(int months) => call(months: months);

  @override
  CreateCompCodeRequest maxRedemptions(int? maxRedemptions) =>
      call(maxRedemptions: maxRedemptions);

  @override
  CreateCompCodeRequest redeemBy(DateTime? redeemBy) =>
      call(redeemBy: redeemBy);

  @override
  CreateCompCodeRequest note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateCompCodeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateCompCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateCompCodeRequest call({
    Object? planCode = const $CopyWithPlaceholder(),
    Object? months = const $CopyWithPlaceholder(),
    Object? maxRedemptions = const $CopyWithPlaceholder(),
    Object? redeemBy = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return CreateCompCodeRequest(
      planCode: planCode == const $CopyWithPlaceholder() || planCode == null
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String,
      months: months == const $CopyWithPlaceholder() || months == null
          ? _value.months
          // ignore: cast_nullable_to_non_nullable
          : months as int,
      maxRedemptions: maxRedemptions == const $CopyWithPlaceholder()
          ? _value.maxRedemptions
          // ignore: cast_nullable_to_non_nullable
          : maxRedemptions as int?,
      redeemBy: redeemBy == const $CopyWithPlaceholder()
          ? _value.redeemBy
          // ignore: cast_nullable_to_non_nullable
          : redeemBy as DateTime?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $CreateCompCodeRequestCopyWith on CreateCompCodeRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateCompCodeRequest.copyWith(...)` or `instanceOfCreateCompCodeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateCompCodeRequestCWProxy get copyWith =>
      _$CreateCompCodeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCompCodeRequest _$CreateCompCodeRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateCompCodeRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['plan_code', 'months']);
    final val = CreateCompCodeRequest(
      planCode: $checkedConvert('plan_code', (v) => v as String),
      months: $checkedConvert('months', (v) => (v as num).toInt()),
      maxRedemptions: $checkedConvert(
        'max_redemptions',
        (v) => (v as num?)?.toInt() ?? 1,
      ),
      redeemBy: $checkedConvert(
        'redeem_by',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      note: $checkedConvert('note', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'planCode': 'plan_code',
    'maxRedemptions': 'max_redemptions',
    'redeemBy': 'redeem_by',
  },
);

Map<String, dynamic> _$CreateCompCodeRequestToJson(
  CreateCompCodeRequest instance,
) => <String, dynamic>{
  'plan_code': instance.planCode,
  'months': instance.months,
  'max_redemptions': ?instance.maxRedemptions,
  'redeem_by': ?instance.redeemBy?.toIso8601String(),
  'note': ?instance.note,
};
