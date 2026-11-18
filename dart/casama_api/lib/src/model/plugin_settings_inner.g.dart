// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_settings_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginSettingsInnerCWProxy {
  PluginSettingsInner name(String name);

  PluginSettingsInner label(String label);

  PluginSettingsInner description(String description);

  PluginSettingsInner server(String server);

  PluginSettingsInner default_(String? default_);

  PluginSettingsInner value(String value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginSettingsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginSettingsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginSettingsInner call({
    String name,
    String label,
    String description,
    String server,
    String? default_,
    String value,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginSettingsInner.copyWith(...)` or call `instanceOfPluginSettingsInner.copyWith.fieldName(value)` for a single field.
class _$PluginSettingsInnerCWProxyImpl implements _$PluginSettingsInnerCWProxy {
  const _$PluginSettingsInnerCWProxyImpl(this._value);

  final PluginSettingsInner _value;

  @override
  PluginSettingsInner name(String name) => call(name: name);

  @override
  PluginSettingsInner label(String label) => call(label: label);

  @override
  PluginSettingsInner description(String description) =>
      call(description: description);

  @override
  PluginSettingsInner server(String server) => call(server: server);

  @override
  PluginSettingsInner default_(String? default_) => call(default_: default_);

  @override
  PluginSettingsInner value(String value) => call(value: value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginSettingsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginSettingsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginSettingsInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? server = const $CopyWithPlaceholder(),
    Object? default_ = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return PluginSettingsInner(
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
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
    );
  }
}

extension $PluginSettingsInnerCopyWith on PluginSettingsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginSettingsInner.copyWith(...)` or `instanceOfPluginSettingsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginSettingsInnerCWProxy get copyWith =>
      _$PluginSettingsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginSettingsInner _$PluginSettingsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PluginSettingsInner', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'name',
          'label',
          'description',
          'server',
          'default',
          'value',
        ],
      );
      final val = PluginSettingsInner(
        name: $checkedConvert('name', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        server: $checkedConvert('server', (v) => v as String),
        default_: $checkedConvert('default', (v) => v as String?),
        value: $checkedConvert('value', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'default_': 'default'});

Map<String, dynamic> _$PluginSettingsInnerToJson(
  PluginSettingsInner instance,
) => <String, dynamic>{
  'name': instance.name,
  'label': instance.label,
  'description': instance.description,
  'server': instance.server,
  'default': instance.default_,
  'value': instance.value,
};
