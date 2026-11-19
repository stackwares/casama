// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apple_sign_in_token_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppleSignInTokenRequestCWProxy {
  AppleSignInTokenRequest authorizationCode(String? authorizationCode);

  AppleSignInTokenRequest refreshToken(String? refreshToken);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppleSignInTokenRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppleSignInTokenRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AppleSignInTokenRequest call({
    String? authorizationCode,
    String? refreshToken,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAppleSignInTokenRequest.copyWith(...)` or call `instanceOfAppleSignInTokenRequest.copyWith.fieldName(value)` for a single field.
class _$AppleSignInTokenRequestCWProxyImpl
    implements _$AppleSignInTokenRequestCWProxy {
  const _$AppleSignInTokenRequestCWProxyImpl(this._value);

  final AppleSignInTokenRequest _value;

  @override
  AppleSignInTokenRequest authorizationCode(String? authorizationCode) =>
      call(authorizationCode: authorizationCode);

  @override
  AppleSignInTokenRequest refreshToken(String? refreshToken) =>
      call(refreshToken: refreshToken);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppleSignInTokenRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppleSignInTokenRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AppleSignInTokenRequest call({
    Object? authorizationCode = const $CopyWithPlaceholder(),
    Object? refreshToken = const $CopyWithPlaceholder(),
  }) {
    return AppleSignInTokenRequest(
      authorizationCode: authorizationCode == const $CopyWithPlaceholder()
          ? _value.authorizationCode
          // ignore: cast_nullable_to_non_nullable
          : authorizationCode as String?,
      refreshToken: refreshToken == const $CopyWithPlaceholder()
          ? _value.refreshToken
          // ignore: cast_nullable_to_non_nullable
          : refreshToken as String?,
    );
  }
}

extension $AppleSignInTokenRequestCopyWith on AppleSignInTokenRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAppleSignInTokenRequest.copyWith(...)` or `instanceOfAppleSignInTokenRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppleSignInTokenRequestCWProxy get copyWith =>
      _$AppleSignInTokenRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppleSignInTokenRequest _$AppleSignInTokenRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AppleSignInTokenRequest',
  json,
  ($checkedConvert) {
    final val = AppleSignInTokenRequest(
      authorizationCode: $checkedConvert(
        'authorization_code',
        (v) => v as String?,
      ),
      refreshToken: $checkedConvert('refresh_token', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'authorizationCode': 'authorization_code',
    'refreshToken': 'refresh_token',
  },
);

Map<String, dynamic> _$AppleSignInTokenRequestToJson(
  AppleSignInTokenRequest instance,
) => <String, dynamic>{
  'authorization_code': ?instance.authorizationCode,
  'refresh_token': ?instance.refreshToken,
};
