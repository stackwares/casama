// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_comp_code_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateCompCodeRequestCWProxy {
  UpdateCompCodeRequest disabled(bool? disabled);

  UpdateCompCodeRequest redeemBy(DateTime? redeemBy);

  UpdateCompCodeRequest maxRedemptions(int? maxRedemptions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCompCodeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCompCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateCompCodeRequest call({
    bool? disabled,
    DateTime? redeemBy,
    int? maxRedemptions,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateCompCodeRequest.copyWith(...)` or call `instanceOfUpdateCompCodeRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateCompCodeRequestCWProxyImpl
    implements _$UpdateCompCodeRequestCWProxy {
  const _$UpdateCompCodeRequestCWProxyImpl(this._value);

  final UpdateCompCodeRequest _value;

  @override
  UpdateCompCodeRequest disabled(bool? disabled) => call(disabled: disabled);

  @override
  UpdateCompCodeRequest redeemBy(DateTime? redeemBy) =>
      call(redeemBy: redeemBy);

  @override
  UpdateCompCodeRequest maxRedemptions(int? maxRedemptions) =>
      call(maxRedemptions: maxRedemptions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCompCodeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCompCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateCompCodeRequest call({
    Object? disabled = const $CopyWithPlaceholder(),
    Object? redeemBy = const $CopyWithPlaceholder(),
    Object? maxRedemptions = const $CopyWithPlaceholder(),
  }) {
    return UpdateCompCodeRequest(
      disabled: disabled == const $CopyWithPlaceholder()
          ? _value.disabled
          // ignore: cast_nullable_to_non_nullable
          : disabled as bool?,
      redeemBy: redeemBy == const $CopyWithPlaceholder()
          ? _value.redeemBy
          // ignore: cast_nullable_to_non_nullable
          : redeemBy as DateTime?,
      maxRedemptions: maxRedemptions == const $CopyWithPlaceholder()
          ? _value.maxRedemptions
          // ignore: cast_nullable_to_non_nullable
          : maxRedemptions as int?,
    );
  }
}

extension $UpdateCompCodeRequestCopyWith on UpdateCompCodeRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateCompCodeRequest.copyWith(...)` or `instanceOfUpdateCompCodeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateCompCodeRequestCWProxy get copyWith =>
      _$UpdateCompCodeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateCompCodeRequest _$UpdateCompCodeRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateCompCodeRequest',
  json,
  ($checkedConvert) {
    final val = UpdateCompCodeRequest(
      disabled: $checkedConvert('disabled', (v) => v as bool?),
      redeemBy: $checkedConvert(
        'redeem_by',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      maxRedemptions: $checkedConvert(
        'max_redemptions',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'redeemBy': 'redeem_by',
    'maxRedemptions': 'max_redemptions',
  },
);

Map<String, dynamic> _$UpdateCompCodeRequestToJson(
  UpdateCompCodeRequest instance,
) => <String, dynamic>{
  'disabled': ?instance.disabled,
  'redeem_by': ?instance.redeemBy?.toIso8601String(),
  'max_redemptions': ?instance.maxRedemptions,
};
