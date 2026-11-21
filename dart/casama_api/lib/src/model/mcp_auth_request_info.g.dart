// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_auth_request_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpAuthRequestInfoCWProxy {
  McpAuthRequestInfo id(String id);

  McpAuthRequestInfo clientName(String clientName);

  McpAuthRequestInfo redirectHost(String redirectHost);

  McpAuthRequestInfo knownApp(bool knownApp);

  McpAuthRequestInfo expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpAuthRequestInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpAuthRequestInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  McpAuthRequestInfo call({
    String id,
    String clientName,
    String redirectHost,
    bool knownApp,
    DateTime expiresAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpAuthRequestInfo.copyWith(...)` or call `instanceOfMcpAuthRequestInfo.copyWith.fieldName(value)` for a single field.
class _$McpAuthRequestInfoCWProxyImpl implements _$McpAuthRequestInfoCWProxy {
  const _$McpAuthRequestInfoCWProxyImpl(this._value);

  final McpAuthRequestInfo _value;

  @override
  McpAuthRequestInfo id(String id) => call(id: id);

  @override
  McpAuthRequestInfo clientName(String clientName) =>
      call(clientName: clientName);

  @override
  McpAuthRequestInfo redirectHost(String redirectHost) =>
      call(redirectHost: redirectHost);

  @override
  McpAuthRequestInfo knownApp(bool knownApp) => call(knownApp: knownApp);

  @override
  McpAuthRequestInfo expiresAt(DateTime expiresAt) =>
      call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpAuthRequestInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpAuthRequestInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpAuthRequestInfo call({
    Object? id = const $CopyWithPlaceholder(),
    Object? clientName = const $CopyWithPlaceholder(),
    Object? redirectHost = const $CopyWithPlaceholder(),
    Object? knownApp = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return McpAuthRequestInfo(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      clientName:
          clientName == const $CopyWithPlaceholder() || clientName == null
          ? _value.clientName
          // ignore: cast_nullable_to_non_nullable
          : clientName as String,
      redirectHost:
          redirectHost == const $CopyWithPlaceholder() || redirectHost == null
          ? _value.redirectHost
          // ignore: cast_nullable_to_non_nullable
          : redirectHost as String,
      knownApp: knownApp == const $CopyWithPlaceholder() || knownApp == null
          ? _value.knownApp
          // ignore: cast_nullable_to_non_nullable
          : knownApp as bool,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $McpAuthRequestInfoCopyWith on McpAuthRequestInfo {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpAuthRequestInfo.copyWith(...)` or `instanceOfMcpAuthRequestInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpAuthRequestInfoCWProxy get copyWith =>
      _$McpAuthRequestInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpAuthRequestInfo _$McpAuthRequestInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'McpAuthRequestInfo',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'client_name',
            'redirect_host',
            'known_app',
            'expires_at',
          ],
        );
        final val = McpAuthRequestInfo(
          id: $checkedConvert('id', (v) => v as String),
          clientName: $checkedConvert('client_name', (v) => v as String),
          redirectHost: $checkedConvert('redirect_host', (v) => v as String),
          knownApp: $checkedConvert('known_app', (v) => v as bool),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'clientName': 'client_name',
        'redirectHost': 'redirect_host',
        'knownApp': 'known_app',
        'expiresAt': 'expires_at',
      },
    );

Map<String, dynamic> _$McpAuthRequestInfoToJson(McpAuthRequestInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'client_name': instance.clientName,
      'redirect_host': instance.redirectHost,
      'known_app': instance.knownApp,
      'expires_at': instance.expiresAt.toIso8601String(),
    };
