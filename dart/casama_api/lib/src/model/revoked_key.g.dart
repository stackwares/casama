// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revoked_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RevokedKeyCWProxy {
  RevokedKey revoked(String revoked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RevokedKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevokedKey(...).copyWith(id: 12, name: "My name")
  /// ```
  RevokedKey call({String revoked});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRevokedKey.copyWith(...)` or call `instanceOfRevokedKey.copyWith.fieldName(value)` for a single field.
class _$RevokedKeyCWProxyImpl implements _$RevokedKeyCWProxy {
  const _$RevokedKeyCWProxyImpl(this._value);

  final RevokedKey _value;

  @override
  RevokedKey revoked(String revoked) => call(revoked: revoked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RevokedKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevokedKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RevokedKey call({Object? revoked = const $CopyWithPlaceholder()}) {
    return RevokedKey(
      revoked: revoked == const $CopyWithPlaceholder() || revoked == null
          ? _value.revoked
          // ignore: cast_nullable_to_non_nullable
          : revoked as String,
    );
  }
}

extension $RevokedKeyCopyWith on RevokedKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRevokedKey.copyWith(...)` or `instanceOfRevokedKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RevokedKeyCWProxy get copyWith => _$RevokedKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevokedKey _$RevokedKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RevokedKey', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['revoked']);
      final val = RevokedKey(
        revoked: $checkedConvert('revoked', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RevokedKeyToJson(RevokedKey instance) =>
    <String, dynamic>{'revoked': instance.revoked};
