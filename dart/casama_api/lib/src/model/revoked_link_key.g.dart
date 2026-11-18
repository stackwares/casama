// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revoked_link_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RevokedLinkKeyCWProxy {
  RevokedLinkKey revoked(String revoked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RevokedLinkKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevokedLinkKey(...).copyWith(id: 12, name: "My name")
  /// ```
  RevokedLinkKey call({String revoked});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRevokedLinkKey.copyWith(...)` or call `instanceOfRevokedLinkKey.copyWith.fieldName(value)` for a single field.
class _$RevokedLinkKeyCWProxyImpl implements _$RevokedLinkKeyCWProxy {
  const _$RevokedLinkKeyCWProxyImpl(this._value);

  final RevokedLinkKey _value;

  @override
  RevokedLinkKey revoked(String revoked) => call(revoked: revoked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RevokedLinkKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevokedLinkKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RevokedLinkKey call({Object? revoked = const $CopyWithPlaceholder()}) {
    return RevokedLinkKey(
      revoked: revoked == const $CopyWithPlaceholder() || revoked == null
          ? _value.revoked
          // ignore: cast_nullable_to_non_nullable
          : revoked as String,
    );
  }
}

extension $RevokedLinkKeyCopyWith on RevokedLinkKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRevokedLinkKey.copyWith(...)` or `instanceOfRevokedLinkKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RevokedLinkKeyCWProxy get copyWith => _$RevokedLinkKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevokedLinkKey _$RevokedLinkKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RevokedLinkKey', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['revoked']);
      final val = RevokedLinkKey(
        revoked: $checkedConvert('revoked', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RevokedLinkKeyToJson(RevokedLinkKey instance) =>
    <String, dynamic>{'revoked': instance.revoked};
