// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redeemed_sign_in_code.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RedeemedSignInCodeCWProxy {
  RedeemedSignInCode tokenHash(String tokenHash);

  RedeemedSignInCode email(String email);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemedSignInCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemedSignInCode(...).copyWith(id: 12, name: "My name")
  /// ```
  RedeemedSignInCode call({String tokenHash, String email});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRedeemedSignInCode.copyWith(...)` or call `instanceOfRedeemedSignInCode.copyWith.fieldName(value)` for a single field.
class _$RedeemedSignInCodeCWProxyImpl implements _$RedeemedSignInCodeCWProxy {
  const _$RedeemedSignInCodeCWProxyImpl(this._value);

  final RedeemedSignInCode _value;

  @override
  RedeemedSignInCode tokenHash(String tokenHash) => call(tokenHash: tokenHash);

  @override
  RedeemedSignInCode email(String email) => call(email: email);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemedSignInCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemedSignInCode(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RedeemedSignInCode call({
    Object? tokenHash = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
  }) {
    return RedeemedSignInCode(
      tokenHash: tokenHash == const $CopyWithPlaceholder() || tokenHash == null
          ? _value.tokenHash
          // ignore: cast_nullable_to_non_nullable
          : tokenHash as String,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
    );
  }
}

extension $RedeemedSignInCodeCopyWith on RedeemedSignInCode {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRedeemedSignInCode.copyWith(...)` or `instanceOfRedeemedSignInCode.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RedeemedSignInCodeCWProxy get copyWith =>
      _$RedeemedSignInCodeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedeemedSignInCode _$RedeemedSignInCodeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RedeemedSignInCode', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['token_hash', 'email']);
      final val = RedeemedSignInCode(
        tokenHash: $checkedConvert('token_hash', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'tokenHash': 'token_hash'});

Map<String, dynamic> _$RedeemedSignInCodeToJson(RedeemedSignInCode instance) =>
    <String, dynamic>{
      'token_hash': instance.tokenHash,
      'email': instance.email,
    };
