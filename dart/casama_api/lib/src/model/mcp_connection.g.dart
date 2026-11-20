// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_connection.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpConnectionCWProxy {
  McpConnection clientId(String clientId);

  McpConnection clientName(String clientName);

  McpConnection userId(String userId);

  McpConnection userName(String userName);

  McpConnection mine(bool mine);

  McpConnection connectedAt(DateTime connectedAt);

  McpConnection lastUsedAt(DateTime? lastUsedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpConnection(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpConnection(...).copyWith(id: 12, name: "My name")
  /// ```
  McpConnection call({
    String clientId,
    String clientName,
    String userId,
    String userName,
    bool mine,
    DateTime connectedAt,
    DateTime? lastUsedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpConnection.copyWith(...)` or call `instanceOfMcpConnection.copyWith.fieldName(value)` for a single field.
class _$McpConnectionCWProxyImpl implements _$McpConnectionCWProxy {
  const _$McpConnectionCWProxyImpl(this._value);

  final McpConnection _value;

  @override
  McpConnection clientId(String clientId) => call(clientId: clientId);

  @override
  McpConnection clientName(String clientName) => call(clientName: clientName);

  @override
  McpConnection userId(String userId) => call(userId: userId);

  @override
  McpConnection userName(String userName) => call(userName: userName);

  @override
  McpConnection mine(bool mine) => call(mine: mine);

  @override
  McpConnection connectedAt(DateTime connectedAt) =>
      call(connectedAt: connectedAt);

  @override
  McpConnection lastUsedAt(DateTime? lastUsedAt) =>
      call(lastUsedAt: lastUsedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpConnection(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpConnection(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpConnection call({
    Object? clientId = const $CopyWithPlaceholder(),
    Object? clientName = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
    Object? userName = const $CopyWithPlaceholder(),
    Object? mine = const $CopyWithPlaceholder(),
    Object? connectedAt = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
  }) {
    return McpConnection(
      clientId: clientId == const $CopyWithPlaceholder() || clientId == null
          ? _value.clientId
          // ignore: cast_nullable_to_non_nullable
          : clientId as String,
      clientName:
          clientName == const $CopyWithPlaceholder() || clientName == null
          ? _value.clientName
          // ignore: cast_nullable_to_non_nullable
          : clientName as String,
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      userName: userName == const $CopyWithPlaceholder() || userName == null
          ? _value.userName
          // ignore: cast_nullable_to_non_nullable
          : userName as String,
      mine: mine == const $CopyWithPlaceholder() || mine == null
          ? _value.mine
          // ignore: cast_nullable_to_non_nullable
          : mine as bool,
      connectedAt:
          connectedAt == const $CopyWithPlaceholder() || connectedAt == null
          ? _value.connectedAt
          // ignore: cast_nullable_to_non_nullable
          : connectedAt as DateTime,
      lastUsedAt: lastUsedAt == const $CopyWithPlaceholder()
          ? _value.lastUsedAt
          // ignore: cast_nullable_to_non_nullable
          : lastUsedAt as DateTime?,
    );
  }
}

extension $McpConnectionCopyWith on McpConnection {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpConnection.copyWith(...)` or `instanceOfMcpConnection.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpConnectionCWProxy get copyWith => _$McpConnectionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpConnection _$McpConnectionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'McpConnection',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'client_id',
            'client_name',
            'user_id',
            'user_name',
            'mine',
            'connected_at',
            'last_used_at',
          ],
        );
        final val = McpConnection(
          clientId: $checkedConvert('client_id', (v) => v as String),
          clientName: $checkedConvert('client_name', (v) => v as String),
          userId: $checkedConvert('user_id', (v) => v as String),
          userName: $checkedConvert('user_name', (v) => v as String),
          mine: $checkedConvert('mine', (v) => v as bool),
          connectedAt: $checkedConvert(
            'connected_at',
            (v) => DateTime.parse(v as String),
          ),
          lastUsedAt: $checkedConvert(
            'last_used_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'clientId': 'client_id',
        'clientName': 'client_name',
        'userId': 'user_id',
        'userName': 'user_name',
        'connectedAt': 'connected_at',
        'lastUsedAt': 'last_used_at',
      },
    );

Map<String, dynamic> _$McpConnectionToJson(McpConnection instance) =>
    <String, dynamic>{
      'client_id': instance.clientId,
      'client_name': instance.clientName,
      'user_id': instance.userId,
      'user_name': instance.userName,
      'mine': instance.mine,
      'connected_at': instance.connectedAt.toIso8601String(),
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
    };
