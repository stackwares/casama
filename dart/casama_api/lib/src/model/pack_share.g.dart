// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_share.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackShareCWProxy {
  PackShare id(String id);

  PackShare url(String url);

  PackShare token(String token);

  PackShare expiresAt(DateTime expiresAt);

  PackShare findings(List<PackSecretFinding> findings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackShare(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackShare(...).copyWith(id: 12, name: "My name")
  /// ```
  PackShare call({
    String id,
    String url,
    String token,
    DateTime expiresAt,
    List<PackSecretFinding> findings,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackShare.copyWith(...)` or call `instanceOfPackShare.copyWith.fieldName(value)` for a single field.
class _$PackShareCWProxyImpl implements _$PackShareCWProxy {
  const _$PackShareCWProxyImpl(this._value);

  final PackShare _value;

  @override
  PackShare id(String id) => call(id: id);

  @override
  PackShare url(String url) => call(url: url);

  @override
  PackShare token(String token) => call(token: token);

  @override
  PackShare expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  PackShare findings(List<PackSecretFinding> findings) =>
      call(findings: findings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackShare(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackShare(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackShare call({
    Object? id = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? token = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? findings = const $CopyWithPlaceholder(),
  }) {
    return PackShare(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      token: token == const $CopyWithPlaceholder() || token == null
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      findings: findings == const $CopyWithPlaceholder() || findings == null
          ? _value.findings
          // ignore: cast_nullable_to_non_nullable
          : findings as List<PackSecretFinding>,
    );
  }
}

extension $PackShareCopyWith on PackShare {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackShare.copyWith(...)` or `instanceOfPackShare.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackShareCWProxy get copyWith => _$PackShareCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackShare _$PackShareFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackShare', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'url', 'token', 'expires_at', 'findings'],
      );
      final val = PackShare(
        id: $checkedConvert('id', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String),
        token: $checkedConvert('token', (v) => v as String),
        expiresAt: $checkedConvert(
          'expires_at',
          (v) => DateTime.parse(v as String),
        ),
        findings: $checkedConvert(
          'findings',
          (v) => (v as List<dynamic>)
              .map((e) => PackSecretFinding.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'expiresAt': 'expires_at'});

Map<String, dynamic> _$PackShareToJson(PackShare instance) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'token': instance.token,
  'expires_at': instance.expiresAt.toIso8601String(),
  'findings': instance.findings.map((e) => e.toJson()).toList(),
};
