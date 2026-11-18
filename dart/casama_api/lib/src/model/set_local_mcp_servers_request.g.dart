// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_local_mcp_servers_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetLocalMcpServersRequestCWProxy {
  SetLocalMcpServersRequest servers(List<LocalMcpServerInfo> servers);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetLocalMcpServersRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetLocalMcpServersRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetLocalMcpServersRequest call({List<LocalMcpServerInfo> servers});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetLocalMcpServersRequest.copyWith(...)` or call `instanceOfSetLocalMcpServersRequest.copyWith.fieldName(value)` for a single field.
class _$SetLocalMcpServersRequestCWProxyImpl
    implements _$SetLocalMcpServersRequestCWProxy {
  const _$SetLocalMcpServersRequestCWProxyImpl(this._value);

  final SetLocalMcpServersRequest _value;

  @override
  SetLocalMcpServersRequest servers(List<LocalMcpServerInfo> servers) =>
      call(servers: servers);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetLocalMcpServersRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetLocalMcpServersRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetLocalMcpServersRequest call({
    Object? servers = const $CopyWithPlaceholder(),
  }) {
    return SetLocalMcpServersRequest(
      servers: servers == const $CopyWithPlaceholder() || servers == null
          ? _value.servers
          // ignore: cast_nullable_to_non_nullable
          : servers as List<LocalMcpServerInfo>,
    );
  }
}

extension $SetLocalMcpServersRequestCopyWith on SetLocalMcpServersRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetLocalMcpServersRequest.copyWith(...)` or `instanceOfSetLocalMcpServersRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetLocalMcpServersRequestCWProxy get copyWith =>
      _$SetLocalMcpServersRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetLocalMcpServersRequest _$SetLocalMcpServersRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetLocalMcpServersRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['servers']);
  final val = SetLocalMcpServersRequest(
    servers: $checkedConvert(
      'servers',
      (v) => (v as List<dynamic>)
          .map((e) => LocalMcpServerInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$SetLocalMcpServersRequestToJson(
  SetLocalMcpServersRequest instance,
) => <String, dynamic>{
  'servers': instance.servers.map((e) => e.toJson()).toList(),
};
