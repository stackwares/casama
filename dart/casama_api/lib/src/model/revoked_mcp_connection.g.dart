// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revoked_mcp_connection.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RevokedMcpConnectionCWProxy {
  RevokedMcpConnection revoked(String revoked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RevokedMcpConnection(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevokedMcpConnection(...).copyWith(id: 12, name: "My name")
  /// ```
  RevokedMcpConnection call({String revoked});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRevokedMcpConnection.copyWith(...)` or call `instanceOfRevokedMcpConnection.copyWith.fieldName(value)` for a single field.
class _$RevokedMcpConnectionCWProxyImpl
    implements _$RevokedMcpConnectionCWProxy {
  const _$RevokedMcpConnectionCWProxyImpl(this._value);

  final RevokedMcpConnection _value;

  @override
  RevokedMcpConnection revoked(String revoked) => call(revoked: revoked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RevokedMcpConnection(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevokedMcpConnection(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RevokedMcpConnection call({Object? revoked = const $CopyWithPlaceholder()}) {
    return RevokedMcpConnection(
      revoked: revoked == const $CopyWithPlaceholder() || revoked == null
          ? _value.revoked
          // ignore: cast_nullable_to_non_nullable
          : revoked as String,
    );
  }
}

extension $RevokedMcpConnectionCopyWith on RevokedMcpConnection {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRevokedMcpConnection.copyWith(...)` or `instanceOfRevokedMcpConnection.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RevokedMcpConnectionCWProxy get copyWith =>
      _$RevokedMcpConnectionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevokedMcpConnection _$RevokedMcpConnectionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RevokedMcpConnection', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['revoked']);
  final val = RevokedMcpConnection(
    revoked: $checkedConvert('revoked', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$RevokedMcpConnectionToJson(
  RevokedMcpConnection instance,
) => <String, dynamic>{'revoked': instance.revoked};
