// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redeem_referral_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RedeemReferralRequestCWProxy {
  RedeemReferralRequest code(String code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemReferralRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemReferralRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  RedeemReferralRequest call({String code});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRedeemReferralRequest.copyWith(...)` or call `instanceOfRedeemReferralRequest.copyWith.fieldName(value)` for a single field.
class _$RedeemReferralRequestCWProxyImpl
    implements _$RedeemReferralRequestCWProxy {
  const _$RedeemReferralRequestCWProxyImpl(this._value);

  final RedeemReferralRequest _value;

  @override
  RedeemReferralRequest code(String code) => call(code: code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemReferralRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemReferralRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RedeemReferralRequest call({Object? code = const $CopyWithPlaceholder()}) {
    return RedeemReferralRequest(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
    );
  }
}

extension $RedeemReferralRequestCopyWith on RedeemReferralRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRedeemReferralRequest.copyWith(...)` or `instanceOfRedeemReferralRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RedeemReferralRequestCWProxy get copyWith =>
      _$RedeemReferralRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedeemReferralRequest _$RedeemReferralRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RedeemReferralRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['code']);
  final val = RedeemReferralRequest(
    code: $checkedConvert('code', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$RedeemReferralRequestToJson(
  RedeemReferralRequest instance,
) => <String, dynamic>{'code': instance.code};
