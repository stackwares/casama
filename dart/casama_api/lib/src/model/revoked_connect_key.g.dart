// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revoked_connect_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RevokedConnectKeyCWProxy {
  RevokedConnectKey revoked(String revoked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RevokedConnectKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevokedConnectKey(...).copyWith(id: 12, name: "My name")
  /// ```
  RevokedConnectKey call({String revoked});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRevokedConnectKey.copyWith(...)` or call `instanceOfRevokedConnectKey.copyWith.fieldName(value)` for a single field.
class _$RevokedConnectKeyCWProxyImpl implements _$RevokedConnectKeyCWProxy {
  const _$RevokedConnectKeyCWProxyImpl(this._value);

  final RevokedConnectKey _value;

  @override
  RevokedConnectKey revoked(String revoked) => call(revoked: revoked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RevokedConnectKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevokedConnectKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RevokedConnectKey call({Object? revoked = const $CopyWithPlaceholder()}) {
    return RevokedConnectKey(
      revoked: revoked == const $CopyWithPlaceholder() || revoked == null
          ? _value.revoked
          // ignore: cast_nullable_to_non_nullable
          : revoked as String,
    );
  }
}

extension $RevokedConnectKeyCopyWith on RevokedConnectKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRevokedConnectKey.copyWith(...)` or `instanceOfRevokedConnectKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RevokedConnectKeyCWProxy get copyWith =>
      _$RevokedConnectKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevokedConnectKey _$RevokedConnectKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RevokedConnectKey', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['revoked']);
      final val = RevokedConnectKey(
        revoked: $checkedConvert('revoked', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RevokedConnectKeyToJson(RevokedConnectKey instance) =>
    <String, dynamic>{'revoked': instance.revoked};
