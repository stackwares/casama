// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_plugin_server.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstalledPluginServerCWProxy {
  InstalledPluginServer key(String key);

  InstalledPluginServer type(InstalledPluginServerTypeEnum type);

  InstalledPluginServer command(String? command);

  InstalledPluginServer args(List<String> args);

  InstalledPluginServer url(String? url);

  InstalledPluginServer integrationId(String integrationId);

  InstalledPluginServer status(InstalledPluginServerStatusEnum status);

  InstalledPluginServer error(String? error);

  InstalledPluginServer tools(List<InstalledPluginServerAllOfTools> tools);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstalledPluginServer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstalledPluginServer(...).copyWith(id: 12, name: "My name")
  /// ```
  InstalledPluginServer call({
    String key,
    InstalledPluginServerTypeEnum type,
    String? command,
    List<String> args,
    String? url,
    String integrationId,
    InstalledPluginServerStatusEnum status,
    String? error,
    List<InstalledPluginServerAllOfTools> tools,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInstalledPluginServer.copyWith(...)` or call `instanceOfInstalledPluginServer.copyWith.fieldName(value)` for a single field.
class _$InstalledPluginServerCWProxyImpl
    implements _$InstalledPluginServerCWProxy {
  const _$InstalledPluginServerCWProxyImpl(this._value);

  final InstalledPluginServer _value;

  @override
  InstalledPluginServer key(String key) => call(key: key);

  @override
  InstalledPluginServer type(InstalledPluginServerTypeEnum type) =>
      call(type: type);

  @override
  InstalledPluginServer command(String? command) => call(command: command);

  @override
  InstalledPluginServer args(List<String> args) => call(args: args);

  @override
  InstalledPluginServer url(String? url) => call(url: url);

  @override
  InstalledPluginServer integrationId(String integrationId) =>
      call(integrationId: integrationId);

  @override
  InstalledPluginServer status(InstalledPluginServerStatusEnum status) =>
      call(status: status);

  @override
  InstalledPluginServer error(String? error) => call(error: error);

  @override
  InstalledPluginServer tools(List<InstalledPluginServerAllOfTools> tools) =>
      call(tools: tools);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstalledPluginServer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstalledPluginServer(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InstalledPluginServer call({
    Object? key = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? command = const $CopyWithPlaceholder(),
    Object? args = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? integrationId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? tools = const $CopyWithPlaceholder(),
  }) {
    return InstalledPluginServer(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as InstalledPluginServerTypeEnum,
      command: command == const $CopyWithPlaceholder()
          ? _value.command
          // ignore: cast_nullable_to_non_nullable
          : command as String?,
      args: args == const $CopyWithPlaceholder() || args == null
          ? _value.args
          // ignore: cast_nullable_to_non_nullable
          : args as List<String>,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      integrationId:
          integrationId == const $CopyWithPlaceholder() || integrationId == null
          ? _value.integrationId
          // ignore: cast_nullable_to_non_nullable
          : integrationId as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as InstalledPluginServerStatusEnum,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      tools: tools == const $CopyWithPlaceholder() || tools == null
          ? _value.tools
          // ignore: cast_nullable_to_non_nullable
          : tools as List<InstalledPluginServerAllOfTools>,
    );
  }
}

extension $InstalledPluginServerCopyWith on InstalledPluginServer {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInstalledPluginServer.copyWith(...)` or `instanceOfInstalledPluginServer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstalledPluginServerCWProxy get copyWith =>
      _$InstalledPluginServerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstalledPluginServer _$InstalledPluginServerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('InstalledPluginServer', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'key',
      'type',
      'command',
      'args',
      'url',
      'integration_id',
      'status',
      'error',
      'tools',
    ],
  );
  final val = InstalledPluginServer(
    key: $checkedConvert('key', (v) => v as String),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$InstalledPluginServerTypeEnumEnumMap, v),
    ),
    command: $checkedConvert('command', (v) => v as String?),
    args: $checkedConvert(
      'args',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    url: $checkedConvert('url', (v) => v as String?),
    integrationId: $checkedConvert('integration_id', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$InstalledPluginServerStatusEnumEnumMap, v),
    ),
    error: $checkedConvert('error', (v) => v as String?),
    tools: $checkedConvert(
      'tools',
      (v) => (v as List<dynamic>)
          .map(
            (e) => InstalledPluginServerAllOfTools.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'integrationId': 'integration_id'});

Map<String, dynamic> _$InstalledPluginServerToJson(
  InstalledPluginServer instance,
) => <String, dynamic>{
  'key': instance.key,
  'type': _$InstalledPluginServerTypeEnumEnumMap[instance.type]!,
  'command': instance.command,
  'args': instance.args,
  'url': instance.url,
  'integration_id': instance.integrationId,
  'status': _$InstalledPluginServerStatusEnumEnumMap[instance.status]!,
  'error': instance.error,
  'tools': instance.tools.map((e) => e.toJson()).toList(),
};

const _$InstalledPluginServerTypeEnumEnumMap = {
  InstalledPluginServerTypeEnum.stdio: 'stdio',
  InstalledPluginServerTypeEnum.streamableHttp: 'streamable-http',
  InstalledPluginServerTypeEnum.sse: 'sse',
};

const _$InstalledPluginServerStatusEnumEnumMap = {
  InstalledPluginServerStatusEnum.pending: 'pending',
  InstalledPluginServerStatusEnum.ok: 'ok',
  InstalledPluginServerStatusEnum.error: 'error',
};
