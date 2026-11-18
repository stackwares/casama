// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redeem_sign_in_code_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RedeemSignInCodeRequestCWProxy {
  RedeemSignInCodeRequest code(String code);

  RedeemSignInCodeRequest deviceName(String? deviceName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemSignInCodeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemSignInCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  RedeemSignInCodeRequest call({String code, String? deviceName});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRedeemSignInCodeRequest.copyWith(...)` or call `instanceOfRedeemSignInCodeRequest.copyWith.fieldName(value)` for a single field.
class _$RedeemSignInCodeRequestCWProxyImpl
    implements _$RedeemSignInCodeRequestCWProxy {
  const _$RedeemSignInCodeRequestCWProxyImpl(this._value);

  final RedeemSignInCodeRequest _value;

  @override
  RedeemSignInCodeRequest code(String code) => call(code: code);

  @override
  RedeemSignInCodeRequest deviceName(String? deviceName) =>
      call(deviceName: deviceName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemSignInCodeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemSignInCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RedeemSignInCodeRequest call({
    Object? code = const $CopyWithPlaceholder(),
    Object? deviceName = const $CopyWithPlaceholder(),
  }) {
    return RedeemSignInCodeRequest(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      deviceName: deviceName == const $CopyWithPlaceholder()
          ? _value.deviceName
          // ignore: cast_nullable_to_non_nullable
          : deviceName as String?,
    );
  }
}

extension $RedeemSignInCodeRequestCopyWith on RedeemSignInCodeRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRedeemSignInCodeRequest.copyWith(...)` or `instanceOfRedeemSignInCodeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RedeemSignInCodeRequestCWProxy get copyWith =>
      _$RedeemSignInCodeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedeemSignInCodeRequest _$RedeemSignInCodeRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RedeemSignInCodeRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['code']);
  final val = RedeemSignInCodeRequest(
    code: $checkedConvert('code', (v) => v as String),
    deviceName: $checkedConvert('device_name', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'deviceName': 'device_name'});

Map<String, dynamic> _$RedeemSignInCodeRequestToJson(
  RedeemSignInCodeRequest instance,
) => <String, dynamic>{
  'code': instance.code,
  'device_name': ?instance.deviceName,
};
