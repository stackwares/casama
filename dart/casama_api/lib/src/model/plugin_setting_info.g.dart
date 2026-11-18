// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_setting_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginSettingInfoCWProxy {
  PluginSettingInfo name(String name);

  PluginSettingInfo label(String label);

  PluginSettingInfo description(String description);

  PluginSettingInfo server(String server);

  PluginSettingInfo default_(String? default_);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginSettingInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginSettingInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginSettingInfo call({
    String name,
    String label,
    String description,
    String server,
    String? default_,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginSettingInfo.copyWith(...)` or call `instanceOfPluginSettingInfo.copyWith.fieldName(value)` for a single field.
class _$PluginSettingInfoCWProxyImpl implements _$PluginSettingInfoCWProxy {
  const _$PluginSettingInfoCWProxyImpl(this._value);

  final PluginSettingInfo _value;

  @override
  PluginSettingInfo name(String name) => call(name: name);

  @override
  PluginSettingInfo label(String label) => call(label: label);

  @override
  PluginSettingInfo description(String description) =>
      call(description: description);

  @override
  PluginSettingInfo server(String server) => call(server: server);

  @override
  PluginSettingInfo default_(String? default_) => call(default_: default_);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginSettingInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginSettingInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginSettingInfo call({
    Object? name = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? server = const $CopyWithPlaceholder(),
    Object? default_ = const $CopyWithPlaceholder(),
  }) {
    return PluginSettingInfo(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      server: server == const $CopyWithPlaceholder() || server == null
          ? _value.server
          // ignore: cast_nullable_to_non_nullable
          : server as String,
      default_: default_ == const $CopyWithPlaceholder()
          ? _value.default_
          // ignore: cast_nullable_to_non_nullable
          : default_ as String?,
    );
  }
}

extension $PluginSettingInfoCopyWith on PluginSettingInfo {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginSettingInfo.copyWith(...)` or `instanceOfPluginSettingInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginSettingInfoCWProxy get copyWith =>
      _$PluginSettingInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginSettingInfo _$PluginSettingInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PluginSettingInfo', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'name',
          'label',
          'description',
          'server',
          'default',
        ],
      );
      final val = PluginSettingInfo(
        name: $checkedConvert('name', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        server: $checkedConvert('server', (v) => v as String),
        default_: $checkedConvert('default', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'default_': 'default'});

Map<String, dynamic> _$PluginSettingInfoToJson(PluginSettingInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'label': instance.label,
      'description': instance.description,
      'server': instance.server,
      'default': instance.default_,
    };
