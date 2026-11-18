// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_code.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SignInCodeCWProxy {
  SignInCode code(String code);

  SignInCode expiresAt(DateTime expiresAt);

  SignInCode serverUrl(String serverUrl);

  SignInCode reachable(bool reachable);

  SignInCode pairUrl(String pairUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SignInCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SignInCode(...).copyWith(id: 12, name: "My name")
  /// ```
  SignInCode call({
    String code,
    DateTime expiresAt,
    String serverUrl,
    bool reachable,
    String pairUrl,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSignInCode.copyWith(...)` or call `instanceOfSignInCode.copyWith.fieldName(value)` for a single field.
class _$SignInCodeCWProxyImpl implements _$SignInCodeCWProxy {
  const _$SignInCodeCWProxyImpl(this._value);

  final SignInCode _value;

  @override
  SignInCode code(String code) => call(code: code);

  @override
  SignInCode expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  SignInCode serverUrl(String serverUrl) => call(serverUrl: serverUrl);

  @override
  SignInCode reachable(bool reachable) => call(reachable: reachable);

  @override
  SignInCode pairUrl(String pairUrl) => call(pairUrl: pairUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SignInCode(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SignInCode(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SignInCode call({
    Object? code = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? serverUrl = const $CopyWithPlaceholder(),
    Object? reachable = const $CopyWithPlaceholder(),
    Object? pairUrl = const $CopyWithPlaceholder(),
  }) {
    return SignInCode(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      serverUrl: serverUrl == const $CopyWithPlaceholder() || serverUrl == null
          ? _value.serverUrl
          // ignore: cast_nullable_to_non_nullable
          : serverUrl as String,
      reachable: reachable == const $CopyWithPlaceholder() || reachable == null
          ? _value.reachable
          // ignore: cast_nullable_to_non_nullable
          : reachable as bool,
      pairUrl: pairUrl == const $CopyWithPlaceholder() || pairUrl == null
          ? _value.pairUrl
          // ignore: cast_nullable_to_non_nullable
          : pairUrl as String,
    );
  }
}

extension $SignInCodeCopyWith on SignInCode {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSignInCode.copyWith(...)` or `instanceOfSignInCode.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SignInCodeCWProxy get copyWith => _$SignInCodeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignInCode _$SignInCodeFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SignInCode',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'code',
        'expires_at',
        'server_url',
        'reachable',
        'pair_url',
      ],
    );
    final val = SignInCode(
      code: $checkedConvert('code', (v) => v as String),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      serverUrl: $checkedConvert('server_url', (v) => v as String),
      reachable: $checkedConvert('reachable', (v) => v as bool),
      pairUrl: $checkedConvert('pair_url', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'expiresAt': 'expires_at',
    'serverUrl': 'server_url',
    'pairUrl': 'pair_url',
  },
);

Map<String, dynamic> _$SignInCodeToJson(SignInCode instance) =>
    <String, dynamic>{
      'code': instance.code,
      'expires_at': instance.expiresAt.toIso8601String(),
      'server_url': instance.serverUrl,
      'reachable': instance.reachable,
      'pair_url': instance.pairUrl,
    };
