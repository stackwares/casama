// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_server_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginServerInfoCWProxy {
  PluginServerInfo key(String key);

  PluginServerInfo type(PluginServerInfoTypeEnum type);

  PluginServerInfo command(String? command);

  PluginServerInfo args(List<String> args);

  PluginServerInfo url(String? url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginServerInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginServerInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginServerInfo call({
    String key,
    PluginServerInfoTypeEnum type,
    String? command,
    List<String> args,
    String? url,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginServerInfo.copyWith(...)` or call `instanceOfPluginServerInfo.copyWith.fieldName(value)` for a single field.
class _$PluginServerInfoCWProxyImpl implements _$PluginServerInfoCWProxy {
  const _$PluginServerInfoCWProxyImpl(this._value);

  final PluginServerInfo _value;

  @override
  PluginServerInfo key(String key) => call(key: key);

  @override
  PluginServerInfo type(PluginServerInfoTypeEnum type) => call(type: type);

  @override
  PluginServerInfo command(String? command) => call(command: command);

  @override
  PluginServerInfo args(List<String> args) => call(args: args);

  @override
  PluginServerInfo url(String? url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginServerInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginServerInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginServerInfo call({
    Object? key = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? command = const $CopyWithPlaceholder(),
    Object? args = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return PluginServerInfo(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as PluginServerInfoTypeEnum,
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
    );
  }
}

extension $PluginServerInfoCopyWith on PluginServerInfo {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginServerInfo.copyWith(...)` or `instanceOfPluginServerInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginServerInfoCWProxy get copyWith => _$PluginServerInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginServerInfo _$PluginServerInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PluginServerInfo', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['key', 'type', 'command', 'args', 'url'],
      );
      final val = PluginServerInfo(
        key: $checkedConvert('key', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$PluginServerInfoTypeEnumEnumMap, v),
        ),
        command: $checkedConvert('command', (v) => v as String?),
        args: $checkedConvert(
          'args',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        url: $checkedConvert('url', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$PluginServerInfoToJson(PluginServerInfo instance) =>
    <String, dynamic>{
      'key': instance.key,
      'type': _$PluginServerInfoTypeEnumEnumMap[instance.type]!,
      'command': instance.command,
      'args': instance.args,
      'url': instance.url,
    };

const _$PluginServerInfoTypeEnumEnumMap = {
  PluginServerInfoTypeEnum.stdio: 'stdio',
  PluginServerInfoTypeEnum.streamableHttp: 'streamable-http',
  PluginServerInfoTypeEnum.sse: 'sse',
};
