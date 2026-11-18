// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_plugin_settings_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdatePluginSettingsRequestCWProxy {
  UpdatePluginSettingsRequest settings(Map<String, String> settings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePluginSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePluginSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdatePluginSettingsRequest call({Map<String, String> settings});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdatePluginSettingsRequest.copyWith(...)` or call `instanceOfUpdatePluginSettingsRequest.copyWith.fieldName(value)` for a single field.
class _$UpdatePluginSettingsRequestCWProxyImpl
    implements _$UpdatePluginSettingsRequestCWProxy {
  const _$UpdatePluginSettingsRequestCWProxyImpl(this._value);

  final UpdatePluginSettingsRequest _value;

  @override
  UpdatePluginSettingsRequest settings(Map<String, String> settings) =>
      call(settings: settings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdatePluginSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdatePluginSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdatePluginSettingsRequest call({
    Object? settings = const $CopyWithPlaceholder(),
  }) {
    return UpdatePluginSettingsRequest(
      settings: settings == const $CopyWithPlaceholder() || settings == null
          ? _value.settings
          // ignore: cast_nullable_to_non_nullable
          : settings as Map<String, String>,
    );
  }
}

extension $UpdatePluginSettingsRequestCopyWith on UpdatePluginSettingsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdatePluginSettingsRequest.copyWith(...)` or `instanceOfUpdatePluginSettingsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdatePluginSettingsRequestCWProxy get copyWith =>
      _$UpdatePluginSettingsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePluginSettingsRequest _$UpdatePluginSettingsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdatePluginSettingsRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['settings']);
  final val = UpdatePluginSettingsRequest(
    settings: $checkedConvert(
      'settings',
      (v) => Map<String, String>.from(v as Map),
    ),
  );
  return val;
});

Map<String, dynamic> _$UpdatePluginSettingsRequestToJson(
  UpdatePluginSettingsRequest instance,
) => <String, dynamic>{'settings': instance.settings};
