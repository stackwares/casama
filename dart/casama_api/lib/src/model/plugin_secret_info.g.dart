// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_secret_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginSecretInfoCWProxy {
  PluginSecretInfo name(String name);

  PluginSecretInfo description(String description);

  PluginSecretInfo server(String server);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginSecretInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginSecretInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginSecretInfo call({String name, String description, String server});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginSecretInfo.copyWith(...)` or call `instanceOfPluginSecretInfo.copyWith.fieldName(value)` for a single field.
class _$PluginSecretInfoCWProxyImpl implements _$PluginSecretInfoCWProxy {
  const _$PluginSecretInfoCWProxyImpl(this._value);

  final PluginSecretInfo _value;

  @override
  PluginSecretInfo name(String name) => call(name: name);

  @override
  PluginSecretInfo description(String description) =>
      call(description: description);

  @override
  PluginSecretInfo server(String server) => call(server: server);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginSecretInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginSecretInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginSecretInfo call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? server = const $CopyWithPlaceholder(),
  }) {
    return PluginSecretInfo(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      server: server == const $CopyWithPlaceholder() || server == null
          ? _value.server
          // ignore: cast_nullable_to_non_nullable
          : server as String,
    );
  }
}

extension $PluginSecretInfoCopyWith on PluginSecretInfo {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginSecretInfo.copyWith(...)` or `instanceOfPluginSecretInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginSecretInfoCWProxy get copyWith => _$PluginSecretInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginSecretInfo _$PluginSecretInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PluginSecretInfo', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'description', 'server']);
      final val = PluginSecretInfo(
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        server: $checkedConvert('server', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PluginSecretInfoToJson(PluginSecretInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'server': instance.server,
    };
